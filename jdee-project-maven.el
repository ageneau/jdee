;;; jdee-project-maven.el -- Project maven integration

;; Author: Matthew O. Smith <matt@m0smith.com>
;; Keywords: java, tools

;; Copyright (C) 2106 Matthew O. Smith

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Code:

(require 'jdee)
(require 'jdee-open-source)
(require 'cl)

(defgroup jdee-project-maven nil
  "JDEE Maven Project Options"
  :group 'jdee
  :prefix "jdee-")


(defcustom jdee-project-maven-file-name "pom.xml"
  "Specify the name of the maven project file."
  :group 'jdee-project-maven
  :type 'string)

(defcustom jdee-project-maven-dir-scope-map (list "target/compile.cp" '("src/main/java")
                                                  "target/test.cp" '("src/main/test"))

  "Specify a map of directories to maven dependency scope type."
  :group 'jdee-project-maven
  :type '(plist :key-type string :value-type (repeat string)))


(defun jdee-project-maven-pom-dir (&optional dir)
  "Find the directory of the closest maven maven project
file (see `jdee-project-maven-file-name') starting at
DIR (default to `default-directory')"
  (let ((pom-path  (jdee-find-project-file (or dir default-directory)
                                           jdee-project-maven-file-name)))
    (when pom-path
      (file-name-directory pom-path))))

(defun jdee-project-maven-scope-file (&optional dir)
  "Return which classpath file to use based on the `jdee-project-maven-dir-scope-map'."
  (cl-loop for (key paths) on jdee-project-maven-dir-scope-map by 'cddr
           if (-any-p (lambda (path) (string-match path (or dir default-directory))) paths)
           return key))

(defun jdee-project-maven-from-file-hook ()
  "Run as a hook to setup the classpath based on having the classpath in a file on disk.  See `jdee-project-maven-dir-scope-map' for how the files are chosen."
  (let ((pom-dir (jdee-project-maven-pom-dir)))
    (when pom-dir
      (let ((cp (jdee-project-maven-classpath-from-file
                 (expand-file-name (jdee-project-maven-scope-file) pom-dir))))
        (jdee-set-variables '(jdee-global-classpath cp))))))

(add-hook 'jdee-project-hooks 'jdee-project-maven-from-file-hook)

(defun jdee-project-maven-classpath-from-file (file-name &optional sep)
  "Read a classpath from a file that contains a classpath.  Useful in conjunction with
a maven plugin to create the classpath like:
	    <plugin>
              <groupId>org.apache.maven.plugins</groupId>
              <artifactId>maven-dependency-plugin</artifactId>
              <version>2.10</version>
              <executions>
		<execution>
		  <id>test-classpath</id>
		  <phase>generate-sources</phase>
		  <goals>
		    <goal>build-classpath</goal>
		  </goals>
		  <configuration>
		    <outputFile>target/test.cp</outputFile>
		    <includeScope>test</includeScope>
		  </configuration>
		</execution>
		<execution>
		  <id>compile-classpath</id>
		  <phase>generate-sources</phase>
		  <goals>
		    <goal>build-classpath</goal>
		  </goals>
		  <configuration>
		    <outputFile>target/compile.cp</outputFile>
		    <includeScope>compile</includeScope>
		  </configuration>
		</execution>
              </executions>
	    </plugin>

It can be used in a prj.el like this in src/test

(jdee-set-variables
 '(jdee-global-classpath (jdee-project-classpath-from-file \"./../../target/test.cp\")))

and this in src/main

(jdee-set-variables
 '(jdee-global-classpath (jdee-project-classpath-from-file \"./../../target/compile.cp\")))


"
  (let ((the-file (jdee-normalize-path file-name)))
    (message "loading file %s %s" the-file (file-exists-p the-file))
    (jdee-with-file-contents
     the-file
     (split-string (buffer-string) (or sep path-separator t)))))

(provide 'jdee-project-maven)

;;; jdee-project-maven.el ends here
