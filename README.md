[![Pub Version](https://img.shields.io/pub/v/anvil)](https://pub.dev/packages/anvil)
[![GitHub](https://img.shields.io/github/license/ethananvil4/anvil)](https://github.com/ethananvil4/anvil/blob/main/LICENSE)

# Anvil: Static Site Generator

Anvil is an opinionated static site generator written in Dart lang. 
It is provided as a single binary and can be used even without Dart installed.

Features as of now:

* Markdown support.
* YAML configuration and front-matter.
* Jinja templates. Also usable in Markdown files.
* Live-reload during development.
* Compiled into single native binary.
* JSON data content and non-public Data pages.
* Pre-defined content types for quick creation.
* SCSS styles
* Generated JSON search index.
* `sitemap.xml` generation.
* Inline & body shortcodes.

Remember that this project is WIP. Everything can change at any time.

## Installation

[Install Dart](https://dart.dev/get-dart).

Run `pub global activate anvil`.

## Usage

Use `anvil init` to setup a new project in the current directory. `anvil init <name>` will setup the project inside the `<name>` directory.

Use `anvil build` to generate the site from your files. By default, generated files will be outputted into the `public` folder.

Use `anvil serve` to start a webserver to see your site instantly. The site will be rebuilt every time you change files in your project and the browser tab will be reloaded automatically.

Use `anvil new` to create new content based on types defined in `types` folder.

And as usual, `anvil` or `anvil help` will show usage help.

## Structure

`content` directory contains all Markdown files which will be transformed into HTML files.

`styles` directory contains SCSS files which will be transformed into CSS.

`static` directory files will be copied into the `public` folder without change.

`public` contains generated files.

`templates` should contain templates which will be used to process Markdown files inside `content`.

`data` contains YAML/JSON files which you can use inside templates.

`types` is used by the `new` command to quickly create content.

`anvil.yaml` configures build options for your site.