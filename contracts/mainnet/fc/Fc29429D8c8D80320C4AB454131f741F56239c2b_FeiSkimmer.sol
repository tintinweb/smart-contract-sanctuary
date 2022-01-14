// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/// @title a PCV Deposit interface
/// @author Fei Protocol
interface IUniswapPCVDeposit {
    // ----------- Events -----------

    event MaxBasisPointsFromPegLPUpdate(uint256 oldMaxBasisPointsFromPegLP, uint256 newMaxBasisPointsFromPegLP);

    // ----------- Governor only state changing api -----------

    function setMaxBasisPointsFromPegLP(uint256 amount) external;

    // ----------- Getters -----------

    function router() external view returns (IUniswapV2Router02);

    function liquidityOwned() external view returns (uint256);

    function maxBasisPointsFromPegLP() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../IPCVSwapper.sol";
import "../../Constants.sol";
import "../utils/WethPCVDeposit.sol";
import "../../utils/Incentivized.sol";
import "../../fei/minter/RateLimitedMinter.sol";
import "../../refs/OracleRef.sol";
import "../../utils/Timed.sol";
import "../../external/UniswapV2Library.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// @title implementation for PCV Swapper that swaps ERC20 tokens on Uniswap
/// @author eswak
contract PCVSwapperUniswap is IPCVSwapper, WethPCVDeposit, OracleRef, Timed, Incentivized, RateLimitedMinter {
    using SafeERC20 for IERC20;
    using Decimal for Decimal.D256;

    // ----------- Events -----------	
    event UpdateMaximumSlippage(uint256 oldMaxSlippage, uint256 newMaximumSlippage);	
    event UpdateMaxSpentPerSwap(uint256 oldMaxSpentPerSwap, uint256 newMaxSpentPerSwap);	

    /// @notice the token to spend on swap (outbound)
    address public immutable override tokenSpent;
    /// @notice the token to receive on swap (inbound)
    address public immutable override tokenReceived;
    /// @notice the address that will receive the inbound tokens
    address public override tokenReceivingAddress;
    /// @notice the maximum amount of tokens to spend on every swap
    uint256 public maxSpentPerSwap;
    /// @notice the maximum amount of slippage vs oracle price
    uint256 public maximumSlippageBasisPoints;

    /// @notice Uniswap pair to swap on
    IUniswapV2Pair public immutable pair;

    struct OracleData {
        address _core;
        address _oracle;
        address _backupOracle;
        // invert should be false if the oracle is reported in tokenSpent terms otherwise true
        bool _invertOraclePrice;
        // The decimalsNormalizer should be calculated as tokenSpent.decimals() - tokenReceived.decimals() if invert is false, otherwise reverse order
        int256 _decimalsNormalizer;
    }

    struct PCVSwapperData {
      address _tokenSpent;
      address _tokenReceived;
      address _tokenReceivingAddress;
      uint256 _maxSpentPerSwap;
      uint256 _maximumSlippageBasisPoints;
      IUniswapV2Pair _pair;
    }

    struct MinterData {
      uint256 _swapFrequency;
      uint256 _swapIncentiveAmount;
    }
    constructor(
        OracleData memory oracleData,
        PCVSwapperData memory pcvSwapperData,
        MinterData memory minterData
    ) 
      OracleRef(
        oracleData._core, 
        oracleData._oracle, 
        oracleData._backupOracle,
        oracleData._decimalsNormalizer,
        oracleData._invertOraclePrice
      ) 
      Timed(minterData._swapFrequency) 
      Incentivized(minterData._swapIncentiveAmount) 
      RateLimitedMinter(minterData._swapIncentiveAmount / minterData._swapFrequency, minterData._swapIncentiveAmount, false) 
    {
        address _tokenSpent = pcvSwapperData._tokenSpent;
        address _tokenReceived = pcvSwapperData._tokenReceived;
        address _tokenReceivingAddress = pcvSwapperData._tokenReceivingAddress;
        uint256 _maxSpentPerSwap = pcvSwapperData._maxSpentPerSwap;
        uint256 _maximumSlippageBasisPoints = pcvSwapperData._maximumSlippageBasisPoints;
        IUniswapV2Pair _pair = pcvSwapperData._pair;

        require(_pair.token0() == _tokenSpent || _pair.token1() == _tokenSpent, "PCVSwapperUniswap: token spent not in pair");
        require(_pair.token0() == _tokenReceived || _pair.token1() == _tokenReceived, "PCVSwapperUniswap: token received not in pair");
        pair = _pair;
        tokenSpent = _tokenSpent;
        tokenReceived = _tokenReceived;

        tokenReceivingAddress = _tokenReceivingAddress;
        emit UpdateReceivingAddress(address(0), _tokenReceivingAddress);

        maxSpentPerSwap = _maxSpentPerSwap;
        emit UpdateMaxSpentPerSwap(0, _maxSpentPerSwap);

        maximumSlippageBasisPoints = _maximumSlippageBasisPoints;
        emit UpdateMaximumSlippage(0, _maximumSlippageBasisPoints);

        // start timer
        _initTimed();
    }

    // =======================================================================
    // IPCVDeposit interface override
    // =======================================================================

    /// @notice withdraw tokenReceived from the contract
    /// @param to address destination of the ERC20
    /// @param amount quantity of tokenReceived to send
    function withdraw(address to, uint256 amount) external override onlyPCVController {
        withdrawERC20(tokenReceived, to, amount);
    }

    /// @notice Reads the balance of tokenReceived held in the contract
		/// @return held balance of token of tokenReceived
    function balance() public view override returns(uint256) {
      return IERC20(tokenReceived).balanceOf(address(this));
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return address(tokenReceived);
    }

    // =======================================================================
    // IPCVSwapper interface override
    // =======================================================================

    /// @notice Sets the address receiving swap's inbound tokens
    /// @param newTokenReceivingAddress the address that will receive tokens
    function setReceivingAddress(address newTokenReceivingAddress) external override onlyGovernor {
      require(newTokenReceivingAddress != address(0), "PCVSwapperUniswap: zero address");
      address oldTokenReceivingAddress = tokenReceivingAddress;
      tokenReceivingAddress = newTokenReceivingAddress;
      emit UpdateReceivingAddress(oldTokenReceivingAddress, newTokenReceivingAddress);
    }

    // =======================================================================
    // Setters
    // =======================================================================

    /// @notice Sets the maximum slippage vs Oracle price accepted during swaps
    /// @param newMaximumSlippageBasisPoints the maximum slippage expressed in basis points (1/10_000)
    function setMaximumSlippage(uint256 newMaximumSlippageBasisPoints) external onlyGovernorOrAdmin {
        uint256 oldMaxSlippage = maximumSlippageBasisPoints;
        require(newMaximumSlippageBasisPoints <= Constants.BASIS_POINTS_GRANULARITY, "PCVSwapperUniswap: Exceeds bp granularity.");
        maximumSlippageBasisPoints = newMaximumSlippageBasisPoints;
        emit UpdateMaximumSlippage(oldMaxSlippage, newMaximumSlippageBasisPoints);
    }

    /// @notice Sets the maximum tokens spent on each swap
    /// @param newMaxSpentPerSwap the maximum number of tokens to be swapped on each call
    function setMaxSpentPerSwap(uint256 newMaxSpentPerSwap) external onlyGovernorOrAdmin {
        uint256 oldMaxSpentPerSwap = maxSpentPerSwap;
        require(newMaxSpentPerSwap != 0, "PCVSwapperUniswap: Cannot swap 0.");
        maxSpentPerSwap = newMaxSpentPerSwap;
        emit UpdateMaxSpentPerSwap(oldMaxSpentPerSwap, newMaxSpentPerSwap);	
    }

    /// @notice sets the minimum time between swaps
		/// @param _duration minimum time between swaps in seconds
    function setSwapFrequency(uint256 _duration) external onlyGovernorOrAdmin {
       _setDuration(_duration);
    }

    // =======================================================================
    // External functions
    // =======================================================================

    /// @notice Swap tokenSpent for tokenReceived
    function swap() external override afterTime whenNotPaused {
	    // Reset timer	
      _initTimed();	
      
      updateOracle();

      uint256 amountIn = _getExpectedAmountIn();
      uint256 amountOut = _getExpectedAmountOut(amountIn);
      uint256 minimumAcceptableAmountOut = _getMinimumAcceptableAmountOut(amountIn);

      // Check spot price vs oracle price discounted by max slippage
      // E.g. for a max slippage of 3%, spot price must be >= 97% oraclePrice
      require(minimumAcceptableAmountOut <= amountOut, "PCVSwapperUniswap: slippage too high.");

      // Perform swap
      IERC20(tokenSpent).safeTransfer(address(pair), amountIn);
      (uint256 amount0Out, uint256 amount1Out) =
          pair.token0() == address(tokenSpent)
              ? (uint256(0), amountOut)
              : (amountOut, uint256(0));
      pair.swap(amount0Out, amount1Out, tokenReceivingAddress, new bytes(0));

      // Emit event
      emit Swap(
        msg.sender,
        tokenSpent,
        tokenReceived,
        amountIn,
        amountOut
      );

      // Incentivize call with FEI rewards
      _incentivize();
    }

    // =======================================================================
    // Internal functions
    // =======================================================================

    function _getExpectedAmountIn() internal view returns (uint256) {
      uint256 amount = IERC20(tokenSpent).balanceOf(address(this));
      require(amount != 0, "PCVSwapperUniswap: no tokenSpent left.");
      return Math.min(maxSpentPerSwap, amount);
    }

    function _getExpectedAmountOut(uint256 amountIn) internal view returns (uint256) {
      // Get pair reserves
      (uint256 _token0, uint256 _token1, ) = pair.getReserves();
      (uint256 tokenSpentReserves, uint256 tokenReceivedReserves) =
          pair.token0() == tokenSpent
              ? (_token0, _token1)
              : (_token1, _token0);

      // Prepare swap
      uint256 amountOut = UniswapV2Library.getAmountOut(
        amountIn,
        tokenSpentReserves,
        tokenReceivedReserves
      );

      return amountOut;
    }

    function _getMinimumAcceptableAmountOut(uint256 amountIn) internal view returns (uint256) {
      Decimal.D256 memory oraclePrice = readOracle();
      Decimal.D256 memory oracleAmountOut = oraclePrice.mul(amountIn);
      Decimal.D256 memory maxSlippage = Decimal.ratio(Constants.BASIS_POINTS_GRANULARITY - maximumSlippageBasisPoints, Constants.BASIS_POINTS_GRANULARITY);
      Decimal.D256 memory oraclePriceMinusSlippage = maxSlippage.mul(oracleAmountOut);
      return oraclePriceMinusSlippage.asUint256();
    }

    function _mintFei(address to, uint256 amountIn) internal override(CoreRef, RateLimitedMinter) {
      RateLimitedMinter._mintFei(to, amountIn);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title a PCV Swapper interface
/// @author eswak
interface IPCVSwapper {

    // ----------- Events -----------
    event UpdateReceivingAddress(address oldTokenReceivingAddress, address newTokenReceivingAddress);

    event Swap(
        address indexed _caller,
        address indexed _tokenSpent,
        address indexed _tokenReceived,
        uint256 _amountSpent,
        uint256 _amountReceived
    );

    // ----------- State changing api -----------

    function swap() external;

    // ----------- Governor only state changing api -----------

    function setReceivingAddress(address _tokenReceivingAddress) external;

    // ----------- Getters -----------

    function tokenSpent() external view returns (address);
    function tokenReceived() external view returns (address);
    function tokenReceivingAddress() external view returns (address);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

library Constants {
    /// @notice the denominator for basis points granularity (10,000)
    uint256 public constant BASIS_POINTS_GRANULARITY = 10_000;
    
    uint256 public constant ONE_YEAR = 365.25 days;

    /// @notice WETH9 address
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice USD stand-in address
    address public constant USD = 0x1111111111111111111111111111111111111111;

    /// @notice Wei per ETH, i.e. 10**18
    uint256 public constant ETH_GRANULARITY = 1e18;
    
    /// @notice number of decimals in ETH, 18
    uint256 public constant ETH_DECIMALS = 18;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../PCVDeposit.sol";
import "../../Constants.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title base class for a WethPCVDeposit PCV Deposit
/// @author Fei Protocol
abstract contract WethPCVDeposit is PCVDeposit {

    /// @notice Empty callback on ETH reception
    receive() external payable virtual {}

    /// @notice Wraps all ETH held by the contract to WETH
    /// Anyone can call it
    function wrapETH() public {
        uint256 ethBalance = address(this).balance;
        if (ethBalance != 0) {
            Constants.WETH.deposit{value: ethBalance}();
        }
    }

    /// @notice deposit
    function deposit() external virtual override {
        wrapETH();
    }

    /// @notice withdraw ETH from the contract
    /// @param to address to send ETH
    /// @param amountOut amount of ETH to send
    function withdrawETH(address payable to, uint256 amountOut)
        external
        override
        onlyPCVController
    {
        Constants.WETH.withdraw(amountOut);
        Address.sendValue(to, amountOut);
        emit WithdrawETH(msg.sender, to, amountOut);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";
import "./IPCVDeposit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title abstract contract for withdrawing ERC-20 tokens using a PCV Controller
/// @author Fei Protocol
abstract contract PCVDeposit is IPCVDeposit, CoreRef {
    using SafeERC20 for IERC20;

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
      address token, 
      address to, 
      uint256 amount
    ) public virtual override onlyPCVController {
        _withdrawERC20(token, to, amount);
    }

    function _withdrawERC20(
      address token, 
      address to, 
      uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(msg.sender, token, to, amount);
    }

    /// @notice withdraw ETH from the contract
    /// @param to address to send ETH
    /// @param amountOut amount of ETH to send
    function withdrawETH(address payable to, uint256 amountOut) external virtual override onlyPCVController {
        Address.sendValue(to, amountOut);
        emit WithdrawETH(msg.sender, to, amountOut);
    }

    function balance() public view virtual override returns(uint256);

    function resistantBalanceAndFei() public view virtual override returns(uint256, uint256) {
      return (balance(), 0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ICoreRef.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title A Reference to Core
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is ICoreRef, Pausable {
    ICore private _core;

    /// @notice a role used with a subset of governor permissions for this contract only
    bytes32 public override CONTRACT_ADMIN_ROLE;

    /// @notice boolean to check whether or not the contract has been initialized.
    /// cannot be initialized twice.
    bool private _initialized;

    constructor(address coreAddress) {
        _initialize(coreAddress);
    }

    /// @notice CoreRef constructor
    /// @param coreAddress Fei Core to reference
    function _initialize(address coreAddress) internal {
        require(!_initialized, "CoreRef: already initialized");
        _initialized = true;

        _core = ICore(coreAddress);
        _setContractAdminRole(_core.GOVERN_ROLE());
    }

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyPCVController() {
        require(
            _core.isPCVController(msg.sender),
            "CoreRef: Caller is not a PCV controller"
        );
        _;
    }

    modifier onlyGovernorOrAdmin() {
        require(
            _core.isGovernor(msg.sender) ||
            isContractAdmin(msg.sender),
            "CoreRef: Caller is not a governor or contract admin"
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || 
            _core.isGuardian(msg.sender),
            "CoreRef: Caller is not a guardian or governor"
        );
        _;
    }

    modifier isGovernorOrGuardianOrAdmin() {
        require(
            _core.isGovernor(msg.sender) ||
            _core.isGuardian(msg.sender) || 
            isContractAdmin(msg.sender), 
            "CoreRef: Caller is not governor or guardian or admin");
        _;
    }

    modifier onlyFei() {
        require(msg.sender == address(fei()), "CoreRef: Caller is not FEI");
        _;
    }

    /// @notice set new Core reference address
    /// @param newCore the new core address
    function setCore(address newCore) external override onlyGovernor {
        require(newCore != address(0), "CoreRef: zero address");
        address oldCore = address(_core);
        _core = ICore(newCore);
        emit CoreUpdate(oldCore, newCore);
    }

    /// @notice sets a new admin role for this contract
    function setContractAdminRole(bytes32 newContractAdminRole) external override onlyGovernor {
        _setContractAdminRole(newContractAdminRole);
    }

    /// @notice returns whether a given address has the admin role for this contract
    function isContractAdmin(address _admin) public view override returns (bool) {
        return _core.hasRole(CONTRACT_ADMIN_ROLE, _admin);
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }

    /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function fei() public view override returns (IFei) {
        return _core.fei();
    }

    /// @notice address of the Tribe contract referenced by Core
    /// @return IERC20 implementation address
    function tribe() public view override returns (IERC20) {
        return _core.tribe();
    }

    /// @notice fei balance of contract
    /// @return fei amount held
    function feiBalance() public view override returns (uint256) {
        return fei().balanceOf(address(this));
    }

    /// @notice tribe balance of contract
    /// @return tribe amount held
    function tribeBalance() public view override returns (uint256) {
        return tribe().balanceOf(address(this));
    }

    function _burnFeiHeld() internal {
        fei().burn(feiBalance());
    }

    function _mintFei(address to, uint256 amount) internal virtual {
        if (amount != 0) {
            fei().mint(to, amount);
        }
    }

    function _setContractAdminRole(bytes32 newContractAdminRole) internal {
        bytes32 oldContractAdminRole = CONTRACT_ADMIN_ROLE;
        CONTRACT_ADMIN_ROLE = newContractAdminRole;
        emit ContractAdminRoleUpdate(oldContractAdminRole, newContractAdminRole);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../core/ICore.sol";

/// @title CoreRef interface
/// @author Fei Protocol
interface ICoreRef {
    // ----------- Events -----------

    event CoreUpdate(address indexed oldCore, address indexed newCore);

    event ContractAdminRoleUpdate(bytes32 indexed oldContractAdminRole, bytes32 indexed newContractAdminRole);

    // ----------- Governor only state changing api -----------

    function setCore(address newCore) external;

    function setContractAdminRole(bytes32 newContractAdminRole) external;

    // ----------- Governor or Guardian only state changing api -----------

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20);

    function feiBalance() external view returns (uint256);

    function tribeBalance() external view returns (uint256);

    function CONTRACT_ADMIN_ROLE() external view returns (bytes32);

    function isContractAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPermissions.sol";
import "../fei/IFei.sol";

/// @title Core Interface
/// @author Fei Protocol
interface ICore is IPermissions {
    // ----------- Events -----------

    event FeiUpdate(address indexed _fei);
    event TribeUpdate(address indexed _tribe);
    event GenesisGroupUpdate(address indexed _genesisGroup);
    event TribeAllocation(address indexed _to, uint256 _amount);
    event GenesisPeriodComplete(uint256 _timestamp);

    // ----------- Governor only state changing api -----------

    function init() external;

    // ----------- Governor only state changing api -----------

    function setFei(address token) external;

    function setTribe(address token) external;

    function allocateTribe(address to, uint256 amount) external;

    // ----------- Getters -----------

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IPermissionsRead.sol";

/// @title Permissions interface
/// @author Fei Protocol
interface IPermissions is IAccessControl, IPermissionsRead {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function GUARDIAN_ROLE() external view returns (bytes32);

    function GOVERN_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function PCV_CONTROLLER_ROLE() external view returns (bytes32);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title Permissions Read interface
/// @author Fei Protocol
interface IPermissionsRead {
    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface IFei is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Burner only state changing api -----------

    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;

    // ----------- Governor only state changing api -----------

    function setIncentiveContract(address account, address incentive) external;

    // ----------- Getters -----------

    function incentiveContract(address account) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDepositBalances.sol";

/// @title a PCV Deposit interface
/// @author Fei Protocol
interface IPCVDeposit is IPCVDepositBalances {
    // ----------- Events -----------
    event Deposit(address indexed _from, uint256 _amount);

    event Withdrawal(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawERC20(
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawETH(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    // ----------- State changing api -----------

    function deposit() external;

    // ----------- PCV Controller only state changing api -----------

    function withdraw(address to, uint256 amount) external;

    function withdrawERC20(address token, address to, uint256 amount) external;

    function withdrawETH(address payable to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title a PCV Deposit interface for only balance getters
/// @author Fei Protocol
interface IPCVDepositBalances {
    
    // ----------- Getters -----------
    
    /// @notice gets the effective balance of "balanceReportedIn" token if the deposit were fully withdrawn
    function balance() external view returns (uint256);

    /// @notice gets the token address in which this deposit returns its balance
    function balanceReportedIn() external view returns (address);

    /// @notice gets the resistant token balance and protocol owned fei of this deposit
    function resistantBalanceAndFei() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";

/// @title abstract contract for incentivizing keepers
/// @author Fei Protocol
abstract contract Incentivized is CoreRef {

    /// @notice FEI incentive for calling keeper functions
    uint256 public incentiveAmount;

    event IncentiveUpdate(uint256 oldIncentiveAmount, uint256 newIncentiveAmount);

    constructor(uint256 _incentiveAmount) {
        incentiveAmount = _incentiveAmount;
        emit IncentiveUpdate(0, _incentiveAmount);
    }

    /// @notice set the incentiveAmount
    function setIncentiveAmount(uint256 newIncentiveAmount) public onlyGovernor {
        uint256 oldIncentiveAmount = incentiveAmount;
        incentiveAmount = newIncentiveAmount;
        emit IncentiveUpdate(oldIncentiveAmount, newIncentiveAmount);
    }

    /// @notice incentivize a call with incentiveAmount FEI rewards
    /// @dev no-op if the contract does not have Minter role
    function _incentivize() internal ifMinterSelf {
        _mintFei(msg.sender, incentiveAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../../utils/RateLimited.sol";

/// @title abstract contract for putting a rate limit on how fast a contract can mint FEI
/// @author Fei Protocol
abstract contract RateLimitedMinter is RateLimited {

    uint256 private constant MAX_FEI_LIMIT_PER_SECOND = 10_000e18; // 10000 FEI/s or ~860m FEI/day
    
    constructor(
        uint256 _feiLimitPerSecond, 
        uint256 _mintingBufferCap, 
        bool _doPartialMint
    ) 
        RateLimited(MAX_FEI_LIMIT_PER_SECOND, _feiLimitPerSecond, _mintingBufferCap, _doPartialMint)
    {}

    /// @notice override the FEI minting behavior to enforce a rate limit
    function _mintFei(address to, uint256 amount) internal virtual override {
        uint256 mintAmount = _depleteBuffer(amount);
        super._mintFei(to, mintAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title abstract contract for putting a rate limit on how fast a contract can perform an action e.g. Minting
/// @author Fei Protocol
abstract contract RateLimited is CoreRef {

    /// @notice maximum rate limit per second governance can set for this contract
    uint256 public immutable MAX_RATE_LIMIT_PER_SECOND;

    /// @notice the rate per second for this contract
    uint256 public rateLimitPerSecond;

    /// @notice the last time the buffer was used by the contract
    uint256 public lastBufferUsedTime;

    /// @notice the cap of the buffer that can be used at once
    uint256 public bufferCap;

    /// @notice a flag for whether to allow partial actions to complete if the buffer is less than amount
    bool public doPartialAction;

    /// @notice the buffer at the timestamp of lastBufferUsedTime
    uint256 private _bufferStored;

    event BufferUsed(uint256 amountUsed, uint256 bufferRemaining);
    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);
    event RateLimitPerSecondUpdate(uint256 oldRateLimitPerSecond, uint256 newRateLimitPerSecond);

    constructor(uint256 _maxRateLimitPerSecond, uint256 _rateLimitPerSecond, uint256 _bufferCap, bool _doPartialAction) {
        lastBufferUsedTime = block.timestamp;

        _setBufferCap(_bufferCap);
        _bufferStored = _bufferCap;

        require(_rateLimitPerSecond <= _maxRateLimitPerSecond, "RateLimited: rateLimitPerSecond too high");
        _setRateLimitPerSecond(_rateLimitPerSecond);
        
        MAX_RATE_LIMIT_PER_SECOND = _maxRateLimitPerSecond;
        doPartialAction = _doPartialAction;
    }

    /// @notice set the rate limit per second
    function setRateLimitPerSecond(uint256 newRateLimitPerSecond) external virtual onlyGovernorOrAdmin {
        require(newRateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND, "RateLimited: rateLimitPerSecond too high");
        _updateBufferStored();
        
        _setRateLimitPerSecond(newRateLimitPerSecond);
    }

    /// @notice set the buffer cap
    function setBufferCap(uint256 newBufferCap) external virtual onlyGovernorOrAdmin {
        _setBufferCap(newBufferCap);
    }

    /// @notice the amount of action used before hitting limit
    /// @dev replenishes at rateLimitPerSecond per second up to bufferCap
    function buffer() public view returns(uint256) { 
        uint256 elapsed = block.timestamp - lastBufferUsedTime;
        return Math.min(_bufferStored + (rateLimitPerSecond * elapsed), bufferCap);
    }

    /** 
        @notice the method that enforces the rate limit. Decreases buffer by "amount". 
        If buffer is <= amount either
        1. Does a partial mint by the amount remaining in the buffer or
        2. Reverts
        Depending on whether doPartialAction is true or false
    */
    function _depleteBuffer(uint256 amount) internal returns(uint256) {
        uint256 newBuffer = buffer();
        
        uint256 usedAmount = amount;
        if (doPartialAction && usedAmount > newBuffer) {
            usedAmount = newBuffer;
        }

        require(newBuffer != 0, "RateLimited: no rate limit buffer");
        require(usedAmount <= newBuffer, "RateLimited: rate limit hit");

        _bufferStored = newBuffer - usedAmount;

        lastBufferUsedTime = block.timestamp;

        emit BufferUsed(usedAmount, _bufferStored);

        return usedAmount;
    }

    function _setRateLimitPerSecond(uint256 newRateLimitPerSecond) internal {
        uint256 oldRateLimitPerSecond = rateLimitPerSecond;
        rateLimitPerSecond = newRateLimitPerSecond;

        emit RateLimitPerSecondUpdate(oldRateLimitPerSecond, newRateLimitPerSecond);
    }

    function _setBufferCap(uint256 newBufferCap) internal {
        _updateBufferStored();

        uint256 oldBufferCap = bufferCap;
        bufferCap = newBufferCap;

        emit BufferCapUpdate(oldBufferCap, newBufferCap);
    }

    function _resetBuffer() internal {
        _bufferStored = bufferCap;
    }

    function _updateBufferStored() internal {
        _bufferStored = buffer();
        lastBufferUsedTime = block.timestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IOracleRef.sol";
import "./CoreRef.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Reference to an Oracle
/// @author Fei Protocol
/// @notice defines some utilities around interacting with the referenced oracle
abstract contract OracleRef is IOracleRef, CoreRef {
    using Decimal for Decimal.D256;
    using SafeCast for int256;

    /// @notice the oracle reference by the contract
    IOracle public override oracle;

    /// @notice the backup oracle reference by the contract
    IOracle public override backupOracle;

    /// @notice number of decimals to scale oracle price by, i.e. multiplying by 10^(decimalsNormalizer)
    int256 public override decimalsNormalizer;

    bool public override doInvert;

    /// @notice OracleRef constructor
    /// @param _core Fei Core to reference
    /// @param _oracle oracle to reference
    /// @param _backupOracle backup oracle to reference
    /// @param _decimalsNormalizer number of decimals to normalize the oracle feed if necessary
    /// @param _doInvert invert the oracle price if this flag is on
    constructor(address _core, address _oracle, address _backupOracle, int256 _decimalsNormalizer, bool _doInvert) CoreRef(_core) {
        _setOracle(_oracle);
        if (_backupOracle != address(0) && _backupOracle != _oracle) {
            _setBackupOracle(_backupOracle);
        }
        _setDoInvert(_doInvert);
        _setDecimalsNormalizer(_decimalsNormalizer);
    }

    /// @notice sets the referenced oracle
    /// @param newOracle the new oracle to reference
    function setOracle(address newOracle) external override onlyGovernor {
        _setOracle(newOracle);
    }

    /// @notice sets the flag for whether to invert or not
    /// @param newDoInvert the new flag for whether to invert
    function setDoInvert(bool newDoInvert) external override onlyGovernor {
        _setDoInvert(newDoInvert);
    }

    /// @notice sets the new decimalsNormalizer
    /// @param newDecimalsNormalizer the new decimalsNormalizer
    function setDecimalsNormalizer(int256 newDecimalsNormalizer) external override onlyGovernor {
        _setDecimalsNormalizer(newDecimalsNormalizer);
    }
    /// @notice sets the referenced backup oracle
    /// @param newBackupOracle the new backup oracle to reference
    function setBackupOracle(address newBackupOracle) external override onlyGovernorOrAdmin {
        _setBackupOracle(newBackupOracle);
    }

    /// @notice invert a peg price
    /// @param price the peg price to invert
    /// @return the inverted peg as a Decimal
    /// @dev the inverted peg would be X per FEI
    function invert(Decimal.D256 memory price)
        public
        pure
        override
        returns (Decimal.D256 memory)
    {
        return Decimal.one().div(price);
    }

    /// @notice updates the referenced oracle
    function updateOracle() public override {
        oracle.update();
    }

    /// @notice the peg price of the referenced oracle
    /// @return the peg as a Decimal
    /// @dev the peg is defined as FEI per X with X being ETH, dollars, etc
    function readOracle() public view override returns (Decimal.D256 memory) {
        (Decimal.D256 memory _peg, bool valid) = oracle.read();
        if (!valid && address(backupOracle) != address(0)) {
            (_peg, valid) = backupOracle.read();
        }
        require(valid, "OracleRef: oracle invalid");

        // Scale the oracle price by token decimals delta if necessary
        uint256 scalingFactor;
        if (decimalsNormalizer < 0) {
            scalingFactor = 10 ** (-1 * decimalsNormalizer).toUint256();
            _peg = _peg.div(scalingFactor);
        } else {
            scalingFactor = 10 ** decimalsNormalizer.toUint256();
            _peg = _peg.mul(scalingFactor);
        }

        // Invert the oracle price if necessary
        if (doInvert) {
            _peg = invert(_peg);
        }
        return _peg;
    }

    function _setOracle(address newOracle) internal {
        require(newOracle != address(0), "OracleRef: zero address");
        address oldOracle = address(oracle);
        oracle = IOracle(newOracle);
        emit OracleUpdate(oldOracle, newOracle);
    }

    // Supports zero address if no backup
    function _setBackupOracle(address newBackupOracle) internal {
        address oldBackupOracle = address(backupOracle);
        backupOracle = IOracle(newBackupOracle);
        emit BackupOracleUpdate(oldBackupOracle, newBackupOracle);
    }

    function _setDoInvert(bool newDoInvert) internal {
        bool oldDoInvert = doInvert;
        doInvert = newDoInvert;
        
        if (oldDoInvert != newDoInvert) {
            _setDecimalsNormalizer( -1 * decimalsNormalizer);
        }

        emit InvertUpdate(oldDoInvert, newDoInvert);
    }

    function _setDecimalsNormalizer(int256 newDecimalsNormalizer) internal {
        int256 oldDecimalsNormalizer = decimalsNormalizer;
        decimalsNormalizer = newDecimalsNormalizer;
        emit DecimalsNormalizerUpdate(oldDecimalsNormalizer, newDecimalsNormalizer);
    }

    function _setDecimalsNormalizerFromToken(address token) internal {
        int256 feiDecimals = 18;
        int256 _decimalsNormalizer = feiDecimals - int256(uint256(IERC20Metadata(token).decimals()));
        
        if (doInvert) {
            _decimalsNormalizer = -1 * _decimalsNormalizer;
        }
        
        _setDecimalsNormalizer(_decimalsNormalizer);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../oracle/IOracle.sol";

/// @title OracleRef interface
/// @author Fei Protocol
interface IOracleRef {
    // ----------- Events -----------

    event OracleUpdate(address indexed oldOracle, address indexed newOracle);

    event InvertUpdate(bool oldDoInvert, bool newDoInvert);

    event DecimalsNormalizerUpdate(int256 oldDecimalsNormalizer, int256 newDecimalsNormalizer);

    event BackupOracleUpdate(address indexed oldBackupOracle, address indexed newBackupOracle);


    // ----------- State changing API -----------

    function updateOracle() external;

    // ----------- Governor only state changing API -----------

    function setOracle(address newOracle) external;

    function setBackupOracle(address newBackupOracle) external;

    function setDecimalsNormalizer(int256 newDecimalsNormalizer) external;

    function setDoInvert(bool newDoInvert) external;

    // ----------- Getters -----------

    function oracle() external view returns (IOracle);

    function backupOracle() external view returns (IOracle);

    function doInvert() external view returns (bool);

    function decimalsNormalizer() external view returns (int256);

    function readOracle() external view returns (Decimal.D256 memory);

    function invert(Decimal.D256 calldata price)
        external
        pure
        returns (Decimal.D256 memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../external/Decimal.sol";

/// @title generic oracle interface for Fei Protocol
/// @author Fei Protocol
interface IOracle {
    // ----------- Events -----------

    event Update(uint256 _peg);

    // ----------- State changing API -----------

    function update() external;

    // ----------- Getters -----------

    function read() external view returns (Decimal.D256 memory, bool);

    function isOutdated() external view returns (bool);
    
}

/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020 Empty Set Squad <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 private constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title an abstract contract for timed events
/// @author Fei Protocol
abstract contract Timed {

    /// @notice the start timestamp of the timed period
    uint256 public startTime;

    /// @notice the duration of the timed period
    uint256 public duration;

    event DurationUpdate(uint256 oldDuration, uint256 newDuration);

    event TimerReset(uint256 startTime);

    constructor(uint256 _duration) {
        _setDuration(_duration);
    }

    modifier duringTime() {
        require(isTimeStarted(), "Timed: time not started");
        require(!isTimeEnded(), "Timed: time ended");
        _;
    }

    modifier afterTime() {
        require(isTimeEnded(), "Timed: time not ended");
        _;
    }

    /// @notice return true if time period has ended
    function isTimeEnded() public view returns (bool) {
        return remainingTime() == 0;
    }

    /// @notice number of seconds remaining until time is up
    /// @return remaining
    function remainingTime() public view returns (uint256) {
        return duration - timeSinceStart(); // duration always >= timeSinceStart which is on [0,d]
    }

    /// @notice number of seconds since contract was initialized
    /// @return timestamp
    /// @dev will be less than or equal to duration
    function timeSinceStart() public view returns (uint256) {
        if (!isTimeStarted()) {
            return 0; // uninitialized
        }
        uint256 _duration = duration;
        uint256 timePassed = block.timestamp - startTime; // block timestamp always >= startTime
        return timePassed > _duration ? _duration : timePassed;
    }

    function isTimeStarted() public view returns (bool) {
        return startTime != 0;
    }

    function _initTimed() internal {
        startTime = block.timestamp;
        
        emit TimerReset(block.timestamp);
    }

    function _setDuration(uint256 newDuration) internal {
        require(newDuration != 0, "Timed: zero duration");

        uint256 oldDuration = duration;
        duration = newDuration;
        emit DurationUpdate(oldDuration, newDuration);
    }
}

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

 library UniswapV2Library {
    using SafeMath for uint;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
 }

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IUniswapPCVDeposit.sol";
import "../../Constants.sol";
import "../PCVDeposit.sol";
import "../../refs/UniRef.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title implementation for Uniswap LP PCV Deposit
/// @author Fei Protocol
contract UniswapPCVDeposit is IUniswapPCVDeposit, PCVDeposit, UniRef {
    using Decimal for Decimal.D256;
    using Babylonian for uint256;

    /// @notice a slippage protection parameter, deposits revert when spot price is > this % from oracle
    uint256 public override maxBasisPointsFromPegLP;

    /// @notice the Uniswap router contract
    IUniswapV2Router02 public override router;

    /// @notice Uniswap PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _pair Uniswap Pair to deposit to
    /// @param _router Uniswap Router
    /// @param _oracle oracle for reference
    /// @param _backupOracle the backup oracle to reference
    /// @param _maxBasisPointsFromPegLP the max basis points of slippage from peg allowed on LP deposit
    constructor(
        address _core,
        address _pair,
        address _router,
        address _oracle,
        address _backupOracle,
        uint256 _maxBasisPointsFromPegLP
    ) UniRef(_core, _pair, _oracle, _backupOracle) {
        router = IUniswapV2Router02(_router);

        _approveToken(address(fei()));
        _approveToken(token);
        _approveToken(_pair);

        maxBasisPointsFromPegLP = _maxBasisPointsFromPegLP;
        emit MaxBasisPointsFromPegLPUpdate(0, _maxBasisPointsFromPegLP);
    }

    receive() external payable {
        _wrap();
    }

    /// @notice deposit tokens into the PCV allocation
    function deposit() external override whenNotPaused {
        updateOracle();

        // Calculate amounts to provide liquidity
        uint256 tokenAmount = IERC20(token).balanceOf(address(this));
        uint256 feiAmount = readOracle().mul(tokenAmount).asUint256();

        _addLiquidity(tokenAmount, feiAmount);

        _burnFeiHeld(); // burn any FEI dust from LP

        emit Deposit(msg.sender, tokenAmount);
    }

    /// @notice withdraw tokens from the PCV allocation
    /// @param amountUnderlying of tokens withdrawn
    /// @param to the address to send PCV to
    /// @dev has rounding errors on amount to withdraw, can differ from the input "amountUnderlying"
    function withdraw(address to, uint256 amountUnderlying)
        external
        override
        onlyPCVController
        whenNotPaused
    {
        uint256 totalUnderlying = balance();
        require(
            amountUnderlying <= totalUnderlying,
            "UniswapPCVDeposit: Insufficient underlying"
        );

        uint256 totalLiquidity = liquidityOwned();

        // ratio of LP tokens needed to get out the desired amount
        Decimal.D256 memory ratioToWithdraw =
            Decimal.ratio(amountUnderlying, totalUnderlying);

        // amount of LP tokens to withdraw factoring in ratio
        uint256 liquidityToWithdraw =
            ratioToWithdraw.mul(totalLiquidity).asUint256();

        // Withdraw liquidity from the pair and send to target
        uint256 amountWithdrawn = _removeLiquidity(liquidityToWithdraw);
        SafeERC20.safeTransfer(IERC20(token), to, amountWithdrawn);

        _burnFeiHeld(); // burn remaining FEI

        emit Withdrawal(msg.sender, to, amountWithdrawn);
    }

    /// @notice sets the new slippage parameter for depositing liquidity
    /// @param _maxBasisPointsFromPegLP the new distance in basis points (1/10000) from peg beyond which a liquidity provision will fail
    function setMaxBasisPointsFromPegLP(uint256 _maxBasisPointsFromPegLP)
        public
        override
        onlyGovernorOrAdmin
    {
        require(
            _maxBasisPointsFromPegLP <= Constants.BASIS_POINTS_GRANULARITY,
            "UniswapPCVDeposit: basis points from peg too high"
        );

        uint256 oldMaxBasisPointsFromPegLP = maxBasisPointsFromPegLP;
        maxBasisPointsFromPegLP = _maxBasisPointsFromPegLP;

        emit MaxBasisPointsFromPegLPUpdate(
            oldMaxBasisPointsFromPegLP,
            _maxBasisPointsFromPegLP
        );
    }

    /// @notice set the new pair contract
    /// @param _pair the new pair
    /// @dev also approves the router for the new pair token and underlying token
    function setPair(address _pair) public virtual override onlyGovernor {
        _setupPair(_pair);

        _approveToken(token);
        _approveToken(_pair);
    }

    /// @notice returns total balance of PCV in the Deposit excluding the FEI
    function balance() public view override returns (uint256) {
        (, uint256 tokenReserves) = getReserves();
        return _ratioOwned().mul(tokenReserves).asUint256();
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return token;
    }

    /**
        @notice get the manipulation resistant Other(example ETH) and FEI in the Uniswap pool
        @return number of other token in pool
        @return number of FEI in pool

        Derivation rETH, rFEI = resistant (ideal) ETH and FEI reserves, P = price of ETH in FEI:
        1. rETH * rFEI = k
        2. rETH = k / rFEI
        3. rETH = (k * rETH) / (rFEI * rETH)
        4. rETH ^ 2 = k / P
        5. rETH = sqrt(k / P)

        and rFEI = k / rETH by 1.

        Finally scale the resistant reserves by the ratio owned by the contract
     */
    function resistantBalanceAndFei() public view override returns(uint256, uint256) {
        (uint256 feiInPool, uint256 otherInPool) = getReserves();

        Decimal.D256 memory priceOfToken = readOracle();

        uint256 k = feiInPool * otherInPool;

        // resistant other/fei in pool
        uint256 resistantOtherInPool = Decimal.one().div(priceOfToken).mul(k).asUint256().sqrt();

        uint256 resistantFeiInPool = Decimal.ratio(k, resistantOtherInPool).asUint256();

        Decimal.D256 memory ratioOwned = _ratioOwned();
        return (
            ratioOwned.mul(resistantOtherInPool).asUint256(),
            ratioOwned.mul(resistantFeiInPool).asUint256()
        );
    }

    /// @notice amount of pair liquidity owned by this contract
    /// @return amount of LP tokens
    function liquidityOwned() public view virtual override returns (uint256) {
        return pair.balanceOf(address(this));
    }

    function _removeLiquidity(uint256 liquidity) internal virtual returns (uint256) {
        uint256 endOfTime = type(uint256).max;
        // No restrictions on withdrawal price
        (, uint256 amountWithdrawn) =
            router.removeLiquidity(
                address(fei()),
                token,
                liquidity,
                0,
                0,
                address(this),
                endOfTime
            );
        return amountWithdrawn;
    }

    function _addLiquidity(uint256 tokenAmount, uint256 feiAmount) internal virtual {
        _mintFei(address(this), feiAmount);

        uint256 endOfTime = type(uint256).max;
        // Deposit price gated by slippage parameter
        router.addLiquidity(
            address(fei()),
            token,
            feiAmount,
            tokenAmount,
            _getMinLiquidity(feiAmount),
            _getMinLiquidity(tokenAmount),
            address(this),
            endOfTime
        );
    }

    /// @notice used as slippage protection when adding liquidity to the pool
    function _getMinLiquidity(uint256 amount) internal view returns (uint256) {
        return
            (amount * (Constants.BASIS_POINTS_GRANULARITY - maxBasisPointsFromPegLP)) /
            Constants.BASIS_POINTS_GRANULARITY;
    }

    /// @notice ratio of all pair liquidity owned by this contract
    function _ratioOwned() internal view returns (Decimal.D256 memory) {
        uint256 liquidity = liquidityOwned();
        uint256 total = pair.totalSupply();
        return Decimal.ratio(liquidity, total);
    }

    /// @notice approves a token for the router
    function _approveToken(address _token) internal {
        uint256 maxTokens = type(uint256).max;
        IERC20(_token).approve(address(router), maxTokens);
    }

    // Wrap all held ETH
    function _wrap() internal {
        uint256 amount = address(this).balance;
        IWETH(router.WETH()).deposit{value: amount}();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./OracleRef.sol";
import "./IUniRef.sol";

/// @title A Reference to Uniswap
/// @author Fei Protocol
/// @notice defines some utilities around interacting with Uniswap
/// @dev the uniswap pair should be FEI and another asset
abstract contract UniRef is IUniRef, OracleRef {

    /// @notice the referenced Uniswap pair contract
    IUniswapV2Pair public override pair;

    /// @notice the address of the non-fei underlying token
    address public override token;

    /// @notice UniRef constructor
    /// @param _core Fei Core to reference
    /// @param _pair Uniswap pair to reference
    /// @param _oracle oracle to reference
    /// @param _backupOracle backup oracle to reference
    constructor(
        address _core,
        address _pair,
        address _oracle,
        address _backupOracle
    ) OracleRef(_core, _oracle, _backupOracle, 0, false) {
        _setupPair(_pair);
        _setDecimalsNormalizerFromToken(_token());
    }

    /// @notice set the new pair contract
    /// @param newPair the new pair
    function setPair(address newPair) external override virtual onlyGovernor {
        _setupPair(newPair);
    }

    /// @notice pair reserves with fei listed first
    function getReserves()
        public
        view
        override
        returns (uint256 feiReserves, uint256 tokenReserves)
    {
        address token0 = pair.token0();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (feiReserves, tokenReserves) = address(fei()) == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        return (feiReserves, tokenReserves);
    }

    function _setupPair(address newPair) internal {
        require(newPair != address(0), "UniRef: zero address");

        address oldPair = address(pair);
        pair = IUniswapV2Pair(newPair);
        emit PairUpdate(oldPair, newPair);

        token = _token();
    }

    function _token() internal view returns (address) {
        address token0 = pair.token0();
        if (address(fei()) == token0) {
            return pair.token1();
        }
        return token0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// @title UniRef interface
/// @author Fei Protocol
interface IUniRef {
    // ----------- Events -----------

    event PairUpdate(address indexed oldPair, address indexed newPair);

    // ----------- Governor only state changing api -----------

    function setPair(address newPair) external;

    // ----------- Getters -----------

    function pair() external view returns (IUniswapV2Pair);

    function token() external view returns (address);

    function getReserves()
        external
        view
        returns (uint256 feiReserves, uint256 tokenReserves);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../PCVDeposit.sol";

interface DelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;

    function delegation(address delegator, bytes32 id) external view returns(address delegatee);
}

/// @title Snapshot Delegator PCV Deposit
/// @author Fei Protocol
contract SnapshotDelegatorPCVDeposit is PCVDeposit {

    event DelegateUpdate(address indexed oldDelegate, address indexed newDelegate);

    /// @notice the Gnosis delegate registry used by snapshot
    DelegateRegistry public constant DELEGATE_REGISTRY = DelegateRegistry(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);
    
    /// @notice the token that is being used for snapshot
    IERC20 public immutable token;

    /// @notice the keccak encoded spaceId of the snapshot space
    bytes32 public spaceId;
    
    /// @notice the snapshot delegate for the deposit
    address public delegate;

    /// @notice Snapshot Delegator PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _token snapshot token
    /// @param _spaceId the id (or ENS name) of the snapshot space
    constructor(
        address _core,
        IERC20 _token,
        bytes32 _spaceId,
        address _initialDelegate
    ) CoreRef(_core) {
        token = _token;
        spaceId = _spaceId;
        _delegate(_initialDelegate);
    }

    /// @notice withdraw tokens from the PCV allocation
    /// @param amountUnderlying of tokens withdrawn
    /// @param to the address to send PCV to
    function withdraw(address to, uint256 amountUnderlying)
        external
        override
        onlyPCVController
    {
        _withdrawERC20(address(token), to, amountUnderlying);
    }

    /// @notice no-op
    function deposit() external override {}

    /// @notice returns total balance of PCV in the Deposit
    function balance() public view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return address(token);
    }

    /// @notice sets the snapshot delegate
    /// @dev callable by governor or admin
    function setDelegate(address newDelegate) external onlyGovernorOrAdmin {
        _delegate(newDelegate);
    }

    /// @notice clears the delegate from snapshot
    /// @dev callable by governor or guardian
    function clearDelegate() external onlyGuardianOrGovernor {
        address oldDelegate = delegate;
        DELEGATE_REGISTRY.clearDelegate(spaceId);

        emit DelegateUpdate(oldDelegate, address(0));
    }

    function _delegate(address newDelegate) internal {
        address oldDelegate = delegate;
        DELEGATE_REGISTRY.setDelegate(spaceId, newDelegate);
        delegate = newDelegate;

        emit DelegateUpdate(oldDelegate, newDelegate);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../PCVDeposit.sol";
import "../../Constants.sol";
import "../../refs/CoreRef.sol";
import "../../external/Decimal.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// stETH Token contract specific functions
interface ILido {
    function getTotalShares() external view returns (uint256);
    function getTotalPooledEther() external view returns (uint256);
    function sharesOf(address _account) external view returns (uint256);
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
    function getFee() external view returns (uint256);
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
    function submit(address referral) external payable returns (uint256);
}

// Curve stETH-ETH pool
interface IStableSwapSTETH {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function coins(uint256 arg0) external view returns (address);
}

/// @title implementation for PCV Deposit that can take ETH and get stETH either
/// by staking on Lido or swapping on Curve, and sell back stETH for ETH on Curve.
/// @author eswak, realisation
contract EthLidoPCVDeposit is PCVDeposit {
    using SafeERC20 for ERC20;
    using Decimal for Decimal.D256;

    // ----------- Events ---------------
    event UpdateMaximumSlippage(uint256 maximumSlippageBasisPoints);

    // ----------- Properties -----------
    // References to external contracts
    address public immutable steth;
    address public immutable stableswap;

    // Maximum tolerated slippage
    uint256 public maximumSlippageBasisPoints;

    constructor(
        address _core,
        address _steth,
        address _stableswap,
        uint256 _maximumSlippageBasisPoints
    ) CoreRef(_core) {
        steth = _steth;
        stableswap = _stableswap;
        maximumSlippageBasisPoints = _maximumSlippageBasisPoints;
    }

    // Empty callback on ETH reception
    receive() external payable {}

    // =======================================================================
    // IPCVDeposit interface override
    // =======================================================================
    /// @notice deposit ETH held by the contract to get stETH.
    /// @dev everyone can call deposit(), it is not protected by PCVController
    /// rights, because all ETH held by the contract is destined to be
    /// changed to stETH anyway.
    function deposit() external override whenNotPaused {
        uint256 amountIn = address(this).balance;
        require(amountIn > 0, "EthLidoPCVDeposit: cannot deposit 0.");

        // Get the expected amount of stETH out of a Curve trade
        // (single trade with all the held ETH)
        address _tokenOne = IStableSwapSTETH(stableswap).coins(0);
        uint256 expectedAmountOut = IStableSwapSTETH(stableswap).get_dy(
            _tokenOne == steth ? int128(1) : int128(0),
            _tokenOne == steth ? int128(0) : int128(1),
            amountIn
        );

        // If we get more stETH out than ETH in by swapping on Curve,
        // get the stETH by doing a Curve swap.
        uint256 actualAmountOut;
        uint256 balanceBefore = IERC20(steth).balanceOf(address(this));
        if (expectedAmountOut > amountIn) {
            uint256 minimumAmountOut = amountIn;

            // Allowance to trade stETH on the Curve pool
            IERC20(steth).approve(stableswap, amountIn);

            // Perform swap
            actualAmountOut = IStableSwapSTETH(stableswap).exchange{value: amountIn}(
                _tokenOne == steth ? int128(1) : int128(0),
                _tokenOne == steth ? int128(0) : int128(1),
                amountIn,
                minimumAmountOut
            );
        }
        // Otherwise, stake ETH for stETH directly on the Lido contract
        // to get a 1:1 trade.
        else {
            ILido(steth).submit{value: amountIn}(address(0));
            actualAmountOut = amountIn;
        }

        // Check the received amount
        uint256 balanceAfter = IERC20(steth).balanceOf(address(this));
        uint256 amountReceived = balanceAfter - balanceBefore;
        // @dev: check is not made on "actualAmountOut" directly, because sometimes
        // there are float rounding error, and we get a few wei less. Additionally,
        // the stableswap could return the uint256 amountOut but never transfer tokens.
        Decimal.D256 memory maxSlippage = Decimal.ratio(Constants.BASIS_POINTS_GRANULARITY - maximumSlippageBasisPoints, Constants.BASIS_POINTS_GRANULARITY);
        uint256 minimumAcceptedAmountOut = maxSlippage.mul(amountIn).asUint256();
        require(amountReceived >= minimumAcceptedAmountOut, "EthLidoPCVDeposit: not enough stETH received.");

        emit Deposit(msg.sender, actualAmountOut);
    }

    /// @notice withdraw stETH held by the contract to get ETH.
    /// This function with swap stETH held by the contract to ETH, and transfer
    /// it to the target address. Note: the withdraw could
    /// revert if the Curve pool is imbalanced with too many stETH and the amount
    /// of ETH out of the trade is less than the tolerated slippage.
    /// @param to the destination of the withdrawn ETH
    /// @param amountIn the number of stETH to withdraw.
    function withdraw(address to, uint256 amountIn) external override onlyPCVController whenNotPaused {
        require(balance() >= amountIn, "EthLidoPCVDeposit: not enough stETH.");

        // Compute the minimum accepted amount of ETH out of the trade, based
        // on the slippage settings.
        Decimal.D256 memory maxSlippage = Decimal.ratio(Constants.BASIS_POINTS_GRANULARITY - maximumSlippageBasisPoints, Constants.BASIS_POINTS_GRANULARITY);
        uint256 minimumAcceptedAmountOut = maxSlippage.mul(amountIn).asUint256();

        // Swap stETH for ETH on the Curve pool
        uint256 balanceBefore = address(this).balance;
        address _tokenOne = IStableSwapSTETH(stableswap).coins(0);
        IERC20(steth).approve(stableswap, amountIn);
        uint256 actualAmountOut = IStableSwapSTETH(stableswap).exchange(
            _tokenOne == steth ? int128(0) : int128(1),
            _tokenOne == steth ? int128(1) : int128(0),
            amountIn,
            0 // minimum accepted amount out
        );

        // Check that we received enough stETH as an output of the trade
        // This is enforced in this contract, after knowing the output of the trade,
        // instead of the StableSwap pool's min_dy check.
        require(actualAmountOut >= minimumAcceptedAmountOut, "EthLidoPCVDeposit: slippage too high.");

        // Check the received amount
        uint256 balanceAfter = address(this).balance;
        uint256 amountReceived = balanceAfter - balanceBefore;
        require(amountReceived >= minimumAcceptedAmountOut, "EthLidoPCVDeposit: not enough ETH received.");

        // Transfer ETH to destination.
        Address.sendValue(payable(to), actualAmountOut);

        emit Withdrawal(msg.sender, to, actualAmountOut);
    }

    /// @notice Returns the current balance of stETH held by the contract
    function balance() public view override returns (uint256 amount) {
        return IERC20(steth).balanceOf(address(this));
    }

    // =======================================================================
    // Functions specific to EthLidoPCVDeposit
    // =======================================================================
    /// @notice Sets the maximum slippage vs 1:1 price accepted during withdraw.
    /// @param _maximumSlippageBasisPoints the maximum slippage expressed in basis points (1/10_000)
    function setMaximumSlippage(uint256 _maximumSlippageBasisPoints) external onlyGovernorOrAdmin {
        require(_maximumSlippageBasisPoints <= Constants.BASIS_POINTS_GRANULARITY, "EthLidoPCVDeposit: Exceeds bp granularity.");
        maximumSlippageBasisPoints = _maximumSlippageBasisPoints;
        emit UpdateMaximumSlippage(_maximumSlippageBasisPoints);
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public pure override returns (address) {
        return address(Constants.WETH);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../uniswap/UniswapPCVDeposit.sol";

// Angle PoolManager contract
interface IPoolManager {
    function token() external returns (address);
}

// Angle StableMaster contract
interface IStableMaster {
    function agToken() external returns (address);

    function mint(
        uint256 amount,
        address user,
        IPoolManager poolManager,
        uint256 minStableAmount
    ) external;

    function burn(
        uint256 amount,
        address burner,
        address dest,
        IPoolManager poolManager,
        uint256 minCollatAmount
    ) external;

    function unpause(bytes32 agent, IPoolManager poolManager) external;
}

// Angle StakingRewards contract
interface IStakingRewards {
    function stakingToken() external returns (address);

    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;
}

/// @title implementation for Angle PCV Deposit
/// @author Angle Core Team and Fei Protocol
contract AngleUniswapPCVDeposit is UniswapPCVDeposit {
    using Decimal for Decimal.D256;

    /// @notice the Angle StableMaster contract
    IStableMaster public immutable stableMaster;

    /// @notice the Angle PoolManager contract
    IPoolManager public poolManager;

    /// @notice the Angle StakingRewards contract
    IStakingRewards public stakingRewards;

    /// @notice Uniswap PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _pair Uniswap Pair to deposit to
    /// @param _router Uniswap Router
    /// @param _oracle oracle for reference
    /// @param _backupOracle the backup oracle to reference
    /// @param _maxBasisPointsFromPegLP the max basis points of slippage from peg allowed on LP deposit
    constructor(
        address _core,
        address _pair,
        address _router,
        address _oracle,
        address _backupOracle,
        uint256 _maxBasisPointsFromPegLP,
        IStableMaster _stableMaster,
        IPoolManager _poolManager,
        IStakingRewards _stakingRewards
    ) UniswapPCVDeposit(_core, _pair, _router, _oracle, _backupOracle, _maxBasisPointsFromPegLP) {
        stableMaster = _stableMaster;
        poolManager = _poolManager;
        stakingRewards = _stakingRewards;
        require(_poolManager.token() == address(fei()), "AngleUniswapPCVDeposit: invalid poolManager");
        require(_stableMaster.agToken() == token, "AngleUniswapPCVDeposit: invalid stableMaster");
        require(_stakingRewards.stakingToken() == _pair, "AngleUniswapPCVDeposit: invalid stakingRewards");

        // Approve FEI on StableMaster to be able to mint agTokens
        SafeERC20.safeApprove(IERC20(address(fei())), address(_stableMaster), type(uint256).max);
        // Approve LP tokens on StakingRewards to earn ANGLE rewards
        SafeERC20.safeApprove(IERC20(_pair), address(_stakingRewards), type(uint256).max);
    }

    /// @notice claim staking rewards
    function claimRewards() external {
        stakingRewards.getReward();
    }

    /// @notice mint agToken from FEI
    /// @dev the call will revert if slippage is too high compared to oracle.
    function mintAgToken(uint256 amountFei)
        public
        onlyPCVController
    {
        // compute minimum amount out
        uint256 minAgTokenOut = Decimal.from(amountFei)
          .div(readOracle())
          .mul(Constants.BASIS_POINTS_GRANULARITY - maxBasisPointsFromPegLP)
          .div(Constants.BASIS_POINTS_GRANULARITY)
          .asUint256();

        // mint FEI to self
        _mintFei(address(this), amountFei);

        // mint agToken from FEI
        stableMaster.mint(
            amountFei,
            address(this),
            poolManager,
            minAgTokenOut
        );
    }

    /// @notice burn agToken for FEI
    /// @dev the call will revert if slippage is too high compared to oracle
    function burnAgToken(uint256 amountAgToken)
        public
        onlyPCVController
    {
        // compute minimum of FEI out for agTokens burnt
        uint256 minFeiOut = readOracle() // FEI per X
          .mul(amountAgToken)
          .mul(Constants.BASIS_POINTS_GRANULARITY - maxBasisPointsFromPegLP)
          .div(Constants.BASIS_POINTS_GRANULARITY)
          .asUint256();

        // burn agTokens for FEI
        stableMaster.burn(
            amountAgToken,
            address(this),
            address(this),
            poolManager,
            minFeiOut
        );

        // burn FEI held (after redeeming agTokens, we have some)
        _burnFeiHeld();
    }

    /// @notice burn ALL agToken held for FEI
    /// @dev see burnAgToken(uint256 amount).
    function burnAgTokenAll()
        external
        onlyPCVController
    {
        burnAgToken(IERC20(token).balanceOf(address(this)));
    }

    /// @notice set the new pair contract
    /// @param _pair the new pair
    /// @dev also approves the router for the new pair token and underlying token
    function setPair(address _pair) public override onlyGovernor {
        super.setPair(_pair);
        SafeERC20.safeApprove(IERC20(_pair), address(stakingRewards), type(uint256).max);
    }

    /// @notice set a new stakingRewards address
    /// @param _stakingRewards the new stakingRewards
    function setStakingRewards(IStakingRewards _stakingRewards)
        public
        onlyGovernor
    {
        require(
            address(_stakingRewards) != address(0),
            "AngleUniswapPCVDeposit: zero address"
        );
        stakingRewards = _stakingRewards;
    }

    /// @notice set a new poolManager address
    /// @param _poolManager the new poolManager
    function setPoolManager(IPoolManager _poolManager)
        public
        onlyGovernor
    {
        require(
            address(_poolManager) != address(0),
            "AngleUniswapPCVDeposit: zero address"
        );
        poolManager = _poolManager;
    }

    /// @notice amount of pair liquidity owned by this contract
    /// @return amount of LP tokens
    function liquidityOwned() public view override returns (uint256) {
        return pair.balanceOf(address(this)) + stakingRewards.balanceOf(address(this));
    }

    function _removeLiquidity(uint256 liquidity) internal override returns (uint256) {
        stakingRewards.withdraw(liquidity);
        return super._removeLiquidity(liquidity);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 feiAmount) internal override {
        super._addLiquidity(tokenAmount, feiAmount);
        uint256 lpBalanceAfter = pair.balanceOf(address(this));
        stakingRewards.stake(lpBalanceAfter);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDeposit.sol";
import "../external/Decimal.sol";

/** 
 @title a PCV Deposit aggregation interface
 @author Fei Protocol

 This contract is a single interface for allocating a specific token to multiple PCV Deposits.
 The aggregator handles new incoming funds and outgoing funds by selecting deposits which are over or under-funded to save for gas and efficiency
*/

interface IPCVDepositAggregator {
    // ----------- Events -----------

    event DepositAdded(
        address indexed depositAddress, 
        uint256 weight
    );

    event DepositRemoved(
        address indexed depositAddress
    );

    event AggregatorWithdrawal(
        uint256 amount
    );

    event AggregatorDeposit();

    event AggregatorDepositSingle(
        address indexed depositAddress,
        uint256 amount
    );

    event AggregatorUpdate(
        address indexed oldAggregator,
        address indexed newAggregator
    );

    event AssetManagerUpdate(
        address indexed oldAssetManager,
        address indexed newAssetManager
    );

    event BufferWeightUpdate(
        uint256 oldWeight,
        uint256 newWeight
    );

    event DepositWeightUpdate(
        address indexed depositAddress, 
        uint256 oldWeight, 
        uint256 newWeight
    );

    // ----------- Public Functions ----------

    /// @notice tops up a deposit from the aggregator's balance
    /// @param pcvDeposit the address of the pcv deposit to top up
    /// @dev this will only pull from the balance that is left over after the aggregator's buffer fills up
    function depositSingle(address pcvDeposit) external;

    // ----------- Governor Only State Changing API -----------

    /// @notice replaces this contract with a new PCV Deposit Aggregator on the rewardsAssetManager
    /// @param newAggregator the address of the new PCV Deposit Aggregator
    function setNewAggregator(address newAggregator) external;

    /// @notice sets the rewards asset manager
    /// @param newAssetManager the address of the new rewards asset manager
    function setAssetManager(address newAssetManager) external;

    // ----------- Governor or Admin Only State Changing API -----------

    /// @notice adds a new PCV Deposit to the set of deposits
    /// @param weight a relative (i.e. not normalized) weight of this PCV deposit
    function addPCVDeposit(address newPCVDeposit, uint256 weight) external;

    /// @notice remove a PCV deposit from the set of deposits
    /// @param pcvDeposit the address of the PCV deposit to remove
    /// @param shouldRebalance whether or not to withdraw from the pcv deposit before removing it
    function removePCVDeposit(address pcvDeposit, bool shouldRebalance) external;

    /// @notice set the relative weight of a particular pcv deposit
    /// @param depositAddress the address of the PCV deposit to set the weight of
    /// @param newDepositWeight the new relative weight of the PCV deposit
    function setPCVDepositWeight(address depositAddress, uint256 newDepositWeight) external;

    /// @notice set the weight for the buffer specifically
    /// @param weight the new weight for the buffer
    function setBufferWeight(uint256 weight) external;

    // ---------- Guardian or Governor Only State Changing API ----------

    /// @notice sets the weight of a pcv deposit to zero
    /// @param depositAddress the address of the pcv deposit to set the weight of to zero
    function setPCVDepositWeightZero(address depositAddress) external;

    // ----------- Read-Only API -----------

    /// @notice the token that the aggregator is managing
    /// @return the address of the token that the aggregator is managing
    function token() external view returns(address);

    /// @notice the upstream rewardsAssetManager funding this contract
    /// @return the address of the upstream rewardsAssetManager funding this contract
    function assetManager() external view returns(address);

    /// @notice returns true if the given address is a PCV Deposit in this aggregator
    /// @param pcvDeposit the address of the PCV deposit to check
    /// @return true if the given address is a PCV Deposit in this aggregator
    function hasPCVDeposit(address pcvDeposit) external view returns (bool);

    /// @notice the set of PCV deposits and non-normalized weights this contract allocates to\
    /// @return deposits addresses and weights as uints
    function pcvDeposits() external view returns(address[] memory deposits, uint256[] memory weights);

    /// @notice current percent of PCV held by the input `pcvDeposit` relative to the total managed by aggregator.
    /// @param pcvDeposit the address of the pcvDeposit
    /// @param depositAmount a hypothetical deposit amount, to be included in the calculation
    /// @return the percent held as a Decimal D256 value
    function percentHeld(address pcvDeposit, uint256 depositAmount) external view returns(Decimal.D256 memory);

    /// @notice the normalized target weight of PCV held by `pcvDeposit` relative to aggregator total
    /// @param pcvDeposit the address of the pcvDeposit
    /// @return the normalized target percent held as a Decimal D256 value
    function normalizedTargetWeight(address pcvDeposit) external view returns(Decimal.D256 memory);

    /// @notice the raw amount of PCV off of the target weight/percent held by `pcvDeposit`
    /// @dev a positive result means the target has "too much" pcv, and a negative result means it needs more pcv
    /// @param pcvDeposit the address of the pcvDeposit
    /// @return the amount from target as an int
    function amountFromTarget(address pcvDeposit) external view returns(int256);

    /// @notice the same as amountFromTarget, but for every targets
    /// @return distancesToTargets all amounts from targets as a uint256 array
    function getAllAmountsFromTargets() external view returns(int256[] memory);

    /// @notice returns the summation of all pcv deposit balances + the aggregator's balance
    /// @return the total amount of pcv held by the aggregator and the pcv deposits
    function getTotalBalance() external view returns(uint256);

    /// @notice returns the summation of all pcv deposit's resistant balance & fei
    /// @return the resistant balance and fei as uints
    function getTotalResistantBalanceAndFei() external view returns(uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../../Constants.sol";
import "../PCVDeposit.sol";
import "./ICurveStableSwap3.sol";

/// @title CurvePCVDepositPlainPool: implementation for a PCVDeposit that deploys
/// liquidity on Curve, in a plain pool (3 stable assets).
/// @author Fei Protocol
contract CurvePCVDepositPlainPool is PCVDeposit {

    // ------------------ Properties -------------------------------------------

    /// @notice maximum slippage accepted during deposit / withdraw, expressed
    /// in basis points (100% = 10_000).
    uint256 public maxSlippageBasisPoints;

    /// @notice The Curve pool to deposit in
    ICurveStableSwap3 public curvePool;

    /// @notice number of coins in the Curve pool
    uint256 private constant N_COINS = 3;
    /// @notice boolean to know if FEI is in the pool
    bool private immutable feiInPool;
    /// @notice FEI index in the pool. If FEI is not present, value = 0.
    uint256 private immutable feiIndexInPool;

    // ------------------ Constructor ------------------------------------------

    /// @notice CurvePCVDepositPlainPool constructor
    /// @param _core Fei Core for reference
    /// @param _curvePool The Curve pool to deposit in
    /// @param _maxSlippageBasisPoints max slippage for deposits, in bp
    constructor(
        address _core,
        address _curvePool,
        uint256 _maxSlippageBasisPoints
    ) CoreRef(_core) {
        curvePool = ICurveStableSwap3(_curvePool);
        maxSlippageBasisPoints = _maxSlippageBasisPoints;

        // cache some values for later gas optimizations
        address feiAddress = address(fei());
        bool foundFeiInPool = false;
        uint256 feiFoundAtIndex = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            address tokenAddress = ICurvePool(_curvePool).coins(i);
            if (tokenAddress == feiAddress) {
                foundFeiInPool = true;
                feiFoundAtIndex = i;
            }
        }
        feiInPool = foundFeiInPool;
        feiIndexInPool = feiFoundAtIndex;
    }

    /// @notice Curve/Convex deposits report their balance in USD
    function balanceReportedIn() public pure override returns(address) {
        return Constants.USD;
    }

    /// @notice deposit tokens into the Curve pool, then stake the LP tokens
    /// on Convex to earn rewards.
    function deposit() public override whenNotPaused {
        // fetch current balances
        uint256[N_COINS] memory balances;
        IERC20[N_COINS] memory tokens;
        uint256 totalBalances = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            tokens[i] = IERC20(curvePool.coins(i));
            balances[i] = tokens[i].balanceOf(address(this));
            totalBalances += balances[i];
        }

        // require non-empty deposit
        require(totalBalances > 0, "CurvePCVDepositPlainPool: cannot deposit 0");

        // set maximum allowed slippage
        uint256 virtualPrice = curvePool.get_virtual_price();
        uint256 minLpOut = totalBalances * 1e18 / virtualPrice;
        uint256 lpSlippageAccepted = minLpOut * maxSlippageBasisPoints / Constants.BASIS_POINTS_GRANULARITY;
        minLpOut -= lpSlippageAccepted;

        // approval
        for (uint256 i = 0; i < N_COINS; i++) {
            // approve for deposit
            if (balances[i] > 0) {
                tokens[i].approve(address(curvePool), balances[i]);
            }
        }

        // deposit in the Curve pool
        curvePool.add_liquidity(balances, minLpOut);
    }

    /// @notice Exit the Curve pool by removing liquidity in one token.
    /// If FEI is in the pool, pull FEI out of the pool. If FEI is not in the pool,
    /// exit in the first token of the pool. To exit without chosing a specific
    /// token, and minimize slippage, use exitPool().
    function withdraw(address to, uint256 amountUnderlying)
        public
        override
        onlyPCVController
        whenNotPaused
    {
        withdrawOneCoin(feiIndexInPool, to, amountUnderlying);
    }

    /// @notice Exit the Curve pool by removing liquidity in one token.
    /// Note that this method can cause slippage. To exit without slippage, use
    /// the exitPool() method.
    function withdrawOneCoin(uint256 coinIndexInPool, address to, uint256 amountUnderlying)
        public
        onlyPCVController
        whenNotPaused
    {
        // burn LP tokens to get one token out
        uint256 virtualPrice = curvePool.get_virtual_price();
        uint256 maxLpUsed = amountUnderlying * 1e18 / virtualPrice;
        uint256 lpSlippageAccepted = maxLpUsed * maxSlippageBasisPoints / Constants.BASIS_POINTS_GRANULARITY;
        maxLpUsed += lpSlippageAccepted;
        curvePool.remove_liquidity_one_coin(maxLpUsed, int128(int256(coinIndexInPool)), amountUnderlying);

        // send token to destination
        IERC20(curvePool.coins(coinIndexInPool)).transfer(to, amountUnderlying);
    }

    /// @notice Exit the Curve pool by removing liquidity. The contract
    /// will hold tokens in proportion to what was in the Curve pool at the time
    /// of exit, i.e. if the pool is 20% FRAX 60% FEI 20% alUSD, and the contract
    /// has 10M$ of liquidity, it will exit the pool with 2M FRAX, 6M FEI, 2M alUSD.
    function exitPool() public onlyPCVController whenNotPaused {
        // burn all LP tokens to exit pool
        uint256 lpTokenBalance = curvePool.balanceOf(address(this));
        uint256[N_COINS] memory minAmountsOuts;
        curvePool.remove_liquidity(lpTokenBalance, minAmountsOuts);
    }

    /// @notice returns the balance in USD
    function balance() public view override returns (uint256) {
        uint256 lpTokens = curvePool.balanceOf(address(this));
        uint256 virtualPrice = curvePool.get_virtual_price();
        uint256 usdBalance = lpTokens * virtualPrice / 1e18;

        // if FEI is in the pool, remove the FEI part of the liquidity, e.g. if
        // FEI is filling 40% of the pool, reduce the balance by 40%.
        if (feiInPool) {
            uint256[N_COINS] memory balances;
            uint256 totalBalances = 0;
            for (uint256 i = 0; i < N_COINS; i++) {
                IERC20 poolToken = IERC20(curvePool.coins(i));
                balances[i] = poolToken.balanceOf(address(curvePool));
                totalBalances += balances[i];
            }
            usdBalance -= usdBalance * balances[feiIndexInPool] / totalBalances;
        }

        return usdBalance;
    }

    /// @notice returns the resistant balance in USD and FEI held by the contract
    function resistantBalanceAndFei() public view override returns (
        uint256 resistantBalance,
        uint256 resistantFei
    ) {
        uint256 lpTokens = curvePool.balanceOf(address(this));
        uint256 virtualPrice = curvePool.get_virtual_price();
        resistantBalance = lpTokens * virtualPrice / 1e18;

        // to have a resistant balance, we assume the pool is balanced, e.g. if
        // the pool holds 3 tokens, we assume FEI is 33.3% of the pool.
        if (feiInPool) {
            resistantFei = resistantBalance / N_COINS;
            resistantBalance -= resistantFei;
        }

        return (resistantBalance, resistantFei);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ICurvePool.sol";

interface ICurveStableSwap3 is ICurvePool {
		// Deployment
		function __init__(address _owner, address[3] memory _coins, address _pool_token, uint256 _A, uint256 _fee, uint256 _admin_fee) external;

	  // Public property getters
	  function get_balances() external view returns (uint256[3] memory);

		// 3Pool
		function calc_token_amount(uint[3] memory amounts, bool deposit) external view returns (uint);
		function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
		function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;
		function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICurvePool {
    // Public property getters
    function coins(uint256 arg0) external view returns (address);
    function balances(uint256 arg0) external view returns (uint256);
    function fee() external view returns (uint256);
    function admin_fee() external view returns (uint256);
    function owner() external view returns (address);
    function lp_token() external view returns (address);
    function initial_A() external view returns (uint256);
    function future_A() external view returns (uint256);
    function initial_A_time() external view returns (uint256);
    function future_A_time() external view returns (uint256);
    function admin_actions_deadline() external view returns (uint256);
    function transfer_ownership_deadline() external view returns (uint256);
    function future_fee() external view returns (uint256);
    function future_admin_fee() external view returns (uint256);
    function future_owner() external view returns (address);

  	// ERC20 Standard
  	function decimals() external view returns (uint);
  	function transfer(address _to, uint _value) external returns (bool);
  	function transferFrom(address _from, address _to, uint _value) external returns (bool);
  	function approve(address _spender, uint _value) external returns (bool);
  	function totalSupply() external view returns (uint);
  	function mint(address _to, uint256 _value) external returns (bool);
  	function burnFrom(address _to, uint256 _value) external returns (bool);
  	function balanceOf(address _owner) external view returns (uint256);

  	// 3Pool
  	function A() external view returns (uint);
  	function get_virtual_price() external view returns (uint);
  	function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
  	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
  	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
  	function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
  	function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;

  	// Admin functions
  	function ramp_A(uint256 _future_A, uint256 _future_time) external;
  	function stop_ramp_A() external;
  	function commit_new_fee(uint256 new_fee, uint256 new_admin_fee) external;
  	function apply_new_fee() external;
  	function commit_transfer_ownership(address _owner) external;
  	function apply_transfer_ownership() external;
  	function revert_transfer_ownership() external;
  	function admin_balances(uint256 i) external returns (uint256);
  	function withdraw_admin_fees() external;
  	function donate_admin_fees() external;
  	function kill_me() external;
  	function unkill_me() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDepositAggregator.sol";
import "./PCVDeposit.sol";
import "../refs/CoreRef.sol";
import "../external/Decimal.sol";
import "./balancer/IRewardsAssetManager.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libs/UintArrayOps.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title PCV Deposit Aggregator
/// @notice A smart contract that aggregates erc20-based PCV deposits and rebalances them according to set weights 
contract PCVDepositAggregator is IPCVDepositAggregator, PCVDeposit {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;
    using Decimal for Decimal.D256;
    using UintArrayOps for uint256[];

    // ---------- Properties ----------

    EnumerableSet.AddressSet private pcvDepositAddresses;
    mapping(address => uint256) public pcvDepositWeights;
    
    // Bufferweights is the weight of the aggregator itself
    uint256 public bufferWeight;

    // Totalweight is the sum of all deposit weights + the buffer weight
    uint256 public totalWeight; 

    // The token that this aggregator deals with. Cannot be changed.
    address public immutable override token;

    // The asset manager that controls the rewards for this aggregator
    address public override assetManager;

    constructor(
        address _core,
        address _assetManager,
        address _token,
        address[] memory _initialPCVDepositAddresses,
        uint128[] memory _initialPCVDepositWeights,
        uint128 _bufferWeight
    ) CoreRef(_core) {
        require(_initialPCVDepositAddresses.length == _initialPCVDepositWeights.length, "Addresses and weights are not the same length!");
        require(_assetManager != address(0x0), "Rewards asset manager cannot be null");
        require(IRewardsAssetManager(_assetManager).getToken() == _token, "Rewards asset manager must be for the same token as this.");

        // Can't use the internal method here because it reads token(), which is an immutable var - immutable vars cannot be read in the constructor
        assetManager = _assetManager;
        token = _token;

        _setBufferWeight(_bufferWeight);
        _setContractAdminRole(keccak256("AGGREGATOR_ADMIN_ROLE"));

        for (uint256 i=0; i < _initialPCVDepositAddresses.length; i++) {
            require(IPCVDeposit(_initialPCVDepositAddresses[i]).balanceReportedIn() == _token, "Deposit token must be the same as for this aggregator.");
            _addPCVDeposit(_initialPCVDepositAddresses[i], _initialPCVDepositWeights[i]);
        }
    }

    // ---------- Public Functions -------------

    /// @notice deposits tokens into sub-contracts (if needed)
    /// 1. fill the buffer to maximum
    /// 2. if buffer is full and there are still tokens unallocated, calculate the optimal distribution of tokens to sub-contracts
    /// 3. distribute the tokens according the calcluations in step 2
    function deposit() external override whenNotPaused {
        // First grab the aggregator balance & the pcv deposit balances, and the sum of the pcv deposit balances
        (uint256 actualAggregatorBalance, uint256 underlyingSum, uint256[] memory underlyingBalances) = _getUnderlyingBalancesAndSum();
        uint256 totalBalance = underlyingSum + actualAggregatorBalance;

        // Optimal aggregator balance is (bufferWeight/totalWeight) * totalBalance
        uint256 optimalAggregatorBalance = bufferWeight * totalBalance / totalWeight;

        // if actual aggregator balance is below optimal, we shouldn't deposit to underlying - just "fill up the buffer"
        if (actualAggregatorBalance <= optimalAggregatorBalance) {
            return;
        }

        // we should fill up the buffer before sending out to sub-deposits
        uint256 amountAvailableForUnderlyingDeposits = optimalAggregatorBalance - actualAggregatorBalance;

        // calculate the amount that each pcv deposit needs. if they have an overage this is 0.
        uint256[] memory optimalUnderlyingBalances = _getOptimalUnderlyingBalances(totalBalance);
        uint256[] memory amountsNeeded = optimalUnderlyingBalances.positiveDifference(underlyingBalances);
        uint256 totalAmountNeeded = amountsNeeded.sum();

        // calculate a scalar. this will determine how much we *actually* send to each underlying deposit.
        Decimal.D256 memory scalar = Decimal.ratio(amountAvailableForUnderlyingDeposits, totalAmountNeeded);
        assert(scalar.asUint256() <= 1);

        for (uint256 i=0; i <underlyingBalances.length; i++) {
            // send scalar * the amount the underlying deposit needs
            uint256 amountToSend = scalar.mul(amountsNeeded[i]).asUint256();
            if (amountToSend > 0) {
                _depositToUnderlying(pcvDepositAddresses.at(i), amountToSend);
            }
        }

        emit AggregatorDeposit();
    }

    /// @notice tops up a deposit from the aggregator's balance
    /// @param pcvDeposit the address of the pcv deposit to top up
    /// @dev this will only pull from the balance that is left over after the aggregator's buffer fills up
    function depositSingle(address pcvDeposit) public override whenNotPaused {
        // First grab the aggregator balance & the pcv deposit balances, and the sum of the pcv deposit balances
        (uint256 actualAggregatorBalance, uint256 underlyingSum,) = _getUnderlyingBalancesAndSum();

        // Optimal aggregator balance is (bufferWeight/totalWeight) * totalBalance
        uint256 totalBalance = underlyingSum + actualAggregatorBalance;
        uint256 optimalAggregatorBalance = bufferWeight * totalBalance / totalWeight;

        require(actualAggregatorBalance > optimalAggregatorBalance, "No overage in aggregator to top up deposit.");

        // Calculate the overage that the aggregator has, and use the total balance to get the optimal balance of the pcv deposit
        // Then make sure it actually needs to be topped up
        uint256 aggregatorOverage = actualAggregatorBalance - optimalAggregatorBalance;
        uint256 optimalDepositBalance = _getOptimalUnderlyingBalance(totalBalance, pcvDeposit);
        uint256 actualDepositBalance = IPCVDeposit(pcvDeposit).balance();

        require(actualDepositBalance < optimalDepositBalance, "Deposit does not need topping up.");

        // If we don't have enough overage to send the whole amount, send as much as we can
        uint256 amountToSend = Math.min(optimalDepositBalance - actualDepositBalance, aggregatorOverage);

        _depositToUnderlying(pcvDeposit, amountToSend);

        emit AggregatorDepositSingle(pcvDeposit, amountToSend);
    }

    /// @notice withdraws the specified amount of tokens from the contract
    /// @dev this is equivalent to half of a rebalance. the implementation is as follows:
    /// 1. check if the contract has enough in the buffer to cover the withdrawal. if so, just use this
    /// 2. if not, calculate what the ideal underlying amount should be for each pcv deposit *after* the withdraw
    /// 3. then, cycle through them and withdraw until each has their ideal amount (for the ones that have overages)
    /// Note this function will withdraw all of the overages from each pcv deposit, even if we don't need that much to
    /// actually cover the transfer! This is intentional because it costs the same to withdraw exactly how much we need
    /// vs the overage amount; the entire overage amount should be moved if it is the same cost as just as much as we need.
    function withdraw(address to, uint256 amount) external override onlyPCVController whenNotPaused {
        uint256 aggregatorBalance = balance();

        if (aggregatorBalance >= amount) {
            IERC20(token).safeTransfer(to, amount);
            return;
        }
        
        uint256[] memory underlyingBalances = _getUnderlyingBalances();
        uint256 totalUnderlyingBalance = underlyingBalances.sum();
        uint256 totalBalance = totalUnderlyingBalance + aggregatorBalance;

        require(totalBalance >= amount, "Not enough balance to withdraw");

        // We're going to have to pull from underlying deposits
        // To avoid the need from a rebalance, we should withdraw proportionally from each deposit
        // such that at the end of this loop, each deposit has moved towards a correct weighting
        uint256 amountNeededFromUnderlying = amount - aggregatorBalance;
        uint256 totalUnderlyingBalanceAfterWithdraw = totalUnderlyingBalance - amountNeededFromUnderlying;

        // Next, calculate exactly the desired underlying balance after withdraw
        uint[] memory idealUnderlyingBalancesPostWithdraw = new uint[](pcvDepositAddresses.length());
        for (uint256 i=0; i < pcvDepositAddresses.length(); i++) {
            idealUnderlyingBalancesPostWithdraw[i] = totalUnderlyingBalanceAfterWithdraw * pcvDepositWeights[pcvDepositAddresses.at(i)] / totalWeight;
        }

        // This basically does half of a rebalance.
        // (pulls from the deposits that have > than their post-withdraw-ideal-underlying-balance)
        for (uint256 i=0; i < pcvDepositAddresses.length(); i++) {
            address pcvDepositAddress = pcvDepositAddresses.at(i);
            uint256 actualPcvDepositBalance = underlyingBalances[i];
            uint256 idealPcvDepositBalance = idealUnderlyingBalancesPostWithdraw[i];

            if (actualPcvDepositBalance > idealPcvDepositBalance) {
                // Has post-withdraw-overage; let's take it
                uint256 amountToWithdraw = actualPcvDepositBalance - idealPcvDepositBalance;
                IPCVDeposit(pcvDepositAddress).withdraw(address(this), amountToWithdraw);
            }
        }

        IERC20(token).safeTransfer(to, amount);

        emit AggregatorWithdrawal(amount);
    }

    /// @notice set the weight for the buffer specifically
    /// @param newBufferWeight the new weight for the buffer
    function setBufferWeight(uint256 newBufferWeight) external override onlyGovernorOrAdmin {
        _setBufferWeight(newBufferWeight);
    }

    /// @notice set the relative weight of a particular pcv deposit
    /// @param depositAddress the address of the PCV deposit to set the weight of
    /// @param newDepositWeight the new relative weight of the PCV deposit
    function setPCVDepositWeight(address depositAddress, uint256 newDepositWeight) external override onlyGovernorOrAdmin {
        require(pcvDepositAddresses.contains(depositAddress), "Deposit does not exist.");

        uint256 oldDepositWeight = pcvDepositWeights[depositAddress];
        int256 difference = newDepositWeight.toInt256() - oldDepositWeight.toInt256();
        pcvDepositWeights[depositAddress] = newDepositWeight;

        totalWeight = (totalWeight.toInt256() + difference).toUint256();

        emit DepositWeightUpdate(depositAddress, oldDepositWeight, newDepositWeight);
    }

    /// @notice sets the weight of a pcv deposit to zero
    /// @param depositAddress the address of the pcv deposit to set the weight of to zero
    function setPCVDepositWeightZero(address depositAddress) external override onlyGuardianOrGovernor {
        require(pcvDepositAddresses.contains(depositAddress), "Deposit does not exist.");

        uint256 oldDepositWeight = pcvDepositWeights[depositAddress];
        pcvDepositWeights[depositAddress] = 0;

        totalWeight = totalWeight - oldDepositWeight;

        emit DepositWeightUpdate(depositAddress, oldDepositWeight, 0);
    }

    /// @notice remove a PCV deposit from the set of deposits
    /// @param pcvDeposit the address of the PCV deposit to remove
    /// @param shouldWithdraw whether or not we want to withdraw from the pcv deposit before removing
    function removePCVDeposit(address pcvDeposit, bool shouldWithdraw) external override onlyGovernorOrAdmin {
        _removePCVDeposit(address(pcvDeposit), shouldWithdraw);
    }

    /// @notice adds a new PCV Deposit to the set of deposits
    /// @param weight a relative (i.e. not normalized) weight of this PCV deposit
    /// @dev the require check here is not in the internal method because the token var (as an immutable var) cannot be read in the constructor
    function addPCVDeposit(address newPCVDeposit, uint256 weight) external override onlyGovernorOrAdmin {
        require(IPCVDeposit(newPCVDeposit).balanceReportedIn() == token, "Deposit token must be the same as for this aggregator.");

        _addPCVDeposit(newPCVDeposit, weight);
    }

    /// @notice replaces this contract with a new PCV Deposit Aggregator on the rewardsAssetManager
    /// @param newAggregator the address of the new PCV Deposit Aggregator
    function setNewAggregator(address newAggregator) external override onlyGovernor {
        require(PCVDepositAggregator(newAggregator).token() == token, "New aggregator must be for the same token as the existing.");

        // Send old aggregator assets over to the new aggregator
        IERC20(token).safeTransfer(newAggregator, balance());

        // No need to remove all deposits, this is a lot of extra gas.

        // Finally, set the new aggregator on the rewards asset manager itself
        IRewardsAssetManager(assetManager).setNewAggregator(newAggregator);

        emit AggregatorUpdate(address(this), newAggregator);
    }

    /// @notice sets the rewards asset manager
    /// @param newAssetManager the address of the new rewards asset manager
    function setAssetManager(address newAssetManager) external override onlyGovernor {
        _setAssetManager(newAssetManager);
    }

    // ---------- View Functions ---------------

    /// @notice returns true if the given address is a PCV Deposit in this aggregator
    /// @param pcvDeposit the address of the PCV deposit to check
    /// @return true if the given address is a PCV Deposit in this aggregator
    function hasPCVDeposit(address pcvDeposit) public view override returns (bool) {
        return pcvDepositAddresses.contains(pcvDeposit);
    }

    /// @notice returns the contract's resistant balance and fei
    function resistantBalanceAndFei() public view override returns (uint256, uint256) {
        return (balance(), 0);
    }

    /// @notice returns the address of the token that this contract holds
    function balanceReportedIn() external view override returns (address) {
        return token;
    }

    /// @notice returns the balance of the aggregator
    /// @dev if you want the total balance of the aggregator and deposits, use getTotalBalance()
    function balance() public view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice current percent of PCV held by the input `pcvDeposit` relative to the total managed by aggregator.
    /// @param pcvDeposit the address of the pcvDeposit
    /// @param depositAmount a hypothetical deposit amount, to be included in the calculation
    /// @return the percent held as a Decimal D256 value
    function percentHeld(address pcvDeposit, uint256 depositAmount) external view override returns(Decimal.D256 memory) {
        uint256 totalBalanceWithTheoreticalDeposit = getTotalBalance() + depositAmount;
        uint256 targetBalanceWithTheoreticalDeposit = IPCVDeposit(pcvDeposit).balance() + depositAmount;

        return Decimal.ratio(targetBalanceWithTheoreticalDeposit, totalBalanceWithTheoreticalDeposit);
    }

    /// @notice the normalized target weight of PCV held by `pcvDeposit` relative to aggregator total
    /// @param pcvDeposit the address of the pcvDeposit
    /// @return the normalized target percent held as a Decimal D256 value
    function normalizedTargetWeight(address pcvDeposit) public view override returns(Decimal.D256 memory) {
        return Decimal.ratio(pcvDepositWeights[pcvDeposit], totalWeight);
    }

    /// @notice the raw amount of PCV off of the target weight/percent held by `pcvDeposit`
    /// @dev a positive result means the target has "too much" pcv, and a negative result means it needs more pcv
    /// @param pcvDeposit the address of the pcvDeposit
    /// @return the amount from target as an int
    function amountFromTarget(address pcvDeposit) public view override returns(int256) {
        uint256 totalBalance = getTotalBalance();

        uint256 pcvDepositBalance = IPCVDeposit(pcvDeposit).balance();
        uint256 pcvDepositWeight = pcvDepositWeights[address(pcvDeposit)];

        uint256 idealDepositBalance = pcvDepositWeight * totalBalance / totalWeight;
        
        return (pcvDepositBalance).toInt256() - (idealDepositBalance).toInt256();
    }

    /// @notice the same as amountFromTarget, but for every targets
    /// @return distancesToTargets all amounts from targets as a uint256 array
    function getAllAmountsFromTargets() public view override returns(int256[] memory distancesToTargets) {
        (uint256 aggregatorBalance, uint256 underlyingSum, uint256[] memory underlyingBalances) = _getUnderlyingBalancesAndSum();
        uint256 totalBalance = aggregatorBalance + underlyingSum;

        distancesToTargets = new int256[](pcvDepositAddresses.length());

        for (uint256 i=0; i < distancesToTargets.length; i++) {
            uint256 idealAmount = totalBalance * pcvDepositWeights[pcvDepositAddresses.at(i)] / totalWeight;
            distancesToTargets[i] = (idealAmount).toInt256() - (underlyingBalances[i]).toInt256();
        }

        return distancesToTargets;
    }

    /// @notice the set of PCV deposits and non-normalized weights this contract allocates to\
    /// @return deposits addresses and weights as uints
    function pcvDeposits() external view override returns(address[] memory deposits, uint256[] memory weights) {
        deposits = new address[](pcvDepositAddresses.length());
        weights = new uint256[](pcvDepositAddresses.length());

        for (uint256 i=0; i < pcvDepositAddresses.length(); i++) {
            deposits[i] = pcvDepositAddresses.at(i);
            weights[i] = pcvDepositWeights[pcvDepositAddresses.at(i)];
        }

        return (deposits, weights);
    }

    /// @notice returns the summation of all pcv deposit balances + the aggregator's balance
    /// @return the total amount of pcv held by the aggregator and the pcv deposits
    function getTotalBalance() public view override returns (uint256) {
        return _getUnderlyingBalances().sum() + balance();
    }

    /// @notice returns the summation of all pcv deposit's resistant balance & fei
    /// @return the resistant balance and fei as uints
    function getTotalResistantBalanceAndFei() external view override returns (uint256, uint256) {
        uint256 totalResistantBalance = 0;
        uint256 totalResistantFei = 0;

        for (uint256 i=0; i<pcvDepositAddresses.length(); i++) {
            (uint256 resistantBalance, uint256 resistantFei) = IPCVDeposit(pcvDepositAddresses.at(i)).resistantBalanceAndFei();

            totalResistantBalance += resistantBalance;
            totalResistantFei += resistantFei;
        }

        // Let's not forget to get this balance
        totalResistantBalance += balance();

        // There's no Fei to add

        return (totalResistantBalance, totalResistantFei);
    }

    // ---------- Internal Functions ----------- //

    // Sets the asset manager
    function _setAssetManager(address newAssetManager) internal {
        require(newAssetManager != address(0x0), "New asset manager cannot be 0x0");
        require(IRewardsAssetManager(newAssetManager).getToken() == token, "New asset manager must be for the same token as the existing.");

        address oldAssetManager = assetManager;
        assetManager = newAssetManager;

        emit AssetManagerUpdate(oldAssetManager, newAssetManager);
    }

    // Sets the buffer weight and updates the total weight
    function _setBufferWeight(uint256 newBufferWeight) internal {
        int256 difference = newBufferWeight.toInt256() - bufferWeight.toInt256();
        uint256 oldBufferWeight = bufferWeight;
        bufferWeight = newBufferWeight;

        totalWeight = (totalWeight.toInt256() + difference).toUint256();

        emit BufferWeightUpdate(oldBufferWeight, newBufferWeight);
    }

    // Sums the underlying deposit balances, returns the sum, the balances, and the aggregator balance
    function _getUnderlyingBalancesAndSum() internal view returns (uint256 aggregatorBalance, uint256 depositSum, uint[] memory depositBalances) {
        uint[] memory underlyingBalances = _getUnderlyingBalances();
        return (balance(), underlyingBalances.sum(), underlyingBalances);
    }

    // Transfers amount to to and calls deposit on the underlying pcv deposit
    function _depositToUnderlying(address to, uint256 amount) internal {
        IERC20(token).transfer(to, amount);
        IPCVDeposit(to).deposit();
    }

    // Uses the weights, the total weight, and the total balance to calculate the optimal underlying pcv deposit balances
    function _getOptimalUnderlyingBalances(uint256 totalBalance) internal view returns (uint[] memory optimalUnderlyingBalances) {
        optimalUnderlyingBalances = new uint[](pcvDepositAddresses.length());

        for (uint256 i=0; i<optimalUnderlyingBalances.length; i++) {
            optimalUnderlyingBalances[i] = pcvDepositWeights[pcvDepositAddresses.at(i)] * totalBalance / totalWeight;
        }

        return optimalUnderlyingBalances;
    }

    // Optimized version of _getOptimalUnderlyingBalances for a single deposit
    function _getOptimalUnderlyingBalance(uint256 totalBalance, address pcvDeposit) internal view returns (uint256 optimalUnderlyingBalance) {
        return pcvDepositWeights[pcvDeposit] * totalBalance / totalWeight;
    }

    // Cycles through the underlying pcv deposits and gets their balances
    function _getUnderlyingBalances() internal view returns (uint[] memory) {
        uint[] memory balances = new uint[](pcvDepositAddresses.length());

        for (uint256 i=0; i<pcvDepositAddresses.length(); i++) {
            balances[i] = IPCVDeposit(pcvDepositAddresses.at(i)).balance();
        }

        return balances;
    }

    // Adds a pcv deposit if not already added
    function _addPCVDeposit(address depositAddress, uint256 weight) internal {
        require(!pcvDepositAddresses.contains(depositAddress), "Deposit already added.");

        pcvDepositAddresses.add(depositAddress);
        pcvDepositWeights[depositAddress] = weight;

        totalWeight = totalWeight + weight;

        emit DepositAdded(depositAddress, weight);
    }

    // Removes a pcv deposit if it exists
    function _removePCVDeposit(address depositAddress, bool shouldWithdraw) internal {
        require(pcvDepositAddresses.contains(depositAddress), "Deposit does not exist.");

        // Set the PCV Deposit weight to 0
        totalWeight = totalWeight - pcvDepositWeights[depositAddress];
        pcvDepositWeights[depositAddress] = 0;

        pcvDepositAddresses.remove(depositAddress);

        if (shouldWithdraw) {
            uint depositBalance = IPCVDeposit(depositAddress).balance();
            IPCVDeposit(depositAddress).withdraw(address(this), depositBalance);
        }

        emit DepositRemoved(depositAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../IPCVDepositAggregator.sol";

/**
@title IRewardsAssetManager
@author Fei Protocol

interface intended to extend the balancer RewardsAssetManager
https://github.com/balancer-labs/balancer-v2-monorepo/blob/389b52f1fc9e468de854810ce9dc3251d2d5b212/pkg/asset-manager-utils/contracts/RewardsAssetManager.sol

This contract will essentially pass-through funds to an IPCVDepositAggregator denominated in the same underlying asset
*/
interface IRewardsAssetManager {
    // ----------- Governor only state changing api -----------
    function setNewAggregator(address newAggregator) external;

    // ----------- Read-only api -----------
    function pcvDepositAggregator() external returns(address);
    function getToken() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library UintArrayOps {
    using SafeCast for uint256;

    function sum(uint[] memory array) internal pure returns (uint256 _sum) {
        for (uint256 i=0; i < array.length; i++) {
            _sum += array[i];
        }

        return _sum;
    }

    function signedDifference(uint256[] memory a, uint256[] memory b) internal pure returns (int256[] memory _difference) {
        require(a.length == b.length, "Arrays must be the same length");

        _difference = new int256[](a.length);

        for (uint256 i=0; i < a.length; i++) {
            _difference[i] = a[i].toInt256() - b[i].toInt256();
        }

        return _difference;
    }

    /// @dev given two int arrays a & b, returns an array c such that c[i] = a[i] - b[i], with negative values truncated to 0
    function positiveDifference(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory _positiveDifference) {
        require(a.length == b.length,  "Arrays must be the same length");

        _positiveDifference = new uint256[](a.length);

        for (uint256 i=0; i < a.length; i++) {
            if (a[i] > b[i]) {
                _positiveDifference[i] = a[i] - b[i];
            }
        }

        return _positiveDifference;
    }
}

pragma solidity ^0.8.4;

import "../IPCVDepositBalances.sol";
import "../../Constants.sol";
import "../../refs/CoreRef.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
  @notice a contract to report static PCV data to cover PCV not held with a reliable oracle or on-chain reading 
  @author Fei Protocol

  Returns PCV in USD terms
*/
contract NamedStaticPCVDepositWrapper is IPCVDepositBalances, CoreRef {
    using SafeCast for *;

    // -------------- Events ---------------
    /// @notice event to update fei and usd balance
    event BalanceUpdate(uint256 oldBalance, uint256 newBalance, uint256 oldFEIBalance, uint256 newFEIBalance);

    /// @notice event to remove a deposit
    event DepositRemoved(uint256 index);
    
    /// @notice event to add a new deposit
    event DepositAdded(uint256 index, string indexed depositName);

    /// @notice event emitted when a deposit is edited
    event DepositChanged(uint256 index, string indexed depositName);

    /// @notice struct to store info on each PCV Deposit
    struct DepositInfo {
        string depositName;
        uint256 usdAmount; /// USD equivalent in this deposit, not including FEI value
        uint256 feiAmount; /// amount of FEI in this deposit
        uint256 underlyingTokenAmount; /// amount of underlying token in this deposit
        address underlyingToken; /// address of the underlying token this deposit is reporting
    }

    /// @notice a list of all pcv deposits
    DepositInfo[] public pcvDeposits;

    /// @notice the PCV balance
    uint256 public override balance;

    /// @notice the reported FEI balance to track protocol controlled FEI in these deposits
    uint256 public feiReportBalance;

    constructor(address _core, DepositInfo[] memory newPCVDeposits) CoreRef(_core) {

        // Uses oracle admin to share admin with CR oracle where this contract is used
        _setContractAdminRole(keccak256("ORACLE_ADMIN_ROLE"));

        // add all pcv deposits
        for (uint256 i = 0; i < newPCVDeposits.length; i++) {
            _addDeposit(newPCVDeposits[i]);
        }
    }

    // ----------- Helper methods to change state -----------

    /// @notice helper method to add a PCV deposit
    function _addDeposit(DepositInfo memory newPCVDeposit) internal {
        require(newPCVDeposit.feiAmount > 0 || newPCVDeposit.usdAmount > 0, "NamedStaticPCVDepositWrapper: must supply either fei or usd amount");

        uint256 oldBalance = balance;
        uint256 oldFEIBalance = feiReportBalance;

        balance += newPCVDeposit.usdAmount;
        feiReportBalance += newPCVDeposit.feiAmount;
        pcvDeposits.push(newPCVDeposit);

        emit DepositAdded(pcvDeposits.length - 1, newPCVDeposit.depositName);
        emit BalanceUpdate(oldBalance, balance, oldFEIBalance, feiReportBalance);
    }

    /// @notice helper method to edit a PCV deposit
    function _editDeposit(
        uint256 index,
        string calldata depositName,
        uint256 usdAmount,
        uint256 feiAmount,
        uint256 underlyingTokenAmount,
        address underlyingToken
    ) internal {
        require(index < pcvDeposits.length, "NamedStaticPCVDepositWrapper: cannot edit index out of bounds");

        DepositInfo storage updatePCVDeposit = pcvDeposits[index];

        uint256 oldBalance = balance;
        uint256 oldFEIBalance = feiReportBalance;
        uint256 newBalance = oldBalance - updatePCVDeposit.usdAmount + usdAmount;
        uint256 newFeiReportBalance = oldFEIBalance - updatePCVDeposit.feiAmount + feiAmount;

        balance = newBalance;
        feiReportBalance = newFeiReportBalance;

        updatePCVDeposit.usdAmount = usdAmount;
        updatePCVDeposit.feiAmount = feiAmount;
        updatePCVDeposit.depositName = depositName;
        updatePCVDeposit.underlyingTokenAmount = underlyingTokenAmount;
        updatePCVDeposit.underlyingToken = underlyingToken;

        emit DepositChanged(index, depositName);
        emit BalanceUpdate(oldBalance, newBalance, oldFEIBalance, newFeiReportBalance);
    }

    /// @notice helper method to delete a PCV deposit
    function _removeDeposit(uint256 index) internal {
        require(index < pcvDeposits.length, "NamedStaticPCVDepositWrapper: cannot remove index out of bounds");

        DepositInfo storage pcvDepositToRemove = pcvDeposits[index];

        uint256 depositBalance = pcvDepositToRemove.usdAmount;
        uint256 feiDepositBalance = pcvDepositToRemove.feiAmount;
        uint256 oldBalance = balance;
        uint256 oldFeiReportBalance = feiReportBalance;
        uint256 lastIndex = pcvDeposits.length - 1;

        if (lastIndex != index) {
            DepositInfo storage lastvalue = pcvDeposits[lastIndex];

            pcvDeposits[index] = lastvalue;
        }

        pcvDeposits.pop();
        balance -= depositBalance;
        feiReportBalance -= feiDepositBalance;

        emit BalanceUpdate(oldBalance, balance, oldFeiReportBalance, feiReportBalance);
        emit DepositRemoved(index);
    }

    // ----------- Governor only state changing api -----------

    /// @notice function to add a deposit
    function addDeposit(
        DepositInfo calldata newPCVDeposit
    ) external onlyGovernorOrAdmin {
        _addDeposit(newPCVDeposit);
    }

    /// @notice function to bulk add deposits
    function bulkAddDeposits(
        DepositInfo[] calldata newPCVDeposits
    ) external onlyGovernorOrAdmin {
        for (uint256 i = 0; i < newPCVDeposits.length; i++) {
            _addDeposit(newPCVDeposits[i]);
        }
    }


    /// @notice function to remove a PCV Deposit
    function removeDeposit(uint256 index) external isGovernorOrGuardianOrAdmin {
        _removeDeposit(index);
    }

    /// @notice function to edit an existing deposit
    function editDeposit(
        uint256 index,
        uint256 usdAmount,
        uint256 feiAmount,
        uint256 underlyingTokenAmount,
        string calldata depositName,
        address underlying
    ) external onlyGovernorOrAdmin {
        _editDeposit(
            index,
            depositName,
            usdAmount,
            feiAmount,
            underlyingTokenAmount,
            underlying
        );
    }

    // ----------- Getters -----------

    /// @notice returns the current number of PCV deposits
    function numDeposits() public view returns (uint256) {
        return pcvDeposits.length;
    }

    /// @notice returns the resistant balance and FEI in the deposit
    function resistantBalanceAndFei() public view override returns (uint256, uint256) {
        return (balance, feiReportBalance);
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public pure override returns (address) {
        return Constants.USD;
    }
    
    /// @notice function to return all of the different tokens deposited into this contract
    function getAllUnderlying() public view returns (address[] memory) {
        uint256 totalDeposits = numDeposits();

        address[] memory allUnderlyingTokens = new address[](totalDeposits);
        for (uint256 i = 0; i < totalDeposits; i++) {
            allUnderlyingTokens[i] = pcvDeposits[i].underlyingToken;
        }

        return allUnderlyingTokens;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../../Constants.sol";
import "../../refs/CoreRef.sol";
import "../IPCVDeposit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title a PCV controller for moving a ratio of the total value in the PCV deposit
/// @author Fei Protocol
/// @notice v2 includes methods for transferring approved ERC20 balances and wrapping and unwrapping WETH in transit
contract RatioPCVControllerV2 is CoreRef {
    using SafeERC20 for IERC20;

    /// @notice PCV controller constructor
    /// @param _core Fei Core for reference
    constructor(
        address _core
    ) CoreRef(_core) {}

    receive() external payable {}

    /// @notice withdraw tokens from the input PCV deposit in basis points terms
    /// @param pcvDeposit PCV deposit to withdraw from
    /// @param to the address to send PCV to
    /// @param basisPoints ratio of PCV to withdraw in basis points terms (1/10000)
    function withdrawRatio(IPCVDeposit pcvDeposit, address to, uint256 basisPoints)
        public
        onlyPCVController
        whenNotPaused
    {
        _withdrawRatio(pcvDeposit, to, basisPoints);
    }

    /// @notice withdraw WETH from the input PCV deposit in basis points terms and send as ETH
    /// @param pcvDeposit PCV deposit to withdraw from
    /// @param to the address to send PCV to
    /// @param basisPoints ratio of PCV to withdraw in basis points terms (1/10000)
    function withdrawRatioUnwrapWETH(IPCVDeposit pcvDeposit, address payable to, uint256 basisPoints)
        public
        onlyPCVController
        whenNotPaused
    {
        uint256 amount = _withdrawRatio(pcvDeposit, address(this), basisPoints);
        _transferWETHAsETH(to, amount);
    }

    /// @notice withdraw ETH from the input PCV deposit in basis points terms and send as WETH
    /// @param pcvDeposit PCV deposit to withdraw from
    /// @param to the address to send PCV to
    /// @param basisPoints ratio of PCV to withdraw in basis points terms (1/10000)
    function withdrawRatioWrapETH(IPCVDeposit pcvDeposit, address to, uint256 basisPoints)
        public
        onlyPCVController
        whenNotPaused
    {
        uint256 amount = _withdrawRatio(pcvDeposit, address(this), basisPoints);
        _transferETHAsWETH(to, amount);
    }

    /// @notice withdraw WETH from the input PCV deposit and send as ETH
    /// @param pcvDeposit PCV deposit to withdraw from
    /// @param to the address to send PCV to
    /// @param amount raw amount of PCV to withdraw
    function withdrawUnwrapWETH(IPCVDeposit pcvDeposit, address payable to, uint256 amount)
        public
        onlyPCVController
        whenNotPaused
    {
        pcvDeposit.withdraw(address(this), amount);
        _transferWETHAsETH(to, amount);
    }

    /// @notice withdraw ETH from the input PCV deposit and send as WETH
    /// @param pcvDeposit PCV deposit to withdraw from
    /// @param to the address to send PCV to
    /// @param amount raw amount of PCV to withdraw
    function withdrawWrapETH(IPCVDeposit pcvDeposit, address to, uint256 amount)
        public
        onlyPCVController
        whenNotPaused
    {
        pcvDeposit.withdraw(address(this), amount);
        _transferETHAsWETH(to, amount);
    }

    /// @notice withdraw a specific ERC20 token from the input PCV deposit in basis points terms
    /// @param pcvDeposit PCV deposit to withdraw from
    /// @param token the ERC20 token to withdraw
    /// @param to the address to send tokens to
    /// @param basisPoints ratio of PCV to withdraw in basis points terms (1/10000)
    function withdrawRatioERC20(IPCVDeposit pcvDeposit, address token, address to, uint256 basisPoints)
        public
        onlyPCVController
        whenNotPaused
    {
        require(basisPoints <= Constants.BASIS_POINTS_GRANULARITY, "RatioPCVController: basisPoints too high");
        uint256 amount = IERC20(token).balanceOf(address(pcvDeposit)) * basisPoints / Constants.BASIS_POINTS_GRANULARITY;
        require(amount != 0, "RatioPCVController: no value to withdraw");

        pcvDeposit.withdrawERC20(token, to, amount);
    }

    /// @notice transfer a specific ERC20 token from the input PCV deposit in basis points terms
    /// @param from address to withdraw from
    /// @param token the ERC20 token to withdraw
    /// @param to the address to send tokens to
    /// @param basisPoints ratio of PCV to withdraw in basis points terms (1/10000)
    function transferFromRatio(address from, IERC20 token, address to, uint256 basisPoints)
        public
        onlyPCVController
        whenNotPaused
    {
        require(basisPoints <= Constants.BASIS_POINTS_GRANULARITY, "RatioPCVController: basisPoints too high");
        uint256 amount = token.balanceOf(address(from)) * basisPoints / Constants.BASIS_POINTS_GRANULARITY;
        require(amount != 0, "RatioPCVController: no value to transfer");

        token.safeTransferFrom(from, to, amount);
    }

    /// @notice transfer a specific ERC20 token from the input PCV deposit
    /// @param from address to withdraw from
    /// @param token the ERC20 token to withdraw
    /// @param to the address to send tokens to
    /// @param amount of tokens to transfer
    function transferFrom(address from, IERC20 token, address to, uint256 amount)
        public
        onlyPCVController
        whenNotPaused
    {
        require(amount != 0, "RatioPCVController: no value to transfer");

        token.safeTransferFrom(from, to, amount);
    }

    /// @notice send ETH as WETH
    /// @param to destination
    function transferETHAsWETH(address to)
        public
        onlyPCVController
        whenNotPaused
    {
        _transferETHAsWETH(to, address(this).balance);
    }

    /// @notice send WETH as ETH
    /// @param to destination
    function transferWETHAsETH(address payable to)
        public
        onlyPCVController
        whenNotPaused
    {
        _transferWETHAsETH(to, IERC20(address(Constants.WETH)).balanceOf(address(this)));
    }

    /// @notice send away ERC20 held on this contract, to avoid having any stuck.
    /// @param token sent
    /// @param to destination
    function transferERC20(IERC20 token, address to)
        public
        onlyPCVController
        whenNotPaused
    {
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(to, amount);
    }

    function _withdrawRatio(IPCVDeposit pcvDeposit, address to, uint256 basisPoints) internal returns (uint256) {
        require(basisPoints <= Constants.BASIS_POINTS_GRANULARITY, "RatioPCVController: basisPoints too high");
        uint256 amount = pcvDeposit.balance() * basisPoints / Constants.BASIS_POINTS_GRANULARITY;
        require(amount != 0, "RatioPCVController: no value to withdraw");

        pcvDeposit.withdraw(to, amount);

        return amount;
    }

    function _transferETHAsWETH(address to, uint256 amount) internal {
        Constants.WETH.deposit{value: amount}();

        Constants.WETH.transfer(to, amount);
    }

    function _transferWETHAsETH(address payable to, uint256 amount) internal {
        Constants.WETH.withdraw(amount);

        Address.sendValue(to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../IPCVDeposit.sol";

/// @title a PCV dripping controller interface
/// @author Fei Protocol
interface IPCVDripController {
    // ----------- Events -----------

    event SourceUpdate (address indexed oldSource, address indexed newSource);
    event TargetUpdate (address indexed oldTarget, address indexed newTarget);
    event DripAmountUpdate (uint256 oldDripAmount, uint256 newDripAmount);
    event Dripped (address indexed source, address indexed target, uint256 amount);

    // ----------- Governor only state changing api -----------

    function setSource(IPCVDeposit newSource) external;

    function setTarget(IPCVDeposit newTarget) external;

    function setDripAmount(uint256 newDripAmount) external;

    // ----------- Public state changing api -----------

    function drip() external;

    // ----------- Getters -----------

    function source() external view returns (IPCVDeposit);

    function target() external view returns (IPCVDeposit);

    function dripAmount() external view returns (uint256);

    function dripEligible() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../IPCVDeposit.sol"; 
import "../../refs/CoreRef.sol";

/// @title a contract to skim excess FEI from addresses
/// @author Fei Protocol
contract FeiSkimmer is CoreRef {
 
    event ThresholdUpdate(uint256 newThreshold);

    /// @notice source PCV deposit to skim excess FEI from
    IPCVDeposit public immutable source;

    /// @notice the threshold of FEI above which to skim
    uint256 public threshold;

    /// @notice FEI Skimmer
    /// @param _core Fei Core for reference
    /// @param _source the target to skim from
    /// @param _threshold the threshold of FEI to be maintained by source
    constructor(
        address _core,
        IPCVDeposit _source,
        uint256 _threshold
    ) 
        CoreRef(_core)
    {
        source = _source;
        threshold = _threshold;
        emit ThresholdUpdate(threshold);
    }

    /// @return true if FEI balance of source exceeds threshold
    function skimEligible() external view returns (bool) {
        return fei().balanceOf(address(source)) > threshold;
    }

    /// @notice skim FEI above the threshold from the source. Pausable. Requires skimEligible()
    function skim()
        external
        whenNotPaused
    {
        IFei _fei = fei();
        uint256 feiTotal = _fei.balanceOf(address(source));

        require(feiTotal > threshold, "under threshold");
        
        uint256 burnAmount = feiTotal - threshold;
        source.withdrawERC20(address(_fei), address(this), burnAmount);

        _fei.burn(burnAmount);
    }
    
    /// @notice set the threshold for FEI skims. Only Governor or Admin
    /// @param newThreshold the new value above which FEI is skimmed.
    function setThreshold(uint256 newThreshold) external onlyGovernorOrAdmin {
        threshold = newThreshold;
        emit ThresholdUpdate(newThreshold);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../../refs/CoreRef.sol";
import "../../Constants.sol";

/// @title abstract contract for splitting PCV into different deposits
/// @author Fei Protocol
abstract contract PCVSplitter is CoreRef {

    uint256[] private ratios;
    address[] private pcvDeposits;

    event AllocationUpdate(address[] oldPCVDeposits, uint256[] oldRatios, address[] newPCVDeposits, uint256[] newRatios);
    event Allocate(address indexed caller, uint256 amount);

    /// @notice PCVSplitter constructor
    /// @param _pcvDeposits list of PCV Deposits to split to
    /// @param _ratios ratios for splitting PCV Deposit allocations
    constructor(address[] memory _pcvDeposits, uint256[] memory _ratios) {
        _setAllocation(_pcvDeposits, _ratios);
    }

    /// @notice make sure an allocation has matching lengths and totals the ALLOCATION_GRANULARITY
    /// @param _pcvDeposits new list of pcv deposits to send to
    /// @param _ratios new ratios corresponding to the PCV deposits
    function checkAllocation(
        address[] memory _pcvDeposits,
        uint256[] memory _ratios
    ) public pure {
        require(
            _pcvDeposits.length == _ratios.length,
            "PCVSplitter: PCV Deposits and ratios are different lengths"
        );

        uint256 total;
        for (uint256 i; i < _ratios.length; i++) {
            total = total + _ratios[i];
        }

        require(
            total == Constants.BASIS_POINTS_GRANULARITY,
            "PCVSplitter: ratios do not total 100%"
        );
    }

    /// @notice gets the pcvDeposits and ratios of the splitter
    function getAllocation()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (pcvDeposits, ratios);
    }

    /// @notice sets the allocation of held PCV
    function setAllocation(
        address[] calldata _allocations,
        uint256[] calldata _ratios
    ) external onlyGovernorOrAdmin {
        _setAllocation(_allocations, _ratios);
    }

    /// @notice distribute funds to single PCV deposit
    /// @param amount amount of funds to send
    /// @param pcvDeposit the pcv deposit to send funds
    function _allocateSingle(uint256 amount, address pcvDeposit)
        internal
        virtual;

    /// @notice sets a new allocation for the splitter
    /// @param _pcvDeposits new list of pcv deposits to send to
    /// @param _ratios new ratios corresponding to the PCV deposits. Must total ALLOCATION_GRANULARITY
    function _setAllocation(
        address[] memory _pcvDeposits,
        uint256[] memory _ratios
    ) internal {
        address[] memory _oldPCVDeposits = pcvDeposits;
        uint256[] memory _oldRatios = ratios;

        checkAllocation(_pcvDeposits, _ratios);

        pcvDeposits = _pcvDeposits;
        ratios = _ratios;

        emit AllocationUpdate(_oldPCVDeposits, _oldRatios, _pcvDeposits, _ratios);
    }

    /// @notice distribute funds to all pcv deposits at specified allocation ratios
    /// @param total amount of funds to send
    function _allocate(uint256 total) internal {
        uint256 granularity = Constants.BASIS_POINTS_GRANULARITY;
        for (uint256 i; i < ratios.length; i++) {
            uint256 amount = total * ratios[i] / granularity;
            _allocateSingle(amount, pcvDeposits[i]);
        }
        emit Allocate(msg.sender, total);
    }
}

pragma solidity ^0.8.0;

import "./PCVSplitter.sol";

/// @title ERC20Splitter
/// @notice a contract to split token held to multiple locations
contract ERC20Splitter is PCVSplitter {

    /// @notice token to split
    IERC20 public token;

    /**
        @notice constructor for ERC20Splitter
        @param _core the Core address to reference
        @param _token the ERC20 token instance to split
        @param _pcvDeposits the locations to send tokens
        @param _ratios the relative ratios of how much tokens to send each location, in basis points
    */
    constructor(
        address _core,
        IERC20 _token,
        address[] memory _pcvDeposits,
        uint256[] memory _ratios
    ) 
        CoreRef(_core)
        PCVSplitter(_pcvDeposits, _ratios)
    {
        token = _token;
    }

    /// @notice distribute held TRIBE
    function allocate() external whenNotPaused {
        _allocate(token.balanceOf(address(this)));
    }

    function _allocateSingle(uint256 amount, address pcvDeposit) internal override {
        token.transfer(pcvDeposit, amount);        
    }
}

pragma solidity ^0.8.4;

import "../IPCVDepositBalances.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
  @notice a lightweight contract to wrap ERC20 holding PCV contracts
  @author Fei Protocol
  When upgrading the PCVDeposit interface, there are many old contracts which do not support it.
  The main use case for the new interface is to add read methods for the Collateralization Oracle.
  Most PCVDeposits resistant balance method is simply returning the balance as a pass-through
  If the PCVDeposit holds FEI it may be considered as protocol FEI

  This wrapper can be used in the CR oracle which reduces the number of contract upgrades and reduces the complexity and risk of the upgrade
*/
contract ERC20PCVDepositWrapper is IPCVDepositBalances {
    
    /// @notice the referenced token deposit
    address public tokenDeposit;

    /// @notice the balance reported in token
    IERC20 public token;

    /// @notice a flag for whether to report the balance as protocol owned FEI
    bool public isProtocolFeiDeposit;

    constructor(address _tokenDeposit, IERC20 _token, bool _isProtocolFeiDeposit) {
        tokenDeposit = _tokenDeposit;
        token = _token;
        isProtocolFeiDeposit = _isProtocolFeiDeposit;
    }

    /// @notice returns total balance of PCV in the Deposit
    function balance() public view override returns (uint256) {
        return token.balanceOf(tokenDeposit);
    }

    /// @notice returns the resistant balance and FEI in the deposit
    function resistantBalanceAndFei() public view override returns (uint256, uint256) {
        uint256 resistantBalance = balance();
        uint256 reistantFei = isProtocolFeiDeposit ? resistantBalance : 0;
        return (resistantBalance, reistantFei);
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return address(token);
    }
}

pragma solidity ^0.8.4;

import "../IPCVDepositBalances.sol";

/**
  @notice a lightweight contract to wrap old PCV deposits to use the new interface 
  @author Fei Protocol
  When upgrading the PCVDeposit interface, there are many old contracts which do not support it.
  The main use case for the new interface is to add read methods for the Collateralization Oracle.
  Most PCVDeposits resistant balance method is simply returning the balance as a pass-through
  If the PCVDeposit holds FEI it may be considered as protocol FEI

  This wrapper can be used in the CR oracle which reduces the number of contract upgrades and reduces the complexity and risk of the upgrade
*/
contract PCVDepositWrapper is IPCVDepositBalances {
   
    /// @notice the referenced PCV Deposit
    IPCVDepositBalances public pcvDeposit;

    /// @notice the balance reported in token
    address public token;

    /// @notice a flag for whether to report the balance as protocol owned FEI
    bool public isProtocolFeiDeposit;

    constructor(IPCVDepositBalances _pcvDeposit, address _token, bool _isProtocolFeiDeposit) {
        pcvDeposit = _pcvDeposit;
        token = _token;
        isProtocolFeiDeposit = _isProtocolFeiDeposit;
    }

    /// @notice returns total balance of PCV in the Deposit
    function balance() public view override returns (uint256) {
        return pcvDeposit.balance();
    }

    /// @notice returns the resistant balance and FEI in the deposit
    function resistantBalanceAndFei() public view override returns (uint256, uint256) {
        uint256 resistantBalance = balance();
        uint256 reistantFei = isProtocolFeiDeposit ? resistantBalance : 0;
        return (resistantBalance, reistantFei);
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return token;
    }
}

pragma solidity ^0.8.4;

import "./../PCVDeposit.sol";
import "./../../utils/Timed.sol";

contract ERC20Dripper is PCVDeposit, Timed {
    using Address for address payable;

    /// @notice event emitted when tokens are dripped
    event Dripped(uint256 amount);

    /// @notice target address to drip tokens to
    address public target;
    /// @notice target token address to send
    address public token;
    /// @notice amount to drip after each window
    uint256 public amountToDrip;


    /// @notice ERC20 PCV Dripper constructor
    /// @param _core Fei Core for reference
    /// @param _target address to drip to
    /// @param _frequency frequency of dripping
    /// @param _amountToDrip amount to drip on each drip
    /// @param _token amount to drip on each drip
    constructor(
        address _core,
        address _target,
        uint256 _frequency,
        uint256 _amountToDrip,
        address _token
    ) CoreRef(_core) Timed(_frequency) {
        require(_target != address(0), "ERC20Dripper: invalid address");
        require(_token != address(0), "ERC20Dripper: invalid token address");
        require(_amountToDrip > 0, "ERC20Dripper: invalid drip amount");

        target = _target;
        amountToDrip = _amountToDrip;
        token = _token;

        // start timer
        _initTimed();
    }
 
    /// @notice drip ERC20 tokens to target
    function drip()
       external
       afterTime
       whenNotPaused
    {
        // reset timer
        _initTimed();

        // drip
        _withdrawERC20(token, target, amountToDrip);
        emit Dripped(amountToDrip);
    }

    /// @notice withdraw tokens from the PCV allocation
    /// @param amountUnderlying of tokens withdrawn
    /// @param to the address to send PCV to
    function withdraw(address to, uint256 amountUnderlying)
        external
        override
        onlyPCVController
    {
        _withdrawERC20(address(token), to, amountUnderlying);
    }

    /// @notice no-op
    function deposit() external override {}

    /// @notice returns total balance of PCV in the Deposit
    function balance() public view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return token;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDripController.sol"; 
import "../../utils/Incentivized.sol"; 
import "../../fei/minter/RateLimitedMinter.sol"; 
import "../../utils/Timed.sol";

/// @title a PCV dripping controller
/// @author Fei Protocol
contract PCVDripController is IPCVDripController, Timed, RateLimitedMinter, Incentivized {
 
    /// @notice source PCV deposit to withdraw from
    IPCVDeposit public override source;

    /// @notice target address to drip to
    IPCVDeposit public override target;

    /// @notice amount to drip after each window
    uint256 public override dripAmount;

    /// @notice PCV Drip Controller constructor
    /// @param _core Fei Core for reference
    /// @param _source the PCV deposit to drip from
    /// @param _target the PCV deposit to drip to
    /// @param _frequency frequency of dripping
    /// @param _dripAmount amount to drip on each drip
    /// @param _incentiveAmount the FEI incentive for calling drip
    constructor(
        address _core,
        IPCVDeposit _source,
        IPCVDeposit _target,
        uint256 _frequency,
        uint256 _dripAmount,
        uint256 _incentiveAmount
    ) 
        CoreRef(_core) 
        Timed(_frequency) 
        Incentivized(_incentiveAmount)
        RateLimitedMinter(_incentiveAmount / _frequency, _incentiveAmount, false) 
    {
        target = _target;
        emit TargetUpdate(address(0), address(_target));

        source = _source;
        emit SourceUpdate(address(0), address(_source));

        dripAmount = _dripAmount;
        emit DripAmountUpdate(0, _dripAmount);

        // start timer
        _initTimed();
    }

    /// @notice drip PCV to target by withdrawing from source
    function drip()
        external
        override
        afterTime
        whenNotPaused
    {
        require(dripEligible(), "PCVDripController: not eligible");
        
        // reset timer
        _initTimed();

        // incentivize caller
        _incentivize();
        
        // drip
        source.withdraw(address(target), dripAmount);
        target.deposit(); // trigger any deposit logic on the target
        emit Dripped(address(source), address(target), dripAmount);
    }

    /// @notice set the new PCV Deposit source
    function setSource(IPCVDeposit newSource)
        external
        override
        onlyGovernor
    {
        require(address(newSource) != address(0), "PCVDripController: zero address");

        address oldSource = address(source);
        source = newSource;
        emit SourceUpdate(oldSource, address(newSource));
    }

    /// @notice set the new PCV Deposit target
    function setTarget(IPCVDeposit newTarget)
        external
        override
        onlyGovernor
    {
        require(address(newTarget) != address(0), "PCVDripController: zero address");

        address oldTarget = address(target);
        target = newTarget;
        emit TargetUpdate(oldTarget, address(newTarget));
    }

    /// @notice set the new drip amount
    function setDripAmount(uint256 newDripAmount)
        external
        override
        onlyGovernorOrAdmin
    {
        require(newDripAmount != 0, "PCVDripController: zero drip amount");

        uint256 oldDripAmount = dripAmount;
        dripAmount = newDripAmount;
        emit DripAmountUpdate(oldDripAmount, newDripAmount);
    }

    /// @notice checks whether the target balance is less than the drip amount
    function dripEligible() public view virtual override returns(bool) {
        return target.balance() < dripAmount;
    }

    function _mintFei(address to, uint256 amountIn) internal override(CoreRef, RateLimitedMinter) {
      RateLimitedMinter._mintFei(to, amountIn);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../../Constants.sol";
import "./IConvexBooster.sol";
import "./IConvexBaseRewardPool.sol";
import "../curve/ICurvePool.sol";
import "../PCVDeposit.sol";

/// @title ConvexPCVDeposit: implementation for a PCVDeposit that stake/unstake
/// the Curve LP tokens on Convex, and can claim rewards.
/// @author Fei Protocol
contract ConvexPCVDeposit is PCVDeposit {

    // ------------------ Properties -------------------------------------------

    /// @notice The Curve pool to deposit in
    ICurvePool public curvePool;
    /// @notice The Convex Booster contract (for deposit/withdraw)
    IConvexBooster public convexBooster;
    /// @notice The Convex Rewards contract (for claiming rewards)
    IConvexBaseRewardPool public convexRewards;

    /// @notice number of coins in the Curve pool
    uint256 private constant N_COINS = 3;
    /// @notice boolean to know if FEI is in the pool
    bool private immutable feiInPool;
    /// @notice FEI index in the pool. If FEI is not present, value = 0.
    uint256 private immutable feiIndexInPool;

    // ------------------ Constructor ------------------------------------------

    /// @notice ConvexPCVDeposit constructor
    /// @param _core Fei Core for reference
    /// @param _curvePool The Curve pool whose LP tokens are staked
    /// @param _convexBooster The Convex Booster contract (for deposit/withdraw)
    /// @param _convexRewards The Convex Rewards contract (for claiming rewards)
    constructor(
        address _core,
        address _curvePool,
        address _convexBooster,
        address _convexRewards
    ) CoreRef(_core) {
        convexBooster = IConvexBooster(_convexBooster);
        convexRewards = IConvexBaseRewardPool(_convexRewards);
        curvePool = ICurvePool(_curvePool);

        // cache some values for later gas optimizations
        address feiAddress = address(fei());
        bool foundFeiInPool = false;
        uint256 feiFoundAtIndex = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            address tokenAddress = curvePool.coins(i);
            if (tokenAddress == feiAddress) {
                foundFeiInPool = true;
                feiFoundAtIndex = i;
            }
        }
        feiInPool = foundFeiInPool;
        feiIndexInPool = feiFoundAtIndex;
    }

    /// @notice Curve/Convex deposits report their balance in USD
    function balanceReportedIn() public pure override returns(address) {
        return Constants.USD;
    }

    /// @notice deposit Curve LP tokens on Convex and stake deposit tokens in the
    /// Convex rewards contract.
    /// Note : this call is permissionless, and can be used if LP tokens are
    /// transferred to this contract directly.
    function deposit() public override whenNotPaused {
        uint256 lpTokenBalance = curvePool.balanceOf(address(this));
        uint256 poolId = convexRewards.pid();
        curvePool.approve(address(convexBooster), lpTokenBalance);
        convexBooster.deposit(poolId, lpTokenBalance, true);
    }

    /// @notice unstake LP tokens from Convex Rewards, and withdraw Curve
    /// LP tokens from Convex
    function withdraw(address to, uint256 amountLpTokens)
        public
        override
        onlyPCVController
        whenNotPaused
    {
        convexRewards.withdrawAndUnwrap(amountLpTokens, false);
        curvePool.transfer(to, amountLpTokens);
    }

    /// @notice claim CRV & CVX rewards earned by the LP tokens staked on this contract.
    function claimRewards() public whenNotPaused {
        convexRewards.getReward(address(this), true);
    }

    /// @notice returns the balance in USD
    function balance() public view override returns (uint256) {
        uint256 lpTokensStaked = convexRewards.balanceOf(address(this));
        uint256 virtualPrice = curvePool.get_virtual_price();
        uint256 usdBalance = lpTokensStaked * virtualPrice / 1e18;

        // if FEI is in the pool, remove the FEI part of the liquidity, e.g. if
        // FEI is filling 40% of the pool, reduce the balance by 40%.
        if (feiInPool) {
            uint256[N_COINS] memory balances;
            uint256 totalBalances = 0;
            for (uint256 i = 0; i < N_COINS; i++) {
                IERC20 poolToken = IERC20(curvePool.coins(i));
                balances[i] = poolToken.balanceOf(address(curvePool));
                totalBalances += balances[i];
            }
            usdBalance -= usdBalance * balances[feiIndexInPool] / totalBalances;
        }

        return usdBalance;
    }

    /// @notice returns the resistant balance in USD and FEI held by the contract
    function resistantBalanceAndFei() public view override returns (
        uint256 resistantBalance,
        uint256 resistantFei
    ) {
        uint256 lpTokensStaked = convexRewards.balanceOf(address(this));
        uint256 virtualPrice = curvePool.get_virtual_price();
        resistantBalance = lpTokensStaked * virtualPrice / 1e18;

        // to have a resistant balance, we assume the pool is balanced, e.g. if
        // the pool holds 3 tokens, we assume FEI is 33.3% of the pool.
        if (feiInPool) {
            resistantFei = resistantBalance / N_COINS;
            resistantBalance -= resistantFei;
        }

        return (resistantBalance, resistantFei);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Docs: https://docs.convexfinance.com/convexfinanceintegration/booster

// main Convex contract(booster.sol) basic interface
interface IConvexBooster {
    // deposit into convex, receive a tokenized deposit. parameter to stake immediately
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
    // burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);
    // claim and dispatch rewards to the reward pool
    function earmarkRewards(uint256 _pid) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IConvexBaseRewardPool {
    function rewardToken() external view returns (address);
    function stakingToken() external view returns (address);
    function duration() external view returns (uint256);
    function operator() external view returns (address);
    function rewardManager() external view returns (address);
    function pid() external view returns (uint256);
    function periodFinish() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function lastUpdateTime() external view returns (uint256);
    function rewardPerTokenStored() external view returns (uint256);
    function queuedRewards() external view returns (uint256);
    function currentRewards() external view returns (uint256);
    function historicalRewards() external view returns (uint256);
    function newRewardRatio() external view returns (uint256);
    function userRewardPerTokenPaid(address user) external view returns (uint256);
    function rewards(address user) external view returns (uint256);
    function extraRewards(uint256 i) external view returns (address);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function extraRewardsLength() external view returns (uint256);
    function addExtraReward(address _reward) external returns(bool);
    function clearExtraRewards() external;
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function stake(uint256 _amount) external returns(bool);
    function stakeAll() external returns(bool);
    function stakeFor(address _for, uint256 _amount) external returns(bool);
    function withdraw(uint256 amount, bool claim) external returns(bool);
    function withdrawAll(bool claim) external;
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function withdrawAllAndUnwrap(bool claim) external;
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function getReward() external returns(bool);
    function donate(uint256 _amount) external returns(bool);
    function queueNewRewards(uint256 _rewards) external returns(bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IVotiumBribe.sol";
import "../../refs/CoreRef.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title VotiumBriber: implementation for a contract that can use
/// tokens to bribe on Votium.
/// @author Fei Protocol
contract VotiumBriber is CoreRef {
    using SafeERC20 for IERC20;

    // ------------------ Properties -------------------------------------------

    /// @notice The Curve pool to deposit in
    IVotiumBribe public votiumBribe;

    /// @notice The token to spend bribes in
    IERC20 public token;

    // ------------------ Constructor ------------------------------------------

    /// @notice VotiumBriber constructor
    /// @param _core Fei Core for reference
    /// @param _token The token spent for bribes
    /// @param _votiumBribe The Votium bribe contract
    constructor(
        address _core,
        IERC20 _token,
        IVotiumBribe _votiumBribe
    ) CoreRef(_core) {
        token = _token;
        votiumBribe = _votiumBribe;

        _setContractAdminRole(keccak256("TRIBAL_CHIEF_ADMIN_ROLE"));
    }

    /// @notice Spend tokens on Votium to bribe for a given pool.
    /// @param _proposal id of the proposal on snapshot
    /// @param _choiceIndex index of the pool in the snapshot vote to vote for
    /// @dev the call will revert if Votium has not called initiateProposal with
    /// the _proposal ID, if _choiceIndex is out of range, or of block.timestamp
    /// is after the deadline for bribing (usually 6 hours before Convex snapshot
    /// vote ends).
    function bribe(bytes32 _proposal, uint256 _choiceIndex) public onlyGovernorOrAdmin whenNotPaused {
        // fetch the current number of TRIBE
        uint256 tokenAmount = token.balanceOf(address(this));
        require(tokenAmount > 0, "VotiumBriber: no tokens to bribe");

        // send TRIBE to bribe contract
        token.approve(address(votiumBribe), tokenAmount);
        votiumBribe.depositBribe(
            address(token), // token
            tokenAmount, // amount
            _proposal, // proposal
            _choiceIndex // choiceIndex
        );
    }

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyPCVController {
        IERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVotiumBribe {
    // Deposit bribe
    function depositBribe(
        address _token,
        uint256 _amount,
        bytes32 _proposal,
        uint256 _choiceIndex
    ) external;

    // admin function
    function initiateProposal(
        bytes32 _proposal,
        uint256 _deadline,
        uint256 _maxIndex
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title IPCVGuardian
/// @notice an interface for defining how the PCVGuardian functions
/// @dev any implementation of this contract should be granted the roles of Guardian and PCVController in order to work correctly
interface IPCVGuardian {
    // ---------- Events ----------
    event SafeAddressAdded(
        address indexed safeAddress
    );

    event SafeAddressRemoved(
        address indexed safeAddress
    );

    event PCVGuardianWithdrawal(
        address indexed pcvDeposit, 
        address indexed destination, 
        uint256 amount
    ); 

    event PCVGuardianETHWithdrawal(
        address indexed pcvDeposit, 
        address indexed destination, 
        uint256 amount
    );

    event PCVGuardianERC20Withdrawal(
        address indexed pcvDeposit, 
        address indexed destination,
        address indexed token,
        uint256 amount
    );

    // ---------- Read-Only API ----------

    /// @notice returns true if the the provided address is a valid destination to withdraw funds to
    /// @param pcvDeposit the address to check
    function isSafeAddress(address pcvDeposit) external view returns (bool);

    /// @notice returns all safe addresses
    function getSafeAddresses() external view returns (address[] memory);

    // ---------- Governor-Only State-Changing API ----------

    /// @notice governor-only method to set an address as "safe" to withdraw funds to
    /// @param pcvDeposit the address to set as safe
    function setSafeAddress(address pcvDeposit) external;

    /// @notice batch version of setSafeAddress
    /// @param safeAddresses the addresses to set as safe, as calldata
    function setSafeAddresses(address[] calldata safeAddresses) external;

    // ---------- Governor-or-Guardian-Only State-Changing API ----------

    /// @notice governor-or-guardian-only method to un-set an address as "safe" to withdraw funds to
    /// @param pcvDeposit the address to un-set as safe
    function unsetSafeAddress(address pcvDeposit) external;

    /// @notice batch version of unsetSafeAddresses
    /// @param safeAddresses the addresses to un-set as safe
    function unsetSafeAddresses(address[] calldata safeAddresses) external;

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    /// @param safeAddress the destination address to withdraw to
    /// @param amount the amount to withdraw
    /// @param pauseAfter if true, the pcv contract will be paused after the withdraw
    /// @param depositAfter if true, attempts to deposit to the target PCV deposit
    function withdrawToSafeAddress(address pcvDeposit, address safeAddress, uint256 amount, bool pauseAfter, bool depositAfter) external;

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    /// @param safeAddress the destination address to withdraw to
    /// @param amount the amount of tokens to withdraw
    /// @param pauseAfter if true, the pcv contract will be paused after the withdraw
    /// @param depositAfter if true, attempts to deposit to the target PCV deposit
    function withdrawETHToSafeAddress(address pcvDeposit, address payable safeAddress, uint256 amount, bool pauseAfter, bool depositAfter) external;

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the deposit to pull funds from
    /// @param safeAddress the destination address to withdraw to
    /// @param token the token to withdraw
    /// @param amount the amount of funds to withdraw
    /// @param pauseAfter whether to pause the pcv after withdrawing
    /// @param depositAfter if true, attempts to deposit to the target PCV deposit
    function withdrawERC20ToSafeAddress(address pcvDeposit, address safeAddress, address token, uint256 amount, bool pauseAfter, bool depositAfter) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../PCVDeposit.sol";
import "../../refs/CoreRef.sol";

interface ITokemakPool {
    function underlyer() external view returns (address);
    function balanceOf(address holder) external view returns(uint256);
    function requestWithdrawal(uint256 amount) external;
}

interface ITokemakRewards {
  struct Recipient {
      uint256 chainId;
      uint256 cycle;
      address wallet;
      uint256 amount;
  }

  function claim(
      Recipient calldata recipient,
      uint8 v,
      bytes32 r,
      bytes32 s // bytes calldata signature
  ) external;
}

/// @title base class for a Tokemak PCV Deposit
/// @author Fei Protocol
abstract contract TokemakPCVDepositBase is PCVDeposit {

    /// @notice event generated when rewards are claimed
    event ClaimRewards (
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    /// @notice event generated when a withdrawal is requested
    event RequestWithdrawal (
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    address private constant TOKE_TOKEN_ADDRESS = address(0x2e9d63788249371f1DFC918a52f8d799F4a38C94);

    /// @notice the tokemak pool to deposit in
    address public immutable pool;

    /// @notice the tokemak rewards contract to claim TOKE incentives
    address public immutable rewards;

    /// @notice the token stored in the Tokemak pool
    IERC20 public immutable token;

    /// @notice Tokemak PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _pool Tokemak pool to deposit in
    /// @param _rewards Tokemak rewards contract to claim TOKE incentives
    constructor(
        address _core,
        address _pool,
        address _rewards
    ) CoreRef(_core) {
        pool = _pool;
        rewards = _rewards;
        token = IERC20(ITokemakPool(_pool).underlyer());
    }

    /// @notice returns total balance of PCV in the Deposit excluding the FEI
    function balance() public view override returns (uint256) {
        return ITokemakPool(pool).balanceOf(address(this));
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return address(token);
    }

    /// @notice request to withdraw a given amount of tokens to Tokemak. These
    /// tokens will be available for withdraw in the next cycles.
    /// This function can be called by the contract admin, e.g. the OA multisig,
    /// in anticipation of the execution of a DAO proposal that will call withdraw().
    /// @dev note that withdraw() calls will revert if this function has not been
    /// called before.
    /// @param amountUnderlying of tokens to withdraw in a subsequent withdraw() call.
    function requestWithdrawal(uint256 amountUnderlying)
        external
        onlyGovernorOrAdmin
        whenNotPaused
    {
        ITokemakPool(pool).requestWithdrawal(amountUnderlying);

        emit RequestWithdrawal(msg.sender, address(this), amountUnderlying);
    }

    /// @notice claim TOKE rewards associated to this PCV Deposit. The TOKE tokens
    /// will be sent to the PCVDeposit, and can then be moved with withdrawERC20.
    /// The Tokemak rewards are distributed as follow :
    /// "At the end of each cycle we publish a signed message for each LP out to
    //    a "folder" on IPFS. This message says how much TOKE the account is entitled
    //    to as their reward (and this is cumulative not just for a single cycle).
    //    That folder hash is published out to the website which will call out to
    //    an IPFS gateway, /ipfs/{folderHash}/{account}.json, and get the payload
    //    they need to submit to the contract. Tx is executed with that payload and
    //    the account is sent their TOKE."
    /// For an example of IPFS json file, see :
    //  https://ipfs.tokemaklabs.xyz/ipfs/Qmf5Vuy7x5t3rMCa6u57hF8AE89KLNkjdxSKjL8USALwYo/0x4eff3562075c5d2d9cb608139ec2fe86907005fa.json
    function claimRewards(
        uint256 cycle,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s // bytes calldata signature
    ) external whenNotPaused {
        ITokemakRewards.Recipient memory recipient = ITokemakRewards.Recipient(
            1, // chainId
            cycle,
            address(this), // wallet
            amount
        );

        ITokemakRewards(rewards).claim(recipient, v, r, s);

        emit ClaimRewards(
          msg.sender,
          address(TOKE_TOKEN_ADDRESS),
          address(this),
          amount
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./TokemakPCVDepositBase.sol";
import "../../Constants.sol";

interface ITokemakEthPool {
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 requestedAmount, bool asEth) external;
}

/// @title ETH implementation for a Tokemak PCV Deposit
/// @author Fei Protocol
contract EthTokemakPCVDeposit is TokemakPCVDepositBase {

    /// @notice Tokemak ETH PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _pool Tokemak pool to deposit in
    /// @param _rewards Tokemak rewards contract
    constructor(
        address _core,
        address _pool,
        address _rewards
    ) TokemakPCVDepositBase(_core, _pool, _rewards) {}

    receive() external payable {}

    /// @notice deposit ETH to Tokemak
    function deposit()
        external
        override
        whenNotPaused
    {
        uint256 amount = address(this).balance;

        ITokemakEthPool(pool).deposit{value: amount}(amount);

        emit Deposit(msg.sender, amount);
    }

    /// @notice withdraw tokens from the PCV allocation
    /// @param amountUnderlying of tokens withdrawn
    /// @param to the address to send PCV to
    function withdraw(address to, uint256 amountUnderlying)
        external
        override
        onlyPCVController
        whenNotPaused
    {
        ITokemakEthPool(pool).withdraw(amountUnderlying, true);

        Address.sendValue(payable(to), amountUnderlying);

        emit Withdrawal(msg.sender, to, amountUnderlying);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./TokemakPCVDepositBase.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ITokemakERC20Pool {
    function deposit(uint256 amount) external;
    function withdraw(uint256 requestedAmount) external;
}

/// @title ERC-20 implementation for a Tokemak PCV Deposit
/// @author Fei Protocol
contract ERC20TokemakPCVDeposit is TokemakPCVDepositBase {

    /// @notice Tokemak ERC20 PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _pool Tokemak pool to deposit in
    /// @param _rewards Tokemak rewards contract
    constructor(
        address _core,
        address _pool,
        address _rewards
    ) TokemakPCVDepositBase(_core, _pool, _rewards) {}

    /// @notice deposit ERC-20 tokens to Tokemak
    function deposit()
        external
        override
        whenNotPaused
    {
        uint256 amount = token.balanceOf(address(this));

        token.approve(pool, amount);

        ITokemakERC20Pool(pool).deposit(amount);

        emit Deposit(msg.sender, amount);
    }

    /// @notice withdraw tokens from the PCV allocation
    /// @param amountUnderlying of tokens withdrawn
    /// @param to the address to send PCV to
    function withdraw(address to, uint256 amountUnderlying)
        external
        override
        onlyPCVController
        whenNotPaused
    {
        ITokemakERC20Pool(pool).withdraw(amountUnderlying);

        token.transfer(to, amountUnderlying);

        emit Withdrawal(msg.sender, to, amountUnderlying);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../utils/WethPCVDeposit.sol";

interface LendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    
    function withdraw(address asset, uint256 amount, address to) external;
}

interface IncentivesController {
    function claimRewards(address[] calldata assets, uint256 amount, address to) external;

    function getRewardsBalance(address[] calldata assets, address user) external view returns(uint256);
}

/// @title Aave PCV Deposit
/// @author Fei Protocol
contract AavePCVDeposit is WethPCVDeposit {

    event ClaimRewards(address indexed caller, uint256 amount);

    /// @notice the associated Aave aToken for the deposit
    IERC20 public aToken;

    /// @notice the Aave v2 lending pool
    LendingPool public lendingPool;

    /// @notice the underlying token of the PCV deposit
    IERC20 public token;

    /// @notice the Aave incentives controller for the aToken
    IncentivesController public incentivesController;

    /// @notice Aave PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _lendingPool the Aave v2 lending pool
    /// @param _token the underlying token of the PCV deposit
    /// @param _aToken the associated Aave aToken for the deposit
    /// @param _incentivesController the Aave incentives controller for the aToken
    constructor(
        address _core,
        LendingPool _lendingPool,
        IERC20 _token,
        IERC20 _aToken,
        IncentivesController _incentivesController
    ) CoreRef(_core) {
        lendingPool = _lendingPool;
        aToken = _aToken;
        token = _token;
        incentivesController = _incentivesController;
    }

    /// @notice claims Aave rewards from the deposit and transfers to this address
    function claimRewards() external {
        address[] memory assets = new address[](1);
        assets[0] = address(aToken);
        // First grab the available balance
        uint256 amount = incentivesController.getRewardsBalance(assets, address(this));

        // claim all available rewards
        incentivesController.claimRewards(assets, amount, address(this));

        emit ClaimRewards(msg.sender, amount);
    }

    /// @notice deposit buffered aTokens
    function deposit() external override whenNotPaused {
        // wrap any held ETH if present
        wrapETH();

        // Approve and deposit buffered tokens
        uint256 pendingBalance = token.balanceOf(address(this));
        token.approve(address(lendingPool), pendingBalance);
        lendingPool.deposit(address(token), pendingBalance, address(this), 0);
        
        emit Deposit(msg.sender, pendingBalance);
    }

    /// @notice withdraw tokens from the PCV allocation
    /// @param amountUnderlying of tokens withdrawn
    /// @param to the address to send PCV to
    function withdraw(address to, uint256 amountUnderlying)
        external
        override
        onlyPCVController
    {
        lendingPool.withdraw(address(token), amountUnderlying, to);
        emit Withdrawal(msg.sender, to, amountUnderlying);
    }

    /// @notice returns total balance of PCV in the Deposit
    /// @dev aTokens are rebasing, so represent 1:1 on underlying value
    function balance() public view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return address(token);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IVault.sol";
import "./IWeightedPool.sol";
import "./BalancerPCVDepositBase.sol";
import "../PCVDeposit.sol";
import "../../Constants.sol";
import "../../refs/CoreRef.sol";
import "../../oracle/IOracle.sol";
import "../../external/gyro/ExtendedMath.sol";
import "../../external/gyro/abdk/ABDKMath64x64.sol";

/// @title base class for a Balancer WeightedPool PCV Deposit
/// @author Fei Protocol
contract BalancerPCVDepositWeightedPool is BalancerPCVDepositBase {
    using ExtendedMath for *;
    using ABDKMath64x64 for *;
    using SafeMath for *;
    using Decimal for Decimal.D256;

    event OracleUpdate(
        address _sender,
        address indexed _token,
        address indexed _oldOracle,
        address indexed _newOracle
    );

    /// @notice oracle array of the tokens stored in this Balancer pool
    IOracle[] public tokenOracles;
    /// @notice mapping of tokens to oracles of the tokens stored in this Balancer pool
    mapping(IERC20 => IOracle) public tokenOraclesMapping;

    /// @notice the token stored in the Balancer pool, used for accounting
    IERC20 public token;
    /// @notice cache of the index of the token in the Balancer pool
    uint8 private tokenIndexInPool;

    /// @notice true if FEI is in the pool
    bool private feiInPool;
    /// @notice if feiInPool is true, this is the index of FEI in the pool.
    /// If feiInPool is false, this is zero.
    uint8 private feiIndexInPool;

    /// @notice Balancer PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _poolId Balancer poolId to deposit in
    /// @param _vault Balancer vault
    /// @param _rewards Balancer rewards (the MerkleOrchard)
    /// @param _maximumSlippageBasisPoints Maximum slippage basis points when depositing
    /// @param _token Address of the ERC20 to manage / do accounting with
    /// @param _tokenOracles oracle for price feeds of the tokens in pool
    constructor(
        address _core,
        address _vault,
        address _rewards,
        bytes32 _poolId,
        uint256 _maximumSlippageBasisPoints,
        address _token,
        IOracle[] memory _tokenOracles
    ) BalancerPCVDepositBase(_core, _vault, _rewards, _poolId, _maximumSlippageBasisPoints) {
        // check that we have oracles for all tokens
        require(poolAssets.length == _tokenOracles.length, "BalancerPCVDepositWeightedPool: wrong number of oracles.");

        tokenOracles = _tokenOracles;

        // set cached values for token addresses & indexes
        bool tokenFound = false;
        address _fei = address(fei());
        for (uint256 i = 0; i < poolAssets.length; i++) {
            tokenOraclesMapping[IERC20(address(poolAssets[i]))] = _tokenOracles[i];
            if (address(poolAssets[i]) == _token) {
                tokenFound = true;
                tokenIndexInPool = uint8(i);
                token = IERC20(address(poolAssets[i]));
            }
            if (address(poolAssets[i]) == _fei) {
                feiInPool = true;
                feiIndexInPool = uint8(i);
            }
        }
        // check that the token is in the pool
        require(tokenFound, "BalancerPCVDepositWeightedPool: token not in pool.");

        // check that token used for account is not FEI
        require(_token != _fei, "BalancerPCVDepositWeightedPool: token must not be FEI.");
    }

    /// @notice sets the oracle for a token in this deposit
    function setOracle(address _token, address _newOracle) external onlyGovernorOrAdmin {
        // we must set the oracle for an asset that is in the pool
        address oldOracle = address(tokenOraclesMapping[IERC20(_token)]);
        require(oldOracle != address(0), "BalancerPCVDepositWeightedPool: invalid token");

        // set oracle in the map
        tokenOraclesMapping[IERC20(_token)] = IOracle(_newOracle);

        // emit event
        emit OracleUpdate(
            msg.sender,
            _token,
            oldOracle,
            _newOracle
        );
    }

    /// @notice returns total balance of PCV in the Deposit, expressed in "token"
    function balance() public view override returns (uint256) {
        uint256 _bptSupply = IWeightedPool(poolAddress).totalSupply();
        if (_bptSupply == 0) {
          // empty (uninitialized) pools have a totalSupply of 0
          return 0;
        }

        (, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
        uint256[] memory underlyingPrices = _readOracles();

        uint256 _balance = balances[tokenIndexInPool];
        for (uint256 i = 0; i < balances.length; i++) {
            bool isToken = i == tokenIndexInPool;
            bool isFei = feiInPool && i == feiIndexInPool;
            if (!isToken && !isFei) {
                _balance += balances[i] * underlyingPrices[i] / underlyingPrices[tokenIndexInPool];
            }
        }

        uint256 _bptBalance = IWeightedPool(poolAddress).balanceOf(address(this));

        return _balance * _bptBalance / _bptSupply;
    }

    // @notice returns the manipulation-resistant balance of tokens & FEI held.
    function resistantBalanceAndFei() public view override returns (
        uint256 _resistantBalance,
        uint256 _resistantFei
    ) {
        // read oracle values
        uint256[] memory underlyingPrices = _readOracles();

        // get BPT token price
        uint256 bptPrice = _getBPTPrice(underlyingPrices);

        // compute balance in USD value
        uint256 bptBalance = IWeightedPool(poolAddress).balanceOf(address(this));
        Decimal.D256 memory bptValueUSD = Decimal.from(bptBalance).mul(bptPrice).div(1e18);

        // compute balance in "token" value
        _resistantBalance = bptValueUSD.mul(1e18).div(underlyingPrices[tokenIndexInPool]).asUint256();

        // if FEI is in the pair, return only the value of asset, and does not
        // count the protocol-owned FEI in the balance. For instance, if the pool
        // is 80% WETH and 20% FEI, balance() will return 80% of the USD value
        // of the balancer pool tokens held by the contract, denominated in
        // "token" (and not in USD).
        if (feiInPool) {
            uint256[] memory _weights = IWeightedPool(poolAddress).getNormalizedWeights();
            _resistantFei = bptValueUSD.mul(_weights[feiIndexInPool]).div(1e18).asUint256();
            // if FEI is x% of the pool, remove x% of the balance
            _resistantBalance = _resistantBalance * (1e18 - _weights[feiIndexInPool]) / 1e18;
        }

        return (_resistantBalance, _resistantFei);
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return address(token);
    }

    // @notice deposit tokens to the Balancer pool
    function deposit() external override whenNotPaused {
        uint256[] memory balances = new uint256[](poolAssets.length);
        uint256 totalbalance = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            balances[i] = IERC20(address(poolAssets[i])).balanceOf(address(this));
            // @dev: note that totalbalance is meaningless here, because we are
            // adding units of tokens that may have different decimals, different
            // values, etc. But the totalbalance is only used for checking > 0,
            // to make sure that we have something to deposit.
            totalbalance += balances[i];
        }
        require(totalbalance > 0, "BalancerPCVDepositWeightedPool: no tokens to deposit");

        // Read oracles
        uint256[] memory underlyingPrices = _readOracles();

        // Build joinPool request
        if (feiInPool) {
            // If FEI is in pool, we mint the good balance of FEI to go with the tokens
            // we are depositing
            uint256 _feiToMint = underlyingPrices[tokenIndexInPool] * balances[tokenIndexInPool] / 1e18;
            _mintFei(address(this), _feiToMint);
            balances[feiIndexInPool] = _feiToMint;
        }

        bytes memory userData = abi.encode(IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, balances, 0);
        // If the pool is not initialized, join with an INIT JoinKind
        if (IWeightedPool(poolAddress).totalSupply() == 0) {
            userData = abi.encode(IWeightedPool.JoinKind.INIT, balances);
        }

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: poolAssets,
            maxAmountsIn: balances,
            userData: userData,
            fromInternalBalance: false // tokens are held on this contract
        });

        // approve spending on balancer's vault
        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i] > 0) {
                IERC20(address(poolAssets[i])).approve(address(vault), balances[i]);
            }
        }

        // execute joinPool & transfer tokens to Balancer
        uint256 bptBalanceBefore = IWeightedPool(poolAddress).balanceOf(address(this));
        vault.joinPool(
            poolId, // poolId
            address(this), // sender
            address(this), // recipient
            request // join pool request
        );
        uint256 bptBalanceAfter = IWeightedPool(poolAddress).balanceOf(address(this));

        // Check for slippage
        {
            // Compute USD value deposited
            uint256 valueIn = 0;
            for (uint256 i = 0; i < balances.length; i++) {
                valueIn += balances[i] * underlyingPrices[i] / 1e18;
            }

            // Compute USD value out
            uint256 bptPrice = _getBPTPrice(underlyingPrices);
            uint256 valueOut = Decimal.from(bptPrice).mul(bptBalanceAfter - bptBalanceBefore).div(1e18).asUint256();
            uint256 minValueOut = Decimal.from(valueIn)
                .mul(Constants.BASIS_POINTS_GRANULARITY - maximumSlippageBasisPoints)
                .div(Constants.BASIS_POINTS_GRANULARITY)
                .asUint256();
            require(valueOut > minValueOut, "BalancerPCVDepositWeightedPool: slippage too high");
        }

        // emit event
        emit Deposit(msg.sender, balances[tokenIndexInPool]);
    }

    /// @notice withdraw tokens from the PCV allocation
    /// @param to the address to send PCV to
    /// @param amount of tokens withdrawn
    /// Note: except for ERC20/FEI pool2s, this function will not withdraw tokens
    /// in the right proportions for the pool, so only use this to withdraw small
    /// amounts comparatively to the pool size. For large withdrawals, it is
    /// preferrable to use exitPool() and then withdrawERC20().
    function withdraw(address to, uint256 amount) external override onlyPCVController whenNotPaused {
        uint256 bptBalance = IWeightedPool(poolAddress).balanceOf(address(this));
        if (bptBalance != 0) {
            IVault.ExitPoolRequest memory request;
            request.assets = poolAssets;
            request.minAmountsOut = new uint256[](poolAssets.length);
            request.minAmountsOut[tokenIndexInPool] = amount;
            request.toInternalBalance = false;

            if (feiInPool) {
                // If FEI is in pool, we also remove an equivalent portion of FEI
                // from the pool, to conserve balance as much as possible
                (Decimal.D256 memory oracleValue, bool oracleValid) = tokenOraclesMapping[token].read();
                require(oracleValid, "BalancerPCVDepositWeightedPool: oracle invalid");
                uint256 amountFeiToWithdraw = oracleValue.mul(amount).asUint256();
                request.minAmountsOut[feiIndexInPool] = amountFeiToWithdraw;
            }

            // Uses encoding for exact tokens out, spending at maximum bptBalance
            bytes memory userData = abi.encode(IWeightedPool.ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT, request.minAmountsOut, bptBalance);
            request.userData = userData;

            vault.exitPool(poolId, address(this), payable(address(this)), request);
            SafeERC20.safeTransfer(token, to, amount);
            _burnFeiHeld();

            emit Withdrawal(msg.sender, to, amount);
        }
    }

    /// @notice read token oracles and revert if one of them is invalid
    function _readOracles() internal view returns (uint256[] memory underlyingPrices) {
        underlyingPrices = new uint256[](poolAssets.length);
        for (uint256 i = 0; i < underlyingPrices.length; i++) {
            (Decimal.D256 memory oracleValue, bool oracleValid) = tokenOraclesMapping[IERC20(address(poolAssets[i]))].read();
            require(oracleValid, "BalancerPCVDepositWeightedPool: invalid oracle");
            underlyingPrices[i] = oracleValue.mul(1e18).asUint256();

            // normalize prices for tokens with different decimals
            uint8 decimals = ERC20(address(poolAssets[i])).decimals();
            require(decimals <= 18, "invalid decimals"); // should never happen
            if (decimals < 18) {
                underlyingPrices[i] = underlyingPrices[i] * 10**(18-decimals);
            }
        }
    }

    /**
    * Calculates the value of Balancer pool tokens using the logic described here:
    * https://docs.gyro.finance/learn/oracles/bpt-oracle
    * This is robust to price manipulations within the Balancer pool.
    * Courtesy of Gyroscope protocol, used with permission. See the original file here :
    * https://github.com/gyrostable/core/blob/master/contracts/GyroPriceOracle.sol#L109-L167
    * @param underlyingPrices = array of prices for underlying assets in the pool,
    *   given in USD, on a base of 18 decimals.
    * @return bptPrice = the price of balancer pool tokens, in USD, on a base
    *   of 18 decimals.
    */
    function _getBPTPrice(uint256[] memory underlyingPrices) internal view returns (uint256 bptPrice) {
        IWeightedPool pool = IWeightedPool(poolAddress);
        uint256 _bptSupply = pool.totalSupply();
        uint256[] memory _weights = pool.getNormalizedWeights();
        ( , uint256[] memory _balances, ) = vault.getPoolTokens(poolId);

        uint256 _k = uint256(1e18);
        uint256 _weightedProd = uint256(1e18);

        for (uint256 i = 0; i < poolAssets.length; i++) {
            uint256 _tokenBalance = _balances[i];
            uint256 _decimals = ERC20(address(poolAssets[i])).decimals();
            if (_decimals < 18) {
                _tokenBalance = _tokenBalance.mul(10**(18 - _decimals));
            }

            // if one of the tokens in the pool has zero balance, there is a problem
            // in the pool, so we return zero
            if (_tokenBalance == 0) {
                return 0;
            }

            _k = _k.mulPow(_tokenBalance, _weights[i], 18);

            _weightedProd = _weightedProd.mulPow(
                underlyingPrices[i].scaledDiv(_weights[i], 18),
                _weights[i],
                18
            );
        }

        uint256 result = _k.scaledMul(_weightedProd).scaledDiv(_bptSupply);
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface IAsset {

}

// interface with required methods from Balancer V2 IVault
// https://github.com/balancer-labs/balancer-v2-monorepo/blob/389b52f1fc9e468de854810ce9dc3251d2d5b212/pkg/vault/contracts/interfaces/IVault.sol

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );


    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IBasePool.sol";

// interface with required methods from Balancer V2 WeightedPool
// https://github.com/balancer-labs/balancer-v2-monorepo/blob/389b52f1fc9e468de854810ce9dc3251d2d5b212/pkg/pool-weighted/contracts/WeightedPool.sol
interface IWeightedPool is IBasePool {
    function getSwapEnabled() external view returns (bool);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function getGradualWeightUpdateParams()
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256[] memory endWeights
        );

    function setSwapEnabled(bool swapEnabled) external;

    function updateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) external;

    function withdrawCollectedManagementFees(address recipient) external;   

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IAssetManager.sol";
import "./IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface with required methods from Balancer V2 IBasePool
// https://github.com/balancer-labs/balancer-v2-monorepo/blob/389b52f1fc9e468de854810ce9dc3251d2d5b212/pkg/pool-utils/contracts/BasePool.sol

interface IBasePool is IERC20 {

    function getSwapFeePercentage() external view returns (uint256);

    function setSwapFeePercentage(uint256 swapFeePercentage) external;

    function setAssetManagerPoolConfig(IERC20 token, IAssetManager.PoolConfig memory poolConfig) external;

    function setPaused(bool paused) external;

    function getVault() external view returns (IVault);

    function getPoolId() external view returns (bytes32);

    function getOwner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

// interface with required methods from Balancer V2 IBasePool
// https://github.com/balancer-labs/balancer-v2-monorepo/blob/389b52f1fc9e468de854810ce9dc3251d2d5b212/pkg/asset-manager-utils/contracts/IAssetManager.sol

interface IAssetManager {
    struct PoolConfig {
        uint64 targetPercentage;
        uint64 criticalPercentage;
        uint64 feePercentage;
    }

    function setPoolConfig(bytes32 poolId, PoolConfig calldata config) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IVault.sol";
import "./IMerkleOrchard.sol";
import "./IWeightedPool.sol";
import "../PCVDeposit.sol";
import "../../Constants.sol";
import "../../refs/CoreRef.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title base class for a Balancer PCV Deposit
/// @author Fei Protocol
abstract contract BalancerPCVDepositBase is PCVDeposit {

    // ----------- Events ---------------
    event UpdateMaximumSlippage(uint256 maximumSlippageBasisPoints);

    /// @notice event generated when rewards are claimed
    event ClaimRewards (
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    // @notice event generated when pool position is exited (LP tokens redeemed
    // for tokens in proportion to the pool's weights.
    event ExitPool(
        bytes32 indexed _poodId,
        address indexed _to,
        uint256 _bptAmount
    );

    // Maximum tolerated slippage for deposits
    uint256 public maximumSlippageBasisPoints;

    /// @notice the balancer pool to deposit in
    bytes32 public immutable poolId;
    address public immutable poolAddress;

    /// @notice cache of the assets in the Balancer pool
    IAsset[] internal poolAssets;

    /// @notice the balancer vault
    IVault public immutable vault;

    /// @notice the balancer rewards contract to claim incentives
    IMerkleOrchard public immutable rewards;

    /// @notice Balancer PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _vault Balancer vault
    /// @param _rewards Balancer rewards (the MerkleOrchard)
    /// @param _poolId Balancer poolId to deposit in
    /// @param _maximumSlippageBasisPoints Maximum slippage basis points when depositing
    constructor(
        address _core,
        address _vault,
        address _rewards,
        bytes32 _poolId,
        uint256 _maximumSlippageBasisPoints
    ) CoreRef(_core) {
        vault = IVault(_vault);
        rewards = IMerkleOrchard(_rewards);
        maximumSlippageBasisPoints = _maximumSlippageBasisPoints;
        poolId = _poolId;

        (poolAddress, ) = IVault(_vault).getPool(_poolId);

        // get the balancer pool tokens
        IERC20[] memory tokens;
        (tokens, , ) = IVault(_vault).getPoolTokens(_poolId);

        // cache the balancer pool tokens as Assets
        poolAssets = new IAsset[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            poolAssets[i] = IAsset(address(tokens[i]));
        }
    }

    // Accept ETH transfers
    receive() external payable {}

    /// @notice Wraps all ETH held by the contract to WETH
    /// Anyone can call it.
    /// Balancer uses WETH in its pools, and not ETH.
    function wrapETH() external {
        uint256 ethBalance = address(this).balance;
        if (ethBalance != 0) {
            Constants.WETH.deposit{value: ethBalance}();
        }
    }

    /// @notice unwrap WETH on the contract, for instance before
    /// sending to another PCVDeposit that needs pure ETH.
    /// Balancer uses WETH in its pools, and not ETH.
    function unwrapETH() external onlyPCVController {
        uint256 wethBalance = IERC20(address(Constants.WETH)).balanceOf(address(this));
        if (wethBalance != 0) {
            Constants.WETH.withdraw(wethBalance);
        }
    }

    /// @notice Sets the maximum slippage vs 1:1 price accepted during withdraw.
    /// @param _maximumSlippageBasisPoints the maximum slippage expressed in basis points (1/10_000)
    function setMaximumSlippage(uint256 _maximumSlippageBasisPoints) external onlyGovernorOrAdmin {
        require(_maximumSlippageBasisPoints <= Constants.BASIS_POINTS_GRANULARITY, "BalancerPCVDepositBase: Exceeds bp granularity.");
        maximumSlippageBasisPoints = _maximumSlippageBasisPoints;
        emit UpdateMaximumSlippage(_maximumSlippageBasisPoints);
    }

    /// @notice redeeem all assets from LP pool
    /// @param _to address to send underlying tokens to
    function exitPool(address _to) external whenNotPaused onlyPCVController {
        uint256 bptBalance = IWeightedPool(poolAddress).balanceOf(address(this));
        if (bptBalance != 0) {
            IVault.ExitPoolRequest memory request;

            // Uses encoding for exact BPT IN withdrawal using all held BPT
            bytes memory userData = abi.encode(IWeightedPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptBalance);
            request.assets = poolAssets;
            request.minAmountsOut = new uint256[](poolAssets.length); // 0 minimums
            request.userData = userData;
            request.toInternalBalance = false; // use external balances to be able to transfer out tokenReceived

            vault.exitPool(poolId, address(this), payable(address(_to)), request);

            if (_to == address(this)) {
                _burnFeiHeld();
            }

            emit ExitPool(poolId, _to, bptBalance);
        }
    }

    /// @notice claim BAL rewards associated to this PCV Deposit.
    /// Note that if dual incentives are active, this will only claim BAL rewards.
    /// For more context, see the following links :
    /// - https://docs.balancer.fi/products/merkle-orchard
    /// - https://docs.balancer.fi/products/merkle-orchard/claiming-tokens
    /// A permissionless manual claim can always be done directly on the
    /// MerkleOrchard contract, on behalf of this PCVDeposit. This function is
    /// provided solely for claiming more conveniently the BAL rewards.
    function claimRewards(
        uint256 distributionId,
        uint256 amount,
        bytes32[] memory merkleProof
    ) external whenNotPaused {
        address BAL_TOKEN_ADDRESS = address(0xba100000625a3754423978a60c9317c58a424e3D);
        address BAL_TOKEN_DISTRIBUTOR = address(0x35ED000468f397AA943009bD60cc6d2d9a7d32fF);

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(BAL_TOKEN_ADDRESS);

        IMerkleOrchard.Claim memory claim = IMerkleOrchard.Claim({
            distributionId: distributionId,
            balance: amount,
            distributor: BAL_TOKEN_DISTRIBUTOR,
            tokenIndex: 0,
            merkleProof: merkleProof
        });
        IMerkleOrchard.Claim[] memory claims = new IMerkleOrchard.Claim[](1);
        claims[0] = claim;

        IMerkleOrchard(rewards).claimDistributions(address(this), claims, tokens);

        emit ClaimRewards(
          msg.sender,
          address(BAL_TOKEN_ADDRESS),
          address(this),
          amount
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface for Balancer's MerkleOrchard
interface IMerkleOrchard {
    struct Claim {
        uint256 distributionId;
        uint256 balance;
        address distributor;
        uint256 tokenIndex;
        bytes32[] merkleProof;
    }

    function claimDistributions(
        address claimer,
        Claim[] memory claims,
        IERC20[] memory tokens
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./abdk/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @notice This contract contains math related utilities that allows to
 * compute fixed-point exponentiation or perform scaled arithmetic operations
 */
library ExtendedMath {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using SafeMath for uint256;

    uint256 constant decimals = 18;
    uint256 constant decimalScale = 10**decimals;

    /**
     * @notice Computes x**y where both `x` and `y` are fixed-point numbers
     */
    function powf(int128 _x, int128 _y) internal pure returns (int128 _xExpy) {
        // 2^(y * log2(x))
        return _y.mul(_x.log_2()).exp_2();
    }

    /**
     * @notice Computes `value * base ** exponent` where all of the parameters
     * are fixed point numbers scaled with `decimal`
     */
    function mulPow(
        uint256 value,
        uint256 base,
        uint256 exponent,
        uint256 decimal
    ) internal pure returns (uint256) {
        int128 basef = base.fromScaled(decimal);
        int128 expf = exponent.fromScaled(decimal);

        return powf(basef, expf).mulu(value);
    }

    /**
     * @notice Multiplies `a` and `b` scaling the result down by `_decimals`
     * `scaledMul(a, b, 18)` with an initial scale of 18 decimals for `a` and `b`
     * would keep the result to 18 decimals
     * The result of the computation is floored
     */
    function scaledMul(
        uint256 a,
        uint256 b,
        uint256 _decimals
    ) internal pure returns (uint256) {
        return a.mul(b).div(10**_decimals);
    }

    function scaledMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return scaledMul(a, b, decimals);
    }

    /**
     * @notice Divides `a` and `b` scaling the result up by `_decimals`
     * `scaledDiv(a, b, 18)` with an initial scale of 18 decimals for `a` and `b`
     * would keep the result to 18 decimals
     * The result of the computation is floored
     */
    function scaledDiv(
        uint256 a,
        uint256 b,
        uint256 _decimals
    ) internal pure returns (uint256) {
        return a.mul(10**_decimals).div(b);
    }

    /**
     * @notice See `scaledDiv(uint256 a, uint256 b, uint256 _decimals)`
     */
    function scaledDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return scaledDiv(a, b, decimals);
    }

    /**
     * @notice Computes a**b where a is a scaled fixed-point number and b is an integer
     * This keeps a scale of `_decimals` for `a`
     * The computation is performed in O(log n)
     */
    function scaledPow(
        uint256 base,
        uint256 exp,
        uint256 _decimals
    ) internal pure returns (uint256) {
        uint256 result = 10**_decimals;

        while (exp > 0) {
            if (exp % 2 == 1) {
                result = scaledMul(result, base, _decimals);
            }
            exp /= 2;
            base = scaledMul(base, base, _decimals);
        }
        return result;
    }

    /**
     * @notice See `scaledPow(uint256 base, uint256 exp, uint256 _decimals)`
     */
    function scaledPow(uint256 base, uint256 exp) internal pure returns (uint256) {
        return scaledPow(base, exp, decimals);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.4;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function uint256toInt128(uint256 input) internal pure returns(int128) {
        return int128(int256(input));
    }

    function int128toUint256(int128 input) internal pure returns(uint256) {
        return uint256(int256(input));
    }

    function int128toUint64(int128 input) internal pure returns(uint64) {
        return uint64(uint256(int256(input)));
    }

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(
            x <= 0x7FFFFFFFFFFFFFFF,
            "value is too high to be transformed in a 64.64-bit number"
        );
        return uint256toInt128(x << 64);
    }

    /**
     * Convert unsigned 256-bit integer number scaled with 10^decimals into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @param decimal scale of the number
     * @return signed 64.64-bit fixed point number
     */
    function fromScaled(uint256 x, uint256 decimal) internal pure returns (int128) {
        uint256 scale = 10**decimal;
        int128 wholeNumber = fromUInt(x / scale);
        int128 decimalNumber = div(fromUInt(x % scale), fromUInt(scale));
        return add(wholeNumber, decimalNumber);
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0);
        return int128toUint64(x >> 64);
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return int256(x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = (int256(x) * y) >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require(
                y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                    y <= 0x1000000000000000000000000000000000000000000000000
            );
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu(x, uint256(y));
            if (negativeResult) {
                require(
                    absoluteResult <=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                );
                return -int256(absoluteResult); // We rely on overflow behavior here
            } else {
                require(
                    absoluteResult <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
                return int256(absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0);

        uint256 lo = (int128toUint256(x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = int128toUint256(x) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        require(y != 0);
        int256 result = (int256(x) << 64) / y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        require(y != 0);

        bool negativeResult = false;
        if (x < 0) {
            x = -x; // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y; // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu(uint256(x), uint256(y));
        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000);
            return -int128(absoluteResult); // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128(absoluteResult); // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0);
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64));
        return int128(result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return -x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return x < 0 ? -x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        require(x != 0);
        int256 result = int256(0x100000000000000000000000000000000) / x;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return int128((int256(x) + int256(y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256(x) * int256(y);
        require(m >= 0);
        require(m < 0x4000000000000000000000000000000000000000000000000000000000000000);
        return int128(sqrtu(uint256(m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        uint256 absoluteResult;
        bool negativeResult = false;
        if (x >= 0) {
            absoluteResult = powu(int128toUint256(x) << 63, y);
        } else {
            // We rely on overflow behavior here
            absoluteResult = powu(uint256(uint128(-x)) << 63, y);
            negativeResult = y & 1 > 0;
        }

        absoluteResult >>= 63;

        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000);
            return -uint256toInt128(absoluteResult); // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint256toInt128(absoluteResult); // We rely on overflow behavior here
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        require(x >= 0);
        return int128(sqrtu(int128toUint256(x) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = int128toUint256(x) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        require(x > 0);

        return uint256toInt128((int128toUint256(log_2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128);
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000, "exponent too large"); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
        if (x & 0x4000000000000000 > 0)
            result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
        if (x & 0x2000000000000000 > 0)
            result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
        if (x & 0x1000000000000000 > 0)
            result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
        if (x & 0x800000000000000 > 0)
            result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
        if (x & 0x400000000000000 > 0)
            result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
        if (x & 0x200000000000000 > 0)
            result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
        if (x & 0x100000000000000 > 0)
            result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
        if (x & 0x80000000000000 > 0)
            result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
        if (x & 0x40000000000000 > 0)
            result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
        if (x & 0x20000000000000 > 0)
            result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
        if (x & 0x10000000000000 > 0)
            result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
        if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
        if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
        if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
        if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
        if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
        if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
        if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
        if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
        if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
        if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
        if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
        if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
        if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
        if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
        if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
        if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
        if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
        if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
        if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
        if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
        if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
        if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
        if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
        if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
        if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
        if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
        if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
        if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
        if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
        if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
        if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
        if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
        if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
        if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
        if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
        if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
        if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
        if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
        if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
        if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
        if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
        if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
        if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
        if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
        if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
        if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
        if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
        if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
        if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
        if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
        if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
        if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

        result >>= int128toUint256(63 - (x >> 64));
        require(result <= int128toUint256(MAX_64x64));

        return uint256toInt128(result);
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128(result);
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
     * number and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x unsigned 129.127-bit fixed point number
     * @param y uint256 value
     * @return unsigned 129.127-bit fixed point number
     */
    function powu(uint256 x, uint256 y) private pure returns (uint256) {
        if (y == 0) return 0x80000000000000000000000000000000;
        else if (x == 0) return 0;
        else {
            int256 msb = 0;
            uint256 xc = x;
            if (xc >= 0x100000000000000000000000000000000) {
                xc >>= 128;
                msb += 128;
            }
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 xe = msb - 127;
            if (xe > 0) x >>= uint256(xe);
            else x <<= uint256(-xe);

            uint256 result = 0x80000000000000000000000000000000;
            int256 re = 0;

            while (y > 0) {
                if (y & 1 > 0) {
                    result = result * x;
                    y -= 1;
                    re += xe;
                    if (
                        result >= 0x8000000000000000000000000000000000000000000000000000000000000000
                    ) {
                        result >>= 128;
                        re += 1;
                    } else result >>= 127;
                    if (re < -127) return 0; // Underflow
                    require(re < 128); // Overflow
                } else {
                    x = x * x;
                    y >>= 1;
                    xe <<= 1;
                    if (x >= 0x8000000000000000000000000000000000000000000000000000000000000000) {
                        x >>= 128;
                        xe += 1;
                    } else x >>= 127;
                    if (xe < -127) return 0; // Underflow
                    require(xe < 128); // Overflow
                }
            }

            if (re > 0) result <<= uint256(re);
            else if (re < 0) result >>= uint256(-re);

            return result;
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/** 
    @title Fei Risk Curve Interface
    @author Fei Protocol

    Risk Curves define a set of balancer weights for a given level of *leverage* in the PCV, which is computable from the collateralization ratio.

    The goal is to have higher weights on stable assets at high leverage (low collateralization) to derisk, and add more volatile assets at high collateralization.

    The Risk Curve will also take into account the magnitute of the change in weights to determine an amount of time to transition
 */
interface IRiskCurve {
    struct CurveParams {
        address[] assets;
        uint256[] baseWeights;
        int256[] slopes;
    }

    // ----------- public state changing API -----------
    /// @notice kick off a new weight change using the current leverage and weight change time
    function changeWeights() external;

    // ----------- Governor or admin only state changing API -----------
    /// @notice change the risk curve parameters
    function changeCurve(CurveParams memory curveParams) external;

    // ----------- Read-only API -----------
    /// @notice determine whether or not to kick off a new weight change
    function isWeightChangeEligible() external view returns(bool);

    /// @notice return the risk curve parameters
    function getCurveParams() external view returns(CurveParams memory);
 
    /// @notice return the current leverage in the protocol, defined as PCV / protocol equity
    function getCurrentLeverage() external view returns(uint256);

    /// @notice return the balancer weight of an asset at a given leverage
    function getAssetWeight(address asset, uint256 leverage) external view returns(uint256);
    
    /// @notice return the set of assets and their corresponding weights at a given leverage
    function getWeights(uint256 leverage) external view returns(address[] memory, uint256[] memory);

    /// @notice return the target weight for an asset at current leverage
    function getCurrentTargetAssetWeight(address asset) external view returns(uint256);

    /// @notice return the set of assets and their corresponding weights at a current leverage
    function getCurrentTargetWeights() external view returns(address[] memory, uint256[] memory);

    /// @notice get the number of seconds to transition weights given the old and new weights
    function getWeightChangeTime(uint256[] memory oldWeights, uint256[] memory newWeights) external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./manager/WeightedBalancerPoolManager.sol";
import "./IVault.sol";
import "../../utils/Timed.sol";
import "../../refs/OracleRef.sol";
import "../IPCVSwapper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title BalancerLBPSwapper
/// @author Fei Protocol
/// @notice an auction contract which cyclically sells one token for another using Balancer LBP
contract BalancerLBPSwapper is IPCVSwapper, OracleRef, Timed, WeightedBalancerPoolManager {
    using Decimal for Decimal.D256;
    using SafeERC20 for IERC20;

    // ------------- Events -------------

    event WithdrawERC20(
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    event ExitPool();

    event MinTokenSpentUpdate(uint256 oldMinTokenSpentBalance, uint256 newMinTokenSpentBalance);

    // ------------- Balancer State -------------
    /// @notice the Balancer LBP used for swapping
    IWeightedPool public pool;

    /// @notice the Balancer V2 Vault contract
    IVault public vault;

    /// @notice the Balancer V2 Pool id of `pool`
    bytes32 public pid;

    // Balancer constants for the weight changes
    uint256 public immutable SMALL_PERCENT;
    uint256 public immutable LARGE_PERCENT;

    // Balancer constants to memoize the target assets and weights from pool
    IAsset[] private assets;
    uint256[] private initialWeights;
    uint256[] private endWeights;

    // ------------- Swapper State -------------

    /// @notice the token to be auctioned
    address public immutable override tokenSpent;

    /// @notice the token to buy
    address public immutable override tokenReceived;

    /// @notice the address to send `tokenReceived`
    address public override tokenReceivingAddress;

    /// @notice the minimum amount of tokenSpent to kick off a new auction on swap()
    uint256 public minTokenSpentBalance;

    struct OracleData {
        address _oracle;
        address _backupOracle;
        // invert should be false if the oracle is reported in tokenSpent terms otherwise true
        bool _invertOraclePrice;
        // The decimalsNormalizer should be calculated as tokenSpent.decimals() - tokenReceived.decimals() if invert is false, otherwise reverse order
        int256 _decimalsNormalizer;
    }

    /**
    @notice constructor for BalancerLBPSwapper
    @param _core Core contract to reference
    @param oracleData The parameters needed to initialize the OracleRef
    @param _frequency minimum time between auctions and duration of auction
    @param _weightSmall the small weight of weight changes (e.g. 5%)
    @param _weightLarge the large weight of weight changes (e.g. 95%)
    @param _tokenSpent the token to be auctioned
    @param _tokenReceived the token to buy
    @param _tokenReceivingAddress the address to send `tokenReceived`
    @param _minTokenSpentBalance the minimum amount of tokenSpent to kick off a new auction on swap()
     */
    constructor(
        address _core,
        OracleData memory oracleData,
        uint256 _frequency,
        uint256 _weightSmall,
        uint256 _weightLarge,
        address _tokenSpent,
        address _tokenReceived,
        address _tokenReceivingAddress,
        uint256 _minTokenSpentBalance
    )
        OracleRef(
            _core,
            oracleData._oracle,
            oracleData._backupOracle,
            oracleData._decimalsNormalizer,
            oracleData._invertOraclePrice
        )
        Timed(_frequency)
        WeightedBalancerPoolManager()
    {
        // weight changes
        SMALL_PERCENT = _weightSmall;
        LARGE_PERCENT = _weightLarge;
        require(_weightSmall < _weightLarge, "BalancerLBPSwapper: bad weights");
        require(_weightSmall + _weightLarge == 1e18, "BalancerLBPSwapper: weights not normalized");

        // tokenSpent and tokenReceived are immutable
        tokenSpent = _tokenSpent;
        tokenReceived = _tokenReceived;

        _setReceivingAddress(_tokenReceivingAddress);
        _setMinTokenSpent(_minTokenSpentBalance);

        _setContractAdminRole(keccak256("SWAP_ADMIN_ROLE"));
    }

    /**
    @notice initialize Balancer LBP
    Needs to be a separate method because this contract needs to be deployed and supplied
    as the owner of the pool on construction.
    Includes various checks to ensure the pool contract is correct and initialization can only be done once
    @param _pool the Balancer LBP used for swapping
    */
    function init(IWeightedPool _pool) external {
        require(address(pool) == address(0), "BalancerLBPSwapper: initialized");
        _initTimed();

        pool = _pool;
        IVault _vault = _pool.getVault();

        vault = _vault;

        // Check ownership
        require(_pool.getOwner() == address(this), "BalancerLBPSwapper: contract not pool owner");

        // Check correct pool token components
        bytes32 _pid = _pool.getPoolId();
        pid = _pid;
        (IERC20[] memory tokens,,) = _vault.getPoolTokens(_pid);
        require(tokens.length == 2, "BalancerLBPSwapper: pool does not have 2 tokens");
        require(
            tokenSpent == address(tokens[0]) ||
            tokenSpent == address(tokens[1]),
            "BalancerLBPSwapper: tokenSpent not in pool"
        );
        require(
            tokenReceived == address(tokens[0]) ||
            tokenReceived == address(tokens[1]),
            "BalancerLBPSwapper: tokenReceived not in pool"
        );

        // Set the asset array and target weights
        assets = new IAsset[](2);
        assets[0] = IAsset(address(tokens[0]));
        assets[1] = IAsset(address(tokens[1]));

        bool tokenSpentAtIndex0 = tokenSpent == address(tokens[0]);
        initialWeights = new uint[](2);
        endWeights = new uint[](2);

        if (tokenSpentAtIndex0) {
            initialWeights[0] = LARGE_PERCENT;
            initialWeights[1] = SMALL_PERCENT;

            endWeights[0] = SMALL_PERCENT;
            endWeights[1] = LARGE_PERCENT;
        }  else {
            initialWeights[0] = SMALL_PERCENT;
            initialWeights[1] = LARGE_PERCENT;

            endWeights[0] = LARGE_PERCENT;
            endWeights[1] = SMALL_PERCENT;
        }

        // Approve pool tokens for vault
        _pool.approve(address(_vault), type(uint256).max);
        IERC20(tokenSpent).approve(address(_vault), type(uint256).max);
        IERC20(tokenReceived).approve(address(_vault), type(uint256).max);
    }

    /**
        @notice Swap algorithm
        1. Withdraw existing LP tokens
        2. Reset weights
        3. Provide new liquidity
        4. Trigger gradual weight change
        5. Transfer remaining tokenReceived to tokenReceivingAddress
        @dev assumes tokenSpent balance of contract exceeds minTokenSpentBalance to kick off a new auction
    */
    function swap() external override afterTime whenNotPaused onlyGovernorOrAdmin {
        _swap();
    }

    /**
        @notice Force a swap() call, without waiting afterTime.
        This should only be callable after init() call, when no
        other swap is happening (call reverts if weight change
        is in progress).
    */
    function forceSwap() external whenNotPaused onlyGovernor {
        _swap();
    }

    /// @notice redeeem all assets from LP pool
    /// @param to destination for withdrawn tokens
    function exitPool(address to) external onlyPCVController {
        _exitPool();
        _transferAll(tokenSpent, to);
        _transferAll(tokenReceived, to);
    }

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
      address token,
      address to,
      uint256 amount
    ) public onlyPCVController {
        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(msg.sender, token, to, amount);
    }

    /// @notice returns when the next auction ends
    function swapEndTime() public view returns(uint256 endTime) {
        (,endTime,) = pool.getGradualWeightUpdateParams();
    }

    /// @notice sets the minimum time between swaps
	/// @param _frequency minimum time between swaps in seconds
    function setSwapFrequency(uint256 _frequency) external onlyGovernorOrAdmin {
       _setDuration(_frequency);
    }

    /// @notice sets the minimum token spent balance
	/// @param newMinTokenSpentBalance minimum amount of FEI to trigger a new auction
    function setMinTokenSpent(uint256 newMinTokenSpentBalance) external onlyGovernorOrAdmin {
       _setMinTokenSpent(newMinTokenSpentBalance);
    }

    /// @notice Sets the address receiving swap's inbound tokens
    /// @param newTokenReceivingAddress the address that will receive tokens
    function setReceivingAddress(address newTokenReceivingAddress) external override onlyGovernorOrAdmin {
        _setReceivingAddress(newTokenReceivingAddress);
    }

    /// @notice return the amount of tokens needed to seed the next auction
    function getTokensIn(uint256 spentTokenBalance) external view returns(address[] memory tokens, uint256[] memory amountsIn) {
        tokens = new address[](2);
        tokens[0] = address(assets[0]);
        tokens[1] = address(assets[1]);

        return (tokens, _getTokensIn(spentTokenBalance));
    }

    /**
        @notice Swap algorithm
        1. Withdraw existing LP tokens
        2. Reset weights
        3. Provide new liquidity
        4. Trigger gradual weight change
        5. Transfer remaining tokenReceived to tokenReceivingAddress
        @dev assumes tokenSpent balance of contract exceeds minTokenSpentBalance to kick off a new auction
    */
    function _swap() internal {
        (,, uint256 lastChangeBlock) = vault.getPoolTokens(pid);

        // Ensures no actor can change the pool contents earlier in the block
        require(lastChangeBlock < block.number, "BalancerLBPSwapper: pool changed this block");

        uint256 bptTotal = pool.totalSupply();

        // Balancer locks a small amount of bptTotal after init, so 0 bpt means pool needs initializing
        if (bptTotal == 0) {
            _initializePool();
            return;
        }
        require(swapEndTime() < block.timestamp, "BalancerLBPSwapper: weight update in progress");

        // 1. Withdraw existing LP tokens (if currently held)
        _exitPool();

        // 2. Reset weights to LARGE_PERCENT:SMALL_PERCENT
        // Using current block time triggers immediate weight reset
        _updateWeightsGradually(
            pool,
            block.timestamp,
            block.timestamp,
            initialWeights
        );

        // 3. Provide new liquidity
        uint256 spentTokenBalance = IERC20(tokenSpent).balanceOf(address(this));
        require(spentTokenBalance > minTokenSpentBalance, "BalancerLBPSwapper: not enough for new swap");

        // uses exact tokens in encoding for deposit, supplying both tokens
        // will use some of the previously withdrawn tokenReceived to seed the 1% required for new auction
        uint256[] memory amountsIn = _getTokensIn(spentTokenBalance);
        bytes memory userData = abi.encode(IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0);

        IVault.JoinPoolRequest memory joinRequest;
        joinRequest.assets = assets;
        joinRequest.maxAmountsIn = amountsIn;
        joinRequest.userData = userData;
        joinRequest.fromInternalBalance = false; // uses external balances because tokens are held by contract

        vault.joinPool(pid, address(this), payable(address(this)), joinRequest);

        // 4. Kick off new auction ending after `duration` seconds
        _updateWeightsGradually(pool, block.timestamp, block.timestamp + duration, endWeights);
        _initTimed(); // reset timer
        // 5. Send remaining tokenReceived to target
        _transferAll(tokenReceived, tokenReceivingAddress);
    }

    function _exitPool() internal {
        uint256 bptBalance = pool.balanceOf(address(this));
        if (bptBalance != 0) {
            IVault.ExitPoolRequest memory exitRequest;

            // Uses encoding for exact BPT IN withdrawal using all held BPT
            bytes memory userData = abi.encode(IWeightedPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptBalance);

            exitRequest.assets = assets;
            exitRequest.minAmountsOut = new uint256[](2); // 0 min
            exitRequest.userData = userData;
            exitRequest.toInternalBalance = false; // use external balances to be able to transfer out tokenReceived

            vault.exitPool(pid, address(this), payable(address(this)), exitRequest);
            emit ExitPool();
        }
    }

    function _transferAll(address token, address to) internal {
        IERC20 _token = IERC20(token);
        _token.safeTransfer(to, _token.balanceOf(address(this)));
    }

    function _setReceivingAddress(address newTokenReceivingAddress) internal {
      require(newTokenReceivingAddress != address(0), "BalancerLBPSwapper: zero address");
      address oldTokenReceivingAddress = tokenReceivingAddress;
      tokenReceivingAddress = newTokenReceivingAddress;
      emit UpdateReceivingAddress(oldTokenReceivingAddress, newTokenReceivingAddress);
    }

    function _initializePool() internal {
        // Balancer LBP initialization uses a unique JoinKind which only takes in amountsIn
        uint256 spentTokenBalance = IERC20(tokenSpent).balanceOf(address(this));
        require(spentTokenBalance >= minTokenSpentBalance, "BalancerLBPSwapper: not enough tokenSpent to init");

        uint256[] memory amountsIn = _getTokensIn(spentTokenBalance);
        bytes memory userData = abi.encode(IWeightedPool.JoinKind.INIT, amountsIn);

        IVault.JoinPoolRequest memory joinRequest;
        joinRequest.assets = assets;
        joinRequest.maxAmountsIn = amountsIn;
        joinRequest.userData = userData;
        joinRequest.fromInternalBalance = false;

        vault.joinPool(
            pid,
            address(this),
            payable(address(this)),
            joinRequest
        );

        // Kick off the first auction
        _updateWeightsGradually(
            pool,
            block.timestamp,
            block.timestamp + duration,
            endWeights
        );
        _initTimed();

        _transferAll(tokenReceived, tokenReceivingAddress);
    }

    function _getTokensIn(uint256 spentTokenBalance) internal view returns(uint256[] memory amountsIn) {
        amountsIn = new uint256[](2);

        uint256 receivedTokenBalance = readOracle().mul(spentTokenBalance).mul(SMALL_PERCENT).div(LARGE_PERCENT).asUint256();

        if (address(assets[0]) == tokenSpent) {
            amountsIn[0] = spentTokenBalance;
            amountsIn[1] = receivedTokenBalance;
        } else {
            amountsIn[0] = receivedTokenBalance;
            amountsIn[1] = spentTokenBalance;
        }
    }

    function _setMinTokenSpent(uint256 newMinTokenSpentBalance) internal {
      uint256 oldMinTokenSpentBalance = minTokenSpentBalance;
      minTokenSpentBalance = newMinTokenSpentBalance;
      emit MinTokenSpentUpdate(oldMinTokenSpentBalance, newMinTokenSpentBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IWeightedBalancerPoolManager.sol";
import "./BaseBalancerPoolManager.sol";

/// @title WeightedBalancerPoolManager
/// @notice an abstract utility class for a contract that manages a Balancer WeightedPool (including LBP)
/// exposes the governable methods to Fei Governors or admins
abstract contract WeightedBalancerPoolManager is IWeightedBalancerPoolManager, BaseBalancerPoolManager {
    
    constructor() BaseBalancerPoolManager() {}

    function setSwapEnabled(IWeightedPool pool, bool swapEnabled) public override onlyGovernorOrAdmin {
        pool.setSwapEnabled(swapEnabled);
    }

    function updateWeightsGradually(
        IWeightedPool pool,
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) public override onlyGovernorOrAdmin {
        _updateWeightsGradually(pool, startTime, endTime, endWeights);
    }

    function _updateWeightsGradually(
        IWeightedPool pool,
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) internal {
        pool.updateWeightsGradually(startTime, endTime, endWeights);
    }

    function withdrawCollectedManagementFees(IWeightedPool pool, address recipient) public override onlyGovernorOrAdmin {
        pool.withdrawCollectedManagementFees(recipient);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../IWeightedPool.sol";
import "./IBaseBalancerPoolManager.sol";

interface IWeightedBalancerPoolManager is IBaseBalancerPoolManager {
    // ----------- Governor or admin only state changing API -----------
    function setSwapEnabled(IWeightedPool pool, bool swapEnabled) external;

    function updateWeightsGradually(
        IWeightedPool pool,
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) external;

    function withdrawCollectedManagementFees(IWeightedPool pool, address recipient) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../IBasePool.sol";

interface IBaseBalancerPoolManager {
    // ----------- Governor or admin only state changing API -----------
    function setSwapFee(IBasePool pool, uint256 swapFee) external;

    function setPaused(IBasePool pool, bool paused) external;

    function setAssetManagerPoolConfig(
        IBasePool pool, 
        IERC20 token, 
        IAssetManager.PoolConfig memory poolConfig
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../refs/CoreRef.sol";
import "./IBaseBalancerPoolManager.sol";

/// @title BaseBalancerPoolManager
/// @notice an abstract utility class for a contract that manages a Balancer BasePool
/// exposes the governable methods to Fei Governors or admins
abstract contract BaseBalancerPoolManager is IBaseBalancerPoolManager, CoreRef {
    
    constructor() {
        _setContractAdminRole(keccak256("BALANCER_MANAGER_ADMIN_ROLE"));
    }

    function setSwapFee(IBasePool pool, uint256 swapFee) public override onlyGovernorOrAdmin {
        pool.setSwapFeePercentage(swapFee);
    }

    function setPaused(IBasePool pool, bool paused) public override onlyGovernorOrAdmin {
        pool.setPaused(paused);
    }

    function setAssetManagerPoolConfig(
        IBasePool pool, 
        IERC20 token, 
        IAssetManager.PoolConfig memory poolConfig
    ) public override onlyGovernorOrAdmin {
        pool.setAssetManagerPoolConfig(token, poolConfig);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;  

import "./IVault.sol";
import "./IWeightedPool.sol";
import "../../external/gyro/ExtendedMath.sol";
import "../IPCVDepositBalances.sol";
import "../../oracle/IOracle.sol";
import "../../Constants.sol";

/// @title BPTLens
/// @author Fei Protocol
/// @notice a contract to read manipulation resistant balances from BPTs
contract BPTLens is IPCVDepositBalances {
    using ExtendedMath for uint256;

    /// @notice the token the lens reports balances in
    address public immutable override balanceReportedIn;

    /// @notice the balancer pool to look at
    IWeightedPool public immutable pool;

    /// @notice the Balancer V2 Vault
    IVault public immutable VAULT;
    
    // the pool id on balancer
    bytes32 internal immutable id;

    // the index of balanceReportedIn on the pool
    uint256 internal immutable index;

    /// @notice true if FEI is in the pair
    bool public immutable feiInPair;

    /// @notice true if FEI is the reported balance
    bool public immutable feiIsReportedIn;

    /// @notice the oracle for balanceReportedIn token
    IOracle public immutable reportedOracle;
        
    /// @notice the oracle for the other token in the pair (not balanceReportedIn)
    IOracle public immutable otherOracle;

    constructor(
        address _token, 
        IWeightedPool _pool,
        IOracle _reportedOracle,
        IOracle _otherOracle,
        bool _feiIsReportedIn,
        bool _feiIsOther
    ) {
        pool = _pool;
        IVault _vault = _pool.getVault();
        VAULT = _vault;

        bytes32 _id = _pool.getPoolId();
        id = _id;
        (
            IERC20[] memory tokens,
            uint256[] memory balances,
        ) = _vault.getPoolTokens(_id); 

        // Check the token is in the BPT and its only a 2 token pool
        require(address(tokens[0]) == _token || address(tokens[1]) == _token);
        require(tokens.length == 2);
        balanceReportedIn = _token;

        index = address(tokens[0]) == _token ? 0 : 1;

        feiIsReportedIn = _feiIsReportedIn;
        feiInPair = _feiIsReportedIn || _feiIsOther;

        reportedOracle = _reportedOracle;
        otherOracle = _otherOracle;
    }

    function balance() public view override returns(uint256) {
        (
            IERC20[] memory _tokens,
            uint256[] memory balances,
        ) = VAULT.getPoolTokens(id); 

        return balances[index];
    }

   /**
     * @notice Calculates the manipulation resistant balances of Balancer pool tokens using the logic described here:
     * https://docs.gyro.finance/learn/oracles/bpt-oracle
     * This is robust to price manipulations within the Balancer pool.
     */
    function resistantBalanceAndFei() public view override returns(uint256, uint256) {
        uint256[] memory prices = new uint256[](2);
        uint256 j = index == 0 ? 1 : 0;

        // Check oracles and fill in prices
        (Decimal.D256 memory reportedPrice, bool reportedValid) = reportedOracle.read();
        prices[index] = reportedPrice.value;

        (Decimal.D256 memory otherPrice, bool otherValid) = otherOracle.read();
        prices[j] = otherPrice.value;

        require(reportedValid && otherValid, "BPTLens: Invalid Oracle");

        (
            IERC20[] memory _tokens,
            uint256[] memory balances,
        ) = VAULT.getPoolTokens(id);

        uint256[] memory weights = pool.getNormalizedWeights();

        // uses balances, weights, and prices to calculate manipulation resistant reserves
        uint256 reserves = _getIdealReserves(balances, prices, weights, index);

        if (feiIsReportedIn) {
            return (reserves, reserves);
        } 
        if (feiInPair) {
           uint256 otherReserves = _getIdealReserves(balances, prices, weights, j);
           return (reserves, otherReserves);
        }
        return (reserves, 0);
    }

    /*
        let r represent reserves and r' be ideal reserves (derived from manipulation resistant variables)
        p are resistant oracle prices of the tokens
        w are the balancer weights
        k is the balancer invariant

        BPTPrice = (p0/w0)^w0 * (p1/w1)^w1 * k
        r0' = BPTPrice * w0/p0
        r0' = ((w0*p1)/(p0*w1))^w1 * k

        Now including k allows for further simplification
        k = r0^w0 * r1^w1

        r0' = r0^w0 * r1^w1 * ((w0*p1)/(p0*w1))^w1
        r0' = r0^w0 * ((w0*p1*r1)/(p0*w1))^w1
    */
    function _getIdealReserves(
        uint256[] memory balances,
        uint256[] memory prices,
        uint256[] memory weights,
        uint256 i
    )
        internal
        pure
        returns (uint256 reserves)
    {
        uint256 j = i == 0 ? 1 : 0;

        uint256 one = Constants.ETH_GRANULARITY;

        uint256 reservesScaled = one.mulPow(balances[i], weights[i], Constants.ETH_DECIMALS);
        uint256 multiplier = (weights[i] * prices[j] * balances[j]) / (prices[i] * weights[j]);

        reserves = reservesScaled.mulPow(multiplier, weights[j], Constants.ETH_DECIMALS);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./CompoundPCVDepositBase.sol";
import "../../Constants.sol";

interface CEther {
    function mint() external payable;
}

/// @title ETH implementation for a Compound PCV Deposit
/// @author Fei Protocol
contract EthCompoundPCVDeposit is CompoundPCVDepositBase {

    /// @notice Compound ETH PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _cToken Compound cToken to deposit
    constructor(
        address _core,
        address _cToken
    ) CompoundPCVDepositBase(_core, _cToken) {
        // require(cToken.isCEther(), "EthCompoundPCVDeposit: Not a CEther");
    }

    receive() external payable {}

    /// @notice deposit ETH to Compound
    function deposit()
        external
        override
        whenNotPaused
    {
        uint256 amount = address(this).balance;

        // CEth deposits revert on failure
        CEther(address(cToken)).mint{value: amount}();
        emit Deposit(msg.sender, amount);
    }

    function _transferUnderlying(address to, uint256 amount) internal override {
        Address.sendValue(payable(to), amount);
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public pure override returns (address) {
        return address(Constants.WETH);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../PCVDeposit.sol";
import "../../refs/CoreRef.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface CToken {
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function isCToken() external view returns(bool);
    function isCEther() external view returns(bool);
}

/// @title base class for a Compound PCV Deposit
/// @author Fei Protocol
abstract contract CompoundPCVDepositBase is PCVDeposit {

    CToken public cToken;

    uint256 private constant EXCHANGE_RATE_SCALE = 1e18;

    /// @notice Compound PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _cToken Compound cToken to deposit
    constructor(
        address _core,
        address _cToken
    ) CoreRef(_core) {
        cToken = CToken(_cToken);
        require(cToken.isCToken(), "CompoundPCVDeposit: Not a cToken");
    }

    /// @notice withdraw tokens from the PCV allocation
    /// @param amountUnderlying of tokens withdrawn
    /// @param to the address to send PCV to
    function withdraw(address to, uint256 amountUnderlying)
        external
        override
        onlyPCVController
        whenNotPaused
    {
        require(
            cToken.redeemUnderlying(amountUnderlying) == 0,
            "CompoundPCVDeposit: redeem error"
        );
        _transferUnderlying(to, amountUnderlying);
        emit Withdrawal(msg.sender, to, amountUnderlying);
    }

    /// @notice returns total balance of PCV in the Deposit excluding the FEI
    /// @dev returns stale values from Compound if the market hasn't been updated
    function balance() public view override returns (uint256) {
        uint256 exchangeRate = cToken.exchangeRateStored();
        return cToken.balanceOf(address(this)) * exchangeRate / EXCHANGE_RATE_SCALE;
    }

    function _transferUnderlying(address to, uint256 amount) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./CompoundPCVDepositBase.sol";

interface CErc20 {
    function mint(uint256 amount) external returns (uint256);

    function underlying() external returns (address);
}

/// @title ERC-20 implementation for a Compound PCV Deposit
/// @author Fei Protocol
contract ERC20CompoundPCVDeposit is CompoundPCVDepositBase {

    /// @notice the token underlying the cToken
    IERC20 public token;

    /// @notice Compound ERC20 PCV Deposit constructor
    /// @param _core Fei Core for reference
    /// @param _cToken Compound cToken to deposit
    constructor(
        address _core,
        address _cToken
    ) CompoundPCVDepositBase(_core, _cToken) {
        token = IERC20(CErc20(_cToken).underlying());
    }

    /// @notice deposit ERC-20 tokens to Compound
    function deposit()
        external
        override
        whenNotPaused
    {
        uint256 amount = token.balanceOf(address(this));

        token.approve(address(cToken), amount);

        // Compound returns non-zero when there is an error
        require(CErc20(address(cToken)).mint(amount) == 0, "ERC20CompoundPCVDeposit: deposit error");
        
        emit Deposit(msg.sender, amount);
    }

    function _transferUnderlying(address to, uint256 amount) internal override {
        SafeERC20.safeTransfer(token, to, amount);
    }

    /// @notice display the related token of the balance reported
    function balanceReportedIn() public view override returns (address) {
        return address(token);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;  

import "../PCVDeposit.sol";
import "./IBAMM.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title BAMMDeposit
/// @author Fei Protocol
/// @notice a contract to read manipulation resistant LUSD from BAMM 
contract BAMMDeposit is PCVDeposit {
    using SafeERC20 for IERC20;

    /// @notice LUSD, the reported token for BAMM    
    address public constant override balanceReportedIn = address(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);

    /// @notice B. Protocol BAMM address
    IBAMM public constant BAMM = IBAMM(0x0d3AbAA7E088C2c82f54B2f47613DA438ea8C598);

    /// @notice Liquity Stability pool address
    IStabilityPool public immutable stabilityPool = BAMM.SP();

    uint256 constant public PRECISION = 1e18;

    constructor(address core) CoreRef(core) {}

    receive() external payable {}
    
    /// @notice deposit into B Protocol BAMM
    function deposit() 
        external
        override
        whenNotPaused
    {
        IERC20 lusd = IERC20(balanceReportedIn);
        uint256 amount = lusd.balanceOf(address(this));

        lusd.safeApprove(address(BAMM), amount);
        BAMM.deposit(amount);
    }

    /// @notice withdraw LUSD from B Protocol BAMM
    function withdraw(address to, uint256 amount) external override onlyPCVController {
        uint256 totalSupply = BAMM.totalSupply();
        uint256 lusdValue = stabilityPool.getCompoundedLUSDDeposit(address(BAMM));
        uint256 shares = (amount * totalSupply / lusdValue) + 1; // extra unit to prevent truncation errors

        // Withdraw the LUSD from BAMM (also withdraws LQTY and dust ETH)
        BAMM.withdraw(shares);

        IERC20(balanceReportedIn).safeTransfer(to, amount);
        emit Withdrawal(msg.sender, to, amount);
    }

    /// @notice report LUSD balance of BAMM 
    // proportional amount of BAMM USD value held by this contract       
    function balance() public view override returns(uint256) {
        uint256 ethBalance  = stabilityPool.getDepositorETHGain(address(BAMM));

        uint256 eth2usdPrice = BAMM.fetchPrice();
        require(eth2usdPrice != 0, "chainlink is down");

        uint256 ethUsdValue = ethBalance * eth2usdPrice / PRECISION;

        uint256 bammLusdValue = stabilityPool.getCompoundedLUSDDeposit(address(BAMM));
        return (bammLusdValue + ethUsdValue) * BAMM.balanceOf(address(this)) / BAMM.totalSupply();
    }

    function claimRewards() public {
        BAMM.withdraw(0); // Claim LQTY
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IStabilityPool.sol";

// Ref: https://github.com/backstop-protocol/dev/blob/main/packages/contracts/contracts/B.Protocol/BAMM.sol
interface IBAMM {

    // Views

    /// @notice returns ETH price scaled by 1e18
    function fetchPrice() external view returns (uint256);

    /// @notice returns amount of ETH received for an LUSD swap
    function getSwapEthAmount(uint256 lusdQty) external view returns (uint256 ethAmount, uint256 feeEthAmount);

    /// @notice LUSD token address
    function LUSD() external view returns (IERC20);

    /// @notice Liquity Stability Pool Address
    function SP() external view returns (IStabilityPool);

    /// @notice BAMM shares held by user
    function balanceOf(address account) external view returns (uint256);

    /// @notice total BAMM shares
    function totalSupply() external view returns (uint256);

    /// @notice Reward token
    function bonus() external view returns (address);

    // Mutative Functions

    /// @notice deposit LUSD for shares in BAMM
    function deposit(uint256 lusdAmount) external;

    /// @notice withdraw shares  in BAMM for LUSD + ETH
    function withdraw(uint256 numShares) external;

    /// @notice transfer shares
    function transfer(address to, uint256 amount) external;

    /// @notice swap LUSD to ETH in BAMM
    function swap(uint256 lusdAmount, uint256 minEthReturn, address dest) external returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

// Ref: https://github.com/backstop-protocol/dev/blob/main/packages/contracts/contracts/StabilityPool.sol
interface IStabilityPool {
    function getCompoundedLUSDDeposit(address holder) external view returns(uint256 lusdValue);

    function getDepositorETHGain(address holder) external view returns(uint256 ethValue);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../refs/CoreRef.sol";
import "./IPCVGuardian.sol";
import "./IPCVDeposit.sol";
import "../libs/CoreRefPauseableLib.sol";

contract PCVGuardian is IPCVGuardian, CoreRef {
    using CoreRefPauseableLib for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // If an address is in this set, it's a safe address to withdraw to
    EnumerableSet.AddressSet private safeAddresses;
    
    constructor(
        address _core,
        address[] memory _safeAddresses
    ) CoreRef(_core) {
        _setContractAdminRole(keccak256("PCV_GUARDIAN_ADMIN_ROLE"));

        for (uint256 i = 0; i < _safeAddresses.length; i++) {
            _setSafeAddress(_safeAddresses[i]);
        }
    }

    // ---------- Read-Only API ----------

    /// @notice returns true if the the provided address is a valid destination to withdraw funds to
    /// @param pcvDeposit the address to check
    function isSafeAddress(address pcvDeposit) public view override returns (bool) {
        return safeAddresses.contains(pcvDeposit);
    }

    /// @notice returns all safe addresses
    function getSafeAddresses() public view override returns (address[] memory) {
        return safeAddresses.values();
    }

    // ---------- Governor-or-Admin-Only State-Changing API ----------

    /// @notice governor-only method to set an address as "safe" to withdraw funds to
    /// @param pcvDeposit the address to set as safe
    function setSafeAddress(address pcvDeposit) external override onlyGovernorOrAdmin {
        _setSafeAddress(pcvDeposit);
    }

    /// @notice batch version of setSafeAddress
    /// @param _safeAddresses the addresses to set as safe, as calldata
    function setSafeAddresses(address[] calldata _safeAddresses) external override onlyGovernorOrAdmin {
        require(_safeAddresses.length != 0, "empty");
        for (uint256 i = 0; i < _safeAddresses.length; i++) {
            _setSafeAddress(_safeAddresses[i]);
        }
    }

    // ---------- Governor-or-Admin-Or-Guardian-Only State-Changing API ----------

    /// @notice governor-or-guardian-only method to un-set an address as "safe" to withdraw funds to
    /// @param pcvDeposit the address to un-set as safe
    function unsetSafeAddress(address pcvDeposit) external override isGovernorOrGuardianOrAdmin {
        _unsetSafeAddress(pcvDeposit);
    }

    /// @notice batch version of unsetSafeAddresses
    /// @param _safeAddresses the addresses to un-set as safe
    function unsetSafeAddresses(address[] calldata _safeAddresses) external override isGovernorOrGuardianOrAdmin {
        require(_safeAddresses.length != 0, "empty");
        for (uint256 i = 0; i < _safeAddresses.length; i++) {
            _unsetSafeAddress(_safeAddresses[i]);
        }
    }

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    /// @param safeAddress the destination address to withdraw to
    /// @param amount the amount to withdraw
    /// @param pauseAfter if true, the pcv contract will be paused after the withdraw
    /// @param depositAfter if true, attempts to deposit to the target PCV deposit
    function withdrawToSafeAddress(
        address pcvDeposit,
        address safeAddress,
        uint256 amount,
        bool pauseAfter,
        bool depositAfter
    ) external override isGovernorOrGuardianOrAdmin {
        require(isSafeAddress(safeAddress), "Provided address is not a safe address!");

        pcvDeposit._ensureUnpaused();

        IPCVDeposit(pcvDeposit).withdraw(safeAddress, amount);

        if (pauseAfter) {
            pcvDeposit._pause();
        }

        if (depositAfter) {
            IPCVDeposit(safeAddress).deposit();
        }

        emit PCVGuardianWithdrawal(pcvDeposit, safeAddress, amount);
    }

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    /// @param safeAddress the destination address to withdraw to
    /// @param amount the amount of tokens to withdraw
    /// @param pauseAfter if true, the pcv contract will be paused after the withdraw
    /// @param depositAfter if true, attempts to deposit to the target PCV deposit
    function withdrawETHToSafeAddress(
        address pcvDeposit,
        address payable safeAddress,
        uint256 amount,
        bool pauseAfter,
        bool depositAfter
    ) external override isGovernorOrGuardianOrAdmin {
        require(isSafeAddress(safeAddress), "Provided address is not a safe address!");

        pcvDeposit._ensureUnpaused();

        IPCVDeposit(pcvDeposit).withdrawETH(safeAddress, amount);

        if (pauseAfter) {
            pcvDeposit._pause();
        }

        if (depositAfter) {
            IPCVDeposit(safeAddress).deposit();
        }

        emit PCVGuardianETHWithdrawal(pcvDeposit, safeAddress, amount);
    }

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the deposit to pull funds from
    /// @param safeAddress the destination address to withdraw to
    /// @param amount the amount of funds to withdraw
    /// @param pauseAfter whether to pause the pcv after withdrawing
    /// @param depositAfter if true, attempts to deposit to the target PCV deposit
    function withdrawERC20ToSafeAddress(
        address pcvDeposit,
        address safeAddress,
        address token,
        uint256 amount,
        bool pauseAfter,
        bool depositAfter
    ) external override isGovernorOrGuardianOrAdmin {
        require(isSafeAddress(safeAddress), "Provided address is not a safe address!");

        pcvDeposit._ensureUnpaused();

        IPCVDeposit(pcvDeposit).withdrawERC20(token, safeAddress, amount);

        if (pauseAfter) {
            pcvDeposit._pause();
        }

        if (depositAfter) {
            IPCVDeposit(safeAddress).deposit();
        }

        emit PCVGuardianERC20Withdrawal(pcvDeposit, safeAddress, token, amount);
    }

    // ---------- Internal Functions ----------

    function _setSafeAddress(address anAddress) internal {
        require(safeAddresses.add(anAddress), "set");
        emit SafeAddressAdded(anAddress);
    }

    function _unsetSafeAddress(address anAddress) internal {
        require(safeAddresses.remove(anAddress), "unset");
        emit SafeAddressRemoved(anAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title PauseableLib
/// @notice PauseableLib is a library that can be used to pause and unpause contracts, amont other utilities.
/// @dev This library should only be used on contracts that implement CoreRef.
library CoreRefPauseableLib {
    function _requireUnpaused(address _pausableCoreRefAddress) internal view {
        require(!CoreRef(_pausableCoreRefAddress).paused(), "PausableLib: Address is paused but required to not be paused.");
    }

    function _requirePaused(address _pausableCoreRefAddress) internal view {
        require(CoreRef(_pausableCoreRefAddress).paused(), "PausableLib: Address is not paused but required to be paused.");
    }

    function _ensureUnpaused(address _pausableCoreRefAddress) internal {
        if (CoreRef(_pausableCoreRefAddress).paused()) {
            CoreRef(_pausableCoreRefAddress).unpause();
        }
    }

    function _ensurePaused(address _pausableCoreRefAddress) internal {
        if (!CoreRef(_pausableCoreRefAddress).paused()) {
            CoreRef(_pausableCoreRefAddress).pause();
        }
    }

    function _pause(address _pauseableCoreRefAddress) internal {
        CoreRef(_pauseableCoreRefAddress).pause();
    }
    
    function _unpause(address _pauseableCoreRefAddress) internal {
        CoreRef(_pauseableCoreRefAddress).unpause();
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}