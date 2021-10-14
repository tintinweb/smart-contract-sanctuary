// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {OurSplitter} from "./OurSplitter.sol";
import {OurMinter} from "./OurMinter.sol";
import {OurIntrospector} from "./OurIntrospector.sol";

/**
 * @title OurPylon
 * @author Nick Adamson - [email protected]
 *
 * Building on the work from:
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * & of course, @author OpenZeppelin
 */
contract OurPylon is OurSplitter, OurMinter, OurIntrospector {
    // Disables modification of Pylon after deployment
    constructor() {
        threshold = 1;
    }

    /**
     * @dev Setup function sets initial storage of Poxy.
     * @param owners_ List of addresses that can execute transactions other than claiming funds.
     * @notice see OurManagement.sol -> setupOwners()
     * @notice approves Zora AH to handle Zora ERC721s
     */
    function setup(address[] calldata owners_) external {
        setupOwners(owners_);
        emit ProxySetup(owners_);

        // Approve Zora AH
        _setApprovalForAH();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {OurStorage} from "./OurStorage.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

/**
 * @title OurSplitter
 * @author Nick Adamson - [email protected]
 *
 * Building on the work from:
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * & of course, @author OpenZeppelin
 */
contract OurSplitter is OurStorage {
    struct Proof {
        bytes32[] merkleProof;
    }

    uint256 public constant PERCENTAGE_SCALE = 10e5;

    /**======== Subgraph =========
     * ETHReceived - emits sender and value in receive() fallback
     * WindowIncremented - emits current claim window, and available value of ETH
     * TransferETH - emits to address, value, and success bool
     * TransferERC20 - emits token's contract address and total transferred amount
     */
    event ETHReceived(address indexed sender, uint256 value);
    event WindowIncremented(uint256 currentWindow, uint256 fundsAvailable);
    event TransferETH(address account, uint256 amount, bool success);
    event TransferERC20(address token, uint256 amount);

    // Plain ETH transfers
    receive() external payable {
        _depositedInWindow += msg.value;
        emit ETHReceived(msg.sender, msg.value);
    }

    function claimETH(
        uint256 window,
        address account,
        uint256 scaledPercentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        require(currentWindow > window, "cannot claim for a future window");
        require(
            !isClaimed(window, account),
            "Account already claimed the given window"
        );

        _setClaimed(window, account);

        require(
            _verifyProof(
                merkleProof,
                merkleRoot,
                _getNode(account, scaledPercentageAllocation)
            ),
            "Invalid proof"
        );

        _transferETHOrWETH(
            account,
            // The absolute amount that's claimable.
            scaleAmountByPercentage(
                balanceForWindow[window],
                scaledPercentageAllocation
            )
        );
    }

    /**
     * @dev Attempts transferring entire balance of an ERC20 to corresponding Recipients
     * @notice if amount of tokens are not equally divisible according to allocation
     * the remainder will be forwarded to accounts[0].
     * In most cases, the difference will be negligible:
     *      ~remainder × 10^-17,
     *      or about 0.000000000000000100 at most.
     * @notice iterating through an array to push payments goes agains best practices,
     *         therefore it is advised to avoid accepting ERC-20 payments.
     */
    function claimERC20ForAll(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata allocations,
        Proof[] calldata merkleProofs
    ) external {
        require(
            _verifyProof(
                merkleProofs[0].merkleProof,
                merkleRoot,
                _getNode(accounts[0], allocations[0])
            ),
            "Invalid proof for Account 0"
        );

        uint256 erc20Balance = IERC20(tokenAddress).balanceOf(address(this));

        for (uint256 i = 1; i < accounts.length; i++) {
            require(
                _verifyProof(
                    merkleProofs[i].merkleProof,
                    merkleRoot,
                    _getNode(accounts[i], allocations[i])
                ),
                "Invalid proof"
            );

            uint256 scaledAmount = scaleAmountByPercentage(
                erc20Balance,
                allocations[i]
            );
            _attemptERC20Transfer(tokenAddress, accounts[i], scaledAmount);
        }

        _attemptERC20Transfer(
            tokenAddress,
            accounts[0],
            IERC20(tokenAddress).balanceOf(address(this))
        );

        emit TransferERC20(tokenAddress, erc20Balance);
    }

    function claimETHForAllWindows(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        // Make sure that the user has this allocation granted.
        require(
            _verifyProof(
                merkleProof,
                merkleRoot,
                _getNode(account, percentageAllocation)
            ),
            "Invalid proof"
        );

        uint256 amount = 0;
        for (uint256 i = 0; i < currentWindow; i++) {
            if (!isClaimed(i, account)) {
                _setClaimed(i, account);

                amount += scaleAmountByPercentage(
                    balanceForWindow[i],
                    percentageAllocation
                );
            }
        }

        _transferETHOrWETH(account, amount);
    }

    function incrementThenClaimAll(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        incrementWindow();
        _claimAll(account, percentageAllocation, merkleProof);
    }

    function incrementWindow() public {
        uint256 fundsAvailable;

        if (currentWindow == 0) {
            fundsAvailable = address(this).balance;
        } else {
            // Current Balance, subtract previous balance to get the
            // funds that were added for this window.
            fundsAvailable = _depositedInWindow;
        }

        _depositedInWindow = 0;
        require(fundsAvailable > 0, "No additional funds for window");
        balanceForWindow.push(fundsAvailable);
        currentWindow += 1;
        emit WindowIncremented(currentWindow, fundsAvailable);
    }

    function isClaimed(uint256 window, address account)
        public
        view
        returns (bool)
    {
        return _claimed[_getClaimHash(window, account)];
    }

    function scaleAmountByPercentage(uint256 amount, uint256 scaledPercent)
        public
        pure
        returns (uint256 scaledAmount)
    {
        /* Example:
                BalanceForWindow = 100 ETH // Allocation = 2%
                To find out the amount we use, for example: (100 * 200) / (100 * 100)
                which returns 2 -- i.e. 2% of the 100 ETH balance.
         */
        scaledAmount = (amount * scaledPercent) / (100 * PERCENTAGE_SCALE);
    }

    /// @notice same as claimETHForAllWindows() but marked private for use in incrementThenClaimAll()
    function _claimAll(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) private {
        // Make sure that the user has this allocation granted.
        require(
            _verifyProof(
                merkleProof,
                merkleRoot,
                _getNode(account, percentageAllocation)
            ),
            "Invalid proof"
        );

        uint256 amount = 0;
        for (uint256 i = 0; i < currentWindow; i++) {
            if (!isClaimed(i, account)) {
                _setClaimed(i, account);

                amount += scaleAmountByPercentage(
                    balanceForWindow[i],
                    percentageAllocation
                );
            }
        }

        _transferETHOrWETH(account, amount);
    }

    //======== Private Functions ========
    function _setClaimed(uint256 window, address account) private {
        _claimed[_getClaimHash(window, account)] = true;
    }

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function _transferETHOrWETH(address to, uint256 value)
        private
        returns (bool didSucceed)
    {
        // Try to transfer ETH to the given recipient.
        didSucceed = _attemptETHTransfer(to, value);
        if (!didSucceed) {
            // If the transfer fails, wrap and send as WETH, so that
            // the auction is not impeded and the recipient still
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(WETH).deposit{value: value}();
            IWETH(WETH).transfer(to, value);
            // At this point, the recipient can unwrap WETH.
            didSucceed = true;
        }

        emit TransferETH(to, value, didSucceed);
    }

    function _attemptETHTransfer(address to, uint256 value)
        private
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt  a limited reentrancy attack.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value, gas: 30000}("");
        return success;
    }

    /**
     * @dev Transfers ERC20s
     * @notice Reverts entire transaction if one fails
     * @notice A rogue owner could easily bypass countermeasures. Provided as last resort,
     * in case Proxy receives ERC20.
     */
    function _attemptERC20Transfer(
        address tokenAddress,
        address splitRecipient,
        uint256 allocatedAmount
    ) private {
        bool didSucceed = IERC20(tokenAddress).transfer(
            splitRecipient,
            allocatedAmount
        );
        require(didSucceed);
    }

    function _getClaimHash(uint256 window, address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(window, account));
    }

    function _amountFromPercent(uint256 amount, uint32 percent)
        private
        pure
        returns (uint256)
    {
        // Solidity 0.8.0 lets us do this without SafeMath.
        return (amount * percent) / 100;
    }

    function _getNode(address account, uint256 percentageAllocation)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, percentageAllocation));
    }

    // From https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
    function _verifyProof(
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import {OurManagement} from "./OurManagement.sol";
import {IZora} from "./interfaces/IZora.sol";
import {IMirror} from "./interfaces/IMirror.sol";
import {IPartyBid} from "./interfaces/IPartyBid.sol";
import {IERC721} from "./interfaces/IERC721.sol";

/**
 * @title OurMinter
 * @author Nick Adamson - [email protected]
 *
 * Building on the work from:
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * & of course, @author OpenZeppelin
 *
 * @notice Some functions are marked as 'untrusted'Function. Use caution when interacting
 * with these, as any contracts you supply could be potentially unsafe.
 * 'Trusted' functions on the other hand -- implied by the absence of 'untrusted' --
 * are hardcoded to use the Zora Protocol/MirrorXYZ/PartyDAO addresses.
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#mark-untrusted-contracts
 */
contract OurMinter is OurManagement {
    /// @notice RINKEBY ADDRESSES
    address public constant ZORA_MEDIA =
        0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;
    address public constant ZORA_MARKET =
        0x85e946e1Bd35EC91044Dc83A5DdAB2B6A262ffA6;
    address public constant ZORA_AH =
        0xE7dd1252f50B3d845590Da0c5eADd985049a03ce;
    address public constant ZORA_EDITIONS =
        0x5d6E1357Acc8BF654979f3b24fdef8C5549A491e;
    address public constant MIRROR_CROWDFUND =
        0xeac226B370D77f436b5780b4DD4A49E59e8bEA37;

    //======== Subgraph =========
    event ZNFTMinted(uint256 tokenId);
    event EditionCreated(
        address editionAddress,
        string name,
        string symbol,
        string description,
        string animationUrl,
        string imageUrl,
        uint256 editionSize,
        uint256 royaltyBPS
    );

    /**======== IZora =========
     * @notice Various functions allowing a Split to interact with Zora Protocol
     * @dev see IZora.sol
     * Media -> Market -> AH -> Editions -> QoL Functions
     */

    /** Media
     * @notice Mint new Zora NFT for Split Contract.
     */
    function mintZNFT(
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares
    ) external onlyOwners {
        IZora(ZORA_MEDIA).mint(mediaData, bidShares);
        emit ZNFTMinted(_getID());
    }

    /** Media
     * @notice EIP-712 mintWithSig. Mints new new Zora NFT for a creator on behalf of split contract.
     */
    function mintZNFTWithSig(
        address creator,
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares,
        IZora.EIP712Signature calldata sig
    ) external onlyOwners {
        IZora(ZORA_MEDIA).mintWithSig(creator, mediaData, bidShares, sig);
        emit ZNFTMinted(_getID());
    }

    /** Media
     * @notice Update the token URIs for a Zora NFT owned by Split Contract
     */
    function updateZNFTURIs(
        uint256 tokenId,
        string calldata tokenURI,
        string calldata metadataURI
    ) external onlyOwners {
        IZora(ZORA_MEDIA).updateTokenURI(tokenId, tokenURI);
        IZora(ZORA_MEDIA).updateTokenMetadataURI(tokenId, metadataURI);
    }

    /** Media
     * @notice Update the token URI
     */
    function updateZNFTTokenURI(uint256 tokenId, string calldata tokenURI)
        external
        onlyOwners
    {
        IZora(ZORA_MEDIA).updateTokenURI(tokenId, tokenURI);
    }

    /** Media
     * @notice Update the token metadata uri
     */
    function updateZNFTMetadataURI(uint256 tokenId, string calldata metadataURI)
        external
    {
        IZora(ZORA_MEDIA).updateTokenMetadataURI(tokenId, metadataURI);
    }

    /** Market
     * @notice Update zora/core/market bidShares (NOT zora/auctionHouse)
     */
    function setZMarketBidShares(
        uint256 tokenId,
        IZora.BidShares calldata bidShares
    ) external {
        IZora(ZORA_MARKET).setBidShares(tokenId, bidShares);
    }

    /** Market
     * @notice Update zora/core/market ask
     */
    function setZMarketAsk(uint256 tokenId, IZora.Ask calldata ask)
        external
        onlyOwners
    {
        IZora(ZORA_MARKET).setAsk(tokenId, ask);
    }

    /** Market
     * @notice Remove zora/core/market ask
     */
    function removeZMarketAsk(uint256 tokenId) external onlyOwners {
        IZora(ZORA_MARKET).removeAsk(tokenId);
    }

    /** Market
     * @notice Accept zora/core/market bid
     */
    function acceptZMarketBid(uint256 tokenId, IZora.Bid calldata expectedBid)
        external
        onlyOwners
    {
        IZora(ZORA_MARKET).acceptBid(tokenId, expectedBid);
    }

    /** AuctionHouse
     * @notice Create auction on Zora's AuctionHouse for an owned/approved NFT
     * @dev reccomended auctionCurrency: ETH or WETH
     *      ERC20s may not be split perfectly. If the amount is indivisible
     *      among ALL recipients, the remainder will be sent to a single recipient.
     */
    function createZoraAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    ) external onlyOwners {
        IZora(ZORA_AH).createAuction(
            tokenId,
            tokenContract,
            duration,
            reservePrice,
            curator,
            curatorFeePercentage,
            auctionCurrency
        );
    }

    /** AuctionHouse
     * @notice Approves an Auction proposal that requested the Split be the curator
     */
    function setZAuctionApproval(uint256 auctionId, bool approved)
        external
        onlyOwners
    {
        IZora(ZORA_AH).setAuctionApproval(auctionId, approved);
    }

    /** AuctionHouse
     * @notice Set an Auction's reserve price
     */
    function setZAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external
        onlyOwners
    {
        IZora(ZORA_AH).setAuctionReservePrice(auctionId, reservePrice);
    }

    /** AuctionHouse
     * @notice Cancel an Auction before any bids have been placed
     */
    function cancelZAuction(uint256 auctionId) external onlyOwners {
        IZora(ZORA_AH).cancelAuction(auctionId);
    }

    /** NFT-Editions
     * @notice Creates a new edition contract as a factory with a deterministic address
     * @dev also approves the Owner that called this as a minter.
     */
    function createZoraEdition(
        string memory name,
        string memory symbol,
        string memory description,
        string memory animationUrl,
        bytes32 animationHash,
        string memory imageUrl,
        bytes32 imageHash,
        uint256 editionSize,
        uint256 royaltyBPS
    ) external onlyOwners {
        uint256 editionId = IZora(ZORA_EDITIONS).createEdition(
            name,
            symbol,
            description,
            animationUrl,
            animationHash,
            imageUrl,
            imageHash,
            editionSize,
            royaltyBPS
        );

        address editionAddress = IZora(ZORA_EDITIONS).getEditionAtId(editionId);

        IZora(editionAddress).setApprovedMinter(msg.sender, true);

        emit EditionCreated(
            editionAddress,
            name,
            symbol,
            description,
            animationUrl,
            imageUrl,
            editionSize,
            royaltyBPS
        );
    }

    /** NFT-Editions
      @param minter address to set approved minting status for
      @param allowed boolean if that address is allowed to mint
      @dev Sets the approved minting status of the given address.
           This requires that msg.sender is the owner of the given edition id.
           If the ZeroAddress (address(0x0)) is set as a minter,
           anyone will be allowed to mint.
           This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setEditionMinter(address minter, bool allowed)
        external
        onlyOwners
    {
        IZora(ZORA_EDITIONS).setApprovedMinter(minter, allowed);
    }

    /** NFT-Editions
      @dev Allows for updates of edition urls by the owner of the edition.
           Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function setEditionURLs(string memory imageUrl, string memory animationUrl)
        external
        onlyOwners
    {
        IZora(ZORA_EDITIONS).updateEditionURLs(imageUrl, animationUrl);
    }

    /** QoL
     * @notice Approve the Zora Auction House to manage Split's ERC-721s
     * @dev Called internally in Proxy's Constructo
     */
    /* solhint-disable ordering */
    function _setApprovalForAH() internal {
        IERC721(ZORA_MEDIA).setApprovalForAll(ZORA_AH, true);
    }

    /** QoL
     * @notice Mints a Zora NFT with this Split as the Creator,
     * and then list it on AuctionHouse for ETH
     */
    function mintToAuctionForETH(
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares,
        uint256 duration,
        uint256 reservePrice
    ) external onlyOwners {
        IZora(ZORA_MEDIA).mint(mediaData, bidShares);

        uint256 tokenId_ = _getID();
        emit ZNFTMinted(tokenId_);

        IZora(ZORA_AH).createAuction(
            tokenId_,
            ZORA_MEDIA,
            duration,
            reservePrice,
            payable(address(this)),
            0,
            address(0)
        );
    }

    //======== /IZora =========
    /* solhint-enable ordering */

    /**======== IMirror =========
     * @notice Create a Crowdfund
     * @dev see IMirror.sol
     */
    function createMirrorCrowdfund(
        string calldata name,
        string calldata symbol,
        address payable operator,
        address payable fundingRecipient,
        uint256 fundingCap,
        uint256 operatorPercent
    ) external onlyOwners {
        IMirror(MIRROR_CROWDFUND).createCrowdfund(
            name,
            symbol,
            operator,
            fundingRecipient,
            fundingCap,
            operatorPercent
        );
    }

    //======== /IMirror =========

    /**======== IERC721 =========
     * NOTE: Althought OurMinter.sol is generally implemented to work with Zora,
     *       the functions below allow a Split to work with any ERC-721 spec'd platform;
     *       (except for minting, @dev 's see untrustedExecuteTransaction() below)
     * @dev see IERC721.sol
     */

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev In case non-Zora ERC721 gets stuck in Account.
     * @notice safeTransferFrom(address from, address to, uint256 tokenId)
     */
    function untrustedSafeTransferERC721(
        address tokenContract_,
        address newOwner_,
        uint256 tokenId_
    ) external onlyOwners {
        IERC721(tokenContract_).safeTransferFrom(
            address(this),
            newOwner_,
            tokenId_
        );
    }

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev sets approvals for non-Zora ERC721 contract
     * @notice setApprovalForAll(address operator, bool approved)
     */
    function untrustedSetApprovalERC721(
        address tokenContract_,
        address operator_,
        bool approved_
    ) external onlyOwners {
        IERC721(tokenContract_).setApprovalForAll(operator_, approved_);
    }

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev burns non-Zora ERC721 that Split contract owns/isApproved
     * @notice setApprovalForAll(address operator, bool approved)
     */
    function untrustedBurnERC721(address tokenContract_, uint256 tokenId_)
        external
        onlyOwners
    {
        IERC721(tokenContract_).burn(tokenId_);
    }

    //======== /IERC721 =========

    //======== PROCEEED WITH CAUTION =========
    /**
     * NOTE: Marked as >> untrusted << Avoid interacting with contracts you do not trust entirely.
     * @dev allows a Split Contract to call (non-payable) functions of any other contract
     * @notice This function is added for 'future-proofing' capabilities and will not be implemented into the
     *         OURZ frontend. The intent is to support the use of custom ERC721 creator contracts.
     * @notice In the interest of securing the Split's funds for Recipients from a rogue owner(OurManagement.sol),
     *         the msg.value is hardcoded to zero.
     */
    function untrustedExecuteTransaction(address to, bytes memory data)
        external
        onlyOwners
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(gas(), to, 0, add(data, 0x20), mload(data), 0, 0)
        }
    }

    //======== /PROCEEED WITH CAUTION =========

    /// @dev calculates tokenID of newly minted ZNFT
    function _getID() private returns (uint256 id) {
        id = IZora(ZORA_MEDIA).tokenByIndex(
            IZora(ZORA_MEDIA).totalSupply() - 1
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./interfaces/ERC1155TokenReceiver.sol";
import "./interfaces/ERC721TokenReceiver.sol";
import "./interfaces/ERC777TokensRecipient.sol";
import "./interfaces/IERC165.sol";

/**
 * @title OurIntrospector
 * @author Nick Adamson - [email protected]
 *
 * Building on the work from:
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * & of course, @author OpenZeppelin
 */
contract OurIntrospector is
    ERC1155TokenReceiver,
    ERC777TokensRecipient,
    ERC721TokenReceiver,
    IERC165
{
    //======== ERC721 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC721/IERC721Receiver.sol

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }

    //======== IERC1155 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC1155/IERC1155Receiver.sol

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    //======== IERC777 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC777/IERC777Recipient.sol
    //sol
    // solhint-disable-next-line ordering
    event ERC777Received(
        address operator,
        address from,
        address to,
        uint256 amount
    );

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external override {
        emit ERC777Received(operator, from, to, amount);
    }

    //======== IERC165 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/introspection/ERC165.sol
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title OurStorage
 * @author Nick Adamson - [email protected]
 *
 * Building on the work from:
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * & of course, @author OpenZeppelin
 */
contract OurStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal _pylon;

    /// @notice RINKEBY ADDRESS
    address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal _claimed;
    uint256 internal _depositedInWindow;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title OurManagement
 * @author Nick Adamson - [email protected]
 *
 * Building on the work from:
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * & of course, @author OpenZeppelin
 */
contract OurManagement {
    // used as origin pointer for linked list of owners
    /* solhint-disable private-vars-leading-underscore */
    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;
    /* solhint-enable private-vars-leading-underscore */

    event ProxySetup(address[] owners);
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event NameChanged(string newName);

    modifier onlyOwners() {
        // This is a function call as it minimized the bytecode size
        checkIsOwner(_msgSender());
        _;
    }

    /// @dev Allows to add a new owner
    function addOwner(address owner) public onlyOwners {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(
            owner != address(0) &&
                owner != SENTINEL_OWNERS &&
                owner != address(this)
        );
        // No duplicate owners allowed.
        require(owners[owner] == address(0));
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
    }

    /// @dev Allows to remove an owner
    function removeOwner(address prevOwner, address owner) public onlyOwners {
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS);
        require(owners[prevOwner] == owner);
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
    }

    /// @dev Allows to swap/replace an owner from the Proxy with another address.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) public onlyOwners {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(
            newOwner != address(0) &&
                newOwner != SENTINEL_OWNERS &&
                newOwner != address(this),
            "2"
        );
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "3");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "4");
        require(owners[prevOwner] == oldOwner, "5");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev for subgraph
    function editNickname(string calldata newName_) public onlyOwners {
        emit NameChanged(newName_);
    }

    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @dev Returns array of owners.
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }

    /**
     * @dev Setup function sets initial owners of contract.
     * @param owners_ List of Split Owners (can mint/manage auctions)
     * @notice threshold ensures that setup function can only be called once.
     */
    /* solhint-disable private-vars-leading-underscore */
    function setupOwners(address[] memory owners_) internal {
        require(threshold == 0, "Setup has already been completed once.");
        // Initializing Proxy owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < owners_.length; i++) {
            address owner = owners_[i];
            require(
                owner != address(0) &&
                    owner != SENTINEL_OWNERS &&
                    owner != address(this) &&
                    currentOwner != owner
            );
            require(owners[owner] == address(0));
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = owners_.length;
        threshold = 1;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function checkIsOwner(address caller_) internal view {
        require(
            isOwner(caller_),
            "Caller is not a whitelisted owner of this Split"
        );
    }
    /* solhint-enable private-vars-leading-underscore */
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title Interface for the entire Zora Protocol. Modified for OurMinter.sol
 * @author (s):
 * https://github.com/ourzora/
 *
 * @notice combination of Market, Media, and AuctionHouse contracts' interfaces.
 * @dev Some functions have been moved to more basic interfaces - eg IERCXXX.sol -
 * @dev to allow for the implementation of 'untrusted' universal functions in Minter.sol.
 * @dev They will work with Zora, with the additional benefit of working with other protocols.
 */
/* solhint-disable private-vars-leading-underscore, ordering */
interface IZora {
    /**
     * @title Interface for Decimal
     */
    struct D256 {
        uint256 value;
    }

    /**
     * @title Interface for Zora Protocol's Media
     */
    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct MediaData {
        // A valid URI of the content represented by this token
        string tokenURI;
        // A valid URI of the metadata associated with this token
        string metadataURI;
        // A SHA256 hash of the content pointed to by tokenURI
        bytes32 contentHash;
        // A SHA256 hash of the content pointed to by metadataURI
        bytes32 metadataHash;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() external returns (uint256);

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) external returns (uint256);

    // /**
    //  * @notice Return the metadata URI for a piece of media given the token URI
    //  */
    // function tokenMetadataURI(uint256 tokenId)
    //     external
    //     view
    //     returns (string memory);

    /**
     * @notice Mint new media for msg.sender.
     */
    function mint(MediaData calldata data, BidShares calldata bidShares)
        external;

    /**
     * @notice EIP-712 mintWithSig method. Mints new media for a creator given a valid signature.
     */
    function mintWithSig(
        address creator,
        MediaData calldata data,
        BidShares calldata bidShares,
        EIP712Signature calldata sig
    ) external;

    // /**
    //  * @notice Transfer the token with the given ID to a given address.
    //  * Save the previous owner before the transfer, in case there is a sell-on fee.
    //  * @dev This can only be called by the auction contract specified at deployment
    //  */
    // function auctionTransfer(uint256 tokenId, address recipient) external;

    // /**
    //  * @notice Revoke approval for a piece of media
    //  */
    // function revokeApproval(uint256 tokenId) external;

    /**
     * @notice Update the token URI
     */
    function updateTokenURI(uint256 tokenId, string calldata tokenURI) external;

    /**
     * @notice Update the token metadata uri
     */
    function updateTokenMetadataURI(
        uint256 tokenId,
        string calldata metadataURI
    ) external;

    /**
     * @notice EIP-712 permit method. Sets an approved spender given a valid signature.
     */
    function permit(
        address spender,
        uint256 tokenId,
        EIP712Signature calldata sig
    ) external;

    /**
     * @title Interface for Zora Protocol's Market
     */
    struct Bid {
        // Amount of the currency being bid
        uint256 amount;
        // Address to the ERC20 token being used to bid
        address currency;
        // Address of the bidder
        address bidder;
        // Address of the recipient
        address recipient;
        // % of the next sale to award the current owner
        D256 sellOnShare;
    }

    struct Ask {
        // Amount of the currency being asked
        uint256 amount;
        // Address to the ERC20 token being asked
        address currency;
    }

    struct BidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        D256 prevOwner;
        // % of sale value that goes to the original creator of the nft
        D256 creator;
        // % of sale value that goes to the seller (current owner) of the nft
        D256 owner;
    }

    event BidCreated(uint256 indexed tokenId, Bid bid);
    event BidRemoved(uint256 indexed tokenId, Bid bid);
    event BidFinalized(uint256 indexed tokenId, Bid bid);
    event AskCreated(uint256 indexed tokenId, Ask ask);
    event AskRemoved(uint256 indexed tokenId, Ask ask);
    event BidShareUpdated(uint256 indexed tokenId, BidShares bidShares);

    // function bidForTokenBidder(uint256 tokenId, address bidder)
    //     external
    //     view
    //     returns (Bid memory);

    // function currentAskForToken(uint256 tokenId)
    //     external
    //     view
    //     returns (Ask memory);

    // function bidSharesForToken(uint256 tokenId)
    //     external
    //     view
    //     returns (BidShares memory);

    // function isValidBid(uint256 tokenId, uint256 bidAmount)
    //     external
    //     view
    //     returns (bool);

    // function isValidBidShares(BidShares calldata bidShares)
    //     external
    //     pure
    //     returns (bool);

    // function splitShare(D256 calldata sharePercentage, uint256 amount)
    //     external
    //     pure
    //     returns (uint256);

    // function configure(address mediaContractAddress) external;

    function setBidShares(uint256 tokenId, BidShares calldata bidShares)
        external;

    function setAsk(uint256 tokenId, Ask calldata ask) external;

    function removeAsk(uint256 tokenId) external;

    function setBid(
        uint256 tokenId,
        Bid calldata bid,
        address spender
    ) external;

    function removeBid(uint256 tokenId, address bidder) external;

    function acceptBid(uint256 tokenId, Bid calldata expectedBid) external;

    /**
     * @title Interface for Auction House
     */
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // Whether or not the auction curator has approved the auction to start
        bool approved;
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The sale percentage to send to the curator
        uint8 curatorFeePercentage;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;
        // The address of the auction's curator.
        // The curator can reject or approve an auction
        address payable curator;
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        address auctionCurrency;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,
        address curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    );

    event AuctionApprovalUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        bool approved
    );

    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid,
        bool extended
    );

    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address curator,
        address winner,
        uint256 amount,
        uint256 curatorFee,
        address auctionCurrency
    );

    event AuctionCanceled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    ) external returns (uint256);

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;

    /**
     * @title Interface for NFT-Editions
     */

    /// Creates a new edition contract as a factory with a deterministic address
    /// Important: None of these fields (except the Url fields with the same hash) can be changed after calling
    /// @param _name Name of the edition contract
    /// @param _symbol Symbol of the edition contract
    /// @param _description Metadata: Description of the edition entry
    /// @param _animationUrl Metadata: Animation url (optional) of the edition entry
    /// @param _animationHash Metadata: SHA-256 Hash of the animation (if no animation url, can be 0x0)
    /// @param _imageUrl Metadata: Image url (semi-required) of the edition entry
    /// @param _imageHash Metadata: SHA-256 hash of the Image of the edition entry (if not image, can be 0x0)
    /// @param _editionSize Total size of the edition (number of possible editions)
    /// @param _royaltyBPS BPS amount of royalty

    function createEdition(
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _animationUrl,
        bytes32 _animationHash,
        string memory _imageUrl,
        bytes32 _imageHash,
        uint256 _editionSize,
        uint256 _royaltyBPS
    ) external returns (uint256);

    /**
      @param _salePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @dev This sets a simple ETH sales price
           Setting a sales price allows users to mint the edition until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setSalePrice(uint256 _salePrice) external;

    /**
      @dev This withdraws ETH from the contract to the contract owner.
     */
    function withdraw() external;

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function mintEditions(address[] memory recipients)
        external
        returns (uint256);

    /** 
     Get edition given the created ID
    @param editionId id of edition to get contract for
     @return address of SingleEditionMintable Edition NFT contract
    */
    function getEditionAtId(uint256 editionId) external view returns (address);

    /**
      @param minter address to set approved minting status for
      @param allowed boolean if that address is allowed to mint
      @dev Sets the approved minting status of the given address.
           This requires that msg.sender is the owner of the given edition id.
           If the ZeroAddress (address(0x0)) is set as a minter,
             anyone will be allowed to mint.
           This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setApprovedMinter(address minter, bool allowed) external;

    /**
      @dev Allows for updates of edition urls by the owner of the edition.
           Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function updateEditionURLs(
        string memory _imageUrl,
        string memory _animationUrl
    ) external;
}
/* solhint-enable private-vars-leading-underscore, ordering */

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title Minimal Interface for MirrorXYZ Protocol
 * @author (s):
 * https://github.com/mirror-xyz/
 *
 * @notice Interface for essential Crowdfund Functions.
 * @dev I don't have an account with Mirror, yet, nor any experience. DO NOT USE IN PRODUCTION.
 */

