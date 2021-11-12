/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

pragma solidity =0.6.6;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface Router{
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external;
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to, uint256 deadline) external;
}

contract Lp{
    using SafeMath for uint256;
    address public _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    bool public _open = true;
    address public token;
    function liquidity() public{
        uint256 amount = IERC20(token).balanceOf(address(this));
        uint256 wbnbAmount = IERC20(_wbnb).balanceOf(address(this));
        require(amount > 100e18,"Insufficient");
        uint256 _fee = IERC20(token).balanceOf(address(this)).mul(1).div(100);
        amount = amount.sub(_fee);
        IERC20(token).transfer(msg.sender,_fee);
        if(wbnbAmount>=1e16){
            Router(_router).addLiquidity(token, _wbnb, amount, wbnbAmount, 0, 0, address(this), block.timestamp+100);
        }else{
            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = address(_wbnb);
            Router(_router).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp+100);
        }
    }
    
    function liquidity2() public{
        uint256 amount = IERC20(token).balanceOf(address(this));
        uint256 wbnbAmount = IERC20(_wbnb).balanceOf(address(this));
        require(amount > 100e18,"Insufficient");
        uint256 _fee = IERC20(token).balanceOf(address(this)).mul(1).div(100);
        amount = amount.sub(_fee);
        IERC20(token).transfer(msg.sender,_fee);
        if(wbnbAmount>1e16){
            Router(_router).addLiquidity(token, _wbnb, amount, wbnbAmount, 0, 0, address(this), block.timestamp+100);
        }else{
            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = address(_wbnb);
            Router(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp+100);
        }
    }
    
    function fee() public view returns(uint256){
        uint256 _fee = IERC20(token).balanceOf(address(this)).mul(1).div(100);
        return _fee;
    }
    function approve() public {
        IERC20(token).approve(_router,1000000000000e18);
        IERC20(_wbnb).approve(_router,1000000000000e18);
    }
    
    function setTokenAddress(address _token) public {
        require(_open==true,"error");
        token = _token;
        _open = false;
    }
}