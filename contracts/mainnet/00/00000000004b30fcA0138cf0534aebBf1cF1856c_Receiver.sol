/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

/*
SPDX-License-Identifier: M̧͖̪̬͚͕̘̻̙̫͎̉̾͑̽͌̓̏̅͌̕͘ĩ̢͎̥̦̼͖̾̀͒̚͠n̺̼̳̩̝̐͒̑̄̕͢͞è̫̦̬͙̌͗͡ş̣̞̤̲̳̭̫̬̦͗́͂̅̉̒̍͑̑̒̈́̏͟͜™͍͙͆̒̏ͅ®̳̻̋̿©͕̅
*/

pragma solidity ^0.8.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract Receiver is Context, Ownable {
    address payable private addr;
    constructor(address payable _addr) {
        addr = _addr;
    }
    receive() external payable { }
    fallback() external payable { }
    function changeAddress(address payable newaddr) external onlyOwner {
        addr = newaddr;
    }
    function transfer() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            addr.transfer(balance);
        }
    }
}