/**
 *Submitted for verification at polygonscan.com on 2021-08-04
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/interfaces/iGovernance.sol



interface iGovernance {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function delegateFee(address reciever) external returns (uint256);

    function claimFee() external returns (uint256);

    function tierLedger(address user, uint index) external returns(uint);

    function depositFee(uint256 amountWETH, uint256 amountWBTC) external;

    function Tiers(uint index) external returns(uint);
}


// File contracts/interfaces/IFarmFactory.sol



interface IFarmFactory {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function getFarm(address depositToken, address rewardToken, uint version) external view returns (address farm);
    function getFarmIndex(address depositToken, address rewardToken) external view returns (uint fID);

    function whitelist(address _address) external view returns (bool);
    function governance() external view returns (address);
    function incinerator() external view returns (address);
    function harvestFee() external view returns (uint);
    function gfi() external view returns (address);
    function feeManager() external view returns (address);
    function allFarms(uint fid) external view returns (address); 
    function createFarm(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external;
    function farmVersion(address deposit, address reward) external view returns(uint);
}


// File contracts/interfaces/IIncinerator.sol



interface IIncinerator {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function convertEarningsToGFIandBurn() external;
}


// File contracts/interfaces/iGravityToken.sol


interface iGravityToken is IERC20 {

    function setGovernanceAddress(address _address) external;

    function changeGovernanceForwarding(bool _bool) external;

    function burn(uint256 _amount) external returns (bool);
}


// File @openzeppelin/contracts/proxy/utils/[email protected]


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/DeFi/FarmV2.sol







contract FarmV2 is Initializable{
    address public FarmFactory;
    IFarmFactory FARMFACTORY;
    bool public initCalled;
    
    
    struct UserInfo {
        uint256 amount;     // LP tokens provided.
        uint256 rewardDebt; // Reward debt.
    }

    struct FarmInfo {
        IERC20 lpToken;
        IERC20 rewardToken;
        uint startBlock;
        uint blockReward;
        uint bonusEndBlock;
        uint bonus;
        uint endBlock;
        uint lastRewardBlock;  // Last block number that reward distribution occurs.
        uint accRewardPerShare; // rewards per share, times 1e12
        uint farmableSupply; // total amount of tokens farmable
        uint numFarmers; // total amount of farmers
    }

    FarmInfo public farmInfo;
    mapping (address => UserInfo) public userInfo;

    uint256 public totalStakedAmount; 
    
    modifier onlyFactory() {
        require(msg.sender == FarmFactory);
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    function initialize() external initializer{
        FarmFactory = msg.sender;
        FARMFACTORY = IFarmFactory(FarmFactory);
    }

    /**
     * @dev initialize farming contract, should be called only once
     * @param rewardToken token to be rewarded to the user (GFI)
     * @param amount amount of tokens to be farmed in total
     * @param depositToken ERC20 compatible (lp) token used for farming
     * @param blockReward token rewards per blockReward
     * @param start blocknumber to start farming
     * @param end blocknumber to stop farming
     * @param bonusEnd blocknumber to stop the bonus period
     * @param bonus bonus amount
     */
    function init(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) public onlyFactory {
        require(!initCalled, 'Gravity Finance: Init already called');
        require(IERC20(rewardToken).balanceOf(address(this)) >= amount, "Farm does not have enough reward tokens to back initialization");
        IERC20 rewardT = IERC20(rewardToken);
        IERC20 lpT = IERC20(depositToken);
        farmInfo.rewardToken = rewardT;
        
        farmInfo.startBlock = start;
        farmInfo.blockReward = blockReward;
        farmInfo.bonusEndBlock = bonusEnd;
        farmInfo.bonus = bonus;
        
        uint256 lastRewardBlock = block.number > start ? block.number : start;
        farmInfo.lpToken = lpT;
        farmInfo.lastRewardBlock = lastRewardBlock;
        farmInfo.accRewardPerShare = 0;
        
        farmInfo.endBlock = end;
        farmInfo.farmableSupply = amount;
        initCalled = true;
    }

    /**
     * @dev Gets the reward multiplier over the given _from_block until _to block
     * @param _from_block the start of the period to measure rewards for
     * @param _to the end of the period to measure rewards for
     * @return The weighted multiplier for the given period
     */
    function getMultiplier(uint256 _from_block, uint256 _to) public view returns (uint256) {
        uint256 _from = _from_block >= farmInfo.startBlock ? _from_block : farmInfo.startBlock;
        uint256 to = farmInfo.endBlock > _to ? _to : farmInfo.endBlock;
        if (to <= farmInfo.bonusEndBlock) {
            return (to - _from)* farmInfo.bonus;
        } else if (_from >= farmInfo.bonusEndBlock) {
            return to - _from;
        } else {
            return (farmInfo.bonusEndBlock -_from)*farmInfo.bonus + (to - farmInfo.bonusEndBlock);
        }
    }

    /**
     * @dev get pending reward token for address
     * @param _user the user for whom unclaimed tokens will be shown
     * @return total amount of withdrawable reward tokens
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = farmInfo.accRewardPerShare;
        uint256 lpSupply = totalStakedAmount;
        if (block.number > farmInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(farmInfo.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier * farmInfo.blockReward;
            accRewardPerShare = accRewardPerShare + (tokenReward * 1e12)/lpSupply;
        }
        return (user.amount * accRewardPerShare)/1e12 - user.rewardDebt;
    }

    /**
     * @dev updates pool information to be up to date to the current block
     */
    function updatePool() public {
        if (block.number <= farmInfo.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = totalStakedAmount;
        if (lpSupply == 0) {
            farmInfo.lastRewardBlock = block.number < farmInfo.endBlock ? block.number : farmInfo.endBlock;
            return;
        }
        uint256 multiplier = getMultiplier(farmInfo.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier * farmInfo.blockReward;
        farmInfo.accRewardPerShare = farmInfo.accRewardPerShare + (tokenReward * 1e12)/lpSupply;
        farmInfo.lastRewardBlock = block.number < farmInfo.endBlock ? block.number : farmInfo.endBlock;
    }

    /**
     * @dev deposit LP token function for msg.sender
     * @param _amount the total deposit amount
     */
    function deposit(uint256 _amount) public {
        require(farmInfo.startBlock <= block.number, 'Gravity Finance: Farming has not started!');
        require(farmInfo.endBlock >= block.number, 'Gravity Finance: Farming has ended!');
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) { //first pay out pending rewards if already farming
            uint256 pending = (user.amount * farmInfo.accRewardPerShare)/1e12 - user.rewardDebt;
            if (FARMFACTORY.harvestFee() > 0 && !FARMFACTORY.whitelist(msg.sender)){ //If harvest fee is greater than 0 and caller is not on whitelist remove harvestFee from pending
                uint fee = ( FARMFACTORY.harvestFee() * pending / 100);
                if (address(farmInfo.rewardToken) == FARMFACTORY.gfi()){ //Burn it
                    iGravityToken(FARMFACTORY.gfi()).burn(fee);
                }
                else { //Send it to the fee manager
                    farmInfo.rewardToken.transfer(FARMFACTORY.feeManager(), fee);
                }
                pending = pending - fee;
            }
            safeRewardTransfer(msg.sender, pending);
        }
        if (user.amount == 0 && _amount > 0) { //not farming already -> add farmer to total amount
            farmInfo.numFarmers += 1;
        }
        farmInfo.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        totalStakedAmount = totalStakedAmount + _amount; 
        user.amount += _amount;
        user.rewardDebt = (user.amount * farmInfo.accRewardPerShare)/1e12; //already rewarded tokens
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev withdraw LP token function for msg.sender
     * @param _amount the total withdrawable amount
     */
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Withdrawal request amount exceeds user farming amount");
        updatePool();
        if (user.amount == _amount && _amount > 0) { //withdraw everything -> less farmers
            farmInfo.numFarmers -= 1;
        }
        uint256 pending = (user.amount * farmInfo.accRewardPerShare)/1e12 - user.rewardDebt;
        if (FARMFACTORY.harvestFee() > 0 && !FARMFACTORY.whitelist(msg.sender)){ //If harvest fee is greater than 0 and caller is not on whitelist remove harvestFee from pending
            uint fee = ( FARMFACTORY.harvestFee() * pending / 100);
            if (address(farmInfo.rewardToken) == FARMFACTORY.gfi()){ //Burn it
                iGravityToken(FARMFACTORY.gfi()).burn(fee);
            }
            else { //Send it to the fee manager
                farmInfo.rewardToken.transfer(FARMFACTORY.feeManager(), fee);
            }
            pending = pending - fee;
        }
        safeRewardTransfer(msg.sender, pending);
        user.amount -= _amount;
        user.rewardDebt = (user.amount * farmInfo.accRewardPerShare)/1e12;
        totalStakedAmount = totalStakedAmount - _amount; 
        farmInfo.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @dev function to withdraw LP tokens and forego harvest rewards. Important to protect users LP tokens
     */
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        totalStakedAmount = totalStakedAmount - _amount; 
        if (_amount > 0) {
            farmInfo.numFarmers -= 1;
        }
        farmInfo.lpToken.transfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    /**
     * @dev Safe reward transfer function, just in case a rounding error causes pool to not have enough reward tokens
     * @param _to the user address to transfer tokens to
     * @param _amount the total amount of tokens to transfer
     */
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = farmInfo.rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            farmInfo.rewardToken.transfer(_to, rewardBal);
        } else {
            farmInfo.rewardToken.transfer(_to, _amount);
        }
    }

    /** 
    * @dev callable by anyone, will send the Farms wETH earnigns to the incinerator contract so they can be swapped into GFI and burned
    **/
    function sendEarningsToIncinerator() external{
        address gfi = FARMFACTORY.gfi();
        require(address(farmInfo.rewardToken) == gfi || address(farmInfo.lpToken) == gfi, "Reward token or Deposit token must be GFI");
        require(FARMFACTORY.incinerator() != address(0), "Incinerator can't be Zero Address!");
        iGovernance(FARMFACTORY.governance()).delegateFee(FARMFACTORY.incinerator());
        IIncinerator(FARMFACTORY.incinerator()).convertEarningsToGFIandBurn();
    }

}