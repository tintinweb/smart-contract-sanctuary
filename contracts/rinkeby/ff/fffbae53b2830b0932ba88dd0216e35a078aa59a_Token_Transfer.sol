/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token_Transfer{
    
    IERC20 public token; 
    uint public amount;
    address private token_address = address(0x5632468696C6D00e1AA39A91fe5863fE72B78c17);
    
    constructor() public
    {
        token = IERC20(token_address);
        amount = 123;
    }
    // address[] private depositors;
    // mapping(address => uint) public depositors_balances;

    // function simple_send_from(address sender, address recipient, uint amount) public {
    //     bool approved = token.approve(sender, amount);
    //     require(approved, "Token approve failed");
    //     bool sent = token.transferFrom(sender, recipient, amount);
    //     require(sent, "Token transfer failed");
    // }
    
    function simple_send(address recipient, uint amount) public {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient Funds!");
        bool sent = token.transfer(recipient, amount);
        require(sent, "Token transfer failed");
    }
    
    function get_token_balance(address _address) public view returns (uint256)
    {
        uint256 balance = token.balanceOf(_address);
        return balance;
    }
    
    function Deposit_to_contract() public payable
    {
        require(address(this) != address(0), "Invalid contarct address!");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient Funds!");
        require(token.transferFrom(msg.sender, address(this), amount), "zzz Failed on transferFrom!");
    }
    
    function get_allowance(address owner) public view returns (uint)
    {
        return token.allowance(owner, address(this));
    }
    
    function get_contract_token_balance() public view returns(uint)
    {
        return token.balanceOf(address(this));
    }
    
    function flush(address recipient) public payable
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint contract_token_balance = token.balanceOf(address(this));
        require(contract_token_balance > 0, "Zero Funds!");
        bool sent = token.transfer(recipient, contract_token_balance);
        require(sent, "Token transfer failed");
    }

}