// SPDX-License-Identifier: MIT

// ChargedState.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IChargedState.sol";

import "./lib/Bitwise.sol";
import "./lib/TokenInfo.sol";
import "./lib/RelayRecipient.sol";
import "./lib/BlackholePrevention.sol";

/**
 * @notice Charged Particles Settings Contract
 */
contract ChargedState is
  IChargedState,
  Ownable,
  RelayRecipient,
  BlackholePrevention
{
  using SafeMath for uint256;
  using TokenInfo for address;
  using Bitwise for uint32;


  // NftState - actionPerms
  uint32 constant internal PERM_RESTRICT_ENERGIZE_FROM_ALL = 1;  // NFTs that have Restrictions on Energize
  uint32 constant internal PERM_ALLOW_DISCHARGE_FROM_ALL   = 2;  // NFTs that allow Discharge by anyone
  uint32 constant internal PERM_ALLOW_RELEASE_FROM_ALL     = 4;  // NFTs that allow Release by anyone
  uint32 constant internal PERM_RESTRICT_BOND_FROM_ALL     = 8;  // NFTs that have Restrictions on Covalent Bonds
  uint32 constant internal PERM_ALLOW_BREAK_BOND_FROM_ALL  = 16; // NFTs that allow Breaking Covalent Bonds by anyone

  struct NftTimelock {
    uint256 unlockBlock;
    address lockedBy;
  }

  struct NftState {
    uint32 actionPerms;

    NftTimelock dischargeTimelock;
    NftTimelock releaseTimelock;
    NftTimelock breakBondTimelock;
    uint256 tempLockExpiry;

    mapping (address => address) dischargeApproval;
    mapping (address => address) releaseApproval;
    mapping (address => address) breakBondApproval;
    mapping (address => address) timelockApproval;
  }

  IChargedSettings internal _chargedSettings;

  // State of individual NFTs (by Token UUID)
  mapping (uint256 => NftState) internal _nftState;


  /***********************************|
  |               Public              |
  |__________________________________*/

  function getDischargeTimelockExpiry(address contractAddress, uint256 tokenId) external view virtual override returns (uint256 lockExpiry) {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);

    if (_nftState[tokenUuid].dischargeTimelock.unlockBlock > block.number) {
      lockExpiry = _nftState[tokenUuid].dischargeTimelock.unlockBlock;
    }
    if (_nftState[tokenUuid].tempLockExpiry > block.number && _nftState[tokenUuid].tempLockExpiry > lockExpiry) {
      lockExpiry = _nftState[tokenUuid].tempLockExpiry;
    }
  }

  function getReleaseTimelockExpiry(address contractAddress, uint256 tokenId) external view virtual override returns (uint256 lockExpiry) {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);

    if (_nftState[tokenUuid].releaseTimelock.unlockBlock > block.number) {
      lockExpiry = _nftState[tokenUuid].releaseTimelock.unlockBlock;
    }
    if (_nftState[tokenUuid].tempLockExpiry > block.number && _nftState[tokenUuid].tempLockExpiry > lockExpiry) {
      lockExpiry = _nftState[tokenUuid].tempLockExpiry;
    }
  }

  function getBreakBondTimelockExpiry(address contractAddress, uint256 tokenId) external view virtual override returns (uint256 lockExpiry) {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);

    if (_nftState[tokenUuid].breakBondTimelock.unlockBlock > block.number) {
      lockExpiry = _nftState[tokenUuid].breakBondTimelock.unlockBlock;
    }
    if (_nftState[tokenUuid].tempLockExpiry > block.number && _nftState[tokenUuid].tempLockExpiry > lockExpiry) {
      lockExpiry = _nftState[tokenUuid].tempLockExpiry;
    }
  }


  /// @notice Checks if an operator is allowed to Discharge a specific Token
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the operator to check
  /// @return True if the operator is Approved
  function isApprovedForDischarge(address contractAddress, uint256 tokenId, address operator) external virtual override view returns (bool) {
    return _isApprovedForDischarge(contractAddress, tokenId, operator);
  }

  /// @notice Checks if an operator is allowed to Release a specific Token
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the operator to check
  /// @return True if the operator is Approved
  function isApprovedForRelease(address contractAddress, uint256 tokenId, address operator) external virtual override view returns (bool) {
    return _isApprovedForRelease(contractAddress, tokenId, operator);
  }

  /// @notice Checks if an operator is allowed to Break Covalent Bonds on a specific Token
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the operator to check
  /// @return True if the operator is Approved
  function isApprovedForBreakBond(address contractAddress, uint256 tokenId, address operator) external virtual override view returns (bool) {
    return _isApprovedForBreakBond(contractAddress, tokenId, operator);
  }

  /// @notice Checks if an operator is allowed to Timelock a specific Token
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the operator to check
  /// @return True if the operator is Approved
  function isApprovedForTimelock(address contractAddress, uint256 tokenId, address operator) external virtual override view returns (bool) {
    return _isApprovedForTimelock(contractAddress, tokenId, operator);
  }


  function isEnergizeRestricted(address contractAddress, uint256 tokenId) external virtual override view returns (bool) {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    return _nftState[tokenUuid].actionPerms.hasBit(PERM_RESTRICT_ENERGIZE_FROM_ALL);
  }


  function isCovalentBondRestricted(address contractAddress, uint256 tokenId) external virtual override view returns (bool) {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    return _nftState[tokenUuid].actionPerms.hasBit(PERM_RESTRICT_BOND_FROM_ALL);
  }


  function getDischargeState(address contractAddress, uint256 tokenId, address sender)
    external
    view
    virtual
    override
    returns (
      bool allowFromAll,
      bool isApproved,
      uint256 timelock,
      uint256 tempLockExpiry
    )
  {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    allowFromAll = _nftState[tokenUuid].actionPerms.hasBit(PERM_ALLOW_DISCHARGE_FROM_ALL);
    isApproved = _isApprovedForDischarge(contractAddress, tokenId, sender);
    timelock = _nftState[tokenUuid].dischargeTimelock.unlockBlock;
    tempLockExpiry = _nftState[tokenUuid].tempLockExpiry;
  }



  function getReleaseState(address contractAddress, uint256 tokenId, address sender)
    external
    view
    virtual
    override
    returns (
      bool allowFromAll,
      bool isApproved,
      uint256 timelock,
      uint256 tempLockExpiry
    )
  {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    allowFromAll = _nftState[tokenUuid].actionPerms.hasBit(PERM_ALLOW_RELEASE_FROM_ALL);
    isApproved = _isApprovedForRelease(contractAddress, tokenId, sender);
    timelock = _nftState[tokenUuid].releaseTimelock.unlockBlock;
    tempLockExpiry = _nftState[tokenUuid].tempLockExpiry;
  }



  function getBreakBondState(address contractAddress, uint256 tokenId, address sender)
    external
    view
    virtual
    override
    returns (
      bool allowFromAll,
      bool isApproved,
      uint256 timelock,
      uint256 tempLockExpiry
    )
  {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    allowFromAll = _nftState[tokenUuid].actionPerms.hasBit(PERM_ALLOW_BREAK_BOND_FROM_ALL);
    isApproved = _isApprovedForBreakBond(contractAddress, tokenId, sender);
    timelock = _nftState[tokenUuid].breakBondTimelock.unlockBlock;
    tempLockExpiry = _nftState[tokenUuid].tempLockExpiry;
  }




  /***********************************|
  |      Only NFT Owner/Operator      |
  |__________________________________*/

  /// @notice Sets an Operator as Approved to Discharge a specific Token
  /// This allows an operator to withdraw the interest-portion only
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the Operator to Approve
  function setDischargeApproval(
    address contractAddress,
    uint256 tokenId,
    address operator
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    require(operator != tokenOwner, "CP:E-106");
    _setDischargeApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @notice Sets an Operator as Approved to Release a specific Token
  /// This allows an operator to withdraw the principal + interest
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the Operator to Approve
  function setReleaseApproval(
    address contractAddress,
    uint256 tokenId,
    address operator
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    require(operator != tokenOwner, "CP:E-106");
    _setReleaseApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @notice Sets an Operator as Approved to Break Covalent Bonds on a specific Token
  /// This allows an operator to withdraw Basket NFTs
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the Operator to Approve
  function setBreakBondApproval(
    address contractAddress,
    uint256 tokenId,
    address operator
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    require(operator != tokenOwner, "CP:E-106");
    _setBreakBondApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @notice Sets an Operator as Approved to Timelock a specific Token
  /// This allows an operator to timelock the principal or interest
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the Operator to Approve
  function setTimelockApproval(
    address contractAddress,
    uint256 tokenId,
    address operator
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    require(operator != tokenOwner, "CP:E-106");
    _setTimelockApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @notice Sets an Operator as Approved to Discharge/Release/Timelock a specific Token
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param operator         The Address of the Operator to Approve
  function setApprovalForAll(
    address contractAddress,
    uint256 tokenId,
    address operator
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    require(operator != tokenOwner, "CP:E-106");
    _setDischargeApproval(contractAddress, tokenId, tokenOwner, operator);
    _setReleaseApproval(contractAddress, tokenId, tokenOwner, operator);
    _setBreakBondApproval(contractAddress, tokenId, tokenOwner, operator);
    _setTimelockApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @dev Updates Restrictions on Energizing an NFT
  function setPermsForRestrictCharge(address contractAddress, uint256 tokenId, bool state)
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    _setPermsForRestrictCharge(contractAddress, tokenId, state);
  }

  /// @dev Updates Allowance on Discharging an NFT by Anyone
  function setPermsForAllowDischarge(address contractAddress, uint256 tokenId, bool state)
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    _setPermsForAllowDischarge(contractAddress, tokenId, state);
  }

  /// @dev Updates Allowance on Discharging an NFT by Anyone
  function setPermsForAllowRelease(address contractAddress, uint256 tokenId, bool state)
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    _setPermsForAllowRelease(contractAddress, tokenId, state);
  }

  /// @dev Updates Restrictions on Covalent Bonds on an NFT
  function setPermsForRestrictBond(address contractAddress, uint256 tokenId, bool state)
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    _setPermsForRestrictBond(contractAddress, tokenId, state);
  }

  /// @dev Updates Allowance on Breaking Covalent Bonds on an NFT by Anyone
  function setPermsForAllowBreakBond(address contractAddress, uint256 tokenId, bool state)
    external
    virtual
    override
    onlyErc721OwnerOrOperator(contractAddress, tokenId, _msgSender())
  {
    _setPermsForAllowBreakBond(contractAddress, tokenId, state);
  }

  /// @notice Sets a Timelock on the ability to Discharge the Interest of a Particle
  /// @param contractAddress  The Address to the NFT to Timelock
  /// @param tokenId          The token ID of the NFT to Timelock
  /// @param unlockBlock      The Ethereum Block-number to Timelock until (~15 seconds per block)
  function setDischargeTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  )
    external
    override
    virtual
  {
    address sender = _msgSender();
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);

    // Clear Timelock
    if (unlockBlock == 0 && _nftState[tokenUuid].dischargeTimelock.lockedBy == sender) {
      delete _nftState[tokenUuid].dischargeTimelock.unlockBlock;
      delete _nftState[tokenUuid].dischargeTimelock.lockedBy;
    }

    // Set Timelock
    else {
      require(_isApprovedForTimelock(contractAddress, tokenId, sender), "CP:E-105");
      require(block.number >= _nftState[tokenUuid].dischargeTimelock.unlockBlock, "CP:E-302");

      _nftState[tokenUuid].dischargeTimelock.unlockBlock = unlockBlock;
      _nftState[tokenUuid].dischargeTimelock.lockedBy = sender;
    }

    emit TokenDischargeTimelock(contractAddress, tokenId, sender, unlockBlock);
  }

  /// @notice Sets a Timelock on the ability to Release the Assets of a Particle
  /// @param contractAddress  The Address to the NFT to Timelock
  /// @param tokenId          The token ID of the NFT to Timelock
  /// @param unlockBlock      The Ethereum Block-number to Timelock until (~15 seconds per block)
  function setReleaseTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  )
    external
    override
    virtual
  {
    address sender = _msgSender();
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);

    // Clear Timelock
    if (unlockBlock == 0 && _nftState[tokenUuid].releaseTimelock.lockedBy == sender) {
      delete _nftState[tokenUuid].releaseTimelock.unlockBlock;
      delete _nftState[tokenUuid].releaseTimelock.lockedBy;
    }

    // Set Timelock
    else {
      require(_isApprovedForTimelock(contractAddress, tokenId, sender), "CP:E-105");
      require(block.number >= _nftState[tokenUuid].releaseTimelock.unlockBlock, "CP:E-302");

      _nftState[tokenUuid].releaseTimelock.unlockBlock = unlockBlock;
      _nftState[tokenUuid].releaseTimelock.lockedBy = sender;
    }

    emit TokenReleaseTimelock(contractAddress, tokenId, sender, unlockBlock);
  }

  /// @notice Sets a Timelock on the ability to Break the Covalent Bond of a Particle
  /// @param contractAddress  The Address to the NFT to Timelock
  /// @param tokenId          The token ID of the NFT to Timelock
  /// @param unlockBlock      The Ethereum Block-number to Timelock until (~15 seconds per block)
  function setBreakBondTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  )
    external
    override
    virtual
  {
    address sender = _msgSender();
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);

    // Clear Timelock
    if (unlockBlock == 0 && _nftState[tokenUuid].breakBondTimelock.lockedBy == sender) {
      delete _nftState[tokenUuid].breakBondTimelock.unlockBlock;
      delete _nftState[tokenUuid].breakBondTimelock.lockedBy;
    }

    // Set Timelock
    else {
      require(_isApprovedForTimelock(contractAddress, tokenId, sender), "CP:E-105");
      require(block.number >= _nftState[tokenUuid].breakBondTimelock.unlockBlock, "CP:E-302");

      _nftState[tokenUuid].breakBondTimelock.unlockBlock = unlockBlock;
      _nftState[tokenUuid].breakBondTimelock.lockedBy = sender;
    }

    emit TokenBreakBondTimelock(contractAddress, tokenId, sender, unlockBlock);
  }


  /***********************************|
  |         Only NFT Contract         |
  |__________________________________*/

  /// @notice Sets a Temporary-Lock on the ability to Release/Discharge the Assets of a Particle
  /// @param contractAddress  The Address to the NFT to Timelock
  /// @param tokenId          The token ID of the NFT to Timelock
  /// @param isLocked         The locked state; contracts are expected to disable this lock before expiry
  function setTemporaryLock(
    address contractAddress,
    uint256 tokenId,
    bool isLocked
  )
    external
    override
    virtual
  {
    require(msg.sender == contractAddress, "CP:E-112");

    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    uint256 unlockBlock;
    if (isLocked && _nftState[tokenUuid].tempLockExpiry == 0) {
      unlockBlock = block.number.add(_chargedSettings.getTempLockExpiryBlocks());
      _nftState[tokenUuid].tempLockExpiry = unlockBlock;
    }
    if (!isLocked) {
      _nftState[tokenUuid].tempLockExpiry = 0;
    }

    emit TokenTempLock(contractAddress, tokenId, unlockBlock);
  }


  /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

  /// @dev Setup the Charged-Settings Controller
  function setChargedSettings(address settingsController) external virtual onlyOwner {
    _chargedSettings = IChargedSettings(settingsController);
    emit ChargedSettingsSet(settingsController);
  }

  function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
    trustedForwarder = _trustedForwarder;
  }

  /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external virtual onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external virtual onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external virtual onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }


  /***********************************|
  |         Private Functions         |
  |__________________________________*/

  /// @dev See {ChargedParticles-isApprovedForDischarge}.
  function _isApprovedForDischarge(address contractAddress, uint256 tokenId, address operator) internal view virtual returns (bool) {
    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    return contractAddress == operator || tokenOwner == operator || _nftState[tokenUuid].dischargeApproval[tokenOwner] == operator;
  }

  /// @dev See {ChargedParticles-isApprovedForRelease}.
  function _isApprovedForRelease(address contractAddress, uint256 tokenId, address operator) internal view virtual returns (bool) {
    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    return contractAddress == operator || tokenOwner == operator || _nftState[tokenUuid].releaseApproval[tokenOwner] == operator;
  }

  /// @dev See {ChargedParticles-isApprovedForBreakBond}.
  function _isApprovedForBreakBond(address contractAddress, uint256 tokenId, address operator) internal view virtual returns (bool) {
    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    return contractAddress == operator || tokenOwner == operator || _nftState[tokenUuid].breakBondApproval[tokenOwner] == operator;
  }

  /// @dev See {ChargedParticles-isApprovedForTimelock}.
  function _isApprovedForTimelock(address contractAddress, uint256 tokenId, address operator) internal view virtual returns (bool) {
    (bool timelockAny, bool timelockOwn) = _chargedSettings.getTimelockApprovals(operator);
    if (timelockAny || (timelockOwn && contractAddress == operator)) { return true; }

    address tokenOwner = contractAddress.getTokenOwner(tokenId);
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    return tokenOwner == operator || _nftState[tokenUuid].timelockApproval[tokenOwner] == operator;
  }

  /// @notice Sets an Operator as Approved to Discharge a specific Token
  /// This allows an operator to withdraw the interest-portion only
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param tokenOwner       The Owner Address of the Token
  /// @param operator         The Address of the Operator to Approve
  function _setDischargeApproval(
    address contractAddress,
    uint256 tokenId,
    address tokenOwner,
    address operator
  )
    internal
    virtual
  {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    _nftState[tokenUuid].dischargeApproval[tokenOwner] = operator;
    emit DischargeApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @notice Sets an Operator as Approved to Release a specific Token
  /// This allows an operator to withdraw the principal + interest
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param tokenOwner       The Owner Address of the Token
  /// @param operator         The Address of the Operator to Approve
  function _setReleaseApproval(
    address contractAddress,
    uint256 tokenId,
    address tokenOwner,
    address operator
  )
    internal
    virtual
  {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    _nftState[tokenUuid].releaseApproval[tokenOwner] = operator;
    emit ReleaseApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @notice Sets an Operator as Approved to Break Covalent Bonds on a specific Token
  /// This allows an operator to withdraw Basket NFTs
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param tokenOwner       The Owner Address of the Token
  /// @param operator         The Address of the Operator to Approve
  function _setBreakBondApproval(
    address contractAddress,
    uint256 tokenId,
    address tokenOwner,
    address operator
  )
    internal
    virtual
  {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    _nftState[tokenUuid].breakBondApproval[tokenOwner] = operator;
    emit BreakBondApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @notice Sets an Operator as Approved to Timelock a specific Token
  /// This allows an operator to timelock the principal or interest
  /// @param contractAddress  The Address to the Contract of the Token
  /// @param tokenId          The ID of the Token
  /// @param tokenOwner       The Owner Address of the Token
  /// @param operator         The Address of the Operator to Approve
  function _setTimelockApproval(
    address contractAddress,
    uint256 tokenId,
    address tokenOwner,
    address operator
  )
    internal
    virtual
  {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    _nftState[tokenUuid].timelockApproval[tokenOwner] = operator;
    emit TimelockApproval(contractAddress, tokenId, tokenOwner, operator);
  }

  /// @dev Updates Restrictions on Energizing an NFT
  function _setPermsForRestrictCharge(address contractAddress, uint256 tokenId, bool state) internal virtual {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    if (state) {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.setBit(PERM_RESTRICT_ENERGIZE_FROM_ALL);
    } else {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.clearBit(PERM_RESTRICT_ENERGIZE_FROM_ALL);
    }
    emit PermsSetForRestrictCharge(contractAddress, tokenId, state);
  }

  /// @dev Updates Allowance on Discharging an NFT by Anyone
  function _setPermsForAllowDischarge(address contractAddress, uint256 tokenId, bool state) internal virtual {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    if (state) {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.setBit(PERM_ALLOW_DISCHARGE_FROM_ALL);
    } else {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.clearBit(PERM_ALLOW_DISCHARGE_FROM_ALL);
    }
    emit PermsSetForAllowDischarge(contractAddress, tokenId, state);
  }

  /// @dev Updates Allowance on Discharging an NFT by Anyone
  function _setPermsForAllowRelease(address contractAddress, uint256 tokenId, bool state) internal virtual {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    if (state) {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.setBit(PERM_ALLOW_RELEASE_FROM_ALL);
    } else {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.clearBit(PERM_ALLOW_RELEASE_FROM_ALL);
    }
    emit PermsSetForAllowRelease(contractAddress, tokenId, state);
  }

  /// @dev Updates Restrictions on Covalent Bonds on an NFT
  function _setPermsForRestrictBond(address contractAddress, uint256 tokenId, bool state) internal virtual {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    if (state) {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.setBit(PERM_RESTRICT_BOND_FROM_ALL);
    } else {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.clearBit(PERM_RESTRICT_BOND_FROM_ALL);
    }
    emit PermsSetForRestrictBond(contractAddress, tokenId, state);
  }

  /// @dev Updates Allowance on Breaking Covalent Bonds on an NFT by Anyone
  function _setPermsForAllowBreakBond(address contractAddress, uint256 tokenId, bool state) internal virtual {
    uint256 tokenUuid = contractAddress.getTokenUUID(tokenId);
    if (state) {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.setBit(PERM_ALLOW_BREAK_BOND_FROM_ALL);
    } else {
      _nftState[tokenUuid].actionPerms = _nftState[tokenUuid].actionPerms.clearBit(PERM_ALLOW_BREAK_BOND_FROM_ALL);
    }
    emit PermsSetForAllowBreakBond(contractAddress, tokenId, state);
  }


  /***********************************|
  |          GSN/MetaTx Relay         |
  |__________________________________*/

  /// @dev See {BaseRelayRecipient-_msgSender}.
  function _msgSender()
    internal
    view
    virtual
    override(BaseRelayRecipient, Context)
    returns (address payable)
  {
    return BaseRelayRecipient._msgSender();
  }

  /// @dev See {BaseRelayRecipient-_msgData}.
  function _msgData()
    internal
    view
    virtual
    override(BaseRelayRecipient, Context)
    returns (bytes memory)
  {
    return BaseRelayRecipient._msgData();
  }


  /***********************************|
  |             Modifiers             |
  |__________________________________*/

  modifier onlyErc721OwnerOrOperator(address contractAddress, uint256 tokenId, address sender) {
    require(contractAddress.isErc721OwnerOrOperator(tokenId, sender), "CP:E-105");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// IChargedSettings.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.6.0;

import "./IChargedSettings.sol";

/**
 * @notice Interface for Charged State
 */
interface IChargedState {

  /***********************************|
  |             Public API            |
  |__________________________________*/

  function getDischargeTimelockExpiry(address contractAddress, uint256 tokenId) external view returns (uint256 lockExpiry);
  function getReleaseTimelockExpiry(address contractAddress, uint256 tokenId) external view returns (uint256 lockExpiry);
  function getBreakBondTimelockExpiry(address contractAddress, uint256 tokenId) external view returns (uint256 lockExpiry);

  function isApprovedForDischarge(address contractAddress, uint256 tokenId, address operator) external view returns (bool);
  function isApprovedForRelease(address contractAddress, uint256 tokenId, address operator) external view returns (bool);
  function isApprovedForBreakBond(address contractAddress, uint256 tokenId, address operator) external view returns (bool);
  function isApprovedForTimelock(address contractAddress, uint256 tokenId, address operator) external view returns (bool);

  function isEnergizeRestricted(address contractAddress, uint256 tokenId) external view returns (bool);
  function isCovalentBondRestricted(address contractAddress, uint256 tokenId) external view returns (bool);

  function getDischargeState(address contractAddress, uint256 tokenId, address sender) external view
    returns (bool allowFromAll, bool isApproved, uint256 timelock, uint256 tempLockExpiry);
  function getReleaseState(address contractAddress, uint256 tokenId, address sender) external view
    returns (bool allowFromAll, bool isApproved, uint256 timelock, uint256 tempLockExpiry);
  function getBreakBondState(address contractAddress, uint256 tokenId, address sender) external view
    returns (bool allowFromAll, bool isApproved, uint256 timelock, uint256 tempLockExpiry);

  /***********************************|
  |      Only NFT Owner/Operator      |
  |__________________________________*/

  function setDischargeApproval(address contractAddress, uint256 tokenId, address operator) external;
  function setReleaseApproval(address contractAddress, uint256 tokenId, address operator) external;
  function setBreakBondApproval(address contractAddress, uint256 tokenId, address operator) external;
  function setTimelockApproval(address contractAddress, uint256 tokenId, address operator) external;
  function setApprovalForAll(address contractAddress, uint256 tokenId, address operator) external;

  function setPermsForRestrictCharge(address contractAddress, uint256 tokenId, bool state) external;
  function setPermsForAllowDischarge(address contractAddress, uint256 tokenId, bool state) external;
  function setPermsForAllowRelease(address contractAddress, uint256 tokenId, bool state) external;
  function setPermsForRestrictBond(address contractAddress, uint256 tokenId, bool state) external;
  function setPermsForAllowBreakBond(address contractAddress, uint256 tokenId, bool state) external;

  function setDischargeTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  ) external;

  function setReleaseTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  ) external;

  function setBreakBondTimelock(
    address contractAddress,
    uint256 tokenId,
    uint256 unlockBlock
  ) external;

  /***********************************|
  |         Only NFT Contract         |
  |__________________________________*/

  function setTemporaryLock(
    address contractAddress,
    uint256 tokenId,
    bool isLocked
  ) external;

  /***********************************|
  |          Particle Events          |
  |__________________________________*/

  event ChargedSettingsSet(address indexed settingsController);

  event DischargeApproval(address indexed contractAddress, uint256 indexed tokenId, address indexed owner, address operator);
  event ReleaseApproval(address indexed contractAddress, uint256 indexed tokenId, address indexed owner, address operator);
  event BreakBondApproval(address indexed contractAddress, uint256 indexed tokenId, address indexed owner, address operator);
  event TimelockApproval(address indexed contractAddress, uint256 indexed tokenId, address indexed owner, address operator);

  event TokenDischargeTimelock(address indexed contractAddress, uint256 indexed tokenId, address indexed operator, uint256 unlockBlock);
  event TokenReleaseTimelock(address indexed contractAddress, uint256 indexed tokenId, address indexed operator, uint256 unlockBlock);
  event TokenBreakBondTimelock(address indexed contractAddress, uint256 indexed tokenId, address indexed operator, uint256 unlockBlock);
  event TokenTempLock(address indexed contractAddress, uint256 indexed tokenId, uint256 unlockBlock);

  event PermsSetForRestrictCharge(address indexed contractAddress, uint256 indexed tokenId, bool state);
  event PermsSetForAllowDischarge(address indexed contractAddress, uint256 indexed tokenId, bool state);
  event PermsSetForAllowRelease(address indexed contractAddress, uint256 indexed tokenId, bool state);
  event PermsSetForRestrictBond(address indexed contractAddress, uint256 indexed tokenId, bool state);
  event PermsSetForAllowBreakBond(address indexed contractAddress, uint256 indexed tokenId, bool state);
}

// SPDX-License-Identifier: MIT

// Bitwise.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.12;

library Bitwise {
  function negate(uint32 a) internal pure returns (uint32) {
    return a ^ maxInt();
  }

  function shiftLeft(uint32 a, uint32 n) internal pure returns (uint32) {
    return a * uint32(2) ** n;
  }

  function shiftRight(uint32 a, uint32 n) internal pure returns (uint32) {
    return a / uint32(2) ** n;
  }

  function maxInt() internal pure returns (uint32) {
    return uint32(-1);
  }

  // Get bit value at position
  function hasBit(uint32 a, uint32 n) internal pure returns (bool) {
    return a & shiftLeft(0x01, n) != 0;
  }

  // Set bit value at position
  function setBit(uint32 a, uint32 n) internal pure returns (uint32) {
    return a | shiftLeft(0x01, n);
  }

  // Set the bit into state "false"
  function clearBit(uint32 a, uint32 n) internal pure returns (uint32) {
    uint32 mask = negate(shiftLeft(0x01, n));
    return a & mask;
  }
}

// SPDX-License-Identifier: MIT

// TokenInfo.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IERC721Chargeable.sol";

library TokenInfo {
  function getTokenUUID(address contractAddress, uint256 tokenId) internal pure virtual returns (uint256) {
    return uint256(keccak256(abi.encodePacked(contractAddress, tokenId)));
  }

  function getTokenOwner(address contractAddress, uint256 tokenId) internal view virtual returns (address) {
    IERC721Chargeable tokenInterface = IERC721Chargeable(contractAddress);
    return tokenInterface.ownerOf(tokenId);
  }

  function getTokenCreator(address contractAddress, uint256 tokenId) internal view virtual returns (address) {
    IERC721Chargeable tokenInterface = IERC721Chargeable(contractAddress);
    return tokenInterface.creatorOf(tokenId);
  }

  /// @dev Checks if an account is the Owner of an External NFT contract
  /// @param contractAddress  The Address to the Contract of the NFT to check
  /// @param account          The Address of the Account to check
  /// @return True if the account owns the contract
  function isContractOwner(address contractAddress, address account) internal view virtual returns (bool) {
    address contractOwner = IERC721Chargeable(contractAddress).owner();
    return contractOwner != address(0x0) && contractOwner == account;
  }

  /// @dev Checks if an account is the Creator of a Proton-based NFT
  /// @param contractAddress  The Address to the Contract of the Proton-based NFT to check
  /// @param tokenId          The Token ID of the Proton-based NFT to check
  /// @param sender           The Address of the Account to check
  /// @return True if the account is the creator of the Proton-based NFT
  function isTokenCreator(address contractAddress, uint256 tokenId, address sender) internal view virtual returns (bool) {
    IERC721Chargeable tokenInterface = IERC721Chargeable(contractAddress);
    address tokenCreator = tokenInterface.creatorOf(tokenId);
    return (sender == tokenCreator);
  }

  /// @dev Checks if an account is the Creator of a Proton-based NFT or the Contract itself
  /// @param contractAddress  The Address to the Contract of the Proton-based NFT to check
  /// @param tokenId          The Token ID of the Proton-based NFT to check
  /// @param sender           The Address of the Account to check
  /// @return True if the account is the creator of the Proton-based NFT or the Contract itself
  function isTokenContractOrCreator(address contractAddress, uint256 tokenId, address creator, address sender) internal view virtual returns (bool) {
    IERC721Chargeable tokenInterface = IERC721Chargeable(contractAddress);
    address tokenCreator = tokenInterface.creatorOf(tokenId);
    if (sender == contractAddress && creator == tokenCreator) { return true; }
    return (sender == tokenCreator);
  }

  /// @dev Checks if an account is the Owner or Operator of an External NFT
  /// @param contractAddress  The Address to the Contract of the External NFT to check
  /// @param tokenId          The Token ID of the External NFT to check
  /// @param sender           The Address of the Account to check
  /// @return True if the account is the Owner or Operator of the External NFT
  function isErc721OwnerOrOperator(address contractAddress, uint256 tokenId, address sender) internal view virtual returns (bool) {
    IERC721Chargeable tokenInterface = IERC721Chargeable(contractAddress);
    address tokenOwner = tokenInterface.ownerOf(tokenId);
    return (sender == tokenOwner || tokenInterface.isApprovedForAll(tokenOwner, sender));
  }

  /**
    * @dev Returns true if `account` is a contract.
    * @dev Taken from OpenZeppelin library
    *
    * [IMPORTANT]
    * ====
    * It is unsafe to assume that an address for which this function returns
    * false is an externally-owned account (EOA) and not a contract.
    *
    * Among others, `isContract` will return false for the following
    * types of addresses:
    *
    *  - an externally-owned account
    *  - a contract in construction
    *  - an address where a contract will be created
    *  - an address where a contract lived, but was destroyed
    * ====
    */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly { codehash := extcodehash(account) }
    return (codehash != accountHash && codehash != 0x0);
  }

  /**
    * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
    * `recipient`, forwarding all available gas and reverting on errors.
    * @dev Taken from OpenZeppelin library
    *
    * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
    * of certain opcodes, possibly making contracts go over the 2300 gas limit
    * imposed by `transfer`, making them unable to receive funds via
    * `transfer`. {sendValue} removes this limitation.
    *
    * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
    *
    * IMPORTANT: because control is transferred to `recipient`, care must be
    * taken to not create reentrancy vulnerabilities. Consider using
    * {ReentrancyGuard} or the
    * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
    */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "TokenInfo: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "TokenInfo: unable to send value, recipient may have reverted");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";

contract RelayRecipient is BaseRelayRecipient {
  function versionRecipient() external override view returns (string memory) {
    return "1.0.0-beta.1/charged-particles.relay.recipient";
  }
}

// SPDX-License-Identifier: MIT

// BlackholePrevention.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice Prevents ETH or Tokens from getting stuck in a contract by allowing
 *  the Owner/DAO to pull them out on behalf of a user
 * This is only meant to contracts that are not expected to hold tokens, but do handle transferring them.
 */
contract BlackholePrevention {
  using Address for address payable;
  using SafeERC20 for IERC20;

  event WithdrawStuckEther(address indexed receiver, uint256 amount);
  event WithdrawStuckERC20(address indexed receiver, address indexed tokenAddress, uint256 amount);
  event WithdrawStuckERC721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);

  function _withdrawEther(address payable receiver, uint256 amount) internal virtual {
    require(receiver != address(0x0), "BHP:E-403");
    if (address(this).balance >= amount) {
      receiver.sendValue(amount);
      emit WithdrawStuckEther(receiver, amount);
    }
  }

  function _withdrawERC20(address payable receiver, address tokenAddress, uint256 amount) internal virtual {
    require(receiver != address(0x0), "BHP:E-403");
    if (IERC20(tokenAddress).balanceOf(address(this)) >= amount) {
      IERC20(tokenAddress).safeTransfer(receiver, amount);
      emit WithdrawStuckERC20(receiver, tokenAddress, amount);
    }
  }

  function _withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) internal virtual {
    require(receiver != address(0x0), "BHP:E-403");
    if (IERC721(tokenAddress).ownerOf(tokenId) == address(this)) {
      IERC721(tokenAddress).transferFrom(address(this), receiver, tokenId);
      emit WithdrawStuckERC721(receiver, tokenAddress, tokenId);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

// IChargedSettings.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.6.0;

import "./IWalletManager.sol";
import "./IBasketManager.sol";

/**
 * @notice Interface for Charged Settings
 */
interface IChargedSettings {

  /***********************************|
  |             Public API            |
  |__________________________________*/

  function isContractOwner(address contractAddress, address account) external view returns (bool);
  function getCreatorAnnuities(address contractAddress, uint256 tokenId) external view returns (address creator, uint256 annuityPct);
  function getCreatorAnnuitiesRedirect(address contractAddress, uint256 tokenId) external view returns (address);
  function getTempLockExpiryBlocks() external view returns (uint256);
  function getTimelockApprovals(address operator) external view returns (bool timelockAny, bool timelockOwn);
  function getAssetRequirements(address contractAddress, address assetToken) external view
    returns (string memory requiredWalletManager, bool energizeEnabled, bool restrictedAssets, bool validAsset, uint256 depositCap, uint256 depositMin, uint256 depositMax);
  function getNftAssetRequirements(address contractAddress, address nftTokenAddress) external view
    returns (string memory requiredBasketManager, bool basketEnabled, uint256 maxNfts);

  // ERC20
  function isWalletManagerEnabled(string calldata walletManagerId) external view returns (bool);
  function getWalletManager(string calldata walletManagerId) external view returns (IWalletManager);

  // ERC721
  function isNftBasketEnabled(string calldata basketId) external view returns (bool);
  function getBasketManager(string calldata basketId) external view returns (IBasketManager);

  /***********************************|
  |         Only NFT Creator          |
  |__________________________________*/

  function setCreatorAnnuities(address contractAddress, uint256 tokenId, address creator, uint256 annuityPercent) external;
  function setCreatorAnnuitiesRedirect(address contractAddress, uint256 tokenId, address creator, address receiver) external;


  /***********************************|
  |      Only NFT Contract Owner      |
  |__________________________________*/

  function setRequiredWalletManager(address contractAddress, string calldata walletManager) external;
  function setRequiredBasketManager(address contractAddress, string calldata basketManager) external;
  function setAssetTokenRestrictions(address contractAddress, bool restrictionsEnabled) external;
  function setAllowedAssetToken(address contractAddress, address assetToken, bool isAllowed) external;
  function setAssetTokenLimits(address contractAddress, address assetToken, uint256 depositMin, uint256 depositMax) external;
  function setMaxNfts(address contractAddress, address nftTokenAddress, uint256 maxNfts) external;

  /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

  function enableNftContracts(address[] calldata contracts) external;
  function setPermsForCharge(address contractAddress, bool state) external;
  function setPermsForBasket(address contractAddress, bool state) external;
  function setPermsForTimelockAny(address contractAddress, bool state) external;
  function setPermsForTimelockSelf(address contractAddress, bool state) external;

  /***********************************|
  |          Particle Events          |
  |__________________________________*/

  event DepositCapSet(address assetToken, uint256 depositCap);
  event TempLockExpirySet(uint256 expiryBlocks);

  event WalletManagerRegistered(string indexed walletManagerId, address indexed walletManager);
  event BasketManagerRegistered(string indexed basketId, address indexed basketManager);

  event RequiredWalletManagerSet(address indexed contractAddress, string walletManager);
  event RequiredBasketManagerSet(address indexed contractAddress, string basketManager);
  event AssetTokenRestrictionsSet(address indexed contractAddress, bool restrictionsEnabled);
  event AllowedAssetTokenSet(address indexed contractAddress, address assetToken, bool isAllowed);
  event AssetTokenLimitsSet(address indexed contractAddress, address assetToken, uint256 assetDepositMin, uint256 assetDepositMax);
  event MaxNftsSet(address indexed contractAddress, address indexed nftTokenAddress, uint256 maxNfts);

  event TokenCreatorConfigsSet(address indexed contractAddress, uint256 indexed tokenId, address indexed creatorAddress, uint256 annuityPercent);
  event TokenCreatorAnnuitiesRedirected(address indexed contractAddress, uint256 indexed tokenId, address indexed redirectAddress);

  event PermsSetForCharge(address indexed contractAddress, bool state);
  event PermsSetForBasket(address indexed contractAddress, bool state);
  event PermsSetForTimelockAny(address indexed contractAddress, bool state);
  event PermsSetForTimelockSelf(address indexed contractAddress, bool state);
}

// SPDX-License-Identifier: MIT

// IWalletManager.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.6.0;

/**
 * @title Particle Wallet Manager interface
 * @dev The wallet-manager for underlying assets attached to Charged Particles
 * @dev Manages the link between NFTs and their respective Smart-Wallets
 */
interface IWalletManager {

  event ControllerSet(address indexed controller);
  event PausedStateSet(bool isPaused);
  event NewSmartWallet(address indexed contractAddress, uint256 indexed tokenId, address indexed smartWallet, address creator, uint256 annuityPct);
  event WalletEnergized(address indexed contractAddress, uint256 indexed tokenId, address indexed assetToken, uint256 assetAmount, uint256 yieldTokensAmount);
  event WalletDischarged(address indexed contractAddress, uint256 indexed tokenId, address indexed assetToken, uint256 creatorAmount, uint256 receiverAmount);
  event WalletDischargedForCreator(address indexed contractAddress, uint256 indexed tokenId, address indexed assetToken, address creator, uint256 receiverAmount);
  event WalletReleased(address indexed contractAddress, uint256 indexed tokenId, address indexed receiver, address assetToken, uint256 principalAmount, uint256 creatorAmount, uint256 receiverAmount);
  event WalletRewarded(address indexed contractAddress, uint256 indexed tokenId, address indexed receiver, address rewardsToken, uint256 rewardsAmount);

  function isPaused() external view returns (bool);

  function isReserveActive(address contractAddress, uint256 tokenId, address assetToken) external view returns (bool);
  function getReserveInterestToken(address contractAddress, uint256 tokenId, address assetToken) external view returns (address);

  function getTotal(address contractAddress, uint256 tokenId, address assetToken) external returns (uint256);
  function getPrincipal(address contractAddress, uint256 tokenId, address assetToken) external returns (uint256);
  function getInterest(address contractAddress, uint256 tokenId, address assetToken) external returns (uint256 creatorInterest, uint256 ownerInterest);
  function getRewards(address contractAddress, uint256 tokenId, address rewardToken) external returns (uint256);

  function energize(address contractAddress, uint256 tokenId, address assetToken, uint256 assetAmount) external returns (uint256 yieldTokensAmount);
  function discharge(address receiver, address contractAddress, uint256 tokenId, address assetToken, address creatorRedirect) external returns (uint256 creatorAmount, uint256 receiverAmount);
  function dischargeAmount(address receiver, address contractAddress, uint256 tokenId, address assetToken, uint256 assetAmount, address creatorRedirect) external returns (uint256 creatorAmount, uint256 receiverAmount);
  function dischargeAmountForCreator(address receiver, address contractAddress, uint256 tokenId, address creator, address assetToken, uint256 assetAmount) external returns (uint256 receiverAmount);
  function release(address receiver, address contractAddress, uint256 tokenId, address assetToken, address creatorRedirect) external returns (uint256 principalAmount, uint256 creatorAmount, uint256 receiverAmount);
  function releaseAmount(address receiver, address contractAddress, uint256 tokenId, address assetToken, uint256 assetAmount, address creatorRedirect) external returns (uint256 principalAmount, uint256 creatorAmount, uint256 receiverAmount);
  function withdrawRewards(address receiver, address contractAddress, uint256 tokenId, address rewardsToken, uint256 rewardsAmount) external returns (uint256 amount);
  function executeForAccount(address contractAddress, uint256 tokenId, address externalAddress, uint256 ethValue, bytes memory encodedParams) external returns (bytes memory);
  function getWalletAddressById(address contractAddress, uint256 tokenId, address creator, uint256 annuityPct) external returns (address);

  function withdrawEther(address contractAddress, uint256 tokenId, address payable receiver, uint256 amount) external;
  function withdrawERC20(address contractAddress, uint256 tokenId, address payable receiver, address tokenAddress, uint256 amount) external;
  function withdrawERC721(address contractAddress, uint256 tokenId, address payable receiver, address nftTokenAddress, uint256 nftTokenId) external;
}

// SPDX-License-Identifier: MIT

// IBasketManager.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.6.0;

/**
 * @title Particle Basket Manager interface
 * @dev The basket-manager for underlying assets attached to Charged Particles
 * @dev Manages the link between NFTs and their respective Smart-Baskets
 */
interface IBasketManager {

  event ControllerSet(address indexed controller);
  event PausedStateSet(bool isPaused);
  event NewSmartBasket(address indexed contractAddress, uint256 indexed tokenId, address indexed smartBasket);
  event BasketAdd(address indexed contractAddress, uint256 indexed tokenId, address basketTokenAddress, uint256 basketTokenId);
  event BasketRemove(address indexed receiver, address indexed contractAddress, uint256 indexed tokenId, address basketTokenAddress, uint256 basketTokenId);

  function isPaused() external view returns (bool);

  function getTokenTotalCount(address contractAddress, uint256 tokenId) external view returns (uint256);
  function getTokenCountByType(address contractAddress, uint256 tokenId, address basketTokenAddress, uint256 basketTokenId) external returns (uint256);

  function addToBasket(address contractAddress, uint256 tokenId, address basketTokenAddress, uint256 basketTokenId) external returns (bool);
  function removeFromBasket(address receiver, address contractAddress, uint256 tokenId, address basketTokenAddress, uint256 basketTokenId) external returns (bool);
  function executeForAccount(address contractAddress, uint256 tokenId, address externalAddress, uint256 ethValue, bytes memory encodedParams) external returns (bytes memory);
  function getBasketAddressById(address contractAddress, uint256 tokenId) external returns (address);

  function withdrawEther(address contractAddress, uint256 tokenId, address payable receiver, uint256 amount) external;
  function withdrawERC20(address contractAddress, uint256 tokenId, address payable receiver, address tokenAddress, uint256 amount) external;
  function withdrawERC721(address contractAddress, uint256 tokenId, address payable receiver, address nftTokenAddress, uint256 nftTokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

// IERC721Chargeable.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.6.0;

import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

interface IERC721Chargeable is IERC165Upgradeable {
    function owner() external view returns (address);
    function creatorOf(uint256 tokenId) external view returns (address);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address tokenOwner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address tokenOwner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly
pragma solidity ^0.6.2;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(),20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr,32), size)
                calldatacopy(add(ptr,64), 0, size)
                return(ptr, add(size,64))
            }
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}