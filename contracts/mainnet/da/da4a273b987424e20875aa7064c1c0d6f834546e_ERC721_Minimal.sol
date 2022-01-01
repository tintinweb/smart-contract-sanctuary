/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/TheNothingERC721/MinimalERC721_V4_worm.sol

pragma solidity ^0.8.10;
library Strings { //from OpenZeppelin v4.4.1
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

interface IERC721Receiver {
    /// returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

interface ITokenURICustom {
    // Implementation of a custom tokenURI
    function constructTokenURI(uint256 tokenId) external pure returns (string memory);
}

contract ERC721_Minimal is Ownable{
    using Strings for uint256;

    //Events ERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    //max supply before minting is disabled
    //uint256 MAX_SUPPLY = type(uint160).max;

    address burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // string private baseURI;

    // Optional mapping for token URIs
    // mapping(uint256 => string) private _tokenURIs;

    address private _customURI;
    bool public finalised;

    // Mapping from token ID to owner address
    address[] private _owners;

    uint256 public supplyCounter;

    // Mapping owner address to token owner flag
    mapping(address => bool) private _isOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ERC-2981: NFT Royalty Standard
    address payable private _royaltyRecipient;
    uint256 private _royaltyBps;


    constructor(string memory name_, string memory symbol_, address contractURI) {
        _name = name_;
        _symbol = symbol_;
        //_setBaseURI(baseURI_);

        _customURI = contractURI;

        _royaltyRecipient = payable(msg.sender);
        _royaltyBps = 1000;

        _mint(msg.sender, supplyCounter);
        supplyCounter+=1;
        
    }

    function setCustomURI(address contractURI) public onlyOwner {
        require(finalised == false, "Uri finalised");
        _customURI = contractURI;
    }

    function setFinalised() public onlyOwner {
        finalised = true;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        // return interfaceId == type(IERC165).interfaceId;
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x2a55205a;
        //ERC721 = 0x80ac58cd
        //ERC721 metadata = 0x5b5e139f
        //ERC721 enumerabe = 0x780e9d63
        //ERC721 receiver = 0x150b7a02
        //ERC165 = 0x01ffc9a7b
        //_INTERFACE_ID_ERC2981 = 0x2a55205a;
    }

    function totalSupply() public view returns (uint256) 
    {   
        return supplyCounter;
    }

    function balanceOf(address owner) public view  returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        if(_isOwner[owner]) {
            return 1;
        }
        else {
            return 0;
        }

    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(_customURI != address(0)) {
            return ITokenURICustom(_customURI).constructTokenURI(tokenId);
        }
        else {
            // string memory bURI = baseURI;
            // return bytes(bURI).length > 0 ? string(abi.encodePacked(bURI, tokenId.toString())) : "";
            return "Missing URI";
         }
    }

    // function _setBaseURI(string memory baseURI_) internal {
    //     baseURI = baseURI_;
    // }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
 
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public  {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        
        _owners.push(to);

        _isOwner[to] = true;

        emit Transfer(address(0), to, tokenId);

    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _isOwner[owner] = false;

        
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);

    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_isOwner[to], "ERC721: Only one token per wallet allowed");




        if(balanceOf(burnAddress) > 0 || to == burnAddress) {
            // Clear approvals from the previous owner
            _approve(address(0), tokenId);

            _owners[tokenId] = to;

            _isOwner[to] = true;
            _isOwner[from] = false;

            emit Transfer(from, to, tokenId);
        }
        else {
            _mint(to, supplyCounter);
            supplyCounter+=1;
            
        }

    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


    //EIP-2981 Royalty Standard
    function setRoyaltyPercentageBasisPoints(uint256 royaltyPercentageBasisPoints) public onlyOwner {
        _royaltyBps = royaltyPercentageBasisPoints;
    }

    function setRoyaltyReceipientAddress(address payable royaltyReceipientAddress) public onlyOwner {
        _royaltyRecipient = royaltyReceipientAddress;
    }

    
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 royalty = (salePrice * _royaltyBps) / 10000;
        return (_royaltyRecipient, royalty);
    }




}