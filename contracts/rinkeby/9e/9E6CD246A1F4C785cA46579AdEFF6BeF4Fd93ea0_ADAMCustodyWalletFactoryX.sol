pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ADAMCustodyWalletX.sol";
import "./Pauser.sol";

contract ADAMCustodyWalletFactoryX is Pauser {
    address public owner;
    address public operator;

    address public tokenAddress;
    address public fromAddress;
    address public toAddress;
    uint256 public tokenId;
    uint256 public amountERC1155;
    bool public erc721Flag = false;

    event OperatorChanged(address indexed oldOperator, address indexed newOperator, address indexed sender);
    event PauserChanged(address indexed oldPauser, address indexed newPauser, address indexed sender);

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

    // predict the wallet address
    function predict(bytes32 _salt) public view returns(address){
        return address(uint(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            _salt,
            keccak256(abi.encodePacked(type(ADAMCustodyWalletX).creationCode))
        ))));
    }

    // transfer ERC721 token
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferERC721(address _tokenAddress, address _from, address _to, uint256 _tokenId, bytes32 _salt) external whenNotPaused onlyOperator {
        // address walletAddress = predict(_salt);
        //require(IERC721(_tokenAddress).balanceOf(walletAddress) >= 0, 'transferERC721 failed');

        tokenAddress = _tokenAddress;
        fromAddress = _from;
        toAddress = _to; 
        tokenId = _tokenId;
        erc721Flag = true;
        

        bytes memory bytecode = type(ADAMCustodyWalletX).creationCode;
        assembly {
            let codeSize := mload(bytecode)
            let newAddr := create2(
                0,
                add(bytecode, 32),
                codeSize,
                _salt
            )
        }

        tokenAddress = address(0);
        fromAddress = address(0);
        toAddress = address(0); 
        tokenId = 0;
        erc721Flag = false;
    }


    // transfer ERC721 token
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferERC721X(address _tokenAddress, address _from, address _to, uint256 _tokenId, bytes32 _salt) external whenNotPaused onlyOperator {
        address predictAddress = predict(_salt);
        //require(IERC721(_tokenAddress).balanceOf(walletAddress) >= 0, 'transferERC721 failed');

        tokenAddress = _tokenAddress;
        fromAddress = _from;
        toAddress = _to; 
        tokenId = _tokenId;
        erc721Flag = true;
        

        ADAMCustodyWalletX custodyWallet = new ADAMCustodyWalletX{salt: _salt}();
        require(
            address(custodyWallet) == predictAddress,
            "transferERC1155: wrong address prediction"
        );

        tokenAddress = address(0);
        fromAddress = address(0);
        toAddress = address(0); 
        tokenId = 0;
        erc721Flag = false;
    }


    // transfer ERC1155 token 
    // function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external
    function transferERC1155X(address _tokenAddress, address _from, address _to, uint256 _tokenId, uint256 _amount, bytes32 _salt) external whenNotPaused onlyOperator {
        address predictAddress = predict(_salt);
        require(IERC1155(_tokenAddress).balanceOf(_from, _tokenId) >= _amount, 'transferERC1155: wrong balance');

        tokenAddress = _tokenAddress;
        fromAddress = _from;
        toAddress = _to; 
        tokenId = _tokenId;
        amountERC1155 = _amount;
        erc721Flag = false; 


        ADAMCustodyWalletX custodyWallet = new ADAMCustodyWalletX{salt: _salt}();
        require(
            address(custodyWallet) == predictAddress,
            "transferERC1155: wrong address prediction"
        );

        tokenAddress = address(0);
        fromAddress = address(0);
        toAddress = address(0); 
        tokenId = 0;
        amountERC1155 = 0;
    }

    function transferERC1155(address _tokenAddress, address _from, address _to, uint256 _tokenId, uint256 _amount, bytes32 _salt) external whenNotPaused onlyOperator {
        //address predictAddress = predict(_salt);
        require(IERC1155(_tokenAddress).balanceOf(_from, _tokenId) >= _amount, 'transferERC1155: wrong balance');

        tokenAddress = _tokenAddress;
        fromAddress = _from;
        toAddress = _to; 
        tokenId = _tokenId;
        amountERC1155 = _amount;
        erc721Flag = false; 


        bytes memory bytecode = type(ADAMCustodyWalletX).creationCode;
        assembly {
            let codeSize := mload(bytecode)
            let newAddr := create2(
                0,
                add(bytecode, 32),
                codeSize,
                _salt
            )
        }

        tokenAddress = address(0);
        fromAddress = address(0);
        toAddress = address(0); 
        tokenId = 0;
        amountERC1155 = 0;
    }
}

pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ADAMCustodyWalletFactoryX.sol";

contract ADAMCustodyWalletX {
    //event ERC721Transfered(address indexed operator, address indexed from, address indexed to, uint256 id);
    //event ERC1155Transfered(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount);

    constructor() public {
        address factory = msg.sender;
        bool erc721 = ADAMCustodyWalletFactoryX(factory).erc721Flag(); 
        address token = ADAMCustodyWalletFactoryX(factory).tokenAddress();
        address from = ADAMCustodyWalletFactoryX(factory).fromAddress();
        address to = ADAMCustodyWalletFactoryX(factory).toAddress();
        uint256 tokenId = ADAMCustodyWalletFactoryX(factory).tokenId();

        if(erc721){
            IERC721(token).safeTransferFrom(from, to, tokenId);
            // event
            //ERC721Transfered(address(this), from, to, tokenId);
        } else {
            uint256 amount = ADAMCustodyWalletFactoryX(factory).amountERC1155();
            IERC1155(token).safeTransferFrom(from, to, tokenId, amount, "");

            // event
            //ERC1155Transfered(address(this), from, to, tokenId, amount);

        }
        //to save gas
        selfdestruct(address(0));
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

