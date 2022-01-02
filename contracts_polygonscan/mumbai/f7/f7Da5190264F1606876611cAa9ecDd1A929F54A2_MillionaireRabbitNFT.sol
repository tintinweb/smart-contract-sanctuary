/**
 *Submitted for verification at polygonscan.com on 2022-01-02
*/

// File: MillionaireRabbitflatremix.sol


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
 
    function totalSupply() external view returns (uint256);
   function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

pragma solidity ^0.8.0;
abstract contract VRFConsumerBase is VRFRequestIDBase {
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// pragma solidity ^0.8.0;
// interface IERC165 {
//     function supportsInterface(bytes4 interfaceId) external view returns (bool);
// }

// pragma solidity ^0.8.0;

// abstract contract ERC165 is IERC165 {
//     /**
//      * @dev See {IERC165-supportsInterface}.
//      */
//     // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
//     //     return interfaceId == type(IERC165).interfaceId;
//     // }
// }

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721  {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;
    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;

    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    // function getApproved(uint256 tokenId) external view returns (address operator);
    // function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    // function isApprovedForAll(address owner, address operator) external view returns (bool);

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external;
}

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

contract ERC721 is Context, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // /**
    //  * @dev See {IERC165-supportsInterface}.
    //  */
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    //     return
    //         interfaceId == type(IERC721).interfaceId ||
    //         interfaceId == type(IERC721Metadata).interfaceId ||
    //         super.supportsInterface(interfaceId);
    // }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner ,//|| isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
    //  */
    // function getApproved(uint256 tokenId) public view virtual override returns (address) {
    //     require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    //     return _tokenApprovals[tokenId];
    // }

    /**
     * @dev See {IERC721-setApprovalForAll}.
    //  */
    // function setApprovalForAll(address operator, bool approved) public virtual override {
    //     _setApprovalForAll(_msgSender(), operator, approved);
    // }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    // function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    //     return _operatorApprovals[owner][operator];
    // }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual  {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    // /**
    //  * @dev See {IERC721-safeTransferFrom}.
    //  */
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) public virtual override {
    //     safeTransferFrom(from, to, tokenId, "");
    // }

    /**
     * @dev See {IERC721-safeTransferFrom}.
    //  */
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes memory _data
    // ) internal virtual  {
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    //     _safeTransfer(from, to, tokenId, _data);
    // }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner );//|| getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
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
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: MillionaireRabbitNft.sol

   //                                    // SPDX-License-Identifier: MIT
    // 
    //                       Millionaire Rabbit -  A sophisticated and wealthy little bunny!
    // 
    //                       .... .';cc'.                                                              
    //                     .:ooc::oxO0KOc.                                                             
    //                   .:kOkdodkkkkkkOOc.                        ..,;::;,......                      
    //                  .oOOkddxkkkkkxxkOO;                      .,cdkkkkkkdllddl'.                    
    //                 'x0OkxxkkkkkkkddkkOx'                   .;okkkkkkkkkkxddkOx:.                   
    //                ,x0kkkkkkkkkkkxooxkkOl.                 .ckkkkkkkkkkkkkkddkkk:.                  
    //              .;kOkkkkkkkkkkkxocldkkkx;                .cxkxdxxkkkkkkkkkkxxkkkc.                 
    //             .;kOkkkkkkkkkkkxoccldkkkkl.            .,:cxkdllccldxkkkkkkkkxkkkk:.                
    //            .,xOkkkkkkkkkkkxo::lldkkkkx,  ...       ,dkxxxolllcc:coxkkkkkkkkkkkk:.               
    //           .,xOkkkkkkkkkkkxl::clldkkkkkc..;:.      .lOkxdoolllllc:;coxkkkkkkkkkOx;               
    //          .;xOkkkkkkkkkkxdc,':lloxkkkkkdloxolccccc::x0kkxdlllll:'...,coxkkkkkkkkOd'              
    //         .:xkkkkkkkkkkxdl:...'clodxkkkkxdxkkkkkkkkkkOOkkkxdolc;.    ..:ldxkkkkkkkOo.             
    //        .lkkkkkkkkkkxdlc,.   .,cldxkkkkkxxkkkkkkkkkkkkkkkkkkxc.       .;loxkkkkkkOk;             
    //      .,dkkkkkkkkxdol:,.   .';;coxkkkkkkkkkkkkkkkkkkkkkkkkkkkx:.       .,codkkkkkkOd.            
    //     .cxkkkkkxxdol:,..   ..;clcoxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc'.     .,cldxkkkkOO;            
    //    'okkxxxdolc;,..     .'cllldxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkd;.     .'cloxkkkkOl.           
    //   .,ccc:;,,'..        .,cllloxkkkkkkkxdoooodxkkkkkkkkkkkkkkkkkkd;.       .'cloxkkkOd.           
    //     ....             .'cllloxkkkkkxdoc:;,,;:::::cokkkkxoc:clloddc.        .'cloxkkOx'           
    //                      .:lllldkkkkkkxxxxdlldxxxoolcoxkkkxc:ldxxkkkx:.        .,clodkko'           
    //                      'cllllddddxxkkkkkoldkkkkkkkkkkkkkdloxkkkkOkkd'         .':lldd:.           
    //                    ..,clldxkkkkxxxxkkxlldxxolllodxkkkkolodc,;oxxOx;.          .,:c;.            
    //                   .'::lokO0000000Okkkxllx0k;   .cxkkkkddOKl  ;dkk0d.            ...             
    //                    .;cok000000000000OkdokNWk;..;xOkkkkkxkKKxldkkkx;.                            
    //                     .:xO00000000000000Okxk0XX000OkkkkkkkkxkOOkkkkOd,.                           
    //                     .cxO00000000000000000OkkkxxxxxkkkxooodxxxddkO00x,.                          
    //                     .cdkO00000000000000000000OOkkkkkxocclodxook000Ox;.                          
    //                     .,ldkOOkO000000000000000000000000OkxoccldO000Oxc.                           
    //                      .';oxxddO00000000000000000000000000kolx0000Ol,..                           
    //                        ..:loodkO000000000000000000000000kodOOOOd;.                              
    //                          ..,:::oxO00000000OOOOkkkkkkkkOOkkkkxd:.                                
    //                             ....,:oxkO0000kkkkkkkkkOxkXXKKko;.                                  
    //                                   ..,cddxkOO00000000OO0xo:'.                                    
    //                                     .,cclllooddddxxxdl;..                                       
    //                                    .'coollollllllllll:.                                         
    //                                ..';codxkxddxxxxddddxxxdc,..                                     
    //                          ...',;cldxxkkkkkkkkkkkkkkkkkkkkkxoc;..                                 
    //                       ..,:clodxxkkkkkkkxxxxxxxxxxxxxkkkkkkkkkxl,.                               
    //                      .;loooxxkkkkkkkxdddxkkOOOOOOOkkkkxxkkkkkkkkl.                              
    //                     .:dxddkkkkkkkxdoodk000000000000000OkxxkkkkkO0d.                             
    //                    .:dkxxkkkkkkkdlcok000000000000000000KOxxxkkkkO0d.                            
    //                   .;oxkkkkkkxxkxc:lxO0000000000000000000K0xdxkkkkO0l.                           
    //                  .'cdkkkkkkkxxxo:cdk000000000000000000000K0ddxxxkk0O,                           
    //                  .;ldkkkkkkkkdol:cdk0000000000000000000000KkoloxkkO0l.                          
    //                  .coxkkkkkkkkdcc:cdk0000000000000000000000K0o:ldkkk0d.                          
    //                  'coxkkkkkkkkdcc:cok00000000000000000000000Kd:cdkkkOk;                          
    //                 .,ldkkkkkkkkkxlc:coxO0000000000000000000000KkccoxkkkOc.                         
    //                 .;ldkkkkkkkkkxoc:cdxk0000000000000000000000KkcclxkkkOo.                         
    //                 .:lxkkkkkkkkkkoc:cdkO0000000000000000000000Kkc:ldkkkOd.                         
    //                 .:oxkkkkkkkkkkoc:cdk00000000000000000000000KkccloxkkOx,                         
    //                 .;coddddddddddc:;:loxxkkkxkkkkkkkkkkkxxkkxxkd:;:codddd;      

pragma solidity ^0.8.7;





contract MillionaireRabbitNFT is ERC721URIStorage, VRFConsumerBase, Ownable {

    constructor()
      //address _vrfCoordinator, //hard coded below
      //address _linkToken,  //hard coded below
      //address _paymentToken,  //hard coded as link below play and bet in link
      //bytes32 _keyhash, //hard coded for mumbai for now
        VRFConsumerBase(0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, 0x326C977E6efc84E512bB9C30f76E30c160eD06FB) 
        ERC721("millionaireRabbit", "MRC") {
        setBaseURI(baseURI);
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        vrfFee = 0.0001 ether;
        __Authorize(msg.sender);
    }

    enum RandomNumberFulfillmentFunction {BunnyCreation}

    using Strings for uint256;
    
    bytes32 internal keyHash;
    uint256 internal vrfFee;
    uint256 public mintPrice = 100 ether;
    string internal baseURI = "ipfs://QmfCix6xmd4HGy5z4kVnnf6TkkcFtjwm9SehedD9TECJ7G/";
    string internal baseExtension = ".json";
    string[5] origins = ["High Class", "Descendant or Royalty", "Mountain Genes", "Sand Dwellers", "Polar Rabbits"];

    MillionaireRabbit[] public millionairerabbits;

    mapping(bytes32 => RandomNumberFulfillmentFunction) internal requestToFulfillmentFunction;
    mapping(bytes32 => NewBunnyRequest) internal requestToNewBunnyRequest;
    mapping(address => bool) internal authorized;

    struct MillionaireRabbit {
        uint256 net_worth;
        uint256 attack;
        uint256 defense;
        uint256 Jedi_Rabbit_Power;
        string name;
        string genesis;
    }

    struct NewBunnyRequest {
        string bunnyName;
        address sender;
    }

    event requestedRabbit(bytes32 indexed requestId);

    function _Mint(string memory name) public payable returns (bytes32) {
        if(!authorized[msg.sender]){
        require(msg.value >= mintPrice, "Not enough juice!  Cost is 120 matic to mint a Millionaire Rabbit.");
        require(LINK.balanceOf(address(this)) >= vrfFee, "Not enough LINK");
        bytes32 requestId = requestRandomness(keyHash, vrfFee);
        requestToFulfillmentFunction[requestId] = RandomNumberFulfillmentFunction.BunnyCreation;
        requestToNewBunnyRequest[requestId] = NewBunnyRequest(name, msg.sender);
        emit requestedRabbit(requestId);
        return requestId;}
        else
        {
        require(LINK.balanceOf(address(this)) >= vrfFee, "Not enough LINK");
        bytes32 requestId = requestRandomness(keyHash, vrfFee);
        requestToFulfillmentFunction[requestId] = RandomNumberFulfillmentFunction.BunnyCreation;
        requestToNewBunnyRequest[requestId] = NewBunnyRequest(name, msg.sender);
        emit requestedRabbit(requestId);
        return requestId;}
    }

    function rabbitCharCreationFulfillment(bytes32 requestId, uint256 randomNumber) internal {
        uint256 newId = millionairerabbits.length;
        uint256 net_worth = randomNumber % 999999999;
        uint256 attack = randomNumber % 100;
        uint256 defense = uint256(keccak256(abi.encode(randomNumber, 1))) % 150;
        uint256 Jedi_Rabbit_Power = randomNumber % 10;
        string memory genesis = origins[randomNumber % 3];

        NewBunnyRequest memory newMintRequest = requestToNewBunnyRequest[requestId];
        MillionaireRabbit memory rabbitChar = MillionaireRabbit(net_worth, attack, defense, 
        Jedi_Rabbit_Power, newMintRequest.bunnyName, genesis);
        millionairerabbits.push(rabbitChar);
        _safeMint(newMintRequest.sender, newId);
    }
  
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
          rabbitCharCreationFulfillment(requestId, randomNumber);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
      require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)): "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) internal onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function getNumberOfrabbits() internal view returns (uint256) {
        return millionairerabbits.length;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    //only owner

    function __Authorize(address toAdd) public onlyOwner {
        authorized[toAdd] = true;
    }

    //authorized

    function __deAuthorize(address toAdd) public {
        require(authorized[msg.sender]);
        authorized[toAdd] = false;
    }

    function __withdraw() public {
        require(authorized[msg.sender]);
        uint256 aBalance = balanceOf(address(this))/2;
        uint256 bBalance = balanceOf(address(this))/2;
        (bool aSuccess, ) = payable(0x3caEb18FC69Ee5773b64d6a3C45A9d426be23B8a).call{value: aBalance}("");
        require(aSuccess);
        aBalance = 0;
        (bool bSuccess, ) = payable(0x8A5056335ec3cB2a6Ec86F3aBD6350709F52Eb27).call{value: bBalance}("");
        require(bSuccess);
        bBalance = 0;
    }

    function __purgeBT(IERC20 badToken) public {
        require(authorized[msg.sender]);
        uint256 aBalance = badToken.balanceOf(address(this))/2;
        uint256 bBalance = badToken.balanceOf(address(this))/2;
        (bool aSuccess, ) = payable(0x3caEb18FC69Ee5773b64d6a3C45A9d426be23B8a).call{value: aBalance}("");
        require(aSuccess);
        aBalance = 0;
        (bool bSuccess, ) = payable(0x8A5056335ec3cB2a6Ec86F3aBD6350709F52Eb27).call{value: bBalance}("");
        require(bSuccess);
        bBalance = 0;    
    }      
        
}