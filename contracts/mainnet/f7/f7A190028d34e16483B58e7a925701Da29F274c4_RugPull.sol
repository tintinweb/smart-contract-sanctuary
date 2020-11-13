// SPDX-License-Identifier: MIT
pragma solidity ^ 0.6.6;

contract RugPull{
	
	Pyramid public PiZZa;
	RugToken public Rugs;
	uint public carpetBags = 25000;
	address public RugChallenger;
	uint public RugChallengerHP;
	address public CARPET_KING;
	uint public carpet_dynasty_generation;
	address public DEV;
	ERC20 public Resolve;
	address payable address0 = address(0);
	mapping(address => address) public gateway;
	mapping(address => bool) public initiated;
	mapping(address => uint) public pocket;
	mapping(address => uint) public thanks;

	constructor() public{
		PiZZa = Pyramid(0x91683899ed812C1AC49590779cb72DA6BF7971fE);
		Rugs = new RugToken();
		DEV = msg.sender;
		CARPET_KING = DEV;
		RugChallenger = DEV;
		Resolve = PiZZa.resolveToken();
		gateway[CARPET_KING] = CARPET_KING;
		initiated[DEV] = true;
	}

	function weight(address addr) public view returns(uint){
		return Resolve.balanceOf(addr);
	}

	function buy(address _gateway, uint _red, uint _green, uint _blue) public payable returns(uint bondsCreated){
		address sender = msg.sender;
		if( !initiated[sender] ){
			if( initiated[_gateway] ){
				gateway[sender] = _gateway;
			}else{
				gateway[sender] = RugChallenger;
			}
		}


		if(_red>1e18) _red = 1e18;
		if(_green>1e18) _green = 1e18;
		if(_blue>1e18) _blue = 1e18;

		uint[] memory UINTs = new uint[](4);
		UINTs[0] = msg.value * 3 / 100;
		UINTs[1] = msg.value * 2 / 100;
		UINTs[2] = msg.value * 1 / 100;
		UINTs[3] = msg.value * 6 / 1000;
		uint eth4PiZZa = msg.value - UINTs[0] - UINTs[1] - UINTs[2] - UINTs[3];


		address lvl1 = gateway[sender];
		if( weight(lvl1) > weight(sender) ){
			pocket[ lvl1 ] += UINTs[0];
		}else{
			splitForKingAndRugChallenger(UINTs[0]);
			emit ReffSnatch(RugChallenger, gateway[sender]);
			gateway[sender] = RugChallenger;
		}

		address lvl2 = gateway[lvl1];
		if( weight(lvl2) > weight(sender) ){
			pocket[ lvl2 ] += UINTs[1];
		}else{
			splitForKingAndRugChallenger(UINTs[1]);
			emit ReffSnatch(sender, gateway[lvl1]);
			gateway[lvl1] = sender;
		}

		address lvl3 = gateway[lvl2];
		if( weight(lvl3) > weight(sender) ){
			pocket[ lvl3 ] += UINTs[2];
		}else{
			splitForKingAndRugChallenger(UINTs[2]);
			emit ReffSnatch(sender, gateway[lvl2]);
			gateway[lvl2] = sender;
		}

		pocket[ CARPET_KING ] += UINTs[3];
		

		uint createdPiZZa = PiZZa.buy{value: eth4PiZZa}(sender, _red, _green, _blue);

		if(RugChallenger != sender){
			if( RugChallengerHP <= weight(sender) ){
				RugChallenger = sender;	
				RugChallengerHP = weight(sender);
				emit RugPulled(sender, RugChallenger, RugChallengerHP);
			}else{
				uint damage = weight(sender);
				if(damage>0){
					RugChallengerHP -= damage;
					emit Damaged( RugChallenger, damage );
				}
			}
		}else{
			if( RugChallengerHP < weight(sender) && msg.value > 0.001 ether)
				RugChallengerHP = weight(sender);
		}

		if(carpetBags > 0 && msg.value > 0.001 ether){
			carpetBags -= 1;
			Rugs.mint(sender, createdPiZZa);
		}

		return createdPiZZa;
	}
	event RugPulled(address winner, address loser, uint HP);
	event Damaged(address RugChallenger, uint damage);
	event ReffSnatch(address snatcher, address slacker);
	event SplitForKingAndRugChallenger(address king, address buyer);
	function splitForKingAndRugChallenger(uint ETH) internal{
		pocket[CARPET_KING] += ETH/2;
		pocket[RugChallenger] += ETH - ETH/2;
		emit SplitForKingAndRugChallenger(CARPET_KING, RugChallenger);
	}

	event Withdraw(address account, uint amount);
	function withdraw() public{
		address sender = msg.sender;
		uint amount = pocket[sender];
		if( amount>0 ){
			pocket[sender] = 0;
			(bool success, ) = sender.call{value:amount}("");
			emit Withdraw(sender, amount);
	        require(success, "Transfer failed.");
        }else{
        	revert();
        }
	}

	event RechargeMagicLamp( address indexed addr, uint256 amountStaked );
	function tokenFallback(address from, uint value, bytes calldata _data) external{
		if(msg.sender == address(Resolve) ){
			address THIS = address(this);
			if(carpetBags == 0){
				carpetBags += value / 1e16; //100 per resolve token
				CARPET_KING = from;
				//takes the resolve tokens used to recharge the magic lamp and it stakes those
				//only the original dev benefits from these resolves being staked
				//the address that recharged the lamp benefits as CARPET_KING
				//only every 6th generation stakes resolves. waits for first 6
				if(carpet_dynasty_generation % 6 == 0){
					uint earnings = PiZZa.resolveEarnings( THIS );
					if(earnings > 0){
						PiZZa.withdraw(earnings);
						
						(bool success, ) = DEV.call{value:earnings}("");
						require(success, "Transfer failed.");
					}
					Resolve.transfer( address(PiZZa), Resolve.balanceOf(THIS) );
				}

				carpet_dynasty_generation += 1;
				emit RechargeMagicLamp(from, carpetBags);
			}else{
				thanks[from] += value; //literally, this is it
				Resolve.transfer( address(PiZZa), value);
			}
		}else{
			revert("no want");
		}
	}
}


