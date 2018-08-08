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

contract JECKAirdrop {
    
    using SafeMath for uint256;
    address public owner;
    address public tokenAddress;
    address public tokenSender;
    uint256 public tokenApproves;


    mapping (address => bool) public blacklist;
    
    uint256 public totalAirdrop = 4000e18;
    uint256 public unitUserBalanceLimit = uint256(1e18).div(10);
    uint256 public totalDistributed = 0;
    uint256 public totalRemaining = totalAirdrop.sub(totalDistributed);
    uint256 public value = uint256(5e18).div(10);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event DistrStarted();
    
    event LOG_receiveApproval(address _sender,uint256 _tokenValue,address _tokenAddress,bytes _extraData);
    event LOG_callTokenTransferFrom(address tokenSender,address _to,uint256 _value);
    
    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier canNotDistr() {
        require(distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    function JECKAirdrop () public {
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
    
    function changeValue(uint256 newValue) onlyOwner public {
        value = newValue;
    }
    
    function changeTotalAirdrop(uint256 newtotalAirdrop) onlyOwner public {
        totalAirdrop = newtotalAirdrop;
    }
    
    function changeUnitUserBalanceLimit(uint256 newUnitUserBalanceLimit) onlyOwner public {
        unitUserBalanceLimit = newUnitUserBalanceLimit;
    }
    
    function enableWhitelist(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = false;
        }
    }

    function disableWhitelist(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = true;
        }
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        DistrFinished();
        return true;
    }
    
    function startDistribution() onlyOwner canNotDistr public returns (bool) {
        distributionFinished = true;
        DistrStarted();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        
        require(callTokenTransferFrom(_to, _amount));
        
        if (totalDistributed >= totalAirdrop) {
            distributionFinished = true;
        }
        
        Distr(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
    
    function airdrop(address[] addresses) onlyOwner canDistr public {
        
        require(addresses.length <= 255);
        require(value <= totalRemaining);
        
        for (uint i = 0; i < addresses.length; i++) {
            require(value <= totalRemaining);
            distr(addresses[i], value);
        }
	
        if (totalDistributed >= totalAirdrop) {
            distributionFinished = true;
        }
    }
    
    function distribution(address[] addresses, uint256 amount) onlyOwner canDistr public {
        
        require(addresses.length <= 255);
        require(amount <= totalRemaining);
        
        for (uint i = 0; i < addresses.length; i++) {
            require(amount <= totalRemaining);
            distr(addresses[i], amount);
        }
	
        if (totalDistributed >= totalAirdrop) {
            distributionFinished = true;
        }
    }
    
    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner canDistr public {

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amounts[i] <= totalRemaining);
            distr(addresses[i], amounts[i]);
            
            if (totalDistributed >= totalAirdrop) {
                distributionFinished = true;
            }
        }
    }
    
    function () external payable {
            getTokens();
     }
    
    function getTokens() payable canDistr onlyWhitelist public {
        
        if (value > totalRemaining) {
            value = totalRemaining;
        }
        
        require(value <= totalRemaining);
        
        require(msg.sender.balance.add(msg.value) >= unitUserBalanceLimit);
        
        address investor = msg.sender;
        uint256 toGive = value;
        
        distr(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
        }

        if (totalDistributed >= totalAirdrop) {
            distributionFinished = true;
        }
    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function getTokenBalance(address _tokenAddress, address _who) constant public returns (uint){
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
    
    function receiveApproval(address _sender,uint256 _tokenValue,address _tokenAddress,bytes _extraData) payable public returns (bool){
        require(tokenAddress == _tokenAddress);
        require(tokenSender == _sender);
        require(totalAirdrop <= _tokenValue);
        
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

}