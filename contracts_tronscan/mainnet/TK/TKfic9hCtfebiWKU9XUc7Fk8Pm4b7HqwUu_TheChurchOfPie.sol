//SourceUnit: TheChurchOfTron.sol

pragma solidity 0.5.9;

contract TheChurchOfPie {
	using SafeMath for uint256;

    uint256 BUTTON_BASE_PRICE = 10 trx;

    address payable owner;

	struct Button {
	    address payable owner;
	    address payable owner_2;
	    address payable owner_3;
	    address payable owner_4;

	    uint256 price;
	    uint8 percent_increase;
	    uint256 insurance;
	    uint256 last_press;
	}

	struct LotteryTickets {
	    address payable owner;
	    uint256 tickets;
	}

	struct LastWinner {
	    address winner;
	    uint256 won;
	    uint256 ticket;
	}

    uint8[] referral_bonuses;
    uint256 total_referral;

    uint256 next_lottery = 1610496000;
    uint256 lottery_pot;
    uint256 lottery_ticket_price = 100 trx;
    LotteryTickets[] lottery_tickets;
    mapping(uint8 => LastWinner) last_lottery_winners;
    bytes32 entropy;

    mapping(uint8 => Button) buttons;
    mapping(address => address payable) referral;
    mapping(address => uint256) ref_income;

    constructor() public {
        owner = msg.sender;

        referral_bonuses.push(80);
        referral_bonuses.push(20);

        buttons[0] = Button(msg.sender, msg.sender, msg.sender, msg.sender, BUTTON_BASE_PRICE, 135, 0, block.timestamp); // 147% ROI
        buttons[1] = Button(msg.sender, msg.sender, msg.sender, msg.sender, BUTTON_BASE_PRICE, 150, 0, block.timestamp); // 206% ROI

        entropy = keccak256(abi.encodePacked(msg.sender, block.timestamp));
    }

    function shareSomePie(uint8 button_id, address payable referrer, string memory _gibberish) public payable {
        Button storage button = buttons[button_id];
        require(msg.value >= button.price);

        uint256 tenth = msg.value.div(10);

        lottery_pot += tenth;
        button.insurance += tenth;

        setAndPayReferral(msg.sender, referrer, tenth.mul(8).div(10), tenth.mul(2).div(10));

        button.owner.transfer(tenth);
        button.owner_2.transfer(tenth);
        button.owner_3.transfer(tenth.mul(2));
        button.owner_4.transfer(tenth.mul(2));
        owner.transfer(tenth);

        button.price = button.price.mul(button.percent_increase).div(100).ceil(1000000);
        button.last_press = block.timestamp;

        button.owner_4 = button.owner_3;
        button.owner_3 = button.owner_2;
        button.owner_2 = button.owner;
        button.owner = msg.sender;

        uint256 free_tickets = 1;
        if(msg.value > 1000 trx){
            free_tickets = msg.value.div(1000 trx);
        }
        lottery_tickets.push(LotteryTickets(msg.sender, free_tickets));

        entropy = keccak256(abi.encodePacked(entropy, msg.sender, _gibberish));
    }

    function resetButton(uint8 button_id) public payable {
        Button storage button = buttons[button_id];
        require(button.last_press < (block.timestamp - (60*60*48)), "Not ready to reset");
        if(next_lottery < block.timestamp){ resolveLottery(); }

        button.owner.transfer(button.insurance.div(5));
        button.owner.transfer(button.insurance.div(5));
        button.owner.transfer(button.insurance.div(5));
        button.owner.transfer(button.insurance.div(5));

        button.price = BUTTON_BASE_PRICE;
        button.last_press = block.timestamp;
        button.insurance = button.insurance.div(5);
    }

    function buyLotteryTickets(address payable referrer, string memory _gibberish) public payable {
        if(next_lottery < block.timestamp){ resolveLottery(); }
        require(msg.value >= lottery_ticket_price, "Not enough TRX");
        uint256 ticket_count = msg.value.div(lottery_ticket_price);
        lottery_tickets.push(LotteryTickets(msg.sender, ticket_count));

        owner.transfer(msg.value.div(10));
        buttons[0].insurance += msg.value.div(20);
        buttons[1].insurance += msg.value.div(20);
        lottery_pot += msg.value.mul(70).div(100);

        setAndPayReferral(msg.sender, referrer, msg.value.mul(8).div(100), msg.value.mul(2).div(100));

        entropy = keccak256(abi.encodePacked(entropy, msg.sender, _gibberish));
    }

    function resolveLottery() public payable {
        require(next_lottery < block.timestamp, "Lottery not over");

        uint256 jackpot = lottery_pot.mul(70).div(100);

        uint256 total_tickets;
        for(uint256 c = 0; c < lottery_tickets.length; c++){
            total_tickets += lottery_tickets[c].tickets;
        }

        address payable winner;
        uint256 winner_ticket = random(total_tickets);
        uint256 winner_ticket_save = winner_ticket;
        for(uint256 c = 0; c < lottery_tickets.length; c++){
            winner_ticket -= lottery_tickets[c].tickets;
            if(winner_ticket <= 0){
                winner = lottery_tickets[c].owner;
            }
        }

        lottery_pot -= jackpot;
        winner.transfer(jackpot);

        last_lottery_winners[2] = last_lottery_winners[1];
        last_lottery_winners[1] = last_lottery_winners[0];
        last_lottery_winners[0] = LastWinner(winner, jackpot, winner_ticket_save);

        delete lottery_tickets;

        next_lottery = next_lottery + (60 * 60 * 24);
    }

    function random(uint256 max) private view returns (uint256) {
       return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, max, lottery_pot, entropy)))%max);
    }

    function setAndPayReferral(address _addr, address payable _referral, uint256 ref1, uint256 ref2) private {
        if(referral[_addr] == address(0)){
            referral[_addr] = _referral;
        }
        ref_income[_referral] += ref1;
        _referral.transfer(ref1);
        address payable ref_2 = referral[_referral];
        if(referral[_referral] == address(0)){ ref_2 = owner; }
        ref_income[ref_2] += ref2;
        ref_2.transfer(ref2);

        total_referral += ( ref1 + ref2 );
    }

	function gameInfo() view external returns(
	    uint256 _b0_price, uint256 _b1_price, address[] memory _b0_owners, address[] memory _b1_owners, uint256 _b0_insurance, uint256 _b1_insurance,
	    uint256 _b0_last_press, uint256 _b1_last_press, uint256 _lottery_pot, uint256 _lottery_tickets, uint256 _referral_global, uint256 _next_lottery){
	    uint256 total_tickets;
        for(uint256 c = 0; c < lottery_tickets.length; c++){
            total_tickets += lottery_tickets[c].tickets;
        }

        address[] memory b0_owners = new address[](4);
        address[] memory b1_owners = new address[](4);
        b0_owners[0] = buttons[0].owner;
        b0_owners[1] = buttons[0].owner_2;
        b0_owners[2] = buttons[0].owner_3;
        b0_owners[3] = buttons[0].owner_4;
        b1_owners[0] = buttons[1].owner;
        b1_owners[1] = buttons[1].owner_2;
        b1_owners[2] = buttons[1].owner_3;
        b1_owners[3] = buttons[1].owner_4;

	    return(buttons[0].price, buttons[1].price, b0_owners, b1_owners, buttons[0].insurance, buttons[1].insurance, buttons[0].last_press, buttons[1].last_press, lottery_pot, total_tickets, total_referral, next_lottery);
	}

	function lotteryInfo() view external returns (address[] memory players, uint256[] memory lucky_numbers, uint256[] memory wins){
        address[] memory _players = new address[](3);
        uint256[] memory _lucky_numbers = new uint256[](3);
        uint256[] memory _wins = new uint256[](3);
        for(uint8 i = 0; i < 3; i++){
            _players[i] = last_lottery_winners[i].winner;
            _lucky_numbers[i] = last_lottery_winners[i].ticket;
            _wins[i] = last_lottery_winners[i].won;
        }
        return(_players, _lucky_numbers, _wins);
	}

	function playerInfo(address player) view external returns (uint256 _ref_income, uint256 _lottery_tickets){
	    uint256 total_tickets;
        for(uint256 c = 0; c < lottery_tickets.length; c++){
            if(address(lottery_tickets[c].owner) == player){
                total_tickets += lottery_tickets[c].tickets;
            }
        }
	    return(ref_income[player], total_tickets);
	}

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        return ((a + b - 1) / b) * b;
    }
}