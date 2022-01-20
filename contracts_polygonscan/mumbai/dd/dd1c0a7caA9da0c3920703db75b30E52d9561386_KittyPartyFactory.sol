// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import './KittyPartyController.sol';
import './interfaces/IKittyPartyInit.sol';
import './interfaces/IKittyPartyAccountant.sol';
import './interfaces/IKittyPartyKeeper.sol';

contract KittyPartyFactory is IKittenPartyInit, Initializable {

    KittyPartyFactoryArgs public kpFactory;

    mapping(address => address[]) public myKitties;
    mapping(address => bool) public myStrategies;

    uint8 public kreatorFeesInBasisPoints;
    uint8 public daoFeesInBasisPoints;
    address public daoAddress;

    uint256 constant DECIMALS = 10 ** 18;
    
    event KittyLive(address indexed kreator, address kitty, bytes32 kittyPartyName);
    event FactoryInitialized();
    
    modifier onlyDAOAddress(){
        require(msg.sender == daoAddress);
        _;
    }

    function initialize(address _daoAddress) external initializer {
        daoAddress = _daoAddress;
        kreatorFeesInBasisPoints = 100;
        daoFeesInBasisPoints = 100;
    }

    function setFactoryInit(KittyPartyFactoryArgs memory _kpFactory) external onlyDAOAddress {
        kpFactory = _kpFactory;
        emit FactoryInitialized();
    }
    
    function setKreatorFees(uint8 _kreatorFeesInBasisPoints) external onlyDAOAddress {
        kreatorFeesInBasisPoints = _kreatorFeesInBasisPoints;
    }

    function setApprovedStrategy(address _strategy) external onlyDAOAddress {
        myStrategies[_strategy] = true;
    }

    function setDAOFees(uint8 _daoFeesInBasisPoints) external onlyDAOAddress {
        daoFeesInBasisPoints = _daoFeesInBasisPoints;
    }
    
    /// @dev Kitty Party is a community not a single pool so limit no of Kittens/pool
    /// @notice Factory that creates a Kitty Party
    function createKitty(
         KittyInitiator calldata _kittyInitiator,
         KittyYieldArgs calldata _kittyYieldArgs
    )
        external
        returns (address kittyAddress)
    {
        address kitty = ClonesUpgradeable.clone(kpFactory.tomCatContract);   
        IERC20 dai = IERC20(_kittyInitiator.daiAddress);
        uint256 allowance = dai.allowance(msg.sender, address(this));
        uint badgeType = (_kittyInitiator.amountInDAIPerRound >= 1000000 * DECIMALS) ? 3 : 
                    (_kittyInitiator.amountInDAIPerRound >= 1000 * DECIMALS) ? 2 : 1;
    
        require(myStrategies[_kittyInitiator.yieldContract] == true, "Strategy not approved");
        //min requirements
        require(_kittyInitiator.maxKittens <= 20, "Too many Kittens");
        require(allowance >= _kittyInitiator.amountInDAIPerRound / 10, "Min 10% req as stake");
        require(_kittyInitiator.amountInDAIPerRound >= 20 * DECIMALS, "Min $20 req as stake");
        require(dai.transferFrom(msg.sender, address(_kittyInitiator.yieldContract), allowance), "Kreator stake fail");
        require(_kittyInitiator.kreatorFeesInBasisPoints <= kreatorFeesInBasisPoints, "Fees too low");
        require(_kittyInitiator.daoFeesInBasisPoints <= daoFeesInBasisPoints, "Dao fees too low");
        //check kreators permissions        
        require(IKittyPartyAccountant(kpFactory.accountantContract).balanceOf(msg.sender, badgeType) > 0, "Kreator not permitted");
        require(IKittyPartyAccountant(kpFactory.accountantContract).balanceOf(msg.sender, 5) == 0, "HARKONNEN");
        require(IKittyPartyAccountant(kpFactory.accountantContract).setupMinter(kitty), "Not able to set minter");
   
        KittyPartyController(kitty).initialize(
            _kittyInitiator,
            _kittyYieldArgs,
            kpFactory,
            msg.sender, 
            allowance
        );

        //Add the created factory to the active kitty party list
        myKitties[msg.sender].push(kitty);
        emit KittyLive(msg.sender, kitty, _kittyInitiator.partyName);

        (bool successLitter,) = address(kpFactory.litterAddress).call(abi.encodeWithSignature("setupKittyParty(address)", kitty));
        require(successLitter, "Not able to set KittyParty role!");
        //automate the cron jobs via keepers
        IKittyPartyKeeper(kpFactory.keeperContractAddress).addKPController(kitty);
        
        return kitty;
    }
     
    function getMyKitties(address candidateAddress) external view returns (address[] memory) {
        return myKitties[candidateAddress];
    }    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
library ClonesUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./KittyPartyStateTransition.sol";
import './interfaces/IKittyPartyInit.sol';
import './interfaces/IKittyPartyWinnerStrategy.sol';
import "./interfaces/IKittyPartyYieldGenerator.sol";

/// @title Kitty Party Controller
contract KittyPartyController is KittyPartyStateTransition, IKittenPartyInit {
    bytes32 private inviteHash;
    uint constant MIN_KITTENS = 2;
    uint256[] public partyRoundKittens;

    IKittyPartyWinnerStrategy kpWinnerSelectStrategy;

    KittyInitiator public kittyInitiator;
    KittyPartyFactoryArgs public kPFactory;
    KittyPartyControllerVars public kittyPartyControllerVars;

    IERC20 public dai;
    bytes public calldataForLock;
    bytes public callDataForUnwind;

    /****** EVENTS *******/

    event RefundRequested(uint refund);
    event StopStaking(address party, uint amount);
    event PaidFees(address party, uint fees);
    event WinnersDecided(address party, uint[] winners);
    event PartyCompleted(address party, uint internalState);

    /****** MODIFIERS *******/

    modifier knownKitten(bytes32 _invitedHash) {
        require(inviteHash == _invitedHash);
        _;
    }

    modifier kittenExists(address _kitten) {
        bytes memory checkExistsKitten = abi.encodeWithSignature("checkExists(address,address)", address(this), msg.sender);
        (bool success, bytes memory returnData) = address(kPFactory.litterAddress).staticcall(checkExistsKitten);
        require(success, "NE");
        (bool exists) = abi.decode(returnData, (bool));
        require(exists == true, "NR");
        _;
    }

    modifier minimumKittens(uint numberOfKittens) {
        require(numberOfKittens >= MIN_KITTENS);
        _;
    }

    modifier onlyKreator(){
        require(msg.sender == kittyPartyControllerVars.kreator);
        _;
    }

    /****** STATE MUTATING FUNCTIONS *******/
    
    ///@dev initialize the contract after deploying
    function initialize(
        KittyInitiator calldata _kittyInitiator,
        KittyYieldArgs calldata _kittyYieldArgs,
        KittyPartyFactoryArgs calldata _kPFactory,
        address _kreator,
        uint256 _kreatorStake
    ) 
        public 
    {
        require(kittyPartyControllerVars.internalState == 0, "Already Initialized");
        kittyPartyControllerVars.internalState = 1;
        kittyInitiator = _kittyInitiator;
        kPFactory = _kPFactory;
        kittyPartyControllerVars.kreator = _kreator;
        kittyPartyControllerVars.kreatorStake = _kreatorStake;
        dai = IERC20(_kittyInitiator.daiAddress);
        kpWinnerSelectStrategy = IKittyPartyWinnerStrategy(kittyInitiator.winnerStrategy);

        IKittyPartyYieldGenerator(kittyInitiator.yieldContract).setPartyInfo(
            _kittyYieldArgs.sellTokenAddress,
            _kittyYieldArgs.lpTokenAddress);
        
        durationInDays = _kittyInitiator.durationInDays;
        _initState(_kittyInitiator.timeToCollection);
    }
    
    function setActivityInterval(uint8 _timeToCollection) external onlyKreator {
        timeToCollection = _timeToCollection;
    }

    function setInviteHash(bytes32 _inviteHash) external onlyKreator {
        inviteHash = _inviteHash;
    }

    ///@dev Calling this can change the state without checking conditions!!! Use cautiously!
    function changeState() external onlyKreator returns (bool success) {
        _timedTransitions();
        return true;
    }

    ///@dev perform the actual value transfer and add Kitten to the party
    function depositAndAddKittenToParty(bytes32 _inviteHash) 
        external 
        knownKitten(_inviteHash)
        returns (bool)
    {
        _timedTransitions();
        _atStage(KittyPartyStages.InitialCollection);
        kittyPartyControllerVars.localKittens = kittyPartyControllerVars.localKittens + 1;

        require(kittyInitiator.maxKittens >= kittyPartyControllerVars.localKittens);
        require(msg.sender != kittyPartyControllerVars.kreator, "Kreator cannot join own party");
        require(numberOfRounds == 0, "Rounds were already initiated");
       
        bytes memory addKitten = abi.encodeWithSignature("addKitten(address)", msg.sender);
        (bool success,) = address(kPFactory.litterAddress).call(addKitten);
        require(success, "Kitten not added");
        
        depositForYield();
        IKittyPartyYieldGenerator(kittyInitiator.yieldContract).createLockedValue(calldataForLock);

        return true;
    }

    function setCallDataForYield(bytes memory _calldataForLock, bytes memory _callDataForUnwind) external onlyKreator {
        calldataForLock = _calldataForLock;
        callDataForUnwind = _callDataForUnwind;
    }

    ///@dev This function adds deposits for each round
    function addRoundDeposits() 
        external 
        kittenExists(msg.sender) 
        returns (bool)
    {        
        _timedTransitions();
        _atStage(KittyPartyStages.Collection);
        depositForYield();
        IKittyPartyYieldGenerator(kittyInitiator.yieldContract).createLockedValue(calldataForLock);
        return true;
    }

    function depositForYield()
        internal
    {
        uint256 daiBalance = dai.balanceOf(address(msg.sender)); 
        require(daiBalance >= kittyInitiator.amountInDAIPerRound, "Not enough balance");
        uint256 allowance = dai.allowance(msg.sender, address(this));
        require(allowance >= kittyInitiator.amountInDAIPerRound, "Please approve amount");
        require(dai.transferFrom(address(msg.sender), address(kittyInitiator.yieldContract), kittyInitiator.amountInDAIPerRound), 'Transfer Failed');
        
        bytes memory getIndex = abi.encodeWithSignature("getIndex(address,address)",address(this),msg.sender);
        (bool success, bytes memory kittenIndex) = address(kPFactory.litterAddress).call(getIndex);
        require(success, "Kitten not added");
        (uint256 index) = abi.decode(kittenIndex, (uint256));
        partyRoundKittens.push(index);
    }

    ///@dev This is called by the kreator once the kreator verifies that all the kittens have deposited initial amount for the first round.
    function applyInitialVerification() 
        external
        minimumKittens(kittyPartyControllerVars.localKittens)
    {
        _timedTransitions();
        _atStage(KittyPartyStages.Staking);
        require(kittyPartyControllerVars.internalState == 1, "Rounds were already initiated");
        kittyPartyControllerVars.internalState = 2;

        if(kittyPartyControllerVars.kreatorStake >= kittyInitiator.amountInDAIPerRound * kittyInitiator.maxKittens) {
            //Multiple Rounds
            numberOfRounds = kittyPartyControllerVars.localKittens;
        } else {
            //only minimum stake so only single round
            numberOfRounds = 0;
        }
    }

    ///@dev This is used for changing state from Collection -> Staking
    function startStakingMultiRound() external {
        _atStage(KittyPartyStages.Collection);
        require(partyRoundKittens.length == kittyPartyControllerVars.localKittens, "Kitten Missing!");
        _timedTransitions();
        _atStage(KittyPartyStages.Staking);
    }

    ///@dev This is used for changing state from Payout -> Collection for multiRound
    function startNextRound() external {
        _atStage(KittyPartyStages.Payout);
        _timedTransitions();
        _atStage(KittyPartyStages.Collection);
    }


    ///@dev Stop the staking and push the yield generated for the specific kitty party to the treasury
    function stopStaking() external {
        _timedTransitions();
        _atStage(KittyPartyStages.Payout);
        
        kpWinnerSelectStrategy.initiateCheckWinner(kittyPartyControllerVars.localKittens);
        IKittyPartyYieldGenerator(kittyInitiator.yieldContract).unwindLockedValue(callDataForUnwind);
        
        bytes memory yieldGenerated = abi.encodeWithSignature("yieldGenerated(address)",address(this));
        (bool successYield, bytes memory returnData) = address(kittyInitiator.yieldContract).staticcall(yieldGenerated);
        require(successYield, "YE1");
        (kittyPartyControllerVars.profit) = abi.decode(returnData, (uint256));
        emit StopStaking(address(this), kittyPartyControllerVars.profit);
    }

     /// @dev pay system and kreator fees
    function payOrganizerFees() external {
        _atStage(KittyPartyStages.Payout);
        require(kittyPartyControllerVars.profit > 0);
        uint256 amountToSendKreator = kittyPartyControllerVars.profit * kittyInitiator.kreatorFeesInBasisPoints / 10000;
        uint256 amountToSendDAO = kittyPartyControllerVars.profit * kittyInitiator.daoFeesInBasisPoints / 10000;
        kittyPartyControllerVars.profitToSplit = kittyPartyControllerVars.profit - (amountToSendKreator + amountToSendDAO);
        kittyPartyControllerVars.profit = 0;
        mintTokens(kittyPartyControllerVars.kreator, amountToSendKreator, 0);
        mintTokens(kPFactory.daoTreasuryContract, amountToSendDAO, 0);
        emit PaidFees(address(this), amountToSendKreator + amountToSendDAO);
    }

    ///@notice send KPR to the winners to redeem the actual amount from the treasury contract
    function applyWinnerStrategy() external {
        _atStage(KittyPartyStages.Payout);
        require(kittyPartyControllerVars.profitToSplit > 0);

        uint256 amountToSend = (kittyPartyControllerVars.profitToSplit 
                                / kpWinnerSelectStrategy.getLength());
        kittyPartyControllerVars.profitToSplit = 0;
        uint[] memory winners = kpWinnerSelectStrategy.getWinners();
        batchMintReceiptTokens(winners, amountToSend);
        delete partyRoundKittens;//clear the current round participants
        emit WinnersDecided(address(this), winners);
    }
    
    ///@notice This is to be called after party completion to mint the NFT's and tokens to the kittens and kreator
    function applyCompleteParty() external {
        _timedTransitions();
        _atStage(KittyPartyStages.Completed);
        require(kittyPartyControllerVars.internalState == 2);
        kittyPartyControllerVars.internalState = 3;
        //Finally give the Kreator a kreator badge for completing the round and also return all the DAI tokens
        mintTokens(kittyPartyControllerVars.kreator, 1, 4);
        mintTokens(kittyPartyControllerVars.kreator, kittyPartyControllerVars.kreatorStake, 0);
        emit PartyCompleted(address(this), kittyPartyControllerVars.internalState);  
    }

    /// @dev mint receipt tokens via the Kitty Party Accountant, receipt tokens can be claimed from the treasury
    function mintTokens(
        address mintTo, 
        uint256 amount, 
        uint256 tokenType
    ) 
        private
    {
        require(mintTo != address(0));
        bytes memory payload = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)", 
            mintTo, 
            tokenType, 
            amount, 
            ""
        );
        // for kittyPartyControllerVars.profit to be calculated we need to unwind the position succesfuly the kittyPartyControllerVarsprofit - X% to kreator and Y% to contract becomes the winning
        (bool success,) = address(kPFactory.accountantContract).call(payload);
        require(success);
    }

    function batchMintReceiptTokens(
        uint256[] memory kittenIndexes,
        uint256 amountToSend
    )
        private
    {
        bytes memory payload = abi.encodeWithSignature(
            "mintToKittens(address,address,uint256[],uint256)",
            kPFactory.litterAddress,
            address(this), 
            kittenIndexes, 
            amountToSend
        );

        (bool success,) = address(kPFactory.accountantContract).call(payload);
        require(success, "Batch receipt failed");
    }

    /// @dev if the MIN_KITTENS have not joined in time, the kreator can seek refund before the internal state changes to party started
    function issueRefund() 
        external
        onlyKreator
    {
        require(stage != KittyPartyStages.Payout, "Cannot refund in payout");
        require(stage != KittyPartyStages.Completed, "Cannot refund in Completed");
        require(kittyPartyControllerVars.internalState  != 3, "Cannot refund");
        kittyPartyControllerVars.internalState = 3; // set the party as finished
        _nextStage(5);

        if(kittyPartyControllerVars.localKittens > 0) {
            IKittyPartyYieldGenerator(kittyInitiator.yieldContract).unwindLockedValue(callDataForUnwind);
            batchMintReceiptTokens(partyRoundKittens, kittyInitiator.amountInDAIPerRound);
            delete partyRoundKittens;//clear the current round participants
        }
        // The fees here are taking into account a sybil attack
        uint kreatorRefundedAmount = kittyPartyControllerVars.kreatorStake * kittyInitiator.daoFeesInBasisPoints / 100;
        mintTokens(kittyPartyControllerVars.kreator, kreatorRefundedAmount, 0);
        emit RefundRequested(kreatorRefundedAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IKittenPartyInit {
    struct KittyInitiator { 
        uint8 kreatorFeesInBasisPoints;
        uint8 daoFeesInBasisPoints;
        uint8 winningStrategy;
        uint8 timeToCollection; 
        uint16 maxKittens;
        uint16 durationInDays;
        uint256 amountInDAIPerRound;
        bytes32 partyName;
        address daiAddress;
        address yieldContract; 
        address winnerStrategy; 
    }

    struct KittyYieldArgs {
        address sellTokenAddress;
        address lpTokenAddress;
    }
    
    struct KittyPartyFactoryArgs {
        address tomCatContract;
        address accountantContract;
        address litterAddress;
        address daoTreasuryContract;
        address keeperContractAddress;
    }

    struct KittyPartyControllerVars {
        address kreator;
        uint256 kreatorStake;
        uint profit;
        uint profitToSplit;
        // The number of kittens inside that party
        uint8 localKittens;
        // A state representing whether the party has started and completed
        uint8 internalState;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Kitty Party Accountant
 */

interface IKittyPartyAccountant {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function setupMinter(address kittyParty) external returns(bool); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKittyPartyKeeper {
    function addKPController(address kpController) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

contract KittyPartyStateTransition {

    enum KittyPartyStages {
        InitialCollection,
        Collection,
        Staking,
        Payout,
        Completed,
        Refund
    }   
    //Set of valid states for the kitty party contract
    //InitialCollection: This collection is different because it is before start of the rounds
    //Collection: Pre-Round verification completed, collection criteria can be checked for
    //Staking: The colection has been completed successfully, the asset can now be staked on respective protocols, we open up for bids in this state
    //Payout: The assets are withdrawn from the repective contracts, a winner is chosen at random
    //Completed: The kitty-party is over
    //Refund: Invalid state jump goto Refund -> create a provision to exit system for all stakeholders and refund only allowed to transition from Initial Collection
    KittyPartyStages public stage = KittyPartyStages.InitialCollection;
    //initial state is verification state
    uint256 public lastStageTime;
    uint16 public durationInDays;
    uint8 public currentRound;
    uint8 public timeToCollection;
    uint16 public numberOfRounds;

    event Completed();
    event StageTransition(address party, uint prevStage, uint nextStage);
    
    modifier transitionAfter() {
        _;
        _nextStage(1);
    }
    
    function getStage() external view returns (uint) {
      return uint(stage);
    }

    function timeSinceChange() external view returns (uint) {
        return block.timestamp - lastStageTime;
    }

    function _atStage(KittyPartyStages _stage) internal view {
        require(stage == _stage, "Not in the expected stage");
    }

    function isTransitionRequired() external view returns(uint8) {
        if ((stage == KittyPartyStages.InitialCollection && (block.timestamp >= (lastStageTime + (timeToCollection * 1 days)))) ||
            (stage == KittyPartyStages.Collection && block.timestamp >= (lastStageTime + (24 * 1 hours))) ||
            (stage == KittyPartyStages.Staking && block.timestamp >= (lastStageTime + (durationInDays * 1 days))) ||
            (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds > currentRound)) ||
            (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds <= currentRound))) {
            return (uint8(stage) + (uint8(stage) <= 2 ? 0:(numberOfRounds > currentRound ? 0 : 1)));
        } else {
            return (88);
        }
    }
    
    function _timedTransitions() internal {
        if (stage == KittyPartyStages.InitialCollection && (block.timestamp >= (lastStageTime + (timeToCollection * 1 days)))) {
           _nextStage(2);
        }
        else if (stage == KittyPartyStages.Collection && block.timestamp >= (lastStageTime + (24 * 1 hours))) {
            _nextStage(1);
        }
        else if (stage == KittyPartyStages.Staking && block.timestamp >= (lastStageTime + (durationInDays * 1 days))) {
            _nextStage(1);
        }
        else if (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds > currentRound)) {
            stage = KittyPartyStages(1);
            currentRound++;
        }
        else if (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds <= currentRound)) {
           _nextStage(1);
        }
    }

    function _nextStage(uint8 jumpTo) internal {
        uint nextStageValue = uint(stage) + jumpTo;
        if(nextStageValue > 6){
            nextStageValue = 6;
        }
        emit StageTransition(address(this), uint(stage), nextStageValue);
        stage = KittyPartyStages(nextStageValue);
        lastStageTime = block.timestamp;
    }

    function _initState(uint8 _timeToCollection) internal {
        require(stage ==  KittyPartyStages.InitialCollection, "Not in the InitialCollection stage");
        lastStageTime = block.timestamp;
        timeToCollection = _timeToCollection;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Kitty Party Yield Generator
 */
interface IKittyPartyWinnerStrategy {
function initiateCheckWinner(uint _numberOfKittens) external;
function getWinners() external view returns (uint256[] memory);
function getWinnerAtLocation(uint i) external view returns (uint256);
function getLength() external view returns (uint);
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Kitty Party Yield Generator
 */
interface IKittyPartyYieldGenerator {
    struct KittyPartyYieldInfo { 
      uint256 lockedAmount;
      uint256 yieldGeneratedInLastRound;
      address sellTokenAddress;
      address poolAddress;
      address lpTokenAddress;
    }
    
    /**
     * @dev Create a new LockedValue in the pool
     */
    function createLockedValue(bytes calldata) external payable returns (uint256);
 
    /**
     * @dev Unwind a LockedValue in the pool
     */
    function unwindLockedValue(bytes calldata) external returns (uint256);

    /**
     * @dev Returns the address of the treasury contract
     */
    function treasuryAddress() external view returns (address);

    /**
     * @dev Returns the amount of tokens staked for a specific kitty party.
     */
    function lockedAmount(address) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens staked for a specific kitty party.
     */
    function yieldGenerated(address) external view returns (uint256);

    /**
     * @dev Returns the pool in which the kitty party tokens were staked
     */
    function lockedPool(address) external view returns (address);

    /**
     * @dev Returns the pool in which the kitty party tokens were staked
     */
    function setPlatformRewardContractAddress(address payable,address) external;
    function setPlatformDepositContractAddress(address payable) external;
    function setPlatformWithdrawContractAddress(address payable) external;
    function setPartyInfo(address, address) external;
}