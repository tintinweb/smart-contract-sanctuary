// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC721MerkleDrop} from "./interface/IERC721MerkleDrop.sol";
import {Ownable} from "../lib/Ownable.sol";
import {Pausable} from "../lib/Pausable.sol";
import {Reentrancy} from "../lib/Reentrancy.sol";
import {IERC721, IERC721Events} from "../lib/ERC721/interface/IERC721.sol";
import {IMirrorFeeConfig} from "../fee-config/MirrorFeeConfig.sol";
import {ITreasuryConfig} from "../treasury/interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../treasury/interface/IMirrorTreasury.sol";

/**
 * @title ERC721MerkleDrop
 * @author MirrorXYZ
 */
contract ERC721MerkleDrop is
    IERC721MerkleDrop,
    Ownable,
    Pausable,
    Reentrancy,
    IERC721Events
{
    /// @notice Address for factory that deploys clones
    address public immutable factory;

    /// @notice Address for Mirror's fee configuration
    address public immutable feeConfig;

    /// @notice Address for Mirror's treasury configuration
    address public immutable treasuryConfig;

    /// @notice Merkle root
    bytes32 public merkleRoot;

    /// @notice Claim deadline block
    uint256 public claimDeadline;

    /// @notice Funds recipient
    address public recipient;

    /// @notice ERC721 token address
    address public token;

    /// @notice ERC721 tokens holder
    address public tokenOwner;

    /// @notice Start token-id
    uint256 public startTokenId;

    /// @notice End token-id
    uint256 public endTokenId;

    /// @notice Current token-id
    uint256 public currentTokenId;

    /// @notice Map of claimed token hashes
    mapping(bytes32 => bool) public claimed;

    constructor(
        address factory_,
        address feeConfig_,
        address treasuryConfig_
    ) Ownable(address(0)) Pausable(true) {
        factory = factory_;
        feeConfig = feeConfig_;
        treasuryConfig = treasuryConfig_;
    }

    function initialize(
        address owner_,
        bool paused_,
        bytes32 merkleRoot_,
        uint256 claimDeadline_,
        address recipient_,
        address token_,
        address tokenOwner_,
        uint256 startTokenId_,
        uint256 endTokenId_
    ) external override {
        // ensure that this function is only callable by the factory
        require(msg.sender == factory, "unauthorized caller");

        // set owner
        _setOwner(address(0), owner_);

        // set pause status
        if (paused_) {
            _pause();
        }

        // set merkle-root
        merkleRoot = merkleRoot_;

        // set claim deadline
        claimDeadline = claimDeadline_;

        // set recipient
        recipient = recipient_;

        // set erc721 token address
        token = token_;

        // set address that owns the tokens
        tokenOwner = tokenOwner_;

        // set start and end token-ids
        startTokenId = startTokenId_;
        endTokenId = endTokenId_;

        // set currentTokenId
        currentTokenId = startTokenId_;
    }

    /// @notice Update claim deadline
    function setClaimDeadline(uint256 newClaimDeadline)
        external
        override
        onlyOwner
    {
        emit UpdateClaimDeadline(claimDeadline, newClaimDeadline);

        // set claim deadline
        claimDeadline = newClaimDeadline;
    }

    /// @notice Pause claiming
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice Unpause claiming
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @notice Cancel drop.
    /// @dev Pauses claiming, removes owner and withdraws
    function cancel(uint16 feePercentage_) external override onlyOwner {
        if (!paused) {
            _pause();
        }

        _renounceOwnership();

        _withdraw(feePercentage_);
    }

    /// @notice Number of claimed tokens
    function claimedTokens() external view override returns (uint256) {
        return currentTokenId - startTokenId;
    }

    /// @notice Claim tokens
    function claim(
        address account,
        uint256 allocation,
        uint256 price,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        // assert claim deadline has not passed
        require(block.number <= claimDeadline, "claim deadline has passed");

        // assert enough funds are sent to cover the cost
        require(price * allocation <= msg.value, "insufficient funds");

        // assert there are enough tokens left to claim allocation amount
        require(
            currentTokenId + allocation <= endTokenId + 1,
            "insufficient tokens"
        );

        // assert account has not claimed already
        require(!isClaimed(index, account), "already claimed");

        // store account claim
        _setClaimed(index, account);

        // assert proof is valid
        require(
            _verifyProof(
                merkleProof,
                merkleRoot,
                _getNode(index, price, account, allocation)
            ),
            "invalid proof"
        );

        // transfer tokens
        for (uint256 i = 0; i < allocation; i++) {
            IERC721(token).transferFrom(tokenOwner, account, currentTokenId++);
        }
    }

    function isClaimed(uint256 index, address account)
        public
        view
        returns (bool)
    {
        return claimed[_getClaimHash(index, account)];
    }

    /// @notice Withdraw funds
    function withdraw(uint16 feePercentage_) external override nonReentrant {
        _withdraw(feePercentage_);
    }

    // ============ Internal Functions ============
    function _withdraw(uint16 feePercentage_) internal {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            // assert that the fee is valid
            require(
                IMirrorFeeConfig(feeConfig).isFeeValid(feePercentage_),
                "invalid fee"
            );

            // calculate the fee on the current balance, using the fee percentage
            uint256 fee = _feeAmount(balance, feePercentage_);

            // if the fee is not zero, attempt to send it to the treasury
            if (fee != 0) {
                IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury())
                    .contribute{value: fee}(fee);
            }
            // broadcast the withdrawal event – with balance and fee
            emit Withdrawal(recipient, address(this).balance, fee);

            // transfer the remaining balance to the recipient
            _sendEther(payable(recipient), address(this).balance);
        }
    }

    function _feeAmount(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }

    function _sendEther(address payable recipient_, uint256 amount) internal {
        // Ensure sufficient balance.
        require(address(this).balance >= amount, "insufficient balance");
        // Send the value.
        (bool success, ) = recipient_.call{value: amount}("");
        require(success, "recipient reverted");
    }

    function _setClaimed(uint256 index, address account) internal {
        claimed[_getClaimHash(index, account)] = true;
    }

    function _getClaimHash(uint256 index, address account)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(index, account));
    }

    function _getNode(
        uint256 index,
        uint256 price,
        address account,
        uint256 allocation
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allocation, price, index));
    }

    // From https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
    function _verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC721MerkleDrop {
    event UpdateClaimDeadline(
        uint256 oldClaimDeadline,
        uint256 newClaimDeadline
    );

    event Withdrawal(address recipient, uint256 amount, uint256 fee);

    function initialize(
        address owner_,
        bool paused_,
        bytes32 merkleRoot_,
        uint256 claimDeadline_,
        address recipient_,
        address token_,
        address tokenOwner_,
        uint256 startTokenId_,
        uint256 endTokenId_
    ) external;

    function claim(
        address account,
        uint256 allocation,
        uint256 price,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable;

    function setClaimDeadline(uint256 claimDeadline_) external;

    function pause() external;

    function unpause() external;

    function cancel(uint16 feePercentage_) external;

    function claimedTokens() external view returns (uint256);

    function withdraw(uint16 feePercentage_) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

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

import {Ownable} from "../lib/Ownable.sol";

interface IMirrorFeeConfig {
    function maxFee() external returns (uint16);

    function minFee() external returns (uint16);

    function isFeeValid(uint16) external view returns (bool);

    function updateMaxFee(uint16 newFee) external;

    function updateMinFee(uint16 newFee) external;
}

/**
 * @title MirrorFeeConfig
 * @author MirrorXYZ
 */
contract MirrorFeeConfig is IMirrorFeeConfig, Ownable {
    uint16 public override maxFee = 500;
    uint16 public override minFee = 250;

    constructor(address owner_) Ownable(owner_) {}

    function updateMaxFee(uint16 newFee) external override onlyOwner {
        maxFee = newFee;
    }

    function updateMinFee(uint16 newFee) external override onlyOwner {
        minFee = newFee;
    }

    function isFeeValid(uint16 fee)
        external
        view
        returns (bool isBeweenMinAndMax)
    {
        isBeweenMinAndMax = (minFee <= fee) && (fee <= maxFee);
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