pragma solidity ^0.5.8;
import "./TRC20Events.sol";

contract ITRC20 is TRC20Events {
    function totalSupply() public view returns (uint);

    function balanceOf(address guy) public view returns (uint);

    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);

    function transfer(address dst, uint wad) public returns (bool);

    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}


