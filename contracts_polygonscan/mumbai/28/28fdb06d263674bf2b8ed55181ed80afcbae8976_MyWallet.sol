/**
 *Submitted for verification at polygonscan.com on 2021-07-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyWallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier OnlyOwner {
        require(msg.sender == owner, "403");
        _;
    }

    function flush() public OnlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function flushToken(Token _token) public OnlyOwner returns (bool) {
        return _token.transfer(owner, _token.balanceOf(address(this)));
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceToken(Token _token) public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function transferTo(address payable _to, uint256 _value) public OnlyOwner {
        _to.transfer(_value);
    }

    function transferTokenTo(
        Token _token,
        address _to,
        uint256 _value
    ) public OnlyOwner returns (bool) {
        return _token.transfer(_to, _value);
    }

    function transferMany(address payable[] memory _to, uint256[] memory _value)
        external
        payable
        OnlyOwner
    {
        require(_to.length == _value.length, "bad params");
        uint256 amount = 0;
        for (uint256 i = 0; i < _value.length; ++i) {
            amount += _value[i];
        }
        require(address(this).balance >= amount, "insufficient balance");
        for (uint256 i = 0; i < _to.length; ++i) {
            _to[i].transfer(_value[i]);
        }
    }

    function transferTokenMany(
        Token _token,
        address[] memory _to,
        uint256[] memory _value
    ) external OnlyOwner {
        require(_to.length == _value.length, "bad params");
        uint256 amount = 0;
        for (uint256 i = 0; i < _value.length; ++i) {
            amount += _value[i];
        }
        require(
            _token.balanceOf(address(this)) >= amount,
            "insufficient balance"
        );
        for (uint256 i = 0; i < _to.length; ++i) {
            _token.transfer(_to[i], _value[i]);
        }
    }
}

interface Token {
    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);
}