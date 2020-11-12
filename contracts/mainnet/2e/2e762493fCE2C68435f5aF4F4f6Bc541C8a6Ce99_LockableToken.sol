pragma solidity ^0.5.0; // solidity 0.5.2

import './ERC20.sol';
import './MultiOwnable.sol';
import './ERC20Burnable.sol';
/**
 * @title Lockable token
 */
contract LockableToken is ERC20, MultiOwnable, ERC20Burnable {
    bool public locked = true;
    uint256 public constant LOCK_MAX = uint256(-1);

    /**
     * dev 락 상태에서도 거래 가능한 언락 계정
     */
    mapping(address => bool) public unlockAddrs;
    /**
     * dev 계정 별로 lock value 만큼 잔고가 잠김
     * dev - 값이 0 일 때 : 잔고가 0 이어도 되므로 제한이 없는 것임.
     * dev - 값이 LOCK_MAX 일 때 : 잔고가 uint256 의 최대값이므로 아예 잠긴 것임.
     */
    mapping(address => uint256) public lockValues;

    event Locked(bool locked, string note);
    event LockedTo(address indexed addr, bool locked, string note);
    event SetLockValue(address indexed addr, uint256 value, string note);

    constructor() public {
        unlockTo(msg.sender,  "");
    }

    modifier checkUnlock (address addr, uint256 value) {
        require(!locked || unlockAddrs[addr], "The account is currently locked.");
        require(_balances[addr].sub(value) >= lockValues[addr], "Transferable limit exceeded. Check the status of the lock value.");
        _;
    }

    function lock(string memory note) onlyOwner public {
        locked = true;
        emit Locked(locked, note);
    }

    function unlock(string memory note) onlyOwner public {
        locked = false;
        emit Locked(locked, note);
    }

    function lockTo(address addr, string memory note) onlyOwner public {
        setLockValue(addr, LOCK_MAX, note);
        unlockAddrs[addr] = false;

        emit LockedTo(addr, true, note);
    }

    function unlockTo(address addr, string memory note) onlyOwner public {
        if (lockValues[addr] == LOCK_MAX)
            setLockValue(addr, 0, note);
        unlockAddrs[addr] = true;

        emit LockedTo(addr, false, note);
    }

    function setLockValue(address addr, uint256 value, string memory note) onlyOwner public {
        lockValues[addr] = value;
        emit SetLockValue(addr, value, note);
    }

    /**
     * dev 이체 가능 금액을 조회한다.
     */
    function getMyUnlockValue() public view returns (uint256) {
        address addr = msg.sender;
        if ((!locked || unlockAddrs[addr]) && _balances[addr] > lockValues[addr])
            return _balances[addr].sub(lockValues[addr]);
        else
            return 0;
    }

    function transfer(address to, uint256 value) checkUnlock(msg.sender, value) public returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) checkUnlock(from, value) public returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
    function burn(uint256 amount) onlyOwner public {
        return super.burn(amount);
    }
    
    function burnFrom(address account, uint256 amount) onlyOwner public {
        return super.burnFrom(account,amount);
    }
    
}