/**
 *Submitted for verification at Etherscan.io on 2021-07-17
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

    ---Rank 1-----------------------------------
    a0 a1 a2 a3 => 60%

    ---Rank 2-----------------------------------
    (a0 a1 a2 !a3) => 25%

    ---Rank 3-----------------------------------
    a0a1 or a1a2 or a2a3 => 10%

    ---Rank 4-----------------------------------
    a0 or a1 or a2 or a3 => 4%
    
    1% -> dev
    --------------------------------------------
    
    If nobody won anything (not even 1 number):

    1% -> dev
    4% -> burned
    95% -> next pot

*/

contract Lottery {
    using SafeMath for uint;

    uint8 public lotoID = 1;
    uint8 public winum1 = 11;
    uint8 public winum2 = 11;
    uint8 public winum3 = 11;
    uint8 public winum4 = 11;

    uint256 public numOfTickets = 1;
    uint256 public ticketPrice = 1000 * 10**9;

    mapping(address => string) tickets;
    mapping(address => uint256) ticketsCount;
    mapping(address => bool) isPlayer;
    address[] public players;
    address[] public winners;

    IERC20 public inu;
    address public devX;

    bool public lotoEnabled;
    bool public buyingEnabled;

    event EndedLoto(uint256 payedOut);
    event BoughtTicket(address account,uint8[] numbers);

    constructor(address inu_, address devX_) public {
        inu = IERC20(inu_);
        devX = devX_;
    }

    modifier onlyDev() {
        require(msg.sender == devX, "Dev Only");
        _;
    }

    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e,"-"));
    }

    function toUint8(bytes1 num) internal pure returns (uint8) {
        if (num == bytes1("0")) {
            return 0;
        } else if (num == bytes1("1")) {
            return 1;
        } else if (num == bytes1("2")) {
            return 2;
        } else if (num == bytes1("3")) {
            return 3;
        } else if (num == bytes1("4")) {
            return 4;
        } else if (num == bytes1("5")) {
            return 5;
        } else if (num == bytes1("6")) {
            return 6;
        } else if (num == bytes1("7")) {
            return 7;
        } else if (num == bytes1("8")) {
            return 8;
        } else if (num == bytes1("9")) {
            return 9;
        }
    }

    function toString(uint8 num) internal pure returns (string memory) {
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
        return tickets[address_];
    }
    
    function getWinningNumber() external view returns(string memory){
        if(winum1==11 && winum2 == 11 && winum3 == 11 && winum4 == 11){
            return "Not out";
        }
        return append("",toString(winum1),toString(winum2),toString(winum3),toString(winum4));
    }

    function getNumPlayers() external view returns (uint256) {
        return players.length;
    }

    function getTotalTickets() external view returns (uint256){
        return numOfTickets - 1;
    }

    function disableBuying() external onlyDev() {
        buyingEnabled = false;
    }

    function enableLoto() external onlyDev() {
        require(!lotoEnabled);
        uint256 len = players.length;
        for (uint256 i = 1; i <= len; i++) { 
            tickets[players[i-1]] = "";
            isPlayer[players[i-1]] = false;
            ticketsCount[players[i-1]]=0;
        }
        delete players;
        delete winners;
        numOfTickets = 1;
        winum1=11;
        winum2=11;
        winum3=11;
        winum4=11;
        lotoEnabled = true;
        buyingEnabled = true;
    }

    function disableLoto(uint8[] memory winningNumber) external onlyDev() {
        require(winningNumber[0] >= 0);
        require(winningNumber[1] >= 0);
        require(winningNumber[2] >= 0);
        require(winningNumber[3] >= 0);

        require(winningNumber[0] < 10);
        require(winningNumber[1] < 10);
        require(winningNumber[2] < 10);
        require(winningNumber[3] < 10);

        require(lotoEnabled);


        winum1 = winningNumber[0];
        winum2 = winningNumber[1];
        winum3 = winningNumber[2];
        winum4 = winningNumber[3];

        lotoEnabled = false;
        buyingEnabled = false;
        lotoID += 1;

        determineWinners();
        if (winners.length > 0) {
            uint256 payedTotal = payoutRewards();
            emit EndedLoto(payedTotal);
        } else {
            if (inu.balanceOf(address(this)) > 0) {
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
            }
        }
    }

    function payoutRewards() internal onlyDev() returns(uint256) {
        uint256 rank1 = 1;
        uint256 rank2 = 1;
        uint256 rank3 = 1;
        uint256 rank4 = 1;

        uint256 len = winners.length;
        for (uint256 i = 1; i <= len; i++) {
            uint8[] memory ranks = scanAddressTickets(winners[i-1],getTickets(winners[i-1]));
            uint256 len2 = ranks.length;
            for(uint256 j=1; j<= len2; j++){
                if(ranks[j-1] == 1){
                    rank1 += 1;
                }
                else if(ranks[j-1] == 2){
                    rank2 += 1;
                }
                else if(ranks[j-1] == 3){
                    rank3 += 1;
                }
                else if(ranks[j-1] == 4){
                    rank4 += 1;
                }
            }
        }

        uint256 rewardRank1 = inu.balanceOf(address(this)).mul(60).div(100);
        uint256 rewardRank2 = inu.balanceOf(address(this)).mul(25).div(100);
        uint256 rewardRank3 = inu.balanceOf(address(this)).mul(10).div(100);
        uint256 rewardRank4 = inu.balanceOf(address(this)).mul(4).div(100);
        uint256 rewardDev = inu
        .balanceOf(address(this))
        .sub(rewardRank1)
        .sub(rewardRank2)
        .sub(rewardRank3)
        .sub(rewardRank4);

        if (rank1 != 1) {
            rewardRank1 = rewardRank1.div(rank1-1);
        }
        if (rank2 != 1) {
            rewardRank2 = rewardRank2.div(rank2-1);
        }
        if (rank3 != 1) {
            rewardRank3 = rewardRank3.div(rank3-1);
        }
        if (rank4 != 1) {
            rewardRank4 = rewardRank4.div(rank4-1);
        }

        uint256 help = 0;
        for (uint256 i = 1; i <= len; i++) {
            uint8[] memory ranks = scanAddressTickets(winners[i-1],getTickets(winners[i-1]));
            uint256 len2 = ranks.length;
            for(uint256 j=1; j<= len2; j++){
                if(ranks[j-1] == 1){
                    if (rewardRank1 > inu.balanceOf(address(this))) {
                        rewardRank1 = inu.balanceOf(address(this));
                    }
                    inu.transfer(winners[i-1], rewardRank1);
                    help += rewardRank1;
                }
                else if(ranks[j-1] == 2){
                   if (rewardRank2 > inu.balanceOf(address(this))) {
                        rewardRank2 = inu.balanceOf(address(this));
                    }
                    inu.transfer(winners[i-1], rewardRank2);
                    help += rewardRank2;
                }
                else if(ranks[j-1] == 3){
                   if (rewardRank3 > inu.balanceOf(address(this))) {
                        rewardRank3 = inu.balanceOf(address(this));
                    }
                    inu.transfer(winners[i-1], rewardRank3);
                    help += rewardRank3;
                }
                else if(ranks[j-1] == 4){
                    if (rewardRank4 > inu.balanceOf(address(this))) {
                        rewardRank4 = inu.balanceOf(address(this));
                    }
                    inu.transfer(winners[i-1], rewardRank4);
                    help += rewardRank4;
                }
            }
        }
        
        if (rewardDev > inu.balanceOf(address(this))) {
            rewardDev = inu.balanceOf(address(this));
        }
        inu.transfer(devX, rewardDev);
        help += rewardDev;
        return help;
    }

    function determineWinners() internal onlyDev() {
        uint256 len = players.length;
        for (uint256 i = 1; i <= len; i++) {
            string memory playerTicket = getTickets(players[i-1]);
            uint8[] memory ranks = scanAddressTickets(players[i-1],playerTicket);
            uint256 len2 = ranks.length;
            for(uint256 j = 1; j<= len2; j++){
                if(ranks[j-1] != 0){
                    winners.push(players[i-1]);
                    break;
                } 
            }
        }
    }

    function scanAddressTickets(address account,string memory ticket) internal view returns (uint8[] memory) {
 
        bytes memory b = bytes(ticket);
        uint256 len = ticketsCount[account].mul(5);
        uint256 winTrack = 0;
        
        uint8[] memory ranks = new uint8[](len);
        
        if(len <= 4) return ranks;
        
        for(uint256 i=1; i<=len; i+=5){
           uint8 num1 = toUint8(b[i-1]);
           uint8 num2 = toUint8(b[i]);
           uint8 num3 = toUint8(b[i+1]);
           uint8 num4 = toUint8(b[i+2]);

           uint8 res = scanTicket([num1,num2,num3,num4]);
           
           if(res != 0 && res != 5){
            ranks[winTrack] = res;
            winTrack += 1;
           }
        }

        return ranks;
    }

    function scanTicket(uint8[4] memory ticket)
        public
        view
        returns (uint8)
    {
        if(lotoEnabled) {
            return 5;
        }

        if (ticket[0] == winum1 &&
                ticket[1] == winum2 &&
                ticket[2] == winum3 && ticket[3] == winum4) {
            return 1;
        } else if (
            (ticket[0] == winum1 &&
                ticket[1] == winum2 &&
                ticket[2] == winum3)
        ) {
            return 2;
        } else if (
            (ticket[0] == winum1 &&
                ticket[1] == winum2) ||
            (ticket[1] == winum2 &&
                ticket[2] == winum3) ||
            (ticket[2] == winum3 && ticket[3] == winum4)
        ) {
            return 3;
        } else if (
            (ticket[0] == winum1) ||
            (ticket[1] == winum2) ||
            (ticket[2] == winum3) ||
            (ticket[3] == winum4)
        ) {
            return 4;
        }
        return 0;
    }

    function buyTicket(uint8[] memory numbers) internal {
        require(inu.balanceOf(msg.sender) >= ticketPrice);
        require(numbers[0] >= 0);
        require(numbers[1] >= 0);
        require(numbers[2] >= 0);
        require(numbers[3] >= 0);

        require(numbers[0] < 10);
        require(numbers[1] < 10);
        require(numbers[2] < 10);
        require(numbers[3] < 10);

        if(!isPlayer[msg.sender]) {
            players.push(msg.sender);
            isPlayer[msg.sender] = true;
        }

        string memory currentTickets = tickets[msg.sender];
        tickets[msg.sender] = append(currentTickets,toString(numbers[0]),toString(numbers[1]),toString(numbers[2]),toString(numbers[3]));

        emit BoughtTicket(msg.sender,numbers);
    }
    
    function buyMultipleTickets(uint8[][] memory tickets_) public {
        uint256 len = tickets_.length;
        require(inu.balanceOf(msg.sender) >= ticketPrice.mul(len));
        inu.transferFrom(msg.sender, address(this), ticketPrice.mul(len));
        
        for(uint256 i=1; i<= len;i++){
            buyTicket(tickets_[i-1]);
        }
        numOfTickets += len;
        ticketsCount[msg.sender] += len;
    }
}