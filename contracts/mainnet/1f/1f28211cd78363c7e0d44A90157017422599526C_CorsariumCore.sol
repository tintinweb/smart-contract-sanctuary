pragma solidity ^0.4.13;

contract SplitPayment {
  using SafeMath for uint256;

  uint256 public totalShares = 0;
  uint256 public totalReleased = 0;

  mapping(address => uint256) public shares;
  mapping(address => uint256) public released;
  address[] public payees;

  /**
   * @dev Constructor
   */
  function SplitPayment(address[] _payees, uint256[] _shares) public payable {
    require(_payees.length == _shares.length);

    for (uint256 i = 0; i < _payees.length; i++) {
      addPayee(_payees[i], _shares[i]);
    }
  }

  /**
   * @dev payable fallback
   */
  function () public payable {}

  /**
   * @dev Claim your share of the balance.
   */
  function claim() public {
    address payee = msg.sender;

    require(shares[payee] > 0);

    uint256 totalReceived = this.balance.add(totalReleased);
    uint256 payment = totalReceived.mul(shares[payee]).div(totalShares).sub(released[payee]);

    require(payment != 0);
    require(this.balance >= payment);

    released[payee] = released[payee].add(payment);
    totalReleased = totalReleased.add(payment);

    payee.transfer(payment);
  }

  /**
   * @dev Add a new payee to the contract.
   * @param _payee The address of the payee to add.
   * @param _shares The number of shares owned by the payee.
   */
  function addPayee(address _payee, uint256 _shares) internal {
    require(_payee != address(0));
    require(_shares > 0);
    require(shares[_payee] == 0);

    payees.push(_payee);
    shares[_payee] = _shares;
    totalShares = totalShares.add(_shares);
  }
}

interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
	
    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your assets.
    /// @dev Throws unless `msg.sender` is the current NFT owner.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract CorsariumAccessControl is SplitPayment {
//contract CorsariumAccessControl {
   
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public megoAddress = 0x4ab6C984E72CbaB4162429721839d72B188010E3;
    address public publisherAddress = 0x00C0bCa70EAaADF21A158141EC7eA699a17D63ed;
    // cat, rene, pablo,  cristean, chulini, pablo, david, mego
    address[] public teamAddresses = [0x4978FaF663A3F1A6c74ACCCCBd63294Efec64624, 0x772009E69B051879E1a5255D9af00723df9A6E04, 0xA464b05832a72a1a47Ace2Be18635E3a4c9a240A, 0xd450fCBfbB75CDAeB65693849A6EFF0c2976026F, 0xd129BBF705dC91F50C5d9B44749507f458a733C8, 0xfDC2ad68fd1EF5341a442d0E2fC8b974E273AC16, 0x4ab6C984E72CbaB4162429721839d72B188010E3];
    // todo: add addresses of creators

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    modifier onlyTeam() {
        require(msg.sender == teamAddresses[0] || msg.sender == teamAddresses[1] || msg.sender == teamAddresses[2] || msg.sender == teamAddresses[3] || msg.sender == teamAddresses[4] || msg.sender == teamAddresses[5] || msg.sender == teamAddresses[6] || msg.sender == teamAddresses[7]);
        _; // do the rest
    }

    modifier onlyPublisher() {
        require(msg.sender == publisherAddress);
        _;
    }

    modifier onlyMEGO() {
        require(msg.sender == megoAddress);
        _;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    function CorsariumAccessControl() public {
        megoAddress = msg.sender;
    }

    /// @dev Called by any team member to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyTeam whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by MEGO, since
    ///  one reason we may pause the contract is when team accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyMEGO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

}

contract CardBase is CorsariumAccessControl, ERC721, ERC721Metadata {

    /*** EVENTS ***/

    /// @dev The Print event is fired whenever a new card comes into existence.
    event Print(address owner, uint256 cardId);
    
    uint256 lastPrintedCard = 0;
     
    mapping (uint256 => address) public tokenIdToOwner;  // 721 tokenIdToOwner
    mapping (address => uint256) public ownerTokenCount; // 721 ownerTokenCount
    mapping (uint256 => address) public tokenIdToApproved; // 721 tokenIdToApprovedAddress
    mapping (uint256 => uint256) public tokenToCardIndex; // 721 tokenIdToMetadata
    //mapping (uint256 => uint256) public tokenCountIndex;
    //mapping (address => uint256[]) internal ownerToTokensOwned;
    //mapping (uint256 => uint256) internal tokenIdToOwnerArrayIndex;

    /// @dev Assigns ownership of a specific card to an address.
    /*function _transfer(address _from, address _to, uint256 _tokenId) internal {
      
        ownershipTokenCount[_to]++;
        // transfer ownership
        cardIndexToOwner[_tokenId] = _to;
       
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
        
    }*/
    
    function _createCard(uint256 _prototypeId, address _owner) internal returns (uint) {

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        require(uint256(1000000) > lastPrintedCard);
        lastPrintedCard++;
        tokenToCardIndex[lastPrintedCard] = _prototypeId;
        _setTokenOwner(lastPrintedCard, _owner);
        //_addTokenToOwnersList(_owner, lastPrintedCard);
        Transfer(0, _owner, lastPrintedCard);
        //tokenCountIndex[_prototypeId]++;
        
        //_transfer(0, _owner, lastPrintedCard); //<-- asd
        

        return lastPrintedCard;
    }

    function _clearApprovalAndTransfer(address _from, address _to, uint _tokenId) internal {
        _clearTokenApproval(_tokenId);
        //_removeTokenFromOwnersList(_from, _tokenId);
        ownerTokenCount[_from]--;
        _setTokenOwner(_tokenId, _to);
        //_addTokenToOwnersList(_to, _tokenId);
    }

    function _ownerOf(uint _tokenId) internal view returns (address _owner) {
        return tokenIdToOwner[_tokenId];
    }

    function _approve(address _to, uint _tokenId) internal {
        tokenIdToApproved[_tokenId] = _to;
    }

    function _getApproved(uint _tokenId) internal view returns (address _approved) {
        return tokenIdToApproved[_tokenId];
    }

    function _clearTokenApproval(uint _tokenId) internal {
        tokenIdToApproved[_tokenId] = address(0);
    }

    function _setTokenOwner(uint _tokenId, address _owner) internal {
        tokenIdToOwner[_tokenId] = _owner;
        ownerTokenCount[_owner]++;
    }

}

