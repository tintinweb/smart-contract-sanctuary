// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

import "../interfaces/IWithdrawalDelayer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract WithdrawalDelayer is ReentrancyGuard, IWithdrawalDelayer {
    struct DepositState {
        uint192 amount;
        uint64 depositTimestamp;
    }

    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant _TRANSFER_SIGNATURE = 0xa9059cbb;

    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant _TRANSFERFROM_SIGNATURE = 0x23b872dd;

    // bytes4(keccak256(bytes("deposit(address,address,uint192)")));
    bytes4 constant _DEPOSIT_SIGNATURE = 0xcfc0b641;

    uint64 public constant MAX_WITHDRAWAL_DELAY = 2 weeks; // Maximum time that the return of funds can be delayed
    uint64 public constant MAX_EMERGENCY_MODE_TIME = 26 weeks; // Maximum time in a state of emergency before a
    // resolution and after which the emergency council can redeem the funds
    uint64 private _withdrawalDelay; // Current delay
    uint64 private _emergencyModeStartingTime; // When emergency mode has started
    address private _hermezGovernance; // Governance who control the system parameters
    address public pendingGovernance;
    address payable public pendingEmergencyCouncil;
    address payable private _emergencyCouncil; // emergency council address who can redeem the funds after MAX_EMERGENCY_MODE_TIME
    bool private _emergencyMode; // bool to set the emergency mode
    address public hermezRollupAddress; // hermez Rollup Address who can send funds to this smart contract
    mapping(bytes32 => DepositState) public deposits; // Mapping to keep track of deposits

    event Deposit(
        address indexed owner,
        address indexed token,
        uint192 amount,
        uint64 depositTimestamp
    );
    event Withdraw(
        address indexed token,
        address indexed owner,
        uint192 amount
    );
    event EmergencyModeEnabled();
    event NewWithdrawalDelay(uint64 withdrawalDelay);
    event EscapeHatchWithdrawal(
        address indexed who,
        address indexed to,
        address indexed token,
        uint256 amount
    );

    event NewEmergencyCouncil(address newEmergencyCouncil);
    event NewHermezGovernanceAddress(address newHermezGovernanceAddress);

    // Event emitted when the contract is initialized
    event InitializeWithdrawalDelayerEvent(
        uint64 initialWithdrawalDelay,
        address initialHermezGovernanceAddress,
        address initialEmergencyCouncil
    );

    /**
     * @notice withdrawalDelayerInitializer (Constructor)
     * @param _initialWithdrawalDelay Initial withdrawal delay time in seconds to be able to withdraw the funds
     * @param _initialHermezRollup Smart contract responsible of making deposits and it's able to change the delay
     * @param _initialHermezGovernanceAddress can claim the funds in an emergency mode
     * @param _initialEmergencyCouncil can claim the funds in an emergency and MAX_EMERGENCY_MODE_TIME exceeded
     */
    constructor(
        uint64 _initialWithdrawalDelay,
        address _initialHermezRollup,
        address _initialHermezGovernanceAddress,
        address payable _initialEmergencyCouncil
    ) public {
        require(
            _initialHermezRollup != address(0),
            "WithdrawalDelayer::withdrawalDelayerInitializer ADDRESS_0_NOT_VALID"
        );

        _withdrawalDelay = _initialWithdrawalDelay;
        hermezRollupAddress = _initialHermezRollup;
        _hermezGovernance = _initialHermezGovernanceAddress;
        _emergencyCouncil = _initialEmergencyCouncil;
        _emergencyMode = false;

        emit InitializeWithdrawalDelayerEvent(
            _initialWithdrawalDelay,
            _initialHermezGovernanceAddress,
            _initialEmergencyCouncil
        );
    }

    /**
     * @notice Getter of the current `_hermezGovernance`
     * @return The `_hermezGovernance` value
     */
    function getHermezGovernanceAddress()
        external
        override
        view
        returns (address)
    {
        return _hermezGovernance;
    }

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param newGovernance The address to transfer governance to.
     */
    function transferGovernance(address newGovernance) public override {
        require(
            msg.sender == _hermezGovernance,
            "WithdrawalDelayer::transferGovernance: ONLY_GOVERNANCE"
        );
        pendingGovernance = newGovernance;
    }

    /**
     * @dev Allows the pendingGovernance address to finalize the transfer.
     */
    function claimGovernance() public override {
        require(
            msg.sender == pendingGovernance,
            "WithdrawalDelayer::claimGovernance: ONLY_PENDING_GOVERNANCE"
        );
        _hermezGovernance = pendingGovernance;
        pendingGovernance = address(0);
        emit NewHermezGovernanceAddress(_hermezGovernance);
    }

    /**
     * @notice Getter of the current `_emergencyCouncil`
     * @return The `_emergencyCouncil` value
     */
    function getEmergencyCouncil() external override view returns (address) {
        return _emergencyCouncil;
    }

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param newEmergencyCouncil The address to transfer governance to.
     */
    function transferEmergencyCouncil(address payable newEmergencyCouncil)
        public
        override
    {
        require(
            msg.sender == _emergencyCouncil,
            "WithdrawalDelayer::transferEmergencyCouncil: ONLY_EMERGENCY_COUNCIL"
        );
        pendingEmergencyCouncil = newEmergencyCouncil;
    }

    /**
     * @dev Allows the pendingGovernance address to finalize the transfer.
     */
    function claimEmergencyCouncil() public override {
        require(
            msg.sender == pendingEmergencyCouncil,
            "WithdrawalDelayer::claimEmergencyCouncil: ONLY_PENDING_GOVERNANCE"
        );
        _emergencyCouncil = pendingEmergencyCouncil;
        pendingEmergencyCouncil = address(0);
        emit NewEmergencyCouncil(_emergencyCouncil);
    }

    /**
     * @notice Getter of the current `_emergencyMode` status to know if the emergency mode is enable or disable
     * @return The `_emergencyMode` value
     */
    function isEmergencyMode() external override view returns (bool) {
        return _emergencyMode;
    }

    /**
     * @notice Getter to obtain the current withdrawal delay
     * @return the current withdrawal delay time in seconds: `_withdrawalDelay`
     */
    function getWithdrawalDelay() external override view returns (uint64) {
        return _withdrawalDelay;
    }

    /**
     * @notice Getter to obtain when emergency mode started
     * @return the emergency mode starting time in seconds: `_emergencyModeStartingTime`
     */
    function getEmergencyModeStartingTime()
        external
        override
        view
        returns (uint64)
    {
        return _emergencyModeStartingTime;
    }

    /**
     * @notice This function enables the emergency mode. Only the governance of the system can enable this mode. This cannot
     * be deactivated in any case so it will be irreversible.
     * @dev The activation time is saved in `_emergencyModeStartingTime` and this function can only be called
     * once if it has not been previously activated.
     * Events: `EmergencyModeEnabled` event.
     */
    function enableEmergencyMode() external override {
        require(
            msg.sender == _hermezGovernance,
            "WithdrawalDelayer::enableEmergencyMode: ONLY_GOVERNANCE"
        );
        require(
            !_emergencyMode,
            "WithdrawalDelayer::enableEmergencyMode: ALREADY_ENABLED"
        );
        _emergencyMode = true;
        /* solhint-disable not-rely-on-time */
        _emergencyModeStartingTime = uint64(now);
        emit EmergencyModeEnabled();
    }

    /**
     * @notice This function allows the governance to change the withdrawal delay time, this is the time that
     * anyone needs to wait until a withdrawal of the funds is allowed. Since this time is calculated at the time of
     * withdrawal, this change affects existing deposits. Can never exceed `MAX_WITHDRAWAL_DELAY`
     * @dev It changes `_withdrawalDelay` if `_newWithdrawalDelay` it is less than or equal to MAX_WITHDRAWAL_DELAY
     * @param _newWithdrawalDelay new delay time in seconds
     * Events: `NewWithdrawalDelay` event.
     */
    function changeWithdrawalDelay(uint64 _newWithdrawalDelay)
        external
        override
    {
        require(
            (msg.sender == _hermezGovernance) ||
                (msg.sender == hermezRollupAddress),
            "WithdrawalDelayer::changeWithdrawalDelay: ONLY_ROLLUP_OR_GOVERNANCE"
        );
        require(
            _newWithdrawalDelay <= MAX_WITHDRAWAL_DELAY,
            "WithdrawalDelayer::changeWithdrawalDelay: EXCEEDS_MAX_WITHDRAWAL_DELAY"
        );
        _withdrawalDelay = _newWithdrawalDelay;
        emit NewWithdrawalDelay(_withdrawalDelay);
    }

    /**
     * Returns the balance and the timestamp for a specific owner and token
     * @param _owner who can claim the deposit once the delay time has expired (if not in emergency mode)
     * @param _token address of the token to withdrawal (0x0 in case of Ether)
     * @return `amount` Total amount withdrawable (if not in emergency mode)
     * @return `depositTimestamp` Moment at which funds were deposited
     */
    function depositInfo(address payable _owner, address _token)
        external
        override
        view
        returns (uint192, uint64)
    {
        DepositState memory ds = deposits[keccak256(
            abi.encodePacked(_owner, _token)
        )];
        return (ds.amount, ds.depositTimestamp);
    }

    /**
     * Function to make a deposit in the WithdrawalDelayer smartcontract, only the Hermez rollup smartcontract can do it
     * @dev In case of an Ether deposit, the address `0x0` will be used and the corresponding amount must be sent in the
     * `msg.value`. In case of an ERC20 this smartcontract must have the approval to expend the token to
     * deposit to be able to make a transferFrom to itself.
     * @param _owner is who can claim the deposit once the withdrawal delay time has been exceeded
     * @param _token address of the token deposited (`0x0` in case of Ether)
     * @param _amount deposit amount
     * Events: `Deposit`
     */
    function deposit(
        address _owner,
        address _token,
        uint192 _amount
    ) external override payable nonReentrant {
        require(
            msg.sender == hermezRollupAddress,
            "WithdrawalDelayer::deposit: ONLY_ROLLUP"
        );
        if (msg.value != 0) {
            require(
                _token == address(0x0),
                "WithdrawalDelayer::deposit: WRONG_TOKEN_ADDRESS"
            );
            require(
                _amount == msg.value,
                "WithdrawalDelayer::deposit: WRONG_AMOUNT"
            );
        } else {
            require(
                IERC20(_token).allowance(hermezRollupAddress, address(this)) >=
                    _amount,
                "WithdrawalDelayer::deposit: NOT_ENOUGH_ALLOWANCE"
            );
            /* solhint-disable avoid-low-level-calls */
            (bool success, bytes memory data) = address(_token).call(
                abi.encodeWithSelector(
                    _TRANSFERFROM_SIGNATURE,
                    hermezRollupAddress,
                    address(this),
                    _amount
                )
            );
            // `transferFrom` method may return (bool) or nothing.
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "WithdrawalDelayer::deposit: TOKEN_TRANSFER_FAILED"
            );
        }
        _processDeposit(_owner, _token, _amount);
    }

    /**
     * @notice Internal call to make a deposit
     * @param _owner is who can claim the deposit once the withdrawal delay time has been exceeded
     * @param _token address of the token deposited (`0x0` in case of Ether)
     * @param _amount deposit amount
     * Events: `Deposit`
     */
    function _processDeposit(
        address _owner,
        address _token,
        uint192 _amount
    ) internal {
        // We identify a deposit with the keccak of its owner and the token
        bytes32 depositId = keccak256(abi.encodePacked(_owner, _token));
        uint192 newAmount = deposits[depositId].amount + _amount;
        require(
            newAmount >= deposits[depositId].amount,
            "WithdrawalDelayer::_processDeposit: DEPOSIT_OVERFLOW"
        );

        deposits[depositId].amount = newAmount;
        deposits[depositId].depositTimestamp = uint64(now);

        emit Deposit(
            _owner,
            _token,
            _amount,
            deposits[depositId].depositTimestamp
        );
    }

    /**
     * This function allows the owner to withdawal the funds. Emergency mode cannot be enabled and it must have exceeded
     * the withdrawal delay time
     * @dev `NonReentrant` modifier is used as a protection despite the state is being previously updated
     * @param _owner can claim the deposit once the delay time has expired
     * @param _token address of the token to withdrawal (0x0 in case of Ether)
     * Events: `Withdraw`
     */
    function withdrawal(address payable _owner, address _token)
        external
        override
        nonReentrant
    {
        require(!_emergencyMode, "WithdrawalDelayer::deposit: EMERGENCY_MODE");
        // We identify a deposit with the keccak of its owner and the token
        bytes32 depositId = keccak256(abi.encodePacked(_owner, _token));
        uint192 amount = deposits[depositId].amount;
        require(amount > 0, "WithdrawalDelayer::withdrawal: NO_FUNDS");
        require(
            uint64(now) >=
                deposits[depositId].depositTimestamp + _withdrawalDelay,
            "WithdrawalDelayer::withdrawal: WITHDRAWAL_NOT_ALLOWED"
        );

        // Update the state
        deposits[depositId].amount = 0;
        deposits[depositId].depositTimestamp = 0;

        // Make the transfer
        if (_token == address(0x0)) {
            _ethWithdrawal(_owner, uint256(amount));
        } else {
            _tokenWithdrawal(_token, _owner, uint256(amount));
        }

        emit Withdraw(_token, _owner, amount);
    }

    /**
     * Allows the Hermez Governance to withdawal the funds in the event that emergency mode was enable.
     * @dev `NonReentrant` modifier is used as a protection despite the state is being previously updated and this is
     * a security mechanism
     * @param _to where the funds will be sent
     * @param _token address of the token withdraw (0x0 in case of Ether)
     * @param _amount the amount to send
     * Events: `EscapeHatchWithdrawal`
     */
    function escapeHatchWithdrawal(
        address _to,
        address _token,
        uint256 _amount
    ) external override nonReentrant {
        require(
            _emergencyMode,
            "WithdrawalDelayer::escapeHatchWithdrawal: ONLY_EMODE"
        );
        require(
            msg.sender == _emergencyCouncil || msg.sender == _hermezGovernance,
            "WithdrawalDelayer::escapeHatchWithdrawal: ONLY_GOVERNANCE"
        );
        if (
            msg.sender == _emergencyCouncil &&
            _emergencyCouncil != _hermezGovernance
        ) {
            require(
                uint64(now) >=
                    _emergencyModeStartingTime + MAX_EMERGENCY_MODE_TIME,
                "WithdrawalDelayer::escapeHatchWithdrawal: NO_MAX_EMERGENCY_MODE_TIME"
            );
        }
        if (_token == address(0x0)) {
            _ethWithdrawal(_to, _amount);
        } else {
            _tokenWithdrawal(_token, _to, _amount);
        }
        emit EscapeHatchWithdrawal(msg.sender, _to, _token, _amount);
    }

    /**
     * Internal function to perform a ETH Withdrawal
     * @param to where the funds will be sent
     * @param amount address of the token withdraw (0x0 in case of Ether)
     */
    function _ethWithdrawal(address to, uint256 amount) internal {
        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = to.call{value: amount}("");
        require(success, "WithdrawalDelayer::_ethWithdrawal: TRANSFER_FAILED");
    }

    /**
     * Internal function to perform a Token Withdrawal
     * @param tokenAddress address of the token to transfer
     * @param to where the funds will be sent
     * @param amount address of the token withdraw (0x0 in case of Ether)
     */
    function _tokenWithdrawal(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        /* solhint-disable avoid-low-level-calls */
        (bool success, bytes memory data) = tokenAddress.call(
            abi.encodeWithSelector(_TRANSFER_SIGNATURE, to, amount)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "WithdrawalDelayer::_tokenWithdrawal: TOKEN_TRANSFER_FAILED"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

interface IWithdrawalDelayer {
    /**
     * @notice Getter of the current `_hermezGovernanceAddress`
     * @return The `_hermezGovernanceAddress` value
     */
    function getHermezGovernanceAddress() external view returns (address);

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param newGovernance The address to transfer governance to.
     */
    function transferGovernance(address newGovernance) external;

    /**
     * @dev Allows the pendingGovernance address to finalize the transfer.
     */
    function claimGovernance() external;

    /**
     * @notice Getter of the current `_emergencyCouncil`
     * @return The `_emergencyCouncil` value
     */
    function getEmergencyCouncil() external view returns (address);

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param newEmergencyCouncil The address to transfer governance to.
     */
    function transferEmergencyCouncil(address payable newEmergencyCouncil)
        external;

    /**
     * @dev Allows the pendingGovernance address to finalize the transfer.
     */
    function claimEmergencyCouncil() external;

    /**
     * @notice Getter of the current `_emergencyMode` status to know if the emergency mode is enable or disable
     * @return The `_emergencyMode` value
     */
    function isEmergencyMode() external view returns (bool);

    /**
     * @notice Getter to obtain the current withdrawal delay
     * @return the current withdrawal delay time in seconds: `_withdrawalDelay`
     */
    function getWithdrawalDelay() external view returns (uint64);

    /**
     * @notice Getter to obtain when emergency mode started
     * @return the emergency mode starting time in seconds: `_emergencyModeStartingTime`
     */
    function getEmergencyModeStartingTime() external view returns (uint64);

    /**
     * @notice This function enables the emergency mode. Only the keeper of the system can enable this mode. This cannot
     * be deactivated in any case so it will be irreversible.
     * @dev The activation time is saved in `_emergencyModeStartingTime` and this function can only be called
     * once if it has not been previously activated.
     * Events: `EmergencyModeEnabled` event.
     */
    function enableEmergencyMode() external;

    /**
     * @notice This function allows the HermezKeeperAddress to change the withdrawal delay time, this is the time that
     * anyone needs to wait until a withdrawal of the funds is allowed. Since this time is calculated at the time of
     * withdrawal, this change affects existing deposits. Can never exceed `MAX_WITHDRAWAL_DELAY`
     * @dev It changes `_withdrawalDelay` if `_newWithdrawalDelay` it is less than or equal to MAX_WITHDRAWAL_DELAY
     * @param _newWithdrawalDelay new delay time in seconds
     * Events: `NewWithdrawalDelay` event.
     */
    function changeWithdrawalDelay(uint64 _newWithdrawalDelay) external;

    /**
     * Returns the balance and the timestamp for a specific owner and token
     * @param _owner who can claim the deposit once the delay time has expired (if not in emergency mode)
     * @param _token address of the token to withdrawal (0x0 in case of Ether)
     * @return `amount` Total amount withdrawable (if not in emergency mode)
     * @return `depositTimestamp` Moment at which funds were deposited
     */
    function depositInfo(address payable _owner, address _token)
        external
        view
        returns (uint192, uint64);

    /**
     * Function to make a deposit in the WithdrawalDelayer smartcontract, only the Hermez rollup smartcontract can do it
     * @dev In case of an Ether deposit, the address `0x0` will be used and the corresponding amount must be sent in the
     * `msg.value`. In case of an ERC20 this smartcontract must have the approval to expend the token to
     * deposit to be able to make a transferFrom to itself.
     * @param _owner is who can claim the deposit once the withdrawal delay time has been exceeded
     * @param _token address of the token deposited (`0x0` in case of Ether)
     * @param _amount deposit amount
     * Events: `Deposit`
     */
    function deposit(
        address _owner,
        address _token,
        uint192 _amount
    ) external payable;

    /**
     * This function allows the owner to withdawal the funds. Emergency mode cannot be enabled and it must have exceeded
     * the withdrawal delay time
     * @dev `NonReentrant` modifier is used as a protection despite the state is being previously updated
     * @param _owner can claim the deposit once the delay time has expired
     * @param _token address of the token to withdrawal (0x0 in case of Ether)
     * Events: `Withdraw`
     */
    function withdrawal(address payable _owner, address _token) external;

    /**
     * Allows the Hermez Governance to withdawal the funds in the event that emergency mode was enable.
     * Note: An Aragon Court will have the right to veto over the call to this method
     * @dev `NonReentrant` modifier is used as a protection despite the state is being previously updated and this is
     * a security mechanism
     * @param _to where the funds will be sent
     * @param _token address of the token withdraw (0x0 in case of Ether)
     * @param _amount the amount to send
     * Events: `EscapeHatchWithdrawal`
     */
    function escapeHatchWithdrawal(
        address _to,
        address _token,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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
}

