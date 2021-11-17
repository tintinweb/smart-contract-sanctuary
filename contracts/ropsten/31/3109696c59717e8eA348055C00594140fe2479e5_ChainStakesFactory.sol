// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import  "./ChainStakePoolFactory.sol";
import "./common/Ownable.sol";

 contract ChainStakesFactory is Ownable{ 

//struct to store deployed Factory details;
        struct Factory{
            address owner;
            address subAdmin;
            address factoryAddress;
            address rewardToken;
            uint256 rewardTokenPerBlock;
            uint256 initBlock;
            uint256 totalRewardSupply;
            uint256 vestingWindow;
        }

//Array hold the deployed factory information.
    Factory[] public factoryArray;

//Mapping factory address with factory Information
    mapping(address=>Factory) public FactoryInfo ;

 /**
     * @dev Fired in deploySmartContract
     *
     * @param _owner an address which performed an operation
     * @param _subAdmin subadmin assigned to factory contract being deployed
     * @param factoryAddress deployed factory address
     * @param rewardToken address of reward token
     * @param _rewardTokenPerBlock reward token per block value for factory
     * @param initblock initialblock of deployed contract
     * @param totalRewardSupply total reward supplied to factoryAddress
     * @param vestingWindow vesting window for factory contract

     */
    event DeployedFactoryContract(
        address indexed _owner,
        address indexed _subAdmin, 
        address indexed factoryAddress,
        address rewardToken,
        uint256 _rewardTokenPerBlock,
        uint256 initblock,
        uint256 totalRewardSupply,
        uint256  vestingWindow

    );


   constructor (){
       //set owner
       Ownable.init(msg.sender);
   }

  

/** 
* @dev deploy ChainStakePoolFactory
     *
     * @param _owner an address which performed an operation
     * @param _subAdmin subadmin assigned to factory contract being deployed
     * @param _rewardToken address of reward token
     * @param _rewardTokenPerBlock reward token per block value for factory
     * @param _initBlock initialblock of deployed contract
     * @param _totalRewardSupply total reward supplied to factoryAddress
     * @param _vestingWindow vesting window for factory contract
*/
     
     
     
function deploySmartContract(
    address _owner,
  address _rewardToken,
      address _subAdmin,
 uint256 _rewardTokenPerBlock,
 uint256 _initBlock,
 uint256 _totalRewardSupply,
 uint256 _vestingWindow
 ) public  onlyOwner returns(address){
 ChainStakePoolFactory _factoryAddress = new ChainStakePoolFactory(
            _owner,
            _rewardToken,
            _subAdmin,
            _rewardTokenPerBlock,
            _initBlock,
            _totalRewardSupply,
            _vestingWindow

        );

        // register it within a factory
        Factory memory newFactory = Factory({
              owner:_owner,
              subAdmin: _subAdmin,
              factoryAddress: address(_factoryAddress),
              rewardToken: _rewardToken,
              rewardTokenPerBlock:_rewardTokenPerBlock,
              initBlock:_initBlock,
              totalRewardSupply:_totalRewardSupply,
              vestingWindow:_vestingWindow
        });

// add new Factory to array;        
         factoryArray.push(newFactory);

//mapping factoryaddress with Factory
     FactoryInfo[address(_factoryAddress)]=newFactory;

  emit DeployedFactoryContract( _owner, _subAdmin,  address(_factoryAddress),
   _rewardToken, _rewardTokenPerBlock,_initBlock,_totalRewardSupply,_vestingWindow
    );

    return address(_factoryAddress);

}

  /**
     * @dev provide length of factoryArray
     */
function factoryLength() public view returns(uint256){
          return factoryArray.length ;   
          
          }

  /**
     * @dev provide information of factory of specific index
     *
     * @param _index index of Array
     */
function getFactory(uint256 _index) public view returns(Factory memory){

return factoryArray[_index];

          }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./common/Ownable.sol";
import "./interface/IPool.sol";
import "./ChainStakeCorePool.sol";

/**
 * @title ChainStake Pool Factory
 *
 * @notice RewardToken Pool Factory manages ChainStake Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_CREATOR permission on the RewardToken token to mint yield
 *      (see `mintYieldTo` function)
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
contract ChainStakePoolFactory is Ownable {
    using SafeMath for uint256;

    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like RewardToken)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for RewardToken pools, 800 for RewardToken/ETH pools - set during deployment)
        uint256 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    /// poolInfo List of all pools
    struct PoolInfo {
        // @dev Pool Info address
        address poolAddress;
        // @dev pool token address (like RewardToken)
        address poolToken;
    }

    /// PoolInfo
    PoolInfo[] public poolInfo;

    /**
     * @dev RewardToken/block determines yield farming reward base
     *      used by the yield pools controlled by the factory
     */
    uint256 public rewardTokenPerBlock;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion
     */
    uint256 public totalWeight;

    /**
     * @dev Counts the total number of staked done on platform
     *        Increases by 1 everytimes when user stake token
     */
    uint256 public totalStakedCount;

    /// rewardToken token address
    address public rewardToken;

    /// total reward supply to pool factory
    uint256 public totalRewardSupply;

    /**
     * @dev End block is the last block when RewardToken/block can be decreased;
     *      it is implied that yield farming stops after that block
     */
    uint256 public endBlock;

    // vesting Window Period
    uint256 public vestingWindow;

    //reward transferred to factory address or not;
    bool public isReward =false;
    
    // add  subadmins 
    mapping(address => bool) public isSubAdmin;
    
    /**
     * @dev Each time the RewardToken/block ratio gets updated, the block number
     *      when the operation has occurred gets recorded into `lastRatioUpdate`
     * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
     *      has passed when decreasing yield reward by 3%
     */
    uint256 public lastRatioUpdate;

    /// @dev Maps pool token address (like RewardToken) -> pool address (like core pool instance)
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
    mapping(address => bool) public poolExists;

    /**
     * @dev Fired in createPool() and registerPool()
     *
     * @param _by an address which executed an action
     * @param poolToken pool token address (like RewardToken)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     * @param isFlashPool flag indicating if pool is a flash pool
     */
    event PoolRegistered(
        address indexed _by,
        address indexed poolToken,
        address indexed poolAddress,
        uint256 weight,
        bool isFlashPool
    );

    /**
     * @dev Fired in changePoolWeight()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event WeightUpdated(
        address indexed _by,
        address indexed poolAddress,
        uint256 weight
    );

    /**
     * @dev Fired in updateRewardTokenPerBlock()
     *
     * @param _by an address which executed an action
     * @param newRewardTokenPerBlock new RewardToken/block value
     */
    event RewardTokenRatioUpdated(
        address indexed _by,
        uint256 newRewardTokenPerBlock
    );

    /**
     * @dev Fired in updateRewardTokenPerBlock()
     *
     * @param _by an address which executed an action
     * @param _blockAdded new endblock value
     * @param _addedReward reward added to total reward supply which will increase the endblock
     */
    event UpdateEndBlock(
        address indexed _by,
        uint256 _blockAdded,
        uint256 _addedReward
    );

    /**
     * @dev Creates/deploys a factory instance
     *
     * @param _rewardToken RewardToken ERC20 token address
     * @param _rewardTokenPerBlock initial RewardToken/block value for rewards
     * @param _initBlock block number to measure _blocksPerUpdate from
     * @param _totalRewardSupply total reward for distribution
     */
    constructor(
        address _owner,
        address _rewardToken,
        address _subAdmin,
        uint256 _rewardTokenPerBlock,
        uint256 _initBlock,
        uint256 _totalRewardSupply,
        uint256 _vestingWindow
    ) {
        // verify the inputs are set
        require(_rewardTokenPerBlock > 0, "RewardToken/block not set");
        require(_initBlock > 0, "init block not set");
        require(
            _totalRewardSupply > _rewardTokenPerBlock,
            "invalid total reward : must be greater than 0"
        );
        
        // set Admins
        Ownable.init(_owner);
        isSubAdmin[_owner] = true;
        isSubAdmin[_subAdmin] = true;
        
        // save the inputs into internal state variables
        rewardTokenPerBlock = _rewardTokenPerBlock;
        lastRatioUpdate = _initBlock;

        uint256 blocks = _totalRewardSupply.div(rewardTokenPerBlock);
        endBlock = _initBlock.add(uint256(blocks));
        totalRewardSupply = _totalRewardSupply;
        rewardToken = _rewardToken;

        vestingWindow = _vestingWindow;
    }



 /**
     * @dev Transfer totalsupply amount to factory address from owner addresss.
     */

     function supplyRewardToken() external onlyOwner {
       require(isReward==false,"Transfer Error : Reward token transfered to factory address");
       IERC20(rewardToken).transferFrom(
             msg.sender,
            address(this),
            uint256(totalRewardSupply)
          ); 
          isReward=true;
     }

    /**
     * @dev update the vestingWindow period .
     *
     * @param _newVestingPeriod an address to query deposit length for
     */
    function updateVestingWindow(uint256 _newVestingPeriod) external onlyOwnerOrSubAdmin {
        // update the vestingWindow period .
        vestingWindow = _newVestingPeriod;
    }
    
    /**
     * @dev update the sub admin status .
     *
     * @param _subAdmin an address of sub admin
     * @param _status an status of sub admin
     */
    function setSubAdmin(address _subAdmin, bool _status) external onlyOwner {
        require(isSubAdmin[_subAdmin] != _status, "Already in same status");
        isSubAdmin[_subAdmin] = _status;
    }

    /**
     * @notice Given a pool token retrieves corresponding pool address
     *
     * @dev A shortcut for `pools` mapping
     *
     * @param poolToken pool token address (like RewardToken) to query pool address for
     * @return pool address for the token specified
     */
    function getPoolAddress(address poolToken) external view returns (address) {
        // read the mapping and return
        return pools[poolToken];
    }

    /**
     * @notice Reads pool information for the pool defined by its pool token address,
     *      designed to simplify integration with the front ends
     *
     * @param _poolToken pool token address to query pool information for
     * @return pool information packed in a PoolData struct
     */
    function getPoolData(address _poolToken)
        public
        view
        returns (PoolData memory)
    {
        // get the pool address from the mapping
        address poolAddr = pools[_poolToken];

        // throw if there is no pool registered for the token specified
        require(poolAddr != address(0), "pool not found");

        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint256 weight = IPool(poolAddr).weight();

        // create the in-memory structure and return it
        return
            PoolData({
                poolToken: poolToken,
                poolAddress: poolAddr,
                weight: weight,
                isFlashPool: isFlashPool
            });
    }

    /**
     * @dev Verifies if `blocksPerUpdate` has passed since last RewardToken/block
     *      ratio update and if RewardToken/block reward can be decreased by 3%
     *
     * @return true if enough time has passed and `updateRewardTokenPerBlock` can be executed
     */
    function shouldUpdateRatio(uint256 _rewardPerBlock)
        public
        view
        returns (bool)
    {
        // if yield farming period has ended
        if (blockNumber() > endBlock) {
            // RewardToken/block reward cannot be updated anymore
            return false;
        }

        // check if _rewardPerBlock > rewardTokenPerBlock
        return _rewardPerBlock > rewardTokenPerBlock;
    }

    /**
     * @dev Creates a core pool (ChainStakeCorePool) and registers it within the factory
     *
     * @dev Can be executed by the pool factory owner only
     *
     * @param poolToken pool token address (like RewardToken, or RewardToken/ETH pair)
     * @param initBlock init block to be used for the pool created
     * @param weight weight of the pool to be created
     */
    function createPool(
        address poolToken,
        uint256 initBlock,
        uint256 weight
    ) external virtual onlyOwner {
        // create/deploy new core pool instance
        IPool pool = new ChainStakeCorePool(
            rewardToken,
            this,
            poolToken,
            initBlock,
            weight
        );

        // register it within a factory
        registerPool(address(pool));
    }

    /**
     * @dev Registers an already deployed pool instance within the factory
     *
     * @dev Can be executed by the pool factory owner only
     *
     * @param poolAddr address of the already deployed pool instance
     */
    function registerPool(address poolAddr) public onlyOwner {
        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint256 weight = IPool(poolAddr).weight();

        // ensure that the pool is not already registered within the factory
        require(
            pools[poolToken] == address(0),
            "this pool is already registered"
        );

        // create pool structure, register it within the factory
        pools[poolToken] = poolAddr;
        poolExists[poolAddr] = true;
        // update total pool weight of the factory
        totalWeight = totalWeight.add(weight);

        poolInfo.push(PoolInfo({poolAddress: poolAddr, poolToken: poolToken}));

        // emit an event
        emit PoolRegistered(
            msg.sender,
            poolToken,
            poolAddr,
            weight,
            isFlashPool
        );
    }

    /**
     * @notice Decreases RewardToken/block reward by 3%, can be executed
     *      no more than once per `blocksPerUpdate` blocks
     */
    function updateRewardTokenPerBlock(uint256 _rewardPerBlock) external onlyOwnerOrSubAdmin {
        // checks if ratio can be updated
        require(shouldUpdateRatio(_rewardPerBlock), "too frequent");

        // update RewardToken/block reward
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            IPool(pool.poolAddress).sync();
        }
        uint256 leftBlocks = endBlock.sub(blockNumber());
        uint256 extraPerBlock = _rewardPerBlock.sub(rewardTokenPerBlock);
        uint256 extratoken = extraPerBlock.mul(leftBlocks);
        IERC20(rewardToken).transferFrom(
            msg.sender,
            address(this),
            extratoken
        );
        rewardTokenPerBlock = _rewardPerBlock;

        // set current block as the last ratio update block
        lastRatioUpdate = uint256(blockNumber());

        // emit an event
        emit RewardTokenRatioUpdated(msg.sender, rewardTokenPerBlock);
    }

    /**
     * @dev Mints RewardToken tokens; executed by RewardToken Pool only
     *
     * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
     *      on the RewardToken ERC20 token instance
     *
     * @param _to an address to mint tokens to
     * @param _amount amount of RewardToken tokens to mint
     */
    function mintYieldTo(address _to, uint256 _amount) external {
        // verify that sender is a pool registered withing the factory
        require(poolExists[msg.sender], "access denied");
        // mint RewardToken tokens as required
        IERC20(rewardToken).transfer(_to, _amount);
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner
     *
     * @param poolAddr address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address poolAddr, uint256 weight) external onlyOwnerOrSubAdmin {
        // verify function is executed either by factory owner or by the pool itself
        require(poolExists[poolAddr], "Invalid Pool address");
        // recalculate total weight
        totalWeight = totalWeight.add(weight).sub(IPool(poolAddr).weight());
        // set the new pool weight
        IPool(poolAddr).setWeight(weight);
        // emit an event
        emit WeightUpdated(msg.sender, poolAddr, weight);
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev update endBlock
     *
     * @param _rewardsupply reward to add for distribution, which will calculate new endBlock
     */
    function updateEndBlock(uint256 _rewardsupply) external onlyOwnerOrSubAdmin {
        //calculate block to be added
        uint256 blockToAdd = _rewardsupply.div(rewardTokenPerBlock);
        //transfer reward amount from admin to poolfactory address
        IERC20(rewardToken).transferFrom(
            msg.sender,
            address(this),
            uint256(_rewardsupply)
        );
        //add calculated blockToAdd to endBlock
        endBlock = endBlock.add(blockToAdd);
        totalRewardSupply = totalRewardSupply.add(_rewardsupply);

        emit UpdateEndBlock(msg.sender, blockToAdd, _rewardsupply);
    }



    //testing purpose
     function setEndBlock(uint256 _endBlock) external onlyOwnerOrSubAdmin {
        endBlock = _endBlock;
    }

 /**
     * @dev return length of pool created.
     *
     */
    function poolLength() public view returns(uint256){
        return poolInfo.length ;
    }

    /**
     * @dev update totalStakedCount, function is called when user stake token in pool.
     *
     */
    function increaseStakedCount() external {
        // verify that sender is a pool registered withing the factory
        require(poolExists[msg.sender], "access denied");
        totalStakedCount = totalStakedCount.add(1);
    }

 /**
     * @dev emergency withdraw all reward token from factory contract address to owner address.
     * @param _amount amount of reward token to withdraw from factory address.
     */
    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        //1. check reward remaining balance
        uint256 rewardBalance=IERC20(rewardToken).balanceOf(address(this));
        require(_amount <= rewardBalance,"Amount Error: amount is greater than total reward balance");
        //2. send amount 
         IERC20(rewardToken).transfer(msg.sender, _amount);

    }
    
    /**
     * @dev Throws if called by any account other than the sub admins.
     */
    modifier onlyOwnerOrSubAdmin() {
        require(isSubAdmin[msg.sender], "Ownable: caller is not the owner or sub admin");
        _;
    }




}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
    }
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function init(address owner_) internal {
        address msgSender = owner_;
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title ChainStake Pool
 *
 * @notice An abstraction representing a pool, see ChainStakePoolBase for details
 */
interface IPool {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev locking period - from
        uint256 lockedFrom;
        // @dev locking period - until
        uint256 lockedUntil;
        // @dev indicates if the stake was created as a yield reward
        bool isYield;
    }

    struct Reward {
        uint256 rewardAmount;
        bool rewardTaken;
        uint256 rewardGeneratedTimestamp;
        uint256 rewardDistributedTimeStamp;
    }

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint256);

    function lastYieldDistribution() external view returns (uint256);

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function pendingYieldRewards(address _user) external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getDeposit(address _user, uint256 _depositId)
        external
        view
        returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function stake(uint256 _amount, uint256 _lockedUntil) external;

    function unstake(uint256 _depositId, uint256 _amount) external;

    function sync() external;

    function processRewards(uint256 _amount) external;

    function setWeight(uint256 _weight) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ChainStakePoolBase.sol";

