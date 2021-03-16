/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity ^0.7.0;

interface IUniswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
        
    function WETH() external pure returns (address);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract JediSwap {
    IUniswap uniswap;
    address public owner;

    constructor(address _uniswap) {
        uniswap = IUniswap(_uniswap); 
        owner = msg.sender;
        IERC20(uniswap.WETH()).approve(address(uniswap), uint256(-1));
    }

    function swapExactTokensForTokens(
        address[] memory path, 
        uint amountIn, 
        uint amountOutMin,
        uint approve) //0, 1, 2, 3
        external
    {
        require(owner == msg.sender, "You are not authorized");
        
        /*address WETH_token = uniswap.WETH();
        address[] memory path = new address[](3);
        path[0] = token;
        path[1] = token2;
        path[2] = WETH_token;*/
        
        /*if (approve > 0) { //1
            IERC20(path[0]).approve(address(uniswap), uint256(-1));
        }*/
        if (approve > 0) { //1
            IERC20(path[1]).approve(address(uniswap), uint256(-1));
        }
        if (approve > 1) { //2
            IERC20(path[2]).approve(address(uniswap), uint256(-1));
        }
        
        //uint deadline = block.timestamp + 5;
        
        uniswap.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this), 
            block.timestamp);
    }
    
    //--------------------------------------------------------
    // ETH
    //--------------------------------------------------------
    function depositETH() public payable {

    }
    
    function withdrawETH(uint withdrawAmount) public {
        require(owner == msg.sender, "You are not authorized");
        msg.sender.transfer(withdrawAmount);
    }
    //--------------------------------------------------------
    // Token ERC20
    //--------------------------------------------------------
    /*function depositToken(
        address token,
        uint amount)
        external {
        IERC20(token).approve(msg.sender, amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }*/
        
    function withdrawToken(
        address token, //0x1f9840a85d5af5bf1d1762f925bdaddc4201f984
        uint amount) //1000000000000000
        external {
        require(owner == msg.sender, "You are not authorized");
        IERC20(token).transferFrom(address(this), msg.sender, amount);
    }
    
    function balance(
        address token) 
        external 
        view 
        returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }
    //--------------------------------------------------------
}