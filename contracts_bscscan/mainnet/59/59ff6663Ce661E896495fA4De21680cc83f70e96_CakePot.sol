/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ICakePot {

    event Start(uint256 indexed season);
    event End(uint256 indexed season);
    event Enter(uint256 indexed season, address indexed who, uint256 amount);
    event Exit(uint256 indexed season, address indexed who, uint256 amount);
    
    function currentSeason() external view returns (uint256);
    
    function userCounts(uint256 season) external view returns (uint256);
    function amounts(uint256 season, address who) external view returns (uint256);
    function totalAmounts(uint256 season) external view returns (uint256);
    function weights(uint256 season, address who) external view returns (uint256);
    function totalWeights(uint256 season) external view returns (uint256);
    
    function ssrs(uint256 season, uint256 index) external view returns (address);
    function srs(uint256 season, uint256 index) external view returns (address);
    function rs(uint256 season, uint256 index) external view returns (address);
    
    function checkEnd() external view returns (bool);
    function enter(uint256 amount) external;
    function end() external;
    function exit(uint256 season) external;
}


interface IHanulRNG {
    function generateRandomNumber(uint256 seed, address sender) external returns (uint256);
}


interface IMasterChef {
    function cakePerBlock() view external returns(uint);
    function totalAllocPoint() view external returns(uint);

    function poolInfo(uint _pid) view external returns(address lpToken, uint allocPoint, uint lastRewardBlock, uint accCakePerShare);
    function userInfo(uint _pid, address _account) view external returns(uint amount, uint rewardDebt);
    function poolLength() view external returns(uint);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IFungibleToken is IERC20 {
    
    function version() external view returns (string memory);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


interface IDubu is IFungibleToken {
    function mint(address to, uint256 amount) external;
}


interface IDubuEmitter {

    event Add(address to, uint256 allocPoint);
    event Set(uint256 indexed pid, uint256 allocPoint);

    function dubu() external view returns (IDubu);
    function emitPerBlock() external view returns (uint256);
    function startBlock() external view returns (uint256);

    function poolCount() external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (
        address to,
        uint256 allocPoint,
        uint256 lastEmitBlock
    );
    function totalAllocPoint() external view returns (uint256);

    function pendingToken(uint256 pid) external view returns (uint256);
    function updatePool(uint256 pid) external;
}


interface IDubuDividend {

    event Distribute(address indexed by, uint256 distributed);
    event Claim(address indexed to, uint256 claimed);

    function accumulativeOf(address owner) external view returns (uint256);
    function claimedOf(address owner) external view returns (uint256);
    function claimableOf(address owner) external view returns (uint256);
    function claim() external;
}


contract DubuDividend is IDubuDividend {

    IDubuEmitter private constant DUBU_EMITTER = IDubuEmitter(0xDDb921d4F0264c10884D652E3aB9704F8189DAf4);
    IBEP20 private constant DUBU = IBEP20(0x972543fe8BeC404AB14e0c38e942032297f44B2A);
    IBEP20 private token;

    uint256 private immutable pid;

    constructor(IBEP20 _token) {
        token = _token;
        pid = DUBU_EMITTER.poolCount();
    }

    uint256 internal currentBalance = 0;
    mapping(address => uint256) internal cakeBalances;

    uint256 constant internal pointsMultiplier = 2**128;
    uint256 internal pointsPerShare = 0;
    mapping(address => int256) internal pointsCorrection;
    mapping(address => uint256) internal claimed;

    function updateBalance() internal {
        uint256 totalBalance = token.balanceOf(address(this));
        if (totalBalance > 0) {
            DUBU_EMITTER.updatePool(pid);
            uint256 balance = DUBU.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                pointsPerShare += value * pointsMultiplier / totalBalance;
                emit Distribute(msg.sender, value);
            }
            currentBalance = balance;
        }
    }

    function claimedOf(address owner) override public view returns (uint256) {
        return claimed[owner];
    }

    function accumulativeOf(address owner) override public view returns (uint256) {
        uint256 _pointsPerShare = pointsPerShare;
        uint256 totalBalance = token.balanceOf(address(this));
        if (totalBalance > 0) {
            uint256 balance = DUBU_EMITTER.pendingToken(pid) + DUBU.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                _pointsPerShare += value * pointsMultiplier / totalBalance;
            }
            return uint256(int256(_pointsPerShare * cakeBalances[owner]) + pointsCorrection[owner]) / pointsMultiplier;
        }
        return 0;
    }

    function claimableOf(address owner) override external view returns (uint256) {
        return accumulativeOf(owner) - claimed[owner];
    }

    function _accumulativeOf(address owner) internal view returns (uint256) {
        return uint256(int256(pointsPerShare * cakeBalances[owner]) + pointsCorrection[owner]) / pointsMultiplier;
    }

    function _claimableOf(address owner) internal view returns (uint256) {
        return _accumulativeOf(owner) - claimed[owner];
    }

    function claim() override external {
        updateBalance();
        uint256 claimable = _claimableOf(msg.sender);
        if (claimable > 0) {
            claimed[msg.sender] += claimable;
            emit Claim(msg.sender, claimable);
            DUBU.transfer(msg.sender, claimable);
            currentBalance -= claimable;
        }
    }

    function _enter(uint256 amount) internal {
        updateBalance();
        cakeBalances[msg.sender] += amount;
        pointsCorrection[msg.sender] -= int256(pointsPerShare * amount);
    }

    function _exit(uint256 amount) internal {
        updateBalance();
        cakeBalances[msg.sender] -= amount;
        pointsCorrection[msg.sender] += int256(pointsPerShare * amount);
    }
}


