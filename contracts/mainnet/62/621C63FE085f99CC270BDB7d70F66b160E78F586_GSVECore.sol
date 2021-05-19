/*
GAS SAVE PROTOCOL - $GSVE TOKEN!
████████████████████████████████████████████████████████████
███████████████████████▀▀▀▀▀▀▀▀▀▀▀▀▀▀███████████████████████
████████████████▀▀░░░░░░░░░░░░░░░░░░░░░░░░▀▀▀███████████████
██████████████░▄░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄░██████████████
██████████████▄░▀▀░░░▄▄▄░░░░░░░░░░░░░▄▄░░░▀▀▄░██████████████
███████████████░░░▀▀░░░░▄▄▄▄▄▄▄▄▄▄▄▄▄▄░░▀▀░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
██████████████░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
██████████████▄░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░▀▀░░▄▄▄▄░░░░░░░▀░░░░░▄▄▄░░▀▀░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
██████████████▀░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
██████████████░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░▄▄░░░░░░░░░░░░▄█░░░░░░░░░░▄▄░░██████████████
███████████████░░░░░▀▀▀▀░░░░░░▄▄░░░░▀▀▀▀░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░▄█░░░░▄░░░░░░░░░██████████████
███████████████░░░░░░░░░░░░░░░██░░░░█░░░░░░░░░██████████████
██████████████░░░░░░░░░░░░░░░░██░░░░█░░░░░░░░░██████████████
██████████████▄░░░░░░░░░░░░░░░██░░░░█░░░░░░░░░██████████████
█████████████████▄▄▄░░░░░░░░░░░░░░░░░░░░░▄▄▄████████████████
██████████████████████████████▄▄▄▄██████████████████████████
████████████████████████████████████████████████████████████
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev Interface of the wrapped Gas Token Type
 */
interface IGasTokenMint {
    function mint(uint256 value) external; 
    function discountedMint(uint256 value, uint256 discountedFee, address recipient) external; 
}


/**
* @dev Interface for interacting with protocol token
*/
interface IGSVEProtocolToken {
    function burn(uint256 amount) external ;
    function burnFrom(address account, uint256 amount) external;
}

/**
* @dev Interface for interacting with the gas vault
*/
interface IGSVEVault {
    function transferToken(address token, address recipient, uint256 amount) external;
}

