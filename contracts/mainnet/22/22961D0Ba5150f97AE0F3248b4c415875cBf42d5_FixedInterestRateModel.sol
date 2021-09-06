// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../library/Ownable.sol";

interface IInterestRateModelClient {
    function updateInterest() external returns (bool);
}

/**
 * @title dForce's Fixed Interest Rate Model Contract
 * @author dForce
 */
contract FixedInterestRateModel is Ownable {
    // ratePerBlock must not exceed this value
    uint256 internal constant ratePerBlockMax = 0.001e18;

    /**
     * @notice The approximate number of Ethereum blocks produced each year
     * @dev This is not used internally, but is expected externally for an interest rate model
     */
    uint256 public constant blocksPerYear = 2425846;

    /**
     * @notice Borrow interest rates per block
     */
    mapping(address => uint256) public borrowRatesPerBlock;

    /**
     * @notice Supply interest rates per block
     */
    mapping(address => uint256) public supplyRatesPerBlock;

    /**
     * @dev Emitted when borrow rate for `target` is set to `rate`.
     */
    event BorrowRateSet(address target, uint256 rate);

    /**
     * @dev Emitted when supply rate for `target` is set to `rate`.
     */
    event SupplyRateSet(address target, uint256 rate);

    constructor() public {
        __Ownable_init();
    }

    /*********************************/
    /******** Security Check *********/
    /*********************************/

    /**
     * @notice Ensure this is an interest rate model contract.
     */
    function isInterestRateModel() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Get the current borrow rate per block
     * @param cash Not used by this model.
     * @param borrows Not used by this model.
     * @param reserves Not used by this model.
     * @return Current borrow rate per block (as a percentage, and scaled by 1e18).
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public view returns (uint256) {
        cash;
        borrows;
        reserves;
        return borrowRatesPerBlock[msg.sender];
    }

    /**
     * @dev Get the current supply interest rate per block.
     * @param cash Not used by this model.
     * @param borrows Not used by this model.
     * @param reserves Not used by this model.
     * @param reserveRatio Not used by this model.
     * @return The supply rate per block (as a percentage, and scaled by 1e18).
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveRatio
    ) external view returns (uint256) {
        cash;
        borrows;
        reserves;
        reserveRatio;
        return supplyRatesPerBlock[msg.sender];
    }

    /**
     * @notice Admin function to set the current borrow rate per block
     */
    function _setBorrowRate(address _target, uint256 _rate) public onlyOwner {
        require(_rate <= ratePerBlockMax, "Borrow rate invalid");

        // Settle interest before setting new one
        IInterestRateModelClient(_target).updateInterest();

        borrowRatesPerBlock[_target] = _rate;

        emit BorrowRateSet(_target, _rate);
    }

    /**
     * @notice Admin function to set the current supply interest rate per block
     */
    function _setSupplyRate(address _target, uint256 _rate) public onlyOwner {
        require(_rate <= ratePerBlockMax, "Supply rate invalid");

        // Settle interest before setting new one
        IInterestRateModelClient(_target).updateInterest();

        supplyRatesPerBlock[_target] = _rate;

        emit SupplyRateSet(_target, _rate);
    }

    /**
     * @notice Admin function to set the borrow interest rates per block for targets
     */
    function _setBorrowRates(
        address[] calldata _targets,
        uint256[] calldata _rates
    ) external onlyOwner {
        require(
            _targets.length == _rates.length,
            "Targets and rates length mismatch!"
        );

        uint256 _len = _targets.length;
        for (uint256 i = 0; i < _len; i++) {
            _setBorrowRate(_targets[i], _rates[i]);
        }
    }

    /**
     * @notice Admin function to set the supply interest rates per block for the targets
     */
    function _setSupplyRates(
        address[] calldata _targets,
        uint256[] calldata _rates
    ) external onlyOwner {
        require(
            _targets.length == _rates.length,
            "Targets and rates length mismatch!"
        );

        uint256 _len = _targets.length;
        for (uint256 i = 0; i < _len; i++) {
            _setSupplyRate(_targets[i], _rates[i]);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {_setPendingOwner} and {_acceptOwner}.
 */
contract Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    address payable public owner;

    /**
     * @dev Returns the address of the current pending owner.
     */
    address payable public pendingOwner;

    event NewOwner(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal {
        owner = msg.sender;
        emit NewOwner(address(0), msg.sender);
    }

    /**
     * @notice Base on the inputing parameter `newPendingOwner` to check the exact error reason.
     * @dev Transfer contract control to a new owner. The newPendingOwner must call `_acceptOwner` to finish the transfer.
     * @param newPendingOwner New pending owner.
     */
    function _setPendingOwner(address payable newPendingOwner)
        external
        onlyOwner
    {
        require(
            newPendingOwner != address(0) && newPendingOwner != pendingOwner,
            "_setPendingOwner: New owenr can not be zero address and owner has been set!"
        );

        // Gets current owner.
        address oldPendingOwner = pendingOwner;

        // Sets new pending owner.
        pendingOwner = newPendingOwner;

        emit NewPendingOwner(oldPendingOwner, newPendingOwner);
    }

    /**
     * @dev Accepts the admin rights, but only for pendingOwenr.
     */
    function _acceptOwner() external {
        require(
            msg.sender == pendingOwner,
            "_acceptOwner: Only for pending owner!"
        );

        // Gets current values for events.
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;

        // Set the new contract owner.
        owner = pendingOwner;

        // Clear the pendingOwner.
        pendingOwner = address(0);

        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }

    uint256[50] private __gap;
}

{
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
  },
  "libraries": {}
}