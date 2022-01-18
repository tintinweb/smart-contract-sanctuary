// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditions, IMirrorCrowdfundEditionsEvents} from "./interface/IMirrorCrowdfundEditions.sol";
import {ERC721} from "../../lib/ERC721/ERC721.sol";
import {IERC721Metadata, IERC721Events, IERC721Receiver} from "../../lib/ERC721/interface/IERC721.sol";
import {IERC2309} from "../../lib/ERC2309/interface/IERC2309.sol";
import {Operatable} from "../../lib/Operatable.sol";
import {Reentrancy} from "../../lib/Reentrancy.sol";
import {ITreasuryConfig} from "../../treasury/interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../treasury/interface/IMirrorTreasury.sol";
import {IMirrorFeeRegistry} from "../../fee-registry/MirrorFeeRegistry.sol";

/**
 * @title MirrorCrowdfundEditions
 * @author MirrorXYZ
 */
contract MirrorCrowdfundEditions is
    Operatable,
    Reentrancy,
    ERC721,
    IMirrorCrowdfundEditions,
    IMirrorCrowdfundEditionsEvents,
    IERC721Metadata,
    IERC2309
{
    // ============ Factory ============

    /// @notice The address that deploys and initializes clones
    address public immutable factory;

    // ============ ERC721 Metadata ============

    /// @notice Edition name
    string public override name;

    /// @notice Ediiton symbol
    string public override symbol;

    /// @notice Edition baseURI
    string public override baseURI;

    // ============ ERC721 Data ============

    /// @notice Id for last edition created
    uint256 internal lastEditionId;

    /// @notice Id for next token minted
    uint256 internal nextTokenId;

    /// @notice Map of tokenId to editionId
    mapping(uint256 => uint256) public tokenToEditionId;

    /// @notice Map of editions with state
    mapping(uint256 => Edition) public editions;

    // ============ Constructor ============
    constructor(address factory_) Operatable(address(0), address(0)) {
        factory = factory_;
    }

    // ============ Registry Methods ============

    /// @notice Initialize metadata and create editions
    function initialize(
        address owner_,
        address operator_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        EditionTier[] memory tiers
    ) external override {
        require(msg.sender == factory, "only factory can initialize");

        name = name_;
        symbol = symbol_;
        baseURI = baseURI_;

        _createEditions(tiers);

        // Update adminstation.
        _setOwner(address(0), owner_);
        _setOperator(operator_);
    }

    function createEditions(EditionTier[] memory tiers)
        external
        override
        onlyOperatorOrOwner
    {
        _createEditions(tiers);
    }

    function unpause(uint256 editionId) external override onlyOwner {
        editions[editionId].paused = false;
    }

    function pause(uint256 editionId) external override onlyOwner {
        editions[editionId].paused = true;
    }

    /// @notice Allows the operator to trigger a purchase.
    function purchase(uint256 editionId, address recipient)
        external
        override
        onlyOperator
        returns (uint256 tokenId)
    {
        return _purchase(editionId, recipient);
    }

    /// @notice Allows the owner or operator to mint directly.
    function mint(uint256 editionId, address to)
        external
        virtual
        onlyOperatorOrOwner
        returns (uint256 tokenId)
    {
        tokenId = _getTokenIdAndMint(editionId, to);
    }

    /// @notice Allows the owner to set a global limit on the total supply.
    function setEditionLimit(uint256 editionId_, uint256 limit_)
        public
        onlyOperatorOrOwner
    {
        Edition storage edition = editions[editionId_];
        // Enforce that the limit should only ever decrease once set.
        require(
            edition.limit == 0 || limit_ < edition.limit,
            "Limit must be < than current limit"
        );
        // Update the limit.
        edition.limit = limit_;
        // Announce the change in limit.
        emit EditionLimitSet(editionId_, limit_);
    }

    function setName(string calldata name_) public onlyOperatorOrOwner {
        name = name_;
    }

    function setSymbol(string calldata symbol_) public onlyOperatorOrOwner {
        symbol = symbol_;
    }

    function setBaseURI(string calldata baseURI_) public onlyOperatorOrOwner {
        baseURI = baseURI_;
    }

    function contractURI() public view override returns (string memory) {
        // Concatenate the components baseURI and metadata
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 editionId = tokenToEditionId[tokenId];
        // If the token does not map to an edition, it'll be 0.
        require(editionId != 0, "Token has not been sold yet");
        // Concatenate the components, baseURI, editionId and tokenId, to create URI.
        return
            string(
                abi.encodePacked(
                    baseURI,
                    _toString(editionId),
                    "/",
                    _toString(tokenId)
                )
            );
    }

    // Given an edition's ID, returns its price.
    function editionPrice(uint256 editionId)
        external
        view
        override
        returns (uint256)
    {
        return editions[editionId].price;
    }

    // ============ Internal Methods ============

    function _createEditions(EditionTier[] memory tiers) internal {
        // Local reference of lastEditionId.
        uint256 lastEditionId_ = lastEditionId;
        // Copy the next edition id, which we reference in the loop.
        uint256 firstEditionId = lastEditionId_ + 1;

        // Execute a loop that created editions.
        for (uint8 x = 0; x < tiers.length; x++) {
            uint256 editionId = firstEditionId + x;

            editions[editionId] = Edition({
                paused: false,
                numMinted: 0,
                numPurchased: 0,
                purchasableAmount: tiers[x].quantity,
                price: tiers[x].price,
                limit: tiers[x].quantity,
                contentHash: tiers[x].contentHash
            });

            emit EditionCreated(tiers[x].quantity, tiers[x].price, editionId);
        }

        // Update the next edition id
        lastEditionId += tiers.length;
    }

    function _getTokenIdAndMint(uint256 editionId, address recipient)
        internal
        returns (uint256 tokenId)
    {
        // Get a reference to the edition data.
        Edition storage edition = editions[editionId];
        // edition purchases are active
        require(!edition.paused, "paused edition");
        // Check that there are still tokens available to purchase.
        require(edition.numPurchased < edition.purchasableAmount, "sold out");
        // Make sure we won't the limit on total supply.
        require(
            edition.limit == 0 || edition.numMinted <= edition.limit,
            "Token limit reached for edition"
        );
        // Track token id. Starts at 1.
        nextTokenId += 1;
        // Local copy to return.
        tokenId = nextTokenId;
        // Store a reference for token id to edition id.
        tokenToEditionId[tokenId] = editionId;
        // Since tokenId would revert given an overflow, we can go unchecked.
        unchecked {
            // Update edition numMinted
            edition.numMinted += 1;
            // Update edition numPurchased.
            edition.numPurchased += 1;
        }
        // Mint a new token for the recipient, using the `tokenId`.
        _mint(recipient, nextTokenId);
        // Return this token's ID.
        return tokenId;
    }

    function _purchase(uint256 editionId, address recipient)
        internal
        returns (uint256 tokenId)
    {
        // Mint the token, get a token ID.
        tokenId = _getTokenIdAndMint(editionId, recipient);
    }

    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    function _toString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditionStructs} from "./IMirrorCrowdfundEditionStructs.sol";

