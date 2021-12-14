/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

pragma solidity 0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract ScaTokenTimelock {

    struct Lock {
        address owner;
        uint256 amount;
        uint256 unlockDate;
    }

    IERC20 public token;

    mapping(address => Lock[]) userToTokenLocks;

    event Locked(address indexed user, uint amount, uint deadline);
    event Withdraw(address indexed user, uint amount);

    constructor(address _token){
        token = IERC20(_token);
    }

    function lockToken(uint256 _amount, uint256 _deadline) external returns (bool)
    {
        return lockTokenFor(msg.sender, _amount, _deadline);
    }

    function lockTokenFor(address _account, uint256 _amount, uint256 _deadline) public returns (bool)
    {
        //before and after balance to prevent _amount of being higher than the final receiving amount due to tokenomics such as fee on transfer
        uint balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _amount);
        uint balanceAfter = token.balanceOf(address(this));
        userToTokenLocks[_account].push(Lock(_account, balanceAfter - balanceBefore, _deadline));
        emit Locked(_account, _amount, _deadline);
        return true;
    }

    function withdraw(uint256 _index) external returns (Lock[] memory)
    {
        return withdrawFor(msg.sender, _index);
    }

    function withdrawFor(address _account, uint256 _index) public returns (Lock[] memory)
    {
        Lock[] storage locks = userToTokenLocks[_account];
        Lock memory lock = locks[_index];
        require(block.timestamp >= lock.unlockDate, "Token not unlocked yet!");
        locks[_index] = locks[locks.length - 1];
        locks.pop();
        token.transfer(_account, lock.amount);
        emit Withdraw(_account, lock.amount);
        return userToTokenLocks[_account];
    }

    function getLocks() public view returns (Lock[] memory)  {
        return getLocksOf(msg.sender);
    }

    function getLocksOf(address account) public view returns (Lock[] memory)  {
        return userToTokenLocks[account];
    }

}