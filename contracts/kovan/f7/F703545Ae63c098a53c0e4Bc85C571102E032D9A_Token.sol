/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract Token {

    // Balances
    mapping(address => uint) tokenBalances;
    // Allowances
    mapping(address => mapping(address => uint)) tokenAllowances;
    // The owner of this token
    address public owner;
    // Optional ERC-20 Functions
    string public name ;
    string public symbol ;
    uint8  public decimals ;
    
     /** This event is emitted when tokens are transferred from one account to another. */
    event Transfer(address indexed from, address indexed to, uint tokens);

    /** This event is emitted when tokens are approved for transfer from one account to another.. */
    event  Approval(address indexed tokenOwner, address indexed spender, uint tokens);
      uint currentSupply;
    // Constructor. Called ONCE when the contract is deployed.
    constructor(uint _currentsupply,string memory _name,string memory _symbol)  {
        owner = msg.sender;
        currentSupply = _currentsupply;
        name = _name;
        symbol = _symbol;
        decimals = 0;
    }

    // Implement a minting function here -OR- generate a fixed
    // supply in the constructor


    

    // Required ERC-20 Functions
    /** Returns the current total supply of tokens available. The easisest
        way to implement this function is to keep track of the total supply
        in a storage variable and to return it when this functino is called. */
    function totalSupply() public view returns (uint) {
        return currentSupply;
    }

    /** Return the balance of a given token owner. */
    function balanceOf(address _tokenOwner) public view returns (uint balance) {
        return tokenBalances[_tokenOwner];
    }

    /** Return the tokens that spender is still allowed to return from tokenOwner. */
    function allowance(address _tokenOwner, address _spender) public view returns (uint remaining) {
        return tokenAllowances[_tokenOwner][_spender];
    }

    /** Transfer tokens from sender's account to the to account.
        Zero-value transfers MUST be treated as normal transfers.
        This function should throw an error (use require(condition, message)) if
        the account has insufficient tokens.
        A successful transfer should emit the Transfer() event.
     */
    function transfer(address _to, uint _tokens) public returns (bool success) {
        uint tokenBalance = tokenBalances[msg.sender];
        require(tokenBalance > _tokens, "You do not have enough tokens");
        tokenBalances[msg.sender] -= _tokens;
        tokenBalances[_to] += _tokens;
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    /** Approve spender to spend tokens from caller's account.
        If this function is called multiple times, the previous allowance
        is replaced.

        Successful execution of this function should emit the Approval() event.
     */
    function approve(address spender, uint tokens) public returns (bool success) {
        tokenAllowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function mint(address to, uint tokens) public returns (bool success) {
        require(msg.sender == owner, "You must be the token owner to call this function");
        tokenBalances[to] += tokens;
        currentSupply += tokens;
        return true;
    }

    /** Transfer tokens from one account to another account.

        Zero-value transfers MUST be treated as normal transfers.
        This function should throw an error (use require(condition, message)) if
        the from account has insufficient tokens or there is insufficient allowance
        for the caller account.

        A successful transfer should emit the Transfer() event.
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokenAllowances[from][msg.sender] > tokens, "Not enough token allowance to transfer!");
        require(tokenBalances[from] > tokens, "Account does not have enough tokens");
        tokenBalances[from] -= tokens;
        tokenBalances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
   
}