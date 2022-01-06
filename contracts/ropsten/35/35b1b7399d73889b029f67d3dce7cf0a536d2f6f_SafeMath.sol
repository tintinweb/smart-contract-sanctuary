/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

//Interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SafeMath
library SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

//Context Contract
contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    address zeroAddress = 0x0000000000000000000000000000000000000000;
}

//ERC20 Standard
contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    uint256 internal _totalSupply;
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function totalSupply() external override view returns (uint256) {
        return _totalSupply.safeSub(balances[zeroAddress]);
    }

    function balanceOf(address account) external override view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address recipient, uint amount) external override returns (bool success) {
        require(msg.sender != zeroAddress, "Burn Address Cannot Transfer");
        require(amount <= balances[msg.sender], "Insufficient Balance");
        balances[msg.sender] = balances[msg.sender].safeSub(amount);
        balances[recipient] = balances[recipient].safeAdd(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool success) {
        require (msg.sender != zeroAddress, "Burn Address Cannot Approve Others To Spend Tokens");
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 value) external override returns (bool succes) {
    require (sender != zeroAddress, "Cannot Transfer Coins From Burn Address");
    require(value <= balances[sender]);
    require(value <= allowed[sender][msg.sender]);

    balances[sender] = balances[sender].safeSub(value);
    balances[recipient] = balances[recipient].safeAdd(value);
    allowed[sender][msg.sender] = allowed[sender][msg.sender].safeSub(value);
    emit Transfer(sender, recipient, value);
    return true;
    }
}

//ERC20Detailed
contract ERC20Detailed is ERC20 {
    using SafeMath for uint;

    string internal constant _name = "PenguinCoin";
    string internal constant _symbol = "PENG";
    uint8 internal constant _decimals = 18;


    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }
}

//EtherTransactor
contract EtherTransactor {
    using SafeMath for uint;

    function sendByTransfer(address payable recipient) public payable {
        recipient.transfer(msg.value);
    }
}

//StakeableToken
contract StakeableToken is ERC20Detailed {
    using SafeMath for uint;

    event StakeBegan(address indexed staker, uint256 value, uint256 startDate, uint256 endDate);
    event StakeClaimed(address indexed staker, uint256 startValue, uint256 endValue, uint256 startDate, uint256 endDate);
    event StakeCanceled(address indexed staker, uint256 startValue, uint256 endValue, uint256 endValueAfterPenalty, uint256 startDate, uint256 endDate);
    struct stake {address _address; uint256 _value; uint256 _startDate; uint256 _endDate;}
    stake[] public stakes;

    function beginStake(uint256 amount, uint256 end) external returns (bool success) {
        require (amount <= balances[msg.sender], "Stake Is Higher Than Balance");
        require (end > block.timestamp, "The end date cannot be the current date or a past date.");
        uint256 time = block.timestamp;

        balances[msg.sender] = balances[msg.sender].safeSub(amount);
        _totalSupply = _totalSupply.safeSub(amount);

        stake memory currentStake;
        currentStake._address  = msg.sender;
        currentStake._value = amount;
        currentStake._startDate = time;
        currentStake._endDate = end;
        stakes.push(currentStake);

        emit Transfer(msg.sender, zeroAddress, amount);
        emit StakeBegan(msg.sender, amount, time, end);
        return true;
    }

    function claimStake(uint256 startDate, uint256 endDate) external returns (bool success) {
        require (endDate <= block.timestamp, "Stake has not ended yet. If you would like to cancel your stake, use the cancelStake function.");
        uint256 points = endDate.safeSub(startDate);
        uint256 maxStake = stakes.length;
        uint256 months = points.safeDiv(2592000);
        for (uint256 i = 0; i < maxStake; i++) {
            stake memory stakeToCheck = stakes[i];
            if (stakeToCheck._address == msg.sender) {
                if (stakeToCheck._startDate == startDate) {
                    if (stakeToCheck._endDate == endDate) {
                    uint256 interest = stakeToCheck._value.safeDiv(100).safeMul(months);
                    balances[msg.sender] = balances[msg.sender].safeAdd(stakeToCheck._value.safeAdd(interest));
                    _totalSupply = _totalSupply.safeAdd(stakeToCheck._value.safeAdd(interest));
                    stakes[i] = stakes[stakes.length - 1];
                    stakes.pop();
                    emit StakeClaimed(msg.sender, stakeToCheck._value, stakeToCheck._value.safeAdd(interest),
                        stakeToCheck._startDate, stakeToCheck._endDate);
                    emit Transfer(zeroAddress, msg.sender, stakeToCheck._value.safeAdd(interest));
                    return true;
                    }
                }
            }
        }
        return false;
    }
    function cancelStake(uint256 startDate, uint256 endDate) external returns (bool success) {
        uint256 time = block.timestamp;
        uint256 maxStake = stakes.length;
        uint256 points = time.safeSub(startDate);
        uint256 months = points.safeDiv(2592000);
        for (uint256 i = 0; i < maxStake; i++) {
            stake memory stakeToCheck = stakes[i];
            if (stakeToCheck._address == msg.sender) {
                if (stakeToCheck._startDate == startDate) {
                    if (stakeToCheck._endDate == endDate) {
                    uint256 interest = stakeToCheck._value.safeDiv(100).safeMul(months);
                    balances[msg.sender] = balances[msg.sender].safeAdd(stakeToCheck._value.safeAdd(interest.safeDiv(2)));
                    _totalSupply = _totalSupply.safeAdd(stakeToCheck._value.safeAdd(interest.safeDiv(2)));
                    stakes[i] = stakes[stakes.length - 1];
                    stakes.pop();
                    emit StakeCanceled(msg.sender, stakeToCheck._value, stakeToCheck._value.safeAdd(interest), 
                    stakeToCheck._value.safeAdd(interest.safeDiv(2)), stakeToCheck._startDate, stakeToCheck._endDate);
                    emit Transfer(zeroAddress, msg.sender, stakeToCheck._value.safeAdd(interest.safeDiv(2)));
                    return true;
                    }
                }
            }
        }
        return false;
    }

    function viewNumberOfStakes() external view returns (uint256) {
        return stakes.length;
    }
}

//Token
contract Token is ERC20Detailed, EtherTransactor, StakeableToken {
    using SafeMath for uint;

    address payable public governance;
    uint256 EtherTOCoinRatio = 100000;
    uint256 public toBeMinted = 10000000000000000000000000000000000;

    constructor() {
       governance = payable(msg.sender);
    }

    function getCoin() external payable returns (bool success) {
        require (toBeMinted >= msg.value.safeMul(EtherTOCoinRatio), "Not Enough Coin Left");
        sendByTransfer(governance);
        balances[msg.sender] = balances[msg.sender].safeAdd(msg.value.safeMul(EtherTOCoinRatio));
        toBeMinted = toBeMinted.safeSub(msg.value.safeMul(EtherTOCoinRatio));
        _totalSupply = _totalSupply.safeAdd(msg.value.safeMul(EtherTOCoinRatio));
        emit Transfer(zeroAddress, msg.sender, msg.value.safeMul(EtherTOCoinRatio));
        return true;
    }
}