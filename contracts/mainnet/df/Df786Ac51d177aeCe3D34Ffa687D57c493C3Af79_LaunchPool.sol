// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenDecimals {
    function decimals() external view returns (uint8);
}

interface InterfaceCurve {
    function getShares(
        uint256 supply,
        uint256 pool,
        uint256 stake,
        uint256 reducer,
        uint256 minPrice
    ) external view returns (uint256);

    function getUnitPrice(
        uint256 supply,
        uint256 pool,
        uint256 reducer,
        uint256 minPrice
    ) external view returns (uint256);
}

contract LaunchPool is Initializable {
    using SafeERC20 for IERC20;
    // Address of the sponsor that controls launch pools and token shares
    address private _sponsor;
    // IPFS hash containing JSON informations about the project
    string public metadata;
    /*
     * Address of the token that was previously deployed by sponsor
     * _stakeMax must never surpass total token supply
     */
    address private _token;
    // Price curve distribution contract address
    address private _curve;
    // Reducer used by curve dustribution
    uint256 private _curveReducer;
    // Reducer used by curve dustribution
    uint256 private _curveMinPrice;
    // Defines start timestamp for Pool opens
    uint256 private _startTimestamp;
    // Defines timestamp for Pool closes
    uint256 private _endTimestamp;
    // The total amount to be staked by investors
    uint256 private _stakesMax;
    // The minimum amount to be staken to approve launch pool
    uint256 private _stakesMin;
    // The total amount current staken at launch pool
    uint256 private _stakesTotal;
    // Prevent access elements bigger then stake size
    uint256 private _stakesCount;
    // The minimum amount for a unique stake
    uint256 private _stakeAmountMin;
    // The maximum amount a single stake could have
    uint256 private _stakeClamp;
    // 0 - Not Initialized - Not even set variables yet
    // 1 - Initialized
    //    Before Start Timestamp => Warm Up
    //    After Start Timestamp => Staking/Unstaking
    //    Before End Timestamp => Staking/Unstaking
    //    After End Timestamp => Only Staking
    // 2 - Paused - Staking stopped
    // 3 - Calculating - Bonus calculation finished, start distribution
    // 4 - Distributing - Finished distribution, start sponsor withdraw
    // 5 - Finalized - Allow sponsor withdraw
    // 6 - Aborted
    enum Stages {
        NotInitialized,
        Initialized,
        Paused,
        Calculating,
        Distributing,
        Finalized,
        Aborted
    }
    // Define current stage of launch pool
    Stages public stage = Stages.NotInitialized;

    // Token list to show on frontend
    address[] private _tokenList;
    mapping(address => bool) private _allowedTokens;
    mapping(address => uint8) private _tokenDecimals;

    struct TokenStake {
        address investor;
        address token;
        uint256 amount;
        // Result bonus calculated based on curve and reducer
        uint256 shares;
    }

    // Stakes struct mapping
    mapping(uint256 => TokenStake) private _stakes;
    // Points to respective stake on _stakes
    mapping(address => uint256[]) private _stakesByAccount;

    // Storing calculation index and balance
    uint256 private _stakesCalculated = 0;
    uint256 private _stakesCalculatedBalance = 0;
    // Storing token distribution index
    uint256 private _stakesDistributed = 0;

    // **** EVENTS ****

    event Staked(
        uint256 index,
        address indexed investor,
        address indexed token,
        uint256 amount
    );
    event Unstaked(
        uint256 index,
        address indexed investor,
        address indexed token,
        uint256 amount
    );
    event Distributed(
        uint256 index,
        address indexed investor,
        uint256 amount,
        uint256 shares
    );
    event MetadataUpdated(string newHash);

    // **** CONSTRUCTOR ****

    function initialize(
        address[] memory allowedTokens,
        uint256[] memory uintArgs,
        string memory _metadata,
        address _owner,
        address _sharesAddress,
        address _curveAddress
    ) public initializer {
        // Allow at most 3 coins
        require(
            allowedTokens.length >= 1 && allowedTokens.length <= 3,
            "There must be at least 1 and at most 3 tokens"
        );
        _stakesMin = uintArgs[0];
        _stakesMax = uintArgs[1];
        _startTimestamp = uintArgs[2];
        _endTimestamp = uintArgs[3];
        _curveReducer = uintArgs[4];
        _stakeAmountMin = uintArgs[5];
        _curveMinPrice = uintArgs[6];
        _stakeClamp = uintArgs[7];
        // Prevent stakes max never surpass Shares total supply
        require(
            IERC20(_sharesAddress).totalSupply() >=
                InterfaceCurve(_curveAddress).getShares(
                    _stakesMax,
                    0,
                    _stakesMax,
                    _curveReducer,
                    _curveMinPrice
                ),
            "Shares token has not enough supply for staking distribution"
        );
        // Store token allowance and treir decimals to easy normalize
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            require(
                ITokenDecimals(allowedTokens[i]).decimals() <= 18,
                "Token allowed has more than 18 decimals"
            );
            _tokenDecimals[allowedTokens[i]] = ITokenDecimals(allowedTokens[i])
                .decimals();
            _allowedTokens[allowedTokens[i]] = true;
            _tokenList.push(allowedTokens[i]);
        }
        _curve = _curveAddress;
        _sponsor = _owner;
        _token = _sharesAddress;
        metadata = _metadata;
        stage = Stages.Initialized;
    }

    // **** MODIFIERS ****

    modifier isTokenAllowed(address _tokenAddr) {
        require(_allowedTokens[_tokenAddr], "Cannot deposit that token");
        _;
    }

    modifier isStaking() {
        require(
            block.timestamp > _startTimestamp,
            "Launch Pool has not started"
        );
        require(stage == Stages.Initialized, "Launch Pool is not staking");
        _;
    }

    modifier isPaused() {
        require(stage == Stages.Paused, "LaunchPool is not paused");
        _;
    }

    modifier isConcluded() {
        require(
            block.timestamp >= _endTimestamp,
            "LaunchPool end timestamp not reached"
        );
        require(
            _stakesTotal >= _stakesMin,
            "LaunchPool not reached minimum stake"
        );
        _;
    }

    modifier isCalculating() {
        require(
            stage == Stages.Calculating,
            "Tokens are not yet ready to calculate"
        );
        _;
    }

    modifier isDistributing() {
        require(
            stage == Stages.Distributing,
            "Tokens are not yet ready to distribute"
        );
        _;
    }

    modifier isFinalized() {
        require(stage == Stages.Finalized, "Launch pool not finalized yet");
        _;
    }

    modifier hasStakeClamped(uint256 amount, address token) {
        // The multiplications allow prevent that tokens with less than 18 decimals pass through
        require(
            amount * (10**(18 - _tokenDecimals[token])) <= _stakeClamp,
            "Stake maximum amount exceeded"
        );
        _;
    }

    modifier hasMaxStakeReached(uint256 amount, address token) {
        // The multiplications allow prevent that tokens with less than 18 decimals pass through
        require(
            _stakesTotal + amount * (10**(18 - _tokenDecimals[token])) <=
                _stakesMax,
            "Maximum staked amount exceeded"
        );
        _;
    }

    modifier onlySponsor() {
        require(sponsor() == msg.sender, "Sponsor: caller is not the sponsor");
        _;
    }

    // **** VIEWS ****

    // Returns the sponsor address, owner of the contract
    function sponsor() public view virtual returns (address) {
        return _sponsor;
    }

    // Return the token list alllowed on launch pool
    function tokenList() public view returns (address[] memory) {
        return _tokenList;
    }

     // Return token shares address
    function sharesAddress() public view returns (address) {
        return _token;
    }

    /**
     * @dev Returns detailed stakes from an investor.
     * Stakes are returned as single dimension array.
     * [0] Amount of token decimals for first investor stake
     * [1] Stake amount of first stake
     * and so on...
     */
    function stakesDetailedOf(address investor_)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory stakes =
            new uint256[](_stakesByAccount[investor_].length * 2);
        for (uint256 i = 0; i < _stakesByAccount[investor_].length; i++) {
            stakes[i * 2] = _tokenDecimals[
                _stakes[_stakesByAccount[investor_][i]].token
            ];
            stakes[i * 2 + 1] = _stakes[_stakesByAccount[investor_][i]].amount;
        }
        return stakes;
    }

    /**
     * @dev Return global stake indexes for a specific investor.
     */
    function stakesOf(address investor_) public view returns (uint256[] memory) {
        return _stakesByAccount[investor_];
    }

    function stakesList() public view returns (uint256[] memory) {
        uint256[] memory stakes = new uint256[](_stakesCount);
        for (uint256 i = 0; i < _stakesCount; i++) {
            stakes[i] = _stakes[i].amount;
        }
        return stakes;
    }

    /**
     * @dev Get Stake shares for interface calculation.
     */
    function getStakeShares(uint256 amount, uint256 balance)
        public
        view
        returns (uint256)
    {
        return
            InterfaceCurve(_curve).getShares(
                _stakesMax,
                balance,
                amount,
                _curveReducer,
                _curveMinPrice
            );
    }

    /**
     * @dev Get general info about launch pool. Return Uint values
     * 0 - Pool start timestamp
     * 1 - Pool end timestamp
     * 2 - Minimum stakes for pool approval
     * 3 - Total stake allowed by launch pool
     * 4 - Sum of all stakes
     * 5 - Stakes Count
     * 6 - Curve Reducer value
     * 7 - Current stage of launch pool
     * 8 - Minimum amount allowed to stake
     * 9 - Minimum price paid for a share
     * 10 - Maximum price that investors will pay for a share
     */
    function getGeneralInfos() public view returns (uint256[] memory values) {
        values = new uint256[](11);
        values[0] = _startTimestamp;
        values[1] = _endTimestamp;
        values[2] = _stakesMin;
        values[3] = _stakesMax;
        values[4] = _stakesTotal;
        values[5] = _stakesCount;
        values[6] = _curveReducer;
        values[7] = uint256(stage);
        values[8] = _stakeAmountMin;
        values[9] = _curveMinPrice;
        values[10] = _stakeClamp;
        return values;
    }

    // **** INITIALIZED *****

    /** @dev Update metadata informations for launch pool
     **/
    function updateMetadata(string memory _hash) external onlySponsor {
        metadata = _hash;
        emit MetadataUpdated(_hash);
    }

    // **** STAKING *****

    /** @dev This allows investor to stake some ERC20 token. Make sure
     * You `ERC20.approve` to this contract before you stake.
     *
     * Requirements:
     *
     * - `token` Address of token contract to be staked
     * - `amount` The amount of tokens to stake
     */
    function stake(address token, uint256 amount)
        external
        isStaking
        isTokenAllowed(token)
        hasMaxStakeReached(amount, token)
        hasStakeClamped(amount, token)
    {
        uint256 normalizedAmount = amount * (10**(18 - _tokenDecimals[token]));
        require(
            normalizedAmount >= _stakeAmountMin,
            "Stake below minimum amount"
        );
        uint256 prevBalance = IERC20(token).balanceOf(address(this));
        // If the transfer fails, we revert and don't record the amount.
        IERC20(token).safeTransferFrom(msg.sender,address(this),amount);
        uint256 resultAmount = IERC20(token).balanceOf(address(this))-prevBalance;
        normalizedAmount = resultAmount * (10**(18 - _tokenDecimals[token]));
        // Store stake id after insert it to the queue
        TokenStake storage s = _stakes[_stakesCount];
        s.investor = msg.sender;
        s.token = token;
        // Convert any token amount that has less than 18 decimals to 18
        s.amount = normalizedAmount;

        _stakesTotal += s.amount;
        _stakesByAccount[msg.sender].push(_stakesCount);
        emit Staked(_stakesCount, msg.sender, token, resultAmount);
        _stakesCount += 1;
    }

    /** @dev This allows investor to unstake a previously stake. A investor stakeID
     * must be passed as parameter. The investor stakes are created sequentially and could
     * be listed using stakesOf().
     *
     * Requirements:
     *
     * - `stakeId` The index of stake from a sender investor. Initiating at 0.
     */
    function unstake(uint256 stakeId) external {
        require(
            stage == Stages.Initialized ||
            stage == Stages.Aborted ||
            stage == Stages.Paused,
            "No Staking/Paused/Aborted stage."
        );
        if (stage == Stages.Initialized) {
            require(block.timestamp <= _endTimestamp, "Launch Pool is closed");
        }
        require(
            _stakesByAccount[msg.sender].length > stakeId,
            "Stake index out of bounds"
        );

        uint256 globalId = _stakesByAccount[msg.sender][stakeId];
        TokenStake memory _stake = _stakes[globalId];
        require(_stake.amount > 0, "Stake already unstaked");
        // In case of 6 decimals (USDC, USDC, etc.) tokens need to be converted back.
        IERC20(_stake.token).safeTransfer(
            msg.sender,
            _stake.amount / (10**(18 - _tokenDecimals[_stake.token]))
        );

        _stakesTotal -= _stake.amount;
        _stakes[globalId].amount = 0;
        emit Unstaked(globalId, msg.sender, _stake.token, _stake.amount);
    }

    /** @dev This allows sponsor pause staking preventing investor to stake.
     * Only called by sponsor.
     **/
    function pause() external onlySponsor isStaking {
        stage = Stages.Paused;
    }

    /** @dev Unpause launch pool returning back to staking/unstaking stage.
     * Only called by sponsor.
     **/
    function unpause() external onlySponsor isPaused {
        stage = Stages.Initialized;
    }

    /** @dev Extend staking period of the launch pool.
     **/
    function extendEndTimestamp(uint256 extension)
        external
        onlySponsor
        isStaking
    {
        // Prevent extension to be bigger than 1 year, to not allow overflows
        require(extension < 365 days, "Extensions must be small than 1 year");
        _endTimestamp += extension;
    }

    /** @dev Lock stakes and proceed to Calculating phase of launch pool.
     * Only called by sponsor.
     **/
    function lock() external onlySponsor isConcluded {
        stage = Stages.Calculating;
    }

    // ***** CALCULATING ******

    /** @dev Calculate how much shares each investor will receive accordingly to their stakes.
     * Shares are calculated in order and skipped in case of has amount 0(unstaked).
     * In case of low gas, the calculation stops at the current stake index.
     * Only called by sponsor.
     **/
    function calculateSharesChunk() external onlySponsor isCalculating {
        InterfaceCurve curve = InterfaceCurve(_curve);
        while (_stakesCalculated < _stakesCount) {
            // Break while loop in case of lack of gas
            if (gasleft() < 100000) break;
            // In case that stake has amount 0, it could be skipped
            if (_stakes[_stakesCalculated].amount > 0) {
                _stakes[_stakesCalculated].shares = curve.getShares(
                    _stakesMax,
                    _stakesCalculatedBalance,
                    _stakes[_stakesCalculated].amount,
                    _curveReducer,
                    _curveMinPrice
                );
                _stakesCalculatedBalance += _stakes[_stakesCalculated].amount;
            }
            _stakesCalculated++;
        }
        if (_stakesCalculated >= _stakesCount) {
            stage = Stages.Distributing;
        }
    }

    // ***** DISTRIBUTING *****

    /** @dev Distribute all shares calculated for each investor.
     * Shares are distributed in order and skipped in case of has amount 0(unstaked).
     * In case of low gas, the distribution stops at the current stake index.
     * Only called by sponsor.
     **/
    function distributeSharesChunk() external onlySponsor isDistributing {
        IERC20 token = IERC20(_token);
        TokenStake memory _stake;
        while (_stakesDistributed < _stakesCount) {
            // Break while loop in case of lack of gas
            if (gasleft() < 100000) break;
            // In case that stake has amount 0, it could be skipped
            _stake = _stakes[_stakesDistributed];
            if (_stake.amount > 0) {
                token.safeTransferFrom(_sponsor, _stake.investor, _stake.shares);
                // Zero amount and shares to not be distribute again same stake
                emit Distributed(
                    _stakesDistributed,
                    _stake.investor,
                    _stake.amount,
                    _stake.shares
                );
                //_stakes[_stakesDistributed].amount = 0;
                _stakes[_stakesDistributed].shares = 0;
            }
            _stakesDistributed++;
        }
        if (_stakesDistributed >= _stakesCount) {
            stage = Stages.Finalized;
        }
    }

    // **** FINALIZED *****

    /** @dev Sponsor withdraw stakes after finalized pool.
     *  This could also be used to withdraw remain not used shared
     **/
    function withdrawStakes(address token) external onlySponsor isFinalized {
        IERC20 instance = IERC20(token);
        uint256 tokenBalance = instance.balanceOf(address(this));
        instance.safeTransfer(msg.sender, tokenBalance);
    }

    // **** ABORTING ****

    /** @dev Abort launch pool and allow all investors to unstake their tokens.
     * Only called by sponsor.
     **/
    function abort() external onlySponsor {
        // TODO Define rules to allow abort pool
        stage = Stages.Aborted;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
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

