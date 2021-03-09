/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.4.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
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
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

contract PersonaTokenBase is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) public balances_;
    mapping(address => mapping(address => uint256)) public allowed_;

    uint256 public totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances_[_owner];
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed_[_owner][_spender];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        require(_value <= balances_[_from]);
        require(_to != address(0));

        balances_[_from] = balances_[_from].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        require(_value <= balances_[_from]);
        require(_value <= allowed_[_from][msg.sender]);
        require(_to != address(0));

        balances_[_from] = balances_[_from].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        return _transferFrom(_from, _to, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        allowed_[msg.sender][_spender] = allowed_[msg.sender][_spender].add(
            _addedValue
        );
        emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = allowed_[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed_[msg.sender][_spender] = 0;
        } else {
            allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
        return true;
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances_[_account]);

        totalSupply_ = totalSupply_.sub(_amount);
        balances_[_account] = balances_[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }
}

contract PersonaToken is PersonaTokenBase, Ownable {
    string public name;
    string public symbol;
    uint256 public decimals = 18;
    struct lockInfo {
        uint256 lockQuantity;
        uint256 lockPeriod;
    }
    mapping(address => lockInfo[]) public tokenLockInfo;
    mapping(address => uint256) public unlockQuantity;
    mapping(address => bool) public lockStatus;
    mapping(address => bool) private FreezedWallet;

    function PersonaToken(
        uint256 initialSupply,
        string tokenName,
        uint256 decimalsToken,
        string tokenSymbol
    ) public {
        decimals = decimalsToken;
        totalSupply_ = initialSupply * 10**uint256(decimals);
        emit Transfer(0, msg.sender, totalSupply_);
        balances_[msg.sender] = totalSupply_;
        name = tokenName;
        symbol = tokenSymbol;
        unlockQuantity[msg.sender] = balances_[msg.sender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        bool transferResult;
        uint256 lockQuantity;
        uint256 lockTotalQuantity;
        uint256 lockPeriod;

        require(FreezedWallet[msg.sender] == false);
        require(FreezedWallet[_to] == false);

        if (lockStatus[msg.sender] == false) {
            transferResult = _transfer(msg.sender, _to, _value);
            if (transferResult == true) {
                unlockQuantity[msg.sender] = unlockQuantity[msg.sender].sub(
                    _value
                );
                unlockQuantity[_to] = unlockQuantity[_to].add(_value);
            }
        } else {
            for (uint256 i = 0; i < tokenLockInfo[msg.sender].length; i++) {
                lockQuantity = tokenLockInfo[msg.sender][i].lockQuantity;
                lockPeriod = tokenLockInfo[msg.sender][i].lockPeriod;

                if (lockPeriod <= now && lockQuantity != 0) {
                    unlockQuantity[msg.sender] = unlockQuantity[msg.sender].add(
                        lockQuantity
                    );
                    tokenLockInfo[msg.sender][i].lockQuantity = 0;
                    lockQuantity = tokenLockInfo[msg.sender][i].lockQuantity;
                }
                lockTotalQuantity = lockTotalQuantity.add(lockQuantity);
            }
            if (lockTotalQuantity == 0) lockStatus[msg.sender] = false;

            require(_value <= unlockQuantity[msg.sender]);

            transferResult = _transfer(msg.sender, _to, _value);
            if (transferResult == true) {
                unlockQuantity[msg.sender] = unlockQuantity[msg.sender].sub(
                    _value
                );
                unlockQuantity[_to] = unlockQuantity[_to].add(_value);
            }
        }

        return transferResult;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        bool transferResult;
        uint256 lockQuantity;
        uint256 lockTotalQuantity;
        uint256 lockPeriod;

        require(FreezedWallet[_from] == false);
        require(FreezedWallet[_to] == false);

        if (lockStatus[_from] == false) {
            transferResult = _transferFrom(_from, _to, _value);
            if (transferResult == true) {
                unlockQuantity[_from] = unlockQuantity[_from].sub(_value);
                unlockQuantity[_to] = unlockQuantity[_to].add(_value);
            }
        } else {
            for (uint256 i = 0; i < tokenLockInfo[_from].length; i++) {
                lockQuantity = tokenLockInfo[_from][i].lockQuantity;
                lockPeriod = tokenLockInfo[_from][i].lockPeriod;

                if (lockPeriod <= now && lockQuantity != 0) {
                    unlockQuantity[_from] = unlockQuantity[_from].add(
                        lockQuantity
                    );
                    tokenLockInfo[_from][i].lockQuantity = 0;
                    lockQuantity = tokenLockInfo[_from][i].lockQuantity;
                }
                lockTotalQuantity = lockTotalQuantity.add(lockQuantity);
            }
            if (lockTotalQuantity == 0) lockStatus[_from] = false;

            require(_value <= unlockQuantity[_from]);

            transferResult = _transferFrom(_from, _to, _value);
            if (transferResult == true) {
                unlockQuantity[_from] = unlockQuantity[_from].sub(_value);
                unlockQuantity[_to] = unlockQuantity[_to].add(_value);
            }
        }

        return transferResult;
    }

    function transferAndLock(
        address _to,
        uint256 _value,
        uint256 _lockPeriod
    ) public onlyOwner {
        bool transferResult;

        require(FreezedWallet[_to] == false);

        transferResult = _transfer(msg.sender, _to, _value);
        if (transferResult == true) {
            lockStatus[_to] = true;
            tokenLockInfo[_to].push(
                lockInfo(_value, now + _lockPeriod * 1 days)
            );
            unlockQuantity[msg.sender] = unlockQuantity[msg.sender].sub(_value);
        }
    }

    function changeLockPeriod(
        address _owner,
        uint256 _index,
        uint256 _newLockPeriod
    ) public onlyOwner {
        require(_index < tokenLockInfo[_owner].length);

        tokenLockInfo[_owner][_index].lockPeriod =
            now +
            _newLockPeriod *
            1 days;
    }

    function freezingWallet(address _owner) public onlyOwner {
        FreezedWallet[_owner] = true;
    }

    function unfreezingWallet(address _owner) public onlyOwner {
        FreezedWallet[_owner] = false;
    }

    function burn(uint256 _amount) public onlyOwner {
        _burn(msg.sender, _amount);
        unlockQuantity[msg.sender] = unlockQuantity[msg.sender].sub(_amount);
    }

    function getNowTime() public view returns (uint256 res) {
        return now;
    }

    function getLockInfo(address _owner, uint256 _index)
        public
        view
        returns (uint256, uint256)
    {
        return (
            tokenLockInfo[_owner][_index].lockQuantity,
            tokenLockInfo[_owner][_index].lockPeriod
        );
    }

    function getUnlockQuantity(address _owner)
        public
        view
        returns (uint256 res)
    {
        return unlockQuantity[_owner];
    }

    function getLockStatus(address _owner) public view returns (bool res) {
        return lockStatus[_owner];
    }

    function getLockCount(address _owner) public view returns (uint256 res) {
        return tokenLockInfo[_owner].length;
    }

    function getFreezingInfo(address _owner) public view returns (bool res) {
        return FreezedWallet[_owner];
    }
}