// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISystemSetting.sol";

contract SystemSetting is Ownable, ISystemSetting {
    uint256 private _maxInitialLiquidityFunding;   // decimals 6
    uint256 private _constantMarginRatio;
    mapping (uint32 => bool) private _leverages;
    uint256 private _minInitialMargin;             // decimals 6
    uint256 private _minAddDeposit;                // decimals 6
    uint256 private _minHoldingPeriod;
    uint256 private _marginRatio;
    uint256 private _positionClosingFee;
    uint256 private _liquidationFee;
    uint256 private _rebaseInterval;
    uint256 private _rebaseRate;
    uint256 private _imbalanceThreshold;
    uint256 private _minFundTokenRequired;         // decimals 6

    uint256 private constant POSITION_CLOSING_FEE_MIN = 1 * 1e15; // 1e15 / 1e18 = 0.1%
    uint256 private constant POSITION_CLOSING_FEE_MAX = 5 * 1e15; // 5e15 / 1e18 = 0.5%

    uint256 private constant LIQUIDATION_FEE_MIN = 1 * 1e16; // 1e16 / 1e18 = 1%
    uint256 private constant LIQUIDATION_FEE_MAX = 5 * 1e16; // 5e16 / 1e18 = 5%

    uint256 private constant REBASE_RATE_MIN = 20;
    uint256 private constant REBASE_RATE_MAX = 2000;

    bool private _active;

    function requireSystemActive() external override view {
        require(_active, "system is suspended");
    }

    function resumeSystem() external override onlyOwner {
        _active = true;
        emit Resume(msg.sender);
    }

    function suspendSystem() external override onlyOwner {
        _active = false;
        emit Suspend(msg.sender);
    }

    function maxInitialLiquidityFunding() external override view returns (uint256) {
        return _maxInitialLiquidityFunding;
    }

    function constantMarginRatio() external override view returns (uint256) {
        return _constantMarginRatio;
    }

    function leverageExist(uint32 leverage_) external override view returns (bool) {
        return _leverages[leverage_];
    }

    function minInitialMargin() external override view returns (uint256) {
        return _minInitialMargin;
    }

    function minAddDeposit() external override view returns (uint256) {
        return _minAddDeposit;
    }

    function minHoldingPeriod() external override view returns (uint) {
        return _minHoldingPeriod;
    }

    function marginRatio() external override view returns (uint256) {
        return _marginRatio;
    }

    function positionClosingFee() external override view returns (uint256) {
        return _positionClosingFee;
    }

    function liquidationFee() external override view returns (uint256) {
        return _liquidationFee;
    }

    function rebaseInterval() external override view returns (uint) {
        return _rebaseInterval;
    }

    function rebaseRate() external override view returns (uint) {
        return _rebaseRate;
    }

    function imbalanceThreshold() external override view returns (uint) {
        return _imbalanceThreshold;
    }

    function minFundTokenRequired() external override view returns (uint) {
        return _minFundTokenRequired;
    }

    function setMaxInitialLiquidityFunding(uint256 maxInitialLiquidityFunding_) external onlyOwner {
        _maxInitialLiquidityFunding = maxInitialLiquidityFunding_;
    }

    function setConstantMarginRatio(uint256 constantMarginRatio_) external onlyOwner {
        _constantMarginRatio = constantMarginRatio_;
    }

    function setMinInitialMargin(uint256 minInitialMargin_) external onlyOwner {
        _minInitialMargin = minInitialMargin_;
    }

    function setMinAddDeposit(uint minAddDeposit_) external onlyOwner {
        _minAddDeposit = minAddDeposit_;
    }

    function setMinHoldingPeriod(uint minHoldingPeriod_) external onlyOwner {
        _minHoldingPeriod = minHoldingPeriod_;
    }

    function setMarginRatio(uint256 marginRatio_) external onlyOwner {
        _marginRatio = marginRatio_;
    }

    function setPositionClosingFee(uint256 positionClosingFee_) external onlyOwner {
        require(positionClosingFee_ >= POSITION_CLOSING_FEE_MIN, "positionClosingFee_ should >= 0.1%");
        require(positionClosingFee_ <= POSITION_CLOSING_FEE_MAX, "positionClosingFee_ should <= 0.5%");

        _positionClosingFee = positionClosingFee_;
    }

    function setLiquidationFee(uint256 liquidationFee_) external onlyOwner {
        require(liquidationFee_ >= LIQUIDATION_FEE_MIN, "liquidationFee_ should >= 10%");
        require(liquidationFee_ <= LIQUIDATION_FEE_MAX, "liquidationFee_ should <= 20%");

        _liquidationFee = liquidationFee_;
    }

    function addLeverage(uint32 leverage_) external onlyOwner {
        _leverages[leverage_] = true;
    }

    function deleteLeverage(uint32 leverage_) external onlyOwner {
        _leverages[leverage_] = false;
    }

    function setRebaseInterval(uint rebaseInterval_) external onlyOwner {
        _rebaseInterval = rebaseInterval_;
    }

    function setRebaseRate(uint rebaseRate_) external onlyOwner {
        require(rebaseRate_ >= REBASE_RATE_MIN, "rebaseRate_ should >= 200");
        require(rebaseRate_ <= REBASE_RATE_MAX, "rebaseRate_ should <= 2000");

        _rebaseRate = rebaseRate_;
    }

    function setImbalanceThreshold(uint imbalanceThreshold_) external onlyOwner {
        _imbalanceThreshold = imbalanceThreshold_;
    }

    function setMinFundTokenRequired(uint minFundTokenRequired_) external onlyOwner {
        _minFundTokenRequired = minFundTokenRequired_;
    }

    function checkOpenPosition(uint position, uint16 level) external view override {
        require(_active, "system is suspended");
        require(_leverages[level], "Leverage Not Exist");
        require(_minInitialMargin <= position, "Too Less Initial Margin");
    }

    function checkAddDeposit(uint margin) external view override {
        require(_active, "system is suspended");
        require(_minAddDeposit <= margin, "Too Less Margin");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface ISystemSetting {
    // maxInitialLiquidityFunding
    function maxInitialLiquidityFunding() external view returns (uint256);

    // constantMarginRatio
    function constantMarginRatio() external view returns (uint256);

    // leverageExist
    function leverageExist(uint32 leverage_) external view returns (bool);

    // minInitialMargin
    function minInitialMargin() external view returns (uint256);

    // minAddDeposit
    function minAddDeposit() external view returns (uint256);

    // minHoldingPeriod
    function minHoldingPeriod() external view returns (uint);

    // marginRatio
    function marginRatio() external view returns (uint256);

    // positionClosingFee
    function positionClosingFee() external view returns (uint256);

    // liquidationFee
    function liquidationFee() external view returns (uint256);

    // rebaseInterval
    function rebaseInterval() external view returns (uint);

    // rebaseRate
    function rebaseRate() external view returns (uint);

    // imbalanceThreshold
    function imbalanceThreshold() external view returns (uint);

    // minFundTokenRequired
    function minFundTokenRequired() external view returns (uint);

    function checkOpenPosition(uint position, uint16 level) external view;
    function checkAddDeposit(uint margin) external view;

    function requireSystemActive() external;
    function resumeSystem() external;
    function suspendSystem() external;

    event Suspend(address indexed sender);
    event Resume(address indexed sender);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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