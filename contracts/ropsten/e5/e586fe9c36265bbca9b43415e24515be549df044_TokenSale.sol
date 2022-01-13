/**
 *Submitted for verification at Etherscan.io on 2022-01-13
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


interface IToken {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract TokenSale {
    using SafeMath for uint256;

    uint256 public price;              // the price, in wei, per token
    address _owner;

//    uint256 public tokensSold;

//     event Sold(address buyer, uint256 amount);

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
    price = newBuyPrice;
  }

  // Guards against integer overflows
  function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    } else {
        uint256 c = a * b;
        assert(c / a == b);
        return c;
      }
   }

//     // @notice Buy tokens from contract by sending ether
//   function buy() payable public {
//     uint amount = msg.value.div(buyPrice);               // calculates the amount
//     itoken.transfer(msg.sender, amount);                  // makes the transfers
//   }
          

    function claim() public payable {
        uint256 amount = safeMultiply(msg.value,10**18);
        //uint256 finalAmount = amount.div(1 ether * price);
        uint256 finalAmount = amount.div(price);
        //itoken.transfer(msg.sender, finalAmount);
    }


    // function buyTokens(uint256 numberOfTokens) public payable {
    //     require(msg.value == safeMultiply(numberOfTokens, price));

    //     uint256 scaledAmount = safeMultiply(numberOfTokens,
    //         10 ** tokenContract.decimals());

    //     require(tokenContract.balanceOf(this) >= scaledAmount);

    //     emit Sold(msg.sender, numberOfTokens);
    //     tokensSold += numberOfTokens;

    //     require(tokenContract.transfer(msg.sender, scaledAmount));
    // }

    // function endSale() public {
    //     require(msg.sender == owner);

    //     // Send unsold tokens to the owner.
    //     require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));

    //     msg.sender.transfer(address(this).balance);
    // }
}