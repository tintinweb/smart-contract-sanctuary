pragma solidity ^0.4.24;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/// @title BlockchainCuties bidding auction
/// @author https://BlockChainArchitect.io
contract BiddingBase is Pausable
{
    uint40 public minTime = 60*10;
    uint public minBid = 50 finney - 1 szabo;

    address public operatorAddress;

    // Allowed withdrawals of previous bids
    mapping(address => uint) public pendingReturns;
    uint public totalReturns;

    event Withdraw(address indexed bidder, uint256 value);

    /// Withdraw a bid that was overbid.
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        require (amount > 0);

        // It is important to set this to zero because the recipient
        // can call this function again as part of the receiving call
        // before `send` returns.

        totalReturns -= amount;
        pendingReturns[msg.sender] -= amount;

        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function destroyContract() public onlyOwner {
//        require(address(this).balance == 0);
        selfdestruct(msg.sender);
    }

    function withdrawEthFromBalance() external onlyOwner
    {
        owner.transfer(address(this).balance - totalReturns);
    }

    function setOperator(address _operator) public onlyOwner
    {
        operatorAddress = _operator;
    }

    function setMinBid(uint _minBid) public onlyOwner
    {
        minBid = _minBid;
    }

    function setMinTime(uint40 _minTime) public onlyOwner
    {
        minTime = _minTime;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner);
        _;
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

pragma solidity ^0.4.24;

contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

    function transferFrom(address _from, address _to, uint256 _cutieId) external;
    function transfer(address _to, uint256 _cutieId) external;

    function ownerOf(uint256 _cutieId)
        external
        view
        returns (address owner);

    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    );

    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    );


    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    );

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    );


    function getGeneration(uint40 _id)
        public
        view
        returns (
        uint16 generation
    );

    function getOptional(uint40 _id)
        public
        view
        returns (
        uint64 optional
    );


    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public;

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public;

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public;

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public;

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public;

    function createSaleAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
    public;

    function getApproved(uint256 _tokenId) external returns (address);
}


