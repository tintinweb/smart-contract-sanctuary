// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './libraries/SafeMath.sol';

import './interfaces/IImpossibleERC20.sol';
import './interfaces/IERC20.sol';

contract ImpossibleERC20 is IImpossibleERC20 {
    using SafeMath for uint256;

    string public override name = 'Impossible Swap LPs';
    string public override symbol = 'IF-LP';
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    constructor() {
        // Initializes a placeholder name/domain separator for testing permit typehashs
        _setupDomainSeparator();
    }

    function _initBetterDesc(address _token0, address _token1) internal {
        // This sets name/symbol to include tokens in LP token
        string memory desc = string(abi.encodePacked(IERC20(_token0).symbol(), '/', IERC20(_token1).symbol()));
        name = string(abi.encodePacked('Impossible Swap LPs: ', desc));
        symbol = string(abi.encodePacked('IF-LP: ', desc));
        _setupDomainSeparator();
    }

    function _setupDomainSeparator() internal {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, 'IF: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'IF: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IImpossibleERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import '../ImpossibleERC20.sol';

contract ERC20 is ImpossibleERC20 {
    constructor(uint256 _totalSupply) {
        _mint(msg.sender, _totalSupply);
    }
}

/// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './ImpossibleERC20.sol';

import './libraries/Math.sol';
import './libraries/ReentrancyGuard.sol';

import './interfaces/IImpossiblePair.sol';
import './interfaces/IERC20.sol';
import './interfaces/IImpossibleSwapFactory.sol';
import './interfaces/IImpossibleCallee.sol';

/**
    @title  Pair contract for Impossible Swap V3
    @author Impossible Finance
    @notice This factory builds upon basic Uni V2 Pair by adding xybk
            invariant, ability to switch between invariants/boost levels,
            and ability to set asymmetrical tuning.
    @dev    See documentation at: https://docs.impossible.finance/impossible-swap/overview
*/

contract ImpossiblePair is IImpossiblePair, ImpossibleERC20, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    /**
     @dev Timestamps, not block numbers
    */
    uint256 private constant THIRTY_MINS = 108000;
    uint32 private constant TWO_WEEKS = 1209600;
    uint32 private constant ONE_DAY = 86400;

    /**
     @dev tradeFee is fee collected per swap in basis points. Init at 30bp.
    */
    uint16 private tradeFee = 30;

    /**
     @dev tradeState Tracks what directional trades are allowed for this pair.
    */
    TradeState private tradeState;

    bool private isXybk;

    address public override factory;
    address public override token0;
    address public override token1;
    address public router;
    address public routerExtension;

    uint128 private reserve0;
    uint128 private reserve1;

    uint256 public kLast;

    /**
     @dev These are the variables for boost.
     @dev Boosts in practice are a function of oldBoost, newBoost, startBlock and endBlock
     @dev We linearly interpolate between oldBoost and newBoost over the blocks
     @dev Note that governance being able to instantly change boosts is dangerous
     @dev Boost0 applies when pool balance0 >= balance1 (when token1 is the more expensive token)
     @dev Boost1 applies when pool balance1 > balance0 (when token0 is the more expensive token)
    */
    uint32 private oldBoost0 = 1;
    uint32 private oldBoost1 = 1;
    uint32 private newBoost0 = 1;
    uint32 private newBoost1 = 1;
    uint32 private currBoost0 = 1;
    uint32 private currBoost1 = 1;

    /**
     @dev BSC mines 10m blocks a year. uint32 will last 400 years before overflowing
    */
    uint256 public startTime;
    uint256 public endTime;

    /**
     @dev withdrawalFeeRatio is the fee collected on burn. Init as 1/201=0.4795% fee (if feeOn)
    */
    uint256 public withdrawalFeeRatio = 201; //

    /**
     @dev Delay sets the duration for boost changes over time. Init as 1 day
     @dev In test environment, set to 50 blocks.
    */
    uint256 public override delay = ONE_DAY;

    modifier onlyIFRouter() {
        require(msg.sender == router || msg.sender == routerExtension, 'IF: FORBIDDEN');
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == IImpossibleSwapFactory(factory).governance(), 'IF: FORBIDDEN');
        _;
    }

    /**
     @notice Gets the fee per swap in basis points, as well as if this pair is uni or xybk
     @return _tradeFee Fee per swap in basis points
     @return _tradeState What trades are allowed for this pair
     @return _isXybk Boolean if this swap is using uniswap or xybk
    */
    function getPairSettings()
        external
        view
        override
        returns (
            uint16 _tradeFee,
            TradeState _tradeState,
            bool _isXybk
        )
    {
        _tradeFee = tradeFee;
        _tradeState = tradeState;
        _isXybk = isXybk;
    }

    /**
     @notice Gets the reserves in the pair contract
     @return _reserve0 Reserve amount of token0 in the pair
     @return _reserve1 Reserve amount of token1 in the pair
    */
    function getReserves() public view override returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = uint256(reserve0);
        _reserve1 = uint256(reserve1);
    }

    /**
     @notice Getter for the stored boost state
     @dev Helper function for internal use. If uni invariant, all boosts=1
     @return _newBoost0 New boost0 value
     @return _newBoost1 New boost1 value
     @return _oldBoost0 Old boost0 value
     @return _oldBoost1 Old boost1 value
    */
    function getBoost()
        internal
        view
        returns (
            uint32 _newBoost0,
            uint32 _newBoost1,
            uint32 _oldBoost0,
            uint32 _oldBoost1,
            uint32 _currBoost0,
            uint32 _currBoost1
        )
    {
        _newBoost0 = newBoost0;
        _newBoost1 = newBoost1;
        _oldBoost0 = oldBoost0;
        _oldBoost1 = oldBoost1;
        _currBoost0 = currBoost0;
        _currBoost1 = currBoost1;
    }

    /**
     @notice Helper function to calculate a linearly interpolated boost
     @dev Calculations: old + |new - old| * (curr-start)/end-start
     @param oldBst The old boost
     @param newBst The new boost
     @param end The endblock which linear interpolation ends at
     @return uint256 Linearly interpolated boost value
    */
    function linInterpolate(
        uint32 oldBst,
        uint32 newBst,
        uint256 end
    ) internal view returns (uint256) {
        uint256 start = startTime;
        if (newBst > oldBst) {
            /// old + diff * (curr-start) / (end-start)
            return
                uint256(oldBst).add(
                    (uint256(newBst).sub(uint256(oldBst))).mul(block.timestamp.sub(start)).div(end.sub(start))
                );
        } else {
            /// old - diff * (curr-start) / (end-start)
            return
                uint256(oldBst).sub(
                    (uint256(oldBst).sub(uint256(newBst))).mul(block.timestamp.sub(start)).div(end.sub(start))
                );
        }
    }

    /**
     @notice Function to get/calculate actual boosts in the system
     @dev If block.timestamp > endBlock, just return new boosts
     @return _boost0 The actual boost0 value
     @return _boost1 The actual boost1 value
    */
    function calcBoost() public view override returns (uint256 _boost0, uint256 _boost1) {
        uint256 _endTime = endTime;
        if (block.timestamp >= _endTime) {
            (uint32 _newBoost0, uint32 _newBoost1, , , , ) = getBoost();
            _boost0 = uint256(_newBoost0);
            _boost1 = uint256(_newBoost1);
        } else {
            (
                uint32 _newBoost0,
                uint32 _newBoost1,
                uint32 _oldBoost0,
                uint32 _oldBoost1,
                uint32 _currBoost0,
                uint32 _currBoost1
            ) = getBoost();
            _boost0 = linInterpolate(_oldBoost0, _newBoost0, _endTime);
            _boost1 = linInterpolate(_oldBoost1, _newBoost1, _endTime);
            if (xybkComputeK(_boost0, _boost1) < kLast) {
                _boost0 = _currBoost0;
                _boost1 = _currBoost1;
            }
        }
    }

    function calcBoostWithUpdate() internal returns (uint256 _boost0, uint256 _boost1) {
        (_boost0, _boost1) = calcBoost();
        currBoost0 = uint32(_boost0);
        currBoost1 = uint32(_boost1);
    }

    /**
     @notice Safe transfer implementation for tokens
     @dev Requires the transfer to succeed and return either null or True
     @param token The token to transfer
     @param to The address to transfer to
     @param value The amount of tokens to transfer
    */
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'IF: TRANSFER_FAILED');
    }

    /**
     @notice Switches pool from uniswap invariant to xybk invariant
     @dev Can only be called by IF governance
     @dev Requires the pool to be uniswap invariant currently
     @param _newBoost0 The new boost0
     @param _newBoost1 The new boost1
    */
    function makeXybk(uint32 _newBoost0, uint32 _newBoost1) external onlyGovernance nonReentrant {
        require(!isXybk, 'IF: IS_ALREADY_XYBK');
        _updateBoost(_newBoost0, _newBoost1);
        isXybk = true;
        emit ChangeInvariant(isXybk, _newBoost0, _newBoost1);
    }

    /**
     @notice Switches pool from xybk invariant to uniswap invariant
     @dev Can only be called by IF governance
     @dev Requires the pool to be xybk invariant currently
    */
    function makeUni() external onlyGovernance nonReentrant {
        require(isXybk, 'IF: IS_ALREADY_UNI');
        require(block.timestamp >= endTime, 'IF: BOOST_ALREADY_CHANGING');
        require(newBoost0 == 1 && newBoost1 == 1, 'IF: INVALID_BOOST');
        isXybk = false;
        oldBoost0 = 1; // Set boost to 1
        oldBoost1 = 1; // xybk with boost=1 is just xy=k formula
        emit ChangeInvariant(isXybk, newBoost0, newBoost1);
    }

    /**
     @notice Setter function for trade fee per swap
     @dev Can only be called by IF governance
     @dev uint8 fee means 255 basis points max, or max trade fee of 2.56%
     @dev uint8 type means fee cannot be negative
     @param _newFee The new trade fee collected per swap, in basis points
    */
    function updateTradeFees(uint8 _newFee) external onlyGovernance {
        uint16 _oldFee = tradeFee;
        tradeFee = uint16(_newFee);
        emit UpdatedTradeFees(_oldFee, _newFee);
    }

    /**
     @notice Setter function for time delay for boost changes
     @dev Can only be called by IF governance
     @dev Delay must be between 30 minutes and 2 weeks
     @param _newDelay The new time delay in seconds
    */
    function updateDelay(uint256 _newDelay) external onlyGovernance {
        require(_newDelay >= THIRTY_MINS && delay <= TWO_WEEKS, 'IF: INVALID_DELAY');
        uint256 _oldDelay = delay;
        delay = _newDelay;
        emit UpdatedDelay(_oldDelay, _newDelay);
    }

    /**
     @notice Setter function for trade state for this pair
     @dev Can only be called by IF governance
     @param _tradeState See line 45 for TradeState enum settings
    */
    function updateTradeState(TradeState _tradeState) external onlyGovernance nonReentrant {
        require(isXybk, 'IF: IS_CURRENTLY_UNI');
        tradeState = _tradeState;
        emit UpdatedTradeState(_tradeState);
    }

    /**
     @notice Setter function for pool boost state
     @dev Can only be called by IF governance
     @dev Pool has to be using xybk invariant to update boost
     @param _newBoost0 The new boost0
     @param _newBoost1 The new boost1
    */
    function updateBoost(uint32 _newBoost0, uint32 _newBoost1) external onlyGovernance nonReentrant {
        require(isXybk, 'IF: IS_CURRENTLY_UNI');
        _updateBoost(_newBoost0, _newBoost1);
    }

    /**
     @notice Internal helper function to change boosts
     @dev _newBoost0 and _newBoost1 have to be between 1 and 1000000
     @dev Pool cannot already have changing boosts
     @param _newBoost0 The new boost0
     @param _newBoost1 The new boost1
    */
    function _updateBoost(uint32 _newBoost0, uint32 _newBoost1) internal {
        require(
            _newBoost0 >= 1 && _newBoost1 >= 1 && _newBoost0 <= 1000000 && _newBoost1 <= 1000000,
            'IF: INVALID_BOOST'
        );
        uint256 _blockTimestamp = block.timestamp;
        require(_blockTimestamp >= endTime, 'IF: BOOST_ALREADY_CHANGING');
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        _mintFee(_reserve0, _reserve1);
        oldBoost0 = newBoost0;
        oldBoost1 = newBoost1;
        newBoost0 = _newBoost0;
        newBoost1 = _newBoost1;
        startTime = _blockTimestamp;
        endTime = _blockTimestamp + delay;
        emit UpdatedBoost(oldBoost0, oldBoost1, newBoost0, newBoost1, startTime, endTime);
    }

    /**
     @notice Setter function for the withdrawal fee that goes to Impossible per burn
     @dev Can only be called by IF governance
     @dev Fee is 1/_newFeeRatio. So <1% is 1/(>=100)
     @param _newFeeRatio The new fee ratio
    */
    function updateWithdrawalFeeRatio(uint256 _newFeeRatio) external onlyGovernance {
        require(_newFeeRatio >= 100, 'IF: INVALID_FEE'); // capped at 1%
        uint256 _oldFeeRatio = withdrawalFeeRatio;
        withdrawalFeeRatio = _newFeeRatio;
        emit UpdatedWithdrawalFeeRatio(_oldFeeRatio, _newFeeRatio);
    }

    /**
     @notice Constructor function for pair address
     @dev For pairs associated with IF swap, msg.sender is always the factory
    */
    constructor() {
        factory = msg.sender;
    }

    /**
     @notice Initialization function by factory on deployment
     @dev Can only be called by factory, and will only be called once
     @dev _initBetterDesc adds token0/token1 symbols to ERC20 LP name, symbol
     @param _token0 Address of token0 in pair
     @param _token0 Address of token1 in pair
     @param _router Address of trusted IF router
    */
    function initialize(
        address _token0,
        address _token1,
        address _router,
        address _routerExtension
    ) external override {
        require(msg.sender == factory, 'IF: FORBIDDEN');
        router = _router;
        routerExtension = _routerExtension;
        token0 = _token0;
        token1 = _token1;
        _initBetterDesc(_token0, _token1);
    }

    /**
     @notice Updates reserve state in pair
     @dev No TWAP/oracle functionality
     @param balance0 The new balance for token0
     @param balance1 The new balance for token1
    */
    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = uint128(balance0);
        reserve1 = uint128(balance1);
        emit Sync(reserve0, reserve1);
    }

    /**
     @notice Mints fee to IF governance multisig treasury
     @dev If feeOn, mint liquidity equal to 4/5th of growth in sqrt(K)
     @param _reserve0 The latest balance for token0 for fee calculations
     @param _reserve1 The latest balance for token1 for fee calculations
     @return feeOn If the mint/burn fee is turned on in this pair
    */
    function _mintFee(uint256 _reserve0, uint256 _reserve1) private returns (bool feeOn) {
        address feeTo = IImpossibleSwapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 oldK = kLast; // gas savings
        if (feeOn) {
            if (oldK != 0) {
                (uint256 _boost0, uint256 _boost1) = calcBoostWithUpdate();
                uint256 newRootK = isXybk
                    ? Math.sqrt(xybkComputeK(_boost0, _boost1))
                    : Math.sqrt(_reserve0.mul(_reserve1));
                uint256 oldRootK = Math.sqrt(oldK);
                if (newRootK > oldRootK) {
                    uint256 numerator = totalSupply.mul(newRootK.sub(oldRootK)).mul(4);
                    uint256 denominator = newRootK.add(oldRootK.mul(4));
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (oldK != 0) {
            kLast = 0;
        }
    }

    /**
     @notice Mints LP tokens based on sent underlying tokens. Underlying tokens must already be sent to contract
     @dev Function should be called from IF router unless you know what you're doing
     @dev Openzeppelin reentrancy guards are used
     @dev First mint must have both token0 and token1. 
     @param to The address to mint LP tokens to
     @return liquidity The amount of LP tokens minted
    */
    function mint(address to) external override nonReentrant returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                _reserve0 > 0 ? amount0.mul(_totalSupply) / _reserve0 : uint256(-1),
                _reserve1 > 0 ? amount1.mul(_totalSupply) / _reserve1 : uint256(-1)
            );
        }
        require(liquidity > 0, 'IF: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1);
        (uint256 _boost0, uint256 _boost1) = calcBoostWithUpdate();
        if (feeOn) kLast = isXybk ? xybkComputeK(_boost0, _boost1) : balance0.mul(balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     @notice Burns LP tokens and returns underlying tokens. LP tokens must already be sent to contract
     @dev Function should be called from IF router unless you know what you're doing
     @dev Openzeppelin reentrancy guards are used
     @param to The address to send underlying tokens to
     @return amount0 The amount of token0's sent
     @return amount1 The amount of token1's sent
    */
    function burn(address to) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint256 _reserve0, uint256 _reserve1) = getReserves(); // gas savings
        bool feeOn = _mintFee(_reserve0, _reserve1);
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        {
            uint256 _totalSupply = totalSupply;
            amount0 = liquidity.mul(balance0) / _totalSupply;
            amount1 = liquidity.mul(balance1) / _totalSupply;
            require(amount0 > 0 || amount1 > 0, 'IF: INSUFFICIENT_LIQUIDITY_BURNED');

            address _feeTo = IImpossibleSwapFactory(factory).feeTo();
            // Burning fees are paid if burn tx doesnt originate from not IF fee collector
            if (feeOn && tx.origin != _feeTo) {
                uint256 _feeRatio = withdrawalFeeRatio; // default is 1/201 ~= 0.4975%
                amount0 -= amount0.div(_feeRatio);
                amount1 -= amount1.div(_feeRatio);
                // Transfers withdrawalFee of LP tokens to IF feeTo
                uint256 transferAmount = liquidity.div(_feeRatio);
                _safeTransfer(address(this), IImpossibleSwapFactory(factory).feeTo(), transferAmount);
                _burn(address(this), liquidity.sub(transferAmount));
            } else {
                _burn(address(this), liquidity);
            }

            _safeTransfer(_token0, to, amount0);
            _safeTransfer(_token1, to, amount1);
        }

        {
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
            _update(balance0, balance1);
            if (feeOn) kLast = isXybk ? xybkComputeK(balance0, balance1) : balance0.mul(balance1);
        }
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /**
     @notice Performs a swap operation. Tokens must already be sent to contract
     @dev Input/output amount of tokens must >0 and pool needs to have sufficient liquidity
     @dev Openzeppelin reentrancy guards are used
     @dev Post-swap invariant check is performed (either uni or xybk)
     @param amount0Out The amount of token0's to output
     @param amount1Out The amount of token1's to output
     @param to The address to output tokens to
     @param data Call data allowing for another function call
    */
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override onlyIFRouter nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, 'IF: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint256 _reserve0, uint256 _reserve1) = getReserves(); // gas savings
        require(amount0Out <= _reserve0 && amount1Out <= _reserve1, 'IF: INSUFFICIENT_LIQUIDITY');

        uint256 balance0;
        uint256 balance1;
        uint256 amount0In;
        uint256 amount1In;
        {
            require(to != token0 && to != token1, 'IF: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IImpossibleCallee(to).ImpossibleCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
            // Check bounds
            amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
            amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        }

        require(amount0In > 0 || amount1In > 0, 'IF: INSUFFICIENT_INPUT_AMOUNT');

        {
            // Avoid stack too deep errors
            bool _isXybk = isXybk;
            uint256 _tradeFee = uint256(tradeFee);
            uint256 balance0Adjusted = balance0.mul(10000).sub(amount0In.mul(_tradeFee)); // tradeFee amt of basis pts
            uint256 balance1Adjusted = balance1.mul(10000).sub(amount1In.mul(_tradeFee)); // tradeFee amt of basis pts
            if (_isXybk) {
                // Check if trade is legal
                TradeState _tradeState = tradeState;
                require(
                    (_tradeState == TradeState.SELL_ALL) ||
                        (_tradeState == TradeState.SELL_TOKEN_0 && amount1Out == 0) ||
                        (_tradeState == TradeState.SELL_TOKEN_1 && amount0Out == 0),
                    'IF: TRADE_NOT_ALLOWED'
                );

                (uint256 boost0, uint256 boost1) = calcBoost(); // dont update boost
                uint256 scaledOldK = xybkComputeK(boost0, boost1).mul(10000**2);
                require(
                    xybkCheckK(boost0, boost1, balance0Adjusted, balance1Adjusted, scaledOldK),
                    'IF: INSUFFICIENT_XYBK_K'
                );
            } else {
                require(
                    balance0Adjusted.mul(balance1Adjusted) >= _reserve0.mul(_reserve1).mul(10000**2),
                    'IF: INSUFFICIENT_UNI_K'
                );
            }
        }

        _update(balance0, balance1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /** 
     @notice Calculates xybk K value
     @dev Uses library function, same as router
     @param _boost0 boost0 to calculate xybk K with
     @param _boost1 boost1 to calculate xybk K with
     @return k The k value given these reserves and boost values
     */
    function xybkComputeK(uint256 _boost0, uint256 _boost1) internal view returns (uint256 k) {
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        uint256 boost = (_reserve0 > _reserve1) ? _boost0.sub(1) : _boost1.sub(1);
        uint256 denom = boost.mul(2).add(1); // 1+2*boost
        uint256 term = boost.mul(_reserve0.add(_reserve1)).div(denom.mul(2)); // boost*(x+y)/(2+4*boost)
        k = (Math.sqrt(term**2 + _reserve0.mul(_reserve1).div(denom)) + term)**2;
    }

    /**
     @notice Performing K invariant check through an approximation from old K
     @dev More details on math at: https://docs.impossible.finance/impossible-swap/swap-math
     @dev If K_new >= K_old, correctness should still hold
     @param boost0 Current boost0 in pair
     @param boost1 Current boost1 in pair
     @param balance0 Current state of balance0 in pair
     @param balance1 Current state of balance1 in pair
     @param oldK The pre-swap K value
     @return bool Whether the new balances satisfy the K check for xybk
    */
    function xybkCheckK(
        uint256 boost0,
        uint256 boost1,
        uint256 balance0,
        uint256 balance1,
        uint256 oldK
    ) internal pure returns (bool) {
        uint256 oldSqrtK = Math.sqrt(oldK);
        uint256 boost = (balance0 > balance1) ? boost0.sub(1) : boost1.sub(1);
        uint256 innerTerm = boost.mul(oldSqrtK);
        return (balance0.add(innerTerm)).mul(balance1.add(innerTerm)).div((boost.add(1))**2) >= oldK;
    }

    /**
     @notice Forces balances to match reserves
     @dev Requires balance0 >= reserve0 and balance1 >= reserve1
     @param to Address to send excess underlying tokens to
    */
    function skim(address to) external override nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(_reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(_reserve1));
    }

    /**
     @notice Forces reserves to match balances
    */
    function sync() external override nonReentrant {
        uint256 _balance0 = IERC20(token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(token1).balanceOf(address(this));
        _update(_balance0, _balance1);
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
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

    constructor() {
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
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './IImpossibleERC20.sol';

interface IImpossiblePair is IImpossibleERC20 {
    enum TradeState {
        SELL_ALL,
        SELL_TOKEN_0,
        SELL_TOKEN_1,
        SELL_NONE
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event ChangeInvariant(bool _isXybk, uint256 _newBoost0, uint256 _newBoost1);
    event UpdatedTradeFees(uint256 _oldFee, uint256 _newFee);
    event UpdatedDelay(uint256 _oldDelay, uint256 _newDelay);
    event UpdatedTradeState(TradeState _tradeState);
    event UpdatedWithdrawalFeeRatio(uint256 _oldWithdrawalFee, uint256 _newWithdrawalFee);
    event UpdatedBoost(
        uint32 _oldBoost0,
        uint32 _oldBoost1,
        uint32 _newBoost0,
        uint32 _newBoost1,
        uint256 _start,
        uint256 _end
    );

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address); // address of token0

    function token1() external view returns (address); // address of token1

    function getReserves() external view returns (uint256, uint256); // reserves of token0/token1

    function calcBoost() external view returns (uint256, uint256);

    function mint(address) external returns (uint256);

    function burn(address) external returns (uint256, uint256);

    function swap(
        uint256,
        uint256,
        address,
        bytes calldata
    ) external;

    function skim(address to) external;

    function sync() external;

    function getPairSettings()
        external
        view
        returns (
            uint16,
            TradeState,
            bool
        ); // Uses single storage slot, save gas

    function delay() external view returns (uint256); // Amount of time delay required before any change to boost etc, denoted in seconds

    function initialize(
        address,
        address,
        address,
        address
    ) external;
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IImpossibleSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event UpdatedGovernance(address governance);

    function feeTo() external view returns (address);

    function governance() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setGovernance(address) external;
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IImpossibleCallee {
    function ImpossibleCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './ImpossiblePair.sol';
import './ImpossibleWrappedToken.sol';

import './interfaces/IImpossibleSwapFactory.sol';

/**
    @title  Swap Factory for Impossible Swap V3
    @author Impossible Finance
    @notice This factory builds upon basic Uni V2 factory by changing "feeToSetter"
            to "governance" and adding a whitelist
    @dev    See documentation at: https://docs.impossible.finance/impossible-swap/overview
*/

contract ImpossibleSwapFactory is IImpossibleSwapFactory {
    address public override feeTo;
    address public override governance;
    address public router;
    address public routerExtension;
    bool public whitelist;
    mapping(address => bool) public approvedTokens;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    /**
     @notice The constructor for the IF swap factory
     @param _governance The address for IF Governance
    */
    constructor(address _governance) {
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, 'IF: FORBIDDEN');
        _;
    }

    /**
     @notice The constructor for the IF swap factory
     @dev _governance The address for IF Governance
     @return uint256 The current number of pairs in the IF swap
    */
    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    /**
     @notice Sets router address in factory
     @dev Router is checked in pair contracts to ensure calls are from IF routers only
     @dev Can only be set by IF governance
     @param _router The address of the IF router
     @param _routerExtension The address of the IF router extension
    */
    function setRouterAndExtension(address _router, address _routerExtension) external onlyGovernance {
        router = _router;
        routerExtension = _routerExtension;
    }

    /**
     @notice Either allow or stop a token from being a valid token for new pair contracts
     @dev Changes can only be made by IF governance
     @param token The address of the token
     @param allowed The boolean to include/exclude this token in the whitelist
    */
    function changeTokenAccess(address token, bool allowed) external onlyGovernance {
        approvedTokens[token] = allowed;
    }

    /**
     @notice Turns on or turns off the whitelist feature
     @dev Can only be set by IF governance
     @param b The boolean that whitelist is set to
    */
    function setWhitelist(bool b) external onlyGovernance {
        whitelist = b;
    }

    /**
     @notice Creates a new Impossible Pair contract
     @dev If whitelist is on, can only use approved tokens in whitelist
     @dev tokenA must not be equal to tokenB
     @param tokenA The address of token A. Token A will be in the new Pair contract
     @param tokenB The address of token B. Token B will be in the new Pair contract
     @return pair The address of the created pair containing token A and token B
    */
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        if (whitelist) {
            require(approvedTokens[tokenA] && approvedTokens[tokenB], 'IF: RESTRICTED_TOKENS');
        }
        require(tokenA != tokenB, 'IF: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'IF: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'IF: PAIR_EXISTS');

        bytes memory bytecode = type(ImpossiblePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IImpossiblePair(pair).initialize(token0, token1, router, routerExtension);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     @notice Sets the address that fees from the swap are paid to
     @dev Can only be called by IF governance
     @param _feeTo The address that will receive swap fees
    */
    function setFeeTo(address _feeTo) external override onlyGovernance {
        feeTo = _feeTo;
    }

    /**
     @notice Sets the address for IF governance
     @dev Can only be called by IF governance
     @param _governance The address of the new IF governance
    */
    function setGovernance(address _governance) external override onlyGovernance {
        governance = _governance;
    }
}

// SPDX-License-Identifier: GPL-3

pragma solidity =0.7.6;

import './libraries/TransferHelper.sol';
import './libraries/SafeMath.sol';
import './libraries/ReentrancyGuard.sol';

import './interfaces/IImpossibleWrappedToken.sol';
import './interfaces/IERC20.sol';

contract ImpossibleWrappedToken is IImpossibleWrappedToken, ReentrancyGuard {
    using SafeMath for uint256;

    string public override name;
    string public override symbol;
    uint8 public override decimals = 18;
    uint256 public override totalSupply;

    IERC20 public underlying;
    uint256 public underlyingBalance;
    uint256 public ratioNum;
    uint256 public ratioDenom;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(
        address _underlying,
        uint256 _ratioNum,
        uint256 _ratioDenom
    ) {
        underlying = IERC20(_underlying);
        ratioNum = _ratioNum;
        ratioDenom = _ratioDenom;
        string memory desc = string(abi.encodePacked(underlying.symbol()));
        name = string(abi.encodePacked('IF-Wrapped ', desc));
        symbol = string(abi.encodePacked('WIF ', desc));
    }

    // amt = amount of wrapped tokens
    function deposit(address dst, uint256 sendAmt) public override nonReentrant returns (uint256 wad) {
        TransferHelper.safeTransferFrom(address(underlying), msg.sender, address(this), sendAmt);
        uint256 receiveAmt = IERC20(underlying).balanceOf(address(this)).sub(underlyingBalance);
        wad = receiveAmt.mul(ratioNum).div(ratioDenom);
        balanceOf[dst] = balanceOf[dst].add(wad);
        totalSupply = totalSupply.add(wad);
        underlyingBalance = underlyingBalance.add(receiveAmt);
        emit Transfer(address(0), dst, wad);
    }

    // wad = amount of wrapped tokens
    function withdraw(address dst, uint256 wad) public override nonReentrant returns (uint256 transferAmt) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(wad);
        totalSupply = totalSupply.sub(wad);
        transferAmt = wad.mul(ratioDenom).div(ratioNum);
        TransferHelper.safeTransfer(address(underlying), dst, transferAmt);
        underlyingBalance = underlyingBalance.sub(transferAmt);
        emit Transfer(msg.sender, address(0), wad);
    }

    function amtToUnderlyingAmt(uint256 amt) public view override returns (uint256) {
        return amt.mul(ratioDenom).div(ratioNum);
    }

    function approve(address guy, uint256 wad) public override returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public override returns (bool) {
        require(dst != address(0x0), 'IF Wrapper: INVALID_DST');
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public override returns (bool) {
        require(balanceOf[src] >= wad, '');
        require(dst != address(0x0), 'IF Wrapper: INVALID_DST');

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad, 'ImpossibleWrapper: INSUFF_ALLOWANCE');
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './IERC20.sol';

interface IImpossibleWrappedToken is IERC20 {
    function deposit(address, uint256) external returns (uint256);

    function withdraw(address, uint256) external returns (uint256);

    function amtToUnderlyingAmt(uint256) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './interfaces/IImpossiblePair.sol';
import './interfaces/IImpossibleSwapFactory.sol';
import './interfaces/IImpossibleRouterExtension.sol';

import './libraries/ImpossibleLibrary.sol';

contract ImpossibleRouterExtension is IImpossibleRouterExtension {
    address public immutable override factory;

    constructor(address _factory) {
        factory = _factory;
    }

    /**
     @notice Helper function for basic swap
     @dev Requires the initial amount to have been sent to the first pair contract
     @param amounts[] An array of trade amounts. Trades are made from arr idx 0 to arr end idx sequentially
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
    */
    function swap(uint256[] memory amounts, address[] memory path) public override {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = ImpossibleLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? ImpossibleLibrary.pairFor(factory, output, path[i + 2]) : msg.sender;
            IImpossiblePair(ImpossibleLibrary.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    /**
     @notice Helper function for swap supporting fee on transfer tokens
     @dev Requires the initial amount to have been sent to the first pair contract
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
    */
    function swapSupportingFeeOnTransferTokens(address[] memory path) public override {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (uint256 amount0Out, uint256 amount1Out) = ImpossibleLibrary.getAmountOutFeeOnTransfer(
                input,
                output,
                factory
            );
            address to = i < path.length - 2 ? ImpossibleLibrary.pairFor(factory, output, path[i + 2]) : msg.sender;
            IImpossiblePair(ImpossibleLibrary.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    /**
     @notice Helper function for adding liquidity
     @dev Logic is unchanged from uniswap-V2-Router02
     @param tokenA The address of underlying tokenA to add
     @param tokenB The address of underlying tokenB to add
     @param amountADesired The desired amount of tokenA to add
     @param amountBDesired The desired amount of tokenB to add
     @param amountAMin The min amount of tokenA to add (amountAMin:amountBDesired sets bounds on ratio)
     @param amountBMin The min amount of tokenB to add (amountADesired:amountBMin sets bounds on ratio)
     @return amountA Actual amount of tokenA added as liquidity to pair
     @return amountB Actual amount of tokenB added as liquidity to pair
    */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) public override returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IImpossibleSwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IImpossibleSwapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB, ) = ImpossibleLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else if (reserveA == 0) {
            amountB = amountBDesired;
        } else if (reserveB == 0) {
            amountA = amountADesired;
        } else {
            uint256 amountBOptimal = ImpossibleLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ImpossibleRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = ImpossibleLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ImpossibleRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     @notice Helper function for removing liquidity
     @dev Logic is unchanged from uniswap-V2-Router02
     @param tokenA The address of underlying tokenA in LP token
     @param tokenB The address of underlying tokenB in LP token
     @param pair The address of the pair corresponding to tokenA and tokenB
     @param amountAMin The min amount of underlying tokenA that has to be received
     @param amountBMin The min amount of underlying tokenB that has to be received
     @return amountA Actual amount of underlying tokenA received
     @return amountB Actual amount of underlying tokenB received
    */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        address pair,
        uint256 amountAMin,
        uint256 amountBMin
    ) public override returns (uint256 amountA, uint256 amountB) {
        (uint256 amount0, uint256 amount1) = IImpossiblePair(pair).burn(msg.sender);
        (address token0, ) = ImpossibleLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'ImpossibleRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'ImpossibleRouter: INSUFFICIENT_B_AMOUNT');
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return ImpossibleLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) public view virtual override returns (uint256 amountOut) {
        return ImpossibleLibrary.getAmountOut(amountIn, tokenIn, tokenOut, factory);
    }

    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) public view virtual override returns (uint256 amountIn) {
        return ImpossibleLibrary.getAmountIn(amountOut, tokenIn, tokenOut, factory);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return ImpossibleLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return ImpossibleLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './IImpossiblePair.sol';

interface IImpossibleRouterExtension {
    function factory() external returns (address factoryAddr);

    function swap(uint256[] memory amounts, address[] memory path) external;

    function swapSupportingFeeOnTransferTokens(address[] memory path) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        address pair,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

/// SPDX-License-Identifier: GPL-3
pragma solidity >=0.5.0;

import '../interfaces/IImpossiblePair.sol';
import '../interfaces/IERC20.sol';

import './SafeMath.sol';
import './Math.sol';

library ImpossibleLibrary {
    using SafeMath for uint256;

    /**
     @notice Sorts tokens in ascending order
     @param tokenA The address of token A
     @param tokenB The address of token B
     @return token0 The address of token 0 (lexicographically smaller than addr of token 1)
     @return token1 The address of token 1 (lexicographically larger than addr of token 0)
    */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ImpossibleLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ImpossibleLibrary: ZERO_ADDRESS');
    }

    /**
     @notice Computes the pair contract create2 address deterministically
     @param factory The address of the token factory (pair contract deployer)
     @param tokenA The address of token A
     @param tokenB The address of token B
     @return pair The address of the pair containing token A and B
    */
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex'fc84b622ba228c468b74c2d99bfe9454ffac280ac017f05a02feb9f739aeb1e4' // init code hash                    
                    )
                )
            )
        );
    }

    /**
     @notice Obtains the token reserves in the pair contract
     @param factory The address of the token factory (pair contract deployer)
     @param tokenA The address of token A
     @param tokenB The address of token B
     @return reserveA The amount of token A in reserves
     @return reserveB The amount of token B in reserves
     @return pair The address of the pair containing token A and B
    */
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            address pair
        )
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        pair = pairFor(factory, tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = IImpossiblePair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     @notice Quote returns amountB based on some amountA, in the ratio of reserveA:reserveB
     @param amountA The amount of token A
     @param reserveA The amount of reserveA
     @param reserveB The amount of reserveB
     @return amountB The amount of token B that matches amount A in the ratio of reserves
    */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'ImpossibleLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'ImpossibleLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /**
     @notice Internal function to compute the K value for an xybk pair based on token balances and boost
     @dev More details on math at: https://docs.impossible.finance/impossible-swap/swap-math
     @dev Implementation is the same as in pair
     @param boost0 Current boost0 in pair
     @param boost1 Current boost1 in pair
     @param balance0 Current state of balance0 in pair
     @param balance1 Current state of balance1 in pair
     @return k Value of K invariant
    */
    function xybkComputeK(
        uint256 boost0,
        uint256 boost1,
        uint256 balance0,
        uint256 balance1
    ) internal pure returns (uint256 k) {
        uint256 boost = (balance0 > balance1) ? boost0.sub(1) : boost1.sub(1);
        uint256 denom = boost.mul(2).add(1); // 1+2*boost
        uint256 term = boost.mul(balance0.add(balance1)).div(denom.mul(2)); // boost*(x+y)/(2+4*boost)
        k = (Math.sqrt(term**2 + balance0.mul(balance1).div(denom)) + term)**2;
    }

    /**
     @notice Internal helper function for calculating artificial liquidity
     @dev More details on math at: https://docs.impossible.finance/impossible-swap/swap-math
     @param _boost The boost variable on the correct side for the pair contract
     @param _sqrtK The sqrt of the invariant variable K in xybk formula
     @return uint256 The artificial liquidity term
    */
    function calcArtiLiquidityTerm(uint256 _boost, uint256 _sqrtK) internal pure returns (uint256) {
        return (_boost - 1).mul(_sqrtK);
    }

    /**
     @notice Quotes maximum output given exact input amount of tokens and addresses of tokens in pair
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param amountIn The input amount of token A
     @param tokenIn The address of input token
     @param tokenOut The address of output token
     @param factory The address of the factory contract
     @return amountOut The maximum output amount of token B for a valid swap
    */
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256 amountOut) {
        require(amountIn > 0, 'ImpossibleLibrary: INSUFFICIENT_INPUT_AMOUNT');
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 amountInPostFee;
        address pair;
        bool isMatch;
        {
            // Avoid stack too deep
            (address token0, ) = sortTokens(tokenIn, tokenOut);
            isMatch = tokenIn == token0;
            (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut);
        }
        uint256 artiLiqTerm;
        bool isXybk;
        {
            // Avoid stack too deep
            uint256 fee;
            IImpossiblePair.TradeState tradeState;
            (fee, tradeState, isXybk) = IImpossiblePair(pair).getPairSettings();
            amountInPostFee = amountIn.mul(10000 - fee);
            require(
                (tradeState == IImpossiblePair.TradeState.SELL_ALL) ||
                    (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_0 && !isMatch) ||
                    (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_1 && isMatch),
                'ImpossibleLibrary: TRADE_NOT_ALLOWED'
            );
        }

        /// If xybk invariant, set reserveIn/reserveOut to artificial liquidity instead of actual liquidity
        if (isXybk) {
            (uint256 boost0, uint256 boost1) = IImpossiblePair(pair).calcBoost();
            uint256 sqrtK = Math.sqrt(
                xybkComputeK(boost0, boost1, isMatch ? reserveIn : reserveOut, isMatch ? reserveOut : reserveIn)
            );
            /// since balance0=balance1 only at sqrtK, if final balanceIn >= sqrtK means balanceIn >= balanceOut
            /// Use post-fee balances to maintain consistency with pair contract K invariant check
            if (amountInPostFee.add(reserveIn.mul(10000)) >= sqrtK.mul(10000)) {
                /// If tokenIn = token0, balanceIn > sqrtK => balance0>sqrtK, use boost0
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                /// If balance started from <sqrtK and ended at >sqrtK and boosts are different, there'll be different amountIn/Out
                /// Don't need to check in other case for reserveIn < reserveIn.add(x) <= sqrtK since that case doesnt cross midpt
                if (reserveIn < sqrtK && boost0 != boost1) {
                    /// Break into 2 trades => start point -> midpoint (sqrtK, sqrtK), then midpoint -> final point
                    amountOut = reserveOut.sub(sqrtK);
                    amountInPostFee = amountInPostFee.sub((sqrtK.sub(reserveIn)).mul(10000));
                    reserveIn = sqrtK;
                    reserveOut = sqrtK;
                }
            } else {
                /// If tokenIn = token0, balanceIn < sqrtK => balance0<sqrtK, use boost1
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
            }
        }
        uint256 numerator = amountInPostFee.mul(reserveOut.add(artiLiqTerm));
        uint256 denominator = (reserveIn.add(artiLiqTerm)).mul(10000).add(amountInPostFee);
        uint256 lastSwapAmountOut = numerator / denominator;
        amountOut = (lastSwapAmountOut > reserveOut) ? reserveOut.add(amountOut) : lastSwapAmountOut.add(amountOut);
    }

    /**
     @notice Quotes minimum input given exact output amount of tokens and addresses of tokens in pair
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param amountOut The desired output amount of token A
     @param tokenIn The address of input token
     @param tokenOut The address of output token
     @param factory The address of the factory contract
     @return amountIn The minimum input amount of token A for a valid swap
    */
    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, 'ImpossibleLibrary: INSUFFICIENT_INPUT_AMOUNT');

        uint256 reserveIn;
        uint256 reserveOut;
        uint256 artiLiqTerm;
        uint256 fee;
        bool isMatch;
        {
            // Avoid stack too deep
            bool isXybk;
            uint256 boost0;
            uint256 boost1;
            {
                // Avoid stack too deep
                (address token0, ) = sortTokens(tokenIn, tokenOut);
                isMatch = tokenIn == token0;
            }
            {
                // Avoid stack too deep
                address pair;
                (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut);
                IImpossiblePair.TradeState tradeState;
                (fee, tradeState, isXybk) = IImpossiblePair(pair).getPairSettings();
                require(
                    (tradeState == IImpossiblePair.TradeState.SELL_ALL) ||
                        (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_0 && !isMatch) ||
                        (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_1 && isMatch),
                    'ImpossibleLibrary: TRADE_NOT_ALLOWED'
                );
                (boost0, boost1) = IImpossiblePair(pair).calcBoost();
            }
            if (isXybk) {
                uint256 sqrtK = Math.sqrt(
                    xybkComputeK(boost0, boost1, isMatch ? reserveIn : reserveOut, isMatch ? reserveOut : reserveIn)
                );
                /// since balance0=balance1 only at sqrtK, if final balanceOut >= sqrtK means balanceOut >= balanceIn
                if (reserveOut.sub(amountOut) >= sqrtK) {
                    /// If tokenIn = token0, balanceOut > sqrtK => balance1>sqrtK, use boost1
                    artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
                } else {
                    /// If tokenIn = token0, balanceOut < sqrtK => balance0>sqrtK, use boost0
                    artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                    /// If balance started from <sqrtK and ended at >sqrtK and boosts are different, there'll be different amountIn/Out
                    /// Don't need to check in other case for reserveOut > reserveOut.sub(x) >= sqrtK since that case doesnt cross midpt
                    if (reserveOut > sqrtK && boost0 != boost1) {
                        /// Break into 2 trades => start point -> midpoint (sqrtK, sqrtK), then midpoint -> final point
                        amountIn = sqrtK.sub(reserveIn).mul(10000); /// Still need to divide by (10000 - fee). Do with below calculation to prevent early truncation
                        amountOut = amountOut.sub(reserveOut.sub(sqrtK));
                        reserveOut = sqrtK;
                        reserveIn = sqrtK;
                    }
                }
            }
        }
        uint256 numerator = (reserveIn.add(artiLiqTerm)).mul(amountOut).mul(10000);
        uint256 denominator = (reserveOut.add(artiLiqTerm)).sub(amountOut);
        amountIn = (amountIn.add((numerator / denominator)).div(10000 - fee)).add(1);
    }

    /**
     @notice Quotes maximum output given some uncertain input amount of tokens and addresses of tokens in pair
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param tokenIn The address of input token
     @param tokenOut The address of output token
     @param factory The address of the factory contract
     @return uint256 The maximum possible output amount of token A
     @return uint256 The maximum possible output amount of token B
    */
    function getAmountOutFeeOnTransfer(
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256, uint256) {
        uint256 reserveIn;
        uint256 reserveOut;
        address pair;
        bool isMatch;
        {
            // Avoid stack too deep
            (address token0, ) = sortTokens(tokenIn, tokenOut);
            isMatch = tokenIn == token0;
            (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut); /// Should be reserve0/1 but reuse variables to save stack
        }
        uint256 amountOut;
        uint256 artiLiqTerm;
        uint256 amountInPostFee;
        bool isXybk;
        {
            // Avoid stack too deep
            uint256 fee;
            uint256 balanceIn = IERC20(tokenIn).balanceOf(address(pair));
            require(balanceIn > reserveIn, 'ImpossibleLibrary: INSUFFICIENT_INPUT_AMOUNT');
            IImpossiblePair.TradeState tradeState;
            (fee, tradeState, isXybk) = IImpossiblePair(pair).getPairSettings();
            require(
                (tradeState == IImpossiblePair.TradeState.SELL_ALL) ||
                    (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_0 && !isMatch) ||
                    (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_1 && isMatch),
                'ImpossibleLibrary: TRADE_NOT_ALLOWED'
            );
            amountInPostFee = (balanceIn.sub(reserveIn)).mul(10000 - fee);
        }
        /// If xybk invariant, set reserveIn/reserveOut to artificial liquidity instead of actual liquidity
        if (isXybk) {
            (uint256 boost0, uint256 boost1) = IImpossiblePair(pair).calcBoost();
            uint256 sqrtK = Math.sqrt(
                xybkComputeK(boost0, boost1, isMatch ? reserveIn : reserveOut, isMatch ? reserveOut : reserveIn)
            );
            /// since balance0=balance1 only at sqrtK, if final balanceIn >= sqrtK means balanceIn >= balanceOut
            /// Use post-fee balances to maintain consistency with pair contract K invariant check
            if (amountInPostFee.add(reserveIn.mul(10000)) >= sqrtK.mul(10000)) {
                /// If tokenIn = token0, balanceIn > sqrtK => balance0>sqrtK, use boost0
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                /// If balance started from <sqrtK and ended at >sqrtK and boosts are different, there'll be different amountIn/Out
                /// Don't need to check in other case for reserveIn < reserveIn.add(x) <= sqrtK since that case doesnt cross midpt
                if (reserveIn < sqrtK && boost0 != boost1) {
                    /// Break into 2 trades => start point -> midpoint (sqrtK, sqrtK), then midpoint -> final point
                    amountOut = reserveOut.sub(sqrtK);
                    amountInPostFee = amountInPostFee.sub(sqrtK.sub(reserveIn));
                    reserveOut = sqrtK;
                    reserveIn = sqrtK;
                }
            } else {
                /// If tokenIn = token0, balanceIn < sqrtK => balance0<sqrtK, use boost0
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
            }
        }
        uint256 numerator = amountInPostFee.mul(reserveOut.add(artiLiqTerm));
        uint256 denominator = (reserveIn.add(artiLiqTerm)).mul(10000).add(amountInPostFee);
        uint256 lastSwapAmountOut = numerator / denominator;
        amountOut = (lastSwapAmountOut > reserveOut) ? reserveOut.add(amountOut) : lastSwapAmountOut.add(amountOut);
        return isMatch ? (uint256(0), amountOut) : (amountOut, uint256(0));
    }

    /**
     @notice Quotes maximum output given exact input amount of tokens and addresses of tokens in trade sequence
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param factory The address of the IF factory
     @param amountIn The input amount of token A
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @return amounts The maximum possible output amount of all tokens through sequential swaps
    */
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'ImpossibleLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            amounts[i + 1] = getAmountOut(amounts[i], path[i], path[i + 1], factory);
        }
    }

    /**
     @notice Quotes minimum input given exact output amount of tokens and addresses of tokens in trade sequence
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param factory The address of the IF factory
     @param amountOut The output amount of token A
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @return amounts The minimum output amount required of all tokens through sequential swaps
    */
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'ImpossibleLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            amounts[i - 1] = getAmountIn(amounts[i], path[i - 1], path[i], factory);
        }
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import '../libraries/SafeMath.sol';

contract DeflatingERC20 {
    using SafeMath for uint256;

    string public constant name = 'Deflating Test Token';
    string public constant symbol = 'DTT';
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 _totalSupply) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        _mint(msg.sender, _totalSupply);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        uint256 burnAmount = value / 100;
        _burn(from, burnAmount);
        uint256 transferAmount = value.sub(burnAmount);
        balanceOf[from] = balanceOf[from].sub(transferAmount);
        balanceOf[to] = balanceOf[to].add(transferAmount);
        emit Transfer(from, to, transferAmount);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './ImpossibleWrappedToken.sol';

import './interfaces/IImpossibleWrapperFactory.sol';
import './interfaces/IERC20.sol';

/**
    @title  Wrapper Factory for Impossible Swap V3
    @author Impossible Finance
    @notice This factory builds upon basic Uni V2 factory by changing "feeToSetter"
            to "governance" and adding a whitelist
    @dev    See documentation at: https://docs.impossible.finance/impossible-swap/overview
*/

contract ImpossibleWrapperFactory is IImpossibleWrapperFactory {
    address public governance;
    mapping(address => address) public override tokensToWrappedTokens;
    mapping(address => address) public override wrappedTokensToTokens;

    /**
     @notice The constructor for the IF swap factory
     @param _governance The address for IF Governance
    */
    constructor(address _governance) {
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, 'IF: FORBIDDEN');
        _;
    }

    /**
     @notice Sets the address for IF governance
     @dev Can only be called by IF governance
     @param _governance The address of the new IF governance
    */
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    /**
     @notice Creates a pair with some ratio
     @dev underlying The address of token to wrap
     @dev ratioNumerator The numerator value of the ratio to apply for ratio * underlying = wrapped underlying
     @dev ratioDenominator The denominator value of the ratio to apply for ratio * underlying = wrapped underlying
    */
    function createPairing(
        address underlying,
        uint256 ratioNumerator,
        uint256 ratioDenominator
    ) external onlyGovernance returns (address) {
        require(
            tokensToWrappedTokens[underlying] == address(0x0) && wrappedTokensToTokens[underlying] == address(0x0),
            'IF: PAIR_EXISTS'
        );
        require(ratioNumerator != 0 && ratioDenominator != 0, 'IF: INVALID_RATIO');
        ImpossibleWrappedToken wrapper = new ImpossibleWrappedToken(underlying, ratioNumerator, ratioDenominator);
        tokensToWrappedTokens[underlying] = address(wrapper);
        wrappedTokensToTokens[address(wrapper)] = underlying;
        emit WrapCreated(underlying, address(wrapper), ratioNumerator, ratioDenominator);
        return address(wrapper);
    }

    /**
     @notice Deletes a pairing
     @notice requires supply of wrapped token to be 0
     @dev wrapper The address of the wrapper
    */
    function deletePairing(address wrapper) external onlyGovernance {
        require(ImpossibleWrappedToken(wrapper).totalSupply() == 0, 'IF: NONZERO_SUPPLY');
        address _underlying = wrappedTokensToTokens[wrapper];
        require(ImpossibleWrappedToken(wrapper).underlying() == IERC20(_underlying), 'IF: INVALID_TOKEN');
        require(_underlying != address(0x0), 'IF: Address must have pair');
        delete tokensToWrappedTokens[_underlying];
        delete wrappedTokensToTokens[wrapper];
        emit WrapDeleted(_underlying, address(wrapper));
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IImpossibleWrapperFactory {
    event WrapCreated(address, address, uint256, uint256);
    event WrapDeleted(address, address);

    function tokensToWrappedTokens(address) external view returns (address);

    function wrappedTokensToTokens(address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import './libraries/TransferHelper.sol';
import './libraries/ReentrancyGuard.sol';
import './libraries/ImpossibleLibrary.sol';
import './libraries/SafeMath.sol';

import './interfaces/IImpossibleSwapFactory.sol';
import './interfaces/IImpossibleRouterExtension.sol';
import './interfaces/IImpossibleRouter.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/IImpossibleWrappedToken.sol';
import './interfaces/IImpossibleWrapperFactory.sol';

/**
    @title  Router for Impossible Swap V3
    @author Impossible Finance
    @notice This router builds upon basic Uni V2 Router02 by allowing custom
            calculations based on settings in pairs (uni/xybk/custom fees)
    @dev    See documentation at: https://docs.impossible.finance/impossible-swap/overview
    @dev    Very little logical changes made in Router02. Most changes to accomodate xybk are in Library
*/

contract ImpossibleRouter is IImpossibleRouter, ReentrancyGuard {
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override wrapFactory;

    address private utilitySettingAdmin;

    address public override routerExtension; // Can be set by utility setting admin once only
    address public override WETH; // Can be set by utility setting admin once only

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'ImpossibleRouter: EXPIRED');
        _;
    }

    /**
     @notice Constructor for IF Router
     @param _pairFactory Address of IF Pair Factory
     @param _wrapFactory Address of IF
     @param _utilitySettingAdmin Admin address allowed to set addresses of utility contracts (once)
    */
    constructor(
        address _pairFactory,
        address _wrapFactory,
        address _utilitySettingAdmin
    ) {
        factory = _pairFactory;
        wrapFactory = _wrapFactory;
        utilitySettingAdmin = _utilitySettingAdmin;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /**
     @notice Used to set addresses of utility contracts
     @dev Only allows setter to set these addresses once for trustlessness
     @dev Must set both WETH and routerExtension at the same time, else swap will be bricked
     @param _WETH address of WETH contract
     @param _routerExtension address of router interface contract
     */
    function setUtilities(address _WETH, address _routerExtension) public {
        require(WETH == address(0x0) && routerExtension == address(0x0));
        require(msg.sender == utilitySettingAdmin, 'IF: ?');
        WETH = _WETH;
        routerExtension = _routerExtension;
    }

    /**
     @notice Helper function for sending tokens that might need to be wrapped
     @param token The address of the token that might have a wrapper
     @param src The source to take underlying tokens from
     @param dst The destination to send wrapped tokens to
     @param amt The amount of tokens to send (wrapped tokens, not underlying)
    */
    function wrapSafeTransfer(
        address token,
        address src,
        address dst,
        uint256 amt
    ) internal {
        address underlying = IImpossibleWrapperFactory(wrapFactory).wrappedTokensToTokens(token);
        if (underlying == address(0x0)) {
            TransferHelper.safeTransferFrom(token, src, dst, amt);
        } else {
            uint256 underlyingAmt = IImpossibleWrappedToken(token).amtToUnderlyingAmt(amt);
            TransferHelper.safeTransferFrom(underlying, src, address(this), underlyingAmt);
            TransferHelper.safeApprove(underlying, token, underlyingAmt);
            IImpossibleWrappedToken(token).deposit(dst, underlyingAmt);
        }
    }

    /**
     @notice Helper function for sending tokens that might need to be unwrapped
     @param token The address of the token that might be wrapped
     @param dst The destination to send underlying tokens to
     @param amt The amount of wrapped tokens to send (wrapped tokens, not underlying)
    */
    function unwrapSafeTransfer(
        address token,
        address dst,
        uint256 amt
    ) internal {
        address underlying = IImpossibleWrapperFactory(wrapFactory).wrappedTokensToTokens(token);
        if (underlying == address(0x0)) {
            TransferHelper.safeTransfer(token, dst, amt);
        } else {
            IImpossibleWrappedToken(token).withdraw(dst, amt);
        }
    }

    /**
     @notice Swap function - receive maximum output given fixed input
     @dev Openzeppelin reentrancy guards
     @param amountIn The exact input amount`
     @param amountOutMin The minimum output amount allowed for a successful swap
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        amounts = ImpossibleLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        unwrapSafeTransfer(path[path.length - 1], to, amounts[amounts.length - 1]);
    }

    /**
     @notice Swap function - receive desired output amount given a maximum input amount
     @dev Openzeppelin reentrancy guards
     @param amountOut The exact output amount desired
     @param amountInMax The maximum input amount allowed for a successful swap
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        amounts = ImpossibleLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ImpossibleRouter: EXCESSIVE_INPUT_AMOUNT');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        unwrapSafeTransfer(path[path.length - 1], to, amountOut);
    }

    /**
     @notice Swap function - receive maximum output given fixed input of ETH
     @dev Openzeppelin reentrancy guards
     @param amountOutMin The minimum output amount allowed for a successful swap
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path[0] == WETH, 'ImpossibleRouter: INVALID_PATH');
        amounts = ImpossibleLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        unwrapSafeTransfer(path[path.length - 1], to, amounts[amounts.length - 1]);
    }

    /**
    @notice Swap function - receive desired ETH output amount given a maximum input amount
     @dev Openzeppelin reentrancy guards
     @param amountOut The exact output amount desired
     @param amountInMax The maximum input amount allowed for a successful swap
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, 'ImpossibleRouter: INVALID_PATH');
        amounts = ImpossibleLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ImpossibleRouter: EXCESSIVE_INPUT_AMOUNT');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     @notice Swap function - receive maximum ETH output given fixed input of tokens
     @dev Openzeppelin reentrancy guards
     @param amountIn The amount of input tokens
     @param amountOutMin The minimum ETH output amount required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, 'ImpossibleRouter: INVALID_PATH');
        amounts = ImpossibleLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     @notice Swap function - receive maximum tokens output given fixed ETH input
     @dev Openzeppelin reentrancy guards
     @param amountOut The minimum output amount in tokens required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path[0] == WETH, 'ImpossibleRouter: INVALID_PATH');
        amounts = ImpossibleLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'ImpossibleRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        unwrapSafeTransfer(path[path.length - 1], to, amountOut);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    /**
     @notice Swap function for fee on transfer tokens, no WETH/WBNB
     @param amountIn The amount of input tokens
     @param amountOutMin The minimum token output amount required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
    */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant {
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amountIn);
        IImpossibleRouterExtension(routerExtension).swapSupportingFeeOnTransferTokens(path);
        uint256 balance = IERC20(path[path.length - 1]).balanceOf(address(this));
        require(balance >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        unwrapSafeTransfer(path[path.length - 1], to, balance);
    }

    /**
     @notice Swap function for fee on transfer tokens with WETH/WBNB
     @param amountOutMin The minimum underlying token output amount required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
    */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) nonReentrant {
        require(path[0] == WETH, 'ImpossibleRouter: INVALID_PATH');
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(ImpossibleLibrary.pairFor(factory, path[0], path[1]), amountIn));
        IImpossibleRouterExtension(routerExtension).swapSupportingFeeOnTransferTokens(path);
        uint256 balance = IERC20(path[path.length - 1]).balanceOf(address(this));
        require(balance >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        unwrapSafeTransfer(path[path.length - 1], to, balance);
    }

    /**
     @notice Swap function for fee on transfer tokens, no WETH/WBNB
     @param amountIn The amount of input tokens
     @param amountOutMin The minimum ETH output amount required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
    */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant {
        require(path[path.length - 1] == WETH, 'ImpossibleRouter: INVALID_PATH');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amountIn);
        IImpossibleRouterExtension(routerExtension).swapSupportingFeeOnTransferTokens(path);
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    /**
     @notice Function for basic add liquidity functionality
     @dev Openzeppelin reentrancy guards
     @param tokenA The address of underlying tokenA to add
     @param tokenB The address of underlying tokenB to add
     @param amountADesired The desired amount of tokenA to add
     @param amountBDesired The desired amount of tokenB to add
     @param amountAMin The min amount of tokenA to add (amountAMin:amountBDesired sets bounds on ratio)
     @param amountBMin The min amount of tokenB to add (amountADesired:amountBMin sets bounds on ratio)
     @param to The address to mint LP tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountA Amount of tokenA added as liquidity to pair
     @return amountB Actual amount of tokenB added as liquidity to pair
     @return liquidity Actual amount of LP tokens minted
    */
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
        virtual
        override
        ensure(deadline)
        nonReentrant
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = IImpossibleRouterExtension(routerExtension).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = ImpossibleLibrary.pairFor(factory, tokenA, tokenB);
        wrapSafeTransfer(tokenA, msg.sender, pair, amountA);
        wrapSafeTransfer(tokenB, msg.sender, pair, amountB);
        liquidity = IImpossiblePair(pair).mint(to);
    }

    /**
     @notice Function for add liquidity functionality with 1 token being WETH/WBNB
     @dev Openzeppelin reentrancy guards
     @param token The address of the non-ETH underlying token to add
     @param amountTokenDesired The desired amount of non-ETH underlying token to add
     @param amountTokenMin The min amount of non-ETH underlying token to add (amountTokenMin:ETH sent sets bounds on ratio)
     @param amountETHMin The min amount of WETH/WBNB to add (amountTokenDesired:amountETHMin sets bounds on ratio)
     @param to The address to mint LP tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountToken Amount of non-ETH underlying token added as liquidity to pair
     @return amountETH Actual amount of WETH/WBNB added as liquidity to pair
     @return liquidity Actual amount of LP tokens minted
    */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        nonReentrant
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = IImpossibleRouterExtension(routerExtension).addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        wrapSafeTransfer(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IImpossiblePair(pair).mint(to);
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    /**
     @notice Function for basic remove liquidity functionality
     @dev Openzeppelin reentrancy guards
     @param tokenA The address of underlying tokenA in LP token
     @param tokenB The address of underlying tokenB in LP token
     @param liquidity The amount of LP tokens to burn
     @param amountAMin The min amount of underlying tokenA that has to be received
     @param amountBMin The min amount of underlying tokenB that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountA Actual amount of underlying tokenA received
     @return amountB Actual amount of underlying tokenB received
    */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) nonReentrant returns (uint256 amountA, uint256 amountB) {
        address pair = ImpossibleLibrary.pairFor(factory, tokenA, tokenB);
        IImpossiblePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (amountA, amountB) = IImpossibleRouterExtension(routerExtension).removeLiquidity(
            tokenA,
            tokenB,
            pair,
            amountAMin,
            amountBMin
        );
        unwrapSafeTransfer(tokenA, to, amountA);
        unwrapSafeTransfer(tokenB, to, amountB);
    }

    /**
     @notice Function for remove liquidity functionality with 1 token being WETH/WBNB
     @dev Openzeppelin reentrancy guards
     @param token The address of the non-ETH underlying token to receive
     @param liquidity The amount of LP tokens to burn
     @param amountTokenMin The desired amount of non-ETH underlying token that has to be received
     @param amountETHMin The min amount of ETH that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountToken Actual amount of non-ETH underlying token received
     @return amountETH Actual amount of WETH/WBNB received
    */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) nonReentrant returns (uint256 amountToken, uint256 amountETH) {
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        IImpossiblePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (amountToken, amountETH) = IImpossibleRouterExtension(routerExtension).removeLiquidity(
            token,
            WETH,
            pair,
            amountTokenMin,
            amountETHMin
        );
        unwrapSafeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
    @notice Function for remove liquidity functionality using EIP712 permit
     @dev Openzeppelin reentrancy guards
     @param tokenA The address of underlying tokenA in LP token
     @param tokenB The address of underlying tokenB in LP token
     @param liquidity The amount of LP tokens to burn
     @param amountAMin The min amount of underlying tokenA that has to be received
     @param amountBMin The min amount of underlying tokenB that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @param approveMax How much tokens are approved for transfer (liquidity, or max)
     @param v,r,s Variables that construct a valid EVM signature
     @return amountA Actual amount of underlying tokenA received
     @return amountB Actual amount of underlying tokenB received
    */
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
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = ImpossibleLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IImpossiblePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        return removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /**
     @notice Function for remove liquidity functionality using EIP712 permit with 1 token being WETH/WBNB
     @param token The address of the non-ETH underlying token to receive
     @param liquidity The amount of LP tokens to burn
     @param amountTokenMin The desired amount of non-ETH underlying token that has to be received
     @param amountETHMin The min amount of ETH that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @param approveMax How much tokens are approved for transfer (liquidity, or max)
     @param v,r,s Variables that construct a valid EVM signature
     @return amountToken Actual amount of non-ETH underlying token received
     @return amountETH Actual amount of WETH/WBNB received
    */
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IImpossiblePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /**
     @notice Function for remove liquidity functionality with 1 token being WETH/WBNB
     @dev This is used when non-WETH/WBNB underlying token is fee-on-transfer: e.g. FEI algo stable v1
     @dev Openzeppelin reentrancy guards
     @param token The address of the non-ETH underlying token to receive
     @param liquidity The amount of LP tokens to burn
     @param amountTokenMin The desired amount of non-ETH underlying token that has to be received
     @param amountETHMin The min amount of ETH that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountETH Actual amount of WETH/WBNB received
    */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) nonReentrant returns (uint256 amountETH) {
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        IImpossiblePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (, amountETH) = IImpossibleRouterExtension(routerExtension).removeLiquidity(
            token,
            WETH,
            pair,
            amountTokenMin,
            amountETHMin
        );
        unwrapSafeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     @notice Function for remove liquidity functionality using EIP712 permit with 1 token being WETH/WBNB
     @dev This is used when non-WETH/WBNB underlying token is fee-on-transfer: e.g. FEI algo stable v1
     @param token The address of the non-ETH underlying token to receive
     @param liquidity The amount of LP tokens to burn
     @param amountTokenMin The desired amount of non-ETH underlying token that has to be received
     @param amountETHMin The min amount of ETH that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @param approveMax How much tokens are approved for transfer (liquidity, or max)
     @param v,r,s Variables that construct a valid EVM signature
     @return amountETH Actual amount of WETH/WBNB received
    */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountETH) {
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IImpossiblePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity >=0.6.2;

interface IImpossibleRouter {
    function factory() external view returns (address factoryAddr);

    function routerExtension() external view returns (address routerExtensionAddr);

    function wrapFactory() external view returns (address wrapFactoryAddr);

    function WETH() external view returns (address WETHAddr);

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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
}

// SPDX-License-Identifier: GPL-3
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}