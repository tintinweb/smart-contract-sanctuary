/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

pragma solidity 0.5.8;

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

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
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

contract Token is ERC20 {
    mapping (address => bool) private _contracts;

    constructor() public {
        _name = "Matic Token";
        _symbol = "MT";
        _decimals = 18;
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

contract Contract_Token_01 is Token {
    
    uint private iniTime;
   
    address payable private admin;
    address payable private adv_1;
    address payable private adv_2;
    uint private totalUsers; 
    uint private totalDeposited; 
    
    uint8[] private REF_BONUSES           = [2, 1];
    uint private constant START_PRICE     = 1 ether; 
    uint private constant DAILY_INCREASE  = 4;
    uint private constant DEAD_TIME       = 20 * 60 * 60;
    uint private constant MIN_BUY         = 5 ether;

    
    mapping(address => Player) private players;
    
    struct Player {
        address upline;
        uint totalDeposited; 
        uint totalWithdrawn; 
        uint totaReferralBonus;
        mapping(uint8 => uint) structure;
    }
    
    event TokenOperation(address indexed account, string txType, uint tokenAmount, uint trxAmount);

    constructor() public {
        admin = msg.sender;
        adv_1 = msg.sender;
        adv_2 = msg.sender;
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
             if(players[_upline].totalDeposited == 0) {
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

    function maticToToken(uint maticAmount) private view returns(uint) {
        return maticAmount * 1e18 / getBuyPrice();
    }

    function tokenToMatic(uint tokenAmount) private view returns(uint) {
        return tokenAmount * getSellPrice() / 1e18;
    }    
    
    function buy(address upline) public payable {
        uint tokenAmount = maticToToken(msg.value);
        require(tokenAmount >= MIN_BUY, "TOT Reload: Token Amount can not be less than 200");
        Player storage player = players[msg.sender];
        
        setUpline(msg.sender, upline);

        if (player.totalDeposited == 0) {
            totalUsers++;
        }
        
        _mint(msg.sender, tokenAmount);
        player.totalDeposited += msg.value;
        totalDeposited += msg.value;
        emit TokenOperation(msg.sender, "BUY", tokenAmount, msg.value);
        payContractFee(msg.value);
        refPayout(msg.sender, tokenAmount);
    } 
    
    function sell(uint tokenAmount) public {
        require(tokenAmount > 0, "TOT Reload: Token amount can not be 0");
        tokenAmount = minVal(tokenAmount, balanceOf(msg.sender));
        uint trxAmount = tokenToMatic(tokenAmount);
        require(getContractBalance() > trxAmount, "TOT Reload: Insufficient Contract Balance");
        _burn(msg.sender, tokenAmount);
        msg.sender.transfer(trxAmount);
        players[msg.sender].totalWithdrawn += trxAmount;
        emit TokenOperation(msg.sender, "SELL", tokenAmount, trxAmount);
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
    
    function userInfo(address _addr) view external returns(uint _tokenBalance, uint _trxBalance, uint _totalTrxDeposited, uint _totalTrxWithdrawn, uint _totaReferralBonus, uint[2] memory _structure) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            balanceOf(_addr),
            _addr.balance,
            player.totalDeposited, 
            player.totalWithdrawn,
            player.totaReferralBonus,
            _structure
        );    
    } 
    
    function contractInfo() view external returns(uint _totalTokenSupply, uint _tokenBuyPrice, uint _tokenSellPrice, uint _totalInvestors, uint _totalTrxDeposited, uint _totalBalance, uint _timeLeftProfit) {
        return (
            totalSupply(),
            getBuyPrice(),
            getSellPrice(),
            totalUsers,
            totalDeposited,                                                                             
            getContractBalance(),
            minZero(iniTime + DEAD_TIME, now)
        );
    }
}