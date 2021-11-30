// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0; 

import './IERC20.sol';
import './safeMath.sol';
import './Irelation.sol';

contract Receive {   
    using SafeMath for uint; 

    struct Msg{
        int256 unlocked;
        uint256 locked;
        uint256 lockTime;
    }

    mapping(address => Msg) public userMsg;
    mapping(address => bool) public mine;
    address public owner;

    address public Relation;

    uint256 public LOCK_DURATION;

    uint256 public blockNumber;
    int256 public award;

    mapping (address => uint256) public relationAward;
    mapping (address => uint256) public relationAwarded;

    constructor () public {
        owner = msg.sender;
        LOCK_DURATION = 100;
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner,'who are you');
        _;
    }
    
    function setRelation(address _addr) public ownerOnly{
        Relation = _addr;
    }

    function setMine(address _mine,bool _bol) public ownerOnly{
        mine[_mine] = _bol;
    }

    // function updata(address _user,uint256 _amount) internal {
    //     Msg storage lt = userMsg[_user];
    // }

    function add(address _user,uint256 _amount) public {
        require(mine[msg.sender] , 'error address');
        Msg storage lt = userMsg[_user]; 
        uint256 _now = blockNumber;
        if (_now < lt.lockTime + LOCK_DURATION) {
            uint256 amount = lt.locked * (_now - lt.lockTime)
                / LOCK_DURATION;
            lt.locked = lt.locked - amount + _amount;
            lt.unlocked += int256(amount);
        } else {
            lt.unlocked += int256(lt.locked);
            lt.locked = _amount;
        }
        lt.lockTime = _now;
    }

    function getAward() public {
        Msg storage lt = userMsg[msg.sender];
        int256 available = lt.unlocked;
        uint256 _now = blockNumber;
        if (_now < lt.lockTime + LOCK_DURATION) {
            available += int256(lt.locked * (_now - lt.lockTime)
                / LOCK_DURATION);
        } else {
            available += int256(lt.locked);
        }
        require(available > 0, "no token available");
        lt.unlocked -= available;
        // 发奖励 award 添加20转账发放
        award = available;

        if( Irelation(Relation).up(msg.sender) != address(0) ){
            // address up = Irelation(Relation).up(msg.sender);
            // relationAward[up] = relationAward[up].add(uint256(award)); 添加比例
        }
    }

    function changeNumber(uint256 _blockNumber) public {
        blockNumber = _blockNumber;
    }

    function getRelationAward() public {
        // relationAward[msg.sender].sub(relationAwarded[msg.sender]) 转账金额
        relationAwarded[msg.sender] = relationAward[msg.sender];
    }

}