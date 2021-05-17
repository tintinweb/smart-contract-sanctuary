/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// File: contracts/interface/ICoFiXV2DAO.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

interface ICoFiXV2DAO {

    function setGovernance(address gov) external;
    function start() external; 

    // function addETHReward() external payable; 

    event FlagSet(address gov, uint256 flag);
    event CoFiBurn(address gov, uint256 amount);
}
// File: contracts/lib/TransferHelper.sol

pragma solidity 0.6.12;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/interface/IWETH.sol

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint);
}

// File: contracts/interface/ICoFiXV2Controller.sol

pragma solidity 0.6.12;

interface ICoFiXV2Controller {

    event NewK(address token, uint256 K, uint256 sigma, uint256 T, uint256 ethAmount, uint256 erc20Amount, uint256 blockNum);
    event NewGovernance(address _new);
    event NewOracle(address _priceOracle);
    event NewKTable(address _kTable);
    event NewTimespan(uint256 _timeSpan);
    event NewKRefreshInterval(uint256 _interval);
    event NewKLimit(int128 maxK0);
    event NewGamma(int128 _gamma);
    event NewTheta(address token, uint32 theta);
    event NewK(address token, uint32 k);
    event NewCGamma(address token, uint32 gamma);

    function addCaller(address caller) external;

    function setCGamma(address token, uint32 gamma) external;

    function queryOracle(address token, uint8 op, bytes memory data) external payable returns (uint256 k, uint256 ethAmount, uint256 erc20Amount, uint256 blockNum, uint256 theta);

    function getKInfo(address token) external view returns (uint32 k, uint32 updatedAt, uint32 theta);

    function getLatestPriceAndAvgVola(address token) external payable returns (uint256, uint256, uint256, uint256);
}
// File: contracts/interface/ICoFiXV2Factory.sol

pragma solidity 0.6.12;

interface ICoFiXV2Factory {
    // All pairs: {ETH <-> ERC20 Token}
    event PairCreated(address indexed token, address pair, uint256);
    event NewGovernance(address _new);
    event NewController(address _new);
    event NewFeeReceiver(address _new);
    event NewFeeVaultForLP(address token, address feeVault);
    event NewVaultForLP(address _new);
    event NewVaultForTrader(address _new);
    event NewVaultForCNode(address _new);
    event NewDAO(address _new);

    /// @dev Create a new token pair for trading
    /// @param  token the address of token to trade
    /// @param  initToken0Amount the initial asset ratio (initToken0Amount:initToken1Amount)
    /// @param  initToken1Amount the initial asset ratio (initToken0Amount:initToken1Amount)
    /// @return pair the address of new token pair
    function createPair(
        address token,
	    uint256 initToken0Amount,
        uint256 initToken1Amount
        )
        external
        returns (address pair);

    function getPair(address token) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function getTradeMiningStatus(address token) external view returns (bool status);
    function setTradeMiningStatus(address token, bool status) external;
    function getFeeVaultForLP(address token) external view returns (address feeVault); // for LPs
    function setFeeVaultForLP(address token, address feeVault) external;

    function setGovernance(address _new) external;
    function setController(address _new) external;
    function setFeeReceiver(address _new) external;
    function setVaultForLP(address _new) external;
    function setVaultForTrader(address _new) external;
    function setVaultForCNode(address _new) external;
    function setDAO(address _new) external;
    function getController() external view returns (address controller);
    function getFeeReceiver() external view returns (address feeReceiver); // For CoFi Holders
    function getVaultForLP() external view returns (address vaultForLP);
    function getVaultForTrader() external view returns (address vaultForTrader);
    function getVaultForCNode() external view returns (address vaultForCNode);
    function getDAO() external view returns (address dao);
}

// File: contracts/interface/ICoFiXERC20.sol

pragma solidity 0.6.12;

interface ICoFiXERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    // function name() external pure returns (string memory);
    // function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: contracts/CoFiXERC20.sol

pragma experimental ABIEncoderV2;

pragma solidity 0.6.12;

