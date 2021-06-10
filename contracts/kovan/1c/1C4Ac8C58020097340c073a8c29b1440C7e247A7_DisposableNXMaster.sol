/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/INXMMaster.sol

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface INXMMaster {

  function tokenAddress() external view returns (address);

  function owner() external view returns (address);

  function pauseTime() external view returns (uint);

  function masterInitialized() external view returns (bool);

  function isInternal(address _add) external view returns (bool);

  function isPause() external view returns (bool check);

  function isOwner(address _add) external view returns (bool);

  function isMember(address _add) external view returns (bool);

  function checkIsAuthToGoverned(address _add) external view returns (bool);

  function updatePauseTime(uint _time) external;

  function dAppLocker() external view returns (address _add);

  function dAppToken() external view returns (address _add);

  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);
}

// File: contracts/abstract/Iupgradable.sol

pragma solidity ^0.5.0;


contract Iupgradable {

  INXMMaster public ms;
  address public nxMasterAddress;

  modifier onlyInternal {
    require(ms.isInternal(msg.sender));
    _;
  }

  modifier isMemberAndcheckPause {
    require(ms.isPause() == false && ms.isMember(msg.sender) == true);
    _;
  }

  modifier onlyOwner {
    require(ms.isOwner(msg.sender));
    _;
  }

  modifier checkPause {
    require(ms.isPause() == false);
    _;
  }

  modifier isMember {
    require(ms.isMember(msg.sender), "Not member");
    _;
  }

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public;

  /**
   * @dev change master address
   * @param _masterAddress is the new address
   */
  function changeMasterAddress(address _masterAddress) public {
    if (address(ms) != address(0)) {
      require(address(ms) == msg.sender, "Not master");
    }

    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;
  }

}

// File: contracts/modules/governance/external/Governed.sol

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;


interface IMaster {
  function getLatestAddress(bytes2 _module) external view returns (address);
}

contract Governed {

  address public masterAddress; // Name of the dApp, needs to be set by contracts inheriting this contract

  /// @dev modifier that allows only the authorized addresses to execute the function
  modifier onlyAuthorizedToGovern() {
    IMaster ms = IMaster(masterAddress);
    require(ms.getLatestAddress("GV") == msg.sender, "Not authorized");
    _;
  }

  /// @dev checks if an address is authorized to govern
  function isAuthorizedToGovern(address _toCheck) public view returns (bool) {
    IMaster ms = IMaster(masterAddress);
    return (ms.getLatestAddress("GV") == _toCheck);
  }

}

// File: contracts/modules/governance/external/Proxy.sol

pragma solidity ^0.5.0;


/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  // solhint-disable-next-line no-complex-fallback
  function() external payable {
    address _impl = implementation();
    require(_impl != address(0));

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 {revert(ptr, size)}
      default {return (ptr, size)}
    }
  }

  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);
}

// File: contracts/modules/governance/external/UpgradeabilityProxy.sol

pragma solidity ^0.5.0;



/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
  /**
  * @dev This event will be emitted every time the implementation gets upgraded
  * @param implementation representing the address of the upgraded implementation
  */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant IMPLEMENTATION_POSITION = keccak256("org.govblocks.proxy.implementation");

  /**
  * @dev Constructor function
  */
  // solhint-disable-next-line no-empty-blocks
  constructor() public {}

  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() public view returns (address impl) {
    bytes32 position = IMPLEMENTATION_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(position)
    }
  }

  /**
  * @dev Sets the address of the current implementation
  * @param _newImplementation address representing the new implementation to be set
  */
  function _setImplementation(address _newImplementation) internal {
    bytes32 position = IMPLEMENTATION_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(position, _newImplementation)
    }
  }

  /**
  * @dev Upgrades the implementation address
  * @param _newImplementation representing the address of the new implementation to be set
  */
  function _upgradeTo(address _newImplementation) internal {
    address currentImplementation = implementation();
    require(currentImplementation != _newImplementation);
    _setImplementation(_newImplementation);
    emit Upgraded(_newImplementation);
  }
}

// File: contracts/modules/governance/external/OwnedUpgradeabilityProxy.sol

pragma solidity ^0.5.0;



/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  // Storage position of the owner of the contract
  bytes32 private constant PROXY_OWNER_POSITION = keccak256("org.govblocks.proxy.owner");

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  constructor(address _implementation) public {
    _setUpgradeabilityOwner(msg.sender);
    _upgradeTo(_implementation);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
  * @dev Tells the address of the owner
  * @return the address of the owner
  */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = PROXY_OWNER_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      owner := sload(position)
    }
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param _newOwner The address to transfer ownership to.
  */
  function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
    require(_newOwner != address(0));
    _setUpgradeabilityOwner(_newOwner);
    emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
  }

  /**
  * @dev Allows the proxy owner to upgrade the current version of the proxy.
  * @param _implementation representing the address of the new implementation to be set.
  */
  function upgradeTo(address _implementation) public onlyProxyOwner {
    _upgradeTo(_implementation);
  }

  /**
   * @dev Sets the address of the owner
  */
  function _setUpgradeabilityOwner(address _newProxyOwner) internal {
    bytes32 position = PROXY_OWNER_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(position, _newProxyOwner)
    }
  }
}

