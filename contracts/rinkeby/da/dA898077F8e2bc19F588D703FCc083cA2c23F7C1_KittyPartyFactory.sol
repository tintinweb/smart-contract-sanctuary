// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import './KittyPartyController.sol';

contract KittyPartyFactory {
     
     address public tomCatContract;
     mapping(address => address[]) public myKitties;

     event KittyLive(address indexed kreator, address kitty);

     constructor(address _tomCatContract){
         tomCatContract = _tomCatContract;
     }
    /// @dev anyone can create a Kitty
    function createKitty(
        uint256 _amountInDAIPerRound,
        address _dai_address,
        uint8 _durationInDays,
        uint8 _kittyType,
        bool _vrfEnabled
        )
    external
    returns (address kittyAddress) {
        address kitty = Clones.clone(tomCatContract);
        KittyPartyController(kitty).initialize(
             _amountInDAIPerRound,
             _dai_address,
             _durationInDays,
             _kittyType,
             _vrfEnabled
             );
        //Add to the kitten list
        myKitties[msg.sender].push(kitty);
        emit KittyLive(msg.sender, kitty);
        return kitty;
     }
     
     function getMyKitties(address candidateAddress) external view returns(address[] memory){
         return myKitties[candidateAddress];
     }


    
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./base/Kittens.sol";
import "./base/KittyPartyWinnerSelectionOptions.sol";
import "./KittyPartyWinnerSelectStrategy.sol";
import "./KittyPartyStateTransition.sol";

/// @title Kitty Party Controller
/// There are three parties
//TODO: Check if we can take only the stake required for admin
contract KittyPartyController is KittyPartyStateTransition, Ownable, Pausable{
    bool vrfEnabled = true;
    
    uint256 public amountInDAIPerRound;
    bool public initialized = false;
    bytes32 private inviteHash;

    IERC20 public dai;

    Kittens kittens;
    KittyPartyWinnerSelectStrategy kpWinnerSelectStrategy;

    event KittenAdded(address kitten);

    modifier knownKitten(bytes32 _invitedHash) {
        require(inviteHash == _invitedHash);
        _;
    }

    modifier kittenExists(address _kitten) {
        require(kittens.checkExists(_kitten) == true, "You need to be a registered kitten");
        _;
    }

    modifier minimumKittens(uint numberOfKittens) {
        require(numberOfKittens >= 2);
        _;
    }
    
    ///@dev initialize the contract after deploying
    function initialize(
        uint256 _amountInDAIPerRound,
        address _dai_address,
        uint8 _durationInDays,
        uint8 _kittyType,
        bool _vrfEnabled
    ) public timedTransitions() {
        require(initialized == false, "Already Initialized");
        initialized = true;
        durationInDays = _durationInDays;
        amountInDAIPerRound = _amountInDAIPerRound;
        kpWinnerSelectStrategy = new KittyPartyWinnerSelectStrategy(
            _kittyType,
            _vrfEnabled
        );
        
        dai = IERC20(_dai_address);
        kittens = new Kittens();
    }
    
    function getWinners() public view returns(address[] memory){
        return kpWinnerSelectStrategy.getWinners();
    }

    function getKittenStore() public view returns(address){
        return address(kittens);
    }

    function setInviteHash(bytes32 _inviteHash) public onlyOwner {
        inviteHash = _inviteHash;
    }

    ///@dev TODO: check for number of badges
    function applyInitialVerification() public timedTransitions() atStage(KittyPartyStages.InitialCollection) onlyOwner minimumKittens(kittens.getLength()){
        //Transition from Collection state, a lot of initiation and checks to be done here.
        // for (uint256 i = 0; i < kittens.getLength(); i++) {
        //     address kitten = kittens.getValueAt(i);
        //     //issue redemptionTickets or receipts
        //     //
        // }
        numberOfRounds = kittens.getLength();
    }

    function applyRoundVerification() public timedTransitions() atStage(KittyPartyStages.Collection) minimumKittens(kittens.getLength()) returns(uint256){
        // Check for each of the kittens is the amount in
        // for (uint256 i = 0; i < kittens.getLength(); i++) {
        //     address kitten = kittens.getValueAt(i);
        //     //issue redemptionTickets or receipts
        //     //
        // }
        uint256 daiBalance = dai.balanceOf(address(msg.sender));
        return daiBalance;
    }

    function applyYieldStrategy() public timedTransitions() atStage(KittyPartyStages.Staking) minimumKittens(kittens.getLength()) returns(uint256){
        // Check for each of the kittens is the amount in, if not then we follow pattern and refund and stop , if yes then we proceed to yield staking
        // for (uint256 i = 0; i < kittens.getLength(); i++) {
        //     address kitten = kittens.getValueAt(i);
        //     //issue redemptionTickets or receipts
        //     //
        // }
        uint256 daiBalance = dai.balanceOf(address(this));
        return daiBalance;
    }

    ///@dev This will be auto called by the oracle later for testing we keep it as public
    function applyWinnerStrategy() public timedTransitions() atStage(KittyPartyStages.Payout){
        kpWinnerSelectStrategy.initiateCheckWinner(address(kittens));
    }

   

    ///@dev any address can be a kitten as long as they have the inviteHash
    function verifyIfCanAddKitten(bytes32 _inviteHash) public knownKitten(_inviteHash) timedTransitions() atStage(KittyPartyStages.InitialCollection) whenNotPaused(){
        uint256 daiBalance = dai.balanceOf(address(msg.sender));
        require(daiBalance >= amountInDAIPerRound, "Not enough balance to start the round");
       
        // Request for approval of tokens for now assuming DAI
        require(dai.approve(address(msg.sender), amountInDAIPerRound), 'Please approve the transfer amount');
    }

    ///@dev perform the actual value transfer and add Kitten to the party
    function depositAndAddKittenToParty(bytes32 _inviteHash) public knownKitten(_inviteHash) timedTransitions() atStage(KittyPartyStages.InitialCollection) whenNotPaused() returns(bool){
        uint256 daiBalance = dai.balanceOf(address(msg.sender));
        require(daiBalance >= amountInDAIPerRound, "Not enough balance to start the round");
        uint256 allowance = dai.allowance(msg.sender, address(this));
        require(allowance >= amountInDAIPerRound, "Please approve amount to be transferred");
        //Can optimize above
        kittens._addKitten(msg.sender);
        emit KittenAdded(msg.sender);
        // console.log("Sender balance is %s tokens", daiBalance);
        // console.log("Sender allowance is %s tokens", allowance);
        require(dai.transferFrom(address(msg.sender), address(this), amountInDAIPerRound), 'Transfer Failed');
        return true;
    }

    ///@dev perform the actual value transfer and add Kitten to the party
    function approveRoundDeposits() public kittenExists(msg.sender) timedTransitions() atStage(KittyPartyStages.Collection) whenNotPaused() returns(bool){

        uint256 daiBalance = dai.balanceOf(address(msg.sender));
        require(daiBalance >= amountInDAIPerRound, "Not enough balance to start the round");
       
        // Request for approval of tokens for now assuming DAI
        require(dai.approve(address(msg.sender), amountInDAIPerRound), 'Please approve the transfer amount');
        
        return true;
    }

        ///@dev perform the actual value transfer and add Kitten to the party
    function addRoundDeposits() public kittenExists(msg.sender) timedTransitions() atStage(KittyPartyStages.Collection) whenNotPaused() returns(bool){
        
        uint256 daiBalance = dai.balanceOf(address(msg.sender)); 
        require(daiBalance >= amountInDAIPerRound, "Not enough balance to start the round");
        uint256 allowance = dai.allowance(msg.sender, address(this));
        require(allowance >= amountInDAIPerRound, "Please approve amount to be transferred");
        require(dai.transferFrom(address(msg.sender), address(this), amountInDAIPerRound), 'Transfer Failed');
        
        return true;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Kitty Party Types and options
/// @notice Utilized by factory while deciding what party to start
/// There are three parties
contract Kittens {
    struct MyKittens {
        address[] addressList; // An unordered list of unique values
        mapping(address => bool) exists;
        mapping(address => uint256) index; // Tracks the index of a value
        mapping(address => uint256) balance;
    }

    MyKittens myKittens;

    function _addKitten(address value) external returns (bool success) {
        // Modify this to wait for Kitten to accept inviteKitten
        if (myKittens.exists[value]) return false;
        myKittens.index[value] = myKittens.addressList.length;
        myKittens.exists[value] = true;
        myKittens.addressList.push(value);
        myKittens.balance[value] = 0;

        return true;
    }

    function getList() public view returns (address[] memory) {
        return myKittens.addressList;
    }

    function getLength() public view returns (uint256) {
        return myKittens.addressList.length - 1;
    }

    function getValueAt(uint256 i) public view returns (address) {
        return myKittens.addressList[i];
    }

    function getIndex(address _kitten) public view returns (uint256) {
        return myKittens.index[_kitten];
    }

    function checkExists(address _kitten) public view returns(bool exists) {
         if (myKittens.exists[_kitten]) return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title Kitty Party Types and options
/// @notice Utilized by factory while deciding what party to start
/// There are three parties 
contract KittyPartyWinnerSelectionOptions {
  bool internal vrfEnabled;
  enum KittyType {
        Bid,
        Equal,
        SingleLottery,
        MultipleLottery
    }
  
  //default type
  KittyType public kittyType = KittyType.SingleLottery;
  constructor(
      uint8 _kittyType, 
      bool _vrfEnabled
      ){
      kittyType = KittyType(_kittyType);
      vrfEnabled = _vrfEnabled;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./base/KittyPartyWinnerSelectionOptions.sol";
import "./base/Kittens.sol";

contract KittyPartyWinnerSelectStrategy is  KittyPartyWinnerSelectionOptions {
  uint256 public randomness;
  bytes32 constant NULL = "";
  bytes32 internal keyHash;
  uint256 internal fee;

  address[] public winnerAddresses;
  address kittens;

  constructor(uint8 _kittyType, bool _vrfEnabled) 
    // VRFConsumerBase(
    //     0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
    //     0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
    // )
    KittyPartyWinnerSelectionOptions(_kittyType, _vrfEnabled)
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; 
    }

    function initiateCheckWinner(address _kittenAddress) external {
    //check strategy call relevant functions based on strategy call
    //Also implement a better strategy for a random user provided seed
    kittens = _kittenAddress;
    if(kittyType == KittyType.Equal) {
      //set everyone as winners
    }
    else if(kittyType == KittyType.Bid){
      //check the lowest bid value and call setWinner
    }
    else{ 
      runLottery();
    }
  }
        
  function runLottery()
        private
        returns (bytes32 requestId)
    {
      if(vrfEnabled == false){
        fulfillRandomness(NULL, uint256(keccak256(abi.encode(block.timestamp + block.difficulty))));
        return NULL;
      }
      else{
        // require(
        //     LINK.balanceOf(address(this)) >= fee,
        //     "Not enough LINK - fill contract with faucet"
        // );
        // return requestRandomness(keyHash, fee);
      }
    }

  /**
  * Callback function used by VRF Coordinator
  */
  function fulfillRandomness(bytes32, uint256 _randomness)
        internal
        // override
    {
        randomness = _randomness;
        //do a callback to msg.sender
        setLotteryWinner();
    }

  function setLotteryWinner() private {
    if(kittyType == KittyType.SingleLottery){
      //use the randomness to get single winner we need another variable to decide whether previous winner can win or not
      uint256 numberOfKittens = Kittens(kittens).getLength();
      uint256 randomResult = (randomness % numberOfKittens) + 1;
      winnerAddresses.push(Kittens(kittens).getValueAt(randomResult));
    }
    else{ 
      //use randomness to choose 3 individual winners
    }
  }

  function getWinners() external view returns(address[] memory){
      return winnerAddresses;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract KittyPartyStateTransition {

enum KittyPartyStages {
        InitialCollection,
        Collection,
        Staking,
        Payout,
        Completed
    } //Set of valid states for the kitty party contract
    //InitialCollection: This collection is different because it is before start of the rounds
    //Collection: Pre-Round verification completed, collection criteria can be checked for
    //Staking: The colection has been completed successfully, the asset can now be staked on respective protocols, we open up for bids in this state
    //Payout: The assets are withdrawn from the repective contracts, a winner is chosen at random
    //Completed: THe kitty-party is over
    KittyPartyStages public stage = KittyPartyStages.InitialCollection;
    //initial state is verification state
    uint public creationTime = block.timestamp;
    uint256 durationInDays;
    uint256 currentRound = 1;
    uint256 numberOfRounds = 2; // this data is duplicated and is equivalent to number of kittens minimum 2

    event Completed();
    event StageTransition(uint prevStage, uint nextStage);

    modifier atStage(KittyPartyStages _stage) {
        require(stage == _stage, "Not in the expected stage");
        _;
    }
    
    modifier transitionAfter() {
        _;
        nextStage();
    }
    
    //TODO: Change to days from hours or minutes
    modifier timedTransitions() {
        if (stage == KittyPartyStages.InitialCollection && block.timestamp >= creationTime + 3 hours) {
            nextStage();
            nextStage();//TODO: clean this and optimize
        }
        if (stage == KittyPartyStages.Collection && block.timestamp >= creationTime + 3 hours) {
            nextStage();
        }
        if (stage == KittyPartyStages.Staking && block.timestamp >= creationTime + durationInDays * 1 hours) {
            nextStage();
        }
        _;
    }

//Check if rounds have been force ended or if rounds are finished and then close else go back to Collection phase
    function nextStage() internal {
      uint nextStageValue = uint(stage) + 1;
      if (stage == KittyPartyStages.Payout && numberOfRounds >= currentRound) {
        nextStageValue = 1;
        currentRound++;
      }
        emit StageTransition(uint(stage), nextStageValue);
        stage = KittyPartyStages(nextStageValue);
    }

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}