/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.8.6;

interface ITribalChief {
  function getTotalStakedInPool(uint256 pid, address user) external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint);
}

contract StakedFeiTribeVoting {

  IUniswapV2Pair public FEI_TRIBE_LP = IUniswapV2Pair(address(0x9928e4046d7c6513326cCeA028cD3e7a91c7590A));
  ITribalChief public TRIBAL_CHIEF = ITribalChief(address(0x9e1076cC0d19F9B0b8019F384B0a29E48Ee46f7f));
  uint256 public PID = 0;

  function balanceOf(address who) public view returns (uint256) {
    uint256 tokenBal = TRIBAL_CHIEF.getTotalStakedInPool(PID, who);
    (,uint256 totalTribe,) = FEI_TRIBE_LP.getReserves();
    uint256 totalLP = FEI_TRIBE_LP.totalSupply();

    return totalTribe * tokenBal / totalLP;
  }  
}