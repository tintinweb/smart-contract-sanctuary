// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract XEDStaking is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeERC20 for IERC20;

    bool public active;

    // set with beginStaking()
    uint256 public startTime;

    // users will have 10 days before staking gets closed for depositing
    uint256 public cutoffTime;
    IERC20 internal immutable stakingToken;

    // used for whitelisting users for staking by signing a message
    address private bouncer;

    enum poolNames {BRONZE, SILVER, GOLD}

    struct pool {
        uint256 maturityAPY;
        uint64 daysToMaturity;
        uint64 earlyWithdrawalAPY;
        uint64 daysToEarlyWithdrawal;
        uint256 maxPoolCapacity; // maximum of funds staked in total
        uint256 rewardSupply; // reward supply available for the pool
        uint256 stakingFunds; // staking rewards not withdrawn yet
        uint256 userFunds; // gets decreased with withdrawals
        uint256 totalDeposited; // doesn't get decreased with withdrawals
    }

    mapping(poolNames => pool) public pools;

    struct userDeposit {
        uint256 amount;
        uint256 depositTime;
    }

    mapping(address => mapping(poolNames => userDeposit)) private userDeposits;

    // Sum of the rewardSupply of all pools rounded up -> (821918 + 5753425 + 12328768) / 100
    uint256 public constant TOTAL_REWARD_SUPPLY = (18904111 * 1 ether) / 100;
    uint256 public constant MIN_STAKING_AMOUNT = 2000 * 1 ether;

    constructor(IERC20 tokenContract) {
        stakingToken = tokenContract;
        bouncer = msg.sender;

        pools[poolNames.BRONZE] = pool({
            maturityAPY: 20,
            daysToMaturity: 60,
            earlyWithdrawalAPY: 8,
            daysToEarlyWithdrawal: 30,
            maxPoolCapacity: 250000 * 1 ether,
            rewardSupply: (821918 * 1 ether) / 100, // 250000*20*60 / (100*365)
            stakingFunds: 0,
            userFunds: 0,
            totalDeposited: 0
        });

        pools[poolNames.SILVER] = pool({
            maturityAPY: 35,
            daysToMaturity: 120,
            earlyWithdrawalAPY: 14,
            daysToEarlyWithdrawal: 60,
            maxPoolCapacity: 500000 * 1 ether,
            rewardSupply: (5753425 * 1 ether) / 100, // 500000*35*120 / (100*365)
            stakingFunds: 0,
            userFunds: 0,
            totalDeposited: 0
        });

        pools[poolNames.GOLD] = pool({
            maturityAPY: 50,
            daysToMaturity: 180,
            earlyWithdrawalAPY: 20,
            daysToEarlyWithdrawal: 100,
            maxPoolCapacity: 500000 * 1 ether,
            rewardSupply: (12328768 * 1 ether) / 100, // 500000*50*180 / (100*365)
            stakingFunds: 0,
            userFunds: 0,
            totalDeposited: 0
        });
    }

    // Bouncer will be a hot wallet in our backend without any critical access (e.g: access to funds)
    // If the hot wallet gets compromised, the owner can just change the bouncer without any critical issues.
    function setBouncer(address _bouncer) external onlyOwner {
        bouncer = _bouncer;
    }

    // Our backend will send to allowed users a signed message (signed by the bouncer)
    // with this contract address and user address
    modifier onlyAllowedUser(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        require(
            isAllowedUser(msg.sender, _v, _r, _s),
            "User isn't authorized to perform this operation."
        );
        _;
    }

    // Function that checks if a given address is allowed by checking the signature
    // of the message sent by the backend.
    // To whitelist all addresses, the bouncer can be set to address(0).
    function isAllowedUser(
        address user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), user));
        return
            bouncer ==
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                _v,
                _r,
                _s
            );
    }

    // Collect any funds that are in the contract, including those that are sent
    // accidentally to it.
    function collect(poolNames _pool) external onlyOwner {
        require(block.timestamp > cutoffTime, "Can only collect excess reward tokens after deposits are locked");
        uint256 excessRewards = getExcessRewards(_pool);
        pools[_pool].stakingFunds = pools[_pool].stakingFunds.sub(excessRewards);
        stakingToken.safeTransfer(owner(), excessRewards);
    }

    event Deposit(
        poolNames indexed pool,
        address indexed userAddress,
        uint256 depositAmount
    );

    function deposit(
        uint256 _depositAmount,
        poolNames _pool,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyAllowedUser(_v, _r, _s) {
        require(active, "Staking is not active yet");
        require(block.timestamp < cutoffTime, "Deposit time period over");
        require(_depositAmount >= MIN_STAKING_AMOUNT, "Deposit amount too low");

        uint256 newUserFunds = pools[_pool].userFunds.add(_depositAmount);
        require(
            newUserFunds <= pools[_pool].maxPoolCapacity,
            "Staking capacity exceeded"
        );

        pools[_pool].totalDeposited = pools[_pool].totalDeposited.add(
            _depositAmount
        );
        pools[_pool].userFunds = newUserFunds;

        userDeposits[msg.sender][_pool].amount = userDeposits[msg.sender][_pool]
            .amount
            .add(_depositAmount);
        userDeposits[msg.sender][_pool].depositTime = block.timestamp;

        stakingToken.safeTransferFrom(
            msg.sender,
            address(this),
            _depositAmount
        );
        emit Deposit(_pool, msg.sender, _depositAmount);
    }

    event Withdraw(
        poolNames indexed pool,
        address indexed userAddress,
        uint256 principal,
        uint256 yield
    );

    // if withdrawn before early withdrawal period user gets 0% APY (only gets his/her funds back)
    function withdraw(poolNames _pool) external {
        uint256 withdrawalAmount = userDeposits[msg.sender][_pool].amount;
        require(withdrawalAmount > 0, "nothing to withdraw");

        uint256 userYield = getUserYield(msg.sender, _pool);
        pools[_pool].userFunds = pools[_pool].userFunds.sub(withdrawalAmount);
        pools[_pool].stakingFunds = pools[_pool].stakingFunds.sub(userYield);

        delete userDeposits[msg.sender][_pool];

        uint256 totalToTransfer = withdrawalAmount.add(userYield);

        stakingToken.safeTransfer(msg.sender, totalToTransfer);
        emit Withdraw(_pool, msg.sender, withdrawalAmount, userYield);
    }

    event StakingBegins(uint256 timestamp, uint256 stakingFunds);

    function beginStaking() external onlyOwner {
        require(
            stakingToken.balanceOf(address(this)) >= TOTAL_REWARD_SUPPLY,
            "Not enough staking rewards"
        );
        require(!active, "Can only begin staking once");
        active = true;
        startTime = block.timestamp;
        cutoffTime = startTime.add(10 days);
        pools[poolNames.BRONZE].stakingFunds = pools[poolNames.BRONZE]
            .rewardSupply;
        pools[poolNames.SILVER].stakingFunds = pools[poolNames.SILVER]
            .rewardSupply;
        pools[poolNames.GOLD].stakingFunds = pools[poolNames.GOLD].rewardSupply;
        emit StakingBegins(startTime, TOTAL_REWARD_SUPPLY);
    }

    function getYieldMultiplier(uint256 daysStaked, poolNames _pool)
        public
        view
        returns (uint256)
    {
        if (daysStaked >= pools[_pool].daysToMaturity)
            return pools[_pool].maturityAPY;
        if (daysStaked >= pools[_pool].daysToEarlyWithdrawal)
            return pools[_pool].earlyWithdrawalAPY;
        return 0;
    }

    function getUserYield(address _userAddress, poolNames _pool)
        public
        view
        returns (uint256)
    {
        uint256 depositTime = userDeposits[_userAddress][_pool].depositTime;
        uint256 amount = userDeposits[_userAddress][_pool].amount;

        uint256 daysStaked = (block.timestamp - depositTime) / 1 days;

        uint256 yieldMultiplier = getYieldMultiplier(daysStaked, _pool);
        uint256 daysMultiplier = getNDays(daysStaked, _pool);

        return (amount * yieldMultiplier * daysMultiplier) / (100 * 365);
    }

    function getExcessRewards(poolNames _pool)
        public
        view
        returns (uint256)
    {
        uint256 pendingUsersRewards = 
        (pools[_pool].userFunds 
        * pools[_pool].daysToMaturity 
        * pools[_pool].maturityAPY) / (100 * 365);

        return pools[_pool].stakingFunds.sub(pendingUsersRewards);     
    }

    function getNDays(uint256 daysStaked, poolNames _pool)
        public
        view
        returns (uint64)
    {
        if (daysStaked >= pools[_pool].daysToMaturity)
            return pools[_pool].daysToMaturity;
        if (daysStaked >= pools[_pool].daysToEarlyWithdrawal)
            return pools[_pool].daysToEarlyWithdrawal;
        return 0;
    }

    function getUserDeposit(address _userAddress, poolNames _pool)
        external
        view
        returns (userDeposit memory)
    {
        return userDeposits[_userAddress][_pool];
    }

    function getStakingPool(poolNames _pool)
        external
        view
        returns (pool memory)
    {
        return pools[_pool];
    }
}