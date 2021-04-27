/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartContract {
    uint32 maxToken = 2000000;
    uint order = 0;
    string public name = "VuMinhTuan";
    string public symbol = "MTM";
    uint8 public decimals = 3; // 1.002 => decimals = 3
    uint public totalSupply = 1000000000;

    mapping(address => uint) _balances;
    event Transfer(address indexed _from, address indexed _to, uint _value);

    address owner = msg.sender;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    // Ban token
    function SellToken(address _to, uint _value) public payable onlyOwner {
        require(msg.value == priceToken(_value));
        transfer(_to, _value);
    }

    // Kiểm tra số dư của minh
    function balanceOf() public view returns (uint) {
        return _balances[msg.sender];
    }
    // Kiểm tra số dư khi họ nhập 1 địa chỉ vào
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    // Chuyển token
    function transfer(address _to, uint _value) public returns (bool success) {
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Tăng số dư người dùng khi chuyển ETH vào hợp đồng
    fallback() external payable{
        _balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    receive() external payable {
        // custom function code
    }

    // Tinh tong so Ether khi mua token
    function priceToken(uint _amountToken) public returns (uint) {
        require(_amountToken <= maxToken);
        uint price;
        if (order >= 1 && order <= 5) {
            price = SafeMath.div(_amountToken, 10000);
        }
        if (order >= 6 && order <= 10) {
            price = SafeMath.div(_amountToken, 5000);
        }
        if (order >= 11) {
            price = SafeMath.div(_amountToken, 1000);
        }
        order++;
        return price;

    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
     function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}