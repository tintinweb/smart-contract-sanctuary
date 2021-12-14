/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// Send MATIC to BUY Vote Token - VTOK 
// Author: VTOK Development Team
// Ver 1.0
//
// Deployed to : 0x1ad6C04C30BF998A3748FDC8c0eB8D6312030788
// Symbol      : VTOK
// Name        : Vote Token Sale
// Total supply: 750,000,000
// Decimals    : 18
// Price : enter price while creating contract or set later
// Details of Contract : Users will be able to Redeem VTOK tokens by sending any Matic amount to contract.
// ------------------------------------------------------------------------------------------------------------


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract VTOK is Owned  {
    
   mapping(address => uint256) balances;
   mapping(address => mapping(address => uint)) allowed;
   //uint _totalSupply;
    
   event Transfer(address indexed from, address indexed to, uint tokens);

   function balanceOf(address tokenOwner) public constant returns (uint balance);

   // To release tokens to the address that have send ether.
   function releaseTokens(address _receiver, uint _amount) public;

   // To take back tokens after refunding ether.
   function refundTokens(address _receiver, uint _amount) public;
   
   function transfer(address to, uint tokens) public returns (bool);
   
   function transferFrom(address from, address to, uint tokens) public returns (bool success);

}

contract VTOKSale {
   
   using SafeMath for uint256;

   uint public redeemStart;
   uint public redeemEnd;
   uint public tokenRate;
   VTOK public token;   
   uint public fundingGoal;
   uint public tokensRedeemed;
   uint public etherRaised;
   address public owner;
   uint decimals = 18;

   event BuyTokens(address buyer, uint etherAmount);
   event Transfer(address indexed from, address indexed to, uint tokens);
   event BuyerBalance(address indexed buyer, uint buyermoney);
   event BuyerTokensAndRate(address indexed buyer, uint buyermoney, uint convertrate);
   event TakeTokensBack(address ownerAddress, uint quantity );
   
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

   

   constructor( uint _tokenRate, address _tokenAddress, uint _fundingGoal) public {

      require( _tokenRate != 0 &&
      _tokenAddress != address(0) &&
      _fundingGoal != 0);
     
      redeemStart = now;
      redeemStart = block.timestamp;
      
      redeemEnd = redeemStart + 4 weeks;
      tokenRate = _tokenRate;
      token = VTOK(_tokenAddress);
      fundingGoal = _fundingGoal;
      owner = msg.sender;
   }

   function () public payable {
      buy();
   }

   function buy() public payable {

      emit BuyTokens( msg.sender , msg.value);
	  
      require(msg.sender!=owner);
      require(etherRaised < fundingGoal);
      require(now < redeemEnd && now > redeemStart);
      uint tokensToGet;
      uint etherUsed = msg.value;
      tokensToGet = etherUsed.mul(tokenRate).div(10**18);

      owner.transfer(etherUsed);
      
      // transfer tokens
      token.transfer(msg.sender, tokensToGet);
      
      emit BuyerBalance(msg.sender, tokensToGet);
      emit BuyerTokensAndRate(msg.sender, tokensToGet, tokenRate);
      
      tokensRedeemed += tokensToGet;
      etherRaised += etherUsed;
   }
   
    function setRedeemEndDate(uint time) public onlyOwner {
        require(time>0);
        redeemEnd = time;
    }

    function getRedeemEndDate() public view returns (uint) {
      return redeemEnd;
    }
   
    function setFundingGoal(uint goal) public onlyOwner {
        fundingGoal = goal;
    }

    function getFundingGoal() public view returns (uint) {
     return fundingGoal;
   }
   
   function setTokenRate(uint tokenEthMultiplierRate) public onlyOwner {
        tokenRate = tokenEthMultiplierRate;
   }
   
   
   function getTokenRate() public view returns (uint) {
     return tokenRate;
   }
   function takeTokensBackAfterRedeemOver(uint quantity) public onlyOwner {
        token.transfer(owner, quantity);
        emit TakeTokensBack(owner, quantity);
   }
 }