//SourceUnit: bttstarworld.sol

pragma solidity >= 0.5.0;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
    owner = msg.sender;
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

}




contract bttStarWorld is Ownable {
    
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
    }
    
   
    
    event Dividends(uint256 value , address indexed sender);
    using SafeMath for uint256;
    
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event DepositAt(address user, uint tariff, uint amount);
    
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;



    uint[] public refRewards;
    uint public totalInvestors;
    uint public totalInvested;
    uint public lastUserId = 2;
    address public owner;
    uint public Sponsor =80; 
    uint public levelUpline =8;
    uint public package1=500;
    uint public package2=1000;
    uint public package3=2000;
    uint public package4=4000;
    uint public package5=8000;
    uint public package6=16000;
    uint public package7=32000;
    uint public package8=64000;
   
  
    
    mapping(uint => address) public userIds;
    event Reinvest(address user, uint tariff, uint amount);

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    

    function registrationExt(address _referrerAddress, uint256 _value) external payable {
        registration(msg.sender, _referrerAddress, msg.value);
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
        
    }
    

   


    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
  
    function LevelDividends(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {       
        uint256 i = 0;
		trcToken id=1002000;
		assert(_contributors.length == _balances.length);
		assert(_contributors.length <= 255);
		uint256 afterValue = 0;
	
        for (i; i < _contributors.length; i++) {
            afterValue = afterValue + _balances[i];
			_contributors[i].transferToken(_balances[i],id);
        }
        emit Dividends(msg.value, msg.sender);
    }

    function DirectDividends(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {       
        uint256 i = 0;
		trcToken id=1002000;
		assert(_contributors.length == _balances.length);
		assert(_contributors.length <= 255);
		uint256 afterValue = 0;
	
        for (i; i < _contributors.length; i++) {
            afterValue = afterValue + _balances[i];
			_contributors[i].transferToken(_balances[i],id);
        }
        emit Dividends(msg.value, msg.sender);
    }




    function MetrixDividends(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {       
        uint256 i = 0;
		trcToken id=1002000;
		assert(_contributors.length == _balances.length);
		assert(_contributors.length <= 255);
		uint256 afterValue = 0;
	
        for (i; i < _contributors.length; i++) {
            afterValue = afterValue + _balances[i];
			_contributors[i].transferToken(_balances[i],id);
        }
        emit Dividends(msg.value, msg.sender);
    }


   function RewardDistribution(address[] memory _to, uint256[] memory _value) public payable returns (bool success)  {
		trcToken id=1002000;
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
		uint256 afterValue = 0;
		for (uint8 i = 0; i < _to.length; i++) {
			afterValue = afterValue + _value[i];
			address(uint160(_to[i])).transferToken(_value[i],id);
		}
		return true;
	}



    function withdrawalToAddress(address payable to, uint amount) external{
        require(msg.sender == owner);
        to.transfer(amount);
        
    }
    
    function withdrawalTokenToAddress(address payable to, uint amount, uint _tokenID) external{
        require(msg.sender == owner);
        to.transferToken(amount,_tokenID);
        
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
			require(balances[msg.sender] >= _value);
			balances[msg.sender] -= _value;
			emit Transfer(msg.sender, _to, _value); 
        return true;
    }
    
    function deposit(uint tariff) external payable {
   		emit DepositAt(msg.sender, tariff, msg.value);
    }
    
    
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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