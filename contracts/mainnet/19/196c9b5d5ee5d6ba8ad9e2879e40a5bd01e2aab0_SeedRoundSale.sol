/**
 *Submitted for verification at Etherscan.io on 2021-03-12
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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
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
        require(msg.sender == owner, "only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface IStakeContract{
    function StakeTokens(address _ofUser, uint256 _tokens) external returns(bool);
    function SetRewardClaimDate() external returns(bool);
}

contract SeedRoundSale is Owned{
    
    using SafeMath for uint256;
    
    uint256 private maxSaleAmount = 20000000 * 10 ** 18;
    bool sale;
    address private tokenAddress;
    address private stakingAddress;
    
    uint256 private minInvestment = 100000 * 10 ** 18;
    uint256 private maxInvestment = 2000000 * 10 ** 18;
    
    uint256 cliffPeriod = 365 days; //365 days;
    uint256 tokenUnLockDate;
    uint256 withdrawPeriod = 30 days;
    
    struct UserTokens{
        uint256 purchased;
        uint256 claimed;
    }
    mapping(address => UserTokens) public purchasedTokens;
    uint256 public totalTokensSold;
    
    AggregatorV3Interface internal ethPriceFeed;
    
    event SaleEnded(address by, uint256 unsoldTokens);
    event CliffStarted(address by);
    event TokensWithdraw(address by, uint256 tokens);
     
     /**
     * Network: Main Network
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor(address _tokenAddress, address _stakingAddress) public{
        tokenAddress = _tokenAddress;
        ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        stakingAddress = _stakingAddress;
        sale = true;
    }
    
    function EndSale() external onlyOwner{
        require(sale, "sale is already close");
        sale = false;
        
        // send the unsold tokens back to owner
        uint256 unsoldTokens = maxSaleAmount.sub(totalTokensSold);
        if(unsoldTokens > 0)
            IERC20(tokenAddress).transfer(tokenAddress, unsoldTokens);
            
        emit SaleEnded(msg.sender, unsoldTokens);
    }
    
    receive() external payable {
        uint256 tokens = getTokenAmount(msg.value);
        _preValidatePurchase(msg.sender, tokens);
        
        purchasedTokens[msg.sender].purchased = purchasedTokens[msg.sender].purchased.add(tokens);
        totalTokensSold = totalTokensSold.add(tokens);
        (bool success, ) = owner.call{value: msg.value}('');
        require(success, "ether transfer to owner unsuccessful");
        
        require(IStakeContract(stakingAddress).StakeTokens(msg.sender, tokens), "token stake unsuccessful");
    }
    
    function addFiatBuyers(address _buyer, uint256 tokens) external onlyOwner{
        _preValidatePurchase(_buyer, tokens);
        totalTokensSold = totalTokensSold.add(tokens);
        purchasedTokens[_buyer].purchased = purchasedTokens[_buyer].purchased.add(tokens);
        require(IStakeContract(stakingAddress).StakeTokens(_buyer, tokens), "token stake unsuccessful");
    }
    
    function _preValidatePurchase(address user, uint256 tokens) internal view{
        require(sale, "sale is closed");
        require(purchasedTokens[user].purchased.add(tokens) >= minInvestment, "below min limit");
        require(purchasedTokens[user].purchased.add(tokens) <= maxInvestment, "exceed max limit");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= maxSaleAmount, "insufficient balance of sale contract");
        require(totalTokensSold.add(tokens) <= maxSaleAmount, "insufficient balance of sale contract, try lesser investment");
    }
    
    function getTokenAmount(uint256 amount) public view returns(uint256){
        int latestPrice = getETHLatestPrice(); 
        latestPrice = latestPrice / 1e8; 
        
        uint256 scaling = 1e18;
        uint256 pointOneDollarsInEthers = (scaling).div(uint256(latestPrice).mul(10));//scaled
        
        return  ((amount.mul(scaling)).div(pointOneDollarsInEthers));
    }
    
    /**
     * Returns the latest price
     */
    function getETHLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethPriceFeed.latestRoundData();
        return price;
    }
    
    function StartCliff() external onlyOwner{
        require(tokenUnLockDate == 0, "cliff already started");
        tokenUnLockDate = block.timestamp.add(cliffPeriod);
        require(IStakeContract(stakingAddress).SetRewardClaimDate(), "failed to set reward claim date in staking");
        emit CliffStarted(msg.sender);
    }
    
    function withdrawTokens() external {
        require(block.timestamp >= tokenUnLockDate, "cliff period has not ended");
        require(tokenUnLockDate > 0, "cliff period has not started");
        
        uint256 monthsPassed = (block.timestamp.sub(tokenUnLockDate)).div(withdrawPeriod);
        if(monthsPassed > 12)
            monthsPassed = 12;
        uint256 allowedToWithdrawPerMonth = (purchasedTokens[msg.sender].purchased.mul(1e18)).div(12); //scaled
        uint256 availableToWithdrawNow = (allowedToWithdrawPerMonth.mul(monthsPassed)).div(1e18); // un-scaled
        availableToWithdrawNow = (availableToWithdrawNow).sub(purchasedTokens[msg.sender].claimed);
        require(availableToWithdrawNow > 0, "nothing pending to claim");
        purchasedTokens[msg.sender].claimed = purchasedTokens[msg.sender].claimed.add(availableToWithdrawNow);
        
        require(IERC20(tokenAddress).transfer(msg.sender, availableToWithdrawNow), "transfer of tokens from sale contract failed");
        emit TokensWithdraw(msg.sender, availableToWithdrawNow);
    }
    
    function availableToWithdraw(address _user) external view returns(uint256){
        if(tokenUnLockDate > 0 && block.timestamp >= tokenUnLockDate){
            uint256 monthsPassed = (block.timestamp.sub(tokenUnLockDate)).div(withdrawPeriod);
            if(monthsPassed > 12)
                monthsPassed = 12;
            uint256 allowedToWithdrawPerMonth = (purchasedTokens[_user].purchased.mul(1e18)).div(12); //scaled
            uint256 availableToWithdrawNow = (allowedToWithdrawPerMonth.mul(monthsPassed)).div(1e18); // un-scaled
            availableToWithdrawNow = (availableToWithdrawNow).sub(purchasedTokens[_user].claimed);
            return availableToWithdrawNow;
        }
        else{
            return 0;
        }
    }
}