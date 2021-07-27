/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// File: contracts/Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/ReentrancyGuard.sol

pragma solidity =0.5.16;
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;
  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

// File: contracts/Halt.sol

pragma solidity =0.5.16;


contract Halt is Ownable {
    
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        public 
        onlyOwner
    {
        halted = halt;
    }
}

// File: contracts/MinePoolData.sol

pragma solidity =0.5.16;




contract MinePoolData is Ownable,Halt,ReentrancyGuard {
    
    address public fnx ;
    address payable public lp;

   // address  public rewardDistribution;
    
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;

    uint256 public rewardPerduration; //reward token number per duration
    uint256 public duration;
    
    mapping(address => uint256) public rewards;   
        
    mapping(address => uint256) public userRewardPerTokenPaid;
    
    uint256 public periodFinish;
    uint256 public startTime;
    
    uint256 internal totalsupply;
    mapping(address => uint256) internal balances;

    uint256 public _fnxFeeRatio ;//= 50;//5%
    uint256 public _htFeeAmount ;//= 1e16;
    address payable public _feeReciever;
    
}

// File: contracts/baseProxy.sol

pragma solidity =0.5.16;



/**
 * @title  baseProxy Contract

 */
contract baseProxy is MinePoolData {
    address public implementation;
    constructor(address implementation_) public {
        // Creator of the contract is admin during initialization
        implementation = implementation_; 
    }
    function getImplementation()public view returns(address){
        return implementation;
    }
    function setImplementation(address implementation_)public onlyOwner{
        implementation = implementation_; 
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("update()"));
        require(success);
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = implementation.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    function delegateToViewAndReturn() internal view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0x40), returndatasize) }
        }
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }
}

// File: contracts/MinePoolProxy.sol

pragma solidity =0.5.16;

/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract MinePoolProxy is baseProxy {
    
    constructor (address implementation_) baseProxy(implementation_) public{
    }
    /**
     * @dev default function for foundation input miner coins.
     */
    function()external payable{

    }
        
    function setPoolMineAddress(address /*_liquidpool*/,address /*_fnxaddress*/) public {
         delegateAndReturn();
    }    
    /**
     * @dev changer liquid pool distributed time interval , only foundation owner can modify database.
     * @  reward the distributed token amount in the time interval
     * @  mineInterval the distributed time interval.
     */
    function setMineRate(uint256 /*reward*/,uint256/*rewardinterval*/) public {
        delegateAndReturn();
    }

    /**
     * @dev getting back the left mine token
     * @ reciever the reciever for getting back mine token
     */
    function getbackLeftMiningToken(address /*reciever*/)  public {
        delegateAndReturn();
    }
  /**
   * @dev set period to finshi mining
   * @ _periodfinish the finish time
   */
    function setPeriodFinish(uint256 /*startTime*/,uint256 /*endTime*/)public {
        delegateAndReturn();
    }
     /**
     * @dev user stake in lp token
     * @  amount stake in amout
     */
    function stake(uint256 /*amount*/,bytes memory /*data*/) payable public {
         delegateAndReturn();
    }  
    
    
   /**
     * @dev user  unstake to cancel mine
      * @  amount stake in amout
     */
    function unstake(uint256 /*amount*/,bytes memory /*data*/) payable public {
         delegateAndReturn();
    }  
   
      /**
     * @dev user  unstake and get back reward
     * @  amount stake in amout
     */
    function exit() public {
         delegateAndReturn();
    }    

    /**
     * @dev user redeem mine rewards.
     */
    function getReward() payable public {
        delegateAndReturn();
    }    
    

///////////////////////////////////////////////////////////////////////////////////
    /**
     * @return Total number of distribution tokens balance.
     */
    function distributionBalance() public view returns (uint256) {
        delegateToViewAndReturn();
    }
  
    /**
     * The user to look up staking information for.
     * return The number of staking tokens deposited for addr.
     */
    function totalStakedFor(address /*addr*/) public view returns (uint256){
        delegateToViewAndReturn();
    }  
    
    
    /**
     * @dev retrieve user's stake balance.
     *  account user's account
     */
    function totalRewards(address /*account*/) public view returns (uint256) {
        delegateToViewAndReturn();
    }


  /**
     * @dev all stake token.
     * @return The number of staking tokens
     */
    function totalStaked(uint256 ) public view returns (uint256) {
         delegateToViewAndReturn();
    }

    /**
     * @dev get mine info
     */
    function getMineInfo() public view returns (uint256,uint256,uint256,uint256) {
        delegateToViewAndReturn();
    }
    
    function getVersion() public view returns (uint256) {
        delegateToViewAndReturn();
    }

    function setFeePara(uint256 /*fnxFeeRatio*/,uint256 /*htFeeAmount*/,address payable /*feeReciever*/) public {
        delegateAndReturn();
    }
//////////////////////////////////////////////////////////////////////////////////
    function deposit(uint256 /*_pid*/, uint256 /*_amount*/) public payable{
        delegateAndReturn();
    }

    function withdraw(uint256 /*_pid*/, uint256 /*_amount*/) public payable{
        delegateAndReturn();
    }

    function allPendingReward(uint256 /*_pid*/,address /*_user*/) public view returns(uint256,uint256,uint256){
        delegateToViewAndReturn();
    }

}