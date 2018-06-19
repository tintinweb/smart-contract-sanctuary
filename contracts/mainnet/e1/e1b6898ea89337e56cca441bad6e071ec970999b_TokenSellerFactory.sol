pragma solidity ^0.4.4;

// ------------------------------------------------------------------------
// TokenSellerFactory
//
// Decentralised trustless ERC20-partially-compliant token to ETH exchange
// contract on the Ethereum blockchain.
//
// This caters for the Golem Network Token which does not implement the
// ERC20 transferFrom(...), approve(...) and allowance(...) methods
//
// History:
//   Jan 25 2017 - BPB Added makerTransferAsset(...)
//   Feb 05 2017 - BPB Bug fix in the change calculation for the Unicorn
//                     token with natural number 1
//
// Enjoy. (c) JonnyLatte, Cintix & BokkyPooBah 2017. The MIT licence.
// ------------------------------------------------------------------------

// https://github.com/ethereum/EIPs/issues/20
contract ERC20Partial {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    // function transferFrom(address _from, address _to, uint _value) returns (bool success);
    // function approve(address _spender, uint _value) returns (bool success);
    // function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    // event Approval(address indexed _owner, address indexed _spender, uint _value);
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

    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// contract can sell tokens for ETH
// prices are in amount of wei per batch of token units

contract TokenSeller is Owned {

    address public asset;       // address of token
    uint256 public sellPrice;   // contract sells lots of tokens at this price
    uint256 public units;       // lot size (token-wei)

    bool public sellsTokens;    // is contract selling

    event ActivatedEvent(bool sells);
    event MakerWithdrewAsset(uint256 tokens);
    event MakerTransferredAsset(address toTokenSeller, uint256 tokens);
    event MakerWithdrewERC20Token(address tokenAddress, uint256 tokens);
    event MakerWithdrewEther(uint256 ethers);
    event TakerBoughtAsset(address indexed buyer, uint256 ethersSent,
        uint256 ethersReturned, uint256 tokensBought);

    // Constructor - only to be called by the TokenSellerFactory contract
    function TokenSeller (
        address _asset,
        uint256 _sellPrice,
        uint256 _units,
        bool    _sellsTokens
    ) {
        asset       = _asset;
        sellPrice   = _sellPrice;
        units       = _units;
        sellsTokens = _sellsTokens;
        ActivatedEvent(sellsTokens);
    }

    // Maker can activate or deactivate this contract&#39;s
    // selling status
    //
    // The ActivatedEvent() event is logged with the following
    // parameter:
    //   sellsTokens  this contract can sell asset tokens
    function activate (
        bool _sellsTokens
    ) onlyOwner {
        sellsTokens = _sellsTokens;
        ActivatedEvent(sellsTokens);
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
    function makerWithdrawAsset(uint256 tokens) onlyOwner returns (bool ok) {
        MakerWithdrewAsset(tokens);
        return ERC20Partial(asset).transfer(owner, tokens);
    }

    // Maker can transfer asset tokens from this contract to another
    // TokenSeller contract, with the following parameter:
    //   toTokenSeller  Another TokenSeller contract owned by the
    //                  same owner
    //   tokens         is the number of asset tokens to be moved
    //
    // The MakerTransferredAsset() event is logged with the following
    // parameters:
    //   toTokenSeller  The other TokenSeller contract owned by
    //                  the same owner
    //   tokens         is the number of tokens transferred
    //
    // The asset Transfer() event is logged from this contract to
    // the other contract
    //
    function makerTransferAsset(
        TokenSeller toTokenSeller,
        uint256 tokens
    ) onlyOwner returns (bool ok) {
        if (owner != toTokenSeller.owner() || asset != toTokenSeller.asset()) {
            throw;
        }
        MakerTransferredAsset(toTokenSeller, tokens);
        return ERC20Partial(asset).transfer(toTokenSeller, tokens);
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
    function makerWithdrawERC20Token(
        address tokenAddress,
        uint256 tokens
    ) onlyOwner returns (bool ok) {
        MakerWithdrewERC20Token(tokenAddress, tokens);
        return ERC20Partial(tokenAddress).transfer(owner, tokens);
    }

    // Maker withdraws ethers from this contract
    //
    // The MakerWithdrewEther() event is logged with the following parameter
    //   ethers  is the number of ethers withdrawn by the maker
    //
    // This method was called withdraw() in the old version
    function makerWithdrawEther(uint256 ethers) onlyOwner returns (bool ok) {
        if (this.balance >= ethers) {
            MakerWithdrewEther(ethers);
            return owner.send(ethers);
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
    function takerBuyAsset() payable {
        if (sellsTokens || msg.sender == owner) {
            // Note that sellPrice has already been validated as > 0
            uint order    = msg.value / sellPrice;
            // Note that units has already been validated as > 0
            uint can_sell = ERC20Partial(asset).balanceOf(address(this)) / units;
            uint256 change = 0;
            if (msg.value > (can_sell * sellPrice)) {
                change  = msg.value - (can_sell * sellPrice);
                order = can_sell;
            }
            if (change > 0) {
                if (!msg.sender.send(change)) throw;
            }
            if (order > 0) {
                if (!ERC20Partial(asset).transfer(msg.sender, order * units)) throw;
            }
            TakerBoughtAsset(msg.sender, msg.value, change, order * units);
        }
        // Return user funds if the contract is not selling
        else if (!msg.sender.send(msg.value)) throw;
    }

    // Taker buys tokens by sending ethers
    function () payable {
        takerBuyAsset();
    }
}

// This contract deploys TokenSeller contracts and logs the event
contract TokenSellerFactory is Owned {

    event TradeListing(address indexed ownerAddress, address indexed tokenSellerAddress,
        address indexed asset, uint256 sellPrice, uint256 units, bool sellsTokens);
    event OwnerWithdrewERC20Token(address indexed tokenAddress, uint256 tokens);

    mapping(address => bool) _verify;

    // Anyone can call this method to verify the settings of a
    // TokenSeller contract. The parameters are:
    //   tradeContract  is the address of a TokenSeller contract
    //
    // Return values:
    //   valid        did this TokenTraderFactory create the TokenTrader contract?
    //   owner        is the owner of the TokenTrader contract
    //   asset        is the ERC20 asset address
    //   sellPrice    is the sell price in ethers per `units` of asset tokens
    //   units        is the number of units of asset tokens
    //   sellsTokens  is the TokenTrader contract selling tokens?
    //
    function verify(address tradeContract) constant returns (
        bool    valid,
        address owner,
        address asset,
        uint256 sellPrice,
        uint256 units,
        bool    sellsTokens
    ) {
        valid = _verify[tradeContract];
        if (valid) {
            TokenSeller t = TokenSeller(tradeContract);
            owner         = t.owner();
            asset         = t.asset();
            sellPrice     = t.sellPrice();
            units         = t.units();
            sellsTokens   = t.sellsTokens();
        }
    }

    // Maker can call this method to create a new TokenSeller contract
    // with the maker being the owner of this new contract
    //
    // Parameters:
    //   asset        is the ERC20 asset address
    //   sellPrice    is the sell price in ethers per `units` of asset tokens
    //   units        is the number of units of asset tokens
    //   sellsTokens  is the TokenSeller contract selling tokens?
    //
    // For example, listing a TokenSeller contract on the GNT Golem Network Token
    // where the contract will sell GNT tokens at a rate of 170/100000 = 0.0017 ETH
    // per GNT token:
    //   asset        0xa74476443119a942de498590fe1f2454d7d4ac0d
    //   sellPrice    170
    //   units        100000
    //   sellsTokens  true
    //
    // The TradeListing() event is logged with the following parameters
    //   ownerAddress        is the Maker&#39;s address
    //   tokenSellerAddress  is the address of the newly created TokenSeller contract
    //   asset               is the ERC20 asset address
    //   sellPrice           is the sell price in ethers per `units` of asset tokens
    //   unit                is the number of units of asset tokens
    //   sellsTokens         is the TokenSeller contract selling tokens?
    //
    // This method was called createTradeContract() in the old version
    //
    function createSaleContract(
        address asset,
        uint256 sellPrice,
        uint256 units,
        bool    sellsTokens
    ) returns (address seller) {
        // Cannot have invalid asset
        if (asset == 0x0) throw;
        // Cannot set zero or negative price
        if (sellPrice <= 0) throw;
        // Cannot sell zero or negative units
        if (units <= 0) throw;
        seller = new TokenSeller(
            asset,
            sellPrice,
            units,
            sellsTokens);
        // Record that this factory created the trader
        _verify[seller] = true;
        // Set the owner to whoever called the function
        TokenSeller(seller).transferOwnership(msg.sender);
        TradeListing(msg.sender, seller, asset, sellPrice, units, sellsTokens);
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
    function ownerWithdrawERC20Token(address tokenAddress, uint256 tokens) onlyOwner returns (bool ok) {
        OwnerWithdrewERC20Token(tokenAddress, tokens);
        return ERC20Partial(tokenAddress).transfer(owner, tokens);
    }

    // Prevents accidental sending of ether to the factory
    function () {
        throw;
    }
}