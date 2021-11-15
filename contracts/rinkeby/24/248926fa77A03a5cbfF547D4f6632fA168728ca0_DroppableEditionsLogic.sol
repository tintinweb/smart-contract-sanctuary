// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IERC721, IERC721Events, IERC721Receiver, IERC721Metadata, IERC165} from "../../../external/interface/IERC721.sol";
import {IERC2309} from "../../../external/interface/IERC2309.sol";
import {ITreasuryConfig} from "../../../interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../../interface/IMirrorTreasury.sol";
import {InitializedGovernable} from "../../../lib/InitializedGovernable.sol";
import {Pausable} from "../../../lib/Pausable.sol";
import {Reentrancy} from "../../../lib/Reentrancy.sol";
import {DroppableEditionsStorage} from "./DroppableEditionsStorage.sol";
import {IDroppableEditionsLogicEvents} from "./interface/IDroppableEditionsLogic.sol";
import {IProxyRegistry} from '../../../external/opensea/IProxyRegistry.sol';

/**
 * @title DroppableEditionsLogic
 * @author MirrorXYZ
 */
contract DroppableEditionsLogic is 
    DroppableEditionsStorage,
    InitializedGovernable,
    Pausable,
    IDroppableEditionsLogicEvents,
    IERC721,
    IERC721Events,
    IERC165,
    IERC721Metadata,
    IERC2309,
    Reentrancy
{

    /// @notice IERC721Metadata
    string public override name;
    string public override symbol;

    constructor(
        address owner_,
        address governor_,
        address proxyRegistry_
    ) InitializedGovernable(owner_, governor_) Pausable(true) {
        proxyRegistry = proxyRegistry_;
    }

    // ============ Pause Methods ============

    /// @notice pause purchases
    function pause() public onlyGovernance {
        _pause();
    }

    /// @notice unpause purchases
    function unpause() public onlyGovernance {
        _unpause();
    }

    // ============ Edition Methods ============

    function purchase(address recipient)
        external
        payable
        returns (uint256 tokenId)
    {
        // Check that recipient has not already purchased
        require(!purchased[recipient], "already purchased");
        // Check that enough funds have been sent to purchase an edition.
        require(msg.value >= price, "insufficient funds");
        // Track and update token id.
        tokenId = allocation + nonAllocatedPurchases;
        // Check that there are still tokens available to purchase.
        require(tokenId < quantity, "sold out");
        // Mint a new token for the sender, using the `tokenId`.
        purchased[recipient] = true;
        _mint(recipient, tokenId);
        emit EditionPurchased(tokenId, msg.value, msg.sender, recipient);

        nonAllocatedPurchases += 1;
    }

    // ============ NFT Methods ============

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        require(
            owner_ != address(0),
            "zero address"
        );

        return _balances[owner_];
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "not approved"
        );

        _burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "not approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "not approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "not approved"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "nonexistent"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address approver, bool approved)
        public
        override
    {
        require(approver != msg.sender, "approve to caller");

        _operatorApprovals[msg.sender][approver] = approved;
        emit ApprovalForAll(msg.sender, approver, approved);
    }

    /**
     * @notice OpenSea proxy contracts are approved by default.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Approve all OpenSea proxy contracts for easy trading.
        if (IProxyRegistry(proxyRegistry).proxies(owner) == operator) {
            return true;
        }

        return _operatorApprovals[owner][operator];
    }

    /// @notice e.g. https://mirror-api.com/editions/metadata
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    /**
     * @notice The hash of the given content for the NFT. Can be used
     * for IPFS storage, verifying authenticity, etc.
     */
    function getContentHash(uint256) public view returns (bytes32) {
        return contentHash;
    }

    // ============ Operational Methods ============

    function withdrawFunds() external Reentrancy.nonReentrant {
        // Transfer the fee to the treasury.
        // Treasury fee is paid first for efficiency, so we don't have to calculate
        // the fee and the revenue amount. Also prevents a reentrancy attack scenario that
        // avoids paying treasury.
        uint256 fee = feeAmount(address(this).balance);
        IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury())
            .contribute{value: fee}(fee);

        // Transfer the remaining available balance to the fundingRecipient.
        _sendFunds(fundingRecipient, address(this).balance);
    }

    function feeAmount(uint256 amount) public view returns (uint256) {
        return (feePercentage * amount) / 10000;
    }

    // ============ Admin Methods ============

    function changeBaseURI(string memory baseURI_) public onlyGovernance {
        baseURI = baseURI_;
    }

    // ============ Drop Distribution Methods ============

    function purchaseWithProof(
        address account,
        uint256 allocation,
        uint256 price,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable {
        require(price * allocation <= msg.value, "insufficient funds");

        require(
            !isClaimed(index, account),
            "already claimed"
        );

        setClaimed(index, account);

        require(
            verifyProof(
                merkleProof,
                merkleRoot,
                getNode(index, price, account, allocation)
            ),
            "invalid proof"
        );

        // "MINT"
        indexToClaimer[currentIndexId] = account;
        currentIndexId += 1;
        claimerToAllocation[account] = allocation;
        claimedTokens += allocation;
        _balances[account] += allocation;

        emit ConsecutiveTransfer(
            nextTokenId,
            nextTokenId + allocation - 1,
            address(0),
            account
        );

        nextTokenId += allocation;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        
        // Check if we are referring to a token that was preallocated.
        if (tokenId < allocation) {
            // It may have not been claimed.
            require(tokenId < claimedTokens, "nonexistent");

            // Check if this token was allocated but then burned.
            require(!burned[tokenId], "nonexistent");

            // Check if this token was allocated and then transferred.
            if (_owners[tokenId] != address(0)) {
                // The token was allocated, but then transferred.
                return _owners[tokenId];
            }
            
            // The token has been claimed and not transferred!
            // We need to find the claimer from this tokenId.
            uint256 indexTracker;
            for (uint256 i = 0; i < currentIndexId; i++) {
                address claimer = indexToClaimer[i];
                indexTracker += claimerToAllocation[claimer];
                if (tokenId < indexTracker) {
                    return claimer;
                }
            }
        }
        
        owner = _owners[tokenId];

        require(owner != address(0), "nonexistent");
    }


    function isClaimed(uint256 index, address account)
        public
        view
        returns (bool)
    {
        return claimed[getClaimHash(index, account)];
    }

    function setClaimed(uint256 index, address account) private {
        claimed[getClaimHash(index, account)] = true;
    }

    function getClaimHash(uint256 index, address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(index, account));
    }

    function getNode(uint256 index, uint256 price, address account, uint256 allocation)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, allocation, price, index));
    }

    // From https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
    function verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) private pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }


    // ============ Private Methods ============

    /// @notice from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
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

    function _sendFunds(address payable recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "recipient reverted");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        if (tokenId < allocation && !_burned[tokenId]) {
            return true;
        }

        return _owners[tokenId] != address(0);
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        if (_balances[owner_] > 0) {
            _balances[owner_] -= 1;
        }
        delete _owners[tokenId];

        _burned[tokenId] = true;

        emit Transfer(owner_, address(0), tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal pure returns (string memory) {
        return "";
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "non ERC721Receiver"
        );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "nonexistent"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "zero address");
        require(!_exists(tokenId), "already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "token not owned"
        );
        require(
            to != address(0),
            "zero address"
        );

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        if (_balances[from] > 0) {
            _balances[from] -= 1;
        }

        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
                        "non ERC721Receiver"
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

    /// @notice from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/Address.sol
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
pragma solidity 0.8.6;

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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
pragma solidity 0.8.6;

