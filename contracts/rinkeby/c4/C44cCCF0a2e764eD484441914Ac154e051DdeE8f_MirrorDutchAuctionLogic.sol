// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IMirrorDutchAuctionLogic} from "./interface/IMirrorDutchAuctionLogic.sol";
import {Ownable} from "../../lib/Ownable.sol";
import {Pausable} from "../../lib/Pausable.sol";
import {IERC721, IERC721Events} from "../../external/interface/IERC721.sol";
import {ITreasuryConfig} from "../../interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../interface/IMirrorTreasury.sol";
import {Reentrancy} from "../../lib/Reentrancy.sol";

/**
 * @title MirrorDutchAuctionLogic
 * @author MirrorXYZ
 *
 * This contract implements a simple Dutch Auction system.
 * The auction works as follows:
 *  - Generate a list of numbers that represent all the prices at which
 *    the assets are offered. The first item is the highest price, the last
 *    item is the lowest price.
 *  - Set a time interval that represents how much time will elapse between price changes.
 *  - After the auction starts, every bid pays the price at the time that their transaction
 *    mines and receives their asset.
 *
 * The auction can be paused and unpaused by the owner without affecting the price mechanism.
 * The auction has a "cancel" functionality that withdraws all funds (paying a fee) and
 * renounces ownership which ensures that the auction cannot be restarted again.
 * The auction assumes that tokenIds of the assets transfered are sequential, beginning at
 * "startTokenId" and ending at "endTokenId".
 * The auction uses blocks as the unit for the interval.
 */
