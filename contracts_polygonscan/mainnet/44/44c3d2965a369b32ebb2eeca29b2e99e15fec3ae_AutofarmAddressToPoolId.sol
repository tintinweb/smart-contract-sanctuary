/**
 *Submitted for verification at polygonscan.com on 2021-09-09
*/

pragma solidity ^0.8.6;


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


interface IAutofarmV2_CrossChain {
    struct PoolInfo {
        IERC20 want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. AUTO to distribute per block.
        uint256 lastRewardBlock; // Last block number that AUTO distribution occurs.
        uint256 accAUTOPerShare; // Accumulated AUTO per share, times 1e12. See below.
        address strat; // Strategy address that will auto compound want tokens
    }

    function poolInfo(uint i) external returns (IERC20, uint256, uint256, uint256, address);

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256);

    function poolLength() external view returns (uint256);
}
contract AutofarmAddressToPoolId {
    mapping(address=>uint256) poolMapper;
    uint256 updatedLen = 0;
    address constant autofarmAddress = 0x89d065572136814230A55DdEeDDEC9DF34EB0B76;

    function getPoolId(address asset) external returns (uint256) {
        IAutofarmV2_CrossChain autofarm = IAutofarmV2_CrossChain(autofarmAddress);

        updatePools();

        uint256 poolId = poolMapper[asset];
        (IERC20 a, , , , ) = autofarm.poolInfo(poolId);
        require(address(a) == asset, "ASSET NOT AVAILABLE IN AUTOFARM");
        return poolId;
    }

    function updatePools() internal {
        IAutofarmV2_CrossChain autofarm = IAutofarmV2_CrossChain(autofarmAddress);

        uint256 len = autofarm.poolLength();
        if (len > updatedLen) {
            for (uint256 i = updatedLen; i < len; i++) {
                (IERC20 a, , , , ) = autofarm.poolInfo(i);
                poolMapper[address(a)] = i;
                updatedLen += 1;
            }
        }
    }
}