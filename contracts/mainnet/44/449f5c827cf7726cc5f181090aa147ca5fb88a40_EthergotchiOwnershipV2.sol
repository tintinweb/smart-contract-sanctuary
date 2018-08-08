pragma solidity ^0.4.19;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
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

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

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

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x780e9d63
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
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f
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

/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address 
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

contract Ownable {
    address private owner;

    event LogOwnerChange(address _owner);

    // Modify method to only allow calls from the owner of the contract.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * Replace the contract owner with a new owner.
     *
     * Parameters
     * ----------
     * _owner : address
     *     The address to replace the current owner with.
     */
    function replaceOwner(address _owner) external onlyOwner {
        owner = _owner;

        LogOwnerChange(_owner);
    }
}

contract Controllable is Ownable {
    // Mapping of a contract address to its position in the list of active
    // contracts. This allows an O(1) look-up of the contract address compared
    // to a linear search within an array.
    mapping(address => uint256) private contractIndices;

    // The list of contracts that are allowed to call the contract-restricted
    // methods of contracts that extend this `Controllable` contract.
    address[] private contracts;

    /**
     * Modify method to only allow calls from active contract addresses.
     *
     * Notes
     * -----
     * The zero address is considered an inactive address, as it is impossible
     * for users to send a call from that address.
     */
    modifier onlyActiveContracts() {
        require(contractIndices[msg.sender] != 0);
        _;
    }

    function Controllable() public Ownable() {
        // The zeroth index of the list of active contracts is occupied by the
        // zero address to ensure that an index of zero can be used to indicate
        // that the contract address is inactive.
        contracts.push(address(0));
    }

    /**
     * Add a contract address to the list of active contracts.
     *
     * Parameters
     * ----------
     * _address : address
     *     The contract address to add to the list of active contracts.
     */
    function activateContract(address _address) external onlyOwner {
        require(contractIndices[_address] == 0);

        contracts.push(_address);

        // The index of the newly added contract is equal to the length of the
        // array of active contracts minus one, as Solidity is a zero-based
        // language.
        contractIndices[_address] = contracts.length - 1;
    }

    /**
     * Remove a contract address from the list of active contracts.
     *
     * Parameters
     * ----------
     * _address : address
     *     The contract address to remove from the list of active contracts.
     */
    function deactivateContract(address _address) external onlyOwner {
        require(contractIndices[_address] != 0);

        // Get the last contract in the array of active contracts. This address
        // will be used to overwrite the address that will be removed.
        address lastActiveContract = contracts[contracts.length - 1];

        // Overwrite the address that is to be removed with the value of the
        // last contract in the list. There is a possibility that these are the
        // same values, in which case nothing happens.
        contracts[contractIndices[_address]] = lastActiveContract;

        // Reduce the contracts array size by one, as the last contract address
        // will have been successfully moved.
        contracts.length--;

        // Set the address mapping to zero, effectively rendering the contract
        // banned from calling this contract.
        contractIndices[_address] = 0;
    }

    /**
     * Get the list of active contracts for this contract.
     *
     * Returns
     * -------
     * address[]
     *     The list of contract addresses that are allowed to call the
     *     contract-restricted methods of this contract.
     */
    function getActiveContracts() external view returns (address[]) {
        return contracts;
    }
}

