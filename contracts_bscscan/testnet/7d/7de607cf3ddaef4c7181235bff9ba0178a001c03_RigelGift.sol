// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

 // import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMathUint8.sol";
import "./SafeMath.sol";
import "./ABDKMath64x64.sol";

pragma experimental ABIEncoderV2;

/// @title GiftInfluencer is responsible for managing crypto rewards and airdrops
contract RigelGift is Ownable {
    using SafeMath for uint256;
    using SafeMathUint8 for uint8;

    uint8 public _maxBuyableSpins;
    uint8 public _maxReferralSpins;

    address public _RGPTokenAddress;
    address public _RGPTokenReceiver;

    uint256 public _rewardProjectCounter;
    uint256 public _perSpinFee = 10 * 10**18;
    uint256 public _subscriptionFee = 10 * 10**18;

    // address _RGPTokenAddress = "0x4af5ff1a60a6ef6c7c8f9c4e304cd9051fca3ec0";

    constructor(address _rigel) public {
        _RGPTokenReceiver = _msgSender();
        _RGPTokenAddress = _rigel;
        _maxBuyableSpins = 5;
        _maxReferralSpins = 5;
        _rewardProjectCounter = 1;
    }
    // Defining a ticker reward inforamtion
    struct TickerInfo {
        uint8 textIndex;
        uint8 weight;
        address token;
        uint256 rewardAmount;
        uint256 cumulitiveSum;
        uint256 claims;
        uint256 initialClaimTotal;
    }

    // Defining a project reward inforamtion
    struct TokenInfo {
        address token;
        uint256 balance;
        uint256 totalFunds;
    }

    // Defining a Project Reward
    struct RewardProject {
        bool status;
        address projOwner;
        uint256 tryCount;
        uint256 retryPeriod;
        uint256 rewardProjectID;
        uint256 claimedCount;
        uint256 projectStartTime;
        uint256 activePeriodInDays;
        uint256 totalSumOfWeights;
    }

    // Defining a User Reward Claim Data
    struct UserClaimData {
        uint8 bSpinAvlb;
        uint8 bSpinUsed;
        uint8 rSpinAvlb;
        uint8 rSpinUsed;
        uint256 time;
        uint256 pSpin;
    }

    // All tickers for a given RewardProject
    mapping(uint256 => TickerInfo[]) public rewardTickers;

    // All rewards for a given RewardProject
    mapping(uint256 => TokenInfo[]) public rewardTokens;

    // Mapping of the ProjectReward and its information
    mapping(uint256 => RewardProject) public rewardProjMapping;

    // Mapping of the project, rewardees and their claim data
    mapping(uint256 => mapping(address => UserClaimData)) public projectClaims;

    // Simply all projectIDs for traversing
    uint256[] public rewardProjects;

    // Event when a Reward Project is created
    event RewardProjectCreate(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );
    // Event when a Reward Project is edited by owner
    event RewardProjectEdit(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );
    // Event when a Reward Project is closed by owner
    event RewardProjectClose(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );

    // Event when a Rewards in a Project is withdrawn
    event RewardsWithdrawn(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );

    // Event when an user buys spins
    event SpinBought(
        uint256 indexed projectIndex,
        address indexed buyer,
        uint8 indexed count
    );

    // Event when an user earns a spin
    event SpinEarned(
        uint256 indexed projectIndex,
        address indexed linkCreator,
        address indexed linkUser
    );

    // Spin and Claim Rewards
    event RewardEarned(
        uint256 indexed projectIndex,
        address indexed winner,
        uint8 indexed ticker
    );

    function onlyActiveProject(uint256 projectID) private view {
        RewardProject memory proj = rewardProjMapping[projectID];
        proj.status == true;
    }

    //create the reward project
    function createRewardProject(
        uint256 tryCount,
        uint256 retryPeriod,
        uint256 activePeriodInDays,
        bytes[] calldata rewards,
        bytes[] calldata tickerInfo
    ) external {
        // RGP Tokens must be approved for transfer
        
        IERC20(_RGPTokenAddress).transferFrom(
            _msgSender(),
            _RGPTokenReceiver,
            _subscriptionFee
        );

        (bool status, uint256 sumOfWeights) =
            _setTickers(_rewardProjectCounter, tickerInfo);
        require(status == true, "RigelGift: _setTickers fail");

        status = _setRewards(_rewardProjectCounter, rewards);
        require(status == true, "RigelGift: _setRewards fail");

        RewardProject memory rewardProj =
            RewardProject(
                true,
                _msgSender(),
                tryCount,
                retryPeriod,
                _rewardProjectCounter,
                0,
                block.timestamp,
                activePeriodInDays,
                sumOfWeights
            );
        rewardProjMapping[_rewardProjectCounter] = rewardProj;
        rewardProjects.push(_rewardProjectCounter);

        emit RewardProjectCreate(_msgSender(), _rewardProjectCounter);
        _rewardProjectCounter = _rewardProjectCounter.add(1);
    }
    function _setRewardProcess(bytes calldata reward) public returns (TokenInfo memory t) {
        (address token, uint256 balance) = decodeTokenInfo(reward);

        require(token != address(0), "RigelGift: ZeroAddress");
        // transfer token to gift contract:
        
        IERC20(token).transferFrom(_msgSender(), address(this), balance);
        TokenInfo memory t = TokenInfo(token, balance, balance);
        return t;
    }
    function _setRewards(uint256 projectID, bytes[] calldata rewards)
        private
        returns (bool status)
    {
        require(rewards.length > 0 && rewards.length < 3, "RigelGift: Must have at least one token and not more than 2");
        TokenInfo memory t = _setRewardProcess(rewards[0]);
        rewardTokens[projectID].push(t);
        if(rewards.length == 2){
            TokenInfo memory t2 = _setRewardProcess(rewards[1]);
            rewardTokens[projectID].push(t2);
        }
        return true;
    }

    function _setTickers(uint256 projectID, bytes[] calldata tickerInfo)
        private
        returns (bool status, uint256 cumulitiveSum)
    {
        uint256 csum;

        for (uint8 i = 0; i < tickerInfo.length; i++) {
            ( 
                uint8 textIndex,
                uint8 weight, 
                address token, 
                uint256 amount
            ) = decodeTickerInfo(tickerInfo[i]);

            isValidWeight(token, weight);

            csum = csum.add(weight);

            TickerInfo memory ticker =
                TickerInfo(textIndex, weight, token, amount, csum, 0, 0);
            rewardTickers[projectID].push(ticker);
        }

        return (true, csum);
    }

    //edit rewards
    function editRewardProject(
        uint256 projectID,
        uint256 tryCount,
        uint256 retryPeriod,
        uint256 addToActivePeriod,
        bytes[] calldata rewards,
        bytes[] calldata tickerInfo
    ) external {
        RewardProject storage proj = rewardProjMapping[projectID];

        require(proj.projOwner == _msgSender(), "RigelGift: ProjectOwner Only");

        require(proj.status == true, "RigelGift: Active Project Only");

        proj.tryCount = tryCount;
        proj.retryPeriod = retryPeriod;
        proj.activePeriodInDays.add(addToActivePeriod);

        // delete rewardTickers[projectID];
        (bool status, uint256 sumOfWeights) =
            _editTickers(projectID, tickerInfo);
        require(status == true, "RigelGift: _editTickers fail");
        proj.totalSumOfWeights = sumOfWeights;

        status = _editRewards(projectID, rewards);
        require(status == true, "RigelGift: _editRewards fail");

        emit RewardProjectEdit(_msgSender(), projectID);
    }
    function _editRewardProcess (uint8 position, uint256 projectID, bytes calldata reward) private returns (bool) {
        TokenInfo[] storage rewards = rewardTokens[projectID];
        (address token, uint256 topup) = decodeTokenInfo(reward);
        if (topup != 0) {
            require(rewards[position].token == token, "RigelGift: Invalid Token");
            IERC20(token).transferFrom(
                _msgSender(),
                address(this),
                topup
            ); 
            rewards[position].balance = rewards[position].balance.add(topup);
            rewards[position].totalFunds = rewards[position].totalFunds.add(topup);
            // transfer token to gift contract:  
        }
        return true;
    }
    function _editRewards(uint256 projectID, bytes[] calldata editRewards)
        private
        returns (bool status)
    {
        if(editRewards.length > 0){
            _editRewardProcess(0, projectID, editRewards[0]);
            if(editRewards.length > 1){
                _editRewardProcess(1, projectID, editRewards[1]);
            }
        }
        return true;
    }
    function _editTickers(uint256 projectID, bytes[] calldata newTickerInfo)
        private
        returns (bool status, uint256 cumulitivieSum)
    {
        TickerInfo[] storage tickers = rewardTickers[projectID];

        require(
            tickers.length == newTickerInfo.length,
            "RigelGift: Invalid Ticker Count"
        );

        uint256 csum;

        for (uint8 i = 0; i < tickers.length; i++) {
            (
                uint8 textIndex, 
                uint8 weight, 
                address token, 
                uint256 amount 
            ) = decodeTickerInfo(newTickerInfo[i]);

            isValidWeight(token, weight);

            csum = csum.add(weight);

            require(tickers[i].token == token, "RigelGift: Invalid Token");

            tickers[i].initialClaimTotal = tickers[i].initialClaimTotal.add(
                tickers[i].claims.mul(tickers[i].rewardAmount)
            );
            tickers[i].rewardAmount = amount;
            tickers[i].cumulitiveSum = csum;
            tickers[i].weight = weight;
            tickers[i].claims = 0;
            tickers[i].textIndex = textIndex;
        }
        return (true, csum);
    }

    function isValidWeight(address token, uint8 weight) private pure {
        if (token != address(0)) {
            require(weight != 0, "RigelGift: Invalid Weight");
        }
    }

    function decodeTokenInfo(bytes calldata rewardInfo)
        private
        pure
        returns (address, uint256)
    {
        return abi.decode(rewardInfo, (address, uint256));
    }

    function decodeTickerInfo(bytes calldata tickerInfo)
        private
        pure
        returns (
            uint8,
            uint8,
            address,
            uint256
        )
    {
        return abi.decode(tickerInfo, (uint8, uint8, address, uint256));
    }

    function closeProject(uint256 projectID) public {
        //set reward project to inactive status
        RewardProject storage proj = rewardProjMapping[projectID];

        require(proj.projOwner == _msgSender(), "RigelGift: ProjectOwner Only");

        require(
            block.timestamp >=
                proj.projectStartTime.add(proj.activePeriodInDays.mul(1 days)),
            "RigelGift: Before Active Period"
        );

        proj.status = false;

        emit RewardProjectClose(proj.projOwner, projectID);
    }

    //withdraw tokens and close project
    function closeProjectWithdrawTokens(uint256 projectID) external {
        RewardProject storage proj = rewardProjMapping[projectID];

        //set reward project to inactive status
        closeProject(projectID);

        //transfer balance reward tokens to project owner
        TokenInfo[] storage rewards = rewardTokens[projectID];
        for (uint8 i = 0; i < rewards.length; i++) {
            TokenInfo memory reward = rewards[i];
            uint256 tempBalance = reward.balance;
            reward.balance = 0;
            IERC20(reward.token).transfer(proj.projOwner, tempBalance);
        }

        emit RewardsWithdrawn(proj.projOwner, projectID);
    }

    //claim rewards
    function claimReward(uint256 projectID, uint8 tickerNum) private {
        RewardProject storage proj = rewardProjMapping[projectID];
        require(proj.status == true, "RigelGift: Active Project Only");

        proj.claimedCount = proj.claimedCount.add(1);

        TickerInfo storage ticker = rewardTickers[projectID][tickerNum];

        if (ticker.token == address(0)) {
            setClaimData(projectID);
            return;
        }

        TokenInfo memory chosenReward;
        TokenInfo[] storage rewardInfos = rewardTokens[projectID];
        for (uint8 i = 0; i < rewardInfos.length; i++) {
            if (rewardInfos[i].token == ticker.token) {
                chosenReward = rewardInfos[i];
                break;
            }
        }

        isEligibleForReward(projectID);

        chosenReward.balance = chosenReward.balance.sub(
            ticker.rewardAmount
        );

        setClaimData(projectID);
        ticker.claims = ticker.claims.add(1);

        
        IERC20(chosenReward.token).transfer(
            _msgSender(),
            ticker.rewardAmount
        );
    }

    function isEligibleForReward(uint256 projectID) public view {
        RewardProject memory proj = rewardProjMapping[projectID];

        require(proj.status == true, "RigelGift: Active Project Only");

        UserClaimData memory claim = projectClaims[projectID][_msgSender()];

        // If BoughtSpins Available and BoughtSpins Used are equal that means they are used up or
        // If RefferalSpinsAvailable and ReferralSpinsUsed are equal that means they are used up
        if (!(isBoughtSpinsAvlb(claim) || isReferrralSpinsAvlb(claim))) {
            require(
                block.timestamp >= (claim.time + proj.retryPeriod),
                "RigelGift: Claim before retry period"
            );

            require(
                claim.pSpin < proj.tryCount,
                "RigelGift: Claim limit reached"
            );
        }
    }

    // Checks if any bought spins are available
    function isBoughtSpinsAvlb(UserClaimData memory claim)
        private
        pure
        returns (bool)
    {
        // If BoughtSpins Available and BoughtSpins Used are equal that means they are used up
        if (claim.bSpinAvlb == claim.bSpinUsed) {
            return false;
        } else {
            return true;
        }
    }

    // Checks if any referral spins are available
    function isReferrralSpinsAvlb(UserClaimData memory claim)
        private
        pure
        returns (bool)
    {
        // If RefferalSpins Available and ReferralSpins Used are equal that means they are used up
        if (claim.rSpinAvlb == claim.rSpinUsed) {
            return false;
        } else {
            return true;
        }
    }

    // Captures and updates the claim Data w.r.t all spin types
    function setClaimData(uint256 projectID) private {
        UserClaimData memory claim = projectClaims[projectID][_msgSender()];

        if (isBoughtSpinsAvlb(claim)) {
            // If BoughtSpins Available and BoughtSpins Used are equal that means they are used up
            claim.bSpinUsed = claim.bSpinUsed.add(1);
        } else if (isReferrralSpinsAvlb(claim)) {
            // If RefferalSpins Available and ReferralSpins Used are equal that means they are used up
            claim.rSpinUsed = claim.rSpinUsed.add(1);
        } else {
            claim.time = block.timestamp;
            claim.pSpin = claim.pSpin.add(1);
        }
        projectClaims[projectID][_msgSender()] = claim;
    }

    // Set the subscription fee, settable only be the owner
    function setSubscriptionFee(uint256 fee) external onlyOwner {
        _subscriptionFee = fee;
    }

    // Set the buy spin fee, settable only be the owner
    function setPerSpinFee(uint256 fee) external onlyOwner {
        _perSpinFee = fee;
    }

    // Set the RGP receiver address
    function setRGPReveiverAddress(address rgpReceiver) external onlyOwner {
        require(rgpReceiver != address(0), "RigelGift: ZeroAddress");

        _RGPTokenReceiver = rgpReceiver;
    }

    // Set the RGP Token address
    function setRGPTokenAddress(address rgpToken) external onlyOwner {
        _RGPTokenAddress = rgpToken;
    }

    // Set maxbuyable spins per user address, per project
    function setMaxBuyableSpins(uint8 count) external onlyOwner {
        _maxBuyableSpins = count;
    }

    // Allows user to buy specified spins for the specified project
    function buySpin(uint256 projectID, uint8 spinCount) external {
        onlyActiveProject(projectID);
        UserClaimData memory claim = projectClaims[projectID][_msgSender()];

        // Eligible to buy spins only upto specified limit
        require(
            claim.bSpinAvlb + spinCount <= _maxBuyableSpins,
            "RigelGift: Beyond Spin Limit"
        );

        // RGP Tokens must be approved for transfer
        
        IERC20(_RGPTokenAddress).transferFrom(
            _msgSender(),
            _RGPTokenReceiver,
            _perSpinFee * spinCount
        );

        // Update Available spins
        claim.bSpinAvlb = claim.bSpinAvlb.add(spinCount);
        projectClaims[projectID][_msgSender()] = claim;

        emit SpinBought(projectID, _msgSender(), spinCount);
    }

    // Set max referral spins per user address, per project that can be earned
    function setMaxReferralSpins(uint8 count) external onlyOwner {
        _maxReferralSpins = count;
    }

    function spinAndClaim(uint256 projectID, address linkCreator) external {
        onlyActiveProject(projectID);
        uint8 tickerNum = generateRandomTicker(projectID);
        // user claims reward
        claimReward(projectID, tickerNum);

        require(linkCreator != _msgSender(), "RigelGift: Self Refferal fail");

        if (linkCreator != address(0)) {
            UserClaimData memory claim = projectClaims[projectID][linkCreator];

            // Eligible to earn referral spins only upto specified limit
            if (claim.rSpinAvlb.add(1) <= _maxReferralSpins) {
                claim.rSpinAvlb = claim.rSpinAvlb.add(1);
                projectClaims[projectID][linkCreator] = claim;

                emit SpinEarned(projectID, linkCreator, _msgSender());
            }
        }
        emit RewardEarned(projectID, _msgSender(), tickerNum);
    }

    function generateRandomTicker(uint256 projectID)
        private
        view
        returns (uint8 tickerNum)
    {
        RewardProject memory proj = rewardProjMapping[projectID];
        TickerInfo[] memory tickers = rewardTickers[projectID];

        //calculateRandomNumber(): Calculates a random number in the range 0.00000 to 1.00000
        // with a presicion to 5 decimal places
        uint256 r =
            ABDKMath64x64.mulu(
                ABDKMath64x64.abs(calculateRandomNumber()),
                proj.totalSumOfWeights
            );

        uint8 i;
        for (i = 0; i < tickers.length; i++) {
            if (r <= tickers[i].cumulitiveSum) {
                break;
            }
        }
        return i;
    }

    // Calculates a random number in the range 0.00000 to 1.00000 with a presicion to 5 decimal places
    // function calculateRandomNumber(uint256 nonce)
    function calculateRandomNumber() private view returns (int128) {
        uint256 max = uint256(0) - uint256(1);
        uint256 scalifier = max / 100000;
        uint256 seed =
            uint256(
                keccak256(abi.encodePacked(block.timestamp, _msgSender(), block.difficulty))
            ) / scalifier;
        return ABDKMath64x64.divu(seed, 100000);
    }
    //DAPP GETTERS
    function projectClaimsByProjectId(uint256 projectID) external view returns (uint256) {
        RewardProject memory proj = rewardProjMapping[projectID];
        return proj.claimedCount;
    }
    function getProjectTokenBalance(uint256 projectID, address token) external view returns (uint256) {
        TokenInfo memory chosenReward;
        TokenInfo[] memory rewardInfos = rewardTokens[projectID];
        for (uint8 i = 0; i < rewardInfos.length; i++) {
            if (rewardInfos[i].token == token) {
                chosenReward = rewardInfos[i];
                break;
            }
        }
        return chosenReward.balance;
    }
    function getProjectTickers(uint256 projectID) external view returns(TickerInfo[] memory){
        return rewardTickers[projectID];
    }
    function getProjectTokens(uint256 projectID) external view returns (TokenInfo[] memory) {
        return rewardTokens[projectID];
    }
}