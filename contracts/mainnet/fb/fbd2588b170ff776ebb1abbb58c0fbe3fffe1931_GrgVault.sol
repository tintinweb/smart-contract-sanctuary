/*

 Copyright 2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

/// @title Drago Interface - Allows interaction with the Drago contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface DragoFace {

    struct Transaction {
        bytes assembledData;
    }

    /*
     * CORE FUNCTIONS
     */
    //function() external payable;
    function buyDrago() external payable returns (bool success);
    function buyDragoOnBehalf(address _hodler) external payable returns (bool success);
    function sellDrago(uint256 _amount) external returns (bool success);
    function setPrices(uint256 _newSellPrice, uint256 _newBuyPrice, uint256 _signaturevaliduntilBlock, bytes32 _hash, bytes calldata _signedData) external;
    function changeMinPeriod(uint32 _minPeriod) external;
    function changeRatio(uint256 _ratio) external;
    function setTransactionFee(uint256 _transactionFee) external;
    function changeFeeCollector(address _feeCollector) external;
    function changeDragoDao(address _dragoDao) external;
    function enforceKyc(bool _enforced, address _kycProvider) external;
    function setAllowance(address _tokenTransferProxy, address _token, uint256 _amount) external;
    function setMultipleAllowances(address _tokenTransferProxy, address[] calldata _tokens, uint256[] calldata _amounts) external;
    function operateOnExchange(address _exchange, Transaction calldata transaction) external returns (bool success);
    function batchOperateOnExchange(address _exchange, Transaction[] calldata transactions) external;

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    function balanceOf(address _who) external view returns (uint256);
    function getEventful() external view returns (address);
    function getData() external view returns (string memory name, string memory symbol, uint256 sellPrice, uint256 buyPrice);
    function calcSharePrice() external view returns (uint256);
    function getAdminData() external view returns (address, address feeCollector, address dragoDao, uint256 ratio, uint256 transactionFee, uint32 minPeriod);
    function getKycProvider() external view returns (address);
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bool isValid);
    function totalSupply() external view returns (uint256);
}

/// @title Drago Registry Interface - Allows external interaction with Drago Registry.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface DragoRegistryFace {

    /*
     * CORE FUNCTIONS
     */
    function register(address _drago, string calldata _name, string calldata _symbol, uint256 _dragoId, address _owner) external payable returns (bool);
    function unregister(uint256 _id) external;
    function setMeta(uint256 _id, bytes32 _key, bytes32 _value) external;
    function addGroup(address _group) external;
    function setFee(uint256 _fee) external;
    function updateOwner(uint256 _id) external;
    function updateOwners(uint256[] calldata _id) external;
    function upgrade(address _newAddress) external payable; //payable as there is a transfer of value, otherwise opcode might throw an error
    function setUpgraded(uint256 _version) external;
    function drain() external;

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    function dragoCount() external view returns (uint256);
    function fromId(uint256 _id) external view returns (address drago, string memory name, string memory symbol, uint256 dragoId, address owner, address group);
    function fromAddress(address _drago) external view returns (uint256 id, string memory name, string memory symbol, uint256 dragoId, address owner, address group);
    function fromName(string calldata _name) external view returns (uint256 id, address drago, string memory symbol, uint256 dragoId, address owner, address group);
    function getNameFromAddress(address _pool) external view returns (string memory);
    function getSymbolFromAddress(address _pool) external view returns (string memory);
    function meta(uint256 _id, bytes32 _key) external view returns (bytes32);
    function getGroups() external view returns (address[] memory);
    function getFee() external view returns (uint256);
}

/// @title Drago Data Helper - Allows to query multiple data of a drago at once.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract HGetDragoData {

    struct DragoData {
        string name;
        string symbol;
        uint256 sellPrice;
        uint256 buyPrice;
        address owner;
        address feeCollector;
        address dragoDao;
        uint256 ratio;
        uint256 transactionFee;
        uint256 totalSupply;
        uint256 ethBalance;
        uint32 minPeriod;
        uint256 id;
        address drago;
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Returns structs of infos on a drago from its ID.
    /// @param _dragoRegistry Address of the pools registry.
    /// @param _dragoId Number of the target drago ID.
    /// @return dragoData Structs of data.
    function queryDataFromId(
        address _dragoRegistry,
        uint256 _dragoId)
        external
        view
        returns (
            DragoData memory dragoData
        )
    {
        address drago;
        DragoRegistryFace dragoRegistryInstance = DragoRegistryFace(_dragoRegistry);
        (drago, , , , , ) = dragoRegistryInstance.fromId(_dragoId);
        (
            dragoData
        ) = queryDataInternal(drago);
        dragoData.id = _dragoId;
        dragoData.drago = drago;
    }

    /// @dev Returns structs of infos on a drago from its address.
    /// @param _dragoRegistry Address of the pools registry.
    /// @param _dragoAddress Array of addresses of the target drago.
    /// @return dragoData Arrays of structs of data.
    function queryDataFromAddress(
        address _dragoRegistry,
        address _dragoAddress)
        external
        view
        returns (
            DragoData memory dragoData
        )
    {
        uint256 dragoId;
        DragoRegistryFace dragoRegistryInstance = DragoRegistryFace(_dragoRegistry);
        (dragoId, , , , , ) = dragoRegistryInstance.fromAddress(_dragoAddress);
        (
            dragoData
        ) = queryDataInternal(_dragoAddress);
        dragoData.id = dragoId;
        dragoData.drago = _dragoAddress;
    }

    /// @dev Returns structs of infos on a drago from its ID.
    /// @param _dragoRegistry Address of the drago registry.
    /// @param _dragoIds Array of IDs of the target dragos.
    /// @return Arrays of structs of data and related address of a drago.
    function queryMultiDataFromId(
        address _dragoRegistry,
        uint256[] calldata _dragoIds)
        external
        view
        returns (
            DragoData[] memory
        )
    {
        uint256 length = _dragoIds.length;
        DragoData[] memory dragoData = new DragoData[](length);
        address[] memory dragos = new address[](length);
        address dragoRegistry = _dragoRegistry;
        DragoRegistryFace dragoRegistryInstance = DragoRegistryFace(dragoRegistry);
        for (uint256 i = 0; i < length; i++) {
            uint256 dragoId = _dragoIds[i];
            (dragos[i], , , , , ) = dragoRegistryInstance.fromId(dragoId);
            (
                dragoData[i]
            ) = queryDataInternal(dragos[i]);
            dragoData[i].id = dragoId;
            dragoData[i].drago = dragos[i];
        }
        return(dragoData);
    }

    /// @dev Returns structs of infos on a drago from its address.
    /// @param _dragoRegistry Address of the pools registry.
    /// @param _dragoAddresses Array of addresses of the target dragos.
    /// @return Arrays of structs of data and related address of a drago.
    function queryMultiDataFromAddress(
        address _dragoRegistry,
        address[] calldata _dragoAddresses)
        external
        view
        returns (
            DragoData[] memory
        )
    {
        uint256 length = _dragoAddresses.length;
        DragoData[] memory dragoData = new DragoData[](length);
        uint256[] memory dragoIds = new uint256[](length);
        address[] memory dragos = _dragoAddresses;
        address dragoRegistry = _dragoRegistry;
        DragoRegistryFace dragoRegistryInstance = DragoRegistryFace(dragoRegistry);
        for (uint256 i = 0; i < length; i++) {
            address dragoAddress = dragos[i];
            (dragoIds[i], , , , , ) = dragoRegistryInstance.fromAddress(dragoAddress);
            (
                dragoData[i]
            ) = queryDataInternal(dragos[i]);
            dragoData[i].id = dragoIds[i];
            dragoData[i].drago = dragos[i];
        }
        return(dragoData);
    }

    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev Returns structs of infos on a drago.
    /// @param _drago Array of addresses of the target dragos.
    /// @return dragoData Structs of data.
    function queryDataInternal(
        address _drago)
        internal
        view
        returns (
            DragoData memory dragoData
        )
    {
        DragoFace dragoInstance = DragoFace(_drago);
        (
            dragoData.name,
            dragoData.symbol,
            dragoData.sellPrice,
            dragoData.buyPrice
        ) = dragoInstance.getData();
        (
            dragoData.owner,
            dragoData.feeCollector,
            dragoData.dragoDao,
            dragoData.ratio,
            dragoData.transactionFee,
            dragoData.minPeriod
        ) = dragoInstance.getAdminData();
        dragoData.totalSupply = dragoInstance.totalSupply();
        dragoData.ethBalance = address(_drago).balance;
    }
}

// SPDX-License-Identifier: Apache 2.0

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import { SafeMath } from "../../utils/SafeMath/SafeMath.sol";
import { InflationFace } from "./InflationFace.sol";
import { RigoTokenFace } from "../RigoToken/RigoTokenFace.sol";
import { IStaking } from "../../staking/interfaces/IStaking.sol";


/// @title Inflation - Allows ProofOfPerformance to mint tokens.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract Inflation is
    SafeMath,
    InflationFace
{
    address public immutable RIGO_TOKEN_ADDRESS;
    address public immutable STAKING_PROXY_ADDRESS;

    uint32 internal immutable PPM_DENOMINATOR = 10**6; // 100% in parts-per-million
    uint256 internal immutable ANNUAL_INFLATION_RATE = 2 * 10**4; // 2% annual inflation

    uint256 public slot;
    uint256 public epochLength = 14 days;

    uint256 private epochEndTime;

    modifier onlyStakingProxy {
        _assertCallerIsStakingProxy();
        _;
    }

    constructor(
        address _rigoTokenAddress,
        address _stakingProxyAddress
    ) {
        RIGO_TOKEN_ADDRESS = _rigoTokenAddress;
        STAKING_PROXY_ADDRESS = _stakingProxyAddress;
    }

    /*
     * CORE FUNCTIONS
     */
    /// @dev Allows staking proxy to mint rewards.
    /// @return mintedInflation Number of allocated tokens.
    function mintInflation()
        external
        override
        onlyStakingProxy
        returns (uint256 mintedInflation)
    {
        //TODO: test
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < epochEndTime) {
            revert("NOT_ENOUGH_TIME_ERROR");
        }

        (uint256 epochDurationInSeconds, , , , ) = IStaking(STAKING_PROXY_ADDRESS).getParams();

        // sanity check for epoch length queried from staking
        if (epochLength != epochDurationInSeconds) {
            if (epochDurationInSeconds < 5 days || epochDurationInSeconds > 90 days) {
                revert("STAKING_EPOCH_TIME_ANOMALY_DETECTED_ERROR");
            } else {
                epochLength = epochDurationInSeconds;
            }
        }

        //TODO: test
        uint256 epochInflation = getEpochInflation();

        // solhint-disable-next-line not-rely-on-time
        epochEndTime = block.timestamp + epochLength;
        slot = safeAdd(slot, 1);

        // TODO: test
        // mint rewards
        RigoTokenFace(RIGO_TOKEN_ADDRESS).mintToken(
            STAKING_PROXY_ADDRESS,
            epochInflation
        );
        return (mintedInflation = epochInflation);
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Returns whether an epoch has ended.
    /// @return Bool the epoch has ended.
    function epochEnded()
        external
        override
        view
        returns (bool)
    {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= epochEndTime) {
            return true;
        } else return false;
    }

    /// @dev Returns how long until next claim.
    /// @return Number in seconds.
    function timeUntilNextClaim()
        external
        view
        override
        returns (uint256)
    {
        /* solhint-disable not-rely-on-time */
        if (block.timestamp < epochEndTime) {
            return (epochEndTime - block.timestamp);
        } else return (uint256(0));
        /* solhint-disable not-rely-on-time */
    }

    /// @dev Returns the epoch inflation.
    /// @return Value of units of GRG minted in an epoch.
    function getEpochInflation()
        public
        view
        override
        returns (uint256)
    {
        // TODO: test
        return safeDiv(
            safeMul(
                RigoTokenFace(RIGO_TOKEN_ADDRESS).totalSupply(),
                ANNUAL_INFLATION_RATE * epochLength
            ),
            (PPM_DENOMINATOR * 365 days)
        );
    }

    /*
     * INTERNAL METHODS
     */
    /// @dev Asserts that the caller is the Staking Proxy.
    function _assertCallerIsStakingProxy()
        internal
        view
    {
        if (msg.sender != STAKING_PROXY_ADDRESS) {
            revert("CALLER_NOT_STAKING_PROXY_ERROR");
        }
    }
}

pragma solidity >=0.4.22 <0.8.0;

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.4.22 <0.8.0;

/// @title Inflation Interface - Allows interaction with the Inflation contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface InflationFace {

    /*
     * CORE FUNCTIONS
     */
    /// @dev Allows staking proxy to mint rewards.
    /// @return mintedInflation Number of allocated tokens.
    function mintInflation() external returns (uint256 mintedInflation);

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Returns whether an epoch has ended.
    /// @return Bool the epoch has ended.
    function epochEnded() external view returns (bool);
    
    /// @dev Returns how long until next claim.
    /// @return Number in seconds.
    function timeUntilNextClaim() external view returns (uint256);
    
    /// @dev Returns the epoch inflation.
    /// @return Value of units of GRG minted in an epoch.
    function getEpochInflation() external view returns (uint256);
}

/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.5.0;

/// @title Rigo Token Interface - Allows interaction with the Rigo token.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface RigoTokenFace {

    function minter() external view returns (address);

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value)
        external
        returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address _spender, uint256 _value)
        external
        returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply()
        external
        view
        returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address _owner)
        external
        view
        returns (uint256);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function mintToken(address _recipient, uint256 _amount) external;
    function changeMintingAddress(address _newAddress) external;
    function changeRigoblockAddress(address _newAddress) external;
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../rigoToken/RigoToken/RigoTokenFace.sol";
import "../../protocol/DragoRegistry/IDragoRegistry.sol";
import "./IStructs.sol";
import "./IGrgVault.sol";


interface IStaking {

    /// @dev Adds a new proof_of_performance address.
    /// @param addr Address of proof_of_performance contract to add.
    function addPopAddress(address addr)
        external;
        
    /// @dev Create a new staking pool. The sender will be the staking pal of this pool.
    /// Note that a staking pal must be payable.
    /// @param rigoblockPoolAddress Adds rigoblock pool to the created staking pool for convenience if non-null.
    /// @return poolId The unique pool id generated for this pool.
    function createStakingPool(address rigoblockPoolAddress)
        external
        returns (bytes32 poolId);
    
    /// @dev Allows the operator to update the staking pal address.
    /// @param poolId Unique id of pool.
    /// @param newStakingPalAddress Address of the new staking pal.
    function setStakingPalAddress(bytes32 poolId, address newStakingPalAddress)
        external;

    /// @dev Decreases the operator share for the given pool (i.e. increases pool rewards for members).
    /// @param poolId Unique Id of pool.
    /// @param newOperatorShare The newly decreased percentage of any rewards owned by the operator.
    function decreaseStakingPoolOperatorShare(bytes32 poolId, uint32 newOperatorShare)
        external;

    /// @dev Begins a new epoch, preparing the prior one for finalization.
    ///      Throws if not enough time has passed between epochs or if the
    ///      previous epoch was not fully finalized.
    /// @return numPoolsToFinalize The number of unfinalized pools.
    function endEpoch()
        external
        returns (uint256);

    /// @dev Instantly finalizes a single pool that earned rewards in the previous
    ///      epoch, crediting it rewards for members and withdrawing operator's
    ///      rewards as WETH. This can be called by internal functions that need
    ///      to finalize a pool immediately. Does nothing if the pool is already
    ///      finalized or did not earn rewards in the previous epoch.
    /// @param poolId The pool ID to finalize.
    function finalizePool(bytes32 poolId)
        external;

    /// @dev Initialize storage owned by this contract.
    ///      This function should not be called directly.
    ///      The StakingProxy contract will call it in `attachStakingContract()`.
    function init()
        external;

    /// @dev Allows caller to join a staking pool as a rigoblock pool id subaccount.
    /// @param stakingPoolId Unique id of staking pool.
    /// @param rigoblockPoolAccount Address of subaccount to be added to staking pool.
    function joinStakingPoolAsRbPoolAccount(
        bytes32 stakingPoolId,
        address rigoblockPoolAccount)
        external;

    /// @dev Moves stake between statuses: 'undelegated' or 'delegated'.
    ///      Delegated stake can also be moved between pools.
    ///      This change comes into effect next epoch.
    /// @param from status to move stake out of.
    /// @param to status to move stake into.
    /// @param amount of stake to move.
    function moveStake(
        IStructs.StakeInfo calldata from,
        IStructs.StakeInfo calldata to,
        uint256 amount
    )
        external;
        
    /// @dev Credits the value of a pool's pop reward.
    ///      Only a known RigoBlock pop can call this method. See
    ///      (MixinPopManager).
    /// @param poolAccount The address of the rigoblock pool account.
    /// @param popReward The pop reward.
    function creditPopReward(
        address poolAccount,
        uint256 popReward
    )
        external
        payable;

    /// @dev Removes an existing proof_of_performance address.
    /// @param addr Address of proof_of_performance contract to remove.
    function removePopAddress(address addr)
        external;

    /// @dev Set all configurable parameters at once.
    /// @param _epochDurationInSeconds Minimum seconds between epochs.
    /// @param _rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @param _minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @param _cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @param _cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    function setParams(
        uint256 _epochDurationInSeconds,
        uint32 _rewardDelegatedStakeWeight,
        uint256 _minimumPoolStake,
        uint32 _cobbDouglasAlphaNumerator,
        uint32 _cobbDouglasAlphaDenominator
    )
        external;

    /// @dev Stake GRG tokens. Tokens are deposited into the GRG Vault.
    ///      Unstake to retrieve the GRG. Stake is in the 'Active' status.
    /// @param amount of GRG to stake.
    function stake(uint256 amount)
        external;

    /// @dev Unstake. Tokens are withdrawn from the GRG Vault and returned to
    ///      the staker. Stake must be in the 'undelegated' status in both the
    ///      current and next epoch in order to be unstaked.
    /// @param amount of GRG to unstake.
    function unstake(uint256 amount)
        external;

    /// @dev Withdraws the caller's WETH rewards that have accumulated
    ///      until the last epoch.
    /// @param poolId Unique id of pool.
    function withdrawDelegatorRewards(bytes32 poolId)
        external;

    /// @dev Computes the reward balance in ETH of a specific member of a pool.
    /// @param poolId Unique id of pool.
    /// @param member The member of the pool.
    /// @return reward Balance in ETH.
    function computeRewardBalanceOfDelegator(bytes32 poolId, address member)
        external
        view
        returns (uint256 reward);

    /// @dev Computes the reward balance in ETH of the operator of a pool.
    /// @param poolId Unique id of pool.
    /// @return reward Balance in ETH.
    function computeRewardBalanceOfOperator(bytes32 poolId)
        external
        view
        returns (uint256 reward);

    /// @dev Returns the earliest end time in seconds of this epoch.
    ///      The next epoch can begin once this time is reached.
    ///      Epoch period = [startTimeInSeconds..endTimeInSeconds)
    /// @return Time in seconds.
    function getCurrentEpochEarliestEndTimeInSeconds()
        external
        view
        returns (uint256);

    /// @dev Gets global stake for a given status.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Global stake for given status.
    function getGlobalStakeByStatus(IStructs.StakeStatus stakeStatus)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @dev Gets an owner's stake balances by status.
    /// @param staker Owner of stake.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Owner's stake balances for given status.
    function getOwnerStakeByStatus(
        address staker,
        IStructs.StakeStatus stakeStatus
    )
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @dev Returns the total stake for a given staker.
    /// @param staker of stake.
    /// @return Total GRG staked by `staker`.
    function getTotalStake(address staker)
        external
        view
        returns (uint256);

    /// @dev Retrieves all configurable parameter values.
    /// @return _epochDurationInSeconds Minimum seconds between epochs.
    /// @return _rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @return _minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @return _cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @return _cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    function getParams()
        external
        view
        returns (
            uint256 _epochDurationInSeconds,
            uint32 _rewardDelegatedStakeWeight,
            uint256 _minimumPoolStake,
            uint32 _cobbDouglasAlphaNumerator,
            uint32 _cobbDouglasAlphaDenominator
        );

    /// @param staker of stake.
    /// @param poolId Unique Id of pool.
    /// @return balance Stake delegated to pool by staker.
    function getStakeDelegatedToPoolByOwner(address staker, bytes32 poolId)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @dev Returns a staking pool
    /// @param poolId Unique id of pool.
    function getStakingPool(bytes32 poolId)
        external
        view
        returns (IStructs.Pool memory);

    /// @dev Get stats on a staking pool in this epoch.
    /// @param poolId Pool Id to query.
    /// @return PoolStats struct for pool id.
    function getStakingPoolStatsThisEpoch(bytes32 poolId)
        external
        view
        returns (IStructs.PoolStats memory);

    /// @dev Returns the total stake delegated to a specific staking pool,
    ///      across all members.
    /// @param poolId Unique Id of pool.
    /// @return balance Total stake delegated to pool.
    function getTotalStakeDelegatedToPool(bytes32 poolId)
        external
        view
        returns (IStructs.StoredBalance memory balance);

    /// @dev An overridable way to access the deployed GRG contract.
    ///      Must be view to allow overrides to access state.
    /// @return grgContract The GRG contract instance.
    function getGrgContract()
        external
        view
        returns (RigoTokenFace grgContract);

    /// @dev An overridable way to access the deployed dragoRegistry.
    ///      Must be view to allow overrides to access state.
    /// @return dragoRegistry The dragoRegistry contract.
    function getDragoRegistry()
        external
        view
        returns (IDragoRegistry dragoRegistry);

    /// @dev An overridable way to access the deployed grgVault.
    ///      Must be view to allow overrides to access state.
    /// @return grgVault The grgVault contract.
    function getGrgVault()
        external
        view
        returns (IGrgVault grgVault);
}

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.5.0 <0.8.0;

