/*
Copyright 2018 DeDev Pte Ltd

Author : Chongsoo Chung (Jones Chung), CEO of DeDev in Seoul, South Korea
 */

pragma solidity ^0.4.20;

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

contract Love is ERC20Interface {
	// ERC20 basic variables
	string public constant symbol = "LOVE";
	string public constant name = "LoveToken";
	uint8 public constant decimals = 0;
	uint256 public constant _totalSupply = (10 ** 10);
	mapping (address => uint) public balances;
	mapping (address => mapping (address => uint256)) public allowed;

	mapping (address => uint256) public tokenSaleAmount;
	uint256 public saleStartEpoch;
	uint256 public tokenSaleLeft = 7 * (10 ** 9);
	uint256 public tokenAirdropLeft = 3 * (10 ** 9);

	uint256 public constant tokenSaleLowerLimit = 10 finney;
	uint256 public constant tokenSaleUpperLimit = 1 ether;
	uint256 public constant tokenExchangeRate = (10 ** 8); // 100m LOVE for each ether
	uint256 public constant devReward = 18; // in percent

	address private constant saleDepositAddress = 0x6969696969696969696969696969696969696969;
	address private constant airdropDepositAddress = 0x7474747474747474747474747474747474747474;

	address public devAddress;
	address public ownerAddress;

// constructor
	function Love(address _ownerAddress, address _devAddress, uint256 _saleStartEpoch) public {
		require(_ownerAddress != 0);
		require(_devAddress != 0);
		require(_saleStartEpoch > now);

		balances[saleDepositAddress] = tokenSaleLeft;
		balances[airdropDepositAddress] = tokenAirdropLeft;

		ownerAddress = _ownerAddress;
		devAddress = _devAddress;
		saleStartEpoch = _saleStartEpoch;
	}

	function sendAirdrop(address[] to, uint256[] value) public {
		require(msg.sender == ownerAddress);
		require(to.length == value.length);
		for(uint256 i = 0; i < to.length; i++){
			if(tokenAirdropLeft > value[i]){
				Transfer(airdropDepositAddress, to[i], value[i]);

				balances[to[i]] += value[i];
				balances[airdropDepositAddress] -= value[i];
				tokenAirdropLeft -= value[i];
			}
			else{
				Transfer(airdropDepositAddress, to[i], tokenAirdropLeft);

				balances[to[i]] += tokenAirdropLeft;
				balances[airdropDepositAddress] -= tokenAirdropLeft;
				tokenAirdropLeft = 0;
				break;
			}
		}
	}

	function buy() payable public {
		require(tokenSaleLeft > 0);
		require(msg.value + tokenSaleAmount[msg.sender] <= tokenSaleUpperLimit);
		require(msg.value >= tokenSaleLowerLimit);
		require(now >= saleStartEpoch);
		require(msg.value >= 1 ether / tokenExchangeRate);

		if(msg.value * tokenExchangeRate / 1 ether > tokenSaleLeft){
			Transfer(saleDepositAddress, msg.sender, tokenSaleLeft);

			uint256 changeAmount = msg.value - tokenSaleLeft * 1 ether / tokenExchangeRate;
			balances[msg.sender] += tokenSaleLeft;
			balances[saleDepositAddress] -= tokenSaleLeft;
			tokenSaleAmount[msg.sender] += msg.value - changeAmount;
			tokenSaleLeft = 0;
			msg.sender.transfer(changeAmount);

			ownerAddress.transfer((msg.value - changeAmount) * (100 - devReward) / 100);
			devAddress.transfer((msg.value - changeAmount) * devReward / 100);
		}
		else{
			Transfer(saleDepositAddress, msg.sender, msg.value * tokenExchangeRate / 1 ether);

			balances[msg.sender] += msg.value * tokenExchangeRate / 1 ether;
			balances[saleDepositAddress] -= msg.value * tokenExchangeRate / 1 ether;
			tokenSaleAmount[msg.sender] += msg.value;
			tokenSaleLeft -= msg.value * tokenExchangeRate / 1 ether;

			ownerAddress.transfer(msg.value * (100 - devReward) / 100);
			devAddress.transfer(msg.value * devReward / 100);
		}
	}

// fallback function : send request to donate
	function () payable public {
		buy();
	}


// ERC20 FUNCTIONS
	//get total tokens
	function totalSupply() constant returns (uint supply){
		return _totalSupply;
	}
	//get balance of user
	function balanceOf(address _owner) constant returns (uint balance){
		return balances[_owner];
	}
	//transfer tokens
	function transfer(address _to, uint _value) returns (bool success){
		if(balances[msg.sender] < _value)
			return false;
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		Transfer(msg.sender, _to, _value);
		return true;
	}
	//transfer tokens if you have been delegated a wallet
	function transferFrom(address _from, address _to, uint _value) returns (bool success){
		if(balances[_from] >= _value
			&& allowed[_from][msg.sender] >= _value
			&& _value >= 0
			&& balances[_to] + _value > balances[_to]){
			balances[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			balances[_to] += _value;
			Transfer(_from, _to, _value);
			return true;
		}
		else{
			return false;
		}
	}
	//delegate your wallet to someone, usually to a smart contract
	function approve(address _spender, uint _value) returns (bool success){
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}
	//get allowance that you can spend, from delegated wallet
	function allowance(address _owner, address _spender) constant returns (uint remaining){
		return allowed[_owner][_spender];
	}
	
	function change_owner(address new_owner){
	    require(msg.sender == ownerAddress);
	    ownerAddress = new_owner;
	}
	function change_dev(address new_dev){
	    require(msg.sender == devAddress);
	    devAddress = new_dev;
	}
}