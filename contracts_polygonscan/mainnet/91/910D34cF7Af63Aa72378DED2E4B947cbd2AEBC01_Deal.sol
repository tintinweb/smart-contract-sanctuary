// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../openzeppelin/Safemath.sol";
import "../openzeppelin/IERC20.sol";
import "./CollateralManager.sol";
import "./FeeManager.sol";
import "./DealStorage.sol";

contract Deal is DealStorage, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ListGig(address indexed client, uint indexed dealId, uint reward, uint32 timeToAcceptInMinutes, string gigCid);
    event DelistGig(address indexed client, uint indexed dealId);
    event DealFirstConfirmation(address indexed client, address indexed freelancer, uint indexed dealId, uint32 deadline, uint collateral, uint reward, string gigCid,
                                uint32 timeToReviseInMinutes, uint8 numRevisionsRemaining);
    event DealSecondConfirmation(address indexed freelancer, uint indexed dealId);
    event GigSubmitted(address indexed freelancer, uint indexed dealId, string submission, uint32 acceptanceDeadline);
    event GigAccepted(address indexed client, address indexed freelancer, uint indexed dealId, string feedback);
    event ConfirmationDeadlineViolation(address indexed client, address indexed freelancer, uint dealId);
    event SubmissionDeadlineViolation(address indexed client, address indexed freelancer, uint dealId);
    event AcceptanceDeadlineViolation(address indexed client, address indexed freelancer, uint dealId);
    event Revision(address indexed client, address indexed freelancer, uint indexed dealId, string instruction);
    event Dispute(address indexed client, address indexed freelancer, uint indexed dealId, string evidence);
    event Ruling(uint indexed dealId, address winner);
    event DisputeResolved(uint indexed dealId, address winner, address loser);

    address _tokenAddress;
    FeeManager _feeManager;
    CollateralManager _collateralManager;

    uint compensationPercentage = 30;
    constructor(
        address tokenAddress,
        address collateralManagerAddress,
        address feeManagerAddress
    ) {
        _tokenAddress = tokenAddress;
        _collateralManager = CollateralManager(collateralManagerAddress);
        _feeManager = FeeManager(feeManagerAddress);
    }

    /**
     * @dev Check if msg sender is the client of the gig
     * @param dealId The unique identity of the gig
     **/
    modifier onlyClient(uint dealId) {
        require(deals[dealId].client == msg.sender, "Not client");
        _;
    }

    /**
     * @dev Check if msg sender is the contributor of the gig
     * @param dealId The unique identity of the gig
     **/
    modifier onlyFreelancer(uint dealId) {
        require(
            deals[dealId].freelancer == msg.sender,
            "Not freelancer"
        );
        _;
    }

    /**
     * @dev Check if gig is still active
     * @param dealId The unique identity of the gig
     **/
    modifier onlyWhenActive(uint dealId) {
        require(deals[dealId].active == true, "Gig is inactive");
        _;
    }

    /**
     * @dev List a gig thus initiating a deal. Fees and reward are escrowed on calling this.
     * @param reward Amount to pay as reward to freelancer
     * @param timeToAcceptInMinutes Time to accept submission in minutes
     **/
    function listGig(
        uint reward,
        uint32 timeToAcceptInMinutes,
        string memory gigCid
        ) external {
            Deadline memory deadline = Deadline(
                0, 0, 0
            );
            
            Deal memory deal = Deal(
                true,
                false,
                false,
                false,
                false,
                0,
                0,
                msg.sender,
                address(0),
                timeToAcceptInMinutes,
                deadline,
                0,
                reward,
                "",
                ""
            );

            deals.push(deal);
            uint dealId = deals.length - 1;

            uint fees = reward.mul(_feeManager.getFeePercentage()).div(100);
            _collateralManager.escrow(reward.add(fees), msg.sender, dealId);

            emit ListGig(msg.sender, dealId, reward, timeToAcceptInMinutes, gigCid);
    }

    /**
     * @dev Delists a gig that is still active and doesn't have a freelancer. 
     *      Gigs can also be delisted if freelancer fails to confirm deal within the confirmation deadline.
     *      - Can only be called by client
     * @param dealId Unique id of gig to delist
     **/
    function delistGig(uint dealId) external onlyClient(dealId) {
        require(deals[dealId].active == true, "Gig is already inactive");
        require(deals[dealId].freelancer == address(0) || deals[dealId].confirmationDeadlineViolated == true, "Freelancer already picked, cannot delist");
        deals[dealId].active  = false;
        _collateralManager.descrowAll(msg.sender, dealId);

        emit DelistGig(msg.sender, dealId);
    }

    /**
     * @dev This confirmation is sent by the client upon picking a freelancer's proposal
     * @param deadline Deadline to submit work
     * @param freelancer Address of freelancer whose proposal is picked
     * @param collateral Collateral to be locked by freelancer
     * @param dealId Unique Id of the deal thats being confirmed
     * @param gigCid IPFS hash containing the gig deliverable and other gig info that are too expensive to store on chain
     * @param timeToReviseInMinutes If client asks for revision, this is the minimum time in minutes before the next deadline to submit work
     * @param numRevisions Number of revisions that a client can ask for
     **/
    function firstConfirmation(
        uint32 deadline,
        address freelancer,
        uint collateral,
        uint dealId,
        string memory gigCid,
        uint32 timeToReviseInMinutes,
        uint8 numRevisions
    ) external onlyClient(dealId){
        require(deals[dealId].freelancer == address(0) || deals[dealId].confirmationDeadlineViolated == true, "Already picked a freelancer");
        require(deals[dealId].active == true, "Gig not active");

        deals[dealId].deadline.submissionDeadline = deadline;
        deals[dealId].deadline.confirmationDeadline = uint32(block.timestamp) + 1 days;
        deals[dealId].freelancer = freelancer;
        deals[dealId].collateral = collateral;
        deals[dealId].gigCid = gigCid;
        deals[dealId].timeToReviseInMinutes = timeToReviseInMinutes;
        deals[dealId].numRevisionsRemaining = numRevisions;
        deals[dealId].confirmationDeadlineViolated = false;
        emit DealFirstConfirmation(msg.sender, freelancer, dealId, deadline, collateral, getReward(dealId), gigCid, timeToReviseInMinutes, numRevisions);
    }

    /**
     * @dev This confirmation is sent by freelancer upon being picked to work on a certain gig. Before calling this, freelancers should make 
     *      sure all the deal parameters look right and only then confirm. After confirmation, the freelancer can make a submission
     * @param dealId The unique identity of the gig
     **/
    function secondConfirmation(uint dealId)
        external
        onlyFreelancer(dealId)
        onlyWhenActive(dealId)
    {
        require(deals[dealId].confirmationDeadlineViolated == false, "Confirmation deadline was violated");
        require(deals[dealId].confirmed == false, "Gig already confirmed");

        deals[dealId].confirmed = true;

        _collateralManager.lockCollateral(deals[dealId].freelancer, deals[dealId].collateral);

        emit DealSecondConfirmation(msg.sender, dealId);
    }

    /**
     * @dev This is called by freelancer when work is submitted or revised.
     * @param dealId The unique identity of the gig
     * @param submission The IPFS hash of the submission
     **/
    function submit(uint dealId, string memory submission)
        external
        onlyFreelancer(dealId)
        onlyWhenActive(dealId)
    {
        require(deals[dealId].confirmed == true, "Deal hasnt been confirmed yet");

        deals[dealId].submission = submission;
        deals[dealId].submitted = true;

        deals[dealId].deadline.acceptanceDeadline =
            uint32(block.timestamp) +
            (deals[dealId].timeToAcceptInMinutes * 1 minutes);

        emit GigSubmitted(msg.sender, dealId, submission, deals[dealId].deadline.acceptanceDeadline);
    }

    /**
     * @dev This is called by client when he accepts the work submitted
     * @param dealId The unique identity of the gig
     * @param feedback The IPFS hash of the feedback that could contain rating and comments about the work
     **/
    function accept(uint dealId, string memory feedback) external onlyClient(dealId) onlyWhenActive(dealId) {
        _fulfill(dealId);
        emit GigAccepted(msg.sender, deals[dealId].freelancer, dealId, feedback);
    }

    /**
     * @dev This can be called by client if the deadline to submit work has expired. It will refund the escrowed amount to client
     *      and slash the freelancers collateral giving a small percentage to client as compensation and burning the rest
     * @param dealId The unique identity of the gig
     **/
    function callSubmissionDeadlineViolation(uint dealId)
        external
        onlyClient(dealId)
        onlyWhenActive(dealId)
    {
        require(deals[dealId].submitted == false, "Already submitted");
        require(block.timestamp > deals[dealId].deadline.submissionDeadline, "Submission deadline hasnt been violated yet");

        uint collateral = deals[dealId].collateral;
        address freelancer = deals[dealId].freelancer;

        deals[dealId].active = false;
        _collateralManager.descrowAll(msg.sender, dealId);
        _collateralManager.increaseAllocation(msg.sender, getDeposit(dealId).add(collateral.mul(compensationPercentage).div(100)));
        _collateralManager.slashCollateral(freelancer, collateral);

        emit SubmissionDeadlineViolation(msg.sender, freelancer, dealId);
    }

    /**
     * @dev This can be called by client if the deadline to confirm has expired. The client can choose to pick another proposal or delist the gig
     *      and withdraw the escrowed amount
     * @param dealId The unique identity of the gig
     **/
    function callConfirmationDeadlineViolation(uint dealId)
        external
        onlyClient(dealId)
    {
        require(block.timestamp > deals[dealId].deadline.confirmationDeadline, "Confirmation deadline hasnt been violated yet");
        require(deals[dealId].confirmed == false, "Already confirmed deal");

        deals[dealId].confirmationDeadlineViolated = true;

        emit ConfirmationDeadlineViolation(msg.sender, deals[dealId].freelancer, dealId);
    }

    /**
     * @dev This can be called by freelancer if the deadline to accept his submitted work has expired. It will pay the escrowed amount for the gig
     * to the freelancer and automatically set the gig as completed
     * @param dealId The unique identity of the gig
     **/
    function callAcceptanceDeadlineViolation(uint dealId)
        external
        onlyFreelancer(dealId)
        onlyWhenActive(dealId)
    {
        require(deals[dealId].submitted == true, "Not submitted yet");
        require(deals[dealId].inDispute == false, "Cannot call deadline violation when gig is in dispute");
        require(block.timestamp > deals[dealId].deadline.acceptanceDeadline, "Acceptance deadline hasnt been violated yet");   
        
        _fulfill(dealId);
        
        emit AcceptanceDeadlineViolation(deals[dealId].client, msg.sender, dealId);
    }

    /**
     * @dev This is called on acceptance of submission or on acceptance deadline violation. Calling this will fulfill the freelancer's payment and 
     *      unlock freelancer's collateral.
     * @param dealId The unique identity of the gig
     **/
    function _fulfill(uint dealId) private
    {
        uint reward = deals[dealId].reward;
        deals[dealId].active = false;

        _collateralManager.unlockCollateral(deals[dealId].freelancer, deals[dealId].collateral);
        _collateralManager.descrow(reward, deals[dealId].freelancer, dealId);
        _collateralManager.descrowAll(owner(), dealId);
    }

    /**
     * @dev This can be called by client to ask for a revision
     * @param dealId The unique identity of the gig
     * @param instructions The IPFS hash containing revision instructions
     **/
    function revise(uint dealId, string memory instructions)
        external
        onlyClient(dealId)
    {
        require(deals[dealId].numRevisionsRemaining > 0, "No revisions left");
        deals[dealId].submitted = false;
        deals[dealId].deadline.submissionDeadline =
            uint32(block.timestamp) +
            (deals[dealId].timeToReviseInMinutes * 1 minutes);
        
        deals[dealId].numRevisionsRemaining -= 1;

        emit Revision(msg.sender, deals[dealId].freelancer, dealId, instructions);
    }

    /**
     * @dev This can be called by client to call dispute if submitted work is spam or doesnt address the deliverable at all. This would
     *      require the client to lock up collateral matching the collateral that was locked by freelancer when starting work.
     * @param dealId The unique identity of the gig
     * @param evidence The IPFS hash containing all info about the gig - deliverable, submission, deal parameters and revision instructions
     **/
    function callDispute(uint dealId, string memory evidence)
        external
        onlyClient(dealId)
        onlyWhenActive(dealId)
    {
        require(deals[dealId].inDispute == false, "Gig is already in dispute");
        require(deals[dealId].submitted == true, "No submission, cant call dispute");

        uint collateral = deals[dealId].collateral;
        deals[dealId].inDispute = true;

        _collateralManager.lockCollateral(msg.sender, collateral);

        emit Dispute(msg.sender, deals[dealId].freelancer, dealId, evidence);
    }

    /**
     * @dev This can be called by owner to resolve dispute in favor of client or freelancer. On resolution, the winner gets their collateral back 
     *      along with the escrowed amount. The loser's collateral is slashed and some of it is paid as compensation to winner and rest is burned.
     * @param dealId The unique identity of the gig
     * @param winner The winner of the dispute
     **/
    function resolveDispute(uint dealId, address winner)
        external
        onlyOwner
    {
        address client = deals[dealId].client;
        address freelancer = deals[dealId].freelancer;

        require(deals[dealId].inDispute == true, "Gig is not in dispute");
        require(winner == client || winner == freelancer, "Winner is neither client nor freelancer");
        
        address loser = client == winner ? freelancer : client;
        uint collateral = deals[dealId].collateral;
        uint compensationFee = (compensationPercentage * collateral) / 100;   // Used as compensation to the dispute winner for inconvenience

        deals[dealId].active = false;
        deals[dealId].inDispute = false;
        _collateralManager.unlockCollateral(
            winner,
            collateral
        );
        _collateralManager.slashCollateral(loser, collateral);

        _collateralManager.descrowAll(winner, dealId);
        _collateralManager.increaseAllocation(winner, compensationFee);

        emit DisputeResolved(dealId, winner, loser);
    }

    /**
     * @dev This can be called by the arbitrators to pick a winner in a dispute
     * @param dealId The unique identity of the gig
     * @param winner The winner of the dispute
     **/
    function voteRuling(uint dealId, address winner) external {
        require(deals[dealId].inDispute == true, "Gig is not in dispute");
        require(_arbitrators[msg.sender] == true, "Not an arbitrator");
        require(winner == deals[dealId].freelancer || winner == deals[dealId].client, "Winner neither client nor freelancer");

        emit Ruling(dealId, winner);
    }

    /**
     * @dev This can be called by owner to add arbitrators to resolve disputes
     * @param members An array of arbitrators to add
     **/
    function addArbitrators(address[] memory members) external onlyOwner {
        for (uint i = 0; i < members.length; i++){
            _arbitrators[members[i]] = true;
        }
    }

    /**
     * @dev This can be called by owner to remove arbitrators that can resolve disputes
     * @param members An array of arbitrators to remove
     **/
    function removeArbitrators(address[] memory members) external onlyOwner {
        for (uint i = 0; i < members.length; i++){
            _arbitrators[members[i]] = false;
        }
    }

    /**
     * @dev Sets the compensation percentage to winner of disputes and for clients in case of submission deadline violation
     * @param compensation Percentage of total collateral to give out as compensation
     **/
    function setCompensationPercentage(uint compensation) external onlyOwner {
        compensationPercentage = compensation;
    }

    function getCompensationPercentage() external view returns(uint) {
        return compensationPercentage;
    }

    function getDeposit(uint dealId) public view returns (uint) {
        return _collateralManager.escrowOf(dealId, address(this));
    }
}

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
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

