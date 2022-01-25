/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
}

interface IUniswapV2ERC20 {
  function totalSupply() external view returns (uint256);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function token0() external view returns (address);

  function token1() external view returns (address);
}

contract OrkanVBTCCalculator{

    using SafeMath for uint256;

    address immutable public ORKAN;

    constructor( address _ORKAN ){
      ORKAN = _ORKAN;
    }
    
    function valuation(address _token, uint256 _amount) external view returns (uint256 value_){

      address token0 = IUniswapV2Pair(_token).token0();

      (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_token).getReserves();

      uint256 totalSupply = IUniswapV2Pair(_token).totalSupply();
      uint256 reserve = token0 == ORKAN ? reserve1 : reserve0;

      return _amount.mul(reserve).div(totalSupply);

    }

  }