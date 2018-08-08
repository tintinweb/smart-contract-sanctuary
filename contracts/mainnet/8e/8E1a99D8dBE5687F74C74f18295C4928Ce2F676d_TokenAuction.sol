pragma solidity ^0.4.15;

/**
 *
 * @author  David Rosen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6d060c0c03090204192d000e020343021f0a">[email&#160;protected]</a>>
 *
 * Version Test-D
 *
 * Overview:
 * This contract impliments a blind auction for burnable tokens. Each secret bid consists
 * of a hashed bid-tuple, (`price`, `quantity`, `salt`), where price is the maximum amount
 * of ether (in wei) a user is willing to pay per token, quantity is the number of tokens
 * the user wants to buy, and salt is an arbitrary value. Together with the hashed bid-tuple,
 * the user includes an encrypted bid tuple, using the public key of the party running the
 * auction, and of course a deposit sufficient to pay for the bid.
 *
 * At the end of the bidding period, the party running the auction sets a &#39;strike price&#39;,
 * thereby signaling the start of the sale period. During this period all bidders must
 * execute their bids. To execute a bid a user reveals their bid-tuple. All bids with a
 * price at least as high as the strike price are filled, and all bids under the strike
 * price are returned. Bids that are exactly equal to the strike price are partially filled,
 * so that the maximum number of tokens generated does not exceed the total supply.
 *
 * Strike Price:
 * The strike price is calculated offchain by the party running the auction. When each
 * secret bid is submitted an event is generated, which includes the sender address, hashed
 * bid-tuple, encrypted bid-tuple and deposit amount. the party running the auction decrypts
 * the encrypted bid-tuple, and regenerates the hash. If the regenerated hash does not match
 * the hash that was submitted with the secret bid, or if the desposited funds are not
 * sufficient to cover the bid, then the bid is disqualified. (presumably disqualifying
 * invalid bids will be cheaper than validating all the valid bids).
 *
 * The auction is structured with a fixed maximum number of tokens. So to raise the maximum
 * funds the bids are sorted, highest to lowest. Starting the strike-price at the highest
 * bid, it is reduced, bid by bid, to include more bids. The quantity of tokens sold increases
 * each time a new bid is included; but the the token price is reduced. At each step the
 * total raise (token-price times quantity-of-tokens-sold) is computed. And the process ends
 * whenever the total raise decreases, or when the total number of tokens exceeds the total
 * supply.
 *
 * Notes:
 * The `salt` is included in the bid-tuple to discourage brute-force attacks on the inputs
 * to the secret bid.
 *
 * A user cannot submit multiple bids from the same Ether account.
 *
 * Users are required to execute their bids. If a user fails to execute their bid before the
 * end of the sale period, then they forfeit half of their deposit, and receive no tokens.
 * This rule was adopted to prevent users from placing several bids, and only revealing one
 * of them. With this rule, all bids must be executed.
 *
 */

// Token standard API
// https://github.com/ethereum/EIPs/issues/20

contract iERC20Token {
  function totalSupply() constant returns (uint supply);
  function balanceOf( address who ) constant returns (uint value);
  function allowance( address owner, address spender ) constant returns (uint remaining);

  function transfer( address to, uint value) returns (bool ok);
  function transferFrom( address from, address to, uint value) returns (bool ok);
  function approve( address spender, uint value ) returns (bool ok);

  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);
}

//Burnable Token interface

contract iBurnableToken is iERC20Token {
  function burnTokens(uint _burnCount) public;
  function unPaidBurnTokens(uint _burnCount) public;
}


