//SourceUnit: TronSafev3.sol

/*! TronSafev3.sol | (c) 2020 Developed by DAPPKING (TronSafe.com) | SPDX-License-Identifier: MIT License */

pragma solidity 0.5.9;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TronSAFEv3 {
    
    
    struct Tarif {
        uint40 life_days;
        uint40 percent;
    }

    struct Deposit {
        uint40 tarif;
        uint256 amount;
        uint40 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 match_bonus;
        uint40 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        uint256 total_deposited;
        uint40 last_withdrawal_time;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }

    address payable public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public Reinvested;
    
    uint8[] public ref_bonuses; // 1 => 1%

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint40 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 reinv);

    constructor() public {
        owner = msg.sender;

        tarifs.push(Tarif(20, 120));
        tarifs.push(Tarif(30, 150));
        tarifs.push(Tarif(50, 200));
        tarifs.push(Tarif(999, 2997));

        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
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
            
            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint40 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 5e7, "Zero amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 400, "Max 400 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;
        player.total_deposited += msg.value;

        _refPayout(msg.sender, msg.value);

        owner.transfer(msg.value / 10);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
        
        if (player.deposits.length == 1) {
           player.last_withdrawal_time= uint40(block.timestamp);
           }
        
    }
    
     function reinvest() external {
      Player storage player = players[msg.sender];
      
      _payout(msg.sender);
      
      require(player.deposits.length < 400, "Max 400 deposits per address");
      require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");
      
      uint256 reinv = player.dividends + player.match_bonus;
      
      player.deposits.push(Deposit({
            tarif: 3,
            amount: reinv,
            time: uint40(block.timestamp)
      }));
      
      player.total_invested += reinv;
      Reinvested += reinv;
            
      player.dividends = 0;
      player.match_bonus = 0;
      
      emit Reinvest(msg.sender, reinv);


    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        
        uint256 total = player.total_deposited;
        uint40 t = uint40(block.timestamp);
        
        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");
        require(t > player.last_withdrawal_time + 86400, "No withdrawals left today");
        
        if (player.dividends+player.match_bonus < total){
        uint256 x = player.dividends/3;
        uint256 y = player.match_bonus/3;
        
        uint256 amount = x + y;

        player.dividends -= x;
        player.match_bonus -= y;
        
       
        player.last_withdrawal_time = uint40(block.timestamp);
        player.total_withdrawn += amount;
        withdrawn += amount;
        
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
        }
        else {
        uint256 amount = player.dividends +player.match_bonus;
        
        player.dividends = 0;
        player.match_bonus= 0;
        
        player.last_withdrawal_time = uint40(block.timestamp);
        player.total_withdrawn += amount;
        withdrawn += amount;
        
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
        }

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
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256 total_deposited, uint256 currentmatchbonus, uint40 lastwithdrawseconds, uint256[3] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            player.total_deposited,
            player.match_bonus,
            player.last_withdrawal_time,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _Reinvested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, Reinvested, withdrawn, match_bonus);
    }
}