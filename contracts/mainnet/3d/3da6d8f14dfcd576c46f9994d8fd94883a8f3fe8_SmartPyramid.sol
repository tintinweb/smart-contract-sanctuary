pragma solidity ^0.4.24;

/**
 *  https://Smart-Pyramid.io
 *
 * Smart-Pyramid Contract
 *  - GAIN 1.23% PER 24 HOURS (every 5900 blocks)
 *  - Minimal contribution 0.01 eth
 *  - Currency and payment - ETH
 *  - Contribution allocation schemes:
 *    -- 84% payments
 *    -- 16% Marketing + Operating Expenses
 *
 *
 * You get MORE PROFIT if you withdraw later !
 * Increase of the total rate of return by 0.01% every day before the payment.
 * The increase in profitability affects all previous days!
 *  After the dividend is paid, the rate of return is returned to 1.23 % per day
 *
 *           For example: if the Deposit is 10 ETH
 * 
 *                days      |   %    |   profit
 *          --------------------------------------
 *            1 (>24 hours) | 1.24 % | 0.124 ETH
 *              10          | 1.33 % | 1.330 ETH
 *              30          | 1.53 % | 4.590 ETH
 *              50          | 1.73 % | 8.650 ETH
 *              100         | 2.23 % | 22.30 ETH
 *
 *
 * How to use:
 *  1. Send any amount of ether to make an investment
 *  2a. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re spending too much on GAS)
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time
 *
 * RECOMMENDED GAS LIMIT: 200000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 *
 * Investors Contest rules
 *
 * Investor contest lasts a whole week
 * The results of the competition are confirmed every MON not earlier than 13:00 MSK (10:00 UTC)
 * According to the results, will be determined 3 winners, who during the week invested the maximum amounts
 * in one payment.
 * If two investors invest the same amount - the highest place in the competition is occupied by the one whose operation
 *  was before
 *
 * Prizes:
 * 1st place: 2 ETH
 * 2nd place: 1 ETH
 * 3rd place: 0.5 ETH
 *
 * On the offensive (10:00 UTC) on Monday, it is necessary to initiate the summing up of the competition.
 * Until the results are announced - the competition is still on.
 * To sum up the results, you need to call the PayDay function
 *
 *
 * Contract reviewed and approved by experts!
 *
 */


