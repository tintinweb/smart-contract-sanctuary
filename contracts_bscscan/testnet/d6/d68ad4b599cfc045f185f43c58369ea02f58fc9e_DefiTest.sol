/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// "SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.8.6;

contract DefiTest {

using SafeMath for uint256;

string public constant symbol = "DFT10";
string public constant name = "DEFI10 TEST TOKEN";
uint8 public constant decimals = 16;
uint256 _totalSupply;
address public owner;

//DefiTest public defiTest;
uint256 defaultYieldPerSecondPool1 = 158548959919; // 5% per Second * 10**18
uint256 defaultYieldPerSecondPool2 = 380517503806; // 12% per Second * 10**18
uint256 public constant maxTokenSupply = 10000000000 * 10 ** uint256(decimals);

uint32 maxYield365 = 100000; // 10 x 10**4
uint32 maxYield730 = 300000; // 30 x 10**4
uint32 maxYield1115 = 600000; // 60 x 10**4


mapping(address => uint256) balances;
mapping(address => mapping (address => uint256)) allowances;

uint256 _totalYield;
uint256 _soldToken;
uint256 _reinvestTotal;
uint256 _sendedYield;

address _admin;

address[] public stakers;

mapping(address => uint256) public stakingBalance;
mapping(address => bool) public isStaking;
mapping(address => uint256) public startTime;
mapping(address => uint16) public stakingDuration; // in 365/730/1115 days
mapping(address => uint8) public stakingPool; // 1 = 5% , 2 = 12%
mapping(address => uint32) public manualYieldReceived; // in %
mapping(address => uint32) public maxManualYield; // 10**4
mapping(address => uint256) public yieldBalance;
mapping(address => uint256) public yieldSettledTime;



constructor() {
    owner = msg.sender;
    _admin = msg.sender;
    _totalSupply = 1000000000 * 10 ** uint256(decimals);
    balances[owner] = _totalSupply;
    _totalYield = 0;
    _sendedYield = 0;
    _reinvestTotal = 0;
    _soldToken = 0;
    emit Transfer(address(0), owner, _totalSupply);
}
function totalSupply() public view returns (uint256) {
   return _totalSupply;
}
function balanceOf(address account) public view returns (uint256 balance) {
   return balances[account];
}
function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(msg.sender != address(0), "ERC20: approve from the zero address");
    require(_to != address(0), "ERC20: approve from the zero address");
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
}
function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_from != address(0), "ERC20: approve from the zero address");
    require(_to != address(0), "ERC20: approve from the zero address");
    require(balances[_from] >= _amount && allowances[_from][msg.sender] >= _amount);
    balances[_from] = balances[_from].sub(_amount);
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
}
function approve(address spender, uint256 _amount) public returns (bool) {
    _approve(msg.sender, spender, _amount);
    return true;
}
function _approve(address _owner, address _spender, uint256 _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");
    allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
    }
    
function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
   return allowances[_owner][_spender];
}

function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue));
    return true;
}
function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
}

function mint(address _to, uint256 _amount) internal returns (bool) {
    _totalSupply += _amount;
    emit Transfer(address(0), _to, _amount);
    return true;
}

function soldToken() public view returns (uint256) {
   return _soldToken;
}

function sendedYield() public view returns (uint256) {
   return _sendedYield;
}

function sellToken(address user, uint256 _amount) public {
    require(msg.sender == _admin || msg.sender == owner,"This function can only be carried out by the administrator or owner.");
    require(_amount > 0, "You cannot sell zero tokens");
    mint(user, _amount);
    _soldToken += _amount;
}

