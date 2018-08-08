pragma solidity ^0.4.21;







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
  function Ownable() public {
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
contract Bidding is Pausable
{
    struct Auction
    {
        uint128 highestBid;
        address highestBidder;
        uint40 timeEnd;
        uint40 lastBidTime;
        uint40 timeStart;
    }

    address public operatorAddress;

    Auction[] public auctions;

    // Allowed withdrawals of previous bids
    mapping(address => uint) public pendingReturns;
    uint public totalReturns;

    event Bid(address indexed bidder, address indexed prevBider, uint256 value, uint256 addedValue, uint40 auction);
    event Withdraw(address indexed bidder, uint256 value);

    function getAuctions(address bidder) public view returns (
        uint40[5] _timeEnd,
        uint40[5] _lastBidTime,
        uint256[5] _highestBid,
        address[5] _highestBidder,
        uint16[5] _auctionIndex,
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
                j++;
                if (j >= 5)
                {
                    break;
                }
            }
        }
    }

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

    function finish(uint16 auction) public onlyOperator
    {
        auctions[auction].timeEnd = 0;
    }

    function addAuction(uint40 _startTime, uint40 _duration, uint128 _startPrice) public onlyOperator
    {
        auctions.push(Auction(_startPrice, address(0), _startTime + _duration, 0, _startTime));
    }

    function isEnded(uint16 auction) public view returns (bool)
    {
        return auctions[auction].timeEnd < now;
    }

    function isActive(uint16 auction) public view returns (bool)
    {
        return auctions[auction].timeStart <= now && now <= auctions[auction].timeEnd;
    }

    function bid(uint16 auction, uint256 useFromPendingReturn) public payable whenNotPaused
    {
        address prevBidder = auctions[auction].highestBidder;
        uint256 returnValue = auctions[auction].highestBid;

        require (useFromPendingReturn <= pendingReturns[msg.sender]);

        uint256 bank = useFromPendingReturn;
        pendingReturns[msg.sender] -= bank;
        totalReturns -= bank;

        uint256 currentBid = bank + msg.value;

        require(currentBid > auctions[auction].highestBid ||
                currentBid == auctions[auction].highestBid && prevBidder == address(0));
        require(isActive(auction));

        auctions[auction].highestBid = uint128(currentBid);
        auctions[auction].highestBidder = msg.sender;
        auctions[auction].lastBidTime = uint40(now);

        emit Bid(msg.sender, prevBidder, currentBid, currentBid - returnValue, auction);

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

    function destroyContract() public onlyOwner {
        require(address(this).balance == 0);
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