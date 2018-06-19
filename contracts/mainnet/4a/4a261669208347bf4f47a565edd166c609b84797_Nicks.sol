pragma solidity ^0.4.24;

contract Nicks {
  mapping (address => string) private nickOfOwner;
  mapping (string => address) private ownerOfNick;

  event Set (string indexed _nick, address indexed _owner);
  event Unset (string indexed _nick, address indexed _owner);

  constructor () public {
	contractOwner = msg.sender;
  }
  
  address public contractOwner; 
  

modifier onlyOwner() {
		require(contractOwner == msg.sender);
		_;
	}

	
  function nickOf (address _owner) public view returns (string _nick) {
    return nickOfOwner[_owner];
  }

  function ownerOf (string _nick) public view returns (address _owner) {
    return ownerOfNick[_nick];
  }

  function set (string _nick) public {
    require(bytes(_nick).length > 2);
    require(ownerOf(_nick) == address(0));

    address owner = msg.sender;
    string storage oldNick = nickOfOwner[owner];

    if (bytes(oldNick).length > 0) {
      emit Unset(oldNick, owner);
      delete ownerOfNick[oldNick];
    }

    nickOfOwner[owner] = _nick;
    ownerOfNick[_nick] = owner;
    emit Set(_nick, owner);
  }

  function unset () public {
    require(bytes(nickOfOwner[msg.sender]).length > 0);

    address owner = msg.sender;
    string storage oldNick = nickOfOwner[owner];

    emit Unset(oldNick, owner);

    delete ownerOfNick[oldNick];
    delete nickOfOwner[owner];
  }

  
  

/////////////////////////////////
/// USEFUL FUNCTIONS ///
////////////////////////////////

/* Fallback function to accept all ether sent directly to the contract */

    function() payable public
    {    }
	
	
	function withdrawEther() public onlyOwner {
		require(address(this).balance > 0);
		
        contractOwner.transfer(address(this).balance);
    }
	
}