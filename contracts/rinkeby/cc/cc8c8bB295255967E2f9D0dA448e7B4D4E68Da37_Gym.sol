// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Gym {
    event LogWithdrawn(uint256 balance);
    event LogPayment(
        address client,
        address owner,
        uint256 day,
        uint256 amount
    );
    event LogRegisteredUnavailableDay(address owner, uint256 day);
    event LogUnregisteredUnavailableDay(address owner, uint256 day);

    address public owner;
    address public paymentToken;
    uint256 public paymentTraining;
    uint256 public maxClientsPerDay;

    mapping(uint256 => bool) public unavailableDaysMap;
    // start of day timestamp => clients that will have a training at that day
    mapping(uint256 => address[]) public trainingDaysMap;

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR::AUTH");
        _;
    }

    constructor(
        address owner_,
        address paymentToken_,
        uint256 paymentTraining_,
        uint256 maxClientsPerDay_
    ) {
        owner = owner_;
        paymentToken = paymentToken_;
        paymentTraining = paymentTraining_;
        maxClientsPerDay = maxClientsPerDay_;
    }

    function registerUnavailableDay(uint256 dayTimestamp) external onlyOwner {
        uint256 day = _getStartOfDay(dayTimestamp);

        require(
            !unavailableDaysMap[day],
            "ERROR::UNAVAILABLE_DAY_ALREADY_REGISTERED"
        );
        require(trainingDaysMap[day].length == 0, "ERROR::DAY_ALREADY_BOOKED");

        unavailableDaysMap[day] = true;

        emit LogUnregisteredUnavailableDay(msg.sender, day);
    }

    function unregisterUnavailableDay(uint256 dayTimestamp) external onlyOwner {
        uint256 day = _getStartOfDay(dayTimestamp);

        require(!!unavailableDaysMap[day], "ERROR::DAY_ALREADY_AVAILABLE");

        unavailableDaysMap[day] = false;

        emit LogUnregisteredUnavailableDay(msg.sender, day);
    }

    function pay(uint256 dayTimestamp) external {
        uint256 day = _getStartOfDay(dayTimestamp);

        require(!unavailableDaysMap[day], "ERROR::DAY_NOT_AVAILABLE");
        require(
            trainingDaysMap[day].length < maxClientsPerDay,
            "ERROR::DAY_ALREADY_MAX_CLIENTS"
        );
        require(
            !_hasClientOnDate(dayTimestamp, msg.sender),
            "ERROR:CLIENT_ALREADY_EXISTS"
        );

        trainingDaysMap[day].push(msg.sender);

        IERC20(paymentToken).transferFrom(
            msg.sender,
            address(this),
            paymentTraining
        );

        emit LogPayment(msg.sender, address(this), day, paymentTraining);
    }

    function withdraw() external onlyOwner {
        uint256 balance = IERC20(paymentToken).balanceOf(address(this));
        IERC20(paymentToken).transferFrom(address(this), owner, balance);
        emit LogWithdrawn(balance);
    }

    function canTrainToday(address client) external view returns (bool) {
        return _hasClientOnDate(block.timestamp, client);
    }

    function canTrainAtDate(address client, uint256 timestamp)
        external
        view
        returns (bool)
    {
        return _hasClientOnDate(timestamp, client);
    }

    function _getStartOfDay(uint256 timestamp) private pure returns (uint256) {
        uint256 secondsFromDayStart = timestamp % (60 * 60 * 24);
        return timestamp - secondsFromDayStart;
    }

    function _hasClientOnDate(uint256 timestamp, address client)
        private
        view
        returns (bool)
    {
        bool canTrain = false;

        uint256 day = _getStartOfDay(timestamp);
        for (uint256 i = 0; i < trainingDaysMap[day].length; i++) {
            if (trainingDaysMap[day][i] == client) {
                canTrain = true;
                break;
            }
        }

        return canTrain;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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