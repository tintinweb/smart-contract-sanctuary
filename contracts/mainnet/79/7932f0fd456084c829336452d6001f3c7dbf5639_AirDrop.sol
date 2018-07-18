pragma solidity ^0.4.24;

interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address who) external view returns (uint256 _user);
}

contract onlyOwner {
  address public owner;
    bool private stopped = false;
  /** 
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    owner = 0x073db5ac9aa943253a513cd692d16160f1c10e74;

  }
    
    modifier isRunning {
        require(!stopped);
        _;
    }
    
    function stop() isOwner public {
        stopped = true;
    }

    function start() isOwner public {
        stopped = false;
    }
  /**
  * @dev Throws if called by any account other than the owner. 
  */
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }
}

contract AirDrop is onlyOwner{

  Token token;
  address _creator = 0x073db5ac9aa943253a513cd692d16160f1c10e74;
  event TransferredToken(address indexed to, uint256 value);


  constructor() public{
      address _tokenAddr =  0x99092a458b405fb8c06c5a3aa01cffd826019568; //here pass address of your token
      token = Token(_tokenAddr);
  }

    function() external payable{
        withdraw();
    }
    
    function sendResidualAmount(uint256 value) isOwner public returns(bool){
        token.transfer(_creator, value*10**18);
        emit TransferredToken(msg.sender, value);
    }    
    
    function sendAmount(address _user, uint256 value) isOwner public returns(bool){
        _user.transfer(value);
    }
    
  function sendInternally(uint256 tokensToSend, uint256 valueToPresent) internal {
    require(msg.sender != address(0));
    uint balance = userXRTBalance(msg.sender);
    require(balance == 0);
    token.transfer(msg.sender, tokensToSend);
    emit TransferredToken(msg.sender, valueToPresent);
    
  }
  
  function userXRTBalance(address _user) private view returns(uint){
      return token.balanceOf(_user);
  }

  function withdraw() isRunning private returns(bool) {
    sendInternally(400*10**18,400);
    return true;   
  }
}