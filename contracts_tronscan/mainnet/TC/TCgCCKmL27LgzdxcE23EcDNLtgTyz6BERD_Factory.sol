//SourceUnit: Factory.sol

/*! Factory.sol | SPDX-License-Identifier: MIT License */

pragma solidity 0.5.12;

interface ITRC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
}

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 index);

    function createPair(address tokenA, address tokenB) external returns(address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function feeTo() external view returns(address);
    function feeToSetter() external view returns(address);
    function pairs(address tokenA, address tokenB) external view returns(address pair);
    function getPair(address tokenA, address tokenB) external view returns(address pair);
    function allPairs(uint256) external view returns(address pair);
    function allPairsLength() external view returns(uint256);
}

interface IPair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function mint(address to) external returns(uint256 liquidity);
    function burn(address to) external returns(uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;

    function MINIMUM_LIQUIDITY() external pure returns(uint256);
    function factory() external view returns(address);
    function token0() external view returns(address);
    function token1() external view returns(address);
    function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns(uint256);
    function price1CumulativeLast() external view returns(uint256);
    function kLast() external view returns(uint256);
}

interface ICallee {
    function call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library Math {
    function min(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns(uint256 z) {
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

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    function encode(uint112 y) internal pure returns(uint224 z) {
        z = uint224(y) * Q112;
    }

    function uqdiv(uint224 x, uint112 y) internal pure returns(uint224 z) {
        z = x / uint224(y);
    }
}

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    string public constant name = 'IOTU';
    string public constant symbol = 'IOTU';
    uint8 public constant decimals = 18;
    
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

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

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns(bool) {
        _approve(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns(bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns(bool) {
        if(allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }

        _transfer(from, to, value);

        return true;
    }
}

contract Pair is TRC20, IPair {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;
    
    uint256 private unlocked = 1;

    address public factory;
    address public token0;
    address public token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint256 public kLast;

    modifier lock() {
        require(unlocked == 1, 'Lock: LOCKED');

        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        factory = msg.sender;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (token == 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C || data.length == 0 || abi.decode(data, (bool))), 'Pair: TRANSFER_FAILED');
    }

    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Pair: OVERFLOW');

        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if(timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;

        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns(bool feeOn) {
        address feeTo = IFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;

        if(feeOn) {
            if(_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);

                if(rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;

                    if(liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        }
        else if(_kLast != 0) kLast = 0;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'Pair: FORBIDDEN');

        token0 = _token0;
        token1 = _token1;
    }

    function mint(address to) external lock returns(uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        uint256 balance0 = ITRC20(token0).balanceOf(address(this));
        uint256 balance1 = ITRC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);

        if(totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);

           _mint(address(0), MINIMUM_LIQUIDITY);
        }
        else liquidity = Math.min(amount0.mul(totalSupply) / _reserve0, amount1.mul(totalSupply) / _reserve1);
        
        require(liquidity > 0, 'Pair: INSUFFICIENT_LIQUIDITY_MINTED');

        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);

        if(feeOn) kLast = uint256(reserve0).mul(reserve1);

        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external lock returns(uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        uint256 balance0 = ITRC20(token0).balanceOf(address(this));
        uint256 balance1 = ITRC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        bool feeOn = _mintFee(_reserve0, _reserve1);

        amount0 = liquidity.mul(balance0) / totalSupply;
        amount1 = liquidity.mul(balance1) / totalSupply;

        require(amount0 > 0 && amount1 > 0, 'Pair: INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(address(this), liquidity);
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = ITRC20(token0).balanceOf(address(this));
        balance1 = ITRC20(token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);

        if(feeOn) kLast = uint256(reserve0).mul(reserve1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Pair: INSUFFICIENT_OUTPUT_AMOUNT');

        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Pair: INSUFFICIENT_LIQUIDITY');

        require(to != token0 && to != token1, 'Pair: INVALID_TO');

        if(amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if(amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        if(data.length > 0) ICallee(to).call(msg.sender, amount0Out, amount1Out, data);

        uint256 balance0 = ITRC20(token0).balanceOf(address(this));
        uint256 balance1 = ITRC20(token1).balanceOf(address(this));
        
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        
        require(amount0In > 0 || amount1In > 0, 'Pair: INSUFFICIENT_INPUT_AMOUNT');

        {
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));

            require(balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(1000 ** 2), 'Pair: Bad swap');
        }

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function skim(address to) external lock {
        _safeTransfer(token0, to, ITRC20(token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(token1, to, ITRC20(token1).balanceOf(address(this)).sub(reserve1));
    }

    function sync() external lock {
        _update(ITRC20(token0).balanceOf(address(this)), ITRC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function getReserves() public view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
}

contract Factory is IFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function createPair(address tokenA, address tokenB) external returns(address pair) {
        require(tokenA != tokenB, 'Factory: IDENTICAL_ADDRESSES');

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(token0 != address(0), 'Factory: ZERO_ADDRESS');
        require(pairs[token0][token1] == address(0), 'Factory: PAIR_EXISTS');

        pair = address(new Pair());

        IPair(pair).initialize(token0, token1);

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Factory: FORBIDDEN');

        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Factory: FORBIDDEN');

        feeToSetter = _feeToSetter;
    }

    function getPair(address tokenA, address tokenB) external view returns(address pair) {
        pair = tokenA < tokenB ? pairs[tokenA][tokenB] : pairs[tokenB][tokenA];
    }

    function allPairsLength() external view returns(uint256) {
        return allPairs.length;
    }
}