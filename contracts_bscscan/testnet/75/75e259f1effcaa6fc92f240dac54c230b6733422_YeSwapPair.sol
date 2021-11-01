/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// Dependency file: contracts\interfaces\IYeSwapERC20.sol

// SPDX-License-Identifier: MIT
// pragma solidity >=0.6.12;

interface IYeSwapERC20 {
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

// Dependency file: contracts\interfaces\IYeSwapPair.sol

// pragma solidity >=0.6.12;

// import 'contracts\interfaces\IYeSwapERC20.sol';

interface IYeSwapPair is IYeSwapERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount1Out, address indexed to );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function pairOwner() external view returns (address);
    function tokenIn() external view returns (address);
    function tokenOut() external view returns (address);
    function getReserves() external view returns ( uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast);
    function getTriggerRate() external view returns (uint);
    function getOracleInfo() external view returns (uint, uint, uint);
    
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amountOut, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, uint, uint) external;
}

// Dependency file: contracts\libraries\SafeMath.sol

// pragma solidity >=0.6.12;

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

// Dependency file: contracts\YeSwapERC20.sol

// pragma solidity =0.6.12;

// import 'contracts\interfaces\IYeSwapERC20.sol';
// import 'contracts\libraries\SafeMath.sol';

contract YeSwapERC20 is IYeSwapERC20 {
    using SafeMath for uint;

    string public constant override name = 'YeSwap';
    string public constant override symbol = 'YESP';
    uint8 public constant override decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public immutable override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
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

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) override external {
        require(deadline >= block.timestamp, 'YeSwap: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'YeSwap: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// Dependency file: contracts\libraries\Math.sol

// pragma solidity >=0.6.12;

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

// Dependency file: contracts\libraries\UQ112x112.sol

// pragma solidity >=0.6.12;

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

// Dependency file: contracts\interfaces\IERC20.sol

// pragma solidity >=0.6.12;

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

// Dependency file: contracts\interfaces\IYeSwapFactory.sol

// pragma solidity >=0.6.12;

interface IYeSwapFactory {
    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAAB, address pairABB, uint);

    function feeTo() external view returns (address);
    function getFeeInfo() external view returns (address, uint256);
    function factoryAdmin() external view returns (address);
    function routerYeSwap() external view returns (address);  
    function nftYeSwap() external view returns (address);  
    function rateTriggerFactory() external view returns (uint16);  
    function rateCapArbitrage() external view returns (uint16);     
    function rateProfitShare() external view returns (uint16); 

    function getPair(address tokenA, address tokenB) external view returns (address pairAB, address pairBA);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createUpdatePair(address tokenA, address tokenB, address pairOwner, uint256 rateTrigger, uint256 switchOracle) 
                                external returns (address pairAAB,address pairABB);

    function setFeeTo(address) external;
    function setFactoryAdmin(address) external;
    function setRouterYeSwap(address) external;
    function configFactory(uint16, uint16, uint16) external;
//    function managePair(address, address, address, address, uint256) external;
    function getPairTokens() external view returns (address pairIn, address pairOut);
}

// Dependency file: contracts\interfaces\IYeSwapCallee.sol

// pragma solidity >=0.6.12;

interface IYeSwapCallee {
    function YeSwapCall(address sender, uint amountOut, bytes calldata data) external;
}

// Dependency file: contracts\libraries\TransferHelper.sol

// pragma solidity >=0.6.12;


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

// Root file: contracts\YeSwapPair.sol

pragma solidity =0.6.12;

// import 'contracts\interfaces\IYeSwapPair.sol';
// import 'contracts\YeSwapERC20.sol';
// import 'contracts\libraries\Math.sol';
// import 'contracts\libraries\UQ112x112.sol';
// import 'contracts\interfaces\IERC20.sol';
// import 'contracts\interfaces\IYeSwapFactory.sol';
// import 'contracts\interfaces\IYeSwapCallee.sol';
// import 'contracts\libraries\TransferHelper.sol';

contract YeSwapPair is IYeSwapPair, YeSwapERC20 {

    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;

    address public immutable override factory;
    address public immutable override tokenIn;
    address public immutable override tokenOut;
    address public override pairOwner;

    uint112 private reserveIn;              // uses single storage slot, accessible via getReserves
    uint112 private reserveOut;             // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast;     // uses single storage slot, accessible via getReserves

    uint private price0CumulativeLast;
    uint private price1CumulativeLast;
    uint private kLast;                     // reserveIn * reserveOut, as of immediately after the most recent liquidity event

    uint private rateTriggerArbitrage;

    uint private unlocked = 0x5A;
    modifier lock() {
        require(unlocked == 0x5A, 'YeSwap: LOCKED');
        unlocked = 0x69;
        _;
        unlocked = 0x5A;
    }
  
    function getReserves() public view override returns ( uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast) {
        _reserveIn = reserveIn;
        _reserveOut = reserveOut;
        _blockTimestampLast = blockTimestampLast;
    }

    function getTriggerRate() public view override returns (uint) {
        return rateTriggerArbitrage;
    }

    function getOracleInfo() public view override returns ( uint _price0CumulativeLast, uint _price1CumulativeLast, uint _kLast) {
        return (price0CumulativeLast, price1CumulativeLast, kLast);
    }

    event Mint(address indexed sender, uint amountIn, uint amountOut);
    event Burn(address indexed sender, uint amountIn, uint amountOut, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserveIn, uint112 reserveOut);

    constructor() public {
        factory     = msg.sender;
        (tokenIn, tokenOut) = IYeSwapFactory(msg.sender).getPairTokens();
    }

    function initialize(address _pairOwner, address router, uint rateTrigger, uint switchOracle) external override {
        require(msg.sender == factory, 'YeSwap: FORBIDDEN');
        
        address _tokenIn = tokenIn;
        if(pairOwner == address(type(uint160).max)) {
            TransferHelper.safeApprove(_tokenIn, router, 0);             // Remove Approve, only from Factory admin
        } else {
            pairOwner  = _pairOwner;
            if(router != address(0))
                TransferHelper.safeApprove(_tokenIn, router, type(uint).max);  // Approve Rourter to transfer out tokenIn for auto-arbitrage
        }

        if(rateTrigger != 0)  rateTriggerArbitrage = uint16(rateTrigger); 

        if(switchOracle == 0)  return;                                   // = 0, do not change the oracle setting
        if(switchOracle == uint(1)) {                                    // = 1, open price oracle setting  
            blockTimestampLast = uint32(block.timestamp % 2**32);
            return;
        }
        if(switchOracle == type(uint).max) {                                  // = -1, close price oracle setting  
            blockTimestampLast = 0;
            price0CumulativeLast = 0;
            price1CumulativeLast = 0;
        }
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balanceIn, uint balanceOut, uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast) private {
        require(balanceIn <= type(uint112).max && balanceOut <= type(uint112).max, 'YeSwap: OVERFLOW');
        uint32 blockTimestamp;
        if(_blockTimestampLast == 0){
            blockTimestamp = uint32(0);
        }
        else {                             // check if oracle is activated or not
            blockTimestamp = uint32(block.timestamp % 2**32);
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            if (timeElapsed > 0 && _reserveIn != 0 && _reserveOut != 0) {
                // * never overflows, and + overflow is desired
                price0CumulativeLast += uint(UQ112x112.encode(_reserveOut).uqdiv(_reserveIn)) * timeElapsed;
                price1CumulativeLast += uint(UQ112x112.encode(_reserveIn).uqdiv(_reserveOut)) * timeElapsed;
            }
        }
        reserveIn = uint112(balanceIn);
        reserveOut = uint112(balanceOut);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserveIn, reserveOut);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserveIn, uint112 _reserveOut) private returns (bool feeOn) {
        (address feeTo, uint rateProfitShare) = IYeSwapFactory(factory).getFeeInfo();
        feeOn = (feeTo != address(0)) || (pairOwner != address(0));
        uint _kLast = kLast;            // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = uint(_reserveIn).mul(_reserveOut);
                if (rootK > _kLast.add(uint(_reserveIn).mul(200))) {     // ignore swap dust increase, select 200 randomly 
                    rootK = Math.sqrt(rootK);
                    _kLast = Math.sqrt(_kLast);
                    uint numerator = totalSupply.mul(rootK.sub(_kLast)).mul(6);
                    uint denominator = rootK.mul(rateProfitShare).add(_kLast);
                    uint liquidityCreator = numerator / (denominator.mul(10));
                    if((liquidityCreator > 0) && (pairOwner != address(0))) {
                        _mint(pairOwner, liquidityCreator);
                    } 
                    uint liquidityYeSwap = numerator / (denominator.mul(15));
                    if((liquidityYeSwap > 0)  && (feeTo != address(0))) {
                        _mint(feeTo, liquidityYeSwap);
                    } 
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }            
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast) = getReserves(); // gas savings
        uint balanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint balanceOut = IERC20(tokenOut).balanceOf(address(this));
        uint amountTokenIn = balanceIn.sub(_reserveIn);
        uint amountTokenOut = balanceOut.sub(_reserveOut);

        bool feeOn = _mintFee(_reserveIn, _reserveOut);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountTokenIn.mul(amountTokenOut)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amountTokenIn.mul(_totalSupply) / _reserveIn, amountTokenOut.mul(_totalSupply) / _reserveOut);
        }
        require(liquidity > 0, 'YeSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balanceIn, balanceOut, _reserveIn, _reserveOut, _blockTimestampLast);
        if (feeOn) kLast = uint(reserveIn).mul(reserveOut);                    // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amountTokenIn, amountTokenOut);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock override returns (uint amountIn, uint amountOut) {
        (uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast) = getReserves();     // gas savings
        (address _tokenIn, address _tokenOut) = (tokenIn, tokenOut);    // gas savings
        uint balanceIn = IERC20(_tokenIn).balanceOf(address(this));
        uint balanceOut = IERC20(_tokenOut).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];                      // liquidity to remove

        bool feeOn = _mintFee(_reserveIn, _reserveOut);
        uint _totalSupply = totalSupply;                        // gas savings, must be defined here since totalSupply can update in _mintFee
        amountIn = liquidity.mul(balanceIn) / _totalSupply;     // using balances ensures pro-rata distribution
        amountOut = liquidity.mul(balanceOut) / _totalSupply;   // using balances ensures pro-rata distribution
        require(amountIn > 0 && amountOut > 0, 'YeSwap: INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(address(this), liquidity);
        TransferHelper.safeTransfer(_tokenIn, to, amountIn);
        TransferHelper.safeTransfer(_tokenOut, to, amountOut);
        balanceIn = IERC20(_tokenIn).balanceOf(address(this));
        balanceOut = IERC20(_tokenOut).balanceOf(address(this));

        _update(balanceIn, balanceOut, _reserveIn, _reserveOut, _blockTimestampLast);
        if (feeOn) kLast = uint(reserveIn).mul(reserveOut);     // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amountIn, amountOut, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amountOut, address to, bytes calldata data) external lock override {
        require(amountOut > 0, 'YeSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast) = (reserveIn, reserveOut, blockTimestampLast);   // gas savings
        require(amountOut < _reserveOut, 'YeSwap: INSUFFICIENT_LIQUIDITY');

        uint balanceIn;
        uint balanceOut;
        {   // scope for {_tokenIn, _tokenOut}, avoids stack too deep errors
            (address _tokenIn, address _tokenOut) = (tokenIn, tokenOut);            // gas savings
            require(to != _tokenIn && to != _tokenOut, 'YeSwap: INVALID_TO');
            TransferHelper.safeTransfer(_tokenOut, to, amountOut); 
            if (data.length > 0) IYeSwapCallee(to).YeSwapCall(msg.sender, amountOut, data);
            balanceIn = IERC20(_tokenIn).balanceOf(address(this));
            balanceOut = IERC20(_tokenOut).balanceOf(address(this));
        }

        uint amountInTokenIn = balanceIn > _reserveIn ? balanceIn - _reserveIn : 0;
        uint amountInTokenOut = balanceOut > (_reserveOut - amountOut) 
                                           ? balanceOut - (_reserveOut - amountOut) : 0;  // to support Flash Swap
        require(amountInTokenIn > 0 || amountInTokenOut > 0, 'YeSwap: INSUFFICIENT_INPUT_AMOUNT');

        {   // avoid stack too deep errors
            uint balanceOutAdjusted = balanceOut.mul(1000).sub(amountInTokenOut.mul(3));      // Fee for Flash Swap: 0.3% from tokenOut
            require(balanceIn.mul(balanceOutAdjusted) >= uint(_reserveIn).mul(_reserveOut).mul(1000), 'YeSwap: K');
        }
        _update(balanceIn, balanceOut, _reserveIn, _reserveOut, _blockTimestampLast);
        emit Swap(msg.sender, amountInTokenIn, amountInTokenOut, amountOut, to);
    }

    // force balances to match reserves
    function skim(address to) external lock override {
        (address _tokenIn, address _tokenOut) = (tokenIn, tokenOut);         // gas savings
        TransferHelper.safeTransfer(_tokenIn, to, IERC20(_tokenIn).balanceOf(address(this)).sub(reserveIn));
        TransferHelper.safeTransfer(_tokenOut, to, IERC20(_tokenOut).balanceOf(address(this)).sub(reserveOut));
    }

    // force reserves to match balances
    function sync() external lock override {
        _update(IERC20(tokenIn).balanceOf(address(this)), IERC20(tokenOut).balanceOf(address(this)), reserveIn, reserveOut, blockTimestampLast);
    }
}