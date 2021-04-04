/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.10;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IRouter{
    	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
	    external returns (uint[] memory amounts);

	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) 
	    external payable returns (uint[] memory amounts);

}

contract SwapDex {
	
	uint256 public DEADLINE = 2797763616;
	address private _owner;
	
	address public aRouter;
	address public constant aRouterUNI = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address public constant aRouterSUSHI = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
	address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Need Owner");
        _;
    }
    
    constructor () public{
        _owner = msg.sender;
        aRouter = aRouterUNI;
	}

	function () external payable{
	}

	function setRouter(bool chooseUNI) public onlyOwner returns (address){
	    if(chooseUNI) aRouter = aRouterUNI;
		    else aRouter = aRouterSUSHI;
		return aRouter;
	}
	
	function setApprove(address _token, address spender,uint256 amount) public onlyOwner{
		IERC20(_token).approve(spender, amount);	
	}

	function swapETHToToken(address to , address[] memory  path, address pair, uint256 pairValue) public payable onlyOwner{
		if(pairValue > (IERC20(WETH).balanceOf(pair)) ){
			IRouter(aRouter).swapExactETHForTokens.value(msg.value)(1, path , to, DEADLINE);
		}else{
			msg.sender.transfer(msg.value);
		}
	}
	
	function swapTokenToETH(address to, uint amountIn,address[] memory path, uint minOut) public onlyOwner{
		IRouter(aRouter).swapExactTokensForETH(amountIn ,minOut, path , to, DEADLINE);
	}
	
	function getETH(address payable _to, uint256 _amount) public onlyOwner{
		  _to.transfer(_amount);
	}
	
	function getToken(address _token, address _to, uint256 _amount) public onlyOwner returns (bool success){
		IERC20(_token).transfer(_to, _amount ) ;
		return true;
	}	
}