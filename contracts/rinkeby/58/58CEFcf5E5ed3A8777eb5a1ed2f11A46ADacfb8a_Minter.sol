// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import {SplitStorage} from "./SplitStorage.sol";
import {IZora} from "./interfaces/IZora.sol";
import {IMirror} from "./interfaces/IMirror.sol";
import {IPartyBid} from "./interfaces/IPartyBid.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC20} from "./interfaces/IERC20.sol";

/**     USE AT YOUR OWN RISK. NOT READY FOR MAINNET. 
 * @title Minter
 * @notice extension for @author MirrorXYZ's Splits Contracts
 * @author [email protected]
 *
 * @notice credit due to open-source contributions of @author (s) from:
 * OpenZeppelin, Zora, MirrorXYZ, PartyDAO, Gnosis, & Synthetix Contracts

        REMINDER: LINK ACKNOWLEDGEMENTS

 *
 * @dev The general === idea === here is that the SplitProxy now has a logic switch in its
 * @dev fallback(). Previously the fallback routed calls to the splitter with a DELEGATECALL. 
 * @dev Now the SplitProxy is Ownable. If the owner triggers fallback(), the call is now
 * @dev routed here as a CALL. Anyone but the owner - and it will behave the same as before.
 * @dev Basically a SplitProxy can be the Creator of an NFT now. And receive royalties.
 * @dev Or be a Curator, and approve Auction House proposals. Or start a crowdfund or PartyDAO.
 * @dev Or whatever else you can think of, it just needs to be implemented below.
 *
 * @notice Some functions are marked as 'untrusted'Function. Use caution when interacting
 * @notice with these, as any contracts you supply could be potentially unsafe.
 * @notice 'Trusted' functions on the other hand -- implied by absence of 'untrusted' --
 * @notice are hardcoded to use the Zora Protocol/MirrorXYZ/PartyDAO addresses.
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#mark-untrusted-contracts
 */
