pragma solidity ^0.4.24;

// File: Multiownable/contracts/Multiownable.sol

contract Multiownable {

    // VARIABLES

    uint256 public ownersGeneration;
    uint256 public howManyOwnersDecide;
    address[] public owners;
    bytes32[] public allOperations;
    address internal insideCallSender;
    uint256 internal insideCallCount;

    // Reverse lookup tables for owners and allOperations
    mapping(address => uint) public ownersIndices; // Starts from 1
    mapping(bytes32 => uint) public allOperationsIndicies;

    // Owners voting mask per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;

    // EVENTS

    event OwnershipTransferred(address[] previousOwners, uint howManyOwnersDecide, address[] newOwners, uint newHowManyOwnersDecide);
    event OperationCreated(bytes32 operation, uint howMany, uint ownersCount, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint howMany, uint ownersCount, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany, uint ownersCount, address performer);
    event OperationDownvoted(bytes32 operation, uint votes, uint ownersCount,  address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller);
    
    // ACCESSORS

    function isOwner(address wallet) public constant returns(bool) {
        return ownersIndices[wallet] > 0;
    }

    function ownersCount() public constant returns(uint) {
        return owners.length;
    }

    function allOperationsCount() public constant returns(uint) {
        return allOperations.length;
    }

    // MODIFIERS

    /**
    * @dev Allows to perform method by any of the owners
    */
    modifier onlyAnyOwner {
        if (checkHowManyOwners(1)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = 1;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after many owners call it with the same arguments
    */
    modifier onlyManyOwners {
        if (checkHowManyOwners(howManyOwnersDecide)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howManyOwnersDecide;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after all owners call it with the same arguments
    */
    modifier onlyAllOwners {
        if (checkHowManyOwners(owners.length)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = owners.length;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after some owners call it with the same arguments
    */
    modifier onlySomeOwners(uint howMany) {
        require(howMany > 0, "onlySomeOwners: howMany argument is zero");
        require(howMany <= owners.length, "onlySomeOwners: howMany argument exceeds the number of owners");
        
        if (checkHowManyOwners(howMany)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howMany;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    // CONSTRUCTOR

    constructor() public {
        owners.push(msg.sender);
        ownersIndices[msg.sender] = 1;
        howManyOwnersDecide = 1;
    }

    // INTERNAL METHODS

    /**
     * @dev onlyManyOwners modifier helper
     */
    function checkHowManyOwners(uint howMany) internal returns(bool) {
        if (insideCallSender == msg.sender) {
            require(howMany <= insideCallCount, "checkHowManyOwners: nested owners modifier check require more owners");
            return true;
        }

        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require(ownerIndex < owners.length, "checkHowManyOwners: msg.sender is not an owner");
        bytes32 operation = keccak256(msg.data, ownersGeneration);

        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0, "checkHowManyOwners: owner already voted for the operation");
        votesMaskByOperation[operation] |= (2 ** ownerIndex);
        uint operationVotesCount = votesCountByOperation[operation] + 1;
        votesCountByOperation[operation] = operationVotesCount;
        if (operationVotesCount == 1) {
            allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);
            emit OperationCreated(operation, howMany, owners.length, msg.sender);
        }
        emit OperationUpvoted(operation, operationVotesCount, howMany, owners.length, msg.sender);

        // If enough owners confirmed the same operation
        if (votesCountByOperation[operation] == howMany) {
            deleteOperation(operation);
            emit OperationPerformed(operation, howMany, owners.length, msg.sender);
            return true;
        }

        return false;
    }

    /**
    * @dev Used to delete cancelled or performed operation
    * @param operation defines which operation to delete
    */
    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (index < allOperations.length - 1) { // Not last
            allOperations[index] = allOperations[allOperations.length - 1];
            allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length--;

        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
    }

    // PUBLIC METHODS

    /**
    * @dev Allows owners to change their mind by cacnelling votesMaskByOperation operations
    * @param operation defines which operation to delete
    */
    function cancelPending(bytes32 operation) public onlyAnyOwner {
        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) != 0, "cancelPending: operation not found for this user");
        votesMaskByOperation[operation] &= ~(2 ** ownerIndex);
        uint operationVotesCount = votesCountByOperation[operation] - 1;
        votesCountByOperation[operation] = operationVotesCount;
        emit OperationDownvoted(operation, operationVotesCount, owners.length, msg.sender);
        if (operationVotesCount == 0) {
            deleteOperation(operation);
            emit OperationCancelled(operation, msg.sender);
        }
    }

    /**
    * @dev Allows owners to change ownership
    * @param newOwners defines array of addresses of new owners
    */
    function transferOwnership(address[] newOwners) public {
        transferOwnershipWithHowMany(newOwners, newOwners.length);
    }

    /**
    * @dev Allows owners to change ownership
    * @param newOwners defines array of addresses of new owners
    * @param newHowManyOwnersDecide defines how many owners can decide
    */
    function transferOwnershipWithHowMany(address[] newOwners, uint256 newHowManyOwnersDecide) public onlyManyOwners {
        require(newOwners.length > 0, "transferOwnershipWithHowMany: owners array is empty");
        require(newOwners.length <= 256, "transferOwnershipWithHowMany: owners count is greater then 256");
        require(newHowManyOwnersDecide > 0, "transferOwnershipWithHowMany: newHowManyOwnersDecide equal to 0");
        require(newHowManyOwnersDecide <= newOwners.length, "transferOwnershipWithHowMany: newHowManyOwnersDecide exceeds the number of owners");

        // Reset owners reverse lookup table
        for (uint j = 0; j < owners.length; j++) {
            delete ownersIndices[owners[j]];
        }
        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0), "transferOwnershipWithHowMany: owners array contains zero");
            require(ownersIndices[newOwners[i]] == 0, "transferOwnershipWithHowMany: owners array contains duplicates");
            ownersIndices[newOwners[i]] = i + 1;
        }
        
        emit OwnershipTransferred(owners, howManyOwnersDecide, newOwners, newHowManyOwnersDecide);
        owners = newOwners;
        howManyOwnersDecide = newHowManyOwnersDecide;
        allOperations.length = 0;
        ownersGeneration++;
    }

}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/BadERC20Aware.sol

library BadERC20Aware {
    using SafeMath for uint;

    function isContract(address addr) internal view returns(bool result) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            result := gt(extcodesize(addr), 0)
        }
    }

    function handleReturnBool() internal pure returns(bool result) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            switch returndatasize()
            case 0 { // not a std erc20
                result := 1
            }
            case 32 { // std erc20
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default { // anything else, should revert for safety
                revert(0, 0)
            }
        }
    }

    function asmTransfer(ERC20 _token, address _to, uint256 _value) internal returns(bool) {
        require(isContract(_token));
        // solium-disable-next-line security/no-low-level-calls
        require(address(_token).call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));
        return handleReturnBool();
    }

    function safeTransfer(ERC20 _token, address _to, uint256 _value) internal {
        require(asmTransfer(_token, _to, _value));
    }
}

