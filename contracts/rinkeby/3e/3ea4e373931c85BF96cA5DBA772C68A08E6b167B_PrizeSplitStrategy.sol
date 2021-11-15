// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICompLike is IERC20 {
  function getCurrentVotes(address account) external view returns (uint96);
  function delegate(address delegatee) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Controlled ERC20 Token
/// @notice ERC20 Tokens with a controller for minting & burning
interface IControlledToken is IERC20 {

  /// @notice Interface to the contract responsible for controlling mint/burn
  function controller() external view returns (address);

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param user Address of the receiver of the minted tokens
  /// @param amount Amount of tokens to mint
  function controllerMint(address user, uint256 amount) external;

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param user Address of the holder account to burn tokens from
  /// @param amount Amount of tokens to burn
  function controllerBurn(address user, uint256 amount) external;

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param operator Address of the operator performing the burn action via the controller contract
  /// @param user Address of the holder account to burn tokens from
  /// @param amount Amount of tokens to burn
  function controllerBurnFrom(address operator, address user, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../external/compound/ICompLike.sol";
import "../interfaces/IControlledToken.sol";

interface IPrizePool {

  /// @dev Event emitted when controlled token is added
  event ControlledTokenAdded(
    IControlledToken indexed token
  );

  event AwardCaptured(
    uint256 amount
  );

  /// @dev Event emitted when assets are deposited
  event Deposited(
    address indexed operator,
    address indexed to,
    IControlledToken indexed token,
    uint256 amount
  );

  /// @dev Event emitted when interest is awarded to a winner
  event Awarded(
    address indexed winner,
    IControlledToken indexed token,
    uint256 amount
  );

  /// @dev Event emitted when external ERC20s are awarded to a winner
  event AwardedExternalERC20(
    address indexed winner,
    address indexed token,
    uint256 amount
  );

  /// @dev Event emitted when external ERC20s are transferred out
  event TransferredExternalERC20(
    address indexed to,
    address indexed token,
    uint256 amount
  );

  /// @dev Event emitted when external ERC721s are awarded to a winner
  event AwardedExternalERC721(
    address indexed winner,
    address indexed token,
    uint256[] tokenIds
  );

  /// @dev Event emitted when assets are withdrawn
  event Withdrawal(
    address indexed operator,
    address indexed from,
    IControlledToken indexed token,
    uint256 amount,
    uint256 redeemed
  );

  /// @dev Event emitted when the Balance Cap is set
  event BalanceCapSet(
    uint256 balanceCap
  );

  /// @dev Event emitted when the Liquidity Cap is set
  event LiquidityCapSet(
    uint256 liquidityCap
  );

  /// @dev Event emitted when the Prize Strategy is set
  event PrizeStrategySet(
    address indexed prizeStrategy
  );

  /// @dev Event emitted when the Ticket is set
  event TicketSet(
    IControlledToken indexed ticket
  );

  /// @dev Emitted when there was an error thrown awarding an External ERC721
  event ErrorAwardingExternalERC721(bytes error);

  /// @notice Deposit assets into the Prize Pool in exchange for tokens
  /// @param to The address receiving the newly minted tokens
  /// @param amount The amount of assets to deposit
  function depositTo(
    address to,
    uint256 amount
  )
    external;

  /// @notice Withdraw assets from the Prize Pool instantly.  A fairness fee may be charged for an early exit.
  /// @param from The address to redeem tokens from.
  /// @param amount The amount of tokens to redeem for assets.
  /// @return The actual amount withdrawn
  function withdrawFrom(
    address from,
    uint256 amount
  ) external returns (uint256);

  /// @notice Returns the balance that is available to award.
  /// @dev captureAwardBalance() should be called first
  /// @return The total amount of assets to be awarded for the current prize
  function awardBalance() external view returns (uint256);

  /// @notice Captures any available interest as award balance.
  /// @dev This function also captures the reserve fees.
  /// @return The total amount of assets to be awarded for the current prize
  function captureAwardBalance() external returns (uint256);

  /// @dev Checks with the Prize Pool if a specific token type may be awarded as an external prize
  /// @param _externalToken The address of the token to check
  /// @return True if the token may be awarded, false otherwise
  function canAwardExternal(address _externalToken) external view returns (bool);

  // @dev Returns the total underlying balance of all assets. This includes both principal and interest.
  /// @return The underlying balance of assets
  function balance() external returns (uint256);

  /// @dev Checks if a specific token is controlled by the Prize Pool
  /// @param _controlledToken The address of the token to check
  /// @return True if the token is a controlled token, false otherwise
  function isControlled(IControlledToken _controlledToken) external view returns (bool);

  /// @notice Called by the prize strategy to award prizes.
  /// @dev The amount awarded must be less than the awardBalance()
  /// @param to The address of the winner that receives the award
  /// @param amount The amount of assets to be awarded
  function award( address to, uint256 amount) external;

  /// @notice Called by the Prize-Strategy to transfer out external ERC20 tokens
  /// @dev Used to transfer out tokens held by the Prize Pool.  Could be liquidated, or anything.
  /// @param to The address of the winner that receives the award
  /// @param externalToken The address of the external asset token being awarded
  /// @param amount The amount of external assets to be awarded
  function transferExternalERC20(address to, address externalToken, uint256 amount) external;

  /// @notice Called by the Prize-Strategy to award external ERC20 prizes
  /// @dev Used to award any arbitrary tokens held by the Prize Pool
  /// @param to The address of the winner that receives the award
  /// @param amount The amount of external assets to be awarded
  /// @param externalToken The address of the external asset token being awarded
  function awardExternalERC20(
    address to, address externalToken, uint256 amount) external;

  /// @notice Called by the prize strategy to award external ERC721 prizes
  /// @dev Used to award any arbitrary NFTs held by the Prize Pool
  /// @param to The address of the winner that receives the award
  /// @param externalToken The address of the external NFT token being awarded
  /// @param tokenIds An array of NFT Token IDs to be transferred
  function awardExternalERC721(address to, address externalToken, uint256[] calldata tokenIds) external;

  /// @notice Allows the owner to set a balance cap per `token` for the pool.
  /// @dev If a user wins, his balance can go over the cap. He will be able to withdraw the excess but not deposit.
  /// @dev Needs to be called after deploying a prize pool to be able to deposit into it.
  /// @param _balanceCap New balance cap.
  /// @return True if new balance cap has been successfully set.
  function setBalanceCap(uint256 _balanceCap) external returns (bool);

  /// @notice Allows the Governor to set a cap on the amount of liquidity that he pool can hold
  /// @param _liquidityCap The new liquidity cap for the prize pool
  function setLiquidityCap(uint256 _liquidityCap) external;

  /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
  /// @param _prizeStrategy The new prize strategy.  Must implement DrawPrizePrizeStrategy
  function setPrizeStrategy(address _prizeStrategy) external;

  /// @notice Set prize pool ticket.
  /// @param _ticket Address of the ticket to set.
  /// @return True if ticket has been successfully set.
  function setTicket(IControlledToken _ticket) external returns (bool);

  /// @dev Returns the address of the prize pool ticket.
  /// @return The address of the prize pool ticket.
  function ticket() external view returns (IControlledToken);
  
  /// @dev Returns the address of the prize pool ticket.
  /// @return The address of the prize pool ticket.
  function getTicket() external view returns (IControlledToken);

  /// @dev Returns the address of the underlying ERC20 asset
  /// @return The address of the asset
  function token() external view returns (address);

  /// @notice The total of all controlled tokens
  /// @return The current total of all tokens
  function accountedBalance() external view returns (uint256);

  /// @notice Delegate the votes for a Compound COMP-like token held by the prize pool
  /// @param _compLike The COMP-like token held by the prize pool that should be delegated
  /// @param _to The address to delegate to
  function compLikeDelegate(ICompLike _compLike, address _to) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
import "./IControlledToken.sol";
import "./IPrizePool.sol";

/**
  * @title Abstract prize split contract for adding unique award distribution to static addresses.
  * @author PoolTogether Inc Team
*/
interface IPrizeSplit {

  /**
    * @notice Emit when an individual prize split is awarded.
    * @param user          User address being awarded
    * @param prizeAwarded  Awarded prize amount
    * @param token         Token address
  */
  event PrizeSplitAwarded(
    address indexed user,
    uint256 prizeAwarded,
    IControlledToken indexed token
  );

  /**
    * @notice The prize split configuration struct.
    * @dev    The prize split configuration struct used to award prize splits during distribution.
    * @param target     Address of recipient receiving the prize split distribution
    * @param percentage Percentage of prize split using a 0-1000 range for single decimal precision i.e. 125 = 12.5%
  */
  struct PrizeSplitConfig {
    address target;
    uint16 percentage;
  }

  /**
    * @notice Emitted when a PrizeSplitConfig config is added or updated.
    * @dev    Emitted when a PrizeSplitConfig config is added or updated in setPrizeSplits or setPrizeSplit.
    * @param target     Address of prize split recipient
    * @param percentage Percentage of prize split. Must be between 0 and 1000 for single decimal precision
    * @param index      Index of prize split in the prizeSplts array
  */
  event PrizeSplitSet(address indexed target, uint16 percentage, uint256 index);

  /**
    * @notice Emitted when a PrizeSplitConfig config is removed.
    * @dev    Emitted when a PrizeSplitConfig config is removed from the _prizeSplits array.
    * @param target Index of a previously active prize split config
  */
  event PrizeSplitRemoved(uint256 indexed target);

  /**
    * @notice Read prize split config from active PrizeSplits.
    * @dev    Read PrizeSplitConfig struct from _prizeSplits array.
    * @param prizeSplitIndex Index position of PrizeSplitConfig
    * @return PrizeSplitConfig Single prize split config
  */
  function getPrizeSplit(uint256 prizeSplitIndex) external view returns (PrizeSplitConfig memory);

  /**
    * @notice Read all prize splits configs.
    * @dev    Read all PrizeSplitConfig structs stored in _prizeSplits.
    * @return _prizeSplits Array of PrizeSplitConfig structs
  */
  function getPrizeSplits() external view returns (PrizeSplitConfig[] memory);
  
  /**
    * @notice Get PrizePool address
    * @return IPrizePool
   */
  function getPrizePool() external view returns(IPrizePool);
  /**
    * @notice Set and remove prize split(s) configs. Only callable by owner.
    * @dev Set and remove prize split configs by passing a new PrizeSplitConfig structs array. Will remove existing PrizeSplitConfig(s) if passed array length is less than existing _prizeSplits length.
    * @param newPrizeSplits Array of PrizeSplitConfig structs
  */
  function setPrizeSplits(PrizeSplitConfig[] calldata newPrizeSplits) external;

  /**
    * @notice Updates a previously set prize split config.
    * @dev Updates a prize split config by passing a new PrizeSplitConfig struct and current index position. Limited to contract owner.
    * @param prizeStrategySplit PrizeSplitConfig config struct
    * @param prizeSplitIndex Index position of PrizeSplitConfig to update
  */
  function setPrizeSplit(PrizeSplitConfig memory prizeStrategySplit, uint8 prizeSplitIndex) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface IStrategy {

  /**
    * @notice Emit when a strategy captures award amount from PrizePool.
    * @param totalPrizeCaptured  Total prize captured from the PrizePool
  */
  event Distributed(
    uint256 totalPrizeCaptured
  );
  
  /**
    * @notice Capture the award balance and distribute to prize splits.
    * @dev    Permissionless function to initialize distribution of interst
    * @return Prize captured from PrizePool
  */
  function distribute() external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";
import "../interfaces/IPrizeSplit.sol";

/**
  * @title PrizeSplit Interface
  * @author PoolTogether Inc Team
*/
abstract contract PrizeSplit is IPrizeSplit, Ownable {

  /* ============ Global Variables ============ */
  PrizeSplitConfig[] internal _prizeSplits;
  

  /* ============ External Functions ============ */

  /// @inheritdoc IPrizeSplit
  function getPrizeSplit(uint256 prizeSplitIndex) external view override returns (PrizeSplitConfig memory) {
    return _prizeSplits[prizeSplitIndex];
  }

  /// @inheritdoc IPrizeSplit
  function getPrizeSplits() external view override returns (PrizeSplitConfig[] memory) {
    return _prizeSplits;
  }

  /// @inheritdoc IPrizeSplit
  function setPrizeSplits(PrizeSplitConfig[] calldata newPrizeSplits) external override onlyOwner {
    uint256 newPrizeSplitsLength = newPrizeSplits.length;

    // Add and/or update prize split configs using newPrizeSplits PrizeSplitConfig structs array.
    for (uint256 index = 0; index < newPrizeSplitsLength; index++) {
      PrizeSplitConfig memory split = newPrizeSplits[index];

      // REVERT when setting the canonical burn address.
      require(split.target != address(0), "PrizeSplit/invalid-prizesplit-target");

      // IF the CURRENT prizeSplits length is below the NEW prizeSplits
      // PUSH the PrizeSplit struct to end of the list.
      if (_prizeSplits.length <= index) {
        _prizeSplits.push(split);
      } else {
        // ELSE update an existing PrizeSplit struct with new parameters
        PrizeSplitConfig memory currentSplit = _prizeSplits[index];

        // IF new PrizeSplit DOES NOT match the current PrizeSplit
        // WRITE to STORAGE with the new PrizeSplit
        if (split.target != currentSplit.target || split.percentage != currentSplit.percentage) {
          _prizeSplits[index] = split;
        } else {
          continue;
        }
      }

      // Emit the added/updated prize split config.
      emit PrizeSplitSet(split.target, split.percentage, index);
    }

    // Remove old prize splits configs. Match storage _prizesSplits.length with the passed newPrizeSplits.length
    while (_prizeSplits.length > newPrizeSplitsLength) {
      uint256 _index = _prizeSplits.length - 1;
      _prizeSplits.pop();
      emit PrizeSplitRemoved(_index);
    }

    // Total prize split do not exceed 100%
    uint256 totalPercentage = _totalPrizeSplitPercentageAmount();
    require(totalPercentage <= 1000, "PrizeSplit/invalid-prizesplit-percentage-total");
  }

  /// @inheritdoc IPrizeSplit
  function setPrizeSplit(PrizeSplitConfig memory prizeStrategySplit, uint8 prizeSplitIndex) external override onlyOwner {
    require(prizeSplitIndex < _prizeSplits.length, "PrizeSplit/nonexistent-prizesplit");
    require(prizeStrategySplit.target != address(0), "PrizeSplit/invalid-prizesplit-target");

    // Update the prize split config
    _prizeSplits[prizeSplitIndex] = prizeStrategySplit;

    // Total prize split do not exceed 100%
    uint256 totalPercentage = _totalPrizeSplitPercentageAmount();
    require(totalPercentage <= 1000, "PrizeSplit/invalid-prizesplit-percentage-total");

    // Emit updated prize split config
    emit PrizeSplitSet(prizeStrategySplit.target, prizeStrategySplit.percentage, prizeSplitIndex);
  }

  /* ============ Internal Functions ============ */

  /**
  * @notice Calculate single prize split distribution amount.
  * @dev Calculate single prize split distribution amount using the total prize amount and prize split percentage.
  * @param amount Total prize award distribution amount
  * @param percentage Percentage with single decimal precision using 0-1000 ranges
  */
  function _getPrizeSplitAmount(uint256 amount, uint16 percentage) internal pure returns (uint256) {
    return (amount * percentage) / 1000;
  }

  /**
  * @notice Calculates total prize split percentage amount.
  * @dev Calculates total PrizeSplitConfig percentage(s) amount. Used to check the total does not exceed 100% of award distribution.
  * @return Total prize split(s) percentage amount
  */
  function _totalPrizeSplitPercentageAmount() internal view returns (uint256) {
    uint256 _tempTotalPercentage;
    uint256 prizeSplitsLength = _prizeSplits.length;
    for (uint8 index = 0; index < prizeSplitsLength; index++) {
      PrizeSplitConfig memory split = _prizeSplits[index];
      _tempTotalPercentage = _tempTotalPercentage +split.percentage;
    }
    return _tempTotalPercentage;
  }

  /**
  * @notice Distributes prize split(s).
  * @dev Distributes prize split(s) by awarding ticket or sponsorship tokens.
  * @param prize Starting prize award amount
  * @return Total prize award distribution amount exlcuding the awarded prize split(s)
  */
  function _distributePrizeSplits(uint256 prize) internal returns (uint256) {
    // Store temporary total prize amount for multiple calculations using initial prize amount.
    uint256 _prizeTemp = prize;
    uint256 prizeSplitsLength = _prizeSplits.length;
    for (uint256 index = 0; index < prizeSplitsLength; index++) {
      PrizeSplitConfig memory split = _prizeSplits[index];
      uint256 _splitAmount = _getPrizeSplitAmount(_prizeTemp, split.percentage);

      // Award the prize split distribution amount.
      _awardPrizeSplitAmount(split.target, _splitAmount);

      // Update the remaining prize amount after distributing the prize split percentage.
      prize = prize - _splitAmount;
    }

    return prize;
  }

  /**
    * @notice Mints ticket or sponsorship tokens to prize split recipient.
    * @dev Mints ticket or sponsorship tokens to prize split recipient via the linked PrizePool contract.
    * @param target Recipient of minted tokens
    * @param amount Amount of minted tokens
  */
  function _awardPrizeSplitAmount(address target, uint256 amount) virtual internal;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "./PrizeSplit.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPrizePool.sol";

/**
  * @title  PoolTogether V4 PrizeSplitStrategy
  * @author PoolTogether Inc Team
  * @notice Captures PrizePool interest for PrizeReserve and additional PrizeSplit recipients.
            The PrizeSplitStrategy will have at minimum a single PrizeSplit with 100% of the captured
            interest transfered to the PrizeReserve. Additional PrizeSplits can be added, depending on
            the deployers requirements (i.e. percentage to charity). In contrast to previous PoolTogether
            iterations, interest can be captured independent of a new Draw. Ideally (to save gas) interest
            is only captured when also distributing the captured prize(s) to applicable ClaimbableDraw(s).
*/
contract PrizeSplitStrategy is PrizeSplit, IStrategy {

  /**
    * @notice PrizePool address
  */
  IPrizePool internal prizePool;

  /**
    * @notice Deployed Event
    * @param owner Contract owner
    * @param prizePool Linked PrizePool contract
  */
  event Deployed(
    address indexed owner,
    IPrizePool prizePool
  );

  /* ============ Constructor ============ */

  /**
    * @notice Deploy the PrizeSplitStrategy smart contract.
    * @param _owner     Owner address
    * @param _prizePool PrizePool address
  */
  constructor (
    address _owner,
    IPrizePool _prizePool
  ) Ownable(_owner) {
    require(address(_prizePool) != address(0), "PrizeSplitStrategy/prize-pool-not-zero-address");
    prizePool = _prizePool;
    emit Deployed(_owner, _prizePool);
  }

  /* ============ External Functions ============ */
  
  /// @inheritdoc IStrategy
  function distribute() external override returns (uint256) {
    uint256 prize = prizePool.captureAwardBalance();
    if(prize == 0) return 0;
    _distributePrizeSplits(prize);
    emit Distributed(prize);
    return prize;
  }

  /// @inheritdoc IPrizeSplit
  function getPrizePool() external view override returns(IPrizePool) {
    return prizePool;
  }

  /* ============ Internal Functions ============ */

  /**
    * @notice Award ticket tokens to prize split recipient.
    * @dev Award ticket tokens to prize split recipient via the linked PrizePool contract.
    * @param _to Recipient of minted tokens.
    * @param _amount Amount of minted tokens.
  */
  function _awardPrizeSplitAmount(address _to, uint256 _amount) override internal {
    IControlledToken _ticket = prizePool.ticket();
    prizePool.award(_to, _amount);
    emit PrizeSplitAwarded(_to, _amount, _ticket);
  }

}

