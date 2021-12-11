pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IArtizenCore.sol";
import "./interfaces/IArtizenTreasury.sol";

// ------------------------------------------ //
//               ArtizenCore v1               //
// ------------------------------------------ //

/**
    @title ArtizenCore
 */
contract ArtizenCore is IArtizenCore, Ownable {
    struct Grant {
        address[] grantAdmins;
        bool adminFeeClaimed;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotePoints;
        uint256 totalDonations; //in DAI (18 decimals)
        uint256 totalProtocolFees; // to track protocol fees per grant in case of refund
        bool cancelled;
    }

    struct Project {
        address[] owners; //address that can withdraw donations on behalf of project
    }

    struct GrantProject {
        uint256 votePoints;
        bool donationsClaimed;
    }

    mapping(uint256 => Grant) private grants;
    mapping(uint256 => Project) private projects;

    // grantID => projectID => votes/donationsClaimed. Tracks votes/claims per project within a specified grant
    mapping(uint256 => mapping(uint256 => GrantProject)) private grantProjects;

    // grantID => set of addresses of donors - for handling refunds if grant gets cancelled
    mapping(uint256 => address[]) private grantDonorsArray; // for batch refund looping - use mapping below for amounts
    mapping(uint256 => mapping(address => uint256)) private grantDonationsMap; // for manual user refund claiming

    // grantID => account => isAdmin
    mapping(uint256 => mapping(address => bool)) private isAdminOfGrant;
    // projectID => account => isOwner
    mapping(uint256 => mapping(address => bool)) private isOwnerOfProject;

    // votes per account
    // account => grantID => vote balance
    mapping(address => mapping(uint256 => uint256)) private voteBalances;

    // grantID => projectID array
    mapping(uint256 => uint256[]) private projectsInGrant;
    // grantID => projectID => project is in grant boolean
    mapping(uint256 => mapping(uint256 => bool))
        private doesGrantContainProject;

    uint256 public override grantCount;
    uint256 public override projectCount;

    uint256 public constant override SCALE = 10000; // Scale is 10 000
    uint256 public override protocolFee;
    uint256 public override adminFee;

    IERC20 public DAI;
    address public override treasuryAddress;

    bool public override isShutdown;

    // ------------------------------------------ //
    //                  EVENTS                    //
    // ------------------------------------------ //

    event GrantCreated(
        uint256 grantID,
        address[] grantAdmins,
        uint256 startTime,
        uint256 endTime
    );

    event GrantRenewed(uint256 oldGrantID, uint256 newGrantID);

    event GrantCancelled(uint256 grantID);

    event RefundSent(
        address indexed donor,
        address indexed sender,
        uint256 indexed grantID,
        uint256 amountRefunded
    );

    event ProjectCreated(uint256 projectID, string name, address[] owners);

    event ProjectSetInGrant(
        uint256 projectID,
        uint256 grantID,
        bool projectInGrant
    );

    event Donate(address indexed donor, uint256 grantID, uint256 amount);

    event Vote(
        address indexed voter,
        uint256 grantID,
        uint256 projectID,
        uint256 votes
    );

    event ProjectDonationsClaimed(
        address[] projectOwners,
        uint256 indexed grantID,
        uint256 indexed projectID,
        uint256 fundsWithdrawn
    );

    event GrantAdminFeesClaimed(
        address[] grantAdmins,
        uint256 indexed grantID,
        uint256 fundsWithdrawn
    );

    event TreasuryAddressUpdated(address oldTreasury, address newTreasury);
    event FeesSet(uint256 protocolFee, uint256 adminFee);
    event Shutdown(bool isCurrentlyShutdown);

    // ------------------------------------------ //
    //                 CONSTRUCTOR                //
    // ------------------------------------------ //

    constructor(address _dai) {
        DAI = IERC20(_dai);
    }

    // ------------------------------------------ //
    //      PUBLIC STATE-MODIFYING FUNCTIONS      //
    // ------------------------------------------ //

    /**
        @notice accepts donation to a grant, votes delegated
        @param _grantID the ID of grant donated to
        @param _amountDonated the amount of DAI donated
        @param _delegateVotesTo an address to delegate votes to
    */
    function donate(
        uint256 _grantID,
        uint256 _amountDonated,
        address _delegateVotesTo
    ) external override notShutdown {
        // Only DAI for now
        _donate(_grantID, _amountDonated, _delegateVotesTo);
    }

    // Gifts voting power to an account without any DAI deposits
    function giftVotes(
        uint256 _amountVotes,
        address _to,
        uint256 _grantID
    ) external override notShutdown onlyOwner {
        voteBalances[_to][_grantID] += _amountVotes;
    }

    /**
        @notice allocate votes to a single project in a grant
        @param _grantID the ID of grant containing voted project
        @param _projectID the ID of project in the grant voted on
        @param _amountVotes the amount of votes allocated to the project
    */
    function vote(
        uint256 _grantID,
        uint256 _projectID,
        uint256 _amountVotes
    ) external override {
        _vote(_grantID, _projectID, _amountVotes);
    }

    // Artizen Owner or Grant Admins can call to trigger payment
    // Will pay the grant's admin fees to all grant admins split equally
    function payGrantAdminFees(uint256 _grantID)
        external
        override
        onlyOwnerOrGrantAdmins(_grantID)
    {
        _payOutGrantAdminFees(_grantID);
    }

    // Artizen Owner or Project Owner can call to trigger payment
    // Will pay project's donations to all project owners split equally
    function payDonationsToProject(uint256 _grantID, uint256 _projectID)
        external
        override
        onlyOwnerOrProjectOwners(_projectID)
    {
        _payOutProjectDonations(_grantID, _projectID);
    }

    // NOTE this may fail if arrays of projects or project owners are too large
    function payDonationsToAllProjectsInGrant(uint256 _grantID)
        external
        override
        onlyOwnerOrGrantAdmins(_grantID)
    {
        uint256 arrayLength = projectsInGrant[_grantID].length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _payOutProjectDonations(_grantID, projectsInGrant[_grantID][i]);
        }
    }

    /**
        @notice creates a new grant
        @param _grantAdmins array of admin accounts of the grant
        @param _startTime starting time of grant
        @param _endTime ending time of grant
    */
    function createGrant(
        address[] memory _grantAdmins,
        uint256 _startTime,
        uint256 _endTime
    ) public override notShutdown returns (uint256) {
        uint256 arrayLength = _grantAdmins.length;
        require(arrayLength > 0, "ART_CORE: GRANT NEEDS ADMINS");
        require(_startTime < _endTime, "ART_CORE: START TIME > END TIME");
        require(_endTime > block.timestamp, "ART_CORE: MUST END IN FUTURE");

        grantCount++;

        grants[grantCount].grantAdmins = _grantAdmins;
        grants[grantCount].startTime = _startTime;
        grants[grantCount].endTime = _endTime;

        // Setting each address in grantAdmins to admin of grant in mapping
        for (uint256 i = 0; i < arrayLength; i++) {
            require(
                _grantAdmins[i] != address(0),
                "ART_CORE: NO ZERO ADDRESS ADMINS"
            );
            isAdminOfGrant[grantCount][_grantAdmins[i]] = true;
        }

        emit GrantCreated(grantCount, _grantAdmins, _startTime, _endTime);

        return grantCount; //returns grantID
    }

    /**
        @notice creates a new grant
        @param _projectName name of project
        @param _projectOwners array of accounts that can withdraw project donations
    */
    function createProject(
        string calldata _projectName,
        address[] calldata _projectOwners
    ) external override notShutdown returns (uint256) {
        uint256 arrayLength = _projectOwners.length;
        require(arrayLength > 0, "ART_CORE: PROJECT NEEDS OWNERS");

        projectCount++;
        projects[projectCount].owners = _projectOwners;

        // Setting each address in projectOwners to owner of project in mapping
        for (uint256 i = 0; i < arrayLength; i++) {
            require(
                _projectOwners[i] != address(0),
                "ART_CORE: NO ZERO ADDRESS OWNERS"
            );
            isOwnerOfProject[projectCount][_projectOwners[i]] = true;
        }

        // emit project name string in event but does not save it on-chain
        emit ProjectCreated(projectCount, _projectName, _projectOwners);

        return projectCount; //returns projectID
    }

    // Creates new grant with same admins
    function renewGrant(
        uint256 _grantID,
        uint256 _startTime,
        uint256 _endTime
    )
        external
        override
        notShutdown
        grantNotCancelled(_grantID)
        onlyOwnerOrGrantAdmins(_grantID)
        returns (uint256)
    {
        // Cannot cancel after grant has ended
        require(
            block.timestamp > grants[_grantID].endTime,
            "ART_CORE: GRANT NOT ENDED"
        );

        uint256 _newGrantID = createGrant(
            grants[_grantID].grantAdmins,
            _startTime,
            _endTime
        );

        emit GrantRenewed(_grantID, _newGrantID);
        return _newGrantID;
    }

    // Must be called before refunds are processed
    // Cancelled and Deleted grants are the same thing
    function cancelGrant(uint256 _grantID)
        external
        override
        grantNotCancelled(_grantID)
        onlyOwnerOrGrantAdmins(_grantID)
    {
        // Cannot cancel after grant has ended
        require(
            block.timestamp < grants[_grantID].endTime,
            "ART_CORE: GRANT ENDED"
        );

        // Setting grant to cancelled
        grants[_grantID].cancelled = true;

        // Reducing protocol fees in Treasury, increasing withdrawable grant funds
        IArtizenTreasury(treasuryAddress).reduceProtocolFeesEarned(
            grants[_grantID].totalProtocolFees
        );

        emit GrantCancelled(_grantID);
        // To refund donors of cancelled grant, call refund functions below
    }

    /**
        @notice Refunds specified donor of cancelled grant if DAI was donated
        @param _grantID ID of grant
        @param _donor address of donor. Note: use own address if you are a donor. 
    */
    function refundGrantDonor(uint256 _grantID, address _donor)
        external
        override
        grantCancelled(_grantID)
    {
        require(
            grantDonationsMap[_grantID][_donor] > 0,
            "ART_CORE: NO REFUNDABLE BALANCE"
        );

        uint256 _amount = grantDonationsMap[_grantID][_donor];
        grantDonationsMap[_grantID][_donor] = 0;
        grants[_grantID].totalDonations -= _amount;

        _refundDonation(_donor, _amount);

        emit RefundSent(_donor, msg.sender, _grantID, _amount);
    }

    // ------------------------------------------ //
    //           ONLY OWNER FUNCTIONS             //
    // ------------------------------------------ //

    /**
        @notice creates a new grant
        @param _projectID ID of project
        @param _grantID ID of grant
        @param _inGrant true/false is project in grant
    */
    function setProjectInGrant(
        uint256 _grantID,
        uint256 _projectID,
        bool _inGrant
    )
        external
        override
        notShutdown
        grantNotCancelled(_grantID)
        onlyOwnerOrGrantAdmins(_grantID)
    {
        // Can't change projects of grant after grant ended
        require(
            block.timestamp < grants[_grantID].endTime,
            "ART_CORE: GRANT ALREADY ENDED"
        );
        // Reverts if project already in/out grant
        require(
            doesGrantContainProject[_grantID][_projectID] != _inGrant,
            "ART_CORE: PROJECT ALREADY SET"
        );

        // setting to true/false in nested mapping
        doesGrantContainProject[_grantID][_projectID] = _inGrant;
        if (_inGrant) {
            // adding to grant
            projectsInGrant[_grantID].push(_projectID);
        } else {
            // Loop until finding index of projectID, then remove from array
            uint256 arrayLength = projectsInGrant[_grantID].length;
            for (uint256 i = 0; i < arrayLength; i++) {
                if (projectsInGrant[_grantID][i] == _projectID) {
                    projectsInGrant[_grantID][i] = projectsInGrant[_grantID][
                        arrayLength - 1
                    ];
                    projectsInGrant[_grantID].pop();
                    break;
                }
            }
        }

        emit ProjectSetInGrant(_grantID, _projectID, _inGrant);
    }

    function setFees(uint256 _protocolFee, uint256 _adminFee)
        external
        override
        notShutdown
        onlyOwner
    {
        require(
            _protocolFee + _adminFee < SCALE,
            "ART_CORE: FEE SUM OUT OF RANGE"
        );

        protocolFee = _protocolFee;
        adminFee = _adminFee;

        emit FeesSet(_protocolFee, _adminFee);
    }

    function setTreasury(address _newTreasury)
        external
        override
        notShutdown
        onlyOwner
    {
        require(_newTreasury != address(0), "ART_CORE: ZERO ADDRESS TREASURY");
        address oldAddress = treasuryAddress;
        treasuryAddress = _newTreasury;
        // Infinite approve Treasury for DAI withdraws
        DAI.approve(_newTreasury, type(uint256).max);

        emit TreasuryAddressUpdated(oldAddress, _newTreasury);
    }

    function shutdown(bool _isShutdown) external override onlyOwner {
        isShutdown = _isShutdown;
        emit Shutdown(_isShutdown);
    }

    // ------------------------------------------ //
    //     INTERNAL STATE-MODIFYING FUNCTIONS     //
    // ------------------------------------------ //

    /**
        @notice internal core donation logic, only processes DAI donations 
        @param _grantID the ID of grant donated to
        @param _amountDAIDonated the amount of DAI donated
        @param _delegateVotesTo an address to delegate votes to
    */
    function _donate(
        uint256 _grantID,
        uint256 _amountDAIDonated,
        address _delegateVotesTo
    ) internal grantNotCancelled(_grantID) {
        require(_amountDAIDonated > 0, "ART_CORE: CANT DONATE ZERO");
        require(
            block.timestamp >= grants[_grantID].startTime &&
                block.timestamp < grants[_grantID].endTime,
            "ART_CORE: GRANT CLOSED"
        );

        // Pulls DAI from donor (msg.sender)
        require(DAI.transferFrom(msg.sender, address(this), _amountDAIDonated));

        // Sends donated funds to Treasury to earn yield
        IArtizenTreasury(treasuryAddress).deposit(_amountDAIDonated);

        // add donated amount to specified grant
        grants[_grantID].totalDonations += _amountDAIDonated;
        grants[_grantID].totalProtocolFees +=
            (_amountDAIDonated * protocolFee) /
            SCALE;

        // Allocating votes. y DAI = square root of 100y votes
        voteBalances[_delegateVotesTo][_grantID] += sqrt(
            _amountDAIDonated / 1e16
        );

        // Account for individual donation amounts per grant per user
        grantDonorsArray[_grantID].push(msg.sender); // in array
        grantDonationsMap[_grantID][msg.sender] += _amountDAIDonated; // in mapping

        emit Donate(msg.sender, _grantID, _amountDAIDonated);
    }

    /**
        @notice internal core voting logic
        @param _grantID the ID of grant donated to
        @param _projectID the ID of project in the grant donated to
        @param _amountVotes the amount of votes allocated to the project
    */
    function _vote(
        uint256 _grantID,
        uint256 _projectID,
        uint256 _amountVotes
    ) internal grantNotCancelled(_grantID) {
        // Checks amountVotes is not zero
        require(_amountVotes > 0, "ART_CORE: CANNOT VOTE ZERO");
        // Checks sender has enough voting power
        require(
            voteBalances[msg.sender][_grantID] >= _amountVotes,
            "ART_CORE: VOTE BALANCE TO LOW"
        );
        // Checks grant is in voting period - also implies grant exists
        require(
            block.timestamp >= grants[_grantID].startTime &&
                block.timestamp < grants[_grantID].endTime,
            "ART_CORE: GRANT VOTING CLOSED"
        );
        // Checks specified project is in specified grant
        require(
            doesGrantContainProject[_grantID][_projectID],
            "ART_CORE: PROJECT NOT IN GRANT"
        );

        // Reduce voting balance first
        voteBalances[msg.sender][_grantID] -= _amountVotes;
        // Add vote points to full grant total
        grants[_grantID].totalVotePoints += _amountVotes;
        // credit project in grant with votes
        grantProjects[_grantID][_projectID].votePoints += _amountVotes;

        emit Vote(msg.sender, _grantID, _projectID, _amountVotes);
    }

    // Internal function to claim fees and send equal slice to all grant admins
    function _payOutGrantAdminFees(uint256 _grantID)
        internal
        grantNotCancelled(_grantID)
    {
        require(
            !grants[_grantID].adminFeeClaimed,
            "ART_CORE: FEE ALREADY CLAIMED"
        );
        require(
            block.timestamp > grants[_grantID].endTime,
            "ART_CORE: GRANT NOT ENDED"
        );

        uint256 _totalGrantAdminFee = getGrantAdminFee(_grantID);
        require(_totalGrantAdminFee > 0, "ART_CORE: NO FUNDS RAISED");

        IArtizenTreasury(treasuryAddress).moveEnoughDaiFromAaveToTreasury(
            _totalGrantAdminFee
        );

        grants[_grantID].adminFeeClaimed = true;

        // Loop through all owners of project - paying each an equal cut
        uint256 arrayLength = grants[_grantID].grantAdmins.length;
        uint256 _amountPerAdmin = _totalGrantAdminFee / arrayLength;
        for (uint256 i = 0; i < arrayLength; i++) {
            IArtizenTreasury(treasuryAddress).withdraw(
                grants[_grantID].grantAdmins[i],
                _amountPerAdmin
            );
        }

        emit GrantAdminFeesClaimed(
            grants[_grantID].grantAdmins,
            _grantID,
            _totalGrantAdminFee
        );
    }

    // Internal function to claim donations and send equal slice to all project owners
    function _payOutProjectDonations(uint256 _grantID, uint256 _projectID)
        internal
        grantNotCancelled(_grantID)
    {
        if (grantProjects[_grantID][_projectID].donationsClaimed) {
            // should not pay out if claimed, but must also not revert in loop for all projects
            return;
        }

        require(
            block.timestamp > grants[_grantID].endTime,
            "ART_CORE: GRANT NOT ENDED"
        );

        uint256 _projectDonations = getProjectDonations(_grantID, _projectID);

        IArtizenTreasury(treasuryAddress).moveEnoughDaiFromAaveToTreasury(
            _projectDonations
        );

        grantProjects[_grantID][_projectID].donationsClaimed = true;

        // Loop through all owners of project - paying each an equal cut
        uint256 arrayLength = projects[_projectID].owners.length;
        uint256 _amountPerOwner = _projectDonations / arrayLength;
        for (uint256 i = 0; i < arrayLength; i++) {
            IArtizenTreasury(treasuryAddress).withdraw(
                projects[_projectID].owners[i],
                _amountPerOwner
            );
        }

        emit ProjectDonationsClaimed(
            projects[_projectID].owners,
            _grantID,
            _projectID,
            _projectDonations
        );
    }

    function _refundDonation(address _donor, uint256 _amount) internal {
        // Sends [_amount] DAI from Treasury to [_donor] as a refund
        IArtizenTreasury(treasuryAddress).withdraw(_donor, _amount);
    }

    // ------------------------------------------ //
    //             VIEW FUNCTIONS                 //
    // ------------------------------------------ //

    function getGrant(uint256 _grantID)
        external
        view
        override
        returns (
            address[] memory,
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            grants[_grantID].grantAdmins,
            grants[_grantID].adminFeeClaimed,
            grants[_grantID].startTime,
            grants[_grantID].endTime,
            grants[_grantID].totalVotePoints,
            grants[_grantID].totalDonations,
            grants[_grantID].cancelled
        );
    }

    function getProjectsInGrant(uint256 _grantID)
        external
        view
        override
        returns (uint256[] memory)
    {
        return projectsInGrant[_grantID];
    }

    // will return 0 if already claimed
    function getGrantAdminFee(uint256 _grantID)
        public
        view
        override
        returns (uint256)
    {
        if (!grants[_grantID].adminFeeClaimed) {
            return (grants[_grantID].totalDonations * adminFee) / SCALE;
        } else {
            return 0;
        }
    }

    // will return 0 if already claimed
    function getProjectDonations(uint256 _grantID, uint256 _projectID)
        public
        view
        override
        returns (uint256)
    {
        if (!grantProjects[_grantID][_projectID].donationsClaimed) {
            uint256 totalFundsToProject = getProjectShareInGrant(
                _grantID,
                _projectID
            );
            // Calcs withdrawable funds for project after fees
            return
                (totalFundsToProject * (SCALE - adminFee - protocolFee)) /
                SCALE;
        } else {
            return 0;
        }
    }

    // Calcs the share of total funds in grant based on votes (in DAI)
    function getProjectShareInGrant(uint256 _grantID, uint256 _projectID)
        internal
        view
        returns (uint256)
    {
        if (grants[_grantID].totalVotePoints == 0) {
            return 0;
        } else {
            // ( project VPs / total grant VPs ) * grant funds
            return
                ((grantProjects[_grantID][_projectID].votePoints * SCALE) /
                    grants[_grantID].totalVotePoints) *
                (grants[_grantID].totalDonations / SCALE);
        }
    }

    // How many unspent votes does an account have in a given grant
    function voteBalanceInGrant(address _account, uint256 _grantID)
        external
        view
        override
        returns (uint256)
    {
        return voteBalances[_account][_grantID];
    }

    // Returns total votes for a specified project in a specified grant
    function projectVotesInGrant(uint256 _grantID, uint256 _projectID)
        external
        view
        override
        returns (uint256)
    {
        return grantProjects[_grantID][_projectID].votePoints;
    }

    // Returns true if account is admin of specified grant
    function isGrantAdmin(address _account, uint256 _grantID)
        external
        view
        override
        returns (bool)
    {
        return isAdminOfGrant[_grantID][_account];
    }

    // Returns true if account is owner of specified project
    function isProjectOwner(address _account, uint256 _projectID)
        external
        view
        override
        returns (bool)
    {
        return isOwnerOfProject[_projectID][_account];
    }

    // Returns total donations in a grant from a specified account
    function grantDonationsFromAccount(address _account, uint256 _grantID)
        external
        view
        override
        returns (uint256)
    {
        return grantDonationsMap[_grantID][_account];
    }

    // FOR INTERNAL SQUARE ROOT MATH
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
    }

    // ------------------------------------------ //
    //                MODIFIERS                   //
    // ------------------------------------------ //

    modifier onlyOwnerOrGrantAdmins(uint256 _grantID) {
        require(
            isAdminOfGrant[_grantID][msg.sender] || msg.sender == owner(),
            "ART_CORE: NOT ADMIN OR OWNER"
        );
        _;
    }

    modifier onlyOwnerOrProjectOwners(uint256 _projectID) {
        require(
            isOwnerOfProject[_projectID][msg.sender] || msg.sender == owner(),
            "ART_CORE: NOT PROJECT OWNER"
        );
        _;
    }

    modifier grantNotCancelled(uint256 _grantID) {
        require(!grants[_grantID].cancelled, "ART_CORE: GRANT CANCELLED");
        _;
    }

    modifier grantCancelled(uint256 _grantID) {
        require(grants[_grantID].cancelled, "ART_CORE: GRANT NOT CANCELLED");
        _;
    }

    modifier notShutdown() {
        require(!isShutdown, "ART_CORE: CONTRACT IS SHUTDOWN");
        _;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

// TODO Update to include latest Core functions
interface IArtizenCore {
    function grantCount() external view returns (uint256);

    function projectCount() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function adminFee() external view returns (uint256);

    function SCALE() external view returns (uint256);

    function isShutdown() external view returns (bool);

    function treasuryAddress() external view returns (address);

    function getGrant(uint256 _grantID)
        external
        view
        returns (
            address[] memory, // grantAdmins
            bool, // adminFeeClaimed
            uint256, // startTime
            uint256, // endTime
            uint256, // totalVotePoint
            uint256, // totalDonations
            bool // cancelled
        );

    function getProjectsInGrant(uint256 _grantID)
        external
        view
        returns (uint256[] memory);

    function getGrantAdminFee(uint256 _grantID) external view returns (uint256);

    function getProjectDonations(uint256 _grantID, uint256 _projectID)
        external
        view
        returns (uint256);

    function voteBalanceInGrant(address _account, uint256 _grantID)
        external
        view
        returns (uint256);

    function projectVotesInGrant(uint256 _grantID, uint256 _projectID)
        external
        view
        returns (uint256);

    function isGrantAdmin(address _account, uint256 _grantID)
        external
        view
        returns (bool);

    function isProjectOwner(address _account, uint256 _projectID)
        external
        view
        returns (bool);

    function grantDonationsFromAccount(address _account, uint256 _grantID)
        external
        view
        returns (uint256);

    function donate(
        uint256 _grantID,
        uint256 _amountDonated,
        address _delegateVotesTo
    ) external;

    function giftVotes(
        uint256 _amountVotes,
        address _to,
        uint256 _grantID
    ) external;

    function vote(
        uint256 _grantID,
        uint256 _projectID,
        uint256 _amountVotes
    ) external;

    function payGrantAdminFees(uint256 _grantID) external;

    function payDonationsToProject(uint256 _grantID, uint256 _projectID)
        external;

    function payDonationsToAllProjectsInGrant(uint256 _grantID) external;

    function createGrant(
        address[] calldata _grantAdmins,
        uint256 _startTime,
        uint256 _endTime
    ) external returns (uint256);

    function createProject(
        string calldata _projectName,
        address[] calldata _projectOwners
    ) external returns (uint256);

    function renewGrant(
        uint256 _grantID,
        uint256 _startTime,
        uint256 _endTime
    ) external returns (uint256);

    function cancelGrant(uint256 _grantID) external;

    function refundGrantDonor(uint256 _grantID, address _donor) external;

    function setProjectInGrant(
        uint256 _grantID,
        uint256 _projectID,
        bool _inGrant
    ) external;

    function setFees(uint256 _protocolFee, uint256 _adminFee) external;

    function setTreasury(address _newTreasury) external;

    function shutdown(bool _isShutdown) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

// TODO Update to include latest Treasury functions
interface IArtizenTreasury {
    function artizenCoreAddress() external view returns (address);

    function daiAddress() external view returns (address);

    function aaveLendingPoolAddress() external view returns (address);

    function isShutdown() external view returns (bool);

    function grantDaiInTreasury() external view returns (uint256);

    function withdraw(address _recipient, uint256 _amount) external;

    function deposit(uint256 _amount) external;

    function withdrawAdmin(address _recipient, uint256 _amount) external;

    function moveDaiFromTreasuryToAave(uint256 _amountDAI) external;

    function moveDaiFromAaveToTreasury(uint256 _amountDAI) external;

    function moveEnoughDaiFromAaveToTreasury(uint256 _amountDAI) external;

    function reduceProtocolFeesEarned(uint256 _amount) external;

    function claimAaveRewards(
        address[] calldata _assets,
        uint256 _amountToClaim
    ) external;

    function setLendingPool(address _lendingPool) external;

    function setTokenAddresses(address _DAI, address _aDAI) external;

    function setAaveIncentivesController(address _newController) external;

    function shutdown(bool _isShutdown) external;

    function getDaiInTreasuryAndAave() external view returns (uint256, uint256);

    function getTotalDaiOwnedByArtizen() external view returns (uint256);
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