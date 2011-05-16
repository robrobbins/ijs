// Act as a bootstrap file that can load jQuery and plugins before we try
// to use them as well as perform any other setup work.
I.provide('base.load');
I.require(['jQuery','tooltip','bgiframe','delegate','dimensions']);
I.require('RML');
I.require('base.test');