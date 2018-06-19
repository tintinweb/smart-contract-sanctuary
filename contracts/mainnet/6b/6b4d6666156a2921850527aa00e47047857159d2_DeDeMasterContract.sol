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

contract DeDeMasterContract {

	mapping (address => bool) public isDeDeContract;

	mapping (address => uint256) public validationTime;
	mapping (address => address) public dip;
	mapping (address => address) public scs;
	mapping (address => address) public issuer;
	mapping (address => address) public targetAddress;//if address value is zero, this contract itself posesses ethereum as target.
	mapping (address => address) public bulletAddress;//if address value is zero, this contract itself gets ethereum as bullet.
	mapping (address => uint256) public targetAmount;
	mapping (address => uint256) public bulletAmount;

	event Issue(address indexed dip, address indexed scs, address issuer, address indexed dedeAddress);
	event Transfer(address indexed from, address indexed to, address issuer, address indexed dedeAddress); // unused in current version
	event Activate(address indexed dip, address indexed scs, address issuer, address indexed dedeAddress);
	event Nullify(address indexed dip, address indexed scs, address issuer, address indexed dedeAddress);

	address public dedeNetworkAddress;

	function DeDeMasterContract(address _dedeNetworkAddress){
		dedeNetworkAddress = _dedeNetworkAddress;
	}

	function changeDedeAddress(address newDedeAddress){
		require(msg.sender == dedeNetworkAddress);
		dedeNetworkAddress = newDedeAddress;
	}

	function issue(uint256 _targetAmount, uint256 _bulletAmount, address _targetAddress, address _bulletAddress, uint256 _validationTime, address _issuer) payable {
		require(msg.sender == dedeNetworkAddress);
		require(now + 1 days < _validationTime);
		require(_targetAddress != _bulletAddress);

		if(_targetAddress == 0){ // ether target
			require(msg.value >= _targetAmount);
			if(msg.value > _targetAmount){
				msg.sender.transfer(msg.value - _targetAmount);
			}
		}

		address dede = (new DeDeContract).value(_targetAddress == 0 ? _targetAmount : 0)(_targetAddress, _targetAmount);
		isDeDeContract[dede] = true;

		validationTime[dede] = _validationTime;
		dip[dede] = msg.sender;
		scs[dede] = msg.sender;
		issuer[dede] = _issuer;
		targetAddress[dede] = _targetAddress;
		bulletAddress[dede] = _bulletAddress;
		targetAmount[dede] = _targetAmount;
		bulletAmount[dede] = _bulletAmount;

		if(_targetAddress != 0){ // send target token to dede
			assert(ERC20Interface(_targetAddress).transferFrom(msg.sender, dede, _targetAmount));
		}

		Issue(msg.sender, msg.sender, _issuer, dede);
	}
	function activate(address dede) payable {
		var _dede = DeDeContract(dede);

		require(isDeDeContract[dede]);

		require(msg.sender == scs[dede]);
		require(now >= validationTime[dede] && now < validationTime[dede] + 1 days);

		isDeDeContract[dede] = false;

		Activate(dip[dede], scs[dede], issuer[dede], dede);

		if(bulletAddress[dede] == 0){
			require(msg.value >= bulletAmount[dede]);
			if(msg.value > bulletAmount[dede]){
				msg.sender.transfer(msg.value - bulletAmount[dede]);
			}
		}
		else{
			assert(ERC20Interface(bulletAddress[dede]).transferFrom(scs[dede], dip[dede], bulletAmount[dede])); // send bullet token to dip
		}

		if(targetAddress[dede] != 0){
			assert(ERC20Interface(targetAddress[dede]).transferFrom(dede, scs[dede], targetAmount[dede])); // send target token to scs
		}
		_dede.activate.value(bulletAddress[dede] == 0 ? bulletAmount[dede] : 0)(bulletAddress[dede] == 0 ? dip[dede] : scs[dede]); // send target ether to scs (or bullet ether to dip) and suicide dede
	}
	function nullify(address dede){
		var _dede = DeDeContract(dede);

		require(isDeDeContract[dede]);

		require(now >= (validationTime[dede] + 1 days) && (msg.sender == dip[dede] || msg.sender == scs[dede]));

		isDeDeContract[dede] = false;

		Nullify(dip[dede], scs[dede], issuer[dede], dede);
	
		if(targetAddress[dede] != 0){
			assert(ERC20Interface(targetAddress[dede]).transferFrom(dede, dip[dede], targetAmount[dede])); // send target token to dip
		}
		_dede.nullify(dip[dede]); // send target ether to dip and suicide dede
	}

	function transfer(address receiver, address dede){ // unused in current version
		require(isDeDeContract[dede]);

		require(msg.sender == scs[dede]);

		Transfer(scs[dede], receiver, issuer[dede], dede);

		scs[dede] = receiver;
	}
}


contract DeDeContract {

	address public masterContract;//master smart contract address

	function DeDeContract(address targetAddress, uint256 targetAmount) payable {
		masterContract = msg.sender;
		if(targetAddress != 0){
			assert(ERC20Interface(targetAddress).approve(msg.sender, targetAmount));
		}
	}

	function activate(address destination) payable {
		require(msg.sender == masterContract);

		suicide(destination);
	}
	function nullify(address destination) {
		require(msg.sender == masterContract);

		suicide(destination);
	}
}