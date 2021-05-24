pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./Pauser.sol";
import { ECRecover } from "./util/ECRecover.sol";

contract ADAMCustodyWalletOne is IERC721Receiver, IERC1155Receiver, Pauser {
    address public owner;
    address public operator;
    // onReceive function signatures
    // Equals to `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    bytes4 constant internal ERC1155_RECEIVED = 0xf23a6e61;
    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 constant internal ERC721_RECEIVED = 0x150b7a02;
    //  Equals to `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    bytes4 constant internal ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // ERC721 NFT contract address => TokenId => nonce
    mapping(address => mapping(uint256 => uint256)) private noncesERC721;
    // ERC721 NFT contract address => TokenId => depositer => nonce
    mapping(address => mapping(uint256 => mapping(bytes32 => uint256))) private noncesERC1155;

    event OperatorChanged(address indexed _oldOperator, address indexed _newOperator, address indexed _sender);
    event PauserChanged(address indexed _oldPauser, address indexed _newPauser, address indexed _sender);
    event OnERC1155Received(address indexed _operator, address indexed _from, uint256 indexed _tokenId, uint256 _amount);
    event OnERC721Received(address indexed _operator, address indexed _from, uint256 indexed _tokenId);
    event OnERC1155BatchReceived(address indexed _operator, address indexed _from, uint256[] _tokenIds, uint256[] _amounts);

    event DepositERC721(address indexed _from, address indexed _to, address indexed _tokenAddress, uint256 _tokenId);
    event WithdrawERC721(address indexed _caller, address indexed _to, address indexed _tokenAddress, uint256 _tokenId);
    event RedepositERC721(address indexed _from, address indexed _to, address indexed _tokenAddress, uint256 _tokenId);
    
    event DepositERC1155(address indexed _from, address indexed _to, address indexed _tokenAddress, uint256 _tokenId, uint256 _amount, bytes32 _holder);
    event WithdrawERC1155(address indexed _caller, address indexed _to, address indexed _tokenAddress, uint256 _tokenId, uint256 _amount, bytes32 _holder);
    event RedepositERC1155(address indexed _from, address indexed _to, address indexed _tokenAddress, uint256 _tokenId, uint256 _amount, bytes32 _holder);

    //test
    event Test(bytes32 _data, address _signer, address _to);


    constructor(address _owner, address _operator, address _pauser) public {
        require(_owner != address(0), "_owner is the zero address");
        require(_operator != address(0), "_operator is the zero address");
        require(_pauser != address(0), "_pauser is the zero address");
        owner = _owner;
        operator = _operator;
        pauser = _pauser; 

        emit OperatorChanged(address(0), operator, msg.sender);
        emit PauserChanged(address(0), pauser, msg.sender);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "the sender is not the operator");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "the sender is not the owner");
        _;
    }

    function changeOperator(address _account) public onlyOwner {
        require(_account != address(0), "this account is the zero address");

        address old = operator;
        operator = _account;
        emit OperatorChanged(old, operator, msg.sender);
    }

    function changePauser(address _account) public onlyOwner {
        require(_account != address(0), "this account is the zero address");

        address old = pauser;
        pauser = _account;
        emit PauserChanged(old, pauser, msg.sender);
    }

    // transfer ERC721 token
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferERC721(address _tokenAddress, address _to, uint256 _tokenId) external whenNotPaused onlyOperator {
        IERC721(_tokenAddress).transferFrom(address(this), _to, _tokenId);
    }

    // transfer ERC1155 token 
    // function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external
    function transferERC1155(address _tokenAddress, address _to, uint256 _tokenId, uint256 _amount) external whenNotPaused onlyOperator {
        IERC1155(_tokenAddress).safeTransferFrom(address(this), _to, _tokenId, _amount, "");
    }

    function getNonceERC721(address _tokenAddress, uint256 _tokenid)
        public
        view
        returns (uint256)
    {
        return noncesERC721[_tokenAddress][_tokenid];
    }

    function getNonceERC1155(address _tokenAddress, uint256 _tokenid, bytes32 _holder)
        public
        view
        returns (uint256)
    {
        return noncesERC1155[_tokenAddress][_tokenid][_holder];
    }

    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        public 
        pure 
        returns (address) 
    {
        return ECRecover.recover(digest, v, r, s);
    }

    function convert(uint256 n) internal pure returns (bytes32) {
        return bytes32(n);
    }

    function depositERC721(address _tokenAddress, uint256 _tokenId) 
        external 
    {
        IERC721(_tokenAddress).transferFrom(address(msg.sender), address(this), _tokenId);
        emit DepositERC721(address(msg.sender), address(this), _tokenAddress, _tokenId);
    }

    function depositERC1155(address _tokenAddress, uint256 _tokenId, uint256 _amount, bytes32 _holder) 
        external 
    {
        IERC1155(_tokenAddress).safeTransferFrom(address(msg.sender), address(this), _tokenId, _amount, "");
        emit DepositERC1155(address(msg.sender), address(this), _tokenAddress, _tokenId, _amount, _holder);
    }

    function test(
        address _tokenAddress,
        uint256 _tokenId,
        address _to,
        uint256 _nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external 
    {
        uint256 nonce = _nonce;

        bytes32 data = keccak256(abi.encodePacked(
            _tokenAddress,
            convert(_tokenId),
            address(msg.sender),
            convert(nonce))
        );
        

        address signer = recover(data, v, r, s);
        emit Test(data, signer, _to);

    }

    function withdrawERC721(
        address _tokenAddress,
        uint256 _tokenId,
        address _to,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external 
    {
        uint256 nonce = getNonceERC721(_tokenAddress, _tokenId);

        bytes32 data = keccak256(abi.encodePacked(
            _tokenAddress,
            convert(_tokenId),
            address(msg.sender),
            convert(nonce))
        );

        require(
            recover(data, v, r, s) == operator,
            "invalid signature"
        );

        noncesERC721[_tokenAddress][_tokenId]++;
        IERC721(_tokenAddress).transferFrom(address(this), _to, _tokenId);

        emit WithdrawERC721(address(msg.sender), _to, _tokenAddress, _tokenId);
    }

    function withdrawERC1155(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _to,
        bytes32 _holder,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external 
    {
        uint256 nonce = getNonceERC1155(_tokenAddress, _tokenId, _holder);

        bytes32 data = keccak256(abi.encodePacked(
            _tokenAddress,
            convert(_tokenId),
            convert(_amount),
            address(msg.sender),
            _holder, 
            convert(nonce))
        );

        require(
            recover(data, v, r, s) == operator,
            "invalid signature"
        );

        noncesERC1155[_tokenAddress][_tokenId][_holder]++;
        IERC1155(_tokenAddress).safeTransferFrom(address(this), _to, _tokenId, _amount, "");

        emit WithdrawERC1155(address(msg.sender), _to, _tokenAddress, _tokenId, _amount, _holder);
    }

    function redepositERC721(
        address _tokenAddress,
        uint256 _tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external
    {

        require(
            IERC721(_tokenAddress).ownerOf(_tokenId) == address(this),
            "redepositERC721 failed"
        );

        uint256 nonce = getNonceERC721(_tokenAddress, _tokenId);

        bytes32 data = keccak256(abi.encodePacked(
            _tokenAddress,
            convert(_tokenId),
            address(msg.sender),
            convert(nonce))
        );
        require(
            recover(data, v, r, s) == operator,
            "invalid signature"
        );

        noncesERC721[_tokenAddress][_tokenId]++;
        emit RedepositERC721(address(msg.sender), address(this), _tokenAddress, _tokenId);
    }


    function redepositERC1155(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        bytes32 _holder,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        external
    {

        require(
            IERC1155(_tokenAddress).balanceOf(address(this), _tokenId) >= _amount,
            "redepositERC1155 failed"
        );

        uint256 nonce = getNonceERC1155(_tokenAddress, _tokenId, _holder);

        bytes32 data = keccak256(abi.encodePacked(
            _tokenAddress,
            convert(_tokenId),
            convert(_amount),
            address(msg.sender),
            _holder,
            convert(nonce))
        );
        require(
            recover(data, v, r, s) == operator,
            "invalid signature"
        );

        noncesERC1155[_tokenAddress][_tokenId][_holder]++;
        emit RedepositERC1155(address(msg.sender), address(this), _tokenAddress, _tokenId, _amount, _holder);
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata /*_data*/
    )
        external
        override
        returns(bytes4)
    {
        OnERC1155Received(_operator, _from, _tokenId, _amount);
        return ERC1155_RECEIVED;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata /*_data*/
    )
        external
        override
        returns(bytes4)
    {
        OnERC721Received(_operator, _from, _tokenId);
        return ERC721_RECEIVED;
    }

    function onERC1155BatchReceived(
        address _operator, 
        address _from, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _amounts, 
        bytes calldata /*_data*/
    )
        external
        override
        returns(bytes4)
    {
        OnERC1155BatchReceived(_operator, _from, _tokenIds, _amounts);
        return ERC1155_BATCH_RECEIVED;
    }    

    // no means
    function supportsInterface(bytes4 /*interfaceId*/) public view virtual override(IERC165) returns (bool) {
        return false;
    }

}

pragma solidity =0.6.6;


contract Pauser {
    address public pauser = address(0);
    bool public paused = false;

    event Pause(bool status, address indexed sender);

    modifier onlyPauser() {
        require(msg.sender == pauser, "the sender is not the pauser");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "this is a paused contract");
        _;
    }

    modifier whenPaused() {
        require(paused, "this is not a paused contract");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        paused = true;
        emit Pause(paused, msg.sender);
    }

    function unpause() public onlyPauser whenPaused {
        paused = false;
        emit Pause(paused, msg.sender);
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.6.6;

/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}