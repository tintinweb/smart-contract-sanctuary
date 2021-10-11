pragma solidity =0.5.16;

import "./Proxy0516.sol";

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


contract Governable is Initializable {
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function __Governable_init_unchained(address governor_) public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
    
    modifier governance() {
        require(msg.sender == governor || msg.sender == _admin());
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {

    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfigI(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfigA(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfigI(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfigA(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    
    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfigI(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfigA(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2ERC20 {
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract UniswapV2ERC20 is IUniswapV2ERC20, Initializable {
    using SafeMath for uint;

    string public constant name = 'TotoroSwap.com Liquidity Provider Token';
    string public constant symbol = 'TLPT';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        initialize();
    }
    
    function initialize() internal initializer {
        uint chainId;
        assembly {
            chainId := chainid
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

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

contract TotoroSwapPair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    //uint private unlocked = 1;
    //modifier lock() {
    //    require(unlocked == 1, 'UniswapV2: LOCKED');
    //    unlocked = 0;
    //    _;
    //    unlocked = 1;
    //}
    // compatibility for Upgradeable, as described in
    // https://docs.openzeppelin.com/upgrades/2.8/writing-upgradeable#avoid-initial-values-in-field-declarations
    uint private locked;
    modifier lock() {
        require(locked == 0, 'TotoroSwap: LOCKED');
        locked = 1;
        _;
        locked = 0;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external initializer {
        //require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        UniswapV2ERC20.initialize();
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        (, uint _taxRate, address _taxToken, address feeTo) = TotoroSwapFactory(factory).getTaxTo(token0, token1);
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            //if (_kLast != 0) {
            if (_kLast != 0 && _taxToken == address(this)) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    //uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint numerator = (totalSupply.mul(_taxRate) / 1e14).mul(rootK.sub(rootKLast));
                    //uint denominator = rootK.mul(5).add(rootKLast);
                    uint denominator = rootK.mul(uint(1e18).sub(_taxRate)).add(rootKLast.mul(_taxRate)) / 1e14;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for _feeRate, _taxRate, _taxToken, _taxTo avoids stack too deep errors
        (uint _feeRate, uint _taxRate, address _taxToken, address _taxTo) = TotoroSwapFactory(factory).getTaxTo(token0, token1);
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        //uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance0Adjusted = balance0.mul(1e18).sub(amount0In.mul(_feeRate)) / 1e14;
        //uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        uint balance1Adjusted = balance1.mul(1e18).sub(amount1In.mul(_feeRate)) / 1e14;
        //require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1e8), 'UniswapV2: K');
        }
        if(_taxToken == token0) {
            uint tax = (amount0In + amount0Out);
            tax = (tax.mul(_feeRate) / 1e18).mul(_taxRate) / 1e18;
            _safeTransfer(token0, _taxTo, tax);
            balance0 = balance0.sub(tax);
        } else if(_taxToken == token1) {
            uint tax = amount1In + amount1Out;
            tax = (tax.mul(_feeRate) / 1e18).mul(_taxRate) / 1e18;
            _safeTransfer(token1, _taxTo, tax);
            balance1 = balance1.sub(tax);
        }
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


contract TotoroSwapFactory is IUniswapV2Factory {
    using SafeMath for uint;
    
    bytes32 public constant pairCodeHash = keccak256(abi.encodePacked(type(InitializableProductProxy).creationCode));
    
    address public productImplementation;
    
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    
    mapping(address => uint) public feeRate;
    mapping(address => uint) public taxRate;
    mapping(address => uint) public taxPriority;
    mapping(address => address) public taxTo;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function initialize(address _feeToSetter, address _productImplementation) public {
        require(feeToSetter== address(0) && _feeToSetter != address(0), 'TotoroSwapFactory.initialize can be delegatecall once by proxy only.');
        feeToSetter = _feeToSetter;
        productImplementation = _productImplementation;
        feeRate[address(0)] = 0.003 ether;      // 0.3%
        taxRate[address(0)] = 0.300 ether;      // 30%
    }
    
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(InitializableProductProxy).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        InitializableProductProxy(uint160(pair)).__InitializableProductProxy_init(address(this), 0x0, abi.encodeWithSignature('initialize(address,address)', token0, token1));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
    
    modifier onlySetter() {
        require(isSetter(msg.sender), 'FORBIDDEN');
        _;
    }
    
    function isSetter(address sender) public view returns (bool) {
        return sender == feeToSetter || sender == _admin();
    }

    function setProductImplementation(address _productImplementation) external onlySetter {
        productImplementation = _productImplementation;
    }

    function setFeeTo(address _feeTo) external onlySetter {
        feeTo = _feeTo;
    }
    
    function setTaxTo(address _taxToken, address _taxTo, uint _taxPriority) external onlySetter {
        taxTo[_taxToken] = _taxTo;
        taxPriority[_taxToken] = _taxPriority;
    }
    
    function setFeeToSetter(address _feeToSetter) external onlySetter {
        feeToSetter = _feeToSetter;
    }
    
    function setFeeRate(address pair, uint _feeRate, uint _taxRate) external onlySetter {
        feeRate[pair] = _feeRate;
        taxRate[pair] = _taxRate;
    }
    
    function getFeeRate(address pair) public view returns (uint _feeRate, uint _taxRate) {
        _feeRate = feeRate[pair];
        if(_feeRate == 0)
            _feeRate= feeRate[address(0)];
        _taxRate = taxRate[pair];
        if(_taxRate == 0)
            _taxRate = taxRate[address(0)];
    }
    
    function getTaxTo(address token0, address token1) public view returns (uint _feeRate, uint _taxRate, address _taxToken, address _taxTo) {
        address pair = getPair[token0][token1];
        (_feeRate, _taxRate) = getFeeRate(pair);
        (uint priority0, uint priority1) = (taxPriority[token0], taxPriority[token1]);
        _taxToken = priority0 > priority1 ? token0 : priority0 < priority1 ? token1 : pair;
        _taxTo = taxTo[_taxToken];
        if(_taxTo == address(0))
            _taxTo = feeTo;
    }
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TotoroSwapFactory: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TotoroSwapFactory: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(token0, token1)),
                pairCodeHash
            ))));
    }

    // return getPair if pair exist, or else return pairFor
    function getPairFor(address tokenA, address tokenB) public view returns (address pair) {
        pair = getPair[tokenA][tokenB];
        if(pair == address(0))
            pair = pairFor(tokenA, tokenB);
    }
    
    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) public pure returns (uint amountB) {
        require(amountA > 0, 'TotoroSwapFactory: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'TotoroSwapFactory: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutPair(address pair, uint amountIn, uint reserveIn, uint reserveOut) public view returns (uint amountOut) {
        require(amountIn > 0, 'TotoroSwapFactory: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TotoroSwapFactory: INSUFFICIENT_LIQUIDITY');
        (uint _feeRate, ) = getFeeRate(pair);
        //uint amountInWithFee = amountIn.mul(997);
        uint amountInWithFee = amountIn.mul(uint(1e18).sub(_feeRate)) / 1e14;
        uint numerator = amountInWithFee.mul(reserveOut);
        //uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint denominator = reserveIn.mul(1e4).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public view returns (uint amountOut) {
        return getAmountOutPair(address(0), amountIn, reserveIn, reserveOut);
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInPair(address pair, uint amountOut, uint reserveIn, uint reserveOut) public view returns (uint amountIn) {
        require(amountOut > 0, 'TotoroSwapFactory: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TotoroSwapFactory: INSUFFICIENT_LIQUIDITY');
        (uint _feeRate, ) = getFeeRate(pair);
        //uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint numerator = reserveIn.mul(amountOut).mul(1e4);
        //uint denominator = reserveOut.sub(amountOut).mul(997);
        uint denominator = reserveOut.sub(amountOut).mul(uint(1e18).sub(_feeRate)) / 1e14;
        amountIn = (numerator / denominator).add(1);
    }
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public view returns (uint amountIn) {
        return getAmountInPair(address(0), amountOut, reserveIn, reserveOut);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TotoroSwapFactory: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TotoroSwapFactory: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[46] private ______gap;
}


/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/79dd498b16b957399f84b9aa7e720f98f9eb83e3/contracts/cryptography/ECDSA.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla implementation from an openzeppelin version.
 */

library OpenZeppelinUpgradesECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint x, uint y) internal pure returns (uint z) {
        return x / y;
    }
}

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}



interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external view returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 {      // is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract TotoroSwapRouter02 is IUniswapV2Router01, IUniswapV2Router02, Initializable {
    using SafeMath for uint;

    address public factory;   // immutable override
    address public WETH;      // immutable override

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    //constructor(address _factory, address _WETH) public {
    //    initialize(_factory, _WETH);
    //}
    
    function __TotoroSwapRouter02_init(address _factory, address _WETH) public initializer {
        factory = _factory;
        WETH = _WETH;
    }

    function () external payable {  // receive
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {                                                               // virtual 
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {                              // virtual override 
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {                // virtual override 
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit.value(amountETH)();                                     // IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {        // virtual override 
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountETH) {  // virtual override 
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {                       // virtual override 
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH) {                 // virtual override 
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountETH) {                    // virtual override 
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH) {                                   // virtual override 
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {    // virtual 
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {           // virtual override 
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {           // virtual override 
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        //virtual
        //override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit.value(amounts[0])();                                   // IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        //virtual
        //override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        //virtual
        //override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        //virtual
        //override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit.value(amounts[0])();                                       // IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal {      // virtual 
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            //amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            amountOutput = TotoroSwapFactory(factory).getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) {                                               // virtual override                     
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        //virtual
        //override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit.value(amountIn)();                                         // IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        //virtual
        //override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure returns (uint amountB) {     // virtual override 
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        view
        //virtual
        //override
        returns (uint amountOut)
    {
        //return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        return TotoroSwapFactory(factory).getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        view
        //virtual
        //override
        returns (uint amountIn)
    {
        //return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
        return TotoroSwapFactory(factory).getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        //virtual
        //override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        //virtual
        //override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

contract TotoroSwapFarmingRouter is TotoroSwapRouter02 {
    using TransferHelper for address;
    
    address public rewardsDistribution;
    IERC20 public rewardsToken;     // TOTORO
    address public currency;        // obsolete
    address internal ecoAddr;
    uint internal ecoRatio;

	mapping (address => uint) public lep;                // 1: linear, 2: exponential, 3: power
	mapping (address => uint) public period;
	mapping (address => uint) public begin;
    mapping (address => uint) public rewardsDuration;
    mapping (address => uint) public periodFinish;
    mapping (address => uint) public taxsBuffer;
    mapping (address => uint) public rewardsBuffer;
    mapping (address => uint) public lastUpdateTime;                        // taxToken => 

    mapping (address => mapping (address => uint)) public swapAmounts;      // account => taxToken =>
    mapping (address => mapping (address => uint)) public swapTaxs;   
    mapping (address => mapping (address => uint)) public rewards;
    mapping (address => mapping (address => uint)) public paid;

    modifier onlySetter() {
        require(TotoroSwapFactory(factory).isSetter(msg.sender), 'FORBIDDEN');
        _;
    }

    function __TotoroSwapFarmingRouter_init(
        address _factory, 
        address _WETH,
        address _rewardsDistribution,
        address _rewardsToken,
        address _ecoAddr
    ) public initializer {
        __TotoroSwapRouter02_init(_factory, _WETH);
        __TotoroSwapFarmingRouter_init_unchained(_rewardsDistribution, _rewardsToken, _ecoAddr);
    }

    function __TotoroSwapFarmingRouter_init_unchained(
        address _rewardsDistribution,
        address _rewardsToken,
        address _ecoAddr
    ) public onlySetter {
        rewardsToken = IERC20(_rewardsToken);
        rewardsDistribution = _rewardsDistribution;
        ecoAddr = _ecoAddr;
        ecoRatio = 0.10 ether;
    }

    function notifyRewardBegin(address _taxToken, uint _lep, uint _period, uint _span, uint _begin) public onlySetter {
        lep[_taxToken]             = _lep;         // 1: linear, 2: exponential, 3: power
        period[_taxToken]          = _period;
        rewardsDuration[_taxToken] = _span;
        begin[_taxToken]           = _begin;
        periodFinish[_taxToken]    = _begin.add(_span);
        rewardsBuffer[_taxToken]   = rewardQuota().mul(_period).div(_span);
        lastUpdateTime[_taxToken] = _begin;
    }
    
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        super._swap(amounts, path, _to);
        for(uint i=0; i<amounts.length-1; i++)
            _swapFarming(path[i], path[i+1], amounts[i], amounts[i+1]);
    }
    
    function _swapFarming(address input, address output, uint amountIn, uint amountOut) internal {
        (uint feeRate, uint taxRate, address taxToken, ) = TotoroSwapFactory(factory).getTaxTo(input, output);
        uint rate = feeRate.mul(taxRate) / 1e18;
        if(input == taxToken)
            _swapFarming(input, amountIn, rate);
        else if(output == taxToken)
            _swapFarming(output, amountOut, rate);
    }

    function _swapFarming(address taxToken, uint amount, uint rate) internal {
        if(begin[taxToken] == 0 || begin[taxToken] >= now || lastUpdateTime[taxToken] >= now)
            return;
        //uint tax = amount.mul(rate).div(1e18);
        //
        //if(now < begin[taxToken].add(period[taxToken])) {
        //    uint temp = taxsBuffer[taxToken].mul(lastUpdateTime[taxToken].sub(begin[taxToken])).div(period[taxToken]).add(tax);
        //    taxsBuffer[taxToken] = temp.mul(period[taxToken].add(now).sub(lastUpdateTime[taxToken])).div(now.sub(begin[taxToken]));
        //} else
        //    taxsBuffer[taxToken] = taxsBuffer[taxToken].add(tax);
        //rewardsBuffer[taxToken] = rewardsBuffer[taxToken].add(rewardDelta(taxToken));
        //uint reward = rewardsBuffer[taxToken].mul(tax).div(taxsBuffer[taxToken]);
        //taxsBuffer[taxToken] = taxsBuffer[taxToken].mul(period[taxToken]).div(period[taxToken].add(now).sub(lastUpdateTime[taxToken]));
        //rewardsBuffer[taxToken] = rewardsBuffer[taxToken].sub(reward);
        
        //rewards[address(0)][address(0)] = rewards[address(0)][address(0)].add(reward);
        //if(ecoAddr != address(0)) {
        //    uint eco = reward.mul(ecoRatio).div(1e18);
        //    rewards[ecoAddr][taxToken] = rewards[ecoAddr][taxToken].add(eco);
        //    reward = reward.sub(eco);
        //}
        //rewards[msg.sender][taxToken] = rewards[msg.sender][taxToken].add(reward);
        
        uint reward;    uint rwdEco;    uint tax;
        (reward, rwdEco, rewardsBuffer[taxToken], taxsBuffer[taxToken], tax) = _swapFarmingable(taxToken, amount, rate);

        rewards[address(0)][address(0)] = rewards[address(0)][address(0)].add(reward.add(rwdEco));
        rewards[ecoAddr][taxToken] = rewards[ecoAddr][taxToken].add(rwdEco);
        rewards[msg.sender][taxToken] = rewards[msg.sender][taxToken].add(reward);
        
        swapAmounts[msg.sender][taxToken] = swapAmounts[msg.sender][taxToken].add(amount);
        swapAmounts[address(0)][taxToken] = swapAmounts[address(0)][taxToken].add(amount);
        swapTaxs[msg.sender][taxToken] = swapTaxs[msg.sender][taxToken].add(tax);
        swapTaxs[address(0)][taxToken] = swapTaxs[address(0)][taxToken].add(tax);
        lastUpdateTime[taxToken] = now;
        emit SwapFarming(msg.sender, taxToken, amount, tax, reward);
    }
    event SwapFarming(address sender, address taxToken, uint amount, uint tax, uint reward);
    
    function _swapFarmingable(address taxToken, uint amount, uint rate) internal view returns (uint reward, uint rwdEco, uint rwdsBuf, uint taxsBuf, uint tax) {
        if(begin[taxToken] == 0 || begin[taxToken] >= now || lastUpdateTime[taxToken] >= now)
            return (0, 0, 0, 0, 0);
        tax = amount.mul(rate).div(1e18);
        
        if(now < begin[taxToken].add(period[taxToken])) {
            taxsBuf = taxsBuffer[taxToken].mul(lastUpdateTime[taxToken].sub(begin[taxToken]));
            taxsBuf = taxsBuf.div(period[taxToken]).add(tax);
            taxsBuf = taxsBuf.mul(period[taxToken].add(now).sub(lastUpdateTime[taxToken]));
            taxsBuf = taxsBuf.div(now.sub(begin[taxToken]));
        } else
            taxsBuf = taxsBuffer[taxToken].add(tax);
        rwdsBuf = rewardsBuffer[taxToken].add(rewardDelta(taxToken));
        reward = rwdsBuf.mul(tax).div(taxsBuf);
        taxsBuf = taxsBuf.mul(period[taxToken]).div(period[taxToken].add(now).sub(lastUpdateTime[taxToken]));
        rwdsBuf = rwdsBuf.sub(reward);
        
        if(ecoAddr != address(0)) {
            rwdEco = reward.mul(ecoRatio).div(1e18);
            reward = reward.sub(rwdEco);
        }
    }
    
    function swapFarmingable(address taxToken, uint amount) external view returns (uint reward) {
        (reward, , , , ) = _swapFarmingable(taxToken, amount, TotoroSwapFactory(factory).feeRate(address(0)));
    }
    
    function swapFarmingablePath(uint amountIn, address[] calldata path) external view returns (uint reward) {
        uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        for(uint i=0; i<amounts.length-1; i++) {
            (uint feeRate, uint taxRate, address taxToken, ) = TotoroSwapFactory(factory).getTaxTo(path[i], path[i+1]);
            uint rate = feeRate.mul(taxRate) / 1e18;
            uint rwd = 0;
            if(path[i] == taxToken)
                (rwd, , , , ) = _swapFarmingable(path[i], amounts[i], rate);
            else if(path[i+1] == taxToken)
                (rwd, , , , ) = _swapFarmingable(path[i+1], amounts[i+1], rate);
            reward = reward.add(rwd);
        }
    }
    
    function rewardQuota() public view returns (uint) {
        return Math.min(rewardsToken.allowance(rewardsDistribution, address(this)), rewardsToken.balanceOf(rewardsDistribution)).sub0(rewards[address(0)][address(0)]);
    }
    
    function rewardDelta(address taxToken) public view returns (uint amt) {
        if(begin[taxToken] == 0 || begin[taxToken] >= now || lastUpdateTime[taxToken] >= now)
            return 0;
            
        amt = rewardQuota();
        
        // calc rewardDelta in period
        if(lep[taxToken] == 3) {                                                              // power
            //uint y = period.mul(1 ether).div(lastUpdateTime.add(rewardsDuration).sub(begin));
            //uint amt1 = amt.mul(1 ether).div(y);
            //uint amt2 = amt1.mul(period).div(now.add(rewardsDuration).sub(begin));
            uint amt2 = amt.mul(lastUpdateTime[taxToken].add(rewardsDuration[taxToken]).sub(begin[taxToken])).div(now.add(rewardsDuration[taxToken]).sub(begin[taxToken]));
            amt = amt.sub(amt2);
        } else if(lep[taxToken] == 2) {                                                       // exponential
            if(now.sub(lastUpdateTime[taxToken]) < rewardsDuration[taxToken])
                amt = amt.mul(now.sub(lastUpdateTime[taxToken])).div(rewardsDuration[taxToken]);
        }else if(now < periodFinish[taxToken])                                                // linear
            amt = amt.mul(now.sub(lastUpdateTime[taxToken])).div(periodFinish[taxToken].sub(lastUpdateTime[taxToken]));
        else if(lastUpdateTime[taxToken] >= periodFinish[taxToken])
            amt = 0;
            
        //if(ecoAddr != 0)
        //    amt = amt.mul(uint(1e18).sub(ecoRatio)).div(1 ether);
    }
    
    function earned(address account, address taxToken) public view returns (uint) {
        return rewards[account][taxToken];
    }

    function getReward(address taxToken) public {
        getRewardA(msg.sender, taxToken);
    }
    function getRewardA(address payable acct, address taxToken) public {
        uint reward = rewards[acct][taxToken];
        if (reward > 0) {
            rewards[acct][taxToken] = 0;
            rewards[address(0)][address(0)] = rewards[address(0)][address(0)].sub0(reward);
            paid[acct][taxToken] = paid[acct][taxToken].add(reward);
            paid[address(0)][taxToken] = paid[address(0)][taxToken].add(reward);
            address(rewardsToken).safeTransferFrom(rewardsDistribution, acct, reward);
            emit RewardPaid(acct, taxToken, reward);
        }
    }
    event RewardPaid(address indexed user, address taxToken, uint256 reward);

    function getRewardAs(address payable acct, address[] calldata taxTokens) external {
        for(uint i=0; i<taxTokens.length; i++)
            getRewardA(acct, taxTokens[i]);
    }
    
    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

library UniswapV2Library {
    using SafeMath for uint;
    //bytes32 private constant PairCodeHash = keccak256(type(InitializableProductProxy).creationCode);      // it will be changed when deploy because of Swarm bzzr
    //bytes32 private constant PairCodeHash = hex'9e3d176cd7b9504eb5f6b77283eeba7ad886f58601c2a02d5adcb699159904b4';
    //bytes32 private constant PairCodeHash = hex'71d15772a2b431bfcb85fd38973fe760b5765f961d5586544c62fabc8ba01d3c';

    //function pairCodeHash() internal pure returns (bytes32) {
    //    return PairCodeHash;
    //}
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        //(address token0, address token1) = sortTokens(tokenA, tokenB);
        //pair = address(uint(keccak256(abi.encodePacked(
        //        hex'ff',
        //        factory,
        //        keccak256(abi.encodePacked(token0, token1)),
		//		TotoroSwapFactory(factory).pairCodeHash                                    //hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
        //    ))));
        return TotoroSwapFactory(factory).getPairFor(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    //function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
    //    require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
    //    require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    //    uint amountInWithFee = amountIn.mul(997);
    //    uint numerator = amountInWithFee.mul(reserveOut);
    //    uint denominator = reserveIn.mul(1000).add(amountInWithFee);
    //    amountOut = numerator / denominator;
    //}

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    //function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
    //    require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    //    require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    //    uint numerator = reserveIn.mul(amountOut).mul(1000);
    //    uint denominator = reserveOut.sub(amountOut).mul(997);
    //    amountIn = (numerator / denominator).add(1);
    //}

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        //require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        //amounts = new uint[](path.length);
        //amounts[0] = amountIn;
        //for (uint i; i < path.length - 1; i++) {
        //    (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
        //    amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        //}
        return TotoroSwapFactory(factory).getAmountsOut(amountIn, path);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        //require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        //amounts = new uint[](path.length);
        //amounts[amounts.length - 1] = amountOut;
        //for (uint i = path.length - 1; i > 0; i--) {
        //    (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
        //    amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        //}
        return TotoroSwapFactory(factory).getAmountsIn(amountOut, path);
    }
}

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
        (bool success,) = to.call.value(value)(new bytes(0));           // (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


contract DeployFactory {
    event Deploy(string name, address addr);
    
    constructor(address adminFactory, address adminPair) public {
        TotoroSwapPair pair = new TotoroSwapPair();
        emit Deploy('TotoroSwapPair', address(pair));
        
        TotoroSwapFactory factory = new TotoroSwapFactory();
        emit Deploy('TotoroSwapFactory', address(factory));
        
        InitializableAdminUpgradeabilityProxy factoryProxy = new InitializableAdminUpgradeabilityProxy();
        factoryProxy.initialize(adminFactory, address(factory), abi.encodeWithSignature('initialize(address,address)', adminPair, address(pair)));
        emit Deploy('factoryProxy', address(factoryProxy));
        
        //selfdestruct(msg.sender);
    }
}
    
contract DeployRouter {
    event Deploy(bytes32 name, address addr);
    
    constructor(address adminRouter, address factoryProxy, address WETH) public {
        if(WETH == address(0))
            WETH = AddressWETH.WETH();
        require(WETH != address(0), 'TotoroSwapFactoryFactory: WETH address is 0x0');

        TotoroSwapRouter02 router = new TotoroSwapRouter02();
        router.__TotoroSwapRouter02_init(address(factoryProxy), WETH);
        emit Deploy('TotoroSwapRouter02', address(router));
        
        InitializableAdminUpgradeabilityProxy routerProxy = new InitializableAdminUpgradeabilityProxy();
        routerProxy.initialize(adminRouter, address(router), abi.encodeWithSignature('initialize(address,address)', address(factoryProxy), WETH));
        emit Deploy('routerProxy', address(routerProxy));
        
        //selfdestruct(msg.sender);
    }
}

//contract Test {
//    function pairFor(address factory, address tokenA, address tokenB) public pure returns (address) {
//        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
//    }
//    
//    function pairCreationCode() public pure returns (bytes memory) {
//        return type(InitializableProductProxy).creationCode;
//    }
//    
//    function pairCodeHash() public pure returns (bytes32) {
//        return UniswapV2Library.pairCodeHash();
//    }
//    
//    function pairCodeHash2() public pure returns (bytes32) {
//        return keccak256(type(InitializableProductProxy).creationCode);
//    }
//}

library AddressWETH {
    function WETH() internal pure returns (address addr) {
        assembly {
            switch chainid() 
                case  1  { addr := 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 }      // Ethereum Mainnet
                case  3  { addr := 0xc778417E063141139Fce010982780140Aa0cD5Ab }      // Ethereum Testnet Ropsten
                case  4  { addr := 0xc778417E063141139Fce010982780140Aa0cD5Ab }      // Ethereum Testnet Rinkeby
                case  5  { addr := 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 }      // Ethereum Testnet Gorli
                case 42  { addr := 0xd0A1E359811322d97991E03f863a0C30C2cF029C }      // Ethereum Testnet Kovan
                case 56  { addr := 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c }      // BSC Mainnet
                case 65  { addr := 0x2219845942d28716c0f7c605765fabdca1a7d9e0 }      // OKExChain Testnet
                case 66  { addr := 0x8f8526dbfd6e38e3d8307702ca8469bae6c56c15 }      // OKExChain Main
                case 128 { addr := 0x5545153ccfca01fbd7dd11c0b23ba694d9509a6f }      // HECO Mainnet 
                case 256 { addr := 0xB49f19289857f4499781AaB9afd4A428C4BE9CA8 }      // HECO Testnet 
                default  { addr := 0x0                                        }      // unknown 
        }
    }
}