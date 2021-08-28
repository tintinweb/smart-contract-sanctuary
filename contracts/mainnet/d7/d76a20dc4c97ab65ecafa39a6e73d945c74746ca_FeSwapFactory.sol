/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

// import './interfaces/IFeSwapFactory.sol';

interface IFeSwapFactory {
    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAAB, address pairABB, uint);

    function feeTo() external view returns (address);
    function getFeeInfo() external view returns (address, uint256);
    function factoryAdmin() external view returns (address);
    function routerFeSwap() external view returns (address);  
    function rateTriggerFactory() external view returns (uint64);  
    function rateCapArbitrage() external view returns (uint64);     
    function rateProfitShare() external view returns (uint64); 

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createUpdatePair(address tokenA, address tokenB, address pairOwner, uint256 rateTrigger) external returns (address pairAAB,address pairABB);

    function setFeeTo(address) external;
    function setFactoryAdmin(address) external;
    function setRouterFeSwap(address) external;
    function configFactory(uint64, uint64, uint64) external;
    function managePair(address, address, address, address) external;
}

// import './IFeSwapERC20.sol';

interface IFeSwapERC20 {
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

// import './interfaces/IFeSwapPair.sol';

interface IFeSwapPair is IFeSwapERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount1Out, address indexed to );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function pairOwner() external view returns (address);
    function tokenIn() external view returns (address);
    function tokenOut() external view returns (address);
    function getReserves() external view returns ( uint112 _reserveIn, uint112 _reserveOut, 
                                                          uint32 _blockTimestampLast, uint _rateTriggerArbitrage);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function rateTriggerArbitrage() external view returns (uint);
    
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amountOut, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, address, address, uint) external;
    function setOwner(address _pairOwner) external;
    function adjusArbitragetRate(uint newRate) external;
}

// import './libraries/SafeMath.sol';

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

// import './FeSwapERC20.sol';

