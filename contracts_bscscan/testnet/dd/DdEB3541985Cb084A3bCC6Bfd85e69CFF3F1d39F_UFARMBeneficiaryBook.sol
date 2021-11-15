// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

import "./access/Ownable.sol";

contract UFARMBeneficiaryBook is Ownable {
    /// @notice mapping for stroring beneficiaries
    mapping(address => Beneficiary[]) public beneficiaries;

    /// @notice struct Beneficiaries for storing beneficiary details
    struct Beneficiary {
        address beneficiaryAddress;
        address vestAddress;
        uint256 claimTokens;
    }

    /// @notice An Activation event occurs on every beneficiary activation.

    event Activated(address account, address vest, uint256 claimTokens, uint256 time);

    /// @notice An Unactivation event occurs on every beneficiary UnActivation.
    event UnActivated(address account, address vest, uint256 time);

    constructor() Ownable(_msgSender()) {}

    /**
     * @notice get block timestamp.
     * @return block timestamp.
     */

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Activate Single Beneficiary. called by only Owner. revert on zero address.
     * @param account A Beneficiary Address.
     * @param vest vest Address.
     * @param tokens no of claimable tokens.
     */

    function singleActivation(
        address account,
        address vest,
        uint256 tokens
    ) external onlyOwner {
        require(account != address(0), "UFARMBeneficiaryBook: Activation failed");
        require(vest != address(0), "UFARMBeneficiaryBook: Invalid Vesting Address");
        Beneficiary memory holder = Beneficiary(account, vest, tokens);
        beneficiaries[account].push(holder);
        emit Activated(account, vest, tokens, _getNow());
    }

    /**
     * @notice Activate Multiple Beneficiary once. called by only Owner. revert on zero address.
     * @param accounts Array of Beneficiary Address.
     * @param vest Array of vest Address.
     * @param tokens Array of claimTokens which consist no of claimable tokens.
     */

    function multiActivation(
        address[] memory accounts,
        address[] memory vest,
        uint256[] memory tokens
    ) external onlyOwner {
        require(vest.length <= 5, "UFARMBeneficiaryBook: limit exhausted");
        require(
            accounts.length == vest.length ||
                vest.length == tokens.length ||
                tokens.length == accounts.length,
            "UFARMBeneficiaryBook: Invalid length."
        );

        for (uint8 u = 0; u < vest.length; u++) {
            require(accounts[u] != address(0), "UFARMBeneficiaryBook: Activation failed");
            require(vest[u] != address(0), "UFARMBeneficiaryBook: Invalid Vesting Address");

            beneficiaries[accounts[u]].push(
                Beneficiary({
                    beneficiaryAddress: accounts[u],
                    vestAddress: vest[u],
                    claimTokens: tokens[u]
                })
            );

            emit Activated(accounts[u], vest[u], tokens[u], _getNow());
        }
    }

    /**
     * @notice unActivate Beneficiary from Specific Vesting. called by only Owner. account should not be zero address.
     * @param account A Beneficiary Address.
     * @param index An insertId.
     * @return it returns true on success.
     */

    function unActivate(address account, uint8 index) external onlyOwner returns (bool) {
        require(account != address(0), "UFARMBeneficiaryBook: UnActivation failed");
        delete beneficiaries[account][index];
        emit UnActivated(account, beneficiaries[account][index].vestAddress, _getNow());
        return true;
    }

    /**
     * @notice unActivate Beneficiary from All Vesting. called by only Owner. account should not be zero address.
     * @param account A Beneficiary Address.
     * @return it returns true on success.
     */

    function unActivateForAll(address account) external onlyOwner returns (bool) {
        require(account != address(0), "UFARMBeneficiaryBook: UnActivation failed");
        delete beneficiaries[account];
        return true;
    }

    /**
     * @notice called by the each vesting contract for beneficiary Activation.
     * @param account A Beneficiary Address.
     * @param index An Insert id.
     * @return this will returns beneficiary, vestAddress and his claimable tokens.
     */

    function isBeneficiary(address account, uint256 index)
        public
        view
        returns (
            bool,
            address,
            uint256
        )
    {
        Beneficiary storage holders = beneficiaries[account][index];
        return (holders.beneficiaryAddress == account, holders.vestAddress, holders.claimTokens);
    }

    /**
     * @notice externally called by the frontend to determine his activation on specific vest path.
     * @param account An address of beneficiary.
     * @return length of beneficiaries Array.
     */

    function beneficiaryActivationCount(address account) public view returns (uint256) {
        return beneficiaries[account].length;
    }
}

// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

import "../security/Pausable.sol";

abstract contract Ownable is Pausable {
    /// @notice store owner.
    address public owner;

    /// @notice store superAdmin using for reverting ownership.
    address public superAdmin;

    /// @notice OwnershipTransferred emit on each ownership transfered.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address ownerAddress) {
        owner = ownerAddress;
        superAdmin = ownerAddress;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(superAdmin == _msgSender(), "Ownable: caller is not the admin");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyAdmin {
        emit OwnershipTransferred(owner, superAdmin);
        owner = superAdmin;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

import "../access/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

