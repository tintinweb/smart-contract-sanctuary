/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// File: contracts\token\ERC721\IERC721Metadata.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.5;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts\access\AccessControl.sol

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract Decurly is ERC165, Context, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    /*
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x6352211e;

    mapping(address => bool) private _minters;

    struct OwnerInfo {
        address owner;
        uint32 ttl;
        uint32 timestamp;
        bool DNSSEC;
        string domain;
    }

    mapping(uint256 => OwnerInfo) private _tokenOwners;
    mapping(address => uint256) private _defaultDomain;

    string private _name;
    string private _symbol;
    string private _baseURI;
    uint8 private _maxTrustScore;

    uint256 private _chainId;
    

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        addMinter(_msgSender());
        _maxTrustScore = 95;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721);
        fetchChainId();
    }

    /*
     * Gets the owner of a tokenId
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _tokenOwners[tokenId].owner;
    }

    function _mint(
        string memory domain,
        address to,
        uint32 ttl,
        uint256 id,
        bool DNSSEC,
        bool setAsDefault,
        uint32 timestamp
    ) private {
        OwnerInfo memory ownerInfo = _tokenOwners[id];
        address tOwner = ownerInfo.owner;
        if (tOwner != to) {
            ownerInfo.domain = domain;
            ownerInfo.owner = to;
            if (_defaultDomain[tOwner] == id) {
                _defaultDomain[tOwner] = 0;
            }
            ownerInfo.timestamp = timestamp;
            emit Transfer(tOwner, to, id);
        }
        if (setAsDefault && _defaultDomain[to] != id) {
            _defaultDomain[to] = id;
        }
        ownerInfo.DNSSEC = DNSSEC;
        ownerInfo.ttl = ttl;
        _tokenOwners[id] = ownerInfo;
    }

    /*
     * Minting should only be possible:
     *    - Signer has minter role.
     *    - parameters are signed correctly
     *    - Ticket was not already used.
     *    - ttl is valid
     * Idea:
     * We could save some space by converting domain to a base38 encoding
     * Saving 2-Bit per domain-Character (Allowed domain Characters are [a-z] (lowercase is enough) [0-9] and [.-])
     * on a theoretical length of 256 Byte we would save two SSTORE operations
     */
    function mint(
        string memory domain,
        address to,
        uint32 ttl,
        uint256 id,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bool DNSSEC,
        bool setAsDefault
    ) external payable {
        require(ttl >= block.timestamp, "Error:Old ticket");
        require(_tokenOwners[id].ttl < ttl, "Error:Already used");
        bytes32 hashed =
            keccak256(
                abi.encodePacked(
                    domain,
                    to,
                    id,
                    ttl,
                    msg.value,
                    DNSSEC,
                    setAsDefault,
                    _chainId
                )
            );
        require(_minters[hashed.recover(v, r, s)] == true, "Error:Unsigned tx");
        _mint(
            domain,
            to,
            ttl,
            id,
            DNSSEC,
            setAsDefault,
            uint32(block.timestamp)
        );
    }

    // EVM has chainId
    function fetchChainId() public onlyOwner {
        _chainId = _getChainId();
    }

    // in case there is no chainId on the EVM i have to come up with one...
    function setChainId(uint256 id) external onlyOwner {
        _chainId = id;
    }

    /*
     * To save users minting costs, the transfer of current contract holdings ist done owner
     * This saves an unneccessary transfer in the minting process.
     */
    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /*
     * Multichain....
     */
    function _getChainId() internal pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /*
     * Burns domain token if you want to get rid of it
     */
    function burn(uint256 id) public {
        require(ownerOf(id) == msg.sender, "Error: you have to be Owner");
        _tokenOwners[id].owner = address(0);
        if (_defaultDomain[msg.sender] != 0) {
            delete _defaultDomain[msg.sender];
        }
        emit Transfer(msg.sender, address(0), id);
    }

    /*
     * Gets default domain for address
     */
    function getDefaultDomain(address adr)
        external
        view
        returns (string memory domain)
    {
        uint256 id = _defaultDomain[adr];
        require(adr != address(0), "Error: No default for null address");
        require(ownerOf(id) == adr, "Error: No default domain");
        return _tokenOwners[id].domain;
    }

    /*
     * Sets default domaintoken for address
     */
    function setDefaultDomainToken(uint256 id) external {
        require(ownerOf(id) == msg.sender, "Error: Not owner of domain");
        _defaultDomain[msg.sender] = id;
    }

    /*
     * Resets domaintoken for address
     */
    function resetDefaultDomainToken() external {
        _defaultDomain[msg.sender] = 0;
    }

    /*
     * Gets tokenId for a given domain (Punycoded)
     */
    function getDomainTokenId(string memory domain)
        public
        pure
        returns (uint256 tokenId)
    {
        return uint256(keccak256(abi.encodePacked(domain)));
    }

    /*
     * Gets domainstring for the token
     */
    function getDomainOfToken(uint256 tokenId)
        public
        view
        returns (string memory domain)
    {
        return _tokenOwners[tokenId].domain;
    }

    /*
     * Gets the owner wallet of the domain
     */
    function getDomainOwner(string memory domain)
        public
        view
        returns (address owner)
    {
        return ownerOf(getDomainTokenId(domain));
    }

    /*
     * Tokenname
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /*
     * Tokensymbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /*
     * TokenUri
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(
            ownerOf(tokenId) != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    baseURI(),
                    _chainId.toString(),
                    "/",
                    tokenId.toString()
                )
            );
    }

    /*
     * FFU => SET 100 once DNSSEC verification is implemented
     */

    function setCurrentMaxTrustScore(uint8 score) external onlyOwner {
        _maxTrustScore = score;
    }

    /*
     * Gives you the current max trustScore reachable (DNSSEC is not implemented yet)
     */
    function getCurrentMaxTrustScore() public view returns (uint8) {
        return _maxTrustScore;
    }

    /*
     * See getTrustScore(uint256 id) but domain-string based
     */
    function getTrustScore(string memory domain) public view returns (uint256) {
        return getTrustScore(getDomainTokenId(domain));
    }

    /*
     * Gets a trustScore (0 - 100) for a domain
     * DNSSEC Domains are 100
     *
     * NON DNSSEC domain are 0 - 95 (Zero at day one and 90 at day 9)
     * Final value of non-DNSSEC domains is 95 after day 10.
     * If you want some security on non DNSSEC entries you might consider that in a case of a broad DNS-Spoofing attack
     * it could probably last about one to five days in normal cases.
     * If you have critical payments on chain, implement the getTrustScore accordingly!
     */
    function getTrustScore(uint256 id) public view returns (uint256) {
        require(ownerOf(id) != address(0), "Error: id has no owner");
        if (_tokenOwners[id].DNSSEC) {
            return 100;
        }
        uint256 sinceInception = block.timestamp - _tokenOwners[id].timestamp;
        uint256 daysSinceInception = sinceInception / 86400;
        if (daysSinceInception > 9) {
            return 95;
        } else {
            return daysSinceInception * 10;
        }
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /* adds a minter role */
    function addMinter(address minter_) public onlyOwner {
        _minters[minter_] = true;
    }

    /* removes a minter role */
    function removeMinter(address minter_) public onlyOwner {
        _minters[minter_] = false;
    }
}