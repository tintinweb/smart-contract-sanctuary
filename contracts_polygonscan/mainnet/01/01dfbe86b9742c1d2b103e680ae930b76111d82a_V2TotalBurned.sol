/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// File: vaultfix/polycrystal-vaults/contracts/libs/IStrategy.sol


pragma solidity ^0.8.4;

// For interacting with our own strategy
interface IStrategy {
    // Want address
    function wantAddress() external view returns (address);
    
    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    // Is strategy paused
    function paused() external view returns (bool);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);
    
    // Univ2 router used by this strategy
    function uniRouterAddress() external view returns (address);

    // Main want token compounding function
    function earn() external;

    // Main want token compounding function
    function earn(address _to) external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens strategy -> vaultChef
    function withdraw(address _userAddress, uint256 _wantAmt) external returns (uint256);
    
    // Returns the strategy's recorded burned amount
    function burnedAmount() external view returns (uint256);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: vaultfix/polycrystal-vaults/contracts/libs/IVaultHealer.sol


pragma solidity ^0.8.4;



interface IVaultHealer {
    function poolInfo(uint256 pid) external view returns (IERC20 want, IStrategy strat);
    function deposit(uint256 _pid, uint256 _wantAmt, address _to) external;
    function poolLength() external view returns (uint);
}
// File: vaultfix/polycrystal-vaults/contracts/libs/V2TotalBurned.sol


pragma solidity ^0.8.4;


library V2TotalBurned {
    
    function getTotalBurned(IVaultHealer vaultHealer) external view returns (uint total) {
        uint poolLength = vaultHealer.poolLength();
        
        for (uint i; i < poolLength; i++) {
            (,IStrategy strat) = vaultHealer.poolInfo(i);
            try strat.burnedAmount() returns (uint amt) {
                total += amt;
            }
            catch {}
        }
    }
    
    
}