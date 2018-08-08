pragma solidity 0.4.19;


contract Admin {
    address public godAddress;
    address public managerAddress;
    address public bursarAddress;

    // God has more priviledges than other admins
    modifier requireGod() {
        require(msg.sender == godAddress);
        _;
    }

    modifier requireManager() {
        require(msg.sender == managerAddress);
        _;
    }

    modifier requireAdmin() {
        require(msg.sender == managerAddress || msg.sender == godAddress);
        _;
    }

    modifier requireBursar() {
        require(msg.sender == bursarAddress);
      _;
    }

    /// @notice Assigns a new address to act as the God. Only available to the current God.
    /// @param _newGod The address of the new God
    function setGod(address _newGod) external requireGod {
        require(_newGod != address(0));

        godAddress = _newGod;
    }

    /// @notice Assigns a new address to act as the Manager. Only available to the current God.
    /// @param _newManager The address of the new Manager
    function setManager(address _newManager) external requireGod {
        require(_newManager != address(0));

        managerAddress = _newManager;
    }

    /// @notice Assigns a new address to act as the Bursar. Only available to the current God.
    /// @param _newBursar The address of the new Bursar
    function setBursar(address _newBursar) external requireGod {
        require(_newBursar != address(0));

        bursarAddress = _newBursar;
    }

    /// @notice !!! COMPLETELY DESTROYS THE CONTRACT !!!
    function destroy() external requireGod {
        selfdestruct(godAddress);
    }
}



contract Pausable is Admin {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external requireAdmin whenNotPaused {
        paused = true;
    }

    function unpause() external requireGod whenPaused {
        paused = false;
    }
}


contract CryptoFamousBase is Pausable {

  // DATA TYPES
  struct Card {
        // Social network type id (1 - Twitter, others TBD)
        uint8 socialNetworkType;
        // The social network id of the social account backing this card.
        uint64 socialId;
        // The ethereum address that most recently claimed this card.
        address claimer;
        // Increased whenever the card is claimed by an address
        uint16 claimNonce;
        // Reserved for future use
        uint8 reserved1;
  }

  struct SaleInfo {
      uint128 timestamp;
      uint128 price;
  }

}


