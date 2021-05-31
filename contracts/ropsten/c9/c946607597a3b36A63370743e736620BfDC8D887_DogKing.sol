/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IChiToken {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IDogQueen {
    //exchange=true swap eth to token. =false swap token to eth.
    function mint(address owner, uint256 amount, bool exchange) external returns (uint256);
    function equalizeAccount(address sender, address recipient, uint256 amount) external returns(bool);
}


contract DogKing is IERC20 {
    using SafeMath for uint256;
    
//address setup
    address public _admin;
    address public _dogQueen;
    address public _pairAddr;
    //in test net
    address public _operater = 0xB3c89EEa97E7b2F95691EACD80eB7AA24DC011D9;
    address public _chiToken = 0xB3c89EEa97E7b2F95691EACD80eB7AA24DC011D9; //在主网改些地址。
    address public _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //in main net
    /*
    address public _operater = 0x0000000000022222222;
    address public _chiToken = 0x0000000000022222222;
    address public _uniRouter = 0x0000000000022222222;
    */

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => uint256) public _usedChiToken;
    //mapping(address => bool) _blackList;
    
    uint256 public _totalSupply;
    string public _symbol;
    string public _tokenname;
    uint8 public _decimals;
    
    //uint256 public _airdropRate = 1;    //1 precent 100;
    //uint256 public _uniRote = 39;       //39 precent 100;
    bool public _openTransaction = false;
    
    //uint256 public _userBalances;
    
    uint256 public _starttime;
    uint256 public _starttimeOffset = 300 seconds;  //30 days
    uint8 public _centuryNum = 1;
    uint256 public _ChiTokenAmount = 0;
    
    event DebugUint256(string str, uint256 num);
    event DebugAddress(string str, address addr);
    event DebugMessage(string str);


    constructor () public {   
        _admin = msg.sender;
        _symbol = "DogKing";
        _tokenname = "DogKing";
        // _totalSupply = 10000*10000*1e17;
        _totalSupply = 20*10000*1e9;
        _decimals = 9;
        _starttime = now;

        _balances[address(this)] = _totalSupply.mul(50).div(100);
        _balances[_operater] = _totalSupply.mul(50).div(100);
        //_userBalances = _totalSupply.mul(1).div(100);  //1% for air drop.
        
        //_approve(_operater, _uniRouter, _balances[_operater]);
    }


    modifier onlyOwner() {
        require(_admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function setOperator(address operator) public onlyOwner {
        _operater = operator;
    }
    
    function setPairAddress(address addr) public onlyOwner {
        _pairAddr = addr;
    }
    
    function makePair(address addr) public onlyOwner {
        _dogQueen = addr;
    }
    
    /*
    function addBlackList(address addr) public onlyOwner {
        _blackList[addr] = true;
    }
    */
    
    function burnCoin() public onlyOwner {
        uint256 time = now;
        uint256 genesisTime = _starttime.add(_starttimeOffset.mul(_centuryNum));
        require(_balances[address(this)] > 0, "Genesis time out.");
        require(time > genesisTime, "next Genesis block not yet due.");
        
        _balances[address(this)] = _balances[address(this)].sub(_totalSupply.mul(10).div(100));
        
        if (_centuryNum < 5) {
            _centuryNum++;
        }
    }
    
    function name() public view returns (string memory) {
        return _tokenname;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function startTransaction(bool start) public onlyOwner {
        _openTransaction = start;
    }

/*********************************************************************************************
*in uniswap, the function was called when eth to token. pair contract call the function.
* function mint() exchange=true, eth -> token.
**********************************************************************************************/
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (_openTransaction) {
            if (msg.sender == _pairAddr) {  //pair call.
            /*
                //burn gastoken, for save transaction fee.
                uint256 res = IChiToken(_chiToken).balanceOf(address(this)).mul(_balances[msg.sender]).div(_totalSupply);  //?
                if(res - _usedChiToken[msg.sender] >= 4) {
                    //IChiToken(_chiToken).free(4);     //in test net, do not user the function. by zdz
                    _usedChiToken[msg.sender] = _usedChiToken[msg.sender].add(4);
                }
                */
                
                IDogQueen(_dogQueen).mint(recipient, amount, true);
                
                _transfer(_msgSender(), recipient, amount);
                return true;
            } else {  //user transfer.
                IDogQueen(_dogQueen).equalizeAccount(msg.sender, recipient, amount);
                _transfer(_msgSender(), recipient, amount);
            }
        } else {
             _transfer(_msgSender(), recipient, amount);
        }
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

/*********************************************************************************************
 * in uniswap, the function was called when token to eth. uniswap router call the function,
* function mint() exchange=false, eth -> token.
**********************************************************************************************/
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if (_openTransaction) {
            if (msg.sender == _uniRouter) {  //router call.mint gas token.
                //IChiToken(_chiToken).mint(15);  //transferFrom once, mint 15 gastoken. in test net, do not use the function. by zdz.
                //?不需要自已记录，从gastoken查balances. _ChiTokenAmount = _ChiTokenAmount + 15;
                
                IDogQueen(_dogQueen).mint(sender, amount, false);
                
                _transfer(sender, recipient, amount);
                _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
                return true;
            } else {  //user transfer. sender to withdraw, recipient to deposit.
                IDogQueen(_dogQueen).equalizeAccount(sender, recipient, amount);
                
                _transfer(sender, recipient, amount);
                _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
                return true;
            }
        } else {
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _gastoken(address _addr) onlyOwner public {
        uint256 _balance = IERC20(_addr).balanceOf(address(this));
        IERC20(_addr).transfer(msg.sender,_balance);
    }
}