contract GSVECore is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    
    //address of our protocol utility token
    address private GSVEToken;
    address private GSVEVault;

    //system is in place to prevent reentrancy from untrusted tokens
    mapping(address => uint256) private _mintingType;
    mapping(address => bool) private _claimable;

    uint256 private _totalStaked;

    //staking  
    mapping(address => uint256) private userStakes;
    mapping(address => uint256) private userStakeTimes;
    mapping(address => uint256) private userTotalRewards;
    mapping(address => uint256) private userClaimTimes;

    //protocol values
    mapping(uint256=>uint256) private tierThreshholds;
    uint256 rewardEnableTime;

    bool rewardsEnabled = false;
    uint256 burnToSaveFee = 25*10**16;
    uint256 burnToClaimGasTokens = 1*10**17;
    uint256 mintingReward = 5*10**17;


    /**
     * @dev A function that enables protocol rewards
     */
    function enableRewards() public onlyOwner {
        require(rewardsEnabled == false, "GSVE: Rewards already enabled");
        rewardsEnabled = true;
        rewardEnableTime = block.timestamp;
        emit protocolUpdated(0x656e61626c655570646174650000000000000000000000000000000000000000, 1);
    }

    /**
    * @dev A function that disables rewards
    */
    function disableRewards() public onlyOwner {
        require(rewardsEnabled, "GSVE: Rewards not already enabled");
        rewardsEnabled = false;
        rewardEnableTime = 0;
        emit protocolUpdated(0x656e61626c655570646174650000000000000000000000000000000000000000, 0);
    }

    /**
     * @dev A function that allows us to update the tier threshold
     */
    function updateTier(uint256 tier, uint256 value) public onlyOwner {
        require(value > 10**18, "GSVE: Tier value seems to be low.");
        tierThreshholds[tier] = value;
        emit TierUpdate(tier, value);
    }

    /**
     * @dev A function that allows us to update the burn gsve:save fee ratio
     */
    function updateBurnSaveFee(uint256 value) public onlyOwner{
        require(value > 10**17, "GSVE: Value seems to be low.");
        burnToSaveFee = value;
        emit protocolUpdated(0x6275726e00000000000000000000000000000000000000000000000000000000, value);
    }

    /**
     * @dev A function that allows us to update the burn gsve:claim gastoken ratio
     */
    function updateBurnClaimFee(uint256 value) public onlyOwner{
        require(value > 10**17, "GSVE: Value seems to be low.");
        burnToClaimGasTokens= value;
        emit protocolUpdated(0x636c61696d000000000000000000000000000000000000000000000000000000, value);
    }

    /**
     * @dev A function that allows us to update the burn gsve:claim gastoken ratio
     */
    function updateMintingReward(uint256 value) public onlyOwner{
        require(value > 10**17, "GSVE: Value seems to be low.");
        mintingReward = value;
        emit protocolUpdated(0x6d696e74696e6700000000000000000000000000000000000000000000000000, value);
    }

    /**
     * @dev A function that allows us to reassign ownership of the contracts that this contract owns. 
     /* Enabling future smartcontract upgrades without the complexity of proxy/proxy upgrades.
     */
    function transferOwnershipOfSubcontract(address ownedContract, address newOwner) public onlyOwner{
        Ownable(ownedContract).transferOwnership(newOwner);
    }

    /**
     * @dev the constructor allows us to set the gsve token
     * as the token we are using for staking and other protocol features
     * also lets us set the vault address.
     */
    constructor(address _tokenAddress, address _vaultAddress, address wchi, address wgst2, address wgst1) {
        GSVEToken = _tokenAddress;
        GSVEVault = _vaultAddress;
        tierThreshholds[1] = 250*(10**18);
        tierThreshholds[2] = 1000*(10**18);
        _claimable[_tokenAddress] = false;

        _claimable[0x0000000000004946c0e9F43F4Dee607b0eF1fA1c] = true;
        _mintingType[0x0000000000004946c0e9F43F4Dee607b0eF1fA1c] = 1;

        _claimable[0x0000000000b3F879cb30FE243b4Dfee438691c04] = true;
        _mintingType[0x0000000000b3F879cb30FE243b4Dfee438691c04] = 1;

        _claimable[0x88d60255F917e3eb94eaE199d827DAd837fac4cB] = true;
        _mintingType[0x88d60255F917e3eb94eaE199d827DAd837fac4cB] = 1;
        

        _claimable[wchi] = true;
        _mintingType[wchi] = 2;

        _claimable[wgst2] = true;
        _mintingType[wgst2] = 2;

        _claimable[wgst1] = true;
        _mintingType[wgst1] = 2;
    }

    /**
     * @dev A function that allows a user to stake tokens. 
     * If they have a rewards from a stake already, they must claim this first.
     */
    function stake(uint256 value) public nonReentrant() {

        if (value == 0){
            return;
        }
        require(IERC20(GSVEToken).transferFrom(msg.sender, address(this), value));
        userStakes[msg.sender] = userStakes[msg.sender].add(value);
        userStakeTimes[msg.sender] = block.timestamp;
        userClaimTimes[msg.sender] = block.timestamp;
        _totalStaked = _totalStaked.add(value);
        emit Staked(msg.sender, value);
    }

    /**
     * @dev A function that allows a user to fully unstake.
     */
    function unstake() public nonReentrant() {
        uint256 stakeSize = userStakes[msg.sender];
        if (stakeSize == 0){
            return;
        }
        userStakes[msg.sender] = 0;
        userStakeTimes[msg.sender] = 0;
        userClaimTimes[msg.sender] = 0;
        _totalStaked = _totalStaked.sub(stakeSize);
        require(IERC20(GSVEToken).transfer(msg.sender, stakeSize));
        emit Unstaked(msg.sender, stakeSize);
    }

    /**
     * @dev A function that allows us to calculate the total rewards a user has not claimed yet.
     */
    function calculateStakeReward(address rewardedAddress) public view returns(uint256){
        if(userStakeTimes[rewardedAddress] == 0){
            return 0;
        }

        if(rewardsEnabled == false){
            return 0;
        }

        uint256 initialTime = Math.max(userStakeTimes[rewardedAddress], rewardEnableTime);
        uint256 timeDifference = block.timestamp.sub(initialTime);
        uint256 rewardPeriod = timeDifference.div((60*60*6));
        uint256 rewardPerPeriod = userStakes[rewardedAddress].div(4000);
        uint256 reward = rewardPeriod.mul(rewardPerPeriod);

        return reward;
    }

    /**
     * @dev A function that allows a user to collect the stake reward entitled to them
     * in the situation where the rewards pool does not have enough tokens
     * then the user is given as much as they can be given.
     */
    function collectReward() public nonReentrant() {
        uint256 remainingRewards = totalRewards();
        require(remainingRewards > 0, "GSVE: contract has ran out of rewards to give");
        require(rewardsEnabled, "GSVE: Rewards are not enabled");

        uint256 reward = calculateStakeReward(msg.sender);
        if(reward == 0){
            return;
        }

        reward = Math.min(remainingRewards, reward);
        userStakeTimes[msg.sender] = block.timestamp;
        userTotalRewards[msg.sender] = userTotalRewards[msg.sender] + reward;
        IGSVEVault(GSVEVault).transferToken(GSVEToken, msg.sender, reward);
        emit Reward(msg.sender, reward);
    }

    /**
     * @dev A function that allows a user to burn some GSVE to avoid paying the protocol mint/wrap fee.
     */
    function burnDiscountedMinting(address gasTokenAddress, uint256 value) public nonReentrant() {
        uint256 mintType = _mintingType[gasTokenAddress];
        require(mintType != 0, "GSVE: Unsupported Token");
        IGSVEProtocolToken(GSVEToken).burnFrom(msg.sender, burnToSaveFee);

        if(mintType == 1){
            convenientMinting(gasTokenAddress, value, 0);
        }
        else if (mintType == 2){
            IGasTokenMint(gasTokenAddress).discountedMint(value, 0, msg.sender);
        }
    }

    /**
     * @dev A function that allows a user to benefit from a lower protocol fee, based on the stake that they have.
     */
    function discountedMinting(address gasTokenAddress, uint256 value) public nonReentrant(){
        uint256 mintType = _mintingType[gasTokenAddress];
        require(mintType != 0, "GSVE: Unsupported Token");
        require(userStakes[msg.sender] >= tierThreshholds[1] , "GSVE: User has not staked enough to discount");

        if(mintType == 1){
            convenientMinting(gasTokenAddress, value, 1);
        }
        else if (mintType == 2){
            IGasTokenMint(gasTokenAddress).discountedMint(value, 1, msg.sender);
        }
    }
    
    /**
     * @dev A function that allows a user to be rewarded tokens by minting or wrapping
     * they pay full fees for this operation.
     */
    function rewardedMinting(address gasTokenAddress, uint256 value) public nonReentrant(){
        uint256 mintType = _mintingType[gasTokenAddress];
        require(mintType != 0, "GSVE: Unsupported Token");
        require(totalRewards() > 0, "GSVE: contract has ran out of rewards to give");
        require(rewardsEnabled, "GSVE: Rewards are not enabled");
        if(mintType == 1){
            convenientMinting(gasTokenAddress, value, 2);
        }
        else if (mintType == 2){
            IGasTokenMint(gasTokenAddress).discountedMint(value, 2, msg.sender);
        }

        IGSVEVault(GSVEVault).transferToken(GSVEToken, msg.sender, mintingReward);
    }

    /**
     * @dev A function that allows us to mint non-wrapped tokens from the convenience of this smart contract.
     * taking a portion of portion of the minted tokens as payment for this convenience.
     */
    function convenientMinting(address gasTokenAddress, uint256 value, uint256 fee) internal {
        uint256 mintType = _mintingType[gasTokenAddress];
        require(mintType == 1, "GSVE: Unsupported Token");

        uint256 userTokens = value.sub(fee);
        require(userTokens > 0, "GSVE: User attempted to mint too little");
        IGasTokenMint(gasTokenAddress).mint(value);
        IERC20(gasTokenAddress).transfer(msg.sender, userTokens);
        if(fee > 0){
            IERC20(gasTokenAddress).transfer(GSVEVault, fee);
        }
    }

    
    /**
     * @dev public entry to the convenient minting function
     */
    function mintGasToken(address gasTokenAddress, uint256 value) public {
        convenientMinting(gasTokenAddress, value, 2);
    }


    /**
     * @dev A function that allows a user to claim tokens from the pool
     * The user burns 1 GSVE for each token they take.
     * They are limited to one claim action every 6 hours, and can claim up to 5 tokens per claim.
     */
    function claimToken(address gasTokenAddress, uint256 value) public nonReentrant() {

        bool isClaimable = _claimable[gasTokenAddress];
        require(isClaimable, "GSVE: Token not claimable");
        require(userStakes[msg.sender] >= tierThreshholds[2] , "GSVE: User has not staked enough to claim from the pool");
        require(block.timestamp.sub(userClaimTimes[msg.sender]) > 60 * 60 * 6, "GSVE: User cannot claim the gas tokens twice in 6 hours");

        uint256 tokensGiven = value;

        uint256 tokensAvailableToClaim = IERC20(gasTokenAddress).balanceOf(GSVEVault);
        tokensGiven = Math.min(Math.min(5, tokensAvailableToClaim), tokensGiven);

        if(tokensGiven == 0){
            return;
        }

        IGSVEProtocolToken(GSVEToken).burnFrom(msg.sender, tokensGiven * burnToClaimGasTokens);
        IGSVEVault(GSVEVault).transferToken(gasTokenAddress, msg.sender, tokensGiven);
        userClaimTimes[msg.sender] = block.timestamp;
        emit Claimed(msg.sender, gasTokenAddress, tokensGiven);
    }

    /**
     * @dev A function that allows us to enable gas tokens for use with this contract.
     */
    function addGasToken(address gasToken, uint256 mintType, bool isClaimable) public onlyOwner{
        _mintingType[gasToken] = mintType;
        _claimable[gasToken] = isClaimable;
    }

    /**
     * @dev A function that allows us to easily check claim type of the token.
     */
    function claimable(address gasToken) public view returns (bool){
        return _claimable[gasToken];
    }

    /**
     * @dev A function that allows us to check the mint type of the token.
     */
    function mintingType(address gasToken) public view returns (uint256){
        return _mintingType[gasToken];
    }

    /**
     * @dev A function that allows us to see the total stake of everyone in the protocol.
     */
    function totalStaked() public view returns (uint256){
        return _totalStaked;
    }

    /**
     * @dev A function that allows us to see the stake size of a specific staker.
     */
    function userStakeSize(address user)  public view returns (uint256){
        return userStakes[user]; 
    }

    /**
     * @dev A function that allows us to see how much rewards the vault has available right now.
     */    
     function totalRewards()  public view returns (uint256){
        return IERC20(GSVEToken).balanceOf(GSVEVault); 
    }

    /**
     * @dev A function that allows us to see how much rewards a user has claimed
     */
    function totalRewardUser(address user)  public view returns (uint256){
        return userTotalRewards[user]; 
    }

    /**
    * @dev A function that allows us to get a tier threshold
    */
    function getTierThreshold(uint256 tier)  public view returns (uint256){
        return tierThreshholds[tier];
    }

    /**
    * @dev A function that allows us to get the time rewards where enabled
    */
    function getRewardEnableTime()  public view returns (uint256){
        return rewardEnableTime;
    }

    /**
    * @dev A function that allows us to get the time rewards where enabled
    */
    function getRewardEnabled()  public view returns (bool){
        return rewardsEnabled;
    }

    /**
    * @dev A function that allows us to get the burnToSaveFee 
    */
    function getBurnToSaveFee()  public view returns (uint256){
        return burnToSaveFee;
    }

    /**
    * @dev A function that allows us to get the burnToClaimGasTokens 
    */
    function getBurnToClaimGasTokens()  public view returns (uint256){
        return burnToClaimGasTokens;
    }

    /**
    * @dev A function that allows us to get the burnToClaimGasTokens 
    */
    function getMintingReward()  public view returns (uint256){
        return mintingReward;
    }

    /**
    * @dev A function that allows us to get the stake times
    */
    function getStakeTimes(address staker)  public view returns (uint256){
        return userStakeTimes[staker];
    }

    /**
    * @dev A function that allows us to get the claim times
    */
    function getClaimTimes(address staker)  public view returns (uint256){
        return userClaimTimes[staker];
    }
    
    event Claimed(address indexed _from, address indexed _token, uint256 _value);

    event Reward(address indexed _from, uint256 _value);

    event Staked(address indexed _from, uint256 _value);

    event Unstaked(address indexed _from, uint256 _value);

    event TierUpdate(uint256 _tier, uint256 _value);

    event protocolUpdated(bytes32 _type, uint256 _value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}