contract CardOwnership is CardBase {
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return ownerTokenCount[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = tokenIdToOwner[_tokenId];
        require(_owner != address(0));
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
        require(_getApproved(_tokenId) == msg.sender);
        require(_ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        Approval(_from, 0, _tokenId);
        Transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 value = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);

            if (value != bytes4(keccak256("onERC721Received(address,uint256,bytes)"))) {
                revert();
            }
        }
    }
	
    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(_getApproved(_tokenId) == msg.sender);
        require(_ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        Approval(_from, 0, _tokenId);
        Transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 value = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, "");

            if (value != bytes4(keccak256("onERC721Received(address,uint256,bytes)"))) {
                revert();
            }
        }
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(_getApproved(_tokenId) == msg.sender);
        require(_ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        Approval(_from, 0, _tokenId);
        Transfer(_from, _to, _tokenId);
    }

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable {
        require(msg.sender == _ownerOf(_tokenId));
        require(msg.sender != _approved);
        
        if (_getApproved(_tokenId) != address(0) || _approved != address(0)) {
            _approve(_approved, _tokenId);
            Approval(msg.sender, _approved, _tokenId);
        }
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your assets.
    /// @dev Throws unless `msg.sender` is the current NFT owner.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        revert();
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address) {
        return _getApproved(_tokenId);
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _owner == _operator;
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name) {
        return "Dark Winds First Edition Cards";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol) {
        return "DW1ST";
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string _tokenURI) {
        _tokenURI = "https://corsarium.playdarkwinds.com/cards/00000.json"; //37 36 35 34 33
        bytes memory tokenUriBytes = bytes(_tokenURI);
        tokenUriBytes[33] = byte(48 + (tokenToCardIndex[_tokenId] / 10000) % 10);
        tokenUriBytes[34] = byte(48 + (tokenToCardIndex[_tokenId] / 1000) % 10);
        tokenUriBytes[35] = byte(48 + (tokenToCardIndex[_tokenId] / 100) % 10);
        tokenUriBytes[36] = byte(48 + (tokenToCardIndex[_tokenId] / 10) % 10);
        tokenUriBytes[37] = byte(48 + (tokenToCardIndex[_tokenId] / 1) % 10);
    }

    function totalSupply() public view returns (uint256 _total) {
        _total = lastPrintedCard;
    }

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { 
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

contract CorsariumCore is CardOwnership {

    uint256 nonce = 1;
    uint256 public cardCost = 1 finney;

    function CorsariumCore(address[] _payees, uint256[] _shares) SplitPayment(_payees, _shares) public {

    }

    // payable fallback
    function () public payable {}

    function changeCardCost(uint256 _newCost) onlyTeam public {
        cardCost = _newCost;
    }

    function getCard(uint _token_id) public view returns (uint256) {
        assert(_token_id <= lastPrintedCard);
        return tokenToCardIndex[_token_id];
    }

    function buyBoosterPack() public payable {
        uint amount = msg.value/cardCost;
        uint blockNumber = block.timestamp;
        for (uint i = 0; i < amount; i++) {
            _createCard(i%5 == 1 ? (uint256(keccak256(i+nonce+blockNumber)) % 50) : (uint256(keccak256(i+nonce+blockNumber)) % 50) + (nonce%50), msg.sender);
        }
        nonce += amount;

    }
    
    function cardsOfOwner(address _owner) external view returns (uint256[] ownerCards) {
        uint256 tokenCount = ownerTokenCount[_owner];

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            // We count on the fact that all cards have IDs starting at 1 and increasing
            // sequentially up to the totalCards count.
            uint256 cardId;

            for (cardId = 1; cardId <= lastPrintedCard; cardId++) {
                if (tokenIdToOwner[cardId] == _owner) {
                    result[resultIndex] = cardId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] ownerCards) {
        uint256 tokenCount = ownerTokenCount[_owner];

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            // We count on the fact that all cards have IDs starting at 1 and increasing
            // sequentially up to the totalCards count.
            uint256 cardId;

            for (cardId = 1; cardId <= lastPrintedCard; cardId++) {
                if (tokenIdToOwner[cardId] == _owner) {
                    result[resultIndex] = cardId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function cardSupply() external view returns (uint256[] printedCards) {

        if (totalSupply() == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](100);
            //uint256 totalCards = 1000000;
            //uint256 resultIndex = 0;

            // We count on the fact that all cards have IDs starting at 1 and increasing
            // sequentially up to 1000000
            uint256 cardId;

            for (cardId = 1; cardId < 1000000; cardId++) {
                result[tokenToCardIndex[cardId]]++;
                //resultIndex++;
            }

            return result;
        }
    }
    
}

interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address 
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}