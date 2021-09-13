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

// contracts/SafeOwnable.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract SafeOwnable {
    address private _owner;
    address private _proposedOwner;

    event OwnershipProposed(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function proposedOwner() public view virtual returns (address) {
        return _proposedOwner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != _owner, "Ownable: proposed owner is the owner");
        emit OwnershipProposed(_owner, newOwner);
        _proposedOwner = newOwner;
    }

    function acceptOwnership() public virtual {
        require(msg.sender == _proposedOwner, "Ownable: not proposed owner");
        emit OwnershipTransferred(_owner, _proposedOwner);
        _owner = _proposedOwner;
        _proposedOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FluxWithdrawalInterface {
    /**
   * @notice transfers the oracle's LINK to another address. Can only be called
   * by the oracle's admin.
   * @param _oracle is the oracle whose LINK is transferred
   * @param _recipient is the address to send the LINK to
   * @param _amount is the amount of LINK to send
   */
    function withdrawPayment(address _oracle, address _recipient, uint256 _amount)
    external;

    /**
   * @notice query the available amount of LINK for an oracle to withdraw
   */
    function withdrawablePayment(address _oracle)
    external
    view
    returns (uint256);

    /**
   * @notice transfer the admin address for an oracle
   * @param _oracle is the address of the oracle whose admin is being transferred
   * @param _newAdmin is the new admin address
   */
    function transferAdmin(address _oracle, address _newAdmin)
    external;

    /**
   * @notice accept the admin address transfer for an oracle
   * @param _oracle is the address of the oracle whose admin is being transferred
   */
    function acceptAdmin(address _oracle)
    external;

    // DEV:
    function inspectSender() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperWithdrawalInterface {
    /**
   * @notice withdraws a keeper's payment, callable only by the keeper's payee
   * @param from keeper address
   * @param to address to send the payment to
   */
    function withdrawPayment(address from, address to)
    external;

    /**
   * @notice read the current info about any keeper address
   */
    function getKeeperInfo(
        address _keeper
    )
    external
    view
    returns (
        address payee,
        bool active,
        uint96 balance
    );

    /**
   * @notice proposes the safe transfer of a keeper's payee to another address
   * @param keeper address of the keeper to transfer payee role
   * @param proposed address to nominate for next payeeship
   */
    function transferPayeeship(
        address keeper,
        address proposed
    )
    external;

    /**
   * @notice accepts the safe transfer of payee role for a keeper
   * @param keeper address to accept the payee role for
   */
    function acceptPayeeship(
        address keeper
    )
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OffchainWithdrawalInterface {
    /**
   * @notice withdraws an oracle's payment from the contract
   * @param _transmitter the transmitter address of the oracle
   * @dev must be called by oracle's payee address
   */
    function withdrawPayment(address _transmitter)
    external;

    /**
   * @notice query an oracle's payment amount
   * @param _transmitter the transmitter address of the oracle
   */
    function owedPayment(address _transmitter)
    external
    view
    returns (uint256);

    /**
   * @notice first step of payeeship transfer (safe transfer pattern)
   * @param _transmitter transmitter address of oracle whose payee is changing
   * @param _proposed new payee address
   * @dev can only be called by payee address
   */
    function transferPayeeship(
        address _transmitter,
        address _proposed
    )
    external;

    /**
   * @notice second step of payeeship transfer (safe transfer pattern)
   * @param _transmitter transmitter address of oracle whose payee is changing
   * @dev can only be called by proposed new payee address
   */
    function acceptPayeeship(
        address _transmitter
    )
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleWithdrawalInterface {
    /**
   * @notice Allows the node operator to withdraw earned LINK to a given address
   * @dev The owner of the contract can be another wallet and does not have to be a Chainlink node
   * @param _recipient The address to send the LINK token to
   * @param _amount The amount to send (specified in wei)
   */
    function withdraw(address _recipient, uint256 _amount)
    external;

    /**
   * @notice Displays the amount of LINK that is available for the node operator to withdraw
   * @dev We use `ONE_FOR_CONSISTENT_GAS_COST` in place of 0 in storage
   * @return The amount of withdrawable LINK on the contract
   */
    function withdrawable() external view returns (uint256);

    /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
    function transferOwnership(address _newOwner) external;
}

// contracts/sweeper/FluxSweeper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/FluxWithdrawalInterface.sol";
import "../SafeOwnable.sol";

abstract contract FluxSweeper is SafeOwnable {
    address[] private aggregators;
    address[] private oracles;

    function getFluxAggregators() public view returns (address[] memory) {
        return aggregators;
    }

    function addFluxAggregators(address[] calldata _aggregators, address[] calldata _oracles) external onlyOwner() {
        require(_aggregators.length == _oracles.length, "must have equal length");
        _addFluxAggregators(_aggregators, _oracles);
    }

    function removeFluxAggregator(uint256 _index) external onlyOwner() {
        require(_index < aggregators.length, "Aggregator does not exist");
        _removeFluxAggregator(_index);
    }

    function withdrawableFlux(uint256 _minAmount) internal view returns (uint256 sum) {
        for (uint i = 0; i < aggregators.length; i++) {
            uint256 _amount = FluxWithdrawalInterface(aggregators[i]).withdrawablePayment(oracles[i]);
            if (_amount > _minAmount) {
                sum += _amount;
            }
        }
        return sum;
    }

    function withdrawFlux(uint256 _minAmount) internal {
        for (uint i = 0; i < aggregators.length; i++) {
            uint256 _amount = FluxWithdrawalInterface(aggregators[i]).withdrawablePayment(oracles[i]);
            if (_amount > _minAmount && _amount > 0) {
                FluxWithdrawalInterface(aggregators[i]).withdrawPayment(oracles[i], address(this), _amount);
            }
        }
    }

    function transferAdminFlux(uint256[] memory _contractIdxs, address _newAdmin) public onlyOwner() {
        require(_contractIdxs.length <= aggregators.length, "too many idxs");
        _transferAdminFlux(_contractIdxs, _newAdmin);
    }

    function acceptAdminFlux(uint256[] calldata _contractIdxs) public onlyOwner {
        require(_contractIdxs.length <= aggregators.length, "too many idxs");
        _acceptAdminFlux(_contractIdxs);
    }

    function _addFluxAggregators(address[] calldata _aggregators, address[] calldata _oracles) internal {
        for (uint i = 0; i < _aggregators.length; i++) {
            aggregators.push(_aggregators[i]);
            oracles.push(_oracles[i]);
        }
    }

    function _removeFluxAggregator(uint256 _index) internal {
        aggregators[_index] = aggregators[aggregators.length - 1];
        aggregators.pop();

        oracles[_index] = oracles[oracles.length - 1];
        oracles.pop();
    }

    function _transferAdminFlux(uint256[] memory _contractIdxs, address _newAdmin) internal {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            uint256 index = _contractIdxs[i];
            FluxWithdrawalInterface(aggregators[index]).transferAdmin(oracles[index], _newAdmin);
        }
    }

    function _acceptAdminFlux(uint256[] memory _contractIdxs) internal {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            uint256 index = _contractIdxs[i];
            FluxWithdrawalInterface(aggregators[index]).acceptAdmin(oracles[index]);
        }
    }

    function _transferAdminFluxAll(address _newAdmin) internal {
        for (uint i = 0; i < aggregators.length; i++) {
            FluxWithdrawalInterface(aggregators[i]).transferAdmin(oracles[i], _newAdmin);
        }
    }

    function _acceptAdminFluxAll() internal {
        for (uint i = 0; i < aggregators.length; i++) {
            FluxWithdrawalInterface(aggregators[i]).acceptAdmin(oracles[i]);
        }
    }
}

// contracts/sweeper/KeeperSweeper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/KeeperWithdrawalInterface.sol";
import "../SafeOwnable.sol";
import "./Sweepable.sol";

abstract contract KeeperSweeper is SafeOwnable, Sweepable {
    address[] private registries;
    address[] private keepers;

    function getKeeperRegistries() public view returns (address[] memory) {
        return registries;
    }

    function addKeeperRegistries(address[] calldata _registries, address[] calldata _keepers) external onlyOwner() {
        require(_registries.length == _keepers.length, "must have equal length");
        _addKeeperRegistries(_registries, _keepers);
    }

    function removeKeeperRegistry(uint256 _index) external onlyOwner() {
        require(_index < registries.length, "Aggregator does not exist");
        _removeKeeperRegistry(_index);
    }

    function withdrawableKeepers(uint256 _minAmount) internal view returns (uint256 sum) {
        for (uint i = 0; i < registries.length; i++) {
            (,,uint96 _amount) = KeeperWithdrawalInterface(registries[i]).getKeeperInfo(keepers[i]);
            if (uint256(_amount) > _minAmount && _amount > 0) {
                sum += _amount;
            }
        }
        return sum;
    }

    function withdrawKeepers(uint256 _minAmount) internal {
        for (uint i = 0; i < registries.length; i++) {
            (,,uint96 _amount) = KeeperWithdrawalInterface(registries[i]).getKeeperInfo(keepers[i]);
            if (uint256(_amount) > _minAmount && _amount > 0) {
                KeeperWithdrawalInterface(registries[i]).withdrawPayment(keepers[i], address(this));
            }
        }
    }

    function transferPayeeshipKeeper(uint256[] memory _contractIdxs, address _newPayee) public onlyOwner() {
        require(_contractIdxs.length <= registries.length, "too many idxs");
        _transferPayeeshipKeeper(_contractIdxs, _newPayee);
    }

    function acceptPayeeshipKeeper(uint256[] calldata _contractIdxs) public onlyOwner() {
        require(_contractIdxs.length <= registries.length, "too many idxs");
        _acceptPayeeshipKeeper(_contractIdxs);
    }

    function _addKeeperRegistries(address[] calldata _registries, address[] calldata _keepers) internal {
        for (uint i = 0; i < _registries.length; i++) {
            registries.push(_registries[i]);
            keepers.push(_keepers[i]);
        }
    }

    function _removeKeeperRegistry(uint256 _index) internal {
        registries[_index] = registries[registries.length - 1];
        registries.pop();

        keepers[_index] = keepers[keepers.length - 1];
        keepers.pop();
    }

    function _transferPayeeshipKeeper(uint256[] memory _contractIdxs, address _newPayee) internal {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            uint256 index = _contractIdxs[i];
            KeeperWithdrawalInterface(registries[index]).transferPayeeship(keepers[index], _newPayee);
        }
    }

    function _acceptPayeeshipKeeper(uint256[] memory _contractIdxs) internal {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            uint256 index = _contractIdxs[i];
            KeeperWithdrawalInterface(registries[index]).acceptPayeeship(keepers[index]);
        }
    }

    function _transferPayeeshipKeeperAll(address _newPayee) internal {
        for (uint i = 0; i < registries.length; i++) {
            KeeperWithdrawalInterface(registries[i]).transferPayeeship(keepers[i], _newPayee);
        }
    }

    function _acceptPayeeshipKeeperAll() internal {
        for (uint i = 0; i < registries.length; i++) {
            KeeperWithdrawalInterface(registries[i]).acceptPayeeship(keepers[i]);
        }
    }
}

