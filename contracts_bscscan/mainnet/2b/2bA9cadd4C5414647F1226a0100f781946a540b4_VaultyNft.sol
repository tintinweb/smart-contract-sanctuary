pragma solidity 0.6.12;

import "../token/ERC1155.sol";

contract VaultyNft is ERC1155Mintable {
    string private _contractURI;

    constructor(address _proxyRegistryAddress) public ERC1155Mintable("Vaulty NFT", "VaultyNFT", _proxyRegistryAddress) {
        _setBaseMetadataURI("https://api.vaulty.finance/nft/");
    }
    
    /**
         * @dev Ends minting of token
         * @param _id          Token ID for which minting will end
         */
    function endMinting(uint256 _id) external onlyWhitelistAdmin {
        tokenMaxSupply[_id] = tokenSupply[_id];
    }

    function burnFt(address _account, uint256 _id, uint256 _amount) public onlyMinter {
        _burnFungible(_account, _id, _amount);
    }

    function burnNft(address _account, uint256 _id) public onlyMinter {
        _burnNonFungible(_account, _id);
    }

    function airdropFt(uint256 _id, address[] memory _addresses) public onlyMinter {
        require(tokenMaxSupply[_id] - tokenSupply[_id] >= _addresses.length, "cannot mint above max supply");
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintFt(_addresses[i], _id, 1, "");
        }
    }

    function airdropNft(uint256 _type, address[] memory _addresses) public onlyMinter {
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintNft(_addresses[i], _type, "");
        }
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol";
import "./IERC165.sol";
import "./IERC1155TokenReceiver.sol";
import "../lib/MinterRole.sol";
import "../lib/WhitelistAdminRole.sol";
import "../lib/Strings.sol";
import "./ProxyRegistry.sol";

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC165 {
    using SafeMath for uint256;
    using Address for address;

    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 internal constant TYPE_MASK = uint256(uint128(~0)) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 internal constant NF_INDEX_MASK = uint128(~0);

    uint256 internal constant TYPE_NF_BIT = 1 << 255;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // onReceive function signatures
    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    // Objects balances
    mapping(address => mapping(uint256 => uint256)) internal balances;

    mapping(uint256 => address) public nfOwners;

    // Operator Functions
    mapping(address => mapping(address => bool)) internal operators;

    // Events
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _uri, uint256 indexed _id);

    function getNonFungibleIndex(uint256 _id) public pure returns (uint256) {
        return _id & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _id) public pure returns (uint256) {
        return _id & TYPE_MASK;
    }

    function ownerOf(uint256 _id) public view returns (address) {
        return nfOwners[_id];
    }

    function isNonFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    /***********************************|
    |     Public Transfer Functions     |
    |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "erc1155#safetransferfrom: INVALID_OPERATOR"
        );
        require(_to != address(0), "erc1155#safetransferfrom: INVALID_RECIPIENT");
        // require(_amount >= balances[_from][_id]) is not necessary since checked with safemath operations

        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, _data);
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public {
        // Requirements
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "erc1155#safebatchtransferfrom: INVALID_OPERATOR"
        );
        require(_to != address(0), "erc1155#safebatchtransferfrom: INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
    }

    /***********************************|
    |    Internal Transfer Functions    |
    |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal {
        // Update balances
        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from, "erc1155#_safeTransferFrom: NOT OWNER");
            nfOwners[_id] = _to;
        } else {
            balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
            balances[_to][_id] = balances[_to][_id].add(_amount); // Add amount
        }

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
     */
    function _callonERC1155Received(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Check if recipient is contract
        if (_to.isContract()) {
            bytes4 retval =
                IERC1155TokenReceiver(_to).onERC1155Received(
                    msg.sender,
                    _from,
                    _id,
                    _amount,
                    _data
                );
            require(
                retval == ERC1155_RECEIVED_VALUE,
                "erc1155#_callonerc1155received: INVALID_ON_RECEIVE_MESSAGE"
            );
        }
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     */
    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal {
        require(
            _ids.length == _amounts.length,
            "erc1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH"
        );

        // Number of transfer to execute
        uint256 nTransfer = _ids.length;

        // Executing all transfers
        for (uint256 i = 0; i < nTransfer; i++) {
            uint256 id = _ids[i];

            if (isNonFungible(id)) {
                require(nfOwners[id] == _from, "erc1155#_safeBatchTransferFrom: NOT OWNER");
                nfOwners[id] = _to;
            } else {
                // Update storage balance of previous bin
                balances[_from][id] = balances[_from][id].sub(_amounts[i]);
                balances[_to][id] = balances[_to][id].add(_amounts[i]);
            }
        }

        // Emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
     */
    function _callonERC1155BatchReceived(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        // Pass data if recipient is contract
        if (_to.isContract()) {
            bytes4 retval =
                IERC1155TokenReceiver(_to).onERC1155BatchReceived(
                    msg.sender,
                    _from,
                    _ids,
                    _amounts,
                    _data
                );
            require(
                retval == ERC1155_BATCH_RECEIVED_VALUE,
                "erc1155#_callonerc1155batchreceived: INVALID_ON_RECEIVE_MESSAGE"
            );
        }
    }

    /***********************************|
    |         Operator Functions        |
    |__________________________________*/

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        // Update operator status
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return isOperator True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }

    /***********************************|
    |         Balance Functions         |
    |__________________________________*/

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) public view returns (uint256) {
        return balances[_owner][_id];
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
        public
        view
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length, "erc1155#balanceofbatch: INVALID_ARRAY_LENGTH");

        // Variables
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < _owners.length; i++) {
            batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }

    /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/

    /**
     * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /**
     * INTERFACE_SIGNATURE_ERC1155 =
     * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
     * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
     * bytes4(keccak256("balanceOf(address,uint256)")) ^
     * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
     * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
     * bytes4(keccak256("isApprovedForAll(address,address)"));
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceID  The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `_interfaceID` and
     */
    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        if (
            _interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155
        ) {
            return true;
        }
        return false;
    }
}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {
    using Strings for uint256;

    // URI's default URI prefix
    string internal baseMetadataURI;
    event URI(string _uri, uint256 indexed _id);

    /***********************************|
    |     Metadata Public Function s    |
    |__________________________________*/

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     *      Token IDs are assumed to be represented in their hex format in URIs
     * @return URI string
     */
    function uri(uint256 _id) public view virtual returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, _id.uint2str()));
    }

    /***********************************|
    |    Metadata Internal Functions    |
    |__________________________________*/

    /**
     * @notice Will emit default URI log event for corresponding token _id
     * @param _tokenIDs Array of IDs of tokens to log default URI
     */
    function _logURIs(uint256[] memory _tokenIDs) internal {
        string memory baseURL = baseMetadataURI;
        string memory tokenURI;

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            tokenURI = string(abi.encodePacked(baseURL, _tokenIDs[i].uint2str()));
            emit URI(tokenURI, _tokenIDs[i]);
        }
    }

    /**
     * @notice Will emit a specific URI log event for corresponding token
     * @param _tokenIDs IDs of the token corresponding to the _uris logged
     * @param _URIs    The URIs of the specified _tokenIDs
     */
    function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
        require(
            _tokenIDs.length == _URIs.length,
            "erc1155metadata#_loguris: INVALID_ARRAYS_LENGTH"
        );
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            emit URI(_URIs[i], _tokenIDs[i]);
        }
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
        baseMetadataURI = _newBaseMetadataURI;
    }
}

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
    mapping(uint256 => uint256) maxIndex;

    /****************************************|
    |            Minting Functions           |
    |_______________________________________*/

    /**
     * @notice Mint _amount of tokens of a given id
     * @param _to      The address to mint tokens to
     * @param _id      Token id to mint
     * @param _amount  The amount to be minted
     * @param _data    Data to pass if receiver is contract
     */
    function _mintFungible(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Add _amount
        balances[_to][_id] = balances[_to][_id].add(_amount);

        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
    }

    function _mintNonFungible(
        address _to,
        uint256 _type,
        bytes memory _data
    ) internal returns (uint256) {
        require(isNonFungible(_type), "not nft");

        uint256 index = maxIndex[_type] + 1;
        maxIndex[_type] = index;

        uint256 _id = _type | index;

        nfOwners[_id] = _to;

        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, 1);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(address(0x0), _to, _id, 1, _data);

        return _id;
    }

    /****************************************|
    |            Burning Functions           |
    |_______________________________________*/

    /**
     * @notice Burn _amount of tokens of a given token id
     * @param _from    The address to burn tokens from
     * @param _id      Token id to burn
     * @param _amount  The amount to be burned
     */
    function _burnFungible(
        address _from,
        uint256 _id,
        uint256 _amount
    ) internal {
        //Substract _amount
        balances[_from][_id] = balances[_from][_id].sub(_amount);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
    }

    function _burnNonFungible(address _from, uint256 _id) internal {
        require(nfOwners[_id] == _from);

        nfOwners[_id] = address(0x0);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, 1);
    }
}

