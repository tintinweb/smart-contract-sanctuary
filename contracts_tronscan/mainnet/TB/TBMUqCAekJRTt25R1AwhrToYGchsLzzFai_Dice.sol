//SourceUnit: Dice_flattened.sol

pragma solidity ^0.5.4;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address payable private _owner;
    mapping(address => bool) private _owners;
    event OwnershipGiven(address indexed newOwner);
    event OwnershipTaken(address indexed previousOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address payable msgSender = msg.sender;
        _addOwnership(msgSender);
        _owner = msgSender;
        emit OwnershipGiven(msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() private view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner 1");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _owners[msg.sender];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function addOwnership(address payable newOwner) public onlyOwner {
        _addOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _addOwnership(address payable newOwner) private {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipGiven(newOwner);
        _owners[newOwner] = true;
    }

    function _removeOwnership(address payable __owner) private {
        _owners[__owner] = false;
        emit OwnershipTaken(__owner);
    }

    function removeOwnership(address payable __owner) public onlyOwner {
        _removeOwnership(__owner);
    }
}


pragma solidity ^0.5.4;

interface IRouter {
    function processGameResult(
        bool win,
        address token_,
        uint wager,
        uint val,
        address  payable player,
        address refAddr
    ) payable external;

    function callByGame(
        address[] calldata players,
        uint[] calldata revenues
    ) external;
}


pragma solidity ^0.5.4;


/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


pragma solidity ^0.5.4;


contract ITRC20List is Ownable {
    event EnableToken(address token_, uint256 ratio_);
    event DisableToken(address token_);
    function enableToken(address token_, uint256 ratio_) public;
    function disableToken(address token_) public;
    function getRationDecimals() public view returns (uint256);
    function isTokenEnabled(address token_) public view returns (bool);
    function getRatioTrx(address token_) public view returns (uint256);
    function getElementOfEnabledList(uint index_) public view returns (address);
    function getSizeOfEnabledList() public view returns (uint256);
    function tokenToSun(address token_, uint256 amount_) public view returns (uint256);
}

pragma solidity ^0.5.4;




contract TRC20Holder is Ownable {
    ITRC20List whiteList;

    function setTRC20List(address whiteList_) public onlyOwner {
        whiteList = ITRC20List(whiteList_);
    }

    function getTRC20List() external view returns (address) {
        return address(whiteList);
    }

    modifier onlyEnabledToken(address token_) {
        require(address(whiteList) != address(0), "You must set address of token");
        require(whiteList.isTokenEnabled(token_), "This token not enabled");
        _;
    }

    function getTokens(address token_, uint256 amount_) internal onlyEnabledToken(token_) {
        require(ITRC20(token_).allowance(msg.sender, address(this)) >= amount_, "Approved less than need");
        bool res = ITRC20(token_).transferFrom(msg.sender, address(this), amount_);
        require(res);
    }

    function withdrawToken(address receiver_, address token_, uint256 amount_) internal onlyEnabledToken(token_) {
        require(ITRC20(token_).balanceOf(address(this)) >= amount_, "Can't make withdraw with this amount");
        bool res = ITRC20(token_).transfer(receiver_, amount_);
        require(res);
    }
}

pragma solidity ^0.5.4;


contract Limit is Ownable {
    uint256 private minBet;
    uint256 private maxBet;
    mapping (address => uint256) private minBetTRC20;
    mapping (address => uint256) private maxBetTRC20;

    constructor() public {
        minBet = 0;
        maxBet = 0;
    }

    function setMinBet(uint256 amount_) public onlyOwner {
        minBet = amount_;
    }

    function getMinBet() public view returns (uint256) {
        return minBet;
    }

    function setMaxBet(uint256 amount_) public onlyOwner {
        maxBet = amount_;
    }

    function getMaxBet() public view returns (uint256) {
        return maxBet;
    }

    modifier betInLimits() {
        if (minBet != maxBet) {
            require(msg.value >= minBet && msg.value <= maxBet, "Bet not in limits");
        }
        _;
    }

    function setMinBetTRC20(address token_, uint256 amount_) public onlyOwner {
        minBetTRC20[token_] = amount_;
    }

    function getMinBetTRC20(address token_) public view returns (uint256) {
        return minBetTRC20[token_];
    }

    function setMaxBetTRC20(address token_, uint256 amount_) public onlyOwner {
        maxBetTRC20[token_] = amount_;
    }

    function getMaxBetTRC20(address token_) public view returns (uint256) {
        return maxBetTRC20[token_];
    }

    modifier betInLimitsTRC20(address token_, uint256 amount_) {
        requireBetInLimitsTRC20(token_, amount_);
        _;
    }

    function requireBetInLimitsTRC20(address token_, uint256 amount_) internal {
        if (minBetTRC20[token_] != maxBetTRC20[token_]) {
            require(amount_ >= minBetTRC20[token_] && amount_ <= maxBetTRC20[token_], "Bet not in limits");
        }
    }
}

pragma solidity ^0.5.4;



contract OwnedByRouter is Ownable {
    address payable internal routerContract;
    modifier onlyRouter() {
        require(msg.sender == routerContract, "Router Ownable: caller is not the router");
        _;
    }

    function getRouter() public view returns (address router) {
        router = routerContract;
    }

    function setRouter(address payable _addr) public onlyOwner {
        removeOwnership(routerContract);
        routerContract = _addr;
        addOwnership(_addr);
    }
}


pragma solidity ^0.5.4;


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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


pragma solidity ^0.5.4;


contract Dice is TRC20Holder, Limit, OwnedByRouter {
    using SafeMath for *;
    event Result(address indexed player, uint indexed gameId, bool result, uint roll, uint var1, uint var2, uint wager, uint prize);
    event ResultTRC20(address indexed player, uint indexed gameId, bool result, uint roll, uint var1, uint var2, uint wager, uint prize, address token);

    uint public houseEdge;
    uint public gameRange;
    uint private gameId;

    constructor(address payable _routerContract) public {
        houseEdge = 100;
        gameRange = 10000;
        routerContract = _routerContract;
        gameId = 0;
    }

    function emitResult(address player, uint gameId, bool result, uint roll, uint var1, uint var2, uint wager, uint prize, address token) internal {
        if (token == address(0)) {
            emit Result(player, gameId, result, roll, var1, var2, wager, prize);
        } else {
            emit ResultTRC20(player, gameId, result, roll, var1, var2, wager, prize, token);
        }
    }

    function processGame(
        uint seed,
        uint var1,
        uint var2,
        address ref,
        address token,
        uint256 wager
    ) internal returns (uint) {
        uint256 range = var2 - var1;
        require(range >= 100 && range <= 9900, "Out of range");
        gameId = gameId.add(1);
        uint roll = getRandom(gameRange, seed);
        bool win = false;
        uint256 prize = 0;
        if (roll <= var2 && roll >= var1) {
            win = true;
            prize = wager.mul(gameRange.sub(houseEdge)).mul(gameRange).div(range).div(gameRange);
        }

        IRouter(routerContract).processGameResult(win, token, wager, prize, msg.sender, ref);
        emitResult(msg.sender, gameId, win, roll, var1, var2, wager, prize, token);
        return roll;
    }

    function GoodLuck(uint seed, uint var1, uint var2, address ref) public payable betInLimits returns (uint) {
        require(var1 < var2);
        require(msg.tokenid == 0 && msg.value > 0, "Require only TRX and balance not zero");
        routerContract.transfer(msg.value);
        return processGame(seed, var1, var2, ref, address(0), msg.value);
    }


    function GoodLuckTRC20(uint seed, uint var1, uint var2, address ref, address token, uint256 amount)
    external
    returns (uint) {
        require(var1 < var2);
        requireBetInLimitsTRC20(token, amount);
        getTokens(token, amount);
        withdrawToken(routerContract, token, amount);
        return processGame(seed, var1, var2, ref, token, amount);
    }

    function getRandom(uint256 gamerange, uint256 seed) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                now +
                block.difficulty +
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.coinbase
                        )
                    )
                ) +
                seed
            ))) % gamerange;
    }
}