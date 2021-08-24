//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;


import "./ERC20.sol";
import "./ERC918.sol";
import "./Owned.sol";
import "./ApproveAndCallFallBack.sol";


// ----------------------------------------------------------------------------

// 'Autumn Token' contract

// ERC20 & ERC918 Mineable Token using Proof Of Work

// Symbol      : AUTUMN

// Name        : Autumn Token

// Total supply: 33,112,800.00

// Decimals    : 18

// Initial mining reward: 120

// Fraction of total supply released before first halving: 3/7

// ----------------------------------------------------------------------------





contract AutumnToken is ERC20Interface, ERC918, Owned {

    string private constant SYMBOL = "AUTUMN";

    string private constant NAME = "Autumn Token";

    uint256 public constant TOKEN_IDENTIFIER = 3;

    uint8 public constant DECIMALS = 18;

    uint256 public constant TOTAL_SUPPLY = 33112800 * 10**18;

    uint256 public constant INITIAL_REWARD = 120 * 10**18;

    uint256 public constant MAX_REWARDS_AVAILABLE = 72; // no more than 72 rewards per mint

    uint256 public constant REWARD_INTERVAL = 600; // rewards every ten minutes on average

    uint256 public constant DURATION_OF_FIRST_ERA = (365 * 24 * 60 * 60 * 9) / 4; // 27 months

    uint256 public constant DURATION_OF_ERA = 3 * 365 * 24 * 60 * 60; // three years

    uint256 public constant MINIMUM_TARGET = 2**16;

    uint256 public constant MAXIMUM_TARGET = 2**234;

    uint256 public immutable contractCreationTime;

    uint256 public lastRewardBlockTime;

    uint256 public maxNumberOfRewardsPerMint;

    bytes32 private challengeNumber;
        
    uint256 private miningTarget;

    uint256 public tokensMinted;

    mapping(address => uint256) internal balances;

    mapping(address => mapping(address => uint256)) internal allowed;


    constructor() {

        miningTarget = MAXIMUM_TARGET / 2**19;

        contractCreationTime = block.timestamp;
        lastRewardBlockTime = block.timestamp;

        maxNumberOfRewardsPerMint = 1;

        challengeNumber = _getNewChallengeNumber(0);

    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function mint(uint256 nonce) override public returns (bool success) {

        uint256 _lastRewardBlockTime = lastRewardBlockTime;
        
        uint256 singleRewardAmount = _getMiningReward(_lastRewardBlockTime);

        // no more minting when reward reaches zero
        if (singleRewardAmount == 0) revert("Reward has reached zero");

        // the PoW must contain work that includes the challenge number and the msg.sender's address
        bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

        uint256 _miningTarget = miningTarget;
        // the digest must be smaller than the target
        if (uint256(digest) > _miningTarget) revert("Digest is larger than mining target");

        uint256 _previousMaxNumberOfRewards = maxNumberOfRewardsPerMint;
        uint256 numberOfRewardsToGive = _numberOfRewardsToGive(_miningTarget / uint256(digest), 
                                                               _lastRewardBlockTime,
                                                               _previousMaxNumberOfRewards,
                                                               block.timestamp);
        uint256 totalRewardAmount = singleRewardAmount * numberOfRewardsToGive;

        uint256 _tokensMinted = _giveRewards(totalRewardAmount);
        
        _setNextMaxNumberOfRewards(numberOfRewardsToGive, _previousMaxNumberOfRewards);

        miningTarget = _adjustDifficulty(_miningTarget, _lastRewardBlockTime,
                                         numberOfRewardsToGive, block.timestamp);

        bytes32 newChallengeNumber = _getNewChallengeNumber(_tokensMinted);
        challengeNumber = newChallengeNumber;

        lastRewardBlockTime = block.timestamp;

        emit Mint(msg.sender, totalRewardAmount, _scheduledNumberOfRewards(block.timestamp), 
                  newChallengeNumber);

        return true;
    }

    function _numberOfRewardsAvailable(uint256 _lastRewardBlockTime, 
                                       uint256 _previousMaxNumberOfRewards, 
                                       uint256 currentTime) internal pure returns (uint256) {

        uint256 numberAvailable = _previousMaxNumberOfRewards;
        uint256 intervalsSinceLastReward = (currentTime - _lastRewardBlockTime) / REWARD_INTERVAL;
        
        if (intervalsSinceLastReward > numberAvailable)
            numberAvailable = intervalsSinceLastReward;

        if (numberAvailable > MAX_REWARDS_AVAILABLE)
            numberAvailable = MAX_REWARDS_AVAILABLE;

        return numberAvailable;
    }

    function _numberOfRewardsToGive(uint256 numberEarned, uint256 _lastRewardBlockTime, 
                                    uint256 _previousMaxNumberOfRewards,
                                    uint256 currentTime) internal pure returns (uint256) {

        uint256 numberAvailable = _numberOfRewardsAvailable(_lastRewardBlockTime,
                                                         _previousMaxNumberOfRewards,
                                                         currentTime);
        if (numberEarned < numberAvailable)
            return numberEarned;

        return numberAvailable;
    }

    function _giveRewards(uint256 totalReward) internal returns (uint256) {

        balances[msg.sender] += totalReward;
        uint256 _tokensMinted = tokensMinted + totalReward;
        tokensMinted = _tokensMinted;
        return _tokensMinted;
    }

    function _setNextMaxNumberOfRewards(uint256 numberOfRewardsGivenNow, 
                                        uint256 _previousMaxNumberOfRewards) internal {

        // the value of the rewards given to this miner presumably exceed the gas costs
        // for processing the transaction. the next miner can submit a proof of enough work
        // to claim up to the same number of rewards immediately, or, if gas costs have increased,
        // wait until the maximum number of rewards claimable has increased enough to overcome
        // the costs.

        if (numberOfRewardsGivenNow != _previousMaxNumberOfRewards)
            maxNumberOfRewardsPerMint = numberOfRewardsGivenNow;
    }

    // backwards compatible mint function
    function mint(uint256 _nonce, bytes32 _challengeDigest) external returns (bool) {

        bytes32 digest = keccak256(abi.encodePacked(challengeNumber, msg.sender, _nonce));
        require(digest == _challengeDigest, "Challenge digest does not match expected digest on token contract");
        
        return mint(_nonce);
    }

    function _getNewChallengeNumber(uint256 _tokensMinted) internal view returns (bytes32) {
        
        // make the latest ethereum block hash a part of the next challenge

        // xor with a number unique to this token to avoid merged mining
        
        // xor with the number of tokens minted to ensure that the challenge changes
        // even if there are multiple mints in the same ethereum block
        
        return bytes32(uint256(blockhash(block.number - 1)) ^ _tokensMinted ^ TOKEN_IDENTIFIER);
    }


    function _scheduledNumberOfRewards(uint256 currentTime) internal view returns (uint256) {
        return (currentTime - contractCreationTime) / REWARD_INTERVAL;
    }

    function _adjustDifficulty(uint256 _miningTarget, 
                               uint256 _lastRewardBlockTime, 
                               uint256 rewardsGivenNow,
                               uint256 currentTime) internal pure returns (uint256){

        uint256 timeSinceLastReward = currentTime - _lastRewardBlockTime;

        // we target a median interval of 10 minutes multiplied by log(2) ~ 61/88 
        // this gives a mean interval of 10 minutes per reward

        if (timeSinceLastReward * 88 < rewardsGivenNow * REWARD_INTERVAL * 61)
            _miningTarget = (_miningTarget * 99) / 100;   // slow down
        else
            _miningTarget = (_miningTarget * 100) / 99;   // speed up

        if (_miningTarget < MINIMUM_TARGET)
            _miningTarget = MINIMUM_TARGET;
        
        if (_miningTarget > MAXIMUM_TARGET) 
            _miningTarget = MAXIMUM_TARGET;

        return _miningTarget;
    }


    function rewardEra(uint256 _time) public view returns (uint256) {

        uint256 timeSinceContractCreation = _time - contractCreationTime;

        if (timeSinceContractCreation < DURATION_OF_FIRST_ERA)
            return 0;
        else
            return 1 + (timeSinceContractCreation - DURATION_OF_FIRST_ERA) / DURATION_OF_ERA;
    }

    function getAdjustmentInterval() public view override returns (uint256) {
        return REWARD_INTERVAL * maxNumberOfRewardsPerMint;
    }

    function getChallengeNumber() public view override returns (bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public view override returns (uint256) {
        // 64 f's:         1234567890123456789012345678901234567890123456789012345678901234
        uint256 maxInt = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        return maxInt / miningTarget;
    }

    function getMiningTarget() public view override returns (uint256) {
       return miningTarget;
   }

    function getMiningReward() public view override returns (uint256) {

        // use the timestamp of the ethereum block that gave the last reward
        // because ethereum miners can manipulate the value of block.timestamp
        return _getMiningReward(lastRewardBlockTime);
    }

    function _getMiningReward(uint256 _time) internal view returns (uint256) {
        return INITIAL_REWARD / 2**rewardEra(_time);
    }

    function getNumberOfRewardsAvailable(uint256 currentTime) external view returns (uint256) {
        return _numberOfRewardsAvailable(lastRewardBlockTime, 
                                         maxNumberOfRewardsPerMint, 
                                         currentTime);
    }

    function getRewardAmountForAchievingTarget(uint256 targetAchieved, uint256 currentTime) external view returns (uint256) {
        uint256 numberOfRewardsToGive = _numberOfRewardsToGive(miningTarget / targetAchieved, 
                                                               lastRewardBlockTime, 
                                                               maxNumberOfRewardsPerMint, 
                                                               currentTime);
        return _getMiningReward(currentTime) * numberOfRewardsToGive;
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {

        return tokensMinted;
    }


    // ------------------------------------------------------------------------

    // Get the token balance for account `tokenOwner`

    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public view override returns (uint256 balance) {

        return balances[tokenOwner];

    }



    // ------------------------------------------------------------------------

    // Transfer the balance from token owner's account to `to` account

    // - Owner's account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        
        require(to != address(0) && to != address(this), "Invalid address");
        
        balances[msg.sender] = balances[msg.sender] - tokens;

        balances[to] = balances[to] + tokens;

        emit Transfer(msg.sender, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account

    //

    // Warning: This function is vulnerable to double-spend attacks and is

    // included for backwards compatibility. Use safeApprove instead.

    // ------------------------------------------------------------------------

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        
        require(spender != address(0) && spender != address(this), "Invalid address");

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Allow token owner to cancel the approval if the approved amount changes from its last

    // known value before this transaction is processed. This allows the owner to avoid 

    // unintentionally re-approving funds that have already been spent.

    // ------------------------------------------------------------------------

    function safeApprove(address spender, uint256 previousAllowance, uint256 newAllowance) external returns (bool success) {

        require(allowed[msg.sender][spender] == previousAllowance,
                "Current spender allowance does not match specified value");

        return approve(spender, newAllowance);
    }



    // ------------------------------------------------------------------------

    // Transfer `tokens` from the `from` account to the `to` account

    //

    // The calling account must already have sufficient tokens approve(...)-d

    // for spending from the `from` account and

    // - From account must have sufficient balance to transfer

    // - Spender must have sufficient allowance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        
        require(to != address(0) && to != address(this), "Invalid address");

        balances[from] = balances[from] - tokens;

        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;

        balances[to] = balances[to] + tokens;

        emit Transfer(from, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Returns the amount of tokens approved by the owner that can be

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining){

        return allowed[tokenOwner][spender];

    }


    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account. The `spender` contract function

    // `receiveApproval(...)` is then executed. This is vulnerable to double-spend attacks

    // when called directly, so it is declared internal and called by safeApproveAndCall

    // ------------------------------------------------------------------------

    function approveAndCall(address spender, uint256 tokens, bytes memory data) internal returns (bool success) {
        
        require(spender != address(0) && spender != address(this), "Invalid address");

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

        return true;

    }


    // ------------------------------------------------------------------------

    // Allow safe approvals with calls to receiving contract

    // ------------------------------------------------------------------------

    function safeApproveAndCall(address spender, uint256 previousAllowance, 
                                uint256 newAllowance, bytes memory data) external returns (bool success) {

        require(allowed[msg.sender][spender] == previousAllowance,
                "Current spender allowance does not match specified value");

        return approveAndCall(spender, newAllowance, data);
    }


    // ------------------------------------------------------------------------

    // Owner can transfer out any accidentally sent ERC20 tokens

    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }

}