function setAdmin(address user) public {
    require(msg.sender == owner,"This function can only be carried out by the owner.");
    _admin = user;
}

    function stake(uint256 _amount, uint16 _stakingDuration, uint8 _stakingPool) public {
        require(isStaking[msg.sender] == false, "You are already staked! Take a new address!");
        require(_stakingPool == 1 || _stakingPool == 2,"Please submit 1 or 2 for the stakingPool");
        require(_stakingDuration == 365 || _stakingDuration == 730 || _stakingDuration == 1115,
            "Please submit the correct staking duration 365/730/1115 days");
        require(
            _amount > 0 &&
            balanceOf(msg.sender) >= _amount, 
            "You cannot stake zero tokens");
        stakingDuration[msg.sender] = _stakingDuration;
        if (_stakingDuration == 365) { maxManualYield[msg.sender] = maxYield365; }
        if (_stakingDuration == 730) { maxManualYield[msg.sender] = maxYield730; }
        if (_stakingDuration == 1115) { maxManualYield[msg.sender] = maxYield1115; }
        stakingPool[msg.sender] = _stakingPool;
        stakers.push(msg.sender);
        isStaking[msg.sender] = true;

        transfer(address(this), _amount);
        stakingBalance[msg.sender] += _amount;
        startTime[msg.sender] = block.timestamp;
        yieldSettledTime[msg.sender] = block.timestamp;
        emit Stake(msg.sender, _amount);
    }
 
    function unstake(uint256 _amount) public {
        require(
            isStaking[msg.sender] == true &&
            stakingBalance[msg.sender] >= _amount, 
            "Nothing to unstake"
        );
        require(
            getOpenDays(msg.sender) == 0,
            "Your funds are blocked"
        );
        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        yieldBalance[msg.sender] += yieldTransfer;
        yieldSettledTime[msg.sender] = block.timestamp;
        uint256 balTransfer = _amount;
        _amount = 0;
        stakingBalance[msg.sender] -= balTransfer;
        transfer(msg.sender, balTransfer);
        if(stakingBalance[msg.sender] == 0){
            isStaking[msg.sender] = false;
        }
        emit Unstake(msg.sender, balTransfer);
    }
    function getCompletedDays(address _user) public view returns(uint256) {
        uint256 durationSeconds = block.timestamp - yieldSettledTime[_user];
        uint256 durationDays = (durationSeconds * 10**18 / 60 / 60 / 24) / 10**18;
        return durationDays;
    }    
    function getOpenDays(address _user) public view returns(uint256) {
        uint256 completedDays = getCompletedDays(_user);
        uint256 duration = stakingDuration[_user];
        uint256 openDays = 0;
        if (duration > completedDays) {
            openDays = duration - completedDays;
        } else 
            openDays = 0;
        return openDays;
    }
    function extendDuration(uint16 _stakingDuration) public {
        require(_stakingDuration == 730 || _stakingDuration == 1115,
            "Please submit the correct staking duration 365/730/1115 days");
        require(_stakingDuration > stakingDuration[msg.sender], 
            "Please submit a higher duration than before!");
        stakingDuration[msg.sender] = _stakingDuration;
        
    }
    function calculateYieldTime(address user) public view returns(uint256) {
        uint256 end = block.timestamp;
        uint256 totalTime = end - yieldSettledTime[user];
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns(uint256) {
        uint256 time = calculateYieldTime(user);
        uint256 rawYield = 0;
        if (stakingPool[user] == 1) {
            rawYield = (defaultYieldPerSecondPool1 * stakingBalance[user] * time / 100) / 10**18;
        } else {
            rawYield = (defaultYieldPerSecondPool2 * stakingBalance[user] * time / 100) / 10**18;
        }
        return rawYield;
    } 
    
    function reinvestYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        require(
            toTransfer > 0 || yieldBalance[msg.sender] > 0,
            "Nothing to withdraw"
            );
            
        if (yieldBalance[msg.sender] != 0) {
            uint256 oldBalance = yieldBalance[msg.sender];
            yieldBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }
        yieldSettledTime[msg.sender] = block.timestamp;
        mint(address(this), toTransfer);
        _reinvestTotal += toTransfer;
        stakingBalance[msg.sender] += toTransfer;
        emit ReinvestYield(msg.sender, toTransfer);
    }
    function manualYieldTest(uint32 _yield) public view returns(uint256) {
        require(_yield > 0, "Please submit a correct value!");
        uint256 totalYield = 0;
        uint256 userYield = 0;
        uint32 possibleUserYield = 0;
        
        for (uint256 i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint256 balance = stakingBalance[recipient];
            
            if(balance >0 && manualYieldReceived[msg.sender] < maxManualYield[msg.sender]) {
                possibleUserYield = maxManualYield[msg.sender] - manualYieldReceived[msg.sender];
                if (_yield > possibleUserYield) {
                    userYield = balance * 10**18 / 100 * possibleUserYield / 10**18 / 10**4;
                    //manualYieldReceived[msg.sender] += possibleUserYield;
                } else {
                    userYield = balance * 10**18 / 100 * _yield / 10**18 / 10**4;                   
                    //manualYieldReceived[msg.sender] += _yield;
                }
                totalYield += userYield;
                //yieldBalance[msg.sender] += userYield;
            }
        }
        return totalYield;
    }
    function manualYield(uint32 _yield, uint8 _stakingPool) public {               // *10**4 max 4 dezimals
        require(_yield > 0, "Please submit a correct value!");
        require(msg.sender == owner,"This function can only be carried out by the owner.");
        
        uint256 totalYield = 0;
        uint256 userYield = 0;
        uint32 possibleUserYield = 0;
        
        for (uint256 i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint256 balance = stakingBalance[recipient];
            
            if(stakingPool[recipient] == _stakingPool && balance >0 && manualYieldReceived[recipient] < maxManualYield[recipient]) {
                possibleUserYield = maxManualYield[recipient] - manualYieldReceived[recipient];
                if (_yield > possibleUserYield) {
                    userYield = balance * 10**18 / 100 * possibleUserYield / 10**18 / 10**4;
                    manualYieldReceived[recipient] += possibleUserYield;
                } else {
                    userYield = balance * 10**18 / 100 * _yield / 10**18 / 10**4;                    
                    manualYieldReceived[recipient] += _yield;
                }
                totalYield += userYield;
                yieldBalance[recipient] += userYield;
            }
        }
 //       if (totalYield > 0) {
//            mint(address(this), totalYield);
  //          emit Transfer(address(0),address(this), totalYield);
  //          _paidYield += totalYield;
//        }
    }
    function withdrawYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        require(
            toTransfer > 0 || yieldBalance[msg.sender] > 0,
            "Nothing to withdraw"
            );
            
        if (yieldBalance[msg.sender] != 0) {
            uint256 oldBalance = yieldBalance[msg.sender];
            yieldBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }
        yieldSettledTime[msg.sender] = block.timestamp;
        mint(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
        _sendedYield += toTransfer;
    } 


event Transfer(address indexed _from, address indexed _to, uint _value);
event Approval(address indexed _owner, address indexed _spender, uint _value);

event Stake(address indexed from, uint256 amount);
event Unstake(address indexed from, uint256 amount);
event YieldWithdraw(address indexed to, uint256 amount);
event ReinvestYield(address indexed to, uint256 amount);
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
}