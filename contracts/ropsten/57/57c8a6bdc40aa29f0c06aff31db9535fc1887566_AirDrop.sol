pragma solidity ^0.4.24;

interface Token {
  function transfer(address _to, uint256 _value) returns(bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}


contract onlyOwner {
	address public owner;
    bool private stopped = false;
	/** 
	* @dev The Ownable constructor sets the original `owner` of the contract to the sender
	* account.
	*/
	constructor() public {
		owner = msg.sender;

	}

	/**
	* @dev Throws if called by any account other than the owner. 
	*/
	modifier isOwner {
		require(msg.sender == owner);
		_;
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
}

contract AirDrop is onlyOwner{

  Token token;

  event TransferredToken(address indexed to, uint256 value);


  constructor() public{
      address _tokenAddr = 0x2eb009E15BB8f39a34deee39369fe0FD22B6bf0f; //here pass address of your token
      token = Token(_tokenAddr);
  }
  
  struct List{
      bool tokensReceived;
  }
  
  mapping (address => List) lists;

  
  function updateUsersList() private returns(bool){
      lists[msg.sender].tokensReceived = true;
  }
  
  	modifier isNotDuplicate {
        require(!lists[msg.sender].tokensReceived);
        _;
    }
  
  function sendInternally(uint256 tokensToSend, uint256 valueToPresent) internal {
    require(msg.sender != address(0));
    token.transfer(msg.sender, tokensToSend);
    updateUsersList();
    emit TransferredToken(msg.sender, valueToPresent);
    
  }

  function withdrawTokens() isRunning isNotDuplicate external returns(bool){
      require(token.balanceOf(this) > 0);
      sendInternally(400*10**18,400);
      return true;
  }
  
}