/*
    Overflow protected math functions
*/
contract SafeMath {
    /**
        constructor
    */
    function SafeMath() {
    }

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract TokenAuction is SafeMath {

  struct SecretBid {
    bool disqualified;     // flag set if hash does not match encrypted bid
    uint deposit;          // funds deposited by bidder
    uint refund;           // funds to be returned to bidder
    uint tokens;           // structure has been allocated
    bytes32 hash;          // hash of price, quantity, secret
  }
  uint constant  AUCTION_START_EVENT = 0x01;
  uint constant  AUCTION_END_EVENT   = 0x02;
  uint constant  SALE_START_EVENT    = 0x04;
  uint constant  SALE_END_EVENT      = 0x08;

  event SecretBidEvent(uint indexed batch, address indexed bidder, uint deposit, bytes32 hash, bytes message);
  event ExecuteEvent(uint indexed batch, address indexed bidder, uint cost, uint refund);
  event ExpireEvent(uint indexed batch, address indexed bidder, uint cost, uint refund);
  event BizarreEvent(address indexed addr, string message, uint val);
  event StateChangeEvent(uint mask);
  //
  //event MessageEvent(string message);
  //event MessageUintEvent(string message, uint val);
  //event MessageAddrEvent(string message, address val);
  //event MessageBytes32Event(string message, bytes32 val);

  bool public isLocked;
  uint public stateMask;
  address public owner;
  address public developers;
  address public underwriter;
  iBurnableToken public token;
  uint public proceeds;
  uint public strikePrice;
  uint public strikePricePctX10;
  uint public developerReserve;
  uint public developerPctX10;
  uint public purchasedCount;
  uint public secretBidCount;
  uint public executedCount;
  uint public expiredCount;
  uint public saleDuration;
  uint public auctionStart;
  uint public auctionEnd;
  uint public saleEnd;
  mapping (address => SecretBid) public secretBids;

  //
  //tunables
  uint batchSize = 4;
  uint contractSendGas = 100000;

  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

  modifier unlockedOnly {
    require(!isLocked);
    _;
  }

  modifier duringAuction {
    require((stateMask & (AUCTION_START_EVENT | AUCTION_END_EVENT)) == AUCTION_START_EVENT);
    _;
  }

  modifier afterAuction {
    require((stateMask & AUCTION_END_EVENT) != 0);
    _;
  }

  modifier duringSale {
    require((stateMask & (SALE_START_EVENT | SALE_END_EVENT)) == SALE_START_EVENT);
    _;
  }

  modifier afterSale {
    require((stateMask & SALE_END_EVENT) != 0);
    _;
  }


  //
  //constructor
  //
  function TokenAuction() {
    owner = msg.sender;
  }

  function lock() public ownerOnly {
    isLocked = true;
  }

  function setAuctionParms(iBurnableToken _token, address _underwriter, uint _auctionStart, uint _auctionDuration, uint _saleDuration) public ownerOnly unlockedOnly {
    token = _token;
    underwriter = _underwriter;
    auctionStart = _auctionStart;
    auctionEnd = safeAdd(_auctionStart, _auctionDuration);
    saleDuration = _saleDuration;
    if (stateMask != 0) {
      //handy for debug
      stateMask = 0;
      strikePrice = 0;
      purchasedCount = 0;
      houseKeep();
    }
  }

  function reserveDeveloperTokens(address _developers, uint _developerPctX10) public ownerOnly unlockedOnly {
    developers = _developers;
    developerPctX10 = _developerPctX10;
    uint _tokenCount = token.balanceOf(this);
    developerReserve = (safeMul(_tokenCount, developerPctX10) / 1000);
  }

  function tune(uint _batchSize, uint _contractSendGas) public ownerOnly {
    batchSize = _batchSize;
    contractSendGas = _contractSendGas;
  }


  //
  //called by owner (or any other concerned party) to generate a SatateChangeEvent
  //
  function houseKeep() public {
    uint _oldMask = stateMask;
    if (now >= auctionStart) {
      stateMask |= AUCTION_START_EVENT;
      if (now >= auctionEnd) {
        stateMask |= AUCTION_END_EVENT;
        if (strikePrice > 0) {
          stateMask |= SALE_START_EVENT;
          if (now >= saleEnd)
            stateMask |= SALE_END_EVENT;
        }
      }
    }
    if (stateMask != _oldMask)
      StateChangeEvent(stateMask);
  }



  //
  //setting the strike price starts the sale period, during which bidders must call executeBid.
  //the strike price should only be set once.... at any rate it cannot be changed once anyone has executed a bid.
  //strikePricePctX10 specifies what percentage (x10) of requested tokens should be awarded to each bidder that
  //bid exactly equal to the strike price.
  //
  function setStrikePrice(uint _strikePrice, uint _strikePricePctX10) public ownerOnly afterAuction {
    require(executedCount == 0);
    strikePrice = _strikePrice;
    strikePricePctX10 = _strikePricePctX10;
    saleEnd = safeAdd(now, saleDuration);
    houseKeep();
  }


  //
  // nobody should be sending funds via this function.... bizarre...
  // the fact that we adjust proceeds here means that this fcn will OOG if called with a send or transfer. that&#39;s
  // probably good, cuz it prevents the caller from losing their funds.
  //
  function () payable {
    proceeds = safeAdd(proceeds, msg.value);
    BizarreEvent(msg.sender, "bizarre payment", msg.value);
  }


  function depositSecretBid(bytes32 _hash, bytes _message) public duringAuction payable {
    //each address can only submit one bid -- and once a bid is submitted it is imutable
    //for testing, an exception is made for the owner -- but only while the contract is unlocked
    if (!(msg.sender == owner && !isLocked) &&
         (_hash == 0 || secretBids[msg.sender].hash != 0) )
        revert();
    secretBids[msg.sender].hash = _hash;
    secretBids[msg.sender].deposit = msg.value;
    secretBidCount += 1;
    uint _batch = secretBidCount / batchSize;
    SecretBidEvent(_batch, msg.sender, msg.value, _hash, _message);
  }


  //
  // the owner may disqualify a bid if it is bogus. for example if the hash does not correspond
  // to the hash that is generated from the encyrpted bid tuple. when a disqualified bid is
  // executed all the deposited funds will be returned to the bidder, as if the bid was below
  // the strike-price.
  function disqualifyBid(address _from) public ownerOnly duringAuction {
    secretBids[msg.sender].disqualified = true;
  }


  //
  // execute a bid.
  // * purchases tokens if the specified price is above the strike price
  // * refunds whatever remains of the deposit
  //
  // call only during the sale period (strikePrice > 0)
  //
  function executeBid(uint256 _secret, uint256 _price, uint256 _quantity) public duringSale {
    executeBidFor(msg.sender, _secret, _price, _quantity);
  }
  function executeBidFor(address _addr, uint256 _secret, uint256 _price, uint256 _quantity) public duringSale {
    bytes32 computedHash = keccak256(_secret, _price, _quantity);
    //MessageBytes32Event("computedHash", computedHash);
    require(secretBids[_addr].hash == computedHash);
    //
    if (secretBids[_addr].deposit > 0) {
      uint _cost = 0;
      uint _refund = 0;
      if (_price >= strikePrice && !secretBids[_addr].disqualified) {
        uint256 _purchaseCount = (_price > strikePrice) ? _quantity : (safeMul(strikePricePctX10, _quantity) / 1000);
        var _maxPurchase = token.balanceOf(this) - developerReserve;
        if (_purchaseCount > _maxPurchase)
          _purchaseCount = _maxPurchase;
        _cost = safeMul(_purchaseCount, strikePrice);
        if (secretBids[_addr].deposit >= _cost) {
          secretBids[_addr].deposit -= _cost;
          proceeds = safeAdd(proceeds, _cost);
          secretBids[_addr].tokens += _purchaseCount;
          purchasedCount += _purchaseCount;
          //transfer tokens to this bidder
          if (!token.transfer(_addr, _purchaseCount))
            revert();
        }
      }
      //refund whatever remains
      //use pull here, to prevent any bidder from reverting their purchase
      if (secretBids[_addr].deposit > 0) {
        _refund = secretBids[_addr].deposit;
        secretBids[_addr].refund += _refund;
        secretBids[_addr].deposit = 0;
      }
      executedCount += 1;
      uint _batch = executedCount / batchSize;
      ExecuteEvent(_batch, _addr, _cost, _refund);
    }
  }


  //
  // expireBid
  // if a bid is not executed during the sale period, then the owner can mark the bid as expired. in this case:
  // * the bidder gets a refund of half of his deposit
  // * the bidder forfeits the other half of his deposit
  // * the bidder does not receive an tokens
  //
  function expireBid(address _addr) public ownerOnly afterSale {
    if (secretBids[_addr].deposit > 0) {
      uint _forfeit = secretBids[_addr].deposit / 2;
      proceeds = safeAdd(proceeds, _forfeit);
      //refund whatever remains
      uint _refund = safeSub(secretBids[_addr].deposit, _forfeit);
      //use pull here, to prevent any bidder from reverting the expire
      secretBids[msg.sender].refund += _refund;
      secretBids[_addr].deposit = 0;
      expiredCount += 1;
      uint _batch = expiredCount / batchSize;
      ExpireEvent(_batch, _addr, _forfeit, _refund);
    }
  }


  //
  // bidder withdraw excess funds (or all funds if bid was too low)
  //
  function withdrawRefund() public {
    uint _amount = secretBids[msg.sender].refund;
    secretBids[msg.sender].refund = 0;
    msg.sender.transfer(_amount);
  }


  //
  // grant developer tokens, equal to a percentage of purchased tokens.
  // once called, any remaining tokens will be burned.
  //
  function doDeveloperGrant() public afterSale {
    uint _quantity = purchasedCount * developerPctX10 / 1000;
    var _tokensLeft = token.balanceOf(this);
    if (_quantity > _tokensLeft)
      _quantity = _tokensLeft;
    if (_quantity > 0) {
      //transfer pct tokens to developers
      _tokensLeft -= _quantity;
      if (!token.transfer(developers, _quantity))
        revert();
    }
    //and burn everthing that remains
    token.unPaidBurnTokens(_tokensLeft);
  }


  //
  // pay auction proceeds to the underwriter
  // may be called by underwriter or owner (fbo underwriter)
  //
  function payUnderwriter() public {
    require(msg.sender == owner || msg.sender == underwriter);
    uint _amount = proceeds;
    proceeds = 0;
    if (!underwriter.call.gas(contractSendGas).value(_amount)())
      revert();
  }


  //for debug
  //only available before the contract is locked
  function haraKiri() ownerOnly unlockedOnly {
    selfdestruct(owner);
  }
}