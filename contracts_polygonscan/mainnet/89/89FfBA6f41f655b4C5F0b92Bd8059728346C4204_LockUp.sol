// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract LockUp is Ownable {
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

    function lockUp(address _token, address _target, uint256 _amount, uint256 _unlock_time, string memory description) public onlyOwner
    {
        require(_token != address(0));
        require(_target != address(0));
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        if (lockupCount[_token] != 0) {
            balance = balance - lockupCount[_token];
        }
        require(_amount <= balance);
        require(block.timestamp <= _unlock_time);

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
        LockUpRecord memory row = lockup[id];
        require(msg.sender == row.owner);
        require(row.unlock_time <= block.timestamp);
        require(row.complete == false);
        IERC20 token = IERC20(row.token);
        token.transfer(msg.sender, row.amount);
        lockup[id].complete = true;
        lockupCount[row.token] = lockupCount[row.token] - row.amount;
    }

    function massUnlock(uint256[] memory ids, address _target, address _token) public onlyOwner {
        uint256 sum = 0;
        for(uint256 id = 0; id < ids.length; id++) {
            LockUpRecord memory row = lockup[ids[id]];
            if (row.owner == _target && row.unlock_time <= block.timestamp && row.complete == false && row.token == _token) {
                lockup[ids[id]].complete = true;
                sum = sum + row.amount;
                lockupCount[row.token] = lockupCount[row.token] - row.amount;
            }
        }
        require(sum > 0);
        IERC20 token = IERC20(_token);
        token.transfer(_target, sum);
    }

    function records() public view returns (LockUpRecord[] memory) {
        LockUpRecord[] memory _records = new LockUpRecord[](count);
        for (uint i = 0; i < count; i++) {
            LockUpRecord memory _record = lockup[i];
            _records[i] = _record;
        }
        return _records;
    }

    function recordsAddress(address _target) public view returns (LockUpRecord[] memory) {
        LockUpRecord[] memory _records = new LockUpRecord[](count);
        for (uint i = 0; i < count; i++) {
            LockUpRecord memory _record = lockup[i];
            if (_record.owner == _target) {
                _records[i] = _record;
            }
        }
        return _records;
    }

    function recordsAddressToken(address _target, address _token) public view returns (LockUpRecord[] memory) {
        LockUpRecord[] memory _records = new LockUpRecord[](count);
        for (uint i = 0; i < count; i++) {
            LockUpRecord memory _record = lockup[i];
            if (_record.owner == _target && _token == _record.token) {
                _records[i] = _record;
            }
        }
        return _records;
    }

    function unlockAvailable(uint256[] memory ids, address _target, address _token) public view returns (uint256) {
        uint256 sum = 0;
        for(uint256 id = 0; id < ids.length; id++) {
            LockUpRecord memory row = lockup[ids[id]];
            if (row.owner == _target && row.unlock_time <= block.timestamp && row.complete == false && row.token == _token) {
                sum = sum + row.amount;
            }
        }
        return sum;
    }

    function lockUpBalance(uint256[] memory ids, address _target, address _token) public view returns (uint256) {
        uint256 sum = 0;
        for(uint256 id = 0; id < ids.length; id++) {
            LockUpRecord memory row = lockup[ids[id]];
            if (row.owner == _target && row.complete == false && row.token == _token) {
                sum = sum + row.amount;
            }
        }
        return sum;
    }

    function checkLockUp(uint256 id, address _target) public view returns (bool) {
        return lockup[id].owner == _target && lockup[id].unlock_time <= block.timestamp && lockup[id].complete == false;
    }
}