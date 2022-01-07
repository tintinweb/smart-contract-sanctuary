/**
 *Submitted for verification at polygonscan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
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
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
    
    function percentageOf(uint a, uint b) internal pure returns (uint256) {
        require(b > 0);
        return a * b / 100;
    }
}


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
abstract contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract FeeSplitter is Context, ReentrancyGuard {
    using SafeMath for uint256;

    struct LogFund {
        address who;
        address recipient;
        uint amount;
        uint date;
    }

    address private usdc;
    uint[3] private sharePercentage = [10,40,50];
    address[2] private owner;
    mapping(address => uint) private shares;

    uint private fund;
    uint private totalWithdrawFund;
    LogFund[] private log;

    constructor(address _usdc) {
        usdc = _usdc;
        owner[0] = 0x6023bA00b59bd080770A6b35fC7CdB1cf853A9C5;
        owner[1] = 0xBF90AF3Ef59dD627f22bE64F2a08b2DB09bec8a3;
    }

    modifier onlyOwner() {
        require(owner[0] == _msgSender() || owner[1] == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier checkBalance() {
        require(hasBalance(), "Not enough balance");
        _;
    }

    function hasBalance() private view returns(bool) {
        uint balance = availableBalance();
        uint amountFund = balance.percentageOf(sharePercentage[0]);
        uint amountOwner1 = balance.percentageOf(sharePercentage[1]);
        uint amountOwner2 = balance.percentageOf(sharePercentage[2]);
        return amountFund > 0 && amountOwner1 > 0 && amountOwner2 > 0;
    }

    function withdrawFund(address recipient, uint amount) public onlyOwner nonReentrant {
        require(recipient != address(0), "can't withdraw to blackhole");
        require(amount > 0, "can't withdraw zero amount");
        distirbuteUSDC();
        require(fund >= amount, "exceeded amount");

        IERC20(usdc).transfer(recipient, amount);
        totalWithdrawFund = totalWithdrawFund.add(amount);
        fund = fund.sub(amount);

        LogFund memory item = LogFund(_msgSender(), recipient, amount, block.timestamp);
        log.push(item);
    }

    function withdrawERC20(address token) public onlyOwner nonReentrant {
        require(token != usdc, "can't withdraw usdc");

        uint balance = IERC20(token).balanceOf(address(this));
        uint amountOwner1 = balance.percentageOf(50);
        uint amountOwner2 = balance.sub(amountOwner1);

        IERC20(token).transfer(owner[0], amountOwner1);
        IERC20(token).transfer(owner[1], amountOwner2);
    }

    function distirbute() public onlyOwner nonReentrant checkBalance {
        distirbuteUSDC();
    }

    function distirbuteUSDC() private {
        uint balance = availableBalance();
        uint amountFund = balance.percentageOf(sharePercentage[0]);
        uint amountOwner1 = balance.percentageOf(sharePercentage[1]);
        uint amountOwner2 = balance.percentageOf(sharePercentage[2]);

        if(amountFund > 0 && amountOwner1 > 0 && amountOwner2 > 0) {
            uint totalAmount = amountFund + amountOwner1 + amountOwner2;
            if(totalAmount <= balance) {
                fund = fund.add(amountFund);
                withdrawUSDC(owner[0], amountOwner1);
                withdrawUSDC(owner[1], amountOwner2);
            }
        }
    }

    function withdrawUSDC(address recipient, uint amount) private {
        shares[recipient] = shares[recipient].add(amount);
        IERC20(usdc).transfer(recipient, amount);
    }

    function allOwners() public view returns (address[2] memory) {
        return owner;
    }

    function totalBalance() public view returns(uint) {
        return IERC20(usdc).balanceOf(address(this));
    }

    function availableBalance() public view returns(uint) {
        return totalBalance().sub(fund);
    }

    function fundBalance() public view returns(uint) {
        uint amountFund = availableBalance().percentageOf(sharePercentage[0]);
        return fund.add(amountFund);
    }

    function sharesByAddress(address _owner) public view returns(uint) {
        return shares[_owner];
    }

    function fundHistory(uint256 cursor) public view returns (LogFund[] memory result, uint256 nextCursor, bool endCursor) {

        uint256 length = 10;
        if (length > log.length - cursor) {
            length = log.length - cursor;
        }

        uint256 begin = log.length - cursor - 1;
        result = new LogFund[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = log[begin - i];
        }

        endCursor = log.length <= cursor + length;
        return (result, cursor + length, endCursor);
    }
}