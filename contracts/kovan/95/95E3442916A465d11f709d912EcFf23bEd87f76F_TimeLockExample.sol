// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IWETH.sol";
  
/* @title A simple timelock contract for ETH and ERC20 tokens. */
contract TimeLockExample {
    
    ILendingPool lendingPool;
    IWETH weth;
    // each deposit to the TimeLock contract generates a
    // unique timelock ID via the `tlIdCounter` counter 
    uint tlIdCounter;
    
    struct TimeLock {
        address asset;
        address sender;
        address receiver;
        uint amount;
        uint expiry;
        bool lent;
    }
    
    // since ETH is deposited alongside ERC20s, we use mock address for ETH
    address constant MOCK_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // the receiver has 30 days to withdraw after the timelock has expired
    uint constant TIME_TO_WITHDRAW = 30 days;

    mapping(uint /* tlIdCounter */ => TimeLock) public timelocks;

    event Deposit(
        uint indexed timeLockID,
        address indexed sender,
        address indexed receiver,
        address asset,
        uint amount,
        uint lockTime
    );

    event Withdrawal(uint indexed timeLockID, address to);
    
    modifier validTimeLockID(uint _id) {
        require(0 < _id && _id <= tlIdCounter, "no such timelock ID");
        _;
    }

    constructor(address _lendingPoolAddr, address _wethAddr) {
        lendingPool = ILendingPool(_lendingPoolAddr);
        weth = IWETH(_wethAddr);
    }
    
    /* Fallback required for WETH withdraw. */
    receive() external payable {
        require(msg.sender == address(weth));
    }

    /** Deposits an ERC20 token to the timelock contract.
     *  
     *  @dev The sender must approve the timelock contract
     *    to transfer `token` on behalf of the sender. 
     *  
     *  @param receiver The intended receiver of the tokens.
     *  @param token The address of the token.
     *  @param amount The amount to be timelocked.
     *  @param lockTime The length of time the token is to be locked,
     *    expressed in seconds.
     *  
     *  @return The timelock ID representing this deposit.
     */ 
    function depositERC20(
        address receiver,
        address token,
        uint amount,
        uint lockTime
    ) external returns (uint) {

        require(amount > 0, "token amount must be nonzero");
 
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        tlIdCounter++;

        timelocks[tlIdCounter] = TimeLock({
            asset: token,
            sender: msg.sender,
            receiver: receiver,
            amount: amount,
            expiry: block.timestamp + lockTime,
            lent: false
        });
     
        emit Deposit(tlIdCounter, msg.sender, receiver, token, amount, lockTime);
        return tlIdCounter;
    }
    
    /** Deposits ETH to the timelock contract.
     *  
     *  @param receiver The intended receiver of the tokens.
     *  @param lockTime The length of time the token is to be locked,
     *    expressed in seconds.
     *  
     *  @return The timelock ID representing this deposit.
     */ 
    function depositETH(address receiver, uint lockTime) external payable returns (uint) {

        require(msg.value > 0, "deposited ETH must be nonzero");
    
        tlIdCounter++;

        timelocks[tlIdCounter] = TimeLock({
            asset: MOCK_ETH_ADDRESS,
            sender: msg.sender,
            receiver: receiver,
            amount: msg.value,
            expiry: block.timestamp + lockTime,
            lent: false
        });
     
        emit Deposit(tlIdCounter, msg.sender, receiver, MOCK_ETH_ADDRESS, msg.value, lockTime);
        return tlIdCounter;
    }
    
    /** Deposit an existing timelocked asset into the AAVE lending pool.
     *
     *  @dev There are many reasons why depositing to the AAVE lending pool
     *    might fail, e.g., there is no reserve for such an asset. See the
     *    AAVE `errors.sol` contract.
     *  @dev ETH deposits are first converted to WETH, then deposited to AAVE.  
     *  
     *  @param timeLockID The timelock ID representing a timelocked deposit.
     */ 
    function depositOnAAVE(uint timeLockID) external validTimeLockID(timeLockID) {
        
        TimeLock storage tl = timelocks[timeLockID];
        
        require(!tl.lent, "already deposited on AAVE");
        require(tl.amount > 0, "insufficient funds");

        tl.lent = true;
        
        if (tl.asset == MOCK_ETH_ADDRESS) {
            // convert to WETH
            weth.deposit{value: tl.amount}();
            require(weth.approve(address(lendingPool), tl.amount), "approve");
            lendingPool.deposit(address(weth), tl.amount, address(this), 0);
        } else {
            require(IERC20(tl.asset).approve(address(lendingPool), tl.amount), "approve");
            // reverts if lending pool for asset doesn't exist
            lendingPool.deposit(tl.asset, tl.amount, address(this), 0);
        }
    }

    /** Withdraw a timelocked asset.
     *
     *  @notice The receiver may withdraw as soon as the timelock expires.
     *    The sender must wait `TIME_TO_WITHDRAW` after the expiry before
     *    they are able to withdraw. 
     *  
     *  @param timeLockID The timelock ID representing a timelocked deposit.
     */ 
    function withdraw(uint timeLockID) external {

        _withdrawalChecks(timeLockID);

        TimeLock storage tl = timelocks[timeLockID];
        
        if (tl.lent) {
            _withdrawFromAAVE(timeLockID);
        }
        
        uint amountToTransfer = tl.amount;
        tl.amount = 0;
       
        if (tl.asset == MOCK_ETH_ADDRESS) {
            payable(msg.sender).transfer(amountToTransfer);
        } else {
            IERC20(tl.asset).transfer(msg.sender, amountToTransfer);
        }
        emit Withdrawal(timeLockID, msg.sender);
    }

    /** Withdraw an asset from AAVE. */ 
    function _withdrawFromAAVE(uint timeLockID) private validTimeLockID(timeLockID) {
        
        TimeLock storage tl = timelocks[timeLockID];
        
        tl.lent = false;
        
        if (tl.asset == MOCK_ETH_ADDRESS) {
            lendingPool.withdraw(address(weth), tl.amount, address(this));
            weth.withdraw(tl.amount);
        } else {
            lendingPool.withdraw(tl.asset, tl.amount, address(this));
        }
    }

    /** Various checks called when a withdrawal is attempted. */ 
    function _withdrawalChecks(uint timeLockID) private view {
        require(0 < timeLockID && timeLockID <= tlIdCounter, "no such timelock ID");
        
        TimeLock storage tl = timelocks[timeLockID];
        require(block.timestamp >= tl.expiry, "time lock has not yet expired");

        require(tl.amount > 0, "insufficient funds");

        // only `sender` or `receiver` in timelock can withdraw 
        require(
            msg.sender == tl.sender || msg.sender == tl.receiver,
            "no permissions to withdraw"    
        );
        
        if (msg.sender == tl.sender) {
            require(
                block.timestamp > tl.expiry + TIME_TO_WITHDRAW,
                "receiver withdrawal period has not yet ended"
            );
        } 
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @dev Simplified interface to AAVE's Lending Pool 
 */
interface ILendingPool {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function approve(address spender, uint value) external returns (bool);
    function deposit() external payable;
    function withdraw(uint wad) external;
}