pragma solidity ^0.4.11;

contract CardboardUnicorns {
  address public owner;
  function mint(address who, uint value);
  function changeOwner(address _newOwner);
  function withdraw();
  function withdrawForeignTokens(address _tokenContract);
}
contract RealUnicornCongress {
  uint public priceOfAUnicornInFinney;
}
contract ForeignToken {
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
}

contract CardboardUnicornAssembler {
  address public cardboardUnicornTokenAddress;
  address public realUnicornAddress = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;
  address public owner = msg.sender;
  uint public pricePerUnicorn = 1 finney;
  uint public lastPriceSetDate = 0;
  
  event PriceUpdate(uint newPrice, address updater);

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  /**
   * Change ownership of the assembler
   */
  function changeOwner(address _newOwner) onlyOwner {
    owner = _newOwner;
  }
  function changeTokenOwner(address _newOwner) onlyOwner {
    CardboardUnicorns cu = CardboardUnicorns(cardboardUnicornTokenAddress);
    cu.changeOwner(_newOwner);
  }
  
  /**
   * Change the CardboardUnicorns token contract managed by this contract
   */
  function changeCardboardUnicornTokenAddress(address _newTokenAddress) onlyOwner {
    CardboardUnicorns cu = CardboardUnicorns(_newTokenAddress);
    require(cu.owner() == address(this)); // We must be the owner of the token
    cardboardUnicornTokenAddress = _newTokenAddress;
  }
  
  /**
   * Change the real unicorn contract location.
   * This contract is used as a price reference; should the Ethereum Foundation
   * re-deploy their contract, this should be called to update the reference.
   */
  function changeRealUnicornAddress(address _newUnicornAddress) onlyOwner {
    realUnicornAddress = _newUnicornAddress;
  }
  
  function withdraw(bool _includeToken) onlyOwner {
    if (_includeToken) {
      // First have the token contract send all its funds to its owner (which is us)
      CardboardUnicorns cu = CardboardUnicorns(cardboardUnicornTokenAddress);
      cu.withdraw();
    }

    // Then send that whole total to our owner
    owner.transfer(this.balance);
  }
  function withdrawForeignTokens(address _tokenContract, bool _includeToken) onlyOwner {
    ForeignToken token = ForeignToken(_tokenContract);

    if (_includeToken) {
      // First have the token contract send its tokens to its owner (which is us)
      CardboardUnicorns cu = CardboardUnicorns(cardboardUnicornTokenAddress);
      cu.withdrawForeignTokens(_tokenContract);
    }

    // Then send that whole total to our owner
    uint256 amount = token.balanceOf(address(this));
    token.transfer(owner, amount);
  }

  /**
   * Update the price of a CardboardUnicorn to be 1/1000 a real Unicorn&#39;s price
   */
  function updatePriceFromRealUnicornPrice() {
    require(block.timestamp > lastPriceSetDate + 7 days); // If owner set the price, cannot sync right after
    RealUnicornCongress congress = RealUnicornCongress(realUnicornAddress);
    pricePerUnicorn = (congress.priceOfAUnicornInFinney() * 1 finney) / 1000;
    PriceUpdate(pricePerUnicorn, msg.sender);
  }
  
  /**
   * Set a specific price for a CardboardUnicorn
   */
  function setPrice(uint _newPrice) onlyOwner {
    pricePerUnicorn = _newPrice;
    lastPriceSetDate = block.timestamp;
    PriceUpdate(pricePerUnicorn, msg.sender);
  }
  
  /**
   * Strap a horn to a horse!
   */
  function assembleUnicorn() payable {
    if (msg.value >= pricePerUnicorn) {
        CardboardUnicorns cu = CardboardUnicorns(cardboardUnicornTokenAddress);
        cu.mint(msg.sender, msg.value / pricePerUnicorn);
        owner.transfer(msg.value);
    }
  }
  
  function() payable {
      assembleUnicorn();
  }

}