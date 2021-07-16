//SourceUnit: otis.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

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


/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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


/**
 * @title Standard TRC20 token (compatible with ERC20 token)
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
     * @param account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
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
     * @dev Internal function that burns an amount of the token of a given
     * account.
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


/**
 * @title StakeMinter
 * @dev TRC20 can be minted via stake
 */
contract StakeMinter is TRC20 {

    using SafeMath for uint256;

    struct StakeInfo {
        uint256 amount;
        uint256 createdAt;
        uint256 lastWithdrewAt;
    }

    mapping (address => mapping (uint256 => StakeInfo)) private _accountStakes;
    mapping (address => uint256) private _accountStakeCounts;

    uint256 private _cap;
    uint256 private _totalStakedAmount;
    uint256 private _maxStakableAmount;

    event NewStake(address indexed account, uint256 amount);
    // event StakeProfit(address indexed account, uint256 value);

    constructor (uint256 cap, uint256 maxStakableAmount) public  {
        _cap = cap;
        _totalStakedAmount = 0;
        _maxStakableAmount = maxStakableAmount;
    }

    /**
     * @return the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @return max stakable amount
     */
    function maxStakableAmount() public view returns (uint256) {
        return _maxStakableAmount;
    }

    /**
     * @return total staked amount
     */
    function totalStakedAmount() public view returns (uint256) {
        return _totalStakedAmount;
    }

    /**
     * @dev Get total number of stakes of an account
     * @param account account address
     * @return stake count
     */
     function getAccountStakeCount(address account) public view returns (uint256) {
        return _accountStakeCounts[account];
    }

    /**
     * @dev Get total number of stakes
     * @return stake count
     */
    function getStakeCount() public view returns (uint256) {
        return _accountStakeCounts[msg.sender];
    }

    /**
     * @dev Get a stake info of an account at current time
     * @param account account address to get the info
     * @param index stake index
     * @return (stake amount, created at, last withrew at, available profit)
     */
    function getAccountStakeInfo(address account, uint256 index) public view returns (uint256, uint256, uint256, uint256) {
        StakeInfo memory info = _accountStakes[account][index];
        
        return (info.amount, info.createdAt, info.lastWithdrewAt, _calculateProfit(account, index, block.timestamp));
    }

    /**
     * @dev Get a stake info at current time
     * @param index stake index
     * @return (stake amount, created at, last withrew at, available profit)
     */
    function getStakeInfo(uint256 index) public view returns (uint256, uint256, uint256, uint256) {
        return getAccountStakeInfo(msg.sender, index);
    }
    
    /**
     * @dev Create a mintable stake for an account.
     * @param account stake beneficiary account
     * @param amount amount of tokens are staked
     */
    function stakeForAccount(address account, uint256 amount) public returns (uint256) {
        require(_totalStakedAmount.add(amount) <= _maxStakableAmount, "Stakable cap exceeded");
        require(balanceOf(msg.sender) >= amount, "Not enough token");
        require(amount >= 3000000000, "Min amount to stake 3'000 OTS");
        
        // increase staked amount
        _totalStakedAmount = _totalStakedAmount.add(amount);

        // create new stake
        uint256 index = _accountStakeCounts[account];

        _accountStakes[account][index].amount = amount;
        _accountStakes[account][index].createdAt = block.timestamp;
        _accountStakes[account][index].lastWithdrewAt = block.timestamp;

        _accountStakeCounts[account] = _accountStakeCounts[account] + 1;

        emit NewStake(account, amount);

        // burn tokens
        _burn(msg.sender, amount);

        return index;
    }

    /**
     * @dev Create a mintable stake.
     * @param amount amount of tokens are staked
     */
    function stake(uint256 amount) public returns (uint256) {
        return stakeForAccount(msg.sender, amount);
    }

    /**
    * @dev Withdraw profit from a stake of an account
    * @param account account address to withdraw profit
    * @param index account stake index
     */
    function withdrawAccountStakeProfit(address account, uint256 index) public returns (uint256) {
        uint256 profit = _calculateProfit(account, index, block.timestamp);
        require (profit > 0, "Stake has zero profit");
        require (totalSupply().add(profit) <= _cap, "Cap exceeded");

        _accountStakes[account][index].lastWithdrewAt = block.timestamp;
        _mint(account, profit);
        
        return profit;
    }

    /**
     * @dev Withdraw proft from a stake
     * @param index stake index
     */
    function withdrawStakeProfit(uint256 index) public returns (uint256) {
        return withdrawAccountStakeProfit(msg.sender, index);
    }

    /**
     * @dev Calculate available profit of an account's stake
     * @param account account address
     * @param index stake index
     * @param time target time
     * @return amount of profit
     */
    function _calculateProfit(address account, uint256 index, uint256 time) internal view returns (uint256) {
        StakeInfo memory info = _accountStakes[account][index];

        uint256 profit = 0;
        
        if (info.createdAt > 0 && time > info.lastWithdrewAt) {
            uint256 duration = _dayDuration(time, info.createdAt);
            uint256 delta1 = _dayDuration(info.lastWithdrewAt, info.createdAt);

            if (delta1 < 1095) {
                uint256 delta2 = _dayDuration(time, info.lastWithdrewAt);

                if (delta2.add(delta1) > 1095) {
                    delta2 = uint256(1095).sub(delta1);
                }

                uint256[3] memory r1 = [uint256(6575342), uint256(4931506), uint256(3287671)];
                uint256[3] memory r2 = [uint256(13150684), uint256(11506849), uint256(9863013)];
                uint256[3] memory d = [uint256(0), uint256(0), uint256(0)];

                if (duration <= 365) {
                    // 1 year
                    d[0] = delta2;
                } else if (duration <= 730) {
                    // 2 year
                    if (delta1 > 365) {
                        d[1] = delta2;
                    } else {
                        d[0] = uint256(365).sub(delta1);
                        d[1] = delta2.sub(d[0]);
                    }
                } else {
                    // 3 year
                    if (delta1 > 730) {
                        d[2] = delta2;
                    } else if (delta1 > 365) {
                        d[1] = uint256(730).sub(delta1);
                        d[2] = delta2.sub(d[1]);
                    } else {
                        d[0] = uint256(365).sub(delta1);
                        d[1] = uint256(365);
                        d[2] = (duration <= 1095) ? delta2.sub(d[1]).sub(d[0]) : uint256(365);
                    }
                }

                // calculate profit
                for (uint i = 0; i < 3; i++) {
                    uint256 p = info.amount >= 20000000000
                        ? d[i].mul(info.amount).mul(r2[i]).div(uint256(10000000000))
                        : d[i].mul(info.amount).mul(r1[i]).div(uint256(10000000000));

                    profit = profit.add(p);
                }
            }
        }

        return profit;
    }

    /**
     * @dev Calculate number of day between two timestamps
     * @return number of day
     */    
    function _dayDuration(uint256 time1, uint256 time2) internal pure returns (uint256) {
        return time1 > time2 ? time1.div(86400).sub(time2.div(86400)) : time2.div(86400).sub(time1.div(86400));
    }
}


/**
 * @title OtisToken
 */
contract OtisToken is StakeMinter {
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor () StakeMinter(2000000000000000, 200000000000000) public  {
        _name = "Otis Token";
        _symbol = "OTS";
        _decimals = 6;
        _mint(msg.sender, 300000000000000);
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}