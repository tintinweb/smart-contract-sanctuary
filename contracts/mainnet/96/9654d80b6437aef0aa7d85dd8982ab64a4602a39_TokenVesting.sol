pragma solidity ^0.5.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title PartnersVesting
 * @dev A token holder contract that can release its token balance gradually at different vesting points
 */
contract TokenVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);

    // The token being vested
    IERC20 public _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _start;

    uint256 private _released = 0;
    uint256 private _amount = 0;
    uint256[] private _schedule;
    uint256[] private _percent;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param token ERC20 token which is being vested
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param amount Amount of tokens being vested
     * @param schedule array of the timestamps (as Unix time) at which point vesting starts
     * @param percent array of the percents which can be released at which vesting points
     */
    constructor (IERC20 token, address beneficiary, uint256 amount, uint256[] memory schedule,
        uint256[] memory percent) public {
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");

        require(schedule.length == percent.length, "TokenVesting: Incorrect release schedule");
        require(schedule.length <= 255);

        _token = token;
        _beneficiary = beneficiary;
        _amount = amount;
        _schedule = schedule;
        _percent = percent;

    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function totalAmount() public view returns (uint256) {
        return _amount;
    }

    /**
     * @return the amount of the token released.
     */
    function released() public view returns (uint256) {
        return _released;
    }

    /**
     * @return the vested amount of the token for a particular timestamp.
     */
    function vestedAmount(uint256 ts) public view returns (uint256) {
        int8 unreleasedIdx = _releasableIdx(ts);
        if (unreleasedIdx >= 0) {
            return _amount.mul(_percent[uint(unreleasedIdx)]).div(100);
        } else {
            return 0;
        }

    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        int8 unreleasedIdx = _releasableIdx(block.timestamp);

        require(unreleasedIdx >= 0, "TokenVesting: no tokens are due");

        uint256 unreleasedAmount = _amount.mul(_percent[uint(unreleasedIdx)]).div(100);

        _token.safeTransfer(_beneficiary, unreleasedAmount);

        _percent[uint(unreleasedIdx)] = 0;
        _released = _released.add(unreleasedAmount);

        emit TokensReleased(address(_token), unreleasedAmount);
    }

    /**
     * @dev Calculates the index that has already vested but hasn't been released yet.
     */
    function _releasableIdx(uint256 ts) private view returns (int8) {
        for (uint8 i = 0; i < _schedule.length; i++) {
            if (ts > _schedule[i] && _percent[i] > 0) {
                return int8(i);
            }
        }

        return -1;
    }

}