// File: contracts/modules/capital/LegacyPoolData.sol

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

contract LegacyPoolData {
 function minCap() external view returns (uint);
 function notariseMCR() external view returns (address);
 function changeNotariseAddress(address) external;
}

// File: contracts/interfaces/IMemberRoles.sol

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IMemberRoles {

  enum Role {UnAssigned, AdvisoryBoard, Member, Owner}

  function payJoiningFee(address _userAddress) external payable;

  function switchMembership(address _newAddress) external;

  function switchMembershipOf(address member, address _newAddress) external;

  function swapOwner(address _newOwnerAddress) external;

  function kycVerdict(address payable _userAddress, bool verdict) external;

  function getClaimPayoutAddress(address payable _member) external view returns (address payable);

  function setClaimPayoutAddress(address payable _address) external;

  function totalRoles() external view returns (uint256);

  function changeAuthorized(uint _roleId, address _newAuthorized) external;

  function members(uint _memberRoleId) external view returns (uint, address[] memory memberArray);

  function numberOfMembers(uint _memberRoleId) external view returns (uint);

  function authorized(uint _memberRoleId) external view returns (address);

  function roles(address _memberAddress) external view returns (uint[] memory);

  function checkRole(address _memberAddress, uint _roleId) external view returns (bool);

  function getMemberLengthForAllRoles() external view returns (uint[] memory totalMembers);

  function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool);

  function membersLength(uint _memberRoleId) external view returns (uint);
}

// File: contracts/interfaces/IPriceFeedOracle.sol

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IPriceFeedOracle {

  function daiAddress() external view returns (address);
  function stETH() external view returns (address);
  function ETH() external view returns (address);

  function getAssetToEthRate(address asset) external view returns (uint);
  function getAssetForEth(address asset, uint ethIn) external view returns (uint);

}

// File: contracts/interfaces/IPool.sol

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;


interface IPool {
  function sellNXM(uint tokenAmount, uint minEthOut) external;

  function sellNXMTokens(uint tokenAmount) external returns (bool);

  function minPoolEth() external returns (uint);

  function transferAssetToSwapOperator(address asset, uint amount) external;

  function setAssetDataLastSwapTime(address asset, uint32 lastSwapTime) external;

  function getAssetDetails(address _asset) external view returns (
    uint112 min,
    uint112 max,
    uint32 lastAssetSwapTime,
    uint maxSlippageRatio
  );

  function sendClaimPayout (
    address asset,
    address payable payoutAddress,
    uint amount
  ) external returns (bool success);

  function transferAsset(
    address asset,
    address payable destination,
    uint amount
  ) external;

  function upgradeCapitalPool(address payable newPoolAddress) external;

  function priceFeedOracle() external view returns (IPriceFeedOracle);

  function getPoolValueInEth() external view returns (uint);


  function transferAssetFrom(address asset, address from, uint amount) external;

  function getEthForNXM(uint nxmAmount) external view returns (uint ethAmount);

  function calculateEthForNXM(
    uint nxmAmount,
    uint currentTotalAssetValue,
    uint mcrEth
  ) external pure returns (uint);

  function calculateMCRRatio(uint totalAssetValue, uint mcrEth) external pure returns (uint);

  function calculateTokenSpotPrice(uint totalAssetValue, uint mcrEth) external pure returns (uint tokenPrice);

  function getTokenPrice(address asset) external view returns (uint tokenPrice);

  function getMCRRatio() external view returns (uint);
}

