pragma solidity ^0.4.24;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

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
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`&#39;s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
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

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface ERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}


/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface {
    /**
     * @dev Mapping of supported intefraces.
     * @notice You must not set element 0xffffffff to true.
     */
    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev Contract constructor.
     */
    constructor()
    public
    {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
    }

    /**
     * @dev Function to check which interfaces are suported by this contract.
     * @param _interfaceID Id of the interface.
     */
    function supportsInterface(
        bytes4 _interfaceID
    )
    external
    view
    returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

}

/**
 * @dev Utility library of inline functions on addresses.
 */
library AddressUtils {

    /**
     * @dev Returns whether the target address is a contract.
     * @param _addr Address to check.
     */
    function isContract(
        address _addr
    )
    internal
    view
    returns (bool)
    {
        uint256 size;

        /**
         * XXX Currently there is no better way to check if there is a contract in an address than to
         * check the size of the code at that address.
         * See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
         * TODO: Check this again before the Serenity release, because all addresses will be
         * contracts then.
         */
        assembly { size := extcodesize(_addr) } // solium-disable-line security/no-inline-assembly
        return size > 0;
    }

}

/**
 * @dev Implementation of ERC-721 non-fungible token standard specifically for WeTrust Spring.
 */
contract NFToken is ERC721, SupportsInterface, ERC721Metadata, ERC721Enumerable {
    using AddressUtils for address;

    ///////////////////////////
    // Constants
    //////////////////////////

    /**
     * @dev Magic value of a smart contract that can recieve NFT.
     * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
     */
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    //////////////////////////
    // Events
    //////////////////////////

    /**
     * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
     * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
     * number of NFTs may be created and assigned without emitting Transfer. At the time of any
     * transfer, the approved address for that NFT (if any) is reset to none.
     * @param _from Sender of NFT (if address is zero address it indicates token creation).
     * @param _to Receiver of NFT (if address is zero address it indicates token destruction).
     * @param _tokenId The NFT that got transfered.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
     * address indicates there is no approved address. When a Transfer event emits, this also
     * indicates that the approved address for that NFT (if any) is reset to none.
     * @param _owner Owner of NFT.
     * @param _approved Address that we are approving.
     * @param _tokenId NFT which we are approving.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
     * all NFTs of the owner.
     * @param _owner Owner of NFT.
     * @param _operator Address to which we are setting operator rights.
     * @param _approved Status of operator rights(true if operator rights are given and false if
     * revoked).
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    ////////////////////////////////
    // Modifiers
    ///////////////////////////////

    /**
     * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = nft[_tokenId].owner;
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "Sender is not an authorized operator of this token");
        _;
    }

    /**
     * @dev Guarantees that the msg.sender is allowed to transfer NFT.
     * @param _tokenId ID of the NFT to transfer.
     */
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = nft[_tokenId].owner;
        require(
            tokenOwner == msg.sender ||
            getApproved(_tokenId) == msg.sender || ownerToOperators[tokenOwner][msg.sender],
            "Sender does not have permission to transfer this Token");

        _;
    }

    /**
     * @dev Check to make sure the address is not zero address
     * @param toTest The Address to make sure it&#39;s not zero address
     */
    modifier onlyNonZeroAddress(address toTest) {
        require(toTest != address(0), "Address must be non zero address");
        _;
    }

    /**
     * @dev Guarantees that no owner exists for the nft
     * @param nftId NFT to test
     */
    modifier noOwnerExists(uint256 nftId) {
        require(nft[nftId].owner == address(0), "Owner must not exist for this token");
        _;
    }

    /**
     * @dev Guarantees that an owner exists for the nft
     * @param nftId NFT to test
     */
    modifier ownerExists(uint256 nftId) {
        require(nft[nftId].owner != address(0), "Owner must exist for this token");
        _;
    }

    ///////////////////////////
    // Storage Variable
    //////////////////////////

    /**
     * @dev name of the NFT
     */
    string nftName = "WeTrust Nifty";

    /**
     * @dev NFT symbol
     */
    string nftSymbol = "SPRN";

    /**
     * @dev hostname to be used as base for tokenURI
     */
    string public hostname = "https://spring.wetrust.io/shiba/";

    /**
     * @dev A mapping from NFT ID to the address that owns it.
     */
    mapping (uint256 => NFT) public nft;

    /**
     * @dev List of NFTs
     */
    uint256[] nftList;

    /**
    * @dev Mapping from owner address to count of his tokens.
    */
    mapping (address => uint256[]) internal ownerToTokenList;

    /**
     * @dev Mapping from owner address to mapping of operator addresses.
     */
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    struct NFT {
        address owner;
        address approval;
        bytes32 traits;
        uint16 edition;
        bytes4 nftType;
        bytes32 recipientId;
        uint256 createdAt;
    }

    ////////////////////////////////
    // Public Functions
    ///////////////////////////////

    /**
     * @dev Contract constructor.
     */
    constructor() public {
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721MetaData
        supportedInterfaces[0x80ac58cd] = true; // ERC721
    }

    /**
     * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
     * considered invalid, and this function throws for queries about the zero address.
     * @param _owner Address for whom to query the balance.
     */
    function balanceOf(address _owner) onlyNonZeroAddress(_owner) public view returns (uint256) {
        return ownerToTokenList[_owner].length;
    }

    /**
     * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
     * invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT.
     */
    function ownerOf(uint256 _tokenId) ownerExists(_tokenId) external view returns (address _owner) {
        return nft[_tokenId].owner;
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address.
     * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
     * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
     * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
     * function checks if `_to` is a smart contract (code size > 0). If so, it calls `onERC721Received`
     * on `_to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address.
     * @notice This works identically to the other function with an extra data parameter, except this
     * function just sets data to ""
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
     * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
     * address. Throws if `_tokenId` is not a valid NFT.
     * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
     * they maybe be permanently lost.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId)
        onlyNonZeroAddress(_to)
        canTransfer(_tokenId)
        ownerExists(_tokenId)
        external
    {

        address tokenOwner = nft[_tokenId].owner;
        require(tokenOwner == _from, "from address must be owner of tokenId");

        _transfer(_to, _tokenId);
    }

    /**
     * @dev Set or reaffirm the approved address for an NFT.
     * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
     * the current NFT owner, or an authorized operator of the current owner.
     * @param _approved Address to be approved for the given NFT ID.
     * @param _tokenId ID of the token to be approved.
     */
    function approve(address _approved, uint256 _tokenId)
        canOperate(_tokenId)
        ownerExists(_tokenId)
        external
    {

        address tokenOwner = nft[_tokenId].owner;
        require(_approved != tokenOwner, "approved address cannot be owner of the token");

        nft[_tokenId].approval = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    /**
     * @dev Enables or disables approval for a third party ("operator") to manage all of
     * `msg.sender`&#39;s assets. It also emits the ApprovalForAll event.
     * @notice This works even if sender doesn&#39;t own any tokens at the time.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operators is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved)
        onlyNonZeroAddress(_operator)
        external
    {

        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Get the approved address for a single NFT.
     * @notice Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId ID of the NFT to query the approval of.
     */
    function getApproved(uint256 _tokenId)
        ownerExists(_tokenId)
        public view returns (address)
    {

        return nft[_tokenId].approval;
    }

    /**
     * @dev Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the NFTs.
     * @param _operator The address that acts on behalf of the owner.
     */
    function isApprovedForAll(address _owner, address _operator)
        onlyNonZeroAddress(_owner)
        onlyNonZeroAddress(_operator)
        external view returns (bool)
    {

        return ownerToOperators[_owner][_operator];
    }

    /**
     * @dev return token list of owned by the owner
     * @param owner The address that owns the NFTs.
     */
    function getOwnedTokenList(address owner) view public returns(uint256[] tokenList) {
        return ownerToTokenList[owner];
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string _name) {
        return nftName;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string _symbol) {
        return nftSymbol;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string) {
        return appendUintToString(hostname, _tokenId);
    }

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return nftList.length;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < nftList.length, "index out of range");
        return nftList[_index];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < balanceOf(_owner), "index out of range");
        return ownerToTokenList[_owner][_index];
    }

    /////////////////////////////
    // Private Functions
    ////////////////////////////

    /**
     * @dev append uint to the end of string
     * @param inStr input string
     * @param v uint value v
     * credit goes to : https://ethereum.stackexchange.com/questions/10811/solidity-concatenate-uint-into-a-string
     */

    function appendUintToString(string inStr, uint v) pure internal returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    /**
     * @dev Actually preforms the transfer.
     * @notice Does NO checks.
     * @param _to Address of a new owner.
     * @param _tokenId The NFT that is being transferred.
     */
    function _transfer(address _to, uint256 _tokenId) private {
        address from = nft[_tokenId].owner;
        clearApproval(_tokenId);

        removeNFToken(from, _tokenId);
        addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
        onlyNonZeroAddress(_to)
        canTransfer(_tokenId)
        ownerExists(_tokenId)
        internal
    {
        address tokenOwner = nft[_tokenId].owner;
        require(tokenOwner == _from, "from address must be owner of tokenId");

        _transfer(_to, _tokenId);

        if (_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, "reciever contract did not return the correct return value");
        }
    }

    /**
     * @dev Clears the current approval of a given NFT ID.
     * @param _tokenId ID of the NFT to be transferred.
     */
    function clearApproval(uint256 _tokenId) private {
        if(nft[_tokenId].approval != address(0))
        {
            delete nft[_tokenId].approval;
        }
    }

    /**
     * @dev Removes a NFT from owner.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _from Address from wich we want to remove the NFT.
     * @param _tokenId Which NFT we want to remove.
     */
    function removeNFToken(address _from, uint256 _tokenId) internal {
        require(nft[_tokenId].owner == _from, "from address must be owner of tokenId");
        uint256[] storage tokenList = ownerToTokenList[_from];
        assert(tokenList.length > 0);

        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == _tokenId) {
                tokenList[i] = tokenList[tokenList.length - 1];
                delete tokenList[tokenList.length - 1];
                tokenList.length--;
                break;
            }
        }
        delete nft[_tokenId].owner;
    }

    /**
     * @dev Assignes a new NFT to owner.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _to Address to wich we want to add the NFT.
     * @param _tokenId Which NFT we want to add.
     */
    function addNFToken(address _to, uint256 _tokenId)
        noOwnerExists(_tokenId)
        internal
    {
        nft[_tokenId].owner = _to;
        ownerToTokenList[_to].push(_tokenId);
    }

}


