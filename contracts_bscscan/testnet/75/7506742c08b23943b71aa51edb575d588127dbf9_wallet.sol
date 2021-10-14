/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity ^0.6.2;
// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
      

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract wallet{
   
    bool public contract_is_active;
    address[4] public boardMember;
    address public dev_address;
    mapping(address =>mapping(uint256=>uint256)) public allowed_amount;

  
    
 
    constructor( address member_1, address member_2, address member_3, address member_4) public {
        boardMember[0] = member_1;
        boardMember[1] = member_2;
        boardMember[2] = member_3;
        boardMember[3] = member_4;
        dev_address = msg.sender;

    }
    
    function vote (address _to, uint256 _amount) public{
        dev_address = msg.sender;
        if(boardMember[0]== msg.sender){
            allowed_amount[_to][0]=_amount;
            return();
        }
        if(boardMember[1]== msg.sender){
            allowed_amount[_to][1]=_amount;
            return();
        }
        if(boardMember[2]== msg.sender){
            allowed_amount[_to][2]=_amount;
            return();
        }
        if(boardMember[3]== msg.sender){
            allowed_amount[_to][3]=_amount;
            return();
        }
        revert();
        
    }
    
    function check_allowence (address _to, uint256 _amount) public view returns(bool){
        
        uint256 approved_vote = 0;
        if(allowed_amount[_to][0]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[_to][1]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[_to][2]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[_to][3]>= _amount){
            approved_vote+=1;
           
        }
        
       if (approved_vote>=3){
           return(true);
       }
    
        return(false);
            
        
    }
    
    function transferToken (address token_contract_address, address _to, uint256 _amount) public{
        require(msg.sender == dev_address);
        require(check_allowence(_to, _amount) == true);
        allowed_amount[_to][0]=0;
        allowed_amount[_to][1]=0;
        allowed_amount[_to][2]=0;
        allowed_amount[_to][3]=0;
                             
        IERC20(token_contract_address).transfer(_to, _amount);
    }
}