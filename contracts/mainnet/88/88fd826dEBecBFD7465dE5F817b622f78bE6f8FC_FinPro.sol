pragma solidity ^0.4.24;

// SafeMath library
library SafeMath {
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        assert(c >= _a);
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_a >= _b);
        return _a - _b;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }
}

// Contract must have an owner
contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
}

// Standard ERC20 Token Interface
interface ERC20Token {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function decimals() external view returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _totalSupply);
    function balanceOf(address _owner) external view returns (uint256 _balance);
    function transfer(address _to, uint256 _value) external returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
    function approve(address _spender, uint256 _value) external returns (bool _success);
    function allowance(address _owner, address _spender) external view returns (uint256 _remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SUPM financial product contract
contract FinPro is Ownable {
    using SafeMath for uint256;

    string private constant name = "FinPro";
    string private constant version = "v0.96";

    uint256[] private fplowerlim;
    uint256[] private fplocktime;
    uint256[] private fpinterest;
    uint256 private fpcount;

    ERC20Token private token;

    struct investedData {
        uint256 fpnum;
        uint256 buytime;
        uint256 unlocktime;
        uint256 value;
        bool withdrawn;
    }

    mapping (address => uint256) private investedAmount;
    mapping (address => mapping (uint256 => investedData)) private investorVault;

    address[] public admins;
    mapping (address => bool) public isAdmin;
    mapping (address => mapping (uint256 => mapping (address => mapping (address => bool)))) public adminWithdraw;
    mapping (address => mapping (uint256 => mapping (address => bool))) public adminTokenWithdraw;

    event FPBought(address _buyer, uint256 _amount, uint256 _investednum,
    uint256 _fpnum, uint256 _buytime, uint256 _unlocktime, uint256 _interestrate);
    event FPWithdrawn(address _investor, uint256 _amount, uint256 _investednum, uint256 _fpnum);

    // admin events
    event FPWithdrawnByAdmins(address indexed _addr, uint256 _amount, address indexed _investor, uint256 _investednum, uint256 _fpnum);
    event TokenWithdrawnByAdmins(address indexed _addr, uint256 _amount);

    // safety method-related events
    event WrongTokenEmptied(address indexed _token, address indexed _addr, uint256 _amount);
    event WrongEtherEmptied(address indexed _addr, uint256 _amount);

    constructor (address _tokenAddress, uint256[] _fplowerlim, uint256[] _fplocktime, uint256[] _fpinterest, address[] _admins) public {
        require(_fplowerlim.length == _fplocktime.length && _fplocktime.length == _fpinterest.length && _fpinterest.length > 0);
        fplowerlim = _fplowerlim;
        fplocktime = _fplocktime;
        fpinterest = _fpinterest;
        fpcount = fplowerlim.length;
        token = ERC20Token(_tokenAddress);
        admins = _admins;
        for (uint256 i = 0; i < admins.length; i++) {
            isAdmin[admins[i]] = true;
        }
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }

    function tokenInfo() public view returns (address _tokenAddress, uint8 _decimals,
    string _name, string _symbol, uint256 _tokenBalance) {
        return (address(token), token.decimals(), token.name(), token.symbol(), token.balanceOf(address(this)));
    }

    function showFPCount() public view returns (uint256) {
        return fplowerlim.length;
    }

    function showFPLowerlim() public view returns (uint256[]) {
        return fplowerlim;
    }

    function showFPLocktime() public view returns (uint256[]) {
        return fplocktime;
    }

    function showFPInterest() public view returns (uint256[]) {
        return fpinterest;
    }

    function showFPInfoAll() public view returns (uint256[] _fplowerlim, uint256[] _fplocktime, uint256[] _fpinterest) {
        return (fplowerlim, fplocktime, fpinterest);
    }

    function showInvestedNum(address _addr) public view returns (uint256) {
        return investedAmount[_addr];
    }

    function showInvestorVault(address _addr, uint256 _investednum) public view
    returns (uint256 _fpnum, uint256 _buytime, uint256 _unlocktime, uint256 _value, bool _withdrawn, bool _withdrawable) {
        require(_investednum > 0 && investedAmount[_addr] >= _investednum);
        return (investorVault[_addr][_investednum].fpnum, investorVault[_addr][_investednum].buytime,
        investorVault[_addr][_investednum].unlocktime, investorVault[_addr][_investednum].value,
        investorVault[_addr][_investednum].withdrawn,
        (now > investorVault[_addr][_investednum].unlocktime && !investorVault[_addr][_investednum].withdrawn));
    }

    function showInvestorVaultFull(address _addr) external view
    returns (uint256[] _fpnum, uint256[] _buytime, uint256[] _unlocktime, uint256[] _value,
    uint256[] _interestrate, bool[] _withdrawn, bool[] _withdrawable) {
        require(investedAmount[_addr] > 0);

        _fpnum = new uint256[](investedAmount[_addr]);
        _buytime = new uint256[](investedAmount[_addr]);
        _unlocktime = new uint256[](investedAmount[_addr]);
        _value = new uint256[](investedAmount[_addr]);
        _interestrate = new uint256[](investedAmount[_addr]);
        _withdrawn = new bool[](investedAmount[_addr]);
        _withdrawable = new bool[](investedAmount[_addr]);

        for(uint256 i = 0; i < investedAmount[_addr]; i++) {
            (_fpnum[i], _buytime[i], _unlocktime[i], _value[i], _withdrawn[i], _withdrawable[i]) = showInvestorVault(_addr, i + 1);
            _interestrate[i] = fpinterest[_fpnum[i]];
        }

        return (_fpnum, _buytime, _unlocktime, _value, _interestrate, _withdrawn, _withdrawable);
    }

    function buyfp(uint256 _fpnum, uint256 _amount) public {
        require(_fpnum < fpcount);
        require(_amount >= fplowerlim[_fpnum]);
        require(token.transferFrom(msg.sender, address(this), _amount));
        investedAmount[msg.sender]++;
        investorVault[msg.sender][investedAmount[msg.sender]] = investedData({fpnum: _fpnum, buytime: now,
        unlocktime: now.add(fplocktime[_fpnum]), value: _amount, withdrawn: false});
        emit FPBought(msg.sender, _amount, investedAmount[msg.sender], _fpnum, now, now.add(fplocktime[_fpnum]), fpinterest[_fpnum]);
    }

    function withdraw(uint256 _investednum) public {
        require(_investednum > 0 && investedAmount[msg.sender] >= _investednum);
        require(!investorVault[msg.sender][_investednum].withdrawn);
        require(now > investorVault[msg.sender][_investednum].unlocktime);
        require(token.balanceOf(address(this)) >= investorVault[msg.sender][_investednum].value);
        require(token.transfer(msg.sender, investorVault[msg.sender][_investednum].value));
        investorVault[msg.sender][_investednum].withdrawn = true;
        emit FPWithdrawn(msg.sender, investorVault[msg.sender][_investednum].value,
        _investednum, investorVault[msg.sender][_investednum].fpnum);
    }

    // admin methods
    function withdrawByAdmin(address _investor, uint256 _investednum, address _target) onlyAdmin public {
        require(_investednum > 0 && investedAmount[_investor] >= _investednum);
        require(!investorVault[_investor][_investednum].withdrawn);
        require(token.balanceOf(address(this)) >= investorVault[_investor][_investednum].value);
        adminWithdraw[_investor][_investednum][_target][msg.sender] = true;
        for (uint256 i = 0; i < admins.length; i++) {
            if (!adminWithdraw[_investor][_investednum][_target][admins[i]]) {
                return;
            }
        }
        require(token.transfer(_target, investorVault[_investor][_investednum].value));
        investorVault[_investor][_investednum].withdrawn = true;
        emit FPWithdrawnByAdmins(_target, investorVault[_investor][_investednum].value, _investor,
        _investednum, investorVault[_investor][_investednum].fpnum);
    }

    function withdrawTokenByAdmin(address _target, uint256 _amount) onlyAdmin public {
        adminTokenWithdraw[_target][_amount][msg.sender] = true;
        uint256 i;
        for (i = 0; i < admins.length; i++) {
            if (!adminTokenWithdraw[_target][_amount][admins[i]]) {
                return;
            }
        }
        for (i = 0; i < admins.length; i++) {
            adminTokenWithdraw[_target][_amount][admins[i]] = false;
        }
        require(token.transfer(_target, _amount));
        emit TokenWithdrawnByAdmins(_target, _amount);
    }

    // safety methods
    function () public payable {
        revert();
    }

    function emptyWrongToken(address _addr) onlyOwner public {
        require(_addr != address(token));
        ERC20Token wrongToken = ERC20Token(_addr);
        uint256 amount = wrongToken.balanceOf(address(this));
        require(amount > 0);
        require(wrongToken.transfer(msg.sender, amount));

        emit WrongTokenEmptied(_addr, msg.sender, amount);
    }

    // shouldn&#39;t happen, just in case
    function emptyWrongEther() onlyOwner public {
        uint256 amount = address(this).balance;
        require(amount > 0);
        msg.sender.transfer(amount);

        emit WrongEtherEmptied(msg.sender, amount);
    }
}