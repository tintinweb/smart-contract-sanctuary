/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
    a0 a1 a2 a3

    ---Rank 4-----------------------------------
    a0 a1 a2 a3 => 60%

    ---Rank 3-----------------------------------
    (a0 a1 a2 !a3) => 25%

    ---Rank 2-----------------------------------
    a0a1 or a1a2 or a2a3 => 10%

    ---Rank 1-----------------------------------
    a0 or a1 or a2 or a3 => 4%
    
    1% -> dev
    --------------------------------------------
    
    If nobody won anything (not even 1 number):

    1% -> dev
    4% -> burned
    95% -> next pot

*/

contract Lottery {
    using SafeMath for uint256;

    mapping(address => mapping(uint256 => uint256[])) private tickets;
    mapping(address => uint256) private numOfTickets;
    mapping(address => bool) private isPlayer;
    address[] public players;

    uint256 public numPlayers;
    uint256 public numTickets;
    uint256 public previousPot;
    uint256 public lotoID;

    uint256 public rank1Num = 0;
    uint256 public rank2Num = 0;
    uint256 public rank3Num = 0;
    uint256 public rank4Num = 0;

    mapping(address => bool) private winningPlayersPushed;
    mapping(address => uint256) private winningTicketNum;
    mapping(address => mapping(uint256 => uint256[])) private winningTickets;
    address[] public winningPlayers;

    uint256[] public winningNumbers;

    IERC20 public inu;
    address public devX;
    uint256 public ticketPrice;
    bool public lotoEnabled;
    bool public buyingEnabled;

    event BoughtTicket(address player, uint256[] numbers);

    constructor(
        address inu_,
        address devX_,
        uint256 ticketPrice_
    ) public {
        inu = IERC20(inu_);
        devX = devX_;
        ticketPrice = ticketPrice_;
    }

    modifier onlyDev() {
        require(msg.sender == devX, "Dev Only");
        _;
    }

    function append(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function toString(uint256 num) internal pure returns (string memory) {
        if (num == 0) {
            return "0";
        } else if (num == 1) {
            return "1";
        } else if (num == 2) {
            return "2";
        } else if (num == 3) {
            return "3";
        } else if (num == 4) {
            return "4";
        } else if (num == 5) {
            return "5";
        } else if (num == 6) {
            return "6";
        } else if (num == 7) {
            return "7";
        } else if (num == 8) {
            return "8";
        } else if (num == 9) {
            return "9";
        }
    }

    function getTickets(address address_) public view returns (string memory) {
        string memory result = "";
        uint256 numTicket = numOfTickets[address_];
        for (uint256 i = 0; i < numTicket; i++) {
            for (uint256 j = 0; j < 4; j++) {
                result = append(result, toString(tickets[address_][i][j]));
            }
            result = append(result, "-");
        }
        return result;
    }

    function getWinningNumber() public view returns (string memory) {
        string memory result = "";
        for (uint256 i = 0; i < winningNumbers.length; i++) {
            result = append(result, toString(winningNumbers[i]));
        }

        return result;
    }

    function getWinningTickets(address address_)
        public
        view
        returns (string memory)
    {
        string memory result = "";
        uint256 numTicket = winningTicketNum[address_];
        for (uint256 i = 0; i < numTicket; i++) {
            for (uint256 j = 0; j < 4; j++) {
                result = append(
                    result,
                    toString(winningTickets[address_][i][j])
                );
            }
            result = append(result, "-");
        }
        return result;
    }

    function getPot() external view returns (uint256) {
        return inu.balanceOf(address(this));
    }

    function setTicketPrice(uint256 price) external onlyDev() {
        ticketPrice = price;
    }

    function startLoto() external onlyDev() {
        // Reset everything
        for (uint256 i = 0; i < players.length; i++) {
            numOfTickets[players[i]] = 0;
            isPlayer[players[i]] = false;
        }

        for (uint256 i = 0; i < winningPlayers.length; i++) {
            winningTicketNum[winningPlayers[i]] = 0;
            winningPlayersPushed[winningPlayers[i]] = false;
        }

        delete players;
        delete winningPlayers;

        numTickets = 0;
        numPlayers = 0;

        lotoEnabled = true;
        buyingEnabled = true;
    }

    function disableBuying() external onlyDev() {
        buyingEnabled = false;
    }

    function endLoto(uint256[] memory winningN) external onlyDev() {
        lotoEnabled = false;
        buyingEnabled = false;
        lotoID += 1;
        winningNumbers = winningN;
        determineWinners();
        if (winningPlayers.length > 0) {
            payoutRewards();
        } else {
            if (inu.balanceOf(address(this)) > 0) {
                previousPot = inu.balanceOf(address(this));
                uint256 devR = inu.balanceOf(address(this)).div(100);
                uint256 burnR = inu.balanceOf(address(this)).mul(4).div(100);
                inu.transfer(devX, devR);

                if (inu.balanceOf(address(this)) < burnR) {
                    burnR = inu.balanceOf(address(this));
                }
                inu.transfer(
                    address(0x000000000000000000000000000000000000dEaD),
                    burnR
                );
            } else {
                previousPot = 0;
            }
        }
    }

    function determineWinners() internal {
        for (uint256 i = 0; i < players.length; i++) {
            uint256 numTicket = numOfTickets[players[i]];
            uint256 numOfWinningTickets = 0;
            for (uint256 j = 0; j < numTicket; j++) {
                uint256[] memory currentTicket = tickets[players[i]][j];
                uint256 rank = scanTicket(currentTicket, false);
                if (rank != 0) {
                    if (!winningPlayersPushed[players[i]]) {
                        winningPlayers.push(players[i]);
                        winningPlayersPushed[players[i]] = true;
                    }
                    winningTickets[players[i]][
                        numOfWinningTickets
                    ] = currentTicket;
                    numOfWinningTickets = numOfWinningTickets + 1;
                }
            }
            winningTicketNum[players[i]] = numOfWinningTickets;
        }
    }

    function payoutRewards() internal onlyDev() {
        uint256 rank1 = 0;
        uint256 rank2 = 0;
        uint256 rank3 = 0;
        uint256 rank4 = 0;

        for (uint256 i = 0; i < winningPlayers.length; i++) {
            uint256 numTickets_ = winningTicketNum[winningPlayers[i]];
            for (uint256 j = 0; j < numTickets_; j++) {
                uint256 rank = scanTicket(
                    winningTickets[winningPlayers[i]][j],
                    false
                );
                if (rank == 1) {
                    rank1 += 1;
                } else if (rank == 2) {
                    rank2 += 1;
                } else if (rank == 3) {
                    rank3 += 1;
                } else if (rank == 4) {
                    rank4 += 1;
                }
            }
        }

        rank1Num = rank1;
        rank2Num = rank2;
        rank3Num = rank3;
        rank4Num = rank4;

        uint256 rewardRank4 = inu.balanceOf(address(this)).mul(60).div(100);
        uint256 rewardRank3 = inu.balanceOf(address(this)).mul(25).div(100);
        uint256 rewardRank2 = inu.balanceOf(address(this)).mul(10).div(100);
        uint256 rewardRank1 = inu.balanceOf(address(this)).mul(4).div(100);
        uint256 rewardDev = inu
        .balanceOf(address(this))
        .sub(rewardRank1)
        .sub(rewardRank2)
        .sub(rewardRank3)
        .sub(rewardRank4);

        if (rank1 != 0) {
            rewardRank1 = rewardRank1.div(rank1);
        }
        if (rank2 != 0) {
            rewardRank2 = rewardRank2.div(rank2);
        }
        if (rank3 != 0) {
            rewardRank3 = rewardRank3.div(rank3);
        }
        if (rank4 != 0) {
            rewardRank4 = rewardRank4.div(rank4);
        }
        uint256 help = 0;
        for (uint256 i = 0; i < winningPlayers.length; i++) {
            uint256 numTickets_ = winningTicketNum[winningPlayers[i]];
            for (uint256 j = 0; j < numTickets_; j++) {
                uint256 rank = scanTicket(
                    winningTickets[winningPlayers[i]][j],
                    false
                );

                if (rank == 1 && rank1 != 0) {
                    if (rewardRank1 > inu.balanceOf(address(this))) {
                        rewardRank1 = inu.balanceOf(address(this));
                    }
                    inu.transfer(winningPlayers[i], rewardRank1);
                    help += rewardRank1;
                } else if (rank == 2 && rank2 != 0) {
                    if (rewardRank2 > inu.balanceOf(address(this))) {
                        rewardRank2 = inu.balanceOf(address(this));
                    }
                    inu.transfer(winningPlayers[i], rewardRank2);
                    help += rewardRank2;
                } else if (rank == 3 && rank3 != 0) {
                    if (rewardRank3 > inu.balanceOf(address(this))) {
                        rewardRank3 = inu.balanceOf(address(this));
                    }
                    inu.transfer(winningPlayers[i], rewardRank3);
                    help += rewardRank3;
                } else if (rank == 4 && rank4 != 0) {
                    if (rewardRank4 > inu.balanceOf(address(this))) {
                        rewardRank4 = inu.balanceOf(address(this));
                    }
                    inu.transfer(winningPlayers[i], rewardRank4);
                    help += rewardRank4;
                }
            }
        }
        if (rewardDev > inu.balanceOf(address(this))) {
            rewardDev = inu.balanceOf(address(this));
        }
        inu.transfer(devX, rewardDev);
        help += rewardDev;

        previousPot = help;
    }

    function scanTicket(uint256[] memory ticket, bool ext)
        public
        view
        returns (uint256)
    {
        if (ext && lotoEnabled) {
            return 0;
        }
        uint256 toNum = 1000 *
            ticket[0] +
            100 *
            ticket[1] +
            10 *
            ticket[2] +
            ticket[3];
        uint256 winningtoNum = 1000 *
            winningNumbers[0] +
            100 *
            winningNumbers[1] +
            10 *
            winningNumbers[2] +
            winningNumbers[3];

        if (toNum == winningtoNum) {
            return 4;
        } else if (
            (ticket[0] == winningNumbers[0] &&
                ticket[1] == winningNumbers[1] &&
                ticket[2] == winningNumbers[2])
        ) {
            return 3;
        } else if (
            (ticket[0] == winningNumbers[0] &&
                ticket[1] == winningNumbers[1]) ||
            (ticket[1] == winningNumbers[1] &&
                ticket[2] == winningNumbers[2]) ||
            (ticket[2] == winningNumbers[2] && ticket[3] == winningNumbers[3])
        ) {
            return 2;
        } else if (
            (ticket[0] == winningNumbers[0]) ||
            (ticket[1] == winningNumbers[1]) ||
            (ticket[2] == winningNumbers[2]) ||
            (ticket[3] == winningNumbers[3])
        ) {
            return 1;
        }
        return 0;
    }

    function buyTicket(uint256[] memory numbers) internal {
        require(lotoEnabled, "Loto Disabled");
        require(buyingEnabled, "Buying Disabled");
        require(inu.balanceOf(msg.sender) >= ticketPrice, "Low Balance");
        for (uint256 i = 0; i < 4; i++) {
            require(numbers[i] <= 9);
            require(numbers[i] >= 0);
        }

        if (!isPlayer[msg.sender]) {
            players.push(msg.sender);
            isPlayer[msg.sender] = true;
            numPlayers += 1;
        }

        tickets[msg.sender][numOfTickets[msg.sender]] = numbers;
        numOfTickets[msg.sender] = numOfTickets[msg.sender] + 1;
        numTickets += 1;

        emit BoughtTicket(msg.sender, numbers);
    }

    function buyMultipleTicket(uint256[][] memory tickets_) external {
        require(
            inu.balanceOf(msg.sender) >= ticketPrice.mul(tickets_.length),
            "Low Balance"
        );

        inu.transferFrom(
            msg.sender,
            address(this),
            ticketPrice.mul(tickets_.length)
        );

        for (uint256 i = 0; i < tickets_.length; i++) {
            buyTicket(tickets_[i]);
        }
    }
}