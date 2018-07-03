pragma solidity ^0.4.24;

contract EGCSnakesAndLadders {

    using SafeMath for uint;

    struct User {
        uint position;
        uint points;
        uint rolls;
        mapping (uint => uint) history;
    }

    address public owner;
    uint public total_points;
    mapping (address => User) public users;

    uint private seed;
    mapping (uint => uint) private ups;
    mapping (uint => uint) private downs;
    mapping (uint => uint) private coins;
    
    constructor() public {
        owner = msg.sender;
        total_points = 0;
        seed = 1;

        ups[11] = 17;
        ups[25] = 20;
        ups[36] = 7;
        ups[42] = 20;
        ups[53] = 20;
        ups[76] = 7;
        ups[87] = 5;

        downs[13] = 7;
        downs[23] = 7;
        downs[39] = 20;
        downs[58] = 17;
        downs[67] = 20;
        downs[74] = 20;
        downs[91] = 20;
        downs[98] = 20;
        
        coins[15] = 10;
        coins[38] = 10;
        coins[49] = 10;
        coins[55] = 10;
        coins[79] = 10;
        coins[85] = 10;
        coins[97] = 10;
    }

    function publicGetExchangeRate() view public returns (uint) {
        return calcExchangeRate();
    }

    function publicGetUserInfo(address user) view public returns (uint[4]) {
        return [
            users[user].position,
            users[user].points,
            users[user].rolls,
            users[user].points.mul(calcExchangeRate())
        ];
    }

    function publicGetUserHistory(address user, uint start) view public returns (uint[10]) {
        return [
            users[user].history[start],
            users[user].history[start.add(1)],
            users[user].history[start.add(2)],
            users[user].history[start.add(3)],
            users[user].history[start.add(4)],
            users[user].history[start.add(5)],
            users[user].history[start.add(6)],
            users[user].history[start.add(7)],
            users[user].history[start.add(8)],
            users[user].history[start.add(9)]
        ];
    }

    function userPlay() public payable {
        require(msg.value == 20 finney);

        uint random = calcRandomNumber();

        uint bonus = users[msg.sender].position.div(100);
        bonus = (bonus < 3) ? (bonus.add(1)) : 3;

        uint points = users[msg.sender].points.add(bonus);
        uint position = users[msg.sender].position.add(random);
        uint total = total_points.sub(users[msg.sender].points);

        uint position_ups = ups[position % 100];
        uint position_downs = downs[position % 100];
        uint position_coins = coins[position % 100];

        points = points.add(random);

        if (position_ups > 0) {
            position = position.add(position_ups);
            points = points.add(position_ups);
        }
        
        if (position_downs > 0) {
            position = position.sub(position_downs);
            points = points.sub(position_downs);
        }

        if (position_coins > 0) {
            points = points.add(position_coins);
        }

        if (msg.sender != owner) {
            total = total.add(1);
            users[owner].points = users[owner].points.add(1);
        }
        
        seed = random.mul(uint(blockhash(block.number - 1)) % 20);
        total_points = total.add(points);

        users[msg.sender].position = position;
        users[msg.sender].points = points;
        users[msg.sender].rolls = users[msg.sender].rolls.add(1);
        users[msg.sender].history[users[msg.sender].rolls] = random;
    }

    function userWithdraw() public {
        uint amount = users[msg.sender].points.mul(calcExchangeRate());
        require(amount > 0);

        total_points = total_points.sub(users[msg.sender].points);
        users[msg.sender].position = 0;
        users[msg.sender].points = 0;
        users[msg.sender].rolls = 0;

        msg.sender.transfer(amount);
    }

    function calcExchangeRate() view private returns (uint) {
        return address(this).balance.div(total_points);
    }

    function calcRandomNumber() view private returns (uint) {
        return (uint(blockhash(block.number - seed)) ^ uint(msg.sender)) % 6 + 1;
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}