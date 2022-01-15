// Copyright (C) 2021 BITFISH LIMITED

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.4;

import "./interfaces/IStakefishServicesContract.sol";
import "./interfaces/IStakefishServicesContractFactory.sol";
import "./libraries/ProxyFactory.sol";
import "./libraries/Address.sol";
import "./StakefishServicesContract.sol";

contract StakefishServicesContractFactory is ProxyFactory, IStakefishServicesContractFactory {
    using Address for address;
    using Address for address payable;

    uint256 private constant FULL_DEPOSIT_SIZE = 32 ether;
    uint256 private constant COMMISSION_RATE_SCALE = 1000000;

    uint256 private _minimumDeposit = 0.1 ether;
    address payable private _servicesContractImpl;
    address private _operatorAddress;
    uint24 private _commissionRate;

    modifier onlyOperator() {
        require(msg.sender == _operatorAddress);
        _;
    }

    constructor(uint24 commissionRate)
    {
        require(uint256(commissionRate) <= COMMISSION_RATE_SCALE, "Commission rate exceeds scale");

        _operatorAddress = msg.sender;
        _commissionRate = commissionRate;
        _servicesContractImpl = payable(new StakefishServicesContract());
        StakefishServicesContract(_servicesContractImpl).initialize(0, address(0), "");

        emit OperatorChanged(msg.sender);
        emit CommissionRateChanged(commissionRate);
    }

    function changeOperatorAddress(address newAddress)
        external
        override
        onlyOperator
    {
        require(newAddress != address(0), "Address can't be zero address");
        _operatorAddress = newAddress;

        emit OperatorChanged(newAddress);
    }

    function changeCommissionRate(uint24 newCommissionRate)
        external
        override
        onlyOperator
    {
        require(uint256(newCommissionRate) <= COMMISSION_RATE_SCALE, "Commission rate exceeds scale");
        _commissionRate = newCommissionRate;

        emit CommissionRateChanged(newCommissionRate);
    }

    function changeMinimumDeposit(uint256 newMinimumDeposit)
        external
        override
        onlyOperator
    {
        _minimumDeposit = newMinimumDeposit;

        emit MinimumDepositChanged(newMinimumDeposit);
    }

    function createContract(
        bytes32 saltValue,
        bytes32 operatorDataCommitment
    )
        external
        payable
        override
        returns (address)
    {
        require (msg.value <= 32 ether);

        bytes memory initData =
            abi.encodeWithSignature(
                "initialize(uint24,address,bytes32)",
                _commissionRate,
                _operatorAddress,
                operatorDataCommitment
            );

        address proxy = _createProxyDeterministic(_servicesContractImpl, initData, saltValue);
        emit ContractCreated(saltValue);

        if (msg.value > 0) {
            IStakefishServicesContract(payable(proxy)).depositOnBehalfOf{value: msg.value}(msg.sender);
        }

        return proxy;
    }

    function createMultipleContracts(
        uint256 baseSaltValue,
        bytes32[] calldata operatorDataCommitments
    )
        external
        payable
        override
    {
        uint256 remaining = msg.value;

        for (uint256 i = 0; i < operatorDataCommitments.length; i++) {
            bytes32 salt = bytes32(baseSaltValue + i);

            bytes memory initData =
                abi.encodeWithSignature(
                    "initialize(uint24,address,bytes32)",
                    _commissionRate,
                    _operatorAddress,
                    operatorDataCommitments[i]
                );

            address proxy = _createProxyDeterministic(
                _servicesContractImpl,
                initData,
                salt
            );

            emit ContractCreated(salt);

            uint256 depositSize = _min(remaining, FULL_DEPOSIT_SIZE);
            if (depositSize > 0) {
                IStakefishServicesContract(payable(proxy)).depositOnBehalfOf{value: depositSize}(msg.sender);
                remaining -= depositSize;
            }
        }

        if (remaining > 0) {
            payable(msg.sender).sendValue(remaining);
        }
    }

    function fundMultipleContracts(
        bytes32[] calldata saltValues,
        bool force
    )
        external
        payable
        override
        returns (uint256)
    {
        uint256 remaining = msg.value;
        address depositor = msg.sender;

        for (uint256 i = 0; i < saltValues.length; i++) {
            if (!force && remaining < _minimumDeposit)
                break;

            address proxy = _getDeterministicAddress(_servicesContractImpl, saltValues[i]);
            if (proxy.isContract()) {
                IStakefishServicesContract sc = IStakefishServicesContract(payable(proxy));
                if (sc.getState() == IStakefishServicesContract.State.PreDeposit) {
                    uint256 depositAmount = _min(remaining, FULL_DEPOSIT_SIZE - address(sc).balance);
                    if (force || depositAmount >= _minimumDeposit) {
                        sc.depositOnBehalfOf{value: depositAmount}(depositor);
                        remaining -= depositAmount;
                    }
                }
            }
        }

        if (remaining > 0) {
            payable(msg.sender).sendValue(remaining);
        }

        return remaining;
    }

    function getOperatorAddress()
        external
        view
        override
        returns (address)
    {
        return _operatorAddress;
    }
    
    function getCommissionRate()
        external
        view
        override
        returns (uint24)
    {
        return _commissionRate;
    }

    function getServicesContractImpl()
        external
        view
        override
        returns (address payable)
    {
        return _servicesContractImpl;
    }

    function getMinimumDeposit()
        external
        view
        override
        returns (uint256)
    {
        return _minimumDeposit;
    }

    function _min(uint256 a, uint256 b) pure internal returns (uint256) {
        return a <= b ? a : b;
    }
}

