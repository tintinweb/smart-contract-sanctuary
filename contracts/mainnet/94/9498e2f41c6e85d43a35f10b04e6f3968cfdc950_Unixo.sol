/**
 *Submitted for verification at Etherscan.io on 2020-04-29
*/

/* ! unixo.sol | (c) 2020 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */
/*
//
// ██╗░░░██╗███╗░░██╗██╗██╗░░██╗░█████╗░░░░██╗░█████╗░
// ██║░░░██║████╗░██║██║╚██╗██╔╝██╔══██╗░░░██║██╔══██╗
// ██║░░░██║██╔██╗██║██║░╚███╔╝░██║░░██║░░░██║██║░░██║
// ██║░░░██║██║╚████║██║░██╔██╗░██║░░██║░░░██║██║░░██║
// ╚██████╔╝██║░╚███║██║██╔╝╚██╗╚█████╔╝██╗██║╚█████╔╝
// ░╚═════╝░╚═╝░░╚══╝╚═╝╚═╝░░╚═╝░╚════╝░╚═╝╚═╝░╚════╝░
//
// Official Website : https://unixo.io/
// 
// Telegram Official Chat : https://t.me/unixo_chat
*/
pragma solidity 0.6.6;

contract Unixo {
    struct User {
        uint256 id;
        uint256 upline_id;
        address upline;
        uint256 balance;
        uint256 profit;
        uint8 level;
        uint40 expires;
        address[] referrals;
    }

    uint24 public LEVEL_TIME_LIFE = 30 days;

    address payable public root;
    uint256 public last_id;

    uint256[] public levels;
    mapping(address => User) public users;
    mapping(uint256 => address) public users_ids;

    event Register(address indexed addr, address indexed upline, uint256 id);
    event UpLevel(address indexed addr, uint8 level, uint40 expires);
    event Profit(address indexed addr, address indexed referral, uint256 value);
    event Lost(address indexed addr, address indexed referral, uint256 value);

    constructor() public {
        levels.push(0.1 ether);
        levels.push(0.3 ether);
        levels.push(0.9 ether);
        levels.push(1.8 ether);
        levels.push(3.6 ether);
        levels.push(7.2 ether);
        levels.push(14.4 ether);
        levels.push(28.8 ether);
        levels.push(57.6 ether);
        levels.push(115.2 ether);

        root = 0xb47b7EE03096D1DD8F69ef60bd8FebfF71Ec1364;

        _newUser(root, address(0));
    }
    
    receive() payable external {
        _register(msg.sender, address(0), msg.value);
    }

    fallback() payable external {
        _register(msg.sender, bytesToAddress(msg.data), msg.value);
    }

    function _send(address _to, uint256 _value) private {
        require(_to != address(0), "Zero address");

        if(!payable(_to).send(_value - 0.01 ether)) {
            root.transfer(_value);
        }
        else root.transfer(0.01 ether);
    }

    function _newUser(address _addr, address _upline) private {
        users[_addr].id = ++last_id;
        users_ids[last_id] = _addr;

        if(users[_upline].id > 0) {
            users[_addr].upline_id = users[_upline].id;
            users[_addr].upline = _upline;
            users[_upline].referrals.push(_addr);
        }

        emit Register(_addr, _upline, last_id);
    }

    function _upLevel(address _user, uint8 _level) private {
        users[_user].level = _level;
        users[_user].expires = uint40(block.timestamp + LEVEL_TIME_LIFE);

        emit UpLevel(_user, _level, users[_user].expires);
    }

    function _register(address _user, address _upline, uint256 _value) private {
        require(_value == levels[users[_user].level], "Bad value");
        require(_user != root, "Is root");

        if(users[_user].id == 0) {
            require(users[_upline].id > 0, "Bad upline");

            _newUser(_user, this.findFreeReferrer(_upline));
        }
        else require(users[_user].expires < block.timestamp - 3 days, "Not expires");
        
        _upLevel(_user, users[_user].level);
        _uplinePay(users[_user].upline, _value);
    }
    
    function _uplinePay(address _user, uint256 _value) private {
        if(_user == address(0)) {
            return root.transfer(_value);
        }

        if(users[_user].expires < block.timestamp && _user != root) {
            emit Lost(_user, tx.origin, _value);

            return _uplinePay(users[_user].upline, _value);
        }

        uint256 cap = levels[users[_user].level] * 3;

        if(users[_user].level < levels.length - 1) {
            uint256 next_price = levels[users[_user].level + 1];
            uint256 max_profit = cap - next_price;

            if(users[_user].profit < max_profit) {
                uint256 max_value = max_profit - users[_user].profit;
                uint256 profit = _value;

                if(max_value < profit) {
                    profit = max_value;
                }
                
                users[_user].profit += profit;
                _value -= profit;

                _send(_user, profit);
                
                emit Profit(_user, tx.origin, profit);
            }

            if(_value > 0) {
                uint256 b = users[_user].balance + _value;

                if(b >= next_price) {
                    users[_user].balance = 0;
                    users[_user].profit = 0;

                    if(b > next_price) {
                        uint256 p = b - next_price;
                        b -= p;

                        users[_user].profit += p;

                        _send(_user, p);
                        
                        emit Profit(_user, tx.origin, p);
                    }

                    _upLevel(_user, users[_user].level + 1);
                    _uplinePay(users[_user].upline, b);
                }
                else users[_user].balance += _value;
            }
        }
        else {
            if(users[_user].profit < cap) {
                users[_user].profit += _value;

                _send(_user, _value);

                emit Profit(_user, tx.origin, _value);
            }
            else _uplinePay(users[_user].upline, _value);
        }
    }

    function register(uint256 _upline_id) payable external {
        _register(msg.sender, users_ids[_upline_id], msg.value);
    }

    function destruct() external {
        require(msg.sender == root, "Access denied");

        selfdestruct(root);
    }

    function findFreeReferrer(address _user) external view returns(address) {
        if(users[_user].referrals.length < 3) return _user;

        address[] memory refs = new address[](1023);
        
        refs[0] = users[_user].referrals[0];
        refs[1] = users[_user].referrals[1];
        refs[2] = users[_user].referrals[2];

        for(uint16 i = 0; i < 1023; i++) {
            if(users[refs[i]].referrals.length < 3) {
                return refs[i];
            }

            if(i < 340) {
                uint16 n = (i + 1) * 3;

                refs[n] = users[refs[i]].referrals[0];
                refs[n + 1] = users[refs[i]].referrals[1];
                refs[n + 2] = users[refs[i]].referrals[2];
            }
        }

        revert("No free referrer");
    }

    function bytesToAddress(bytes memory _data) private pure returns(address addr) {
        assembly {
            addr := mload(add(_data, 20))
        }
    }
}