/**
 * @title ChainStake Core Pool
 *
 * @notice Core pools represent permanent pools like RewardToken or RewardToken/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See ChainStakePoolBase for more details
 */
contract ChainStakeCorePool is ChainStakePoolBase {
    using SafeMath for uint256;

    /// @dev Flag indicating pool type, false means "core pool"
    bool public constant override isFlashPool = false;

    /// @dev Pool tokens value available in the pool;
    ///      pool token examples are RewardToken (RewardToken core pool) or RewardToken/ETH pair (LP core pool)
    /// @dev For LP core pool this value doesnt' count for RewardToken tokens received as Vault rewards
    ///      while for RewardToken core pool it does count for such tokens as well
    uint256 public poolTokenReserve;

    /**
     * @dev Creates/deploys an instance of the core pool
     *
     * @param _rewardToken RewardToken ERC20 Token ChainStakeERC20 address
     * @param _factory Pool factory ChainStakePoolFactory instance/address
     * @param _poolToken token the pool operates on, for example RewardToken or RewardToken/ETH pair
     * @param _initBlock initial block used to calculate the rewards
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */

    constructor(
        address _rewardToken,
        ChainStakePoolFactory _factory,
        address _poolToken,
        uint256 _initBlock,
        uint256 _weight
    )
        ChainStakePoolBase(
            _rewardToken,
            _factory,
            _poolToken,
            _initBlock,
            _weight
        )
    {}

    /**
     * @notice Service function to calculate and pay pending vault and yield rewards to the sender
     *
     * @dev Internally executes similar function `_processRewards` from the parent smart contract
     *      to calculate and pay yield rewards; adds vault rewards processing
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */

    function processRewards(uint256 _amount) external override {
        _processRewards(msg.sender, true, false, _amount);
    }

    /**
     * @inheritdoc ChainStakePoolBase
     *
     * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
     *      and updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint256 _lockedUntil,
        bool _isYield
    ) internal override {
        super._stake(_staker, _amount, _lockedUntil, _isYield);
        poolTokenReserve = poolTokenReserve.add(_amount);
        // increase totalstakedcount when user stake token .
        factory.increaseStakedCount();
    }

    /**
     * @inheritdoc ChainStakePoolBase
     *
     * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
     *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal override {
        User storage user = users[_staker];
        Deposit memory stakeDeposit = user.deposits[_depositId];

        //check if blocknumber is greater than endBlock, then bypass locking period and unstake the amount
        if (factory.endBlock() > blockNumber()) {
            require(
                stakeDeposit.lockedFrom == 0 ||
                    now256() > stakeDeposit.lockedUntil,
                "deposit not yet unlocked"
            );
        }
        poolTokenReserve = poolTokenReserve.sub(_amount);
        super._unstake(_staker, _depositId, _amount);
    }

    /**
     * @inheritdoc ChainStakePoolBase
     *
     * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
     *      and for RewardToken pool updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _processRewards(
        address _staker,
        bool _withUpdate,
        bool _isStake,
        uint256 _amount
    ) internal override returns (uint256 pendingYield) {
        pendingYield = super._processRewards(
            _staker,
            _withUpdate,
            _isStake,
            _amount
        );

        // update `poolTokenReserve` only if this is a RewardToken Core Pool
        if (poolToken == rewardToken) {
            poolTokenReserve = poolTokenReserve.add(pendingYield);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interface/IPool.sol";
import "./ChainStakePoolFactory.sol";

/**
 * @title ChainStake Pool Base
 *
 * @notice An abstract contract containing common logic for any pool,
 *      be it a flash pool (temporary pool like SNX) or a core pool (permanent pool like RewardToken/ETH or RewardToken pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (ChainStakePoolFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - RewardToken token address
 *          - pool token address, it can be RewardToken token address, RewardToken/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 10% for RewardToken pool and 90% for RewardToken/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 * @dev For RewardToken Pool we use 100 as weight and for RewardToken/ETH pool - 900.
 */
abstract contract ChainStakePoolBase is IPool, ReentrancyGuard {
    using SafeMath for uint256;

    /// @dev Data structure representing token holder using a pool
    struct User {
        // @dev Total staked amount
        uint256 tokenAmount;
        // @dev Total weight
        uint256 totalWeight;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev last reward distribution block  to user .
        uint256 userLastRewardDistribution;
        // @dev hold index of last
        uint256 userLastRewardIndex;
        // @dev remainder time
        uint256 remainderTime;
        // @dev An array of holder's deposits
        Deposit[] deposits;
        //@dev An Array of holder's reward
        Reward[] rewards;
    }

    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => User) public users;

    /// @dev Link to the pool factory ChainStakePoolFactory instance
    ChainStakePoolFactory public immutable factory;

    /// @dev Link to the pool token instance, for example RewardToken or RewardToken/ETH pair
    address public immutable override poolToken;

    /// @dev Pool weight, 100 for RewardToken pool or 900 for RewardToken/ETH
    uint256 public override weight;

    /// rewardToken token reward address
    address public rewardToken;

    /// @dev Block number of the last yield distribution event
    uint256 public override lastYieldDistribution;

    /// @dev Used to calculate yield rewards
    /// @dev This value is different from "reward per token" used in locked pool
    /// @dev Note: stakes are different in duration and "weight" reflects that
    uint256 public override yieldRewardsPerWeight;

    /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
    uint256 public override usersLockingWeight;


    /// @dev start block , when pool is created .
    uint256 public startBlock;

    /**
     * @dev Stake weight is proportional to deposit amount and time locked, precisely
     *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer
     * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e6
     * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
     *      weight is a deposit amount multiplied by 2 * 1e6
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    /**
     * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
     *      we use simplified calculation and use the following constant instead previos one
     */
    uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER =
        2 * WEIGHT_MULTIPLIER;

    /**
     * @dev Rewards per weight are stored multiplied by 1e12, as integers.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    /**
     * @dev Fired in _stake() and stake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     */
    event Staked(address indexed _by, address indexed _from, uint256 amount);

    /**
     * @dev Fired in _updateStakeLock() and updateStakeLock()
     *
     * @param _by an address which performed an operation
     * @param depositId updated deposit ID
     * @param lockedFrom deposit locked from value
     * @param lockedUntil updated deposit locked until value
     */
    event StakeLockUpdated(
        address indexed _by,
        uint256 depositId,
        uint256 lockedFrom,
        uint256 lockedUntil
    );

    /**
     * @dev Fired in _unstake() and unstake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     */
    event Unstaked(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current block number
     */
    event Synchronized(
        address indexed _by,
        uint256 yieldRewardsPerWeight,
        uint256 lastYieldDistribution
    );

    /**
     * @dev Fired in setWeight()
     *
     * @param _by an address which performed an operation, always a factory
     * @param _fromVal old pool weight value
     * @param _toVal new pool weight value
     */
    event PoolWeightUpdated(
        address indexed _by,
        uint256 _fromVal,
        uint256 _toVal
    );
    
    event UnStakeAllStatus(
        address _staker,
        uint256 index,
        uint256 _amount,
        uint256 transferedAmount
    );
    
    /**
     * @dev Overridden in sub-contracts to construct the pool
     *
     * @param _rewardToken RewardToken ERC20 Token ChainStakeERC20 address
     * @param _factory Pool factory ChainStakePoolFactory instance/address
     * @param _poolToken token the pool operates on, for example RewardToken or RewardToken/ETH pair
     * @param _initBlock initial block used to calculate the rewards
     *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    constructor(
        address _rewardToken,
        ChainStakePoolFactory _factory,
        address _poolToken,
        uint256 _initBlock,
        uint256 _weight
    ) {
        // verify the inputs are set
        require(
            address(_factory) != address(0),
            "RewardToken Pool fct address not set"
        );
        require(_poolToken != address(0), "pool token address not set");
        require(_initBlock > 0, "init block not set");
        require(_weight > 0, "pool weight not set");
        rewardToken = _rewardToken;

        // save the inputs into internal state variables
        factory = _factory;
        poolToken = _poolToken;
        weight = _weight;

        // init the dependent internal state variables
        lastYieldDistribution = _initBlock;
        startBlock = _initBlock;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified
     *
     * @param _staker an address to calculate yield rewards value for
     * @return calculated yield reward value for the given address
     */
    function pendingYieldRewards(address _staker)
        public
        view
        override
        returns (uint256)
    {
        // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;

        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (blockNumber() > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 endBlock = factory.endBlock();
            uint256 multiplier = blockNumber() > endBlock
                ? endBlock.sub(lastYieldDistribution)
                : blockNumber().sub(lastYieldDistribution);
            uint256 rewardTokenRewards = (multiplier.mul(weight.mul(factory.rewardTokenPerBlock())).div(factory.totalWeight()));

            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight =
                rewardToWeight(rewardTokenRewards, usersLockingWeight).add(yieldRewardsPerWeight);
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        // based on the rewards per weight value, calculate pending rewards;
        User memory user = users[_staker];
        uint256 pending = weightToReward(
            user.totalWeight,
            newYieldRewardsPerWeight
        ).sub(user.subYieldRewards);

        return pending;
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user) external view override returns (uint256) {
        // read specified user token amount and return
        return users[_user].tokenAmount;
    }

    /**
     * @notice Returns information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address _user, uint256 _depositId)
        external
        view
        override
        returns (Deposit memory)
    {
        // read deposit at specified index and return
        return users[_user].deposits[_depositId];
    }

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user)
        external
        view
        override
        returns (uint256)
    {
        // read deposits array length and return
        return users[_user].deposits.length;
    }

    /**
     * @notice Stakes specified amount of tokens for the specified amount of time,
     *      and pays pending yield rewards if any
     *
     * @dev Requires amount to stake to be greater than zero
     *
     * @param _amount amount of tokens to stake
     * @param _lockUntil stake period as unix timestamp; zero means no locking
     */
    function stake(uint256 _amount, uint256 _lockUntil) external override {
        // delegate call to an internal function
        _stake(msg.sender, _amount, _lockUntil, false);
    }

    /**
     * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function unstake(uint256 _depositId, uint256 _amount) external override {
      require(factory.isReward(),"Error:Reward token not Supplied ");
        // delegate call to an internal function
        _unstake(msg.sender, _depositId, _amount);
    }

    /**
     * @dev Unstakes given amount, from the deposit array whose locking period has expired .
     * @param _amount Amount the user want to unstake
     */
    function unstakeAll(uint256 _amount) external {
      //check for total reward token on factory address
     require(factory.isReward(),"Error:Reward token not Supplied ");
      uint256 eligibleAmount=eligibleUnstake(msg.sender);
      require( _amount <= eligibleAmount,"Error : Unstake Amount is greater than eligible amount");
        User storage user = users[msg.sender];
        uint256 transferedAmount = 0;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if ((_amount.sub(transferedAmount)) > 0) {
                Deposit storage deposit = user.deposits[i];
                if (factory.endBlock() > blockNumber()) {
                    if (
                        now256() > deposit.lockedUntil &&
                        deposit.isYield == false &&
                        deposit.tokenAmount > 0
                    ) {
                        if (
                            (_amount.sub(transferedAmount)) >= deposit.tokenAmount
                        ) {
                            transferedAmount = transferedAmount.add(deposit.tokenAmount);
                            _unstake(msg.sender, i, deposit.tokenAmount);
                        } else {
                            _unstake(
                                msg.sender,
                                i,
                                (_amount.sub(transferedAmount))
                            );
                            transferedAmount =
                                transferedAmount.add(_amount).sub(transferedAmount);
                        }
                    }
                } else {
                    if (deposit.isYield == false && deposit.tokenAmount > 0) {
                        if (
                            (_amount.sub(transferedAmount)) >= deposit.tokenAmount
                        ) {
                            transferedAmount =
                                transferedAmount.add(deposit.tokenAmount);
                            _unstake(msg.sender, i, deposit.tokenAmount);
                        } else {
                            _unstake(
                                msg.sender,
                                i,
                                (_amount.sub(transferedAmount))
                            );
                            transferedAmount =
                                transferedAmount.add(_amount).sub(transferedAmount);
                        }
                    }
                }
            } else {
                // get out of loop, if required amount is unstaked .
                break;
            }
        }
    }

    /**
     * @dev Return eligible unstaking amoount . eligible Unstaking amount are tose amount whose lockperiod has been expired .
     * @param _staker Address of user
     */

    function eligibleUnstake(address _staker) public view returns (uint256) {
        User memory user = users[_staker];
        uint256 _eligibleUnstake = 0;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit memory deposit = user.deposits[i];
            if (factory.endBlock() > blockNumber()) {
                if (now256() > deposit.lockedUntil && deposit.tokenAmount > 0) {
                    _eligibleUnstake = _eligibleUnstake.add(deposit.tokenAmount);
                }
            } else {
                if (deposit.isYield == false && deposit.tokenAmount > 0) {
                    _eligibleUnstake = _eligibleUnstake.add(deposit.tokenAmount);
                }
            }
        }
        return _eligibleUnstake;
    }

    /**
     * @notice Extends locking period for a given deposit
     *
     * @dev Requires new lockedUntil value to be:
     *      higher than the current one, and
     *      in the future, but
     *      no more than 1 year in the future
     *
     * @param depositId updated deposit ID
     * @param lockedUntil updated deposit locked until value
     */
    function updateStakeLock(uint256 depositId, uint256 lockedUntil) external {
        // sync and call processRewards
        _sync();
        ////check
        _processRewards(msg.sender, false, false, 0);
        // delegate call to an internal function
        _updateStakeLock(msg.sender, depositId, lockedUntil);
    }

    /**
     * @notice Service function to synchronize pool state with current time
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one block passes between synchronizations
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function sync() external override {
        // delegate call to an internal function
        _sync();
    }

    /**
     * @notice Service function to calculate and pay pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function processRewards(uint256 _amount) external virtual override {
      require(factory.isReward(),"Error:Reward token not Supplied ");
        // delegate call to an internal function
        _processRewards(msg.sender, true, false, _amount);
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating
     *
     * @dev Set weight to zero to disable the pool
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint256 _weight) external override {
        // verify function is executed by the factory
        require(msg.sender == address(factory), "access denied");

        // emit an event logging old and new weight values
        emit PoolWeightUpdated(msg.sender, weight, _weight);

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time/blocks which might have passed
     *
     * @param _staker an address to calculate yield rewards value for
     * @return pending calculated yield reward value for the given address
     */
    function _pendingYieldRewards(address _staker)
        internal
        view
        returns (uint256 pending)
    {
        // read user data structure into memory
        User memory user = users[_staker];

        // and perform the calculation using the values read
        return
            weightToReward(user.totalWeight, yieldRewardsPerWeight).sub(user.subYieldRewards);
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     * @param _lockUntil stake period as unix timestamp; zero means no locking
     * @param _isYield a flag indicating if that stake is created to store yield reward
     *      from the previously unstaked stake
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint256 _lockUntil,
        bool _isYield
    ) internal virtual {
        // validate the inputs
        require(_amount > 0, "zero amount");
        require(
            _lockUntil == 0 ||
                (_lockUntil > now256() && _lockUntil.sub(now256()) <= 365 days),
            "invalid lock interval"
        );

        // update smart contract state
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // process current pending rewards if any
        if (user.tokenAmount > 0 && bool(factory.isReward())) {
            _processRewards(_staker, false, true, 0);
        }
        //update userlastrewarddistribution for first time .
        if (user.tokenAmount == 0) {
            user.userLastRewardDistribution = uint256(now256());
        }

        // in most of the cases added amount `addedAmount` is simply `_amount`
        // however for deflationary tokens this can be different

        // read the current balance
        uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
        // transfer `_amount`; note: some tokens may get burnt here
        transferPoolTokenFrom(address(msg.sender), address(this), _amount);
        // read new balance, usually this is just the difference `previousBalance - _amount`
        uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
        // calculate real amount taking into account deflation
        uint256 addedAmount = newBalance.sub(previousBalance);

        // set the `lockFrom` and `lockUntil` taking into account that
        // zero value for `_lockUntil` means "no locking" and leads to zero values
        // for both `lockFrom` and `lockUntil`
        uint256 lockFrom = _lockUntil > 0 ? uint256(now256()) : 0;
        uint256 lockUntil = _lockUntil;

        // stake weight formula rewards for locking
        uint256 stakeWeight = (((lockUntil.sub(lockFrom)).mul(WEIGHT_MULTIPLIER)).div(
            365 days).add(WEIGHT_MULTIPLIER)).mul(addedAmount);

        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the deposit (append it to deposits array)
        Deposit memory deposit = Deposit({
            tokenAmount: addedAmount,
            weight: stakeWeight,
            lockedFrom: lockFrom,
            lockedUntil: lockUntil,
            isYield: _isYield
        });
        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);

        // update user record
        user.tokenAmount = user.tokenAmount.add(addedAmount);
        user.totalWeight = user.totalWeight.add(stakeWeight);
        user.subYieldRewards = weightToReward(
            user.totalWeight,
            yieldRewardsPerWeight
        );

        // update global variable
        usersLockingWeight = usersLockingWeight.add(stakeWeight);

        // emit an event
        emit Staked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual {
        require(factory.isReward(),"Error:Reward token not Supplied ");
        // verify an amount is set
        require(_amount > 0, "zero amount");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];
        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards(_staker, false, true, 0);

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;
        uint256 newWeight = (((stakeDeposit.lockedUntil.sub(stakeDeposit.lockedFrom)).mul(
            WEIGHT_MULTIPLIER)).div(365 days).add(WEIGHT_MULTIPLIER)).mul(stakeDeposit.tokenAmount.sub(_amount));

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount .sub(_amount) == 0) {
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount = stakeDeposit.tokenAmount.sub(_amount);
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount = user.tokenAmount.sub(_amount);
        user.totalWeight = user.totalWeight.sub(previousWeight).add(newWeight);
        user.subYieldRewards = weightToReward(
            user.totalWeight,
            yieldRewardsPerWeight
        );

        // update global variable
        usersLockingWeight = usersLockingWeight.sub(previousWeight).add(newWeight);

        // transfer token to user
        transferPoolToken(msg.sender, _amount);

        // emit an event
        emit Unstaked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     *      updates factory state via `updateRewardTokenPerBlock`
     */
    function _sync() internal virtual {
        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endBlock = factory.endBlock();
        if (lastYieldDistribution >= endBlock) {
            return;
        }
        if (blockNumber() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (usersLockingWeight == 0) {
            lastYieldDistribution = uint256(blockNumber());
            return;
        }

        // to calculate the reward we need to know how many blocks passed, and reward per block
        uint256 currentBlock = blockNumber() > endBlock
            ? endBlock
            : blockNumber();
        uint256 blocksPassed = currentBlock.sub(lastYieldDistribution);
        uint256 rewardTokenPerBlock = factory.rewardTokenPerBlock();

        // calculate the reward
        uint256 rewardTokenReward = (blocksPassed.mul(rewardTokenPerBlock).mul(
            weight)).div(factory.totalWeight());

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight = yieldRewardsPerWeight.add(rewardToWeight(
            rewardTokenReward,
            usersLockingWeight
        ));
        lastYieldDistribution = uint256(currentBlock);

        // emit an event
        emit Synchronized(
            msg.sender,
            yieldRewardsPerWeight,
            lastYieldDistribution
        );
    }

    /**
     * @dev Used internally, Used to check user can processReward/claimreward or not
     *
     * @param _staker address of user
     */

    function vestingAllowed(address _staker) internal returns (bool) {
        User storage user = users[_staker];
        uint256 totalTime = (uint256(now256()).sub(user.userLastRewardDistribution)).add(
            user.remainderTime);
        uint256 quotient = totalTime.div(factory.vestingWindow());
        if (quotient > 0){
            uint256 remainder = totalTime.mod(factory.vestingWindow());
            user.userLastRewardDistribution = uint256(now256());
            user.remainderTime = remainder;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
     * @param _isStake ''''''
     */
    function _processRewards(
        address _staker,
        bool _withUpdate,
        bool _isStake,
        uint256 _amount
    ) internal virtual returns (uint256 pendingYield) {
        require(factory.isReward(),"Error:Reward token not Supplied ");
        // update smart contract state if required
         bool vestingStatus = vestingAllowed(_staker);
        require(
            vestingStatus || _isStake,
            "Vesting period error : wait untill vesting period get over"
        );
        if (_withUpdate) {
            _sync();
        }
       
        if (vestingStatus) {
            //1. add pending reward
            pendingYield = addReward(_staker, true);
            // 2. Change status of reward struct
            uint256 rewardamount = calculatePendingRewardToTransfer(_staker);
            uint256 amountToTransfer;
            if (_amount > 0) {
                if(_amount > rewardamount){
                    amountToTransfer = rewardamount;
                }else{
                  amountToTransfer = _amount;
                }
            } else {
                amountToTransfer = rewardamount;
            }
            changeRewardStatus(_staker, amountToTransfer);
            //3. send reward to user

            factory.mintYieldTo(_staker, amountToTransfer);

        } else {
            pendingYield = addReward(_staker, false);
        }
    }


 /**
     * @dev Used internally, used mostly when process reward is called
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withupdate flag allowing to disable synchronization (see sync()) if set to false
     */

    function addReward(address _staker, bool _withupdate)
        internal
        returns (uint256 pendingYield)
    {
        // calculate pending yield rewards, this value will be returned
        pendingYield = _pendingYieldRewards(_staker);
        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;

        User storage user = users[_staker];
        Reward memory newReward = Reward({
            rewardAmount: pendingYield,
            rewardTaken: false,
            rewardGeneratedTimestamp: uint256(now256()),
            rewardDistributedTimeStamp: uint256(0)
        });

        user.rewards.push(newReward);
        if (_withupdate) {
            user.subYieldRewards = weightToReward(
                user.totalWeight,
                yieldRewardsPerWeight
            );
        }
    }

    /**
     * @dev Gives the length of reward Array
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     */

    function getRewardLength(address _staker)
        external
        view
        returns (uint256 lengthofreward)
    {
        return users[_staker].rewards.length;
    }

    /**
     * @dev Provide detail information about reward .
     *
     *@param _staker an address which receives the reward (which has staked some tokens earlier)
     *@param _rid index of reward Array
     */
    function getRewardInfo(address _staker, uint256 _rid)
        external
        view
        returns (Reward memory _reward)
    {
        return users[_staker].rewards[_rid];
    }

    /**
     * @dev Used to calculate total rewards in reward Array .
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     */

    function calculatePendingRewardToTransfer(address _staker)
        public
        view
        returns (uint256 totalPendingRewardToTransfer)
    {
        User storage user = users[_staker];
        for (uint256 i = 0; i < user.rewards.length; i++) {
            Reward storage reward = user.rewards[i];
            if (reward.rewardAmount > 0) {
                totalPendingRewardToTransfer = totalPendingRewardToTransfer.add(reward.rewardAmount);
            }
        }
    }

    /**
     * @dev Used to calculate total reward yeild by user .
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     *
     */

    function earnedReward(address _staker) public view returns (uint256) {
        return
            calculatePendingRewardToTransfer(_staker).add(pendingYieldRewards(_staker));
    }


 /**
     * @dev Used internally, mostly when processREward is called.
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _amount amount of reward to be sent to user back, it changes the status of reward 
     */
    function changeRewardStatus(address _staker, uint256 _amount) internal {
        User storage user = users[_staker];
        uint256 rewardTransfered = 0;
        for (uint256 i = 0; i < user.rewards.length; i++) {
            if ((_amount.sub(rewardTransfered)) > 0) {
                Reward storage reward = user.rewards[i];

                if (reward.rewardAmount > 0) {
                    if ((_amount.sub(rewardTransfered)) >= reward.rewardAmount) {
                        rewardTransfered =rewardTransfered.add(reward.rewardAmount);
                        reward.rewardAmount = 0;
                        reward.rewardTaken = true;
                        reward.rewardDistributedTimeStamp = uint256(now256());
                    } else {
                        reward.rewardAmount = reward.rewardAmount.sub(_amount.sub(rewardTransfered));
                        reward.rewardDistributedTimeStamp = uint256(now256());
                        rewardTransfered =rewardTransfered.add((_amount.sub(rewardTransfered)));
                    }
                }
            } else {
                break;
            }
        }
    }

    /**
     * @dev See updateStakeLock()
     *
     * @param _staker an address to update stake lock
     * @param _depositId updated deposit ID
     * @param _lockedUntil updated deposit locked until value
     */
    function _updateStakeLock(
        address _staker,
        uint256 _depositId,
        uint256 _lockedUntil
    ) internal {
        // validate the input time
        require(_lockedUntil > now256(), "lock should be in the future");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        // validate the input against deposit structure
        require(_lockedUntil > stakeDeposit.lockedUntil, "invalid new lock");

        // verify locked from and locked until values
        if (stakeDeposit.lockedFrom == 0) {
            require(
                _lockedUntil.sub(now256()) <= 365 days,
                "max lock period is 365 days"
            );
            stakeDeposit.lockedFrom = uint256(now256());
        } else {
            require(
                _lockedUntil.sub(stakeDeposit.lockedFrom) <= 365 days,
                "max lock period is 365 days"
            );
        }

        // update locked until value, calculate new weight
        stakeDeposit.lockedUntil = _lockedUntil;
        uint256 newWeight = (((stakeDeposit.lockedUntil.sub(stakeDeposit.lockedFrom)).mul(WEIGHT_MULTIPLIER)).div(
            (uint256(365 days)).add(WEIGHT_MULTIPLIER))).mul(stakeDeposit.tokenAmount);

        // save previous weight
        uint256 previousWeight = stakeDeposit.weight;
        // update weight
        stakeDeposit.weight = newWeight;

        // update user total weight and global locking weight
        user.totalWeight = user.totalWeight.sub(previousWeight).add(newWeight);
        usersLockingWeight = usersLockingWeight.sub(previousWeight).add(newWeight);

        // emit an event
        emit StakeLockUpdated(
            _staker,
            _depositId,
            stakeDeposit.lockedFrom,
            _lockedUntil
        );
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      RewardToken reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param rewardPerWeight RewardToken reward per weight
     * @return reward value normalized to 10^12
     */
    function weightToReward(uint256 _weight, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        // apply the formula and return
        return (_weight.mul(rewardPerWeight)).div(REWARD_PER_WEIGHT_MULTIPLIER);
    }

    /**
     * @dev Converts reward RewardToken value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward
     *      - OR -
     * @dev Converts reward RewardToken value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight
     *
     * @param reward yield reward
     * @param rewardPerWeight reward/weight (or stake weight)
     * @return stake weight (or reward/weight)
     */
    function rewardToWeight(uint256 reward, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        // apply the reverse formula and return
        return (reward.mul(REWARD_PER_WEIGHT_MULTIPLIER)).div(rewardPerWeight);
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a pool token
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     */
    function transferPoolToken(address _to, uint256 _value)
        internal
        nonReentrant
    {
        // just delegate call to the target
        SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a pool token
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     */
    function transferPoolTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal nonReentrant {
        // just delegate call to the target
        SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
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

    constructor() {
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