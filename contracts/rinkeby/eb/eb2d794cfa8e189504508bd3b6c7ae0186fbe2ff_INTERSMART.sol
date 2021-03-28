/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity 0.5.10;

contract INTERSMART {

    address public owner = address(0);

    uint256 public price = 0.10 ether;
    uint256 public fee   = 0.02 ether;

    uint256[] deposits = [
        0.08 ether,
        1.28 ether,
        10.24 ether,
        40.96 ether
    ];

    uint256 public refLimit = 2;

    uint256[] public stageLimits = [7, 7, 8, 10];

    struct User {
        address partner;
        address[] partners;
        uint256 overflowIdx;
        uint256 profit;
        mapping (uint256 => uint256) ids;
        mapping (uint256 => uint256) rounds;
        mapping (uint256 => mapping (uint256 => uint256)) lastLine;
    }

    mapping (address => User) internal _users;
    mapping (uint256 => mapping (uint256 => address)) internal _userByid;
    mapping (uint256 => uint256) internal _amountOfUsers;
    uint256 internal _startDate;

    address payable internal _wallet;

    event getIn(address indexed referral, address indexed partner, address indexed referrer, uint256 price);
    event getOut(address indexed account, uint256 profit);
    event withdrawn(address indexed account, uint256 amount);
    event stageUp(address indexed account, uint256 stage);
    event reinvest(address indexed account, uint256 stage);
    event payOut(address indexed referrer, address indexed referral, uint256 stage, uint256 round, uint256 amount);
    event qualification(address indexed referrer);

    constructor(address payable walletAddr) public {
        require(walletAddr != address(0));
        require(!_isContract(walletAddr), 'walletAddr cannot be a smart-contract');

        _wallet = walletAddr;
        User storage user = _users[_wallet];

        for (uint256 i = 0; i < 4; i++) {
            user.rounds[i] = stageLimits[i];
            _amountOfUsers[i]++;
            _users[_wallet].ids[i] = _amountOfUsers[i];
            _userByid[i][_users[_wallet].ids[i]] = _wallet;
        }

        _startDate = block.timestamp;
    }

    function() external payable {
        if (msg.value == 0) {

            withdraw();

        } else if (msg.value >= price) {

            if (msg.value > price) {
                msg.sender.transfer(msg.value - price);
            }

            if (!isRegistered(msg.sender)) {
                regUser(_bytesToAddress(bytes(msg.data)), msg.sender);
            } else {
                revert('User is registered already');
            }

        } else revert('Incorrect value');
    }

    function regUser(address referrerAddr, address msgsender) public payable {
        require(!isRegistered(msgsender), 'User is registered already');
        require(isRegistered(referrerAddr), 'User must provide an active referrer address');
        require(msg.value >= price, 'Value must be equal to the price');

        User storage user = _users[msgsender];
        address referrer = referrerAddr;

        _wallet.transfer(fee);

        _amountOfUsers[0]++;

        _users[referrer].partners.push(msgsender);
        if (getUserAmountOfPartners(referrer) == refLimit) {
            emit qualification(referrer);
        }

        user.partner = referrer;

        (uint256 newID, uint256 overflowIdx, address freeReferrer) = getFreeReferrer(referrer);
        _users[referrer].overflowIdx = overflowIdx;

        user.ids[0] = newID;
        _userByid[0][user.ids[0]] = msgsender;

        emit getIn(msgsender, user.partner, freeReferrer, price);

        _processStructure(msgsender, 0);

    }

    function withdraw() public {
        uint256 amount = getUserProfit(msg.sender);

        require(amount > 0, 'User has no profit yet');
        require(getUserAmountOfPartners(msg.sender) >= 2, 'User did not invite 2 referrals yet');

        _users[msg.sender].profit = 0;
        msg.sender.transfer(amount);

        emit withdrawn(msg.sender, amount);
    }

    function _processStructure(address account, uint256 stage) internal {

        _users[account].rounds[stage]++;

        emit stageUp(account, stage);

        uint256 deposit = deposits[stage];
        uint256 full = 64 / 2**(stage);
        uint256 round = _users[account].rounds[stage];
        uint256 stageUpIdx;
        uint256 profit;
        uint256 reinvestIdx;

        if (round == 1) {
            if (stage < 3) {
                stageUpIdx = full / 4;
                profit = deposit * (stageUpIdx - 1);
            } else {
                stageUpIdx = 0;
                profit = deposit * 3;
            }
            reinvestIdx = stageUpIdx+1;
        } else {
            stageUpIdx = 0;
            profit = deposit;
            if (round < stageLimits[stage]) {
                reinvestIdx = full / 4 + 1;
            } else {
                reinvestIdx = 0;
            }
        }

        address rootAddr = getUserReferrer(account, stage, 4-stage);

        if (rootAddr != address(0) && rootAddr != _wallet) {

            _users[rootAddr].lastLine[stage][round]++;

            if (_users[rootAddr].lastLine[stage][round] == stageUpIdx) {

                _amountOfUsers[stage+1]++;
                _users[rootAddr].ids[stage+1] = _amountOfUsers[stage+1]; ///
                _userByid[stage+1][_amountOfUsers[stage+1]] = rootAddr;
                _processStructure(rootAddr, stage+1);

            } else if (_users[rootAddr].lastLine[stage][round] == reinvestIdx) {

                _processStructure(rootAddr, stage);

            } else if (round == 1 && _users[rootAddr].lastLine[stage][round] == full/2) {

                _users[rootAddr].profit += profit;
                emit payOut(rootAddr, account, stage, round, profit);

            } else if (round > 1) {

                _users[rootAddr].profit += profit;
                emit payOut(rootAddr, account, stage, round, profit);

            }

        } else {
            _users[_wallet].profit += deposit;
        }

    }

    function getFreeReferrer(address referrer) public view returns(uint256 newID, uint256 overflowIdx, address freeReferrer) {
        require(isRegistered(referrer), "User is not registered yet");
        if (getUserAmountOfReferrals(referrer, 0) < 2) {
            return (_users[referrer].ids[0] * 2 + getUserAmountOfReferrals(referrer, 0), getUserAmountOfReferrals(referrer, 0) + 1, referrer);
        }

        overflowIdx = _users[referrer].overflowIdx;
        uint256 startIdx = _users[referrer].ids[0] * 2;
        uint256 addend = overflowIdx;
        uint256 line = 1;
        uint256 count;

        while (true) {
            if (addend > 0) {
                if (addend >= 2**line) {
                    addend -= 2**line;
                    startIdx = startIdx * 2;
                    line++;
                } else {
                    count += addend;
                    addend = 0;
                }
            } else if (startIdx + count < startIdx + 2**line) {
                if (_userByid[0][startIdx + count] == address(0)) {
                    return (startIdx + count, overflowIdx + 1, _userByid[0][(startIdx + count) / 2]);
                } else {
                    overflowIdx++;
                    count++;
                }
            } else {
                startIdx = startIdx * 2;
                count = 0;
                line++;
            }
        }
    }

    function _bytesToAddress(bytes memory source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(source,0x14))
        }
        return parsedReferrer;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getAmountOfUsers(uint256 stage) public view returns(uint256) {
        return _amountOfUsers[stage];
    }

    function getDaysSinceStart() public view returns(uint256) {
        if (_startDate > 0) {
            return ((block.timestamp - _startDate) / (1 days));
        }
    }

    function isRegistered(address account) public view returns(bool) {
        return (_users[account].rounds[0] > 0);
    }

    function getUserId(address user, uint256 stage) public view returns(uint256) {
        return _users[user].ids[stage];
    }

    function getUserById(uint256 stage, uint256 id) public view returns(address) {
        return _userByid[stage][id];
    }

    function getUserReferrer(address account, uint256 stage, uint256 level) public view returns(address) {
        return _userByid[stage][_users[account].ids[stage] / 2**(level+1)];
    }

    function getUserReferrers(address account, uint256 stage) public view returns(address[] memory) {
        uint256 limit = 5 - stage;
        address[] memory referrers = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            referrers[i] = getUserReferrer(account, stage, i);
        }
        return referrers;
    }

    function getUserPartners(address account) public view returns(address[] memory) {
        return _users[account].partners;
    }

    function getUserAmountOfPartners(address account) public view returns(uint256) {
        return _users[account].partners.length;
    }

    function getUserReferrals(address account, uint256 stage) public view returns(address, address) {
        return (_userByid[stage][_users[account].ids[stage] * 2], _userByid[stage][_users[account].ids[stage] * 2 + 1]);
    }

    function getUserAmountOfReferrals(address account, uint256 stage) public view returns(uint256) {
        if (_userByid[stage][_users[account].ids[stage] * 2 + 1] != address(0)) {
            return 2;
        } else if (_userByid[stage][_users[account].ids[stage] * 2] != address(0)) {
            return 1;
        } else {
            return 0;
        }
    }

    function getUserProfit(address account) public view returns(uint256) {
        return _users[account].profit;
    }

    function getUserPoints(address account, uint256 stage, uint256 round) public view returns(uint256) {
        return _users[account].lastLine[stage][round];
    }

    function getUserRounds(address account, uint256 stage) public view returns(uint256) {
        return _users[account].rounds[stage];
    }

    function getUserLevel(address account) public view returns(uint256) {
        uint256 i;

        for (i = 1; i <= 3; i++) {
            if (_users[account].rounds[i] == 0) {
                break;
            }
        }

        return i-1;
    }

    function getUserStages(address account) public view returns(uint256[] memory) {
        uint256[] memory stages = new uint256[](4);

        for (uint256 i = 0; i < 4; i++) {

            stages[i] = getUserRounds(account, i);

        }

        return stages;
    }

    function getStructure(address account, uint256 stage, uint256 round) public view returns(address[] memory) {
        require(stage < 4, "Invalid stage value");
        require(round > 0 && round <= stageLimits[stage], "Invalid round value");

        uint256 limit = 64 / 2**(stage) - 1;

        address[] memory referrals = new address[](limit);

        if (_users[account].rounds[stage] < round) {
            return referrals;
        }

        uint256 id = _users[account].ids[stage];

        uint256 count;
        uint256 line;

        while (count < limit) {
            for (uint256 i = 0; i < 2**line; i++) {
                uint256 idx = id * 2**line + i;
                if (_users[_userByid[stage][idx]].rounds[stage] >= round) {
                    referrals[count] = _userByid[stage][idx];
                }
                count++;
            }
            line++;
        }

        return referrals;
    }

    function getInfo1() external view returns(uint256[] memory) {
        uint256[] memory info = new uint256[](2);

        info[0] = getAmountOfUsers(0);
        info[1] = getDaysSinceStart();

        return info;
    }

    function getInfo2(address account) external view returns(uint256[] memory) {
        uint256[] memory info = new uint256[](2);

        info[0] = getUserAmountOfPartners(account);
        info[1] = getUserProfit(account);

        return info;
    }

    function getInfo3(address account) external view returns(address[] memory, uint256[] memory) {
        address[] memory partners = getUserPartners(account);
        uint256[] memory stages = new uint256[](partners.length);

        for (uint256 i = 0; i < partners.length; i++) {
            stages[i] = getUserLevel(partners[i]);
        }

        return (partners, stages);
    }

    function getInfo4(address account) external view returns(uint256[] memory, uint256[] memory) {
        uint256[] memory reinvests = getUserStages(account);
        uint256[] memory progress = new uint256[](4);

        for (uint256 i = 0; i < 4; i++) {
            address[] memory referrals;
            if (reinvests[i] > 0) {
                referrals = getStructure(account, i, 1);
            }
            for (uint256 l = 0; l < referrals.length; l++) {
                if (referrals[l] != address(0)) {
                    progress[i]++;
                }
            }
            progress[i] = progress[i] * 10000 / (64 / 2**(i) - 1);
        }

        return (reinvests, progress);
    }

    /// TEST

    function TEST_regRandomUsers_new(address[] memory users, address referrer) public payable {
        require(msg.value == users.length * price);
        for (uint i; i<users.length; i++) {
            regUser(referrer, users[i]);
        }
    }

    function TEST_regRandomUsers(address referrer, uint256 amount) public payable {
        require(msg.value == amount * price);
        for (uint i; i<amount; i++) {
            regUser(referrer, address((now*(i+1))**10));
        }
    }

    function TEST_addProfit(address account) public payable {
        _users[account].profit += msg.value;
    }

    function TEST_withdraw() public {
        msg.sender.transfer(address(this).balance);
    }

}