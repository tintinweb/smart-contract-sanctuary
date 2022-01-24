/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function deciwamals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
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
}


/*
* @title  Jurassic Period System, build in BSC Network
* @dev    A Blockchain Game system built on smart contract technology. Open to all, transparent to all.
*         The worlds first decentralized, community support fund
*/
contract JurassicPeriodV2 is Ownable {
    
    IERC20 public investToken;
    using SafeMath for uint256;

    /* Player base data struct define */
    struct Player {
        address referral;
        uint256 level_id;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 total_dividends;
        uint256 total_referral_bonus;
        uint256 last_payout;
        address[] referrals;
    }

    /* Player animal object struct define */
    struct PlayerAnimal {
        uint256 id;
        uint256 status;
        uint256 time;
        uint256 expire;
        uint256 ended;
        uint256 payout;
        uint256 eggs;
        uint256 referral_eggs;
        uint256 total_eggs;
        uint256 total_referral_eggs;
        uint256 last_payout;
        address referral;
        address[] referrals;
        uint256 team_count;
    }
    
    /* Deposit smart contract address */
    //address public invest_token_address = 0x59cC61BF9fd75368e8c06CE17E43C6aC59F516C3;
    address public invest_token_address = 0x4EE7c7b78908aAAF74C3BC94755F4Ade1A066221;
    uint256 public invest_token_decimal = 8;
    /* Platform official address */
    address payable public platform_address = 0xE88a1fAC4234294c79956f8F228974366A983357;
    
    uint256 public total_dividends;
    uint256 public total_referral_bonus;
    
    /* Animal defined data */
    uint256[] public animal_ids =       [1,2,3,4,5,6,7,8,9];
    uint256[] public animal_prices =    [500000,1000000,2000000,5000000,10000000,20000000,30000000,50000000,100000000];
    uint256[] public animal_pays =      [2,2,2,2,2,2,2,2,2];//1 for BNB,2 for JRSP
    uint256[] public animal_daily_yields =  [120,120,120,120,120,120,120,120,120];
    uint256[] public animal_statuses =    [1,1,1,1,1,0,0,0,0];
    uint256[] public animal_exchange_rates1 =   [8,5,3,1,1,1,1,1,1];
    uint256[] public animal_exchange_rates2 =   [1,1,1,1,2,4,6,8,15];
    uint256[] public animal_total_nums =        [0,0,0,0,0,0,0,0,0];

    /* Referral bonuses data define */
    uint256[] public referral_bonuses = [5,10,15,20,25,30];

    /* Yield section config data */
    uint256[] public yield_section_limits = [2,4000,6000,8000,10000];
    
    /* Animal feed defined data */
    uint256[] public animal_feed_ids =    [1,2,3,4,5,6,7,8,9];
    uint256[] public animal_feed_prices =         [30000,60000,100000,300000,600000,1200000,1800000,2400000,4500000];
    uint256[] public yield_section1_feed_prices = [15000,30000,50000, 150000,300000,600000, 900000, 1200000,2250000];
    uint256[] public yield_section2_feed_prices = [7000, 15000,25000, 75000, 150000,300000, 450000, 600000, 1120000];
    uint256[] public yield_section3_feed_prices = [4000, 7000, 13000, 38000, 75000, 150000, 225000, 300000, 560000];
    uint256[] public yield_section4_feed_prices = [2000, 4000, 7000,  19000, 38000, 75000,  114000, 150000, 280000];
    uint256[] public yield_section5_feed_prices = [1000, 2000, 4000,  8000,  19000, 38000,  55000,  75000,  140000];

    /*Animal daily sell limit number*/
    uint256 constant public animal_daily_sell_limit = 1000;
    uint256 public animal_next_opentime = 1640404800;  //initial date: 2021-12-25 12:00
    uint256[] public animal_daily_nums = [0,0,0,0,0,0,0,0,0];

    /* Mapping data list define */
    mapping(address => Player) public players;
    mapping(address => PlayerAnimal) public animal1s;
    mapping(address => PlayerAnimal) public animal2s;
    mapping(address => PlayerAnimal) public animal3s;
    mapping(address => PlayerAnimal) public animal4s;
    mapping(address => PlayerAnimal) public animal5s;
    mapping(address => PlayerAnimal) public animal6s;
    mapping(address => PlayerAnimal) public animal7s;
    mapping(address => PlayerAnimal) public animal8s;
    mapping(address => PlayerAnimal) public animal9s;

    event BuyAnimal(address indexed addr,uint256 animal_id);
    event BuyFeed(address indexed addr,uint256 animal_id,uint256 quantity);
    event Harvest(address indexed addr);
    event Exchange(address indexed addr);
    event SetReferral(address indexed addr,address refferal,uint256 animal_id);
	
    constructor() public {
        /* Create invest token instance  */
        investToken = IERC20(invest_token_address);
    }
    
    /* Function to receive Ether. msg.data must be empty */
    receive() external payable {}

    /* Fallback function is called when msg.data is not empty */ 
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
        
    /*
    * @dev format token amount with token decimal
    */
    function _getTokenAmount(uint256 _amount,uint256 _token_decimal) 
        pure
        private
        returns(uint256 token_amount)
    {
        uint256 token_decimals = 10 ** _token_decimal;
        token_amount = _amount * token_decimals;   
        return token_amount;
    }

    /*
    * @dev get animal price
    */
    function _getAnimalFeedPrice(uint256 id)
        view
        private
        returns(uint256 _price)
    {
        uint256 animal_id = id-1;
        uint256 _total_num = animal_total_nums[animal_id];
        _price = animal_feed_prices[animal_id];
        if(_total_num > yield_section_limits[0]){
            _price = yield_section1_feed_prices[animal_id];
        }
        if(_total_num > yield_section_limits[1]){
            _price = yield_section2_feed_prices[animal_id];
        }
        if(_total_num > yield_section_limits[2]){
            _price = yield_section3_feed_prices[animal_id];
        }
        if(_total_num > yield_section_limits[3]){
            _price = yield_section4_feed_prices[animal_id];
        }
        if(_total_num > yield_section_limits[4]){
            _price = yield_section5_feed_prices[animal_id];
        }
        return _price;
    }
    
    /*
    * @dev get animal feed prices
    */
    function _getAnimalFeedPrices()
        view
        private
        returns(uint256[] memory prices)
    {
        uint256[] memory _feed_prices = new uint256[](9);
        for(uint8 i = 0; i < 9; i++){
            _feed_prices[i] = _getAnimalFeedPrice(i+1);
        }
        return _feed_prices;
    }

     /*
    * @dev get the animal day payout profit, if total yield reached reduce limit, invest day rate will be reduce
    */
    function _getAnimalDayPayoutOf(uint256 animal_id)
        view
        private
        returns(uint256 daily_yield)
    {
        uint256 _total_num = animal_total_nums[animal_id-1];
        uint256 _daily_yield = animal_daily_yields[animal_id-1];
        //format daily payout amount
        _daily_yield = _getTokenAmount(_daily_yield, invest_token_decimal);
        if(_total_num > yield_section_limits[0]){
            _daily_yield = _daily_yield / 2;
        }
        if(_total_num > yield_section_limits[1]){
            _daily_yield = _daily_yield / 2;
        }
        if(_total_num > yield_section_limits[2]){
            _daily_yield = _daily_yield / 2;
        }
        if(_total_num > yield_section_limits[3]){
            _daily_yield = _daily_yield / 2;
        }
        if(_total_num > yield_section_limits[4]){
            _daily_yield = _daily_yield / 2;
        }
        return _daily_yield;
    }

    /*
    * @dev get animal next sell opentime
    */
    function _getAnimalNextOpentime()
        view
        private
        returns(uint256 opentime)
    {
       uint256 _opentime = animal_next_opentime;
       uint256 blocktime = uint256(block.timestamp);
       while(_opentime < blocktime){
           _opentime = _opentime.add(86400);
       }
       return _opentime;
    }
    
    /*
    * @dev get animal daily stock quantity
    */
    function _getAnimalDailyStocks()
        view
        private
        returns(uint256[] memory stocks)
    {
        uint256[] memory _stocks = new uint256[](9);
        uint256 blocktime = uint256(block.timestamp);
        uint256 _limit = animal_daily_sell_limit;
        if(animal_next_opentime < blocktime){
            for(uint8 i = 0; i < 9; i++){
                _stocks[i] = _limit;
            }
        } else {
            for(uint8 i = 0; i < 9; i++){
                _stocks[i] = _limit - animal_daily_nums[i];
            }
        }
        return _stocks;
    }

    /*
    * @dev get animal open status
    */
    function _getAnimalStatus(uint256 _animal_id)
        view
        private
        returns(uint256 status)
    {
        uint256 _status = animal_statuses[_animal_id-1];
        if(_status == 0) {
            if(animal_total_nums[_animal_id-1]>= yield_section_limits[0]){
                _status = 1;
            }
        }
        return _status;
    }

    /*
    * @dev get all animal open status
    */
    function _getAnimalStatuses()
        view
        private
        returns(uint256[] memory statuses)
    {
        uint256[] memory _statuses = new uint256[](9);
        for(uint8 i = 0; i < 9; i++){
            _statuses[i] = _getAnimalStatus((i+1));
        }
        return _statuses;
    }

    /*
    * @dev update animal next sell opentime & reset animal daily sell quantity
    */
    function _updateAnimalNextOpentime()
        private
    {
        uint256 blocktime = uint256(block.timestamp);
        if(animal_next_opentime < blocktime){
            animal_next_opentime = _getAnimalNextOpentime();
            animal_daily_nums = [0,0,0,0,0,0,0,0,0];
        }
    }

    /*
    * @dev get animal daily nums
    */
    function _getAnimalDailyNums()
        view
        private
        returns(uint256[] memory daily_nums)
    {
        uint256[] memory _daily_nums = new uint256[](9);
        uint256 blocktime = uint256(block.timestamp);
        if(animal_next_opentime < blocktime){
            for(uint8 i = 0; i < 9; i++){
                _daily_nums[i] = 0;
            }
        } else {
            for(uint8 i = 0; i < 9; i++){
                _daily_nums[i] = animal_daily_nums[i];
            }
        }
        return _daily_nums;
    }
    
    /*
    * @dev get user animal list
    */
    function _getUserAnimalList(address _addr)
        view
        private
        returns(PlayerAnimal[] memory animals)
    {
        PlayerAnimal[] memory _animals = new PlayerAnimal[](9);
        for(uint8 i = 0; i < 9; i++){
            _animals[i] = _getUserAnimalInfo(_addr,(i+1));
        }
        return _animals;
    }

    /*
    * @dev get user animal status
    */
    function _getUserAnimalInfo(address _addr,uint256 _animal_id)
        view
        private
        returns(PlayerAnimal memory animal)
    {
        PlayerAnimal memory _animal = animal1s[_addr];
        if(_animal_id == 2) _animal = animal2s[_addr];
        if(_animal_id == 3) _animal = animal3s[_addr];
        if(_animal_id == 4) _animal = animal4s[_addr];
        if(_animal_id == 5) _animal = animal5s[_addr];
        if(_animal_id == 6) _animal = animal6s[_addr];
        if(_animal_id == 7) _animal = animal7s[_addr];
        if(_animal_id == 8) _animal = animal8s[_addr];
        if(_animal_id == 9) _animal = animal9s[_addr];
        
        /* get animal status,verify the animal is ended or not */
        if(_animal.status == 1 && _animal.ended < uint256(block.timestamp)) {
            _animal.status = 3;
        }
        //get animal current payout total
        _animal.payout = _payoutOf(_addr,_animal_id);
        
        return _animal;
    }

    /*
    * @dev get user animal data with storage way
    */
    function _getStorageAnimal(address _addr,uint256 _animal_id)
        view
        private
        returns(PlayerAnimal storage animal)
    {
        PlayerAnimal storage _animal = animal1s[_addr];
        if(_animal_id == 2) _animal = animal2s[_addr];
        if(_animal_id == 3) _animal = animal3s[_addr];
        if(_animal_id == 4) _animal = animal4s[_addr];
        if(_animal_id == 5) _animal = animal5s[_addr];
        if(_animal_id == 6) _animal = animal6s[_addr];
        if(_animal_id == 7) _animal = animal7s[_addr];
        if(_animal_id == 8) _animal = animal8s[_addr];
        if(_animal_id == 9) _animal = animal9s[_addr];
        return _animal;
    }

        
    /*
    * @dev update user referral data
    */
    function _setReferral(address _addr, address _referral, uint256 _animal_id) 
        private 
    {
        Player storage player = players[_addr];
        if(player.referral != address(0)) {  _referral = player.referral; }
        PlayerAnimal storage animal = _getStorageAnimal(_addr,_animal_id);

        if(_referral != _addr && _referral != address(0)) {

            /* Set player referral data */
            if(player.referral == address(0)){
                Player storage ref_player = players[_referral];
                if(ref_player.referral != address(0) || _referral == platform_address){
                    player.referral = _referral;
                    ref_player.referrals.push(_addr);
                }
            }
            
            /* Set player animal referral data */
            if(animal.referral == address(0)) {
                animal.referral = _referral;
                /* update user referral address list*/
                PlayerAnimal storage ref_animal = _getStorageAnimal(_referral,_animal_id);
                ref_animal.referrals.push(_addr);
            }

            //update team member count
            _updateTeamCount(_addr,_animal_id);
        }
    }

    /*
    * @dev update user team member count
    */
    function _updateTeamCount(address _addr,uint256 _animal_id)
        private
    {
        PlayerAnimal memory animal = _getUserAnimalInfo(_addr, _animal_id);
        address ref = animal.referral;
        while(true){
            if(ref == address(0)) break;

            PlayerAnimal storage ref_animal = _getStorageAnimal(ref, _animal_id);
            ref_animal.team_count += 1;
            ref = ref_animal.referral;
        }
    }
    
    
    /*
    * @dev Grant user referral bonus in user havest
    */
    function _referralPayout(address _addr, uint256 _amount, uint256 _animal_id) 
        private
    {
        address ref = players[_addr].referral;
        if(ref == address(0)) return;

        PlayerAnimal storage ref_animal = _getStorageAnimal(ref, _animal_id);
        uint256 blocktime = uint256(block.timestamp);

        // verify the referral animal feed is expired or not
        if(ref_animal.expire < blocktime) return;

        uint256 bonus_index = ref_animal.referrals.length;
        if(bonus_index==0) return;
        if(bonus_index > referral_bonuses.length) {
            bonus_index = referral_bonuses.length;
        }
        uint256 _bonus_rate = referral_bonuses[bonus_index-1];
        uint256 _bonus_eggs = _amount * _bonus_rate / 100;

        //update referral player bonus data
        ref_animal.referral_eggs += _bonus_eggs;
    }
    
    
    /*
    * @dev get user animal current total pending profit
    * @return user animal pending payout amount
    */
    function _payoutOf(address _addr,uint256 _animal_id)
        view
        private 
        returns(uint256 value)
    {
        PlayerAnimal storage _animal = _getStorageAnimal(_addr,_animal_id);
        if(_animal.id > 0) {
            uint256 _day_payout = _getAnimalDayPayoutOf(_animal.id);
            uint256 blocktime = uint256(block.timestamp);
            uint256 from = _animal.last_payout > _animal.time ? _animal.last_payout : _animal.time;
            uint256 to = blocktime > _animal.expire ? _animal.expire : blocktime;
            if(from < to) {
                value = _day_payout * (to - from) / 86400;
            }
        }
        return value;
    }
    

    /*
    * @dev get animal list
    */
    function getAnimalList()
        view 
        external 
        returns(
            uint256[] memory ids,uint256[] memory prices,uint256[] memory pays, 
            uint256[] memory total_nums,uint256[] memory statuses, uint256[] memory stocks, 
            uint256[] memory daily_nums
        )
    {
        uint256[] memory _statuses = _getAnimalStatuses();
        uint256[] memory _stocks = _getAnimalDailyStocks();
        uint256[] memory _daily_nums = _getAnimalDailyNums();
        return (
            animal_ids,
            animal_prices,
            animal_pays,
            animal_total_nums,
            _statuses,
            _stocks,
            _daily_nums
        );
    }
    
    /*
    * @dev get user animal frame list
    */
    function getUserAnimalList(address _addr)
        view 
        external 
        returns(
            uint256[] memory ids,uint256[] memory payouts,uint256[] memory statuses,
            uint256[] memory expires,uint256[] memory referral_nums,uint256[] memory referral_eggs
        )
    {
        //user animal list
        PlayerAnimal[] memory _animals = _getUserAnimalList(_addr);
        uint256[] memory _payouts = new uint256[](9);
        uint256[] memory _statuses = new uint256[](9);
        uint256[] memory _expires = new uint256[](9);
        uint256[] memory _referral_nums = new uint256[](9);
        uint256[] memory _referral_eggs = new uint256[](9);
        
        for(uint256 i = 0; i < 9; i++){
            _payouts[i] = _animals[i].payout + _animals[i].eggs;
            _statuses[i] = _animals[i].status;
            _expires[i] = _animals[i].expire;
            _referral_nums[i] = _animals[i].referrals.length;
            _referral_eggs[i] = _animals[i].referral_eggs;
        }
        return (
            animal_ids,
            _payouts,
            _statuses,
            _expires,
            _referral_nums,
            _referral_eggs
        );
    }

    /*
    * @dev get user animal frame list
    */
    function getUserAnimalDatas(address _addr)
        view 
        external 
        returns(
            uint256[] memory statuses,uint256[] memory referral_nums,
            uint256[] memory team_counts,uint256[] memory eggs,uint256[] memory referral_eggs,
            uint256[] memory dividends,uint256[] memory referral_bonus
        )
    {
        //user animal list
        PlayerAnimal[] memory _animals = _getUserAnimalList(_addr);
        uint256[] memory _statuses = new uint256[](9);
        uint256[] memory _referral_nums = new uint256[](9);
        uint256[] memory _total_eggs = new uint256[](9);
        uint256[] memory _total_referral_eggs = new uint256[](9);
        uint256[] memory _total_dividends = new uint256[](9);
        uint256[] memory _total_referral_bonus = new uint256[](9);
        uint256[] memory _team_counts = new uint256[](9);
        
        for(uint256 i = 0; i < 9; i++) {
            uint256 _dividends = _animals[i].total_eggs / animal_exchange_rates1[i] * animal_exchange_rates2[i];
            uint256 _referral_bonus = _animals[i].total_referral_eggs / animal_exchange_rates1[i] * animal_exchange_rates2[i];

            _statuses[i] = _animals[i].status;
            _referral_nums[i] = _animals[i].referrals.length;
            _total_eggs[i] = _animals[i].total_eggs;
            _total_referral_eggs[i] = _animals[i].total_referral_eggs;
            _total_dividends[i] = _dividends;
            _total_referral_bonus[i] = _referral_bonus;
            _team_counts[i] = _animals[i].team_count;
        }
        return (
            _statuses,
            _referral_nums,
            _team_counts,
            _total_eggs,
            _total_referral_eggs,
            _total_dividends,
            _total_referral_bonus
        );
    }

    /*
    * @dev get invest period list
    */
    function getAnimalFeedList()
        view 
        external 
        returns(uint256[] memory ids,uint256[] memory prices,uint256[] memory pays,uint256[] memory statuses)
    {
        uint256[] memory _feed_prices = _getAnimalFeedPrices();
        uint256[] memory _statuses = _getAnimalStatuses();
        return (
            animal_feed_ids,
            _feed_prices,
            animal_pays,
            _statuses
        );
    }

    /*
    * @dev user do set refferal action
    */
    function setReferral(address _referral,uint256 _animal_id)
        payable
        external 
    {
        require(_animal_id >= 1 && _animal_id <= 9 , "Invalid animal Id");

        PlayerAnimal memory player = _getUserAnimalInfo(msg.sender,_animal_id-1);
        require(player.referral == address(0), "Referral has been set");
        require(_referral != address(0), "Invalid Referral address");
        
        PlayerAnimal memory ref_player = _getUserAnimalInfo(player.referral,_animal_id-1);
        require(ref_player.referral != address(0) || _referral == platform_address, "Referral address not activated yet");

        _setReferral(msg.sender,_referral,_animal_id);
        emit SetReferral(msg.sender,_referral,_animal_id);
    }
    
    /*
    * @dev user do buy animal action, update user animal data
    */
    function buyAnimal(address _referral, uint256 _animal_id) 
        external
        payable
    {
        require(_animal_id >= 1 && _animal_id <= 9 , "Invalid Animal Id");

        //verify the animal opening status
        uint256 _animal_status = _getAnimalStatus(_animal_id);
        require(_animal_status == 1, "Animal purchase opensoon");
        //verify animal daily sell limit status
        require(animal_daily_sell_limit >= animal_daily_nums[_animal_id-1], "Animal sold out today");

        PlayerAnimal memory _animal = _getUserAnimalInfo(msg.sender, _animal_id);
        PlayerAnimal storage animal = _getStorageAnimal(msg.sender, _animal_id);

        //Animal must be dided or not actived
        require(_animal.status != 1, "Animal is actived now");

        //get animal pay method
        uint256 _payMethod = animal_pays[_animal_id-1];
        uint256 blocktime = uint256(block.timestamp);

        //BNB pay to buy animal
        if(_payMethod == 1) {
            uint256 _amount = _getTokenAmount(animal_prices[_animal_id-1], 14);
            require(msg.value == _amount, "Invalid animal price");
            
            //Transfer BNB to platform address
            platform_address.transfer(msg.value);
        }
        //JRSP pay to buy animal
        else {
            uint256 _decimal = invest_token_decimal - 4;
            uint256 _token_amount = _getTokenAmount(animal_prices[_animal_id-1], _decimal);
            require(investToken.balanceOf(msg.sender) >= _token_amount, "Insufficient funds");

            /* Transfer user address token to contract address*/
            require(investToken.transferFrom(msg.sender, address(this), _token_amount), "transferFrom failed");
        }

        //update animal next open time
        _updateAnimalNextOpentime();

        //update animal total buy number
        animal_total_nums[_animal_id-1] += 1;
        animal_daily_nums[_animal_id-1] += 1;

        //update player animal data
        if(animal.id==0){
            animal.id = _animal_id;
        }
        animal.status = 1;
        animal.time = blocktime;
        animal.expire = blocktime.add(86400); //expire of 1 day
        animal.ended = animal.expire.add(86400*3); //ended of 3 day
        
        //update player referral data
        _setReferral(msg.sender, _referral, _animal_id);
        
        emit BuyAnimal(msg.sender, _animal_id);
    }

    /*
    * @dev user do buy animal action,update user animal data
    */
    function buyFeed(uint256 _animal_id,uint256 _quantity) 
        external
        payable
    {
        require(_animal_id >= 1 && _animal_id <= 9 , "Invalid Animal Id");
        require(_quantity > 0, "Invalid quantity number");

        PlayerAnimal memory _animal = _getUserAnimalInfo(msg.sender, _animal_id);
        PlayerAnimal storage animal = _getStorageAnimal(msg.sender, _animal_id);
        
        //Animal must be dided or not actived
        require(_animal.status == 1, "Animal is not active now");

        //get animal pay method
        uint256 _payMethod = animal_pays[_animal_id-1];
        uint256 blocktime = uint256(block.timestamp);
        uint256 _feed_price = _getAnimalFeedPrice(_animal_id).mul(_quantity);

        // BNB pay to buy animal feed
        if(_payMethod == 1) {
            uint256 _amount = _getTokenAmount(_feed_price, 14);
            require(msg.value == _amount, "Invalid animal price");
            //Transfer BNB to platform address
            platform_address.transfer(msg.value);
        }
        // JRSP pay to buy animal feed
        else {
            uint256 _decimal = invest_token_decimal - 4;
            uint256 _token_amount = _getTokenAmount(_feed_price, _decimal);
            require(investToken.balanceOf(msg.sender) >= _token_amount, "Insufficient funds");
            /* Transfer user address token to contract address*/
            require(investToken.transferFrom(msg.sender, address(this), _token_amount), "transferFrom failed");
        }
        //verify the animal is expired or not
        if(animal.expire > blocktime){
            //update feed expire time
            animal.expire = animal.expire.add(86400*_quantity);
            animal.ended = animal.expire.add(86400*3); //ended of 3 day
        }
        else {

            uint256 _profit_eggs = _animal.payout;
            animal.eggs += _profit_eggs;

            //update feed expire time
            animal.last_payout = blocktime;
            animal.expire = blocktime.add(86400*_quantity);
            animal.ended = animal.expire.add(86400*3); //ended of 3 day
        }
        emit BuyFeed(msg.sender, _animal_id, _quantity);
    }
    
    
    /*
    * @dev user do havest action, update user total havest data, grant rereferral bonus
    */
    function harvest() 
        payable 
        external 
    {
        //Player storage player = players[msg.sender];
        uint256 _total_dividends = 0;
        uint256 _total_referral_bonus = 0;

        for (uint8 _animal_id=1;_animal_id <= 9;_animal_id++) 
        {
            PlayerAnimal memory _animal = _getUserAnimalInfo(msg.sender, _animal_id);
            PlayerAnimal storage animal = _getStorageAnimal(msg.sender, _animal_id);
            uint256 _profit_eggs = _animal.payout;

            animal.eggs += _profit_eggs;
            uint256 total_eggs = animal.eggs + animal.referral_eggs;
            if(total_eggs > 0) {

                //update referral payout data
                _referralPayout(msg.sender,total_eggs,_animal_id);

                //calculate egg exchange data
                uint256 _dividends = animal.eggs / animal_exchange_rates1[_animal_id-1] * animal_exchange_rates2[_animal_id-1];
                uint256 _referral_bonus = animal.referral_eggs / animal_exchange_rates1[_animal_id-1] * animal_exchange_rates2[_animal_id-1];
                
                //update batch total withdraw token
                _total_dividends += _dividends;
                _total_referral_bonus += _referral_bonus;

                //update total eggs number
                animal.total_eggs += animal.eggs;
                animal.total_referral_eggs += animal.referral_eggs;

                //reset animal yield eggs
                animal.eggs = 0;
                animal.referral_eggs = 0;

                //update last payout time
                animal.last_payout = uint256(block.timestamp);
            }
        }

        total_dividends += _total_dividends;
        total_referral_bonus += _total_referral_bonus;

        uint256 _token_amount = _total_dividends + _total_referral_bonus;
        /* process token transfer action */
        require(investToken.approve(address(this), _token_amount), "approve failed");
        require(investToken.transferFrom(address(this), msg.sender, _token_amount), "transferFrom failed");

        emit Harvest(msg.sender);
    }
    
    /*
    * @dev get contract data info 
    * @return total invested,total investor number,total withdraw,total referral bonus
    */
    function contractInfo() 
        view 
        external 
        returns(
            uint256 _animal_next_opentime, uint256 _total_dividends, uint256 _total_referral_bonus
        ) 
    {
        uint256 _next_opentime = _getAnimalNextOpentime();
        return (
            _next_opentime, 
            total_dividends,
            total_referral_bonus
        );
    }
    
    /*
    * @dev get user info
    * @return pending withdraw amount,referral,rreferral num etc.
    */
    function userInfo(address _addr)
        view 
        external 
        returns
        (
            address _referral, uint256 _referral_num, 
            uint256 _dividends, uint256 _referral_bonus,
            uint256 _total_dividends, uint256 _total_referral_bonus
        )
    {
        Player storage player = players[_addr];
        uint256 _devidends_;
        uint256 _referral_bonus_;
        PlayerAnimal[] memory animals = _getUserAnimalList(_addr);
        for(uint8 i=0;i<animals.length;i++){
            PlayerAnimal memory animal = animals[0];
            _devidends_ += animal.eggs / animal_exchange_rates1[i] * animal_exchange_rates2[i];
            _referral_bonus_ += animal.referral_eggs / animal_exchange_rates1[i] * animal_exchange_rates2[i];
        }
        return (
            player.referral,
            player.referrals.length,
            player.dividends,
            player.referral_bonus,
            _devidends_,
            _referral_bonus_
        );
    }
}