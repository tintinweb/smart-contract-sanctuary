pragma solidity ^0.4.24;

/*******************************************************************************
 *
 * Copyright (c) 2018 Decentralization Authority MDAO.
 * Released under the MIT License.
 *
 * ZeroGold POW Mining
 * 
 * An ERC20 token wallet which dispenses tokens via Proof of Work mining.
 * Based on recommendation from /u/diego_91
 * 
 * Version 18.8.19
 *
 * Web    : https://d14na.org
 * Email  : <span class="__cf_email__" data-cfemail="592a2c2929362b2d193d686d373877362b3e">[email&#160;protected]</span>
 */


/*******************************************************************************
 *
 * SafeMath
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


/*******************************************************************************
 *
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);
    }
}


/*******************************************************************************
 *
 * ERC Token Standard #20 Interface
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/*******************************************************************************
 *
 * ERC 918 Mineable Token Interface
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-918.md
 */
contract ERC918Interface {
    function getChallengeNumber() public constant returns (bytes32);
    function getMiningDifficulty() public constant returns (uint);
    function getMiningTarget() public constant returns (uint);
    function getMiningReward() public constant returns (uint);

    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;
    bytes32 public challengeNumber;
}

/*******************************************************************************
 *
 * @notice ZeroGoldDust - Merged Mining Contract
 *
 * @dev This is a standard ERC20 mineable token contract.
 */
contract ZeroGoldPOWMining is Owned {
    using SafeMath for uint;

    /* Initialize the ZeroGold contract. */
    ERC20Interface zeroGold;
    
    /* Initialize the Mining Leader contract. */
    ERC918Interface public miningLeader;
    
    /* Initialize the Mint Helper. */
    address public mintHelper = 0x0;

    modifier onlyMintHelper {
        require(msg.sender == mintHelper);
        _;
    }
    
    /* Reward divisor. */
    // NOTE A value of 20 means the reward is 1/20 (5%) 
    //      of current tokens held in the quarry. 
    uint rewardDivisor = 20;

    /* Number of times this has been mined. */
    uint epochCount = 0;
    
    /* Initialize last reward value. */
    uint public lastRewardAmount = 0;

    mapping(bytes32 => bytes32) solutionForChallenge;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    constructor(address _miningLeader, address _mintHelper) public  {
        /* Initialize the mining leader. */
        miningLeader = ERC918Interface(_miningLeader);

        /* Initialize the mint helper (address ONLY). */
        mintHelper = _mintHelper;

        /* Initialize the ZeroGold contract. */
        // NOTE We hard-code the address here, since it should never change.
        zeroGold = ERC20Interface(0x6ef5bca539A4A01157af842B4823F54F9f7E9968);
    }

    /**
     * Merge
     * (called from our mining leader)
     * 
     * Ensure that mergeMint() can only be called once per Parent::mint().
     * Do this by ensuring that the "new" challenge number from 
     * Parent::challenge post mint can be called once and that this block time 
     * is the same as this mint, and the caller is msg.sender.
     * 
     * Only allow one reward for each challenge. Do this by calculating what 
     * the new challenge will be in _startNewMiningEpoch, and verify that 
     * it is not that value this checks happen in the local contract, not in the parent
     * 
     */
    function merge() external onlyMintHelper returns (bool success) {
        /* Retrieve the future challenge number from mining leader. */
        bytes32 futureChallengeNumber = blockhash(block.number - 1);

        /* Retrieve the challenge number from the mining leader. */
        bytes32 challengeNumber = miningLeader.getChallengeNumber();

        /* Verify the next challenge is different from the current. */
        if (challengeNumber == futureChallengeNumber) {
            // NOTE This is likely the second time that merge() has been
            //      called in a transaction, so return false (don&#39;t revert).
            return false; 
        }

        /* Verify Parent::lastRewardTo == msg.sender. */
        if (miningLeader.lastRewardTo() != msg.sender) {
            // NOTE A different address called mint last 
            //      so return false (don&#39;t revert).
            return false;
        }
            
        /* Verify Parent::lastRewardEthBlockNumber == block.number. */
        if (miningLeader.lastRewardEthBlockNumber() != block.number) {
            // NOTE parent::mint() was called in a different block number 
            //      so return false (don&#39;t revert).
            return false;
        }

        // We now update the solutionForChallenge hashmap with the value of 
        // parent::challengeNumber when a solution is merge minted. Only allow 
        // one reward for each challenge based on parent::challengeNumber.
        bytes32 parentChallengeNumber = miningLeader.challengeNumber();
        bytes32 solution = solutionForChallenge[parentChallengeNumber];
        if (solution != 0x0) return false; // prevent the same answer from awarding twice
        
        bytes32 digest = &#39;merge&#39;;
        solutionForChallenge[parentChallengeNumber] = digest;

        // We may safely run the relevant logic to give an award to the sender, 
        // and update the contract.
        
        /* Retrieve the reward value. */
        uint rewardAmount = getRewardAmount();

        /* Retrieve our ZeroGold balance. */
        uint balance = zeroGold.balanceOf(address(this));

        /* Verify that we are not trying to transfer more than we HODL. */
        assert(rewardAmount <= balance);

        /* Set last reward amount. */
        // NOTE `lastRewardAmount` is called from MintHelper during `merge` 
        //      to assign `merge_totalReward`.
        lastRewardAmount = rewardAmount;
        
        /* Increment the epoch count. */
        epochCount = epochCount.add(1);

        // NOTE: Use 0 to indicate a merge mine.
        emit Mint(msg.sender, rewardAmount, epochCount, 0);

        return true;
    }

    /* Transfer the ZeroGold reward to our mining leader&#39;s payout wallets. */
    // NOTE This function will be called twice by MintHelper.merge(), 
    //      once for `minterWallet` and once for `payoutsWallet`.
    function transfer(
        address _wallet, 
        uint _reward
    ) external onlyMintHelper returns (bool) {
        /* Verify our mining leader isn&#39;t trying to over reward its wallets. */
        if (_reward > lastRewardAmount) {
            return false;
        }
            
        /* Reduce the last reward amount. */
        lastRewardAmount = lastRewardAmount.sub(_reward);

        /* Transfer the ZeroGold to mining leader. */
        zeroGold.transfer(_wallet, _reward);
    }

    /* Calculate the current reward value. */
    function getRewardAmount() public constant returns (uint) {
        /* Retrieve the balance of the mineable token. */
        uint totalBalance = zeroGold.balanceOf(address(this));

        return totalBalance.div(rewardDivisor);
    }

    /* Set the mining leader. */
    function setMiningLeader(address _miningLeader) external onlyOwner {
        miningLeader = ERC918Interface(_miningLeader);
    }

    /* Set the mint helper. */
    function setMintHelper(address _mintHelper) external onlyOwner {
        mintHelper = _mintHelper;
    }

    /* Set the reward divisor. */
    function setRewardDivisor(uint _rewardDivisor) external onlyOwner {
        rewardDivisor = _rewardDivisor;
    }

    /**
     * THIS CONTRACT DOES NOT ACCEPT DIRECT ETHER
     */
    function () public payable {
        /* Cancel this transaction. */
        revert(&#39;Oops! Direct payments are NOT permitted here.&#39;);
    }

    /**
     * Transfer Any ERC20 Token
     *
     * @notice Owner can transfer out any accidentally sent ERC20 tokens.
     *
     * @dev Provides an ERC20 interface, which allows for the recover
     *      of any accidentally sent ERC20 tokens.
     */
    function transferAnyERC20Token(
        address tokenAddress, uint tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}