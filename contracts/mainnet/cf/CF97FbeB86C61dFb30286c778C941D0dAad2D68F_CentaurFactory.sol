// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import './libraries/Ownable.sol';
import './interfaces/ICentaurFactory.sol';
import './interfaces/ICentaurPool.sol';
import './interfaces/ICentaurRouter.sol';
import './interfaces/ICloneFactory.sol';
import './CentaurSettlement.sol';
import './CentaurRouter.sol';
import './CentaurPool.sol';

contract CentaurFactory is ICentaurFactory, Ownable {
	uint public override poolFee;

    address public override poolLogic;
	address public override cloneFactory;
    address public override settlement;
    address payable public override router;

    // Base token => Pool
    mapping(address => address) public override getPool;
    address[] public override allPools;

    event PoolCreated(address indexed baseToken, address pool, uint);

    constructor(address _poolLogic, address _cloneFactory, address _WETH) public {
        poolLogic = _poolLogic;
        cloneFactory = _cloneFactory;

        // Deploy CentaurSettlement
        CentaurSettlement settlementContract = new CentaurSettlement(address(this), 3 minutes);
        settlement = address(settlementContract);


        // Deploy CentaurRouter
        CentaurRouter routerContract = new CentaurRouter(address(this), _WETH);
        router = address(routerContract);

        // Default poolFee = 0.2%
        poolFee = 200000000000000000;
    }

    function allPoolsLength() external override view returns (uint) {
        return allPools.length;
    }

    function isValidPool(address _pool) external view override returns (bool) {
        for (uint i = 0; i < allPools.length; i++) {
            if (allPools[i] == _pool) {
                return true;
            }
        }

        return false;
    }

    function createPool(address _baseToken, address _oracle, uint _liquidityParameter) external onlyOwner override returns (address pool) {
    	require(_baseToken != address(0) && _oracle != address(0), 'CentaurSwap: ZERO_ADDRESS');
    	require(getPool[_baseToken] == address(0), 'CentaurSwap: POOL_EXISTS');

    	pool = ICloneFactory(cloneFactory).createClone(poolLogic);
    	ICentaurPool(pool).init(
            address(this),
            _baseToken,
            _oracle,
            _liquidityParameter
        );

    	getPool[_baseToken] = pool;
        allPools.push(pool);

        emit PoolCreated(_baseToken, pool, allPools.length);
    }

    function addPool(address _pool) external onlyOwner override {
        address baseToken = ICentaurPool(_pool).baseToken();
        require(baseToken != address(0), 'CentaurSwap: ZERO_ADDRESS');
        require(getPool[baseToken] == address(0), 'CentaurSwap: POOL_EXISTS');

        getPool[baseToken] = _pool;
        allPools.push(_pool);
    }

    function removePool(address _pool) external onlyOwner override {
        address baseToken = ICentaurPool(_pool).baseToken();
        require(baseToken != address(0), 'CentaurSwap: ZERO_ADDRESS');
        require(getPool[baseToken] != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        getPool[baseToken] = address(0);
        for (uint i = 0; i < allPools.length; i++) {
            if (allPools[i] == _pool) {
                allPools[i] = allPools[allPools.length - 1];
                allPools.pop();
                break;
            }
        }
    }

    // Pool Functions
    function setPoolTradeEnabled(address _pool, bool _tradeEnabled) public onlyOwner override {
        ICentaurPool(_pool).setTradeEnabled(_tradeEnabled);
    }

    function setPoolDepositEnabled(address _pool, bool _depositEnabled) public onlyOwner override {
        ICentaurPool(_pool).setDepositEnabled(_depositEnabled);
    }

    function setPoolWithdrawEnabled(address _pool, bool _withdrawEnabled) public onlyOwner override {
        ICentaurPool(_pool).setWithdrawEnabled(_withdrawEnabled);
    }

    function setPoolLiquidityParameter(address _pool, uint _liquidityParameter) public onlyOwner override {
        ICentaurPool(_pool).setLiquidityParameter(_liquidityParameter);
    }

    function setAllPoolsTradeEnabled(bool _tradeEnabled) external onlyOwner override {
        for (uint i = 0; i < allPools.length; i++) {
            setPoolTradeEnabled(allPools[i], _tradeEnabled);
        }
    }

    function setAllPoolsDepositEnabled(bool _depositEnabled) external onlyOwner override {
        for (uint i = 0; i < allPools.length; i++) {
            setPoolDepositEnabled(allPools[i], _depositEnabled);
        }
    }

    function setAllPoolsWithdrawEnabled(bool _withdrawEnabled) external onlyOwner override {
        for (uint i = 0; i < allPools.length; i++) {
            setPoolWithdrawEnabled(allPools[i], _withdrawEnabled);
        }
    }

    function emergencyWithdrawFromPool(address _pool, address _token, uint _amount, address _to) external onlyOwner override {
        ICentaurPool(_pool).emergencyWithdraw(_token, _amount, _to);
    }

    // Router Functions
    function setRouterOnlyEOAEnabled(bool _onlyEOAEnabled) external onlyOwner override {
        CentaurRouter(router).setOnlyEOAEnabled(_onlyEOAEnabled);
    }

    function setRouterContractWhitelist(address _address, bool _whitelist) external onlyOwner override {
        if (_whitelist) {
            CentaurRouter(router).addContractToWhitelist(_address);
        } else {
            CentaurRouter(router).removeContractFromWhitelist(_address);
        }
    }

    // Settlement Functions
    function setSettlementDuration(uint _duration) external onlyOwner override {
        CentaurSettlement(settlement).setSettlementDuration(_duration);
    }

    // Helper Functions
    function setPoolFee(uint _poolFee) external onlyOwner override {
        poolFee = _poolFee;
    }

    function setPoolLogic(address _poolLogic) external onlyOwner override {
        poolLogic = _poolLogic;
    }

    function setCloneFactory(address _cloneFactory) external onlyOwner override {
        cloneFactory = _cloneFactory;
    }

    function setSettlement(address _settlement) external onlyOwner override {
        settlement = _settlement;
    }

    function setRouter(address payable _router) external onlyOwner override {
        router = _router;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ICentaurFactory {
    event PoolCreated(address indexed token, address pool, uint);

    function poolFee() external view returns (uint);

    function poolLogic() external view returns (address);
    function cloneFactory() external view returns (address);
    function settlement() external view returns (address);
    function router() external view returns (address payable);

    function getPool(address token) external view returns (address pool);
    function allPools(uint) external view returns (address pool);
    function allPoolsLength() external view returns (uint);
    function isValidPool(address pool) external view returns (bool);

    function createPool(address token, address oracle, uint poolUtilizationPercentage) external returns (address pool);
    function addPool(address pool) external;
    function removePool(address pool) external;

    function setPoolLiquidityParameter(address, uint) external;
    function setPoolTradeEnabled(address, bool) external;
    function setPoolDepositEnabled(address, bool) external;
    function setPoolWithdrawEnabled(address, bool) external;
    function setAllPoolsTradeEnabled(bool) external;
    function setAllPoolsDepositEnabled(bool) external;
    function setAllPoolsWithdrawEnabled(bool) external;
    function emergencyWithdrawFromPool(address, address, uint, address) external;

    function setRouterOnlyEOAEnabled(bool) external;
    function setRouterContractWhitelist(address, bool) external;

    function setSettlementDuration(uint) external;

    function setPoolFee(uint) external;
    function setPoolLogic(address) external;
    function setCloneFactory(address) external;
    function setSettlement(address) external;
    function setRouter(address payable) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ICentaurPool {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event AmountIn(address indexed sender, uint amount);
    event AmountOut(address indexed sender, uint amount, address indexed to);
    event EmergencyWithdraw(uint256 _timestamp, address indexed _token, uint256 _amount, address indexed _to);

    function factory() external view returns (address);
    function settlement() external view returns (address);
    function baseToken() external view returns (address);
    function baseTokenDecimals() external view returns (uint);
    function oracle() external view returns (address);
    function oracleDecimals() external view returns (uint);
    function baseTokenTargetAmount() external view returns (uint);
    function baseTokenBalance() external view returns (uint);
    function liquidityParameter() external view returns (uint);

    function init(address, address, address, uint) external;

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount);

    function swapTo(address _sender, address _fromToken, uint _amountIn, uint _value, address _receiver) external returns (uint maxAmount);
    function swapFrom(address _sender) external returns (uint amount, uint value);
    function swapSettle(address _sender) external returns (uint);

    function getOraclePrice() external view returns (uint price);
    function getAmountOutFromValue(uint _value) external view returns (uint amount);
    function getValueFromAmountIn(uint _amount) external view returns (uint value);
    function getAmountInFromValue(uint _value) external view returns (uint amount);
    function getValueFromAmountOut(uint _amount) external view returns (uint value);

    function setFactory(address) external;
    function setTradeEnabled(bool) external;
    function setDepositEnabled(bool) external;
    function setWithdrawEnabled(bool) external;
    function setLiquidityParameter(uint) external;
    function emergencyWithdraw(address, uint, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface ICentaurRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function onlyEOAEnabled() external pure returns (bool);
    function whitelistContracts(address _address) external view returns (bool);

    function addLiquidity(
        address _baseToken,
        uint _amount,
        address _to,
        uint _minLiquidity,
        uint _deadline
    ) external returns (uint amount, uint liquidity);
    function removeLiquidity(
        address _baseToken,
        uint _liquidity,
        address _to,
        uint _minAmount,
        uint _deadline
    ) external returns (uint amount);

    function swapExactTokensForTokens(
        address _fromToken,
        uint _amountIn,
        address _toToken,
        uint _amountOutMin,
        address to,
        uint _deadline
    ) external;
    function swapTokensForExactTokens(
        address _fromToken,
        uint _amountInMax,
        address _toToken,
        uint _amountOut,
        address _to,
        uint _deadline
    ) external;

    function swapSettle(address _sender, address _pool) external returns (uint amount);
    function swapSettleMultiple(address _sender, address[] memory _pools) external;

    function validatePools(address _fromToken, address _toToken) external view returns (address inputTokenPool, address outputTokenPool);
    function getAmountOut(address _fromToken, address _toToken, uint _amountIn) external view returns (uint amountOut);
    function getAmountIn(address _fromToken, address _toToken, uint _amountOut) external view returns (uint amountIn);

    function setFactory(address) external;
    function setOnlyEOAEnabled(bool) external;
    function addContractToWhitelist(address) external;
    function removeContractFromWhitelist(address) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICloneFactory {
    function createClone(address target) external returns (address result);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import './libraries/SafeMath.sol';
import './interfaces/ICentaurFactory.sol';
import './interfaces/ICentaurPool.sol';
import './interfaces/ICentaurSettlement.sol';

contract CentaurSettlement is ICentaurSettlement {

	using SafeMath for uint;

	bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

	address public override factory;
	uint public override settlementDuration;

	// User address -> Token address -> Settlement
	mapping(address => mapping (address => Settlement)) pendingSettlement;

	modifier onlyFactory() {
        require(msg.sender == factory, 'CentaurSwap: ONLY_FACTORY_ALLOWED');
        _;
    }

	constructor (address _factory, uint _settlementDuration) public {
		factory = _factory;
		settlementDuration = _settlementDuration;
	}

	function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CentaurSwap: TRANSFER_FAILED');
    }

	function addSettlement(
		address _sender,
		Settlement memory _pendingSettlement
	) external override {
		require(ICentaurFactory(factory).isValidPool(_pendingSettlement.fPool), 'CentaurSwap: POOL_NOT_FOUND');
		require(ICentaurFactory(factory).isValidPool(_pendingSettlement.tPool), 'CentaurSwap: POOL_NOT_FOUND');

		require(msg.sender == _pendingSettlement.tPool, 'CentaurSwap: INVALID_POOL');

		require(pendingSettlement[_sender][_pendingSettlement.fPool].settlementTimestamp == 0, 'CentaurSwap: SETTLEMENT_EXISTS');
		require(pendingSettlement[_sender][_pendingSettlement.tPool].settlementTimestamp == 0, 'CentaurSwap: SETTLEMENT_EXISTS');

		pendingSettlement[_sender][_pendingSettlement.fPool] = _pendingSettlement;
		pendingSettlement[_sender][_pendingSettlement.tPool] = _pendingSettlement;

	}

	function removeSettlement(
		address _sender,
		address _fPool,
		address _tPool
	) external override {
		require(msg.sender == _tPool, 'CentaurSwap: INVALID_POOL');

		require(pendingSettlement[_sender][_fPool].settlementTimestamp != 0, 'CentaurSwap: SETTLEMENT_DOES_NOT_EXISTS');
		require(pendingSettlement[_sender][_tPool].settlementTimestamp != 0, 'CentaurSwap: SETTLEMENT_DOES_NOT_EXISTS');

		require(block.timestamp >= pendingSettlement[_sender][_fPool].settlementTimestamp, 'CentaurSwap: SETTLEMENT_PENDING');

		_safeTransfer(ICentaurPool(_tPool).baseToken(), _tPool, pendingSettlement[_sender][_fPool].maxAmountOut);

		delete pendingSettlement[_sender][_fPool];
		delete pendingSettlement[_sender][_tPool];
	}

	function getPendingSettlement(address _sender, address _pool) external override view returns (Settlement memory) {
		return pendingSettlement[_sender][_pool];
	}
	
	function hasPendingSettlement(address _sender, address _pool) external override view returns (bool) {
		return (pendingSettlement[_sender][_pool].settlementTimestamp != 0);
	}

	// Helper Functions
	function setSettlementDuration(uint _settlementDuration) onlyFactory external override {
		settlementDuration = _settlementDuration;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/ICentaurFactory.sol';
import './interfaces/ICentaurPool.sol';
import './interfaces/ICentaurRouter.sol';
import "@openzeppelin/contracts/utils/Address.sol";

contract CentaurRouter is ICentaurRouter {
	using SafeMath for uint;

	address public override factory;
    address public immutable override WETH;
    bool public override onlyEOAEnabled;
    mapping(address => bool) public override whitelistContracts;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'CentaurSwap: EXPIRED');
        _;
    }

    modifier onlyEOA(address _address) {
        if (onlyEOAEnabled) {
            require((!Address.isContract(_address) || whitelistContracts[_address]), 'CentaurSwap: ONLY_EOA_ALLOWED');
        }
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'CentaurSwap: ONLY_FACTORY_ALLOWED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
        onlyEOAEnabled = true;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address _baseToken,
        uint _amount,
        uint _minLiquidity
    ) internal view virtual returns (uint liquidity) {
		ICentaurPool pool = ICentaurPool(ICentaurFactory(factory).getPool(_baseToken));

        uint _totalSupply = pool.totalSupply();
        uint _baseTokenTargetAmount = pool.baseTokenTargetAmount();
        liquidity = _amount;

        if (_totalSupply == 0) {
            liquidity = _amount.add(_baseTokenTargetAmount);
        } else {
            liquidity = _amount.mul(_totalSupply).div(_baseTokenTargetAmount);
        }

    	require(liquidity > _minLiquidity, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');
    }

    function addLiquidity(
        address _baseToken,
        uint _amount,
        address _to,
        uint _minLiquidity,
        uint _deadline
    ) external virtual override ensure(_deadline) onlyEOA(msg.sender) returns (uint amount, uint liquidity) {
        address pool = ICentaurFactory(factory).getPool(_baseToken);
        require(pool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        (liquidity) = _addLiquidity(_baseToken, _amount, _minLiquidity);
        
        TransferHelper.safeTransferFrom(_baseToken, msg.sender, pool, _amount);
        liquidity = ICentaurPool(pool).mint(_to);
        require(liquidity > _minLiquidity, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');

        return (_amount, liquidity);
    }

    function removeLiquidity(
        address _baseToken,
        uint _liquidity,
        address _to,
        uint _minAmount,
        uint _deadline
    ) public virtual override ensure(_deadline) onlyEOA(msg.sender) returns (uint amount) {
        address pool = ICentaurFactory(factory).getPool(_baseToken);
        require(pool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        ICentaurPool(pool).transferFrom(msg.sender, pool, _liquidity); // send liquidity to pool
        amount = ICentaurPool(pool).burn(_to);
        require(amount > _minAmount, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');

        return amount;
    }

    function swapExactTokensForTokens(
        address _fromToken,
        uint _amountIn,
        address _toToken,
        uint _amountOutMin,
        address _to,
        uint _deadline
    ) external virtual override ensure(_deadline) onlyEOA(msg.sender) {
        require(getAmountOut(_fromToken, _toToken, _amountIn) >= _amountOutMin, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        
        (address inputTokenPool, address outputTokenPool) = validatePools(_fromToken, _toToken);

        TransferHelper.safeTransferFrom(_fromToken, msg.sender, inputTokenPool, _amountIn);

        (uint finalAmountIn, uint value) = ICentaurPool(inputTokenPool).swapFrom(msg.sender);
        ICentaurPool(outputTokenPool).swapTo(msg.sender, _fromToken, finalAmountIn, value, _to);
    }

    function swapTokensForExactTokens(
        address _fromToken,
        uint _amountInMax,
        address _toToken,
        uint _amountOut,
        address _to,
        uint _deadline
    ) external virtual override ensure(_deadline) onlyEOA(msg.sender) {
        uint amountIn = getAmountIn(_fromToken, _toToken, _amountOut);
        require(amountIn <= _amountInMax, 'CentaurSwap: EXCESSIVE_INPUT_AMOUNT');
        
        (address inputTokenPool, address outputTokenPool) = validatePools(_fromToken, _toToken);

        TransferHelper.safeTransferFrom(_fromToken, msg.sender, inputTokenPool, amountIn);

        (uint finalAmountIn, uint value) = ICentaurPool(inputTokenPool).swapFrom(msg.sender);
        ICentaurPool(outputTokenPool).swapTo(msg.sender, _fromToken, finalAmountIn, value, _to);
    }

    function swapSettle(address _sender, address _pool) external virtual override returns (uint amount) {
        amount = ICentaurPool(_pool).swapSettle(_sender);
    }

    function swapSettleMultiple(address _sender, address[] memory _pools) external virtual override {
        for(uint i = 0; i < _pools.length; i++) {
            ICentaurPool(_pools[i]).swapSettle(_sender);
        }
    }

    function validatePools(address _fromToken, address _toToken) public view virtual override returns (address inputTokenPool, address outputTokenPool) {
        inputTokenPool = ICentaurFactory(factory).getPool(_fromToken);
        require(inputTokenPool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        outputTokenPool = ICentaurFactory(factory).getPool(_toToken);
        require(outputTokenPool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        return (inputTokenPool, outputTokenPool);
    } 

    function getAmountOut(
        address _fromToken,
        address _toToken,
        uint _amountIn
    ) public view virtual override returns (uint amountOut) {
        uint poolFee = ICentaurFactory(factory).poolFee();
        uint value = ICentaurPool(ICentaurFactory(factory).getPool(_fromToken)).getValueFromAmountIn(_amountIn);
        uint amountOutBeforeFees = ICentaurPool(ICentaurFactory(factory).getPool(_toToken)).getAmountOutFromValue(value);
        amountOut = (amountOutBeforeFees).mul(uint(100 ether).sub(poolFee)).div(100 ether);
    }

    function getAmountIn(
        address _fromToken,
        address _toToken,
        uint _amountOut
    ) public view virtual override returns (uint amountIn) {
        uint poolFee = ICentaurFactory(factory).poolFee();
        uint amountOut = _amountOut.mul(100 ether).div(uint(100 ether).sub(poolFee));
        uint value = ICentaurPool(ICentaurFactory(factory).getPool(_toToken)).getValueFromAmountOut(amountOut);
        amountIn = ICentaurPool(ICentaurFactory(factory).getPool(_fromToken)).getAmountInFromValue(value);
    }

    // Helper functions
    function setFactory(address _factory) external virtual override onlyFactory {
        factory = _factory;
    }

    function setOnlyEOAEnabled(bool _onlyEOAEnabled) external virtual override onlyFactory {
        onlyEOAEnabled = _onlyEOAEnabled;
    }

    function addContractToWhitelist(address _address) external virtual override onlyFactory {
        require(Address.isContract(_address), 'CentaurSwap: NOT_CONTRACT');
        whitelistContracts[_address] = true;
    }

    function removeContractFromWhitelist(address _address) external virtual override onlyFactory {
        whitelistContracts[_address] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import './CentaurLPToken.sol';
import './libraries/Initializable.sol';
import './libraries/SafeMath.sol';
import './libraries/CentaurMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/ICentaurFactory.sol';
import './interfaces/ICentaurPool.sol';
import './interfaces/ICentaurSettlement.sol';
import './interfaces/IOracle.sol';

contract CentaurPool is Initializable, CentaurLPToken {
    using SafeMath for uint;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public baseToken;
    uint public baseTokenDecimals;
    address public oracle;
    uint public oracleDecimals;

    uint public baseTokenTargetAmount;
    uint public baseTokenBalance;

    uint public liquidityParameter;

    bool public tradeEnabled;
    bool public depositEnabled;
    bool public withdrawEnabled;

    uint private unlocked;
    modifier lock() {
        require(unlocked == 1, 'CentaurSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier tradeAllowed() {
        require(tradeEnabled, "CentaurSwap: TRADE_NOT_ALLOWED");
        _;
    }

    modifier depositAllowed() {
        require(depositEnabled, "CentaurSwap: DEPOSIT_NOT_ALLOWED");
        _;
    }

    modifier withdrawAllowed() {
        require(withdrawEnabled, "CentaurSwap: WITHDRAW_NOT_ALLOWED");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == ICentaurFactory(factory).router(), 'CentaurSwap: ONLY_ROUTER_ALLOWED');
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'CentaurSwap: ONLY_FACTORY_ALLOWED');
        _;
    }

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event AmountIn(address indexed sender, uint amount);
    event AmountOut(address indexed sender, uint amount, address indexed to);
    event EmergencyWithdraw(uint256 _timestamp, address indexed _token, uint256 _amount, address indexed _to);

    function init(address _factory, address _baseToken, address _oracle, uint _liquidityParameter) external initializer {
        factory = _factory;
        baseToken = _baseToken;
        baseTokenDecimals = IERC20(baseToken).decimals();
        oracle = _oracle;
        oracleDecimals = IOracle(oracle).decimals();

        tradeEnabled = false;
        depositEnabled = false;
        withdrawEnabled = false;

        liquidityParameter = _liquidityParameter;

        symbol = string(abi.encodePacked("CS-", IERC20(baseToken).symbol()));

        unlocked = 1;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CentaurSwap: TRANSFER_FAILED');
    }

    function mint(address to) external lock onlyRouter depositAllowed returns (uint liquidity) {
        uint balance = IERC20(baseToken).balanceOf(address(this));
        uint amount = balance.sub(baseTokenBalance);

        if (totalSupply == 0) {
            liquidity = amount.add(baseTokenTargetAmount);
        } else {
            liquidity = amount.mul(totalSupply).div(baseTokenTargetAmount);
        }

        require(liquidity > 0, 'CentaurSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        baseTokenBalance = baseTokenBalance.add(amount);
        baseTokenTargetAmount = baseTokenTargetAmount.add(amount);

        emit Mint(msg.sender, amount);
    }

    function burn(address to) external lock onlyRouter withdrawAllowed returns (uint amount) {
        uint liquidity = balanceOf[address(this)];

        amount = liquidity.mul(baseTokenTargetAmount).div(totalSupply);

        require(amount > 0, 'CentaurSwap: INSUFFICIENT_LIQUIDITY_BURNED');

        require(baseTokenBalance > amount, 'CentaurSwap: INSUFFICIENT_LIQUIDITY');

        _burn(address(this), liquidity);
        _safeTransfer(baseToken, to, amount);

        baseTokenBalance = baseTokenBalance.sub(amount);
        baseTokenTargetAmount = baseTokenTargetAmount.sub(amount);

        emit Burn(msg.sender, amount, to);
    }

    function swapTo(address _sender, address _fromToken, uint _amountIn, uint _value, address _receiver) external lock onlyRouter tradeAllowed returns (uint maxAmount) {
        require(_fromToken != baseToken, 'CentaurSwap: INVALID_POOL');

        address pool = ICentaurFactory(factory).getPool(_fromToken);
        require(pool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        // Check if has pendingSettlement
        address settlement = ICentaurFactory(factory).settlement();
        require(!ICentaurSettlement(settlement).hasPendingSettlement(_sender, address(this)), 'CentaurSwap: PENDING_SETTLEMENT');
        
        // maxAmount because amount might be lesser during settlement. (If amount is more, excess is given back to pool)
        maxAmount = getAmountOutFromValue(_value);

        ICentaurSettlement.Settlement memory pendingSettlement = ICentaurSettlement.Settlement(
                pool,
                _amountIn,
                ICentaurPool(pool).baseTokenTargetAmount(),
                (ICentaurPool(pool).baseTokenBalance()).sub(_amountIn),
                ICentaurPool(pool).liquidityParameter(),
                address(this), 
                maxAmount,
                baseTokenTargetAmount,
                baseTokenBalance,
                liquidityParameter,
                _receiver,
                block.timestamp.add(ICentaurSettlement(settlement).settlementDuration())
            );

        // Subtract maxAmount from baseTokenBalance first, difference (if any) will be added back during settlement
        baseTokenBalance = baseTokenBalance.sub(maxAmount);

        // Add to pending settlement
        ICentaurSettlement(settlement).addSettlement(_sender, pendingSettlement);

        // Transfer amount to settlement for escrow
        _safeTransfer(baseToken, settlement, maxAmount);

        return maxAmount;
    }

    function swapFrom(address _sender) external lock onlyRouter tradeAllowed returns (uint amount, uint value) {
        uint balance = IERC20(baseToken).balanceOf(address(this));

        require(balance > baseTokenBalance, 'CentaurSwap: INSUFFICIENT_SWAP_AMOUNT');

        // Check if has pendingSettlement
        address settlement = ICentaurFactory(factory).settlement();
        require(!ICentaurSettlement(settlement).hasPendingSettlement(_sender, address(this)), 'CentaurSwap: PENDING_SETTLEMENT');

        amount = balance.sub(baseTokenBalance);
        value = getValueFromAmountIn(amount);

        baseTokenBalance = balance;

        emit AmountIn(_sender, amount);

        return (amount, value);
    }

    function swapSettle(address _sender) external lock returns (uint) {
        address settlement = ICentaurFactory(factory).settlement();
        ICentaurSettlement.Settlement memory pendingSettlement = ICentaurSettlement(settlement).getPendingSettlement(_sender, address(this));

        require (pendingSettlement.settlementTimestamp != 0, 'CentaurSwap: NO_PENDING_SETTLEMENT');
        require (pendingSettlement.tPool == address(this), 'CentaurSwap: WRONG_POOL_SETTLEMENT');
        require (block.timestamp >= pendingSettlement.settlementTimestamp, 'CentaurSwap: SETTLEMENT_STILL_PENDING');

        uint newfPoolOraclePrice = ICentaurPool(pendingSettlement.fPool).getOraclePrice();
        uint newtPoolOraclePrice = getOraclePrice();

        uint newValue = CentaurMath.getValueFromAmountIn(pendingSettlement.amountIn, newfPoolOraclePrice, ICentaurPool(pendingSettlement.fPool).baseTokenDecimals(), pendingSettlement.fPoolBaseTokenTargetAmount, pendingSettlement.fPoolBaseTokenBalance, pendingSettlement.fPoolLiquidityParameter);
        uint newAmount = CentaurMath.getAmountOutFromValue(newValue, newtPoolOraclePrice, baseTokenDecimals, pendingSettlement.tPoolBaseTokenTargetAmount, pendingSettlement.tPoolBaseTokenBalance, pendingSettlement.tPoolLiquidityParameter);

        uint poolFee = ICentaurFactory(factory).poolFee();

        // Remove settlement and receive escrowed amount
        ICentaurSettlement(settlement).removeSettlement(_sender, pendingSettlement.fPool, pendingSettlement.tPool);

        if (newAmount > pendingSettlement.maxAmountOut) {

            uint fee = (pendingSettlement.maxAmountOut).mul(poolFee).div(100 ether);
            uint amountOut = pendingSettlement.maxAmountOut.sub(fee);

            _safeTransfer(baseToken, pendingSettlement.receiver, amountOut);
            emit AmountOut(_sender, amountOut, pendingSettlement.receiver);

            baseTokenBalance = baseTokenBalance.add(fee);
            baseTokenTargetAmount = baseTokenTargetAmount.add(fee);

            return amountOut;
        } else {
            uint fee = (newAmount).mul(poolFee).div(100 ether);
            uint amountOut = newAmount.sub(fee);

            _safeTransfer(baseToken, pendingSettlement.receiver, amountOut);
            emit AmountOut(_sender, amountOut, pendingSettlement.receiver);

            // Difference added back to baseTokenBalance
            uint difference = (pendingSettlement.maxAmountOut).sub(amountOut);
            baseTokenBalance = baseTokenBalance.add(difference);

            // TX fee goes back into pool for liquidity providers
            baseTokenTargetAmount = baseTokenTargetAmount.add(difference);

            return newAmount;
        }
    }

    function getOraclePrice() public view returns (uint price) {
        (, int answer,,,) = IOracle(oracle).latestRoundData();

        // Returns price in 18 decimals
        price = uint(answer).mul(10 ** uint(18).sub(oracleDecimals));
    }

    // Swap Exact Tokens For Tokens (getAmountOut)
    function getAmountOutFromValue(uint _value) public view returns (uint amount) {
        amount = CentaurMath.getAmountOutFromValue(_value, getOraclePrice(), baseTokenDecimals,  baseTokenTargetAmount, baseTokenBalance, liquidityParameter);
    
        require(baseTokenBalance > amount, "CentaurSwap: INSUFFICIENT_LIQUIDITY");
    }

    function getValueFromAmountIn(uint _amount) public view returns (uint value) {
        value = CentaurMath.getValueFromAmountIn(_amount, getOraclePrice(), baseTokenDecimals, baseTokenTargetAmount, baseTokenBalance, liquidityParameter);
    }

    // Swap Tokens For Exact Tokens (getAmountIn)
    function getAmountInFromValue(uint _value) public view returns (uint amount) {
        amount = CentaurMath.getAmountInFromValue(_value, getOraclePrice(), baseTokenDecimals,  baseTokenTargetAmount, baseTokenBalance, liquidityParameter);
    }

    function getValueFromAmountOut(uint _amount) public view returns (uint value) {
        require(baseTokenBalance > _amount, "CentaurSwap: INSUFFICIENT_LIQUIDITY");

        value = CentaurMath.getValueFromAmountOut(_amount, getOraclePrice(), baseTokenDecimals, baseTokenTargetAmount, baseTokenBalance, liquidityParameter);
    }

    // Helper functions
    function setFactory(address _factory) external onlyFactory {
        factory = _factory;
    }

    function setTradeEnabled(bool _tradeEnabled) external onlyFactory {
        tradeEnabled = _tradeEnabled;
    }

    function setDepositEnabled(bool _depositEnabled) external onlyFactory {
        depositEnabled = _depositEnabled;
    }

    function setWithdrawEnabled(bool _withdrawEnabled) external onlyFactory {
        withdrawEnabled = _withdrawEnabled;
    }

    function setLiquidityParameter(uint _liquidityParameter) external onlyFactory {
        liquidityParameter = _liquidityParameter;
    }

    function emergencyWithdraw(address _token, uint _amount, address _to) external onlyFactory {
        _safeTransfer(_token, _to, _amount);

        emit EmergencyWithdraw(block.timestamp, _token, _amount, _to);
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

interface ICentaurSettlement {
    // event SettlementAdded(address indexed sender, address indexed _fromToken, uint _amountIn, address indexed _toToken, uint _amountOut);
    // event SettlementRemoved(address indexed sender, address indexed _fromToken, address indexed _toToken);
    struct Settlement {
        address fPool;
        uint amountIn;
        uint fPoolBaseTokenTargetAmount;
        uint fPoolBaseTokenBalance;
        uint fPoolLiquidityParameter;
        address tPool;
        uint maxAmountOut;
        uint tPoolBaseTokenTargetAmount;
        uint tPoolBaseTokenBalance;
        uint tPoolLiquidityParameter;
        address receiver;
        uint settlementTimestamp;
    }

    function factory() external pure returns (address);
    function settlementDuration() external pure returns (uint);

    function addSettlement(
        address _sender,
        Settlement memory _pendingSettlement
    ) external;
    function removeSettlement(address _sender, address _fPool, address _tPool) external;
    
    function getPendingSettlement(address _sender, address _pool) external view returns (Settlement memory);
    function hasPendingSettlement(address _sender, address _pool) external view returns (bool);

    function setSettlementDuration(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function symbol() external pure returns (string memory);
    /**
     * @dev Returns the token decimal.
     */
    function decimals() external pure returns (uint8);

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

pragma solidity =0.6.12;

import './libraries/SafeMath.sol';

contract CentaurLPToken {
    using SafeMath for uint;

    string public constant name = 'CentaurSwap LP Token';
    string public symbol;
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { SafeMath } from "./SafeMath.sol";
import { ABDKMathQuad } from './ABDKMathQuad.sol';

library CentaurMath {
    using SafeMath for uint256;

    bytes16 constant ONE_ETHER_QUAD = 0x403ABC16D674EC800000000000000000;

    // Helper Functions
    function getAmountOutFromValue(uint _value, uint _P, uint _tokenDecimals, uint _baseTokenTargetAmount, uint _baseTokenBalance, uint _liquidityParameter) external pure returns (uint amount) {
        bytes16 DECIMAL_QUAD = ABDKMathQuad.fromUInt(10 ** _tokenDecimals);

        bytes16 value_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_value), DECIMAL_QUAD);
        bytes16 P_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_P), ONE_ETHER_QUAD);
        bytes16 baseTokenTargetAmount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenTargetAmount), DECIMAL_QUAD);
        bytes16 baseTokenBalance_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenBalance), DECIMAL_QUAD);
        bytes16 k_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_liquidityParameter), DECIMAL_QUAD);

        bytes16 X2 = ABDKMathQuad.sub(baseTokenBalance_quad, baseTokenTargetAmount_quad);
        bytes16 X1 = _solveEquationForAmountOut(
            value_quad,
            X2,
            k_quad,
            P_quad
        );

        bytes16 amountOut = ABDKMathQuad.sub(X2, X1);
        amount = ABDKMathQuad.toUInt(ABDKMathQuad.mul(amountOut, ONE_ETHER_QUAD));
    }

    function getValueFromAmountIn(uint _amount, uint _P, uint _tokenDecimals, uint _baseTokenTargetAmount, uint _baseTokenBalance, uint _liquidityParameter) external pure returns (uint value) {
        bytes16 DECIMAL_QUAD = ABDKMathQuad.fromUInt(10 ** _tokenDecimals);

        bytes16 amount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_amount), DECIMAL_QUAD);
        bytes16 P_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_P), ONE_ETHER_QUAD);
        bytes16 baseTokenTargetAmount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenTargetAmount), DECIMAL_QUAD);
        bytes16 baseTokenBalance_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenBalance), DECIMAL_QUAD);
        bytes16 k_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_liquidityParameter), DECIMAL_QUAD);

        bytes16 X1 = ABDKMathQuad.sub(baseTokenBalance_quad, baseTokenTargetAmount_quad);
        bytes16 X2 = ABDKMathQuad.add(X1, amount_quad);

        value = _solveForIntegral(
            X1,
            X2,
            k_quad,
            P_quad
        );
    }

    function getAmountInFromValue(uint _value, uint _P, uint _tokenDecimals, uint _baseTokenTargetAmount, uint _baseTokenBalance, uint _liquidityParameter) external pure returns (uint amount) {
        bytes16 DECIMAL_QUAD = ABDKMathQuad.fromUInt(10 ** _tokenDecimals);

        bytes16 value_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_value), DECIMAL_QUAD);
        bytes16 P_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_P), ONE_ETHER_QUAD);
        bytes16 baseTokenTargetAmount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenTargetAmount), DECIMAL_QUAD);
        bytes16 baseTokenBalance_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenBalance), DECIMAL_QUAD);
        bytes16 k_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_liquidityParameter), DECIMAL_QUAD);

        bytes16 X1 = ABDKMathQuad.sub(baseTokenBalance_quad, baseTokenTargetAmount_quad);
        bytes16 X2 = _solveEquationForAmountIn(
            value_quad,
            X1,
            k_quad,
            P_quad
        );

        bytes16 amountOut = ABDKMathQuad.sub(X2, X1);
        amount = ABDKMathQuad.toUInt(ABDKMathQuad.mul(amountOut, ONE_ETHER_QUAD));
    }

    function getValueFromAmountOut(uint _amount, uint _P, uint _tokenDecimals, uint _baseTokenTargetAmount, uint _baseTokenBalance, uint _liquidityParameter) external pure returns (uint value) {
        bytes16 DECIMAL_QUAD = ABDKMathQuad.fromUInt(10 ** _tokenDecimals);

        bytes16 amount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_amount), DECIMAL_QUAD);
        bytes16 P_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_P), ONE_ETHER_QUAD);
        bytes16 baseTokenTargetAmount_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenTargetAmount), DECIMAL_QUAD);
        bytes16 baseTokenBalance_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_baseTokenBalance), DECIMAL_QUAD);
        bytes16 k_quad = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_liquidityParameter), DECIMAL_QUAD);

        bytes16 X2 = ABDKMathQuad.sub(baseTokenBalance_quad, baseTokenTargetAmount_quad);
        bytes16 X1 = ABDKMathQuad.sub(X2, amount_quad);

        value = _solveForIntegral(
            X1,
            X2,
            k_quad,
            P_quad
        );
    }
    // Core Functions
    
    // Solve for Delta
    function _solveForIntegral (
        bytes16 X1, 
        bytes16 X2, 
        bytes16 k,
        bytes16 P
    ) internal pure returns (uint256) {
        bytes16 multiplier = ABDKMathQuad.mul(k, P);

        bytes16 NLog_X2 = ABDKMathQuad.ln(ABDKMathQuad.add(X2, k));
        bytes16 NLog_X1 = ABDKMathQuad.ln(ABDKMathQuad.add(X1, k));

        bytes16 delta = ABDKMathQuad.mul(multiplier, ABDKMathQuad.sub(NLog_X2, NLog_X1));

        return ABDKMathQuad.toUInt(ABDKMathQuad.mul(delta, ONE_ETHER_QUAD));
    }

    // Solve for amountOut
    // Given X2, solve for X1
    function _solveEquationForAmountOut (
        bytes16 delta,
        bytes16 X2,
        bytes16 k,
        bytes16 P
    ) internal pure returns (bytes16 X1) {
        bytes16 NLog_X2 = ABDKMathQuad.ln(ABDKMathQuad.add(X2, k));
        bytes16 deltaOverTotal = ABDKMathQuad.div(delta, ABDKMathQuad.mul(k, P));

        bytes16 ePower = ABDKMathQuad.exp(ABDKMathQuad.sub(NLog_X2, deltaOverTotal));

        X1 = ABDKMathQuad.sub(ePower, k);
    }

    // Solve for amountOut
    // Given X1, solve for X2
    function _solveEquationForAmountIn (
        bytes16 delta,
        bytes16 X1,
        bytes16 k,
        bytes16 P
    ) internal pure returns (bytes16 X2) {
        bytes16 NLog_X1 = ABDKMathQuad.ln(ABDKMathQuad.add(X1, k));
        bytes16 deltaOverTotal = ABDKMathQuad.div(delta, ABDKMathQuad.mul(k, P));

        bytes16 ePower = ABDKMathQuad.exp(ABDKMathQuad.add(deltaOverTotal, NLog_X1));

        X2 = ABDKMathQuad.sub(ePower, k);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IOracle {
	function decimals() external view returns (uint8);
	function description() external view returns (string memory);
	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(uint80 _roundId)
		external
		view
		returns (
		  uint80 roundId,
		  int256 answer,
		  uint256 startedAt,
		  uint256 updatedAt,
		  uint80 answeredInRound
	);
		
	function latestRoundData()
		external
		view
		returns (
		  uint80 roundId,
		  int256 answer,
		  uint256 startedAt,
		  uint256 updatedAt,
		  uint80 answeredInRound
	);
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      // We rely on overflow behavior here
      uint256 result = uint256 (x > 0 ? x : -x);

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
      if (x < 0) result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    require (exponent <= 16638); // Overflow
    if (exponent < 16383) return 0; // Underflow

    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16495) result >>= 16495 - exponent;
    else if (exponent > 16495) result <<= exponent - 16495;

    if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
      require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
      return -int256 (result); // We rely on overflow behavior here
    } else {
      require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int256 (result);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      uint256 result = x;

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    if (exponent < 16383) return 0; // Underflow

    require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

    require (exponent <= 16638); // Overflow
    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16495) result >>= 16495 - exponent;
    else if (exponent > 16495) result <<= exponent - 16495;

    return result;
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      // We rely on overflow behavior here
      uint256 result = uint256 (x > 0 ? x : -x);

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
      if (x < 0) result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    require (exponent <= 16510); // Overflow
    if (exponent < 16255) return 0; // Underflow

    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16367) result >>= 16367 - exponent;
    else if (exponent > 16367) result <<= exponent - 16367;

    if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
      require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
      return -int256 (result); // We rely on overflow behavior here
    } else {
      require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int256 (result);
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      // We rely on overflow behavior here
      uint256 result = uint128 (x > 0 ? x : -x);

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
      if (x < 0) result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    require (exponent <= 16446); // Overflow
    if (exponent < 16319) return 0; // Underflow

    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16431) result >>= 16431 - exponent;
    else if (exponent > 16431) result <<= exponent - 16431;

    if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
      require (result <= 0x80000000000000000000000000000000);
      return -int128 (result); // We rely on overflow behavior here
    } else {
      require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (result);
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

    uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
    uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (exponent == 0x7FFFF) {
      if (significand > 0) return NaN;
      else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
    }

    if (exponent > 278526)
      return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
    else if (exponent < 245649)
      return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
    else if (exponent < 245761) {
      significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
      exponent = 0;
    } else {
      significand >>= 124;
      exponent -= 245760;
    }

    uint128 result = uint128 (significand | exponent << 112);
    if (negative) result |= 0x80000000000000000000000000000000;

    return bytes16 (result);
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
    else if (exponent == 0) {
      if (result > 0) {
        uint256 msb = msb (result);
        result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        exponent = 245649 + msb;
      }
    } else {
      result <<= 124;
      exponent += 245760;
    }

    result |= exponent << 236;
    if (uint128 (x) >= 0x80000000000000000000000000000000)
      result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

    return bytes32 (result);
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    uint256 exponent = uint64 (x) >> 52 & 0x7FF;

    uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

    if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
    else if (exponent == 0) {
      if (result > 0) {
        uint256 msb = msb (result);
        result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        exponent = 15309 + msb;
      }
    } else {
      result <<= 60;
      exponent += 15360;
    }

    result |= exponent << 112;
    if (x & 0x8000000000000000 > 0)
      result |= 0x80000000000000000000000000000000;

    return bytes16 (uint128 (result));
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (exponent == 0x7FFF) {
      if (significand > 0) return 0x7FF8000000000000; // NaN
      else return negative ?
          bytes8 (0xFFF0000000000000) : // -Infinity
          bytes8 (0x7FF0000000000000); // Infinity
    }

    if (exponent > 17406)
      return negative ?
          bytes8 (0xFFF0000000000000) : // -Infinity
          bytes8 (0x7FF0000000000000); // Infinity
    else if (exponent < 15309)
      return negative ?
          bytes8 (0x8000000000000000) : // -0
          bytes8 (0x0000000000000000); // 0
    else if (exponent < 15361) {
      significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
      exponent = 0;
    } else {
      significand >>= 60;
      exponent -= 15360;
    }

    uint64 result = uint64 (significand | exponent << 52);
    if (negative) result |= 0x8000000000000000;

    return bytes8 (result);
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
      0x7FFF0000000000000000000000000000;
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
      0x7FFF0000000000000000000000000000;
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

    if (absoluteX == 0) return 0;
    else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
    else return 1;
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

    uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

    // Not infinities of the same sign
    require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

    if (x == y) return 0;
    else {
      bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
      bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

      if (negativeX) {
        if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
        else return -1; 
      } else {
        if (negativeY) return 1;
        else return absoluteX > absoluteY ? int8 (1) : -1;
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    if (x == y) {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
        0x7FFF0000000000000000000000000000;
    } else return false;
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) { 
        if (x == y) return x;
        else return NaN;
      } else return x; 
    } else if (yExponent == 0x7FFF) return y;
    else {
      bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
      else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
      else {
        int256 delta = int256 (xExponent) - int256 (yExponent);
  
        if (xSign == ySign) {
          if (delta > 112) return x;
          else if (delta > 0) ySignifier >>= uint256 (delta);
          else if (delta < -112) return y;
          else if (delta < 0) {
            xSignifier >>= uint256 (-delta);
            xExponent = yExponent;
          }
  
          xSignifier += ySignifier;
  
          if (xSignifier >= 0x20000000000000000000000000000) {
            xSignifier >>= 1;
            xExponent += 1;
          }
  
          if (xExponent == 0x7FFF)
            return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
          else {
            if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
            else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
            return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier)); 
          }
        } else {
          if (delta > 0) {
            xSignifier <<= 1;
            xExponent -= 1;
          } else if (delta < 0) {
            ySignifier <<= 1;
            xExponent = yExponent - 1;
          }

          if (delta > 112) ySignifier = 1;
          else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
          else if (delta < -112) xSignifier = 1;
          else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

          if (xSignifier >= ySignifier) xSignifier -= ySignifier;
          else {
            xSignifier = ySignifier - xSignifier;
            xSign = ySign;
          }

          if (xSignifier == 0)
            return POSITIVE_ZERO;

          uint256 msb = msb (xSignifier);

          if (msb == 113) {
            xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            xExponent += 1;
          } else if (msb < 112) {
            uint256 shift = 112 - msb;
            if (xExponent > shift) {
              xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent -= shift;
            } else {
              xSignifier <<= xExponent - 1;
              xExponent = 0;
            }
          } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          if (xExponent == 0x7FFF)
            return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
          else return bytes16 (uint128 (
              (xSign ? 0x80000000000000000000000000000000 : 0) |
              (xExponent << 112) |
              xSignifier));
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    return add (x, y ^ 0x80000000000000000000000000000000);
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) {
        if (x == y) return x ^ y & 0x80000000000000000000000000000000;
        else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
        else return NaN;
      } else {
        if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      }
    } else if (yExponent == 0x7FFF) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return y ^ x & 0x80000000000000000000000000000000;
    } else {
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      xSignifier *= ySignifier;
      if (xSignifier == 0)
        return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
            NEGATIVE_ZERO : POSITIVE_ZERO;

      xExponent += yExponent;

      uint256 msb =
        xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
        xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
        msb (xSignifier);

      if (xExponent + msb < 16496) { // Underflow
        xExponent = 0;
        xSignifier = 0;
      } else if (xExponent + msb < 16608) { // Subnormal
        if (xExponent < 16496)
          xSignifier >>= 16496 - xExponent;
        else if (xExponent > 16496)
          xSignifier <<= xExponent - 16496;
        xExponent = 0;
      } else if (xExponent + msb > 49373) {
        xExponent = 0x7FFF;
        xSignifier = 0;
      } else {
        if (msb > 112)
          xSignifier >>= msb - 112;
        else if (msb < 112)
          xSignifier <<= 112 - msb;

        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        xExponent = xExponent + msb - 16607;
      }

      return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
          xExponent << 112 | xSignifier));
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) return NaN;
      else return x ^ y & 0x80000000000000000000000000000000;
    } else if (yExponent == 0x7FFF) {
      if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
      else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
    } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
      if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
      else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
    } else {
      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) {
        if (xSignifier != 0) {
          uint shift = 226 - msb (xSignifier);

          xSignifier <<= shift;

          xExponent = 1;
          yExponent += shift - 114;
        }
      }
      else {
        xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
      }

      xSignifier = xSignifier / ySignifier;
      if (xSignifier == 0)
        return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
            NEGATIVE_ZERO : POSITIVE_ZERO;

      assert (xSignifier >= 0x1000000000000000000000000000);

      uint256 msb =
        xSignifier >= 0x80000000000000000000000000000 ? msb (xSignifier) :
        xSignifier >= 0x40000000000000000000000000000 ? 114 :
        xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

      if (xExponent + msb > yExponent + 16497) { // Overflow
        xExponent = 0x7FFF;
        xSignifier = 0;
      } else if (xExponent + msb + 16380  < yExponent) { // Underflow
        xExponent = 0;
        xSignifier = 0;
      } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
        if (xExponent + 16380 > yExponent)
          xSignifier <<= xExponent + 16380 - yExponent;
        else if (xExponent + 16380 < yExponent)
          xSignifier >>= yExponent - xExponent - 16380;

        xExponent = 0;
      } else { // Normal
        if (msb > 112)
          xSignifier >>= msb - 112;

        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        xExponent = xExponent + msb + 16269 - yExponent;
      }

      return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
          xExponent << 112 | xSignifier));
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    return x ^ 0x80000000000000000000000000000000;
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
    else {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      if (xExponent == 0x7FFF) return x;
      else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return POSITIVE_ZERO;

        bool oddExponent = xExponent & 0x1 == 0;
        xExponent = xExponent + 16383 >> 1;

        if (oddExponent) {
          if (xSignifier >= 0x10000000000000000000000000000)
            xSignifier <<= 113;
          else {
            uint256 msb = msb (xSignifier);
            uint256 shift = (226 - msb) & 0xFE;
            xSignifier <<= shift;
            xExponent -= shift - 112 >> 1;
          }
        } else {
          if (xSignifier >= 0x10000000000000000000000000000)
            xSignifier <<= 112;
          else {
            uint256 msb = msb (xSignifier);
            uint256 shift = (225 - msb) & 0xFE;
            xSignifier <<= shift;
            xExponent -= shift - 112 >> 1;
          }
        }

        uint256 r = 0x10000000000000000000000000000;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
        uint256 r1 = xSignifier / r;
        if (r1 < r) r = r1;

        return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
    else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
    else {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      if (xExponent == 0x7FFF) return x;
      else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return NEGATIVE_INFINITY;

        bool resultNegative;
        uint256 resultExponent = 16495;
        uint256 resultSignifier;

        if (xExponent >= 0x3FFF) {
          resultNegative = false;
          resultSignifier = xExponent - 0x3FFF;
          xSignifier <<= 15;
        } else {
          resultNegative = true;
          if (xSignifier >= 0x10000000000000000000000000000) {
            resultSignifier = 0x3FFE - xExponent;
            xSignifier <<= 15;
          } else {
            uint256 msb = msb (xSignifier);
            resultSignifier = 16493 - msb;
            xSignifier <<= 127 - msb;
          }
        }

        if (xSignifier == 0x80000000000000000000000000000000) {
          if (resultNegative) resultSignifier += 1;
          uint256 shift = 112 - msb (resultSignifier);
          resultSignifier <<= shift;
          resultExponent -= shift;
        } else {
          uint256 bb = resultNegative ? 1 : 0;
          while (resultSignifier < 0x10000000000000000000000000000) {
            resultSignifier <<= 1;
            resultExponent -= 1;
  
            xSignifier *= xSignifier;
            uint256 b = xSignifier >> 255;
            resultSignifier += b ^ bb;
            xSignifier >>= 127 + b;
          }
        }

        return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
            resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
    else if (xExponent > 16397)
      return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
    else if (xExponent < 16255)
      return 0x3FFF0000000000000000000000000000;
    else {
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      if (xExponent > 16367)
        xSignifier <<= xExponent - 16367;
      else if (xExponent < 16367)
        xSignifier >>= 16367 - xExponent;

      if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
        return POSITIVE_ZERO;

      if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        return POSITIVE_INFINITY;

      uint256 resultExponent = xSignifier >> 128;
      xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xNegative && xSignifier != 0) {
        xSignifier = ~xSignifier;
        resultExponent += 1;
      }

      uint256 resultSignifier = 0x80000000000000000000000000000000;
      if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
      if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
      if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
      if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
      if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
      if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
      if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
      if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
      if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
      if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
      if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
      if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
      if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
      if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
      if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
      if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
      if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
      if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
      if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
      if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
      if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
      if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
      if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
      if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
      if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
      if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
      if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
      if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
      if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
      if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
      if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
      if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
      if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
      if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
      if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
      if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
      if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
      if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
      if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
      if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
      if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
      if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
      if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
      if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
      if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
      if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
      if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
      if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
      if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
      if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
      if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
      if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
      if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
      if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
      if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
      if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
      if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
      if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
      if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
      if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
      if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
      if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
      if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
      if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

      if (!xNegative) {
        resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        resultExponent += 0x3FFF;
      } else if (resultExponent <= 0x3FFE) {
        resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        resultExponent = 0x3FFF - resultExponent;
      } else {
        resultSignifier = resultSignifier >> resultExponent - 16367;
        resultExponent = 0;
      }

      return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function msb (uint256 x) private pure returns (uint256) {
    require (x > 0);

    uint256 result = 0;

    if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
    if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
    if (x >= 0x100000000) { x >>= 32; result += 32; }
    if (x >= 0x10000) { x >>= 16; result += 16; }
    if (x >= 0x100) { x >>= 8; result += 8; }
    if (x >= 0x10) { x >>= 4; result += 4; }
    if (x >= 0x4) { x >>= 2; result += 2; }
    if (x >= 0x2) result += 1; // No need to shift x anymore

    return result;
  }
}

