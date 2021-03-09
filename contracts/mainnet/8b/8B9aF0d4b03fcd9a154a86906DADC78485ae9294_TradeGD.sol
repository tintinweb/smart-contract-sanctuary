//SPDX-License-Identifier: MIT

pragma solidity >=0.6;

pragma experimental ABIEncoderV2;

interface cERC20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeemUnderlying(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 cTokenAmount) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address addr) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferAndCall(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}

interface Staking {
    struct Staker {
        // The staked DAI amount
        uint256 stakedDAI;
        // The latest block number which the
        // staker has staked tokens
        uint256 lastStake;
    }

    function stakeDAI(uint256 amount) external;

    function withdrawStake() external;

    function stakers(address staker) external view returns (Staker memory);
}

interface Uniswap {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

interface Reserve {
    function buy(
        address _buyWith,
        uint256 _tokenAmount,
        uint256 _minReturn
    ) external returns (uint256);

    function sell(
        address _sellWith,
        uint256 _tokenAmount,
        uint256 _minReturn
    ) external returns (uint256);
}

interface AmbBridge {
    function relayTokens(
        address token,
        address receiver,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Interfaces.sol";

contract TradeGD is OwnableUpgradeable {
    Uniswap public uniswap;
    cERC20 public GD;
    cERC20 public DAI;
    cERC20 public cDAI;
    Reserve public reserve;

    address public gdBridge;
    address public omniBridge;

    event GDTraded(
        string protocol,
        string action,
        address from,
        uint256 value,
        uint256[] uniswap,
        uint256 gd
    );

    /**
     * @dev initialize the upgradable contract
     * @param _gd address of the GoodDollar token
     * @param _dai address of the DAI token
     * @param _cdai address of the cDAI token
     * @param _reserve address of the GoodDollar reserve
     */
    function initialize(
        address _gd,
        address _dai,
        address _cdai,
        address _reserve
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        uniswap = Uniswap(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        GD = cERC20(_gd);
        DAI = cERC20(_dai);
        cDAI = cERC20(_cdai);
        reserve = Reserve(_reserve);
        gdBridge = address(0xD5D11eE582c8931F336fbcd135e98CEE4DB8CCB0);
        omniBridge = address(0xf301d525da003e874DF574BCdd309a6BF0535bb6);

        GD.approve(
            address(uniswap),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        DAI.approve(
            address(cDAI),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        GD.approve(
            address(reserve),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        cDAI.approve(
            address(reserve),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        DAI.approve(
            omniBridge,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    function setContract(string memory name, address newaddress)
        public
        onlyOwner
    {
        bytes32 nameHash = keccak256(bytes(name));
        if (nameHash == keccak256(bytes("GD"))) {
            GD = cERC20(newaddress);
            GD.approve(
                address(uniswap),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
            GD.approve(
                address(reserve),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        } else if (nameHash == keccak256(bytes("uniswap"))) {
            uniswap = Uniswap(newaddress);
        } else if (nameHash == "reserve") {
            reserve = Reserve(newaddress);
            GD.approve(
                address(reserve),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
            cDAI.approve(
                address(reserve),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        } else if (nameHash == keccak256(bytes("gdBridge"))) {
            gdBridge = newaddress;
        } else if (nameHash == keccak256(bytes("omniBridge"))) {
            omniBridge = newaddress;
            DAI.approve(
                omniBridge,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        }
    }

    /**
     * @dev buy GD from reserve using ETH since reserve  is in cDAI
     * we first buy DAI from uniswap -> mint cDAI -> buy GD
     * @param _minDAIAmount - the min amount of DAI to receive for buying with ETH
     * @param _minGDAmount - the min amount of GD to receive for buying with cDAI(via DAI)
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function buyGDFromReserve(
        uint256 _minDAIAmount,
        uint256 _minGDAmount,
        address _bridgeTo
    ) external payable returns (uint256) {
        uint256 gd = _buyGDFromReserve(_minDAIAmount, _minGDAmount);

        transferWithFee(GD, gd, _bridgeTo);

        return gd;
    }

    function transferWithFee(
        cERC20 _token,
        uint256 _amount,
        address _bridgeTo
    ) internal {
        uint256 amountAfterFee = deductFee(_amount);
        if (_bridgeTo == address(0)) {
            _token.transfer(msg.sender, amountAfterFee);
        } else if (_token == GD) {
            _token.transferAndCall(
                gdBridge,
                amountAfterFee,
                abi.encodePacked(_bridgeTo)
            );
        } else {
            AmbBridge(omniBridge).relayTokens(
                address(_token),
                _bridgeTo,
                amountAfterFee
            );
        }
    }

    function deductFee(uint256 _amount) public pure returns (uint256) {
        return (_amount * 998) / 1000;
    }

    /**
     * @dev buy GD from reserve using DAI since reserve  is in cDAI
     * we first mint cDAI
     * @param _DAIAmount - the amount of DAI approved to buy G$ with
     * @param _minGDAmount - the min amount of GD to receive for buying with cDAI(via DAI)
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function buyGDFromReserveWithDAI(
        uint256 _DAIAmount,
        uint256 _minGDAmount,
        address _bridgeTo
    ) public returns (uint256) {
        uint256 gd = _buyGDFromReserveWithDAI(_DAIAmount, _minGDAmount);
        transferWithFee(GD, gd, _bridgeTo);
        return gd;
    }

    function _buyGDFromReserveWithDAI(uint256 _DAIAmount, uint256 _minGDAmount)
        internal
        returns (uint256)
    {
        require(_DAIAmount > 0, "DAI amount should not be 0");
        require(
            DAI.transferFrom(msg.sender, _DAIAmount),
            "must approve DAI first"
        );

        uint256 cdaiRes = cDAI.mint(_DAIAmount);
        require(cdaiRes == 0, "cDAI buying failed");
        uint256 cdai = cDAI.balanceOf(address(this));
        uint256 gd = reserve.buy(address(cDAI), cdai, _minGDAmount);
        require(gd > 0, "gd buying failed");
        emit GDTraded(
            "reserve",
            "buy",
            msg.sender,
            _DAIAmount,
            new uint256[](0),
            gd
        );

        return gd;
    }

    /**
     * @dev sell GD to reserve converting resulting cDAI to DAI
     * @param _GDAmount - the amount of G$ approved to sell
     * @param _minCDAIAmount - the min amount of cDAI to receive for selling G$
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function sellGDToReserveForDAI(
        uint256 _GDAmount,
        uint256 _minCDAIAmount,
        address _bridgeTo
    ) external returns (uint256) {
        require(_GDAmount > 0, "G$ amount should not be 0");
        require(
            GD.transferFrom(msg.sender, _GDAmount),
            "must approve G$ first"
        );

        uint256 cdai = reserve.sell(address(cDAI), _GDAmount, _minCDAIAmount);
        require(cdai > 0, "G$ selling failed");
        uint256 daiRedeemed = DAI.balanceOf(address(this));
        require(cDAI.redeem(cdai) == 0, "cDAI redeem faiiled");
        daiRedeemed = DAI.balanceOf(address(this)) - daiRedeemed;

        transferWithFee(DAI, daiRedeemed, _bridgeTo);

        emit GDTraded(
            "reserve",
            "sell",
            msg.sender,
            cdai,
            new uint256[](0),
            _GDAmount
        );
    }

    function _buyGDFromReserve(uint256 _minDAIAmount, uint256 _minGDAmount)
        internal
        returns (uint256)
    {
        require(msg.value > 0, "You must send some ETH");

        address[] memory path = new address[](2);
        path[1] = address(DAI);
        path[0] = uniswap.WETH();
        uint256[] memory swap =
            uniswap.swapExactETHForTokens{value: msg.value}(
                _minDAIAmount,
                path,
                address(this),
                now
            );
        uint256 dai = swap[1];
        require(dai > 0, "DAI buying failed");
        uint256 cdaiRes = cDAI.mint(dai);
        require(cdaiRes == 0, "cDAI buying failed");
        uint256 cdai = cDAI.balanceOf(address(this));
        uint256 gd = reserve.buy(address(cDAI), cdai, _minGDAmount);
        // uint256 gd = GD.balanceOf(address(this));
        require(gd > 0, "gd buying failed");
        emit GDTraded("reserve", "buy", msg.sender, msg.value, swap, gd);

        return gd;
    }

    /**
     * @dev buy GD from uniswap pool using ETH since pool is in DAI
     * we first buy DAI from uniswap -> buy GD
     * @param _minGDAmount - the min amount of GD to receive for buying with DAI(via ETH)
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function buyGDFromUniswap(uint256 _minGDAmount, address _bridgeTo)
        external
        payable
        returns (uint256)
    {
        require(msg.value > 0, "You must send some ETH");

        uint256 value = msg.value;

        address[] memory path = new address[](3);
        path[2] = address(GD);
        path[1] = address(DAI);
        path[0] = uniswap.WETH();
        uint256[] memory swap =
            uniswap.swapExactETHForTokens{value: value}(
                _minGDAmount,
                path,
                address(this),
                now
            );
        uint256 gd = swap[2];
        require(gd > 0, "gd buying failed");
        emit GDTraded("uniswap", "buy", msg.sender, msg.value, swap, gd);

        transferWithFee(GD, gd, _bridgeTo);
        return gd;
    }

    /**
     * @dev buy G$ from reserve using ETH and sell to uniswap pool resulting in DAI
     * @param _minDAIAmount - the min amount of dai to receive for selling eth to uniswap
     * @param _minGDAmount - the min amount of G$ to receive for buying with cDAI(via ETH) from reserve
     * @param _minDAIAmountUniswap - the min amount of DAI to receive for selling G$ to uniswap
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function sellGDFromReserveToUniswap(
        uint256 _minDAIAmount,
        uint256 _minGDAmount,
        uint256 _minDAIAmountUniswap,
        address _bridgeTo
    ) external payable returns (uint256) {
        uint256 gd = _buyGDFromReserve(_minDAIAmount, _minGDAmount);

        address[] memory path = new address[](2);
        path[0] = address(GD);
        path[1] = address(DAI);
        uint256[] memory swap =
            uniswap.swapExactTokensForTokens(
                gd,
                _minDAIAmountUniswap,
                path,
                address(this),
                now
            );
        uint256 dai = swap[1];
        require(dai > 0, "gd selling failed");
        emit GDTraded("uniswap", "sell", msg.sender, msg.value, swap, gd);

        transferWithFee(DAI, dai, _bridgeTo);

        return dai;
    }

    /**
     * @dev buy GD from reserve using DAI and sell to uniswap pool resulting in DAI
     * @param _DAIAmount - the amount of dai approved to buy G$
     * @param _minGDAmount - the min amount of GD to receive for buying with cDAI
     * @param _minDAIAmount - the min amount of DAI to receive for selling  G$ on uniswap
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function sellGDFromReserveToUniswapWithDAI(
        uint256 _DAIAmount,
        uint256 _minGDAmount,
        uint256 _minDAIAmount,
        address _bridgeTo
    ) external payable returns (uint256) {
        uint256 gd = _buyGDFromReserveWithDAI(_DAIAmount, _minGDAmount);

        address[] memory path = new address[](2);
        path[0] = address(GD);
        path[1] = address(DAI);
        uint256[] memory swap =
            uniswap.swapExactTokensForTokens(
                gd,
                _minDAIAmount,
                path,
                address(this),
                now
            );

        uint256 dai = swap[1];
        require(dai > 0, "gd selling failed");
        emit GDTraded("uniswap", "sell", msg.sender, msg.value, swap, gd);

        transferWithFee(DAI, dai, _bridgeTo);

        return dai;
    }

    function withdraw(address to) public onlyOwner {
        GD.transfer(to, GD.balanceOf(address(this)));
        DAI.transfer(to, DAI.balanceOf(address(this)));
        payable(to).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}