contract CryptoFamousOwnership is CryptoFamousBase {
  // EVENTS
  /// @dev emitted when a new Card is created. Can happen when a social identity is claimed or stolen for the first time.
  event CardCreated(uint256 indexed cardId, uint8 socialNetworkType, uint64 socialId, address claimer, address indexed owner);

  // STORAGE
  /// @dev contains all the Cards in the system. Card with ID 0 is invalid.
  Card[] public allCards;

  /// @dev SocialNetworkType -> (SocialId -> CardId)
  mapping (uint8 => mapping (uint64 => uint256)) private socialIdentityMappings;

  /// @dev getter for `socialIdentityMappings`
  function socialIdentityToCardId(uint256 _socialNetworkType, uint256 _socialId) public view returns (uint256 cardId) {
    uint8 _socialNetworkType8 = uint8(_socialNetworkType);
    require(_socialNetworkType == uint256(_socialNetworkType8));

    uint64 _socialId64 = uint64(_socialId);
    require(_socialId == uint256(_socialId64));

    cardId = socialIdentityMappings[_socialNetworkType8][_socialId64];
    return cardId;
  }

  mapping (uint8 => mapping (address => uint256)) private claimerAddressToCardIdMappings;

  /// @dev returns the last Card ID claimed by `_claimerAddress` in network with `_socialNetworkType`
  function lookUpClaimerAddress(uint256 _socialNetworkType, address _claimerAddress) public view returns (uint256 cardId) {
    uint8 _socialNetworkType8 = uint8(_socialNetworkType);
    require(_socialNetworkType == uint256(_socialNetworkType8));

    cardId = claimerAddressToCardIdMappings[_socialNetworkType8][_claimerAddress];
    return cardId;
  }

  /// @dev A mapping from Card ID to the timestamp of the first completed Claim of that Card
  mapping (uint256 => uint128) public cardIdToFirstClaimTimestamp;

  /// @dev A mapping from Card ID to the current owner address of that Card
  mapping (uint256 => address) public cardIdToOwner;

  /// @dev A mapping from owner address to the number of Cards currently owned by it
  mapping (address => uint256) internal ownerAddressToCardCount;

  function _changeOwnership(address _from, address _to, uint256 _cardId) internal whenNotPaused {
      ownerAddressToCardCount[_to]++;
      cardIdToOwner[_cardId] = _to;

      if (_from != address(0)) {
          ownerAddressToCardCount[_from]--;
      }
  }

  function _recordFirstClaimTimestamp(uint256 _cardId) internal {
    cardIdToFirstClaimTimestamp[_cardId] = uint128(now); //solhint-disable-line not-rely-on-time
  }

  function _createCard(
      uint256 _socialNetworkType,
      uint256 _socialId,
      address _owner,
      address _claimer
  )
      internal
      whenNotPaused
      returns (uint256)
  {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint16 claimNonce = 0;
      if (_claimer != address(0)) {
        claimNonce = 1;
      }

      Card memory _card = Card({
          socialNetworkType: _socialNetworkType8,
          socialId: _socialId64,
          claimer: _claimer,
          claimNonce: claimNonce,
          reserved1: 0
      });
      uint256 newCardId = allCards.push(_card) - 1;
      socialIdentityMappings[_socialNetworkType8][_socialId64] = newCardId;

      if (_claimer != address(0)) {
        claimerAddressToCardIdMappings[_socialNetworkType8][_claimer] = newCardId;
        _recordFirstClaimTimestamp(newCardId);
      }

      // event CardCreated(uint256 indexed cardId, uint8 socialNetworkType, uint64 socialId, address claimer, address indexed owner);
      CardCreated(
          newCardId,
          _socialNetworkType8,
          _socialId64,
          _claimer,
          _owner
      );

      _changeOwnership(0, _owner, newCardId);

      return newCardId;
  }

  /// @dev Returns the toal number of Cards in existence
  function totalNumberOfCards() public view returns (uint) {
      return allCards.length - 1;
  }

  /// @notice Returns a list of all Card IDs currently owned by `_owner`
  /// @dev (this thing iterates, don&#39;t call from smart contract code)
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
      uint256 tokenCount = ownerAddressToCardCount[_owner];

      if (tokenCount == 0) {
          return new uint256[](0);
      }

      uint256[] memory result = new uint256[](tokenCount);
      uint256 total = totalNumberOfCards();
      uint256 resultIndex = 0;

      uint256 cardId;

      for (cardId = 1; cardId <= total; cardId++) {
          if (cardIdToOwner[cardId] == _owner) {
              result[resultIndex] = cardId;
              resultIndex++;
          }
      }

      return result;
  }
}


