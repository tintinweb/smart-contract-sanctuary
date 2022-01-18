/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

pragma solidity >=0.6.0 <0.8.0;

contract MasterChef  {
    address private _owner;
    constructor() public{
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

}