interface IMirror {
    /**
     * @notice Interface for the Crowdfund contracts
     */
    function createCrowdfund(
        string calldata name_,
        string calldata symbol_,
        address payable operator_,
        address payable fundingRecipient_,
        uint256 fundingCap_,
        uint256 operatorPercent_
    ) external returns (address crowdfundProxy);

    function closeFunding() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title Interface for PartyDAO
 * @author (s):
 * https://github.com/PartyDAO/
 */
interface IPartyBid {
    //======== Deploy function =========
    function startParty(
        address _marketWrapper,
        address _nftContract,
        uint256 _tokenId,
        uint256 _auctionId,
        string memory _name,
        string memory _symbol
    ) external returns (address partyBidProxy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Minimal Interface for ERC721s
 * @author (s):
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721
 *
 * @notice Modified for OurMinter.sol
 * @dev Allows Split contract to interact with ERC-721s beyond the Zora Protocol.
 */

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
interface IERC721Burnable {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC721Burnable, IERC721Enumerable {
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
     * @notice Most NFT Protocols vary in their implementation of mint,
     * @notice so this should be changed if you know you will need to use a
     * @notice different protocol.
     * @dev lowest common denominator mint()
     */
    // function mint(string calldata calldatacontentURI_ || address to_ || etc...) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
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