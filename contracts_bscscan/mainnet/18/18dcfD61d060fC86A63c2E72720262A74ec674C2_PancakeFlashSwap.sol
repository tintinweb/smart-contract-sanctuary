/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// File: Pancake.sol

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IPancakeCallee {
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IPancakeFactory {
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

pragma solidity >=0.5.0;

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
// File: PancakeFlashSwap.sol

pragma solidity >=0.5.0;


contract PancakeFlashSwap is IPancakeCallee{
    
    address public factory;
    address public WETH;
    address public owner;
    
    /**
     * On BSC,
     * _factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
     * _weth = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
     */
    
    constructor(address _factory, address _weth) public{
        
        factory = _factory;
        WETH = _weth;
        owner = msg.sender;
    }
    
    function balance(address _token) public view returns(uint256){
        
        return IERC20(_token).balanceOf(address(this));
    }
    
    function setFactory(address _address) public {
        require(msg.sender == owner, "Unauthorised");
        factory = _address;
    }
    
    function setWeth(address _address) public{
        require(msg.sender == _address, "Unauthorised");
        WETH = _address;
    }
    
    function withdraw(address _token) public{
        require(msg.sender == owner, "Not Authorised");
        
        IERC20(_token).transfer(owner, balance(_token));
    }
    
    function flashSwap(address _token, uint256 _amount) public{
        address pair = IPancakeFactory(factory).getPair(_token, WETH);
        require(pair != address(0), "Pair Not Found");
        
        address token0 = IPancakePair(pair).token0();
        address token1 = IPancakePair(pair).token1();
        
        uint256 amount0Out = _token == token0 ? _amount : 0;
        uint256 amount1Out = _token == token1 ? _amount : 0;
        
        bytes memory data = abi.encode(_token, _amount);
        
        IPancakePair(pair).swap(amount0Out, amount1Out, address(this), data);
        
    }
    
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external{
        
        address token0 = IPancakePair(msg.sender).token0();
        address token1 = IPancakePair(msg.sender).token1();
        
        address pair = IPancakeFactory(factory).getPair(token0, token1);
        
        require(msg.sender == pair, "Not Authorised Callee");
        require(sender == address(this), "Incorrect Sender");
        
        (address _token, uint256 _amount) = abi.decode(data, (address, uint256));
        
        uint256 fee = ((_amount * 3)/997) + 1;
        uint256 amountToRepay = _amount + fee;
        
        IERC20(_token).transfer(pair, amountToRepay);
    }
}