// ERC20 token implementation, inherited by CoFiXPair contract, no owner or governance
contract CoFiXERC20 is ICoFiXERC20 {
    using SafeMath for uint;

    string public constant nameForDomain = 'CoFiX Pool Token';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(nameForDomain)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

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

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'CERC20: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'CERC20: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// File: contracts/interface/ICoFiXV2Pair.sol

pragma solidity 0.6.12;

interface ICoFiXV2Pair is ICoFiXERC20 {

    struct OraclePrice {
        uint256 ethAmount;
        uint256 erc20Amount;
        uint256 blockNum;
        uint256 K;
        uint256 theta;
    }

    // All pairs: {ETH <-> ERC20 Token}
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, address outToken, uint outAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint amountIn,
        uint amountOut,
        address outToken,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function mint(address to, uint amountETH, uint amountToken) external payable returns (uint liquidity, uint oracleFeeChange);
    function burn(address tokenTo, address ethTo) external payable returns (uint amountTokenOut, uint amountETHOut, uint oracleFeeChange);
    function swapWithExact(address outToken, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[5] memory tradeInfo);
    // function swapForExact(address outToken, uint amountOutExact, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo);
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, string memory, string memory, uint256, uint256) external;

    /// @dev get Net Asset Value Per Share
    /// @param  ethAmount ETH side of Oracle price {ETH <-> ERC20 Token}
    /// @param  erc20Amount Token side of Oracle price {ETH <-> ERC20 Token}
    /// @return navps The Net Asset Value Per Share (liquidity) represents
    function getNAVPerShare(uint256 ethAmount, uint256 erc20Amount) external view returns (uint256 navps);

    /// @dev get initial asset ratio
    /// @return _initToken0Amount Token0(ETH) side of initial asset ratio {ETH <-> ERC20 Token}
    /// @return _initToken1Amount Token1(ERC20) side of initial asset ratio {ETH <-> ERC20 Token}
    function getInitialAssetRatio() external view returns (uint256 _initToken0Amount, uint256 _initToken1Amount);
}

// File: contracts/CoFiXV2Pair.sol

pragma solidity 0.6.12;

