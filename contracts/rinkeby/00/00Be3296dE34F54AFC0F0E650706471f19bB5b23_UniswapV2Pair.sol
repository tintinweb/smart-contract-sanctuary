// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;


interface IERC1155 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, bytes32 _hash, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, bytes32[] _hash, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
   * @dev MUST emit when the URI is updated for a token ID
   *   URIs are defined in RFC 3986
   *   The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema"
   */
  event URI(string _amount, bytes32 indexed _hash);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _hash    Computed hash of erc721 contract address and its tokenId
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, bytes32 _hash, uint256 _amount, bytes calldata _data) external returns (bool);

  function transferFrom(address _from, address _to, bytes32 _hash, uint256 _amount) external returns (bool);
  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _hashes   Computed hash of erc721 contract address and its tokenId
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, bytes32[] calldata _hashes, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _hash   Computed hash of erc721 contract address and its tokenId
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, bytes32 _hash) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _hashes Computed hash of erc721 contract address and its tokenId
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, bytes32[] calldata _hashes) external view returns (uint256[] memory);

  /**
   * @notice Get the dispensed amount of ERC1155 tokens
   * @param _hash   Computed hash of erc721 contract address and its tokenId
   * @return        Amount of ERC1155 tokens that were dispensed on deposit of ERC721 token _id
   */
  function dispensedOf(bytes32 _hash) external view returns (uint256);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the contract name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the contract symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the amount of decimals.
     */
    function decimals() external view returns (uint8);

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

pragma solidity ^0.6.6;

import "./interfaces/IUniswapV2ERC20.sol";
import "../../common/math/SafeMath.sol";

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant override name = 'MEMESWAP';
    string public constant override symbol = 'MEMESWAP-LP';
    uint8 public constant override decimals = 18;
    uint  public override totalSupply;

    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) public virtual override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) public virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public virtual override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Callee.sol";
