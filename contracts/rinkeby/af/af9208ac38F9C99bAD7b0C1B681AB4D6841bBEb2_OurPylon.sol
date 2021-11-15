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

        // Approve Zora AH
        setupApprovalForAH();
    }

    /**
     * @dev Attempts transferring entire balance of an ERC20 to corresponding Recipients
     * @notice see OurSplitter -> massClaimERC20()
     */ 
    function claimERC20ForAllSplits(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata allocations,
        bytes32[] calldata merkleProofZero // accounts[0], allocations[0]
    ) external onlyOwners {
        require(tokenAddress != address(0), "Use claimETH");
        massClaimERC20(tokenAddress, accounts, allocations, merkleProofZero);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import { OurStorage } from "./OurStorage.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
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
    uint256 public constant PERCENTAGE_SCALE = 10e5;

    /**======== Subgraph =========
     * ETHReceived - emits sender and value in receive() fallback
     * TransferETH - emits destination address, value, and success bool
     * MassTransferERC20 - emits token address, total transferred amount, and success bool 
     * WindowIncremented - emits token address, current claim window, and available value of ERC20
     */
    event ETHReceived(address indexed sender, uint256 value);
    event TransferETH(address account, uint256 amount, bool success);
    event MassTransferERC20(address token, uint256 amount, bool success);
    event WindowIncremented(uint256 currentWindow, uint256 fundsAvailable);

    // Plain ETH transfers
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
        depositedInWindow += msg.value;
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

        setClaimed(window, account);

        require(
            verifyProof(
                merkleProof,
                merkleRoot,
                getNode(account, scaledPercentageAllocation)
            ),
            "Invalid proof"
        );

        transferETHOrWETH(
            account,
            // The absolute amount that's claimable.
            scaleAmountByPercentage(
                balanceForWindow[window],
                scaledPercentageAllocation
            )
        );
    }

    /**
     * NOTE: SPLITS DO NOT SUPPORT ERC20. THIS FUNCTION IS PROVIDED AS A LAST RESORT.
     * NOTE: AVOID ERC-20 AUCTION CURRENCIES AT ALL COST.
     *
     * @dev As a last resort option, this allows an Owner to attempt transferring the entire balance of an ERC20 to ALL split recipients.
     * @notice THE ONLY ADDRESS & ALLOCATION CHECKED ARE INDEX 0. THIS IS EASILY MANIPULATED.
     * @notice only callable by Owner, however doesn't protect against rogue owner.
     *
     * @custom:owners DONT BE SHITTY. OurActions live eternally on the block chain, Z is watching.
     */
    function massClaimERC20(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata allocations,
        bytes32[] calldata merkleProofZero // accounts[0], allocations[0]
    ) internal {
        require(
            verifyProof(
                merkleProofZero,
                merkleRoot,
                getNode(accounts[0], allocations[0])
            ),
            "Invalid proof"
        );

        uint256 ERC20Balance = IERC20(tokenAddress).balanceOf(address(this));

        for (uint256 i = 0; i <= accounts.length; i++) {
            transferERC20(
                tokenAddress, 
                accounts[i], 
                scaleAmountByPercentage(
                    ERC20Balance,
                    allocations[i]
                )
            );
        }

        emit MassTransferERC20(tokenAddress, ERC20Balance, true);
    }

    function claimETHForAllWindows(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        // Make sure that the user has this allocation granted.
        require(
            verifyProof(merkleProof, merkleRoot, getNode(account, percentageAllocation)),
            "Invalid proof"
        );

        uint256 amount = 0;
        for (uint256 i = 0; i < currentWindow; i++) {
            if (!isClaimed(i, account)) {
                setClaimed(i, account);

                amount += scaleAmountByPercentage(balanceForWindow[i], percentageAllocation);
            }
        }

        transferETHOrWETH(account, amount);
    }

    function incrementWindow() public {
        uint256 fundsAvailable;

        if (currentWindow == 0) {
            fundsAvailable = address(this).balance;
        } else {
            // Current Balance, subtract previous balance to get the
            // funds that were added for this window.
            fundsAvailable = depositedInWindow;
        }

        depositedInWindow = 0;
        require(fundsAvailable > 0, "No additional funds for window");
        balanceForWindow.push(fundsAvailable);
        currentWindow += 1;
        emit WindowIncremented(currentWindow, fundsAvailable);
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

    

    function isClaimed(uint256 window, address account)
        public
        view
        returns (bool)
    {
        return claimed[getClaimHash(window, account)];
    }

    //======== Private Functions ========
    function setClaimed(uint256 window, address account) private {
        claimed[getClaimHash(window, account)] = true;
    }


    function getClaimHash(uint256 window, address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(window, account));
    }

    function amountFromPercent(uint256 amount, uint32 percent) private pure returns (uint256) {
        // Solidity 0.8.0 lets us do this without SafeMath.
        return (amount * percent) / 100;
    }

    function getNode(address account, uint256 percentageAllocation) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, percentageAllocation));
    }

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function transferETHOrWETH(address to, uint256 value) private returns (bool didSucceed) {
        // Try to transfer ETH to the given recipient.
        didSucceed = attemptETHTransfer(to, value);
       if (!didSucceed) {
            // If the transfer fails, wrap and send as WETH, so that
            // the auction is not impeded and the recipient still
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(weth).deposit{value: value}();
            IWETH(weth).transfer(to, value);
            // At this point, the recipient can unwrap WETH.
        }

        emit TransferETH(to, value, didSucceed);
    }

    function attemptETHTransfer(address to, uint256 value) private returns (bool) {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt  a limited reentrancy attack.
        (bool success, ) = to.call{ value: value, gas: 30000 }("");
        return success;
    }

    /**
     * @dev Transfers ERC20s
     * @notice Reverts entire transaction if one fails
     * @notice A rogue owner could easily bypass countermeasures. Provided as last resort,
     * in case Proxy receives ERC20.
     */
    function transferERC20(address tokenAddress, address splitRecipient, uint256 allocatedAmount) internal {
        bool didSucceed = IERC20(tokenAddress).transfer(splitRecipient, allocatedAmount);
        require(didSucceed);
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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

/// @us The Future Is Ourz

import { OurManagement } from "./OurManagement.sol";
import { IZora } from "./interfaces/IZora.sol";
import { IMirror } from "./interfaces/IMirror.sol";
import { IPartyBid } from "./interfaces/IPartyBid.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IERC20 } from "./interfaces/IERC20.sol";

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
    address public constant _zoraMedia = 0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;
    address public constant _zoraMarket = 0x85e946e1Bd35EC91044Dc83A5DdAB2B6A262ffA6;
    address public constant _zoraAH = 0xE7dd1252f50B3d845590Da0c5eADd985049a03ce;
    address public constant _mirrorAH = 0x2D5c022fd4F81323bbD1Cc0Ec6959EC8CC1C5A11;
    address public constant _mirrorCrowdfund = 0xeac226B370D77f436b5780b4DD4A49E59e8bEA37;
    address public constant _mirrorEditions = 0xa8b8F7cC0C64c178ddCD904122844CBad0021647;
    address public constant _partyBid = 0xB725682D5AdadF8dfD657f8e7728744C0835ECd9;
    address public constant _weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    /**======== IZora =========
     * @notice Various functions allowing a Split to interact with Zora Protocol
     * @dev see IZora.sol
     * Starts with metatransactions for QoL, followed by single tx
     * implementations of Zora's contracts. Media -> Market -> AH
     */

    /** QoL
     * @notice Approve the splitOwner and Zora Auction House to manage Split's ERC-721s
     * @dev Called in Proxy's Constructor, hence internal
     */

    function setupApprovalForAH() internal {
        IERC721(_zoraMedia).setApprovalForAll(_zoraAH, true);
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
        IZora(_zoraMedia).mint(mediaData, bidShares);
        uint256 index = IERC721(_zoraMedia).totalSupply() - 1;
        uint256 tokenId_ = IERC721(_zoraMedia).tokenByIndex(index);
        IZora(_zoraAH).createAuction(
            tokenId_,
            _zoraMedia,
            duration,
            reservePrice,
            payable(address(this)),
            0,
            address(0)
        );
    }

    /** Media
     * @notice Mint new Zora NFT for Split Contract.
     */
    function mintZora(IZora.MediaData calldata mediaData, IZora.BidShares calldata bidShares)
        external
        onlyOwners
    {
        IZora(_zoraMedia).mint(mediaData, bidShares);
    }

    /** Media
     * @notice EIP-712 mintWithSig. Mints new new Zora NFT for a creator on behalf of split contract.
     */
    function mintZoraWithSig(
        address creator,
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares,
        IZora.EIP712Signature calldata sig
    ) external onlyOwners {
        IZora(_zoraMedia).mintWithSig(creator, mediaData, bidShares, sig);
    }

    /** Media
     * @notice Update the token URIs for a Zora NFT owned by Split Contract
     */
    function updateZoraMediaURIs(
        uint256 tokenId,
        string calldata tokenURI,
        string calldata metadataURI
    ) external onlyOwners {
        IZora(_zoraMedia).updateTokenURI(tokenId, tokenURI);
        IZora(_zoraMedia).updateTokenMetadataURI(tokenId, metadataURI);
    }

    /** Media
     * @notice Update the token URI
     */
    function updateZoraMediaTokenURI(uint256 tokenId, string calldata tokenURI) external onlyOwners {
        IZora(_zoraMedia).updateTokenURI(tokenId, tokenURI);
    }

    /** Media
     * @notice Update the token metadata uri
     */
    function updateZoraMediaMetadataURI(uint256 tokenId, string calldata metadataURI) external {
        IZora(_zoraMedia).updateTokenMetadataURI(tokenId, metadataURI);
    }

    /** Market
     * @notice Update zora/core/market bidShares (NOT zora/auctionHouse)
     */
    function setZoraMarketBidShares(uint256 tokenId, IZora.BidShares calldata bidShares) external {
        IZora(_zoraMarket).setBidShares(tokenId, bidShares);
    }

    /** Market
     * @notice Update zora/core/market ask
     */
    function setZoraMarketAsk(uint256 tokenId, IZora.Ask calldata ask) external onlyOwners {
        IZora(_zoraMarket).setAsk(tokenId, ask);
    }

    /** Market
     * @notice Remove zora/core/market ask
     */
    function removeZoraMarketAsk(uint256 tokenId) external onlyOwners {
        IZora(_zoraMarket).removeAsk(tokenId);
    }

    /** Market
     * @notice Set zora/core/market bid (NOT zora/auctionHouse)
     */
    function setZoraMarketBid(
        uint256 tokenId,
        IZora.Bid calldata bid,
        address spender
    ) external onlyOwners {
        IZora(_zoraMarket).setBid(tokenId, bid, spender);
    }

    /** Market
     * @notice Remove zora/core/market bid (NOT zora/auctionHouse)
     */
    function removeZoraMarketBid(uint256 tokenId, address bidder) external onlyOwners {
        IZora(_zoraMarket).removeBid(tokenId, bidder);
    }

    /** Market
     * @notice Accept zora/core/market bid
     */
    function acceptZoraMarketBid(uint256 tokenId, IZora.Bid calldata expectedBid) external onlyOwners {
        IZora(_zoraMarket).acceptBid(tokenId, expectedBid);
    }

    /** AuctionHouse
     * @notice Create auction on Zora's AuctionHouse for an owned/approved NFT
     * @dev requires currency ETH or WETH
     */
    function createZoraAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentages,
        address auctionCurrency
    ) external onlyOwners {
        require(auctionCurrency == address(0) || auctionCurrency == _weth);
        IZora(_zoraAH).createAuction(
            tokenId,
            tokenContract,
            duration,
            reservePrice,
            curator,
            curatorFeePercentages,
            auctionCurrency
        );
    }

    /** AuctionHouse
     * @notice SPLITS DO NOT SUPPORT ERC20. MUST BE HANDLED MANUALLY.
     * NOTE: Marked as >> unsafe << as FUNDS WILL NOT BE SPLIT.
     * @dev Provided as option in case you know what you're doing.
     */
    function unsafeCreateZoraAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentages,
        address auctionCurrency
    ) external onlyOwners {
        IZora(_zoraAH).createAuction(
            tokenId,
            tokenContract,
            duration,
            reservePrice,
            curator,
            curatorFeePercentages,
            auctionCurrency
        );
    }

    /** AuctionHouse
     * @notice Approve Auction; aka Split Contract is now the Curator
     */
    function setZoraAuctionApproval(uint256 auctionId, bool approved) external onlyOwners {
        IZora(_zoraAH).setAuctionApproval(auctionId, approved);
    }

    /** AuctionHouse
     * @notice Set Auction's reserve price
     */
    function setZoraAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external onlyOwners {
        IZora(_zoraAH).setAuctionReservePrice(auctionId, reservePrice);
    }

    /** AuctionHouse
     * @notice Bid on an Auction
     */
    function createZoraAuctionBid(uint256 auctionId, uint256 amount) external payable {
        IZora(_zoraAH).createBid(auctionId, amount);
    }

    /** AuctionHouse
     * @notice End an Auction
     */
    function endZoraAuction(uint256 auctionId) external onlyOwners {
        IZora(_zoraAH).endAuction(auctionId);
    }

    /** AuctionHouse
     * @notice Cancel an Auction before any bids have been placed
     */
    function cancelZoraAuction(uint256 auctionId) external onlyOwners {
        IZora(_zoraAH).cancelAuction(auctionId);
    }

    //======== /IZora =========

    /**======== IMirror =========
     * @notice Various functions allowing a Split to interact with MirrorXYZ
     * @dev see IMirror.sol
     */
    /** ReserveAuctionV3
     * @notice Create Reserve Auction
     */
    function createMirrorAuction(
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        address creator,
        address payable creatorShareRecipient
    ) external onlyOwners {
        IMirror(_mirrorAH).createAuction(tokenId, duration, reservePrice, creator, creatorShareRecipient);
    }

    /** ReserveAuctionV3
     * @notice Bid on Reserve Auction
     */
    function createMirrorBid(uint256 tokenId) external payable {
        IMirror(_mirrorAH).createBid(tokenId);
    }

    /** ReserveAuctionV3
     * @notice End Reserve Auction
     */
    function endMirrorAuction(uint256 tokenId) external onlyOwners {
        IMirror(_mirrorAH).endAuction(tokenId);
    }

    /** ReserveAuctionV3
     * @notice Update Minimum Bid on Reserve Auction
     */
    function updateMirrorMinBid(uint256 minBid) external onlyOwners {
        IMirror(_mirrorAH).updateMinBid(minBid);
    }

    /** Editions
     * @notice Create an Edition
     */
    function createMirrorEdition(
        uint256 quantity,
        uint256 price,
        address payable fundingRecipient
    ) external onlyOwners {
        IMirror(_mirrorEditions).createEdition(quantity, price, fundingRecipient);
    }

    /** Editions
     * @notice Buy an Edition
     */
    function buyMirrorEdition(uint256 editionId) external payable {
        IMirror(_mirrorEditions).buyEdition(editionId);
    }

    /** Editions
     * @notice Withdraw funds from Edition
     */
    function withdrawEditionFunds(uint256 editionId) external onlyOwners {
        IMirror(_mirrorEditions).withdrawFunds(editionId);
    }

    /** Crowdfund
     * @notice Create a Crowdfund
     */
    function createMirrorCrowdfund(
        string calldata name,
        string calldata symbol,
        address payable operator,
        address payable fundingRecipient,
        uint256 fundingCap,
        uint256 operatorPercent
    ) external onlyOwners {
        IMirror(_mirrorCrowdfund).createCrowdfund(
            name,
            symbol,
            operator,
            fundingRecipient,
            fundingCap,
            operatorPercent
        );
    }

    /** Crowdfund
     * @notice Marked as >> untrusted << Use caution when supplying crowdfundProxy_
     * @dev Close Funding period for Crowdfund
     */
    function untrustedCloseCrowdFunding(address crowdfundProxy_) external onlyOwners {
        IMirror(crowdfundProxy_).closeFunding();
    }

    //======== /IMirror =========

    /**======== IPartyBid =========
     * @notice Various functions allowing a Split to interact with PartyDAO
     * @dev see IPartyBid.sol
     */
    /** PartyBid
     * @notice Starts a Party Bid
     */
    function startSplitParty(
        address marketWrapper,
        address nftContract,
        uint256 tokenId,
        uint256 auctionId,
        string memory name,
        string memory symbol
    ) external onlyOwners {
        IPartyBid(_partyBid).startParty(marketWrapper, nftContract, tokenId, auctionId, name, symbol);
    }

    /** PartyBid
     * NOTE: Marked as >> untrusted << Use caution when supplying partyAddress_
     * @notice Contributes funds to PartyBid
     */
    // function untrustedContributeToParty(address partyAddress_) external payable {
    //   IPartyBid(partyAddress_).contribute();
    // }

    /** PartyBid
     * NOTE: Marked as >> untrusted << Use caution when supplying partyAddress_
     * @notice Bid for Party
     */
    // function untrustedSplitPartyBid(address partyAddress_) external onlyOwners {
    //   IPartyBid(partyAddress_).bid();
    // }

    /** PartyBid
     * NOTE: Marked as >> untrusted << Use caution when supplying partyAddress_
     * @notice Finalizes Party
     */
    // function untrustedFinalizeParty(address partyAddress_) external onlyOwners {
    //   IPartyBid(partyAddress_).finalize();
    // }

    /** PartyBid
     * NOTE: Marked as >> untrusted << Use caution when supplying partyAddress_
     * @notice Claims funds from Party for Party contributors
     */
    // function untrustedClaimParty(address partyAddress_, address contributor) external onlyOwners {
    //   IPartyBid(partyAddress_).claim(contributor);
    // }

    //======== /IPartyBid =========

    /**======== IERC721 =========
     * NOTE: Althought OurMinter.sol is generally implemented to work with Zora (or Mirror),
     * the functions below allow a Split to work with any ERC-721 spec'd platform
     * @dev see IERC721.sol
     */

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * this should be changed if you know you will be using a different protocol.
     * @dev mint non-Zora ERC721 with one parameter, eg Foundation.app. See IERC721.sol
     * @dev mint(string contentURI/IPFSHash || address to_ || etc...)
     */
    //   function untrustedMint721(address tokenContract_, string contentURI_ || address to_ || etc...)
    //       external
    //   {
    //       IERC721(tokenContract_).mint(contentURI_ || address to_ || etc...);
    //   }

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev In case non-Zora ERC721 gets stuck in Account.
     * @notice safeTransferFrom(address from, address to, uint256 tokenId)
     */
    function untrustedSafeTransfer721(
        address tokenContract_,
        address newOwner_,
        uint256 tokenId_
    ) external onlyOwners {
        IERC721(tokenContract_).safeTransferFrom(address(msg.sender), newOwner_, tokenId_);
    }

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev In case non-Zora ERC721 gets stuck in Account. Try untrustedSafeTransfer721 first.
     * @notice transferFrom(address from, address to, uint256 tokenId)
     */
    // function untrustedTransfer721(
    //   address tokenContract_,
    //   address newOwner_,
    //   uint256 tokenId_
    // ) external onlyOwners {
    //   IERC721(tokenContract_).transferFrom(address(msg.sender), newOwner_, tokenId_);
    // }

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev sets approvals for non-Zora ERC721 contract
     * @notice setApprovalForAll(address operator, bool approved)
     */
    function untrustedSetApproval721(
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
    function untrustedBurn721(address tokenContract_, uint256 tokenId_) external onlyOwners {
        IERC721(tokenContract_).burn(tokenId_);
    }

    //======== /IERC721 =========

    /**======== IERC20 =========
     * NOTE: SPLITS DO NOT SUPPORT ERC20. MUST BE HANDLED MANUALLY.
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     *
     * @dev As a last resort option, this allows the splitOwner to approve another
     * address to transfer any ERC20s that are stuck in the Split contract.
     * @dev see IERC20.sol
     *
     * @notice To include this functionality for ERC20s, approve() was removed from IERC721.
     *
     * @Owners be nice and approve all recipients allocations.
     */
    // function untrustedRescueERC20(
    //     address tokenContract_,
    //     address spender_,
    //     uint256 amount_
    // ) external onlyOwners returns (bool) {
    //     bool success = IERC20(tokenContract_).approve(spender_, amount_);
    //     return success;
    // }
    //======== /IERC20 =========
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
    event ERC721Received(address operator, address from, uint256 tokenId);

    function onERC721Received(
        address operator_,
        address from_,
        uint256 tokenId_,
        bytes calldata
    ) external override returns (bytes4) {
        emit ERC721Received(operator_, from_, tokenId_);
        return 0x150b7a02;
    }

    //======== IERC1155 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC1155/IERC1155Receiver.sol
    event ERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value
    );
    event Batch1155Received(
        address operator,
        address from,
        uint256[] ids,
        uint256[] values
    );

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override returns (bytes4) {
        emit ERC1155Received(operator, from, id, value);
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external override returns (bytes4) {
        emit Batch1155Received(operator, from, ids, values);
        return 0xbc197c81;
    }

    //======== IERC777 =========
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC777/IERC777Recipient.sol
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
    address public constant weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
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
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ProxySetup(address[] owners);

    // used as origin pointer for linked list of owners
    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function checkIsOwner(address caller_) internal view returns (bool) {
        bool _isOwner = isOwner(caller_);
        return _isOwner;
    }

    modifier onlyOwners() {
        // This is a function call as it minimized the bytecode size
        checkIsOwner(_msgSender());
        _;
    }
    /** 
     * @dev Setup function sets initial owners of contract.
     * @param owners_ List of Split Owners (can mint/manage auctions)
     * @notice threshold ensures that setup function can only be called once.
     */
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
        
        emit ProxySetup(owners_);
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

    event TokenURIUpdated(uint256 indexed _tokenId, address owner, string _uri);
    event TokenMetadataURIUpdated(
        uint256 indexed _tokenId,
        address owner,
        string _uri
    );

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
     * @title Interface for Auction Houses
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
        uint8 curatorFeePercentages,
        address auctionCurrency
    ) external returns (uint256);

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title Minimal Interface for the entire MirrorXYZ Protocol
 * @author (s):
 * https://github.com/mirror-xyz/
 *
 * @notice combination of Editions, ReserveAuctionV3, and AuctionHouse contracts' interfaces.
 * @dev I don't have an account with Mirror, yet, nor any experience. DO NOT USE IN PRODUCTION.
 */

