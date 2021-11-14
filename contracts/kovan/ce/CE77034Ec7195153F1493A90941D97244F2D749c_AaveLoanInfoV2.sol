/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// File: src/contracts/utils/ContractAddress.sol

pragma solidity ^0.6.0;


contract ContractAddressMainnet {
  address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant DS_PROXY_REGISTRY = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
  address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant GasToken = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
  address public constant AAVE_SUBSCRIPTION_ADDRESS = 0x6B25043BF08182d8e86056C6548847aF607cd7CD;
  address public constant AAVE_MONITOR_PROXY = 0x380982902872836ceC629171DaeAF42EcC02226e;
  address public constant DSGuard_FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;
  address public constant feeRecipientAddr = 0x358076F1F8724b1c1f3c306B1152F23693018Ee6;//kovan
  address public constant DISCOUNT_ADDR = 0xDa98758dB31f1e075fB8fD712Ef37a24DCc9290e;//kovan
  address public constant BOT_REGISTRY_ADDRESS = 0x3b9965cc3faD9BF3C8e75948d82C7ef9E5B8ed41;//kovan
  address public constant LOGGER = 0x1432C0A171778E5A27fbF6fBcBC79D21A02018ec;//kovan
  address payable public constant AAVE_RECEIVER = 0x5a4fc27dd39827Ee6eC501fed57520030B20675B;//kovan
  address public constant AAVE_BASIC_PROXY = 0x1389E35b1830c7B258B18875D8c4B5C03c391f51;//kovan
  address public constant AAVE_MARKET_ID = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
  address public constant AAVE_Loan_Info = 0x8840869fdA851b90A611Aa6f040D9844A6D609a0;//kovan
  address public constant nullAddress = 0x0000000000000000000000000000000000000000;

}


contract ContractAddressKovan {
  address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant DS_PROXY_REGISTRY = 0x64A436ae831C1672AE81F674CAb8B6775df3475C;
  address public constant WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
  address public constant GasToken = 0x0000000000170CcC93903185bE5A2094C870Df62;//kovan
  address public constant AAVE_SUBSCRIPTION_ADDRESS = 0xE033fB6B635789Dd3E8Fe81cb3F6587d1c08b4bB;//kovan
  address public constant AAVE_MONITOR_PROXY = 0xF2b3cBaf7A52dF6Cc2e1B711e6dbAEA1d865E116;//kovan
  address public constant DSGuard_FACTORY_ADDRESS = 0x59b4cA1f520bbDFF10e0a4F89F5aFF451438E55d;//kovan
  address public constant feeRecipientAddr = 0x358076F1F8724b1c1f3c306B1152F23693018Ee6;//kovan
  address public constant DISCOUNT_ADDR = 0xb389382d450fe3eb12C74C613d32438661d288f3;//kovan
  address public constant BOT_REGISTRY_ADDRESS = 0xCEd4AF8D6a05d9aE8223229E84D56BEe189A77b5;//kovan
  address public constant LOGGER = 0x1432C0A171778E5A27fbF6fBcBC79D21A02018ec;//kovan
  address payable public constant AAVE_RECEIVER = 0x3562B16F07daEBb609f55755bfC575203B0F7480;//kovan
  address payable public constant AAVE_RECEIVER2 = 0xa3c67dc44BbfdC19989e128ceaE9eCFeB81E852f;//kovan
  
  address public constant AAVE_BASIC_PROXY = 0x1389E35b1830c7B258B18875D8c4B5C03c391f51;//kovan
  address public constant AAVE_MARKET_ID = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;//kovan
  address public constant AAVE_Loan_Info = 0x8840869fdA851b90A611Aa6f040D9844A6D609a0;//kovan
  address public constant nullAddress = 0x0000000000000000000000000000000000000000;
  
}