import "./UniswapV2ERC20.sol";
import "../../erc20/IERC20.sol";
import "../../erc1155/interfaces/IERC1155.sol";
import "../../common/math/Math.sol";
import "../../common/math/SafeMath.sol";
import "../../common/math/UQ112x112.sol";

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public override constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant BASE_TOKEN_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TOKEN_SELECTOR = 0x7fe68381;

    address public override factory;
    address public override dispenser;
    address public override baseToken;
    bytes32 public override tokenHash;

    uint112 public tokenReserve;           // uses single storage slot, accessible via getReserves
    uint112 public baseTokenReserve;           // uses single storage slot, accessible via getReserves
    uint32  public blockTimestampLast;     // uses single storage slot, accessible via getReserves

    uint public override tokenCumulativeLast;
    uint public override baseTokenCumulativeLast;
    uint public override kLast; // tokenReserve * baseTokenReserve, as of immediately after the most recent liquidity event

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    event Mint(address indexed sender, uint tokenAmount, uint baseTokenAmount);
    event Burn(address indexed sender, uint tokenAmount, uint baseTokenAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint tokenAmountIn,
        uint baseTokenAmountIn,
        uint tokenAmountOut,
        uint baseTokenAmountOut,
        address indexed to
    );
    event Sync(uint112 tokenReserve, uint112 baseTokenReserve);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(bytes32 _tokenHash, address _dispenser, address _baseToken) external virtual override {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        tokenHash = _tokenHash;
        dispenser = _dispenser;
        baseToken = _baseToken;
    }

    function getReserves() public view override returns (uint112 _tokenReserve, uint112 _baseTokenReserve, uint32 _blockTimestampLast) {
        _tokenReserve = tokenReserve;
        _baseTokenReserve = baseTokenReserve;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeBaseTokenTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(BASE_TOKEN_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: BASE_TOKEN_TRANSFER_FAILED');
    }

    function _safeTokenTransfer(bytes32 _tokenHash, address to, uint value) private {
        (bool success, bytes memory data) = dispenser.call(abi.encodeWithSelector(TOKEN_SELECTOR, address(this), to, _tokenHash, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TOKEN_TRANSFER_FAILED');
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint tokenBalance, uint baseTokenBalance, uint112 _tokenReserve, uint112 _baseTokenReserve) private {
        require(tokenBalance <= uint112(-1) && baseTokenBalance <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _tokenReserve != 0 && _baseTokenReserve != 0) {
            // * never overflows, and + overflow is desired
            tokenCumulativeLast += uint(UQ112x112.encode(_baseTokenReserve).uqdiv(_tokenReserve)) * timeElapsed;
            baseTokenCumulativeLast += uint(UQ112x112.encode(_tokenReserve).uqdiv(_baseTokenReserve)) * timeElapsed;
        }
        tokenReserve = uint112(tokenBalance);
        baseTokenReserve = uint112(baseTokenBalance);
        blockTimestampLast = blockTimestamp;
        emit Sync(tokenReserve, baseTokenReserve);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _tokenReserve, uint112 _baseTokenReserve) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_tokenReserve).mul(_baseTokenReserve));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external virtual override lock returns (uint liquidity) {
        // address dispenser = IUniswapV2Factory(factory).dispenser();
        // address baseToken = IUniswapV2Factory(factory).baseToken();
        (uint112 _tokenReserve, uint112 _baseTokenReserve,) = getReserves(); // gas savings
        uint tokenBalance = IERC1155(dispenser).balanceOf(address(this), tokenHash);
        uint baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
        uint tokenAmount = tokenBalance.sub(_tokenReserve);
        uint baseTokenAmount = baseTokenBalance.sub(_baseTokenReserve);

        bool feeOn = _mintFee(_tokenReserve, _baseTokenReserve);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(tokenAmount.mul(baseTokenAmount)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(tokenAmount.mul(_totalSupply) / _tokenReserve, baseTokenAmount.mul(_totalSupply) / _baseTokenReserve);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(tokenBalance, baseTokenBalance, _tokenReserve, _baseTokenReserve);
        if (feeOn) kLast = uint(tokenReserve).mul(baseTokenReserve); // tokenReserve and baseTokenReserve are up-to-date
        emit Mint(msg.sender, tokenAmount, baseTokenAmount);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to, uint exactTokenAmountOut, uint exactBaseTokenAmountOut) external virtual override lock returns (uint tokenAmount, uint baseTokenAmount) {
        (uint112 _tokenReserve, uint112 _baseTokenReserve,) = getReserves(); // gas savings
        bytes32 _tokenHash = tokenHash;                                // gas savings

        uint tokenBalance = IERC1155(dispenser).balanceOf(address(this), tokenHash);
        uint baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
        uint liquidityBalance = balanceOf[address(this)]; // the amount was asked to burn

        bool feeOn = _mintFee(_tokenReserve, _baseTokenReserve);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can be updated in _mintFee

        uint liquidity;
        if (exactTokenAmountOut > 0) {
            liquidity = _totalSupply.sub(MINIMUM_LIQUIDITY).mul(exactTokenAmountOut).div(tokenBalance);
            require(liquidity == liquidityBalance, 'UniswapV2: INSUFFICIENT_LIQUIDITY_PROVIDED');

            tokenAmount = exactTokenAmountOut;
            baseTokenAmount = tokenAmount == tokenBalance
                ? baseTokenBalance
                : liquidity.mul(baseTokenBalance).div(_totalSupply);

        } else if (exactBaseTokenAmountOut > 0) {
            liquidity = _totalSupply.sub(MINIMUM_LIQUIDITY).mul(exactBaseTokenAmountOut).div(baseTokenBalance);
            require(liquidity == liquidityBalance, 'UniswapV2: INSUFFICIENT_LIQUIDITY_PROVIDED');

            baseTokenAmount = exactBaseTokenAmountOut;
            tokenAmount = baseTokenAmount == baseTokenBalance
                ? tokenBalance
                : liquidity.mul(tokenBalance).div(_totalSupply);

        } else {
            liquidity = liquidityBalance;
            tokenAmount = liquidity.mul(tokenBalance).div(_totalSupply);
            baseTokenAmount = liquidity.mul(baseTokenBalance).div(_totalSupply); // using balances ensures pro-rata distribution
        }

        // we're removing the whole liquidity
        if (tokenAmount == tokenBalance && baseTokenAmount == baseTokenBalance) {
            liquidity = _totalSupply.sub(MINIMUM_LIQUIDITY);
            _burn(address(0), MINIMUM_LIQUIDITY);
        }

        require(tokenAmount > 0 && baseTokenAmount > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);

        _safeTokenTransfer(_tokenHash, to, tokenAmount);
        _safeBaseTokenTransfer(baseToken, to, baseTokenAmount);
        tokenBalance = IERC1155(dispenser).balanceOf(address(this), tokenHash);
        baseTokenBalance = IERC20(baseToken).balanceOf(address(this));

        _update(tokenBalance, baseTokenBalance, _tokenReserve, _baseTokenReserve);
        if (feeOn) kLast = uint(tokenReserve).mul(baseTokenReserve); // tokenReserve and baseTokenReserve are up-to-date
        emit Burn(msg.sender, tokenAmount, baseTokenAmount, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint tokenAmountOut, uint baseTokenAmountOut, address to, bytes calldata data) external virtual override lock {
        require(tokenAmountOut > 0 || baseTokenAmountOut > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _tokenReserve, uint112 _baseTokenReserve,) = getReserves(); // gas savings
        require(tokenAmountOut < _tokenReserve && baseTokenAmountOut < _baseTokenReserve, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint tokenBalance;
        uint baseTokenBalance;
        { // scope for _token{0,1}, avoids stack too deep errors
        bytes32 _tokenHash = tokenHash;
        require(to != baseToken, 'UniswapV2: INVALID_TO');
        // TODO: rewrite transfer
        if (tokenAmountOut > 0) _safeTokenTransfer(_tokenHash, to, tokenAmountOut); // optimistically transfer tokens
        if (baseTokenAmountOut > 0) _safeBaseTokenTransfer(baseToken, to, baseTokenAmountOut); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, tokenAmountOut, baseTokenAmountOut, data);
        tokenBalance = IERC1155(dispenser).balanceOf(address(this), _tokenHash);
        baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
        }
        uint tokenAmountIn = tokenBalance > _tokenReserve - tokenAmountOut ? tokenBalance - (_tokenReserve - tokenAmountOut) : 0;
        uint baseTokenAmountIn = baseTokenBalance > _baseTokenReserve - baseTokenAmountOut ? baseTokenBalance - (_baseTokenReserve - baseTokenAmountOut) : 0;
        require(tokenAmountIn > 0 || baseTokenAmountIn > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint tokenBalanceAdjusted = tokenBalance.mul(1000).sub(tokenAmountIn.mul(3));
        uint baseTokenBalanceAdjusted = baseTokenBalance.mul(1000).sub(baseTokenAmountIn.mul(3));
        require(tokenBalanceAdjusted.mul(baseTokenBalanceAdjusted) >= uint(_tokenReserve).mul(_baseTokenReserve).mul(1000**2), 'UniswapV2: K');
        }

        _update(tokenBalance, baseTokenBalance, _tokenReserve, _baseTokenReserve);
        emit Swap(msg.sender, tokenAmountIn, baseTokenAmountIn, tokenAmountOut, baseTokenAmountOut, to);
    }

    // force balances to match reserves
    function skim(address to) external virtual override lock {
        bytes32 _tokenHash = tokenHash; // gas savings
        _safeTokenTransfer(_tokenHash, to, IERC1155(dispenser).balanceOf(address(this), _tokenHash).sub(tokenReserve));
        _safeBaseTokenTransfer(baseToken, to, IERC20(baseToken).balanceOf(address(this)).sub(baseTokenReserve));
    }

    // force reserves to match balances
    function sync() external virtual override lock {
        _update(IERC1155(dispenser).balanceOf(address(this), tokenHash), IERC20(baseToken).balanceOf(address(this)), tokenReserve, baseTokenReserve);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswapV2Factory {
    event PairCreated(address indexed sender, bytes32 tokenHash, address indexed baseToken, address pair, uint allPairsLength);

    function dispenser() external view returns (address);
    function baseToken() external view returns (address);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(bytes32 tokenHash) external view returns (address pair);
    function allPairs(uint i) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(bytes32 tokenHash) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    event Mint(address indexed sender, uint tokenAmount, uint baseTokenAmount);
    event Burn(address indexed sender, uint tokenAmount, uint baseTokenAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint tokenAmountIn,
        uint baseTokenAmountIn,
        uint tokenAmountOut,
        uint baseTokenAmountOut,
        address indexed to
    );
    event Sync(uint112 tokenReserve, uint112 baseTokenReserve);

    function MINIMUM_LIQUIDITY() external view returns (uint);
    function factory() external view returns (address);
    function dispenser() external view returns (address);
    function baseToken() external view returns (address);
    function tokenHash() external view returns (bytes32);
    function getReserves() external view returns (uint112 tokenReserve, uint112 baseTokenReserve, uint32 blockTimestampLast);
    function tokenCumulativeLast() external view returns (uint);
    function baseTokenCumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to, uint exactTokenAmountOut, uint exactBaseTokenAmountOut) external returns (uint tokenAmount, uint baseTokenAmount);
    function swap(uint tokenAmountOut, uint baseTokenAmountOut, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(bytes32, address, address) external;
}

