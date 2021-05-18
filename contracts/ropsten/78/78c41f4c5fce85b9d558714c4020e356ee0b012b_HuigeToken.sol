/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity >=0.6.0 <0.8.0;

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

contract HuigeToken is IERC20 {
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;

    uint _totalSupply = 10e18 * 210000;
    
    constructor(){
        _balances[msg.sender] = _totalSupply;
    }
    
    function decimals()  public pure returns (uint8){
        return 18;
    }

    function name()  public pure returns ( string memory){
        return "HuiGe Token";
    }
    
    function symol()  public pure returns ( string memory){
        return "HGT";
    }
    
    
    function totalSupply() external override view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256){
        return _balances[account];
    }

    function allowance(address owner, address spender) external override  view returns (uint256){
        return _allowances[owner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool){
        require(_balances[sender] >= amount);
        _balances[sender]-=amount;
        _balances[recipient]+=amount;
        emit Transfer(sender,recipient,amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override  returns (bool){
        return _transfer(msg.sender,recipient,amount);

    }


    function approve(address spender, uint256 amount) external override  returns (bool){
        
        _allowances[msg.sender][spender] += amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override  returns (bool){
        require(_allowances[sender][msg.sender] >= amount);
        _allowances[sender][msg.sender] -= amount;
        return _transfer(sender,recipient,amount);
        
    }


}