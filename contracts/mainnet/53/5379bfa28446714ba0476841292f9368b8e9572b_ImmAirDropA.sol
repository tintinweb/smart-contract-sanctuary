pragma solidity ^0.4.21;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ImmAirDropA{
    using SafeMath for uint256;
    uint256 public decimals = 18;
    address public owner;
    address public wallet;
    ERC20 public token;
    mapping (address => bool) public admins;
	
    modifier onlyOwner {
       require(msg.sender == owner);
       _;
    }
	
     function ImmAirDropA(ERC20 _token, address _wallet) public {
        require(_token != address(0));
        token = _token;
        admins[msg.sender] = true;
        owner = msg.sender;
        wallet = _wallet;
    }

   modifier onlyAdmin {
        require(admins[msg.sender]);
        _;
    }

	function addAdminWhitelist(address _userlist) public onlyOwner onlyAdmin{
		if(_userlist != address(0) && !admins[_userlist]){
			admins[_userlist] = true;
		}
	}
	
	function reClaimBalance() public onlyAdmin{
		uint256 taBal = token.balanceOf(this);
		token.transfer(wallet, taBal);
	}
	
	function adminUpdateWallet(address _wallet) public onlyAdmin{
		require(_wallet != address(0));
		wallet = _wallet;
	}

	function adminUpdateToken(ERC20 _token) public onlyOwner{
		require(_token != address(0));
		token = _token;
	}

    function signupUserWhitelist(address[] _userlist, uint256 _amttype) public onlyAdmin{
    	require(_userlist.length > 0);
    	uint256 useamt = _amttype * (10 ** uint256(decimals));
    	for (uint256 i = 0; i < _userlist.length; i++) {
    		if(_userlist[i] != address(0)){
    			token.transfer(_userlist[i], useamt);
    		}
    	}
    }
	
	function () external payable {
		revert();
	}
	
}