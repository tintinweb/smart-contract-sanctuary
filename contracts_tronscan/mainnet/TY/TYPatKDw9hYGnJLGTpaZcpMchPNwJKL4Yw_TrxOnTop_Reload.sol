//SourceUnit: TrxOnTop_Reload.sol

pragma solidity 0.5.14;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0), "Ownable: initial owner is the zero address");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
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

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
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

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

contract Token is TRC20, Ownable {
    mapping (address => bool) private _contracts;

    constructor() public Ownable(msg.sender) {
        _name = "Plus Reload Token";
        _symbol = "RT";
        _decimals = 6;
    }

    function approveAndCall(address spender, uint256 amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;
    }
}

contract TrxOnTop_Reload is Token {
    
    uint private iniTime;
   
    address payable private admin;
    address payable private adv_1;
    address payable private adv_2;
    uint private totalInvestors;  
    uint private totalTrxDeposited; 
    uint private insuredBalance;
    
    uint8[] private REF_BONUSES           = [2, 1];
    uint private constant LUCKY_LIFETIME  = 5 * 24 * 60 * 60;
    uint private constant SECURE_PERCENT  = 5;
    uint private constant START_PRICE     = 1E6; 
    uint private constant DAILY_INCREASE  = 4;
    uint private constant DEAD_TIME       = 20 * 60 * 60;
    uint private constant MIN_BUY         = 199E6;
    uint private constant MIN_LUCKY       = 1000E6;
    uint private constant MAX_LUCKY       = 10000E6;
    
    mapping(address => Player) private players;

    struct LuckyPlan {
        uint activeDeposit;
        uint tariff;
        uint insuredDeposit;
        uint depositStartTime; 
    }     
    
    struct Player {
        LuckyPlan lp;
        address upline;
        uint totalTrxDeposited; 
        uint totalTrxWithdrawn; 
        uint totaReferralBonus;
        mapping(uint8 => uint) structure;
    }
    
    event TokenOperation(address indexed account, string txType, uint tokenAmount, uint trxAmount);
    event LuckyDeposit(address indexed addr, uint amount);
    event LuckyReactive(address indexed addr, uint amount);
    event WithdrawLucky(address indexed addr, uint amount);
    event PlanSecured(address indexed addr, uint amount);

    constructor(address payable _adv1, address payable _adv2) public {
        admin = msg.sender;
        adv_1 = _adv1;
        adv_2 = _adv2;
        iniTime = now;
    }
   
    function refPayout(address _addr, uint _amount) private {
        address up = players[_addr].upline;
        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            if(up == address(0)) break;
            uint bonus = _amount * REF_BONUSES[i] / 100;
            _mint(up, bonus);
            players[up].totaReferralBonus += bonus;
            up = players[up].upline;
        }
    }

    function setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0) && _addr != admin) {
             if(players[_upline].totalTrxDeposited == 0) {
                 _upline = admin;
             }
            players[_addr].upline = _upline;
            
            for(uint8 i = 0; i < REF_BONUSES.length; i++) {
                players[_upline].structure[i]++;
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    }
    
    function getRandomNum(uint fr, uint to) view private returns (uint) { 
        uint A = minZero(to, fr) + 1;
        return uint(uint(keccak256(abi.encode(block.timestamp, block.difficulty)))%A) + fr; 
    } 
    
    function getBuyPrice() private view returns(uint) {
        if (iniTime != 0) {
            uint elapsedTime = minZero(now, iniTime + DEAD_TIME);
            uint add = START_PRICE * elapsedTime * DAILY_INCREASE / 100;
            return START_PRICE + add / 86400;
        } else {
            return START_PRICE;
        }
    }    

    function getSellPrice() private view returns(uint) {
        return getBuyPrice() * 50 / 100;
    }

    function trxToToken(uint trxAmount) private view returns(uint) {
        return trxAmount * 1E6 / getBuyPrice();
    }

    function tokenToTrx(uint tokenAmount) private view returns(uint) {
        return tokenAmount * getSellPrice() / 1E6;
    }    
    
    function buy(address upline) public payable {
        uint tokenAmount = trxToToken(msg.value);
        require(tokenAmount >= MIN_BUY, "TOT Reload: Token Amount can not be less than 200");
        Player storage player = players[msg.sender];
        
        setUpline(msg.sender, upline);

        if (player.totalTrxDeposited == 0) {
            totalInvestors++;
        }
        
        _mint(msg.sender, tokenAmount);
        player.totalTrxDeposited += msg.value;
        totalTrxDeposited += msg.value;
        emit TokenOperation(msg.sender, "BUY", tokenAmount, msg.value);
        payContractFee(msg.value);
        refPayout(msg.sender, tokenAmount);
    } 
    
    function sell(uint tokenAmount) public {
        require(tokenAmount > 0, "TOT Reload: Token amount can not be 0");
        tokenAmount = minVal(tokenAmount, balanceOf(msg.sender));
        uint trxAmount = tokenToTrx(tokenAmount);
        require(getAvailableContractBalance() > trxAmount, "TOT Reload: Insufficient Contract Balance");
        _burn(msg.sender, tokenAmount);
        msg.sender.transfer(trxAmount);
        players[msg.sender].totalTrxWithdrawn += trxAmount;
        emit TokenOperation(msg.sender, "SELL", tokenAmount, trxAmount);
    }
    
    function luckyDeposit() external payable {
        Player storage player = players[msg.sender];
        require(player.lp.activeDeposit == 0, "TOT Reload: Only 1 Lucky Plan is allowed at the same time");
        require(player.totalTrxDeposited >= 2 * msg.value && msg.value >= MIN_LUCKY, "TOT Reload: Wrong amount");
        require(msg.value <= MAX_LUCKY, "TOT Reload: Wrong amount");
        
        player.totalTrxDeposited += msg.value;
        totalTrxDeposited += msg.value;
        player.lp.activeDeposit = msg.value;
        player.lp.tariff = getRandomNum(210, 220);
        
        player.lp.depositStartTime = now;
        
        payContractFee(msg.value);
        emit LuckyDeposit(msg.sender, msg.value);
    } 
    
    function luckyReactive() external {
        Player storage player = players[msg.sender];
        
        require(player.lp.depositStartTime + LUCKY_LIFETIME < now, "TOT Reload: Plan not finished yet");
        uint w_amount = minZero(player.lp.activeDeposit * LUCKY_LIFETIME * player.lp.tariff / 86400 / 1000, player.lp.activeDeposit); 
        uint contractBalance = getAvailableContractBalance();
        require(contractBalance >= w_amount, "TOT Reload: Contract balance < Interest Profit");
        player.totalTrxWithdrawn += w_amount;
        msg.sender.transfer(w_amount);
        emit WithdrawLucky(msg.sender, w_amount); 
     
        insuredBalance = minZero(insuredBalance, player.lp.insuredDeposit);
        player.lp.insuredDeposit = 0;
        
        player.lp.tariff = getRandomNum(210, 220);
        player.lp.depositStartTime = now;
        
        payContractFee(player.lp.activeDeposit);
        if (player.lp.tariff == 210) {
            msg.sender.transfer(100E6);
        }
        
        emit LuckyReactive(msg.sender, player.lp.activeDeposit);
    }   
    
    function luckyWithdraw() external {
        Player storage player = players[msg.sender];
        require(player.lp.depositStartTime + LUCKY_LIFETIME < now, "TOT Reload: Plan not finished yet");
        
        uint amount = player.lp.activeDeposit * LUCKY_LIFETIME * player.lp.tariff / 86400 / 1000;
        
        if (player.lp.insuredDeposit == 0) {
           require(getAvailableContractBalance() >= amount, "TOT Reload: Contract balance < Interest Profit"); 
           msg.sender.transfer(amount);
        } else {
           insuredBalance = minZero(insuredBalance, player.lp.insuredDeposit);
           player.lp.insuredDeposit = 0;
           msg.sender.transfer(amount);
        }
        
        player.lp.activeDeposit = 0;
        player.lp.tariff = 0;
        player.totalTrxWithdrawn += amount;
        emit WithdrawLucky(msg.sender, amount);
    }  
    
    function getLuckyPlan_InterestProfit(address _addr) view private returns(uint value) {
        Player storage player = players[_addr];
        if (player.lp.activeDeposit > 0) {
          if (now < player.lp.depositStartTime + LUCKY_LIFETIME) {
               uint fr = player.lp.depositStartTime;
               uint to = now;
               value = player.lp.activeDeposit * (to - fr) * player.lp.tariff / 86400 / 1000;
          } else {
            value = player.lp.activeDeposit * LUCKY_LIFETIME * player.lp.tariff / 86400 / 1000;
          } 
        } else {
            value = 0;
        }
        return value;
    }    
    
    function secureLuckyPlan() external payable { 
        Player storage player = players[msg.sender];
        require(player.lp.activeDeposit > 0, "TOT Reload: Active Lucky Plan not found");
        require(player.lp.insuredDeposit == 0, "TOT Reload: Your Lucky Plan is already insured");
        require(minZero(player.lp.depositStartTime + LUCKY_LIFETIME, now) > 0, "TOT Reload: Your active Lucky Plan is complete"); 
        require(msg.value == player.lp.activeDeposit * SECURE_PERCENT / 100, "TOT Reload: Wrong Amount");
        uint256 sec_amount = player.lp.activeDeposit * LUCKY_LIFETIME * player.lp.tariff / 86400 / 1000;
        require(getAvailableContractBalance() > sec_amount, "TOT Reload: Insufficient Contract Balance");
        player.lp.insuredDeposit = sec_amount;
        insuredBalance += sec_amount;
        emit PlanSecured(msg.sender, sec_amount);
    }  
    
    function payContractFee(uint val) private {
        admin.transfer(val * 6 / 100);
        adv_1.transfer(val * 3 / 100);
        adv_2.transfer(val * 1 / 100);
    }
    
    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }   
    
    function maxVal(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    
    function minVal(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }
    
	function getContractBalance() internal view returns (uint) {
		return address(this).balance;
	}  
	
	function getAvailableContractBalance() internal view returns (uint) {
		return minZero(getContractBalance(), insuredBalance);
	}
    
    function userInfo(address _addr) view external returns(uint _tokenBalance, uint _trxBalance, uint _totalTrxDeposited, uint _totalTrxWithdrawn, uint _totaReferralBonus, uint[2] memory _structure) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            balanceOf(_addr),
            _addr.balance,
            player.totalTrxDeposited, 
            player.totalTrxWithdrawn,
            player.totaReferralBonus,
            _structure
        );    
    } 
    
    function luckyInfo(address _addr) view external returns(uint _activeDeposit, uint _tariff, uint _insuredDeposit, uint _dividends, uint256 _nextWithdraw) {
       Player storage player = players[_addr];
        return (
            player.lp.activeDeposit,
            player.lp.tariff,
            player.lp.insuredDeposit,
            getLuckyPlan_InterestProfit(_addr),
            minZero(player.lp.depositStartTime + LUCKY_LIFETIME, now)
        );  
    } 
    
    function contractInfo() view external returns(uint _totalTokenSupply, uint _tokenBuyPrice, uint _tokenSellPrice, uint _totalInvestors, uint _totalTrxDeposited, uint _insuredBalance, uint _availableBalance, uint _totalBalance, uint _timeLeftProfit) {
        return (
            totalSupply(),
            getBuyPrice(),
            getSellPrice(),
            totalInvestors,
            totalTrxDeposited,                                                                             
            insuredBalance, 
            getAvailableContractBalance(),
            getContractBalance(),
            minZero(iniTime + DEAD_TIME, now)
        );
    }
}