// File: contracts/TokenSwap.sol

/**
 * @title TokenSwap
 * This product is protected under license.  Any unauthorized copy, modification, or use without
 * express written consent from the creators is prohibited.
 */







contract TokenSwap is Ownable, Multiownable {

    // LIBRARIES

    using BadERC20Aware for ERC20;
    using SafeMath for uint256;

    // TYPES

    enum Status {AddParties, WaitingDeposits, SwapConfirmed, SwapCanceled}

    struct SwapOffer {
        address participant;
        ERC20 token;

        uint256 tokensForSwap;
        uint256 withdrawnTokensForSwap;

        uint256 tokensFee;
        uint256 withdrawnFee;

        uint256 tokensTotal;
        uint256 withdrawnTokensTotal;
    }

    struct LockupStage {
        uint256 secondsSinceLockupStart;
        uint8 unlockedTokensPercentage;
    }

    // VARIABLES
    Status public status = Status.AddParties;

    uint256 internal startLockupAt;
    LockupStage[] internal lockupStages;

    address[] internal participants;
    mapping(address => bool) internal isParticipant;
    mapping(address => address) internal tokenByParticipant;
    mapping(address => SwapOffer) internal offerByToken;

    // EVENTS
    event AddLockupStage(uint256 secondsSinceLockupStart, uint8 unlockedTokensPercentage);
    event StatusUpdate(Status oldStatus, Status newStatus);
    event AddParty(address participant, ERC20 token, uint256 amount);
    event RemoveParty(address participant);
    event ConfirmParties();
    event CancelSwap();
    event ConfirmSwap();
    event StartLockup(uint256 startLockupAt);
    event Withdraw(address participant, ERC20 token, uint256 amount);
    event WithdrawFee(ERC20 token, uint256 amount);
    event Reclaim(address participant, ERC20 token, uint256 amount);

    // MODIFIERS
    modifier onlyParticipant {
        require(
            isParticipant[msg.sender] == true,
            "Only swap participants allowed to call the method"
        );
        _;
    }

    modifier canAddParty {
        require(status == Status.AddParties, "Unable to add new parties in the current status");
        _;
    }

    modifier canRemoveParty {
        require(status == Status.AddParties, "Unable to remove parties in the current status");
        _;
    }

    modifier canConfirmParties {
        require(
            status == Status.AddParties,
            "Unable to confirm parties in the current status"
        );
        require(participants.length > 1, "Need at least two participants");
        _;
    }

    modifier canCancelSwap {
        require(
            status == Status.WaitingDeposits,
            "Unable to cancel swap in the current status"
        );
        _;
    }

    modifier canConfirmSwap {
        require(status == Status.WaitingDeposits, "Unable to confirm in the current status");
        require(
            _haveEveryoneDeposited(),
            "Unable to confirm swap before all parties have deposited tokens"
        );
        _;
    }

    modifier canWithdraw {
        require(status == Status.SwapConfirmed, "Unable to withdraw tokens in the current status");
        require(startLockupAt != 0, "Lockup has not been started");
        _;
    }

    modifier canWithdrawFee {
        require(status == Status.SwapConfirmed, "Unable to withdraw fee in the current status");
        require(startLockupAt != 0, "Lockup has not been started");
        _;
    }

    modifier canReclaim {
        require(
            status == Status.SwapConfirmed || status == Status.SwapCanceled,
            "Unable to reclaim in the current status"
        );
        _;
    }

    // CONSTRUCTOR
    constructor() public {
        _initializeLockupStages();
        _validateLockupStages();
    }

    // EXTERNAL METHODS
    /**
     * @dev Add new party to the swap.
     * @param _participant Address of the participant.
     * @param _token An ERC20-compliant token which participant is offering to swap.
     * @param _tokensForSwap How much tokens the participant wants to swap.
     * @param _tokensFee How much tokens will be payed as a fee.
     * @param _tokensTotal How much tokens the participant is offering (i.e. _tokensForSwap + _tokensFee).
     */
    function addParty(
        address _participant,
        ERC20 _token,
        uint256 _tokensForSwap,
        uint256 _tokensFee,
        uint256 _tokensTotal
    )
        external
        onlyOwner
        canAddParty
    {
        require(_participant != address(0), "_participant is invalid address");
        require(_token != address(0), "_token is invalid address");
        require(_tokensForSwap > 0, "_tokensForSwap must be positive");
        require(_tokensFee > 0, "_tokensFee must be positive");
        require(_tokensTotal == _tokensForSwap.add(_tokensFee), "token amounts inconsistency");
        require(
            isParticipant[_participant] == false,
            "Unable to add the same party multiple times"
        );

        isParticipant[_participant] = true;
        SwapOffer memory offer = SwapOffer({
            participant: _participant,
            token: _token,
            tokensForSwap: _tokensForSwap,
            withdrawnTokensForSwap: 0,
            tokensFee: _tokensFee,
            withdrawnFee: 0,
            tokensTotal: _tokensTotal,
            withdrawnTokensTotal: 0
        });
        participants.push(offer.participant);
        offerByToken[offer.token] = offer;
        tokenByParticipant[offer.participant] = offer.token;

        emit AddParty(offer.participant, offer.token, offer.tokensTotal);
    }

    /**
     * @dev Remove party.
     * @param _participantIndex Index of the participant in the participants array.
     */
    function removeParty(uint256 _participantIndex) external onlyOwner canRemoveParty {
        require(_participantIndex < participants.length, "Participant does not exist");

        address participant = participants[_participantIndex];
        address token = tokenByParticipant[participant];

        delete isParticipant[participant];
        participants[_participantIndex] = participants[participants.length - 1];
        participants.length--;
        delete offerByToken[token];
        delete tokenByParticipant[participant];

        emit RemoveParty(participant);
    }

    /**
     * @dev Confirm swap parties
     */
    function confirmParties() external onlyOwner canConfirmParties {
        address[] memory newOwners = new address[](participants.length + 1);

        for (uint256 i = 0; i < participants.length; i++) {
            newOwners[i] = participants[i];
        }

        newOwners[newOwners.length - 1] = owner;
        transferOwnershipWithHowMany(newOwners, newOwners.length - 1);
        _changeStatus(Status.WaitingDeposits);
        emit ConfirmParties();
    }

    /**
     * @dev Confirm swap.
     */
    function confirmSwap() external canConfirmSwap onlyManyOwners {
        emit ConfirmSwap();
        _changeStatus(Status.SwapConfirmed);
        _startLockup();
    }

    /**
     * @dev Cancel swap.
     */
    function cancelSwap() external canCancelSwap onlyManyOwners {
        emit CancelSwap();
        _changeStatus(Status.SwapCanceled);
    }

    /**
     * @dev Withdraw tokens
     */
    function withdraw() external onlyParticipant canWithdraw {
        for (uint i = 0; i < participants.length; i++) {
            address token = tokenByParticipant[participants[i]];
            SwapOffer storage offer = offerByToken[token];

            if (offer.participant == msg.sender) {
                continue;
            }

            uint256 tokenReceivers = participants.length - 1;
            uint256 tokensAmount = _withdrawableAmount(offer).div(tokenReceivers);

            offer.token.safeTransfer(msg.sender, tokensAmount);
            emit Withdraw(msg.sender, offer.token, tokensAmount);
            offer.withdrawnTokensForSwap = offer.withdrawnTokensForSwap.add(tokensAmount);
            offer.withdrawnTokensTotal = offer.withdrawnTokensTotal.add(tokensAmount);
        }
    }

    /**
     * @dev Withdraw swap fee
     */
    function withdrawFee() external onlyOwner canWithdrawFee {
        for (uint i = 0; i < participants.length; i++) {
            address token = tokenByParticipant[participants[i]];
            SwapOffer storage offer = offerByToken[token];

            uint256 tokensAmount = _withdrawableFee(offer);

            offer.token.safeTransfer(msg.sender, tokensAmount);
            emit WithdrawFee(offer.token, tokensAmount);
            offer.withdrawnFee = offer.withdrawnFee.add(tokensAmount);
            offer.withdrawnTokensTotal = offer.withdrawnTokensTotal.add(tokensAmount);
        }
    }

    /**
     * @dev Reclaim tokens if a participant has deposited too much or if the swap has been canceled.
     */
    function reclaim() external onlyParticipant canReclaim {
        address token = tokenByParticipant[msg.sender];

        SwapOffer storage offer = offerByToken[token];
        uint256 currentBalance = offer.token.balanceOf(address(this));
        uint256 availableForReclaim = currentBalance
            .sub(offer.tokensTotal.sub(offer.withdrawnTokensTotal));

        if (status == Status.SwapCanceled) {
            availableForReclaim = currentBalance;
        }

        if (availableForReclaim > 0) {
            offer.token.safeTransfer(offer.participant, availableForReclaim);
        }

        emit Reclaim(offer.participant, offer.token, availableForReclaim);
    }

    // INTERNAL METHODS
    /**
     * @dev Initialize lockup period stages.
     */
    function _initializeLockupStages() internal {
        _addLockupStage(LockupStage(0, 10));
        _addLockupStage(LockupStage(60 days, 20));
        _addLockupStage(LockupStage(90 days, 40));
        _addLockupStage(LockupStage(120 days, 60));
        _addLockupStage(LockupStage(150 days, 80));
        _addLockupStage(LockupStage(180 days, 100));
    }

    /**
     * @dev Add lockup period stage
     */
    function _addLockupStage(LockupStage _stage) internal {
        emit AddLockupStage(_stage.secondsSinceLockupStart, _stage.unlockedTokensPercentage);
        lockupStages.push(_stage);
    }

    /**
     * @dev Validate lock-up period configuration.
     */
    function _validateLockupStages() internal view {
        for (uint i = 0; i < lockupStages.length; i++) {
            LockupStage memory stage = lockupStages[i];

            require(
                stage.unlockedTokensPercentage >= 0,
                "LockupStage.unlockedTokensPercentage must not be negative"
            );
            require(
                stage.unlockedTokensPercentage <= 100,
                "LockupStage.unlockedTokensPercentage must not be greater than 100"
            );

            if (i == 0) {
                continue;
            }

            LockupStage memory previousStage = lockupStages[i - 1];
            require(
                stage.secondsSinceLockupStart > previousStage.secondsSinceLockupStart,
                "LockupStage.secondsSinceLockupStart must increase monotonically"
            );
            require(
                stage.unlockedTokensPercentage > previousStage.unlockedTokensPercentage,
                "LockupStage.unlockedTokensPercentage must increase monotonically"
            );
        }

        require(
            lockupStages[0].secondsSinceLockupStart == 0,
            "The first lockup stage must start immediately"
        );
        require(
            lockupStages[lockupStages.length - 1].unlockedTokensPercentage == 100,
            "The last lockup stage must unlock 100% of tokens"
        );
    }

    /**
     * @dev Change swap status.
     */
    function _changeStatus(Status _newStatus) internal {
        emit StatusUpdate(status, _newStatus);
        status = _newStatus;
    }

    /**
     * @dev Check whether every participant has deposited enough tokens for the swap to be confirmed.
     */
    function _haveEveryoneDeposited() internal view returns(bool) {
        for (uint i = 0; i < participants.length; i++) {
            address token = tokenByParticipant[participants[i]];
            SwapOffer memory offer = offerByToken[token];

            if (offer.token.balanceOf(address(this)) < offer.tokensTotal) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Start lockup period
     */
    function _startLockup() internal {
        startLockupAt = now;
        emit StartLockup(startLockupAt);
    }

    /**
     * @dev Find amount of tokens ready to be withdrawn by a swap party.
     */
    function _withdrawableAmount(SwapOffer _offer) internal view returns(uint256) {
        return _unlockedAmount(_offer.tokensForSwap).sub(_offer.withdrawnTokensForSwap);
    }

    /**
     * @dev Find amount of tokens ready to be withdrawn as the swap fee.
     */
    function _withdrawableFee(SwapOffer _offer) internal view returns(uint256) {
        return _unlockedAmount(_offer.tokensFee).sub(_offer.withdrawnFee);
    }

    /**
     * @dev Find amount of unlocked tokens, including withdrawn tokens.
     */
    function _unlockedAmount(uint256 totalAmount) internal view returns(uint256) {
        return totalAmount.mul(_getUnlockedTokensPercentage()).div(100);
    }

    /**
     * @dev Get percent of unlocked tokens
     */
    function _getUnlockedTokensPercentage() internal view returns(uint256) {
        for (uint256 i = lockupStages.length; i > 0; i--) {
            LockupStage storage stage = lockupStages[i - 1];
            uint256 stageBecomesActiveAt = startLockupAt.add(stage.secondsSinceLockupStart);

            if (now < stageBecomesActiveAt) {
                continue;
            }

            return stage.unlockedTokensPercentage;
        }
    }
}