/**
 * @title ERC1155Mintable
 * ERC1155Mintable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Mintable is
    ERC1155,
    ERC1155MintBurn,
    ERC1155Metadata,
    Ownable,
    MinterRole,
    WhitelistAdminRole
{
    using Strings for string;

    address proxyRegistryAddress;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyWhitelistAdmin {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @return tokenId The newly created token ID
     */
    function create(
        uint256 _type,
        uint256 _maxSupply,
        uint256 _initialSupply,
        bool isNft,
        string calldata _uri,
        bytes calldata _data
    ) external onlyWhitelistAdmin returns (uint256 tokenId) {
        if (isNft) {
            _type <<= 128;
            _type |= TYPE_NF_BIT;
        }

        require(tokenMaxSupply[_type] == 0, "type exists");
        require(_initialSupply <= _maxSupply, "initial supply cannot be more than max supply");
        require(_maxSupply != 0, "incorrect max supply");

        if (bytes(_uri).length != 0) {
            emit URI(_uri, _type);
        }

        if (_initialSupply != 0) {
            if (isNft) {
                for (uint256 i = 0; i < _initialSupply; ++i) {
                    _mintNonFungible(msg.sender, _type, _data);
                }
            } else {
                _mintFungible(msg.sender, _type, _initialSupply, _data);
            }

            tokenSupply[_type] = _initialSupply;
        }

        tokenMaxSupply[_type] = _maxSupply;
        return _type;
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mintFt(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public onlyMinter {
        uint256 tokenId = _id;

        uint256 newSupply = tokenSupply[tokenId].add(_quantity);
        require(newSupply <= tokenMaxSupply[tokenId], "max supply has reached");

        _mintFungible(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function mintNft(
        address _to,
        uint256 _type,
        bytes memory _data
    ) public onlyMinter returns (uint256) {
        uint256 newSupply = tokenSupply[_type].add(1);
        require(newSupply <= tokenMaxSupply[_type], "max supply has reached");

        uint256 id = _mintNonFungible(_to, _type, _data);
        tokenSupply[_type]++;
        return id;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return tokenMaxSupply[_id] != 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

pragma solidity 0.6.12;

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    virtual
    external
    view
    returns (bool);
}

pragma solidity 0.6.12;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) virtual external returns(bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) virtual external returns(bytes4);

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) virtual external view returns (bool);

}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "./Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "not minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "not admin");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

pragma solidity 0.6.12;

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity 0.6.12;

import "../Governable.sol";

contract ProxyRegistry is Governable {
  mapping(address => address) public proxies;

  constructor(address _storage) public Governable(_storage) {}

  function addOperator(address _owner, address _operator) public onlyGovernance {
    proxies[_owner] = _operator;
  }

  function removeOperator(address _owner) public onlyGovernance {
    delete proxies[_owner];
  }
}

pragma solidity 0.6.12;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "roles: account already has requested role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "roles: account does not have needed role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity 0.6.12;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

pragma solidity 0.6.12;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}