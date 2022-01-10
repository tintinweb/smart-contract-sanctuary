/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.6.2;

/**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Calculation error");
        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Calculation error");
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        require(b <= a,"Calculation error");
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a,"Calculation error");
        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b != 0,"Calculation error");
        return a % b;
    }
}

/**
 * @title IToken
 * @dev   Contract interface for token contract 
 */
abstract contract IToken {
    function balanceOf(address) public pure virtual returns (uint256);
    function allowance(address, address) public pure virtual returns (uint256);
    function transfer(address, uint256) public pure virtual returns (bool);
    function transferFrom(address, address, uint256) public pure virtual returns (bool);
    function approve(address , uint256) public pure  virtual returns (bool);
 }


/**
 * @title claim
 * @dev Claim Contract to swap exact token in reference to ETH  
 */
contract claim {

  using SafeMath for uint256;

  address private _owner;                                           // variable for Owner of the Contract.
  uint256 public buyPrice;

  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functionality of Constructor and Interface  
  * ---------------------------------------------------------------------------------------------------------------------------
  */
  
  // constructor to declare owner of the contract during time of deploy  
  constructor() public {
     _owner = msg.sender;
  }
  
  // Interface declaration for contract
  IToken itoken;

  /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Owner functions of get value, set value and other Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  /**
  * @dev get address of smart contract owner
  * @return address of owner
  */
  function getowner() public view returns (address) {
    return _owner;
  }

  /**
  * @dev modifier to check if the message sender is owner
  */
  modifier onlyOwner() {
    require(isOwner(),"You are not authenticate to make this transfer");
    _;
  }

  /**
  * @dev Internal function for modifier
  */
  function isOwner() internal view returns (bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Transfer ownership of the smart contract. For owner only
  * @return request status
  */
  function transferOwnership(address newOwner) public onlyOwner returns (bool){
    _owner = newOwner;
    return true;
  }
    
  // function to set Contract Address for Token Transfer Functions
  function setContractAddress(address tokenContractAddress) external onlyOwner returns(bool){
    itoken = IToken(tokenContractAddress);
    return true;
  }
  
  // @param newBuyPrice Price users can buy from the contract
  function setPrices(uint256 newBuyPrice) public {
    buyPrice = newBuyPrice;
  }

  // @notice Buy tokens from contract by sending ether
  function buy() payable public {
    uint amount = msg.value.div(buyPrice);               // calculates the amount
    itoken.transfer(msg.sender, amount);                  // makes the transfers
  }

  receive() external payable {}
  fallback() external payable {}
  
}