// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

interface IRadRouter is IERC721Receiver {
  /**
   * @dev Emitted when a retail revenue split is updated for asset ledger `ledger`
   */
  event RetailRevenueSplitChange(address indexed ledger, address indexed stakeholder, uint256 share, uint256 totalStakeholders, uint256 totalSplit);

  /**
   * @dev Emitted when a resale revenue split is updated for asset ledger `ledger`
   */
  event ResaleRevenueSplitChange(address indexed ledger, address indexed stakeholder, uint256 share, uint256 totalStakeholders, uint256 totalSplit);

  /**
   * @dev Emitted when the minimum price of asset `assetId` is updated
   */
  event AssetMinPriceChange(address indexed ledger, uint256 indexed assetId, uint256 minPrice);

  /**
   * @dev Emitted when seller `seller` changes ownership for asset `assetId` in ledger `ledger` to or from this escrow. `escrowed` is true for deposits and false for withdrawals
   */
  event SellerEscrowChange(address indexed ledger, uint256 indexed assetId, address indexed seller, bool escrowed);

  /**
   * @dev Emitted when buyer `buyer` deposits or withdraws ETH from this escrow for asset `assetId` in ledger `ledger`. `escrowed` is true for deposits and false for withdrawals
   */
  event BuyerEscrowChange(address indexed ledger, uint256 indexed assetId, address indexed buyer, bool escrowed);

  /**
   * @dev Emitted when stakeholder `stakeholder` is paid out from a retail sale or resale
   */
  event StakeholderPayout(address indexed ledger, uint256 indexed assetId, address indexed stakeholder, uint256 payout, uint256 share, bool retail);

  /**
   * @dev Emitted when buyer `buyer` deposits or withdraws ETH from this escrow for asset `assetId` in ledger `ledger`. `escrowed` is true for deposits and false for withdrawals
   */
  event EscrowFulfill(address indexed ledger, uint256 indexed assetId, address seller, address buyer, uint256 value);

  /**
   * @dev Sets a stakeholder's revenue share for an asset ledger. If `retail` is true, sets retail revenue splits; otherwise sets resale revenue splits
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_stakeholder` cannot be the zero address.
   * - `_share` must be >= 0 and <= 100
   * - Revenue cannot be split more than 5 ways
   *
   * Emits a {RetailRevenueSplitChange|ResaleRevenueSplitChange} event.
   */
  function setRevenueSplit(address _ledger, address payable _stakeholder, uint256 _share, bool _retail) external returns (bool success);

  /**
   * @dev Returns the revenue share of `_stakeholder` for ledger `_ledger`
   *
   * See {setRevenueSplit}
   */
  function getRevenueSplit(address _ledger, address payable _stakeholder, bool _retail) external view returns (uint256 share);

  /**
   * @dev Sets multiple stakeholders' revenue shares for an asset ledger. Overwrites any existing revenue share. If `retail` is true, sets retail revenue splits; otherwise sets resale revenue splits
   * See {setRevenueSplit}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_stakeholders` cannot contain zero addresses.
   * - `_shares` must be >= 0 and <= 100
   * - Revenue cannot be split more than 5 ways
   *
   * Emits a {RetailRevenueSplitChange|ResaleRevenueSplitChange} event.
   */
  function setRevenueSplits(address _ledger, address payable[] calldata _stakeholders, uint256[] calldata _shares, bool _retail) external returns (bool success);

  /**
   * @dev For ledger `_ledger`, returns retail revenue stakeholders if `_retail` is true, otherwise returns resale revenue stakeholders.
   */
  function getRevenueStakeholders(address _ledger, bool _retail) external view returns (address[] memory stakeholders);

