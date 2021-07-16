//SourceUnit: ANKDay4.sol

pragma solidity =0.5.4;

import "Pool.sol";

contract ANKPoolDay4 is Pool {
    constructor() public Pool(address(0x411FEA2987B8385E58E70191247B3D988931BD0982),  3125*10**14, true, 1599984000, 1e12, 9 seconds, 9600) {}
}


//SourceUnit: ITRC20.sol

pragma solidity =0.5.4;

interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


//SourceUnit: Pool.sol

pragma solidity =0.5.4;

import "SafeMath.sol";
import "ITRC20.sol";
import "owner.sol";

contract Pool is Ownable {
    using SafeMath for uint256;

    ITRC20 public lptokenContract;
    ITRC20 public liquorContract = ITRC20(0x41499E922079D0B4CC83F6E289C6C3812E210EE031); // TGgUHkmotBAmxH1CQezdWeVcpYVLJSHLuU

    uint256 private _totalSupply = 0;                               // current total supply
    mapping(address => uint256) private _balances;                  // user's balance
    mapping(address => uint256) public userDebt;                    // user's debt
    mapping(address => uint256) private paidReward;                 // user earned and harvested

    uint256 public startTime;
    uint256 public period;
    uint256 public totalPeriod;
    uint256 public decimals;
    uint256 public rewardPerPeriod;                                 // reward of some period
    uint256 public accRewardPerUnit;                                // acc reward
    uint256 public lastRewardPeriod;                                // last reward period
    bool public transferNoReturn;

    constructor(address contractAddr, uint256 _rewardPerPeriod, bool _transferNoReturn, uint256 _startTime, uint256 _decimals, uint256 _period, uint256 _totalPeriod) public {
        accRewardPerUnit = 0;
        lptokenContract = ITRC20(contractAddr);
        rewardPerPeriod = _rewardPerPeriod;
        transferNoReturn = _transferNoReturn;
        startTime = _startTime;
        decimals = _decimals;
        period = _period;
        totalPeriod = _totalPeriod;
    }

    function updateRewardPerPeriod(uint256 _rewardPerPeriod) external onlyOwner returns (bool) {
        rewardPerPeriod = _rewardPerPeriod;
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function paidRewardOf(address account) public view returns (uint256) {
        return paidReward[account];
    }

    function getUserEarned(address account) public view returns (uint256) {
        uint256 lastP = currentPeriod();
        if(balanceOf(account) == 0 || lastP == 0) {
            return 0;
        }
        uint256 periods = lastP - lastRewardPeriod;
        uint256 reward = periods.mul(rewardPerPeriod);
        uint256 perReward = accRewardPerUnit.add(reward.mul(decimals).div(_totalSupply));
        uint256 debt = userDebt[account];
        uint256 balance = balanceOf(account);
        return balance.mul(perReward).div(decimals).sub(debt);
    }

    function rewardOf(address account) public view returns (uint256) {
        return paidRewardOf(account).add(getUserEarned(account));
    }

    function stake(uint256 amount) public returns (bool) {
        address user = msg.sender;
        
        if (balanceOf(user) > 0) {
            harvest();   
        }

        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
        require(lptokenContract.transferFrom(user, address(this), amount), "stake failed");

        return updateUserDebt();
    }

    function withdraw(uint256 amount) public returns (bool) {
        harvest();

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        if (transferNoReturn && lptokenContract.balanceOf(address(this)) >= amount) {
            lptokenContract.transfer(msg.sender, amount);
        } else {
            require(lptokenContract.transfer(msg.sender, amount), "withdraw failed");
        }

        return updateUserDebt();
    }

    function updateUserDebt() private returns (bool) {
        updatePool();
        userDebt[msg.sender] = balanceOf(msg.sender).mul(accRewardPerUnit).div(decimals);
        return true;
    }

    function harvest() public returns (bool) {
        updatePool();
        uint256 reward = getUserEarned(msg.sender);
        require(liquorContract.transfer(msg.sender, reward), "harvest failed");
        paidReward[msg.sender] = paidReward[msg.sender].add(reward);
        return updateUserDebt();
    }

    function exit() public returns (bool) {
        uint256 amount = balanceOf(msg.sender);
        withdraw(amount);
        return true;
    }

    function currentPeriod() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        }
        uint256 time = block.timestamp - startTime;
        uint256 mod = time % period;
        time = time - mod;
        uint256 _period = time / period;
        if (_period > totalPeriod) {
            _period = totalPeriod;
        }
        return _period;
    }

    function updatePool() private returns (bool) {
        if (_totalSupply == 0 || block.timestamp <= startTime) {
            return false;
        }
        uint256 lastP = currentPeriod();
        uint256 periods = lastP - lastRewardPeriod;
        uint256 reward = periods.mul(rewardPerPeriod);
        accRewardPerUnit = accRewardPerUnit.add(reward.mul(decimals).div(_totalSupply));
        lastRewardPeriod = lastP;
        return true;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity =0.5.4;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
 
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
 
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
 
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
 
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

//SourceUnit: context.sol

pragma solidity =0.5.4;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}


//SourceUnit: owner.sol

pragma solidity =0.5.4;

import "context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}