interface IMirrorCrowdfundEditionsEvents {
    /// @notice Create edition
    event EditionCreated(
        uint256 purchasableAmount,
        uint256 price,
        uint256 editionId
    );

    event OperatorChanged(
        address indexed proxy,
        address oldOperator,
        address newOperator
    );

    event EditionLimitSet(uint256 indexed editionId, uint256 limit);
}

interface IMirrorCrowdfundEditions is IMirrorCrowdfundEditionStructs {
    function initialize(
        address owner_,
        address operator_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        EditionTier[] memory tiers
    ) external;

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    /// @notice Create edition
    function createEditions(EditionTier[] memory tiers) external;

    function mint(uint256 editionId, address to)
        external
        returns (uint256 tokenId);

    function unpause(uint256 editionId) external;

    function pause(uint256 editionId) external;

    function purchase(uint256 editionId, address recipient)
        external
        returns (uint256 tokenId);

    function editionPrice(uint256 editionId) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC721, IERC721Events, IERC721Metadata, IERC721Receiver} from "./interface/IERC721.sol";
import {IERC165} from "../ERC165/interface/IERC165.sol";

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * Based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
 */
contract ERC721 is ERC165, IERC721, IERC721Events {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

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
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/Address.sol
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Events {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Burnable is IERC721 {
    function burn(uint256 tokenId) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Royalties {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../lib/Ownable.sol";

interface IOperatableEvents {
    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );
}

// Adds an additional admin account that might be a contract, can be set by owner.
contract Operatable is Ownable, IOperatableEvents {
    address public operator;

    // modifiers

    modifier onlyOperator() {
        require(isOperator(), "caller is not the operator.");
        _;
    }

     modifier onlyOperatorOrOwner() {
        require(isOperator() || isOwner(), "caller is not the operator or owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner, address operator_) Ownable(owner) {
        operator = operator_;

        emit OperatorTransferred(address(0), operator_);
    }

    /**
     * @dev Transfer operator to a new address.
     */
    function transferOperator(address newOperator_) external onlyOwner {
        _setOperator(newOperator_);
    }

    /**
     * @dev Returns true if the caller is the current operator.
     */
    function isOperator() public view returns (bool) {
        return msg.sender == operator;
    }

    function _setOperator(address newOperator_) internal {
        emit OperatorTransferred(operator, newOperator_);

        operator = newOperator_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

contract Reentrancy {
    // ============ Constants ============

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Mutable Storage ============

    uint256 internal reentrancyStatus;

    // ============ Modifiers ============

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");
        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = REENTRANCY_ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip2200)
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorTreasury {
    function transferFunds(address payable to, uint256 value) external;

    function transferERC20(
        address token,
        address to,
        uint256 value
    ) external;

    function contributeWithTributary(address tributary) external payable;

    function contribute(uint256 amount) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../lib/Ownable.sol";

interface IMirrorFeeRegistry {
    function maxFee() external returns (uint256);

    function updateMaxFee(uint256 newFee) external;
}

/**
 * @title MirrorFeeRegistry
 * @author MirrorXYZ
 */
contract MirrorFeeRegistry is IMirrorFeeRegistry, Ownable {
    uint256 public override maxFee = 500;

    constructor(address owner_) Ownable(owner_) {}

    function updateMaxFee(uint256 newFee) external override onlyOwner {
        maxFee = newFee;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IMirrorCrowdfundEditionStructs {
    /// @notice Statuses for funding and redeeming.
    enum FundingStatus {
        CONTRIBUTE,
        CONTRIBUTE_WITH_PROOF,
        PAUSED,
        CLOSED,
        REFUND,
        REDEEM_WITH_PROOF
    }

    struct Edition {
        // How many tokens are available to purchase in a campaign?
        uint256 purchasableAmount;
        // What is the price per token in the campaign?
        uint256 price;
        // What is the content hash of the token's content?
        bytes32 contentHash;
        // How many have currently been minted in total?
        uint256 numMinted;
        // How many have been purchased?
        uint256 numPurchased;
        // Is this edition paused?
        bool paused;
        // Optionally limit the number of tokens that can be minted.
        uint256 limit;
    }

    struct EditionTier {
        // When setting up an EditionTier, specify the supply limit.
        uint256 quantity;
        uint256 price;
        bytes32 contentHash;
    }

    // ERC20 Attributes.
    struct ERC20Attributes {
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        uint256 nonce;
    }

    // Initialization configuration.
    struct CrowdfundInitConfig {
        address owner;
        uint256 exchangeRate;
        address fundingRecipient;
        FundingStatus fundingStatus;
    }

    struct CampaignConfig {
        string name;
        string symbol;
        uint256 fundingCap;
    }

    struct Campaign {
        address editionsProxy;
        uint256 fundingCap;
        uint256 amountRaised;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract Ownable is IOwnableEvents {
    address public owner;
    address private nextOwner;

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _renounceOwnership() internal {
        emit OwnershipTransferred(owner, address(0));

        owner = address(0);
    }
}