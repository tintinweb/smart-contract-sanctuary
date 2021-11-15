pragma solidity ^0.6.0;

import "../utils/GasBurner.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";

import "../utils/SafeERC20.sol";

/// @title Basic compound interactions through the DSProxy
contract AaveBasicProxy is GasBurner {

    using SafeERC20 for ERC20;

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AAVE_LENDING_POOL_ADDRESSES = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

    uint16 public constant AAVE_REFERRAL_CODE = 64;

    /// @notice User deposits tokens to the Aave protocol
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _amount Amount of tokens to be deposited
    function deposit(address _tokenAddr, uint256 _amount) public burnGas(5) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint ethValue = _amount;

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
            approveToken(_tokenAddr, lendingPoolCore);
            ethValue = 0;
        }

        ILendingPool(lendingPool).deposit{value: ethValue}(_tokenAddr, _amount, AAVE_REFERRAL_CODE);

        setUserUseReserveAsCollateralIfNeeded(_tokenAddr);
    }

    /// @notice User withdraws tokens from the Aave protocol
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _aTokenAddr ATokens to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn
    /// @param _wholeAmount If true we will take the whole amount on chain
    function withdraw(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeAmount) public burnGas(8) {
        uint256 amount = _wholeAmount ? ERC20(_aTokenAddr).balanceOf(address(this)) : _amount;

        IAToken(_aTokenAddr).redeem(amount);

        withdrawTokens(_tokenAddr);
    }

    /// @notice User borrows tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    /// @param _type Send 1 for stable rate and 2 for variable rate
    function borrow(address _tokenAddr, uint256 _amount, uint256 _type) public burnGas(8) {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).borrow(_tokenAddr, _amount, _type, AAVE_REFERRAL_CODE);

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _aTokenAddr ATokens to be paybacked
    /// @param _amount Amount of tokens to be payed back
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function payback(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeDebt) public burnGas(3) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint256 amount = _amount;

        (,uint256 borrowAmount,,,,,uint256 originationFee,,,) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, address(this));

        if (_wholeDebt) {
            amount = borrowAmount + originationFee;
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
            approveToken(_tokenAddr, lendingPoolCore);
        }

        ILendingPool(lendingPool).repay{value: msg.value}(_tokenAddr, amount, payable(address(this)));

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _aTokenAddr ATokens to be paybacked
    /// @param _amount Amount of tokens to be payed back
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function paybackOnBehalf(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeDebt, address payable _onBehalf) public burnGas(3) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint256 amount = _amount;

        (,uint256 borrowAmount,,,,,uint256 originationFee,,,) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, _onBehalf);

        if (_wholeDebt) {
            amount = borrowAmount + originationFee;
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
            approveToken(_tokenAddr, lendingPoolCore);
        }

        ILendingPool(lendingPool).repay{value: msg.value}(_tokenAddr, amount, _onBehalf);

        withdrawTokens(_tokenAddr);
    }

    /// @notice Helper method to withdraw tokens from the DSProxy
    /// @param _tokenAddr Address of the token to be withdrawn
    function withdrawTokens(address _tokenAddr) public {
        uint256 amount = _tokenAddr == ETH_ADDR ? address(this).balance : ERC20(_tokenAddr).balanceOf(address(this));

        if (amount > 0) {
            if (_tokenAddr != ETH_ADDR) {
                ERC20(_tokenAddr).safeTransfer(msg.sender, amount);
            } else {
                msg.sender.transfer(amount);
            }
        }
    }

    /// @notice Approves token contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _caller Address which will gain the approval
    function approveToken(address _tokenAddr, address _caller) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeApprove(_caller, uint256(-1));
        }
    }

    function setUserUseReserveAsCollateralIfNeeded(address _tokenAddr) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        (,,,,,,,,,bool collateralEnabled) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, address(this));

        if (!collateralEnabled) {
            ILendingPool(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, true);
        }
    }

    function setUserUseReserveAsCollateral(address _tokenAddr, bool _true) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, _true);
    }

    function swapBorrowRateMode(address _reserve) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).swapBorrowRateMode(_reserve);
    }
}

pragma solidity ^0.6.0;

import "../interfaces/GasTokenInterface.sol";

contract GasBurner {
    // solhint-disable-next-line const-name-snakecase
    GasTokenInterface public constant gasToken = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    modifier burnGas(uint _amount) {
        if (gasToken.balanceOf(address(this)) >= _amount) {
            gasToken.free(_amount);
        }

        _;
    }
}

pragma solidity ^0.6.0;

abstract contract IAToken {
    function redeem(uint256 _amount) external virtual;
    function balanceOf(address _owner) external virtual view returns (uint256 balance);
}

pragma solidity ^0.6.0;

abstract contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external virtual;
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external virtual payable;
	function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external virtual;
	function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external virtual;
	function repay( address _reserve, uint256 _amount, address payable _onBehalfOf) external virtual payable;
	function swapBorrowRateMode(address _reserve) external virtual;
    function getReserves() external virtual view returns(address[] memory);

    /// @param _reserve underlying token address
    function getReserveData(address _reserve)
        external virtual
        view
        returns (
            uint256 totalLiquidity,               // reserve total liquidity
            uint256 availableLiquidity,           // reserve available liquidity for borrowing
            uint256 totalBorrowsStable,           // total amount of outstanding borrows at Stable rate
            uint256 totalBorrowsVariable,         // total amount of outstanding borrows at Variable rate
            uint256 liquidityRate,                // current deposit APY of the reserve for depositors, in Ray units.
            uint256 variableBorrowRate,           // current variable rate APY of the reserve pool, in Ray units.
            uint256 stableBorrowRate,             // current stable rate APY of the reserve pool, in Ray units.
            uint256 averageStableBorrowRate,      // current average stable borrow rate
            uint256 utilizationRate,              // expressed as total borrows/total liquidity.
            uint256 liquidityIndex,               // cumulative liquidity index
            uint256 variableBorrowIndex,          // cumulative variable borrow index
            address aTokenAddress,                // aTokens contract address for the specific _reserve
            uint40 lastUpdateTimestamp            // timestamp of the last update of reserve data
        );

    /// @param _user users address
    function getUserAccountData(address _user)
        external virtual
        view
        returns (
            uint256 totalLiquidityETH,            // user aggregated deposits across all the reserves. In Wei
            uint256 totalCollateralETH,           // user aggregated collateral across all the reserves. In Wei
            uint256 totalBorrowsETH,              // user aggregated outstanding borrows across all the reserves. In Wei
            uint256 totalFeesETH,                 // user aggregated current outstanding fees in ETH. In Wei
            uint256 availableBorrowsETH,          // user available amount to borrow in ETH
            uint256 currentLiquidationThreshold,  // user current average liquidation threshold across all the collaterals deposited
            uint256 ltv,                          // user average Loan-to-Value between all the collaterals
            uint256 healthFactor                  // user current Health Factor
    );

    /// @param _reserve underlying token address
    /// @param _user users address
    function getUserReserveData(address _reserve, address _user)
        external virtual
        view
        returns (
            uint256 currentATokenBalance,         // user current reserve aToken balance
            uint256 currentBorrowBalance,         // user current reserve outstanding borrow balance
            uint256 principalBorrowBalance,       // user balance of borrowed asset
            uint256 borrowRateMode,               // user borrow rate mode either Stable or Variable
            uint256 borrowRate,                   // user current borrow rate APY
            uint256 liquidityRate,                // user current earn rate on _reserve
            uint256 originationFee,               // user outstanding loan origination fee
            uint256 variableBorrowIndex,          // user variable cumulative index
            uint256 lastUpdateTimestamp,          // Timestamp of the last data update
            bool usageAsCollateralEnabled         // Whether the user's current reserve is enabled as a collateral
    );

    function getReserveConfigurationData(address _reserve)
        external virtual
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address rateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
    );

    // ------------------ LendingPoolCoreData ------------------------
    function getReserveATokenAddress(address _reserve) public virtual view returns (address);
    function getReserveConfiguration(address _reserve)
        external virtual
        view
        returns (uint256, uint256, uint256, bool);
    function getUserUnderlyingAssetBalance(address _reserve, address _user)
        public virtual
        view
        returns (uint256);

    function getReserveCurrentLiquidityRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveCurrentVariableBorrowRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveCurrentStableBorrowRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveTotalLiquidity(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveAvailableLiquidity(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveTotalBorrowsVariable(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveTotalBorrowsStable(address _reserve)
        public virtual
        view
        returns (uint256);

    // ---------------- LendingPoolDataProvider ---------------------
    function calculateUserGlobalData(address _user)
        public virtual
        view
        returns (
            uint256 totalLiquidityBalanceETH,
            uint256 totalCollateralBalanceETH,
            uint256 totalBorrowBalanceETH,
            uint256 totalFeesETH,
            uint256 currentLtv,
            uint256 currentLiquidationThreshold,
            uint256 healthFactor,
            bool healthFactorBelowThreshold
        );
}

pragma solidity ^0.6.0;

/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */
abstract contract ILendingPoolAddressesProvider {

    function getLendingPool() public virtual view returns (address);
    function getLendingPoolCore() public virtual view returns (address payable);
    function getLendingPoolConfigurator() public virtual view returns (address);
    function getLendingPoolDataProvider() public virtual view returns (address);
    function getLendingPoolParametersProvider() public virtual view returns (address);
    function getTokenDistributor() public virtual view returns (address);
    function getFeeProvider() public virtual view returns (address);
    function getLendingPoolLiquidationManager() public virtual view returns (address);
    function getLendingPoolManager() public virtual view returns (address);
    function getPriceOracle() public virtual view returns (address);
    function getLendingRateOracle() public virtual view returns (address);
}

pragma solidity ^0.6.0;

import "../interfaces/ERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";

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

pragma solidity ^0.6.0;

import "./ERC20.sol";

abstract contract GasTokenInterface is ERC20 {
    function free(uint256 value) public virtual returns (bool success);

    function freeUpTo(uint256 value) public virtual returns (uint256 freed);

    function freeFrom(address from, uint256 value) public virtual returns (bool success);

    function freeFromUpTo(address from, uint256 value) public virtual returns (uint256 freed);
}

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

pragma solidity ^0.6.0;

import "../interfaces/DSProxyInterface.sol";
import "./SafeERC20.sol";

/// @title Pulls a specified amount of tokens from the EOA owner account to the proxy
contract PullTokensProxy {
    using SafeERC20 for ERC20;

    /// @notice Pulls a token from the proxyOwner -> proxy
    /// @dev Proxy owner must first give approve to the proxy address
    /// @param _tokenAddr Address of the ERC20 token
    /// @param _amount Amount of tokens which will be transfered to the proxy
    function pullTokens(address _tokenAddr, uint _amount) public {
        address proxyOwner = DSProxyInterface(address(this)).owner();

        ERC20(_tokenAddr).safeTransferFrom(proxyOwner, address(this), _amount);
    }
}

pragma solidity ^0.6.0;


abstract contract DSProxyInterface {

    /// Truffle wont compile if this isn't commented
    // function execute(bytes memory _code, bytes memory _data)
    //     public virtual
    //     payable
    //     returns (address, bytes32);

    function execute(address _target, bytes memory _data) public virtual payable returns (bytes32);

    function setCache(address _cacheAddr) public virtual payable returns (bool);

    function owner() public virtual returns (address);
}

pragma solidity ^0.6.0;

import "../auth/Auth.sol";
import "../interfaces/DSProxyInterface.sol";

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

contract DFSProxy is Auth {
    string public constant NAME = "DFSProxy";
    string public constant VERSION = "v0.1";

    mapping(address => mapping(uint => bool)) public nonces;

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("callProxy(address _user,address _proxy,address _contract,bytes _txData,uint256 _nonce)");

    constructor(uint256 chainId_) public {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(NAME)),
            keccak256(bytes(VERSION)),
            chainId_,
            address(this)
        ));
    }

    function callProxy(address _user, address _proxy, address _contract, bytes calldata _txData, uint256 _nonce,
                    uint8 _v, bytes32 _r, bytes32 _s) external payable onlyAuthorized
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     _user,
                                     _proxy,
                                     _contract,
                                     _txData,
                                     _nonce))
        ));

        // user must be proxy owner
        require(DSProxyInterface(_proxy).owner() == _user);
        require(_user == ecrecover(digest, _v, _r, _s), "DFSProxy/user-not-valid");
        require(!nonces[_user][_nonce], "DFSProxy/invalid-nonce");
        
        nonces[_user][_nonce] = true;

        DSProxyInterface(_proxy).execute{value: msg.value}(_contract, _txData);
    }
}

pragma solidity ^0.6.0;

import "./AdminAuth.sol";

contract Auth is AdminAuth {

	bool public ALL_AUTHORIZED = false;

	mapping(address => bool) public authorized;

	modifier onlyAuthorized() {
        require(ALL_AUTHORIZED || authorized[msg.sender]);
        _;
    }

	constructor() public {
		authorized[msg.sender] = true;
	}

	function setAuthorized(address _user, bool _approved) public onlyOwner {
		authorized[_user] = _approved;
	}

	function setAllAuthorized(bool _authorized) public onlyOwner {
		ALL_AUTHORIZED = _authorized;
	}
}

pragma solidity ^0.6.0;

import "../utils/SafeERC20.sol";

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
        admin = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9;
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

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ILendingPool.sol";
import "../interfaces/CTokenInterface.sol";
import "../interfaces/ILoanShifter.sol";
import "../interfaces/DSProxyInterface.sol";
import "../interfaces/Vat.sol";
import "../interfaces/Manager.sol";
import "../interfaces/IMCDSubscriptions.sol";
import "../interfaces/ICompoundSubscriptions.sol";
import "../auth/AdminAuth.sol";
import "../auth/ProxyPermission.sol";
import "../exchangeV3/DFSExchangeData.sol";
import "./ShifterRegistry.sol";
import "../utils/GasBurner.sol";
import "../loggers/DefisaverLogger.sol";


/// @title LoanShifterTaker Entry point for using the shifting operation
contract LoanShifterTaker is AdminAuth, ProxyPermission, GasBurner {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant MCD_SUB_ADDRESS = 0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a;
    address public constant COMPOUND_SUB_ADDRESS = 0x52015EFFD577E08f498a0CCc11905925D58D6207;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    Manager public constant manager = Manager(MANAGER_ADDRESS);
    ShifterRegistry public constant shifterRegistry = ShifterRegistry(0x597C52281b31B9d949a9D8fEbA08F7A2530a965e);

    enum Protocols { MCD, COMPOUND }
    enum SwapType { NO_SWAP, COLL_SWAP, DEBT_SWAP }
    enum Unsub { NO_UNSUB, FIRST_UNSUB, SECOND_UNSUB, BOTH_UNSUB }

    struct LoanShiftData {
        Protocols fromProtocol;
        Protocols toProtocol;
        SwapType swapType;
        Unsub unsub;
        bool wholeDebt;
        uint collAmount;
        uint debtAmount;
        address debtAddr1;
        address debtAddr2;
        address addrLoan1;
        address addrLoan2;
        uint id1;
        uint id2;
    }

    /// @notice Main entry point, it will move or transform a loan
    /// @dev Called through DSProxy
    function moveLoan(
        DFSExchangeData.ExchangeData memory _exchangeData,
        LoanShiftData memory _loanShift
    ) public payable burnGas(20) {
        if (_isSameTypeVaults(_loanShift)) {
            _forkVault(_loanShift);
            logEvent(_exchangeData, _loanShift);
            return;
        }

        _callCloseAndOpen(_exchangeData, _loanShift);
    }

    //////////////////////// INTERNAL FUNCTIONS //////////////////////////

    function _callCloseAndOpen(
        DFSExchangeData.ExchangeData memory _exchangeData,
        LoanShiftData memory _loanShift
    ) internal {
        address protoAddr = shifterRegistry.getAddr(getNameByProtocol(uint8(_loanShift.fromProtocol)));

        if (_loanShift.wholeDebt) {
            _loanShift.debtAmount = ILoanShifter(protoAddr).getLoanAmount(_loanShift.id1, _loanShift.debtAddr1);
        }

        // encode data
        bytes memory paramsData = abi.encode(_loanShift, _exchangeData, address(this));

        address payable loanShifterReceiverAddr = payable(shifterRegistry.getAddr("LOAN_SHIFTER_RECEIVER"));

        loanShifterReceiverAddr.transfer(address(this).balance);

        // call FL
        givePermission(loanShifterReceiverAddr);

        lendingPool.flashLoan(loanShifterReceiverAddr,
           getLoanAddr(_loanShift.debtAddr1, _loanShift.fromProtocol), _loanShift.debtAmount, paramsData);

        removePermission(loanShifterReceiverAddr);

        unsubFromAutomation(
            _loanShift.unsub,
            _loanShift.id1,
            _loanShift.id2,
            _loanShift.fromProtocol,
            _loanShift.toProtocol
        );

        logEvent(_exchangeData, _loanShift);
    }

    function _forkVault(LoanShiftData memory _loanShift) internal {
        // Create new Vault to move to
        if (_loanShift.id2 == 0) {
            _loanShift.id2 = manager.open(manager.ilks(_loanShift.id1), address(this));
        }

        if (_loanShift.wholeDebt) {
            manager.shift(_loanShift.id1, _loanShift.id2);
        }
    }

    function _isSameTypeVaults(LoanShiftData memory _loanShift) internal pure returns (bool) {
        return _loanShift.fromProtocol == Protocols.MCD && _loanShift.toProtocol == Protocols.MCD
                && _loanShift.addrLoan1 == _loanShift.addrLoan2;
    }

    function getNameByProtocol(uint8 _proto) internal pure returns (string memory) {
        if (_proto == 0) {
            return "MCD_SHIFTER";
        } else if (_proto == 1) {
            return "COMP_SHIFTER";
        }
    }

    function getLoanAddr(address _address, Protocols _fromProtocol) internal returns (address) {
        if (_fromProtocol == Protocols.COMPOUND) {
            return getUnderlyingAddr(_address);
        } else if (_fromProtocol == Protocols.MCD) {
            return DAI_ADDRESS;
        } else {
            return address(0);
        }
    }

    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    function logEvent(
        DFSExchangeData.ExchangeData memory _exchangeData,
        LoanShiftData memory _loanShift
    ) internal {
        address srcAddr = _exchangeData.srcAddr;
        address destAddr = _exchangeData.destAddr;

        uint collAmount = _exchangeData.srcAmount;
        uint debtAmount = _exchangeData.destAmount;

        if (_loanShift.swapType == SwapType.NO_SWAP) {
            srcAddr = _loanShift.addrLoan1;
            destAddr = _loanShift.debtAddr1;

            collAmount = _loanShift.collAmount;
            debtAmount = _loanShift.debtAmount;
        }

        DefisaverLogger(DEFISAVER_LOGGER)
            .Log(address(this), msg.sender, "LoanShifter",
            abi.encode(
            _loanShift.fromProtocol,
            _loanShift.toProtocol,
            _loanShift.swapType,
            srcAddr,
            destAddr,
            collAmount,
            debtAmount
        ));
    }

    function unsubFromAutomation(Unsub _unsub, uint _cdp1, uint _cdp2, Protocols _from, Protocols _to) internal {
        if (_unsub != Unsub.NO_UNSUB) {
            if (_unsub == Unsub.FIRST_UNSUB || _unsub == Unsub.BOTH_UNSUB) {
                unsubscribe(_cdp1, _from);
            }

            if (_unsub == Unsub.SECOND_UNSUB || _unsub == Unsub.BOTH_UNSUB) {
                unsubscribe(_cdp2, _to);
            }
        }
    }

    function unsubscribe(uint _cdpId, Protocols _protocol) internal {
        if (_cdpId != 0 && _protocol == Protocols.MCD) {
            IMCDSubscriptions(MCD_SUB_ADDRESS).unsubscribe(_cdpId);
        }

        if (_protocol == Protocols.COMPOUND) {
            ICompoundSubscriptions(COMPOUND_SUB_ADDRESS).unsubscribe();
        }
    }

}

pragma solidity ^0.6.0;

import "./ERC20.sol";

abstract contract CTokenInterface is ERC20 {
    function mint(uint256 mintAmount) external virtual returns (uint256);

    // function mint() external virtual payable;

    function accrueInterest() public virtual returns (uint);

    function redeem(uint256 redeemTokens) external virtual returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);

    function borrow(uint256 borrowAmount) external virtual returns (uint256);
    function borrowIndex() public view virtual returns (uint);
    function borrowBalanceStored(address) public view virtual returns(uint);

    function repayBorrow(uint256 repayAmount) external virtual returns (uint256);

    function repayBorrow() external virtual payable;

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);

    function repayBorrowBehalf(address borrower) external virtual payable;

    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral)
        external virtual
        returns (uint256);

    function liquidateBorrow(address borrower, address cTokenCollateral) external virtual payable;

    function exchangeRateCurrent() external virtual returns (uint256);

    function supplyRatePerBlock() external virtual returns (uint256);

    function borrowRatePerBlock() external virtual returns (uint256);

    function totalReserves() external virtual returns (uint256);

    function reserveFactorMantissa() external virtual returns (uint256);

    function borrowBalanceCurrent(address account) external virtual returns (uint256);

    function totalBorrowsCurrent() external virtual returns (uint256);

    function getCash() external virtual returns (uint256);

    function balanceOfUnderlying(address owner) external virtual returns (uint256);

    function underlying() external virtual returns (address);

    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint, uint);
}

pragma solidity ^0.6.0;

abstract contract ILoanShifter {
    function getLoanAmount(uint, address) public virtual returns (uint);
    function getUnderlyingAsset(address _addr) public view virtual returns (address);
}

pragma solidity ^0.6.0;

abstract contract Vat {

    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]

    function can(address, address) virtual public view returns (uint);
    function dai(address) virtual public view returns (uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
    function fork(bytes32, address, address, int, int) virtual public;
}

pragma solidity ^0.6.0;

abstract contract Manager {
    function last(address) virtual public returns (uint);
    function cdpCan(address, uint, address) virtual public view returns (uint);
    function ilks(uint) virtual public view returns (bytes32);
    function owns(uint) virtual public view returns (address);
    function urns(uint) virtual public view returns (address);
    function vat() virtual public view returns (address);
    function open(bytes32, address) virtual public returns (uint);
    function give(uint, address) virtual public;
    function cdpAllow(uint, address, uint) virtual public;
    function urnAllow(address, uint) virtual public;
    function frob(uint, int, int) virtual public;
    function flux(uint, address, uint) virtual public;
    function move(uint, address, uint) virtual public;
    function exit(address, uint, address, uint) virtual public;
    function quit(uint, address) virtual public;
    function enter(address, uint) virtual public;
    function shift(uint, uint) virtual public;
}

pragma solidity ^0.6.0;

abstract contract IMCDSubscriptions {
    function unsubscribe(uint256 _cdpId) external virtual ;
    function subscribersPos(uint256 _cdpId) external virtual returns (uint256, bool);
}

pragma solidity ^0.6.0;

abstract contract ICompoundSubscriptions {
    function unsubscribe() external virtual ;
}

pragma solidity ^0.6.0;

import "../DS/DSGuard.sol";
import "../DS/DSAuth.sol";

contract ProxyPermission {
    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /// @notice Called in the context of DSProxy to authorize an address
    /// @param _contractAddr Address which will be authorized
    function givePermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }

    /// @notice Called in the context of DSProxy to remove authority of an address
    /// @param _contractAddr Auth address which will be removed from authority list
    function removePermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        
        // if there is no authority, that means that contract doesn't have permission
        if (currAuthority == address(0)) {
            return;
        }

        DSGuard guard = DSGuard(currAuthority);
        guard.forbid(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }

    function proxyOwner() internal returns(address) {
        return DSAuth(address(this)).owner();
    } 
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract DFSExchangeData {

    // first is empty to keep the legacy order in place
    enum ExchangeType { _, OASIS, KYBER, UNISWAP, ZEROX }

    enum ActionType { SELL, BUY }

    struct OffchainData {
        address wrapper;
        address exchangeAddr;
        address allowanceTarget;
        uint256 price;
        uint256 protocolFee;
        bytes callData;
    }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint256 srcAmount;
        uint256 destAmount;
        uint256 minPrice;
        uint256 dfsFeeDivider; // service fee divider
        address user; // user to check special fee
        address wrapper;
        bytes wrapperData;
        OffchainData offchainData;
    }

    function packExchangeData(ExchangeData memory _exData) public pure returns(bytes memory) {
        return abi.encode(_exData);
    }

    function unpackExchangeData(bytes memory _data) public pure returns(ExchangeData memory _exData) {
        _exData = abi.decode(_data, (ExchangeData));
    }
}

pragma solidity ^0.6.0;

import "../auth/AdminAuth.sol";

contract ShifterRegistry is AdminAuth {
    mapping (string => address) public contractAddresses;
    bool public finalized;

    function changeContractAddr(string memory _contractName, address _protoAddr) public onlyOwner {
        require(!finalized);
        contractAddresses[_contractName] = _protoAddr;
    }

    function lock() public onlyOwner {
        finalized = true;
    }

    function getAddr(string memory _contractName) public view returns (address contractAddr) {
        contractAddr = contractAddresses[_contractName];

        require(contractAddr != address(0), "No contract address registred");
    }

}

pragma solidity ^0.6.0;

contract DefisaverLogger {
    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

    // solhint-disable-next-line func-name-mixedcase
    function Log(address _contract, address _caller, string memory _logName, bytes memory _data)
        public
    {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}

pragma solidity ^0.6.0;


abstract contract DSGuard {
    function canCall(address src_, address dst_, bytes4 sig) public view virtual returns (bool);

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function permit(address src, address dst, bytes32 sig) public virtual;

    function forbid(address src, address dst, bytes32 sig) public virtual;
}


abstract contract DSGuardFactory {
    function newGuard() public virtual returns (DSGuard guard);
}

pragma solidity ^0.6.0;

import "./DSAuthority.sol";


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

pragma solidity ^0.6.0;


abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../loggers/DefisaverLogger.sol";
import "../../utils/Discount.sol";

import "../../interfaces/reflexer/IOracleRelayer.sol";
import "../../interfaces/reflexer/ITaxCollector.sol";
import "../../interfaces/reflexer/ICoinJoin.sol";

import "./RAISaverProxyHelper.sol";
import "../../utils/BotRegistry.sol";
import "../../exchangeV3/DFSExchangeCore.sol";

/// @title Implements Boost and Repay for Reflexer Safes
contract RAISaverProxy is DFSExchangeCore, RAISaverProxyHelper {

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    bytes32 public constant ETH_COLL_TYPE = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    address public constant SAFE_ENGINE_ADDRESS = 0xCC88a9d330da1133Df3A7bD823B95e52511A6962;
    address public constant ORACLE_RELAYER_ADDRESS = 0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851;
    address public constant RAI_JOIN_ADDRESS = 0x0A5653CCa4DB1B6E265F47CAf6969e64f1CFdC45;
    address public constant TAX_COLLECTOR_ADDRESS = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;
    address public constant RAI_ADDRESS = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    ISAFEEngine public constant safeEngine = ISAFEEngine(SAFE_ENGINE_ADDRESS);
    ICoinJoin public constant raiJoin = ICoinJoin(RAI_JOIN_ADDRESS);
    IOracleRelayer public constant oracleRelayer = IOracleRelayer(ORACLE_RELAYER_ADDRESS);

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Repay - draws collateral, converts to Rai and repays the debt
    /// @dev Must be called by the DSProxy contract that owns the Safe
    function repay(
        ExchangeData memory _exchangeData,
        uint _safeId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable {

        address managerAddr = getManagerAddr(_managerType);

        address user = getOwner(ISAFEManager(managerAddr), _safeId);
        bytes32 ilk = ISAFEManager(managerAddr).collateralTypes(_safeId);

        drawCollateral(managerAddr, _safeId, _joinAddr, _exchangeData.srcAmount, true);

        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        (, uint raiAmount) = _sell(_exchangeData);

        raiAmount -= takeFee(_gasCost, raiAmount);

        paybackDebt(managerAddr, _safeId, ilk, raiAmount, user);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "RAIRepay", abi.encode(_safeId, user, _exchangeData.srcAmount, raiAmount));

    }

    /// @notice Boost - draws Rai, converts to collateral and adds to Safe
    /// @dev Must be called by the DSProxy contract that owns the Safe
    function boost(
        ExchangeData memory _exchangeData,
        uint _safeId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable {

        address managerAddr = getManagerAddr(_managerType);

        address user = getOwner(ISAFEManager(managerAddr), _safeId);
        bytes32 ilk = ISAFEManager(managerAddr).collateralTypes(_safeId);

        uint raiDrawn = drawRai(managerAddr, _safeId, ilk, _exchangeData.srcAmount);

        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        _exchangeData.srcAmount = raiDrawn - takeFee(_gasCost, raiDrawn);
        (, uint swapedColl) = _sell(_exchangeData);

        addCollateral(managerAddr, _safeId, _joinAddr, swapedColl, true);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "RAIBoost", abi.encode(_safeId, user, _exchangeData.srcAmount, swapedColl));
    }

    /// @notice Draws Rai from the Safe
    /// @dev If _raiAmount is bigger than max available we'll draw max
    /// @param _managerAddr Address of the Safe Manager
    /// @param _safeId Id of the Safe
    /// @param _collType Coll type of the Safe
    /// @param _raiAmount Amount of Rai to draw
    function drawRai(address _managerAddr, uint _safeId, bytes32 _collType, uint _raiAmount) internal returns (uint) {
        uint rate = ITaxCollector(TAX_COLLECTOR_ADDRESS).taxSingle(_collType);
        uint raiVatBalance = safeEngine.coinBalance(ISAFEManager(_managerAddr).safes(_safeId));

        uint maxAmount = getMaxDebt(_managerAddr, _safeId, _collType);

        if (_raiAmount >= maxAmount) {
            _raiAmount = sub(maxAmount, 1);
        }

        ISAFEManager(_managerAddr).modifySAFECollateralization(_safeId, int(0), normalizeDrawAmount(_raiAmount, rate, raiVatBalance));
        ISAFEManager(_managerAddr).transferInternalCoins(_safeId, address(this), toRad(_raiAmount));

        if (safeEngine.safeRights(address(this), address(RAI_JOIN_ADDRESS)) == 0) {
            safeEngine.approveSAFEModification(RAI_JOIN_ADDRESS);
        }

        ICoinJoin(RAI_JOIN_ADDRESS).exit(address(this), _raiAmount);

        return _raiAmount;
    }

    /// @notice Adds collateral to the Safe
    /// @param _managerAddr Address of the Safe Manager
    /// @param _safeId Id of the Safe
    /// @param _joinAddr Address of the join contract for the Safe collateral
    /// @param _amount Amount of collateral to add
    /// @param _toWeth Should we convert to Weth
    function addCollateral(address _managerAddr, uint _safeId, address _joinAddr, uint _amount, bool _toWeth) internal {
        int convertAmount = 0;

        if (isEthJoinAddr(_joinAddr) && _toWeth) {
            TokenInterface(IBasicTokenAdapters(_joinAddr).collateral()).deposit{value: _amount}();
            convertAmount = toPositiveInt(_amount);
        } else {
            convertAmount = toPositiveInt(convertTo18(_joinAddr, _amount));
        }

        ERC20(address(IBasicTokenAdapters(_joinAddr).collateral())).safeApprove(_joinAddr, _amount);

        IBasicTokenAdapters(_joinAddr).join(address(this), _amount);

        safeEngine.modifySAFECollateralization(
            ISAFEManager(_managerAddr).collateralTypes(_safeId),
            ISAFEManager(_managerAddr).safes(_safeId),
            address(this),
            address(this),
            convertAmount,
            0
        );

    }

    /// @notice Draws collateral and returns it to DSProxy
    /// @param _managerAddr Address of the Safe Manager
    /// @dev If _amount is bigger than max available we'll draw max
    /// @param _safeId Id of the Safe
    /// @param _joinAddr Address of the join contract for the Safe collateral
    /// @param _amount Amount of collateral to draw
    /// @param _toEth Boolean if we should unwrap Ether
    function drawCollateral(address _managerAddr, uint _safeId, address _joinAddr, uint _amount, bool _toEth) internal returns (uint) {
        uint frobAmount = _amount;

        if (IBasicTokenAdapters(_joinAddr).decimals() != 18) {
            frobAmount = _amount * (10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));
        }

        ISAFEManager(_managerAddr).modifySAFECollateralization(_safeId, -toPositiveInt(frobAmount), 0);
        ISAFEManager(_managerAddr).transferCollateral(_safeId, address(this), frobAmount);

        IBasicTokenAdapters(_joinAddr).exit(address(this), _amount);

        if (isEthJoinAddr(_joinAddr) && _toEth) {
            TokenInterface(IBasicTokenAdapters(_joinAddr).collateral()).withdraw(_amount); // Weth -> Eth
        }

        return _amount;
    }

    /// @notice Paybacks Rai debt
    /// @param _managerAddr Address of the Safe Manager
    /// @dev If the _raiAmount is bigger than the whole debt, returns extra Rai
    /// @param _safeId Id of the Safe
    /// @param _collType Coll type of the Safe
    /// @param _raiAmount Amount of Rai to payback
    /// @param _owner Address that owns the DSProxy that owns the Safe
    function paybackDebt(address _managerAddr, uint _safeId, bytes32 _collType, uint _raiAmount, address _owner) internal {
        address urn = ISAFEManager(_managerAddr).safes(_safeId);

        uint wholeDebt = getAllDebt(SAFE_ENGINE_ADDRESS, urn, urn, _collType);

        if (_raiAmount > wholeDebt) {
            ERC20(RAI_ADDRESS).transfer(_owner, sub(_raiAmount, wholeDebt));
            _raiAmount = wholeDebt;
        }

        if (ERC20(RAI_ADDRESS).allowance(address(this), RAI_JOIN_ADDRESS) == 0) {
            ERC20(RAI_ADDRESS).approve(RAI_JOIN_ADDRESS, uint(-1));
        }

        raiJoin.join(urn, _raiAmount);

        int paybackAmnt = _getRepaidDeltaDebt(SAFE_ENGINE_ADDRESS, ISAFEEngine(safeEngine).coinBalance(urn), urn, _collType);

        ISAFEManager(_managerAddr).modifySAFECollateralization(_safeId, 0, paybackAmnt);
    }

    /// @notice Gets the maximum amount of collateral available to draw
    /// @param _managerAddr Address of the Safe Manager
    /// @param _safeId Id of the Safe
    /// @param _collType Coll type of the Safe
    /// @param _joinAddr Joind address of collateral
    /// @dev Substracts 1% to aviod rounding error later on
    function getMaxCollateral(address _managerAddr, uint _safeId, bytes32 _collType, address _joinAddr) public view returns (uint) {
        (uint collateral, uint debt) = getSafeInfo(ISAFEManager(_managerAddr), _safeId, _collType);

        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        uint maxCollateral = sub(collateral, wmul(wdiv(RAY, safetyPrice), debt));

        uint normalizeMaxCollateral = maxCollateral / (10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));

        // take one percent due to precision issues
        return normalizeMaxCollateral * 99 / 100;
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _managerAddr Address of the Safe Manager
    /// @param _safeId Id of the Safe
    /// @param _collType Coll type of the Safe
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxDebt(
        address _managerAddr,
        uint256 _safeId,
        bytes32 _collType
    ) public view virtual returns (uint256) {
        (uint256 collateral, uint256 debt) =
            getSafeInfo(ISAFEManager(_managerAddr), _safeId, _collType);

        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        return sub(sub(rmul(collateral, safetyPrice), debt), 10);
    }

    function getPrice(bytes32 _collType) public returns (uint256) {
        (, uint256 safetyCRatio) =
            IOracleRelayer(ORACLE_RELAYER_ADDRESS).collateralTypes(_collType);
        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        uint256 redemptionPrice = IOracleRelayer(ORACLE_RELAYER_ADDRESS).redemptionPrice();

        return rmul(rmul(safetyPrice, redemptionPrice), safetyCRatio);
    }

    function isAutomation() internal view returns(bool) {
        return BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin);
    }

    function takeFee(uint256 _gasCost, uint _amount) internal returns(uint) {
        if (_gasCost > 0) {
            uint ethRaiPrice = getPrice(ETH_COLL_TYPE);
            uint feeAmount = rmul(_gasCost, ethRaiPrice);

            if (feeAmount > _amount / 5) {
                feeAmount = _amount / 5;
            }

            address walletAddr = _feeRecipient.getFeeAddr();

            ERC20(RAI_ADDRESS).transfer(walletAddr, feeAmount);

            return feeAmount;
        }

        return 0;
    }
}

pragma solidity ^0.6.0;


contract Discount {
    address public owner;
    mapping(address => CustomServiceFee) public serviceFees;

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
}

pragma solidity ^0.6.0;

abstract contract IOracleRelayer {
    struct CollateralType {
        address orcl;
        uint256 safetyCRatio;
    }

    mapping (bytes32 => CollateralType) public collateralTypes;

    function redemptionPrice() public virtual returns (uint256);
    uint256 public redemptionRate;
}

pragma solidity ^0.6.0;

abstract contract ITaxCollector {
    struct CollateralType {
        uint256 stabilityFee;
        uint256 updateTime;
    }

    mapping (bytes32 => CollateralType) public collateralTypes;

    function taxSingle(bytes32) public virtual returns (uint);
}

pragma solidity ^0.6.0;

abstract contract ICoinJoin {
    uint256 public decimals;

    function join(address account, uint256 wad) external virtual;

    function exit(address account, uint256 wad) external virtual;
}

pragma solidity ^0.6.0;

import "../../DS/DSMath.sol";
import "../../DS/DSProxy.sol";
import "../../interfaces/reflexer/IBasicTokenAdapters.sol";
import "../../interfaces/reflexer/ISAFEManager.sol";
import "../../interfaces/reflexer/ISAFEEngine.sol";
import "../../interfaces/reflexer/ITaxCollector.sol";

/// @title Helper methods for RAISaverProxy
contract RAISaverProxyHelper is DSMath {

    enum ManagerType { RAI }

    /// @notice Returns a normalized debt _amount based on the current rate
    /// @param _amount Amount of dai to be normalized
    /// @param _rate Current rate of the stability fee
    /// @param _daiVatBalance Balance od Dai in the Vat for that Safe
    function normalizeDrawAmount(uint _amount, uint _rate, uint _daiVatBalance) internal pure returns (int dart) {
        if (_daiVatBalance < mul(_amount, RAY)) {
            dart = toPositiveInt(sub(mul(_amount, RAY), _daiVatBalance) / _rate);
            dart = mul(uint(dart), _rate) < mul(_amount, RAY) ? dart + 1 : dart;
        }
    }

    /// @notice Converts a number to Rad percision
    /// @param _wad The input number in wad percision
    function toRad(uint _wad) internal pure returns (uint) {
        return mul(_wad, 10 ** 27);
    }

    /// @notice Converts a number to 18 decimal percision
    /// @param _joinAddr Join address of the collateral
    /// @param _amount Number to be converted
    function convertTo18(address _joinAddr, uint256 _amount) internal view returns (uint256) {
        return mul(_amount, 10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));
    }

    /// @notice Converts a uint to int and checks if positive
    /// @param _x Number to be converted
    function toPositiveInt(uint _x) internal pure returns (int y) {
        y = int(_x);
        require(y >= 0, "int-overflow");
    }

    /// @notice Gets Dai amount in Vat which can be added to Safe
    /// @param _safeEngine Address of Vat contract
    /// @param _urn Urn of the Safe
    /// @param _collType CollType of the Safe
    function normalizePaybackAmount(address _safeEngine, address _urn, bytes32 _collType) internal view returns (int amount) {
        uint dai = ISAFEEngine(_safeEngine).coinBalance(_urn);

        (, uint rate,,,,) = ISAFEEngine(_safeEngine).collateralTypes(_collType);
        (, uint art) = ISAFEEngine(_safeEngine).safes(_collType, _urn);

        amount = toPositiveInt(dai / rate);
        amount = uint(amount) <= art ? - amount : - toPositiveInt(art);
    }

    /// @notice Gets delta debt generated (Total Safe debt minus available safeHandler COIN balance)
    /// @param safeEngine address
    /// @param taxCollector address
    /// @param safeHandler address
    /// @param collateralType bytes32
    /// @return deltaDebt
    function _getGeneratedDeltaDebt(
        address safeEngine,
        address taxCollector,
        address safeHandler,
        bytes32 collateralType,
        uint wad
    ) internal returns (int deltaDebt) {
        // Updates stability fee rate
        uint rate = ITaxCollector(taxCollector).taxSingle(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets COIN balance of the handler in the safeEngine
        uint coin = ISAFEEngine(safeEngine).coinBalance(safeHandler);

        // If there was already enough COIN in the safeEngine balance, just exits it without adding more debt
        if (coin < mul(wad, RAY)) {
            // Calculates the needed deltaDebt so together with the existing coins in the safeEngine is enough to exit wad amount of COIN tokens
            deltaDebt = toPositiveInt(sub(mul(wad, RAY), coin) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra deltaDebt wei (for the given COIN wad amount)
            deltaDebt = mul(uint(deltaDebt), rate) < mul(wad, RAY) ? deltaDebt + 1 : deltaDebt;
        }
    }

    function _getRepaidDeltaDebt(
        address safeEngine,
        uint coin,
        address safe,
        bytes32 collateralType
    ) internal view returns (int deltaDebt) {
        // Gets actual rate from the safeEngine
        (, uint rate,,,,) = ISAFEEngine(safeEngine).collateralTypes(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets actual generatedDebt value of the safe
        (, uint generatedDebt) = ISAFEEngine(safeEngine).safes(collateralType, safe);

        // Uses the whole coin balance in the safeEngine to reduce the debt
        deltaDebt = toPositiveInt(coin / rate);
        // Checks the calculated deltaDebt is not higher than safe.generatedDebt (total debt), otherwise uses its value
        deltaDebt = uint(deltaDebt) <= generatedDebt ? - deltaDebt : - toPositiveInt(generatedDebt);
    }

    /// @notice Gets the whole debt of the Safe
    /// @param _safeEngine Address of Vat contract
    /// @param _usr Address of the Dai holder
    /// @param _urn Urn of the Safe
    /// @param _collType CollType of the Safe
    function getAllDebt(address _safeEngine, address _usr, address _urn, bytes32 _collType) internal view returns (uint daiAmount) {
        (, uint rate,,,,) = ISAFEEngine(_safeEngine).collateralTypes(_collType);
        (, uint art) = ISAFEEngine(_safeEngine).safes(_collType, _urn);
        uint dai = ISAFEEngine(_safeEngine).coinBalance(_usr);

        uint rad = sub(mul(art, rate), dai);
        daiAmount = rad / RAY;

        daiAmount = mul(daiAmount, RAY) < rad ? daiAmount + 1 : daiAmount;
    }

    /// @notice Gets the token address from the Join contract
    /// @param _joinAddr Address of the Join contract
    function getCollateralAddr(address _joinAddr) internal view returns (address) {
        return address(IBasicTokenAdapters(_joinAddr).collateral());
    }

    /// @notice Checks if the join address is one of the Ether coll. types
    /// @param _joinAddr Join address to check
    function isEthJoinAddr(address _joinAddr) internal view returns (bool) {
        // if it's dai_join_addr don't check gem() it will fail
        if (_joinAddr == 0x0A5653CCa4DB1B6E265F47CAf6969e64f1CFdC45) return false;

        // if coll is weth it's and eth type coll
        if (address(IBasicTokenAdapters(_joinAddr).collateral()) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            return true;
        }

        return false;
    }

    /// @notice Gets Safe info (collateral, debt)
    /// @param _manager Manager contract
    /// @param _safeId Id of the Safe
    /// @param _collType CollType of the Safe
    function getSafeInfo(ISAFEManager _manager, uint _safeId, bytes32 _collType) public view returns (uint, uint) {
        address vat = _manager.safeEngine();
        address urn = _manager.safes(_safeId);

        (uint collateral, uint debt) = ISAFEEngine(vat).safes(_collType, urn);
        (,uint rate,,,,) = ISAFEEngine(vat).collateralTypes(_collType);

        return (collateral, rmul(debt, rate));
    }

    /// @notice Address that owns the DSProxy that owns the Safe
    /// @param _manager Manager contract
    /// @param _safeId Id of the Safe
    function getOwner(ISAFEManager _manager, uint _safeId) public view returns (address) {
        DSProxy proxy = DSProxy(uint160(_manager.ownsSAFE(_safeId)));

        return proxy.owner();
    }

    /// @notice Based on the manager type returns the address
    /// @param _managerType Type of vault manager to use
    function getManagerAddr(ManagerType _managerType) public pure returns (address) {
        if (_managerType == ManagerType.RAI) {
            return 0xEfe0B4cA532769a3AE758fD82E1426a03A94F185;
        }
    }
}

pragma solidity ^0.6.0;

import "../auth/AdminAuth.sol";

contract BotRegistry is AdminAuth {

    mapping (address => bool) public botList;

    constructor() public {
        botList[0x776B4a13093e30B05781F97F6A4565B6aa8BE330] = true;

        botList[0xAED662abcC4FA3314985E67Ea993CAD064a7F5cF] = true;
        botList[0xa5d330F6619d6bF892A5B87D80272e1607b3e34D] = true;
        botList[0x5feB4DeE5150B589a7f567EA7CADa2759794A90A] = true;
        botList[0x7ca06417c1d6f480d3bB195B80692F95A6B66158] = true;
    }

    function setBot(address _botAddr, bool _state) public onlyOwner {
        botList[_botAddr] = _state;
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../DS/DSMath.sol";
import "../interfaces/TokenInterface.sol";
import "../interfaces/ExchangeInterfaceV3.sol";
import "../utils/ZrxAllowlist.sol";
import "./DFSExchangeData.sol";
import "./DFSExchangeHelper.sol";
import "../exchange/SaverExchangeRegistry.sol";
import "../interfaces/OffchainWrapperInterface.sol";

contract DFSExchangeCore is DFSExchangeHelper, DSMath, DFSExchangeData {

    string public constant ERR_SLIPPAGE_HIT = "Slippage hit";
    string public constant ERR_DEST_AMOUNT_MISSING = "Dest amount missing";
    string public constant ERR_WRAPPER_INVALID = "Wrapper invalid";
    string public constant ERR_NOT_ZEROX_EXCHANGE = "Zerox exchange invalid";

    /// @notice Internal method that preforms a sell on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and destAmount
    function _sell(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(EXCHANGE_WETH_ADDRESS).deposit{value: exData.srcAmount}();
        }

        exData.srcAmount -= getFee(exData.srcAmount, exData.user, exData.srcAddr, exData.dfsFeeDivider);

        // Try 0x first and then fallback on specific wrapper
        if (exData.offchainData.price > 0) {
            (success, swapedTokens) = takeOrder(exData, ActionType.SELL);

            if (success) {
                wrapper = exData.offchainData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.SELL);
            wrapper = exData.wrapper;
        }

        // if anything is left in weth, pull it to user as eth
        if (getBalance(EXCHANGE_WETH_ADDRESS) > 0) {
            TokenInterface(EXCHANGE_WETH_ADDRESS).withdraw(
                TokenInterface(EXCHANGE_WETH_ADDRESS).balanceOf(address(this))
            );
        }

        if (exData.destAddr == EXCHANGE_WETH_ADDRESS) {
            require(getBalance(KYBER_ETH_ADDRESS) >= wmul(exData.minPrice, exData.srcAmount), ERR_SLIPPAGE_HIT);
        } else {
            require(getBalance(exData.destAddr) >= wmul(exData.minPrice, exData.srcAmount), ERR_SLIPPAGE_HIT);
        }

        return (wrapper, swapedTokens);
    }

    /// @notice Internal method that preforms a buy on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and srcAmount
    function _buy(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;

        require(exData.destAmount != 0, ERR_DEST_AMOUNT_MISSING);

        exData.srcAmount -= getFee(exData.srcAmount, exData.user, exData.srcAddr, exData.dfsFeeDivider);

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(EXCHANGE_WETH_ADDRESS).deposit{value: exData.srcAmount}();
        }

        if (exData.offchainData.price > 0) {
            (success, swapedTokens) = takeOrder(exData, ActionType.BUY);

            if (success) {
                wrapper = exData.offchainData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.BUY);
            wrapper = exData.wrapper;
        }

        // if anything is left in weth, pull it to user as eth
        if (getBalance(EXCHANGE_WETH_ADDRESS) > 0) {
            TokenInterface(EXCHANGE_WETH_ADDRESS).withdraw(
                TokenInterface(EXCHANGE_WETH_ADDRESS).balanceOf(address(this))
            );
        }

        if (exData.destAddr == EXCHANGE_WETH_ADDRESS) {
            require(getBalance(KYBER_ETH_ADDRESS) >= exData.destAmount, ERR_SLIPPAGE_HIT);
        } else {
            require(getBalance(exData.destAddr) >= exData.destAmount, ERR_SLIPPAGE_HIT);
        }

        return (wrapper, getBalance(exData.destAddr));
    }

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) private returns (bool success, uint256) {
        if (!ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isZrxAddr(_exData.offchainData.exchangeAddr)) {
            return (false, 0);
        }

        if (!SaverExchangeRegistry(SAVER_EXCHANGE_REGISTRY).isWrapper(_exData.offchainData.wrapper)) {
            return (false, 0);
        }

        // send src amount
        ERC20(_exData.srcAddr).safeTransfer(_exData.offchainData.wrapper, _exData.srcAmount);

        return OffchainWrapperInterface(_exData.offchainData.wrapper).takeOrder{value: _exData.offchainData.protocolFee}(_exData, _type);
    }

    /// @notice Calls wraper contract for exchage to preform an on-chain swap
    /// @param _exData Exchange data struct
    /// @param _type Type of action SELL|BUY
    /// @return swapedTokens For Sell that the destAmount, for Buy thats the srcAmount
    function saverSwap(ExchangeData memory _exData, ActionType _type) internal returns (uint swapedTokens) {
        require(SaverExchangeRegistry(SAVER_EXCHANGE_REGISTRY).isWrapper(_exData.wrapper), ERR_WRAPPER_INVALID);

        ERC20(_exData.srcAddr).safeTransfer(_exData.wrapper, _exData.srcAmount);

        if (_type == ActionType.SELL) {
            swapedTokens = ExchangeInterfaceV3(_exData.wrapper).
                    sell(_exData.srcAddr, _exData.destAddr, _exData.srcAmount, _exData.wrapperData);
        } else {
            swapedTokens = ExchangeInterfaceV3(_exData.wrapper).
                    buy(_exData.srcAddr, _exData.destAddr, _exData.destAmount, _exData.wrapperData);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}

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

pragma solidity ^0.6.0;

import "./DSAuth.sol";
import "./DSNote.sol";


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

pragma solidity ^0.6.0;

abstract contract IBasicTokenAdapters {
    bytes32 public collateralType;

    function decimals() virtual public view returns (uint);
    function collateral() virtual public view returns (address);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

pragma solidity ^0.6.0;

abstract contract ISAFEManager {

    function lastSAFEID(address) virtual public returns (uint);
    function safeCan(address, uint, address) virtual public view returns (uint);
    function collateralTypes(uint) virtual public view returns (bytes32);
    function ownsSAFE(uint) virtual public view returns (address);
    function safes(uint) virtual public view returns (address);
    function safeEngine() virtual public view returns (address);
    function openSAFE(bytes32, address) virtual public returns (uint);
    function transferSAFEOwnership(uint, address) virtual public;
    function allowSAFE(uint, address, uint) virtual public;
    function handlerAllowed(address, uint) virtual public;
    function modifySAFECollateralization(uint, int, int) virtual public;
    function transferCollateral(uint, address, uint) virtual public;
    function transferInternalCoins(uint, address, uint) virtual public;
    function quitSystem(uint, address) virtual public;
    function enterSystem(address, uint) virtual public;
    function moveSAFE(uint, uint) virtual public;
}

pragma solidity ^0.6.0;

abstract contract ISAFEEngine {

    struct SAFE {
        uint256 lockedCollateral;
        uint256 generatedDebt;
    }

    struct CollateralType {
        // Total debt issued for this specific collateral type
        uint256 debtAmount;        // [wad]
        // Accumulator for interest accrued on this collateral type
        uint256 accumulatedRate;   // [ray]
        // Floor price at which a SAFE is allowed to generate debt
        uint256 safetyPrice;       // [ray]
        // Maximum amount of debt that can be generated with this collateral type
        uint256 debtCeiling;       // [rad]
        // Minimum amount of debt that must be generated by a SAFE using this collateral
        uint256 debtFloor;         // [rad]
        // Price at which a SAFE gets liquidated
        uint256 liquidationPrice;  // [ray]
    }

    mapping (bytes32 => mapping (address => SAFE )) public safes;
    mapping (bytes32 => CollateralType) public collateralTypes;
    mapping (bytes32 => mapping (address => uint)) public tokenCollateral;

    function safeRights(address, address) virtual public view returns (uint);
    function coinBalance(address) virtual public view returns (uint);
    function modifySAFECollateralization(bytes32, address, address, address, int, int) virtual public;
    function approveSAFEModification(address) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
    function transferSAFECollateralAndDebt(bytes32, address, address, int, int) virtual public;
}

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

pragma solidity ^0.6.0;

abstract contract TokenInterface {
	address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    function allowance(address, address) public virtual returns (uint256);

    function balanceOf(address) public virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(address, address, uint256) public virtual returns (bool);

    function deposit() public virtual payable;

    function withdraw(uint256) public virtual;
}

pragma solidity ^0.6.0;

interface ExchangeInterfaceV3 {
    function sell(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external payable returns (uint);

    function buy(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) external payable returns(uint);

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external view returns (uint);

    function getBuyRate(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external view returns (uint);
}

pragma solidity ^0.6.0;

import "../auth/AdminAuth.sol";

contract ZrxAllowlist is AdminAuth {

    mapping (address => bool) public zrxAllowlist;
    mapping(address => bool) private nonPayableAddrs;

    constructor() public {
        zrxAllowlist[0x6958F5e95332D93D21af0D7B9Ca85B8212fEE0A5] = true;
        zrxAllowlist[0x61935CbDd02287B511119DDb11Aeb42F1593b7Ef] = true;
        zrxAllowlist[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        zrxAllowlist[0x080bf510FCbF18b91105470639e9561022937712] = true;

        nonPayableAddrs[0x080bf510FCbF18b91105470639e9561022937712] = true;
    }

    function setAllowlistAddr(address _zrxAddr, bool _state) public onlyOwner {
        zrxAllowlist[_zrxAddr] = _state;
    }

    function isZrxAddr(address _zrxAddr) public view returns (bool) {
        return zrxAllowlist[_zrxAddr];
    }

    function addNonPayableAddr(address _nonPayableAddr) public onlyOwner {
		nonPayableAddrs[_nonPayableAddr] = true;
	}

	function removeNonPayableAddr(address _nonPayableAddr) public onlyOwner {
		nonPayableAddrs[_nonPayableAddr] = false;
	}

	function isNonPayableAddr(address _addr) public view returns(bool) {
		return nonPayableAddrs[_addr];
	}
}

pragma solidity ^0.6.0;

import "../utils/SafeERC20.sol";
import "../utils/Discount.sol";
import "../interfaces/IFeeRecipient.sol";

contract DFSExchangeHelper {

    string public constant ERR_OFFCHAIN_DATA_INVALID = "Offchain data invalid";

    using SafeERC20 for ERC20;

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant EXCHANGE_WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IFeeRecipient public constant _feeRecipient = IFeeRecipient(0x39C4a92Dc506300c3Ea4c67ca4CA611102ee6F2A);

    address public constant DISCOUNT_ADDRESS = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;
    address public constant SAVER_EXCHANGE_REGISTRY = 0x25dd3F51e0C3c3Ff164DDC02A8E4D65Bb9cBB12D;

    address public constant ZRX_ALLOWLIST_ADDR = 0x4BA1f38427b33B8ab7Bb0490200dAE1F1C36823F;


    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function getBalance(address _tokenAddr) internal view returns (uint balance) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_tokenAddr).balanceOf(address(this));
        }
    }

    function sendLeftover(address _srcAddr, address _destAddr, address payable _to) internal {
        // send back any leftover ether or tokens
        if (address(this).balance > 0) {
            _to.transfer(address(this).balance);
        }

        if (getBalance(_srcAddr) > 0) {
            ERC20(_srcAddr).safeTransfer(_to, getBalance(_srcAddr));
        }

        if (getBalance(_destAddr) > 0) {
            ERC20(_destAddr).safeTransfer(_to, getBalance(_destAddr));
        }
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @param _user Address of the user
    /// @param _token Address of the token
    /// @param _dfsFeeDivider Dfs fee divider
    /// @return feeAmount Amount in Dai owner earned on the fee
    function getFee(uint256 _amount, address _user, address _token, uint256 _dfsFeeDivider) internal returns (uint256 feeAmount) {
        if (_dfsFeeDivider != 0 && Discount(DISCOUNT_ADDRESS).isCustomFeeSet(_user)) {
            _dfsFeeDivider = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(_user);
        }

        if (_dfsFeeDivider == 0) {
            feeAmount = 0;
        } else {
            feeAmount = _amount / _dfsFeeDivider;

            // fee can't go over 10% of the whole amount
            if (feeAmount > (_amount / 10)) {
                feeAmount = _amount / 10;
            }

            address walletAddr = _feeRecipient.getFeeAddr();

            if (_token == KYBER_ETH_ADDRESS) {
                payable(walletAddr).transfer(feeAmount);
            } else {
                ERC20(_token).safeTransfer(walletAddr, feeAmount);
            }
        }
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }

        function writeUint256(bytes memory _b, uint256 _index, uint _input) internal pure {
        if (_b.length < _index + 32) {
            revert(ERR_OFFCHAIN_DATA_INVALID);
        }

        bytes32 input = bytes32(_input);

        _index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(_b, _index), input)
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? EXCHANGE_WETH_ADDRESS : _src;
    }
}

pragma solidity ^0.6.0;

import "../auth/AdminAuth.sol";

contract SaverExchangeRegistry is AdminAuth {

	mapping(address => bool) private wrappers;

	constructor() public {
		wrappers[0x880A845A85F843a5c67DB2061623c6Fc3bB4c511] = true;
		wrappers[0x4c9B55f2083629A1F7aDa257ae984E03096eCD25] = true;
		wrappers[0x42A9237b872368E1bec4Ca8D26A928D7d39d338C] = true;
	}

	function addWrapper(address _wrapper) public onlyOwner {
		wrappers[_wrapper] = true;
	}

	function removeWrapper(address _wrapper) public onlyOwner {
		wrappers[_wrapper] = false;
	}

	function isWrapper(address _wrapper) public view returns(bool) {
		return wrappers[_wrapper];
	}
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../exchangeV3/DFSExchangeData.sol";

abstract contract OffchainWrapperInterface is DFSExchangeData {
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) virtual public payable returns (bool success, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

abstract contract IFeeRecipient {
    function getFeeAddr() public view virtual returns (address);
    function changeWalletAddr(address _newWallet) public virtual;
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../auth/AdminAuth.sol";
import "../utils/FlashLoanReceiverBase.sol";
import "../interfaces/DSProxyInterface.sol";
import "../exchangeV3/DFSExchangeCore.sol";
import "./ShifterRegistry.sol";
import "./LoanShifterTaker.sol";

/// @title LoanShifterReceiver Recevies the Aave flash loan and calls actions through users DSProxy
contract LoanShifterReceiver is DFSExchangeCore, FlashLoanReceiverBase, AdminAuth {
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER =
        ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    ShifterRegistry public constant shifterRegistry =
        ShifterRegistry(0x597C52281b31B9d949a9D8fEbA08F7A2530a965e);

    struct ParamData {
        bytes proxyData1;
        bytes proxyData2;
        address proxy;
        address debtAddr;
        uint8 protocol1;
        uint8 protocol2;
        uint8 swapType;
    }

    constructor() public FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        // Format the call data for DSProxy
        (ParamData memory paramData, ExchangeData memory exchangeData) =
            packFunctionCall(_amount, _fee, _params);

        address protocolAddr1 = shifterRegistry.getAddr(getNameByProtocol(paramData.protocol1));
        address protocolAddr2 = shifterRegistry.getAddr(getNameByProtocol(paramData.protocol2));

        // Send Flash loan amount to DSProxy
        sendTokenToProxy(payable(paramData.proxy), _reserve, _amount);

        // Execute the Close/Change debt operation
        DSProxyInterface(paramData.proxy).execute(protocolAddr1, paramData.proxyData1);

        exchangeData.dfsFeeDivider = SERVICE_FEE;
        exchangeData.user = DSProxyInterface(paramData.proxy).owner();

        if (paramData.swapType == 1) {
            uint256 amount = exchangeData.srcAmount;

            if (exchangeData.srcAddr != exchangeData.destAddr) {
                // COLL_SWAP
                (, amount) = _sell(exchangeData);
            }

            sendTokenAndEthToProxy(payable(paramData.proxy), exchangeData.destAddr, amount);
        } else if (paramData.swapType == 2) {
            // DEBT_SWAP

            if (exchangeData.srcAddr != exchangeData.destAddr) {
                exchangeData.destAmount = (_amount + _fee);
                _buy(exchangeData);

                // Send extra to DSProxy
                sendTokenToProxy(
                    payable(paramData.proxy),
                    exchangeData.srcAddr,
                    ERC20(exchangeData.srcAddr).balanceOf(address(this))
                );
            }
        } else {
            // NO_SWAP just send tokens to proxy
            sendTokenAndEthToProxy(
                payable(paramData.proxy),
                exchangeData.srcAddr,
                getBalance(exchangeData.srcAddr)
            );
        }

        // Execute the Open operation
        DSProxyInterface(paramData.proxy).execute(protocolAddr2, paramData.proxyData2);

        // Repay FL
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function packFunctionCall(
        uint256 _amount,
        uint256 _fee,
        bytes memory _params
    )
        internal
        pure
        returns (ParamData memory paramData, ExchangeData memory exchangeData)
    {

        LoanShifterTaker.LoanShiftData memory shiftData;
        address proxy;

        (shiftData, exchangeData, proxy) = abi.decode(
            _params,
            (LoanShifterTaker.LoanShiftData, ExchangeData, address)
        );

        bytes memory proxyData1;
        bytes memory proxyData2;
        uint256 openDebtAmount = (_amount + _fee);

        if (shiftData.fromProtocol == LoanShifterTaker.Protocols.MCD) {
            // MAKER FROM
            proxyData1 = abi.encodeWithSignature(
                "close(uint256,address,uint256,uint256)",
                shiftData.id1,
                shiftData.addrLoan1,
                _amount,
                shiftData.collAmount
            );
        } else if (shiftData.fromProtocol == LoanShifterTaker.Protocols.COMPOUND) {
            // COMPOUND FROM
            if (shiftData.swapType == LoanShifterTaker.SwapType.DEBT_SWAP) {
                // DEBT_SWAP
                proxyData1 = abi.encodeWithSignature(
                    "changeDebt(address,address,uint256,uint256)",
                    shiftData.debtAddr1,
                    shiftData.debtAddr2,
                    _amount,
                    exchangeData.srcAmount
                );
            } else {
                proxyData1 = abi.encodeWithSignature(
                    "close(address,address,uint256,uint256)",
                    shiftData.addrLoan1,
                    shiftData.debtAddr1,
                    shiftData.collAmount,
                    shiftData.debtAmount
                );
            }
        }

        if (shiftData.toProtocol == LoanShifterTaker.Protocols.MCD) {
            // MAKER TO
            proxyData2 = abi.encodeWithSignature(
                "open(uint256,address,uint256)",
                shiftData.id2,
                shiftData.addrLoan2,
                openDebtAmount
            );
        } else if (shiftData.toProtocol == LoanShifterTaker.Protocols.COMPOUND) {
            // COMPOUND TO
            if (shiftData.swapType == LoanShifterTaker.SwapType.DEBT_SWAP) {
                // DEBT_SWAP
                proxyData2 = abi.encodeWithSignature("repayAll(address)", shiftData.debtAddr2);
            } else {
                proxyData2 = abi.encodeWithSignature(
                    "open(address,address,uint256)",
                    shiftData.addrLoan2,
                    shiftData.debtAddr2,
                    openDebtAmount
                );
            }
        }

        paramData = ParamData({
            proxyData1: proxyData1,
            proxyData2: proxyData2,
            proxy: proxy,
            debtAddr: shiftData.debtAddr1,
            protocol1: uint8(shiftData.fromProtocol),
            protocol2: uint8(shiftData.toProtocol),
            swapType: uint8(shiftData.swapType)
        });
    }

    function sendTokenAndEthToProxy(
        address payable _proxy,
        address _reserve,
        uint256 _amount
    ) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, _amount);
        }

        _proxy.transfer(address(this).balance);
    }

    function sendTokenToProxy(
        address payable _proxy,
        address _reserve,
        uint256 _amount
    ) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, _amount);
        } else {
            _proxy.transfer(address(this).balance);
        }
    }

    function getNameByProtocol(uint8 _proto) internal pure returns (string memory) {
        if (_proto == 0) {
            return "MCD_SHIFTER";
        } else if (_proto == 1) {
            return "COMP_SHIFTER";
        }
    }

    receive() external payable override(FlashLoanReceiverBase, DFSExchangeCore) {}
}

pragma solidity ^0.6.0;

import "./SafeERC20.sol";

interface IFlashLoanReceiver {
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

abstract contract ILendingPoolAddressesProvider {

    function getLendingPool() public view virtual returns (address);
    function setLendingPoolImpl(address _pool) public virtual;

    function getLendingPoolCore() public virtual view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) public virtual;

    function getLendingPoolConfigurator() public virtual view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) public virtual;

    function getLendingPoolDataProvider() public virtual view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) public virtual;

    function getLendingPoolParametersProvider() public virtual view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public virtual;

    function getTokenDistributor() public virtual view returns (address);
    function setTokenDistributor(address _tokenDistributor) public virtual;


    function getFeeProvider() public virtual view returns (address);
    function setFeeProviderImpl(address _feeProvider) public virtual;

    function getLendingPoolLiquidationManager() public virtual view returns (address);
    function setLendingPoolLiquidationManager(address _manager) public virtual;

    function getLendingPoolManager() public virtual view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) public virtual;

    function getPriceOracle() public virtual view returns (address);
    function setPriceOracle(address _priceOracle) public virtual;

    function getLendingRateOracle() public view virtual returns (address);
    function setLendingRateOracle(address _lendingRateOracle) public virtual;
}

library EthAddressLib {

    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {

    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    ILendingPoolAddressesProvider public addressesProvider;

    constructor(ILendingPoolAddressesProvider _provider) public {
        addressesProvider = _provider;
    }

    receive () external virtual payable {}

    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {

        address payable core = addressesProvider.getLendingPoolCore();

        transferInternal(core,_reserve, _amount);
    }

    function transferInternal(address payable _destination, address _reserve, uint256  _amount) internal {
        if(_reserve == EthAddressLib.ethAddress()) {
            //solium-disable-next-line
            _destination.call{value: _amount}("");
            return;
        }

        ERC20(_reserve).safeTransfer(_destination, _amount);


    }

    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == EthAddressLib.ethAddress()) {

            return _target.balance;
        }

        return ERC20(_reserve).balanceOf(_target);

    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../DS/DSProxy.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../../exchangeV3/DFSExchangeCore.sol";
import "../../shifter/ShifterRegistry.sol";
import "./CompoundCreateTaker.sol";

/// @title Contract that receives the FL from Aave for Creating loans
contract CompoundCreateReceiver is FlashLoanReceiverBase, DFSExchangeCore {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    ShifterRegistry public constant shifterRegistry = ShifterRegistry(0x597C52281b31B9d949a9D8fEbA08F7A2530a965e);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    // solhint-disable-next-line no-empty-blocks
    constructor() public FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) {}

    struct CompCreateData {
        address payable proxyAddr;
        bytes proxyData;
        address cCollAddr;
        address cDebtAddr;
    }

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
   function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {
        // Format the call data for DSProxy
        (CompCreateData memory compCreate, ExchangeData memory exchangeData)
                                 = packFunctionCall(_amount, _fee, _params);


        address leveragedAsset = _reserve;

        // If the assets are different
        if (compCreate.cCollAddr != compCreate.cDebtAddr) {
            exchangeData.dfsFeeDivider = SERVICE_FEE;
            exchangeData.user = DSProxyInterface(compCreate.proxyAddr).owner();

            _sell(exchangeData);

            leveragedAsset = exchangeData.destAddr;
        }

        // Send amount to DSProxy
        sendToProxy(compCreate.proxyAddr, leveragedAsset);

        address compOpenProxy = shifterRegistry.getAddr("COMP_SHIFTER");

        // Execute the DSProxy call
        DSProxyInterface(compCreate.proxyAddr).execute(compOpenProxy, compCreate.proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            // solhint-disable-next-line avoid-tx-origin
            tx.origin.transfer(address(this).balance);
        }
    }

    /// @notice Formats function data call so we can call it through DSProxy
    /// @param _amount Amount of FL
    /// @param _fee Fee of the FL
    /// @param _params Saver proxy params
    function packFunctionCall(uint _amount, uint _fee, bytes memory _params) internal pure  returns (CompCreateData memory compCreate, ExchangeData memory exchangeData) {

        CompoundCreateTaker.CreateInfo memory createData;
        address proxy;

        (createData , exchangeData, proxy)= abi.decode(_params, (CompoundCreateTaker.CreateInfo, ExchangeData, address));

        bytes memory proxyData = abi.encodeWithSignature(
            "open(address,address,uint256)",
                                createData.cCollAddress, createData.cBorrowAddress, (_amount + _fee));


        compCreate = CompCreateData({
            proxyAddr: payable(proxy),
            proxyData: proxyData,
            cCollAddr: createData.cCollAddress,
            cDebtAddr: createData.cBorrowAddress
        });

        return (compCreate, exchangeData);
    }

    /// @notice Send the FL funds received to DSProxy
    /// @param _proxy DSProxy address
    /// @param _reserve Token address
    function sendToProxy(address payable _proxy, address _reserve) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, ERC20(_reserve).balanceOf(address(this)));
        } else {
            _proxy.transfer(address(this).balance);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external override(FlashLoanReceiverBase, DFSExchangeCore) payable {}
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/ILendingPool.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../auth/ProxyPermission.sol";
import "../../exchangeV3/DFSExchangeData.sol";
import "../../utils/SafeERC20.sol";

/// @title Opens compound positions with a leverage
contract CompoundCreateTaker is ProxyPermission {
    using SafeERC20 for ERC20;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    struct CreateInfo {
        address cCollAddress;
        address cBorrowAddress;
        uint depositAmount;
    }

    /// @notice Main function which will take a FL and open a leverage position
    /// @dev Call through DSProxy, if _exchangeData.destAddr is a token approve DSProxy
    /// @param _createInfo [cCollAddress, cBorrowAddress, depositAmount]
    /// @param _exchangeData Exchange data struct
    function openLeveragedLoan(
        CreateInfo memory _createInfo,
        DFSExchangeData.ExchangeData memory _exchangeData,
        address payable _compReceiver
    ) public payable {
        uint loanAmount = _exchangeData.srcAmount;

        // Pull tokens from user
        if (_exchangeData.destAddr != ETH_ADDRESS) {
            ERC20(_exchangeData.destAddr).safeTransferFrom(msg.sender, address(this), _createInfo.depositAmount);
        } else {
            require(msg.value >= _createInfo.depositAmount, "Must send correct amount of eth");
        }

        // Send tokens to FL receiver
        sendDeposit(_compReceiver, _exchangeData.destAddr);

        bytes memory paramsData = abi.encode(_createInfo, _exchangeData, address(this));

        givePermission(_compReceiver);

        lendingPool.flashLoan(_compReceiver, _exchangeData.srcAddr, loanAmount, paramsData);

        removePermission(_compReceiver);

        logger.Log(address(this), msg.sender, "CompoundLeveragedLoan",
            abi.encode(_exchangeData.srcAddr, _exchangeData.destAddr, _exchangeData.srcAmount, _exchangeData.destAmount));
    }

    function sendDeposit(address payable _compoundReceiver, address _token) internal {
        if (_token != ETH_ADDRESS) {
            ERC20(_token).safeTransfer(_compoundReceiver, ERC20(_token).balanceOf(address(this)));
        }

        _compoundReceiver.transfer(address(this).balance);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../saver/RAISaverProxy.sol";
import "../../exchangeV3/DFSExchangeData.sol";
import "../../utils/GasBurner.sol";
import "../../interfaces/ILendingPool.sol";
import "../../utils/DydxFlashLoanBase.sol";

contract RAISaverTaker is RAISaverProxy, DydxFlashLoanBase, GasBurner {
    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct SaverData {
        uint256 flAmount;
        bool isRepay;
        uint256 safeId;
        uint256 gasCost;
        address joinAddr;
        ManagerType managerType;
    }

    function boostWithLoan(
        ExchangeData memory _exchangeData,
        uint256 _safeId,
        uint256 _gasCost,
        address _joinAddr,
        ManagerType _managerType,
        address _raiSaverFlashLoan
    ) public payable burnGas(25) {
        address managerAddr = getManagerAddr(_managerType);

        uint256 maxDebt =
            getMaxDebt(managerAddr, _safeId, ISAFEManager(managerAddr).collateralTypes(_safeId));

        if (maxDebt >= _exchangeData.srcAmount) {
            if (_exchangeData.srcAmount > maxDebt) {
                _exchangeData.srcAmount = maxDebt;
            }

            boost(_exchangeData, _safeId, _gasCost, _joinAddr, _managerType);
            return;
        }

        uint256 loanAmount = getAvailableEthLiquidity();

        SaverData memory saverData =
            SaverData({
                flAmount: loanAmount,
                isRepay: false,
                safeId: _safeId,
                gasCost: _gasCost,
                joinAddr: _joinAddr,
                managerType: _managerType
            });

        _flashLoan(_raiSaverFlashLoan, _exchangeData, saverData);
    }

    function repayWithLoan(
        ExchangeData memory _exchangeData,
        uint256 _safeId,
        uint256 _gasCost,
        address _joinAddr,
        ManagerType _managerType,
        address _raiSaverFlashLoan
    ) public payable burnGas(25) {
        address managerAddr = getManagerAddr(_managerType);

        uint256 maxColl =
            getMaxCollateral(
                managerAddr,
                _safeId,
                ISAFEManager(managerAddr).collateralTypes(_safeId),
                _joinAddr
            );

        if (maxColl >= _exchangeData.srcAmount) {
            if (_exchangeData.srcAmount > maxColl) {
                _exchangeData.srcAmount = maxColl;
            }

            repay(_exchangeData, _safeId, _gasCost, _joinAddr, _managerType);
            return;
        }

        uint256 loanAmount = _exchangeData.srcAmount;

        SaverData memory saverData =
            SaverData({
                flAmount: loanAmount,
                isRepay: true,
                safeId: _safeId,
                gasCost: _gasCost,
                joinAddr: _joinAddr,
                managerType: _managerType
            });

        _flashLoan(_raiSaverFlashLoan, _exchangeData, saverData);
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _managerAddr Address of the CDP Manager
    /// @param _safeId Id of the CDP
    /// @param _collType Coll type of the CDP
    function getMaxDebt(
        address _managerAddr,
        uint256 _safeId,
        bytes32 _collType
    ) public override view returns (uint256) {
        (uint256 collateral, uint256 debt) =
            getSafeInfo(ISAFEManager(_managerAddr), _safeId, _collType);

        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        return sub(rmul(collateral, safetyPrice), debt);
    }

    /// @notice Fetches Eth Dydx liqudity
    function getAvailableEthLiquidity() internal view returns (uint256 liquidity) {
        liquidity = ERC20(WETH_ADDR).balanceOf(SOLO_MARGIN_ADDRESS);
    }

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must send 2 wei with this transaction
    function _flashLoan(address RAI_SAVER_FLASH_LOAN, ExchangeData memory _exchangeData, SaverData memory _saverData) internal {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        address managerAddr = getManagerAddr(_saverData.managerType);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_saverData.flAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _saverData.flAmount, RAI_SAVER_FLASH_LOAN);
        payable(RAI_SAVER_FLASH_LOAN).transfer(msg.value); // 0x fee

        bytes memory exchangeData = packExchangeData(_exchangeData);
        operations[1] = _getCallAction(abi.encode(exchangeData, _saverData), RAI_SAVER_FLASH_LOAN);

        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        ISAFEManager(managerAddr).allowSAFE(_saverData.safeId, RAI_SAVER_FLASH_LOAN, 1);
        solo.operate(accountInfos, operations);
        ISAFEManager(managerAddr).allowSAFE(_saverData.safeId, RAI_SAVER_FLASH_LOAN, 0);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../utils/SafeMath.sol";
import "../savings/dydx/ISoloMargin.sol";

contract DydxFlashLoanBase {
    using SafeMath for uint256;

    address public constant SOLO_MARGIN_ADDRESS = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    function _getMarketIdFromTokenAddress(address token)
        internal
        view
        returns (uint256)
    {
        return 0;
    }

    function _getRepaymentAmountInternal(uint256 amount)
        internal
        view
        returns (uint256)
    {
        // Needs to be overcollateralize
        // Needs to provide +2 wei to be safe
        return amount.add(2);
    }

    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 1});
    }

    function _getWithdrawAction(uint marketId, uint256 amount, address contractAddr)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: contractAddr,
                otherAccountId: 0,
                data: ""
            });
    }

    function _getCallAction(bytes memory data, address contractAddr)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: 0
                }),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: contractAddr,
                otherAccountId: 0,
                data: data
            });
    }

    function _getDepositAction(uint marketId, uint256 amount, address contractAddr)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: contractAddr,
                otherAccountId: 0,
                data: ""
            });
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


library Account {
    enum Status {Normal, Liquid, Vapor}
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
    struct Storage {
        mapping(uint256 => Types.Par) balances; // Mapping from marketId to principal
        Status status;
    }
}


library Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (public virtually)
        Sell, // sell an amount of some token (public virtually)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AccountLayout {OnePrimary, TwoPrimary, PrimaryAndSecondary}

    enum MarketLayout {ZeroMarkets, OneMarket, TwoMarkets}

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }
}


library Decimal {
    struct D256 {
        uint256 value;
    }
}


library Interest {
    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }
}


library Monetary {
    struct Price {
        uint256 value;
    }
    struct Value {
        uint256 value;
    }
}


library Storage {
    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;
        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;
        // Interest index of the market
        Interest.Index index;
        // Contract address of the price oracle for this market
        address priceOracle;
        // Contract address of the interest setter for this market
        address interestSetter;
        // Multiplier on the marginRatio for this market
        Decimal.D256 marginPremium;
        // Multiplier on the liquidationSpread for this market
        Decimal.D256 spreadPremium;
        // Whether additional borrows are allowed for this market
        bool isClosing;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;
        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;
        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;
        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        uint64 marginRatioMax;
        uint64 liquidationSpreadMax;
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of Solo
    struct State {
        // number of markets
        uint256 numMarkets;
        // marketId => Market
        mapping(uint256 => Market) markets;
        // owner => account number => Account
        mapping(address => mapping(uint256 => Account.Storage)) accounts;
        // Addresses that can control other users accounts
        mapping(address => mapping(address => bool)) operators;
        // Addresses that can control all users accounts
        mapping(address => bool) globalOperators;
        // mutable risk parameters of the system
        RiskParams riskParams;
        // immutable risk limits of the system
        RiskLimits riskLimits;
    }
}


library Types {
    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}


abstract contract ISoloMargin {
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    ) public virtual;

    function getIsGlobalOperator(address operator) public virtual view returns (bool);

    function getMarketTokenAddress(uint256 marketId)
        public virtual
        view
        returns (address);

    function ownerSetInterestSetter(uint256 marketId, address interestSetter)
        public virtual;

    function getAccountValues(Account.Info memory account)
        public virtual
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketPriceOracle(uint256 marketId)
        public virtual
        view
        returns (address);

    function getMarketInterestSetter(uint256 marketId)
        public virtual
        view
        returns (address);

    function getMarketSpreadPremium(uint256 marketId)
        public virtual
        view
        returns (Decimal.D256 memory);

    function getNumMarkets() public virtual view returns (uint256);

    function ownerWithdrawUnsupportedTokens(address token, address recipient)
        public virtual
        returns (uint256);

    function ownerSetMinBorrowedValue(Monetary.Value memory minBorrowedValue)
        public virtual;

    function ownerSetLiquidationSpread(Decimal.D256 memory spread) public virtual;

    function ownerSetEarningsRate(Decimal.D256 memory earningsRate) public virtual;

    function getIsLocalOperator(address owner, address operator)
        public virtual
        view
        returns (bool);

    function getAccountPar(Account.Info memory account, uint256 marketId)
        public virtual
        view
        returns (Types.Par memory);

    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal.D256 memory marginPremium
    ) public virtual;

    function getMarginRatio() public virtual view returns (Decimal.D256 memory);

    function getMarketCurrentIndex(uint256 marketId)
        public virtual
        view
        returns (Interest.Index memory);

    function getMarketIsClosing(uint256 marketId) public virtual view returns (bool);

    function getRiskParams() public virtual view returns (Storage.RiskParams memory);

    function getAccountBalances(Account.Info memory account)
        public virtual
        view
        returns (address[] memory, Types.Par[] memory, Types.Wei[] memory);

    function renounceOwnership() public virtual;

    function getMinBorrowedValue() public virtual view returns (Monetary.Value memory);

    function setOperators(OperatorArg[] memory args) public virtual;

    function getMarketPrice(uint256 marketId) public virtual view returns (address);

    function owner() public virtual view returns (address);

    function isOwner() public virtual view returns (bool);

    function ownerWithdrawExcessTokens(uint256 marketId, address recipient)
        public virtual
        returns (uint256);

    function ownerAddMarket(
        address token,
        address priceOracle,
        address interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium
    ) public virtual;

    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) public virtual;

    function getMarketWithInfo(uint256 marketId)
        public virtual
        view
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

    function ownerSetMarginRatio(Decimal.D256 memory ratio) public virtual;

    function getLiquidationSpread() public virtual view returns (Decimal.D256 memory);

    function getAccountWei(Account.Info memory account, uint256 marketId)
        public virtual
        view
        returns (Types.Wei memory);

    function getMarketTotalPar(uint256 marketId)
        public virtual
        view
        returns (Types.TotalPar memory);

    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) public virtual view returns (Decimal.D256 memory);

    function getNumExcessTokens(uint256 marketId)
        public virtual
        view
        returns (Types.Wei memory);

    function getMarketCachedIndex(uint256 marketId)
        public virtual
        view
        returns (Interest.Index memory);

    function getAccountStatus(Account.Info memory account)
        public virtual
        view
        returns (uint8);

    function getEarningsRate() public virtual view returns (Decimal.D256 memory);

    function ownerSetPriceOracle(uint256 marketId, address priceOracle) public virtual;

    function getRiskLimits() public virtual view returns (Storage.RiskLimits memory);

    function getMarket(uint256 marketId)
        public virtual
        view
        returns (Storage.Market memory);

    function ownerSetIsClosing(uint256 marketId, bool isClosing) public virtual;

    function ownerSetGlobalOperator(address operator, bool approved) public virtual;

    function transferOwnership(address newOwner) public virtual;

    function getAdjustedAccountValues(Account.Info memory account)
        public virtual
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketMarginPremium(uint256 marketId)
        public virtual
        view
        returns (Decimal.D256 memory);

    function getMarketInterestRate(uint256 marketId)
        public virtual
        view
        returns (Interest.Rate memory);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../auth/ProxyPermission.sol";
import "../utils/DydxFlashLoanBase.sol";
import "../loggers/DefisaverLogger.sol";
import "../interfaces/ERC20.sol";


/// @title Takes flash loan
contract DyDxFlashLoanTaker is DydxFlashLoanBase, ProxyPermission {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    /// @notice Takes flash loan for _receiver
    /// @dev Receiver must send back WETH + 2 wei after executing transaction
    /// @dev Method is meant to be called from proxy and proxy will give authorization to _receiver
    /// @param _receiver Address of funds receiver
    /// @param _ethAmount ETH amount that needs to be pulled from dydx    
    /// @param _encodedData Bytes with packed data
    function takeLoan(address _receiver, uint256 _ethAmount, bytes memory _encodedData) public {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_ethAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _ethAmount, _receiver);
        operations[1] = _getCallAction(
            _encodedData,
            _receiver
        );
        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        givePermission(_receiver);
        solo.operate(accountInfos, operations);
        removePermission(_receiver);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "DyDxFlashLoanTaken", abi.encode(_receiver, _ethAmount, _encodedData));
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ProtocolInterface.sol";
import "../interfaces/ERC20.sol";
import "../interfaces/ITokenInterface.sol";
import "../interfaces/ComptrollerInterface.sol";
import "./dydx/ISoloMargin.sol";
import "./SavingsLogger.sol";
import "./dsr/DSRSavingsProtocol.sol";
import "./compound/CompoundSavingsProtocol.sol";


contract SavingsProxy is DSRSavingsProtocol, CompoundSavingsProtocol {
    address public constant ADAI_ADDRESS = 0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d;

    address public constant SAVINGS_DYDX_ADDRESS = 0x03b1565e070df392e48e7a8e01798C4B00E534A5;
    address public constant SAVINGS_AAVE_ADDRESS = 0x535B9035E9bA8D7efe0FeAEac885fb65b303E37C;
    address public constant NEW_IDAI_ADDRESS = 0x493C57C4763932315A328269E1ADaD09653B9081;

    address public constant COMP_ADDRESS = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address public constant SAVINGS_LOGGER_ADDRESS = 0x89b3635BD2bAD145C6f92E82C9e83f06D5654984;
    address public constant SOLO_MARGIN_ADDRESS = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    enum SavingsProtocol {Compound, Dydx, Fulcrum, Dsr, Aave}

    function deposit(SavingsProtocol _protocol, uint256 _amount) public {
        if (_protocol == SavingsProtocol.Dsr) {
            dsrDeposit(_amount, true);
        } else if (_protocol == SavingsProtocol.Compound) {
            compDeposit(msg.sender, _amount);
        } else {
            _deposit(_protocol, _amount, true);
        }

        SavingsLogger(SAVINGS_LOGGER_ADDRESS).logDeposit(msg.sender, uint8(_protocol), _amount);
    }

    function withdraw(SavingsProtocol _protocol, uint256 _amount) public {
        if (_protocol == SavingsProtocol.Dsr) {
            dsrWithdraw(_amount, true);
        } else if (_protocol == SavingsProtocol.Compound) {
            compWithdraw(msg.sender, _amount);
        } else {
            _withdraw(_protocol, _amount, true);
        }

        SavingsLogger(SAVINGS_LOGGER_ADDRESS).logWithdraw(msg.sender, uint8(_protocol), _amount);
    }

    function swap(SavingsProtocol _from, SavingsProtocol _to, uint256 _amount) public {
        if (_from == SavingsProtocol.Dsr) {
            dsrWithdraw(_amount, false);
        } else if (_from == SavingsProtocol.Compound) {
            compWithdraw(msg.sender, _amount);
        } else {
            _withdraw(_from, _amount, false);
        }

        // possible to withdraw 1-2 wei less than actual amount due to division precision
        // so we deposit all amount on DSProxy
        uint256 amountToDeposit = ERC20(DAI_ADDRESS).balanceOf(address(this));

        if (_to == SavingsProtocol.Dsr) {
            dsrDeposit(amountToDeposit, false);
        } else if (_from == SavingsProtocol.Compound) {
            compDeposit(msg.sender, _amount);
        } else {
            _deposit(_to, amountToDeposit, false);
        }

        SavingsLogger(SAVINGS_LOGGER_ADDRESS).logSwap(
            msg.sender,
            uint8(_from),
            uint8(_to),
            _amount
        );
    }

    function withdrawDai() public {
        ERC20(DAI_ADDRESS).transfer(msg.sender, ERC20(DAI_ADDRESS).balanceOf(address(this)));
    }

    function claimComp() public {
        ComptrollerInterface(COMP_ADDRESS).claimComp(address(this));
    }

    function getAddress(SavingsProtocol _protocol) public pure returns (address) {

        if (_protocol == SavingsProtocol.Dydx) {
            return SAVINGS_DYDX_ADDRESS;
        }

        if (_protocol == SavingsProtocol.Aave) {
            return SAVINGS_AAVE_ADDRESS;
        }
    }

    function _deposit(SavingsProtocol _protocol, uint256 _amount, bool _fromUser) internal {
        if (_fromUser) {
            ERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount);
        }

        approveDeposit(_protocol);

        ProtocolInterface(getAddress(_protocol)).deposit(address(this), _amount);

        endAction(_protocol);
    }

    function _withdraw(SavingsProtocol _protocol, uint256 _amount, bool _toUser) public {
        approveWithdraw(_protocol);

        ProtocolInterface(getAddress(_protocol)).withdraw(address(this), _amount);

        endAction(_protocol);

        if (_toUser) {
            withdrawDai();
        }
    }

    function endAction(SavingsProtocol _protocol) internal {
        if (_protocol == SavingsProtocol.Dydx) {
            setDydxOperator(false);
        }
    }

    function approveDeposit(SavingsProtocol _protocol) internal {
        if (_protocol == SavingsProtocol.Compound || _protocol == SavingsProtocol.Fulcrum || _protocol == SavingsProtocol.Aave) {
            ERC20(DAI_ADDRESS).approve(getAddress(_protocol), uint256(-1));
        }

        if (_protocol == SavingsProtocol.Dydx) {
            ERC20(DAI_ADDRESS).approve(SOLO_MARGIN_ADDRESS, uint256(-1));
            setDydxOperator(true);
        }
    }

    function approveWithdraw(SavingsProtocol _protocol) internal {
        if (_protocol == SavingsProtocol.Compound) {
            ERC20(NEW_CDAI_ADDRESS).approve(getAddress(_protocol), uint256(-1));
        }

        if (_protocol == SavingsProtocol.Dydx) {
            setDydxOperator(true);
        }

        if (_protocol == SavingsProtocol.Fulcrum) {
            ERC20(NEW_IDAI_ADDRESS).approve(getAddress(_protocol), uint256(-1));
        }

        if (_protocol == SavingsProtocol.Aave) {
            ERC20(ADAI_ADDRESS).approve(getAddress(_protocol), uint256(-1));
        }
    }

    function setDydxOperator(bool _trusted) internal {
        ISoloMargin.OperatorArg[] memory operatorArgs = new ISoloMargin.OperatorArg[](1);
        operatorArgs[0] = ISoloMargin.OperatorArg({
            operator: getAddress(SavingsProtocol.Dydx),
            trusted: _trusted
        });

        ISoloMargin(SOLO_MARGIN_ADDRESS).setOperators(operatorArgs);
    }
}

pragma solidity ^0.6.0;

abstract contract ProtocolInterface {
    function deposit(address _user, uint256 _amount) public virtual;

    function withdraw(address _user, uint256 _amount) public virtual;
}

pragma solidity ^0.6.0;

import "./ERC20.sol";

abstract contract ITokenInterface is ERC20 {
    function assetBalanceOf(address _owner) public virtual view returns (uint256);

    function mint(address receiver, uint256 depositAmount) external virtual returns (uint256 mintAmount);

    function burn(address receiver, uint256 burnAmount) external virtual returns (uint256 loanAmountPaid);

    function tokenPrice() public virtual view returns (uint256 price);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

abstract contract ComptrollerInterface {
    struct CompMarketState {
        uint224 index;
        uint32 block;
    }

    function claimComp(address holder) public virtual;
    function claimComp(address holder, address[] memory cTokens) public virtual;
    function claimComp(address[] memory holders, address[] memory cTokens, bool borrowers, bool suppliers) public virtual;

    function compSupplyState(address) public view virtual returns (CompMarketState memory);
    function compSupplierIndex(address,address) public view virtual returns (uint);
    function compAccrued(address) public view virtual returns (uint);

    function compBorrowState(address) public view virtual returns (CompMarketState memory);
    function compBorrowerIndex(address,address) public view virtual returns (uint);

    function enterMarkets(address[] calldata cTokens) external virtual returns (uint256[] memory);

    function exitMarket(address cToken) external virtual returns (uint256);

    function getAssetsIn(address account) external virtual view returns (address[] memory);

    function markets(address account) public virtual view returns (bool, uint256);

    function getAccountLiquidity(address account) external virtual view returns (uint256, uint256, uint256);

    function oracle() public virtual view returns (address);

    function borrowCaps(address) external virtual returns (uint256);
}

pragma solidity ^0.6.0;

contract SavingsLogger {
    event Deposit(address indexed sender, uint8 protocol, uint256 amount);
    event Withdraw(address indexed sender, uint8 protocol, uint256 amount);
    event Swap(address indexed sender, uint8 fromProtocol, uint8 toProtocol, uint256 amount);

    function logDeposit(address _sender, uint8 _protocol, uint256 _amount) external {
        emit Deposit(_sender, _protocol, _amount);
    }

    function logWithdraw(address _sender, uint8 _protocol, uint256 _amount) external {
        emit Withdraw(_sender, _protocol, _amount);
    }

    function logSwap(address _sender, uint8 _protocolFrom, uint8 _protocolTo, uint256 _amount)
        external
    {
        emit Swap(_sender, _protocolFrom, _protocolTo, _amount);
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/Join.sol";
import "../../DS/DSMath.sol";

abstract contract VatLike {
    function can(address, address) virtual public view returns (uint);
    function ilks(bytes32) virtual public view returns (uint, uint, uint, uint, uint);
    function dai(address) virtual public view returns (uint);
    function urns(bytes32, address) virtual public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
}

abstract contract PotLike {
    function pie(address) virtual public view returns (uint);
    function drip() virtual public returns (uint);
    function join(uint) virtual public;
    function exit(uint) virtual public;
}

abstract contract GemLike {
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
}

abstract contract DaiJoinLike {
    function vat() virtual public returns (VatLike);
    function dai() virtual public returns (GemLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

contract DSRSavingsProtocol is DSMath {

    // Mainnet
    address public constant POT_ADDRESS = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    function dsrDeposit(uint _amount, bool _fromUser) internal {
        VatLike vat = DaiJoinLike(DAI_JOIN_ADDRESS).vat();

        uint chi = PotLike(POT_ADDRESS).drip();

        daiJoin_join(DAI_JOIN_ADDRESS, address(this), _amount, _fromUser);

        if (vat.can(address(this), address(POT_ADDRESS)) == 0) {
            vat.hope(POT_ADDRESS);
        }

        PotLike(POT_ADDRESS).join(mul(_amount, RAY) / chi);
    }

    function dsrWithdraw(uint _amount, bool _toUser) internal {
        VatLike vat = DaiJoinLike(DAI_JOIN_ADDRESS).vat();

        uint chi = PotLike(POT_ADDRESS).drip();
        uint pie = mul(_amount, RAY) / chi;

        PotLike(POT_ADDRESS).exit(pie);
        uint balance = DaiJoinLike(DAI_JOIN_ADDRESS).vat().dai(address(this));

        if (vat.can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            vat.hope(DAI_JOIN_ADDRESS);
        }

        address to;
        if (_toUser) {
            to = msg.sender;
        } else {
            to = address(this);
        }

        if (_amount == uint(-1)) {
            DaiJoinLike(DAI_JOIN_ADDRESS).exit(to, mul(chi, pie) / RAY);
        } else {
            DaiJoinLike(DAI_JOIN_ADDRESS).exit(
                to,
                balance >= mul(_amount, RAY) ? _amount : balance / RAY
            );
        }
    }

    function daiJoin_join(address apt, address urn, uint wad, bool _fromUser) internal {
        if (_fromUser) {
            DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);
        }

        DaiJoinLike(apt).dai().approve(apt, wad);

        DaiJoinLike(apt).join(urn, wad);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../compound/helpers/Exponential.sol";
import "../../interfaces/ERC20.sol";

contract CompoundSavingsProtocol {

    address public constant NEW_CDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    CTokenInterface public constant cDaiContract = CTokenInterface(NEW_CDAI_ADDRESS);

    function compDeposit(address _user, uint _amount) internal {
        // get dai from user
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        // mainnet only
        ERC20(DAI_ADDRESS).approve(NEW_CDAI_ADDRESS, uint(-1));

        // mint cDai
        require(cDaiContract.mint(_amount) == 0, "Failed Mint");
    }

    function compWithdraw(address _user, uint _amount) internal {
        // transfer all users balance to this contract
        require(cDaiContract.transferFrom(_user, address(this), ERC20(NEW_CDAI_ADDRESS).balanceOf(_user)));

        // approve cDai to compound contract
        cDaiContract.approve(NEW_CDAI_ADDRESS, uint(-1));
        // get dai from cDai contract
        require(cDaiContract.redeemUnderlying(_amount) == 0, "Reedem Failed");

        // return to user balance we didn't spend
        uint cDaiBalance = cDaiContract.balanceOf(address(this));
        if (cDaiBalance > 0) {
            cDaiContract.transfer(_user, cDaiBalance);
        }
        // return dai we have to user
        ERC20(DAI_ADDRESS).transfer(_user, _amount);
    }
}

pragma solidity ^0.6.0;

import "./Gem.sol";

abstract contract Join {
    bytes32 public ilk;

    function dec() virtual public view returns (uint);
    function gem() virtual public view returns (Gem);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

pragma solidity ^0.6.0;

abstract contract Gem {
    function dec() virtual public returns (uint);
    function gem() virtual public returns (Gem);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;

    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public returns (bool);
    function transferFrom(address, address, uint) virtual public returns (bool);
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
    function allowance(address, address) virtual public returns (uint);
}

pragma solidity ^0.6.0;

import "./CarefulMath.sol";

contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
}

pragma solidity ^0.6.0;

contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/CEtherInterface.sol";
import "../../interfaces/CompoundOracleInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ComptrollerInterface.sol";
import "../../interfaces/IFeeRecipient.sol";

import "../../utils/Discount.sol";
import "../../DS/DSMath.sol";
import "../../DS/DSProxy.sol";
import "../../compound/helpers/Exponential.sol";
import "../../utils/BotRegistry.sol";

import "../../utils/SafeERC20.sol";

/// @title Utlity functions for cream contracts
contract CreamSaverHelper is DSMath, Exponential {

    using SafeERC20 for ERC20;

    IFeeRecipient public constant feeRecipient = IFeeRecipient(0x39C4a92Dc506300c3Ea4c67ca4CA611102ee6F2A);

    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0xD06527D5e56A3495252A528C4987003b712860eE;
    address public constant COMPTROLLER = 0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    /// @notice Helper method to payback the cream debt
    /// @dev If amount is bigger it will repay the whole debt and send the extra to the _user
    /// @param _amount Amount of tokens we want to repay
    /// @param _cBorrowToken Ctoken address we are repaying
    /// @param _borrowToken Token address we are repaying
    /// @param _user Owner of the cream position we are paying back
    function paybackDebt(uint _amount, address _cBorrowToken, address _borrowToken, address payable _user) internal {
        uint wholeDebt = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(address(this));

        if (_amount > wholeDebt) {
            if (_borrowToken == ETH_ADDRESS) {
                _user.transfer((_amount - wholeDebt));
            } else {
                ERC20(_borrowToken).safeTransfer(_user, (_amount - wholeDebt));
            }

            _amount = wholeDebt;
        }

        approveCToken(_borrowToken, _cBorrowToken);

        if (_borrowToken == ETH_ADDRESS) {
            CEtherInterface(_cBorrowToken).repayBorrow{value: _amount}();
        } else {
            require(CTokenInterface(_cBorrowToken).repayBorrow(_amount) == 0);
        }
    }

    /// @notice Calculates the fee amount
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _cTokenAddr CToken addr. of token we are getting for the fee
    /// @return feeAmount The amount we took for the fee
    function getFee(uint _amount, address _user, uint _gasCost, address _cTokenAddr) internal returns (uint feeAmount) {
        uint fee = MANUAL_SERVICE_FEE;

        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            fee = AUTOMATIC_SERVICE_FEE;
        }

        address tokenAddr = getUnderlyingAddr(_cTokenAddr);

        if (Discount(DISCOUNT_ADDR).isCustomFeeSet(_user)) {
            fee = Discount(DISCOUNT_ADDR).getCustomServiceFee(_user);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        if (_gasCost != 0) {
            address oracle = ComptrollerInterface(COMPTROLLER).oracle();

            uint ethTokenPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(_cTokenAddr);

            _gasCost = wdiv(_gasCost, ethTokenPrice);

            feeAmount = add(feeAmount, _gasCost);
        }

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        address walletAddr = feeRecipient.getFeeAddr();


        if (tokenAddr == ETH_ADDRESS) {
            payable(walletAddr).transfer(feeAmount);
        } else {
            ERC20(tokenAddr).safeTransfer(walletAddr, feeAmount);
        }
    }

    /// @notice Calculates the gas cost of transaction and send it to wallet
    /// @param _amount Amount that is converted
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _cTokenAddr CToken addr. of token we are getting for the fee
    /// @return feeAmount The amount we took for the fee
    function getGasCost(uint _amount, uint _gasCost, address _cTokenAddr) internal returns (uint feeAmount) {
        address tokenAddr = getUnderlyingAddr(_cTokenAddr);

        if (_gasCost != 0) {
            address oracle = ComptrollerInterface(COMPTROLLER).oracle();

            uint ethTokenPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(_cTokenAddr);

            feeAmount = wdiv(_gasCost, ethTokenPrice);
        }

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        address walletAddr = feeRecipient.getFeeAddr();

        if (tokenAddr == ETH_ADDRESS) {
            payable(walletAddr).transfer(feeAmount);
        } else {
            ERC20(tokenAddr).safeTransfer(walletAddr, feeAmount);
        }
    }

    /// @notice Enters the market for the collatera and borrow tokens
    /// @param _cTokenAddrColl Collateral address we are entering the market in
    /// @param _cTokenAddrBorrow Borrow address we are entering the market in
    function enterMarket(address _cTokenAddrColl, address _cTokenAddrBorrow) internal {
        address[] memory markets = new address[](2);
        markets[0] = _cTokenAddrColl;
        markets[1] = _cTokenAddrBorrow;

        ComptrollerInterface(COMPTROLLER).enterMarkets(markets);
    }

    /// @notice Approves CToken contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _cTokenAddr Address which will gain the approval
    function approveCToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).safeApprove(_cTokenAddr, uint(-1));
        }
    }

    /// @notice Returns the underlying address of the cToken asset
    /// @param _cTokenAddress cToken address
    /// @return Token address of the cToken specified
    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    /// @notice Returns the owner of the DSProxy that called the contract
    function getUserAddress() internal view returns (address) {
        DSProxy proxy = DSProxy(uint160(address(this)));

        return proxy.owner();
    }

    /// @notice Returns the maximum amount of collateral available to withdraw
    /// @dev Due to rounding errors the result is - 1% wei from the exact amount
    /// @param _cCollAddress Collateral we are getting the max value of
    /// @param _account Users account
    /// @return Returns the max. collateral amount in that token
    function getMaxCollateral(address _cCollAddress, address _account) public returns (uint) {
        (, uint liquidityInEth, ) = ComptrollerInterface(COMPTROLLER).getAccountLiquidity(_account);
        uint usersBalance = CTokenInterface(_cCollAddress).balanceOfUnderlying(_account);
        address oracle = ComptrollerInterface(COMPTROLLER).oracle();

        if (liquidityInEth == 0) return usersBalance;

        CTokenInterface(_cCollAddress).accrueInterest();

         if (_cCollAddress == CETH_ADDRESS) {
             if (liquidityInEth > usersBalance) return usersBalance;

             return sub(liquidityInEth, (liquidityInEth / 100));
         }

        uint ethPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(_cCollAddress);
        uint liquidityInToken = wdiv(liquidityInEth, ethPrice);

        if (liquidityInToken > usersBalance) return usersBalance;

        return sub(liquidityInToken, (liquidityInToken / 100)); // cut off 1% due to rounding issues
    }

    /// @notice Returns the maximum amount of borrow amount available
    /// @dev Due to rounding errors the result is - 1% wei from the exact amount
    /// @param _cBorrowAddress Borrow token we are getting the max value of
    /// @param _account Users account
    /// @return Returns the max. borrow amount in that token
    function getMaxBorrow(address _cBorrowAddress, address _account) public returns (uint) {
        (, uint liquidityInEth, ) = ComptrollerInterface(COMPTROLLER).getAccountLiquidity(_account);
        address oracle = ComptrollerInterface(COMPTROLLER).oracle();

        CTokenInterface(_cBorrowAddress).accrueInterest();

        if (_cBorrowAddress == CETH_ADDRESS) return sub(liquidityInEth, (liquidityInEth / 100));

        uint ethPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(_cBorrowAddress);
        uint liquidityInToken = wdiv(liquidityInEth, ethPrice);

        return sub(liquidityInToken, (liquidityInToken / 100)); // cut off 1% due to rounding issues
    }
}

pragma solidity ^0.6.0;

abstract contract CEtherInterface {
    function mint() external virtual payable;
    function repayBorrow() external virtual payable;
}

pragma solidity ^0.6.0;

abstract contract CompoundOracleInterface {
    function getUnderlyingPrice(address cToken) external view virtual returns (uint);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../exchange/SaverExchangeCore.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../utils/Discount.sol";
import "../helpers/CreamSaverHelper.sol";
import "../../loggers/DefisaverLogger.sol";

/// @title Implements the actual logic of Repay/Boost with FL
contract CreamSaverFlashProxy is SaverExchangeCore, CreamSaverHelper  {

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    using SafeERC20 for ERC20;

    /// @notice Repays the position and sends tokens back for FL
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for transaction
    /// @param _flashLoanData Data about FL [amount, fee]
    function flashRepay(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());
        uint flashBorrowed = _flashLoanData[0] + _flashLoanData[1];

        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));

        // draw max coll
        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(maxColl) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            // swap max coll + loanAmount
            _exData.srcAmount = maxColl + _flashLoanData[0];
            (,swapAmount) = _sell(_exData);

            // get fee
            swapAmount -= getFee(swapAmount, user, _gasCost, _cAddresses[1]);
        } else {
            swapAmount = (maxColl + _flashLoanData[0]);
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        // payback debt
        paybackDebt(swapAmount, _cAddresses[1], borrowToken, user);

        // draw collateral for loanAmount + loanFee
        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(flashBorrowed) == 0);

        // repay flash loan
        returnFlashLoan(collToken, flashBorrowed);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CreamRepay", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Boosts the position and sends tokens back for FL
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    /// @param _flashLoanData Data about FL [amount, fee]
    function flashBoost(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());
        uint flashBorrowed = _flashLoanData[0] + _flashLoanData[1];

        // borrow max amount
        uint borrowAmount = getMaxBorrow(_cAddresses[1], address(this));
        require(CTokenInterface(_cAddresses[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            // get dfs fee
            borrowAmount -= getFee((borrowAmount + _flashLoanData[0]), user, _gasCost, _cAddresses[1]);
            _exData.srcAmount = (borrowAmount + _flashLoanData[0]);

            (,swapAmount) = _sell(_exData);
        } else {
            swapAmount = (borrowAmount + _flashLoanData[0]);
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        // deposit swaped collateral
        depositCollateral(collToken, _cAddresses[0], swapAmount);

        // borrow token to repay flash loan
        require(CTokenInterface(_cAddresses[1]).borrow(flashBorrowed) == 0);

        // repay flash loan
        returnFlashLoan(borrowToken, flashBorrowed);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CreamBoost", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Helper method to deposit tokens in Compound
    /// @param _collToken Token address of the collateral
    /// @param _cCollToken CToken address of the collateral
    /// @param _depositAmount Amount to deposit
    function depositCollateral(address _collToken, address _cCollToken, uint _depositAmount) internal {
        approveCToken(_collToken, _cCollToken);

        if (_collToken != ETH_ADDRESS) {
            require(CTokenInterface(_cCollToken).mint(_depositAmount) == 0);
        } else {
            CEtherInterface(_cCollToken).mint{value: _depositAmount}(); // reverts on fail
        }
    }

    /// @notice Returns the tokens/ether to the msg.sender which is the FL contract
    /// @param _tokenAddr Address of token which we return
    /// @param _amount Amount to return
    function returnFlashLoan(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, _amount);
        }

        msg.sender.transfer(address(this).balance);
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../DS/DSMath.sol";
import "../interfaces/TokenInterface.sol";
import "../interfaces/ExchangeInterfaceV2.sol";
import "../utils/ZrxAllowlist.sol";
import "./SaverExchangeHelper.sol";
import "./SaverExchangeRegistry.sol";

contract SaverExchangeCore is SaverExchangeHelper, DSMath {

    // first is empty to keep the legacy order in place
    enum ExchangeType { _, OASIS, KYBER, UNISWAP, ZEROX }

    enum ActionType { SELL, BUY }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint srcAmount;
        uint destAmount;
        uint minPrice;
        address wrapper;
        address exchangeAddr;
        bytes callData;
        uint256 price0x;
    }

    /// @notice Internal method that preforms a sell on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and destAmount
    function _sell(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;
        uint tokensLeft = exData.srcAmount;

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(WETH_ADDRESS).deposit.value(exData.srcAmount)();
        }

        // Try 0x first and then fallback on specific wrapper
        if (exData.price0x > 0) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            uint ethAmount = getProtocolFee(exData.srcAddr, exData.srcAmount);
            (success, swapedTokens, tokensLeft) = takeOrder(exData, ethAmount, ActionType.SELL);

            if (success) {
                wrapper = exData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.SELL);
            wrapper = exData.wrapper;
        }

        require(getBalance(exData.destAddr) >= wmul(exData.minPrice, exData.srcAmount), "Final amount isn't correct");

        // if anything is left in weth, pull it to user as eth
        if (getBalance(WETH_ADDRESS) > 0) {
            TokenInterface(WETH_ADDRESS).withdraw(
                TokenInterface(WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, swapedTokens);
    }

    /// @notice Internal method that preforms a buy on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and srcAmount
    function _buy(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;

        require(exData.destAmount != 0, "Dest amount must be specified");

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(WETH_ADDRESS).deposit.value(exData.srcAmount)();
        }

        if (exData.price0x > 0) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            uint ethAmount = getProtocolFee(exData.srcAddr, exData.srcAmount);
            (success, swapedTokens,) = takeOrder(exData, ethAmount, ActionType.BUY);

            if (success) {
                wrapper = exData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.BUY);
            wrapper = exData.wrapper;
        }

        require(getBalance(exData.destAddr) >= exData.destAmount, "Final amount isn't correct");

        // if anything is left in weth, pull it to user as eth
        if (getBalance(WETH_ADDRESS) > 0) {
            TokenInterface(WETH_ADDRESS).withdraw(
                TokenInterface(WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, getBalance(exData.destAddr));
    }

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _ethAmount Ether fee needed for 0x order
    function takeOrder(
        ExchangeData memory _exData,
        uint256 _ethAmount,
        ActionType _type
    ) private returns (bool success, uint256, uint256) {

        // write in the exact amount we are selling/buing in an order
        if (_type == ActionType.SELL) {
            writeUint256(_exData.callData, 36, _exData.srcAmount);
        } else {
            writeUint256(_exData.callData, 36, _exData.destAmount);
        }

        if (ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isNonPayableAddr(_exData.exchangeAddr)) {
            _ethAmount = 0;
        }

        uint256 tokensBefore = getBalance(_exData.destAddr);

        if (ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isZrxAddr(_exData.exchangeAddr)) {
            (success, ) = _exData.exchangeAddr.call{value: _ethAmount}(_exData.callData);
        } else {
            success = false;
        }

        uint256 tokensSwaped = 0;
        uint256 tokensLeft = _exData.srcAmount;

        if (success) {
            // check to see if any _src tokens are left over after exchange
            tokensLeft = getBalance(_exData.srcAddr);

            // convert weth -> eth if needed
            if (_exData.destAddr == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(
                    TokenInterface(WETH_ADDRESS).balanceOf(address(this))
                );
            }

            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(_exData.destAddr) - tokensBefore;
        }

        return (success, tokensSwaped, tokensLeft);
    }

    /// @notice Calls wraper contract for exchage to preform an on-chain swap
    /// @param _exData Exchange data struct
    /// @param _type Type of action SELL|BUY
    /// @return swapedTokens For Sell that the destAmount, for Buy thats the srcAmount
    function saverSwap(ExchangeData memory _exData, ActionType _type) internal returns (uint swapedTokens) {
        require(SaverExchangeRegistry(SAVER_EXCHANGE_REGISTRY).isWrapper(_exData.wrapper), "Wrapper is not valid");

        uint ethValue = 0;

        ERC20(_exData.srcAddr).safeTransfer(_exData.wrapper, _exData.srcAmount);

        if (_type == ActionType.SELL) {
            swapedTokens = ExchangeInterfaceV2(_exData.wrapper).
                    sell{value: ethValue}(_exData.srcAddr, _exData.destAddr, _exData.srcAmount);
        } else {
            swapedTokens = ExchangeInterfaceV2(_exData.wrapper).
                    buy{value: ethValue}(_exData.srcAddr, _exData.destAddr, _exData.destAmount);
        }
    }

    function writeUint256(bytes memory _b, uint256 _index, uint _input) internal pure {
        if (_b.length < _index + 32) {
            revert("Incorrent lengt while writting bytes32");
        }

        bytes32 input = bytes32(_input);

        _index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(_b, _index), input)
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }

    /// @notice Calculates protocol fee
    /// @param _srcAddr selling token address (if eth should be WETH)
    /// @param _srcAmount amount we are selling
    function getProtocolFee(address _srcAddr, uint256 _srcAmount) internal view returns(uint256) {
        // if we are not selling ETH msg value is always the protocol fee
        if (_srcAddr != WETH_ADDRESS) return address(this).balance;

        // if msg value is larger than srcAmount, that means that msg value is protocol fee + srcAmount, so we subsctract srcAmount from msg value
        // we have an edge case here when protocol fee is higher than selling amount
        if (address(this).balance > _srcAmount) return address(this).balance - _srcAmount;

        // if msg value is lower than src amount, that means that srcAmount isn't included in msg value, so we return msg value
        return address(this).balance;
    }

    function packExchangeData(ExchangeData memory _exData) public pure returns(bytes memory) {
        // splitting in two different bytes and encoding all because of stack too deep in decoding part

        bytes memory part1 = abi.encode(
            _exData.srcAddr,
            _exData.destAddr,
            _exData.srcAmount,
            _exData.destAmount
        );

        bytes memory part2 = abi.encode(
            _exData.minPrice,
            _exData.wrapper,
            _exData.exchangeAddr,
            _exData.callData,
            _exData.price0x
        );


        return abi.encode(part1, part2);
    }

    function unpackExchangeData(bytes memory _data) public pure returns(ExchangeData memory _exData) {
        (
            bytes memory part1,
            bytes memory part2
        ) = abi.decode(_data, (bytes,bytes));

        (
            _exData.srcAddr,
            _exData.destAddr,
            _exData.srcAmount,
            _exData.destAmount
        ) = abi.decode(part1, (address,address,uint256,uint256));

        (
            _exData.minPrice,
            _exData.wrapper,
            _exData.exchangeAddr,
            _exData.callData,
            _exData.price0x
        )
        = abi.decode(part2, (uint256,address,address,bytes,uint256));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}

pragma solidity ^0.6.0;

interface ExchangeInterfaceV2 {
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable returns (uint);

    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint);

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) external view returns (uint);

    function getBuyRate(address _srcAddr, address _destAddr, uint _srcAmount) external view returns (uint);
}

pragma solidity ^0.6.0;

import "../utils/SafeERC20.sol";
import "../utils/Discount.sol";

contract SaverExchangeHelper {

    using SafeERC20 for ERC20;

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant DISCOUNT_ADDRESS = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;
    address public constant SAVER_EXCHANGE_REGISTRY = 0x25dd3F51e0C3c3Ff164DDC02A8E4D65Bb9cBB12D;

    address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address public constant ZRX_ALLOWLIST_ADDR = 0x4BA1f38427b33B8ab7Bb0490200dAE1F1C36823F;


    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function getBalance(address _tokenAddr) internal view returns (uint balance) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_tokenAddr).balanceOf(address(this));
        }
    }

    function approve0xProxy(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != KYBER_ETH_ADDRESS) {
            ERC20(_tokenAddr).safeApprove(address(ERC20_PROXY_0X), _amount);
        }
    }

    function sendLeftover(address _srcAddr, address _destAddr, address payable _to) internal {
        // send back any leftover ether or tokens
        if (address(this).balance > 0) {
            _to.transfer(address(this).balance);
        }

        if (getBalance(_srcAddr) > 0) {
            ERC20(_srcAddr).safeTransfer(_to, getBalance(_srcAddr));
        }

        if (getBalance(_destAddr) > 0) {
            ERC20(_destAddr).safeTransfer(_to, getBalance(_destAddr));
        }
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../loggers/DefisaverLogger.sol";
import "../../utils/Discount.sol";

import "../../interfaces/Spotter.sol";
import "../../interfaces/Jug.sol";
import "../../interfaces/DaiJoin.sol";
import "../../interfaces/Join.sol";

import "./MCDSaverProxyHelper.sol";
import "../../utils/BotRegistry.sol";
import "../../exchangeV3/DFSExchangeCore.sol";

/// @title Implements Boost and Repay for MCD CDPs
contract MCDSaverProxy is DFSExchangeCore, MCDSaverProxyHelper {

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    bytes32 public constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant JUG_ADDRESS = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    Vat public constant vat = Vat(VAT_ADDRESS);
    DaiJoin public constant daiJoin = DaiJoin(DAI_JOIN_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Repay - draws collateral, converts to Dai and repays the debt
    /// @dev Must be called by the DSProxy contract that owns the CDP
    function repay(
        ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable {

        address managerAddr = getManagerAddr(_managerType);

        address user = getOwner(Manager(managerAddr), _cdpId);
        bytes32 ilk = Manager(managerAddr).ilks(_cdpId);

        drawCollateral(managerAddr, _cdpId, _joinAddr, _exchangeData.srcAmount);

        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        (, uint daiAmount) = _sell(_exchangeData);

        daiAmount -= takeFee(_gasCost, daiAmount);

        paybackDebt(managerAddr, _cdpId, ilk, daiAmount, user);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "MCDRepay", abi.encode(_cdpId, user, _exchangeData.srcAmount, daiAmount));

    }

    /// @notice Boost - draws Dai, converts to collateral and adds to CDP
    /// @dev Must be called by the DSProxy contract that owns the CDP
    function boost(
        ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable {

        address managerAddr = getManagerAddr(_managerType);

        address user = getOwner(Manager(managerAddr), _cdpId);
        bytes32 ilk = Manager(managerAddr).ilks(_cdpId);

        uint daiDrawn = drawDai(managerAddr, _cdpId, ilk, _exchangeData.srcAmount);

        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        _exchangeData.srcAmount = daiDrawn - takeFee(_gasCost, daiDrawn);
        (, uint swapedColl) = _sell(_exchangeData);

        addCollateral(managerAddr, _cdpId, _joinAddr, swapedColl);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "MCDBoost", abi.encode(_cdpId, user, _exchangeData.srcAmount, swapedColl));
    }

    /// @notice Draws Dai from the CDP
    /// @dev If _daiAmount is bigger than max available we'll draw max
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _daiAmount Amount of Dai to draw
    function drawDai(address _managerAddr, uint _cdpId, bytes32 _ilk, uint _daiAmount) internal returns (uint) {
        uint rate = Jug(JUG_ADDRESS).drip(_ilk);
        uint daiVatBalance = vat.dai(Manager(_managerAddr).urns(_cdpId));

        uint maxAmount = getMaxDebt(_managerAddr, _cdpId, _ilk);

        if (_daiAmount >= maxAmount) {
            _daiAmount = sub(maxAmount, 1);
        }

        Manager(_managerAddr).frob(_cdpId, int(0), normalizeDrawAmount(_daiAmount, rate, daiVatBalance));
        Manager(_managerAddr).move(_cdpId, address(this), toRad(_daiAmount));

        if (vat.can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            vat.hope(DAI_JOIN_ADDRESS);
        }

        DaiJoin(DAI_JOIN_ADDRESS).exit(address(this), _daiAmount);

        return _daiAmount;
    }

    /// @notice Adds collateral to the CDP
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _joinAddr Address of the join contract for the CDP collateral
    /// @param _amount Amount of collateral to add
    function addCollateral(address _managerAddr, uint _cdpId, address _joinAddr, uint _amount) internal {
        int convertAmount = 0;

        if (isEthJoinAddr(_joinAddr)) {
            Join(_joinAddr).gem().deposit{value: _amount}();
            convertAmount = toPositiveInt(_amount);
        } else {
            convertAmount = toPositiveInt(convertTo18(_joinAddr, _amount));
        }

        ERC20(address(Join(_joinAddr).gem())).safeApprove(_joinAddr, _amount);

        Join(_joinAddr).join(address(this), _amount);

        vat.frob(
            Manager(_managerAddr).ilks(_cdpId),
            Manager(_managerAddr).urns(_cdpId),
            address(this),
            address(this),
            convertAmount,
            0
        );

    }

    /// @notice Draws collateral and returns it to DSProxy
    /// @param _managerAddr Address of the CDP Manager
    /// @dev If _amount is bigger than max available we'll draw max
    /// @param _cdpId Id of the CDP
    /// @param _joinAddr Address of the join contract for the CDP collateral
    /// @param _amount Amount of collateral to draw
    function drawCollateral(address _managerAddr, uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        uint frobAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            frobAmount = _amount * (10 ** (18 - Join(_joinAddr).dec()));
        }

        Manager(_managerAddr).frob(_cdpId, -toPositiveInt(frobAmount), 0);
        Manager(_managerAddr).flux(_cdpId, address(this), frobAmount);

        Join(_joinAddr).exit(address(this), _amount);

        if (isEthJoinAddr(_joinAddr)) {
            Join(_joinAddr).gem().withdraw(_amount); // Weth -> Eth
        }

        return _amount;
    }

    /// @notice Paybacks Dai debt
    /// @param _managerAddr Address of the CDP Manager
    /// @dev If the _daiAmount is bigger than the whole debt, returns extra Dai
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _daiAmount Amount of Dai to payback
    /// @param _owner Address that owns the DSProxy that owns the CDP
    function paybackDebt(address _managerAddr, uint _cdpId, bytes32 _ilk, uint _daiAmount, address _owner) internal {
        address urn = Manager(_managerAddr).urns(_cdpId);

        uint wholeDebt = getAllDebt(VAT_ADDRESS, urn, urn, _ilk);

        if (_daiAmount > wholeDebt) {
            ERC20(DAI_ADDRESS).transfer(_owner, sub(_daiAmount, wholeDebt));
            _daiAmount = wholeDebt;
        }

        if (ERC20(DAI_ADDRESS).allowance(address(this), DAI_JOIN_ADDRESS) == 0) {
            ERC20(DAI_ADDRESS).approve(DAI_JOIN_ADDRESS, uint(-1));
        }

        daiJoin.join(urn, _daiAmount);

        Manager(_managerAddr).frob(_cdpId, 0, normalizePaybackAmount(VAT_ADDRESS, urn, _ilk));
    }

    /// @notice Gets the maximum amount of collateral available to draw
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _joinAddr Joind address of collateral
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxCollateral(address _managerAddr, uint _cdpId, bytes32 _ilk, address _joinAddr) public view returns (uint) {
        uint price = getPrice(_ilk);

        (uint collateral, uint debt) = getCdpInfo(Manager(_managerAddr), _cdpId, _ilk);

        (, uint mat) = Spotter(SPOTTER_ADDRESS).ilks(_ilk);

        uint maxCollateral = sub(collateral, (div(mul(mat, debt), price)));

        uint normalizeMaxCollateral = maxCollateral / (10 ** (18 - Join(_joinAddr).dec()));

        // take one percent due to precision issues
        return normalizeMaxCollateral * 99 / 100;
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxDebt(address _managerAddr, uint _cdpId, bytes32 _ilk) public virtual view returns (uint) {
        uint price = getPrice(_ilk);

        (, uint mat) = spotter.ilks(_ilk);
        (uint collateral, uint debt) = getCdpInfo(Manager(_managerAddr), _cdpId, _ilk);

        return sub(sub(div(mul(collateral, price), mat), debt), 10);
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    function isAutomation() internal view returns(bool) {
        return BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin);
    }

    function takeFee(uint256 _gasCost, uint _amount) internal returns(uint) {
        if (_gasCost > 0) {
            uint ethDaiPrice = getPrice(ETH_ILK);
            uint feeAmount = rmul(_gasCost, ethDaiPrice);

            if (feeAmount > _amount / 5) {
                feeAmount = _amount / 5;
            }

            address walletAddr = _feeRecipient.getFeeAddr();

            ERC20(DAI_ADDRESS).transfer(walletAddr, feeAmount);

            return feeAmount;
        }

        return 0;
    }
}

pragma solidity ^0.6.0;

import "./PipInterface.sol";

abstract contract Spotter {
    struct Ilk {
        PipInterface pip;
        uint256 mat;
    }

    mapping (bytes32 => Ilk) public ilks;

    uint256 public par;

}

pragma solidity ^0.6.0;

abstract contract Jug {
    struct Ilk {
        uint256 duty;
        uint256  rho;
    }

    mapping (bytes32 => Ilk) public ilks;

    function drip(bytes32) public virtual returns (uint);
}

pragma solidity ^0.6.0;

import "./Vat.sol";
import "./Gem.sol";

abstract contract DaiJoin {
    function vat() public virtual returns (Vat);
    function dai() public virtual returns (Gem);
    function join(address, uint) public virtual payable;
    function exit(address, uint) public virtual;
}

pragma solidity ^0.6.0;

import "../../DS/DSMath.sol";
import "../../DS/DSProxy.sol";
import "../../interfaces/Manager.sol";
import "../../interfaces/Join.sol";
import "../../interfaces/Vat.sol";

/// @title Helper methods for MCDSaverProxy
contract MCDSaverProxyHelper is DSMath {

    enum ManagerType { MCD, BPROTOCOL }

    /// @notice Returns a normalized debt _amount based on the current rate
    /// @param _amount Amount of dai to be normalized
    /// @param _rate Current rate of the stability fee
    /// @param _daiVatBalance Balance od Dai in the Vat for that CDP
    function normalizeDrawAmount(uint _amount, uint _rate, uint _daiVatBalance) internal pure returns (int dart) {
        if (_daiVatBalance < mul(_amount, RAY)) {
            dart = toPositiveInt(sub(mul(_amount, RAY), _daiVatBalance) / _rate);
            dart = mul(uint(dart), _rate) < mul(_amount, RAY) ? dart + 1 : dart;
        }
    }

    /// @notice Converts a number to Rad percision
    /// @param _wad The input number in wad percision
    function toRad(uint _wad) internal pure returns (uint) {
        return mul(_wad, 10 ** 27);
    }

    /// @notice Converts a number to 18 decimal percision
    /// @param _joinAddr Join address of the collateral
    /// @param _amount Number to be converted
    function convertTo18(address _joinAddr, uint256 _amount) internal view returns (uint256) {
        return mul(_amount, 10 ** (18 - Join(_joinAddr).dec()));
    }

    /// @notice Converts a uint to int and checks if positive
    /// @param _x Number to be converted
    function toPositiveInt(uint _x) internal pure returns (int y) {
        y = int(_x);
        require(y >= 0, "int-overflow");
    }

    /// @notice Gets Dai amount in Vat which can be added to Cdp
    /// @param _vat Address of Vat contract
    /// @param _urn Urn of the Cdp
    /// @param _ilk Ilk of the Cdp
    function normalizePaybackAmount(address _vat, address _urn, bytes32 _ilk) internal view returns (int amount) {
        uint dai = Vat(_vat).dai(_urn);

        (, uint rate,,,) = Vat(_vat).ilks(_ilk);
        (, uint art) = Vat(_vat).urns(_ilk, _urn);

        amount = toPositiveInt(dai / rate);
        amount = uint(amount) <= art ? - amount : - toPositiveInt(art);
    }

    /// @notice Gets the whole debt of the CDP
    /// @param _vat Address of Vat contract
    /// @param _usr Address of the Dai holder
    /// @param _urn Urn of the Cdp
    /// @param _ilk Ilk of the Cdp
    function getAllDebt(address _vat, address _usr, address _urn, bytes32 _ilk) internal view returns (uint daiAmount) {
        (, uint rate,,,) = Vat(_vat).ilks(_ilk);
        (, uint art) = Vat(_vat).urns(_ilk, _urn);
        uint dai = Vat(_vat).dai(_usr);

        uint rad = sub(mul(art, rate), dai);
        daiAmount = rad / RAY;

        daiAmount = mul(daiAmount, RAY) < rad ? daiAmount + 1 : daiAmount;
    }

    /// @notice Gets the token address from the Join contract
    /// @param _joinAddr Address of the Join contract
    function getCollateralAddr(address _joinAddr) internal view returns (address) {
        return address(Join(_joinAddr).gem());
    }

    /// @notice Checks if the join address is one of the Ether coll. types
    /// @param _joinAddr Join address to check
    function isEthJoinAddr(address _joinAddr) internal view returns (bool) {
        // if it's dai_join_addr don't check gem() it will fail
        if (_joinAddr == 0x9759A6Ac90977b93B58547b4A71c78317f391A28) return false;

        // if coll is weth it's and eth type coll
        if (address(Join(_joinAddr).gem()) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            return true;
        }

        return false;
    }

    /// @notice Gets CDP info (collateral, debt)
    /// @param _manager Manager contract
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getCdpInfo(Manager _manager, uint _cdpId, bytes32 _ilk) public view returns (uint, uint) {
        address vat = _manager.vat();
        address urn = _manager.urns(_cdpId);

        (uint collateral, uint debt) = Vat(vat).urns(_ilk, urn);
        (,uint rate,,,) = Vat(vat).ilks(_ilk);

        return (collateral, rmul(debt, rate));
    }

    /// @notice Address that owns the DSProxy that owns the CDP
    /// @param _manager Manager contract
    /// @param _cdpId Id of the CDP
    function getOwner(Manager _manager, uint _cdpId) public view returns (address) {
        DSProxy proxy = DSProxy(uint160(_manager.owns(_cdpId)));

        return proxy.owner();
    }

    /// @notice Based on the manager type returns the address
    /// @param _managerType Type of vault manager to use
    function getManagerAddr(ManagerType _managerType) public pure returns (address) {
        if (_managerType == ManagerType.MCD) {
            return 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
        } else if (_managerType == ManagerType.BPROTOCOL) {
            return 0x3f30c2381CD8B917Dd96EB2f1A4F96D91324BBed;
        }
    }
}

pragma solidity ^0.6.0;


abstract contract PipInterface {
    function read() public virtual returns (bytes32);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/ILoanShifter.sol";
import "../../mcd/saver/MCDSaverProxy.sol";
import "../../mcd/create/MCDCreateProxyActions.sol";

contract McdShifter is MCDSaverProxy {

    using SafeERC20 for ERC20;

    Manager manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    address public constant OPEN_PROXY_ACTIONS = 0x6d0984E80a86f26c0dd564ca0CF74a8E9Da03305;

    function getLoanAmount(uint _cdpId, address _joinAddr) public view virtual returns(uint loanAmount) {
        bytes32 ilk = manager.ilks(_cdpId);

        (, uint rate,,,) = vat.ilks(ilk);
        (, uint art) = vat.urns(ilk, manager.urns(_cdpId));
        uint dai = vat.dai(manager.urns(_cdpId));

        uint rad = sub(mul(art, rate), dai);
        loanAmount = rad / RAY;

        loanAmount = mul(loanAmount, RAY) < rad ? loanAmount + 1 : loanAmount;
    }

    function close(
        uint _cdpId,
        address _joinAddr,
        uint _loanAmount,
        uint _collateral
    ) public {
        address owner = getOwner(manager, _cdpId);
        bytes32 ilk = manager.ilks(_cdpId);
        (uint maxColl, ) = getCdpInfo(manager, _cdpId, ilk);

        // repay dai debt cdp
        paybackDebt(address(manager), _cdpId, ilk, _loanAmount, owner);

        maxColl = _collateral > maxColl ? maxColl : _collateral;

        // withdraw collateral from cdp
        drawCollateral(address(manager), _cdpId, _joinAddr, maxColl);

        // send back to msg.sender
        if (isEthJoinAddr(_joinAddr)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20 collToken = ERC20(getCollateralAddr(_joinAddr));
            collToken.safeTransfer(msg.sender, collToken.balanceOf(address(this)));
        }
    }

    function open(
        uint _cdpId,
        address _joinAddr,
        uint _debtAmount
    ) public {

        uint collAmount = 0;

        if (isEthJoinAddr(_joinAddr)) {
            collAmount = address(this).balance;
        } else {
            collAmount = ERC20(address(Join(_joinAddr).gem())).balanceOf(address(this));
        }

        if (_cdpId == 0) {
            openAndWithdraw(collAmount, _debtAmount, address(this), _joinAddr);
        } else {
            // add collateral
            addCollateral(address(manager), _cdpId, _joinAddr, collAmount);
            // draw debt
            drawDai(address(manager), _cdpId, manager.ilks(_cdpId), _debtAmount);
        }

        // transfer to repay FL
        ERC20(DAI_ADDRESS).transfer(msg.sender, ERC20(DAI_ADDRESS).balanceOf(address(this)));

        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function openAndWithdraw(uint _collAmount, uint _debtAmount, address _proxy, address _joinAddrTo) internal {
        bytes32 ilk = Join(_joinAddrTo).ilk();

        if (isEthJoinAddr(_joinAddrTo)) {
            MCDCreateProxyActions(OPEN_PROXY_ACTIONS).openLockETHAndDraw{value: address(this).balance}(
                address(manager),
                JUG_ADDRESS,
                _joinAddrTo,
                DAI_JOIN_ADDRESS,
                ilk,
                _debtAmount,
                _proxy
            );
        } else {
            ERC20(getCollateralAddr(_joinAddrTo)).approve(OPEN_PROXY_ACTIONS, uint256(-1));

            MCDCreateProxyActions(OPEN_PROXY_ACTIONS).openLockGemAndDraw(
                address(manager),
                JUG_ADDRESS,
                _joinAddrTo,
                DAI_JOIN_ADDRESS,
                ilk,
                _collAmount,
                _debtAmount,
                true,
                _proxy
            );
        }
    }

}

pragma solidity ^0.6.0;


abstract contract GemLike {
    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual;

    function transferFrom(address, address, uint256) public virtual;

    function deposit() public virtual payable;

    function withdraw(uint256) public virtual;
}


abstract contract ManagerLike {
    function cdpCan(address, uint256, address) public virtual view returns (uint256);

    function ilks(uint256) public virtual view returns (bytes32);

    function owns(uint256) public virtual view returns (address);

    function urns(uint256) public virtual view returns (address);

    function vat() public virtual view returns (address);

    function open(bytes32, address) public virtual returns (uint256);

    function give(uint256, address) public virtual;

    function cdpAllow(uint256, address, uint256) public virtual;

    function urnAllow(address, uint256) public virtual;

    function frob(uint256, int256, int256) public virtual;

    function flux(uint256, address, uint256) public virtual;

    function move(uint256, address, uint256) public virtual;

    function exit(address, uint256, address, uint256) public virtual;

    function quit(uint256, address) public virtual;

    function enter(address, uint256) public virtual;

    function shift(uint256, uint256) public virtual;
}


abstract contract VatLike {
    function can(address, address) public virtual view returns (uint256);

    function ilks(bytes32) public virtual view returns (uint256, uint256, uint256, uint256, uint256);

    function dai(address) public virtual view returns (uint256);

    function urns(bytes32, address) public virtual view returns (uint256, uint256);

    function frob(bytes32, address, address, address, int256, int256) public virtual;

    function hope(address) public virtual;

    function move(address, address, uint256) public virtual;
}


abstract contract GemJoinLike {
    function dec() public virtual returns (uint256);

    function gem() public virtual returns (GemLike);

    function join(address, uint256) public virtual payable;

    function exit(address, uint256) public virtual;
}


abstract contract GNTJoinLike {
    function bags(address) public virtual view returns (address);

    function make(address) public virtual returns (address);
}


abstract contract DaiJoinLike {
    function vat() public virtual returns (VatLike);

    function dai() public virtual returns (GemLike);

    function join(address, uint256) public virtual payable;

    function exit(address, uint256) public virtual;
}


abstract contract HopeLike {
    function hope(address) public virtual;

    function nope(address) public virtual;
}


abstract contract ProxyRegistryInterface {
    function build(address) public virtual returns (address);
}


abstract contract EndLike {
    function fix(bytes32) public virtual view returns (uint256);

    function cash(bytes32, uint256) public virtual;

    function free(bytes32) public virtual;

    function pack(uint256) public virtual;

    function skim(bytes32, address) public virtual;
}


abstract contract JugLike {
    function drip(bytes32) public virtual returns (uint256);
}


abstract contract PotLike {
    function pie(address) public virtual view returns (uint256);

    function drip() public virtual returns (uint256);

    function join(uint256) public virtual;

    function exit(uint256) public virtual;
}


abstract contract ProxyRegistryLike {
    function proxies(address) public virtual view returns (address);

    function build(address) public virtual returns (address);
}


abstract contract ProxyLike {
    function owner() public virtual view returns (address);
}


// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant RAY = 10**27;

    // Internal functions

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    // Public functions
    // solhint-disable-next-line func-name-mixedcase
    function daiJoin_join(address apt, address urn, uint256 wad) public {
        // Gets DAI from the user's wallet
        DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the DAI amount
        DaiJoinLike(apt).dai().approve(apt, wad);
        // Joins DAI into the vat
        DaiJoinLike(apt).join(urn, wad);
    }
}


contract MCDCreateProxyActions is Common {
    // Internal functions

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = mul(wad, 10**27);
    }

    function convertTo18(address gemJoin, uint256 amt) internal returns (uint256 wad) {
        // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to frob function
        // Adapters will automatically handle the difference of precision
        wad = mul(amt, 10**(18 - GemJoinLike(gemJoin).dec()));
    }

    function _getDrawDart(address vat, address jug, address urn, bytes32 ilk, uint256 wad)
        internal
        returns (int256 dart)
    {
        // Updates stability fee rate
        uint256 rate = JugLike(jug).drip(ilk);

        // Gets DAI balance of the urn in the vat
        uint256 dai = VatLike(vat).dai(urn);

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < mul(wad, RAY)) {
            // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            dart = toInt(sub(mul(wad, RAY), dai) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
            dart = mul(uint256(dart), rate) < mul(wad, RAY) ? dart + 1 : dart;
        }
    }

    function _getWipeDart(address vat, uint256 dai, address urn, bytes32 ilk)
        internal
        view
        returns (int256 dart)
    {
        // Gets actual rate from the vat
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (, uint256 art) = VatLike(vat).urns(ilk, urn);

        // Uses the whole dai balance in the vat to reduce the debt
        dart = toInt(dai / rate);
        // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
        dart = uint256(dart) <= art ? -dart : -toInt(art);
    }

    function _getWipeAllWad(address vat, address usr, address urn, bytes32 ilk)
        internal
        view
        returns (uint256 wad)
    {
        // Gets actual rate from the vat
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (, uint256 art) = VatLike(vat).urns(ilk, urn);
        // Gets actual dai amount in the urn
        uint256 dai = VatLike(vat).dai(usr);

        uint256 rad = sub(mul(art, rate), dai);
        wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        wad = mul(wad, RAY) < rad ? wad + 1 : wad;
    }

    // Public functions

    function transfer(address gem, address dst, uint256 wad) public {
        GemLike(gem).transfer(dst, wad);
    }

    // solhint-disable-next-line func-name-mixedcase
    function ethJoin_join(address apt, address urn) public payable {
        // Wraps ETH in WETH
        GemJoinLike(apt).gem().deposit{value: msg.value}();
        // Approves adapter to take the WETH amount
        GemJoinLike(apt).gem().approve(address(apt), msg.value);
        // Joins WETH collateral into the vat
        GemJoinLike(apt).join(urn, msg.value);
    }

    // solhint-disable-next-line func-name-mixedcase
    function gemJoin_join(address apt, address urn, uint256 wad, bool transferFrom) public {
        // Only executes for tokens that have approval/transferFrom implementation
        if (transferFrom) {
            // Gets token from the user's wallet
            GemJoinLike(apt).gem().transferFrom(msg.sender, address(this), wad);
            // Approves adapter to take the token amount
            GemJoinLike(apt).gem().approve(apt, 0);
            GemJoinLike(apt).gem().approve(apt, wad);
        }
        // Joins token collateral into the vat
        GemJoinLike(apt).join(urn, wad);
    }

    function hope(address obj, address usr) public {
        HopeLike(obj).hope(usr);
    }

    function nope(address obj, address usr) public {
        HopeLike(obj).nope(usr);
    }

    function open(address manager, bytes32 ilk, address usr) public returns (uint256 cdp) {
        cdp = ManagerLike(manager).open(ilk, usr);
    }

    function give(address manager, uint256 cdp, address usr) public {
        ManagerLike(manager).give(cdp, usr);
    }

    function move(address manager, uint256 cdp, address dst, uint256 rad) public {
        ManagerLike(manager).move(cdp, dst, rad);
    }

    function frob(address manager, uint256 cdp, int256 dink, int256 dart) public {
        ManagerLike(manager).frob(cdp, dink, dart);
    }

    function lockETH(address manager, address ethJoin, uint256 cdp) public payable {
        // Receives ETH amount, converts it to WETH and joins it into the vat
        ethJoin_join(ethJoin, address(this));
        // Locks WETH amount into the CDP
        VatLike(ManagerLike(manager).vat()).frob(
            ManagerLike(manager).ilks(cdp),
            ManagerLike(manager).urns(cdp),
            address(this),
            address(this),
            toInt(msg.value),
            0
        );
    }

    function lockGem(address manager, address gemJoin, uint256 cdp, uint256 wad, bool transferFrom)
        public
    {
        // Takes token amount from user's wallet and joins into the vat
        gemJoin_join(gemJoin, address(this), wad, transferFrom);
        // Locks token amount into the CDP
        VatLike(ManagerLike(manager).vat()).frob(
            ManagerLike(manager).ilks(cdp),
            ManagerLike(manager).urns(cdp),
            address(this),
            address(this),
            toInt(convertTo18(gemJoin, wad)),
            0
        );
    }

    function draw(address manager, address jug, address daiJoin, uint256 cdp, uint256 wad) public {
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        // Generates debt in the CDP
        frob(manager, cdp, 0, _getDrawDart(vat, jug, urn, ilk, wad));
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), toRad(wad));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }
        // Exits DAI to the user's wallet as a token
        DaiJoinLike(daiJoin).exit(msg.sender, wad);
    }

    function lockETHAndDraw(
        address manager,
        address jug,
        address ethJoin,
        address daiJoin,
        uint256 cdp,
        uint256 wadD
    ) public payable {
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        // Receives ETH amount, converts it to WETH and joins it into the vat
        ethJoin_join(ethJoin, urn);
        // Locks WETH amount into the CDP and generates debt
        frob(manager, cdp, toInt(msg.value), _getDrawDart(vat, jug, urn, ilk, wadD));
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), toRad(wadD));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }
        // Exits DAI to the user's wallet as a token
        DaiJoinLike(daiJoin).exit(msg.sender, wadD);
    }

    function openLockETHAndDraw(
        address manager,
        address jug,
        address ethJoin,
        address daiJoin,
        bytes32 ilk,
        uint256 wadD,
        address owner
    ) public payable returns (uint256 cdp) {
        cdp = open(manager, ilk, address(this));
        lockETHAndDraw(manager, jug, ethJoin, daiJoin, cdp, wadD);
        give(manager, cdp, owner);
    }

    function lockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        uint256 cdp,
        uint256 wadC,
        uint256 wadD,
        bool transferFrom
    ) public {
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        // Takes token amount from user's wallet and joins into the vat
        gemJoin_join(gemJoin, urn, wadC, transferFrom);
        // Locks token amount into the CDP and generates debt
        frob(
            manager,
            cdp,
            toInt(convertTo18(gemJoin, wadC)),
            _getDrawDart(vat, jug, urn, ilk, wadD)
        );
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), toRad(wadD));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }
        // Exits DAI to the user's wallet as a token
        DaiJoinLike(daiJoin).exit(msg.sender, wadD);
    }

    function openLockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        bytes32 ilk,
        uint256 wadC,
        uint256 wadD,
        bool transferFrom,
        address owner
    ) public returns (uint256 cdp) {
        cdp = open(manager, ilk, address(this));
        lockGemAndDraw(manager, jug, gemJoin, daiJoin, cdp, wadC, wadD, transferFrom);
        give(manager, cdp, owner);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../exchangeV3/DFSExchangeCore.sol";
import "./MCDCreateProxyActions.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/Manager.sol";
import "../../interfaces/Join.sol";
import "../../DS/DSProxy.sol";
import "./MCDCreateTaker.sol";

contract MCDCreateFlashLoan is DFSExchangeCore, AdminAuth, FlashLoanReceiverBase {
    address public constant CREATE_PROXY_ACTIONS = 0x6d0984E80a86f26c0dd564ca0CF74a8E9Da03305;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant JUG_ADDRESS = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (address proxy, bytes memory packedData) = abi.decode(_params, (address,bytes));
        (MCDCreateTaker.CreateData memory createData, ExchangeData memory exchangeData) = abi.decode(packedData, (MCDCreateTaker.CreateData,ExchangeData));

        exchangeData.dfsFeeDivider = SERVICE_FEE;
        exchangeData.user = DSProxy(payable(proxy)).owner();

        openAndLeverage(createData.collAmount, createData.daiAmount + _fee, createData.joinAddr, proxy, exchangeData);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function openAndLeverage(
        uint _collAmount,
        uint _daiAmountAndFee,
        address _joinAddr,
        address _proxy,
        ExchangeData memory _exchangeData
    ) public {
        (, uint256 collSwaped) = _sell(_exchangeData);

        bytes32 ilk = Join(_joinAddr).ilk();

        if (isEthJoinAddr(_joinAddr)) {
            MCDCreateProxyActions(CREATE_PROXY_ACTIONS).openLockETHAndDraw{value: address(this).balance}(
                MANAGER_ADDRESS,
                JUG_ADDRESS,
                _joinAddr,
                DAI_JOIN_ADDRESS,
                ilk,
                _daiAmountAndFee,
                _proxy
            );
        } else {
            ERC20(address(Join(_joinAddr).gem())).safeApprove(CREATE_PROXY_ACTIONS, (_collAmount + collSwaped));

            MCDCreateProxyActions(CREATE_PROXY_ACTIONS).openLockGemAndDraw(
                MANAGER_ADDRESS,
                JUG_ADDRESS,
                _joinAddr,
                DAI_JOIN_ADDRESS,
                ilk,
                (_collAmount + collSwaped),
                _daiAmountAndFee,
                true,
                _proxy
            );
        }
    }

    /// @notice Checks if the join address is one of the Ether coll. types
    /// @param _joinAddr Join address to check
    function isEthJoinAddr(address _joinAddr) internal view returns (bool) {
        // if it's dai_join_addr don't check gem() it will fail
        if (_joinAddr == 0x9759A6Ac90977b93B58547b4A71c78317f391A28) return false;

        // if coll is weth it's and eth type coll
        if (address(Join(_joinAddr).gem()) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            return true;
        }

        return false;
    }

    receive() external override(FlashLoanReceiverBase, DFSExchangeCore) payable {}
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ILendingPool.sol";
import "../../exchangeV3/DFSExchangeData.sol";
import "../../utils/SafeERC20.sol";
import "../../utils/GasBurner.sol";

contract MCDCreateTaker is GasBurner {

    using SafeERC20 for ERC20;

    address payable public constant MCD_CREATE_FLASH_LOAN = 0x409F216aa8034a12135ab6b74Bf6444335004BBd;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // solhint-disable-next-line const-name-snakecase
    Manager public constant manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    struct CreateData {
        uint collAmount;
        uint daiAmount;
        address joinAddr;
    }

    function openWithLoan(
        DFSExchangeData.ExchangeData memory _exchangeData,
        CreateData memory _createData
    ) public payable burnGas(20) {

        MCD_CREATE_FLASH_LOAN.transfer(msg.value); //0x fee


        if (!isEthJoinAddr(_createData.joinAddr)) {
            ERC20(getCollateralAddr(_createData.joinAddr)).safeTransferFrom(msg.sender, address(this), _createData.collAmount);
            ERC20(getCollateralAddr(_createData.joinAddr)).safeTransfer(MCD_CREATE_FLASH_LOAN, _createData.collAmount);
        }

        bytes memory packedData = _packData(_createData, _exchangeData);
        bytes memory paramsData = abi.encode(address(this), packedData);

        lendingPool.flashLoan(MCD_CREATE_FLASH_LOAN, DAI_ADDRESS, _createData.daiAmount, paramsData);

        logger.Log(address(this), msg.sender, "MCDCreate", abi.encode(manager.last(address(this)), _createData.collAmount, _createData.daiAmount));
    }

    function getCollateralAddr(address _joinAddr) internal view returns (address) {
        return address(Join(_joinAddr).gem());
    }

    /// @notice Checks if the join address is one of the Ether coll. types
    /// @param _joinAddr Join address to check
    function isEthJoinAddr(address _joinAddr) internal view returns (bool) {
        // if it's dai_join_addr don't check gem() it will fail
        if (_joinAddr == 0x9759A6Ac90977b93B58547b4A71c78317f391A28) return false;

        // if coll is weth it's and eth type coll
        if (address(Join(_joinAddr).gem()) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            return true;
        }

        return false;
    }

    function _packData(
        CreateData memory _createData,
        DFSExchangeData.ExchangeData memory _exchangeData
    ) internal pure returns (bytes memory) {

        return abi.encode(_createData, _exchangeData);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../saver/MCDSaverProxy.sol";
import "../../exchangeV3/DFSExchangeData.sol";
import "../../utils/GasBurner.sol";
import "../../interfaces/ILendingPool.sol";

contract MCDSaverTaker is MCDSaverProxy, GasBurner {

    address payable public constant MCD_SAVER_FLASH_LOAN = 0xcBb5DbBCcFbf6aF8AF75d0cbD5646C73d847cd15;
    address public constant AAVE_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    function boostWithLoan(
        ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable burnGas(25) {
        address managerAddr = getManagerAddr(_managerType);

        uint256 maxDebt = getMaxDebt(managerAddr, _cdpId, Manager(managerAddr).ilks(_cdpId));

        uint maxLiq = getAvailableLiquidity(DAI_JOIN_ADDRESS);

        if (maxDebt >= _exchangeData.srcAmount || maxLiq == 0) {
            if (_exchangeData.srcAmount > maxDebt) {
                _exchangeData.srcAmount = maxDebt;
            }

            boost(_exchangeData, _cdpId, _gasCost, _joinAddr, _managerType);
            return;
        }

        uint256 loanAmount = sub(_exchangeData.srcAmount, maxDebt);
        loanAmount = loanAmount > maxLiq ? maxLiq : loanAmount;

        MCD_SAVER_FLASH_LOAN.transfer(msg.value); // 0x fee

        Manager(managerAddr).cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(packExchangeData(_exchangeData), _cdpId, _gasCost, _joinAddr, false, uint8(_managerType));

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, DAI_ADDRESS, loanAmount, paramsData);

        Manager(managerAddr).cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 0);
    }

    function repayWithLoan(
        ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable burnGas(25) {
        address managerAddr = getManagerAddr(_managerType);

        uint256 maxColl = getMaxCollateral(managerAddr, _cdpId, Manager(managerAddr).ilks(_cdpId), _joinAddr);

        uint maxLiq = getAvailableLiquidity(_joinAddr);

        if (maxColl >= _exchangeData.srcAmount || maxLiq == 0) {
            if (_exchangeData.srcAmount > maxColl) {
                _exchangeData.srcAmount = maxColl;
            }

            repay(_exchangeData, _cdpId, _gasCost, _joinAddr, _managerType);
            return;
        }

        uint256 loanAmount = sub(_exchangeData.srcAmount, maxColl);
        loanAmount = loanAmount > maxLiq ? maxLiq : loanAmount;

        MCD_SAVER_FLASH_LOAN.transfer(msg.value); // 0x fee

        Manager(managerAddr).cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(packExchangeData(_exchangeData), _cdpId, _gasCost, _joinAddr, true, uint8(_managerType));

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, getAaveCollAddr(_joinAddr), loanAmount, paramsData);

        Manager(managerAddr).cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 0);
    }


    /// @notice Gets the maximum amount of debt available to generate
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(address _managerAddr, uint256 _cdpId, bytes32 _ilk) public override view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(Manager(_managerAddr), _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    function getAaveCollAddr(address _joinAddr) internal view returns (address) {
        if (isEthJoinAddr(_joinAddr)
            || _joinAddr == 0x775787933e92b709f2a3C70aa87999696e74A9F8) {
            return KYBER_ETH_ADDRESS;
        } else if (_joinAddr == DAI_JOIN_ADDRESS) {
            return DAI_ADDRESS;
        } else
         {
            return getCollateralAddr(_joinAddr);
        }
    }

    function getAvailableLiquidity(address _joinAddr) internal view returns (uint liquidity) {
        address tokenAddr = getAaveCollAddr(_joinAddr);

        if (tokenAddr == KYBER_ETH_ADDRESS) {
            liquidity = AAVE_POOL_CORE.balance;
        } else {
            liquidity = ERC20(tokenAddr).balanceOf(AAVE_POOL_CORE);
        }
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/IAToken.sol";
import "../../interfaces/ILendingPool.sol";
import "../../interfaces/ERC20.sol";
import "../../DS/DSAuth.sol";


contract AaveSavingsProtocol is ProtocolInterface, DSAuth {

    address public constant ADAI_ADDRESS = 0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d;
    address public constant AAVE_LENDING_POOL = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address public constant AAVE_LENDING_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function deposit(address _user, uint _amount) public override {
        require(msg.sender == _user);
        // get dai from user
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        ERC20(DAI_ADDRESS).approve(AAVE_LENDING_POOL_CORE, uint(-1));
        ILendingPool(AAVE_LENDING_POOL).deposit(DAI_ADDRESS, _amount, 0);

        ERC20(ADAI_ADDRESS).transfer(_user, ERC20(ADAI_ADDRESS).balanceOf(address(this)));
    }

    function withdraw(address _user, uint _amount) public override {
        require(msg.sender == _user);
        require(ERC20(ADAI_ADDRESS).transferFrom(_user, address(this), _amount));

        IAToken(ADAI_ADDRESS).redeem(_amount);

        // return dai we have to user
        ERC20(DAI_ADDRESS).transfer(_user, _amount);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/ITokenInterface.sol";
import "../../DS/DSAuth.sol";

contract FulcrumSavingsProtocol is ProtocolInterface, DSAuth {

    address public constant NEW_IDAI_ADDRESS = 0x493C57C4763932315A328269E1ADaD09653B9081;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public savingsProxy;
    uint public decimals = 10 ** 18;

    function addSavingsProxy(address _savingsProxy) public auth {
        savingsProxy = _savingsProxy;
    }

    function deposit(address _user, uint _amount) public override {
        require(msg.sender == _user);

        // get dai from user
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        // approve dai to Fulcrum
        ERC20(DAI_ADDRESS).approve(NEW_IDAI_ADDRESS, uint(-1));

        // mint iDai
        ITokenInterface(NEW_IDAI_ADDRESS).mint(_user, _amount);
    }

    function withdraw(address _user, uint _amount) public override {
        require(msg.sender == _user);

        // transfer all users tokens to our contract
        require(ERC20(NEW_IDAI_ADDRESS).transferFrom(_user, address(this), ITokenInterface(NEW_IDAI_ADDRESS).balanceOf(_user)));

        // approve iDai to that contract
        ERC20(NEW_IDAI_ADDRESS).approve(NEW_IDAI_ADDRESS, uint(-1));
        uint tokenPrice = ITokenInterface(NEW_IDAI_ADDRESS).tokenPrice();

        // get dai from iDai contract
        ITokenInterface(NEW_IDAI_ADDRESS).burn(_user, _amount * decimals / tokenPrice);

        // return all remaining tokens back to user
        require(ERC20(NEW_IDAI_ADDRESS).transfer(_user, ITokenInterface(NEW_IDAI_ADDRESS).balanceOf(address(this))));
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "./ISoloMargin.sol";
import "../../interfaces/ERC20.sol";
import "../../DS/DSAuth.sol";

contract DydxSavingsProtocol is ProtocolInterface, DSAuth {
    address public constant SOLO_MARGIN_ADDRESS = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    ISoloMargin public soloMargin;
    address public savingsProxy;

    uint daiMarketId = 3;

    constructor() public {
        soloMargin = ISoloMargin(SOLO_MARGIN_ADDRESS);
    }

    function addSavingsProxy(address _savingsProxy) public auth {
        savingsProxy = _savingsProxy;
    }

    function deposit(address _user, uint _amount) public override {
        require(msg.sender == _user);

        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = getAccount(_user, 0);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        Types.AssetAmount memory amount = Types.AssetAmount({
            sign: true,
            denomination: Types.AssetDenomination.Wei,
            ref: Types.AssetReference.Delta,
            value: _amount
        });

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: amount,
            primaryMarketId: daiMarketId,
            otherAddress: _user,
            secondaryMarketId: 0, //not used
            otherAccountId: 0, //not used
            data: "" //not used
        });

        soloMargin.operate(accounts, actions);
    }

    function withdraw(address _user, uint _amount) public override {
        require(msg.sender == _user);

        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = getAccount(_user, 0);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        Types.AssetAmount memory amount = Types.AssetAmount({
            sign: false,
            denomination: Types.AssetDenomination.Wei,
            ref: Types.AssetReference.Delta,
            value: _amount
        });

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: amount,
            primaryMarketId: daiMarketId,
            otherAddress: _user,
            secondaryMarketId: 0, //not used
            otherAccountId: 0, //not used
            data: "" //not used
        });

        soloMargin.operate(accounts, actions);
    }

    function getWeiBalance(address _user, uint _index) public view returns(Types.Wei memory) {

        Types.Wei[] memory weiBalances;
        (,,weiBalances) = soloMargin.getAccountBalances(getAccount(_user, _index));

        return weiBalances[daiMarketId];
    }

    function getParBalance(address _user, uint _index) public view returns(Types.Par memory) {
        Types.Par[] memory parBalances;
        (,parBalances,) = soloMargin.getAccountBalances(getAccount(_user, _index));

        return parBalances[daiMarketId];
    }

    function getAccount(address _user, uint _index) public pure returns(Account.Info memory) {
        Account.Info memory account = Account.Info({
            owner: _user,
            number: _index
        });

        return account;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./RAISaverTaker.sol";
import "../saver/RAISaverProxy.sol";
import "../../savings/dydx/ISoloMargin.sol";
import "../../exchangeV3/DFSExchangeCore.sol";

contract RAISaverFlashLoan is RAISaverProxy, AdminAuth {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function callFunction(
        address,
        Account.Info memory,
        bytes memory _params
    ) public {

        (
            bytes memory exDataBytes ,
            RAISaverTaker.SaverData memory saverData
        )
         = abi.decode(_params, (bytes, RAISaverTaker.SaverData));


        ExchangeData memory exchangeData = unpackExchangeData(exDataBytes);

        address managerAddr = getManagerAddr(saverData.managerType);
        address userProxy = ISAFEManager(managerAddr).ownsSAFE(saverData.safeId);

        if (saverData.isRepay) {
            repayWithLoan(exchangeData, saverData);
        } else {
            boostWithLoan(exchangeData, saverData);
        }

        // payback FL, assumes we have weth
        TokenInterface(WETH_ADDR).deposit{value: (address(this).balance)}();
        ERC20(WETH_ADDR).safeTransfer(userProxy, (saverData.flAmount + 2));
    }

    function boostWithLoan(
        ExchangeData memory _exchangeData,
        RAISaverTaker.SaverData memory _saverData
    ) internal {

        address managerAddr = getManagerAddr(_saverData.managerType);
        address user = getOwner(ISAFEManager(managerAddr), _saverData.safeId);
        bytes32 collType = ISAFEManager(managerAddr).collateralTypes(_saverData.safeId);

        addCollateral(managerAddr, _saverData.safeId, _saverData.joinAddr, _saverData.flAmount, false);

        // Draw users Rai
        uint raiDrawn = drawRai(managerAddr, _saverData.safeId, collType, _exchangeData.srcAmount);

        // Swap
        _exchangeData.srcAmount = raiDrawn - takeFee(_saverData.gasCost, raiDrawn);
        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;

        (, uint swapedAmount) = _sell(_exchangeData);

        // Return collateral
        addCollateral(managerAddr, _saverData.safeId, _saverData.joinAddr, swapedAmount, true);
        // Draw collateral to repay the flash loan
        drawCollateral(managerAddr, _saverData.safeId, _saverData.joinAddr, _saverData.flAmount, false);

        logger.Log(address(this), msg.sender, "RAIFlashBoost", abi.encode(_saverData.safeId, user, _exchangeData.srcAmount, swapedAmount));
    }

    function repayWithLoan(
        ExchangeData memory _exchangeData,
        RAISaverTaker.SaverData memory _saverData
    ) internal {

        TokenInterface(WETH_ADDR).withdraw(_saverData.flAmount);

        address managerAddr = getManagerAddr(_saverData.managerType);

        address user = getOwner(ISAFEManager(managerAddr), _saverData.safeId);
        bytes32 collType = ISAFEManager(managerAddr).collateralTypes(_saverData.safeId);

        // Swap
        _exchangeData.srcAmount = _saverData.flAmount;
        _exchangeData.user = user;

        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;

        (, uint paybackAmount) = _sell(_exchangeData);

        paybackAmount -= takeFee(_saverData.gasCost, paybackAmount);
        paybackAmount = limitLoanAmount(managerAddr, _saverData.safeId, collType, paybackAmount, user);

        // Payback the debt
        paybackDebt(managerAddr, _saverData.safeId, collType, paybackAmount, user);

        // Draw collateral to repay the flash loan
        drawCollateral(managerAddr, _saverData.safeId, _saverData.joinAddr, _saverData.flAmount, false);

        logger.Log(address(this), msg.sender, "RAIFlashRepay", abi.encode(_saverData.safeId, user, _exchangeData.srcAmount, paybackAmount));
    }

    /// @notice Handles that the amount is not bigger than cdp debt and not dust
    function limitLoanAmount(address _managerAddr, uint _safeId, bytes32 _collType, uint _paybackAmount, address _owner) internal returns (uint256) {
        uint debt = getAllDebt(address(safeEngine), ISAFEManager(_managerAddr).safes(_safeId), ISAFEManager(_managerAddr).safes(_safeId), _collType);

        if (_paybackAmount > debt) {
            ERC20(RAI_ADDRESS).transfer(_owner, (_paybackAmount - debt));
            return debt;
        }

        uint debtLeft = debt - _paybackAmount;

        (,,,, uint dust,) = safeEngine.collateralTypes(_collType);
        dust = dust / 10**27;

        // Less than dust value
        if (debtLeft < dust) {
            uint amountOverDust = (dust - debtLeft);

            ERC20(RAI_ADDRESS).transfer(_owner, amountOverDust);

            return (_paybackAmount - amountOverDust);
        }

        return _paybackAmount;
    }

    receive() external override(DFSExchangeCore) payable {}

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../savings/dydx/ISoloMargin.sol";
import "../../utils/SafeERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSProxy.sol";
import "../AaveHelperV2.sol";
import "../../auth/AdminAuth.sol";
import "../../exchangeV3/DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiverV2 is AaveHelperV2, AdminAuth, DFSExchangeData {

    using SafeERC20 for ERC20;

    address public constant AAVE_SAVER_PROXY = 0xBBCD23145Ab10C369c9e5D3b1D58506B0cD2ab44;
    address public constant AAVE_BASIC_PROXY = 0xc17c8eB12Ba24D62E69fd57cbd504EEf418867f9;
    address public constant AETH_ADDRESS = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        (
            bytes memory exchangeDataBytes,
            address market,
            uint256 rateMode,
            uint256 gasCost,
            bool isRepay,
            uint256 ethAmount,
            uint256 txValue,
            address user,
            address proxy
        )
        = abi.decode(data, (bytes,address,uint256,uint256,bool,uint256,uint256,address,address));

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        // deposit eth on behalf of proxy
        DSProxy(payable(proxy)).execute{value: ethAmount}(AAVE_BASIC_PROXY, abi.encodeWithSignature("deposit(address,address,uint256)", market, ETH_ADDR, ethAmount));

        bytes memory functionData = packFunctionCall(market, exchangeDataBytes, rateMode, gasCost, isRepay);
        DSProxy(payable(proxy)).execute{value: txValue}(AAVE_SAVER_PROXY, functionData);

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256)", market, ETH_ADDR, ethAmount));

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    function packFunctionCall(address _market, bytes memory _exchangeDataBytes, uint256 _rateMode, uint256 _gasCost, bool _isRepay) internal returns (bytes memory) {
        ExchangeData memory exData = unpackExchangeData(_exchangeDataBytes);

        bytes memory functionData;

        if (_isRepay) {
            functionData = abi.encodeWithSignature("repay(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256)", _market, exData, _rateMode, _gasCost);
        } else {
            functionData = abi.encodeWithSignature("boost(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256)", _market, exData, _rateMode, _gasCost);
        }

        return functionData;
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        }
    }
}

pragma solidity ^0.6.0;

import "../DS/DSMath.sol";
import "../DS/DSProxy.sol";
import "../utils/Discount.sol";
import "../interfaces/IFeeRecipient.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPoolV2.sol";
import "../interfaces/IPriceOracleGetterAave.sol";
import "../interfaces/IAaveProtocolDataProviderV2.sol";

import "../utils/SafeERC20.sol";
import "../utils/BotRegistry.sol";

contract AaveHelperV2 is DSMath {

    using SafeERC20 for ERC20;

    IFeeRecipient public constant feeRecipient = IFeeRecipient(0x39C4a92Dc506300c3Ea4c67ca4CA611102ee6F2A);

    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

	address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint public constant NINETY_NINE_PERCENT_WEI = 990000000000000000;
    uint16 public constant AAVE_REFERRAL_CODE = 64;

    uint public constant STABLE_ID = 1;
    uint public constant VARIABLE_ID = 2;

    /// @notice Calculates the gas cost for transaction
    /// @param _oracleAddress address of oracle used
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _tokenAddr token addr. of token we are getting for the fee
    /// @return gasCost The amount we took for the gas cost
    function getGasCost(address _oracleAddress, uint _amount, address _user, uint _gasCost, address _tokenAddr) internal returns (uint gasCost) {
        if (_gasCost == 0) return 0;

        // in case its ETH, we need to get price for WETH
        // everywhere else  we still use ETH as thats the token we have in this moment
        address priceToken = _tokenAddr == ETH_ADDR ? WETH_ADDRESS : _tokenAddr;
        uint256 price = IPriceOracleGetterAave(_oracleAddress).getAssetPrice(priceToken);
        _gasCost = wdiv(_gasCost, price) / (10 ** (18 - _getDecimals(_tokenAddr)));
        gasCost = _gasCost;

        // gas cost can't go over 20% of the whole amount
        if (gasCost > (_amount / 20)) {
            gasCost = _amount / 20;
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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

abstract contract IAaveProtocolDataProviderV2 {

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

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../AaveHelperV2.sol";
import "../../../utils/GasBurner.sol";
import "../../../auth/AdminAuth.sol";
import "../../../auth/ProxyPermission.sol";
import "../../../utils/DydxFlashLoanBase.sol";
import "../../../loggers/DefisaverLogger.sol";
import "../../../interfaces/ProxyRegistryInterface.sol";
import "../../../interfaces/TokenInterface.sol";
import "../../../interfaces/ERC20.sol";
import "../../../exchangeV3/DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
/// @dev Contract needs to have enough wei in WETH for all transactions (2 WETH wei per transaction)
contract AaveSaverTakerOV2 is ProxyPermission, GasBurner, DFSExchangeData, AaveHelperV2 {

    address payable public constant AAVE_RECEIVER = 0xD6F7171a0f873262267CF99e010C8B08Bcdd199f;

    // leaving _flAmount to be the same as the older version
    function repay(address _market, ExchangeData memory _data, uint _rateMode, uint256 _gasCost, uint _flAmount) public payable burnGas(10) {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        // send msg.value for exchange to the receiver
        AAVE_RECEIVER.transfer(msg.value);

        address[] memory assets = new address[](1);
        assets[0] = _data.srcAddr;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _data.srcAmount;

        // for repay we are using regular flash loan with paying back the flash loan + premium
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        // create data
        bytes memory encodedData = packExchangeData(_data);
        bytes memory data = abi.encode(encodedData, _market, _gasCost, _rateMode, true, address(this));

        // give permission to receiver and execute tx
        givePermission(AAVE_RECEIVER);
        ILendingPoolV2(lendingPool).flashLoan(AAVE_RECEIVER, assets, amounts, modes, address(this), data, AAVE_REFERRAL_CODE);
        removePermission(AAVE_RECEIVER);
    }

    // leaving _flAmount to be the same as the older version
    function boost(address _market, ExchangeData memory _data, uint _rateMode, uint256 _gasCost, uint _flAmount) public payable burnGas(10) {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        // send msg.value for exchange to the receiver
        AAVE_RECEIVER.transfer(msg.value);

        address[] memory assets = new address[](1);
        assets[0] = _data.srcAddr;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _data.srcAmount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = _rateMode;

        // create data
        bytes memory encodedData = packExchangeData(_data);
        bytes memory data = abi.encode(encodedData, _market, _gasCost, _rateMode, false, address(this));

        // give permission to receiver and execute tx
        givePermission(AAVE_RECEIVER);
        ILendingPoolV2(lendingPool).flashLoan(AAVE_RECEIVER, assets, amounts, modes, address(this), data, AAVE_REFERRAL_CODE);
        removePermission(AAVE_RECEIVER);
    }
}

pragma solidity ^0.6.0;

import "./DSProxyInterface.sol";

abstract contract ProxyRegistryInterface {
    function proxies(address _owner) public virtual view returns (address);
    function build(address) public virtual returns (address);
}

pragma solidity ^0.6.0;

import "../../interfaces/ExchangeInterfaceV3.sol";
import "../../interfaces/OasisInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSMath.sol";
import "../../utils/SafeERC20.sol";
import "../../auth/AdminAuth.sol";

contract OasisTradeWrapperV3 is DSMath, ExchangeInterfaceV3, AdminAuth {

    using SafeERC20 for ERC20;

    address public constant OTC_ADDRESS = 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Sells a _srcAmount of tokens at Oasis
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external override payable returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        ERC20(srcAddr).safeApprove(OTC_ADDRESS, _srcAmount);

        uint destAmount = OasisInterface(OTC_ADDRESS).sellAllAmount(srcAddr, _srcAmount, destAddr, 0);

        // convert weth -> eth and send back
        if (destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(destAmount);
            msg.sender.transfer(destAmount);
        } else {
            ERC20(destAddr).safeTransfer(msg.sender, destAmount);
        }

        return destAmount;
    }

    /// @notice Buys a _destAmount of tokens at Oasis
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) external override payable returns(uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        ERC20(srcAddr).safeApprove(OTC_ADDRESS, uint(-1));

        uint srcAmount = OasisInterface(OTC_ADDRESS).buyAllAmount(destAddr, _destAmount, srcAddr, uint(-1));

        // convert weth -> eth and send back
        if (destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(_destAmount);
            msg.sender.transfer(_destAmount);
        } else {
            ERC20(destAddr).safeTransfer(msg.sender, _destAmount);
        }

        // Send the leftover from the source token back
        sendLeftOver(srcAddr);

        return srcAmount;
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) public override view returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        return wdiv(OasisInterface(OTC_ADDRESS).getBuyAmount(destAddr, srcAddr, _srcAmount), _srcAmount);
    }


    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) public override view returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        return wdiv(1 ether, wdiv(OasisInterface(OTC_ADDRESS).getPayAmount(srcAddr, destAddr, _destAmount), _destAmount));
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
     function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }


    receive() payable external {}
}

pragma solidity ^0.6.0;

abstract contract OasisInterface {
    function getBuyAmount(address tokenToBuy, address tokenToPay, uint256 amountToPay)
        external
        virtual
        view
        returns (uint256 amountBought);

    function getPayAmount(address tokenToPay, address tokenToBuy, uint256 amountToBuy)
        public virtual
        view
        returns (uint256 amountPaid);

    function sellAllAmount(address pay_gem, uint256 pay_amt, address buy_gem, uint256 min_fill_amount)
        public virtual
        returns (uint256 fill_amt);

    function buyAllAmount(address buy_gem, uint256 buy_amt, address pay_gem, uint256 max_fill_amount)
        public virtual
        returns (uint256 fill_amt);
}

pragma solidity ^0.6.0;

import "../../interfaces/Join.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/Vat.sol";
import "../../interfaces/Flipper.sol";
import "../../interfaces/Gem.sol";

contract BidProxy {

    address public constant DAI_JOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function daiBid(uint _bidId, uint _amount, address _flipper) public {
        uint tendAmount = _amount * (10 ** 27);

        joinDai(_amount);

        (, uint lot, , , , , , ) = Flipper(_flipper).bids(_bidId);

        Vat(VAT_ADDRESS).hope(_flipper);

        Flipper(_flipper).tend(_bidId, lot, tendAmount);
    }

    function collateralBid(uint _bidId, uint _amount, address _flipper) public {
        (uint bid, , , , , , , ) = Flipper(_flipper).bids(_bidId);

        joinDai(bid / (10**27));

        Vat(VAT_ADDRESS).hope(_flipper);

        Flipper(_flipper).dent(_bidId, _amount, bid);
    }

    function closeBid(uint _bidId, address _flipper, address _joinAddr) public {
        bytes32 ilk = Join(_joinAddr).ilk();

        Flipper(_flipper).deal(_bidId);
        uint amount = Vat(VAT_ADDRESS).gem(ilk, address(this));

        Vat(VAT_ADDRESS).hope(_joinAddr);
        Gem(_joinAddr).exit(msg.sender, amount);
    }

    function exitCollateral(address _joinAddr) public {
        bytes32 ilk = Join(_joinAddr).ilk();

        uint amount = Vat(VAT_ADDRESS).gem(ilk, address(this));

        if(Join(_joinAddr).dec() != 18) {
            amount = amount / (10**(18 - Join(_joinAddr).dec()));
        }

        Vat(VAT_ADDRESS).hope(_joinAddr);
        Gem(_joinAddr).exit(msg.sender, amount);
    }

    function exitDai() public {
        uint amount = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        Vat(VAT_ADDRESS).hope(DAI_JOIN);
        Gem(DAI_JOIN).exit(msg.sender, amount);
    }

    function withdrawToken(address _token) public {
        uint balance = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, balance);
    }

    function withdrawEth() public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function joinDai(uint _amount) internal {
        uint amountInVat = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        if (_amount > amountInVat) {
            uint amountDiff = (_amount - amountInVat) + 1;

            ERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), amountDiff);
            ERC20(DAI_ADDRESS).approve(DAI_JOIN, amountDiff);
            Join(DAI_JOIN).join(address(this), amountDiff);
        }
    }
}

pragma solidity ^0.6.0;

abstract contract Flipper {
    function bids(uint _bidId) public virtual returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function tend(uint id, uint lot, uint bid) virtual external;
    function dent(uint id, uint lot, uint bid) virtual external;
    function deal(uint id) virtual external;
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./saver/MCDSaverProxyHelper.sol";
import "../interfaces/Spotter.sol";

contract MCDLoanInfo is MCDSaverProxyHelper {

    Manager public constant manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    Vat public constant vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Spotter public constant spotter = Spotter(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    struct VaultInfo {
        address owner;
        uint256 ratio;
    	uint256 collateral;
    	uint256 debt;
    	bytes32 ilk;
    	address urn;
    }

	/// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    /// @notice Gets CDP ratio
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getRatio(uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint price = getPrice( _ilk);

        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        if (debt == 0) return 0;

        return rdiv(wmul(collateral, price), debt);
    }

    /// @notice Gets CDP info (collateral, debt, price, ilk)
    /// @param _cdpId Id of the CDP
    function getVaultInfo(uint _cdpId) public view returns (VaultInfo memory vaultInfo) {
        address urn = manager.urns(_cdpId);
        bytes32 ilk = manager.ilks(_cdpId);

        (uint256 collateral, uint256 debt) = vat.urns(ilk, urn);
        (,uint rate,,,) = vat.ilks(ilk);

        debt = rmul(debt, rate);

        vaultInfo = VaultInfo({
            owner: manager.owns(_cdpId),
            ratio: getRatio(_cdpId, ilk),
            collateral: collateral,
            debt: debt,
            ilk: ilk,
            urn: urn
        });
    }

    function getVaultInfos(uint256[] memory _cdps) public view returns (VaultInfo[] memory vaultInfos) {
    	vaultInfos = new VaultInfo[](_cdps.length);

    	for (uint256 i = 0; i < _cdps.length; i++) {
    		vaultInfos[i] = getVaultInfo(_cdps[i]);
    	}
    }

    function getRatios(uint256[] memory _cdps) public view returns (uint[] memory ratios) {
    	ratios = new uint256[](_cdps.length);

    	for (uint256 i = 0; i<_cdps.length; i++) {
    		bytes32 ilk = manager.ilks(_cdps[i]);

    		ratios[i] = getRatio(_cdps[i], ilk);
    	}
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/Manager.sol";
import "./StaticV2.sol";
import "../saver/MCDSaverProxy.sol";
import "../../interfaces/Vat.sol";
import "../../interfaces/Spotter.sol";
import "../../auth/AdminAuth.sol";

/// @title Handles subscriptions for automatic monitoring
contract SubscriptionsV2 is AdminAuth, StaticV2 {

    bytes32 internal constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant BAT_ILK = 0x4241542d41000000000000000000000000000000000000000000000000000000;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;

    CdpHolder[] public subscribers;
    mapping (uint => SubPosition) public subscribersPos;

    mapping (bytes32 => uint) public minLimits;

    uint public changeIndex;

    Manager public manager = Manager(MANAGER_ADDRESS);
    Vat public vat = Vat(VAT_ADDRESS);
    Spotter public spotter = Spotter(SPOTTER_ADDRESS);
    MCDSaverProxy public saverProxy;

    event Subscribed(address indexed owner, uint cdpId);
    event Unsubscribed(address indexed owner, uint cdpId);
    event Updated(address indexed owner, uint cdpId);
    event ParamUpdates(address indexed owner, uint cdpId, uint128, uint128, uint128, uint128, bool boostEnabled);

    /// @param _saverProxy Address of the MCDSaverProxy contract
    constructor(address _saverProxy) public {
        saverProxy = MCDSaverProxy(payable(_saverProxy));

        minLimits[ETH_ILK] = 1700000000000000000;
        minLimits[BAT_ILK] = 1700000000000000000;
    }

    /// @dev Called by the DSProxy contract which owns the CDP
    /// @notice Adds the users CDP in the list of subscriptions so it can be monitored
    /// @param _cdpId Id of the CDP
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalBoost Ratio amount which boost should target
    /// @param _optimalRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    /// @param _nextPriceEnabled Boolean determing if we can use nextPrice for this cdp
    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled, bool _nextPriceEnabled) external {
        require(isOwner(msg.sender, _cdpId), "Must be called by Cdp owner");

        // if boost is not enabled, set max ratio to max uint
        uint128 localMaxRatio = _boostEnabled ? _maxRatio : uint128(-1);
        require(checkParams(manager.ilks(_cdpId), _minRatio, localMaxRatio), "Must be correct params");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        CdpHolder memory subscription = CdpHolder({
                minRatio: _minRatio,
                maxRatio: localMaxRatio,
                optimalRatioBoost: _optimalBoost,
                optimalRatioRepay: _optimalRepay,
                owner: msg.sender,
                cdpId: _cdpId,
                boostEnabled: _boostEnabled,
                nextPriceEnabled: _nextPriceEnabled
            });

        changeIndex++;

        if (subInfo.subscribed) {
            subscribers[subInfo.arrPos] = subscription;

            emit Updated(msg.sender, _cdpId);
            emit ParamUpdates(msg.sender, _cdpId, _minRatio, localMaxRatio, _optimalBoost, _optimalRepay, _boostEnabled);
        } else {
            subscribers.push(subscription);

            subInfo.arrPos = subscribers.length - 1;
            subInfo.subscribed = true;

            emit Subscribed(msg.sender, _cdpId);
        }
    }

    /// @notice Called by the users DSProxy
    /// @dev Owner who subscribed cancels his subscription
    function unsubscribe(uint _cdpId) external {
        require(isOwner(msg.sender, _cdpId), "Must be called by Cdp owner");

        _unsubscribe(_cdpId);
    }

    /// @dev Checks if the _owner is the owner of the CDP
    function isOwner(address _owner, uint _cdpId) internal view returns (bool) {
        return getOwner(_cdpId) == _owner;
    }

    /// @dev Checks limit for minimum ratio and if minRatio is bigger than max
    function checkParams(bytes32 _ilk, uint128 _minRatio, uint128 _maxRatio) internal view returns (bool) {
        if (_minRatio < minLimits[_ilk]) {
            return false;
        }

        if (_minRatio > _maxRatio) {
            return false;
        }

        return true;
    }

    /// @dev Internal method to remove a subscriber from the list
    function _unsubscribe(uint _cdpId) internal {
        require(subscribers.length > 0, "Must have subscribers in the list");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        require(subInfo.subscribed, "Must first be subscribed");

        uint lastCdpId = subscribers[subscribers.length - 1].cdpId;

        SubPosition storage subInfo2 = subscribersPos[lastCdpId];
        subInfo2.arrPos = subInfo.arrPos;

        subscribers[subInfo.arrPos] = subscribers[subscribers.length - 1];
        subscribers.pop();

        changeIndex++;
        subInfo.subscribed = false;
        subInfo.arrPos = 0;

        emit Unsubscribed(msg.sender, _cdpId);
    }

    /// @notice Returns an address that owns the CDP
    /// @param _cdpId Id of the CDP
    function getOwner(uint _cdpId) public view returns(address) {
        return manager.owns(_cdpId);
    }

    /// @notice Helper method for the front to get all the info about the subscribed CDP
    function getSubscribedInfo(uint _cdpId) public view returns(bool, uint128, uint128, uint128, uint128, address, uint coll, uint debt) {
        SubPosition memory subInfo = subscribersPos[_cdpId];

        if (!subInfo.subscribed) return (false, 0, 0, 0, 0, address(0), 0, 0);

        (coll, debt) = saverProxy.getCdpInfo(manager, _cdpId, manager.ilks(_cdpId));

        CdpHolder memory subscriber = subscribers[subInfo.arrPos];

        return (
            true,
            subscriber.minRatio,
            subscriber.maxRatio,
            subscriber.optimalRatioRepay,
            subscriber.optimalRatioBoost,
            subscriber.owner,
            coll,
            debt
        );
    }

    function getCdpHolder(uint _cdpId) public view returns (bool subscribed, CdpHolder memory) {
        SubPosition memory subInfo = subscribersPos[_cdpId];

        if (!subInfo.subscribed) return (false, CdpHolder(0, 0, 0, 0, address(0), 0, false, false));

        CdpHolder memory subscriber = subscribers[subInfo.arrPos];

        return (true, subscriber);
    }

    /// @notice Helper method for the front to get the information about the ilk of a CDP
    function getIlkInfo(bytes32 _ilk, uint _cdpId) public view returns(bytes32 ilk, uint art, uint rate, uint spot, uint line, uint dust, uint mat, uint par) {
        // send either ilk or cdpId
        if (_ilk == bytes32(0)) {
            _ilk = manager.ilks(_cdpId);
        }

        ilk = _ilk;
        (,mat) = spotter.ilks(_ilk);
        par = spotter.par();
        (art, rate, spot, line, dust) = vat.ilks(_ilk);
    }

    /// @notice Helper method to return all the subscribed CDPs
    function getSubscribers() public view returns (CdpHolder[] memory) {
        return subscribers;
    }

    /// @notice Helper method to return all the subscribed CDPs
    function getSubscribersByPage(uint _page, uint _perPage) public view returns (CdpHolder[] memory) {
        CdpHolder[] memory holders = new CdpHolder[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        uint count = 0;
        for (uint i=start; i<end; i++) {
            holders[count] = subscribers[i];
            count++;
        }

        return holders;
    }

    ////////////// ADMIN METHODS ///////////////////

    /// @notice Admin function to change a min. limit for an asset
    function changeMinRatios(bytes32 _ilk, uint _newRatio) public onlyOwner {
        minLimits[_ilk] = _newRatio;
    }

    /// @notice Admin function to unsubscribe a CDP
    function unsubscribeByAdmin(uint _cdpId) public onlyOwner {
        SubPosition storage subInfo = subscribersPos[_cdpId];

        if (subInfo.subscribed) {
            _unsubscribe(_cdpId);
        }
    }
}

pragma solidity ^0.6.0;

/// @title Implements enum Method
abstract contract StaticV2 {

    enum Method { Boost, Repay }

    struct CdpHolder {
        uint128 minRatio;
        uint128 maxRatio;
        uint128 optimalRatioBoost;
        uint128 optimalRatioRepay;
        address owner;
        uint cdpId;
        bool boostEnabled;
        bool nextPriceEnabled;
    }

    struct SubPosition {
        uint arrPos;
        bool subscribed;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/Manager.sol";
import "../../interfaces/Vat.sol";
import "../../interfaces/Spotter.sol";

import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../utils/GasBurner.sol";
import "../../utils/BotRegistry.sol";
import "../../exchangeV3/DFSExchangeData.sol";

import "./ISubscriptionsV2.sol";
import "./StaticV2.sol";
import "./MCDMonitorProxyV2.sol";


/// @title Implements logic that allows bots to call Boost and Repay
contract MCDMonitorV2 is DSMath, AdminAuth, GasBurner, StaticV2 {

    uint public REPAY_GAS_TOKEN = 25;
    uint public BOOST_GAS_TOKEN = 25;

    uint public MAX_GAS_PRICE = 800000000000; // 800 gwei

    uint public REPAY_GAS_COST = 1000000;
    uint public BOOST_GAS_COST = 1000000;

    bytes4 public REPAY_SELECTOR = 0xf360ce20;
    bytes4 public BOOST_SELECTOR = 0x8ec2ae25;

    MCDMonitorProxyV2 public monitorProxyContract;
    ISubscriptionsV2 public subscriptionsContract;
    address public mcdSaverTakerAddress;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    address public constant PROXY_PERMISSION_ADDR = 0x5a4f877CA808Cca3cB7c2A194F80Ab8588FAE26B;

    Manager public manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    Vat public vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Spotter public spotter = Spotter(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    constructor(address _monitorProxy, address _subscriptions, address _mcdSaverTakerAddress) public {
        monitorProxyContract = MCDMonitorProxyV2(_monitorProxy);
        subscriptionsContract = ISubscriptionsV2(_subscriptions);
        mcdSaverTakerAddress = _mcdSaverTakerAddress;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    function repayFor(
        DFSExchangeData.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _nextPrice,
        address _joinAddr
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _cdpId, _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(REPAY_GAS_COST);

        address owner = subscriptionsContract.getOwner(_cdpId);

        monitorProxyContract.callExecute{value: msg.value}(
            owner,
            mcdSaverTakerAddress,
            abi.encodeWithSelector(REPAY_SELECTOR, _exchangeData, _cdpId, gasCost, _joinAddr, 0));


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _cdpId, _nextPrice);
        require(isGoodRatio);

        returnEth();

        logger.Log(address(this), owner, "AutomaticMCDRepay", abi.encode(ratioBefore, ratioAfter));
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    function boostFor(
        DFSExchangeData.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _nextPrice,
        address _joinAddr
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN)  {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _cdpId, _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(BOOST_GAS_COST);

        address owner = subscriptionsContract.getOwner(_cdpId);

        monitorProxyContract.callExecute{value: msg.value}(
            owner,
            mcdSaverTakerAddress,
            abi.encodeWithSelector(BOOST_SELECTOR, _exchangeData, _cdpId, gasCost, _joinAddr, 0));

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _cdpId, _nextPrice);
        require(isGoodRatio);

        returnEth();

        logger.Log(address(this), owner, "AutomaticMCDBoost", abi.encode(ratioBefore, ratioAfter));
    }

/******************* INTERNAL METHODS ********************************/
    function returnEth() internal {
        // return if some eth left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

/******************* STATIC METHODS ********************************/

    /// @notice Returns an address that owns the CDP
    /// @param _cdpId Id of the CDP
    function getOwner(uint _cdpId) public view returns(address) {
        return manager.owns(_cdpId);
    }

    /// @notice Gets CDP info (collateral, debt)
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getCdpInfo(uint _cdpId, bytes32 _ilk) public view returns (uint, uint) {
        address urn = manager.urns(_cdpId);

        (uint collateral, uint debt) = vat.urns(_ilk, urn);
        (,uint rate,,,) = vat.ilks(_ilk);

        return (collateral, rmul(debt, rate));
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    /// @notice Gets CDP ratio
    /// @param _cdpId Id of the CDP
    /// @param _nextPrice Next price for user
    function getRatio(uint _cdpId, uint _nextPrice) public view returns (uint) {
        bytes32 ilk = manager.ilks(_cdpId);
        uint price = (_nextPrice == 0) ? getPrice(ilk) : _nextPrice;

        (uint collateral, uint debt) = getCdpInfo(_cdpId, ilk);

        if (debt == 0) return 0;

        return rdiv(wmul(collateral, price), debt) / (10 ** 18);
    }

    /// @notice Checks if Boost/Repay could be triggered for the CDP
    /// @dev Called by MCDMonitor to enforce the min/max check
    function canCall(Method _method, uint _cdpId, uint _nextPrice) public view returns(bool, uint) {
        bool subscribed;
        CdpHolder memory holder;
        (subscribed, holder) = subscriptionsContract.getCdpHolder(_cdpId);

        // check if cdp is subscribed
        if (!subscribed) return (false, 0);

        // check if using next price is allowed
        if (_nextPrice > 0 && !holder.nextPriceEnabled) return (false, 0);

        // check if boost and boost allowed
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        // check if owner is still owner
        if (getOwner(_cdpId) != holder.owner) return (false, 0);

        uint currRatio = getRatio(_cdpId, _nextPrice);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    /// @dev After the Boost/Repay check if the ratio doesn't trigger another call
    function ratioGoodAfter(Method _method, uint _cdpId, uint _nextPrice) public view returns(bool, uint) {
        CdpHolder memory holder;

        (, holder) = subscriptionsContract.getCdpHolder(_cdpId);

        uint currRatio = getRatio(_cdpId, _nextPrice);

        if (_method == Method.Repay) {
            return (currRatio < holder.maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.minRatio, currRatio);
        }
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) public view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

    /// @notice Allows owner to change gas cost for boost operation, but only up to 3 millions
    /// @param _gasCost New gas cost for boost method
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change gas cost for repay operation, but only up to 3 millions
    /// @param _gasCost New gas cost for repay method
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change max gas price
    /// @param _maxGasPrice New max gas price
    function changeMaxGasPrice(uint _maxGasPrice) public onlyOwner {
        require(_maxGasPrice < 1000000000000);

        MAX_GAS_PRICE = _maxGasPrice;
    }

    /// @notice Allows owner to change the amount of gas token burned per function call
    /// @param _gasAmount Amount of gas token
    /// @param _isRepay Flag to know for which function we are setting the gas token amount
    function changeGasTokenAmount(uint _gasAmount, bool _isRepay) public onlyOwner {
        if (_isRepay) {
            REPAY_GAS_TOKEN = _gasAmount;
        } else {
            BOOST_GAS_TOKEN = _gasAmount;
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StaticV2.sol";

abstract contract ISubscriptionsV2 is StaticV2 {

    function getOwner(uint _cdpId) external view virtual returns(address);
    function getSubscribedInfo(uint _cdpId) public view virtual returns(bool, uint128, uint128, uint128, uint128, address, uint coll, uint debt);
    function getCdpHolder(uint _cdpId) public view virtual returns (bool subscribed, CdpHolder memory);
}

pragma solidity ^0.6.0;

import "../../interfaces/DSProxyInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../auth/AdminAuth.sol";

/// @title Implements logic for calling MCDSaverProxy always from same contract
contract MCDMonitorProxyV2 is AdminAuth {

    uint public CHANGE_PERIOD;
    uint public MIN_CHANGE_PERIOD = 6 * 1 hours;
    address public monitor;
    address public newMonitor;
    address public lastMonitor;
    uint public changeRequestedTimestamp;

    event MonitorChangeInitiated(address oldMonitor, address newMonitor);
    event MonitorChangeCanceled();
    event MonitorChangeFinished(address monitor);
    event MonitorChangeReverted(address monitor);

    modifier onlyMonitor() {
        require (msg.sender == monitor);
        _;
    }

    constructor(uint _changePeriod) public {
        CHANGE_PERIOD = _changePeriod * 1 hours;
    }

    /// @notice Only monitor contract is able to call execute on users proxy
    /// @param _owner Address of cdp owner (users DSProxy address)
    /// @param _saverProxy Address of MCDSaverProxy
    /// @param _data Data to send to MCDSaverProxy
    function callExecute(address _owner, address _saverProxy, bytes memory _data) public payable onlyMonitor {
        // execute reverts if calling specific method fails
        DSProxyInterface(_owner).execute{value: msg.value}(_saverProxy, _data);

        // return if anything left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @notice Allowed users are able to set Monitor contract without any waiting period first time
    /// @param _monitor Address of Monitor contract
    function setMonitor(address _monitor) public onlyOwner {
        require(monitor == address(0));
        monitor = _monitor;
    }

    /// @notice Allowed users are able to start procedure for changing monitor
    /// @dev after CHANGE_PERIOD needs to call confirmNewMonitor to actually make a change
    /// @param _newMonitor address of new monitor
    function changeMonitor(address _newMonitor) public onlyOwner {
        require(changeRequestedTimestamp == 0);

        changeRequestedTimestamp = now;
        lastMonitor = monitor;
        newMonitor = _newMonitor;

        emit MonitorChangeInitiated(lastMonitor, newMonitor);
    }

    /// @notice At any point allowed users are able to cancel monitor change
    function cancelMonitorChange() public onlyOwner {
        require(changeRequestedTimestamp > 0);

        changeRequestedTimestamp = 0;
        newMonitor = address(0);

        emit MonitorChangeCanceled();
    }

    /// @notice Anyone is able to confirm new monitor after CHANGE_PERIOD if process is started
    function confirmNewMonitor() public onlyOwner {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);
        require(newMonitor != address(0));

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;

        emit MonitorChangeFinished(monitor);
    }

    /// @notice Its possible to revert monitor to last used monitor
    function revertMonitor() public onlyOwner {
        require(lastMonitor != address(0));

        monitor = lastMonitor;

        emit MonitorChangeReverted(monitor);
    }

    function setChangePeriod(uint _periodInHours) public onlyOwner {
        require(_periodInHours * 1 hours > MIN_CHANGE_PERIOD);

        CHANGE_PERIOD = _periodInHours * 1 hours;
    }

}

pragma solidity ^0.6.0;

import "../../interfaces/CEtherInterface.sol";
import "../../interfaces/CompoundOracleInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ComptrollerInterface.sol";
import "../../interfaces/IFeeRecipient.sol";

import "../../utils/Discount.sol";
import "../../DS/DSMath.sol";
import "../../DS/DSProxy.sol";
import "./Exponential.sol";
import "../../utils/BotRegistry.sol";

import "../../utils/SafeERC20.sol";

/// @title Utlity functions for Compound contracts
contract CompoundSaverHelper is DSMath, Exponential {

    using SafeERC20 for ERC20;

    IFeeRecipient public constant feeRecipient = IFeeRecipient(0x39C4a92Dc506300c3Ea4c67ca4CA611102ee6F2A);

    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address public constant COMPOUND_LOGGER = 0x3DD0CDf5fFA28C6847B4B276e2fD256046a44bb7;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    /// @notice Helper method to payback the Compound debt
    /// @dev If amount is bigger it will repay the whole debt and send the extra to the _user
    /// @param _amount Amount of tokens we want to repay
    /// @param _cBorrowToken Ctoken address we are repaying
    /// @param _borrowToken Token address we are repaying
    /// @param _user Owner of the compound position we are paying back
    function paybackDebt(uint _amount, address _cBorrowToken, address _borrowToken, address payable _user) internal {
        uint wholeDebt = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(address(this));

        if (_amount > wholeDebt) {
            if (_borrowToken == ETH_ADDRESS) {
                _user.transfer((_amount - wholeDebt));
            } else {
                ERC20(_borrowToken).safeTransfer(_user, (_amount - wholeDebt));
            }

            _amount = wholeDebt;
        }

        approveCToken(_borrowToken, _cBorrowToken);

        if (_borrowToken == ETH_ADDRESS) {
            CEtherInterface(_cBorrowToken).repayBorrow{value: _amount}();
        } else {
            require(CTokenInterface(_cBorrowToken).repayBorrow(_amount) == 0);
        }
    }

    /// @notice Calculates the fee amount
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _cTokenAddr CToken addr. of token we are getting for the fee
    /// @return feeAmount The amount we took for the fee
    function getFee(uint _amount, address _user, uint _gasCost, address _cTokenAddr) internal returns (uint feeAmount) {
        uint fee = MANUAL_SERVICE_FEE;

        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            fee = AUTOMATIC_SERVICE_FEE;
        }

        address tokenAddr = getUnderlyingAddr(_cTokenAddr);

        if (Discount(DISCOUNT_ADDR).isCustomFeeSet(_user)) {
            fee = Discount(DISCOUNT_ADDR).getCustomServiceFee(_user);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        if (_gasCost != 0) {
            address oracle = ComptrollerInterface(COMPTROLLER).oracle();

            uint usdTokenPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(_cTokenAddr);
            uint ethPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(CETH_ADDRESS);

            uint tokenPriceInEth = wdiv(usdTokenPrice, ethPrice);

            _gasCost = wdiv(_gasCost, tokenPriceInEth);

            feeAmount = add(feeAmount, _gasCost);
        }

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        address walletAddr = feeRecipient.getFeeAddr();

        if (tokenAddr == ETH_ADDRESS) {
            payable(walletAddr).transfer(feeAmount);
        } else {
            ERC20(tokenAddr).safeTransfer(walletAddr, feeAmount);
        }
    }

    /// @notice Calculates the gas cost of transaction and send it to wallet
    /// @param _amount Amount that is converted
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _cTokenAddr CToken addr. of token we are getting for the fee
    /// @return feeAmount The amount we took for the fee
    function getGasCost(uint _amount, uint _gasCost, address _cTokenAddr) internal returns (uint feeAmount) {
        address tokenAddr = getUnderlyingAddr(_cTokenAddr);

        if (_gasCost != 0) {
            address oracle = ComptrollerInterface(COMPTROLLER).oracle();

            uint usdTokenPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(_cTokenAddr);
            uint ethPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(CETH_ADDRESS);

            uint tokenPriceInEth = wdiv(usdTokenPrice, ethPrice);

            feeAmount = wdiv(_gasCost, tokenPriceInEth);
        }

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        address walletAddr = feeRecipient.getFeeAddr();

        if (tokenAddr == ETH_ADDRESS) {
            payable(walletAddr).transfer(feeAmount);
        } else {
            ERC20(tokenAddr).safeTransfer(walletAddr, feeAmount);
        }
    }

    /// @notice Enters the market for the collatera and borrow tokens
    /// @param _cTokenAddrColl Collateral address we are entering the market in
    /// @param _cTokenAddrBorrow Borrow address we are entering the market in
    function enterMarket(address _cTokenAddrColl, address _cTokenAddrBorrow) internal {
        address[] memory markets = new address[](2);
        markets[0] = _cTokenAddrColl;
        markets[1] = _cTokenAddrBorrow;

        ComptrollerInterface(COMPTROLLER).enterMarkets(markets);
    }

    /// @notice Approves CToken contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _cTokenAddr Address which will gain the approval
    function approveCToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).safeApprove(_cTokenAddr, uint(-1));
        }
    }

    /// @notice Returns the underlying address of the cToken asset
    /// @param _cTokenAddress cToken address
    /// @return Token address of the cToken specified
    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    /// @notice Returns the owner of the DSProxy that called the contract
    function getUserAddress() internal view returns (address) {
        DSProxy proxy = DSProxy(uint160(address(this)));

        return proxy.owner();
    }

    /// @notice Returns the maximum amount of collateral available to withdraw
    /// @dev Due to rounding errors the result is - 1% wei from the exact amount
    /// @param _cCollAddress Collateral we are getting the max value of
    /// @param _account Users account
    /// @return Returns the max. collateral amount in that token
    function getMaxCollateral(address _cCollAddress, address _account) public returns (uint) {
        (, uint liquidityInUsd, ) = ComptrollerInterface(COMPTROLLER).getAccountLiquidity(_account);
        uint usersBalance = CTokenInterface(_cCollAddress).balanceOfUnderlying(_account);
        address oracle = ComptrollerInterface(COMPTROLLER).oracle();

        if (liquidityInUsd == 0) return usersBalance;

        CTokenInterface(_cCollAddress).accrueInterest();

        (, uint collFactorMantissa) = ComptrollerInterface(COMPTROLLER).markets(_cCollAddress);
        Exp memory collateralFactor = Exp({mantissa: collFactorMantissa});

        (, uint tokensToUsd) = divScalarByExpTruncate(liquidityInUsd, collateralFactor);

        uint usdPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(_cCollAddress);
        uint liqInToken = wdiv(tokensToUsd, usdPrice);

        if (liqInToken > usersBalance) return usersBalance;

        return sub(liqInToken, (liqInToken / 100)); // cut off 1% due to rounding issues
    }

    /// @notice Returns the maximum amount of borrow amount available
    /// @dev Due to rounding errors the result is - 1% wei from the exact amount
    /// @param _cBorrowAddress Borrow token we are getting the max value of
    /// @param _account Users account
    /// @return Returns the max. borrow amount in that token
    function getMaxBorrow(address _cBorrowAddress, address _account) public returns (uint) {
        (, uint liquidityInUsd, ) = ComptrollerInterface(COMPTROLLER).getAccountLiquidity(_account);
        address oracle = ComptrollerInterface(COMPTROLLER).oracle();

        CTokenInterface(_cBorrowAddress).accrueInterest();

        uint usdPrice = CompoundOracleInterface(oracle).getUnderlyingPrice(_cBorrowAddress);
        uint liquidityInToken = wdiv(liquidityInUsd, usdPrice);

        return sub(liquidityInToken, (liquidityInToken / 100)); // cut off 1% due to rounding issues
    }

    function isAutomation() internal view returns(bool) {
        return BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin);
    }
}

pragma solidity ^0.6.0;

import "../../compound/helpers/CompoundSaverHelper.sol";

contract CompShifter is CompoundSaverHelper {

    using SafeERC20 for ERC20;

    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    function getLoanAmount(uint _cdpId, address _joinAddr) public returns(uint loanAmount) {
        return getWholeDebt(_cdpId, _joinAddr);
    }

    function getWholeDebt(uint _cdpId, address _joinAddr) public returns(uint loanAmount) {
        return CTokenInterface(_joinAddr).borrowBalanceCurrent(msg.sender);
    }

    function close(
        address _cCollAddr,
        address _cBorrowAddr,
        uint _collAmount,
        uint _debtAmount
    ) public {
        address collAddr = getUnderlyingAddr(_cCollAddr);

        // payback debt
        paybackDebt(_debtAmount, _cBorrowAddr, getUnderlyingAddr(_cBorrowAddr), tx.origin);

        require(CTokenInterface(_cCollAddr).redeemUnderlying(_collAmount) == 0);

        // Send back money to repay FL
        if (collAddr == ETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(collAddr).safeTransfer(msg.sender, ERC20(collAddr).balanceOf(address(this)));
        }
    }

    function changeDebt(
        address _cBorrowAddrOld,
        address _cBorrowAddrNew,
        uint _debtAmountOld,
        uint _debtAmountNew
    ) public {

        address borrowAddrNew = getUnderlyingAddr(_cBorrowAddrNew);

        // payback debt in one token
        paybackDebt(_debtAmountOld, _cBorrowAddrOld, getUnderlyingAddr(_cBorrowAddrOld), tx.origin);

        // draw debt in another one
        borrowCompound(_cBorrowAddrNew, _debtAmountNew);

        // Send back money to repay FL
        if (borrowAddrNew == ETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(borrowAddrNew).safeTransfer(msg.sender, ERC20(borrowAddrNew).balanceOf(address(this)));
        }
    }

    function open(
        address _cCollAddr,
        address _cBorrowAddr,
        uint _debtAmount
    ) public {

        address collAddr = getUnderlyingAddr(_cCollAddr);
        address borrowAddr = getUnderlyingAddr(_cBorrowAddr);

        uint collAmount = 0;

        if (collAddr == ETH_ADDRESS) {
            collAmount = address(this).balance;
        } else {
            collAmount = ERC20(collAddr).balanceOf(address(this));
        }

        depositCompound(collAddr, _cCollAddr, collAmount);

        // draw debt
        borrowCompound(_cBorrowAddr, _debtAmount);

        // Send back money to repay FL
        if (borrowAddr == ETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(borrowAddr).safeTransfer(msg.sender, ERC20(borrowAddr).balanceOf(address(this)));
        }

    }

    function repayAll(address _cTokenAddr) public {
        address tokenAddr = getUnderlyingAddr(_cTokenAddr);
        uint amount = ERC20(tokenAddr).balanceOf(address(this));

        if (amount != 0) {
            paybackDebt(amount, _cTokenAddr, tokenAddr, tx.origin);
        }
    }

    function depositCompound(address _tokenAddr, address _cTokenAddr, uint _amount) internal {
        approveCToken(_tokenAddr, _cTokenAddr);

        enterMarket(_cTokenAddr);

        if (_tokenAddr != ETH_ADDRESS) {
            require(CTokenInterface(_cTokenAddr).mint(_amount) == 0, "mint error");
        } else {
            CEtherInterface(_cTokenAddr).mint{value: _amount}();
        }
    }

    function borrowCompound(address _cTokenAddr, uint _amount) internal {
        enterMarket(_cTokenAddr);

        require(CTokenInterface(_cTokenAddr).borrow(_amount) == 0);
    }

    function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../exchangeV3/DFSExchangeCore.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../utils/Discount.sol";
import "../helpers/CompoundSaverHelper.sol";
import "../../loggers/DefisaverLogger.sol";

/// @title Implements the actual logic of Repay/Boost with FL
contract CompoundSaverFlashProxy is DFSExchangeCore, CompoundSaverHelper  {

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    using SafeERC20 for ERC20;

    /// @notice Repays the position and sends tokens back for FL
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for transaction
    /// @param _flashLoanData Data about FL [amount, fee]
    function flashRepay(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());
        uint flashBorrowed = _flashLoanData[0] + _flashLoanData[1];

        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));

        // draw max coll
        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(maxColl) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            // swap max coll + loanAmount
            _exData.srcAmount = maxColl + _flashLoanData[0];
            _exData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
            _exData.user = user;

            (,swapAmount) = _sell(_exData);

            // get fee
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        } else {
            swapAmount = (maxColl + _flashLoanData[0]);
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        // payback debt
        paybackDebt(swapAmount, _cAddresses[1], borrowToken, user);

        // draw collateral for loanAmount + loanFee
        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(flashBorrowed) == 0);

        // repay flash loan
        returnFlashLoan(collToken, flashBorrowed);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CompoundRepay", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Boosts the position and sends tokens back for FL
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    /// @param _flashLoanData Data about FL [amount, fee]
    function flashBoost(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());
        uint flashBorrowed = _flashLoanData[0] + _flashLoanData[1];

        // borrow max amount
        uint borrowAmount = getMaxBorrow(_cAddresses[1], address(this));
        require(CTokenInterface(_cAddresses[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            // get dfs fee
            _exData.srcAmount = (borrowAmount + _flashLoanData[0]);
            _exData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
            _exData.user = user;

            (, swapAmount) = _sell(_exData);
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        } else {
            swapAmount = (borrowAmount + _flashLoanData[0]);
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        // deposit swaped collateral
        depositCollateral(collToken, _cAddresses[0], swapAmount);

        // borrow token to repay flash loan
        require(CTokenInterface(_cAddresses[1]).borrow(flashBorrowed) == 0);

        // repay flash loan
        returnFlashLoan(borrowToken, flashBorrowed);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CompoundBoost", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Helper method to deposit tokens in Compound
    /// @param _collToken Token address of the collateral
    /// @param _cCollToken CToken address of the collateral
    /// @param _depositAmount Amount to deposit
    function depositCollateral(address _collToken, address _cCollToken, uint _depositAmount) internal {
        approveCToken(_collToken, _cCollToken);

        if (_collToken != ETH_ADDRESS) {
            require(CTokenInterface(_cCollToken).mint(_depositAmount) == 0);
        } else {
            CEtherInterface(_cCollToken).mint{value: _depositAmount}(); // reverts on fail
        }
    }

    /// @notice Returns the tokens/ether to the msg.sender which is the FL contract
    /// @param _tokenAddr Address of token which we return
    /// @param _amount Amount to return
    function returnFlashLoan(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, _amount);
        }

        msg.sender.transfer(address(this).balance);
    }

}

pragma solidity ^0.6.0;

import "../../utils/GasBurner.sol";
import "../../auth/ProxyPermission.sol";

import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ILendingPool.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ProxyRegistryInterface.sol";

import "../helpers/CreamSaverHelper.sol";

/// @title Imports cream position from the account to DSProxy
contract CreamImportTaker is CreamSaverHelper, ProxyPermission, GasBurner {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant CREAM_IMPORT_FLASH_LOAN = 0x24F4aC0Fe758c45cf8425D8Fbdd608cca9A7dBf8;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must approve cream_IMPORT_FLASH_LOAN to pull _cCollateralToken
    /// @param _cCollateralToken Collateral we are moving to DSProxy
    /// @param _cBorrowToken Borrow token we are moving to DSProxy
    function importLoan(address _cCollateralToken, address _cBorrowToken) external burnGas(20) {
        address proxy = getProxy();

        uint loanAmount = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(msg.sender);
        bytes memory paramsData = abi.encode(_cCollateralToken, _cBorrowToken, msg.sender, proxy);

        givePermission(CREAM_IMPORT_FLASH_LOAN);

        lendingPool.flashLoan(CREAM_IMPORT_FLASH_LOAN, getUnderlyingAddr(_cBorrowToken), loanAmount, paramsData);

        removePermission(CREAM_IMPORT_FLASH_LOAN);

        logger.Log(address(this), msg.sender, "CreamImport", abi.encode(loanAmount, 0, _cCollateralToken));
    }

    /// @notice Gets proxy address, if user doesn't has DSProxy build it
    /// @return proxy DsProxy address
    function getProxy() internal returns (address proxy) {
        proxy = ProxyRegistryInterface(PROXY_REGISTRY_ADDRESS).proxies(msg.sender);

        if (proxy == address(0)) {
            proxy = ProxyRegistryInterface(PROXY_REGISTRY_ADDRESS).build(msg.sender);
        }

    }
}

pragma solidity ^0.6.0;

import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../utils/SafeERC20.sol";

/// @title Receives FL from Aave and imports the position to DSProxy
contract CreamImportFlashLoan is FlashLoanReceiverBase {

    using SafeERC20 for ERC20;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant CREAM_BORROW_PROXY = 0x87F198Ef6116CdBC5f36B581d212ad950b7e2Ddd;

    address public owner;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
            owner = msg.sender;
    }

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        (
            address cCollateralToken,
            address cBorrowToken,
            address user,
            address proxy
        )
        = abi.decode(_params, (address,address,address,address));

        // approve FL tokens so we can repay them
        ERC20(_reserve).safeApprove(cBorrowToken, uint(-1));

        // repay cream debt
        require(CTokenInterface(cBorrowToken).repayBorrowBehalf(user, uint(-1)) == 0, "Repay borrow behalf fail");

        // transfer cTokens to proxy
        uint cTokenBalance = CTokenInterface(cCollateralToken).balanceOf(user);
        require(CTokenInterface(cCollateralToken).transferFrom(user, proxy, cTokenBalance));

        // borrow
        bytes memory proxyData = getProxyData(cCollateralToken, cBorrowToken, _reserve, (_amount + _fee));
        DSProxyInterface(proxy).execute(CREAM_BORROW_PROXY, proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    /// @notice Formats function data call so we can call it through DSProxy
    /// @param _cCollToken CToken address of collateral
    /// @param _cBorrowToken CToken address we will borrow
    /// @param _borrowToken Token address we will borrow
    /// @param _amount Amount that will be borrowed
    /// @return proxyData Formated function call data
    function getProxyData(address _cCollToken, address _cBorrowToken, address _borrowToken, uint _amount) internal pure returns (bytes memory proxyData) {
        proxyData = abi.encodeWithSignature(
            "borrow(address,address,address,uint256)",
            _cCollToken, _cBorrowToken, _borrowToken, _amount);
    }

    function withdrawStuckFunds(address _tokenAddr, uint _amount) public {
        require(owner == msg.sender, "Must be owner");

        if (_tokenAddr == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            msg.sender.transfer(_amount);
        } else {
            ERC20(_tokenAddr).safeTransfer(owner, _amount);
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../exchangeV3/DFSExchangeCore.sol";

/// @title Receiver of Dydx flash loan and performs the fl repay/boost logic
/// @notice Must have a dust amount of WETH on the contract for 2 wei dydx fee
contract MCDSaverFlashLoan is MCDSaverProxy, AdminAuth, FlashLoanReceiverBase {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    struct SaverData {
        uint cdpId;
        uint gasCost;
        uint loanAmount;
        uint fee;
        address joinAddr;
        ManagerType managerType;
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (
            bytes memory exDataBytes,
            uint cdpId,
            uint gasCost,
            address joinAddr,
            bool isRepay,
            uint8 managerType
        )
         = abi.decode(_params, (bytes,uint256,uint256,address,bool,uint8));

        ExchangeData memory exchangeData = unpackExchangeData(exDataBytes);

        SaverData memory saverData = SaverData({
            cdpId: cdpId,
            gasCost: gasCost,
            loanAmount: _amount,
            fee: _fee,
            joinAddr: joinAddr,
            managerType: ManagerType(managerType)
        });

        if (isRepay) {
            repayWithLoan(exchangeData, saverData);
        } else {
            boostWithLoan(exchangeData, saverData);
        }

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function boostWithLoan(
        ExchangeData memory _exchangeData,
        SaverData memory _saverData
    ) internal {

        address managerAddr = getManagerAddr(_saverData.managerType);

        address user = getOwner(Manager(managerAddr), _saverData.cdpId);

        // Draw users Dai
        uint maxDebt = getMaxDebt(managerAddr, _saverData.cdpId, Manager(managerAddr).ilks(_saverData.cdpId));
        uint daiDrawn = drawDai(managerAddr, _saverData.cdpId, Manager(managerAddr).ilks(_saverData.cdpId), maxDebt);

        // Swap
        _exchangeData.srcAmount = daiDrawn + _saverData.loanAmount - takeFee(_saverData.gasCost, daiDrawn + _saverData.loanAmount);
        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        (, uint swapedAmount) = _sell(_exchangeData);

        // Return collateral
        addCollateral(managerAddr, _saverData.cdpId, _saverData.joinAddr, swapedAmount);

        // Draw Dai to repay the flash loan
        drawDai(managerAddr, _saverData.cdpId,  Manager(managerAddr).ilks(_saverData.cdpId), (_saverData.loanAmount + _saverData.fee));

        logger.Log(address(this), msg.sender, "MCDFlashBoost", abi.encode(_saverData.cdpId, user, _exchangeData.srcAmount, swapedAmount));
    }

    function repayWithLoan(
        ExchangeData memory _exchangeData,
        SaverData memory _saverData
    ) internal {

        address managerAddr = getManagerAddr(_saverData.managerType);

        address user = getOwner(Manager(managerAddr), _saverData.cdpId);
        bytes32 ilk = Manager(managerAddr).ilks(_saverData.cdpId);

        // Draw collateral
        uint maxColl = getMaxCollateral(managerAddr, _saverData.cdpId, ilk, _saverData.joinAddr);
        uint collDrawn = drawCollateral(managerAddr, _saverData.cdpId, _saverData.joinAddr, maxColl);

        // Swap
        _exchangeData.srcAmount = (_saverData.loanAmount + collDrawn);
        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        (, uint paybackAmount) = _sell(_exchangeData);

        paybackAmount -= takeFee(_saverData.gasCost, paybackAmount);
        paybackAmount = limitLoanAmount(managerAddr, _saverData.cdpId, ilk, paybackAmount, user);

        // Payback the debt
        paybackDebt(managerAddr, _saverData.cdpId, ilk, paybackAmount, user);

        // Draw collateral to repay the flash loan
        drawCollateral(managerAddr, _saverData.cdpId, _saverData.joinAddr, (_saverData.loanAmount + _saverData.fee));

        logger.Log(address(this), msg.sender, "MCDFlashRepay", abi.encode(_saverData.cdpId, user, _exchangeData.srcAmount, paybackAmount));
    }

    /// @notice Handles that the amount is not bigger than cdp debt and not dust
    function limitLoanAmount(address _managerAddr, uint _cdpId, bytes32 _ilk, uint _paybackAmount, address _owner) internal returns (uint256) {
        uint debt = getAllDebt(address(vat), Manager(_managerAddr).urns(_cdpId), Manager(_managerAddr).urns(_cdpId), _ilk);

        if (_paybackAmount > debt) {
            ERC20(DAI_ADDRESS).transfer(_owner, (_paybackAmount - debt));
            return debt;
        }

        uint debtLeft = debt - _paybackAmount;

        (,,,, uint dust) = vat.ilks(_ilk);
        dust = dust / 10**27;

        // Less than dust value
        if (debtLeft < dust) {
            uint amountOverDust = (dust - debtLeft);

            ERC20(DAI_ADDRESS).transfer(_owner, amountOverDust);

            return (_paybackAmount - amountOverDust);
        }

        return _paybackAmount;
    }

    receive() external override(FlashLoanReceiverBase, DFSExchangeCore) payable {}

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../auth/AdminAuth.sol";
import "../../exchangeV3/DFSExchangeCore.sol";
import "../../mcd/saver/MCDSaverProxyHelper.sol";
import "./MCDCloseTaker.sol";

contract MCDCloseFlashLoan is DFSExchangeCore, MCDSaverProxyHelper, FlashLoanReceiverBase, AdminAuth {
    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    bytes32 internal constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    DaiJoin public constant daiJoin = DaiJoin(DAI_JOIN_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);
    Vat public constant vat = Vat(VAT_ADDRESS);

    struct CloseData {
        uint cdpId;
        uint collAmount;
        uint daiAmount;
        uint minAccepted;
        address joinAddr;
        address proxy;
        uint flFee;
        bool toDai;
        address reserve;
        uint amount;
    }

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        (address proxy, bytes memory packedData) = abi.decode(_params, (address,bytes));

        (MCDCloseTaker.CloseData memory closeDataSent, ExchangeData memory exchangeData) = abi.decode(packedData, (MCDCloseTaker.CloseData,ExchangeData));

        CloseData memory closeData = CloseData({
            cdpId: closeDataSent.cdpId,
            collAmount: closeDataSent.collAmount,
            daiAmount: closeDataSent.daiAmount,
            minAccepted: closeDataSent.minAccepted,
            joinAddr: closeDataSent.joinAddr,
            proxy: proxy,
            flFee: _fee,
            toDai: closeDataSent.toDai,
            reserve: _reserve,
            amount: _amount
        });

        address user = DSProxy(payable(closeData.proxy)).owner();

        exchangeData.dfsFeeDivider = SERVICE_FEE;
        exchangeData.user = user;

        address managerAddr = getManagerAddr(closeDataSent.managerType);

        closeCDP(closeData, exchangeData, user, managerAddr);
    }

    function closeCDP(
        CloseData memory _closeData,
        ExchangeData memory _exchangeData,
        address _user,
        address _managerAddr
    ) internal {

        paybackDebt(_managerAddr, _closeData.cdpId, Manager(_managerAddr).ilks(_closeData.cdpId), _closeData.daiAmount); // payback whole debt
        uint drawnAmount = drawMaxCollateral(_managerAddr, _closeData.cdpId, _closeData.joinAddr, _closeData.collAmount); // draw whole collateral

        uint daiSwaped = 0;

        if (_closeData.toDai) {
            _exchangeData.srcAmount = drawnAmount;
            (, daiSwaped) = _sell(_exchangeData);
        } else {
            _exchangeData.destAmount = (_closeData.daiAmount + _closeData.flFee);
            (, daiSwaped) = _buy(_exchangeData);
        }

        address tokenAddr = getVaultCollAddr(_closeData.joinAddr);

        if (_closeData.toDai) {
            tokenAddr = DAI_ADDRESS;
        }

        require(getBalance(tokenAddr) >= _closeData.minAccepted, "Below min. number of eth specified");

        transferFundsBackToPoolInternal(_closeData.reserve, _closeData.amount.add(_closeData.flFee));

        sendLeftover(tokenAddr, DAI_ADDRESS, payable(_user));

    }

    function drawMaxCollateral(address _managerAddr, uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        Manager(_managerAddr).frob(_cdpId, -toPositiveInt(_amount), 0);
        Manager(_managerAddr).flux(_cdpId, address(this), _amount);

        uint joinAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            joinAmount = _amount / (10 ** (18 - Join(_joinAddr).dec()));
        }

        Join(_joinAddr).exit(address(this), joinAmount);

        if (isEthJoinAddr(_joinAddr)) {
            Join(_joinAddr).gem().withdraw(joinAmount); // Weth -> Eth
        }

        return joinAmount;
    }

    function paybackDebt(address _managerAddr, uint _cdpId, bytes32 _ilk, uint _daiAmount) internal {
        address urn = Manager(_managerAddr).urns(_cdpId);

        daiJoin.dai().approve(DAI_JOIN_ADDRESS, _daiAmount);
        daiJoin.join(urn, _daiAmount);

        Manager(_managerAddr).frob(_cdpId, 0, normalizePaybackAmount(VAT_ADDRESS, urn, _ilk));
    }

    function getVaultCollAddr(address _joinAddr) internal view returns (address) {
        address tokenAddr = address(Join(_joinAddr).gem());

        if (tokenAddr == EXCHANGE_WETH_ADDRESS) {
            return KYBER_ETH_ADDRESS;
        }

        return tokenAddr;
    }

    function getPrice(bytes32 _ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(_ilk);
        (, , uint256 spot, , ) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    receive() external override(FlashLoanReceiverBase, DFSExchangeCore) payable {}

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ILendingPool.sol";
import "../../exchangeV3/DFSExchangeData.sol";
import "../../utils/GasBurner.sol";

abstract contract IMCDSubscriptions {
    function unsubscribe(uint256 _cdpId) external virtual ;

    function subscribersPos(uint256 _cdpId) external virtual returns (uint256, bool);
}


contract MCDCloseTaker is MCDSaverProxyHelper, GasBurner {

    address public constant SUBSCRIPTION_ADDRESS_NEW = 0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(DEFISAVER_LOGGER);

    struct CloseData {
        uint cdpId;
        address joinAddr;
        uint collAmount;
        uint daiAmount;
        uint minAccepted;
        bool wholeDebt;
        bool toDai;
        ManagerType managerType;
    }

    Vat public constant vat = Vat(VAT_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    function closeWithLoan(
        DFSExchangeData.ExchangeData memory _exchangeData,
        CloseData memory _closeData,
        address payable mcdCloseFlashLoan
    ) public payable burnGas(20) {
        mcdCloseFlashLoan.transfer(msg.value); // 0x fee

        address managerAddr = getManagerAddr(_closeData.managerType);

        if (_closeData.wholeDebt) {
            _closeData.daiAmount = getAllDebt(
                VAT_ADDRESS,
                Manager(managerAddr).urns(_closeData.cdpId),
                Manager(managerAddr).urns(_closeData.cdpId),
                Manager(managerAddr).ilks(_closeData.cdpId)
            );

            (_closeData.collAmount, )
                = getCdpInfo(Manager(managerAddr), _closeData.cdpId, Manager(managerAddr).ilks(_closeData.cdpId));
        }

        Manager(managerAddr).cdpAllow(_closeData.cdpId, mcdCloseFlashLoan, 1);

        bytes memory packedData  = _packData(_closeData, _exchangeData);
        bytes memory paramsData = abi.encode(address(this), packedData);

        lendingPool.flashLoan(mcdCloseFlashLoan, DAI_ADDRESS, _closeData.daiAmount, paramsData);

        Manager(managerAddr).cdpAllow(_closeData.cdpId, mcdCloseFlashLoan, 0);

        // If sub. to automatic protection unsubscribe
        unsubscribe(SUBSCRIPTION_ADDRESS_NEW, _closeData.cdpId);

        logger.Log(address(this), msg.sender, "MCDClose", abi.encode(_closeData.cdpId, _closeData.collAmount, _closeData.daiAmount, _closeData.toDai));
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(address _managerAddr, uint256 _cdpId, bytes32 _ilk) public view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(Manager(_managerAddr), _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(_ilk);
        (, , uint256 spot, , ) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    function unsubscribe(address _subContract, uint _cdpId) internal {
        (, bool isSubscribed) = IMCDSubscriptions(_subContract).subscribersPos(_cdpId);

        if (isSubscribed) {
            IMCDSubscriptions(_subContract).unsubscribe(_cdpId);
        }
    }

    function _packData(
        CloseData memory _closeData,
        DFSExchangeData.ExchangeData memory _exchangeData
    ) internal pure returns (bytes memory) {

        return abi.encode(_closeData, _exchangeData);
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../../exchange/SaverExchangeCore.sol";

/// @title Contract that receives the FL from Aave for Repays/Boost
contract CreamSaverFlashLoan is FlashLoanReceiverBase, SaverExchangeCore {
    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address payable public COMPOUND_SAVER_FLASH_PROXY = 0x1e012554891d271eDc80ba8eB146EA5FF596fA51;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public owner;

    using SafeERC20 for ERC20;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
            owner = msg.sender;
    }

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
   function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {
        // Format the call data for DSProxy
        (bytes memory proxyData, address payable proxyAddr) = packFunctionCall(_amount, _fee, _params);

        // Send Flash loan amount to DSProxy
        sendLoanToProxy(proxyAddr, _reserve, _amount);

        // Execute the DSProxy call
        DSProxyInterface(proxyAddr).execute(COMPOUND_SAVER_FLASH_PROXY, proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    /// @notice Formats function data call so we can call it through DSProxy
    /// @param _amount Amount of FL
    /// @param _fee Fee of the FL
    /// @param _params Saver proxy params
    /// @return proxyData Formated function call data
    function packFunctionCall(uint _amount, uint _fee, bytes memory _params) internal pure returns (bytes memory proxyData, address payable) {
        (
            bytes memory exDataBytes,
            address[2] memory cAddresses, // cCollAddress, cBorrowAddress
            uint256 gasCost,
            bool isRepay,
            address payable proxyAddr
        )
        = abi.decode(_params, (bytes,address[2],uint256,bool,address));

        ExchangeData memory _exData = unpackExchangeData(exDataBytes);

        uint[2] memory flashLoanData = [_amount, _fee];

        if (isRepay) {
            proxyData = abi.encodeWithSignature("flashRepay((address,address,uint256,uint256,uint256,address,address,bytes,uint256),address[2],uint256,uint256[2])", _exData, cAddresses, gasCost, flashLoanData);
        } else {
            proxyData = abi.encodeWithSignature("flashBoost((address,address,uint256,uint256,uint256,address,address,bytes,uint256),address[2],uint256,uint256[2])", _exData, cAddresses, gasCost, flashLoanData);
        }

        return (proxyData, proxyAddr);
    }

    /// @notice Send the FL funds received to DSProxy
    /// @param _proxy DSProxy address
    /// @param _reserve Token address
    /// @param _amount Amount of tokens
    function sendLoanToProxy(address payable _proxy, address _reserve, uint _amount) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, _amount);
        }

        _proxy.transfer(address(this).balance);
    }

    receive() external override(SaverExchangeCore, FlashLoanReceiverBase) payable {}
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../exchange/SaverExchangeCore.sol";

contract ExchangeDataParser {
     function decodeExchangeData(
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (address[4] memory, uint[4] memory, bytes memory) {
        return (
         [exchangeData.srcAddr, exchangeData.destAddr, exchangeData.exchangeAddr, exchangeData.wrapper],
         [exchangeData.srcAmount, exchangeData.destAmount, exchangeData.minPrice, exchangeData.price0x],
         exchangeData.callData
        );
    }

    function encodeExchangeData(
        address[4] memory exAddr, uint[4] memory exNum, bytes memory callData
    ) internal pure returns (SaverExchangeCore.ExchangeData memory) {
        return SaverExchangeCore.ExchangeData({
            srcAddr: exAddr[0],
            destAddr: exAddr[1],
            srcAmount: exNum[0],
            destAmount: exNum[1],
            minPrice: exNum[2],
            wrapper: exAddr[3],
            exchangeAddr: exAddr[2],
            callData: callData,
            price0x: exNum[3]
        });
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/GasTokenInterface.sol";
import "../interfaces/IFeeRecipient.sol";
import "./SaverExchangeCore.sol";
import "../DS/DSMath.sol";
import "../loggers/DefisaverLogger.sol";
import "../auth/AdminAuth.sol";
import "../utils/GasBurner.sol";
import "../utils/SafeERC20.sol";

contract SaverExchange is SaverExchangeCore, AdminAuth, GasBurner {

    using SafeERC20 for ERC20;

    uint256 public constant SERVICE_FEE = 800; // 0.125% Fee

    IFeeRecipient public constant _feeRecipient = IFeeRecipient(0x39C4a92Dc506300c3Ea4c67ca4CA611102ee6F2A);

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    uint public burnAmount = 10;

    /// @notice Takes a src amount of tokens and converts it into the dest token
    /// @dev Takes fee from the _srcAmount before the exchange
    /// @param exData [srcAddr, destAddr, srcAmount, destAmount, minPrice, exchangeType, exchangeAddr, callData, price0x]
    /// @param _user User address who called the exchange
    function sell(ExchangeData memory exData, address payable _user) public payable burnGas(burnAmount) {

        // take fee
        uint dfsFee = getFee(exData.srcAmount, exData.srcAddr);
        exData.srcAmount = sub(exData.srcAmount, dfsFee);

        // Perform the exchange
        (address wrapper, uint destAmount) = _sell(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr, _user);

        // log the event
        logger.Log(address(this), msg.sender, "ExchangeSell", abi.encode(wrapper, exData.srcAddr, exData.destAddr, exData.srcAmount, destAmount));
    }

    /// @notice Takes a dest amount of tokens and converts it from the src token
    /// @dev Send always more than needed for the swap, extra will be returned
    /// @param exData [srcAddr, destAddr, srcAmount, destAmount, minPrice, exchangeType, exchangeAddr, callData, price0x]
    /// @param _user User address who called the exchange
    function buy(ExchangeData memory exData, address payable _user) public payable burnGas(burnAmount){

        uint dfsFee = getFee(exData.srcAmount, exData.srcAddr);
        exData.srcAmount = sub(exData.srcAmount, dfsFee);

        // Perform the exchange
        (address wrapper, uint srcAmount) = _buy(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr, _user);

        // log the event
        logger.Log(address(this), msg.sender, "ExchangeBuy", abi.encode(wrapper, exData.srcAddr, exData.destAddr, srcAmount, exData.destAmount));

    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @param _token Address of the token
    /// @return feeAmount Amount in Dai owner earned on the fee
    function getFee(uint256 _amount, address _token) internal returns (uint256 feeAmount) {
        uint256 fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(msg.sender)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(msg.sender);
        }

        if (fee == 0) {
            feeAmount = 0;
        } else {
            address walletAddr = _feeRecipient.getFeeAddr();

            feeAmount = _amount / fee;
            if (_token == KYBER_ETH_ADDRESS) {
                payable(walletAddr).transfer(feeAmount);
            } else {
                ERC20(_token).safeTransfer(walletAddr, feeAmount);
            }
        }
    }

    /// @notice Changes the amount of gas token we burn for each call
    /// @dev Only callable by the owner
    /// @param _newBurnAmount New amount of gas tokens to be burned
    function changeBurnAmount(uint _newBurnAmount) public {
        require(owner == msg.sender);

        burnAmount = _newBurnAmount;
    }

}

pragma solidity ^0.6.0;

import "../../utils/SafeERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/IFeeRecipient.sol";
import "../../interfaces/ExchangeInterfaceV3.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";

contract KyberWrapperV3 is DSMath, ExchangeInterfaceV3, AdminAuth {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant KYBER_INTERFACE = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;

    IFeeRecipient public constant feeRecipient = IFeeRecipient(0x39C4a92Dc506300c3Ea4c67ca4CA611102ee6F2A);

    using SafeERC20 for ERC20;

    /// @notice Sells a _srcAmount of tokens at Kyber
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external override payable returns (uint) {
        ERC20 srcToken = ERC20(_srcAddr);
        ERC20 destToken = ERC20(_destAddr);

        address walletAddr = feeRecipient.getFeeAddr();

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcToken.safeApprove(address(kyberNetworkProxy), _srcAmount);
        }

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            _srcAmount,
            destToken,
            msg.sender,
            uint(-1),
            0,
            walletAddr
        );

        return destAmount;
    }

    /// @notice Buys a _destAmount of tokens at Kyber
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) external override payable returns(uint) {
        ERC20 srcToken = ERC20(_srcAddr);
        ERC20 destToken = ERC20(_destAddr);

        address walletAddr = feeRecipient.getFeeAddr();

        uint srcAmount = 0;
        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcAmount = srcToken.balanceOf(address(this));
        } else {
            srcAmount = msg.value;
        }

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcToken.safeApprove(address(kyberNetworkProxy), srcAmount);
        }

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            srcAmount,
            destToken,
            msg.sender,
            _destAmount,
            0,
            walletAddr
        );

        require(destAmount == _destAmount, "Wrong dest amount");

        uint srcAmountAfter = 0;

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcAmountAfter = srcToken.balanceOf(address(this));
        } else {
            srcAmountAfter = address(this).balance;
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return (srcAmount - srcAmountAfter);
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return rate Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) public override view returns (uint rate) {
        (rate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE)
            .getExpectedRate(ERC20(_srcAddr), ERC20(_destAddr), _srcAmount);

        // multiply with decimal difference in src token
        rate = rate * (10**(18 - getDecimals(_srcAddr)));
        // divide with decimal difference in dest token
        rate = rate / (10**(18 - getDecimals(_destAddr)));
    }

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return rate Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) public override view returns (uint rate) {
        uint256 srcRate = getSellRate(_destAddr, _srcAddr, _destAmount, _additionalData);
        uint256 srcAmount = wmul(srcRate, _destAmount);

        rate = getSellRate(_srcAddr, _destAddr, srcAmount, _additionalData);

        // increase rate by 3% too account for inaccuracy between sell/buy conversion
        rate = rate + (rate / 30);
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    receive() payable external {}

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }
}

pragma solidity ^0.6.0;

import "./ERC20.sol";

abstract contract KyberNetworkProxyInterface {
    function maxGasPrice() external virtual view returns (uint256);

    function getUserCapInWei(address user) external virtual view returns (uint256);

    function getUserCapInTokenWei(address user, ERC20 token) external virtual view returns (uint256);

    function enabled() external virtual view returns (bool);

    function info(bytes32 id) external virtual view returns (uint256);

    function getExpectedRate(ERC20 src, ERC20 dest, uint256 srcQty)
        public virtual
        view
        returns (uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes memory hint
    ) public virtual payable returns (uint256);

    function trade(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId
    ) public virtual payable returns (uint256);

    function swapEtherToToken(ERC20 token, uint256 minConversionRate)
        external virtual
        payable
        returns (uint256);

    function swapTokenToEther(ERC20 token, uint256 tokenQty, uint256 minRate)
        external virtual
        payable
        returns (uint256);

    function swapTokenToToken(ERC20 src, uint256 srcAmount, ERC20 dest, uint256 minConversionRate)
        public virtual
        returns (uint256);
}

pragma solidity ^0.6.0;

import "../../utils/SafeERC20.sol";
import "../../interfaces/ExchangeInterfaceV3.sol";
import "../../interfaces/UniswapRouterInterface.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";

/// @title DFS exchange wrapper for UniswapV2
contract UniswapWrapperV3 is DSMath, ExchangeInterfaceV3, AdminAuth {

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    UniswapRouterInterface public constant router = UniswapRouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    using SafeERC20 for ERC20;

    /// @notice Sells a _srcAmount of tokens at UniswapV2
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external payable override returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        uint[] memory amounts;
        address[] memory path = abi.decode(_additionalData, (address[]));

        ERC20(_srcAddr).safeApprove(address(router), _srcAmount);

        // if we are buying ether
        if (_destAddr == WETH_ADDRESS) {
            amounts = router.swapExactTokensForETH(_srcAmount, 1, path, msg.sender, block.timestamp + 1);
        }
        // if we are selling token to token
        else {
            amounts = router.swapExactTokensForTokens(_srcAmount, 1, path, msg.sender, block.timestamp + 1);
        }

        return amounts[amounts.length - 1];
    }

    /// @notice Buys a _destAmount of tokens at UniswapV2
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) external override payable returns(uint) {

        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        uint[] memory amounts;
        address[] memory path = abi.decode(_additionalData, (address[]));

        ERC20(_srcAddr).safeApprove(address(router), uint(-1));


         // if we are buying ether
        if (_destAddr == WETH_ADDRESS) {
            amounts = router.swapTokensForExactETH(_destAmount, uint(-1), path, msg.sender, block.timestamp + 1);
        }
        // if we are buying token to token
        else {
            amounts = router.swapTokensForExactTokens(_destAmount, uint(-1), path, msg.sender, block.timestamp + 1);
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return amounts[0];
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) public override view returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        address[] memory path = abi.decode(_additionalData, (address[]));

        uint[] memory amounts = router.getAmountsOut(_srcAmount, path);
        return wdiv(amounts[amounts.length - 1], _srcAmount);
    }

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) public override view returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        address[] memory path = abi.decode(_additionalData, (address[]));

        uint[] memory amounts = router.getAmountsIn(_destAmount, path);
        return wdiv(_destAmount, amounts[0]);
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    receive() payable external {}
}

pragma solidity ^0.6.0;

abstract contract UniswapRouterInterface {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
    ) external virtual returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external virtual
    returns (uint[] memory amounts);

    function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
    ) external virtual returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) public virtual view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path) public virtual view returns (uint[] memory amounts);
}

pragma solidity ^0.6.0;

import "../../utils/SafeERC20.sol";
import "../../interfaces/ExchangeInterfaceV2.sol";
import "../../interfaces/UniswapRouterInterface.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";

/// @title DFS exchange wrapper for UniswapV2
contract UniswapV2Wrapper is DSMath, ExchangeInterfaceV2, AdminAuth {

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    UniswapRouterInterface public constant router = UniswapRouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    using SafeERC20 for ERC20;

    /// @notice Sells a _srcAmount of tokens at UniswapV2
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable override returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        uint[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = _srcAddr;
        path[1] = _destAddr;

        ERC20(_srcAddr).safeApprove(address(router), _srcAmount);

        // if we are buying ether
        if (_destAddr == WETH_ADDRESS) {
            amounts = router.swapExactTokensForETH(_srcAmount, 1, path, msg.sender, block.timestamp + 1);
        }
        // if we are selling token to token
        else {
            amounts = router.swapExactTokensForTokens(_srcAmount, 1, path, msg.sender, block.timestamp + 1);
        }

        return amounts[amounts.length - 1];
    }

    /// @notice Buys a _destAmount of tokens at UniswapV2
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external override payable returns(uint) {

        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        uint[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = _srcAddr;
        path[1] = _destAddr;

        ERC20(_srcAddr).safeApprove(address(router), uint(-1));


         // if we are buying ether
        if (_destAddr == WETH_ADDRESS) {
            amounts = router.swapTokensForExactETH(_destAmount, uint(-1), path, msg.sender, block.timestamp + 1);
        }
        // if we are buying token to token
        else {
            amounts = router.swapTokensForExactTokens(_destAmount, uint(-1), path, msg.sender, block.timestamp + 1);
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return amounts[0];
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public override view returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        address[] memory path = new address[](2);
        path[0] = _srcAddr;
        path[1] = _destAddr;

        uint[] memory amounts = router.getAmountsOut(_srcAmount, path);
        return wdiv(amounts[amounts.length - 1], _srcAmount);
    }

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public override view returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        address[] memory path = new address[](2);
        path[0] = _srcAddr;
        path[1] = _destAddr;

        uint[] memory amounts = router.getAmountsIn(_destAmount, path);
        return wdiv(_destAmount, amounts[0]);
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    receive() payable external {}
}

pragma solidity ^0.6.0;

import "../../utils/SafeERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterfaceV2.sol";
import "../../interfaces/UniswapExchangeInterface.sol";
import "../../interfaces/UniswapFactoryInterface.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";

contract UniswapWrapper is DSMath, ExchangeInterfaceV2, AdminAuth {

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant UNISWAP_FACTORY = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;

    using SafeERC20 for ERC20;

    /// @notice Sells a _srcAmount of tokens at Uniswap
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable override returns (uint) {
        address uniswapExchangeAddr;
        uint destAmount;

        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        // if we are buying ether
        if (_destAddr == WETH_ADDRESS) {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).safeApprove(uniswapExchangeAddr, _srcAmount);

            destAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToEthTransferInput(_srcAmount, 1, block.timestamp + 1, msg.sender);
        }
        // if we are selling token to token
        else {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).safeApprove(uniswapExchangeAddr, _srcAmount);

            destAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToTokenTransferInput(_srcAmount, 1, 1, block.timestamp + 1, msg.sender, _destAddr);
        }

        return destAmount;
    }

    /// @notice Buys a _destAmount of tokens at Uniswap
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external override payable returns(uint) {
        address uniswapExchangeAddr;
        uint srcAmount;

        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

         // if we are buying ether
        if (_destAddr == WETH_ADDRESS) {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).safeApprove(uniswapExchangeAddr, uint(-1));

            srcAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToEthTransferOutput(_destAmount, uint(-1), block.timestamp + 1, msg.sender);
        }
        // if we are buying token to token
        else {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).safeApprove(uniswapExchangeAddr, uint(-1));

            srcAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToTokenTransferOutput(_destAmount, uint(-1), uint(-1), block.timestamp + 1, msg.sender, _destAddr);
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return srcAmount;
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public override view returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        if(_srcAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr);
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getEthToTokenInputPrice(_srcAmount), _srcAmount);
        } else if (_destAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getTokenToEthInputPrice(_srcAmount), _srcAmount);
        } else {
            uint ethBought = UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr)).getTokenToEthInputPrice(_srcAmount);
            return wdiv(UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr)).getEthToTokenInputPrice(ethBought), _srcAmount);
        }
    }

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public override view returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        if(_srcAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr);
            return wdiv(1 ether, wdiv(UniswapExchangeInterface(uniswapTokenAddress).getEthToTokenOutputPrice(_destAmount), _destAmount));
        } else if (_destAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);
            return wdiv(1 ether, wdiv(UniswapExchangeInterface(uniswapTokenAddress).getTokenToEthOutputPrice(_destAmount), _destAmount));
        } else {
            uint ethNeeded = UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr)).getTokenToEthOutputPrice(_destAmount);
            return wdiv(1 ether, wdiv(UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr)).getEthToTokenOutputPrice(ethNeeded), _destAmount));
        }
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }

    receive() payable external {}
}

pragma solidity ^0.6.0;

abstract contract UniswapExchangeInterface {
    function getEthToTokenInputPrice(uint256 eth_sold)
        external virtual
        view
        returns (uint256 tokens_bought);

    function getEthToTokenOutputPrice(uint256 tokens_bought)
        external virtual
        view
        returns (uint256 eth_sold);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external virtual
        view
        returns (uint256 eth_bought);

    function getTokenToEthOutputPrice(uint256 eth_bought)
        external virtual
        view
        returns (uint256 tokens_sold);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external virtual returns (uint256 eth_bought);

    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient)
        external virtual
        payable
        returns (uint256 tokens_bought);

    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external virtual returns (uint256 tokens_bought);

    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external virtual payable returns (uint256  eth_sold);

    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external virtual returns (uint256  tokens_sold);

    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external virtual returns (uint256  tokens_sold);

}

pragma solidity ^0.6.0;

abstract contract UniswapFactoryInterface {
    function getExchange(address token) external view virtual returns (address exchange);
}

pragma solidity ^0.6.0;

import "../../utils/SafeERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterfaceV2.sol";
import "../../interfaces/IFeeRecipient.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";

contract KyberWrapper is DSMath, ExchangeInterfaceV2, AdminAuth {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant KYBER_INTERFACE = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;

    IFeeRecipient public constant feeRecipient = IFeeRecipient(0x39C4a92Dc506300c3Ea4c67ca4CA611102ee6F2A);

    using SafeERC20 for ERC20;

    /// @notice Sells a _srcAmount of tokens at Kyber
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external override payable returns (uint) {
        ERC20 srcToken = ERC20(_srcAddr);
        ERC20 destToken = ERC20(_destAddr);

        address walletAddr = feeRecipient.getFeeAddr();

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcToken.safeApprove(address(kyberNetworkProxy), _srcAmount);
        }

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            _srcAmount,
            destToken,
            msg.sender,
            uint(-1),
            0,
            walletAddr
        );

        return destAmount;
    }

    /// @notice Buys a _destAmount of tokens at Kyber
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external override payable returns(uint) {
        ERC20 srcToken = ERC20(_srcAddr);
        ERC20 destToken = ERC20(_destAddr);

        address walletAddr = feeRecipient.getFeeAddr();

        uint srcAmount = 0;
        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcAmount = srcToken.balanceOf(address(this));
        } else {
            srcAmount = msg.value;
        }

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcToken.safeApprove(address(kyberNetworkProxy), srcAmount);
        }

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            srcAmount,
            destToken,
            msg.sender,
            _destAmount,
            0,
            walletAddr
        );

        require(destAmount == _destAmount, "Wrong dest amount");

        uint srcAmountAfter = 0;

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcAmountAfter = srcToken.balanceOf(address(this));
        } else {
            srcAmountAfter = address(this).balance;
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return (srcAmount - srcAmountAfter);
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return rate Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public override view returns (uint rate) {
        (rate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE)
            .getExpectedRate(ERC20(_srcAddr), ERC20(_destAddr), _srcAmount);

        // multiply with decimal difference in src token
        rate = rate * (10**(18 - getDecimals(_srcAddr)));
        // divide with decimal difference in dest token
        rate = rate / (10**(18 - getDecimals(_destAddr)));
    }

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return rate Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public override view returns (uint rate) {
        uint256 srcRate = getSellRate(_destAddr, _srcAddr, _destAmount);
        uint256 srcAmount = wmul(srcRate, _destAmount);

        rate = getSellRate(_srcAddr, _destAddr, srcAmount);

        // increase rate by 3% too account for inaccuracy between sell/buy conversion
        rate = rate + (rate / 30);
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    receive() payable external {}

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/ExchangeInterfaceV2.sol";
import "../../interfaces/OasisInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSMath.sol";
import "../../utils/SafeERC20.sol";
import "../../auth/AdminAuth.sol";

contract OasisTradeWrapper is DSMath, ExchangeInterfaceV2, AdminAuth {

    using SafeERC20 for ERC20;

    address public constant OTC_ADDRESS = 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Sells a _srcAmount of tokens at Oasis
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external override payable returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        ERC20(srcAddr).safeApprove(OTC_ADDRESS, _srcAmount);

        uint destAmount = OasisInterface(OTC_ADDRESS).sellAllAmount(srcAddr, _srcAmount, destAddr, 0);

        // convert weth -> eth and send back
        if (destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(destAmount);
            msg.sender.transfer(destAmount);
        } else {
            ERC20(destAddr).safeTransfer(msg.sender, destAmount);
        }

        return destAmount;
    }

    /// @notice Buys a _destAmount of tokens at Oasis
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external override payable returns(uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        ERC20(srcAddr).safeApprove(OTC_ADDRESS, uint(-1));

        uint srcAmount = OasisInterface(OTC_ADDRESS).buyAllAmount(destAddr, _destAmount, srcAddr, uint(-1));

        // convert weth -> eth and send back
        if (destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(_destAmount);
            msg.sender.transfer(_destAmount);
        } else {
            ERC20(destAddr).safeTransfer(msg.sender, _destAmount);
        }

        // Send the leftover from the source token back
        sendLeftOver(srcAddr);

        return srcAmount;
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public override view returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        return wdiv(OasisInterface(OTC_ADDRESS).getBuyAmount(destAddr, srcAddr, _srcAmount), _srcAmount);
    }


    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public override view returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        return wdiv(1 ether, wdiv(OasisInterface(OTC_ADDRESS).getPayAmount(srcAddr, destAddr, _destAmount), _destAmount));
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
     function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }


    receive() payable external {}
}

pragma solidity ^0.6.0;

import "../DS/DSMath.sol";
import "../interfaces/TokenInterface.sol";
import "../interfaces/ExchangeInterfaceV2.sol";
import "./SaverExchangeHelper.sol";

contract Prices is DSMath {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    enum ActionType { SELL, BUY }


    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @param _type Type of action SELL|BUY
    /// @param _wrappers Array of wrapper addresses to compare
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        ActionType _type,
        address[] memory _wrappers
    ) public returns (address, uint256) {

        uint256[] memory rates = new uint256[](_wrappers.length);
        for (uint i=0; i<_wrappers.length; i++) {
            rates[i] = getExpectedRate(_wrappers[i], _srcToken, _destToken, _amount, _type);
        }

        return getBiggestRate(_wrappers, rates);
    }

    /// @notice Return the expected rate from the exchange wrapper
    /// @dev In case of Oasis/Uniswap handles the different precision tokens
    /// @param _wrapper Address of exchange wrapper
    /// @param _srcToken From token
    /// @param _destToken To token
    /// @param _amount Amount to be exchanged
    /// @param _type Type of action SELL|BUY
    function getExpectedRate(
        address _wrapper,
        address _srcToken,
        address _destToken,
        uint256 _amount,
        ActionType _type
    ) public returns (uint256) {
        bool success;
        bytes memory result;

        if (_type == ActionType.SELL) {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getSellRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            ));

        } else {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getBuyRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            ));
        }

        if (success) {
            return sliceUint(result, 0);
        }

        return 0;
    }

    /// @notice Finds the biggest rate between exchanges, needed for sell rate
    /// @param _wrappers Array of wrappers to compare
    /// @param _rates Array of rates to compare
    function getBiggestRate(
        address[] memory _wrappers,
        uint256[] memory _rates
    ) internal pure returns (address, uint) {
        uint256 maxIndex = 0;

        // starting from 0 in case there is only one rate in array
        for (uint256 i=0; i<_rates.length; i++) {
            if (_rates[i] > _rates[maxIndex]) {
                maxIndex = i;
            }
        }

        return (_wrappers[maxIndex], _rates[maxIndex]);
    }

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../DS/DSMath.sol";
import "../interfaces/TokenInterface.sol";
import "../interfaces/ExchangeInterfaceV3.sol";
import "../utils/SafeERC20.sol";

contract DFSPrices is DSMath {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    enum ActionType { SELL, BUY }


    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @param _type Type of action SELL|BUY
    /// @param _wrappers Array of wrapper addresses to compare
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        ActionType _type,
        address[] memory _wrappers,
        bytes[] memory _additionalData
    ) public returns (address, uint256) {

        uint256[] memory rates = new uint256[](_wrappers.length);
        for (uint i=0; i<_wrappers.length; i++) {
            rates[i] = getExpectedRate(_wrappers[i], _srcToken, _destToken, _amount, _type, _additionalData[i]);
        }

        return getBiggestRate(_wrappers, rates);
    }

    /// @notice Return the expected rate from the exchange wrapper
    /// @dev In case of Oasis/Uniswap handles the different precision tokens
    /// @param _wrapper Address of exchange wrapper
    /// @param _srcToken From token
    /// @param _destToken To token
    /// @param _amount Amount to be exchanged
    /// @param _type Type of action SELL|BUY
    function getExpectedRate(
        address _wrapper,
        address _srcToken,
        address _destToken,
        uint256 _amount,
        ActionType _type,
        bytes memory _additionalData
    ) public returns (uint256) {
        bool success;
        bytes memory result;

        if (_type == ActionType.SELL) {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getSellRate(address,address,uint256,bytes)",
                _srcToken,
                _destToken,
                _amount,
                _additionalData
            ));

        } else {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getBuyRate(address,address,uint256,bytes)",
                _srcToken,
                _destToken,
                _amount,
                _additionalData
            ));
        }

        if (success) {
            return sliceUint(result, 0);
        }

        return 0;
    }

    /// @notice Finds the biggest rate between exchanges, needed for sell rate
    /// @param _wrappers Array of wrappers to compare
    /// @param _rates Array of rates to compare
    function getBiggestRate(
        address[] memory _wrappers,
        uint256[] memory _rates
    ) internal pure returns (address, uint) {
        uint256 maxIndex = 0;

        // starting from 0 in case there is only one rate in array
        for (uint256 i=0; i<_rates.length; i++) {
            if (_rates[i] > _rates[maxIndex]) {
                maxIndex = i;
            }
        }

        return (_wrappers[maxIndex], _rates[maxIndex]);
    }

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../DFSExchangeHelper.sol";
import "../../interfaces/OffchainWrapperInterface.sol";
import "../../interfaces/TokenInterface.sol";

contract ZeroxWrapper is OffchainWrapperInterface, DFSExchangeHelper, AdminAuth, DSMath {
    string public constant ERR_SRC_AMOUNT = "Not enough funds";
    string public constant ERR_PROTOCOL_FEE = "Not enough eth for protcol fee";
    string public constant ERR_TOKENS_SWAPED_ZERO = "Order success but amount 0";

    using SafeERC20 for ERC20;

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _type Action type (buy or sell)
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) override public payable returns (bool success, uint256) {
        // check that contract have enough balance for exchange and protocol fee
        require(getBalance(_exData.srcAddr) >= _exData.srcAmount, ERR_SRC_AMOUNT);
        require(getBalance(KYBER_ETH_ADDRESS) >= _exData.offchainData.protocolFee, ERR_PROTOCOL_FEE);

        /// @dev 0x always uses max approve in v1, so we approve the exact amount we want to sell
        /// @dev safeApprove is modified to always first set approval to 0, then to exact amount
        if (_type == ActionType.SELL) {
            ERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, _exData.srcAmount);
        } else {
            uint srcAmount = wdiv(_exData.destAmount, _exData.offchainData.price) + 1; // + 1 so we round up
            ERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, srcAmount);
        }
        // we know that it will be eth if dest addr is either weth or eth
        address destAddr = _exData.destAddr == KYBER_ETH_ADDRESS ? EXCHANGE_WETH_ADDRESS : _exData.destAddr;

        uint256 tokensBefore = getBalance(destAddr);
        (success, ) = _exData.offchainData.exchangeAddr.call{value: _exData.offchainData.protocolFee}(_exData.offchainData.callData);
        uint256 tokensSwaped = 0;

        if (success) {
            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(destAddr) - tokensBefore;
            require(tokensSwaped > 0, ERR_TOKENS_SWAPED_ZERO);
        }

        // returns all funds from src addr, dest addr and eth funds (protocol fee leftovers)
        sendLeftover(_exData.srcAddr, destAddr, msg.sender);

        return (success, tokensSwaped);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../DFSExchangeHelper.sol";
import "../../interfaces/OffchainWrapperInterface.sol";
import "../../interfaces/TokenInterface.sol";

contract ScpWrapper is OffchainWrapperInterface, DFSExchangeHelper, AdminAuth, DSMath {

    string public constant ERR_SRC_AMOUNT = "Not enough funds";
    string public constant ERR_PROTOCOL_FEE = "Not enough eth for protcol fee";
    string public constant ERR_TOKENS_SWAPED_ZERO = "Order success but amount 0";

    using SafeERC20 for ERC20;

    /// @notice Takes order from Scp and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _type Action type (buy or sell)
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) override public payable returns (bool success, uint256) {
        // check that contract have enough balance for exchange and protocol fee
        require(getBalance(_exData.srcAddr) >= _exData.srcAmount, ERR_SRC_AMOUNT);
        require(getBalance(KYBER_ETH_ADDRESS) >= _exData.offchainData.protocolFee, ERR_PROTOCOL_FEE);

        ERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, _exData.srcAmount);

        // write in the exact amount we are selling/buing in an order
        if (_type == ActionType.SELL) {
            writeUint256(_exData.offchainData.callData, 36, _exData.srcAmount);
        } else {
            uint srcAmount = wdiv(_exData.destAmount, _exData.offchainData.price) + 1; // + 1 so we round up
            writeUint256(_exData.offchainData.callData, 36, srcAmount);
        }

        // we know that it will be eth if dest addr is either weth or eth
        address destAddr = _exData.destAddr == KYBER_ETH_ADDRESS ? EXCHANGE_WETH_ADDRESS : _exData.destAddr;

        uint256 tokensBefore = getBalance(destAddr);
        (success, ) = _exData.offchainData.exchangeAddr.call{value: _exData.offchainData.protocolFee}(_exData.offchainData.callData);
        uint256 tokensSwaped = 0;


        if (success) {
            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(destAddr) - tokensBefore;
            require(tokensSwaped > 0, ERR_TOKENS_SWAPED_ZERO);
        }

        // returns all funds from src addr, dest addr and eth funds (protocol fee leftovers)
        sendLeftover(_exData.srcAddr, destAddr, msg.sender);

        return (success, tokensSwaped);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}

pragma solidity ^0.6.0;

import "../DS/DSMath.sol";
import "../DS/DSProxy.sol";
import "../utils/Discount.sol";
import "../interfaces/IFeeRecipient.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";
import "../interfaces/IPriceOracleGetterAave.sol";

import "../utils/SafeERC20.sol";
import "../utils/BotRegistry.sol";

contract AaveHelper is DSMath {

    using SafeERC20 for ERC20;

    IFeeRecipient public constant feeRecipient = IFeeRecipient(0x39C4a92Dc506300c3Ea4c67ca4CA611102ee6F2A);

    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

	address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AAVE_LENDING_POOL_ADDRESSES = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
    uint public constant NINETY_NINE_PERCENT_WEI = 990000000000000000;
    uint16 public constant AAVE_REFERRAL_CODE = 64;

    /// @param _collateralAddress underlying token address
    /// @param _user users address
	function getMaxCollateral(address _collateralAddress, address _user) public view returns (uint256) {
        address lendingPoolAddressDataProvider = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolDataProvider();
        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        uint256 pow10 = 10 ** (18 - _getDecimals(_collateralAddress));

        // fetch all needed data
        (,uint256 totalCollateralETH, uint256 totalBorrowsETH,,uint256 currentLTV,,,) = ILendingPool(lendingPoolAddressDataProvider).calculateUserGlobalData(_user);
        (,uint256 tokenLTV,,) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_collateralAddress);
        uint256 collateralPrice = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_collateralAddress);
        uint256 userTokenBalance = ILendingPool(lendingPoolCoreAddress).getUserUnderlyingAssetBalance(_collateralAddress, _user);
        uint256 userTokenBalanceEth = wmul(userTokenBalance * pow10, collateralPrice);

		// if borrow is 0, return whole user balance
        if (totalBorrowsETH == 0) {
        	return userTokenBalance;
        }

        uint256 maxCollateralEth = div(sub(mul(currentLTV, totalCollateralETH), mul(totalBorrowsETH, 100)), currentLTV);
		/// @dev final amount can't be higher than users token balance
        maxCollateralEth = maxCollateralEth > userTokenBalanceEth ? userTokenBalanceEth : maxCollateralEth;

        // might happen due to wmul precision
        if (maxCollateralEth >= totalCollateralETH) {
        	return wdiv(totalCollateralETH, collateralPrice) / pow10;
        }

        // get sum of all other reserves multiplied with their liquidation thresholds by reversing formula
        uint256 a = sub(wmul(currentLTV, totalCollateralETH), wmul(tokenLTV, userTokenBalanceEth));
        // add new collateral amount multiplied by its threshold, and then divide with new total collateral
        uint256 newLiquidationThreshold = wdiv(add(a, wmul(sub(userTokenBalanceEth, maxCollateralEth), tokenLTV)), sub(totalCollateralETH, maxCollateralEth));

        // if new threshold is lower than first one, calculate new max collateral with newLiquidationThreshold
        if (newLiquidationThreshold < currentLTV) {
        	maxCollateralEth = div(sub(mul(newLiquidationThreshold, totalCollateralETH), mul(totalBorrowsETH, 100)), newLiquidationThreshold);
        	maxCollateralEth = maxCollateralEth > userTokenBalanceEth ? userTokenBalanceEth : maxCollateralEth;
        }

		return wmul(wdiv(maxCollateralEth, collateralPrice) / pow10, NINETY_NINE_PERCENT_WEI);
	}

	/// @param _borrowAddress underlying token address
	/// @param _user users address
	function getMaxBorrow(address _borrowAddress, address _user) public view returns (uint256) {
		address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
		address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

		(,,,,uint256 availableBorrowsETH,,,) = ILendingPool(lendingPoolAddress).getUserAccountData(_user);

		uint256 borrowPrice = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_borrowAddress);

		return wmul(wdiv(availableBorrowsETH, borrowPrice) / (10 ** (18 - _getDecimals(_borrowAddress))), NINETY_NINE_PERCENT_WEI);
	}

    function getMaxBoost(address _borrowAddress, address _collateralAddress, address _user) public view returns (uint256) {
        address lendingPoolAddressDataProvider = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolDataProvider();
        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        (,uint256 totalCollateralETH, uint256 totalBorrowsETH,,uint256 currentLTV,,,) = ILendingPool(lendingPoolAddressDataProvider).calculateUserGlobalData(_user);
        (,uint256 tokenLTV,,) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_collateralAddress);
        totalCollateralETH = div(mul(totalCollateralETH, currentLTV), 100);

        uint256 availableBorrowsETH = wmul(mul(div(sub(totalCollateralETH, totalBorrowsETH), sub(100, tokenLTV)), 100), NINETY_NINE_PERCENT_WEI);
        uint256 borrowPrice = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_borrowAddress);

        return wdiv(availableBorrowsETH, borrowPrice) / (10 ** (18 - _getDecimals(_borrowAddress)));
    }

    /// @notice Calculates the fee amount
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _tokenAddr token addr. of token we are getting for the fee
    /// @return feeAmount The amount we took for the fee
    function getFee(uint _amount, address _user, uint _gasCost, address _tokenAddr) internal returns (uint feeAmount) {
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        uint fee = MANUAL_SERVICE_FEE;

        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            fee = AUTOMATIC_SERVICE_FEE;
        }

        if (Discount(DISCOUNT_ADDR).isCustomFeeSet(_user)) {
            fee = Discount(DISCOUNT_ADDR).getCustomServiceFee(_user);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        if (_gasCost != 0) {
            uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddr);

            _gasCost = wdiv(_gasCost, price) / (10 ** (18 - _getDecimals(_tokenAddr)));

            feeAmount = add(feeAmount, _gasCost);
        }

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        address walletAddr = feeRecipient.getFeeAddr();

        if (_tokenAddr == ETH_ADDR) {
            payable(walletAddr).transfer(feeAmount);
        } else {
            ERC20(_tokenAddr).safeTransfer(walletAddr, feeAmount);
        }
    }

    /// @notice Calculates the gas cost for transaction
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _tokenAddr token addr. of token we are getting for the fee
    /// @return gasCost The amount we took for the gas cost
    function getGasCost(uint _amount, address _user, uint _gasCost, address _tokenAddr) internal returns (uint gasCost) {

        if (_gasCost == 0) return 0;

        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();
        uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddr);

        _gasCost = wmul(_gasCost, price);
        gasCost = _gasCost;

        // fee can't go over 20% of the whole amount
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
    function sendContractBalance(address _token, address _user, uint _amount) public {
        if (_amount == 0) return;

        if (_token == ETH_ADDR) {
            payable(_user).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(_user, _amount);
        }
    }

    function sendFullContractBalance(address _token, address _user) public {
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

    function isAutomation() internal view returns(bool) {
        return BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../savings/dydx/ISoloMargin.sol";
import "../../utils/SafeERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSProxy.sol";
import "../AaveHelper.sol";
import "../../auth/AdminAuth.sol";
import "../../exchangeV3/DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiver is AaveHelper, AdminAuth, DFSExchangeData {

    using SafeERC20 for ERC20;

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant AAVE_SAVER_PROXY = 0x2a3B273695A045EC263970e3C86c23800a0F04FC;
    address public constant AAVE_BASIC_PROXY = 0xd042D4E9B4186c545648c7FfFe87125c976D110B;
    address public constant AETH_ADDRESS = 0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {

        (
            bytes memory exchangeDataBytes,
            uint256 gasCost,
            bool isRepay,
            uint256 ethAmount,
            uint256 txValue,
            address user,
            address proxy
        )
        = abi.decode(data, (bytes,uint256,bool,uint256,uint256,address,address));

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        
        // deposit eth on behalf of proxy
        DSProxy(payable(proxy)).execute{value: ethAmount}(AAVE_BASIC_PROXY, abi.encodeWithSignature("deposit(address,uint256)", ETH_ADDR, ethAmount));
        
        bytes memory functionData = packFunctionCall(exchangeDataBytes, gasCost, isRepay);
        DSProxy(payable(proxy)).execute{value: txValue}(AAVE_SAVER_PROXY, functionData);

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256,bool)", ETH_ADDR, AETH_ADDRESS, ethAmount, false));

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    function packFunctionCall(bytes memory _exchangeDataBytes, uint256 _gasCost, bool _isRepay) internal returns (bytes memory) {
        ExchangeData memory exData = unpackExchangeData(_exchangeDataBytes);

        bytes memory functionData;

        if (_isRepay) {
            functionData = abi.encodeWithSignature("repay((address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256)", exData, _gasCost);
        } else {
            functionData = abi.encodeWithSignature("boost((address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256)", exData, _gasCost);
        }

        return functionData;
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth 
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../DS/DSMath.sol";
import "../interfaces/reflexer/IGetSafes.sol";
import "../interfaces/reflexer/ISAFEEngine.sol";
import "../interfaces/reflexer/ISAFEManager.sol";
import "../interfaces/reflexer/IOracleRelayer.sol";
import "../interfaces/reflexer/IMedianOracle.sol";
import "../interfaces/reflexer/ITaxCollector.sol";

contract RaiLoanInfo is DSMath {
    // mainnet
    address public constant GET_SAFES_ADDR = 0xdf4BC9aA98cC8eCd90Ba2BEe73aD4a1a9C8d202B;
    address public constant MANAGER_ADDR = 0xEfe0B4cA532769a3AE758fD82E1426a03A94F185;
    address public constant SAFE_ENGINE_ADDRESS = 0xCC88a9d330da1133Df3A7bD823B95e52511A6962;
    address public constant ORACLE_RELAYER_ADDRESS = 0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851;
    address public constant MEDIAN_ORACLE_ADDRESS = 0x12A5E1c81B10B264A575930aEae80681DDF595fe;
    address public constant TAX_COLLECTOR_ADDRESS = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;

    // kovan
    // address public constant GET_SAFES_ADDR = 0x702dcf4a8C3bBBd243477D5704fc45F2762D3826;
    // address public constant MANAGER_ADDR = 0x807C8eCb73d9c8203d2b1369E678098B9370F2EA;
    // address public constant SAFE_ENGINE_ADDRESS = 0x7f63fE955fFF8EA474d990f1Fc8979f2C650edbE;
    // address public constant ORACLE_RELAYER_ADDRESS = 0xE5Ae4E49bEA485B5E5172EE6b1F99243cB15225c;
    // address public constant MEDIAN_ORACLE_ADDRESS = 0x82bEAd00751EFA3286c9Dd17e4Ea2570916B3944;
    // address public constant TAX_COLLECTOR_ADDRESS = 0xc1a94C5ad9FCD79b03F79B34d8C0B0C8192fdc16;

    struct SafeInfo {
        uint256 safeId;
        uint256 coll;
        uint256 debt;
        address safeAddr;
        bytes32 collType;
    }

    struct CollInfo {
        uint256 debtCeiling;
        uint256 currDebtAmount;
        uint256 currRate;
        uint256 dust;
        uint256 safetyPrice;
        uint256 liqPrice;
        uint256 assetPrice;
        uint256 liqRatio;
        uint256 stabilityFee;
    }

    struct RaiInfo {
        uint256 redemptionPrice;
        uint256 currRaiPrice;
        uint256 redemptionRate;
    }

    function getCollateralTypeInfo(bytes32 _collType)
        public
        returns (CollInfo memory collInfo)
    {
        (
            uint256 debtAmount,
            uint256 accumulatedRates,
            uint256 safetyPrice,
            uint256 debtCeiling,
            uint256 debtFloor,
            uint256 liquidationPrice
        ) = ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        (, uint liqRatio) = IOracleRelayer(ORACLE_RELAYER_ADDRESS).collateralTypes(_collType);

        (uint stabilityFee,) = ITaxCollector(TAX_COLLECTOR_ADDRESS).collateralTypes(_collType);


        collInfo = CollInfo({
            debtCeiling: debtCeiling,
            currDebtAmount: debtAmount,
            currRate: accumulatedRates,
            dust: debtFloor,
            safetyPrice: safetyPrice,
            liqPrice: liquidationPrice,
            assetPrice: getPrice(_collType),
            liqRatio: liqRatio,
            stabilityFee: stabilityFee
        });
    }

    function getCollAndRaiInfo(bytes32 _collType)
        public
        returns (CollInfo memory collInfo, RaiInfo memory raiInfo) {
            collInfo = getCollateralTypeInfo(_collType);
            raiInfo = getRaiInfo();
        }

    function getPrice(bytes32 _collType) public returns (uint256) {
        (, uint256 safetyCRatio) =
            IOracleRelayer(ORACLE_RELAYER_ADDRESS).collateralTypes(_collType);
        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        uint256 redemptionPrice = IOracleRelayer(ORACLE_RELAYER_ADDRESS).redemptionPrice();

        return rmul(rmul(safetyPrice, redemptionPrice), safetyCRatio);
    }

    function getRaiInfo() public returns (RaiInfo memory raiInfo) {
        raiInfo = RaiInfo({
            redemptionPrice: IOracleRelayer(ORACLE_RELAYER_ADDRESS).redemptionPrice(),
            currRaiPrice: IMedianOracle(MEDIAN_ORACLE_ADDRESS).read(),
            redemptionRate: IOracleRelayer(ORACLE_RELAYER_ADDRESS).redemptionRate()
        });
    }

    function getSafeInfo(uint256 _safeId) public view returns (SafeInfo memory safeInfo) {
        address safeAddr = ISAFEManager(MANAGER_ADDR).safes(_safeId);
        bytes32 collType = ISAFEManager(MANAGER_ADDR).collateralTypes(_safeId);

        (uint256 coll, uint256 debt) = ISAFEEngine(SAFE_ENGINE_ADDRESS).safes(collType, safeAddr);

        safeInfo = SafeInfo({
            safeId: _safeId,
            coll: coll,
            debt: debt,
            safeAddr: safeAddr,
            collType: collType
        });
    }

    function getUserSafes(address _user)
        public
        view
        returns (
            uint256[] memory ids,
            address[] memory safes,
            bytes32[] memory collateralTypes
        )
    {
        return IGetSafes(GET_SAFES_ADDR).getSafesAsc(MANAGER_ADDR, _user);
    }

    function getUserSafesFullInfo(address _user) public view returns (SafeInfo[] memory safeInfos) {
        (uint256[] memory ids, , ) = getUserSafes(_user);

        safeInfos = new SafeInfo[](ids.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            safeInfos[i] = getSafeInfo(ids[i]);
        }
    }

    function getFullInfo(address _user, bytes32 _collType)
        public
        returns (
            CollInfo memory collInfo,
            RaiInfo memory raiInfo,
            SafeInfo[] memory safeInfos
        )
    {
        collInfo = getCollateralTypeInfo(_collType);
        raiInfo = getRaiInfo();
        safeInfos = getUserSafesFullInfo(_user);
    }
}

pragma solidity ^0.6.0;

abstract contract IGetSafes {
    function getSafesAsc(address manager, address guy) external virtual view returns (uint[] memory ids, address[] memory safes, bytes32[] memory collateralTypes);
    function getSafesDesc(address manager, address guy) external virtual view returns (uint[] memory ids, address[] memory safes, bytes32[] memory collateralTypes);

}

pragma solidity ^0.6.0;

abstract contract IMedianOracle {
    function read() external virtual view returns (uint256);
}

pragma solidity ^0.6.0;

import "./DSProxy.sol";

abstract contract DSProxyFactoryInterface {
    function build(address owner) public virtual returns (DSProxy proxy);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../../utils/SafeERC20.sol";
import "../../../interfaces/TokenInterface.sol";
import "../../../DS/DSProxy.sol";
import "../../AaveHelperV2.sol";
import "../../../auth/AdminAuth.sol";
import "../../../exchangeV3/DFSExchangeCore.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiverOV2 is AaveHelperV2, AdminAuth, DFSExchangeCore {

    using SafeERC20 for ERC20;

    address public constant AAVE_BASIC_PROXY = 0xc17c8eB12Ba24D62E69fd57cbd504EEf418867f9;

    function boost(ExchangeData memory _exchangeData, address _market, uint256 _gasCost, address _proxy) internal {
        (, uint swappedAmount) = _sell(_exchangeData);

        address user = DSAuth(_proxy).owner();
        swappedAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), swappedAmount, user, _gasCost, _exchangeData.destAddr);

        // if its eth we need to send it to the basic proxy, if not, we need to approve users proxy to pull tokens
        uint256 msgValue = 0;
        address token = _exchangeData.destAddr;
        // sell always return eth, but deposit differentiate eth vs weth, so we change weth address to eth when we are depoisting
        if (_exchangeData.destAddr == ETH_ADDR || _exchangeData.destAddr == WETH_ADDRESS) {
            msgValue = swappedAmount;
            token = ETH_ADDR;
        } else {
            ERC20(_exchangeData.destAddr).safeApprove(_proxy, swappedAmount);
        }
        // deposit collateral on behalf of user
        DSProxy(payable(_proxy)).execute{value: msgValue}(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "deposit(address,address,uint256)",
                _market,
                token,
                swappedAmount
                )
            );
    }

    function repay(ExchangeData memory _exchangeData, address _market, uint256 _gasCost, address _proxy, uint256 _rateMode, uint _aaveFlashlLoanFee) internal {
        // we will withdraw exactly the srcAmount, as fee we keep before selling
        uint valueToWithdraw = _exchangeData.srcAmount;
        // take out the fee wee need to pay and sell the rest
        _exchangeData.srcAmount = _exchangeData.srcAmount - _aaveFlashlLoanFee;

        (, uint swappedAmount) = _sell(_exchangeData);

        // set protocol fee left to eth balance of this address
        // but if destAddr is eth or weth, this also includes that value so we need to substract it
        uint protocolFeeLeft = address(this).balance;

        address user = DSAuth(_proxy).owner();
        swappedAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), swappedAmount, user, _gasCost, _exchangeData.destAddr);

        // if its eth we need to send it to the basic proxy, if not, we need to approve basic proxy to pull tokens
        uint256 msgValue = 0;
        if (_exchangeData.destAddr == ETH_ADDR || _exchangeData.destAddr == WETH_ADDRESS) {
            protocolFeeLeft -= swappedAmount;
            msgValue = swappedAmount;
        } else {
            ERC20(_exchangeData.destAddr).safeApprove(_proxy, swappedAmount);
        }

        // first payback the loan with swapped amount
        DSProxy(payable(_proxy)).execute{value: msgValue}(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "payback(address,address,uint256,uint256)",
                _market,
                _exchangeData.destAddr,
                swappedAmount,
                _rateMode
                )
            );

        // if some tokens left after payback (full repay) we need to return it back to the proxy owner
        require(user != address(0)); // be sure that we fetched the user correctly
        if (_exchangeData.destAddr == ETH_ADDR || _exchangeData.destAddr == WETH_ADDRESS) {
            // keep protocol fee for tx.origin, but the rest of the balance return to the user
            payable(user).transfer(address(this).balance - protocolFeeLeft);
        } else {
            // in case its a token, just return whole value back to the user, as protocol fee is always in eth
            uint amount = ERC20(_exchangeData.destAddr).balanceOf(address(this));
            ERC20(_exchangeData.destAddr).safeTransfer(user, amount);
        }

        // pull the amount we flash loaned in collateral to be able to payback the debt
        DSProxy(payable(_proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256)", _market, _exchangeData.srcAddr, valueToWithdraw));
    }

    function executeOperation(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) public returns (bool) {
        (
            bytes memory exchangeDataBytes,
            address market,
            uint256 gasCost,
            uint256 rateMode,
            bool isRepay,
            address proxy
        )
        = abi.decode(params, (bytes,address,uint256,uint256,bool,address));

        address lendingPool = ILendingPoolAddressesProviderV2(market).getLendingPool();

        require(msg.sender == lendingPool, "Callbacks only allowed from Aave");
        require(initiator == proxy, "initiator isn't proxy");

        ExchangeData memory exData = unpackExchangeData(exchangeDataBytes);
        exData.user = DSAuth(proxy).owner();
        exData.dfsFeeDivider = MANUAL_SERVICE_FEE;
        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            exData.dfsFeeDivider = AUTOMATIC_SERVICE_FEE;
        }

        // this is to avoid stack too deep
        uint fee = premiums[0];
        uint totalValueToReturn = exData.srcAmount + fee;

        // if its repay, we are using regular flash loan and payback the premiums
        if (isRepay) {
            repay(exData, market, gasCost, proxy, rateMode, fee);

            address token = exData.srcAddr;
            if (token == ETH_ADDR || token == WETH_ADDRESS) {
                // deposit eth, get weth and return to sender
                TokenInterface(WETH_ADDRESS).deposit.value(totalValueToReturn)();
                token = WETH_ADDRESS;
            }

            ERC20(token).safeApprove(lendingPool, totalValueToReturn);
        } else {
            boost(exData, market, gasCost, proxy);
        }

        tx.origin.transfer(address(this).balance);

        return true;
    }

    /// @dev allow contract to receive eth from sell
    receive() external override payable {}
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../savings/dydx/ISoloMargin.sol";
import "../../utils/SafeERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSProxy.sol";
import "../AaveHelperV2.sol";
import "../../auth/AdminAuth.sol";

// weth->eth
// deposit eth for users proxy
// borrow users token from proxy
// repay on behalf of user
// pull user supply
// take eth amount from supply (if needed more, borrow it?)
// return eth to sender

/// @title Import Aave position from account to wallet
contract AaveImportV2 is AaveHelperV2, AdminAuth {

    using SafeERC20 for ERC20;

    address public constant BASIC_PROXY = 0xc17c8eB12Ba24D62E69fd57cbd504EEf418867f9;
    address public constant PULL_TOKENS_PROXY = 0x45431b79F783e0BF0fe7eF32D06A3e061780bfc4;

    function callFunction(
        address,
        Account.Info memory,
        bytes memory data
    ) public {

        (
            address market,
            address collateralToken,
            address borrowToken,
            uint256 ethAmount,
            address proxy
        )
        = abi.decode(data, (address,address,address,uint256,address));

        address user = DSProxy(payable(proxy)).owner();

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(market);

        uint256 globalBorrowAmountStable = 0;
        uint256 globalBorrowAmountVariable = 0;

        { // avoid stack too deep
            // deposit eth on behalf of proxy
            DSProxy(payable(proxy)).execute{value: ethAmount}(BASIC_PROXY, abi.encodeWithSignature("deposit(address,address,uint256)", market, ETH_ADDR, ethAmount));
            // borrow needed amount to repay users borrow
            (, uint256 borrowsStable, uint256 borrowsVariable,,,,,,) = dataProvider.getUserReserveData(borrowToken, user);

            if (borrowsStable > 0) {
                DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("borrow(address,address,uint256,uint256)", market, borrowToken, borrowsStable, STABLE_ID));
                globalBorrowAmountStable = borrowsStable;
            }

            if (borrowsVariable > 0) {
                DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("borrow(address,address,uint256,uint256)", market, borrowToken, borrowsVariable, VARIABLE_ID));
                globalBorrowAmountVariable = borrowsVariable;
            }
        }

        if (globalBorrowAmountVariable > 0) {
            paybackOnBehalf(market, proxy, globalBorrowAmountVariable, borrowToken, user, VARIABLE_ID);
        }

        if (globalBorrowAmountStable > 0) {
            paybackOnBehalf(market, proxy, globalBorrowAmountStable, borrowToken, user, STABLE_ID);
        }

        (address aToken,,) = dataProvider.getReserveTokensAddresses(collateralToken);

        // pull coll tokens
        DSProxy(payable(proxy)).execute(PULL_TOKENS_PROXY, abi.encodeWithSignature("pullTokens(address,uint256)", aToken, ERC20(aToken).balanceOf(user)));

        // enable as collateral
        DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("setUserUseReserveAsCollateralIfNeeded(address,address)", market, collateralToken));

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256)", market, ETH_ADDR, ethAmount));

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit{value: (address(this).balance)}();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    function paybackOnBehalf(address _market, address _proxy, uint _amount, address _token, address _onBehalf, uint _rateMode) internal {
        // payback on behalf of user
        if (_token != ETH_ADDR) {
            ERC20(_token).safeApprove(_proxy, _amount);
            DSProxy(payable(_proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehalf(address,address,uint256,uint256,address)", _market, _token, _amount, _rateMode, _onBehalf));
        } else {
            DSProxy(payable(_proxy)).execute{value: _amount}(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehalf(address,address,uint256,uint256,address)", _market, _token, _amount, _rateMode, _onBehalf));
        }
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit{value: (address(this).balance)}();
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../savings/dydx/ISoloMargin.sol";
import "../../utils/SafeERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSProxy.sol";
import "../AaveHelper.sol";
import "../../auth/AdminAuth.sol";

// weth->eth
// deposit eth for users proxy
// borrow users token from proxy
// repay on behalf of user
// pull user supply
// take eth amount from supply (if needed more, borrow it?)
// return eth to sender

/// @title Import Aave position from account to wallet
contract AaveImport is AaveHelper, AdminAuth {

    using SafeERC20 for ERC20;

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BASIC_PROXY = 0xF499FB2feb3351aEA373723a6A0e8F6BE6fBF616;
    address public constant AETH_ADDRESS = 0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04;

    address public constant PULL_TOKENS_PROXY = 0x45431b79F783e0BF0fe7eF32D06A3e061780bfc4;

    function callFunction(
        address,
        Account.Info memory,
        bytes memory data
    ) public {

        (
            address collateralToken,
            address borrowToken,
            uint256 ethAmount,
            address proxy
        )
        = abi.decode(data, (address,address,uint256,address));

        address user = DSProxy(payable(proxy)).owner();

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        address aCollateralToken = ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(collateralToken);
        address aBorrowToken = ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(borrowToken);
        uint256 globalBorrowAmount = 0;

        { // avoid stack too deep
            // deposit eth on behalf of proxy
            DSProxy(payable(proxy)).execute{value: ethAmount}(BASIC_PROXY, abi.encodeWithSignature("deposit(address,uint256)", ETH_ADDR, ethAmount));
            // borrow needed amount to repay users borrow
            (,uint256 borrowAmount,,uint256 borrowRateMode,,,uint256 originationFee,,,) = ILendingPool(lendingPool).getUserReserveData(borrowToken, user);
            borrowAmount += originationFee;
            DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("borrow(address,uint256,uint256)", borrowToken, borrowAmount, borrowRateMode));
            globalBorrowAmount = borrowAmount;
        }

        // payback on behalf of user
        if (borrowToken != ETH_ADDR) {
            ERC20(borrowToken).safeApprove(proxy, globalBorrowAmount);
            DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehalf(address,address,uint256,bool,address)", borrowToken, aBorrowToken, 0, true, user));
        } else {
            DSProxy(payable(proxy)).execute{value: globalBorrowAmount}(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehalf(address,address,uint256,bool,address)", borrowToken, aBorrowToken, 0, true, user));
        }

         // pull coll tokens
        DSProxy(payable(proxy)).execute(PULL_TOKENS_PROXY, abi.encodeWithSignature("pullTokens(address,uint256)", aCollateralToken, ERC20(aCollateralToken).balanceOf(user)));


        // enable as collateral
        DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("setUserUseReserveAsCollateralIfNeeded(address)", collateralToken));

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256,bool)", ETH_ADDR, AETH_ADDRESS, ethAmount, false));


        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit{value: (address(this).balance)}();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit{value: (address(this).balance)}();
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../AaveHelper.sol";
import "../../exchangeV3/DFSExchangeCore.sol";
import "../../interfaces/IAToken.sol";
import "../../interfaces/ILendingPool.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../utils/GasBurner.sol";

contract AaveSaverProxy is GasBurner, DFSExchangeCore, AaveHelper {

	address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    uint public constant VARIABLE_RATE = 2;

	function repay(ExchangeData memory _data, uint _gasCost) public payable burnGas(20) {

		address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
		address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
		address payable user = payable(getUserAddress());

		// redeem collateral
		address aTokenCollateral = ILendingPool(lendingPoolCore).getReserveATokenAddress(_data.srcAddr);
		// uint256 maxCollateral = IAToken(aTokenCollateral).balanceOf(address(this));
		// don't swap more than maxCollateral
		// _data.srcAmount = _data.srcAmount > maxCollateral ? maxCollateral : _data.srcAmount;
		IAToken(aTokenCollateral).redeem(_data.srcAmount);

		uint256 destAmount = _data.srcAmount;
		if (_data.srcAddr != _data.destAddr) {
            _data.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
            _data.user = user;
			// swap
			(, destAmount) = _sell(_data);
			destAmount -= getGasCost(destAmount, user, _gasCost, _data.destAddr);
		} else {
			destAmount -= getGasCost(destAmount, user, _gasCost, _data.destAddr);
		}

		// payback
		if (_data.destAddr == ETH_ADDR) {
			ILendingPool(lendingPool).repay{value: destAmount}(_data.destAddr, destAmount, payable(address(this)));
		} else {
			approveToken(_data.destAddr, lendingPoolCore);
			ILendingPool(lendingPool).repay(_data.destAddr, destAmount, payable(address(this)));
		}

		// first return 0x fee to msg.sender as it is the address that actually sent 0x fee
		sendContractBalance(ETH_ADDR, tx.origin, min(address(this).balance, msg.value));
		// send all leftovers from dest addr to proxy owner
		sendFullContractBalance(_data.destAddr, user);

		DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveRepay", abi.encode(_data.srcAddr, _data.destAddr, _data.srcAmount, destAmount));
	}

	function boost(ExchangeData memory _data, uint _gasCost) public payable burnGas(20) {
		address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
		address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
		(,,,uint256 borrowRateMode,,,,,,bool collateralEnabled) = ILendingPool(lendingPool).getUserReserveData(_data.destAddr, address(this));
		address payable user = payable(getUserAddress());

		// skipping this check as its too expensive
		// uint256 maxBorrow = getMaxBoost(_data.srcAddr, _data.destAddr, address(this));
		// _data.srcAmount = _data.srcAmount > maxBorrow ? maxBorrow : _data.srcAmount;

		// borrow amount
		ILendingPool(lendingPool).borrow(_data.srcAddr, _data.srcAmount, borrowRateMode == 0 ? VARIABLE_RATE : borrowRateMode, AAVE_REFERRAL_CODE);

		uint256 destAmount;
		if (_data.destAddr != _data.srcAddr) {
            _data.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
            _data.user = user;

			// swap
			(, destAmount) = _sell(_data);
            destAmount -= getGasCost(_data.destAmount, user, _gasCost, _data.destAddr);

		} else {
			destAmount = _data.srcAmount;
            destAmount -= getGasCost(_data.destAmount, user, _gasCost, _data.destAddr);

		}

		if (_data.destAddr == ETH_ADDR) {
			ILendingPool(lendingPool).deposit{value: destAmount}(_data.destAddr, destAmount, AAVE_REFERRAL_CODE);
		} else {
			approveToken(_data.destAddr, lendingPoolCore);
			ILendingPool(lendingPool).deposit(_data.destAddr, destAmount, AAVE_REFERRAL_CODE);
		}

		if (!collateralEnabled) {
            ILendingPool(lendingPool).setUserUseReserveAsCollateral(_data.destAddr, true);
        }

		// returning to msg.sender as it is the address that actually sent 0x fee
		sendContractBalance(ETH_ADDR, tx.origin, min(address(this).balance, msg.value));
		// send all leftovers from dest addr to proxy owner
		sendFullContractBalance(_data.destAddr, user);

		DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveBoost", abi.encode(_data.srcAddr, _data.destAddr, _data.srcAmount, destAmount));
	}
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../AaveHelperV2.sol";
import "../../exchangeV3/DFSExchangeCore.sol";
import "../../interfaces/IAToken.sol";
import "../../interfaces/TokenInterface.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../utils/GasBurner.sol";

contract AaveSaverProxyV2 is DFSExchangeCore, AaveHelperV2, GasBurner {

	address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

	function repay(address _market, ExchangeData memory _data, uint _rateMode, uint _gasCost) public payable burnGas(20) {
		address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
		IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
		address payable user = payable(getUserAddress());

		ILendingPoolV2(lendingPool).withdraw(_data.srcAddr, _data.srcAmount, address(this));

		uint256 destAmount = _data.srcAmount;
		if (_data.srcAddr != _data.destAddr) {
			_data.user = user;
			
			_data.dfsFeeDivider = MANUAL_SERVICE_FEE;
			if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            	_data.dfsFeeDivider = AUTOMATIC_SERVICE_FEE;
        	}
			
			// swap
			(, destAmount) = _sell(_data);
		}

		// take gas cost at the end
		destAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), destAmount, user, _gasCost, _data.destAddr);

		// payback
		if (_data.destAddr == WETH_ADDRESS) {
			TokenInterface(WETH_ADDRESS).deposit.value(destAmount)();
		}

		approveToken(_data.destAddr, lendingPool);

		// if destAmount higher than borrow repay whole debt
		uint borrow;
		if (_rateMode == STABLE_ID) {
			(,borrow,,,,,,,) = dataProvider.getUserReserveData(_data.destAddr, address(this));	
		} else {
			(,,borrow,,,,,,) = dataProvider.getUserReserveData(_data.destAddr, address(this));
		}
		ILendingPoolV2(lendingPool).repay(_data.destAddr, destAmount > borrow ? borrow : destAmount, _rateMode, payable(address(this)));

		// first return 0x fee to tx.origin as it is the address that actually sent 0x fee
		sendContractBalance(ETH_ADDR, tx.origin, min(address(this).balance, msg.value));
		// send all leftovers from dest addr to proxy owner
		sendFullContractBalance(_data.destAddr, user);

		DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveV2Repay", abi.encode(_data.srcAddr, _data.destAddr, _data.srcAmount, destAmount));
	}

	function boost(address _market, ExchangeData memory _data, uint _rateMode, uint _gasCost) public payable burnGas(20) {
		address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
		IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);
		address payable user = payable(getUserAddress());

		// borrow amount
		ILendingPoolV2(lendingPool).borrow(_data.srcAddr, _data.srcAmount, _rateMode, AAVE_REFERRAL_CODE, address(this));

		// take gas cost at the beginning
		_data.srcAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), _data.srcAmount, user, _gasCost, _data.srcAddr);

		uint256 destAmount;
		if (_data.destAddr != _data.srcAddr) {
			_data.user = user;
			
			_data.dfsFeeDivider = MANUAL_SERVICE_FEE;
			if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            	_data.dfsFeeDivider = AUTOMATIC_SERVICE_FEE;
        	}
        	
			(, destAmount) = _sell(_data);
		} else {
			destAmount = _data.srcAmount;
		}

		if (_data.destAddr == WETH_ADDRESS) {
			TokenInterface(WETH_ADDRESS).deposit.value(destAmount)();
		}

		approveToken(_data.destAddr, lendingPool);
		ILendingPoolV2(lendingPool).deposit(_data.destAddr, destAmount, address(this), AAVE_REFERRAL_CODE);


		(,,,,,,,,bool collateralEnabled) = dataProvider.getUserReserveData(_data.destAddr, address(this));
		if (!collateralEnabled) {
            ILendingPoolV2(lendingPool).setUserUseReserveAsCollateral(_data.destAddr, true);
        }

		// returning to msg.sender as it is the address that actually sent 0x fee
		sendContractBalance(ETH_ADDR, tx.origin, min(address(this).balance, msg.value));
		// send all leftovers from dest addr to proxy owner
		sendFullContractBalance(_data.destAddr, user);

		DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveV2Boost", abi.encode(_data.srcAddr, _data.destAddr, _data.srcAmount, destAmount));
	}
}

pragma solidity ^0.6.0;

import "../utils/GasBurner.sol";
import "../interfaces/TokenInterface.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPoolV2.sol";
import "./AaveHelperV2.sol";

import "../utils/SafeERC20.sol";

/// @title Basic compound interactions through the DSProxy
contract AaveBasicProxyV2 is GasBurner, AaveHelperV2 {

    using SafeERC20 for ERC20;

    /// @notice User deposits tokens to the Aave protocol
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _amount Amount of tokens to be deposited
    function deposit(address _market, address _tokenAddr, uint256 _amount) public burnGas(5) payable {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        if (_tokenAddr == ETH_ADDR) {
            require(msg.value == _amount);
            TokenInterface(WETH_ADDRESS).deposit{value: _amount}();
            _tokenAddr = WETH_ADDRESS;
        } else {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
        }

        approveToken(_tokenAddr, lendingPool);
        ILendingPoolV2(lendingPool).deposit(_tokenAddr, _amount, address(this), AAVE_REFERRAL_CODE);

        setUserUseReserveAsCollateralIfNeeded(_market, _tokenAddr);
    }

    /// @notice User withdraws tokens from the Aave protocol
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn -> send -1 for whole amount
    function withdraw(address _market, address _tokenAddr, uint256 _amount) public burnGas(8) {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        if (_tokenAddr == WETH_ADDRESS) {
            // if weth, pull to proxy and return ETH to user
            ILendingPoolV2(lendingPool).withdraw(_tokenAddr, _amount, address(this));
            // needs to use balance of in case that amount is -1 for whole debt
            TokenInterface(WETH_ADDRESS).withdraw(TokenInterface(WETH_ADDRESS).balanceOf(address(this)));
            msg.sender.transfer(address(this).balance);
        } else {
            // if not eth send directly to user
            ILendingPoolV2(lendingPool).withdraw(_tokenAddr, _amount, msg.sender);
        }
    }

    /// @notice User borrows tokens to the Aave protocol
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    /// @param _type Send 1 for stable rate and 2 for variable
    function borrow(address _market, address _tokenAddr, uint256 _amount, uint256 _type) public burnGas(8) {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        ILendingPoolV2(lendingPool).borrow(_tokenAddr, _amount, _type, AAVE_REFERRAL_CODE, address(this));

        if (_tokenAddr == WETH_ADDRESS) {
            // we do this so the user gets eth instead of weth
            TokenInterface(WETH_ADDRESS).withdraw(_amount);
            _tokenAddr = ETH_ADDR;
        }

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _amount Amount of tokens to be payed back
    function payback(address _market, address _tokenAddr, uint256 _amount, uint256 _rateMode) public burnGas(3) payable {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        if (_tokenAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit{value: msg.value}();
        } else {
            uint amountToPull = min(_amount, ERC20(_tokenAddr).balanceOf(msg.sender));
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amountToPull);
        }

        approveToken(_tokenAddr, lendingPool);
        ILendingPoolV2(lendingPool).repay(_tokenAddr, _amount, _rateMode, payable(address(this)));

        if (_tokenAddr == WETH_ADDRESS) {
            // Pull if we have any eth leftover
            TokenInterface(WETH_ADDRESS).withdraw(ERC20(WETH_ADDRESS).balanceOf(address(this)));
            _tokenAddr = ETH_ADDR;
        }

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _amount Amount of tokens to be payed back
    function paybackOnBehalf(address _market, address _tokenAddr, uint256 _amount, uint256 _rateMode, address _onBehalf) public burnGas(3) payable {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        if (_tokenAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit{value: msg.value}();
        } else {
            uint amountToPull = min(_amount, ERC20(_tokenAddr).allowance(msg.sender, address(this)));
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amountToPull);
        }

        approveToken(_tokenAddr, lendingPool);
        ILendingPoolV2(lendingPool).repay(_tokenAddr, _amount, _rateMode, _onBehalf);

        if (_tokenAddr == WETH_ADDRESS) {
            // we do this so the user gets eth instead of weth
            TokenInterface(WETH_ADDRESS).withdraw(_amount);
            _tokenAddr = ETH_ADDR;
        }

        withdrawTokens(_tokenAddr);
    }


    /// @notice Helper method to withdraw tokens from the DSProxy
    /// @param _tokenAddr Address of the token to be withdrawn
    function withdrawTokens(address _tokenAddr) public {
        uint256 amount = _tokenAddr == ETH_ADDR ? address(this).balance : ERC20(_tokenAddr).balanceOf(address(this));

        if (amount > 0) {
            if (_tokenAddr != ETH_ADDR) {
                ERC20(_tokenAddr).safeTransfer(msg.sender, amount);
            } else {
                msg.sender.transfer(amount);
            }
        }
    }

    function setUserUseReserveAsCollateralIfNeeded(address _market, address _tokenAddr) public {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);

        (,,,,,,,,bool collateralEnabled) = dataProvider.getUserReserveData(_tokenAddr, address(this));

        if (!collateralEnabled) {
            ILendingPoolV2(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, true);
        }
    }

    function setUserUseReserveAsCollateral(address _market, address _tokenAddr, bool _true) public {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        ILendingPoolV2(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, _true);
    }

    // stable = 1, variable = 2
    function swapBorrowRateMode(address _market, address _reserve, uint _rateMode) public {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        ILendingPoolV2(lendingPool).swapBorrowRateMode(_reserve, _rateMode);
    }

    function changeToWeth(address _token) private view returns(address) {
        if (_token == ETH_ADDR) {
            return WETH_ADDRESS;
        }

        return _token;
    }


    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}

pragma solidity ^0.6.0;

import "./AaveHelperV2.sol";
import "../interfaces/ILendingPoolV2.sol";

contract AaveSafetyRatioV2 is AaveHelperV2 {

    function getSafetyRatio(address _market, address _user) public view returns(uint256) {
        ILendingPoolV2 lendingPool = ILendingPoolV2(ILendingPoolAddressesProviderV2(_market).getLendingPool());
        
        (,uint256 totalDebtETH,uint256 availableBorrowsETH,,,) = lendingPool.getUserAccountData(_user);

        if (totalDebtETH == 0) return uint256(0);

        return wdiv(add(totalDebtETH, availableBorrowsETH), totalDebtETH);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../exchangeV3/DFSExchangeData.sol";
import "./AaveMonitorProxyV2.sol";
import "./AaveSubscriptionsV2.sol";
import "../AaveSafetyRatioV2.sol";

/// @title Contract implements logic of calling boost/repay in the automatic system
contract AaveMonitorV2 is AdminAuth, DSMath, AaveSafetyRatioV2, GasBurner {

    using SafeERC20 for ERC20;

    string public constant NAME = "AaveMonitorV2";

    enum Method { Boost, Repay }

    uint public REPAY_GAS_TOKEN = 20;
    uint public BOOST_GAS_TOKEN = 20;

    uint public MAX_GAS_PRICE = 400000000000; // 400 gwei

    uint public REPAY_GAS_COST = 2000000;
    uint public BOOST_GAS_COST = 2000000;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant AAVE_MARKET_ADDRESS = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

    AaveMonitorProxyV2 public aaveMonitorProxy;
    AaveSubscriptionsV2 public subscriptionsContract;
    address public aaveSaverProxy;

    DefisaverLogger public logger = DefisaverLogger(DEFISAVER_LOGGER);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    /// @param _aaveMonitorProxy Proxy contracts that actually is authorized to call DSProxy
    /// @param _subscriptions Subscriptions contract for Aave positions
    /// @param _aaveSaverProxy Contract that actually performs Repay/Boost
    constructor(address _aaveMonitorProxy, address _subscriptions, address _aaveSaverProxy) public {
        aaveMonitorProxy = AaveMonitorProxyV2(_aaveMonitorProxy);
        subscriptionsContract = AaveSubscriptionsV2(_subscriptions);
        aaveSaverProxy = _aaveSaverProxy;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _exData Exchange data
    /// @param _user The actual address that owns the Aave position
    function repayFor(
        DFSExchangeData.ExchangeData memory _exData,
        address _user,
        uint256 _rateMode,
        uint256 _flAmount
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _user);
        require(isAllowed); // check if conditions are met

        uint256 gasCost = calcGasCost(REPAY_GAS_COST);

        aaveMonitorProxy.callExecute{value: msg.value}(
            _user,
            aaveSaverProxy,
            abi.encodeWithSignature(
                "repay(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256,uint256)",
                AAVE_MARKET_ADDRESS,
                _exData,
                _rateMode,
                gasCost,
                _flAmount
            )
        );

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _user);
        require(isGoodRatio); // check if the after result of the actions is good

        returnEth();

        logger.Log(address(this), _user, "AutomaticAaveRepayV2", abi.encode(ratioBefore, ratioAfter));
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _exData Exchange data
    /// @param _user The actual address that owns the Aave position
    function boostFor(
        DFSExchangeData.ExchangeData memory _exData,
        address _user,
        uint256 _rateMode,
        uint256 _flAmount
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _user);
        require(isAllowed); // check if conditions are met

        uint256 gasCost = calcGasCost(BOOST_GAS_COST);

        aaveMonitorProxy.callExecute{value: msg.value}(
            _user,
            aaveSaverProxy,
            abi.encodeWithSignature(
                "boost(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256,uint256)",
                AAVE_MARKET_ADDRESS,
                _exData,
                _rateMode,
                gasCost,
                _flAmount
            )
        );


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _user);
        require(isGoodRatio);  // check if the after result of the actions is good

        returnEth();

        logger.Log(address(this), _user, "AutomaticAaveBoostV2", abi.encode(ratioBefore, ratioAfter));
    }

/******************* INTERNAL METHODS ********************************/
    function returnEth() internal {
        // return if some eth left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

/******************* STATIC METHODS ********************************/

    /// @notice Checks if Boost/Repay could be triggered for the CDP
    /// @dev Called by AaveMonitor to enforce the min/max check
    /// @param _method Type of action to be called
    /// @param _user The actual address that owns the Aave position
    /// @return Boolean if it can be called and the ratio
    function canCall(Method _method, address _user) public view returns(bool, uint) {
        bool subscribed = subscriptionsContract.isSubscribed(_user);
        AaveSubscriptionsV2.AaveHolder memory holder = subscriptionsContract.getHolder(_user);

        // check if cdp is subscribed
        if (!subscribed) return (false, 0);

        // check if boost and boost allowed
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        uint currRatio = getSafetyRatio(AAVE_MARKET_ADDRESS, _user);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    /// @dev After the Boost/Repay check if the ratio doesn't trigger another call
    /// @param _method Type of action to be called
    /// @param _user The actual address that owns the Aave position
    /// @return Boolean if the recent action preformed correctly and the ratio
    function ratioGoodAfter(Method _method, address _user) public view returns(bool, uint) {
        AaveSubscriptionsV2.AaveHolder memory holder;

        holder = subscriptionsContract.getHolder(_user);

        uint currRatio = getSafetyRatio(AAVE_MARKET_ADDRESS, _user);

        if (_method == Method.Repay) {
            return (currRatio < holder.maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.minRatio, currRatio);
        }
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) public view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

    /// @notice As the code is new, have a emergancy admin saver proxy change
    function changeAaveSaverProxy(address _newAaveSaverProxy) public onlyAdmin {
        aaveSaverProxy = _newAaveSaverProxy;
    }

    /// @notice Allows owner to change gas cost for boost operation, but only up to 3 millions
    /// @param _gasCost New gas cost for boost method
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change gas cost for repay operation, but only up to 3 millions
    /// @param _gasCost New gas cost for repay method
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change max gas price
    /// @param _maxGasPrice New max gas price
    function changeMaxGasPrice(uint _maxGasPrice) public onlyOwner {
        require(_maxGasPrice < 500000000000);

        MAX_GAS_PRICE = _maxGasPrice;
    }

    /// @notice Allows owner to change gas token amount
    /// @param _gasTokenAmount New gas token amount
    /// @param _repay true if repay gas token, false if boost gas token
    function changeGasTokenAmount(uint _gasTokenAmount, bool _repay) public onlyOwner {
        if (_repay) {
            REPAY_GAS_TOKEN = _gasTokenAmount;
        } else {
            BOOST_GAS_TOKEN = _gasTokenAmount;
        }
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/DSProxyInterface.sol";
import "../../utils/SafeERC20.sol";
import "../../auth/AdminAuth.sol";

/// @title Contract with the actuall DSProxy permission calls the automation operations
contract AaveMonitorProxyV2 is AdminAuth {

    using SafeERC20 for ERC20;

    string public constant NAME = "AaveMonitorProxyV2";

    uint public CHANGE_PERIOD;
    address public monitor;
    address public newMonitor;
    address public lastMonitor;
    uint public changeRequestedTimestamp;

    event MonitorChangeInitiated(address oldMonitor, address newMonitor);
    event MonitorChangeCanceled();
    event MonitorChangeFinished(address monitor);
    event MonitorChangeReverted(address monitor);


    modifier onlyMonitor() {
        require (msg.sender == monitor);
        _;
    }

    constructor(uint _changePeriod) public {
        CHANGE_PERIOD = _changePeriod * 1 hours;
    }

    /// @notice Only monitor contract is able to call execute on users proxy
    /// @param _owner Address of cdp owner (users DSProxy address)
    /// @param _aaveSaverProxy Address of AaveSaverProxy
    /// @param _data Data to send to AaveSaverProxy
    function callExecute(address _owner, address _aaveSaverProxy, bytes memory _data) public payable onlyMonitor {
        // execute reverts if calling specific method fails
        DSProxyInterface(_owner).execute{value: msg.value}(_aaveSaverProxy, _data);

        // return if anything left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @notice Owner is able to set Monitor contract without any waiting period first time
    /// @param _monitor Address of Monitor contract
    function setMonitor(address _monitor) public onlyOwner {
        require(monitor == address(0));
        monitor = _monitor;
    }

    /// @notice Owner is able to start procedure for changing monitor
    /// @dev after CHANGE_PERIOD needs to call confirmNewMonitor to actually make a change
    /// @param _newMonitor address of new monitor
    function changeMonitor(address _newMonitor) public onlyOwner {
        require(changeRequestedTimestamp == 0);

        changeRequestedTimestamp = now;
        lastMonitor = monitor;
        newMonitor = _newMonitor;

        emit MonitorChangeInitiated(lastMonitor, newMonitor);
    }

    /// @notice At any point owner is able to cancel monitor change
    function cancelMonitorChange() public onlyOwner {
        require(changeRequestedTimestamp > 0);

        changeRequestedTimestamp = 0;
        newMonitor = address(0);

        emit MonitorChangeCanceled();
    }

    /// @notice Anyone is able to confirm new monitor after CHANGE_PERIOD if process is started
    function confirmNewMonitor() public onlyOwner {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);
        require(newMonitor != address(0));

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;

        emit MonitorChangeFinished(monitor);
    }

    /// @notice Its possible to revert monitor to last used monitor
    function revertMonitor() public onlyOwner {
        require(lastMonitor != address(0));

        monitor = lastMonitor;

        emit MonitorChangeReverted(monitor);
    }

    function setChangePeriod(uint _periodInHours) public onlyOwner {
        require(_periodInHours * 1 hours > CHANGE_PERIOD);

        CHANGE_PERIOD = _periodInHours * 1 hours;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../auth/AdminAuth.sol";

/// @title Stores subscription information for Aave automatization
contract AaveSubscriptionsV2 is AdminAuth {

    string public constant NAME = "AaveSubscriptionsV2";

    struct AaveHolder {
        address user;
        uint128 minRatio;
        uint128 maxRatio;
        uint128 optimalRatioBoost;
        uint128 optimalRatioRepay;
        bool boostEnabled;
    }

    struct SubPosition {
        uint arrPos;
        bool subscribed;
    }

    AaveHolder[] public subscribers;
    mapping (address => SubPosition) public subscribersPos;

    uint public changeIndex;

    event Subscribed(address indexed user);
    event Unsubscribed(address indexed user);
    event Updated(address indexed user);
    event ParamUpdates(address indexed user, uint128, uint128, uint128, uint128, bool);

    /// @dev Called by the DSProxy contract which owns the Aave position
    /// @notice Adds the users Aave poistion in the list of subscriptions so it can be monitored
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalBoost Ratio amount which boost should target
    /// @param _optimalRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled) external {

        // if boost is not enabled, set max ratio to max uint
        uint128 localMaxRatio = _boostEnabled ? _maxRatio : uint128(-1);
        require(checkParams(_minRatio, localMaxRatio), "Must be correct params");

        SubPosition storage subInfo = subscribersPos[msg.sender];

        AaveHolder memory subscription = AaveHolder({
                minRatio: _minRatio,
                maxRatio: localMaxRatio,
                optimalRatioBoost: _optimalBoost,
                optimalRatioRepay: _optimalRepay,
                user: msg.sender,
                boostEnabled: _boostEnabled
            });

        changeIndex++;

        if (subInfo.subscribed) {
            subscribers[subInfo.arrPos] = subscription;

            emit Updated(msg.sender);
            emit ParamUpdates(msg.sender, _minRatio, localMaxRatio, _optimalBoost, _optimalRepay, _boostEnabled);
        } else {
            subscribers.push(subscription);

            subInfo.arrPos = subscribers.length - 1;
            subInfo.subscribed = true;

            emit Subscribed(msg.sender);
        }
    }

    /// @notice Called by the users DSProxy
    /// @dev Owner who subscribed cancels his subscription
    function unsubscribe() external {
        _unsubscribe(msg.sender);
    }

    /// @dev Checks limit if minRatio is bigger than max
    /// @param _minRatio Minimum ratio, bellow which repay can be triggered
    /// @param _maxRatio Maximum ratio, over which boost can be triggered
    /// @return Returns bool if the params are correct
    function checkParams(uint128 _minRatio, uint128 _maxRatio) internal pure returns (bool) {

        if (_minRatio > _maxRatio) {
            return false;
        }

        return true;
    }

    /// @dev Internal method to remove a subscriber from the list
    /// @param _user The actual address that owns the Aave position
    function _unsubscribe(address _user) internal {
        require(subscribers.length > 0, "Must have subscribers in the list");

        SubPosition storage subInfo = subscribersPos[_user];

        require(subInfo.subscribed, "Must first be subscribed");

        address lastOwner = subscribers[subscribers.length - 1].user;

        SubPosition storage subInfo2 = subscribersPos[lastOwner];
        subInfo2.arrPos = subInfo.arrPos;

        subscribers[subInfo.arrPos] = subscribers[subscribers.length - 1];
        subscribers.pop(); // remove last element and reduce arr length

        changeIndex++;
        subInfo.subscribed = false;
        subInfo.arrPos = 0;

        emit Unsubscribed(msg.sender);
    }

    /// @dev Checks if the user is subscribed
    /// @param _user The actual address that owns the Aave position
    /// @return If the user is subscribed
    function isSubscribed(address _user) public view returns (bool) {
        SubPosition storage subInfo = subscribersPos[_user];

        return subInfo.subscribed;
    }

    /// @dev Returns subscribtion information about a user
    /// @param _user The actual address that owns the Aave position
    /// @return Subscription information about the user if exists
    function getHolder(address _user) public view returns (AaveHolder memory) {
        SubPosition storage subInfo = subscribersPos[_user];

        return subscribers[subInfo.arrPos];
    }

    /// @notice Helper method to return all the subscribed CDPs
    /// @return List of all subscribers
    function getSubscribers() public view returns (AaveHolder[] memory) {
        return subscribers;
    }

    /// @notice Helper method for the frontend, returns all the subscribed CDPs paginated
    /// @param _page What page of subscribers you want
    /// @param _perPage Number of entries per page
    /// @return List of all subscribers for that page
    function getSubscribersByPage(uint _page, uint _perPage) public view returns (AaveHolder[] memory) {
        AaveHolder[] memory holders = new AaveHolder[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > holders.length) ? holders.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            holders[count] = subscribers[i];
            count++;
        }

        return holders;
    }

    ////////////// ADMIN METHODS ///////////////////

    /// @notice Admin function to unsubscribe a position
    /// @param _user The actual address that owns the Aave position
    function unsubscribeByAdmin(address _user) public onlyOwner {
        SubPosition storage subInfo = subscribersPos[_user];

        if (subInfo.subscribed) {
            _unsubscribe(_user);
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./AaveSafetyRatioV2.sol";
import "../interfaces/IAaveProtocolDataProviderV2.sol";

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

    struct TokenInfo {
        address aTokenAddress;
        address underlyingTokenAddress;
        uint256 collateralFactor;
        uint256 price;
    }

    struct TokenInfoFull {
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
        address token;
        uint256 balance;
        uint256 borrowsStable;
        uint256 borrowsVariable;
        uint256 stableBorrowRate;
        bool enabledAsCollateral;
    }

    /// @notice Calcualted the ratio of coll/debt for a compound user
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _user Address of the user
    function getRatio(address _market, address _user) public view returns (uint256) {
        // For each asset the account is in
        return getSafetyRatio(_market, _user);
    }

    /// @notice Fetches Aave prices for tokens
    /// @param _market Address of LendingPoolAddressesProvider for specific market
    /// @param _tokens Arr. of tokens for which to get the prices
    /// @return prices Array of prices
    function getPrices(address _market, address[] memory _tokens) public view returns (uint256[] memory prices) {
        address priceOracleAddress = ILendingPoolAddressesProviderV2(_market).getPriceOracle();
        prices = IPriceOracleGetterAave(priceOracleAddress).getAssetsPrices(_tokens);
    }

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

    function getTokenBalances(address _market, address _user, address[] memory _tokens) public view returns (UserToken[] memory userTokens) {
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);

        userTokens = new UserToken[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address asset = _tokens[i];
            userTokens[i].token = asset;

            (userTokens[i].balance, userTokens[i].borrowsStable, userTokens[i].borrowsVariable,,,userTokens[i].stableBorrowRate,,,userTokens[i].enabledAsCollateral) = dataProvider.getUserReserveData(asset, _user);
        }
    }

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
            aTokenAddress: aToken,
            underlyingTokenAddress: _token,
            supplyRate: t.liquidityRate,
            borrowRateVariable: t.variableBorrowRate,
            borrowRateStable: t.stableBorrowRate,
            totalSupply: ERC20(aToken).totalSupply(),
            availableLiquidity: t.availableLiquidity,
            totalBorrow: t.totalVariableDebt+t.totalStableDebt,
            collateralFactor: ltv,
            liquidationRatio: liquidationThreshold,
            price: price,
            usageAsCollateralEnabled: usageAsCollateralEnabled,
            borrowinEnabled: borrowinEnabled,
            stableBorrowRateEnabled: stableBorrowRateEnabled
        });
    }

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
            collAddr: new address[](reserves.length),
            borrowAddr: new address[](reserves.length),
            collAmounts: new uint[](reserves.length),
            borrowStableAmounts: new uint[](reserves.length),
            borrowVariableAmounts: new uint[](reserves.length)
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
}

pragma solidity ^0.6.0;

import "./AaveHelper.sol";

contract AaveSafetyRatio is AaveHelper {

    function getSafetyRatio(address _user) public view returns(uint256) {
        address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        (,,uint256 totalBorrowsETH,,uint256 availableBorrowsETH,,,) = ILendingPool(lendingPoolAddress).getUserAccountData(_user);

        if (totalBorrowsETH == 0) return uint256(0);

        return wdiv(add(totalBorrowsETH, availableBorrowsETH), totalBorrowsETH);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "./AaveMonitorProxy.sol";
import "./AaveSubscriptions.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../../loggers/DefisaverLogger.sol";
import "../AaveSafetyRatio.sol";
import "../../exchangeV3/DFSExchangeData.sol";

/// @title Contract implements logic of calling boost/repay in the automatic system
contract AaveMonitor is AdminAuth, DSMath, AaveSafetyRatio, GasBurner {

    using SafeERC20 for ERC20;

    enum Method { Boost, Repay }

    uint public REPAY_GAS_TOKEN = 20;
    uint public BOOST_GAS_TOKEN = 20;

    uint public MAX_GAS_PRICE = 400000000000; // 400 gwei

    uint public REPAY_GAS_COST = 2000000;
    uint public BOOST_GAS_COST = 2000000;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    AaveMonitorProxy public aaveMonitorProxy;
    AaveSubscriptions public subscriptionsContract;
    address public aaveSaverProxy;

    DefisaverLogger public logger = DefisaverLogger(DEFISAVER_LOGGER);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    /// @param _aaveMonitorProxy Proxy contracts that actually is authorized to call DSProxy
    /// @param _subscriptions Subscriptions contract for Aave positions
    /// @param _aaveSaverProxy Contract that actually performs Repay/Boost
    constructor(address _aaveMonitorProxy, address _subscriptions, address _aaveSaverProxy) public {
        aaveMonitorProxy = AaveMonitorProxy(_aaveMonitorProxy);
        subscriptionsContract = AaveSubscriptions(_subscriptions);
        aaveSaverProxy = _aaveSaverProxy;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _exData Exchange data
    /// @param _user The actual address that owns the Aave position
    function repayFor(
        DFSExchangeData.ExchangeData memory _exData,
        address _user
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _user);
        require(isAllowed); // check if conditions are met

        uint256 gasCost = calcGasCost(REPAY_GAS_COST);

        aaveMonitorProxy.callExecute{value: msg.value}(
            _user,
            aaveSaverProxy,
            abi.encodeWithSignature(
                "repay((address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256)",
                _exData,
                gasCost
            )
        );

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _user);
        require(isGoodRatio); // check if the after result of the actions is good

        returnEth();

        logger.Log(address(this), _user, "AutomaticAaveRepay", abi.encode(ratioBefore, ratioAfter));
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _exData Exchange data
    /// @param _user The actual address that owns the Aave position
    function boostFor(
        DFSExchangeData.ExchangeData memory _exData,
        address _user
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _user);
        require(isAllowed); // check if conditions are met

        uint256 gasCost = calcGasCost(BOOST_GAS_COST);

        aaveMonitorProxy.callExecute{value: msg.value}(
            _user,
            aaveSaverProxy,
            abi.encodeWithSignature(
                "boost((address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256)",
                _exData,
                gasCost
            )
        );


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _user);
        require(isGoodRatio);  // check if the after result of the actions is good

        returnEth();

        logger.Log(address(this), _user, "AutomaticAaveBoost", abi.encode(ratioBefore, ratioAfter));
    }

/******************* INTERNAL METHODS ********************************/
    function returnEth() internal {
        // return if some eth left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

/******************* STATIC METHODS ********************************/

    /// @notice Checks if Boost/Repay could be triggered for the CDP
    /// @dev Called by AaveMonitor to enforce the min/max check
    /// @param _method Type of action to be called
    /// @param _user The actual address that owns the Aave position
    /// @return Boolean if it can be called and the ratio
    function canCall(Method _method, address _user) public view returns(bool, uint) {
        bool subscribed = subscriptionsContract.isSubscribed(_user);
        AaveSubscriptions.AaveHolder memory holder = subscriptionsContract.getHolder(_user);

        // check if cdp is subscribed
        if (!subscribed) return (false, 0);

        // check if boost and boost allowed
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        uint currRatio = getSafetyRatio(_user);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    /// @dev After the Boost/Repay check if the ratio doesn't trigger another call
    /// @param _method Type of action to be called
    /// @param _user The actual address that owns the Aave position
    /// @return Boolean if the recent action preformed correctly and the ratio
    function ratioGoodAfter(Method _method, address _user) public view returns(bool, uint) {
        AaveSubscriptions.AaveHolder memory holder;

        holder= subscriptionsContract.getHolder(_user);

        uint currRatio = getSafetyRatio(_user);

        if (_method == Method.Repay) {
            return (currRatio < holder.maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.minRatio, currRatio);
        }
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) public view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

    /// @notice As the code is new, have a emergancy admin saver proxy change
    function changeAaveSaverProxy(address _newAaveSaverProxy) public onlyAdmin {
        aaveSaverProxy = _newAaveSaverProxy;
    }

    /// @notice Allows owner to change gas cost for boost operation, but only up to 3 millions
    /// @param _gasCost New gas cost for boost method
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change gas cost for repay operation, but only up to 3 millions
    /// @param _gasCost New gas cost for repay method
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change max gas price
    /// @param _maxGasPrice New max gas price
    function changeMaxGasPrice(uint _maxGasPrice) public onlyOwner {
        require(_maxGasPrice < 500000000000);

        MAX_GAS_PRICE = _maxGasPrice;
    }

    /// @notice Allows owner to change gas token amount
    /// @param _gasTokenAmount New gas token amount
    /// @param _repay true if repay gas token, false if boost gas token
    function changeGasTokenAmount(uint _gasTokenAmount, bool _repay) public onlyOwner {
        if (_repay) {
            REPAY_GAS_TOKEN = _gasTokenAmount;
        } else {
            BOOST_GAS_TOKEN = _gasTokenAmount;
        }
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/DSProxyInterface.sol";
import "../../utils/SafeERC20.sol";
import "../../auth/AdminAuth.sol";

/// @title Contract with the actuall DSProxy permission calls the automation operations
contract AaveMonitorProxy is AdminAuth {

    using SafeERC20 for ERC20;

    uint public CHANGE_PERIOD;
    address public monitor;
    address public newMonitor;
    address public lastMonitor;
    uint public changeRequestedTimestamp;

    mapping(address => bool) public allowed;

    event MonitorChangeInitiated(address oldMonitor, address newMonitor);
    event MonitorChangeCanceled();
    event MonitorChangeFinished(address monitor);
    event MonitorChangeReverted(address monitor);

    // if someone who is allowed become malicious, owner can't be changed
    modifier onlyAllowed() {
        require(allowed[msg.sender] || msg.sender == owner);
        _;
    }

    modifier onlyMonitor() {
        require (msg.sender == monitor);
        _;
    }

    constructor(uint _changePeriod) public {
        CHANGE_PERIOD = _changePeriod * 1 days;
    }

    /// @notice Only monitor contract is able to call execute on users proxy
    /// @param _owner Address of cdp owner (users DSProxy address)
    /// @param _aaveSaverProxy Address of AaveSaverProxy
    /// @param _data Data to send to AaveSaverProxy
    function callExecute(address _owner, address _aaveSaverProxy, bytes memory _data) public payable onlyMonitor {
        // execute reverts if calling specific method fails
        DSProxyInterface(_owner).execute{value: msg.value}(_aaveSaverProxy, _data);

        // return if anything left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @notice Allowed users are able to set Monitor contract without any waiting period first time
    /// @param _monitor Address of Monitor contract
    function setMonitor(address _monitor) public onlyAllowed {
        require(monitor == address(0));
        monitor = _monitor;
    }

    /// @notice Allowed users are able to start procedure for changing monitor
    /// @dev after CHANGE_PERIOD needs to call confirmNewMonitor to actually make a change
    /// @param _newMonitor address of new monitor
    function changeMonitor(address _newMonitor) public onlyAllowed {
        require(changeRequestedTimestamp == 0);

        changeRequestedTimestamp = now;
        lastMonitor = monitor;
        newMonitor = _newMonitor;

        emit MonitorChangeInitiated(lastMonitor, newMonitor);
    }

    /// @notice At any point allowed users are able to cancel monitor change
    function cancelMonitorChange() public onlyAllowed {
        require(changeRequestedTimestamp > 0);

        changeRequestedTimestamp = 0;
        newMonitor = address(0);

        emit MonitorChangeCanceled();
    }

    /// @notice Anyone is able to confirm new monitor after CHANGE_PERIOD if process is started
    function confirmNewMonitor() public onlyAllowed {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);
        require(newMonitor != address(0));

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;

        emit MonitorChangeFinished(monitor);
    }

    /// @notice Its possible to revert monitor to last used monitor
    function revertMonitor() public onlyAllowed {
        require(lastMonitor != address(0));

        monitor = lastMonitor;

        emit MonitorChangeReverted(monitor);
    }


    /// @notice Allowed users are able to add new allowed user
    /// @param _user Address of user that will be allowed
    function addAllowed(address _user) public onlyAllowed {
        allowed[_user] = true;
    }

    /// @notice Allowed users are able to remove allowed user
    /// @dev owner is always allowed even if someone tries to remove it from allowed mapping
    /// @param _user Address of allowed user
    function removeAllowed(address _user) public onlyAllowed {
        allowed[_user] = false;
    }

    function setChangePeriod(uint _periodInDays) public onlyAllowed {
        require(_periodInDays * 1 days > CHANGE_PERIOD);

        CHANGE_PERIOD = _periodInDays * 1 days;
    }

    /// @notice In case something is left in contract, owner is able to withdraw it
    /// @param _token address of token to withdraw balance
    function withdrawToken(address _token) public onlyOwner {
        uint balance = ERC20(_token).balanceOf(address(this));
        ERC20(_token).safeTransfer(msg.sender, balance);
    }

    /// @notice In case something is left in contract, owner is able to withdraw it
    function withdrawEth() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../auth/AdminAuth.sol";

/// @title Stores subscription information for Aave automatization
contract AaveSubscriptions is AdminAuth {

    struct AaveHolder {
        address user;
        uint128 minRatio;
        uint128 maxRatio;
        uint128 optimalRatioBoost;
        uint128 optimalRatioRepay;
        bool boostEnabled;
    }

    struct SubPosition {
        uint arrPos;
        bool subscribed;
    }

    AaveHolder[] public subscribers;
    mapping (address => SubPosition) public subscribersPos;

    uint public changeIndex;

    event Subscribed(address indexed user);
    event Unsubscribed(address indexed user);
    event Updated(address indexed user);
    event ParamUpdates(address indexed user, uint128, uint128, uint128, uint128, bool);

    /// @dev Called by the DSProxy contract which owns the Aave position
    /// @notice Adds the users Aave poistion in the list of subscriptions so it can be monitored
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalBoost Ratio amount which boost should target
    /// @param _optimalRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled) external {

        // if boost is not enabled, set max ratio to max uint
        uint128 localMaxRatio = _boostEnabled ? _maxRatio : uint128(-1);
        require(checkParams(_minRatio, localMaxRatio), "Must be correct params");

        SubPosition storage subInfo = subscribersPos[msg.sender];

        AaveHolder memory subscription = AaveHolder({
                minRatio: _minRatio,
                maxRatio: localMaxRatio,
                optimalRatioBoost: _optimalBoost,
                optimalRatioRepay: _optimalRepay,
                user: msg.sender,
                boostEnabled: _boostEnabled
            });

        changeIndex++;

        if (subInfo.subscribed) {
            subscribers[subInfo.arrPos] = subscription;

            emit Updated(msg.sender);
            emit ParamUpdates(msg.sender, _minRatio, localMaxRatio, _optimalBoost, _optimalRepay, _boostEnabled);
        } else {
            subscribers.push(subscription);

            subInfo.arrPos = subscribers.length - 1;
            subInfo.subscribed = true;

            emit Subscribed(msg.sender);
        }
    }

    /// @notice Called by the users DSProxy
    /// @dev Owner who subscribed cancels his subscription
    function unsubscribe() external {
        _unsubscribe(msg.sender);
    }

    /// @dev Checks limit if minRatio is bigger than max
    /// @param _minRatio Minimum ratio, bellow which repay can be triggered
    /// @param _maxRatio Maximum ratio, over which boost can be triggered
    /// @return Returns bool if the params are correct
    function checkParams(uint128 _minRatio, uint128 _maxRatio) internal pure returns (bool) {

        if (_minRatio > _maxRatio) {
            return false;
        }

        return true;
    }

    /// @dev Internal method to remove a subscriber from the list
    /// @param _user The actual address that owns the Aave position
    function _unsubscribe(address _user) internal {
        require(subscribers.length > 0, "Must have subscribers in the list");

        SubPosition storage subInfo = subscribersPos[_user];

        require(subInfo.subscribed, "Must first be subscribed");

        address lastOwner = subscribers[subscribers.length - 1].user;

        SubPosition storage subInfo2 = subscribersPos[lastOwner];
        subInfo2.arrPos = subInfo.arrPos;

        subscribers[subInfo.arrPos] = subscribers[subscribers.length - 1];
        subscribers.pop(); // remove last element and reduce arr length

        changeIndex++;
        subInfo.subscribed = false;
        subInfo.arrPos = 0;

        emit Unsubscribed(msg.sender);
    }

    /// @dev Checks if the user is subscribed
    /// @param _user The actual address that owns the Aave position
    /// @return If the user is subscribed
    function isSubscribed(address _user) public view returns (bool) {
        SubPosition storage subInfo = subscribersPos[_user];

        return subInfo.subscribed;
    }

    /// @dev Returns subscribtion information about a user
    /// @param _user The actual address that owns the Aave position
    /// @return Subscription information about the user if exists
    function getHolder(address _user) public view returns (AaveHolder memory) {
        SubPosition storage subInfo = subscribersPos[_user];

        return subscribers[subInfo.arrPos];
    }

    /// @notice Helper method to return all the subscribed CDPs
    /// @return List of all subscribers
    function getSubscribers() public view returns (AaveHolder[] memory) {
        return subscribers;
    }

    /// @notice Helper method for the frontend, returns all the subscribed CDPs paginated
    /// @param _page What page of subscribers you want
    /// @param _perPage Number of entries per page
    /// @return List of all subscribers for that page
    function getSubscribersByPage(uint _page, uint _perPage) public view returns (AaveHolder[] memory) {
        AaveHolder[] memory holders = new AaveHolder[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > holders.length) ? holders.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            holders[count] = subscribers[i];
            count++;
        }

        return holders;
    }

    ////////////// ADMIN METHODS ///////////////////

    /// @notice Admin function to unsubscribe a position
    /// @param _user The actual address that owns the Aave position
    function unsubscribeByAdmin(address _user) public onlyOwner {
        SubPosition storage subInfo = subscribersPos[_user];

        if (subInfo.subscribed) {
            _unsubscribe(_user);
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./AaveSafetyRatio.sol";

contract AaveLoanInfo is AaveSafetyRatio {

	struct LoanData {
        address user;
        uint128 ratio;
        address[] collAddr;
        address[] borrowAddr;
        uint256[] collAmounts;
        uint256[] borrowAmounts;
    }

    struct TokenInfo {
        address aTokenAddress;
        address underlyingTokenAddress;
        uint256 collateralFactor;
        uint256 price;
    }

    struct TokenInfoFull {
    	address aTokenAddress;
        address underlyingTokenAddress;
        uint256 supplyRate;
        uint256 borrowRate;
        uint256 borrowRateStable;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalBorrow;
        uint256 collateralFactor;
        uint256 liquidationRatio;
        uint256 price;
        bool usageAsCollateralEnabled;
    }

    struct UserToken {
        address token;
        uint256 balance;
        uint256 borrows;
        uint256 borrowRateMode;
        uint256 borrowRate;
        bool enabledAsCollateral;
    }

    /// @notice Calcualted the ratio of coll/debt for a compound user
    /// @param _user Address of the user
    function getRatio(address _user) public view returns (uint256) {
        // For each asset the account is in
        return getSafetyRatio(_user);
    }

    /// @notice Fetches Aave prices for tokens
    /// @param _tokens Arr. of tokens for which to get the prices
    /// @return prices Array of prices
    function getPrices(address[] memory _tokens) public view returns (uint256[] memory prices) {
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();
        prices = new uint[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; ++i) {
            prices[i] = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokens[i]);
        }
    }

    /// @notice Fetches Aave collateral factors for tokens
    /// @param _tokens Arr. of tokens for which to get the coll. factors
    /// @return collFactors Array of coll. factors
    function getCollFactors(address[] memory _tokens) public view returns (uint256[] memory collFactors) {
    	address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        collFactors = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; ++i) {
        	(,collFactors[i],,) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_tokens[i]);
        }
    }

    function getTokenBalances(address _user, address[] memory _tokens) public view returns (UserToken[] memory userTokens) {
    	address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        userTokens = new UserToken[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address asset = _tokens[i];
            userTokens[i].token = asset;

            (userTokens[i].balance, userTokens[i].borrows,,userTokens[i].borrowRateMode,userTokens[i].borrowRate,,,,,userTokens[i].enabledAsCollateral) = ILendingPool(lendingPoolAddress).getUserReserveData(asset, _user);
        }
    }

    /// @notice Calcualted the ratio of coll/debt for an aave user
    /// @param _users Addresses of the user
    /// @return ratios Array of ratios
    function getRatios(address[] memory _users) public view returns (uint256[] memory ratios) {
        ratios = new uint256[](_users.length);

        for (uint256 i = 0; i < _users.length; ++i) {
            ratios[i] = getSafetyRatio(_users[i]);
        }
    }

    /// @notice Information about reserves
    /// @param _tokenAddresses Array of tokens addresses
    /// @return tokens Array of reserves infomartion
    function getTokensInfo(address[] memory _tokenAddresses) public view returns(TokenInfo[] memory tokens) {
    	address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
    	address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        tokens = new TokenInfo[](_tokenAddresses.length);

        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
        	(,uint256 ltv,,) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_tokenAddresses[i]);

            tokens[i] = TokenInfo({
                aTokenAddress: ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(_tokenAddresses[i]),
                underlyingTokenAddress: _tokenAddresses[i],
                collateralFactor: ltv,
                price: IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddresses[i])
            });
        }
    }

    /// @notice Information about reserves
    /// @param _tokenAddresses Array of token addresses
    /// @return tokens Array of reserves infomartion
    function getFullTokensInfo(address[] memory _tokenAddresses) public view returns(TokenInfoFull[] memory tokens) {
    	address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
    	address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        tokens = new TokenInfoFull[](_tokenAddresses.length);

        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
        	(uint256 ltv, uint256 liqRatio,,, bool usageAsCollateralEnabled, bool borrowingEnabled, bool stableBorrowingEnabled,) = ILendingPool(lendingPoolAddress).getReserveConfigurationData(_tokenAddresses[i]);

            tokens[i] = TokenInfoFull({
            	aTokenAddress: ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(_tokenAddresses[i]),
                underlyingTokenAddress: _tokenAddresses[i],
                supplyRate: ILendingPool(lendingPoolCoreAddress).getReserveCurrentLiquidityRate(_tokenAddresses[i]),
                borrowRate: borrowingEnabled ? ILendingPool(lendingPoolCoreAddress).getReserveCurrentVariableBorrowRate(_tokenAddresses[i]) : 0,
                borrowRateStable: stableBorrowingEnabled ? ILendingPool(lendingPoolCoreAddress).getReserveCurrentStableBorrowRate(_tokenAddresses[i]) : 0,
                totalSupply: ILendingPool(lendingPoolCoreAddress).getReserveTotalLiquidity(_tokenAddresses[i]),
                availableLiquidity: ILendingPool(lendingPoolCoreAddress).getReserveAvailableLiquidity(_tokenAddresses[i]),
                totalBorrow: ILendingPool(lendingPoolCoreAddress).getReserveTotalBorrowsVariable(_tokenAddresses[i]) + ILendingPool(lendingPoolCoreAddress).getReserveTotalBorrowsStable(_tokenAddresses[i]),
                collateralFactor: ltv,
                liquidationRatio: liqRatio,
                price: IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddresses[i]),
                usageAsCollateralEnabled: usageAsCollateralEnabled
            });
        }
    }


    /// @notice Fetches all the collateral/debt address and amounts, denominated in ether
    /// @param _user Address of the user
    /// @return data LoanData information
    function getLoanData(address _user) public view returns (LoanData memory data) {
        address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        address[] memory reserves = ILendingPool(lendingPoolAddress).getReserves();

        data = LoanData({
            user: _user,
            ratio: 0,
            collAddr: new address[](reserves.length),
            borrowAddr: new address[](reserves.length),
            collAmounts: new uint[](reserves.length),
            borrowAmounts: new uint[](reserves.length)
        });

        uint64 collPos = 0;
        uint64 borrowPos = 0;

        for (uint64 i = 0; i < reserves.length; i++) {
            address reserve = reserves[i];

            (uint256 aTokenBalance, uint256 borrowBalance,,,,,,,,) = ILendingPool(lendingPoolAddress).getUserReserveData(reserve, _user);
            uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(reserves[i]);

            if (aTokenBalance > 0) {
            	uint256 userTokenBalanceEth = wmul(aTokenBalance, price) * (10 ** (18 - _getDecimals(reserve)));
            	data.collAddr[collPos] = reserve;
                data.collAmounts[collPos] = userTokenBalanceEth;
                collPos++;
        	}

            // Sum up debt in Eth
            if (borrowBalance > 0) {
            	uint256 userBorrowBalanceEth = wmul(borrowBalance, price) * (10 ** (18 - _getDecimals(reserve)));
                data.borrowAddr[borrowPos] = reserve;
                data.borrowAmounts[borrowPos] = userBorrowBalanceEth;
                borrowPos++;
            }
        }

        data.ratio = uint128(getSafetyRatio(_user));

        return data;
    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in ether
    /// @param _users Addresses of the user
    /// @return loans Array of LoanData information
    function getLoanDataArr(address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_users[i]);
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/GasTokenInterface.sol";
import "./DFSExchangeCore.sol";
import "../DS/DSMath.sol";
import "../loggers/DefisaverLogger.sol";
import "../auth/AdminAuth.sol";
import "../utils/GasBurner.sol";
import "../utils/SafeERC20.sol";

contract DFSExchange is DFSExchangeCore, AdminAuth, GasBurner {

    using SafeERC20 for ERC20;

    uint256 public constant SERVICE_FEE = 800; // 0.125% Fee

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    uint public burnAmount = 10;

    /// @notice Takes a src amount of tokens and converts it into the dest token
    /// @dev Takes fee from the _srcAmount before the exchange
    /// @param exData [srcAddr, destAddr, srcAmount, destAmount, minPrice, exchangeType, exchangeAddr, callData, price0x]
    /// @param _user User address who called the exchange
    function sell(ExchangeData memory exData, address payable _user) public payable burnGas(burnAmount) {

        exData.dfsFeeDivider = SERVICE_FEE;
        exData.user = _user;

        // Perform the exchange
        (address wrapper, uint destAmount) = _sell(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr, _user);

        // log the event
        logger.Log(address(this), msg.sender, "ExchangeSell", abi.encode(wrapper, exData.srcAddr, exData.destAddr, exData.srcAmount, destAmount));
    }

    /// @notice Takes a dest amount of tokens and converts it from the src token
    /// @dev Send always more than needed for the swap, extra will be returned
    /// @param exData [srcAddr, destAddr, srcAmount, destAmount, minPrice, exchangeType, exchangeAddr, callData, price0x]
    /// @param _user User address who called the exchange
    function buy(ExchangeData memory exData, address payable _user) public payable burnGas(burnAmount){

        exData.dfsFeeDivider = SERVICE_FEE;
        exData.user = _user;

        // Perform the exchange
        (address wrapper, uint srcAmount) = _buy(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr, _user);

        // log the event
        logger.Log(address(this), msg.sender, "ExchangeBuy", abi.encode(wrapper, exData.srcAddr, exData.destAddr, srcAmount, exData.destAmount));

    }

    /// @notice Changes the amount of gas token we burn for each call
    /// @dev Only callable by the owner
    /// @param _newBurnAmount New amount of gas tokens to be burned
    function changeBurnAmount(uint _newBurnAmount) public {
        require(owner == msg.sender);

        burnAmount = _newBurnAmount;
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../auth/AdminAuth.sol";
import "./DFSExchange.sol";
import "../utils/SafeERC20.sol";

contract AllowanceProxy is AdminAuth {

    using SafeERC20 for ERC20;

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    DFSExchange dfsExchange = DFSExchange(0xc2Ce04e2FB4DD20964b4410FcE718b95963a1587);

    function callSell(DFSExchangeCore.ExchangeData memory exData) public payable {
        pullAndSendTokens(exData.srcAddr, exData.srcAmount);

        dfsExchange.sell{value: msg.value}(exData, msg.sender);
    }

    function callBuy(DFSExchangeCore.ExchangeData memory exData) public payable {
        pullAndSendTokens(exData.srcAddr, exData.srcAmount);

        dfsExchange.buy{value: msg.value}(exData, msg.sender);
    }

    function pullAndSendTokens(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount, "msg.value smaller than amount");
        } else {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(dfsExchange), _amount);
        }
    }

    function ownerChangeExchange(address payable _newExchange) public onlyOwner {
        dfsExchange = DFSExchange(_newExchange);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/BotRegistry.sol";
import "../../utils/GasBurner.sol";
import "./CompoundMonitorProxy.sol";
import "./CompoundSubscriptions.sol";
import "../../interfaces/GasTokenInterface.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../../loggers/DefisaverLogger.sol";
import "../CompoundSafetyRatio.sol";
import "../../exchange/SaverExchangeCore.sol";

/// @title Contract implements logic of calling boost/repay in the automatic system
contract CompoundMonitor is AdminAuth, DSMath, CompoundSafetyRatio, GasBurner {

    using SafeERC20 for ERC20;

    enum Method { Boost, Repay }

    uint public REPAY_GAS_TOKEN = 20;
    uint public BOOST_GAS_TOKEN = 20;

    uint constant public MAX_GAS_PRICE = 500000000000; // 500 gwei

    uint public REPAY_GAS_COST = 1500000;
    uint public BOOST_GAS_COST = 1000000;

    address public constant GAS_TOKEN_INTERFACE_ADDRESS = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    CompoundMonitorProxy public compoundMonitorProxy;
    CompoundSubscriptions public subscriptionsContract;
    address public compoundFlashLoanTakerAddress;

    DefisaverLogger public logger = DefisaverLogger(DEFISAVER_LOGGER);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    /// @param _compoundMonitorProxy Proxy contracts that actually is authorized to call DSProxy
    /// @param _subscriptions Subscriptions contract for Compound positions
    /// @param _compoundFlashLoanTaker Contract that actually performs Repay/Boost
    constructor(address _compoundMonitorProxy, address _subscriptions, address _compoundFlashLoanTaker) public {
        compoundMonitorProxy = CompoundMonitorProxy(_compoundMonitorProxy);
        subscriptionsContract = CompoundSubscriptions(_subscriptions);
        compoundFlashLoanTakerAddress = _compoundFlashLoanTaker;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _user The actual address that owns the Compound position
    function repayFor(
        SaverExchangeCore.ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        address _user
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _user);
        require(isAllowed); // check if conditions are met

        uint256 gasCost = calcGasCost(REPAY_GAS_COST);

        compoundMonitorProxy.callExecute{value: msg.value}(
            _user,
            compoundFlashLoanTakerAddress,
            abi.encodeWithSignature(
                "repayWithLoan((address,address,uint256,uint256,uint256,address,address,bytes,uint256),address[2],uint256)",
                _exData,
                _cAddresses,
                gasCost
            )
        );

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _user);
        require(isGoodRatio); // check if the after result of the actions is good

        returnEth();

        logger.Log(address(this), _user, "AutomaticCompoundRepay", abi.encode(ratioBefore, ratioAfter));
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _user The actual address that owns the Compound position
    function boostFor(
        SaverExchangeCore.ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        address _user
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _user);
        require(isAllowed); // check if conditions are met

        uint256 gasCost = calcGasCost(BOOST_GAS_COST);

        compoundMonitorProxy.callExecute{value: msg.value}(
            _user,
            compoundFlashLoanTakerAddress,
            abi.encodeWithSignature(
                "boostWithLoan((address,address,uint256,uint256,uint256,address,address,bytes,uint256),address[2],uint256)",
                _exData,
                _cAddresses,
                gasCost
            )
        );


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _user);
        require(isGoodRatio);  // check if the after result of the actions is good

        returnEth();

        logger.Log(address(this), _user, "AutomaticCompoundBoost", abi.encode(ratioBefore, ratioAfter));
    }

/******************* INTERNAL METHODS ********************************/
    function returnEth() internal {
        // return if some eth left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

/******************* STATIC METHODS ********************************/

    /// @notice Checks if Boost/Repay could be triggered for the CDP
    /// @dev Called by MCDMonitor to enforce the min/max check
    /// @param _method Type of action to be called
    /// @param _user The actual address that owns the Compound position
    /// @return Boolean if it can be called and the ratio
    function canCall(Method _method, address _user) public view returns(bool, uint) {
        bool subscribed = subscriptionsContract.isSubscribed(_user);
        CompoundSubscriptions.CompoundHolder memory holder = subscriptionsContract.getHolder(_user);

        // check if cdp is subscribed
        if (!subscribed) return (false, 0);

        // check if boost and boost allowed
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        uint currRatio = getSafetyRatio(_user);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    /// @dev After the Boost/Repay check if the ratio doesn't trigger another call
    /// @param _method Type of action to be called
    /// @param _user The actual address that owns the Compound position
    /// @return Boolean if the recent action preformed correctly and the ratio
    function ratioGoodAfter(Method _method, address _user) public view returns(bool, uint) {
        CompoundSubscriptions.CompoundHolder memory holder;

        holder= subscriptionsContract.getHolder(_user);

        uint currRatio = getSafetyRatio(_user);

        if (_method == Method.Repay) {
            return (currRatio < holder.maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.minRatio, currRatio);
        }
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) public view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

    /// @notice As the code is new, have a emergancy admin saver proxy change
    function changeCompoundFlashLoanTaker(address _newCompoundFlashLoanTakerAddress) public onlyAdmin {
        compoundFlashLoanTakerAddress = _newCompoundFlashLoanTakerAddress;
    }

    /// @notice Allows owner to change gas cost for boost operation, but only up to 3 millions
    /// @param _gasCost New gas cost for boost method
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change gas cost for repay operation, but only up to 3 millions
    /// @param _gasCost New gas cost for repay method
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    /// @notice If any tokens gets stuck in the contract owner can withdraw it
    /// @param _tokenAddress Address of the ERC20 token
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        ERC20(_tokenAddress).safeTransfer(_to, _amount);
    }

    /// @notice If any Eth gets stuck in the contract owner can withdraw it
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferEth(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/DSProxyInterface.sol";
import "../../utils/SafeERC20.sol";
import "../../auth/AdminAuth.sol";

/// @title Contract with the actuall DSProxy permission calls the automation operations
contract CompoundMonitorProxy is AdminAuth {

    using SafeERC20 for ERC20;

    uint public CHANGE_PERIOD;
    address public monitor;
    address public newMonitor;
    address public lastMonitor;
    uint public changeRequestedTimestamp;

    mapping(address => bool) public allowed;

    event MonitorChangeInitiated(address oldMonitor, address newMonitor);
    event MonitorChangeCanceled();
    event MonitorChangeFinished(address monitor);
    event MonitorChangeReverted(address monitor);

    // if someone who is allowed become malicious, owner can't be changed
    modifier onlyAllowed() {
        require(allowed[msg.sender] || msg.sender == owner);
        _;
    }

    modifier onlyMonitor() {
        require (msg.sender == monitor);
        _;
    }

    constructor(uint _changePeriod) public {
        CHANGE_PERIOD = _changePeriod * 1 days;
    }

    /// @notice Only monitor contract is able to call execute on users proxy
    /// @param _owner Address of cdp owner (users DSProxy address)
    /// @param _compoundSaverProxy Address of CompoundSaverProxy
    /// @param _data Data to send to CompoundSaverProxy
    function callExecute(address _owner, address _compoundSaverProxy, bytes memory _data) public payable onlyMonitor {
        // execute reverts if calling specific method fails
        DSProxyInterface(_owner).execute{value: msg.value}(_compoundSaverProxy, _data);

        // return if anything left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @notice Allowed users are able to set Monitor contract without any waiting period first time
    /// @param _monitor Address of Monitor contract
    function setMonitor(address _monitor) public onlyAllowed {
        require(monitor == address(0));
        monitor = _monitor;
    }

    /// @notice Allowed users are able to start procedure for changing monitor
    /// @dev after CHANGE_PERIOD needs to call confirmNewMonitor to actually make a change
    /// @param _newMonitor address of new monitor
    function changeMonitor(address _newMonitor) public onlyAllowed {
        require(changeRequestedTimestamp == 0);

        changeRequestedTimestamp = now;
        lastMonitor = monitor;
        newMonitor = _newMonitor;

        emit MonitorChangeInitiated(lastMonitor, newMonitor);
    }

    /// @notice At any point allowed users are able to cancel monitor change
    function cancelMonitorChange() public onlyAllowed {
        require(changeRequestedTimestamp > 0);

        changeRequestedTimestamp = 0;
        newMonitor = address(0);

        emit MonitorChangeCanceled();
    }

    /// @notice Anyone is able to confirm new monitor after CHANGE_PERIOD if process is started
    function confirmNewMonitor() public onlyAllowed {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);
        require(newMonitor != address(0));

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;

        emit MonitorChangeFinished(monitor);
    }

    /// @notice Its possible to revert monitor to last used monitor
    function revertMonitor() public onlyAllowed {
        require(lastMonitor != address(0));

        monitor = lastMonitor;

        emit MonitorChangeReverted(monitor);
    }


    /// @notice Allowed users are able to add new allowed user
    /// @param _user Address of user that will be allowed
    function addAllowed(address _user) public onlyAllowed {
        allowed[_user] = true;
    }

    /// @notice Allowed users are able to remove allowed user
    /// @dev owner is always allowed even if someone tries to remove it from allowed mapping
    /// @param _user Address of allowed user
    function removeAllowed(address _user) public onlyAllowed {
        allowed[_user] = false;
    }

    function setChangePeriod(uint _periodInDays) public onlyAllowed {
        require(_periodInDays * 1 days > CHANGE_PERIOD);

        CHANGE_PERIOD = _periodInDays * 1 days;
    }

    /// @notice In case something is left in contract, owner is able to withdraw it
    /// @param _token address of token to withdraw balance
    function withdrawToken(address _token) public onlyOwner {
        uint balance = ERC20(_token).balanceOf(address(this));
        ERC20(_token).safeTransfer(msg.sender, balance);
    }

    /// @notice In case something is left in contract, owner is able to withdraw it
    function withdrawEth() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../auth/AdminAuth.sol";

/// @title Stores subscription information for Compound automatization
contract CompoundSubscriptions is AdminAuth {

    struct CompoundHolder {
        address user;
        uint128 minRatio;
        uint128 maxRatio;
        uint128 optimalRatioBoost;
        uint128 optimalRatioRepay;
        bool boostEnabled;
    }

    struct SubPosition {
        uint arrPos;
        bool subscribed;
    }

    CompoundHolder[] public subscribers;
    mapping (address => SubPosition) public subscribersPos;

    uint public changeIndex;

    event Subscribed(address indexed user);
    event Unsubscribed(address indexed user);
    event Updated(address indexed user);
    event ParamUpdates(address indexed user, uint128, uint128, uint128, uint128, bool);

    /// @dev Called by the DSProxy contract which owns the Compound position
    /// @notice Adds the users Compound poistion in the list of subscriptions so it can be monitored
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalBoost Ratio amount which boost should target
    /// @param _optimalRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled) external {

        // if boost is not enabled, set max ratio to max uint
        uint128 localMaxRatio = _boostEnabled ? _maxRatio : uint128(-1);
        require(checkParams(_minRatio, localMaxRatio), "Must be correct params");

        SubPosition storage subInfo = subscribersPos[msg.sender];

        CompoundHolder memory subscription = CompoundHolder({
                minRatio: _minRatio,
                maxRatio: localMaxRatio,
                optimalRatioBoost: _optimalBoost,
                optimalRatioRepay: _optimalRepay,
                user: msg.sender,
                boostEnabled: _boostEnabled
            });

        changeIndex++;

        if (subInfo.subscribed) {
            subscribers[subInfo.arrPos] = subscription;

            emit Updated(msg.sender);
            emit ParamUpdates(msg.sender, _minRatio, localMaxRatio, _optimalBoost, _optimalRepay, _boostEnabled);
        } else {
            subscribers.push(subscription);

            subInfo.arrPos = subscribers.length - 1;
            subInfo.subscribed = true;

            emit Subscribed(msg.sender);
        }
    }

    /// @notice Called by the users DSProxy
    /// @dev Owner who subscribed cancels his subscription
    function unsubscribe() external {
        _unsubscribe(msg.sender);
    }

    /// @dev Checks limit if minRatio is bigger than max
    /// @param _minRatio Minimum ratio, bellow which repay can be triggered
    /// @param _maxRatio Maximum ratio, over which boost can be triggered
    /// @return Returns bool if the params are correct
    function checkParams(uint128 _minRatio, uint128 _maxRatio) internal pure returns (bool) {

        if (_minRatio > _maxRatio) {
            return false;
        }

        return true;
    }

    /// @dev Internal method to remove a subscriber from the list
    /// @param _user The actual address that owns the Compound position
    function _unsubscribe(address _user) internal {
        require(subscribers.length > 0, "Must have subscribers in the list");

        SubPosition storage subInfo = subscribersPos[_user];

        require(subInfo.subscribed, "Must first be subscribed");

        address lastOwner = subscribers[subscribers.length - 1].user;

        SubPosition storage subInfo2 = subscribersPos[lastOwner];
        subInfo2.arrPos = subInfo.arrPos;

        subscribers[subInfo.arrPos] = subscribers[subscribers.length - 1];
        subscribers.pop(); // remove last element and reduce arr length

        changeIndex++;
        subInfo.subscribed = false;
        subInfo.arrPos = 0;

        emit Unsubscribed(msg.sender);
    }

    /// @dev Checks if the user is subscribed
    /// @param _user The actual address that owns the Compound position
    /// @return If the user is subscribed
    function isSubscribed(address _user) public view returns (bool) {
        SubPosition storage subInfo = subscribersPos[_user];

        return subInfo.subscribed;
    }

    /// @dev Returns subscribtion information about a user
    /// @param _user The actual address that owns the Compound position
    /// @return Subscription information about the user if exists
    function getHolder(address _user) public view returns (CompoundHolder memory) {
        SubPosition storage subInfo = subscribersPos[_user];

        return subscribers[subInfo.arrPos];
    }

    /// @notice Helper method to return all the subscribed CDPs
    /// @return List of all subscribers
    function getSubscribers() public view returns (CompoundHolder[] memory) {
        return subscribers;
    }

    /// @notice Helper method for the frontend, returns all the subscribed CDPs paginated
    /// @param _page What page of subscribers you want
    /// @param _perPage Number of entries per page
    /// @return List of all subscribers for that page
    function getSubscribersByPage(uint _page, uint _perPage) public view returns (CompoundHolder[] memory) {
        CompoundHolder[] memory holders = new CompoundHolder[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > holders.length) ? holders.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            holders[count] = subscribers[i];
            count++;
        }

        return holders;
    }

    ////////////// ADMIN METHODS ///////////////////

    /// @notice Admin function to unsubscribe a CDP
    /// @param _user The actual address that owns the Compound position
    function unsubscribeByAdmin(address _user) public onlyOwner {
        SubPosition storage subInfo = subscribersPos[_user];

        if (subInfo.subscribed) {
            _unsubscribe(_user);
        }
    }
}

pragma solidity ^0.6.0;

import "../DS/DSMath.sol";
import "../interfaces/CompoundOracleInterface.sol";
import "../interfaces/ComptrollerInterface.sol";
import "../interfaces/CTokenInterface.sol";
import "./helpers/Exponential.sol";


contract CompoundSafetyRatio is Exponential, DSMath {
    // solhint-disable-next-line const-name-snakecase
    ComptrollerInterface public constant comp = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /// @notice Calcualted the ratio of debt / adjusted collateral
    /// @param _user Address of the user
    function getSafetyRatio(address _user) public view returns (uint) {
        // For each asset the account is in
        address[] memory assets = comp.getAssetsIn(_user);
        address oracleAddr = comp.oracle();


        uint sumCollateral = 0;
        uint sumBorrow = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory oraclePrice;

            if (cTokenBalance != 0 || borrowBalance != 0) {
                oraclePrice = Exp({mantissa: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(asset)});
            }

            // Sum up collateral in Usd
            if (cTokenBalance != 0) {

                (, uint collFactorMantissa) = comp.markets(address(asset));

                Exp memory collateralFactor = Exp({mantissa: collFactorMantissa});
                Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});

                (, Exp memory tokensToUsd) = mulExp3(collateralFactor, exchangeRate, oraclePrice);

                (, sumCollateral) = mulScalarTruncateAddUInt(tokensToUsd, cTokenBalance, sumCollateral);
            }

            // Sum up debt in Usd
            if (borrowBalance != 0) {
                (, sumBorrow) = mulScalarTruncateAddUInt(oraclePrice, borrowBalance, sumBorrow);
            }
        }

        if (sumBorrow == 0) return uint(-1);

        uint borrowPowerUsed = (sumBorrow * 10**18) / sumCollateral;
        return wdiv(1e18, borrowPowerUsed);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./CompoundSafetyRatio.sol";
import "./helpers/CompoundSaverHelper.sol";


/// @title Gets data about Compound positions
contract CompoundLoanInfo is CompoundSafetyRatio {

    struct LoanData {
        address user;
        uint128 ratio;
        address[] collAddr;
        address[] borrowAddr;
        uint[] collAmounts;
        uint[] borrowAmounts;
    }

    struct TokenInfo {
        address cTokenAddress;
        address underlyingTokenAddress;
        uint collateralFactor;
        uint price;
    }

    struct TokenInfoFull {
        address underlyingTokenAddress;
        uint supplyRate;
        uint borrowRate;
        uint exchangeRate;
        uint marketLiquidity;
        uint totalSupply;
        uint totalBorrow;
        uint collateralFactor;
        uint price;
        uint borrowCap;
    }

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;


    /// @notice Calcualted the ratio of coll/debt for a compound user
    /// @param _user Address of the user
    function getRatio(address _user) public view returns (uint) {
        // For each asset the account is in
        return getSafetyRatio(_user);
    }

    /// @notice Fetches Compound prices for tokens
    /// @param _cTokens Arr. of cTokens for which to get the prices
    /// @return prices Array of prices
    function getPrices(address[] memory _cTokens) public view returns (uint[] memory prices) {
        prices = new uint[](_cTokens.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokens.length; ++i) {
            prices[i] = CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokens[i]);
        }
    }

    /// @notice Fetches Compound collateral factors for tokens
    /// @param _cTokens Arr. of cTokens for which to get the coll. factors
    /// @return collFactors Array of coll. factors
    function getCollFactors(address[] memory _cTokens) public view returns (uint[] memory collFactors) {
        collFactors = new uint[](_cTokens.length);

        for (uint i = 0; i < _cTokens.length; ++i) {
            (, collFactors[i]) = comp.markets(_cTokens[i]);
        }
    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in usd
    /// @param _user Address of the user
    /// @return data LoanData information
    function getLoanData(address _user) public view returns (LoanData memory data) {
        address[] memory assets = comp.getAssetsIn(_user);
        address oracleAddr = comp.oracle();

        data = LoanData({
            user: _user,
            ratio: 0,
            collAddr: new address[](assets.length),
            borrowAddr: new address[](assets.length),
            collAmounts: new uint[](assets.length),
            borrowAmounts: new uint[](assets.length)
        });

        uint collPos = 0;
        uint borrowPos = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory oraclePrice;

            if (cTokenBalance != 0 || borrowBalance != 0) {
                oraclePrice = Exp({mantissa: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(asset)});
            }

            // Sum up collateral in Usd
            if (cTokenBalance != 0) {
                Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
                (, Exp memory tokensToUsd) = mulExp(exchangeRate, oraclePrice);

                data.collAddr[collPos] = asset;
                (, data.collAmounts[collPos]) = mulScalarTruncate(tokensToUsd, cTokenBalance);
                collPos++;
            }

            // Sum up debt in Usd
            if (borrowBalance != 0) {
                data.borrowAddr[borrowPos] = asset;
                (, data.borrowAmounts[borrowPos]) = mulScalarTruncate(oraclePrice, borrowBalance);
                borrowPos++;
            }
        }

        data.ratio = uint128(getSafetyRatio(_user));

        return data;
    }

    function getTokenBalances(address _user, address[] memory _cTokens) public view returns (uint[] memory balances, uint[] memory borrows) {
        balances = new uint[](_cTokens.length);
        borrows = new uint[](_cTokens.length);

        for (uint i = 0; i < _cTokens.length; i++) {
            address asset = _cTokens[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
            (, balances[i]) = mulScalarTruncate(exchangeRate, cTokenBalance);

            borrows[i] = borrowBalance;
        }

    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in usd
    /// @param _users Addresses of the user
    /// @return loans Array of LoanData information
    function getLoanDataArr(address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_users[i]);
        }
    }

    /// @notice Calcualted the ratio of coll/debt for a compound user
    /// @param _users Addresses of the user
    /// @return ratios Array of ratios
    function getRatios(address[] memory _users) public view returns (uint[] memory ratios) {
        ratios = new uint[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            ratios[i] = getSafetyRatio(_users[i]);
        }
    }

    /// @notice Information about cTokens
    /// @param _cTokenAddresses Array of cTokens addresses
    /// @return tokens Array of cTokens infomartion
    function getTokensInfo(address[] memory _cTokenAddresses) public returns(TokenInfo[] memory tokens) {
        tokens = new TokenInfo[](_cTokenAddresses.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokenAddresses.length; ++i) {
            (, uint collFactor) = comp.markets(_cTokenAddresses[i]);

            tokens[i] = TokenInfo({
                cTokenAddress: _cTokenAddresses[i],
                underlyingTokenAddress: getUnderlyingAddr(_cTokenAddresses[i]),
                collateralFactor: collFactor,
                price: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokenAddresses[i])
            });
        }
    }

    /// @notice Information about cTokens
    /// @param _cTokenAddresses Array of cTokens addresses
    /// @return tokens Array of cTokens infomartion
    function getFullTokensInfo(address[] memory _cTokenAddresses) public returns(TokenInfoFull[] memory tokens) {
        tokens = new TokenInfoFull[](_cTokenAddresses.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokenAddresses.length; ++i) {
            (, uint collFactor) = comp.markets(_cTokenAddresses[i]);
            CTokenInterface cToken = CTokenInterface(_cTokenAddresses[i]);

            tokens[i] = TokenInfoFull({
                underlyingTokenAddress: getUnderlyingAddr(_cTokenAddresses[i]),
                supplyRate: cToken.supplyRatePerBlock(),
                borrowRate: cToken.borrowRatePerBlock(),
                exchangeRate: cToken.exchangeRateCurrent(),
                marketLiquidity: cToken.getCash(),
                totalSupply: cToken.totalSupply(),
                totalBorrow: cToken.totalBorrowsCurrent(),
                collateralFactor: collFactor,
                price: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokenAddresses[i]),
                borrowCap: comp.borrowCaps(_cTokenAddresses[i])
            });
        }
    }

    /// @notice Returns the underlying address of the cToken asset
    /// @param _cTokenAddress cToken address
    /// @return Token address of the cToken specified
    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ComptrollerInterface.sol";
import "../../utils/SafeERC20.sol";

contract CreamBorrowProxy {

    using SafeERC20 for ERC20;

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant COMPTROLLER_ADDR = 0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258;

    function borrow(address _cCollToken, address _cBorrowToken, address _borrowToken, uint _amount) public {
        address[] memory markets = new address[](2);
        markets[0] = _cCollToken;
        markets[1] = _cBorrowToken;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);

        require(CTokenInterface(_cBorrowToken).borrow(_amount) == 0);

        // withdraw funds to msg.sender
        if (_borrowToken != ETH_ADDR) {
            ERC20(_borrowToken).safeTransfer(msg.sender, ERC20(_borrowToken).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }
}

pragma solidity ^0.6.0;

import "../DS/DSMath.sol";
import "../interfaces/CompoundOracleInterface.sol";
import "../interfaces/ComptrollerInterface.sol";
import "../interfaces/CTokenInterface.sol";
import "../compound/helpers/Exponential.sol";


contract CreamSafetyRatio is Exponential, DSMath {
    // solhint-disable-next-line const-name-snakecase
    ComptrollerInterface public constant comp = ComptrollerInterface(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);

    /// @notice Calcualted the ratio of debt / adjusted collateral
    /// @param _user Address of the user
    function getSafetyRatio(address _user) public view returns (uint) {
        // For each asset the account is in
        address[] memory assets = comp.getAssetsIn(_user);
        address oracleAddr = comp.oracle();


        uint sumCollateral = 0;
        uint sumBorrow = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory oraclePrice;

            if (cTokenBalance != 0 || borrowBalance != 0) {
                oraclePrice = Exp({mantissa: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(asset)});
            }

            // Sum up collateral in Eth
            if (cTokenBalance != 0) {

                (, uint collFactorMantissa) = comp.markets(address(asset));

                Exp memory collateralFactor = Exp({mantissa: collFactorMantissa});
                Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});

                (, Exp memory tokensToEther) = mulExp3(collateralFactor, exchangeRate, oraclePrice);

                (, sumCollateral) = mulScalarTruncateAddUInt(tokensToEther, cTokenBalance, sumCollateral);
            }

            // Sum up debt in Eth
            if (borrowBalance != 0) {
                (, sumBorrow) = mulScalarTruncateAddUInt(oraclePrice, borrowBalance, sumBorrow);
            }
        }

        if (sumBorrow == 0) return uint(-1);

        uint borrowPowerUsed = (sumBorrow * 10**18) / sumCollateral;
        return wdiv(1e18, borrowPowerUsed);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./CreamSafetyRatio.sol";
import "./helpers/CreamSaverHelper.sol";


/// @title Gets data about cream positions
contract CreamLoanInfo is CreamSafetyRatio {

    struct LoanData {
        address user;
        uint128 ratio;
        address[] collAddr;
        address[] borrowAddr;
        uint[] collAmounts;
        uint[] borrowAmounts;
    }

    struct TokenInfo {
        address cTokenAddress;
        address underlyingTokenAddress;
        uint collateralFactor;
        uint price;
    }

    struct TokenInfoFull {
        address underlyingTokenAddress;
        uint supplyRate;
        uint borrowRate;
        uint exchangeRate;
        uint marketLiquidity;
        uint totalSupply;
        uint totalBorrow;
        uint collateralFactor;
        uint price;
    }

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0xD06527D5e56A3495252A528C4987003b712860eE;


    /// @notice Calcualted the ratio of coll/debt for a cream user
    /// @param _user Address of the user
    function getRatio(address _user) public view returns (uint) {
        // For each asset the account is in
        return getSafetyRatio(_user);
    }

    /// @notice Fetches cream prices for tokens
    /// @param _cTokens Arr. of cTokens for which to get the prices
    /// @return prices Array of prices
    function getPrices(address[] memory _cTokens) public view returns (uint[] memory prices) {
        prices = new uint[](_cTokens.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokens.length; ++i) {
            prices[i] = CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokens[i]);
        }
    }

    /// @notice Fetches cream collateral factors for tokens
    /// @param _cTokens Arr. of cTokens for which to get the coll. factors
    /// @return collFactors Array of coll. factors
    function getCollFactors(address[] memory _cTokens) public view returns (uint[] memory collFactors) {
        collFactors = new uint[](_cTokens.length);

        for (uint i = 0; i < _cTokens.length; ++i) {
            (, collFactors[i]) = comp.markets(_cTokens[i]);
        }
    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in eth
    /// @param _user Address of the user
    /// @return data LoanData information
    function getLoanData(address _user) public view returns (LoanData memory data) {
        address[] memory assets = comp.getAssetsIn(_user);
        address oracleAddr = comp.oracle();

        data = LoanData({
            user: _user,
            ratio: 0,
            collAddr: new address[](assets.length),
            borrowAddr: new address[](assets.length),
            collAmounts: new uint[](assets.length),
            borrowAmounts: new uint[](assets.length)
        });

        uint collPos = 0;
        uint borrowPos = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory oraclePrice;

            if (cTokenBalance != 0 || borrowBalance != 0) {
                oraclePrice = Exp({mantissa: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(asset)});
            }

            // Sum up collateral in eth
            if (cTokenBalance != 0) {
                Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
                (, Exp memory tokensToEth) = mulExp(exchangeRate, oraclePrice);

                data.collAddr[collPos] = asset;
                (, data.collAmounts[collPos]) = mulScalarTruncate(tokensToEth, cTokenBalance);
                collPos++;
            }

            // Sum up debt in eth
            if (borrowBalance != 0) {
                data.borrowAddr[borrowPos] = asset;
                (, data.borrowAmounts[borrowPos]) = mulScalarTruncate(oraclePrice, borrowBalance);
                borrowPos++;
            }
        }

        data.ratio = uint128(getSafetyRatio(_user));

        return data;
    }

    function getTokenBalances(address _user, address[] memory _cTokens) public view returns (uint[] memory balances, uint[] memory borrows) {
        balances = new uint[](_cTokens.length);
        borrows = new uint[](_cTokens.length);

        for (uint i = 0; i < _cTokens.length; i++) {
            address asset = _cTokens[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
            (, balances[i]) = mulScalarTruncate(exchangeRate, cTokenBalance);

            borrows[i] = borrowBalance;
        }

    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in eth
    /// @param _users Addresses of the user
    /// @return loans Array of LoanData information
    function getLoanDataArr(address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_users[i]);
        }
    }

    /// @notice Calcualted the ratio of coll/debt for a cream user
    /// @param _users Addresses of the user
    /// @return ratios Array of ratios
    function getRatios(address[] memory _users) public view returns (uint[] memory ratios) {
        ratios = new uint[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            ratios[i] = getSafetyRatio(_users[i]);
        }
    }

    /// @notice Information about cTokens
    /// @param _cTokenAddresses Array of cTokens addresses
    /// @return tokens Array of cTokens infomartion
    function getTokensInfo(address[] memory _cTokenAddresses) public returns(TokenInfo[] memory tokens) {
        tokens = new TokenInfo[](_cTokenAddresses.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokenAddresses.length; ++i) {
            (, uint collFactor) = comp.markets(_cTokenAddresses[i]);

            tokens[i] = TokenInfo({
                cTokenAddress: _cTokenAddresses[i],
                underlyingTokenAddress: getUnderlyingAddr(_cTokenAddresses[i]),
                collateralFactor: collFactor,
                price: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokenAddresses[i])
            });
        }
    }

    /// @notice Information about cTokens
    /// @param _cTokenAddresses Array of cTokens addresses
    /// @return tokens Array of cTokens infomartion
    function getFullTokensInfo(address[] memory _cTokenAddresses) public returns(TokenInfoFull[] memory tokens) {
        tokens = new TokenInfoFull[](_cTokenAddresses.length);
        address oracleAddr = comp.oracle();

        for (uint i = 0; i < _cTokenAddresses.length; ++i) {
            (, uint collFactor) = comp.markets(_cTokenAddresses[i]);
            CTokenInterface cToken = CTokenInterface(_cTokenAddresses[i]);

            tokens[i] = TokenInfoFull({
                underlyingTokenAddress: getUnderlyingAddr(_cTokenAddresses[i]),
                supplyRate: cToken.supplyRatePerBlock(),
                borrowRate: cToken.borrowRatePerBlock(),
                exchangeRate: cToken.exchangeRateCurrent(),
                marketLiquidity: cToken.getCash(),
                totalSupply: cToken.totalSupply(),
                totalBorrow: cToken.totalBorrowsCurrent(),
                collateralFactor: collFactor,
                price: CompoundOracleInterface(oracleAddr).getUnderlyingPrice(_cTokenAddresses[i])
            });
        }
    }

    /// @notice Returns the underlying address of the cToken asset
    /// @param _cTokenAddress cToken address
    /// @return Token address of the cToken specified
    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }
}

pragma solidity ^0.6.0;

import "../utils/GasBurner.sol";
import "../utils/SafeERC20.sol";
import "../interfaces/CTokenInterface.sol";
import "../interfaces/CEtherInterface.sol";
import "../interfaces/ComptrollerInterface.sol";

/// @title Basic cream interactions through the DSProxy
contract CreamBasicProxy is GasBurner {

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant COMPTROLLER_ADDR = 0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258;

    using SafeERC20 for ERC20;

    /// @notice User deposits tokens to the cream protocol
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _cTokenAddr CTokens to be deposited
    /// @param _amount Amount of tokens to be deposited
    /// @param _inMarket True if the token is already in market for that address
    function deposit(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket) public burnGas(5) payable {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
        }

        approveToken(_tokenAddr, _cTokenAddr);

        if (!_inMarket) {
            enterMarket(_cTokenAddr);
        }

        if (_tokenAddr != ETH_ADDR) {
            require(CTokenInterface(_cTokenAddr).mint(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).mint{value: msg.value}(); // reverts on fail
        }
    }

    /// @notice User withdraws tokens to the cream protocol
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _cTokenAddr CTokens to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn
    /// @param _isCAmount If true _amount is cTokens if falls _amount is underlying tokens
    function withdraw(address _tokenAddr, address _cTokenAddr, uint _amount, bool _isCAmount) public burnGas(5) {

        if (_isCAmount) {
            require(CTokenInterface(_cTokenAddr).redeem(_amount) == 0);
        } else {
            require(CTokenInterface(_cTokenAddr).redeemUnderlying(_amount) == 0);
        }

        // withdraw funds to msg.sender
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, ERC20(_tokenAddr).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }

    }

    /// @notice User borrows tokens to the cream protocol
    /// @param _tokenAddr The address of the token to be borrowed
    /// @param _cTokenAddr CTokens to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    /// @param _inMarket True if the token is already in market for that address
    function borrow(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket) public burnGas(8) {
        if (!_inMarket) {
            enterMarket(_cTokenAddr);
        }

        require(CTokenInterface(_cTokenAddr).borrow(_amount) == 0);

        // withdraw funds to msg.sender
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, ERC20(_tokenAddr).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the cream protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _cTokenAddr CTokens to be paybacked
    /// @param _amount Amount of tokens to be payedback
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function payback(address _tokenAddr, address _cTokenAddr, uint _amount, bool _wholeDebt) public burnGas(5) payable {
        approveToken(_tokenAddr, _cTokenAddr);

        if (_wholeDebt) {
            _amount = CTokenInterface(_cTokenAddr).borrowBalanceCurrent(address(this));
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);

            require(CTokenInterface(_cTokenAddr).repayBorrow(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).repayBorrow{value: msg.value}();
            msg.sender.transfer(address(this).balance); // send back the extra eth
        }
    }

    /// @notice Helper method to withdraw tokens from the DSProxy
    /// @param _tokenAddr Address of the token to be withdrawn
    function withdrawTokens(address _tokenAddr) public {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, ERC20(_tokenAddr).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @notice Enters the cream market so it can be deposited/borrowed
    /// @param _cTokenAddr CToken address of the token
    function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);
    }

    /// @notice Exits the cream market so it can't be deposited/borrowed
    /// @param _cTokenAddr CToken address of the token
    function exitMarket(address _cTokenAddr) public {
        ComptrollerInterface(COMPTROLLER_ADDR).exitMarket(_cTokenAddr);
    }

    /// @notice Approves CToken contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _cTokenAddr Address which will gain the approval
    function approveToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeApprove(_cTokenAddr, uint(-1));
        }
    }
}

pragma solidity ^0.6.0;

import "../utils/GasBurner.sol";
import "../utils/SafeERC20.sol";
import "../interfaces/CTokenInterface.sol";
import "../interfaces/CEtherInterface.sol";
import "../interfaces/ComptrollerInterface.sol";

/// @title Basic compound interactions through the DSProxy
contract CompoundBasicProxy is GasBurner {

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    using SafeERC20 for ERC20;

    /// @notice User deposits tokens to the Compound protocol
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _cTokenAddr CTokens to be deposited
    /// @param _amount Amount of tokens to be deposited
    /// @param _inMarket True if the token is already in market for that address
    function deposit(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket) public burnGas(5) payable {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
        }

        approveToken(_tokenAddr, _cTokenAddr);

        if (!_inMarket) {
            enterMarket(_cTokenAddr);
        }

        if (_tokenAddr != ETH_ADDR) {
            require(CTokenInterface(_cTokenAddr).mint(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).mint{value: msg.value}(); // reverts on fail
        }
    }

    /// @notice User withdraws tokens to the Compound protocol
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _cTokenAddr CTokens to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn
    /// @param _isCAmount If true _amount is cTokens if falls _amount is underlying tokens
    function withdraw(address _tokenAddr, address _cTokenAddr, uint _amount, bool _isCAmount) public burnGas(5) {

        if (_isCAmount) {
            require(CTokenInterface(_cTokenAddr).redeem(_amount) == 0);
        } else {
            require(CTokenInterface(_cTokenAddr).redeemUnderlying(_amount) == 0);
        }

        // withdraw funds to msg.sender
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, ERC20(_tokenAddr).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }

    }

    /// @notice User borrows tokens to the Compound protocol
    /// @param _tokenAddr The address of the token to be borrowed
    /// @param _cTokenAddr CTokens to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    /// @param _inMarket True if the token is already in market for that address
    function borrow(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket) public burnGas(8) {
        if (!_inMarket) {
            enterMarket(_cTokenAddr);
        }

        require(CTokenInterface(_cTokenAddr).borrow(_amount) == 0);

        // withdraw funds to msg.sender
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, ERC20(_tokenAddr).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Compound protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _cTokenAddr CTokens to be paybacked
    /// @param _amount Amount of tokens to be payedback
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function payback(address _tokenAddr, address _cTokenAddr, uint _amount, bool _wholeDebt) public burnGas(5) payable {
        approveToken(_tokenAddr, _cTokenAddr);

        if (_wholeDebt) {
            _amount = CTokenInterface(_cTokenAddr).borrowBalanceCurrent(address(this));
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);

            require(CTokenInterface(_cTokenAddr).repayBorrow(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).repayBorrow{value: msg.value}();
            msg.sender.transfer(address(this).balance); // send back the extra eth
        }
    }

    /// @notice Helper method to withdraw tokens from the DSProxy
    /// @param _tokenAddr Address of the token to be withdrawn
    function withdrawTokens(address _tokenAddr) public {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, ERC20(_tokenAddr).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @notice Enters the Compound market so it can be deposited/borrowed
    /// @param _cTokenAddr CToken address of the token
    function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);
    }

    /// @notice Exits the Compound market so it can't be deposited/borrowed
    /// @param _cTokenAddr CToken address of the token
    function exitMarket(address _cTokenAddr) public {
        ComptrollerInterface(COMPTROLLER_ADDR).exitMarket(_cTokenAddr);
    }

    /// @notice Approves CToken contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _cTokenAddr Address which will gain the approval
    function approveToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeApprove(_cTokenAddr, uint(-1));
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./CompBalance.sol";
import "../../exchangeV3/DFSExchangeCore.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../CompoundBasicProxy.sol";

contract CompLeverage is DFSExchangeCore, CompBalance {
    address public constant C_COMP_ADDR = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;
    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Should claim COMP and sell it to the specified token and deposit it back
    /// @param exchangeData Standard Exchange struct
    /// @param _cTokensSupply List of cTokens user is supplying
    /// @param _cTokensBorrow List of cTokens user is borrowing
    /// @param _cDepositAddr The cToken address of the asset you want to deposit
    /// @param _inMarket Flag if the cToken is used as collateral
    function claimAndSell(
        ExchangeData memory exchangeData,
        address[] memory _cTokensSupply,
        address[] memory _cTokensBorrow,
        address _cDepositAddr,
        bool _inMarket
    ) public payable {
        // Claim COMP token
        _claim(address(this), _cTokensSupply, _cTokensBorrow);

        uint compBalance = ERC20(COMP_ADDR).balanceOf(address(this));
        uint depositAmount = 0;

        // Exchange COMP
        if (exchangeData.srcAddr != address(0)) {
            exchangeData.user = msg.sender;
            exchangeData.dfsFeeDivider = 400; // 0.25%
            exchangeData.srcAmount = compBalance;

            (, depositAmount) = _sell(exchangeData);

            // if we have no deposit after, send back tokens to the user
            if (_cDepositAddr == address(0)) {
                if (exchangeData.destAddr != ETH_ADDRESS) {
                    ERC20(exchangeData.destAddr).safeTransfer(msg.sender, depositAmount);
                } else {
                    msg.sender.transfer(address(this).balance);
                }
            }
        }

        // Deposit back a token
        if (_cDepositAddr != address(0)) {
            // if we are just depositing COMP without a swap
            if (_cDepositAddr == C_COMP_ADDR) {
                depositAmount = compBalance;
            }

            address tokenAddr = getUnderlyingAddr(_cDepositAddr);
            deposit(tokenAddr, _cDepositAddr, depositAmount, _inMarket);
        }

        logger.Log(address(this), msg.sender, "CompLeverage", abi.encode(compBalance, depositAmount, _cDepositAddr, exchangeData.destAmount));
    }

    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    function deposit(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket) public burnGas(5) payable {
        approveToken(_tokenAddr, _cTokenAddr);

        if (!_inMarket) {
            enterMarket(_cTokenAddr);
        }

        if (_tokenAddr != ETH_ADDRESS) {
            require(CTokenInterface(_cTokenAddr).mint(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).mint{value: _amount}(); // reverts on fail
        }
    }

     function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);
    }

    function approveToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).safeApprove(_cTokenAddr, uint(-1));
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../helpers/Exponential.sol";
import "../../utils/SafeERC20.sol";
import "../../utils/GasBurner.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ComptrollerInterface.sol";

contract CompBalance is Exponential, GasBurner {
    ComptrollerInterface public constant comp = ComptrollerInterface(
        0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
    );
    address public constant COMP_ADDR = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    uint224 public constant compInitialIndex = 1e36;

    function claimComp(
        address _user,
        address[] memory _cTokensSupply,
        address[] memory _cTokensBorrow
    ) public burnGas(8) {
        _claim(_user, _cTokensSupply, _cTokensBorrow);

        ERC20(COMP_ADDR).transfer(msg.sender, ERC20(COMP_ADDR).balanceOf(address(this)));
    }

    function _claim(
        address _user,
        address[] memory _cTokensSupply,
        address[] memory _cTokensBorrow
    ) internal {
        address[] memory u = new address[](1);
        u[0] = _user;

        comp.claimComp(u, _cTokensSupply, false, true);
        comp.claimComp(u, _cTokensBorrow, true, false);
    }

    function getBalance(address _user, address[] memory _cTokens) public view returns (uint256) {
        uint256 compBalance = 0;

        for (uint256 i = 0; i < _cTokens.length; ++i) {
            compBalance += getSuppyBalance(_cTokens[i], _user);
            compBalance += getBorrowBalance(_cTokens[i], _user);
        }

        compBalance = add_(comp.compAccrued(_user), compBalance);

        compBalance += ERC20(COMP_ADDR).balanceOf(_user);

        return compBalance;
    }

    function getClaimableAssets(address[] memory _cTokens, address _user)
        public
        view
        returns (bool[] memory supplyClaims, bool[] memory borrowClaims)
    {
        supplyClaims = new bool[](_cTokens.length);
        borrowClaims = new bool[](_cTokens.length);

        for (uint256 i = 0; i < _cTokens.length; ++i) {
            supplyClaims[i] = getSuppyBalance(_cTokens[i], _user) > 0;
            borrowClaims[i] = getBorrowBalance(_cTokens[i], _user) > 0;
        }
    }

    function getSuppyBalance(address _cToken, address _supplier)
        public
        view
        returns (uint256 supplierAccrued)
    {
        ComptrollerInterface.CompMarketState memory supplyState = comp.compSupplyState(_cToken);
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({
            mantissa: comp.compSupplierIndex(_cToken, _supplier)
        });

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = compInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint256 supplierTokens = CTokenInterface(_cToken).balanceOf(_supplier);
        uint256 supplierDelta = mul_(supplierTokens, deltaIndex);
        supplierAccrued = supplierDelta;
    }

    function getBorrowBalance(address _cToken, address _borrower)
        public
        view
        returns (uint256 borrowerAccrued)
    {
        ComptrollerInterface.CompMarketState memory borrowState = comp.compBorrowState(_cToken);
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({
            mantissa: comp.compBorrowerIndex(_cToken, _borrower)
        });

        Exp memory marketBorrowIndex = Exp({mantissa: CTokenInterface(_cToken).borrowIndex()});

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint256 borrowerAmount = div_(
                CTokenInterface(_cToken).borrowBalanceStored(_borrower),
                marketBorrowIndex
            );
            uint256 borrowerDelta = mul_(borrowerAmount, deltaIndex);
            borrowerAccrued = borrowerDelta;
        }
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/ERC20.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ComptrollerInterface.sol";
import "../../utils/SafeERC20.sol";

contract CompoundBorrowProxy {

    using SafeERC20 for ERC20;

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    function borrow(address _cCollToken, address _cBorrowToken, address _borrowToken, uint _amount) public {
        address[] memory markets = new address[](2);
        markets[0] = _cCollToken;
        markets[1] = _cBorrowToken;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);

        require(CTokenInterface(_cBorrowToken).borrow(_amount) == 0);

        // withdraw funds to msg.sender
        if (_borrowToken != ETH_ADDR) {
            ERC20(_borrowToken).safeTransfer(msg.sender, ERC20(_borrowToken).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../auth/AdminAuth.sol";
import "./SaverExchange.sol";
import "../utils/SafeERC20.sol";

contract AllowanceProxy is AdminAuth {

    using SafeERC20 for ERC20;

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // TODO: Real saver exchange address
    SaverExchange saverExchange = SaverExchange(0x235abFAd01eb1BDa28Ef94087FBAA63E18074926);

    function callSell(SaverExchangeCore.ExchangeData memory exData) public payable {
        pullAndSendTokens(exData.srcAddr, exData.srcAmount);

        saverExchange.sell{value: msg.value}(exData, msg.sender);
    }

    function callBuy(SaverExchangeCore.ExchangeData memory exData) public payable {
        pullAndSendTokens(exData.srcAddr, exData.srcAmount);

        saverExchange.buy{value: msg.value}(exData, msg.sender);
    }

    function pullAndSendTokens(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount, "msg.value smaller than amount");
        } else {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(saverExchange), _amount);
        }
    }

    function ownerChangeExchange(address payable _newExchange) public onlyOwner {
        saverExchange = SaverExchange(_newExchange);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../exchange/SaverExchangeCore.sol";
import "../../loggers/DefisaverLogger.sol";
import "../helpers/CreamSaverHelper.sol";

/// @title Contract that implements repay/boost functionality
contract CreamSaverProxy is CreamSaverHelper, SaverExchangeCore {

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Withdraws collateral, converts to borrowed token and repays debt
    /// @dev Called through the DSProxy
    /// @param _exData Exchange data
    /// @param _cAddresses Coll/Debt addresses [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    function repay(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());

        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));

        uint collAmount = (_exData.srcAmount > maxColl) ? maxColl : _exData.srcAmount;

        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(collAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            (, swapAmount) = _sell(_exData);
            swapAmount -= getFee(swapAmount, user, _gasCost, _cAddresses[1]);
        } else {
            swapAmount = collAmount;
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        paybackDebt(swapAmount, _cAddresses[1], borrowToken, user);

        // handle 0x fee
        tx.origin.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        logger.Log(address(this), msg.sender, "CreamRepay", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Borrows token, converts to collateral, and adds to position
    /// @dev Called through the DSProxy
    /// @param _exData Exchange data
    /// @param _cAddresses Coll/Debt addresses [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    function boost(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());

        uint maxBorrow = getMaxBorrow(_cAddresses[1], address(this));
        uint borrowAmount = (_exData.srcAmount > maxBorrow) ? maxBorrow : _exData.srcAmount;

        require(CTokenInterface(_cAddresses[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            borrowAmount -= getFee(borrowAmount, user, _gasCost, _cAddresses[1]);

            _exData.srcAmount = borrowAmount;
            (,swapAmount) = _sell(_exData);
        } else {
            swapAmount = borrowAmount;
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        approveCToken(collToken, _cAddresses[0]);

        if (collToken != ETH_ADDRESS) {
            require(CTokenInterface(_cAddresses[0]).mint(swapAmount) == 0);
        } else {
            CEtherInterface(_cAddresses[0]).mint{value: swapAmount}(); // reverts on fail
        }

        // handle 0x fee
        tx.origin.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        logger.Log(address(this), msg.sender, "CreamBoost", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../interfaces/ILendingPool.sol";
import "./CreamSaverProxy.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../auth/ProxyPermission.sol";

/// @title Entry point for the FL Repay Boosts, called by DSProxy
contract CreamFlashLoanTaker is CreamSaverProxy, ProxyPermission, GasBurner {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_SAVER_FLASH_LOAN = 0x3ceD2067c0B057611e4E2686Dbe40028962Cc625;
    address public constant AAVE_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    /// @notice Repays the position with it's own fund or with FL if needed
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _gasCost Gas cost for specific transaction
    function repayWithLoan(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable burnGas(25) {
        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));
        uint availableLiquidity = getAvailableLiquidity(_exData.srcAddr);

        if (_exData.srcAmount <= maxColl || availableLiquidity == 0) {
            repay(_exData, _cAddresses, _gasCost);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_exData.srcAmount - maxColl);
            bytes memory encoded = packExchangeData(_exData);
            bytes memory paramsData = abi.encode(encoded, _cAddresses, _gasCost, true, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_cAddresses[0]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.Log(address(this), msg.sender, "CreamFlashRepay", abi.encode(loanAmount, _exData.srcAmount, _cAddresses[0]));
        }
    }

    /// @notice Boosts the position with it's own fund or with FL if needed
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _gasCost Gas cost for specific transaction
    function boostWithLoan(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable burnGas(20) {
        uint maxBorrow = getMaxBorrow(_cAddresses[1], address(this));
        uint availableLiquidity = getAvailableLiquidity(_exData.srcAddr);

        if (_exData.srcAmount <= maxBorrow || availableLiquidity == 0) {
            boost(_exData, _cAddresses, _gasCost);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_exData.srcAmount - maxBorrow);
            bytes memory paramsData = abi.encode(packExchangeData(_exData), _cAddresses, _gasCost, false, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_cAddresses[1]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.Log(address(this), msg.sender, "CreamFlashBoost", abi.encode(loanAmount, _exData.srcAmount, _cAddresses[1]));
        }

    }

    function getAvailableLiquidity(address _tokenAddr) internal view returns (uint liquidity) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            liquidity = AAVE_POOL_CORE.balance;
        } else {
            liquidity = ERC20(_tokenAddr).balanceOf(AAVE_POOL_CORE);
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../interfaces/ILendingPool.sol";
import "./CompoundSaverProxy.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../auth/ProxyPermission.sol";

/// @title Entry point for the FL Repay Boosts, called by DSProxy
contract CompoundFlashLoanTaker is CompoundSaverProxy, ProxyPermission, GasBurner {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_SAVER_FLASH_LOAN = 0x819879d4725944b679371cE64474d3B92253cAb6;
    address public constant AAVE_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    /// @notice Repays the position with it's own fund or with FL if needed
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _gasCost Gas cost for specific transaction
    function repayWithLoan(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable burnGas(25) {
        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));
        uint availableLiquidity = getAvailableLiquidity(_exData.srcAddr);

        if (_exData.srcAmount <= maxColl || availableLiquidity == 0) {
            repay(_exData, _cAddresses, _gasCost);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_exData.srcAmount - maxColl);
            if (loanAmount > availableLiquidity) loanAmount = availableLiquidity;
            bytes memory encoded = packExchangeData(_exData);
            bytes memory paramsData = abi.encode(encoded, _cAddresses, _gasCost, true, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_cAddresses[0]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.Log(address(this), msg.sender, "CompoundFlashRepay", abi.encode(loanAmount, _exData.srcAmount, _cAddresses[0]));
        }
    }

    /// @notice Boosts the position with it's own fund or with FL if needed
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _gasCost Gas cost for specific transaction
    function boostWithLoan(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable burnGas(20) {
        uint maxBorrow = getMaxBorrow(_cAddresses[1], address(this));
        uint availableLiquidity = getAvailableLiquidity(_exData.srcAddr);

        if (_exData.srcAmount <= maxBorrow || availableLiquidity == 0) {
            boost(_exData, _cAddresses, _gasCost);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_exData.srcAmount - maxBorrow);
            if (loanAmount > availableLiquidity) loanAmount = availableLiquidity;
            bytes memory paramsData = abi.encode(packExchangeData(_exData), _cAddresses, _gasCost, false, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_cAddresses[1]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.Log(address(this), msg.sender, "CompoundFlashBoost", abi.encode(loanAmount, _exData.srcAmount, _cAddresses[1]));
        }

    }

    function getAvailableLiquidity(address _tokenAddr) internal view returns (uint liquidity) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            liquidity = AAVE_POOL_CORE.balance;
        } else {
            liquidity = ERC20(_tokenAddr).balanceOf(AAVE_POOL_CORE);
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../exchangeV3/DFSExchangeCore.sol";
import "../../loggers/DefisaverLogger.sol";
import "../helpers/CompoundSaverHelper.sol";

/// @title Contract that implements repay/boost functionality
contract CompoundSaverProxy is CompoundSaverHelper, DFSExchangeCore {

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Withdraws collateral, converts to borrowed token and repays debt
    /// @dev Called through the DSProxy
    /// @param _exData Exchange data
    /// @param _cAddresses Coll/Debt addresses [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    function repay(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());

        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));

        uint collAmount = (_exData.srcAmount > maxColl) ? maxColl : _exData.srcAmount;

        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(collAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            _exData.srcAmount = collAmount;
            _exData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
            _exData.user = user;

            (, swapAmount) = _sell(_exData);
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        } else {
            swapAmount = collAmount;
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        paybackDebt(swapAmount, _cAddresses[1], borrowToken, user);

        // handle 0x fee
        tx.origin.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        logger.Log(address(this), msg.sender, "CompoundRepay", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Borrows token, converts to collateral, and adds to position
    /// @dev Called through the DSProxy
    /// @param _exData Exchange data
    /// @param _cAddresses Coll/Debt addresses [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    function boost(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());

        uint maxBorrow = getMaxBorrow(_cAddresses[1], address(this));
        uint borrowAmount = (_exData.srcAmount > maxBorrow) ? maxBorrow : _exData.srcAmount;

        require(CTokenInterface(_cAddresses[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            _exData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
            _exData.user = user;

            _exData.srcAmount = borrowAmount;
            (, swapAmount) = _sell(_exData);

             swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        } else {
            swapAmount = borrowAmount;
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        approveCToken(collToken, _cAddresses[0]);

        if (collToken != ETH_ADDRESS) {
            require(CTokenInterface(_cAddresses[0]).mint(swapAmount) == 0);
        } else {
            CEtherInterface(_cAddresses[0]).mint{value: swapAmount}(); // reverts on fail
        }

        // handle 0x fee
        tx.origin.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        logger.Log(address(this), msg.sender, "CompoundBoost", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

}

pragma solidity ^0.6.0;

import "../../utils/GasBurner.sol";
import "../../auth/ProxyPermission.sol";

import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ILendingPool.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ProxyRegistryInterface.sol";

import "../helpers/CompoundSaverHelper.sol";

/// @title Imports Compound position from the account to DSProxy
contract CompoundImportTaker is CompoundSaverHelper, ProxyPermission, GasBurner {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_IMPORT_FLASH_LOAN = 0x1DB68Ba0B85800FD323387E8B69d9AE867e00B94;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must approve DSProxy to pull _cCollateralToken
    /// @param _cCollateralToken Collateral we are moving to DSProxy
    /// @param _cBorrowToken Borrow token we are moving to DSProxy
    function importLoan(address _cCollateralToken, address _cBorrowToken) external burnGas(20) {
        uint loanAmount = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(msg.sender);
        bytes memory paramsData = abi.encode(_cCollateralToken, _cBorrowToken, address(this));

        givePermission(COMPOUND_IMPORT_FLASH_LOAN);

        lendingPool.flashLoan(COMPOUND_IMPORT_FLASH_LOAN, getUnderlyingAddr(_cBorrowToken), loanAmount, paramsData);

        removePermission(COMPOUND_IMPORT_FLASH_LOAN);

        logger.Log(address(this), msg.sender, "CompoundImport", abi.encode(loanAmount, 0, _cCollateralToken));
    }
}

pragma solidity ^0.6.0;

import "../../auth/ProxyPermission.sol";
import "../../interfaces/ICompoundSubscription.sol";

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract CompoundSubscriptionsProxy is ProxyPermission {

    address public constant COMPOUND_SUBSCRIPTION_ADDRESS = 0x52015EFFD577E08f498a0CCc11905925D58D6207;
    address public constant COMPOUND_MONITOR_PROXY = 0xB1cF8DE8e791E4Ed1Bd86c03E2fc1f14389Cb10a;

    /// @notice Calls subscription contract and creates a DSGuard if non existent
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function subscribe(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        givePermission(COMPOUND_MONITOR_PROXY);
        ICompoundSubscription(COMPOUND_SUBSCRIPTION_ADDRESS).subscribe(
            _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls subscription contract and updated existing parameters
    /// @dev If subscription is non existent this will create one
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function update(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        ICompoundSubscription(COMPOUND_SUBSCRIPTION_ADDRESS).subscribe(_minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls the subscription contract to unsubscribe the caller
    function unsubscribe() public {
        removePermission(COMPOUND_MONITOR_PROXY);
        ICompoundSubscription(COMPOUND_SUBSCRIPTION_ADDRESS).unsubscribe();
    }
}

pragma solidity ^0.6.0;

abstract contract ICompoundSubscription {
    function subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled) public virtual;
    function unsubscribe() public virtual;
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../auth/AdminAuth.sol";
import "../../auth/ProxyPermission.sol";
import "../../utils/DydxFlashLoanBase.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../exchangeV3/DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
/// @dev Contract needs to have enough wei in WETH for all transactions (2 WETH wei per transaction)
contract AaveSaverTakerV2 is DydxFlashLoanBase, ProxyPermission, GasBurner, DFSExchangeData {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable public constant AAVE_RECEIVER = 0x5a7689F1452d57E92878e0c0Be47cA3525e8Fcc9;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    function repay(address _market, ExchangeData memory _data, uint _rateMode, uint256 _gasCost, uint _flAmount) public payable {
        _flashLoan(_market, _data, _rateMode,_gasCost, true, _flAmount);
    }

    function boost(address _market, ExchangeData memory _data, uint _rateMode, uint256 _gasCost, uint _flAmount) public payable {
        _flashLoan(_market, _data, _rateMode, _gasCost, false, _flAmount);
    }

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must send 2 wei with this transaction
    function _flashLoan(address _market, ExchangeData memory _data, uint _rateMode, uint _gasCost, bool _isRepay, uint _flAmount) internal {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        uint256 ethAmount = _flAmount;

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(ethAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, ethAmount, AAVE_RECEIVER);
        AAVE_RECEIVER.transfer(msg.value);
        bytes memory encodedData = packExchangeData(_data);
        operations[1] = _getCallAction(
            abi.encode(encodedData, _market, _rateMode, _gasCost, _isRepay, ethAmount, msg.value, proxyOwner(), address(this)),
            AAVE_RECEIVER
        );
        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        givePermission(AAVE_RECEIVER);
        solo.operate(accountInfos, operations);
        removePermission(AAVE_RECEIVER);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../auth/AdminAuth.sol";
import "../../auth/ProxyPermission.sol";
import "../../utils/DydxFlashLoanBase.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../interfaces/ERC20.sol";


/// @title Import Aave position from account to wallet
/// @dev Contract needs to have enough wei in WETH for all transactions (2 WETH wei per transaction)
contract AaveImportTakerV2 is DydxFlashLoanBase, ProxyPermission {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address payable public constant AAVE_IMPORT = 0x1C9B7FBD410Adcd213C5d6CBA12e651300061eaD;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must send 2 wei with this transaction
    /// @dev User must approve DSProxy to pull _aCollateralToken
    /// @param _market Market in which we want to import
    /// @param _collateralToken Collateral token we are moving to DSProxy
    /// @param _borrowToken Borrow token we are moving to DSProxy
    /// @param _ethAmount ETH amount that needs to be pulled from dydx
    function importLoan(address _market, address _collateralToken, address _borrowToken, uint _ethAmount) public {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_ethAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _ethAmount, AAVE_IMPORT);
        operations[1] = _getCallAction(
            abi.encode(_market, _collateralToken, _borrowToken, _ethAmount, address(this)),
            AAVE_IMPORT
        );
        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        givePermission(AAVE_IMPORT);
        solo.operate(accountInfos, operations);
        removePermission(AAVE_IMPORT);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveImport", abi.encode(_collateralToken, _borrowToken));
    }
}

pragma solidity ^0.6.0;

import "../../auth/ProxyPermission.sol";
import "../../interfaces/IAaveSubscription.sol";

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract AaveSubscriptionsProxyV2 is ProxyPermission {

    string public constant NAME = "AaveSubscriptionsProxyV2";

    address public constant AAVE_SUBSCRIPTION_ADDRESS = 0x6B25043BF08182d8e86056C6548847aF607cd7CD;
    address public constant AAVE_MONITOR_PROXY = 0x380982902872836ceC629171DaeAF42EcC02226e;

    /// @notice Calls subscription contract and creates a DSGuard if non existent
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function subscribe(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        givePermission(AAVE_MONITOR_PROXY);
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).subscribe(
            _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls subscription contract and updated existing parameters
    /// @dev If subscription is non existent this will create one
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function update(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).subscribe(_minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls the subscription contract to unsubscribe the caller
    function unsubscribe() public {
        removePermission(AAVE_MONITOR_PROXY);
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).unsubscribe();
    }
}

pragma solidity ^0.6.0;

abstract contract IAaveSubscription {
    function subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled) public virtual;
    function unsubscribe() public virtual;
}

pragma solidity ^0.6.0;

import "../../auth/ProxyPermission.sol";
import "../../interfaces/IAaveSubscription.sol";

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract AaveSubscriptionsProxy is ProxyPermission {

    address public constant AAVE_SUBSCRIPTION_ADDRESS = 0xe08ff7A2BADb634F0b581E675E6B3e583De086FC;
    address public constant AAVE_MONITOR_PROXY = 0xfA560Dba3a8D0B197cA9505A2B98120DD89209AC;

    /// @notice Calls subscription contract and creates a DSGuard if non existent
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function subscribe(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        givePermission(AAVE_MONITOR_PROXY);
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).subscribe(
            _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls subscription contract and updated existing parameters
    /// @dev If subscription is non existent this will create one
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function update(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).subscribe(_minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls the subscription contract to unsubscribe the caller
    function unsubscribe() public {
        removePermission(AAVE_MONITOR_PROXY);
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).unsubscribe();
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../auth/AdminAuth.sol";
import "../../auth/ProxyPermission.sol";
import "../../utils/DydxFlashLoanBase.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../exchangeV3/DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
/// @dev Contract needs to have enough wei in WETH for all transactions (2 WETH wei per transaction)
contract AaveSaverTaker is DydxFlashLoanBase, ProxyPermission, GasBurner, DFSExchangeData {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable public constant AAVE_RECEIVER = 0xf5AE5851288365CAB81283716575Ea6685FD0545;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    function repay(ExchangeData memory _data, uint256 _gasCost) public payable {
        _flashLoan(_data, _gasCost, true);
    }

    function boost(ExchangeData memory _data, uint256 _gasCost) public payable {
        _flashLoan(_data, _gasCost, false);
    }

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must send 2 wei with this transaction
    function _flashLoan(ExchangeData memory _data, uint _gasCost, bool _isRepay) internal {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        uint256 ethAmount = ERC20(WETH_ADDR).balanceOf(SOLO_MARGIN_ADDRESS);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(ethAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, ethAmount, AAVE_RECEIVER);
        AAVE_RECEIVER.transfer(msg.value);
        bytes memory encodedData = packExchangeData(_data);
        operations[1] = _getCallAction(
            abi.encode(encodedData, _gasCost, _isRepay, ethAmount, msg.value, proxyOwner(), address(this)),
            AAVE_RECEIVER
        );
        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        givePermission(AAVE_RECEIVER);
        solo.operate(accountInfos, operations);
        removePermission(AAVE_RECEIVER);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../auth/AdminAuth.sol";
import "../../auth/ProxyPermission.sol";
import "../../utils/DydxFlashLoanBase.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../interfaces/ERC20.sol";


/// @title Import Aave position from account to wallet
/// @dev Contract needs to have enough wei in WETH for all transactions (2 WETH wei per transaction)
contract AaveImportTaker is DydxFlashLoanBase, ProxyPermission {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address payable public constant AAVE_IMPORT = 0x5cD4239D2AA5b487bA87c3715127eA53685B4926;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must send 2 wei with this transaction
    /// @dev User must approve DSProxy to pull _aCollateralToken
    /// @param _collateralToken Collateral token we are moving to DSProxy
    /// @param _borrowToken Borrow token we are moving to DSProxy
    /// @param _ethAmount ETH amount that needs to be pulled from dydx
    function importLoan(address _collateralToken, address _borrowToken, uint _ethAmount) public {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_ethAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _ethAmount, AAVE_IMPORT);
        operations[1] = _getCallAction(
            abi.encode(_collateralToken, _borrowToken, _ethAmount, address(this)),
            AAVE_IMPORT
        );
        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        givePermission(AAVE_IMPORT);
        solo.operate(accountInfos, operations);
        removePermission(AAVE_IMPORT);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveImport", abi.encode(_collateralToken, _borrowToken));
    }
}

pragma solidity ^0.6.0;

import "../../DS/DSGuard.sol";
import "../../DS/DSAuth.sol";

contract SubscriptionsInterfaceV2 {
    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled, bool _nextPriceEnabled) external {}
    function unsubscribe(uint _cdpId) external {}
}

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract SubscriptionsProxyV2 {

    address public constant MONITOR_PROXY_ADDRESS = 0x1816A86C4DA59395522a42b871bf11A4E96A1C7a;
    address public constant OLD_SUBSCRIPTION = 0x83152CAA0d344a2Fd428769529e2d490A88f4393;
    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    function migrate(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled, bool _nextPriceEnabled, address _subscriptions) public {
        SubscriptionsInterfaceV2(OLD_SUBSCRIPTION).unsubscribe(_cdpId);

        subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled, _nextPriceEnabled, _subscriptions);
    }

    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled, bool _nextPriceEnabled, address _subscriptions) public {

        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(MONITOR_PROXY_ADDRESS, address(this), bytes4(keccak256("execute(address,bytes)")));

        SubscriptionsInterfaceV2(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled, _nextPriceEnabled);
    }

    function update(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled, bool _nextPriceEnabled, address _subscriptions) public {
        SubscriptionsInterfaceV2(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled, _nextPriceEnabled);
    }

    function unsubscribe(uint _cdpId, address _subscriptions) public {
        SubscriptionsInterfaceV2(_subscriptions).unsubscribe(_cdpId);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../../exchangeV3/DFSExchangeData.sol";

/// @title Contract that receives the FL from Aave for Repays/Boost
contract CompoundSaverFlashLoan is FlashLoanReceiverBase, DFSExchangeData {
    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address payable public COMPOUND_SAVER_FLASH_PROXY = 0xcaB974d1702a056e6FF16f1DaA34646E41Ef485E;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public owner;

    using SafeERC20 for ERC20;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
            owner = msg.sender;
    }

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
   function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {
        // Format the call data for DSProxy
        (bytes memory proxyData, address payable proxyAddr) = packFunctionCall(_amount, _fee, _params);

        // Send Flash loan amount to DSProxy
        sendLoanToProxy(proxyAddr, _reserve, _amount);

        // Execute the DSProxy call
        DSProxyInterface(proxyAddr).execute(COMPOUND_SAVER_FLASH_PROXY, proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    /// @notice Formats function data call so we can call it through DSProxy
    /// @param _amount Amount of FL
    /// @param _fee Fee of the FL
    /// @param _params Saver proxy params
    /// @return proxyData Formated function call data
    function packFunctionCall(uint _amount, uint _fee, bytes memory _params) internal pure returns (bytes memory proxyData, address payable) {
        (
            bytes memory exDataBytes,
            address[2] memory cAddresses, // cCollAddress, cBorrowAddress
            uint256 gasCost,
            bool isRepay,
            address payable proxyAddr
        )
        = abi.decode(_params, (bytes,address[2],uint256,bool,address));

        ExchangeData memory _exData = unpackExchangeData(exDataBytes);

        uint[2] memory flashLoanData = [_amount, _fee];

        if (isRepay) {
            proxyData = abi.encodeWithSignature("flashRepay((address,address,uint256,uint256,uint256,address,address,bytes,uint256),address[2],uint256,uint256[2])", _exData, cAddresses, gasCost, flashLoanData);
        } else {
            proxyData = abi.encodeWithSignature("flashBoost((address,address,uint256,uint256,uint256,address,address,bytes,uint256),address[2],uint256,uint256[2])", _exData, cAddresses, gasCost, flashLoanData);
        }

        return (proxyData, proxyAddr);
    }

    /// @notice Send the FL funds received to DSProxy
    /// @param _proxy DSProxy address
    /// @param _reserve Token address
    /// @param _amount Amount of tokens
    function sendLoanToProxy(address payable _proxy, address _reserve, uint _amount) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, _amount);
        }

        _proxy.transfer(address(this).balance);
    }

    receive() external override(FlashLoanReceiverBase) payable {}
}

pragma solidity ^0.6.0;

import "../../auth/AdminAuth.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../utils/SafeERC20.sol";

/// @title Receives FL from Aave and imports the position to DSProxy
contract CompoundImportFlashLoan is FlashLoanReceiverBase, AdminAuth {
    using SafeERC20 for ERC20;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER =
        ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant COMPOUND_BORROW_PROXY = 0xb7EDC39bE76107e2Cc645f0f6a3D164f5e173Ee2;
    address public constant PULL_TOKENS_PROXY = 0x45431b79F783e0BF0fe7eF32D06A3e061780bfc4;

    // solhint-disable-next-line no-empty-blocks
    constructor() public FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) {}

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        (address cCollAddr, address cBorrowAddr, address proxy) =
            abi.decode(_params, (address, address, address));

        address user = DSProxyInterface(proxy).owner();
        uint256 usersCTokenBalance = CTokenInterface(cCollAddr).balanceOf(user);

        if (_reserve != EthAddressLib.ethAddress()) {
            // approve FL tokens so we can repay them
            ERC20(_reserve).safeApprove(cBorrowAddr, _amount);

            // repay compound debt on behalf of the user
            require(
                CTokenInterface(cBorrowAddr).repayBorrowBehalf(user, uint256(-1)) == 0,
                "Repay borrow behalf fail"
            );
        } else {
            CTokenInterface(cBorrowAddr).repayBorrow{value: _amount}(); // reverts on fail
        }

        bytes memory depositProxyCallData = formatDSProxyPullTokensCall(cCollAddr, usersCTokenBalance);
        DSProxyInterface(proxy).execute(PULL_TOKENS_PROXY, depositProxyCallData);

        // borrow debt now on ds proxy
        bytes memory borrowProxyCallData =
            formatDSProxyBorrowCall(cCollAddr, cBorrowAddr, _reserve, (_amount + _fee));
        DSProxyInterface(proxy).execute(COMPOUND_BORROW_PROXY, borrowProxyCallData);

        // repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    /// @notice Formats function data call to pull tokens to DSProxy
    /// @param _cTokenAddr CToken address of the collateral
    /// @param _amount Amount of cTokens to pull
    function formatDSProxyPullTokensCall(
        address _cTokenAddr,
        uint256 _amount
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "pullTokens(address,uint256)",
            _cTokenAddr,
            _amount
        );
    }

    /// @notice Formats function data call borrow through DSProxy
    /// @param _cCollToken CToken address of collateral
    /// @param _cBorrowToken CToken address we will borrow
    /// @param _borrowToken Token address we will borrow
    /// @param _amount Amount that will be borrowed
    function formatDSProxyBorrowCall(
        address _cCollToken,
        address _cBorrowToken,
        address _borrowToken,
        uint256 _amount
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "borrow(address,address,address,uint256)",
            _cCollToken,
            _cBorrowToken,
            _borrowToken,
            _amount
        );
    }
}

pragma solidity ^0.6.0;

import "../../interfaces/OsmMom.sol";
import "../../interfaces/Osm.sol";
import "../../auth/AdminAuth.sol";
import "../../interfaces/Manager.sol";

contract MCDPriceVerifier is AdminAuth {

    OsmMom public osmMom = OsmMom(0x76416A4d5190d071bfed309861527431304aA14f);
    Manager public manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    mapping(address => bool) public authorized;

    function verifyVaultNextPrice(uint _nextPrice, uint _cdpId) public view returns(bool) {
        require(authorized[msg.sender]);

        bytes32 ilk = manager.ilks(_cdpId);

        return verifyNextPrice(_nextPrice, ilk);
    }

    function verifyNextPrice(uint _nextPrice, bytes32 _ilk) public view returns(bool) {
        require(authorized[msg.sender]);

        address osmAddress = osmMom.osms(_ilk);

        uint whitelisted = Osm(osmAddress).bud(address(this));
        // If contracts doesn't have access return true
        if (whitelisted != 1) return true;

        (bytes32 price, bool has) = Osm(osmAddress).peep();

        return has ? uint(price) == _nextPrice : false;
    }

    function setAuthorized(address _address, bool _allowed) public onlyOwner {
        authorized[_address] = _allowed;
    }
}

pragma solidity ^0.6.0;


abstract contract OsmMom {
    mapping (bytes32 => address) public osms;
}

pragma solidity ^0.6.0;


abstract contract Osm {
    mapping(address => uint256) public bud;

    function peep() external view virtual returns (bytes32, bool);
}

pragma solidity ^0.6.0;

import "./ERC20.sol";

//TODO: currenlty only adjusted to kyber, but should be genric interfaces for more dec. exchanges
interface ExchangeInterface {
    function swapEtherToToken(uint256 _ethAmount, address _tokenAddress, uint256 _maxAmount)
        external
        payable
        returns (uint256, uint256);

    function swapTokenToEther(address _tokenAddress, uint256 _amount, uint256 _maxAmount)
        external
        returns (uint256);

    function swapTokenToToken(address _src, address _dest, uint256 _amount)
        external
        payable
        returns (uint256);

    function getExpectedRate(address src, address dest, uint256 srcQty)
        external
        view
        returns (uint256 expectedRate);
}

