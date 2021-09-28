// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./../utils/Address.sol";
import "./../utils/SafeMath.sol";
import "./../utils/ERC20.sol";
import "./../utils/SafeERC20.sol";
import "./../oracle/AssetOracle.sol";
import "./utils/FundShares.sol";
import "./FundLibrary.sol";
import "./FundDeployer.sol";
import "./../interfaces/IParaswapAugustus.sol";

contract FundLogic is FundShares, FundLibrary{
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public deployer;
    address public manager;
    address public oracle;

    string public fundName;
    string public managerName;

    uint256 public constant MAX_ASSETS = 20;

    mapping(address => uint256) private arbSender;
    mapping(address => uint256) private arbOrigin;

    address public depositAsset;
    uint8 public depositAssetDecimals;
    address[] public activeAssets;
    mapping(address => bool) public isActiveAsset;

    bool private wasInitialized = false;
    bool private firstDeposit;
    bool public managerFeesEnabled;

    uint256 public sharePriceLastFee;
    uint256 public timeLastFee;
    uint256 public PERFORMANCE_FEE;

    address public buybackVault;

    address public PARASWAP_TOKEN_PROXY;
    address public PARASWAP_AUGUSTUS;

    uint256 public minDeposit;
    uint256 public maxDeposit;

    modifier onlyManager() {
        require(msg.sender == manager, "Unauthorized: Only manager");
        _;
    }

    modifier arbProtection() {
        require(arbSender[msg.sender] != block.number, "ARB PROTECTION: msg.sender");
        require(arbOrigin[tx.origin] != block.number, "ARB PROTECTION: tx.origin");
        arbSender[msg.sender] = block.number;
        arbOrigin[tx.origin] = block.number;
        _;
    }

    modifier onlyProxy() {
        bool _genesisFlag;
        assembly {
            // solium-disable-line
            _genesisFlag := sload(0xa7e8032f370433e2cd75389d33b731b61bee456da1b0f7117f2621cbd1fdcf7a)
        }
        require(_genesisFlag == true, "Genesis Logic: Only callable by proxy");
        _;
    }

    modifier depositLimit(uint256 _amount) {
        if(minDeposit > 0) {
            require(_amount > minDeposit, "Deposit too small");
        }

        if(maxDeposit > 0) {
            require(_amount < maxDeposit, "Deposit too big");
        }

        _;
    }

    function init(
        address _oracle,
        address _deployer,
        address _manager,
        string memory _fundName,
        string memory _managerName,
        address _depositAsset,
        uint256 _performanceFee,
        address _paraswapProxy,
        address _paraswapAugustus,
        address _bbvault,
        uint256 _min,
        uint256 _max
    ) public onlyProxy{
        require(!wasInitialized, "Fund already initialized");
        require(_performanceFee <= 10000, "Performance fee too big");
        wasInitialized = true;

        oracle = _oracle;
        deployer = _deployer;
        manager = _manager;
        fundName = _fundName;
        managerName = _managerName;

        _addActiveAsset(_depositAsset);
        depositAsset = _depositAsset;
        depositAssetDecimals = uint8(ERC20(depositAsset).decimals()); // For USDT's non ERC20 compliant functions

        firstDeposit = false;
        timeLastFee = 0;
        PERFORMANCE_FEE = _performanceFee;
        managerFeesEnabled = true;

        PARASWAP_TOKEN_PROXY = _paraswapProxy;
        PARASWAP_AUGUSTUS = _paraswapAugustus;

        buybackVault = _bbvault;

        minDeposit = _min;
        maxDeposit = _max;

        _initializeShares("BotOcean Fund", "BOF");
    }

    function getManager() external view returns (address) {
        return manager;
    }

    function getName() external view returns (string memory) {
        return fundName;
    }

    function getManagerName() external view returns (string memory) {
        return managerName;
    }

    function getBuybackFee() external view returns (uint256,uint256) {
        return FundDeployer(deployer).getBuybackFee();
    }

    function getVersion() external pure returns (string memory) {
        return "v1.0";
    }

    function getIsActiveAsset(address _asset) external view returns (bool) {
        return isActiveAsset[_asset];
    }

    function getActiveAssetsLength() external view returns (uint) {
        return activeAssets.length;
    }

    // Only Manager can call this function to get new paraswap addresses
    // They are fetched from the FundDeployer
    // Migrations are not "automatic" to prevent the FundDeployer's owner ability to create
    // a fake ParaSwap contract and steal funds
    function upgradeParaswap() external onlyManager {
        (address _aug, address _proxy) = FundDeployer(deployer).getParaswapAddresses();

        emit ParaswapUpgrade(
            PARASWAP_TOKEN_PROXY,
            PARASWAP_AUGUSTUS,
            _proxy,
            _aug
        );

        PARASWAP_AUGUSTUS = _aug;
        PARASWAP_TOKEN_PROXY = _proxy;
    }

    // Only Manager can call this function to get new buyback addresse
    // They are fetched from the FundDeployer
    // Migrations are not "automatic" to prevent the FundDeployer's owner ability to create
    // a fake buyback contract and steal funds
    function upgradeBuyBackVault() external onlyManager {
        address _newVault = FundDeployer(deployer).getBuybackVault();
        emit BuybackVaultUpgrade(
            buybackVault,
            _newVault
        );
        buybackVault = _newVault;
    }

    // Only Manager can call this function to get new oracle addresse
    // They are fetched from the FundDeployer
    // Migrations are not "automatic" to prevent the FundDeployer's owner ability to create
    // a fake oracle contract and steal funds
    function upgradeOracle() external onlyManager {
        address _newOracle = FundDeployer(deployer).getOracle();
        emit OracleUpgrade(
            oracle,
            _newOracle
        );
        oracle = _newOracle;
    }

    function changeManager(address _manager, string memory _managerName) external onlyManager {
        emit ManagerUpdated(manager, managerName, _manager, _managerName);
        manager = _manager;
        managerName = _managerName;
    }

    // Sefety function for disabling manager fees in case of emergency withdrawls
    // Manager should only set this to false if _settleFees() fails
    function setManagerFeeEnabled(bool _newStatus) external onlyManager {
        managerFeesEnabled = _newStatus;
    }

    function addActiveAsset(address _asset) external onlyManager {
        _addActiveAsset(_asset);
    }

    function removeActiveAsset(address _asset) external onlyManager {
        address _tempDA  = depositAsset;
        require(_asset != _tempDA, "deposit asset");
        _removeActiveAsset(_asset);
        emit AssetRemoved(_asset);
    }

    function changeDepositLimits(uint256 _minD, uint256 _maxD) external onlyManager {
        minDeposit = _minD;
        maxDeposit = _maxD;
    }

    function changeMinDeposit(uint256 _minDeposit) external onlyManager {
        minDeposit = _minDeposit;
    }

    function changeMaxDeposit(uint256 _maxDeposit) external onlyManager {
        maxDeposit = _maxDeposit;
    }

    function _addActiveAsset(address _asset) internal {
        if(!isActiveAsset[_asset]){
            require(AssetOracle(oracle).isSupportedAsset(_asset), "Asset not supported");
            require(activeAssets.length < MAX_ASSETS, "Max assets reached");
            activeAssets.push(_asset);
            isActiveAsset[_asset] = true;
            emit AssetAdded(_asset);
        }
    }

    function _removeActiveAsset(address _asset) internal {
        if(isActiveAsset[_asset]) {
            require(ERC20(_asset).balanceOf(address(this)) <= 100, "Cannot remove asset with balance");

            isActiveAsset[_asset] = false;
            uint256 _length = activeAssets.length;
            for (uint256 i = 0; i < _length; i++) {
                if (activeAssets[i] == _asset) {
                    if (i < _length - 1) {
                        activeAssets[i] = activeAssets[_length - 1];
                    }
                    activeAssets.pop();
                    break;
                }
            }
        }
    }

    function _getAssetsBalances() internal view returns (uint256[] memory) {
        uint256 _length = activeAssets.length;
        uint256[] memory _bal = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _bal[i] = (ERC20(activeAssets[i]).balanceOf(address(this)));
        }
        
        return _bal;
    }

    function totalValueUSD() public view returns (uint256) {
        uint256[] memory _balances = _getAssetsBalances();
        uint256 _aumUSD = AssetOracle(oracle).aum(activeAssets, _balances);
        return _aumUSD;
    }

    function totalValueDepositAsset() public view returns (uint256) {
        uint256[] memory _balances = _getAssetsBalances();
        uint256 _aumDepositAsset = AssetOracle(oracle).aumDepositAsset(depositAsset, activeAssets, _balances);
        return _aumDepositAsset;
    }

    function sharePriceUSD() public view returns (uint256) {
        uint256 _valueUSD = totalValueUSD(); // 8 decimals
        uint256 _totalSupply = totalSupply(); // 18 decimals

        if(_valueUSD == 0 || _totalSupply == 0) {
            return 0;
        }

        return _valueUSD.mul(1e18).div(_totalSupply);
    }

    function deposit(uint256 _amount) external onlyProxy arbProtection depositLimit(_amount) returns (uint256){
        // Dont't mint fees on first deposit since we do not know the share of a price
        if(firstDeposit){
            _settleFees();
        }

        uint256 depositAssetValue = totalValueDepositAsset();
        uint256 totalShares = totalSupply();

        uint256 _balBefore = ERC20(depositAsset).balanceOf(address(this));
        ERC20(depositAsset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _balAfter = ERC20(depositAsset).balanceOf(address(this));

        // Extra protection
        require(_balAfter.sub(_balBefore) >= _amount, "Incorrect deposit transfer amount");

        uint256 sharesToMint;
        // Deposit asset ranges from 0-18 decimals. Shares are always 18 decimals.
        // This does the conversion
        // AUDIT: VERY VERY IMPORTANT TO CHECK IF EVERYTHING IS RIGHT
        if(totalShares == 0){
            sharesToMint = _amount.mul(1e18);
            sharesToMint = sharesToMint.div(10**uint256(depositAssetDecimals));
        } else {
            uint256 _amount18 = _amount.mul(1e18);
            _amount18 = _amount18.div(10**uint256(depositAssetDecimals));
            uint256 _value18 = depositAssetValue.mul(1e18);
            _value18 = _value18.div(10**uint256(depositAssetDecimals));
            sharesToMint = _amount18.mul(totalShares).div(_value18);
        }

        _mint(msg.sender, sharesToMint);

        if(!firstDeposit){
            firstDeposit = true;
            sharePriceLastFee = sharePriceUSD();
        }

        emit Deposit(
            msg.sender,
            _amount,
            sharesToMint,
            sharePriceUSD(),
            block.timestamp
        );

        return sharesToMint;
    }

    function withdraw(uint256 _sharesAmount) external onlyProxy arbProtection {
        require(balanceOf(msg.sender) >= _sharesAmount, "Not enough shares");

        // Dont't mint fees on first deposit since we do not know the share of a price
        if(firstDeposit){
            _settleFees();
        }

        // Deposit asset ranges from 0-18 decimals. Shares are always 18 decimals.
        // This does the conversion
        // AUDIT: VERY VERY IMPORTANT TO CHECK IF EVERYTHING IS RIGHT
        uint256 _ownership = _sharesAmount.mul(1e18).div(totalSupply());

        _burn(msg.sender, _sharesAmount);

        uint256 _length = activeAssets.length;
        for(uint256 i = 0; i < _length; i++) {
            uint256 _totalBal = ERC20(activeAssets[i]).balanceOf(address(this));
            // Deposit asset ranges from 0-18 decimals. Shares are always 18 decimals.
            // This does the conversion
            // AUDIT: VERY VERY IMPORTANT TO CHECK IF EVERYTHING IS RIGHT
            uint256 _withdrawAmount = _totalBal.mul(_ownership).div(1e18);

            if(_withdrawAmount > 0) {
                ERC20(activeAssets[i]).safeTransfer(msg.sender, _withdrawAmount);
            }               
        }

        emit Withdraw(
            msg.sender,
            _sharesAmount,
            sharePriceUSD(),
            block.timestamp
        );
    }

    function _swap(address _src, address _dst, uint256 _amount, uint256 _toAmount, uint256 _expectedAmount, IParaswapAugustus.Path[] memory _path) internal returns (uint256){
        require(ERC20(_src).balanceOf(address(this)) >= _amount, "Not enough tokens");
        uint256 _before = ERC20(_dst).balanceOf(address(this));
        // TODO: SWAP
        ERC20(_src).safeApprove(PARASWAP_TOKEN_PROXY, 0);
        ERC20(_src).safeApprove(PARASWAP_TOKEN_PROXY, _amount);

        IParaswapAugustus.SellData memory swapData = IParaswapAugustus.SellData({
            fromToken: _src,
            fromAmount: _amount,
            toAmount: _toAmount,
            expectedAmount: _expectedAmount,
            beneficiary: payable(address(this)),
            referrer: "BOTOCEAN",
            useReduxToken: false,
            path: _path
        });

        IParaswapAugustus(PARASWAP_AUGUSTUS).multiSwap(swapData);

        uint256 _after = ERC20(_dst).balanceOf(address(this));

        emit Swap(
            _src,
            _dst,
            _amount,
            _after.sub(_before),
            block.timestamp
        );

        return _after.sub(_before);
    }

    // The path will be made available from Paraswap's param transaction builder API.
    function swap(address _src, address _dst, uint256 _amount, uint256 _toAmount, uint256 _expectedAmount, IParaswapAugustus.Path[] memory _path) external onlyManager {
        require(_src != _dst, "same asset");
        require(isActiveAsset[_src], "Unknown asset");
        if(!isActiveAsset[_dst]) {
            _addActiveAsset(_dst);
        }
        uint256 _swapAmount = _amount;
        uint256 _myBal = ERC20(_src).balanceOf(address(this));
        if(_myBal < _swapAmount) {
            _swapAmount = _myBal;
        }

        // Other Checks

        // Swap
        _swap(_src, _dst, _swapAmount, _toAmount, _expectedAmount, _path);
    }

    function _settleFees() internal {
        if(managerFeesEnabled && PERFORMANCE_FEE > 0){
            uint256 feeWaitTime = FundDeployer(deployer).getFeeWaitPeriod();
            uint256 _currentSharePrice = sharePriceUSD();
            uint256 _totalSupply = totalSupply();

            uint256 _buybackFee;
            uint256 _buybackFeeMax;
            (_buybackFee, _buybackFeeMax) = FundDeployer(deployer).getBuybackFee();

            if(timeLastFee.add(feeWaitTime) > block.timestamp) {
                return;
            }

            if(_currentSharePrice == 0 || _currentSharePrice < sharePriceLastFee) {
                return;
            }

            // Calculate fees
            uint256 profitUSD = _currentSharePrice.sub(sharePriceLastFee).mul(_totalSupply).div(1e18);
            if(profitUSD < 100000) { // If profit smaller than $0.001, don't mint fees
                return;
            }
            uint256 managerFeeUSD = profitUSD.mul(PERFORMANCE_FEE).div(10000);
            uint256 managerFeeShares = managerFeeUSD.mul(1e18).div(_currentSharePrice);
            uint256 buybackShares = managerFeeShares.mul(_buybackFee).div(_buybackFeeMax);
            managerFeeShares = managerFeeShares.sub(buybackShares);

            // Mint fees
            _mint(buybackVault, buybackShares);
            _mint(manager, managerFeeShares);

            // Emit event
            uint256 newSharePrice = sharePriceUSD();
            emit FeeMinted(
                sharePriceLastFee,
                newSharePrice,
                profitUSD,
                buybackShares,
                managerFeeShares,
                block.timestamp
            );

            // Update values
            sharePriceLastFee = newSharePrice;
            timeLastFee = block.timestamp;
        }
    }

    function settleFees() external onlyManager {
        require(firstDeposit, "Cannot mint fees before first deposit");
        _settleFees();
    }

    function getFundLogic() public view returns (address) {
        address _impl;
        assembly {
            // solium-disable-line
            _impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }

        return _impl;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Context.sol";
import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public owner;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./../utils/Address.sol";
import "./../utils/SafeMath.sol";
import "./../utils/ERC20.sol";
import "./chainlink/AggregatorV3Interface.sol";

contract AssetOracle {
    using SafeMath for uint256;
    using Address for address;

    address public owner;

    mapping(address => address) private assetTokenFeed;
    address[] public supportedAssets;

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized: owner only");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function isSupportedAsset(address _asset) external view returns (bool) {
        return assetTokenFeed[_asset] != address(0);
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function _addSupportedAsset(address _asset, address _priceFeed) internal {
        uint8 _decs = AggregatorV3Interface(_priceFeed).decimals();
        // If decimals is not 8, price calculation vuln will occur
        require(_decs == 8, "Not USD feed");

        uint8 _ercDecs = ERC20(_asset).decimals();
        require(_ercDecs <= 18, "Logic not implemented for assets with decimals > 18");
        assetTokenFeed[_asset] = _priceFeed;
        supportedAssets.push(_asset);
    }

    function addSupportedAssets(address[] memory _assets, address[] memory _priceFeeds) external onlyOwner {
        require(_assets.length == _priceFeeds.length, "Not equal arrays");
        uint256 _length = _assets.length;

        for(uint256 i = 0; i < _length; i++) {
            _addSupportedAsset(_assets[i], _priceFeeds[i]);
        }
    }

    // Returns USD value of asset with 8 decimals
    function _assetValue(address _asset, uint256 _amount) internal view returns (uint256) {
        if(assetTokenFeed[_asset] == address(0)) {
            // Safe fail for unknown assets
            return 0;
        }
        (, int price, , ,) = AggregatorV3Interface(assetTokenFeed[_asset]).latestRoundData();
        uint8 assetDecimals = ERC20(_asset).decimals();
        uint256 finalValue = uint256(price).mul(_amount).div(10**uint256(assetDecimals));
        return finalValue;
    }

    function assetValue(address _asset, uint256 _amount) external view returns (uint256) {
        return _assetValue(_asset, _amount);
    }

    function aum(address[] memory _assets, uint256[] memory _amounts) public view returns (uint256) {
        require(_assets.length == _amounts.length, "Not equal arrays");
        uint256 _length = _assets.length;

        uint256 _aum = 0;
        for(uint256 i = 0; i < _length; i++) {
            _aum = _aum.add(_assetValue(_assets[i], _amounts[i]));
        }

        return _aum;
    }

    function aumDepositAsset(address _depositAsset, address[] memory _assets, uint256[] memory _amounts) external view returns (uint256) {
        if(assetTokenFeed[_depositAsset] == address(0)) {
            // Safe fail for unknown assets
            return 0;
        }

        uint256 _aumUSD = aum(_assets, _amounts); // 8 decimals
        (, int price, , ,) = AggregatorV3Interface(assetTokenFeed[_depositAsset]).latestRoundData(); // 8 decimals
        uint8 _decimalsDepositAsset = ERC20(_depositAsset).decimals();
        uint256 _aumDepositAsset = _aumUSD.mul(10**uint256(_decimalsDepositAsset)).div(uint256(price));
        return _aumDepositAsset;
    }

    function getSupportedAssetsLength() external view returns (uint) {
        return supportedAssets.length;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IParaswapAugustus {
    struct Route {
        address payable exchange;
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;
        Route[] routes;
    }

    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Path[] path;
    }

    function multiSwap(SellData calldata) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ILockedOwner {
    function burnTokens(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./../../utils/SafeMath.sol";
import "./../../interfaces/IERC20.sol";

abstract contract FundShares {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 private _decimals = 18;

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

    function _initializeShares(string memory shareName, string memory shareSymbol) internal {
        _name = shareName;
        _symbol = shareSymbol;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// https://eips.ethereum.org/EIPS/eip-1822
contract FundProxy {
    constructor(bytes memory _constructData, address _fundLogic) public {
        assembly {
            // solium-disable-line
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _fundLogic)
            // Genesis proxy flag
            sstore(0xa7e8032f370433e2cd75389d33b731b61bee456da1b0f7117f2621cbd1fdcf7a, true)
        }

        (bool success, bytes memory returnData) = _fundLogic.delegatecall(_constructData);
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract FundLibrary {
    event Deposit(
        address depositor,
        uint256 depositAmount,
        uint256 sharesEmitted,
        uint256 sharePrice,
        uint256 timestamp
    );

    event Swap(
        address from,
        address to,
        uint256 amount,
        uint256 receivedAmount,
        uint256 timestamp
    );

    event Withdraw(
        address withdrawer,
        uint256 sharesWithdrew,
        uint256 sharePrice,
        uint256 timestamp
    );

    event ManagerUpdated(
        address oldManager,
        string oldName,
        address newManager,
        string newName
    );

    event AssetAdded(
        address asset
    );

    event AssetRemoved(
        address asset
    );

    event ParaswapUpgrade(
        address oldParaswapProxy,
        address oldParaswapAugustus,
        address newParaswapProxy,
        address newParaswapAugustus
    );

    event BuybackVaultUpgrade(
        address oldVault,
        address newVault
    );

    event OracleUpgrade(
        address oldOracle,
        address newOracle
    );

    event FeeMinted(
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 profitUSD,
        uint256 sharesBuybackMinted,
        uint256 sharesManagerMinted,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./../utils/Address.sol";
import "./../utils/SafeMath.sol";
import "./../utils/ERC20.sol";
import "./../utils/SafeERC20.sol";

import "./FundProxy.sol";
import "./FundLogic.sol";
import "./../buyback/BuybackVault.sol";

contract FundDeployer {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20;

    address public owner;
    address public oracle;

    uint256 public BUYBACK_FEE;
    uint256 public constant BUYBACK_FEE_MAX = 10000;

    uint256 public MAX_PERFORMANCE_FEE_ALLOWED = 5000;

    address public PARASWAP_TOKEN_PROXY;
    address public PARASWAP_AUGUSTUS;

    uint256 public feeWaitPeriod = 1 days;

    address public buybackVault;

    address public fundLogic;

    address[] public deployedFunds;
    mapping(address => bool) isDeployedFund;

    event FundDeployed(
        address fund,
        string fundName,
        string managerName,
        address depositAsset,
        address manager,
        uint256 timestamp
    );

    event OwnerUpdate(
        address oldOwner,
        address newOwner
    );

    event OracleUpdate(
        address oldOracle,
        address newOracle
    );

    event LogicUpdate(
        address oldLogic,
        address newLogic
    );

    event BuybackFeeUpdate(
        uint256 oldFee,
        uint256 newFee
    );

    event BuybackVaultUpdate(
        address oldVault,
        address newVault
    );

    event ParaswapUpdate(
        address oldParaswapProxy,
        address oldParaswapAugustus,
        address newParaswapProxy,
        address newParaswapAugustus
    );

    event MaxPerformanceFeeUpdate(
        uint256 oldMaxPerformanceFeeAllowed,
        uint256 newMaxPerformanceFeeAllowed
    );

    event FeeWaitPeriodChange(
        uint256 oldFeeWaitPeriod,
        uint256 newFeeWaitPeriod
    );

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized: Only owner");
        _;
    }

    constructor(
        address _oracle,
        uint256 _buybackFee,
        address _paraswapProxy,
        address _paraswapAugustus,
        address _bbvault,
        address _fundLogic
    ) public {
        owner = msg.sender;
        oracle = _oracle;
        BUYBACK_FEE = _buybackFee;
        PARASWAP_TOKEN_PROXY = _paraswapProxy;
        PARASWAP_AUGUSTUS = _paraswapAugustus;
        buybackVault = _bbvault;
        fundLogic = _fundLogic;
    }

    function changeOwner(address _owner) external onlyOwner {
        emit OwnerUpdate(owner, _owner);
        owner = _owner;
    }

    function changeOracle(address _oracle) external onlyOwner {
        emit OracleUpdate(oracle, _oracle);
        oracle = _oracle;
    }

    function changeLogic(address _newLogic) external onlyOwner {
        emit LogicUpdate(fundLogic, _newLogic);
        fundLogic = _newLogic;
    }

    function changeFeeWaitPeriod(uint256 _newPeriod) external onlyOwner {
        emit FeeWaitPeriodChange(feeWaitPeriod, _newPeriod);
        feeWaitPeriod = _newPeriod;
    }

    function changeBuybackFee(uint256 _newFee) external onlyOwner {
        // Ensure our users we will never set an extremly high buy back fee
        require(_newFee <= 5000, "Buyback fee too big");
        emit BuybackFeeUpdate(BUYBACK_FEE, _newFee);
        BUYBACK_FEE = _newFee;
    }

    function changeBuybackVault(address _newVault) external onlyOwner {
        emit BuybackVaultUpdate(buybackVault, _newVault);
        buybackVault = _newVault;
    }

    function changeMaxPerformanceFeeAllowed(uint256 _newMax) external onlyOwner {
        require (_newMax < 10000, "Max performance fee allowed too big");
        emit MaxPerformanceFeeUpdate(MAX_PERFORMANCE_FEE_ALLOWED, _newMax);
        MAX_PERFORMANCE_FEE_ALLOWED = _newMax;
    }

    function upgradeParaswap(address _paraProxy, address _paraAugustus) external onlyOwner {
        emit ParaswapUpdate(PARASWAP_TOKEN_PROXY, PARASWAP_AUGUSTUS, _paraProxy, _paraAugustus);
        PARASWAP_TOKEN_PROXY = _paraProxy;
        PARASWAP_AUGUSTUS = _paraAugustus;
    }

    function getBuybackFee() external view returns (uint256,uint256) {
        return (BUYBACK_FEE, BUYBACK_FEE_MAX);
    }

    function getParaswapAddresses() external view returns (address,address) {
        return (PARASWAP_AUGUSTUS, PARASWAP_TOKEN_PROXY);
    }

    function getBuybackVault() external view returns (address) {
        return buybackVault;
    }

    function getOracle() external view returns (address) {
        return oracle;
    }

    function getDeployedFunds() external view returns (address[] memory) {
        return deployedFunds;
    }

    function getFundLogic() external view returns (address) {
        return fundLogic;
    }

    function getFeeWaitPeriod() external view returns (uint256) {
        return feeWaitPeriod;
    }

    function addressIsFund(address _fund) external view returns (bool) {
        return isDeployedFund[_fund];
    }

    function deployFund(
        string memory _fundName,
        string memory _managerName,
        address _depositAsset,
        uint256 _performanceFee,
        uint256 _minDeposit,
        uint256 _maxDeposit
    ) external returns (address) {
        require(_performanceFee <= MAX_PERFORMANCE_FEE_ALLOWED, "Performance fee too big");
        // _depositAsset will be validated when the fund is created

        bytes memory constructData = abi.encodeWithSignature(
            "init(address,address,address,string,string,address,uint256,address,address,address,uint256,uint256)",
            oracle,
            address(this),
            msg.sender,
            _fundName,
            _managerName,
            _depositAsset,
            _performanceFee,
            PARASWAP_TOKEN_PROXY,
            PARASWAP_AUGUSTUS,
            buybackVault,
            _minDeposit,
            _maxDeposit
        );

        address _fundProxy = address(new FundProxy(constructData, fundLogic));

        require(FundLogic(_fundProxy).getFundLogic() == fundLogic && FundLogic(_fundProxy).getManager() == msg.sender, "FundProxy creation failed");

        deployedFunds.push(_fundProxy);
        isDeployedFund[_fundProxy] = true;
        BuybackVault(buybackVault).addFund(_fundProxy);

        emit FundDeployed(
            _fundProxy,
            _fundName,
            _managerName,
            _depositAsset,
            msg.sender,
            block.timestamp
        );

        // Alert buyback vault with new fund

        return _fundProxy;
    }

    function getRegisteredFundsLength() external view returns (uint) {
        return deployedFunds.length;
    }

    function getIsDeployedFund(address _fund) external view returns (bool) {
        return isDeployedFund[_fund];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./../utils/SafeMath.sol";
import "./../utils/Address.sol";
import "./../utils/ERC20.sol";
import "./../utils/SafeERC20.sol";
import "./../interfaces/IParaswapAugustus.sol";
import "./../interfaces/IUniswapV2Router02.sol";
import "./../interfaces/ILockedOwner.sol";

import "./../fund/FundLogic.sol";

contract BuybackVault {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20;

    address public fundDeployer;
    address public owner;

    address[] public deployedFunds;
    mapping(address => bool) isDeployedFund;

    address public PARASWAP_TOKEN_PROXY;
    address public PARASWAP_AUGUSTUS;
    address public UNISWAP_ROUTER;

    address public BOTS;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == fundDeployer || msg.sender == owner, "Unauthorized");
        _;
    }

    constructor(
        address _paraswapProxy,
        address _paraswapAugustus,
        address _uniRouter,
        address _bots
    ) public {
        owner = msg.sender;
        PARASWAP_TOKEN_PROXY = _paraswapProxy;
        PARASWAP_AUGUSTUS = _paraswapAugustus;
        UNISWAP_ROUTER = _uniRouter;
        BOTS = _bots;
    }

    function changeDeployer(address _newDeployer) external onlyOwner {
        fundDeployer = _newDeployer;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeParaswap(address _newProxy, address _newAugustus) external onlyOwner {
        PARASWAP_TOKEN_PROXY = _newProxy;
        PARASWAP_AUGUSTUS = _newAugustus;
    }

    function changeUniswap(address _newRouter) external onlyOwner {
        UNISWAP_ROUTER = _newRouter;
    }

    function changeBots(address _newBOTS) external onlyOwner {
        BOTS = _newBOTS;
    }

    function addFund(address _vaultProxy) external onlyDeployer {
        if(!isDeployedFund[_vaultProxy]){
            isDeployedFund[_vaultProxy] = true;
            deployedFunds.push(_vaultProxy);
        }
    }

    function removeFund(address _vaultProxy) external onlyDeployer {
        if(isDeployedFund[_vaultProxy]){
            isDeployedFund[_vaultProxy] = false;
            uint256 _length = deployedFunds.length;
            for (uint256 i = 0; i < _length; i++) {
                if (deployedFunds[i] == _vaultProxy) {
                    if (i < _length - 1) {
                        deployedFunds[i] = deployedFunds[_length - 1];
                    }
                    deployedFunds.pop();
                    break;
                }
            }
        }
    }

    function withdrawFromFund(address _fundProxy, uint256 _sharesAmount) public onlyOwner {
        uint256 _myBal = FundLogic(_fundProxy).balanceOf(address(this));
        if(_sharesAmount > _myBal || _sharesAmount == 0){
            _sharesAmount = _myBal;
        }

        // Soft fail
        if(_sharesAmount > 0){
            FundLogic(_fundProxy).withdraw(_sharesAmount);
        }
    }

    function withdrawFromFunds(address[] memory _funds) public onlyOwner {
        uint256 _length = _funds.length;
        for(uint256 i = 0; i < _length; i++){
            withdrawFromFund(_funds[i], 0); // Withdraw all
        }
    }

    function withdrawAllFunds() external onlyOwner {
        withdrawFromFunds(deployedFunds);
    }

    function paraswapSwap(address _src, uint256 _amount, uint256 _toAmount, uint256 _expectedAmount, IParaswapAugustus.Path[] memory _path) public onlyOwner {
        uint256 _srcBal = ERC20(_src).balanceOf(address(this));
        if(_srcBal < _amount || _amount == 0){
            _amount = _srcBal;
        }
        
        ERC20(_src).safeApprove(PARASWAP_TOKEN_PROXY, 0);
        ERC20(_src).safeApprove(PARASWAP_TOKEN_PROXY, _amount);

        IParaswapAugustus.SellData memory swapData = IParaswapAugustus.SellData({
            fromToken: _src,
            fromAmount: _amount,
            toAmount: _toAmount,
            expectedAmount: _expectedAmount,
            beneficiary: payable(address(this)),
            referrer: "BOTOCEAN",
            useReduxToken: false,
            path: _path
        });

        IParaswapAugustus(PARASWAP_AUGUSTUS).multiSwap(swapData);
    }

    function uniswapSwap(uint256 _amount, uint256 _toMinAmount, address[] memory _path) public onlyOwner {
        address _src = _path[0];
        uint256 _srcBal = ERC20(_src).balanceOf(address(this));
        if(_srcBal < _amount || _amount == 0){
            _amount = _srcBal;
        }

        ERC20(_src).safeApprove(UNISWAP_ROUTER, _amount);
        uint256 expTime = uint256(block.timestamp).add(uint256(1 days));

        IUniswapV2Router02(UNISWAP_ROUTER).swapExactTokensForTokens(
            _amount,
            _toMinAmount,
            _path,
            address(this),
            expTime
        );
    }

    function burnBOTS() external onlyOwner {
        uint256 _botsBal = ERC20(BOTS).balanceOf(address(this));
        address botsOwner = ERC20(BOTS).owner();
        ILockedOwner(botsOwner).burnTokens(_botsBal);
    }

    // Only used if burnBOTS fails
    function manualBurnBOTS() external onlyOwner {
        uint256 _botsBal = ERC20(BOTS).balanceOf(address(this));
        ERC20(BOTS).safeTransfer(address(0x0000000000000000000000000000000000000001), _botsBal);
    }

    function getRegisteredFundsLength() external view returns (uint) {
        return deployedFunds.length;
    }

    function getIsDeployedFund(address _fund) external view returns (bool) {
        return isDeployedFund[_fund];
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 26000
  },
  "evmVersion": "byzantium",
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