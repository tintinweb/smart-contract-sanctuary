pragma solidity ^0.5.13;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.5.13;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

contract BerserkToken {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private INITIAL_SUPPLY = 10000 ether; 
	uint256 public BURN_RATE = 5;
	
	address public burnPoolAddress= address(0x0);
	uint256 public burnPoolAmount=0;
	uint256 public burnPoolAmountPrevious=0;
	bool public berserkSwapBool= false;

	string constant public name = "Berserk";
	string constant public symbol = "BER";
	uint8 constant public decimals = 18;
	
	mapping (address => bool) public minters;
	address public governance;
	address public burnOwner;
	address public berserkSwapOwner;
	address public berserkSwapAddress = address(0x0);
	
    mapping(address => bool) public isAdmin;

	struct User {
		bool whitelisted;
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		uint256 totalSupply;
		uint256 burnedSupply;
		mapping(address => User) users;
	}
	Info private info;

	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Burn(uint256 tokens);
	event Mint(uint256 amount);

	constructor() public {
		info.totalSupply = INITIAL_SUPPLY;
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
		info.burnedSupply = 0;
        governance = msg.sender;
        burnOwner= msg.sender;
        isAdmin[msg.sender]=true;
        berserkSwapOwner = msg.sender;
	}

	function burn(uint256 _tokens) external {
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		uint256 _burnedAmount = _tokens;
		info.totalSupply -= _burnedAmount;
		emit Transfer(msg.sender, address(0x0), _burnedAmount);
		info.burnedSupply= info.burnedSupply + _tokens;
		emit Burn(_burnedAmount);
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
	
	 function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
	
	 function addMinter(address _minter) public {
        require(msg.sender == governance, "!governance");
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public {
        require(msg.sender == governance, "!governance");
        minters[_minter] = false;
    }
    
    function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}
    
    function mint(address account, uint256 amount) public {
        require(minters[msg.sender], "!minter");
        _mint(account, amount);
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        info.totalSupply = info.totalSupply+amount;
        info.users[msg.sender].balance = info.users[msg.sender].balance+amount;
        emit Transfer(address(0), account, amount);
    }
    
    function renounceBurnOwnership () external {
        require (msg.sender == burnOwner);
        burnOwner= address(0x0);
    }
    
    function setBurnAmount(uint256 _burnAmount) public{
        require(msg.sender == burnOwner, "Not authorized!");
        BURN_RATE= _burnAmount;
    }
    
    function setBurnPoolAddress(address _burnPoolAddress) public{
        require(msg.sender == burnOwner, "Not authorized!");
        burnPoolAddress= _burnPoolAddress;
    }

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}
	
	function burnedSupply() public view returns (uint256){
	    return info.burnedSupply;
	}
	
	function resetBurnAmount() public {
	    require(isAdmin[msg.sender]==true);
	    burnPoolAmountPrevious= burnPoolAmount;
	    burnPoolAmount= 0;
	}
	
	function getBurnAmount() public view returns (uint256){
	    return burnPoolAmount;
	}
	
	function getBurnAmountPrevious() public view returns (uint256){
	    return burnPoolAmountPrevious;
	}
    
    function getBurnPoolAddress() public view returns (address){
        return burnPoolAddress;
    }
	
	function setAdminStatus(address _admin) external {
	    require (msg.sender == governance);
        isAdmin[_admin] = true;
    }
    
    function setBerserkSwapAddress (address _berserkSwapAddress) external {
        require (msg.sender == berserkSwapOwner);
        berserkSwapAddress = _berserkSwapAddress;
    }
    
    function setBerserkSwapBool () external {
        require (msg.sender == berserkSwapOwner);
        berserkSwapBool = true;
    }

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance ;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 userBalance, uint256 totalBurnedSupply) {
		return (totalSupply(), balanceOf(_user), burnedSupply());
	}
	
	function allInfoBurned() public view returns (uint256, uint256){
	    return (burnPoolAmount, burnPoolAmountPrevious);
	}

	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		uint256 _burnedAmount = _tokens * BURN_RATE;
		_burnedAmount= _burnedAmount / 100;
		uint256 _transferred = _tokens - _burnedAmount;

        if (berserkSwapBool == true) {
            if (_from == berserkSwapAddress || _to == berserkSwapAddress)
                {
                _burnedAmount = _tokens * BURN_RATE ;
                _burnedAmount= _burnedAmount / 200;
                _transferred = _tokens - _burnedAmount;
                
                info.users[_to].balance += _transferred;
    	    	emit Transfer(_from, _to, _transferred);
    			_burnedAmount /= 2;
    			
    			emit Transfer(_from, burnPoolAddress, _burnedAmount);
    			burnPoolAmount= burnPoolAmount+ _burnedAmount;
    			
    			info.users[burnPoolAddress].balance =  info.users[burnPoolAddress].balance+ _burnedAmount;
    			info.totalSupply= info.totalSupply - _burnedAmount;
    			
    			emit Transfer(_from, address(0x0), _burnedAmount);
    			info.burnedSupply= info.burnedSupply + _burnedAmount;
    			emit Burn(_burnedAmount);
                }
                
            else {
                info.users[_to].balance += _transferred;
    	    	emit Transfer(_from, _to, _transferred);
    			_burnedAmount /= 2;
    			emit Transfer(_from, burnPoolAddress, _burnedAmount);
    			burnPoolAmount= burnPoolAmount+ _burnedAmount;
    			
    			info.users[burnPoolAddress].balance =  info.users[burnPoolAddress].balance+ _burnedAmount;
    			info.totalSupply= info.totalSupply - _burnedAmount;
    			
    			emit Transfer(_from, address(0x0), _burnedAmount);
    			info.burnedSupply= info.burnedSupply + _burnedAmount;
    			emit Burn(_burnedAmount);
            }
        }

        else {
    		if (burnPoolAddress != address(0x0)) {
    	    	info.users[_to].balance = info.users[_to].balance + _transferred;
    	    	emit Transfer(_from, _to, _transferred);
    			_burnedAmount /= 2;
    			emit Transfer(_from, burnPoolAddress, _burnedAmount);
    			burnPoolAmount= burnPoolAmount+ _burnedAmount;
    			
    			info.users[burnPoolAddress].balance =  info.users[burnPoolAddress].balance+ _burnedAmount;
    			info.totalSupply= info.totalSupply - _burnedAmount;
    			
    			emit Transfer(_from, address(0x0), _burnedAmount);
    			info.burnedSupply= info.burnedSupply + _burnedAmount;
    			emit Burn(_burnedAmount);
    		}
    		
    		else {
    		    _transferred= _tokens;
    		    info.users[_to].balance = info.users[_to].balance + _tokens;
    		    emit Transfer(_from, _to, _tokens);
    		}
        }
		
		return _transferred;
	}

	 modifier onlyAdmin {
        require(isAdmin[msg.sender], "OnlyAdmin methods called by non-admin.");
        _;
    }
}