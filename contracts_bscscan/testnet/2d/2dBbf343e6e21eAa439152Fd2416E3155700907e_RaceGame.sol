/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT
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

contract RaceGame
{
    uint256 public roundid;
    address token;
    address devwallet;

    struct Gameselect
    {
        uint256 amount;
        uint256 color;
        uint256 round;
        uint256 winningnumber;
        bool winner;
    }
    
    uint256 percentage=uint256(1);
    mapping(uint256 => mapping(address => Gameselect)) userdetails;
    mapping(address => uint256 []) listofroundid;
    mapping(address => uint256 []) userwinnerlist;
    mapping(address => mapping(uint256 => bool)) status;
    mapping(uint256 => uint256) index;

    constructor(address _tokenaddress,address _devwallet)
    {
        token = _tokenaddress;
        devwallet = _devwallet;
    }
    
    function startgame(uint256 amount,uint256 color,uint256 round) external 
    {
        require(IERC20(token).transferFrom(msg.sender,address(this),amount),"address not approve");
        roundid+=1;
        userdetails[roundid][msg.sender] = Gameselect(amount,color,round,0,false);
        listofroundid[msg.sender].push(roundid);
        uint256 rand1 = uint(keccak256(abi.encodePacked(amount,color,roundid,round,msg.sender,block.number,block.gaslimit))) % uint256(4) ;
        userdetails[roundid][msg.sender].winningnumber = rand1;
        winnergenerate(roundid,rand1);
    }

    function winnergenerate(uint256 _roundid,uint256 rand1) internal
    {
        if(rand1 == userdetails[_roundid][msg.sender].color)
        {
            userdetails[_roundid][msg.sender].winner = true;
            index[_roundid] = userwinnerlist[msg.sender].length;
            userwinnerlist[msg.sender].push(_roundid);
            status[msg.sender][_roundid] = true;
        }
    }

    function claim(uint256 _roundid) external
    {
        require(userdetails[_roundid][msg.sender].winner,"You are not winner in this round");
        require(status[msg.sender][_roundid],"You withdraw your amount");
        uint amount =(userdetails[_roundid][msg.sender].amount)*percentage;
        require(IERC20(token).transfer(msg.sender,amount),"not approve");
        status[msg.sender][_roundid] = false;
        delete userwinnerlist[msg.sender][(index[_roundid])];
    }

    function getwinningnumber(uint256 _roundid) external view returns(Gameselect memory)
    {
        return userdetails[_roundid][msg.sender];
    }

    function getuserroundid() external view returns(uint [] memory)
    {
        return listofroundid[msg.sender];
    }

    function userwinningnumberlist() external view returns(uint256 [] memory)
    {
        return (userwinnerlist[msg.sender]);
    }
    
    function withdrawtoken(uint256 amount) external
    {
        require(devwallet == msg.sender,"you are not allowed");
        require(IERC20(token).transfer(msg.sender,amount),"not transfer");
    }
    
    function setpercentage(uint256 _percentage) external
    {
       require(devwallet == msg.sender,"you are not allowed");
       percentage = _percentage;
    }

}