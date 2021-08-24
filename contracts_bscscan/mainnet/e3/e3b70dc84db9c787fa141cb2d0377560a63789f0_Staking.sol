/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

pragma solidity 0.6.7;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by to perform certain actions (e.g. participate in a
 * crowdsale).
 */
abstract contract WhitelistedRole is Ownable {
    using Roles for Roles.Role;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    Roles.Role internal _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Sender is not whitelisted");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addToWhitelist(address[] memory accounts) public virtual onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelisteds.add(accounts[i]);
            emit AddedToWhitelist(accounts[i]);
        }
    }

    function removeFromWhitelist(address[] memory accounts) public virtual onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelisteds.remove(accounts[i]);
            emit RemovedFromWhitelist(accounts[i]);
        }
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
 interface IERC20 {
     function transfer(address to, uint256 value) external returns (bool);
     function approve(address spender, uint256 value) external returns (bool);
     function transferFrom(address from, address to, uint256 value) external returns (bool);
     function totalSupply() external view returns (uint256);
     function balanceOf(address who) external view returns (uint256);
     function allowance(address owner, address spender) external view returns (uint256);
     event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed owner, address indexed spender, uint256 value);
 }

/**
 * @title Staking contract
 */
contract Staking is WhitelistedRole {
    using SafeMath for uint256;

    IERC20 public token;

    uint256 constant public ONE_HUNDRED = 10000;
    uint256 constant public ONE_DAY = 1 days;


    uint256 _stakesBalance;

    Parameters[] _stages;
    struct Parameters {
        uint256 minimum;
        uint256 medium;
        uint256 maximum;
        uint256 minPercent;
        uint256 medPercent;
        uint256 maxPercent;
        uint256 timestamp;
        uint256 interval;
    }

    uint256 public yearSettingsLimit;
    uint256 public feePercent;
    uint256 public feePeriod;

    mapping (address => User) _users;
    struct User {
        uint256 stake;
        uint256 stakeDate;
        uint256 checkpoint;
        uint256 lastStage;
        uint256 reserved;
        uint256 date;
        address pool;
    }

    event Staked(address indexed user, uint256 amount, address pool);
    event StakedWithdrawn(address sender, address indexed user, uint256 amount);
    event StakedReserved(address sender, address indexed user, uint256 amount);
    event StakeWithdrawn(address sender, address indexed user, uint256 amount, uint256 fee, uint256 remaining, address pool);
    event SetParameters(uint256 index, uint256 interval, uint256 minimum, uint256 medium, uint256 maximum, uint256 minPercent, uint256 medPercent, uint256 maxPercent);
    event SetUserPool(address indexed addr);
    event SetFeePercent(uint256 indexed percent);
    event SetFeePeriod(uint256 indexed period);
    event TotalStaking(address indexed sender, address indexed from, uint256 amount);
    event PoolFee(address indexed pool, address indexed user, uint256 amount);

    receive() external payable {
        if (msg.value > 0) {
            msg.sender.transfer(msg.value);
        }

        if (msg.data.length > 0) {
            if (_bytesToAddress(bytes(msg.data)) == msg.sender) {
                withdrawAll(msg.sender);
            }
        } else {
            withdrawStaked(msg.sender);
        }
    }

    fallback() external {}

    constructor(address CluiserLandTokenAddr15, uint256 newMinimum, uint256 newMedium, uint256 newMaximum, uint256 newMinPercent, uint256 newMedPercent, uint256 newMaxPercent, uint256 settingsLimit, uint256 newFeePercent, uint256 newFeePeriod) public Ownable(msg.sender) {
        require(CluiserLandTokenAddr15 != address(0));

        token = IERC20(CluiserLandTokenAddr15);
        setParameters(newMinimum, newMedium, newMaximum, newMinPercent, newMedPercent, newMaxPercent);
        yearSettingsLimit = settingsLimit;
        feePercent = newFeePercent;
        feePeriod = newFeePeriod;
    }

    function receiveApproval(address from, uint256 amount, address tokenAddr, bytes calldata extraData) external {
        require(tokenAddr == address(token));
        if (extraData.length > 0) {
            donate(from, amount);
        } else {
            invest(from, amount);
        }
    }

    function invest(address from, uint256 amount) public {
        User storage user = _users[from];

        require(msg.sender == address(token) || msg.sender == from, "You can send only your tokens");
        require(token.allowance(from, address(this)) >= amount, "Approve this token amount first");
        require(user.pool != address(0), "User pool is zero address");


        uint256 remaining = getTokenBalanceOf(address(this)).sub(_stakesBalance);
        if(!isWhitelisted(from)){

            address pool_addr = getUserPool(from);
            uint256 fee = amount.mul(feePercent).div(ONE_HUNDRED);

            require(remaining >= fee, "Insufficient funds");
            token.transfer(pool_addr, fee);
            emit PoolFee(pool_addr, from, fee);
        }



        token.transferFrom(from, address(this), amount);

        if(user.stake > 0) {
            user.reserved = getStaked(from);
        }else{
            user.stakeDate = now;
        }

        user.checkpoint = now;
        user.lastStage = getCurrentStage();

        user.stake = user.stake.add(amount);
        _stakesBalance = _stakesBalance.add(amount);

        emit Staked(from, amount, user.pool);
    }


    function setUserPool(address addr) public {
        require(addr != address(0), "Pool is zero address");
        require(addr != address(token), "Pool is token address");
        require(isWhitelisted(addr), "Pool is not whitelisted");

        User storage user = _users[msg.sender];

        user.pool = addr;

        emit SetUserPool(addr);
    }

    function setFeePercent(uint256 percent) public onlyOwner {
        require(percent >= 500 && percent <= 1500, "Invalid value");

        feePercent = percent;

        emit SetFeePercent(percent);
    }

    function setFeePeriod(uint256 period) public onlyOwner {
        require(period >= 30 && period <= 365, "Invalid value");

        feePeriod = period;

        emit SetFeePeriod(period);
    }


    function donate(address from, uint256 amount) public {
        require(msg.sender == address(token) || msg.sender == from, "You can send only your tokens");
        require(token.allowance(from, address(this)) >= amount, "Approve this token amount first");

        token.transferFrom(from, address(this), amount);

        emit TotalStaking(msg.sender, from, amount);
    }

    function withdrawAll(address account) public {
        require(msg.sender == account || msg.sender == _owner);

        withdrawStake(account);
        if (_users[account].reserved > 0) {
            withdrawStaked(account);
        }
    }

    function withdrawStake(address account) public {
        require(msg.sender == account || msg.sender == _owner);

        User storage user = _users[account];


        uint256 stake = user.stake;
        require(stake > 0, "Account has no stake");

        if (user.checkpoint < now) {
            user.reserved = getStaked(account);
            user.checkpoint = now;
            user.lastStage = getCurrentStage();
        }


        uint256 fee = 0;
        if(!isWhitelisted(account)){
            if(!(user.stakeDate > 0 && ((now - user.stakeDate) >= (feePeriod * ONE_DAY)))){
                fee = stake.mul(feePercent).div(ONE_HUNDRED);
                stake = stake.sub(fee);
            }
        }


        user.stake = 0;
        user.stakeDate = 0;
        _stakesBalance = _stakesBalance.sub(stake.add(fee));
        address pool_addr = getUserPool(account);

        token.transfer(account, stake);
        emit StakeWithdrawn(msg.sender, account, stake, fee, user.reserved, pool_addr);
    }

    function withdrawStaked(address account) public {
        require(msg.sender == account || msg.sender == _owner);

        User storage user = _users[account];
        uint256 payout = getStaked(account);

        if (user.checkpoint < now) {
            user.checkpoint = now;
            user.lastStage = getCurrentStage();
        }

        if (user.reserved > 0) {
            user.reserved = 0;
        }

        require(payout > 0, "Account has no staked");

        uint256 remaining = getTokenBalanceOf(address(this)).sub(_stakesBalance);

        if (payout > remaining) {
            user.reserved = user.reserved.add(payout - remaining);
            payout = remaining;

            emit StakedReserved(msg.sender, account, user.reserved);
        }

        if (payout > 0) {
            token.transfer(account, payout);
            emit StakedWithdrawn(msg.sender, account, payout);
        }
    }



    function setParameters(uint256 newMinimum, uint256 newMedium, uint256 newMaximum, uint256 newMinPercent, uint256 newMedPercent, uint256 newMaxPercent) public onlyOwner {
        require(newMedium > newMinimum && newMedPercent > newMinPercent, "Medium must be more or equal than minimum");
        require(newMaximum > newMedium && newMaxPercent > newMedPercent, "Maximum must be more or equal than medium");
        require(newMaxPercent <= 60, "maxPercent must be less or equal than 0.6");

        uint256 currentStage = getCurrentStage();
        uint256 nextStage;
        uint256 interval;

        if (_stages.length > 0) {
            Parameters storage current = _stages[currentStage];

            require(newMinimum != current.minimum || newMedium != current.medium || newMaximum != current.maximum || newMinPercent != current.minPercent || newMedPercent != current.medPercent || newMaxPercent != current.maxPercent, "Nothing changes");

            nextStage = currentStage+1;
            if (nextStage >= yearSettingsLimit) {
                require(now - _stages[nextStage - yearSettingsLimit].timestamp >= 365 * ONE_DAY, "Year-settings-limit overflow");
            }

            if (current.interval == 0) {
                interval = now - current.timestamp;
                current.interval = interval;
            }
        }

        _stages.push(Parameters(newMinimum, newMedium, newMaximum, newMinPercent, newMedPercent, newMaxPercent, now, 0));

        emit SetParameters(nextStage, interval, newMinimum, newMedium, newMaximum, newMinPercent, newMedPercent, newMaxPercent);
    }

    function addToWhitelist(address[] memory accounts) public override onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {

            _whitelisteds.add(accounts[i]);
            emit AddedToWhitelist(accounts[i]);
        }
    }

    function removeFromWhitelist(address[] memory accounts) public override onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {

            _whitelisteds.remove(accounts[i]);
            emit RemovedFromWhitelist(accounts[i]);
        }
    }

    function getStake(address addr) public view returns(uint256) {
        return _users[addr].stake;
    }

    function getUserPool(address addr) public view returns(address) {
        return _users[addr].pool;
    }

    function getUserCheckpoint(address addr) public view returns(uint256) {
        return _users[addr].checkpoint;
    }

    function getFeePercent() public view returns(uint256) {
        return feePercent;
    }

    function getFeePeriod() public view returns(uint256) {
        return feePeriod;
    }

    function getPercent(uint256 stake, uint256 stage) public view returns(uint256) {
        Parameters memory par = _stages[stage];

        uint256 userPercent;

        if (stake < par.minimum) {
            userPercent = 0;
        } else if (stake >= par.minimum && stake < par.medium) {
            userPercent = par.minPercent;
        } else if (stake >= par.medium && stake < par.maximum) {
            userPercent = par.medPercent;
        } else if (stake >= par.maximum) {
            userPercent = par.maxPercent;
        }

        return userPercent;
    }

    function getUserPercent(address addr) public view returns(uint256) {
        return getPercent(getStake(addr), getCurrentStage());
    }

    function getStaked(address addr) public view returns(uint256) {
        User storage user = _users[addr];

        uint256 currentStage = getCurrentStage();
        uint256 payout = user.reserved;
        uint256 percent;
        uint256 stake = user.stake;

        if (user.lastStage == currentStage) {

            percent = getUserPercent(addr);
            payout += (stake.mul(percent).div(ONE_HUNDRED)).mul(now.sub(user.checkpoint)).div(ONE_DAY);

        } else {

            uint256 i = currentStage.sub(user.lastStage);

            while (true) {

                percent = getPercent(stake, currentStage-i);

                if (currentStage-i == user.lastStage) {
                    payout += (stake.mul(percent).div(ONE_HUNDRED)).mul(_stages[user.lastStage+1].timestamp.sub(user.checkpoint)).div(ONE_DAY);
                } else if (_stages[currentStage-i].interval != 0) {
                    payout += (stake.mul(percent).div(ONE_HUNDRED)).mul(_stages[currentStage-i].interval).div(ONE_DAY);
                } else {
                    payout += (stake.mul(percent).div(ONE_HUNDRED)).mul(now.sub(_stages[currentStage].timestamp)).div(ONE_DAY);
                    break;
                }

                i--;
            }

        }

        return payout;
    }

    function getAvailable(address addr) public view returns(uint256) {
        return getStake(addr).add(getStaked(addr));
    }

    function getCurrentStage() public view returns(uint256) {
        if (_stages.length > 0) {
            return _stages.length-1;
        }
    }

    function getParameters(uint256 stage) public view returns(uint256 minimum, uint256 medium, uint256 maximum, uint256 minPercent, uint256 medPercent, uint256 maxPercent, uint256 timestamp, uint256 interval) {
        Parameters memory par = _stages[stage];
        return (par.minimum, par.medium, par.maximum, par.minPercent, par.medPercent, par.maxPercent, par.timestamp, par.interval);
    }

    function getCurrentParameters() public view returns(uint256 minimum, uint256 medium, uint256 maximum, uint256 minPercent, uint256 medPercent, uint256 maxPercent, uint256 timestamp, uint256 interval) {
        return getParameters(getCurrentStage());
    }

    function getContractTokenBalance() public view returns(uint256 balance, uint256 stakes, uint256 stakedsupply) {
        balance = token.balanceOf(address(this));
        stakes = _stakesBalance;
        if (balance >= stakes) {
            stakedsupply = balance.sub(stakes);
        }
    }

    function getTokenBalanceOf(address account) public view returns(uint256) {
        return token.balanceOf(account);
    }

    function _bytesToAddress(bytes memory source) internal pure returns(address parsedAddr) {
        assembly {
            parsedAddr := mload(add(source,0x14))
        }
        return parsedAddr;
    }

}