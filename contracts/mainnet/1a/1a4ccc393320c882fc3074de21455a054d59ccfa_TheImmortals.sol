pragma solidity ^0.4.14;

contract TheImmortalsPhoto {
	string public photoData;
	string public photoText;
	bool public deleted;
	address superContract;
	address owner;

	function TheImmortalsPhoto(string _photoData, string _photoText, address _owner, address _superContract){
        photoData = _photoData;
        photoText = _photoText;
        deleted = false;
        superContract = _superContract;
        owner = _owner;
	}
	
	function removeFace(){
	    require(msg.sender == owner || msg.sender == superContract);
	    photoData = "";
	    photoText = "";
        deleted = true;
	}
}

contract TheImmortals {
    address public owner;
    mapping (address => address[]) public immortals;
    address[] public accounts;
    uint8 public numberImmortals;
    uint constant public maxImmortals = 5;
    
     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function TheImmortals() {
        owner = msg.sender;
    }

    event PhotoAdded(address indexed _from, address _contract);

    function addFace(string _photoData, string _photoText) payable {
        require (msg.value >= 0.1 ether || msg.sender == owner);
        require (numberImmortals <= maxImmortals);

        address newFace = new TheImmortalsPhoto(_photoData, _photoText, msg.sender, address(this));
        immortals[msg.sender].push(newFace);
        if (immortals[msg.sender].length == 1){
          accounts.push(msg.sender);
        }
        numberImmortals++;

        PhotoAdded(msg.sender, newFace);
    }

	function deleteUser(address userAddress) onlyOwner {
	    for (uint8 i=0;i<immortals[userAddress].length;i++){
	        TheImmortalsPhoto faceContract = TheImmortalsPhoto(immortals[userAddress][i]);
	        faceContract.removeFace();
            immortals[userAddress][i] = 0x0;
	    }
	}
	
	function withdraw() onlyOwner {
	    address myAddress = this;
	    owner.transfer(myAddress.balance);
	}
}