library Tools {
    /**
     * Concatenate two strings.
     *
     * Parameters
     * ----------
     * stringLeft : string
     *     A string to concatenate with another string. This is the left part.
     * stringRight : string
     *     A string to concatenate with another string. This is the right part.
     *
     * Returns
     * -------
     * string
     *     The resulting string from concatenating the two given strings.
     */
    function concatenate(
        string stringLeft,
        string stringRight
    )
        internal
        pure
        returns (string)
    {
        // Get byte representations of both strings to allow for one-by-one
        // character iteration.
        bytes memory stringLeftBytes = bytes(stringLeft);
        bytes memory stringRightBytes = bytes(stringRight);

        // Initialize new string holder with the appropriate number of bytes to
        // hold the concatenated string.
        string memory resultString = new string(
            stringLeftBytes.length + stringRightBytes.length
        );

        // Get a bytes representation of the result string to allow for direct
        // modification.
        bytes memory resultBytes = bytes(resultString);

        // Initialize a number to hold the current index of the result string
        // to assign a character to.
        uint k = 0;

        // First loop over the left string, and afterwards over the right
        // string to assign each character to its proper location in the new
        // string.
        for (uint i = 0; i < stringLeftBytes.length; i++) {
            resultBytes[k++] = stringLeftBytes[i];
        }

        for (i = 0; i < stringRightBytes.length; i++) {
            resultBytes[k++] = stringRightBytes[i];
        }

        return string(resultBytes);
    }

    /**
     * Convert 256-bit unsigned integer into a 32 bytes structure.
     *
     * Parameters
     * ----------
     * value : uint256
     *     The unsigned integer to convert to bytes32.
     *
     * Returns
     * -------
     * bytes32
     *     The bytes32 representation of the given unsigned integer.
     */
    function uint256ToBytes32(uint256 value) internal pure returns (bytes32) {
        if (value == 0) {
            return &#39;0&#39;;
        }

        bytes32 resultBytes;

        while (value > 0) {
            resultBytes = bytes32(uint(resultBytes) / (2 ** 8));
            resultBytes |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
            value /= 10;
        }

        return resultBytes;
    }

    /**
     * Convert bytes32 data structure into a string.
     *
     * Parameters
     * ----------
     * data : bytes32
     *     The bytes to convert to a string.
     *
     * Returns
     * -------
     * string
     *     The string representation of given bytes.
     *
     * Notes
     * -----
     * This method is right-padded with zero bytes.
     */
    function bytes32ToString(bytes32 data) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);

        for (uint i = 0; i < 32; i++) {
            bytes1 char = bytes1(bytes32(uint256(data) * 2 ** (8 * i)));

            if (char != 0) {
                bytesString[i] = char;
            }
        }

        return string(bytesString);
    }
}

/**
 * Partial interface of former ownership contract.
 *
 * This interface is used to perform the migration of tokens, from the former
 * ownership contract to the current version. The inclusion of the entire
 * contract is too bulky, hence the partial interface.
 */
interface PartialOwnership {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}

/**
 * Ethergotchi Ownership Contract
 *
 * This contract governs the "non-fungible tokens" (NFTs) that represent the
 * various Ethergotchi owned by players within Aethia.
 *
 * The NFTs are implemented according to the standard described in EIP-721 as
 * it was on March 19th, 2018.
 *
 * In addition to the mentioned specification, a method was added to create new
 * tokens: `add(uint256 _tokenId, address _owner)`. This method can *only* be
 * called by activated Aethia game contracts.
 *
 * For more information on Aethia and/or Ethergotchi, visit the following
 * website: https://aethia.co
 */
