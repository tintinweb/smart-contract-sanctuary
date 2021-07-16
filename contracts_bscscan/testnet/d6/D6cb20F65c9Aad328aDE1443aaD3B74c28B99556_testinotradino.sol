/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

contract testinotradino {
    
  IUniswapV2Router02 private PANCAKE_ROUTER = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
  uint internal timeout = 600;
    
     function CompraTokenFees(address _token, uint _slippage) public payable {
        uint deadline = block.timestamp + timeout;
        PANCAKE_ROUTER.swapExactETHForTokens{ value: msg.value }(_slippage, GeneraPath(_token,true), msg.sender, deadline);
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
  }
  function GeneraPath(address _token, bool is_buy) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    if(is_buy) {
        path[0] = PANCAKE_ROUTER.WETH();
        path[1] = _token;
    } else {
        path[0] = _token;
        path[1] = PANCAKE_ROUTER.WETH();
    }
    
    return path;
  }
  receive() payable external {}
}


abstract contract BSC_TOKEN {
    function approve(address spender, uint value) virtual external returns (bool);
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
    function transferFrom(address from, address to, uint value) virtual external returns (bool);
    function allowance(address owner, address spender) virtual external view returns (uint256);
}


interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}