// contracts/sweeper/OffchainSweeper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/OffchainWithdrawalInterface.sol";
import "../SafeOwnable.sol";
import "./Sweepable.sol";

abstract contract OffchainSweeper is SafeOwnable, Sweepable {
    address[] private aggregators;
    address[] private transmitters;

    function getOffchainAggregators() public view returns (address[] memory) {
        return aggregators;
    }

    function addOffchainAggregators(address[] calldata _aggregators, address[] calldata _transmitters) external onlyOwner() {
        require(_aggregators.length == _transmitters.length, "must have equal length");
        _addOffchainAggregators(_aggregators, _transmitters);
    }

    function removeOffchainAggregator(uint256 _index) external onlyOwner() {
        require(_index < aggregators.length, "Aggregator does not exist");
        _removeOffchainAggregator(_index);
    }

    function withdrawableOffchain(uint256 _minAmount) internal view returns (uint256 sum) {
        for (uint i = 0; i < aggregators.length; i++) {
            uint256 _amount = availableOnAggregator(aggregators[i], transmitters[i]);
            if (_amount > _minAmount && _amount > 0) {
                sum += _amount;
            }
        }
        return sum;
    }

    function withdrawOffchain(uint256 _minAmount) internal {
        for (uint i = 0; i < aggregators.length; i++) {
            uint256 _amount = availableOnAggregator(aggregators[i], transmitters[i]);
            if (_amount > _minAmount && _amount > 0) {
                OffchainWithdrawalInterface(aggregators[i]).withdrawPayment(transmitters[i]);
            }
        }
    }

    // Return the maximum amount that we can withdraw from the aggregator, limited by
    // either the owed payment or how much LINK is available on the contract.
    function availableOnAggregator(address _aggregator, address _transmitter) private view returns (uint256 balance) {
        uint256 _amount = OffchainWithdrawalInterface(_aggregator).owedPayment(_transmitter);
        uint256 _available = IERC20(token).balanceOf(_aggregator);
        if (_available < _amount) return 0; // If there's not enough LINK, the withdraw call would fail
        return _amount;
    }

    function transferPayeeshipOffchain(uint256[] memory _contractIdxs, address _newPayee) public onlyOwner() {
        require(_contractIdxs.length <= aggregators.length, "too many idxs");
        _transferPayeeshipOffchain(_contractIdxs, _newPayee);
    }

    function acceptPayeeshipOffchain(uint256[] calldata _contractIdxs) public onlyOwner() {
        require(_contractIdxs.length <= aggregators.length, "too many idxs");
        _acceptPayeeshipOffchain(_contractIdxs);
    }

    function _addOffchainAggregators(address[] calldata _aggregators, address[] calldata _transmitters) internal {
        for (uint i = 0; i < _aggregators.length; i++) {
            aggregators.push(_aggregators[i]);
            transmitters.push(_transmitters[i]);
        }
    }

    function _removeOffchainAggregator(uint256 _index) internal {
        aggregators[_index] = aggregators[aggregators.length - 1];
        aggregators.pop();

        transmitters[_index] = transmitters[transmitters.length - 1];
        transmitters.pop();
    }

    function _transferPayeeshipOffchain(uint256[] memory _contractIdxs, address _newPayee) internal {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            uint256 index = _contractIdxs[i];
            OffchainWithdrawalInterface(aggregators[index]).transferPayeeship(transmitters[index], _newPayee);
        }
    }

    function _acceptPayeeshipOffchain(uint256[] memory _contractIdxs) internal {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            uint256 index = _contractIdxs[i];
            OffchainWithdrawalInterface(aggregators[index]).acceptPayeeship(transmitters[index]);
        }
    }

    function _transferPayeeshipOffchainAll(address _newPayee) internal {
        for (uint i = 0; i < aggregators.length; i++) {
            OffchainWithdrawalInterface(aggregators[i]).transferPayeeship(transmitters[i], _newPayee);
        }
    }

    function _acceptPayeeshipOffchainAll() internal {
        for (uint i = 0; i < aggregators.length; i++) {
            OffchainWithdrawalInterface(aggregators[i]).acceptPayeeship(transmitters[i]);
        }
    }
}

