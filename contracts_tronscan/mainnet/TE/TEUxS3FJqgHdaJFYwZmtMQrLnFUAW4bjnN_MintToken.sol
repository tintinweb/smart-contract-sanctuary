//SourceUnit: ITRC20.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10 <0.9.0;

/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
}

//SourceUnit: MintToken.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10 <0.9.0;

import "./StakeBase.sol";

contract MintToken is StakeBase {

    uint256 private _cap;
    
    constructor () public  {
        _cap = 1500000000 * 10**18;
        _mint(msg.sender, 450000000 * 10**18);
    }

    function name() public pure returns (string memory) {
        return "Mint Token";
    }

    function symbol() public pure returns (string memory) {
        return "MINT";
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool) {
        _burnFrom(from, value);
        return true;
    }

    function info() public view 
    returns (address, uint256, uint256, uint256, uint256) {
        return accountInfo(msg.sender);
    }

    function stakeInfo(uint256 idx) public view 
    returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return accountStakeInfo(msg.sender, idx);
    }

    function stakeCount() public view returns (uint256) {
        return accountStakeCount(msg.sender);
    }
    
    function withdrawCommissions() internal returns (uint256) {
        return withdrawAccountCommissions(msg.sender);
    }

    function withdrawStakeProfit(uint256 idx) internal returns (uint256) {
        return withdrawAccountStakeProfit(msg.sender, idx);
    }

    function withdrawStakeCapital(uint256 idx) public returns (uint256) {
        return withdrawAccountStakeCapital(msg.sender, idx);
    }

}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


//SourceUnit: StakeBase.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10 <0.9.0;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./TRC20.sol";

