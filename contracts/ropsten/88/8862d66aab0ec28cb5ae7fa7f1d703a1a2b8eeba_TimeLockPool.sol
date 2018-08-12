pragma solidity ^0.4.24;

// File: contracts/math/SafeMath.sol

/**
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Released under the MIT license.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/token/ERC20/ERC20Interface.sol

/**
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Released under the MIT license.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
*/

/**
 * @title 
 * @dev 
 */
contract ERC20Interface {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/DAICOVO/TimeLockPool.sol

/// @title A token-pool that locks deposited tokens until their date of maturity.
/// @author ICOVO AG
/// @dev It regards the address "0x0" as ETH when you speficy a token.
contract TimeLockPool{
    using SafeMath for uint256;

    struct LockedBalance {
      uint256 balance;
      uint256 releaseTime;
    }

    /*
      structure: lockedBalnces[owner][token] = LockedBalance(balance, releaseTime);
      token address = &#39;0x0&#39; stands for ETH (unit = wei)
    */
    mapping (address => mapping (address => LockedBalance[])) public lockedBalances;

    event Deposit(
        address indexed owner,
        address indexed tokenAddr,
        uint256 amount,
        uint256 releaseTime
    );

    event Withdraw(
        address indexed owner,
        address indexed tokenAddr,
        uint256 amount
    );

    /// @dev Constructor. 
    /// @return 
    constructor() public {}

    /// @dev Deposit tokens to specific account with time-lock.
    /// @param tokenAddr The contract address of a ERC20/ERC223 token.
    /// @param account The owner of deposited tokens.
    /// @param amount Amount to deposit.
    /// @param releaseTime Time-lock period.
    /// @return True if it is successful, revert otherwise.
    function depositERC20 (
        address tokenAddr,
        address account,
        uint256 amount,
        uint256 releaseTime
    ) external returns (bool) {
        require(account != address(0x0));
        require(tokenAddr != 0x0);
        require(msg.value == 0);
        require(amount > 0);
        require(ERC20Interface(tokenAddr).transferFrom(msg.sender, this, amount));

        lockedBalances[account][tokenAddr].push(LockedBalance(amount, releaseTime));
        emit Deposit(account, tokenAddr, amount, releaseTime);

        return true;
    }

    /// @dev Deposit ETH to specific account with time-lock.
    /// @param account The owner of deposited tokens.
    /// @param releaseTime Timestamp to release the fund.
    /// @return True if it is successful, revert otherwise.
    function depositETH (
        address account,
        uint256 releaseTime
    ) external payable returns (bool) {
        require(account != address(0x0));
        address tokenAddr = address(0x0);
        uint256 amount = msg.value;
        require(amount > 0);

        lockedBalances[account][tokenAddr].push(LockedBalance(amount, releaseTime));
        emit Deposit(account, tokenAddr, amount, releaseTime);

        return true;
    }

    /// @dev Release the available balance of an account.
    /// @param account An account to receive tokens.
    /// @param tokenAddr An address of ERC20/ERC223 token.
    /// @param max_count Max number of records to withdraw.
    /// @return True if it is successful, revert otherwise.
    function withdraw (address account, address tokenAddr, uint256 max_count) external returns (bool) {
        require(account != address(0x0));

        uint256 release_amount = 0;
        for (uint256 i = 0; i < lockedBalances[account][tokenAddr].length && i < max_count; i++) {
            if (lockedBalances[account][tokenAddr][i].balance > 0 &&
                lockedBalances[account][tokenAddr][i].releaseTime <= block.timestamp) {

                release_amount = release_amount.add(lockedBalances[account][tokenAddr][i].balance);
                lockedBalances[account][tokenAddr][i].balance = 0;
            }
        }

        require(release_amount > 0);

        if (tokenAddr == 0x0) {
            if (!account.send(release_amount)) {
                revert();
            }
            emit Withdraw(account, tokenAddr, release_amount);
            return true;
        } else {
            if (!ERC20Interface(tokenAddr).transfer(account, release_amount)) {
                revert();
            }
            emit Withdraw(account, tokenAddr, release_amount);
            return true;
        }
    }

    /// @dev Returns total amount of balances which already passed release time.
    /// @param account An account to receive tokens.
    /// @param tokenAddr An address of ERC20/ERC223 token.
    /// @return Available balance of specified token.
    function getAvailableBalanceOf (address account, address tokenAddr) 
        external
        view
        returns (uint256)
    {
        require(account != address(0x0));

        uint256 balance = 0;
        for(uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if (lockedBalances[account][tokenAddr][i].releaseTime <= block.timestamp) {
                balance = balance.add(lockedBalances[account][tokenAddr][i].balance);
            }
        }
        return balance;
    }

    /// @dev Returns total amount of balances which are still locked.
    /// @param account An account to receive tokens.
    /// @param tokenAddr An address of ERC20/ERC223 token.
    /// @return Locked balance of specified token.
    function getLockedBalanceOf (address account, address tokenAddr)
        external
        view
        returns (uint256) 
    {
        require(account != address(0x0));

        uint256 balance = 0;
        for(uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if(lockedBalances[account][tokenAddr][i].releaseTime > block.timestamp) {
                balance = balance.add(lockedBalances[account][tokenAddr][i].balance);
            }
        }
        return balance;
    }

    /// @dev Returns next release time of locked balances.
    /// @param account An account to receive tokens.
    /// @param tokenAddr An address of ERC20/ERC223 token.
    /// @return Timestamp of next release.
    function getNextReleaseTimeOf (address account, address tokenAddr)
        external
        view
        returns (uint256) 
    {
        require(account != address(0x0));

        uint256 nextRelease = 2**256 - 1;
        for (uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if (lockedBalances[account][tokenAddr][i].releaseTime > block.timestamp &&
               lockedBalances[account][tokenAddr][i].releaseTime < nextRelease) {

                nextRelease = lockedBalances[account][tokenAddr][i].releaseTime;
            }
        }

        /* returns 0 if there are no more locked balances. */
        if (nextRelease == 2**256 - 1) {
            nextRelease = 0;
        }
        return nextRelease;
    }
}