// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
pragma solidity 0.8.2;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";
import "@openzeppelin/[email protected]/token/ERC1155/IERC1155.sol";

contract Management {
    address public manager;
    address public feeRecipient;

    modifier onlyManager {
        require(msg.sender == manager, "Only Manager can execute this function");
        _;
    }

    function setFeeRecipient(address _feeRecipient) public onlyManager {
        feeRecipient = _feeRecipient;
    }
}

contract ServiceCharges is Management {
	mapping(uint => uint[2]) public recipientsRange;
	function setDefaultPrices() internal {
		recipientsRange[1] = [1, 100];
		recipientsRange[2] = [101, 250];
		recipientsRange[3] = [251, 500];
		recipientsRange[4] = [501, 1000];
	}

	function changeRecipientsRange(uint range1Start, uint range1End, 
    uint range2Start, uint range2End, uint range3Start, 
    uint range3End, uint range4Start, uint range4End) 
	public onlyManager {
        recipientsRange[1] = [range1Start, range1End];
        recipientsRange[2] = [range2Start, range2End];
        recipientsRange[3] = [range3Start, range3End];
        recipientsRange[4] = [range4Start, range4End];
	}

    uint public ethFee;
    function setEthFee(uint _ethFee) public onlyManager {
        ethFee = _ethFee;
    }

  
    function withdrawCollectedETH() public onlyManager {
        (bool success, ) = feeRecipient.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    address public zuzAddress;
    uint public zuzFee;
    function setZuzData(address _zuzAddress, uint _zuzFee) public onlyManager {
        zuzAddress = _zuzAddress;
        zuzFee = _zuzFee;
    }
    
    address public usdtAddress;
    uint public usdtFee;
    function setUsdtData(address _usdtAddress, uint _usdtFee) public onlyManager {
        usdtAddress = _usdtAddress;
        usdtFee = _usdtFee;
    }

    address public usdcAddress;
    uint public usdcFee;
    function setUsdcData(address _usdcAddress, uint _usdcFee) public onlyManager {
        usdcAddress = _usdcAddress;
        usdcFee = _usdcFee;
    }
    
}

contract MultiSenderV8 is ServiceCharges { 
    
    constructor() {
        manager = msg.sender;
        feeRecipient = msg.sender;
		setDefaultPrices();
    }

    
    modifier getServiceFee(string memory _paymentMethod, uint noOfRecipients, uint noOfIds, uint noOfAmounts) {
		require(noOfRecipients == noOfIds && noOfRecipients == noOfAmounts, "size of all - recipientsArray, idsArray, amountsArray, should be equal");

		uint multiplier;
		if(noOfRecipients < recipientsRange[1][0]) multiplier = 0;
		else if(noOfRecipients >= recipientsRange[1][0]  && noOfRecipients <= recipientsRange[1][1]) multiplier = 1;
		else if(noOfRecipients >= recipientsRange[2][0] && noOfRecipients <= recipientsRange[2][1]) multiplier = 2;
		else if(noOfRecipients >= recipientsRange[3][0] && noOfRecipients <= recipientsRange[3][1]) multiplier = 3;
		else if(noOfRecipients >= recipientsRange[4][0] && noOfRecipients <= recipientsRange[4][1]) multiplier = 4;
		else require(false, "Contact our team to tranfer to no_of_recipients > uppermost_limit");

        if( keccak256(abi.encodePacked(_paymentMethod)) == keccak256(abi.encodePacked("eth")) ) require(msg.value >= (ethFee * multiplier), "Not Enought ETH sent");
        else if( keccak256(abi.encodePacked(_paymentMethod)) == keccak256(abi.encodePacked("zuz")) ) IERC20(zuzAddress).transferFrom(msg.sender, feeRecipient, (zuzFee * multiplier));
        else if( keccak256(abi.encodePacked(_paymentMethod)) == keccak256(abi.encodePacked("usdt")) ) IERC20(usdtAddress).transferFrom(msg.sender, feeRecipient, (usdtFee * multiplier));
        else if( keccak256(abi.encodePacked(_paymentMethod)) == keccak256(abi.encodePacked("usdc")) ) IERC20(usdcAddress).transferFrom(msg.sender, feeRecipient, (usdcFee * multiplier));
        else require(false, "Invalid payment-method");
        _;
    }

    function transferERC20(address _tokenAddress, address[] memory _recipients, uint[] memory _amounts, string memory _paymentMethod) public payable getServiceFee(_paymentMethod, _recipients.length, _recipients.length, _amounts.length) {
        for(uint i=0; i<_recipients.length; i++) {
            IERC20(_tokenAddress).transferFrom(msg.sender, _recipients[i], _amounts[i]);
        }
    }
    
    
    function transferERC721(address _tokenAddress, address[] memory _recipients, uint[] memory _tokenIds, string memory _paymentMethod) public payable getServiceFee(_paymentMethod, _recipients.length, _tokenIds.length, _recipients.length) {
        require(_recipients.length == _tokenIds.length, "number of recipients and tokenIds should be same");
        for(uint i=0; i<_recipients.length; i++) {
            IERC721(_tokenAddress).transferFrom(msg.sender, _recipients[i], _tokenIds[i]);
        }
    }
    
    bytes defaultData0;
    function transferERC1155(address _tokenAddress, address[] memory _recipients, uint[] memory _tokenIds, uint[] memory _amounts, string memory _paymentMethod) public payable getServiceFee(_paymentMethod, _recipients.length, _tokenIds.length, _amounts.length) {
        require(_recipients.length == _amounts.length, "number of recipients and amounts should be same");
        for(uint i=0; i<_recipients.length; i++) {
            IERC1155(_tokenAddress).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i], _amounts[i], defaultData0);
        }
    }
}