contract StakeBase is TRC20 {

    using SafeMath for uint256;

    struct AccountInfo {
        address referrer;
        uint256 stakeCount;
        uint256 stakeValue;
        uint256 stakeTotal;
        uint256 commissions;
    }

    struct StakeInfo {
        uint256 capital;
        uint256 balance;
        uint256 createdAt;
        uint256 lastTakenProfitAt;
        uint256 lastTakenCapitalAt;
    }

    uint256 constant SUN = 10**6;
    uint256 constant WEI = 10**18;

    uint256 private _startTime;
    uint256 private _usdPrice;

    uint256 private _totalProfit = 0; // total withdrew profit
    uint256 private _unstakeCapital = 0; // 10% of each un-stake

    address payable private _owner;
    address[] private _masterNodes; // stake >= 20k
    mapping (address => AccountInfo) private _accounts;
    mapping (address => mapping (uint256 => StakeInfo)) private _stakes;

    event NewStake(address indexed account, uint256 index, uint256 amount);
    event UnStake(address indexed account, uint256 index);
    event StakeProfit(address indexed account, uint256 index, uint256 amount);
    event AccountCommissions(address indexed account, uint256 amount);
    event RewardMasterNodes(uint256 amount);
    event PriceChange(string symbol, uint256 price);
    event OwnerChange(address indexed oldOwner, address indexed newOwner);

    constructor () public  {
        _owner = msg.sender;
        _startTime = block.timestamp;
        _usdPrice = SUN / 100; // 0.01 * 10^6 = 10000
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Sender is not owner");
        _;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function usdPrice() public view returns (uint256) {
        return _usdPrice;
    }

    function accountInfo(address account) public view 
    returns (address, uint256, uint256, uint256, uint256) {
        return (
            _accounts[account].referrer,
            _accounts[account].stakeCount,
            _accounts[account].stakeValue,
            _accounts[account].stakeTotal,
            _accounts[account].commissions
        );
    }

    function accountStakeInfo(address account, uint256 idx) public view 
    returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            _stakes[account][idx].capital,
            _stakes[account][idx].balance,
            _stakes[account][idx].createdAt,
            _profit(account, idx, block.timestamp), // available profit
            _stakes[account][idx].lastTakenProfitAt,
            _stakes[account][idx].lastTakenCapitalAt
        );
    }

    function accountStakeCount(address account) public view returns (uint256) {
        return _accounts[account].stakeCount;
    }

    function stakingStatistic() external view returns (uint256, uint256, uint256) {
        return (_masterNodes.length, _totalProfit, _unstakeCapital);
    }

    function changeOwner(address payable newOwner) external onlyOwner returns (bool) {
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnerChange(oldOwner, newOwner);

        return true;
    }

    function setUsdPrice(uint256 price) external onlyOwner returns (bool) {
        require(price >= SUN / 100, "USD price cannot less than 0.01 USD");
        
        _usdPrice = price;
        emit PriceChange("USD", price);

        return true;
    }

    /**
    * un-stake to withdraw capital before the end of stake
    * - 20% fee
    * - 80% can withdraw in next 10 months
    */
    function unstake(address account, uint256 idx) public returns (bool) {
        require(_stakes[account][idx].capital > 0, 'Stake does not exist');
    
        // can withdraw capital from this block time
        _stakes[account][idx].lastTakenCapitalAt = block.timestamp;

        // deduct capital to 20%
        uint256 amount = (_stakes[account][idx].capital * 20) / 100;
        _stakes[account][idx].capital -= amount; 
        _stakes[account][idx].balance -= amount;

        // burn 10% = amount / 2
        // keep 10% for master nodes
        _unstakeCapital += amount / 2;

        // emit Unstake event
        emit UnStake(account, idx);

        return true;
    }

    function stake(address account, uint256 amount, address referrer) public returns (bool) {
        require(balanceOf(msg.sender) >= amount, 'Token balance is not enough');
        require(amount >= 1000 * WEI, 'Minimum to stake is 1,000 Tokens');

        // transfer & lock tokens
        _transfer(msg.sender, address(this), amount);

        // stake
        _stake(account, amount, referrer);

        return true;
    }

    function withdrawAccountCommissions(address account) public returns (uint256) {
        require(_accounts[account].stakeCount > 0, 'Account does not exist');
        uint256 commissions = _accounts[account].commissions;
        require(commissions > 0, 'Account commissions is empty');

        _accounts[account].commissions = 0; // reset
        _mint(account, commissions);

        emit AccountCommissions(account, commissions);

        return commissions;
    }

    function withdrawAccountStakeProfit(address account, uint256 idx) public returns (uint256) {
        require(_accounts[account].stakeCount > 0, 'Account does not exist');
        
        uint256 time = block.timestamp;
        uint256 profit = _profit(account, idx, time);

        if (profit > 0) {
            _stakes[account][idx].lastTakenProfitAt = time;
            _totalProfit += profit;

            // Affiliate commissions
            _proCommissions(account, profit);
            _mint(account, profit);

            emit StakeProfit(account, idx, profit);
        }

        return profit;
    }

    function withdrawAccountStakeCapital(address account, uint256 idx) public returns (uint256) {
        require(_stakes[account][idx].balance > 0, 'Stake does not exist or empty');

        uint256 time = block.timestamp;
        uint256 amount = _capital(account, idx, time);

        if (amount > 0) {
            _stakes[account][idx].balance -= amount;
            _stakes[account][idx].lastTakenCapitalAt = time;
            _transfer(address(this), account, amount);
        }

        return amount;
    }

    /**
    * Reward master nodes
    * 2% of profit divide to commissions of all master nodes
    */
    function mintingRewardMasterNodes() public returns (uint256, uint256) {
        require(_totalProfit >= 1000 * WEI, 'Total profit does not match minimum expectation as 1,000 Tokens');

        // 2% - divide to all master nodes
        uint256 count = _masterNodes.length;
        uint256 amount = (_totalProfit * 2) / 100 / count;

        for (uint8 i = 0; i < count; i++) {
            _accounts[_masterNodes[i]].commissions += amount;
        }

        emit RewardMasterNodes(amount);

        // reset profit
        _totalProfit = 0;

        return (count, amount);
    }

    /**
    * Reward master nodes
    * 2% of profit divide to commissions of all master nodes
    */
    function unstakeRewardMasterNodes() public returns (uint256) {
        require(_unstakeCapital >= 1000 * WEI, 'Total profit does not match minimum expectation as 1,000 Tokens');

        // divide to all master nodes
        uint256 count = _masterNodes.length;
        uint256 amount = _unstakeCapital / count;

        for (uint256 i = 0; i < count; i++) {
            _accounts[_masterNodes[i]].commissions += amount;
        }

        emit RewardMasterNodes(amount);

        // reset unstake capital
        _unstakeCapital = 0;

        return amount;
    }

    /**
    * Save stake & account info
    */
    function _stake(address account, uint256 amount, address referrer) internal {
        require(amount > 0, 'Amount is Zero');
        require(referrer == _owner || _accounts[referrer].stakeCount > 0, 'Referrer does not have any stake yet!');

        bool isMasterNode = false;        
        uint256 idx = _accounts[account].stakeCount;
        uint256 value = (amount * _usdPrice) / WEI;

        // save account info
        if (_accounts[account].stakeCount > 0) {
            if (_accounts[account].stakeValue >= 20000 * SUN) {
                isMasterNode = true;
            }
        } else {
            _accounts[account].referrer = referrer;
        }

        _accounts[account].stakeCount += 1;
        _accounts[account].stakeTotal += amount;
        _accounts[account].stakeValue += value;

        // add account to master nodes if qualify
        if (!isMasterNode && _accounts[account].stakeValue >= 20000 * SUN) {
            _masterNodes.push(account);
        }

        // create new stake
        _stakes[account][idx].capital = amount;
        _stakes[account][idx].balance = amount;
        _stakes[account][idx].createdAt = block.timestamp;
        _stakes[account][idx].lastTakenProfitAt = block.timestamp;
        _stakes[account][idx].lastTakenCapitalAt = block.timestamp + 31104000; // 12 months later

        // Affiliate commissions
        _affCommissions(account, amount);

        emit NewStake(account, idx, amount);
    }

    /**
    * Calculate suitable withdraw amount
    * 10% / 30 days (~ month) = 38580246914 / second * 10^18
    */
    function _capital(address account, uint256 idx, uint256 time) internal view returns (uint256) {
        StakeInfo memory info = _stakes[account][idx];

        if (time < info.lastTakenCapitalAt) {
            return 0;
        }

        uint256 duration = time - info.lastTakenCapitalAt;
        uint256 amount = (info.capital * duration * 38580246914) / WEI;

        if (amount > info.balance) {
            amount = info.balance;
        }

        return amount;
    }

    /**
    * Calculate suitable withdraw profit
    * 8% (240 days)
    * 6% (180 days)
    * 4% later
    */
    function _profit(address account, uint256 idx, uint256 time) internal view returns (uint256) {
        StakeInfo memory info = _stakes[account][idx];

        if (time <= info.lastTakenProfitAt) {
            return 0;
        }

        uint256 profit = 0;

        // rating per second
        uint256[3] memory r = [uint256(30864197531), uint256(23148148148), uint256(15432098765)];
        uint256[3] memory d = [uint256(0), uint256(0), uint256(0)];
        uint256 p1 = 20736000; // 240 days in seconds
        uint256 p2 = 15552000; // 180 days in seconds
        uint256 e1 = _startTime + p1;
        uint256 e2 = _startTime + p1 + p2;

        if (info.lastTakenProfitAt > e2) {
            // 4
            d[2] = time - info.lastTakenProfitAt;
        } else if (info.lastTakenProfitAt > e1) {
            // 6
            if (time > e2) {
                d[2] = time - e2;
                d[1] = e2 - info.lastTakenProfitAt;
            } else {
                d[1] = time - info.lastTakenProfitAt;
            }
        } else {
            // 8
            if (time > e2) {
                d[2] = time - e2;
                d[1] = p2;
                d[0] = e1 - info.lastTakenProfitAt;
            } else if (time > e1) {
                d[1] = time - e1;
                d[0] = e1 - info.lastTakenProfitAt;
            } else {
                d[0] = time - info.lastTakenProfitAt;
            }
        }

        // calculate profit
        for (uint i = 0; i < 3; i++) {
            if (d[i] > 0) {
                // amount * rating * duration
                profit += (info.balance * r[i] * d[i]) / WEI;
            }
        }

        return profit;
    }

    /**
    * Affiliate Commissions
    * F1 5%, F2 3%, F3 2%
    */
    function _affCommissions(address account, uint256 amount) internal {
        uint8[3] memory r = [uint8(5), uint8(3), uint8(2)];
        
        uint8 l = 0;
        
        while (l < 3) {
            uint256 commissions = (amount * r[l]) / 100;
            account = _accounts[account].referrer;
            if (_accounts[account].stakeCount > 0) {
                _accounts[account].commissions += commissions;
            } else {
                break;
            }
            l += 1;
        }
    }

    /**
    * condition staking >= 500$
    * comm levels = F1 stake >= 500$.
    * F1 10%, F2 8%, F3 6%, F4 4%, F5 2%, F6/7/8 1%
    */
    function _proCommissions(address account, uint256 amount) internal {
        uint8[8] memory r = [uint8(10), uint8(8), uint8(6), uint8(4), uint8(2), uint8(1), uint8(1), uint8(1)];
        
        uint8 l = 0;

        while (l < 8) {
            uint256 commissions = (amount * r[l]) / 100;
            account = _accounts[account].referrer;
            if (_accounts[account].stakeCount > 0) {
                if (_accounts[account].stakeValue >= 500 * SUN) {
                    _accounts[account].commissions += commissions;
                }
            } else {
                break;
            }
            l += 1;
        }
    }
}


//SourceUnit: TRC20.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10 <0.9.0;

import "./ITRC20.sol";
import "./SafeMath.sol";

/**
 * @title Standard TRC20 token (compatible with ERC20 token)
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TRC20 is ITRC20 {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;


    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
    
}