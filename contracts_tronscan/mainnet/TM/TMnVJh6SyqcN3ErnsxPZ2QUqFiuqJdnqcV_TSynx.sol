//SourceUnit: defi3.sol

/*
The Synthetic Tron Protocol
TSynx is the backbone for synthetic NFC bonds in the tron ​​network, 
allowing anyone, anywhere to create, manage and trade synthetic NFC bonds.

official website:

    https://tsynx.com
    support@tsynx.com
*/

pragma solidity ^0.5.14;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract Context {

    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeTRC20 {
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        if (address(token) == USDTAddr) {
            (bool success,) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success, "SafeTRC20: low-level call failed");
        } else {
            callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeTRC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeTRC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {

        // require(isContract(address(token)), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "(2)SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}


contract Order is Context {
  
  address public sCollegiate;
  address public sFoundation;

  constructor() public {
    sCollegiate = _msgSender();
    sFoundation = address(0x0); 
  }

  modifier onlyCollegiate() {
    require(_msgSender() == sCollegiate, "Only for Collegiate member");
    _;
  }

  function isCollegiate() public view returns (bool) {
    return _msgSender() == sCollegiate;
  }

  function setCollegiate(address _elected) public onlyCollegiate returns(bool) {
    sCollegiate = _elected;
    return true;
  }

  function setFoundation(address new_constitution) public onlyCollegiate {
    sFoundation = new_constitution;
  }
}

contract Election is Order {
  
 bool public sCount;

  constructor() public {
    sCount = true;
  }
 
  modifier usePercent {
    require(sCount, "In election");
    _;
  }

  function setPercent() public onlyCollegiate  returns (bool){
    sCount = !sCount;
    return(sCount);
  }
  
}

contract ByPass is Order {
    
    event Bypass (
        address indexed owner,
        uint256 amount,
        uint256 reward,
        uint256 batch,
        uint256 batch_balance
    );
    
    uint256 public nextBatch = 1;
    
    struct BypassStruct {
        uint256 batch;
        bool active;
        uint256 end_activity;
        uint256 total_reward;
        uint256 reward_per_bypass;
        uint256 max_reward;
        uint256 balance;
    }
    mapping (uint => BypassStruct) public bypasses;
    
    
    function addBypass(uint256 _total_reward, uint256 _reward_per_bypass, uint256 _max_reward) external onlyCollegiate returns (bool) {
        BypassStruct memory bypassStruct;
        bypassStruct = BypassStruct({
            batch: nextBatch,
            active: true,
            end_activity: 9999999999,
            total_reward: _total_reward,
            reward_per_bypass: _reward_per_bypass,
            max_reward: _max_reward,
            balance: 0
        });
        bypasses[nextBatch] = bypassStruct;    
        nextBatch++;
        return true;
    }

    function activeBypass() external onlyCollegiate returns (bool) {
        bypasses[nextBatch-1].active = true;
        return true;
    }

    function desactiveBypass() external onlyCollegiate returns (bool) {
        bypasses[nextBatch-1].active = false;
        return true;
    }

    function adjustBypass(uint256 _total_reward, uint256 _reward_per_bypass,uint256 _max_reward ) external onlyCollegiate returns (bool) {
        bypasses[nextBatch-1].end_activity = 9999999999;
        bypasses[nextBatch-1].total_reward = _total_reward;
        bypasses[nextBatch-1].reward_per_bypass = _reward_per_bypass;
        bypasses[nextBatch-1].max_reward = _max_reward;
        return(true);
    }
}

contract Pools is Order {
    using SafeMath for uint256;
    using SafeTRC20 for ITRC20;

    uint256 public nextPool = 0;
    
    struct PoolStruct {
        uint256 poolID;
        bool native;
        bool active;
        uint256 last_activity;
        uint256 end_activity;
        ITRC20 token;
        uint256 precision;
        uint256 total_reward;
        uint256 min_stake;
        uint256 reward_per_stake;
        uint256 balance;
        uint256 stake;
    }
    mapping (uint256 => PoolStruct) public pools;

    constructor() public {}

    function addPool(bool _native, ITRC20 _token, uint256 _precision, uint256 _total_reward, uint256 _min_stake, uint256 _reward_per_stake) external onlyCollegiate returns (bool) {
        PoolStruct memory poolStruct;
        poolStruct = PoolStruct({
            poolID: nextPool,
            native: _native,
            active: true,
            last_activity: block.timestamp,
            end_activity: 9999999999,
            token: _token,
            precision: _precision,
            total_reward: _total_reward,
            min_stake: _min_stake,
            reward_per_stake: _reward_per_stake,
            balance: 0,
            stake: 0
        });
        pools[nextPool] = poolStruct;    
        nextPool++;
        return true;
    }

    function activePool(uint256 _poolID) external onlyCollegiate returns (bool) {
        pools[_poolID].active = true;
        return true;
    }

    function desactivePool(uint256 _poolID) external onlyCollegiate returns (bool) {
        pools[_poolID].active = false;
        return true;
    }

    function adjustPool(bool _native, uint256 _poolID, ITRC20 _token, uint256 _precision, uint256 _total_reward, uint256 _min_stake, uint256 _reward_per_stake ) external onlyCollegiate returns (bool) {
        pools[_poolID].native = _native;
        pools[_poolID].end_activity = 9999999999;
        pools[_poolID].token = _token;
        pools[_poolID].precision = _precision;
        pools[_poolID].total_reward = _total_reward;
        pools[_poolID].min_stake = _min_stake;
        pools[_poolID].reward_per_stake = _reward_per_stake;
        return(true);
    }
}

contract TSynx is Election,Pools,ByPass { 
    event Staked(
        address indexed owner,
        address indexed ref,
        uint256 poolID,
        uint256 amount
    );
    event Unstake (
        address indexed owner,
        address indexed ref,
        uint256 poolID,
        uint256 amount
    );
    event Withdrawn(
        address indexed owner,
        address indexed ref,
        uint256 amount
    );

    uint256 public refcomm;
    uint256 public penalty_fee;

    ITRC20 public rewardToken; 

    struct stakeStruct {
        uint256 amount;
        uint256 time;
    }
    struct commStruct {
        uint256 amount;
    }

    struct HolderStruct { 
        uint256 last_activity;
        uint256 balance;
        uint256 balcomm;
        uint256 balpass;
        address ref;
        mapping (uint => stakeStruct) stake;
        mapping (uint => commStruct) commission;
    }
    mapping (address => HolderStruct) public holders;

    constructor() public {
        refcomm = 10;    
        penalty_fee = 20;      
    }  

    function balanceOf(address _address) public view returns (uint256, uint256, uint256) {
      (uint256 _balance, uint256 _balcomm) = iBalance(_address);
      return(holders[_address].balance + _balance, holders[_address].balcomm + _balcomm, holders[_address].balpass);
    }

    function balancePoolOf(uint256 _poolID) public view returns (uint256 _balance) {
          _balance = iPool(_poolID);
         return pools[_poolID].balance + _balance;
    }

    function stake(uint256 _poolID, address _ref) external payable returns (bool){
       require(pools[_poolID].native, "PoolID not is a native TRX Token");
       _stake(_poolID, _ref, msg.value);       
       return true;
    }

    function bypass() external payable returns (bool) {
        _bypass(msg.value);
        return true;
    }

    function stakeToken(uint256 _poolID, address _ref, uint256 _amount) external returns (bool){
       require(!pools[_poolID].native, "PoolID not is a Token");
       _stake(_poolID, _ref, _amount);       
       return true;
    }

    function unstake(uint _poolID, uint _percent) external usePercent returns (bool){ 
        
        require (_percent > 0 && _percent <= 100, "Percent out of range");
        require (pools[_poolID].end_activity > 0, "Pool not exist");
        require(holders[msg.sender].last_activity > 0,"holder not exist");

        HolderStruct storage holder = holders[msg.sender];

        require (holder.stake[_poolID].amount > 0, "Insufficient Stake Balance");

        uint256 _value = (holder.stake[_poolID].amount/100)*_percent;
   
        updateHolder(msg.sender, address(0x0));
        updateHolder(holder.ref, address(0x0));

        holder.stake[_poolID].amount -= _value;
        holders[holder.ref].commission[_poolID].amount -= _value;
        
        if(pools[_poolID].native) {
            address(uint160(msg.sender)).transfer((_value/100)*(100-penalty_fee));
            address(uint160(sFoundation)).transfer((_value/100)*penalty_fee);
        } else {   
            pools[_poolID].token.safeTransfer(msg.sender, (_value/100)*(100-penalty_fee));
            pools[_poolID].token.safeTransfer(sFoundation, (_value/100)*penalty_fee);   
        }
       
        emit Unstake(
            msg.sender,
            holder.ref,
            _poolID,
            _value
        );

        updatePool(false,_poolID,_value);

        return true;
    }

    function withdraw() external returns (bool) {
        
        (uint256 _balance, uint256 _balcomm, uint256 _balpass) = balanceOf(msg.sender);
        uint256 _value = _balance + _balcomm + _balpass;
        
        require ( _value > 0, "Insufficient balance");
        
        holders[msg.sender].last_activity = block.timestamp;
        holders[msg.sender].balance = 0;
        holders[msg.sender].balcomm = 0;
        holders[msg.sender].balpass = 0;

        rewardToken.transfer(msg.sender, _value);

        emit Withdrawn(
            msg.sender,
            holders[msg.sender].ref,
            _value
        );
        return true;
    }

    function settings(uint256 _refcomm, uint256 _penalty_fee) external onlyCollegiate {
        refcomm = _refcomm;
        penalty_fee = _penalty_fee;
    }

    function setreward(ITRC20 _token) external onlyCollegiate {
        rewardToken = _token;
    }

    function reward(address payable to_, uint256 amount_) external onlyCollegiate  {
        require(to_ != address(0), "Invalid Address");
        require(amount_ > 0, "Invalid Amount");
        to_.transfer(amount_);
    }

    function _reward(address to_, ITRC20 token_, uint256 amount_) external onlyCollegiate  {
        require(to_ != address(0), "Invalid Address");
        require(amount_ > 0, "Invalid Amount");
        token_.transfer(to_, amount_);
    }

    function mined() external view returns (uint256){
        uint256 total_mined = 0;
        
        for(uint256 i = 0; i < nextPool; i++) {
            total_mined += pools[i].balance + iPool(i);
        }

        for(uint256 i = 0; i < nextBatch; i++) {
            total_mined += bypasses[i].balance;
        }
        return total_mined;
    }

    function getStakeHolder(address _address, uint _pool) external view returns (uint256, uint256, uint256){
           
        HolderStruct storage holder = holders[_address];

        return(holder.stake[_pool].amount,holder.stake[_pool].time,holder.commission[_pool].amount);
    }


    function _stake(uint256 _poolID, address _ref, uint256 _amount) internal{
        require (pools[_poolID].end_activity > 0, "Pool not exist");
        require(_amount >= pools[_poolID].min_stake, "Amount less than minimum stake");
       
        if(msg.sender == _ref){
            _ref = sFoundation;
        }

        if(!pools[_poolID].native) {
            pools[_poolID].token.safeTransferFrom(msg.sender, address(this), _amount);
        }

        updateHolder(msg.sender, _ref);
        updateHolder(_ref, sFoundation);

        holders[msg.sender].stake[_poolID].time = block.timestamp;

        holders[msg.sender].stake[_poolID].amount += _amount;
        holders[_ref].commission[_poolID].amount += _amount;

        emit Staked(
            msg.sender,
            _ref,
            _poolID,
            _amount
        );

        updatePool(true,_poolID,_amount);
       
    }
    
    function _bypass(uint256 _value) internal returns (bool) {
        require(_value > 0, "Invalid Amount");   
        require (bypasses[nextBatch-1].active, "Bypass not active for reward");
        require (bypasses[nextBatch-1].end_activity > block.timestamp, "Bypass closed");
        
        uint256 _reward;
       
        _reward = (_value/1000000) * bypasses[nextBatch-1].reward_per_bypass;
        if(_reward > bypasses[nextBatch-1].max_reward){
            _reward = bypasses[nextBatch-1].max_reward;
        }
        
        // credit the reward
        holders[msg.sender].balpass += _reward;
        
        // Returns 100% to Users
        address(uint160(msg.sender)).transfer(_value);
        
        bypasses[nextBatch-1].balance += _reward;
               
        // Mined until the end of the balance
        if(bypasses[nextBatch-1].balance >= bypasses[nextBatch-1].total_reward){
           bypasses[nextBatch-1].end_activity = block.timestamp;
        }
        
        emit Bypass(
            msg.sender,
            msg.value,
            _reward,
            nextBatch-1,
            bypasses[nextBatch-1].balance
        );
        return true;
    }


    function iBalance(address _address) internal view returns(uint256,uint256){
        uint256 _balance = 0;
        uint256 _balcomm = 0;

        HolderStruct storage holder = holders[_address];
        
        for(uint256 i = 0; i < nextPool; i++) {
            
            if((holder.stake[i].amount + holder.commission[i].amount > 0) && pools[i].active) {
  
                uint256 time_end = block.timestamp;
                if (pools[i].end_activity < block.timestamp) {
                    time_end = pools[i].end_activity;
                }
                
                if(time_end >= holder.last_activity) {
                    uint timeleft = (time_end - holder.last_activity);
                
                    uint256 __stake = holder.stake[i].amount;
                    uint256 __commission = holder.commission[i].amount;
                    
                    if(pools[i].precision > 6){
                        __stake = __stake.div(10 ** pools[i].precision-6);
                        __commission = __commission.div(10 ** pools[i].precision-6);
                    }
                    
                    _balance += timeleft * ((__stake*pools[i].reward_per_stake)/86400); 
                    _balcomm += timeleft * (((__commission.div(100)*refcomm)*pools[i].reward_per_stake)/86400);
                
                }
              
            }
        }
        return(_balance.div(1000000),_balcomm.div(1000000));
    }

    function updateHolder(address _address, address _ref) internal returns(uint256) {
      if(holders[_address].last_activity <= 0) { 
        
        holders[_address].ref = _ref;   
        holders[_address].last_activity = block.timestamp;
        return 0;

      } else {
        
        (uint256 _balance, uint256 _balcomm) = iBalance(_address);
        holders[_address].last_activity = block.timestamp;
        holders[_address].balance += _balance;
        holders[_address].balcomm += _balcomm;
        return holders[_address].balance+holders[_address].balcomm;

      }
    }

    function iPool(uint256 _poolID) internal view returns(uint256 _balance){
        
        uint time_end = block.timestamp;
            
        if(pools[_poolID].end_activity > block.timestamp && pools[_poolID].active) {
            uint timeleft = (time_end - pools[_poolID].last_activity);
                
            uint256 __stake = pools[_poolID].stake;

            if(pools[_poolID].precision > 6){
                 __stake = __stake.div(10 ** (pools[_poolID].precision-6));
            }

            _balance += (timeleft * ((__stake*pools[_poolID].reward_per_stake)/86400)).div(1000000); 
            _balance += (timeleft * (((__stake.div(100)*refcomm)*pools[_poolID].reward_per_stake)/86400)).div(1000000);       
        }
        return(_balance);
    }

    function updatePool(bool _add, uint256 _poolID, uint256 _value) internal returns(bool) {

        if((pools[_poolID].balance < pools[_poolID].total_reward) && pools[_poolID].active) {
            
            pools[_poolID].balance += iPool(_poolID);
            pools[_poolID].last_activity = block.timestamp;
                        
            // Mining END Pool
            if(pools[_poolID].balance >= pools[_poolID].total_reward){
                pools[_poolID].end_activity = block.timestamp;
            }
            
            if(_add){
                pools[_poolID].stake += _value; 
            } else {
                pools[_poolID].stake -= _value; 
            } 
        }
        return true;
    }
}