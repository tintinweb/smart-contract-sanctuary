/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata){
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(){
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address){
        return _owner;
    }
    modifier onlyOwner(){
        require(owner() == _msgSender(),"Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract A {
    constructor(){
        _getColor("red");
    }
    function _getColor(string memory color) public pure returns(string memory){
        return color;
    }
}
contract MyContract is Ownable,A {
    string private name;
    constructor(string memory _name){
        name = _name;
    }
    function getName() view external returns(string memory){
        return name;
    }
}