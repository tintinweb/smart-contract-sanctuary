pragma solidity ^0.4.11;

contract ERC20Interface {
	function totalSupply() constant returns (uint supply);
	function balanceOf(address _owner) constant returns (uint balance);
	function transfer(address _to, uint _value) returns (bool success);
	function transferFrom(address _from, address _to, uint _value) returns (bool success);
	function approve(address _spender, uint _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract DepositMasterContract {
	address myAddress;
	address dedeAddress;
	address dedeStorageAddress;
	mapping (address => bool) isOurContract;

	event ContractCreated(address contractAddress);
	event Deposited(address indexed contractAddress, address indexed receivingAddress, address indexed token, uint256 value);

	modifier onlyMe() {
		require(msg.sender == myAddress);
		_;
	}
	modifier onlyDeDe() {
		require(msg.sender == dedeAddress);
		_;
	}
	modifier onlyAdmins() {
		require(msg.sender == myAddress || msg.sender == dedeAddress);
		_;
	}

	function DepositMasterContract(address _dedeAddress){
		dedeAddress = _dedeAddress;
		dedeStorageAddress = _dedeAddress;
		myAddress = msg.sender;
	}

	function createContract() onlyDeDe {
		address depositContract = new DepositContract();
		isOurContract[depositContract] = true;
		ContractCreated(depositContract);
	}
	function sweep(address contractAddress, address token, uint256 mininumValue) onlyDeDe {
		require(isOurContract[contractAddress]);
		uint256 result = DepositContract(contractAddress).sweep(token, dedeStorageAddress, mininumValue);
		if(result > 0){
			Deposited(contractAddress, dedeStorageAddress, token, result);
		}
	}

	function changeMyAddress(address newMyAddress) onlyMe {
		myAddress = newMyAddress;
	}
	function changeDeDeAddress(address newDeDeAddress) onlyAdmins {
		dedeAddress = newDeDeAddress;
	}
	function changeDeDeStorageAddress(address newDeDeStorageAddress) onlyAdmins {
		dedeStorageAddress = newDeDeStorageAddress;
	}
}

contract DepositContract {
	address masterAddress;

	modifier onlyMaster() {
		require(msg.sender == masterAddress);
		_;
	}

	function DepositContract(){
		masterAddress = msg.sender;
	}

	function sweep(address token, address dedeStorageAddress, uint256 mininumValue) onlyMaster returns (uint256) {
		bool success;
		uint256 sendingValue;
		if(token == address(0)){ // ether
			sendingValue = this.balance;
			if(mininumValue > sendingValue){
				return 0;
			}
			success = dedeStorageAddress.send(this.balance);
			return (success ? sendingValue : 0);
		}
		else{ // token
			sendingValue = ERC20Interface(token).balanceOf(this);
			if(mininumValue > sendingValue){
				return 0;
			}
			success = ERC20Interface(token).transfer(dedeStorageAddress, sendingValue);
			return (success ? sendingValue : 0);
		}
	}

	function () payable {}
}