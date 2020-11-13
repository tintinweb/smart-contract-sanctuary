// SPDX-License-Identifier: AGPL-3.0-only

/*
    Escrow.sol - SKALE Allocator
    Copyright (C) 2020-Present SKALE Labs
    @author Artem Payvin

    SKALE Allocator is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Allocator is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Allocator.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import "./IERC1820Registry.sol";
import "./IERC777Sender.sol";
import "./IERC777Recipient.sol";
import "./IERC20.sol";

import "./IDelegationController.sol";
import "./IDistributor.sol";
import "./ITokenState.sol";

import "./Allocator.sol";
import "./Permissions.sol";


/**
 * @title Escrow
 * @dev This contract manages funds locked by the Allocator contract.
 */
contract Escrow is IERC777Recipient, IERC777Sender, Permissions {

    address private _beneficiary;

    uint256 private _availableAmountAfterTermination;

    IERC1820Registry private _erc1820;

    address public constant ADMIN = address(0xAeA97b739dcd6f5b586586CB7a538d60bA96a757);

    modifier onlyBeneficiary() {
        require(_msgSender() == _beneficiary || _msgSender() == ADMIN, "Message sender is not a plan beneficiary");
        _;
    }

    modifier onlyVestingManager() {
        Allocator allocator = Allocator(contractManager.getContract("Allocator"));
        require(
            allocator.hasRole(allocator.VESTING_MANAGER_ROLE(), _msgSender()),
            "Message sender is not a vesting manager"
        );
        _;
    }

    modifier onlyActiveBeneficiaryOrVestingManager() {
        Allocator allocator = Allocator(contractManager.getContract("Allocator"));
        if (allocator.isVestingActive(_beneficiary)) {
            require(_msgSender() == _beneficiary || _msgSender() == ADMIN, "Message sender is not beneficiary");
        } else {
            require(
                allocator.hasRole(allocator.VESTING_MANAGER_ROLE(), _msgSender()),
                "Message sender is not authorized"
            );
        }
        _;
    }   

    function initialize(address contractManagerAddress, address beneficiary) external initializer {
        require(beneficiary != address(0), "Beneficiary address is not set");
        Permissions.initialize(contractManagerAddress);
        _beneficiary = beneficiary;
        _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensSender"), address(this));
    } 

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )
        external override
        allow("SkaleToken")
        // solhint-disable-next-line no-empty-blocks
    {

    }

    function tokensToSend(
        address,
        address,
        address to,
        uint256,
        bytes calldata,
        bytes calldata
    )
        external override
        allow("SkaleToken")
        // solhint-disable-next-line no-empty-blocks
    {

    }

    /**
     * @dev Allows Beneficiary to retrieve vested tokens from the Escrow contract.
     * 
     * IMPORTANT: Slashed tokens are non-transferable.
     */
    function retrieve() external onlyBeneficiary {
        Allocator allocator = Allocator(contractManager.getContract("Allocator"));
        ITokenState tokenState = ITokenState(contractManager.getContract("TokenState"));
        uint256 vestedAmount = 0;
        if (allocator.isVestingActive(_beneficiary)) {
            vestedAmount = allocator.calculateVestedAmount(_beneficiary);
        } else {
            vestedAmount = _availableAmountAfterTermination;
        }
        uint256 escrowBalance = IERC20(contractManager.getContract("SkaleToken")).balanceOf(address(this));
        uint256 fullAmount = allocator.getFullAmount(_beneficiary);
        uint256 forbiddenToSend = tokenState.getAndUpdateForbiddenForDelegationAmount(address(this));
        if (vestedAmount > fullAmount.sub(escrowBalance)) {
            if (vestedAmount.sub(fullAmount.sub(escrowBalance)) > forbiddenToSend)
            require(
                IERC20(contractManager.getContract("SkaleToken")).transfer(
                    _beneficiary,
                    vestedAmount
                        .sub(
                            fullAmount
                                .sub(escrowBalance)
                            )
                        .sub(forbiddenToSend)
                ),
                "Error of token send"
            );
        }
    }

    /**
     * @dev Allows Vesting Manager to retrieve remaining transferrable escrow balance
     * after beneficiary's termination. 
     * 
     * IMPORTANT: Slashed tokens are non-transferable.
     * 
     * Requirements:
     * 
     * - Allocator must be active.
     */
    function retrieveAfterTermination(address destination) external onlyVestingManager {
        Allocator allocator = Allocator(contractManager.getContract("Allocator"));
        ITokenState tokenState = ITokenState(contractManager.getContract("TokenState"));

        require(destination != address(0), "Destination address is not set");
        require(!allocator.isVestingActive(_beneficiary), "Vesting is active");
        uint256 escrowBalance = IERC20(contractManager.getContract("SkaleToken")).balanceOf(address(this));
        uint256 forbiddenToSend = tokenState.getAndUpdateLockedAmount(address(this));
        if (escrowBalance > forbiddenToSend) {
            require(
                IERC20(contractManager.getContract("SkaleToken")).transfer(
                    destination,
                    escrowBalance.sub(forbiddenToSend)
                ),
                "Error of token send"
            );
        }
    }

    /**
     * @dev Allows Beneficiary to propose a delegation to a validator.
     * 
     * Requirements:
     * 
     * - Beneficiary must be active.
     * - Beneficiary must have sufficient delegatable tokens.
     * - If trusted list is enabled, validator must be a member of the trusted
     * list.
     */
    function delegate(
        uint256 validatorId,
        uint256 amount,
        uint256 delegationPeriod,
        string calldata info
    )
        external
        onlyBeneficiary
    {
        Allocator allocator = Allocator(contractManager.getContract("Allocator"));
        require(allocator.isDelegationAllowed(_beneficiary), "Delegation is not allowed");
        require(allocator.isVestingActive(_beneficiary), "Beneficiary is not Active");
        
        IDelegationController delegationController = IDelegationController(
            contractManager.getContract("DelegationController")
        );
        delegationController.delegate(validatorId, amount, delegationPeriod, info);
    }

    /**
     * @dev Allows Beneficiary and Vesting manager to request undelegation. Only 
     * Vesting manager can request undelegation after beneficiary is deactivated 
     * (after beneficiary termination).
     * 
     * Requirements:
     * 
     * - Beneficiary and Vesting manager must be `msg.sender`.
     */
    function requestUndelegation(uint256 delegationId) external onlyActiveBeneficiaryOrVestingManager {
        IDelegationController delegationController = IDelegationController(
            contractManager.getContract("DelegationController")
        );
        delegationController.requestUndelegation(delegationId);
    }

    /**
     * @dev Allows Beneficiary and Vesting manager to cancel a delegation proposal. Only 
     * Vesting manager can request undelegation after beneficiary is deactivated 
     * (after beneficiary termination).
     * 
     * Requirements:
     * 
     * - Beneficiary and Vesting manager must be `msg.sender`.
     */
    function cancelPendingDelegation(uint delegationId) external onlyActiveBeneficiaryOrVestingManager {
        IDelegationController delegationController = IDelegationController(
            contractManager.getContract("DelegationController")
        );
        delegationController.cancelPendingDelegation(delegationId);
    }

    /**
     * @dev Allows Beneficiary and Vesting manager to withdraw earned bounty. Only
     * Vesting manager can withdraw bounty to Allocator contract after beneficiary
     * is deactivated.
     * 
     * IMPORTANT: Withdraws are only possible after 90 day initial network lock.
     * 
     * Requirements:
     * 
     * - Beneficiary or Vesting manager must be `msg.sender`.
     * - Beneficiary must be active when Beneficiary is `msg.sender`.
     */
    function withdrawBounty(uint256 validatorId, address to) external onlyActiveBeneficiaryOrVestingManager {        
        IDistributor distributor = IDistributor(contractManager.getContract("Distributor"));
        distributor.withdrawBounty(validatorId, to);
    }

    /**
     * @dev Allows Allocator contract to cancel vesting of a Beneficiary. Cancel
     * vesting is performed upon termination.
     */
    function cancelVesting(uint256 vestedAmount) external allow("Allocator") {
        _availableAmountAfterTermination = vestedAmount;
    }
}
