/**
 *Submitted for verification at polygonscan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
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

contract MonsoonFinanceVesting {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public totalVesting = 13000000E18;                        // Total cash withdrawal to be withdrawn
    mapping(address => uint256) public drawData;                                                  // Withdrawal limit each time
    uint256 public constant dayTime = 86400 * 30;                                      // Every withdrawal interval 30 d
    mapping(address => uint256) public drawDay;                                                   // Withdrawal days
    mapping(address => uint256) public drawLastTime;                                              // Last withdrawal time
    uint256 public drawDayTotal;                                              // Total amount withdrawn
    uint256 public startDate;                                                 // Withdrawal start time
    mapping(address => uint256) public fixedCountToken;                                           // 8% = 20 * 00000 * 1e18
    bool public claimEnabled = false;
    address owner;
    uint public startBlock = block.timestamp;

    event ManagerFixedDraw(address indexed mananger, uint256 amount);
    event ManagerDraw(address indexed mananger, uint256 day, uint256 amount);

    constructor(address _token) public {
        token = IERC20(_token);
        startDate = block.timestamp+dayTime;
        owner = msg.sender;
        
        fixedCountToken[0x840f461D7826A6EaC3ba0Ff21c1bBEf4F775aa75] = 26144E18;
        drawData[0x840f461D7826A6EaC3ba0Ff21c1bBEf4F775aa75] = 33399E18;
        
        fixedCountToken[0x8D365687a75DC7688864822869ae0551Bb6fc105] = 13072E18;
        drawData[0x8D365687a75DC7688864822869ae0551Bb6fc105] = 16699E18;
        
        
        fixedCountToken[0x837a2Cea35c6C36d551899DDc656e152839000E2] = 78431E18;
        drawData[0x837a2Cea35c6C36d551899DDc656e152839000E2] = 100196E18;
        
        fixedCountToken[0xF78d4b28C975353aA6aE45c31471e8Ca8da0BA35] = 104575E18;
        drawData[0xF78d4b28C975353aA6aE45c31471e8Ca8da0BA35] = 133595E18;
        
        fixedCountToken[0x0d4eD61d464084F126bf93b4Cd868a7F177Fe901] = 26144E18;
        drawData[0x0d4eD61d464084F126bf93b4Cd868a7F177Fe901] = 33399E18;
        
        fixedCountToken[0x47B9251fc88F1A6372BBf6C3427834c5697D6fD3] = 52288E18;
        drawData[0x47B9251fc88F1A6372BBf6C3427834c5697D6fD3] = 66797E18;
        
        fixedCountToken[0x5fAFeC436B45a12Ff430804A644E68Cb012E5bD6] = 13072E18;
        drawData[0x5fAFeC436B45a12Ff430804A644E68Cb012E5bD6] = 16699E18;
        
        fixedCountToken[0x9343873867756F9E8Ca203b80b70097e222FDbB3] = 52288E18;
        drawData[0x9343873867756F9E8Ca203b80b70097e222FDbB3] = 66797E18;
        
        fixedCountToken[0x1231c9F171503cFefF56cD66E6dB29e573139E87] = 33987E18;
        drawData[0x1231c9F171503cFefF56cD66E6dB29e573139E87] = 43418E18;
        
        fixedCountToken[0xAe9Faecf214f54A748174003f7aCA7642A7396cE] = 5229E18;
        drawData[0xAe9Faecf214f54A748174003f7aCA7642A7396cE] = 6680E18;
        
        fixedCountToken[0x4cF9faf73714b65B98557c822B6B514dfDa0E339] = 52288E18;
        drawData[0x4cF9faf73714b65B98557c822B6B514dfDa0E339] = 66797E18;
        
        fixedCountToken[0x33ECdb74dd094ebf8cFFD0E934cCEC3BD48aFAec] = 52288E18;
        drawData[0x33ECdb74dd094ebf8cFFD0E934cCEC3BD48aFAec] = 66797E18;
        
        fixedCountToken[0x656416e3230836a817a543F70Cdd2C0Cfb4aC732] = 26144E18;
        drawData[0x656416e3230836a817a543F70Cdd2C0Cfb4aC732] = 33399E18;
        
        fixedCountToken[0xa2B9a5f796ef1f68B2aEF0c984F961beD1085500] = 15163E18;
        drawData[0xa2B9a5f796ef1f68B2aEF0c984F961beD1085500] = 19371E18;
        
        
    }

    function unlockedDate(address claimer) public view returns(uint256) {
        return block.timestamp.sub(drawLastTime[claimer]).div(dayTime);
    }

    function balanceOf() public view returns(uint256) {
        return token.balanceOf(address(this));
    }


    function fixedDrawDown() public {
        require(claimEnabled);
        require(fixedCountToken[msg.sender] > 0, "Insufficient fixed withdrawal limit");
        uint256 useDayBalance = _safeTransfer(fixedCountToken[msg.sender]);
        fixedCountToken[msg.sender] = 0;
        if(drawLastTime[msg.sender] == 0) {
            drawLastTime[msg.sender] = startBlock;
        }
        emit ManagerFixedDraw(msg.sender, useDayBalance);
    }

    function drawDown() public {
        require(block.timestamp >= startDate, "It's not time to unlock the transaction");
        uint256 day = unlockedDate(msg.sender);
        uint256 useDayBalance = 0;
        if(day > 0) {
            useDayBalance = day.mul(drawData[msg.sender]);
            useDayBalance = _safeTransfer(useDayBalance);
            drawDay[msg.sender] = drawDay[msg.sender].add(day);
            drawLastTime[msg.sender] = drawLastTime[msg.sender].add(day.mul(dayTime));
        }
        emit ManagerDraw(msg.sender, drawDay[msg.sender], useDayBalance);
    }

    function _safeTransfer(uint256 useDayBalance) private returns (uint256) {
        if(useDayBalance > balanceOf()) {
            useDayBalance = balanceOf();
        }
        require(useDayBalance > 0, "No available withdrawal limit");
        drawDayTotal = drawDayTotal.add(useDayBalance);
        token.transfer(msg.sender, useDayBalance);
        return useDayBalance;
    }
    
    function enableClaim() external {
        require(msg.sender == owner);
        claimEnabled = true;
    }
    
    function addVesting(address addr, uint firstClaim, uint eachClaim) external {
        require(msg.sender == owner);
        fixedCountToken[addr] = firstClaim;
        drawData[addr] = eachClaim;
        drawLastTime[addr] = block.timestamp;
    }
}