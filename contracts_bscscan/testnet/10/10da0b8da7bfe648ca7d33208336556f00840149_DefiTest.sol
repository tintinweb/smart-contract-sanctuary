/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

contract DefiTest {

    using SafeMath for uint256;

// Token details
    string public constant symbol = "DFT40";
    string public constant name = "DEFI40 TEST TOKEN";
    uint8 public constant decimals = 16;
    uint256 _totalSupply;
    address public owner;

//DEFI 
    address public admin;
    uint256 constant defaultYieldPerSecondPool1 = 158548959919; // 5% per Second * 10**18
    uint256 constant defaultYieldPerSecondPool2 = 158548959919; // 5% per Second * 10**18
    uint256 public constant maxTokenSupply = 10000000000 * 10 ** uint256(decimals);

    uint256 constant maxYield365 = 100000; // 10 x 10**4
    uint256 constant maxYield730 = 300000; // 30 x 10**4
    uint256 constant maxYield1095 = 600000; // 60 x 10**4


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowances;

    uint256 _totalYield;
    uint256 _soldToken;
    uint256 _reinvestTotal;
    uint256 _sendedYield;
    uint256 _burnedTotal;
    uint256 _totalStakedPool1;
    uint256 _totalStakedPool2;

    address[] public stakersPool1;
    address[] public stakersPool2;

    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public endTime;
    mapping(address => uint256) public stakingDuration; // in 365/730/1095 days
    mapping(address => uint256) public stakingPool; // 1 = 5% , 2 = 5%
    mapping(address => uint256) public manualYieldReceived; // in %
    mapping(address => uint256) public maxManualYield; // 10**4
    mapping(address => uint256) public yieldBalance;
    mapping(address => uint256) public yieldSettledTime;

    constructor() {
        owner = msg.sender;
        admin = msg.sender;
        _totalSupply = 1000000000 * 10 ** uint256(decimals);
        balances[owner] = _totalSupply;
        _totalStakedPool1 = 0;
        _totalStakedPool2 = 0;
        _totalYield = 0;
        _sendedYield = 0;
        _reinvestTotal = 0;
        _soldToken = 0;
        _burnedTotal = 0;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256 balance) {
        return balances[account];
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(msg.sender != address(0), "ERC20: Please use a valid FROM address");
        require(_to != address(0), "ERC20: Please use a valid TO address");
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(_from != address(0), "ERC20: Please use a valid FROM address");
        require(_to != address(0), "ERC20: Please use a valid TO address");
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
        require(_owner != address(0), "ERC20: Please use a valid OWNER address");
        require(_spender != address(0), "ERC20: Please use a valid SPENDER address");
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
        require(_to != address(0), "ERC20: Please use a valid TO address");
        if (maxTokenSupply > _totalSupply + _amount) {
            _totalSupply += _amount;
            balances[_to] = balances[_to].add(_amount);
            emit Transfer(address(0), _to, _amount);
            return true; 
        } else {
            return false;
        }
    }
    function burn(uint256 _amount) public {
        require(msg.sender == admin || msg.sender == owner,"This function can only be carried out by the administrator or owner.");
        require(_amount > 0, "You cannot burn zero tokens");
        require(balanceOf(msg.sender) >= _amount, "Your balance is too low");
        _totalSupply -= _amount;
        _burnedTotal += _amount;
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

// DEFI Start

    function burnedTotal() public view returns (uint256) {
        return _burnedTotal;
    }
    function soldToken() public view returns (uint256) {
        return _soldToken;
    }
    function sendedYield() public view returns (uint256) {
        return _sendedYield;
    }
    function reinvestTotal() public view returns (uint256) {
        return _reinvestTotal;
    }
    function totalYield() public view returns (uint256) {
        return _totalYield;
    }
    function totalStakedPool1() public view returns (uint256) {
        return _totalStakedPool1;
    }
    function totalStakedPool2() public view returns (uint256) {
        return _totalStakedPool2;
    }
    function getStakersCount(uint256 _pool) public view returns(uint256) {
        require(_pool == 1 || _pool == 2, "Only 1 or 2 is possible");
        if (_pool == 1) {
            return (stakersPool1.length);
        } else {
            return (stakersPool2.length);
        } 
    }
    function sellToken(address _user, uint256 _amount) public {
        require(msg.sender == admin || msg.sender == owner,
                "This function can only be carried out by the administrator or owner.");
        require(_amount > 0, "You cannot sell zero tokens");
        mint(_user, _amount);
        _soldToken += _amount;
    }
    function setAdmin(address _user) public {
        require(msg.sender == owner,"This function can only be carried out by the owner.");
        admin = _user;
    }
    function setStakingDuration(address _user, uint256 _stakingDuration) internal {
        stakingDuration[msg.sender] = _stakingDuration;
        if (_stakingDuration == 365) { maxManualYield[_user] = maxYield365; }
        if (_stakingDuration == 730) { maxManualYield[_user] = maxYield730; }
        if (_stakingDuration == 1095) { maxManualYield[_user] = maxYield1095; }
        startTime[_user] = block.timestamp;
        endTime[_user] = block.timestamp + _stakingDuration * 24 * 60 * 60;
        yieldSettledTime[_user] = block.timestamp;
    }
    function stakePool1(uint256 _amount, uint256 _stakingDuration) public {
        require(stakingBalance[msg.sender] == 0, "You are already staked! Take a new address!");
        require(_stakingDuration == 365 || _stakingDuration == 730 || _stakingDuration == 1095, 
                "Please submit the correct staking duration 365/730/1095 days");
        require(_amount > 0 && balanceOf(msg.sender) >= _amount, "You cannot stake zero tokens");
        setStakingDuration(msg.sender, _stakingDuration);
        stakersPool1.push(msg.sender);
        stakingPool[msg.sender] = 1;
        transfer(address(this), _amount);
        stakingBalance[msg.sender] = _amount;
        _totalStakedPool1 += _amount;
        emit Stake(msg.sender, _amount);
    }
    function stakePool2(uint256 _amount, uint256 _stakingDuration) public {
        require(stakingBalance[msg.sender] == 0, "You are already staked! Take a new address!");
        require(_stakingDuration == 365 || _stakingDuration == 730 || _stakingDuration == 1095, 
                "Please submit the correct staking duration 365/730/1115 days");
        require(_amount > 0 && balanceOf(msg.sender) >= _amount, "You cannot stake zero tokens");
        setStakingDuration(msg.sender, _stakingDuration);
        stakersPool2.push(msg.sender);
        stakingPool[msg.sender] = 2;
        transfer(address(this), _amount);
        stakingBalance[msg.sender] = _amount;
        _totalStakedPool2 += _amount;
        emit Stake(msg.sender, _amount);
    }
    function unstakeInternal(address _user) internal {
        settleYield();
        if (yieldBalance[_user] > 0) {
            withdrawYield(100, _user);
        }
        uint256 _amount = stakingBalance[_user];
        transfer(_user, _amount);
        if (stakingPool[_user] == 1) {
            _totalStakedPool1 -= _amount;
        } else {
            _totalStakedPool2 -= _amount;
        }
        stakingBalance[_user] = 0;
        manualYieldReceived[_user] = 0;
        maxManualYield[_user] = 0;
        emit Unstake(_user, _amount);
    }
    function unstake() public {
        require(stakingBalance[msg.sender] > 0, "Nothing to unstake");
        require(block.timestamp >= endTime[msg.sender], "Your funds are blocked");
        unstakeInternal(msg.sender);
    }
    function unstakeOf(address _user) public {
        require(msg.sender == admin || msg.sender == owner, "This function can only be carried out by the administrator or owner.");
        require(stakingBalance[_user] > 0, "Nothing to unstake");
        require(block.timestamp >= endTime[_user], "Your funds are blocked");
        unstakeInternal(_user);
    }
    function getCompletedDays(address _user) public view returns(uint256) {
        require(stakingBalance[_user] > 0, "No active staking!");
        uint256 completedDays = 0;
        if (block.timestamp > endTime[_user]) {
            completedDays = stakingDuration[_user];
        } else {
            completedDays = (block.timestamp - startTime[_user]) * 10**18 / 24 / 60 / 60 / 10**18;
        }
        return completedDays;
    }    
    function getOpenDays(address _user) public view returns(uint256) {
        require(stakingBalance[_user] > 0, "No active staking!");
        uint256 openDays = 0;
        if (block.timestamp >= endTime[_user]) {
            openDays = 0;
        } else {
            openDays = (endTime[_user] - block.timestamp) * 10**18 / 24 / 60 / 60 / 10**18;
        }
        return openDays + 1;
    }
    function extendDuration(uint256 _stakingDuration) public {
        require(_stakingDuration == 730 || _stakingDuration == 1095,
            "Please submit the correct staking duration 365/730/1095 days");
        require(_stakingDuration > stakingDuration[msg.sender], 
            "Please submit a higher duration than before!");
        stakingDuration[msg.sender] = _stakingDuration;
        endTime[msg.sender] = startTime[msg.sender] + _stakingDuration * 24 * 60 * 60;
        
    }
    function calculateYieldTime(address _user) public view returns(uint256) {
        require(stakingBalance[_user] > 0, "No active Contract");
        uint256 end = block.timestamp;
        uint256 totalTime = 0;
        require(yieldSettledTime[_user] < endTime[_user], "Contract is already fully settled");
        if (endTime[_user] > end) {
            totalTime  = end - yieldSettledTime[_user];
        } else {
            totalTime = endTime[_user] - yieldSettledTime[_user];
        }
        return totalTime;
    }
    function calculateYieldTotal(address _user) public view returns(uint256) {
        require(stakingBalance[_user] > 0, "No active Contract");
        uint256 time = calculateYieldTime(_user);
        uint256 rawYield = 0;
        if (stakingPool[_user] == 1) {
            rawYield = (defaultYieldPerSecondPool1 * stakingBalance[_user] * time / 100) / 10**18;
        } else {
            rawYield = (defaultYieldPerSecondPool2 * stakingBalance[_user] * time / 100) / 10**18;
        }
        return rawYield;
    } 
    function settleYield() public {
        require(stakingBalance[msg.sender] > 0, "No active staking!");
        uint256 openYield = calculateYieldTotal(msg.sender);
        require(openYield > 0,"Nothing to settle!");
        yieldBalance[msg.sender] += openYield;
        yieldSettledTime[msg.sender] = block.timestamp;
        _totalYield += openYield;
    }
    
    function reinvestYield(uint256 _percent) public {
        require(_percent >= 1 && _percent <= 100,"Please submit a percentage between 1 and 100!");
        settleYield();
        require(yieldBalance[msg.sender] > 0, "Nothing to reinvest");
        uint256 reinvestAmount = 0;
        if (_percent == 100) {
            reinvestAmount = yieldBalance[msg.sender];
        } else {
            reinvestAmount = yieldBalance[msg.sender] * _percent / 100;
        }
        if (mint(address(this), reinvestAmount) == true) {
            yieldBalance[msg.sender] -= reinvestAmount;
            stakingBalance[msg.sender] += reinvestAmount;
            _reinvestTotal += reinvestAmount;
            if (stakingPool[msg.sender] == 1) {
                _totalStakedPool1 += reinvestAmount;
            } else {
                _totalStakedPool2 += reinvestAmount;
            }
            emit ReinvestYield(msg.sender, reinvestAmount);
        }
    }
    function withdrawYield(uint256 _percent, address _to) public {
        require(_percent >= 1 && _percent <= 100,"Please submit a percentage between 1 and 100!");
        require(_to != address(0), "ERC20: Please use a valid TO address");
        settleYield();
        require(yieldBalance[msg.sender] > 0, "Nothing to withdraw");
        uint256 withdrawAmount = 0;
        if (_percent == 100) {
            withdrawAmount = yieldBalance[msg.sender];
        } else {
            withdrawAmount = yieldBalance[msg.sender] * _percent / 100;
        }

        if (mint(address(_to), withdrawAmount) == true) {
            yieldBalance[msg.sender] -= withdrawAmount;
            _sendedYield += withdrawAmount;
            emit YieldWithdraw(msg.sender, withdrawAmount);
        }
    } 
    function manualYieldPool1(uint256 _yield) public {               // *10**4 max 4 dezimals
        require(_yield > 0, "Please submit a correct value!");
        require(msg.sender == admin || msg.sender == owner,"This function can only be carried out by the administrator or owner.");
        
        uint256 manualYieldTotal = 0;
        uint256 userYield = 0;
        uint256 possibleUserYield = 0;

        for (uint256 i=0; i<stakersPool1.length; i++) {
            address recipient = stakersPool1[i];
            uint256 balance = stakingBalance[recipient];
            if (endTime[recipient] > block.timestamp) {
                if(balance > 0 && manualYieldReceived[recipient] < maxManualYield[recipient]) {
                    possibleUserYield = maxManualYield[recipient] - manualYieldReceived[recipient];
                    if (_yield > possibleUserYield) {
                        userYield = balance * possibleUserYield / 100 / 10**4;
                        manualYieldReceived[recipient] += possibleUserYield;
                    } else {
                        userYield = balance * _yield / 100 / 10**4;                    
                        manualYieldReceived[recipient] += _yield;
                    }
                    manualYieldTotal += userYield;
                    yieldBalance[recipient] += userYield;
                }
            } else {
                unstakeInternal(recipient);
            }
        } 
        _totalYield += manualYieldTotal;
    }
    function manualYieldPool2(uint256 _yield) public {               // *10**4 max 4 dezimals
        require(_yield > 0, "Please submit a correct value!");
        require(msg.sender == admin || msg.sender == owner,"This function can only be carried out by the administrator or owner.");
        
        uint256 manualYieldTotal = 0;
        uint256 userYield = 0;
        uint256 possibleUserYield = 0;

        for (uint256 i=0; i<stakersPool2.length; i++) {
            address recipient = stakersPool2[i];
            uint256 balance = stakingBalance[recipient];
            if (endTime[recipient] > block.timestamp) {
                if(balance > 0 && manualYieldReceived[recipient] < maxManualYield[recipient]) {
                    possibleUserYield = maxManualYield[recipient] - manualYieldReceived[recipient];
                   if (_yield > possibleUserYield) {
                        userYield = balance * possibleUserYield / 100 / 10**4;
                        manualYieldReceived[recipient] += possibleUserYield;
                    } else {
                        userYield = balance * _yield / 100 / 10**4;                    
                        manualYieldReceived[recipient] += _yield;
                    }
                    manualYieldTotal += userYield;
                    yieldBalance[recipient] += userYield;
                }
            } else {
                unstakeInternal(recipient);
            }
        } 
        _totalYield += manualYieldTotal;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    event Stake(address indexed _from, uint256 _amount);
    event Unstake(address indexed _to, uint256 _amount);
    event YieldWithdraw(address indexed _to, uint256 _amount);
    event ReinvestYield(address indexed _to, uint256 _amount);
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