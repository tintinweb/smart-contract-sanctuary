/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// File: contracts1/TokenSaleStorage.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract TokenSaleStorage {

    uint public startSale;
    uint public finishSale;
    //admin address
    address payable public admin;

    //Setup pool parametres

    
    address public tokenAddress;

    address public USDCAddress;
    
    uint public last;
    
    uint public tokenNumber;
    uint public basicPrice;


    mapping (uint => uint) internal tokenPrices;
    mapping (uint => uint) internal marketCap;

}

// File: contracts1/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts1/TokenSale.sol

pragma solidity ^0.6.12;



contract TokenSale is TokenSaleStorage {
    
    using SafeMath for uint;
    constructor() public {
        admin = msg.sender;
    }


    function setTokenAddress(address _tokenAddress) external 
    {
        require(msg.sender == admin,"Only admin can set parametres.");

        tokenAddress = _tokenAddress;
    }
    function setUSDCAddress(address _USDCAddress) external 
    {
        require(msg.sender == admin,"Only admin can set parametres.");

        USDCAddress = _USDCAddress;
    }

    function getTokenAddress() external  view returns(address)
    {
        return tokenAddress;
    }

    function getUSDCAddress() external  view returns(address)
    {
        return USDCAddress;
    }


    function getTokenPrices(uint blockNumb) external  view returns(uint)
    {   
        return tokenPrices[blockNumb];
    }
    
    function getMarketTokens(uint blockNumb) external  view returns(uint)
    {
        return marketCap[blockNumb];
    }



    function getTokenLastPrices() external  view returns(uint[] memory, uint[] memory)
    {
        uint currenBlock = getBlock();
        /*uint counter = startSale.sub(240);
        uint elementsNumber = currenBlock%240;
        if(elementsNumber > 2)
        {
            elementsNumber.sub(2);
            elementsNumber.add(580);
        }
        else
        {
            elementsNumber.mul(240);
        }
        uint[] memory returnPrices = new uint[](elementsNumber);
        uint[] memory returnBloks = new uint[](elementsNumber);
        uint elementCounter = 0;
        if(currenBlock.sub(481) > startSale.add(240))
        {  
            while(counter.add(240) < currenBlock.sub(481))
            {
                returnBloks[elementCounter] = counter;
                returnPrices[elementCounter] = tokenPrices[counter.add(240)];
                elementCounter++;
            }
        }
        for(counter = currenBlock.sub(481); counter < currenBlock; counter++)
        {
            returnBloks[elementCounter] = counter;
            returnPrices[elementCounter] = tokenPrices[counter];
        }*/
        uint blockNumb = finishSale.sub(startSale);
        uint[] memory returnPrices = new uint[](blockNumb.div(240));
        uint[] memory returnBloks = new uint[](blockNumb.div(240));
        
        uint counter = startSale;
        for(uint i = 0;i < 150; i++)
        {
            returnBloks[i] = counter;
            returnPrices[i] = tokenPrices[counter];
            counter = counter+=240;
        }

        return (returnBloks, returnPrices);
    }

    function getMarketLastTokens() external  view returns(uint[] memory, uint[] memory)
    {
        /*uint currenBlock = getBlock();
        uint counter = startSale.sub(240);
        uint elementsNumber = currenBlock%240;
        if(elementsNumber > 2)
        {
            elementsNumber.sub(2);
            elementsNumber.add(580);
        }
        else
        {
            elementsNumber.mul(240);
        }
        uint[] memory returnTokens = new uint[](elementsNumber);
        uint[] memory returnBloks = new uint[](elementsNumber);
        uint elementCounter = 0;
        if(currenBlock.sub(481) > startSale.add(240))
        {  
            while(counter.add(240) < currenBlock.sub(481))
            {
                returnBloks[elementCounter] = counter;
                returnTokens[elementCounter] = marketCap[counter.add(240)];
                elementCounter++;
            }
        }
        for(counter = currenBlock.sub(481); counter < currenBlock; counter++)
        {
            returnBloks[elementCounter] = counter;
            returnTokens[elementCounter] = marketCap[counter];
        }*/
        uint blockNumb = finishSale.sub(startSale);
        uint[] memory returnTokens = new uint[](blockNumb.div(240));
        uint[] memory returnBloks = new uint[](blockNumb.div(240));
        
        uint counter = startSale;
        for(uint i = 0;i < 150; i++)
        {
            returnBloks[i] = counter;
            returnTokens[i] = marketCap[counter];
            counter = counter+240;
        }


        return (returnBloks, returnTokens);
    }
    
    

    


    function setData() external 
    {
        uint tokenNumber_ = tokenNumber;
        uint baseSale = 17;
        uint basicPrice_ = basicPrice;
        uint counter = 0;
        uint block_ = last;
        
        for(;counter < 100; counter++)
        {
            
            tokenNumber_ = tokenNumber_.sub(baseSale.mul((counter%4+1).mul(240)));
            marketCap[block_] = tokenNumber_;
           
            basicPrice_ = basicPrice_.sub((1e13*(counter%5+1)).mul(240));
            tokenPrices[block_] = basicPrice_;
            block_ = block_.add(240);
        }
        last = block_;
        tokenNumber = tokenNumber_;
        basicPrice = basicPrice_;
    }



    function setTimeStamps(uint startSale_, uint finishSale_) external 
    {

        require(msg.sender == admin,"Only admin can set parametres.");
        startSale = startSale_;
        finishSale = finishSale_;
        last = startSale_;
        tokenNumber = 7000000;
        basicPrice = 38e17;
    }


    function getTimeStamps() external  view returns(uint, uint)
    {
        return (startSale, finishSale);
    }
    
    
    function getBlock() internal view returns(uint)
    {
        return block.number;
    }

}