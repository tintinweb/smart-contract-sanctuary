/**
 *Submitted for verification at arbiscan.io on 2021-09-30
*/

pragma solidity 0.6.0;

interface IErc20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract Locker {
    struct Lock {
        uint amount;
        uint unlockTime;
    }
    
    mapping (address => mapping (address => Lock)) public locks;
    
    function lock(address token, uint amount, uint lockTime) external {
        IErc20(token).transferFrom(msg.sender, address(this), amount);
        locks[msg.sender][token] = Lock(amount, now + lockTime);
    }
    
    function unlock(address token) external {
        Lock storage _lock = locks[msg.sender][token];
        require(_lock.amount > 0);
        require(_lock.unlockTime <= now);
        
        IErc20(token).transfer(msg.sender, _lock.amount);
        _lock.amount = 0;
    }
}