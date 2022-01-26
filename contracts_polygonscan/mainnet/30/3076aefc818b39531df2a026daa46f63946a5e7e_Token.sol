/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// ERC20 Contract 
contract Token {

    string public name;             // = "ITechNote Coin" "Fa Tsai Bee";
    string public symbol;           // = "FTB";
    uint256 public decimals;        // = 18;
    uint256 public totalSupply;     //= 1000000000000000000000000000000; // total supply + 18 decimals

    // Initialize parameters of ERC20 token
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply;
    }

    // Track address balances 
    mapping(address => uint256) public balanceOf;

    // Create Transfer fire event
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Require message sender's balance then do _transfer function
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // Require target address not a zero address, or it'll create new contract
    /* From Solidity docs:
    If the target account is not set (the transaction does not have a recipient or the recipient is set to?null), 
    the transaction creates a?new contract. As already mentioned, 
    the address of that contract is not the zero address but an address derived from the sender 
    and its number of transactions sent (the ¡§nonce¡¨).
    */
    // Internal function transfer can only be called by this contract
    // Emit Transfer event
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    // Track allowance between contract and wallet
    mapping(address => mapping(address => uint256)) public allowance;

    // Create Approval fire event
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Allow _spender to spend up to _value on your behalf
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // message sender help _from address send tokens to _to address
    // _value must be less or equre allowance value set by approve function
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}