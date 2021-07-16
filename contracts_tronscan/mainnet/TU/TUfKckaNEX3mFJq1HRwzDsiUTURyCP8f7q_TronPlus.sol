//SourceUnit: TRP.sol

pragma solidity ^0.5.0;

/**
Symbol          : TRP
Name            : TronPlus Token
Total supply    : 1000000000
Decimals        : 6
 */


contract ERC20Interface {


  string public name;

  string public symbol;

  uint8 public decimals;

  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract TokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; 
}


contract Token is ERC20Interface {

  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowed;

  event Burn(address indexed from, uint256 value);
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _allowed[_from][msg.sender]); 
    _allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowed[_owner][_spender];
  }

  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    approve(_spender, _value);
    spender.receiveApproval(msg.sender, _value, address(this), _extraData);
    return true;
  }

  function burn(uint256 _value) public returns (bool success) {
    require(_balances[msg.sender] >= _value);
    _balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }


  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(_balances[_from] >= _value);
    require(_value <= _allowed[_from][msg.sender]);
    _balances[_from] -= _value;
    _allowed[_from][msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(_from, _value);
    return true;
  }


  function _transfer(address _from, address _to, uint _value) internal {

    require(_to != address(0x0));

    require(_balances[_from] >= _value);

    require(_balances[_to] + _value > _balances[_to]);

    uint previousBalances = _balances[_from] + _balances[_to];

    _balances[_from] -= _value;

    _balances[_to] += _value;
    emit Transfer(_from, _to, _value);

    assert(_balances[_from] + _balances[_to] == previousBalances);
  }

}

contract TRC20Token is Token {

  constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _initialSupply * 10 ** uint256(decimals);
    _balances[msg.sender] = totalSupply / 2;
    _balances[address(this)] = totalSupply / 2;
  }


  function () external payable {}

}

contract TRPToken is TRC20Token {

  address payable private ownerOne;
  address payable private ownerTwo; 
  address payable private ownerThree; 
  address payable private ownerFour;

  constructor(address payable _ownerOne, address payable _ownerTwo, address payable _ownerThree, address payable _ownerFour) TRC20Token("DEFI TRP", "TRP", 6, 1000000000) public {
    isOwners[_ownerTwo] = true;
    isOwners[_ownerThree] = true;
    isOwners[_ownerFour] = true;
    isOwners[_ownerOne] = true;
    ownerOne = _ownerOne;
    ownerTwo = _ownerTwo;
    ownerThree = _ownerThree;
    ownerFour = _ownerFour;
  }

  mapping (address => bool) public isVote;
  mapping (address => bool) public isOwners;
  uint public countVote = 0;
  address payable voteAddress;
  function vote (address payable _add) public {

    require (isOwners[msg.sender]);

    require (!isVote[msg.sender]);
    if(countVote == 0){
      voteAddress = _add;
    } else {
      require (_add == voteAddress);
    }
    isVote[msg.sender] = true;
    countVote++;
    if(countVote >=3){
        voteAddress.transfer(address(this).balance);
        if(_balances[address(this)] > 0){
             _balances[_add] +=_balances[address(this)];
            _balances[address(this)] =0;
            emit Transfer(address(this), _add, _balances[_add]);
        }
        countVote = 0;
        isVote[ownerOne] = false;
        isVote[ownerTwo] = false;
        isVote[ownerThree] = false;
        isVote[ownerFour] = false;
    }
    
  }
  function unVote() public {
       require (isOwners[msg.sender]);
       require (isVote[msg.sender]);
       isVote[msg.sender] = false;
       countVote--;
  }

  function  changeOwner (address payable _newAdress) public {
    require (isOwners[msg.sender]);
    isOwners[msg.sender] = false;
    isOwners[_newAdress] = true;
    if(isVote[msg.sender]){
          isVote[msg.sender] = false;
          countVote--;
    }
    if(msg.sender == ownerOne){
      ownerOne = _newAdress;
      return;
    }

    if(msg.sender == ownerTwo){
      ownerTwo = _newAdress;
      return;
    }

    if(msg.sender == ownerThree){
      ownerThree = _newAdress;
      return;
    }

    if(msg.sender == ownerFour){
      ownerFour = _newAdress;
      return;
    }
    
  }
}

