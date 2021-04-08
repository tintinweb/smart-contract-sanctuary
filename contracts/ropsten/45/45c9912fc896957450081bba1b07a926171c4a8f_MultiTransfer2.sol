/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.7.1;

abstract contract ERC20Interface {
    // Get the total token supply
    function totalSupply() external virtual returns (uint256);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) external virtual returns (uint256);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) external virtual returns (bool);
 
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool);
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) external virtual returns (bool);
 
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) external virtual returns (uint256);
 
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MultiTransfer2 {

    // Constructor
    constructor() {

    }

    function twoTransfer (
        address _contractAddress1,
        address _to1,
        uint256 _amount1,
        address _contractAddress2,
        address _to2,
        uint256 _amount2
    ) public returns (bool) {
        ERC20Interface erc20_1 = ERC20Interface(_contractAddress1);
        erc20_1.transferFrom(msg.sender, _to1, _amount1);
        ERC20Interface erc20_2 = ERC20Interface(_contractAddress2);
        erc20_2.transferFrom(msg.sender, _to2, _amount2);
    }
 }