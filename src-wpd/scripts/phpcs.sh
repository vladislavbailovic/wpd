#!/bin/bash
phpcs $(find . -name "*.php") --standard=./phpcs.ruleset.xml
