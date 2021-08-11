// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./libraries/AddressArray.sol";
import "./interfaces/ILfi.sol";
import "./interfaces/ILtoken.sol";
import "./interfaces/IDsecDistribution.sol";
import "./interfaces/IFarmingPool.sol";
import "./interfaces/ITreasuryPool.sol";

contract TreasuryPool is Pausable, ReentrancyGuard, ITreasuryPool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using AddressArray for address[];

    uint256 public constant ROUNDING_TOLERANCE = 9999999999 wei;

    uint256 public immutable lpRewardPerEpoch;
    uint256 public immutable teamRewardPerEpoch;
    address public immutable teamAccount;

    address public governanceAccount;
    address public lfiAddress;
    address public underlyingAssetAddress;
    address public ltokenAddress;
    address public dsecDistributionAddress;

    uint256 public totalUnderlyingAssetAmount = 0;
    uint256 public totalLtokenAmount = 0;

    address[] private _farmingPoolAddresses;
    uint256 public totalLoanedUnderlyingAssetAmount = 0;

    ILfi private _lfi;
    IERC20 private _underlyingAsset;
    ILtoken private _ltoken;
    IDsecDistribution private _dsecDistribution;

    constructor(
        address lfiAddress_,
        address underlyingAssetAddress_,
        address ltokenAddress_,
        address dsecDistributionAddress_,
        uint256 lpRewardPerEpoch_,
        uint256 teamRewardPerEpoch_,
        address teamAccount_
    ) {
        require(
            lfiAddress_ != address(0),
            "TreasuryPool: LFI address is the zero address"
        );
        require(
            underlyingAssetAddress_ != address(0),
            "TreasuryPool: underlying asset address is the zero address"
        );
        require(
            ltokenAddress_ != address(0),
            "TreasuryPool: LToken address is the zero address"
        );
        require(
            dsecDistributionAddress_ != address(0),
            "TreasuryPool: dsec distribution address is the zero address"
        );
        require(
            teamAccount_ != address(0),
            "TreasuryPool: team account is the zero address"
        );

        governanceAccount = msg.sender;
        lfiAddress = lfiAddress_;
        underlyingAssetAddress = underlyingAssetAddress_;
        ltokenAddress = ltokenAddress_;
        dsecDistributionAddress = dsecDistributionAddress_;
        lpRewardPerEpoch = lpRewardPerEpoch_;
        teamRewardPerEpoch = teamRewardPerEpoch_;
        teamAccount = teamAccount_;

        _lfi = ILfi(lfiAddress);
        _underlyingAsset = IERC20(underlyingAssetAddress);
        _ltoken = ILtoken(ltokenAddress);
        _dsecDistribution = IDsecDistribution(dsecDistributionAddress);
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "TreasuryPool: sender not authorized");
        _;
    }

    modifier onlyFarmingPool() {
        require(
            _farmingPoolAddresses.contains(msg.sender),
            "TreasuryPool: sender not a farming pool"
        );
        _;
    }

    function farmingPoolAddresses() external view returns (address[] memory) {
        return _farmingPoolAddresses;
    }

    function addLiquidity(uint256 amount) external override nonReentrant {
        require(amount != 0, "TreasuryPool: can't add 0");
        require(!paused(), "TreasuryPool: deposit while paused");

        uint256 ltokenAmount;
        uint256 length = _farmingPoolAddresses.length;
        if (length > 0) {
            uint256 totalBorrowerInterestEarning = 0;
            for (uint256 i = 0; i < length; i++) {
                IFarmingPool farmingPool =
                    IFarmingPool(_farmingPoolAddresses[i]);
                // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
                // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
                // slither-disable-next-line reentrancy-benign,calls-loop
                uint256 borrowerInterestEarning =
                    farmingPool.computeBorrowerInterestEarning();
                totalBorrowerInterestEarning = totalBorrowerInterestEarning.add(
                    borrowerInterestEarning
                );
            }
            ltokenAmount = _divExchangeRate(
                amount,
                totalBorrowerInterestEarning
            );
        } else {
            ltokenAmount = amount;
        }

        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.add(amount);
        totalLtokenAmount = totalLtokenAmount.add(ltokenAmount);

        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
        // slither-disable-next-line reentrancy-events
        emit AddLiquidity(
            msg.sender,
            underlyingAssetAddress,
            ltokenAddress,
            amount,
            ltokenAmount,
            block.timestamp
        );

        _underlyingAsset.safeTransferFrom(msg.sender, address(this), amount);
        _dsecDistribution.addDsec(msg.sender, amount);
        _ltoken.mint(msg.sender, ltokenAmount);
    }

    function removeLiquidity(uint256 amount) external override nonReentrant {
        uint256 totalUnderlyingAssetAvailable =
            getTotalUnderlyingAssetAvailableCore();

        require(amount != 0, "TreasuryPool: can't remove 0");
        require(!paused(), "TreasuryPool: withdraw while paused");
        require(
            totalUnderlyingAssetAvailable > 0,
            "TreasuryPool: insufficient liquidity"
        );
        require(
            _ltoken.balanceOf(msg.sender) >= amount,
            "TreasuryPool: insufficient LToken"
        );

        uint256 underlyingAssetAmount;
        uint256 length = _farmingPoolAddresses.length;
        if (length > 0) {
            underlyingAssetAmount = 0;
            uint256 totalBorrowerInterestEarning = 0;
            for (uint256 i = 0; i < length; i++) {
                IFarmingPool farmingPool =
                    IFarmingPool(_farmingPoolAddresses[i]);
                // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
                // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
                // slither-disable-next-line reentrancy-benign,calls-loop
                uint256 borrowerInterestEarning =
                    farmingPool.computeBorrowerInterestEarning();
                totalBorrowerInterestEarning = totalBorrowerInterestEarning.add(
                    borrowerInterestEarning
                );
            }
            underlyingAssetAmount = _mulExchangeRate(
                amount,
                totalBorrowerInterestEarning
            );
        } else {
            underlyingAssetAmount = amount;
        }
        if (
            _isRoundingToleranceGreaterThan(
                underlyingAssetAmount,
                totalUnderlyingAssetAvailable
            )
        ) {
            underlyingAssetAmount = totalUnderlyingAssetAvailable;
        }
        require(
            totalUnderlyingAssetAvailable >= underlyingAssetAmount,
            "TreasuryPool: insufficient liquidity"
        );

        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.sub(
            underlyingAssetAmount
        );
        totalLtokenAmount = totalLtokenAmount.sub(amount);

        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
        // slither-disable-next-line reentrancy-events
        emit RemoveLiquidity(
            msg.sender,
            ltokenAddress,
            underlyingAssetAddress,
            amount,
            underlyingAssetAmount,
            block.timestamp
        );

        _ltoken.burn(msg.sender, amount);
        _dsecDistribution.removeDsec(msg.sender, underlyingAssetAmount);
        _underlyingAsset.safeTransfer(msg.sender, underlyingAssetAmount);
    }

    function redeemProviderReward(uint256 fromEpoch, uint256 toEpoch)
        external
        override
    {
        require(fromEpoch <= toEpoch, "TreasuryPool: invalid epoch range");
        require(!paused(), "TreasuryPool: redeem while paused");

        uint256 totalRewardAmount = 0;
        for (uint256 i = fromEpoch; i <= toEpoch; i++) {
            // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            if (_dsecDistribution.hasRedeemedDsec(msg.sender, i)) {
                break;
            }

            // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            uint256 rewardAmount =
                _dsecDistribution.redeemDsec(msg.sender, i, lpRewardPerEpoch);
            totalRewardAmount = totalRewardAmount.add(rewardAmount);
        }

        if (totalRewardAmount == 0) {
            return;
        }

        emit RedeemProviderReward(
            msg.sender,
            fromEpoch,
            toEpoch,
            lfiAddress,
            totalRewardAmount,
            block.timestamp
        );

        _lfi.redeem(msg.sender, totalRewardAmount);
    }

    function redeemTeamReward(uint256 fromEpoch, uint256 toEpoch)
        external
        override
        onlyBy(teamAccount)
    {
        require(fromEpoch <= toEpoch, "TreasuryPool: invalid epoch range");
        require(!paused(), "TreasuryPool: redeem while paused");

        uint256 totalRewardAmount = 0;
        for (uint256 i = fromEpoch; i <= toEpoch; i++) {
            // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            if (_dsecDistribution.hasRedeemedTeamReward(i)) {
                break;
            }

            // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            _dsecDistribution.redeemTeamReward(i);
            totalRewardAmount = totalRewardAmount.add(teamRewardPerEpoch);
        }

        if (totalRewardAmount == 0) {
            return;
        }

        emit RedeemTeamReward(
            teamAccount,
            fromEpoch,
            toEpoch,
            lfiAddress,
            totalRewardAmount,
            block.timestamp
        );

        _lfi.redeem(teamAccount, totalRewardAmount);
    }

    function loan(uint256 amount) external override onlyFarmingPool() {
        require(
            amount <= getTotalUnderlyingAssetAvailableCore(),
            "TreasuryPool: insufficient liquidity"
        );

        totalLoanedUnderlyingAssetAmount = totalLoanedUnderlyingAssetAmount.add(
            amount
        );

        emit Loan(amount, msg.sender, block.timestamp);

        _underlyingAsset.safeTransfer(msg.sender, amount);
    }

    function repay(uint256 principal, uint256 interest)
        external
        override
        onlyFarmingPool()
    {
        if (
            _isRoundingToleranceGreaterThan(
                principal,
                totalLoanedUnderlyingAssetAmount
            )
        ) {
            principal = totalLoanedUnderlyingAssetAmount;
        }

        require(
            principal <= totalLoanedUnderlyingAssetAmount,
            "TreasuryPool: invalid amount"
        );

        uint256 totalAmount = principal.add(interest);
        totalLoanedUnderlyingAssetAmount = totalLoanedUnderlyingAssetAmount.sub(
            principal
        );
        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.add(interest);

        emit Repay(principal, interest, msg.sender, block.timestamp);

        _underlyingAsset.safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
    }

    function estimateUnderlyingAssetsFor(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        uint256 ltokenAmount;
        uint256 length = _farmingPoolAddresses.length;
        if (length > 0) {
            uint256 totalBorrowerInterestEarning = 0;
            for (uint256 i = 0; i < length; i++) {
                IFarmingPool farmingPool =
                    IFarmingPool(_farmingPoolAddresses[i]);
                // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
                // slither-disable-next-line calls-loop
                uint256 borrowerInterestEarning =
                    farmingPool.estimateBorrowerInterestEarning();
                totalBorrowerInterestEarning = totalBorrowerInterestEarning.add(
                    borrowerInterestEarning
                );
            }
            ltokenAmount = _divExchangeRate(
                amount,
                totalBorrowerInterestEarning
            );
        } else {
            ltokenAmount = amount;
        }

        return ltokenAmount;
    }

    function estimateLtokensFor(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        uint256 underlyingAssetAmount;
        uint256 length = _farmingPoolAddresses.length;
        if (length > 0) {
            uint256 totalBorrowerInterestEarning = 0;
            for (uint256 i = 0; i < length; i++) {
                IFarmingPool farmingPool =
                    IFarmingPool(_farmingPoolAddresses[i]);
                // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
                // slither-disable-next-line calls-loop
                uint256 borrowerInterestEarning =
                    farmingPool.estimateBorrowerInterestEarning();
                totalBorrowerInterestEarning = totalBorrowerInterestEarning.add(
                    borrowerInterestEarning
                );
            }
            underlyingAssetAmount = _mulExchangeRate(
                amount,
                totalBorrowerInterestEarning
            );
        } else {
            underlyingAssetAmount = amount;
        }

        return underlyingAssetAmount;
    }

    /**
     * @return The utilisation rate, it represents as percentage in 64.64-bit fixed
     *         point number e.g. 0x50FFFFFED35A2FA158 represents 80.99999993% with
     *         an invisible decimal point in between 0x50 and 0xFFFFFED35A2FA158.
     */
    function getUtilisationRate() external view override returns (uint256) {
        // https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        // slither-disable-next-line incorrect-equality
        if (totalUnderlyingAssetAmount == 0) {
            return 0;
        }

        // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
        // slither-disable-next-line too-many-digits
        require(
            totalLoanedUnderlyingAssetAmount <
                0x0010000000000000000000000000000000000000000,
            "TreasuryPool: overflow"
        );

        uint256 dividend = totalLoanedUnderlyingAssetAmount.mul(100) << 64;
        return dividend.div(totalUnderlyingAssetAmount);
    }

    function getTotalUnderlyingAssetAvailableCore()
        internal
        view
        returns (uint256)
    {
        return totalUnderlyingAssetAmount.sub(totalLoanedUnderlyingAssetAmount);
    }

    function getTotalUnderlyingAssetAvailable()
        external
        view
        override
        returns (uint256)
    {
        return getTotalUnderlyingAssetAvailableCore();
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "TreasuryPool: new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function addFarmingPoolAddress(address address_)
        external
        onlyBy(governanceAccount)
    {
        require(
            address_ != address(0),
            "TreasuryPool: address is the zero address"
        );
        require(
            !_farmingPoolAddresses.contains(address_),
            "TreasuryPool: address is already a farming pool"
        );

        _farmingPoolAddresses.push(address_);
    }

    function removeFarmingPoolAddress(address address_)
        external
        onlyBy(governanceAccount)
    {
        require(
            address_ != address(0),
            "TreasuryPool: address is the zero address"
        );

        uint256 index = _farmingPoolAddresses.indexOf(address_);
        require(
            index > 0,
            "TreasuryPool: address not an existing farming pool"
        );

        _farmingPoolAddresses.removeAt(index);
    }

    function pause() external onlyBy(governanceAccount) {
        _pause();
    }

    function unpause() external onlyBy(governanceAccount) {
        _unpause();
    }

    function _divExchangeRate(uint256 amount, uint256 borrowerInterestEarning)
        private
        view
        returns (uint256)
    {
        if (totalLtokenAmount > 0) {
            // amount/((totalUnderlyingAssetAmount+borrowerInterestEarning)/totalLtokenAmount)
            return
                amount.mul(totalLtokenAmount).div(
                    totalUnderlyingAssetAmount.add(borrowerInterestEarning)
                );
        } else {
            return amount;
        }
    }

    function _mulExchangeRate(uint256 amount, uint256 borrowerInterestEarning)
        private
        view
        returns (uint256)
    {
        if (totalLtokenAmount > 0) {
            // amount*((totalUnderlyingAssetAmount+borrowerInterestEarning)/totalLtokenAmount)
            return
                amount
                    .mul(
                    totalUnderlyingAssetAmount.add(borrowerInterestEarning)
                )
                    .div(totalLtokenAmount);
        } else {
            return amount;
        }
    }

    function _isRoundingToleranceGreaterThan(uint256 expected, uint256 actual)
        private
        pure
        returns (bool)
    {
        return expected > actual && expected.sub(actual) <= ROUNDING_TOLERANCE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;

library AddressArray {
    /**
     * Searches for the specified element and returns the one-based index of the first occurrence within the entire array.
     * @param array The array to search.
     * @param element The element to locate in the array.
     * @return The one-based index of the first occurrence of item within the entire arry, if found; otherwise, 0.
     */
    function indexOf(address[] storage array, address element)
        internal
        view
        returns (uint256)
    {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == element) {
                return i + 1;
            }
        }
        return 0;
    }

    /**
     * Determines whether an element is in the array.
     * @param array The array to search.
     * @param element The element to locate in the array.
     * @return true if item is found in the array; otherwise, false.
     */
    function contains(address[] storage array, address element)
        internal
        view
        returns (bool)
    {
        uint256 index = indexOf(array, element);
        return index > 0;
    }

    /**
     * Removes the element at the specified index of the array.
     * @param array The array to search.
     * @param index The one-based index of the element to remove.
     */
    function removeAt(address[] storage array, uint256 index) internal {
        require(index > 0, "AddressArray: index is one-based");

        uint256 length = array.length;
        require(index <= length, "AddressArray: index is greater than length");

        array[index - 1] = array[length - 1];
        array.pop();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILfi is IERC20 {
    function redeem(address to, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ILtoken {
    function mint(address to, uint256 token) external;

    function burn(address account, uint256 token) external;

    function balanceOf(address account) external view returns (uint256);

    function isNonFungibleToken() external pure returns (bool);

    function setTokenAmount(uint256 token, uint256 amount) external;

    function getTokenAmount(uint256 token) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IDsecDistribution {
    function addDsec(address account, uint256 amount) external;

    function hasRedeemedDsec(address account, uint256 epoch)
        external
        view
        returns (bool);

    function hasRedeemedTeamReward(uint256 epoch) external view returns (bool);

    function removeDsec(address account, uint256 amount) external;

    function redeemDsec(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) external returns (uint256);

    function redeemTeamReward(uint256 epoch) external;

    event DsecAdd(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount,
        uint256 timestamp,
        uint256 dsec
    );

    event DsecRemove(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount,
        uint256 timestamp,
        uint256 dsec
    );

    event DsecRedeem(
        address indexed account,
        uint256 indexed epoch,
        uint256 distributionAmount,
        uint256 rewardAmount
    );

    event TeamRewardRedeem(address indexed sender, uint256 indexed epoch);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IFarmingPool {
    function addLiquidity(uint256 amount) external;

    function removeLiquidity(uint256 amount) external;

    function liquidate(address account) external;

    function computeBorrowerInterestEarning()
        external
        returns (uint256 borrowerInterestEarning);

    function estimateBorrowerInterestEarning()
        external
        view
        returns (uint256 borrowerInterestEarning);

    function getTotalTransferToAdapterFor(address account)
        external
        view
        returns (uint256 totalTransferToAdapter);

    function getLoansAtLastAccrualFor(address account)
        external
        view
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        );

    function getPoolLoansAtLastAccrual()
        external
        view
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        );

    function needToLiquidate(address account, uint256 liquidationThreshold)
        external
        view
        returns (
            bool isLiquidate,
            uint256 accountRedeemableUnderlyingTokens,
            uint256 threshold
        );

    event AddLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        uint256 amount,
        uint256 receiveQuantity,
        uint256 timestamp
    );

    event RemoveLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        uint256 requestedAmount,
        uint256 actualAmount,
        uint256 adapterTransfer,
        uint256 loanPrincipalToRepay,
        uint256 payableInterest,
        uint256 taxAmount,
        uint256 receiveQuantity,
        uint256 outstandingInterest,
        uint256 timestamp
    );

    event LiquidateFarmer(
        address indexed account,
        address indexed underlyingAssetAddress,
        address indexed farmerAccount,
        uint256 requestedAmount,
        uint256 actualAmount,
        uint256 adapterTransfer,
        uint256 loanPrincipalToRepay,
        uint256 payableInterest,
        uint256 taxAmount,
        uint256 liquidationPenalty,
        uint256 receiveQuantity,
        uint256 outstandingInterest,
        uint256 timestamp
    );

    event ComputeBorrowerInterestEarning(
        uint256 borrowerInterestEarning,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ITreasuryPool {
    function estimateLtokensFor(uint256 amount) external view returns (uint256);

    function estimateUnderlyingAssetsFor(uint256 amount)
        external
        view
        returns (uint256);

    function getTotalUnderlyingAssetAvailable() external view returns (uint256);

    function getUtilisationRate() external view returns (uint256);

    function addLiquidity(uint256 amount) external;

    function loan(uint256 amount) external;

    function removeLiquidity(uint256 amount) external;

    function redeemProviderReward(uint256 fromEpoch, uint256 toEpoch) external;

    function redeemTeamReward(uint256 fromEpoch, uint256 toEpoch) external;

    function repay(uint256 principal, uint256 interest) external;

    event AddLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        address indexed ltokenAddress,
        uint256 underlyingAssetToken,
        uint256 ltokenAmount,
        uint256 timestamp
    );

    event Loan(uint256 amount, address operator, uint256 timestamp);

    event RemoveLiquidity(
        address indexed account,
        address indexed ltokenAddress,
        address indexed underlyingAssetAddress,
        uint256 ltokenToken,
        uint256 underlyingAssetAmount,
        uint256 timestamp
    );

    event RedeemProviderReward(
        address indexed account,
        uint256 indexed fromEpoch,
        uint256 indexed toEpoch,
        address rewardTokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event RedeemTeamReward(
        address indexed account,
        uint256 indexed fromEpoch,
        uint256 indexed toEpoch,
        address rewardTokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event Repay(
        uint256 principal,
        uint256 interest,
        address operator,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}