interface IMirror {
    /**
     * @notice Interface for the Reserve Auction contract
     */
    function createAuction(
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        address creator,
        address payable creatorShareRecipient
    ) external;

    function createBid(uint256 tokenId) external payable;

    function endAuction(uint256 tokenId) external;

    function updateMinBid(uint256 _minBid) external;

    /**
     * @notice Interface for the Editions contract
     */
    function createEdition(
        // The number of tokens that can be minted and sold.
        uint256 quantity,
        // The price to purchase a token.
        uint256 price,
        // The account that should receive the revenue.
        address payable fundingRecipient
    ) external;

    function buyEdition(uint256 editionId) external payable;

    function withdrawFunds(uint256 editionId) external;

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
 *
 * @dev I have yet to personally use PartyBid. DO NOT USE IN PRODUCTION.
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

    // ======== External: Contribute =========
    /**
     * @notice Contribute to the PartyBid's treasury
     * while the auction is still open
     * @dev Emits a Contributed event upon success; callable by anyone
     */
    function contribute() external payable;

    // ======== External: Bid =========
    /**
     * @notice Submit a bid to the Market
     * @dev Reverts if insufficient funds to place the bid and pay PartyDAO fees,
     * or if any external auction checks fail (including if PartyBid is current high bidder)
     * Emits a Bid event upon success.
     * Callable by any contributor
     */
    function bid() external;

    // ======== External: Finalize =========
    /**
     * @notice Finalize the state of the auction
     * @dev Emits a Finalized event upon success; callable by anyone
     */
    function finalize() external;

    // ======== External: Claim =========
    /**
     * @notice Claim the tokens and excess ETH owed
     * to a single contributor after the auction has ended
     * @dev Emits a Claimed event upon success
     * callable by anyone (doesn't have to be the contributor)
     * @param _contributor the address of the contributor
     */
    function claim(address _contributor) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Minimal Interface for ERC20s
 * @author (s):
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 *
 * @notice Modified for OurMinter.sol
 * @dev Provides ability to 'rescue' ERC20s from a Split contract.
 */

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