contract CakePot is Ownable, ICakePot, DubuDividend {

    IHanulRNG private rng = IHanulRNG(0x92eE48b37386b997FAF1571789cd53A7f9b7cdd7);
    IBEP20 private constant CAKE = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IMasterChef private constant CAKE_MASTER_CHEF = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    
    uint256 public period = 720;
    uint256 override public currentSeason = 0;
    uint256 public startSeasonBlock;

    mapping(uint256 => uint256) override public userCounts;
    mapping(uint256 => mapping(address => uint256)) override public amounts;
    mapping(uint256 => uint256) override public totalAmounts;
    mapping(uint256 => mapping(address => uint256)) override public weights;
    mapping(uint256 => uint256) override public totalWeights;
    
    mapping(uint256 => uint256) public maxSSRCounts;
    mapping(uint256 => uint256) public maxSRCounts;
    mapping(uint256 => uint256) public maxRCounts;
    mapping(uint256 => uint256) public ssrRewards;
    mapping(uint256 => uint256) public srRewards;
    mapping(uint256 => uint256) public rRewards;
    mapping(uint256 => uint256) public nRewards;

    mapping(uint256 => address[]) override public ssrs;
    mapping(uint256 => address[]) override public srs;
    mapping(uint256 => address[]) override public rs;
    mapping(uint256 => mapping(address => bool)) public exited;

    constructor() DubuDividend(CAKE) {
        CAKE.approve(address(CAKE_MASTER_CHEF), type(uint256).max);
        startSeasonBlock = block.number;
        emit Start(0);
    }

    function setRNG(IHanulRNG _rng) external onlyOwner {
        rng = _rng;
    }

    function setPeriod(uint256 _period) external onlyOwner {
        period = _period;
    }

    function checkEnd() override public view returns (bool) {
        return block.number - startSeasonBlock > period;
    }

    function enter(uint256 amount) override external {
        require(amount > 0);
        require(checkEnd() != true);

        if (amounts[currentSeason][msg.sender] == 0) {
            userCounts[currentSeason] += 1;
        }
        
        amounts[currentSeason][msg.sender] += amount;
        totalAmounts[currentSeason] += amount;
        uint256 weight = (period - (block.number - startSeasonBlock)) * amount;
        weights[currentSeason][msg.sender] += weight;
        totalWeights[currentSeason] += weight;

        CAKE.transferFrom(msg.sender, address(this), amount);
        CAKE_MASTER_CHEF.enterStaking(amount);

        _enter(amount);
        emit Enter(currentSeason, msg.sender, amount);
    }

    function end() override external {
        require(checkEnd() == true);

        uint256 userCount = userCounts[currentSeason];
        (uint256 staked,) = CAKE_MASTER_CHEF.userInfo(0, address(this));
        CAKE_MASTER_CHEF.leaveStaking(staked);
        uint256 balance = CAKE.balanceOf(address(this));
        uint256 totalReward = balance - staked;

        // ssr
        uint256 maxSSRCount = userCount * 3 / 100; // 3%
        uint256 totalSSRReward = totalReward * 3 / 10; // 30%
        maxSSRCounts[currentSeason] = maxSSRCount;
        ssrRewards[currentSeason] = maxSSRCount == 0 ? 0 : totalSSRReward / maxSSRCount;

        // sr
        uint256 maxSRCount = userCount * 7 / 100; // 7%
        uint256 totalSRReward = totalReward / 5; // 20%
        maxSRCounts[currentSeason] = maxSRCount;
        srRewards[currentSeason] = maxSRCount == 0 ? 0 : totalSRReward / maxSRCount;

        // r
        uint256 maxRCount = userCount * 3 / 20; // 15%
        uint256 totalRReward = totalReward / 10; // 10%
        maxRCounts[currentSeason] = maxRCount;
        rRewards[currentSeason] = maxRCount == 0 ? 0 : totalRReward / maxRCount;

        // n
        nRewards[currentSeason] = userCount == 0 ? 0 : (totalReward - totalSSRReward - totalSRReward - totalRReward) / userCount;

        emit End(currentSeason);

        // start next season.
        currentSeason += 1;
        startSeasonBlock = block.number;
        emit Start(currentSeason);
    }

    function exit(uint256 season) override external {
        require(season < currentSeason);
        require(exited[season][msg.sender] != true);
        
        uint256 enterAmount = amounts[season][msg.sender];
        _exit(enterAmount);

        uint256 amount = enterAmount + nRewards[season];
        uint256 weight = weights[season][msg.sender];

        uint256 a = userCounts[season] * totalWeights[season] / weight;
        uint256 k = (rng.generateRandomNumber(season, msg.sender) % 100) * a;
        if (ssrs[season].length < maxSSRCounts[season] && k < 3) { // 3%, sr
            ssrs[season].push(msg.sender);
            amount += ssrRewards[season];
        }
        
        k = (rng.generateRandomNumber(season, msg.sender) % 100) * a;
        if (srs[season].length < maxSRCounts[season] && k < 7) { // 7%, sr
            srs[season].push(msg.sender);
            amount += srRewards[season];
        }
        
        k = (rng.generateRandomNumber(season, msg.sender) % 100) * a;
        if (rs[season].length < maxRCounts[season] && k < 15) { // 15%, r
            rs[season].push(msg.sender);
            amount += rRewards[season];
        }

        // n
        CAKE.transfer(msg.sender, amount);

        exited[season][msg.sender] = true;
        
        emit Exit(season, msg.sender, amount);
    }
}