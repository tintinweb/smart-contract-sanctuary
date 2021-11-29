// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IOracle.sol";
import "../interface/IChainlink.sol";
import "../common/Ownable.sol";
import "../common/Governable.sol";

contract CapcPricer is Ownable, Governable {

    enum Coin {CUSD, CPT}

    address public usdcAddress;

    IChainlink public usdcChainlink;
    uint8 public usdcPriceDecimals;

    IOracle public CusdOracle;
    IOracle public cptUsdcOracle;

    uint256 public collateralRatio = 800000;
    uint256 public lastUpdateTime;
    uint256 public ratioStep = 2500;
    uint256 public priceBand = 5000;
    uint256 public updateCooldown = 3600;

    uint256 public constant CAPC_DECIMAL = 1e6;

    modifier onlyGovernor() {
        require(msg.sender == owner() || msg.sender == timelock() || msg.sender == controller(), "Only Governor!");
        _;
    }

    function updateCollateralRatio() public {
        uint256 cusdPrice = getCUSDPrice();
        require(block.timestamp - lastUpdateTime >= updateCooldown, "Wait after cooldown!");

        if (cusdPrice > CAPC_DECIMAL + priceBand) {
            if (collateralRatio <= ratioStep)
                collateralRatio = 0;
            else
                collateralRatio -= ratioStep;
        } else if (cusdPrice < CAPC_DECIMAL - priceBand) {
            if (collateralRatio + ratioStep >= 1000000)
                collateralRatio = 1000000;
            else
                collateralRatio += ratioStep;
        }

        lastUpdateTime = block.timestamp;
    }

    function setRatioStep(uint256 newStep) public onlyGovernor {
        ratioStep = newStep;
    }

    function setUpdateCooldown(uint256 newCooldown) public onlyGovernor {
        updateCooldown = newCooldown;
    }

    function setPriceBand(uint256 newBand) public onlyGovernor {
        priceBand = newBand;
    }

    function setCollateralRatio(uint256 newRatio) public onlyGovernor {
        collateralRatio = newRatio;
    }

    function setLastUpdateTime(uint256 newTime) public onlyGovernor {
        lastUpdateTime = newTime;
    }

    function setUsdcAddress(address newAddress) public onlyGovernor {
        usdcAddress = newAddress;
    }

    function setCusdOracle(address oracleAddr) public onlyGovernor {
        CusdOracle = IOracle(oracleAddr);
    }

    function setCptOracle(address oracleAddr) public onlyGovernor {
        cptUsdcOracle = IOracle(oracleAddr);
    }

    function setUsdcChainLink(address chainlinkAddress) public onlyGovernor {
        usdcChainlink = IChainlink(chainlinkAddress);
        usdcPriceDecimals = usdcChainlink.getDecimals();
    }

    function setController(address newController) public onlyOwner {
        _setController(newController);
    }

    function setTimelock(address newTimelock) public onlyOwner {
        _setTimelock(newTimelock);
    }


    function getCUSDPrice() public view returns (uint256) {
        return oraclePrice(Coin.CUSD);
    }

    function getCPTPrice() public view returns (uint256) {
        return oraclePrice(Coin.CPT);
    }

    function getUSDCPrice() public view returns (uint256) {
        return uint256(usdcChainlink.getLatestPrice()) * (CAPC_DECIMAL) / (uint256(10) ** usdcPriceDecimals);
    }

    function oraclePrice(Coin choice) internal view returns (uint256) {
        uint256 usdcPriceInUSD = uint256(usdcChainlink.getLatestPrice()) * (CAPC_DECIMAL) / (uint256(10) ** usdcPriceDecimals);

        uint256 priceVsUsdc;

        if (choice == Coin.CUSD) {
            priceVsUsdc = uint256(CusdOracle.consult(usdcAddress, CAPC_DECIMAL));
        } else if (choice == Coin.CPT) {
            priceVsUsdc = uint256(cptUsdcOracle.consult(usdcAddress, CAPC_DECIMAL));
        }

        else revert("INVALID COIN!");

        return usdcPriceInUSD * CAPC_DECIMAL / priceVsUsdc;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic governing control mechanism, where
 * there is an governing account that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governing account will be empty. This
 * can later be changed by governor or owner.
 *
 */
abstract contract Governable is Context {
    
    address internal _controller;
    address internal _timelock;

    event ControllerTransferred(address indexed previousController, address indexed newController);
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);
    
    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view virtual returns (address) {
        return _controller;
    }
    
    /**
     * @dev Returns the address of the current timelock.
     */
    function timelock() public view virtual returns (address) {
        return _timelock;
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(controller() == _msgSender(), "Controller: caller is not the controller");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the timelock.
     */
    modifier onlyTimelock() {
        require(timelock() == _msgSender(), "Timelock: caller is not the timelock");
        _;
    }

    /**
     * @dev Transfers controller of the contract to a new account
     * Can only be called by the current controller.
     */
    function transferController(address newController) public virtual onlyController {
        require(newController != address(0), "Controller: new controller is the zero address");
        _setController(newController);
    }

    /**
    * @dev Leaves the contract without controller. It will not be possible to call
     * `onlyController` functions anymore. Can only be called by the current owner.
     */
    function renounceController() public virtual onlyController {
        _setController(address(0));
    }

    function _setController(address newController) internal {
        address old = _controller;
        _controller = newController;
        emit ControllerTransferred(old, newController);
    }
    
    /**
     * @dev Transfers timelock of the contract to a new account
     * Can only be called by the current timelock.
     */
    function transferTimelock(address newTimelock) public virtual onlyTimelock {
        require(newTimelock != address(0), "Timelock: new timelock is the zero address");
        _setTimelock(newTimelock);
    }
    
    /**
    * @dev Leaves the contract without timelock. It will not be possible to call
     * `onlyTimelock` functions anymore. Can only be called by the current owner.
     */
    function renounceTimelock() public virtual onlyTimelock {
        _setTimelock(address(0));
    }

    function _setTimelock(address newTimelock) internal {
        address old = _timelock;
        _timelock = newTimelock;
        emit TimelockTransferred(old, newTimelock);
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), "Only Owner!");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlink {

    function getLatestPrice() external view returns (int);

    function getDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {

    function consult(address token, uint amountIn) external view returns (uint amountOut);

    function update() external;
}