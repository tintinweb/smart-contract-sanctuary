pragma solidity >=0.8.2;
// SPDX-License-Identifier: Unlicensed

import "./Initializable.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MyRouter is Initializable {
    using SafeMath for uint256;
    
    address public _owner;
    address public _token;
    address public _minusTaxSystem;

    uint private ADD_LIQ_MODE;

    uint private LAST_SUPPLY;
    
    fallback() external payable {}
    receive() external payable {}
    
    function initialize() public initializer {
        _owner = msg.sender;
        // _token = token_;
        _minusTaxSystem = address(0x05121c1D1717C9339395Fe940A4aAD0Bb7849fB7);
        ADD_LIQ_MODE = 1;
    }
    
    function isAddLiqMode() external view returns (uint) {
        return ADD_LIQ_MODE;
    }
    
    function getLastSupply() external view returns (uint) {
        return LAST_SUPPLY;
    }
    
    function setToken(address token_) external {
        _token = token_;
    }
    
    function setMinusTaxSystem(address minusTaxSystem_) external {
        _minusTaxSystem = minusTaxSystem_;
    }
    
    function getVariables() internal view returns (uint, address, address, address[] memory) {
        uint denominator = 10000;
        address router = address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        
        address[] memory path = new address[](2);
        
        return (
            denominator,
            router,
            _token,
            path
            );
    }
    
    
    function getTokenReady(uint amount) internal {
        // move user's token to this contract to run the process
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
    }
    
    
    function addLiquidityBNB(uint addLiqTokenAmount, uint slippage) external payable {
        ADD_LIQ_MODE = 2;
        
        (uint denominator, address router, address token, ) = getVariables();
        
        uint amountTokenMin;
        uint amountETHMin;
        {
            
            uint amountToken = addLiqTokenAmount;
            uint amountETH = msg.value;
            amountTokenMin = amountToken.sub(amountToken.mul(slippage).div(denominator));
            amountETHMin = amountETH.sub(amountETH.mul(slippage).div(denominator));
        }
        
        getTokenReady(addLiqTokenAmount);
        
        uint usedToken = IERC20(token).balanceOf(address(this));
        uint usedETH = address(this).balance;
    
        // use official router API to skip verify
        IUniswapV2Router02(router).addLiquidityETH{value: msg.value}(
            token,
            addLiqTokenAmount,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            block.timestamp
            );
        
        // return leftovers
        usedToken = usedToken.sub(IERC20(token).balanceOf(address(this)));
        if (usedToken < addLiqTokenAmount) {
            IERC20(token).transfer(msg.sender, addLiqTokenAmount.sub(usedToken));
        }
        usedETH = usedETH.sub(address(this).balance);
        if (usedETH < msg.value) {
            payable(msg.sender).transfer(msg.value.sub(usedETH));
        }
        
        // update LP token total
        address _uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router02(router).factory())
        .getPair(token, IUniswapV2Router02(router).WETH());
        LAST_SUPPLY = IERC20(_uniswapV2Pair).totalSupply();
        
        ADD_LIQ_MODE = 1;
    }
    
}