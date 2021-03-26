//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface IDeployer {

    function deploy(bytes calldata _data) external returns(address);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface IInsurance {

    function stake(uint256 amount, address market) external;

    function withdraw(uint256 amount, address market) external;

    function reward(uint256 amount, address market) external;

    function updatePoolAmount(address market) external;

    function drainPool(address market, uint256 amount) external;

    function deployInsurancePool(address market) external;

    function getPoolUserBalance(address market, address user) external view returns (uint256);

    function getRewardsPerToken(address market) external view returns (uint256);

    function getPoolToken(address market) external view returns (address);

    function getPoolTarget(address market) external view returns (uint256);

    function getPoolHoldings(address market) external view returns (uint256);

    function getPoolFundingRate(address market) external view returns (uint256);

    function poolNeedsFunding(address market) external view returns (bool);

    function isInsured(address market) external view returns (bool);

    function setFactory(address tracerFactory) external;

    function setAccountContract(address accountContract) external;

    function INSURANCE_MUL_FACTOR() external view returns (int256);
    
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface ITracer {

    function makeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration
    ) external returns (uint256);

    function permissionedMakeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration,
        address maker
    ) external returns (uint256);

    function takeOrder(uint256 orderId, uint256 amount) external;

    function permissionedTakeOrder(uint256 orderId, uint256 amount, address taker) external;

    function settle(address account) external;

    function tracerBaseToken() external view returns (address);

    function marketId() external view returns(bytes32);

    function leveragedNotionalValue() external view returns(int256);

    function oracle() external view returns(address);

    function gasPriceOracle() external view returns(address);

    function priceMultiplier() external view returns(uint256);

    function feeRate() external view returns(uint256);

    function maxLeverage() external view returns(int256);

    function LIQUIDATION_GAS_COST() external pure returns(uint256);

    function FUNDING_RATE_SENSITIVITY() external pure returns(uint256);

    function currentHour() external view returns(uint8);

    function getOrder(uint orderId) external view returns(uint256, uint256, int256, bool, address, uint256);

    function getOrderTakerAmount(uint256 orderId, address taker) external view returns(uint256);

    function tracerGetBalance(address account) external view returns(
        int256 margin,
        int256 position,
        int256 totalLeveragedValue,
        uint256 deposited,
        int256 lastUpdatedGasPrice,
        uint256 lastUpdatedIndex
    );

    function setUserPermissions(address account, bool permission) external;

    function setInsuranceContract(address insurance) external;

    function setAccountContract(address account) external;

    function setPricingContract(address pricing) external;

    function setOracle(address _oracle) external;

    function setGasOracle(address _gasOracle) external;

    function setFeeRate(uint256 _feeRate) external;

    function setMaxLeverage(int256 _maxLeverage) external;

    function setFundingRateSensitivity(uint256 _fundingRateSensitivity) external;

    function transferOwnership(address newOwner) external;

    function initializePricing() external;

    function matchOrders(uint order1, uint order2) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface ITracerFactory {

    function tracersByIndex(uint256 count) external view returns (address);

    function validTracers(address market) external view returns (bool);

    function daoApproved(address market) external view returns (bool);

    function setInsuranceContract(address newInsurance) external;

    function setDeployerContract(address newDeployer) external;

    function setApproved(address market, bool value) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "./Interfaces/ITracer.sol";
import "./Interfaces/IInsurance.sol";
import "./Interfaces/ITracerFactory.sol";
import "./Interfaces/IDeployer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TracerFactory is Ownable, ITracerFactory {

    uint256 public tracerCounter;
    address public insurance;
    address public deployer;

    // Index of Tracer (where 0 is index of first Tracer market), corresponds to tracerCounter => market address
    mapping(uint256 => address) public override tracersByIndex;
    // Tracer market => whether that address is a valid Tracer or not
    mapping(address => bool) public override validTracers;
    // Tracer market => whether this address is a DAO approved market.
    // note markets deployed by the DAO are by default approved
    mapping(address => bool) public override daoApproved;

    event TracerDeployed(bytes32 indexed marketId, address indexed market);

    constructor(
        address _insurance,
        address _deployer,
        address _governance
    ) public {
        setInsuranceContract(_insurance);
        setDeployerContract(_deployer);
        transferOwnership(_governance);
    }

    /**
     * @notice Allows any user to deploy a tracer market
     * @param _data The data that will be used as constructor parameters for the new Tracer market.
     */
    function deployTracer(
        bytes calldata _data
    ) external {
        _deployTracer(_data, msg.sender);
    }

   /**
     * @notice Allows the Tracer DAO to deploy a DAO approved Tracer market
     * @param _data The data that will be used as constructor parameters for the new Tracer market.
     */
    function deployTracerAndApprove(
        bytes calldata _data
    ) external onlyOwner() {
        address tracer = _deployTracer(_data, owner());
        // DAO deployed markets are automatically approved
        setApproved(address(tracer), true);
    }

    /**
    * @notice internal function for the actual deployment of a Tracer market.
    */
    function _deployTracer(
        bytes calldata _data,
        address tracerOwner
    ) internal returns (address) {
        // Create and link tracer to factory
        address market = IDeployer(deployer).deploy(_data);
        ITracer tracer = ITracer(market);

        validTracers[market] = true;
        tracersByIndex[tracerCounter] = market;

        IInsurance(insurance).deployInsurancePool(market);
        tracerCounter++;

        // Perform admin operations on the tracer to finalise linking
        tracer.setInsuranceContract(insurance);
        tracer.initializePricing();

        // Ownership either to the deployer or the DAO
        tracer.transferOwnership(tracerOwner);
        emit TracerDeployed(tracer.marketId(), address(tracer));
        return market;
    }

    /**
     * @notice Sets the insurance contract for tracers. Allows the
     *         factory to be used as a point of reference for all pieces
     *         in the tracer protocol.
     * @param newInsurance the new insurance contract address
     */
    function setInsuranceContract(address newInsurance) public override onlyOwner() {
        insurance = newInsurance;
    }

    /**
     * @notice Sets the insurance contract for tracers. Allows the
     *         factory to be used as a point of reference for all pieces
     *         in the tracer protocol.
     * @param newDeployer the new deployer contract address
     */
    function setDeployerContract(address newDeployer) public override onlyOwner() {
        deployer = newDeployer;
    }

    /**
    * @notice Sets a contracts approval by the DAO. This allows the factory to
    *         identify contracts that the DAO has "absorbed" into its control
    * @dev requires the contract to be owned by the DAO if being set to true.
    */
    function setApproved(address market, bool value) public override onlyOwner() {
        if(value) { require(Ownable(market).owner() == owner(), "TFC: Owner not DAO"); }
        daoApproved[market] = value;
    }

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