// contracts/sweeper/OracleSweeper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/OracleWithdrawalInterface.sol";
import "../SafeOwnable.sol";

abstract contract OracleSweeper is SafeOwnable {
    address[] private oracles;

    function getOracles() public view returns (address[] memory) {
        return oracles;
    }

    function addOracles(address[] calldata _oracles) external onlyOwner() {
        _addOracles(_oracles);
    }

    function removeOracle(uint256 _index) external onlyOwner() {
        require(_index < oracles.length, "Oracle does not exist");
        _removeOracle(_index);
    }

    function withdrawableOracles(uint256 _minAmount) internal view returns (uint256 sum) {
        for (uint i = 0; i < oracles.length; i++) {
            uint256 _amount = OracleWithdrawalInterface(oracles[i]).withdrawable();
            if (_amount > _minAmount) {
                sum += _amount;
            }
        }
        return sum;
    }

    function withdrawOracles(uint256 _minAmount) internal {
        for (uint i = 0; i < oracles.length; i++) {
            uint256 _amount = OracleWithdrawalInterface(oracles[i]).withdrawable();
            if (_amount > _minAmount && _amount > 0) {
                OracleWithdrawalInterface(oracles[i]).withdraw(address(this), _amount);
            }
        }
    }

    function transferOwnershipOracles(uint256[] memory _contractIdxs, address _newOwner) public onlyOwner() {
        require(_contractIdxs.length <= oracles.length, "too many idxs");
        _transferOwnershipOracles(_contractIdxs, _newOwner);
    }

    function _addOracles(address[] calldata _oracles) internal {
        for (uint i = 0; i < _oracles.length; i++) {
            oracles.push(_oracles[i]);
        }
    }

    function _removeOracle(uint256 _index) internal {
        oracles[_index] = oracles[oracles.length - 1];
        oracles.pop();
    }

    function _transferOwnershipOracles(uint256[] memory _contractIdxs, address _newOwner) internal {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            uint256 index = _contractIdxs[i];
            OracleWithdrawalInterface(oracles[index]).transferOwnership(_newOwner);
        }
    }

    function _transferOwnershipOraclesAll(address _newOwner) internal {
        for (uint i = 0; i < oracles.length; i++) {
            OracleWithdrawalInterface(oracles[i]).transferOwnership(_newOwner);
        }
    }
}

