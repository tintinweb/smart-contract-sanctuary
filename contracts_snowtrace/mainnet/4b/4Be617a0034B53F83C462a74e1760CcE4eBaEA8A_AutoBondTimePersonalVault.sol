// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (contracts/AutoBondTimePersonalVault.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "ITimeBondDepository.sol";
import "IJoeRouter01.sol";
import "ITimeAutoBondVault01.sol";

/**
 *  @title AutoBondPersonalVault
 *  @author pbnather
 *  @dev This contract allows for managing bonds in Wonderland.money for a single user.
 *
 *  User, aka `depositor`, sends TIME or MEMO to the contract, which can be managed by `manager` address.
 *  If estimated bond 5-day ROI is better than staking 5-day ROI, manager can create a bond.
 *  Estimated 5-day ROI assumes that claimable bond rewards are redeemed close to, but before, each TIME rebase.
 *
 *  Contract has price checks, so that the bond which yields worse estimated 5-day ROI than just staking MEMO
 *  will be reverted (it accounts for the fees and slippage taken).
 *  Manager has only access to functions allowing creating a bond, reedeming a bond, and staking TIME for MEMO.
 *  User has only access to functions allowing depositing, withdrawing, and redeeming a bond.
 *
 *  Fees are sent to `admin` on each bond redeem. Admin can also change the `manager` address.
 *
 *  NOTE: This contract needs to be deployed individually for each user, with `depositor` set for her address.
 */