abstract contract Pyramid{
    function buy(address addr, uint _red, uint _green, uint _blue) public virtual payable returns(uint createdBonds);
    function resolveToken() public view virtual returns(ERC20);
    function resolveEarnings(address _owner) public view virtual returns (uint256 amount);
    function withdraw(uint amount) public virtual returns(uint);
}

abstract contract ERC20{
	function balanceOf(address _owner) public view virtual returns (uint256 balance);
	function transfer(address _to, uint _value) public virtual returns (bool);
}

contract RugToken{

	string public name = "Rug Token";
    string public symbol = "RUG";
    uint8 constant public decimals = 18;
	address public owner;

	constructor() public{
		owner = msg.sender;
	}

	modifier ownerOnly{
	  require(msg.sender == owner);
	  _;
    }

	event Mint(
		address indexed addr,
		uint256 amount
	);

	function mint(address _address, uint _value) external ownerOnly(){
		balances[_address] += _value;
		_totalSupply += _value;
		emit Mint(_address, _value);
	}

	mapping(address => uint256) public balances;

	uint public _totalSupply;

	mapping(address => mapping(address => uint)) approvals;

	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount,
		bytes data
	);
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount
	);
	
	function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	// Function that is called when a user or another contract wants to transfer funds.
	function transfer(address _to, uint _value, bytes memory _data) public virtual returns (bool) {
		if( isContract(_to) ){
			return transferToContract(_to, _value, _data);
		}else{
			return transferToAddress(_to, _value, _data);
		}
	}
	
	// Standard function transfer similar to ERC20 transfer with no _data.
	// Added due to backwards compatibility reasons .
	function transfer(address _to, uint _value) public virtual returns (bool) {
		//standard function transfer similar to ERC20 transfer with no _data
		//added due to backwards compatibility reasons
		bytes memory empty;
		if(isContract(_to)){
			return transferToContract(_to, _value, empty);
		}else{
			return transferToAddress(_to, _value, empty);
		}
	}


	//function that is called when transaction target is an address
	function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool) {
		moveTokens(msg.sender, _to, _value);
		emit Transfer(msg.sender, _to, _value, _data);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	//function that is called when transaction target is a contract
	function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool) {
		moveTokens(msg.sender, _to, _value);
		ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		emit Transfer(msg.sender, _to, _value, _data);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function moveTokens(address _from, address _to, uint _amount) internal virtual{
		require( _amount <= balances[_from] );

		//update balances
		balances[_from] -= _amount;
		balances[_to] += _amount;
	}

    function allowance(address src, address guy) public view returns (uint) {
        return approvals[src][guy];
    }
  	
    function transferFrom(address src, address dst, uint amount) public returns (bool){
        address sender = msg.sender;
        require(approvals[src][sender] >=  amount);
        require(balances[src] >= amount);
        approvals[src][sender] -= amount;
        moveTokens(src,dst,amount);
        bytes memory empty;
        emit Transfer(sender, dst, amount, empty);
        emit Transfer(sender, dst, amount);
        return true;
    }

    event Approval(address indexed src, address indexed guy, uint amount);
    function approve(address guy, uint amount) public returns (bool) {
        address sender = msg.sender;
        approvals[sender][guy] = amount;

        emit Approval( sender, guy, amount );
        return true;
    }

    function isContract(address _addr) public view returns (bool is_contract) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		if(length>0) {
			return true;
		}else {
			return false;
		}
	}
}


abstract contract ERC223ReceivingContract{
    function tokenFallback(address _from, uint _value, bytes calldata _data) external virtual;
}