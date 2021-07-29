/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event fundTransfer(address indexed from, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    address public founder1;
    address public founder2;
    address public teamMentor;
    address public fundHolder;
    address public treasuryHolder;
    address public owner;
    uint256 private _founderFund;
    uint256 private _mentorFund;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint8 private month = 0;
    uint256 private _percentage;
    uint256 private previousTimeStamp = 0;


    constructor (string memory name_, string memory symbol_, address founder1_, address founder2_, address teamMentor_, address fundHolder_, address treasuryHolder_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 4;
        founder1 = founder1_;
        founder2 = founder2_;
        teamMentor = teamMentor_;
        fundHolder = fundHolder_;
        treasuryHolder = treasuryHolder_;
        owner = msg.sender;
        
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transfer(msg.sender, newOwner, _balances[msg.sender]);
        owner = newOwner;
        return true;
    }
    

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        _founderFund = _totalSupply.mul(889).div(10000);
        _mentorFund = _totalSupply.mul(1111).div(10000);
        _balances[fundHolder] = _balances[fundHolder].add(_founderFund.mul(2));
        _balances[fundHolder] = _balances[fundHolder].add(_mentorFund);
        _balances[treasuryHolder] = _balances[treasuryHolder].add(_mentorFund);
        _balances[account] = _balances[account].sub(_founderFund.mul(2)).sub(_mentorFund.mul(2));
        
        emit Transfer(address(0), account, amount);
        emit Transfer(address(0), fundHolder, _founderFund);
        emit Transfer(address(0), fundHolder, _mentorFund);
        emit Transfer(address(0), treasuryHolder, _mentorFund);
    }
    
    function transferMonthlyFunds() public onlyOwner returns(bool) {
        require (previousTimeStamp <= block.timestamp,"ERC20:transfer is currently not allowed");
        uint256 amount = 0;
        month +=1;
        if(month <= 5) {
            _percentage = 8;
        } else if(month > 5 && month <= 16) {
            _percentage = 4;
        } else if(month> 16 && month <=24) {
            _percentage = 2;
        } else {
            _percentage = 0;

        }
        amount = _founderFund.mul(_percentage).div(100);
        _transfer(fundHolder, founder1, amount);
        _transfer(fundHolder, founder2, amount);
        amount = _mentorFund.mul(_percentage).div(100);
        _transfer(fundHolder, teamMentor, amount);
        
        //for 30 days
        previousTimeStamp = block.timestamp + 86400 * 30;
        return true;
        
        
    }

    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract DigitalSwissFranc is ERC20 {

    constructor (address founder1_, address founder2_, address teamMentor_, address fundHolder_, address treasuryHolder_) ERC20("DIGITAL SWISS FRANC", "DSFR", founder1_, founder2_, teamMentor_,fundHolder_, treasuryHolder_) {
        _mint(msg.sender, 9000000000 * (10 ** uint256(decimals())));
    }
}