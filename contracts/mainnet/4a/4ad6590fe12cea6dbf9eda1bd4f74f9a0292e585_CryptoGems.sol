pragma solidity ^0.4.21;

contract CryptoGems {


	// Start of ERC20 Token standard

	event Transfer(address indexed _from, address indexed _to, uint256 _value); 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	uint256 constant private MAX_UINT256 = 2**256 - 1;
	string public name = "CryptoGem";
	string public symbol = "GEM";
	uint public decimals = 4;
	uint256 public totalSupply = 0;

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		uint256 allowance = allowed[_from][msg.sender];
		require(balances[_from] >= _value && allowance >= _value);
		balances[_to] += _value;
		balances[_from] -= _value;
		if (allowance < MAX_UINT256) {
			allowed[_from][msg.sender] -= _value;
		}
		emit Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}  

	// End of ERC20 Token standard

	event Mint(address indexed to, uint256 amount);
	event stateEvent(address indexed owner, uint256 id, uint64 state);
	event TransferMiner(address indexed owner, address indexed to, uint256 id);

	// Structure of Miner //
	struct Miner {
		uint256 id;
		string name;
		uint64 workDuration;
		uint64 sleepDuration;
		uint64 difficulty;

		uint256 workBlock;
		uint256 sleepBlock;

		uint64 state;
		bytes32 hash;
		address owner;

		bool onSale;
		uint256 salePrice;

		uint64 exp;
	}
	
	Miner[] public miners;

	uint256 public gemPerMiner = 0;
	uint256 public gemPerEther = 0;
	uint256 public etherPerMiner = 0;
	uint256 public etherPerSale = 0;
	bool public sale = true;
	address public contractOwner;


	function CryptoGems() public {
		contractOwner = msg.sender;
		gemPerEther = 10000 * (10**decimals);
		etherPerMiner = 0.5 ether;
		etherPerSale = 0.001 ether;
		gemPerMiner = 5000 * (10**decimals);
		sale = true;
	}

	modifier onlyContractOwner() {
		require(msg.sender == contractOwner);
		_;
	}

	//    Actions Payable   //
	function buyGems() public payable { 
		require( sale == true );
		require( msg.value > 0 );
		balances[ msg.sender ] += (msg.value * gemPerEther)/(1 ether);
		totalSupply += (msg.value * gemPerEther)/(1 ether);
	}

	function buyMinersWithEther(uint64 quantity) public payable {
		require( sale == true );
		require( quantity * etherPerMiner <= msg.value);
		for(uint64 i=1;i<=quantity;i++) {
			createMiner();
		}
	}
	function buyMinersWithGem(uint64 quantity) public {
		require( sale == true );
		require( quantity * gemPerMiner <= balances[ msg.sender ]);
		balances[ msg.sender ] -= quantity * gemPerMiner;
		balances[ contractOwner ] += quantity * gemPerMiner;

		emit Transfer(msg.sender, contractOwner, quantity * gemPerMiner);


		for(uint64 i=1;i<=quantity;i++) {
			createMiner();
		}
	}

	function createMiner() private {
		uint64 nonce = 1;
		Miner memory _miner = Miner({
			id: 0,
			name: "",
			workDuration:  uint64(keccak256(miners.length, msg.sender, nonce++))%(3000-2000)+2000,
			sleepDuration: uint64(keccak256(miners.length, msg.sender, nonce))%(2200-1800)+1800,
			difficulty: uint64(keccak256(miners.length, msg.sender, nonce))%(130-100)+100,
			workBlock: 0,
			sleepBlock: 0,
			state: 3,
			hash: keccak256(miners.length, msg.sender),
			owner: msg.sender,
			onSale: false,
			salePrice: 0,
			exp: 0
		});
		uint256 id = miners.push(_miner) - 1;
		miners[id].id = id;
	}


	//   Actions   //
	function goToWork(uint256 id) public {
		require(msg.sender == miners[id].owner);
		uint64 state = minerState(id);
		miners[id].state = state;
		if(state == 3) {
			//init and ready states
			miners[id].workBlock = block.number;
			miners[id].state = 0;
			emit stateEvent(miners[id].owner, id, 0);
		}
	}

	function goToSleep(uint256 id) public {
		require(msg.sender == miners[id].owner);
		uint64 state = minerState(id);
		miners[id].state = state;
		if(state == 1) {
			//tired state
			miners[id].sleepBlock = block.number;
			miners[id].state = 2;
			uint64 curLvl = getMinerLevel(id);
			miners[id].exp = miners[id].exp + miners[id].workDuration;
			uint64 lvl = getMinerLevel(id);

			uint256 gemsMined = (10**decimals)*miners[id].workDuration / miners[id].difficulty;
			balances[ msg.sender ] += gemsMined;
			totalSupply += gemsMined;


			if(curLvl < lvl) {
				miners[id].difficulty = miners[id].difficulty - 2;
			}
			emit stateEvent(miners[id].owner, id, 2);
		}
	}

	function setOnSale(uint256 id, bool _onSale, uint256 _salePrice) public payable { 
		require( msg.value >= etherPerSale );
		require( msg.sender == miners[id].owner);
		require( _salePrice >= 0 );

		miners[id].onSale = _onSale;
		miners[id].salePrice = _salePrice;
	
	}

	function buyMinerFromSale(uint256 id) public {
		require(msg.sender != miners[id].owner);
		require(miners[id].onSale == true);
		require(balances[msg.sender] >= miners[id].salePrice);
		transfer(miners[id].owner, miners[id].salePrice);

		emit TransferMiner(miners[id].owner, msg.sender, id);
		miners[id].owner = msg.sender;

		miners[id].onSale = false;
		miners[id].salePrice = 0;
	}

	function transferMiner(address to, uint256 id) public returns (bool success) {
		require(miners[id].owner == msg.sender);
		miners[id].owner = to;
		emit TransferMiner(msg.sender, to, id);
		return true;
	}


	function nameMiner(uint256 id, string _name) public returns (bool success) {
		require(msg.sender == miners[id].owner);
		bytes memory b = bytes(miners[id].name ); // Uses memory
		if (b.length == 0) {
			miners[id].name = _name;
		} else return false;

		return true;
	}

	//   Calls   //
	function getMinersByAddress(address _address) public constant returns(uint256[]) {
		uint256[] memory m = new uint256[](miners.length);
		uint256 cnt = 0;
		for(uint256 i=0;i<miners.length;i++) {
			if(miners[i].owner == _address) {
				m[cnt++] = i;
			}
		}
		uint256[] memory ret = new uint256[](cnt);
		for(i=0;i<cnt;i++) {
			ret[i] = m[i];
		}
		return ret;
	}

	function getMinersOnSale() public constant returns(uint256[]) {
		uint256[] memory m = new uint256[](miners.length);
		uint256 cnt = 0;
		for(uint256 i=0;i<miners.length;i++) {
			if(miners[i].onSale == true) {
				m[cnt++] = i;
			}
		}
		uint256[] memory ret = new uint256[](cnt);
		for(i=0;i<cnt;i++) {
			ret[i] = m[i];
		}
		return ret;
	}

	function minerState(uint256 id) public constant returns (uint64) {
		// require(msg.sender == miners[id].owner);

		//working
		if(miners[id].workBlock !=0 && block.number - miners[id].workBlock <= miners[id].workDuration) {
			return 0;
		}
		//sleeping
		if(miners[id].sleepBlock !=0 && block.number - miners[id].sleepBlock <= miners[id].sleepDuration) {
			return 2;
		}
		//tired
		if(miners[id].workBlock !=0 && block.number - miners[id].workBlock > miners[id].workDuration && miners[id].workBlock > miners[id].sleepBlock) {
			return 1;
		}
		//ready
		if(miners[id].sleepBlock !=0 && block.number - miners[id].sleepBlock > miners[id].sleepDuration && miners[id].sleepBlock > miners[id].workBlock) {
			return 3;
		}
		return 3;
	}

	function getMinerLevel(uint256 id)  public constant returns (uint8){
		uint256 exp = miners[id].exp;
		if(exp < 15000) return 1;
		if(exp < 35000) return 2;
		if(exp < 60000) return 3;
		if(exp < 90000) return 4;
		if(exp < 125000) return 5;
		if(exp < 165000) return 6;
		if(exp < 210000) return 7;
		if(exp < 260000) return 8;
		if(exp < 315000) return 9;
		return 10;
	}
	


	//   Admin Only   //
	function withdrawEther(address _sendTo, uint256 _amount) onlyContractOwner public returns(bool) {
	    
        address CryptoGemsContract = this;
		if (_amount > CryptoGemsContract.balance) {
			_sendTo.transfer(CryptoGemsContract.balance);
		} else {
			_sendTo.transfer(_amount);
		}
		return true;
	}
	function changeContractOwner(address _contractOwner) onlyContractOwner public {
		contractOwner = _contractOwner;
	}
	function setMinerPrice(uint256 _amount) onlyContractOwner public returns(bool) {
		etherPerMiner = _amount;
		return true;
	}
	function setGemPerMiner(uint256 _amount) onlyContractOwner public returns(bool) {
		gemPerMiner = _amount;
		return true;
	}
	function setSale(bool _sale) onlyContractOwner public returns(bool) {
		sale = _sale;
		return true;
	}
	function setGemPrice(uint256 _amount) onlyContractOwner public returns(bool) {
		gemPerEther = _amount;
		return true;
	}

}