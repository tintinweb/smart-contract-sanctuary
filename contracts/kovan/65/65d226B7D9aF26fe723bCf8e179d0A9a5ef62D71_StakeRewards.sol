//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20PermitUpgradeable as IERC20Permit} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../access/BumperAccessControl.sol";
import "../interfaces/IStakeChangedReceiver.sol";
 
/// @notice one user's stake information 
struct StakeInfo {
    uint amount;    // amount of tokens in stake
    uint lastCI;   
    uint64 start;
    uint16 option; // selected option
    bool autorenew; // if true user don't have to do anything for continue staking
    uint64 end;
    uint64 requestedAt;
    uint claimed;
}

/// @notice period option(period in days and percentage assign with period )
struct StakeOption {
    uint total;       // amounts of stakes in each option
    uint128 emission;          // calculated emission for each option
    uint index;             // cummulative index for each option
}

/// @title Solo-staking token contract
/// @notice Staking token for one of pre-defined periods with different rewards and bonus percentage.
contract StakeRewards is Initializable, BumperAccessControl {

    using SafeERC20 for IERC20;

    function multipliers() public pure returns (uint16[4] memory) 
    { 
        return [uint16(100), uint16(150), uint16(275), uint16(600) ]; 
    }

    function periods() public pure returns (uint32[4] memory) {
        return [uint32(0), uint32(30 days), uint32(60 days), uint32(90 days)];
    }

    // store information about users stakes
    mapping(address => StakeInfo[]) public usersStake;
    // store information about stake options
    StakeOption[] public stakeOptions;

    // total emission per second for all options (5000 BUMP / day)
    uint public constant totalEmissionPerSecond = uint(5000) * uint(10**18) / 24 / 60 / 60; 

    address public stakeToken; // address of token
    uint64 public unlockTimestamp; // timestamp where this contract will unlocked
    uint32 public constant withdrawWindow = 2 days; // withdraw window for autorenew option. 
    uint32 public constant cooldownPeriod = 10 days;
    uint public lastIndexTimestamp;

    // emitted when user successfuly staked tokens
    event Staked(address sender, uint256 amount, uint256 period, bool autorenew, uint timestamp, uint16 option);

    // emitted when user successfuly claimed tokens
    event Claimed(address sender, uint256 amount, uint timestamp, uint16 option);

    // emitted when user successfuly unstaked tokens
    event Withdrawn(address sender, uint256 amount, uint256 rewards, uint timestamp, uint16 option );

    // emitted when user successfuly requested withdraw
    event WithdrawRequested(address indexed sender, uint256 amount, uint256 timestamp, uint16 option );

    modifier unlocked() {
        require(unlockTimestamp < uint64(block.timestamp), "locked");
        _;
    }

    ///@notice Will initialize state variables of this contract
    /// @param _whitelistAddresses addresses who can govern this account
    /// @param _stakeToken is staked token address
    /// @param _unlockTimestamp timestamp of end public sale period
    function initialize(
        address[] calldata _whitelistAddresses,
        address _stakeToken,
        uint64 _unlockTimestamp
    ) external initializer {
        _BumperAccessControl_init(_whitelistAddresses);
        stakeToken = _stakeToken;
        unlockTimestamp = _unlockTimestamp;

        // create stake options (it can be change later by governance)
        stakeOptions.push(StakeOption(0, 0, 0)); //  0 days, 1
        stakeOptions.push(StakeOption(0, 0, 0)); // 30 days, 1.5
        stakeOptions.push(StakeOption(0, 0, 0)); // 60 days, 2.75
        stakeOptions.push(StakeOption(0, 0, 0)); // 90 days, 6
    }

    /// -------------------  EXTERNAL, PUBLIC, VIEW, HELPERS  -------------------
    /// @notice return all user stakes
    function getUserStakes(address _account)
        public
        view
        returns (StakeInfo[] memory)
    {
        return usersStake[_account];
    }

    /// @notice return stake options array
    function getStakeOptions() public view returns (StakeOption[] memory) {
        return stakeOptions;
    }

    /// @notice returns how many tokens free
    function freeAmount() public view returns (uint256) { 
        uint total;
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            total += stakeOptions[i].total;
        } 
        return
            IERC20(stakeToken).balanceOf(address(this)) - total;
    }

    /// -------------------  EXTERNAL, PUBLIC, STATE CHANGE -------------------
    /// @notice stake tokens for give option
    /// @param amount - amount of tokens
    /// @param option - index of the option in stakeOptions mapping
    /// @param autorenew - auto-renewal staking when its finished
    function stake(uint256 amount, uint16 option, bool autorenew) external unlocked {
        require(amount > 0, "!amount");
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);
        _stakeFor(amount, option, autorenew, msg.sender );
    }

    /// @notice special function for stake user token from whitelisted addresses (used for future integration with other contracts)
    /// @param amount - amount of tokens,
    /// @param option - index of the option in stakeOptions mapping
    /// @param account - address of user account
    /// @param autorenew - auto-renewal staking when its finished
    function stakeFor(
        uint256 amount,
        uint16 option,
        address account,
        bool autorenew
    ) external onlyGovernance {
        require(amount > 0, "!amount");
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);        
        _stakeFor(amount, option, autorenew, account);
    }

    /// @notice stake tokens using permit flow
    /// @param amount - amount of tokens,
    /// @param option - index of the option in stakeOptions mapping
    /// @param autorenew - auto-renewal staking when its finished
    /// @param deadline - deadline for permit    
    /// @param v - permit v
    /// @param r - permit r
    /// @param s - permit s
    function stakeWithPermit(
        uint256 amount,
        uint16 option,
        bool autorenew,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external unlocked {
        require(amount > 0, "!amount");
        IERC20Permit(stakeToken).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);
        _stakeFor(amount, option, autorenew, msg.sender);        
    }

    /// @notice internal function for stake logic implementation (without transfer tokens)
    /// @param amount - amount of tokens,
    /// @param option - index of the option in stakeOptions mapping
    /// @param account - address of user account
    function _stakeFor(
        uint256 amount,
        uint16 option,
        bool autorenew,
        address account
    ) internal {
        require(option < stakeOptions.length, "!option");

        _updateIndexes();

        StakeOption storage opt = stakeOptions[option];

        StakeInfo memory newStake = StakeInfo(
            amount,
            opt.index,
            uint64(block.timestamp),
            option,
            autorenew,
            autorenew ? 0 : uint64(block.timestamp + periods()[option]),
            0,
            0
        );

        usersStake[account].push(newStake);
        opt.total += amount;

        _updateEmissions();

        emit Staked(account, amount, periods()[option]/1 days, autorenew, block.timestamp, option );
    }

    /// @notice withdraw tokens
    /// @param stakeIndex - index in users stakes array
    function withdraw(uint16 stakeIndex) external unlocked {
        StakeInfo[] storage stakeInfoList = usersStake[msg.sender];       
        require(stakeInfoList.length > stakeIndex, "!index");

        _updateIndexes();

        StakeInfo memory s = stakeInfoList[stakeIndex];
        StakeOption storage opt = stakeOptions[s.option];
        (uint rewards, , bool withdrawable,) = calcRewards(s, opt);
        require(withdrawable, "!withdraw" );

        // reduce amount of option
        opt.total -= s.amount;

        // get amount to withdraw
        uint256 amountToWithdraw = s.amount + rewards;

        // remove stake from the user stakes array
        stakeInfoList[stakeIndex] = stakeInfoList[stakeInfoList.length - 1];
        stakeInfoList.pop();

        // transfer tokens to user
        IERC20(stakeToken).safeTransfer(msg.sender, amountToWithdraw);

        _updateEmissions();

        emit Withdrawn( msg.sender, s.amount, rewards, block.timestamp, stakeIndex );
    }

    /// @notice set autorenew
    function switchAutorenew(uint16 stakeIndex) external unlocked {
        StakeInfo[] storage stakeInfoList = usersStake[msg.sender];
        require(stakeInfoList.length > stakeIndex, "!index");
        StakeInfo storage s = stakeInfoList[stakeIndex];

        if (s.autorenew) {
            uint64 numOfperiods = uint64(block.timestamp - s.start) / periods()[s.option] + 1;
            s.end = s.start + numOfperiods * periods()[s.option];
            s.autorenew = false;     
        }
        else {
            require( block.timestamp < s.start + periods()[s.option], "end" );
            s.end = 0;
            s.autorenew = true;
        }
    }

    /// @notice claim rewards for the stake
    function claimRewards(uint16 stakeIndex) external unlocked {
        StakeInfo[] storage stakeInfoList = usersStake[msg.sender];
        require(stakeInfoList.length > stakeIndex, "!index");
        StakeInfo storage s = stakeInfoList[stakeIndex];

        StakeOption memory opt = stakeOptions[s.option];
        opt.index = calculateCumulativeIndex(s.option);
        (uint rewards, bool claimable, , ) = calcRewards(s, opt);
        require( claimable && rewards > 0, "!rewards" );

        s.claimed += rewards;

        IERC20(stakeToken).safeTransfer(msg.sender, rewards);

        emit Claimed(msg.sender, rewards, block.timestamp, stakeIndex );
    }
    
    /// @notice calculate rewards and check if user can claim/withdraw tokens
    function calcRewards(StakeInfo memory s, StakeOption memory opt) public view returns (uint rewards, bool claimable, bool withdrawable, uint endOfLastPeriod) {

        rewards = (opt.index - s.lastCI) * s.amount / 10**18; 

        if (periods()[s.option] == 0) { // flexible staking
            endOfLastPeriod = block.timestamp;
            claimable = rewards > 0;
            withdrawable = block.timestamp > (s.requestedAt + cooldownPeriod) && 
                block.timestamp < (s.requestedAt + cooldownPeriod + withdrawWindow);
        }
        else if (s.autorenew) { 
            uint numOfPeriods = (block.timestamp - s.start) / periods()[s.option];  
            endOfLastPeriod = s.start + (numOfPeriods * periods()[s.option]);
            withdrawable = block.timestamp > endOfLastPeriod && block.timestamp < endOfLastPeriod + withdrawWindow;
        }
        else { // no autorenew and option with lockup period
            endOfLastPeriod = s.end;

            if (block.timestamp > s.end) {
                uint extraTime = block.timestamp - s.end;
                uint extraRewards = rewards * extraTime / (s.end - s.start + extraTime);
                rewards -= extraRewards;
            }
            withdrawable = block.timestamp > s.end;
        }
        if (rewards > s.claimed)
            rewards -= s.claimed;
        else
            rewards = 0;
            
        claimable = rewards > 0;
    }
    
    /// @notice calculate rewards by index of stake
    function calcRewardsByIndex(uint16 stakeIndex) public view returns (uint rewards, bool claimable, bool withdrawable, uint endOfLastPeriod) {
        StakeInfo memory s = usersStake[msg.sender][stakeIndex];
        StakeOption memory opt = stakeOptions[ s.option ];
        opt.index = calculateCumulativeIndex(s.option);
        (rewards,claimable,withdrawable,endOfLastPeriod) = calcRewards( s, opt );
    }

    /// @notice Restake tokens of given stake to new stake with given option with or without rewards
    function restake(uint16 stakeIndex, uint16 option, bool withRewards, bool autorenew) external  unlocked
    {
        require(option < stakeOptions.length, "!option");
        require(stakeIndex < usersStake[msg.sender].length, "!index");

        _updateIndexes();

        StakeInfo memory s = usersStake[msg.sender][stakeIndex];
        StakeOption memory opt = stakeOptions[s.option];
        (uint rewards, , bool withdrawable, ) = calcRewards(s,opt);
        require(withdrawable, "!withdraw");

        stakeOptions[s.option].total -= s.amount;

        uint amount = s.amount + (withRewards ? rewards : 0);        
        StakeInfo memory newStake = StakeInfo(
            amount,
            stakeOptions[option].index,
            uint64(block.timestamp),
            option,
            autorenew,
            autorenew ? 0 : uint64( block.timestamp + periods()[s.option]),
            0,
            0
        );

        usersStake[msg.sender][stakeIndex] = newStake;

        stakeOptions[option].total += amount;

        if (!withRewards){
            IERC20(stakeToken).safeTransfer(msg.sender, rewards);
        }

        _updateEmissions();

        emit Staked(msg.sender, amount, periods()[newStake.option], autorenew, block.timestamp, option );        
    }

    /// @notice create a request to withdraw tokens from stake
    /// @dev must be call before withdraw function 
    function requestWithdraw(uint16 stakeIndex) external unlocked { 
        require(stakeIndex < usersStake[msg.sender].length, "!index");
        StakeInfo storage s = usersStake[msg.sender][stakeIndex];
        require(s.option == 0, "!option");
        require(block.timestamp > s.requestedAt + cooldownPeriod, "requested" );

        s.requestedAt = uint64(block.timestamp);

        emit WithdrawRequested(msg.sender, s.amount, block.timestamp, stakeIndex );
    }

    /// @notice calculate total weithed amount of tokens in all options
    function totalWeigthedAmount() public view returns (uint weithedAmountSum) {
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            weithedAmountSum += multipliers()[i] * stakeOptions[i].total;
        }
    }

    /// @notice calculate total amount of tokens in all options
    function totalAmount() public view returns (uint amount, uint weithedAmountSum) {
        weithedAmountSum = totalWeigthedAmount();
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            amount += stakeOptions[i].total;
        } 
    }
    /// @notice calculate current emission rate per second by staked amount of tokens (it can be more than fact emission because of users can unstake with delay)
    function _updateIndexes() internal {
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            stakeOptions[i].index = calculateCumulativeIndex(i);
        }
        lastIndexTimestamp = block.timestamp;
    }

    /// @notice calculate current emission rate per second by staked amount of tokens (it can be more than fact emission because of users can unstake with delay)
    function _updateEmissions() internal {
        uint weigthedAmountSum = totalWeigthedAmount();
        uint16[4] memory m = multipliers();
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            StakeOption storage option = stakeOptions[i];
            if (weigthedAmountSum > 0) {
                option.emission = uint64(totalEmissionPerSecond  * (option.total * m[i]) / weigthedAmountSum);
            }
            else 
                option.emission = 0;
        }
    }

    /// @notice Calculate cumulative index
    /// @param option option index
    function calculateCumulativeIndex(
        uint16 option
    ) public view returns (uint index) {
        StakeOption storage opt = stakeOptions[option];
        if (opt.total > 0) {
            index = opt.index + (block.timestamp - lastIndexTimestamp) * opt.emission * 10**18 /opt.total;
        } else {
            index = opt.index;
        }
    }

    /// @notice update unlock timestamp when the contract will go live
    function updateUnlockTimestamp(uint64 _timestamp) external onlyGovernance {
        require(_timestamp > 0, "!timestamp");
        unlockTimestamp = _timestamp;
    }

    /// @notice emergency withdraw tokens from the contract
    /// @param token - address of the token
    /// @param amount - amount to withdraw
    function withdrawExtraTokens(address token, uint256 amount)
        external
        onlyGovernance
    {
        if (token == stakeToken) {
            require(amount <= freeAmount(), "!free");
        }
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

///@title BumperAccessControl contract is used to restrict access of functions to onlyGovernance and onlyOwner.
///@notice This contains suitable modifiers to restrict access of functions to onlyGovernance and onlyOwner.
contract BumperAccessControl is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    ///@dev This stores if a particular address is considered as whitelist or not in form of mapping.
    mapping(address => bool) internal whitelist;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function _BumperAccessControl_init(address[] memory _whitelist)
        internal
        initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        ///Setting white list addresses as true
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    modifier onlyGovernance {
        require(whitelist[_msgSender()], "!whitelist");
        _;
    }

    modifier onlyGovernanceOrOwner {
        require(
            whitelist[_msgSender()] || owner() == _msgSender(),
            "!ownerOrWhitelist"
        );
        _;
    }

    ///@dev It sets this address as true in whitelist address mapping
    ///@param addr Address that is set as whitelist address
    function addAddressToWhitelist(address addr) external onlyOwner {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    ///@dev It sets passed address as false in whitelist address mapping
    ///@param addr Address that is removed as whitelist address
    function removeAddressFromWhitelist(address addr) external onlyOwner {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IStakeChangedReceiver {
  function notify(uint newEmissionPerBlock ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}