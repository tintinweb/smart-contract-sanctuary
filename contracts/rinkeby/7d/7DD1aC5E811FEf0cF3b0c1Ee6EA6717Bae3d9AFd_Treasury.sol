// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./interfaces/IController.sol";
import "./TellorVars.sol";
import "./interfaces/IGovernance.sol";

/**
 @author Tellor Inc.
 @title Treasury
 @dev This is the Treasury contract which defines the function for Tellor
 * treasuries, or staking pools.
*/
contract Treasury is TellorVars {
    // Storage
    uint256 public totalLocked; // amount of TRB locked across all treasuries
    uint256 public treasuryCount; // number of total treasuries
    mapping(uint256 => TreasuryDetails) public treasury; // maps an ID to a treasury and its corresponding details
    mapping(address => uint256) treasuryFundsByUser; // maps a treasury investor to their total treasury funds, in TRB

    // Structs
    // Internal struct used to keep track of an individual user in a treasury
    struct TreasuryUser {
        uint256 amount; // the amount the user has placed in a treasury, in TRB
        uint256 startVoteCount; // the amount of votes that have been cast when a user deposits their money into a treasury
        bool paid; // determines if a user has paid/voted in Tellor governance proposals
    }
    // Internal struct used to keep track of a treasury and its pertinent attributes (amount, interest rate, etc.)
    struct TreasuryDetails {
        uint256 dateStarted; // the date that treasury was started
        uint256 maxAmount; // the maximum amount stored in the treasury, in TRB
        uint256 rate; // the interest rate of the treasury, in BP
        uint256 purchasedAmount; // the amount of TRB purchased from the treasury
        uint256 duration; // the time in which the treasury locks participants
        uint256 endVoteCount; // the end vote count for when the treasury duration is over
        bool endVoteCountRecorded; // determines if the vote count has been calculated or not
        address[] owners; // the owners of the treasury
        mapping(address => TreasuryUser) accounts; // a mapping of a treasury user address and corresponding details
    }

    // Events
    event TreasuryIssued(uint256 _id, uint256 _amount, uint256 _rate);
    event TreasuryPaid(address _investor, uint256 _amount);
    event TreasuryPurchased(address _investor, uint256 _amount);

    // Functions
    /**
     * @dev This is an external function that is used to deposit money into a treasury.
     * @param _id is the ID for a specific treasury instance
     * @param _amount is the amount to deposit into a treasury
     */
    function buyTreasury(uint256 _id, uint256 _amount) external {
        // Transfer sender funds to Treasury
        require(_amount > 0, "Amount must be greater than zero.");
        require(
            IController(TELLOR_ADDRESS).approveAndTransferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Insufficient balance. Try a lower amount."
        );
        treasuryFundsByUser[msg.sender] += _amount;
        // Check for sufficient treasury funds
        TreasuryDetails storage _treas = treasury[_id];
        require(
            _treas.dateStarted + _treas.duration > block.timestamp,
            "Treasury duration has expired."
        );
        require(
            _amount <= _treas.maxAmount - _treas.purchasedAmount,
            "Not enough money in treasury left to purchase."
        );
        // Update treasury details -- vote count, purchasedAmount, amount, and owners
        address governanceContract = IController(TELLOR_ADDRESS).addresses(
            _GOVERNANCE_CONTRACT
        );
        if (_treas.accounts[msg.sender].amount == 0) {
            _treas.accounts[msg.sender].startVoteCount = IGovernance(
                governanceContract
            ).getVoteCount();
            _treas.owners.push(msg.sender);
        }
        _treas.purchasedAmount += _amount;
        _treas.accounts[msg.sender].amount += _amount;
        totalLocked += _amount;
        emit TreasuryPurchased(msg.sender, _amount);
    }

    /**
     * @dev This is an external function that is used to delegate voting rights from one TRB holder to another.
     * Note that only the governance contract can call this function.
     * @param _delegate is the address that the sender gives voting rights to
     */
    function delegateVotingPower(address _delegate) external {
        require(
            msg.sender ==
                IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT),
            "Only governance contract is allowed to delegate voting power."
        );
        IGovernance(msg.sender).delegate(_delegate);
    }

    /**
     * @dev This is an external function that is used to issue a new treasury.
     * Note that only the governance contract can call this function.
     * @param _maxAmount is the amount of total TRB that treasury stores
     * @param _rate is the treasury's interest rate in BP
     * @param _duration is the amount of time the treasury locks participants
     */
    function issueTreasury(
        uint256 _maxAmount,
        uint256 _rate,
        uint256 _duration
    ) external {
        require(
            msg.sender ==
                IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT),
            "Only governance contract is allowed to issue a treasury."
        );
        require(
            _maxAmount > 0 &&
                _maxAmount <= IController(TELLOR_ADDRESS).totalSupply(),
            "Invalid maxAmount value"
        );
        require(
            _duration > 0 && _duration <= 315360000,
            "Invalid duration value"
        );
        require(_rate > 0 && _rate <= 10000, "Invalid rate value");
        // Increment treasury count, and define new treasury and its details (start date, total amount, rate, etc.)
        treasuryCount++;
        TreasuryDetails storage _treas = treasury[treasuryCount];
        _treas.dateStarted = block.timestamp;
        _treas.maxAmount = _maxAmount;
        _treas.rate = _rate;
        _treas.duration = _duration;
        emit TreasuryIssued(treasuryCount, _maxAmount, _rate);
    }

    /**
     * @dev This functions allows an investor to pay the treasury. Internally, the function calculates the number of
     votes in governance contract when issued, and also transfers the amount individually locked + interest to the investor.
     * @param _id is the ID of the treasury the account is stored in
     * @param _investor is the address of the account in the treasury
     */
    function payTreasury(address _investor, uint256 _id) external {
        // Validate ID of treasury, duration for treasury has not passed, and the user has not paid
        TreasuryDetails storage treas = treasury[_id];
        require(
            _id <= treasuryCount,
            "ID does not correspond to a valid treasury."
        );
        require(
            treas.dateStarted + treas.duration <= block.timestamp,
            "Treasury duration has not expired."
        );
        require(
            !treas.accounts[_investor].paid,
            "Treasury investor has already been paid."
        );
        // Calculate non-voting penalty (treasury holders have to vote)
        uint256 numVotesParticipated;
        uint256 votesSinceTreasury;
        address governanceContract = IController(TELLOR_ADDRESS).addresses(
            _GOVERNANCE_CONTRACT
        );
        // Find endVoteCount if not already calculated
        if (!treas.endVoteCountRecorded) {
            uint256 voteCountIter = IGovernance(governanceContract)
                .getVoteCount();
            if (voteCountIter > 0) {
                (, uint256[8] memory voteInfo, , , , , ) = IGovernance(
                    governanceContract
                ).getVoteInfo(voteCountIter);
                while (
                    voteCountIter > 0 &&
                    voteInfo[1] > treas.dateStarted + treas.duration
                ) {
                    voteCountIter--;
                    if (voteCountIter > 0) {
                        (, voteInfo, , , , , ) = IGovernance(governanceContract)
                            .getVoteInfo(voteCountIter);
                    }
                }
            }
            treas.endVoteCount = voteCountIter;
            treas.endVoteCountRecorded = true;
        }
        // Add up number of votes _investor has participated in
        if (treas.endVoteCount > treas.accounts[_investor].startVoteCount) {
            for (
                uint256 voteCount = treas.accounts[_investor].startVoteCount;
                voteCount < treas.endVoteCount;
                voteCount++
            ) {
                bool voted = IGovernance(governanceContract).didVote(
                    voteCount + 1,
                    _investor
                );
                if (voted) {
                    numVotesParticipated++;
                }
                votesSinceTreasury++;
            }
        }
        // Determine amount of TRB to mint for interest
        uint256 _mintAmount = (treas.accounts[_investor].amount * treas.rate) /
            10000;
        if (votesSinceTreasury > 0) {
            _mintAmount =
                (_mintAmount * numVotesParticipated) /
                votesSinceTreasury;
        }
        if (_mintAmount > 0) {
            IController(TELLOR_ADDRESS).mint(address(this), _mintAmount);
        }
        // Transfer locked amount + interest amount, and indicate user has paid
        totalLocked -= treas.accounts[_investor].amount;
        IController(TELLOR_ADDRESS).transfer(
            _investor,
            _mintAmount + treas.accounts[_investor].amount
        );
        treasuryFundsByUser[_investor] -= treas.accounts[_investor].amount;
        treas.accounts[_investor].paid = true;
        emit TreasuryPaid(
            _investor,
            _mintAmount + treas.accounts[_investor].amount
        );
    }

    // Getters
    /**
     * @dev This function returns the details of an account within a treasury.
     * Note: refer to 'TreasuryUser' struct.
     * @param _id is the ID of the treasury the account is stored in
     * @param _investor is the address of the account in the treasury
     * @return uint256 of the amount of TRB the account has staked in the treasury
     * @return uint256 of the start vote count of when the account deposited money into the treasury
     * @return bool of whether the treasury account has paid or not
     */
    function getTreasuryAccount(uint256 _id, address _investor)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            treasury[_id].accounts[_investor].amount,
            treasury[_id].accounts[_investor].startVoteCount,
            treasury[_id].accounts[_investor].paid
        );
    }

    /**
     * @dev This function returns the number of treasuries/TellorX staking pools.
     * @return uint256 of the number of treasuries
     */
    function getTreasuryCount() external view returns (uint256) {
        return treasuryCount;
    }

    function getTreasuryDetails(uint256 _id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            treasury[_id].dateStarted,
            treasury[_id].maxAmount,
            treasury[_id].rate,
            treasury[_id].purchasedAmount
        );
    }

    /**
     * @dev This function returns the amount of deposited by a user into treasuries.
     * @param _user is the specific account within a treasury to look up
     * @return uint256 of the amount of funds the user has, in TRB
     */
    function getTreasuryFundsByUser(address _user)
        external
        view
        returns (uint256)
    {
        return treasuryFundsByUser[_user];
    }

    /**
     * @dev This function returns the addresses of the owners of a treasury
     * @param _id is the ID of a specific treasury
     * @return address[] memory of the addresses of the owners of the treasury
     */
    function getTreasuryOwners(uint256 _id)
        external
        view
        returns (address[] memory)
    {
        return treasury[_id].owners;
    }

    /**
     * @dev This function is used during the upgrade process to verify valid Tellor Contracts
     */
    function verify() external pure returns (uint256) {
        return 9999;
    }

    /**
     * @dev This function determines whether or not an investor in a treasury has paid/voted on Tellor governance proposals
     * @param _id is the ID of the treasury the account is stored in
     * @param _investor is the address of the account in the treasury
     * @return bool of whether or not the investor has paid
     */
    function wasPaid(uint256 _id, address _investor)
        external
        view
        returns (bool)
    {
        return treasury[_id].accounts[_investor].paid;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IController{
    function addresses(bytes32) external returns(address);
    function uints(bytes32) external returns(uint256);
    function burn(uint256 _amount) external;
    function changeDeity(address _newDeity) external;
    function changeOwner(address _newOwner) external;
    function changeTellorContract(address _tContract) external;
    function changeControllerContract(address _newController) external;
    function changeGovernanceContract(address _newGovernance) external;
    function changeOracleContract(address _newOracle) external;
    function changeTreasuryContract(address _newTreasury) external;
    function changeUint(bytes32 _target, uint256 _amount) external;
    function migrate() external;
    function mint(address _reciever, uint256 _amount) external;
    function init() external;
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256);
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256);
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function allowance(address _user, address _spender) external view  returns (uint256);
    function allowedToTrade(address _user, uint256 _amount) external view returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function approveAndTransferFrom(address _from, address _to, uint256 _amount) external returns(bool);
    function balanceOf(address _user) external view returns (uint256);
    function balanceOfAt(address _user, uint256 _blockNumber)external view returns (uint256);
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool success) ;
    function depositStake() external;
    function requestStakingWithdraw() external;
    function withdrawStake() external;
    function changeStakingStatus(address _reporter, uint _status) external;
    function slashReporter(address _reporter, address _disputer) external;
    function getStakerInfo(address _staker) external view returns (uint256, uint256);
    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index) external view returns (uint256);
    function getNewCurrentVariables()external view returns (bytes32 _c,uint256[5] memory _r,uint256 _d,uint256 _t);
    //in order to call fallback function
    function beginDispute(uint256 _requestId, uint256 _timestamp,uint256 _minerIndex) external;
    function unlockDisputeFee(uint256 _disputeId) external;
    function vote(uint256 _disputeId, bool _supportsDispute) external;
    function tallyVotes(uint256 _disputeId) external;
    //test functions
    function tipQuery(uint,uint,bytes memory) external;
    function getNewVariablesOnDeck() external view returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./tellor3/TellorVariables.sol";

