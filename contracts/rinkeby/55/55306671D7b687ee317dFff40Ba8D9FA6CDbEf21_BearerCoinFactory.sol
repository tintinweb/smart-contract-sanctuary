/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BearerCoinFactory {

    address private owner;
    string private version = '1';
    uint256 private buildFee = 0.1 ether;  // held in Wei
    uint256 private allNumBearerCoins = 0;

    mapping(BearerCoin => uint256) public lookupBearerCoinId;
    mapping(uint256 => BearerCoin) public lookupBearerCoinAddress;
    mapping(address => uint256) public userFactoryBalance;
    mapping(address => uint256) public userNumBearerCoins;
    mapping(address => BearerCoin[]) private userListBearerCoins;

    BearerCoin[] private allListBearerCoins;

	constructor() {
        owner = msg.sender;
	}

    modifier onlyOwner() {
        require(msg.sender == owner, 'function restricted to owner');
        _;
    }

	function getSummary() public view returns (
		address, string memory, uint256, uint256, uint256
	) {
		return (
			owner,
			version,
			allNumBearerCoins,
			buildFee,
			address(this).balance
		);
	}

    // sending wei to the factory adds to user balance
    function addFactoryBalance(uint256 _deposit) public payable {
        require(msg.value == _deposit, 'value of message did not equal deposit amount');
        userFactoryBalance[msg.sender] += _deposit;
    }

    // withdraw wei only if user balance permits
    function withdrawFactoryBalance(uint256 _withdrawal) public {
        require(userFactoryBalance[msg.sender] >= _withdrawal, 'sender factory balance less than requested withdrawal');
        require(address(this).balance >= _withdrawal, 'contract balance less than requested withdrawal');

        userFactoryBalance[msg.sender] -= _withdrawal;
        payable(msg.sender).transfer(_withdrawal);
    }

    // anyone with sufficient factory balance can build a coin
    function createBearerCoin() public {
        if (msg.sender != owner) {
            require(userFactoryBalance[msg.sender] >= buildFee, 'factory balance needs to be greater than or equal to buildFee');
            userFactoryBalance[msg.sender] -= buildFee;
            userFactoryBalance[owner] += buildFee;
        }
        allNumBearerCoins++;
        BearerCoin myBearerCoin = new BearerCoin(msg.sender, address(this), allNumBearerCoins);
        allListBearerCoins.push(myBearerCoin);
        lookupBearerCoinId[myBearerCoin] = allNumBearerCoins;
        lookupBearerCoinAddress[allNumBearerCoins] = myBearerCoin;

        userListBearerCoins[msg.sender].push(myBearerCoin);
        userNumBearerCoins[msg.sender]++;
    }

    // get the list of BearerCoins for a particular address
    function getUserListBearerCoins(address _user) public view returns (BearerCoin[] memory) {
        return userListBearerCoins[_user];
    }

    // owner can get list of all BearerCoins this factory has minted
    function getAllListBearerCoins() public view onlyOwner returns (BearerCoin[] memory) {
        return allListBearerCoins;
    }

	// owner can change owner of factory
	function setOwner(address _owner) public onlyOwner {
	    owner = _owner;
	}

    // call setOwner on the BearerCoin
	function setOwner(address _bc, uint256 _gasFee, address _gasAddress, string memory _pw, bytes32 _newPwHash, address _owner) public onlyOwner {
        BearerCoin bc = BearerCoin(payable(_bc));
        bc.setOwner(_gasFee, _gasAddress, _pw, _newPwHash, _owner);
    }

    // call setZeroOwner on the BearerCoin
	function setZeroOwner(address _bc, uint256 _gasFee, address _gasAddress, string memory _pw, bytes32 _newPwHash) public onlyOwner {
        BearerCoin bc = BearerCoin(payable(_bc));
        bc.setZeroOwner(_gasFee, _gasAddress, _pw, _newPwHash);
    }

    // call transferMoney on the BearerCoin
    function transferMoney(address _bc, uint256 _gasFee, address _gasAddress, string memory _pw, bytes32 _newPwHash, address _recipientAddress, uint256 _transferWei) public onlyOwner {
        BearerCoin bc = BearerCoin(payable(_bc));
        bc.transferMoney(_gasFee, _gasAddress, _pw, _newPwHash, _recipientAddress, _transferWei);
    }
}