// Copyright (C) 2021 BITFISH LIMITED

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only


pragma solidity ^0.8.0;

/// @notice Governs the life cycle of a single Eth2 validator with ETH provided by multiple stakers.
interface IStakefishServicesContract {
    /// @notice The life cycle of a services contract.
    enum State {
        NotInitialized,
        PreDeposit,
        PostDeposit,
        Withdrawn
    }

    /// @notice Emitted when a `spender` is set to allow the transfer of an `owner`'s deposit stake amount.
    /// `amount` is the new allownace.
    /// @dev Also emitted when {transferDepositFrom} is called.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Emitted when deposit stake amount is transferred.
    /// @param from The address of deposit stake owner.
    /// @param to The address of deposit stake beneficiary.
    /// @param amount The amount of transferred deposit stake.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @notice Emitted when a `spender` is set to allow withdrawal on behalf of a `owner`.
    /// `amount` is the new allowance.
    /// @dev Also emitted when {WithdrawFrom} is called.
    event WithdrawalApproval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Emitted when `owner`'s ETH are withdrawan to `to`.
    /// @param owner The address of deposit stake owner.
    /// @param to The address of ETH beneficiary.
    /// @param amount The amount of deposit stake to be converted to ETH.
    /// @param value The amount of withdrawn ETH.
    event Withdrawal(
        address indexed owner,
        address indexed to,
        uint256 amount,
        uint256 value
    );

    /// @notice Emitted when 32 ETH is transferred to the eth2 deposit contract.
    /// @param pubkey A BLS12-381 public key.
    event ValidatorDeposited(
        bytes pubkey // 48 bytes
    );

    /// @notice Emitted when a validator exits and the operator settles the commission.
    event ServiceEnd();

    /// @notice Emitted when deposit to the services contract.
    /// @param from The address of the deposit stake owner.
    /// @param amount The accepted amount of ETH deposited into the services contract.
    event Deposit(
        address from,
        uint256 amount
    );

    /// @notice Emitted when operaotr claims commission fee.
    /// @param receiver The address of the operator.
    /// @param amount The amount of ETH sent to the operator address.
    event Claim(
        address receiver,
        uint256 amount
    );

    /// @notice Updates the exit date of the validator.
    /// @dev The exit date should be in the range of uint64.
    /// @param newExitDate The new exit date should come before the previously specified exit date.
    function updateExitDate(uint64 newExitDate) external;

    /// @notice Submits a Phase 0 DepositData to the eth2 deposit contract.
    /// @dev The Keccak hash of the contract address and all submitted data should match the `_operatorDataCommitment`.
    /// Emits a {ValidatorDeposited} event.
    /// @param validatorPubKey A BLS12-381 public key.
    /// @param depositSignature A BLS12-381 signature.
    /// @param depositDataRoot The SHA-256 hash of the SSZ-encoded DepositData object.
    /// @param exitDate The expected exit date of the created validator
    function createValidator(
        bytes calldata validatorPubKey, // 48 bytes
        bytes calldata depositSignature, // 96 bytes
        bytes32 depositDataRoot,
        uint64 exitDate
    ) external;