// contracts/sweeper/Sweepable.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/OffchainWithdrawalInterface.sol";
import "../SafeOwnable.sol";

abstract contract Sweepable is SafeOwnable {
    address public token;
    uint256 public minAmount;
    address public recipient;

    constructor(address _token, address _recipient, uint256 _minAmount) {
        token = _token;
        recipient = _recipient;
        minAmount = _minAmount;
    }

    function setMinAmount(uint256 _minAmount) external onlyOwner() {
        minAmount = _minAmount;
    }

    function setRecipient(address _recipient) external onlyOwner() {
        recipient = _recipient;
    }

    function sweepableAmount() external view returns (uint256) {
        return _sweepableAmount(minAmount) + IERC20(token).balanceOf(address(this));
    }

    // Intentionally allow anyone to sweep the contract.
    // All tokens are sent to the recipient (set by owner).
    // This allows us to run insecure cronjobs that can sweep regularly.
    function sweepAll() external {
        _sweepAll(minAmount);

        sweepBalance();
    }

    function sweepableManualAmount() external view returns (uint256) {
        return _sweepableManualAmount(minAmount) + IERC20(token).balanceOf(address(this));
    }

    function sweepManual() external {
        _sweepManual(minAmount);

        sweepBalance();
    }

    function sweepBalance() public {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(recipient, balance);
        }
    }

    // proxy() takes an arbitrary list of addresses and data in case this contract is made
    // the admin, owner or payee of a contract that this contract does not have an interface for.
    // In these cases, this method should be used to transfer ownership to an updated contract
    // that holds the necessary interface to interact with it.
    function proxy(address[] calldata _addresses, bytes[] calldata _data) external onlyOwner() {
        require(_addresses.length == _data.length, "must have equal length");

        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(this), "cannot proxy to itself");
            // solhint-disable-next-line avoid-low-level-calls
            _addresses[i].call(_data[i]);
        }
    }

    function acceptNewSweeper() external onlyOwner() {
        _acceptNewSweeper();
    }

    function migrateSweeper(address _newSweeper) external onlyOwner() {
        _migrateSweeper(_newSweeper);
    }

    function _sweepableAmount(uint256 _minAmount) internal virtual view returns (uint256);
    function _sweepAll(uint256 _minAmount) internal virtual;
    function _sweepableManualAmount(uint256 _minAmount) internal virtual view returns (uint256);
    function _sweepManual(uint256 _minAmount) internal virtual;
    function _acceptNewSweeper() internal virtual;
    function _migrateSweeper(address _newSweeper) internal virtual;
}

