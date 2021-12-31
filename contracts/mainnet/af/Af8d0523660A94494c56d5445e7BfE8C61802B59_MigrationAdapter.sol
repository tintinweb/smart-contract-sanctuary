//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "../adapters/AbstractAdapter.sol";

contract MigrationAdapter is AbstractAdapter {
    constructor(address owner_) AbstractAdapter(owner_) {}

    function outputTokens(address)
        public
        view
        override
        returns (address[] memory outputs)
    {
        return new address[](0);
    }

    function encodeMigration(address, address, address, uint256)
        public
        override
        view
        returns (Call[] memory calls)
    {
        return new Call[](0);
    }

    function encodeWithdraw(address, uint256)
        public
        override
        view
        returns (Call[] memory calls)
    {
        return new Call[](0);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "../interfaces/IAdapter.sol";
import "../helpers/Whitelistable.sol";

import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV3Router.sol";
import "../interfaces/IQuoter.sol";

interface IGenericRouter {
    function settleTransfer(address token, address to) external;

    function settleSwap(
        address adapter,
        address tokenIn,
        address tokenOut,
        address from,
        address to
    ) external;
}

/// @title Token Sets Vampire Attack Contract
/// @author Enso.finance (github.com/EnsoFinance)
/// @notice Adapter for redeeming the underlying assets from Token Sets

abstract contract AbstractAdapter is IAdapter, Whitelistable {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant SUSHI = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant UNI_V2 = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    address public constant UNI_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    /**
    * @dev Require exchange registered
    */
    modifier onlyExchange(address _exchange) {
        require(isExchange(_exchange), "AbstractAdapter#buy: should be exchanges");
        _;
    }

    constructor(address owner_) {
        _setOwner(owner_);
    }

    function outputTokens(address _lp)
        public
        view
        override
        virtual
        returns (address[] memory outputs);

    function encodeMigration(address _genericRouter, address _strategy, address _lp, uint256 _amount)
        public
        override
        virtual
        view
        returns (Call[] memory calls);

    function encodeWithdraw(address _lp, uint256 _amount)
        public
        override
        virtual
        view
        returns (Call[] memory calls);

    function buy(address _lp, address _exchange, uint256 _minAmountOut, uint256 _deadline)
        public
        override
        virtual
        payable
        onlyExchange(_exchange)
        onlyWhitelisted(_lp)
    {
        if (_exchange == UNI_V3) {
            _buyV3(_lp, _minAmountOut, _deadline);
        } else {
            _buyV2(_lp, _exchange, _minAmountOut, _deadline);
        }
    }

    function getAmountOut(
        address _lp,
        address _exchange,
        uint256 _amountIn
    )
        external
        override
        virtual
        onlyExchange(_exchange)
        onlyWhitelisted(_lp)
        returns (uint256)
    {
        if (_exchange == UNI_V3) {
            return _getV3(_lp, _amountIn);
        } else {
            return _getV2(_lp, _exchange, _amountIn);
        }
    }

    function _buyV2(
        address _lp,
        address _exchange,
        uint256 _minAmountOut,
        uint256 _deadline
    )
        internal
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _lp;
        IUniswapV2Router(_exchange).swapExactETHForTokens{value: msg.value}(
            _minAmountOut,
            path,
            msg.sender,
            _deadline
        );
    }

    function _buyV3(
        address _lp,
        uint256 _minAmountOut,
        uint256 _deadline
    )
        internal
    {
        IUniswapV3Router(UNI_V3).exactInputSingle{value: msg.value}(IUniswapV3Router.ExactInputSingleParams(
          WETH,
          _lp,
          3000,
          msg.sender,
          _deadline,
          msg.value,
          _minAmountOut,
          0
        ));
    }

    function _getV2(address _lp, address _exchange, uint256 _amountIn)
        internal
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _lp;
        return IUniswapV2Router(_exchange).getAmountsOut(_amountIn, path)[1];
    }

    function _getV3(address _lp, uint256 _amountIn)
        internal
        returns (uint256)
    {

        return IQuoter(QUOTER).quoteExactInputSingle(
            WETH,
            _lp,
            3000,
            _amountIn,
            0
        );
    }

    /**
    * @param _lp to view pool token
    * @return if token in whitelist
    */
    function isWhitelisted(address _lp)
        public
        view
        override
        returns(bool)
    {
        return whitelisted[_lp];
    }

    function isExchange(address _exchange)
        public
        pure
        returns (bool)
    {
        return(_exchange == SUSHI || _exchange == UNI_V2 || _exchange == UNI_V3);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IAdapter {
    struct Call {
        address target;
        bytes callData;
    }

    function outputTokens(address inputToken) external view returns (address[] memory outputs);

    function encodeMigration(address _genericRouter, address _strategy, address _lp, uint256 _amount)
        external view returns (Call[] memory calls);

    function encodeWithdraw(address _lp, uint256 _amount) external view returns (Call[] memory calls);

    function buy(address _lp, address _exchange, uint256 _minAmountOut, uint256 _deadline) external payable;

    function getAmountOut(address _lp, address _exchange, uint256 _amountIn) external returns (uint256);

    function isWhitelisted(address _token) external view returns (bool);
}

import "../helpers/Ownable.sol";
// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

abstract contract Whitelistable is Ownable {

    mapping(address => bool) public whitelisted;

    event Added(address token);
    event Removed(address token);

    /**
    * @dev Require adapter registered
    */
    modifier onlyWhitelisted(address _lp) {
        require(whitelisted[_lp], "Whitelistable#onlyWhitelisted: not whitelisted lp");
        _;
    }

    /**
    * @dev add pool token to whitelist
    * @param _token pool address
    */
    function add(address _token)
        public
        onlyOwner
    {
        _add(_token);
    }

    /**
    * @dev batch add pool token to whitelist
    * @param _tokens[] array of pool address
    */
    function addBatch(address[] memory _tokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _add(_tokens[i]);
        }
    }

    /**
    * @dev remove pool token from whitelist
    * @param _token pool address
    */
    function remove(address _token)
        public
        onlyOwner
    {
        _remove(_token);
    }

    /**
    * @dev batch remove pool token from whitelist
    * @param _tokens[] array of pool address
    */
    function removeBatch(address[] memory _tokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _remove(_tokens[i]);
        }
    }

    function _add(address _token)
        internal
    {
        whitelisted[_token] = true;
        emit Added(_token);
    }

    function _remove(address _token)
        internal
    {
        require(whitelisted[_token], 'Whitelistable#_Remove: not exist');
        whitelisted[_token] = false;
        emit Removed(_token);
    }
}

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
          external
          payable
          returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

pragma solidity >=0.6.0 <0.9.0;

interface IQuoter {
  function quoteExactInputSingle(
      address tokenIn,
      address tokenOut,
      uint24 fee,
      uint256 amountIn,
      uint160 sqrtPriceLimitX96
  ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

import "../ecosystem/openzeppelin/utils/Context.sol";

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
    function _setOwner(address owner_) 
        internal
    {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
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

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}