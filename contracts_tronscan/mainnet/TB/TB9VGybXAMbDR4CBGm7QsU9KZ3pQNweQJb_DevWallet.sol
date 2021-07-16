//SourceUnit: DevWallet.sol

pragma solidity 0.5.4;

import "./SafeMath.sol";
import "./Token.sol";

interface IInvestor {
    function buyFor(address _player, address _referredBy) external payable returns (uint256);
}

contract DevWallet {
    using SafeMath for uint256;
    address public owner;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private constant CEOShares = 45;
    uint256 private constant CTOShares = 15;
    uint256 private constant COOShares = 15;
    uint256 private constant InvestorShares = 25;
    IInvestor InvestorContract;
    address InvestorAddress = address(0x41b46d7b70aeb2fc63661d2ff32ec23637afd629ec); //TSRDnYXAYecRdmG4a5jfUrenoeqH5b7xxs


    uint256[] devShares = [CEOShares, CTOShares, COOShares, InvestorShares];

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    Token token;

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner method");
        _;
    }

    constructor (address CEOAddress, address CTOAddress, address COOAddress, address _InvestorContract, Token _token) public payable {
        owner = msg.sender;
        address[4] memory payees = [CEOAddress, CTOAddress, COOAddress, _InvestorContract];
        require(payees.length == devShares.length, "DevWallet: payees and shares length mismatch");
        require(payees.length > 0, "DevWallet: no payees");
        token = _token;
        InvestorContract = IInvestor(_InvestorContract);

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], devShares[i]);
        }
    }

    function setInvestorAddress(address newInvestorAddress) external onlyOwner {
        InvestorAddress = newInvestorAddress;
    }

    function() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    function release(address payable account) public {
        require(_shares[account] > 0, "DevWallet: account has no shares");

        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 payment = totalReceived.mul(_shares[account]).div(_totalShares).sub(_released[account]);

        require(payment != 0, "DevWallet: account is not due payment");

        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);
        if(account == address(InvestorContract)) {
            InvestorContract.buyFor.value(payment)(InvestorAddress, address(0));
        } else {
            account.transfer(payment);
        }
        emit PaymentReleased(account, payment);
    }

    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "DevWallet: account is the zero address");
        require(shares_ > 0, "DevWallet: shares are 0");
        require(_shares[account] == 0, "DevWallet: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account, shares_);
    }

    function transferTLT(address beneficiary, uint amount) external onlyOwner {
        token.transfer(beneficiary, amount);
    }
}

//SourceUnit: ERC20.sol

pragma solidity 0.5.4;

import "./IERC20.sol";
import "./SafeMath.sol";
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}


//SourceUnit: ERC20Burnable.sol

pragma solidity 0.5.4;

import "./ERC20.sol";

contract ERC20Burnable is ERC20 {
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}


//SourceUnit: ERC20Detailed.sol

pragma solidity 0.5.4;

import "./IERC20.sol";

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}


//SourceUnit: IERC20.sol

pragma solidity 0.5.4;

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


//SourceUnit: SafeMath.sol

pragma solidity 0.5.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: Token.sol

pragma solidity 0.5.4;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";

contract Token is ERC20, ERC20Detailed, ERC20Burnable {
    string public _name = "Lounge Token";
    string public _symbol = "TLT";
    uint8 public _decimals = 10;

    constructor()
    ERC20Burnable()
    ERC20Detailed(_name, _symbol, _decimals)
    ERC20()
    public {
        _mint(msg.sender, 230000000 * (10 ** uint256(decimals())));
    }
}