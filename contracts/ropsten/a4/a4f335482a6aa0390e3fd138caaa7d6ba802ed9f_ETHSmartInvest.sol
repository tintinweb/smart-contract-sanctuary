pragma solidity ^0.4.24;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

contract ETHSmartInvest {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED   = 10000;
    uint256 constant public INTEREST      = 330;
    uint256 constant public MARKETING_FEE = 800;
    uint256 constant public ADMIN_FEE     = 200;
    uint256 constant public ONE_DAY       = 1 days;
    uint256 constant public MINIMUM       = 0.01 ether;

    uint256[] public referralPercents     = [200, 100, 50, 25, 10];

    struct User {
        uint256 time;
        uint256 deposit;
        uint256 reserve;
        address referrer;
        uint256 bonus;
    }

    address public marketing = 0x0;
    address public admin = 0x0;
    
    mapping(address => User) public users;

    event InvestorAdded(address indexed investor, uint256 amount);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositIncreased(address indexed investor, uint256 amount, uint256 totalAmount);
    event DividendsPayed(address indexed investor, uint256 amount);
    event RefBonusPayed(address indexed investor, uint256 amount);
    event RefBonusAdded(address indexed investor, address indexed referrer, uint256 amount, uint256 indexed level);

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest();
        }
    }

    function invest() public payable {
        require(msg.value >= MINIMUM);
        marketing.transfer(msg.value * MARKETING_FEE / ONE_HUNDRED);
        admin.transfer(msg.value * ADMIN_FEE / ONE_HUNDRED);

        if (users[msg.sender].deposit > 0) {
            saveDividends();
            emit DepositIncreased(msg.sender, msg.value, users[msg.sender].deposit + msg.value);
        } else {
            emit InvestorAdded(msg.sender, msg.value);
        }

        users[msg.sender].deposit += msg.value;
        users[msg.sender].time = block.timestamp;

        if (users[msg.sender].referrer != 0x0) {
            refSystem();
        } else if (msg.data.length == 20) {
            addReferrer();
        }
    }


    function withdraw() public {
        uint256 payout = getDividends(msg.sender);
        emit DividendsPayed(msg.sender, payout);

        if (getRefBonus(msg.sender) != 0) {
            payout += getRefBonus(msg.sender);
            emit RefBonusPayed(msg.sender, getRefBonus(msg.sender));
            users[msg.sender].bonus = 0;
        }

        require(payout >= MINIMUM);

        if (users[msg.sender].reserve != 0) {
            users[msg.sender].reserve = 0;
        }

        users[msg.sender].time += (block.timestamp.sub(users[msg.sender].time)).div(ONE_DAY).mul(ONE_DAY);

        msg.sender.transfer(payout);
    }

    function bytesToAddress(bytes source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(source,0x14))
        }
        return parsedReferrer;
    }

    function addReferrer() internal {
        address refAddr = bytesToAddress(bytes(msg.data));
        if (refAddr != msg.sender) {
            users[msg.sender].referrer = refAddr;

            refSystem();
            emit ReferrerAdded(msg.sender, refAddr);
        }
    }

    function refSystem() internal {
        address first = users[msg.sender].referrer;
        users[first].bonus += msg.value * referralPercents[0] / ONE_HUNDRED;
        emit RefBonusAdded(msg.sender, first, msg.value * referralPercents[0] / ONE_HUNDRED, 1);
        address second = users[first].referrer;
        if (second != address(0)) {
            users[second].bonus += msg.value * referralPercents[1] / ONE_HUNDRED;
            emit RefBonusAdded(msg.sender, second, msg.value * referralPercents[1] / ONE_HUNDRED, 2);
            address third = users[second].referrer;
            if (third != address(0)) {
                users[third].bonus += msg.value * referralPercents[2] / ONE_HUNDRED;
                emit RefBonusAdded(msg.sender, third, msg.value * referralPercents[2] / ONE_HUNDRED, 3);
                address fourth = users[third].referrer;
                if (fourth != address(0)) {
                    users[fourth].bonus += msg.value * referralPercents[3] / ONE_HUNDRED;
                    emit RefBonusAdded(msg.sender, fourth, msg.value * referralPercents[3] / ONE_HUNDRED, 4);
                    address fifth = users[fourth].referrer;
                    if (fifth != address(0)) {
                        users[fifth].bonus += msg.value * referralPercents[4] / ONE_HUNDRED;
                        emit RefBonusAdded(msg.sender, fifth, msg.value * referralPercents[4] / ONE_HUNDRED, 5);
                    }
                }
            }
        }
    }

    function saveDividends() internal {
        uint256 dividends = (users[msg.sender].deposit.mul(INTEREST).div(ONE_HUNDRED)).mul(block.timestamp.sub(users[msg.sender].time)).div(ONE_DAY);
        users[msg.sender].reserve += dividends;
    }

    function getDividends(address userAddr) public view returns(uint256) {
        return (users[userAddr].deposit.mul(INTEREST).div(ONE_HUNDRED)).mul((block.timestamp.sub(users[userAddr].time)).div(ONE_DAY)).add(users[userAddr].reserve);
    }

    function getRefBonus(address userAddr) public view returns(uint256) {
        return users[userAddr].bonus;
    }

    function getNextTime(address userAddr) public view returns(uint256) {
        return (block.timestamp.sub(users[userAddr].time)).div(ONE_DAY).mul(ONE_DAY).add(users[userAddr].time).add(ONE_DAY);
    }

}