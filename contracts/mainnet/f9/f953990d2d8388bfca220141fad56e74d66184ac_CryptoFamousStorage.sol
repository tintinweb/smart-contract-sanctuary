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