// contracts/sweeper/Sweeper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../SafeOwnable.sol";
import "./FluxSweeper.sol";
import "./OffchainSweeper.sol";
import "./OracleSweeper.sol";
import "./Sweepable.sol";
import "./KeeperSweeper.sol";

/**
* @title SweeperV1
* @dev Sweeper contract that contains implementations for multiple contract types
*/
contract SweeperV1 is SafeOwnable, Sweepable, FluxSweeper, OffchainSweeper, OracleSweeper, KeeperSweeper {
    constructor(address _token, address _recipient, uint256 _minAmount)
    Sweepable(_token, _recipient, _minAmount)
    {}

    function _sweepableAmount(uint256 _minAmount) internal override view returns (uint256) {
        return withdrawableFlux(_minAmount)
        + withdrawableOffchain(_minAmount)
        + withdrawableOracles(_minAmount)
        + withdrawableKeepers(_minAmount);
    }

    // Intentionally allow anyone to sweep the contract.
    // All tokens are sent to the recipient (set by owner).
    // This allows us to run insecure cronjobs that can sweep regularly.
    function _sweepAll(uint256 _minAmount) internal override {
        withdrawFlux(_minAmount);
        withdrawOffchain(_minAmount);
        withdrawOracles(_minAmount);
        withdrawKeepers(_minAmount);
    }

    function _sweepableManualAmount(uint256 _minAmount) internal override view returns (uint256) {
        return withdrawableFlux(minAmount)
        + withdrawableOracles(_minAmount)
        + withdrawableKeepers(_minAmount);
    }

    function _sweepManual(uint256 _minAmount) internal override {
        withdrawFlux(_minAmount);
        withdrawOracles(_minAmount);
        withdrawKeepers(_minAmount);
    }

    function _acceptNewSweeper() internal override {
        _acceptAdminFluxAll();
        _acceptPayeeshipOffchainAll();
        _acceptPayeeshipKeeperAll();
    }

    function _migrateSweeper(address _newSweeper) internal override {
        _transferAdminFluxAll(_newSweeper);
        _transferPayeeshipOffchainAll(_newSweeper);
        _transferPayeeshipKeeperAll(_newSweeper);
        _transferOwnershipOraclesAll(_newSweeper);
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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