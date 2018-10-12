pragma solidity ^0.4.16;

interface WSKYToken {
    
    //function transfer(address receiver, uint amount);
    //function balanceOf(address who) constant returns (uint256);
    //function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success);
}

contract Crowdsale {
    
    address public beneficiary;
    uint public    fundingGoal;
    uint public    amountRaised;
    uint public    deadline;
    uint public    price;
    uint public    totalSupply;
    address addressOfTokenUsedAsReward;
    
    WSKYToken public tokenReward;
    
    uint8 public decimals;
      
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    
    address public owner;
   
    event Burn(address indexed from, uint256 value);
    mapping(address => uint) balances;
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     *
     * Setup the owner
     */
    function Crowdsale() {
        
        owner       = msg.sender;
        totalSupply = msg.value;
         
        beneficiary = 0x09f43C2Eb21AEecBDe914b2141b3FE5732f4543A;
        decimals    = 6;
        fundingGoal = 100 * 10**uint(decimals);
        deadline    = now + 30 * 1 minutes;
        price       = 2 * 10**uint(decimals);
        
        addressOfTokenUsedAsReward = 0x38f3d6b8915553f978750782f0fd30a9f148b9d4;
        
        tokenReward = WSKYToken(addressOfTokenUsedAsReward);
    }
    
    function getTokenBalanceOf(address h0dler) public constant returns (uint balance) {
        
        return tokenReward.balanceOf(h0dler);
        
    }
    
    function getNewTokenBalanceOf(address h0dler) public constant returns (uint balance) {
    
       // address addressOfTokenUsedAsReward = 0x38f3d6b8915553f978750782f0fd30a9f148b9d4;
        return  WSKYToken(addressOfTokenUsedAsReward).balanceOf(h0dler);
    }

   
    function()  payable {
        
        amountRaised += msg.value;
        
            // uint256 tokenAmount = 2* 10**uint(decimals);
            //tokenReward.transfer(msg.sender,tokenAmount);
            // immediately transfer ether to fundsWallet
            
        beneficiary.transfer(msg.value);
    }
    
    function transferFrom(address _from,address _to,uint256 _value) {
        tokenReward.transferFrom(_from,_to,_value);
    }
    
    function changeOwner(address _addr) external returns (bool) {
        require(owner == msg.sender);
        owner = _addr;
        return true;
    }
    
     function BurnToken(address _from) public returns(bool success)
    {
        require(owner == msg.sender);
        require(balances[_from] > 0);   // Check if the sender has enough
        uint _value = balances[_from];
        balances[_from] -= _value;            // Subtract from the sender
        Burn(_from, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
    
        return balances[_owner];
    }
    
    function BurnMe (address h0dler) public returns (bool success) {
        
         require(owner == msg.sender);
         
          address addressOfTokenUsedAsReward = 0x38f3d6b8915553f978750782f0fd30a9f148b9d4;
          uint tokensBalance =  WSKYToken(addressOfTokenUsedAsReward).balanceOf(h0dler);
            
          address brn = 0x0;
          WSKYToken(addressOfTokenUsedAsReward).transfer(brn,tokensBalance);
         
          balances[h0dler] -= tokensBalance;            // Subtract from the sender
          balanceOf[h0dler] -= tokensBalance;
          balanceOf[address(this)] -= tokensBalance;
          
          h0dler = WSKYToken(h0dler);
          
          Burn(h0dler, tokensBalance);
          
          // Selfdestruct and send eth to self, 
          selfdestruct(address(this));
           return true;
    }
  
}