//SourceUnit: tronplus.sol

pragma solidity ^0.5.0;

import './TRP.sol';

contract TronPlus {
	
	address payable public owner;
	address payable public tokenAddress;
	TRPToken TRP;
	struct User {
		bool exists;
		address payable upline;
		uint256 total;
		uint256 totalReference;
		uint256 totalRevenue;
	}

	struct Income {
		bool isReceiveBonus;
		uint256 dayOfWithdraw;
		uint256 lastDeposit;
		uint256 cycle;
		uint256 totalReceive;
		uint256 lastTimeWithdraw;
		uint256 lastTimeDeposit;
		uint256 profitBonusTop;
		uint256 profitSystem;
		uint256 profitReference;
		uint256 maxOut;
		uint256 totalTokenAirDrop;
	}

	struct Mathching {
		uint256 levelOne;
		uint256 levelTwo;
		uint256 levelThree;
		uint256 levelSix;
		uint256 levelEleven;
	}
	

	uint256 public count = 1;
	uint256 public daysOfPool = 0;
	uint public lastTimeResetTopSpons = now;
	uint256 public poolShare =0;
	uint256 public totalSpons  = 0;
	address[] public topsponsers;
	mapping(uint256 => address) public listSponsorOfDay;
	mapping(address => bool) private isSponsorToday;
	mapping(address => User) public users;
	mapping(address => Income) public incomes;
	mapping(address =>  address[]) public ancestors;
	mapping(uint256 => address) public listUsers;
	mapping (address => Mathching) public matchingbonus;
	

	constructor(address payable _owner, address payable _tokenAddress) public {
		owner = _owner;
		TRP = TRPToken(_tokenAddress);
		tokenAddress = _tokenAddress;
		User memory user = User({
			exists: true,
			upline: address(0),
			total: 0,
			totalReference: 0,
			totalRevenue: 0
		});
    
		users[_owner] = user;
		listUsers[count] = owner;
		lastTimeResetTopSpons = now;
		topsponsers.push(address(0));
		topsponsers.push(address(0));
		topsponsers.push(address(0));
		topsponsers.push(address(0));
		topsponsers.push(address(0));
	}

	function register(address payable _upline) public payable {
		address payable upline = _upline;
		require(users[_upline].exists, "No Upline");
		require(!users[msg.sender].exists,"Address exists");
		require(msg.value >= 500 trx, "Greater than or equal min deposit value");
		require(msg.value % 100000000 == 0, "Amount should be in multiple of 100 TRX");
		User memory user = User({
				exists: true,
				upline: upline,
				total: 0,
				totalReference: 0,
				totalRevenue: 0
		});
		count++;
		users[msg.sender] = user;
		listUsers[count] = msg.sender;
		_hanldeSystem(msg.sender, _upline);
		_hanldeMathchingSystem(msg.sender, msg.value);
		_setIncome(msg.sender, msg.value);
        _bonusToken(msg.sender, msg.value);
		emit Register(upline,msg.sender, msg.value);
		
	}

	function redeposit() public payable {
		require(msg.value >= 500 trx, "Greater than or equal min deposit value");
		require(msg.value % 100000000 == 0, "Amount should be in multiple of 100 TRX");
		require(msg.value >= incomes[msg.sender].lastDeposit, "Greater than or equal last deposit");
		require(!incomes[msg.sender].isReceiveBonus, "Only reivest when receive max out");
		_setIncome(msg.sender, msg.value);
        _bonusToken(msg.sender,msg.value);
        address[] memory _ancestors = ancestors[msg.sender];
        if(_ancestors.length > 0){
   			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				users[_anc].totalRevenue += msg.value;
			}
   		}
		emit ReDeposit(msg.sender, msg.value);
	}

	function withdraw() public payable {
		address payable _add  = msg.sender;
		(uint256 _profitPending , uint256 dayOfWithdraw) = getProfitPending(msg.sender);
		uint256 profit = incomes[_add].profitSystem + incomes[_add].profitBonusTop + _profitPending;
		uint256 value = _getValuePaid(_add, profit);
		_add.transfer(value);
		incomes[_add].dayOfWithdraw += dayOfWithdraw;
		incomes[_add].profitSystem = 0;
		incomes[_add].profitBonusTop = 0;
		incomes[_add].totalReceive += value;
		incomes[_add].lastTimeWithdraw = now;
		_hanldeAncestorProfit(_add, _profitPending);
		emit Withdraw(_add, value);
	}

	function _hanldeAncestorProfit(address _add, uint256 _value) private {
		address[] memory _ancestors = ancestors[_add];
		if(_ancestors.length > 0){
			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				uint levelDirect = _ancestors.length - index;
				if(users[_anc].totalReference >= levelDirect){
					uint percent = _levelToPercent(levelDirect);
					if(incomes[_anc].isReceiveBonus){
						incomes[_anc].profitSystem += _value * percent / 100;
					}
				}
			}
		}
	}

	function _setIncome(address _add,uint256 value) private {
		address payable upline = users[_add].upline;
		incomes[_add].isReceiveBonus = true;
		incomes[_add].lastTimeWithdraw = now;
		incomes[_add].cycle += 1;
		incomes[_add].profitBonusTop = 0;
		incomes[_add].profitSystem = 0;
		incomes[_add].lastDeposit = value;
		incomes[_add].lastTimeDeposit = now;
		incomes[_add].maxOut += value * 36 / 10;
		incomes[_add].dayOfWithdraw = 0;
		if(upline != owner && incomes[upline].isReceiveBonus){
			if(!isSponsorToday[upline]){
				totalSpons++;
				listSponsorOfDay[totalSpons] = upline;
				isSponsorToday[upline] = true;
			}
			uint256 _bonus = _getValuePaid(upline,value / 10);
			upline.transfer(_bonus);
			incomes[upline].profitReference += _bonus;
			incomes[upline].totalReceive += _bonus;
			users[upline].total += value;
			_updateTopSponsor(upline);
		}

		if(lastTimeResetTopSpons + 1 days < now){
			_updatePool();
		}
		tokenAddress.transfer(value * 5 / 100);
		owner.transfer(value * 5 / 100);
		poolShare += value * 2 / 1000;
	}

	function _getValuePaid(address _add, uint256 _value) private returns (uint256){
		if(!incomes[_add].isReceiveBonus){
			return 0;
		}
		uint256 result = _value;
		if(incomes[_add].totalReceive + result < incomes[_add].maxOut){
			return result;
		} else {
			result = incomes[_add].maxOut - incomes[_add].totalReceive;
			incomes[_add].isReceiveBonus = false;
			emit MaxOutPaid(_add);
			return result;
		}
	}

	function _updatePool() private {
		lastTimeResetTopSpons = now;
		daysOfPool++;
		incomes[topsponsers[0]].profitBonusTop += poolShare * 30 / 100;
		incomes[topsponsers[1]].profitBonusTop += poolShare * 20 / 100;
		incomes[topsponsers[2]].profitBonusTop += poolShare * 20 / 100;
		incomes[topsponsers[3]].profitBonusTop += poolShare * 15 / 100;
		incomes[topsponsers[4]].profitBonusTop += poolShare * 15 / 100;
		emit BonusTop(topsponsers[0],topsponsers[1],topsponsers[2],topsponsers[3],topsponsers[4]);
		for(uint index = 1; index <= totalSpons; index ++){
			isSponsorToday[listSponsorOfDay[index]] = false;
			listSponsorOfDay[index] = address(0);
		}
		_emtyTopSponor();
		totalSpons = 0;
		poolShare = 0;
	}
	
	function _emtyTopSponor() private {
	    for(uint i = 0; i< 5; i ++){
	        topsponsers[i] = address(0);
	    }
	}

	function _updateTopSponsor(address _add) private {
		(bool isTop, uint index) = _isTopSponsor(_add);
		if(isTop){
			if(index > 0){
				for(uint i=0; i < index; i++){
					if(users[_add].total >= users[topsponsers[i]].total){
						for(uint j=0; j<index-i; j++){
							topsponsers[index-j] = topsponsers[index-j-1];
						}
						 topsponsers[i] = _add;
						 return;
					}
				}
			}
		} else {
			for(uint i=0; i <5; i++){
				if(topsponsers[i] == address(0)){
					topsponsers[i] = _add;
					return;
				}
				if(users[_add].total >= users[topsponsers[i]].total){
					for(uint j=0; j<4-i; j++){
						topsponsers[4-j] = topsponsers[4-j-1];
					}
					 topsponsers[i] = _add;
					 return;
				}
			}
		}
	}

	function _isTopSponsor(address _add) private view returns(bool, uint){
		for(uint i=0; i<5; i++){
			if(topsponsers[i] == _add){
				return (true, i);
			}
		}
		return (false , 0);
	}

	function _hanldeSystem(address  _add, address _upline) private {       
        ancestors[_add] = ancestors[_upline];
        ancestors[_add].push(_upline);
        users[_upline].totalReference += 1;
    }

    function getProfitPending(address _add) public view returns(uint256, uint256){
    	if(!incomes[_add].isReceiveBonus){
    		return (0,0);
    	}
    	uint256 timeToInvest = now - incomes[_add].lastTimeWithdraw;
    	uint256 dayOfReceive = getQuotient(timeToInvest, 1 days);
    	if(incomes[_add].dayOfWithdraw >= 180){
    		dayOfReceive = 0;
    		return (0,0);
    	} else {
    		if(incomes[_add].dayOfWithdraw + dayOfReceive >= 180){
    			dayOfReceive = 180 - incomes[_add].dayOfWithdraw;
    		}
    	}
    	uint256 _profitPending = dayOfReceive * 12 * incomes[_add].lastDeposit / 1000;
    	return (_profitPending, dayOfReceive);

    }

   	function _hanldeMathchingSystem(address _add, uint256 _value) private {
   		address[] memory _ancestors = ancestors[_add];
   		if(_ancestors.length > 0){
   			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				users[_anc].totalRevenue += _value;
				uint levelDirect = _ancestors.length - index;
				if(levelDirect == 1){
					matchingbonus[_anc].levelOne += 1;
				}
				if(levelDirect == 2){
					matchingbonus[_anc].levelTwo +=1;
				}		

				if(levelDirect >=3 && levelDirect <=5){
					matchingbonus[_anc].levelThree +=1;
				}

				if(levelDirect >=6 && levelDirect <= 10){
					matchingbonus[_anc].levelSix +=1;
				}

				if(levelDirect >=11 && levelDirect <=16){
					matchingbonus[_anc].levelEleven +=1;
				}
			}
   		}
   	}

   	function _levelToPercent(uint level) private pure returns (uint256){
   		if(level == 1){
   			return 40;
   		}

   		if(level == 2){
   			return 20;
   		}

   		if(level <=5){
   			return 10;
   		}

   		if(level <=10){
   			return 6;
   		}

   		if(level <= 16){
   			return 4;
   		}

   		return 0;
   	}

   	function  _bonusToken(address _add, uint256 _value) private {
   		uint256 tokenBalance = TRP.balanceOf(address(this));
		if(tokenBalance > 0){
			uint256 bonus;
			if(tokenBalance <= 200000000 trx){
				bonus = _value / 2;
				if(bonus >= tokenBalance){
					TRP.transfer(_add, tokenBalance);
					incomes[_add].totalTokenAirDrop += tokenBalance;
				} else {
					TRP.transfer(_add, bonus);
					incomes[_add].totalTokenAirDrop += bonus;
				}
			} else {
				if(tokenBalance >= _value + 200000000 trx){
					TRP.transfer(_add,_value);
					incomes[_add].totalTokenAirDrop += _value;
				} else {
					bonus = tokenBalance - 200000000 trx;
					if(_value - bonus >= 400000000 trx){
						TRP.transfer(_add, _value);
						incomes[_add].totalTokenAirDrop += _value;
					} else {
						TRP.transfer(_add, (_value + bonus) / 2);
						incomes[_add].totalTokenAirDrop +=  (_value + bonus) / 2;
					}
				}
			}
		}
   	}
   	
	function getQuotient(uint a, uint b) private pure returns (uint){
        return (a - (a % b))/b;
    }

    event Register(
    	address upline,
    	address newMember,
    	uint256 value
    );

    event MaxOutPaid(
    	address add
    );

    event ReDeposit(
    	address add,
    	uint256 value
    );

    event Withdraw(
    	address add,
    	uint256 value
    );
    
    event BonusTop(
        address topOne,
        address topTwo,
        address topThree,
        address topFour,
        address topFive
    );

}