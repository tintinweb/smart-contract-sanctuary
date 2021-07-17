/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// SPDX-License-Identifier: GPL 3.0
/**
 * 

      ___           ___           ___           ___           ___                       ___     
     /  /\         /__/\         /  /\         /  /\         /__/\        ___          /  /\    
    /  /:/         \  \:\       /  /::\       /  /::\       |  |::\      /  /\        /  /::\   
   /  /:/           \__\:\     /  /:/\:\     /  /:/\:\      |  |:|:\    /  /:/       /  /:/\:\  
  /  /:/  ___   ___ /  /::\   /  /:/~/:/    /  /:/  \:\   __|__|:|\:\  /__/::\      /  /:/~/::\ 
 /__/:/  /  /\ /__/\  /:/\:\ /__/:/ /:/___ /__/:/ \__\:\ /__/::::| \:\ \__\/\:\__  /__/:/ /:/\:\
 \  \:\ /  /:/ \  \:\/:/__\/ \  \:\/:::::/ \  \:\ /  /:/ \  \:\~~\__\/    \  \:\/\ \  \:\/:/__\/
  \  \:\  /:/   \  \::/       \  \::/~~~~   \  \:\  /:/   \  \:\           \__\::/  \  \::/     
   \  \:\/:/     \  \:\        \  \:\        \  \:\/:/     \  \:\          /__/:/    \  \:\     
    \  \::/       \  \:\        \  \:\        \  \::/       \  \:\         \__\/      \  \:\    
     \__\/         \__\/         \__\/         \__\/         \__\/                     \__\/    

// Copyright (C) 2017, 2018, 2019, 2020, 2021 Augur, dbrock, rain, mrchico, lucasvo

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
/*
IMPORT

// File: openzeppelin-solidity/contracts/proxy/Proxy.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */

pragma solidity ^0.8.6;

interface IBEP20 {
  // @dev Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of tokens owned by `account`.
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `value` tokens are moved from one account (`from`) to  another (`to`). Note that `value` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 value);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Chromia is IBEP20 {
  
    // common addresses
    address private owner;
    address private developmentPot;
    address private foundersPot;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Binance-Peg Chromia Token";
    string public override symbol = "CHR";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint value);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint value);
    
    // On init of contract we're going to set the admin and give them all tokens.
    constructor(uint totalSupplyValue, address developmentAddress, address foundersAddress) {
        // set total supply
        totalSupply = totalSupplyValue;
        
        // designate addresses
        owner = msg.sender;
        developmentPot = developmentAddress;
        foundersPot = foundersAddress;
        
        // split the tokens according to agreed upon percentages
        balances[developmentPot] =  totalSupply * 5 / 100;
        balances[foundersPot] = totalSupply * 15 / 100;
        
        balances[owner] = totalSupply * 80 / 100;
    }
    
    // Get the address of the token's owner
    function getOwner() public view override returns(address) {
        return owner;
    }
    
    // Get the address of the token's development pot
    function getDeveloper() public view returns(address) {
        return developmentPot;
    }
    
    // Get the address of the token's founder pot
    function getFounder() public view returns(address) {
        return foundersPot;
    }
    
    // Get the balance of an account
    function balanceOf(address account) public view override returns(uint) {
        return balances[account];
    }
    
    // Transfer balance from one user to another
    function transfer(address to, uint value) public override returns(bool) {
        require(value > 0, "Transfer value has to be higher than 0.");
        require(balanceOf(msg.sender) >= value, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total value
        uint taxTBD = value * 4 / 100;
        uint burnTBD = value * 0 / 100;
        uint valueAfterTaxAndBurn = value - taxTBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += valueAfterTaxAndBurn;
        balances[msg.sender] -= value;
        
        emit Transfer(msg.sender, to, value);
        
        // finally, we burn and tax the extras percentage
        balances[owner] += taxTBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint value) public override returns(bool) {
        allowances[msg.sender][spender] = value; 
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint value) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= value, "Allowance too low for transfer.");
        require(balances[from] >= value, "Balance is too low to make transfer.");
        
        balances[to] += value;
        balances[from] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    // function to allow users to burn currency from their account
    function burn(uint256 amount) public returns(bool) {
        _burn(msg.sender, amount);
        
        return true;
    }
    
    // intenal functions
    
    // burn amount of currency from specific account
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "You can't burn from zero address.");
        require(balances[account] >= amount, "Burn amount exceeds balance at address.");
    
        balances[account] -= amount;
        totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
    }
    
}