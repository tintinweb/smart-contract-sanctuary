// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./interfaces/IPlennyERC20.sol";
import "./PlennyCoordinator.sol";
import "./storage/PlennyCoordinatorStorage.sol";
import "./PlennyDao.sol";
import "./PlennyTreasury.sol";
import "./PlennyLiqMining.sol";
import "./PlennyOracleValidator.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./PlennyBasePausableV2.sol";
import "./storage/PlennyDappFactoryStorage.sol";
import "./PlennyValidatorElection.sol";

/// @title  PlennyDappFactory
/// @notice Contract for storing information about the Lightning Oracles and Delegators.
contract PlennyDappFactory is PlennyBasePausableV2, PlennyDappFactoryStorage {

    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address payable;
    using BytesLib for bytes;
    using SafeERC20Upgradeable for IPlennyERC20;

    /// An event emitted when logging function calls.
    event LogCall(bytes4  indexed sig, address indexed caller, bytes data) anonymous;
    /// An event emitted when a validator is added.
    event ValidatorAdded(address account, bool created);

    /// @dev    Logs the method calls.
    modifier _logs_() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    /// @notice Initializes the smart contract instead of constructor.
    /// @dev    Called only once.
    /// @param  _registry Plenny contract registry
    function initialize(address _registry) external initializer {

        maxCapacity = 130000;
        minCapacity = 50000;

        // 100 PL2
        makersFixedRewardAmount = uint256(50).mul((10 ** uint256(18)));
        capacityFixedRewardAmount = uint256(25).mul((10 ** uint256(18)));

        // 0.00002%
        makersRewardPercentage = 2;
        // 0.00001%
        capacityRewardPercentage = 1;

        defaultLockingAmount = uint256(10000).mul((10 ** uint256(18)));

        // 0.05%
        userChannelReward = uint256(5);
        // 1 day(s) in blocks
        userChannelRewardPeriod = 6646;
        // 1.5%
        userChannelRewardFee = 150;

        // 1x
        stakedMultiplier = 100;

        // 0.8x
        delegatedMultiplier = 80;

        // 1x
        reputationMultiplier = 100;

        PlennyBasePausableV2.__plennyBasePausableInit(_registry);
    }

    /// @notice Registers a Lightning Oracle. The oracle needs to stake Plenny as a prerequisite for the registration.
    ///         The oracle needs to have a verified Lightning node registered in the PlennyCoordinator.
    /// @param  _name Name of the oracle
    /// @param  nodeIndex index/id of the Lightning as registered in the PlennyCoordinator.
    /// @param  nodeIP ip address of the verified Lightning node.
    /// @param  nodePort port of the verified Lightning node.
    /// @param  serviceUrl url(host:port) used for running the Plenny Oracle Service.
    /// @param  _revenueShare revenue share percentage
    function addValidator(string memory _name, uint256 nodeIndex, string memory nodeIP,
        string memory nodePort, string memory serviceUrl, uint256 _revenueShare) external whenNotPaused _logs_ {
        require(myDelegatedOracle[msg.sender].delegationIndex == 0, "ERR_DELEGATOR");
        require(contractRegistry.stakingContract().plennyBalance(msg.sender) >= defaultLockingAmount, "ERR_NO_FUNDS");
        require(_revenueShare <= 100, "ERR_MAX_AMOUNT");

        (,,,, uint256 status,, address to) = contractRegistry.coordinatorContract().nodes(nodeIndex);
        require(to == msg.sender, "ERR_NOT_OWNER");
        require(status == 1, "ERR_NOT_VERIFIED");

        uint256 index = validatorIndexPerAddress[msg.sender];

        if (index >= validators.length || validatorAddressPerIndex[index] != msg.sender) {
            validators.push(ValidatorInfo(_name, nodeIndex, nodeIP, nodePort, serviceUrl, _revenueShare, msg.sender, 0));
            validatorIndexPerAddress[msg.sender] = validators.length - 1;
            validatorAddressPerIndex[validators.length - 1] = msg.sender;
            validatorsScore.push(0);
            _setValidatorScore(validatorsScore.length - 1);
        } else {
            ValidatorInfo storage validatorInfo = validators[index];
            validatorInfo.name = _name;
            validatorInfo.nodeIndex = nodeIndex;
            validatorInfo.nodeIP = nodeIP;
            validatorInfo.nodePort = nodePort;
            validatorInfo.validatorServiceUrl = serviceUrl;
            validatorInfo.revenueShareGlobal = _revenueShare;
        }
        emit ValidatorAdded(msg.sender, index == 0);
    }

    /// @notice Used for registering the initial(ZERO) oracle. Managed by the contract owner.
    /// @param  publicKey The public key of the Lightning node.
    /// @param  name Name of the oracle
    /// @param  nodeIP ip address of the initial Lightning node.
    /// @param  nodePort port of the initial Lightning node.
    /// @param  serviceUrl url(host:port) used for running the Plenny Oracle Service.
    /// @param  revenueShare revenue share percentage
    /// @param  account address of the initial lightning oracle.
    function createDefaultValidator(string calldata publicKey, string calldata name, string calldata nodeIP,
        string calldata nodePort, string calldata serviceUrl, uint256 revenueShare, address payable account) external onlyOwner _logs_ {

        uint256 nodeIndex = contractRegistry.coordinatorContract().verifyDefaultNode(publicKey, account);

        validators.push(ValidatorInfo(name, nodeIndex, nodeIP, nodePort, serviceUrl, revenueShare, account, 0));
        validatorIndexPerAddress[account] = validators.length - 1;
        validatorAddressPerIndex[validators.length - 1] = account;
        validatorsScore.push(0);
        _setValidatorScore(validatorsScore.length - 1);
    }

    /// @notice Unregisters a Lightning Oracle. In case the oracle is an active validator in the current validation cycle,
    ///         it will fail in removing it.
    function removeValidator() external whenNotPaused _logs_ {
        uint256 index = validatorIndexPerAddress[msg.sender];
        require(validatorAddressPerIndex[index] == msg.sender, "ERR_NOT_ORACLE");
        require(!contractRegistry.validatorElectionContract().validators(
            contractRegistry.validatorElectionContract().latestElectionBlock(), msg.sender),
            "ERR_ACTIVE_VALIDATOR");

        address[] memory delegations = getDelegators(msg.sender);
        for (uint256 i = 0; i < delegations.length; i++) {
            _undelegate(msg.sender, delegations[i]);
        }

        if (validatorsScoreSum >= validatorsScore[index]) {
            validatorsScoreSum -= validatorsScore[index];
        } else {
            validatorsScoreSum = 0;
        }

        uint256 lastIndex = validators.length - 1;
        address lastAddress = validatorAddressPerIndex[lastIndex];

        if (lastIndex == index && lastAddress == msg.sender) {
            delete validatorAddressPerIndex[index];
            delete validatorIndexPerAddress[lastAddress];
        } else {
            validatorAddressPerIndex[index] = lastAddress;
            validatorsScore[index] = validatorsScore[lastIndex];
            validators[index] = validators[lastIndex];

            validatorIndexPerAddress[lastAddress] = index;
            validatorIndexPerAddress[msg.sender] = 0;
        }

        validators.pop();
        validatorsScore.pop();

    }

    /// @notice Delegates Plenny to the given oracle.
    /// @param  newOracle address of the oracle to delegate to
    function delegateTo(address payable newOracle) external whenNotPaused _logs_ {
        require(myDelegatedOracle[msg.sender].oracle != newOracle, "ERR_ALREADY_DELEGATION");
        require(msg.sender != newOracle, "ERR_LOOP_DELEGATION");
        require(!isOracleValidator(msg.sender), "ERR_IS_ORACLE");
        // if I have delegators --> no go
        require(delegationCount[msg.sender].numDelegators < 1, "ERR_CANNOT_HAVE_DELEGATORS");

        // the oracle needs to be a validator --> no go
        require(isOracleValidator(newOracle), "ERR_NOT_VALIDATOR");

        updateDelegators(myDelegatedOracle[msg.sender].oracle, newOracle, msg.sender);
        myDelegatedOracle[msg.sender] = MyDelegationInfo(delegationCount[newOracle].numDelegators, newOracle);
        delegatorsCount++;
    }

    /// @notice Removes a delegation.
    function undelegate() external whenNotPaused _logs_ {
        require(myDelegatedOracle[msg.sender].delegationIndex > 0, "ERR_NOT_DELEGATING");
        removeDelegator(myDelegatedOracle[msg.sender].oracle, msg.sender);
        delete myDelegatedOracle[msg.sender];
        delegatorsCount--;
    }

    /// @notice Called whenever a delegator user stakes more Plenny.
    /// @dev    Called by the PlennyStaking contract.
    /// @param  user address
    /// @param  amount Plenny amount that was staked
    function increaseDelegatedBalance(address user, uint256 amount) external override {
        require(msg.sender == contractRegistry.requireAndGetAddress("PlennyStaking"), "ERR_NOT_AUTH");

        if (isOracleValidator(user)) {
            _setValidatorScore(validatorIndexPerAddress[user]);
        }

        // if the user is a delegator increase its delegated balance
        if (myDelegatedOracle[user].delegationIndex > 0) {
            delegators[myDelegatedOracle[user].oracle][myDelegatedOracle[user].delegationIndex].delegatedAmount += amount;
            delegationCount[myDelegatedOracle[user].oracle].totalDelegatedAmount += amount;
            _setValidatorScore(validatorIndexPerAddress[myDelegatedOracle[user].oracle]);
        }
    }

    /// @notice Called whenever a delegator user unstakes Plenny.
    /// @dev    Only called by the PlennyStaking contract.
    /// @param  user address
    /// @param  amount Plenny amount that was unstaked
    function decreaseDelegatedBalance(address user, uint256 amount) external override {
        require(msg.sender == contractRegistry.requireAndGetAddress("PlennyStaking"), "ERR_NOT_AUTH");

        if (isOracleValidator(user)) {
            _setValidatorScore(validatorIndexPerAddress[user]);
        }

        // if the user is a delegator decrease its delegated balance
        if (myDelegatedOracle[user].delegationIndex > 0) {
            delegators[myDelegatedOracle[user].oracle][myDelegatedOracle[user].delegationIndex].delegatedAmount -= amount;
            delegationCount[myDelegatedOracle[user].oracle].totalDelegatedAmount -= amount;
            _setValidatorScore(validatorIndexPerAddress[myDelegatedOracle[user].oracle]);
        }
    }

    /// @notice Called whenever an oracle has participated in a validation cycle just before a new validator election
    ///         is triggered. It will update the oracle reputation of that validation cycle.
    /// @dev    Only called by the PlennyValidatorElection contract.
    /// @param  validator oracle address
    /// @param  reward the validator reward to update reputation for
    function updateReputation(address validator, uint256 reward) external override {
        require(msg.sender == contractRegistry.requireAndGetAddress("PlennyValidatorElection"), "ERR_NOT_AUTH");

        uint256 index = validatorIndexPerAddress[validator];
        require(validatorAddressPerIndex[index] == validator, "ERR_VALIDATOR_NOT_FOUND");

        validators[index].reputation += reward;

        _setValidatorScore(index);
    }

    /// @notice Changes the default Locking Amount. Managed by the contract owner.
    /// @param  amount Plenny amount
    function setDefaultLockingAmount(uint256 amount) external onlyOwner {
        defaultLockingAmount = amount;
    }

    /// @notice Changes the user Channel Reward. Managed by the contract owner.
    /// @param  amount percentage multiplied by 100
    function setUserChannelReward(uint256 amount) external onlyOwner {
        userChannelReward = amount;
    }

    /// @notice Changes the user Channel Reward Period. Managed by the contract owner.
    /// @param  amount period, in blocks
    function setUserChannelRewardPeriod(uint256 amount) external onlyOwner {
        userChannelRewardPeriod = amount;
    }

    /// @notice Changes the user Channel Reward Fee. Managed by the contract owner.
    /// @param  amount percentage multiplied by 100
    function setUserChannelRewardFee(uint256 amount) external onlyOwner {
        userChannelRewardFee = amount;
    }

    /// @notice Changes the staked Multiplier. Managed by the contract owner.
    /// @param  amount multiplied by 100
    function setStakedMultiplier(uint256 amount) external onlyOwner {
        stakedMultiplier = amount;
    }

    /// @notice Changes the delegated Multiplier. Managed by the contract owner.
    /// @param  amount multiplied by 100
    function setDelegatedMultiplier(uint256 amount) external onlyOwner {
        delegatedMultiplier = amount;
    }

    /// @notice Changes the reputation Multiplier. Managed by the contract owner.
    /// @param  amount multiplied by 100
    function setReputationMultiplier(uint256 amount) external onlyOwner {
        reputationMultiplier = amount;
    }

    /// @notice Changes the  minimum channel capacity amount. Managed by the contract owner.
    /// @param  value channel capacity, in satoshi
    function setMinCapacity(uint256 value) external onlyOwner {
        require(value < maxCapacity, "ERR_VALUE_TOO_HIGH");
        minCapacity = value;
    }

    /// @notice Changes the maximum channel capacity amount. Managed by the contract owner.
    /// @param  value channel capacity, in satoshi
    function setMaxCapacity(uint256 value) external onlyOwner {
        require(value > minCapacity, "ERR_VALUE_TOO_LOW");
        maxCapacity = value;
    }

    /// @notice Changes the makers Fixed Reward Amount. Managed by the contract owner.
    /// @param  value plenny reward amount, in wei
    function setMakersFixedRewardAmount(uint256 value) external onlyOwner {
        makersFixedRewardAmount = value;
    }

    /// @notice Changes the capacity Fixed Reward Amount. Managed by the contract owner.
    /// @param  value plenny reward, in wei
    function setCapacityFixedRewardAmount(uint256 value) external onlyOwner {
        capacityFixedRewardAmount = value;
    }

    /// @notice Changes the makers Reward Percentage. Managed by the contract owner.
    /// @param  value multiplied by 100
    function setMakersRewardPercentage(uint256 value) external onlyOwner {
        makersRewardPercentage = value;
    }

    /// @notice Changes the capacity Reward Percentage. Managed by the contract owner.
    /// @param  value multiplied by 100
    function setCapacityRewardPercentage(uint256 value) external onlyOwner {
        capacityRewardPercentage = value;
    }

    /// @notice Gets info for the given oracle.
    /// @param  validator oracle address
    /// @return name name
    /// @return nodeIndex index/id of the Lightning as registered in the PlennyCoordinator.
    /// @return nodeIP ip address of the verified Lightning node.
    /// @return nodePort port of the verified Lightning node.
    /// @return validatorServiceUrl url(host:port) used for running the Plenny Oracle Service.
    /// @return revenueShareGlobal revenue share percentage
    /// @return owner address of the validator
    /// @return reputation score/reputation
    function getValidatorInfo(address validator) external view returns (string memory name, uint256 nodeIndex,
        string memory nodeIP, string memory nodePort, string memory validatorServiceUrl, uint256 revenueShareGlobal,
        address owner, uint256 reputation){

        uint256 index = validatorIndexPerAddress[validator];
        if (index >= validators.length || validatorAddressPerIndex[index] != validator) {
            return ("ERR", 0, "ERR", "ERR", "ERR", 0, address(0), 0);
        } else {
            ValidatorInfo memory info = validators[index];
            return (info.name, info.nodeIndex, info.nodeIP, info.nodePort, info.validatorServiceUrl,
            info.revenueShareGlobal, info.owner, info.reputation);
        }
    }

    /// @notice Lists all delegator addresses for the given user.
    /// @return address[] array of addresses
    function getMyDelegators() external view returns (address[] memory){
        return getDelegators(msg.sender);
    }

    /// @notice Number of oracles.
    /// @return uint256 counter
    function validatorsCount() external view returns (uint256) {
        return validators.length;
    }

    /// @notice Calculates random numbers for a channel capacity used for verifying nodes in the PlennyCoordinator.
    /// @return uint256 random number
    function random() external view override returns (uint256) {
        uint256 ceiling = maxCapacity - minCapacity;
        uint256 randomNumber = uint256(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty))) % ceiling);
        randomNumber = randomNumber + minCapacity;
        return randomNumber;
    }

    /// @notice Calculates random numbers based on the block info.
    /// @return uint256 random number
    function pureRandom() external view override returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty)));
    }

    /// @notice Gets all the validator scores and the sum of all scores.
    /// @return scores arrays of validator scores
    /// @return sum score sum
    function getValidatorsScore() external view override returns (uint256[] memory scores, uint256 sum) {
        return (validatorsScore, validatorsScoreSum);
    }

    /// @notice Gets all delegators for the given oracle.
    /// @param  oracle address
    /// @return address[] array of delegator addresses
    function getDelegators(address oracle) public view override returns (address[] memory){

        uint256 delegations = delegationCount[oracle].numDelegators;
        address[] memory result = new address[](delegations);
        uint256 counter = 0;

        for (uint256 i = 1; i <= delegations; i++) {
            result[counter] = delegators[oracle][i].delegator;
            counter++;
        }

        return result;
    }

    /// @notice Gets the Plenny balance from all the delegators of the given address.
    /// @param  user address to check
    /// @return uint256 delegated balance
    function getDelegatedBalance(address user) public view override returns (uint256) {
        return delegationCount[user].totalDelegatedAmount;
    }

    /// @notice Checks if the address is an oracle.
    /// @param  oracle address to check
    /// @return bool true/false
    function isOracleValidator(address oracle) public view override returns (bool) {
        return validatorAddressPerIndex[validatorIndexPerAddress[oracle]] == oracle;
    }

    /// @notice Update the delegation for the given delegator from old to a new oracle.
    /// @param  oldOracle address of the old delegator to
    /// @param  newOracle address of the new delegator to
    /// @param  delegator address to update the delegation for
    function updateDelegators(address oldOracle, address newOracle, address delegator) internal {
        removeDelegator(oldOracle, delegator);

        uint256 delegatedAmount = contractRegistry.stakingContract().plennyBalance(delegator);

        delegationCount[newOracle].numDelegators++;
        delegationCount[newOracle].totalDelegatedAmount += delegatedAmount;

        delegators[newOracle][delegationCount[newOracle].numDelegators] = DelegatorInfo(delegatedAmount, delegator);
        _setValidatorScore(validatorIndexPerAddress[newOracle]);
    }

    /// @notice Remove the delegation for the given delegator
    /// @param  oracle delegation to remove
    /// @param  delegator the delegator to remove the delegation for
    function removeDelegator(address oracle, address delegator) internal {

        delegationCount[oracle].totalDelegatedAmount -= delegators[oracle][myDelegatedOracle[delegator].delegationIndex].delegatedAmount;

        if (myDelegatedOracle[delegator].delegationIndex != delegationCount[oracle].numDelegators) {
            myDelegatedOracle[delegators[oracle][delegationCount[oracle].numDelegators].delegator].delegationIndex = myDelegatedOracle[delegator].delegationIndex;
            delegators[oracle][myDelegatedOracle[delegator].delegationIndex] = delegators[oracle][delegationCount[oracle].numDelegators];
            delete delegators[oracle][delegationCount[oracle].numDelegators];
        }
        else {
            delete delegators[oracle][myDelegatedOracle[delegator].delegationIndex];
        }
        delegationCount[oracle].numDelegators--;
        _setValidatorScore(validatorIndexPerAddress[oracle]);
    }

    /// @notice Calculates the validator score for the given validator
    /// @param  index id of the validator
    function _setValidatorScore(uint256 index) internal {

        uint256 oldValue = validatorsScore[index];

        address oracle = validators[index].owner;
        uint256 _reputation = validators[index].reputation;

        uint256 stakedBalance = contractRegistry.stakingContract().plennyBalance(oracle);
        uint256 delegatedBalance = getDelegatedBalance(oracle);

        uint256 staked = stakedBalance.mul(stakedMultiplier).div(100);
        uint256 delegated = delegatedBalance.mul(delegatedMultiplier).div(100);
        uint256 reputation = _reputation.mul(reputationMultiplier).div(100);

        uint256 newValue = staked.add(delegated).add(reputation);
        validatorsScore[index] = newValue;

        if (newValue >= oldValue) {
            validatorsScoreSum = validatorsScoreSum.add(newValue - oldValue);
        } else {
            validatorsScoreSum = validatorsScoreSum.sub(oldValue - newValue);
        }
    }

    /// @notice Perform undelegate operation for the given delegator
    /// @param  oracle delegation to remove
    /// @param  delegator the delegator to remove the delegation for
    function _undelegate(address oracle, address delegator) private {
        removeDelegator(oracle, delegator);
        delete myDelegatedOracle[delegator];
        delegatorsCount--;
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.7.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPlennyValidatorElection.sol";

/// @title  PlennyValidatorElectionStorage
/// @notice Storage contact for PlennyValidatorElection
abstract contract PlennyValidatorElectionStorage is IPlennyValidatorElection {

    /// @notice election period, in blocks
    uint256 public newElectionPeriod;
    /// @notice maximum number of validators elected in a validation cycle
    uint256 public maxValidators;
    /// @notice percentage of the accumulated validation reward that will go to the user that has triggered the election.
    uint256 public userRewardPercent;

    /// @notice block of the latest election
    uint256 public override latestElectionBlock;
    /// @notice elected validators per election. An election is identified by the block number when it was triggered.
    mapping(uint256 => address[]) public electedValidators;
    /// @notice election info
    mapping(uint256 => mapping(address => Election)) public elections;
    /// @notice active elections
    mapping(uint256 => Election[]) public activeElection;
    /// @notice check if oracle is elected validator
    mapping(uint256 => mapping(address => bool)) public override validators;

    /// @notice Reward to be transferred to the user triggering the election
    mapping (uint256 => uint256) public pendingUserReward;
    /// @notice Total pending reward per cycle
    mapping (uint256 => uint256) public pendingElectionReward;
    /// @notice Reward to be transferred to oracle validators
    mapping (uint256 => mapping(address => uint256)) public pendingElectionRewardPerValidator;

    struct Election {
        uint256 created;
        uint256 revenueShare;
        uint256 stakedBalance;
        uint256 delegatedBalance;
        address[] delegators;
        uint256[] delegatorsBalance;
    }

    struct ValidatorIndex {
        uint256 index;
        bool exists;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPlennyTreasury.sol";

/* solhint-disable-next-line no-empty-blocks */
/// @title  PlennyTreasuryStorage
/// @notice Storage contract for PlennyTreasury
abstract contract PlennyTreasuryStorage is IPlennyTreasury {

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPlennyOracleValidator.sol";

/// @title  PlennyOracleValidatorStorage
/// @notice Storage contract for the PlennyOracleValidator
contract PlennyOracleValidatorStorage is IPlennyOracleValidator {

    /// @notice quorum
    uint public minQuorumDivisor;
    /// @notice total reward for the oracle validations
    uint256 public totalOracleReward;
    /// @notice fixed amount reward given to the oracle validation when validating
    uint256 public oracleFixedRewardAmount;
    /// @notice percentage amount reward (from PlennyTreasury) given to the oracle validation when validating
    uint256 public oracleRewardPercentage;
    /// @dev percentage of the reward that goes for the validator (i.e leader) that has posted the data on-chain.
    uint256 internal leaderRewardPercent;

    /// @notice all oracle validations
    mapping(uint256 => mapping(address => uint256)) public override oracleValidations;

    /// @notice validations for opened channel
    mapping(uint256 => mapping(address => bool)) public oracleOpenChannelAnswers;
    /// @dev the oracle validators that have reached consensus on a opened channel
    mapping(uint256 => address []) internal oracleOpenChannelConsensus;
    /// @dev the data for the opened channel as agreed by the oracle validators
    mapping(uint256 => bytes32) internal latestOpenChannelAnswer;

    /// @notice validations for closed channel
    mapping(uint256 => mapping(address => bool)) public oracleCloseChannelAnswers;
    /// @dev the oracle validators that have reached consensus on a closed channel
    mapping(uint256 => address []) internal oracleCloseChannelConsensus;
    /// @dev the data for the closed channel as agreed by the oracle validators
    mapping(uint256 => bytes32) internal latestCloseChannelAnswer;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPlennyLiqMining.sol";

/// @title  PlennyLiqMiningStorage
/// @notice Storage contract for the PlennyLiqMining
contract PlennyLiqMiningStorage is IPlennyLiqMining {

    /// @notice weight multiplier, for scaling up
    uint256 public constant WEIGHT_MULTIPLIER = 100;

    /// @notice mining reward
    uint256 public totalMiningReward;
    /// @notice total plenny amount locked
    uint256 public totalValueLocked;
    /// @notice total weight locked
    uint256 public override totalWeightLocked;
    /// @notice total weight already collected
    uint256 public totalWeightCollected;
    /// @notice distribution period, in blocks
    uint256 public nextDistributionSeconds; // 1 day
    /// @notice blocks per week
    uint256 public averageBlockCountPerWeek; // 1 week
    /// @notice maximum locking period, in blocks
    uint256 public maxPeriodWeek; // 10 years

    /// @notice  Withdrawal fee in % * 100
    uint256 public liquidityMiningFee;
    /// @notice exit fee, charged when the user withdraws its locked LPs
    uint256 public fishingFee;

    /// @notice mining reward percentage
    uint256 public liqMiningReward;

    /// @notice arrays of locked records
    LockedBalance[] public lockedBalance;
    /// @notice maps records to address
    mapping (address => uint256[]) public lockedIndexesPerAddress;
    /// @notice locked balance per address
    mapping(address => uint256) public totalUserLocked;
    /// @notice weight per address
    mapping(address => uint256) public totalUserWeight;
    /// @notice earner tokens per address
    mapping(address => uint256) public totalUserEarned;
    /// @notice locked period per address
    mapping(address => uint256) public userLockedPeriod;
    /// @notice collection period per address
    mapping(address => uint256) public userLastCollectedPeriod;

    struct LockedBalance {
        address owner;
        uint256 amount;
        uint256 addedDate;
        uint256 endDate;
        uint256 weight;
        bool deleted;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPlennyDappFactory.sol";

// solhint-disable max-states-count
/// @title  PlennyDappFactoryStorage
/// @notice Storage contract for the PlennyDappFactory
abstract contract PlennyDappFactoryStorage is IPlennyDappFactory {

    /// @notice default Plenny amount the oracles needs to stake
    uint256 public override defaultLockingAmount;

    /// @notice percentage to distribute the channel reward to the user for the given reward period.
    uint256 public override userChannelReward;
    /// @notice period(in blocks) for distribute the channel reward to the user
    uint256 public override userChannelRewardPeriod;
    /// @notice fee charged whenever user collects the channel reward
    uint256 public override userChannelRewardFee;

    /// @notice Maximum channel capacity for opening channels during lightning node verification process.
    uint256 public maxCapacity;
    /// @notice Minimum channel capacity for opening channels during lightning node verification process.
    uint256 public minCapacity;

    /// @notice Fixed reward that is given to the makers in the ocean/marketplace for opening channel to the takers.
    uint256 public override makersFixedRewardAmount;
    /// @notice Fixed amount for giving reward for providing channel capacity
    uint256 public override capacityFixedRewardAmount;

    /// @notice Percentage of the treasury HODL that the maker gets when providing channel capacity via the ocean/marketplace
    uint256 public override makersRewardPercentage;
    /// @notice Percentage of the treasury HODL that the users gets when providing outbound channel capacity
    uint256 public override capacityRewardPercentage;

    /// @notice number of total delegations
    uint256 public delegatorsCount;

    /// @notice number of delegations per oracle
    mapping (address => OracleDelegation) public delegationCount;

    /// @notice arrays of all oracle validators
    ValidatorInfo[] public override validators;
    /// @dev delegator info per oracle
    mapping(address => mapping (uint256 => DelegatorInfo)) internal delegators;
    /// @notice validatorindex per address
    mapping(address => uint256)public override validatorIndexPerAddress;
    /// @notice validator address per index
    mapping(uint256 => address)public validatorAddressPerIndex;
    /// @notice delegation info for the given delegator address
    mapping(address => MyDelegationInfo)public myDelegatedOracle;

    /// @notice arrays of validator scores
    uint256[] public validatorsScore;
    /// @notice sum of all scores
    uint256 public validatorsScoreSum;

    struct ValidatorInfo {
        string name;
        uint256 nodeIndex;
        string nodeIP;
        string nodePort;
        string validatorServiceUrl;
        uint256 revenueShareGlobal;
        address owner;
        uint256 reputation;
    }

    struct OracleDelegation {
        uint256 numDelegators;
        uint256 totalDelegatedAmount;
    }

    struct DelegatorInfo {
        uint256 delegatedAmount;
        address delegator;
    }

    struct MyDelegationInfo {
        uint256 delegationIndex;
        address oracle;
    }

    /// @dev Multiplier for staked balance into the validator score.
    uint256 internal stakedMultiplier;
    /// @dev Multiplier for delegated balance into the validator score.
    uint256 internal delegatedMultiplier;
    /// @dev Multiplier for reputation into the validator score.
    uint256 internal reputationMultiplier;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../PlennyDappFactory.sol";

contract PlennyDaoStorage {

    /// The name of this contract
    string public constant NAME = "PlennyDao";

    // The initial delay when creating a proposal, in blocks
    uint public votingDelay;
    // The duration of voting on a proposal, in blocks
    uint public votingDuration;
    // The quorum vote % needed for each proposal  / BASE
    uint public minQuorum;
    // The % of votes required in order for a voter to become a proposer / BASE
    uint public proposalThreshold;

    /// The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 _proposalID,bool support)");

    mapping (bytes32 => bool) public queuedTransactions;

    uint public constant GRACE_PERIOD = 93046;   // blocks count, 14 days approximately
    uint public constant MINIMUM_DELAY = 10;     // blocks count, 2 minutes approximately
    uint public constant MAXIMUM_DELAY = 199384; // blocks count, 30 days approximately
    uint64 public delay;

    address public guardian;

    uint public constant BASE = 10000;

    uint public proposalCount;
    struct Proposal {
        uint id;
        address proposer;
        uint eta;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint startBlock;
        uint startBlockAlt;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
        mapping (address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint votes;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    mapping (uint => Proposal) public proposals;
    mapping (address => uint) public latestProposalIds;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPlennyCoordinator.sol";

/// @title  PlennyCoordinatorStorage
/// @notice Storage contract for the PlennyCoordinator
abstract contract PlennyCoordinatorStorage is IPlennyCoordinator {

    /// @notice total rewards
    uint256 public totalTimeReward;
    /// @notice number of channels
    uint256 public channelsCount;
    /// @notice number of nodes
    uint256 public nodesCount;
    /// @notice channel threshold, in satoshi
    uint256 public override channelRewardThreshold;
    /// @notice total outbound channel capacity, in satoshi
    uint256 public totalOutboundCapacity;
    /// @notice total inbound channel capacity, in satoshi
    uint256 public totalInboundCapacity;

    /// @notice maps index/id with a channel info
    mapping(uint256 => LightningChannel) public channels;
    /// @notice maps index/id with a node info
    mapping(uint256 => LightningNode) public override nodes;

    /// @dev maps the index for a channel point and the user
    mapping(string => mapping(address => uint256)) internal channelIndexPerId;
    /// @dev confirmed channel points per user
    mapping(string => uint256) internal confirmedChannelIndexPerId;
    /// @notice counter per channel status
    mapping(uint => uint256) public channelStatusCount;
    /// @notice tracks when the reward starts for a given channel
    mapping(uint256 => uint256) public override channelRewardStart;

    /// @dev maps node public key per user and index/id
    mapping(string => mapping(address => uint256)) internal nodeIndexPerPubKey;
    /// @dev node counter per user
    mapping(address => uint256) internal nodeOwnerCount;

    /// @notice nodes per user
    mapping(address => uint256[]) public nodesPerAddress;
    /// @notice channels per user
    mapping(address => uint256[]) public channelsPerAddress;

    struct LightningNode {
        uint256 capacity;
        uint256 addedDate;
        string publicKey;
        address validatorAddress;

        uint256 status;

        uint256 verifiedDate;
        address payable to;
    }

    struct LightningChannel {
        uint256 capacity;
        uint256 appliedDate;
        uint256 confirmedDate;

        uint256 status;

        uint256 closureDate;
        address payable to;
        address payable oracleAddress;
        uint256 rewardAmount;

        uint256 id;
        string channelPoint;
        uint256 blockNumber;
        uint256 blockNumberAlt;
    }

    struct NodeInfo {
        uint256 nodeIndex;
        string ownerPublicKey;
        string validatorPublicKey;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./ExtendedMathLib.sol";

/// @title  RewardLib
/// @notice Library for calculating the reward

library RewardLib {

	using SafeMathUpgradeable for uint256;

	/// @notice Calculate reward for channel capacity
	/// @param  capacity channel capacity
	/// @param  marketplace if reward from marketplace
	/// @param  penaltyValue minimum channel capacity for which a reward is given
	/// @param  makersFixedRewardAmount maker's fixed reward
	/// @param  makersRewardPercentage maker's percentage reward
	/// @param  capacityFixedRewardAmount capacity fixed reward
	/// @param  capacityRewardPercentage capacity percentage reward
	/// @param  treasuryBalance balance of the PlennyTreasury
	/// @return multiplier reward multiplier
	function calculateReward(
		uint256 capacity,
		bool marketplace,
		uint256 penaltyValue,
		uint256 makersFixedRewardAmount,
		uint256 makersRewardPercentage,
		uint256 capacityFixedRewardAmount,
		uint256 capacityRewardPercentage,
		uint256 treasuryBalance
	) internal pure returns (uint multiplier){
		uint256 rewardAmount;

		if (marketplace) {
			if (makersFixedRewardAmount < makersRewardPercentage.mul(treasuryBalance).div(100).div(100000)) {
				rewardAmount = makersFixedRewardAmount;
			} else {
				rewardAmount = makersRewardPercentage.mul(treasuryBalance).div(100).div(100000);
			}
		} else {
			if (capacityFixedRewardAmount < capacityRewardPercentage.mul(treasuryBalance).div(100).div(100000)) {
				rewardAmount = capacityFixedRewardAmount;
			} else {
				rewardAmount = capacityRewardPercentage.mul(treasuryBalance).div(100).div(100000);
			}
		}
		if (capacity >= penaltyValue) {

			uint256 cS = capacity.sub(penaltyValue.sub(uint256(1)));
			uint256 cMax = uint256(15500000);
			uint256 sqrtCS = ExtendedMathLib.sqrt(cS);
			uint256 sqrtCMax = ExtendedMathLib.sqrt(cMax);

			return rewardAmount.mul(cS).mul(sqrtCS).div(cMax).div(sqrtCMax);
		} else {
			return 0;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";


/// @title  ExtendedMathLib
/// @notice Library for calculating the square root

library ExtendedMathLib {

	using SafeMathUpgradeable for uint256;

	/// @notice Calculates root
	/// @param  y number
	/// @return z calculated number
	function sqrt(uint y) internal pure returns (uint z) {
		if (y > 3) {
			z = y;
			uint x = y / 2 + 1;
			while (x < z) {
				z = x;
				x = (y / x + x) / 2;
			}
		} else if (y != 0) {
			z = 1;
		}
		return z;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/* solhint-disable */
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyValidatorElection {

    function validators(uint256 electionBlock, address addr) external view returns (bool);

    function latestElectionBlock() external view returns (uint256);

    function getElectedValidatorsCount(uint256 electionBlock) external view returns (uint256);

    function reserveReward(address validator, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyTreasury {

    function approve(address addr, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyStaking {

    function plennyBalance(address addr) external view returns (uint256);

    function decreasePlennyBalance(address dapp, uint256 amount, address to) external;

    function increasePlennyBalance(address dapp, uint256 amount, address from) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyReward {

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyOracleValidator {

    function oracleValidations(uint256, address) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyOcean {

    function processCapacityRequest(uint256 index) external;

    function closeCapacityRequest(uint256 index, uint256 id, uint256 date) external;

    function collectCapacityRequestReward(uint256 index, uint256 id, uint256 date) external;

    function capacityRequests(uint256 index) external view returns (uint256, uint256, string memory, address payable,
        uint256, uint256, string memory, address payable);

    function capacityRequestPerChannel(string calldata channelPoint) external view returns (uint256 index);

    function makerIndexPerAddress(address addr) external view returns (uint256 index);

    function capacityRequestsCount() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyLocking {

    function totalVotesLocked() external view returns (uint256);

    function govLockReward() external view returns (uint256);

    function getUserVoteCountAtBlock(address account, uint blockNumber) external view returns (uint256);

    function getTotalVoteCountAtBlock(uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyLiqMining {

    function totalWeightLocked() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IBasePlennyERC20.sol";

interface IPlennyERC20 is IBasePlennyERC20 {

    function registerTokenOnL2(address l2CustomTokenAddress, uint256 maxSubmissionCost, uint256 maxGas, uint256 gasPriceBid) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyDappFactory {

    function isOracleValidator(address validatorAddress) external view returns (bool);

    // to be removed from factory
    function random() external view returns (uint256);

    function decreaseDelegatedBalance(address dapp, uint256 amount) external;

    function increaseDelegatedBalance(address dapp, uint256 amount) external;

    function updateReputation(address validator, uint256 electionBlock) external;

    function getValidatorsScore() external view returns (uint256[] memory scores, uint256 sum);

    function getDelegatedBalance(address) external view returns (uint256);

    function getDelegators(address) external view returns (address[] memory);

    function pureRandom() external view returns (uint256);

    function validators(uint256 index) external view returns (string memory name, uint256 nodeIndex, string memory nodeIP,
        string memory nodePort, string memory validatorServiceUrl, uint256 revenueShareGlobal, address owner, uint256 reputation);

    function validatorIndexPerAddress(address addr) external view returns (uint256 index);

    function userChannelRewardPeriod() external view returns (uint256);

    function userChannelReward() external view returns (uint256);

    function userChannelRewardFee() external view returns (uint256);

    function makersFixedRewardAmount() external view returns (uint256);

    function makersRewardPercentage() external view returns (uint256);

    function capacityFixedRewardAmount() external view returns (uint256);

    function capacityRewardPercentage() external view returns (uint256);

    function defaultLockingAmount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPlennyCoordinator {

    function nodes(uint256 index) external view returns (uint256, uint256, string memory, address, uint256, uint256, address payable);

    function openChannel(string memory _channelPoint, address payable _oracleAddress, bool capacityRequest) external;

    function confirmChannelOpening(uint256 channelIndex, uint256 _channelCapacitySat,
        uint256 channelId, string memory node1PublicKey, string memory node2PublicKey) external;

    function verifyDefaultNode(string calldata publicKey, address payable account) external returns (uint256);

    function closeChannel(uint256 channelIndex) external;

    function channelRewardStart(uint256 index) external view returns (uint256);

    function channelRewardThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IWETH.sol";
import "./IPlennyERC20.sol";
import "./IPlennyCoordinator.sol";
import "./IPlennyTreasury.sol";
import "./IPlennyOcean.sol";
import "./IPlennyStaking.sol";
import "./IPlennyValidatorElection.sol";
import "./IPlennyOracleValidator.sol";
import "./IPlennyDappFactory.sol";
import "./IPlennyReward.sol";
import "./IPlennyLiqMining.sol";
import "./IPlennyLocking.sol";
import "../interfaces/IUniswapV2Router02.sol";

interface IContractRegistry {

    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name) external view returns (address);

    function plennyTokenContract() external view returns (IPlennyERC20);

    function factoryContract() external view returns (IPlennyDappFactory);

    function oceanContract() external view returns (IPlennyOcean);

    function lpContract() external view returns (IUniswapV2Pair);

    function uniswapRouterV2() external view returns (IUniswapV2Router02);

    function treasuryContract() external view returns (IPlennyTreasury);

    function stakingContract() external view returns (IPlennyStaking);

    function coordinatorContract() external view returns (IPlennyCoordinator);

    function validatorElectionContract() external view returns (IPlennyValidatorElection);

    function oracleValidatorContract() external view returns (IPlennyOracleValidator);

    function wrappedETHContract() external view returns (IWETH);

    function rewardContract() external view returns (IPlennyReward);

    function liquidityMiningContract() external view returns (IPlennyLiqMining);

    function lockingContract() external view returns (IPlennyLocking);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBasePlennyERC20 is IERC20Upgradeable {

    function initialize(address owner, bytes memory _data) external;

    function mint(address addr, uint256 amount) external;

}

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);

    /**
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
    function withdrawEth(address destination) external payable returns(uint);

    /**
    * @notice Send a transaction to L1
    * @param destination recipient address on L1
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);



    /**
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**
    * @notice get the value of target L2 storage slot
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint amount);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
        uint indexed batchNumber, uint indexInBatch,
        uint arbBlockNum, uint ethBlockNum, uint timestamp,
        uint callvalue, bytes data);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IPlennyERC20.sol";
import "./PlennyBasePausableV2.sol";
import "./storage/PlennyValidatorElectionStorage.sol";


/// @title  PlennyValidatorElection
/// @notice Contains the logic for the election cycle and the process of electing validators based on
///         Delegated Proof of Stake (DPoS), and reserves rewards.
contract PlennyValidatorElection is PlennyBasePausableV2, PlennyValidatorElectionStorage {

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IPlennyERC20;

    /// An event emitted when logging function calls.
    event LogCall(bytes4  indexed sig, address indexed caller, bytes data) anonymous;
    /// An event emitted when the rewards are distributed.
    event OracleReward(address indexed to, uint256 amount);

    /// @notice Initializes the smart contract instead of a constructor. Called once during deploy.
    /// @param  _registry Plenny contract registry
    function initialize(address _registry) external initializer {

        // 1 week in blocks
        newElectionPeriod = 46523;

        maxValidators = 3;

        // 0.5%
        userRewardPercent = 50;

        PlennyBasePausableV2.__plennyBasePausableInit(_registry);
    }

    /// @notice Triggers a new election. Fails if not enough time has passed from the previous election.
    function newElection() external whenNotPaused nonReentrant {
        _logs_();

        if (latestElectionBlock > 0) {
            require(activeElection[latestElectionBlock][0].created + newElectionPeriod <= _blockNumber(), "ERR_LOCKED");
        }

        IPlennyERC20 token = contractRegistry.plennyTokenContract();

        require(contractRegistry.treasuryContract().approve(address(this),
            pendingElectionReward[latestElectionBlock]), "failed");
        token.safeTransferFrom(contractRegistry.requireAndGetAddress("PlennyTreasury"),
                address(this),
                pendingElectionReward[latestElectionBlock]);

        // send reward to the user
        token.safeTransfer(msg.sender, pendingUserReward[latestElectionBlock]);

        address[] memory existingValidators = electedValidators[latestElectionBlock];
        for (uint i = 0; i < existingValidators.length; i++) {
            address oracle = existingValidators[i];

            uint256 myReward = pendingElectionRewardPerValidator[latestElectionBlock][oracle];

            contractRegistry.factoryContract().updateReputation(oracle, myReward);

            if (myReward > 0) {
                uint256 potentialDelegatedReward = myReward.mul(elections[latestElectionBlock][oracle].delegatedBalance)
                .div(elections[latestElectionBlock][oracle].stakedBalance + elections[latestElectionBlock][oracle].delegatedBalance);
                uint256 sharedDelegatedReward = potentialDelegatedReward.mul(elections[latestElectionBlock][oracle].revenueShare).div(100);

                // Send reward to the oracle
                uint256 oracleReward = myReward - sharedDelegatedReward;
                token.safeTransfer(oracle, oracleReward);

                if (sharedDelegatedReward > 0) {
                    for (uint256 k = 0; k < elections[latestElectionBlock][oracle].delegators.length; k++) {
                        uint256 delegatorReward = elections[latestElectionBlock][oracle].delegatedBalance == 0 ? 0 :
                        sharedDelegatedReward.mul(elections[latestElectionBlock][oracle].delegatorsBalance[k])
                        .div(elections[latestElectionBlock][oracle].delegatedBalance);

                        if (delegatorReward > 0) {
                            token.safeTransfer(elections[latestElectionBlock][oracle].delegators[k], delegatorReward);
                            emit OracleReward(elections[latestElectionBlock][oracle].delegators[k], delegatorReward);
                        }
                    }
                }
            }
        }

        // scores holds a list of score for every validator
        (uint256[] memory scores, uint256 scoreSum) = contractRegistry.factoryContract().getValidatorsScore();
        ValidatorIndex [] memory oracles = new ValidatorIndex[](scores.length);

        // New election
        require(scores.length > 0 && scoreSum > 0, "ERR_NO_VALIDATORS");
        uint256 length = scores.length > maxValidators ? maxValidators : scores.length;
        address[] memory newValidators = new address[](length);

        uint256 randomNumber = contractRegistry.factoryContract().pureRandom();
        uint256 oraclesToBeElectedLength = scores.length;

        latestElectionBlock = _blockNumber();
        for (uint i = 0; i < newValidators.length; i++) {
            randomNumber = uint256(keccak256(abi.encode(randomNumber)));
            uint256 randomIndex = _getRandomIndex(scores, scoreSum, randomNumber);
            uint256 validatorIndex = _getValidatorIndex(oracles, randomIndex);

            (,,,,, uint256 revenueShare,address owner,) = contractRegistry.factoryContract().validators(validatorIndex);

            newValidators[i] = owner;
            validators[latestElectionBlock][owner] = true;

            scoreSum -= scores[randomIndex];
            oraclesToBeElectedLength--;
            scores[randomIndex] = scores[oraclesToBeElectedLength];
            if (oracles[oraclesToBeElectedLength].exists) {
                oracles[randomIndex] = oracles[oraclesToBeElectedLength];
            } else {
                oracles[randomIndex] = ValidatorIndex(oraclesToBeElectedLength, true);
            }

            // Creating snapshot
            uint256 stakedBalance = contractRegistry.stakingContract().plennyBalance(newValidators[i]);
            uint256 delegatedBalance = contractRegistry.factoryContract().getDelegatedBalance(newValidators[i]);

            address[] memory delegators = contractRegistry.factoryContract().getDelegators(newValidators[i]);
            uint256[] memory delegatorsBalance = new uint256[](delegators.length);
            for (uint256 j = 0; j < delegators.length; j++) {
                delegatorsBalance[j] = contractRegistry.stakingContract().plennyBalance(delegators[j]);
            }

            elections[latestElectionBlock][newValidators[i]] = Election(latestElectionBlock, revenueShare, stakedBalance, delegatedBalance, delegators, delegatorsBalance);
            activeElection[latestElectionBlock].push(Election(latestElectionBlock, revenueShare, stakedBalance, delegatedBalance, delegators, delegatorsBalance));
        }
        electedValidators[latestElectionBlock] = newValidators;

    }

    /// @notice Reserves a reward for a given validator as a result of a oracle validation done on-chain.
    /// @param  validator to reserve reward for
    /// @param  oracleChannelReward the reward amount
    function reserveReward(address validator, uint256 oracleChannelReward) external override whenNotPaused nonReentrant {
        _onlyAggregator();

        uint256 userReward = oracleChannelReward.mul(userRewardPercent).div(10000);
        uint256 validatorReward = oracleChannelReward - userReward;

        pendingUserReward[latestElectionBlock] += userReward;
        pendingElectionRewardPerValidator[latestElectionBlock][validator] += validatorReward;
        pendingElectionReward[latestElectionBlock] += oracleChannelReward;
    }

    /// @notice Changes the new election period (measured in blocks). Called by the owner.
    /// @param  amount election period, in blocks
    function setNewElectionPeriod(uint256 amount) external onlyOwner {
        newElectionPeriod = amount;
    }

    /// @notice Changes the maximum number of validators. Called by the owner.
    /// @param  amount validators
    function setMaxValidators(uint256 amount) external onlyOwner {
        maxValidators = amount;
    }

    /// @notice Changes the user reward in percentage. Called by the owner.
    /// @param  amount amount percentage for the user
    function setUserRewardPercent(uint256 amount) external onlyOwner {
        userRewardPercent = amount;
    }

    /// @notice Gets elected validator count per election.
    /// @param  electionBlock block of the election
    /// @return uint256 count
    function getElectedValidatorsCount(uint256 electionBlock) external view override returns (uint256) {
        return electedValidators[electionBlock].length;
    }

    /// @notice Get a random index for the election based on the validators scores and a randomness.
    /// @param _scores validators scores
    /// @param _scoreSum score sum
    /// @param _randomNumber randomness
    /// @return uint256 index
    function _getRandomIndex(uint256[] memory _scores, uint256 _scoreSum, uint256 _randomNumber) internal pure returns (uint256) {
        uint256 random = _randomNumber % _scoreSum;
        uint256 sum = 0;
        uint256 index = 0;
        while (sum <= random) {
            sum += _scores[index];
            index++;
        }
        return index - 1;
    }

    /// @notice Get validator index.
    /// @param  _oracles validators
    /// @param  _randomIndex the index
    /// @return uint256 the actual index
    function _getValidatorIndex(ValidatorIndex [] memory _oracles, uint256 _randomIndex) internal pure returns (uint256) {
        if (_oracles[_randomIndex].exists) {
            return _oracles[_randomIndex].index;
        } else {
            return _randomIndex;
        }
    }

    /// @dev    logs the function calls.
    function _logs_() internal {
        emit LogCall(msg.sig, msg.sender, msg.data);
    }

    /// @dev    Only the authorized contracts can make requests.
    function _onlyAggregator() internal view {
        require(contractRegistry.requireAndGetAddress("PlennyOracleValidator") == msg.sender, "ERR_NON_AGGR");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./interfaces/IPlennyERC20.sol";
import "./interfaces/IWETH.sol";
import "./PlennyBasePausableV2.sol";
import "./storage/PlennyTreasuryStorage.sol";

/// @title  PlennyTreasury
/// @notice Stores Plenny reserved for rewards given within the capacity market and for oracle validations.
contract PlennyTreasury is PlennyBasePausableV2, PlennyTreasuryStorage {

    using SafeERC20Upgradeable for IPlennyERC20;

    /// An event emitted when logging function calls.
    event LogCall(bytes4  indexed sig, address indexed caller, bytes data) anonymous;

    /// @dev    logs the function calls.
    modifier _logs_() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    /// @dev    If a token is supported in the treasury.
    modifier onlySupported(address tokenToTransfer) {
        require(isSupported(tokenToTransfer), "ERR_NOT_SUPPORTED");
        _;
    }

    /// @notice Initializes the smart contract instead of an constructor. Called once during deploy.
    /// @param  _registry Plenny contract registry
    function initialize(address _registry) external initializer {
        PlennyBasePausableV2.__plennyBasePausableInit(_registry);
    }

    /// @notice Transfers the amount of the given token to the given address. Called by the owner.
    /// @param  to address
    /// @param  tokenToTransfer token address
    /// @param  value reward amount
    function transfer(address to, address tokenToTransfer, uint256 value)
    external onlyOwner whenNotPaused onlySupported(tokenToTransfer) _logs_ {

        require(IPlennyERC20(tokenToTransfer).balanceOf(address(this)) >= value, "ERR_NO_FUNDS");
        IPlennyERC20(tokenToTransfer).safeTransfer(to, value);
    }

    /// @notice Approves a reward for the given address.
    /// @param  addr address to send reward to
    /// @param  amount reward amount
    /// @return bool true/false
    function approve(address addr, uint256 amount) external override returns (bool) {
        _onlyAuth();
        contractRegistry.plennyTokenContract().safeApprove(addr, amount);
        return true;
    }

    /// @notice If token is supported by the treasury.
    /// @param  tokenToTransfer token address
    /// @return bool true/false
    function isSupported(address tokenToTransfer) public view returns (bool) {
        return contractRegistry.requireAndGetAddress("PlennyERC20") == tokenToTransfer
        || contractRegistry.requireAndGetAddress("UNIETH-PL2") == tokenToTransfer;
    }

    /// @dev    Only the authorized contracts can make requests.
    function _onlyAuth() internal view {
        require(contractRegistry.getAddress("PlennyLiqMining") == msg.sender
        || contractRegistry.requireAndGetAddress("PlennyOracleValidator") == msg.sender
        || contractRegistry.requireAndGetAddress("PlennyCoordinator") == msg.sender
            || contractRegistry.requireAndGetAddress("PlennyValidatorElection") == msg.sender, "ERR_NOT_AUTH");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "./PlennyBasePausableV2.sol";
import "./storage/PlennyOracleValidatorStorage.sol";

/// @title  PlennyOracleValidator
/// @notice Runs channel validations (for opening and closing) and contains the logic for reaching consensus among the
///         oracle validators participating in the  Decentralized Oracle Network (DON).
contract PlennyOracleValidator is PlennyBasePausableV2, PlennyOracleValidatorStorage {

    using SafeMathUpgradeable for uint256;
    /// An event emitted when logging function calls.
    event LogCall(bytes4  indexed sig, address indexed caller, bytes data) anonymous;

    /// An event emitted when channel opening info is committed.
    event ChannelOpeningCommit(address indexed leader, uint256 indexed channelIndex);
    /// An event emitted when channel opening is verified.
    event ChannelOpeningVerify(address indexed validator, uint256 indexed channelIndex);
    /// An event emitted when channel opening info is revealed and checked.
    event ChannelOpeningReveal(address indexed leader, uint256 channelIndex);

    /// An event emitted when channel closing info committed.
    event ChannelClosingCommit(address indexed leader, uint256 indexed channelIndex);
    /// An event emitted when channel closing is verified.
    event ChannelClosingVerify(address indexed validator, uint256 indexed channelIndex);
    /// An event emitted when channel closing info is revealed and checked.
    event ChannelCloseReveal(address indexed leader, uint256 channelIndex);

    /// @dev    log function call.
    modifier _logs_() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    /// @dev    only oracle validator check.
    modifier onlyValidators {

        IPlennyValidatorElection validatorElection = contractRegistry.validatorElectionContract();
        require(validatorElection.validators(validatorElection.latestElectionBlock(), msg.sender), "ERR_NOT_VALIDATOR");
        _;
    }

    /// @notice Initializes the smart contract instead of a constructor. Called once during deploy.
    /// @param  _registry Plenny contract registry
    function initialize(address _registry) external initializer {

        minQuorumDivisor = 70;

        oracleFixedRewardAmount = uint256(200).mul((10 ** uint256(18)));
        // 0.00008%
        oracleRewardPercentage = 8;

        // 85%
        leaderRewardPercent = 85;

        PlennyBasePausableV2.__plennyBasePausableInit(_registry);
    }

    /// @notice Called whenever an oracle has gathered enough signatures from other oracle validators offline,
    ///         containing the channel information on the Lightning Network.
    ///         The sender oracle validator (i.e leader) claims the biggest reward for posting the data on-chain.
    ///         Other off-chain validators also receive a smaller reward for their off-chain validation.
    /// @dev    All oracle validators are running the Plenny oracle service. When a new channel opening needs to be
    ///         verified on the Lightning Network, the validators are competing with each other to obtain the data from
    ///         the Lightning Network and get enough signatures for that data from other validators.
    ///         Whoever validator gets enough signatures first is entitled to call this function for posting the data on-chain.
    /// @param  channelIndex index/id of the channel submission as registered in this contract.
    /// @param  _channelCapacitySat capacity of the channel expressed in satoshi.
    /// @param  channelId Id of the channel as registered on the lightning network.
    /// @param  nodePublicKey Public key of the first node in the channel.
    /// @param  node2PublicKey Public key of the second node in the channel.
    /// @param  signatures array of validators signatures gathered offline. They are verified against the channel data.
    function execChannelOpening(uint256 channelIndex, uint256 _channelCapacitySat,
        uint256 channelId, string calldata nodePublicKey, string calldata node2PublicKey, bytes[] memory signatures)
            external onlyValidators whenNotPaused _logs_ {

        require(latestOpenChannelAnswer[channelIndex] == 0, "ERR_ANSWERED");

        bytes32 dataHash = keccak256(abi.encodePacked(channelIndex, _channelCapacitySat, channelId, nodePublicKey, node2PublicKey));
        IPlennyValidatorElection validatorElection = contractRegistry.validatorElectionContract();

        for (uint i = 0; i < signatures.length ; i++) {
            address signatory = ECDSAUpgradeable.recover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)),
                    signatures[i]);

            // check if the signatory is a validator
            if (validatorElection.validators(validatorElection.latestElectionBlock(), signatory)
                && !oracleOpenChannelAnswers[channelIndex][signatory]) {

                oracleOpenChannelConsensus[channelIndex].push(signatory);
                oracleOpenChannelAnswers[channelIndex][signatory] = true;
                oracleValidations[validatorElection.latestElectionBlock()][signatory]++;
            }
        }

        require(oracleOpenChannelAnswers[channelIndex][msg.sender], "ERR_SENDER_MISSING_SIGNATURE");
        require(oracleOpenChannelConsensus[channelIndex].length >= minQuorum(), "ERR_OPEN_CONSENSUS");

        latestOpenChannelAnswer[channelIndex] = dataHash;
        updateOracleRewards(oracleOpenChannelConsensus[channelIndex], msg.sender);

        contractRegistry.coordinatorContract().confirmChannelOpening(channelIndex,
            _channelCapacitySat, channelId,
            nodePublicKey, node2PublicKey);
        emit ChannelOpeningReveal(msg.sender, channelIndex);

    }

    /// @notice Called whenever an oracle has gathered enough signatures from other oracle validators offline,
    ///         containing the information of the channel closing on the Lightning Network.
    ///         The sender oracle validator (i.e leader) claims the biggest reward for posting the data on-chain.
    ///         Other off-chain validators also receive a smaller reward for their off-chain validation.
    /// @dev    All oracle validators are running the Plenny oracle service. When a channel is closed on the Lightning Network,
    ///         the validators are competing with each other's to obtain the closing transaction data from the lightning Network
    ///         and get enough signature for that data from other validators off-chain.
    ///         Whoever validator gets enough signatures first is entitled to call this function for posting the data on-chain.
    /// @param  channelIndex channel index/id of an already opened channel
    /// @param  closingTransactionId bitcoin closing transaction id of the closing lightning channel
    /// @param  signatures signatures array of validators signatures gathered via validator's REST API. They are verified against the channel data.
    function execCloseChannel(uint256 channelIndex, string memory closingTransactionId, bytes[] memory signatures)
        external onlyValidators whenNotPaused nonReentrant _logs_ {

        require(latestCloseChannelAnswer[channelIndex] == 0, "ERR_ANSWERED");

        bytes32 dataHash = keccak256(abi.encodePacked(channelIndex, closingTransactionId));
        IPlennyValidatorElection validatorElection = contractRegistry.validatorElectionContract();

        for (uint i = 0; i < signatures.length ; i++) {
            address signatory = ECDSAUpgradeable.recover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)),
                    signatures[i]);

            // check if the signatory is a validator
            if (validatorElection.validators(validatorElection.latestElectionBlock(), signatory)
                && !oracleCloseChannelAnswers[channelIndex][signatory]) {

                oracleCloseChannelConsensus[channelIndex].push(signatory);
                oracleCloseChannelAnswers[channelIndex][signatory] = true;
                oracleValidations[validatorElection.latestElectionBlock()][signatory]++;
            }
        }

        require(oracleCloseChannelAnswers[channelIndex][msg.sender], "ERR_SENDER_MISSING_SIGNATURE");
        require(oracleCloseChannelConsensus[channelIndex].length >= minQuorum(), "ERR_CLOSE_CONSENSUS");

        latestCloseChannelAnswer[channelIndex] = dataHash;
        updateOracleRewards(oracleCloseChannelConsensus[channelIndex], msg.sender);
        contractRegistry.coordinatorContract().closeChannel(channelIndex);

        emit ChannelCloseReveal(msg.sender, channelIndex);
    }

    /// @notice Changes the oracle reward percentage. Called by the contract owner.
    /// @param  value oracle validator reward
    function setOracleRewardPercentage(uint256 value) external onlyOwner {
        oracleRewardPercentage = value;
    }

    /// @notice Changes the oracle fixed reward amount. Called by the contract owner.
    /// @param  value oracle validator fixed reward
    function setOracleFixedRewardAmount(uint256 value) external onlyOwner {
        oracleFixedRewardAmount = value;
    }


    /// @notice Changes the leader reward percentage. Called by the contract owner.
    /// @param  amount leader percentage
    function setLeaderRewardPercent(uint256 amount) external onlyOwner {
        leaderRewardPercent = amount;
    }

    /// @notice Consensus length for the given channel (opening).
    /// @param  channelIndex channel id
    /// @return uint256 how many validators has reached consensus for this channel
    function oracleOpenChannelConsensusLength(uint256 channelIndex) external view returns (uint256) {
        return oracleOpenChannelConsensus[channelIndex].length;
    }

    /// @notice Consensus length for the given channel (closing).
    /// @param  channelIndex channel id
    /// @return uint256 how many validators has reached consensus for this channel
    function oracleCloseChannelConsensusLength(uint256 channelIndex) external view returns (uint256) {
        return oracleCloseChannelConsensus[channelIndex].length;
    }

    /// @notice Minimum quorum for reaching the oracle validator consensus.
    /// @return uint256 consensus quorum
    function minQuorum() public view returns (uint256) {

        IPlennyValidatorElection validatorElection = contractRegistry.validatorElectionContract();

        uint quorum = validatorElection.getElectedValidatorsCount(validatorElection.latestElectionBlock()) * minQuorumDivisor / 100;
        return quorum > 0 ? quorum : 1;
    }

    /// @notice Updates all the oracle validators reward for the given validation cycle.
    /// @param  signatories off-chain validators
    /// @param  leader on-chain validator
    function updateOracleRewards(address[] memory signatories, address leader) internal {

        uint256 treasuryBalance = contractRegistry.plennyTokenContract().balanceOf(
            contractRegistry.requireAndGetAddress("PlennyTreasury"));
        uint256 oracleChannelReward;

        if (oracleFixedRewardAmount < oracleRewardPercentage.mul(treasuryBalance).div(100).div(100000)) {
            oracleChannelReward = oracleFixedRewardAmount;
        } else {
            oracleChannelReward = oracleRewardPercentage.mul(treasuryBalance).div(100).div(100000);
        }

        totalOracleReward += oracleChannelReward;

        // distribute the reward to the signatories
        for (uint i = 0; i < signatories.length ; i++) {
            address signatory = signatories[i];

            uint256 signatoryReward = leader == signatory ? oracleChannelReward.mul(leaderRewardPercent).div(100)
            : (oracleChannelReward - oracleChannelReward.mul(leaderRewardPercent).div(100)).div(signatories.length - 1);

            contractRegistry.validatorElectionContract().reserveReward(signatory, signatoryReward);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./storage/PlennyLiqMiningStorage.sol";
import "./PlennyBasePausableV2.sol";
import "./libraries/ExtendedMathLib.sol";
import "./interfaces/IWETH.sol";

/// @title  PlennyLiqMining
/// @notice Staking for liquidity mining integrated with the DEX, allows users to stake LP-token and earn periodic rewards.
contract PlennyLiqMining is PlennyBasePausableV2, PlennyLiqMiningStorage {

    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address payable;
    using ExtendedMathLib for uint256;

    /// An event emitted when logging function calls
    event LogCall(bytes4  indexed sig, address indexed caller, bytes data) anonymous;

    /// @notice Initializes the contract instead of the constructor. Called once during contract deployment.
    /// @param  _registry plenny contract registry
    function initialize(address _registry) external initializer {
        // 5%
        liquidityMiningFee = 500;

        liqMiningReward = 1;
        // 0.01%

        // 0.5%
        fishingFee = 50;

        // 1 day = 6646 blocks
        nextDistributionSeconds = 6646;

        // 10 years in blocks
        maxPeriodWeek = 24275076;
        // 1 week in blocks
        averageBlockCountPerWeek = 46523;

        PlennyBasePausableV2.__plennyBasePausableInit(_registry);
    }

    /// @notice Locks LP token in this contract for the given period.
    /// @param  amount lp amount to lock
    /// @param  period period, in weeks
    function lockLP(uint256 amount, uint256 period) external whenNotPaused nonReentrant {
        _logs_();
        require(amount > 0, "ERR_EMPTY");
        require(period <= maxPeriodWeek, "ERR_MAX_PERIOD");

        uint256 weight = calculateWeight(period);
        uint256 endDate = _blockNumber().add(averageBlockCountPerWeek.mul(period));
        lockedBalance.push(LockedBalance(msg.sender, amount, _blockNumber(), endDate, weight, false));
        uint256 index = lockedBalance.length - 1;
        lockedIndexesPerAddress[msg.sender].push(index);

        totalUserLocked[msg.sender] = totalUserLocked[msg.sender].add(amount);
        totalUserWeight[msg.sender] = totalUserWeight[msg.sender].add(amount.mul(weight).div(WEIGHT_MULTIPLIER));
        if (userLockedPeriod[msg.sender] == 0) {
            userLockedPeriod[msg.sender] = _blockNumber().add(nextDistributionSeconds);
            userLastCollectedPeriod[msg.sender] = _blockNumber();
        }

        totalValueLocked = totalValueLocked.add(amount);
        totalWeightLocked = totalWeightLocked.add(amount.mul(weight).div(WEIGHT_MULTIPLIER));

        require(contractRegistry.lpContract().transferFrom(msg.sender, address(this), amount), "Failed");
    }

    /// @notice Relocks the LP tokens once the locking period has expired.
    /// @param  index id of the previously locked record
    /// @param  period the new locking period, in weeks
    function relockLP(uint256 index, uint256 period) external whenNotPaused nonReentrant {
        _logs_();
        uint256 i = lockedIndexesPerAddress[msg.sender][index];
        require(index < lockedBalance.length, "ERR_NOT_FOUND");
        require(period > 0, "ERR_INVALID_PERIOD");
        require(period <= maxPeriodWeek, "ERR_MAX_PERIOD");
        LockedBalance storage balance = lockedBalance[i];
        require(balance.owner == msg.sender, "ERR_NO_PERMISSION");
        require(balance.endDate < _blockNumber(), "ERR_LOCKED");

        uint256 oldWeight = balance.amount.mul(balance.weight).div(WEIGHT_MULTIPLIER);
        totalUserWeight[msg.sender] = totalUserWeight[msg.sender].sub(oldWeight);
        totalWeightLocked = totalWeightLocked.sub(oldWeight);

        uint256 weight = calculateWeight(period);
        balance.endDate = _blockNumber().add(averageBlockCountPerWeek.mul(period));
        balance.weight = weight;

        uint256 newWeight = balance.amount.mul(balance.weight).div(WEIGHT_MULTIPLIER);
        totalUserWeight[msg.sender] = totalUserWeight[msg.sender].add(newWeight);
        totalWeightLocked = totalWeightLocked.add(newWeight);
    }

    /// @notice Withdraws the LP tokens, once the locking period has expired.
    /// @param  index id of the locking record
    function withdrawLP(uint256 index) external whenNotPaused nonReentrant {
        _logs_();
        uint256 i = lockedIndexesPerAddress[msg.sender][index];
        require(index < lockedBalance.length, "ERR_NOT_FOUND");

        LockedBalance storage balance = lockedBalance[i];
        require(balance.owner == msg.sender, "ERR_NO_PERMISSION");
        require(balance.endDate < _blockNumber(), "ERR_LOCKED");

        if (lockedIndexesPerAddress[msg.sender].length == 1) {
            userLockedPeriod[msg.sender] = 0;
        }

        uint256 fee = balance.amount.mul(fishingFee).div(100).div(100);
        uint256 weight = balance.amount.mul(balance.weight).div(WEIGHT_MULTIPLIER);

        if (_blockNumber() > (userLastCollectedPeriod[msg.sender]).add(nextDistributionSeconds)) {
            totalUserEarned[msg.sender] = totalUserEarned[msg.sender].add(
                calculateReward(weight).mul(_blockNumber().sub(userLastCollectedPeriod[msg.sender])).div(nextDistributionSeconds));
            totalWeightCollected = totalWeightCollected.add(weight);
            totalWeightLocked = totalWeightLocked.sub(weight);
        } else {
            totalWeightLocked = totalWeightLocked.sub(weight);
        }

        totalUserLocked[msg.sender] = totalUserLocked[msg.sender].sub(balance.amount);
        totalUserWeight[msg.sender] = totalUserWeight[msg.sender].sub(weight);
        totalValueLocked = totalValueLocked.sub(balance.amount);

        balance.deleted = true;
        removeElementFromArray(index, lockedIndexesPerAddress[msg.sender]);

        IUniswapV2Pair lpToken = contractRegistry.lpContract();
        require(lpToken.transfer(msg.sender, balance.amount - fee), "Failed");
        require(lpToken.transfer(contractRegistry.requireAndGetAddress("PlennyRePLENishment"), fee), "Failed");
    }

    /// @notice Collects plenny reward for the locked LP tokens
    function collectReward() external whenNotPaused nonReentrant {
        if (totalUserEarned[msg.sender] == 0) {
            require(userLockedPeriod[msg.sender] < _blockNumber(), "ERR_LOCKED_PERIOD");
        }

        uint256 reward = calculateReward(totalUserWeight[msg.sender]).mul((_blockNumber().sub(userLastCollectedPeriod[msg.sender]))
        .div(nextDistributionSeconds)).add(totalUserEarned[msg.sender]);

        uint256 fee = reward.mul(liquidityMiningFee).div(10000);

        bool reset = true;
        uint256 [] memory userRecords = lockedIndexesPerAddress[msg.sender];
        for (uint256 i = 0; i < userRecords.length; i++) {
            LockedBalance storage balance = lockedBalance[userRecords[i]];
            reset = false;
            if (balance.weight > WEIGHT_MULTIPLIER && balance.endDate < _blockNumber()) {
                uint256 diff = balance.amount.mul(balance.weight).div(WEIGHT_MULTIPLIER).sub(balance.amount);
                totalUserWeight[msg.sender] = totalUserWeight[msg.sender].sub(diff);
                totalWeightLocked = totalWeightLocked.sub(diff);
                balance.weight = uint256(1).mul(WEIGHT_MULTIPLIER);
            }
        }

        if (reset) {
            userLockedPeriod[msg.sender] = 0;
        } else {
            userLockedPeriod[msg.sender] = _blockNumber().add(nextDistributionSeconds);
        }
        userLastCollectedPeriod[msg.sender] = _blockNumber();
        totalUserEarned[msg.sender] = 0;
        totalWeightCollected = 0;

        IPlennyReward plennyReward = contractRegistry.rewardContract();
        require(plennyReward.transfer(msg.sender, reward - fee), "Failed");
        require(plennyReward.transfer(contractRegistry.requireAndGetAddress("PlennyRePLENishment"), fee), "Failed");
    }

    /// @notice Changes the liquidity Mining Fee. Managed by the contract owner.
    /// @param  newLiquidityMiningFee mining fee. Multiplied by 10000
    function setLiquidityMiningFee(uint256 newLiquidityMiningFee) external onlyOwner {
        require(newLiquidityMiningFee < 10001, "ERR_WRONG_STATE");
        liquidityMiningFee = newLiquidityMiningFee;
    }

    /// @notice Changes the fishing Fee. Managed by the contract owner
    /// @param  newFishingFee fishing(exit) fee. Multiplied by 10000
    function setFishingFee(uint256 newFishingFee) external onlyOwner {
        require(newFishingFee < 10001, "ERR_WRONG_STATE");
        fishingFee = newFishingFee;
    }

    /// @notice Changes the next Distribution in seconds. Managed by the contract owner
    /// @param  value number of blocks.
    function setNextDistributionSeconds(uint256 value) external onlyOwner {
        nextDistributionSeconds = value;
    }

    /// @notice Changes the max Period in week. Managed by the contract owner
    /// @param  value max locking period, in blocks
    function setMaxPeriodWeek(uint256 value) external onlyOwner {
        maxPeriodWeek = value;
    }

    /// @notice Changes average block counts per week. Managed by the contract owner
    /// @param count blocks per week
    function setAverageBlockCountPerWeek(uint256 count) external onlyOwner {
        averageBlockCountPerWeek = count;
    }

    /// @notice Percentage reward for liquidity mining. Managed by the contract owner.
    /// @param  value multiplied by 100
    function setLiqMiningReward(uint256 value) external onlyOwner {
        liqMiningReward = value;
    }

    /// @notice Number of total locked records.
    /// @return uint256 number of records
    function lockedBalanceCount() external view returns (uint256) {
        return lockedBalance.length;
    }

    /// @notice Shows potential reward for the given user.
    /// @return uint256 token amount
    function getPotentialRewardLiqMining() external view returns (uint256) {
        return calculateReward(totalUserWeight[msg.sender]);
    }

    /// @notice Gets number of locked records per address.
    /// @param  addr address to check
    /// @return uint256 number
    function getBalanceIndexesPerAddressCount(address addr) external view returns (uint256){
        return lockedIndexesPerAddress[addr].length;
    }

    /// @notice Gets locked records per address.
    /// @param  addr address to check
    /// @return uint256[] arrays of indexes
    function getBalanceIndexesPerAddress(address addr) external view returns (uint256[] memory){
        return lockedIndexesPerAddress[addr];
    }

    /// @notice Gets the LP token rate.
    /// @return rate
    function getUniswapRate() external view returns (uint256 rate){

        IUniswapV2Pair lpContract = contractRegistry.lpContract();

        address token0 = lpContract.token0();
        if (token0 == contractRegistry.requireAndGetAddress("WETH")) {
            (uint256 tokenEth, uint256 tokenPl2,) = lpContract.getReserves();
            return tokenPl2 > 0 ? uint256(1).mul((10 ** uint256(18))).mul(tokenEth).div(tokenPl2) : 0;
        } else {
            (uint256 pl2, uint256 eth,) = lpContract.getReserves();
            return pl2 > 0 ? uint256(1).mul((10 ** uint256(18))).mul(eth).div(pl2) : 0;
        }
    }

    /// @notice Calculates the reward of the user based on the user's participation (weight) in the LP locking.
    /// @param  weight participation in the LP mining
    /// @return uint256 plenny reward amount
    function calculateReward(uint256 weight) public view returns (uint256) {
        if (totalWeightLocked > 0) {
            return contractRegistry.plennyTokenContract().balanceOf(
                contractRegistry.requireAndGetAddress("PlennyReward")).mul(liqMiningReward)
                .mul(weight).div(totalWeightLocked.add(totalWeightCollected)).div(10000);
        } else {
            return 0;
        }
    }

    /// @notice Calculates the user's weight based on its locking period.
    /// @param  period locking period, in weeks
    /// @return uint256 weight
    function calculateWeight(uint256 period) internal pure returns (uint256) {

        uint256 periodInWei = period.mul(10 ** uint256(18));
        uint256 weightInWei = uint256(1).add((uint256(2).mul(periodInWei.sqrt())).div(10));

        uint256 numerator = (weightInWei.sub(1)).mul(WEIGHT_MULTIPLIER);
        uint256 denominator = (10 ** uint256(18)).sqrt();
        return numerator.div(denominator).add(WEIGHT_MULTIPLIER);
    }

    /// @notice String equality.
    /// @param  a first string
    /// @param  b second string
    /// @return bool true/false
    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    /// @notice Emits log event of the function calls.
    function _logs_() internal {
        emit LogCall(msg.sig, msg.sender, msg.data);
    }

    /// @notice Removes index element from the given array.
    /// @param  index index to remove from the array
    /// @param  array the array itself
    function removeElementFromArray(uint256 index, uint256[] storage array) private {
        if (index == array.length - 1) {
            array.pop();
        } else {
            array[index] = array[array.length - 1];
            array.pop();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

pragma experimental ABIEncoderV2;

import "./PlennyBasePausableV2.sol";
import "./storage/PlennyDaoStorage.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./interfaces/ArbSys.sol";

/// @title  PlennyDao
/// @notice Governs the Dapp via voting on community proposals.
contract PlennyDao is PlennyBasePausableV2, PlennyDaoStorage {

    using SafeMathUpgradeable for uint256;

    /// An event emitted when a new delay is set.
    event NewDelay(uint indexed newDelay);
    /// An event emitted when logging function calls.
    event LogCall(bytes4  indexed sig, address indexed caller, bytes data) anonymous;
    /// An event emitted when a new proposal is created.
    event ProposalCreated(uint indexed id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);
    /// An event emitted when a vote has been cast on a proposal.
    event VoteCast(address voter, uint indexed proposalId, bool support, uint votes);
    /// An event emitted when a proposal has been canceled.
    event ProposalCanceled(uint indexed id);
    /// An event emitted when a proposal has been queued in the Timelock.
    event ProposalQueued(uint indexed id, uint eta);
    /// An event emitted when a proposal has been executed in the Timelock.
    event ProposalExecuted(uint indexed id);
    /// An event emitted when a proposal has been canceled.
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    /// An event emitted when a proposal has been executed.
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    /// An event emitted when a proposal has been queued.
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    /// An event emitted when a new guardian is set.
    event NewGuardian(address guardian);

    /// @dev    Emits log event of the function calls.
    modifier _logs_() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    /// @notice Initializes the smart contract instead of a constructor.
    /// @dev    Can be called only once during deployment.
    /// @param  _registry PlennyContractRegistry
    function initialize(address _registry) external initializer {
        // sets the minimal quorum to 50%
        minQuorum = 5000;
        // set the proposal threshold to 1%
        proposalThreshold = 100;
        //execution delay in blocks count with an average of 13s per block, 2 minutes approximately
        delay = 10;
        // voting duration & delays in blocks
        votingDuration = 20;
        votingDelay = 1;

        PlennyBasePausableV2.__plennyBasePausableInit(_registry);

        guardian = msg.sender;
    }

    /// @notice Submits a governance proposal. The submitter needs to have enough votes at stake in order to submit a proposal
    /// @dev    A proposal is an executable code that consists of the address of the smart contract to call, the function
    ///         (signature to call), and the value(s) provided to that function.
    /// @param  targets addresses of the smart contracts
    /// @param  values values provided to the relevant functions
    /// @param  signatures function signatures
    /// @param  calldatas function data
    /// @param  description the description of the proposal
    /// @return uint proposal id
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures,
        bytes[] memory calldatas, string memory description) external whenNotPaused _logs_ returns (uint) {

        require(contractRegistry.lockingContract().getUserVoteCountAtBlock(
            msg.sender, _blockNumber().sub(1)) > minProposalVoteCount(_blockNumber().sub(1)), "ERR_BELOW_THREASHOLD");
        require(targets.length == values.length && targets.length == signatures.length
            && targets.length == calldatas.length, "ERR_LENGHT_MISMATCH");
        require(targets.length != 0, "ERR_NO_ACTION");
        require(targets.length <= proposalMaxOperations(), "ERR_MANY_ACTION");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "ERR_ALREADY_ACTIVE");
            require(proposersLatestProposalState != ProposalState.Pending, "ERR_ALREADY_PENDING");
        }

        uint startBlock = _blockNumber().add(votingDelay);
        uint endBlock = startBlock.add(votingDuration);

        proposalCount++;
        Proposal memory newProposal = Proposal({
        id : proposalCount,
        proposer : msg.sender,
        eta : 0,
        targets : targets,
        values : values,
        signatures : signatures,
        calldatas : calldatas,
        startBlock : startBlock,
        startBlockAlt: _altBlockNumber(),
        endBlock : endBlock,
        forVotes : 0,
        againstVotes : 0,
        canceled : false,
        executed : false
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    /// @notice Casts a vote for the given proposal.
    /// @param  _proposalID proposal id
    /// @param  support for/against the proposal
    function castVote(uint _proposalID, bool support) external whenNotPaused nonReentrant _logs_ {
        return _castVote(msg.sender, _proposalID, support);
    }

    /// @notice Casts a vote for the given proposal using signed signatures.
    /// @param  _proposalID proposal id
    /// @param  support for/against the proposal
    /// @param  v recover value + 27
    /// @param  r first 32 bytes of the signature
    /// @param  s next 32 bytes of the signature
    function castVoteBySig(uint _proposalID, bool support, uint8 v, bytes32 r, bytes32 s) external whenNotPaused nonReentrant _logs_ {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, _proposalID, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ERR_INVALID_ADDR");
        return _castVote(signatory, _proposalID, support);
    }

    /// @notice Queues a proposal into the timelock for execution, if it has been voted successfully.
    /// @param  _proposalID proposal id
    function queue(uint _proposalID) external whenNotPaused nonReentrant _logs_ {
        require(state(_proposalID) == ProposalState.Succeeded, "ERR_NOT_SUCCESS");
        Proposal storage proposal = proposals[_proposalID];

        uint eta = _blockNumber().add(delay);

        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(_proposalID, eta);
    }

    /// @notice Cancels a proposal.
    /// @param  _proposalID proposal id
    function cancel(uint _proposalID) external whenNotPaused nonReentrant _logs_ {
        ProposalState state = state(_proposalID);
        require(state != ProposalState.Executed, "ERR_ALREADY_EXEC");

        Proposal storage proposal = proposals[_proposalID];
        require(msg.sender == guardian || contractRegistry.lockingContract().getUserVoteCountAtBlock(
            proposal.proposer, _blockNumber().sub(1)) < minProposalVoteCount(_blockNumber().sub(1)), "ERR_CANNOT_CANCEL");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(_proposalID);
    }

    /// @notice Executes a proposal that has been previously queued in a timelock.
    /// @param  _proposalID proposal id
    function execute(uint _proposalID) external payable whenNotPaused nonReentrant _logs_ {
        require(state(_proposalID) == ProposalState.Queued, "ERR_NOT_QUEUED");

        Proposal storage proposal = proposals[_proposalID];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(_proposalID);
    }

    /// @notice Queues proposal to change a guardian. Guardian can temporarily reject unwanted proposals.
    /// @param  newGuardian new guardian address
    /// @param  eta proposal ETA
    function queueSetGuardian(address newGuardian, uint eta) external {
        require(msg.sender == guardian, "ERR_NOT_AUTH");
        queueTransaction(address(this), 0, "setGuardian(address)", abi.encode(newGuardian), eta);
    }

    /// @notice Executes the guardian proposal. Guardian can temporarily reject unwanted proposals.
    /// @param  newGuardian new guardian address
    /// @param  eta proposal ETA for execution
    function executeSetGuardian(address newGuardian, uint eta) external {
        require(msg.sender == guardian, "ERR_NOT_AUTH");
        executeTransaction(address(this), 0, "setGuardian(address)", abi.encode(newGuardian), eta);
    }

    /// @notice Changes the guardian. Only called by the DAO itself.
    /// @param  _guardian new guardian address
    function setGuardian(address _guardian) external {
        require(msg.sender == address(this), "ERR_NOT_AUTH");
        require(_guardian != address(0), "ERR_INVALID_ADDRESS");

        guardian = _guardian;

        emit NewGuardian(_guardian);
    }

    /// @notice Abdicates as a guardian of the DAO.
    function abdicate() external {
        require(msg.sender == guardian, "ERR_NOT_AUTH");
        guardian = address(0);
    }

    /// @notice Changes the proposal delay.
    /// @param  delay_ delay
    function setDelay(uint64 delay_) external onlyOwner _logs_ {
        require(delay_ >= MINIMUM_DELAY, "Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    /// @notice Changes the proposal quorum.
    /// @param  value quorum
    function setMinQuorum(uint256 value) external onlyOwner _logs_ {
        minQuorum = value;
    }

    /// @notice Changes the proposal token threshold.
    /// @param  value threshold
    function setProposalThreshold(uint256 value) external onlyOwner _logs_ {
        proposalThreshold = value;
    }

    /// @notice Changes the proposal voting duration.
    /// @param  value voting duration, in blocks
    function setVotingDuration(uint256 value) external onlyOwner _logs_ {
        votingDuration = value;
    }

    /// @notice Changes the proposal voting delay.
    /// @param  value voting delay, in blocks
    function setVotingDelay(uint256 value) external onlyOwner _logs_ {
        votingDelay = value;
    }

    /// @notice Gets the proposal info.
    /// @param  _proposalID proposal id
    /// @return targets addresses of the smart contracts
    /// @return values values provided to the relevant functions
    /// @return signatures function signatures
    /// @return calldatas function data
    function getActions(uint _proposalID) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[_proposalID];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /// @notice Gets the receipt of voting for a proposal.
    /// @param  _proposalID proposal id
    /// @param  voter voter address
    /// @return Receipt receipt info
    function getReceipt(uint _proposalID, address voter) external view returns (Receipt memory) {
        return proposals[_proposalID].receipts[voter];
    }

    /// @notice Min vote quorum at the given block number.
    /// @param  _blockNumber block number
    /// @return _minQuorum The minimum quorum
    function minQuorumVoteCount(uint _blockNumber) public view returns (uint _minQuorum) {
        return contractRegistry.lockingContract().getTotalVoteCountAtBlock(_blockNumber).mul(minQuorum).div(BASE);
    }

    /// @notice Min proposal votes at the given block number.
    /// @param  _blockNumber block number
    /// @return uint votes min votes
    function minProposalVoteCount(uint _blockNumber) public view returns (uint) {
        return contractRegistry.lockingContract().getTotalVoteCountAtBlock(_blockNumber).mul(proposalThreshold).div(BASE);
    }

    /// @notice State of the proposal.
    /// @param  _proposalID proposal id
    /// @return ProposalState The proposal state
    function state(uint _proposalID) public view returns (ProposalState) {
        require(proposalCount >= _proposalID && _proposalID > 0, "ERR_ID_NOT_FOUND");
        Proposal storage proposal = proposals[_proposalID];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (_blockNumber() <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (_blockNumber() <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < minQuorumVoteCount(proposal.startBlock)) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (_blockNumber() >= proposal.eta.add(GRACE_PERIOD)) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /// @notice Maximum number of actions in a proposal.
    /// @return uint number of actions
    function proposalMaxOperations() public pure returns (uint) {
        return 10;
        // 10 actions
    }

    /// @notice Cast a vote for the given proposal.
    /// @param  voter voter address
    /// @param  _proposalID proposal id
    /// @param  support for/against the proposal
    function _castVote(address voter, uint _proposalID, bool support) internal {
        require(state(_proposalID) == ProposalState.Active, "ERR_VOTING_CLOSED");
        Proposal storage proposal = proposals[_proposalID];
        Receipt storage receipt = proposal.receipts[voter];
        require(!receipt.hasVoted, "ERR_DUPLICATE_VOTE");
        uint votes = contractRegistry.lockingContract().getUserVoteCountAtBlock(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, _proposalID, support, votes);
    }

    /// @notice Alternative block number if on L2.
    /// @return uint256 L1 block number or L2 block number
    function _altBlockNumber() internal view returns (uint256){
        uint chainId = getChainId();
        if (chainId == 42161 || chainId == 421611) {
            return ArbSys(address(100)).arbBlockNumber();
        } else {
            return block.number;
        }
    }

    /// @notice Chain id
    /// @param  chainId The chain id
    function getChainId() internal pure returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    /// @notice Queues the proposal or reverts if cannot be queued
    /// @param  target address of the smart contracts
    /// @param  value value provided to the relevant function
    /// @param  signature function signature
    /// @param  data function data
    /// @param  eta proposal ETA
    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!queuedTransactions[keccak256(abi.encode(target, value, signature, data, eta))], "ERR_ALREADY_QUEUED");
        queueTransaction(target, value, signature, data, eta);
    }

    /// @notice Queues the proposal
    /// @param  target address of the smart contracts
    /// @param  value value provided to the relevant function
    /// @param  signature function signature
    /// @param  data function data
    /// @param  eta proposal ETA
    /// @return bytes32 transaction hash
    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) internal returns (bytes32) {
        require(eta >= _blockNumber().add(delay), "ERR_ETA_NOT_REACHED");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    /// @notice Cancels the proposal
    /// @param  target address of the smart contracts
    /// @param  value value provided to the relevant function
    /// @param  signature function signature
    /// @param  data function data
    /// @param  eta proposal ETA
    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) internal {

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    /// @notice Executes the proposal
    /// @param  target address of the smart contracts
    /// @param  value value provided to the relevant function
    /// @param  signature function signature
    /// @param  data function data
    /// @param  eta proposal ETA
    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta)
    internal returns (bytes memory) {

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "ERR_NOT_QUEUED");
        require(_blockNumber() >= eta, "ERR_ETA_NOT_REACHED");
        require(_blockNumber() <= eta.add(GRACE_PERIOD), "ERR_STALE_TXN");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        bool success;
        bytes memory returnData;
        if (target == address(this)) {
            // solhint-disable-next-line avoid-call-value
            (success, returnData) = address(this).call{value : value}(callData);
        } else {
            // solhint-disable-next-line avoid-call-value
            (success, returnData) = target.call{value : value}(callData);
        }

        require(success, "ERR_TXN_REVERTED");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./PlennyBaseUpgradableV2.sol";
import "./storage/PlennyCoordinatorStorage.sol";
import "./libraries/RewardLib.sol";

import "./interfaces/ArbSys.sol";

/// @title  PlennyCoordinator
/// @notice Coordinator contract between the Lightning Network and the Ethereum blockchain. Coordination and storing of
///         the data from the LN on-chain. Allows the users to provide info about their lightning nodes/channels,
///         and manages the channel rewards (i.e. NCCR) due for some actions.
contract PlennyCoordinator is PlennyBaseUpgradableV2, PlennyCoordinatorStorage {

    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IPlennyERC20;
    using RewardLib for uint256;

    /// An event emitted when a lightning node is added, but not yet verified.
    event LightningNodePending(address indexed by, uint256 verificationCapacity, string publicKey, address validatorAddress, uint256 indexed nodeIndex);
    /// An event emitted when a lightning node is verified.
    event LightningNodeVerified(address indexed to, string publicKey, uint256 indexed nodeIndex);
    /// An event emitted when a lightning channel is added, but not yet confirmed.
    event LightningChannelOpeningPending(address indexed by, string channelPoint, uint256 indexed channelIndex);
    /// An event emitted when a lightning channel is confirmed.
    event LightningChannelOpeningConfirmed(address to, uint256 amount, string node1, string node2, uint256 indexed channelIndex, uint256 blockNumber);
    /// An event emitted when a lightning channel is closed.
    event LightningChannelClosed(uint256 channelIndex);
    /// An event emitted when a reward is collected.
    event RewardReleased(address to, uint256 amount);
    /// An event emitted when logging function calls.
    event LogCall(bytes4  indexed sig, address indexed caller, bytes data) anonymous;

    /// @notice Initializes the smart contract instead of a constructor.
    /// @dev    Can be called only once during deploy.
    /// @param  _registry PlennyContractRegistry
    function initialize(address _registry) external initializer {
        channelRewardThreshold = uint256(500000);
        PlennyBaseUpgradableV2.__plennyBaseInit(_registry);
    }

    /// @notice Allows the user to add provisional information about their own lightning node.
    /// @dev    The lightning node is considered as "pending" in the system until the user verifies it by opening a channel
    ///         with a given capacity on the lightning network and submitting info (channel point) about that channel
    ///         in this contract.
    /// @param  nodePublicKey Public key of the lightning node.
    /// @param  validatorAddress An oracle validator address is responsible for validating the lightning node.
    /// @return uint256 The capacity of the channel that the user needs to open on the lightning network.
    function addLightningNode(string calldata nodePublicKey, address validatorAddress) external returns (uint256) {
        uint256 nodeIndex = nodeIndexPerPubKey[nodePublicKey][msg.sender];

        LightningNode storage node = nodes[nodeIndex];

        require(node.validatorAddress != validatorAddress, "ERR_DUPLICATE");
        if (nodeIndex > 0) {
            node.status = 2;
        }

        IPlennyDappFactory factory = contractRegistry.factoryContract();
        require(factory.isOracleValidator(validatorAddress), "ERR_NOT_ORACLE");

        uint256 verificationCapacity = factory.random();

        nodesCount++;
        nodes[nodesCount] = LightningNode(verificationCapacity, _blockNumber(), nodePublicKey, validatorAddress,
            0, 0, msg.sender);

        nodeIndexPerPubKey[nodePublicKey][msg.sender] = nodesCount;
        nodeOwnerCount[msg.sender]++;
        nodesPerAddress[msg.sender].push(nodesCount);

        emit LightningNodePending(msg.sender, verificationCapacity, nodePublicKey, validatorAddress, nodesCount);

        return (verificationCapacity);
    }

    /// @notice Submits a claim/info that a certain channel has been opened on the lightning network.
    /// @dev    The information can be submitted either by the end-user directly or by the maker that has opened
    ///         the channel via the lightning ocean/marketplace.
    /// @param  _channelPoint Channel point of the lightning channel.
    /// @param  _oracleAddress an address of the lightning oracle that is the counter-party of the lightning channel.
    /// @param  capacityRequest if this channel is opened via the lightning ocean/marketplace.
    function openChannel(string memory _channelPoint, address payable _oracleAddress, bool capacityRequest) external override {

        require(_oracleAddress != msg.sender, "ERR_SELF");

        require(contractRegistry.factoryContract().isOracleValidator(_oracleAddress)
            || contractRegistry.oceanContract().makerIndexPerAddress(_oracleAddress) > 0, "ERR_NOT_ORACLE");

        address payable nodeOwner;
        if (capacityRequest) {
            nodeOwner = _oracleAddress;
        } else {
            nodeOwner = msg.sender;
        }

        // check if the user has at least one verified node
        uint256 ownedNodes = nodeOwnerCount[nodeOwner];
        require(ownedNodes > 0, "ERR_NOT_FOUND");

        // check if this channel was already added
        uint256 channelIndex = channelIndexPerId[_channelPoint][nodeOwner];
        require(channelIndex == 0, "ERR_DUPLICATE");
        require(confirmedChannelIndexPerId[_channelPoint] == 0, "ERR_DUPLICATE");

        channelsCount++;
        channels[channelsCount] = LightningChannel(0, _blockNumber(), 0, 0, 0, nodeOwner,
            _oracleAddress, 0, 0, _channelPoint, 0, _altBlockNumber());

        channelsPerAddress[nodeOwner].push(channelsCount);
        channelIndexPerId[_channelPoint][nodeOwner] = channelsCount;
        channelStatusCount[0]++;

        emit LightningChannelOpeningPending(nodeOwner, _channelPoint, channelsCount);
    }

    /// @notice Instant verification of the initial(ZERO) lightning node. Managed by the contract owner.
    /// @param  publicKey The public key of the initial lightning node.
    /// @param  account address of the initial lightning oracle.
    /// @return uint256 node index
    function verifyDefaultNode(string calldata publicKey, address payable account) external override returns (uint256){
        _onlyFactory();

        nodesCount++;
        nodes[nodesCount] = LightningNode(0, _blockNumber(), publicKey, account, 1, _blockNumber(), account);
        nodeIndexPerPubKey[publicKey][account] = nodesCount;
        nodesPerAddress[account].push(nodesCount);
        uint256 newNodeIndex = nodeIndexPerPubKey[publicKey][account];

        nodeOwnerCount[account]++;
        return newNodeIndex;
    }

    /// @notice Confirms that a lightning channel with the provided information was indeed opened on the lightning network.
    ///         Once a channel is confirmed, the submitter of the channel info becomes eligible for collecting rewards as long
    ///         as the channel is kept open on the lightning network. In case this channel is opened as a result of
    ///         verification of a lightning node, the node gets also marked as "verified".
    /// @dev    This is only called by the validation mechanism once the validators have reached the consensus on the
    ///         information provided below.
    /// @param  channelIndex index/id of the channel submission as registered in this contract.
    /// @param  _channelCapacitySat The capacity of the channel expressed in satoshi.
    /// @param  channelId Id of the channel as registered on the lightning network.
    /// @param  node1PublicKey The public key of the first node in the channel.
    /// @param  node2PublicKey The public key of the second node in the channel.
    function confirmChannelOpening(uint256 channelIndex, uint256 _channelCapacitySat,
        uint256 channelId, string memory node1PublicKey, string memory node2PublicKey) external override nonReentrant {
        _onlyAggregator();
        require(channelIndex > 0, "ERR_CHANNEL_NOT_FOUND");
        require(_channelCapacitySat > 0, "ERR_EMPTY");

        LightningChannel storage channel = channels[channelIndex];
        require(channel.status == 0, "ERR_WRONG_STATE");
        require(confirmedChannelIndexPerId[channel.channelPoint] == 0, "ERR_DUPLICATE");

        NodeInfo memory nodeInfo = NodeInfo(0, "0", "0");
        if (nodeIndexPerPubKey[node1PublicKey][channel.to] > 0) {
            nodeInfo.nodeIndex = nodeIndexPerPubKey[node1PublicKey][channel.to];
            nodeInfo.ownerPublicKey = node1PublicKey;
            nodeInfo.validatorPublicKey = node2PublicKey;
        } else {
            if (nodeIndexPerPubKey[node2PublicKey][channel.to] > 0) {
                nodeInfo.nodeIndex = nodeIndexPerPubKey[node2PublicKey][channel.to];
                nodeInfo.ownerPublicKey = node2PublicKey;
                nodeInfo.validatorPublicKey = node1PublicKey;
            }
        }

        // check if the channel matches data in smart contracts
        require(nodeInfo.nodeIndex > 0, "ERR_NODE_NOT_FOUND");
        LightningNode storage node = nodes[nodeInfo.nodeIndex];
        require(stringsEqual(node.publicKey, nodeInfo.ownerPublicKey), "ERR_WRONG_STATE");
        require(node.to == channel.to, "ERR_NODE_CHANNEL_MATCH");

        if (node.status == 0) {
            // verify the node
            if (node.capacity == _channelCapacitySat) {
                node.status = 1;
                node.verifiedDate = _blockNumber();
                emit LightningNodeVerified(node.to, node.publicKey, nodeInfo.nodeIndex);
            }
        }

        require(node.status == 1, "ERR_WRONG_STATE");

        // reserve the amount in the escrow
        channel.id = channelId;
        channel.status = 1;
        channel.capacity = _channelCapacitySat;
        channel.confirmedDate = _blockNumber();
        channel.blockNumber = contractRegistry.validatorElectionContract().latestElectionBlock();
        channelRewardStart[channel.id] = _blockNumber();
        confirmedChannelIndexPerId[channel.channelPoint] = channelIndex;

        channelStatusCount[0]--;
        channelStatusCount[1]++;

        uint256 potentialTreasuryRewardAmount = 0;

        IPlennyOcean plennyOcean = contractRegistry.oceanContract();
        uint256 capacityRequestIndex = plennyOcean.capacityRequestPerChannel(channel.channelPoint);
        if (capacityRequestIndex > 0) {
            (uint256 capacity,,,,,, string memory channelPoint,) = plennyOcean.capacityRequests(capacityRequestIndex);
            if (stringsEqual(channelPoint, channel.channelPoint)) {
                potentialTreasuryRewardAmount = _calculatePotentialReward(_channelCapacitySat, true);
                channel.rewardAmount = potentialTreasuryRewardAmount;
                //increment total inbound capacity
                totalInboundCapacity += capacity;
                // process the request
                plennyOcean.processCapacityRequest(capacityRequestIndex);
            }
        } else {
            potentialTreasuryRewardAmount = _calculatePotentialReward(_channelCapacitySat, false);
            channel.rewardAmount = potentialTreasuryRewardAmount;

            IPlennyDappFactory factory = contractRegistry.factoryContract();
            (,uint256 validatorNodeIndex,,,,,,) = factory.validators(factory.validatorIndexPerAddress(channel.oracleAddress));
            require(stringsEqual(nodeInfo.validatorPublicKey, nodes[validatorNodeIndex].publicKey), "ERR_WRONG_STATE");
            totalOutboundCapacity += channel.capacity;
        }

        emit LightningChannelOpeningConfirmed(channel.to, potentialTreasuryRewardAmount, nodeInfo.ownerPublicKey, nodeInfo.validatorPublicKey, channelIndex, _blockNumber());
    }

    /// @notice Marks that a previously opened channel on the lightning network has been closed.
    /// @dev    This is only called by the validation mechanism once the validators have reached the consensus that
    ///         the channel has been indeed closed on the lightning network.
    /// @param  channelIndex index/id of the channel submission as registered in this contract.
    function closeChannel(uint256 channelIndex) external override nonReentrant {
        _onlyAggregator();
        require(channelIndex > 0, "ERR_EMPTY");

        LightningChannel storage channel = channels[channelIndex];
        require(channel.status == 1, "ERR_WRONG_STATE");

        channel.status = 2;
        channel.closureDate = _blockNumber();
        channelStatusCount[1]--;

        IPlennyOcean ocean = contractRegistry.oceanContract();
        uint256 capacityRequestIndex = ocean.capacityRequestPerChannel(channel.channelPoint);
        if (ocean.capacityRequestsCount() > 0) {
            totalInboundCapacity -= channel.capacity;
            (,,,,,, string memory channelPoint,) = ocean.capacityRequests(capacityRequestIndex);
            if (stringsEqual(channelPoint, channel.channelPoint)) {
                ocean.closeCapacityRequest(capacityRequestIndex, channel.id, channel.confirmedDate);
            }
        } else {
            totalOutboundCapacity -= channel.capacity;
        }

        _collectChannelRewardInternal(channel);

        emit LightningChannelClosed(channelIndex);
    }

    /// @notice Batch collect of all pending rewards for all the channels opened by the sender.
    /// @param  channelIndex indexes/ids of the channel submissions as registered in this contract.
    function claimAllChannelsReward(uint256 [] calldata channelIndex) external nonReentrant {
        for (uint256 i = 0; i < channelIndex.length; i++) {
            _collectChannelReward(channelIndex[i]);
        }
    }

    /// @notice Collects pending rewards only for the provided channel opened by the sender.
    /// @param  channelIndex index/id of the channel submission as registered in this contract.
    function collectChannelReward(uint256 channelIndex) external nonReentrant {
        _collectChannelReward(channelIndex);
    }

    /// @notice Set the channel threshold (in satoshi) for which a reward is given.
    /// @dev    Only the owner of the contract can set this.
    /// @param  threshold channel threshold (in satoshi)
    function setChannelRewardThreshold(uint256 threshold) external onlyOwner {
        require(threshold > 20000 && threshold < 16000000, "ERR_INVALID_VALUE");
        channelRewardThreshold = threshold;
    }

    /// @notice Gets the number of opened channels as registered in this contract.
    /// @return uint256 opened channels count
    function getChannelsCount() external view returns (uint256){
        return channelStatusCount[1];
    }

    /// @notice Gets all the submitted nodes for the given address.
    /// @param  addr Address to check for
    /// @return array indexes of all the nodes that belong to the address
    function getNodesPerAddress(address addr) external view returns (uint256[] memory){
        return nodesPerAddress[addr];
    }

    /// @notice Gets all the submitted channels for the given address.
    /// @param  addr Address to check for
    /// @return array indexes of all the channels that belong to the address
    function getChannelsPerAddress(address addr) external view returns (uint256[] memory){
        return channelsPerAddress[addr];
    }

    /// @notice Calculates the potential reward for the given channel capacity. If the channel is opened through the
    ///         ocean/marketplace the reward is increased.
    /// @param  capacity capacity of the channel
    /// @param  marketplace if the reward comes as a result of marketplace action.
    /// @return potentialReward channel reward
    function _calculatePotentialReward(uint256 capacity, bool marketplace) public view returns (uint256 potentialReward){
        uint256 treasuryBalance = contractRegistry.plennyTokenContract().balanceOf(contractRegistry.getAddress("PlennyTreasury"));

        IPlennyDappFactory factory = contractRegistry.factoryContract();

        return capacity.calculateReward(
            marketplace,
            channelRewardThreshold,
            factory.makersFixedRewardAmount(),
            factory.makersRewardPercentage(),
            factory.capacityFixedRewardAmount(),
            factory.capacityRewardPercentage(),
            treasuryBalance);
    }


    /// @notice Check string equality
    /// @param  a first string
    /// @param  b second string
    /// @return bool true/false
    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    /// @notice Only oracle consensus validators
    function _onlyAggregator() internal view {
        require(contractRegistry.getAddress("PlennyOracleValidator") == msg.sender, "ERR_NON_AGGR");
    }

    /// @notice Only plenny oracle factory
    function _onlyFactory() internal view {
        require(contractRegistry.getAddress("PlennyDappFactory") == msg.sender, "ERR_NOT_FACTORY");
    }

    /// @notice In case the contract is deployed on Arbitrum, get the Arbitrum block number.
    /// @return uint256 L1 block number or L2 block number
    function _altBlockNumber() internal view returns (uint256){
        uint chainId = getChainId();
        if (chainId == 42161 || chainId == 421611) {
            return ArbSys(address(100)).arbBlockNumber();
        } else {
            return block.number;
        }
    }

    /// @notice id of the network the contract is deployed to.
    /// @return chainId Network id
    function getChainId() internal pure returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    /// @notice Collects a reward for a given channel
    /// @param  channel opened/active channel
    function _collectChannelRewardInternal(LightningChannel storage channel) private {
        address payable _to = channel.to;

        IPlennyDappFactory factory = contractRegistry.factoryContract();
        uint256 _reward = _blockNumber() - channel.confirmedDate > factory.userChannelRewardPeriod()
        ? channel.rewardAmount.mul(factory.userChannelReward()).mul(_blockNumber() - channelRewardStart[channel.id])
            .div(factory.userChannelRewardPeriod()).div(10000) : 0;
        if (_reward > channel.rewardAmount) {
            _reward = channel.rewardAmount;
        }

        uint256 rewardFee = _reward.mul(factory.userChannelRewardFee()).div(100).div(100);

        totalTimeReward += _reward;
        channel.rewardAmount -= _reward;
        channelRewardStart[channel.id] = _blockNumber();
        emit RewardReleased(_to, _reward);

        IPlennyTreasury treasury = contractRegistry.treasuryContract();

        require(treasury.approve(address(this), rewardFee), "failed");
        contractRegistry.plennyTokenContract().safeTransferFrom(address(treasury),
            contractRegistry.getAddress("PlennyRePLENishment"), rewardFee);

        require(treasury.approve(contractRegistry.getAddress("PlennyCoordinator"), _reward - rewardFee), "failed");
        contractRegistry.plennyTokenContract().safeTransferFrom(address(treasury), _to, _reward - rewardFee);
    }

    /// @notice Collects a reward for a given index/id of a channel
    /// @param  channelIndex channel index/id
    function _collectChannelReward(uint256 channelIndex) private {
        require(channelIndex > 0, "ERR_EMPTY");

        LightningChannel storage channel = channels[channelIndex];
        require(channel.status == 1, "ERR_WRONG_STATE");

        IPlennyOcean ocean = contractRegistry.oceanContract();

        uint256 capacityRequestIndex = ocean.capacityRequestPerChannel(channel.channelPoint);
        if (ocean.capacityRequestsCount() > 0) {
            (,,,,,, string memory channelPoint,) = ocean.capacityRequests(capacityRequestIndex);
            if (stringsEqual(channelPoint, channel.channelPoint)) {
                ocean.collectCapacityRequestReward(capacityRequestIndex, channel.id, channel.confirmedDate);
            }
        }

        _collectChannelRewardInternal(channel);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IContractRegistry.sol";

/// @title  Base Plenny upgradeable contract.
/// @notice Used by all Plenny contracts, except PlennyERC20, to allow upgradeable contracts.
abstract contract PlennyBaseUpgradableV2 is AccessControlUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {

    /// @notice Plenny contract addresses registry
    IContractRegistry public contractRegistry;

    /// @notice Initializes the contract. Can be called only once.
    /// @dev    Upgradable contracts does not have a constructor, so this method is its replacement.
    /// @param  _registry Plenny contracts registry
    function __plennyBaseInit(address _registry) internal initializer {
        require(_registry != address(0x0), "ERR_REG_EMPTY");
        contractRegistry = IContractRegistry(_registry);

        AccessControlUpgradeable.__AccessControl_init();
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Returns current block number
    /// @return uint256 block number
    function _blockNumber() internal view returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./PlennyBaseUpgradableV2.sol";

/// @title  Base abstract pausable contract.
/// @notice Used by all Plenny contracts, except PlennyERC20, to allow pausing of the contracts by addresses having PAUSER role.
/// @dev    Abstract contract that any Plenny contract extends from for providing pausing features.
abstract contract PlennyBasePausableV2 is PlennyBaseUpgradableV2, PausableUpgradeable {

    /// @notice PAUSER role constant
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev    Checks if the sender has PAUSER role.
    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERR_NOT_PAUSER");
        _;
    }

    /// @notice Assigns PAUSER role for the given address.
    /// @dev    Only a pauser can assign more PAUSER roles.
    /// @param  account Address to assign PAUSER role to
    function addPauser(address account) external onlyPauser {
        _setupRole(PAUSER_ROLE, account);
    }

    /// @notice Renounces PAUSER role.
    /// @dev    The users renounce the PAUSER roles themselves.
    function renouncePauser() external {
        revokeRole(PAUSER_ROLE, _msgSender());
    }

    /// @notice Pauses the contract if not already paused.
    /// @dev    Only addresses with PAUSER role can pause the contract
    function pause() external onlyPauser whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract if already paused.
    /// @dev    Only addresses with PAUSER role can unpause
    function unpause() external onlyPauser whenPaused {
        _unpause();
    }

    /// @notice Initializes the contract along with the PAUSER role.
    /// @param  _registry Contract registry
    function __plennyBasePausableInit(address _registry) internal initializer {
        PlennyBaseUpgradableV2.__plennyBaseInit(_registry);
        PausableUpgradeable.__Pausable_init();
        _setupRole(PAUSER_ROLE, _msgSender());
    }
}