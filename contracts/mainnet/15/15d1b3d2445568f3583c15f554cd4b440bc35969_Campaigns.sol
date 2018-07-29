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
    owner = msg.sender;

  }
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }
}

contract Campaigns is onlyOwner{

  Token token;
  event TransferredToken(address indexed to, uint256 value);


  constructor(address _contract) public{
      address _tokenAddr = _contract; //here pass address of your token
      token = Token(_tokenAddr);
  }


    function sendResidualAmount(uint256 value) isOwner public returns(bool){
        token.transfer(owner, value*10**18);
        emit TransferredToken(msg.sender, value);
        return true;
    }    
    
    function sendAmount(address[] _user, uint256 value) isOwner public returns(bool){
        for(uint i=0; i<_user.length; i++)
        token.transfer(_user[i], value*10**18);
        return true;
    }
	
	function sendIndividualAmount(address[] _user, uint256[] value) isOwner public returns(bool){
        for(uint i=0; i<_user.length; i++)
        token.transfer(_user[i], value[i]*10**18);
        return true;
    }
  
}