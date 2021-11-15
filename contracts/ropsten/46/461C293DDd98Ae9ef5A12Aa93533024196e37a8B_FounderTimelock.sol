// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FounderTimelock {
    address admin;
    uint256 public totalAllocated = 0;

    struct Founder {
        uint256 amountWithdrawn;
        uint256 totalAmountLocked;
    }

    mapping(address => Founder) public founders;

    uint256 public immutable start;
    uint256 public immutable totalAmountTimelocked = 50000000000000;
    uint256 public totalAmountWithdrawn = 0;

    mapping(uint256 => uint256) private percentageAvailableByDays;

    constructor() {
        start = block.timestamp;
        admin = msg.sender;
        _setWithdrawalSchedule();
    }

    function _setWithdrawalSchedule() internal {
        uint256 currentPercentage = 0;
        uint256 startDay = 7;

        while (currentPercentage <= 100) {
            percentageAvailableByDays[startDay] = currentPercentage += 10;
            startDay += 7;
        }
    }

    function addFounder(
        address _founderAddress,
        uint256 _amountLocked
    ) external {
        require(msg.sender == admin, "Caller must be admin");

        require(
            founders[_founderAddress].totalAmountLocked == 0,
            "Address has already been added"
        );

        require(_founderAddress != address(0), "Cannot add address(0)");

        require(
            (totalAllocated + _amountLocked) <= totalAmountTimelocked,
            "Suggested allocation exceeds amount in timelock"
        );

        founders[_founderAddress].totalAmountLocked = _amountLocked;
        founders[_founderAddress].amountWithdrawn = 0;

        totalAllocated += _amountLocked;
    }

    receive() external payable {}

    function withdraw(address token) external {
        require(
            founders[msg.sender].totalAmountLocked > 0,
            "only founder accessible"
        );

        require(token != address(0));

        require((block.timestamp >= start + 7 days),
            "should not be able to withdraw yet"
        );

        address owner = msg.sender;
        uint256 currentElapsedTime = block.timestamp - start;
        uint256 currentElapsedDays = (currentElapsedTime / 86400);

        uint256 standardWithdrawalDay =
                (currentElapsedDays - (7)) -
                ((currentElapsedDays - (7)) % 7) +
                (7);

        uint256 percentageAvailableToOwner = percentageAvailableByDays[standardWithdrawalDay];

        uint256 amountAvailableToOwner = ((percentageAvailableToOwner) *
            founders[msg.sender].totalAmountLocked) / 100;

        uint256 amountAvailableForWithdrawal = amountAvailableToOwner -
            founders[msg.sender].amountWithdrawn;

        require(
            amountAvailableForWithdrawal > 0,
            "Nothing available for withdrawal"
        );

        require(
            (amountAvailableForWithdrawal + totalAmountWithdrawn) <
                totalAmountTimelocked,
            "Claim more than amount designated for withdrawal"
        );

        IERC20(token).transfer(owner, amountAvailableForWithdrawal);
        totalAmountWithdrawn += amountAvailableForWithdrawal;
        founders[owner].amountWithdrawn += amountAvailableForWithdrawal;

    }

    // Functions for testing
    function checkFounderAllocation(address _founder)
        external
        view
        returns (uint256)
    {
        return founders[_founder].totalAmountLocked;
    }

    function checkAvailability(uint256 _daysElapsed)
        external
        view
        returns (uint256)
    {
            uint256 standardWithdrawalDay = (_daysElapsed - (7)) -
                ((_daysElapsed - (7)) % 7) +
                (7);
            return percentageAvailableByDays[standardWithdrawalDay];
    }

    function checkAmountAvailable(uint256 _percentAvailable)
        external
        view
        returns (uint256)
    {
        return
            (_percentAvailable * founders[msg.sender].totalAmountLocked) / 100;
    }

    function checkAmountWithdrawn() external view returns (uint256) {
        return founders[msg.sender].amountWithdrawn;
    }
}

// SPDX-License-Identifier: MIT

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

