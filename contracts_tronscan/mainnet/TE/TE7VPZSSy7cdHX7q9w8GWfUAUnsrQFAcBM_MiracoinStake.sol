//SourceUnit: BasicToken.sol

pragma solidity ^0.4.25;

import "./TRC20.sol";

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is TRC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


//SourceUnit: BurnableToken.sol

pragma solidity ^0.4.25;

import "./BasicToken.sol";


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


//SourceUnit: FreezableMintableToken.sol

pragma solidity ^0.4.25;

import "./MintableToken.sol";
import "./StandardToken.sol";

contract FreezableToken is StandardToken {
    // freezing chains
    mapping (bytes32 => uint64) internal chains;
    // freezing amounts for each chain
    mapping (bytes32 => uint) internal freezings;
    // total freezing balance per address
    mapping (address => uint) internal freezingBalance;

    event Freezed(address indexed to, uint64 release, uint amount);
    event Released(address indexed owner, uint amount);

    /**
     * @dev Gets the balance of the specified address include freezing tokens.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner) + freezingBalance[_owner];
    }

    /**
     * @dev Gets the balance of the specified address without freezing tokens.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function freezingBalanceOf(address _owner) public view returns (uint256 balance) {
        return freezingBalance[_owner];
    }

    /**
     * @dev gets freezing count
     * @param _addr Address of freeze tokens owner.
     */
    function freezingCount(address _addr) public view returns (uint count) {
        uint64 release = chains[toKey(_addr, 0)];
        while (release != 0) {
            count++;
            release = chains[toKey(_addr, release)];
        }
    }

    /**
     * @dev gets freezing end date and freezing balance for the freezing portion specified by index.
     * @param _addr Address of freeze tokens owner.
     * @param _index Freezing portion index. It ordered by release date descending.
     */
    function getFreezing(address _addr, uint _index) public view returns (uint64 _release, uint _balance) {
        for (uint i = 0; i < _index + 1; i++) {
            _release = chains[toKey(_addr, _release)];
            if (_release == 0) {
                return;
            }
        }
        _balance = freezings[toKey(_addr, _release)];
    }

    /**
     * @dev freeze your tokens to the specified address.
     *      Be careful, gas usage is not deterministic,
     *      and depends on how many freezes _to address already has.
     * @param _to Address to which token will be freeze.
     * @param _amount Amount of token to freeze.
     * @param _until Release date, must be in future.
     */
    function freezeTo(address _to, uint _amount, uint64 _until) public {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_amount);

        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freeze(_to, _until);
        emit Transfer(msg.sender, _to, _amount);
        emit Freezed(_to, _until, _amount);
    }

    /**
     * @dev release first available freezing tokens.
     */
    function releaseOnce() public {
        bytes32 headKey = toKey(msg.sender, 0);
        uint64 head = chains[headKey];
        require(head != 0);
        require(uint64(block.timestamp) > head);
        bytes32 currentKey = toKey(msg.sender, head);

        uint64 next = chains[currentKey];

        uint amount = freezings[currentKey];
        delete freezings[currentKey];

        balances[msg.sender] = balances[msg.sender].add(amount);
        freezingBalance[msg.sender] = freezingBalance[msg.sender].sub(amount);

        if (next == 0) {
            delete chains[headKey];
        } else {
            chains[headKey] = next;
            delete chains[currentKey];
        }
        emit Released(msg.sender, amount);
    }

    /**
     * @dev release all available for release freezing tokens. Gas usage is not deterministic!
     * @return how many tokens was released
     */
    function releaseAll() public returns (uint tokens) {
        uint release;
        uint balance;
        (release, balance) = getFreezing(msg.sender, 0);
        while (release != 0 && block.timestamp > release) {
            releaseOnce();
            tokens += balance;
            (release, balance) = getFreezing(msg.sender, 0);
        }
    }

    function toKey(address _addr, uint _release) internal pure returns (bytes32 result) {
        // WISH masc to increase entropy
        result = 0x5749534800000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_addr, 0x10000000000000000))
            result := or(result, and(_release, 0xffffffffffffffff))
        }
    }

    function freeze(address _to, uint64 _until) internal {
        require(_until > block.timestamp);
        bytes32 key = toKey(_to, _until);
        bytes32 parentKey = toKey(_to, uint64(0));
        uint64 next = chains[parentKey];

        if (next == 0) {
            chains[parentKey] = _until;
            return;
        }

        bytes32 nextKey = toKey(_to, next);
        uint parent;

        while (next != 0 && _until > next) {
            parent = next;
            parentKey = nextKey;

            next = chains[nextKey];
            nextKey = toKey(_to, next);
        }

        if (_until == next) {
            return;
        }

        if (next != 0) {
            chains[key] = next;
        }

        chains[parentKey] = _until;
    }
}


