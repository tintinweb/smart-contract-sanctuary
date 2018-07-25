pragma solidity ^0.4.24;

interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
}

contract onlyOwner {
  address public owner;
  /** 
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    owner = 0x073db5ac9aa943253a513cd692d16160f1c10e74;

  }
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
      address _tokenAddr = 0x2eb009E15BB8f39a34deee39369fe0FD22B6bf0f; //here pass address of your token
      token = Token(_tokenAddr);
  }


    function sendResidualAmount(uint256 value) isOwner public returns(bool){
        token.transfer(_creator, value*10**18);
        emit TransferredToken(msg.sender, value);
    }    
    
    function sendAmount(address[] _user, uint256 value) isOwner public returns(bool){
        for(uint i=0; i<_user.length; i++)
        sendInternally(_user[i],value);
    }
    
  function sendInternally(address _user, uint256 value) internal {
    require(_user != address(0));
    token.transfer(_user, value*10**18);
    emit TransferredToken(_user, value);
    
  }
  
  
}