// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./TellorStaking.sol";
import "./interfaces/IController.sol";
import "./Transition.sol";
import "./Getters.sol";

/**
 @author Tellor Inc.
 @title Controller
 @dev This is the Controller contract which defines the functionality for
 * changing contract addresses, as well as minting and migrating tokens
*/
contract Controller is TellorStaking, Transition, Getters {
    // Functions
    constructor(
        address _governance,
        address _oracle,
        address _treasury
    ) Transition(_governance, _oracle, _treasury) {}

    /**
     * @dev Changes Controller contract to a new address
     * Note: this function is only callable by the Governance contract.
     * @param _newController is the address of the new Controller contract
     */
    function changeControllerContract(address _newController) external {
        require(
            msg.sender == addresses[_GOVERNANCE_CONTRACT],
            "Only the Governance contract can change the Controller contract address"
        );
        require(_isValid(_newController));
        addresses[_TELLOR_CONTRACT] = _newController; //name _TELLOR_CONTRACT is hardcoded in
        assembly {
            sstore(_EIP_SLOT, _newController)
        }
    }

    /**
     * @dev Changes Governance contract to a new address
     * Note: this function is only callable by the Governance contract.
     * @param _newGovernance is the address of the new Governance contract
     */
    function changeGovernanceContract(address _newGovernance) external {
        require(
            msg.sender == addresses[_GOVERNANCE_CONTRACT],
            "Only the Governance contract can change the Governance contract address"
        );
        require(_isValid(_newGovernance));
        addresses[_GOVERNANCE_CONTRACT] = _newGovernance;
    }

    /**
     * @dev Changes Oracle contract to a new address
     * Note: this function is only callable by the Governance contract.
     * @param _newOracle is the address of the new Oracle contract
     */
    function changeOracleContract(address _newOracle) external {
        require(
            msg.sender == addresses[_GOVERNANCE_CONTRACT],
            "Only the Governance contract can change the Oracle contract address"
        );
        require(_isValid(_newOracle));
        addresses[_ORACLE_CONTRACT] = _newOracle;
    }

    /**
     * @dev Changes Treasury contract to a new address
     * Note: this function is only callable by the Governance contract.
     * @param _newTreasury is the address of the new Treasury contract
     */
    function changeTreasuryContract(address _newTreasury) external {
        require(
            msg.sender == addresses[_GOVERNANCE_CONTRACT],
            "Only the Governance contract can change the Treasury contract address"
        );
        require(_isValid(_newTreasury));
        addresses[_TREASURY_CONTRACT] = _newTreasury;
    }

    /**
     * @dev Changes a uint for a specific target index
     * Note: this function is only callable by the Governance contract.
     * @param _target is the index of the uint to change
     * @param _amount is the amount to change the given uint to
     */
    function changeUint(bytes32 _target, uint256 _amount) external {
        require(
            msg.sender == addresses[_GOVERNANCE_CONTRACT],
            "Only the Governance contract can change the uint"
        );
        uints[_target] = _amount;
    }

    /**
     * @dev Mints tokens of the sender from the old contract to the sender
     */
    function migrate() external {
        require(!migrated[msg.sender], "Already migrated");
        _doMint(
            msg.sender,
            IController(addresses[_OLD_TELLOR]).balanceOf(msg.sender)
        );
        migrated[msg.sender] = true;
    }

    /**
     * @dev Mints TRB for a certain address
     * Note: this function is only callable by the Governance contract.
     * @param _receiver is the address of the contract that will receive the minted tokens
     * @param _amount is the amount of tokens that will be minted for the _receiver address
     */
    function mint(address _receiver, uint256 _amount) external {
        require(
            msg.sender == addresses[_GOVERNANCE_CONTRACT] ||
                msg.sender == addresses[_TREASURY_CONTRACT] ||
                msg.sender == TELLOR_ADDRESS,
            "Only an admin can mint tokens"
        );
        _doMint(_receiver, _amount);
    }

    /**
     * @dev Used during the upgrade process to verify valid Tellor Contracts
     */
    function verify() external pure returns (uint256) {
        return 9999;
    }

    /**
     * @dev Used during the upgrade process to verify valid Tellor Contracts and ensure
     * they have the right signature
     * @param _contract is the address of the Tellor contract to verify
     * @return bool of whether or not the address is a valid Tellor contract
     */
    function _isValid(address _contract) internal returns (bool) {
        (bool _success, bytes memory _data) = address(_contract).call(
            abi.encodeWithSelector(0xfc735e99, "") // verify() signature
        );
        require(
            _success && abi.decode(_data, (uint256)) > 9000, // An arbitrary number to ensure that the contract is valid
            "new contract is invalid"
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Token.sol";
import "./interfaces/IGovernance.sol";

/**
 @author Tellor Inc.
 @title TellorStaking
 @dev This is the TellorStaking contract which defines the functionality for
 * updating staking statuses for reporters, including depositing and withdrawing
 * stakes.
*/
contract TellorStaking is Token {
    // Events
    event NewStaker(address _staker);
    event StakeWithdrawRequested(address _staker);
    event StakeWithdrawn(address _staker);

    // Functions
    /**
     * @dev Changes staking status of a reporter
     * Note: this function is only callable by the Governance contract.
     * @param _reporter is the address of the reporter to change staking status for
     * @param _status is the new status of the reporter
     */
    function changeStakingStatus(address _reporter, uint256 _status) external {
        require(
            IGovernance(addresses[_GOVERNANCE_CONTRACT])
                .isApprovedGovernanceContract(msg.sender),
            "Only approved governance contract can change staking status"
        );
        StakeInfo storage stakes = stakerDetails[_reporter];
        stakes.currentStatus = _status;
    }

    /**
     * @dev Allows a reporter to submit stake
     */
    function depositStake() external {
        // Ensure staker has enough balance to stake
        require(
            balances[msg.sender][balances[msg.sender].length - 1].value >=
                uints[_STAKE_AMOUNT],
            "Balance is lower than stake amount"
        );
        // Ensure staker is currently either not staked or locked for withdraw.
        // Note that slashed reporters cannot stake again from slashed address.
        require(
            stakerDetails[msg.sender].currentStatus == 0 ||
                stakerDetails[msg.sender].currentStatus == 2,
            "Reporter is in the wrong state"
        );
        // Increment number of stakers, create new staker, and update dispute fee
        uints[_STAKE_COUNT] += 1;
        stakerDetails[msg.sender] = StakeInfo({
            currentStatus: 1,
            startDate: block.timestamp // This resets their stake start date to now
        });
        emit NewStaker(msg.sender);
        IGovernance(addresses[_GOVERNANCE_CONTRACT]).updateMinDisputeFee();
    }

    /**
     * @dev Allows a reporter to request to withdraw their stake
     */
    function requestStakingWithdraw() external {
        // Ensures reporter is already staked
        StakeInfo storage stakes = stakerDetails[msg.sender];
        require(stakes.currentStatus == 1, "Reporter is not staked");
        // Change status to reflect withdraw request and updates start date for staking
        stakes.currentStatus = 2;
        stakes.startDate = block.timestamp;
        // Update number of stakers and dispute fee
        uints[_STAKE_COUNT] -= 1;
        IGovernance(addresses[_GOVERNANCE_CONTRACT]).updateMinDisputeFee();
        emit StakeWithdrawRequested(msg.sender);
    }

    /**
     * @dev Slashes a reporter and transfers their stake amount to their disputer
     * Note: this function is only callable by the Governance contract.
     * @param _reporter is the address of the reporter being slashed
     * @param _disputer is the address of the disputer receiving the reporter's stake
     */
    function slashReporter(address _reporter, address _disputer) external {
        require(
            IGovernance(addresses[_GOVERNANCE_CONTRACT])
                .isApprovedGovernanceContract(msg.sender),
            "Only approved governance contract can slash reporter"
        );
        stakerDetails[_reporter].currentStatus = 5; // Change status of reporter to slashed
        // Transfer stake amount of reporter has a balance bigger than the stake amount
        if (balanceOf(_reporter) >= uints[_STAKE_AMOUNT]) {
            _doTransfer(_reporter, _disputer, uints[_STAKE_AMOUNT]);
        }
        // Else, transfer all of the reporter's balance
        else if (balanceOf(_reporter) > 0) {
            _doTransfer(_reporter, _disputer, balanceOf(_reporter));
        }
    }

    /**
     * @dev Withdraws a reporter's stake
     */
    function withdrawStake() external {
        StakeInfo storage _s = stakerDetails[msg.sender];
        // Ensure reporter is locked and that enough time has passed
        require(block.timestamp - _s.startDate >= 7 days, "7 days didn't pass");
        require(_s.currentStatus == 2, "Reporter not locked for withdrawal");
        _s.currentStatus = 0; // Updates status to withdrawn
        emit StakeWithdrawn(msg.sender);
    }

    /**GETTERS**/
    /**
     * @dev Allows users to retrieve all information about a staker
     * @param _staker address of staker inquiring about
     * @return uint current state of staker
     * @return uint startDate of staking
     */
    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256)
    {
        return (
            stakerDetails[_staker].currentStatus,
            stakerDetails[_staker].startDate
        );
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

import "./tellor3/TellorStorage.sol";
import "./TellorVars.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IController.sol";

/**
 @author Tellor Inc.
 @title Transition
* @dev The Transition contract links to the Oracle contract and
* allows parties (like Liquity) to continue to use the master
* address to access values. All parties should be reading values
* through this address
*/
contract Transition is TellorStorage, TellorVars {
    // Functions
    /**
     * @dev Saves new Tellor contract addresses. Available to init function after fork vote
     * @param _governance is the address of the Governance contract
     * @param _oracle is the address of the Oracle contract
     * @param _treasury is the address of the Treasury contract
     */
    constructor(
        address _governance,
        address _oracle,
        address _treasury
    ) {
        require(_governance != address(0), "must set governance address");
        addresses[_GOVERNANCE_CONTRACT] = _governance;
        addresses[_ORACLE_CONTRACT] = _oracle;
        addresses[_TREASURY_CONTRACT] = _treasury;
    }

    /**
     * @dev Runs once Tellor is migrated over. Changes the underlying storage.
     */
    function init() external {
        require(
            addresses[_GOVERNANCE_CONTRACT] == address(0),
            "Only good once"
        );
        // Set state amount, switch time, and minimum dispute fee
        uints[_STAKE_AMOUNT] = 100e18;
        uints[_SWITCH_TIME] = block.timestamp;
        uints[_MINIMUM_DISPUTE_FEE] = 10e18;
        // Define contract addresses
        Transition _controller = Transition(addresses[_TELLOR_CONTRACT]);
        addresses[_GOVERNANCE_CONTRACT] = _controller.addresses(
            _GOVERNANCE_CONTRACT
        );
        addresses[_ORACLE_CONTRACT] = _controller.addresses(_ORACLE_CONTRACT);
        addresses[_TREASURY_CONTRACT] = _controller.addresses(
            _TREASURY_CONTRACT
        );
        IController(TELLOR_ADDRESS).mint(
            addresses[_ORACLE_CONTRACT],
            105120e18
        );
        // IController(TELLOR_ADDRESS).mint(TEAM_VESTING_CONTRACT, 105120e18);
    }

    //Getters
    /**
     * @dev Allows users to access the number of decimals
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @dev Allows Tellor to read data from the addressVars mapping
     * @param _data is the keccak256("variable_name") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_owner")]
     * addressVars[keccak256("tellorContract")]
     * @return address of the requested variable
     */
    function getAddressVars(bytes32 _data) external view returns (address) {
        return addresses[_data];
    }

    /**
     * @dev Gets all dispute variables
     * @param _disputeId to look up
     * @return bytes32 hash of dispute
     * bool executed where true if it has been voted on
     * bool disputeVotePassed
     * bool isPropFork true if the dispute is a proposed fork
     * address of reportedMiner
     * address of reportingParty
     * address of proposedForkAddress
     * uint of requestId
     * uint of timestamp
     * uint of value
     * uint of minExecutionDate
     * uint of numberOfVotes
     * uint of blocknumber
     * uint of minerSlot
     * uint of quorum
     * uint of fee
     * int count of the current tally
     */
    function getAllDisputeVars(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        )
    {
        Dispute storage disp = disputesById[_disputeId];
        return (
            disp.hash,
            disp.executed,
            disp.disputeVotePassed,
            disp.isPropFork,
            disp.reportedMiner,
            disp.reportingParty,
            disp.proposedForkAddress,
            [
                disp.disputeUintVars[_REQUEST_ID],
                disp.disputeUintVars[_TIMESTAMP],
                disp.disputeUintVars[_VALUE],
                disp.disputeUintVars[_MIN_EXECUTION_DATE],
                disp.disputeUintVars[_NUM_OF_VOTES],
                disp.disputeUintVars[_BLOCK_NUMBER],
                disp.disputeUintVars[_MINER_SLOT],
                disp.disputeUintVars[keccak256("quorum")],
                disp.disputeUintVars[_FEE]
            ],
            disp.tally
        );
    }

    /**
     * @dev Gets id if a given hash has been disputed
     * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId,_timestamp));
     * @return uint disputeId
     */
    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256)
    {
        return disputeIdByDisputeHash[_hash];
    }

    /**
     * @dev Checks for uint variables in the disputeUintVars mapping based on the disputeId
     * @param _disputeId is the dispute id;
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the disputeUintVars under the Dispute struct
     * @return uint value for the bytes32 data submitted
     */
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256)
    {
        return disputesById[_disputeId].disputeUintVars[_data];
    }

    /**
     * @dev Returns the latest value for a specific request ID.
     * @param _requestId the requestId to look up
     * @return uint256 of the value of the latest value of the request ID
     * @return bool of whether or not the value was successfully retrieved
     */
    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool)
    {
        // Try the new contract first
        uint256 _timeCount = IOracle(addresses[_ORACLE_CONTRACT])
            .getTimestampCountById(bytes32(_requestId));
        if (_timeCount != 0) {
            // If timestamps for the ID exist, there is value, so return the value
            return (
                retrieveData(
                    _requestId,
                    IOracle(addresses[_ORACLE_CONTRACT])
                        .getReportTimestampByIndex(
                            bytes32(_requestId),
                            _timeCount - 1
                        )
                ),
                true
            );
        } else {
            // Else, look at old value + timestamps since mining has not started
            Request storage _request = requestDetails[_requestId];
            if (_request.requestTimestamps.length != 0) {
                return (
                    retrieveData(
                        _requestId,
                        _request.requestTimestamps[
                            _request.requestTimestamps.length - 1
                        ]
                    ),
                    true
                );
            } else {
                return (0, false);
            }
        }
    }

    /**
     * @dev Function is solely for the parachute contract
     */
    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _c,
            uint256[5] memory _r,
            uint256 _diff,
            uint256 _tip
        )
    {
        _r = [uint256(1), uint256(1), uint256(1), uint256(1), uint256(1)];
        _diff = 0;
        _tip = 0;
        _c = keccak256(
            abi.encode(
                IOracle(addresses[_ORACLE_CONTRACT]).getTimeOfLastNewValue()
            )
        );
    }

    /**
     * @dev Counts the number of values that have been submitted for the request.
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256)
    {
        // Defaults to new one, but will give old value if new mining has not started
        uint256 _val = IOracle(addresses[_ORACLE_CONTRACT])
            .getTimestampCountById(bytes32(_requestId));
        if (_val > 0) {
            return _val;
        } else {
            return requestDetails[_requestId].requestTimestamps.length;
        }
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestId is the requestId to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
        external
        view
        returns (uint256)
    {
        // Try new contract first, but give old timestamp if new mining has not started
        try
            IOracle(addresses[_ORACLE_CONTRACT]).getReportTimestampByIndex(
                bytes32(_requestId),
                _index
            )
        returns (uint256 _val) {
            return _val;
        } catch {
            return requestDetails[_requestId].requestTimestamps[_index];
        }
    }

    /**
     * @dev Getter for the variables saved under the TellorStorageStruct uints variable
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name")
     * where variable_name is the variables/strings used to save the data in the mapping.
     * The variables names in the TellorVariables contract
     * @return uint of specified variable
     */
    function getUintVar(bytes32 _data) external view returns (uint256) {
        return uints[_data];
    }

    /**
     * @dev Getter for if the party is migrated
     * @param _addy address of party
     * @return if the party is migrated
     */
    function isMigrated(address _addy) external view returns (bool) {
        return migrated[_addy];
    }

    /**
     * @dev Allows users to access the token's name
     */
    function name() external pure returns (string memory) {
        return "Tellor Tributes";
    }

    /**
     * @dev Retrieve value from oracle based on timestamp
     * @param _requestId being requested
     * @param _timestamp to retrieve data/value from
     * @return value for timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        if (_timestamp < uints[_SWITCH_TIME]) {
            return requestDetails[_requestId].finalValues[_timestamp];
        }
        return
            _sliceUint(
                IOracle(addresses[_ORACLE_CONTRACT]).getValueByTimestamp(
                    bytes32(_requestId),
                    _timestamp
                )
            );
    }

    /**
     * @dev Allows users to access the token's symbol
     */
    function symbol() external pure returns (string memory) {
        return "TRB";
    }

    /**
     * @dev Getter for the total_supply of oracle tokens
     * @return uint total supply
     */
    function totalSupply() external view returns (uint256) {
        return uints[_TOTAL_SUPPLY];
    }

    /**
     * @dev Allows Tellor X to fallback to the old Tellor if there are current open disputes
     * (or disputes on old Tellor values)
     */
    fallback() external {
        address _addr = 0x2754da26f634E04b26c4deCD27b3eb144Cf40582; // Main Tellor address (Harcode this in?)
        // Obtain function header from msg.data
        bytes4 _function;
        for (uint256 i = 0; i < 4; i++) {
            _function |= bytes4(msg.data[i] & 0xFF) >> (i * 8);
        }
        // Ensure that the function is allowed and related to disputes, voting, and dispute fees
        require(
            _function ==
                bytes4(
                    bytes32(keccak256("beginDispute(uint256,uint256,uint256)"))
                ) ||
                _function == bytes4(bytes32(keccak256("vote(uint256,bool)"))) ||
                _function ==
                bytes4(bytes32(keccak256("tallyVotes(uint256)"))) ||
                _function ==
                bytes4(bytes32(keccak256("unlockDisputeFee(uint256)"))),
            "function should be allowed"
        ); //should autolock out after a week (no disputes can begin past a week)
        // Calls the function in msg.data from main Tellor address
        (bool _result, ) = _addr.delegatecall(msg.data);
        assembly {
            returndatacopy(0, 0, returndatasize())
            switch _result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // Internal
    /**
     * @dev Utilized to help slice a bytes variable into a uint
     * @param _b is the bytes variable to be sliced
     * @return _x of the sliced uint256
     */
    function _sliceUint(bytes memory _b) public pure returns (uint256 _x) {
        uint256 _number = 0;
        for (uint256 _i = 0; _i < _b.length; _i++) {
            _number = _number * 2**8;
            _number = _number + uint8(_b[_i]);
        }
        return _number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./tellor3/TellorStorage.sol";
import "./TellorVars.sol";
import "./interfaces/IOracle.sol";

/**
 @author Tellor Inc.
 @title Getters
* @dev The Getters contract links to the Oracle contract and
* allows parties to continue to use the master
* address to access bytes values. All parties should be reading values
* through this address
*/
contract Getters is TellorStorage, TellorVars {
    // Functions
    /**
     * @dev Counts the number of values that have been submitted for the request.
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the id
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        return (
            IOracle(addresses[_ORACLE_CONTRACT]).getTimestampCountById(_queryId)
        );
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _queryId is the id to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return (
            IOracle(addresses[_ORACLE_CONTRACT]).getReportTimestampByIndex(
                _queryId,
                _index
            )
        );
    }

    /**
     * @dev Retrieve value from oracle based on timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        return (
            IOracle(addresses[_ORACLE_CONTRACT]).getValueByTimestamp(
                _queryId,
                _timestamp
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./tellor3/TellorStorage.sol";
import "./TellorVars.sol";
import "./interfaces/IGovernance.sol";

/**
 @author Tellor Inc.
 @title Token
 @dev Contains the methods related to transfers and ERC20, its storage
 * and hashes of tellor variables that are used to save gas on transactions.
*/
contract Token is TellorStorage, TellorVars {
    // Events
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    ); // ERC20 Approval event
    event Transfer(address indexed _from, address indexed _to, uint256 _value); // ERC20 Transfer Event

    // Functions
    /**
     * @dev Getter function for remaining spender balance
     * @param _user address of party with the balance
     * @param _spender address of spender of parties said balance
     * @return Returns the remaining allowance of tokens granted to the _spender from the _user
     */
    function allowance(address _user, address _spender)
        external
        view
        returns (uint256)
    {
        return _allowances[_user][_spender];
    }

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * and removing the staked amount from their balance if they are staked
     * @param _user address of user
     * @param _amount to check if the user can spend
     * @return true if they are allowed to spend the amount being checked
     */
    function allowedToTrade(address _user, uint256 _amount)
        public
        view
        returns (bool)
    {
        if (
            stakerDetails[_user].currentStatus != 0 &&
            stakerDetails[_user].currentStatus < 5
        ) {
            // Subtracts the stakeAmount from balance if the _user is staked
            return (balanceOf(_user) - uints[_STAKE_AMOUNT] >= _amount);
        }
        return (balanceOf(_user) >= _amount); // Else, check if balance is greater than amount they want to spend
    }

    /**
     * @dev This function approves a _spender an _amount of tokens to use
     * @param _spender address
     * @param _amount amount the spender is being approved for
     * @return true if spender approved successfully
     */
    function approve(address _spender, uint256 _amount)
        external
        returns (bool)
    {
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev This function approves a transfer of _amount tokens from _from to _to
     * @param _from is the address the tokens will be transferred from
     * @param _to is the address the tokens will be transferred to
     * @param _amount is the number of tokens to transfer
     * @return true if spender approved successfully
     */
    function approveAndTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        require(
            (IGovernance(addresses[_GOVERNANCE_CONTRACT])
                .isApprovedGovernanceContract(msg.sender) ||
                msg.sender == addresses[_TREASURY_CONTRACT] ||
                msg.sender == addresses[_ORACLE_CONTRACT]),
            "Only the Governance, Treasury, or Oracle Contract can approve and transfer tokens"
        );
        _doTransfer(_from, _to, _amount);
        return true;
    }

    /**
     * @dev Gets balance of owner specified
     * @param _user is the owner address used to look up the balance
     * @return Returns the balance associated with the passed in _user
     */
    function balanceOf(address _user) public view returns (uint256) {
        return balanceOfAt(_user, block.number);
    }

    /**
     * @dev Queries the balance of _user at a specific _blockNumber
     * @param _user The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at _blockNumber specified
     */
    function balanceOfAt(address _user, uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        TellorStorage.Checkpoint[] storage checkpoints = balances[_user];
        if (
            checkpoints.length == 0 || checkpoints[0].fromBlock > _blockNumber
        ) {
            return 0;
        } else {
            if (_blockNumber >= checkpoints[checkpoints.length - 1].fromBlock)
                return checkpoints[checkpoints.length - 1].value;
            // Binary search of the value in the array
            uint256 _min = 0;
            uint256 _max = checkpoints.length - 2;
            while (_max > _min) {
                uint256 _mid = (_max + _min + 1) / 2;
                if (checkpoints[_mid].fromBlock == _blockNumber) {
                    return checkpoints[_mid].value;
                } else if (checkpoints[_mid].fromBlock < _blockNumber) {
                    _min = _mid;
                } else {
                    _max = _mid - 1;
                }
            }
            return checkpoints[_min].value;
        }
    }

    /**
     * @dev Burns an amount of tokens
     * @param _amount is the amount of tokens to burn
     */
    function burn(uint256 _amount) external {
        _doBurn(msg.sender, _amount);
    }

    /**
     * @dev Allows for a transfer of tokens to _to
     * @param _to The address to send tokens to
     * @param _amount The amount of tokens to send
     */
    function transfer(address _to, uint256 _amount)
        external
        returns (bool success)
    {
        _doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @notice Send _amount tokens to _to from _from on the condition it
     * is approved by _from
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool success) {
        require(
            _allowances[_from][msg.sender] >= _amount,
            "Allowance is wrong"
        );
        _allowances[_from][msg.sender] -= _amount;
        _doTransfer(_from, _to, _amount);
        return true;
    }

    // Internal
    /**
     * @dev Helps burn TRB Tokens
     * @param _from is the address to burn or remove TRB amount
     * @param _amount is the amount of TRB to burn
     */
    function _doBurn(address _from, uint256 _amount) internal {
        // Ensure that amount of balance are valid
        if (_amount == 0) return;
        require(
            allowedToTrade(_from, _amount),
            "Should have sufficient balance to trade"
        );
        uint128 _previousBalance = uint128(balanceOf(_from));
        uint128 _sizedAmount = uint128(_amount);
        // Update total supply and balance of _from
        _updateBalanceAtNow(_from, _previousBalance - _sizedAmount);
        uints[_TOTAL_SUPPLY] -= _amount;
    }

    /**
     * @dev Helps swap the old Tellor contract Tokens to the new one
     * @param _to is the address to send minted amount to
     * @param _amount is the amount of TRB to send
     */
    function _doMint(address _to, uint256 _amount) internal {
        // Ensure to address and mint amount are valid
        require(_amount != 0, "Tried to mint non-positive amount");
        require(_to != address(0), "Receiver is 0 address");
        uint128 _previousBalance = uint128(balanceOf(_to));
        uint128 _sizedAmount = uint128(_amount);
        // Update total supply and balance of _to address
        uints[_TOTAL_SUPPLY] += _amount;
        _updateBalanceAtNow(_to, _previousBalance + _sizedAmount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev Completes transfers by updating the balances on the current block number
     * and ensuring the amount does not contain tokens staked for reporting
     * @param _from address to transfer from
     * @param _to address to transfer to
     * @param _amount to transfer
     */
    function _doTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        // Ensure user has a correct balance and to address
        require(_amount != 0, "Tried to send non-positive amount");
        require(_to != address(0), "Receiver is 0 address");
        require(
            allowedToTrade(_from, _amount),
            "Should have sufficient balance to trade"
        );
        // Update balance of _from address
        uint128 _previousBalance = uint128(balanceOf(_from));
        uint128 _sizedAmount = uint128(_amount);
        _updateBalanceAtNow(_from, _previousBalance - _sizedAmount);
        // Update balance of _to address
        _previousBalance = uint128(balanceOf(_to));
        _updateBalanceAtNow(_to, _previousBalance + _sizedAmount);
        emit Transfer(_from, _to, _amount);
    }

    /**
     * @dev Updates balance for from and to on the current block number via doTransfer
     * @param _value is the new balance
     */
    function _updateBalanceAtNow(address _user, uint128 _value) internal {
        Checkpoint[] storage checkpoints = balances[_user];
        // Checks if no checkpoints exist, or if checkpoint block is not current block
        if (
            checkpoints.length == 0 ||
            checkpoints[checkpoints.length - 1].fromBlock != block.number
        ) {
            // If yes, push a new checkpoint into the array
            checkpoints.push(
                TellorStorage.Checkpoint({
                    fromBlock: uint128(block.number),
                    value: _value
                })
            );
        } else {
            // Else, update old checkpoint
            TellorStorage.Checkpoint storage oldCheckPoint = checkpoints[
                checkpoints.length - 1
            ];
            oldCheckPoint.value = _value;
        }
    }
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
  @title TellorStorage
  @dev Contains all the variables/structs used by Tellor
*/
contract TellorStorage {
    //Internal struct for use in proof-of-work submission
    struct Details {
        uint256 value;
        address miner;
    }
    struct Dispute {
        bytes32 hash; //unique hash of dispute: keccak256(_miner,_requestId,_timestamp)
        int256 tally; //current tally of votes for - against measure
        bool executed; //is the dispute settled
        bool disputeVotePassed; //did the vote pass?
        bool isPropFork; //true for fork proposal NEW
        address reportedMiner; //miner who submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty; //miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        address proposedForkAddress; //new fork address (if fork proposal)
        mapping(bytes32 => uint256) disputeUintVars;
        mapping(address => bool) voted; //mapping of address to whether or not they voted
    }
    struct StakeInfo {
        uint256 currentStatus; //0-not Staked, 1=Staked, 2=LockedForWithdraw 3= OnDispute 4=ReadyForUnlocking 5=Unlocked
        uint256 startDate; //stake start date
    }
    //Internal struct to allow balances to be queried by blocknumber for voting purposes
    struct Checkpoint {
        uint128 fromBlock; // fromBlock is the block number that the value was generated from
        uint128 value; // value is the amount of tokens at a specific block number
    }
    struct Request {
        uint256[] requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint256) apiUintVars;
        mapping(uint256 => uint256) minedBlockNum; //[apiId][minedTimestamp]=>block.number
        //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }
    uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
    uint256[] public newValueTimestamps; //array of all timestamps requested
    //This is a boolean that tells you if a given challenge has been completed by a given miner
    mapping(uint256 => uint256) requestIdByTimestamp; //minedTimestamp to apiId
    mapping(uint256 => uint256) requestIdByRequestQIndex; //link from payoutPoolIndex (position in payout pool array) to apiId
    mapping(uint256 => Dispute) public disputesById; //disputeId=> Dispute details
    mapping(bytes32 => uint256) public requestIdByQueryHash; // api bytes32 gets an id = to count of requests array
    mapping(bytes32 => uint256) public disputeIdByDisputeHash; //maps a hash to an ID for each dispute
    mapping(bytes32 => mapping(address => bool)) public minersByChallenge;
    Details[5] public currentMiners; //This struct is for organizing the five mined values to find the median
    mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info
    mapping(uint256 => Request) requestDetails;
    mapping(bytes32 => uint256) public uints;
    mapping(bytes32 => address) public addresses;
    mapping(bytes32 => bytes32) public bytesVars;
    //ERC20 storage
    mapping(address => Checkpoint[]) public balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    //Migration storage
    mapping(address => bool) public migrated;
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
    address TELLOR_ADDRESS;
        // 0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0; // Address of main Tellor Contract
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IOracle{
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(address);
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function reportingLock() external view returns(uint256);
    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;
    function verify() external pure returns(uint);
    function changeReportingLock(uint256 _newReportingLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
}