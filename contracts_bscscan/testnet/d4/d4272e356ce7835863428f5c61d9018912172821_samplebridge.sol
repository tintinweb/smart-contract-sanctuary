/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

//pragma solidity ^0.4.23;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// The ERC-721 Interface to reference the Samples Publisher token
interface ERC721Interface {
     function publictotalSupply() external view returns (uint256);
     function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
     function burnToken(address tokenOwner, uint256 tid) external;
     function createToken(address sendTo, uint tid) external;
	 function setURI(string uri) external;
     function balanceOf(address _owner) external view returns (uint256 _balance);
     function ownerOf(uint256 _tokenId) external view returns (address _owner);
     function transferOwnership(address _owner) external;
	 function isApprovedForAll(address _owner, address _operator) external constant returns (bool truefalse);
}

// The ERC-721 Interface to reference the animal factory token
interface ERC721OldInterface {
     function totalSupply() public view returns (uint256);
     function safeTransferFrom(address _from, address _to, uint256 _tokenId);
     function burnToken(address tokenOwner, uint256 tid) ;
     function sendToken(address sendTo, uint tid, string tmeta) ;
     function getTotalTokensAgainstAddress(address ownerAddress) public constant returns (uint totalAnimals);
     function getAnimalIdAgainstAddress(address ownerAddress) public constant returns (uint[] listAnimals);
     function balanceOf(address _owner) public view returns (uint256 _balance);
     function ownerOf(uint256 _tokenId) public view returns (address _owner);
     function setAnimalMeta(uint tid, string tmeta);
}


contract samplebridge is Ownable
{
    


    using SafeMath for uint256;
 
    // The token from old contract
    ERC721OldInterface public oldtokenaddress;
	 // The token from new contract
    ERC721Interface public newtokenaddress;
    


    //variable to show whether the contract has been paused or not
    bool public isContractPaused;
	
	



   event TransferToNewContractMsg(address indexed owner, address indexed beneficiary, uint256 bunid);

  
   constructor(address _walletOwner,address _oldtokenaddress, address _newtokenaddress) public 
   { 
        require(_walletOwner != 0x0);
        owner = _walletOwner;
        isContractPaused = false;

        oldtokenaddress = ERC721OldInterface(_oldtokenaddress);
		newtokenaddress = ERC721Interface(_newtokenaddress);
    }



	
	function TransferToNewContract(uint bunnyid)
	{
	
		require (!isContractPaused);
		
		require(newtokenaddress.isApprovedForAll(owner,address(this)));
		
		require(bunnyid!=1);
		
        require(msg.sender != 0x0);
		
        address oldtokenowner=oldtokenaddress.ownerOf(bunnyid);
		address newtokenowner=newtokenaddress.ownerOf(bunnyid);
		
		///check if token owner is requester if not throw error
		require(oldtokenowner==msg.sender);
		
		///check if new token owner is owner of contract if not throw error
		require(newtokenowner==owner);
		
		newtokenaddress.safeTransferFrom(newtokenowner,msg.sender, bunnyid);
		
		emit TransferToNewContractMsg(newtokenowner,msg.sender, bunnyid);
		
		

	}	
  
	

    

    function pauseContract(bool isPaused) public onlyOwner
    {
        isContractPaused = isPaused;
    }
	
	
 
   

    


   
}