contract FeSwapERC20 is IFeSwapERC20 {
    using SafeMath for uint;

    string public constant override name = 'FeSwap';
    string public constant override symbol = 'FESP';
    uint8 public constant override decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
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
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) override external {
        require(deadline >= block.timestamp, 'FeSwap: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'FeSwap: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// import './libraries/Math.sol';

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


// import './libraries/UQ112x112.sol';

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


// import './interfaces/IERC20.sol';

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

// import './interfaces/IFeSwapCallee.sol';

interface IFeSwapCallee {
    function FeSwapCall(address sender, uint amountOut, bytes calldata data) external;
}

// import './FeSwapPair.sol';

contract FeSwapPair is IFeSwapPair, FeSwapERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override factory;
    address public override pairOwner;
    address public override tokenIn;
    address public override tokenOut;

    uint112 private reserveIn;              // uses single storage slot, accessible via getReserves
    uint112 private reserveOut;             // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast;     // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast;             // reserveIn * reserveOut, as of immediately after the most recent liquidity event

    uint public override rateTriggerArbitrage;

    uint private unlocked = 0x5A;
    modifier lock() {
        require(unlocked == 0x5A, 'FeSwap: LOCKED');
        unlocked = 0x69;
        _;
        unlocked = 0x5A;
    }
  
    function getReserves() public view override returns ( uint112 _reserveIn, uint112 _reserveOut, 
                                                          uint32 _blockTimestampLast, uint _rateTriggerArbitrage) {
        _reserveIn = reserveIn;
        _reserveOut = reserveOut;
        _blockTimestampLast = blockTimestampLast;
        _rateTriggerArbitrage = rateTriggerArbitrage;

    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FeSwap: TRANSFER_FAILED');
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
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _tokenIn, address _tokenOut, address _pairOwner, address router, uint rateTrigger) external override {
        require(msg.sender == factory, 'FeSwap: FORBIDDEN');
        tokenIn     = _tokenIn;
        tokenOut    = _tokenOut;
        pairOwner   = _pairOwner;
        if(rateTrigger != 0)  rateTriggerArbitrage = rateTrigger;
        IERC20(tokenIn).approve(router, uint(-1));      // Approve Rourter to transfer out tokenIn for auto-arbitrage 
    }

    function setOwner(address _pairOwner) external override {
        require(msg.sender == factory, 'FeSwap: FORBIDDEN');
        pairOwner = _pairOwner;
    }

    function adjusArbitragetRate(uint newRate) external override {
        require(msg.sender == factory, 'FeSwap: FORBIDDEN');
        rateTriggerArbitrage = newRate;
    }  

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balanceIn, uint balanceOut, uint112 _reserveIn, uint112 _reserveOut) private {
        require(balanceIn <= uint112(-1) && balanceOut <= uint112(-1), 'FeSwap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserveIn != 0 && _reserveOut != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserveOut).uqdiv(_reserveIn)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserveIn).uqdiv(_reserveOut)) * timeElapsed;
        }
        reserveIn = uint112(balanceIn);
        reserveOut = uint112(balanceOut);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserveIn, reserveOut);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserveIn, uint112 _reserveOut) private returns (bool feeOn) {
        (address feeTo, uint rateProfitShare) = IFeSwapFactory(factory).getFeeInfo();
        feeOn = (feeTo != address(0)) || (pairOwner != address(0));
        uint _kLast = kLast;            // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserveIn).mul(_reserveOut));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast.add(20)) {     // ignore swap dust increase, select 20 randomly 
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(6);
                    uint denominator = rootK.mul(rateProfitShare).add(rootKLast);
                    uint liquidityCreator = numerator / (denominator.mul(10));
                    if((liquidityCreator > 0) && (pairOwner != address(0))) {
                        _mint(pairOwner, liquidityCreator);
                    } 
                    uint liquidityFeSwap = numerator / (denominator.mul(15));
                    if((liquidityFeSwap > 0)  && (feeTo != address(0))) {
                        _mint(feeTo, liquidityFeSwap);
                    } 
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }            
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserveIn, uint112 _reserveOut, ,) = getReserves(); // gas savings
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
        require(liquidity > 0, 'FeSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balanceIn, balanceOut, _reserveIn, _reserveOut);
        if (feeOn) kLast = uint(reserveIn).mul(reserveOut);                    // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amountTokenIn, amountTokenOut);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock override returns (uint amountIn, uint amountOut) {
        (uint112 _reserveIn, uint112 _reserveOut, ,) = getReserves();     // gas savings
        (address _tokenIn, address _tokenOut) = (tokenIn, tokenOut);    // gas savings
        uint balanceIn = IERC20(_tokenIn).balanceOf(address(this));
        uint balanceOut = IERC20(_tokenOut).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];                      // liquidity to remove

        bool feeOn = _mintFee(_reserveIn, _reserveOut);
        uint _totalSupply = totalSupply;                        // gas savings, must be defined here since totalSupply can update in _mintFee
        amountIn = liquidity.mul(balanceIn) / _totalSupply;     // using balances ensures pro-rata distribution
        amountOut = liquidity.mul(balanceOut) / _totalSupply;   // using balances ensures pro-rata distribution
        require(amountIn > 0 && amountOut > 0, 'FeSwap: INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(address(this), liquidity);
        _safeTransfer(_tokenIn, to, amountIn);
        _safeTransfer(_tokenOut, to, amountOut);
        balanceIn = IERC20(_tokenIn).balanceOf(address(this));
        balanceOut = IERC20(_tokenOut).balanceOf(address(this));

        _update(balanceIn, balanceOut, _reserveIn, _reserveOut);
        if (feeOn) kLast = uint(reserveIn).mul(reserveOut);     // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amountIn, amountOut, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amountOut, address to, bytes calldata data) external lock override {
        require(amountOut > 0, 'FeSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserveIn, uint112 _reserveOut) = (reserveIn, reserveOut);        // gas savings
        require(amountOut < _reserveOut, 'FeSwap: INSUFFICIENT_LIQUIDITY');

        uint balanceIn;
        uint balanceOut;
        {   // scope for {_tokenIn, _tokenOut}, avoids stack too deep errors
            (address _tokenIn, address _tokenOut) = (tokenIn, tokenOut);            // gas savings
            require(to != _tokenIn && to != _tokenOut, 'FeSwap: INVALID_TO');
            _safeTransfer(_tokenOut, to, amountOut); 
            if (data.length > 0) IFeSwapCallee(to).FeSwapCall(msg.sender, amountOut, data);
            balanceIn = IERC20(_tokenIn).balanceOf(address(this));
            balanceOut = IERC20(_tokenOut).balanceOf(address(this));
        }

        uint amountInTokenIn = balanceIn > _reserveIn ? balanceIn - _reserveIn : 0;
        uint amountInTokenOut = balanceOut > (_reserveOut - amountOut) 
                                           ? balanceOut - (_reserveOut - amountOut) : 0;  // to support Flash Swap
        require(amountInTokenIn > 0 || amountInTokenOut > 0, 'FeSwap: INSUFFICIENT_INPUT_AMOUNT');

        uint balanceOutAdjusted = balanceOut.mul(1000).sub(amountInTokenOut.mul(3));      // Fee for Flash Swap: 0.3% from tokenOut
        require(balanceIn.mul(balanceOutAdjusted) >= uint(_reserveIn).mul(_reserveOut).mul(1000), 'FeSwap: K');

        _update(balanceIn, balanceOut, _reserveIn, _reserveOut);
        emit Swap(msg.sender, amountInTokenIn, amountInTokenOut, amountOut, to);
    }

    // force balances to match reserves
    function skim(address to) external lock override {
        address _tokenIn = tokenIn;     // gas savings
        address _tokenOut = tokenOut;   // gas savings
        _safeTransfer(_tokenIn, to, IERC20(_tokenIn).balanceOf(address(this)).sub(reserveIn));
        _safeTransfer(_tokenOut, to, IERC20(_tokenOut).balanceOf(address(this)).sub(reserveOut));
    }

    // force reserves to match balances
    function sync() external lock override {
        _update(IERC20(tokenIn).balanceOf(address(this)), IERC20(tokenOut).balanceOf(address(this)), reserveIn, reserveOut);
    }
}