    /// @notice Deposits `msg.value` of ETH.
    /// @dev If the balance of the contract exceeds 32 ETH, the excess will be sent
    /// back to `msg.sender`.
    /// Emits a {Deposit} event.
    function deposit() external payable returns (uint256 surplus);


    /// @notice Deposits `msg.value` of ETH on behalf of `depositor`.
    /// @dev If the balance of the contract exceeds 32 ETH, the excess will be sent
    /// back to `depositor`.
    /// Emits a {Deposit} event.
    function depositOnBehalfOf(address depositor) external payable returns (uint256 surplus);

    /// @notice Settles operator service commission and enable withdrawal.
    /// @dev It can be called by operator if the time has passed `_exitDate`.
    /// It can be called by any address if the time has passed `_exitDate + MAX_SECONDS_IN_EXIT_QUEUE`.
    /// Emits a {ServiceEnd} event.
    function endOperatorServices() external;

    /// @notice Withdraws all the ETH of `msg.sender`.
    /// @dev It can only be called when the contract state is not `PostDeposit`.
    /// Emits a {Withdrawal} event.
    /// @param minimumETHAmount The minimum amount of ETH that must be received for the transaction not to revert.
    function withdrawAll(uint256 minimumETHAmount) external returns (uint256);

    /// @notice Withdraws the ETH of `msg.sender` which is corresponding to the `amount` of deposit stake.
    /// @dev It can only be called when the contract state is not `PostDeposit`.
    /// Emits a {Withdrawal} event.
    /// @param amount The amount of deposit stake to be converted to ETH.
    /// @param minimumETHAmount The minimum amount of ETH that must be received for the transaction not to revert.
    function withdraw(uint256 amount, uint256 minimumETHAmount) external returns (uint256);

    /// @notice Withdraws the ETH of `msg.sender` which is corresponding to the `amount` of deposit stake to a specified address.
    /// @dev It can only be called when the contract state is not `PostDeposit`.
    /// Emits a {Withdrawal} event.
    /// @param amount The amount of deposit stake to be converted to ETH.
    /// @param beneficiary The address of ETH receiver.
    /// @param minimumETHAmount The minimum amount of ETH that must be received for the transaction not to revert.
    function withdrawTo(
        uint256 amount,
        address payable beneficiary,
        uint256 minimumETHAmount
    ) external returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's deposit stake.
    /// @dev Emits an {Approval} event.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Increases the allowance granted to `spender` by the caller.
    /// @dev Emits an {Approval} event indicating the upated allowances;
    function increaseAllowance(address spender, uint256 addValue) external returns (bool);

    /// @notice Decreases the allowance granted to `spender` by the caller.
    /// @dev Emits an {Approval} event indicating the upated allowances;
    /// It reverts if current allowance is less than `subtractedValue`.
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Decreases the allowance granted to `spender` by the caller.
    /// @dev Emits an {Approval} event indicating the upated allowances;
    /// It sets allowance to zero if current allowance is less than `subtractedValue`.
    function forceDecreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's deposit amount that can be withdrawn.
    /// @dev Emits an {WithdrawalApproval} event.
    function approveWithdrawal(address spender, uint256 amount) external returns (bool);

    /// @notice Increases the allowance of withdrawal granted to `spender` by the caller.
    /// @dev Emits an {WithdrawalApproval} event indicating the upated allowances;
    function increaseWithdrawalAllowance(address spender, uint256 addValue) external returns (bool);

    /// @notice Decreases the allowance of withdrawal granted to `spender` by the caller.
    /// @dev Emits an {WithdrawwalApproval} event indicating the upated allowances;
    /// It reverts if current allowance is less than `subtractedValue`.
    function decreaseWithdrawalAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Decreases the allowance of withdrawal granted to `spender` by the caller.
    /// @dev Emits an {WithdrawwalApproval} event indicating the upated allowances;
    /// It reverts if current allowance is less than `subtractedValue`.
    function forceDecreaseWithdrawalAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Withdraws the ETH of `depositor` which is corresponding to the `amount` of deposit stake to a specified address.
    /// @dev Emits a {Withdrawal} event.
    /// Emits a {WithdrawalApproval} event indicating the updated allowance.
    /// @param depositor The address of deposit stake holder.
    /// @param beneficiary The address of ETH receiver.
    /// @param amount The amount of deposit stake to be converted to ETH.
    /// @param minimumETHAmount The minimum amount of ETH that must be received for the transaction not to revert.
    function withdrawFrom(
        address depositor,
        address payable beneficiary,
        uint256 amount,
        uint256 minimumETHAmount
    ) external returns (uint256);

