//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IStaking.sol";

contract Staking is IStaking, ReentrancyGuard {
    mapping(address => uint256) private _stakedBalances;
    mapping(address => uint256) private _unlockTimes;

    address private tokenAddress;
    address private daoAddress;
    uint256 totalStakedBalance;
    bool shutdown=false;

    event StakeChanged(address staker, uint256 newStakedBalance);
    event UnlockTimeIncreased(address staker, uint256 newUnlockBlock);
    event EmergencyShutdown(address calledBy, uint256 shutdownBlock);

    modifier onlyDao() {
        require(msg.sender == daoAddress, "only dao can call this function");
        _;
    }

    modifier notShutdown() {
        require(!shutdown, "cannot be called after shutdown");
        _;
    }

    constructor(address _token, address _dao) {
        tokenAddress = _token;
        daoAddress = _dao;
    }

    /**
     * @dev returns address of the token that can be staked
     *
     * @return the address of the token contract
     */
    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    /**
     * @dev returns address of the DAO contract
     *
     * @return the address of the dao contract
     */
    function getDaoAddress() public view returns (address) {
        return daoAddress;
    }

    /**
     * @dev Gets staker's staked balance (voting power)
     * @param staker                 The staker's address
     * @return (uint) staked token balance
     */
    function getStakedBalance(address staker) external view override returns(uint256) {
        return _stakedBalances[staker];
    }

    /**
     * @dev Gets staker's unlock time
     * @param staker                 The staker's address
     * @return (uint) staker's unlock time in blocks
     */
    function getUnlockTime(address staker) external view override returns(uint256) {
        return _unlockTimes[staker];
    }

    /**
     * @dev returns if staking contract is shutdown or not
     */
    function isShutdown() public view override returns(bool) {
        return shutdown;
    }

    // Raphael calls this to lock tokens when vote() called
    function voted(
        address voter,
        uint256 endBlock
    ) external onlyDao notShutdown override returns(bool) {
        if(_unlockTimes[voter] < endBlock){
            _unlockTimes[voter] = endBlock;

            emit UnlockTimeIncreased(voter, endBlock);
        }
 
        return true;
    }

    /**
     * @dev allows a user to stake and to increase their stake
     * @param amount the uint256 amount of native token being staked/added
     * @notice user must first approve staking contract for at least the amount
     */
    function stake(uint256 amount) external notShutdown override {
        IERC20 tokenContract = IERC20(tokenAddress);
        require(tokenContract.balanceOf(msg.sender) >= amount, "Amount higher than user's balance");
        require(tokenContract.allowance(msg.sender, address(this)) >= amount, 'Approved allowance too low');
        require(
            tokenContract.transferFrom(msg.sender, address(this), amount),
            "staking tokens failed"
        );
        totalStakedBalance += amount;
        _stakedBalances[msg.sender] += amount;

        emit StakeChanged(msg.sender, _stakedBalances[msg.sender]);
    }

    /**
     * @dev allows a user to withdraw their unlocked tokens
     * @param amount the uint256 amount of native token being withdrawn
     */
    function withdraw(uint256 amount) external override {
        if(!shutdown){
            require(_unlockTimes[msg.sender] < block.number, "Tokens not unlocked yet");
        }
        require(
            _stakedBalances[msg.sender] >= amount,
            "Insufficient staked balance"
        );
        require(totalStakedBalance >= amount, "insufficient funds in contract");

        // Send unlocked tokens back to user
        totalStakedBalance -= amount;
        _stakedBalances[msg.sender] -= amount;
        IERC20 tokenContract = IERC20(tokenAddress);
        require(tokenContract.transfer(msg.sender, amount), "withdraw failed");
    }

    function emergencyShutdown(address admin) external onlyDao notShutdown nonReentrant override {
        // when shutdown = true, it skips the locktime require in withdraw
        // so all users get their tokens unlocked immediately
        shutdown = true;
        emit EmergencyShutdown(admin, block.number);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStaking{
    function getStakedBalance(address staker) external view returns(uint256);
    function getUnlockTime(address staker) external view returns(uint256);
    function isShutdown() external view returns(bool);
    function voted(address voter, uint256 endBlock) external returns(bool);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function emergencyShutdown(address admin) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}