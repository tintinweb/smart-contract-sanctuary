pragma solidity ^0.4.26;

contract yunyunsite {
    int256 exchangeNo = 0;
    int256 public signDays = 0;
    bool public lottery = false;
    struct yunyun {
        int256 points;
        uint256 signAt;
    }

    struct Reward {
        int256 id;
        string name;
        uint256 exchangeAt;
        bool state;
    }

    Reward[] public rewards;

    event signRecords(address, uint256);

    mapping(address => yunyun) public yun;

    modifier checkSignDays(int256 day) {
        require(day >= 5);
        _;
    }

    // modifier checkSignAt(address _address){
    //     require(now > yun[_address].signAt + 1 days , "一天只能簽到一次!");
    //     _;
    // }

    modifier checkPointEnough(int256 point) {
        require(yun[msg.sender].points >= point, "點數不夠啦!");
        _;
    }

    function sign() public {
        yun[msg.sender].points += 1;
        yun[msg.sender].signAt = now;
        signDays += 1;
        emit signRecords(msg.sender, now);
    }

    function exchange(int256 _point, string _name) public {
        exchangeNo += 1;
        rewards.push(Reward(exchangeNo, _name, now, false));
        yun[msg.sender].points -= _point;
    }

    function changeRewardState(uint256 _index) public {
        rewards[_index].state = true;
    }

    function checkLotteryState() public checkSignDays(signDays) {
        lottery = true;
    }

    function changeLotteryState() public checkSignDays(signDays) {
        lottery = false;
        signDays = 0;
    }
}

