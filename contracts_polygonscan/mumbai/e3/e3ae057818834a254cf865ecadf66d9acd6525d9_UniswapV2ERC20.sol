/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

/**
 *Submitted for verification at polygonscan.com on 2021-05-18
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: contracts/interfaces/IUniswapV2ERC20.sol

pragma solidity >=0.5.0;

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

// File: contracts/libraries/SafeMath.sol

pragma solidity =0.5.16;

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

// File: contracts/UniswapV2ERC20.sol

pragma solidity =0.5.16;



contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;
    
     address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint256  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
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

    function _mint(address to, uint value) public {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) public {
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
    
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint256 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
    
    function setReserve(uint112 _reserve0, uint112 _reserve1) public {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = block.timestamp;
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

// // File: contracts/libraries/Math.sol

// pragma solidity =0.5.16;

// // a library for performing various math operations

// library Math {
//     function min(uint x, uint y) internal pure returns (uint z) {
//         z = x < y ? x : y;
//     }

//     // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
//     function sqrt(uint y) internal pure returns (uint z) {
//         if (y > 3) {
//             z = y;
//             uint x = y / 2 + 1;
//             while (x < z) {
//                 z = x;
//                 x = (y / x + x) / 2;
//             }
//         } else if (y != 0) {
//             z = 1;
//         }
//     }
// }

// // File: contracts/libraries/UQ112x112.sol

// pragma solidity =0.5.16;

// // a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// // range: [0, 2**112 - 1]
// // resolution: 1 / 2**112

// library UQ112x112 {
//     uint224 constant Q112 = 2**112;

//     // encode a uint112 as a UQ112x112
//     function encode(uint112 y) internal pure returns (uint224 z) {
//         z = uint224(y) * Q112; // never overflows
//     }

//     // divide a UQ112x112 by a uint112, returning a UQ112x112
//     function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
//         z = x / uint224(y);
//     }
// }

// // File: contracts/interfaces/IERC20.sol

// pragma solidity >=0.5.0;

// interface IERC20 {
//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Transfer(address indexed from, address indexed to, uint value);

//     function name() external view returns (string memory);
//     function symbol() external view returns (string memory);
//     function decimals() external view returns (uint8);
//     function totalSupply() external view returns (uint);
//     function balanceOf(address owner) external view returns (uint);
//     function allowance(address owner, address spender) external view returns (uint);

//     function approve(address spender, uint value) external returns (bool);
//     function transfer(address to, uint value) external returns (bool);
//     function transferFrom(address from, address to, uint value) external returns (bool);
// }

// // File: contracts/interfaces/IUniswapV2Factory.sol

// pragma solidity >=0.5.0;

// interface IUniswapV2Factory {
//     event PairCreated(address indexed token0, address indexed token1, address pair, uint);

//     function feeTo() external view returns (address);
//     function feeToSetter() external view returns (address);

//     function getPair(address tokenA, address tokenB) external view returns (address pair);
//     function allPairs(uint) external view returns (address pair);
//     function allPairsLength() external view returns (uint);

//     function createPair(address tokenA, address tokenB) external returns (address pair);

//     function setFeeTo(address) external;
//     function setFeeToSetter(address) external;
// }

// // File: contracts/interfaces/IUniswapV2Callee.sol

// pragma solidity >=0.5.0;

// interface IUniswapV2Callee {
//     function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
// }

// // File: contracts/UniswapV2Pair.sol

// pragma solidity =0.5.16;








// contract UniswapV2Pair is UniswapV2ERC20 {
//     using SafeMath  for uint;
//     using UQ112x112 for uint224;

//     uint public constant MINIMUM_LIQUIDITY = 10**3;
//     bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

//     address public factory;
//     address public token0;
//     address public token1;

//     uint112 private reserve0;           // uses single storage slot, accessible via getReserves
//     uint112 private reserve1;           // uses single storage slot, accessible via getReserves
//     uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

//     uint public price0CumulativeLast;
//     uint public price1CumulativeLast;
//     uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

//     uint private unlocked = 1;
//     modifier lock() {
//         require(unlocked == 1, 'UniswapV2: LOCKED');
//         unlocked = 0;
//         _;
//         unlocked = 1;
//     }
//     function setReserve(uint112 _reserve0, uint112 _reserve1) public returns () {
//         reserve0 = _reserve0;
//         reserve1 = _reserve1;
//         blockTimestampLast = block.timestamp;
//     }

//     function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
//         _reserve0 = reserve0;
//         _reserve1 = reserve1;
//         _blockTimestampLast = blockTimestampLast;
//     }

    
// }