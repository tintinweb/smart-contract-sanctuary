// File: openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/BankConfig.sol

pragma solidity 0.5.16;

interface BankConfig {
    /// @dev Return minimum ETH debt size per position.
    function minDebtSize() external view returns (uint256);

    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

    /// @dev Return the bps rate for reserve pool.
    function getReservePoolBps() external view returns (uint256);

    /// @dev Return the bps rate for Avada Kill caster.
    function getKillBps() external view returns (uint256);

    /// @dev Return whether the given address is a goblin.
    function isGoblin(address goblin) external view returns (bool);

    /// @dev Return whether the given goblin accepts more debt. Revert on non-goblin.
    function acceptDebt(address goblin) external view returns (bool);

    /// @dev Return the work factor for the goblin + ETH debt, using 1e4 as denom. Revert on non-goblin.
    function workFactor(address goblin, uint256 debt) external view returns (uint256);

    /// @dev Return the kill factor for the goblin + ETH debt, using 1e4 as denom. Revert on non-goblin.
    function killFactor(address goblin, uint256 debt) external view returns (uint256);
}

// File: contracts/SimpleBankConfig.sol

pragma solidity 0.5.16;



contract SimpleBankConfig is BankConfig, Ownable {
    /// @notice Configuration for each goblin.
    struct GoblinConfig {
        bool isGoblin;
        bool acceptDebt;
        uint256 workFactor;
        uint256 killFactor;
    }

    /// The minimum ETH debt size per position.
    uint256 public minDebtSize;
    /// The interest rate per second, multiplied by 1e18.
    uint256 public interestRate;
    /// The portion of interests allocated to the reserve pool.
    uint256 public getReservePoolBps;
    /// The reward for successfully killing a position.
    uint256 public getKillBps;
    /// Mapping for goblin address to its configuration.
    mapping (address => GoblinConfig) goblins;

    constructor(
        uint256 _minDebtSize,
        uint256 _interestRate,
        uint256 _reservePoolBps,
        uint256 _killBps
    ) public {
        setParams(_minDebtSize, _interestRate, _reservePoolBps, _killBps);
    }

    /// @dev Set all the basic parameters. Must only be called by the owner.
    /// @param _minDebtSize The new minimum debt size value.
    /// @param _interestRate The new interest rate per second value.
    /// @param _reservePoolBps The new interests allocated to the reserve pool value.
    /// @param _killBps The new reward for killing a position value.
    function setParams(
        uint256 _minDebtSize,
        uint256 _interestRate,
        uint256 _reservePoolBps,
        uint256 _killBps
    ) public onlyOwner {
        minDebtSize = _minDebtSize;
        interestRate = _interestRate;
        getReservePoolBps = _reservePoolBps;
        getKillBps = _killBps;
    }

    /// @dev Set the configuration for the given goblin. Must only be called by the owner.
    /// @param goblin The goblin address to set configuration.
    /// @param _isGoblin Whether the given address is a valid goblin.
    /// @param _acceptDebt Whether the goblin is accepting new debts.
    /// @param _workFactor The work factor value for this goblin.
    /// @param _killFactor The kill factor value for this goblin.
    function setGoblin(
        address goblin,
        bool _isGoblin,
        bool _acceptDebt,
        uint256 _workFactor,
        uint256 _killFactor
    ) public onlyOwner {
        goblins[goblin] = GoblinConfig({
            isGoblin: _isGoblin,
            acceptDebt: _acceptDebt,
            workFactor: _workFactor,
            killFactor: _killFactor
        });
    }

    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 /* debt */, uint256 /* floating */) external view returns (uint256) {
        return interestRate;
    }

    /// @dev Return whether the given address is a goblin.
    function isGoblin(address goblin) external view returns (bool) {
        return goblins[goblin].isGoblin;
    }

    /// @dev Return whether the given goblin accepts more debt. Revert on non-goblin.
    function acceptDebt(address goblin) external view returns (bool) {
        require(goblins[goblin].isGoblin, "!goblin");
        return goblins[goblin].acceptDebt;
    }

    /// @dev Return the work factor for the goblin + ETH debt, using 1e4 as denom. Revert on non-goblin.
    function workFactor(address goblin, uint256 /* debt */) external view returns (uint256) {
        require(goblins[goblin].isGoblin, "!goblin");
        return goblins[goblin].workFactor;
    }

    /// @dev Return the kill factor for the goblin + ETH debt, using 1e4 as denom. Revert on non-goblin.
    function killFactor(address goblin, uint256 /* debt */) external view returns (uint256) {
        require(goblins[goblin].isGoblin, "!goblin");
        return goblins[goblin].killFactor;
    }
}