/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

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

contract StreamerContractV1{

    address private owner;
    address private free1Add;
    address private free2Add;
    bool public running;
    constructor() {
        owner = msg.sender;
        free1Add = 0x2CD3Fe9dD27A0dda831aBeb908d746E2335b431E; //Z
        free2Add = 0x13C74162B334b2B41A43d3A9C584e1451952bb29; //C
        running = true;
        
        
    }

    receive() external payable {}

    function Donate(address payable _to) public payable {
    if(running == true){
        uint amount = msg.value;
        uint amount_host = (amount * 5)/100; // 5
        uint amount_fee_1 = (amount_host * 65)/100;  // 3.25
        address(uint160(free1Add)).transfer(amount_fee_1); // Z 3.25
        uint amount_fee_2 = (amount_host * 35)/100; // 1.75
        address(uint160(free2Add)).transfer(amount_fee_2); // C 1.75
        uint payload = (amount * 95)/100; // 95
        _to.transfer(payload);
     } 
}
     
    modifier restricted() {
         if (msg.sender == owner)_;
     }
     
     function getOwner() external view returns (address) {
        return owner;
    }
     

    function withdraw(uint amount) public  {
          if (msg.sender == owner){
            uint acc2 =  amount / 2; 
            address(uint160(free1Add)).transfer(acc2);
            address(uint160(free2Add)).transfer(acc2);
          }
     } 
    
    function Contect__balance() view public returns (uint){
          if (msg.sender == owner){
              return address(this).balance;
          }else{
              return 0;
          }
     } 
     
     
     function change_status(bool state_status) public{
          if (msg.sender == owner){
              running = state_status;
          }
     } 
     
   
    
    function checkBal(address _token) public view returns(uint) {
         if (msg.sender == owner){
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
         }else{
             return 101010101010;
         }
    }
    
    function withdrawErc20(address _token) public {
       if (msg.sender == owner){
           IERC20 token = IERC20(_token);
           uint acc2 =  token.balanceOf(address(this)) / 2; 
           IERC20(token).transfer(free1Add, acc2);
           IERC20(token).transfer(free2Add, acc2);
       }
    }
  
     
    // function destory() public {
    //     if (msg.sender == owner){
    //          selfdestruct(payable(owner));
    //     }
    // }
     
   

}