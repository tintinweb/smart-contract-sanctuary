/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.4.18;

interface ERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface UniswapV2Pair {
    function token0() external returns(address _token0);
    function token1() external returns(address _token1);
    function mint(address to) external returns (uint liquidity);
    function sync() external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

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

contract UniOAP {
    using SafeMath for uint;
    address owner;
    mapping(address => bool) public authorized;
    event Data(uint256 value,uint256 value2,uint256 value3);

    
     modifier onlyAuth() {
        require(authorized[msg.sender] == true, "Sender must be authorized.");
        _;
    }
    
    constructor() 
        public 
    {
        authorized[msg.sender] = true;
    }

    function() public payable {
       revert("Invalid Transaction");
    }
    
    function swap(address _uniPair, bool reverse) onlyAuth external{

        UniswapV2Pair pair = UniswapV2Pair(_uniPair);

        ERC20 token0 = ERC20(pair.token0());
        ERC20 token1 = ERC20(pair.token1());
        
        (uint reserveInput, uint reserveOutput,) = pair.getReserves();
        uint amountInput;
        uint amountOutput;
        uint amount0Out;
        uint amount1Out;
        
        if(!reverse){
        token0.transfer(_uniPair, token0.balanceOf(address(this)));
        pair.sync();
        amountInput = token0.balanceOf(address(_uniPair)).sub(reserveInput);
        emit Data(amountInput, reserveInput, reserveOutput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
        (amount0Out,amount1Out) = (uint(0), amountOutput);
        pair.swap(
            amount0Out,
            amount1Out,
            msg.sender,
            new bytes(0)
        );
        }
        else{
        token1.transfer(_uniPair, token1.balanceOf(address(this)));
        amountInput = token1.balanceOf(address(_uniPair)).sub(reserveOutput);
        emit Data(amountInput, reserveInput, reserveOutput);
        amountOutput = getAmountOut(amountInput, reserveOutput, reserveInput );
        (amount0Out, amount1Out) = (amountOutput, uint(0));
        pair.swap(
            amount0Out,
            amount1Out,
            msg.sender,
            new bytes(0)
        );
        pair.sync();
        }

    }
    
    function swap2(address _uniPair, bool reverse) onlyAuth external{

        UniswapV2Pair pair = UniswapV2Pair(_uniPair);

        ERC20 token0 = ERC20(pair.token0());
        ERC20 token1 = ERC20(pair.token1());
        
        (uint reserveInput, uint reserveOutput,) = pair.getReserves();
        uint amountInput;
        uint amountOutput;
        uint amount0Out;
        uint amount1Out;
        
        if(!reverse){
        token0.transfer(_uniPair, token0.balanceOf(address(this)));
        pair.sync();
        amountInput = token0.balanceOf(address(_uniPair)).sub(reserveInput);
        emit Data(amountInput, reserveInput, reserveOutput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
        (amount0Out,amount1Out) = (uint(0), amountOutput);
        pair.swap(
            amount0Out,
            amount1Out,
            msg.sender,
            new bytes(0)
        );
        }
        else{
        token1.transfer(_uniPair, token1.balanceOf(address(this)));
        amountInput = token1.balanceOf(address(_uniPair)).sub(reserveOutput);
        emit Data(amountInput, reserveInput, reserveOutput);
        amountOutput = getAmountOut(amountInput, reserveOutput, reserveInput );
        (amount0Out,amount1Out) = (uint(0), amountOutput);
        pair.swap(
            amount0Out,
            amount1Out,
            msg.sender,
            new bytes(0)
        );
        pair.sync();
        }

    }
    
     function swap3(address _uniPair, bool reverse) onlyAuth external{

        UniswapV2Pair pair = UniswapV2Pair(_uniPair);

        ERC20 token0 = ERC20(pair.token0());
        ERC20 token1 = ERC20(pair.token1());
        
        (uint reserveInput, uint reserveOutput,) = pair.getReserves();
        uint amountInput;
        uint amountOutput;
        uint amount0Out;
        uint amount1Out;
        
        if(!reverse){
        token0.transfer(_uniPair, token0.balanceOf(address(this)));
        pair.sync();
        amountInput = token0.balanceOf(address(_uniPair)).sub(reserveInput);
        emit Data(amountInput, reserveInput, reserveOutput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
        (amount0Out,amount1Out) = (uint(0), amountOutput);
        pair.swap(
            amount0Out,
            amount1Out,
            msg.sender,
            new bytes(0)
        );
        }
        else{
        token1.transfer(_uniPair, token1.balanceOf(address(this)));
        pair.sync();
        amountInput = token1.balanceOf(address(_uniPair)).sub(reserveOutput);
        emit Data(amountInput, reserveInput, reserveOutput);
        amountOutput = getAmountOut(amountInput, reserveOutput, reserveInput );
        (amount0Out, amount1Out) = (amountOutput, uint(0));
        pair.swap(
            amount0Out,
            amount1Out,
            msg.sender,
            new bytes(0)
        );
        }

    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'ALA: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ALA: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    
    function getAmountOut2(uint amountIn, uint reserveIn, uint reserveOut) external returns (uint amountOut) {
        require(amountIn > 0, 'ALA: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ALA: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    
    function mintProxy(address _uniPair) onlyAuth external{

        UniswapV2Pair pair = UniswapV2Pair(_uniPair);

        ERC20 tokenA = ERC20(pair.token0() );
        ERC20 tokenB = ERC20(pair.token1() );
        
        tokenA.transfer(_uniPair, tokenA.balanceOf(address(this)));
        tokenB.transfer(_uniPair, tokenB.balanceOf(address(this)));
        
        pair.mint(msg.sender);
        
    }
    
     function failSafe(address _toUser, address _token, uint _amount) public returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        if(_token == address(0))
        (_toUser).transfer(_amount);
        else ERC20(_token).transfer(_toUser, ERC20(_token).balanceOf(address(this)));
        return true;
    }
    
     function claimTokens(address _toUser, address _token) public {
        if (_token == address(0)) {
            address(uint160(_toUser)).transfer(address(this).balance);
            return;
        }
        ERC20 _erc20token = ERC20(_token);
        uint256 balance = _erc20token.balanceOf(address(this));
        _erc20token.transfer(_toUser, balance);
    }
    
    function addAuth(address _newowner, bool status) onlyAuth public  {
       authorized[_newowner] = status;
    }
}