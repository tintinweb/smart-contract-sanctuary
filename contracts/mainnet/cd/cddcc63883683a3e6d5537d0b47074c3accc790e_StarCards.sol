pragma solidity ^0.4.23;

/************************************************
 *
 * Star Cards - Verifiably unique celebrity collectibles
 * Authors: Dick Oranges & Eggy Bagelface
 *
 * MD5: 696fa8ba0f25d6d6f8391e37251736bc
 * SHA256: ba3178b5d13ec7b05cf3ebaae2be797cc0eb6756eac455426f2b1d70f17cefae
 *
 ************************************************/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param addr address to check
     * @return whether the target address is a contract
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
        return size > 0;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function owned(uint256 _tokenId) public view returns (bool _owned);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public;
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}


pragma solidity ^0.4.21;


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
    /**
     * @dev Magic value to be returned upon successful reception of an NFT
     *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
     *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
     */
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a `safetransfer`. This function MAY throw to revert and reject the
     *  transfer. This function MUST use 50,000 gas or less. Return of other
     *  than the magic value MUST result in the transaction being reverted.
     *  Note: the contract address is always the message sender.
     * @param _from The sending address
     * @param _tokenId The NFT identifier which is being transfered
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
     */
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}



/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    /**
     * @dev Guarantees msg.sender is owner of the given token
     * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
     * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
     * @param _tokenId uint256 ID of the token to validate
     */
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    /**
     * @dev Gets the balance of the specified address
     * @param _owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param _tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Returns whether the specified token is owned
     * @param _tokenId uint256 ID of the token to query the existance of
     * @return whether the token is owned
     */
    function owned(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * @dev The zero address indicates there is no approved address.
     * @dev There can only be one approved address per token at a given time.
     * @dev Can only be called by the token owner or an approved operator.
     * @param _to address to be approved for the given token ID
     * @param _tokenId uint256 ID of the token to be approved
     */
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * @param _tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for a the given token ID
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * @dev An operator is allowed to transfer all tokens of the sender on their behalf
     * @param _to operator address to set the approval
     * @param _approved representing the status of the approval to be set
     */
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param _owner owner address which you want to query the approval of
     * @param _operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * @dev If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
     *  the transfer is reverted.
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * @dev If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
     *  the transfer is reverted.
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public
        canTransfer(_tokenId)
    {
        transferFrom(_from, _to, _tokenId);
        // solium-disable-next-line arg-overflow
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *  is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

    /**
     * @dev Internal function to clear current approval of a given token ID
     * @dev Reverts if the given address is not indeed the owner of the token
     * @param _owner owner of the token
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * @dev The call is not executed if the target address is not a contract
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal
        returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}


/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {

    // Token name
    string internal name_;

    // Token symbol
    string internal symbol_;

    // Token supply
    uint256 internal totalSupply_;

    // Mapping from owner to list of owned token IDs
    mapping (address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;

    /**
     * @dev Constructor function
     */
    constructor(string _name, string _symbol, uint256 _totalSupply) public {
        name_ = _name;
        symbol_ = _symbol;
        totalSupply_ = _totalSupply;
    }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() public view returns (string) {
        return name_;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() public view returns (string) {
        return symbol_;
    }

    /**
     * @dev Returns an URI for a given token ID
     * @dev Throws if the token is not owned. May return an empty string.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(owned(_tokenId));
        return tokenURIs[_tokenId];
    }

    /**
     * @dev Gets the total token supply
     * @return uint256 representing the total token supply
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Internal function to set the token URI for a given token
     * @dev Reverts if the token ID is not owned
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(owned(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param _owner address owning the tokens list to be accessed
     * @param _index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * @dev Reverts if the index is greater or equal to the total number of tokens
     * @param _index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return _index;
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }
}

contract ERC165 {

    bytes4 constant ERC165InterfaceId = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant ERC721InterfaceId = 0x80ac58cd;
    bytes4 constant ERC721EnumerableInterfaceId = 0x780e9d63;
    bytes4 constant ERC721MetadataInterfaceId = 0x5b5e139f;
    bytes4 constant ERC721TokenReceiverInterfaceId = 0xf0b9e5ba;

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
            ((interfaceID == ERC165InterfaceId) ||
            (interfaceID == ERC721InterfaceId) ||
            (interfaceID == ERC721EnumerableInterfaceId) ||
            (interfaceID == ERC721MetadataInterfaceId) ||
            (interfaceID == ERC721TokenReceiverInterfaceId));
    }
}

contract StarCards is Ownable, ERC721Token, ERC165 {

    // The card database can be verified using these checksums.
    string constant public dataset_md5checksum = "696fa8ba0f25d6d6f8391e37251736bc";
    string constant public dataset_sha256checksum = "ba3178b5d13ec7b05cf3ebaae2be797cc0eb6756eac455426f2b1d70f17cefae";

    // The card database can be downloaded at this URL.
    string public databaseDownloadUrl = "ftp://starcards.my/starCardsDataset.json";
    
    uint256 constant public editionSize = 345;
    uint256 constant public minimumBid = 0.001 ether;
    uint256 constant public timeBetweenEditions = 1 days;
    uint256 constant public initializationDelay = 3 days;

    struct ReleaseAuction {
        Bid highestBid;
        uint additionalTime;
        bool completed;
    }

    struct Bid {
        uint value;
        uint timePlaced;
        address bidder;
    }

    event NewBid(uint id, uint value, uint timePlaced, address bidder);

    mapping(address => uint) public pendingWithdrawals;
    mapping(uint => ReleaseAuction) releaseAuctions;

    uint256 public contractInitializationTime;

    constructor() ERC721Token("Star Cards", "STAR", 586155) public payable {
        owner = msg.sender;
        contractInitializationTime = now + initializationDelay;
    }

    function setDatabaseDownloadUrl(string url) public onlyOwner {
        databaseDownloadUrl = url;
    }

    function getCurrentEdition() public view returns (uint256) {
        uint256 secondsSinceContractInitialization = SafeMath.sub(now, contractInitializationTime);
        return SafeMath.div(secondsSinceContractInitialization, timeBetweenEditions);
    }

    function getEditionReleaseTime(uint edition) public view returns (uint256) {
        return SafeMath.add(contractInitializationTime, (SafeMath.mul(edition, timeBetweenEditions)));
    }

    function getEdition(uint id) public view onlyValidTokenIds(id) returns (uint256) {
        return SafeMath.div(id, editionSize);
    }

    function isReleased(uint id) public view onlyValidTokenIds(id) returns (bool) {
        return getEdition(id) <= getCurrentEdition();
    }

    function getReleaseAuctionEndTime(uint id) public view onlyValidTokenIds(id) returns (uint) {
        uint256 timeFromRelease = SafeMath.add(timeBetweenEditions, releaseAuctions[id].additionalTime);
        return SafeMath.add(getEditionReleaseTime(getEdition(id)), timeFromRelease);
    }

    function releaseAuctionEnded(uint id) public view onlyValidTokenIds(id) returns (bool) {
        return (isReleased(id) && (getReleaseAuctionEndTime(id) < now));
    }

    function getHighestBidder(uint id) public view onlyValidTokenIds(id) returns (address) {
        return releaseAuctions[id].highestBid.bidder;
    }

    function getHighestBid(uint id) public view onlyValidTokenIds(id) returns (uint) {
        return releaseAuctions[id].highestBid.value;
    }

    function getAdditionalTime(uint id) public view onlyValidTokenIds(id) returns (uint) {
        return releaseAuctions[id].additionalTime;
    }

    function getRemainingTime(uint id) public view onlyValidTokenIds(id) returns (uint) {
        uint endTime = getReleaseAuctionEndTime(id);
        if (endTime > now) {
            return SafeMath.sub(endTime, now);
        } else {
            return 0;
        }
    }

    function getAllTokens(address owner) public view returns (uint[]) {
        uint size = ownedTokens[owner].length;
        uint[] memory result = new uint[](size);
        for (uint i = 0; i < size; i++) {
            result[i] = ownedTokens[owner][i];
        }
        return result;
    }

    // Complete the release auction.
    function completeReleaseAuction(uint id) payable external onlyReleasedTokens(id) {

        require(releaseAuctionEnded(id));

        ReleaseAuction storage auction = releaseAuctions[id];

        require(!auction.completed);

        address newOwner;
        uint payout;

        if (auction.highestBid.bidder == address(0)) {
            require(msg.value >= minimumBid);
            newOwner = msg.sender;
            payout = msg.value;
        } else {
            newOwner = auction.highestBid.bidder;
            payout = auction.highestBid.value;
        }

        addTokenTo(newOwner, id);

        pendingWithdrawals[owner] = SafeMath.add(pendingWithdrawals[owner], payout);

        auction.completed = true;
    }

    // Place a bid on an active auction.
    function placeBid(uint id) payable external onlyReleasedTokens(id) {

        require(!releaseAuctionEnded(id)); // Ensure release auction has not expired.

        ReleaseAuction storage auction = releaseAuctions[id];

        // Ensure new bid is greater than or equal to current bid plus minimum bid increase.
        require(msg.value >= auction.highestBid.value + minimumBid);

        // Reset auction timeout.
        auction.additionalTime = SafeMath.add(auction.additionalTime, timeBetweenEditions - getRemainingTime(id));

        // Refund previous bidder if there is one.
        if (auction.highestBid.bidder != address(0)) {
            pendingWithdrawals[auction.highestBid.bidder] = SafeMath.add(pendingWithdrawals[auction.highestBid.bidder], auction.highestBid.value);
        }

        // Update highest bid.
        auction.highestBid = Bid(msg.value, now, msg.sender);

        emit NewBid(id, msg.value, now, msg.sender);
    }

    // Withdraw a bid that was overbid.
    function withdraw() external returns (bool) {
        uint amount = pendingWithdrawals[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingWithdrawals[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingWithdrawals[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // Token must be released to execute
    modifier onlyReleasedTokens(uint id) {
        require(isReleased(id));
        _;
    }

    // Token id must be in range
    modifier onlyValidTokenIds(uint id) {
        require(id < totalSupply());
        _;
    }
  
    function() external payable {
        revert();
    }
}