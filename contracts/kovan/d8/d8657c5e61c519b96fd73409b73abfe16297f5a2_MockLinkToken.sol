/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// File: contracts/LinkTokenInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  function deposit(address user, uint256 amount) external; 
}

// File: contracts/MockLinkToken.sol

pragma solidity ^0.7.1;


contract MockLinkToken is LinkTokenInterface {
    string public _name = "Wrapped LINK";
    string public _symbol = "LINK";
    uint8 public _decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public _balanceOf;
    mapping(address => mapping(address => uint256)) public _allowance;

    function decimals() external view override returns (uint8 decimalPlaces) {
        decimalPlaces = _decimals;
    }

    function decreaseApproval(address spender, uint256 addedValue)
        external
        override
        returns (bool success)
    {
        return true;
    }

    function increaseApproval(address spender, uint256 subtractedValue)
        external
        override
    {
        return;
    }

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external override returns (bool success){
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        remaining = _allowance[owner][spender];
    }

    function balanceOf(address owner)
        external
        view
        override
        returns (uint256 balance)
    {
        balance = _balanceOf[owner];
    }

    function name() external view override returns (string memory tokenName) {
        tokenName = _name;
    }

    function symbol()
        external
        view
        override
        returns (string memory tokenSymbol)
    {
        tokenSymbol = _symbol;
    }

    function deposit(address user, uint256 amount) external override{
        _balanceOf[user] += amount;
        emit Deposit(user, amount);
    }

    function withdraw(uint256 wad) public {
        require(_balanceOf[msg.sender] >= wad);
        _balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() external view override returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad)
        external
        override
        returns (bool)
    {
        _allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad)
        external
        override
        returns (bool)
    {
        return transferFrom2(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external override returns (bool) {
        require(_balanceOf[src] >= wad);

        if (src != msg.sender && _allowance[src][msg.sender] != uint256(-1)) {
            require(_allowance[src][msg.sender] >= wad);
            _allowance[src][msg.sender] -= wad;
        }

        _balanceOf[src] -= wad;
        _balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function transferFrom2(
        address src,
        address dst,
        uint256 wad
    ) private returns (bool) {
        require(_balanceOf[src] >= wad, "insufficient balance");
        if (src != msg.sender && _allowance[src][msg.sender] != uint256(-1)) {
            require(_allowance[src][msg.sender] >= wad);
            _allowance[src][msg.sender] -= wad;
        }

        _balanceOf[src] -= wad;
        _balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}