contract Minter is SplitStorage {
    /// @notice for testing purposes
    // uint256 private _fakeId;

    // /// @notice for testing purposes
    // function fakeCall(uint256 fakeId_) external {
    //     _fakeId = fakeId_;
    // }

    // /// @notice for testing purposes
    // function fakeId() public view returns (uint256) {
    //     return _fakeId;
    // }

    // constructor(
    //     address zoraMedia_,
    //     address zoraMarket_,
    //     address zoraAuctionHouse_,
    //     address wethAddress_,
    //     address mirrorAH_,
    //     address mirrorCrowdfundFactory_,
    //     address mirrorEditions_,
    //     address partyBidFactory_
    // ) {
    //     _zoraMedia = zoraMedia_;
    //     _zoraMarket = zoraMarket_;
    //     _zoraAuctionHouse = zoraAuctionHouse_;
    //     wethAddress = wethAddress_;
    //     _mirrorAH = mirrorAH_;
    //     _mirrorCrowdfundFactory = mirrorCrowdfundFactory_;
    //     _mirrorEditions = mirrorEditions_;
    //     _partyBidFactory = partyBidFactory_;
    // }

    /**======== IZora =========
     * @notice Various functions allowing a Split to interact with Zora Protocol
     * @dev see IZora.sol
     * @notice Starts with metatransactions for QoL, followed by single tx
     * @notice implementations of Zora's contracts. Media -> Market -> AH
     */

    /** QoL
     * @notice Approve the splitOwner and Zora Auction House to manage Split's ERC-721s
     * @dev Called in Proxy's constructor
     */
    function setApprovalsForSplit(address splitOwner) external {
        address(_zoraMedia).delegatecall(
            abi.encodeWithSignature(
                "setApprovalForAll(address, bool)",
                splitOwner,
                true
            )
        );
        // IERC721(_zoraMedia).setApprovalForAll(_zoraAuctionHouse, true);
    }

    /** QoL
     * @notice Update Zora Approvals for Owners
     * @dev upon Proxy's transferOwnership()
     */
    function updateApprovalsForSplit(
        address oldSplitOwner,
        address newSplitOwner
    ) external {
        IERC721(_zoraMedia).setApprovalForAll(oldSplitOwner, false);
        IERC721(_zoraMedia).setApprovalForAll(newSplitOwner, true);
    }

    /** QoL
     * @notice Mints a Zora NFT with this Split as the Creator,
     * @notice and then list it on AuctionHouse for ETH
     */
    function mintToAuctionForETH(
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares,
        uint256 duration,
        uint256 reservePrice
    ) external {
        IZora(_zoraMedia).mint(mediaData, bidShares);
        uint256 index = IERC721(_zoraMedia).totalSupply() - 1;
        uint256 tokenId_ = IERC721(_zoraMedia).tokenByIndex(index);
        IZora(_zoraAuctionHouse).createAuction(
            tokenId_,
            _zoraMedia,
            duration,
            reservePrice,
            payable(address(msg.sender)),
            0,
            address(0)
        );
    }

    /** Media
     * @notice Mint new Zora NFT for Split Contract.
     */
    function mintZora(
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares
    ) external {
        IZora(_zoraMedia).mint(mediaData, bidShares);
    }

    /** Media
     * @notice EIP-712 mintWithSig. Mints new new Zora NFT for a creator on behalf
     * @notice of split contract.
     */
    function mintZoraWithSig(
        address creator,
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares,
        IZora.EIP712Signature calldata sig
    ) external {
        IZora(_zoraMedia).mintWithSig(creator, mediaData, bidShares, sig);
    }

    /** Media
     * @notice Update the token URIs for a Zora NFT owned by Split Contract
     */
    function updateZoraMediaURIs(
        uint256 tokenId,
        string calldata tokenURI,
        string calldata metadataURI
    ) external {
        IZora(_zoraMedia).updateTokenURI(tokenId, tokenURI);
        IZora(_zoraMedia).updateTokenMetadataURI(tokenId, metadataURI);
    }

    /** Media
     * @notice Update the token URI
     */
    function updateZoraMediaTokenURI(uint256 tokenId, string calldata tokenURI)
        external
    {
        IZora(_zoraMedia).updateTokenURI(tokenId, tokenURI);
    }

    /** Media
     * @notice Update the token metadata uri
     */
    function updateZoraMediaMetadataURI(
        uint256 tokenId,
        string calldata metadataURI
    ) external {
        IZora(_zoraMedia).updateTokenMetadataURI(tokenId, metadataURI);
    }

    /** Market
     * @notice Update zora/core/market bidShares (NOT zora/auctionHouse)
     */
    function setZoraMarketBidShares(
        uint256 tokenId,
        IZora.BidShares calldata bidShares
    ) external {
        IZora(_zoraMarket).setBidShares(tokenId, bidShares);
    }

    /** Market
     * @notice Update zora/core/market ask
     */
    function setZoraMarketAsk(uint256 tokenId, IZora.Ask calldata ask)
        external
    {
        IZora(_zoraMarket).setAsk(tokenId, ask);
    }

    /** Market
     * @notice Remove zora/core/market ask
     */
    function removeZoraMarketAsk(uint256 tokenId) external {
        IZora(_zoraMarket).removeAsk(tokenId);
    }

    /** Market
     * @notice Set zora/core/market bid (NOT zora/auctionHouse)
     */
    function setZoraMarketBid(
        uint256 tokenId,
        IZora.Bid calldata bid,
        address spender
    ) external {
        IZora(_zoraMarket).setBid(tokenId, bid, spender);
    }

    /** Market
     * @notice Remove zora/core/market bid (NOT zora/auctionHouse)
     */
    function removeZoraMarketBid(uint256 tokenId, address bidder) external {
        IZora(_zoraMarket).removeBid(tokenId, bidder);
    }

    /** Market
     * @notice Accept zora/core/market bid
     */
    function acceptZoraMarketBid(
        uint256 tokenId,
        IZora.Bid calldata expectedBid
    ) external {
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
    ) external {
        require(
            auctionCurrency == address(0) || auctionCurrency == wethAddress
        );
        IZora(_zoraAuctionHouse).createAuction(
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
     * @notice Marked as >> unsafe << as FUNDS WILL NOT BE SPLIT.
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
    ) external {
        IZora(_zoraAuctionHouse).createAuction(
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
    function setZoraAuctionApproval(uint256 auctionId, bool approved) external {
        IZora(_zoraAuctionHouse).setAuctionApproval(auctionId, approved);
    }

    /** AuctionHouse
     * @notice Set Auction's reserve price
     */
    function setZoraAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external
    {
        IZora(_zoraAuctionHouse).setAuctionReservePrice(
            auctionId,
            reservePrice
        );
    }

    /** AuctionHouse
     * @notice Bid on an Auction
     */
    function createZoraAuctionBid(uint256 auctionId, uint256 amount)
        external
        payable
    {
        IZora(_zoraAuctionHouse).createBid(auctionId, amount);
    }

    /** AuctionHouse
     * @notice End an Auction
     */
    function endZoraAuction(uint256 auctionId) external {
        IZora(_zoraAuctionHouse).endAuction(auctionId);
    }

    /** AuctionHouse
     * @notice Cancel an Auction before any bids have been placed
     */
    function cancelZoraAuction(uint256 auctionId) external {
        IZora(_zoraAuctionHouse).cancelAuction(auctionId);
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
    ) external {
        IMirror(_mirrorAH).createAuction(
            tokenId,
            duration,
            reservePrice,
            creator,
            creatorShareRecipient
        );
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
    function endMirrorAuction(uint256 tokenId) external {
        IMirror(_mirrorAH).endAuction(tokenId);
    }

    /** ReserveAuctionV3
     * @notice Update Minimum Bid on Reserve Auction
     */
    function updateMirrorMinBid(uint256 minBid) external {
        IMirror(_mirrorAH).updateMinBid(minBid);
    }

    /** Editions
     * @notice Create an Edition
     */
    function createMirrorEdition(
        uint256 quantity,
        uint256 price,
        address payable fundingRecipient
    ) external {
        IMirror(_mirrorEditions).createEdition(
            quantity,
            price,
            fundingRecipient
        );
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
    function withdrawEditionFunds(uint256 editionId) external {
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
    ) external {
        IMirror(_mirrorCrowdfundFactory).createCrowdfund(
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
    function untrustedCloseCrowdFunding(address crowdfundProxy_) external {
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
    ) external {
        IPartyBid(_partyBidFactory).startParty(
            marketWrapper,
            nftContract,
            tokenId,
            auctionId,
            name,
            symbol
        );
    }

    /** PartyBid
     * @notice Marked as >> untrusted << Use caution when supplying partyAddress_
     * @notice Contributes funds to PartyBid
     */
    function untrustedContributeToParty(address partyAddress_)
        external
        payable
    {
        IPartyBid(partyAddress_).contribute();
    }

    /** PartyBid
     * @notice Marked as >> untrusted << Use caution when supplying partyAddress_
     * @notice Bid for Party
     */
    function untrustedSplitPartyBid(address partyAddress_) external {
        IPartyBid(partyAddress_).bid();
    }

    /** PartyBid
     * @notice Marked as >> untrusted << Use caution when supplying partyAddress_
     * @notice Finalizes Party
     */
    function untrustedFinalizeParty(address partyAddress_) external {
        IPartyBid(partyAddress_).finalize();
    }

    /** PartyBid
     * @notice Marked as >> untrusted << Use caution when supplying partyAddress_
     * @notice Claims funds from Party for Party contributors
     */
    function untrustedClaimParty(address partyAddress_, address contributor)
        external
    {
        IPartyBid(partyAddress_).claim(contributor);
    }

    //======== /IPartyBid =========

    /**======== IERC721 =========
     * @notice Althought Minter.sol is generally implemented to work with Zora (or Mirror),
     * @notice the functions below allow a Split to work with any ERC-721 spec'd platform
     * @dev see IERC721.sol
     */

    /**
     * @notice Marked as >> untrusted << Use caution when supplying tokenContract_
     * @notice this should be changed if you know you will be using a different protocol.
     * @dev mint non-Zora ERC721 with one parameter, eg Foundation.app. See IERC721.sol
     * @dev mint(string contentURI/IPFSHash || address to_ || etc...)
     */
    // function untrustedMint721(address tokenContract_, string contentURI_ || address to_ || etc...)
    //     external
    // {
    //     IERC721(tokenContract_).mint(contentURI_ || address to_ || etc...);
    // }

    /**
     * @notice Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev In case non-Zora ERC721 gets stuck in Account.
     * @dev safeTransferFrom(address from, address to, uint256 tokenId)
     */
    function untrustedSafeTransfer721(
        address tokenContract_,
        address newOwner_,
        uint256 tokenId_
    ) external {
        IERC721(tokenContract_).safeTransferFrom(
            address(msg.sender),
            newOwner_,
            tokenId_
        );
    }

    /**
     * @notice Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev In case non-Zora ERC721 gets stuck in Account. Try untrustedSafeTransfer721 first.
     * @dev transferFrom(address from, address to, uint256 tokenId)
     */
    function untrustedTransfer721(
        address tokenContract_,
        address newOwner_,
        uint256 tokenId_
    ) external {
        IERC721(tokenContract_).safeTransferFrom(
            address(msg.sender),
            newOwner_,
            tokenId_
        );
    }

    /**
     * @notice Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev sets approvals for non-Zora ERC721 contract
     * @dev setApprovalForAll(address operator, bool approved)
     */
    function untrustedSetApproval721(
        address tokenContract_,
        address operator_,
        bool approved_
    ) external {
        IERC721(tokenContract_).setApprovalForAll(operator_, approved_);
    }

    /**
     * @notice Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev burns non-Zora ERC721 that Split contract owns/isApproved
     * @dev setApprovalForAll(address operator, bool approved)
     */
    function untrustedBurn721(address tokenContract_, uint256 tokenId_)
        external
    {
        IERC721(tokenContract_).burn(tokenId_);
    }

    //======== /IERC721 =========

    /**======== IERC20 =========
     * @notice SPLITS DO NOT SUPPORT ERC20. MUST BE HANDLED MANUALLY.
     * @notice As a last resort option, this allows the splitOwner to approve another
     * @notice address to transfer any ERC20s that are stuck in the Split contract.
     *
     * @notice Marked as >> untrusted << Use caution when supplying tokenContract_
     *
     * @notice To include this functionality for ERC20s, approve() was removed from IERC721.
     *
     * @dev see IERC20.sol
     */
    function untrustedRescueERC20(
        address tokenContract_,
        address spender_,
        uint256 amount_
    ) external returns (bool) {
        bool success = IERC20(tokenContract_).approve(spender_, amount_);
        return success;
    }
    //======== /IERC20 =========
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title SplitStorage
 * @author MirrorXYZ
 *
 * Modified to store:
 * address of the deployed Minter Contract
 */
contract SplitStorage {
    //======== Constants =========
    address public constant _zoraMedia =
        0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;
    address public constant _zoraMarket =
        0x85e946e1Bd35EC91044Dc83A5DdAB2B6A262ffA6;
    address public constant _zoraAuctionHouse =
        0xE7dd1252f50B3d845590Da0c5eADd985049a03ce;
    //0x835F86fF1670917A786b72D1FD8DcC385E27DD77 mainnet
    address public constant _mirrorAH =
        0x2D5c022fd4F81323bbD1Cc0Ec6959EC8CC1C5A11;
    //idk 0x517bab7661C315C63C6465EEd1b4248e6f7FE183 maybe
    address public constant _mirrorCrowdfundFactory =
        0xeac226B370D77f436b5780b4DD4A49E59e8bEA37;
    //0x3725CA6034bcDBc3c9aDa649d49Df68527661175 mainnet
    address public constant _mirrorEditions =
        0xa8b8F7cC0C64c178ddCD904122844CBad0021647;
    //0xD96Ff9e48f095f5a22Db5bDFFCA080bCC3B98c7f mainnet
    address public constant _partyBidFactory =
        0xB725682D5AdadF8dfD657f8e7728744C0835ECd9;
    address public constant wethAddress =
        0xc778417E063141139Fce010982780140Aa0cD5Ab;

    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal _splitter;
    address internal _minter;
    address internal _owner;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title Interface for the entire Zora Protocol. Modified for Minter.sol
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
 * @notice Modified for Minter.sol
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
 * @notice Modified for Minter.sol
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

