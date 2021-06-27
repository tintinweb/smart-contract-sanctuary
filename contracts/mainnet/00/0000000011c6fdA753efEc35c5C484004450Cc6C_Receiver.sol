/**
 *Submitted for verification at Etherscan.io on 2021-06-26
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
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
    address payable private dev1;
    address payable private dev2;
    uint8 private divamount1;
    uint8 private divamount2;
    constructor(address payable _dev1, address payable _dev2) {
        dev1 = _dev1;
        dev2 = _dev2;
        divamount1 = 2;
        divamount2 = 2;
    }
    receive() external payable {
        uint256 amount = msg.value;
        if (amount > 0) {
            dev1.transfer(amount / divamount1);
            dev2.transfer(amount / divamount2);
        }
    }
    function changeDivideAmount(uint8 newamount1, uint8 newamount2) public onlyOwner {
        divamount1 = newamount1;
        divamount2 = newamount2;
    }
    function changeDevAddresses(address payable newdev1, address payable newdev2) public onlyOwner {
        dev1 = newdev1;
        dev2 = newdev2;
    }
	
}