// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./CTokenInterface.sol";
import "./SafeERC20.sol";
import "./EIP20NonStandardInterface.sol";


contract Staking is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint128 constant private BASE_MULTIPLIER = uint128(1 * 10 ** 18);

    // timestamp for the epoch 1
    // everything before that is considered epoch 0 which won't have a reward but allows for the initial stake
    uint256 public epoch1Start;

    // duration of each epoch
    uint256 public epochDuration;

    // holds the current balance of the user for each token
    mapping(address => mapping(address => uint256)) private balances;
    mapping(address => uint256) public stableCoinBalances;
    
    address constant public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant public wbtcSwappLP = 0x5548F847Fd9a1D3487d5fbB2E8d73972803c4Cce;
    
    address constant public cUsdc = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address constant public cUsdt = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;
    address constant public cDai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    
    // address to pay interest from Сompound
    address payable constant TEAM_ADDRESS = 0xde121Cc755c1D1786Dd46FfF7e373e9372FD79D8;

    struct Pool {
        uint256 size;
        bool set;
    }

    // for each token, we store the total pool size
    mapping(address => mapping(uint256 => Pool)) private poolSize;

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    // balanceCheckpoints[user][token][]
    mapping(address => mapping(address => Checkpoint[])) private balanceCheckpoints;

    mapping(address => uint128) private lastWithdrawEpochId;


    //referrals
    uint256 public firstReferrerRewardPercentage;
    uint256 public secondReferrerRewardPercentage;

    struct Referrer {
        // uint256 totalReward;
        uint256 referralsCount;
        mapping(uint256 => address) referrals;
    }

    // staker to referrer
    mapping(address => address) public referrals;
    // referrer data
    mapping(address => Referrer) public referrers;

    event Deposit(address indexed user, address indexed tokenAddress, uint256 amount);
    event Withdraw(address indexed user, address indexed tokenAddress, uint256 amount);
    event ManualEpochInit(address indexed caller, uint128 indexed epochId, address[] tokens);
    event EmergencyWithdraw(address indexed user, address indexed tokenAddress, uint256 amount);
    event RegisteredReferer(address referral, address referrer);
    
    event GetInterest(address indexed token, uint256 amount);
    event CheckInterest(uint256 cBalance, uint256 uBalance, uint256 interest);

    address public _owner;

    constructor () {
        epoch1Start = 1624230000;
        epochDuration = 2419200; // 28 days

        _owner = msg.sender;

        firstReferrerRewardPercentage = 1000;
        secondReferrerRewardPercentage = 500;
    }

    function checkStableCoin(address token) public pure returns (bool) {
        if (token == usdc ||
            token == usdt ||
            token == dai
        ) {
            return true;
        }
        return false;
    }

    /*
     * Stores `amount` of `tokenAddress` tokens for the `user` into the vault
     */
    function deposit(address tokenAddress, uint256 amount, address referrer) public nonReentrant {
        require(amount > 0, "Staking: Amount must be > 0");
        bool isStableCoin = checkStableCoin(tokenAddress);

        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount, "Staking: Token allowance too small");
        
        if (isStableCoin) {
            stableCoinBalances[tokenAddress] = stableCoinBalances[tokenAddress].add(amount);
            if (tokenAddress == usdt) {
                EIP20NonStandardInterface token = EIP20NonStandardInterface(tokenAddress);
                token.transferFrom(msg.sender, address(this), amount);
            } else {
                IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
            }
            _transferToCompound(tokenAddress, amount);
        } else {
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        }

        if (referrer != address(0)) {
            processReferrals(referrer);
        }

        balances[msg.sender][tokenAddress] = balances[msg.sender][tokenAddress].add(amount);

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();
        uint128 currentMultiplier = currentEpochMultiplier();

        if (!epochIsInitialized(tokenAddress, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            manualEpochInit(tokens, currentEpoch);
        }

        // update the next epoch pool size
        Pool storage pNextEpoch = poolSize[tokenAddress][currentEpoch + 1];
        if (isStableCoin) {
            pNextEpoch.size = stableCoinBalances[tokenAddress];
        } else {
            pNextEpoch.size = IERC20(tokenAddress).balanceOf(address(this));
        }
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[msg.sender][tokenAddress];

        uint256 balanceBefore = getEpochUserBalance(msg.sender, tokenAddress, currentEpoch);

        // if there's no checkpoint yet, it means the user didn't have any activity
        // we want to store checkpoints both for the current epoch and next epoch because
        // if a user does a withdraw, the current epoch can also be modified and
        // we don't want to insert another checkpoint in the middle of the array as that could be expensive
        if (checkpoints.length == 0) {
            checkpoints.push(Checkpoint(currentEpoch, currentMultiplier, 0, amount));

            // next epoch => multiplier is 1, epoch deposits is 0
            checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, amount, 0));
        } else {
            uint256 last = checkpoints.length - 1;

            // the last action happened in an older epoch (e.g. a deposit in epoch 3, current epoch is >=5)
            if (checkpoints[last].epochId < currentEpoch) {
                uint128 multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    BASE_MULTIPLIER,
                    amount,
                    currentMultiplier
                );
                checkpoints.push(Checkpoint(currentEpoch, multiplier, getCheckpointBalance(checkpoints[last]), amount));
                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));
            }
            // the last action happened in the previous epoch
            else if (checkpoints[last].epochId == currentEpoch) {
                checkpoints[last].multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    checkpoints[last].multiplier,
                    amount,
                    currentMultiplier
                );
                checkpoints[last].newDeposits = checkpoints[last].newDeposits.add(amount);

                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));
            }
            // the last action happened in the current epoch
            else {
                if (last >= 1 && checkpoints[last - 1].epochId == currentEpoch) {
                    checkpoints[last - 1].multiplier = computeNewMultiplier(
                        getCheckpointBalance(checkpoints[last - 1]),
                        checkpoints[last - 1].multiplier,
                        amount,
                        currentMultiplier
                    );
                    checkpoints[last - 1].newDeposits = checkpoints[last - 1].newDeposits.add(amount);
                }

                checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
            }
        }

        uint256 balanceAfter = getEpochUserBalance(msg.sender, tokenAddress, currentEpoch);

        poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.add(balanceAfter.sub(balanceBefore));

        emit Deposit(msg.sender, tokenAddress, amount);
    }

    // must be in bases point ( 1,5% = 150 bp)
    function updateReferrersPercentage(uint256 first, uint256 second) external {
        require(msg.sender == _owner, "Only owner can perfrom this action");
        firstReferrerRewardPercentage = first;
        secondReferrerRewardPercentage = second;
    }

    function processReferrals(address referrer) internal {
        //Return if sender has referrer alredy or referrer is contract or self ref
        if (hasReferrer(msg.sender) || !notContract(referrer) || referrer == msg.sender) {
            return;
        }

        //check cross refs 
        if (referrals[referrer] == msg.sender || referrals[referrals[referrer]] == msg.sender) {
            return;
        }
        
        //check if already has stake, do not add referrer if has
        if (balanceOf(msg.sender, usdc) > 0 || balanceOf(msg.sender, usdt) > 0 || balanceOf(msg.sender, dai) > 0 || balanceOf(msg.sender, wbtcSwappLP) > 0) {
            return;
        }

        referrals[msg.sender] = referrer;

        Referrer storage refData = referrers[referrer];

        refData.referralsCount = refData.referralsCount.add(1);
        refData.referrals[refData.referralsCount] = msg.sender;
        emit RegisteredReferer(msg.sender, referrer);
    }

    function hasReferrer(address addr) public view returns(bool) {
        return referrals[addr] != address(0);
    }

    function getReferralById(address referrer, uint256 id) public view returns (address) {
        return referrers[referrer].referrals[id];
    }
    
    function _transferToCompound(address tokenAddress, uint256 amount) internal {
        address cToken = _getCompoundToken(tokenAddress);
        IERC20(tokenAddress).safeApprove(cToken, amount);
        CTokenInterface(cToken).mint(amount);
    }
    
    function _redeemFromCompound(address tokenAddress, uint256 amount) internal {
        address cToken = _getCompoundToken(tokenAddress);
        CTokenInterface(cToken).redeemUnderlying(amount);
    }
    
    function _getCompoundToken(address tokenAddress) internal pure returns (address cToken) {
        if (tokenAddress == usdc) {
            return cUsdc;
        }
        if (tokenAddress == usdt) {
            return cUsdt;
        }
        if (tokenAddress == dai) {
            return cDai;
        }
    }
    
    function checkInterestFromCompound(address tokenAddress) external returns (uint256 interest){
        bool isStableCoin = checkStableCoin(tokenAddress);
        require(isStableCoin, "Wrong token address");
        
        address cToken = _getCompoundToken(tokenAddress);
        uint256 cTBalance = CTokenInterface(cToken).balanceOf(address(this));
        if (cTBalance == 0) {
            emit CheckInterest(cTBalance, 0, 0);
            return 0;
        }
        
        uint256 cBalance = CTokenInterface(cToken).balanceOfUnderlying(address(this));
        uint256 balance = stableCoinBalances[tokenAddress];
        if (balance >= cBalance) {
            emit CheckInterest(cBalance, balance, 0);
            return 0;
        }
        
        uint256 _interest = cBalance.sub(balance);
        emit CheckInterest(cBalance, balance, _interest);
        return _interest;
    }
    
    //Get 80% of interest from Compound
    function getInterestFromCompound(address tokenAddress) external nonReentrant{
        bool isStableCoin = checkStableCoin(tokenAddress);
        require(isStableCoin, "Wrong token address");
        
        address cToken = _getCompoundToken(tokenAddress);
        uint256 cTBalance = CTokenInterface(cToken).balanceOf(address(this));
        require(cTBalance > 0, "There is no interest to withdraw");

        uint256 cBalance = CTokenInterface(cToken).balanceOfUnderlying(address(this));
        uint256 balance = stableCoinBalances[tokenAddress];
        require(cBalance > balance, "There is no interest to withdraw");

        uint256 interest = cBalance.sub(balance).mul(4).div(5);

        if (interest > 0) {
            CTokenInterface(cToken).redeemUnderlying(interest);
            if (tokenAddress == usdt) {
                EIP20NonStandardInterface(tokenAddress).transfer(TEAM_ADDRESS, interest);
            } else {
                IERC20(tokenAddress).transfer(TEAM_ADDRESS, interest);
            }
            emit GetInterest(tokenAddress, interest);
        }
    }
    
     //Get 100% of interest from Compound, recommended only after all users withdrawn their tokens
    function getInterest(address tokenAddress) external nonReentrant{
        bool isStableCoin = checkStableCoin(tokenAddress);
        require(isStableCoin, "Wrong token address");
        
        address cToken = _getCompoundToken(tokenAddress);
        uint256 cBalance = CTokenInterface(cToken).balanceOf(address(this));
        require(cBalance > 0, "No funds to withdraw");
        uint256 balance = stableCoinBalances[tokenAddress];
        CTokenInterface(cToken).redeem(cBalance);
        
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        
        uint256 interest = tokenBalance.sub(balance);
        if (interest > 0) {
            if (tokenAddress == usdt) {
                EIP20NonStandardInterface(tokenAddress).transfer(TEAM_ADDRESS, interest);
            } else {
                IERC20(tokenAddress).transfer(TEAM_ADDRESS, interest);
            }
            emit GetInterest(tokenAddress, interest);
        }
        
        if (balance > 0) {
            IERC20(tokenAddress).safeApprove(cToken, balance);
            CTokenInterface(cToken).mint(balance);
        }
    }
    
    /*
     * Removes the deposit of the user and sends the amount of `tokenAddress` back to the `user`
     */
    function withdraw(address tokenAddress, uint256 amount) public nonReentrant {
        require(balances[msg.sender][tokenAddress] >= amount, "Staking: balance too small");

        bool isStableCoin = checkStableCoin(tokenAddress);

        balances[msg.sender][tokenAddress] = balances[msg.sender][tokenAddress].sub(amount);

        if (isStableCoin) {
            stableCoinBalances[tokenAddress] = stableCoinBalances[tokenAddress].sub(amount);
            _redeemFromCompound(tokenAddress, amount);
            if (tokenAddress == usdt) {
                EIP20NonStandardInterface(tokenAddress).transfer(msg.sender, amount);
            } else {
                IERC20(tokenAddress).transfer(msg.sender, amount);
            }
        } else {
            IERC20(tokenAddress).transfer(msg.sender, amount);
        }

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();

        lastWithdrawEpochId[tokenAddress] = currentEpoch;

        if (!epochIsInitialized(tokenAddress, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            manualEpochInit(tokens, currentEpoch);
        }

        // update the pool size of the next epoch to its current balance
        Pool storage pNextEpoch = poolSize[tokenAddress][currentEpoch + 1];
        if (isStableCoin) {
            pNextEpoch.size = stableCoinBalances[tokenAddress];
        } else {
            pNextEpoch.size = IERC20(tokenAddress).balanceOf(address(this));
        }
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[msg.sender][tokenAddress];
        uint256 last = checkpoints.length - 1;

        // note: it's impossible to have a withdraw and no checkpoints because the balance would be 0 and revert

        // there was a deposit in an older epoch (more than 1 behind [eg: previous 0, now 5]) but no other action since then
        if (checkpoints[last].epochId < currentEpoch) {
            checkpoints.push(Checkpoint(currentEpoch, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the `epochId - 1` epoch => we have a checkpoint for the current epoch
        else if (checkpoints[last].epochId == currentEpoch) {
            checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
            checkpoints[last].newDeposits = 0;
            checkpoints[last].multiplier = BASE_MULTIPLIER;

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the current epoch
        else {
            Checkpoint storage currentEpochCheckpoint = checkpoints[last - 1];

            uint256 balanceBefore = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            // in case of withdraw, we have 2 branches:
            // 1. the user withdraws less than he added in the current epoch
            // 2. the user withdraws more than he added in the current epoch (including 0)
            if (amount < currentEpochCheckpoint.newDeposits) {
                uint128 avgDepositMultiplier = uint128(
                    balanceBefore.sub(currentEpochCheckpoint.startBalance).mul(BASE_MULTIPLIER).div(currentEpochCheckpoint.newDeposits)
                );

                currentEpochCheckpoint.newDeposits = currentEpochCheckpoint.newDeposits.sub(amount);

                currentEpochCheckpoint.multiplier = computeNewMultiplier(
                    currentEpochCheckpoint.startBalance,
                    BASE_MULTIPLIER,
                    currentEpochCheckpoint.newDeposits,
                    avgDepositMultiplier
                );
            } else {
                currentEpochCheckpoint.startBalance = currentEpochCheckpoint.startBalance.sub(
                    amount.sub(currentEpochCheckpoint.newDeposits)
                );
                currentEpochCheckpoint.newDeposits = 0;
                currentEpochCheckpoint.multiplier = BASE_MULTIPLIER;
            }

            uint256 balanceAfter = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(balanceBefore.sub(balanceAfter));

            checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
        }

        emit Withdraw(msg.sender, tokenAddress, amount);
    }

    /*
     * manualEpochInit can be used by anyone to initialize an epoch based on the previous one
     * This is only applicable if there was no action (deposit/withdraw) in the current epoch.
     * Any deposit and withdraw will automatically initialize the current and next epoch.
     */
    function manualEpochInit(address[] memory tokens, uint128 epochId) public {
        require(epochId <= getCurrentEpoch(), "can't init a future epoch");

        for (uint i = 0; i < tokens.length; i++) {
            Pool storage p = poolSize[tokens[i]][epochId];

            if (epochId == 0) {
                p.size = uint256(0);
                p.set = true;
            } else {
                require(!epochIsInitialized(tokens[i], epochId), "Staking: epoch already initialized");
                require(epochIsInitialized(tokens[i], epochId - 1), "Staking: previous epoch not initialized");

                p.size = poolSize[tokens[i]][epochId - 1].size;
                p.set = true;
            }
        }

        emit ManualEpochInit(msg.sender, epochId, tokens);
    }

    function emergencyWithdraw(address tokenAddress) public {
        bool isStableCoin = checkStableCoin(tokenAddress);
        require(!isStableCoin, "Cant withdraw stable coins");
        require((getCurrentEpoch() - lastWithdrawEpochId[tokenAddress]) >= 10, "At least 10 epochs must pass without success");

        uint256 totalUserBalance = balances[msg.sender][tokenAddress];
        require(totalUserBalance > 0, "Amount must be > 0");

        balances[msg.sender][tokenAddress] = 0;

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, totalUserBalance);

        emit EmergencyWithdraw(msg.sender, tokenAddress, totalUserBalance);
    }

    /*
     * Returns the valid balance of a user that was taken into consideration in the total pool size for the epoch
     * A deposit will only change the next epoch balance.
     * A withdraw will decrease the current epoch (and subsequent) balance.
     */
    function getEpochUserBalance(address user, address token, uint128 epochId) public view returns (uint256) {
        Checkpoint[] storage checkpoints = balanceCheckpoints[user][token];

        // if there are no checkpoints, it means the user never deposited any tokens, so the balance is 0
        if (checkpoints.length == 0 || epochId < checkpoints[0].epochId) {
            return 0;
        }

        uint min = 0;
        uint max = checkpoints.length - 1;

        // shortcut for blocks newer than the latest checkpoint == current balance
        if (epochId >= checkpoints[max].epochId) {
            return getCheckpointEffectiveBalance(checkpoints[max]);
        }

        // binary search of the value in the array
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].epochId <= epochId) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return getCheckpointEffectiveBalance(checkpoints[min]);
    }

    /*
     * Returns the amount of `token` that the `user` has currently staked
     */
    function balanceOf(address user, address token) public view returns (uint256) {
        return balances[user][token];
    }

    /*
     * Returns the id of the current epoch derived from block.timestamp
     */
    function getCurrentEpoch() public view returns (uint128) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return uint128((block.timestamp - epoch1Start) / epochDuration + 1);
    }

    /*
     * Returns the total amount of `tokenAddress` that was locked from beginning to end of epoch identified by `epochId`
     */
    function getEpochPoolSize(address tokenAddress, uint128 epochId) public view returns (uint256) {
        // Premises:
        // 1. it's impossible to have gaps of uninitialized epochs
        // - any deposit or withdraw initialize the current epoch which requires the previous one to be initialized
        if (epochIsInitialized(tokenAddress, epochId)) {
            return poolSize[tokenAddress][epochId].size;
        }

        // epochId not initialized and epoch 0 not initialized => there was never any action on this pool
        if (!epochIsInitialized(tokenAddress, 0)) {
            return 0;
        }

        // epoch 0 is initialized => there was an action at some point but none that initialized the epochId
        // which means the current pool size is equal to the current balance of token held by the staking contract
        IERC20 token = IERC20(tokenAddress);

        if (checkStableCoin(tokenAddress)) {
            return stableCoinBalances[tokenAddress];
        }

        return token.balanceOf(address(this));
    }

    /*
     * Returns the percentage of time left in the current epoch
     */
    function currentEpochMultiplier() public view returns (uint128) {
        uint128 currentEpoch = getCurrentEpoch();
        uint256 currentEpochEnd = epoch1Start + currentEpoch * epochDuration;
        uint256 timeLeft = currentEpochEnd - block.timestamp;
        uint128 multiplier = uint128(timeLeft * BASE_MULTIPLIER / epochDuration);

        return multiplier;
    }

    function computeNewMultiplier(uint256 prevBalance, uint128 prevMultiplier, uint256 amount, uint128 currentMultiplier) public pure returns (uint128) {
        uint256 prevAmount = prevBalance.mul(prevMultiplier).div(BASE_MULTIPLIER);
        uint256 addAmount = amount.mul(currentMultiplier).div(BASE_MULTIPLIER);
        uint128 newMultiplier = uint128(prevAmount.add(addAmount).mul(BASE_MULTIPLIER).div(prevBalance.add(amount)));

        return newMultiplier;
    }

    /*
     * Checks if an epoch is initialized, meaning we have a pool size set for it
     */
    function epochIsInitialized(address token, uint128 epochId) public view returns (bool) {
        return poolSize[token][epochId].set;
    }

    function getCheckpointBalance(Checkpoint memory c) internal pure returns (uint256) {
        return c.startBalance.add(c.newDeposits);
    }

    function getCheckpointEffectiveBalance(Checkpoint memory c) internal pure returns (uint256) {
        return getCheckpointBalance(c).mul(c.multiplier).div(BASE_MULTIPLIER);
    }

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly { size := extcodesize(_addr) }
        return (size == 0);
    }
}