// FeSwapFactory.sol

contract FeSwapFactory is IFeSwapFactory {
    uint64 public constant RATE_TRIGGER_FACTORY         = 10;       //  price difference be 1%
    uint64 public constant RATE_CAP_TRIGGER_ARBITRAGE   = 50;       //  price difference < 5%
    uint64 public constant RATE_PROFIT_SHARE            = 11;       //  Feswap and Pair owner share 1/12 of the swap profit, 11 means 1/12

    address public override factoryAdmin;
    address public override feeTo;
    address public override routerFeSwap;
    uint64 public override rateTriggerFactory;
    uint64 public override rateCapArbitrage;
    uint64 public override rateProfitShare;                        // 1/X => rateProfitShare = (X-1)

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAAB, address pairABB, uint allPairsLength);
    event PairOwnerChanged(address indexed pairAAB, address indexed pairABB, address oldOwner, address newOwner);

    constructor(address _factoryAdmin) public {                     //factoryAdmin will be set to TimeLock after Feswap works normally
        factoryAdmin        = _factoryAdmin;
        rateTriggerFactory  = RATE_TRIGGER_FACTORY;
        rateCapArbitrage    = RATE_CAP_TRIGGER_ARBITRAGE;
        rateProfitShare     = RATE_PROFIT_SHARE;
     }

    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    
    function getFeeInfo() external view override returns (address _feeTo, uint256 _rateProfitShare) {
        return (feeTo, rateProfitShare);
    }

    function createUpdatePair(address tokenA, address tokenB, address pairOwner, uint256 rateTrigger) external override returns (address pairAAB, address pairABB ) {
        require(tokenA != tokenB, 'FeSwap: IDENTICAL_ADDRESSES');
        // pairOwner allowed to zero to discard the profit
        require(tokenA != address(0) && tokenB != address(0) && routerFeSwap != address(0) , 'FeSwap: ZERO_ADDRESS');
        require((msg.sender == factoryAdmin) || (msg.sender == routerFeSwap) , 'FeSwap: FORBIDDEN');
        require(rateTrigger <= rateCapArbitrage, 'FeSwap: GAP TOO MORE');

        pairAAB = getPair[tokenA][tokenB];
        if(pairAAB != address(0)) {
            pairABB = getPair[tokenB][tokenA];
            address oldOwner = IFeSwapPair(pairAAB).pairOwner();
            if(oldOwner!=pairOwner) {
                IFeSwapPair(pairAAB).setOwner(pairOwner);           // Owner Security must be checked by Router
                IFeSwapPair(pairABB).setOwner(pairOwner);
                emit PairOwnerChanged(pairAAB, pairABB, oldOwner, pairOwner);
            }
            if(rateTrigger!=0)
            {
                rateTrigger = rateTrigger*6 + rateTriggerFactory*4 + 10000;     // base is 10000
                IFeSwapPair(pairAAB).adjusArbitragetRate(rateTrigger); 
                IFeSwapPair(pairABB).adjusArbitragetRate(rateTrigger);                
            }
        } else {
            bytes memory bytecode = type(FeSwapPair).creationCode;
            bytes32 saltAAB = keccak256(abi.encodePacked(tokenA, tokenB));
            bytes32 saltABB = keccak256(abi.encodePacked(tokenB, tokenA));
            assembly {
                pairAAB := create2(0, add(bytecode, 32), mload(bytecode), saltAAB)
                pairABB := create2(0, add(bytecode, 32), mload(bytecode), saltABB)
            }

            if(rateTrigger == 0) rateTrigger = rateTriggerFactory;
            rateTrigger = rateTrigger*6 + rateTriggerFactory*4 + 10000;

            IFeSwapPair(pairAAB).initialize(tokenA, tokenB, pairOwner, routerFeSwap, rateTrigger);
            getPair[tokenA][tokenB] = pairAAB;
            allPairs.push(pairAAB);

            IFeSwapPair(pairABB).initialize(tokenB, tokenA, pairOwner, routerFeSwap, rateTrigger);
            getPair[tokenB][tokenA] = pairABB;
            allPairs.push(pairABB);

            emit PairCreated(tokenA, tokenB, pairAAB, pairABB, allPairs.length);
        }
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == factoryAdmin, 'FeSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFactoryAdmin(address _factoryAdmin) external override {
        require(msg.sender == factoryAdmin, 'FeSwap: FORBIDDEN');
        factoryAdmin = _factoryAdmin;
    }

    function setRouterFeSwap(address _routerFeSwap) external override {
        require(msg.sender == factoryAdmin, 'FeSwap: FORBIDDEN');
        routerFeSwap = _routerFeSwap;                                         // for Router Initiation
    }    

    function configFactory(uint64 newTriggerRate, uint64 newRateCap, uint64 newProfitShareRate) external override {
        require(msg.sender == factoryAdmin, 'FeSwap: FORBIDDEN');
        rateTriggerFactory  = newTriggerRate;
        rateCapArbitrage    = newRateCap;
        rateProfitShare     = newProfitShareRate;                   // 1/X => rateProfitShare = (X-1)
    } 
    
    // Function to update Router in case of emergence, factoryAdmin will be set to TimeLock after Feswap works normally
    // routerFeSwap must be secured and absolutely cannot be replaced uncontrolly.
    function managePair(address _tokenA, address _tokenB, address _pairOwner, address _routerFeSwap) external override {
        require(msg.sender == factoryAdmin, 'FeSwap: FORBIDDEN');
        address pairAAB = getPair[_tokenA][_tokenB];
        address pairABB = getPair[_tokenB][_tokenA];
        
        require(pairAAB != address(0), 'FeSwap: NO TOKEN PAIR');
        IFeSwapPair(pairAAB).initialize(_tokenA, _tokenB, _pairOwner, _routerFeSwap, 0);
        IFeSwapPair(pairABB).initialize(_tokenB, _tokenA, _pairOwner, _routerFeSwap, 0);
    } 
}