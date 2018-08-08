pragma solidity ^0.4.23;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

pragma solidity 0.4.24;

contract Transfer {

    address constant public ETH = 0x0;

    /**
    * @dev Transfer tokens from this contract to an account.
    * @param token Address of token to transfer. 0x0 for ETH
    * @param to Address to send tokens to.
    * @param amount Amount of token to send.
    */
    function transfer(address token, address to, uint256 amount) internal returns (bool) {
        if (token == ETH) {
            to.transfer(amount);
        } else {
            require(ERC20(token).transfer(to, amount));
        }
        return true;
    }

    /**
    * @dev Transfer tokens from an account to this contract.
    * @param token Address of token to transfer. 0x0 for ETH
    * @param from Address to send tokens from.
    * @param to Address to send tokens to.
    * @param amount Amount of token to send.
    */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) 
        internal
        returns (bool)
    {
        require(token == ETH && msg.value == amount || msg.value == 0);

        if (token != ETH) {
            // Remember to approve first
            require(ERC20(token).transferFrom(from, to, amount));
        }
        return true;
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/*

  Copyright 2018 Contra Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.4.24;


// @title Bank: Accept deposits and allow approved contracts to borrow Ether and ERC20 tokens.
// @author Rich McAteer <rich@marble.org>, Max Wolff <max@marble.org>
contract Bank is Ownable, Transfer {
    using SafeMath for uint256;

    // Borrower => Approved
    mapping (address => bool) public approved;

    modifier onlyApproved() {
        require(approved[msg.sender] == true);
        _;
    }

    /**
    * @dev Deposit tokens to the bank.
    * @param token Address of token to deposit. 0x0 for ETH
    * @param amount Amount of token to deposit.
    */
    function deposit(address token, uint256 amount) external onlyOwner payable {
        transferFrom(token, msg.sender, this, amount);
    }

    /**
    * @dev Withdraw tokens from the bank.
    * @param token Address of token to withdraw. 0x0 for ETH
    * @param amount Amount of token to withdraw.
    */
    function withdraw(address token, uint256 amount) external onlyOwner {
        transfer(token, msg.sender, amount);
    }

    /**
    * @dev Borrow tokens from the bank.
    * @param token Address of token to borrow. 0x0 for ETH
    * @param amount Amount of token to borrow.
    */
    function borrow(address token, uint256 amount) external onlyApproved {
        borrowFor(token, msg.sender, amount);
    }

    /**
    * @dev Borrow tokens from the bank on behalf of another account.
    * @param token Address of token to borrow. 0x0 for ETH
    * @param who Address to send borrowed amount to.
    * @param amount Amount of token to borrow.
    */
    function borrowFor(address token, address who, uint256 amount) public onlyApproved {
        transfer(token, who, amount);        
    }

    /**
    * @dev Repay tokens to the bank.
    * @param token Address of token to repay. 0x0 for ETH
    * @param amount Amount of token to repay.
    */
    function repay(address token, uint256 amount) external payable {
        transferFrom(token, msg.sender, this, amount);
    }

    /**
    * @dev Approve a new borrower.
    * @param borrower Address of new borrower.
    */
    function addBorrower(address borrower) external onlyOwner {
        approved[borrower] = true;
    }

    /**
    * @dev Revoke approval of a borrower.
    * @param borrower Address of borrower to revoke.
    */
    function removeBorrower(address borrower) external onlyOwner {
        approved[borrower] = false;
    }

    /**
    * @dev Gets balance of bank. 
    * @param token Address of token to calculate total supply of.
    */
    function totalSupplyOf(address token) public view returns (uint256 balance) {
        if (token == ETH) {
            return address(this).balance; 
        } else {
            return ERC20(token).balanceOf(this); 
        }
    }

}