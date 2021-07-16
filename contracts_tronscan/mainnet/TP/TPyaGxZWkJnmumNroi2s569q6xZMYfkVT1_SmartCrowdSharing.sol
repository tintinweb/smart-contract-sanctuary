//SourceUnit: smart_crowdsharing.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.5.15;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract SmartCrowdSharing {
    
    using SafeMath for *;
    
    address public system_owner;
    uint public current_id = 0;
    mapping(uint => uint) private BONUS_A;
    mapping(uint => uint) private BONUS_B;
    uint private price = 0;

    uint private PRICE_MIN = 100 trx;
    uint private PRICE_MAX = 100000 trx;

    struct MemberObject {
        bool is_exist;
        uint member_id;
        address member_address;
        uint sponsor_id;
        address[] downlines;
        uint downline_qty;
        uint create_time;
    }

    mapping (uint => MemberObject) public map_id_members;
    mapping (address => MemberObject) public map_address_members;

    event Create_new_member(address indexed _address_member, address indexed _address_sponsor, uint _time);
    event Change_price(uint current_price, uint new_price);
    event Sent_sponsor_bonus(address indexed _address_sponsor, address indexed _address_member, uint _level, uint _bonus, uint _time);
    event Get_ethereum_balance(address indexed _system_owner, address indexed _address_member, uint _amount, uint _time);
    event Change_owner(address indexed _current_owner, address indexed _new_owner, uint _time);


    constructor() public {

        BONUS_A[1] = 40;
        BONUS_A[2] = 5;
        BONUS_A[3] = 5;

        BONUS_B[1] = 3;
        BONUS_B[2] = 3;
        BONUS_B[3] = 3;
        BONUS_B[4] = 3;
        BONUS_B[5] = 3;
        BONUS_B[6] = 3;
        BONUS_B[7] = 3;
        BONUS_B[8] = 3;
        BONUS_B[9] = 3;
        BONUS_B[10] = 3;

        price = 1000 trx;

        system_owner = msg.sender;

        current_id++;

        MemberObject memory member;

        member = MemberObject({
            is_exist: true,
            member_id: current_id,
            member_address: msg.sender,
            sponsor_id: 0,
            downlines: new address[](0),
            downline_qty: 0,
            create_time: block.timestamp
        });
        map_id_members[current_id] = member;
        map_address_members[msg.sender] = member;
    }

    function() external payable {
        if (msg.value != price) {
            revert('Incorrect value send');
        }

        if (map_address_members[msg.sender].is_exist) {
            revert('Cancel transaction, the account is already exist');
        }

        uint from_id = 0;

        address sponsor_address = bytes_address(msg.data);

        if (map_address_members[sponsor_address].is_exist) {
            from_id = map_address_members[sponsor_address].sponsor_id;
        } else {
            revert('Incorrect sponsor');
        }

        new_member(from_id);
    }

    function new_member(uint from_id) public payable {
        require(!map_address_members[msg.sender].is_exist, 'This account is already exist');
        require(from_id > 0 && from_id <= current_id, 'Incorrect sponsor id');
        require(msg.value == price, 'Incorrect value send');

        uint time_now = block.timestamp;

        MemberObject memory member;
        current_id++;

        member = MemberObject({
            is_exist: true,
            member_id: current_id,
            member_address: msg.sender,
            sponsor_id: from_id,
            downlines: new address[](0),
            downline_qty: 0,
            create_time: time_now
        });
        map_id_members[current_id] = member;
        map_address_members[msg.sender] = member;

        map_id_members[from_id].downlines.push(msg.sender);
        map_id_members[from_id].downline_qty++;

        uint sponsor_id = from_id;
        uint level = 1;
        uint not_found = 0;

        uint percent = 0;
        uint256 amount = price;
        uint256 bonus = 0;
        uint256 bonus_paid = 0;
        uint256 amount_balance = 0;

        while (level <= 10 && not_found == 0) {
            if (map_id_members[sponsor_id].is_exist) {

                // Calculate bonus
                percent = 0;
                if (level <= 3) {
                    percent = BONUS_A[level];
                }
                if (map_id_members[sponsor_id].downline_qty >= 5) {
                    percent += BONUS_B[level];
                } else if (map_id_members[sponsor_id].downline_qty >= 4) {
                    if (level <= 8) {
                        percent += BONUS_B[level];
                    }
                } else if (map_id_members[sponsor_id].downline_qty >= 3) {
                    if (level <= 6) {
                        percent += BONUS_B[level];
                    }
                } else if (map_id_members[sponsor_id].downline_qty >= 2) {
                    if (level <= 4) {
                        percent += BONUS_B[level];
                    }
                } else if (map_id_members[sponsor_id].downline_qty >= 1) {
                    if (level <= 2) {
                        percent += BONUS_B[level];
                    }
                } else {
                    if (level == 1) {
                        percent += BONUS_B[level];
                    }
                }

                bonus = amount.mul(percent).div(100);

                if (bonus > 0) {
                    bonus_paid = bonus_paid.add(bonus);
                    pay_sponsor_bonus(level, bonus, map_id_members[sponsor_id].member_address);
                }

                // Next upline
                sponsor_id = map_id_members[sponsor_id].sponsor_id;
                if (sponsor_id == 0) {
                    not_found = 1;
                }
            } else {
                not_found = 1;
            }
            level++;
        }

        bool is_sent = false;
        amount_balance = amount.sub(bonus_paid);
        is_sent = address(uint160(system_owner)).send(amount_balance);
        if (is_sent) {
            emit Get_ethereum_balance(system_owner, msg.sender, amount_balance, time_now);
        }
        emit Create_new_member(msg.sender, map_id_members[from_id].member_address, time_now);
    }

    function pay_sponsor_bonus(uint _level, uint _bonus, address _sponsor_address) internal {
        bool is_sent = false;
        is_sent = address(uint160(_sponsor_address)).send(_bonus);
        if (is_sent) {
            emit Sent_sponsor_bonus(_sponsor_address, msg.sender, _level, _bonus, block.timestamp);
        }
    }

    function bytes_address(bytes memory data) private pure returns (address sponsor_address) {
        assembly {
            sponsor_address := mload(add(data, 20))
        }
    }

    function change_price(uint new_price) external {
        require(msg.sender == system_owner, "Reserved function");
        _change_price(new_price);
    }

    function _change_price(uint new_price) internal {
        require(new_price >= PRICE_MIN && new_price <= PRICE_MAX, "Incorrect pricing");
        emit Change_price(price, new_price);
        price = new_price;
    }


    function get_current_price() public view returns(uint) {
        return price;
    }

    function transfer_owner(address new_owner) external {
        require(msg.sender == system_owner,"Reserved function");
        _transfer_owner(new_owner);
    }

    function _transfer_owner(address new_owner) internal {
        require(new_owner != address(0), "New owner is not zero address");
        emit Change_owner(system_owner, new_owner, block.timestamp);
        system_owner = new_owner;
    }
}