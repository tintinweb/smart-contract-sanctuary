/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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

contract PrivateSale
{
    event Buy(
        address indexed _buyer,
        uint _ethValue,
        uint _shellAmount
    );
    
    IERC20 public shellToken;
    address payable public owner;
    
    uint public BNB = 1 ether;
    uint public shellTotalSupply = 10**27;
    uint public BNBRaised = 0;
    
    bool public open = false;
    
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = payable(newOwner);
    }
    
    constructor(address _token)
    {
        shellToken = IERC20(_token);
        owner = payable(msg.sender);
    }
    
    function setOpen(bool _open) 
    external
    {
        
        require(msg.sender == owner, "Only owner!");
        open = _open;
    }
    
    function deposit(uint256 _amount)
    external
    {
        require(shellToken.transferFrom(msg.sender, address(this), _amount));
    }
    
    function flushEther(uint amount)
    external
    {
        if(amount == 0 || amount > address(this).balance)
        {
            amount = address(this).balance;
        }   
        owner.transfer(amount);
    }
    
    function flushShell(uint amount)
    external
    {
        if(amount == 0 || amount > address(this).balance)
        {
            amount = shellToken.balanceOf(address(this));
        }
        require(shellToken.transfer(owner, amount), "BEP20_TRANSFER_FAILED");
    }
    
    function marketCap() 
    external view
    returns(uint)
    {
        return _marketCap();
    }
    
    function _marketCap() 
    internal view
    returns(uint)
    {
        return 20000 * BNB; 
    }
    
    function tokenForEthAmount(uint ethAmount)
    external view
    returns(uint)
    {
        return shellTotalSupply * ethAmount/ _marketCap();
    }
    
    receive() external payable
    {
        require(open, "The sale is closed");
        
        uint tokenAmount = shellTotalSupply * msg.value/ _marketCap();
        
        require(shellToken.transfer(msg.sender, tokenAmount), "BEP20_TRANSFER_FAILED");
        
        BNBRaised += msg.value;
        
        emit Buy(msg.sender, msg.value, tokenAmount);
    }
}