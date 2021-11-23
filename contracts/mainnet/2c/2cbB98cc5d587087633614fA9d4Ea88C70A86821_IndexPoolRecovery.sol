// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import './lib/UniswapV2Library.sol';
import './lib/TransferHelper.sol';
import './interfaces/IProxyManagerAccessControl.sol';
import './interfaces/IDelegateCallProxyManager.sol';
import './interfaces/IERC20.sol';
import './interfaces/IRootChainManager.sol';

contract IndexPoolRecovery {
  uint256 internal constant sideChainDepositAmount = type(uint128).max;
  address internal constant treasury = 0x78a3eF33cF033381FEB43ba4212f2Af5A5A0a2EA;
  IProxyManagerAccessControl internal constant proxyManagerController =
    IProxyManagerAccessControl(0x3D4860d4b7952A3CAD3Accfada61463F15fc0D54);
  IDelegateCallProxyManager internal constant proxyManager =
    IDelegateCallProxyManager(0xD23DeDC599bD56767e42D48484d6Ca96ab01C115);
  IRootChainManager internal constant polygonRootChainManager =
    IRootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
  address internal constant polygonERC20Predicate = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;
  address internal immutable polygonRecipient;

  address internal constant DEFI5 = 0xfa6de2697D59E88Ed7Fc4dFE5A33daC43565ea41;
  address internal constant CC10 = 0x17aC188e09A7890a1844E5E65471fE8b0CcFadF3;
  address internal constant CC10_SELLER = 0xE487F6E45D292BF8D9B883d007d93714f4bFE148;
  address internal constant FFF = 0xaBAfA52D3d5A2c18A4C1Ae24480D22B831fC0413;
  address internal constant DEGEN = 0x126c121f99e1E211dF2e5f8De2d96Fa36647c855;

  address internal immutable recoveryContract;
  bytes32 internal constant slot = bytes32(uint256(keccak256('indexed.recovery.module')) - 1);
  address internal immutable corePoolImplementation;
  bytes32 internal constant corePoolImplementationID = keccak256('IndexPool.sol');
  address internal immutable coreSellerImplementation;
  bytes32 internal constant coreSellerImplementationID = keccak256('UnboundTokenSeller.sol');
  address internal immutable sigmaPoolImplementation;
  bytes32 internal constant sigmaPoolImplementationID = keccak256('SigmaIndexPoolV1.sol');
  address internal immutable coreControllerImplementation;
  address internal constant coreControllerAddress = 0xF00A38376C8668fC1f3Cd3dAeef42E0E44A7Fcdb;
  address internal immutable sigmaControllerImplementation;
  address internal constant sigmaControllerAddress = 0x5B470A8C134D397466A1a603678DadDa678CBC29;

  function getImplementationAddress(bytes32 implementationID) internal view returns (address implementation) {
    address holder = proxyManager.getImplementationHolder(implementationID);
    (bool success, bytes memory data) = holder.staticcall('');
    require(success, string(data));
    implementation = abi.decode((data), (address));
    require(implementation != address(0), 'ERR_NULL_IMPLEMENTATION');
  }

  constructor(
    address _coreControllerImplementation,
    address _sigmaControllerImplementation,
    address _coreIndexPoolImplementation,
    address _sigmaPoolImplementation,
    address _polygonRecipient
  ) public {
    coreControllerImplementation = _coreControllerImplementation;
    sigmaControllerImplementation = _sigmaControllerImplementation;
    corePoolImplementation = _coreIndexPoolImplementation;
    sigmaPoolImplementation = _sigmaPoolImplementation;
    coreSellerImplementation = getImplementationAddress(coreSellerImplementationID);
    recoveryContract = address(this);
    polygonRecipient = _polygonRecipient;
  }

  /**
   * @dev Enables fake deposits to Polygon.
   * Accepts the transferFrom call only if the current contract is
   * DEFI5, CC10 or FFF, the caller is the polygon erc20 predicate,
   * the sender is the recovery contract, the receiver is the polygon
   * erc20 predicate and the amount is 2**128-1.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external view returns (bool) {
    require(
      (
        address(this) == DEFI5 ||
        address(this) == CC10 ||
        address(this) == FFF
      ) &&
      msg.sender == polygonERC20Predicate &&
      from == recoveryContract &&
      to == polygonERC20Predicate &&
      amount == sideChainDepositAmount
    );
    return true;
  }

  /**
   * @dev Enable transfers when the sender is FFF and the receiver is DEGEN.
   * This allows DEGEN to be removed from FFF even while the implementation contract
   * for Sigma pools is set to the recovery contract.
   */
  function transfer(address to, uint256 amount) external onlyFromTo(FFF, DEGEN) returns (bool) {
    _delegate(sigmaPoolImplementation);
  }

  /**
   * @dev If the sender is FFF and the receiver is DEGEN, delegate
   * to the real sigma pool implementation to read the balance;
   * otherwise, return the value stored at the balance slot for `account`.
   */
  function balanceOf(address account) external returns (uint256 bal) {
    if (msg.sender == FFF && address(this) == DEGEN) {
      _delegate(sigmaPoolImplementation);
    }
    uint256 balslot = balanceSlot(account);
    assembly {
      bal := sload(balslot)
    }
  }

  /**
   * @dev Delegate to an implementation contract.
   */
  function _delegate(address implementation) internal virtual {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
        // delegatecall returns 0 on error.
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }

  /**
   * @dev Calculates the slot for temporary balance storage.
   */
  function balanceSlot(address account) internal pure returns (uint256 _slot) {
    _slot = uint256(keccak256(abi.encodePacked(slot, keccak256(abi.encodePacked(account))))) - 1;
  }

  /**
   * @dev Temporarily set a balance value at the balance slot for an account.
   * This is used for draining Uniswap pairs.
   */
  function setContractBal(address account, uint256 bal) internal {
    uint256 balslot = balanceSlot(account);
    assembly {
      sstore(balslot, bal)
    }
  }

  function calculateUniswapPair(
    address token0,
    address token1
  ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex'ff',
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
          )
        )
      )
    );
  }


  /**
   * @dev Transfer the full balance held by this contract of a token to the treasury.
   */
  function claimToken(IERC20 token) internal {
    uint256 bal = token.balanceOf(address(this));
    if (bal > 0) TransferHelper.safeTransfer(address(token), treasury, bal);
  }

  /**
   * @dev Transfer all but 1 wei of the paired token from a Uniswap pair
   * to the treasury.
   */
  function claimLiquidity(address pairedToken) internal {
    (address token0, address token1) =
      address(this) < pairedToken ? (address(this), pairedToken) : (pairedToken, address(this));
    address pair = calculateUniswapPair(token0, token1);
    uint256 pairedReserves = IERC20(pairedToken).balanceOf(pair);
    setContractBal(pair, 1);
    IUniswapV2Pair(pair).sync();
    uint256 amountIn = UniswapV2Library.getAmountIn(pairedReserves - 1, 1, pairedReserves);
    setContractBal(pair, amountIn + 1);
    if (token0 == address(this)) {
      IUniswapV2Pair(pair).swap(0, pairedReserves - 1, treasury, '');
    } else {
      IUniswapV2Pair(pair).swap(pairedReserves - 1, 0, treasury, '');
    }
    setContractBal(pair, 0);
  }

  modifier onlyFromTo(address _caller, address _contract) {
    require(msg.sender == _caller && address(this) == _contract);
    _;
  }

  /**
   * @dev Transfer the assets in DEFI5 and its Uniswap pair's WETH to the treasury.
   */
  function defi5() external onlyFromTo(recoveryContract, DEFI5) {
    claimToken(IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2)); // sushi
    claimToken(IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984)); // uni
    claimToken(IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9)); // aave
    claimToken(IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52)); // crv
    claimToken(IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888)); // comp
    claimToken(IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2)); // mkr
    claimToken(IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)); // snx
    claimLiquidity(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address _treasury = treasury;
  }

  /**
   * @dev Transfer the assets in CC10 and its Uniswap pair's WETH to the treasury.
   */
  function cc10() external onlyFromTo(recoveryContract, CC10) {
    claimToken(IERC20(0xd26114cd6EE289AccF82350c8d8487fedB8A0C07)); // omg
    claimToken(IERC20(0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828)); // uma
    claimToken(IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF)); // bat
    claimToken(IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888)); // comp
    claimToken(IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2)); // sushi
    claimToken(IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52)); // crv
    claimToken(IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2)); // mkr
    claimToken(IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)); // snx
    claimToken(IERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e)); // yfi
    claimToken(IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984)); // uni
    claimLiquidity(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address _treasury = treasury;
  }

  /**
   * @dev Transfer the assets in FFF and its Uniswap pair's WETH to the treasury.
   */
  function fff() external onlyFromTo(recoveryContract, FFF) {
    claimToken(IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)); // weth
    claimToken(IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)); // wbtc
    claimToken(IERC20(DEGEN)); // degen
    claimLiquidity(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address _treasury = treasury;
  }

  /**
   * @dev Transfer the assets in the CC10 token seller to the treasury.
   */
  function cc10Seller() external onlyFromTo(recoveryContract, CC10_SELLER) {
    claimToken(IERC20(0xd26114cd6EE289AccF82350c8d8487fedB8A0C07));
    claimToken(IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498));
    address _treasury = treasury;
    assembly {
      selfdestruct(_treasury)
    }
  }

  /**
   * @dev Execute a deposit to Polygon.
   */
  function sendToPolygon() internal {
    bytes memory encodedAmount = abi.encode(sideChainDepositAmount);

    polygonRootChainManager.depositFor(polygonRecipient, DEFI5, encodedAmount);
    polygonRootChainManager.depositFor(polygonRecipient, CC10, encodedAmount);
    polygonRootChainManager.depositFor(polygonRecipient, FFF, encodedAmount);
  }

  function drainAndRepair() external onlyFromTo(treasury, recoveryContract) {
    proxyManagerController.setImplementationAddressManyToOne(corePoolImplementationID, address(this));
    proxyManagerController.setImplementationAddressManyToOne(coreSellerImplementationID, address(this));
    proxyManagerController.setImplementationAddressManyToOne(sigmaPoolImplementationID, address(this));
    sendToPolygon();
    IndexPoolRecovery(FFF).fff();
    IndexPoolRecovery(DEFI5).defi5();
    IndexPoolRecovery(CC10).cc10();
    IndexPoolRecovery(CC10_SELLER).cc10Seller();

    proxyManagerController.setImplementationAddressManyToOne(corePoolImplementationID, corePoolImplementation);
    proxyManagerController.setImplementationAddressManyToOne(coreSellerImplementationID, coreSellerImplementation);
    proxyManagerController.setImplementationAddressManyToOne(sigmaPoolImplementationID, sigmaPoolImplementation);
    proxyManagerController.setImplementationAddressOneToOne(coreControllerAddress, coreControllerImplementation);
    proxyManagerController.setImplementationAddressOneToOne(sigmaControllerAddress, sigmaControllerImplementation);

    proxyManagerController.transferOwnership(treasury);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


/**
 * @dev Contract that manages deployment and upgrades of delegatecall proxies.
 *
 * An implementation identifier can be created on the proxy manager which is
 * used to specify the logic address for a particular contract type, and to
 * upgrade the implementation as needed.
 *
 * A one-to-one proxy is a single proxy contract with an upgradeable implementation
 * address.
 *
 * A many-to-one proxy is a single upgradeable implementation address that may be
 * used by many proxy contracts.
 */
interface IDelegateCallProxyManager {
/* ==========  Events  ========== */

  event DeploymentApprovalGranted(address deployer);
  event DeploymentApprovalRevoked(address deployer);

  event ManyToOne_ImplementationCreated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ImplementationUpdated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ProxyDeployed(
    bytes32 implementationID,
    address proxyAddress
  );

  event OneToOne_ProxyDeployed(
    address proxyAddress,
    address implementationAddress
  );

  event OneToOne_ImplementationUpdated(
    address proxyAddress,
    address implementationAddress
  );

/* ==========  Controls  ========== */

  /**
   * @dev Allows `deployer` to deploy many-to-one proxies.
   */
  function approveDeployer(address deployer) external;

  /**
   * @dev Prevents `deployer` from deploying many-to-one proxies.
   */
  function revokeDeployerApproval(address deployer) external;

/* ==========  Implementation Management  ========== */

  /**
   * @dev Creates a many-to-one proxy relationship.
   *
   * Deploys an implementation holder contract which stores the
   * implementation address for many proxies. The implementation
   * address can be updated on the holder to change the runtime
   * code used by all its proxies.
   *
   * @param implementationID ID for the implementation, used to identify the
   * proxies that use it. Also used as the salt in the create2 call when
   * deploying the implementation holder contract.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external;

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationManyToOne(bytes32 implementationID) external;

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationOneToOne(address proxyAddress) external;

  /**
   * @dev Updates the implementation address for a many-to-one
   * proxy relationship.
   *
   * @param implementationID Identifier for the implementation.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external;

  /**
   * @dev Updates the implementation address for a one-to-one proxy.
   *
   * Note: This could work for many-to-one as well if the caller
   * provides the implementation holder address in place of the
   * proxy address, as they use the same access control and update
   * mechanism.
   *
   * @param proxyAddress Address of the deployed proxy
   * @param implementation Address with the runtime code for
   * the proxy to use.
   */
  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external;

/* ==========  Proxy Deployment  ========== */

  /**
   * @dev Deploy a proxy contract with a one-to-one relationship
   * with its implementation.
   *
   * The proxy will have its own implementation address which can
   * be updated by the proxy manager.
   *
   * @param suppliedSalt Salt provided by the account requesting deployment.
   * @param implementation Address of the contract with the runtime
   * code that the proxy should use.
   */
  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  ) external returns(address proxyAddress);

  /**
   * @dev Deploy a proxy with a many-to-one relationship with its implemenation.
   *
   * The proxy will call the implementation holder for every transaction to
   * determine the address to use in calls.
   *
   * @param implementationID Identifier for the proxy's implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external returns(address proxyAddress);

/* ==========  Queries  ========== */

  /**
   * @dev Returns a boolean stating whether `implementationID` is locked.
   */
  function isImplementationLocked(bytes32 implementationID) external view returns (bool);

  /**
   * @dev Returns a boolean stating whether `proxyAddress` is locked.
   */
  function isImplementationLocked(address proxyAddress) external view returns (bool);

  /**
   * @dev Returns a boolean stating whether `deployer` is allowed to deploy many-to-one
   * proxies.
   */
  function isApprovedDeployer(address deployer) external view returns (bool);

  /**
   * @dev Queries the temporary storage value `_implementationHolder`.
   * This is used in the constructor of the many-to-one proxy contract
   * so that the create2 address is static (adding constructor arguments
   * would change the codehash) and the implementation holder can be
   * stored as a constant.
   */
  function getImplementationHolder() external view returns (address);

  /**
   * @dev Returns the address of the implementation holder contract
   * for `implementationID`.
   */
  function getImplementationHolder(bytes32 implementationID) external view returns (address);

  /**
   * @dev Computes the create2 address for a one-to-one proxy requested
   * by `originator` using `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address originator,
    bytes32 suppliedSalt
  ) external view returns (address);

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` requested by `originator` using
   * `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external view returns (address);

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(bytes32 implementationID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IProxyManagerAccessControl {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function transferManagerOwnership(address newOwner) external;

  function transferOwnership(address newOwner) external;

  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external;

  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IRootChainManager {
  event TokenMapped(address indexed rootToken, address indexed childToken, bytes32 indexed tokenType);

  event PredicateRegistered(bytes32 indexed tokenType, address indexed predicateAddress);

  function registerPredicate(bytes32 tokenType, address predicateAddress) external;

  function mapToken(
    address rootToken,
    address childToken,
    bytes32 tokenType
  ) external;

  function cleanMapToken(address rootToken, address childToken) external;

  function remapToken(
    address rootToken,
    address childToken,
    bytes32 tokenType
  ) external;

  function depositEtherFor(address user) external payable;

  function depositFor(
    address user,
    address rootToken,
    bytes calldata depositData
  ) external;

  function exit(bytes calldata inputData) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash cfedb1f55864dcf8cc0831fdd8ec18eb045b7fd1.

Subject to the MIT license
*************************************************************************************************/


library TransferHelper {
  function safeApproveMax(address token, address to) internal {
    safeApprove(token, to, type(uint256).max);
  }

  function safeUnapprove(address token, address to) internal {
    safeApprove(token, to, 0);
  }

  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:SA");
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:ST");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:STF");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}("");
    require(success, "TH:STE");
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

/* ========== External Interfaces ========== */
import "../interfaces/IUniswapV2Pair.sol";

/* ========== External Libraries ========== */
import "@openzeppelin/contracts/math/SafeMath.sol";

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 87edfdcaf49ccc52591502993db4c8c08ea9eec0.

Subject to the GPL-3.0 license
*************************************************************************************************/


library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }

  function getCumulativePriceLast(
    address factory,
    address tokenIn,
    address tokenOut
  ) internal view returns (uint256) {
    (address token0, address token1) = sortTokens(tokenIn, tokenOut);
    IUniswapV2Pair pair = IUniswapV2Pair(
      calculatePair(factory, token0, token1)
    );
    if (token0 == tokenIn) return pair.price0CumulativeLast();
    return pair.price1CumulativeLast();
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
      pairFor(factory, tokenA, tokenB)
    )
      .getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i],
        path[i + 1]
      );
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i - 1],
        path[i]
      );
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}