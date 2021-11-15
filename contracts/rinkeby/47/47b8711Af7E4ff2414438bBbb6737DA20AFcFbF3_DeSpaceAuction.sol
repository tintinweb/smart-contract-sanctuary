// SPDX-License-Identifier: MIT

//DES NFT auction contract 2021.7 */
//** Author: Henry Onyebuchi */

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./DesLinkRegistryInterface.sol";

interface IDESNFT is IERC721Upgradeable {
    /**
     * @dev Returns true if "addr" is an admin 
     */
    function isAdmin(address addr) external view returns (bool);

    /**
     * @dev Returns true if "addr" is a super admin 
     */
    function hasRole(bytes32 role, address addr) external view returns (bool);
}

contract DeSpaceAuction is 
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable {

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
        bool started;
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
            auction.seller != msg.sender
            && auction.admin != msg.sender,
            "Error: cannot bid own auction"
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
        uint _tokenId
        ) external returns(bool created) {

        Auction storage auction = auctions[_tokenId];
        require(
            auction.seller == address(0), 
            "Error: auction already exist"
        ); 
        
        address nftOwner = nft.ownerOf(_tokenId);
        if (!auction.started) {
            
            require(
                nft.isAdmin(msg.sender),
                "Error: only NFT admin can call"
            );

            nft.safeTransferFrom(
                nftOwner, 
                address(this), 
                _tokenId
            );

            auction.started = true;

        } else {

            require(
                nftOwner == msg.sender,
                "Error: only NFT owner can call"
            );

            nft.safeTransferFrom(
                msg.sender, 
                address(this), 
                _tokenId
            );
        }
        
        //create auction
        uint period = block.timestamp + 1 days;
        auction.endPeriod = period;
        auction.seller = payable(nftOwner); 
        auction.admin = payable(msg.sender); 
        
        emit NewAuction(
            _tokenId, 
            initialBidAmount, 
            period, 
            nftOwner
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
        uint _tokenId) 
        external payable nonReentrant()
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
            
            uint newTimeLeft = _bidTimeRemaining(_tokenId);
            
            emit AuctionUpdated(
                _tokenId, 
                block.timestamp + newTimeLeft
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
        uint _bidAmount) 
        external nonReentrant() 
        bidConditions(_tokenId) returns(bool bidded) {
        
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
            IERC20Upgradeable(_compliantToken).transferFrom(
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
            
            IERC20Upgradeable(_compliantToken).transferFrom(
                msg.sender, address(this), _bidAmount
            );

            //return token to the prevous highest bidder
            IERC20Upgradeable(_compliantToken).transfer(
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
            
            uint newTimeLeft = _bidTimeRemaining(_tokenId);
            
            emit AuctionUpdated(
                _tokenId, 
                block.timestamp + newTimeLeft
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
        ) external nonReentrant() returns(bool closed) {

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
                IERC20Upgradeable(compliantToken).transfer(
                    feeReceipient, fee
                );
                IERC20Upgradeable(compliantToken).transfer(
                    auction.seller, highestBidAmount - fee
                );
            } else {
                feeReceipient.transfer(fee);
                auction.seller.transfer(highestBidAmount - fee);
            }
            
            nft.transferFrom(
                address(this), highestBidder, _tokenId
            );

            emit AuctionResulted(
                highestBidder, _tokenId, highestBidAmount
            );
        }
        
        auction.seller = payable(address(0));
        auction.highestBidder = payable(address(0));
        auction.admin = payable(address(0));
        auction.compliantToken = payable(address(0));
        auction.highestBidAmount = 0;
        auction.endPeriod = 0;
        auction.bidCount = 0;
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
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
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
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
interface IERC165Upgradeable {
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