interface IERC2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

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
pragma solidity 0.8.6;

import {Ownable} from "../lib/Ownable.sol";
import {IGovernable} from "../lib/interface/IGovernable.sol";

contract InitializedGovernable is Ownable, IGovernable {
    // ============ Events ============

    event GovernorChanged(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    // ============ Mutable Storage ============

    // Mirror governance contract.
    address public override governor;

    // ============ Modifiers ============

    modifier onlyGovernance() {
        require(isOwner() || isGovernor(), "caller is not governance");
        _;
    }

    modifier onlyGovernor() {
        require(isGovernor(), "caller is not governor");
        _;
    }

    // ============ Constructor ============

    constructor(address owner_, address governor_) Ownable(owner_) {
        _setGovernor(governor_);
    }

    // ============ Administration ============

    function changeGovernor(address governor_) public override onlyGovernance {
        _setGovernor(governor_);
    }

    // ============ Utility Functions ============

    function isGovernor() public view override returns (bool) {
        return msg.sender == governor;
    }

    // ============ Internal Functions ============

    function _setGovernor(address governor_) internal {
        emit GovernorChanged(governor, governor_);

        governor = governor_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IPausableEvents {
    /// @notice Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @notice Emitted when the pause is lifted by `account`.
    event Unpaused(address account);
}

interface IPausable {
    function paused() external returns (bool);
}

contract Pausable is IPausable, IPausableEvents {
    bool public override paused;

    // Modifiers

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /// @notice Initializes the contract in unpaused state.
    constructor(bool paused_) {
        paused = paused_;
    }

    // ============ Internal Functions ============

    function _pause() internal whenNotPaused {
        paused = true;

        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        paused = false;

        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

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
pragma solidity 0.8.6;

/**
 * @title DroppableEditionsStorage
 * @author MirrorXYZ
 */
contract DroppableEditionsStorage {
    // ============ Structs ============

    /// @notice Contains general data about the NFT.
    struct NFTMetadata {
        string name;
        string symbol;
        string baseURI;
        bytes32 contentHash;
    }

    /// @notice Contains information pertaining to the edition spec.
    struct EditionData {
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        uint256 allocation;
        // The price at which each token will be sold, in ETH.
        uint256 price;
    }

    /// @notice Contains information about funds disbursement.
    struct AdminData {
        // Operator of this contract.
        address operator;
        bytes32 merkleRoot;
        // Address that receive gov tokens via treasury.
        address tributary;
        // The account that will receive sales revenue.
        address payable fundingRecipient;
        // The fee taken when withdrawing funds
        uint256 feePercentage;
    }

    // ============ Storage for Setup ============

    /// @notice NFTMetadata`
    string public baseURI;
    bytes32 contentHash;

    /// @notice EditionData
    uint256 public allocation;
    uint256 public quantity;
    uint256 public price;

    /// @notice EditionConfig
    address public operator;
    address public tributary;
    address payable public fundingRecipient;
    uint256 feePercentage;

    /// @notice Treasury Config, provided at setup, for finding the treasury address.
    address treasuryConfig;

    // ============ Mutable Runtime Storage ============

    /// @notice `nextTokenId` increments with each token purchased, globally across all editions.
    uint256 internal nextTokenId;
    /// @notice The number of tokens that have moved outside of the pre-mint allocation.
    uint256 internal allocationsTransferred = 0;

    /**
     * @notice A special mapping of burned tokens, to take care of burning within
     * the tokenId range of the allocation.
     */
    mapping(uint256 => bool) internal _burned;

    // ============ Mutable Internal NFT Storage ============

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @notice Only allow one purchase per account.
    mapping(address => bool) internal purchased;

    // OpenSea's Proxy Registry
    address public proxyRegistry;

    bytes32 public merkleRoot;

    uint256 currentTokenId;
    uint256 currentIndexId;
    uint256 claimedTokens;
    uint256 nonAllocatedPurchases = 0;

    mapping(uint256 => bool) public burned;

    mapping(uint256 => address) public indexToClaimer;
    mapping(address => uint256) public claimerToAllocation;

    mapping(bytes32 => bool) public claimed;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Allows to renounce upgrades
    bool public upgradesAllowed = true;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IDroppableEditionsLogicEvents {
    event EditionPurchased(
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver
    );

    event EditionCreatorChanged(
        address indexed previousCreator,
        address indexed newCreator
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IProxyRegistry {
    function proxies(address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

contract Ownable {
    address public owner;
    address private nextOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IGovernable {
    function changeGovernor(address governor_) external;

    function isGovernor() external view returns (bool);

    function governor() external view returns (address);
}