    /// @notice Transfers `amount` deposit stake from caller to `to`.
    /// @dev Emits a {Transfer} event.
    function transferDeposit(address to, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` deposit stake from `from` to `to`.
    /// @dev Emits a {Transfer} event.
    /// Emits an {Approval} event indicating the updated allowance.
    function transferDepositFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /// @notice Transfers operator claimable commission fee to the operator address.
    /// @dev Emits a {Claim} event.
    function operatorClaim() external returns (uint256);

    /// @notice Returns the remaining number of deposit stake that `spender` will be allowed to withdraw
    /// on behalf of `depositor` through {withdrawFrom}.
    function withdrawalAllowance(address depositor, address spender) external view returns (uint256);

    /// @notice Returns the operator service commission rate.
    function getCommissionRate() external view returns (uint256);

    /// @notice Returns operator claimable commission fee.
    function getOperatorClaimable() external view returns (uint256);

    /// @notice Returns the exit date of the validator.
    function getExitDate() external view returns (uint256);

    /// @notice Returns the state of the contract.
    function getState() external view returns (State);

    /// @notice Returns the address of operator.
    function getOperatorAddress() external view returns (address);

    /// @notice Returns the amount of deposit stake owned by `depositor`.
    function getDeposit(address depositor) external view returns (uint256);

    /// @notice Returns the total amount of deposit stake.
    function getTotalDeposits() external view returns (uint256);

    /// @notice Returns the remaining number of deposit stake that `spender` will be allowed to transfer
    /// on behalf of `depositor` through {transferDepositFrom}.
    function getAllowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the commitment which is the hash of the contract address and all inputs to the `createValidator` function.
    function getOperatorDataCommitment() external view returns (bytes32);

    /// @notice Returns the amount of ETH that is withdrawable by `owner`.
    function getWithdrawableAmount(address owner) external view returns (uint256);
}

// Copyright (C) 2021 BITFISH LIMITED

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only


pragma solidity ^0.8.0;

/// @notice Manages the deployment of services contracts
interface IStakefishServicesContractFactory {
    /// @notice Emitted when a proxy contract of the services contract is created
    event ContractCreated(
        bytes32 create2Salt
    );

    /// @notice Emitted when operator service commission rate is set or changed.
    event CommissionRateChanged(
        uint256 newCommissionRate
    );

    /// @notice Emitted when operator address is set or changed.
    event OperatorChanged(
        address newOperatorAddress
    );

    /// @notice Emitted when minimum deposit amount is changed.
    event MinimumDepositChanged(
        uint256 newMinimumDeposit
    );

    /// @notice Updates the operator service commission rate.
    /// @dev Emits a {CommissionRateChanged} event.
    function changeCommissionRate(uint24 newCommissionRate) external;

    /// @notice Updates address of the operator.
    /// @dev Emits a {OperatorChanged} event.
    function changeOperatorAddress(address newAddress) external;

    /// @notice Updates the minimum size of deposit allowed.
    /// @dev Emits a {MinimumDeposiChanged} event.
    function changeMinimumDeposit(uint256 newMinimumDeposit) external;

    /// @notice Deploys a proxy contract of the services contract at a deterministic address.
    /// @dev Emits a {ContractCreated} event.
    function createContract(bytes32 saltValue, bytes32 operatorDataCommitmet) external payable returns (address);

    /// @notice Deploys multiple proxy contracts of the services contract at deterministic addresses.
    /// @dev Emits a {ContractCreated} event for each deployed proxy contract.
    function createMultipleContracts(uint256 baseSaltValue, bytes32[] calldata operatorDataCommitmets) external payable;

    /// @notice Funds multiple services contracts in order.
    /// @dev The surplus will be returned to caller if all services contracts are filled up.
    /// Using salt instead of address to prevent depositing into malicious contracts.
    /// @param saltValues The salts that are used to deploy services contracts.
    /// @param force If set to `false` then it will only deposit into a services contract 
    /// when it has more than `MINIMUM_DEPOSIT` ETH of capacity.
    /// @return surplus The amount of returned ETH.
    function fundMultipleContracts(bytes32[] calldata saltValues, bool force) external payable returns (uint256);

    /// @notice Returns the address of the operator.
    function getOperatorAddress() external view returns (address);

    /// @notice Returns the operator service commission rate.
    function getCommissionRate() external view returns (uint24);

    /// @notice Returns the address of implementation of services contract.
    function getServicesContractImpl() external view returns (address payable);

    /// @notice Returns the minimum deposit amount.
    function getMinimumDeposit() external view returns (uint256);
}

// Copyright (C) 2021 BITFISH LIMITED

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.4;

/// @dev https://eips.ethereum.org/EIPS/eip-1167
contract ProxyFactory {
    function _getDeterministicAddress(
        address target,
        bytes32 salt
    ) internal view returns (address proxy) {
        address deployer = address(this);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), shl(0x60, target))
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(clone, 0x38), shl(0x60, deployer))
            mstore(add(clone, 0x4c), salt)
            mstore(add(clone, 0x6c), keccak256(clone, 0x37))
            proxy := keccak256(add(clone, 0x37), 0x55)
        }
    }

    function _createProxyDeterministic(
        address target,
        bytes memory initData,
        bytes32 salt
    ) internal returns (address proxy) {
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), shl(0x60, target))
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create2(0, clone, 0x37, salt)
        }
        require(proxy != address(0), "Proxy deploy failed");

        if (initData.length > 0) {
            (bool success, ) = proxy.call(initData);
            require(success, "Proxy init failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4d0f8c1da8654a478f046ea7cf83d2166e1025af/contracts/utils/Address.sol

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

// Copyright (C) 2021 BITFISH LIMITED

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.4;

import "./interfaces/deposit_contract.sol";
import "./interfaces/IStakefishServicesContract.sol";
import "./libraries/Address.sol";

contract StakefishServicesContract is IStakefishServicesContract {
    using Address for address payable;

    uint256 private constant HOUR = 3600;
    uint256 private constant DAY = 24 * HOUR;
    uint256 private constant WEEK = 7 * DAY;
    uint256 private constant YEAR = 365 * DAY;
    uint256 private constant MAX_SECONDS_IN_EXIT_QUEUE = 1 * YEAR;
    uint256 private constant COMMISSION_RATE_SCALE = 1000000;

    // Packed into a single slot
    uint24 private _commissionRate;
    address private _operatorAddress;
    uint64 private _exitDate;
    State private _state;

    bytes32 private _operatorDataCommitment;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => mapping(address => uint256)) private _allowedWithdrawals;
    mapping(address => uint256) private _deposits;
    uint256 private _totalDeposits;
    uint256 private _operatorClaimable;

    IDepositContract public constant depositContract =
        IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);

    modifier onlyOperator() {
        require(
            msg.sender == _operatorAddress,
            "Caller is not the operator"
        );
        _;
    }

    modifier initializer() {
        require(
            _state == State.NotInitialized,
            "Contract is already initialized"
        );
        _state = State.PreDeposit;
        _;
    }

    function initialize(
        uint24 commissionRate,
        address operatorAddress,
        bytes32 operatorDataCommitment
    )
        external
        initializer
    {
        require(uint256(commissionRate) <= COMMISSION_RATE_SCALE, "Commission rate exceeds scale");

        _commissionRate = commissionRate;
        _operatorAddress = operatorAddress;
        _operatorDataCommitment = operatorDataCommitment;
    }

    receive() payable external {
        if (_state == State.PreDeposit) {
            revert("Plain Ether transfer not allowed");
        }
    }

    function updateExitDate(uint64 newExitDate)
        external
        override
        onlyOperator
    {
        require(
            _state == State.PostDeposit,
            "Validator is not active"
        );

        require(
            newExitDate < _exitDate,
            "Not earlier than the original value"
        );

        _exitDate = newExitDate;
    }

    function createValidator(
        bytes calldata validatorPubKey, // 48 bytes
        bytes calldata depositSignature, // 96 bytes
        bytes32 depositDataRoot,
        uint64 exitDate
    )
        external
        override
        onlyOperator
    {

        require(_state == State.PreDeposit, "Validator has been created");
        _state = State.PostDeposit;

        require(validatorPubKey.length == 48, "Invalid validator public key");
        require(depositSignature.length == 96, "Invalid deposit signature");
        require(_operatorDataCommitment == keccak256(
            abi.encodePacked(
                address(this),
                validatorPubKey,
                depositSignature,
                depositDataRoot,
                exitDate
            )
        ), "Data doesn't match commitment");

        _exitDate = exitDate;

        depositContract.deposit{value: 32 ether}(
            validatorPubKey,
            abi.encodePacked(uint96(0x010000000000000000000000), address(this)),
            depositSignature,
            depositDataRoot
        );

        emit ValidatorDeposited(validatorPubKey);
    }

    function deposit()
        external
        payable
        override
        returns (uint256 surplus)
    {
        require(
            _state == State.PreDeposit,
            "Validator already created"
        );

        return _handleDeposit(msg.sender);
    }

    function depositOnBehalfOf(address depositor)
        external
        payable
        override
        returns (uint256 surplus)
    {
        require(
            _state == State.PreDeposit,
            "Validator already created"
        );
        return _handleDeposit(depositor);
    }

    function endOperatorServices()
        external
        override
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "Can't end with 0 balance");
        require(_state == State.PostDeposit, "Not allowed in the current state");
        require((msg.sender == _operatorAddress && block.timestamp > _exitDate) ||
                (_deposits[msg.sender] > 0 && block.timestamp > _exitDate + MAX_SECONDS_IN_EXIT_QUEUE), "Not allowed at the current time");

        _state = State.Withdrawn;

        if (balance > 32 ether) {
            uint256 profit = balance - 32 ether;
            uint256 finalCommission = profit * _commissionRate / COMMISSION_RATE_SCALE;
            _operatorClaimable += finalCommission;
        }

        emit ServiceEnd();
    }

    function operatorClaim()
        external
        override
        onlyOperator
        returns (uint256)
    {
        uint256 claimable = _operatorClaimable;
        if (claimable > 0) {
            _operatorClaimable = 0;
            payable(_operatorAddress).sendValue(claimable);

            emit Claim(_operatorAddress, claimable);
        }

        return claimable;
    }

    string private constant WITHDRAWALS_NOT_ALLOWED =
        "Not allowed when validator is active";

    function withdrawAll(uint256 minimumETHAmount)
        external
        override
        returns (uint256)
    {
        require(_state != State.PostDeposit, WITHDRAWALS_NOT_ALLOWED);
        uint256 value = _executeWithdrawal(msg.sender, payable(msg.sender), _deposits[msg.sender]);
        require(value >= minimumETHAmount, "Less than minimum amount");
        return value;
    }

    function withdraw(
        uint256 amount,
        uint256 minimumETHAmount
    )
        external
        override
        returns (uint256)
    {
        require(_state != State.PostDeposit, WITHDRAWALS_NOT_ALLOWED);
        uint256 value = _executeWithdrawal(msg.sender, payable(msg.sender), amount);
        require(value >= minimumETHAmount, "Less than minimum amount");
        return value;
    }

    function withdrawTo(
        uint256 amount,
        address payable beneficiary,
        uint256 minimumETHAmount
    )
        external
        override
        returns (uint256)
    {
        require(_state != State.PostDeposit, WITHDRAWALS_NOT_ALLOWED);
        uint256 value = _executeWithdrawal(msg.sender, beneficiary, amount);
        require(value >= minimumETHAmount, "Less than minimum amount");
        return value;
    }

    function approve(
        address spender,
        uint256 amount
    )
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function forceDecreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        _approve(msg.sender, spender, currentAllowance - _min(subtractedValue, currentAllowance));
        return true;
    }

    function approveWithdrawal(
        address spender,
        uint256 amount
    )
        external
        override
        returns (bool)
    {
        _approveWithdrawal(msg.sender, spender, amount);
        return true;
    }

    function increaseWithdrawalAllowance(
        address spender,
        uint256 addedValue
    )
        external
        override
        returns (bool)
    {
        _approveWithdrawal(msg.sender, spender, _allowedWithdrawals[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseWithdrawalAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        override
        returns (bool)
    {
        _approveWithdrawal(msg.sender, spender, _allowedWithdrawals[msg.sender][spender] - subtractedValue);
        return true;
    }

    function forceDecreaseWithdrawalAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowedWithdrawals[msg.sender][spender];
        _approveWithdrawal(msg.sender, spender, currentAllowance - _min(subtractedValue, currentAllowance));
        return true;
    }

    function withdrawFrom(
        address depositor,
        address payable beneficiary,
        uint256 amount,
        uint256 minimumETHAmount
    )
        external
        override
        returns (uint256)
    {
        require(_state != State.PostDeposit, WITHDRAWALS_NOT_ALLOWED);
        uint256 spenderAllowance = _allowedWithdrawals[depositor][msg.sender];
        uint256 newAllowance = spenderAllowance - amount;
        // Please note that there is no need to require(_deposit <= spenderAllowance)
        // here because modern versions of Solidity insert underflow checks
        _allowedWithdrawals[depositor][msg.sender] = newAllowance;
        emit WithdrawalApproval(depositor, msg.sender, newAllowance);

        uint256 value = _executeWithdrawal(depositor, beneficiary, amount);
        require(value >= minimumETHAmount, "Less than minimum amount");
        return value; 
    }

    function transferDeposit(
        address to,
        uint256 amount
    )
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferDepositFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[from][msg.sender];

        _approve(from, msg.sender, currentAllowance - amount);
        _transfer(from, to, amount);

        return true;
    }

    function withdrawalAllowance(
        address depositor,
        address spender
    )
        external
        view
        override
        returns (uint256)
    {
        return _allowedWithdrawals[depositor][spender];
    }

    function getCommissionRate()
        external
        view
        override
        returns (uint256)
    {
        return _commissionRate;
    }

    function getExitDate()
        external
        view
        override
        returns (uint256)
    {
        return _exitDate;
    }

    function getState()
        external
        view
        override
        returns(State)
    {
        return _state;
    }

    function getOperatorAddress()
        external
        view
        override
        returns (address)
    {
        return _operatorAddress;
    }

    function getDeposit(address depositor)
        external
        view
        override
        returns (uint256)
    {
        return _deposits[depositor];
    }

    function getTotalDeposits()
        external
        view
        override
        returns (uint256)
    {
        return _totalDeposits;
    }

    function getAllowance(
        address owner,
        address spender
    )
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function getOperatorDataCommitment()
        external
        view
        override
        returns (bytes32)
    {
        return _operatorDataCommitment;
    }

    function getOperatorClaimable()
        external
        view
        override
        returns (uint256)
    {
        return _operatorClaimable;
    }

    function getWithdrawableAmount(address owner)
        external
        view
        override
        returns (uint256)
    {
        if (_state == State.PostDeposit) {
            return 0;
        }

        return _deposits[owner] * (address(this).balance - _operatorClaimable) / _totalDeposits;
    }

    function _executeWithdrawal(
        address depositor,
        address payable beneficiary,
        uint256 amount
    )
        internal
        returns (uint256)
    {
        require(amount > 0, "Amount shouldn't be zero");

        uint256 value = amount * (address(this).balance - _operatorClaimable) / _totalDeposits;
        // Modern versions of Solidity automatically add underflow checks,
        // so we don't need to `require(_deposits[_depositor] < _deposit` here:
        _deposits[depositor] -= amount;
        _totalDeposits -= amount;
        emit Withdrawal(depositor, beneficiary, amount, value);
        payable(beneficiary).sendValue(value);

        return value;
    }

    // NOTE: This throws (on underflow) if the contract's balance was more than
    // 32 ether before the call
    function _handleDeposit(address depositor)
        internal
        returns (uint256 surplus)
    {
        uint256 depositSize = msg.value;
        surplus = (address(this).balance > 32 ether) ?
            (address(this).balance - 32 ether) : 0;

        uint256 acceptedDeposit = depositSize - surplus;

        _deposits[depositor] += acceptedDeposit;
        _totalDeposits += acceptedDeposit;

        emit Deposit(depositor, acceptedDeposit);
        
        if (surplus > 0) {
            payable(depositor).sendValue(surplus);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        require(to != address(0), "Transfer to the zero address");

        _deposits[from] -= amount;
        _deposits[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
    {
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _approveWithdrawal(
        address owner,
        address spender,
        uint256 amount
    )
        internal
    {
        require(spender != address(0), "Approve to the zero address");

        _allowedWithdrawals[owner][spender] = amount;
        emit WithdrawalApproval(owner, spender, amount);
    }

    function _min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.4;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// Based on official specification in https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}

// This is a rewrite of the Vyper Eth2.0 deposit contract in Solidity.
// It tries to stay as close as possible to the original source code.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
contract DepositContract is IDepositContract, ERC165 {
    uint constant DEPOSIT_CONTRACT_TREE_DEPTH = 32;
    // NOTE: this also ensures `deposit_count` will fit into 64-bits
    uint constant MAX_DEPOSIT_COUNT = 2**DEPOSIT_CONTRACT_TREE_DEPTH - 1;

    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] branch;
    uint256 deposit_count;

    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] zero_hashes;

    constructor() {
        // Compute hashes in empty sparse Merkle tree
        for (uint height = 0; height < DEPOSIT_CONTRACT_TREE_DEPTH - 1; height++)
            zero_hashes[height + 1] = sha256(abi.encodePacked(zero_hashes[height], zero_hashes[height]));
    }

    function get_deposit_root() override external view returns (bytes32) {
        bytes32 node;
        uint size = deposit_count;
        for (uint height = 0; height < DEPOSIT_CONTRACT_TREE_DEPTH; height++) {
            if ((size & 1) == 1)
                node = sha256(abi.encodePacked(branch[height], node));
            else
                node = sha256(abi.encodePacked(node, zero_hashes[height]));
            size /= 2;
        }
        return sha256(abi.encodePacked(
            node,
            to_little_endian_64(uint64(deposit_count)),
            bytes24(0)
        ));
    }

    function get_deposit_count() override external view returns (bytes memory) {
        return to_little_endian_64(uint64(deposit_count));
    }

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) override external payable {
        // Extended ABI length checks since dynamic types are used.
        require(pubkey.length == 48, "DepositContract: invalid pubkey length");
        require(withdrawal_credentials.length == 32, "DepositContract: invalid withdrawal_credentials length");
        require(signature.length == 96, "DepositContract: invalid signature length");

        // Check deposit amount
        require(msg.value >= 1 ether, "DepositContract: deposit value too low");
        require(msg.value % 1 gwei == 0, "DepositContract: deposit value not multiple of gwei");
        uint deposit_amount = msg.value / 1 gwei;
        require(deposit_amount <= type(uint64).max, "DepositContract: deposit value too high");

        // Emit `DepositEvent` log
        bytes memory amount = to_little_endian_64(uint64(deposit_amount));
        emit DepositEvent(
            pubkey,
            withdrawal_credentials,
            amount,
            signature,
            to_little_endian_64(uint64(deposit_count))
        );

        // Compute deposit data root (`DepositData` hash tree root)
        bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 signature_root = sha256(abi.encodePacked(
            sha256(abi.encodePacked(signature[:64])),
            sha256(abi.encodePacked(signature[64:], bytes32(0)))
        ));
        bytes32 node = sha256(abi.encodePacked(
            sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
            sha256(abi.encodePacked(amount, bytes24(0), signature_root))
        ));

        // Verify computed and expected deposit data roots match
        require(node == deposit_data_root, "DepositContract: reconstructed DepositData does not match supplied deposit_data_root");

        // Avoid overflowing the Merkle tree (and prevent edge case in computing `branch`)
        require(deposit_count < MAX_DEPOSIT_COUNT, "DepositContract: merkle tree full");

        // Add deposit data root to Merkle tree (update a single `branch` node)
        deposit_count += 1;
        uint size = deposit_count;
        for (uint height = 0; height < DEPOSIT_CONTRACT_TREE_DEPTH; height++) {
            if ((size & 1) == 1) {
                branch[height] = node;
                return;
            }
            node = sha256(abi.encodePacked(branch[height], node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    function supportsInterface(bytes4 interfaceId) override external pure returns (bool) {
        return interfaceId == type(ERC165).interfaceId || interfaceId == type(IDepositContract).interfaceId;
    }

    function to_little_endian_64(uint64 value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
}