contract FreezableMintableToken is FreezableToken, MintableToken {
    /**
     * @dev Mint the specified amount of token to the specified address and freeze it until the specified date.
     *      Be careful, gas usage is not deterministic,
     *      and depends on how many freezes _to address already has.
     * @param _to Address to which token will be freeze.
     * @param _amount Amount of token to mint and freeze.
     * @param _until Release date, must be in future.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintAndFreeze(address _to, uint _amount, uint64 _until) public onlyOwner canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);

        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freeze(_to, _until);
        emit Mint(_to, _amount);
        emit Freezed(_to, _until, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}


//SourceUnit: MintableToken.sol

pragma solidity ^0.4.25;

import "./StandardToken.sol";
import "./Ownable.sol";


/**
 * @title Mintable token
 * @dev Simple TRC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


//SourceUnit: MiraToken.sol

pragma solidity ^0.4.25;

import "./MintableToken.sol";
import "./BurnableToken.sol";
import "./Pausable.sol";
import "./FreezableMintableToken.sol";


contract Consts {
    uint public constant TOKEN_DECIMALS = 18;
    uint8 public constant TOKEN_DECIMALS_UINT8 = 18;
    uint public constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    string public constant TOKEN_NAME = "MIRA";
    string public constant TOKEN_SYMBOL = "MIRA";
    bool public constant PAUSED = false;
    address public constant TARGET_USER = 0x5d4C83C3d283056ae6F51130F8DD9dC41462f358;
    bool public constant CONTINUE_MINTING = true;
}


contract MIRATOKEN is Consts, FreezableMintableToken, BurnableToken, Pausable {
    event Initialized();
    bool public initialized = false;

    constructor() public {
        init();
        
    }

    function name() public pure returns (string) {
        return TOKEN_NAME;
    }

    function symbol() public pure returns (string) {
        return TOKEN_SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return TOKEN_DECIMALS_UINT8;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transfer(_to, _value);
    }

    function init() private {
        require(!initialized);
        initialized = true;

        if (PAUSED) {
            pause();
        }


        if (!CONTINUE_MINTING) {
            finishMinting();
        }

        emit Initialized();
    }
}


//SourceUnit: MiracoinStake.sol

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity >=0.4.20;
import "./MiraToken.sol";


contract MiracoinStake {
    address public owner;
    address  a;

    
    TRC20 public token;
    
    uint8 decimals;
    
    struct User{
        bool referred;
        address referred_by;
        uint256 total_invested_amount;
        uint256 referal_profit;
    }
    
    struct Referal_levels{
        uint256 level_1;
    }

    struct Panel_1{
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
        uint256 remaining_inv_prof;
    }


    mapping(address => Panel_1) public panel_1;

    mapping(address => User) public user_info;
    mapping(address => Referal_levels) public refer_info;
    uint public totalcontractamount;



    constructor() public {
        owner = msg.sender;
        a = msg.sender;
        
        //token = TRC20(0x417d984528e2a25fb086c9abfeedc2d8a93bcb8d10);
        token = TRC20(0x415913b1794f4628246cbe81c0a92bd8d7305ff29c);
                        
    }

    function getContractERC20Balance() public view returns (uint256){
       return token.balanceOf(address(this));
    }

    function withdraw_tokens_admin(uint256 value) public returns(bool){
        require(msg.sender == owner, 'current user is not admin');
        token.transfer(msg.sender, value);
    }


    // -------------------- PANEL 1 -------------------------------  
    // 0.5-1% : 90 days == 62.95% profit :: 90 days 0.699/day  == 0.7

function invest_panel1(uint256 t_value) public {
        // 50,000,000 = 50 trx
        require(t_value >= 10 * (10 ** 18), 'Please Enter Amount no less than 10');
        require(t_value <= 100000 * (10 ** 18), 'Please Enter Amount no less than 10');

        
        if( panel_1[msg.sender].time_started == false){
            panel_1[msg.sender].start_time = now;
            panel_1[msg.sender].time_started = true;
            panel_1[msg.sender].exp_time = now + 90 days; //90*24*60*60  = 90 days
        }
            // // Approve to contract for taking tokens in
            // token.approve(address(this), t_value); // doesn't work external

            // transfer the tokens from user to contract
            token.transferFrom(msg.sender, address(this), t_value);

            // assign token amount to bot accout
            panel_1[msg.sender].invested_amount += t_value;
            user_info[msg.sender].total_invested_amount += t_value; 
            
            referral_system(t_value);
            
            //neg
        if(panel1_days() <= 90){ //90
            panel_1[msg.sender].profit += ((t_value*7*(90 - panel1_days()))/(1000)); // 90 - panel_days()
        }

    }

    function is_plan_completed_p1() public view returns(bool){
        if(panel_1[msg.sender].exp_time != 0){
            if(now >= panel_1[msg.sender].exp_time){
                return true;
            }
        if(now < panel_1[msg.sender].exp_time){
            return false;
            }
        }else{
            return false;
        }
    }

    function plan_completed_p1() public  returns(bool){
        if( panel_1[msg.sender].exp_time != 0){
        if(now >= panel_1[msg.sender].exp_time){
            reset_panel_1();
            return true;
        }
        if(now < panel_1[msg.sender].exp_time){
            return false;
            }
        }

    }

    function current_profit_p1() public view returns(uint256){
        uint256 local_profit ;
        if(now <= panel_1[msg.sender].exp_time){

        if( (panel1_days()%7 +1) ==  1){
                // Day_1 = 0.5 : 64
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(64*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  2){
                // Day_2 = 0.8 : 102
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(102*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  3){
                //Day_3 = 0.6 : 77
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(77*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }

        }           
        if((panel1_days()%7 +1) ==  4){
                // Day_4 = 0.7 : 90
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  5){
                // Day_5 = 1 : 129
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(129*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  6){
                // Day_6 = 0.55 : 71
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(71*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  7){
                // Day_7 = 0.75 : 96
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(96*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }

            // if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
            //     local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
            //     return local_profit;
            // }else{
            //     return 0;
            // }
        }
        if(now > panel_1[msg.sender].exp_time){
            return panel_1[msg.sender].profit;
        }
    }

    function panel1_days() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return ((now - panel_1[msg.sender].start_time)/(1 days)); // change to 24*60*60   1 days
        }
        else {
            return 0;
        }
    }
    
    function withdraw_profit_panel1(uint256 amount) public payable {
        uint256 current_profit = current_profit_p1();
        require(amount <= current_profit, ' Amount sould be less than profit');
        panel_1[msg.sender].profit_withdrawn = panel_1[msg.sender].profit_withdrawn + amount;
        //neg
        panel_1[msg.sender].profit = panel_1[msg.sender].profit - amount;
        token.transfer(msg.sender, (amount - ((5*amount)/100)));
        token.transfer(a, ((5*amount)/100));
    }

    function is_valid_time_p1() public view returns(bool){
        if(panel_1[msg.sender].time_started == true){
        return (now > l_l1())&&(now < u_l1());    
        }
        else {
            return true;
        }
    }

    function l_l1() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return (1 days)*panel1_days() + panel_1[msg.sender].start_time;     // 24*60*60 1 days
        }else{
            return now;
        }
        
    }
    function u_l1() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return ((1 days)*panel1_days() + panel_1[msg.sender].start_time + 10 hours);    // 1 days  , 8 hours
        }else {
            return now + (10 hours);  // 8*60*60  8 hours
        }
    }

    function reset_panel_1() private{
        panel_1[msg.sender].remaining_inv_prof = panel_1[msg.sender].profit + panel_1[msg.sender].invested_amount;

        panel_1[msg.sender].invested_amount = 0;
        panel_1[msg.sender].profit = 0;
        panel_1[msg.sender].profit_withdrawn = 0;
        panel_1[msg.sender].start_time = 0;
        panel_1[msg.sender].exp_time = 0;
        panel_1[msg.sender].time_started = false;
    }  

    function withdraw_all_p1() public payable{

        token.transfer(msg.sender, panel_1[msg.sender].remaining_inv_prof);
        panel_1[msg.sender].remaining_inv_prof = 0;

    }


    




 //------------------- Referal System ------------------------

    function refer(address ref_add) public {
        require(user_info[msg.sender].referred == false, ' Already referred ');
        require(ref_add != msg.sender, ' You cannot refer yourself ');
        
        user_info[msg.sender].referred_by = ref_add;
        user_info[msg.sender].referred = true;        
        
        address level1 = user_info[msg.sender].referred_by;
        
        if( (level1 != msg.sender) && (level1 != address(0)) ){
            refer_info[level1].level_1 += 1;
        }   
    }
    

    function referral_system(uint256 amount) private {
        address level1 = user_info[msg.sender].referred_by;

        if( (level1 != msg.sender) && (level1 != address(0)) ){
            user_info[level1].referal_profit += (amount*7)/(100);
        }

    }

    function referal_withdraw() public {    
        uint256 pending = user_info[msg.sender].referal_profit;
        user_info[msg.sender].referal_profit = 0;
        
        token.transfer(msg.sender, pending);
    }  



}

 


//SourceUnit: Ownable.sol

pragma solidity ^0.4.25;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


//SourceUnit: Pausable.sol

pragma solidity ^0.4.25;


import "./Ownable.sol";


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


//SourceUnit: StandardToken.sol

pragma solidity ^0.4.25;

import "./BasicToken.sol";
import "./TRC20.sol";

/**
 * @title Standard TRC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is TRC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


//SourceUnit: TRC20.sol

pragma solidity ^0.4.25;

contract TRC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title TRC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract TRC20 is TRC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}