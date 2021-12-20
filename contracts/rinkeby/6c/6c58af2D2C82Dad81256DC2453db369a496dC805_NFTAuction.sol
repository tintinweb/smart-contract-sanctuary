/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        string id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        string[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, string indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, string memory id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, string[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        string memory id,
        uint256 amount,
        string calldata data
    ) external;

    function isMinters(address _for) external view returns (bool);

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
    function safeBatchTransferFrom(
        address from,
        address to,
        string[] calldata ids,
        uint256[] calldata amounts,
        string calldata data
    ) external;
}

contract Ownable {
    // Variable that maintains
    // owner address
    address private _owner;

    // Sets the original owner of
    // contract when it is deployed
    constructor() {
        _owner = msg.sender;
    }

    // Publicly exposes who is the
    // owner of this contract
    function owner() public view returns (address) {
        return _owner;
    }

    // onlyOwner modifier that validates only
    // if caller of function is contract owner,
    // otherwise not
    modifier onlyOwner() {
        require(isOwner(), "Function accessible only by the owner !!");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    // function for owners to verify their ownership.
    // Returns true for owners otherwise false
}

abstract contract Context {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(
            msg.sender == address(trustedForwarder),
            "Function can only be called through the trusted Forwarder"
        );
        _;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract NFTAuction is Ownable, Context {
    mapping(address => mapping(string => address)) private nftContractAuctions;

    address public _nftContractAddress;
    mapping(address => bool) public escrowOwner;

    //Each Auction is unique to each NFT (contract + id pairing).

    constructor(address _nftAddress, address _trustedForwarder) {
        _nftContractAddress = _nftAddress;
        trustedForwarder = _trustedForwarder;
    }

    event changeForwarder(
        address indexed newForwarder,
        address indexed oldForwarder
    );
    event NftAuctionCreated(string tokenId, address NFT_Owner);
    event AuctionEnd(string tokenId, address newOwner);

    modifier isAuctionNotStartedByOwner(string memory _tokenId) {
        require(
            nftContractAuctions[_nftContractAddress][_tokenId] == address(0),
            "Auction already started by owner"
        );
        _;
    }

    modifier isNftOwner(string memory _tokenId, address NFT_Owner) {
        require(
            IERC1155(_nftContractAddress).balanceOf(NFT_Owner, _tokenId) != 0,
            "Sender doesn't own NFT"
        );
        _;
    }

    function changeTrustedForwarder(address newForwarder) external onlyOwner {
        require(
            newForwarder != address(0x0) && newForwarder != trustedForwarder,
            "Msg : Invlaid Address"
        );
        address _oldForwarder = trustedForwarder;
        trustedForwarder = newForwarder;
        emit changeForwarder(newForwarder, _oldForwarder);
    }

    function lockNFT(string memory _tokenId, address NFT_Owner)
        external
        isAuctionNotStartedByOwner(_tokenId)
    {
        nftContractAuctions[_nftContractAddress][_tokenId] = _msgSender();
        require(
            IERC1155(_nftContractAddress).balanceOf(_msgSender(), _tokenId) !=
                0,
            "Not Allowed : Sender is not owner"
        );

        IERC1155(_nftContractAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _tokenId,
            1,
            ""
        );
        emit NftAuctionCreated(_tokenId, NFT_Owner);
    }

    function unLockNFT(string memory _tokenId, address _newOwner) external {
        require(
            escrowOwner[msg.sender],
            "Not Allowed: Msg sender should be escrow Owner"
        );
        IERC1155(_nftContractAddress).safeTransferFrom(
            address(this),
            _newOwner,
            _tokenId,
            1,
            ""
        );
        nftContractAuctions[_nftContractAddress][_tokenId] = address(0);

        emit AuctionEnd(_tokenId, _newOwner);
    }

    function setEscrowOwner(address _newOwner, bool value) public onlyOwner {
        escrowOwner[_newOwner] = value;
    }
}