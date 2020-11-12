pragma solidity 0.5.13;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

contract DeFiFirefly {

	uint256 constant public INITIAL_SUPPLY = 9e13; // 900,000
	uint256 public unallocatedEth;
	uint256 id;
	mapping(uint256 => address) idToAddress;
	mapping(address => bool) isUser;

	string constant public name = "Defi Firefly";
	string constant public symbol = "DFF";
	uint8 constant public decimals = 8;

	struct User {
		uint256 balance;
		uint256 staked;
		mapping(address => uint256) allowance;
		uint256 dividend;
		uint256 totalEarned;
		uint256 stakeTimestamp;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalStaked;
		mapping(address => User) users;
		address admin;
	}
	Info public info;

	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Stake(address indexed owner, uint256 tokens);
	event Unstake(address indexed owner, uint256 tokens);
	event Collect(address indexed owner, uint256 amount);
	event Fee(uint256 tokens);
	event POOLDDIVIDENDCALCULATE(uint256 totalStaked, uint256 amount,uint256 sharePerToken,uint256 eligibleMembers, uint256 totalDistributed);


	constructor() public {
		info.admin = msg.sender;
		info.totalSupply = INITIAL_SUPPLY;
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
		id =0;
		idToAddress[id] = msg.sender;
		isUser[msg.sender] = true;
		id++;
	}

	function stake(uint256 _tokens) external {
		_stake(_tokens);
	}

	function unstake(uint256 _tokens) external {
		_unstake(_tokens);
	}

	function collectDividend() public returns (uint256) {
	    uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0, "no dividends to recieve");
		address(uint160(msg.sender)).transfer(_dividends);
		emit Collect(msg.sender, _dividends);
		info.users[msg.sender].dividend = 0;
		info.users[msg.sender].totalEarned += _dividends;
		return _dividends;
	}
	
	function sendDividend() external payable onlyAdmin returns(uint256){
	    unallocatedEth += msg.value;
	    return unallocatedEth;
	}

	function distribute() external onlyAdmin {
		require(info.totalStaked > 0,"no stakers to distribute");
		require(address(this).balance > 0, "no dividend to distribute");
		uint256 share;
		uint256 count;
		uint256 distributed;
		share = div(unallocatedEth, div(info.totalStaked,1e8,"division error"),"invaid holding supply" );
		for(uint256 i=1; i<id; i++){
            if(stakedOf(idToAddress[i]) >0){
                info.users[idToAddress[i]].dividend += mul(share, div(stakedOf(idToAddress[i]),1e8,"division error"));
                distributed += mul(share, div(stakedOf(idToAddress[i]),1e8,"division error"));
                count++;
            }
        }
        emit POOLDDIVIDENDCALCULATE(info.totalStaked, unallocatedEth, share, count, distributed);
        address(uint160(info.admin)).transfer(unallocatedEth - distributed);
        if(share > 0){
            unallocatedEth = 0;
        }
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		uint256 _transferred = _transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _transferred, _data));
		}
		return true;
	}

	function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function totalStaked() public view returns (uint256) {
		return info.totalStaked;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance - stakedOf(_user);
	}

	function stakedOf(address _user) public view returns (uint256) {
		return info.users[_user].staked;
	}

	function dividendsOf(address _user) public view returns (uint256) {
        return	info.users[_user].dividend;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}
	
	function userTotalEarned(address _user) public view returns(uint256){
	    return info.users[_user].totalEarned;
	}
	
	modifier onlyAdmin(){
        require(msg.sender == info.admin,"only admin can change transaction fee ");
        _;
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

	function allInfoFor(address _user) public view returns (uint256 userBalance, uint256 userStaked, uint256 userDividends,uint256 totalEarned) {
		return ( balanceOf(_user), stakedOf(_user), dividendsOf(_user),userTotalEarned(_user));
	}

    function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens, "insufficient funds");
		if(!isUser[_to]){
		    idToAddress[id] = _to;
		    isUser[_to] = true;
		    id++;
		}
		info.users[_from].balance -= _tokens;
        info.users[_to].balance += _tokens;
        emit Transfer(_from, _to, _tokens);
        return _tokens;
    }

	function _stake(uint256 _amount) internal {
		require(balanceOf(msg.sender) >= _amount, "insufficient funds");
		info.totalStaked += _amount;
		info.users[msg.sender].staked += _amount;
		info.users[msg.sender].stakeTimestamp = now;
		emit Transfer(msg.sender, address(this), _amount);
		emit Stake(msg.sender, _amount);
	}

    function _unstake(uint256 _amount) internal {
		require(stakedOf(msg.sender) >= _amount,"user stake already 0");
		require(info.users[msg.sender].stakeTimestamp + 24 hours <= now,"must wait 24 hours before unstaking");
		if(dividendsOf(msg.sender)>0){
		    collectDividend();
		}
		info.totalStaked -= _amount;
		info.users[msg.sender].staked -= _amount;
		emit Unstake(msg.sender, _amount);
	}
}