contract EthergotchiOwnershipV2 is
    Controllable,
    ERC721,
    ERC721Enumerable,
    ERC721Metadata
{
    // Direct mapping to keep track of token owners.
    mapping(uint256 => address) private ownerByTokenId;

    // Mapping that keeps track of all tokens owned by a specific address. This
    // allows for iteration by owner, and is implemented to be able to comply
    // with the enumeration methods described in the ERC721Enumerable interface.
    mapping(address => uint256[]) private tokenIdsByOwner;

    // Mapping that keeps track of a token"s position in an owner"s list of
    // tokens. This allows for constant time look-ups within the list, instead
    // of needing to iterate the list of tokens.
    mapping(uint256 => uint256) private ownerTokenIndexByTokenId;

    // Mapping that keeps track of addresses that are approved to make a
    // transfer of a token. Approval can only be given to a single address, but
    // can be overridden for modification or retraction purposes.
    mapping(uint256 => address) private approvedTransfers;

    // Mapping that keeps track of operators that are allowed to perform
    // actions on behalf of another address. An address is allowed to set more
    // than one operator. Operators can perform all actions on behalf on an
    // address, *except* for setting a different operator.
    mapping(address => mapping(address => bool)) private operators;

    // Total number of tokens governed by this contract. This allows for the
    // enumeration of all tokens, provided that tokens are created with their
    // identifiers being numbers, incremented by one.
    uint256 private totalTokens;

    // The ERC-165 identifier of the ERC-165 interface. This contract
    // implements the `supportsInterface` method to check whether other types
    // of standard interfaces are supported.
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = bytes4(
        keccak256("supportsInterface(bytes4)")
    );

    // The ERC-165 identifier of the ERC-721 interface. This contract
    // implements all methods of the ERC-721 Enumerable interface, and uses
    // this identifier to supply the correct answer to a call to
    // `supportsInterface`.
    bytes4 private constant INTERFACE_SIGNATURE_ERC721 = bytes4(
        keccak256("balanceOf(address)") ^
        keccak256("ownerOf(uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256,bytes)") ^
        keccak256("safeTransferFrom(address,address,uint256)") ^
        keccak256("transferFrom(address,address,uint256)") ^
        keccak256("approve(address,uint256)") ^
        keccak256("setApprovalForAll(address,bool)") ^
        keccak256("getApproved(uint256)") ^
        keccak256("isApprovedForAll(address,address)")
    );

    // The ERC-165 identifier of the ERC-721 Enumerable interface. This
    // contract implements all methods of the ERC-721 Enumerable interface, and
    // uses this identifier to supply the correct answer to a call to
    // `supportsInterface`.
    bytes4 private constant INTERFACE_SIGNATURE_ERC721_ENUMERABLE = bytes4(
        keccak256("totalSupply()") ^
        keccak256("tokenByIndex(uint256)") ^
        keccak256("tokenOfOwnerByIndex(address,uint256)")
    );

    // The ERC-165 identifier of the ERC-721 Metadata interface. This contract
    // implements all methods of the ERC-721 Metadata interface, and uses the
    // identifier to supply the correct answer to a `supportsInterface` call.
    bytes4 private constant INTERFACE_SIGNATURE_ERC721_METADATA = bytes4(
        keccak256("name()") ^
        keccak256("symbol()") ^
        keccak256("tokenURI(uint256)")
    );

    // The ERC-165 identifier of the ERC-721 Token Receiver interface. This
    // is not implemented by this contract, but is used to identify the
    // response given by the receiving contracts, if the `safeTransferFrom`
    // method is used.
    bytes4 private constant INTERFACE_SIGNATURE_ERC721_TOKEN_RECEIVER = bytes4(
        keccak256("onERC721Received(address,uint256,bytes)")
    );

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
     * Modify method to only allow calls if the token is valid.
     *
     * Notice
     * ------
     * Ethergotchi are valid if they are owned by an address that is not the
     * zero address.
     */
    modifier onlyValidToken(uint256 _tokenId) {
        require(ownerByTokenId[_tokenId] != address(0));
        _;
    }

    /**
     * Modify method to only allow transfers from authorized callers.
     *
     * Notice
     * ------
     * This method also adds a few checks against common transfer beneficiary
     * mistakes to prevent a subset of unintended transfers that cannot be
     * reverted.
     */
    modifier onlyValidTransfers(address _from, address _to, uint256 _tokenId) {
        // Get owner of the token. This is used to check against various cases
        // where the caller is allowed to transfer the token.
        address tokenOwner = ownerByTokenId[_tokenId];

        // Check whether the caller is allowed to transfer the token with given
        // identifier. The caller is allowed to perform the transfer in any of
        // the following cases:
        //  1. the caller is the owner of the token;
        //  2. the caller is approved by the owner of the token to transfer
        //     that specific token; or
        //  3. the caller is approved as operator by the owner of the token, in
        //     which case the caller is approved to perform any action on
        //     behalf of the owner.
        require(
            msg.sender == tokenOwner ||
            msg.sender == approvedTransfers[_tokenId] ||
            operators[tokenOwner][msg.sender]
        );

        // Check against accidental transfers to the common "wrong" addresses.
        // This includes the zero address, this ownership contract address, and
        // "non-transfers" where the same address is filled in for both `_from`
        // and `_to`.
        require(
            _to != address(0) &&
            _to != address(this) &&
            _to != _from
        );

        _;
    }

    /**
     * Ethergotchi ownership contract constructor
     *
     * At the time of contract construction, an Ethergotchi is artificially
     * constructed to ensure that Ethergotchi are numbered starting from one.
     */
    function EthergotchiOwnershipV2(
        address _formerContract
    )
        public
        Controllable()
    {
        ownerByTokenId[0] = address(0);
        tokenIdsByOwner[address(0)].push(0);
        ownerTokenIndexByTokenId[0] = 0;

        // The migration index is initialized to 1 as the zeroth token need not
        // be migrated; it is already created during the construction of this
        // contract.
        migrationIndex = 1;
        formerContract = PartialOwnership(_formerContract);
    }

    /**
     * Add new token into circulation.
     *
     * Parameters
     * ----------
     * _tokenId : uint256
     *     The identifier of the token to add into circulation.
     * _owner : address
     *     The address of the owner who receives the newly added token.
     *
     * Notice
     * ------
     * This method can only be called by active game contracts. Game contracts
     * are added and modified manually. These additions and modifications
     * always trigger an event for audit purposes.
     */
    function add(
        uint256 _tokenId,
        address _owner
    )
        external
        onlyActiveContracts
    {
        // Safety checks to prevent contracts from calling this method without
        // setting the proper arguments.
        require(_tokenId != 0 && _owner != address(0));

        _add(_tokenId, _owner);

        // As per the standard, transfers of newly created tokens should always
        // originate from the zero address.
        Transfer(address(0), _owner, _tokenId);
    }

    /**
     * Check whether contract supports given interface.
     *
     * Parameters
     * ----------
     * interfaceID : bytes4
     *     The four-bytes representation of an interface of which to check
     *     whether this contract supports it.
     *
     * Returns
     * -------
     * bool
     *     True if given interface is supported, else False.
     *
     * Notice
     * ------
     * It is expected that the `bytes4` values of interfaces are generated by
     * calling XOR on all function signatures of the interface.
     *
     * Technically more interfaces are supported, as some interfaces may be
     * subsets of the supported interfaces. This check is only to be used to
     * verify whether "standard interfaces" are supported.
     */
    function supportsInterface(
        bytes4 interfaceID
    )
        external
        view
        returns (bool)
    {
        return (
            interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            interfaceID == INTERFACE_SIGNATURE_ERC721 ||
            interfaceID == INTERFACE_SIGNATURE_ERC721_METADATA ||
            interfaceID == INTERFACE_SIGNATURE_ERC721_ENUMERABLE
        );
    }

    /**
     * Get the name of the token this contract governs ownership of.
     *
     * Notice
     * ------
     * This is the collective name of the token. Individual tokens may be named
     * differently by their owners.
     */
    function name() external pure returns (string) {
        return "Ethergotchi";
    }

    /**
     * Get the symbol of the token this contract governs ownership of.
     *
     * Notice
     * ------
     * This symbol has been explicitly changed to `ETHERGOTCHI` from `GOTCHI`
     * in the `PHOENIX` patch of Aethia to prevent confusion with older tokens.
     */
    function symbol() external pure returns (string) {
        return "ETHERGOTCHI";
    }

    /**
     * Get the URI pointing to a JSON file with metadata for a given token.
     *
     * Parameters
     * ----------
     * _tokenId : uint256
     *     The identifier of the token to get the URI for.
     *
     * Returns
     * -------
     * string
     *     The URI pointing to a JSON file with metadata for the token with
     *     given identifier.
     *
     * Notice
     * ------
     * This method returns a string that may contain more than one null-byte,
     * because the conversion method is not ideal.
     */
    function tokenURI(uint256 _tokenId) external view returns (string) {
        bytes32 tokenIdBytes = Tools.uint256ToBytes32(_tokenId);

        return Tools.concatenate(
            "https://aethia.co/ethergotchi/",
            Tools.bytes32ToString(tokenIdBytes)
        );
    }

    /**
     * Get the number of tokens assigned to given owner.
     *
     * Parameters
     * ----------
     * _owner : address
     *     The address of the owner of which to get the number of owned tokens
     *     of.
     *
     * Returns
     * -------
     * uint256
     *     The number of tokens owned by given owner.
     *
     * Notice
     * ------
     * Tokens owned by the zero address are considered invalid, as described in
     * the EIP 721 standard, and queries regarding the zero address will result
     * in the transaction being rejected.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));

        return tokenIdsByOwner[_owner].length;
    }

    /**
     * Get the address of the owner of given token.
     *
     * Parameters
     * ----------
     * _tokenId : uint256
     *     The identifier of the token of which to get the owner"s address.
     *
     * Returns
     * -------
     * address
     *     The address of the owner of given token.
     *
     * Notice
     * ------
     * Tokens owned by the zero address are considered invalid, as described in
     * the EIP 721 standard, and queries regarding the zero address will result
     * in the transaction being rejected.
     */
    function ownerOf(uint256 _tokenId) external view returns (address) {
        // Store the owner in a temporary variable to avoid having to do the
        // lookup twice.
        address _owner = ownerByTokenId[_tokenId];

        require(_owner != address(0));

        return _owner;
    }

    /**
     * Transfer the ownership of given token from one address to another.
     *
     * Parameters
     * ----------
     * _from : address
     *     The benefactor address to transfer the given token from.
     * _to : address
     *     The beneficiary address to transfer the given token to.
     * _tokenId : uint256
     *     The identifier of the token to transfer.
     * data : bytes
     *     Non-specified data to send along the transfer towards the `to`
     *     address that can be processed.
     *
     * Notice
     * ------
     * This method performs a check to determine whether the receiving party is
     * a smart contract by calling the `_isContract` method. This works until
     * the `Serenity` update of Ethereum is deployed.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes data
    )
        external
        onlyValidToken(_tokenId)
    {
        // Call the internal `_safeTransferFrom` method to avoid duplicating
        // the transfer code.
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    /**
     * Transfer the ownership of given token from one address to another.
     *
     * Parameters
     * ----------
     * _from : address
     *     The benefactor address to transfer the given token from.
     * _to : address
     *     The beneficiary address to transfer the given token to.
     * _tokenId : uint256
     *     The identifier of the token to transfer.
     *
     * Notice
     * ------
     * This method does exactly the same as calling the `safeTransferFrom`
     * method with the `data` parameter set to an empty bytes value:
     *  `safeTransferFrom(_from, _to, _tokenId, "")`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        onlyValidToken(_tokenId)
    {
        // Call the internal `_safeTransferFrom` method to avoid duplicating
        // the transfer code.
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * Transfer the ownership of given token from one address to another.
     *
     * Parameters
     * ----------
     * _from : address
     *     The benefactor address to transfer the given token from.
     * _to : address
     *     The beneficiary address to transfer the given token to.
     * _tokenId : uint256
     *     The identifier of the token to transfer.
     *
     * Notice
     * ------
     * This method performs a few rudimentary checks to determine whether the
     * receiving party can actually receive the token. However, it is still up
     * to the caller to ensure this is actually the case.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        onlyValidToken(_tokenId)
        onlyValidTransfers(_from, _to, _tokenId)
    {
        _transfer(_to, _tokenId);
    }

    /**
     * Approve the given address for the transfer of the given token.
     *
     * Parameters
     * ----------
     * _approved : address
     *     The address to approve. Approval allows the address to transfer the
     *     given token to a different address.
     * _tokenId : uint256
     *     The identifier of the token to give transfer approval for.
     *
     * Notice
     * ------
     * There is no specific method to revoke approvals, but the approval is
     * removed after the transfer has been completed. Additionally the owner
     * or operator may call the method with the zero address as `_approved` to
     * effectively revoke the approval.
     */
    function approve(address _approved, uint256 _tokenId) external {
        address _owner = ownerByTokenId[_tokenId];

        // Approval can only be given by the owner or an operator approved by
        // the owner.
        require(msg.sender == _owner || operators[_owner][msg.sender]);

        // Set address as approved for transfer. It can be the case that the
        // address was already set (e.g. this method was called twice in a row)
        // in which case this does not change anything.
        approvedTransfers[_tokenId] = _approved;

        Approval(msg.sender, _approved, _tokenId);
    }

    /**
     * Set approval for a third-party to manage all tokens of the caller.
     *
     * Parameters
     * ----------
     * _operator : address
     *     The address to set the operator status for.
     * _approved : bool
     *     The operator status. True if the given address should be allowed to
     *     act on behalf of the caller, else False.
     *
     * Notice
     * ------
     * There is no duplicate checking done out of simplicity. Callers are thus
     * able to set the same address as operator a multitude of times, even if
     * it does not change the actual state of the system.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        operators[msg.sender][_operator] = _approved;

        ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * Get approved address for given token.
     *
     * Parameters
     * ----------
     * _tokenId : uint256
     *     The identifier of the token of which to get the approved address of.
     *
     * Returns
     * -------
     * address
     *     The address that is allowed to initiate a transfer of the given
     *     token.
     *
     * Notice
     * ------
     * Technically this method could be implemented without the method modifier
     * as the network guarantees that the address mapping is initiated with all
     * addresses set to the zero address. The requirement is implemented to
     * comply with the standard as described in EIP-721.
     */
    function getApproved(
        uint256 _tokenId
    )
        external
        view
        onlyValidToken(_tokenId)
        returns (address)
    {
        return approvedTransfers[_tokenId];
    }

    /**
     * Check whether an address is an authorized operator of another address.
     *
     * Parameters
     * ----------
     * _owner : address
     *     The address of which to check whether it has approved the other
     *     address to act as operator.
     * _operator : address
     *     The address of which to check whether it has been approved to act
     *     as operator on behalf of `_owner`.
     *
     * Returns
     * -------
     * bool
     *     True if `_operator` is approved for all actions on behalf of
     *     `_owner`.
     *
     * Notice
     * ------
     * This method cannot fail, as the Ethereum network guarantees that all
     * address mappings exist and are set to the zero address by default.
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        external
        view
        returns (bool)
    {
        return operators[_owner][_operator];
    }

    /**
     * Get the total number of tokens currently in circulation.
     *
     * Returns
     * -------
     * uint256
     *     The total number of tokens currently in circulation.
     */
    function totalSupply() external view returns (uint256) {
        return totalTokens;
    }

    /**
     * Get token identifier by index.
     *
     * Parameters
     * ----------
     * _index : uint256
     *     The index of the token to get the identifier of.
     *
     * Returns
     * -------
     * uint256
     *     The identifier of the token at given index.
     *
     * Notice
     * ------
     * Ethergotchi tokens are incrementally numbered starting from zero, and
     * always go up by one. The index of the token is thus equivalent to its
     * identifier.
     */
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < totalTokens);

        return _index;
    }

    /**
     * Get token of owner by index.
     *
     * Parameters
     * ----------
     * _owner : address
     *     The address of the owner of which to get the token of.
     * _index : uint256
     *     The index of the token in the given owner"s list of token.
     *
     * Returns
     * -------
     * uint256
     *     The identifier of the token at given index of an owner"s list of
     *     tokens.
     */
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        view
        returns (uint256)
    {
        require(_index < tokenIdsByOwner[_owner].length);

        return tokenIdsByOwner[_owner][_index];
    }

    /**
     * Check whether given address is a smart contract.
     *
     * Parameters
     * ----------
     * _address : address
     *     The address of which to check whether it is a contract.
     *
     * Returns
     * -------
     * bool
     *     True if given address is a contract, else False.
     *
     * Notice
     * ------
     * This method works as long as the `Serenity` update of Ethereum has not
     * been deployed. At the time of writing, contracts cannot set their code
     * size to zero, nor can "normal" addresses set their code size to anything
     * non-zero. With `Serenity` the idea will be that each and every address
     * is an contract, effectively rendering this method.
     */
    function _isContract(address _address) internal view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(_address)
        }

        return size > 0;
    }

    /**
     * Transfer the ownership of given token from one address to another.
     *
     * Parameters
     * ----------
     * _from : address
     *     The benefactor address to transfer the given token from.
     * _to : address
     *     The beneficiary address to transfer the given token to.
     * _tokenId : uint256
     *     The identifier of the token to transfer.
     * data : bytes
     *     Non-specified data to send along the transfer towards the `to`
     *     address that can be processed.
     *
     * Notice
     * ------
     * This method performs a check to determine whether the receiving party is
     * a smart contract by calling the `_isContract` method. This works until
     * the `Serenity` update of Ethereum is deployed.
     */
    function _safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId,
        bytes data
    )
        internal
        onlyValidTransfers(_from, _to, _tokenId)
    {
        // Call the method that performs the actual transfer. All common cases
        // of "wrong" transfers have already been checked at this point. The
        // internal transfer method does no checking.
        _transfer(_to, _tokenId);

        // Check whether the receiving party is a contract, and if so, call
        // the `onERC721Received` method as defined in the ERC-721 standard.
        if (_isContract(_to)) {

            // Assume the receiving party has implemented ERC721TokenReceiver,
            // as otherwise the "unsafe" `transferFrom` method should have been
            // called instead.
            ERC721TokenReceiver _receiver = ERC721TokenReceiver(_to);

            // The response returned by `onERC721Received` of the receiving
            // contract"s `on *must* be equal to the magic number defined by
            // the ERC-165 signature of `ERC721TokenReceiver`. If this is not
            // the case, the transaction will be reverted.
            require(
                _receiver.onERC721Received(
                    address(this),
                    _tokenId,
                    data
                ) == INTERFACE_SIGNATURE_ERC721_TOKEN_RECEIVER
            );
        }
    }

    /**
     * Transfer token to new owner.
     *
     * Parameters
     * ----------
     * _to : address
     *     The address of the owner-to-be of given token.
     * _tokenId : _tokenId
     *     The identifier of the token that is to be transferred.
     *
     * Notice
     * ------
     * This method performs no safety checks as it can only be called within
     * the controlled environment of this contract.
     */
    function _transfer(address _to, uint256 _tokenId) internal {
        // Get current owner of the token. It is technically possible that the
        // owner is the same address as the address to which the token is to be
        // sent to. In this case the token will be moved to the end of the list
        // of tokens owned by this address.
        address _from = ownerByTokenId[_tokenId];

        // There are two possible scenarios for transfers when it comes to the
        // removal of the token from the side that currently owns the token:
        //  1: the owner has two or more tokens; or
        //  2: the owner has one token.
        if (tokenIdsByOwner[_from].length > 1) {

            // Get the index of the token that has to be removed from the list
            // of tokens owned by the current owner.
            uint256 tokenIndexToDelete = ownerTokenIndexByTokenId[_tokenId];

            // To keep the list of tokens without gaps, and thus reducing the
            // gas cost associated with interacting with the list, the last
            // token in the owner"s list of tokens is moved to fill the gap
            // created by removing the token.
            uint256 tokenIndexToMove = tokenIdsByOwner[_from].length - 1;

            // Overwrite the token that is to be removed with the token that
            // was at the end of the list. It is possible that both are one and
            // the same, in which case nothing happens.
            tokenIdsByOwner[_from][tokenIndexToDelete] =
                tokenIdsByOwner[_from][tokenIndexToMove];
        }

        // Remove the last item in the list of tokens owned by the current
        // owner. This item has either already been copied to the location of
        // the token that is to be transferred, or is the only token of this
        // owner in which case the list of tokens owned by this owner is now
        // empty.
        tokenIdsByOwner[_from].length--;

        // Add the token to the list of tokens owned by `_to`. Items are always
        // added to the very end of the list. This makes the token index of the
        // new token within the owner"s list of tokens equal to the length of
        // the list minus one as Solidity is a zero-based language. This token
        // index is then set for this token identifier.
        tokenIdsByOwner[_to].push(_tokenId);
        ownerTokenIndexByTokenId[_tokenId] = tokenIdsByOwner[_to].length - 1;

        // Set the direct ownership information of the token to the new owner
        // after all other ownership-related mappings have been updated to make
        // sure the "side" data is correct.
        ownerByTokenId[_tokenId] = _to;

        // Remove the approved address of this token. It may be the case there
        // was no approved address, in which case nothing changes.
        approvedTransfers[_tokenId] = address(0);

        // Log the transfer event onto the blockchain to leave behind an audit
        // trail of all transfers that have taken place.
        Transfer(_from, _to, _tokenId);
    }

    /**
     * Add new token into circulation.
     *
     * Parameters
     * ----------
     * _tokenId : uint256
     *     The identifier of the token to add into circulation.
     * _owner : address
     *     The address of the owner who receives the newly added token.
     */
    function _add(uint256 _tokenId, address _owner) internal {
        // Ensure the token does not already exist, and prevent duplicate calls
        // using the same identifier.
        require(ownerByTokenId[_tokenId] == address(0));

        // Update the direct ownership mapping, by setting the owner of the
        // token identifier to `_owner`, and adding the token to the list of
        // tokens owned by `_owner`. Arrays are always initialized to empty
        // versions of of their specific type, thus ensuring that the `push`
        // method will not fail.
        ownerByTokenId[_tokenId] = _owner;
        tokenIdsByOwner[_owner].push(_tokenId);

        // Update the mapping that keeps track of a token"s index within the
        // list of tokens owned by each owner. At the time of addition a token
        // is always added to the end of the list, and will thus always equal
        // the number of tokens already in the list, minus one, because the
        // arrays within Solidity are zero-based.
        ownerTokenIndexByTokenId[_tokenId] = tokenIdsByOwner[_owner].length - 1;

        totalTokens += 1;
    }

    /*********************************************/
    /** MIGRATION state variables and functions **/
    /*********************************************/

    // This number is used to keep track of how many tokens have been migrated.
    // The number cannot exceed the number of tokens that were assigned to
    // owners in the previous Ownership contract.
    uint256 public migrationIndex;

    // The previous token ownership contract.
    PartialOwnership private formerContract;

    /**
     * Migrate data from the former Ethergotchi ownership contract.
     *
     * Parameters
     * ----------
     * _count : uint256
     *     The number of tokens to migrate in a single transaction.
     *
     * Notice
     * ------
     * This method is limited in use to ensure no &#39;malicious&#39; calls are made.
     * Additionally, this method writes to a contract state variable to keep
     * track of how many tokens have been migrated.
     */
    function migrate(uint256 _count) external onlyOwner {
        // Ensure that the migrate function can *only* be called in a specific
        // time period. This period ranges from Saturday, March 24th, 00:00:00
        // UTC until Sunday, March 25th, 23:59:59 UTC.
        require(1521849600 <= now && now <= 1522022399);

        // Get the maximum number of tokens handed out by the previous
        // ownership contract.
        uint256 formerTokenCount = formerContract.totalSupply();

        // The index to stop the migration at for this transaction.
        uint256 endIndex = migrationIndex + _count;

        // It is possible that the final transaction has a higher end index
        // than there are a number of tokens. In this case, the end index is
        // reduced to ensure no non-existent tokens are migrated.
        if (endIndex >= formerTokenCount) {
            endIndex = formerTokenCount;
        }

        // Loop through the token identifiers to migrate in this transaction.
        // Token identifiers are equivalent to their &#39;index&#39;, as identifiers
        // start at zero (with the zeroth token being owned by the zero
        // address), and are incremented by one for each new token.
        for (uint256 i = migrationIndex; i < endIndex; i++) {
            address tokenOwner;

            // There was a malicious account that acquired over 400 eggs via
            // referral codes, which breaks the terms of use. The acquired egg
            // numbers ranged from identifier 1247 up until 1688, excluding
            // 1296, 1297, 1479, 1492, 1550, 1551, and 1555. This was found by
            // looking at activity on the pick-up contract, and tracing it back
            // to the following address:
            //  `0c7a911ac29ea1e3b1d438f98f8bc053131dcaf52`
            if (_isExcluded(i)) {
                tokenOwner = address(0);
            } else {
                tokenOwner = formerContract.ownerOf(i);
            }

            // Assign the token to the same address that owned it in the
            // previous ownership contract.
            _add(i, tokenOwner);

            // Log the token transfer. In this case where the token is &#39;newly&#39;
            // created, but actually transferred from a previous contract, the
            // `_from` address is set to the previous contract address, to
            // signify a migration.
            Transfer(address(formerContract), tokenOwner, i);
        }

        // Set the new migration index to where the current transaction ended
        // its migration.
        migrationIndex = endIndex;
    }

    /**
     * Check if Ethergotchi should be excluded from migration.
     *
     * Parameters
     * ----------
     * _gotchiId : uint256
     *     The identifier of the Ethergotchi of which to check the exclusion
     *     status.
     *
     * Returns
     * -------
     * bool
     *     True if the Ethergotchi should be excluded from the migration, else
     *     False.
     */
    function _isExcluded(uint256 _gotchiId) internal pure returns (bool) {
        return
            1247 <= _gotchiId && _gotchiId <= 1688 &&
            _gotchiId != 1296 &&
            _gotchiId != 1297 &&
            _gotchiId != 1479 &&
            _gotchiId != 1492 &&
            _gotchiId != 1550 &&
            _gotchiId != 1551 &&
            _gotchiId != 1555;
    }
}