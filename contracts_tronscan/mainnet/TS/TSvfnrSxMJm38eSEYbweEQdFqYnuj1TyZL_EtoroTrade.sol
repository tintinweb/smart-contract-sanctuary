//SourceUnit: EtoroTrade.sol

pragma solidity 0.5.4;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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



contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() 
  {
	  require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
	  bool wasInitializing = initializing;
	  initializing = true;
	  initialized = true;
		_;
	  initializing = wasInitializing;
  }
  function isConstructor() private view returns (bool) 
  {
  uint256 cs;
  assembly { cs := extcodesize(address) }
  return cs == 0;
  }
  uint256[50] private __gap;

}

contract Ownable is Initializable {
  address public _owner;
   address public owner;
  uint256 private _ownershipLocked;
  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
  address indexed previousOwner,
  address indexed newOwner
	);
  function initialize(address sender) internal initializer {
   _owner = sender;
    owner = sender;
   _ownershipLocked = 0;

  }
  function ownerr() public view returns(address) {
   return _owner;

  }

  modifier onlyOwner() {
    require(isOwner());
    _;

  }

  function isOwner() public view returns(bool) {
  return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
   _transferOwnership(newOwner);

  }
  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;

  }

  // Set _ownershipLocked flag to lock contract owner forever

  function lockOwnership() public onlyOwner {
    require(_ownershipLocked == 0);
    emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private __gap;

}

interface ITRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 value) external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed sender,uint256 value);
}

contract EtoroTrade is Ownable {
    using SafeMath for uint256;
    
    

   ITRC20 private USDT_COIN; 
   
 
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
	event Registration(string  member_name,uint256 package,string  sponcer_id,address indexed sender);
	event Investment(string  member_user_id, uint256  Package,address indexed sender);
    
    constructor(address ownerAddress,ITRC20 _USDT_COIN) public {
        USDT_COIN=_USDT_COIN;
		owner = ownerAddress;
		Ownable.initialize(msg.sender);
    }
     
	function NewRegistration(string memory member_name,uint256 package, string memory sponcer_id) public payable
	{
		require(USDT_COIN.balanceOf(msg.sender)>=package,"Low Balance in wallet");
        require(USDT_COIN.allowance(msg.sender,address(this))>=package,"Approve Your Token First");
		USDT_COIN.transferFrom(msg.sender, owner, package);
		emit Registration(member_name,package,sponcer_id,msg.sender);
	}
     
    function invest(uint256 _tokenQty,string memory member_user_id) public payable {
        
        require(USDT_COIN.balanceOf(msg.sender)>=_tokenQty,"Low Balance in wallet");
        require(USDT_COIN.allowance(msg.sender,address(this))>=_tokenQty,"Approve Your Token First");
		USDT_COIN.transferFrom(msg.sender, owner, _tokenQty);
		emit Investment(member_user_id,_tokenQty,msg.sender);
              
    }
    
	
  	function multisend_USDT(address payable[]  memory  _contributors, uint256[] memory _balances, uint256 totalQty) public payable {
    	uint256 total = totalQty;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            USDT_COIN.transferFrom(msg.sender, _contributors[i], _balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
    
  
	
	function walletLoss(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
    
	function TokenFromBalance() public 
	{
        require(msg.sender == owner, "onlyOwner");
        USDT_COIN.transfer(owner,address(this).balance);
	}
	
}