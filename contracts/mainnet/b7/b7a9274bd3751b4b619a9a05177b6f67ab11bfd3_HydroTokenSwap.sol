/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT

/*
MIT License
Copyright (c) 2020 Hydro Money
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity 0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title ERC20 interface
 */
interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


/**
 * @title Hydro ERC20-BEP20 Swap Contract
 */
contract HydroTokenSwap is Ownable {
    using SafeMath for uint256;
    uint256 public contractTotalAmountSwapped;

    address constant Hydro_ADDRESS= 0x946112efaB61C3636CBD52DE2E1392D7A75A6f01;
    address Main_ADDRESS= 0x4aE8bfB81205837DE1437De26D02E5ca87694714;
    bool public isActive;
    
    struct User {
      address userAdd;
      uint256 totalAmountSwapped;
    }
    
    //a mapping to keep the details of users
    mapping(address => User) public userDetails;

    //main event that is emitted after a successful deposit
    event SwapDeposit(address indexed depositor, uint256 outputAmount);
    
    //check if the contract is open to swaps
    function isSwapActive() public view returns (bool) {
      return isActive;
    }
    
    //make sure contract is open to swaps
    modifier hasActiveSwap {
        require(isSwapActive(), "Swapping is currently paused");
        _;
    }



    /**
     * @dev Allows the user to deposit some amount of Hydro tokens. Records user/swap data and emits a SwapDeposit event.
     * @param amount Amount of input tokens to be swapped.
     */
    function swap( uint256 amount) external hasActiveSwap {
        
        require(amount > 0, "Input amount must be positive.");
        uint256 outputAmount = amount;
        require(outputAmount > 0, "Amount too small.");
        require(IERC20(Hydro_ADDRESS).transferFrom(msg.sender, Main_ADDRESS, amount), "Transferring Hydro tokens from user failed");
        userDetails[msg.sender].totalAmountSwapped+=amount;
        userDetails[msg.sender].userAdd=msg.sender;
        contractTotalAmountSwapped+=amount;
        emit SwapDeposit(msg.sender,amount);
        
    }
    
    function totalAmountSwappedInContract(address _user) public view returns(uint256){
        return userDetails[_user].totalAmountSwapped;
    }
    
    function grossAmountSwapped() public view returns(uint256){
        return contractTotalAmountSwapped;
    }
    
    //allow the owner to activate the escrow contract
    function openEscrow() public onlyOwner hasActiveSwap returns(bool){
        isActive=true;
    }
    
     //allow the owner to deactivate the escrow contract
    function closeEscrow() public onlyOwner returns(bool){
        isActive=false;
    }

  //allow owner to rescue any tokens sent to the contract

    function transferOut(address _token) public onlyOwner returns(bool){
        IERC20 token= IERC20(_token); 
        uint256 balance= token.balanceOf(address(this));
        require(token.transfer(msg.sender,balance),"HydroSwap: Token Transfer error");
    return true;
    }
    
 
      /**
    
    !!!!!!!!!!!!!!!!!!
    !!!!!CAUTION!!!!!!
    !!!!!!!!!!!!!!!!!!
    
    **/
    //allow owner to change central wallet
    
    function changeCentralWallet(address _newWallet) public onlyOwner returns(bool){
        require(_newWallet!=address(0),"Error: Burn address not supported");
        Main_ADDRESS=_newWallet;
        return true;
    }
  
}