// File: contracts/interfaces/IQuotation.sol

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IQuotation {
  function verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  function createCover(
    address payable from,
    address scAddress,
    bytes4 currency,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  function transferAssetsToNewContract(address) external pure;
}

// File: contracts/interfaces/IClaims.sol

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IClaims {

  function setClaimStatus(uint claimId, uint stat) external;

  function getCATokens(uint claimId, uint member) external view returns (uint tokens);

  function submitClaim(uint coverId) external;

  function submitClaimForMember(uint coverId, address member) external;

  function submitClaimAfterEPOff() external pure;

  function submitCAVote(uint claimId, int8 verdict) external;

  function submitMemberVote(uint claimId, int8 verdict) external;

  function pauseAllPendingClaimsVoting() external pure;

  function startAllPendingClaimsVoting() external pure;

  function checkVoteClosing(uint claimId) external view returns (int8 close);
}

// File: contracts/interfaces/ITokenController.sol

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface ITokenController {

  function coverInfo(uint id) external view returns (uint16 claimCount, bool hasOpenClaim, bool hasAcceptedClaim);

  function claimSubmissionGracePeriod() external view returns (uint);

  function withdrawCoverNote(
    address _of,
    uint[] calldata _coverIds,
    uint[] calldata _indexes
  ) external;

  function markCoverClaimOpen(uint coverId) external;

  function markCoverClaimClosed(uint coverId, bool isAccepted) external;

  function changeOperator(address _newOperator) external;

  function operatorTransfer(address _from, address _to, uint _value) external returns (bool);

  function lockClaimAssessmentTokens(uint256 _amount, uint256 _time) external;

  function lockOf(address _of, bytes32 _reason, uint256 _amount, uint256 _time) external returns (bool);

  function mintCoverNote(
    address _of,
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  ) external;

  function extendClaimAssessmentLock(uint256 _time) external;

  function extendLockOf(address _of, bytes32 _reason, uint256 _time) external returns (bool);

  function increaseClaimAssessmentLock(uint256 _amount) external;

  function burnFrom(address _of, uint amount) external returns (bool);

  function burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) external;

  function reduceLock(address _of, bytes32 _reason, uint256 _time) external;

  function releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount) external;

  function addToWhitelist(address _member) external;

  function removeFromWhitelist(address _member) external;

  function mint(address _member, uint _amount) external;

  function lockForMemberVote(address _of, uint _days) external;
  function withdrawClaimAssessmentTokens(address _of) external;

  function getLockReasons(address _of) external view returns (bytes32[] memory reasons);

  function getLockedTokensValidity(address _of, bytes32 reason) external view returns (uint256 validity);

  function getUnlockableTokens(address _of) external view returns (uint256 unlockableTokens);

  function tokensLocked(address _of, bytes32 _reason) external view returns (uint256 amount);

  function tokensLockedWithValidity(address _of, bytes32 _reason)
  external
  view
  returns (uint256 amount, uint256 validity);

  function tokensUnlockable(address _of, bytes32 _reason) external view returns (uint256 amount);

  function totalSupply() external view returns (uint256);

  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) external view returns (uint256 amount);
  function totalBalanceOf(address _of) external view returns (uint256 amount);

  function totalLockedBalance(address _of) external view returns (uint256 amount);
}

// File: contracts/interfaces/IQuotationData.sol

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IQuotationData {

  function authQuoteEngine() external view returns (address);
  function stlp() external view returns (uint);
  function stl() external view returns (uint);
  function pm() external view returns (uint);
  function minDays() external view returns (uint);
  function tokensRetained() external view returns (uint);
  function kycAuthAddress() external view returns (address);

  function refundEligible(address) external view returns (bool);
  function holdedCoverIDStatus(uint) external view returns (uint);
  function timestampRepeated(uint) external view returns (bool);

  enum HCIDStatus {NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover}
  enum CoverStatus {Active, ClaimAccepted, ClaimDenied, CoverExpired, ClaimSubmitted, Requested}

  function addInTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external;

  function subFromTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external;

  function subFromTotalSumAssured(bytes4 _curr, uint _amount) external;

  function addInTotalSumAssured(bytes4 _curr, uint _amount) external;

  function setTimestampRepeated(uint _timestamp) external;

  /// @dev Creates a blank new cover.
  function addCover(
    uint16 _coverPeriod,
    uint _sumAssured,
    address payable _userAddress,
    bytes4 _currencyCode,
    address _scAddress,
    uint premium,
    uint premiumNXM
  ) external;


  function addHoldCover(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] calldata coverDetails,
    uint16 coverPeriod
  ) external;

  function setRefundEligible(address _add, bool status) external;

  function setHoldedCoverIDStatus(uint holdedCoverID, uint status) external;

  function setKycAuthAddress(address _add) external;

  function changeAuthQuoteEngine(address _add) external;

  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val);

  function getProductDetails()
  external
  view
  returns (
    uint _minDays,
    uint _pm,
    uint _stl,
    uint _stlp
  );

  function getCoverLength() external view returns (uint len);

  function getAuthQuoteEngine() external view returns (address _add);

  function getTotalSumAssured(bytes4 _curr) external view returns (uint amount);

  function getAllCoversOfUser(address _add) external view returns (uint[] memory allCover);

  function getUserCoverLength(address _add) external view returns (uint len);

  function getCoverStatusNo(uint _cid) external view returns (uint8);

  function getCoverPeriod(uint _cid) external view returns (uint32 cp);

  function getCoverSumAssured(uint _cid) external view returns (uint sa);

  function getCurrencyOfCover(uint _cid) external view returns (bytes4 curr);

  function getValidityOfCover(uint _cid) external view returns (uint date);

  function getscAddressOfCover(uint _cid) external view returns (uint, address);

  function getCoverMemberAddress(uint _cid) external view returns (address payable _add);

  function getCoverPremiumNXM(uint _cid) external view returns (uint _premiumNXM);

  function getCoverDetailsByCoverID1(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    address _memberAddress,
    address _scAddress,
    bytes4 _currencyCode,
    uint _sumAssured,
    uint premiumNXM
  );

  function getCoverDetailsByCoverID2(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil
  );

  function getHoldedCoverDetailsByID1(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address scAddress,
    bytes4 coverCurr,
    uint16 coverPeriod
  );

  function getUserHoldedCoverLength(address _add) external view returns (uint);

  function getUserHoldedCoverByIndex(address _add, uint index) external view returns (uint);

  function getHoldedCoverDetailsByID2(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address payable memberAddress,
    uint[] memory coverDetails
  );

  function getTotalSumAssuredSC(address _add, bytes4 _curr) external view returns (uint amount);

  function changeCoverStatusNo(uint _cid, uint8 _stat) external;

}

