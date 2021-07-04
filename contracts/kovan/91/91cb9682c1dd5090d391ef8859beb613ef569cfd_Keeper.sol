/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity 0.6.10;


interface ERC20Like {
    function transfer(address to, uint qty) external;
    function approve(address spender, uint qty) external;
}

interface BAMMLike {
    function getSwapEthAmount(uint lusdQty) external view returns(uint ethAmount, uint feeEthAmount);
    function swap(uint lusdAmount, address payable dest) external payable returns(uint);
}

interface KyberLike {
    function getExpectedRate(address src, address dest, uint qty) external view returns(uint256);
    function trade(
        address src,
        uint256 srcAmount,
        address dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet
    ) external payable returns (uint256);
}


contract Keeper {
  function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
      (address lusd, address bamm, address kyber, uint ethQty) = abi.decode(checkData, (address,address,address,uint256));
      
      uint kyberRate = KyberLike(kyber).getExpectedRate(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, lusd, ethQty);
      uint kyberLusdQty = kyberRate * ethQty / 1e18;
      
      (uint bammQty, ) = BAMMLike(bamm).getSwapEthAmount(kyberLusdQty);
      
      upkeepNeeded = bammQty > ethQty * 101 / 100; // more than 1% arbitrage
      performData = checkData;
  }
  
  function performUpkeep(bytes calldata performData) external {
      (address lusd, address bamm, address kyber, uint ethQty) = abi.decode(performData, (address,address,address,uint256));
      
      uint ethBalanceBefore = address(this).balance;
      
      // trade on kyber
      uint lusdQty = KyberLike(kyber).trade{value: ethQty}(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, ethQty, lusd, address(this), uint(-1), 0, address(this));
      
      // swap on b.amm
      ERC20Like(lusd).approve(bamm, lusdQty);
      BAMMLike(bamm).swap(lusdQty, address(this));
      
      uint ethBalanceAfter = address(this).balance;
      
      require(ethBalanceAfter >= ethBalanceBefore, "!arb");
  }
  
  receive() external payable {}  
}