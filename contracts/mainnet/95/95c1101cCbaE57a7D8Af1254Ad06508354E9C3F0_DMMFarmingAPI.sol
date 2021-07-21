// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;


interface IERC20 {
  function decimals() external view returns (uint8);
}

interface DMMPool {
    function totalSupply() external view returns (uint256);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
}

interface DMMFarming {
    function getRewardTokens() external view returns (address[] memory);

    function getPoolInfo(uint256 _pid)
        external
        view
        returns (
            uint256 totalStake,
            address stakeToken,
            uint32 startBlock,
            uint32 endBlock,
            uint32 lastRewardBlock,
            uint256[] memory rewardPerBlocks,
            uint256[] memory accRewardPerShares
        );
}

contract DMMFarmingAPI {
    function getInfo(
        DMMPool _pool,
        DMMFarming _farming,
        uint256 _pid,
        IERC20 _token0,
        IERC20 _token1
    )
        public
        view
        returns (
            address[] memory rewardTokens,
            uint256 totalStake,
            uint256[] memory rewardPerBlocks,
            uint256 lpTotalSupply,
            uint8 token0Decimals,
            uint8 token1Decimals,
            uint256 token0Balance,
            uint256 token1Balance
        )
    {
        (uint112 reserve0, uint112 reserve1) = _pool.getReserves();

        rewardTokens = _farming.getRewardTokens();
        (totalStake,,,,,rewardPerBlocks,) = _farming.getPoolInfo(_pid);
        lpTotalSupply = _pool.totalSupply();
        token0Decimals = _token0.decimals();
        token1Decimals = _token1.decimals();
        token0Balance = reserve0;
        token1Balance = reserve1;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 15000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}