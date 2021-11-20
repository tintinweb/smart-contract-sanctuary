/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: UNLICENSED

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

// File: BeachCollectiveT.sol


pragma solidity >=0.7.0 <0.9.0;
// pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


pragma solidity >=0.7.0 <0.9.0;
// pragma solidity ^0.8.0;


contract TestFunding{
    mapping(address => uint) public users;
    // address public admin;
    // uint public minimumDeposit;
    uint public totalDeposit;
    uint public noOfUsers;
    // address b_token_address = 0xC6B11aBd15508313d0fc25003068fd0C6F100653;
    // IERC20 B_tokenContract = IERC20(b_token_address);

    IERC20 private _token;
    
    event deposit_token(address indexed owner, address indexed spender, uint256 value);
    event withdraw_token(address indexed withdrawer, uint256 value);


    constructor(IERC20 token){
        _token = token;
    }

    function depositToken(uint amount) public {
        require(amount > 0, "You need to sell at least some tokens");

        if(users[msg.sender] == 0){
            noOfUsers++;
        }
        // _token.allowance(msg.sender, address(this));
        // require(allowance >= amount, "Check the token allowance");
        // _token.transferFrom(msg.sender, address(this), amount);
        // _token.transfer(address(this), amount);
        
        _token.approve(address(this),amount);
        _token.transferFrom(msg.sender, address(this), amount);

        // B_tokenContract.increaseAllowance(address(this), amount);
        // B_tokenContract.transfer(address(this), amount);

        users[msg.sender]+=amount;
        totalDeposit  += amount;
        // emit deposit_token(msg.sender, address(this),amount);

    }


    function getUserBalance() public view returns(uint)
    {
     return users[msg.sender];
    }

    // function getCurrentUser() public view returns(address)
    // {
    //  return msg.sender;
    // }

    function withdrawToken(uint amount) public
    {
    require(users[msg.sender]>0,'Your are not Deposit any token');
    require(users[msg.sender] >= amount,'Your withdraw is exeeds your token Deposit');
    address payable user = payable(msg.sender);
    user.transfer(amount);
    totalDeposit -= amount;
    users[msg.sender] -= amount;
    // emit withdraw_token(msg.sender,amount);

    }

}