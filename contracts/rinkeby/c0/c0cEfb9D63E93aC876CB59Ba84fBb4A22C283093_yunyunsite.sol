pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;

contract yunyunsite {
    int256 exchangeNo = 0;
    int256 public signDays = 0;
    int256 public totalDays = 0;
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
    event lotteryRecords(uint256, string);
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
        totalDays += 1;
        emit signRecords(msg.sender, now);
    }

    function _addReward(int256 eNo, string _name) private {
        rewards.push(Reward(eNo, _name, now, false));
    }

    function exchange(int256 _point, string _name) public {
        exchangeNo += 1;
        _addReward(exchangeNo, _name);
        yun[msg.sender].points -= _point;
    }

    function lottery(string _name) public {
        exchangeNo += 1;
        _addReward(exchangeNo, _name);
        emit lotteryRecords(now, _name);
    }

    function changeRewardState(uint256 _index) public {
        rewards[_index].state = true;
    }

    function initSignDays() public checkSignDays(signDays) {
        signDays = 0;
    }

    function extraPoints(int256 _points, string _name) public {
        yun[msg.sender].points += _points;
        emit lotteryRecords(now, _name);
    }

    function getAllReward() public view returns (Reward[] memory) {
        return rewards;
    }
}

