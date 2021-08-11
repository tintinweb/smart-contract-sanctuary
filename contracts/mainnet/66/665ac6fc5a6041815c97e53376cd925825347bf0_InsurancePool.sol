/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// File: iface/IERC20.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

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

// File: ParassetERC20.sol

pragma solidity ^0.8.4;

/*
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

contract ParassetERC20 is Context, IERC20 {

	mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply;

    string _name;
    string _symbol;

    constructor() { }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// File: iface/IParassetGovernance.sol

pragma solidity ^0.8.4;

/// @dev This interface defines the governance methods
interface IParassetGovernance {
    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}
// File: ParassetBase.sol

pragma solidity ^0.8.4;

contract ParassetBase {

    // Lock flag
    uint256 _locked;

	/// @dev To support open-zeppelin/upgrades
    /// @param governance IParassetGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Log:ParassetBase!initialize");
        _governance = governance;
        _locked = 0;
    }

    /// @dev IParassetGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IParassetGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IParassetGovernance(governance).checkGovernance(msg.sender, 0), "Log:ParassetBase:!gov");
        _governance = newGovernance;
    }

    /// @dev Uniform accuracy
    /// @param inputToken Initial token
    /// @param inputTokenAmount Amount of token
    /// @param outputToken Converted token
    /// @return stability Amount of outputToken
    function getDecimalConversion(
        address inputToken, 
        uint256 inputTokenAmount, 
        address outputToken
    ) public view returns(uint256) {
    	uint256 inputTokenDec = 18;
    	uint256 outputTokenDec = 18;
    	if (inputToken != address(0x0)) {
    		inputTokenDec = IERC20(inputToken).decimals();
    	}
    	if (outputToken != address(0x0)) {
    		outputTokenDec = IERC20(outputToken).decimals();
    	}
    	return inputTokenAmount * (10**outputTokenDec) / (10**inputTokenDec);
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IParassetGovernance(_governance).checkGovernance(msg.sender, 0), "Log:ParassetBase:!gov");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 0, "Log:ParassetBase:!_locked");
        _locked = 1;
        _;
        _locked = 0;
    }
}
// File: lib/TransferHelper.sol

pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
// File: iface/ILPStakingMiningPool.sol

pragma solidity ^0.8.4;

interface ILPStakingMiningPool {
	function getBlock(uint256 endBlock) external view returns(uint256);
	function getBalance(address stakingToken, address account) external view returns(uint256);
	function getChannelInfo(address stakingToken) external view returns(uint256 lastUpdateBlock, uint256 endBlock, uint256 rewardRate, uint256 rewardPerTokenStored, uint256 totalSupply);
	function getAccountReward(address stakingToken, address account) external view returns(uint256);
	function stake(uint256 amount, address stakingToken) external;
	function withdraw(uint256 amount, address stakingToken) external;
	function getReward(address stakingToken) external;
}
// File: iface/IParasset.sol

pragma solidity ^0.8.4;

interface IParasset {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function destroy(uint256 amount, address account) external;
    function issuance(uint256 amount, address account) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: iface/IInsurancePool.sol

pragma solidity ^0.8.4;

interface IInsurancePool {
    
    /// @dev Destroy ptoken, update negative ledger
    /// @param amount quantity destroyed
    function destroyPToken(uint256 amount) external;

    /// @dev Clear negative books
    function eliminate() external;
}
// File: InsurancePool.sol

pragma solidity ^0.8.4;

contract InsurancePool is ParassetBase, IInsurancePool, ParassetERC20 {

    // negative account funds
    uint256 public _insNegative;
    // latest redemption time
    uint256 public _latestTime;
    // status
    uint8 public _flag;      // = 0: pause
                             // = 1: active
                             // = 2: redemption only
    // user address => freeze LP data
    mapping(address => Frozen) _frozenIns;
    struct Frozen {
        // frozen quantity
        uint256 amount;
        // freezing time                      
        uint256 time;                       
    }
    // pToken address
    address public _pTokenAddress;
    // redemption cycle, 2 days
	uint96 public _redemptionCycle;
    // underlyingToken address
    address public _underlyingTokenAddress;
    // redemption duration, 7 days
	uint96 public _waitCycle;
    // mortgagePool address
    address public _mortgagePool;
    // rate(2/1000)
    uint96 public _feeRate;

    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // staking address
    ILPStakingMiningPool _lpStakingMiningPool;

    event SubNegative(uint256 amount, uint256 allValue);
    event AddNegative(uint256 amount, uint256 allValue);

    function initialize(address governance) public override {
        super.initialize(governance);
        _redemptionCycle = 15 minutes;
        _waitCycle = 30 minutes;
        _feeRate = 2;
        _totalSupply = 0;
    }

	//---------modifier---------

    modifier onlyMortgagePool() {
        require(msg.sender == address(_mortgagePool), "Log:InsurancePool:!mortgagePool");
        _;
    }

    modifier whenActive() {
        require(_flag == 1, "Log:InsurancePool:!active");
        _;
    }

    modifier redemptionOnly() {
        require(_flag != 0, "Log:InsurancePool:!0");
        _;
    }

    //---------view---------

    /// @dev View the lpStakingMiningPool address
    /// @return lpStakingMiningPool address
    function getLPStakingMiningPool() external view returns(address) {
        return address(_lpStakingMiningPool);
    }

    /// @dev View the all lp 
    /// @return all lp 
    function getAllLP(address user) public view returns(uint256) {
        return _balances[user] + _lpStakingMiningPool.getBalance(address(this), user);
    }

    /// @dev View redemption period, next time
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTime() external view returns(uint256 startTime, uint256 endTime) {
        uint256 time = _latestTime;
        if (block.timestamp > time) {
            uint256 subTime = (block.timestamp - time) / uint256(_waitCycle);
            endTime = time + (uint256(_waitCycle) * (1 + subTime));
        } else {
            endTime = time;
        }
        startTime = endTime - uint256(_redemptionCycle);
    }

    /// @dev View frozen LP and unfreeze time
    /// @param add user address
    /// @return frozen LP
    /// @return unfreeze time
    function getFrozenIns(address add) external view returns(uint256, uint256) {
        Frozen memory frozenInfo = _frozenIns[add];
        return (frozenInfo.amount, frozenInfo.time);
    }

    /// @dev View frozen LP and unfreeze time, real time
    /// @param add user address
    /// @return frozen LP
    function getFrozenInsInTime(address add) external view returns(uint256) {
        Frozen memory frozenInfo = _frozenIns[add];
        if (block.timestamp > frozenInfo.time) {
            return 0;
        }
        return frozenInfo.amount;
    }

    /// @dev View redeemable LP, real time
    /// @param add user address
    /// @return redeemable LP
    function getRedemptionAmount(address add) external view returns (uint256) {
        Frozen memory frozenInfo = _frozenIns[add];
        uint256 balanceSelf = _balances[add];
        if (block.timestamp > frozenInfo.time) {
            return balanceSelf;
        } else {
            return balanceSelf - frozenInfo.amount;
        }
    }

    //---------governance----------

    /// @dev Set token name
    /// @param name token name
    /// @param symbol token symbol
    function setTokenInfo(string memory name, string memory symbol) external onlyGovernance {
        _name = name;
        _symbol = symbol;
    }

    /// @dev Set contract status
    /// @param num 0: pause, 1: active, 2: redemption only
    function setFlag(uint8 num) external onlyGovernance {
        _flag = num;
    }

    /// @dev Set mortgage pool address
    function setMortgagePool(address add) external onlyGovernance {
    	_mortgagePool = add;
    }

    /// @dev Set the staking contract address
    function setLPStakingMiningPool(address add) external onlyGovernance {
        _lpStakingMiningPool = ILPStakingMiningPool(add);
    }

    /// @dev Set the latest redemption time
    function setLatestTime(uint256 num) external onlyGovernance {
        _latestTime = num;
    }

    /// @dev Set the rate
    function setFeeRate(uint96 num) external onlyGovernance {
        _feeRate = num;
    }

    /// @dev Set redemption cycle
    function setRedemptionCycle(uint256 num) external onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        _redemptionCycle = uint96(num * 1 days);
    }

    /// @dev Set redemption duration
    function setWaitCycle(uint256 num) external onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        _waitCycle = uint96(num * 1 days);
    }

    /// @dev Set the underlying asset and PToken mapping and
    /// @param uToken underlying asset address
    /// @param pToken PToken address
    function setInfo(address uToken, address pToken) external onlyGovernance {
        _underlyingTokenAddress = uToken;
        _pTokenAddress = pToken;
    }

    function test_insNegative(uint256 amount) external onlyGovernance {
        _insNegative = amount;
    }

    //---------transaction---------

    /// @dev Exchange: PToken exchanges the underlying asset
    /// @param amount amount of PToken
    function exchangePTokenToUnderlying(uint256 amount) public redemptionOnly nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Calculate the fee
    	uint256 fee = amount * _feeRate / 1000;

        // Transfer to the PToken
        address pTokenAddress = _pTokenAddress;
        TransferHelper.safeTransferFrom(pTokenAddress, msg.sender, address(this), amount);

        // Calculate the amount of transferred underlying asset
        uint256 uTokenAmount = getDecimalConversion(pTokenAddress, amount - fee, _underlyingTokenAddress);
        require(uTokenAmount > 0, "Log:InsurancePool:!uTokenAmount");

        // Transfer out underlying asset
    	if (_underlyingTokenAddress == address(0x0)) {
            TransferHelper.safeTransferETH(msg.sender, uTokenAmount);
    	} else {
            TransferHelper.safeTransfer(_underlyingTokenAddress, msg.sender, uTokenAmount);
    	}

    	// Eliminate negative ledger
        eliminate();
    }

    /// @dev Exchange: underlying asset exchanges the PToken
    /// @param amount amount of underlying asset
    function exchangeUnderlyingToPToken(uint256 amount) public payable redemptionOnly nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Calculate the fee
    	uint256 fee = amount * _feeRate / 1000;

        // Transfer to the underlying asset
    	if (_underlyingTokenAddress == address(0x0)) {
            // The underlying asset is ETH
            require(msg.value == amount, "Log:InsurancePool:!msg.value");
    	} else {
            // The underlying asset is ERC20
            require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            TransferHelper.safeTransferFrom(_underlyingTokenAddress, msg.sender, address(this), amount);
    	}

        // Calculate the amount of transferred PTokens
        uint256 pTokenAmount = getDecimalConversion(_underlyingTokenAddress, amount - fee, address(0x0));
        require(pTokenAmount > 0, "Log:InsurancePool:!pTokenAmount");

        // Transfer out PToken
        address pTokenAddress = _pTokenAddress;
        uint256 pTokenBalance = IERC20(pTokenAddress).balanceOf(address(this));
        if (pTokenBalance < pTokenAmount) {
            // Insufficient PToken balance,
            uint256 subNum = pTokenAmount - pTokenBalance;
            _issuancePToken(subNum);
        }
        TransferHelper.safeTransfer(pTokenAddress, msg.sender, pTokenAmount);
    }

    /// @dev Subscribe for insurance
    /// @param amount amount of underlying asset
    function subscribeIns(uint256 amount) public payable whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Update redemption time
    	updateLatestTime();

        // Thaw LP
    	Frozen storage frozenInfo = _frozenIns[msg.sender];
    	if (block.timestamp > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}

        // PToken balance 
    	uint256 pTokenBalance = IERC20(_pTokenAddress).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (_underlyingTokenAddress == address(0x0)) {
            // The amount of ETH involved in the calculation does not include the transfer in this time
            require(msg.value == amount, "Log:InsurancePool:!msg.value");
            tokenBalance = address(this).balance - amount;
    	} else {
            require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            // Underlying asset conversion 18 decimals
            tokenBalance = getDecimalConversion(_underlyingTokenAddress, IERC20(_underlyingTokenAddress).balanceOf(address(this)), address(0x0));
    	}

        // Calculate LP
    	uint256 insAmount = 0;
    	uint256 insTotal = _totalSupply;
        uint256 allBalance = tokenBalance + pTokenBalance;
    	if (insTotal != 0) {
            // Insurance pool assets must be greater than 0
            require(allBalance > _insNegative, "Log:InsurancePool:allBalanceNotEnough");
            uint256 allValue = allBalance - _insNegative;
    		insAmount = getDecimalConversion(_underlyingTokenAddress, amount, address(0x0)) * insTotal / allValue;
    	} else {
            // The initial net value is 1
            insAmount = getDecimalConversion(_underlyingTokenAddress, amount, address(0x0)) - MINIMUM_LIQUIDITY;
            _issuance(MINIMUM_LIQUIDITY, address(0x0));
        }

    	// Transfer to the underlying asset(ERC20)
    	if (_underlyingTokenAddress != address(0x0)) {
    		require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            TransferHelper.safeTransferFrom(_underlyingTokenAddress, msg.sender, address(this), amount);
    	}

    	// Additional LP issuance
    	_issuance(insAmount, msg.sender);

    	// Freeze insurance LP
    	frozenInfo.amount = frozenInfo.amount + insAmount;
    	frozenInfo.time = _latestTime;
    }

    /// @dev Redemption insurance
    /// @param amount redemption LP
    function redemptionIns(uint256 amount) public redemptionOnly nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Update redemption time
    	updateLatestTime();

        // Judging the redemption time
        uint256 tokenTime = _latestTime;
    	require(block.timestamp < tokenTime && block.timestamp > tokenTime - uint256(_redemptionCycle), "Log:InsurancePool:!time");

        // Thaw LP
    	Frozen storage frozenInfo = _frozenIns[msg.sender];
    	if (block.timestamp > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}
    	
        // PToken balance
    	uint256 pTokenBalance = IERC20(_pTokenAddress).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (_underlyingTokenAddress == address(0x0)) {
            tokenBalance = address(this).balance;
    	} else {
    		tokenBalance = getDecimalConversion(_underlyingTokenAddress, IERC20(_underlyingTokenAddress).balanceOf(address(this)), address(0x0));
    	}

        // Insurance pool assets must be greater than 0
        uint256 allBalance = tokenBalance + pTokenBalance;
        require(allBalance > _insNegative, "Log:InsurancePool:allBalanceNotEnough");
        // Calculated amount of assets
    	uint256 allValue = allBalance - _insNegative;
    	uint256 insTotal = _totalSupply;
    	uint256 underlyingAmount = amount * allValue / insTotal;

        // Destroy LP
        _destroy(amount, msg.sender);
        // Judgment to freeze LP
        require(getAllLP(msg.sender) >= frozenInfo.amount, "Log:InsurancePool:frozen");
    	
    	// Transfer out assets, priority transfer of the underlying assets, if the underlying assets are insufficient, transfer ptoken
    	if (_underlyingTokenAddress == address(0x0)) {
            // ETH
            if (tokenBalance >= underlyingAmount) {
                TransferHelper.safeTransferETH(msg.sender, underlyingAmount);
            } else {
                TransferHelper.safeTransferETH(msg.sender, tokenBalance);
                TransferHelper.safeTransfer(_pTokenAddress, msg.sender, underlyingAmount - tokenBalance);
            }
    	} else {
            // ERC20
            if (tokenBalance >= underlyingAmount) {
                TransferHelper.safeTransfer(_underlyingTokenAddress, msg.sender, getDecimalConversion(_pTokenAddress, underlyingAmount, _underlyingTokenAddress));
            } else {
                TransferHelper.safeTransfer(_underlyingTokenAddress, msg.sender, getDecimalConversion(_pTokenAddress, tokenBalance, _underlyingTokenAddress));
                TransferHelper.safeTransfer(_pTokenAddress, msg.sender, underlyingAmount - tokenBalance);
            }
    	}
    }

    /// @dev Destroy PToken, update negative ledger
    /// @param amount quantity destroyed
    function destroyPToken(uint256 amount) public override onlyMortgagePool {
        _insNegative = _insNegative + amount;
        emit AddNegative(amount, _insNegative);

        eliminate();
    }

    /// @dev Issuance PToken, update negative ledger
    /// @param amount Additional issuance quantity
    function _issuancePToken(uint256 amount) private {
        IParasset(_pTokenAddress).issuance(amount, address(this));
        _insNegative = _insNegative + amount;
        emit AddNegative(amount, _insNegative);
    }

    /// @dev Clear negative books
    function eliminate() override public {
    	IParasset pErc20 = IParasset(_pTokenAddress);
        // negative ledger
    	uint256 negative = _insNegative;
        // PToken balance
    	uint256 pTokenBalance = pErc20.balanceOf(address(this)); 
    	if (negative > 0 && pTokenBalance > 0) {
    		if (negative >= pTokenBalance) {
                // Increase negative ledger
                pErc20.destroy(pTokenBalance, address(this));
    			_insNegative = _insNegative - pTokenBalance;
                emit SubNegative(pTokenBalance, _insNegative);
    		} else {
                // negative ledger = 0
                pErc20.destroy(negative, address(this));
    			_insNegative = 0;
                emit SubNegative(negative, _insNegative);
    		}
    	}
    }

    /// @dev Update redemption time
    function updateLatestTime() public {
        uint256 time = _latestTime;
    	if (block.timestamp > time) {
    		uint256 subTime = (block.timestamp - time) / uint256(_waitCycle);
    		_latestTime = time + (uint256(_waitCycle) * (1 + subTime));
    	}
    }

    /// @dev Destroy LP
    /// @param amount quantity destroyed
    /// @param account destroy address
    function _destroy(
        uint256 amount, 
        address account
    ) private {
        require(_balances[account] >= amount, "Log:InsurancePool:!destroy");
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        // emit Destroy(amount, account);
        emit Transfer(account, address(0x0), amount);
    }

    /// @dev Additional LP issuance
    /// @param amount additional issuance quantity
    /// @param account additional issuance address
    function _issuance(
        uint256 amount, 
        address account
    ) private {
        _balances[account] = _balances[account] + amount;
        _totalSupply = _totalSupply + amount;
        // emit Issuance(amount, account);
        emit Transfer(address(0x0), account, amount);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // Update redemption time
        updateLatestTime();

        // Thaw LP
        Frozen storage frozenInfo = _frozenIns[sender];
        if (block.timestamp > frozenInfo.time) {
            frozenInfo.amount = 0;
        }

        require(sender != address(0), "ERC20: transfer from the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        if (recipient != address(_lpStakingMiningPool)) {
            require(getAllLP(sender) >= frozenInfo.amount, "Log:InsurancePool:frozen");
        }
    }

    /// The insurance pool penetrates the warehouse, and external assets are added to the insurance pool.
    function addETH() external payable {}

}