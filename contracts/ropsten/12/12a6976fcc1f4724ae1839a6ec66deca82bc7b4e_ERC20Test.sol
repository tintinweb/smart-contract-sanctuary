/**
 *Submitted for verification at Etherscan.io on 2021-02-18
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
    
    constructor() public{
        ownerAddress = msg.sender;
    }
    
    struct userDet{
        uint _userAmt;
        uint _time;
    }
    
    mapping(address => mapping(address => userDet))public users;
    
    event DepDetail(address indexed _usersAdd, uint _userAmt,  uint _time);
    
    function deposit( address tokenaddress, uint _amount) public {
        require(ERC20(tokenaddress).balanceOf(msg.sender) >= _amount, "insufficient balance");
        require(ERC20(tokenaddress).allowance(msg.sender, address(this)) >= _amount, "insufficient allowance");
        
        require(ERC20(tokenaddress).transferFrom(msg.sender, address(this), _amount));
        
        users[msg.sender][tokenaddress]._userAmt += _amount;
        users[msg.sender][tokenaddress]._time = now;
        
        emit DepDetail(msg.sender,_amount,now);
    }
    
    function withdraw(uint _amount,address _toaddress,address tokenaddress) public returns (bool){
        address _user = msg.sender;
        
        require(_user == ownerAddress);
        require(ERC20(tokenaddress).balanceOf(contractAddress) >= _amount, "insufficient balance");
        
        ERC20(tokenaddress).transfer(_toaddress,_amount);
        
        return true;
    }
    
    function contractTokenBalance(address tokenaddress) public view returns(uint){
        return  ERC20(tokenaddress).balanceOf(contractAddress);
    }

}