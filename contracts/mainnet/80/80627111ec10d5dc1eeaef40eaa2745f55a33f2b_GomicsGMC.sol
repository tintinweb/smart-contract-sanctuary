pragma solidity ^0.5.4;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(
            addedValue
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(
            subtractedValue
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            value
        );
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

contract GomicsGMC is ERC20 {
    string public constant name = "Gomics GMC";
    string public constant symbol = "GMC";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 500000000 * (10**uint256(decimals));

    constructor() public {
        super._mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Already owner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function dropToken(address[] memory _receivers, uint256[] memory _values)  public onlyOwner {
        require(_receivers.length != 0);
        require(_receivers.length == _values.length);
        
        for (uint256 i = 0; i < _receivers.length; i++) {
            transfer(_receivers[i], _values[i]);
            emit Transfer(msg.sender, _receivers[i], _values[i]);
        }
    }


    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Paused by owner");
        _;
    }

    modifier whenPaused() {
        require(paused, "Not paused now");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

    event Frozen(address target);
    event Unfrozen(address target);

    mapping(address => bool) internal freezes;

    modifier whenNotFrozen() {
        require(!freezes[msg.sender], "Sender account is locked.");
        _;
    }

    function freeze(address _target) public onlyOwner {
        freezes[_target] = true;
        emit Frozen(_target);
    }

    function unfreeze(address _target) public onlyOwner {
        freezes[_target] = false;
        emit Unfrozen(_target);
    }

    function isFrozen(address _target) public view returns (bool) {
        return freezes[_target];
    }

    function transfer(address _to, uint256 _value)
        public
        whenNotFrozen
        whenNotPaused
        returns (bool)
    {
        releaseLock(msg.sender);
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        require(!freezes[_from], "From account is locked.");
        releaseLock(_from);
        return super.transferFrom(_from, _to, _value);
    }

    event Mint(address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        super._mint(_to, _amount);
        emit Mint(_to, _amount);
        return true;
    }

    event Burn(address indexed burner, uint256 value);

    function burn(address _who, uint256 _value) public onlyOwner {
        require(_value <= super.balanceOf(_who), "Balance is too small.");

        _burn(_who, _value);
        emit Burn(_who, _value);
    }

    struct LockInfo {
        uint256 releaseTime;
        uint256 balance;
    }
    mapping(address => LockInfo[]) internal lockInfo;

    event Lock(address indexed holder, uint256 value, uint256 releaseTime);
    event Unlock(address indexed holder, uint256 value);

    function balanceOf(address _holder) public view returns (uint256 balance) {
        uint256 lockedBalance = 0;
        for (uint256 i = 0; i < lockInfo[_holder].length; i++) {
            lockedBalance = lockedBalance.add(lockInfo[_holder][i].balance);
        }
        return super.balanceOf(_holder).add(lockedBalance);
    }

    function releaseLock(address _holder) internal {
        for (uint256 i = 0; i < lockInfo[_holder].length; i++) {
            if (lockInfo[_holder][i].releaseTime <= now) {
                _balances[_holder] = _balances[_holder].add(
                    lockInfo[_holder][i].balance
                );
                emit Unlock(_holder, lockInfo[_holder][i].balance);
                lockInfo[_holder][i].balance = 0;

                if (i != lockInfo[_holder].length - 1) {
                    lockInfo[_holder][i] = lockInfo[_holder][lockInfo[_holder]
                        .length - 1];
                    i--;
                }
                lockInfo[_holder].length--;
            }
        }
    }

    function lockCount(address _holder) public view returns (uint256) {
        return lockInfo[_holder].length;
    }

    function lockState(address _holder, uint256 _idx)
        public
        view
        returns (uint256, uint256)
    {
        return (
            lockInfo[_holder][_idx].releaseTime,
            lockInfo[_holder][_idx].balance
        );
    }

    function lock(
        address _holder,
        uint256 _amount,
        uint256 _releaseTime
    ) public onlyOwner {
        require(super.balanceOf(_holder) >= _amount, "Balance is too small.");
        _balances[_holder] = _balances[_holder].sub(_amount);
        lockInfo[_holder].push(LockInfo(_releaseTime, _amount));
        emit Lock(_holder, _amount, _releaseTime);
    }

    function lockAfter(
        address _holder,
        uint256 _amount,
        uint256 _afterTime
    ) public onlyOwner {
        require(super.balanceOf(_holder) >= _amount, "Balance is too small.");
        _balances[_holder] = _balances[_holder].sub(_amount);
        lockInfo[_holder].push(LockInfo(now + _afterTime, _amount));
        emit Lock(_holder, _amount, now + _afterTime);
    }

    function unlock(address _holder, uint256 i) public onlyOwner {
        require(i < lockInfo[_holder].length, "No lock information.");

        _balances[_holder] = _balances[_holder].add(
            lockInfo[_holder][i].balance
        );
        emit Unlock(_holder, lockInfo[_holder][i].balance);
        lockInfo[_holder][i].balance = 0;

        if (i != lockInfo[_holder].length - 1) {
            lockInfo[_holder][i] = lockInfo[_holder][lockInfo[_holder].length -
                1];
        }
        lockInfo[_holder].length--;
    }

    function transferWithLock(
        address _to,
        uint256 _value,
        uint256 _releaseTime
    ) public onlyOwner returns (bool) {
        require(_to != address(0), "wrong address");
        require(_value <= super.balanceOf(owner), "Not enough balance");

        _balances[owner] = _balances[owner].sub(_value);
        lockInfo[_to].push(LockInfo(_releaseTime, _value));
        emit Transfer(owner, _to, _value);
        emit Lock(_to, _value, _releaseTime);

        return true;
    }

    function transferWithLockAfter(
        address _to,
        uint256 _value,
        uint256 _afterTime
    ) public onlyOwner returns (bool) {
        require(_to != address(0), "wrong address");
        require(_value <= super.balanceOf(owner), "Not enough balance");

        _balances[owner] = _balances[owner].sub(_value);
        lockInfo[_to].push(LockInfo(now + _afterTime, _value));
        emit Transfer(owner, _to, _value);
        emit Lock(_to, _value, now + _afterTime);

        return true;
    }

    function currentTime() public view returns (uint256) {
        return now;
    }

    function afterTime(uint256 _value) public view returns (uint256) {
        return now + _value;
    }
}