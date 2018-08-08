pragma solidity ^0.4.4;

// ------------------------------------------------------------------------
// TokenTraderFactory
//
// Decentralised trustless ERC20-compliant token to ETH exchange contract
// on the Ethereum blockchain.
//
// Note that this TokenTrader cannot be used with the Golem Network Token
// directly as the token does not implement the ERC20
// transferFrom(...), approve(...) and allowance(...) methods
//
// History:
//   Jan 25 2017 - BPB Added makerTransferAsset(...) and
//                     makerTransferEther(...)
//   Feb 05 2017 - BPB Bug fix in the change calculation for the Unicorn
//                     token with natural number 1
//   Feb 08 2017 - BPB/JL Renamed etherValueOfTokensToSell to
//                     amountOfTokensToSell in takerSellAsset(...) to
//                     better describe the parameter
//                     Added check in createTradeContract(...) to prevent
//                     GNTs from being used with this contract. The asset
//                     token will need to have an allowance(...) function.
//
// Enjoy. (c) JonnyLatte & BokkyPooBah 2017. The MIT licence.
// ------------------------------------------------------------------------

// https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    modifier onlyOwnerOrTokenTraderWithSameOwner {
        if (msg.sender != owner && TokenTrader(msg.sender).owner() != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// contract can buy or sell tokens for ETH
// prices are in amount of wei per batch of token units

contract TokenTrader is Owned {

    address public asset;       // address of token
    uint256 public buyPrice;    // contract buys lots of token at this price
    uint256 public sellPrice;   // contract sells lots at this price
    uint256 public units;       // lot size (token-wei)

    bool public buysTokens;     // is contract buying
    bool public sellsTokens;    // is contract selling

    event ActivatedEvent(bool buys, bool sells);
    event MakerDepositedEther(uint256 amount);
    event MakerWithdrewAsset(uint256 tokens);
    event MakerTransferredAsset(address toTokenTrader, uint256 tokens);
    event MakerWithdrewERC20Token(address tokenAddress, uint256 tokens);
    event MakerWithdrewEther(uint256 ethers);
    event MakerTransferredEther(address toTokenTrader, uint256 ethers);
    event TakerBoughtAsset(address indexed buyer, uint256 ethersSent,
        uint256 ethersReturned, uint256 tokensBought);
    event TakerSoldAsset(address indexed seller, uint256 amountOfTokensToSell,
        uint256 tokensSold, uint256 etherValueOfTokensSold);

    // Constructor - only to be called by the TokenTraderFactory contract
    function TokenTrader (
        address _asset,
        uint256 _buyPrice,
        uint256 _sellPrice,
        uint256 _units,
        bool    _buysTokens,
        bool    _sellsTokens
    ) {
        asset       = _asset;
        buyPrice    = _buyPrice;
        sellPrice   = _sellPrice;
        units       = _units;
        buysTokens  = _buysTokens;
        sellsTokens = _sellsTokens;
        ActivatedEvent(buysTokens, sellsTokens);
    }

    // Maker can activate or deactivate this contract&#39;s buying and
    // selling status
    //
    // The ActivatedEvent() event is logged with the following
    // parameter:
    //   buysTokens   this contract can buy asset tokens
    //   sellsTokens  this contract can sell asset tokens
    //
    function activate (
        bool _buysTokens,
        bool _sellsTokens
    ) onlyOwner {
        buysTokens  = _buysTokens;
        sellsTokens = _sellsTokens;
        ActivatedEvent(buysTokens, sellsTokens);
    }

    // Maker can deposit ethers to this contract so this contract
    // can buy asset tokens.
    //
    // Maker deposits asset tokens to this contract by calling the
    // asset&#39;s transfer() method with the following parameters
    //   _to     is the address of THIS contract
    //   _value  is the number of asset tokens to be transferred
    //
    // Taker MUST NOT send tokens directly to this contract. Takers
    // MUST use the takerSellAsset() method to sell asset tokens
    // to this contract
    //
    // Maker can also transfer ethers from one TokenTrader contract
    // to another TokenTrader contract, both owned by the Maker
    //
    // The MakerDepositedEther() event is logged with the following
    // parameter:
    //   ethers  is the number of ethers deposited by the maker
    //
    // This method was called deposit() in the old version
    //
    function makerDepositEther() payable onlyOwnerOrTokenTraderWithSameOwner {
        MakerDepositedEther(msg.value);
    }

    // Maker can withdraw asset tokens from this contract, with the
    // following parameter:
    //   tokens  is the number of asset tokens to be withdrawn
    //
    // The MakerWithdrewAsset() event is logged with the following
    // parameter:
    //   tokens  is the number of tokens withdrawn by the maker
    //
    // This method was called withdrawAsset() in the old version
    //
    function makerWithdrawAsset(uint256 tokens) onlyOwner returns (bool ok) {
        MakerWithdrewAsset(tokens);
        return ERC20(asset).transfer(owner, tokens);
    }

    // Maker can transfer asset tokens from this contract to another
    // TokenTrader contract, with the following parameter:
    //   toTokenTrader  Another TokenTrader contract owned by the
    //                  same owner and with the same asset
    //   tokens         is the number of asset tokens to be moved
    //
    // The MakerTransferredAsset() event is logged with the following
    // parameters:
    //   toTokenTrader  The other TokenTrader contract owned by
    //                  the same owner and with the same asset
    //   tokens         is the number of tokens transferred
    //
    // The asset Transfer() event is also logged from this contract
    // to the other contract
    //
    function makerTransferAsset(
        TokenTrader toTokenTrader,
        uint256 tokens
    ) onlyOwner returns (bool ok) {
        if (owner != toTokenTrader.owner() || asset != toTokenTrader.asset()) {
            throw;
        }
        MakerTransferredAsset(toTokenTrader, tokens);
        return ERC20(asset).transfer(toTokenTrader, tokens);
    }

    // Maker can withdraw any ERC20 asset tokens from this contract
    //
    // This method is included in the case where this contract receives
    // the wrong tokens
    //
    // The MakerWithdrewERC20Token() event is logged with the following
    // parameter:
    //   tokenAddress  is the address of the tokens withdrawn by the maker
    //   tokens        is the number of tokens withdrawn by the maker
    //
    // This method was called withdrawToken() in the old version
    //
    function makerWithdrawERC20Token(
        address tokenAddress,
        uint256 tokens
    ) onlyOwner returns (bool ok) {
        MakerWithdrewERC20Token(tokenAddress, tokens);
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // Maker can withdraw ethers from this contract
    //
    // The MakerWithdrewEther() event is logged with the following parameter
    //   ethers  is the number of ethers withdrawn by the maker
    //
    // This method was called withdraw() in the old version
    //
    function makerWithdrawEther(uint256 ethers) onlyOwner returns (bool ok) {
        if (this.balance >= ethers) {
            MakerWithdrewEther(ethers);
            return owner.send(ethers);
        }
    }

    // Maker can transfer ethers from this contract to another TokenTrader
    // contract, with the following parameters:
    //   toTokenTrader  Another TokenTrader contract owned by the
    //                  same owner and with the same asset
    //   ethers         is the number of ethers to be moved
    //
    // The MakerTransferredEther() event is logged with the following parameter
    //   toTokenTrader  The other TokenTrader contract owned by the
    //                  same owner and with the same asset
    //   ethers         is the number of ethers transferred
    //
    // The MakerDepositedEther() event is logged on the other
    // contract with the following parameter:
    //   ethers  is the number of ethers deposited by the maker
    //
    function makerTransferEther(
        TokenTrader toTokenTrader,
        uint256 ethers
    ) onlyOwner returns (bool ok) {
        if (owner != toTokenTrader.owner() || asset != toTokenTrader.asset()) {
            throw;
        }
        if (this.balance >= ethers) {
            MakerTransferredEther(toTokenTrader, ethers);
            toTokenTrader.makerDepositEther.value(ethers)();
        }
    }

    // Taker buys asset tokens by sending ethers
    //
    // The TakerBoughtAsset() event is logged with the following parameters
    //   buyer           is the buyer&#39;s address
    //   ethersSent      is the number of ethers sent by the buyer
    //   ethersReturned  is the number of ethers sent back to the buyer as
    //                   change
    //   tokensBought    is the number of asset tokens sent to the buyer
    //
    // This method was called buy() in the old version
    //
    function takerBuyAsset() payable {
        if (sellsTokens || msg.sender == owner) {
            // Note that sellPrice has already been validated as > 0
            uint order    = msg.value / sellPrice;
            // Note that units has already been validated as > 0
            uint can_sell = ERC20(asset).balanceOf(address(this)) / units;
            uint256 change = 0;
            if (msg.value > (can_sell * sellPrice)) {
                change  = msg.value - (can_sell * sellPrice);
                order = can_sell;
            }
            if (change > 0) {
                if (!msg.sender.send(change)) throw;
            }
            if (order > 0) {
                if (!ERC20(asset).transfer(msg.sender, order * units)) throw;
            }
            TakerBoughtAsset(msg.sender, msg.value, change, order * units);
        }
        // Return user funds if the contract is not selling
        else if (!msg.sender.send(msg.value)) throw;
    }

    // Taker sells asset tokens for ethers by:
    // 1. Calling the asset&#39;s approve() method with the following parameters
    //    _spender            is the address of this contract
    //    _value              is the number of tokens to be sold
    // 2. Calling this takerSellAsset() method with the following parameter
    //    etherValueOfTokens  is the ether value of the asset tokens to be sold
    //                        by the taker
    //
    // The TakerSoldAsset() event is logged with the following parameters
    //   seller                  is the seller&#39;s address
    //   amountOfTokensToSell    is the amount of the asset tokens being
    //                           sold by the taker
    //   tokensSold              is the number of the asset tokens sold
    //   etherValueOfTokensSold  is the ether value of the asset tokens sold
    //
    // This method was called sell() in the old version
    //
    function takerSellAsset(uint256 amountOfTokensToSell) {
        if (buysTokens || msg.sender == owner) {
            // Maximum number of token the contract can buy
            // Note that buyPrice has already been validated as > 0
            uint256 can_buy = this.balance / buyPrice;
            // Token lots available
            // Note that units has already been validated as > 0
            uint256 order = amountOfTokensToSell / units;
            // Adjust order for funds available
            if (order > can_buy) order = can_buy;
            if (order > 0) {
                // Extract user tokens
                if (!ERC20(asset).transferFrom(msg.sender, address(this), order * units)) throw;
                // Pay user
                if (!msg.sender.send(order * buyPrice)) throw;
            }
            TakerSoldAsset(msg.sender, amountOfTokensToSell, order * units, order * buyPrice);
        }
    }

    // Taker buys tokens by sending ethers
    function () payable {
        takerBuyAsset();
    }
}

// This contract deploys TokenTrader contracts and logs the event
contract TokenTraderFactory is Owned {

    event TradeListing(address indexed ownerAddress, address indexed tokenTraderAddress,
        address indexed asset, uint256 buyPrice, uint256 sellPrice, uint256 units,
        bool buysTokens, bool sellsTokens);
    event OwnerWithdrewERC20Token(address indexed tokenAddress, uint256 tokens);

    mapping(address => bool) _verify;

    // Anyone can call this method to verify the settings of a
    // TokenTrader contract. The parameters are:
    //   tradeContract  is the address of a TokenTrader contract
    //
    // Return values:
    //   valid        did this TokenTraderFactory create the TokenTrader contract?
    //   owner        is the owner of the TokenTrader contract
    //   asset        is the ERC20 asset address
    //   buyPrice     is the buy price in ethers per `units` of asset tokens
    //   sellPrice    is the sell price in ethers per `units` of asset tokens
    //   units        is the number of units of asset tokens
    //   buysTokens   is the TokenTrader contract buying tokens?
    //   sellsTokens  is the TokenTrader contract selling tokens?
    //
    function verify(address tradeContract) constant returns (
        bool    valid,
        address owner,
        address asset,
        uint256 buyPrice,
        uint256 sellPrice,
        uint256 units,
        bool    buysTokens,
        bool    sellsTokens
    ) {
        valid = _verify[tradeContract];
        if (valid) {
            TokenTrader t = TokenTrader(tradeContract);
            owner         = t.owner();
            asset         = t.asset();
            buyPrice      = t.buyPrice();
            sellPrice     = t.sellPrice();
            units         = t.units();
            buysTokens    = t.buysTokens();
            sellsTokens   = t.sellsTokens();
        }
    }

    // Maker can call this method to create a new TokenTrader contract
    // with the maker being the owner of this new contract
    //
    // Parameters:
    //   asset        is the ERC20 asset address
    //   buyPrice     is the buy price in ethers per `units` of asset tokens
    //   sellPrice    is the sell price in ethers per `units` of asset tokens
    //   units        is the number of units of asset tokens
    //   buysTokens   is the TokenTrader contract buying tokens?
    //   sellsTokens  is the TokenTrader contract selling tokens?
    //
    // For example, listing a TokenTrader contract on the REP Augur token where
    // the contract will buy REP tokens at a rate of 39000/100000 = 0.39 ETH
    // per REP token and sell REP tokens at a rate of 41000/100000 = 0.41 ETH
    // per REP token:
    //   asset        0x48c80f1f4d53d5951e5d5438b54cba84f29f32a5
    //   buyPrice     39000
    //   sellPrice    41000
    //   units        100000
    //   buysTokens   true
    //   sellsTokens  true
    //
    // The TradeListing() event is logged with the following parameters
    //   ownerAddress        is the Maker&#39;s address
    //   tokenTraderAddress  is the address of the newly created TokenTrader contract
    //   asset               is the ERC20 asset address
    //   buyPrice            is the buy price in ethers per `units` of asset tokens
    //   sellPrice           is the sell price in ethers per `units` of asset tokens
    //   unit                is the number of units of asset tokens
    //   buysTokens          is the TokenTrader contract buying tokens?
    //   sellsTokens         is the TokenTrader contract selling tokens?
    //
    function createTradeContract(
        address asset,
        uint256 buyPrice,
        uint256 sellPrice,
        uint256 units,
        bool    buysTokens,
        bool    sellsTokens
    ) returns (address trader) {
        // Cannot have invalid asset
        if (asset == 0x0) throw;
        // Check for ERC20 allowance function
        // This will throw an error if the allowance function
        // is undefined to prevent GNTs from being used
        // with this factory
        uint256 allowance = ERC20(asset).allowance(msg.sender, this);
        // Cannot set zero or negative price
        if (buyPrice <= 0 || sellPrice <= 0) throw;
        // Must make profit on spread
        if (buyPrice >= sellPrice) throw;
        // Cannot buy or sell zero or negative units
        if (units <= 0) throw;

        trader = new TokenTrader(
            asset,
            buyPrice,
            sellPrice,
            units,
            buysTokens,
            sellsTokens);
        // Record that this factory created the trader
        _verify[trader] = true;
        // Set the owner to whoever called the function
        TokenTrader(trader).transferOwnership(msg.sender);
        TradeListing(msg.sender, trader, asset, buyPrice, sellPrice, units, buysTokens, sellsTokens);
    }

    // Factory owner can withdraw any ERC20 asset tokens from this contract
    //
    // This method is included in the case where this contract receives
    // the wrong tokens
    //
    // The OwnerWithdrewERC20Token() event is logged with the following
    // parameter:
    //   tokenAddress  is the address of the tokens withdrawn by the maker
    //   tokens        is the number of tokens withdrawn by the maker
    //
    function ownerWithdrawERC20Token(address tokenAddress, uint256 tokens) onlyOwner returns (bool ok) {
        OwnerWithdrewERC20Token(tokenAddress, tokens);
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // Prevents accidental sending of ether to the factory
    function () {
        throw;
    }
}

contract FixedSupplyToken is ERC20 {
    string public name;
    string public symbol;
    uint256 _totalSupply;
    uint8 public decimals;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Constructor
    function FixedSupplyToken(
      string _name,
      string _symbol,
      uint256 _supply,
      uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        _totalSupply = _supply;
        decimals = _decimals;
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract TokenToken is FixedSupplyToken{
  TokenTrader[] public tokenExchanges;
  uint256[] public tokenRatios; // Measured in per 1e18, e.g.g 5e17 = 50%
                                // TokenRatios MUST ADD TO 1 (1e18)
  uint256 tokensBought = 0;

  address public owner;
  event OwnershipTransferred(address indexed _from, address indexed _to);

  /* This generates a public event on the blockchain that will notify clients */
  //event Transfer(address indexed from, address indexed to, uint256 value);

  /* Initializes contract with initial supply tokens to the creator of the contract */

  function TokenToken(
    string _name,
    string _symbol,
    uint256 _supply,
    uint8 _decimals,
    TokenTrader[] initialTokenExchanges,
    uint256[] initialTokenRatios
    ) FixedSupplyToken(
      _name,
      _symbol,
      _supply,
      _decimals
    ) {
    tokenExchanges = initialTokenExchanges;
    tokenRatios = initialTokenRatios;
    owner = msg.sender;
  }

  modifier onlyOwner {
      if (msg.sender != owner) throw;
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
  }

  function setPurchaseRatios (
    TokenTrader[] newTokenExchanges,
    uint256[] newTokenRatios
  ) onlyOwner returns (bool success) {
      // Should have a lot of assertions
      // TODO: Assert newTokenRatios.length == tokenRatios.length
      // TODO: Assert newTokenRatios add to 1
      tokenExchanges = newTokenExchanges;
      tokenRatios = newTokenRatios;
      return true;
  }

  function buyPrice() returns (uint totalPrice) {
    totalPrice = 0;
    for (uint i = 0; i < tokenExchanges.length; ++i) {
      totalPrice += tokenExchanges[i].buyPrice() * tokenRatios[i] / 1e18;
    }
    return totalPrice;
  }

  function sellPrice() returns (uint totalPrice) {
    totalPrice = 0;
    for (uint i = 0; i < tokenExchanges.length; ++i) {
      totalPrice += tokenExchanges[i].sellPrice() * tokenRatios[i] / 1e18;
    }
    return totalPrice;
  }

  function () { // Sending ether to it buys coins automatically
    buy();
  }
  function buy() payable returns (uint amount){        // Buy in ETH

    amount = msg.value / buyPrice();
    for (uint i = 0; i < tokenExchanges.length; ++i) {
      TokenTrader tokenExchange = tokenExchanges[i];
      tokenExchange.transfer(msg.value * tokenRatios[i] / 1e18);
    }
    tokensBought += amount;
    balances[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
    balances[this] -= amount;                         // subtracts amount from seller&#39;s balance
    Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    return amount;                                     // ends function and returns
  }

  function sell(uint amount) returns (uint revenue){   // Sell in tokens
    if (balances[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
    balances[this] += amount;                         // adds the amount to owner&#39;s balance
    balances[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance

    uint256 subTokensToSell = 0;
    revenue = 0;
    for (uint i = 0; i < tokenExchanges.length; ++i) { // Unsafe code: what if the loop errors halfway?
      TokenTrader tokenExchange = tokenExchanges[i];
      subTokensToSell = ERC20(tokenExchange.asset()).balanceOf(this)*amount/tokensBought;

      revenue += subTokensToSell * tokenExchange.sellPrice();
      ERC20(tokenExchange.asset()).approve(address(tokenExchange), subTokensToSell); // Approve sale
      tokenExchange.takerSellAsset(subTokensToSell); // Make Sale
    }

    tokensBought -= amount;
    msg.sender.transfer(revenue);
    Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
    return revenue;                                // ends function and returns
  }

  function breakdown(uint amount) {   // Breakdown in tokens
    if (balances[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
    balances[this] += amount;                         // adds the amount to owner&#39;s balance
    balances[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance

    uint256 subTokensToSell = 0;
    for (uint i = 0; i < tokenExchanges.length; ++i) { // Unsafe code: what if the loop errors halfway?
      TokenTrader tokenExchange = tokenExchanges[i];
      subTokensToSell = ERC20(tokenExchange.asset()).balanceOf(this)*amount/tokensBought;
      ERC20(tokenExchange.asset()).transfer(msg.sender, subTokensToSell);
    }

    tokensBought -= amount;
    Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
  }

  function rebalance(TokenTrader fromExchange, TokenTrader toExchange, uint256 fromPercent) onlyOwner {
    uint256 subTokensToSell = ERC20(fromExchange.asset()).balanceOf(this) * fromPercent / 1e18;

    uint256 revenue = subTokensToSell * fromExchange.sellPrice();
    ERC20(fromExchange.asset()).approve(address(fromExchange), subTokensToSell); // Approve sale
    fromExchange.takerSellAsset(subTokensToSell); // Make sale

    toExchange.transfer(revenue); // Make purchase with new contract.
  }

  function kill() { if (msg.sender == owner) selfdestruct(owner); }
}