contract ContractAddressExchangeKovan {
  	address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant EXCHANGE_WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public constant FEE_Recipient = 0x358076F1F8724b1c1f3c306B1152F23693018Ee6;
    address public constant DISCOUNT_ADDRESS = 0xb389382d450fe3eb12C74C613d32438661d288f3;
    address public constant SAVER_EXCHANGE_REGISTRY = 0x3c5dEea2C8CB7D895c1Fd01f93e25a037A03Bc62;
    address public constant ZRX_ALLOWLIST_ADDR = 0xe1Df37678f0f2fc06881a9da16c05272b27e32E4;
  	address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
  	address public constant EXHANGE_WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
  	address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
}

contract ContractAddressRopsten{
    address public constant Euler = 0xfC3DD73e918b931be7DEfd0cc616508391bcc001;
}

// File: src/contracts/utils/SafeMath.sol

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: src/contracts/utils/Address.sol

pragma solidity ^0.6.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: src/contracts/interfaces/ERC20.sol

pragma solidity ^0.6.0;

interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: src/contracts/utils/SafeERC20.sol

pragma solidity ^0.6.0;




library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     */
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: src/contracts/auth/AdminAuth.sol

pragma solidity ^0.6.0;


contract AdminAuth {

    using SafeERC20 for ERC20;

    address public owner;
    address public admin;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
        admin = 0xA78f9C8D422926f523Efc747101D1901a1a79639;
    }

    /// @notice Admin is set by owner first time, after that admin is super role and has permission to change owner
    /// @param _admin Address of multisig that becomes admin
    function setAdminByOwner(address _admin) public {
        require(msg.sender == owner);
        require(admin == address(0));

        admin = _admin;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function setAdminByAdmin(address _admin) public {
        require(msg.sender == admin);

        admin = _admin;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function setOwnerByAdmin(address _owner) public {
        require(msg.sender == admin);

        owner = _owner;
    }

    /// @notice Destroy the contract
    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }

    /// @notice  withdraw stuck funds
    function withdrawStuckFunds(address _token, uint _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(owner).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(owner, _amount);
        }
    }
}

// File: src/contracts/utils/BotRegistry.sol

pragma solidity ^0.6.0;


contract BotRegistry is AdminAuth {

    mapping (address => bool) public botList;

    constructor() public {
       botList[0xA78f9C8D422926f523Efc747101D1901a1a79639] = true;
    }

    function setBot(address _botAddr, bool _state) public onlyOwner {
        botList[_botAddr] = _state;
    }
     function setBotList(address[] memory _botAddr) public onlyOwner {
        for(uint i=0;i<_botAddr.length;i++){
            if(_botAddr[i]!=0x0000000000000000000000000000000000000000){
                botList[_botAddr[i]] = true;
            }
        }
        
    }

}

// File: src/contracts/interfaces/IAaveSubscription.sol

pragma solidity ^0.6.0;

abstract contract IAaveSubscription {
    function subscribe(address _market,uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled,uint256 _lastReplyPrice,uint256 _lastBoostPrice,uint128 _optimalType,uint128 _repayAllRatio,uint256 _planRepayPrice,uint256 _planBoostPrice) public virtual;
    function unsubscribe() public virtual;
    function getOptimalType(address _user) public view virtual returns(uint128 subscribeType) ;
    function updateOptionParam(uint256 _lastReplyPrice,uint256 _lastBoostPrice) public virtual;
}

// File: src/contracts/interfaces/IAaveProtocolDataProviderV2.sol


pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface IAaveProtocolDataProviderV2 {

  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function getAllReservesTokens() external virtual view returns (TokenData[] memory);

  function getAllATokens() external virtual view returns (TokenData[] memory);

  function getReserveConfigurationData(address asset)
    external virtual
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  function getReserveData(address asset)
    external virtual
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  function getUserReserveData(address asset, address user)
    external virtual
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  function getReserveTokensAddresses(address asset)
    external virtual
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );
}
// File: src/contracts/interfaces/IPriceOracleGetterAave.sol

pragma solidity ^0.6.0;