/// @title Drago Registry Interface - Allows external interaction with Drago Registry.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IDragoRegistry {

    /*
     * CORE FUNCTIONS
     */
    function register(address _drago, string calldata _name, string calldata _symbol, uint256 _dragoId, address _owner) external payable returns (bool);
    function unregister(uint256 _id) external;
    function setMeta(uint256 _id, bytes32 _key, bytes32 _value) external;
    function addGroup(address _group) external;
    function setFee(uint256 _fee) external;
    function updateOwner(uint256 _id) external;
    function updateOwners(uint256[] calldata _id) external;
    function upgrade(address _newAddress) external payable; //payable as there is a transfer of value, otherwise opcode might throw an error
    function setUpgraded(uint256 _version) external;
    function drain() external;

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    function dragoCount() external view returns (uint256);
    function fromId(uint256 _id) external view returns (address drago, string memory name, string memory symbol, uint256 dragoId, address owner, address group);
    function fromAddress(address _drago) external view returns (uint256 id, string memory name, string memory symbol, uint256 dragoId, address owner, address group);
    function fromName(string calldata _name) external view returns (uint256 id, address drago, string memory symbol, uint256 dragoId, address owner, address group);
    function getNameFromAddress(address _pool) external view returns (string memory);
    function getSymbolFromAddress(address _pool) external view returns (string memory);
    function meta(uint256 _id, bytes32 _key) external view returns (bytes32);
    function getGroups() external view returns (address[] memory);
    function getFee() external view returns (uint256);
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;


interface IStructs {

    /// @dev Stats for a pool that earned rewards.
    /// @param feesCollected Fees collected in ETH by this pool.
    /// @param weightedStake Amount of weighted stake in the pool.
    /// @param membersStake Amount of non-operator stake in the pool.
    struct PoolStats {
        uint256 feesCollected;
        uint256 weightedStake;
        uint256 membersStake;
    }

    /// @dev Holds stats aggregated across a set of pools.
    /// @param rewardsAvailable Rewards (ETH) available to the epoch
    ///        being finalized (the previous epoch). This is simply the balance
    ///        of the contract at the end of the epoch.
    /// @param numPoolsToFinalize The number of pools that have yet to be finalized through `finalizePools()`.
    /// @param totalFeesCollected The total fees collected for the epoch being finalized.
    /// @param totalWeightedStake The total fees collected for the epoch being finalized.
    /// @param totalRewardsFinalized Amount of rewards that have been paid during finalization.
    struct AggregatedStats {
        uint256 rewardsAvailable;
        uint256 numPoolsToFinalize;
        uint256 totalFeesCollected;
        uint256 totalWeightedStake;
        uint256 totalRewardsFinalized;
    }

    /// @dev Encapsulates a balance for the current and next epochs.
    /// Note that these balances may be stale if the current epoch
    /// is greater than `currentEpoch`.
    /// @param currentEpoch The current epoch
    /// @param currentEpochBalance Balance in the current epoch.
    /// @param nextEpochBalance Balance in `currentEpoch+1`.
    struct StoredBalance {
        uint64 currentEpoch;
        uint96 currentEpochBalance;
        uint96 nextEpochBalance;
    }

    /// @dev Statuses that stake can exist in.
    ///      Any stake can be (re)delegated effective at the next epoch
    ///      Undelegated stake can be withdrawn if it is available in both the current and next epoch
    enum StakeStatus {
        UNDELEGATED,
        DELEGATED
    }

    /// @dev Info used to describe a status.
    /// @param status Status of the stake.
    /// @param poolId Unique Id of pool. This is set when status=DELEGATED.
    struct StakeInfo {
        StakeStatus status;
        bytes32 poolId;
    }

    /// @dev Struct to represent a fraction.
    /// @param numerator Numerator of fraction.
    /// @param denominator Denominator of fraction.
    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    /// @dev Holds the metadata for a staking pool.
    /// @param operator Operator of the pool.
    /// @param stakingPal Staking pal of the pool.
    /// @param operatorShare Fraction of the total balance owned by the operator, in ppm.
    /// @param stakingPalShare Fraction of the operator reward owned by the staking pal, in ppm.
    struct Pool {
        address operator;
        address stakingPal;
        uint32 operatorShare;
        uint32 stakingPalShare;
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;


interface IGrgVault {

    /// @dev Emmitted whenever a StakingProxy is set in a vault.
    event StakingProxySet(address stakingProxyAddress);

    /// @dev Emitted when the Staking contract is put into Catastrophic Failure Mode
    /// @param sender Address of sender (`msg.sender`)
    event InCatastrophicFailureMode(address sender);

