pragma solidity ^0.4.26;

contract yunyunsite{
    struct yunyun{
        int points;
        uint signAt;
    }
    
    event signRecords(address,uint);
    mapping(address => yunyun) public yun;
    
    
    // modifier checkSignAt(address _address){
    //     require(now > yun[_address].signAt + 1 days , "一天只能簽到一次!");
    //     _;
    // }
    
    modifier checkPointEnough(int256 point){
        require(yun[msg.sender].points >= point , "點數不夠啦!");
        _;
    }
    
    function sign() public {
        yun[msg.sender].points += 1;
        yun[msg.sender].signAt = now;
        emit signRecords(msg.sender,now);
    }
    
    function exchange(int256 point) public checkPointEnough(point){
        yun[msg.sender].points -= point;
    }
    
    
    
}