/************
@title IPriceOracleGetterAave interface
@notice Interface for the Aave price oracle.*/
abstract contract IPriceOracleGetterAave {
    function getAssetPrice(address _asset) external virtual view returns (uint256);
    function getAssetsPrices(address[] calldata _assets) external virtual view returns(uint256[] memory);
    function getSourceOfAsset(address _asset) external virtual view returns(address);
    function getFallbackOracle() external virtual view returns(address);
}
// File: src/contracts/interfaces/ILendingPoolV2.sol


pragma solidity 0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProviderV2 {
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

interface ILendingPoolV2 {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external;

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProviderV2);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}


// File: src/contracts/interfaces/IAToken.sol

pragma solidity ^0.6.0;

abstract contract IAToken {
    function redeem(uint256 _amount) external virtual;
    function balanceOf(address _owner) external virtual view returns (uint256 balance);
}

// File: src/contracts/interfaces/IFeeRecipient.sol



pragma solidity ^0.6.0;

abstract contract IFeeRecipient {
    function getFeeAddr() public view virtual returns (address);
    function changeWalletAddr(address _newWallet) public virtual;
}

// File: src/contracts/utils/Discount.sol


pragma solidity ^0.6.0;


contract Discount {
    address public owner;
    mapping(address => CustomServiceFee) public serviceFees;
    mapping(address => CustomServiceFee) public automaticFees;

    uint256 constant MAX_SERVICE_FEE = 400;

    struct CustomServiceFee {
        bool active;
        uint256 amount;
    }

    constructor() public {
        owner = msg.sender;
    }

    function isCustomFeeSet(address _user) public view returns (bool) {
        return serviceFees[_user].active;
    }

    function getCustomServiceFee(address _user) public view returns (uint256) {
        return serviceFees[_user].amount;
    }

    function setServiceFee(address _user, uint256 _fee) public {
        require(msg.sender == owner, "Only owner");
        require(_fee >= MAX_SERVICE_FEE || _fee == 0);

        serviceFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableServiceFee(address _user) public {
        require(msg.sender == owner, "Only owner");

        serviceFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
    
    function isAutoFeeSet(address _user) public view returns (bool) {
        return automaticFees[_user].active;
    }

    function getAutoServiceFee(address _user) public view returns (uint256) {
        return automaticFees[_user].amount;
    }

    function setAutoServiceFee(address _user, uint256 _fee) public {
        require(msg.sender == owner, "Only owner");
        require(_fee >= MAX_SERVICE_FEE || _fee == 0);

        automaticFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableAutoServiceFee(address _user) public {
        require(msg.sender == owner, "Only owner");

        automaticFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
}

// File: src/contracts/DS/DSNote.sol

pragma solidity ^0.6.0;


contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

// File: src/contracts/DS/DSAuthority.sol

pragma solidity ^0.6.0;


abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
}

// File: src/contracts/DS/DSAuth.sol

pragma solidity ^0.6.0;



contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

// File: src/contracts/DS/DSProxy.sol

pragma solidity ^0.6.0;




abstract contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache; // global cache for contracts

    constructor(address _cacheAddr) public {
        require(setCache(_cacheAddr));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // use the proxy to execute calldata _data on contract _code
    // function execute(bytes memory _code, bytes memory _data)
    //     public
    //     payable
    //     virtual
    //     returns (address target, bytes32 response);

    function execute(address _target, bytes memory _data)
        public
        payable
        virtual
        returns (bytes32 response);

    //set new cache
    function setCache(address _cacheAddr) public virtual payable returns (bool);
}


contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
                case 1 {
                    // throw if contract failed to deploy
                    revert(0, 0)
                }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}

// File: src/contracts/DS/DSMath.sol

pragma solidity ^0.6.0;


contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// File: src/contracts/aaveV2/AaveHelperV2.sol

pragma solidity ^0.6.0;














contract AaveHelperV2 is DSMath,ContractAddressKovan {

    using SafeERC20 for ERC20;

    IFeeRecipient public constant feeRecipient = IFeeRecipient(feeRecipientAddr);


    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee
    uint public constant AUTOMATIC_FULL_SERVICE_FEE = 285; //0.35%


    uint16 public constant AAVE_REFERRAL_CODE = 64;

    uint public constant STABLE_ID = 1;
    uint public constant VARIABLE_ID = 2;
    
    enum OptionEnum{deposit,withdraw,borrow,payback,paybackOnBehalf,repay,boost,assetSwap,liquidationCall}
    mapping(OptionEnum => bool) public optionMap;
    address aaveHelperOwner;
    constructor () public {
        aaveHelperOwner = msg.sender;
        optionMap[OptionEnum.deposit] = true;
        optionMap[OptionEnum.withdraw] = false;
        optionMap[OptionEnum.borrow] = false;
        optionMap[OptionEnum.payback] = false;
        optionMap[OptionEnum.paybackOnBehalf] = false;
        optionMap[OptionEnum.repay] = false;
        optionMap[OptionEnum.boost] = false;
        optionMap[OptionEnum.assetSwap] = false;
        optionMap[OptionEnum.liquidationCall] = false;
    }
    modifier checkSubscribed(OptionEnum _option){
        uint128 subscribedType = getSubscribedType();
        if(subscribedType == 2){
            require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin) || optionMap[_option]);
        }
        _;
    }
    function setOptionMap(OptionEnum _option,bool _flag) public {
        require(msg.sender == aaveHelperOwner);
        optionMap[_option] = _flag;
    }
    function setAutoPriceParam(uint256 _lastBoostPrice,uint256 _lastRepayPrice) internal {
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).updateOptionParam(_lastRepayPrice,_lastBoostPrice);
    }
    function getSubscribedType() internal returns(uint128) {
        return IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).getOptimalType(msg.sender);
    }
    /// @notice Calculates the gas cost for transaction
    /// @param _oracleAddress address of oracle used
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _tokenAddr token addr. of token we are getting for the fee
    /// @return gasCost The amount we took for the gas cost
    function getGasCost(address _oracleAddress, uint _amount, address _user, uint _gasCost, address _tokenAddr,uint autoFee) internal returns (uint gasCost) {
        if (_gasCost == 0 ||autoFee == 0) return 0;
        // in case its ETH, we need to get price for WETH
        // everywhere else  we still use ETH as thats the token we have in this moment
        address priceToken = _tokenAddr == ETH_ADDR ? WETH_ADDRESS : _tokenAddr;
        uint256 price = IPriceOracleGetterAave(_oracleAddress).getAssetPrice(priceToken);
        _gasCost = wdiv(_gasCost, price) / (10 ** (18 - _getDecimals(_tokenAddr)));
        gasCost = _gasCost;

        // gas cost can't go over 20% of the whole amount
        if (gasCost > (_amount / 5)) {
            gasCost = _amount / 5;
        }

        address walletAddr = feeRecipient.getFeeAddr();

        if (_tokenAddr == ETH_ADDR) {
            payable(walletAddr).transfer(gasCost);
        } else {
            ERC20(_tokenAddr).safeTransfer(walletAddr, gasCost);
        }
    }


    /// @notice Returns the owner of the DSProxy that called the contract
    function getUserAddress() internal view returns (address) {
        DSProxy proxy = DSProxy(payable(address(this)));

        return proxy.owner();
    }

    /// @notice Approves token contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _caller Address which will gain the approval
    function approveToken(address _tokenAddr, address _caller) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeApprove(_caller, uint256(-1));
        }
    }

    /// @notice Send specific amount from contract to specific user
    /// @param _token Token we are trying to send
    /// @param _user User that should receive funds
    /// @param _amount Amount that should be sent
    function sendContractBalance(address _token, address _user, uint _amount) internal {
        if (_amount == 0) return;

        if (_token == ETH_ADDR) {
            payable(_user).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(_user, _amount);
        }
    }

    function sendFullContractBalance(address _token, address _user) internal {
        if (_token == ETH_ADDR) {
            sendContractBalance(_token, _user, address(this).balance);
        } else {
            sendContractBalance(_token, _user, ERC20(_token).balanceOf(address(this)));
        }
    }

    function _getDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return ERC20(_token).decimals();
    }

    function getDataProvider(address _market) internal view returns(IAaveProtocolDataProviderV2) {
        return IAaveProtocolDataProviderV2(ILendingPoolAddressesProviderV2(_market).getAddress(0x0100000000000000000000000000000000000000000000000000000000000000));
    }
    function getAaveAssetPrice(address _market,address _asset) internal view returns(uint256){
            address priceOracleAddress = ILendingPoolAddressesProviderV2(_market).getPriceOracle();
            uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_asset);
            return price;
    }
}