// File: contracts/interfaces/ITokenData.sol

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface ITokenData {

  function walletAddress() external view returns (address payable);
  function lockTokenTimeAfterCoverExp() external view returns (uint);
  function bookTime() external view returns (uint);
  function lockCADays() external view returns (uint);
  function lockMVDays() external view returns (uint);
  function scValidDays() external view returns (uint);
  function joiningFee() external view returns (uint);
  function stakerCommissionPer() external view returns (uint);
  function stakerMaxCommissionPer() external view returns (uint);
  function tokenExponent() external view returns (uint);
  function priceStep() external view returns (uint);

  function depositedCN(uint) external view returns (uint amount, bool isDeposited);

  function lastCompletedStakeCommission(address) external view returns (uint);

  function changeWalletAddress(address payable _address) external;

  function getStakerStakedContractByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (address stakedContractAddress);

  function getStakerStakedBurnedByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint burnedAmount);

  function getStakerStakedUnlockableBeforeLastBurnByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint unlockable);

  function getStakerStakedContractIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint scIndex);

  function getStakedContractStakerIndex(
    address _stakedContractAddress,
    uint _stakedContractIndex
  )
  external
  view
  returns (uint sIndex);

  function getStakerInitialStakedAmountOnContract(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint amount);

  function getStakerStakedContractLength(
    address _stakerAddress
  )
  external
  view
  returns (uint length);

  function getStakerUnlockedStakedTokens(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint amount);

  function pushUnlockedStakedTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;


  function pushBurnedTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function pushUnlockableBeforeLastBurnTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function setUnlockableBeforeLastBurnTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function pushEarnedStakeCommissions(
    address _stakerAddress,
    address _stakedContractAddress,
    uint _stakedContractIndex,
    uint _commissionAmount
  ) external;

  function pushRedeemedStakeCommissions(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function getStakerEarnedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint);

  function getStakerRedeemedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint);

  function getStakerTotalEarnedStakeCommission(
    address _stakerAddress
  )
  external
  view
  returns (uint totalCommissionEarned);

  function getStakerTotalReedmedStakeCommission(
    address _stakerAddress
  )
  external
  view
  returns (uint totalCommissionRedeemed);

  function setDepositCN(uint coverId, bool flag) external;

  function getStakedContractStakerByIndex(
    address _stakedContractAddress,
    uint _stakedContractIndex
  )
  external
  view
  returns (address stakerAddress);

  function getStakedContractStakersLength(
    address _stakedContractAddress
  ) external view returns (uint length);

  function addStake(
    address _stakerAddress,
    address _stakedContractAddress,
    uint _amount
  ) external returns (uint scIndex);

  function bookCATokens(address _of) external;

  function isCATokensBooked(address _of) external view returns (bool res);

  function setStakedContractCurrentCommissionIndex(
    address _stakedContractAddress,
    uint _index
  ) external;

  function setLastCompletedStakeCommissionIndex(
    address _stakerAddress,
    uint _index
  ) external;


  function setStakedContractCurrentBurnIndex(
    address _stakedContractAddress,
    uint _index
  ) external;

  function setDepositCNAmount(uint coverId, uint amount) external;
}

// File: contracts/interfaces/IClaimsReward.sol

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IClaimsReward {

  /// @dev Decides the next course of action for a given claim.
  function changeClaimStatus(uint claimid) external;

  function getCurrencyAssetAddress(bytes4 currency) external view returns (address);

  function getRewardToBeGiven(
    uint check,
    uint voteid,
    uint flag
  )
  external
  view
  returns (
    uint tokenCalculated,
    bool lastClaimedCheck,
    uint tokens,
    uint perc
  );

  function upgrade(address _newAdd) external;

  function getRewardToBeDistributedByUser(address _add) external view returns (uint total);

  function getRewardAndClaimedStatus(uint check, uint claimId) external view returns (uint reward, bool claimed);


  function claimAllPendingReward(uint records) external;

  function getAllPendingRewardOfUser(address _add) external view returns (uint);

  function _claimStakeCommission(uint _records, address _user) external;
}

