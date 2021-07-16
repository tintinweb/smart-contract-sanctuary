//SourceUnit: LEX.sol

pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

contract TRC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract LEX is TRC20Interface {
	using SafeMath for uint256;
	
    string public constant NAME = "LightExchangeToken";
    string public constant SYMBOL = "LEX";
	uint256 public decimals = 6;	

	uint256 public maximumTokens = 1e14; //100M TOKENS
	uint256 private constant preSellPrice = 10; //1 TOKEN = 10 TRX
	uint256 private constant preSellTime1 = 1575903600; //50% discont from 12/09/2019 @ 3:00pm (UTC)
	uint256 private constant preSellTime2 = 1578582000; //37% discont from 01/09/2020 @ 3:00pm (UTC)
	uint256 private constant preSellTime3 = 1581260400; //16% discont from 02/09/2020 @ 3:00pm (UTC)
	uint256 private constant preSellLimit1 = 22e11; //2.2M TOKENS
	uint256 private constant preSellLimit2 = 16e11; //1.6M TOKENS
	uint256 private constant preSellLimit3 = 12e11; //1.2M TOKENS
	uint256 public totalPreSelled;
	
	//dividends
	uint256 private dividendsPerToken;	
	uint256 private totalDividendsPayed;
	uint256 public totalDividends;
	
	//frozen dividends
	uint256 public totalFrozenTokens;
	uint256 private unfreezeDate = 1584630000; //03/19/2020 @ 3:00pm (UTC)

	uint256 gamesCount;
    mapping (uint256 => address) private games;
    mapping (address => uint256) public dividendStat;
    mapping (address => uint256) private heldDividends;
    mapping (address => uint256) public frozenTokens;
    mapping (address => uint256) private dividendsToPay;
	
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;	
	
    address public contractOwner;
    address public marketing;	
    address public developing;	
	
    event ContractOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
    constructor(address _marketing, address _developing) public {
        contractOwner = msg.sender;
        marketing = _marketing;
        developing = _developing;
		
		_mint(contractOwner, 3e12); 
		frozenTokens[contractOwner] = 3e12;		

		_mint(marketing, 3e12); 
		frozenTokens[marketing] = 3e12;		
		
		_mint(developing, 4e12); 
		frozenTokens[developing] = 4e12;		

		totalFrozenTokens = totalFrozenTokens.add(10e12);		
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    function transferContractOwnership(address _newOwner) public onlyContractOwner {
        require(_newOwner != address(0));
        emit ContractOwnershipTransferred(contractOwner, _newOwner);
        contractOwner = _newOwner;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
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
		
		updateDividends(sender);
		updateDividends(recipient);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
		

		if (frozenTokens[sender] >= amount) {
			frozenTokens[sender] = frozenTokens[sender].sub(amount);
			totalFrozenTokens = totalFrozenTokens.sub(amount);
		} else if (frozenTokens[sender] > 0) {
			totalFrozenTokens = totalFrozenTokens.sub(frozenTokens[sender]);
			frozenTokens[sender] = 0;
		}
		if (now < unfreezeDate) {
			frozenTokens[recipient] = frozenTokens[recipient].add(amount);
			totalFrozenTokens = totalFrozenTokens.add(amount);
		}
		
		
		holdDividends(sender);
		holdDividends(recipient);
		
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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
	
    function name() public pure returns(string) { 
        return NAME;
    }

    function symbol() public pure returns(string) { 
        return SYMBOL;
    }	
	//end TRC20	functions
	
    function() public payable { 
        preSell();
    }
	
	function preSell() public payable {
		uint256 tokensToBuyValue;
		
		if (now < preSellTime1) {
			revert("Too early...");
		} else if (now >= preSellTime1 && now< preSellTime2) {
		   //50% discont
		   require (totalPreSelled < preSellLimit1, "Pre-sell one is finished, wait for pre-sell two.");
		   tokensToBuyValue = msg.value.mul(100).div(50).div(preSellPrice);
		   require (totalPreSelled + tokensToBuyValue <= preSellLimit1, "Pre-sell limit exceeded");
		   
		} else if (now >= preSellTime2 && now< preSellTime3) {
			//37% discont
		   require (totalPreSelled < preSellLimit1 + preSellLimit2, "Pre-sell two is finished, wait for pre-sell three.");
		   tokensToBuyValue = msg.value.mul(100).div(63).div(preSellPrice);
		   require (totalPreSelled + tokensToBuyValue <= preSellLimit1 + preSellLimit2, "Pre-sell limit exceeded");			
			
		} else {
			//16% discont
		   require (totalPreSelled < preSellLimit1 + preSellLimit2 + preSellLimit3, "Pre-sell is finished");
		   tokensToBuyValue = msg.value.mul(100).div(84).div(preSellPrice);
		   require (totalPreSelled + tokensToBuyValue <= preSellLimit1 + preSellLimit2 + preSellLimit3, "Pre-sell limit exceeded");					
		}
		if (tokensToBuyValue > 0) {
			updateDividends(msg.sender);
			_mint(msg.sender, tokensToBuyValue);
			totalPreSelled = totalPreSelled.add(tokensToBuyValue);
			if (now < unfreezeDate) {
				frozenTokens[msg.sender] = frozenTokens[msg.sender].add(tokensToBuyValue);
				totalFrozenTokens = totalFrozenTokens.add(tokensToBuyValue);
			}			
			holdDividends(msg.sender);
		}
	}
	
	function WithdrawPreSell(uint256 _value, bool _safeDivs) external onlyContractOwner {
		uint256 toPayValue = _value;
        if (_safeDivs) {
			uint256 maxValue = address(this).balance.add(totalDividendsPayed).sub(totalDividends);
			if (toPayValue > maxValue) {
				toPayValue = maxValue;
			}
		}
		contractOwner.transfer(toPayValue.mul(333).div(1000));
		marketing.transfer(toPayValue.mul(333).div(1000));
		developing.transfer(toPayValue.mul(333).div(1000));
	}	

	function burnTokens(uint256 _value) external {	
		require (_value>0 && _value<=_balances[msg.sender],"Wrong burn value");
		updateDividends(msg.sender);
		if (frozenTokens[msg.sender] >= _value) {
			frozenTokens[msg.sender] = frozenTokens[msg.sender].sub(_value);
			totalFrozenTokens = totalFrozenTokens.sub(_value);
		} else if (frozenTokens[msg.sender] > 0) {
			totalFrozenTokens = totalFrozenTokens.sub(frozenTokens[msg.sender]);
			frozenTokens[msg.sender] = 0;
		}
		_burn(msg.sender, _value);
		holdDividends(msg.sender);
	}
	
	function emission(address account, uint256 trxValue) external {
		require (isGame(msg.sender), "Access denied");
		
		uint256 subNum = _totalSupply;
		if (subNum < maximumTokens.mul(15).div(100)) {
			subNum = maximumTokens.mul(15).div(100);
		}
		uint256 minedTokens = trxValue.div(765).mul(maximumTokens.sub(subNum)).div(maximumTokens);

		if (minedTokens > 0) {
			updateDividends(account);
			_mint(account, minedTokens);
			holdDividends(account);
		}
	}

	function riseDividends() external payable {
		dividendsPerToken = dividendsPerToken.add(msg.value.mul(1e6).div(_totalSupply.sub(totalFrozenTokens)));
		totalDividends = totalDividends.add(msg.value);
	}
	
	function getDividends() public {
		updateDividends(msg.sender);
		if (dividendsToPay[msg.sender]>0) {
			msg.sender.transfer(dividendsToPay[msg.sender]);
			totalDividendsPayed = totalDividendsPayed.add(dividendsToPay[msg.sender]);
			dividendStat[msg.sender] = totalDividendsPayed.add(dividendsToPay[msg.sender]);
			dividendsToPay[msg.sender] = 0;
		}			
	}
	
	function unfreezeTokens() external {
		require (msg.sender != contractOwner && msg.sender != marketing && msg.sender != developing, "It isn't for admins");
		require (now >= unfreezeDate, "It isn't time for unfreeze");

		updateDividends(msg.sender);
		totalFrozenTokens = totalFrozenTokens.sub(frozenTokens[msg.sender]);
		frozenTokens[msg.sender] = 0;
		holdDividends(msg.sender);
	}	
	
	function addGame(address game) external onlyContractOwner {
		games[gamesCount] = game;
		gamesCount++;
	}	
	
	function holdDividends(address account) private {
		heldDividends[account] = _balances[account].sub(frozenTokens[account]).mul(dividendsPerToken).div(1e6);
	}
	
	function updateDividends(address account) private {
		uint256 divs = getDividendsValue(account);
		dividendsToPay[account] = dividendsToPay[account].add(divs);
		holdDividends(account);
	}
	
	function getDividendsValue(address account) private view returns(uint256) {
		uint256 divs = _balances[account].sub(frozenTokens[account]).mul(dividendsPerToken).div(1e6);
		if (divs > heldDividends[account]) {
			return divs.sub(heldDividends[account]);
		}
		return 0;
	}
	
	function getDividendsToPay(address account) public view returns(uint256) {
		return getDividendsValue(account) + dividendsToPay[account];
	}	
	
	
	function isGame(address game) private view returns(bool){
		for (uint256 i=0; i<gamesCount; i++) {
			if (games[i] == game) {
				return true;
			}
		}
		return false;
	}	
	
}