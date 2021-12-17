/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

 interface BEP20Interface {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function balanceOf(address account) external view returns (uint256);
}



contract EgonMigrate {
	using SafeMath for uint256;
	
	
	address payable ownerAddress;
    BEP20Interface public Egon1Address=BEP20Interface(0x8669CD3841029CdAa5AeD2880bbc24fb1FE6d296);
    BEP20Interface public Egon2Address = BEP20Interface(0x05995a068bdac17c582eC75AB46bb8e7394be1d9);
    BEP20Interface public EANAddress2=BEP20Interface(0xf711D680DD3e987B6bd24253931E5495C954b557);

    uint256 public priceInUsdt;
    
    struct PoolDetails
    {
        uint256 minInvestment;
        uint256 life_days;
        uint256 maturityPercentage;
    }

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 checkpoint;
	}
	
	mapping (address => bool) public isBlocked;
	bool public isRunningSwap=true;
    
	event buyEAN(address indexed user,uint256 priceInUsdt,uint256 tokens);

	constructor(address payable marketingAddr) {
       	ownerAddress = marketingAddr;
		priceInUsdt = 115000000;
	}
	

	/*******Swapping ********/
	  function setPrice(uint256 amount) public
    {
        require(msg.sender==ownerAddress,"Invalid user");
        require(amount>0,"Invalid amount or plan");
        priceInUsdt=amount;
    }
    
	
    function exchange(uint256 amount) public payable
    {
        
        require(amount>0,"Invalid Amount");
        address payable userAddress = payable(msg.sender);
            require(BEP20Interface(Egon1Address).transferFrom(userAddress,address(this),amount),"Token transfer failed");
            uint256 tokenAmount=amount.mul(priceInUsdt).div(1e18);
        require(BEP20Interface(address(Egon2Address)).transfer(address(userAddress),amount),"Token transfer failed");
        require(BEP20Interface(address(EANAddress2)).transfer(address(userAddress),tokenAmount),"Token transfer failed");
        
        emit buyEAN(userAddress,amount,tokenAmount);
       
    }
    
    function eanWithdrawal(address payable userAddress,uint256 amount) public 
    {
        require(msg.sender==ownerAddress,"Invalid user");
        require(BEP20Interface(address(Egon1Address)).transfer(address(userAddress),amount),"Token transfer failed");
    }
    
    function emtWithdrawal(address payable userAddress,uint256 amount) public 
    {
        require(msg.sender==ownerAddress,"Invalid user");
        require(BEP20Interface(address(Egon1Address)).transfer(address(userAddress),amount),"Token transfer failed");
    }

    function ean2Withdrawal(address payable userAddress,uint256 amount) public 
    {
        require(msg.sender==ownerAddress,"Invalid user");
        require(BEP20Interface(address(EANAddress2)).transfer(address(userAddress),amount),"Token transfer failed");
    }
    
   

}