  /**
   * @dev Sets the minimum price for asset `_assetId`
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   * - `_minPrice` is in wei
   *
   * Emits a {AssetMinPriceChange} event.
   */
  function setAssetMinPrice(address _ledger, uint256 _assetId, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Sets a stakeholder's revenue share for an asset ledger. If `retail` is true, sets retail revenue splits; otherwise sets resale revenue splits.
   * Also sets the minimum price for asset `_assetId`
   * See {setAssetMinPrice | setRevenueSplits}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_stakeholder` cannot be the zero address.
   * - `_share` must be > 0 and <= 100
   * - Revenue cannot be split more than 5 ways
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   * - `_minPrice` is in wei
   *
   * Emits a {RetailRevenueSplitChange|ResaleRevenueSplitChange} event.
   */
  function setAssetMinPriceAndRevenueSplits(address _ledger, address payable[] calldata _stakeholders, uint256[] calldata _shares, bool _retail, uint256 _assetId, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Returns the minium price of asset `_assetId` in ledger `_ledger`
   *
   * See {setAssetMinPrice}
   */
  function getAssetMinPrice(address _ledger, uint256 _assetId) external view returns (uint256 minPrice);

  /**
   * @dev Transfers ownership of asset `_assetId` to this contract for escrow.
   * If buyer has already escrowed, triggers escrow fulfillment.
   * See {fulfill}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDeposit(address _ledger, uint256 _assetId) external returns (bool success);

  /**
   * @dev Transfers ownership of asset `_assetId` to this contract for escrow.
   * If buyer has already escrowed, triggers escrow fulfillment.
   * See {fulfill}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDepositWithCreatorShare(address _ledger, uint256 _assetId, uint256 _creatorResaleShare) external returns (bool success);

  function sellerEscrowDepositWithCreatorShareBatch(address _ledger, uint256[] calldata _assetIds, uint256 _creatorResaleShare) external returns (bool success);

  /**
   * @dev Transfers ownership of asset `_assetId` to this contract for escrow.
   * If buyer has already escrowed, triggers escrow fulfillment.
   * See {fulfill}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDepositWithCreatorShareWithMinPrice(address _ledger, uint256 _assetId, uint256 _creatorResaleShare, uint256 _minPrice) external returns (bool success);

  function sellerEscrowDepositWithCreatorShareWithMinPriceBatch(address _ledger, uint256[] calldata _assetIds, uint256 _creatorResaleShare, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Transfers ownership of asset `_assetId` to this contract for escrow.
   * Sets asset min price to `_minPrice` if `_setMinPrice` is true. Reverts if `_setMinPrice` is true and buyer has already escrowed. Otherwise, if buyer has already escrowed, triggers escrow fulfillment.
   * See {fulfill | setAssetMinPrice}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   * - `_minPrice` is in wei
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDeposit(address _ledger, uint256 _assetId, bool _setMinPrice, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Transfers ownership of all assets `_assetIds` to this contract for escrow.
   * If any buyers have already escrowed, triggers escrow fulfillment for the respective asset.
   * See {fulfill}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDepositBatch(address _ledger, uint256[] calldata _assetIds) external returns (bool success);

  /**
   * @dev Transfers ownership of all assets `_assetIds` to this contract for escrow.
   * Sets each asset min price to `_minPrice` if `_setMinPrice` is true. Reverts if `_setMinPrice` is true and buyer has already escrowed. Otherwise, if any buyers have already escrowed, triggers escrow fulfillment for the respective asset.
   * See {fulfill | setAssetMinPrice}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   * - `_minPrice` is in wei
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDepositBatch(address _ledger, uint256[] calldata _assetIds, bool _setMinPrice, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Transfers ownership of asset `_assetId` from this contract for escrow back to seller.
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowWithdraw(address _ledger, uint256 _assetId) external returns (bool success);

  /**
   * @dev Accepts buyer's `msg.sender` funds into escrow for asset `_assetId` in ledger `_ledger`.
   * If seller has already escrowed, triggers escrow fulfillment.
   * See {fulfill}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `msg.value` must be at least the seller's listed price
   * - `_assetId` in `ledger` cannot already have an escrowed buyer
   *
   * Emits a {BuyerEscrowChange} event.
   */
  function buyerEscrowDeposit(address _ledger, uint256 _assetId) external payable returns (bool success);

  /**
   * @dev Returns buyer's `msg.sender` funds back from escrow for asset `_assetId` in ledger `_ledger`.
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `msg.sender` must be the escrowed buyer for asset `_assetId` in ledger `_ledger`, asset owner, or Rad operator
   *
   * Emits a {BuyerEscrowChange} event.
   */
  function buyerEscrowWithdraw(address _ledger, uint256 _assetId) external returns (bool success);

  /**
   * @dev Returns the wallet address of the seller of asset `_assetId`
   *
   * See {sellerEscrowDeposit}
   */
  function getSellerWallet(address _ledger, uint256 _assetId) external view returns (address wallet);

  /**
   * @dev Returns the wallet address of the buyer of asset `_assetId`
   *
   * See {buyerEscrowDeposit}
   */
  function getBuyerWallet(address _ledger, uint256 _assetId) external view returns (address wallet);

  /**
   * @dev Returns the escrowed `_assetId` by the seller of asset `_assetId`
   *
   * See {sellerEscrowDeposit}
   */
  function getSellerDeposit(address _ledger, uint256 _assetId) external view returns (uint256 amount);

  /**
   * @dev Returns the escrowed amount by the buyer of asset `_assetId`
   *
   * See {buyerEscrowDeposit}
   */
  function getBuyerDeposit(address _ledger, uint256 _assetId) external view returns (uint256 amount);

  /**
   * @dev Returns the wallet address of the creator of asset `_assetId`
   *
   * See {sellerEscrowDeposit}
   */
  function getCreatorWallet(address _ledger, uint256 _assetId) external view returns (address wallet);

  /**
   * @dev Returns the amount of the creator's share of asset `_assetId`
   *
   * See {sellerEscrowDeposit}
   */
  function getCreatorShare(address _ledger, uint256 _assetId) external view returns (uint256 amount);

  /**
   * @dev Returns true if an asset has been sold for retail and will be considered resale moving forward
   */
  function getAssetIsResale(address _ledger, uint256 _assetId) external view returns (bool resale);

  /**
   * @dev Returns an array of all retailed asset IDs for ledger `_ledger`
   */
  function getRetailedAssets(address _ledger) external view returns (uint256[] memory assets);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import './IRadRouter.sol';
import './RevenueSplitMapping.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

contract RadRouter is IRadRouter, ERC721Holder {
  using RevenueSplitMapping for RevMap;

  struct Ledger {
    RevMap RetailSplits;
    RevMap ResaleSplits;
    mapping (uint256 => Asset) Assets;
    uint256[] retailedAssets;
  }

  struct Asset {
    address owner; // does not change on escrow, only through sale
    uint256 minPrice;
    bool resale;
    Creator creator;
    Buyer buyer;
  }

  struct Creator {
    address wallet;
    uint256 share;
  }

  struct Buyer {
    address wallet;
    uint256 amountEscrowed;
  }

  modifier onlyBy(address _account)
  {
    require(
      msg.sender == _account,
      'Sender not authorized'
    );
    _;
  }

  address public administrator_; // Rad administrator account
  mapping(address => Ledger) private Ledgers;

  /**
   * @dev Initializes the contract and sets the router administrator `administrator_`
   */
  constructor() { administrator_ = msg.sender; }

  /**
   * @dev See {IRadRouter-setRevenueSplit}.
   */
  function setRevenueSplit(address _ledger, address payable _stakeholder, uint256 _share, bool _retail) public onlyBy(administrator_) virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    require(_stakeholder != address(0), 'Stakeholder cannot be the zero address');
    require(_share >= 0 && _share <= 100, 'Stakeholder share must be at least 0% and at most 100%');

    uint256 total;

    if (_retail) {
      if (_share == 0) {
        Ledgers[_ledger].RetailSplits.remove(_stakeholder);
        emit RetailRevenueSplitChange(_ledger, _stakeholder, _share, Ledgers[_ledger].RetailSplits.size(), Ledgers[_ledger].RetailSplits.total);
        return true;
      }
      if (Ledgers[_ledger].RetailSplits.contains(_stakeholder)) {
        require(Ledgers[_ledger].RetailSplits.size() <= 5, 'Cannot split revenue more than 5 ways.');
        total = Ledgers[_ledger].RetailSplits.total - Ledgers[_ledger].RetailSplits.get(_stakeholder);
      } else {
        require(Ledgers[_ledger].RetailSplits.size() < 5, 'Cannot split revenue more than 5 ways.');
        total = Ledgers[_ledger].RetailSplits.total;
      }
    } else {
      if (_share == 0) {
        Ledgers[_ledger].ResaleSplits.remove(_stakeholder);
        emit ResaleRevenueSplitChange(_ledger, _stakeholder, _share, Ledgers[_ledger].ResaleSplits.size(), Ledgers[_ledger].ResaleSplits.total);
        return true;
      }
      if (Ledgers[_ledger].ResaleSplits.contains(_stakeholder)) {
        require(Ledgers[_ledger].ResaleSplits.size() <= 5, 'Cannot split revenue more than 5 ways.');
        total = Ledgers[_ledger].ResaleSplits.total - Ledgers[_ledger].RetailSplits.get(_stakeholder);
      } else {
        require(Ledgers[_ledger].ResaleSplits.size() < 5, 'Cannot split revenue more than 5 ways.');
        total = Ledgers[_ledger].ResaleSplits.total;
      }
    }
    require(_share + total <= 100, 'Total revenue split cannot exceed 100%');

    if (_retail) {
      Ledgers[_ledger].RetailSplits.set(_stakeholder, _share);
      emit RetailRevenueSplitChange(_ledger, _stakeholder, _share, Ledgers[_ledger].RetailSplits.size(), Ledgers[_ledger].RetailSplits.total);
    } else {
      Ledgers[_ledger].ResaleSplits.set(_stakeholder, _share);
      emit ResaleRevenueSplitChange(_ledger, _stakeholder, _share, Ledgers[_ledger].ResaleSplits.size(), Ledgers[_ledger].ResaleSplits.total);
    }

    success = true;
  }

  /**
   * @dev See {IRadRouter-getRevenueSplit}.
   */
  function getRevenueSplit(address _ledger, address payable _stakeholder, bool _retail) external view virtual override returns (uint256 share) {
    if (_retail) {
      share = Ledgers[_ledger].RetailSplits.get(_stakeholder);
    } else {
      share = Ledgers[_ledger].ResaleSplits.get(_stakeholder);
    }
  }

  /**
   * @dev See {IRadRouter-setRevenueSplits}.
   */
  function setRevenueSplits(address _ledger, address payable[] calldata _stakeholders, uint256[] calldata _shares, bool _retail) public virtual override returns (bool success) {
    require(_stakeholders.length == _shares.length, 'Stakeholders and shares must have equal length');
    require(_stakeholders.length <= 5, 'Cannot split revenue more than 5 ways.');
    if (_retail) {
      Ledgers[_ledger].RetailSplits.clear();
    } else {
      Ledgers[_ledger].ResaleSplits.clear();
    }
    for (uint256 i = 0; i < _stakeholders.length; i++) {
      setRevenueSplit(_ledger, _stakeholders[i], _shares[i], _retail);
    }

    success = true;
  }

  function getRevenueStakeholders(address _ledger, bool _retail) external view virtual override returns (address[] memory stakeholders) {
    if (_retail) {
      stakeholders = Ledgers[_ledger].RetailSplits.keys;
    } else {
      stakeholders = Ledgers[_ledger].ResaleSplits.keys;
    }
  }

  /**
   * @dev See {IRadRouter-setAssetMinPrice}.
   */
  function setAssetMinPrice(address _ledger, uint256 _assetId, uint256 _minPrice) public virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);
    require(msg.sender == owner || msg.sender == administrator_, 'Only the asset owner or Rad administrator can set the asset minimum price');
    require(owner == address(this) || ledger.isApprovedForAll(owner, address(this)) || ledger.getApproved(_assetId) == address(this), 'Must approve Rad Router as an operator before setting minimum price.');

    Ledgers[_ledger].Assets[_assetId].owner = owner;
    Ledgers[_ledger].Assets[_assetId].minPrice = _minPrice;

    emit AssetMinPriceChange(_ledger, _assetId, _minPrice);

    success = true;
  }

  /**
   * @dev See {IRadRouter-getAssetMinPrice}.
   */
  function getAssetMinPrice(address _ledger, uint256 _assetId) external view virtual override returns (uint256 minPrice) {
    minPrice = Ledgers[_ledger].Assets[_assetId].minPrice;
  }

  /**
   * @dev See {IRadRouter-setAssetMinPriceAndRevenueSplits}.
   */
  function setAssetMinPriceAndRevenueSplits(address _ledger, address payable[] calldata _stakeholders, uint256[] calldata _shares, bool _retail, uint256 _assetId, uint256 _minPrice) public virtual override returns (bool success) {
    success = setRevenueSplits(_ledger, _stakeholders, _shares, _retail) && setAssetMinPrice(_ledger, _assetId, _minPrice);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDeposit}.
   */
  function sellerEscrowDeposit(address _ledger, uint256 _assetId) public virtual override returns (bool success) {
    success = sellerEscrowDeposit(_ledger, _assetId, false, 0);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositWithCreatorShare}.
   */
  function sellerEscrowDepositWithCreatorShare(address _ledger, uint256 _assetId, uint256 _creatorResaleShare) public virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    require(_creatorResaleShare >= 0 && _creatorResaleShare <= 100, 'Creator share must be at least 0% and at most 100%');

    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);

    require(
      msg.sender == owner ||
      msg.sender == administrator_,
      'Only the asset owner or Rad administrator can change asset ownership'
    );

    require(
      ledger.isApprovedForAll(owner, address(this)) ||
      ledger.getApproved(_assetId) == address(this),
      'Must set Rad Router as an operator for all assets before depositing to escrow.'
    );

    if (
      Ledgers[_ledger].Assets[_assetId].creator.wallet == address(0) ||
      Ledgers[_ledger].Assets[_assetId].creator.wallet == owner ||
      Ledgers[_ledger].Assets[_assetId].owner == owner
    ) {

      if (Ledgers[_ledger].Assets[_assetId].creator.wallet == address(0)) {
        Ledgers[_ledger].Assets[_assetId].creator.wallet = owner;
      }

      require(
        Ledgers[_ledger].Assets[_assetId].creator.wallet == owner ||
        Ledgers[_ledger].Assets[_assetId].creator.share == 0 ||
        Ledgers[_ledger].Assets[_assetId].owner == owner,
        'Cannot set creator share.'
      );

      uint256 total = Ledgers[_ledger].Assets[_assetId].creator.share;
      address[] storage stakeholders = Ledgers[_ledger].ResaleSplits.keys;

      for (uint256 i = 0; i < stakeholders.length; i++) {
        total += Ledgers[_ledger].ResaleSplits.get(stakeholders[i]);
      }

      require(total <= 100, 'Creator share cannot exceed total ledger stakeholder when it is 100.');

      Ledgers[_ledger].Assets[_assetId].creator.share = _creatorResaleShare;
    }

    success = sellerEscrowDeposit(_ledger, _assetId, false, 0);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositWithCreatorShareBatch}.
   */
  function sellerEscrowDepositWithCreatorShareBatch(address _ledger, uint256[] calldata _assetIds, uint256 _creatorResaleShare) public virtual override returns (bool success) {
    success = false;

    for (uint256 i = 0; i < _assetIds.length; i++) {
      if (!sellerEscrowDepositWithCreatorShare(_ledger, _assetIds[i], _creatorResaleShare)) {
        success = false;
        break;
      } else {
        success = true;
      }
    }
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositWithCreatorShareWithMinPrice}.
   */
  function sellerEscrowDepositWithCreatorShareWithMinPrice(address _ledger, uint256 _assetId, uint256 _creatorResaleShare, uint256 _minPrice) public virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    require(_creatorResaleShare >= 0 && _creatorResaleShare <= 100, 'Creator share must be at least 0% and at most 100%');

    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);

    require(
      msg.sender == owner ||
      msg.sender == administrator_,
      'Only the asset owner or Rad administrator can change asset ownership'
    );

    require(
      ledger.isApprovedForAll(owner, address(this)) ||
      ledger.getApproved(_assetId) == address(this),
      'Must set Rad Router as an operator for all assets before depositing to escrow.'
    );

    if (
      Ledgers[_ledger].Assets[_assetId].creator.wallet == address(0) ||
      Ledgers[_ledger].Assets[_assetId].creator.wallet == owner ||
      Ledgers[_ledger].Assets[_assetId].owner == owner
    ) {
      if (Ledgers[_ledger].Assets[_assetId].creator.wallet == address(0)) {
        Ledgers[_ledger].Assets[_assetId].creator.wallet = owner;
      }

      require(
        Ledgers[_ledger].Assets[_assetId].creator.wallet == owner ||
        Ledgers[_ledger].Assets[_assetId].creator.share == 0 ||
        Ledgers[_ledger].Assets[_assetId].owner == owner,
        'Cannot set creator share.'
      );

      uint256 total = Ledgers[_ledger].Assets[_assetId].creator.share;
      address[] storage stakeholders = Ledgers[_ledger].ResaleSplits.keys;

      for (uint256 i = 0; i < stakeholders.length; i++) {
        total += Ledgers[_ledger].ResaleSplits.get(stakeholders[i]);
      }

      require(total <= 100, 'Creator share cannot exceed total ledger stakeholder when it is 100.');

      Ledgers[_ledger].Assets[_assetId].creator.share = _creatorResaleShare;
    }

    success = sellerEscrowDeposit(_ledger, _assetId, true, _minPrice);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositWithCreatorShareWithMinPriceBatch}.
   */
  function sellerEscrowDepositWithCreatorShareWithMinPriceBatch(address _ledger, uint256[] calldata _assetIds, uint256 _creatorResaleShare, uint256 _minPrice) public virtual override returns (bool success) {
    success = false;
    for (uint256 i = 0; i < _assetIds.length; i++) {
      if (!sellerEscrowDepositWithCreatorShareWithMinPrice(_ledger, _assetIds[i], _creatorResaleShare, _minPrice)) {
        success = false;
        break;
      } else {
        success = true;
      }
    }
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDeposit}.
   */
  function sellerEscrowDeposit(address _ledger, uint256 _assetId, bool _setMinPrice, uint256 _minPrice) public virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);
    require(msg.sender == owner || msg.sender == administrator_, 'Only the asset owner or Rad administrator can change asset ownership');
    require(ledger.isApprovedForAll(owner, address(this)) || ledger.getApproved(_assetId) == address(this), 'Must set Rad Router as an operator for all assets before depositing to escrow');

    if (_setMinPrice) {
      setAssetMinPrice(_ledger, _assetId, _minPrice);
    }

    Ledgers[_ledger].Assets[_assetId].owner = owner;

    ledger.safeTransferFrom(owner, address(this), _assetId);

    if (Ledgers[_ledger].Assets[_assetId].buyer.wallet != address(0)) {
      _fulfill(_ledger, _assetId);
    }

    emit SellerEscrowChange(_ledger, _assetId, owner, true);

    success = true;
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositBatch}.
   */
  function sellerEscrowDepositBatch(address _ledger, uint256[] calldata _assetIds) external virtual override returns (bool success) {
    success = sellerEscrowDepositBatch(_ledger, _assetIds, false, 0);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositBatch}.
   */
  function sellerEscrowDepositBatch(address _ledger, uint256[] calldata _assetIds, bool _setMinPrice, uint256 _minPrice) public virtual override returns (bool success) {
    for (uint256 i = 0; i < _assetIds.length; i++) {
      sellerEscrowDeposit(_ledger, _assetIds[i], _setMinPrice, _minPrice);
    }

    success = true;
  }

  /**
   * @dev See {IRadRouter-sellerEscrowWithdraw}.
   */
  function sellerEscrowWithdraw(address _ledger, uint256 _assetId) external virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    IERC721 ledger = IERC721(_ledger);
    address owner = Ledgers[_ledger].Assets[_assetId].owner;
    require(msg.sender == owner || msg.sender == administrator_, 'Only the asset owner or Rad administrator can change asset ownership');
    require(ledger.isApprovedForAll(owner, address(this)), 'Must set Rad Router as an operator for all assets before depositing to escrow');

    Ledgers[_ledger].Assets[_assetId].creator.wallet = address(0);
    Ledgers[_ledger].Assets[_assetId].creator.share = 0;

    ledger.safeTransferFrom(address(this), owner, _assetId);

    emit SellerEscrowChange(_ledger, _assetId, owner, false);

    success = true;
  }

  /**
   * @dev See {IRadRouter-buyerEscrowDeposit}.
   */
  function buyerEscrowDeposit(address _ledger, uint256 _assetId) external payable virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');

    require(
      Ledgers[_ledger].Assets[_assetId].buyer.wallet == address(0) ||
      Ledgers[_ledger].Assets[_assetId].buyer.wallet == msg.sender,
      'Another buyer has already escrowed'
    );

    require(
      Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed + msg.value >= Ledgers[_ledger].Assets[_assetId].minPrice,
      'Buyer did not send enough ETH'
    );

    Ledgers[_ledger].Assets[_assetId].buyer.wallet = msg.sender;
    Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed += msg.value;

    IERC721 ledger = IERC721(_ledger);

    if (ledger.ownerOf(_assetId) == address(this)) {
      _fulfill(_ledger, _assetId);
    }

    emit BuyerEscrowChange(_ledger, _assetId, msg.sender, true);

    success = true;
  }

  /**
   * @dev See {IRadRouter-buyerEscrowWithdraw}.
   */
  function buyerEscrowWithdraw(address _ledger, uint256 _assetId) external virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    require(
      msg.sender == Ledgers[_ledger].Assets[_assetId].buyer.wallet ||
      msg.sender == Ledgers[_ledger].Assets[_assetId].owner ||
      msg.sender == administrator_,
      'msg.sender must be the buyer, seller, or Rad operator'
    );

    payable(Ledgers[_ledger].Assets[_assetId].buyer.wallet).transfer(Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed);

    Ledgers[_ledger].Assets[_assetId].buyer.wallet = address(0);
    Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed = 0;

    emit BuyerEscrowChange(_ledger, _assetId, msg.sender, false);

    success = true;
  }

  /**
   * @dev See {IRadRouter-getSellerWallet}.
   */
  function getSellerWallet(address _ledger, uint256 _assetId) public view override returns (address wallet) {
    if (Ledgers[_ledger].Assets[_assetId].owner == address(0)) {
      require(_ledger != address(0), 'Asset ledger cannot be the zero address');
      IERC721 ledger = IERC721(_ledger);
      wallet = ledger.ownerOf(_assetId);
    } else {
      wallet = Ledgers[_ledger].Assets[_assetId].owner;
    }
  }

  /**
   * @dev See {IRadRouter-getSellerWallet}.
   */
  function getSellerDeposit(address _ledger, uint256 _assetId) public view override returns (uint256 amount) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);

    if (owner == address(this)) {
      return _assetId;
    }

    return 0;
  }

  /**
   * @dev See {IRadRouter-getBuyerWallet}.
   */
  function getBuyerWallet(address _ledger, uint256 _assetId) public view override returns (address wallet) {
    wallet = Ledgers[_ledger].Assets[_assetId].buyer.wallet;
  }

  /**
   * @dev See {IRadRouter-getBuyerDeposit}.
   */
  function getBuyerDeposit(address _ledger, uint256 _assetId) public view override returns (uint256 amount) {
    amount = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed;
  }

  /**
   * @dev See {IRadRouter-getAssetIsResale}.
   */
  function getAssetIsResale(address _ledger, uint256 _assetId) public view override returns (bool resale) {
    resale = Ledgers[_ledger].Assets[_assetId].resale;
  }

  /**
   * @dev See {IRadRouter-getRetailedAssets}.
   */
  function getRetailedAssets(address _ledger) public view override returns (uint256[] memory assets) {
    assets = Ledgers[_ledger].retailedAssets;
  }

  /**
   * @dev See {IRadRouter-getCreatorWallet}.
   */
  function getCreatorWallet(address _ledger, uint256 _assetId) public view override returns (address wallet) {
    wallet = Ledgers[_ledger].Assets[_assetId].creator.wallet;
  }

  /**
   * @dev See {IRadRouter-getCreatorShare}.
   */
  function getCreatorShare(address _ledger, uint256 _assetId) public view override returns (uint256 amount) {
    amount = Ledgers[_ledger].Assets[_assetId].creator.share;
  }

  /**
   * @dev Fulfills asset sale transaction and pays out all revenue split stakeholders
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_assetId` owner must be this contract
   * - `_assetId` buyer must not be the zero address
   *
   * Emits a {EscrowFulfill} event.
   */
  function _fulfill(address _ledger, uint256 _assetId) internal virtual returns (bool success) {
    IERC721 ledger = IERC721(_ledger);

    require(
      ledger.ownerOf(_assetId) == address(this),
      'Seller has not escrowed'
    );

    require(
      Ledgers[_ledger].Assets[_assetId].buyer.wallet != address(0),
      'Buyer has not escrowed'
    );

    require(
      Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed >= Ledgers[_ledger].Assets[_assetId].minPrice,
      'Buyer escrow amount is less than asset min price'
    );

    ledger.safeTransferFrom(
      address(this),
      Ledgers[_ledger].Assets[_assetId].buyer.wallet,
      _assetId
    );

    if (!Ledgers[_ledger].Assets[_assetId].resale) {
      if (Ledgers[_ledger].RetailSplits.size() > 0) {
        uint256 totalShareSplit = 0;

        for (uint256 i = 0; i < Ledgers[_ledger].RetailSplits.size(); i++) {
          address stakeholder = Ledgers[_ledger].RetailSplits.getKeyAtIndex(i);
          uint256 share = Ledgers[_ledger].RetailSplits.get(stakeholder);

          if (totalShareSplit + share > 100) {
            share = totalShareSplit + share - 100;
          }

          uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * share / 100;
          payable(stakeholder).transfer(payout);
          emit StakeholderPayout(_ledger, _assetId, stakeholder, payout, share, true);
          totalShareSplit += share;

          // ignore other share stake holders if total max split has been reached
          if (totalShareSplit >= 100) {
            break;
          }
        }

        if (totalShareSplit < 100) {
          uint256 remainingShare = 100 - totalShareSplit;
          uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * remainingShare / 100;
          payable(Ledgers[_ledger].Assets[_assetId].owner).transfer(payout);
          emit StakeholderPayout(_ledger, _assetId, Ledgers[_ledger].Assets[_assetId].owner, payout, remainingShare, true);
        }
      } else { // if no revenue split is defined, send all to asset owner
        uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed;
        payable(Ledgers[_ledger].Assets[_assetId].owner).transfer(payout);
        emit StakeholderPayout(_ledger, _assetId, Ledgers[_ledger].Assets[_assetId].owner, payout, 100, true);
      }

      Ledgers[_ledger].Assets[_assetId].resale = true;
      Ledgers[_ledger].retailedAssets.push(_assetId);
    } else {
      uint256 totalShareSplit = 0;

      if (
        Ledgers[_ledger].Assets[_assetId].creator.share > 0 &&
        Ledgers[_ledger].Assets[_assetId].creator.wallet != address(0)
      ) {
        uint256 creatorPayout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * Ledgers[_ledger].Assets[_assetId].creator.share / 100;

        if (creatorPayout > 0) {
          totalShareSplit = Ledgers[_ledger].Assets[_assetId].creator.share;
          payable(Ledgers[_ledger].Assets[_assetId].creator.wallet).transfer(creatorPayout);
        }

        emit StakeholderPayout(
          _ledger,
          _assetId,
          Ledgers[_ledger].Assets[_assetId].creator.wallet,
          creatorPayout,
          Ledgers[_ledger].Assets[_assetId].creator.share,
          false);
      }

      if (Ledgers[_ledger].ResaleSplits.size() > 0) {
        for (uint256 i = 0; i < Ledgers[_ledger].ResaleSplits.size(); i++) {
          address stakeholder = Ledgers[_ledger].ResaleSplits.getKeyAtIndex(i);
          uint256 share = Ledgers[_ledger].ResaleSplits.get(stakeholder) - (Ledgers[_ledger].Assets[_assetId].creator.share / 100);

          if (totalShareSplit + share > 100) {
            share = totalShareSplit + share - 100;
          }

          uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * share / 100;

          payable(stakeholder).transfer(payout);
          emit StakeholderPayout(_ledger, _assetId, stakeholder, payout, share, false);

          totalShareSplit += share;

          // ignore other share stake holders if total max split has been reached
          if (totalShareSplit >= 100) {
            break;
          }
        }

        if (totalShareSplit < 100) {
          uint256 remainingShare = 100 - totalShareSplit;
          uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * remainingShare / 100;
          payable(Ledgers[_ledger].Assets[_assetId].owner).transfer(payout);
          emit StakeholderPayout(_ledger, _assetId, Ledgers[_ledger].Assets[_assetId].owner, payout, remainingShare, false);
        }
      } else { // if no revenue split is defined, send all to asset owner
        uint256 remainingShare = 100 - totalShareSplit;
        uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * remainingShare / 100;
        payable(Ledgers[_ledger].Assets[_assetId].owner).transfer(payout);
        emit StakeholderPayout(_ledger, _assetId, Ledgers[_ledger].Assets[_assetId].owner, payout, remainingShare, false);
      }
    }

    emit EscrowFulfill(
      _ledger,
      _assetId,
      Ledgers[_ledger].Assets[_assetId].owner,
      Ledgers[_ledger].Assets[_assetId].buyer.wallet,
      Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed
    );

    Ledgers[_ledger].Assets[_assetId].owner = Ledgers[_ledger].Assets[_assetId].buyer.wallet;
    Ledgers[_ledger].Assets[_assetId].minPrice = 0;
    Ledgers[_ledger].Assets[_assetId].buyer.wallet = address(0);
    Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed = 0;

    success = true;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.8 <0.9.0;

struct RevMap {
    address[] keys;
    uint256 total;
    mapping(address => IndexValue) values;
}

struct IndexValue {
    uint256 value;
    uint256 indexOf;
    bool inserted;
}

// https://solidity-by-example.org/app/iterable-mapping/
library RevenueSplitMapping {
    function get(RevMap storage map, address key) external view returns (uint256) {
        return map.values[key].value;
    }

    function getKeyAtIndex(RevMap storage map, uint256 index) external view returns (address) {
        return map.keys[index];
    }

    function size(RevMap storage map) external view returns (uint256) {
        return map.keys.length;
    }

    function set(RevMap storage map, address key, uint256 val) external {
        if (map.values[key].inserted) {
            map.total-=map.values[key].value;
            map.values[key].value = val;
            map.total+=val;
        } else {
            map.values[key].inserted = true;
            map.values[key].value = val;
            map.total+=val;
            map.values[key].indexOf = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(RevMap storage map, address key) external {
        if (!map.values[key].inserted) {
            return;
        }

        map.total-=map.values[key].value;

        uint256 index = map.values[key].indexOf;
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.values[lastKey].indexOf = index;
        delete map.values[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }

    function contains(RevMap storage map, address key) external view returns(bool) {
        return map.values[key].inserted;
    }

    function clear(RevMap storage map) external {
        for (uint256 i = 0; i < map.keys.length; i++) {
            delete map.values[map.keys[i]];
        }
        delete map.keys;
        map.total = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/Users/dom/repos/rad-contracts/contracts/RevenueSplitMapping.sol": {
      "RevenueSplitMapping": "0xebdA821D01ffEC8f07d62876095FFB98EE57c854"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}