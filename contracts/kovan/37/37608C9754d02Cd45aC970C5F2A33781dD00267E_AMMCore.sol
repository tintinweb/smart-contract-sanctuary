// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@yield-protocol/utils-v2/contracts/token/ERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/TransferHelper.sol";

import "../interfaces/IAMMCore.sol";
import "../types/TokenData.sol";

/// @title AMMRouter
/// @author devtooligan.eth
/// @notice Simple Automated Market Maker - Core logic contract. An excercise for the Yield mentorship program
/// @dev For use with AMMRouter
contract AMMCore is ERC20("TooliganLP", "TLP", 18), IAMMCore {
    address public owner;
    TokenData internal x;
    TokenData internal y;
    uint256 public k; // x.reserve * y.reserve == k

    //@notice Initialized with contracts of two tokens in pair
    constructor(IERC20 _xToken, IERC20 _yToken) {
        x = TokenData(_xToken, 0);
        y = TokenData(_yToken, 0);
        owner = msg.sender;
    }

    function getX() external view override returns (TokenData memory) {
        return x;
    }

    function getY() external view override returns (TokenData memory) {
        return y;
    }

    //@notice Initializes liquidity pools and k
    // @notice Use this function to initialize k and add liquidity
    // @dev Can only be used once
    // @param wadX The amount of tokenX to add
    // @param wadY The amount of tokenY to add
    function init(uint256 wadX, uint256 wadY) external override {
        require(msg.sender == owner, "Unauthorized");
        require(k == 0, "Previously initialized");
        require(wadX > 0 && wadY > 0, "Invalid amounts");

        IERC20 xToken = x.token;
        IERC20 yToken = y.token;
        TransferHelper.safeTransferFrom(xToken, owner, address(this), wadX);
        TransferHelper.safeTransferFrom(yToken, owner, address(this), wadY);
        uint256 xBalance = xToken.balanceOf(address(this));
        uint256 yBalance = yToken.balanceOf(address(this));

        x.reserve = xBalance;
        y.reserve = yBalance;
        uint256 kValue = (xBalance * yBalance) / 1e18;
        k = kValue;

        _mint(owner, kValue);

        emit Initialized(kValue);
    }

    //@notice Initializes liquidity pools / k ratio
    //@param admin - who will get the initial lp's
    //@dev This should be called by the router contract
    function mintLP(address guy) external override {
        uint256 kValue = k;
        require(kValue > 0, "Not initialized");
        uint256 newXreserve = x.token.balanceOf(address(this));
        uint256 newYreserve = y.token.balanceOf(address(this));
        uint256 addedX = newXreserve - x.reserve;
        uint256 mintAmount = (addedX * kValue) / x.reserve;

        x.reserve = newXreserve;
        y.reserve = newYreserve;
        k = (x.reserve * y.reserve) / 1e18;

        _mint(guy, mintAmount);

        emit Minted(guy, mintAmount);
    }

    //@notice Used to burn Lp's and get out original tokens
    //@param admin - who will get the initial lp's
    //@dev This should be called by the router contract
    function burnLP(address guy, uint256 wad) external override {
        uint256 xReserve = x.reserve;
        uint256 yReserve = y.reserve;
        require(xReserve > 0 && yReserve > 0, "Not initialized");
        uint256 burnRatio = (wad * 1e18) / _totalSupply;
        uint256 xTokensToSend = burnRatio * xReserve;
        uint256 yTokensToSend = burnRatio * yReserve;

        x.reserve = xReserve - xTokensToSend;
        y.reserve = yReserve - yTokensToSend;
        k = (x.reserve * y.reserve) / 1e18;
        _burn(guy, wad);
        TransferHelper.safeTransfer(x.token, guy, xTokensToSend);
        TransferHelper.safeTransfer(y.token, guy, yTokensToSend);

        emit Burned(guy, wad, xTokensToSend, yTokensToSend);
    }

    //@notice Used to sell a fixed amount of tokenX for a computed amount of Y
    //@notice This assumes the transfer in of tokenX has already occurred
    //@param address - The address of the seller / where to send the Y tokens
    //@dev This should be called by the router contract
    function swapX(address guy) external override {
        uint256 kValue = k;
        require(kValue > 0, "Not initialized");
        TokenData memory xData = x;
        TokenData memory yData = y;

        uint256 amountXIn = xData.token.balanceOf(address(this)) - xData.reserve;
        uint256 newXreserve = xData.reserve + amountXIn;
        uint256 newYreserve = (kValue * 1e18) / newXreserve;
        uint256 amountYOut = yData.reserve - newYreserve;

        x.reserve = newXreserve;
        y.reserve = newYreserve;
        TransferHelper.safeTransfer(yData.token, guy, amountYOut);

        emit Swapped(guy, address(xData.token), amountXIn, amountYOut);
    }

    //@notice Used to sell a fixed amount of tokenY for a computed amount of X
    //@notice This assumes the transfer in of tokenY has already occurred
    //@param address - The address of the seller / where to send the X tokens
    //@dev This should be called by the router contract
    function swapY(address guy) external override {
        uint256 kValue = k;
        require(kValue > 0, "Not initialized");
        TokenData memory xData = x;
        TokenData memory yData = y;
        uint256 amountYIn = yData.token.balanceOf(address(this)) - yData.reserve;
        uint256 newYreserve = yData.reserve + amountYIn;
        uint256 newXreserve = (kValue * 1e18) / newYreserve;
        uint256 amountXOut = xData.reserve - newXreserve;

        x.reserve = newXreserve;
        y.reserve = newYreserve;
        TransferHelper.safeTransfer(xData.token, guy, amountXOut);

        emit Swapped(guy, address(yData.token), amountYIn, amountXOut);
    }
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

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
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address payable to, uint256 value) internal {
        (bool success, bytes memory data) = to.call{value: value}(new bytes(0));
        if (!success) revert(RevertMsgExtractor.getRevertMsg(data));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "../types/TokenData.sol";

/**
 * @dev Interface for AMMCore
 */
interface IAMMCore is IERC20 {
    function getX() external view returns (TokenData memory);

    function getY() external view returns (TokenData memory);

    event Initialized(uint256 k);
    event Minted(address indexed guy, uint256 k);
    event Burned(address indexed guy, uint256 wad, uint256 xTokensToSend, uint256 yTokensToSend);
    event Swapped(address indexed guy, address indexed tokenIn, uint256 amountX, uint256 amountY);

    //@notice Initializes liquidity pools and k
    // @notice Use this function to initialize k and add liquidity
    // @dev Can only be used once
    // @param wadX The amount of tokenX to add
    // @param wadY The amount of tokenY to add
    function init(uint256 wadX, uint256 wadY) external;

    //@notice Initializes liquidity pools / k ratio
    //@param admin - who will get the initial lp's
    //@dev This should be called by the router contract
    function mintLP(address guy) external;

    //@notice Used to burn Lp's and get out original tokens
    //@param admin - who will get the initial lp's
    //@dev This should be called by the router contract
    function burnLP(address guy, uint256 wad) external;

    //@notice Used to sell a fixed amount of tokenX for a computed amount of Y
    //@notice This assumes the transfer in of tokenX has already occurred
    //@param address - The address of the seller / where to send the Y tokens
    //@dev This should be called by the router contract
    function swapX(address guy) external;

    //@notice Used to sell a fixed amount of tokenY for a computed amount of X
    //@notice This assumes the transfer in of tokenY has already occurred
    //@param address - The address of the seller / where to send the X tokens
    //@dev This should be called by the router contract
    function swapY(address guy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

struct TokenData {
    IERC20 token;
    uint256 reserve;
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/contracts/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}