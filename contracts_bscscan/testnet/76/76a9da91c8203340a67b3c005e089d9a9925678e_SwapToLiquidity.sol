/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

pragma solidity >=0.6.12;

interface IUniswapV2Router01 {


	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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


}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
	

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable;

}
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
contract Ownable 
{    
  // Variable that maintains 
  // owner address
  address private _owner;
  
  // Sets the original owner of 
  // contract when it is deployed
  constructor()
  {
    _owner = msg.sender;
  }
  
  // Publicly exposes who is the
  // owner of this contract
  function owner() public view returns(address) 
  {
    return _owner;
  }
  
  // onlyOwner modifier that validates only 
  // if caller of function is contract owner, 
  // otherwise not
  modifier onlyOwner() 
  {
    require(isOwner(),
    "Function accessible only by the owner !!");
    _;
  }
  
  // function for owners to verify their ownership. 
  // Returns true for owners otherwise false
  function isOwner() public view returns(bool) 
  {
    return msg.sender == _owner;
  }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}
  
contract SwapToLiquidity is Ownable {

	uint256 MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
	//event ammountsOut(uint amount1, uint amount2);
	address router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        receive() external payable {
            // React to receiving ether
        }
    function SwapToLP (address[] calldata path, address to) public payable{
        
                    _uniswapV2Router.swapExactETHForTokens{value: msg.value/2}(0, path, address(this), block.timestamp+15000);
					//approves
					TransferHelper.safeApprove(path[path.length-1], router, MAX_INT);
					(, uint amountETH, ) = _uniswapV2Router.addLiquidityETH{value: msg.value/2}(path[path.length-1], IERC20(path[path.length-1]).balanceOf(address(this)), 0,  0, to, block.timestamp+15000);
                    TransferHelper.safeTransferETH(to, msg.value/2 - amountETH);
					//emit ammountsOut (amounts[0], amounts[path.length-1]);
    }

    function withdrawToken(address _tokenContract) onlyOwner external {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner(), tokenContract.balanceOf(address(this)));
    }
    function withdraw() onlyOwner  public {
    TransferHelper.safeTransferETH(owner(), address(this).balance);
    }
    function ChangeRouter(address newRouter) onlyOwner  public{
        router = newRouter;
    }
      function Router() public view returns(address) 
    {
        return router;
    }
    
}