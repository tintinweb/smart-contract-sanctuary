/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

/**
* @title ERC20Basic
* @dev Simpler version of ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/179
*/
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract LockUp {
    struct LockUpRecord {
        uint256 id;
        address token;
        address owner;
        uint256 amount;
        uint256 unlock_time;
        string description;
        bool complete;
    }
    mapping (uint256 => LockUpRecord) public lockup;
    mapping (address => uint256) public lockupCount;
    uint256 public count;
    address public _owner;

    constructor() public {
        _owner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function lockUp(address _token, address _target, uint256 _amount, uint256 _unlock_time, string description) public onlyOwner
    {
        require(_token != address(0));
        require(_target != address(0));
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(address(this));
        if (lockupCount[_token] != 0) {
            balance = balance - lockupCount[_token];
        }
        require(_amount <= balance);
        require(now <= _unlock_time);

        lockup[count] = LockUpRecord({
        id: count,
        token: _token,
        owner: _target,
        amount: _amount,
        unlock_time: _unlock_time,
        description: description,
        complete: false
        });

        if (lockupCount[_token] != 0) {
            lockupCount[_token] = lockupCount[_token] + _amount;
        } else {
            lockupCount[_token] = _amount;
        }

        count = count + 1;
    }

    function delegate(uint256 id, address _target) public onlyOwner {
        require(msg.sender == lockup[id].owner);
        lockup[id].owner = _target;
    }

    function unlock(uint256 id) public {
        LockUpRecord row = lockup[id];
        require(msg.sender == row.owner);
        require(row.unlock_time <= block.timestamp);
        require(row.complete == false);
        ERC20Basic token = ERC20Basic(row.token);
        token.transfer(msg.sender, row.amount);
        lockup[id].complete = true;
        lockupCount[row.token] = lockupCount[row.token] - row.amount;
    }

    function massUnlock(uint256[] ids, address _target, address _token) public onlyOwner {
        uint256 sum = 0;
        for(uint256 id = 0; id < ids.length; id++) {
            LockUpRecord row = lockup[ids[id]];
            if (row.owner == _target && row.unlock_time <= block.timestamp && row.complete == false && row.token == _token) {
                lockup[ids[id]].complete = true;
                sum = sum + row.amount;
                lockupCount[row.token] = lockupCount[row.token] - row.amount;
            }
        }
        require(sum > 0);
        ERC20Basic token = ERC20Basic(_token);
        token.transfer(_target, sum);
    }

    function records() public view returns (LockUpRecord[] memory) {
        LockUpRecord[] memory _records = new LockUpRecord[](count);
        for (uint i = 0; i < count; i++) {
            LockUpRecord _record = lockup[i];
            _records[i] = _record;
        }
        return _records;
    }

    function recordsAddress(address _target) public view returns (LockUpRecord[] memory) {
        LockUpRecord[] memory _records = new LockUpRecord[](count);
        for (uint i = 0; i < count; i++) {
            LockUpRecord _record = lockup[i];
            if (_record.owner == _target) {
                _records[i] = _record;
            }
        }
        return _records;
    }

    function recordsAddressToken(address _target, address _token) public view returns (LockUpRecord[] memory) {
        LockUpRecord[] memory _records = new LockUpRecord[](count);
        for (uint i = 0; i < count; i++) {
            LockUpRecord _record = lockup[i];
            if (_record.owner == _target && _token == _record.token) {
                _records[i] = _record;
            }
        }
        return _records;
    }

    function unlockAvailable(uint256[] ids, address _target, address _token) public view returns (uint256) {
        uint256 sum = 0;
        for(uint256 id = 0; id < ids.length; id++) {
            LockUpRecord row = lockup[ids[id]];
            if (row.owner == _target && row.unlock_time <= now && row.complete == false && row.token == _token) {
                sum = sum + row.amount;
            }
        }
        return sum;
    }

    function lockUpBalance(uint256[] ids, address _target, address _token) public view returns (uint256) {
        uint256 sum = 0;
        for(uint256 id = 0; id < ids.length; id++) {
            LockUpRecord row = lockup[ids[id]];
            if (row.owner == _target && row.complete == false && row.token == _token) {
                sum = sum + row.amount;
            }
        }
        return sum;
    }

    function checkLockUp(uint256 id, address _target) public view returns (bool) {
        return lockup[id].owner == _target && lockup[id].unlock_time <= now && lockup[id].complete == false;
    }
}