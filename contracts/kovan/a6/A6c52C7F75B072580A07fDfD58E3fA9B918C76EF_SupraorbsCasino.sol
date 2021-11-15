// SPDX-License-Identifier: MIT

// Gem.sol -- Part of Supraorbs Casino
// Copyright (c) 2021 WSCF Global, Inc. <https://wscf.io>

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/ISupraorbsCasino.sol";
import "./interfaces/IGem.sol";

import "./lib/Bitwise.sol";
import "./lib/TokenInfo.sol";
//import "./lib/RelayRecipient.sol";
import "./lib/BlackholePrevention.sol";


contract SupraorbsCasino is ISupraorbsCasino, Ownable, BlackholePrevention
{
  using SafeMath for uint256;
  using Address for address payable;
  using TokenInfo for address;
  using Bitwise for uint32;

  enum ORBS { SlotMachine, Roullette, Baccarat }

  uint256 constant internal GEM_RELEASE_LOCK_TIME = 2024033841;
  uint16 constant internal BLOCK_TIME = 15;
  
  struct Orb {
    address createdBy;
    uint256 gemChips;
    uint256 gameChips;
  }

  struct OrbState {
    Orb slotMachine;
    Orb roullette;
    Orb baccarat;

    mapping (ORBS => bool) isPlaying;
  }

  IGem internal _gem;

  // State of individual NFTs (by Token UUID)
  mapping (uint256 => OrbState) internal _orbState;

  /***********************************|
  |             Public API            |
  |__________________________________*/ 


  function getSlotMachineOrb(uint256 tokenId) external view virtual override returns(
    uint256 gemChips,
    uint256 gameChips,
    bool isPlaying
  ) 
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.SlotMachine];
    gemChips = _orbState[tokenUuid].slotMachine.gemChips;
    gameChips = _orbState[tokenUuid].slotMachine.gameChips;
  }

  function getRoulletteOrb(uint256 tokenId) external view virtual override returns(
    uint256 gemChips,
    uint256 gameChips,
    bool isPlaying
  ) 
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.Roullette];
    gemChips = _orbState[tokenUuid].roullette.gemChips;
    gameChips = _orbState[tokenUuid].roullette.gameChips;
  }

  function getBaccaratOrb(uint256 tokenId) external view virtual override returns(
    uint256 gemChips,
    uint256 gameChips,
    bool isPlaying
  ) 
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.Baccarat];
    gemChips = _orbState[tokenUuid].baccarat.gemChips;
    gameChips = _orbState[tokenUuid].baccarat.gameChips;
  }

  /***********************************|
  |      Only NFT Owner/Operator      |
  |__________________________________*/

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function enterSlotMachineOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, msg.sender)
    returns(bool isPlaying)
  {
    isPlaying = _enterSlotMachineOrb(tokenId, walletManagerId, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function enterRoulletteOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, msg.sender)
    returns(bool isPlaying)
  {
    isPlaying = _enterRoulletteOrb(tokenId, walletManagerId, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function enterBaccaratOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, msg.sender)
    returns(bool isPlaying)
  {
    isPlaying = _enterBaccaratOrb(tokenId, walletManagerId, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function exitSlotMachineOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, msg.sender)
    returns(uint256 gemChips)
  {
    gemChips = _exitSlotMachineOrb(tokenId, walletManagerId, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function exitRoulletteOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, msg.sender)
    returns(uint256 gemChips)
  {
    gemChips = _exitRoulletteOrb(tokenId, walletManagerId, chipsCoin);
  }

  /// @param tokenId          The ID of the Token
  /// @param walletManagerId          Name of the NFT wallet
  /// @param chipsCoin          Asset in NFT wallet
  function exitBaccaratOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    external
    virtual
    override
    onlyErc721OwnerOrOperator(tokenId, msg.sender)
    returns(uint256 gemChips)
  {
    gemChips = _exitBaccaratOrb(tokenId, walletManagerId, chipsCoin);
  }

  /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }


  /***********************************|
  |         Private Functions         |
  |__________________________________*/

  function _enterSlotMachineOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    internal
    virtual
    returns(bool isPlaying)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(!_orbState[tokenUuid].isPlaying[ORBS.SlotMachine], "ORB:E-106");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    require(chipsBalance > 0, "ORB:E-107");
    _orbState[tokenUuid].slotMachine.gemChips = chipsBalance;
    _orbState[tokenUuid].slotMachine.gameChips = chipsBalance;
    _orbState[tokenUuid].slotMachine.createdBy = msg.sender;
    uint256 unlockBlock = block.number.add((GEM_RELEASE_LOCK_TIME.sub(block.timestamp)).div(BLOCK_TIME));
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.SlotMachine] = true;
    _gem.setReleaseTimeLock(tokenId, unlockBlock);
    //return orb state
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.SlotMachine];
    emit EnterSlotMachineOrb(msg.sender, tokenId, chipsBalance);
  }

  function _enterRoulletteOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    internal
    virtual
    returns(bool isPlaying)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(!_orbState[tokenUuid].isPlaying[ORBS.Roullette], "ORB:E-106");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    require(chipsBalance > 0, "ORB:E-107");
    _orbState[tokenUuid].roullette.gemChips = chipsBalance;
    _orbState[tokenUuid].roullette.gameChips = chipsBalance;
    _orbState[tokenUuid].roullette.createdBy = msg.sender;
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.add((GEM_RELEASE_LOCK_TIME.sub(block.timestamp)).div(BLOCK_TIME));
    _gem.setReleaseTimeLock(tokenId, unlockBlock);
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.Roullette] = true;
    //return orb state
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.Roullette];
    emit EnterRoulletteOrb(msg.sender, tokenId, chipsBalance);
  }

  function _enterBaccaratOrb(
    uint256 tokenId, 
    string calldata walletManagerId,
    address chipsCoin
  )
    internal
    virtual
    returns(bool isPlaying)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(!_orbState[tokenUuid].isPlaying[ORBS.Baccarat], "ORB:E-106");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    require(chipsBalance > 0, "ORB:E-107");
    _orbState[tokenUuid].baccarat.gemChips = chipsBalance;
    _orbState[tokenUuid].baccarat.gameChips = chipsBalance;
    _orbState[tokenUuid].baccarat.createdBy = msg.sender;
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.add((GEM_RELEASE_LOCK_TIME.sub(block.timestamp)).div(BLOCK_TIME));
    _gem.setReleaseTimeLock(tokenId, unlockBlock);
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.Baccarat] = true;
    //return orb state
    isPlaying = _orbState[tokenUuid].isPlaying[ORBS.Baccarat];
    emit EnterBaccaratOrb(msg.sender, tokenId, chipsBalance);
  }

  function _exitSlotMachineOrb(
    uint256 tokenId,
    string calldata walletManagerId,
    address chipsCoin
  )
  internal
  virtual
  returns(uint256 gemChips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.SlotMachine], "ORB:E-108"); //user must be playing slot
    require(_orbState[tokenUuid].slotMachine.createdBy == msg.sender, "ORB:E-109");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    if (_orbState[tokenUuid].slotMachine.gemChips < chipsBalance)
    {
      _orbState[tokenUuid].slotMachine.gemChips = chipsBalance;
    }
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.sub(1);
    _gem.setReleaseTimeLock(tokenId, unlockBlock);
    if (_orbState[tokenUuid].slotMachine.gemChips > _orbState[tokenUuid].slotMachine.gameChips)
    {
      uint256 lossChips = _orbState[tokenUuid].slotMachine.gemChips.sub(_orbState[tokenUuid].slotMachine.gameChips);
      _gem.withdrawCasinoCoins(owner(), tokenId, walletManagerId, chipsCoin, lossChips);
    }
    else if (_orbState[tokenUuid].slotMachine.gemChips < _orbState[tokenUuid].slotMachine.gameChips)
    {
      uint256 wonChips = _orbState[tokenUuid].slotMachine.gameChips.sub(_orbState[tokenUuid].slotMachine.gemChips);
      //Collect asset token from casino admin
      _collectAssetToken(owner(), chipsCoin, wonChips);

      IERC20(chipsCoin).approve(address(_gem), wonChips);
      _gem.addCasinoCoins(tokenId, walletManagerId, chipsCoin, wonChips);
    }
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.SlotMachine] = false;
    gemChips = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    emit ExitSlotMachineOrb(msg.sender, tokenId, gemChips);
  }

  function _exitRoulletteOrb(
    uint256 tokenId,
    string calldata walletManagerId,
    address chipsCoin
  )
  internal
  virtual
  returns(uint256 gemChips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.Roullette], "ORB:E-108"); //user must be playing slot
    require(_orbState[tokenUuid].roullette.createdBy == msg.sender, "ORB:E-109");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    if (_orbState[tokenUuid].roullette.gemChips < chipsBalance)
    {
      _orbState[tokenUuid].roullette.gemChips = chipsBalance;
    }
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.sub(1);
    _gem.setReleaseTimeLock(tokenId, unlockBlock);
    if (_orbState[tokenUuid].roullette.gemChips > _orbState[tokenUuid].roullette.gameChips)
    {
      uint256 lossChips = _orbState[tokenUuid].roullette.gemChips.sub(_orbState[tokenUuid].roullette.gameChips);
      _gem.withdrawCasinoCoins(owner(), tokenId, walletManagerId, chipsCoin, lossChips);
    }
    else if (_orbState[tokenUuid].roullette.gemChips < _orbState[tokenUuid].roullette.gameChips)
    {
      uint256 wonChips = _orbState[tokenUuid].roullette.gameChips.sub(_orbState[tokenUuid].roullette.gemChips);
      //Collect asset token from casino admin
      _collectAssetToken(owner(), chipsCoin, wonChips);

      IERC20(chipsCoin).approve(address(_gem), wonChips);
      _gem.addCasinoCoins(tokenId, walletManagerId, chipsCoin, wonChips);
    }
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.Roullette] = false;
    gemChips = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    emit ExitRoulletteOrb(msg.sender, tokenId, gemChips);
  }

  function _exitBaccaratOrb(
    uint256 tokenId,
    string calldata walletManagerId,
    address chipsCoin
  )
  internal
  virtual
  returns(uint256 gemChips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.Baccarat], "ORB:E-108"); //user must be playing slot
    require(_orbState[tokenUuid].baccarat.createdBy == msg.sender, "ORB:E-109");
    uint256 chipsBalance = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    if (_orbState[tokenUuid].baccarat.gemChips < chipsBalance)
    {
      _orbState[tokenUuid].baccarat.gemChips = chipsBalance;
    }
    //set release lock on GEM _setReleaseLock
    uint256 unlockBlock = block.number.sub(1);
    _gem.setReleaseTimeLock(tokenId, unlockBlock);
    if (_orbState[tokenUuid].baccarat.gemChips > _orbState[tokenUuid].baccarat.gameChips)
    {
      uint256 lossChips = _orbState[tokenUuid].baccarat.gemChips.sub(_orbState[tokenUuid].baccarat.gameChips);
      _gem.withdrawCasinoCoins(owner(), tokenId, walletManagerId, chipsCoin, lossChips);
    }
    else if (_orbState[tokenUuid].baccarat.gemChips < _orbState[tokenUuid].baccarat.gameChips)
    {
      uint256 wonChips = _orbState[tokenUuid].baccarat.gameChips.sub(_orbState[tokenUuid].baccarat.gemChips);
      //Collect asset token from casino admin
      _collectAssetToken(owner(), chipsCoin, wonChips);

      IERC20(chipsCoin).approve(address(_gem), wonChips);
      _gem.addCasinoCoins(tokenId, walletManagerId, chipsCoin, wonChips);
    }
    //set isPlaying
    _orbState[tokenUuid].isPlaying[ORBS.Baccarat] = false;
    gemChips = _gem.getCasinoChipsBalance(tokenId, walletManagerId, chipsCoin);
    emit ExitBaccaratOrb(msg.sender, tokenId, gemChips);
  }

  /**
    * @dev Collects the Required Asset Token from the users wallet
    * @param from         The owner address to collect the Assets from
    * @param assetAmount  The Amount of Asset Tokens to Collect
    */
  function _collectAssetToken(address from, address assetToken, uint256 assetAmount) internal virtual {
    uint256 _userAssetBalance = IERC20(assetToken).balanceOf(from);
    require(assetAmount <= _userAssetBalance, "ORB:E-411");
    // Be sure to Approve this Contract to transfer your Asset Token
    require(IERC20(assetToken).transferFrom(from, address(this), assetAmount), "ORB:E-401");
  }

  /***********************************|
  | Only Admin/DAO (Supraorbs Casino) |
  |__________________________________*/

  function setSlotMachineOrbChips(
    uint256 tokenId, 
    uint256 gameChips
  ) external virtual onlyOwner
  returns (uint256 gemGamechips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.SlotMachine], "ORB:E-108"); //user must be playing slot
    _orbState[tokenUuid].slotMachine.gameChips = gameChips;
    gemGamechips = _orbState[tokenUuid].slotMachine.gameChips;
    emit SlotMachineOrbUpdated(tokenId, gemGamechips);
  }

  function setRoulletteOrbChips(
    uint256 tokenId, 
    uint256 gameChips
  ) external virtual onlyOwner 
  returns (uint256 gemGamechips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.Roullette], "ORB:E-108"); //user must be playing slot
    _orbState[tokenUuid].roullette.gameChips = gameChips;
    gemGamechips = _orbState[tokenUuid].roullette.gameChips;
    emit RoulletteOrbUpdated(tokenId, gemGamechips);
  }

  function setbaccaratOrbChips(
    uint256 tokenId, 
    uint256 gameChips
  ) external virtual onlyOwner 
  returns (uint256 gemGamechips)
  {
    uint256 tokenUuid = address(_gem).getTokenUUID(tokenId);
    require(_orbState[tokenUuid].isPlaying[ORBS.Baccarat], "ORB:E-108"); //user must be playing slot
    _orbState[tokenUuid].baccarat.gameChips = gameChips;
    gemGamechips = _orbState[tokenUuid].baccarat.gameChips;
    emit BaccaratOrbUpdated(tokenId, gemGamechips);
  }

  /**
    * @dev Setup the Gem Interface
    */
  function setGem(address gem) external virtual onlyOwner {
    _gem = IGem(gem);
    emit GemSet(gem);
  }

  /***********************************|
  |             Modifiers             |
  |__________________________________*/

  modifier onlyErc721OwnerOrOperator(uint256 tokenId, address sender) {
    require(address(_gem).isErc721OwnerOrOperator(tokenId, sender), "ORB:E-105");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// Gem.sol -- Part of Supraorbs Casino
// Copyright (c) 2021 WSCF Global, Inc. <https://wscf.io>

pragma solidity 0.6.12;

import "./IGem.sol";

/**
 * @notice Interface for Supraorbs Casino
 */
interface ISupraorbsCasino {
  event EnterSlotMachineOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event EnterRoulletteOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event EnterBaccaratOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event ExitSlotMachineOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event ExitRoulletteOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event ExitBaccaratOrb(address indexed player, uint256 indexed tokenId, uint256 gemChips);
  event SlotMachineOrbUpdated(uint256 indexed tokenId, uint256 gemGameChips);
  event RoulletteOrbUpdated(uint256 indexed tokenId, uint256 gemGameChips);
  event BaccaratOrbUpdated(uint256 indexed tokenId, uint256 gemGameChips);
  event GemSet(address indexed settings);

  /***********************************|
  |             Public API            |
  |__________________________________*/

  function getSlotMachineOrb(uint256 tokenId) external view returns(uint256 gemChips, uint256 gameChips, bool isPlaying);
  function getRoulletteOrb(uint256 tokenId) external view returns(uint256 gemChips, uint256 gameChips, bool isPlaying);
  function getBaccaratOrb(uint256 tokenId) external view returns(uint256 gemChips, uint256 gameChips, bool isPlaying);

  /***********************************|
  |     Only Token Creator/Owner      |
  |__________________________________*/

  function enterSlotMachineOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(bool isPlaying);
  function enterRoulletteOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(bool isPlaying);
  function enterBaccaratOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(bool isPlaying);
  function exitSlotMachineOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(uint256 gemChips);
  function exitRoulletteOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(uint256 gemChips);
  function exitBaccaratOrb(uint256 tokenId, string calldata walletManagerId, address chipsCoin) external returns(uint256 gemChips);
}

// SPDX-License-Identifier: MIT

// IGem.sol -- Part of Supraorbs Casino
// Copyright (c) 2021 WSCF Global, Inc. <https://wscf.io>

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./IChargedState.sol";
import "./IChargedSettings.sol";
import "./IChargedParticles.sol";
import "./ISupraorbsCasino.sol";

import "../lib/BlackholePrevention.sol";
// import "../lib/RelayRecipient.sol";


interface IGem is IERC721 {
  event ChargedStateSet(address indexed chargedState);
  event ChargedSettingsSet(address indexed chargedSettings);
  event ChargedParticlesSet(address indexed chargedParticles);
  event PausedStateSet(bool isPaused);
  event SupraorbsCasinoSet(address indexed supraorbsCasino);
  event SalePriceSet(uint256 indexed tokenId, uint256 salePrice);
  event CreatorRoyaltiesSet(uint256 indexed tokenId, uint256 royaltiesPct);
  event GemCreated(uint256 indexed tokenId, address indexed receiver, address creator, uint256 creatorRoyalties);
  event RoyaltiesClaimed(address indexed receiver, uint256 amountClaimed);
  event GemReleaseTimeLock(address indexed contractAddress, uint256 indexed tokenId, address indexed operator, uint256 unlockBlock);

  /***********************************|
  |              Public               |
  |__________________________________*/

  function creatorOf(uint256 tokenId) external view returns (address);
  function getSalePrice(uint256 tokenId) external view returns (uint256);
  function getLastSellPrice(uint256 tokenId) external view returns (uint256);
  function getCreatorRoyalties(address account) external view returns (uint256);
  function getCreatorRoyaltiesPct(uint256 tokenId) external view returns (uint256);
  function getCreatorRoyaltiesReceiver(uint256 tokenId) external view returns (address);

  function getCasinoChipsBalance(uint256 tokenId, string calldata walletManagerId, address assetToken) external returns (uint256);
  function claimCreatorRoyalties() external returns (uint256);

  function mintGem(
    address creator,
    address receiver,
    string memory tokenMetaUri,
    string memory walletManagerId,
    address assetToken,
    uint256 assetAmount,
    address casinoGame
  ) external returns (uint256 newTokenId);

  /***********************************|
  |     Only Token Creator/Owner      |
  |__________________________________*/

  function setSalePrice(uint256 tokenId, uint256 salePrice) external;
  function addCasinoCoins(
    uint256 tokenId,
    string calldata walletManagerId, 
    address assetToken, 
    uint256 assetAmount) 
    external returns (uint256 yieldTokensAmount);
  function withdrawCasinoCoins(
    address receiver,
    uint256 tokenId,
    string calldata walletManagerId,
    address assetToken,
    uint256 assetAmount) 
    external returns (uint256 creatorAmount, uint256 receiverAmount);
  function setReleaseTimeLock(uint256 tokenId, uint256 unlockBlock) external;
  function setCreatorRoyaltiesReceiver(uint256 tokenId, address receiver) external;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
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

// IChargedParticles.sol -- Part of the Charged Particles Protocol
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
 * @notice Interface for Charged Particles
 */
interface IChargedParticles {

  /***********************************|
  |             Public API            |
  |__________________________________*/

  function getStateAddress() external view returns (address stateAddress);
  function getSettingsAddress() external view returns (address settingsAddress);

  function baseParticleMass(address contractAddress, uint256 tokenId, string calldata walletManagerId, address assetToken) external returns (uint256);
  function currentParticleCharge(address contractAddress, uint256 tokenId, string calldata walletManagerId, address assetToken) external returns (uint256);
  function currentParticleKinetics(address contractAddress, uint256 tokenId, string calldata walletManagerId, address assetToken) external returns (uint256);
  function currentParticleCovalentBonds(address contractAddress, uint256 tokenId, string calldata basketManagerId) external view returns (uint256);

  /***********************************|
  |        Particle Mechanics         |
  |__________________________________*/

  function energizeParticle(
      address contractAddress,
      uint256 tokenId,
      string calldata walletManagerId,
      address assetToken,
      uint256 assetAmount,
    address referrer
  ) external returns (uint256 yieldTokensAmount);

  function dischargeParticle(
      address receiver,
      address contractAddress,
      uint256 tokenId,
      string calldata walletManagerId,
      address assetToken
  ) external returns (uint256 creatorAmount, uint256 receiverAmount);

  function dischargeParticleAmount(
      address receiver,
      address contractAddress,
      uint256 tokenId,
      string calldata walletManagerId,
      address assetToken,
      uint256 assetAmount
  ) external returns (uint256 creatorAmount, uint256 receiverAmount);

  function dischargeParticleForCreator(
      address receiver,
      address contractAddress,
      uint256 tokenId,
      string calldata walletManagerId,
      address assetToken,
      uint256 assetAmount
  ) external returns (uint256 receiverAmount);

  function releaseParticle(
      address receiver,
      address contractAddress,
      uint256 tokenId,
      string calldata walletManagerId,
      address assetToken
  ) external returns (uint256 creatorAmount, uint256 receiverAmount);

  function releaseParticleAmount(
    address receiver,
    address contractAddress,
    uint256 tokenId,
    string calldata walletManagerId,
    address assetToken,
    uint256 assetAmount
  ) external returns (uint256 creatorAmount, uint256 receiverAmount);

  function covalentBond(
    address contractAddress,
    uint256 tokenId,
    string calldata basketManagerId,
    address nftTokenAddress,
    uint256 nftTokenId
  ) external returns (bool success);

  function breakCovalentBond(
    address receiver,
    address contractAddress,
    uint256 tokenId,
    string calldata basketManagerId,
    address nftTokenAddress,
    uint256 nftTokenId
  ) external returns (bool success);

  /***********************************|
  |          Particle Events          |
  |__________________________________*/

  event UniverseSet(address indexed universeAddress);
  event ChargedStateSet(address indexed chargedState);
  event ChargedSettingsSet(address indexed chargedSettings);
  event LeptonTokenSet(address indexed leptonToken);
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
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

