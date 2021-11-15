// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/RoyaltiesV1.sol";
import "./interfaces/IERC1155Receiver.sol";

contract TestSale is RoyaltiesV1, IERC1155Receiver {
    address public immutable owner; // Owner's address
    uint256 public itemPrice; // Fixed price for one token
    uint256 public saleStart; // block.timestamp of initialization transaction
    uint256 public saleDuration; // Duration of sale in seconds
    uint256 public availableForSale; // Remaining amount of tokens
    uint256 public tokenIdToSale; // ERC1155 tokenID using for sale
    IERC1155 public tokenToSale;

    uint256 public constant maxBPs = 10000; // Maximum BPs (100%)

    address payable[] public royaltiesRecipients; // List of fee recepients
    uint256[] public royaltiesBPs; // List of fees' amounts

    event Sold(address indexed buyer, uint256 amount, uint256 itemPrice);
    event SaleStarted(
        address initiator,
        uint256 saleStart,
        uint256 saleDuration,
        uint256 availableForSale,
        uint256 tokenIdToSale
    );
    event NewPrice(uint256 oldPrice, uint256 newPrice);

    constructor() {
        owner = msg.sender;
    }

    function getFeeRecipients(uint256 id)
        external
        view
        override
        returns (address payable[] memory)
    {
        if (id == tokenIdToSale) return royaltiesRecipients;
        address payable[] memory empty;
        return empty;
    }

    function getFeeBps(uint256 id)
        external
        view
        override
        returns (uint256[] memory)
    {
        if (id == tokenIdToSale) return royaltiesBPs;
        uint256[] memory empty;
        return empty;
    }

    function setItemPrice(uint256 _newItemPrice) public onlyOwner {
        require(_newItemPrice > 0, "invalid newItemPrice");
        uint256 oldPrice = itemPrice;
        require(_newItemPrice != oldPrice, "this itemPrice already set");
        itemPrice = _newItemPrice;
        emit NewPrice(oldPrice, _newItemPrice);
    }

    function isActive() public view returns (bool) {
        if (
            itemPrice > 0 &&
            saleStart <= block.timestamp &&
            block.timestamp <= saleStart + saleDuration &&
            availableForSale > 0
        ) return true;
        return false;
    }

    function startSale(
        uint256 _saleDuration,
        uint256 _itemPrice,
        address _tokenToSale,
        uint256 _tokenIdToSale,
        address payable[] memory _royaltiesRecipients,
        uint256[] memory _royaltiesBPs
    ) external onlyOwner {
        require(!isActive(), "sale has already started");
        require(_saleDuration > 0, "sale duration must be != 0");
        require(_tokenToSale != address(0), "incorrect tokenToSale address");
        uint256 tokenBalance = IERC1155(_tokenToSale).balanceOf(
            address(this),
            _tokenIdToSale
        );
        require(tokenBalance > 0, "not enough tokens");
        setItemPrice(_itemPrice);
        saleDuration = _saleDuration;
        saleStart = block.timestamp;
        tokenIdToSale = _tokenIdToSale;
        availableForSale = tokenBalance;
        tokenToSale = IERC1155(_tokenToSale);
        uint256 feeSum;
        for (uint256 i = 0; i < _royaltiesRecipients.length; i++) {
            // ignore if some element is >= maxBPs
            if (_royaltiesBPs[i] < maxBPs) {
                royaltiesBPs.push(_royaltiesBPs[i]);
                royaltiesRecipients.push(_royaltiesRecipients[i]);
                feeSum += _royaltiesBPs[i];
            }
        }
        require(feeSum < maxBPs, "fees sum must be < 10000");
        emit SaleStarted(
            msg.sender,
            saleStart,
            _saleDuration,
            tokenBalance,
            _tokenIdToSale
        );
    }

    function buy(uint256 _amount) public payable {
        require(isActive(), "sale is not active");
        require(_amount <= availableForSale, "amount exceeds available");
        uint256 totalCharge = _amount * itemPrice;
        require(msg.value >= totalCharge, "not enough funds");
        availableForSale -= _amount;
        address payable[] memory recipients = royaltiesRecipients;
        uint256[] memory fees = royaltiesBPs;
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer((totalCharge * fees[i]) / maxBPs);
        }
        tokenToSale.safeTransferFrom(
            address(this),
            msg.sender,
            tokenIdToSale,
            _amount,
            ""
        );
        if (msg.value > totalCharge)
            payable(msg.sender).transfer(msg.value - totalCharge);
        emit Sold(msg.sender, _amount, itemPrice);
        emit SecondarySaleFees(tokenIdToSale, recipients, fees);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "amount must be != 0");
        require(_amount <= address(this).balance, "not enough balance");
        payable(owner).transfer(_amount);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override view returns (bytes4) {
        return IERC1155Receiver(address(this)).onERC1155Received.selector;
    }

    function magicFunction(bytes memory _encodedData) external payable {
        (bool success, ) = address(this).delegatecall(_encodedData);
        require(success, "no magic");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "access denied");
        _;
    }

    receive() external payable {
        uint256 amount = msg.value / itemPrice;
        require(amount >= 1, "not enough eth");
        buy(amount);
    }
}

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

pragma solidity =0.8.7;

interface RoyaltiesV1 {
    event SecondarySaleFees(uint256 tokenId, address payable[] recipients, uint[] bps);

    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
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

