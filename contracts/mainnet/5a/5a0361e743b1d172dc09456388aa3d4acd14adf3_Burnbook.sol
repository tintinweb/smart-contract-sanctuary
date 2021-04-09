/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

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

abstract contract ApproveAndCallFallBack {
       function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public virtual;
  }
  


contract Burnbook is ApproveAndCallFallBack{
        
    address _burn_address = address(0x0);
    
    mapping(address => mapping(address=>uint256)) burnedTokens;
    
    constructor(){
 
    }
    
    event tokensBurned(address from, address token, uint256 tokens);
    
    
    function burnTokens(address from, address token, uint256 tokens) public returns (bool){
        
        IERC20(token).transferFrom(from,_burn_address,tokens);
        
        burnedTokens[from][token] = burnedTokens[from][token] + tokens;
        
        emit tokensBurned(from,token,tokens);
        
        return true;
    }
    
    function getBurnedTokensAmount(address burner, address token) public view returns (uint) {
        
        return burnedTokens[burner][token];
    }
    
    
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public override{
        burnTokens(from,token,tokens);
    }
    
    
    
    
    
}