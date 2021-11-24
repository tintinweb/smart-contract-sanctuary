// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IPancakeRouter {
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
}
interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ATEST {

  IPancakeRouter private router;
  address private constant routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
  address public liquidityPool = 0x872a6bBb513a0AA390d25D0AA1A3011b389E4BB2;
  address public apesAddress = 0xaA9757e593690F4E4eD72298D5bF88491bb71a86;

  modifier onlyOwner() {
      require(owner() == msg.sender, "Ownable: caller is not the owner");
      _;
  }

  constructor() {
      router = IPancakeRouter(routerAddress);
  }

  function owner() public view virtual returns (address) {
      return 0x27F9523afe7e869a842A6942C72D91c34269B603;
  }

  function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) external payable onlyOwner returns (uint amountToken, uint amountETH, uint liquidity) {
      IERC20(apesAddress).approve(routerAddress, tokenAmount);
      (amountToken, amountETH, liquidity) = router.addLiquidityETH{value: ethAmount}(apesAddress, tokenAmount, 0, 0, owner(), block.timestamp);
  }

  function addLiquidity(uint256 _albatoken, uint256 _wethtoken) external payable onlyOwner {
      IERC20(address(this)).approve(routerAddress, _albatoken);
      IERC20(router.WETH()).approve(routerAddress, _wethtoken);
      router.addLiquidity(apesAddress, router.WETH(), _albatoken, _wethtoken, 0, 0, owner(), block.timestamp);
  }

  function wrapETH(uint _amount) external onlyOwner {
    IWETH(router.WETH()).deposit{value: _amount}();
  }

  function unwrapETH(uint _amount) external onlyOwner {
    IWETH(router.WETH()).withdraw(_amount);
  }

  receive() external payable virtual {}


}