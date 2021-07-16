//SourceUnit: TronOwls3.sol

pragma solidity ^0.4.25;

contract JustOwls {

    using SafeMath for uint256;
	
	string public name = 'JustOwlsToken';
	string public symbol = 'JOWL';
	uint public decimals = 6;	
	
	uint constant TO_SUN = 1000000; //Precision divider
	uint constant PERIOD = 30 days; 
	
    uint[5] owlsPrices = [100, 532, 1500, 5000, 15000]; //JOWL price
    uint[5] magicIncome = [120, 124, 128, 132, 136]; //% per 30 days

    uint public totalPlayers;
    uint public totalOwls;

    struct lastInvestor {
		address investor;
        uint time;
        uint value;
    }	

	lastInvestor[5] public lastFiveInvestors; 
    mapping(address => uint) public lastInvestorProfit;
    mapping(address => uint) public investorProfit;	
	
    struct Player {
        uint time;
		address referrer;
        uint[5] owls;
    }
	
    mapping(address => Player) public players;

    address administration;	
	
    constructor() public {
        administration = msg.sender;
		_mint(msg.sender, 2000000000000); //pre-sell limit 2000000 JOWL
    }
	
	//TRC20
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed admin, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].add(getMagicProfit(account));
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
		collectMagic(recipient);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address admin, address spender) public view returns (uint256) {
        return _allowances[admin][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
		collectMagic(sender);
		collectMagic(recipient);
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
		investorProfit[account] = investorProfit[account].add(amount);
		
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address admin, address spender, uint256 value) internal {
        require(admin != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[admin][spender] = value;
        emit Approval(admin, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }	
	//end TRC20
	
    function buyForMagic(uint _owl, uint _number, address _referrer) public {
        require(_owl >= 0 && _owl <= 4 && _number > 0);
		
		uint owlsMagicPrice = owlsPrices[_owl].mul(_number).mul(TO_SUN);
		
        Player storage player = players[msg.sender];

        if (player.time > 0) {
			collectMagic(msg.sender);		
		} else {
			if (_referrer != address(0)) {
				player.referrer = _referrer;
			}
			player.time = now;
			totalPlayers++;
		}
		
		if (owlsMagicPrice >= 5000000000) { //5000 JOWL
			addLastInvestor(msg.sender,owlsMagicPrice);
		}		
			
        player.owls[_owl] = player.owls[_owl].add(_number);
		_burn(msg.sender, owlsMagicPrice);
		_mint(administration, owlsMagicPrice.div(10)); //10% administration fee
		
        totalOwls = totalOwls.add(_number);		
    }		
	
	function addLastInvestor(address _addr, uint _value) internal {
		lastInvestor storage investor;
		lastInvestor storage investorPrev;
		collectMagicBonus();
		for (uint i = 4; i >= 1; i--) {
			investor = lastFiveInvestors[i];
			investorPrev = lastFiveInvestors[i-1];
			investor.investor = investorPrev.investor;
			investor.time = now;
			investor.value = investorPrev.value;
		}
		investor = lastFiveInvestors[0];
		investor.investor = _addr;
        investor.time = now;
        investor.value = _value;
	}
	
	function collectMagicBonus() internal {	
		lastInvestor storage investor;
		uint profit;
		for (uint i = 0; i <= 4; i++) {
			investor = lastFiveInvestors[i];
			if (investor.value > 0) {
				//3% per day
				profit = investor.value.mul( now.sub(investor.time) ).mul(3).div(1 days).div(100);	
				_mint(investor.investor, profit);
				//safe stat
				lastInvestorProfit[investor.investor] = lastInvestorProfit[investor.investor].add(profit);  
			}
		}
	}

    function collectMagic(address _addr) public {
        Player storage player = players[_addr];
		if (player.time > 0) {			
			uint profit = getMagicProfit(_addr);

			address referrer = player.referrer;
			if (referrer != address(0)) {
				_mint(referrer, profit.mul(5).div(100)); //5% to refferer
			}
			
			_mint(_addr, profit);
			player.time = now;
		}
    }	
		
	function getMagicProfit(address _addr) public view returns(uint){
		uint profit;
		if (players[_addr].time > 0) {
			for (uint i = 0; i <= 4; i++) {
				profit = profit.add( players[_addr].owls[i].mul(owlsPrices[i]).mul(magicIncome[i]).mul(TO_SUN) );
			}
			profit = profit.mul( now.sub(players[_addr].time) ).div(PERIOD).div(100);	
		}
		return profit;
	}
	
    function owlsOf(address _addr) public view returns (uint[5]) {
        return players[_addr].owls;
    }	
	
}
	

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}