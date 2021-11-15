// SPDX-License-Identifier: MIT

//DES NFT auction contract 2021.7 */
//** Author: Henry Onyebuchi */

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./DesLinkRegistryInterface.sol";

interface IDESNFT is IERC721 {
    /**
     * @dev Returns true if "addr" is an admin 
     */
    function isAdmin(address addr) external view returns (bool);

    /**
     * @dev Returns true if "addr" is a super admin 
     */
    function hasRole(bytes32 role, address addr) external view returns (bool);
}

contract DeSpaceAuction is ERC721Holder, Initializable {
    using SafeERC20 for IERC20;

    //state variables
    DesLinkRegistryInterface private registry;
    IDESNFT private nft;
    uint public initialBidAmount;
    uint public feePercentage; // 1% = 1000
    uint private DIVISOR;
    bool private deployed;
    address payable public feeReceipient;

    //struct
    struct Auction {
        address payable seller;
        address payable highestBidder;
        address payable admin;
        address compliantToken;
        uint highestBidAmount;
        uint endPeriod;
        uint bidCount;
    }

    //NFT address to token id to Auction struct
    mapping(uint => Auction) private auctions;

    //Events
    event AuctionUpdated(
        uint indexed _tokenId, 
        uint newEndPeriod
    );

    event AuctionCancelled(
        uint indexed tokenID
    );

    event AuctionResulted(
        address indexed highestBidder, 
        uint indexed tokenId, 
        uint highestBidAmount
    );

    event NewAuction(
        uint indexed tokenId,
        uint price,
        uint endPeriod,
        address indexed seller
    );

    event NewBid(
        address indexed bidder,
        uint indexed tokenId,
        address indexed paymentToken,
        uint price
    );

    event FeePercentageSet(
        address indexed sender, 
        uint feePercentage
    );

    event FeeReceipientSet(
        address indexed sender, 
        address feeReceipient
    );

    event RegistrySet(
        address indexed sender, 
        address registry
    );

    //Deployer
    function initialize(
        address _nft,
        address _registryAddress,
        address _feeReceipient, 
        uint _fee
        ) external initializer {
        
        require(
            !deployed,
            "Error: contract has already been initialized"
        );
        
        _setRegistry(_registryAddress);  
        _setFeeReceipient(_feeReceipient);
        _setFeePercentage(_fee);

        nft = IDESNFT(_nft);

        deployed = true;
        initialBidAmount = 1 ether;
        DIVISOR = 100 * 1000;
    }

    //Modifier to check all conditions are met before bid
    modifier bidConditions(uint _tokenId) {
        
        Auction memory auction = auctions[_tokenId];
        uint endPeriod = auction.endPeriod;
        
        require(
            auction.seller != msg.sender, 
            "Error: cannot bid own auction"
        ); 
        require(
            !nft.isAdmin(msg.sender), 
            "Error: admin cannot bid auction"
        ); 
        require(
            endPeriod != 0, 
            "Error: auction does not exist"
        );
        require(
            endPeriod > block.timestamp, 
            "Error: auction has ended"
        );
        
        _;
    }

    //modifier for only super admin call
    modifier onlySuperAdmin() {

        //as hashed in the NFT contract
        bytes32 role;
        
        require(
            nft.hasRole(role, msg.sender),
            "Error: only super admin can call"
        );

        _;
    }


    ///-----------------///
    /// WRITE FUNCTIONS ///
    ///-----------------///


    /* 
     * @dev check creates a new auction for an existing token.
     * @dev only NFT admin can create a new auction.
     * -------------------------------------------------------
     * errors if auction already exists.
     * ---------------------------------
     * @param _artist --> the artist/seller of the NFT.
     * @param _tokenId --> the id of the NFT.
     * -----------------------------------------
     * returns true if sussessfully created.
     */
    function createAuction(
        address _artist,
        uint _tokenId
        ) external returns(bool created) {
        
        require(
            nft.isAdmin(msg.sender),
            "Error: only NFT admin can call"
        );

        Auction storage auction = auctions[_tokenId];
        
        require(
            auction.seller == address(0), 
            "Error: auction already exist"
        ); 
        
        //collect NFT from sender
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        
        //create auction
        uint period = block.timestamp + 1 days;
        auction.endPeriod = period;
        auction.seller = payable(_artist); 
        auction.admin = payable(msg.sender); 
        
        emit NewAuction(
            _tokenId, 
            initialBidAmount, 
            period, 
            _artist
        );

        return true;
    }

    /* 
     * @dev bids for an existing auction with ETH.
     * -------------------------------------------
     * errors if auction seller bids.
     * errors if auction does not exist.
     * errors if auction period is over.
     * if first bid, must send 1 ether.
     * if not first bid, previous bid must have been in ETH
     * if not first bid, must send 10% of previous bid in ETH. See { nextBidAmount }
     * if auction period is less than 1 hour, increases period by 10 minutes.
     * caps increased period to 1 hour.
     * -----------------------------------------------------------------------------
     * @param _tokenId --> the id of the NFT.
     * -----------------------------------------
     * returns back ether to the previous bidder.
     * returns true if sussessfully bidded.
     */
    function bidWithEther(
        uint _tokenId
        ) external payable 
        bidConditions(_tokenId) returns(bool bidded) {
        
        Auction storage auction = auctions[_tokenId];
        
        if(auction.bidCount == 0) { 
            require(
                msg.value == initialBidAmount, 
                "Error: must start bid with 1 ether"
            );
        } else {
            require(
                auction.compliantToken == address(0),
                "Error: must pay with compliant token"
            );
            uint amount = _nextBidAmount(_tokenId);
            require(
                msg.value == amount, 
                "Error: must bid 10 percent more than previous bid"
            );
            //return ether to the prevous highest bidder
            auction.highestBidder.transfer(auction.highestBidAmount);
        }

        //update data
        auction.highestBidder = payable(msg.sender);
        auction.highestBidAmount = msg.value; 
        auction.bidCount++;

        emit NewBid(
            msg.sender,
            _tokenId, 
            address(0),  
            msg.value
        );

        //increase countdown clock
        uint timeLeft = _bidTimeRemaining(_tokenId);
        if(timeLeft < 1 hours) {
            timeLeft + 10 minutes <= 1 hours 
            ? auction.endPeriod += 10 minutes 
            : auction.endPeriod += 1 hours - timeLeft;
            
            emit AuctionUpdated(
                _tokenId, 
                block.timestamp + _bidTimeRemaining(_tokenId)
            );
        }

        return true;
    }

    /* 
     * @dev bids for an existing auction with compliant token(s).
     * @dev must approve contract for { nextBidAmountToken }.
     * -----------------------------------------------------
     * errors if auction seller bids.
     * errors if auction does not exist.
     * errors if auction period is over.
     * if first bid, must send { nextBidAmountToken }.
     * if not first bid, previous bid must have been in _compliantToken
     * if not first bid, must send 10% of previous bid.
     * if auction period is less than 1 hour, increases period by 10 minutes.
     * caps increased period to 1 hour.
     * ----------------------------------------------------------------------
     * @param _tokenId --> the id of the NFT.
     * @param _compliantToken --> payment token (must be compliant from Registry).
     * @param _bidAmount --> the amount of compliant token to bid with. Should be 
     * determined using the nextBidAmountToken(_token, _tokenId, _compliantToken)
     * function which returns the amount to bid with
     * ---------------------------------------------------------------------------
     * returns back _compliantToken to the previous bidder. 
     * returns true if sussessfully bidded.
     */
    function bidWithToken(
        uint _tokenId,
        address _compliantToken,
        uint _bidAmount
        ) external bidConditions(_tokenId) returns(bool bidded) {
        
        Auction storage auction = auctions[_tokenId];

        require(
            _bidAmount > 0 &&
            _bidAmount == _nextBidAmountToken(
                _tokenId, 
                _compliantToken
            ),
            "Error: must bid with valid input. see nextBidAmountToken."
        );

        if(auction.bidCount == 0) {
            IERC20(_compliantToken).safeTransferFrom(
                msg.sender, address(this), _bidAmount
            );
            auction.compliantToken = _compliantToken;
        } else {
            if (auction.compliantToken == address(0)) {
                revert("Payment should be in ether");
            } else {
                require(
                    auction.compliantToken == _compliantToken, 
                    "Error: must pay with compliant token"
                );
            }
            
            IERC20(_compliantToken).safeTransferFrom(
                msg.sender, address(this), _bidAmount
            );

            //return token to the prevous highest bidder
            IERC20(_compliantToken).safeTransfer(
                auction.highestBidder, auction.highestBidAmount
            );
        }

        //update data
        auction.highestBidder = payable(msg.sender);
        auction.highestBidAmount = _bidAmount; 
        auction.bidCount++;

        emit NewBid(
            msg.sender, 
            _tokenId,
            _compliantToken, 
            _bidAmount
        );

        //increase countdown clock
        uint timeLeft = _bidTimeRemaining(_tokenId);
        if(timeLeft < 1 hours) {
            timeLeft + 10 minutes <= 1 hours 
            ? auction.endPeriod += 10 minutes 
            : auction.endPeriod += (1 hours - timeLeft);
            
            emit AuctionUpdated(
                _tokenId, 
                block.timestamp + _bidTimeRemaining(_tokenId)
            );
        }

        return true;
    }

    /* 
     * @dev bids for an existing auction.
     * @dev only NFT super admin or auction creator can execute.
     * ---------------------------------------------------------
     * errors if auction does not exist.
     * errors if auction period is not over.
     * -------------------------------------
     * @param _tokenId --> the id of the NFT.
     * --------------------------------------
     * returns true if sussessfully bidded.
     * returns back NFT to the seller if auction is unseccessful.
     * if successfull, collects fee, pays selle and transfers NFT to highest bidder
     */
    function closeBid(
        uint _tokenId
        ) external returns(bool closed) {

        Auction storage auction = auctions[_tokenId];

        //as hashed in the DeSpace NFT contract
        bytes32 role;

        require(
            nft.hasRole(role, msg.sender)
            || auction.admin == msg.sender,
            "Error: only super admin or auction creator"
        );
        
        require(
            auction.seller != address(0), 
            "Error: auction does not exist"
        );
        
        uint timeLeft = _bidTimeRemaining(_tokenId);
        require(
            timeLeft == 0, 
            "Error: auction has not ended"
        );
        
        uint highestBidAmount = auction.highestBidAmount;
        address highestBidder = auction.highestBidder;

        if (highestBidAmount == 0) {
            //auction failed, no bidding occured
            nft.transferFrom(
                address(this), auction.admin, _tokenId
            );
            emit AuctionCancelled(_tokenId);
        
        } else {
            //auction succeeded, pay fee, send money to seller, and token to buyer
            uint fee = (feePercentage * highestBidAmount) / DIVISOR;
            if (auction.compliantToken != address(0)) {
                address compliantToken = auction.compliantToken;
                IERC20(compliantToken).safeTransfer(
                    feeReceipient, fee
                );
                IERC20(compliantToken).safeTransfer(
                    auction.seller, highestBidAmount - fee
                );
            } else {
                feeReceipient.transfer(fee);
                auction.seller.transfer(highestBidAmount - fee);
            }
            
            nft.safeTransferFrom(
                address(this), highestBidder, _tokenId
            );

            emit AuctionResulted(
                highestBidder, _tokenId, highestBidAmount
            );
        }
        
        delete auctions[_tokenId];
        return true;
    }

    
    ///-----------------///
    /// ADMIN FUNCTIONS ///
    ///-----------------///


    /* 
     * @dev sets the fee percentage (only NFT super admin).
     * @dev 1 percent equals 1000
     * ------------------------------------------
     * errors if new value already exists.
     * -----------------------------------
     * @param _newFeePercentage --> the new fee percentage.
     * ----------------------------------------------------
     * returns whether successfully set or not.
     */ 
    function setFeePercentage(
        uint _newFeePercentage
        ) external onlySuperAdmin() returns(bool feePercentageSet) {
        
        _setFeePercentage(_newFeePercentage);
        
        emit FeePercentageSet(msg.sender, _newFeePercentage);
        return true;
    }

    /* 
     * @dev sets the fee receipient (only NFT super admin).
     * ----------------------------------------------------
     * errors if new receipient already exists.
     * ----------------------------------------
     * @param _newFeeReceipient --> the new fee receipient.
     * ----------------------------------------------------
     * returns whether successfully set or not.
     */ 
    function setFeeReceipient(
        address _newFeeReceipient
        ) external onlySuperAdmin() returns(bool feeReceipientSet) {
        
        _setFeeReceipient(_newFeeReceipient);
        
        emit FeeReceipientSet(msg.sender, _newFeeReceipient);
        return true;
    }

    /* 
     * @dev sets the registry pointer (only NFT super admin).
     * ------------------------------------------------------
     * errors if new registry already exists.
     * --------------------------------------
     * @param _newRegistry --> the new registry address.
     * -------------------------------------------------
     * returns whether successfully set or not.
     */ 
    function setRegistry(
        address _newRegistry
        ) external onlySuperAdmin() returns(bool registrySet) {
        
        _setRegistry(_newRegistry);
        
        emit RegistrySet(msg.sender, _newRegistry);
        return true;
    }


    ///-----------------///
    /// READ FUNCTIONS ///
    ///-----------------///


    /* 
     * @dev get the seconds left for an auction to end.
     * ------------------------------------------------
     * @param _token --> the address of the NFT.
     * @param _tokenId --> the id of the NFT.
     * ---------------------------------------
     * returns the remaining seconds.
     */  
    function bidTimeRemaining( 
        uint _tokenId
        ) external view returns(uint secondsLeft) {
        
        return _bidTimeRemaining(_tokenId);
    }

    /* 
     * @dev get the next viable amount to make bid.
     * --------------------------------------------
     * @param _token --> the address of the NFT.
     * @param _tokenId --> the id of the NFT.
     * ---------------------------------------
     * returns the amount in wei.
     * returns 0 for invalid auction or if initial bid wasn't in ether
     */
    function nextBidAmount(
        uint _tokenId
        ) external view returns(uint amount) {
        
        return _nextBidAmount(_tokenId);
    }

    /* 
     * @dev get the next viable amount to make bid in compliant token.
     * ---------------------------------------------------------------
     * @param _token --> the address of the NFT.
     * @param _tokenId --> the id of the NFT.
     * @param _compliantToken --> the token to check for.
     * --------------------------------------------------
     * returns the amount.
     * returns 0 if invalid auction or if initial bid was made in another asset
     * returns 1 ether equivilent in _compliantToken if first bid
     * returns 10 percent more of previous bid if not initial
     */
    function nextBidAmountToken(
        uint _tokenId,
        address _compliantToken
        ) external view returns(uint amount) {
        
        return _nextBidAmountToken(
            _tokenId, _compliantToken);
    }

    /**
     * @dev get the price from chainlink.
     * ----------------------------------
     * @param _compliantToken --> the token to check the price in ether
     * ----------------------------------------------------------------
     * returns the latest price
     * returns 0 if not compliant
     */
    function getThePrice(
        address _compliantToken
        ) external view returns(uint price_per_ETH) {
        
        return _getThePrice(_compliantToken);
    }

    /**
     * @dev get the contract address of DesLinkRegistry.
     * -------------------------------------------------
     * returns the contract address of DesLinkRegistry.
     */
    function getRegistry(
        ) external view returns(address registry_) {
        
        return address(registry);
    }

    /**
     * @dev get the struct details of an auction.
     * ------------------------------------------
     * returns the struct details of an auction.
     */
    function getAuction(
        uint _tokenId
        ) external view returns(Auction memory) {
        
        return auctions[_tokenId];
    }

    
    ///-----------------///
    /// PRIVATE FUNCTIONS ///
    ///-----------------///


    /* 
     * @dev get the seconds left for an auction to end.
     * ------------------------------------------------
     * @param _token --> the address of the NFT.
     * @param _tokenId --> the id of the NFT.
     * ---------------------------------------
     * returns the remaining seconds.
     * returns 0 if auction isn't open.
     */
    function _bidTimeRemaining(
        uint _tokenId
        ) private view returns(uint secondsLeft) {
        
        uint endPeriod = auctions[_tokenId].endPeriod;

        if(endPeriod > block.timestamp) 
        return endPeriod - block.timestamp;
        return 0;
    }

    /* 
     * @dev get the next viable amount to make bid.
     * --------------------------------------------
     * @param _token --> the address of the NFT.
     * @param _tokenId --> the id of the NFT.
     * ---------------------------------------
     * returns the amount in wei.
     * returns 0 if invalid auction
     * returns 1 ether if first bid
     * returns 10 percent more of previous bid
     */
    function _nextBidAmount(
        uint _tokenId
        ) private view returns(uint amount) {
        
        address seller = auctions[_tokenId].seller;
        if (
            seller != address(0) && 
            auctions[_tokenId].compliantToken == address(0)
        ) {
            uint count = auctions[_tokenId].bidCount;
            uint current = auctions[_tokenId].highestBidAmount;
            if(count == 0) return 1 ether;
            //10% of current highest bid
            else return ((current * 10000) / DIVISOR) + current;
        }
        return 0;
    }

    /* 
     * @dev get the next viable amount to make bid in compliant token.
     * ---------------------------------------------------------------
     * @param _token --> the address of the NFT.
     * @param _tokenId --> the id of the NFT.
     * @param _compliantToken --> the token to check for.
     * --------------------------------------------------
     * returns the amount.
     * returns 0 if invalid auction or if initial bid was made in another asset
     * returns 1 ether equivilent in _compliantToken if first bid
     * returns 10 percent more of previous bid if not initial
     */
    function _nextBidAmountToken(
        uint _tokenId,
        address _compliantToken
        ) private view returns(uint amount) {
        
        Auction memory auction = auctions[_tokenId];
        if (auction.seller != address(0)) {
            uint current = auction.highestBidAmount; 
            
            if (current == 0) {
                (,uint8 decimals) = registry.getProxy(_compliantToken);
                uint ethPerToken = _getThePrice(_compliantToken);
                return (
                //get the equivilent based on chainlink oracle price and token decimal
                    ((10 ** uint(decimals)) * initialBidAmount) / ethPerToken
                );
            } else {
                if (auction.compliantToken == _compliantToken) {
                    //10% of current highest bid
                    return ((current * 10000) / DIVISOR) + current;
                } else {
                    return 0;
                }
            }
        }
        return 0;
    }

    /**
     * @dev get the price from chainlink.
     * ----------------------------------
     * @param _compliantToken --> the token to check the price in ether
     * ----------------------------------------------------------------
     * returns the latest price
     * returns 0 if not compliant
     */
    function _getThePrice(
        address _compliantToken
        ) private view returns(uint) {

        //get chainlink proxy from DesLinkRegistry
        (address chainlinkProxy,) = registry.getProxy(_compliantToken);
        
        if(chainlinkProxy != address(0)) { 
            (,int price,,,) = AggregatorV3Interface(
                chainlinkProxy).latestRoundData();
            return uint(price);
        }
        return 0;
    }

    /* 
     * @dev sets the fee percentage (only owner).
     * ------------------------------------------
     * errors if new value already exists.
     * -----------------------------------
     * @param _newFeePercentage --> the new fee percentage.
     * ----------------------------------------------------
     * returns whether successfully set or not.
     */ 
    function _setFeePercentage(
        uint _newFee
        ) private {
        require(_newFee != feePercentage, "Error: already set");
        feePercentage = _newFee;
    }

    /* 
     * @dev sets the fee receipient (only owner).
     * ------------------------------------------
     * errors if new receipient already exists.
     * ----------------------------------------
     * @param _newFeeReceipient --> the new fee receipient.
     * ----------------------------------------------------
     * returns whether successfully set or not.
     */ 
    function _setFeeReceipient(
        address _newFeeReceipient
        ) private {
        require(_newFeeReceipient != feeReceipient, "Error: already receipient");
        feeReceipient = payable(_newFeeReceipient);
    }

    /* 
     * @dev sets the registry pointer (only owner).
     * --------------------------------------------
     * errors if new pointer already exists.
     * -------------------------------------
     * @param _newRegistry --> the new registry pointer.
     */ 
    function _setRegistry(
        address _newRegistry
        ) private {
        require(_newRegistry != address(registry), "Error: already registry");
        registry = DesLinkRegistryInterface(_newRegistry);
    }
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.9.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.4;

interface DesLinkRegistryInterface {

    function addProxy(
        string calldata _ticker,
        address _token,
        address _proxy
        ) external returns(
            bool added
        );

    function removeProxy(
        address _token
        ) external returns(
            bool removed
        );

    function getProxy(
        address _token
        ) external view returns(
            address proxy, 
            uint8 tokenDecimals
        );
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

