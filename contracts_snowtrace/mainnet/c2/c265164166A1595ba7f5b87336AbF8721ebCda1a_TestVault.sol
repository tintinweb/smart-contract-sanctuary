// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (contracts/TestVault.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "Initializable.sol";
import "Ownable.sol";
import "ITimeBondDepository.sol";
import "IJoeRouter01.sol";
import "IBondingHQ.sol";
import "IPersonalVault.sol";
import "IwMEMO.sol";

contract TestVault is Initializable, Ownable, IPersonalVault {
    using SafeERC20 for IERC20;

    /* ======== STATE VARIABLES ======== */

    IERC20 public asset; // e.g. TIME
    IERC20 public stakedAsset; // e.g. MEMO
    IwMEMO public wrappedAsset; // e.g. wMEMO
    IStaking public stakingContract; // Staking contract
    IBondingHQ public bondingHQ; // Bonding HQ

    address public manager; // Address which can manage bonds
    address public admin; // Address to send fees
    address public feeHarvester;
    uint256 public fee; // Fee taken from each redeem
    uint256 public minimumBondDiscount; // 1% = 100
    bool public isManaged; // If vault is in managed mode

    mapping(address => BondInfo) public bonds;
    address[] public activeBonds;

    /* ======== STRUCTS ======== */

    struct BondInfo {
        uint256 payout; // Time remaining to be paid
        uint256 assetUsed; // Asset amount used
        uint256 vestingEndTime; // Timestamp of bond end
        uint256 maturing; // How much MEMO is maturing
    }

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 indexed amount,
        address indexed bondedWith,
        uint256 indexed payout
    );
    event BondingDiscountChanged(
        uint256 indexed oldDiscount,
        uint256 indexed newDiscount
    );
    event BondRedeemed(address indexed bondedWith, uint256 indexed payout);
    event AssetsStaked(uint256 indexed amount);
    event AssetsUnstaked(uint256 indexed amount);
    event Withdrawal(uint256 indexed amount);
    event Deposit(uint256 indexed amount);
    event ManagedChanged(bool indexed managed);
    event ManagerChanged(
        address indexed oldManager,
        address indexed newManager
    );
    event FeeHarvesterChanged(
        address indexed oldManager,
        address indexed newManager
    );

    /* ======== INITIALIZATION ======== */

    function init(
        address _bondingHQ,
        address _asset,
        address _stakedAsset,
        address _wrappedAsset,
        address _stakingContract,
        address _manager,
        address _admin,
        address _feeHarvester,
        uint256 _fee,
        uint256 _minimumBondDiscount,
        bool _isManaged
    ) external initializer {
        // require(_bondingHQ != address(0));
        // bondingHQ = IBondingHQ(_bondingHQ);
        require(_asset != address(0));
        asset = IERC20(_asset);
        require(_stakedAsset != address(0));
        stakedAsset = IERC20(_stakedAsset);
        require(_wrappedAsset != address(0));
        wrappedAsset = IwMEMO(_wrappedAsset);
        require(_stakingContract != address(0));
        stakingContract = IStaking(_stakingContract);
        require(_admin != address(0));
        admin = _admin;
        require(_manager != address(0));
        manager = _manager;
        require(_feeHarvester != address(0));
        feeHarvester = _feeHarvester;
        require(_fee < 10000, "Fee should be less than 100%");
        fee = _fee;
        minimumBondDiscount = _minimumBondDiscount;
        isManaged = _isManaged;
    }

    /* ======== MODIFIERS ======== */

    modifier managed() {
        if (isManaged) {
            require(
                msg.sender == manager,
                "Only manager can call managed vaults"
            );
        } else {
            require(
                msg.sender == owner(),
                "Only depositor can call manual vaults"
            );
        }
        _;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function changeManager(address _address) external {
        require(msg.sender == admin);
        require(_address != address(0));
        address old = manager;
        manager = _address;
        emit ManagerChanged(old, _address);
    }

    function changeFeeHarvester(address _address) external {
        require(msg.sender == admin);
        require(_address != address(0));
        address old = feeHarvester;
        feeHarvester = _address;
        emit FeeHarvesterChanged(old, _address);
    }

    /* ======== MANAGER FUNCTIONS ======== */

    function bond(
        address _depository,
        uint256 _amount,
        uint256 _slippage
    ) external override managed returns (uint256) {
        (
            address principle,
            address router,
            address tokenA,
            address tokenB,
            bool isLpToken,
            bool usingWrapped,
            bool active
        ) = bondingHQ.depositoryInfo(_depository);
        require(
            principle != address(0) && active,
            "Depository doesn't exist or is inactive"
        );
        if (isLpToken) {
            return
                _bondWithAssetTokenLp(
                    IERC20(tokenA),
                    IERC20(principle),
                    ITimeBondDepository(_depository),
                    _amount,
                    _slippage,
                    IJoeRouter01(router),
                    usingWrapped
                );
        } else {
            return
                _bondWithToken(
                    IERC20(principle),
                    ITimeBondDepository(_depository),
                    _amount,
                    _slippage,
                    IJoeRouter01(router)
                );
        }
    }

    function stakeAssets(uint256 _amount) public override managed {
        require(asset.balanceOf(address(this)) >= _amount, "Not enough tokens");
        asset.approve(address(stakingContract), _amount);
        stakingContract.stake(_amount, address(this));
        stakingContract.claim(address(this));
        emit AssetsStaked(_amount);
    }

    /* ======== USER FUNCTIONS ======== */

    function setManaged(bool _managed) external override onlyOwner {
        require(isManaged != _managed, "Cannot set mode to current mode");
        isManaged = _managed;
        emit ManagedChanged(_managed);
    }

    function setMinimumBondingDiscount(uint256 _discount)
        external
        override
        onlyOwner
    {
        require(
            minimumBondDiscount != _discount,
            "New discount value is the same as current one"
        );
        uint256 old = minimumBondDiscount;
        minimumBondDiscount = _discount;
        emit BondingDiscountChanged(old, _discount);
    }

    function withdraw(uint256 _amount) external override onlyOwner {
        require(
            stakedAsset.balanceOf(address(this)) >= _amount,
            "Not enough tokens"
        );
        stakedAsset.safeTransfer(owner(), _amount);
        emit Withdrawal(_amount);
    }

    /**
     *  @notice Anybody can top up the vault, but only depositor will be able to withdraw.
     *  For personal vaults it's the same as sending stakedAsset to the contract address.
     */
    function deposit(uint256 _amount) external override {
        require(
            stakedAsset.balanceOf(msg.sender) >= _amount,
            "Not enough tokens"
        );
        stakedAsset.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(_amount);
    }

    /**
     *  @notice This function is callable by anyone just in case manager is not working.
     */
    function redeem(address _depository) external override {
        (address principle, , , , , , ) = bondingHQ.depositoryInfo(_depository);
        require(principle != address(0));
        _redeemBondFrom(ITimeBondDepository(_depository));
    }

    /**
     *  @notice This function is callable by anyone just in case manager is not working.
     */
    function redeemAllBonds() external override {
        for (uint256 i = 0; i < activeBonds.length; i++) {
            _redeemBondFrom(ITimeBondDepository(activeBonds[i]));
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @dev this function checks if taken bond is profitable after fees.
     *  It estimates using precomputed magic number what's the minimum viable 5-day ROI
     *  (assmuing redeemeing before all the rebases), versus staking MEMO.
     *  It also checks if minimum bonding discount set by the user is reached.
     */
    function isBondProfitable(uint256 _bonded, uint256 _payout)
        public
        view
        returns (bool _profitable)
    {
        uint256 bondingROI = ((10000 * _payout) / _bonded) - 10000; // 1% = 100
        require(
            bondingROI >= minimumBondDiscount,
            "Bonding discount lower than threshold"
        );
        (, uint256 stakingReward, , ) = stakingContract.epoch();
        IMemories memories = IMemories(address(stakedAsset));
        uint256 circualtingSupply = memories.circulatingSupply();
        uint256 stakingROI = (100000 * stakingReward) / circualtingSupply;
        uint256 magicNumber = 2 * (60 + (stakingROI / 100));
        uint256 minimumBonding = (100 * stakingROI) / magicNumber;
        _profitable = bondingROI >= minimumBonding;
    }

    function getBondedFunds() public view override returns (uint256 _funds) {
        for (uint256 i = 0; i < activeBonds.length; i++) {
            _funds += bonds[activeBonds[i]].payout;
        }
    }

    function getAllManagedFunds()
        external
        view
        override
        returns (uint256 _funds)
    {
        _funds += getBondedFunds();
        _funds += stakedAsset.balanceOf(address(this));
        _funds += asset.balanceOf(address(this));
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _bondWithToken(
        IERC20 _token,
        ITimeBondDepository _depository,
        uint256 _amount,
        uint256 _slippage,
        IJoeRouter01 _router
    ) public managed returns (uint256) {
        _unstakeAssets(_amount);
        uint256 received = _sellAssetFor(
            asset,
            _token,
            _amount,
            _slippage,
            _router
        );
        uint256 payout = _bondWith(_token, received, _depository);
        // require(
        //     isBondProfitable(_amount, payout),
        //     "Bonding rate worse than staking"
        // );
        _addBondInfo(address(_depository), payout, _amount);
        emit BondCreated(_amount, address(_token), payout);
        return payout;
    }

    function _bondWithAssetTokenLp(
        IERC20 _token,
        IERC20 _lpToken,
        ITimeBondDepository _depository,
        uint256 _amount,
        uint256 _slippage,
        IJoeRouter01 _router,
        bool usingWrapped
    ) public managed returns (uint256) {
        uint256 amount;
        if (usingWrapped) {
            stakedAsset.approve(address(wrappedAsset), _amount);
            amount = wrappedAsset.wrap(_amount);
        } else {
            _unstakeAssets(_amount);
            amount = _amount;
        }
        uint256 received = _sellAssetFor(
            usingWrapped ? asset : IERC20(address(wrappedAsset)),
            _token,
            amount / 2,
            _slippage,
            _router
        );
        uint256 remaining = amount - (amount / 2);
        uint256 usedAsset = _addLiquidityFor(
            _token,
            usingWrapped ? asset : IERC20(address(wrappedAsset)),
            received,
            remaining,
            _router
        );

        // Stake not used assets
        if (usedAsset < remaining) {
            if (usingWrapped) {
                wrappedAsset.unwrap(remaining - usedAsset);
            } else {
                stakeAssets(remaining - usedAsset);
            }
        }

        uint256 used = amount - remaining + usedAsset;
        uint256 lpAmount = _lpToken.balanceOf(address(this));
        uint256 payout = _bondWith(_lpToken, lpAmount, _depository);
        // require(
        //     isBondProfitable(used, payout),
        //     "Bonding rate worse than staking"
        // );
        _addBondInfo(address(_depository), payout, used);
        emit BondCreated(used, address(_lpToken), payout);
        return payout;
    }

    /**
     *  @dev This function swaps assets for sepcified token via TraderJoe.
     *  @notice Slippage cannot exceed 1.5%.
     */
    function _sellAssetFor(
        IERC20 _asset,
        IERC20 _token,
        uint256 _amount,
        uint256 _slippage,
        IJoeRouter01 _router
    ) public managed returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(_asset);
        path[1] = address(_token);
        uint256[] memory amounts = _router.getAmountsOut(_amount, path);
        uint256 minOutput = (amounts[1] * (10000 - _slippage)) / 10000;
        _asset.approve(address(_router), _amount);
        uint256[] memory results = _router.swapExactTokensForTokens(
            _amount,
            minOutput,
            path,
            address(this),
            block.timestamp + 60
        );
        return results[1] > results[0] ? results[1] : results[0];
    }

    /**
     *  @dev This function adds liquidity for specified tokens on TraderJoe.
     *  @notice This function tries to maximize usage of first token {_tokenA}.
     */
    function _addLiquidityFor(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        IJoeRouter01 _router
    ) public managed returns (uint256) {
        _tokenA.approve(address(_router), _amountA);
        _tokenB.approve(address(_router), _amountB);
        (, uint256 assetSent, ) = _router.addLiquidity(
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
    ) public managed returns (uint256 _payout) {
        _token.approve(address(_depository), _amount);
        uint256 maxBondPrice = _depository.bondPrice();
        _payout = _depository.deposit(_amount, maxBondPrice, address(this));
    }

    function _redeemBondFrom(ITimeBondDepository _depository)
        public
        managed
        returns (uint256)
    {
        uint256 amount = _depository.redeem(address(this), true);
        uint256 feeValue = (amount * fee) / 10000;
        uint256 redeemed = amount - feeValue;
        bonds[address(_depository)].payout -= amount;
        if (block.timestamp >= bonds[address(_depository)].vestingEndTime) {
            _removeBondInfo(address(_depository));
        }
        stakedAsset.safeTransfer(feeHarvester, feeValue);
        emit BondRedeemed(address(_depository), redeemed);
        return redeemed;
    }

    function _unstakeAssets(uint256 _amount) public managed {
        stakedAsset.approve(address(stakingContract), _amount);
        stakingContract.unstake(_amount, false);
        emit AssetsUnstaked(_amount);
    }

    function _addBondInfo(
        address _depository,
        uint256 _payout,
        uint256 _assetsUsed
    ) public managed {
        if (bonds[address(_depository)].payout == 0) {
            activeBonds.push(address(_depository));
        }
        bonds[address(_depository)] = BondInfo({
            payout: bonds[address(_depository)].payout + _payout,
            assetUsed: bonds[address(_depository)].assetUsed + _assetsUsed,
            vestingEndTime: block.timestamp + 5 days,
            maturing: 0 // not used yet
        });
    }

    function _removeBondInfo(address _depository) public managed {
        require(bonds[address(_depository)].vestingEndTime >= block.timestamp);
        bonds[address(_depository)].payout = 0;
        for (uint256 i = 0; i < activeBonds.length; i++) {
            if (activeBonds[i] == _depository) {
                activeBonds[i] = activeBonds[activeBonds.length - 1];
                activeBonds.pop();
                break;
            }
        }
    }

    /* ======== AUXILLIARY ======== */

    /**
     *  @notice allow anyone to send lost tokens (excluding asset and stakedAsset) to the admin
     *  @return bool
     */
    function recoverLostToken(IERC20 _token) external returns (bool) {
        require(_token != asset, "NAT");
        require(_token != stakedAsset, "NAP");
        require(_token != IERC20(address(wrappedAsset)), "NAW");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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
// DegenBlue Contracts v0.0.1 (interfaces/IBondingHQ.sol)

/**
 *  @title IBondingHQ
 *  @author pbnather
 *
 *  This interface is meant to be used to interact with the vault contract
 *  by it's `manager`, wich manages bonding and redeeming operations.
 */
pragma solidity ^0.8.0;

interface IBondingHQ {
    function depositoryInfo(address _depository)
        external
        view
        returns (
            address principle,
            address router,
            address tokenA,
            address tokenB,
            bool isLpToken,
            bool usingWrapped,
            bool active
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (interfaces/IPersonalVault.sol)

/**
 *  @title IPersonalVault
 *  @author pbnather
 *
 *  This interface is meant to be used to interact with the vault contract
 *  by it's `manager`, wich manages bonding and redeeming operations.
 */
pragma solidity ^0.8.0;

interface IPersonalVault {
    function bond(
        address _depository,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256);

    function stakeAssets(uint256 _amount) external;

    function setManaged(bool _managed) external;

    function setMinimumBondingDiscount(uint256 _discount) external;

    function withdraw(uint256 _amount) external;

    function deposit(uint256 _amount) external;

    function redeem(address _depository) external;

    function redeemAllBonds() external;

    function getBondedFunds() external view returns (uint256 _funds);

    function getAllManagedFunds() external view returns (uint256 _funds);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (interfaces/IwMEMO.sol)

/**
 *  @title IwMEMO
 *  @author pbnather
 *
 *  This interface is meant to be used to interact with the vault contract
 *  by it's `manager`, wich manages bonding and redeeming operations.
 */
pragma solidity ^0.8.0;

interface IwMEMO {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);
}