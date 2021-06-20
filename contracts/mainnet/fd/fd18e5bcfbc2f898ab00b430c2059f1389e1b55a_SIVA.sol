/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

interface PreSale {
    function userShare(address _useraddress) external view returns (uint256);
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

contract SIVA is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) claimedPreSaleTokens;
    mapping (address => uint256) public analyticsID;
    mapping (address => uint256) public SIVAadsID;
    mapping (address => uint256) public SIVABusinessID;
    mapping (uint256 => mapping (string => address)) public SIVAMarketingMatrix;
    mapping (uint256 => mapping (string => address)) public SIVAIndexA;
    mapping (uint256 => mapping (string => string)) public SIVAIndexB;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    string private _url;
    address public _deployer;
    address public presaleContract;
    uint256 public process;
    uint256 public SIVAINDEX;

    constructor () public {
        _deployer = _msgSender();
        _name = "SIVA";
        _symbol = "SIVA";
        _decimals = 18;
        _url = "https://sivanetwork.eth";
        _totalSupply = 200000000 * 10 ** 18;
        _balances[_deployer] = _totalSupply;
        process = 0;
        SIVAINDEX = 0;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function url() public view returns (string memory) {
        return _url;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function setUrl(string calldata uri) public virtual returns (bool) {
        require (_msgSender() == _deployer, "Only deployer.");
        _url = uri;
        return true;
    }

    function setPresaleContract(address _contract) public virtual returns (bool) {
        require (_msgSender() == _deployer, "Only deployer.");
        presaleContract = _contract;
        return true;
    }

    function setName(string calldata cname) public virtual returns (bool) {
        require (_msgSender() == _deployer, "Only deployer.");
        _name = cname;
        return true;
    }

    function generateCard() public virtual returns (bool) {
        require (_msgSender() != address(0), "No Zero address submission.");
        analyticsID[_msgSender()] = process;
        SIVAadsID[_msgSender()] = process;
        SIVABusinessID[_msgSender()] = process;
        process += 1;
        return true;
    }

    function generateMarketingMatrix(string calldata _metadata, string calldata _description) public virtual returns (bool) {
        require (_msgSender() != address(0), "No Zero address submission.");
        SIVAMarketingMatrix[SIVAINDEX][_metadata] = _msgSender();
        SIVAIndexA[SIVAINDEX][_metadata] = _msgSender();
        SIVAIndexB[SIVAINDEX][_metadata] = _description;
        SIVAINDEX += 1;
        return true;
    }

    function claimPresaleTokens() public virtual returns (bool) {
        require(_msgSender() != address(0), "No request from the zero address");
        require(claimedPreSaleTokens[_msgSender()] == false, "Unable");
        _transfer(address(this), _msgSender(), PreSale(presaleContract).userShare(_msgSender()));
        claimedPreSaleTokens[_msgSender()] = true;
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
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
}