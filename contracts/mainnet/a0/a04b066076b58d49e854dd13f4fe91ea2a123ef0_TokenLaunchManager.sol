// SPDX-License-Identifier: AGPL-3.0-only

/*
    TokenLaunchManager.sol - SKALE Manager
    Copyright (C) 2019-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;

import "./IERC777.sol";
import "./IERC20.sol";
import "./IERC777Recipient.sol";
import "./IERC1820Registry.sol";

import "./Permissions.sol";
import "./TokenLaunchLocker.sol";

/**
 * @title Token Launch Manager
 * @dev This contract manages functions for the Token Launch event.
 *
 * The seller is an entity who distributes tokens through a Launch process.
 */
contract TokenLaunchManager is Permissions, IERC777Recipient {
    event Approved(
        address holder,
        uint amount
    );

    /**
     * @dev Emitted when a `holder` retrieves `amount`.
     */
    event TokensRetrieved(
        address holder,
        uint amount
    );

    /**
     * @dev Emitted when token launch is completed.
     */
    event TokenLaunchIsCompleted(
        uint timestamp
    );

    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

    IERC1820Registry private _erc1820;

    mapping (address => uint) public approved;
    bool public tokenLaunchIsCompleted;
    uint private _totalApproved;

    modifier onlySeller() {
        require(_isOwner() || hasRole(SELLER_ROLE, _msgSender()), "Not authorized");
        _;
    }

    /**
     * @dev Allocates values for `walletAddress`
     *
     * Requirements:
     *
     * - token launch must not be completed
     * - the total approved must be less than or equal to the seller balance.
     *
     * Emits an Approved event.
     *
     * @param walletAddress address wallet address to approve transfers to
     * @param value uint token amount to approve transfer to
     */
    function approveTransfer(address walletAddress, uint value) external onlySeller {
        require(!tokenLaunchIsCompleted, "Can't approve because token launch is completed");
        _approveTransfer(walletAddress, value);
        require(_totalApproved <= _getBalance(), "Balance is too low");
    }

    /**
     * @dev Allocates values for `walletAddresses`
     *
     * Requirements:
     *
     * - token launch must not be completed
     * - the input arrays must be equal in size.
     * - the total approved must be less than or equal to the seller balance.
     *
     * Emits an Approved event.
     *
     * @param walletAddress address[] array of wallet addresses to approve transfers to
     * @param value uint[] array of token amounts to approve transfer to
     */
    function approveBatchOfTransfers(address[] calldata walletAddress, uint[] calldata value) external onlySeller {
        require(!tokenLaunchIsCompleted, "Can't approve because token launch is completed");
        require(walletAddress.length == value.length, "Wrong input arrays length");
        for (uint i = 0; i < walletAddress.length; ++i) {
            _approveTransfer(walletAddress[i], value[i]);
        }
        require(_totalApproved <= _getBalance(), "Balance is too low");
    }

    /**
     * @dev Allow withdrawals and disallow approvals changes
     *
     * Requirements:
     *
     * - all approvals must be done
     * - token launch must be not completed
     *
     */
    function completeTokenLaunch() external onlySeller {
        require(!tokenLaunchIsCompleted, "Can't complete launch because it's already completed");
        tokenLaunchIsCompleted = true;
        emit TokenLaunchIsCompleted(now);
    }

    /**
     * @dev Allows the seller to update a purchaser's address in case of an error.
     *
     * Requirements:
     *
     * - the updated address must not already be in use.
     *
     * Emits an Approved event.
     *
     * @param oldAddress address token purchaser's previous address
     * @param newAddress address token purchaser's new address
     */
    function changeApprovalAddress(address oldAddress, address newAddress) external onlySeller {
        require(!tokenLaunchIsCompleted, "Can't change approval because token launch is completed");
        require(approved[newAddress] == 0, "New address is already used");
        uint oldValue = approved[oldAddress];
        if (oldValue > 0) {
            _setApprovedAmount(oldAddress, 0);
            _approveTransfer(newAddress, oldValue);
        }
    }

    /**
     * @dev Allows the seller to update a purchaser's amount in case of an error.
     *
     * @param wallet address of the token purchaser
     * @param newValue uint of the updated token amount
     */
    function changeApprovalValue(address wallet, uint newValue) external onlySeller {
        require(!tokenLaunchIsCompleted, "Can't change approval because token launch is completed");
        _setApprovedAmount(wallet, newValue);
    }

    /**
     * @dev Transfers the entire value to the sender's address. Transferred tokens
     * are locked for Proof-of-Use.
     *
     * Requirements:
     *
     * - token transfer must be approved.
     */
    function retrieve() external {
        require(tokenLaunchIsCompleted, "Can't retrive tokens because token launch is not completed");
        require(approved[_msgSender()] > 0, "Transfer is not approved");
        uint value = approved[_msgSender()];
        _setApprovedAmount(_msgSender(), 0);
        require(
            IERC20(contractManager.getContract("SkaleToken")).transfer(_msgSender(), value),
            "Error in transfer call to SkaleToken");
        TokenLaunchLocker(contractManager.getContract("TokenLaunchLocker")).lock(_msgSender(), value);
        emit TokensRetrieved(_msgSender(), value);
    }

    /**
     * @dev A required callback for ERC777.
     */
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

    function initialize(address contractManagerAddress) public override initializer {
        Permissions.initialize(contractManagerAddress);
        tokenLaunchIsCompleted = false;
        _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }    

    // private

    function _approveTransfer(address walletAddress, uint value) internal onlySeller {
        require(value > 0, "Value must be greater than zero");
        _setApprovedAmount(walletAddress, approved[walletAddress].add(value));
        emit Approved(walletAddress, value);
    }

    function _getBalance() private view returns(uint balance) {
        return IERC20(contractManager.getContract("SkaleToken")).balanceOf(address(this));
    }

    function _setApprovedAmount(address wallet, uint value) private {
        require(wallet != address(0), "Wallet address must be non zero");
        uint oldValue = approved[wallet];
        if (oldValue != value) {
            approved[wallet] = value;
            if (value > oldValue) {
                _totalApproved = _totalApproved.add(value.sub(oldValue));
            } else {
                _totalApproved = _totalApproved.sub(oldValue.sub(value));
            }
        }
    }
}