/**
 *Submitted for verification at polygonscan.com on 2021-08-04
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/proxy/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/interfaces/IFarmV2.sol


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

interface IFarmV2 {

    function initialize() external;
    function withdrawRewards(uint256 amount) external;
    function FarmFactory() external view returns(address);
    function init(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external; 
    function pendingReward(address _user) external view returns (uint256);

    function userInfo(address user) external view returns (UserInfo memory);
    function farmInfo() external view returns (FarmInfo memory);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    
}


// File contracts/DeFi/FarmFactory.sol






contract FarmFactory is Ownable{

    address public FarmImplementation;
    mapping(bytes32 => bool) FarmValid;
    mapping(address => mapping(address => mapping(uint => address))) public getFarm;
    mapping(address => mapping(address => uint)) public getFarmIndex;
    mapping(address => mapping(address => uint)) public farmVersion;
    address[] public allFarms;
    mapping(address => bool) public whitelist;
    address public governance;
    address public incinerator;
    uint public harvestFee; // number between 0->5
    address public gfi;
    address public feeManager;
    

    /**
    * @dev emitted when owner changes the whitelist
    * @param _address the address that had its whitelist status changed
    * @param newBool the new state of the address
    **/
    event whiteListChanged(address _address, bool newBool);

    /**
    * @dev emitted when a farm is created
    * @param farmAddress the address of the new farm
    * @param fid the farm ID of the new farm
    **/
    event FarmCreated(address farmAddress, uint fid, uint start, uint end);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Caller is not in whitelist!");
        _;
    }

    constructor(address _gfi, address _governance) {
        FarmImplementation = address(new FarmV2());
        gfi = _gfi;
        governance = _governance;
    }

    function adjustWhitelist(address _address, bool _bool) external onlyOwner {
        whitelist[_address] = _bool;
        emit whiteListChanged(_address, _bool);
    }

    function setHarvestFee(uint _fee) external onlyOwner{
        require(_fee <= 5, "New fee can not be greater than 5%");
        require(_fee >= 0, "New fee must be greater than or equal to 0");
        harvestFee = _fee;
    }

    function setIncinerator(address _incinerator) external onlyOwner{
        incinerator = _incinerator;
    }

    function setFeeManager(address _feeManager) external onlyOwner{
        feeManager = _feeManager;
    }

    function setGovernance(address _governance) external onlyOwner{
        governance = _governance;
    }

    /**
    * @dev allows caller to create farm as long as parameters are approved by factory owner
    * Creates a clone of FarmV2 contract, so that farm creation is cheap
    **/
    function createFarm(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external {
        //check if caller is on whitelist, used by IDO factory
        if(!whitelist[msg.sender]){
            //require statement to see if caller is able to create farm with given inputs
            bytes32 _hash = _getFarmHash(msg.sender, depositToken, rewardToken, amount, blockReward, start, end, bonusEnd, bonus);
            require(FarmValid[_hash], "Farm parameters are not valid!");
            FarmValid[_hash] = false; //Revoke so caller can not call again
        }

        //Create the clone proxy, and add it to the getFarm mappping, and allFarms array
        farmVersion[depositToken][rewardToken] = farmVersion[depositToken][rewardToken] + 1;
        bytes32 salt = keccak256(abi.encodePacked(depositToken, rewardToken, farmVersion[depositToken][rewardToken]));
        address farmClone = Clones.cloneDeterministic(FarmImplementation, salt);
        getFarm[depositToken][rewardToken][farmVersion[depositToken][rewardToken]] = farmClone;
        getFarmIndex[depositToken][rewardToken] = allFarms.length;
        allFarms.push(farmClone);
        //Fund the farm
        require(IERC20(rewardToken).transferFrom(msg.sender, address(farmClone), amount), "Failed to transfer tokens to back new farm");
        
        //Init the newly created farm
        IFarmV2(farmClone).initialize();
        IFarmV2(farmClone).init(depositToken, rewardToken, amount, blockReward, start, end, bonusEnd, bonus);
        emit FarmCreated(farmClone, getFarmIndex[depositToken][rewardToken], start, end);
    }

    function _getFarmHash(address from, address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) internal pure returns(bytes32 _hash){
        _hash = keccak256(abi.encodePacked(from, depositToken, rewardToken, amount, blockReward, start, end, bonusEnd, bonus));
    }

    function approveOrRevokeFarm(bool status, address from, address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external onlyOwner{
        bytes32 _hash = keccak256(abi.encodePacked(from, depositToken, rewardToken, amount, blockReward, start, end, bonusEnd, bonus));
        FarmValid[_hash] = status;
    }

}