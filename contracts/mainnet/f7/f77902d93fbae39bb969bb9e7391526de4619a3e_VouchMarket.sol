/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

/**
 * @title ProofOfHumanity Interface
 * @dev See https://github.com/Proof-Of-Humanity/Proof-Of-Humanity.
 */
interface IProofOfHumanity {
    function isRegistered(address _submissionID)
        external
        view
        returns (bool registered);

    function getSubmissionInfo(address _submissionID)
        external
        view
        returns (
            uint8 status,
            uint64 submissionTime,
            uint64 index,
            bool registered,
            bool hasVouched,
            uint256 numberOfRequests
        );
}

contract VouchMarket {
    /** @dev To be emitted when a proposal is submitted.
     *  @param idProposal Unique identifier of the proposal.
     *  @param user The user that receives the vouch.
     *  @param amount The ETH sent by the user.
     *  @param timeLimit Time limit until the user can claim his own funds.
     *  @param voucher The person who vouch.
     */
    event LogProposal(
        uint64 indexed idProposal,
        address indexed user,
        uint256 amount,
        uint64 timeLimit,
        address voucher
    );
    /**
     *  @dev Emitted when a voucher locks a proposal.
     *  @param idProposal Unique identifier of the proposal.
     *  @param voucher The person who locks and vouch the proposal.
     */
    event LogProposalLocked(uint64 indexed idProposal, address indexed voucher);
    /**
     *  @dev Emitted when a proposal reward is claimed.
     *  @param idProposal Unique identifier of the proposal.
     *  @param voucher The person who vouch.
     */
    event LogRewardForVouchingClaimed(
        uint64 indexed idProposal,
        address indexed voucher
    );
    /**
     *  @dev Emitted when a vouch is not performed for this proposal.
     *  @param idProposal Unique identifier of the proposal.
     */
    event LogClaimVouchNotPerformed(uint64 indexed idProposal);
    /**
     *  @dev To be emitted when a withdrawal occurs.
     *  @param idProposal Unique identifier of the proposal.
     *  @param withdrawer The person who withdraws.
     *  @param fund The ETH sent to the person who withdraws.
     *  @param fee The contract fee.
     */
    event LogWithdrawn(
        uint64 indexed idProposal,
        address indexed withdrawer,
        uint256 fund,
        uint256 fee
    );

    // Proof of Humanity contract.
    IProofOfHumanity private PoH =
        IProofOfHumanity(0xC5E9dDebb09Cd64DfaCab4011A0D5cEDaf7c9BDb);
    /// @dev Divisor to calculate the fee, higher the value, higher the voucher reward
    uint256 public feeDivisor;
    /// @dev Counter of submitted proposals
    uint64 public proposalCounter;
    /// @dev Minimum waiting time to lock another proposal
    uint64 public cooldownTime;
    // Contract maintainer
    address private maintainer;
    // UBIburner contract
    address private UBIburner;

    struct Proposal {
        address user; //Person who need the vouch
        uint64 timeLimit; //If someone locks it and does not claim it, time limit to wait and withdraw your funds
        uint256 amount; //Transactions cost + incentive + fee to burn UBI
        address voucher; //Person selected to vouch or person who lock the proposal
    }

    /// @dev Map all the proposals by their IDs. idProposal -> Proposal
    mapping(uint64 => Proposal) public proposalMap;

    /// @dev Map the last time a user locks a proposal. voucher -> time
    mapping(address => uint64) public timeLastLockMap;

    constructor(
        uint256 _feeDivisor,
        uint64 _cooldownTime,
        address _UBIburner
    ) {
        maintainer = msg.sender;
        feeDivisor = _feeDivisor;
        cooldownTime = _cooldownTime;
        UBIburner = _UBIburner;
    }

    modifier onlyMaintainer() {
        require(msg.sender == maintainer, "Not maintainer");
        _;
    }

    /**
     *  @dev Submit proposal.
     *  @param addedTime Time limit until the user can claim his own funds.
     *  @param voucher (Optional) The person who give the vouch. Address 0 to denote that anyone can vouch.
     */
    function submitProposal(uint64 addedTime, address voucher)
        external
        payable
    {
        uint64 idProposal = proposalCounter;
        Proposal storage thisProposal = proposalMap[idProposal];
        uint256 amount = msg.value;
        require(amount > 0, "money?");
        uint64 timeLimit = uint64(block.timestamp) + addedTime;
        thisProposal.user = msg.sender;
        thisProposal.amount = amount;
        thisProposal.timeLimit = timeLimit;
        if (voucher != address(0)) {
            thisProposal.voucher = voucher;
            emit LogProposalLocked(idProposal, voucher);
        }
        proposalCounter++;
        emit LogProposal(idProposal, msg.sender, amount, timeLimit, voucher);
    }

    /**
     *  @dev Lock the proposal before the vouch happens and only the locker will be able to claim it. Reducing the voucher race.
     *  @param idProposal The ID of the proposal.
     */
    function lockProposal(uint64 idProposal) external {
        (, , , , bool hasVouched, ) = PoH.getSubmissionInfo(msg.sender);
        Proposal storage thisProposal = proposalMap[idProposal];
        require(thisProposal.amount > 0, "Wrong time or done");
        require(thisProposal.voucher == address(0), "Locked or assigned");
        require(PoH.isRegistered(msg.sender), "Not registered"); //Avoid invalid vouch
        require(
            block.timestamp > timeLastLockMap[msg.sender] + cooldownTime &&
                !hasVouched,
            "Can't vouch yet"
        ); //Avoid multiple locks at the same time and vouchers w/o available vouch
        timeLastLockMap[msg.sender] = uint64(block.timestamp);
        thisProposal.voucher = msg.sender;
        emit LogProposalLocked(idProposal, msg.sender);
    }

    /**
     *  @dev Update the proposal to increase the reward and set a new time limit.
     *  @param idProposal The ID of the proposal.
     *  @param addedTime Time limit until the user can claim his own funds.
     *  @param voucher (Optional) The person who vouch. Address 0 to denote that anyone can vouch.
     */
    function updateProposal(
        uint64 idProposal,
        uint64 addedTime,
        address voucher
    ) external payable {
        Proposal storage thisProposal = proposalMap[idProposal];
        require(thisProposal.user == msg.sender, "Nice try");
        require(thisProposal.amount > 0, "Wrong time or done");
        address designedVoucher = thisProposal.voucher;
        uint64 moment = uint64(block.timestamp);
        if (thisProposal.timeLimit < moment)
            require(designedVoucher == address(0), "Wait time limit expires");
        uint64 timeLimit = moment + addedTime;
        uint256 amount = thisProposal.amount;
        if (msg.value > 0) {
            amount += msg.value;
            thisProposal.amount = amount;
        }
        thisProposal.timeLimit = timeLimit;
        if (voucher != designedVoucher) thisProposal.voucher = voucher;
        emit LogProposal(idProposal, msg.sender, amount, timeLimit, voucher);
    }

    /**
     *  @dev After vouch for a proposal, claim the proposal reward.
     *  @param idProposal The ID of the proposal.
     */
    function claimRewardForVouching(uint64 idProposal) external {
        Proposal storage thisProposal = proposalMap[idProposal];
        address user = thisProposal.user;
        (uint8 status, , , , , ) = PoH.getSubmissionInfo(user);
        require(thisProposal.amount > 0, "Wrong time or done");
        require(thisProposal.voucher == msg.sender, "You are not the voucher");
        require(
            status == uint8(2) || PoH.isRegistered(user), //status == 2 is pending registration
            "Can't claim yet"
        );
        emit LogRewardForVouchingClaimed(idProposal, msg.sender);
        pay(idProposal);
    }

    /**
     *  @dev If the user is not vouched in time limit, user can claim his own funds.
     *  @param idProposal The ID of the proposal.
     */
    function claimVouchNotPerformed(uint64 idProposal) external {
        Proposal storage thisProposal = proposalMap[idProposal];
        require(thisProposal.user == msg.sender, "Nice try");
        require(
            ((block.timestamp > thisProposal.timeLimit &&
                thisProposal.amount > 0) ||
                (thisProposal.voucher == address(0))),
            "Done or has a voucher and the time limit is not over yet"
        );
        emit LogClaimVouchNotPerformed(idProposal);
        pay(idProposal);
    }

    /**
     *  @dev Calculate and withdraw the funds of the proposal.
     *  @param idProposal The ID of the proposal.
     */
    function pay(uint64 idProposal) private {
        Proposal storage thisProposal = proposalMap[idProposal];
        uint256 fee = thisProposal.amount / feeDivisor;
        uint256 feeToMaintainer = fee / 5; //20% of the fee for the maintainer. That is a maximum of 5% of the deposit.
        uint256 feeToBurnUBI = fee - feeToMaintainer; //80% of the fee to burn UBIs. That is a maximum of 20% of the deposit.
        uint256 fund = thisProposal.amount - fee;
        thisProposal.amount = 0;
        emit LogWithdrawn(idProposal, msg.sender, fund, fee);
        (bool successTx1, ) = maintainer.call{value: feeToMaintainer}("");
        require(successTx1, "Tx1 fail");
        (bool successTx2, ) = UBIburner.call{value: feeToBurnUBI}("");
        require(successTx2, "Tx2 fail");
        (bool successTx3, ) = msg.sender.call{value: fund}("");
        require(successTx3, "Tx3 fail");
    }

    /**
     *  @dev Change Fee Divisor Commission Calculator and the cooldown time to wait after a proposal lock.
     *  @param _feeDivisor The divisor to calculate the fee, the higher this value is, the lower the fee and the higher the reward for the voucher.
     *  @param _cooldownTime Minimum waiting time to lock another proposal.
     */
    function changeParameters(
        uint256 _feeDivisor,
        uint64 _cooldownTime,
        address _UBIburner
    ) external onlyMaintainer {
        require(_feeDivisor >= 4);
        feeDivisor = _feeDivisor;
        cooldownTime = _cooldownTime;
        UBIburner = _UBIburner;
    }

    /**
     *  @dev Change maintainer.
     *  @param _maintainer The address of the new maintainer
     */
    function changeMaintainer(address _maintainer) external onlyMaintainer {
        require(_maintainer != address(0));
        maintainer = _maintainer;
    }
}