// File: contracts/interfaces/IClaimsData.sol

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IClaimsData {

  function pendingClaimStart() external view returns (uint);
  function claimDepositTime() external view returns (uint);
  function maxVotingTime() external view returns (uint);
  function minVotingTime() external view returns (uint);
  function payoutRetryTime() external view returns (uint);
  function claimRewardPerc() external view returns (uint);
  function minVoteThreshold() external view returns (uint);
  function maxVoteThreshold() external view returns (uint);
  function majorityConsensus() external view returns (uint);
  function pauseDaysCA() external view returns (uint);

  function userClaimVotePausedOn(address) external view returns (uint);

  function setpendingClaimStart(uint _start) external;

  function setRewardDistributedIndexCA(address _voter, uint caIndex) external;

  function setUserClaimVotePausedOn(address user) external;

  function setRewardDistributedIndexMV(address _voter, uint mvIndex) external;


  function setClaimRewardDetail(
    uint claimid,
    uint percCA,
    uint percMV,
    uint tokens
  ) external;

  function setRewardClaimed(uint _voteid, bool claimed) external;

  function changeFinalVerdict(uint _claimId, int8 _verdict) external;

  function addClaim(
    uint _claimId,
    uint _coverId,
    address _from,
    uint _nowtime
  ) external;

  function addVote(
    address _voter,
    uint _tokens,
    uint claimId,
    int8 _verdict
  ) external;

  function addClaimVoteCA(uint _claimId, uint _voteid) external;

  function setUserClaimVoteCA(
    address _from,
    uint _claimId,
    uint _voteid
  ) external;

  function setClaimTokensCA(uint _claimId, int8 _vote, uint _tokens) external;

  function setClaimTokensMV(uint _claimId, int8 _vote, uint _tokens) external;

  function addClaimVotemember(uint _claimId, uint _voteid) external;

  function setUserClaimVoteMember(
    address _from,
    uint _claimId,
    uint _voteid
  ) external;

  function updateState12Count(uint _claimId, uint _cnt) external;

  function setClaimStatus(uint _claimId, uint _stat) external;

  function setClaimdateUpd(uint _claimId, uint _dateUpd) external;

  function setClaimAtEmergencyPause(
    uint _coverId,
    uint _dateUpd,
    bool _submit
  ) external;

  function setClaimSubmittedAtEPTrue(uint _index, bool _submit) external;


  function setFirstClaimIndexToSubmitAfterEP(
    uint _firstClaimIndexToSubmit
  ) external;


  function setPendingClaimDetails(
    uint _claimId,
    uint _pendingTime,
    bool _voting
  ) external;

  function setPendingClaimVoteStatus(uint _claimId, bool _vote) external;

  function setFirstClaimIndexToStartVotingAfterEP(
    uint _claimStartVotingFirstIndex
  ) external;

  function callVoteEvent(
    address _userAddress,
    uint _claimId,
    bytes4 _typeOf,
    uint _tokens,
    uint _submitDate,
    int8 _verdict
  ) external;

  function callClaimEvent(
    uint _coverId,
    address _userAddress,
    uint _claimId,
    uint _datesubmit
  ) external;

  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val);

  function getClaimOfEmergencyPauseByIndex(
    uint _index
  )
  external
  view
  returns (
    uint coverId,
    uint dateUpd,
    bool submit
  );

  function getAllClaimsByIndex(
    uint _claimId
  )
  external
  view
  returns (
    uint coverId,
    int8 vote,
    uint status,
    uint dateUpd,
    uint state12Count
  );

  function getUserClaimVoteCA(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote);

  function getUserClaimVoteMember(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote);

  function getAllVoteLength() external view returns (uint voteCount);

  function getClaimStatusNumber(uint _claimId) external view returns (uint claimId, uint statno);

  function getRewardStatus(uint statusNumber) external view returns (uint percCA, uint percMV);

  function getClaimState12Count(uint _claimId) external view returns (uint num);

  function getClaimDateUpd(uint _claimId) external view returns (uint dateupd);

  function getAllClaimsByAddress(address _member) external view returns (uint[] memory claimarr);


  function getClaimsTokenCA(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  );

  function getClaimsTokenMV(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  );
  function getCaClaimVotesToken(uint _claimId) external view returns (uint claimId, uint cnt);

  function getMemberClaimVotesToken(
    uint _claimId
  )
  external
  view
  returns (uint claimId, uint cnt);

  function getVoteDetails(uint _voteid)
  external view
  returns (
    uint tokens,
    uint claimId,
    int8 verdict,
    bool rewardClaimed
  );

  function getVoterVote(uint _voteid) external view returns (address voter);

  function getClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint coverId,
    int8 vote,
    uint status,
    uint dateUpd,
    uint state12Count
  );

  function getClaimVoteLength(
    uint _claimId,
    uint8 _ca
  )
  external
  view
  returns (uint claimId, uint len);

  function getVoteVerdict(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (int8 ver);

  function getVoteToken(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (uint tok);

  function getVoteVoter(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (address voter);

  function getUserClaimCount(address _add) external view returns (uint len);

  function getClaimLength() external view returns (uint len);

  function actualClaimLength() external view returns (uint len);


  function getClaimFromNewStart(
    uint _index,
    address _add
  )
  external
  view
  returns (
    uint coverid,
    uint claimId,
    int8 voteCA,
    int8 voteMV,
    uint statusnumber
  );

  function getUserClaimByIndex(
    uint _index,
    address _add
  )
  external
  view
  returns (
    uint status,
    uint coverid,
    uint claimId
  );

  function getAllVotesForClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint[] memory ca,
    uint[] memory mv
  );


  function getTokensClaim(
    address _of,
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint tokens
  );

  function getRewardDistributedIndex(
    address _voter
  )
  external
  view
  returns (
    uint lastCAvoteIndex,
    uint lastMVvoteIndex
  );

  function getClaimRewardDetail(
    uint claimid
  )
  external
  view
  returns (
    uint percCA,
    uint percMV,
    uint tokens
  );

  function getClaimCoverId(uint _claimId) external view returns (uint claimId, uint coverid);

  function getClaimVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token);

  function getClaimMVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token);

  function getVoteAddressCA(address _voter, uint index) external view returns (uint);

  function getVoteAddressMember(address _voter, uint index) external view returns (uint);

  function getVoteAddressCALength(address _voter) external view returns (uint);

  function getVoteAddressMemberLength(address _voter) external view returns (uint);

  function getFinalVerdict(uint _claimId) external view returns (int8 verdict);

  function getLengthOfClaimSubmittedAtEP() external view returns (uint len);

  function getFirstClaimIndexToSubmitAfterEP() external view returns (uint indexToSubmit);

  function getLengthOfClaimVotingPause() external view returns (uint len);

  function getPendingClaimDetailsByIndex(
    uint _index
  )
  external
  view
  returns (
    uint claimId,
    uint pendingTime,
    bool voting
  );

  function getFirstClaimIndexToStartVotingAfterEP() external view returns (uint firstindex);

}

