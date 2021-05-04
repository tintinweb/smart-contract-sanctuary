pragma solidity 0.7.6;

import "./complifi-amm/libs/complifi/tokens/IERC20Metadata.sol";
import "./ILiquidityMining.sol";

//import "hardhat/console.sol";

contract ProxyActionsLiquidityMining {

    /// @notice Direct liquidity mining method deposit
    function deposit(
        address _liquidityMining,
        address _token,
        uint256 _tokenAmount
    ) external {

        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);
        require(liquidityMining.isTokenAdded(_token), "TOKEN_NOT_ADDED");

        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _tokenAmount),
            "TOKEN_IN"
        );

        IERC20(_token).approve(_liquidityMining, _tokenAmount);

        uint256 pid = liquidityMining.poolPidByAddress(_token);
        liquidityMining.deposit(pid, _tokenAmount);
    }

    /// @notice Direct liquidity mining method withdraw
    function withdraw(
        address _liquidityMining,
        address _token,
        uint256 _tokenAmount
    ) external {

        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);
        require(liquidityMining.isTokenAdded(_token), "TOKEN_NOT_ADDED");

        uint256 pid = liquidityMining.poolPidByAddress(_token);
        liquidityMining.withdraw(pid, _tokenAmount);

        uint tokenBalance = IERC20(_token).balanceOf(address(this));
        if(tokenBalance > 0) {
            require(
                IERC20(_token).transfer(msg.sender, tokenBalance),
                "TOKEN_OUT"
            );
        }
    }

    /// @notice Direct liquidity mining method claim
    function claim(
        address _liquidityMining
    ) external {

        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);
        liquidityMining.claim();

        uint rewardClaimedBalance = IERC20(liquidityMining.rewardToken()).balanceOf(address(this));
        if(rewardClaimedBalance > 0) {
            require(
                IERC20(liquidityMining.rewardToken()).transfer(msg.sender, rewardClaimedBalance),
                "REWARD_OUT"
            );
        }
    }
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IERC20 {

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);
}

interface ILiquidityMining {

    function rewardToken() external view returns(address);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claim() external;
    function poolPidByAddress(address) external view returns(uint256);
    function isTokenAdded(address _token) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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