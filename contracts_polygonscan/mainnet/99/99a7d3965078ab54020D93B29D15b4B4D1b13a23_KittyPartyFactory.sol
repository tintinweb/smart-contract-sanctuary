// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import './KittyPartyController.sol';
import './interfaces/IKittyPartyInit.sol';

contract KittyPartyFactory is IKittenPartyInit, IERC1155Receiver {

    KittyPartyFactoryArgs public kPFactory;

    mapping(address => address[]) public myKitties;

    bool public shouldReject;

    bytes public lastData;
    address public lastOperator;
    address public lastFrom;
    uint256 public lastId;
    uint256 public lastValue;

    uint8 public kreatorFeesInBasisPoints = 100;
    uint8 public daoFeesInBasisPoints = 100;
   
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81;

    event KittyLive(address indexed kreator, address kitty, bytes32 kittyPartyName);
    
    modifier onlyDAOAddress(){
        require(msg.sender == kPFactory.daoAddress);
        _;
    }

    constructor(
        KittyPartyFactoryArgs memory _kPFactory
    )   {
        kPFactory = _kPFactory;
    }
    
    function setKreatorFees(uint8 _kreatorFeesInBasisPoints) external onlyDAOAddress {
        kreatorFeesInBasisPoints = _kreatorFeesInBasisPoints;
    }

    function setDAOFees(uint8 _daoFeesInBasisPoints) external onlyDAOAddress {
        daoFeesInBasisPoints = _daoFeesInBasisPoints;
    }
    
    /// @dev A factory that creates a Kitty Party, any user can create a PLANETARY factory
    /// @notice Kitty Party is a community not a single pool so limit no of Kittens/pool
    function createKitty(
         KittyInitiator calldata _kittyInitiator,
         KittyYieldArgs calldata _kittyYieldArgs
    )
        external
        returns (address kittyAddress)
    {
        address kitty = ClonesUpgradeable.clone(kPFactory.tomCatContract);
        (bool success,) = address(kPFactory.accountantContract).call(abi.encodeWithSignature("setupMinter(address)", kitty));
        require(success, "Not able to set minter");
        require(_kittyInitiator.maxKittens <= 20, "Too many Kittens");
        
        IERC20 dai = IERC20(_kittyInitiator.daiAddress);
        uint256 allowance = dai.allowance(msg.sender, address(this));

        //require minimum stake from kreator
        require(allowance >= _kittyInitiator.amountInDAIPerRound / 10, "Min 10% req as Stake");
        require(_kittyInitiator.amountInDAIPerRound >= 20 * 10 ** 18, "Min $20 req as Stake");
        require(dai.transferFrom(msg.sender, address(_kittyInitiator.yieldContract), allowance), "Kreator stake fail");
        require(_kittyInitiator.kreatorFeesInBasisPoints <= kreatorFeesInBasisPoints);// you cannot charge more fees than guidance
        require(_kittyInitiator.daoFeesInBasisPoints <= daoFeesInBasisPoints);
        
        KittyPartyController(kitty).initialize(
            _kittyInitiator,
            _kittyYieldArgs,
            kPFactory,
            msg.sender, 
            allowance
        );

        //Add the created factory to the active kitty party list
        myKitties[msg.sender].push(kitty);
        emit KittyLive(msg.sender, kitty, _kittyInitiator.partyName);

        (bool successLitter,) = address(kPFactory.litterAddress).call(abi.encodeWithSignature("setupKittyParty(address)", kitty));
        require(successLitter, "Not able to set KittyParty role!");
        
        return kitty;
    }
     
    function getMyKitties(address candidateAddress) external view returns (address[] memory) {
        return myKitties[candidateAddress];
    }

    function setShouldReject(bool _value) public {
        shouldReject = _value;
    }

    function onERC1155Received(
        address _operator, 
        address _from, 
        uint256 _id, 
        uint256 _value, 
        bytes calldata _data
    ) 
        external 
        override
        returns (bytes4) 
    {
        lastOperator = _operator;
        lastFrom = _from;
        lastId = _id;
        lastValue = _value;
        lastData = _data;
        if (shouldReject == true) {
            revert("onERC1155Received: transfer not accepted");
        } else {
            return ERC1155_ACCEPTED;
        }
    }

    function onERC1155BatchReceived(
        address _operator, 
        address _from, 
        uint256[] calldata _ids, 
        uint256[] calldata _values, 
        bytes calldata _data
    ) 
        external 
        override
        returns (bytes4) 
    {
        lastOperator = _operator;
        lastFrom = _from;
        lastId = _ids[0];
        lastValue = _values[0];
        lastData = _data;
        if (shouldReject == true) {
            revert("onERC1155BatchReceived: transfer not accepted");
        } else {
            return ERC1155_BATCH_ACCEPTED;
        }
    }

    // ERC165 interface support
    function supportsInterface(bytes4 interfaceID) 
        external 
        pure 
        override 
        returns (bool) 
    {
        return  interfaceID == 0x01ffc9a7 ||    // ERC165
                interfaceID == 0x4e2312e0;      // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
    }


    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

    IKittyPartyWinnerStrategy kpWinnerSelectStrategy;

    KittyInitiator public kittyInitiator;
    KittyPartyFactoryArgs public kPFactory;
    KittyPartyControllerVars public kittyPartyControllerVars;

    IERC20 public dai;
    bytes public calldataForLock;
    bytes public callDataForUnwind;

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
        require(success, "NK");
        
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
    }

    ///@dev This is called by the kreator once the kreator verifies that all the kittens have deposited initial amount for the first round.
    function applyInitialVerification() 
        external
        minimumKittens(kittyPartyControllerVars.localKittens)
    {
        //TODO: split this logic so that there is more flexibility, that is keep no of rounds separate from no of Kittens
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

    ///@dev this is where the receipts are given to the winners to redeem the actual amount from the treasury contract
    function applyWinnerStrategy() external {
        _atStage(KittyPartyStages.Payout);
        require(kittyPartyControllerVars.profitToSplit > 0);

        uint amountToSend =  (kittyPartyControllerVars.profitToSplit 
                                / kpWinnerSelectStrategy.getLength());
        kittyPartyControllerVars.profitToSplit = 0;
        uint[] memory winners = kpWinnerSelectStrategy.getWinners();
        bytes memory payload = abi.encodeWithSignature(
            "mintToWinners(address,address,address,uint256[],uint256)",
            kittyPartyControllerVars.kreator,
            kPFactory.litterAddress,
            address(this), 
            winners, 
            amountToSend
        );

        (bool success,) = address(kPFactory.accountantContract).call(payload);
        require(success, "YE2");
        emit WinnersDecided(address(this), winners);
    }
    
    ///@dev This is to be called after party completion to mint the NFT's and tokens to the kittens and kreator
    function applyCompleteParty() external {
        _timedTransitions();
        _atStage(KittyPartyStages.Completed);
        require(kittyPartyControllerVars.internalState == 2);
        kittyPartyControllerVars.internalState = 3;
        bytes memory payload = abi.encodeWithSignature(
            "transferBadgesOnCompletion(address,address)", 
            kPFactory.litterAddress,
            address(this)
        );
        (bool success,) = address(kPFactory.accountantContract).call(payload);
        require(success);

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

    /// @dev if the MIN_KITTENS have not joined in time, the kreator can seek refund before the internal state changes to party started
    function checkRefund() 
        external
        onlyKreator
    {
        require(kittyPartyControllerVars.localKittens < MIN_KITTENS, "No refund possible");
        require(kittyPartyControllerVars.internalState == 1, "No refund possible"); //as long as verification was not done
        kittyPartyControllerVars.internalState = 3; // set the party as finished
        _nextStage(5);

        if(kittyPartyControllerVars.localKittens > 0) {
            uint refund = kittyPartyControllerVars.localKittens * kittyInitiator.amountInDAIPerRound;
            IKittyPartyYieldGenerator(kittyInitiator.yieldContract).unwindLockedValue(callDataForUnwind);
            mintTokens(kittyPartyControllerVars.kreator, refund, 0);
            emit RefundRequested(refund);
        }
        mintTokens(kittyPartyControllerVars.kreator, kittyPartyControllerVars.kreatorStake, 0);   
    }
}

// SPDX-License-Identifier: BSL
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
        address daoAddress;
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
    event StageTransition(uint prevStage, uint nextStage);
    
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
            (stage == KittyPartyStages.Collection && block.timestamp >= (lastStageTime + (3 * 1 hours))) ||
            (stage == KittyPartyStages.Staking && block.timestamp >= (lastStageTime + (durationInDays * 1 days))) ||
            (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds > currentRound)) ||
            (stage == KittyPartyStages.Payout && block.timestamp >= (lastStageTime + (8 * 1 hours)) && (numberOfRounds <= currentRound))) {
            return (uint8(stage) + (numberOfRounds > currentRound ? 0 : 1));
        } else {
            return (88);
        }
    }
    
    function _timedTransitions() internal {
        if (stage == KittyPartyStages.InitialCollection && (block.timestamp >= (lastStageTime + (timeToCollection * 1 days)))) {
           _nextStage(2);
        }
        else if (stage == KittyPartyStages.Collection && block.timestamp >= (lastStageTime + (3 * 1 hours))) {
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
        emit StageTransition(uint(stage), nextStageValue);
        stage = KittyPartyStages(nextStageValue);
        lastStageTime = block.timestamp;
    }

    function _initState(uint8 _timeToCollection) internal {
        require(stage ==  KittyPartyStages.InitialCollection, "Not in the InitialCollection stage");
        lastStageTime = block.timestamp;
        timeToCollection = _timeToCollection;
    }
}

// SPDX-License-Identifier: BSL
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
    function setPlatformRewardContractAddress(address payable) external;
    function setPlatformDepositContractAddress(address payable) external;
    function setPlatformWithdrawContractAddress(address payable) external;
    function setPartyInfo(address, address) external;
}