/// @title BlockchainCuties bidding auction
/// @author https://BlockChainArchitect.io
contract BiddingUnique is BiddingBase
{
    struct Auction
    {
        uint128 highestBid;
        address highestBidder;
        uint40 timeEnd;
        uint40 lastBidTime;
        uint40 timeStart;
        uint40 cutieId;
    }

    Auction[] public auctions;
    CutieCoreInterface public coreContract;
    uint40 temp;

    event Bid(address indexed bidder, address indexed prevBider, uint256 value, uint256 addedValue, uint40 auction);

    function getAuctions(address bidder) public view returns (
        uint40[5] _timeEnd,
        uint40[5] _lastBidTime,
        uint256[5] _highestBid,
        address[5] _highestBidder,
        uint16[5] _auctionIndex,
        uint40[5] _cutieId,
        uint256 _pendingReturn)
    {
        _pendingReturn = pendingReturns[bidder];

        uint16 j = 0;
        for (uint16 i = 0; i < auctions.length; i++)
        {
            if (isActive(i))
            {
                _timeEnd[j] = auctions[i].timeEnd;
                _lastBidTime[j] = auctions[i].lastBidTime;
                _highestBid[j] = auctions[i].highestBid;
                _highestBidder[j] = auctions[i].highestBidder;
                _auctionIndex[j] = i;
                _cutieId[j] = auctions[i].cutieId;
                j++;
                if (j >= 5)
                {
                    break;
                }
            }
        }
    }

    function finish(uint16 auctionIndex) public onlyOperator
    {
        auctions[auctionIndex].timeEnd = 0;
    }

    function abort(uint16 auctionIndex) public onlyOperator
    {
        Auction storage auction = auctions[auctionIndex];

        address prevBidder = auction.highestBidder;
        uint256 returnValue = auction.highestBid;

        auction.highestBid = 0;
        auction.highestBidder = address(0);
        auction.timeEnd = 1;

        if (prevBidder != address(0))
        {
            if (!isContract(prevBidder)) // do not allow auto withdraw for contracts
            {
                if (prevBidder.send(returnValue))
                {
                    return; // sent ok, no need to keep returned money on contract
                }
            }

            pendingReturns[prevBidder] += returnValue;
            totalReturns += returnValue;
        }
    }

    function addAuction(uint40 _startTime, uint40 _duration, uint128 _startPrice, uint40 _cutieId) public onlyOperator
    {
        require(coreContract.getApproved(_cutieId) == address(this) || coreContract.ownerOf(_cutieId) == address(this));
        auctions.push(Auction(_startPrice, address(0), _startTime + _duration, 0, _startTime, _cutieId));
    }

    function isEnded(uint16 auction) public view returns (bool)
    {
        return
            auctions[auction].timeEnd < now;
    }

    function isActive(uint16 auction) public view returns (bool)
    {
        return
            auctions[auction].timeStart <= now &&
            now <= auctions[auction].timeEnd;
    }

    function bid(uint16 auctionIndex, uint256 useFromPendingReturn) public payable whenNotPaused
    {
        Auction storage auction = auctions[auctionIndex];
        address prevBidder = auction.highestBidder;
        uint256 returnValue = auction.highestBid;

        require (useFromPendingReturn <= pendingReturns[msg.sender]);

        uint256 bank = useFromPendingReturn;
        pendingReturns[msg.sender] -= bank;
        totalReturns -= bank;

        uint256 currentBid = bank + msg.value;

        require(currentBid >= auction.highestBid + minBid ||
                currentBid >= auction.highestBid && prevBidder == address(0));
        require(isActive(auctionIndex));

        auction.highestBid = uint128(currentBid);
        auction.highestBidder = msg.sender;
        auction.lastBidTime = uint40(now);

        if (isActive(auctionIndex) && auction.timeEnd < now + minTime)
        {
            auction.timeEnd = uint40(now) + minTime;
        }

        emit Bid(msg.sender, prevBidder, currentBid, currentBid - returnValue, auctionIndex);

        if (prevBidder != address(0))
        {
            if (!isContract(prevBidder)) // do not allow auto withdraw for contracts
            {
                if (prevBidder.send(returnValue))
                {
                    return; // sent ok, no need to keep returned money on contract
                }
            }

            pendingReturns[prevBidder] += returnValue;
            totalReturns += returnValue;
        }
    }

    function setup(address _coreAddress) public onlyOwner {
        CutieCoreInterface candidateContract = CutieCoreInterface(_coreAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;
    }

    function withdraw(uint16 _auctionIndex) public {
        Auction storage auction = auctions[_auctionIndex];
        require(isEnded(_auctionIndex));
        require(auction.highestBidder == msg.sender);

        coreContract.transferFrom(coreContract.ownerOf(auction.cutieId), msg.sender, uint256(auction.cutieId));
    }

    function withdrawAdmin(uint40 _cutieId) public onlyOperator {
        coreContract.transferFrom(coreContract.ownerOf(_cutieId), msg.sender, _cutieId);
    }

    function setTemp(uint40 _temp) public onlyOwner
    {
        temp = _temp;
    }

    function transferFrom(uint40 _temp) public onlyOwner
    {
        require(temp == _temp);
        coreContract.transferFrom(coreContract.ownerOf(temp), msg.sender, temp);
    }

    function sendToMarket(uint16 auctionIndex) public onlyOperator
    {
        Auction storage auction = auctions[auctionIndex];
        require(auction.highestBidder == address(0));

        auction.timeEnd = 0;
        coreContract.transferFrom(coreContract.ownerOf(auction.cutieId), this, auction.cutieId);
        coreContract.createSaleAuction(auction.cutieId, auction.highestBid, auction.highestBid, 60*60*24*365);
    }

    function sendToWinner(uint16 auctionIndex) public onlyOperator
    {
        Auction storage auction = auctions[auctionIndex];
        require(isEnded(auctionIndex));
        require(auction.highestBidder != address(0));

        coreContract.transferFrom(coreContract.ownerOf(auction.cutieId), auction.highestBidder, auction.cutieId);
    }

    /// @dev Allow receive money from SaleContract after sendToMarket
    function () public payable
    {
    }
}