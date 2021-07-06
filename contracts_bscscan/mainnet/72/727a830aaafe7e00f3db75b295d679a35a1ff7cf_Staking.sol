/**
 *Submitted for verification at BscScan.com on 2021-07-06
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

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role internal _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Sender is not whitelisted");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisteds(address[] memory accounts) public virtual onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelisteds.add(accounts[i]);
            emit WhitelistedAdded(accounts[i]);
        }
    }

    function removeWhitelisteds(address[] memory accounts) public virtual onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelisteds.remove(accounts[i]);
            emit WhitelistedRemoved(accounts[i]);
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


    uint256 _depositsBalance;

    Parameters[] _stages;
    struct Parameters {
        uint256 minimum;
        uint256 maximum;
        uint256 minPercent;
        uint256 maxPercent;
        uint256 poolPercent;
        uint256 timestamp;
        uint256 interval;
    }

    uint256 public yearSettingsLimit;

    mapping (address => User) _users;
    struct User {
        uint256 deposit;
        uint256 checkpoint;
        uint256 lastStage;
        uint256 reserved;
        address pool;
    }

    event Invested(address indexed user, uint256 amount);
    event DividendsWithdrawn(address sender, address indexed user, uint256 amount, uint256 fee);
    event DividendsReserved(address sender, address indexed user, uint256 amount);
    event DepositWithdrawn(address sender, address indexed user, uint256 amount, uint256 remaining);
    event SetParameters(uint256 index, uint256 interval, uint256 minimum, uint256 maximum, uint256 minPercent, uint256 maxPercent, uint256 poolPercent);
    event SetPool(address indexed addr);
    event StakingPool(address indexed sender, address indexed from, uint256 amount);
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
            withdrawDividends(msg.sender);
        }
    }

    fallback() external {}

    constructor(address CluiserLandTokenAddr7, uint256 newMinimum, uint256 newMaximum, uint256 newMinPercent, uint256 newMaxPercent, uint256 newPoolPercent, uint256 settingsLimit) public Ownable(msg.sender) {
        require(CluiserLandTokenAddr7 != address(0));

        token = IERC20(CluiserLandTokenAddr7);
        setParameters(newMinimum, newMaximum, newMinPercent, newMaxPercent, newPoolPercent);
        yearSettingsLimit = settingsLimit;
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

        token.transferFrom(from, address(this), amount);

        if (user.deposit > 0) {
            user.reserved = getDividends(from);
        }

        user.checkpoint = now;
        user.lastStage = getCurrentStage();

        user.deposit = user.deposit.add(amount);
        _depositsBalance = _depositsBalance.add(amount);

        emit Invested(from, amount);
    }


    function setPool(address addr) public {
        require(addr != address(0), "Pool is the zero address");
        require(addr != address(token), "Pool is token address");
        require(isWhitelisted(addr), "Pool is not whitelisted");

        User storage user = _users[msg.sender];

        user.pool = addr;

        emit SetPool(addr);
    }



    function donate(address from, uint256 amount) public {
        require(msg.sender == address(token) || msg.sender == from, "You can send only your tokens");
        require(token.allowance(from, address(this)) >= amount, "Approve this token amount first");

        token.transferFrom(from, address(this), amount);

        emit StakingPool(msg.sender, from, amount);
    }

    function withdrawAll(address account) public {
        require(msg.sender == account || msg.sender == _owner);

        withdrawDeposit(account);
        if (_users[account].reserved > 0) {
            withdrawDividends(account);
        }
    }

    function withdrawDeposit(address account) public {
        require(msg.sender == account || msg.sender == _owner);

        User storage user = _users[account];

        uint256 deposit = user.deposit;
        require(deposit > 0, "Account has no deposit");

        if (user.checkpoint < now) {
            user.reserved = getDividends(account);
            user.checkpoint = now;
            user.lastStage = getCurrentStage();
        }

        user.deposit = 0;
        _depositsBalance = _depositsBalance.sub(deposit);

        token.transfer(account, deposit);

        emit DepositWithdrawn(msg.sender, account, deposit, user.reserved);
    }

    function withdrawDividends(address account) public {
        require(msg.sender == account || msg.sender == _owner);

        User storage user = _users[account];
        Parameters memory current = _stages[getCurrentStage()];

        uint256 payout = getDividends(account);

        if (user.checkpoint < now) {
            user.checkpoint = now;
            user.lastStage = getCurrentStage();
        }

        if (user.reserved > 0) {
            user.reserved = 0;
        }

        require(payout > 0, "Account has no dividends");

        uint256 remaining = getTokenBalanceOf(address(this)).sub(_depositsBalance);

        if (payout > remaining) {
            user.reserved = user.reserved.add(payout - remaining);
            payout = remaining;

            emit DividendsReserved(msg.sender, account, user.reserved);
        }

        if (payout > 0) {

            address fee_addr = user.pool != address(0) ? user.pool : _owner;
            uint256 fee = payout.mul(current.poolPercent).div(ONE_HUNDRED);

            payout = payout.sub(fee);
            token.transfer(fee_addr, fee);
            emit PoolFee(fee_addr, msg.sender, fee);

            token.transfer(account, payout);
            emit DividendsWithdrawn(msg.sender, account, payout, fee);
        }
    }



    function setParameters(uint256 newMinimum, uint256 newMaximum, uint256 newMinPercent, uint256 newMaxPercent,  uint256 newPoolPercent) public onlyOwner {
        require(newMaximum >= newMinimum && newMaxPercent >= newMinPercent, "Maximum must be more or equal than minimum");
        require(newMaxPercent <= 50, "maxPercent must be less or equal than 0.5");

        uint256 currentStage = getCurrentStage();
        uint256 nextStage;
        uint256 interval;

        if (_stages.length > 0) {
            Parameters storage current = _stages[currentStage];

            require(newMinimum != current.minimum || newMaximum != current.maximum || newMinPercent != current.minPercent || newMaxPercent != current.maxPercent || newPoolPercent != current.poolPercent, "Nothing changes");

            nextStage = currentStage+1;
            if (nextStage >= yearSettingsLimit) {
                require(now - _stages[nextStage - yearSettingsLimit].timestamp >= 365 * ONE_DAY, "Year-settings-limit overflow");
            }

            if (current.interval == 0) {
                interval = now - current.timestamp;
                current.interval = interval;
            }
        }

        _stages.push(Parameters(newMinimum, newMaximum, newMinPercent, newMaxPercent, newPoolPercent, now, 0));

        emit SetParameters(nextStage, interval, newMinimum, newMaximum, newMinPercent, newMaxPercent, newPoolPercent);
    }

    function addWhitelisteds(address[] memory accounts) public override onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {

            if (_users[accounts[i]].checkpoint < now) {
                _users[accounts[i]].reserved = getDividends(accounts[i]);
                _users[accounts[i]].checkpoint = now;
                _users[accounts[i]].lastStage = getCurrentStage();
            }

            _whitelisteds.add(accounts[i]);
            emit WhitelistedAdded(accounts[i]);
        }
    }

    function removeWhitelisteds(address[] memory accounts) public override onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {

            if (_users[accounts[i]].checkpoint < now) {
                _users[accounts[i]].reserved = getDividends(accounts[i]);
                _users[accounts[i]].checkpoint = now;
                _users[accounts[i]].lastStage = getCurrentStage();
            }

            _whitelisteds.remove(accounts[i]);
            emit WhitelistedRemoved(accounts[i]);
        }
    }

    function getDeposit(address addr) public view returns(uint256) {
        return _users[addr].deposit;
    }

    function getPool(address addr) public view returns(address) {
        return addr != address(0) ? _users[addr].pool : _owner;
    }

    function getUserCheckpoint(address addr) public view returns(uint256) {
        return _users[addr].checkpoint;
    }

    function getPercent(uint256 deposit, uint256 stage) public view returns(uint256) {
        Parameters memory par = _stages[stage];

        uint256 userPercent;

        if (deposit < par.minimum) {
            userPercent = 0;
        } else if (deposit >= par.maximum) {
            userPercent = par.minPercent;
        } else {
            uint256 amount = deposit.sub(par.minimum);
            userPercent = par.maxPercent.sub(amount.mul(par.maxPercent.sub(par.minPercent)).div(par.maximum.sub(par.minimum)));
        }

        return userPercent;
    }

    function getUserPercent(address addr) public view returns(uint256) {
        if (isWhitelisted(addr)) {
            return _stages[getCurrentStage()].maxPercent;
        } else {
            return getPercent(getDeposit(addr), getCurrentStage());
        }
    }

    function getDividends(address addr) public view returns(uint256) {
        User storage user = _users[addr];

        uint256 currentStage = getCurrentStage();
        uint256 payout = user.reserved;
        uint256 percent;
        uint256 deposit = user.deposit;

        if (user.lastStage == currentStage) {

            if (isWhitelisted(addr)) {
                percent = _stages[currentStage].maxPercent;
            } else if (deposit > _stages[currentStage].maximum) {
                deposit = _stages[currentStage].maximum;
                percent = _stages[currentStage].minPercent;
            } else {
                percent = getUserPercent(addr);
            }

            payout += (deposit.mul(percent).div(ONE_HUNDRED)).mul(now.sub(user.checkpoint)).div(ONE_DAY);

        } else {

            uint256 i = currentStage.sub(user.lastStage);

            while (true) {

                if (isWhitelisted(addr)) {
                    percent = _stages[currentStage-i].maxPercent;
                } else if (deposit > _stages[currentStage].maximum) {
                    deposit = _stages[currentStage-i].maximum;
                    percent = _stages[currentStage-i].minPercent;
                } else {
                    percent = getPercent(deposit, currentStage-i);
                }

                if (currentStage-i == user.lastStage) {
                    payout += (deposit.mul(percent).div(ONE_HUNDRED)).mul(_stages[user.lastStage+1].timestamp.sub(user.checkpoint)).div(ONE_DAY);
                } else if (_stages[currentStage-i].interval != 0) {
                    payout += (deposit.mul(percent).div(ONE_HUNDRED)).mul(_stages[currentStage-i].interval).div(ONE_DAY);
                } else {
                    payout += (deposit.mul(percent).div(ONE_HUNDRED)).mul(now.sub(_stages[currentStage].timestamp)).div(ONE_DAY);
                    break;
                }

                i--;
            }

        }

        return payout;
    }

    function getAvailable(address addr) public view returns(uint256) {
        return getDeposit(addr).add(getDividends(addr));
    }

    function getCurrentStage() public view returns(uint256) {
        if (_stages.length > 0) {
            return _stages.length-1;
        }
    }

    function getParameters(uint256 stage) public view returns(uint256 minimum, uint256 maximum, uint256 minPercent, uint256 maxPercent, uint256 poolPercent, uint256 timestamp, uint256 interval) {
        Parameters memory par = _stages[stage];
        return (par.minimum, par.maximum, par.minPercent, par.maxPercent, par.poolPercent, par.timestamp, par.interval);
    }

    function getCurrentParameters() public view returns(uint256 minimum, uint256 maximum, uint256 minPercent, uint256 maxPercent, uint256 poolPercent, uint256 timestamp, uint256 interval) {
        return getParameters(getCurrentStage());
    }

    function getContractTokenBalance() public view returns(uint256 balance, uint256 deposits, uint256 dividends) {
        balance = token.balanceOf(address(this));
        deposits = _depositsBalance;
        if (balance >= deposits) {
            dividends = balance.sub(deposits);
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