contract BearerCoin {
	address private owner;
	address private factoryAddress;
	uint256 private coinNumber;
	bytes32 private pwHash;

    // set the original BearerCoin owner to whoever used the factory to create the coin
    constructor(address _owner, address _factoryAddress, uint256 _coinNumber) {
        owner = _owner;
        factoryAddress = _factoryAddress;
        coinNumber = _coinNumber;
        pwHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'function restricted to owner');
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factoryAddress, 'function restricted to factory');
        _;
    }

    // anyone can add Wei to the coin
    receive() external payable { /* allow deposits */ }

	function getSummary() public view returns (
		address, uint256, uint256, address, bytes32
	) {
		return (
			factoryAddress,
			coinNumber,
			address(this).balance,
			owner,
			pwHash
		);
	}

    // owner can set a new password
	function setPwHash (bytes32 _pwHash) public onlyOwner {
	    pwHash = _pwHash;
    }

    // owner can set the password to zero
	function setZeroPwHash () public onlyOwner {
	    pwHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
    }

	// owner can set a new owner
	function setOwner(address _owner) public onlyOwner {
	    owner = _owner;
	}
	
	// owner can set the owner to zero
	function setZeroOwner() public onlyOwner {
        owner = 0x0000000000000000000000000000000000000000;
	}
	
    // owner can withdraw Wei to their own account
    function withdrawMoney(uint256 _withdrawal) public onlyOwner {
        require(address(this).balance >= _withdrawal, 'coin balance less than requested withdrawal');
        payable(msg.sender).transfer(_withdrawal);
    }

    // owner can send Wei to another account
    function transferMoney(address _recipientAddress, uint256 _transferWei) public onlyOwner {
        require(address(this).balance >= _transferWei, 'coin balance less than requested transfer');
        address payable _recipientAddressPayable = payable(_recipientAddress);
        _recipientAddressPayable.transfer(_transferWei);
    }

	// pwHash can set a new owner through factory
	function setOwner(uint256 _gasFee, address _gasAddress, string memory _pw, bytes32 _newPwHash, address _owner) public payable onlyFactory {
        require(pwHash == keccak256(abi.encodePacked(ripemd160(abi.encodePacked(_pw)))), 'password failed');
        require(address(this).balance >= _gasFee, 'coin balance less than gas fee');
	    pwHash = _newPwHash;
	    owner = _owner;
        payable(_gasAddress).transfer(_gasFee);
	}
	
	// pwHash can set the owner to zero through factory
	function setZeroOwner(uint256 _gasFee, address _gasAddress, string memory _pw, bytes32 _newPwHash) public payable onlyFactory {
        require(pwHash == keccak256(abi.encodePacked(ripemd160(abi.encodePacked(_pw)))), 'password failed');
        require(address(this).balance >= _gasFee, 'coin balance less than gas fee');
	    pwHash = _newPwHash;
        owner = 0x0000000000000000000000000000000000000000;
        payable(_gasAddress).transfer(_gasFee);
	}
	
    // pwHash can send Wei to another account through factory
    function transferMoney(uint256 _gasFee, address _gasAddress, string memory _pw, bytes32 _newPwHash, address _recipientAddress, uint256 _transferWei) public payable onlyFactory {
        require(pwHash == keccak256(abi.encodePacked(ripemd160(abi.encodePacked(_pw)))), 'password failed');
        require(address(this).balance >= _transferWei + _gasFee, 'coin balance less than requested transfer plus gas fee');
	    pwHash = _newPwHash;
        payable(_recipientAddress).transfer(_transferWei);
        payable(_gasAddress).transfer(_gasFee);
    }
}