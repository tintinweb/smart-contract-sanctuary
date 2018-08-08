pragma solidity 0.4.16;
contract Ownable {
    address public owner;

    function Ownable() { //This call only first time when contract deployed by person
        owner = msg.sender;
    }
    modifier onlyOwner() { //This modifier is for checking owner is calling
        if (owner == msg.sender) {
            _;
        } else {
            revert();
        }

    }

}

contract Mortal is Ownable {
    
    function kill() {
        if (msg.sender == owner)
            selfdestruct(owner);
    }
}

contract Token {
    uint256 public totalSupply;
    uint256 tokensForICO;
    uint256 etherRaised;

    function balanceOf(address _owner) constant returns(uint256 balance);

    function transfer(address _to, uint256 _tokens) public returns(bool resultTransfer);

    function transferFrom(address _from, address _to, uint256 _tokens) public returns(bool resultTransfer);

    function approve(address _spender, uint _value) returns(bool success);

    function allowance(address _owner, address _spender) constant returns(uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}
contract StandardToken is Token,Mortal,Pausable {
    
    function transfer(address _to, uint256 _value) whenNotPaused returns (bool success) {
        require(_to!=0x0);
        require(_value>0);
         if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 totalTokensToTransfer)whenNotPaused returns (bool success) {
        require(_from!=0x0);
        require(_to!=0x0);
        require(totalTokensToTransfer>0);
    
       if (balances[_from] >= totalTokensToTransfer&&allowance(_from,_to)>=totalTokensToTransfer) {
            balances[_to] += totalTokensToTransfer;
            balances[_from] -= totalTokensToTransfer;
            allowed[_from][msg.sender] -= totalTokensToTransfer;
            Transfer(_from, _to, totalTokensToTransfer);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balanceOfUser) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
contract DIGI is StandardToken{
    string public constant name = "DIGI";
    uint8 public constant decimals = 4;
    string public constant symbol = "DIGI";
    uint256 constant priceOfToken=1666666666666666;
    uint256 twoWeeksBonusTime;
    uint256 thirdWeekBonusTime;
    uint256 fourthWeekBonusTime;
    uint256 public deadLine;
    function DIGI(){
       totalSupply=980000000000;  //98 Million
       owner = msg.sender;
       balances[msg.sender] = (980000000000);
       twoWeeksBonusTime=now + 2 * 1 weeks;//set time for first two week relative to deploy time
       thirdWeekBonusTime=twoWeeksBonusTime+1 * 1 weeks;//third week calculate by adding one week by first two week
       fourthWeekBonusTime=thirdWeekBonusTime+1 * 1 weeks;
       deadLine=fourthWeekBonusTime+1 *1 weeks;//deadline is after fourth week just add one week
       etherRaised=0;
    }
    /**
     * @dev directly send ether and transfer token to that account 
     */
    function() payable whenNotPaused{
        require(msg.sender != 0x0);
        require(msg.value >= priceOfToken);//must be atleate single token price
        require(now<deadLine);
        uint bonus=0;
        if(now < twoWeeksBonusTime){
            bonus=40;
        }
        else if(now<thirdWeekBonusTime){
          bonus=20;  
        }
        else if (now <fourthWeekBonusTime){
            bonus = 10;
        }
        uint tokensToTransfer=((msg.value*10000)/priceOfToken);
        uint bonusTokens=(tokensToTransfer * bonus) /100;
        tokensToTransfer=tokensToTransfer+bonusTokens;
       if(balances[owner] <tokensToTransfer) //check etiher owner can have token otherwise reject transaction and ether
       {
           revert();
       }
        allowed[owner][msg.sender] += tokensToTransfer;
        bool transferRes=transferFrom(owner, msg.sender, tokensToTransfer);
        if (!transferRes) {
            revert();
        }
        else{
        etherRaised+=msg.value;
        }
        
    }
    
    /**
   * @dev called by the owner to extend deadline relative to last deadLine Time,
   * to accept ether and transfer tokens
   */
   function extendDeadline(uint daysToExtend) onlyOwner{
       deadLine=deadLine +daysToExtend * 1 days;
   }
   
   /**
    * To transfer all balace to any account by only owner
    * */
    function transferFundToAccount(address _accountByOwner) onlyOwner whenPaused returns(uint256 result){
        require(etherRaised>0);
        _accountByOwner.transfer(etherRaised);
        etherRaised=0;
        return etherRaised;
    }
       /**
    * To transfer all balace to any account by only owner
    * */
    function transferLimitedFundToAccount(address _accountByOwner,uint256 balanceToTransfer) onlyOwner whenPaused {
        require(etherRaised>0);
        require(balanceToTransfer<etherRaised);
        _accountByOwner.transfer(balanceToTransfer);
        etherRaised=etherRaised-balanceToTransfer;
    }
    
}