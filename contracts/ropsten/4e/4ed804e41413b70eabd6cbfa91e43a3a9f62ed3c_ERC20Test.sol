/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.5.16;


interface ERC20 {
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

contract ERC20Test{
     address contractAddress = address(this);
    address ownerAddress;
    
    ERC20 _token;
    
    constructor(address tokenaddress) public{
        ownerAddress = msg.sender;
        _token = ERC20(tokenaddress);
    }
    
 function deposit(uint _amount)public {
      require(_token.balanceOf(msg.sender) >= _amount, "insufficient balance");
        require(_token.allowance(msg.sender, address(this)) >= _amount, "insufficient allowance");
            require(_token.transferFrom(msg.sender, address(this), _amount), "winning reward transfer failed");
   }
  
  function withdraw(uint _amount,address _toaddress) public returns (bool){
      address _user = msg.sender;
      require(_user == ownerAddress);
      require(_token.balanceOf(contractAddress) >= _amount, "insufficient balance");
      _token.transfer(_toaddress,_amount);
      return true;
  }
  
   function contractBalance() public view returns(uint){
      
      return _token.balanceOf(contractAddress);
  }
}