#!/bin/bash
phpcbf $(find . -name "*.php") --standard=./phpcs.ruleset.xml
