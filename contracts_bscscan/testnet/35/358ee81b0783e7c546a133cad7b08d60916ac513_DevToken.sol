/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "./Ownable.sol";
//import "./Stakeable.sol";
/**
* @notice DevToken is a development token that we use to learn how to code solidity 
* and what BEP-20 interface requires
*/


contract DevToken {
  
  /**
  * @notice Our Tokens required variables that are needed to operate everything
  */
  uint256 private _totalSupply;
  uint256 private _decimals;
  string private _symbol;
  string private _name;
  uint256 private _taxFee;
  address private _owner;
  

  /**
  * @notice _balances is a mapping that contains a address as KEY 
  * and the balance of the address as the value
  */
  mapping (address => uint256) private _balances;
  /**
  * @notice _allowances is used to manage and control allownace
  * An allowance is the right to use another accounts balance, or part of it
   */
   mapping (address => mapping (address => uint256)) private _allowances;

  /**
  * @notice Events are created below.
  * Transfer event is a event that notify the blockchain that a transfer of assets has taken place
  *
  */
  event Transfer(address indexed from, address indexed to, uint256 value);
  /**
   * @notice Approval is emitted when a new Spender is approved to spend Tokens on
   * the Owners account
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: only owner can call this function");
        // This _; is not a TYPO, It is important for the compiler;
        _;
    }

  /**
  * @notice constructor will be triggered when we create the Smart contract
  * _name = name of the token
  * _short_symbol = Short Symbol name for the token
  * token_decimals = The decimal precision of the Token, defaults 18
  * _totalSupply is how much Tokens there are totally 
  */
  //constructor(string memory token_name, string memory short_symbol, uint8 token_decimals, uint256 token_totalSupply){
    constructor () {  
      _name = "9 COIN";
      _symbol = "9COIN";
      _decimals = 9;
      _totalSupply = 1000000000000000*10**9;
      _taxFee = 10;
      

      // Add all the tokens created to the creator of the token
      _balances[msg.sender] = _totalSupply;

      // Emit an Transfer event to notify the blockchain that an Transfer has occured
      emit Transfer(address(0), msg.sender, _totalSupply);
  }
  /**
  * @notice decimals will return the number of decimal precision the Token is deployed with
  */
  function decimals() external view returns (uint256) {
    return _decimals;
  }
  /**
  * @notice symbol will return the Token's symbol 
  */
  function symbol() external view returns (string memory){
    return _symbol;
  }
  /**
  * @notice name will return the Token's symbol 
  */
  function name() external view returns (string memory){
    return _name;
  }
  /**
  * @notice totalSupply will return the tokens total supply of tokens
  */
  function totalSupply() external view returns (uint256){
    return _totalSupply;
  }
  /**
  * @notice balanceOf will return the account balance for the given account
  */
  /*function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
  * @notice _mint will create tokens on the address inputted and then increase the total supply
  *
  * It will also emit an Transfer event, with sender set to zero address (adress(0))
  * 
  * Requires that the address that is recieveing the tokens is not zero address
  */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "7coin: cannot mint to zero address");

    // Increase total supply
    _totalSupply = _totalSupply + (amount);
    // Add amount to the account balance using the balance mapping
    _balances[account] = _balances[account] + amount;
    // Emit our event to log the action
    emit Transfer(address(0), account, amount);
  }

  function mint(address account, uint256 amount) external returns (bool) {
    require(_owner == msg.sender, "7coin: only owner can call this function");
    _mint(account, amount);
    return true;
  }

  /**
  * @notice transfer is used to transfer funds from the sender to the recipient
  * This function is only callable from outside the contract. For internal usage see 
  * _transfer
  *
  * Requires
  * - Caller cannot be zero
  * - Caller must have a balance = or bigger than amount
  *
   */
  function transfer(address recipient, uint256 amount) internal returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }
  /**
  * @notice _transfer is used for internal transfers
  * 
  * Events
  * - Transfer
  * 
  * Requires
  *  - Sender cannot be zero
  *  - recipient cannot be zero 
  *  - sender balance most be = or bigger than amount
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "7coin: transfer from zero address");
    require(recipient != address(0), "7coin: transfer to zero address");
    require(_balances[sender] >= amount, "7coin: cant transfer more than your account holds");

    _balances[sender] = _balances[sender] - amount - ((amount/100) * _taxFee);
    _balances[recipient] = _balances[recipient] + amount;
    _balances[_owner] += ((amount/100) * _taxFee);

    emit Transfer(sender, recipient, amount);
  }

  /*function _getTaxFee() public view returns(uint256) {
        return _taxFee;
    }*/



}