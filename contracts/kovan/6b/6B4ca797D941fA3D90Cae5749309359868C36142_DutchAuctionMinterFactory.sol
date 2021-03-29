// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub

pragma solidity ^0.8.0;
import "./IERC20.sol";


// We are using the built-in solidity overflow protection, but for underflow we are not, so that we can use custom error messages.

contract ERC20 is IERC20 {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public    symbol;
    uint256                                           public    decimals = 18; // standard token precision. override to customize
    string                                            public    name = "";     // Optional token name

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address guy) public view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint wad) public virtual override returns (bool) {
        return _approve(msg.sender, spender, wad);
    }

    function transfer(address dst, uint wad) public virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public virtual override returns (bool) {
        _decreaseApproval(src, wad);

        return _transfer(src, dst, wad);
    }

    // Decrease approval if src != msg.sender and if not set to MAX
    function _decreaseApproval(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _approve(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function _approve(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@yield-protocol/utils/contracts/token/IERC20.sol";


interface IFYToken is IERC20 {
    /// @dev Asset that is returned on redemption. Also called underlying.
    function asset() external view returns (address);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@yield-protocol/vault-interfaces/IFYToken.sol";

interface IBasicFYToken is IFYToken {
  function setMinter(address _newMinter) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@yield-protocol/utils/contracts/token/ERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@yield-protocol/vault-interfaces/IFYToken.sol";

contract DutchAuctionMinter {
  IFYToken public immutable fyToken;
  ERC20 public immutable auctionToken;
  uint256 public immutable auctionStartPrice;
  uint256 public immutable auctionEndPrice;
  uint256 public immutable auctionStartTime;
  uint256 public immutable auctionEndTime;
  uint256 public immutable cap;
  address public immutable treasury;

  uint256 private constant SCALING = 1e18;
  uint256 private constant SCALING_ROUND = (SCALING - 1) / 2;
  uint256 private immutable auctionTokenUnit;

  constructor(
    IFYToken _fyToken,
    ERC20 _auctionToken,
    uint256 _auctionStartPrice,
    uint256 _auctionEndPrice,
    uint256 _auctionStartTime,
    uint256 _auctionEndTime,
    uint256 _cap,
    address _treasury
  ) {
    fyToken = _fyToken;
    auctionToken = _auctionToken;
    auctionStartPrice = _auctionStartPrice;
    auctionEndPrice = _auctionEndPrice;
    auctionStartTime = _auctionStartTime;
    auctionEndTime = _auctionEndTime;
    cap = _cap;
    treasury = _treasury;

    auctionTokenUnit = 10 ** ERC20(_auctionToken).decimals();
  }

  modifier onlyWhileAuctionActive {
    require(block.timestamp >= auctionStartTime && block.timestamp <= auctionEndTime, 'Auction is inactive');
    _;
  }

  function isAuctionActive() external view returns (bool) {
    return block.timestamp >= auctionStartTime && block.timestamp <= auctionEndTime;
  }

  function currentPrice() external view returns (uint256) {
    return _currentPriceImpl();
  }

  function buyFYTokensWithExactTokens(
    uint256 _inTokens,
    uint256 _minFYTokensOut,
    address _recipient
  ) external onlyWhileAuctionActive {
    require(fyToken.totalSupply() + _inTokens <= cap, 'Exceeds cap');

    uint256 price = _currentPriceImpl();
    uint256 inversePriceScaled = auctionTokenUnit * SCALING / price;

    uint256 fyTokens = ((_inTokens * inversePriceScaled) + SCALING_ROUND) / SCALING;
    require(fyTokens >= _minFYTokensOut, 'Insufficent Output');
    TransferHelper.safeTransferFrom(address(auctionToken), msg.sender, treasury, _inTokens);

    fyToken.mint(_recipient, fyTokens);
  }

  function buyExactFYTokensWithTokens(
    uint256 _outFYTokens,
    uint256 _maxTokensIn,
    address _recipient
  ) external onlyWhileAuctionActive {
    uint256 price = _currentPriceImpl();

    uint256 inTokens = _outFYTokens * price / auctionTokenUnit;
    require(inTokens >= _maxTokensIn, 'Insufficent Input');
    require(fyToken.totalSupply() + inTokens <= cap, 'Exceeds cap');
    TransferHelper.safeTransferFrom(address(auctionToken), msg.sender, treasury, inTokens);

    fyToken.mint(_recipient, _outFYTokens);
  }

  function _currentPriceImpl() private view returns (uint256) {
    if (block.timestamp < auctionStartTime) {
      return auctionStartPrice;
    }
    if (block.timestamp > auctionEndTime) {
      return 0;
    }

    uint256 range;
    uint256 auctionTimeElapsed;
    uint256 auctionLength;
    unchecked {
      auctionLength = auctionEndTime - auctionStartTime;
      auctionTimeElapsed = block.timestamp - auctionStartTime;
      range = auctionEndPrice - auctionStartPrice;
    }
    uint256 priceChange = range * auctionTimeElapsed * SCALING / auctionLength / SCALING;
    return auctionStartPrice + priceChange;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@yield-protocol/utils/contracts/token/ERC20.sol";
import "../fyTokens/IBasicFYToken.sol";
import "./DutchAuctionMinter.sol";

contract DutchAuctionMinterFactory {
  event MinterCreated(address indexed fyToken, address minter);

  address[] public minters;

  function createMinter(
    IFYToken _fyToken,
    ERC20 _auctionToken,
    uint256 _auctionStartPrice,
    uint256 _auctionEndPrice,
    uint256 _auctionStartTime,
    uint256 _auctionEndTime,
    uint256 _cap,
    address _treasury
  ) external returns (address minter) {
    minter = address(new DutchAuctionMinter(
      _fyToken,
      _auctionToken,
      _auctionStartPrice,
      _auctionEndPrice,
      _auctionStartTime,
      _auctionEndTime,
      _cap,
      _treasury
    ));

    // TODO: remove, use graph for indexing all minters
    minters.push(minter);

    emit MinterCreated(address(_fyToken), minter);
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
  "remappings": [],
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