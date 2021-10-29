// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PMGPermission.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

contract DPolyPay is PMGPermission {
    struct STokenSupport {
        address _address;
        uint256 _type;
    }

    struct SMerchantRecord {
        uint256 total;
        uint256 freeze;
        uint256 withdraw;
    }

    string private _platFormSymbol = "000";

    mapping(string => mapping(string => SMerchantRecord))
        private _merchantRecord;
    string[] private _merchantIndexes;
    mapping(string => STokenSupport) private _tokensSupport;
    string[] private _tokenSupprtIndexes;

    constructor() PMGPermission() {
        addTokenSupport(_platFormSymbol, address(0x0));
    }

    event EAddTokenSupport(string indexed symbol, address tokenAddr);
    event EApprovePay(
        string indexed merchant,
        string indexed orderId,
        string indexed symbol,
        uint256 moneyCount
    );
    event EDealPay(
        string indexed merchant,
        string indexed orderId,
        string indexed symbol,
        uint256 moneyCount
    );

    event EWithDraw(string indexed merchant, string indexed symbol, address to);

    function addTokenSupport(string memory symbol, address tokenAddr)
        public
        OnlyOwner
    {
        _tokensSupport[symbol] = STokenSupport(tokenAddr, 0);
        _tokenSupprtIndexes.push(symbol);
        emit EAddTokenSupport(symbol, tokenAddr);
    }

    function tokenSupports() public view returns (string[] memory) {
        return _tokenSupprtIndexes;
    }

    function merchantSupports() public view returns (string[] memory) {
        return _merchantIndexes;
    }

    function addMerchant(string memory merchant) public OnlyOwner {
        _merchantIndexes.push(merchant);
    }

    function approvePay(
        string memory merchant,
        string memory symbol,
        uint256 moneyCount,
        string memory orderId
    ) public {
        if (
            keccak256(abi.encode(symbol)) ==
            keccak256(abi.encode(_platFormSymbol))
        ) {
            // plat form coin no need approve
        } else {
            IERC20(_tokensSupport[symbol]._address).approve(
                address(this),
                moneyCount
            );
        }
        emit EApprovePay(merchant, orderId, symbol, moneyCount);
    }

    function dealPay(
        string memory merchant,
        string memory symbol,
        uint256 moneyCount,
        string memory orderId
    ) public payable {
        if (
            keccak256(abi.encode(symbol)) ==
            keccak256(abi.encode(_platFormSymbol))
        ) {
            // do nothing, money now to contract
            moneyCount = msg.value;
        } else {
            IERC20(_tokensSupport[symbol]._address).transferFrom(
                msg.sender,
                address(this),
                moneyCount
            );
        }
        _merchantRecord[merchant][symbol].total += moneyCount;
        emit EDealPay(merchant, orderId, symbol, moneyCount);
    }

    function withDraw(
        string memory merchant,
        string memory symbol,
        address to
    ) public OnlyOwner {
        IERC20(_tokensSupport[symbol]._address).transfer(
            to,
            _merchantRecord[merchant][symbol].total
        );
        _merchantRecord[merchant][symbol].withdraw += _merchantRecord[merchant][
            symbol
        ].total;
        _merchantRecord[merchant][symbol].total = 0;
        emit EWithDraw(merchant, symbol, to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
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
pragma solidity ^0.8.0;

contract PMGPermission {
  address private _owner;
  event EChangeOwner(address from, address to);
  constructor() {
    _owner = msg.sender;
  }

  function changeOwner(address newOwner) public OnlyOwner {
    emit EChangeOwner(_owner, newOwner);
    _owner = newOwner;
  }

  modifier OnlyOwner() {
    require(msg.sender == _owner, "invalid permission");
    _;
  }
}