contract AutoBondTimePersonalVault is ITimeAutoBondVault01 {
    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 indexed amount,
        address indexed bondedWith,
        uint256 indexed payout
    );
    event BondRedeemed(address indexed bondedWith, uint256 indexed payout);
    event BondingAllowed(bool indexed allowed);
    event AssetsStaked(uint256 indexed amount);
    event AssetsUnstaked(uint256 indexed amount);
    event ManagerChanged(
        address indexed oldManager,
        address indexed newManager
    );

    /* ======== STATE VARIABLES ======== */

    ITimeBondDepository public immutable mimBondDepository;
    ITimeBondDepository public immutable wethBondDepository;
    ITimeBondDepository public immutable timeMimLpBondDepository;
    IJoeRouter01 public immutable joeRouter;
    IStaking public immutable staking;
    IERC20 public immutable asset; // e.g. TIME
    IERC20 public immutable stakedAsset; // e.g. MEMO
    IERC20 public immutable mim;
    IERC20 public immutable weth;
    IERC20 public immutable timeMimJLP;
    address public immutable depositor; // address allowed to withdraw funds
    address public immutable admin; // address to send fees
    uint256 public immutable fee; // fee taken from each redeem
    address public manager; // address which can manage bonds
    bool public isBondingAllowed;

    /* ======== INITIALIZATION ======== */

    /**
     *  @dev `_argsIndex`:
     *  0 - asset
     *  1 - stakedAsset
     *  2 - mim
     *  3 - weth
     *  4 - timeMimJLP
     *  5 - depositor
     *  6 - admin
     *  7 - manager
     *  8 - joeRouter
     *  9 - staking
     *  10 - mimBondDepository
     *  11 - wethBondDepository
     *  12 - timeMimLpBondDepository
     */
    constructor(address[] memory _args, uint256 _fee) public {
        require(_args[0] != address(0));
        asset = IERC20(_args[0]);
        require(_args[1] != address(0));
        stakedAsset = IERC20(_args[1]);
        require(_args[2] != address(0));
        mim = IERC20(_args[2]);
        require(_args[3] != address(0));
        weth = IERC20(_args[3]);
        require(_args[4] != address(0));
        timeMimJLP = IERC20(_args[4]);
        require(_args[5] != address(0));
        depositor = _args[5];
        require(_args[6] != address(0));
        admin = _args[6];
        require(_args[7] != address(0));
        manager = _args[7];
        require(_args[8] != address(0));
        joeRouter = IJoeRouter01(_args[8]);
        require(_args[9] != address(0));
        staking = IStaking(_args[9]);
        require(_args[10] != address(0));
        mimBondDepository = ITimeBondDepository(_args[10]);
        require(_args[11] != address(0));
        wethBondDepository = ITimeBondDepository(_args[11]);
        require(_args[12] != address(0));
        timeMimLpBondDepository = ITimeBondDepository(_args[12]);
        require(_fee <= 50, "Fee cannot be greater than 0.5%");
        fee = _fee;
        isBondingAllowed = true;
    }

    modifier only(address _address) {
        require(msg.sender == _address);
        _;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function changeManager(address _address) external only(admin) {
        require(_address != address(0));
        address old = manager;
        manager = _address;
        emit ManagerChanged(old, _address);
    }

    /* ======== MANAGER FUNCTIONS ======== */

    function bondWithMim(uint256 _amount, uint256 _slippage)
        external
        override
        only(manager)
        returns (uint256)
    {
        return _bondWithToken(mim, mimBondDepository, _amount, _slippage);
    }

    function bondWithWeth(uint256 _amount, uint256 _slippage)
        external
        override
        only(manager)
        returns (uint256)
    {
        return _bondWithToken(weth, wethBondDepository, _amount, _slippage);
    }

    function bondWithTimeMimLP(uint256 _amount, uint256 _slippage)
        external
        override
        only(manager)
        returns (uint256)
    {
        require(
            isBondingAllowed,
            "Bonding not allowed, depositor action required"
        );
        _unstakeAssets(_amount);
        // Sell half TIME for MIM
        uint256 received = _sellAssetFor(mim, _amount / 2, _slippage);
        uint256 remaining = _amount - (_amount / 2);
        // Add liquidity
        uint256 usedAsset = _addLiquidityFor(mim, asset, received, remaining);
        // Bond with TIME-MIM LP
        uint256 lpAmount = timeMimJLP.balanceOf(address(this));
        uint256 payout = _bondWith(
            timeMimJLP,
            lpAmount,
            timeMimLpBondDepository
        );
        // Stake not used assets
        if (usedAsset < remaining) {
            stakeAssets(remaining - usedAsset);
        }

        require(
            isBondProfitable(_amount - remaining + usedAsset, payout),
            "Bonding rate worse than staking"
        );
        emit BondCreated(
            _amount - remaining + usedAsset,
            address(timeMimJLP),
            payout
        );
        return payout;
    }

    function stakeAssets(uint256 _amount) public override only(manager) {
        require(asset.balanceOf(address(this)) >= _amount, "Not enough tokens");
        asset.approve(address(staking), _amount);
        staking.stake(_amount, address(this));
        staking.claim(address(this));
        emit AssetsStaked(_amount);
    }

    /* ======== USER FUNCTIONS ======== */

    function allowBonding(bool _allow) external only(depositor) {
        require(isBondingAllowed != _allow, "State is the same");
        isBondingAllowed = _allow;
        emit BondingAllowed(_allow);
    }

    function withdraw(uint256 _amount, bool _staked) external only(depositor) {
        if (_staked) {
            require(
                stakedAsset.balanceOf(address(this)) >= _amount,
                "Not enough tokens"
            );
            stakedAsset.safeTransfer(depositor, _amount);
        } else {
            require(
                asset.balanceOf(address(this)) >= _amount,
                "Not enough tokens"
            );
            asset.safeTransfer(depositor, _amount);
        }
    }

    /**
     *  @notice Anybody can top up the vault, but only depositor will be able to withdraw.
     *  For personal vaults it's the same as sending stakedAsset to the contract address.
     */
    function deposit(uint256 _amount) external {
        require(
            stakedAsset.balanceOf(msg.sender) >= _amount,
            "Not enough tokens"
        );
        stakedAsset.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     *  @notice This function is callable by anyone just in case manager is not working.
     */
    function redeemMimBond() external override returns (uint256) {
        return _redeemBondFrom(mimBondDepository);
    }

    /**
     *  @notice This function is callable by anyone just in case manager is not working.
     */
    function redeemTimeMimLPBond() external override returns (uint256) {
        return _redeemBondFrom(timeMimLpBondDepository);
    }

    /**
     *  @notice This function is callable by anyone just in case manager is not working.
     */
    function redeemWethBond() external override returns (uint256) {
        return _redeemBondFrom(wethBondDepository);
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @dev this function checks if taken bond is profitable after fees.
     *  It estimates using precomputed magic number what's the minimum viable 5-day ROI
     *  (assmuing redeemeing before all the rebases), versus staking MEMO.
     */
    function isBondProfitable(uint256 _bonded, uint256 _payout)
        public
        view
        returns (bool _profitable)
    {
        uint256 bondingROI = ((10000 * _payout) / _bonded) - 10000; // 1% = 100
        (, uint256 stakingReward, , ) = staking.epoch();
        IMemories memories = IMemories(address(stakedAsset));
        uint256 circualtingSupply = memories.circulatingSupply();
        uint256 stakingROI = (100000 * stakingReward) / circualtingSupply;
        uint256 magicNumber = 2 * (60 + (stakingROI / 100));
        uint256 minimumBonding = (100 * stakingROI) / magicNumber;
        _profitable = bondingROI >= minimumBonding;
    }

    function PendingBondFor(ITimeBondDepository _depository)
        external
        view
        returns (uint256)
    {
        return _depository.pendingPayoutFor(address(this));
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _bondWithToken(
        IERC20 _token,
        ITimeBondDepository _depository,
        uint256 _amount,
        uint256 _slippage
    ) internal returns (uint256) {
        require(
            isBondingAllowed,
            "Bonding not allowed, depositor action required"
        );
        _unstakeAssets(_amount);
        uint256 received = _sellAssetFor(_token, _amount, _slippage);
        uint256 payout = _bondWith(_token, received, _depository);
        require(
            isBondProfitable(_amount, payout),
            "Bonding rate worse than staking"
        );
        emit BondCreated(_amount, address(_token), payout);
        return payout;
    }

    /**
     *  @dev This function swaps assets for sepcified token via TraderJoe.
     *  @notice Slippage cannot exceed 1.5%.
     */
    function _sellAssetFor(
        IERC20 _token,
        uint256 _amount,
        uint256 _slippage
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(asset);
        path[1] = address(_token);
        uint256[] memory amounts = joeRouter.getAmountsOut(_amount, path);
        require(_slippage <= 150, "Slippage greater than 1.5%");
        uint256 minOutput = (amounts[1] * (10000 - _slippage)) / 10000;
        asset.approve(address(joeRouter), _amount);
        uint256[] memory results = joeRouter.swapExactTokensForTokens(
            _amount,
            minOutput,
            path,
            address(this),
            block.timestamp + 60
        );
        return results[1];
    }

    /**
     *  @dev This function adds liquidity for specified tokens on TraderJoe.
     *  @notice This function tries to maximize usage of first token {_tokenA}.
     */
    function _addLiquidityFor(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) internal returns (uint256) {
        _tokenA.approve(address(joeRouter), _amountA);
        _tokenB.approve(address(joeRouter), _amountB);
        (, uint256 assetSent, ) = joeRouter.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amountA,
            _amountB,
            (_amountA * 995) / 1000,
            (_amountB * 995) / 1000,
            address(this),
            block.timestamp + 60
        );
        return assetSent;
    }

    /**
     * @dev This function adds liquidity for specified tokens on TraderJoe.
     */
    function _bondWith(
        IERC20 _token,
        uint256 _amount,
        ITimeBondDepository _depository
    ) internal returns (uint256 _payout) {
        _token.approve(address(_depository), _amount);
        uint256 maxBondPrice = _depository.bondPrice();
        _payout = _depository.deposit(_amount, maxBondPrice, address(this));
    }

    function _redeemBondFrom(ITimeBondDepository _depository)
        internal
        returns (uint256)
    {
        uint256 amount = _depository.redeem(address(this), true);
        uint256 feeValue = (amount * fee) / 10000;
        stakedAsset.safeTransfer(admin, feeValue);
        uint256 redeemed = amount - feeValue;
        emit BondRedeemed(address(_depository), redeemed);
        return redeemed;
    }

    function _unstakeAssets(uint256 _amount) internal {
        require(
            stakedAsset.balanceOf(address(this)) >= _amount,
            "Not enough tokens"
        );
        stakedAsset.approve(address(staking), _amount);
        staking.unstake(_amount, false);
        emit AssetsUnstaked(_amount);
    }

    /* ======== AUXILLIARY ======== */

    /**
     *  @notice allow anyone to send lost tokens (excluding asset and stakedAsset) to the admin
     *  @return bool
     */
    function recoverLostToken(IERC20 _token) external returns (bool) {
        require(_token != asset, "NAT");
        require(_token != stakedAsset, "NAP");
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(admin, balance);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (bool);

    function valueOf(address _token, uint256 _amount)
        external
        view
        returns (uint256 value_);
}

interface IBondCalculator {
    function valuation(address _LP, uint256 _amount)
        external
        view
        returns (uint256);

    function markdown(address _LP) external view returns (uint256);
}

interface IMemories {
    function circulatingSupply() external view returns (uint256);
}

interface IStaking {
    function epoch()
        external
        view
        returns (
            uint256 number,
            uint256 distribute,
            uint32 length,
            uint32 endTime
        );

    function claim(address _recipient) external;

    function stake(uint256 _amount, address _recipient) external returns (bool);

    function unstake(uint256 _amount, bool _trigger) external;
}

interface IStakingHelper {
    function stake(uint256 _amount, address _recipient) external;
}

interface ITimeBondDepository {
    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 minimumPrice; // vs principle value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint32 vestingTerm; // in seconds
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // Time remaining to be paid
        uint256 pricePaid; // In DAI, for front end viewing
        uint32 lastTime; // Last interaction
        uint32 vesting; // Seconds left to vest
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in seconds) between adjustments
        uint32 lastTime; // time when last adjustment made
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */
    function redeem(address _recipient, bool _stake) external returns (uint256);

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() external view returns (uint256);

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint256 _value) external view returns (uint256);

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() external view returns (uint256 price_);

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() external view returns (uint256 price_);

    /**
     *  @notice calculate current ratio of debt to Time supply
     *  @return debtRatio_ uint
     */
    function debtRatio() external view returns (uint256 debtRatio_);

    /**
     *  @notice debt ratio in same terms for reserve or liquidity bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns (uint256);

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() external view returns (uint256);

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() external view returns (uint256 decay_);

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor)
        external
        view
        returns (uint256 percentVested_);

    /**
     *  @notice calculate amount of Time available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_);

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or Time) to the DAO
     *  @return bool
     */
    function recoverLostToken(IERC20 _token) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (interfaces/ITimeAutoBondVault01.sol)

/**
 *  @title ITimeAutoBondVault01
 *  @author pbnather
 *
 *  This interface is meant to be used to interact with the vault contract
 *  by it's `manager`, wich manages bonding and redeeming operations.
 */
pragma solidity ^0.8.0;

interface ITimeAutoBondVault01 {
    function bondWithMim(uint256 _amount, uint256 _slippage)
        external
        returns (uint256);

    function bondWithWeth(uint256 _amount, uint256 _slippage)
        external
        returns (uint256);

    function bondWithTimeMimLP(uint256 _amount, uint256 _slippage)
        external
        returns (uint256);

    function stakeAssets(uint256 _amount) external;

    function redeemMimBond() external returns (uint256);

    function redeemWethBond() external returns (uint256);

    function redeemTimeMimLPBond() external returns (uint256);
}