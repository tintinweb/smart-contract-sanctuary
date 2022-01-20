// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/Ownable.sol";
import "./erc/721/ERC721.sol";
import "./utils/Counters.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//     _______     _______.  ______     ___      .______    _______ .______    __          ___      .__   __.     //
//    |   ____|   /       | /      |   /   \     |   _  \  |_______||   _  \  |  |        /   \     |  \ |  |     //
//    |  |__     |   (----`|  ,----'  /  ^  \    |  |_)  |  _______ |  |_)  | |  |       /  ^  \    |   \|  |     //
//    |   __|     \   \    |  |      /  /_\  \   |   ___/  |_______||   ___/  |  |      /  /_\  \   |  . `  |     //
//    |  |____.----)   |   |  `----./  _____  \  |  |       _______ |  |      |  `----./  _____  \  |  |\   |     //
//    |_______|_______/     \______/__/     \__\ | _|      |_______|| _|      |_______/__/     \__\ |__| \__|     //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @title Escape Plan artist smart contract
 */
contract EscapePlan is ERC721, Ownable {
    receive() external payable {}
    fallback() external payable {}

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 private _platinumIdCounter = 0;
    uint256 private _goldIdCounter = 0;
    uint256 private _bronzeIdCounter = 0;

    event Withdrawal(address caller, address account, uint256 amount);
    event Mint(address account, uint256 tokenId, string cid);

    constructor() ERC721("Escape Plan", "ESC") {
    }

    function withdraw(address account) public onlyOwner {
        (bool success, ) = payable(account).call{value: address(this).balance}("");
        require(success, "EscapePlan: ether transfer failed");

        emit Withdrawal(msg.sender, account, address(this).balance);
    }

    function _routeMint(address account, string memory cid, uint256 percent) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(account, tokenId);
        _setTokenCID(tokenId, cid);
        _tokenIdCounter.increment();
        if (percent != 0) {
            _setTokenRoyalty(tokenId, account, percent);
        } else {
            _setTokenRoyalty(tokenId, account, 0);
        }

        emit Mint(account, tokenId, cid);
    }

    function customMint(address account, string memory cid, uint256 percent) public onlyOwner {
        _routeMint(account, cid, percent);
    }

    function platinumMint(address account) public onlyOwner {
        require(_platinumIdCounter <= 10, "EscapePlan: exceeds token supply");
        _routeMint(account, "QmZAgEWMFuaMDzM1FbmKTbtGiQt2MKVsTYPcZ8p6Xq6ReQ", 10);
        _platinumIdCounter += 1;
    }

    function goldMint(address account) public onlyOwner {
        require(_goldIdCounter <= 10, "EscapePlan: exceeds token supply");
        _routeMint(account, "QmbL82Q4n3aknueHibMS6hBvJThfAtmKrHw6BfoWnscrm6", 10);
        _goldIdCounter += 1;
    }

    function bronzeMint(address account) public onlyOwner {
        require(_bronzeIdCounter <= 10, "EscapePlan: exceeds token supply");
        _routeMint(account, "QmQbG4iyqopwo6Uv7CpzRPALewAvpC6jPBSk2T2wUXdNgB", 10);
        _bronzeIdCounter += 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module for single ownership
 */
abstract contract Ownable {
    /**
     * @dev Ownable events
     */

    // Event for ownership transfer
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Ownable definitions
     */
    
    // Owner address
    address private _owner;

    /**
     * @dev Prevents function called by non-owner from executing
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Ownable public functions
     */
    
    // Returns the owner address of the contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Transfers ownership of the contract to `newOwner`
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    // Leaves the contract without an owner
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Ownable event emitting interal functions
     */

    // Emits {OwnershipTransferred} event and transfers ownership of the contract to `newOwner`
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./extensions/IERC721Enumerable.sol";
import "./extensions/IERC721Metadata.sol";
import "./receiver/IERC721Receiver.sol";
import "../165/ERC165.sol";
import "../2981/IERC2981.sol";
import "../../utils/Address.sol";
import "../../utils/Strings.sol";

/**
 * @dev Implementation of the IERC721, IERC721Enumerable, and IERC721Metadata interfaces
 */
contract ERC721 is ERC165, IERC721, IERC721Enumerable, IERC721Metadata, IERC2981 {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev ERC721 and ERC721Metadata definitions
     */
    // Maps token ID to owner account
    mapping(uint256 => address) private _owners;

    // Maps owner account to token count
    mapping(address => uint256) private _balances;

    // Maps token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Maps owner account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Maps token ID to token CID
    mapping(uint256 => string) private _tokenCIDs;

    /**
     * @dev ERC721Enumerable definitions
     */

    // Maps owner account to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Maps token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token IDs used for enumeration
    uint256[] private _allTokens;

    // Maps token ID to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev ERC2981 definitions
     */
    
    // Royalty info structure
    struct RoyaltyInfo {
        address receiver;
        uint256 percent;
    }

    // Maps token ID to royalty info structure
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev Sets the token {name} and {symbol}
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev ERC721 and ERC721Metadata public functions
     */

    // Returns the amount of tokens owned by `account`
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _balances[owner];
    }

    // Returns the owner of the `tokenId` token
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    // Safely transfers `tokenId` token from `from` to `to`
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // Safely transfers `tokenId` token from `from` to `to` with additional `data` parameter
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner or approved");

        _safeTransfer(from, to, tokenId, _data);
    }

    // Transfers `tokenId` token from `from` to `to`
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner or approved");

        _transfer(from, to, tokenId);
    }

    // Gives permission to `to` to transfer `tokenId` token
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner or approved for all"
        );

        _approve(to, tokenId);
    }

    // Approve or remove `operator` as an operator for the caller
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    // Returns the account approved for `tokenId` token
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    // Returns if the `operator` is allowed to manage all of the assets of `owner`
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Returns the {name} of the token
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // Returns the {symbol} of the token
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // Returns the Uniform Resource Identifier for `tokenId` token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenCID = _tokenCIDs[tokenId];

        return string(abi.encodePacked(baseURI(), _tokenCID));
    }

    /**
     * @dev ERC721Enumerable public functions
     */

    // Returns the total amount of tokens stored by the contract
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    // Returns a token ID at a given `index` of all the tokens stored by the contract
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    // Returns a token ID owned by `owner` at a given `index` of its token list
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev ERC721Enumerable private functions
     */
    
    // Adds a token to ownership-tracking data structures
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    // Adds a token to tracking data structures
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    // Removes a token from ownership-tracking data structures
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    // Removes a token from tracking data structures
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev ERC721 public function that burns `tokenId`
     */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not owner or approved");

        _burn(tokenId);
    }

    /**
     * @dev ERC2981 public functions
     */

    // Returns royalty amount for `tokenId`
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];
        uint256 royaltyAmount;

        if (royalty.percent == 0) {
            royaltyAmount = 0;
        } else {
            royaltyAmount = (_salePrice * royalty.percent) / 100;
        }

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev ERC2981 internal functions
     */

    // Sets royalty amount for `tokenId`
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint256 percent) internal virtual {
        require(percent <= 100, "ERC2981: royalty fee will exceed sale price");
        require(receiver != address(0), "ERC2981: royalty to the zero address");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, percent);
    }

    /**
     * @dev ERC721 and ERC721Metadata interal functions
     */
    
    // Internally safely mints `tokenId` and transfers it to `to`
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    // Internally safely mints `tokenId` and transfers it to `to` with additional `data` parameter
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    // Internally returns whether `tokenId` exists
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Internally returns whether `spender` is allowed to manage `tokenId`
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Internally safely transfers `tokenId` token from `from` to `to`
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // Internally returns base URI for computing token CIDs
    function baseURI() internal view virtual returns (string memory) {
        return "ipfs://";
    }

    // Internally sets `_tokenCID` as the token CID of `tokenId` token
    function _setTokenCID(uint256 tokenId, string memory _tokenCID) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        _tokenCIDs[tokenId] = _tokenCID;
    }

    /**
     * @dev ERC721 private functions
     */

    // Invokes {IERC721Receiver-onERC721Received} on a target address
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {revert(add(32, reason), mload(reason))}
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev ERC721 event emitting interal functions
     */

    // Emits {Transfer} event and transfers token to `to`
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // Emits {Transfer} event and burns token
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // Emits {Transfer} event and adjusts balances
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // Emits {Approval} event and sets approved account
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    // Emits {ApprovalForAll} event and sets approved account
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is interally called before any token transfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides counters that can only be incremented decremented or reset
 */
library Counters {
    struct Counter {uint256 _value;}

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {counter._value += 1;}
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {counter._value = value - 1;}
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../165/IERC165.sol";

/**
 * @dev Interface of the ERC721 standard as defined in the EIP
 */
interface IERC721 is IERC165 {
    /**
     * @dev ERC721 standard events
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev ERC721 standard functions
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @dev Interface for ERC721Enumerable as defined in the EIP-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev ERC721 token enumeration functions
     */
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @dev Interface for ERC721Metadata as defined in the EIP-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev ERC721 token metadata functions
     */
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for ERC721TokenReceiver as defined in EIP-721
 */
interface IERC721Receiver {
    /**
     * @dev ERC721TokenReceiver standard functions
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the IERC165 interface
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../721/IERC721.sol";

/**
 * @dev Interface for ERC2981 as defined in EIP-2981
 */
interface IERC2981 is IERC721 {
    /**
     * @dev ERC2891 standard functions
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard as defined in the EIP
 */
interface IERC165 {
    /**
     * @dev ERC165 standard functions
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}