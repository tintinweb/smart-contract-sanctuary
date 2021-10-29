/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

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
}

contract MMPriceOracle {
    
    using SafeMath for uint256;
    
    struct Price {
        uint256 bnbPrice;
        uint256 usdPrice;
        uint40 time;
    }
    
    mapping(uint256 => Price) public prices;
    
    address private owner;
    address[] private allowedBots;
    uint256 private bnbPrice;
    uint256 private usdPrice;
    uint256 private updateCount;
    
    /**
     * @dev Emitted when price is updated.
     */
    event CurrentPriceUpdated(uint256 bnb, uint256 usd, uint40 time);
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner() == _msgSender(), "MMPriceOracle: Caller is not the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        bnbPrice = 0;
        usdPrice = 0;
        updateCount = 0;
        allowedBots.push(owner);
    }
    
    function setCurrentPrice(uint256 _bnbPrice, uint256 _usdPrice) external {
        require(this.checkInArray(msg.sender), "MMPriceOracle: Insufficient permission.");
        require(_bnbPrice > 0, "MMPriceOracle: BNB price must be non-zero");
        require(_usdPrice > 0, "MMPriceOracle: USD price must be non-zero");

        bnbPrice = _bnbPrice;
        usdPrice = _usdPrice;
        
        
        prices[updateCount].bnbPrice = bnbPrice;
        prices[updateCount].usdPrice = usdPrice;
        prices[updateCount].time = uint40(block.timestamp);
        
        updateCount++;
        

        emit CurrentPriceUpdated(_bnbPrice, _usdPrice, uint40(block.timestamp));
    }
    
    function checkInArray(address _addr) external view returns (bool){
        for(uint256 i = 0; i < allowedBots.length; i++){
            if(_addr == allowedBots[i]){
                return true;
            } 
        }
        return false;
    }
    
    function addAllowedBots(address _addr) external onlyOwner returns (bool){
        allowedBots.push(_addr);
        return true;
    }
    
    function removeAllowedBots(address _addr) external onlyOwner returns (bool){
        uint256 index = 0;
        
        for(uint256 i = 0; i < allowedBots.length; i++){
            if(allowedBots[i] == _addr){
                index = i;
            }
        }

        allowedBots[index] = allowedBots[allowedBots.length - 1];
        allowedBots.pop();
        return true;
    }
    
    /**
     * @dev Returns the address of the current owner.
     */
    function _owner() internal view virtual returns (address) {
        return owner;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    
    function getCurrentPrice() external view returns (uint256 bnb, uint256 usd) {
        bnb = bnbPrice;
        usd = usdPrice;
    }
    
    function getAveragePrice(uint40 start, uint40 end) external view returns (uint256 bnb, uint256 usd) {
        uint256 bnbSum = 0;
        uint256 usdSum = 0;
        uint256 range = 0;
        
        for(uint256 i = 0; i < updateCount; i++){
            if(prices[i].time >= start && prices[i].time <= end){
                bnbSum += prices[i].bnbPrice;
                usdSum += prices[i].usdPrice;
                range++;
            } 
        }
        
        bnb = bnbSum.div(range);
        usd = usdSum.div(range);
    }
    
    function getBots() external view returns (address[] memory bots) {
        return allowedBots;
    }
    
    /* to remove */
    
    function getBots1() external view returns (address[] memory bots) {
        return allowedBots;
    }
    
    function getBots2() external view returns (address[] memory bots) {
        return allowedBots;
    }
    
    function getBots3() external view returns (address[] memory bots) {
        return allowedBots;
    }
    
    function getBots4() external view returns (address[] memory bots) {
        return allowedBots;
    }
    
}