pragma solidity ^0.4.4;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BoltToken is ERC20{
    
    address owner = msg.sender;
    
    bool public canPurchase = false;
    
    mapping (address => uint) balances;
    mapping (address => uint) roundContributions;
    address[] roundContributionsIndexes;
    mapping (address => mapping (address => uint)) allowed;

    uint public currentSupply = 0;
    uint public totalSupply = 32032000000000000000000000;
    
    uint public round = 0;
    uint public roundFunds = 0;
    uint public roundReward = 200200000000000000000000;
    
    string public name = "BOLT token";
    string public symbol = "BOLT";
    uint8 public decimals = 18;
    
    bool public isToken = true;
    
    string public tokenSaleAgreement = "https://bolt-project.net/tsa.pdf";
    
    uint contributionsDistribStep = 0;
    
    event Contribution(address indexed from, uint value);
    event RoundEnd(uint roundNumber);
    
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint _value) public returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (2 * 32) + 4) { return false; }

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    
    function transferFrom(address _from, address _to, uint _value) public  returns (bool success){
        // mitigates the ERC20 short address attack
        if(msg.data.length < (3 * 32) + 4) { return false; }
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }
    
    function approve(address _spender, uint _value) public  returns (bool success){
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function enablePurchase() public {
        if(msg.sender != owner && currentSupply>=totalSupply){ return; }
        
        canPurchase = true;
    }

    function disablePurchase() public {
        if(msg.sender != owner){ return; }
        
        canPurchase = false;
    }
    
    function changeTsaLink(string _link) public {
        if(msg.sender != owner){ return; }
        
        tokenSaleAgreement = _link;
    }
    
    function changeReward(uint _roundReward) public {
        if(msg.sender != owner){ return; }
        
        roundReward = _roundReward;
    }
    
    function nextRound() public {
        if(msg.sender != owner){ return; }
        uint i = contributionsDistribStep;
        while(i < contributionsDistribStep+10 && i<roundContributionsIndexes.length){
            address contributor = roundContributionsIndexes[i];
            balances[contributor] += roundReward*roundContributions[contributor]/roundFunds;
            roundContributions[contributor] = 0;
            i++;
        }
        
        contributionsDistribStep = i;
        
        if(i==roundContributionsIndexes.length){
            delete roundContributionsIndexes;
            
            emit RoundEnd(round);
            
            roundFunds = 0;
            currentSupply += roundReward;
            round += 1;
            contributionsDistribStep = 0;
        }
    }

    function contribute(bool _acceptConditions) payable public {
        
        if(msg.value == 0){ return; }
        
        if(!canPurchase || !_acceptConditions || msg.value < 10 finney){
            msg.sender.transfer(msg.value);
            return;
        }
        
        owner.transfer(msg.value);
        
        if(roundContributions[msg.sender] == 0){
           roundContributionsIndexes.push(msg.sender); 
        }
        
        roundContributions[msg.sender] += msg.value;
        roundFunds += msg.value;
        
        emit Contribution(msg.sender, msg.value);
    }
}