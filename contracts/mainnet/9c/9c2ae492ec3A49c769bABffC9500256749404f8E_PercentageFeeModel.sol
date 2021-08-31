// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

interface IFeeModel {
    function beneficiary() external view returns (address payable);

    function getInterestFeeAmount(address pool, uint256 interestAmount)
        external
        view
        returns (uint256 feeAmount);

    function getEarlyWithdrawFeeAmount(
        address pool,
        uint64 depositID,
        uint256 withdrawnDepositAmount
    ) external view returns (uint256 feeAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFeeModel} from "./IFeeModel.sol";

contract PercentageFeeModel is IFeeModel, Ownable {
    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant MAX_INTEREST_FEE = 50 * 10**16; // 50%
    uint256 internal constant MAX_EARLY_WITHDRAW_FEE = 5 * 10**16; // 5%

    struct FeeOverride {
        bool isOverridden;
        uint256 fee;
    }

    address payable public override beneficiary;
    mapping(address => FeeOverride) public interestFeeOverrideForPool;
    mapping(address => FeeOverride) public earlyWithdrawFeeOverrideForPool;
    mapping(address => mapping(uint64 => FeeOverride))
        public earlyWithdrawFeeOverrideForDeposit;

    uint256 public interestFee;
    uint256 public earlyWithdrawFee;

    event SetBeneficiary(address newBeneficiary);
    event SetInterestFee(uint256 newValue);
    event SetEarlyWithdrawFee(uint256 newValue);
    event OverrideInterestFeeForPool(address indexed pool, uint256 newFee);
    event OverrideEarlyWithdrawFeeForPool(address indexed pool, uint256 newFee);
    event OverrideEarlyWithdrawFeeForDeposit(
        address indexed pool,
        uint64 indexed depositID,
        uint256 newFee
    );

    constructor(
        address payable _beneficiary,
        uint256 _interestFee,
        uint256 _earlyWithdrawFee
    ) {
        require(
            _beneficiary != address(0) &&
                _interestFee <= MAX_INTEREST_FEE &&
                _earlyWithdrawFee <= MAX_EARLY_WITHDRAW_FEE,
            "PercentageFeeModel: invalid input"
        );
        beneficiary = _beneficiary;
        interestFee = _interestFee;
        earlyWithdrawFee = _earlyWithdrawFee;
    }

    function getInterestFeeAmount(address pool, uint256 interestAmount)
        external
        view
        override
        returns (uint256 feeAmount)
    {
        uint256 feeRate;
        FeeOverride memory feeOverrideForPool =
            interestFeeOverrideForPool[pool];
        if (feeOverrideForPool.isOverridden) {
            // fee has been overridden for pool
            feeRate = feeOverrideForPool.fee;
        } else {
            // use default fee
            feeRate = interestFee;
        }
        return (interestAmount * feeRate) / PRECISION;
    }

    function getEarlyWithdrawFeeAmount(
        address pool,
        uint64 depositID,
        uint256 withdrawnDepositAmount
    ) external view override returns (uint256 feeAmount) {
        uint256 feeRate;
        FeeOverride memory feeOverrideForDeposit =
            earlyWithdrawFeeOverrideForDeposit[pool][depositID];
        if (feeOverrideForDeposit.isOverridden) {
            // fee has been overridden for deposit
            feeRate = feeOverrideForDeposit.fee;
        } else {
            FeeOverride memory feeOverrideForPool =
                earlyWithdrawFeeOverrideForPool[pool];
            if (feeOverrideForPool.isOverridden) {
                // fee has been overridden for pool
                feeRate = feeOverrideForPool.fee;
            } else {
                // use default fee
                feeRate = earlyWithdrawFee;
            }
        }
        return (withdrawnDepositAmount * feeRate) / PRECISION;
    }

    function setBeneficiary(address payable newValue) external onlyOwner {
        require(newValue != address(0), "PercentageFeeModel: 0 address");
        beneficiary = newValue;
        emit SetBeneficiary(newValue);
    }

    function setInterestFee(uint256 newValue) external onlyOwner {
        require(newValue <= MAX_INTEREST_FEE, "PercentageFeeModel: too big");
        interestFee = newValue;
        emit SetInterestFee(newValue);
    }

    function setEarlyWithdrawFee(uint256 newValue) external onlyOwner {
        require(
            newValue <= MAX_EARLY_WITHDRAW_FEE,
            "PercentageFeeModel: too big"
        );
        earlyWithdrawFee = newValue;
        emit SetEarlyWithdrawFee(newValue);
    }

    function overrideInterestFeeForPool(address pool, uint256 newFee)
        external
        onlyOwner
    {
        require(newFee <= interestFee, "PercentageFeeModel: too big");
        interestFeeOverrideForPool[pool] = FeeOverride({
            isOverridden: true,
            fee: newFee
        });
        emit OverrideInterestFeeForPool(pool, newFee);
    }

    function overrideEarlyWithdrawFeeForPool(address pool, uint256 newFee)
        external
        onlyOwner
    {
        require(newFee <= earlyWithdrawFee, "PercentageFeeModel: too big");
        earlyWithdrawFeeOverrideForPool[pool] = FeeOverride({
            isOverridden: true,
            fee: newFee
        });
        emit OverrideEarlyWithdrawFeeForPool(pool, newFee);
    }

    function overrideEarlyWithdrawFeeForDeposit(
        address pool,
        uint64 depositID,
        uint256 newFee
    ) external onlyOwner {
        require(newFee <= earlyWithdrawFee, "PercentageFeeModel: too big");
        earlyWithdrawFeeOverrideForDeposit[pool][depositID] = FeeOverride({
            isOverridden: true,
            fee: newFee
        });
        emit OverrideEarlyWithdrawFeeForDeposit(pool, depositID, newFee);
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