// File: contracts/modules/governance/NXMaster.sol

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;















contract NXMaster is INXMMaster, Governed {
  using SafeMath for uint;

  struct EmergencyPause {
    bool pause;
    uint time;
    bytes4 by;
  }

  EmergencyPause[] public emergencyPaused;

  bytes2[] internal allContractNames;
  mapping(address => bool) public contractsActive;
  mapping(bytes2 => address payable) internal allContractVersions;
  mapping(bytes2 => bool) public isProxy;
  mapping(bytes2 => bool) public isUpgradable;

  address public tokenAddress;
  bool internal reentrancyLock;
  bool public masterInitialized;
  address public owner;
  uint public pauseTime;

  modifier noReentrancy() {
    require(!reentrancyLock, "Reentrant call.");
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

  function upgradeMultipleImplementations(
    bytes2[] calldata _contractNames,
    address[] calldata _contractAddresses
  )
  external
  onlyAuthorizedToGovern
  {
    require(_contractNames.length == _contractAddresses.length, "Array length should be equal.");
    for (uint i = 0; i < _contractNames.length; i++) {
      require(_contractAddresses[i] != address(0), "null address is not allowed.");
      require(isProxy[_contractNames[i]], "Contract should be proxy.");
      OwnedUpgradeabilityProxy proxy = OwnedUpgradeabilityProxy(allContractVersions[_contractNames[i]]);
      proxy.upgradeTo(_contractAddresses[i]);
    }
  }

  /// @dev Adds new internal contract
  /// @param _contractName contract code for new contract
  /// @param _contractAddress contract address for new contract
  /// @param _type pass 1 if contract is upgradable, 2 if contract is proxy, any other uint if none.
  function addNewInternalContract(
    bytes2 _contractName,
    address payable _contractAddress,
    uint _type
  )
  external
  onlyAuthorizedToGovern {
    require(allContractVersions[_contractName] == address(0), "Contract code is already available.");
    require(_contractAddress != address(0), "NULL address is not allowed.");
    allContractNames.push(_contractName);
    address newInternalContract = _contractAddress;
    if (_type == 1) {
      isUpgradable[_contractName] = true;
    } else if (_type == 2) {
      newInternalContract = _generateProxy(_contractAddress);
      isProxy[_contractName] = true;
    }
    allContractVersions[_contractName] = address(uint160(newInternalContract));
    contractsActive[newInternalContract] = true;
    Iupgradable up = Iupgradable(allContractVersions[_contractName]);
    up.changeMasterAddress(address(this));
    up.changeDependentContractAddress();
  }

  /**
   * @dev Anyone can close a claim if oraclize fails to close it.
   * @param _claimId id of claim to be closed.
   */
  function closeClaim(uint _claimId) external {

    require(canCall(_claimId), "Payout retry time not reached.");
    IClaimsReward cr = IClaimsReward(getLatestAddress("CR"));
    cr.changeClaimStatus(_claimId);
  }

  function getOwnerParameters(bytes8 code) external view returns (bytes8 codeVal, address val) {
    codeVal = code;
    IQuotationData qd;
    LegacyPoolData pd;
    if (code == "MSWALLET") {
      ITokenData td;
      td = ITokenData(getLatestAddress("TD"));
      val = td.walletAddress();

    } else if (code == "MCRNOTA") {

      pd = LegacyPoolData(getLatestAddress("PD"));
      val = pd.notariseMCR();

    } else if (code == "OWNER") {

      val = owner;

    } else if (code == "QUOAUTH") {

      qd = IQuotationData(getLatestAddress("QD"));
      val = qd.authQuoteEngine();

    } else if (code == "KYCAUTH") {
      qd = IQuotationData(getLatestAddress("QD"));
      val = qd.kycAuthAddress();

    }

  }

  /// @dev Add Emergency pause
  /// @param _pause to set Emergency Pause ON/OFF
  /// @param _by to set who Start/Stop EP
  function addEmergencyPause(bool _pause, bytes4 _by) public onlyAuthorizedToGovern {
    emergencyPaused.push(EmergencyPause(_pause, now, _by));
    if (_pause == false) {
      IClaims c1 = IClaims(allContractVersions["CL"]);
      c1.submitClaimAfterEPOff(); // Process claims submitted while EP was on
      c1.startAllPendingClaimsVoting(); // Resume voting on all pending claims
    }
  }

  ///@dev update time in seconds for which emergency pause is applied.
  function updatePauseTime(uint _time) public {
    require(isInternal(msg.sender), "Not internal call.");
    pauseTime = _time;
  }

  /// @dev upgrades multiple contracts at a time
  function upgradeMultipleContracts(
    bytes2[] memory _contractsName,
    address payable[] memory _contractsAddress
  )
  public
  onlyAuthorizedToGovern
  {
    require(_contractsName.length == _contractsAddress.length, "Array length should be equal.");

    for (uint i = 0; i < _contractsName.length; i++) {

      address payable newAddress = _contractsAddress[i];
      require(newAddress != address(0), "NULL address is not allowed.");
      require(isUpgradable[_contractsName[i]], "Contract should be upgradable.");

      if (_contractsName[i] == "QT") {
        IQuotation qt = IQuotation(allContractVersions["QT"]);
        qt.transferAssetsToNewContract(newAddress);

      } else if (_contractsName[i] == "CR") {
        ITokenController tc = ITokenController(getLatestAddress("TC"));
        tc.addToWhitelist(newAddress);
        tc.removeFromWhitelist(allContractVersions["CR"]);
        IClaimsReward cr = IClaimsReward(allContractVersions["CR"]);
        cr.upgrade(newAddress);

      } else if (_contractsName[i] == "P1") {
        IPool p1 = IPool(allContractVersions["P1"]);
        p1.upgradeCapitalPool(newAddress);
      }

      address payable oldAddress = allContractVersions[_contractsName[i]];
      contractsActive[oldAddress] = false;
      allContractVersions[_contractsName[i]] = newAddress;
      contractsActive[newAddress] = true;

      Iupgradable up = Iupgradable(allContractVersions[_contractsName[i]]);
      up.changeMasterAddress(address(this));
    }

    _changeAllAddress();
  }

  /// @dev checks whether the address is an internal contract address.
  function isInternal(address _contractAddress) public view returns (bool) {
    return contractsActive[_contractAddress];
  }

  /// @dev checks whether the address is the Owner or not.
  function isOwner(address _address) public view returns (bool) {
    return owner == _address;
  }

  /// @dev Checks whether emergency pause id on/not.
  function isPause() public view returns (bool) {
    uint length = emergencyPaused.length;
    return length > 0 && emergencyPaused[length - 1].pause;
  }

  /// @dev checks whether the address is a member of the mutual or not.
  function isMember(address _add) public view returns (bool) {
    IMemberRoles mr = IMemberRoles(getLatestAddress("MR"));
    return mr.checkRole(_add, uint(IMemberRoles.Role.Member));
  }

  ///@dev Gets the number of emergency pause has been toggled.
  function getEmergencyPausedLength() public view returns (uint len) {
    len = emergencyPaused.length;
  }

  ///@dev Gets last emergency pause details.
  function getLastEmergencyPause() public view returns (bool _pause, uint _time, bytes4 _by) {
    _pause = false;
    _time = 0;
    _by = "";
    uint len = getEmergencyPausedLength();
    if (len > 0) {
      len = len.sub(1);
      _pause = emergencyPaused[len].pause;
      _time = emergencyPaused[len].time;
      _by = emergencyPaused[len].by;
    }
  }

  /// @dev Gets latest version name and address
  /// @return contractsName Latest version's contract names
  /// @return contractsAddress Latest version's contract addresses
  function getVersionData()
  public
  view
  returns (
    bytes2[] memory contractsName,
    address[] memory contractsAddress
  )
  {
    contractsName = allContractNames;
    contractsAddress = new address[](allContractNames.length);

    for (uint i = 0; i < allContractNames.length; i++) {
      contractsAddress[i] = allContractVersions[allContractNames[i]];
    }
  }

  /**
   * @dev returns the address of token controller
   * @return address is returned
   */
  function dAppLocker() public view returns (address _add) {

    _add = getLatestAddress("TC");

  }

  /**
   * @dev returns the address of nxm token
   * @return address is returned
   */
  function dAppToken() public view returns (address _add) {
    _add = tokenAddress;
  }

  /// @dev Gets latest contract address
  /// @param _contractName Contract name to fetch
  function getLatestAddress(bytes2 _contractName) public view returns (address payable contractAddress) {
    contractAddress = allContractVersions[_contractName];
  }

  /// @dev Creates a new version of contract addresses
  /// @param _contractAddresses Array of contract addresses which will be generated
  function addNewVersion(address payable[] memory _contractAddresses) public {

    require(msg.sender == owner && !masterInitialized, "Caller should be owner and should only be called once.");
    require(_contractAddresses.length == allContractNames.length, "array length not same");
    masterInitialized = true;

    IMemberRoles mr = IMemberRoles(_contractAddresses[14]);
    // shoud send proxy address for proxy contracts (if not 1st time deploying)
    // bool isMasterUpgrade = mr.nxMasterAddress() != address(0);

    for (uint i = 0; i < allContractNames.length; i++) {
      require(_contractAddresses[i] != address(0), "NULL address is not allowed.");
      allContractVersions[allContractNames[i]] = _contractAddresses[i];
      contractsActive[_contractAddresses[i]] = true;

    }

    // Need to override owner as owner in MR to avoid inconsistency as owner in MR is some other address.
    (, address[] memory mrOwner) = mr.members(uint(IMemberRoles.Role.Owner));
    owner = mrOwner[0];
  }

  /**
   * @dev to check if the address is authorized to govern or not
   * @param _add is the address in concern
   * @return the boolean status status for the check
   */
  function checkIsAuthToGoverned(address _add) public view returns (bool) {
    return isAuthorizedToGovern(_add);
  }

  /// @dev Allow AB Members to Start Emergency Pause
  function startEmergencyPause() public onlyAuthorizedToGovern {
    addEmergencyPause(true, "AB"); // Start Emergency Pause
    IClaims c1 = IClaims(allContractVersions["CL"]);
    c1.pauseAllPendingClaimsVoting(); // Pause Voting of all pending Claims
  }

  /**
   * @dev to update the owner parameters
   * @param code is the associated code
   * @param val is value to be set
   */
  function updateOwnerParameters(bytes8 code, address payable val) public onlyAuthorizedToGovern {
    IQuotationData qd;
    LegacyPoolData pd;
    if (code == "MSWALLET") {
      ITokenData td;
      td = ITokenData(getLatestAddress("TD"));
      td.changeWalletAddress(val);

    } else if (code == "MCRNOTA") {

      pd = LegacyPoolData(getLatestAddress("PD"));
      pd.changeNotariseAddress(val);

    } else if (code == "OWNER") {

      IMemberRoles mr = IMemberRoles(getLatestAddress("MR"));
      mr.swapOwner(val);
      owner = val;

    } else if (code == "QUOAUTH") {

      qd = IQuotationData(getLatestAddress("QD"));
      qd.changeAuthQuoteEngine(val);

    } else if (code == "KYCAUTH") {
      qd = IQuotationData(getLatestAddress("QD"));
      qd.setKycAuthAddress(val);

    } else {
      revert("Invalid param code");
    }
  }

  /**
   * @dev to generater proxy
   * @param _implementationAddress of the proxy
   */
  function _generateProxy(address _implementationAddress) internal returns (address) {
    OwnedUpgradeabilityProxy proxy = new OwnedUpgradeabilityProxy(_implementationAddress);
    return address(proxy);
  }

  /// @dev Sets the older versions of contract addresses as inactive and the latest one as active.
  function _changeAllAddress() internal {
    for (uint i = 0; i < allContractNames.length; i++) {
      contractsActive[allContractVersions[allContractNames[i]]] = true;
      Iupgradable up = Iupgradable(allContractVersions[allContractNames[i]]);
      up.changeDependentContractAddress();
    }
  }

  function canCall(uint _claimId) internal view returns (bool)
  {
    IClaimsData cd = IClaimsData(getLatestAddress("CD"));
    (, , , uint status, uint dateUpd,) = cd.getClaim(_claimId);
    if (status == 12) {
      if (dateUpd.add(cd.payoutRetryTime()) > now) {
        return false;
      }
    }
    return true;
  }
}

// File: contracts/mocks/Disposables/DisposableNXMaster.sol

pragma solidity ^0.5.0;


contract DisposableNXMaster is NXMaster {

  function initialize(
    address _owner,
    address _tokenAddress,
    uint _pauseTime,
    bytes2[] calldata _contractNames,
    uint8[] calldata _contractTypes, // 0 - eternal storage, 1 - "upgradable", 2 - proxy
    address payable[] calldata _contractAddresses
  ) external {

    require(!masterInitialized, "!init");
    masterInitialized = true;

    owner = _owner;
    tokenAddress = _tokenAddress;
    pauseTime = _pauseTime;

    masterAddress = address(this);
    contractsActive[address(this)] = true;

    require(
      _contractNames.length == _contractTypes.length,
      "check names & types arrays length"
    );

    for (uint i = 0; i < _contractNames.length; i++) {

      bytes2 name = _contractNames[i];
      address payable contractAddress = _contractAddresses[i];

      allContractNames.push(name);
      allContractVersions[name] = contractAddress;
      contractsActive[contractAddress] = true;

      if (_contractTypes[i] == 1) {
        isUpgradable[name] = true;
      } else if (_contractTypes[i] == 2) {
        isProxy[name] = true;
      }
    }
  }

  function switchGovernanceAddress(address payable newGV) external {

    {// change governance address
      address currentGV = allContractVersions["GV"];
      allContractVersions["GV"] = newGV;
      contractsActive[currentGV] = false;
      contractsActive[newGV] = true;
    }

    // notify all contracts about address change
    for (uint i = 0; i < allContractNames.length; i++) {
      address _address = allContractVersions[allContractNames[i]];
      Iupgradable up = Iupgradable(_address);
      up.changeMasterAddress(address(this));
      up.changeDependentContractAddress();
    }
  }

}