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

contract KahnAirDrop2{
    using SafeMath for uint256;
	
    struct User{
		address user_address;
		uint signup_time;
		uint256 reward_amount;
		bool blacklisted;
		uint paid_time;
		uint256 paid_token;
		bool status;
	}
	
	/* @dev Contract creator address */
    address public owner;
	
    /* @dev Assigned wallet where the remaining unclaim tokens to be return */
    address public wallet;
	
	/* @dev bounty address  */
	address[] public bountyaddress;
	
	/* @dev admin address  */
	address[] public adminaddress;
	
    /* @dev Total Signup count */
    uint public userSignupCount = 0;
	
    /* @dev Total tokens claimed */
    uint256 public userClaimAmt = 0;

    /* @dev The token being distribute */
    ERC20 public token;

    /* @dev To record the different reward amount for each bounty  */
    mapping(address => User) public bounties;
	
    /* @dev to include the bounty in the list */
	mapping(address => bool) public signups;
	
    /* @dev Admin with permission to manage the signed up bounty */
    mapping (address => bool) public admins;
	
    /**
    * @param _token Token smart contract address
    * @param _wallet ETH address to reclaim unclaim tokens
    */
    function KahnAirDrop2(ERC20 _token, address _wallet) public {
        require(_token != address(0));
        token = _token;
        admins[msg.sender] = true;
        adminaddress.push(msg.sender) -1;
        owner = msg.sender;
        wallet = _wallet;
    }

    modifier onlyOwner {
       require(msg.sender == owner);
       _;
    }
	
    modifier onlyAdmin {
        require(admins[msg.sender]);
        _;
    }

	/*******************/
	/* Owner Function **/
	/*******************/
    /* @dev Update Contract Configuration  */
    function ownerUpdateToken(ERC20 _token, address _wallet) public onlyOwner{
        token = _token;
        wallet = _wallet;
    }

	/*******************/
	/* Admin Function **/
	/*******************/
    /* @dev Add admin to whitelist */
	function addAdminWhitelist(address[] _userlist) public onlyOwner onlyAdmin{
		require(_userlist.length > 0);
		for (uint256 i = 0; i < _userlist.length; i++) {
			address baddr = _userlist[i];
			if(baddr != address(0)){
				if(!admins[baddr]){
					admins[baddr] = true;
					adminaddress.push(baddr) -1;
				}
			}
		}
	}
	
    /* @dev Remove admin from whitelist */
	function removeAdminWhitelist(address[] _userlist) public onlyAdmin{
		require(_userlist.length > 0);
		for (uint256 i = 0; i < _userlist.length; i++) {
			address baddr = _userlist[i];
			if(baddr != address(0)){
				if(admins[baddr]){
					admins[baddr] = false;
				}
			}
		}
	}
	
	/* @dev Allow Admin to reclaim all unclaim tokens back to the specified wallet */
	function reClaimBalance() public onlyAdmin{
		uint256 taBal = token.balanceOf(this);
		token.transfer(wallet, taBal);
	}
	
	function adminUpdateWallet(address _wallet) public onlyAdmin{
		require(_wallet != address(0));
		wallet = _wallet;
	}

	/***************************/
	/* Admin & Staff Function **/
	/***************************/
	/* @dev Admin/Staffs Update Contract Configuration */

    /* @dev Add user to whitelist */
    function signupUserWhitelist(address[] _userlist, uint256[] _amount) public onlyAdmin{
    	require(_userlist.length > 0);
		require(_amount.length > 0);
    	for (uint256 i = 0; i < _userlist.length; i++) {
    		address baddr = _userlist[i];
    		uint256 bval = _amount[i];
    		if(baddr != address(0)){
    			if(bounties[baddr].user_address != baddr){
					bounties[baddr] = User(baddr,now,0,false,now,bval,true);
					token.transfer(baddr, bval);
    			}
    		}
    	}
    }
	
	/* @dev Return list of bounty addresses */
	function getBountyAddress() view public onlyAdmin returns(address[]){
		return bountyaddress;
	}
	
	function chkUserDetails(address _address) view public onlyAdmin returns(address,uint,uint256,bool,uint,uint256,bool){
		require(_address != address(0));
		return(bounties[_address].user_address, bounties[_address].signup_time, bounties[_address].reward_amount, bounties[_address].blacklisted, bounties[_address].paid_time, bounties[_address].paid_token, bounties[_address].status);
	}
	
	function () external payable {
		revert();
	}
	
}