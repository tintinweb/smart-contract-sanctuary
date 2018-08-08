pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface Token { 
    function distr(address _to, uint256 _value) external returns (bool);
    function teamdistr(address _to, uint256 _value) external returns (bool);
    function totalSupply() constant external returns (uint256 supply);
    function balanceOf(address _owner) constant external returns (uint256 balance);
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TFFC is ERC20Basic {

	using SafeMath for uint256;
	address owner = msg.sender;

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	mapping (address => bool) public blacklist;

	string public constant name = "TFFC";
	string public constant symbol = "TF";
	uint public constant decimals = 8;

	uint256 public totalSupply = 50000000e8;//50000000e8;//总量5000万个
	uint256 public totaTeamRemaining = (totalSupply.div(100).mul(20));
	uint256 private totaTeamRemainingBak = totaTeamRemaining;
	uint256 public totalRemaining = (totalSupply.sub(totaTeamRemaining));
	uint256 private totalRemainingBak = totalRemaining;
	uint256 public uservalue;
	uint256 public teamvalue;
	uint256 private TeamReleaseCount = 0;
	uint256 private UserSendCount = 0;
	uint256 private UserSendCountBak = 0; 
	uint256 private totalPhaseValue = 1000e8;
	bool public distributionuserFinished = false; //用户分发是否结束的标志 false:未结束 true:结束
	bool public distributionteamFinished = false;//团队分发是否结束的标志 false：未结束  true： 结束

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event UserDistr(address indexed to, uint256 amount);
    event TeamDistr(address indexed to, uint256 amount);
    event DistrFinished();

	modifier onlyOwner() {
		require(msg.sender == owner);
        _;
	}

	modifier canUserDistr() {
        require(!distributionuserFinished);
        _;
    }

    modifier canTeamDistr() {
        require(!distributionteamFinished);
        _;
    }

    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function TFFC () public {
    	owner = msg.sender;
    	uservalue = 1000e8;
    	teamvalue = (totaTeamRemaining.div(100).mul(20));
    }

    function teamdistr(address _to, uint256 _amount) canTeamDistr private returns (bool) {
    	TeamReleaseCount = TeamReleaseCount.add(_amount);
    	totaTeamRemaining = totaTeamRemaining.sub(_amount);
    	balances[_to] = balances[_to].add(_amount);
    	emit TeamDistr(_to,_amount);
    	emit Transfer(address(0), _to, _amount);
    	
    	return true;

    	if (TeamReleaseCount >= totaTeamRemainingBak) {
        	distributionteamFinished = true;
        }
    }

    function teamRelease(address _to) payable canTeamDistr onlyOwner public {
    	if (teamvalue > totaTeamRemaining) {
			teamvalue = totaTeamRemaining;
		}

		require(teamvalue <= totaTeamRemaining);

        teamdistr(_to, teamvalue);

        if (TeamReleaseCount >= totaTeamRemainingBak) {
        	distributionteamFinished = true;
        }
    }

    function () external payable {
        getTokens();
    }

    function distr(address _to, uint256 _amount) canUserDistr private returns (bool) {
		
		UserSendCount = UserSendCount.add(_amount);
		totalRemaining = totalRemaining.sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		if (UserSendCount < totalRemainingBak) {
			if (UserSendCount.sub(UserSendCountBak) >= totalPhaseValue) {
        		uservalue = uservalue.div(2);
        		UserSendCountBak = UserSendCount;
        	}
		}

        emit UserDistr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        
        return true;
        
        if (UserSendCount >= totalRemainingBak) {
        	distributionuserFinished = true;
        }
        
    }


	function getTokens() payable canUserDistr onlyWhitelist public {
		
		if (uservalue > totalRemaining) {
			uservalue = totalRemaining;
		}

		require(uservalue <= totalRemaining);

		address investor = msg.sender;
        uint256 toGive = uservalue;

        distr(investor, toGive);

        if (toGive > 0) {
        	blacklist[investor] = true;
        }

        if (UserSendCount >= totalRemainingBak) {
        	distributionuserFinished = true;
        }
	}

	function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function enableWhitelist(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = false;
        }
    }

    function disableWhitelist(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = true;
        }
    }

    function finishUserDistribution() onlyOwner canUserDistr public returns (bool) {
        distributionuserFinished = true;
        emit DistrFinished();
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }

    function withdraw() onlyOwner public {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }

    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }

    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}