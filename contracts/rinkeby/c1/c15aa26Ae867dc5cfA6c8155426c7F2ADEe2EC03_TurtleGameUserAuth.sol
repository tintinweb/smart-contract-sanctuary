pragma solidity ^0.6.6;

contract TurtleGameUserAuth {
	
	address authContractOwner; // Owner of this contract

	uint256 totalAccounts; // Total number of registered accounts

	address[] registeredAccounts; // Array of registered addresses

	// Mapping from address of the user to nickName
    mapping(address => string) addressToNickName;

	// Mapping from nickName to address of the user
	mapping(string => address) nickNameToAddress;

	// Event is emitted when the account is created
    event AccountCreated(string nickName);

	// Contructor is called when an instance of 'TurtleGameUserAuth' contract is deployed
	constructor(string memory _nickName) public {
		authContractOwner = msg.sender;
		totalAccounts = 1;
		nickNameToAddress[_nickName] = msg.sender;
		addressToNickName[msg.sender] = _nickName;
		registeredAccounts.push(msg.sender);
	}

	// Function 'createAccount' creates an account for a unique nickName
    function createAccount(string memory _nickName) public {
        require(bytes(_nickName).length <= 32, "Nickname should not be more than 32 characters");
        require(bytes(_nickName).length > 2, "Nick name should be atleast 3 characters");
        require(nickNameToAddress[_nickName] == address(0));
        nickNameToAddress[_nickName] = msg.sender;
		addressToNickName[msg.sender] = _nickName;
		registeredAccounts.push(msg.sender);

        emit AccountCreated(_nickName);
    }

	// Function 'addressByNickName' returns address of the user by their nickName
    function addressByNickName(string memory _nickName) public view returns (address) {
        return nickNameToAddress[_nickName];
    }

	// Function 'nickNameByAddress' returns nickName of the user by their wallet address
	function nickNameByAddress(address _address) public view returns (string memory) {
        return addressToNickName[_address];
    }

	// Function 'getRegisteredAccounts' returns the list of registered accounts
	function getRegisteredAccounts() public view returns (address[] memory) {
		return registeredAccounts;
	}
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}