//SourceUnit: defi.sol

/*
  OCTO DeFi
  Decentralized finance for TRON network

  www.octodefi.com
  support@octodefi.com

  OctoDefi (c) 2020, Tron Network 
*/

pragma solidity ^0.5.8;


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



contract SysGov is Context {
  address public sysGovernance;
  address public sysWallet;
  bool public sysVote;
  constructor() public {
    sysGovernance = _msgSender();
    sysWallet = address(0x0);
    sysVote = false;
  }

  modifier onlyGovernance() {
    require(_msgSender() == sysGovernance, "Only for Governance Maintenance");
    _;
  }

  function isGovernance() public view returns (bool) {
    return _msgSender() == sysGovernance;
  }

  function setGovernance(address _newGovernance) public onlyGovernance {
    sysGovernance = _newGovernance;
  }

  modifier onlyVote {
    require(!sysVote, "Only for Governance Maintenance");
    _;
  }
  function sVotet() public onlyGovernance {
    sysVote = true;
    //return true;
  }
  function sVotef() public onlyGovernance {
    sysVote = false;
    //return true;
  }




}

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

library SafeTRC20 {
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        if (address(token) == USDTAddr) {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
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

        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "(2)SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}

contract StakeCtrl is SysGov{
    using SafeMath for uint256;
    using SafeTRC20 for ITRC20;

    uint256 public level_current = 1;
    uint256 level_balance = 0;
    uint256 level_last_activity;
    uint256[3] level_stake = [0,0,0];
    uint256[3] level_commission = [0,0,0];

    uint256 minTRX = 50 trx;
    
    ITRC20 public octoAddr = ITRC20(0xb0f9bD8D54329556D1B640f339796edCf07685aA); 

    struct TokenStruct {
        ITRC20 tokenAddr;
        uint256 minOrder;
    }
    TokenStruct[] public tokens;

    struct LevelStruct {
        uint256 amount;
        uint256 start_time;
        uint256 end_time;
        uint256[3] pay_per_token;
        uint256 commission;
    }
    LevelStruct[] public levels;

    constructor() public {

        levels.push(LevelStruct({amount: 4000000 trx, start_time: now, end_time: 9999999999, pay_per_token: [uint256(25*10000),uint256(125*10000),uint256(10000)], commission: 20}));
        levels.push(LevelStruct({amount: 3000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*5000),uint256(125*5000),uint256(5000)], commission: 15}));
        levels.push(LevelStruct({amount: 3000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*4000),uint256(125*4000),uint256(4000)], commission: 15}));
        levels.push(LevelStruct({amount: 2000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*3000),uint256(125*3000),uint256(3000)], commission: 10}));
        levels.push(LevelStruct({amount: 2000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*2000),uint256(125*2000),uint256(2000)], commission: 10}));
        levels.push(LevelStruct({amount: 2000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*1500),uint256(125*1500),uint256(1500)], commission: 10}));
        levels.push(LevelStruct({amount: 1000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*1200),uint256(125*1200),uint256(1200)], commission: 5}));
        levels.push(LevelStruct({amount: 1000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*1000),uint256(125*1000),uint256(1000)], commission: 5}));
        levels.push(LevelStruct({amount: 1000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*950),uint256(125*950),uint256(950)], commission: 5}));
        levels.push(LevelStruct({amount: 1000000 trx, start_time: 9999999999, end_time: 9999999999, pay_per_token: [uint256(25*800),uint256(125*800),uint256(800)], commission: 5}));

        // USDT Token - p_token0
        tokens.push(TokenStruct({tokenAddr: ITRC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C), minOrder: 2*10**6}));

        // SUN Token - p_token1
        tokens.push(TokenStruct({tokenAddr: ITRC20(0x6b5151320359Ec18b08607c70a3b7439Af626aa3), minOrder:10*10**18}));
                                                                  
    }

    function getMin() external view returns(uint256,uint256,uint256) {
        return (minTRX,tokens[0].minOrder,tokens[1].minOrder);
    }

    function sM(uint256 _minTRX,uint256 _minToken0,uint256 _minToken1) external  onlyGovernance returns (bool) {
        minTRX = _minTRX;
        tokens[0].minOrder = _minToken0;
        tokens[1].minOrder = _minToken1;
        return true;
    }

    function sT(uint256 _tokenId, ITRC20 _token) external onlyGovernance returns (bool) {
        require(_tokenId == 0 || _tokenId == 1,"Token ID not found!");
        tokens[_tokenId].tokenAddr = _token;
        return true;
    }

    function sL(uint256 l, uint256 a, uint256 start_time, uint256 end_time, uint256 p0, uint256 p1, uint256 p2, uint256 c) external onlyGovernance returns (bool) {
        if(a > 0) {
            levels[l].amount = a;
        }
        if(start_time > 0) {
            levels[l].start_time = start_time;
        }
        if(end_time > 0) {
            levels[l].end_time = end_time;
        }
        levels[l].pay_per_token[0] = p0;
        levels[l].pay_per_token[1] = p1;
        levels[l].pay_per_token[2] = p2;
        levels[l].commission = c;
    }
}

