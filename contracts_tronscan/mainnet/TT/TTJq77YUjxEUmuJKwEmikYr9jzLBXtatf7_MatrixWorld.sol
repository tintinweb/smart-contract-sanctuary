//SourceUnit: MatrixWorld.sol

pragma solidity >=0.4.23 <0.6.0;

contract DeFi {
    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract MatrixWorld is DeFi  {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
    }

  
	struct  levels {
		bool registered;
		address referer;
		uint referrals_tier1;
		uint referrals_tier2;
		uint referrals_tier3;
		uint referrals_tier4;
		uint referrals_tier5;
		uint referrals_tier6;
		uint referrals_tier8;
		uint referrals_tier9;
		uint referrals_tier10;
		
		uint balanceRef;
		uint totalRef;
		uint withdrawn;
   }
  
    struct GlobalLevel {
            uint referralsAmt_tier1;
            uint referralsAmt_tier2;
            uint referralsAmt_tier3;
            uint referralsAmt_tier4;
            uint referralsAmt_tier5;
            uint balanceRef;
    }
	
	
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
			require(balances[msg.sender] >= _value);
			balances[msg.sender] -= _value;
			balances[_to] += _value;
			emit Transfer(msg.sender, _to, _value); 
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
        
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


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    
    uint[] public refRewards;
    uint public totalInvestors;
    uint public totalInvested;
    uint public lastUserId = 2;
    address public owner;
    uint public Sponsor =80; 
    uint public levelUpline =10;
   // uint public GlobalLevel =5;
    uint public FrontierLeader=4;
    uint public System=1;
    
    mapping (address => levels) public investors;
    mapping (address => GlobalLevel) public investorreferrals;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    event Reinvest(address user, uint tariff, uint amount);

  
    
    
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    
    
    constructor(address _ownerAddress) public {
        owner = _ownerAddress;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        users[_ownerAddress] = user;
        idToAddress[1] = _ownerAddress;
        userIds[1] = _ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner, msg.value);
        }
        
        registration(msg.sender, bytesToAddress(msg.data),msg.value);
    }

    function registrationExt(address _referrerAddress, uint256 _value) external payable {
        registration(msg.sender, _referrerAddress, msg.value);
    }
    
	
	function globallevel() public view returns (uint) {
		levels storage investor = investors[msg.sender];
    	uint amount = investor.balanceRef;
		return amount;
	}
	
	function levelUplineInvestor(uint amount, address referer) internal {
    
	  address rec = referer;
      uint refRewardPercent = 0;
      for (uint i = 0; i < 10; i++) {
			if (!investors[rec].registered) {
			break;
		}
      refRewardPercent = 1;
	  
      uint a = amount * refRewardPercent / 100;
      investorreferrals[rec].referralsAmt_tier1 += a;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      FrontierLeader += a;
      
      rec = investors[rec].referer;
    }
  }
 
 
	function registration(address _userAddress, address _referrerAddress, uint256 _value) private {
       
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: _referrerAddress,
            partnersCount: 0
        });
        users[_userAddress] = user;
        idToAddress[lastUserId] = _userAddress;
        users[_userAddress].referrer = _referrerAddress;
        userIds[lastUserId] = _userAddress;
        lastUserId++;
        users[_referrerAddress].partnersCount++;
        emit Registration(_userAddress, _referrerAddress, users[_userAddress].id, users[_referrerAddress].id);
    }
    

    function isUserExists(address _user) public view returns (bool) {
        return (users[_user].id != 0);
    }


    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

   function RewardDistribution(address[] memory _to, uint256[] memory _value) public payable returns (bool success)  {
		// input validation
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
		uint256 afterValue = 0;
		for (uint8 i = 0; i < _to.length; i++) {
			afterValue = afterValue + _value[i];
			address(uint160(_to[i])).transfer(_value[i]);
		}
		return true;
	}
}