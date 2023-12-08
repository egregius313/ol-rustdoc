;;; ol-rustdoc.el --- Provide Rustdoc support for links in Orgmode -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Edward Minnix III
;;
;; Author: Edward Minnix III <egregius313@gmail.com>
;; Maintainer: Edward Minnix III <egregius313@gmail.com>
;; Created: April 18, 2022
;; Modified: April 18, 2022
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/egregius313/ol-rustdoc
;; Package-Requires: ((emacs "27.1") (org "9.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Support links for Rust documentation by using supplying the `rustdoc:' link
;; type.
;;
;;; Code:

(require 'ol)
(require 'dash)
(require 's)

(defgroup ol-rustdoc nil
  "Customization for ol-rustdoc."
  :group 'org)

(org-link-set-parameters "rustdoc"
                         :follow #'ol-rustdoc-open
                         :export #'ol-rustdoc-export)

(defcustom ol-rustdoc-std-version
  "latest"
  "Version to use for looking up variables from the stdlib."
  :type 'string
  :group 'ol-rustdoc)

(defcustom ol-rustdoc-default-versions
  '((std . "stable")
    (nightly_rustc . "stable"))
  "Default version to use."
  :type '(alist :key-type symbol :value-type string))

(defcustom ol-rustdoc-package-doc-hosts
  '((std . "docs.rust-lang.org")
    (serde . "docs.serde.rs")
    (serde_json . "docs.serde.rs")
    (nightly_rustc . "docs.rust-lang.org"))
  "Default documentation site hostnames for packages."
  :type '(alist :key-type symbol :value-type string)
  :group 'ol-rustdoc)

(defcustom ol-rustdoc-package-default-doc-host
  "docs.rs"
  "Default documentation site for packages."
  :type 'string
  :group 'ol-rustdoc)

(defconst ol-rustdoc-identifier-regexp
  (rx alpha (* word)))

(defconst ol-rustdoc-regex
  (rx (group (regexp ol-rustdoc-identifier-regexp))))

(defun ol-rustdoc-package-name (path)
  "Get the package name from the specified `PATH'."
  (->> path
       (s-match (rx (+ word)))
       car
       intern))

(defun ol-rustdoc-normalize-path (path)
  "Convert the `PATH' to an expected path for a url."
  (->>
   path
   (s-replace-regexp (rx word-boundary
                         (group (regexp ol-rustdoc-identifier-regexp))
                         "#"
                         (group (regexp ol-rustdoc-identifier-regexp)))
                     "\\2.\\1")
   (s-replace-regexp "::" "/")))

(defun ol-rustdoc-format-rustc-nightly-url (host _package version normalized-path)
  (format "https://%s/%s/%s.html" host version (s-replace "nightly_rustc" "nightly-rustc" normalized-path)))

(defun ol-rustdoc-format-std-url (host _package version normalized-path)
  (format "https://%s/%s/%s.html" host version normalized-path))

(defun ol-rustdoc-format-serde-url (host package version normalized-path)
  (format "https://%s/%s.html" host normalized-path))


(defcustom ol-rustdoc-formatters
  '((std . ol-rustdoc-format-std-url)
    (serde . ol-rustdoc-format-serde-url)
    (serde_json . ol-rustdoc-format-serde-url)
    (nightly_rustc . ol-rustdoc-format-rustc-nightly-url))
  "Formatters for rustdoc urls."
  :type '(alist :key-type symbol :value-type function))

(defun ol-rustdoc-default-formatter (host package version normalized-path)
  (format "https://%s/%s/%s/%s.html" host package version normalized-path))


(defun ol-rustdoc-path-to-url (path)
  "Get the url for an item specified by `PATH'."
  (let* ((package (ol-rustdoc-package-name path))
         (normalized-path (ol-rustdoc-normalize-path path))
         (host (alist-get package ol-rustdoc-package-doc-hosts ol-rustdoc-package-default-doc-host))
         (version (alist-get package ol-rustdoc-default-versions "latest"))
         (formatter (alist-get package ol-rustdoc-formatters 'ol-rustdoc-default-formatter)))
    (funcall formatter host package version normalized-path)))


(defun ol-rustdoc-open (path _)
  "Open the documentation for the item specified by `PATH'."
  (browse-url (ol-rustdoc-path-to-url path)))

(defun ol-rustdoc-export (link description format _)
  "Export a man page link from Org files."
  (let ((path (ol-rustdoc-path-to-url link))
        (desc (or description (s-replace-regexp (rx "#" (* any)) "" link))))
    (pcase format
      (`html (format "<a target=\"_blank\" href=\"%s\">%s</a>" path desc))
      (`latex (format "\\href{%s}{%s}" path desc))
      (`texinfo (format "@uref{%s,%s}" path desc))
      (`ascii (format "%s (%s)" desc path))
      (_ path))))

(provide 'ol-rustdoc)
;;; ol-rustdoc.el ends here