contract CryptoFamousStorage is CryptoFamousOwnership {
  function CryptoFamousStorage() public {
      godAddress = msg.sender;
      managerAddress = msg.sender;
      bursarAddress = msg.sender;

      // avoid zero identifiers
      _createCard(0, 0, address(0), address(0));
  }

  function() external payable {
      // just let msg.value be added to this.balance
      FallbackEtherReceived(msg.sender, msg.value);
  }

  event FallbackEtherReceived(address from, uint256 value);

  /// @dev Only this address will be allowed to call functions marked with `requireAuthorizedLogicContract`
  address public authorizedLogicContractAddress;
  modifier requireAuthorizedLogicContract() {
      require(msg.sender == authorizedLogicContractAddress);
      _;
  }

  /// @dev mapping from Card ID to information about that card&#39;s last trade
  mapping (uint256 => SaleInfo) public cardIdToSaleInfo;

  /// @dev mapping from Card ID to the current value stashed away for a future claimer
  mapping (uint256 => uint256) public cardIdToStashedPayout;
  /// @dev total amount of stashed payouts
  uint256 public totalStashedPayouts;

  /// @dev if we fail to send any value to a Card&#39;s previous owner as part of the
  /// invite/steal transaction we&#39;ll hold it in this contract. This mapping records the amount
  /// owed to that "previous owner".
  mapping (address => uint256) public addressToFailedOldOwnerTransferAmount;
  /// @dev total amount of failed old owner transfers
  uint256 public totalFailedOldOwnerTransferAmounts;

  /// @dev mapping from Card ID to that card&#39;s current perk text
  mapping (uint256 => string) public cardIdToPerkText;

  function authorized_setCardPerkText(uint256 _cardId, string _perkText) external requireAuthorizedLogicContract {
    cardIdToPerkText[_cardId] = _perkText;
  }

  function setAuthorizedLogicContractAddress(address _newAuthorizedLogicContractAddress) external requireGod {
    authorizedLogicContractAddress = _newAuthorizedLogicContractAddress;
  }

  function authorized_changeOwnership(address _from, address _to, uint256 _cardId) external requireAuthorizedLogicContract {
    _changeOwnership(_from, _to, _cardId);
  }

  function authorized_createCard(uint256 _socialNetworkType, uint256 _socialId, address _owner, address _claimer) external requireAuthorizedLogicContract returns (uint256) {
    return _createCard(_socialNetworkType, _socialId, _owner, _claimer);
  }

  function authorized_updateSaleInfo(uint256 _cardId, uint256 _sentValue) external requireAuthorizedLogicContract {
    cardIdToSaleInfo[_cardId] = SaleInfo(uint128(now), uint128(_sentValue)); // solhint-disable-line not-rely-on-time
  }

  function authorized_updateCardClaimerAddress(uint256 _cardId, address _claimerAddress) external requireAuthorizedLogicContract {
    Card storage card = allCards[_cardId];
    if (card.claimer == address(0)) {
      _recordFirstClaimTimestamp(_cardId);
    }
    card.claimer = _claimerAddress;
    card.claimNonce += 1;
  }

  function authorized_updateCardReserved1(uint256 _cardId, uint8 _reserved) external requireAuthorizedLogicContract {
    uint8 _reserved8 = uint8(_reserved);
    require(_reserved == uint256(_reserved8));

    Card storage card = allCards[_cardId];
    card.reserved1 = _reserved8;
  }

  function authorized_triggerStashedPayoutTransfer(uint256 _cardId) external requireAuthorizedLogicContract {
    Card storage card = allCards[_cardId];
    address claimerAddress = card.claimer;

    require(claimerAddress != address(0));

    uint256 stashedPayout = cardIdToStashedPayout[_cardId];

    require(stashedPayout > 0);

    cardIdToStashedPayout[_cardId] = 0;
    totalStashedPayouts -= stashedPayout;

    claimerAddress.transfer(stashedPayout);
  }

  function authorized_recordStashedPayout(uint256 _cardId) external payable requireAuthorizedLogicContract {
      cardIdToStashedPayout[_cardId] += msg.value;
      totalStashedPayouts += msg.value;
  }

  function authorized_recordFailedOldOwnerTransfer(address _oldOwner) external payable requireAuthorizedLogicContract {
      addressToFailedOldOwnerTransferAmount[_oldOwner] += msg.value;
      totalFailedOldOwnerTransferAmounts += msg.value;
  }

  // solhint-disable-next-line no-empty-blocks
  function authorized_recordPlatformFee() external payable requireAuthorizedLogicContract {
      // just let msg.value be added to this.balance
  }

  /// @dev returns the current contract balance after subtracting the amounts stashed away for others
  function netContractBalance() public view returns (uint256 balance) {
    balance = this.balance - totalStashedPayouts - totalFailedOldOwnerTransferAmounts;
    return balance;
  }

  /// @dev the Bursar account can use this to withdraw the contract&#39;s net balance
  function bursarPayOutNetContractBalance(address _to) external requireBursar {
      uint256 payout = netContractBalance();

      if (_to == address(0)) {
          bursarAddress.transfer(payout);
      } else {
          _to.transfer(payout);
      }
  }

  /// @dev Any wallet owed value that&#39;s recorded under `addressToFailedOldOwnerTransferAmount`
  /// can use this function to withdraw that value.
  function withdrawFailedOldOwnerTransferAmount() external whenNotPaused {
      uint256 failedTransferAmount = addressToFailedOldOwnerTransferAmount[msg.sender];

      require(failedTransferAmount > 0);

      addressToFailedOldOwnerTransferAmount[msg.sender] = 0;
      totalFailedOldOwnerTransferAmounts -= failedTransferAmount;

      msg.sender.transfer(failedTransferAmount);
  }
}