    /// @dev Emitted when Grg Tokens are deposited into the vault.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens deposited.
    event Deposit(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted when Grg Tokens are withdrawn from the vault.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens withdrawn.
    event Withdraw(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted whenever the GRG AssetProxy is set.
    event GrgProxySet(address grgProxyAddress);

    /// @dev Sets the address of the StakingProxy contract.
    /// Note that only the contract staker can call this function.
    /// @param _stakingProxyAddress Address of Staking proxy contract.
    function setStakingProxy(address _stakingProxyAddress)
        external;

    /// @dev Vault enters into Catastrophic Failure Mode.
    /// *** WARNING - ONCE IN CATOSTROPHIC FAILURE MODE, YOU CAN NEVER GO BACK! ***
    /// Note that only the contract staker can call this function.
    function enterCatastrophicFailure()
        external;

    /// @dev Sets the Grg proxy.
    /// Note that only the contract staker can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param grgProxyAddress Address of the RigoBlock Grg Proxy.
    function setGrgProxy(address grgProxyAddress)
        external;

    /// @dev Deposit an `amount` of Grg Tokens from `staker` into the vault.
    /// Note that only the Staking contract can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens to deposit.
    function depositFrom(address staker, uint256 amount)
        external;

    /// @dev Withdraw an `amount` of Grg Tokens to `staker` from the vault.
    /// Note that only the Staking contract can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens to withdraw.
    function withdrawFrom(address staker, uint256 amount)
        external;

    /// @dev Withdraw ALL Grg Tokens to `staker` from the vault.
    /// Note that this can only be called when *in* Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    function withdrawAllFrom(address staker)
        external
        returns (uint256);

    /// @dev Returns the balance in Grg Tokens of the `staker`
    /// @return Balance in Grg.
    function balanceOf(address staker)
        external
        view
        returns (uint256);

    /// @dev Returns the entire balance of Grg tokens in the vault.
    function balanceOfGrgVault()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: Apache 2.0

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity 0.7.4;

import { AuthorityFace } from "../../protocol/authorities/Authority/AuthorityFace.sol";
import { IPool } from "../../utils/Pool/IPool.sol";
import { SafeMath } from "../../utils/SafeMath/SafeMath.sol";
import { ProofOfPerformanceFace } from "./ProofOfPerformanceFace.sol";
import { RigoTokenFace } from "../RigoToken/RigoTokenFace.sol";
import { IDragoRegistry } from "../../protocol/DragoRegistry/IDragoRegistry.sol";
import { IStaking } from "../../staking/interfaces/IStaking.sol";


/// @title Proof of Performance - Controls parameters of inflation.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract ProofOfPerformance is
    SafeMath,
    ProofOfPerformanceFace
{
    address public immutable RIGO_TOKEN_ADDRESS;
    address public immutable STAKING_PROXY_ADDRESS;

    address public dragoRegistryAddress;
    address public rigoblockDaoAddress;
    address public authorityAddress;

    mapping (address => Group) public groupByAddress;
    mapping (uint256 => uint256) private _highWaterMark;

    struct Group {
        uint256 epochReward;
        uint256 rewardRatio;
    }

    modifier onlyRigoblockDao() {
        _assertCallerIsRigoblockDao();
        _;
    }

    modifier onlyStakingProxy() {
        _assertCallerIsStakingProxy();
        _;
    }
    
    modifier isApprovedFactory(address _factory) {
        _assertIsApprovedFactory(_factory);
        _;
    }

    constructor(
        address _rigoTokenAddress,
        address _stakingProxyAddress,
        address _rigoblockDao,
        address _dragoRegistry,
        address _authorityAddress
    ) {
        RIGO_TOKEN_ADDRESS = _rigoTokenAddress;
        STAKING_PROXY_ADDRESS = _stakingProxyAddress;
        rigoblockDaoAddress = _rigoblockDao;
        dragoRegistryAddress = _dragoRegistry;
        authorityAddress = _authorityAddress;
    }

    /// @dev Credits the pop reward to the Staking Proxy contract.
    /// @param poolId Number of the pool Id in registry.
    function creditPopRewardToStakingProxy(
        uint256 poolId
    )
        external
        override
    {
        (address poolAddress, , , , , ) = IDragoRegistry(dragoRegistryAddress).fromId(poolId);

        if (poolAddress == address(0)) {
            return;
        }

        uint256 poolPrice = IPool(poolAddress).calcSharePrice();

        // allow smart contract calls only from pool itself
        if (_isContract(msg.sender)) {
            _assertContractIsPool(poolAddress);
        }

        // TODO: test
        // initialization is not necessary but explicit as to prevent failure in case of a future upgrade
        _initializeHwmIfUninitialized(poolId);

        (uint256 popReward, ) = _proofOfPerformanceInternal(poolId);

        // pop assets component is always positive, therefore we must update the hwm if positive performance
        _updateHwmIfPositivePerformance(poolPrice, poolId);

        IStaking(STAKING_PROXY_ADDRESS).creditPopReward(poolAddress, popReward);
    }

    /// @dev Allows RigoBlock Dao to update the pools registry.
    /// @param newDragoRegistryAddress Address of new registry.
    function setRegistry(address newDragoRegistryAddress)
        external
        override
        onlyRigoblockDao
    {
        dragoRegistryAddress = newDragoRegistryAddress;
    }

    /// @dev Allows RigoBlock Dao to update its address.
    /// @param newRigoblockDaoAddress Address of new dao.
    function setRigoblockDao(address newRigoblockDaoAddress)
        external
        override
        onlyRigoblockDao
    {
        rigoblockDaoAddress = newRigoblockDaoAddress;
    }
    
    /// @dev Allows rigoblock dao to update the authority.
    /// @param newAuthorityAddress Address of the authority.
    function setAuthority(address newAuthorityAddress)
        external
        override
        onlyRigoblockDao
    {
        authorityAddress = newAuthorityAddress;
    }

    /// @dev Allows RigoBlock Dao to set the ratio between assets and performance reward for a group.
    /// @param groupAddress Address of the pool's group.
    /// @param newRatio Value of the new ratio.
    /// @notice onlyRigoblockDao can set ratio.
    function setRatio(
        address groupAddress,
        uint256 newRatio)
        external
        override
        onlyRigoblockDao
    {
        require(
            newRatio <= 10000,
            "RATIO_BIGGER_THAN_10000"
        ); //(from 0 to 10000)
        groupByAddress[groupAddress].rewardRatio = newRatio;
    }
    
    /// @dev Allows rigoblock dao to set the inflation factor for a group.
    /// @param groupAddress Address of the group/factory.
    /// @param inflationFactor Value of the reward factor.
    function setInflationFactor(address groupAddress, uint256 inflationFactor)
        external
        override
        onlyRigoblockDao
        isApprovedFactory(groupAddress)
    {
        groupByAddress[groupAddress].epochReward = inflationFactor;
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Gets data of a pool.
    /// @param poolId Id of the pool.
    /// @return active Bool the pool is active.
    /// @return poolAddress address of the pool.
    /// @return poolGroup address of the pool factory.
    /// @return poolPrice price of the pool in wei.
    /// @return poolSupply total supply of the pool in units.
    /// @return poolValue total value of the pool in wei.
    /// @return epochReward value of the reward factor or said pool.
    /// @return ratio of assets/performance reward (from 0 to 10000).
    /// @return pop value of the pop reward to be claimed in GRGs.
    function getPoolData(uint256 poolId)
        external
        view
        override
        returns (
            bool active,
            address poolAddress,
            address poolGroup,
            uint256 poolPrice,
            uint256 poolSupply,
            uint256 poolValue,
            uint256 epochReward,
            uint256 ratio,
            uint256 pop
        )
    {
        active = _isActiveInternal(poolId);
        (poolAddress, poolGroup) = _addressFromIdInternal(poolId);
        (poolPrice, poolSupply, poolValue) = _getPoolPriceAndValueInternal(poolId);
        (epochReward, , ratio) = getRewardParameters(poolId);
        (pop, ) = _proofOfPerformanceInternal(poolId);
        return(
            active,
            poolAddress,
            poolGroup,
            poolPrice,
            poolSupply,
            poolValue,
            epochReward,
            ratio,
            pop
        );
    }

    /// @dev Returns the highwatermark of a pool.
    /// @param poolId Id of the pool.
    /// @return Value of the all-time-high pool nav.
    function getHwm(uint256 poolId)
        external
        view
        override
        returns (uint256)
    {
        return _getHwmInternal(poolId);
    }
    
    /// @dev Returns the split ratio of asset and performance reward.
    /// @param poolId Id of the pool.
    /// @return epochReward Value of the reward factor.
    /// @return epochTime Value of epoch time.
    /// @return ratio Value of the ratio from 1 to 100.
    function getRewardParameters(uint256 poolId)
        public
        view
        override
        returns (
            uint256 epochReward,
            uint256 epochTime,
            uint256 ratio
        )
    {
        ( , address groupAddress) = _addressFromIdInternal(poolId);
        epochReward = groupByAddress[groupAddress].epochReward;
        (epochTime, , , , ) = IStaking(STAKING_PROXY_ADDRESS).getParams();
        ratio = groupByAddress[groupAddress].rewardRatio;
    }

    /// @dev Returns the proof of performance reward for a pool.
    /// @param poolId Id of the pool.
    /// @return popReward Value of the pop reward in Rigo tokens.
    /// @return performanceReward Split of the performance reward in Rigo tokens.
    /// @notice epoch reward should be big enough that it.
    /// @notice can be decreased if number of funds increases.
    /// @notice should be at least 10^6 (just as pool base) to start with.
    /// @notice rigo token has 10^18 decimals.
    function proofOfPerformance(uint256 poolId)
        external
        view
        override
        returns (uint256 popReward, uint256 performanceReward)
    {
        return _proofOfPerformanceInternal(poolId);
    }

    /// @dev Checks whether a pool is registered and active.
    /// @param poolId Id of the pool.
    /// @return Bool the pool is active.
    function isActive(uint256 poolId)
        external
        view
        override
        returns (bool)
    {
        return _isActiveInternal(poolId);
    }

    /// @dev Returns the address and the group of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return pool Address of the target pool.
    /// @return group Address of the pool's group.
    function addressFromId(uint256 poolId)
        external
        view
        override
        returns (
            address pool,
            address group
        )
    {
        return _addressFromIdInternal(poolId);
    }

    /// @dev Returns the price a pool from its id.
    /// @param poolId Id of the pool.
    /// @return poolPrice Price of the pool in wei.
    /// @return totalTokens Number of tokens of a pool (totalSupply).
    function getPoolPrice(uint256 poolId)
        external
        view
        override
        returns (
            uint256 poolPrice,
            uint256 totalTokens
        )
    {
        (poolPrice, totalTokens, ) = _getPoolPriceAndValueInternal(poolId);
    }

    /// @dev Returns the value of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return aum Total value of the pool in ETH.
    function calcPoolValue(uint256 poolId)
        external
        view
        override
        returns (
            uint256 aum
        )
    {
        ( , , aum) = _getPoolPriceAndValueInternal(poolId);
    }

    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev Initializes the High Watermark if unitialized.
    /// @param poolId Number of the pool Id in registry.
    function _initializeHwmIfUninitialized(uint256 poolId)
        internal
    {
        if (_highWaterMark[poolId] == uint256(0)) {
            _highWaterMark[poolId] = 1 ether;
        }
    }

    /// @dev Updates high-water mark if positive performance.
    /// @param poolPrice Value of the pool price.
    /// @param poolId Number of the pool Id in registry.
    function _updateHwmIfPositivePerformance(
        uint256 poolPrice,
        uint256 poolId
    )
        internal
    {
        if (poolPrice > _highWaterMark[poolId]) {
            _highWaterMark[poolId] = poolPrice;
        }
    }

    /// @dev Returns the proof of performance reward for a pool.
    /// @param poolId Id of the pool.
    /// @return popReward Value of the pop reward in Rigo tokens.
    /// @return performanceReward Split of the performance reward in Rigo tokens.
    /// @notice epoch reward should be big enough that it  can be decreased when number of funds increases
    /// @notice should be at least 10^6 (just as pool base) to start with.
    function _proofOfPerformanceInternal(uint256 poolId)
        internal
        view
        returns (uint256 popReward, uint256 performanceReward)
    {
        (uint256 newPrice, uint256 tokenSupply, uint256 poolValue) = _getPoolPriceAndValueInternal(poolId);
        (address poolAddress, ) = _addressFromIdInternal(poolId);
        (uint256 epochReward, uint256 epochTime, uint256 rewardRatio) = getRewardParameters(poolId);

        uint256 assetsComponent = safeMul(
            poolValue,
            epochReward
        ) * epochTime / 1 days; // proportional to epoch time

        // TODO: test new logic of only performance component null if price below high watermark
        uint256 performanceComponent = newPrice <= _getHwmInternal(poolId) ? uint256(0) : safeMul(
            safeMul(
                (newPrice - _getHwmInternal(poolId)),
                tokenSupply
            ) / 1000000, // Pool(poolAddress).BASE(),
            epochReward
        ) * 365; // 365 = 365 days / 1 days

        uint256 assetsReward = (
            safeMul(
                assetsComponent,
                safeSub(10000, rewardRatio) // 10000 = 100%
            ) / 10000 ether
        ) * _ethBalanceAdjustmentInternal(poolAddress, poolValue) / 1 ether; // reward inversely proportional to Eth in pool

        performanceReward = safeDiv(
            safeMul(performanceComponent, rewardRatio),
            10000 ether
        ) * _ethBalanceAdjustmentInternal(poolAddress, poolValue) / 1 ether;

        popReward = safeAdd(performanceReward, assetsReward);
    }

    /// @dev Returns the high-watermark of the pool.
    /// @param poolId Number of the pool in registry.
    /// @return Number high-watermark.
    function _getHwmInternal(uint256 poolId)
        internal
        view
        returns (uint256)
    {
        if (_highWaterMark[poolId] == uint256(0)) {
            return (1 ether);

        } else {
            return _highWaterMark[poolId];
        }
    }

    /// @dev Returns the non-linear rewards adjustment by eth.
    /// @param poolAddress Address of the pool.
    /// @param poolValue Number of value of the pool in wei.
    /// @return Number non-linear adjustment.
    function _ethBalanceAdjustmentInternal(
        address poolAddress,
        uint256 poolValue
    )
        internal
        view
        returns (uint256)
    {
        uint256 poolEthBalance = address(IPool(poolAddress)).balance;
        // prevent dust from small pools
        // 1 gwei = 1e9
        if (poolEthBalance > poolValue || poolEthBalance < 1000000 gwei || poolValue < 10 * 1000000 gwei) {
            revert("ETH_ABOVE_AUM_OR_DUST_ERROR");
        }

        // logistic function progression g(x)=e^x/(1+e^x).
        // rebased on {(poolEthBalance / poolValue)} b [0.025:0.6], x b [-1.9:2.8].
        if (1 ether * poolEthBalance / poolValue >= 800 * 1000000 gwei) {
            return (1 ether);

        } else if (1 ether * poolEthBalance / poolValue >= 600 * 1000000 gwei) {
            return (1 ether * 943 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 500 * 1000000 gwei) {
            return (1 ether * 881 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 400 * 1000000 gwei) {
            return (1 ether * 769 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 300 * 1000000 gwei) {
            return (1 ether * 599 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 200 * 1000000 gwei) {
            return (1 ether * 401 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 100 * 1000000 gwei) {
            return (1 ether * 231 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 75 * 1000000 gwei) {
            return (1 ether * 198 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 50 * 1000000 gwei) {
            return (1 ether * 168 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 38 * 1000000 gwei) {
            return (1 ether * 155 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 25 * 1000000 gwei) {
            return (1 ether * 142 / 1000);

        } else { // reward is 0 for any pool not backed by at least 2.5% eth
            revert("ETH_BELOW_2.5_PERCENT_AUM_ERROR");
        }
    }

    /// @dev Checks whether a pool is registered and active.
    /// @param poolId Id of the pool.
    /// @return Bool the pool is active.
    function _isActiveInternal(uint256 poolId)
        internal view
        returns (bool)
    {
        (address poolAddress, , , , , ) = IDragoRegistry(dragoRegistryAddress).fromId(poolId);
        if (poolAddress != address(0)) {
            return true;
        } else return false;
    }

    /// @dev Returns the address and the group of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return pool Address of the target pool.
    /// @return group Address of the pool's group.
    function _addressFromIdInternal(uint256 poolId)
        internal
        view
        returns (
            address pool,
            address group
        )
    {
        (pool, , , , , group) = IDragoRegistry(dragoRegistryAddress).fromId(poolId);
        return (pool, group);
    }

    /// @dev Returns price, supply, aum of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return poolPrice Price of the pool in wei.
    /// @return totalTokens Number of tokens of a pool (totalSupply).
    /// @return aum Address of the target pool.
    function _getPoolPriceAndValueInternal(uint256 poolId)
        internal
        view
        returns (
            uint256 poolPrice,
            uint256 totalTokens,
            uint256 aum
        )
    {
        (address poolAddress, ) = _addressFromIdInternal(poolId);
        IPool pool = IPool(poolAddress);
        poolPrice = pool.calcSharePrice();
        totalTokens = pool.totalSupply();
        if (poolPrice == uint256(0) || totalTokens == uint256(0)) {
            revert("POOL_PRICE_OR_TOTAL_SUPPLY_NULL_ERROR");
        }
        aum = safeMul(poolPrice, totalTokens) / 1000000; // pool.BASE();
    }

    /// @dev Asserts that the caller is the RigoBlock Dao.
    function _assertCallerIsRigoblockDao()
        internal
        view
    {
        if (msg.sender != rigoblockDaoAddress) {
            revert("CALLER_NOT_RIGOBLOCK_DAO_ERROR");
        }
    }

    /// @dev Asserts that the caller is the Staking Proxy.
    function _assertCallerIsStakingProxy()
        internal
        view
    {
        if (msg.sender != STAKING_PROXY_ADDRESS) {
            revert("CALLER_NOT_STAKING_PROXY_ERROR");
        }
    }

    /// @dev Determines whether an address is an account or a contract
    /// @param target Address to be inspected
    /// @return Boolean the address is a contract
    function _isContract(address target)
        internal view
        returns (bool)
    {
        uint size;
        // solhint-disable-next-line
        assembly {
            size := extcodesize(target)
        }
        return size > 0;
    }

    /// @dev Asserts whether the caller contract is the pool
    /// @param poolAddress Address of the calling pool
    function _assertContractIsPool(address poolAddress)
        internal
        view
    {
        if (msg.sender != poolAddress) {
            revert("SMART_CONTRACT_CALLER_IS_NOT_POOL_ERROR");
        }
    }
    
    /// @dev Asserts that an address is an approved factory.
    /// @param _factory Address of the target factory.
    function _assertIsApprovedFactory(address _factory)
        internal
        view
    {
        if (!AuthorityFace(authorityAddress).isWhitelistedFactory(_factory)) {
            revert("NOT_APPROVED_AUTHORITY_ERROR");
        }
    }
}

/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.4.22 <0.8.0;

/// @title Authority Interface - Allows interaction with the Authority contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface AuthorityFace {

    /*
     * EVENTS
     */
    event AuthoritySet(address indexed authority);
    event WhitelisterSet(address indexed whitelister);
    event WhitelistedUser(address indexed target, bool approved);
    event WhitelistedRegistry(address indexed registry, bool approved);
    event WhitelistedFactory(address indexed factory, bool approved);
    event WhitelistedVault(address indexed vault, bool approved);
    event WhitelistedDrago(address indexed drago, bool isWhitelisted);
    event NewDragoEventful(address indexed dragoEventful);
    event NewVaultEventful(address indexed vaultEventful);
    event NewNavVerifier(address indexed navVerifier);
    event NewExchangesAuthority(address indexed exchangesAuthority);

    /*
     * CORE FUNCTIONS
     */
    function setAuthority(address _authority, bool _isWhitelisted) external;
    function setWhitelister(address _whitelister, bool _isWhitelisted) external;
    function whitelistUser(address _target, bool _isWhitelisted) external;
    function whitelistDrago(address _drago, bool _isWhitelisted) external;
    function whitelistVault(address _vault, bool _isWhitelisted) external;
    function whitelistRegistry(address _registry, bool _isWhitelisted) external;
    function whitelistFactory(address _factory, bool _isWhitelisted) external;
    function setDragoEventful(address _dragoEventful) external;
    function setVaultEventful(address _vaultEventful) external;
    function setNavVerifier(address _navVerifier) external;
    function setExchangesAuthority(address _exchangesAuthority) external;

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    function isWhitelistedUser(address _target) external view returns (bool);
    function isAuthority(address _authority) external view returns (bool);
    function isWhitelistedRegistry(address _registry) external view returns (bool);
    function isWhitelistedDrago(address _drago) external view returns (bool);
    function isWhitelistedVault(address _vault) external view returns (bool);
    function isWhitelistedFactory(address _factory) external view returns (bool);
    function getDragoEventful() external view returns (address);
    function getVaultEventful() external view returns (address);
    function getNavVerifier() external view returns (address);
    function getExchangesAuthority() external view returns (address);
}

/*

 Copyright 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.6.0 <0.8.0;

/// @title Pool Interface - Interface of pool standard functions.
/// @author Gabriele Rigo - <[email protected]>
/// @notice only public view functions are used
interface IPool {
    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    function balanceOf(address _who) external view returns (uint256);
    function totalSupply() external view returns (uint256 totaSupply);
    function getEventful() external view returns (address);
    function getData() external view returns (string memory name, string memory symbol, uint256 sellPrice, uint256 buyPrice);
    function calcSharePrice() external view returns (uint256);
    function getAdminData() external view returns (address, address feeCollector, address dragodAO, uint256 ratio, uint256 transactionFee, uint32 minPeriod);
}

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.4.22 <0.8.0;

/// @title Proof of Performance Interface - Allows interaction with the PoP contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface ProofOfPerformanceFace {
    
    /*
     * CORE FUNCTIONS
     */
    /// @dev Credits the pop reward to the Staking Proxy contract.
    /// @param poolId Number of the pool Id in registry.
    function creditPopRewardToStakingProxy(uint256 poolId) external;

    /// @dev Allows RigoBlock Dao to update the pools registry.
    /// @param newDragoRegistryAddress Address of new registry.
    function setRegistry(address newDragoRegistryAddress) external;

    /// @dev Allows RigoBlock Dao to update its address.
    /// @param newRigoblockDaoAddress Address of new dao.
    function setRigoblockDao(address newRigoblockDaoAddress) external;
    
    /// @dev Allows rigoblock dao to update the authority.
    /// @param newAuthorityAddress Address of the authority.
    function setAuthority(address newAuthorityAddress) external;

    /// @dev Allows RigoBlock Dao to set the ratio between assets and performance reward for a group.
    /// @param groupAddress Address of the pool's group.
    /// @param newRatio Value of the new ratio.
    /// @notice onlyRigoblockDao can set ratio.
    function setRatio(address groupAddress, uint256 newRatio) external;
    
    /// @dev Allows rigoblock dao to set the inflation factor for a group.
    /// @param groupAddress Address of the group/factory.
    /// @param inflationFactor Value of the reward factor.
    function setInflationFactor(address groupAddress, uint256 inflationFactor) external;

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Gets data of a pool.
    /// @param poolId Id of the pool.
    /// @return active Bool the pool is active.
    /// @return poolAddress address of the pool.
    /// @return poolGroup address of the pool factory.
    /// @return poolPrice price of the pool in wei.
    /// @return poolSupply total supply of the pool in units.
    /// @return poolValue total value of the pool in wei.
    /// @return epochReward value of the reward factor or said pool.
    /// @return ratio of assets/performance reward (from 0 to 10000).
    /// @return pop value of the pop reward to be claimed in GRGs.
    function getPoolData(uint256 poolId)
        external
        view
        returns (
            bool active,
            address poolAddress,
            address poolGroup,
            uint256 poolPrice,
            uint256 poolSupply,
            uint256 poolValue,
            uint256 epochReward,
            uint256 ratio,
            uint256 pop
        );
    
    /// @dev Returns the highwatermark of a pool.
    /// @param poolId Id of the pool.
    /// @return Value of the all-time-high pool nav.
    function getHwm(uint256 poolId) external view returns (uint256);

    /// @dev Returns the split ratio of asset and performance reward.
    /// @param poolId Id of the pool.
    /// @return epochReward Value of the reward factor.
    /// @return epochTime Value of epoch time.
    /// @return ratio Value of the ratio from 1 to 100.
    function getRewardParameters(uint256 poolId)
        external
        view
        returns (
            uint256 epochReward,
            uint256 epochTime,
            uint256 ratio
        );

    /// @dev Returns the proof of performance reward for a pool.
    /// @param poolId Id of the pool.
    /// @return popReward Value of the pop reward in Rigo tokens.
    /// @return performanceReward Split of the performance reward in Rigo tokens.
    /// @notice epoch reward should be big enough that it.
    /// @notice can be decreased if number of funds increases.
    /// @notice should be at least 10^6 (just as pool base) to start with.
    /// @notice rigo token has 10^18 decimals.
    function proofOfPerformance(uint256 poolId)
        external
        view
        returns (uint256 popReward, uint256 performanceReward);

    /// @dev Checks whether a pool is registered and active.
    /// @param poolId Id of the pool.
    /// @return Bool the pool is active.
    function isActive(uint256 poolId)
        external
        view
        returns (bool);

    /// @dev Returns the address and the group of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return pool Address of the target pool.
    /// @return group Address of the pool's group.
    function addressFromId(uint256 poolId)
        external
        view
        returns (
            address pool,
            address group
        );

    /// @dev Returns the price a pool from its id.
    /// @param poolId Id of the pool.
    /// @return poolPrice Price of the pool in wei.
    /// @return totalTokens Number of tokens of a pool (totalSupply).
    function getPoolPrice(uint256 poolId)
        external
        view
        returns (
            uint256 poolPrice,
            uint256 totalTokens
        );

    /// @dev Returns the value of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return aum Total value of the pool in ETH.
    function calcPoolValue(uint256 poolId)
        external
        view
        returns (
            uint256 aum
        );
}

// SPDX-License-Identifier: Apache 2.0

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.7.4;

import "../utils/0xUtils/Authorizable.sol";
import "../utils/0xUtils/LibRichErrors.sol";
import "../utils/0xUtils/LibSafeMath.sol";
import "../utils/0xUtils/IAssetProxy.sol";
import "../utils/0xUtils/IAssetData.sol";
import "../utils/0xUtils/IERC20Token.sol";
import "./libs/LibStakingRichErrors.sol";
import "./interfaces/IGrgVault.sol";


contract GrgVault is
    Authorizable,
    IGrgVault
{
    using LibSafeMath for uint256;

    // Address of staking proxy contract
    address public stakingProxyAddress;

    // True iff vault has been set to Catastrophic Failure Mode
    bool public isInCatastrophicFailure;

    // Mapping from staker to GRG balance
    mapping (address => uint256) internal _balances;

    // Grg Asset Proxy
    IAssetProxy public grgAssetProxy;

    // Grg Token
    IERC20Token internal _grgToken;

    // Asset data for the ERC20 Proxy
    bytes internal _grgAssetData;

    /// @dev Only stakingProxy can call this function.
    modifier onlyStakingProxy() {
        _assertSenderIsStakingProxy();
        _;
    }

    /// @dev Function can only be called in catastrophic failure mode.
    modifier onlyInCatastrophicFailure() {
        _assertInCatastrophicFailure();
        _;
    }

    /// @dev Function can only be called not in catastropic failure mode
    modifier onlyNotInCatastrophicFailure() {
        _assertNotInCatastrophicFailure();
        _;
    }

    /// @dev Constructor.
    /// @param _grgProxyAddress Address of the RigoBlock Grg Proxy.
    /// @param _grgTokenAddress Address of the Grg Token.
    constructor(
        address _grgProxyAddress,
        address _grgTokenAddress
    )
        Authorizable()
    {
        grgAssetProxy = IAssetProxy(_grgProxyAddress);
        _grgToken = IERC20Token(_grgTokenAddress);
        _grgAssetData = abi.encodeWithSelector(
            IAssetData(address(0)).ERC20Token.selector,
            _grgTokenAddress
        );
    }

    /// @dev Sets the address of the StakingProxy contract.
    /// Note that only the contract owner can call this function.
    /// @param _stakingProxyAddress Address of Staking proxy contract.
    function setStakingProxy(address _stakingProxyAddress)
        external
        override
        onlyAuthorized
    {
        stakingProxyAddress = _stakingProxyAddress;
        emit StakingProxySet(_stakingProxyAddress);
    }

    /// @dev Vault enters into Catastrophic Failure Mode.
    /// *** WARNING - ONCE IN CATOSTROPHIC FAILURE MODE, YOU CAN NEVER GO BACK! ***
    /// Note that only the contract owner can call this function.
    function enterCatastrophicFailure()
        external
        override
        onlyAuthorized
        onlyNotInCatastrophicFailure
    {
        isInCatastrophicFailure = true;
        emit InCatastrophicFailureMode(msg.sender);
    }

    /// @dev Sets the Grg proxy.
    /// Note that only an authorized address can call this function.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param _grgProxyAddress Address of the RigoBlock Grg Proxy.
    function setGrgProxy(address _grgProxyAddress)
        external
        override
        onlyAuthorized
        onlyNotInCatastrophicFailure
    {
        grgAssetProxy = IAssetProxy(_grgProxyAddress);
        emit GrgProxySet(_grgProxyAddress);
    }

    /// @dev Deposit an `amount` of Grg Tokens from `staker` into the vault.
    /// Note that only the Staking contract can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens to deposit.
    function depositFrom(address staker, uint256 amount)
        external
        override
        onlyStakingProxy
        onlyNotInCatastrophicFailure
    {
        // update balance
        _balances[staker] = _balances[staker].safeAdd(amount);

        // notify
        emit Deposit(staker, amount);

        // deposit GRG from staker
        grgAssetProxy.transferFrom(
            _grgAssetData,
            staker,
            address(this),
            amount
        );
    }

    /// @dev Withdraw an `amount` of Grg Tokens to `staker` from the vault.
    /// Note that only the Staking contract can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens to withdraw.
    function withdrawFrom(address staker, uint256 amount)
        external
        override
        onlyStakingProxy
        onlyNotInCatastrophicFailure
    {
        _withdrawFrom(staker, amount);
    }

    /// @dev Withdraw ALL Grg Tokens to `staker` from the vault.
    /// Note that this can only be called when *in* Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    function withdrawAllFrom(address staker)
        external
        override
        onlyInCatastrophicFailure
        returns (uint256)
    {
        // get total balance
        uint256 totalBalance = _balances[staker];

        // withdraw GRG to staker
        _withdrawFrom(staker, totalBalance);
        return totalBalance;
    }

    /// @dev Returns the balance in Grg Tokens of the `staker`
    /// @return Balance in Grg.
    function balanceOf(address staker)
        external
        view
        override
        returns (uint256)
    {
        return _balances[staker];
    }

    /// @dev Returns the entire balance of Grg tokens in the vault.
    function balanceOfGrgVault()
        external
        view
        override
        returns (uint256)
    {
        return _grgToken.balanceOf(address(this));
    }

    /// @dev Withdraw an `amount` of Grg Tokens to `staker` from the vault.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens to withdraw.
    function _withdrawFrom(address staker, uint256 amount)
        internal
    {
        // update balance
        // note that this call will revert if trying to withdraw more
        // than the current balance
        _balances[staker] = _balances[staker].safeSub(amount);

        // notify
        emit Withdraw(staker, amount);

        // withdraw GRG to staker
        _grgToken.transfer(
            staker,
            amount
        );
    }

    /// @dev Asserts that sender is stakingProxy contract.
    function _assertSenderIsStakingProxy()
        private
        view
    {
        if (msg.sender != stakingProxyAddress) {
            LibRichErrors.rrevert(LibStakingRichErrors.OnlyCallableByStakingContractError(
                msg.sender
            ));
        }
    }

    /// @dev Asserts that vault is in catastrophic failure mode.
    function _assertInCatastrophicFailure()
        private
        view
    {
        if (!isInCatastrophicFailure) {
            LibRichErrors.rrevert(LibStakingRichErrors.OnlyCallableIfInCatastrophicFailureError());
        }
    }

    /// @dev Asserts that vault is not in catastrophic failure mode.
    function _assertNotInCatastrophicFailure()
        private
        view
    {
        if (isInCatastrophicFailure) {
            LibRichErrors.rrevert(LibStakingRichErrors.OnlyCallableIfNotInCatastrophicFailureError());
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;

import "./interfaces/IAuthorizable.sol";
import "./LibAuthorizableRichErrors.sol";
import "./LibRichErrors.sol";
import "./Ownable.sol";


// solhint-disable no-empty-blocks
contract Authorizable is
    Ownable,
    IAuthorizable
{
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        _assertSenderIsAuthorized();
        _;
    }

    /// @dev Whether an address is authorized to call privileged functions.
    /// @dev 0 Address to query.
    /// @return 0 Whether the address is authorized.
    mapping (address => bool) public authorized;
    /// @dev Whether an adderss is authorized to call privileged functions.
    /// @dev 0 Index of authorized address.
    /// @return 0 Authorized address.
    address[] public authorities;

    /// @dev Initializes the `owner` address.
    constructor()
        Ownable()
    {}

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external
        override
        onlyOwner
    {
        _addAuthorizedAddress(target);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external
        override
        onlyOwner
    {
        if (!authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetNotAuthorizedError(target));
        }
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                _removeAuthorizedAddressAtIndex(target, i);
                break;
            }
        }
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external
        override
        onlyOwner
    {
        _removeAuthorizedAddressAtIndex(target, index);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        override
        returns (address[] memory)
    {
        return authorities;
    }

    /// @dev Reverts if msg.sender is not authorized.
    function _assertSenderIsAuthorized()
        internal
        view
    {
        if (!authorized[msg.sender]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.SenderNotAuthorizedError(msg.sender));
        }
    }

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function _addAuthorizedAddress(address target)
        internal
    {
        // Ensure that the target is not the zero address.
        if (target == address(0)) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.ZeroCantBeAuthorizedError());
        }

        // Ensure that the target is not already authorized.
        if (authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetAlreadyAuthorizedError(target));
        }

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorization of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function _removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        internal
    {
        if (!authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetNotAuthorizedError(target));
        }
        if (index >= authorities.length) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.IndexOutOfBoundsError(
                index,
                authorities.length
            ));
        }
        if (authorities[index] != target) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.AuthorizedAddressMismatchError(
                authorities[index],
                target
            ));
        }

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.pop();
        emit AuthorizedAddressRemoved(target, msg.sender);
    }
}

/*
  Copyright 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity >=0.5.9 <0.8.0;


abstract contract IAuthorizable {

    // Event logged when a new address is authorized.
    event AuthorizedAddressAdded(
        address indexed target,
        address indexed caller
    );

    // Event logged when a currently authorized address is unauthorized.
    event AuthorizedAddressRemoved(
        address indexed target,
        address indexed caller
    );

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external
        virtual;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external
        virtual;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external
        virtual;

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        virtual
        returns (address[] memory);
}

/*
  Copyright 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity >=0.5.9 <0.8.0;


library LibAuthorizableRichErrors {

    // bytes4(keccak256("AuthorizedAddressMismatchError(address,address)"))
    bytes4 internal constant AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR =
        0x140a84db;

    // bytes4(keccak256("IndexOutOfBoundsError(uint256,uint256)"))
    bytes4 internal constant INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR =
        0xe9f83771;

    // bytes4(keccak256("SenderNotAuthorizedError(address)"))
    bytes4 internal constant SENDER_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xb65a25b9;

    // bytes4(keccak256("TargetAlreadyAuthorizedError(address)"))
    bytes4 internal constant TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR =
        0xde16f1a0;

    // bytes4(keccak256("TargetNotAuthorizedError(address)"))
    bytes4 internal constant TARGET_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xeb5108a2;

    // bytes4(keccak256("ZeroCantBeAuthorizedError()"))
    bytes internal constant ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES =
        hex"57654fe4";

    // solhint-disable func-name-mixedcase
    function AuthorizedAddressMismatchError(
        address authorized,
        address target
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR,
            authorized,
            target
        );
    }

    function IndexOutOfBoundsError(
        uint256 index,
        uint256 length
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR,
            index,
            length
        );
    }

    function SenderNotAuthorizedError(address sender)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SENDER_NOT_AUTHORIZED_ERROR_SELECTOR,
            sender
        );
    }

    function TargetAlreadyAuthorizedError(address target)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function TargetNotAuthorizedError(address target)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_NOT_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function ZeroCantBeAuthorizedError()
        internal
        pure
        returns (bytes memory)
    {
        return ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;


library LibRichErrors {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

/*
  Copyright 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity >=0.5.9 <0.8.0;

import "./interfaces/IOwnable.sol";
import "./LibOwnableRichErrors.sol";
import "./LibRichErrors.sol";


contract Ownable is
    IOwnable
{
    /// @dev The owner of this contract.
    /// @return 0 The owner address.
    address public owner;

    constructor ()
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _assertSenderIsOwner();
        _;
    }

    /// @dev Change the owner of this contract.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner)
        public
        override
        onlyOwner
    {
        if (newOwner == address(0)) {
            LibRichErrors.rrevert(LibOwnableRichErrors.TransferOwnerToZeroError());
        } else {
            owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    function _assertSenderIsOwner()
        internal
        view
    {
        if (msg.sender != owner) {
            LibRichErrors.rrevert(LibOwnableRichErrors.OnlyOwnerError(
                msg.sender,
                owner
            ));
        }
    }
}

/*
  Copyright 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity >=0.5.9 <0.8.0;


abstract contract IOwnable {

    /// @dev Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner)
        public
        virtual;
}

pragma solidity >=0.5.9 <0.8.0;


library LibOwnableRichErrors {

    // bytes4(keccak256("OnlyOwnerError(address,address)"))
    bytes4 internal constant ONLY_OWNER_ERROR_SELECTOR =
        0x1de45ad1;

    // bytes4(keccak256("TransferOwnerToZeroError()"))
    bytes internal constant TRANSFER_OWNER_TO_ZERO_ERROR_BYTES =
        hex"e69edc3e";

    // solhint-disable func-name-mixedcase
    function OnlyOwnerError(
        address sender,
        address owner
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_OWNER_ERROR_SELECTOR,
            sender,
            owner
        );
    }

    function TransferOwnerToZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return TRANSFER_OWNER_TO_ZERO_ERROR_BYTES;
    }
}

pragma solidity >=0.5.9 <0.8.0;

import "./LibRichErrors.sol";
import "./LibSafeMathRichErrors.sol";


library LibSafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

pragma solidity >=0.5.4 <0.8.0;


library LibSafeMathRichErrors {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.4 <0.8.0;


abstract contract IAssetProxy {

    /// @dev Transfers assets. Either succeeds or throws.
    /// @param assetData Byte array encoded for the respective asset proxy.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    function transferFrom(
        bytes calldata assetData,
        address from,
        address to,
        uint256 amount
    )
        external
        virtual;

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        virtual
        returns (bytes4);
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// solhint-disable
pragma solidity >=0.5.4 <0.8.0;
pragma experimental ABIEncoderV2;


// @dev Interface of the asset proxy's assetData.
// The asset proxies take an ABI encoded `bytes assetData` as argument.
// This argument is ABI encoded as one of the methods of this interface.
interface IAssetData {

    /// @dev Function signature for encoding ERC20 assetData.
    /// @param tokenAddress Address of ERC20Token contract.
    function ERC20Token(address tokenAddress)
        external;

    /// @dev Function signature for encoding ERC721 assetData.
    /// @param tokenAddress Address of ERC721 token contract.
    /// @param tokenId Id of ERC721 token to be transferred.
    function ERC721Token(
        address tokenAddress,
        uint256 tokenId
    )
        external;

    /// @dev Function signature for encoding ERC1155 assetData.
    /// @param tokenAddress Address of ERC1155 token contract.
    /// @param tokenIds Array of ids of tokens to be transferred.
    /// @param values Array of values that correspond to each token id to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param callbackData Extra data to be passed to receiver's `onERC1155Received` callback function.
    function ERC1155Assets(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata callbackData
    )
        external;

    /// @dev Function signature for encoding MultiAsset assetData.
    /// @param values Array of amounts that correspond to each asset to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param nestedAssetData Array of assetData fields that will be be dispatched to their correspnding AssetProxy contract.
    function MultiAsset(
        uint256[] calldata values,
        bytes[] calldata nestedAssetData
    )
        external;

    /// @dev Function signature for encoding StaticCall assetData.
    /// @param staticCallTargetAddress Address that will execute the staticcall.
    /// @param staticCallData Data that will be executed via staticcall on the staticCallTargetAddress.
    /// @param expectedReturnDataHash Keccak-256 hash of the expected staticcall return data.
    function StaticCall(
        address staticCallTargetAddress,
        bytes calldata staticCallData,
        bytes32 expectedReturnDataHash
    )
        external;

    /// @dev Function signature for encoding ERC20Bridge assetData.
    /// @param tokenAddress Address of token to transfer.
    /// @param bridgeAddress Address of the bridge contract.
    /// @param bridgeData Arbitrary data to be passed to the bridge contract.
    function ERC20Bridge(
        address tokenAddress,
        address bridgeAddress,
        bytes calldata bridgeData
    )
        external;
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;


abstract contract IERC20Token {

    // solhint-disable no-simple-event-func-name
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value)
        external
        virtual
        returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        virtual
        returns (bool);

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address _spender, uint256 _value)
        external
        virtual
        returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply()
        external
        view
        virtual
        returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address _owner)
        external
        view
        virtual
        returns (uint256);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        virtual
        returns (uint256);
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;

import "../../utils/0xUtils/LibRichErrors.sol";
import "../interfaces/IStructs.sol";


library LibStakingRichErrors {

    enum OperatorShareErrorCodes {
        OperatorShareTooLarge,
        CanOnlyDecreaseOperatorShare
    }

    enum InitializationErrorCodes {
        MixinSchedulerAlreadyInitialized,
        MixinParamsAlreadyInitialized
    }

    enum InvalidParamValueErrorCodes {
        InvalidCobbDouglasAlpha,
        InvalidRewardDelegatedStakeWeight,
        InvalidMaximumMakersInPool,
        InvalidMinimumPoolStake,
        InvalidEpochDuration
    }

    enum PopManagerErrorCodes {
        PopAlreadyRegistered,
        PopNotRegistered
    }

    // bytes4(keccak256("OnlyCallableByPopError(address)"))
    bytes4 internal constant ONLY_CALLABLE_BY_POP_ERROR_SELECTOR =
        0x61ecb802;

    // bytes4(keccak256("PopManagerError(uint8,address)"))
    bytes4 internal constant POP_MANAGER_ERROR_SELECTOR =
        0xb9588e43;

    // bytes4(keccak256("InsufficientBalanceError(uint256,uint256)"))
    bytes4 internal constant INSUFFICIENT_BALANCE_ERROR_SELECTOR =
        0x84c8b7c9;

    // bytes4(keccak256("OnlyCallableByPoolOperatorError(address,bytes32)"))
    bytes4 internal constant ONLY_CALLABLE_BY_POOL_OPERATOR_ERROR_SELECTOR =
        0x82ded785;

    // bytes4(keccak256("BlockTimestampTooLowError(uint256,uint256)"))
    bytes4 internal constant BLOCK_TIMESTAMP_TOO_LOW_ERROR_SELECTOR =
        0xa6bcde47;

    // bytes4(keccak256("OnlyCallableByStakingContractError(address)"))
    bytes4 internal constant ONLY_CALLABLE_BY_STAKING_CONTRACT_ERROR_SELECTOR =
        0xca1d07a2;

    // bytes4(keccak256("OnlyCallableIfInCatastrophicFailureError()"))
    bytes internal constant ONLY_CALLABLE_IF_IN_CATASTROPHIC_FAILURE_ERROR =
        hex"3ef081cc";

    // bytes4(keccak256("OnlyCallableIfNotInCatastrophicFailureError()"))
    bytes internal constant ONLY_CALLABLE_IF_NOT_IN_CATASTROPHIC_FAILURE_ERROR =
        hex"7dd020ce";

    // bytes4(keccak256("OperatorShareError(uint8,bytes32,uint32)"))
    bytes4 internal constant OPERATOR_SHARE_ERROR_SELECTOR =
        0x22df9597;

    // bytes4(keccak256("PoolExistenceError(bytes32,bool)"))
    bytes4 internal constant POOL_EXISTENCE_ERROR_SELECTOR =
        0x9ae94f01;

    // bytes4(keccak256("ProxyDestinationCannotBeNilError()"))
    bytes internal constant PROXY_DESTINATION_CANNOT_BE_NIL_ERROR =
        hex"6eff8285";

    // bytes4(keccak256("InitializationError(uint8)"))
    bytes4 internal constant INITIALIZATION_ERROR_SELECTOR =
        0x0b02d773;

    // bytes4(keccak256("InvalidParamValueError(uint8)"))
    bytes4 internal constant INVALID_PARAM_VALUE_ERROR_SELECTOR =
        0xfc45bd11;

    // bytes4(keccak256("InvalidProtocolFeePaymentError(uint256,uint256)"))
    bytes4 internal constant INVALID_PROTOCOL_FEE_PAYMENT_ERROR_SELECTOR =
        0x31d7a505;

    // bytes4(keccak256("PreviousEpochNotFinalizedError(uint256,uint256)"))
    bytes4 internal constant PREVIOUS_EPOCH_NOT_FINALIZED_ERROR_SELECTOR =
        0x614b800a;

    // bytes4(keccak256("PoolNotFinalizedError(bytes32,uint256)"))
    bytes4 internal constant POOL_NOT_FINALIZED_ERROR_SELECTOR =
        0x5caa0b05;

    // solhint-disable func-name-mixedcase
    function OnlyCallableByPopError(
        address senderAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_CALLABLE_BY_POP_ERROR_SELECTOR,
            senderAddress
        );
    }

    function PopManagerError(
        PopManagerErrorCodes errorCodes,
        address popAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            POP_MANAGER_ERROR_SELECTOR,
            errorCodes,
            popAddress
        );
    }

    function InsufficientBalanceError(
        uint256 amount,
        uint256 balance
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INSUFFICIENT_BALANCE_ERROR_SELECTOR,
            amount,
            balance
        );
    }

    function OnlyCallableByPoolOperatorError(
        address senderAddress,
        bytes32 poolId
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_CALLABLE_BY_POOL_OPERATOR_ERROR_SELECTOR,
            senderAddress,
            poolId
        );
    }

    function BlockTimestampTooLowError(
        uint256 epochEndTime,
        uint256 currentBlockTimestamp
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            BLOCK_TIMESTAMP_TOO_LOW_ERROR_SELECTOR,
            epochEndTime,
            currentBlockTimestamp
        );
    }

    function OnlyCallableByStakingContractError(
        address senderAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_CALLABLE_BY_STAKING_CONTRACT_ERROR_SELECTOR,
            senderAddress
        );
    }

    function OnlyCallableIfInCatastrophicFailureError()
        internal
        pure
        returns (bytes memory)
    {
        return ONLY_CALLABLE_IF_IN_CATASTROPHIC_FAILURE_ERROR;
    }

    function OnlyCallableIfNotInCatastrophicFailureError()
        internal
        pure
        returns (bytes memory)
    {
        return ONLY_CALLABLE_IF_NOT_IN_CATASTROPHIC_FAILURE_ERROR;
    }

    function OperatorShareError(
        OperatorShareErrorCodes errorCodes,
        bytes32 poolId,
        uint32 operatorShare
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            OPERATOR_SHARE_ERROR_SELECTOR,
            errorCodes,
            poolId,
            operatorShare
        );
    }

    function PoolExistenceError(
        bytes32 poolId,
        bool alreadyExists
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            POOL_EXISTENCE_ERROR_SELECTOR,
            poolId,
            alreadyExists
        );
    }

    function InvalidProtocolFeePaymentError(
        uint256 expectedProtocolFeePaid,
        uint256 actualProtocolFeePaid
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_PROTOCOL_FEE_PAYMENT_ERROR_SELECTOR,
            expectedProtocolFeePaid,
            actualProtocolFeePaid
        );
    }

    function InitializationError(InitializationErrorCodes code)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INITIALIZATION_ERROR_SELECTOR,
            uint8(code)
        );
    }

    function InvalidParamValueError(InvalidParamValueErrorCodes code)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_PARAM_VALUE_ERROR_SELECTOR,
            uint8(code)
        );
    }

    function ProxyDestinationCannotBeNilError()
        internal
        pure
        returns (bytes memory)
    {
        return PROXY_DESTINATION_CANNOT_BE_NIL_ERROR;
    }

    function PreviousEpochNotFinalizedError(
        uint256 unfinalizedEpoch,
        uint256 unfinalizedPoolsRemaining
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            PREVIOUS_EPOCH_NOT_FINALIZED_ERROR_SELECTOR,
            unfinalizedEpoch,
            unfinalizedPoolsRemaining
        );
    }

    function PoolNotFinalizedError(
        bytes32 poolId,
        uint256 epoch
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            POOL_NOT_FINALIZED_ERROR_SELECTOR,
            poolId,
            epoch
        );
    }
}

// SPDX-License-Identifier: Apache 2.0

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// solhint-disable-next-line
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/IStaking.sol";
import "./sys/MixinParams.sol";
import "./stake/MixinStake.sol";
import "./rewards/MixinPopRewards.sol";


contract Staking is
    IStaking,
    MixinParams,
    MixinStake,
    MixinPopRewards
{
    /// @dev Initialize storage owned by this contract.
    ///      This function should not be called directly.
    ///      The StakingProxy contract will call it in `attachStakingContract()`.
    function init()
        public
        override
        onlyAuthorized
    {
        // DANGER! When performing upgrades, take care to modify this logic
        // to prevent accidentally clearing prior state.
        _initMixinScheduler();
        _initMixinParams();
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibRichErrors.sol";
import "../immutable/MixinStorage.sol";
import "../immutable/MixinConstants.sol";
import "../interfaces/IStakingEvents.sol";
import "../interfaces/IStakingProxy.sol";
import "../interfaces/IStaking.sol";
import "../libs/LibStakingRichErrors.sol";


abstract contract MixinParams is
    IStaking,
    IStakingEvents,
    MixinStorage,
    MixinConstants
{
    /// @dev Set all configurable parameters at once.
    /// @param _epochDurationInSeconds Minimum seconds between epochs.
    /// @param _rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @param _minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @param _cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @param _cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    function setParams(
        uint256 _epochDurationInSeconds,
        uint32 _rewardDelegatedStakeWeight,
        uint256 _minimumPoolStake,
        uint32 _cobbDouglasAlphaNumerator,
        uint32 _cobbDouglasAlphaDenominator
    )
        external
        override
        onlyAuthorized
    {
        _setParams(
            _epochDurationInSeconds,
            _rewardDelegatedStakeWeight,
            _minimumPoolStake,
            _cobbDouglasAlphaNumerator,
            _cobbDouglasAlphaDenominator
        );

        // Let the staking proxy enforce that these parameters are within
        // acceptable ranges.
        IStakingProxy(address(this)).assertValidStorageParams();
    }

    /// @dev Retrieves all configurable parameter values.
    /// @return _epochDurationInSeconds Minimum seconds between epochs.
    /// @return _rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @return _minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @return _cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @return _cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    function getParams()
        external
        view
        override
        returns (
            uint256 _epochDurationInSeconds,
            uint32 _rewardDelegatedStakeWeight,
            uint256 _minimumPoolStake,
            uint32 _cobbDouglasAlphaNumerator,
            uint32 _cobbDouglasAlphaDenominator
        )
    {
        _epochDurationInSeconds = epochDurationInSeconds;
        _rewardDelegatedStakeWeight = rewardDelegatedStakeWeight;
        _minimumPoolStake = minimumPoolStake;
        _cobbDouglasAlphaNumerator = cobbDouglasAlphaNumerator;
        _cobbDouglasAlphaDenominator = cobbDouglasAlphaDenominator;
    }

    /// @dev Initialize storage belonging to this mixin.
    function _initMixinParams()
        internal
    {
        // Ensure state is uninitialized.
        _assertParamsNotInitialized();

        // Set up defaults.
        uint256 _epochDurationInSeconds = 10 minutes;
        uint32 _rewardDelegatedStakeWeight = (90 * PPM_DENOMINATOR) / 100;
        uint256 _minimumPoolStake = 100 * MIN_TOKEN_VALUE;
        uint32 _cobbDouglasAlphaNumerator = 2;
        uint32 _cobbDouglasAlphaDenominator = 3;

        _setParams(
            _epochDurationInSeconds,
            _rewardDelegatedStakeWeight,
            _minimumPoolStake,
            _cobbDouglasAlphaNumerator,
            _cobbDouglasAlphaDenominator
        );
    }

    /// @dev Asserts that upgradable storage has not yet been initialized.
    function _assertParamsNotInitialized()
        internal
        view
    {
        if (epochDurationInSeconds != 0 &&
            rewardDelegatedStakeWeight != 0 &&
            minimumPoolStake != 0 &&
            cobbDouglasAlphaNumerator != 0 &&
            cobbDouglasAlphaDenominator != 0
        ) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InitializationError(
                    LibStakingRichErrors.InitializationErrorCodes.MixinParamsAlreadyInitialized
                )
            );
        }
    }

    /// @dev Set all configurable parameters at once.
    /// @param _epochDurationInSeconds Minimum seconds between epochs.
    /// @param _rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @param _minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @param _cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @param _cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    function _setParams(
        uint256 _epochDurationInSeconds,
        uint32 _rewardDelegatedStakeWeight,
        uint256 _minimumPoolStake,
        uint32 _cobbDouglasAlphaNumerator,
        uint32 _cobbDouglasAlphaDenominator
    )
        private
    {
        epochDurationInSeconds = _epochDurationInSeconds;
        rewardDelegatedStakeWeight = _rewardDelegatedStakeWeight;
        minimumPoolStake = _minimumPoolStake;
        cobbDouglasAlphaNumerator = _cobbDouglasAlphaNumerator;
        cobbDouglasAlphaDenominator = _cobbDouglasAlphaDenominator;

        emit ParamsSet(
            _epochDurationInSeconds,
            _rewardDelegatedStakeWeight,
            _minimumPoolStake,
            _cobbDouglasAlphaNumerator,
            _cobbDouglasAlphaDenominator
        );
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "./MixinConstants.sol";
import "../../utils/0xUtils/LibRichErrors.sol";
import "../../utils/0xUtils/Authorizable.sol";
import "../interfaces/IGrgVault.sol";
import "../interfaces/IStructs.sol";
import "../libs/LibStakingRichErrors.sol";


// solhint-disable max-states-count, no-empty-blocks
abstract contract MixinStorage is
    Authorizable
{
    // address of staking contract
    address public stakingContract;

    // mapping from StakeStatus to global stored balance
    // NOTE: only Status.DELEGATED is used to access this mapping, but this format
    // is used for extensibility
    mapping (uint8 => IStructs.StoredBalance) internal _globalStakeByStatus;

    // mapping from StakeStatus to address of staker to stored balance
    mapping (uint8 => mapping (address => IStructs.StoredBalance)) internal _ownerStakeByStatus;

    // Mapping from Owner to Pool Id to Amount Delegated
    mapping (address => mapping (bytes32 => IStructs.StoredBalance)) internal _delegatedStakeToPoolByOwner;

    // Mapping from Pool Id to Amount Delegated
    mapping (bytes32 => IStructs.StoredBalance) internal _delegatedStakeByPoolId;

    /// @dev Mapping from RigoBlock pool subaccount to pool Id of rigoblock pool
    /// @dev 0 RigoBlock pool subaccount address.
    /// @return 0 The pool ID.
    mapping (address => bytes32) public poolIdByRbPoolAccount;

    // mapping from Pool Id to Pool
    mapping (bytes32 => IStructs.Pool) internal _poolById;

    /// @dev mapping from pool ID to reward balance of members
    /// @dev 0 Pool ID.
    /// @return 0 The total reward balance of members in this pool.
    mapping (bytes32 => uint256) public rewardsByPoolId;

    // The current epoch.
    uint256 public currentEpoch;

    // The current epoch start time.
    uint256 public currentEpochStartTimeInSeconds;

    // mapping from Pool Id to Epoch to Reward Ratio
    mapping (bytes32 => mapping (uint256 => IStructs.Fraction)) internal _cumulativeRewardsByPool;

    // mapping from Pool Id to Epoch
    mapping (bytes32 => uint256) internal _cumulativeRewardsByPoolLastStored;

    /// @dev Registered RigoBlock Proof_of_Performance contracts, capable of paying protocol fees.
    /// @dev 0 The address to check.
    /// @return 0 Whether the address is a registered proof_of_performance.
    mapping (address => bool) public validPops;

    /* Tweakable parameters */

    // Minimum seconds between epochs.
    uint256 public epochDurationInSeconds;

    // How much delegated stake is weighted vs operator stake, in ppm.
    uint32 public rewardDelegatedStakeWeight;

    // Minimum amount of stake required in a pool to collect rewards.
    uint256 public minimumPoolStake;

    // Numerator for cobb douglas alpha factor.
    uint32 public cobbDouglasAlphaNumerator;

    // Denominator for cobb douglas alpha factor.
    uint32 public cobbDouglasAlphaDenominator;

    /* State for finalization */

    /// @dev Stats for each pool that generated fees with sufficient stake to earn rewards.
    ///      See `_minimumPoolStake` in `MixinParams`.
    /// @dev 0 Pool ID.
    /// @dev 1 Epoch number.
    /// @return 0 Pool fee stats.
    mapping (bytes32 => mapping (uint256 => IStructs.PoolStats)) public poolStatsByEpoch;

    /// @dev Aggregated stats across all pools that generated fees with sufficient stake to earn rewards.
    ///      See `_minimumPoolStake` in MixinParams.
    /// @dev 0 Epoch number.
    /// @return 0 Reward computation stats.
    mapping (uint256 => IStructs.AggregatedStats) public aggregatedStatsByEpoch;

    /// @dev The GRG balance of this contract that is reserved for pool reward payouts.
    uint256 public grgReservedForPoolRewards;
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;


abstract contract MixinConstants {

    // 100% in parts-per-million.
    uint32 constant internal PPM_DENOMINATOR = 10**6;

    bytes32 constant internal NIL_POOL_ID = 0x0000000000000000000000000000000000000000000000000000000000000000;

    address constant internal NIL_ADDRESS = 0x0000000000000000000000000000000000000000;

    uint256 constant internal MIN_TOKEN_VALUE = 10**18;
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;


interface IStakingEvents {

    /// @dev Emitted by MixinStake when GRG is staked.
    /// @param staker of GRG.
    /// @param amount of GRG staked.
    event Stake(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted by MixinStake when GRG is unstaked.
    /// @param staker of GRG.
    /// @param amount of GRG unstaked.
    event Unstake(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted by MixinStake when GRG is unstaked.
    /// @param staker of GRG.
    /// @param amount of GRG unstaked.
    event MoveStake(
        address indexed staker,
        uint256 amount,
        uint8 fromStatus,
        bytes32 indexed fromPool,
        uint8 toStatus,
        bytes32 indexed toPool
    );

    /// @dev Emitted by MixinExchangeManager when an exchange is added.
    /// @param exchangeAddress Address of new exchange.
    event PopAdded(
        address exchangeAddress
    );

    /// @dev Emitted by MixinExchangeManager when an exchange is removed.
    /// @param exchangeAddress Address of removed exchange.
    event PopRemoved(
        address exchangeAddress
    );

    /// @dev Emitted by MixinExchangeFees when a pool starts earning rewards in an epoch.
    /// @param epoch The epoch in which the pool earned rewards.
    /// @param poolId The ID of the pool.
    event StakingPoolEarnedRewardsInEpoch(
        uint256 indexed epoch,
        bytes32 indexed poolId
    );

    /// @dev Emitted by MixinFinalizer when an epoch has ended.
    /// @param epoch The epoch that ended.
    /// @param numPoolsToFinalize Number of pools that earned rewards during `epoch` and must be finalized.
    /// @param rewardsAvailable Rewards available to all pools that earned rewards during `epoch`.
    /// @param totalWeightedStake Total weighted stake across all pools that earned rewards during `epoch`.
    /// @param totalFeesCollected Total fees collected across all pools that earned rewards during `epoch`.
    event EpochEnded(
        uint256 indexed epoch,
        uint256 numPoolsToFinalize,
        uint256 rewardsAvailable,
        uint256 totalFeesCollected,
        uint256 totalWeightedStake
    );

    /// @dev Emitted by MixinFinalizer when an epoch is fully finalized.
    /// @param epoch The epoch being finalized.
    /// @param rewardsPaid Total amount of rewards paid out.
    /// @param rewardsRemaining Rewards left over.
    event EpochFinalized(
        uint256 indexed epoch,
        uint256 rewardsPaid,
        uint256 rewardsRemaining
    );

    /// @dev Emitted by MixinFinalizer when rewards are paid out to a pool.
    /// @param epoch The epoch when the rewards were paid out.
    /// @param poolId The pool's ID.
    /// @param operatorReward Amount of reward paid to pool operator.
    /// @param membersReward Amount of reward paid to pool members.
    event RewardsPaid(
        uint256 indexed epoch,
        bytes32 indexed poolId,
        uint256 operatorReward,
        uint256 membersReward
    );

    /// @dev Emitted whenever staking parameters are changed via the `setParams()` function.
    /// @param epochDurationInSeconds Minimum seconds between epochs.
    /// @param rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @param minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @param cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @param cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    event ParamsSet(
        uint256 epochDurationInSeconds,
        uint32 rewardDelegatedStakeWeight,
        uint256 minimumPoolStake,
        uint256 cobbDouglasAlphaNumerator,
        uint256 cobbDouglasAlphaDenominator
    );

    /// @dev Emitted by MixinStakingPool when a new pool is created.
    /// @param poolId Unique id generated for pool.
    /// @param operator The operator (creator) of pool.
    /// @param operatorShare The share of rewards given to the operator, in ppm.
    event StakingPoolCreated(
        bytes32 poolId,
        address operator,
        uint32 operatorShare
    );

    /// @dev Emitted by MixinStakingPool when a rigoblock pool is added to its staking pool.
    /// @param rbPoolAddress Adress of maker added to pool.
    /// @param poolId Unique id of pool.
    event RbPoolStakingPoolSet(
        address indexed rbPoolAddress,
        bytes32 indexed poolId
    );

    /// @dev Emitted when a staking pool's operator share is decreased.
    /// @param poolId Unique Id of pool.
    /// @param oldOperatorShare Previous share of rewards owned by operator.
    /// @param newOperatorShare Newly decreased share of rewards owned by operator.
    event OperatorShareDecreased(
        bytes32 indexed poolId,
        uint32 oldOperatorShare,
        uint32 newOperatorShare
    );
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "./IStructs.sol";


abstract contract IStakingProxy {

    /// @dev Emitted by StakingProxy when a staking contract is attached.
    /// @param newStakingContractAddress Address of newly attached staking contract.
    event StakingContractAttachedToProxy(
        address newStakingContractAddress
    );

    /// @dev Emitted by StakingProxy when a staking contract is detached.
    event StakingContractDetachedFromProxy();

    /// @dev Attach a staking contract; future calls will be delegated to the staking contract.
    /// Note that this is callable only by an authorized address.
    /// @param _stakingContract Address of staking contract.
    function attachStakingContract(address _stakingContract)
        external
        virtual;

    /// @dev Detach the current staking contract.
    /// Note that this is callable only by an authorized address.
    function detachStakingContract()
        external
        virtual;

    /// @dev Asserts that an epoch is between 5 and 30 days long.
    //       Asserts that 0 < cobb douglas alpha value <= 1.
    //       Asserts that a stake weight is <= 100%.
    //       Asserts that pools allow >= 1 maker.
    //       Asserts that all addresses are initialized.
    function assertValidStorageParams()
        external
        view
        virtual;
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibSafeMath.sol";
import "../staking_pools/MixinStakingPool.sol";
import "../libs/LibStakingRichErrors.sol";


abstract contract MixinStake is
    MixinStakingPool
{
    using LibSafeMath for uint256;

    /// @dev Stake GRG tokens. Tokens are deposited into the GRG Vault.
    ///      Unstake to retrieve the GRG. Stake is in the 'Active' status.
    /// @param amount Amount of GRG to stake.
    function stake(uint256 amount)
        external
        override
    {
        address staker = msg.sender;

        // deposit equivalent amount of GRG into vault
        getGrgVault().depositFrom(staker, amount);

        // mint stake
        _increaseCurrentAndNextBalance(
            _ownerStakeByStatus[uint8(IStructs.StakeStatus.UNDELEGATED)][staker],
            amount
        );

        // notify
        emit Stake(
            staker,
            amount
        );
    }

    /// @dev Unstake. Tokens are withdrawn from the GRG Vault and returned to
    ///      the staker. Stake must be in the 'undelegated' status in both the
    ///      current and next epoch in order to be unstaked.
    /// @param amount Amount of GRG to unstake.
    function unstake(uint256 amount)
        external
        override
    {
        address staker = msg.sender;

        IStructs.StoredBalance memory undelegatedBalance =
            _loadCurrentBalance(_ownerStakeByStatus[uint8(IStructs.StakeStatus.UNDELEGATED)][staker]);

        // stake must be undelegated in current and next epoch to be withdrawn
        uint256 currentWithdrawableStake = LibSafeMath.min256(
            undelegatedBalance.currentEpochBalance,
            undelegatedBalance.nextEpochBalance
        );

        if (amount > currentWithdrawableStake) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InsufficientBalanceError(
                    amount,
                    currentWithdrawableStake
                )
            );
        }

        // burn undelegated stake
        _decreaseCurrentAndNextBalance(
            _ownerStakeByStatus[uint8(IStructs.StakeStatus.UNDELEGATED)][staker],
            amount
        );

        // withdraw equivalent amount of GRG from vault
        getGrgVault().withdrawFrom(staker, amount);

        // emit stake event
        emit Unstake(
            staker,
            amount
        );
    }

    /// @dev Moves stake between statuses: 'undelegated' or 'delegated'.
    ///      Delegated stake can also be moved between pools.
    ///      This change comes into effect next epoch.
    /// @param from Status to move stake out of.
    /// @param to Status to move stake into.
    /// @param amount Amount of stake to move.
    function moveStake(
        IStructs.StakeInfo calldata from,
        IStructs.StakeInfo calldata to,
        uint256 amount
    )
        external
        override
    {
        address staker = msg.sender;

        // Sanity check: no-op if no stake is being moved.
        if (amount == 0) {
            return;
        }

        // Sanity check: no-op if moving stake from undelegated to undelegated.
        if (from.status == IStructs.StakeStatus.UNDELEGATED &&
            to.status == IStructs.StakeStatus.UNDELEGATED) {
            return;
        }

        // handle delegation
        if (from.status == IStructs.StakeStatus.DELEGATED) {
            _undelegateStake(
                from.poolId,
                staker,
                amount
            );
        }

        if (to.status == IStructs.StakeStatus.DELEGATED) {
            _delegateStake(
                to.poolId,
                staker,
                amount
            );
        }

        // execute move
        IStructs.StoredBalance storage fromPtr = _ownerStakeByStatus[uint8(from.status)][staker];
        IStructs.StoredBalance storage toPtr = _ownerStakeByStatus[uint8(to.status)][staker];
        _moveStake(
            fromPtr,
            toPtr,
            amount
        );

        // notify
        emit MoveStake(
            staker,
            amount,
            uint8(from.status),
            from.poolId,
            uint8(to.status),
            to.poolId
        );
    }

    /// @dev Delegates a owners stake to a staking pool.
    /// @param poolId Id of pool to delegate to.
    /// @param staker Owner who wants to delegate.
    /// @param amount Amount of stake to delegate.
    function _delegateStake(
        bytes32 poolId,
        address staker,
        uint256 amount
    )
        private
    {
        // Sanity check the pool we're delegating to exists.
        _assertStakingPoolExists(poolId);

        _withdrawAndSyncDelegatorRewards(
            poolId,
            staker
        );

        // Increase how much stake the staker has delegated to the input pool.
        _increaseNextBalance(
            _delegatedStakeToPoolByOwner[staker][poolId],
            amount
        );

        // Increase how much stake has been delegated to pool.
        _increaseNextBalance(
            _delegatedStakeByPoolId[poolId],
            amount
        );

        // Increase next balance of global delegated stake.
        _increaseNextBalance(
            _globalStakeByStatus[uint8(IStructs.StakeStatus.DELEGATED)],
            amount
        );
    }

    /// @dev Un-Delegates a owners stake from a staking pool.
    /// @param poolId Id of pool to un-delegate from.
    /// @param staker Owner who wants to un-delegate.
    /// @param amount Amount of stake to un-delegate.
    function _undelegateStake(
        bytes32 poolId,
        address staker,
        uint256 amount
    )
        private
    {
        // sanity check the pool we're undelegating from exists
        _assertStakingPoolExists(poolId);

        _withdrawAndSyncDelegatorRewards(
            poolId,
            staker
        );

        // Decrease how much stake the staker has delegated to the input pool.
        _decreaseNextBalance(
            _delegatedStakeToPoolByOwner[staker][poolId],
            amount
        );

        // Decrease how much stake has been delegated to pool.
        _decreaseNextBalance(
            _delegatedStakeByPoolId[poolId],
            amount
        );

        // Decrease next balance of global delegated stake (aggregated across all stakers).
        _decreaseNextBalance(
            _globalStakeByStatus[uint8(IStructs.StakeStatus.DELEGATED)],
            amount
        );
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibRichErrors.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../libs/LibStakingRichErrors.sol";
import "../interfaces/IStructs.sol";
import "../sys/MixinAbstract.sol";
import "./MixinStakingPoolRewards.sol";


abstract contract MixinStakingPool is
    MixinAbstract,
    MixinStakingPoolRewards
{
    using LibSafeMath for uint256;
    using LibSafeDowncast for uint256;

    /// @dev Asserts that the sender is the operator of the input pool.
    /// @param poolId Pool sender must be operator of.
    modifier onlyStakingPoolOperator(bytes32 poolId) {
        _assertSenderIsPoolOperator(poolId);
        _;
    }

    /// @dev Create a new staking pool. The sender will be the staking pal of this pool.
    /// Note that a staking pal must be payable.
    /// @param rigoblockPoolAddress Adds rigoblock pool to the created staking pool for convenience if non-null.
    /// @return poolId The unique pool id generated for this pool.
    function createStakingPool(address rigoblockPoolAddress)
        external
        override
        returns (bytes32 poolId)
    {
        // TODO: test
        (uint256 rbPoolId, , , , address rbPoolOwner, ) = getDragoRegistry().fromAddress(rigoblockPoolAddress);
        require(
            rbPoolId != uint256(0),
            "NON_REGISTERED_RB_POOL_ERROR"
        );
        // note that an operator must be payable
        address operator = rbPoolOwner;

        // add stakingPal, which receives part of operator reward
        address stakingPal = msg.sender;

        // operator initially shares 30% with stakers
        uint32 operatorShare = uint32(700000);

        // staking pal received 10% of operator rewards
        uint32 stakingPalShare = uint32(100000);

        // check that staking pool does not exist and add unique id for this pool
        _assertStakingPoolDoesNotExist(bytes32(rbPoolId));
        poolId = bytes32(rbPoolId);

        // @notice _assertNewOperatorShare if operatorShare, stakingPalShare are inputs after an upgrade

        // create and store pool
        IStructs.Pool memory pool = IStructs.Pool({
            operator: operator,
            stakingPal: stakingPal,
            operatorShare: operatorShare,
            stakingPalShare : stakingPalShare
        });
        _poolById[poolId] = pool;

        // Staking pool has been created
        emit StakingPoolCreated(poolId, operator, operatorShare);

        joinStakingPoolAsRbPoolAccount(poolId, rigoblockPoolAddress);

        return poolId;
    }

    /// @dev Allows the operator to update the staking pal address.
    /// @param poolId Unique id of pool.
    /// @param newStakingPalAddress Address of the new staking pal.
    function setStakingPalAddress(bytes32 poolId, address newStakingPalAddress)
        external
        override
        onlyStakingPoolOperator(poolId)
    {
        IStructs.Pool storage pool = _poolById[poolId];

        if (newStakingPalAddress == address(0) || pool.stakingPal == newStakingPalAddress) {
            return;
        }

        pool.stakingPal = newStakingPalAddress;
    }

    /// @dev Decreases the operator share for the given pool (i.e. increases pool rewards for members).
    /// @param poolId Unique Id of pool.
    /// @param newOperatorShare The newly decreased percentage of any rewards owned by the operator.
    function decreaseStakingPoolOperatorShare(bytes32 poolId, uint32 newOperatorShare)
        external
        override
        onlyStakingPoolOperator(poolId)
    {
        // load pool and assert that we can decrease
        uint32 currentOperatorShare = _poolById[poolId].operatorShare;
        _assertNewOperatorShare(
            poolId,
            currentOperatorShare,
            newOperatorShare
        );

        // decrease operator share
        _poolById[poolId].operatorShare = newOperatorShare;
        emit OperatorShareDecreased(
            poolId,
            currentOperatorShare,
            newOperatorShare
        );
    }

    /// @dev Allows caller to join a staking pool as a rigoblock pool account.
    /// @param poolId Unique id of pool.
    /// @param rigoblockPoolAccount Address of subaccount to be added to staking pool.
    function joinStakingPoolAsRbPoolAccount(
        bytes32 poolId,
        address rigoblockPoolAccount)
        public
        override
    {
        //TODO: test
        (address poolAddress, , , uint256 rbPoolId, , ) = getDragoRegistry().fromId(uint256(poolId));

        // only rigoblock pools registered in drago registry can have accounts added to their staking pool
        if (rbPoolId == uint256(0)) {
            revert("NON_REGISTERED_POOL_ID_ERROR");
        }

        // only allow pool itself to be registered account
        if (poolAddress != rigoblockPoolAccount) {
            revert("POOL_TO_JOIN_NOT_SELF_ERROR");
        }

        // write to storage
        poolIdByRbPoolAccount[poolAddress] = poolId;
        emit RbPoolStakingPoolSet(
            rigoblockPoolAccount,
            poolId
        );
    }

    /// @dev Returns a staking pool
    /// @param poolId Unique id of pool.
    function getStakingPool(bytes32 poolId)
        public
        view
        override
        returns (IStructs.Pool memory)
    {
        return _poolById[poolId];
    }

    /// @dev Reverts iff a staking pool does not exist.
    /// @param poolId Unique id of pool.
    function _assertStakingPoolExists(bytes32 poolId)
        internal
        view
    {
        if (_poolById[poolId].operator == NIL_ADDRESS) {
            // we use the pool's operator as a proxy for its existence
            LibRichErrors.rrevert(
                LibStakingRichErrors.PoolExistenceError(
                    poolId,
                    false
                )
            );
        }
    }

    /// @dev Reverts iff a staking pool does exist.
    /// @param poolId Unique id of pool.
    function _assertStakingPoolDoesNotExist(bytes32 poolId)
        internal
        view
    {
        if (_poolById[poolId].operator != NIL_ADDRESS) {
            // we use the pool's operator as a proxy for its existence
            LibRichErrors.rrevert(
                LibStakingRichErrors.PoolExistenceError(
                    poolId,
                    false
                )
            );
        }
    }

    /// @dev Reverts iff the new operator share is invalid.
    /// @param poolId Unique id of pool.
    /// @param currentOperatorShare Current operator share.
    /// @param newOperatorShare New operator share.
    function _assertNewOperatorShare(
        bytes32 poolId,
        uint32 currentOperatorShare,
        uint32 newOperatorShare
    )
        private
        pure
    {
        // sanity checks
        if (newOperatorShare > PPM_DENOMINATOR) {
            // operator share must be a valid fraction
            LibRichErrors.rrevert(LibStakingRichErrors.OperatorShareError(
                LibStakingRichErrors.OperatorShareErrorCodes.OperatorShareTooLarge,
                poolId,
                newOperatorShare
            ));
        } else if (newOperatorShare > currentOperatorShare) {
            // new share must be less than or equal to the current share
            LibRichErrors.rrevert(LibStakingRichErrors.OperatorShareError(
                LibStakingRichErrors.OperatorShareErrorCodes.CanOnlyDecreaseOperatorShare,
                poolId,
                newOperatorShare
            ));
        }
    }

    /// @dev Asserts that the sender is the operator of the input pool.
    /// @param poolId Pool sender must be operator of.
    function _assertSenderIsPoolOperator(bytes32 poolId)
        private
        view
    {
        address operator = _poolById[poolId].operator;
        if (msg.sender != operator) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.OnlyCallableByPoolOperatorError(
                    msg.sender,
                    poolId
                )
            );
        }
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;


/// @dev Exposes some internal functions from various contracts to avoid
///      cyclical dependencies.
abstract contract MixinAbstract {

    /// @dev Computes the reward owed to a pool during finalization.
    ///      Does nothing if the pool is already finalized.
    /// @param poolId The pool's ID.
    /// @return totalReward The total reward owed to a pool.
    /// @return membersStake The total stake for all non-operator members in
    ///         this pool.
    function _getUnfinalizedPoolRewards(bytes32 poolId)
        internal
        view
        virtual
        returns (
            uint256 totalReward,
            uint256 membersStake
        );

    /// @dev Asserts that a pool has been finalized last epoch.
    /// @param poolId The id of the pool that should have been finalized.
    function _assertPoolFinalizedLastEpoch(bytes32 poolId)
        internal
        view
        virtual;
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibMath.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../interfaces/IStaking.sol";
import "./MixinCumulativeRewards.sol";
import "../sys/MixinAbstract.sol";


abstract contract MixinStakingPoolRewards is
    IStaking,
    MixinAbstract,
    MixinCumulativeRewards
{
    using LibSafeMath for uint256;

    /// @dev Withdraws the caller's WETH rewards that have accumulated
    ///      until the last epoch.
    /// @param poolId Unique id of pool.
    function withdrawDelegatorRewards(bytes32 poolId)
        external
        override
    {
        _withdrawAndSyncDelegatorRewards(poolId, msg.sender);
    }

    /// @dev Computes the reward balance in ETH of the operator of a pool.
    /// @param poolId Unique id of pool.
    /// @return reward totalReward Balance in ETH.
    function computeRewardBalanceOfOperator(bytes32 poolId)
        external
        view
        override
        returns (uint256 reward)
    {
        // Because operator rewards are immediately withdrawn as WETH
        // on finalization, the only factor in this function are unfinalized
        // rewards.
        IStructs.Pool memory pool = _poolById[poolId];
        // Get any unfinalized rewards.
        (uint256 unfinalizedTotalRewards, uint256 unfinalizedMembersStake) =
            _getUnfinalizedPoolRewards(poolId);

        // Get the operators' portion.
        (reward,) = _computePoolRewardsSplit(
            pool.operatorShare,
            unfinalizedTotalRewards,
            unfinalizedMembersStake
        );
        return reward;
    }

    /// @dev Computes the reward balance in ETH of a specific member of a pool.
    /// @param poolId Unique id of pool.
    /// @param member The member of the pool.
    /// @return reward totalReward Balance in ETH.
    function computeRewardBalanceOfDelegator(bytes32 poolId, address member)
        external
        view
        override
        returns (uint256 reward)
    {
        IStructs.Pool memory pool = _poolById[poolId];
        // Get any unfinalized rewards.
        (uint256 unfinalizedTotalRewards, uint256 unfinalizedMembersStake) =
            _getUnfinalizedPoolRewards(poolId);

        // Get the members' portion.
        (, uint256 unfinalizedMembersReward) = _computePoolRewardsSplit(
            pool.operatorShare,
            unfinalizedTotalRewards,
            unfinalizedMembersStake
        );
        return _computeDelegatorReward(
            poolId,
            member,
            unfinalizedMembersReward,
            unfinalizedMembersStake
        );
    }

    /// @dev Syncs rewards for a delegator. This includes withdrawing rewards
    ///      rewards and adding/removing dependencies on cumulative rewards.
    /// @param poolId Unique id of pool.
    /// @param member of the pool.
    function _withdrawAndSyncDelegatorRewards(
        bytes32 poolId,
        address member
    )
        internal
    {
        // Ensure the pool is finalized.
        _assertPoolFinalizedLastEpoch(poolId);

        // Compute balance owed to delegator
        uint256 balance = _computeDelegatorReward(
            poolId,
            member,
            // No unfinalized values because we ensured the pool is already
            // finalized.
            0,
            0
        );

        // Sync the delegated stake balance. This will ensure future calls of
        // `_computeDelegatorReward` during this epoch will return 0,
        // preventing a delegator from withdrawing more than once an epoch.
        _delegatedStakeToPoolByOwner[member][poolId] =
            _loadCurrentBalance(_delegatedStakeToPoolByOwner[member][poolId]);

        // Withdraw non-0 balance
        if (balance != 0) {
            // Decrease the balance of the pool
            _decreasePoolRewards(poolId, balance);

            // Withdraw the member's GRG balance
            getGrgContract().transfer(member, balance);
        }

        // Ensure a cumulative reward entry exists for this epoch,
        // copying the previous epoch's CR if one doesn't exist already.
        _updateCumulativeReward(poolId);
    }

    /// @dev Handles a pool's reward at the current epoch.
    ///      This will split the reward between the operator and members,
    ///      depositing them into their respective vaults, and update the
    ///      accounting needed to allow members to withdraw their individual
    ///      rewards.
    /// @param poolId Unique Id of pool.
    /// @param reward received by the pool.
    /// @param membersStake the amount of non-operator delegated stake that
    ///        will split the  reward.
    /// @return operatorReward Portion of `reward` given to the pool operator.
    /// @return membersReward Portion of `reward` given to the pool members.
    function _syncPoolRewards(
        bytes32 poolId,
        uint256 reward,
        uint256 membersStake
    )
        internal
        returns (uint256 operatorReward, uint256 membersReward)
    {
        IStructs.Pool memory pool = _poolById[poolId];

        // Split the reward between operator and members
        (operatorReward, membersReward) = _computePoolRewardsSplit(
            pool.operatorShare,
            reward,
            membersStake
        );

        if (operatorReward > 0) {
            if (pool.operator == pool.stakingPal) {
                // Transfer the operator's grg reward to the operator
                getGrgContract().transfer(pool.operator, operatorReward);
            } else {
                // Transfer staking pal share of operator's reward to staking pal
                // Transfer the reamining operator's grg reward to the operator
                uint256 stakingPalReward = operatorReward.safeMul(pool.stakingPalShare).safeDiv(PPM_DENOMINATOR);
                getGrgContract().transfer(pool.stakingPal, stakingPalReward);
                getGrgContract().transfer(pool.operator, operatorReward.safeSub(stakingPalReward));
            }
        }

        if (membersReward > 0) {
            // Increase the balance of the pool
            _increasePoolRewards(poolId, membersReward);
            // Create a cumulative reward entry at the current epoch.
            _addCumulativeReward(poolId, membersReward, membersStake);
        }

        return (operatorReward, membersReward);
    }

    /// @dev Compute the split of a pool reward between the operator and members
    ///      based on the `operatorShare` and `membersStake`.
    /// @param operatorShare The fraction of rewards owed to the operator,
    ///        in PPM.
    /// @param totalReward The pool reward.
    /// @param membersStake The amount of member (non-operator) stake delegated
    ///        to the pool in the epoch the rewards were earned.
    /// @return operatorReward Portion of `totalReward` given to the pool operator.
    /// @return membersReward Portion of `totalReward` given to the pool members.
    function _computePoolRewardsSplit(
        uint32 operatorShare,
        uint256 totalReward,
        uint256 membersStake
    )
        internal
        pure
        returns (uint256 operatorReward, uint256 membersReward)
    {
        if (membersStake == 0) {
            operatorReward = totalReward;
        } else {
            operatorReward = LibMath.getPartialAmountCeil(
                uint256(operatorShare),
                PPM_DENOMINATOR,
                totalReward
            );
            membersReward = totalReward.safeSub(operatorReward);
        }
        return (operatorReward, membersReward);
    }

    /// @dev Computes the reward balance in ETH of a specific member of a pool.
    /// @param poolId Unique id of pool.
    /// @param member of the pool.
    /// @param unfinalizedMembersReward Unfinalized total members reward (if any).
    /// @param unfinalizedMembersStake Unfinalized total members stake (if any).
    /// @return reward Balance in WETH.
    function _computeDelegatorReward(
        bytes32 poolId,
        address member,
        uint256 unfinalizedMembersReward,
        uint256 unfinalizedMembersStake
    )
        private
        view
        returns (uint256 reward)
    {
        uint256 currentEpoch_ = currentEpoch;
        IStructs.StoredBalance memory delegatedStake = _delegatedStakeToPoolByOwner[member][poolId];

        // There can be no rewards if the last epoch when stake was stored is
        // equal to the current epoch, because all prior rewards, including
        // rewards finalized this epoch have been claimed.
        if (delegatedStake.currentEpoch == currentEpoch_) {
            return 0;
        }

        // We account for rewards over 3 intervals, below.

        // 1/3 Unfinalized rewards earned in `currentEpoch - 1`.
        reward = _computeUnfinalizedDelegatorReward(
            delegatedStake,
            currentEpoch_,
            unfinalizedMembersReward,
            unfinalizedMembersStake
        );

        // 2/3 Finalized rewards earned in epochs [`delegatedStake.currentEpoch + 1` .. `currentEpoch - 1`]
        uint256 delegatedStakeNextEpoch = uint256(delegatedStake.currentEpoch).safeAdd(1);
        reward = reward.safeAdd(
            _computeMemberRewardOverInterval(
                poolId,
                delegatedStake.currentEpochBalance,
                delegatedStake.currentEpoch,
                delegatedStakeNextEpoch
            )
        );

        // 3/3 Finalized rewards earned in epoch `delegatedStake.currentEpoch`.
        reward = reward.safeAdd(
            _computeMemberRewardOverInterval(
                poolId,
                delegatedStake.nextEpochBalance,
                delegatedStakeNextEpoch,
                currentEpoch_
            )
        );

        return reward;
    }

    /// @dev Computes the unfinalized rewards earned by a delegator in the last epoch.
    /// @param delegatedStake Amount of stake delegated to pool by a specific staker
    /// @param currentEpoch_ The epoch in which this call is executing
    /// @param unfinalizedMembersReward Unfinalized total members reward (if any).
    /// @param unfinalizedMembersStake Unfinalized total members stake (if any).
    /// @return reward Balance in WETH.
    function _computeUnfinalizedDelegatorReward(
        IStructs.StoredBalance memory delegatedStake,
        uint256 currentEpoch_,
        uint256 unfinalizedMembersReward,
        uint256 unfinalizedMembersStake
    )
        private
        pure
        returns (uint256)
    {
        // If there are unfinalized rewards this epoch, compute the member's
        // share.
        if (unfinalizedMembersReward == 0 || unfinalizedMembersStake == 0) {
            return 0;
        }

        // Unfinalized rewards are always earned from stake in
        // the prior epoch so we want the stake at `currentEpoch_-1`.
        uint256 unfinalizedStakeBalance = delegatedStake.currentEpoch >= currentEpoch_.safeSub(1) ?
            delegatedStake.currentEpochBalance :
            delegatedStake.nextEpochBalance;

        // Sanity check to save gas on computation
        if (unfinalizedStakeBalance == 0) {
            return 0;
        }

        // Compute unfinalized reward
        return LibMath.getPartialAmountFloor(
            unfinalizedMembersReward,
            unfinalizedMembersStake,
            unfinalizedStakeBalance
        );
    }

    /// @dev Increases rewards for a pool.
    /// @param poolId Unique id of pool.
    /// @param amount Amount to increment rewards by.
    function _increasePoolRewards(bytes32 poolId, uint256 amount)
        private
    {
        rewardsByPoolId[poolId] = rewardsByPoolId[poolId].safeAdd(amount);
        grgReservedForPoolRewards = grgReservedForPoolRewards.safeAdd(amount);
    }

    /// @dev Decreases rewards for a pool.
    /// @param poolId Unique id of pool.
    /// @param amount Amount to decrement rewards by.
    function _decreasePoolRewards(bytes32 poolId, uint256 amount)
        private
    {
        rewardsByPoolId[poolId] = rewardsByPoolId[poolId].safeSub(amount);
        grgReservedForPoolRewards = grgReservedForPoolRewards.safeSub(amount);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;

import "./LibSafeMath.sol";
import "./LibRichErrors.sol";
import "./LibMathRichErrors.sol";


library LibMath {

    using LibSafeMath for uint256;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        if (isRoundingErrorFloor(
                numerator,
                denominator,
                target
        )) {
            LibRichErrors.rrevert(LibMathRichErrors.RoundingError(
                numerator,
                denominator,
                target
            ));
        }

        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded up.
    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        if (isRoundingErrorCeil(
                numerator,
                denominator,
                target
        )) {
            LibRichErrors.rrevert(LibMathRichErrors.RoundingError(
                numerator,
                denominator,
                target
            ));
        }

        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target)
            .safeAdd(denominator.safeSub(1))
            .safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded down.
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded up.
    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target)
            .safeAdd(denominator.safeSub(1))
            .safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        if (denominator == 0) {
            LibRichErrors.rrevert(LibMathRichErrors.DivisionByZeroError());
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * denominator)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        if (denominator == 0) {
            LibRichErrors.rrevert(LibMathRichErrors.DivisionByZeroError());
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = denominator.safeSub(remainder) % denominator;
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }
}

pragma solidity >=0.5.9 <0.8.0;


library LibMathRichErrors {

    // bytes4(keccak256("DivisionByZeroError()"))
    bytes internal constant DIVISION_BY_ZERO_ERROR =
        hex"a791837c";

    // bytes4(keccak256("RoundingError(uint256,uint256,uint256)"))
    bytes4 internal constant ROUNDING_ERROR_SELECTOR =
        0x339f3de2;

    // solhint-disable func-name-mixedcase
    function DivisionByZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return DIVISION_BY_ZERO_ERROR;
    }

    function RoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ROUNDING_ERROR_SELECTOR,
            numerator,
            denominator,
            target
        );
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibFractions.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../stake/MixinStakeBalances.sol";
import "../immutable/MixinConstants.sol";


abstract contract MixinCumulativeRewards is
    MixinStakeBalances,
    MixinConstants
{
    using LibSafeMath for uint256;

    /// @dev returns true iff Cumulative Rewards are set
    function _isCumulativeRewardSet(IStructs.Fraction memory cumulativeReward)
        internal
        pure
        returns (bool)
    {
        // We use the denominator as a proxy for whether the cumulative
        // reward is set, as setting the cumulative reward always sets this
        // field to at least 1.
        return cumulativeReward.denominator != 0;
    }

    /// @dev Sets a pool's cumulative delegator rewards for the current epoch,
    ///      given the rewards earned and stake from the last epoch, which will
    ///      be summed with the previous cumulative rewards for this pool.
    ///      If the last cumulative reward epoch is the current epoch, this is a
    ///      no-op.
    /// @param poolId The pool ID.
    /// @param reward The total reward earned by pool delegators from the last epoch.
    /// @param stake The total delegated stake in the pool in the last epoch.
    function _addCumulativeReward(
        bytes32 poolId,
        uint256 reward,
        uint256 stake
    )
        internal
    {
        // Fetch the last epoch at which we stored an entry for this pool;
        // this is the most up-to-date cumulative rewards for this pool.
        uint256 lastStoredEpoch = _cumulativeRewardsByPoolLastStored[poolId];
        uint256 currentEpoch_ = currentEpoch;

        // If we already have a record for this epoch, don't overwrite it.
        if (lastStoredEpoch == currentEpoch_) {
            return;
        }

        IStructs.Fraction memory mostRecentCumulativeReward =
            _cumulativeRewardsByPool[poolId][lastStoredEpoch];

        // Compute new cumulative reward
        IStructs.Fraction memory cumulativeReward;
        if (_isCumulativeRewardSet(mostRecentCumulativeReward)) {
            // If we have a prior cumulative reward entry, we sum them as fractions.
            (cumulativeReward.numerator, cumulativeReward.denominator) = LibFractions.add(
                mostRecentCumulativeReward.numerator,
                mostRecentCumulativeReward.denominator,
                reward,
                stake
            );
            // Normalize to prevent overflows in future operations.
            (cumulativeReward.numerator, cumulativeReward.denominator) = LibFractions.normalize(
                cumulativeReward.numerator,
                cumulativeReward.denominator
            );
        } else {
            (cumulativeReward.numerator, cumulativeReward.denominator) = (reward, stake);
        }

        // Store cumulative rewards for this epoch.
        _cumulativeRewardsByPool[poolId][currentEpoch_] = cumulativeReward;
        _cumulativeRewardsByPoolLastStored[poolId] = currentEpoch_;
    }

    /// @dev Sets a pool's cumulative delegator rewards for the current epoch,
    ///      using the last stored cumulative rewards. If we've already set
    ///      a CR for this epoch, this is a no-op.
    /// @param poolId The pool ID.
    function _updateCumulativeReward(bytes32 poolId)
        internal
    {
        // Just add empty rewards for this epoch, which will be added to
        // the previous CR, so we end up with the previous CR being set for
        // this epoch.
        _addCumulativeReward(poolId, 0, 1);
    }

    /// @dev Computes a member's reward over a given epoch interval.
    /// @param poolId Uniqud Id of pool.
    /// @param memberStakeOverInterval Stake delegated to pool by member over
    ///        the interval.
    /// @param beginEpoch Beginning of interval.
    /// @param endEpoch End of interval.
    /// @return reward Reward accumulated over interval [beginEpoch, endEpoch]
    function _computeMemberRewardOverInterval(
        bytes32 poolId,
        uint256 memberStakeOverInterval,
        uint256 beginEpoch,
        uint256 endEpoch
    )
        internal
        view
        returns (uint256 reward)
    {
        // Sanity check if we can skip computation, as it will result in zero.
        if (memberStakeOverInterval == 0 || beginEpoch == endEpoch) {
            return 0;
        }

        // Sanity check interval
        require(beginEpoch < endEpoch, "CR_INTERVAL_INVALID");

        // Sanity check begin reward
        IStructs.Fraction memory beginReward = _getCumulativeRewardAtEpoch(poolId, beginEpoch);
        IStructs.Fraction memory endReward = _getCumulativeRewardAtEpoch(poolId, endEpoch);

        // Compute reward
        reward = LibFractions.scaleDifference(
            endReward.numerator,
            endReward.denominator,
            beginReward.numerator,
            beginReward.denominator,
            memberStakeOverInterval
        );
    }

    /// @dev Fetch the most recent cumulative reward entry for a pool.
    /// @param poolId Unique ID of pool.
    /// @return cumulativeReward The most recent cumulative reward `poolId`.
    function _getMostRecentCumulativeReward(bytes32 poolId)
        private
        view
        returns (IStructs.Fraction memory cumulativeReward)
    {
        uint256 lastStoredEpoch = _cumulativeRewardsByPoolLastStored[poolId];
        return _cumulativeRewardsByPool[poolId][lastStoredEpoch];
    }

    /// @dev Fetch the cumulative reward for a given epoch.
    ///      If the corresponding CR does not exist in state, then we backtrack
    ///      to find its value by querying `epoch-1` and then most recent CR.
    /// @param poolId Unique ID of pool.
    /// @param epoch The epoch to find the
    /// @return cumulativeReward The cumulative reward for `poolId` at `epoch`.
    function _getCumulativeRewardAtEpoch(bytes32 poolId, uint256 epoch)
        private
        view
        returns (IStructs.Fraction memory cumulativeReward)
    {
        // Return CR at `epoch`, given it's set.
        cumulativeReward = _cumulativeRewardsByPool[poolId][epoch];
        if (_isCumulativeRewardSet(cumulativeReward)) {
            return cumulativeReward;
        }

        // Return CR at `epoch-1`, given it's set.
        uint256 lastEpoch = epoch.safeSub(1);
        cumulativeReward = _cumulativeRewardsByPool[poolId][lastEpoch];
        if (_isCumulativeRewardSet(cumulativeReward)) {
            return cumulativeReward;
        }

        // Return the most recent CR, given it's less than `epoch`.
        uint256 mostRecentEpoch = _cumulativeRewardsByPoolLastStored[poolId];
        if (mostRecentEpoch < epoch) {
            cumulativeReward = _cumulativeRewardsByPool[poolId][mostRecentEpoch];
            if (_isCumulativeRewardSet(cumulativeReward)) {
                return cumulativeReward;
            }
        }

        // Otherwise return an empty CR.
        return IStructs.Fraction(0, 1);
    }
}

pragma solidity >=0.5.4 <0.8.0;

import "./LibSafeMath.sol";


library LibFractions {

    using LibSafeMath for uint256;

    /// @dev Safely adds two fractions `n1/d1 + n2/d2`
    /// @param n1 numerator of `1`
    /// @param d1 denominator of `1`
    /// @param n2 numerator of `2`
    /// @param d2 denominator of `2`
    /// @return numerator Numerator of sum
    /// @return denominator Denominator of sum
    function add(
        uint256 n1,
        uint256 d1,
        uint256 n2,
        uint256 d2
    )
        internal
        pure
        returns (
            uint256 numerator,
            uint256 denominator
        )
    {
        if (n1 == 0) {
            return (numerator = n2, denominator = d2);
        }
        if (n2 == 0) {
            return (numerator = n1, denominator = d1);
        }
        numerator = n1
            .safeMul(d2)
            .safeAdd(n2.safeMul(d1));
        denominator = d1.safeMul(d2);
        return (numerator, denominator);
    }

    /// @dev Rescales a fraction to prevent overflows during addition if either
    ///      the numerator or the denominator are > `maxValue`.
    /// @param numerator The numerator.
    /// @param denominator The denominator.
    /// @param maxValue The maximum value allowed for both the numerator and
    ///        denominator.
    /// @return scaledNumerator The rescaled numerator.
    /// @return scaledDenominator The rescaled denominator.
    function normalize(
        uint256 numerator,
        uint256 denominator,
        uint256 maxValue
    )
        internal
        pure
        returns (
            uint256 scaledNumerator,
            uint256 scaledDenominator
        )
    {
        // If either the numerator or the denominator are > `maxValue`,
        // re-scale them by `maxValue` to prevent overflows in future operations.
        if (numerator > maxValue || denominator > maxValue) {
            uint256 rescaleBase = numerator >= denominator ? numerator : denominator;
            rescaleBase = rescaleBase.safeDiv(maxValue);
            scaledNumerator = numerator.safeDiv(rescaleBase);
            scaledDenominator = denominator.safeDiv(rescaleBase);
        } else {
            scaledNumerator = numerator;
            scaledDenominator = denominator;
        }
        return (scaledNumerator, scaledDenominator);
    }

    /// @dev Rescales a fraction to prevent overflows during addition if either
    ///      the numerator or the denominator are > 2 ** 127.
    /// @param numerator The numerator.
    /// @param denominator The denominator.
    /// @return scaledNumerator The rescaled numerator.
    /// @return scaledDenominator The rescaled denominator.
    function normalize(
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (
            uint256 scaledNumerator,
            uint256 scaledDenominator
        )
    {
        return normalize(numerator, denominator, 2 ** 127);
    }

    /// @dev Safely scales the difference between two fractions.
    /// @param n1 numerator of `1`
    /// @param d1 denominator of `1`
    /// @param n2 numerator of `2`
    /// @param d2 denominator of `2`
    /// @param s scalar to multiply by difference.
    /// @return result `s * (n1/d1 - n2/d2)`.
    function scaleDifference(
        uint256 n1,
        uint256 d1,
        uint256 n2,
        uint256 d2,
        uint256 s
    )
        internal
        pure
        returns (uint256 result)
    {
        if (s == 0) {
            return 0;
        }
        if (n2 == 0) {
            return result = s
                .safeMul(n1)
                .safeDiv(d1);
        }
        uint256 numerator = n1
            .safeMul(d2)
            .safeSub(n2.safeMul(d1));
        uint256 tmp = numerator.safeDiv(d2);
        return s
            .safeMul(tmp)
            .safeDiv(d1);
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../libs/LibSafeDowncast.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../interfaces/IStructs.sol";
import "../immutable/MixinDeploymentConstants.sol";
import "./MixinStakeStorage.sol";
import "../../rigoToken/Inflation/InflationFace.sol";


abstract contract MixinStakeBalances is
    MixinStakeStorage,
    MixinDeploymentConstants
{
    using LibSafeMath for uint256;
    using LibSafeDowncast for uint256;

    /// @dev Gets global stake for a given status.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Global stake for given status.
    function getGlobalStakeByStatus(IStructs.StakeStatus stakeStatus)
        external
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(
            _globalStakeByStatus[uint8(IStructs.StakeStatus.DELEGATED)]
        );
        if (stakeStatus == IStructs.StakeStatus.UNDELEGATED) {
            // Undelegated stake is the difference between total stake and delegated stake
            // Note that any ZRX erroneously sent to the vault will be counted as undelegated stake
            uint256 totalStake = getGrgVault().balanceOfGrgVault();
            balance.currentEpochBalance = totalStake.safeSub(balance.currentEpochBalance).downcastToUint96();
            balance.nextEpochBalance = totalStake.safeSub(balance.nextEpochBalance).downcastToUint96();
        }
        return balance;
    }

    /// @dev Gets an owner's stake balances by status.
    /// @param staker Owner of stake.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Owner's stake balances for given status.
    function getOwnerStakeByStatus(
        address staker,
        IStructs.StakeStatus stakeStatus
    )
        external
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(
            _ownerStakeByStatus[uint8(stakeStatus)][staker]
        );
        return balance;
    }

    /// @dev Returns the total stake for a given staker.
    /// @param staker of stake.
    /// @return Total GRG staked by `staker`.
    function getTotalStake(address staker)
        public
        view
        override
        returns (uint256)
    {
        return getGrgVault().balanceOf(staker);
    }

    /// @dev Returns the stake delegated to a specific staking pool, by a given staker.
    /// @param staker of stake.
    /// @param poolId Unique Id of pool.
    /// @return balance Stake delegated to pool by staker.
    function getStakeDelegatedToPoolByOwner(address staker, bytes32 poolId)
        public
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(_delegatedStakeToPoolByOwner[staker][poolId]);
        return balance;
    }

    /// @dev Returns the total stake delegated to a specific staking pool,
    ///      across all members.
    /// @param poolId Unique Id of pool.
    /// @return balance Total stake delegated to pool.
    function getTotalStakeDelegatedToPool(bytes32 poolId)
        public
        view
        override
        returns (IStructs.StoredBalance memory balance)
    {
        balance = _loadCurrentBalance(_delegatedStakeByPoolId[poolId]);
        return balance;
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;

import "../../utils/0xUtils/LibRichErrors.sol";
import "../../utils/0xUtils/LibSafeMathRichErrors.sol";


library LibSafeDowncast {

    /// @dev Safely downcasts to a uint96
    /// Note that this reverts if the input value is too large.
    function downcastToUint96(uint256 a)
        internal
        pure
        returns (uint96 b)
    {
        b = uint96(a);
        if (uint256(b) != a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256DowncastError(
                LibSafeMathRichErrors.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96,
                a
            ));
        }
        return b;
    }

    /// @dev Safely downcasts to a uint64
    /// Note that this reverts if the input value is too large.
    function downcastToUint64(uint256 a)
        internal
        pure
        returns (uint64 b)
    {
        b = uint64(a);
        if (uint256(b) != a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256DowncastError(
                LibSafeMathRichErrors.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
                a
            ));
        }
        return b;
    }

    /// @dev Safely downcasts to a uint32
    /// Note that this reverts if the input value is too large.
    function downcastToUint32(uint256 a)
        internal
        pure
        returns (uint32 b)
    {
        b = uint32(a);
        if (uint256(b) != a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256DowncastError(
                LibSafeMathRichErrors.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
                a
            ));
        }
        return b;
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/IEtherToken.sol";
import "../interfaces/IGrgVault.sol";
import "../interfaces/IStaking.sol";
import "../../protocol/DragoRegistry/IDragoRegistry.sol";
import "../../rigoToken/RigoToken/RigoTokenFace.sol";


// solhint-disable separate-by-one-line-in-contract
abstract contract MixinDeploymentConstants is IStaking {

    // Mainnet GrgVault address
    address constant private GRG_VAULT_ADDRESS = address(0x0a33744eE5D57d6d69944213d8E6ad80d64Fdc58);

    // Ropsten GrgVault address
    // address constant private GRG_VAULT_ADDRESS = address(0x8bd3132B2C6Bb8A2776315134fE5B0B08a1A6035);
    
    // Mainnet DragoRegistry address
    address constant private DRAGO_REGISTRY_ADDRESS = address(0xdE6445484a8dcD9bf35fC95eb4E3990Cc358822e);
    
    // Ropsten DragoRegistry address
    // address constant private DRAGO_REGISTRY_ADDRESS = address(0x4e868D1dDF940316964eA7673E21bE6CBED8b30B);
    
    // Mainnet GRG Address
    address constant private GRG_ADDRESS = address(0x4FbB350052Bca5417566f188eB2EBCE5b19BC964);

    // Ropsten GRG Address
    // address constant private GRG_ADDRESS = address(0x6FA8590920c5966713b1a86916f7b0419411e474);

    /// @dev An overridable way to access the deployed grgVault.
    ///      Must be view to allow overrides to access state.
    /// @return grgVault The grgVault contract.
    function getGrgVault()
        public
        view
        virtual
        override
        returns (IGrgVault grgVault)
    {
        grgVault = IGrgVault(GRG_VAULT_ADDRESS);
        return grgVault;
    }
    
    /// @dev An overridable way to access the deployed dragoRegistry.
    ///      Must be view to allow overrides to access state.
    /// @return dragoRegistry The dragoRegistry contract.
    function getDragoRegistry()
        public
        view
        virtual
        override
        returns (IDragoRegistry dragoRegistry)
    {
        dragoRegistry = IDragoRegistry(DRAGO_REGISTRY_ADDRESS);
        return dragoRegistry;
    }
    
    /// @dev An overridable way to access the deployed GRG contract.
    ///      Must be view to allow overrides to access state.
    /// @return grgContract The GRG contract instance.
    function getGrgContract()
        public
        view
        virtual
        override
        returns (RigoTokenFace grgContract)
    {
        grgContract = RigoTokenFace(GRG_ADDRESS);
        return grgContract;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >= 0.5.9;

import "./IERC20Token.sol";


abstract contract IEtherToken is
    IERC20Token
{
    function deposit()
        public
        virtual
        payable;

    function withdraw(uint256 amount)
        public
        virtual;
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../libs/LibSafeDowncast.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../interfaces/IStructs.sol";
import "../sys/MixinScheduler.sol";


/// @dev This mixin contains logic for managing stake storage.
abstract contract MixinStakeStorage is
    MixinScheduler
{
    using LibSafeMath for uint256;
    using LibSafeDowncast for uint256;

    /// @dev Moves stake between states: 'undelegated' or 'delegated'.
    ///      This change comes into effect next epoch.
    /// @param fromPtr pointer to storage location of `from` stake.
    /// @param toPtr pointer to storage location of `to` stake.
    /// @param amount of stake to move.
    function _moveStake(
        IStructs.StoredBalance storage fromPtr,
        IStructs.StoredBalance storage toPtr,
        uint256 amount
    )
        internal
    {
        // do nothing if pointers are equal
        if (_arePointersEqual(fromPtr, toPtr)) {
            return;
        }

        // load current balances from storage
        IStructs.StoredBalance memory from = _loadCurrentBalance(fromPtr);
        IStructs.StoredBalance memory to = _loadCurrentBalance(toPtr);

        // sanity check on balance
        if (amount > from.nextEpochBalance) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InsufficientBalanceError(
                    amount,
                    from.nextEpochBalance
                )
            );
        }

        // move stake for next epoch
        from.nextEpochBalance = uint256(from.nextEpochBalance).safeSub(amount).downcastToUint96();
        to.nextEpochBalance = uint256(to.nextEpochBalance).safeAdd(amount).downcastToUint96();

        // update state in storage
        _storeBalance(fromPtr, from);
        _storeBalance(toPtr, to);
    }

    /// @dev Loads a balance from storage and updates its fields to reflect values for the current epoch.
    /// @param balancePtr to load.
    /// @return balance current balance.
    function _loadCurrentBalance(IStructs.StoredBalance storage balancePtr)
        internal
        view
        returns (IStructs.StoredBalance memory balance)
    {
        balance = balancePtr;
        uint256 currentEpoch_ = currentEpoch;
        if (currentEpoch_ > balance.currentEpoch) {
            balance.currentEpoch = currentEpoch_.downcastToUint64();
            balance.currentEpochBalance = balance.nextEpochBalance;
        }
        return balance;
    }

    /// @dev Increments both the `current` and `next` fields.
    /// @param balancePtr storage pointer to balance.
    /// @param amount to mint.
    function _increaseCurrentAndNextBalance(IStructs.StoredBalance storage balancePtr, uint256 amount)
        internal
    {
        // Remove stake from balance
        IStructs.StoredBalance memory balance = _loadCurrentBalance(balancePtr);
        balance.nextEpochBalance = uint256(balance.nextEpochBalance).safeAdd(amount).downcastToUint96();
        balance.currentEpochBalance = uint256(balance.currentEpochBalance).safeAdd(amount).downcastToUint96();

        // update state
        _storeBalance(balancePtr, balance);
    }

    /// @dev Decrements both the `current` and `next` fields.
    /// @param balancePtr storage pointer to balance.
    /// @param amount to mint.
    function _decreaseCurrentAndNextBalance(IStructs.StoredBalance storage balancePtr, uint256 amount)
        internal
    {
        // Remove stake from balance
        IStructs.StoredBalance memory balance = _loadCurrentBalance(balancePtr);
        balance.nextEpochBalance = uint256(balance.nextEpochBalance).safeSub(amount).downcastToUint96();
        balance.currentEpochBalance = uint256(balance.currentEpochBalance).safeSub(amount).downcastToUint96();

        // update state
        _storeBalance(balancePtr, balance);
    }

    /// @dev Increments the `next` field (but not the `current` field).
    /// @param balancePtr storage pointer to balance.
    /// @param amount to increment by.
    function _increaseNextBalance(IStructs.StoredBalance storage balancePtr, uint256 amount)
        internal
    {
        // Add stake to balance
        IStructs.StoredBalance memory balance = _loadCurrentBalance(balancePtr);
        balance.nextEpochBalance = uint256(balance.nextEpochBalance).safeAdd(amount).downcastToUint96();

        // update state
        _storeBalance(balancePtr, balance);
    }

    /// @dev Decrements the `next` field (but not the `current` field).
    /// @param balancePtr storage pointer to balance.
    /// @param amount to decrement by.
    function _decreaseNextBalance(IStructs.StoredBalance storage balancePtr, uint256 amount)
        internal
    {
        // Remove stake from balance
        IStructs.StoredBalance memory balance = _loadCurrentBalance(balancePtr);
        balance.nextEpochBalance = uint256(balance.nextEpochBalance).safeSub(amount).downcastToUint96();

        // update state
        _storeBalance(balancePtr, balance);
    }

    /// @dev Stores a balance in storage.
    /// @param balancePtr points to where `balance` will be stored.
    /// @param balance to save to storage.
    function _storeBalance(
        IStructs.StoredBalance storage balancePtr,
        IStructs.StoredBalance memory balance
    )
        private
    {
        // note - this compresses into a single `sstore` when optimizations are enabled,
        // since the StoredBalance struct occupies a single word of storage.
        balancePtr.currentEpoch = balance.currentEpoch;
        balancePtr.nextEpochBalance = balance.nextEpochBalance;
        balancePtr.currentEpochBalance = balance.currentEpochBalance;
    }

    /// @dev Returns true iff storage pointers resolve to same storage location.
    /// @param balancePtrA first storage pointer.
    /// @param balancePtrB second storage pointer.
    /// @return areEqual true iff pointers are equal.
    function _arePointersEqual(
        // solhint-disable-next-line no-unused-vars
        IStructs.StoredBalance storage balancePtrA,
        // solhint-disable-next-line no-unused-vars
        IStructs.StoredBalance storage balancePtrB
    )
        private
        pure
        returns (bool areEqual)
    {
        assembly {
            areEqual := and(
                eq(balancePtrA.slot, balancePtrB.slot),
                eq(balancePtrA.offset, balancePtrB.offset)
            )
        }
        return areEqual;
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibRichErrors.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../libs/LibStakingRichErrors.sol";
import "../immutable/MixinStorage.sol";
import "../interfaces/IStakingEvents.sol";
import "../interfaces/IStaking.sol";


abstract contract MixinScheduler is
    IStaking,
    IStakingEvents,
    MixinStorage
{
    using LibSafeMath for uint256;

    /// @dev Returns the earliest end time in seconds of this epoch.
    ///      The next epoch can begin once this time is reached.
    ///      Epoch period = [startTimeInSeconds..endTimeInSeconds)
    /// @return Time in seconds.
    function getCurrentEpochEarliestEndTimeInSeconds()
        public
        view
        override
        returns (uint256)
    {
        return currentEpochStartTimeInSeconds.safeAdd(epochDurationInSeconds);
    }

    /// @dev Initializes state owned by this mixin.
    ///      Fails if state was already initialized.
    function _initMixinScheduler()
        internal
    {
        // assert the current values before overwriting them.
        _assertSchedulerNotInitialized();

        // solhint-disable-next-line
        currentEpochStartTimeInSeconds = block.timestamp;
        currentEpoch = 1;
    }

    /// @dev Moves to the next epoch, given the current epoch period has ended.
    ///      Time intervals that are measured in epochs (like timeLocks) are also incremented, given
    ///      their periods have ended.
    function _goToNextEpoch()
        internal
    {
        // get current timestamp
        // solhint-disable-next-line not-rely-on-time
        uint256 currentBlockTimestamp = block.timestamp;

        // validate that we can increment the current epoch
        uint256 epochEndTime = getCurrentEpochEarliestEndTimeInSeconds();
        if (epochEndTime > currentBlockTimestamp) {
            LibRichErrors.rrevert(LibStakingRichErrors.BlockTimestampTooLowError(
                epochEndTime,
                currentBlockTimestamp
            ));
        }

        // incremment epoch
        uint256 nextEpoch = currentEpoch.safeAdd(1);
        currentEpoch = nextEpoch;
        currentEpochStartTimeInSeconds = currentBlockTimestamp;
    }

    /// @dev Assert scheduler state before initializing it.
    /// This must be updated for each migration.
    function _assertSchedulerNotInitialized()
        internal
        view
    {
        if (currentEpochStartTimeInSeconds != 0) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InitializationError(
                    LibStakingRichErrors.InitializationErrorCodes.MixinSchedulerAlreadyInitialized
                )
            );
        }
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibMath.sol";
import "../../utils/0xUtils/LibRichErrors.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../libs/LibStakingRichErrors.sol";
import "../interfaces/IStructs.sol";
import "../sys/MixinFinalizer.sol";
import "../staking_pools/MixinStakingPool.sol";
import "./MixinPopManager.sol";


abstract contract MixinPopRewards is
    MixinPopManager,
    MixinStakingPool,
    MixinFinalizer
{
    using LibSafeMath for uint256;

    /// @dev Credits the value of a pool's pop reward.
    ///      Only a known RigoBlock pop can call this method. See
    ///      (MixinPopManager).
    /// @param poolAccount The address of the rigoblock pool account.
    /// @param popReward The pop reward.
    function creditPopReward(
        address poolAccount,
        uint256 popReward
    )
        external
        payable
        override
        onlyPop
    {
        // Get the pool id of the maker address.
        bytes32 poolId = poolIdByRbPoolAccount[poolAccount];

        // Only attribute the pop reward to a pool if the pool account is
        // registered to a pool.
        if (poolId == NIL_POOL_ID) {
            return;
        }

        uint256 poolStake = getTotalStakeDelegatedToPool(poolId).currentEpochBalance;
        // Ignore pools with dust stake.
        if (poolStake < minimumPoolStake) {
            return;
        }

        // Look up the pool stats and aggregated stats for this epoch.
        uint256 currentEpoch_ = currentEpoch;
        IStructs.PoolStats storage poolStatsPtr = poolStatsByEpoch[poolId][currentEpoch_];
        IStructs.AggregatedStats storage aggregatedStatsPtr = aggregatedStatsByEpoch[currentEpoch_];

        // Perform some initialization if this is the pool's first protocol fee in this epoch.
        uint256 feesCollectedByPool = poolStatsPtr.feesCollected;
        if (feesCollectedByPool == 0) {
            // Compute member and total weighted stake.
            (uint256 membersStakeInPool, uint256 weightedStakeInPool) = _computeMembersAndWeightedStake(poolId, poolStake);
            poolStatsPtr.membersStake = membersStakeInPool;
            poolStatsPtr.weightedStake = weightedStakeInPool;

            // Increase the total weighted stake.
            aggregatedStatsPtr.totalWeightedStake = aggregatedStatsPtr.totalWeightedStake.safeAdd(weightedStakeInPool);

            // Increase the number of pools to finalize.
            aggregatedStatsPtr.numPoolsToFinalize = aggregatedStatsPtr.numPoolsToFinalize.safeAdd(1);

            // Emit an event so keepers know what pools earned rewards this epoch.
            emit StakingPoolEarnedRewardsInEpoch(currentEpoch_, poolId);
        }

        if (popReward > feesCollectedByPool) {
            // Credit the fees to the pool.
            poolStatsPtr.feesCollected = popReward;

            // Increase the total fees collected this epoch.
            aggregatedStatsPtr.totalFeesCollected = aggregatedStatsPtr
                .totalFeesCollected
                .safeAdd(popReward)
                .safeSub(feesCollectedByPool);
        }
    }

    /// @dev Get stats on a staking pool in this epoch.
    /// @param poolId Pool Id to query.
    /// @return PoolStats struct for pool id.
    function getStakingPoolStatsThisEpoch(bytes32 poolId)
        external
        view
        override
        returns (IStructs.PoolStats memory)
    {
        return poolStatsByEpoch[poolId][currentEpoch];
    }

    /// @dev Computes the members and weighted stake for a pool at the current
    ///      epoch.
    /// @param poolId ID of the pool.
    /// @param totalStake Total (unweighted) stake in the pool.
    /// @return membersStake Non-operator stake in the pool.
    /// @return weightedStake Weighted stake of the pool.
    function _computeMembersAndWeightedStake(
        bytes32 poolId,
        uint256 totalStake
    )
        private
        view
        returns (uint256 membersStake, uint256 weightedStake)
    {
        uint256 operatorStake = getStakeDelegatedToPoolByOwner(
            _poolById[poolId].operator,
            poolId
        ).currentEpochBalance;

        membersStake = totalStake.safeSub(operatorStake);
        weightedStake = operatorStake.safeAdd(
            LibMath.getPartialAmountFloor(
                rewardDelegatedStakeWeight,
                PPM_DENOMINATOR,
                membersStake
            )
        );
        return (membersStake, weightedStake);
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibRichErrors.sol";
import "../../utils/0xUtils/LibSafeMath.sol";
import "../libs/LibCobbDouglas.sol";
import "../libs/LibStakingRichErrors.sol";
import "../interfaces/IStructs.sol";
import "../staking_pools/MixinStakingPoolRewards.sol";


abstract contract MixinFinalizer is
    MixinStakingPoolRewards
{
    using LibSafeMath for uint256;

    /// @dev Begins a new epoch, preparing the prior one for finalization.
    ///      Throws if not enough time has passed between epochs or if the
    ///      previous epoch was not fully finalized.
    /// @return numPoolsToFinalize The number of unfinalized pools.
    function endEpoch()
        external
        override
        returns (uint256)
    {
        uint256 currentEpoch_ = currentEpoch;
        uint256 prevEpoch = currentEpoch_.safeSub(1);

        // Make sure the previous epoch has been fully finalized.
        uint256 numPoolsToFinalizeFromPrevEpoch = aggregatedStatsByEpoch[prevEpoch].numPoolsToFinalize;
        if (numPoolsToFinalizeFromPrevEpoch != 0) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.PreviousEpochNotFinalizedError(
                    prevEpoch,
                    numPoolsToFinalizeFromPrevEpoch
                )
            );
        }

        // mint epoch inflation, jump first epoch as all regitered pool accounts will become active from following epoch
        //  mint happens before time has passed check, therefore tokens will be allocated even before expiry if method is called
        //  but will not be minted again until epoch time has passed. This could happen when epoch length is changed only.
        if (currentEpoch_ > uint256(1)) {
            try InflationFace(getGrgContract().minter()).mintInflation() returns (uint256 mintedInflation) {
                return (mintedInflation);
            } catch Error(string memory) {
                return (0);
            } catch (bytes memory) {
                return (0);
            }
        }

        // TODO: test
        // Load aggregated stats for the epoch we're ending.
        aggregatedStatsByEpoch[currentEpoch_].rewardsAvailable = _getAvailableGrgBalance();
        IStructs.AggregatedStats memory aggregatedStats = aggregatedStatsByEpoch[currentEpoch_];

        // Emit an event.
        emit EpochEnded(
            currentEpoch_,
            aggregatedStats.numPoolsToFinalize,
            aggregatedStats.rewardsAvailable,
            aggregatedStats.totalFeesCollected,
            aggregatedStats.totalWeightedStake
        );

        // Advance the epoch. This will revert if not enough time has passed.
        _goToNextEpoch();

        // If there are no pools to finalize then the epoch is finalized.
        if (aggregatedStats.numPoolsToFinalize == 0) {
            emit EpochFinalized(currentEpoch_, 0, aggregatedStats.rewardsAvailable);
        }

        return aggregatedStats.numPoolsToFinalize;
    }

    /// @dev Instantly finalizes a single pool that earned rewards in the previous
    ///      epoch, crediting it rewards for members and withdrawing operator's
    ///      rewards as WETH. This can be called by internal functions that need
    ///      to finalize a pool immediately. Does nothing if the pool is already
    ///      finalized or did not earn rewards in the previous epoch.
    /// @param poolId The pool ID to finalize.
    function finalizePool(bytes32 poolId)
        external
        override
    {
        // Compute relevant epochs
        uint256 currentEpoch_ = currentEpoch;
        uint256 prevEpoch = currentEpoch_.safeSub(1);

        // Load the aggregated stats into memory; noop if no pools to finalize.
        IStructs.AggregatedStats memory aggregatedStats = aggregatedStatsByEpoch[prevEpoch];
        if (aggregatedStats.numPoolsToFinalize == 0) {
            return;
        }

        // Noop if the pool did not earn rewards or already finalized (has no fees).
        IStructs.PoolStats memory poolStats = poolStatsByEpoch[poolId][prevEpoch];
        if (poolStats.feesCollected == 0) {
            return;
        }

        // Clear the pool stats so we don't finalize it again, and to recoup
        // some gas.
        delete poolStatsByEpoch[poolId][prevEpoch];

        // Compute the rewards.
        uint256 rewards = _getUnfinalizedPoolRewardsFromPoolStats(poolStats, aggregatedStats);

        // Pay the operator and update rewards for the pool.
        // Note that we credit at the CURRENT epoch even though these rewards
        // were earned in the previous epoch.
        (uint256 operatorReward, uint256 membersReward) = _syncPoolRewards(
            poolId,
            rewards,
            poolStats.membersStake
        );

        // Emit an event.
        emit RewardsPaid(
            currentEpoch_,
            poolId,
            operatorReward,
            membersReward
        );

        uint256 totalReward = operatorReward.safeAdd(membersReward);

        // Increase `totalRewardsFinalized`.
        aggregatedStatsByEpoch[prevEpoch].totalRewardsFinalized =
            aggregatedStats.totalRewardsFinalized =
            aggregatedStats.totalRewardsFinalized.safeAdd(totalReward);

        // Decrease the number of unfinalized pools left.
        aggregatedStatsByEpoch[prevEpoch].numPoolsToFinalize =
            aggregatedStats.numPoolsToFinalize =
            aggregatedStats.numPoolsToFinalize.safeSub(1);

        // If there are no more unfinalized pools remaining, the epoch is
        // finalized.
        if (aggregatedStats.numPoolsToFinalize == 0) {
            emit EpochFinalized(
                prevEpoch,
                aggregatedStats.totalRewardsFinalized,
                aggregatedStats.rewardsAvailable.safeSub(aggregatedStats.totalRewardsFinalized)
            );
        }
    }

    /// @dev Computes the reward owed to a pool during finalization.
    ///      Does nothing if the pool is already finalized.
    /// @param poolId The pool's ID.
    /// @return reward The total reward owed to a pool.
    /// @return membersStake The total stake for all non-operator members in
    ///         this pool.
    function _getUnfinalizedPoolRewards(bytes32 poolId)
        internal
        view
        virtual
        override
        returns (
            uint256 reward,
            uint256 membersStake
        )
    {
        uint256 prevEpoch = currentEpoch.safeSub(1);
        IStructs.PoolStats memory poolStats = poolStatsByEpoch[poolId][prevEpoch];
        reward = _getUnfinalizedPoolRewardsFromPoolStats(poolStats, aggregatedStatsByEpoch[prevEpoch]);
        membersStake = poolStats.membersStake;
    }

    /// @dev Returns the GRG balance of this contract, minus
    ///      any GRG that has already been reserved for rewards.
    function _getAvailableGrgBalance()
        internal
        view
        returns (uint256 grgBalance)
    {
        grgBalance = getGrgContract().balanceOf(address(this))
            .safeSub(grgReservedForPoolRewards);

        return grgBalance;
    }

    /// @dev Asserts that a pool has been finalized last epoch.
    /// @param poolId The id of the pool that should have been finalized.
    function _assertPoolFinalizedLastEpoch(bytes32 poolId)
        internal
        view
        virtual
        override
    {
        uint256 prevEpoch = currentEpoch.safeSub(1);
        IStructs.PoolStats memory poolStats = poolStatsByEpoch[poolId][prevEpoch];

        // A pool that has any fees remaining has not been finalized
        if (poolStats.feesCollected != 0) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.PoolNotFinalizedError(
                    poolId,
                    prevEpoch
                )
            );
        }
    }

    /// @dev Computes the reward owed to a pool during finalization.
    /// @param poolStats Stats for a specific pool.
    /// @param aggregatedStats Stats aggregated across all pools.
    /// @return rewards Unfinalized rewards for the input pool.
    function _getUnfinalizedPoolRewardsFromPoolStats(
        IStructs.PoolStats memory poolStats,
        IStructs.AggregatedStats memory aggregatedStats
    )
        private
        view
        returns (uint256 rewards)
    {
        // There can't be any rewards if the pool did not collect any fees.
        if (poolStats.feesCollected == 0) {
            return rewards;
        }

        // Use the cobb-douglas function to compute the total reward.
        rewards = LibCobbDouglas.cobbDouglas(
            aggregatedStats.rewardsAvailable,
            poolStats.feesCollected,
            aggregatedStats.totalFeesCollected,
            poolStats.weightedStake,
            aggregatedStats.totalWeightedStake,
            cobbDouglasAlphaNumerator,
            cobbDouglasAlphaDenominator
        );

        // Clip the reward to always be under
        // `rewardsAvailable - totalRewardsPaid`,
        // in case cobb-douglas overflows, which should be unlikely.
        uint256 rewardsRemaining = aggregatedStats.rewardsAvailable.safeSub(aggregatedStats.totalRewardsFinalized);
        if (rewardsRemaining < rewards) {
            rewards = rewardsRemaining;
        }
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "./LibFixedMath.sol";


library LibCobbDouglas {

    /// @dev The cobb-douglas function used to compute fee-based rewards for
    ///      staking pools in a given epoch. This function does not perform
    ///      bounds checking on the inputs, but the following conditions
    ///      need to be true:
    ///         0 <= fees / totalFees <= 1
    ///         0 <= stake / totalStake <= 1
    ///         0 <= alphaNumerator / alphaDenominator <= 1
    /// @param totalRewards collected over an epoch.
    /// @param fees Fees attributed to the the staking pool.
    /// @param totalFees Total fees collected across all pools that earned rewards.
    /// @param stake Stake attributed to the staking pool.
    /// @param totalStake Total stake across all pools that earned rewards.
    /// @param alphaNumerator Numerator of `alpha` in the cobb-douglas function.
    /// @param alphaDenominator Denominator of `alpha` in the cobb-douglas
    ///        function.
    /// @return rewards Rewards owed to the staking pool.
    function cobbDouglas(
        uint256 totalRewards,
        uint256 fees,
        uint256 totalFees,
        uint256 stake,
        uint256 totalStake,
        uint32 alphaNumerator,
        uint32 alphaDenominator
    )
        internal
        pure
        returns (uint256 rewards)
    {
        int256 feeRatio = LibFixedMath.toFixed(fees, totalFees);
        int256 stakeRatio = LibFixedMath.toFixed(stake, totalStake);
        if (feeRatio == 0 || stakeRatio == 0) {
            return rewards = 0;
        }
        // The cobb-doublas function has the form:
        // `totalRewards * feeRatio ^ alpha * stakeRatio ^ (1-alpha)`
        // This is equivalent to:
        // `totalRewards * stakeRatio * e^(alpha * (ln(feeRatio / stakeRatio)))`
        // However, because `ln(x)` has the domain of `0 < x < 1`
        // and `exp(x)` has the domain of `x < 0`,
        // and fixed-point math easily overflows with multiplication,
        // we will choose the following if `stakeRatio > feeRatio`:
        // `totalRewards * stakeRatio / e^(alpha * (ln(stakeRatio / feeRatio)))`

        // Compute
        // `e^(alpha * ln(feeRatio/stakeRatio))` if feeRatio <= stakeRatio
        // or
        // `e^(alpa * ln(stakeRatio/feeRatio))` if feeRatio > stakeRatio
        int256 n = feeRatio <= stakeRatio ?
            LibFixedMath.div(feeRatio, stakeRatio) :
            LibFixedMath.div(stakeRatio, feeRatio);
        n = LibFixedMath.exp(
            LibFixedMath.mulDiv(
                LibFixedMath.ln(n),
                int256(alphaNumerator),
                int256(alphaDenominator)
            )
        );
        // Compute
        // `totalRewards * n` if feeRatio <= stakeRatio
        // or
        // `totalRewards / n` if stakeRatio > feeRatio
        // depending on the choice we made earlier.
        n = feeRatio <= stakeRatio ?
            LibFixedMath.mul(stakeRatio, n) :
            LibFixedMath.div(stakeRatio, n);
        // Multiply the above with totalRewards.
        rewards = LibFixedMath.uintMul(n, totalRewards);
    }
}

/*

  Copyright 2017 Bprotocol Foundation, 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;

import "./LibFixedMathRichErrors.sol";


// solhint-disable indent
/// @dev Signed, fixed-point, 127-bit precision math library.
library LibFixedMath {

    // 1
    int256 private constant FIXED_1 = int256(0x0000000000000000000000000000000080000000000000000000000000000000);
    // 2**255
    int256 private constant MIN_FIXED_VAL = int256(0x8000000000000000000000000000000000000000000000000000000000000000);
    // 1^2 (in fixed-point)
    int256 private constant FIXED_1_SQUARED = int256(0x4000000000000000000000000000000000000000000000000000000000000000);
    // 1
    int256 private constant LN_MAX_VAL = FIXED_1;
    // e ^ -63.875
    int256 private constant LN_MIN_VAL = int256(0x0000000000000000000000000000000000000000000000000000000733048c5a);
    // 0
    int256 private constant EXP_MAX_VAL = 0;
    // -63.875
    int256 private constant EXP_MIN_VAL = -int256(0x0000000000000000000000000000001ff0000000000000000000000000000000);

    /// @dev Get one as a fixed-point number.
    function one() internal pure returns (int256 f) {
        f = FIXED_1;
    }

    /// @dev Returns the addition of two fixed point numbers, reverting on overflow.
    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = _add(a, b);
    }

    /// @dev Returns the addition of two fixed point numbers, reverting on overflow.
    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        if (b == MIN_FIXED_VAL) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.SignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_SMALL,
                b
            ));
        }
        c = _add(a, -b);
    }

    /// @dev Returns the multiplication of two fixed point numbers, reverting on overflow.
    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = _mul(a, b) / FIXED_1;
    }

    /// @dev Returns the division of two fixed point numbers.
    function div(int256 a, int256 b) internal pure returns (int256 c) {
        c = _div(_mul(a, FIXED_1), b);
    }

    /// @dev Performs (a * n) / d, without scaling for precision.
    function mulDiv(int256 a, int256 n, int256 d) internal pure returns (int256 c) {
        c = _div(_mul(a, n), d);
    }

    /// @dev Returns the unsigned integer result of multiplying a fixed-point
    ///      number with an integer, reverting if the multiplication overflows.
    ///      Negative results are clamped to zero.
    function uintMul(int256 f, uint256 u) internal pure returns (uint256) {
        if (int256(u) < int256(0)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.UnsignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                u
            ));
        }
        int256 c = _mul(f, int256(u));
        if (c <= 0) {
            return 0;
        }
        return uint256(uint256(c) >> 127);
    }

    /// @dev Returns the absolute value of a fixed point number.
    function abs(int256 f) internal pure returns (int256 c) {
        if (f == MIN_FIXED_VAL) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.SignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_SMALL,
                f
            ));
        }
        if (f >= 0) {
            c = f;
        } else {
            c = -f;
        }
    }

    /// @dev Returns 1 / `x`, where `x` is a fixed-point number.
    function invert(int256 f) internal pure returns (int256 c) {
        c = _div(FIXED_1_SQUARED, f);
    }

    /// @dev Convert signed `n` / 1 to a fixed-point number.
    function toFixed(int256 n) internal pure returns (int256 f) {
        f = _mul(n, FIXED_1);
    }

    /// @dev Convert signed `n` / `d` to a fixed-point number.
    function toFixed(int256 n, int256 d) internal pure returns (int256 f) {
        f = _div(_mul(n, FIXED_1), d);
    }

    /// @dev Convert unsigned `n` / 1 to a fixed-point number.
    ///      Reverts if `n` is too large to fit in a fixed-point number.
    function toFixed(uint256 n) internal pure returns (int256 f) {
        if (int256(n) < int256(0)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.UnsignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                n
            ));
        }
        f = _mul(int256(n), FIXED_1);
    }

    /// @dev Convert unsigned `n` / `d` to a fixed-point number.
    ///      Reverts if `n` / `d` is too large to fit in a fixed-point number.
    function toFixed(uint256 n, uint256 d) internal pure returns (int256 f) {
        if (int256(n) < int256(0)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.UnsignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                n
            ));
        }
        if (int256(d) < int256(0)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.UnsignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                d
            ));
        }
        f = _div(_mul(int256(n), FIXED_1), int256(d));
    }

    /// @dev Convert a fixed-point number to an integer.
    function toInteger(int256 f) internal pure returns (int256 n) {
        return f / FIXED_1;
    }

    /// @dev Get the natural logarithm of a fixed-point number 0 < `x` <= LN_MAX_VAL
    function ln(int256 x) internal pure returns (int256 r) {
        if (x > LN_MAX_VAL) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.SignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                x
            ));
        }
        if (x <= 0) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.SignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_SMALL,
                x
            ));
        }
        if (x == FIXED_1) {
            return 0;
        }
        if (x <= LN_MIN_VAL) {
            return EXP_MIN_VAL;
        }

        int256 y;
        int256 z;
        int256 w;

        // Rewrite the input as a quotient of negative natural exponents and a single residual q, such that 1 < q < 2
        // For example: log(0.3) = log(e^-1 * e^-0.25 * 1.0471028872385522)
        //              = 1 - 0.25 - log(1 + 0.0471028872385522)
        // e ^ -32
        if (x <= int256(0x00000000000000000000000000000000000000000001c8464f76164760000000)) {
            r -= int256(0x0000000000000000000000000000001000000000000000000000000000000000); // - 32
            x = x * FIXED_1 / int256(0x00000000000000000000000000000000000000000001c8464f76164760000000); // / e ^ -32
        }
        // e ^ -16
        if (x <= int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000)) {
            r -= int256(0x0000000000000000000000000000000800000000000000000000000000000000); // - 16
            x = x * FIXED_1 / int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000); // / e ^ -16
        }
        // e ^ -8
        if (x <= int256(0x00000000000000000000000000000000000afe10820813d78000000000000000)) {
            r -= int256(0x0000000000000000000000000000000400000000000000000000000000000000); // - 8
            x = x * FIXED_1 / int256(0x00000000000000000000000000000000000afe10820813d78000000000000000); // / e ^ -8
        }
        // e ^ -4
        if (x <= int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000)) {
            r -= int256(0x0000000000000000000000000000000200000000000000000000000000000000); // - 4
            x = x * FIXED_1 / int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000); // / e ^ -4
        }
        // e ^ -2
        if (x <= int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000100000000000000000000000000000000); // - 2
            x = x * FIXED_1 / int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000); // / e ^ -2
        }
        // e ^ -1
        if (x <= int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000080000000000000000000000000000000); // - 1
            x = x * FIXED_1 / int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000); // / e ^ -1
        }
        // e ^ -0.5
        if (x <= int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000040000000000000000000000000000000); // - 0.5
            x = x * FIXED_1 / int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000); // / e ^ -0.5
        }
        // e ^ -0.25
        if (x <= int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000020000000000000000000000000000000); // - 0.25
            x = x * FIXED_1 / int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000); // / e ^ -0.25
        }
        // e ^ -0.125
        if (x <= int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) {
            r -= int256(0x0000000000000000000000000000000010000000000000000000000000000000); // - 0.125
            x = x * FIXED_1 / int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d); // / e ^ -0.125
        }
        // `x` is now our residual in the range of 1 <= x <= 2 (or close enough).

        // Add the taylor series for log(1 + z), where z = x - 1
        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        r += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1; // add y^01 / 01 - y^02 / 02
        r += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1; // add y^03 / 03 - y^04 / 04
        r += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1; // add y^05 / 05 - y^06 / 06
        r += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1; // add y^07 / 07 - y^08 / 08
        r += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1; // add y^09 / 09 - y^10 / 10
        r += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1; // add y^11 / 11 - y^12 / 12
        r += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1; // add y^13 / 13 - y^14 / 14
        r += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;                      // add y^15 / 15 - y^16 / 16
    }

    /// @dev Compute the natural exponent for a fixed-point number EXP_MIN_VAL <= `x` <= 1
    function exp(int256 x) internal pure returns (int256 r) {
        if (x < EXP_MIN_VAL) {
            // Saturate to zero below EXP_MIN_VAL.
            return 0;
        }
        if (x == 0) {
            return FIXED_1;
        }
        if (x > EXP_MAX_VAL) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.SignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                x
            ));
        }

        // Rewrite the input as a product of natural exponents and a
        // single residual q, where q is a number of small magnitude.
        // For example: e^-34.419 = e^(-32 - 2 - 0.25 - 0.125 - 0.044)
        //              = e^-32 * e^-2 * e^-0.25 * e^-0.125 * e^-0.044
        //              -> q = -0.044

        // Multiply with the taylor series for e^q
        int256 y;
        int256 z;
        // q = x % 0.125 (the residual)
        z = y = x % 0x0000000000000000000000000000000010000000000000000000000000000000;
        z = z * y / FIXED_1; r += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1; r += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1; r += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1; r += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1; r += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1; r += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1; r += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1; r += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1; r += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1; r += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1; r += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1; r += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1; r += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1; r += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1; r += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1; r += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1; r += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1; r += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1; r += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        r = r / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        // Multiply with the non-residual terms.
        x = -x;
        // e ^ -32
        if ((x & int256(0x0000000000000000000000000000001000000000000000000000000000000000)) != 0) {
            r = r * int256(0x00000000000000000000000000000000000000f1aaddd7742e56d32fb9f99744)
                / int256(0x0000000000000000000000000043cbaf42a000812488fc5c220ad7b97bf6e99e); // * e ^ -32
        }
        // e ^ -16
        if ((x & int256(0x0000000000000000000000000000000800000000000000000000000000000000)) != 0) {
            r = r * int256(0x00000000000000000000000000000000000afe10820813d65dfe6a33c07f738f)
                / int256(0x000000000000000000000000000005d27a9f51c31b7c2f8038212a0574779991); // * e ^ -16
        }
        // e ^ -8
        if ((x & int256(0x0000000000000000000000000000000400000000000000000000000000000000)) != 0) {
            r = r * int256(0x0000000000000000000000000000000002582ab704279e8efd15e0265855c47a)
                / int256(0x0000000000000000000000000000001b4c902e273a58678d6d3bfdb93db96d02); // * e ^ -8
        }
        // e ^ -4
        if ((x & int256(0x0000000000000000000000000000000200000000000000000000000000000000)) != 0) {
            r = r * int256(0x000000000000000000000000000000001152aaa3bf81cb9fdb76eae12d029571)
                / int256(0x00000000000000000000000000000003b1cc971a9bb5b9867477440d6d157750); // * e ^ -4
        }
        // e ^ -2
        if ((x & int256(0x0000000000000000000000000000000100000000000000000000000000000000)) != 0) {
            r = r * int256(0x000000000000000000000000000000002f16ac6c59de6f8d5d6f63c1482a7c86)
                / int256(0x000000000000000000000000000000015bf0a8b1457695355fb8ac404e7a79e3); // * e ^ -2
        }
        // e ^ -1
        if ((x & int256(0x0000000000000000000000000000000080000000000000000000000000000000)) != 0) {
            r = r * int256(0x000000000000000000000000000000004da2cbf1be5827f9eb3ad1aa9866ebb3)
                / int256(0x00000000000000000000000000000000d3094c70f034de4b96ff7d5b6f99fcd8); // * e ^ -1
        }
        // e ^ -0.5
        if ((x & int256(0x0000000000000000000000000000000040000000000000000000000000000000)) != 0) {
            r = r * int256(0x0000000000000000000000000000000063afbe7ab2082ba1a0ae5e4eb1b479dc)
                / int256(0x00000000000000000000000000000000a45af1e1f40c333b3de1db4dd55f29a7); // * e ^ -0.5
        }
        // e ^ -0.25
        if ((x & int256(0x0000000000000000000000000000000020000000000000000000000000000000)) != 0) {
            r = r * int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)
                / int256(0x00000000000000000000000000000000910b022db7ae67ce76b441c27035c6a1); // * e ^ -0.25
        }
        // e ^ -0.125
        if ((x & int256(0x0000000000000000000000000000000010000000000000000000000000000000)) != 0) {
            r = r * int256(0x00000000000000000000000000000000783eafef1c0a8f3978c7f81824d62ebf)
                / int256(0x0000000000000000000000000000000088415abbe9a76bead8d00cf112e4d4a8); // * e ^ -0.125
        }
    }

    /// @dev Returns the multiplication two numbers, reverting on overflow.
    function _mul(int256 a, int256 b) private pure returns (int256 c) {
        if (a == 0 || b == 0) {
            return 0;
        }
        c = a * b;
        if (c / a != b || c / b != a) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.BinOpError(
                LibFixedMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
    }

    /// @dev Returns the division of two numbers, reverting on division by zero.
    function _div(int256 a, int256 b) private pure returns (int256 c) {
        if (b == 0) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.BinOpError(
                LibFixedMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        if (a == MIN_FIXED_VAL && b == -1) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.BinOpError(
                LibFixedMathRichErrors.BinOpErrorCodes.DIVISION_OVERFLOW,
                a,
                b
            ));
        }
        c = a / b;
    }

    /// @dev Adds two numbers, reverting on overflow.
    function _add(int256 a, int256 b) private pure returns (int256 c) {
        c = a + b;
        if ((a < 0 && b < 0 && c > a) || (a > 0 && b > 0 && c < a)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.BinOpError(
                LibFixedMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;

import "../../utils/0xUtils/LibRichErrors.sol";


library LibFixedMathRichErrors {

    enum ValueErrorCodes {
        TOO_SMALL,
        TOO_LARGE
    }

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        DIVISION_BY_ZERO,
        DIVISION_OVERFLOW
    }

    // bytes4(keccak256("SignedValueError(uint8,int256)"))
    bytes4 internal constant SIGNED_VALUE_ERROR_SELECTOR =
        0xed2f26a1;

    // bytes4(keccak256("UnsignedValueError(uint8,uint256)"))
    bytes4 internal constant UNSIGNED_VALUE_ERROR_SELECTOR =
        0xbd79545f;

    // bytes4(keccak256("BinOpError(uint8,int256,int256)"))
    bytes4 internal constant BIN_OP_ERROR_SELECTOR =
        0x8c12dfe7;

    // solhint-disable func-name-mixedcase
    function SignedValueError(
        ValueErrorCodes error,
        int256 n
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SIGNED_VALUE_ERROR_SELECTOR,
            uint8(error),
            n
        );
    }

    function UnsignedValueError(
        ValueErrorCodes error,
        uint256 n
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UNSIGNED_VALUE_ERROR_SELECTOR,
            uint8(error),
            n
        );
    }

    function BinOpError(
        BinOpErrorCodes error,
        int256 a,
        int256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            BIN_OP_ERROR_SELECTOR,
            uint8(error),
            a,
            b
        );
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/LibRichErrors.sol";
import "../libs/LibStakingRichErrors.sol";
import "../interfaces/IStakingEvents.sol";
import "../interfaces/IStaking.sol";
import "../immutable/MixinStorage.sol";


abstract contract MixinPopManager is
    IStaking,
    IStakingEvents,
    MixinStorage
{
    /// @dev Asserts that the call is coming from a valid pop.
    modifier onlyPop() {
        if (!validPops[msg.sender]) {
            LibRichErrors.rrevert(LibStakingRichErrors.OnlyCallableByPopError(
                msg.sender
            ));
        }
        _;
    }

    /// @dev Adds a new pop address.
    /// @param addr Address of pop contract to add.
    function addPopAddress(address addr)
        external
        override
        onlyAuthorized
    {
        if (validPops[addr]) {
            LibRichErrors.rrevert(LibStakingRichErrors.PopManagerError(
                LibStakingRichErrors.PopManagerErrorCodes.PopAlreadyRegistered,
                addr
            ));
        }
        validPops[addr] = true;
        emit PopAdded(addr);
    }

    /// @dev Removes an existing proof_of_performance address.
    /// @param addr Address of proof_of_performance contract to remove.
    function removePopAddress(address addr)
        external
        override
        onlyAuthorized
    {
        if (!validPops[addr]) {
            LibRichErrors.rrevert(LibStakingRichErrors.PopManagerError(
                LibStakingRichErrors.PopManagerErrorCodes.PopNotRegistered,
                addr
            ));
        }
        validPops[addr] = false;
        emit PopRemoved(addr);
    }
}

// SPDX-License-Identifier: Apache 2.0

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./libs/LibSafeDowncast.sol";
import "./immutable/MixinStorage.sol";
import "./immutable/MixinConstants.sol";
import "./interfaces/IStorageInit.sol";
import "./interfaces/IStakingProxy.sol";


/// #dev The RigoBlock Staking contract.
contract StakingProxy is
    IStakingProxy,
    MixinStorage,
    MixinConstants
{
    using LibSafeDowncast for uint256;

    /// @dev Constructor.
    /// @param _stakingContract Staking contract to delegate calls to.
    constructor(address _stakingContract)
        MixinStorage()
    {
        // Deployer address must be authorized in order to call `init`
        _addAuthorizedAddress(msg.sender);

        // Attach the staking contract and initialize state
        _attachStakingContract(_stakingContract);

        // Remove the sender as an authorized address
        _removeAuthorizedAddressAtIndex(msg.sender, 0);
    }

    /// @dev Delegates calls to the staking contract, if it is set.
    receive()
        external
        payable
    {
        // Sanity check that we have a staking contract to call
        address stakingContract_ = stakingContract;
        if (stakingContract_ == NIL_ADDRESS) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.ProxyDestinationCannotBeNilError()
            );
        }

        // Call the staking contract with the provided calldata.
        (bool success, bytes memory returnData) = stakingContract_.delegatecall(msg.data);

        // Revert on failure or return on success.
        assembly {
            switch success
            case 0 {
                revert(add(0x20, returnData), mload(returnData))
            }
            default {
                return(add(0x20, returnData), mload(returnData))
            }
        }
    }

    /// @dev Attach a staking contract; future calls will be delegated to the staking contract.
    /// Note that this is callable only by an authorized address.
    /// @param _stakingContract Address of staking contract.
    function attachStakingContract(address _stakingContract)
        external
        override
        onlyAuthorized
    {
        _attachStakingContract(_stakingContract);
    }

    /// @dev Detach the current staking contract.
    /// Note that this is callable only by an authorized address.
    function detachStakingContract()
        external
        override
        onlyAuthorized
    {
        stakingContract = NIL_ADDRESS;
        emit StakingContractDetachedFromProxy();
    }

    /// @dev Batch executes a series of calls to the staking contract.
    /// @param data An array of data that encodes a sequence of functions to
    ///             call in the staking contracts.
    function batchExecute(bytes[] calldata data)
        external
        returns (bytes[] memory batchReturnData)
    {
        // Initialize commonly used variables.
        bool success;
        bytes memory returnData;
        uint256 dataLength = data.length;
        batchReturnData = new bytes[](dataLength);
        address staking = stakingContract;

        // Ensure that a staking contract has been attached to the proxy.
        if (staking == NIL_ADDRESS) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.ProxyDestinationCannotBeNilError()
            );
        }

        // Execute all of the calls encoded in the provided calldata.
        for (uint256 i = 0; i != dataLength; i++) {
            // Call the staking contract with the provided calldata.
            (success, returnData) = staking.delegatecall(data[i]);

            // Revert on failure.
            if (!success) {
                assembly {
                    revert(add(0x20, returnData), mload(returnData))
                }
            }

            // Add the returndata to the batch returndata.
            batchReturnData[i] = returnData;
        }

        return batchReturnData;
    }

    /// @dev Asserts that an epoch is between 5 and 90 days long.
    //       Asserts that 0 < cobb douglas alpha value <= 1.
    //       Asserts that a stake weight is <= 100%.
    //       Asserts that pools allow >= 1 maker.
    //       Asserts that all addresses are initialized.
    function assertValidStorageParams()
        public
        view
        override
    {
        // Epoch length must be between 5 and 90 days long
        uint256 _epochDurationInSeconds = epochDurationInSeconds;
        if (_epochDurationInSeconds < 5 minutes || _epochDurationInSeconds > 90 days) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InvalidParamValueError(
                    LibStakingRichErrors.InvalidParamValueErrorCodes.InvalidEpochDuration
            ));
        }

        // Alpha must be 0 < x <= 1
        uint32 _cobbDouglasAlphaDenominator = cobbDouglasAlphaDenominator;
        if (cobbDouglasAlphaNumerator > _cobbDouglasAlphaDenominator || _cobbDouglasAlphaDenominator == 0) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InvalidParamValueError(
                    LibStakingRichErrors.InvalidParamValueErrorCodes.InvalidCobbDouglasAlpha
            ));
        }

        // Weight of delegated stake must be <= 100%
        if (rewardDelegatedStakeWeight > PPM_DENOMINATOR) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InvalidParamValueError(
                    LibStakingRichErrors.InvalidParamValueErrorCodes.InvalidRewardDelegatedStakeWeight
            ));
        }

        // Minimum stake must be > 1
        if (minimumPoolStake < 2) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InvalidParamValueError(
                    LibStakingRichErrors.InvalidParamValueErrorCodes.InvalidMinimumPoolStake
            ));
        }
    }

    /// @dev Attach a staking contract; future calls will be delegated to the staking contract.
    /// @param _stakingContract Address of staking contract.
    function _attachStakingContract(address _stakingContract)
        internal
    {
        // Attach the staking contract
        stakingContract = _stakingContract;
        emit StakingContractAttachedToProxy(_stakingContract);

        // Call `init()` on the staking contract to initialize storage.
        (bool didInitSucceed, bytes memory initReturnData) = stakingContract.delegatecall(
            abi.encodeWithSelector(IStorageInit(0).init.selector)
        );

        if (!didInitSucceed) {
            assembly {
                revert(add(initReturnData, 0x20), mload(initReturnData))
            }
        }

        // Assert initialized storage values are valid
        assertValidStorageParams();
    }
}

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;


interface IStorageInit {

    /// @dev Initialize storage owned by this contract.
    function init()
        external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
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
  }
}