//@dev Implemention of NFT for WeTrust Spring
contract SpringNFT is NFToken{


    //////////////////////////////
    // Events
    /////////////////////////////
    event RecipientUpdate(bytes32 indexed recipientId, bytes32 updateId);

    //////////////////////////////
    // Modifiers
    /////////////////////////////

    /**
     * @dev Guarrentees that recipient Exists
     * @param id receipientId to check
     */
    modifier recipientExists(bytes32 id) {
        require(recipients[id].exists, "Recipient Must exist");
        _;
    }

    /**
     * @dev Guarrentees that recipient does not Exists
     * @param id receipientId to check
     */
    modifier recipientDoesNotExists(bytes32 id) {
        require(!recipients[id].exists, "Recipient Must not exists");
        _;
    }

    /**
     * @dev Guarrentees that msg.sender is wetrust owned signer address
     */
    modifier onlyByWeTrustSigner() {
        require(msg.sender == wetrustSigner, "sender must be from WeTrust Signer Address");
        _;
    }

    /**
     * @dev Guarrentees that msg.sender is wetrust owned manager address
     */
    modifier onlyByWeTrustManager() {
        require(msg.sender == wetrustManager, "sender must be from WeTrust Manager Address");
        _;
    }

    /**
     * @dev Guarrentees that msg.sender is either wetrust recipient
     * @param id receipientId to check
     */
    modifier onlyByWeTrustOrRecipient(bytes32 id) {
        require(msg.sender == wetrustSigner || msg.sender == recipients[id].owner, "sender must be from WeTrust or Recipient&#39;s owner address");
        _;
    }

    /**
     * @dev Guarrentees that contract is not in paused state
     */
    modifier onlyWhenNotPaused() {
        require(!paused, "contract is currently in paused state");
        _;
    }

    //////////////////////////////
    // Storage Variables
    /////////////////////////////

    /**
     * @dev wetrust controlled address that is used to create new NFTs
     */
    address public wetrustSigner;

    /**
     *@dev wetrust controlled address that is used to switch the signer address
     */
    address public wetrustManager;

    /**
     * @dev if paused is true, suspend most of contract&#39;s functionality
     */
    bool public paused;

    /**
     * @dev mapping of recipients from WeTrust Spring platform
     */
    mapping(bytes32 => Recipient) public recipients;
    /**
     * @dev mapping to a list of updates made by recipients
     */
    mapping(bytes32 => Update[]) public recipientUpdates;

    /**
     * @dev Stores the Artist signed Message who created the NFT
     */
    mapping (uint256 => bytes) public nftArtistSignature;

    struct Update {
        bytes32 id;
        uint256 createdAt;
    }

    struct Recipient {
        string name;
        string url;
        address owner;
        uint256 nftCount;
        bool exists;
    }

    //////////////////////////////
    // Public functions
    /////////////////////////////

    /**
     * @dev contract constructor
     */
    constructor (address signer, address manager) NFToken() public {
        wetrustSigner = signer;
        wetrustManager = manager;
    }

    /**
     * @dev Create a new NFT
     * @param tokenId create new NFT with this tokenId
     * @param receiver the owner of the new NFT
     * @param recipientId The issuer of the NFT
     * @param traits NFT Traits
     * @param nftType Type of the NFT
     */

    function createNFT(
        uint256 tokenId,
        address receiver,
        bytes32 recipientId,
        bytes32 traits,
        bytes4 nftType)
        noOwnerExists(tokenId)
        onlyByWeTrustSigner
        onlyWhenNotPaused public
    {
        mint(tokenId, receiver, recipientId, traits, nftType);
    }

    /**
     * @dev Allows anyone to redeem a token by providing a signed Message from Spring platform
     * @param signedMessage A signed Message containing the NFT parameter from Spring platform
     * The Signed Message must be concatenated in the following format
     * - address to (the smart contract address)
     * - uint256 tokenId
     * - bytes4 nftType
     * - bytes32 traits
     * - bytes32 recipientId
     * - bytes32 r of Signature
     * - bytes32 s of Signature
     * - uint8 v of Signature
     */
    function redeemToken(bytes signedMessage) onlyWhenNotPaused public {
        address to;
        uint256 tokenId;
        bytes4 nftType;
        bytes32 traits;
        bytes32 recipientId;
        bytes32 r;
        bytes32 s;
        byte vInByte;
        uint8 v;
        string memory prefix = "\x19Ethereum Signed Message:\n32";

        assembly {
            to := mload(add(signedMessage, 32))
            tokenId := mload(add(signedMessage, 64))
            nftType := mload(add(signedMessage, 96)) // first 32 bytes are data padding
            traits := mload(add(signedMessage, 100))
            recipientId := mload(add(signedMessage, 132))
            r := mload(add(signedMessage, 164))
            s := mload(add(signedMessage, 196))
            vInByte := mload(add(signedMessage, 228))
        }
        require(to == address(this), "This signed Message is not meant for this smart contract");
        v = uint8(vInByte);
        if (v < 27) {
            v += 27;
        }

        require(nft[tokenId].owner == address(0), "This token has been redeemed already");
        bytes32 msgHash = createRedeemMessageHash(tokenId, nftType, traits, recipientId);
        bytes32 preFixedMsgHash = keccak256(
            abi.encodePacked(
                prefix,
                msgHash
            ));

        address signer = ecrecover(preFixedMsgHash, v, r, s);

        require(signer == wetrustSigner, "WeTrust did not authorized this redeem script");
        return mint(tokenId, msg.sender, recipientId, traits, nftType);
    }

    /**
     * @dev Add a new reciepient of WeTrust Spring
     * @param recipientId Unique identifier of receipient
     * @param name of the Recipient
     * @param url link to the recipient&#39;s website
     * @param owner Address owned by the recipient
     */
    function addRecipient(bytes32 recipientId, string name, string url, address owner)
        onlyByWeTrustSigner
        onlyWhenNotPaused
        recipientDoesNotExists(recipientId)
        public
    {
        require(bytes(name).length > 0, "name must not be empty string"); // no empty string

        recipients[recipientId].name = name;
        recipients[recipientId].url = url;
        recipients[recipientId].owner = owner;
        recipients[recipientId].exists = true;
    }

    /**
     * @dev Add an link to the update the recipient had made
     * @param recipientId The issuer of the update
     * @param updateId unique id of the update
     */
    function addRecipientUpdate(bytes32 recipientId, bytes32 updateId)
        onlyWhenNotPaused
        recipientExists(recipientId)
        onlyByWeTrustOrRecipient(recipientId)
        public
    {
        recipientUpdates[recipientId].push(Update(updateId, now));
        emit RecipientUpdate(recipientId, updateId);
    }

    /**
     * @dev Change recipient information
     * @param recipientId to change
     * @param name new name of the recipient
     * @param url new link of the recipient
     * @param owner new address owned by the recipient
     */
    function updateRecipientInfo(bytes32 recipientId, string name, string url, address owner)
        onlyByWeTrustSigner
        onlyWhenNotPaused
        recipientExists(recipientId)
        public
    {
        require(bytes(name).length > 0, "name must not be empty string"); // no empty string

        recipients[recipientId].name = name;
        recipients[recipientId].url = url;
        recipients[recipientId].owner = owner;
    }

    /**
     * @dev add a artist signed message for a particular NFT
     * @param nftId NFT to add the signature to
     * @param artistSignature Artist Signed Message
     */
    function addArtistSignature(uint256 nftId, bytes artistSignature) onlyByWeTrustSigner onlyWhenNotPaused public {
        require(nftArtistSignature[nftId].length == 0, "Artist Signature already exist for this token"); // make sure no prior signature exists

        nftArtistSignature[nftId] = artistSignature;
    }

    /**
     * @dev Set whether or not the contract is paused
     * @param _paused status to put the contract in
     */
    function setPaused(bool _paused) onlyByWeTrustManager public {
        paused = _paused;
    }

    /**
     * @dev Transfer the WeTrust signer of NFT contract to a new address
     * @param newAddress new WeTrust owned address
     */
    function changeWeTrustSigner(address newAddress) onlyWhenNotPaused onlyByWeTrustManager public {
        wetrustSigner = newAddress;
    }

    /**
     * @dev Returns the number of updates recipients had made
     * @param recipientId receipientId to check
     */
    function getUpdateCount(bytes32 recipientId) view public returns(uint256 count) {
        return recipientUpdates[recipientId].length;
    }

    /**
     * @dev returns the message hash to be signed for redeem token
     * @param tokenId id of the token to be created
     * @param nftType Type of NFT to be created
     * @param traits Traits of NFT to be created
     * @param recipientId Issuer of the NFT
     */
    function createRedeemMessageHash(
        uint256 tokenId,
        bytes4 nftType,
        bytes32 traits,
        bytes32 recipientId)
        view public returns(bytes32 msgHash)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                tokenId,
                nftType,
                traits,
                recipientId
            ));
    }

    /**
     * @dev Determines the edition of the NFT
     *      formula used to determine edition Size given the edition Number:
     *      f(x) = min(300x + 100, 5000)
     * using equation: g(x) = 150x^2 - 50x + 1 if x <= 16
     * else g(x) = 5000(x-16) - g(16)
     * maxEdition = 5000
     * @param nextNFTcount to determine edition for
     */
    function determineEdition(uint256 nextNFTcount) pure public returns (uint16 edition) {
        uint256 output;
        uint256 valueWhenXisSixteen = 37601; // g(16)
        if (nextNFTcount < valueWhenXisSixteen) {
            output = (sqrt(2500 + (600 * (nextNFTcount - 1))) + 50) / 300;
        } else {
            output = ((nextNFTcount - valueWhenXisSixteen) / 5000) + 16;
        }

        if (output > 5000) {
            output = 5000;
        }

        edition = uint16(output); // we don&#39;t have to worry about casting because output will always be less than or equal to 5000
    }

    /**
     * @dev set new host name for this nft contract
     * @param newHostName new host name to use
     */
    function setNFTContractInfo(string newHostName, string newName, string newSymbol) onlyByWeTrustManager external {
        hostname = newHostName;
        nftName = newName;
        nftSymbol = newSymbol;
    }
    //////////////////////////
    // Private Functions
    /////////////////////////

    /**
     * @dev Find the Square root of a number
     * @param x input
     * Credit goes to: https://ethereum.stackexchange.com/questions/2910/can-i-square-root-in-solidity
     */

    function sqrt(uint x) pure internal returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev Add the new NFT to the storage
     * @param receiver the owner of the new NFT
     * @param recipientId The issuer of the NFT
     * @param traits NFT Traits
     * @param nftType Type of the NFT
     */
    function mint(uint256 tokenId, address receiver, bytes32 recipientId, bytes32 traits, bytes4 nftType)
        recipientExists(recipientId)
        internal
    {
        nft[tokenId].owner = receiver;
        nft[tokenId].traits = traits;
        nft[tokenId].recipientId = recipientId;
        nft[tokenId].nftType = nftType;
        nft[tokenId].createdAt = now;
        nft[tokenId].edition = determineEdition(recipients[recipientId].nftCount + 1);

        recipients[recipientId].nftCount++;
        ownerToTokenList[receiver].push(tokenId);

        nftList.push(tokenId);

        emit Transfer(address(0), receiver, tokenId);
    }
}