// File: src/contracts/aaveV2/AaveSafetyRatioV2.sol

pragma solidity ^0.6.0;


/**
调用aave获取用户最大借款额度和剩余额度计算安全汇率。越大越安全
*/
contract AaveSafetyRatioV2 is AaveHelperV2 {
	//越大越安全 100%就是额度用完了
    function getSafetyRatio(address _market, address _user) public view returns(uint256) {
        ILendingPoolV2 lendingPool = ILendingPoolV2(ILendingPoolAddressesProviderV2(_market).getLendingPool());
        
        (,uint256 totalDebtETH,uint256 availableBorrowsETH,,,) = lendingPool.getUserAccountData(_user);

        if (totalDebtETH == 0) return uint256(0);
        //totalDebtETH 总欠款
        //availableBorrowsETH 还可以再借款
        //（totalDebtETH+availableBorrowsETH）/totalDebtETH
        //越大越安全
        return wdiv(add(totalDebtETH, availableBorrowsETH), totalDebtETH);
    }
}
// File: src/contracts/aaveV2/AaveLoanInfoV2.sol

pragma solidity ^0.6.0;


/**
    获取aave的一些token的信息。调用aave获取信息的工具类
*/
contract AaveLoanInfoV2 is AaveSafetyRatioV2 {

    struct LoanData {
        address user;
        uint128 ratio;
        address[] collAddr;
        address[] borrowAddr;
        uint256[] collAmounts;
        uint256[] borrowStableAmounts;
        uint256[] borrowVariableAmounts;
    }
    struct UserLoanData {
        address user;
        string symbol;
        address tokenAddr;
        uint8 loanType;//1 collateralFactor 2 stableBorrow 3 variableBorrow 
        uint256 amount;
        uint256 priceETH;
        uint256 rate;
        uint256 ltv;
        
    }

    struct TokenInfo {
        address aTokenAddress;
        address underlyingTokenAddress;
        uint256 collateralFactor;
        uint256 price;
    }
            
            
    struct TokenInfoFull {
        string symbol;
        address aTokenAddress;
        address underlyingTokenAddress;
        uint256 supplyRate;
        uint256 borrowRateVariable;
        uint256 borrowRateStable;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalBorrow;
        uint256 collateralFactor;
        uint256 liquidationRatio;
        uint256 price;
        bool usageAsCollateralEnabled;
        bool borrowinEnabled;
        bool stableBorrowRateEnabled;
    }

    struct ReserveData {
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 liquidityRate;
        uint256 variableBorrowRate;
        uint256 stableBorrowRate;
    }

    struct UserToken {
        address token;//资产地址 
        uint256 balance;//质押资产 
        uint256 borrowsStable;//固定汇率借款 
        uint256 borrowsVariable;//动态汇率借款 
        uint256 stableBorrowRate;//固定借款汇率 
        bool enabledAsCollateral;//开启质押 
    }
   

    //获取安全汇率
    /// @notice Calcualted the ratio of coll/debt for a compound user
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _user Address of the user
    function getRatio(address _market, address _user) public view returns (uint256) {
        // For each asset the account is in
        return getSafetyRatio(_market, _user);
    }
    //获取aave的资产价格。aave用预言机的价格
    /// @notice Fetches Aave prices for tokens
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _tokens Arr. of tokens for which to get the prices
    /// @return prices Array of prices
    function getPrices(address _market, address[] memory _tokens) public view returns (uint256[] memory prices) {
        address priceOracleAddress = ILendingPoolAddressesProviderV2(_market).getPriceOracle();
        prices = IPriceOracleGetterAave(priceOracleAddress).getAssetsPrices(_tokens);
    }
    //获取token的贷款额度ltv
    /// @notice Fetches Aave collateral factors for tokens
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _tokens Arr. of tokens for which to get the coll. factors
    /// @return collFactors Array of coll. factors
    function getCollFactors(address _market, address[] memory _tokens) public view returns (uint256[] memory collFactors) {
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
        collFactors = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; ++i) {
            (,collFactors[i],,,,,,,,) = dataProvider.getReserveConfigurationData(_tokens[i]);
        }
    }
    //获取用户的借贷情况
    function getTokenBalances(address _market, address _user, address[] memory _tokens) public view returns (UserToken[] memory userTokens) {
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);

        userTokens = new UserToken[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address asset = _tokens[i];
            userTokens[i].token = asset;

            (userTokens[i].balance, userTokens[i].borrowsStable, userTokens[i].borrowsVariable,,,userTokens[i].stableBorrowRate,,,userTokens[i].enabledAsCollateral) = dataProvider.getUserReserveData(asset, _user);
        }
    }
    //获取用户的安全汇率
    /// @notice Calcualted the ratio of coll/debt for an aave user
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _users Addresses of the user
    /// @return ratios Array of ratios
    function getRatios(address _market, address[] memory _users) public view returns (uint256[] memory ratios) {
        ratios = new uint256[](_users.length);

        for (uint256 i = 0; i < _users.length; ++i) {
            ratios[i] = getSafetyRatio(_market, _users[i]);
        }
    }
    //获取token储备金信息
    /// @notice Information about reserves
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _tokenAddresses Array of tokens addresses
    /// @return tokens Array of reserves infomartion
    function getTokensInfo(address _market, address[] memory _tokenAddresses) public view returns(TokenInfo[] memory tokens) {
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
        address priceOracleAddress = ILendingPoolAddressesProviderV2(_market).getPriceOracle();

        tokens = new TokenInfo[](_tokenAddresses.length);

        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
            (,uint256 ltv,,,,,,,,) = dataProvider.getReserveConfigurationData(_tokenAddresses[i]);
            (address aToken,,) = dataProvider.getReserveTokensAddresses(_tokenAddresses[i]);

            tokens[i] = TokenInfo({
                aTokenAddress: aToken,
                underlyingTokenAddress: _tokenAddresses[i],
                collateralFactor: ltv,
                price: IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddresses[i])
            });
        }
    }
    //获取token的aave配置信息
    function getTokenInfoFull(IAaveProtocolDataProviderV2 _dataProvider, address _priceOracleAddress, address _token) private view returns(TokenInfoFull memory _tokenInfo) {
        (
            , // uint256 decimals
            uint256 ltv,
            uint256 liquidationThreshold,
            , //   uint256 liquidationBonus
            , //   uint256 reserveFactor
            bool usageAsCollateralEnabled,
            bool borrowinEnabled,
            bool stableBorrowRateEnabled,
            , //   bool isActive
            //   bool isFrozen
        ) = _dataProvider.getReserveConfigurationData(_token);

        ReserveData memory t;

        (
            t.availableLiquidity,
            t.totalStableDebt,
            t.totalVariableDebt,
            t.liquidityRate,
            t.variableBorrowRate,
            t.stableBorrowRate,
            ,
            ,
            ,

        ) = _dataProvider.getReserveData(_token);

        (address aToken,,) = _dataProvider.getReserveTokensAddresses(_token);

        uint price = IPriceOracleGetterAave(_priceOracleAddress).getAssetPrice(_token);

        _tokenInfo = TokenInfoFull({
            symbol:'',
            aTokenAddress: aToken,
            underlyingTokenAddress: _token,
            supplyRate: t.liquidityRate,//存款利率  
            borrowRateVariable: t.variableBorrowRate,//以可变利率借入的利率
            borrowRateStable: t.stableBorrowRate,//以稳定利率借入的利率
            totalSupply: ERC20(aToken).totalSupply(),//token 发行总量 
            availableLiquidity: t.availableLiquidity,//可用的流动资金量
            totalBorrow: t.totalVariableDebt+t.totalStableDebt,//借入债务总量
            collateralFactor: ltv,//最高借入量 
            liquidationRatio: liquidationThreshold,//清算阈值 
            price: price,//单价
            usageAsCollateralEnabled: usageAsCollateralEnabled,//是否可以抵押 
            borrowinEnabled: borrowinEnabled,//是否可以借款 
            stableBorrowRateEnabled: stableBorrowRateEnabled//是否可以稳定汇率借款 
        });
    }
    //获取token资产信息  
    /// @notice Information about reserves
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _tokenAddresses Array of token addresses
    /// @return tokens Array of reserves infomartion
    function getFullTokensInfo(address _market, address[] memory _tokenAddresses) public view returns(TokenInfoFull[] memory tokens) {
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
        address priceOracleAddress = ILendingPoolAddressesProviderV2(_market).getPriceOracle();

        tokens = new TokenInfoFull[](_tokenAddresses.length);

        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
            tokens[i] = getTokenInfoFull(dataProvider, priceOracleAddress, _tokenAddresses[i]);
        }
    }


    /// @notice Fetches all the collateral/debt address and amounts, denominated in ether
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _user Address of the user
    /// @return data LoanData information
    function getLoanData(address _market, address _user) public view returns (LoanData memory data) {
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
        address priceOracleAddress = ILendingPoolAddressesProviderV2(_market).getPriceOracle();

        IAaveProtocolDataProviderV2.TokenData[] memory reserves = dataProvider.getAllReservesTokens();

        data = LoanData({
            user: _user,
            ratio: 0,
            collAddr: new address[](reserves.length),//质押资产地址数组
            borrowAddr: new address[](reserves.length),//贷款地址数组 
            collAmounts: new uint[](reserves.length),//质押资产数量数组
            borrowStableAmounts: new uint[](reserves.length),//以固定汇率贷款贷款数量 
            borrowVariableAmounts: new uint[](reserves.length)//以动态汇率贷款数量 
        });

        uint64 collPos = 0;
        uint64 borrowPos = 0;
        
        for (uint64 i = 0; i < reserves.length; i++) {
            address reserve = reserves[i].tokenAddress;

            (uint256 aTokenBalance, uint256 borrowsStable, uint256 borrowsVariable,,,,,,) = dataProvider.getUserReserveData(reserve, _user);
            uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(reserve);
            

            if (aTokenBalance > 0) {
                uint256 userTokenBalanceEth = wmul(aTokenBalance, price) * (10 ** (18 - _getDecimals(reserve)));
                data.collAddr[collPos] = reserve;
                data.collAmounts[collPos] = userTokenBalanceEth;
                collPos++;
            }

            // Sum up debt in Eth
            if (borrowsStable > 0) {
                uint256 userBorrowBalanceEth = wmul(borrowsStable, price) * (10 ** (18 - _getDecimals(reserve)));
                data.borrowAddr[borrowPos] = reserve;
                data.borrowStableAmounts[borrowPos] = userBorrowBalanceEth;
            }

            // Sum up debt in Eth
            if (borrowsVariable > 0) {
                uint256 userBorrowBalanceEth = wmul(borrowsVariable, price) * (10 ** (18 - _getDecimals(reserve)));
                data.borrowAddr[borrowPos] = reserve;
                data.borrowVariableAmounts[borrowPos] = userBorrowBalanceEth;
            }

            if (borrowsStable > 0 || borrowsVariable > 0) {
                borrowPos++;
            }
        }

        data.ratio = uint128(getSafetyRatio(_market, _user));

        return data;
    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in ether
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _users Addresses of the user
    /// @return loans Array of LoanData information
    function getLoanDataArr(address _market, address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_market, _users[i]);
        }
    }
    function getAaveMarketInfo(address _market) public view returns(TokenInfoFull[] memory tokens){
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
        IAaveProtocolDataProviderV2.TokenData[] memory tokenData = dataProvider.getAllReservesTokens();
         address priceOracleAddress = ILendingPoolAddressesProviderV2(_market).getPriceOracle();

        tokens = new TokenInfoFull[](tokenData.length);

        for (uint256 i = 0; i < tokenData.length; ++i) {
            tokens[i] = getTokenInfoFull(dataProvider, priceOracleAddress, tokenData[i].tokenAddress);
            tokens[i].symbol = tokenData[i].symbol;
        }
    }

    function getUserAccountData(address _market,address _user)
        public
        view
        returns (
           uint256 totalCollateralETH,
           uint256 totalDebtETH,
           uint256 availableBorrowsETH,
           uint256 currentLiquidationThreshold,
           uint256 ltv,
           uint256 healthFactor
    ){
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        (totalCollateralETH,totalDebtETH,availableBorrowsETH,currentLiquidationThreshold,ltv,healthFactor) = ILendingPoolV2(lendingPool).getUserAccountData(_user);
    }
    
    function getUserLoanData(address _market, address _user) public view returns (UserLoanData[] memory data) {
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
        address priceOracleAddress = ILendingPoolAddressesProviderV2(_market).getPriceOracle();

        IAaveProtocolDataProviderV2.TokenData[] memory reserves = dataProvider.getAllReservesTokens();


       

        uint64 collPos = 0;
        uint64 borrowPos = 0;
        data = new UserLoanData[](reserves.length);
        for (uint64 i = 0; i < reserves.length; i++) {
            address reserve = reserves[i].tokenAddress;
            string memory symbol = reserves[i].symbol;

            (uint256 aTokenBalance, uint256 borrowsStable, uint256 borrowsVariable,,,,,,) = dataProvider.getUserReserveData(reserve, _user);
            uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(reserve);
            TokenInfoFull memory tokenInfo = getTokenInfoFull(dataProvider,priceOracleAddress,reserve);

            if (aTokenBalance > 0) {
                uint256 userTokenBalanceEth = wmul(aTokenBalance, price) * (10 ** (18 - _getDecimals(reserve)));
                data[collPos].user = _user;
                data[collPos].symbol = symbol;
                data[collPos].tokenAddr = reserve;
                data[collPos].loanType = 1;
                data[collPos].amount = aTokenBalance;
                data[collPos].priceETH = userTokenBalanceEth;
                data[collPos].rate = tokenInfo.supplyRate;
                data[collPos].ltv = tokenInfo.collateralFactor;
                
                collPos++;
            }

            // Sum up debt in Eth
            if (borrowsStable > 0) {
                uint256 userBorrowBalanceEth = wmul(borrowsStable, price) * (10 ** (18 - _getDecimals(reserve)));
                
                data[collPos].user = _user;
                data[collPos].symbol = symbol;
                data[collPos].tokenAddr = reserve;
                data[collPos].loanType = 2;
                data[collPos].amount = borrowsStable;
                data[collPos].priceETH = userBorrowBalanceEth;
                data[collPos].rate = tokenInfo.borrowRateStable;
                data[collPos].ltv = tokenInfo.collateralFactor;
                collPos++;
            }

            // Sum up debt in Eth
            if (borrowsVariable > 0) {
                uint256 userBorrowBalanceEth = wmul(borrowsVariable, price) * (10 ** (18 - _getDecimals(reserve)));
                data[collPos].user = _user;
                data[collPos].symbol = symbol;
                data[collPos].tokenAddr = reserve;
                data[collPos].loanType = 3;
                data[collPos].amount = borrowsVariable;
                data[collPos].priceETH = userBorrowBalanceEth;
                data[collPos].rate = tokenInfo.borrowRateVariable;
                data[collPos].ltv = tokenInfo.collateralFactor;
                collPos++;
            }
            
        }
    }
}