pragma solidity ^0.6.0;

import "./Vat.sol";
import "./Gem.sol";

abstract contract DaiJoin {
    function vat() public virtual returns (Vat);
    function dai() public virtual returns (Gem);
    function join(address, uint) public virtual payable;
    function exit(address, uint) public virtual;
}