contract MirrorDutchAuctionLogic is
    IMirrorDutchAuctionLogic,
    Ownable,
    Pausable,
    Reentrancy,
    IERC721Events
{
    /// @notice Set a list of prices
    uint256[] public override prices;

    /// @notice Set the time interval in blocks
    uint256 public override interval;

    /// @notice Set the current tokenId
    uint256 public override tokenId;

    /// @notice Set the last tokenId
    uint256 public override endTokenId;

    /// @notice Set total time elapsed since auction started
    uint256 public override globalTimeElapsed;

    /// @notice Set the recipient of the funds for withdrawals
    address public override recipient;

    /// @notice Set whether an account has purchased
    mapping(address => bool) public override purchased;

    /// @notice Set the block at which auction started
    uint256 public override auctionStartBlock;

    /// @notice Set the block at which auction was paused, only set if auction has started
    uint256 public override pauseBlock;

    /// @notice Set the block at which auction was unpaused
    uint256 public override unpauseBlock;

    /// @notice Set the contract that holds the NFTs
    address public override nft;

    /// @notice Set the ending price
    uint256 public override endingPrice;

    /// @notice Set the contract that holds the treasury configuration
    address public treasuryConfig;

    modifier onlyOnce() {
        require(!purchased[msg.sender], "already purchased");
        _;
    }

    constructor(address owner_) Ownable(owner_) Pausable(true) {}

    /// @notice Get a list of all prices
    function getAllPrices() external view override returns (uint256[] memory) {
        return prices;
    }

    /**
     * @dev This contract is used as the logic for proxies. Hence we include
     * the ability to call "initialize" when deploying a proxy to set initial
     * variables without having to define them and implement in the proxy's
     * constructor. This function reverts if called after deployment.
     */
    function initialize(
        address owner_,
        address treasuryConfig_,
        IMirrorDutchAuctionLogic.AuctionConfig memory auctionConfig_
    ) external override {
        // Ensure that this function is only callable during contract construction
        assembly {
            if extcodesize(address()) {
                revert(0, 0)
            }
        }

        // ensure auction is paused
        _pause();

        // set owner
        _setOwner(address(0), owner_);

        // set treasury config
        treasuryConfig = treasuryConfig_;

        // save auction configuration
        prices = auctionConfig_.prices;
        interval = auctionConfig_.interval;
        recipient = auctionConfig_.recipient;
        tokenId = auctionConfig_.startTokenId;
        endTokenId = auctionConfig_.endTokenId;
        nft = auctionConfig_.nft;
    }

    /// @notice Pause auction
    function pause() external override whenNotPaused onlyOwner {
        // Auction has started
        if (auctionStartBlock > 0) {
            globalTimeElapsed = _currentTimeElapsed();

            pauseBlock = block.number;
        }

        _pause();
    }

    /// @notice Unpause auction
    function unpause() external override whenPaused onlyOwner {
        _unpause();

        unpauseBlock = block.number;
    }

    /// @notice Withdraw all funds and destroy contract
    function cancel() external override onlyOwner {
        _withdraw();

        _pause();

        _renounceOwnership();
    }

    /// @notice Set auctionStartBlock and unpause
    function startAuction() external override onlyOwner {
        require(auctionStartBlock == 0, "already started");

        auctionStartBlock = block.number;

        if (paused) {
            _unpause();
        }
    }

    /// @notice Current price. Zero if auction has not started.
    function price() external view override returns (uint256) {
        return _currentPrice();
    }

    /**
     * @notice Bid for an NFT. If the price is met transfer NFT to sender.
     * If price drops before the transaction mines, refund value.
     */
    function bid()
        external
        payable
        override
        nonReentrant
        whenNotPaused
        onlyOnce
    {
        require(auctionStartBlock > 0, "auction has not started");

        require(tokenId <= endTokenId, "auction sold out");

        uint256 currentPrice = _currentPrice();

        require(msg.value >= currentPrice, "insufficient funds");

        // transfer NFT
        IERC721(nft).transferFrom(owner, msg.sender, tokenId);

        emit Bid(msg.sender, currentPrice, tokenId);

        tokenId++;

        purchased[msg.sender] = true;

        // refund excess eth when price decrease before the transaction mines
        if (msg.value > currentPrice) {
            _transferEther(payable(msg.sender), msg.value - currentPrice);
        }

        // snapshot the ending price
        if (tokenId > endTokenId) {
            endingPrice = currentPrice;
        }
    }

    /// @notice Withdraw all funds, and pay fee
    function withdraw() external override nonReentrant {
        _withdraw();
    }

    //======== Internal Methods =========
    function _currentPrice() internal view returns (uint256) {
        // auction has not started
        if (auctionStartBlock == 0) {
            return 0;
        }

        // if ending price has been set i.e. all nfts are sold
        if (endingPrice != 0) {
            return endingPrice;
        }

        uint256 timeElapsed = _currentTimeElapsed();

        uint256 priceIndex = timeElapsed / interval;

        // price becomes the reserve price i.e. last in the list of prices
        if (priceIndex >= prices.length) {
            return prices[prices.length - 1];
        }

        return prices[priceIndex];
    }

    function _currentTimeElapsed() internal view returns (uint256 timeElapsed) {
        // if auction has been paused before
        // if not return time elapse since the start of the auction
        if (pauseBlock > 0) {
            // if currently paused return global time elapsed, which is saved when pausing
            // if not return global time elapsed, plus time elapsed since it was unpaused
            if (paused) {
                timeElapsed = globalTimeElapsed;
            } else {
                timeElapsed = globalTimeElapsed + (block.number - unpauseBlock);
            }
        } else {
            timeElapsed = block.number - auctionStartBlock;
        }
    }

    function _withdraw() internal {
        uint256 feePercentage = 250;

        uint256 fee = _feeAmount(address(this).balance, feePercentage);

        IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury()).contribute{
            value: fee
        }(fee);

        // transfer the remaining available balance to the recipient
        uint256 withdrawalAmount = address(this).balance;

        _transferEther(payable(recipient), withdrawalAmount);

        emit Withdrawal(recipient, withdrawalAmount, fee);
    }

    function _feeAmount(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }

    function _transferEther(address payable account, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "insufficient balance for send"
        );

        (bool success, ) = account.call{value: amount}("");
        require(success, "unable to send value: recipient may have reverted");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorDutchAuctionLogic {
    /// @notice Emitted when a withdrawal takes place.
    event Withdrawal(address recipient, uint256 amount, uint256 fee);

    /// @notice Emitted when a bid takes place.
    event Bid(address recipient, uint256 price, uint256 tokenId);

    struct AuctionConfig {
        uint256[] prices;
        uint256 interval;
        uint256 startTokenId;
        uint256 endTokenId;
        address recipient;
        address nft;
    }

    /// @notice Get a list of prices
    function prices(uint256 index) external returns (uint256);

    /// @notice Get the time interval in blocks
    function interval() external returns (uint256);

    /// @notice Get the current tokenId
    function tokenId() external returns (uint256);

    /// @notice Get the last tokenId
    function endTokenId() external returns (uint256);

    /// @notice Get total time elapsed since auction started
    function globalTimeElapsed() external returns (uint256);

    /// @notice Get the recipient of the funds for withdrawals
    function recipient() external returns (address);

    /// @notice Get whether an account has purchased
    function purchased(address account) external returns (bool);

    /// @notice Get the block at which auction started
    function auctionStartBlock() external returns (uint256);

    /// @notice Get the block at which auction was paused, only set if auction has started
    function pauseBlock() external returns (uint256);

    /// @notice Get the block at which auction was unpaused
    function unpauseBlock() external returns (uint256);

    /// @notice Get the contract that holds the NFTs
    function nft() external returns (address);

    /// @notice Get the ending price
    function endingPrice() external returns (uint256);

    /// @notice Get the contract that holds the treasury configuration
    function getAllPrices() external returns (uint256[] memory);

    /**
     * @dev This contract is used as the logic for proxies. Hence we include
     * the ability to call "initialize" when deploying a proxy to set initial
     * variables without having to define them and implement in the proxy's
     * constructor. This function reverts if called after deployment.
     */
    function initialize(
        address owner_,
        address treasuryConfig_,
        IMirrorDutchAuctionLogic.AuctionConfig memory auctionConfig_
    ) external;

    /// @notice Pause auction
    function pause() external;

    /// @notice Unpause auction
    function unpause() external;

    /// @notice Withdraw all funds and destroy contract
    function cancel() external;

    /// @notice Set auctionStartBlock and unpause
    function startAuction() external;

    /// @notice Current price. Zero if auction has not started.
    function price() external view returns (uint256);

    /**
     * @notice Bid for an NFT. If the price is met transfer NFT to sender.
     * If price drops before the transaction mines, refund value.
     */
    function bid() external payable;

    /// @notice Withdraw all funds, and pay fee
    function withdraw() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

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
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
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

interface IERC721Royalties {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
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