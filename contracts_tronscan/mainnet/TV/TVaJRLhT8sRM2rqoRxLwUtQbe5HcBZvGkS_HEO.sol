//SourceUnit: HEOTest3.sol

pragma solidity >=0.5.4;

interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Managable {
    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

contract HEO is Managable {

	struct User {
		uint8 cycle;
		uint8 level;
		address upline;
		uint16 referees;
        uint256 teams;
		uint256 refBonus;
		uint256 poolBonus;
		uint256 teamsBonus;
		uint256 investPayouts;
		uint256 payouts;
		uint256 depositAmount;
        uint256 depositTop;
		uint256 depositPayouts;
		uint40 depositTime;
		uint256 investLast;
	}

	struct Uext {
		uint256 directBonus;
		uint256 totalDeposits;
		uint256 totalPayouts;
	}

	ITRC20 usdtToken;

	address payable private supperUpline;
	address payable private adminAddr;
	address payable private owesFund;
	address payable private supplyFund;
	address payable private safeFund;
	address payable private encourageFund;
	mapping(address => User) private users;
	mapping(address => Uext) private uexts;
	uint256 private minDeposit;
    uint256 private maxDeposit;
	uint8[] private refBonusScale; 
	uint8[] private teamsBonusScale; 
	uint8[] private poolBonuses; 
	uint40 private poolLastDraw = uint40(block.timestamp);
	uint256 public poolCycle; 
	uint256 private poolBalance;
	mapping(uint256 => mapping(address => uint256)) private poolUsersRefsDepositsSum;
	mapping(uint8 => address) private poolTop;
	uint256 private totalUsers = 1;
	uint256 private totalDeposited;
	uint256 private totalWithdraw;
	uint256 private adminWithdraw;
	
	event uplineEvent(address indexed addr, address indexed upline);
	event depositEvent(address indexed addr, uint256 amount);
	event refPayoutEvent(address indexed addr, address indexed from, uint256 amount);
	event teamsPayoutEvent(address indexed addr, address indexed from, uint256 amount);
	event poolPayoutEvent(address indexed addr, uint256 amount);
	event withdrawEvent(address indexed addr, uint256 amount);
	event logDate(uint40 date);

	event logIEvent(address indexed addr, uint256 log);

	constructor(address payable _trc_addr, address payable _supper_upline, address payable _admin_addr, address payable _owes_fund, address payable _supply_fund, address payable _safe_fund, address payable _encourage_fund) public {
		supperUpline = _supper_upline;
		adminAddr = _admin_addr;
		owesFund = _owes_fund;
		supplyFund = _supply_fund;
		safeFund = _safe_fund;
		encourageFund = _encourage_fund;

		usdtToken = ITRC20(_trc_addr);
		refBonusScale.push(0);
		refBonusScale.push(10);
		refBonusScale.push(10);
		refBonusScale.push(10);
		refBonusScale.push(10);
		refBonusScale.push(5);
		refBonusScale.push(5);
		refBonusScale.push(5);
		refBonusScale.push(5);
		refBonusScale.push(5);
		teamsBonusScale.push(5);
		teamsBonusScale.push(10);
		teamsBonusScale.push(15);
		poolBonuses.push(4);
		poolBonuses.push(3);
		poolBonuses.push(2);
		poolBonuses.push(1);
        minDeposit = 1e8;
        maxDeposit = 2e9;
	}

	function setSupperUpline(address payable _supper_upline) public onlyOwner {
        supperUpline = _supper_upline;
    }

	function setAdminAddr(address payable _admin_addr) public onlyOwner {
        adminAddr = _admin_addr;
    }

	function setOwesFund(address payable _owes_fund) public onlyOwner {
        owesFund = _owes_fund;
    }

	function setSupplyFund(address payable _supply_fund) public onlyOwner {
        supplyFund = _supply_fund;
    }

	function setSafeFund(address payable _safe_fund) public onlyOwner {
        safeFund = _safe_fund;
    }

	function setEncourageFund(address payable _encourage_fund) public onlyOwner {
        encourageFund = _encourage_fund;
    }

	function _setUpline(address _addr, address _upline) private {
		if (users[_addr].upline == address(0) && _upline != _addr && _addr != supperUpline && (users[_upline].depositTime > 0 || _upline == supperUpline)) {
			users[_addr].upline = _upline;
			users[_upline].referees++;
			emit uplineEvent(_addr, _upline);
			totalUsers++;
			for (uint8 i = 0; i < refBonusScale.length; i++) {
				if (_upline == address(0)) break;
				users[_upline].teams++;
				_upline = users[_upline].upline;
			}
		}
	}

	function _deposit(address _addr, uint256 _amount) private {
		require(users[_addr].upline != address(0) && _addr != supperUpline, "No upline");
        require(users[_addr].depositTime <= 0 || (uint40(block.timestamp) - users[_addr].depositTime) / 1 days >= 10, "Not yet, Deposit already exists");
        
		address __addr = supperUpline;
		if (users[_addr].depositTime > 0) {
			users[_addr].investLast += payoutOfInterest(_addr);

			users[_addr].cycle++;
            require(_amount >= minDeposit && _amount <= maxDeposit + users[_addr].cycle * 5e8 && _amount <= 1e10, "Bad amount 1");
            require(_amount >= users[_addr].depositTop / 2, "Bad amount 2");

            users[_addr].investPayouts += users[_addr].depositAmount;
			users[_addr].payouts = 0;
            if(users[_addr].depositTop < _amount){
                users[_addr].depositTop = _amount; 
            }
		} else {
			require(_amount >= minDeposit && _amount <= maxDeposit, "Bad amount 3");

            users[_addr].payouts = 0;
            users[_addr].depositTop = _amount;
		}
		
        users[_addr].depositAmount = _amount;
        users[_addr].depositPayouts = 0;
        users[_addr].depositTime = uint40(block.timestamp);
        uexts[_addr].totalDeposits += _amount;
		
		totalDeposited += _amount;
		emit depositEvent(_addr, _amount);
		if (users[_addr].upline != address(0)) {
			if(users[users[_addr].upline].depositAmount >=  _amount){
				uexts[users[_addr].upline].directBonus += _amount / 20;
			}else{
				uexts[users[_addr].upline].directBonus += users[users[_addr].upline].depositAmount / 20;
			}
			users[__addr].teamsBonus += _amount;
		}
        
		users[owesFund].teamsBonus += _amount / 200;
		users[supplyFund].teamsBonus += _amount / 200;
		users[safeFund].teamsBonus += _amount / 200;
		users[encourageFund].teamsBonus += _amount / 200;

		if (poolLastDraw + 1 days < uint40(block.timestamp)) {
			_drawPool();
		}
		_pollDeposits(_addr, _amount);

		uint256 adminScale = _amount / 100;
		adminWithdraw += adminScale;

		usdtToken.transferFrom(msg.sender, address(this), _amount);
		usdtToken.transfer(adminAddr, adminScale);
	}


	function _pollDeposits(address _addr, uint256 _amount) private {
		poolBalance += _amount  / 100;

		address upline = users[_addr].upline;
		if (upline == address(0)) return;

		poolUsersRefsDepositsSum[poolCycle][upline] += _amount;
		uint8 poolLen = uint8(poolBonuses.length - 1);

        if(_isPoolTop(upline) == false){
            if (poolTop[poolLen] == upline || poolTop[poolLen] == address(0)){
                poolTop[poolLen] = upline;
            }else{
                if(poolUsersRefsDepositsSum[poolCycle][upline] > poolUsersRefsDepositsSum[poolCycle][poolTop[poolLen]]){
                    poolTop[poolLen] = upline;
                }else{
                    return;
                }
            }
        }

        for (uint8 i = poolLen; i > 0; i--) {
			if(i < 1)return;

			if (poolTop[i - 1] == address(0)) {
                poolTop[i - 1] = poolTop[i];
                poolTop[i] = address(0);
			}else if(poolUsersRefsDepositsSum[poolCycle][poolTop[i]] > poolUsersRefsDepositsSum[poolCycle][poolTop[i - 1]]){
                address tmpAddr = poolTop[i - 1];
                poolTop[i - 1] = poolTop[i];
                poolTop[i] = tmpAddr;
            }
        }
		
	}

    function _isPoolTop(address _addr) private view returns(bool isIn){
        for (uint8 i = 0; i < poolBonuses.length; i++) {
            if(poolTop[i] == _addr){
                return true;
            }
        }
        return false;
    }

	function _drawPool() private {
		poolLastDraw = poolLastDraw + 1 days;
		poolCycle++;

		uint256 draw_amount = poolBalance / 100;
		for (uint8 i = 0; i < poolBonuses.length; i++) {
			if (poolTop[i] == address(0)) break;
			uint256 win = draw_amount * poolBonuses[i];
			users[poolTop[i]].poolBonus += win;
			poolBalance -= win;
			emit poolPayoutEvent(poolTop[i], win);
		}
		for (uint8 i = 0; i < poolBonuses.length; i++) {
			poolTop[i] = address(0);
		}

	}

	function deposit(address _upline, uint256 _amount) payable external {
		_setUpline(msg.sender, _upline);
		_deposit(msg.sender, _amount);
	}
    
	function _refPayout(address _addr, uint256 _amount) private {
		address up = users[_addr].upline;
        uint256 len = refBonusScale.length;

		for (uint8 i = 0; i < len; i++) {
			if (up == address(0)) break;

			if (users[up].referees >= i + 1) {
				uint256 bonus = _amount * refBonusScale[i] / 100;
				users[up].refBonus += bonus;
				emit refPayoutEvent(up, _addr, bonus);
			}
			up = users[up].upline;
		}
	}

	function _teamsPayout(address _addr, uint256 _amount) private {
		address up = users[_addr].upline;
		User memory user;
		uint8 same = 0;

		while (true) {
			if (up == address(0)) break;

			if(users[up].referees >= 20 && users[up].teams >= 400){
				users[up].level = 3;
				if(user.level >= 3 && same == 0){
					same = 1;
					uint256 tbonus = _amount  / 10;
					users[up].teamsBonus += tbonus;
					return;
				}else if(user.level >= 3 && same == 1){
					return;
				}

				uint256 teamsScale = teamsBonusScale[2];
				if(user.level > 0){
					teamsScale -= teamsBonusScale[user.level];
				}
				uint256 bonus = _amount * teamsScale / 100;
				users[up].teamsBonus += bonus;
				user = users[up];
				same = 0;
			}else if(users[up].referees >= 15 && users[up].teams >= 200){
				users[up].level = 2;
				if(user.level == 2 && same == 0){
					same = 1;
					uint256 tbonus = _amount  / 10;
					users[up].teamsBonus += tbonus;
					continue;
				}else if(user.level == 2 && same == 1){
					continue;
				}

				uint256 teamsScale = teamsBonusScale[1];
				if(user.level > 0){
					teamsScale -= teamsBonusScale[user.level];
				}
				uint256 bonus = _amount * teamsScale / 100;
				users[up].teamsBonus += bonus;
				user = users[up];
				same = 0;
			}else if (users[up].referees >= 10 && users[up].teams >= 100) {
				users[up].level = 1;
				if(user.level == 1 && same == 0){
					same = 1;
					uint256 tbonus = _amount  / 10;
					users[up].teamsBonus += tbonus;
					continue;
				}else if(user.level == 1 && same == 1){
					continue;
				}

				uint256 bonus = _amount * teamsBonusScale[0] / 100;
				users[up].teamsBonus += bonus;
				user = users[up];
			}
			up = users[up].upline;
		}
	}

	function withdraw() public payable {
		uint256 interest = payoutOfInterest(msg.sender);
		uint256 max_payout = maxPayoutOf(msg.sender);
		emit logIEvent(msg.sender, max_payout);
		require(max_payout > 0, "Zero payout");
		require(usdtToken.balanceOf(address(this)) > 0, "Zero balance");
		if( max_payout > usdtToken.balanceOf(address(this))){
			max_payout = usdtToken.balanceOf(address(this));
		}
		emit logIEvent(msg.sender, max_payout);
		totalWithdraw += max_payout;

		uexts[msg.sender].totalPayouts += max_payout;
		users[msg.sender].depositPayouts += max_payout;
		users[msg.sender].payouts += interest;
		users[msg.sender].refBonus = 0;
		users[msg.sender].poolBonus = 0;
		users[msg.sender].teamsBonus = 0;
		users[msg.sender].investPayouts = 0;
		users[msg.sender].investLast = 0;
		uexts[msg.sender].directBonus = 0;
		
		if(interest > 0){
			_refPayout(msg.sender, interest);
			
			_teamsPayout(msg.sender, interest);
		}

		usdtToken.transfer(msg.sender, max_payout);
		emit withdrawEvent(msg.sender, max_payout);
		
	}


	function maxPayoutOf(address _addr) view private returns(uint256 payout) {
		uint256 amount = payoutOfInterest(_addr) + users[_addr].investLast + users[_addr].investPayouts + users[_addr].teamsBonus + users[_addr].poolBonus + users[_addr].refBonus + uexts[_addr].directBonus;
		return amount;
	}

	function maxPayoutOfNow(address _addr) view external returns(uint256 payout, uint256 payoutInterestTop) {
		payoutInterestTop = payoutOfInterest(_addr);
		uint256 amount = payoutOfInterest(_addr) + users[_addr].investLast + users[_addr].investPayouts + users[_addr].teamsBonus + users[_addr].poolBonus + users[_addr].refBonus + uexts[_addr].directBonus;
		return (amount, payoutInterestTop);
	}

	function payoutOfInterest(address _addr) view private returns(uint256 payout) {
		if(users[_addr].depositTime <= 0){
			return 0;
		}
		uint256 day = (uint40(block.timestamp) - users[_addr].depositTime) / 1 days;
		if (day > 10) {
			day = 10;
		}

		uint256 scale = 15 - users[_addr].cycle;
		if(scale <= 10){
			scale = 10;
		}

		payout = users[_addr].depositAmount * day / 1000 * scale - users[_addr].payouts;
		return payout;
	}
	
	
	function userInfo(address _addr) view external returns(address upline, uint40 depositTime, uint256 depositAmount, uint256 depositTop, uint256 investPayouts, uint256 depositPayouts, uint256 directBonus) {
		return (users[_addr].upline, users[_addr].depositTime, users[_addr].depositAmount, users[_addr].depositTop, users[_addr].investPayouts, users[_addr].depositPayouts, uexts[_addr].directBonus);
	}
	function userInfoBonus(address _addr) view external returns( uint256 refBonus, uint256 poolBonus, uint256 teamsBonus) {
		return (users[_addr].refBonus, users[_addr].poolBonus, users[_addr].teamsBonus);
	}
	function userInfoTotals(address _addr) view external returns(uint16 cycle, uint16 referees, uint256 totalDeposits, uint256 totalPayouts, uint256 teams, uint256 depositDay) {
		uint256 day = (uint40(block.timestamp) - users[_addr].depositTime) / 1 days;
		return (users[_addr].cycle, users[_addr].referees, uexts[_addr].totalDeposits, uexts[_addr].totalPayouts, users[_addr].teams, day);
	}
	function contractInfo() view external returns(uint256 rtotalUsers, uint256 rtotalDeposited, uint256 rtotalWithdraw, uint40 rpoolLastDraw, uint256 rpoolBalance, uint256 radminWithdraw, uint256 toketBalance, uint256 safeFunds) {
		uint256 teamBonus = users[safeFund].teamsBonus;
		return (totalUsers, totalDeposited, totalWithdraw, poolLastDraw, poolBalance, adminWithdraw, usdtToken.balanceOf(address(this)), teamBonus);
	}
	function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
		for (uint8 i = 0; i < poolBonuses.length; i++) {
			if (poolTop[i] == address(0)) break;
			addrs[i] = poolTop[i];
			deps[i] = poolUsersRefsDepositsSum[poolCycle][poolTop[i]];
		}
	}

}