library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;

        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract InvestorsStorage {
    address private owner;

    mapping (address => Investor) private investors;

    struct Investor {
        uint deposit;
        uint checkpoint;
        address referrer;
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function updateInfo(address _address, uint _value) external onlyOwner {
        investors[_address].deposit += _value;
        investors[_address].checkpoint = block.timestamp;
    }

    function updateCheckpoint(address _address) external onlyOwner {
        investors[_address].checkpoint = block.timestamp;
    }

    function addReferrer(address _referral, address _referrer) external onlyOwner {
        investors[_referral].referrer = _referrer;
    }

    function getInterest(address _address) external view returns(uint) {
        if (investors[_address].deposit > 0) {
            return(123 + ((block.timestamp - investors[_address].checkpoint) / 1 days));
        }
    }

    function d(address _address) external view returns(uint) {
        return investors[_address].deposit;
    }

    function c(address _address) external view returns(uint) {
        return investors[_address].checkpoint;
    }

    function r(address _address) external view returns(address) {
        return investors[_address].referrer;
    }
}

contract SmartPyramid {
    using SafeMath for uint;

    address admin;
    uint waveStartUp;
    uint nextPayDay;

    mapping (uint => Leader) top;

    event LogInvestment(address indexed _addr, uint _value);
    event LogIncome(address indexed _addr, uint _value, string indexed _type);
    event LogReferralInvestment(address indexed _referrer, address indexed _referral, uint _value);
    event LogGift(address _firstAddr, uint _firstDep, address _secondAddr, uint _secondDep, address _thirdAddr, uint _thirdDep);
    event LogNewWave(uint _waveStartUp);

    InvestorsStorage private x;

    modifier notOnPause() {
        require(waveStartUp <= block.timestamp);
        _;
    }

    struct Leader {
        address addr;
        uint deposit;
    }

    function bytesToAddress(bytes _source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(_source,0x14))
        }
        return parsedReferrer;
    }

    function addReferrer(uint _value) internal {
        address _referrer = bytesToAddress(bytes(msg.data));
        if (_referrer != msg.sender) {
            x.addReferrer(msg.sender, _referrer);
            x.r(msg.sender).transfer(_value / 20);
            emit LogReferralInvestment(_referrer, msg.sender, _value);
            emit LogIncome(_referrer, _value / 20, "referral");
        }
    }

    constructor(address _admin) public {
        admin = _admin;
        x = new InvestorsStorage();
    }

    function getInfo(address _address) external view returns(uint deposit, uint amountToWithdraw) {
        deposit = x.d(_address);
        if (block.timestamp >= x.c(_address) + 10 minutes) {
            amountToWithdraw = (x.d(_address).mul(x.getInterest(_address)).div(10000)).mul(block.timestamp.sub(x.c(_address))).div(1 days);
        } else {
            amountToWithdraw = 0;
        }
    }

    function getTop() external view returns(address, uint, address, uint, address, uint) {
        return(top[1].addr, top[1].deposit, top[2].addr, top[2].deposit, top[3].addr, top[3].deposit);
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest();
        }
    }

    function invest() notOnPause public payable {

        admin.transfer(msg.value * 4 / 25);

        if (x.d(msg.sender) > 0) {
            withdraw();
        }

        x.updateInfo(msg.sender, msg.value);

        if (msg.value > top[3].deposit) {
            toTheTop();
        }

        if (x.r(msg.sender) != 0x0) {
            x.r(msg.sender).transfer(msg.value / 20);
            emit LogReferralInvestment(x.r(msg.sender), msg.sender, msg.value);
            emit LogIncome(x.r(msg.sender), msg.value / 20, "referral");
        } else if (msg.data.length == 20) {
            addReferrer(msg.value);
        }

        emit LogInvestment(msg.sender, msg.value);
    }


    function withdraw() notOnPause public {

        if (block.timestamp >= x.c(msg.sender) + 10 minutes) {
            uint _payout = (x.d(msg.sender).mul(x.getInterest(msg.sender)).div(10000)).mul(block.timestamp.sub(x.c(msg.sender))).div(1 days);
            x.updateCheckpoint(msg.sender);
        }

        if (_payout > 0) {

            if (_payout > address(this).balance) {
                nextWave();
                return;
            }

            msg.sender.transfer(_payout);
            emit LogIncome(msg.sender, _payout, "withdrawn");
        }
    }

    function toTheTop() internal {
        if (msg.value <= top[2].deposit) {
            top[3] = Leader(msg.sender, msg.value);
        } else {
            if (msg.value <= top[1].deposit) {
                top[3] = top[2];
                top[2] = Leader(msg.sender, msg.value);
            } else {
                top[3] = top[2];
                top[2] = top[1];
                top[1] = Leader(msg.sender, msg.value);
            }
        }
    }

    function payDay() external {
        require(block.timestamp >= nextPayDay);
        nextPayDay = block.timestamp.sub((block.timestamp - 1538388000).mod(7 days)).add(7 days);

        emit LogGift(top[1].addr, top[1].deposit, top[2].addr, top[2].deposit, top[3].addr, top[3].deposit);

        for (uint i = 0; i <= 2; i++) {
            if (top[i+1].addr != 0x0) {
                top[i+1].addr.transfer(2 ether / 2 ** i);
                top[i+1] = Leader(0x0, 0);
            }
        }
    }

    function nextWave() private {
        for (uint i = 0; i <= 2; i++) {
            top[i+1] = Leader(0x0, 0);
        }
        x = new InvestorsStorage();
        waveStartUp = block.timestamp + 7 days;
        emit LogNewWave(waveStartUp);
    }
}