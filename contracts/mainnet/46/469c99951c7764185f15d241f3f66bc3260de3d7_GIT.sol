pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract GIT {
    
    using SafeMath for uint256;
    address public owner;
    address public tokenAddress;
    address public tokenSender;
    uint256 public tokenApproves;

    mapping (address => uint256) balances;

    uint256 public totalExchange = 200000e18;
    uint256 public totalDistributed = 0;
    uint256 public totalRemaining = totalExchange.sub(totalDistributed);

    uint256 constant public unitEthWei = 1e18;
    uint256 public unitsOneEthCanBuy = 250e18;
    uint256 public unitsUserCanBuyLimitEth = 4e18;
    uint256 public unitsUserCanBuyLimit = (unitsUserCanBuyLimitEth.div(unitEthWei)).mul(unitsOneEthCanBuy);

    event ExchangeFinished();
    event ExchangeStarted();
    
    
    event LOG_receiveApproval(address _sender,uint256 _tokenValue,address _tokenAddress,bytes _extraData);
    event LOG_callTokenTransferFrom(address tokenSender,address _to,uint256 _value);
    event LOG_exchange(address _to, uint256 amount);
    
    bool public exchangeFinished = false;
    
    modifier canExchange() {
        require(!exchangeFinished);
        _;
    }
    
    modifier canNotExchange() {
        require(exchangeFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function GIT () public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function changeTokenAddress(address newTokenAddress) onlyOwner public {
        if (newTokenAddress != address(0)) {
            tokenAddress = newTokenAddress;
        }
    }
    
    function changeTokenSender(address newTokenSender) onlyOwner public {
        if (newTokenSender != address(0)) {
            tokenSender = newTokenSender;
        }
    }
    
    function changeUnitsOneEthCanBuy(uint256 newUnitsOneEthCanBuy) onlyOwner public {
        unitsOneEthCanBuy = newUnitsOneEthCanBuy;
    }
    
    function changeUnitsUserCanBuyLimitEth(uint256 newUnitsUserCanBuyLimitEth) onlyOwner public {
        unitsUserCanBuyLimitEth = newUnitsUserCanBuyLimitEth;
    }
    
    function changeTotalExchange(uint256 newTotalExchange) onlyOwner public {
        totalExchange = newTotalExchange;
    }
    
    function changeTokenApproves(uint256 newTokenApproves) onlyOwner public {
        tokenApproves = newTokenApproves;
    }
    
    function changeTotalDistributed(uint256 newTotalDistributed) onlyOwner public {
        totalDistributed = newTotalDistributed;
    }
    
    function changeTotalRemaining(uint256 newTotalRemaining) onlyOwner public {
        totalRemaining = newTotalRemaining;
    }
    
    function changeUnitsUserCanBuyLimit(uint256 newUnitsUserCanBuyLimit) onlyOwner public {
        unitsUserCanBuyLimit = newUnitsUserCanBuyLimit;
    }
    
    function finishExchange() onlyOwner canExchange public returns (bool) {
        exchangeFinished = true;
        ExchangeFinished();
        return true;
    }
    
    function startExchange() onlyOwner canNotExchange public returns (bool) {
        exchangeFinished = false;
        ExchangeStarted();
        return true;
    }
    
    function () external payable {
            exchangeTokens();
     }
    
    function exchangeTokens() payable canExchange public {
        
        require(exchange());

        if (totalDistributed >= totalExchange) {
            exchangeFinished = true;
        }
        
    }
    
    function getTokenBalance(address _tokenAddress, address _who) constant public returns (uint256){
        ForeignToken t = ForeignToken(_tokenAddress);
        uint bal = t.balanceOf(_who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        uint256 etherBalance = this.balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
    function receiveApproval(address _sender,uint256 _tokenValue,address _tokenAddress,bytes _extraData) public returns (bool){
        require(tokenAddress == _tokenAddress);
        require(tokenSender == _sender);
        require(totalExchange <= _tokenValue);
        
        tokenApproves = _tokenValue;
        LOG_receiveApproval(_sender, _tokenValue ,_tokenAddress ,_extraData);
        return true;
    }
    
    function callTokenTransferFrom(address _to,uint256 _value) private returns (bool){
        
        require(tokenSender != address(0));
        require(tokenAddress.call(bytes4(bytes32(keccak256("transferFrom(address,address,uint256)"))), tokenSender, _to, _value));
        
        LOG_callTokenTransferFrom(tokenSender, _to, _value);
        return true;
    }
    
    function exchange() payable canExchange public returns (bool) {
        
        uint256 amount = 0;
        if(msg.value == 0){
            return false;
        }
        
        address _to = msg.sender;
        
        amount = msg.value.mul(unitsOneEthCanBuy.div(unitEthWei));
        require(amount.add(balances[msg.sender]) <= unitsUserCanBuyLimit);
        
        totalDistributed = totalDistributed.add(amount);
        totalRemaining = totalRemaining.sub(amount);
        
        require(callTokenTransferFrom(_to, amount));
        
        balances[msg.sender] = amount.add(balances[msg.sender]);
        
        if (totalDistributed >= totalExchange) {
            exchangeFinished = true;
        }
        
        LOG_exchange(_to, amount);
        return true;
    }

}