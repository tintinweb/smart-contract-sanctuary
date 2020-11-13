pragma solidity ^0.6.0;

abstract contract DssProxyActionsDsr {
    function join(address daiJoin, address pot, uint wad) virtual public;
    function exit(address daiJoin, address pot, uint wad) virtual public;
    function exitAll(address daiJoin, address pot) virtual public;
}
