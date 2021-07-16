//SourceUnit: argos_v_4_trx.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.5.10;

contract ArgosNEX {
    struct User {
        uint256 balance;
        uint8 level;
        address upline;
        mapping (uint8 => uint256) referrals;
    }

    address payable public root;
    bool public inceptionDeprecated;

    uint256[] public levels;
    mapping(address => User) public users;

    event Register(address indexed addr, address indexed upline, uint40 time);
    event BuyLevel(address indexed addr, address indexed upline, uint8 level, uint40 time);
    event Profit(address indexed addr, address indexed referral, uint256 value, uint40 time);
    event Lost(address indexed addr, address indexed referral, uint256 value, uint40 time);
    event Inception(address indexed addr, address indexed upline, uint8 level, uint40 time);
    event InceptionDeprecated(uint40 time);

    constructor(address payable rootAddr) public {
        levels.push(0);
        levels.push(100e6);

        for(uint8 i = 2; i < 16; i++) {
            levels.push(levels[i - 1] * 2);
        }

        root = rootAddr;

        users[rootAddr].level = uint8(levels.length - 1);

        emit Register(rootAddr, address(0), uint40(block.timestamp));

        for (uint8 i = 1; i < levels.length; i++) {
            emit BuyLevel(rootAddr, address(0), i, uint40(block.timestamp));
        }
    }

    function _send(address _addr, uint256 _value) private {
        if (_addr == address(0) || !address(uint160(_addr)).send(_value)) {
            root.transfer(_value);
        }
    }

    function _buyLevel(address _user, uint8 _level) private {
        require(levels[_level] > 0, "Invalid level");
        require(users[_user].balance >= levels[_level], "Insufficient funds");
        require(_level == 0 || users[_user].level < _level, "Level exists");
        require(users[_user].level == _level - 1, "Need previous level");

        uint256 value = levels[_level];

        users[_user].balance -= value;
        users[_user].level++;

        address upline = users[_user].upline;

        while (users[upline].level < _level) {
            upline = users[upline].upline;
        }

        emit BuyLevel(_user, upline, _level, uint40(block.timestamp));

        address profiter = _findProfiter(upline, _level);

        emit Profit(profiter, _user, value, uint40(block.timestamp));

        if (users[profiter].level == levels.length - 1 || users[profiter].level > _level) {
            _send(profiter, value);
        } else {
            users[profiter].balance += value;

            if (_buyNextLevel(profiter) && users[profiter].balance > 0) {
                uint256 balance = users[profiter].balance;

                users[profiter].balance = 0;

                _send(profiter, balance);
            }
        }
    }

    function _findProfiter(address _user, uint8 _level) private returns(address) {
        users[_user].referrals[_level]++;

        return users[_user].referrals[_level] % 3 == 0 && users[_user].upline != address(0) ? _findProfiter(users[_user].upline, _level) : _user;
    }

    function _buyNextLevel(address _user) private returns(bool) {
        uint8 next_level = users[_user].level + 1;

        if (users[_user].balance >= levels[next_level]) {
            _buyLevel(_user, next_level);

            return true;
        }

        return false;
    }

    function _register(address _user, address _upline, uint256 _value) private {
        require(users[_user].level == 0, "User arleady register");
        require(users[_upline].level > 0, "Upline not register");
        require(_value == levels[1], "Insufficient funds");

        users[_user].balance += _value;
        users[_user].upline = _upline;

        emit Register(_user, _upline, uint40(block.timestamp));

        _buyLevel(_user, 1);
    }

    function register(address _upline) payable external {
        _register(msg.sender, _upline, msg.value);
    }

    function buy(uint8 _level) payable external {
        require(users[msg.sender].level > 0, "User not register");

        users[msg.sender].balance += msg.value;

        _buyLevel(msg.sender, _level);
    }

    function inception(address[] calldata arrAccounts, uint8[] calldata arrLevels) external {
        require(msg.sender == root && !inceptionDeprecated, "No access");
        require(arrAccounts.length == arrLevels.length, "Arrays are not equal");

        for (uint256 i = 0; i < arrAccounts.length; i++) {
            require(arrAccounts[i] != address(0), "Zero address");
            require(users[arrAccounts[i]].level == 0 || users[arrAccounts[i]].upline == root, "Invalid user");
            require(users[arrAccounts[i]].level < arrLevels[i], "Decreasing of level");
            require(arrLevels[i] < uint8(levels.length - 1), "Level is not exist");

            if (users[arrAccounts[i]].upline == address(0)) {
                users[arrAccounts[i]].upline = root;
                emit Register(arrAccounts[i], root, uint40(block.timestamp));
            }

            uint8 j = users[arrAccounts[i]].level == 0 ? 1 : users[arrAccounts[i]].level;
            for (j; j < arrLevels[i]; j++) {
                emit BuyLevel(arrAccounts[i], root, j, uint40(block.timestamp));
            }

            users[arrAccounts[i]].level = arrLevels[i];

            emit Inception(arrAccounts[i], root, arrLevels[i], uint40(block.timestamp));
        }
    }

    function deprecateInception() external {
        require(msg.sender == root && !inceptionDeprecated, "No access");

        inceptionDeprecated = true;

        emit InceptionDeprecated(uint40(block.timestamp));
    }

    function nextLevelCost(address user) external view returns(uint256) {
        return levels[users[user].level + 1] - users[user].balance;
    }
}