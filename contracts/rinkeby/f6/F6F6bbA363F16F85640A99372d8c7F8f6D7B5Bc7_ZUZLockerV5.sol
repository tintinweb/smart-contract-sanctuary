// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// pragma solidity ^0.4.25;
pragma solidity 0.8.2;

import "@openzeppelin/[email protected]/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/[email protected]/token/ERC1155/utils/ERC1155Holder.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender, address recipient, uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(
        address from, address to, uint256 tokenId
    ) external;
}

interface IERC1155 {
    function safeTransferFrom(
        address from, address to, uint256 id, uint256 amount, bytes calldata data
    ) external;
}


contract owned {
        address public owner;

        constructor() {
            owner = msg.sender;
        }

        function transferOwnership(address newOwner)  public {
            require(msg.sender == owner, "Only Owner can transfer ownership");
            owner = newOwner;
        }
}

contract ZUZLockerV5 is owned, ERC721Holder, ERC1155Holder {
    
    struct TokenInfo {
        address tokenAddress;
        address tokenOwner;
        uint tokenType;
        bool isLiquidityToken;
        uint tokenId;
        uint tokenAmount;
        uint lockTime;
        uint unlockTime;
        bool withdrawn;
    }
    
    uint256 public lastDepositId;
    mapping (uint256 => TokenInfo) public TokenInfoTable;
    mapping (address => uint[]) public depositsByCurrentUser;
    mapping (address => mapping(address => uint)) public totalTokensLockedByUser;
    
    
    function lockTokens(address _tokenAddress, uint _tokenType, bool _isLiquidityToken, uint _tokenId, uint256 _tokenAmount, uint _unlockTime) public {
        uint fiftyYears = block.timestamp + 1576800000;
        require(_unlockTime < fiftyYears, 'Maximum lock period is 50 years');
        
        if(_tokenType == 1) {
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        }
        else if(_tokenType == 2) {
            IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        }
        else if(_tokenType == 3) {
             IERC1155(_tokenAddress).safeTransferFrom(
                msg.sender, address(this), _tokenId, _tokenAmount, '0x'
            );
        }
        else {
            require(false, "_tokenType is not supported");
        }
        totalTokensLockedByUser[msg.sender][_tokenAddress] += _tokenAmount;
        
        uint _id = ++lastDepositId;
        TokenInfoTable[_id].tokenAddress = _tokenAddress;
        TokenInfoTable[_id].tokenOwner = msg.sender;
        TokenInfoTable[_id].tokenType = _tokenType;
        TokenInfoTable[_id].isLiquidityToken = _isLiquidityToken;
        TokenInfoTable[_id].tokenId = _tokenId;
        TokenInfoTable[_id].tokenAmount = _tokenAmount;
        TokenInfoTable[_id].lockTime = block.timestamp;
        TokenInfoTable[_id].unlockTime = _unlockTime;
        TokenInfoTable[_id].withdrawn = false;
        
        depositsByCurrentUser[msg.sender].push(_id);
    }
    
    
    function withdrawTokens(uint _id) public {
        require(msg.sender == TokenInfoTable[_id].tokenOwner, 'Only Token Owner can withdraw tokens');
        require(block.timestamp >= TokenInfoTable[_id].unlockTime, 'Unlock time is still in future');
        require(TokenInfoTable[_id].withdrawn == false, 'Tokens are already withdrawn');
        
        uint tokenType = TokenInfoTable[_id].tokenType;
        if(tokenType == 1) {
            IERC20(TokenInfoTable[_id].tokenAddress).transfer(TokenInfoTable[_id].tokenOwner, TokenInfoTable[_id].tokenAmount);
        }
        else if(tokenType == 2) {
            IERC721(TokenInfoTable[_id].tokenAddress).safeTransferFrom(address(this), TokenInfoTable[_id].tokenOwner, TokenInfoTable[_id].tokenId);
        }
        else if(tokenType == 3) {
            IERC1155(TokenInfoTable[_id].tokenAddress).safeTransferFrom(
                address(this), TokenInfoTable[_id].tokenOwner, TokenInfoTable[_id].tokenId, TokenInfoTable[_id].tokenAmount, '0x'
            );
        }
        TokenInfoTable[_id].withdrawn = true;
        
        //update balance in address
        totalTokensLockedByUser[TokenInfoTable[_id].tokenOwner][TokenInfoTable[_id].tokenAddress] -= TokenInfoTable[_id].tokenAmount;
    }
    
    
    /*get total token balance by address*/
    function getTokenBalanceByAddress(address _userAddress, address _tokenAddress) view public returns (uint)
    {
       return totalTokensLockedByUser[_userAddress][_tokenAddress];
    }
    
    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id) view public returns (TokenInfo memory)
    {
        return TokenInfoTable[_id];
    }
    
    /*get DepositsByUserAddress*/
    function getDepositsByUserAddress(address _currentUser) view public returns (uint[] memory)
    {
        return depositsByCurrentUser[_currentUser];
    }
}