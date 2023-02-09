# Composer comments phar patcher

This tools patch phar file `composer.phar` for JSON comments support.

## Usage 

```
$ curl https://gist.githubusercontent.com/../phar-patcher | php -- path/to/composer.phar
```

Or use local pre downloaded `phar-patcher` script.

```
$ phar-patcher path/to/composer.phar
```

Now you may use the comments in your `composer.json` file.

```
{
    "repositories": [
        {"type": "composer", "url": /*"https://example.com/mirror/org1/"*/ "https://packagist.com/org2"},
        {"packagist": false}
    ],
    "require": {
        "php": ">=8.1",
        "ext-redis": "*",
        "firebase/php-jwt": "^6.0",
      //  "babdev/pagerfanta-bundle": "^3.7",
      //  "babdev/pagerfanta-bundle": "^2.0",
      //  "cebe/markdown": "^1.1"
    }
}
```

### New composer commands behaviour if JSON is not valid.

| The Command         | Behaviour                                         |
|---------------------|---------------------------------------------------|
| composer `install`  | ignore comments                                   |
| composer `update`   | ignore comments                                   |
| composer `require`  | ignore comments and dump composer.json without it |
| composer `validate` | not allowed                                       |

composer `depends`, `suggests`, `run-script`, `reinstall` etc. ignore comments too

### How it works.

By default, composer load plugins after loading `composer.json` file. 
So it's not possible to overwrite behaviour of `JsonFile` inside a plugin context.
Alternative way is patching existing PHAR `composer.phar`.

This script is overwrite `json_decode` function for namespace `Composer\Json\json_decode`

PHP in the first try to load a function from the current namespace, so when `json_decode` is called under
`JsonFile` class my custom function `Composer\Json\json_decode` is trigger. 

```php
namespace Composer\Json;

if (!\function_exists('Composer\Json\json_decode')) {
    function json_decode($json, $associative = null, $depth = 512, $flags = 0)
    {
        if (null === ($result = \json_decode($json, $associative, $depth, $flags))) {
            $minify = \preg_replace('#(([},{\[\]]|false\b|true\b|null\b|\d\b|\w")//.*)|(\s//.*)|(^//.*)#', '$2', $json);
            $minify = \preg_replace('#\s*(?!<\")/\*[^*]+\*/(?!\")\s*#', '', $minify);

            return \json_decode($minify, $associative, $depth, $flags);
        }

        return $result;
    }
}
```

### Backward Incompatible Changes and Impact on performance.

No impact. By default, in the first time called standard `json_decode` function. JSON will be minified 
if only exists comments and standard `json_decode` is not success.