contract OCTODeFi is StakeCtrl {
    event Staked(
        address indexed owner,
        address indexed ref,
        uint256 level,
        uint256 tokenID,
        uint256 value,
        uint256 balance
    );
    event Unstake (
        address indexed owner,
        address indexed ref,
        uint256 level,
        uint256 tokenID,
        uint256 value,
        uint256 balance  
    );
    event Withdrawn(
        address indexed owner,
        uint256 level,
        uint256 value
    );
    event WithdrawnComm(
        address indexed owner,
        uint256 level,
        uint256 value
    );
    
    uint256 public nextID = 1;

    struct HolderStruct { 
        uint id;
        uint256 last_activity;
        uint256 balance;
        uint256 balcomm;
        uint256[3] stake;
        address ref;
        uint256[3] commission;
    }
    mapping (address => HolderStruct) public holders;
    mapping (uint => address) public holdersList;

    constructor() public {}

    /*
    * Stake TRX for get OCTO
    *
    */
    function stake(address _ref) public payable returns (bool){

        require(msg.value >= minTRX, "Amount less than Min order");

        bool _paycomm = false;
        
        if(holders[msg.sender].id <= 0) {    // First deposit of an address
            _newHolder(msg.sender,_ref);
        } else {
            aBalance(msg.sender);
        }
        
        holders[msg.sender].stake[2] += msg.value;
        
        emit Staked(
            msg.sender,
            _ref,
            level_current,
            2,
            msg.value,
            holders[msg.sender].stake[2]
        );

        // Commission
        if(holders[msg.sender].ref != msg.sender){
          if(holders[_ref].id <= 0){
            _newHolder(_ref,_ref);
          } else {
             aBalance(_ref); 
          }
          holders[holders[msg.sender].ref].commission[2] += msg.value; 
             _paycomm = true;
        } 

        // Update level
        level_update(true,2,msg.value,_paycomm);
        return true;
    }

   /*
    * Stake Token USDT or SUN for get OCTO
    *
    */
    function stakeToken(uint256 tokenId, uint256 _value, address _ref) external returns (bool){

        require(tokenId ==0 || tokenId ==1,"Token ID not found!");
        require(_value >= tokens[tokenId].minOrder, "Amount less than Min order");

        tokens[tokenId].tokenAddr.safeTransferFrom(msg.sender, address(this), _value);


        bool _paycomm = false;
        
        if(holders[msg.sender].id <= 0) {    // First deposit of an address
            _newHolder(msg.sender,_ref);
        } else {
            aBalance(msg.sender);
        }
        
        holders[msg.sender].stake[tokenId] += _value;
        
        emit Staked(
            msg.sender,
            _ref,
            level_current,
            tokenId,
            _value,
            holders[msg.sender].stake[tokenId]
        );

        // Commission
        if(holders[msg.sender].ref != msg.sender){
          if(holders[_ref].id <= 0){
            _newHolder(_ref,_ref);
          } else {
             aBalance(_ref); 
          }
          holders[holders[msg.sender].ref].commission[tokenId] += _value; 
             _paycomm = true;
        } 
        // Update level
        level_update(true,tokenId,_value,_paycomm);
        return true;
    }
   
   /*
    * Unstake TRX and Token
    *
    */
    function unstake(uint _percent) external onlyVote returns (bool) {
        require (_percent > 0 && _percent <= 100, "Percent not correct");
        require(holders[msg.sender].id > 0,"User not exist");

        HolderStruct storage holder = holders[msg.sender];

        require (holder.stake[2] > 0, "Insufficient TRX Stake Balance");

        bool _paycomm = false;
        uint256 _value = (holder.stake[2]/100)*_percent;
               
        aBalance(msg.sender);
        aBalance(holder.ref);
        holder.stake[2] -= _value;
        if(holder.ref != msg.sender){
            holders[holder.ref].commission[2] -= _value; // Remove Commission too
            _paycomm = true;
        }

        address(uint160(msg.sender)).transfer(_value);
       
        emit Unstake(
            msg.sender,
            holder.ref,
            level_current,
            2,
            _value,
            holders[msg.sender].stake[2]
        );

        // Update level
        level_update(false,2,_value,_paycomm);

        return true;
    }

    function unstakeToken(uint _tokenId, uint _percent) external onlyVote returns (bool){
        require (_percent > 0 && _percent <= 100, "Percent not correct");
        require (_tokenId == 0 || _tokenId == 1, "Token not exist");
        require(holders[msg.sender].id > 0,"User not exist");

        HolderStruct storage holder = holders[msg.sender];

        require (holder.stake[_tokenId] > 0, "Insufficient Token Stake Balance");

        bool _paycomm = false;
        uint256 _value = (holder.stake[_tokenId]/100)*_percent;
              
        aBalance(msg.sender);
        aBalance(holder.ref);
        holder.stake[_tokenId] -= _value;
        if(holder.ref != msg.sender){
            holders[holder.ref].commission[_tokenId] -= _value;
            _paycomm = true;
        }

        tokens[_tokenId].tokenAddr.safeTransfer(msg.sender, _value);
       
        emit Unstake(
            msg.sender,
            holder.ref,
            level_current,
            _tokenId,
            _value,
            holders[msg.sender].stake[_tokenId]
        );

        // Update level
        level_update(false,_tokenId,_value,_paycomm);

        return true;
    }


    // Return Balance for reward + commision
    function balanceOf(address _address) public view returns (uint256) {
      (uint256 _balance, uint256 _balcomm) = vBalance(_address);
      return holders[_address].balance + _balance;
    }
    
    // Return Levels Balance
    function balanceOf() public view returns (uint256){
        return level_balance+vLevel();  
    }

    // Return Balance Commission
    function balcommOf(address _address) public view returns (uint256) {
      (uint256 _balance, uint256 _balcomm) = vBalance(_address);
      return holders[_address].balcomm + _balcomm;
    }

    // Get stake for address
    function getStake(address _address) external view returns(uint256,uint256,uint256){
        return(holders[_address].stake[0], holders[_address].stake[1], holders[_address].stake[2]);
    }

    // Get Commission for address
    function getCommission(address _address) external view returns(uint256,uint256,uint256){
        return(holders[_address].commission[0], holders[_address].commission[1], holders[_address].commission[2]);
    }

    // Level Status
    function getLevel() external view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
        return(level_current,level_balance,vLevel(),level_stake[0],level_stake[1],level_stake[2],level_commission[0],level_commission[1],level_commission[2],level_last_activity);
    }

    
    /**
    * @notice Withdraw
    * withdraw all OCTO's Token in balance (Balance + Commission)
    */
    function withdraw() external returns (bool) {
        uint256 _value = balanceOf(msg.sender) + balcommOf(msg.sender) ;
        
        require ( _value > 0, "Insufficient balance");
        
        aBalance(msg.sender);
        holders[msg.sender].balance = 0;
        holders[msg.sender].balcomm = 0;

        octoAddr.transfer(msg.sender, _value);

        emit Withdrawn(
            msg.sender,
            level_current,
            _value
        );

        return true;
    }

   /**
    * Reward
    */
    function reward(address payable to_, uint256 amount_) external onlyGovernance
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");
        to_.transfer(amount_);
    }
    function reward(address to_, ITRC20 token_, uint256 amount_) external onlyGovernance
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");
        token_.transfer(to_, amount_);
    }
   
   /**
    * @notice Balance Calc
    * @param _address Account to calculates
    */
    function vBalance(address _address) internal view returns(uint256,uint256){
        uint256 _balance = 0;
        uint256 _balcomm = 0;
        HolderStruct storage holder = holders[_address];
        
        for(uint i = 0; i < levels.length; i++) {
            
            if(levels[i].start_time > now) {
                 break; 
            }

            uint time_end = now;
            if (levels[i].end_time < now) {
                time_end = levels[i].end_time;
            }

            if(time_end >= holder.last_activity) {
                uint timem = (time_end - holder.last_activity);
                
                // Mining reward and commission per token
                // Reward per second
                for(uint m = 0; m < levels[i].pay_per_token.length; m++) {
                    
                    uint256 _stake_r = holder.stake[m];
                    uint256 _commission_r = holder.commission[m];
                    
                    if(m == 1){  // Adjust for SUN Token (18 dec - 6 dec (TRX,USDT and OCTO))
                        _stake_r = _stake_r.div(1000000000000);
                        _commission_r = _commission_r.div(1000000000000);
                    }

                    _balance += timem * ((_stake_r*levels[i].pay_per_token[m])/86400); 
                    _balcomm += timem * ((((_commission_r/100)*levels[i].commission)*levels[i].pay_per_token[m])/86400);
                }
            }
        }
        return(_balance.div(1000000), _balcomm.div(100000));
    }

   /**
    * @notice Calcule Geral reward
    */
    function vLevel() internal view returns(uint256){
        uint256 _balance = 0;
         
        for(uint i = 0; i < levels.length; i++) {
            
            if(levels[i].start_time > now) {
                 break; 
            }

            uint time_end = now;
            if (levels[i].end_time < now) {
                time_end = levels[i].end_time;
            }

            if(time_end >= level_last_activity) {
                uint timem = (time_end - level_last_activity);
                
                //Reward per Geral Stake Level
                for(uint m = 0; m < levels[i].pay_per_token.length; m++) {
                    uint256 _level_stake_r = level_stake[m];
                    uint256 _level_commission_r = level_commission[m];
                    
                    if(m == 1) {
                        _level_stake_r = _level_stake_r.div(1000000000000);
                        _level_commission_r = _level_commission_r.div(1000000000000);
                    }

                    _balance += timem * ((_level_stake_r*levels[i].pay_per_token[m])/86400); 
                    _balance += timem * ((((_level_commission_r/100)*levels[i].commission)*levels[i].pay_per_token[m])/86400);
                }
            }
        }
        return(_balance.div(1000000));
    }

   /**
    * @notice Create a new user with Balance 0
    * @param _address Tron address for Compound Interest
    * @param _ref Tron address for commission
    */
    function _newHolder(address _address, address _ref) internal {
        HolderStruct memory holderStruct;
        holderStruct = HolderStruct({
            id: nextID,
            last_activity: now,
            balance: 0,
            balcomm: 0,
            stake: [uint256(0),uint256(0),uint256(0)],
            ref: _ref,
            commission: [uint256(0),uint256(0),uint256(0)]
        });
        holders[_address] = holderStruct;    
        holdersList[nextID] = _address;
        nextID++;
    }

   /**
    * @notice Adjust balance in new operation on contract
    * @param _address Tron address for Compound Interest
    */
    function aBalance(address _address) internal returns(uint256) {
      (uint256 _balance, uint256 _balcomm) = vBalance(_address);
      holders[_address].last_activity = now;
      holders[_address].balance += _balance;
      holders[_address].balcomm += _balcomm;
      return holders[_address].balance+holders[_address].balcomm;
    }

    // Update current level status
    function level_update(bool _add, uint256 _tokenId, uint256 _value, bool _comm) internal returns(bool) {
        if (level_current == 11){
            return false;
        }
        level_balance += vLevel();
        level_last_activity = now;
        // Reward level end
        if(level_balance >= levels[level_current-1].amount){
            levels[level_current-1].end_time = now;
            level_balance -= levels[level_current-1].amount;
            level_current++;
            if(level_current <= 10){
                levels[level_current-1].start_time = now;
            }
        }
        if(_add){
            level_stake[_tokenId] += _value;
            if(_comm){
                level_commission[_tokenId] += _value;
            } 
        } else {
            level_stake[_tokenId] -= _value;
            if(_comm){
                level_commission[_tokenId] -= _value;
            }
        } 
        return true;
    }  
}