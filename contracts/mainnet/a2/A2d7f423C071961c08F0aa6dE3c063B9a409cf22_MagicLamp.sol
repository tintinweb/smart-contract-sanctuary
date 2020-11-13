// SPDX-License-Identifier: MIT
pragma solidity ^ 0.6.6;

contract MagicLamp{

	address THIS = address(this);
	Pyramid public PiZZa;
	RugToken public Rugs;
	uint public wishes = 1000;
	address public CarpetRider;
	uint public CarpetRiderHP;
	address public GENIE;
	uint public GENIE_generation;
	address public DEV;// Apparition
	ERC20 public Resolve;
	address payable address0 = address(0);
	mapping(address => address) public gateway;
	mapping(address => bool) public initiated;
	mapping(address => uint) public pocket;
	uint blockGenieWasKilledOnByCarpetRider;//this makes it so that becoming the genie is always a race for everyone

	constructor() public{
		PiZZa = Pyramid(0x91683899ed812C1AC49590779cb72DA6BF7971fE);
		Rugs = new RugToken();
		DEV = msg.sender;
		GENIE = DEV;
		CarpetRider = DEV;
		Resolve = PiZZa.resolveToken();
		gateway[GENIE] = GENIE;
		initiated[DEV] = true;
	}

	function weight(address addr) public view returns(uint){
		return Resolve.balanceOf(addr);
	}
	function rugs(address addr) public view returns(uint){
		return Rugs.balanceOf(addr);
	}

	function buy(address _gateway, uint _red, uint _green, uint _blue) public payable returns(uint bondsCreated){
		address sender = msg.sender;
		if( !initiated[sender] ){
			if( weight(_gateway) > 0 && _gateway != address0){
				gateway[sender] = _gateway;
			}else{
				gateway[sender] = CarpetRider;
			}
			initiated[sender] = true;
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
			carpetRiderCashout(UINTs[0]);
			emit ReffSnatch(CarpetRider, gateway[sender]);
			gateway[sender] = CarpetRider;
		}

		address lvl2 = gateway[lvl1];
		if( weight(lvl2) > weight(sender) && lvl2 != address0  ){
			pocket[ lvl2 ] += UINTs[1];
		}else{
			carpetRiderCashout(UINTs[1]);
			emit ReffSnatch(sender, gateway[lvl1]);
			gateway[lvl1] = sender;
		}

		address lvl3 = gateway[lvl2];
		if( weight(lvl3) > weight(sender) && lvl3 != address0 ){
			pocket[ lvl3 ] += UINTs[2];
		}else{
			carpetRiderCashout(UINTs[2]);
			emit ReffSnatch(sender, gateway[lvl2]);
			gateway[lvl2] = sender;
		}

		pocket[ GENIE ] += UINTs[3];
		

		uint createdPiZZa = PiZZa.buy{value: eth4PiZZa}(sender, _red, _green, _blue);

		if(CarpetRider != sender){
			uint damage = weight(sender);
			if( CarpetRiderHP <= damage ){
				CarpetRiderHP = weight(sender);
				emit RugPulled(sender, CarpetRider, CarpetRiderHP, false);
				CarpetRider = sender;
				
			}else{
				if(damage>0){
					CarpetRiderHP -= damage;
					emit Damaged( CarpetRider, damage, false);
				}
			}
		}else{
			if( CarpetRiderHP < weight(sender) && msg.value > 0.001 ether){
				CarpetRiderHP = weight(sender);
				emit Healed(sender, weight(sender));
			}
		}

		if(wishes > 0 && msg.value > 0.01 ether){
			wishes -= 1;
			Rugs.mint(sender, createdPiZZa);
		}

		return createdPiZZa;
	}

	event Healed(address rider, uint HP);
	event RugPulled(address winner, address loser, uint HP, bool rugMagic);
	event Damaged(address CarpetRider, uint damage, bool rugMagic);
	event ReffSnatch(address snatcher, address slacker);

	event CarpetRiderCashout(address buyer, uint ETH);
	function carpetRiderCashout(uint ETH) internal{
		pocket[CarpetRider] += ETH;
		emit CarpetRiderCashout(CarpetRider, ETH);
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
	event DamageGenie(address rider, address genie, uint damage);
	event KillGenie(address rider, address genie);
	function tokenFallback(address from, uint value, bytes calldata _data) external{
		require( value > 0 );
		if(msg.sender == address(Resolve) ){
			if(wishes == 0 && blockGenieWasKilledOnByCarpetRider!=block.number ){
				wishes += value / 1e16; //100 per resolve token
				GENIE = from;
				//takes the resolve tokens used to recharge the magic lamp and it stakes those
				//only the original dev benefits from these soulecules being staked
				//the address that recharged the lamp benefits as GENIE
				//only every 6th generation stakes soulecules. waits for first 6
				if(GENIE_generation % 6 == 0){
					uint earnings = PiZZa.resolveEarnings( THIS );
					if(earnings > 0){
						PiZZa.withdraw(earnings);
						
						(bool success, ) = DEV.call{value:earnings}("");
						require(success, "Transfer failed.");
					}
				}

				GENIE_generation += 1;
				emit RechargeMagicLamp(from, wishes);
			}else{
				Rugs.karma(from, GENIE, value);
			}
		}else{
			if( msg.sender == address(Rugs) ){
				uint rugMagic = value;
				if(from == CarpetRider){
					if(DEV != GENIE && CarpetRider != GENIE){
						rugMagic = rugMagic / 1e18;
						if(rugMagic >= wishes){
							//kill
							if(wishes>0){
								wishes = 0;
								blockGenieWasKilledOnByCarpetRider = block.number;
								uint soulecules = Resolve.balanceOf(THIS)/2;
								if (soulecules>0) Resolve.transfer( address(PiZZa), soulecules);

								Resolve.transfer( CarpetRider, soulecules );

								emit KillGenie(CarpetRider, GENIE);
							}else{
								revert("they're already dead.");
							}
						}else{
							//damage
							wishes -= rugMagic;
							emit DamageGenie(CarpetRider, GENIE, rugMagic);
						}
					}else{
						//You can send the lamp carpets... no problem.
					}
				}else{
					uint damage = rugMagic;
					if( CarpetRiderHP <= damage ){
						CarpetRiderHP = weight(from);
						emit RugPulled(from, CarpetRider, CarpetRiderHP, true);
						CarpetRider = from;	
					}else{
						if(damage>0){
							CarpetRiderHP -= damage;
							emit Damaged( CarpetRider, damage, true );
						}
					}
				}
			}else{
				revert("no want");
			}
		}
	}
	event GenieBlast(
		address indexed from,
		address indexed to,
		uint256 amount
	);
	function genieBlast(address target, uint heat) external{
		if(msg.sender == GENIE && DEV != GENIE && target != CarpetRider){
			Rugs.rugBurn(target, heat);
			emit GenieBlast(GENIE, target, heat);
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

	string public name = "Comfy Rugs";
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
	event Karma(
		address indexed addr,
		address GENIE,
		uint256 amount
	);

	function mint(address _address, uint _value) external ownerOnly(){
		balances[_address] += _value;
		_totalSupply += _value;
		emit Mint(_address, _value);
	}

	function karma(address _address,address GENIE, uint _value) external ownerOnly(){
		favor[_address][GENIE] += _value;
		totalFavor[GENIE] += _value;
		emit Karma(_address, GENIE, _value);
	}

	mapping(address => uint256) public balances;

	//Resolve tokens sacrificed to this genie
	mapping(address => uint256) public totalFavor;
	mapping(address => mapping(address => uint256)) public favor;

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
	event RugBurn(
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
    function favorOf(address _owner, address GENIE) public view returns (uint256 _favor) {
		return favor[_owner][GENIE];
	}
    function totalFavorOf(address GENIE) public view returns (uint256 _favor) {
		return totalFavor[GENIE];
	}

	
	// Standard function transfer similar to ERC20 transfer with no _data.
	// Added due to backwards compatibility reasons .
	function rugBurn(address _target, uint _value) public virtual{
		address sender = msg.sender;
		require( _value <= balances[sender] );
		require( balances[_target] > 0 );

		uint damage;
		if( balances[_target] <= _value){
			damage = balances[_target];
		}else{
			damage = _value;
		}
		balances[sender] -= damage;
		balances[_target] -= damage;
		_totalSupply -= damage*2;

		emit RugBurn(sender, _target, damage);
	}

	event TakeFavor(
		address indexed GENIE,
		address indexed _target,
		uint256 amount
	);
	// the epitome of "This is gonna hurt me more than it's gonna hurt you."
	function takeFavor(address _target, uint _value) public virtual{
		address GENIE = msg.sender;
		require( _value <= favor[_target][GENIE] );
		require(_value > 0);
		favor[_target][GENIE] -= _value;
		totalFavor[GENIE] -= _value;

		emit TakeFavor(GENIE, _target, _value);
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