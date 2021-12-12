// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAuctionHouse } from "./interfaces/IAuctionHouse.sol";
import { IBidDb } from "./interfaces/IBidDb.sol";

/// @title BidDb contract
/// @author Daniel Liu
/// @dev Owner is AuctionHouse
/// @notice Only creator can migrate data from old BidDb, call setCreater(0) to disable function migrateOldData.

contract BidDb is IBidDb, Ownable {
    // uesd for migrate old data
    uint256 internal immutable _maxOldAuctionId;
    address internal _creater;

    // auction id => IAuctionHouse.Auction
    mapping(uint256 => IAuctionHouse.Auction) internal _auctions;

    // auction id => AuctionStatus
    mapping(uint256 => AuctionStatus) internal _auctionStatus;

    // auction id => Bid[]
    mapping(uint256 => Bid[]) internal _bids;

    // token => token id => array of auction id 
    mapping(address => mapping(uint256 => uint256[])) _auctionIds;

    address[] internal _tokens;

    uint256 internal _maxAuctionId;

    // token => token id
    mapping(address => uint256[]) internal _tokenIds;

    constructor(uint256 maxOldAuctionId) public {
        _maxOldAuctionId = maxOldAuctionId;
        _creater = _msgSender();
    }

    function getMaxOldAuctionId() external view override returns(uint256) {
        return _maxOldAuctionId;
    }

    function getMaxAuctionId() external view override returns(uint256) {
        return _maxAuctionId;
    }    

    function getTokens() external view override returns(address[] memory) {
        return _tokens;
    }

    function getTokens(uint256 offset, uint256 limit) external view override returns(address[] memory) {
        require(offset < _tokens.length, "offset is too big");
        require(limit > 0, "limit can't be 0");

        uint256 maxLimit = _tokens.length - offset;
        if (limit > maxLimit) {
            limit = maxLimit;
        }

        address[] memory result = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            result[i] = _tokens[offset];
            offset++;
        }

        return result;
    }

    function getTokenIds(address token) external view override returns(uint256[] memory) {
        return _tokenIds[token];
    }

    function getTokenIds(address token, uint256 offset, uint256 limit) external view override returns(uint256[] memory) {
        uint256[] storage tokenIds = _tokenIds[token];
        require(offset < tokenIds.length, "offset is too big");
        require(limit > 0, "limit can't be 0");

        uint256 maxLimit = tokenIds.length - offset;
        if (limit > maxLimit) {
            limit = maxLimit;
        }

        uint256[] memory result = new uint256[](limit);
        for (uint256 i = 0; i < limit; i++) {
            result[i] = tokenIds[offset];
            offset++;
        }

        return result;
    }

    function getAuction(uint256 auctionId) external view override returns (
        IAuctionHouse.Auction memory, 
        AuctionStatus memory, 
        Bid[] memory) 
    {
        return (_auctions[auctionId], _auctionStatus[auctionId], _bids[auctionId]);
    }

    function getAuctionByTokenId(address token, uint256 tokenId) external view override returns (
        IAuctionHouse.Auction memory, 
        AuctionStatus memory, 
        Bid[] memory) 
    {
        uint256[] storage auctionIds = _auctionIds[token][tokenId];
        require(auctionIds.length > 0, "getAuctionByNftId: no auction");
        
        uint256 auctionId = auctionIds[auctionIds.length - 1];
        return (_auctions[auctionId], _auctionStatus[auctionId], _bids[auctionId]);
    }

    function createAuction(
        uint256 auctionId, 
        uint256 tokenId, 
        address tokenContract, 
        uint256 duration, 
        uint256 reservePrice, 
        uint8   curatorFeePercentage, 
        address tokenOwner, 
        address payable curator, 
        address auctionCurrency) 
            external 
            override 
            onlyOwner 
    {
        IAuctionHouse.Auction storage auction = _auctions[auctionId];
        auction.tokenId = tokenId;
        auction.tokenContract = tokenContract;
        auction.duration = duration;
        auction.reservePrice = reservePrice;
        auction.curatorFeePercentage = curatorFeePercentage;
        auction.tokenOwner = tokenOwner;
        auction.curator = curator;
        auction.auctionCurrency = auctionCurrency;

        AuctionStatus storage auctionStatus = _auctionStatus[auctionId];
        auctionStatus.createTime = block.timestamp;
        // auctionStatus.endTime = 0;
        // auctionStatus.curatorFee = 0;
        // auctionStatus.tokenOwnerProfit = 0;
        auctionStatus.state = State.Create;    

        _safePush(_tokens, tokenContract);
        _safePush(_tokenIds[tokenContract], tokenId);
        
        _auctionIds[tokenContract][tokenId].push(auctionId);

        if (auctionId > _maxAuctionId) {
            _maxAuctionId = auctionId;
        }
    }

    function setAuctionApproval(uint256 auctionId, bool approved) external override onlyOwner {
        _auctions[auctionId].approved = approved;
        _auctionStatus[auctionId].state = approved ? State.Approval : State.Create;
    }

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external override onlyOwner {
        _auctions[auctionId].reservePrice = reservePrice;
    }
    
    function createBid(uint256 auctionId, address bidder, uint256 amount, uint256 duration) external override onlyOwner {
        _auctionStatus[auctionId].state = State.InBid;

        IAuctionHouse.Auction storage auction = _auctions[auctionId];
        auction.bidder = payable(bidder);
        auction.amount = amount;
        auction.duration = duration;

        if (auction.firstBidTime == 0) {
            auction.firstBidTime = block.timestamp;
        }
        
        Bid memory bid = Bid({
            amount: amount,
            time: block.timestamp,
            bidder: bidder
        });

        _bids[auctionId].push(bid);
    }

    function cancelAuction(uint256 auctionId) external override onlyOwner {
        AuctionStatus storage auctionStatus = _auctionStatus[auctionId];
        auctionStatus.state = State.Cancel;
        auctionStatus.endTime = block.timestamp;
    }

    function endAuction(uint256 auctionId, uint256 curatorFee, uint256 tokenOwnerProfit) external override onlyOwner {
        AuctionStatus storage auctionStatus = _auctionStatus[auctionId];
        auctionStatus.state = State.End;
        auctionStatus.endTime = block.timestamp;
        auctionStatus.curatorFee = curatorFee;
        auctionStatus.tokenOwnerProfit = tokenOwnerProfit;
    }

    function getCreater() external view returns(address) {
        return _creater;
    }

    /// @notice set creator to 0 when finished 
    function setCreater(address creater) external {
        require(_creater == _msgSender(), "only creater");
        _creater = creater;
    }

    /// @dev this function assumes current contract has no data at this time
    function migrateOldData(address oldBidDb) external {
        require(_creater == _msgSender(), "only creater");

        for (uint256 i = 0; i < _maxOldAuctionId; i++) {
            delete _auctions[i];
            delete _auctionStatus[i];
            delete _bids[i];

            IAuctionHouse.Auction memory oldAuction = _getOldAuction(oldBidDb, i);
            if (oldAuction.tokenOwner == address(0)) {
                continue;
            }

            if (i > _maxAuctionId) {
                _maxAuctionId = i;
            }
            
            _auctions[i] = oldAuction;
            
            IBidDb.Bid[] memory oldBids = _getOldBids(oldBidDb, i);
            for (uint256 j = 0; j < oldBids.length; j++) {
                _bids[i].push(oldBids[j]);
            }
            
            IBidDb.Status memory oldStatus = _getOldStatus(oldBidDb, i);
            AuctionStatus storage auctionStatus = _auctionStatus[i];
            auctionStatus.createTime = oldStatus.beginTime;
            // old BidDb has no auctionStatus.endTime
            auctionStatus.curatorFee = oldStatus.curatorFee;
            auctionStatus.tokenOwnerProfit = oldStatus.tokenOwnerProfit;
            auctionStatus.state = oldStatus.state;

            _auctionIds[oldAuction.tokenContract][oldAuction.tokenId].push(i);

            _safePush(_tokens, oldAuction.tokenContract);
            _safePush(_tokenIds[oldAuction.tokenContract], oldAuction.tokenId);
        }
    }

    function _getOldAuction(address oldBidDb, uint256 auctionId) internal view returns (IAuctionHouse.Auction memory) {
        (bool success, bytes memory returnData) = oldBidDb.staticcall(abi.encodeWithSignature("auctions(uint256)", auctionId));

        if (!success) {
            revert(_getRevertMessage(returnData));
        }

        return abi.decode(returnData, (IAuctionHouse.Auction));
    }

    function _getOldStatus(address oldBidDb, uint256 auctionId) internal view returns (IBidDb.Status memory) {
        (bool success, bytes memory returnData) = oldBidDb.staticcall(abi.encodeWithSignature("getBidStatus(uint256)", auctionId));

        if (!success) {
            revert(_getRevertMessage(returnData));
        }

        return abi.decode(returnData, (IBidDb.Status));
    }


    function _getOldBids(address oldBidDb, uint256 auctionId) internal view returns (IBidDb.Bid[] memory) {
        (bool success, bytes memory returnData) = oldBidDb.staticcall(abi.encodeWithSignature("getBidHistory(uint256)", auctionId));

        if (!success) {
            revert(_getRevertMessage(returnData));
        }

        return abi.decode(returnData, (IBidDb.Bid[]));
    }

    function _getRevertMessage(bytes memory revertData) internal pure returns (string memory message) {
        uint256 dataLen = revertData.length;

        if (dataLen < 68) {
            message = "Transaction reverted silently";
        } else {
            uint256 t;
            assembly {
                revertData := add(revertData, 4)
                t := mload(revertData) // Save the content of the length slot
                mstore(revertData, sub(dataLen, 4)) // Set proper length
            }
            message = abi.decode(revertData, (string));
            assembly {
                mstore(revertData, t) // Restore the content of the length slot
            }
        }
    }

    /// @dev If array does not contans value, then push to tail; else do nothing.
    function _safePush(uint256[] storage array, uint256 value) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return;               
            }
        }

        array.push(value);
    }

    function _safePush(address[] storage array, address value) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return;               
            }
        }

        array.push(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for Auction Houses
 */
interface IAuctionHouse {
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

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import { IAuctionHouse } from "./IAuctionHouse.sol";

/**
 * @title Interface for IBidDb
 */
interface IBidDb {
    enum State {
        Create, // not approved
        Approval, // approved
        InBid, // has bid
        Cancel, // canceled when has no bid
        End // ended when has bid
    }

    struct Status {
        uint256 beginTime;
        uint256 curatorFee;
        uint256 tokenOwnerProfit;
        address winner; // 20 bytes
        uint88 count;   // 11 bytes, size of bid array
        State state;    // 1 byte
    }

    struct Bid {
        uint256 time;
        uint256 amount;
        address bidder; 
    }

    struct BidStatus {
        Status status;
        Bid[] bids;
    }

    struct AuctionStatus {
        uint256 createTime;       // time of call createAuction
        uint256 endTime;          // time of call endAuction or cancelAuction
        uint256 curatorFee;       // pay to curator when end
        uint256 tokenOwnerProfit; // pay to owner when end
        State   state;            // auction state, 1 byte
    }

    function getMaxOldAuctionId() external view returns(uint256);

    function getMaxAuctionId() external view returns(uint256);

    function getTokens() external view returns(address[] memory);
    function getTokens(uint256 offset, uint256 limit) external view returns(address[] memory);

    function getTokenIds(address token) external view returns(uint256[] memory);
    function getTokenIds(address token, uint256 offset, uint256 limit) external view returns(uint256[] memory);

    function getAuction(uint256 auctionId) external view returns(IAuctionHouse.Auction memory, AuctionStatus memory, Bid[] memory);
    function getAuctionByTokenId(address token, uint256 tokenId) external view returns(IAuctionHouse.Auction memory, AuctionStatus memory, Bid[] memory);

    function createAuction(
        uint256 auctionId, 
        uint256 tokenId, 
        address tokenContract, 
        uint256 duration, 
        uint256 reservePrice, 
        uint8 curatorFeePercentage, 
        address tokenOwner, 
        address payable curator, 
        address auctionCurrency) external;

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external ;
    
    function createBid(uint256 auctionId, address bidder, uint256 amount, uint256 duration) external;

    function cancelAuction(uint256 auctionId) external;

    function endAuction(uint256 auctionId, uint256 curatorFee, uint256 tokenOwnerProfit) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}