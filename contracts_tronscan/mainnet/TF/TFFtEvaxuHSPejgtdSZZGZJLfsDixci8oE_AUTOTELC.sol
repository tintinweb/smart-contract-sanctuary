//SourceUnit: autotelc.sol


pragma solidity 0.5.10;
contract TELCCoin {


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

contract AUTOTELC{
	address payable public owner;
	address payable public tokenAddress;
	struct User {
		uint id;
		address payable referrer;
        uint partnersCount;
        uint activeDate;
		uint deposit;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => X3) x3Matrix;
	}
	
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
	uint public telcRate = 822;
	uint public trxRate = 822;
	uint public telcRateDivider = 100;
	uint public trxRateDivider = 100;
	uint public fees = 0;
	TELCCoin AutoT;
	uint256 public count = 1;
	uint8 public constant LAST_LEVEL = 15;
	mapping(address => User) public users;
	mapping(uint256 => address payable) public listUsers;
	
	constructor(address payable _owner,address payable _tokenAddress) public {
		owner = _owner;
		AutoT = TELCCoin(_tokenAddress);
		tokenAddress = _tokenAddress;
		User memory user = User({
			id: 1,
            referrer: address(0),
            partnersCount: uint(0),
			activeDate: now,
			deposit: 0			
		});
		users[owner] = user;
		listUsers[count] = owner;
		for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[owner].activeX3Levels[i] = true;
        } 
	}
	function() external payable {
        if(msg.data.length == 0) {
            return register( owner);
        }
		
    }
	
	function register(address payable _upline) public payable {
		require(!isUserExists(msg.sender), "user exists");
        require(isUserExists(_upline), "referrer not exists");
		uint deposit = msg.value*trxRateDivider/trxRate;
		_addMember(_upline,deposit);
		emit Register(_upline,msg.sender, msg.value);
	}
	function upgrade() public payable {
		require(isUserExists(msg.sender), "user Not exists");
        uint deposit = msg.value*trxRateDivider/trxRate;
		require(users[msg.sender].deposit < deposit, "Upgrade By Higher Package");
		users[msg.sender].deposit = deposit;
		_setInstantIncome(deposit);
		emit upgrades(msg.sender, msg.value);
	}
	
	function _addMember(address payable _upline,uint deposit) internal {
		count++;
		User memory user = User({
            id: count,
            referrer: _upline,
            partnersCount: 0,
			activeDate: now,
			deposit: deposit
        });		
		users[msg.sender] = user;
		listUsers[count] = msg.sender;
		users[msg.sender].referrer = _upline;
        
        users[msg.sender].activeX3Levels[1] = true; 
		users[_upline].partnersCount++;
		
		address freeX3Referrer = findFreeX3Referrer(msg.sender, 1);
        users[msg.sender].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(msg.sender, freeX3Referrer, 1,deposit,0);
		
		_setInstantIncome(deposit);
	}
	function updateX3Referrer(address userAddress, address referrerAddress, uint8 level,uint deposit,uint8 recy) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, 	
			uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendDividends(referrerAddress,deposit,recy);
        }
        if (users[referrerAddress].x3Matrix[level].referrals.length == 3) {
			recy = 1;
			emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
			//close matrix
			users[referrerAddress].x3Matrix[level].referrals = new address[](0);
			if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
				users[referrerAddress].x3Matrix[level].blocked = true;
			}
	
			//create new one by recursion
			if (referrerAddress != owner) {
				//check referrer active level
				address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
				if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
					users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
				}
				
				users[referrerAddress].x3Matrix[level].reinvestCount++;
				emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
				updateX3Referrer(referrerAddress, freeReferrerAddress, level,deposit,recy);
			} else {
				sendDividends(owner,deposit,recy);
				users[owner].x3Matrix[level].reinvestCount++;
				emit Reinvest(owner, address(0), userAddress, 1, level);
			}
		}
    }
	function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
	function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
	function _setInstantIncome(uint deposit) private {		
		uint bp = 25;
		uint256 bonus = (bp * deposit*telcRate) / (100*telcRateDivider);
		AutoT.transfer(msg.sender,bonus);
		emit InstantIncome(msg.sender,bonus,bp);
	}
	function sendDividends(address userAddress,uint deposit,uint8 recy) private {
        address receiver = userAddress;
		deposit = deposit > users[userAddress].deposit ? users[userAddress].deposit : deposit;
		uint value = deposit*trxRate/trxRateDivider;
		uint bonus = value*40/100;
		if(bonus > 0){
			if (!address(uint160(receiver)).send(bonus)) {
				address(uint160(owner)).send(address(this).balance);
				
			}
			emit SentDividends(receiver, msg.sender, bonus, recy);
		}
        return;
		
    }
	function findReceiver(address userAddress) private view returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        return (receiver, isExtraDividends);
    }
	function withdraw(uint256 valuet) public {
		if (msg.sender == owner){
			uint256 contractBalance = address(this).balance/1e6;
			require(contractBalance >= valuet,"No Value");
			owner.transfer(valuet*1e6);
		} 
	}
	function changeFee(uint256 fee) public {
		if (msg.sender == owner){
			fees = fee;
		} 
	}
	function payFees() public payable {
		require(isUserExists(msg.sender), "user Not exists");
		require(msg.value/1e6 == fees, "Please Pay Fix Certain Fees"); 
		owner.transfer(msg.value);
	}
	function  changeTrxRate (uint8 _newRate) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		trxRate = _newRate;
		return;
	}
	function  changeTelcRate (uint8 _newRate) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		telcRate = _newRate;
		return;
	}
	function  changeTrxRateDivider (uint8 _newRate) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		trxRateDivider = _newRate;
		return;
	}
	function  changeTelcRateDivider (uint8 _newRate) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		telcRateDivider = _newRate;
		return;
	}
	
	event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
	event SentDividends(address indexed receiver, address indexed from, uint value, uint8 types);
	event Register(
    	address upline,
    	address newMember,
    	uint256 value
    );
	event upgrades(
    	address Member,
    	uint256 value
    );
	event InstantIncome(
    	address add,
    	uint256 value,
		uint256 percent
    );

    event Withdraw(
    	address add,
    	uint256 value
    );
}