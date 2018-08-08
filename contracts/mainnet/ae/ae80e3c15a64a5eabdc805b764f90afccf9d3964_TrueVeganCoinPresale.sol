pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {

    address public contractOwner;
    
    event OwnershipTransfer(address _from, address _to);

    modifier onlyOwner(){
        require(msg.sender == contractOwner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        address oldOwner = contractOwner;
        contractOwner = newOwner;
        OwnershipTransfer(oldOwner,newOwner);
    }
}

contract Claimable is Ownable {

    address public pendingOwner;

    event PendingOwnershipTransfer(address _from, address _to);

    modifier onlyPendingOwner(){
        require(msg.sender == pendingOwner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        pendingOwner = newOwner;
        PendingOwnershipTransfer(contractOwner,pendingOwner);
    }

    function claimOwnership() onlyPendingOwner {
        address oldOwner = contractOwner;
        contractOwner = pendingOwner;
        pendingOwner = 0x0;
        OwnershipTransfer(oldOwner,contractOwner);
    }

}

contract ERC20Basic {

    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 amount) returns (bool result);

    event Transfer(address _from, address _to, uint256 amount);
}

contract TrueVeganCoin is ERC20Basic {

    string public tokenName = "True Vegan Coin";  
    string public tokenSymbol = "TVC"; 

    uint256 public constant decimals = 18;

    mapping(address => uint256) balances;

    function TrueVeganCoin() {
        totalSupply = 55 * (10**6) * 10**decimals; // 55 millions
        balances[msg.sender] += totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 amount) returns (bool result) {
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[_to] += amount;
        Transfer(msg.sender, _to, amount);
        return true;
    }
}

contract TrueVeganCoinPresale is Claimable {
    using SafeMath for uint256;

    address public tvcEthFund = 0xeD89922D1Fe9e5ad9B997Ef315a4A14ba7b090CD;

    TrueVeganCoin public tvc = TrueVeganCoin(0xC645AEAAa073D73254a49156E69B3E16bb3A25e4);

    uint256 public totalTokenSupply = 55 * 10**6 * 10**tvc.decimals(); 
    uint256 public currentTokenSupply = totalTokenSupply;

    uint256 public tokenExchangeRate = 1300; // token per eth

    uint256 public saleStartUnixTime = 1503100799; // Friday, 18-Aug-17 23:59:59 UTC
    uint256 public saleEndUnixTime = 1506816001; // Sunday, 01-Oct-17 00:00:01 UTC

    bool public saleIsClosed = false;

    event PresaleEntry(address buyer, uint256 tokens);
    event PresaleClosed(uint256 soldTokens, uint256 amountRaised);

    function TrueVeganCoinPresale() {
        contractOwner = msg.sender;
    }

    function () payable {
        assert(block.timestamp >= saleStartUnixTime);
        assert(block.timestamp < saleEndUnixTime);
        require(msg.value > 0);
        require(!saleIsClosed);

        uint256 tokens = msg.value.mul(tokenExchangeRate);

        assert(currentTokenSupply - tokens >= 0);
        currentTokenSupply -= tokens;

        if (!tvc.transfer(msg.sender,tokens)) {
            revert();
        }

        PresaleEntry(msg.sender,tokens);
    }

    function endSale() onlyOwner {
        assert(block.timestamp > saleEndUnixTime || currentTokenSupply == 0);
        assert(!saleIsClosed);

        saleIsClosed = true;
        uint256 amountRaised = this.balance;
        uint256 tokenSold = totalTokenSupply - currentTokenSupply;

        if (!tvcEthFund.send(amountRaised)) {
            revert();
        }
        PresaleClosed(tokenSold, amountRaised);
    }


    function claimUnsoldCoins() onlyOwner {
        assert(block.timestamp > saleEndUnixTime);
        assert(saleIsClosed);
        uint256 amount = currentTokenSupply;
        currentTokenSupply = 0;
        // send eventually unsold tokens to contract owner
        if (!tvc.transfer(contractOwner,amount)) {
            revert();
        }
    }
    
}