/**
 @author Tellor Inc.
 @title TellorVariables
 @dev Helper contract to store hashes of variables.
 * For each of the bytes32 constants, the values are equal to
 * keccak256([VARIABLE NAME])
*/
contract TellorVars is TellorVariables {
    // Storage
    address constant TELLOR_ADDRESS =
        0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0; // Address of main Tellor Contract
    // Hashes for each pertinent contract
    bytes32 constant _GOVERNANCE_CONTRACT =
        0xefa19baa864049f50491093580c5433e97e8d5e41f8db1a61108b4fa44cacd93;
    bytes32 constant _ORACLE_CONTRACT =
        0xfa522e460446113e8fd353d7fa015625a68bc0369712213a42e006346440891e;
    bytes32 constant _TREASURY_CONTRACT =
        0x1436a1a60dca0ebb2be98547e57992a0fa082eb479e7576303cbd384e934f1fa;
    bytes32 constant _SWITCH_TIME =
        0x6c0e91a96227393eb6e42b88e9a99f7c5ebd588098b549c949baf27ac9509d8f;
    bytes32 constant _MINIMUM_DISPUTE_FEE =
        0x7335d16d7e7f6cb9f532376441907fe76aa2ea267285c82892601f4755ed15f0;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IGovernance{
    enum VoteResult {FAILED,PASSED,INVALID}
    function setApprovedFunction(bytes4 _func, bool _val) external;
    function beginDispute(bytes32 _queryId,uint256 _timestamp) external;
    function delegate(address _delegate) external;
    function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);
    function executeVote(uint256 _disputeId) external;
    function proposeVote(address _contract,bytes4 _function, bytes calldata _data, uint256 _timestamp) external;
    function tallyVotes(uint256 _disputeId) external;
    function updateMinDisputeFee() external;
    function verify() external pure returns(uint);
    function vote(uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function voteFor(address[] calldata _addys,uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function getDelegateInfo(address _holder) external view returns(address,uint);
    function isApprovedGovernanceContract(address _contract) external view returns(bool);
    function isFunctionApproved(bytes4 _func) external view returns(bool);
    function getVoteCount() external view returns(uint256);
    function getVoteRounds(bytes32 _hash) external view returns(uint256[] memory);
    function getVoteInfo(uint256 _disputeId) external view returns(bytes32,uint256[8] memory,bool[2] memory,VoteResult,bytes memory,bytes4,address[2] memory);
    function getDisputeInfo(uint256 _disputeId) external view returns(uint256,uint256,bytes memory, address);
    function getOpenDisputesOnId(uint256 _disputeId) external view returns(uint256);
    function didVote(uint256 _disputeId, address _voter) external view returns(bool);
    //testing
    function testMin(uint256 a, uint256 b) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

/**
 @author Tellor Inc.
 @title TellorVariables
 @dev Helper contract to store hashes of variables
*/
contract TellorVariables {
    bytes32 constant _BLOCK_NUMBER =
        0x4b4cefd5ced7569ef0d091282b4bca9c52a034c56471a6061afd1bf307a2de7c; //keccak256("_BLOCK_NUMBER");
    bytes32 constant _CURRENT_CHALLENGE =
        0xd54702836c9d21d0727ffacc3e39f57c92b5ae0f50177e593bfb5ec66e3de280; //keccak256("_CURRENT_CHALLENGE");
    bytes32 constant _CURRENT_REQUESTID =
        0xf5126bb0ac211fbeeac2c0e89d4c02ac8cadb2da1cfb27b53c6c1f4587b48020; //keccak256("_CURRENT_REQUESTID");
    bytes32 constant _CURRENT_REWARD =
        0xd415862fd27fb74541e0f6f725b0c0d5b5fa1f22367d9b78ec6f61d97d05d5f8; //keccak256("_CURRENT_REWARD");
    bytes32 constant _CURRENT_TOTAL_TIPS =
        0x09659d32f99e50ac728058418d38174fe83a137c455ff1847e6fb8e15f78f77a; //keccak256("_CURRENT_TOTAL_TIPS");
    bytes32 constant _DEITY =
        0x5fc094d10c65bc33cc842217b2eccca0191ff24148319da094e540a559898961; //keccak256("_DEITY");
    bytes32 constant _DIFFICULTY =
        0xf758978fc1647996a3d9992f611883adc442931dc49488312360acc90601759b; //keccak256("_DIFFICULTY");
    bytes32 constant _DISPUTE_COUNT =
        0x310199159a20c50879ffb440b45802138b5b162ec9426720e9dd3ee8bbcdb9d7; //keccak256("_DISPUTE_COUNT");
    bytes32 constant _DISPUTE_FEE =
        0x675d2171f68d6f5545d54fb9b1fb61a0e6897e6188ca1cd664e7c9530d91ecfc; //keccak256("_DISPUTE_FEE");
    bytes32 constant _DISPUTE_ROUNDS =
        0x6ab2b18aafe78fd59c6a4092015bddd9fcacb8170f72b299074f74d76a91a923; //keccak256("_DISPUTE_ROUNDS");
    bytes32 constant _EXTENSION =
        0x2b2a1c876f73e67ebc4f1b08d10d54d62d62216382e0f4fd16c29155818207a4; //keccak256("_EXTENSION");
    bytes32 constant _FEE =
        0x1da95f11543c9b03927178e07951795dfc95c7501a9d1cf00e13414ca33bc409; //keccak256("_FEE");
    bytes32 constant _FORK_EXECUTED =
        0xda571dfc0b95cdc4a3835f5982cfdf36f73258bee7cb8eb797b4af8b17329875; //keccak256("_FORK_EXECUTED");
    bytes32 constant _LOCK =
        0xd051321aa26ce60d202f153d0c0e67687e975532ab88ce92d84f18e39895d907;
    bytes32 constant _MIGRATOR =
        0xc6b005d45c4c789dfe9e2895b51df4336782c5ff6bd59a5c5c9513955aa06307; //keccak256("_MIGRATOR");
    bytes32 constant _MIN_EXECUTION_DATE =
        0x46f7d53798d31923f6952572c6a19ad2d1a8238d26649c2f3493a6d69e425d28; //keccak256("_MIN_EXECUTION_DATE");
    bytes32 constant _MINER_SLOT =
        0x6de96ee4d33a0617f40a846309c8759048857f51b9d59a12d3c3786d4778883d; //keccak256("_MINER_SLOT");
    bytes32 constant _NUM_OF_VOTES =
        0x1da378694063870452ce03b189f48e04c1aa026348e74e6c86e10738514ad2c4; //keccak256("_NUM_OF_VOTES");
    bytes32 constant _OLD_TELLOR =
        0x56e0987db9eaec01ed9e0af003a0fd5c062371f9d23722eb4a3ebc74f16ea371; //keccak256("_OLD_TELLOR");
    bytes32 constant _ORIGINAL_ID =
        0xed92b4c1e0a9e559a31171d487ecbec963526662038ecfa3a71160bd62fb8733; //keccak256("_ORIGINAL_ID");
    bytes32 constant _OWNER =
        0x7a39905194de50bde334d18b76bbb36dddd11641d4d50b470cb837cf3bae5def; //keccak256("_OWNER");
    bytes32 constant _PAID =
        0x29169706298d2b6df50a532e958b56426de1465348b93650fca42d456eaec5fc; //keccak256("_PAID");
    bytes32 constant _PENDING_OWNER =
        0x7ec081f029b8ac7e2321f6ae8c6a6a517fda8fcbf63cabd63dfffaeaafa56cc0; //keccak256("_PENDING_OWNER");
    bytes32 constant _REQUEST_COUNT =
        0x3f8b5616fa9e7f2ce4a868fde15c58b92e77bc1acd6769bf1567629a3dc4c865; //keccak256("_REQUEST_COUNT");
    bytes32 constant _REQUEST_ID =
        0x9f47a2659c3d32b749ae717d975e7962959890862423c4318cf86e4ec220291f; //keccak256("_REQUEST_ID");
    bytes32 constant _REQUEST_Q_POSITION =
        0xf68d680ab3160f1aa5d9c3a1383c49e3e60bf3c0c031245cbb036f5ce99afaa1; //keccak256("_REQUEST_Q_POSITION");
    bytes32 constant _SLOT_PROGRESS =
        0xdfbec46864bc123768f0d134913175d9577a55bb71b9b2595fda21e21f36b082; //keccak256("_SLOT_PROGRESS");
    bytes32 constant _STAKE_AMOUNT =
        0x5d9fadfc729fd027e395e5157ef1b53ef9fa4a8f053043c5f159307543e7cc97; //keccak256("_STAKE_AMOUNT");
    bytes32 constant _STAKE_COUNT =
        0x10c168823622203e4057b65015ff4d95b4c650b308918e8c92dc32ab5a0a034b; //keccak256("_STAKE_COUNT");
    bytes32 constant _T_BLOCK =
        0xf3b93531fa65b3a18680d9ea49df06d96fbd883c4889dc7db866f8b131602dfb; //keccak256("_T_BLOCK");
    bytes32 constant _TALLY_DATE =
        0xf9e1ae10923bfc79f52e309baf8c7699edb821f91ef5b5bd07be29545917b3a6; //keccak256("_TALLY_DATE");
    bytes32 constant _TARGET_MINERS =
        0x0b8561044b4253c8df1d9ad9f9ce2e0f78e4bd42b2ed8dd2e909e85f750f3bc1; //keccak256("_TARGET_MINERS");
    bytes32 constant _TELLOR_CONTRACT =
        0x0f1293c916694ac6af4daa2f866f0448d0c2ce8847074a7896d397c961914a08; //keccak256("_TELLOR_CONTRACT");
    bytes32 constant _TELLOR_GETTERS =
        0xabd9bea65759494fe86471c8386762f989e1f2e778949e94efa4a9d1c4b3545a; //keccak256("_TELLOR_GETTERS");
    bytes32 constant _TIME_OF_LAST_NEW_VALUE =
        0x2c8b528fbaf48aaf13162a5a0519a7ad5a612da8ff8783465c17e076660a59f1; //keccak256("_TIME_OF_LAST_NEW_VALUE");
    bytes32 constant _TIME_TARGET =
        0xd4f87b8d0f3d3b7e665df74631f6100b2695daa0e30e40eeac02172e15a999e1; //keccak256("_TIME_TARGET");
    bytes32 constant _TIMESTAMP =
        0x2f9328a9c75282bec25bb04befad06926366736e0030c985108445fa728335e5; //keccak256("_TIMESTAMP");
    bytes32 constant _TOTAL_SUPPLY =
        0xe6148e7230ca038d456350e69a91b66968b222bfac9ebfbea6ff0a1fb7380160; //keccak256("_TOTAL_SUPPLY");
    bytes32 constant _TOTAL_TIP =
        0x1590276b7f31dd8e2a06f9a92867333eeb3eddbc91e73b9833e3e55d8e34f77d; //keccak256("_TOTAL_TIP");
    bytes32 constant _VALUE =
        0x9147231ab14efb72c38117f68521ddef8de64f092c18c69dbfb602ffc4de7f47; //keccak256("_VALUE");
    bytes32 constant _EIP_SLOT =
        0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;
}