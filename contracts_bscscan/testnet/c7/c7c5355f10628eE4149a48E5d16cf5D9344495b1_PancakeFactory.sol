/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 w, uint y) internal pure returns (uint224 z) {
        z = uint224(y) * uint224(w) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
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

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// a library for performing various math operations

library Math {
    function min(uint w, uint x,uint y) internal pure returns (uint z) {
        z = w < x && w < y && x < y ? x + w : y;
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


interface IPancakePair {
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1,uint112 reserve2, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1, uint amount2);
    function swap(uint amount0Out, uint amount1Out,uint amount2Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address , address , address) external;
}


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB, address tokenC) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB,address tokenC) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeERC20 {
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
interface IPancakeCallee {
    function pancakeCall(address sender, uint amount0, uint amount1,uint amount2, bytes calldata data) external;
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


contract PancakeERC20 is IPancakeERC20 {
    using SafeMath for uint;

    string public constant name = 'Panther LP';
    string public constant symbol = 'Parfait-LP';
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
        require(deadline >= block.timestamp, 'Pancake: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Pancake: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
contract PancakePair is IPancakePair, PancakeERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;
    address public token2;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;// uses single storage slot, accessible via getReserves
    uint112 private reserve2;
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public price2CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Pancake: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1,uint112 _reserve2, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _reserve2 = reserve2;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Pancake: TRANSFER_FAILED');
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
    event Sync(uint112 reserve0, uint112 reserve1,uint112 reserve2);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address _token2) external {
        require(msg.sender == factory, 'Pancake: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        token2 = _token2;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint balance2 ,uint112 _reserve0, uint112 _reserve1,uint112 _reserve2) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1) && balance2 <= uint112(-1), 'Pancake: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0 && _reserve2 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve2,_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0,_reserve1).uqdiv(_reserve2)) * timeElapsed;
            price2CumulativeLast += uint(UQ112x112.encode(_reserve1,_reserve2).uqdiv(_reserve0)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        reserve2 = uint112(balance2);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1,reserve2);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1, uint112 _reserve2) private returns (bool feeOn) {
        address feeTo = IPancakeFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1).mul(_reserve2));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(3).add(rootKLast);
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
        (uint112 _reserve0, uint112 _reserve1,uint112 _reserve2,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint balance2 = IERC20(token2).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        uint amount2 = balance2.sub(_reserve2);

        bool feeOn = _mintFee(_reserve0, _reserve1, _reserve2);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1).mul(amount2)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1, amount2.mul(_totalSupply) / _reserve2);
        }
        require(liquidity > 0, 'Pancake: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1,balance2, _reserve0, _reserve1,_reserve2);
        if (feeOn) kLast = uint(reserve0).mul(reserve1).mul(reserve2); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }
    function _burn1(address _to) internal returns(uint balance1, uint amount1) {
       (uint112 re0,uint112 re1,uint112 re2,) = getReserves();
       address _token1 = token1;
       balance1 = IERC20(_token1).balanceOf(address(this));
       uint liquidity = balanceOf[address(this)];
        uint _totalSupply = totalSupply;
        amount1 = liquidity.mul(balance1) / _totalSupply; 
        //require(amount0 > 0 && amount1 > 0 && amount2 > 0, 'Pancake: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token1, _to, amount1);
      //  if (feeOn) kLast = uint(re0).mul(re1).mul(re2);
    }
    function _burn2(address _to) internal returns(uint balance2, uint amount2) {
       (uint112 re0, uint112 re1, uint112 re2,) = getReserves(); 
       address _token2 = token2;
        balance2 = IERC20(_token2).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
     
        uint _totalSupply = totalSupply;
        amount2 = liquidity.mul(balance2) / _totalSupply; 
        //require(amount0 > 0 && amount1 > 0 && amount2 > 0, 'Pancake: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token2, _to, amount2);
    }
    function _burn0(address _to) internal returns(uint balance0, uint amount0 ){
       (uint112 r0, uint112 r1 , uint112 r2,) = getReserves(); // gas saving
        address _token0 = token0;                                // gas savings
         balance0 = IERC20(_token0).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

    
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
         amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        _burn(address(this), liquidity);
        _safeTransfer(_token0, _to, amount0);
      
       
    }
    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint , uint , uint ) {
       (uint112 r0, uint112 r1 , uint112 r2,) = getReserves(); // gas saving
       (uint balance0, uint amount0) = _burn0(to); // gas saving
       (uint balance1,  uint amount1) = _burn1(to); // gas saving
       (uint balance2, uint amount2) = _burn2(to); // gas saving
        bool feeOn = _mintFee(r0,r1,r2);
        require(amount0 > 0 && amount1 > 0 && amount2 > 0, 'Pancake: INSUFFICIENT_LIQUIDITY_BURNED');    
        _update(balance0, balance1,balance2, r0, r1,r2);
        if (feeOn) kLast = uint(r0).mul(r1).mul(r2); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
       // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }
   function _swap0(uint amount0Out, address to) internal returns(uint, uint) {
     //   require(amount0Out > 0, 'Pancake: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,uint _reserve2,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 , 'Pancake: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        require(to != _token0 , 'Pancake: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
   //     if (data.length > 0) IPancakeCallee(to).pancakeCall(msg.sender, amount0Out, amount0Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        require(amount0In > 0, 'Pancake: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(2));
        //require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Pancake: K');
        }
       return (amount0Out, balance0);
    //    _update(balance0, balance1, _reserve0, _reserve1);
        //emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
      function _swap1(uint amount1Out, address to) internal returns(uint,  uint) {
      //  require(amount1Out > 0, 'Pancake: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,uint _reserve2,) = getReserves(); // gas savings
        require( amount1Out < _reserve1, 'Pancake: INSUFFICIENT_LIQUIDITY');

        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token1 = token1;
        require(to != _token1 , 'Pancake: INVALID_TO');
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        //if (data.length > 0) IPancakeCallee(to).pancakeCall(msg.sender, amount1Out, amount1Out, data);
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require( amount1In > 0, 'Pancake: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(2));
     //   require(balance1Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Pancake: K');
        }
        return (amount1Out, balance1);
    //    _update(balance0, balance1, _reserve0, _reserve1);
    //    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
      function _swap2(uint amount2Out, address to) internal returns(uint, uint) {
      //  require(amount2Out > 0, 'Pancake: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve, uint112 _reserve1,uint _reserve2,) = getReserves(); // gas savings
        require( amount2Out < _reserve2, 'Pancake: INSUFFICIENT_LIQUIDITY');

        uint balance2;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token2 = token2;
        require(to != _token2 , 'Pancake: INVALID_TO');
        if (amount2Out > 0) _safeTransfer(_token2, to, amount2Out); // optimistically transfer tokens
      //  if (data.length > 0) IPancakeCallee(to).pancakeCall(msg.sender, amount2Out, amount2Out, data);
        balance2 = IERC20(_token2).balanceOf(address(this));
        }
        uint amount2In = balance2 > _reserve2 - amount2Out ? balance2 - (_reserve2 - amount2Out) : 0;
        require(amount2In > 0, 'Pancake: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance2Adjusted = balance2.mul(1000).sub(amount2In.mul(2));
        //require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Pancake: K');
        }

    //    _update(balance0, balance1, _reserve0, _reserve1);
       return (amount2Out, balance2);
      }

      function isKError(
          uint amount0Out,
          uint amount1Out,
          uint amount2Out,
          uint balance0,
          uint balance1,
          uint balance2,
          address to
          ) internal {
        (uint112 _reserve0, uint112 _reserve1,uint112 _reserve2,) = getReserves(); // gas savings
        (amount0Out, balance0) = _swap0(amount0Out, to);
        (amount1Out, balance1) = _swap1(amount1Out, to);
        (amount2Out, balance2) = _swap2(amount2Out, to);

          uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        uint amount2In = balance2 > _reserve2 - amount2Out ? balance2 - (_reserve2 - amount2Out) : 0;
           // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(2));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(2));
        uint balance2Adjusted = balance2.mul(1000).sub(amount2In.mul(2)); 
       require(balance0Adjusted.mul(balance1Adjusted).mul(balance2Adjusted) >= uint(_reserve0).mul(_reserve1).mul(reserve2).mul(1000**2), 'Pancake: K');
       
      }
    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out,uint amount2Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0 || amount2Out > 0, 'Pancake: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,uint112 _reserve2,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1 && amount2Out < _reserve2, 'Pancake: INSUFFICIENT_LIQUIDITY');
         uint balance0;
         uint balance1;
         uint balance2;
        if (data.length > 0) IPancakeCallee(to).pancakeCall(msg.sender, amount0Out, amount1Out,amount2Out, data);
        (amount0Out, balance0) = _swap0(amount0Out, to);
        (amount1Out, balance1) = _swap1(amount1Out, to);
        (amount2Out, balance2) = _swap2(amount2Out, to);
        
        isKError(amount0Out,amount1Out, amount2Out, balance0,balance1,balance2,to);

        _update(balance0, balance1,balance2,_reserve0, _reserve1,_reserve2);
   //     emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        address _token2 = token2;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
        _safeTransfer(_token2, to, IERC20(_token2).balanceOf(address(this)).sub(reserve2));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)),IERC20(token2).balanceOf(address(this)), reserve0, reserve1, reserve2);
    }
}

contract PancakeFactory is IPancakeFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(PancakePair).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => mapping(address => address))) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB, address tokenC) external returns (address pair) {
        require(tokenA != tokenB && tokenB != tokenC && tokenA != tokenC, 'Pancake: IDENTICAL_ADDRESSES');
        (address token0, address token1,address token2) = tokenA < tokenB || tokenA < tokenC && tokenB < tokenC ? (tokenA, tokenB,tokenC) : (tokenC, tokenB,tokenA);
        require(token0 != address(0) && token1 != address(0), 'Pancake: ZERO_ADDRESS');
        require(getPair[token0][token1][token2] == address(0), 'Pancake: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(PancakePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1,token2));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IPancakePair(pair).initialize(token0, token1,token2);
        getPair[token0][token1][token2] = pair;
        getPair[token1][token2][token0] = pair;// populate mapping in the reverse direction
        getPair[token2][token1][token0] = pair;
        getPair[token0][token2][token1] = pair;
        getPair[token1][token0][token2] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Pancake: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Pancake: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}