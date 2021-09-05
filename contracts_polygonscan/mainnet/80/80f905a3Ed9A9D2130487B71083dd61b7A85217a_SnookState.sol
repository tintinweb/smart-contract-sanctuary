/**
 *Submitted for verification at polygonscan.com on 2021-09-05
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org
// SPDX-License-Identifier: MIT

// File contracts/IDescriptorUser.sol

pragma solidity ^0.8.0;

// https://ethereum.stackexchange.com/questions/27259/how-can-you-share-a-struct-definition-between-contracts-in-separate-files
interface IDescriptorUser {
  struct Descriptor {
    uint score;
    uint stars;
    uint traitCount;

    uint resurrectionPrice;
    uint resurrectionCount;
    uint onResurrectionScore;
    uint onResurrectionStars;
    uint onResurrectionTraitCount;
    string onResurrectionTokenURI;

    // required to recalculate probability density on exit from the game
    uint onGameEntryTraitCount; 
    uint deathTime;
    bool gameAllowed; // contract get the token to play only when this flag is true
  }
}


// File contracts/ISnookState.sol

pragma solidity ^0.8.0;

interface ISnookState is IDescriptorUser { 
  function getSnookGameAddress() external view returns (address);
  function getSkinRewardsAddress() external view returns (address);
  function getAfterdeathAddress() external view returns (address);
  function getSGEAddress() external view returns (address);
  
  function getDescriptor(uint tokenId) external view returns(Descriptor memory);
  function setDescriptor(uint tokenId, Descriptor memory descriptor) external;
  function deleteDescriptor(uint tokenId) external;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/SnookState.sol

pragma solidity ^0.8.0;


contract SnookState is ISnookState, Initializable {
  mapping (uint => Descriptor) private _descriptors;

  address private _game;
  address private _skinRewards;
  address private _afterdeath;
  address private _sge;
  
  function getSnookGameAddress() external override view returns (address) {
    return _game;
  }

  function getSkinRewardsAddress() external override view returns (address) {
    return _skinRewards;
  }

  function getAfterdeathAddress() external override view returns (address) {
    return _afterdeath;
  }

  function getSGEAddress() external override view returns (address) {
    return _sge;
  }

  function initialize(
    address game,
    address skinRewards,
    address afterdeath,
    address sge
  ) initializer public {
    _game = game;
    _skinRewards = skinRewards;
    _afterdeath = afterdeath;
    _sge = sge;
  }

  modifier onlyGameContracts {
    require(
      msg.sender == _game || 
      msg.sender == _skinRewards || 
      msg.sender == _sge ||
      msg.sender == _afterdeath, 
      'SnookState: Not game contracts'
    );
    _;
  }

  function getDescriptor(uint tokenId) onlyGameContracts external override view returns(Descriptor memory) {
    return _descriptors[tokenId];
  }
  function setDescriptor(uint tokenId, Descriptor memory descriptor) onlyGameContracts external override {
    _descriptors[tokenId] = descriptor;
  }
  function deleteDescriptor(uint tokenId) onlyGameContracts external override {
    delete _descriptors[tokenId];
  }
}