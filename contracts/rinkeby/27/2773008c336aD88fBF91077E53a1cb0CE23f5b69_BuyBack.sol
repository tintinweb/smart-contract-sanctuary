/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.6.2;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BuyBack{
    
    IUniswap uniswap;
    
    constructor(address _uniswap) public {
        uniswap = IUniswap(_uniswap);
    }

    function swapExactETHForTokens(
        uint amountOut,
        address token,
        uint deadline
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            address(this),
            deadline
        
        );
    }   
    
     address payable internal constant burn = 0x0000000000000000000000000000000000000000;
     address payable internal constant rewardPool = 0x295f495f36fFed67eF7ce5e219F2cf471b594E5B;
    
     IERC20 public token = IERC20(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);
    
     function sendAndBurnToken(uint256 value) external payable {
	 token.transfer(burn, value/2);
     token.transfer(rewardPool, value/8);
  }
  
}