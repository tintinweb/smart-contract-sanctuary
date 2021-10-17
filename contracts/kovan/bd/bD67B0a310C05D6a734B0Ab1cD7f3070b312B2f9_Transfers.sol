/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

// SPDX-License-Identifier: piliang
pragma solidity ^0.6.12;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
     function decimals() external view returns (uint256);

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

contract Transfers {
    address public dev_address;
    mapping(address => uint256) public tokenBalanceOf;
    mapping(address => uint256) public BuytokenBalanceOf;
    bool public claimBool;
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, bool isContribution);
    address[] public tokens;

    constructor (
    ) public {
        dev_address = msg.sender;
    }

    function setTokenAddress(address tokenNew)public {
        tokens.push(tokenNew);
        IERC20(tokenNew).transferFrom(msg.sender,address(this),1000000*10**(IERC20(tokenNew).decimals()));
    }


    
   function  setClaim(bool bools) public{
        require(msg.sender==dev_address,"No call permission");
        claimBool=bools;
   }


    function claim() public  {
        require(claimBool==true,"claim is not start");
        require(tokenBalanceOf[msg.sender]<=0,"Cannot be obtained more than once");
        for(uint256 i=0;i<tokens.length;i++){
            IERC20(tokens[i]).transfer(msg.sender, 100000*10**(IERC20(tokens[i]).decimals()));
        tokenBalanceOf[msg.sender]+=100000*10**(IERC20(tokens[i]).decimals());
        }
        
    }

      function batchTransfer(address[] calldata _to, uint _value) public{
    require(_to.length > 0,"length is 0");
    for(uint i=0;i<_to.length;i++)
    {
       for(uint256 j=0;j<tokens.length;j++){
            IERC20(tokens[j]).transfer(_to[i], _value*10**(IERC20(tokens[j]).decimals()));
        tokenBalanceOf[_to[i]]+=_value*10**(IERC20(tokens[j]).decimals());
        }
     }
}
    
}