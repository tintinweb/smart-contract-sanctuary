/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// File: contracts/updater/interfaces/IFreeFromUpTo.sol
pragma solidity ^0.6.12;

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

// File: contracts/updater/BurnChi.sol
pragma solidity 0.6.12;

contract BurnChi {
    IFreeFromUpTo private constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI(bool _useChi) {
        if(_useChi) {
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
        } else {
            _;
        }
    }
}

// File: contracts/updater/interfaces/ITokenManager.sol
pragma solidity ^0.6.12;

interface ITokenManager {
  function updateRewardParams(address payable userAddr) external returns (bool);
}

// File: contracts/updater/interfaces/IObserver.sol
pragma solidity ^0.6.12;

interface IObserver {
  function updateChainMarketInfo(uint256 _idx, uint256 chainDeposit, uint256 chainBorrow) external returns (bool);
}

// File: contracts/updater/Updater.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

/**
 * @title BiFi's Updater contract
 * @notice Update chain market, reward
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract Updater is BurnChi {
  address public owner;

  ITokenManager public manager;
  IObserver public observer;

  modifier onlyOwner {
		require(msg.sender == owner, "onlyOwner");
		_;
	}

  constructor(address managerAddress, address observerAddress) public {
    owner = msg.sender;

    manager = ITokenManager(managerAddress);
    observer = IObserver(observerAddress);
  }

  function setManager(address managerAddress) public onlyOwner returns (bool) {
    manager = ITokenManager(managerAddress);
    return true;
  }

  function setObserver(address observerAddress) public onlyOwner returns (bool) {
    observer = IObserver(observerAddress);
    return true;
  }

  function syncReward(address payable rewerder, uint256 _idx, uint256 chainDeposit, uint256 chainBorrow, bool _useChi) external onlyOwner discountCHI(_useChi) returns (bool) {
    _updateChainMarketInfo(_idx, chainDeposit, chainBorrow);
    _updateRewardParams(rewerder);

    return true;
  }

  function updateRewardParams(address payable rewerder, bool _useChi) external onlyOwner discountCHI(_useChi) returns (bool) {
    return _updateRewardParams(rewerder);
  }

  function _updateRewardParams(address payable rewerder) internal returns (bool) {
    return manager.updateRewardParams(rewerder);
  }

  function updateChainMarketInfo(uint256 _idx, uint256 chainDeposit, uint256 chainBorrow, bool _useChi) external onlyOwner discountCHI(_useChi) returns (bool) {
    return _updateChainMarketInfo(_idx, chainDeposit, chainBorrow);
  }

  function _updateChainMarketInfo(uint256 _idx, uint256 chainDeposit, uint256 chainBorrow) internal returns (bool) {
    return observer.updateChainMarketInfo(_idx, chainDeposit, chainBorrow);
  }
}