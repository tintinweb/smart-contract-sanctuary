pragma solidity ^0.4.21;

// Contract for Auction of the starship Astra Kal
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


// This is an interface which creates a symbol for the starships ERC721 contracts. 
// The ERC721 contracts will be published later, before the auction ends.  

contract starShipTokenInterface {
    string public name;
    string public symbol;
    uint256 public ID;
    address public owner;

    function transfer(address _to) public returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to);
}


contract starShipToken is starShipTokenInterface {
    using SafeMath for uint256;

  
  constructor(string _name, string _symbol, uint256 _ID) public {
    name = _name;
    symbol = _symbol;
    ID = _ID;
    owner = msg.sender;
  }

  /**
  * @dev Gets the owner of the token.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function viewOwner() public view returns (address) {
    return owner;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  */
  function transfer(address _to) public returns (bool) {
    require(_to != address(0));
    require(msg.sender == owner);

    owner = _to;
    emit Transfer(msg.sender, _to);
    return true;
  }
}

// contract for implementing the auction in Hot Potato format
contract hotPotatoAuction {
    // The token that is going up for auction
    starShipToken public token;
    
    // The total number of bids on the current starship
    uint256 public totalBids;
    
    // starting bid of the starship
    uint256 public startingPrice;
    
    // current Bid amount
    uint256 public currentBid;
    
    // Minimum amount needed to bid on this item
    uint256 public currentMinBid;
    
    // The time at which the auction will end
    uint256 public auctionEnd;
    
    // Variable to store the hot Potato prize for the loser bid
    uint256 public hotPotatoPrize;
    
    // The seller of the current item
    address public seller;
    
    
    address public highBidder;
    address public loser;

    function hotPotatoAuction(
        starShipToken _token,
        uint256 _startingPrice,
        uint256 _auctionEnd
    )
        public
    {
        token = _token;
        startingPrice = _startingPrice;
        currentMinBid = _startingPrice;
        totalBids = 0;
        seller = msg.sender;
        auctionEnd = _auctionEnd;
        hotPotatoPrize = _startingPrice;
        currentBid = 0;
    }
    
    mapping(address => uint256) public balanceOf;

    /** 
     *  @dev withdrawBalance from the contract address
     *  @param amount that you want to withdrawBalance
     * 
     */
     
    function withdrawBalance(uint256 amount) returns(bool) {
        require(amount <= address(this).balance);
        require (msg.sender == seller);
        seller.transfer(amount);
        return true;
    }

    /** 
     *  @dev withdraw from the Balance array
     * 
     */
    function withdraw() public returns(bool) {
        require(msg.sender != highBidder);
        
        uint256 amount = balanceOf[loser];
        balanceOf[loser] = 0;
        loser.transfer(amount);
        return true;
    }
    

    event Bid(address highBidder, uint256 highBid);

    function bid() public payable returns(bool) {
        require(now < auctionEnd);
        require(msg.value >= startingPrice);
        require (msg.value >= currentMinBid);
        
        if(totalBids !=0)
        {
            loser = highBidder;
        
            require(withdraw());
        }
        
        highBidder = msg.sender;
        
        currentBid = msg.value;
        
        hotPotatoPrize = currentBid/20;
        
        balanceOf[msg.sender] = msg.value + hotPotatoPrize;
        
        if(currentBid < 1000000000000000000)
        {
            currentMinBid = msg.value + currentBid/2;
            hotPotatoPrize = currentBid/20; 
        }
        else
        {
            currentMinBid = msg.value + currentBid/5;
            hotPotatoPrize = currentBid/20;
        }
        
        totalBids = totalBids + 1;
        
        return true;
        emit Bid(highBidder, msg.value);
    }

    function resolve() public {
        require(now >= auctionEnd);
        require(msg.sender == seller);
        require (highBidder != 0);
        
        require (token.transfer(highBidder));

        balanceOf[seller] += balanceOf[highBidder];
        balanceOf[highBidder] = 0;
        highBidder = 0;
    }
    /** 
     *  @dev view balance of contract
     */
     
    function getBalanceContract() constant returns(uint){
        return address(this).balance;
    }
}