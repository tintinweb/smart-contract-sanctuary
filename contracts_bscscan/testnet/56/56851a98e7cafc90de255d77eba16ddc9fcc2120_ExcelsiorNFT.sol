/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

pragma solidity ^0.5.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function approve(address to, uint256 tokenId) public;

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;
}

contract IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping(uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor() public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval =
            IERC721Receiver(to).onERC721Received(
                msg.sender,
                from,
                tokenId,
                _data
            );
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(
            isMinter(msg.sender),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
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

/**
 * @title ERC721Mintable
 * @dev ERC721 minting logic.
 */
contract ERC721Mintable is ERC721, MinterRole {

    bool public anyoneCanMint;

    /**
     * @dev Options to activate or deactivate mint ability
     */

    function _setMintableOption(bool _anyoneCanMint) internal {
        anyoneCanMint = _anyoneCanMint;
    }

    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 tokenId)
        public
        onlyMinter
        returns (bool)
    {
        _mint(to, tokenId);
        return true;
    }

    function canIMint() public view returns (bool) {
        return anyoneCanMint || isMinter(msg.sender);
    }

    /**
     * Open modifier to anyone can mint possibility
     */
    modifier onlyMinter() {
        string memory mensaje;
        require(
            canIMint(),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

}

/**
 * @title ERC721MetadataMintable
 * @dev ERC721 minting logic with metadata.
 */
contract ERC721MetadataMintable is ERC721, ERC721Metadata, MinterRole {
    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param tokenURI The token URI of the minted token.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return true;
    }
}

/**
 * @title ERC721
 * Full ERC-721 Token with automint function
 */

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata, ERC721Mintable, ERC721MetadataMintable {

    uint256 public autoTokenId;
    constructor (string memory name, string memory symbol, bool _anyoneCanMint, uint256 _autoTokenId) public
        ERC721Mintable()
        ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks

        _setMintableOption(_anyoneCanMint);
        autoTokenId = _autoTokenId;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev Function to mint tokens with automatic ID
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function autoMint(address to, string memory tokenURI) public onlyMinter returns (bool) {
        do {
            autoTokenId++;
        } while(_exists(autoTokenId));
        _mint(to, autoTokenId);
        _setTokenURI(autoTokenId, tokenURI);
        return true;
    }

    /**
     * @dev Function to transfer tokens
     * @param to The address that will receive the minted tokens.
     * @param tokenId the token ID
     */
    function transfer(
        address to,
        uint256 tokenId
    ) public {
        _transferFrom(msg.sender, to, tokenId);
    }

}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

/**
 * @title NFT
 * ERC-721 Marketplace
 */

contract ExcelsiorNFT is ERC721Full, ReentrancyGuard {

    using SafeMath for uint256;

    using Address for address payable;

    // admin address, the owner of the marketplace
    address admin;

    IERC20 XLSR;

    // commission rate is a value from 0 to 100
    uint256 commissionRate;

    // last price sold or auctioned
    mapping(uint256 => uint256) public soldFor;

    // Mapping from token ID to sell price in Ether or to bid price, depending if it is an auction or not
    mapping(uint256 => uint256) public sellBidPrice;

    // Mapping payment address for tokenId
    mapping(uint256 => address) private _wallets;

    event Sale(uint256 indexed tokenId, address indexed from, address indexed to, uint256 value);
    event Commission(uint256 indexed tokenId, address indexed to, uint256 value, uint256 rate, uint256 total);

    /*

    index   _isAuction  _sellBidPrice   Meaning
    0       true        0               Item 0 is on auction and no bids so far
    1       true        10              Item 1 is on auction and the last bid is for 10 Ethers
    2       false       0               Item 2 is not on auction nor for sell
    3       false       10              Item 3 is on sale for 10 Ethers

    */

    // Auction data
    struct Auction {

        // Parameters of the auction. Times are either
        // absolute unix timestamps (seconds since 1970-01-01)
        // or time periods in seconds.
        address beneficiary;
        uint auctionStart;
        uint auctionEnd;

        // Current state of the auction.
        address highestBidder;
        uint highestBid;

        // Set to true at the end, disallows any change
        bool open;

        // minimum reserve price in wei
        uint256 reserve;

    }

    // mapping auctions for each tokenId
    mapping(uint256 => Auction) public auctions;

    // Events that will be fired on changes.
    event Refund(address bidder, uint amount);
    event HighestBidIncreased(address indexed bidder, uint amount, uint256 tokenId);
    event AuctionEnded(address winner, uint amount);

    event LimitSell(address indexed from, address indexed to, uint256 amount);
    event LimitBuy(address indexed from, address indexed to, uint256 amount);
    event MarketSell(address indexed from, address indexed to, uint256 amount);
    event MarketBuy(address indexed from, address indexed to, uint256 amount);

    event SaleClosed(uint256 tokenId);
    event AuctionClosed(uint256 tokenId);

    constructor(address tokenAddress, address _admin, uint256 _commissionRate, string memory name, string memory symbol, bool _anyoneCanMint, uint256 _autoTokenId) public
        ERC721Full(name, symbol, _anyoneCanMint, _autoTokenId) {
        admin = _admin;
        require(_commissionRate<=100, "NFT: Commission rate has to be between 0 and 100");
        commissionRate = _commissionRate;
        XLSR = IERC20(tokenAddress);
    }

     modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "AdminRole: caller does not have the Admin role"
        );
        _;
    }

    function setAutoTokenId(uint256 _autoTokenId) public onlyAdmin returns(bool){
        autoTokenId = _autoTokenId;
        return true;
    }

    function addMinter(address account) public onlyAdmin returns(bool) {
        _addMinter(account);
        return true;
    }

    function renounceMinter(address account) public onlyAdmin returns(bool){
        _removeMinter(account);
        return true;
    }

    function canSell(uint256 tokenId) public view returns (bool) {
        return (ownerOf(tokenId)==msg.sender && !auctions[tokenId].open);
    }

    // Sell option for a fixed price
    function sell(uint256 tokenId, uint256 price, address wallet) public returns (bool){

        // onlyOwner
        require(ownerOf(tokenId)==msg.sender, "NFT: Only owner can sell this item");

        // cannot set a price if auction is activated
        require(!auctions[tokenId].open, "NFT: Cannot sell an item which has an active auction");

        // set sell price for index
        sellBidPrice[tokenId] = price;

        // If price is zero, means not for sale
        if (price>0) {

            // approve the Index to the current contract
            approve(address(this), tokenId);

            // set wallet payment
            _wallets[tokenId] = wallet;
            return true;
        }
        return false;
    }

    // simple function to return the price of a tokenId
    // returns: sell price, bid price, sold price, only one can be non zero
    function getPrice(uint256 tokenId) public view returns (uint256, uint256, uint256) {
        if (sellBidPrice[tokenId]>0) return (sellBidPrice[tokenId], 0, 0);
        if (auctions[tokenId].highestBid>0) return (0, auctions[tokenId].highestBid, 0);
        return (0, 0, soldFor[tokenId]);
    }

    function canBuy(uint256 tokenId) public view returns (uint256) {
        if (!auctions[tokenId].open && sellBidPrice[tokenId]>0 && sellBidPrice[tokenId]>0 && getApproved(tokenId) == address(this)) {
            return sellBidPrice[tokenId];
        } else {
            return 0;
        }
    }

    // Buy option
    function buy(uint256 tokenId) public nonReentrant returns(bool){

        // is on sale
        require(!auctions[tokenId].open && sellBidPrice[tokenId]>0, "NFT: The collectible is not for sale");

        // transfer funds
        require(XLSR.balanceOf(msg.sender) >=  sellBidPrice[tokenId], "NFT: Not enough funds"); // B

        // transfer ownership
        address owner = ownerOf(tokenId);

        require(msg.sender!=owner, "NFT: The seller cannot buy his own collectible");

        // we need to call a transferFrom from this contract, which is the one with permission to sell the NFT
        callOptionalReturn(this, abi.encodeWithSelector(this.transferFrom.selector, owner, msg.sender, tokenId));

        // calculate amounts
        uint256 amount4admin =  sellBidPrice[tokenId].mul(commissionRate).div(100);
        uint256 amount4owner =  sellBidPrice[tokenId].sub(amount4admin);

        require(XLSR.allowance(msg.sender, address(this)) >= sellBidPrice[tokenId], "allowance not enough" );
        XLSR.transferFrom(msg.sender, address(this),  sellBidPrice[tokenId]);
        XLSR.transfer(_wallets[tokenId], amount4owner);
        XLSR.transfer(admin, amount4admin);

        // close the sell
        sellBidPrice[tokenId] = 0;
        _wallets[tokenId] = address(0);

        soldFor[tokenId] = sellBidPrice[tokenId];

        emit Sale(tokenId, owner, msg.sender, sellBidPrice[tokenId]);
        emit Commission(tokenId, owner, sellBidPrice[tokenId], commissionRate, amount4admin);
        return true;
    }

    function canAuction(uint256 tokenId) public view returns (bool) {
        return (ownerOf(tokenId)==msg.sender && !auctions[tokenId].open && sellBidPrice[tokenId]==0);
    }

    // Instantiate an auction contract for a tokenId
    function createAuction(uint256 tokenId, uint _startingTime, uint _closingTime, address _beneficiary, uint256 _reservePrice) public returns(bool){

        require(sellBidPrice[tokenId]==0, "NFT: The selected NFT is open for sale, cannot be auctioned");
        require(!auctions[tokenId].open, "NFT: The selected NFT already has an auction");
        require(ownerOf(tokenId)==msg.sender, "NFT: Only owner can auction this item");
        require(_startingTime < _closingTime, "Invalid start or end time");
        require(_closingTime <= _startingTime + 10 days, "Max auction duration can not exceed 10 days");

        auctions[tokenId].beneficiary = _beneficiary;
        auctions[tokenId].auctionStart = _startingTime;
        auctions[tokenId].auctionEnd = _closingTime;
        auctions[tokenId].reserve = _reservePrice;
        auctions[tokenId].open = true; //XXXX

        // approve the Index to the current contract
        approve(address(this), tokenId);
        return true;
    }

    function canBid(uint256 tokenId) public view returns (bool) {
        if (!address(msg.sender).isContract() &&
            auctions[tokenId].open &&
            now >= auctions[tokenId].auctionStart &&
            now <= auctions[tokenId].auctionEnd &&
            msg.sender != ownerOf(tokenId) &&
            getApproved(tokenId) == address(this)
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(uint256 tokenId, uint256 price) public nonReentrant returns(bool) {
        // No arguments are necessary, all
        // information is already part of
        // the transaction.

        require(XLSR.balanceOf(msg.sender) >= price, "Insuffucuent funds");

        // Contracts cannot bid, because they can block the auction with a reentrant attack
        require(!msg.sender.isContract(), "No script kiddies");

        // auction has to be opened
        require(auctions[tokenId].open, "No opened auction found");

        // approve was lost
        require(getApproved(tokenId) == address(this), "Cannot complete the auction");

        // Revert the call if the bidding
        // period has not started.
        require(
            now >= auctions[tokenId].auctionStart,
            "Auction not yet started."
        );

        // Revert the call if the bidding
        // period is over.
        require(
            now <= auctions[tokenId].auctionEnd,
            "Auction already ended."
        );

        // If the bid is not higher, send the
        // money back.
        require(
            price > auctions[tokenId].highestBid,
            "There already is a higher bid."
        );

        address owner = ownerOf(tokenId);
        require(msg.sender!=owner, "NFT: The owner cannot bid his own collectible");

        require(XLSR.allowance(msg.sender, address(this)) >= price, "Insuffucuent allowance");
        XLSR.transferFrom(msg.sender, address(this), price);

        // return the funds to the previous bidder, if there is one -- YYY
        if (auctions[tokenId].highestBid>0) {
            XLSR.transfer(auctions[tokenId].highestBidder, auctions[tokenId].highestBid);
            emit Refund(auctions[tokenId].highestBidder, auctions[tokenId].highestBid);
        }

        // now store the bid data
        auctions[tokenId].highestBidder = msg.sender;
        auctions[tokenId].highestBid = price;
        emit HighestBidIncreased(msg.sender, price, tokenId);
        return true;
    }

    // anyone can execute withdraw if auction is opened and
    // the bid time expired and the reserve was not met
    // or
    // the auction is openen but the contract is unable to transfer
    function canWithdraw(uint256 tokenId) public view returns (bool) {
        if (auctions[tokenId].open &&
            (
                (
                    now >= auctions[tokenId].auctionEnd &&
                    auctions[tokenId].highestBid<auctions[tokenId].reserve
                ) ||
                getApproved(tokenId) != address(this)
            )
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// Withdraw a bid when the auction is not finalized
    function withdraw(uint256 tokenId) public nonReentrant returns (bool) {

        require(canWithdraw(tokenId), "Conditions to withdraw are not met");

        // transfer funds to highest bidder always
        if (auctions[tokenId].highestBid > 0) {
            XLSR.transfer(auctions[tokenId].highestBidder, auctions[tokenId].highestBid);
        }

        // finalize the auction
        delete auctions[tokenId];

    }

    function canFinalize(uint256 tokenId) public view returns (bool) {
        if (auctions[tokenId].open &&
            now >= auctions[tokenId].auctionEnd &&
            auctions[tokenId].highestBid>=auctions[tokenId].reserve
        ) {
            return true;
        } else {
            return false;
        }
    }

    // implement the auctionFinalize including the NFT transfer logic
    function auctionFinalize(uint256 tokenId) public nonReentrant onlyAdmin returns(bool){

        require(auctions[tokenId].open, "NFT: There is no auction opened for this tokenId");
        require(now >= auctions[tokenId].auctionEnd, "Auction not yet ended.");
        require(auctions[tokenId].highestBid>=auctions[tokenId].reserve, "Auction has not reached its minimum reserve price.");

        // transfer the ownership of token to the highest bidder
        address highestBidder = auctions[tokenId].highestBidder;

        // calculate payment amounts
        uint256 amount4admin = auctions[tokenId].highestBid.mul(commissionRate).div(100);
        uint256 amount4owner = auctions[tokenId].highestBid.sub(amount4admin);

        // to owner
        XLSR.transfer(auctions[tokenId].beneficiary, amount4owner);
        // to admin
        XLSR.transfer(admin, amount4admin);

        emit Sale(tokenId, auctions[tokenId].beneficiary, highestBidder, auctions[tokenId].highestBid);
        emit Commission(tokenId, auctions[tokenId].beneficiary, auctions[tokenId].highestBid, commissionRate, amount4admin);

        emit AuctionEnded(auctions[tokenId].highestBidder, auctions[tokenId].highestBid);

        // transfer ownership
        address owner = ownerOf(tokenId);

        // we need to call a transferFrom from this contract, which is the one with permission to sell the NFT
        // transfer the NFT to the auction's highest bidder
        callOptionalReturn(this, abi.encodeWithSelector(this.transferFrom.selector, owner, highestBidder, tokenId));

        soldFor[tokenId] = auctions[tokenId].highestBid;

        // finalize the auction
        delete auctions[tokenId];
        return true;
    }

    // Bid query functions
    function highestBidder(uint256 tokenId) public view returns (address) {
        return auctions[tokenId].highestBidder;
    }

    function highestBid(uint256 tokenId) public view returns (uint256) {
        return auctions[tokenId].highestBid;
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC721 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC721: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC721: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC721: ERC20 operation did not succeed");
        }
    }

    // update contract fields
    function updateAdmin(address _admin) onlyAdmin external returns(bool) {
        admin=_admin;
        return true;
    }

    // update contract fields
    function updateCommissionRate(uint256 _commissionRate)  onlyAdmin external returns (bool){
        commissionRate=_commissionRate;
        return true;
    }

    // update contract fields
    function updateAnyOneCanMint(bool _anyoneCanMint) onlyAdmin external returns(bool) {
        anyoneCanMint=_anyoneCanMint;
        return true;
    }

    function removeAuction(uint256 tokenId) external onlyAdmin returns(bool success){

        // auction has to be opened
        require(auctions[tokenId].open, "No opened auction found");

        // return the funds to the previous bidder, if there is one
        if (auctions[tokenId].highestBid>0) {
            XLSR.transfer(auctions[tokenId].highestBidder, auctions[tokenId].highestBid);
            emit Refund(auctions[tokenId].highestBidder, auctions[tokenId].highestBid);
        }

        // finalize the auction
        delete auctions[tokenId];
        emit AuctionClosed(tokenId);

        return true;
    }

    function removeSell(uint256 tokenId) external onlyAdmin returns(bool success){
        // is on sale
        require(!auctions[tokenId].open && sellBidPrice[tokenId]>0, "NFT: The collectible is not for sale");
        // close the sell
        sellBidPrice[tokenId] = 0;
        _wallets[tokenId] = address(0);

        emit SaleClosed(tokenId);
        return true;
    }

}