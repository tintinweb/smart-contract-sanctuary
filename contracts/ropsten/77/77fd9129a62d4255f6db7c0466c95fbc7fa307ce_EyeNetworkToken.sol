pragma solidity 0.4.24;

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function burn(uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * The contractName contract does this and that...
 */
contract EyeNetworkToken is ERC20, Ownable {

    using SafeMath for uint256;

    uint256  public  totalSupply = 1250000000 * 1 ether;

    mapping  (address => uint256)             public          _balances;
    mapping  (address => mapping (address => uint256)) public  _approvals;


    string   public  name = "EyeNetwork";
    string   public  symbol = "ENB";
    uint256  public  decimals = 18;

    bool public vote_locked = true;
    address vote_owner;
    uint    public  startTime;
    address[] public voters;
    mapping  (address => uint256) public _votes;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor () public{
        vote_owner = msg.sender;
        _balances[msg.sender] = totalSupply;
        startTime = block.timestamp;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint256) {
        return _approvals[src][guy];
    }

    function lock_vote_amount(bool locked) internal {
      vote_locked = locked;
    }

    function getNumOfVoters() public view returns(uint) {
        return voters.length;
    }

    function getApprovedVotes() public view returns(uint256) {
      uint256 approved = 0;
      for (uint i = 0; i < voters.length; i++) {
        approved = approved.add(_balances[voters[i]]);
      }
      return approved;
    }

    function ApplyVote() internal returns (bool) {
      uint passed_days = block.timestamp < startTime ? 0 : (block.timestamp - startTime) / 24 hours + 1;
      if (passed_days < 912) return false;
      uint256 approved = 0;

      for (uint i = 0; i < voters.length; i++) {
        approved.add(_balances[voters[i]]);
      }
      if (1000000000 * 1 ether < approved.mul(2)){
        lock_vote_amount(false);
      }
      return true;
    }
    

    function Vote() public returns (bool) {
      if (_votes[msg.sender] == 0){
         voters.push(msg.sender);
         _votes[msg.sender] = 1;
      }
      return ApplyVote();
    }


    function transfer(address dst, uint256 wad) public returns (bool) {
        require(dst != 0x0);
        require(_balances[msg.sender] >= wad);
        require(!vote_locked || msg.sender != vote_owner || (msg.sender == vote_owner && (_balances[msg.sender] >= (250000000 * 1 ether + wad)) && vote_locked));
        _balances[msg.sender] = _balances[msg.sender].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        emit Transfer(msg.sender, dst, wad);
        return true;
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(src != 0x0);
        require(dst != 0x0);
        require(_balances[src] >= wad);
        require(_approvals[src][msg.sender] >= wad);
        require(!vote_locked || msg.sender != vote_owner || (msg.sender == vote_owner && (_balances[msg.sender] >= (250000000 * 1 ether + wad)) && vote_locked));
        _approvals[src][msg.sender] = _approvals[src][msg.sender].sub(wad);
        _balances[src] = _balances[src].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        require(guy != 0x0);
        require(wad <= _balances[msg.sender]);
        require(wad == 0 || _approvals[msg.sender][guy] == 0);
        _approvals[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function burn(uint256 wad) public onlyOwner returns (bool)  {
        require(wad <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(wad);
        totalSupply = totalSupply.sub(wad);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _value) public
    {
        _approvals[msg.sender][_spender] =
        _approvals[msg.sender][_spender].add(_value);
        emit Approval(msg.sender, _spender, _approvals[msg.sender][_spender]);
    }

    function decreaseAllowance(address _spender, uint256 _value) public
    {
        _approvals[msg.sender][_spender] =
        _approvals[msg.sender][_spender].sub(_value);
        emit Approval(msg.sender, _spender, _approvals[msg.sender][_spender]);
    }
}

contract EnbManageContract is Ownable {

    using SafeMath for uint256;

    EyeNetworkToken enb;

    uint256 public constant total_investor = 400000000 * 1 ether;

    uint256 public constant total_team = 600000000 * 1 ether;
    uint256 public constant total_project_management = 50000000 * 1 ether;
    uint256 public constant total_finance_team = 150000000 * 1 ether;
    uint256 public constant total_project_team = 400000000 * 1 ether;

    uint256 public constant total_vote = 250000000 * 1 ether;

    uint256 public remain_investor;

    uint256 public remain_team;
    uint256 public avail_team;
    uint256 public avail_project_management;
    uint256 public avail_finance_team;
    uint256 public avail_project_team;
    uint256 public sent_team;

    uint256 public remain_vote;

    uint256 public constant rate = 30;

    uint    public  startTime;

	enum TeamSubdivision {
		PROJECT_MANAGEMENT_TEAM,
		FINANCE_TEAM,
		PROJECT_TEAM
	}

    event TransferForProjectManagement(address indexed beneficiary, uint256 tokenamount, uint time);
    event TransferForFinanceTeam(address indexed beneficiary, uint256 tokenamount, uint time);
    event TransferForProjectTeam(address indexed beneficiary, uint256 tokenamount, uint time);
    event TransferForVote(address indexed beneficiary, uint256 tokenamount, uint time);
    event BuyTokens(address indexed beneficiary, uint256 value, uint256 amount, uint time);

    constructor (address token) public {
        require(token != 0x0);
        enb = EyeNetworkToken(token);
		    require (enb.owner() == owner);
		    remain_investor = total_investor;
        avail_team = 0;
		    remain_team = total_team;
		    avail_project_management = total_project_management;
		    avail_finance_team = total_finance_team;
		    avail_project_team = total_project_team;
		    sent_team = 0;
		    remain_vote = total_vote;
		    startTime = time();
	}

	function () public payable  {
		buyTokens(msg.sender);
	}

	// low level token purchase function
	function buyTokens(address beneficiary) public payable  {
	    require(beneficiary != 0x0);
	    require(msg.value > 0);
		buyTokens(beneficiary, msg.value);
	}

	function buyTokens(address beneficiary, uint256 weiAmount) internal {
		require(beneficiary != 0x0);
        require(weiAmount > 0);
		// calculate token amount to be sent
		uint256 tokens = weiAmount.mul(rate);

		if(remain_investor <= tokens){
			uint256 real = remain_investor;
			remain_investor = 0;
			uint256 refund = weiAmount - real.div(rate);
			beneficiary.transfer(refund);
			transferToken(beneficiary, real);
			emit BuyTokens(beneficiary, weiAmount.sub(refund), real, time());
		} else{
			remain_investor = remain_investor.sub(tokens);
			transferToken(beneficiary, tokens);
			emit BuyTokens(beneficiary, weiAmount, tokens, time());
		}

	}

    function calcForTeam(uint256 tokenamount, TeamSubdivision calc_type) internal returns(uint256){
        uint256 real_sent;
        // today = starting date - current date *** here we calculate the date since launching the smart contract
        // if it is not 180 days yet, the value available for team will be negative
        // if available amount for team is negative(which will not allow the process to proceed then)
        // if the date is higher than 180, it will be releasable and the amount will be increased linearly
        avail_team = total_team.div(730).mul(today().sub(180)).sub(sent_team);

        // here we check if both the team type is recognizable(ex. in managmenet, finance or project team) and the token amount is more than the the amount
        if(calc_type == TeamSubdivision.PROJECT_MANAGEMENT_TEAM && avail_team.sub(tokenamount)>=0){
			if(avail_project_management.sub(tokenamount) > 0){
				if(avail_team > tokenamount){
					real_sent = tokenamount;
					avail_project_management = avail_project_management.sub(real_sent);
				}else{
					real_sent = avail_team;
					avail_project_management = avail_project_management.sub(real_sent);
				}
			}else{
				if(avail_team > avail_project_management){
					real_sent = avail_project_management;
					avail_project_management = 0;
				}else{
					real_sent = avail_team;
					avail_project_management = 0;
				}
			}
		}else if(calc_type == TeamSubdivision.FINANCE_TEAM  && avail_team.sub(tokenamount)>=0 ){
			if(avail_finance_team > tokenamount){
				if(avail_team > tokenamount){
					real_sent = tokenamount;
					avail_finance_team = avail_finance_team.sub(real_sent);
				}else{
					real_sent = avail_team;
					avail_finance_team = avail_finance_team.sub(real_sent);
				}
			}else{
				if(avail_team > avail_finance_team){
					real_sent = avail_finance_team;
					avail_finance_team = 0;
				}else{
					real_sent = avail_team;
					avail_finance_team = 0;
				}
			}
		}else if(calc_type == TeamSubdivision.PROJECT_TEAM  && avail_team.sub(tokenamount)>=0){
			if(avail_project_team > tokenamount){
				if(avail_team > tokenamount){
					real_sent = tokenamount;
					avail_project_team = avail_project_team.sub(real_sent);
				}else{
					real_sent = avail_team;
					avail_project_team = avail_project_team.sub(real_sent);
				}
			}else{
				if(avail_team > avail_project_team){
					real_sent = avail_project_team;
					avail_project_team = 0;
				}else{
					real_sent = avail_team;
					avail_project_team = 0;
				}
			}
		}else{
			revert();
		}

		sent_team = sent_team.add(real_sent);
        return real_sent;
	}

	function transfterForProjectManagement(address beneficiary, uint256 tokenamount) public onlyOwner{
		require(beneficiary != 0x0);
		uint256 real_projectmanagement = calcForTeam(tokenamount * 1 ether, TeamSubdivision.PROJECT_MANAGEMENT_TEAM);
		transferToken(beneficiary, real_projectmanagement);
        emit TransferForProjectManagement(beneficiary, real_projectmanagement, time());
	}

	function transferForFinanceTeam(address beneficiary, uint256 tokenamount) public onlyOwner{
		require(beneficiary != 0x0);
		uint256 real_financeteam = calcForTeam(tokenamount * 1 ether, TeamSubdivision.FINANCE_TEAM);
		transferToken(beneficiary, real_financeteam);
        emit TransferForFinanceTeam(beneficiary, real_financeteam, time());
	}

	function transferForProjectTeam(address beneficiary, uint256 tokenamount) public onlyOwner{
		require(beneficiary != 0x0);
		uint256 real_projecteam = calcForTeam(tokenamount * 1 ether, TeamSubdivision.PROJECT_TEAM);
		transferToken(beneficiary, real_projecteam);
        emit TransferForProjectTeam(beneficiary, real_projecteam, time());
	}

	function transferForVote(address beneficiary, uint256 tokenamount) public onlyOwner{
		require(beneficiary != 0x0);
		if(remain_vote <= tokenamount * 1 ether){
			uint256 real_vote = remain_vote;
			remain_vote = 0;
			transferToken(beneficiary,real_vote);
            emit TransferForVote(beneficiary, real_vote, time());
		}else{
			remain_vote = remain_vote.sub(tokenamount * 1 ether);
			transferToken(beneficiary,tokenamount * 1 ether);
            emit TransferForVote(beneficiary, tokenamount * 1 ether, time());
		}
	}

	function transferToken(address beneficiary, uint256 tokenamount) internal {
		enb.transfer(beneficiary, tokenamount);
	}

	function time() public view returns (uint) {
        return block.timestamp;
    }

    function today() public view returns (uint) {
        return dayFor(time());
    }

    function dayFor(uint timestamp) public view returns (uint) {
        return timestamp < startTime
            ? 0
            : (timestamp - startTime) / 24 hours + 1;
    }

	function withdrawEther() external onlyOwner
	{
		owner.transfer(address(this).balance);
	}
}