// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStaking.sol";
import "./management/ManagedUpgradeable.sol";
import "./management/Constants.sol";
import "./libraries/DecimalsConverter.sol";

contract GenesisStaking is IStaking, ManagedUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    address[] public _rewardTokenAddress;
    mapping(address => RewardInfo) public rewardsInfo;

    string internal _name;
    bool internal _canTakeReward;
    bool internal _isPrivate;
    bool internal _isKYC;
    uint256 internal _startBlock;
    uint256 internal _totalStaked;
    uint256 internal _rewardEndBlock;
    uint256 internal _lastUpdateBlock;
    uint256 internal _depositFee;
    address internal _stakedToken;
    address payable internal _tresuary;

    mapping(address => uint256) internal _tokensDecimals;
    mapping(address => uint256) internal _rewardTokenAddressIndex;
    mapping(address => uint256) internal _staked;

    modifier updateRewards(address _recipient) {
        _updateRewards(_recipient);
        _;
    }

    modifier canHarvest() {
        require(_canTakeReward, "GS: It is not allowed to take the reward");
        _;
    }

    modifier canStake(
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        if (_isPrivate) {
            _hasPermission(_msgSender(), WHITELISTED_PRIVATE);
        }
        if (_isKYC) {
            require(
                management.isKYCPassed(_msgSender(), _deadline, _v, _r, _s),
                "KYC not passed"
            );
        }
        _;
    }

    modifier requireAccess() {
        require(
            management.requireAccess(_msgSender(), address(this)),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    function initialize(
        address management_,
        string memory stakingName_,
        bool isETHStake_,
        bool isPrivate_,
        bool canTakeReward_,
        address stakedToken_,
        uint256 startBlock_,
        uint256 durationBlock_,
        uint256 depositFee_
    ) external initializer {
        require(
            isETHStake_ || stakedToken_ != address(0),
            "GS: not correct staked token address"
        );

        _name = stakingName_;
        _startBlock = startBlock_;
        _rewardEndBlock = startBlock_ + durationBlock_;
        _lastUpdateBlock = startBlock_;
        _isPrivate = isPrivate_;
        _canTakeReward = canTakeReward_;
        _depositFee = depositFee_;
        _stakedToken = stakedToken_;

        if (isETHStake_) {
            _tokensDecimals[stakedToken_] = 18;
        } else {
            _tokensDecimals[stakedToken_] = IERC20Metadata(stakedToken_)
                .decimals();
        }

        __Managed_init(management_);
        _setDependency();
    }

    function getBalanceInfo(address _recipient)
        external
        view
        returns (uint256 balance, uint256 poolShare)
    {
        balance = _staked[_recipient];
        poolShare = _totalStaked == 0
            ? 0
            : (balance * DECIMALS18) / _totalStaked;
    }

    function getFutureEarn(address _recipient, uint256 _blockPerDay)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory perDay,
            uint256[] memory perWeek,
            uint256[] memory perMonth,
            uint256[] memory perYear
        )
    {
        uint256 size = _rewardTokenAddress.length;
        tokens = new address[](size);
        perDay = new uint256[](size);
        perWeek = new uint256[](size);
        perMonth = new uint256[](size);
        perYear = new uint256[](size);

        uint256 blockNumber = block.number;
        uint256 blocksToEnd;
        if (blockNumber < _rewardEndBlock) {
            uint256 startBlock = blockNumber > _startBlock
                ? blockNumber
                : _startBlock;
            blocksToEnd = _rewardEndBlock - startBlock;
        }

        uint256 poolShare = _totalStaked == 0
            ? 0
            : (_staked[_recipient] * DECIMALS18) / _totalStaked;

        uint256 blocksPerDay = blocksToEnd > _blockPerDay
            ? _blockPerDay
            : blocksToEnd;
        uint256 blocksPerWeek = blocksPerDay * 7 > blocksToEnd
            ? blocksPerDay * 7
            : blocksToEnd;
        uint256 blocksPerMonth = blocksPerDay * 30 > blocksToEnd
            ? blocksPerDay * 30
            : blocksToEnd;
        uint256 blocksPerYear = blocksPerDay * 365 > blocksToEnd
            ? blocksPerDay * 365
            : blocksToEnd;
        for (uint256 i = 0; i < size; i++) {
            address token = _rewardTokenAddress[i];
            tokens[i] = token;
            uint256 rewardPerBlock = (rewardsInfo[token].rewardPerBlock *
                poolShare) / DECIMALS18;
            perDay[i] = rewardPerBlock * blocksPerDay;
            perWeek[i] = rewardPerBlock * blocksPerWeek;
            perMonth[i] = rewardPerBlock * blocksPerMonth;
            perYear[i] = rewardPerBlock * blocksPerYear;
        }
    }

    function getInfo()
        external
        view
        returns (
            string memory name,
            address stakedToken,
            uint256 startBlock,
            uint256 endBlock,
            bool canTakeRewards,
            bool isPrivate,
            bool isKYC,
            uint256 totalStaked,
            uint256 depositeFee
        )
    {
        name = _name;
        stakedToken = _stakedToken;
        startBlock = _startBlock;
        endBlock = _rewardEndBlock;
        canTakeRewards = _canTakeReward;
        isPrivate = _isPrivate;
        isKYC = _isKYC;
        totalStaked = _totalStaked;
        depositeFee = _depositFee;
    }

    function getRewardsPerBlockInfos()
        external
        view
        override
        returns (address[] memory rewardTokens, uint256[] memory rewardPerBlock)
    {
        uint256 size = _rewardTokenAddress.length;
        rewardTokens = new address[](size);
        rewardPerBlock = new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            address token = _rewardTokenAddress[i];
            rewardTokens[i] = token;
            rewardPerBlock[i] = rewardsInfo[token].rewardPerBlock;
        }
    }

    function getAvailHarvest(address _recipient)
        external
        view
        override
        returns (address[] memory tokens, uint256[] memory rewards)
    {
        uint256 length = _rewardTokenAddress.length;
        tokens = new address[](length);
        rewards = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address token = _rewardTokenAddress[i];
            RewardInfo storage info = rewardsInfo[token];
            uint256 newRewardPerTokenStore = _calculateNewRewardPerTokenStore(
                info
            );
            uint256 calculateRewards = info.rewards[_recipient] +
                ((newRewardPerTokenStore -
                    info.rewardsPerTokenPaid[_recipient]) *
                    _staked[_recipient]) /
                DECIMALS18;
            tokens[i] = token;
            rewards[i] = calculateRewards;
        }
    }

    function balanceOf(address _recipient)
        external
        view
        override
        returns (uint256)
    {
        return _staked[_recipient];
    }

    function setDepositeFee(uint256 amount_)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        _depositFee = amount_;
    }

    function setCanTakeReward(bool value_) external override requireAccess {
        _canTakeReward = value_;
    }

    function setDependency() external override {
        _setDependency();
    }

    function setPrivate(bool value_) external override requireAccess {
        _isPrivate = value_;
    }

    function setKYC(bool value_)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        _isKYC = value_;
    }

    function stakeETH(
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        require(_stakedToken == address(0), "is not eth staked");
        _stake(_msgSender(), msg.value, _deadline, _v, _r, _s);
    }

    function stake(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        require(_stakedToken != address(0), "is eth staked");
        _stake(_msgSender(), _amount, _deadline, _v, _r, _s);
    }

    function unstake(uint256 _amount)
        external
        override
        updateRewards(_msgSender())
    {
        require(_amount > 0, "GS: Amount should be greater than 0");
        require(
            _staked[_msgSender()] >= _amount,
            "GS: Insufficient staked amount"
        );

        _staked[_msgSender()] -= _amount;
        _totalStaked -= _amount;

        if (_stakedToken == address(0)) {
            payable(_msgSender()).sendValue(_amount);
        } else {
            IERC20(_stakedToken).safeTransfer(
                _msgSender(),
                DecimalsConverter.convertFrom18(
                    _amount,
                    _tokensDecimals[_stakedToken]
                )
            );
        }

        emit Withdrawn(_msgSender(), _amount);
    }

    function harvest() external override canHarvest {
        _harvest(_msgSender());
    }

    function harvestFor(address _recipient) external override canHarvest {
        _harvest(_recipient);
    }

    function setRewardEndBlock(uint256 rewardEndBlock_)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        _rewardEndBlock = rewardEndBlock_;
    }

    function addDurartion(uint256 _blockAmount) external {
        require(_blockAmount > 0, "Register: block amount can't be 0");

        for (uint256 i = 0; i < _rewardTokenAddress.length; i++) {
            RewardInfo storage info = rewardsInfo[_rewardTokenAddress[i]];
            address token = _rewardTokenAddress[i];
            if (info.rewardPerBlock > 0) {
                uint256 transferAmount = info.rewardPerBlock * _blockAmount;
                IERC20(token).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    DecimalsConverter.convertFrom18(
                        transferAmount,
                        _tokensDecimals[token]
                    )
                );
            }
        }

        _rewardEndBlock += _blockAmount;

        emit AddDuration(_blockAmount);
    }

    function setRewardSetting(
        address[] memory _rewardTokens,
        uint256[] memory _rewardPerBlock
    ) external override requireAccess updateRewards(address(0)) {
        require(
            _rewardTokens.length == _rewardPerBlock.length,
            "Incorrect reward"
        );

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            address token = _rewardTokens[i];
            uint256 decimals = IERC20Metadata(token).decimals();
            if (_rewardTokenAddressIndex[token] == 0) {
                _rewardTokenAddress.push(token);
                _rewardTokenAddressIndex[token] = _rewardTokenAddress.length;
                _tokensDecimals[token] = decimals;
            }
            RewardInfo storage rewType = rewardsInfo[token];
            uint256 needTransfer = _calculateNumberTokensNeedTransfer(
                token,
                _rewardPerBlock[i]
            );
            rewType.rewardPerBlock = _rewardPerBlock[i];

            IERC20(token).safeTransferFrom(
                _msgSender(),
                address(this),
                DecimalsConverter.convertFrom18(needTransfer, decimals)
            );
        }

        emit SetRewardSetting(_rewardTokens, _rewardPerBlock);
    }

    function _calculateNumberTokensNeedTransfer(
        address rewardToken,
        uint256 newRewardPerBlock
    ) internal view returns (uint256) {
        if (_rewardEndBlock < block.number) {
            return 0;
        }

        uint256 startBlock = block.number > _startBlock
            ? block.number
            : _startBlock;

        uint256 rewardPerBlock = rewardsInfo[rewardToken].rewardPerBlock;
        if (rewardPerBlock >= newRewardPerBlock) return 0;

        return
            (_rewardEndBlock - startBlock) *
            (newRewardPerBlock - rewardPerBlock);
    }

    function _setDependency() internal {
        _tresuary = payable(management.contractRegistry(ADDRESS_TRESUARY));
    }

    function _stake(
        address _addr,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal canStake(_deadline, _v, _r, _s) updateRewards(_addr) {
        require(_amount > 0, "GS: Amount should be greater than 0");

        uint256 fee;
        if (_depositFee > 0) {
            fee = (_amount * _depositFee) / PERCENTAGE_100;
            _amount = _amount - fee;
            if (_stakedToken == address(0)) {
                _tresuary.sendValue(fee);
            } else {
                IERC20(_stakedToken).safeTransferFrom(
                    _addr,
                    _tresuary,
                    DecimalsConverter.convertFrom18(
                        fee,
                        _tokensDecimals[_stakedToken]
                    )
                );
            }
        }

        if (_stakedToken != address(0)) {
            IERC20(_stakedToken).safeTransferFrom(
                _addr,
                address(this),
                DecimalsConverter.convertFrom18(
                    _amount,
                    _tokensDecimals[_stakedToken]
                )
            );
        }

        _staked[_addr] += _amount;
        _totalStaked += _amount;

        emit Staked(_addr, _amount, fee);
    }

    function _harvest(address _recipient) internal updateRewards(_recipient) {
        for (uint256 i = 0; i < _rewardTokenAddress.length; i++) {
            address token = _rewardTokenAddress[i];
            RewardInfo storage info = rewardsInfo[token];
            uint256 rewards = info.rewards[_recipient];
            if (rewards > 0) {
                info.rewards[_recipient] -= rewards;
                IERC20(token).safeTransfer(
                    _recipient,
                    DecimalsConverter.convertFrom18(
                        rewards,
                        _tokensDecimals[token]
                    )
                );
                emit RewardPaid(_recipient, token, rewards);
            }
        }
    }

    function _updateRewards(address _recipient) internal {
        for (uint256 i = 0; i < _rewardTokenAddress.length; i++) {
            RewardInfo storage info = rewardsInfo[_rewardTokenAddress[i]];
            uint256 newRewardPerTokenStore = _calculateNewRewardPerTokenStore(
                info
            );

            info.rewardPerTokenStore = newRewardPerTokenStore;

            if (_recipient != address(0)) {
                info.rewards[_recipient] +=
                    ((newRewardPerTokenStore -
                        info.rewardsPerTokenPaid[_recipient]) *
                        _staked[_recipient]) /
                    DECIMALS18;
                info.rewardsPerTokenPaid[_recipient] = newRewardPerTokenStore;
            }
        }
        _lastUpdateBlock = block.number;
    }

    function _calculateNewRewardPerTokenStore(RewardInfo storage info)
        internal
        view
        returns (uint256)
    {
        uint256 blockPassted = _calculateBlocksPassted();

        if (blockPassted == 0 || _totalStaked == 0)
            return info.rewardPerTokenStore;

        uint256 accumulativeRewardPerToken = (blockPassted *
            info.rewardPerBlock *
            DECIMALS18) / _totalStaked;
        return info.rewardPerTokenStore + accumulativeRewardPerToken;
    }

    function _calculateBlocksPassted() internal view returns (uint256) {
        uint256 fromBlock = block.number < _rewardEndBlock
            ? block.number
            : _rewardEndBlock;
        uint256 toBlock = _startBlock > _lastUpdateBlock
            ? _startBlock
            : _lastUpdateBlock;
        if (fromBlock > _startBlock && _lastUpdateBlock < _rewardEndBlock) {
            return fromBlock - toBlock;
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IStaking {
    event AddDuration(uint256 blockAmount);
    event Staked(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address token, uint256 reward);
    event WithdrawExtraTokens(
        address indexed user,
        address token,
        uint256 amount
    );

    event SetRewardSetting(address[] rewardToken, uint256[] rewardPerBlock);

    struct RewardInfo {
        uint256 rewardPerBlock;
        uint256 rewardPerTokenStore;
        mapping(address => uint256) rewardsPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    function balanceOf(address _recipient) external view returns (uint256);

    function getAvailHarvest(address recipient)
        external
        view
        returns (address[] memory tokens, uint256[] memory availRewards);

    function getRewardsPerBlockInfos()
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory rewardPerBlock
        );

    function setDependency() external;
    
    function stake(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function unstake(uint256 _amount) external;

    function harvest() external;

    function harvestFor(address _recipient) external;

    function setDepositeFee(uint256 amount_) external;

    function setCanTakeReward(bool value_) external;

    function setPrivate(bool value_) external;

    function setKYC(bool value_) external;

    function setRewardEndBlock(uint256 _rewardEndBlock) external;

    function setRewardSetting(
        address[] memory _rewardTokens,
        uint256[] memory _rewardPerBlock
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IManagement.sol";
import "./Constants.sol";

contract ManagedUpgradeable is OwnableUpgradeable {
    IManagement public management;

    modifier requirePermission(uint256 _permission) {
        require(_hasPermission(msg.sender, _permission), ERROR_ACCESS_DENIED);
        _;
    }

    modifier canCallOnlyRegisteredContract(uint256 _key) {
        require(
            msg.sender == management.contractRegistry(_key),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    function setManagementContract(address _management) external onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);

        management = IManagement(_management);
    }

    function __Managed_init(address _managementAddress) internal initializer {
        management = IManagement(_managementAddress);
        __Ownable_init();
    }

    function _hasPermission(address _subject, uint256 _permission)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permission);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 100 * DECIMALS18;
uint256 constant PERCENTAGE_1 = DECIMALS18;
uint256 constant MAX_FEE_PERCENTAGE = 99 * DECIMALS18;
bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;

string constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";
string constant ERROR_NO_CONTRACT = "ERROR_NO_CONTRACT";
string constant ERROR_NOT_AVAILABLE = "ERROR_NOT_AVAILABLE";

bytes32 constant KYC_CONTAINER_TYPEHASE = keccak256(
    "Container(address sender,uint256 deadline)"
);

address constant EMERGENCY_ADDRESS = 0x85CCc822A20768F50397BBA5Fd9DB7de68851D5B;

//permisionss
//WHITELIST
uint256 constant ROLE_ADMIN = 1;
uint256 constant ROLE_REGULAR = 5;

uint256 constant CAN_SET_KYC_WHITELISTED = 10;
uint256 constant CAN_SET_PRIVATE_WHITELISTED = 11;

uint256 constant WHITELISTED_KYC = 20;
uint256 constant WHITELISTED_PRIVATE = 21;

uint256 constant CAN_SET_REMAINING_SUPPLY = 29;

uint256 constant CAN_TRANSFER_NFT = 30;
uint256 constant CAN_MINT_NFT = 31;
uint256 constant CAN_BURN_NFT = 32;

uint256 constant REGISTER_CAN_ADD_STAKING = 43;
uint256 constant CAN_ADD_POOL = 45;
uint256 constant CAN_SET_POOL_OWNER = 46;
//REGISTER_ADDRESS
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKE_FACTORY = 2;
uint256 constant CONTRACT_NFT_FACTORY = 3;
uint256 constant CONTRACT_LIQUIDITY_MINING_FACTORY = 4;
uint256 constant CONTRACT_STAKING_REGISTER = 5;
uint256 constant CONTRACT_POOL_REGISTER = 6;

uint256 constant ADDRESS_TRESUARY = 10;
uint256 constant ADDRESS_FACTORY_SIGNER = 11;
uint256 constant ADDRESS_PROXY_OWNER = 12;
uint256 constant ADDRESS_MANAGED_OWNER = 13;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library DecimalsConverter {
    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount / (10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IManagement {
    event PoolOwnerSet(address indexed pool, address indexed owner, bool value);

    event PermissionsSet(
        address indexed subject,
        uint256[] indexed permissions,
        bool value
    );

    event UsersPermissionsSet(
        address[] indexed subject,
        uint256 indexed permissions,
        bool value
    );

    event PermissionSet(
        address indexed subject,
        uint256 indexed permission,
        bool value
    );

    event ContractRegistered(
        uint256 indexed key,
        address indexed source,
        address target
    );

    function isKYCPassed(
        address _recipient,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external view returns (bool);

    function requireAccess(address _sender, address _pool)
        external
        view
        returns (bool);

    function contractRegistry(uint256 _key)
        external
        view
        returns (address payable);

    function permissions(address _subject, uint256 _permission)
        external
        view
        returns (bool);

    function kycSigner() external view returns (address);

    function setPoolOwner(
        address _pool,
        address _owner,
        bool _value
    ) external;

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    ) external;

    function setPermissions(
        address _address,
        uint256[] calldata _permissions,
        bool _value
    ) external;

    function registerContract(uint256 _key, address payable _target) external;

    function setKycWhitelists(address[] calldata _address, bool _value)
        external;

    function setPrivateWhitelists(address[] calldata _address, bool _value)
        external;
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