pragma solidity >=0.8.0 <0.9.0;

import "../openzeppelin/Safemath.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/Context.sol";
import "../utility/Usable.sol";

contract CollateralManager is Context, Usable {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    address _token;

    mapping(bytes32 => uint) private _escrowBalances;
    mapping(address => uint) private _deposits;
    mapping(address => uint) private _collaterals;


    event Escrow(bytes32 indexed escrowId, uint256 weiAmount);
    event Descrow(uint indexed dealId, uint256 weiAmount);
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event LockCollateral(address indexed user, uint amount);
    event UnlockCollateral(address indexed user, uint amount);
    event Slash(address indexed user, uint amount);

    constructor(address token) {
        _token = token;
    }

    /**
     * @dev Deposits the sent amount as escrow for a deal. It can only be called by verified contracts. 
     *      Each escrow amount is uniquely set based on the dealId and the calling contract
     * @param dealId The unique id of the deal maintained by the logic contract
     */
    function escrow(uint256 amount, address from, uint dealId) external onlyVerifiedContract {
        bytes32 escrowId = keccak256(abi.encodePacked(msg.sender, dealId));
        _escrowBalances[escrowId] = _escrowBalances[escrowId].add(amount);
        IERC20(_token).safeTransferFrom(from, address(this), amount);
        emit Escrow(escrowId, amount);
    }

    /**
     * @dev Withdraw amount from escrow by unique deal Id and calling contract pair
     * @param to The account address where the amount is sent 
     */
    function descrow(uint256 amount, address to, uint dealId) external {
        bytes32 escrowId = keccak256(abi.encodePacked(msg.sender, dealId));
        _escrowBalances[escrowId] = _escrowBalances[escrowId].sub(amount);
        _deposits[to] = _deposits[to].add(amount);

        emit Descrow(dealId, amount);
    }

    /**
     * @dev Withdraw the full amount from escrow by unique deal Id and calling contract pair
     * @param to The account address where the amount is sent 
     */
    function descrowAll(address to, uint dealId) external {
        bytes32 escrowId = keccak256(abi.encodePacked(msg.sender, dealId));
        uint amount = _escrowBalances[escrowId];

        _escrowBalances[escrowId] = 0;
        _deposits[to] = _deposits[to].add(amount);

        emit Descrow(dealId, amount);
    }

    /**
     * @dev Deposit used as collateral for working on gigs
     **/
    function deposit(uint amount) external {
        _deposits[_msgSender()] = _deposits[_msgSender()].add(amount);
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), amount);

        emit Deposit(_msgSender(), amount);
    }

    /**
     * @dev Withdraw deposited amount, refunds, payment from gigs or compensation from violations
     **/
    function withdraw(uint amount) external {
        require(amount <= _deposits[_msgSender()].sub(_collaterals[_msgSender()]), "Withdraw amount higher than total withdrawable amount");

        _deposits[_msgSender()] = _deposits[_msgSender()].sub(amount);
        IERC20(_token).transfer(_msgSender(), amount);
        
        emit Withdraw(_msgSender(), amount);
    }

    /**
     * @dev Lock an user's collateral before they start the gig or when they call a dispute.
     *      - It can only be called by verified contracts. 
     **/
    function lockCollateral(address user, uint amount)
        onlyVerifiedContract
        external
    {
        require(amount <= _deposits[user].sub(_collaterals[user]), "Lock amount higher than total lockable amount");

        _collaterals[user] = _collaterals[user].add(amount);
        emit LockCollateral(user, amount);
    }

    /**
     * @dev Unlock locked collateral
     *      - It can only be called by verified contracts. 
     **/
    function unlockCollateral(address user, uint amount)
        onlyVerifiedContract
        external
    {
        _collaterals[user] = _collaterals[user].sub(amount);
        emit UnlockCollateral(user, amount);
    }

    /**
     * @dev Slash a user's collateral on losing a dispute or failing to complete a gig in time. 
     *      - It can only be called by verified contracts
     **/
    function slashCollateral(address user, uint amount) external onlyVerifiedContract {
        _collaterals[user] =_collaterals[user].sub(amount);
        _deposits[user] = _deposits[user].sub(amount);

        emit Slash(user, amount);
    }

    /**
     * @dev Allocate more funds in this contract to a user
     *      - It can only be called by verified contracts
     **/
    function increaseAllocation(address user, uint amount) external onlyVerifiedContract{
        _deposits[user] = _deposits[user].add(amount);
    }

    /**
     * @dev Gets an user's deposit
     **/
    function getDeposit(address user)
        external
        view
        returns (
            uint
        )
    {
        return _deposits[user];
    }

    /**
     * @dev Gets an user's collaterals
     **/
    function getCollateral(address user)
        external
        view
        returns (
            uint
        )
    {
        return _collaterals[user];
    }

    /**
     * @dev Gets the escrowed amount for a dealId in a logic contract
     **/
    function escrowOf(uint dealId, address dealContract) external view returns (uint256) {
        return _escrowBalances[keccak256(abi.encodePacked(dealContract, dealId))];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "../openzeppelin/Ownable.sol";
import "../openzeppelin/IERC20.sol";

contract FeeManager is Ownable {

    event FeeChange(uint feePercentage);

    uint feePercentage = 2;
    address _tokenAddress;
    constructor(
        address tokenAddress
    ) {
        _tokenAddress = tokenAddress;
    }

    /**
     * @dev This can be called to get current platform fees
     **/
    function getFeePercentage()
        external 
        view
        returns(uint)
    {
        return feePercentage;
    }

    /**
     * @dev This can be called by owner wallet to set platform fees
     **/
    function setPlatformFee(uint percentage)
        external
        onlyOwner
    {
        feePercentage = percentage;

        emit FeeChange(feePercentage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract DealStorage {
    /**
     * @dev Deal storage. This is only created if deal is successfully agreed on by both parties
     **/
    struct Deadline {
        uint32 submissionDeadline;
        uint32 acceptanceDeadline;
        uint32 confirmationDeadline;
    }

    struct Deal {
        bool active;
        bool confirmed;
        bool submitted;
        bool inDispute;
        bool confirmationDeadlineViolated;
        uint8 numRevisionsRemaining;
        uint32 timeToReviseInMinutes;
        address client;
        address freelancer;
        uint32 timeToAcceptInMinutes;
        Deadline deadline;
        uint collateral;
        uint reward;
        string submission;
        string gigCid;
    }

    Deal[] deals;
    mapping (address => bool) internal _arbitrators;

    function getFreelancer(uint dealId) external view returns (address){
        return deals[dealId].freelancer;
    }

    function getClient(uint dealId) external view returns (address){
        return deals[dealId].client;
    }

    function getDeal(uint dealId) external view returns (Deal memory) {
        return deals[dealId];
    }

    function getReward(uint dealId) public view returns (uint256) {
        return deals[dealId].reward;
    }

    function getDeals() external view returns (Deal[] memory) {
        return deals;
    }   

    function isArbitrator(address arbitrator) external view returns (bool) {
        return _arbitrators[arbitrator];
    }   
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from './IERC20.sol';
import {SafeMath} from './Safemath.sol';
import {Address} from './Address.sol';

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
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../openzeppelin/Context.sol';
import '../openzeppelin/Ownable.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are user accounts that can be granted exclusive access to write to 
 * derived contracts
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyUser`, which can be applied to functions restricting access to verified users
 */
abstract contract Usable is Ownable {
  mapping(address => bool) verifiedContracts;

  event ContractAdded(address indexed verifiedContracts);
  event ContractRemoved(address indexed verifiedContracts);

  /**
   * @dev Returns if user is verified.
   */
  function isVerifiedContract(address contractAddress) public view returns (bool) {
    return verifiedContracts[contractAddress];
  }

  /**
   * @dev Throws if called by any account other than verified users.
   */
  modifier onlyVerifiedContract() {
    require(verifiedContracts[msg.sender] == true, 'Usable: caller is not verified user contract');
    _;
  }

  /**
   * @dev Adds new verified contract
   * Can only be added by owner
   */
  function addVerifiedContract(address verifiedContract) public onlyOwner {
    require(verifiedContract != address(0), 'Usable: new user is the zero address');
    verifiedContracts[verifiedContract] = true;

    emit ContractAdded(verifiedContract);
  }

  /**
   * @dev Removes existing verified user
   * Can only be removed by owner
   */
  function removeVerifiedContract(address verifiedContract) public onlyOwner {
    verifiedContracts[verifiedContract] = false;

    emit ContractRemoved(verifiedContract);

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
     * plain`call` is an unsafe replacement for a function call: use this
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity >=0.8.0 <0.9.0;

import './Context.sol';

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
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}