// Pair contract for each trading pair, storing assets and handling settlement
// No owner or governance
contract CoFiXV2Pair is ICoFiXV2Pair, CoFiXERC20 {
    using SafeMath for uint;

    enum CoFiX_OP { QUERY, MINT, BURN, SWAP_WITH_EXACT, SWAP_FOR_EXACT } // operations in CoFiX

    uint public override constant MINIMUM_LIQUIDITY = 10**9; // it's negligible because we calc liquidity in ETH
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    uint256 constant public K_BASE = 1E8; // K
    uint256 constant public NAVPS_BASE = 1E18; // NAVPS (Net Asset Value Per Share), need accuracy
    uint256 constant public THETA_BASE = 1E8; // theta

    string public name;
    string public symbol;

    address public override immutable factory;
    address public override token0; // WETH token
    address public override token1; // any ERC20 token

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves

    uint256 public initToken1Amount;
    uint256 public initToken0Amount;

    uint private unlocked = 1;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, address outToken, uint outAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint amountIn,
        uint amountOut,
        address outToken,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    modifier lock() {
        require(unlocked == 1, "CPair: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        factory = msg.sender;
    }

    receive() external payable {}

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, string memory _name, string memory _symbol, uint256 _initToken0Amount, uint256 _initToken1Amount) external override {
        require(msg.sender == factory, "CPair: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        name = _name;
        symbol = _symbol;
        initToken1Amount = _initToken1Amount;
        initToken0Amount = _initToken0Amount;
    }

    function getInitialAssetRatio() public override view returns (uint256 _initToken0Amount, uint256 _initToken1Amount) {
        _initToken1Amount = initToken1Amount;
        _initToken0Amount = initToken0Amount;
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "CPair: TRANSFER_FAILED");
    }

    // update reserves
    function _update(uint balance0, uint balance1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), "CPair: OVERFLOW");
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to, uint amountETH, uint amountToken) external payable override lock returns (uint liquidity, uint oracleFeeChange) {
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        require(amountETH <= amount0 && amountToken <= amount1, "CPair: illegal ammount");
        
        amount0 = amountETH;
        amount1 = amountToken;
        require(amount0.mul(initToken1Amount) == amount1.mul(initToken0Amount), "CPair: invalid asset ratio");
        
        uint256 _ethBalanceBefore = address(this).balance;
        { // scope for ethAmount/erc20Amount/blockNum to avoid stack too deep error
            bytes memory data = abi.encode(msg.sender, to, amount0, amount1);
            // query price
            OraclePrice memory _op;
            (_op.K, _op.ethAmount, _op.erc20Amount, _op.blockNum, _op.theta) = _queryOracle(_token1, CoFiX_OP.MINT, data);
            uint256 navps = calcNAVPerShare(_reserve0, _reserve1, _op.ethAmount, _op.erc20Amount);
            if (totalSupply == 0) {
                liquidity = calcLiquidity(amount0, navps).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            } else {
                liquidity = calcLiquidity(amount0, navps);
            }
        }
        oracleFeeChange = msg.value.sub(_ethBalanceBefore.sub(address(this).balance));

        require(liquidity > 0, "CPair: SHORT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1);
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);

        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address tokenTo, address ethTo) external payable override lock returns (uint amountTokenOut, uint amountEthOut, uint oracleFeeChange) {
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint256 _ethBalanceBefore = address(this).balance;
        // uint256 fee;
        {
            bytes memory data = abi.encode(msg.sender, liquidity);
            // query price
            OraclePrice memory _op;
            (_op.K, _op.ethAmount, _op.erc20Amount, _op.blockNum, _op.theta) = _queryOracle(_token1, CoFiX_OP.BURN, data);

            (amountTokenOut, amountEthOut) = calcOutTokenAndETHForBurn(liquidity, _op); // navps calculated
        }
        oracleFeeChange = msg.value.sub(_ethBalanceBefore.sub(address(this).balance));

        require(amountTokenOut > 0 && amountEthOut > 0, "CPair: SHORT_LIQUIDITY_BURNED");

        _burn(address(this), liquidity);
        _safeTransfer(_token1, tokenTo, amountTokenOut);
        _safeTransfer(_token0, ethTo, amountEthOut);

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);

        emit Burn(msg.sender, _token0, amountEthOut, ethTo);
        emit Burn(msg.sender, _token1, amountTokenOut, tokenTo);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swapWithExact(address outToken, address to)
        external
        payable override lock
        returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[5] memory tradeInfo)
    {
        // tradeInfo[0]: thetaFee, tradeInfo[1]: ethAmount, tradeInfo[2]: erc20Amount
        address _token0 = token0;
        address _token1 = token1;
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));

        // uint256 fee;
        { // scope for ethAmount/erc20Amount/blockNum to avoid stack too deep error
            uint256 _ethBalanceBefore = address(this).balance;
            (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings

            // calc amountIn
            if (outToken == _token1) {
                amountIn = balance0.sub(_reserve0);
            } else if (outToken == _token0) {
                amountIn = balance1.sub(_reserve1);
            } else {
                revert("CPair: wrong outToken");
            }
            require(amountIn > 0, "CPair: wrong amountIn");
            bytes memory data = abi.encode(msg.sender, outToken, to, amountIn);
            // query price
            OraclePrice memory _op;
            (_op.K, _op.ethAmount, _op.erc20Amount, _op.blockNum, _op.theta) = _queryOracle(_token1, CoFiX_OP.SWAP_WITH_EXACT, data);
            
            if (outToken == _token1) {
                (amountOut, tradeInfo[0]) = calcOutToken1(amountIn, _op);
            } else if (outToken == _token0) {
                (amountOut, tradeInfo[0]) = calcOutToken0(amountIn, _op);
            }
            oracleFeeChange = msg.value.sub(_ethBalanceBefore.sub(address(this).balance));
            tradeInfo[1] = _op.ethAmount;
            tradeInfo[2] = _op.erc20Amount;
        }
        
        require(to != _token0 && to != _token1, "CPair: INVALID_TO");

        _safeTransfer(outToken, to, amountOut); // optimistically transfer tokens
        if (tradeInfo[0] > 0) {
            if (ICoFiXV2Factory(factory).getTradeMiningStatus(_token1)) {
                // only transfer fee to protocol feeReceiver when trade mining is enabled for this trading pair
                _safeSendFeeForDAO(_token0, tradeInfo[0]);
            } else {
                _safeSendFeeForLP(_token0, _token1, tradeInfo[0]);
                tradeInfo[0] = 0; // so router won't go into the trade mining logic (reduce one more call gas cost)
            }
        }
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);

        emit Swap(msg.sender, amountIn, amountOut, outToken, to);
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }

    // calc Net Asset Value Per Share (no K)
    // use it in this contract, for optimized gas usage
    function calcNAVPerShare(uint256 balance0, uint256 balance1, uint256 ethAmount, uint256 erc20Amount) public view returns (uint256 navps) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            navps = NAVPS_BASE;
        } else {
            /*
            NV  = \frac{E_t + U_t/P_t}{(1 + \frac{k_0}{P_t})*F_t}\\\\
                = \frac{E_t + U_t * \frac{ethAmount}{erc20Amount}}{(1 + \frac{initToken1Amount}{initToken0Amount} * \frac{ethAmount}{erc20Amount})*F_t}\\\\
                = \frac{E_t * erc20Amount + U_t * ethAmount}{(erc20Amount + \frac{initToken1Amount * ethAmount}{initToken0Amount}) * F_t}\\\\
                = \frac{E_t * erc20Amount * initToken0Amount + U_t * ethAmount * initToken0Amount}{( erc20Amount * initToken0Amount + initToken1Amount * ethAmount) * F_t} \\\\
                = \frac{balance0 * erc20Amount * initToken0Amount + balance1 * ethAmount * initToken0Amount}{(erc20Amount * initToken0Amount + initToken1Amount * ethAmount) * totalSupply}
             */
            uint256 balance0MulErc20AmountMulInitToken0Amount = balance0.mul(erc20Amount).mul(initToken0Amount);
            uint256 balance1MulEthAmountMulInitToken0Amount = balance1.mul(ethAmount).mul(initToken0Amount);
            uint256 initToken1AmountMulEthAmount = initToken1Amount.mul(ethAmount);
            uint256 initToken0AmountMulErc20Amount = erc20Amount.mul(initToken0Amount);

            navps = (balance0MulErc20AmountMulInitToken0Amount.add(balance1MulEthAmountMulInitToken0Amount))
                        .div(_totalSupply).mul(NAVPS_BASE)
                        .div(initToken1AmountMulEthAmount.add(initToken0AmountMulErc20Amount));
        }
    }

    // use it in this contract, for optimized gas usage
    function calcLiquidity(uint256 amount0, uint256 navps) public pure returns (uint256 liquidity) {
        liquidity = amount0.mul(NAVPS_BASE).div(navps);
    }

    // get Net Asset Value Per Share for mint
    // only for read, could cost more gas if use it directly in contract
    function getNAVPerShareForMint(OraclePrice memory _op) public view returns (uint256 navps) {
        return calcNAVPerShare(reserve0, reserve1, _op.ethAmount, _op.erc20Amount);
    }

    // get Net Asset Value Per Share for burn
    // only for read, could cost more gas if use it directly in contract
    function getNAVPerShareForBurn(OraclePrice memory _op) external view returns (uint256 navps) {
        return calcNAVPerShare(reserve0, reserve1, _op.ethAmount, _op.erc20Amount);
    }

    // get Net Asset Value Per Share
    // only for read, could cost more gas if use it directly in contract
    function getNAVPerShare(uint256 ethAmount, uint256 erc20Amount) external override view returns (uint256 navps) {
        return calcNAVPerShare(reserve0, reserve1, ethAmount, erc20Amount);
    }

    // get estimated liquidity amount (it represents the amount of pool tokens will be minted if someone provide liquidity to the pool)
    // only for read, could cost more gas if use it directly in contract
    function getLiquidity(uint256 amount0, OraclePrice memory _op) external view returns (uint256 liquidity) {
        uint256 navps = getNAVPerShareForMint(_op);
        return calcLiquidity(amount0, navps);
    }

    function calcOutTokenAndETHForBurn(uint256 liquidity, OraclePrice memory _op) public view returns (uint256 amountTokenOut, uint256 amountEthOut) {
        // amountEthOut = liquidity * navps * (THETA_BASE - theta) / THETA_BASE
        // amountTokenOut = liquidity * navps * (THETA_BASE - theta) * initToken1Amount / (initToken0Amount * THETA_BASE)
        uint256 navps;
        {
            navps = calcNAVPerShare(reserve0, reserve1, _op.ethAmount, _op.erc20Amount);
            uint256 amountEth = liquidity.mul(navps);

            uint256 amountEthOutLarge = amountEth.mul(THETA_BASE.sub(_op.theta));
            amountEthOut = amountEthOutLarge.div(NAVPS_BASE).div(THETA_BASE);
            amountTokenOut = amountEthOutLarge.mul(initToken1Amount).div(NAVPS_BASE).div(initToken0Amount).div(THETA_BASE);
            // amountTokenOut = amountEthOut.mul(initToken1Amount).div(initToken0Amount);
        }

        // recalc amountOut when has no enough reserve0 or reserve1 to out in initAssetRatio
        {
            if (amountEthOut > reserve0) {
                // user first, out eth as much as possibile. And may leave over a few amounts of reserve1. 
                uint256 amountEthInsufficient = amountEthOut - reserve0;
                uint256 amountTokenEquivalent = amountEthInsufficient.mul(_op.erc20Amount).div(_op.ethAmount);
                amountTokenOut = amountTokenOut.add(amountTokenEquivalent);
                if (amountTokenOut > reserve1) {
                    amountTokenOut = reserve1;
                }
                amountEthOut = reserve0;
                // amountEthOut = reserve0 - fee;    
            } else if (amountTokenOut > reserve1) {
                uint256 amountTokenInsufficient = amountTokenOut - reserve1;
                uint256 amountEthEquivalent = amountTokenInsufficient.mul(_op.ethAmount).div(_op.erc20Amount);
                amountEthOut = amountEthOut.add(amountEthEquivalent);
                if (amountEthOut > reserve0) {
                    amountEthOut = reserve0;
                }
                amountTokenOut = reserve1;
            }
        }   
    }

    // get estimated amountOut for token0 (WETH) when swapWithExact
    function calcOutToken0(uint256 amountIn, OraclePrice memory _op) public pure returns (uint256 amountOut, uint256 fee) {
        /*
        x &= (a/P_{b}^{'})*\frac{THETA_{BASE} - \theta}{THETA_{BASE}} \\\\
          &= a / (\frac{erc20Amount}{ethAmount} * \frac{(k_{BASE} + k)}{(k_{BASE})}) * \frac{THETA_{BASE} - \theta}{THETA_{BASE}} \\\\
          &= \frac{a*ethAmount*k_{BASE}}{erc20Amount*(k_{BASE} + k)} * \frac{THETA_{BASE} - \theta}{THETA_{BASE}} \\\\
          &= \frac{a*ethAmount*k_{BASE}*(THETA_{BASE} - \theta)}{erc20Amount*(k_{BASE} + k)*THETA_{BASE}} \\\\
        // amountOut = amountIn * _op.ethAmount * K_BASE * (THETA_BASE - _op.theta) / _op.erc20Amount / (K_BASE + _op.K) / THETA_BASE;
        */
        amountOut = amountIn.mul(_op.ethAmount).mul(K_BASE).mul(THETA_BASE.sub(_op.theta)).div(_op.erc20Amount).div(K_BASE.add(_op.K)).div(THETA_BASE);
        if (_op.theta != 0) {
            // fee = amountIn * _op.ethAmount * K_BASE * (_op.theta) / _op.erc20Amount / (K_BASE + _op.K) / THETA_BASE;
            fee = amountIn.mul(_op.ethAmount).mul(K_BASE).mul(_op.theta).div(_op.erc20Amount).div(K_BASE.add(_op.K)).div(THETA_BASE);
        }
        return (amountOut, fee);
    }

    // get estimated amountOut for token1 (ERC20 token) when swapWithExact
    function calcOutToken1(uint256 amountIn, OraclePrice memory _op) public pure returns (uint256 amountOut, uint256 fee) {
        /*
        y &= b*P_{s}^{'}*\frac{THETA_{BASE} - \theta}{THETA_{BASE}} \\\\
          &= b * \frac{erc20Amount}{ethAmount} * \frac{(k_{BASE} - k)}{(k_{BASE})} * \frac{THETA_{BASE} - \theta}{THETA_{BASE}} \\\\
          &= \frac{b*erc20Amount*(k_{BASE} - k)*(THETA_{BASE} - \theta)}{ethAmount*k_{BASE}*THETA_{BASE}} \\\\
        // amountOut = amountIn * _op.erc20Amount * (K_BASE - _op.K) * (THETA_BASE - _op.theta) / _op.ethAmount / K_BASE / THETA_BASE;
        */
        amountOut = amountIn.mul(_op.erc20Amount).mul(K_BASE.sub(_op.K)).mul(THETA_BASE.sub(_op.theta)).div(_op.ethAmount).div(K_BASE).div(THETA_BASE);
        if (_op.theta != 0) {
            // fee = amountIn * _op.theta / THETA_BASE;
            fee = amountIn.mul(_op.theta).div(THETA_BASE);
        }
        return (amountOut, fee);
    }

    // get estimate amountInNeeded for token0 (WETH) when swapForExact
    function calcInNeededToken0(uint256 amountOut, OraclePrice memory _op) public pure returns (uint256 amountInNeeded, uint256 fee) {
        // inverse of calcOutToken1
        // amountOut = amountIn.mul(_op.erc20Amount).mul(K_BASE.sub(_op.K)).mul(THETA_BASE.sub(_op.theta)).div(_op.ethAmount).div(K_BASE).div(THETA_BASE);
        amountInNeeded = amountOut.mul(_op.ethAmount).mul(K_BASE).mul(THETA_BASE).div(_op.erc20Amount).div(K_BASE.sub(_op.K)).div(THETA_BASE.sub(_op.theta));
        if (_op.theta != 0) {
            // fee = amountIn * _op.theta / THETA_BASE;
            fee = amountInNeeded.mul(_op.theta).div(THETA_BASE);
        }
        return (amountInNeeded, fee);
    }

    // get estimate amountInNeeded for token1 (ERC20 token) when swapForExact
    function calcInNeededToken1(uint256 amountOut, OraclePrice memory _op) public pure returns (uint256 amountInNeeded, uint256 fee) {
        // inverse of calcOutToken0
        // amountOut = amountIn.mul(_op.ethAmount).mul(K_BASE).mul(THETA_BASE.sub(_op.theta)).div(_op.erc20Amount).div(K_BASE.add(_op.K)).div(THETA_BASE);
        amountInNeeded = amountOut.mul(_op.erc20Amount).mul(K_BASE.add(_op.K)).mul(THETA_BASE).div(_op.ethAmount).div(K_BASE).div(THETA_BASE.sub(_op.theta));
        if (_op.theta != 0) {
            // fee = amountIn * _op.ethAmount * K_BASE * (_op.theta) / _op.erc20Amount / (K_BASE + _op.K) / THETA_BASE;
            fee = amountInNeeded.mul(_op.ethAmount).mul(K_BASE).mul(_op.theta).div(_op.erc20Amount).div(K_BASE.add(_op.K)).div(THETA_BASE);
        }
        return (amountInNeeded, fee);
    }

    function _queryOracle(address token, CoFiX_OP op, bytes memory data) internal returns (uint256, uint256, uint256, uint256, uint256) {
        return ICoFiXV2Controller(ICoFiXV2Factory(factory).getController()).queryOracle{value: msg.value}(token, uint8(op), data);
    }

    function _safeSendFeeForDAO(address _token0, uint256 _fee) internal {
        address feeReceiver = ICoFiXV2Factory(factory).getFeeReceiver();
        if (feeReceiver == address(0)) {
            return; // if feeReceiver not set, theta fee keeps in pair pool
        }
        uint256 bal = IWETH(_token0).balanceOf(address(this));
        if (_fee > bal) {
            _fee = bal;
        }

        IWETH(_token0).withdraw(_fee);
        if (_fee > 0) TransferHelper.safeTransferETH(feeReceiver, _fee); // transfer fee to protocol dao for redeem Cofi
        // ICoFiXV2DAO(dao).addETHReward{value: _fee}(); 
    }

    // Safe WETH transfer function, just in case not having enough WETH. LP will earn these fees.
    function _safeSendFeeForLP(address _token0, address _token1, uint256 _fee) internal {
        address feeVault = ICoFiXV2Factory(factory).getFeeVaultForLP(_token1);
        if (feeVault == address(0)) {
            return; // if fee vault not set, theta fee keeps in pair pool
        }
        _safeSendFee(_token0, feeVault, _fee); // transfer fee to protocol fee reward pool for LP
    }

    function _safeSendFee(address _token0, address _receiver, uint256 _fee) internal {
        uint256 wethBal = IERC20(_token0).balanceOf(address(this));
        if (_fee > wethBal) {
            _fee = wethBal;
        }
        if (_fee > 0) _safeTransfer(_token0, _receiver, _fee); 
    }
}
// 🦄 & CoFi Rocks