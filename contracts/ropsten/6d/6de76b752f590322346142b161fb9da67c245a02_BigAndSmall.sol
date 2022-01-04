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
        pool_rule = 1000000;
        pool_balance = 1000000;
        case_no = 0;
    }

    event Roll(uint256 no, uint256 point);

    event PlayerWin(address player, int256 amount);

    event PlayLose(address player, int256 amount);

    event Charge(address player, int256 amount);

    function Play(
        address player,
        uint256 point,
        int256 amount
    ) public returns (int256) {
        if (pool_balance < amount * 5) {
            return 500;
        }
        if (balances[player] < amount) {
            return 501;
        }

        case_no = case_no + 1;
        game_player[case_no] = player;
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
        emit Roll(case_no, result);

        if (result == point) {
            int256 payback = amount * 5;
            pool_balance -= payback;
            balances[player] += payback;
            game_amount[case_no] = amount * 5;
            emit PlayerWin(player, payback);
            return 1;
        } else {
            pool_balance += amount;
            balances[player] -= amount;
            game_amount[case_no] = -amount;
            emit PlayLose(player, amount);
            return 2;
        }
    }

    function CheckCasePoint(address player, uint256 no) public
        view
        returns (uint256)
        {
        if (game_player[no] == player) {
            return (game_point[no]);
        }
        return 0;
    }

    function CheckCaseResult(address player, uint256 no)
        public
        view
        returns (int256)
    {
        if (game_player[no] == player) {
            return (game_amount[no]);
        }
        return 0;
    }

    function PlayerCharge() public payable {
        if (msg.value < 100) {
            return;
        }
        bool result = payable(owner).send(msg.value);
        if (result) {
            pool_balance += int256(msg.value) * 10000;
            balances[msg.sender] += int256(msg.value) * 10000;
        }
    }
}