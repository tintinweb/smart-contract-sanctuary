pragma solidity ^0.5.4;
// SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.6.12;

import "./SafeMath.sol";

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Ownable {

    address public owner;

    // Events
    event OwnerTransferred(address indexed previousOwner, address indexed newOwner);

    // The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() public {
        owner = msg.sender;
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    // New Owner
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnerTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TransferTool is Ownable {    
    
    using SafeMath for uint256;
    
    // BNB 转账
    function transfer(address _to) public payable returns (bool) {
        require(_to != address(0));
        address payable to = address(uint160(_to));
        to.transfer(msg.value);
        return true;
    }

    // BNB 批量转账（平均 msg.value）
    function transfersAvg(address[] memory _tos) public payable returns (bool) {
        uint256 len = _tos.length;
        require(len > 0, "require _tos's length > 0");
        require(msg.value > 0, "require sender value > 0");
        uint256 value = msg.value.div(len);
        for (uint256 i = 0; i < len; i++) {
            address payable to = address(uint160(_tos[i])); // v0.5
            to.transfer(value);
        }
        return true;
    }

    // BNB 批量转账 by value
    function transfersValue(address[] memory _tos, uint256 _value) public payable returns (bool) {
        uint256 len = _tos.length;
        require(len > 0, "require _tos's length > 0");
        require(msg.value > 0, "require sender value > 0");
        require(msg.value >= _value.mul(len), "sender value not enough");
        for (uint256 i = 0; i < len; i++) {
            address payable to = address(uint160(_tos[i])); // v0.5
            to.transfer(_value);
        }
        return true;
    }

    // BNB 批量转账 by values
    function transfersValues(address[] memory _tos, uint256[] memory _values) public payable returns (bool) {
        uint256 len = _tos.length;
        uint256 len2 = _values.length;
        require(len > 0 && len2 > 0, "require _tos's length and _values's length > 0");
        require(len == len2, "_tos’ length and _values's length is not equal");
        require(msg.value > 0, "require sender value > 0");
        uint256 total = 0;
        for (uint256 j = 0; j < len2; j++) {
            total.add(_values[j]);
        }
        require(msg.value >= total, "sender value not enough");
        for (uint256 i = 0; i < len; i++) {
            address payable to = address(uint160(_tos[i])); // v0.5
            to.transfer(_values[i]);
        }
        return true;
    }


    // Token 批量转账 by value （先 approve 给本合约 len * _value）
    function tokenTransfersValue(address _tokenAddress, address[] memory _tos, uint256 _value) public returns (bool) {
        uint256 len = _tos.length;
        require(len > 0, "require _tos's length > 0");
        Token token = Token(_tokenAddress);
        for (uint256 i = 0; i < len; i++) {
            token.transferFrom(msg.sender, _tos[i], _value);
        }
        return true;
    }
    
    // Token 批量转账 by values（先 approve 给本合约 _values's sum）
    function tokenTransfersValues(address _tokenAddress, address[] memory _tos, uint256[] memory _values) public returns (bool) {
        uint256 len = _tos.length;
        uint256 len2 = _values.length;
        require(len > 0 && len2 > 0, "require _tos's length and _values's length > 0");
        require(len == len2, "_tos’ length and _values's length is not equal");
        Token token = Token(_tokenAddress);
        for (uint256 i = 0; i < len; i++) {
            token.transferFrom(msg.sender, _tos[i], _values[i]);
        }
        return true;
    }


    // 合约余额
    function balance() public view returns (uint) {
        return address(this).balance;
    }

    // 合约可接收
    function() payable external {}

    // 合约余额 提取
    function withdraw(address _to, uint256 _value) public onlyOwner returns (bool) {
        uint256 bal = address(this).balance;
        require(_to != address(0));
        require(bal > 0, "balance is zero");
        require(bal >= _value, "balance not enough");
        address payable to = address(uint160(_to)); // v0.5
        to.transfer(_value);
        // payable(_to).transfer(msg.value) // 0.6+
        return true;
    }

    // 合约销毁
    function destory() public onlyOwner {
        address payable addr = address(uint160(owner)); // v0.5
        selfdestruct(addr);
    }
}