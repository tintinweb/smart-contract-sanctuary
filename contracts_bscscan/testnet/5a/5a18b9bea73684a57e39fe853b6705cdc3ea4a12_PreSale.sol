/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: UNLICENSED

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

    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return (a + m - 1) / m * m;
    }
}
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}
// ----------------------------------------------------------------------------
//BEP/ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
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
    function allowance(address owner, address spender) external view returns (uint256);

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

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PreSale is Owned {
    using SafeMath for uint256;
    uint256 public investedETH = 0;
    uint256 public saleEndDate;
    uint256 salePeriod = 2 days; //5 days;
    uint256 public SoftCap = 1 ether;
    uint256 public HardCap = 5 ether;
    uint256 decimals = 18;
    uint256 public purchasedTokens;
    address tokenAdd;
    uint256 public totalInvestors;
    uint256 public totalSaleTokens = 1500000 * 10 ** (18);
    
    struct users {
        uint256 amount;
        uint256 tokens;
    }
    mapping(address => users) public investors;
    
    event SaleEndDateUpdated(uint256 _newDate);
    
    modifier haveTokensInContract(){
        uint256 tokensInContract = IBEP20(tokenAdd).balanceOf(address(this));
        require(totalSaleTokens == tokensInContract, "tokens not available");
        _;
    }
    constructor(address _tokenAddress) public {
        owner = 0x22e8Fef88E50D07e2e2EB38D0B9bF11230F85905;
        saleEndDate = block.timestamp.add(salePeriod);
        tokenAdd = _tokenAddress;
    }
    
    function endSale() external {
        saleEndDate = block.timestamp;
    }
    
    receive() external payable{
        Invest();
    }
    
    function Invest() public payable haveTokensInContract{
        require(block.timestamp <= saleEndDate, "Sale closed");
        require(msg.value <= 5 ether, "exceed max limit allowed");
        
        if(investors[msg.sender].tokens == 0)
            totalInvestors = totalInvestors.add(1);
            
        investors[msg.sender].tokens = investors[msg.sender].tokens.add(getTokenAmount(msg.value));
        investors[msg.sender].amount = investors[msg.sender].amount.add(msg.value);
    }
    
    // it requires to set the end date of sale in unix timestamp
    function SetSaleEndDate(uint256 _newEndDate) external onlyOwner{
        saleEndDate = _newEndDate;
        emit SaleEndDateUpdated(_newEndDate);
    }

    function ClaimTokens() external {
        require(investors[msg.sender].amount > 0, "Sorry!, Not an investor");
        require(block.timestamp > saleEndDate, "Sale is not closed");
        if (investedETH >= SoftCap){ // Softcap
            require(IBEP20(tokenAdd).transfer(address(msg.sender), investors[msg.sender].tokens));
            investors[msg.sender].tokens = 0;
            investors[msg.sender].amount = 0;
        }
        else{
            payable(msg.sender).transfer(investors[msg.sender].amount);
            investedETH = investedETH.sub(investors[msg.sender].amount);
            investors[msg.sender].amount = 0;
            investors[msg.sender].tokens = 0;
        }
    }

    function getTokenAmount(uint256 amount) internal returns(uint256){
        // uint256 actualAmount = amount;
        uint256 amountThisBracket;
        uint256 tokens = 0;
        uint256 firstCap = 1 ether; // 0 - 1
        uint256 secondCap = 5 ether; // 2 - 5
        uint256 thirdCap = 8 ether; // 6 - 8
        uint256 firstCapRate = 3028;
        uint256 secondCapRate = 3014;
        uint256 thirdCapRate = 2999;

        if (investedETH < firstCap){
            if ((investedETH + amount) > firstCap){
                amount = (investedETH + amount) - firstCap;
                amountThisBracket = firstCap - investedETH;
                investedETH = firstCap;
                tokens += (firstCapRate * amountThisBracket);
            }
            else{
                tokens += (firstCapRate * amount);
            }
        }

        if ((investedETH >= firstCap) && (investedETH < secondCap)){
            if ((investedETH + amount) > secondCap ){
                amount = (investedETH + amount) - secondCap;
                amountThisBracket = secondCap - investedETH;
                investedETH = secondCap;
                tokens += secondCapRate * amountThisBracket;
            }
            else{
                tokens += secondCapRate * amount;
            }
        }

        if (investedETH >= secondCap && (investedETH < thirdCap)){
            if ((investedETH + amount) > thirdCap){
                amount = (investedETH + amount) - thirdCap;
                amountThisBracket = thirdCap - investedETH;
                investedETH = thirdCap;
                tokens += thirdCapRate * amountThisBracket;

            }
            else{
                tokens += thirdCapRate * amount;
            }
        }

        if (investedETH >= thirdCap){
            tokens +=  2884 * amount;
        }

        investedETH += amount;
        purchasedTokens = purchasedTokens.add(tokens);
        return tokens;
    }

    function ClaimFunds() onlyOwner external{
        require(block.timestamp > saleEndDate, "sale is not closed");
        require(investedETH >= SoftCap, "sale didn't reached soft cap");
        owner.transfer(address(this).balance);
    }
    
    function getUnSoldTokens() onlyOwner external{
        require(block.timestamp > saleEndDate, "sale is not closed");
        // check unsold tokens
        
        require(totalSaleTokens > purchasedTokens, "no unsold tokens in contract");
        uint256 unSoldTokens = totalSaleTokens.sub(purchasedTokens);
        if(investedETH < SoftCap)
            unSoldTokens = IBEP20(tokenAdd).balanceOf(address(this)); // send all tokens back if soft cap is not reached
        require(IBEP20(tokenAdd).transfer(owner, unSoldTokens), "transfer of token failed");
    }
    
    function isTokensClaimable(address _user) external view returns(bool){
        if(investors[_user].amount > 0 && block.timestamp > saleEndDate && investedETH >= SoftCap){
            return true;
        } else{
            return false;
        }
    }
    
    function isFundsRefundable(address _user) external view returns(bool){
        if(investors[_user].amount > 0 && block.timestamp > saleEndDate && investedETH < SoftCap){
            return true;
        } else{
            return false;
        }
    }

}