// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Ownable } from "./lib/Ownable.sol";
import { ReentrancyGuard } from "./lib/ReentrancyGuard.sol";
import { ERC20 } from "./lib/ERC20.sol";
import { Stoppable } from "./lib/Stoppable.sol";
import { SafeERC20 } from "./lib/SafeERC20.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IVault } from "./interfaces/IVault.sol";
import { IVPStorage } from "./interfaces/IVPStorage.sol";
import { IStoppable } from "./interfaces/IStoppable.sol";

contract ElasticPool is Ownable, ReentrancyGuard, ERC20, Stoppable {
	using SafeERC20 for address;

	uint256 public constant COEFFICIENT_PRECISION = 1e6;	// Coefficients precision (parts per million, ppm)
	string public constant name = 'ElasticPoolToken';		// Internal token name
    string public constant symbol = 'EPT';	// Internal token symbol
	address public immutable inToken;		// inToken contract address
	address public immutable bVault;		// Balancer Vault address
	bytes32 public immutable bPoolId;		// Balancer Pool ID
	address public immutable balToken;		// Balancer BAL Token address
	address public immutable feeAddress;	// Address where fees will be sent
	address public immutable reservePool;	// ReservePool contract address, allowed to burn EPT without approval
	address public immutable vpStorage;		// VPStorage contract address where extra profit will be sent

	struct Params {
		uint64 feeCoefficient;			// Fee from profit coefficient in ppm cannot be higher 20 000 (2%)
		uint64 lossCoefficient;			// Max loss coefficient contract will compensate to user in ppm, cannot be lower 100 000 (10%)
		uint64 profitCoefficient;		// Max profit coefficient contract will pay to user in ppm, cannot be lower 100 000 (10%)
		uint64 holdTime;				// Hold time for withdrawal in seconds
	}
	Params private params;

	bytes32 public bPoolIdOne;			// Balancer Pool ID one used for Exchange BAL to In Token
	bytes32 public bPoolIdTwo;			// Balancer Pool ID two used for Exchange BAL to In Token
	address public bIntermediateToken;	// Address of intermediate token for BAL to In Token Exchange

	struct Pool {				// Struct to hold Balancer Pool Info
		address bptToken;
		address[] assets;
		uint256 inTokenIndex;
	}
	Pool public bPool;
	
	struct User {				// Struct to store user balances and time last deposited
		uint256 inBalance;		// In Token Balance
		uint256 bpBalance;		// BPT Token Balance
		uint256 lastTime;		// Last time deposited
	}
	mapping (address => User) private userData;
	
	uint256 private inBalance;	// Total In Token balance locked in contract

	modifier onlyAmountGreaterThanZero(uint256 amount_) {
		require(amount_ != 0, "amount must be greater than 0");
		_;
	}

	event Received(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePaid(address indexed user, uint256 amount);
	
	constructor (
		address owner_,
		uint8 decimals_,
		address inToken_,
		address bVault_,
		bytes32 bPoolId_,
		address balToken_,
		address feeAddress_,
		address reservePool_,
		address vpStorage_,
		Params memory params_
	)
		Ownable(owner_)
		ERC20(decimals_)
	{
		inToken = inToken_;
		bVault = bVault_;
		bPoolId = bPoolId_;
		balToken = balToken_;
		feeAddress = feeAddress_;
		reservePool = reservePool_;
		vpStorage = vpStorage_;
		_setFeeCoefficient(params_.feeCoefficient);
		_setLossCoefficient(params_.lossCoefficient);
		_setProfitCoefficient(params_.profitCoefficient);
		_setHoldTime(params_.holdTime);
	}

	/** 
	* @dev Sets ReservePool, VPStorage contract addresses, can be called only once
	* infinite approves inToken to VPStorage and bVault contracts to save gas on receiveOutToken calls and deposits
	* infinite approves balToken to bVault contract to save gas on swaps
	* calls updatebPool() to update pool info
	*/
	function initialize (
		bytes32 bPoolIdOne_,
		bytes32 bPoolIdTwo_,
		address bIntermediateToken_
	)
		external
	{
		require(bPoolIdOne == bytes32(0), "already initialized");
		_setExchangePools(bPoolIdOne_, bPoolIdTwo_, bIntermediateToken_);
		inToken.safeApprove(vpStorage, type(uint256).max);
		inToken.safeApprove(bVault, type(uint256).max);
		balToken.safeApprove(bVault, type(uint256).max);
		updatebPool();
	}

	/***************************************
					PRIVATE
	****************************************/

	/** 
	* @dev Sets Fee Coefficient
	* @param coefficient_ Fee coefficient
	*/
	function _setFeeCoefficient (
		uint256 coefficient_
	)
		private
	{
		require(coefficient_ <= 2e4, "fee coefficient must be lower 20 001");
		params.feeCoefficient = uint64(coefficient_);
	} 

	/** 
	* @dev Sets Loss Coefficient
	* @param coefficient_ Loss coefficient
	*/
	function _setLossCoefficient (
		uint256 coefficient_
	)
		private
	{
		require(coefficient_ >= 1e5, "loss coefficient must be higher 99 999");
		params.lossCoefficient = uint64(coefficient_);
	}    

	/** 
	* @dev Sets Profit Coefficient
	* @param coefficient_ - Profit coefficient
	*/
	function _setProfitCoefficient (
		uint256 coefficient_
	)
		private
	{
		require(coefficient_ >= 1e5, "profit coefficient must be higher 99 999");
		params.profitCoefficient = uint64(coefficient_);
	} 

	/** 
	* @dev Sets Hold time
	* @param holdDays_ Hold time in days
	*/
	function _setHoldTime (
		uint256 holdDays_
	)
		private
	{
		params.holdTime = uint64(holdDays_ * (1 days));
	}

	/** 
	* @dev Sets Balancer Pools for Exchange BAL to In Tokens
	* @param bPoolIdOne_ - first Balancer Pool ID
	* @param bPoolIdTwo_ - second Balancer Pool ID
	* @param bIntermediateToken_ - intermediate token address (same as inToken in case if exchange is done via singe pool)
	*/
	function _setExchangePools (
		bytes32 bPoolIdOne_,
		bytes32 bPoolIdTwo_,
		address bIntermediateToken_
	)
		private
	{
		// Throws error if pool one ID is wrong
		IVault(bVault).getPool(bPoolIdOne_);
		// Throws error if BAL Token is not registered with Pool ID One 
		IVault(bVault).getPoolTokenInfo(bPoolIdOne_, address(balToken));
		// Throws error if Intermediate Token is not registered with Pool ID One 
		IVault(bVault).getPoolTokenInfo(bPoolIdOne_, address(bIntermediateToken_));
		bPoolIdOne = bPoolIdOne_;
		bIntermediateToken = bIntermediateToken_;
		if(address(inToken) != bIntermediateToken_){
			// Throws error if pool two ID is wrong
			IVault(bVault).getPool(bPoolIdTwo_);
			// Throws error if Intermediate Token is not registered with Pool ID Two 
			IVault(bVault).getPoolTokenInfo(bPoolIdTwo_, bIntermediateToken_);
			// Throws error if InToken is not registered with Pool ID Two 
			IVault(bVault).getPoolTokenInfo(bPoolIdTwo_, address(inToken));
			bIntermediateToken.safeApprove(address(bVault), type(uint256).max);
			bPoolIdTwo = bPoolIdTwo_;
		}
	}

	function _withdraw(address address_, uint256 bpAmount_)
		private
		returns (uint256 inAmount_, uint256 amount_)
	{
		User storage _user = userData[address_];
		if(!stopped)
			require(block.timestamp -_user.lastTime >= params.holdTime, 'cannot withdraw, tokens on hold');
		require(_user.bpBalance >= bpAmount_, "not enough balance");
		inAmount_ = _user.inBalance * bpAmount_ / _user.bpBalance;
		inBalance -= inAmount_;
		_user.inBalance -= inAmount_;
		_user.bpBalance -= bpAmount_;
		uint256 _inBalance = IERC20(inToken).balanceOf(address(this));
		Pool memory _bPool = bPool;
		IVault.ExitPoolRequest memory _request;
		_request.assets = _bPool.assets;
		_request.minAmountsOut = new uint256[](_bPool.assets.length);
		_request.userData = abi.encode(IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bpAmount_, _bPool.inTokenIndex);
		IVault(bVault).exitPool(bPoolId, address(this), payable(address(this)), _request);
		amount_ = IERC20(inToken).balanceOf(address(this)) - _inBalance;
		emit Withdrawn(address_, inAmount_);
	}

	/**
	 * @dev Calculates returned In, Compensation Tokens values and fees
	 * @param inAmount_ initial investment of In Tokens
	 * @param amount_ returned amount from Balancer
	 */
	function _calcChange(uint256 inAmount_, uint256 amount_)
		private
		view
		returns (
			uint256 returnAmount_, 
			uint256 compensatedAmount_, 
			uint256 fee_, 
			uint256 feeWorker_
		)
	{
		uint256 _change; uint256 _maxChange;
		if(inAmount_ > amount_){
			_change = inAmount_- amount_;
			_maxChange = inAmount_ * params.lossCoefficient / COEFFICIENT_PRECISION;
			if(_change > _maxChange){
				compensatedAmount_ = _maxChange;
			}else{
				compensatedAmount_ = _change;
			}
			returnAmount_ = amount_;
		}else{
			_change = amount_ - inAmount_;
			_maxChange = _change * params.profitCoefficient * COEFFICIENT_PRECISION;
			returnAmount_ = inAmount_ + _maxChange;
			fee_ = (_change - _maxChange) * params.feeCoefficient / COEFFICIENT_PRECISION;
			feeWorker_ = _change - _maxChange - fee_;
		}
		return (returnAmount_, compensatedAmount_, fee_, feeWorker_);
	}

	/***************************************
					ADMIN
	****************************************/

	/** 
	* @dev Sets Balancer Pools for Exchange BAL to In Tokens
	* @param bPoolIdOne_ - first Balancer Pool ID
	* @param bPoolIdTwo_ - second Balancer Pool ID
	* @param bIntermediateToken_ - intermediate token address (same as inToken in case if exchange is done via singe pool)
	*/
	function setExchangePools (
		bytes32 bPoolIdOne_,
		bytes32 bPoolIdTwo_,
		address bIntermediateToken_
	)
		external
		onlyOwner
	{
		_setExchangePools(bPoolIdOne_, bPoolIdTwo_, bIntermediateToken_);
	}

	/** 
	* @dev Sets Fee Coefficient
	* @param coefficient_ Fee coefficient
	*/
	function setFeeCoefficient (
		uint256 coefficient_
	)
		external
		onlyOwner
	{
		_setFeeCoefficient(coefficient_);
	} 

	/** 
	* @dev Sets Loss Coefficient
	* @param coefficient_ Loss coefficient
	*/
	function setLossCoefficient (
		uint256 coefficient_
	)
		external
		onlyOwner
	{
		_setLossCoefficient(coefficient_);
	}    

	/** 
	* @dev Sets Profit Coefficient
	* @param coefficient_ - Profit coefficient
	*/
	function setProfitCoefficient (
		uint256 coefficient_
	)
		external
		onlyOwner
	{
		_setProfitCoefficient(coefficient_);
	} 

	/** 
	* @dev Sets Hold time
	* @param holdDays_ Hold time in days
	*/
	function setHoldTime (
		uint256 holdDays_
	)
		external
		onlyOwner
	{
		_setHoldTime(holdDays_);
	}

	/**
	 * @dev Triggers stopped state.
	 */
	function stop() external onlyOwner {
		_stop();
		IStoppable(reservePool).stop();
	}


	/***************************************
					ACTIONS
	****************************************/

	/**
	 * @dev Updates Balancer Pool information
	 */
	function updatebPool()
		public
	{
		Pool memory _bPool = bPool;
		(address _bptToken, ) = IVault(bVault).getPool(bPoolId);
		if(address(bPool.bptToken) == address(0))
			_bPool.bptToken = _bptToken;
		// Throws error if inToken is not registered with pool
		IVault(bVault).getPoolTokenInfo(bPoolId, inToken);
		(address[] memory _tokens, ,) = IVault(bVault).getPoolTokens(bPoolId);
		_bPool.assets = _tokens;
		for (uint256 i = 0; i < _tokens.length; i++)
			if(_tokens[i] == inToken)
				_bPool.inTokenIndex = i;
		bPool = _bPool;
	}

	/**
	 * @dev Exchanges BAL Tokens to In Tokens on Balancer and sends to worker address
	 */
	function checkAndDistributeBal ()
		external
	{
		uint256 _balAmount = IERC20(balToken).balanceOf(address(this));
		require(_balAmount != 0, 'BAL balance is 0');
		IVault.FundManagement memory _funds;
		_funds.sender = address(this);
		_funds.recipient = payable(address(this));
		address _bIntermediateToken = bIntermediateToken;
		IVault.SingleSwap memory _singleSwap;
		_singleSwap.kind = IVault.SwapKind.GIVEN_IN;
		_singleSwap.poolId = bPoolIdOne;
		_singleSwap.assetIn = balToken;
		_singleSwap.assetOut = _bIntermediateToken;
		_singleSwap.amount = _balAmount;
		uint256 _amountOut = IVault(bVault).swap(_singleSwap, _funds, 1, block.timestamp+1);
		if(inToken != _bIntermediateToken){
			_singleSwap.poolId = bPoolIdTwo;
			_singleSwap.assetIn = _bIntermediateToken;
			_singleSwap.assetOut = inToken;
			_singleSwap.amount = _amountOut;
			_amountOut = IVault(bVault).swap(_singleSwap, _funds, 0, block.timestamp+1);
		}
		IVPStorage(vpStorage).receiveOutToken(_amountOut);
	}

	/**
	 * @dev Destroys tokens from account, if msg.sender is not ReservePool allowance checked
	 * @param account_ address to burn from
	 * @param amount_ amount of tokens
	 */
	function burnFrom(address account_, uint256 amount_)  
		external
		whenNotStopped
	{
		if(msg.sender != reservePool && account_ != msg.sender)
			require(allowance[account_][msg.sender] >= amount_, "burn amount exceeds allowance");
		_burn(account_, amount_);
	}

	/**
	 * @dev Deposits In Tokens
	 * @param inAmount_ amount of InToken
	 */
	function receiveInToken (uint256 inAmount_)
		external
		nonReentrant
		whenNotStopped
		onlyAmountGreaterThanZero(inAmount_)
		returns (uint256 bpAmount_)
	{
		inToken.safeTransferFrom(msg.sender, address(this), inAmount_);
		Pool memory _bPool = bPool; 
		uint256 _bptBalance = IERC20(_bPool.bptToken).balanceOf(address(this));
		IVault.JoinPoolRequest memory _request;
		_request.assets = _bPool.assets;
		_request.maxAmountsIn = new uint256[](_bPool.assets.length);
		_request.maxAmountsIn[_bPool.inTokenIndex] = inAmount_;
		_request.userData = abi.encode(IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, _request.maxAmountsIn, 0);
		IVault(bVault).joinPool(bPoolId, address(this), address(this), _request);
		bpAmount_ = IERC20(_bPool.bptToken).balanceOf(address(this)) - _bptBalance;
		inBalance += inAmount_;
		User storage _user = userData[msg.sender];
		_user.inBalance += inAmount_;
		_user.bpBalance += bpAmount_;
		_user.lastTime = block.timestamp;
		emit Received(msg.sender, inAmount_);
	}

	/**
	 * @dev Withdraw
	 * @param bpAmount_ amount of BPT Tokens
	 * @return amount_ amount of In Tokens returned
	 * @return compensatedAmount_ amount of EPT Tokens minted
	 */
	function withdraw(uint256 bpAmount_)
		external
		nonReentrant
		whenNotStopped
		onlyAmountGreaterThanZero(bpAmount_)
		returns (uint256 amount_, uint256 compensatedAmount_)
	{
		uint256 _inAmount;
		(_inAmount, amount_) = _withdraw(msg.sender, bpAmount_);
		uint256 _fee; uint256 _feeWorker;
		(
			amount_, 
			compensatedAmount_, 
			_fee, 
			_feeWorker
		) = calcChange(_inAmount, amount_);
		inToken.safeTransfer(msg.sender, amount_);
		if(compensatedAmount_ != 0)
			_mint(msg.sender, compensatedAmount_);
		if(_fee != 0){
			inToken.safeTransfer(feeAddress, _fee);
			emit FeePaid(feeAddress, _fee);
		}
		if(_feeWorker != 0){
			inToken.safeTransfer(vpStorage, _feeWorker);
			emit FeePaid(vpStorage, _feeWorker);
		}
		return (amount_, compensatedAmount_);
	}

	/**
	 * @dev Withdraw Emergency
	 * @return amount_ amount of In Tokens returned
	 */
	function emergencyWithdraw()
		external
		nonReentrant
		whenStopped
		returns (uint256 amount_)
	{
		uint256 _bpAmount = userData[msg.sender].bpBalance;
		(, amount_) = _withdraw(msg.sender, _bpAmount);
		inToken.safeTransfer(msg.sender, amount_);
	}
	
	/***************************************
					GETTERS
	****************************************/

	/**
	 * @dev Returns feeCoefficient
	 */
	function feeCoefficient()
		external
		view
		returns (uint64)
	{
		return params.feeCoefficient;
	}

	/**
	 * @dev Returns lossCoefficient
	 */
	function lossCoefficient()
		external
		view
		returns (uint64)
	{
		return params.lossCoefficient;
	}

	/**
	 * @dev Returns profitCoefficient
	 */
	function profitCoefficient()
		external
		view
		returns (uint64)
	{
		return params.profitCoefficient;
	}

	/**
	 * @dev Returns holdTime
	 */
	function holdTime()
		external
		view
		returns (uint64)
	{
		return params.holdTime;
	}

	/**
	 * @dev Returns contract's total balance of BAL Token
	 */
	function getBalanceBal()
		external
		view
		returns (uint256)
	{
		return IERC20(balToken).balanceOf(address(this));
	}

	/**
	 * @dev Returns total balance of In Token locked into contract
	 */
	function getBalanceIn()
		external
		view
		returns (uint256)
	{
		return inBalance;
	}

	/**
	 * @dev Returns contract's total balance of BPT Token
	 */
	function getBalanceBp()
		external
		view
		returns (uint256)
	{
		return IERC20(bPool.bptToken).balanceOf(address(this));
	}

	/**
	 * @dev Returns balance of In Token of given user address
	 * @param address_ address of the user
	 */
	function getBalanceInOf(address address_)
		external
		view
		returns (uint256)
	{
		return userData[address_].inBalance;
	}

	/**
	 * @dev Returns balance of BPT Token of given user address
	 * @param address_ address of the user
	 */
	function getBalanceBpOf(address address_)
		external
		view
		returns (uint256)
	{
		return userData[address_].bpBalance;
	}

	/**
	 * @dev Returns true if hold is active for given user address
	 * @param address_ address of the user
	 */
	function isOnHold(address address_)
		external
		view
		returns (bool)
	{
		if(userData[address_].lastTime == 0) return false;
		return block.timestamp - userData[address_].lastTime < params.holdTime;
	}

	/**
	 * @dev Returns holdtime for given user address
	 * @param address_ address of the user
	 * @return holdTime_ Hold time in seconds
	 */
	function getHoldTime(address address_)
		external
		view
		returns (uint256 holdTime_)
	{
		uint256 _releaseTime = userData[address_].lastTime + params.holdTime; 
		if(_releaseTime > block.timestamp)
			holdTime_ = _releaseTime - block.timestamp;
	}

	/**
	 * @dev Calculates returned In, Compensation Tokens values and fees
	 * @param inAmount_ initial investment of In Tokens
	 * @param amount_ returned amount from Balancer
	 */
	function calcChange(uint256 inAmount_, uint256 amount_)
		public
		view
		returns (
			uint256 returnAmount_, 
			uint256 compensatedAmount_, 
			uint256 fee_, 
			uint256 feeWorker_
		)
	{
		return _calcChange(inAmount_, amount_);
	}

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotStopped` and `whenStopped`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Stoppable {
	/**
	 * @dev Emitted when the stop is triggered by `account`.
	 */
	event Stopped(address account);

	bool public stopped;

	/**
	 * @dev Modifier to make a function callable only when the contract is not stopped.
	 *
	 * Requirements:
	 *
	 * - The contract must not be stopped.
	 */
	modifier whenNotStopped() {
		require(!stopped, "Stoppable: stopped");
		_;
	}

	/**
	 * @dev Modifier to make a function callable only when the contract is stopped.
	 *
	 * Requirements:
	 *
	 * - The contract must be stopped.
	 */
	modifier whenStopped() {
		require(stopped, "Stoppable: not stopped");
		_;
	}

	/**
	 * @dev Triggers stopped state.
	 *
	 * Requirements:
	 *
	 * - The contract must not be stopped.
	 */
	function _stop() internal whenNotStopped {
		stopped = true;
		emit Stopped(msg.sender);
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeERC20 {
    
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant APPROVE_SELECTOR = bytes4(keccak256(bytes('approve(address,uint256)')));

    function safeTransfer(address token, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FROM_FAILED');
    }

    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE_SELECTOR, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: APPROVE_FAILED');
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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
abstract contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address owner_) {
        owner = owner_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

contract ERC20 {
    // string public virtual constant name = 'Token';
    // string public virtual constant symbol = 'TKN';
    uint8 public immutable decimals;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor (uint8 decimals_) {
        decimals = decimals_;
    }

    function _mint(address to, uint value) internal virtual {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal virtual {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal virtual {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal virtual {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVault {

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function getPoolTokenInfo(bytes32 poolId, address token) 
        external 
        view 
        returns (
            uint256 cash, 
            uint256 managed, 
            uint256 blockNumber, 
            address assetManager
        );

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }
    
    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function swap(SingleSwap memory singleSwap,
     FundManagement memory funds,
     uint256 limit,
     uint256 deadline) external returns (uint256 assetDelta);

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
       bytes32 poolId;
       SwapKind kind;
       address assetIn;
       address assetOut;
       uint256 amount;
       bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

/**
 * @dev Interface of VPStorage worker
 */
interface IVPStorage {

    /**
     * @dev Requests worker to withdraw tokens exchanged from BAL on ElasticPool
     */
    function receiveOutToken(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

/**
 * @dev Interface of the Stopable
 */
interface IStoppable {
	function stop() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Minimal Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}