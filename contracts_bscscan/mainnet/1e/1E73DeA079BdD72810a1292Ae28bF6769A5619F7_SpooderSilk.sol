/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: MIT


// Current Version of solidity
pragma solidity ^0.8.2;

// SPOOD Interface
interface SpooderToken {
    function allowance() external view returns (uint);
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint);
    function devWallet1() external view returns (address);
    function devWallet2() external view returns (address);
    function lpWallet() external view returns (address);
    function balanceOf(address) external returns(uint);
    function transfer(address, uint) external returns(bool);
    function transferFrom(address, address, uint) external returns(bool);
    function approve(address, uint) external returns (bool);
}

// Main SILK information
contract SpooderSilk {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "Spooder Silk";
    string public symbol = "SILK";
    uint public decimals = 18;
    uint public totalStaked = 0;
    // Tax Wallet
    address public taxWallet = 0x8AdDB7a081589332fAD85Fc7ec82346a592a182b;
    // Staking Wallet
    address public stakeWallet = 0x6041a3C18ca1E5Cbaf4AFE7840c4C61Ada9F45d5;
    // SPOOD Contract address
    address public contractSPOOD = 0xba51A671F55fddCFbb2B470A8619dB528a8Dc558;
    address public contractSILK;
    address[] public userStaked;
    address public user;
    uint public userReward;
    uint public rewardVectorLength = 0;
    
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    event Stake(address indexed from, uint value);
    event UnStake(address indexed to, uint value);
    event UpdateRewards(uint value);
    
    constructor() {
        // Staking Wallet
        balances[stakeWallet] = 100000000 * 10 ** 18;
        contractSILK = address(this);
    }
    // EXECUTE THIS FUNCTION TO STAKE
    function stake(uint value) public returns(bool) {
        // Require stake amount balance of SPOOD
        require(SpooderToken(contractSPOOD).balanceOf(msg.sender) >= value, 'Insuficient Balance');
        // Do not allow the staking wallet to stake or unstake its holdings. In effect to the staking balance, it does nothing as both tokens remain in the wallet, but this does break the reward distribution.
        // Bug ID: InfiniteSILKprinter
        require(msg.sender != stakeWallet,'Staking Wallet Cannot Stake or Unstake Tokens');
        
        // approve contract address for staking value on user wallet first
        
        // Transfer SPOOD to Staking Wallet
        SpooderToken(contractSPOOD).transferFrom(msg.sender, stakeWallet, value);
        // Transfer SILK to user
        balances[msg.sender] += value;
        balances[stakeWallet] -= value;
        // Increase total staked
        totalStaked += value;
        // Make sure address has been added to reward list
        bool stakeCheck = false;
        if (userStaked.length == 0) {
            userStaked.push(msg.sender);
        }
        for (uint i = 0; i < userStaked.length; i++) {
            user = userStaked[i];
            if (user == msg.sender) {
                stakeCheck = true;
                break;
            }
        }
        if (stakeCheck == false) {
            // Put new address at end
            userStaked.push(msg.sender);
        }
        emit Stake(msg.sender, value);
        return true;
    }
    
    // EXECUTE THIS FUNCTION TO UNSTAKE
    function unstake(uint value) public returns(bool) {
        // Require unstake amount balance of SILK
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        // Do not allow the staking wallet to stake or unstake its holdings. In effect to the staking balance, it does nothing as both tokens remain in the wallet, but this does break the reward distribution.
        require(msg.sender != stakeWallet,'Staking Wallet Cannot Stake or Unstake Tokens');
        
        // approve contract address on SPOOD stake wallet after deployment
        
        // Trasnfer SPOOD to user
        SpooderToken(contractSPOOD).transferFrom(stakeWallet, msg.sender, value);
        // Transfer SILK to Staking Wallet
        balances[stakeWallet] += value;
        balances[msg.sender] -= value;
        // Decrease total staked
        totalStaked -= value;
        emit UnStake(msg.sender, value);
        return true;
    }
    
    // EXECUTE THIS FUNCTION TO SEND SPOOD FROM TAX WALLET AND DISRIBUTE
    // CALL FROM TAX WALLET - STAKE WALLET CONNECTION CONTRACT
    function updateRewards(uint value) public returns(bool) {
        require(msg.sender == taxWallet,'Only the Tax Wallet can distribute staking rewards');
        rewardVectorLength = userStaked.length;
        require(rewardVectorLength > 0,'No Stakers');
        
        // approve contract address for SPOOD transfer value from tax wallet first
        
        // Transfer SPOOD from tax wallet to staking wallet
        SpooderToken(contractSPOOD).transferFrom(taxWallet, stakeWallet, value);
        
        // Distribute rewards through SILK
        for (uint i = 0; i < rewardVectorLength; i++) {
            // Calculate percantage of reward per wallet
            user = userStaked[i];
            userReward = uint(value*balanceOf(user)/totalStaked);
            // Transfer SILK to user
            balances[user] += userReward;
            balances[stakeWallet] -= userReward;
            // Increase total staked
            totalStaked += userReward;
        }
        emit UpdateRewards(value);
        return true;
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // FOR FUTURE USE - IF SPOOD 10% MAX WALLET LIMITS ADDITIONAL STAKING
    // Probably will never have to use
    function addStakeWallet(address to, uint value) public returns(bool) {
        require(msg.sender == stakeWallet,'Only the Staking Wallet can create additional staking wallets');
        // Transfer SPOOD between Staking Wallets
        SpooderToken(contractSPOOD).transferFrom(stakeWallet, to, value);
        return true;
    }
    function removeStakeWallet(address from, uint value) public returns(bool) {
        require(msg.sender == stakeWallet,'Only the Staking Wallet can remove additional staking wallets');
        // Transfer SPOOD between Staking Wallets
        // approve contract address for SPOOD transfer value from additional staking wallet first
        SpooderToken(contractSPOOD).transferFrom(from, stakeWallet, value);
        return true;
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        // Only allow transfers between Staking Wallet and user, no user to user transfers.
        if (msg.sender != stakeWallet) {
            require(to == stakeWallet,'You can only send SILK to and from the SPOOD Staking Wallet');
        }
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        // Only allow transfers between Staking Wallet and user, no user to user transfers.
        if (from != stakeWallet) {
            require(to == stakeWallet,'You can only send SILK to and from the SPOOD Staking Wallet');
        }
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}