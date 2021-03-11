/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;

contract BearerCoinFactory {
    // for everyone
    address public owner;
    string public version;
    uint public buildFee;
    uint public maxNumBearerCoins;
    uint public allNumBearerCoins;
    mapping(BearerCoin => uint) public lookupBearerCoin;
    mapping(address => uint256) public userFactoryBalance;
    mapping(address => uint) public userNumBearerCoins;
    mapping(address => BearerCoin[]) private userListBearerCoins;
    BearerCoin[] private allListBearerCoins;

	constructor() {
        version = '1';
        owner = msg.sender;
        allNumBearerCoins = 0;
        maxNumBearerCoins = 1000;
        buildFee = 0.1 ether;  // held in Wei
	}

    modifier restricted() {
        require(msg.sender == owner, 'function restricted to owner');
        _;
    }

    // sending wei to the factory adds to user balance
    function addFactoryBalance(uint256 deposit) public payable {
        require(msg.value == deposit, 'value of message did not equal deposit amount');
        userFactoryBalance[msg.sender] += deposit;
    }

    // withdraw wei only if user balance permits
    function withdrawFactoryBalance(uint256 withdrawal) public {
        require(userFactoryBalance[msg.sender] >= withdrawal, 'sender factory balance less than requested withdrawal');
        require(address(this).balance >= withdrawal, 'contract balance less than requested withdrawal');

        userFactoryBalance[msg.sender] -= withdrawal;
        msg.sender.transfer(withdrawal);
    }

    // anyone with sufficient factory balance can build a coin
    function createBearerCoin() public returns (BearerCoin) {
        require(allNumBearerCoins < maxNumBearerCoins, 'factory has reached its maximum number of BearerCoins');

        if (msg.sender != owner) {
            require(userFactoryBalance[msg.sender] >= buildFee, 'factory balance needs to be greater than or equal to buildFee');
            userFactoryBalance[msg.sender] -= buildFee;
            userFactoryBalance[owner] += buildFee;
        }
        allNumBearerCoins++;
        BearerCoin myBearerCoin = new BearerCoin(msg.sender, allNumBearerCoins);
        allListBearerCoins.push(myBearerCoin);
        lookupBearerCoin[myBearerCoin] = allNumBearerCoins;

        userListBearerCoins[msg.sender].push(myBearerCoin);
        userNumBearerCoins[msg.sender]++;

        return(myBearerCoin);
    }

    // get the list of BearerCoins for a particular address
    function getUserListBearerCoins(address user) public view returns (BearerCoin[] memory) {
        return userListBearerCoins[user];
    }

    // function to checkBalance
	function checkBalance() public view returns (uint) {
	    return address(this).balance;
	}

    // owner can get list of all BearerCoins this factory has minted
    function getAllListBearerCoins() public view restricted returns (BearerCoin[] memory) {
        return allListBearerCoins;
    }

	// owner can directly change owner to another
	function setOwner(address newOwner) public restricted {
	    owner = newOwner;
	}
}

contract BearerCoin {
	address public owner;
	string public factoryVersion;
	uint public factoryNumber;
	bool public locked;
	bytes32 public pwHash;
	bytes32 public testHashBytes32;

    // set the original BearerCoin owner to whoever used the factory to create the coin
    constructor(address creatorAddress, uint curNumBearerCoins) {
        owner = creatorAddress;
        factoryNumber = curNumBearerCoins;
        factoryVersion = '1';
        locked = true;
    }

    modifier restricted() {
        require(locked == true, 'BearerCoin is locked to owner');
        require(msg.sender == owner, 'function restricted to owner');
        _;
    }

    // anyone can add Wei to the coin
    function addEther(uint256 amount) public payable { }

	function getSummary() public view returns (
		string memory, uint, bool, uint, address, bytes32
	) {
		return (
			factoryVersion,
			factoryNumber,
			locked,
			address(this).balance,
			owner,
			pwHash
		);
	}

    // Unlock the BearerCoin while setting a new pwHash
	function unlockCoin (bytes32 newPwHash) public restricted {
	    pwHash = newPwHash;
	    locked = false;
    }

    // lock the unlocked BearerCoin to a new owner
    function lockCoin(string memory oldSalt, string memory oldPw) public {
        require(locked == false, 'BearerCoin is locked, must be unlocked before tryPwHash can be called');
        bytes32 myPwHash = keccak256(abi.encodePacked(ripemd160(abi.encodePacked(oldSalt, oldPw))));
        require(myPwHash == pwHash, 'login failed');
    	owner = msg.sender;
    	locked = true;
    }

    // the owner can withdraw Wei to their own account
    function withdrawMoney(uint256 withdrawal) public restricted {
        require(address(this).balance >= withdrawal, 'coin balance less than requested withdrawal');
        msg.sender.transfer(withdrawal);
    }

    // the owner can send Wei to another account
    function transferMoney(address recipientAddress, uint256 transferWei) public restricted {
        require(address(this).balance >= transferWei, 'coin balance less than requested transfer');
        address payable recipientAddressPayable = payable(recipientAddress);
        recipientAddressPayable.transfer(transferWei);
    }

    // function to checkBalance
	function checkBalance() public view returns (uint) {
	    return address(this).balance;
	}

	// owner can directly change owner to another
	function setOwner(address newOwner) public restricted {
	    owner = newOwner;
	}
}