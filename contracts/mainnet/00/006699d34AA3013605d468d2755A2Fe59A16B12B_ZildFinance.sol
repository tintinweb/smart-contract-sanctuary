pragma solidity 0.5.4;

import 'SafeMath.sol';
import 'Ownable.sol';
import 'IERC20.sol';

contract ZildFinanceCoin is Ownable, IERC20 {

    using SafeMath for uint256;

    string public constant name = 'Zild Finance Coin';
    string public constant symbol = 'Zild';
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 9980 * 10000 * 10 ** uint256(decimals);
    uint256 public allowBurn = 2100 * 10000 * 10 ** uint256(decimals);
    uint256 public tokenDestroyed;
	
    uint256 public constant FounderAllocation = 1497 * 10000 * 10 ** uint256(decimals);
    uint256 public constant FounderLockupAmount = 998 * 10000 * 10 ** uint256(decimals);
    uint256 public constant FounderLockupCliff = 365 days;
    uint256 public constant FounderReleaseInterval = 30 days;
    uint256 public constant FounderReleaseAmount = 20.7916 * 10000 * 10 ** uint256(decimals);
    uint256 public constant MarketingAllocation = 349 * 10000 * 10 ** uint256(decimals);
    uint256 public constant FurnaceAllocation = 150 * 10000 * 10 ** uint256(decimals);
	
    address public founder = address(0);
    uint256 public founderLockupStartTime = 0;
    uint256 public founderReleasedAmount = 0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;    
    mapping (address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);
    event ChangeFounder(address indexed previousFounder, address indexed newFounder);
    event SetMinter(address indexed minter);
    event SetMarketing(address indexed marketing);
    event SetFurnace(address indexed furnace);	
    event Burn(address indexed _from, uint256 _tokenDestroyed, uint256 _timestamp);
    event FrozenFunds(address target, bool frozen);
	
    constructor(address _founder, address _marketing) public {
        require(_founder != address(0), "ZildFinanceCoin: founder is the zero address");
        require(_marketing != address(0), "ZildFinanceCoin: operator is the zero address");
        founder = _founder;
        founderLockupStartTime = block.timestamp;
        _balances[address(this)] = totalSupply;
        _transfer(address(this), _marketing, MarketingAllocation);
    }

    function release() public {
        uint256 currentTime = block.timestamp;
        uint256 cliffTime = founderLockupStartTime.add(FounderLockupCliff);
        if (currentTime < cliffTime) return;
        if (founderReleasedAmount >= FounderLockupAmount) return;
        uint256 month = currentTime.sub(cliffTime).div(FounderReleaseInterval);
        uint256 releaseAmount = month.mul(FounderReleaseAmount);
        if (releaseAmount > FounderLockupAmount) releaseAmount = FounderLockupAmount;
        if (releaseAmount <= founderReleasedAmount) return;
        uint256 amount = releaseAmount.sub(founderReleasedAmount);
        founderReleasedAmount = releaseAmount;
        _transfer(address(this), founder, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "ERC20: tranfer to the zero address");
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[to]);
        _transfer(msg.sender, to, amount);
        return true;
    }
	
    function burn(uint256 _value) public returns (bool){
        _burn(msg.sender, _value);
        return true;
    }

    function _burn(address _who, uint256 _burntAmount) internal {
        require (tokenDestroyed.add(_burntAmount) <= allowBurn, "ZildFinanceCoin: exceeded the maximum allowable burning amount" );
        require(_balances[msg.sender] >= _burntAmount && _burntAmount > 0);
        _transfer(address(_who), address(0), _burntAmount);
        totalSupply = totalSupply.sub(_burntAmount);
        tokenDestroyed = tokenDestroyed.add(_burntAmount);
        emit Burn(_who, _burntAmount, block.timestamp);
    }
	

    function allowance(address from, address to) public view returns (uint256) {
        return _allowances[from][to];
    }

    function approve(address to, uint256 amount) public returns (bool) {
        _approve(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 remaining = _allowances[from][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance");
        require(to != address(0), "ERC20: tranfer to the zero address");
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);
        require(!frozenAccount[msg.sender]);
        _transfer(from, to, amount);
        _approve(from, msg.sender, remaining);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        _balances[from] = _balances[from].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function _approve(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
        _allowances[from][to] = amount;
        emit Approval(from, to, amount);
    }

    function changeFounder(address _founder) public onlyOwner {
        require(_founder != address(0), "ZildFinanceCoin: founder is the zero address");
        emit ChangeFounder(founder, _founder);
        founder = _founder;
    }

    function setMinter(address minter) public onlyOwner {
        require(minter != address(0), "ZildFinanceCoin: minter is the zero address");
        require(_balances[minter] == 0, "ZildFinanceCoin: minter has been initialized");
        _transfer(address(this), minter, totalSupply.sub(FounderAllocation));
        emit SetMinter(minter);
    }

    function setFurnace(address furnace) public onlyOwner {
        require(furnace != address(0), "ZildFinanceCoin: furnace is the zero address");
        require(_balances[furnace] == 0, "ZildFinanceCoin: furnace has been initialized");
        _transfer(address(this), furnace, FurnaceAllocation);
        emit SetFurnace(furnace);
    }
	
    function freezeAccount(address _target, bool _bool) public onlyOwner {
        if (_target != address(0)) {
            frozenAccount[_target] = _bool;
            emit FrozenFunds(_target,_bool);
        }
    }

}