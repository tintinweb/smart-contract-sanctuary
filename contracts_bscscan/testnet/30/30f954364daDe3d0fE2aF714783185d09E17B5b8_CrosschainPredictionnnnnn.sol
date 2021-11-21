/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface Apple {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract CrosschainPredictionnnnnn {
    
    uint public pollId;
    Apple public apple;
    address public owner;
    bool public lockStatus;
    
    struct user {
        uint depAmount;
        uint time;
        uint earnings;
        uint flag;
        bool status;
    }
    
    struct poll {
        uint startTime;
        uint endTime;
        uint predictTime;
        uint given;
        uint expect;
        uint upCount;
        uint downCount;
        uint upAmt;
        uint downAmt;
        uint poolTotalAmount;
        bool status;
    }
    
    mapping(address => mapping(uint => user)) public users;
    mapping(uint => poll) public polls;
    mapping(uint => uint)public winningAnnounce;
    
    event CreatePoll(uint id,uint start,uint end,uint predict,uint given,uint expect);
    event Poll(address indexed from,uint amount,uint pollid,uint flag,uint time);
    event Claim(address indexed from,uint amount,uint pollid,uint time);
    event FailSafe(address indexed from,uint amt,uint time);
    
    constructor (address _apple,address _owner) {
        apple = Apple(_apple);
        owner = _owner;
    }
    
     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
     /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "PICNIC: Contract Locked");
        _;
    }

    /**
     * @dev Throws if called by other contract
     */
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "PICNIC: Invalid address");
        _;
    }
    
    function createPoll (
      uint _start,
      uint _end,
      uint _given,
      uint _expect,
      uint _predictTime
    ) public isLock onlyOwner {
        pollId++;
        poll storage pools = polls[pollId];
        pools.startTime = _start;
        pools.endTime = _end;
        pools.given = _given;
        pools.expect = _expect;
        pools.predictTime = _predictTime;
        
        emit CreatePoll(pollId, _start, _end, _predictTime, _given, _expect);
    }
    
    function polling(
      uint _pollid,
      uint _amount,
      uint _flag
    ) public isLock {
         poll storage pools = polls[_pollid];
         user storage userInfo = users[msg.sender][_pollid];
         require(userInfo.status == false,"Already polled");
         require(_pollid <= pollId,"Invalid pool id");
         require(pools.startTime <= block.timestamp && pools.endTime >= block.timestamp,"Not correct time");
         require(_amount > 0 && _flag == 1 || _flag == 2,"Not correct value");
         
         if (_flag == 1) {
             pools.upCount++;
             pools.upAmt += _amount;
             userInfo.depAmount += _amount;
             userInfo.time = block.timestamp;
             userInfo.status = true;
             userInfo.flag = _flag;
         }
         
         else if (_flag == 2) {
             pools.downCount++;
             pools.downAmt += _amount;
             userInfo.depAmount += _amount;
             userInfo.time = block.timestamp;
             userInfo.status = true;
             userInfo.flag = _flag;
         }
         apple.transferFrom(msg.sender,address(this),_amount);
         pools.poolTotalAmount += _amount;
         
         emit Poll(msg.sender, _amount, _pollid, _flag, block.timestamp);
    }
    
    function draw(
         uint _pollid,
         uint _decision
         ) public onlyOwner {
         poll storage pools = polls[_pollid];
         require(_decision == 1 || _decision == 2,"Wrong decision");
         require(pools.status == false,"Already drawed");
         require(block.timestamp >= pools.predictTime,"Predict time left");
        
         if (_decision == 1) {
             winningAnnounce[_pollid] = 1;
         }
         
         else if (_decision == 2) {
             winningAnnounce[_pollid] = 2;
         }
         pools.status = true;
    }
    
    function getResult(
        uint _poolid,
        address _user
        ) public view returns(uint) {
         require(_poolid <= pollId,"Invalid pool id");
         poll storage pools = polls[_poolid];
         user storage userInfo = users[_user][_poolid];
         //require(!userInfo.status == false ,"user already claimed");
         require(pools.status == true,"Not yet closed");
         require(userInfo.depAmount > 0 ,"Not yet deposit");
        
    

         if (winningAnnounce[_poolid] == userInfo.flag) {

             uint percent = (userInfo.depAmount*100/pools.poolTotalAmount)*1e18;
             return  pools.poolTotalAmount*percent/100e18;
         }
         else return 0;
    }
    
    function claim (
        uint _poolid
        ) public isLock {
        poll storage pools = polls[_poolid];
        user storage userInfo = users[msg.sender][_poolid];
        require(pools.status == true,"Not yet closed");
        require(_poolid <= pollId,"Invalid pool id");  
        
            if(userInfo.status == true) {
                require(getResult(_poolid,msg.sender) > 0,"No amount for this user");
                apple.transfer(msg.sender,getResult(_poolid,msg.sender));
                userInfo.status = false;
                emit Claim( msg.sender,getResult(_poolid,msg.sender) , _poolid, block.timestamp);
            }
            else
            {
                revert("User Already Claimed");
            }
        }
     
    /**
     * @dev failSafe: Withdraw BNB
     */
    function failSafe(address  _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "PICNIC: Invalid Address");
        require(apple.balanceOf(address(this)) >= _amount, "PICNIC: Insufficient balance");
        apple.transfer(_toUser,_amount);
        emit FailSafe(_toUser, _amount, block.timestamp);
        return true;
    }

    /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }   
    
}