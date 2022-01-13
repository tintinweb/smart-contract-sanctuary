/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0


/**
 * We want to ensure that we use at least v0.8 of the Solidity compiler
 * where overflows are checked by default, so we no longer need a SafeMath
 * library - see https://docs.soliditylang.org/en/v0.8.6/control-structures.html#checked-or-unchecked-arithmetic
 */
pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title Token
 * @dev Implements an ERC20 token, see https://eips.ethereum.org/EIPS/eip-20
 */

contract Token {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    string _name = "MyToken";
    string _symbol = "MTK";
    uint8 _decimals = 2;
    uint256 _totalSupply = 100000;
    address _contractOwner;

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowance;

    /**
     * Constructor - remember who the contract owner is and assign initial balance
     */
    constructor()  {
        _contractOwner = msg.sender;
        _balances[_contractOwner] = _totalSupply;
    }

    /**
     * Return the name of the token - note that according to ERC20, this is an optional
     * function
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * Return the symbol of the taken - note that according to ERC20, this is an optional
     * function
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * Return the decimals used for display purposes - optional
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * Return the total supply of the token 
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * Returns the account balance of another account with address owner.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * Transfers value amount of tokens to address to, and emits the Transfer event. 
     * Throws if the message caller’s account balance does not have enough token to spend.
     */
     function transfer(address to, uint256 value) public returns (bool success) {
         require(_balances[msg.sender] >= value, "Insufficient balance");
         _balances[msg.sender] -= value;
         _balances[to] += value;
         emit Transfer(msg.sender, to, value);
         return true;
     }

    /**
     * Allows spender spend token on behalf of the the msg.sender multiple times, up to the _value amount. 
     * If this function is called again it overwrites the current allowance with value.
     */
    function approve(address spender, uint256 value) public returns (bool success) {
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /** 
     * Transfers value amount of tokens from address from to address to, and fires the Transfer event. 
     * Throws unless the from account has deliberately authorized the sender of the message via 
     * a previous call to approve. Note that the authorization is checked based on the sender of the message, not the to field
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(_allowance[from][msg.sender] >= value, "Transfer not authorized");
        require(_balances[from] >= value, "Insufficient balance");
        _allowance[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }    

    /**
     * Returns the amount which spender is still allowed to spend on the behalf of owner
     */
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return _allowance[owner][spender];
    }
}