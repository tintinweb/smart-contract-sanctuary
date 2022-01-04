/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

pragma solidity >=0.8.11;

contract BigAndSmall {
    int256 public pool_rule;
    int256 public pool_balance;
    uint256 case_no;
    uint256 last_player;
    address private owner;

    mapping(address => int256) private balances;
    mapping(uint256 => address) private game_player;
    mapping(uint256 => uint256) private game_point;
    mapping(uint256 => int256) private game_amount;

    constructor() {
        owner = msg.sender;
        pool_rule = 1000000000000;
        pool_balance = 1000000000000;
        case_no = 10000;
    }

    event PlayerCase(uint256 case_no, uint256 point, int256 amount);
    event Charge(address player, int256 amount);

    function Play(uint256 point, int256 amount) public returns (uint256) {
        if (pool_balance < amount * 5) {
            return 500;
        }
        if (balances[msg.sender] < amount) {
            return 501;
        }

        case_no = case_no + 1;
        game_player[case_no] = msg.sender;
        uint256 result = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        pool_balance,
                        case_no,
                        last_player
                    )
                )
            ) % 6
        ) + 1;
        game_point[case_no] = result;

        if (result == point) {
            int256 payback = amount * 5;
            pool_balance -= payback;
            balances[msg.sender] += payback;
            game_amount[case_no] = amount * 5;
            emit PlayerCase(case_no, result, payback);
        } else {
            pool_balance += amount;
            balances[msg.sender] -= amount;
            game_amount[case_no] = -amount;
            emit PlayerCase(case_no, result, -amount);
        }
        return case_no;
    }

    function CheckCasePoint(uint256 no) public view returns (uint256) {
        if (game_player[no] == msg.sender) {
            return (game_point[no]);
        }
        return 0;
    }

    function CheckCaseResult(uint256 no) public view returns (int256) {
        if (game_player[no] == msg.sender) {
            return (game_amount[no]);
        }
        return 0;
    }

    function GetPlayerBalance() public view returns (int256) {
        return balances[msg.sender];
    }

    function PlayerCharge() public payable {
        if (msg.value < 100) {
            return;
        }
        bool result = payable(owner).send(msg.value);
        if (result) {
            pool_balance += int256(msg.value);
            balances[msg.sender] += int256(msg.value);
            emit Charge(msg.sender, int256(msg.value));
        }
    }
}