contract CryptoFamous is CryptoFamousBase {
    function CryptoFamous(address _storageContractAddress) public {
        godAddress = msg.sender;
        managerAddress = msg.sender;
        bursarAddress = msg.sender;
        verifierAddress = msg.sender;
        storageContract = CryptoFamousStorage(_storageContractAddress);
    }

    function() external payable {
        // just let msg.value be added to this.balance
        FallbackEtherReceived(msg.sender, msg.value);
    }

    event FallbackEtherReceived(address from, uint256 value);

    event EconomyParametersUpdated(uint128 _newMinCardPrice, uint128 _newInitialCardPrice, uint128 _newPurchasePremiumRate, uint128 _newHourlyValueDecayRate, uint128 _newOwnerTakeShare, uint128 _newCardTakeShare, uint128 _newPlatformFeeRate);

    /// @dev Fired whenever a Card is stolen.
    event CardStealCompleted(uint256 indexed cardId, address claimer, uint128 oldPrice, uint128 sentValue, address indexed prevOwner, address indexed newOwner, uint128 totalOwnerPayout, uint128 totalCardPayout);

    /// @dev Fired whenever a Card is claimed.
    event CardClaimCompleted(uint256 indexed cardId, address previousClaimer, address newClaimer, address indexed owner);

    /// @dev Fired whenever a Card&#39;s perk text is updated.
    event CardPerkTextUpdated(uint256 indexed cardId, string newPerkText);

    /// @notice Reference to the contract that handles the creation and ownership changes between cards.
    CryptoFamousStorage public storageContract;

    uint16 private constant TWITTER = 1;

    // solhint-disable-next-line var-name-mixedcase
    uint128 public MIN_CARD_PRICE = 0.01 ether;
    function _setMinCardPrice(uint128 _newMinCardPrice) private {
        MIN_CARD_PRICE = _newMinCardPrice;
    }

    // solhint-disable-next-line var-name-mixedcase
    uint128 public INITIAL_CARD_PRICE = 0.01 ether;
    function _setInitialCardPrice(uint128 _newInitialCardPrice) private {
        INITIAL_CARD_PRICE = _newInitialCardPrice;
    }

    // solhint-disable-next-line var-name-mixedcase
    uint128 public PURCHASE_PREMIUM_RATE = 10000; // basis points OF LAST SALE PRICE
    function _setPurchasePremiumRate(uint128 _newPurchasePremiumRate) private {
        PURCHASE_PREMIUM_RATE = _newPurchasePremiumRate;
    }

    // solhint-disable-next-line var-name-mixedcase
    uint128 public HOURLY_VALUE_DECAY_RATE = 21; // basis points OF STARTING PRICE
    function _setHourlyValueDecayRate(uint128 _newHourlyValueDecayRate) private {
        HOURLY_VALUE_DECAY_RATE = _newHourlyValueDecayRate;
    }

    // solhint-disable var-name-mixedcase
    uint128 public OWNER_TAKE_SHARE = 5000; // basis points OF PROFIT
    uint128 public CARD_TAKE_SHARE = 5000; // basis points OF PROFIT
    // solhint-enable var-name-mixedcase

    function _setProfitSharingParameters(uint128 _newOwnerTakeShare, uint128 _newCardTakeShare) private {
      require(_newOwnerTakeShare + _newCardTakeShare == 10000);

      OWNER_TAKE_SHARE = _newOwnerTakeShare;
      CARD_TAKE_SHARE = _newCardTakeShare;
    }

    // solhint-disable-next-line var-name-mixedcase
    uint128 public PLATFORM_FEE_RATE = 600; // basis points OF PROFIT
    function _setPlatformFeeRate(uint128 _newPlatformFeeRate) private {
        require(_newPlatformFeeRate < 10000);
        PLATFORM_FEE_RATE = _newPlatformFeeRate;
    }

    /// @dev Used to update all the parameters of the economy in one go
    function setEconomyParameters(uint128 _newMinCardPrice, uint128 _newInitialCardPrice, uint128 _newPurchasePremiumRate, uint128 _newHourlyValueDecayRate, uint128 _newOwnerTakeShare, uint128 _newCardTakeShare, uint128 _newPlatformFeeRate) external requireAdmin {
        _setMinCardPrice(_newMinCardPrice);
        _setInitialCardPrice(_newInitialCardPrice);
        _setPurchasePremiumRate(_newPurchasePremiumRate);
        _setHourlyValueDecayRate(_newHourlyValueDecayRate);
        _setProfitSharingParameters(_newOwnerTakeShare, _newCardTakeShare);
        _setPlatformFeeRate(_newPlatformFeeRate);
        EconomyParametersUpdated(_newMinCardPrice, _newInitialCardPrice, _newPurchasePremiumRate, _newHourlyValueDecayRate, _newOwnerTakeShare, _newCardTakeShare, _newPlatformFeeRate);
    }

    address public verifierAddress;
    /// @notice Assigns a new address to act as the Verifier. Only available to the current God.
    /// @notice The Verifier address is used to confirm the authenticity of the claim signature.
    /// @param _newVerifier The address of the new Verifier
    function setVerifier(address _newVerifier) external requireGod {
        require(_newVerifier != address(0));

        verifierAddress = _newVerifier;
    }

    // mimicking eth_sign.
    function prefixed(bytes32 hash) private pure returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hash);
    }

    function claimTwitterId(uint256 _twitterId, address _claimerAddress, uint8 _v, bytes32 _r, bytes32 _s) external whenNotPaused returns (uint256) {
      return _claimSocialNetworkIdentity(TWITTER, _twitterId, _claimerAddress, _v, _r, _s);
    }

    function claimSocialNetworkIdentity(uint256 _socialNetworkType, uint256 _socialId, address _claimerAddress, uint8 _v, bytes32 _r, bytes32 _s) external whenNotPaused returns (uint256) {
      return _claimSocialNetworkIdentity(_socialNetworkType, _socialId, _claimerAddress, _v, _r, _s);
    }

    /// @dev claiming a social identity requires a signature provided by the CryptoFamous backend
    /// to verify the authenticity of the claim. Once a Card is claimed by an address, that address
    /// has access to the Card&#39;s current and future earnings on the system.
    function _claimSocialNetworkIdentity(uint256 _socialNetworkType, uint256 _socialId, address _claimerAddress, uint8 _v, bytes32 _r, bytes32 _s) private returns (uint256) {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);

      uint16 claimNonce = 0;
      if (cardId != 0) {
        (, , , claimNonce, ) = storageContract.allCards(cardId);
      }

      bytes32 prefixedAndHashedAgain = prefixed(
        keccak256(
          _socialNetworkType, _socialId, _claimerAddress, uint256(claimNonce)
        )
      );

      address recoveredSignerAddress = ecrecover(prefixedAndHashedAgain, _v, _r, _s);
      require(recoveredSignerAddress == verifierAddress);

      if (cardId == 0) {
        return storageContract.authorized_createCard(_socialNetworkType8, _socialId64, _claimerAddress, _claimerAddress);
      } else {
        _claimExistingCard(cardId, _claimerAddress);
        return cardId;
      }
    }

    function _claimExistingCard(uint256 _cardId, address _claimerAddress) private {
        address previousClaimer;
        (, , previousClaimer, ,) = storageContract.allCards(_cardId);
        address owner = storageContract.cardIdToOwner(_cardId);

        _updateCardClaimerAddress(_cardId, _claimerAddress);

        CardClaimCompleted(_cardId, previousClaimer, _claimerAddress, owner);

        uint256 stashedPayout = storageContract.cardIdToStashedPayout(_cardId);
        if (stashedPayout > 0) {
          _triggerStashedPayoutTransfer(_cardId);
        }
    }

    /// @dev The Card&#39;s perk text is displayed prominently on its profile and will likely be
    /// used for promotional reasons.
    function setCardPerkText(uint256 _cardId, string _perkText) external whenNotPaused {
      address cardClaimer;
      (, , cardClaimer, , ) = storageContract.allCards(_cardId);

      require(cardClaimer == msg.sender);

      require(bytes(_perkText).length <= 280);

      _updateCardPerkText(_cardId, _perkText);
      CardPerkTextUpdated(_cardId, _perkText);
    }

    function stealCardWithTwitterId(uint256 _twitterId) external payable whenNotPaused {
      _stealCardWithSocialIdentity(TWITTER, _twitterId);
    }

    function stealCardWithSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) external payable whenNotPaused {
      _stealCardWithSocialIdentity(_socialNetworkType, _socialId);
    }

    function _stealCardWithSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) private {
      // Avoid zeroth
      require(_socialId != 0);

      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);
      if (cardId == 0) {
        cardId = storageContract.authorized_createCard(_socialNetworkType8, _socialId64, address(0), address(0));
        _stealCardWithId(cardId);
      } else {
        _stealCardWithId(cardId);
      }
    }

    function stealCardWithId(uint256 _cardId) external payable whenNotPaused {
      // Avoid zeroth
      require(_cardId != 0);

      _stealCardWithId(_cardId);
    }

    function claimTwitterIdIfNeededThenStealCardWithTwitterId(
      uint256 _twitterIdToClaim,
      address _claimerAddress,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint256 _twitterIdToSteal
      ) external payable whenNotPaused returns (uint256) {
          return _claimIfNeededThenSteal(TWITTER, _twitterIdToClaim, _claimerAddress, _v, _r, _s, TWITTER, _twitterIdToSteal);
      }

    function claimIfNeededThenSteal(
      uint256 _socialNetworkTypeToClaim,
      uint256 _socialIdToClaim,
      address _claimerAddress,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint256 _socialNetworkTypeToSteal,
      uint256 _socialIdToSteal
      ) external payable whenNotPaused returns (uint256) {
          return _claimIfNeededThenSteal(_socialNetworkTypeToClaim, _socialIdToClaim, _claimerAddress, _v, _r, _s, _socialNetworkTypeToSteal, _socialIdToSteal);
    }

    /// @dev "Convenience" function allowing us to avoid forcing the user to go through an extra
    /// Ethereum transactions if they really, really want to do their first steal right now.
    function _claimIfNeededThenSteal(
      uint256 _socialNetworkTypeToClaim,
      uint256 _socialIdToClaim,
      address _claimerAddress,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint256 _socialNetworkTypeToSteal,
      uint256 _socialIdToSteal
      ) private returns (uint256) {
        uint8 _socialNetworkTypeToClaim8 = uint8(_socialNetworkTypeToClaim);
        require(_socialNetworkTypeToClaim == uint256(_socialNetworkTypeToClaim8));

        uint64 _socialIdToClaim64 = uint64(_socialIdToClaim);
        require(_socialIdToClaim == uint256(_socialIdToClaim64));

        uint256 claimedCardId = storageContract.socialIdentityToCardId(_socialNetworkTypeToClaim8, _socialIdToClaim64);

        address currentClaimer = address(0);
        if (claimedCardId != 0) {
          (, , currentClaimer, , ) = storageContract.allCards(claimedCardId);
        }

        if (currentClaimer == address(0)) {
          claimedCardId = _claimSocialNetworkIdentity(_socialNetworkTypeToClaim, _socialIdToClaim, _claimerAddress, _v, _r, _s);
        }

        _stealCardWithSocialIdentity(_socialNetworkTypeToSteal, _socialIdToSteal);

        return claimedCardId;
    }

    function _stealCardWithId(uint256 _cardId) private { // solhint-disable-line function-max-lines, code-complexity
        // Make sure the card already exists
        uint64 twitterId;
        address cardClaimer;
        (, twitterId, cardClaimer, , ) = storageContract.allCards(_cardId);
        require(twitterId != 0);

        address oldOwner = storageContract.cardIdToOwner(_cardId);
        address newOwner = msg.sender;

        // Making sure not stealing from self
        require(oldOwner != newOwner);

        require(newOwner != address(0));

        // Check for sent value overflow (which realistically wouldn&#39;t happen)
        uint128 sentValue = uint128(msg.value);
        require(uint256(sentValue) == msg.value);

        uint128 lastPrice;
        uint128 decayedPrice;
        uint128 profit;
        // uint128 ownerProfitTake;
        // uint128 cardProfitTake;
        uint128 totalOwnerPayout;
        uint128 totalCardPayout;
        uint128 platformFee;

        (lastPrice,
        decayedPrice,
        profit,
        , // ownerProfitTake,
        , // cardProfitTake,
        totalOwnerPayout,
        totalCardPayout,
        platformFee
        ) = currentPriceInfoOf(_cardId, sentValue);

        require(sentValue >= decayedPrice);

        _updateSaleInfo(_cardId, sentValue);
        storageContract.authorized_changeOwnership(oldOwner, newOwner, _cardId);

        CardStealCompleted(_cardId, cardClaimer, lastPrice, sentValue, oldOwner, newOwner, totalOwnerPayout, totalCardPayout);

        if (platformFee > 0) {
          _recordPlatformFee(platformFee);
        }

        if (totalCardPayout > 0) {
            if (cardClaimer == address(0)) {
                _recordStashedPayout(_cardId, totalCardPayout);
            } else {
                // Because the caller can manipulate the .send to fail, we need a fallback
                if (!cardClaimer.send(totalCardPayout)) {
                  _recordStashedPayout(_cardId, totalCardPayout);
                }
            }
        }

        if (totalOwnerPayout > 0) {
          if (oldOwner != address(0)) {
              // Because the caller can manipulate the .send to fail, we need a fallback
              if (!oldOwner.send(totalOwnerPayout)) { // solhint-disable-line multiple-sends
                _recordFailedOldOwnerTransfer(oldOwner, totalOwnerPayout);
              }
          }
        }
    }

    function currentPriceInfoOf(uint256 _cardId, uint256 _sentGrossPrice) public view returns (
        uint128 lastPrice,
        uint128 decayedPrice,
        uint128 profit,
        uint128 ownerProfitTake,
        uint128 cardProfitTake,
        uint128 totalOwnerPayout,
        uint128 totalCardPayout,
        uint128 platformFee
    ) {
        uint128 lastTimestamp;
        (lastTimestamp, lastPrice) = storageContract.cardIdToSaleInfo(_cardId);

        decayedPrice = decayedPriceFrom(lastPrice, lastTimestamp);
        require(_sentGrossPrice >= decayedPrice);

        platformFee = uint128(_sentGrossPrice) * PLATFORM_FEE_RATE / 10000;
        uint128 sentNetPrice = uint128(_sentGrossPrice) - platformFee;

        if (sentNetPrice > lastPrice) {
            profit = sentNetPrice - lastPrice;
            ownerProfitTake = profit * OWNER_TAKE_SHARE / 10000;
            cardProfitTake = profit * CARD_TAKE_SHARE / 10000;
        } else {
            profit = 0;
            ownerProfitTake = 0;
            cardProfitTake = 0;
        }

        totalOwnerPayout = ownerProfitTake + (sentNetPrice - profit);
        totalCardPayout = cardProfitTake;

        // Special adjustment if there is no current owner
        address currentOwner = storageContract.cardIdToOwner(_cardId);
        if (currentOwner == address(0)) {
          totalCardPayout = totalCardPayout + totalOwnerPayout;
          totalOwnerPayout = 0;
        }

        require(_sentGrossPrice >= (totalCardPayout + totalOwnerPayout + platformFee));

        return (lastPrice, decayedPrice, profit, ownerProfitTake, cardProfitTake, totalOwnerPayout, totalCardPayout, platformFee);
    }

    function decayedPriceFrom(uint256 _lastPrice, uint256 _lastTimestamp) public view returns (uint128 decayedPrice) {
        if (_lastTimestamp == 0) {
            decayedPrice = INITIAL_CARD_PRICE;
        } else {
            uint128 startPrice = uint128(_lastPrice) + (uint128(_lastPrice) * PURCHASE_PREMIUM_RATE / 10000);
            require(startPrice >= uint128(_lastPrice));

            uint128 secondsLapsed;
            if (now > _lastTimestamp) { // solhint-disable-line not-rely-on-time
                secondsLapsed = uint128(now) - uint128(_lastTimestamp); // solhint-disable-line not-rely-on-time
            } else {
                secondsLapsed = 0;
            }
            uint128 hoursLapsed = secondsLapsed / 1 hours;
            uint128 totalDecay = (hoursLapsed * (startPrice * HOURLY_VALUE_DECAY_RATE / 10000));

            if (totalDecay > startPrice) {
                decayedPrice = MIN_CARD_PRICE;
            } else {
                decayedPrice = startPrice - totalDecay;
                if (decayedPrice < MIN_CARD_PRICE) {
                  decayedPrice = MIN_CARD_PRICE;
                }
            }
        }

        return decayedPrice;
    }

    //////////////// STORAGE CONTRACT MUTATION

    function _updateSaleInfo(uint256 _cardId, uint256 _sentValue) private {
        storageContract.authorized_updateSaleInfo(_cardId, _sentValue);
    }

    function _updateCardClaimerAddress(uint256 _cardId, address _claimerAddress) private {
        storageContract.authorized_updateCardClaimerAddress(_cardId, _claimerAddress);
    }

    function _recordStashedPayout(uint256 _cardId, uint256 _stashedPayout) private {
        storageContract.authorized_recordStashedPayout.value(_stashedPayout)(_cardId);
    }

    function _triggerStashedPayoutTransfer(uint256 _cardId) private {
        storageContract.authorized_triggerStashedPayoutTransfer(_cardId);
    }

    function _recordFailedOldOwnerTransfer(address _oldOwner, uint256 _oldOwnerPayout) private {
        storageContract.authorized_recordFailedOldOwnerTransfer.value(_oldOwnerPayout)(_oldOwner);
    }

    function _recordPlatformFee(uint256 _platformFee) private {
        storageContract.authorized_recordPlatformFee.value(_platformFee)();
    }

    function _updateCardPerkText(uint256 _cardId, string _perkText) private {
        storageContract.authorized_setCardPerkText(_cardId, _perkText);
    }

    /////////////// QUERY FUNCTIONS

    // solhint-disable-next-line func-order
    function decayedPriceOfTwitterId(uint256 _twitterId) public view returns (uint128) {
      return decayedPriceOfSocialIdentity(TWITTER, _twitterId);
    }

    function decayedPriceOfSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) public view returns (uint128) {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);

      return decayedPriceOfCard(cardId);
    }

    function decayedPriceOfCard(uint256 _cardId) public view returns (uint128) {
      uint128 lastTimestamp;
      uint128 lastPrice;
      (lastTimestamp, lastPrice) = storageContract.cardIdToSaleInfo(_cardId);
      return decayedPriceFrom(lastPrice, lastTimestamp);
    }

    function ownerOfTwitterId(uint256 _twitterId) public view returns (address) {
      return ownerOfSocialIdentity(TWITTER, _twitterId);
    }

    function ownerOfSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) public view returns (address) {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);

      address ownerAddress = storageContract.cardIdToOwner(cardId);
      return ownerAddress;
    }

    function claimerOfTwitterId(uint256 _twitterId) public view returns (address) {
      return claimerOfSocialIdentity(TWITTER, _twitterId);
    }

    function claimerOfSocialIdentity(uint256 _socialNetworkType, uint256 _socialId) public view returns (address) {
      uint8 _socialNetworkType8 = uint8(_socialNetworkType);
      require(_socialNetworkType == uint256(_socialNetworkType8));

      uint64 _socialId64 = uint64(_socialId);
      require(_socialId == uint256(_socialId64));

      uint256 cardId = storageContract.socialIdentityToCardId(_socialNetworkType8, _socialId64);

      address claimerAddress;
      (, , claimerAddress, ,) = storageContract.allCards(cardId);

      return claimerAddress;
    }

    function twitterIdOfClaimerAddress(address _claimerAddress) public view returns (uint64) {
      return socialIdentityOfClaimerAddress(TWITTER, _claimerAddress);
    }

    function socialIdentityOfClaimerAddress(uint256 _socialNetworkType, address _claimerAddress) public view returns (uint64) {
      uint256 cardId = storageContract.lookUpClaimerAddress(_socialNetworkType, _claimerAddress);

      uint64 socialId;
      (, socialId, , ,) = storageContract.allCards(cardId);
      return socialId;
    }

    function withdrawContractBalance(address _to) external requireBursar {
      if (_to == address(0)) {
          bursarAddress.transfer(this.balance);
      } else {
          _to.transfer(this.balance);
      }
    }
}