// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract ATEST {

  IPancakeRouter private router;
  address private constant routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;  // --- TEST ---
  address public liquidityPool = 0x5fc0CC9AdA81a929D29182b957725D1b5fC92D41;
  address public apesAddress = 0x4FD0b8cc6991dAC90cD246360b81cfd280a13807;

  constructor() {
      router = IPancakeRouter(routerAddress);
  }

  function getPrice1() public view returns(uint256) {
    address[] memory path;
    path[0] = router.WETH();
    path[1] = apesAddress;
    uint256[] memory amountsIn;
    amountsIn = router.getAmountsIn(1000000000, path);
    uint256 currentPrice = amountsIn[0];
    if ( currentPrice == 0 ) {
      currentPrice = 36 * 10**12;
    }
    return currentPrice;
  }

  function getPrice2() public view returns(uint[] memory amounts) {
    address[] memory path;
    path[0] = router.WETH();
    path[1] = apesAddress;
    amounts = router.getAmountsIn(1000000000, path);
  }


}