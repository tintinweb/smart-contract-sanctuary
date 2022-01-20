// SPDX-License-Identifier: MIT

import "Ownable.sol";

pragma solidity ^0.8.0;

contract AccountBind is Ownable{

    struct Account {
        uint mid;
        bool bound;
    }

    mapping(address => Account) accounts;
    mapping(uint => address) mids;

     // 合约支持捐赠
     // 捐助用户燃料费发放
    function donate() payable public{
        payable(address(this)).transfer(msg.value);
    }

    // 判断地址是否已经绑定
    function isAddressBound(address addr) view internal returns(bool) {
        return accounts[addr].bound;
    }

    // 判断 MID 是否已经绑定
    function isMidBound(uint mid) view internal returns(bool) {
        return mids[mid] != address(0);
    }

    // 获取地址绑定的 MID
    // Token Mint 合约需要调用
    function getMid(address addr) view external returns(uint) {
        require(
            isAddressBound(addr) == true,
            "Address not bound."
        );
        return accounts[addr].mid;
    }

    // 合约中还剩多少钱 ^_^
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 完成绑定，发钱发钱
    // 只允许管理员调用
    function bind(address payable addr, uint mid) public payable onlyOwner {
        require(
            isAddressBound(addr) != true,
            "Address already bound."
        );
        require(
            isMidBound(mid) != true,
            "Mid already bound."
        );
        accounts[addr] = Account({mid: mid, bound: true});
        mids[mid] = addr;
        addr.transfer(10000000000000000);
    }

    // 不玩了，不玩了，尼玛退钱
    // 只允许管理员调用
    function withdraw() public payable onlyOwner {
        payable(Ownable.owner()).transfer(getBalance());
    }

}