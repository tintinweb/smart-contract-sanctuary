// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * @notice Copied from OpenZeppelin.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for vesting schedules with cliff period.
 */
contract Vesting {
    // ERC20 basic token contract being held
    IERC20 private _token;

    // Vesting struct to store address info
    struct VestingStruct {
        uint256 vestedTokens;
        uint256 cliffPeriod;
        uint256 vestingPeriod;
        uint256 vestingStartTime;
        uint256 withdrawalPerDay;
    }

    // Mapping to store Balance and Release Time of Beneficiary
    mapping(address => VestingStruct) public addressInfo;

    mapping(address => uint256) public tokensAlreadyWithdrawn;

    /**
     * @dev Triggers on new deposit call
     */
    event TokenVested(
        address beneficary,
        uint256 amount,
        uint256 cliffPeriod,
        uint256 vestingPeriod,
        uint256 vestingStartTime,
        uint256 withdrawalPerDay
    );

    /**
     * @dev Triggers on every release
     */
    event TokenReleased(address beneficary, uint256 amount);

    /**
     * @dev Sets the token address to be vested.
     *
     * token_ value is immutable: they can only be set once during
     * construction.
     */
    constructor(IERC20 token_) public {
        _token = token_;
    }

    /**
     * @return the token being held.
     */
    function token() external view returns (IERC20) {
        return _token;
    }

    /**
     * @return the total token stored in the contract
     */
    function totalTokensVested() external view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @notice Deposit tokens for vesting.
     * @param beneficiary The address, who can release token after vesting duration.
     * @param amount The amount of token to be locked.
     * @param vestingPeriod Must be in days.
     */
    function deposit(
        address beneficiary,
        uint256 amount,
        uint256 cliffPeriod,
        uint256 vestingPeriod
    ) external returns (bool success) {
        VestingStruct memory result = addressInfo[msg.sender];

        require(
            result.vestedTokens == 0,
            "Vesting: Beneficiary already have vested token. Use another address"
        );

        require(
            _token.transferFrom(msg.sender, address(this), amount),
            "Vesting: Please approve token first"
        );

        addressInfo[beneficiary] = VestingStruct(
            amount,
            cliffPeriod,
            vestingPeriod,
            block.timestamp,
            amount / vestingPeriod
        );

        emit TokenVested(
            beneficiary,
            amount,
            cliffPeriod,
            vestingPeriod,
            block.timestamp,
            amount / vestingPeriod
        );

        return true;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function withdraw() external virtual {
        VestingStruct memory result = addressInfo[msg.sender];

        require(
            result.vestedTokens > 0,
            "Vesting: You don't have any vested token"
        );

        require(
            block.timestamp >=
                (result.vestingStartTime + (result.cliffPeriod * 1 days)),
            "Vesting: Cliff period is not over yet"
        );

        uint256 tokensAvailable = getAvailableTokens(msg.sender);
        uint256 alreadyWithdrawn = tokensAlreadyWithdrawn[msg.sender];

        require(
            tokensAvailable + alreadyWithdrawn <= result.vestedTokens,
            "Vesting: Can't withdraw more than vested token amount"
        );

        if (tokensAvailable + alreadyWithdrawn == result.vestedTokens) {
            tokensAlreadyWithdrawn[msg.sender] = 0;
            addressInfo[msg.sender] = VestingStruct(0, 0, 0, 0, 0);
        } else {
            tokensAlreadyWithdrawn[msg.sender] += tokensAvailable;
        }

        emit TokenReleased(msg.sender, tokensAvailable);

        _token.transfer(msg.sender, tokensAvailable);
    }

    function getAvailableTokens(address beneficiary)
        public
        view
        returns (uint256)
    {
        VestingStruct memory result = addressInfo[beneficiary];

        if (result.vestedTokens > 0) {
            uint256 vestingEndTime =
                (result.vestingStartTime + (result.vestingPeriod * 1 days));

            if (block.timestamp >= vestingEndTime) {
                return
                    result.vestedTokens - tokensAlreadyWithdrawn[beneficiary];
            } else {
                uint256 totalDays =
                    ((
                        block.timestamp > vestingEndTime
                            ? vestingEndTime
                            : block.timestamp
                    ) - result.vestingStartTime) / 1 days;

                return
                    (totalDays * result.withdrawalPerDay) -
                    tokensAlreadyWithdrawn[beneficiary];
            }
        } else {
            return 0;
        }
    }
}

