/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

// SPDX-License-Identifier: GPL-3.0

/*
*
* Code by Harshil Jain
* Email: - [email protected]
* Telegram: - @OreGaZembuTouchiSuru
* ----------------------------------
* Compiler Configurations: -
* 1) Solidity -> v0.8.4
* 2) Optimizations -> Yes (200)
* ----------------------------------
* Depolyed At -> 0x65C4a53dcC7c87024e6f91aEb39AC2d0B459F4df
* 
*/

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB, bytes32 initCodeHash) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                initCodeHash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB, bytes32 initCodeHash) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, initCodeHash)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path, bytes32 initCodeHash) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1], initCodeHash);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path, bytes32 initCodeHash) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i], initCodeHash);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
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

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function createPair(address tokenA, address tokenB) external returns (address pair);
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

abstract contract Authorization {
    
    mapping(address => bool) isOwner;
    mapping(address => bool) isAuthorized;
    address kamiSama = 0x8c7B31eF7f282330Fa705677c185d495356F8026;
    
    constructor() {
        isOwner[kamiSama] = true;
        isAuthorized[kamiSama] = true;
    }
    
    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Not allowed");
        _;
    }
    
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not allowed");
        _;
    }
    
    event changedAuthorization(address _address, bool authorization);
    event changedOwnership(address _address, bool _ownership);
    
    function setAuthorization(address _address, bool _authorize) onlyOwner() external {
        if (!isOwner[_address]) {
            isAuthorized[_address] = _authorize;
            emit changedAuthorization(_address, _authorize);
        }
    }
    
    function setOwnership(address _address, bool _permission) onlyOwner() public {
        if(_address != address(0) && _address != kamiSama) {
            isOwner[_address] = _permission;
            if(_permission) {
                isAuthorized[_address] = _permission;
            }
            emit changedOwnership(_address, _permission);
        }
    }
}


