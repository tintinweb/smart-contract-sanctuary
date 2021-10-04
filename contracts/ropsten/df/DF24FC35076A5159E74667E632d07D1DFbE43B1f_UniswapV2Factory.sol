/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.6;



// Part: IERC20

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

// Part: IUniswapV2Callee

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// Part: IUniswapV2Factory

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

// Part: Math

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

// Part: Ownable

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

// Part: SafeMath

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// Part: Utils

library Utils {
    struct PoolInfo {
        address pool;
        uint32 poolType;
        uint64 poolId;
    }


    function getAmount(uint _calldataPointer) internal pure returns (uint112 amount, uint calldataPointer) {
        calldataPointer = _calldataPointer;
        uint8 firstByte = uint8(msg.data[calldataPointer++]);
        uint8 decimals;
        uint8 amountBytes;
        //using temp uint variable saves pointless and opcodes
        uint amount_ = 0;
        uint8 t = 0xF0;
        if(firstByte&t == t) {
            amountBytes = firstByte&0x0F;
            decimals = 0;
        }
        else {
            decimals = firstByte&0x1F;
            amountBytes = (firstByte&0xE0)>>5;
        }
        for(uint i = 0; i < amountBytes+1; i++) {
            amount_ <<= 8;
            amount_ += uint8(msg.data[calldataPointer++]);
        }
        amount = uint112(amount_*10**uint(decimals));
    }

    function getPoolIdWithTokenId(uint _calldataPointer) internal pure returns (uint poolId, bool token0First, uint calldataPointer) {
        calldataPointer = _calldataPointer;
        uint8 lastByte = uint8(msg.data[calldataPointer++]);
        poolId = lastByte&0x3F;
        token0First = (lastByte&0x40) == 0 ? true : false;
        //next byte flag
        if(lastByte&0x80 != 0) {
            lastByte = uint8(msg.data[calldataPointer++]);
            poolId += uint(lastByte&0x7F)<<6;
            for(uint i = 1; lastByte&0x80 != 0; i++) {
                lastByte = uint8(msg.data[calldataPointer++]);
                poolId += uint(lastByte&0x7F)<<(6+7*i);
            }
        }
    }

    function getPoolIdWithoutTokenId(uint _calldataPointer) internal pure returns (uint poolId, uint calldataPointer) {
        calldataPointer = _calldataPointer;
        uint lastByte = 0;
        do {
            poolId <<= 7;
            lastByte = uint8(msg.data[calldataPointer++]);
            poolId += uint(lastByte&0x7F);
        } while(lastByte&0x80 != 0);
    }

    function getPoolIdCount(uint calldataPointer) internal pure returns (uint count) {
        while(calldataPointer < msg.data.length) {
                while(uint8(msg.data[calldataPointer++])&0x80 != 0) {}
            count++;
        }
    }
}

// Part: PoolRegistry

contract PoolRegistry is Ownable {
    Utils.PoolInfo[] public allPools;
    mapping(address => bool) public canAddPools;

    function addAuthorizedPoolAdder(address authorized) external onlyOwner {
        canAddPools[authorized] = true;
    }

    function addPool(address pool, uint32 poolType) external returns (uint64 poolId) {
        require(canAddPools[msg.sender] == true, "not authorized");
        poolId = uint64(allPools.length);
        allPools.push(Utils.PoolInfo(pool, poolType, poolId));
        return poolId;
    }

    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }
}

// Part: UniswapV2ERC20

contract UniswapV2ERC20 {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    uint  public totalSupply;
    string constant public name = "Zipswap LP Token";
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) internal _allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
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

    function symbol() external view virtual returns (string memory) {
        return 'LP';
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
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function allowance(address _owner, address _spender) external virtual view returns (uint256) {
        return _allowance[_owner][_spender];
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual returns (bool) {
        if (_allowance[from][msg.sender] != type(uint256).max) {
            _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'swap: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'swap: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// Part: UniswapV2Pair

contract UniswapV2Pair is UniswapV2ERC20 {
    using SafeMath  for uint;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address constant routerPacked = 0x00000000005ef20f4c4Bb5B2D516Ee674D4FdFBb;
    address public immutable factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Zipswap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function tokens() public view returns (address _token0, address _token1) {
        return (token0, token1);
    }

    function symbol() external view override returns (string memory) {
        return string(abi.encodePacked(IERC20(token0).symbol(), "-", IERC20(token1).symbol(), "-ZS"));
    }

    function allowance(address _owner, address _spender) external override view returns (uint256) {
        if(_spender == routerPacked) {
            return type(uint256).max;
        }
        return _allowance[_owner][_spender];
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if(msg.sender != routerPacked) {
            if (_allowance[from][msg.sender] != type(uint256).max) {
                _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
            }
        }
        _transfer(from, to, value);
        return true;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Zipswap: TRANSFER_FAILED');
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

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'Zipswap: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Zipswap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        //uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
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
        require(liquidity > 0, 'Zipswap: INSUFFICIENT_LIQUIDITY_MINTED');
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
        require(amount0 > 0 && amount1 > 0, 'Zipswap: INSUFFICIENT_LIQUIDITY_BURNED');
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
        require(amount0Out > 0 || amount1Out > 0, 'Zipswap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Zipswap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'Zipswap: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Zipswap: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Zipswap: K');
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
}

// File: UniswapV2Factory.sol

contract UniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => Utils.PoolInfo)) internal _getPair;
    PoolRegistry immutable public poolRegistry;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, PoolRegistry _poolRegistry) {
        feeToSetter = _feeToSetter;
        poolRegistry = _poolRegistry;
    }

    //for compatibility
    function getPair(address tokenA, address tokenB) external view returns(address) {
        return _getPair[tokenA][tokenB].pool;
    }

    function getPool(address tokenA, address tokenB) external view returns(address pool, uint32 poolType, uint64 poolId) {
        Utils.PoolInfo memory poolInfo = _getPair[tokenA][tokenB];
        (pool, poolType, poolId) = (poolInfo.pool, poolInfo.poolType, poolInfo.poolId);
    }

    function allPairsLength() external view returns (uint) {
        return poolRegistry.allPoolsLength();
    }

    function allPairs(uint id) external view returns (address) {
        (address pool, uint32 poolType,) = poolRegistry.allPools(id);
        require(poolType == 0, 'Zipswap: UNKNOWN_POOL_TYPE');
        return pool;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Zipswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Zipswap: ZERO_ADDRESS');
        require(_getPair[token0][token1].pool == address(0), 'Zipswap: PAIR_EXISTS'); // single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        UniswapV2Pair _pair = new UniswapV2Pair{salt: salt}();
        _pair.initialize(token0, token1);
        pair = address(_pair);
        uint64 poolId = poolRegistry.addPool(pair, 0);
        Utils.PoolInfo memory poolInfo = Utils.PoolInfo(pair, 0, poolId);
        _getPair[token0][token1] = poolInfo;
        _getPair[token1][token0] = poolInfo; // populate mapping in the reverse direction
        emit PairCreated(token0, token1, pair, poolRegistry.allPoolsLength());
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Zipswap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Zipswap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}