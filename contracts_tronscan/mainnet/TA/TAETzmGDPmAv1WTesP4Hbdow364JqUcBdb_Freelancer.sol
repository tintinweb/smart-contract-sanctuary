//SourceUnit: Freelancer.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Freelancer {
    /** 
    NEVER MAKE VIEW FUNCTION IF MODIFIEING ANY VALUE 
    LIKE UINT DATA = 3 // HERE ITS UPDATING SO IT MUST NOT BE VIEW
    */

    using SafeMath for uint256;

    address public owner;
    uint256 public total_contract_money_till_now_got = 0;
    uint256 public current_contract_money_left = 0;

    //Store candidate count
    uint256 public playersCount;

    //Array of all address
    address[] public users_array;

    struct Player {
        uint256 id;
        address user_address;
        uint256 reff_id;
        address referral_address;
        uint256 total_withdrawals;
        uint256 earned_money;
        uint256 invested_amount;
        uint256 time;
        uint256 days_left;
    }

    struct SendTrx {
        uint256 id;
        address user_address;
        uint256 amount_to_send;
    }

    mapping(uint256 => Player) public players;
    mapping(address => Player) public players_address;
    mapping(uint256 => SendTrx) public send_trx;

    // constructor() public {
    //     owner = msg.sender;
    // }

    function getEntries() public view returns (address[] memory) {
        return users_array;
    }

    // REGISTER
    function register(
        address _addr,
        uint256 _referral_id,
        uint256 _invested_trx,
        uint256 _time
    ) public {
        if (_referral_id != 0) {
            // USER ADDRESS MUST NOT EXIST
            require(hasUser(_addr) == false, "ALREADY A USER");

            // REFERRAL ID MUST EXIST
            require(players[_referral_id].id != 0, "REFERRAL ID DOESN'T EXIST");

            // DEDUCT 25% AMOUNT
            uint256 transfer_amount = _invested_trx.div(100).mul(25);

            // GET 75% AMOUNT
            uint256 contract_amount = transfer_amount.sub(_invested_trx);

            // ADD AMOUNT TO CONTRACT ADDRESS
            total_contract_money_till_now_got = total_contract_money_till_now_got
                .add(contract_amount);

            // ADD NEW USER
            insertUser(
                _addr,
                _referral_id,
                players[_referral_id].user_address,
                0,
                0,
                _invested_trx,
                _time
            );

            // TRANSFER MONEY TO REFERRAL ID
            transferTo(_referral_id, transfer_amount);

            // SET TRANSFER AMOUNT TO STRUCT
            setAmountStruct(_referral_id, transfer_amount);
        } else {
            // USER ADDRESS MUST NOT EXIST
            require(hasUser(_addr) == false, "USER OR ADDRESS ALREADY EXIST");

            // ADD AMOUNT TO CONTRACT ADDRESS
            total_contract_money_till_now_got = total_contract_money_till_now_got
                .add(_invested_trx);

            address refer_addr = 0x0000000000000000000000000000000000000000;

            // ADD NEW USER
            insertUser(_addr, 0, refer_addr, 0, 0, _invested_trx, _time);
        }
    }

    // LOGIN
    function login(uint256 _id)
        public
        view
        returns (
            uint256,
            address,
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(players[_id].id != 0, "NO SUCH USER EXIST");
        Player storage players_data = players[_id];
        return (
            players_data.id,
            players_data.user_address,
            players_data.reff_id,
            players_data.referral_address,
            players_data.total_withdrawals,
            players_data.earned_money,
            players_data.invested_amount,
            players_data.time,
            players_data.days_left
        );
    }

    // GET ALL USERS COUNT
    function getAllUsersCount() public view returns (uint256) {
        return users_array.length;
    }

    // PUT SEND AMOUNT IN STRUCT
    function setAmountStruct(uint256 _id, uint256 _amount) public {
        Player storage players_data = players[_id];
        // PUT DATA IN STRUCT OF ID
        send_trx[_id] = SendTrx(_id, players_data.user_address, _amount);
    }

    // UPDATE AMOUNT STRUCT AFTER SENDING AMOUNT FROM OWNER
    function updateAmountStruct(uint256 _id) public {
        SendTrx storage send_data = send_trx[_id];
        send_data.amount_to_send = 0;
    }

    // DEPOSIT EARNING
    function updateTimeAndEarned(uint256 _id, uint256 _newTime) public {
        Player storage players_data = players[_id];
        uint256 give_earned = players_data.invested_amount.div(100).mul(2);
        current_contract_money_left = current_contract_money_left.add(
            give_earned
        );
        players_data.time = _newTime;
        players_data.earned_money = players_data.earned_money.add(give_earned);
    }

    // WITHDRAW EARNINGS
    function withdraw(uint256 _id, uint256 _trx_deposit) public {
        Player storage players_data = players[_id];

        require(players[_id].id != 0, "NO SUCH USER PRESENT");
        require(
            players_data.earned_money > _trx_deposit,
            "DON'T HAVE ENOUGH MONEY TO WITHDRAW"
        );
        require(
            totalReferrals(players_data.user_address) != 0,
            "MUST REFER ATLEAST ONCE"
        );
        require(daysLeft(_id) == true, "OUT OF DAYS");

        players_data.days_left = players_data.days_left.sub(1);
        players_data.earned_money = players_data.earned_money.sub(_trx_deposit);
        players_data.total_withdrawals = players_data.total_withdrawals.add(
            _trx_deposit
        );
        send_trx[_id] = SendTrx(_id, players_data.user_address, _trx_deposit);
    }

    // GET ALL REFERRAL OF USER
    function totalReferrals(address _user) public view returns (uint256) {
        uint256 referral_count = 0;
        for (uint256 i = 0; i < users_array.length; i++) {
            address referral = users_array[i];
            Player storage player_data = players_address[referral];
            if (player_data.referral_address == _user) {
                referral_count++;
            }
        }
        return referral_count;
    }

    // GET USERS DAYS LEFT
    function daysLeft(uint256 _id) internal view returns (bool) {
        Player storage days_left = players[_id];
        if (days_left.days_left == 0) {
            return false;
        } else {
            return true;
        }
    }

    // TRANSFER 25% TO REFERRAL ID
    function transferTo(uint256 _id, uint256 _amount) public {
        Player storage player_data = players[_id];
        current_contract_money_left = current_contract_money_left.sub(_amount);
        player_data.earned_money = player_data.earned_money.add(_amount);
    }

    // CHECKS IF USER EXIST OR NOT BY ADDRESS
    function hasUser(address _userAddress) internal view returns (bool) {
        address check = players_address[_userAddress].user_address;
        if (check != 0x0000000000000000000000000000000000000000) {
            return true;
        } else {
            return false;
        }
    }

    function insertUser(
        address _addr,
        uint256 _referral_id,
        address _referral_address,
        uint256 _with_drawals,
        uint256 _earned,
        uint256 _trx,
        uint256 _time
    ) public {
        // CREATE ID
        playersCount++;

        // PUT DATA IN STRUCT OF ID
        players[playersCount] = Player(
            playersCount,
            _addr,
            _referral_id,
            _referral_address,
            _with_drawals,
            _earned,
            _trx,
            _time,
            100
        );

        // PUT DATA IN STRUCT OF ADDRESS
        players_address[_addr] = Player(
            playersCount,
            _addr,
            _referral_id,
            _referral_address,
            _with_drawals,
            _earned,
            _trx,
            _time,
            100
        );

        // PUSH ADDRESS IN ARRAY
        users_array.push(_addr);
    }
}

// library for maths calculations
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