contract ArbitrageSmartContract is Authorization {
    using SafeMath for uint;
    
    struct DexInformation {
        uint dexIndex;
        string name;
        bytes32 initCodeHash;
        address routerAddress;
    }
    
    mapping(uint => DexInformation) allDexInformation;
    uint public dexCount = 0;

    uint constant deadline = 1 days;
    address token0;
    address token1;
    uint indexA;
    uint indexB;
    uint borrowAmount;
    IUniswapV2Pair pairOnExchangeA;
    address routerAddressOnExchangeB;
    uint256 profitAmount = 0;
    
    constructor() {
    }
    
    bool inArbitrage = false;
    
    modifier lockEntrace() {
        require(!inArbitrage, "Already In Arbitrage. Cannot Re-enter");
        inArbitrage = true;
        _;
        inArbitrage = false;
    }
    
    event ProfitGenerated(uint256 _amount);
    
    function startArbitrage(
        address _token0,
        address _token1,
        uint _amount0,
        uint _amount1,
        address _pairAddressOnExchangeA,
        uint256 _indexA,
        uint256 _indexB
    ) onlyAuthorized() lockEntrace() external {
        
        require(_indexA <= dexCount && _indexB <= dexCount && _indexA > 0 && _indexB > 0, "Invalid Index Values");
        require(
            _pairAddressOnExchangeA != address(0) && 
            allDexInformation[_indexA].routerAddress != address(0) && 
            allDexInformation[_indexB].routerAddress != address(0),
            "This pool or router does not exists"
        );
        require(_amount0 == 0 || _amount1 == 0, "One of the amounts has to be zero");
        
        borrowAmount = (_amount0 == 0) ? _amount1 : _amount0;
        require(borrowAmount != 0, "Cannot borrow 0 tokens");
        
        indexA = _indexA;
        indexB = _indexB;
        pairOnExchangeA = IUniswapV2Pair(_pairAddressOnExchangeA);
        routerAddressOnExchangeB = allDexInformation[_indexB].routerAddress;
        (token0, token1) = (pairOnExchangeA.token0() == _token0) ? (_token0, _token1) : (_token1, _token0);
        (uint amount0Out, uint amount1Out) = (pairOnExchangeA.token0() == _token0) ? (_amount0, _amount1) : (_amount1, _amount0);
        
        pairOnExchangeA.swap(
            amount0Out,
            amount1Out,
            address(this),
            bytes('not empty')
        );
        
        emit ProfitGenerated(profitAmount);
        profitAmount = 0;
    }
    
    function uniswapV2Call(
        address _sender, 
        uint _amount0, 
        uint _amount1, 
        bytes calldata _data
    ) external {
        require(msg.sender == address(pairOnExchangeA), "Unauthorized");
        require(_amount0 == borrowAmount || _amount1 == borrowAmount, "Invalid Out Amount");
        require(_amount0 == 0 || _amount1 == 0, "We never borrow two tokens at once");
        
        address[] memory path = new address[](2);
        address _token0 = IUniswapV2Pair(msg.sender).token0();
        address _token1 = IUniswapV2Pair(msg.sender).token1();
        (path[0], path[1]) = _amount0 == 0 ? (_token0, _token1) : (_token1, _token0);
        
        require(
            (path[0] == token0 && path[1] == token1) || (path[1] == token0 && path[0] == token1),
            "Token Addresses have to be same as original addresses"
        );
        
        uint amountRequired = UniswapV2Library.getAmountsIn(
            pairOnExchangeA.factory(),
            borrowAmount,
            path,
            allDexInformation[indexA].initCodeHash
        )[0];
        
        IERC20 token = IERC20(path[1]);
        token.approve(routerAddressOnExchangeB, borrowAmount);
        
        address temp = path[0];
        path[0] = path[1];
        path[1] = temp;
        
        uint amountReceived = IUniswapV2Router02(routerAddressOnExchangeB).swapExactTokensForTokens(
            borrowAmount,
            amountRequired,
            path,
            address(this),
            block.timestamp + deadline
        )[1];
        
        require(amountRequired > 0, "Invalid Required Amount");
        require(amountReceived > amountRequired, "Amount Received is Less Than Repay Amount");
        
        IERC20 otherToken = IERC20(path[1]);
        otherToken.transfer(msg.sender, amountRequired);
        profitAmount = amountReceived - amountRequired;
        otherToken.transfer(tx.origin, profitAmount);
    }
    
    function addNewDexInformation(string memory _name, address _routerAddress, bytes32 _initCodeHash) external onlyOwner() returns(uint256) {
        require(_routerAddress != address(0), "Invalid Input data...");
        dexCount += 1;
        
        DexInformation storage newDexInfo = allDexInformation[dexCount];
        newDexInfo.dexIndex = dexCount;
        newDexInfo.name = _name;
        newDexInfo.routerAddress = _routerAddress;
        newDexInfo.initCodeHash = _initCodeHash;
        allDexInformation[dexCount] = newDexInfo;
        
        return dexCount;
    }
    
    function editDexInformation(uint256 _index, string memory _name, address _routerAddress, bytes32 _initCodeHash) external onlyOwner() {
        require(_index > 0 && _index <= dexCount && _routerAddress != address(0), "Invalid Input data...");
        
        DexInformation storage newDexInfo = allDexInformation[_index];
        newDexInfo.dexIndex = dexCount;
        newDexInfo.name = _name;
        newDexInfo.routerAddress = _routerAddress;
        newDexInfo.initCodeHash = _initCodeHash;
        allDexInformation[_index] = newDexInfo;
    }
    
    function getDexInformation(uint256 _index) external view returns(DexInformation memory) {
        return allDexInformation[_index];
    }
    
    function getAllDexInformation() external view returns(DexInformation[] memory) {
        DexInformation[] memory availableDexs = new DexInformation[](dexCount);
        
        for (uint i = 1; i <= dexCount; i++) {
            availableDexs[i - 1] = allDexInformation[i];
        }
        
        return availableDexs;
    }
}