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

	event Issue(address dip, address scs, address issuer, address dedeAddress);
	//event Transfer(address from, address to, address issuer, address dedeAddress); // unused in current version
	event Activate(address dip, address scs, address issuer, address dedeAddress);
	event Nullify(address dip, address scs, address issuer, address dedeAddress);

	address public dedeNetworkAddress;

	address public myAddress;

	function DeDeMasterContract(address _dedeNetworkAddress){
		dedeNetworkAddress = _dedeNetworkAddress;
		myAddress = msg.sender;
	}

	function changeDedeAddress(address newDedeAddress){
		require(msg.sender == myAddress || msg.sender == dedeNetworkAddress);
		dedeNetworkAddress = newDedeAddress;
	}

	function issue(uint256 _targetAmount, uint256 _bulletAmount, address _targetAddress, address _bulletAddress, uint256 _validationTime, address _issuer) payable {
		require(msg.sender == dedeNetworkAddress);

		//have eth input, or try token transferfrom
		if(_targetAddress == 0){ // ether
			require(msg.value >= _targetAmount);
			if(msg.value > _targetAmount){
				msg.sender.transfer(msg.value - _targetAmount);
			}
		}
		else{ // token
			assert(ERC20Interface(_targetAddress).transferFrom(msg.sender, this, _targetAmount));
		}

		address dede = (new DeDeContract).value(_targetAddress == 0 ? _targetAmount : 0)(msg.sender, msg.sender, _issuer, _targetAmount, _bulletAmount, _targetAddress, _bulletAddress, _validationTime);
		isDeDeContract[dede] = true;

		if(_targetAddress != 0){ // token
			assert(ERC20Interface(_targetAddress).transfer(dede, _targetAmount));
		}

		Issue(msg.sender, dedeNetworkAddress, _issuer, dede);
	}
	function activate(address dede) payable {
		var _dede = DeDeContract(dede);

		require(isDeDeContract[dede]);

		isDeDeContract[dede] = false;

		_dede.activate.value(msg.value)(msg.sender);

		Activate(_dede.dip(), _dede.scs(), _dede.issuer(), dede);
	}
	function nullify(address dede){
		var _dede = DeDeContract(dede);

		require(isDeDeContract[dede]);

		isDeDeContract[dede] = false;

		_dede.nullify(msg.sender);

		Nullify(_dede.dip(), _dede.scs(), _dede.issuer(), dede);
	}

	/*function transfer(address receiver, address dede){ // unused in current version
		var _dede = DeDeContract(dede);

		require(isDeDeContract[dede]);

		_dede.transfer(msg.sender, receiver);

		Transfer(_dede.scs(), receiver, _dede.issuer(), dede);
	}*/
}


contract DeDeContract {
	uint256 public validationTime;

	address public masterContract;//master smart contract address
	address public dip;
	address public scs;
	address public issuer;

	address public targetAddress;//if address value is zero, this contract itself posesses ethereum as target.
	address public bulletAddress;//if address value is zero, this contract itself gets ethereum as bullet.

	uint256 public targetAmount;
	uint256 public bulletAmount;

	function DeDeContract(address _dip, address _scs, address _issuer, uint256 _targetAmount, uint256 _bulletAmount, address _targetAddress, address _bulletAddress, uint256 _validationTime) payable {
		require(now < _validationTime);

		masterContract = msg.sender;

		dip = _dip;
		scs = _scs;
		issuer = _issuer;

		targetAddress = _targetAddress;
		bulletAddress = _bulletAddress;
		targetAmount = _targetAmount;
		bulletAmount = _bulletAmount;

		validationTime = _validationTime;
	}

	function activate(address sender) payable {
		require(msg.sender == masterContract);
		require(sender == scs);
		require(now >= validationTime && now < validationTime + 1 days);

		if(targetAddress != 0){
			assert(ERC20Interface(targetAddress).transfer(scs, targetAmount)); // send target token to scs
		}

		if(bulletAddress == 0){
			require(msg.value >= bulletAmount);
			suicide(dip); // force send bullet ether to dip
		}
		else{
			assert(ERC20Interface(bulletAddress).transferFrom(scs, dip, bulletAmount)); // send bullet token to dip
			suicide(scs); // force send target or leftover ether to scs
		}
	}
	function nullify(address sender) {
		require(msg.sender == masterContract);
		require(now >= (validationTime + 1 days) && (sender == dip || sender == scs));
	
		if(targetAddress != 0){
			assert(ERC20Interface(targetAddress).transfer(dip, targetAmount));
		}

		suicide(dip);
	}

	/*function transfer(address sender, address receiver) {
		require(msg.sender == masterContract);
		require(sender == scs);

		scs = receiver;
	}*/
}