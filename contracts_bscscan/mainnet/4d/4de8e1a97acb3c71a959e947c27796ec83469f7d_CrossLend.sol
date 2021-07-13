/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// File: @openzeppelin/contracts/token/ERC777/IERC777.sol


pragma solidity >=0.6.0 <0.8.0;

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
    function send(address recipient, uint256 amount, bytes calldata data) external;

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

// File: @openzeppelin/contracts/token/ERC777/IERC777Recipient.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/introspection/IERC1820Registry.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 _interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: crosslend/data.sol

pragma solidity >=0.6.2 <0.8.0;

enum FinancialType{CRFI, CFil}

struct FinancialPackage {
  FinancialType Type;
  
  uint256 Days;
  uint256 CFilInterestRate;
  uint256 CRFIInterestRateDyn;
  uint256 ID;

  uint256 Weight;
  uint256 ParamCRFI;
  uint256 ParamCFil;
  uint256 Total;
}

struct LoanCFilPackage {
  uint256 APY;
  uint256 PledgeRate;
  uint256 PaymentDue;
  uint256 PaymentDue99;

  uint256 UpdateTime;
  uint256 Param;
}

struct ViewSystemInfo{
  FinancialPackage[] Packages;
  uint256 AffRate;
  uint256 AffRequire;
  uint256 EnableAffCFil;
  
  LoanCFilPackage LoanCFil;

  ChainManager ChainM;

  // invest
  uint256 NewInvestID;
  mapping(uint256 => InvestInfo) Invests;
  mapping(address => uint256) InvestAddrID;
        
  // setting power
  address SuperAdmin;
  mapping(address => bool) Admins;

  // statistic
  uint256 nowInvestCRFI;
  uint256 nowInvestCFil; 
  uint256 cfilInterestPool;
  uint256 crfiInterestPool;

  uint256 cfilLendingTotal;
  uint256 crfiRewardTotal;
  uint256 avaiCFilAmount;
  
  uint256 totalWeightCFil;
  uint256 totalWeightCRFI;
  uint256 crfiMinerPerDayCFil;
  uint256 crfiMinerPerDayCRFI;
  
  uint256 ParamUpdateTime;
}

struct SystemInfoView {
  uint256 AffRate;
  uint256 AffRequire;
  uint256 EnableAffCFil;
  
  // invest
  uint256 NewInvestID;

  // statistic
  uint256 nowInvestCRFI;
  uint256 nowInvestCFil; 
  uint256 cfilInterestPool;
  uint256 crfiInterestPool;

  uint256 cfilLendingTotal;
  uint256 crfiRewardTotal;
  uint256 avaiCFilAmount;
  
  uint256 totalWeightCFil;
  uint256 totalWeightCRFI;
  uint256 crfiMinerPerDayCFil;
  uint256 crfiMinerPerDayCRFI;
  
  uint256 ParamUpdateTime;
}

struct SystemInfo {

  FinancialPackage[] Packages;
  uint256 AffRate;
  uint256 AffRequire;
  uint256 EnableAffCFil;
  
  LoanCFilPackage LoanCFil;

  ChainManager ChainM;

  // invest
  uint256 NewInvestID;
  mapping(uint256 => InvestInfo) Invests;
  mapping(address => uint256) InvestAddrID;
        
  // setting power
  address SuperAdmin;
  mapping(address => bool) Admins;

  // statistic
  uint256 nowInvestCRFI;
  uint256 nowInvestCFil; 
  uint256 cfilInterestPool;
  uint256 crfiInterestPool;

  uint256 cfilLendingTotal;
  uint256 crfiRewardTotal;
  uint256 avaiCFilAmount;
  
  uint256 totalWeightCFil;
  uint256 totalWeightCRFI;
  uint256 crfiMinerPerDayCFil;
  uint256 crfiMinerPerDayCRFI;
  
  uint256 ParamUpdateTime;

  mapping(string => string) kvMap;
}

struct InterestDetail{
  uint256 crfiInterest;
  uint256 cfilInterest;
}

struct LoanInvest{
  uint256 Lending;
  uint256 Pledge;
  uint256 Param;
  uint256 NowInterest;
}

struct InvestInfoView {
  address Addr;
  uint256 ID;

  uint256 affID;

  // statistic for financial
  uint256 totalAffTimes;
  uint256 totalAffPackageTimes;
  
  uint256 totalAffCRFI;
  uint256 totalAffCFil;
  
  uint256 nowInvestFinCRFI;
  uint256 nowInvestFinCFil;
}

struct InvestInfo {
  mapping(uint256 => ChainQueue) InvestRecords;

  address Addr;
  uint256 ID;

  uint256 affID;

  LoanInvest LoanCFil;

  // statistic for financial
  uint256 totalAffTimes;
  uint256 totalAffPackageTimes;
  
  uint256 totalAffCRFI;
  uint256 totalAffCFil;
  
  uint256 nowInvestFinCRFI;
  uint256 nowInvestFinCFil;
}


//////////////////// queue

struct QueueData {
  uint256 RecordID;
  
  FinancialType Type;
  uint256 PackageID;
  uint256 Days;
  uint256 EndTime;
  uint256 AffID;
  uint256 Amount;

  uint256 ParamCRFI;
  uint256 ParamCFil;
}

struct ChainItem {
  uint256 Next;
  uint256 Prev;
  uint256 My;
  
  QueueData Data;
}

struct ChainQueue{
  uint256 First;
  uint256 End;

  uint256 Size;
}


struct ChainManager{
  ChainItem[] rawQueue;

  ChainQueue avaiQueue;
}

library ChainQueueLib{

  //////////////////// item
  function GetNullItem(ChainManager storage chainM)
    internal
    view
    returns(ChainItem storage item){
    return chainM.rawQueue[0];
  }

  function HasNext(ChainManager storage chainM,
                   ChainItem storage item)
    internal
    view
    returns(bool has){

    if(item.Next == 0){
      return false;
    }

    return true;
  }

  function Next(ChainManager storage chainM,
                ChainItem storage item)
    internal
    view
    returns(ChainItem storage nextItem){

    uint256 nextIdx = item.Next;
    require(nextIdx > 0, "no next item");

    return chainM.rawQueue[uint256(nextIdx)];
  }

  //////////////////// chain
  function GetFirstItem(ChainManager storage chainM,
                        ChainQueue storage chain)
    internal
    view
    returns(ChainItem storage item){

    require(chain.Size > 0, "chain is empty");

    return chainM.rawQueue[chain.First];
  }

  function GetEndItem(ChainManager storage chainM,
                      ChainQueue storage chain)
    internal
    view
    returns(ChainItem storage item){

    require(chain.Size > 0, "chain is empty");

    return chainM.rawQueue[chain.End];
  }

  // need ensure the item is in chain
  function DeleteItem(ChainManager storage chainM,
                      ChainQueue storage chain,
                      ChainItem storage item)
    internal{

    if(chain.First == item.My){
      PopPutFirst(chainM, chain);
      return;
    } else if (chain.End == item.My){
      PopPutEnd(chainM, chain);
      return;
    }

    ChainItem storage next = chainM.rawQueue[item.Next];
    ChainItem storage prev = chainM.rawQueue[item.Prev];

    next.Prev = item.Prev;
    prev.Next = item.Next;

    item.Prev = 0;
    item.Next = 0;

    chain.Size--;

    PutItem(chainM, item);
  }

  function PopPutFirst(ChainManager storage chainM,
                       ChainQueue storage chain)
    internal{

    ChainItem storage item = PopFirstItem(chainM, chain);
    PutItem(chainM, item);
  }

  function PopPutEnd(ChainManager storage chainM,
                     ChainQueue storage chain)
    internal{

    ChainItem storage item = PopEndItem(chainM, chain);
    PutItem(chainM, item);
  }

  function PopEndItem(ChainManager storage chainM,
                        ChainQueue storage chain)
    internal
    returns(ChainItem storage item){
    
    require(chain.Size >0, "chain is empty");
    
    uint256 itemIdx = chain.End;
    chain.End = chainM.rawQueue[itemIdx].Prev;
    if(chain.End > 0){
      chainM.rawQueue[chain.End].Next = 0;
    } else {
      chain.First = 0;
    }
    chain.Size--;
    item = chainM.rawQueue[itemIdx];
    item.Prev = 0;
    return item;
  }

  function PopFirstItem(ChainManager storage chainM,
                        ChainQueue storage chain)
    internal
    returns(ChainItem storage item){

    require(chain.Size > 0, "chain is empty");

    uint256 itemIdx = chain.First;
    chain.First = chainM.rawQueue[itemIdx].Next;
    if(chain.First > 0){
      chainM.rawQueue[chain.First].Prev = 0;
    } else {
      chain.End = 0;
    }
    chain.Size--;

    item = chainM.rawQueue[itemIdx];
    item.Next = 0;

    return item;
  }

  function PushEndItem(ChainManager storage chainM,
                       ChainQueue storage chain,
                       ChainItem storage item)
    internal{

    item.Prev = chain.End;
    item.Next = 0;

    if(chain.Size == 0){
      chain.First = item.My;
      chain.End = item.My;
    } else {
      chainM.rawQueue[chain.End].Next = item.My;
      chain.End = item.My;
    }
    chain.Size++;
  }

  //////////////////// chain manager
  function InitChainManager(ChainManager storage chainM)
    internal{
    if(chainM.rawQueue.length == 0){
      chainM.rawQueue.push();
    }
  }
  
  function GetAvaiItem(ChainManager storage chainM)
    internal
    returns(ChainItem storage item){
    
    if(chainM.avaiQueue.Size == 0){
      if(chainM.rawQueue.length == 0){
        chainM.rawQueue.push();
      }
      
      uint256 itemIdx = chainM.rawQueue.length;
      chainM.rawQueue.push();

      item = chainM.rawQueue[itemIdx];
      item.Next = 0;
      item.Prev = 0;
      item.My = itemIdx;
      
      return item;
    }

    return PopFirstItem(chainM, chainM.avaiQueue);
  }

  function PutItem(ChainManager storage chainM,
                   ChainItem storage item)
    internal{
    
    PushEndItem(chainM, chainM.avaiQueue, item);
  }
}

// File: crosslend/main.sol

pragma solidity >=0.7.0 <0.8.0;
pragma abicoder v2;







contract CrossLend is IERC777Recipient, ReentrancyGuard{
  //////////////////// for using
  using ChainQueueLib for ChainManager;
  using SafeMath for uint256;

  //////////////////// constant
  IERC1820Registry constant internal _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

  uint256 constant Decimal = 1e18;

  uint256 public OneDayTime;

  //////////////////// var
  SystemInfo internal SInfo;
  
  IERC777 public CRFI;
  IERC777 public CFil;
  IERC777 public SFil;

  //////////////////// modifier
  modifier IsAdmin() {
    require(msg.sender == SInfo.SuperAdmin || SInfo.Admins[msg.sender], "only admin");
    _;
  }

  modifier IsSuperAdmin() {
    require(SInfo.SuperAdmin == msg.sender, "only super admin");
    _;
  }

  //////////////////// event
  event AffEvent(address indexed receiver, address indexed sender, uint256 indexed affTimes, uint256 crfiInterest, uint256 cfilInterest, uint256 packageID, uint256 timestamp);

  event AffBought(address indexed affer, address indexed sender, uint256 indexed affPackageTimes, uint256 amount, uint256 packageID, uint256 timestamp);
  
  event loanCFilEvent(address indexed addr, uint256 cfilAmount, uint256 sfilAmount);

  //////////////////// constructor
  constructor(address crfiAddr, address cfilAddr, address sfilAddr) {
    CRFI = IERC777(crfiAddr);
    CFil = IERC777(cfilAddr);
    SFil = IERC777(sfilAddr);
    OneDayTime = 60 * 60 * 24;

    SInfo.SuperAdmin = msg.sender;

    SInfo.AffRate = Decimal / 10;
    SInfo.EnableAffCFil = 1;

    SInfo.ChainM.InitChainManager();
    
    ////////// add package

    SInfo.crfiMinerPerDayCFil = 1917808 * Decimal / 100;
    SInfo.crfiMinerPerDayCRFI = 821918 * Decimal / 100;

    SInfo.ParamUpdateTime = block.timestamp;
    
    // loan CFil
    ChangeLoanRate(201 * Decimal / 1000,
                   56 * Decimal / 100,
                   2300 * Decimal);
    SInfo.LoanCFil.UpdateTime = block.timestamp;

    // add crfi
    AddPackage(FinancialType.CRFI,
               0,
               (20 * Decimal) / 1000,
               Decimal);
    
    AddPackage(FinancialType.CRFI,
               90,
               (32 * Decimal) / 1000,
               (15 * Decimal) / 10);

    AddPackage(FinancialType.CRFI,
               180,
               (34 * Decimal) / 1000,
               2 * Decimal);

    AddPackage(FinancialType.CRFI,
               365,
               (36 * Decimal) / 1000,
               (25 * Decimal) / 10);
                   
    AddPackage(FinancialType.CRFI,
               540,
               (40 * Decimal) / 1000,
               3 * Decimal);
    
    // add cfil
    AddPackage(FinancialType.CFil,
               0,
               (20 * Decimal) / 1000,
               Decimal);
    
    AddPackage(FinancialType.CFil,
               90,
               (33 * Decimal) / 1000,
               (15 * Decimal) / 10);

    AddPackage(FinancialType.CFil,
               180, 
               (35 * Decimal) / 1000,
               2 * Decimal);

    AddPackage(FinancialType.CFil,
               365,
               (37 * Decimal) / 1000,
               (25 * Decimal) / 10);
                   
    AddPackage(FinancialType.CFil,
               540,
               (41 * Decimal) / 1000,
               3 * Decimal);
    
    // register interfaces
    _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
  }
  
  //////////////////// super admin func
  function AddAdmin(address admin)
    public
    IsSuperAdmin(){
    require(!SInfo.Admins[admin], "already add this admin");
    SInfo.Admins[admin] = true;
  }

  function DelAdmin(address admin)
    public
    IsSuperAdmin(){
    require(SInfo.Admins[admin], "this addr is not admin");
    SInfo.Admins[admin] = false;
  }

  function ChangeSuperAdmin(address suAdmin)
    public
    IsSuperAdmin(){
    require(suAdmin != address(0x0), "empty new super admin");

    if(suAdmin == SInfo.SuperAdmin){
      return;
    }
    
    SInfo.SuperAdmin = suAdmin;
  }

  //////////////////// admin func
  function SetMap(string memory key,
                  string memory value)
    public
    IsAdmin(){

    SInfo.kvMap[key] = value;
  }
  
  function ChangePackageRate(uint256 packageID,
                             uint256 cfilInterestRate,
                             uint256 weight)
    public
    IsAdmin(){
    
    require(packageID < SInfo.Packages.length, "packageID error");

    updateAllParam();
    
    FinancialPackage storage package = SInfo.Packages[packageID];
    package.CFilInterestRate = cfilInterestRate;

    uint256 nowTotal = package.Total.mul(package.Weight) / Decimal;
    if(package.Type == FinancialType.CRFI){
      SInfo.totalWeightCRFI = SInfo.totalWeightCRFI.sub(nowTotal);
    } else {
      SInfo.totalWeightCFil = SInfo.totalWeightCFil.sub(nowTotal);
    }

    package.Weight = weight;

    nowTotal = package.Total.mul(package.Weight) / Decimal;
    if(package.Type == FinancialType.CRFI){
      SInfo.totalWeightCRFI = SInfo.totalWeightCRFI.add(nowTotal);
    } else {
      SInfo.totalWeightCFil = SInfo.totalWeightCFil.add(nowTotal);
    }
  }

  function AddPackage(FinancialType _type,
                      uint256 dayTimes,
                      uint256 cfilInterestRate,
                      uint256 weight)
    public
    IsAdmin(){

    updateAllParam();
    
    uint256 idx = SInfo.Packages.length;
    SInfo.Packages.push();
    FinancialPackage storage package = SInfo.Packages[idx];

    package.Type = _type;
    package.Days = dayTimes;
    package.Weight = weight;
    package.CFilInterestRate = cfilInterestRate;
    package.ID = idx;
  }

  function ChangeCRFIMinerPerDay(uint256 crfi, uint256 cfil)
    public
    IsAdmin(){

    updateAllParam();

    SInfo.crfiMinerPerDayCFil = cfil;
    SInfo.crfiMinerPerDayCRFI = crfi;
  }

  function ChangeLoanRate(uint256 apy, uint256 pledgeRate, uint256 paymentDue)
    public
    IsAdmin(){

    require(pledgeRate > 0, "pledge rate can't = 0");

    SInfo.LoanCFil.APY = apy;
    SInfo.LoanCFil.PledgeRate = pledgeRate;
    SInfo.LoanCFil.PaymentDue = paymentDue;
    SInfo.LoanCFil.PaymentDue99 = paymentDue.mul(99) / 100;
  }

  function ChangeAffCFil(bool enable)
    public
    IsAdmin(){
    if(enable && SInfo.EnableAffCFil == 0){
      SInfo.EnableAffCFil = 1;
    } else if(!enable && SInfo.EnableAffCFil > 0){
      SInfo.EnableAffCFil = 0;
    }
  }

  function ChangeAffRate(uint256 rate)
    public
    IsAdmin(){
    
    SInfo.AffRate = rate;
  }

  function ChangeAffRequire(uint256 amount)
    public
    IsAdmin(){
    SInfo.AffRequire = amount;
  }

  function WithdrawCRFIInterestPool(uint256 amount)
    public
    IsAdmin(){
    SInfo.crfiInterestPool = SInfo.crfiInterestPool.sub(amount);
    CRFI.send(msg.sender, amount, "");
  }

  function WithdrawCFilInterestPool(uint256 amount)
    public
    IsAdmin(){
    SInfo.cfilInterestPool = SInfo.cfilInterestPool.sub(amount);
    CFil.send(msg.sender, amount, "");
  }
  
  //////////////////// public
  function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData)
    public
    override
    nonReentrant(){

    ////////// check
    require(userData.length > 0, "no user data");
    
    // mode = 0, normal bought financial package
    // mode = 2, charge cfil interest pool
    // mode = 3, charge crfi interest pool
    // mode = 4, loan cfil
    // mode = 5, repay cfil by loan
    (uint256 mode, uint256 param, address addr) = abi.decode(userData, (uint256,uint256, address));
    require(from != address(0x0), "from is zero");

    if(mode == 5){
      _repayLoanCFil(from, amount);
    }else if(mode == 4){
      _loanCFil(from, amount);
    }else if(mode == 3){
      require(amount > 0, "no amount");
      require(msg.sender == address(CRFI), "only charge crfi");
      SInfo.crfiInterestPool = SInfo.crfiInterestPool.add(amount);
      return;
    }else if(mode == 2){
      require(amount > 0, "no amount");
      require(msg.sender == address(CFil), "only charge cfil");
      SInfo.cfilInterestPool = SInfo.cfilInterestPool.add(amount);
      
      return;
    } else if (mode == 0){
      _buyFinancialPackage(from, param, addr, amount);
    } else {
      revert("mode error");
    }
  }
  
  function Withdraw(uint256 packageID, bool only, uint256 maxNum)
    public
    nonReentrant(){

    InvestInfo storage uInfo = SInfo.Invests[getUID(msg.sender)];
    
    uint256 cfil;
    uint256 cfilInterest;
    uint256 crfi;
    uint256 crfiInterest;

    (crfi, crfiInterest, cfil, cfilInterest) = _withdrawFinancial(uInfo, packageID, only, maxNum);

    if(crfi > 0){
      uInfo.nowInvestFinCRFI = uInfo.nowInvestFinCRFI.sub(crfi);
    }
    if(cfil > 0){
      uInfo.nowInvestFinCFil = uInfo.nowInvestFinCFil.sub(cfil);
    }

    withdrawCoin(uInfo.Addr, crfi, crfiInterest, cfil, cfilInterest);
  }

  //////////////////// view func

  function GetMap(string memory key)
    public
    view
    returns(string memory value){

    return SInfo.kvMap[key];
  }

  function GetFinancialPackage()
    public
    view
    returns(FinancialPackage[] memory packages){

    packages = new FinancialPackage[](SInfo.Packages.length);
    for(uint256 packageID = 0; packageID < SInfo.Packages.length; packageID++){
      packages[packageID] = SInfo.Packages[packageID];
      packages[packageID].CRFIInterestRateDyn = getFinancialCRFIRate(SInfo.Packages[packageID]);
    }
    
    return packages;
  }

  function GetInvesterFinRecords(address addr)
    public
    view
    returns(QueueData[] memory records){

    uint256 uid = SInfo.InvestAddrID[addr];
    if(uid == 0){
      return records;
    }

    InvestInfo storage uInfo = SInfo.Invests[uid];

    uint256 recordSize = 0;

    for(uint256 packageID = 0; packageID < SInfo.Packages.length; packageID++){
      ChainQueue storage chain = uInfo.InvestRecords[packageID];
      recordSize = recordSize.add(chain.Size);
    }

    records = new QueueData[](recordSize);
    uint256 id = 0;
    
    for(uint256 packageID = 0; packageID < SInfo.Packages.length; packageID++){
      ChainQueue storage chain = uInfo.InvestRecords[packageID];
      if(chain.Size == 0){
        continue;
      }

      ChainItem storage item = SInfo.ChainM.GetFirstItem(chain);
      for(;;){
        records[id] = item.Data;
        id++;

        if(!SInfo.ChainM.HasNext(item)){
          break;
        }

        item = SInfo.ChainM.Next(item);
      }
    }
    
    return records;
  }


  function GetSystemInfo()
    public
    view
    returns(SystemInfoView memory sInfoView){

    sInfoView.AffRate = SInfo.AffRate;
    sInfoView.AffRequire = SInfo.AffRequire;
    sInfoView.EnableAffCFil = SInfo.EnableAffCFil;
    sInfoView.NewInvestID = SInfo.NewInvestID;
    sInfoView.nowInvestCRFI = SInfo.nowInvestCRFI;
    sInfoView.nowInvestCFil = SInfo.nowInvestCFil;
    sInfoView.cfilInterestPool = SInfo.cfilInterestPool;
    sInfoView.crfiInterestPool = SInfo.crfiInterestPool;

    sInfoView.cfilLendingTotal = SInfo.cfilLendingTotal;
    sInfoView.crfiRewardTotal = SInfo.crfiRewardTotal;
    sInfoView.avaiCFilAmount = SInfo.avaiCFilAmount;
  
    sInfoView.totalWeightCFil = SInfo.totalWeightCFil;
    sInfoView.totalWeightCRFI = SInfo.totalWeightCRFI;
    sInfoView.crfiMinerPerDayCFil = SInfo.crfiMinerPerDayCFil;
    sInfoView.crfiMinerPerDayCRFI = SInfo.crfiMinerPerDayCRFI;
  
    sInfoView.ParamUpdateTime = SInfo.ParamUpdateTime;

    return sInfoView;
  }

  function GetPackages()
    public
    view
    returns(FinancialPackage[] memory financialPackages,
            LoanCFilPackage memory loanCFil){

    return (GetFinancialPackage(),
            SInfo.LoanCFil);
  }


  function GetInvestRecords(address addr)
    public
    view
    returns(QueueData[] memory records,
            LoanInvest memory loanInvest,
            InterestDetail[] memory interestDetail){

    uint256 uid = SInfo.InvestAddrID[addr];
    if(uid == 0){
      return (records, loanInvest, interestDetail);
    }

    InvestInfo storage uInfo = SInfo.Invests[uid];

    records = GetInvesterFinRecords(addr);
    interestDetail = new InterestDetail[](records.length+1);

    uint256 id = 0;
    for(; id < records.length; id++){
      (interestDetail[id].crfiInterest, interestDetail[id].cfilInterest) = _calcInvestFinancial(records[id].PackageID, records[id].Amount, records[id].ParamCRFI, records[id].ParamCFil);
    }

    interestDetail[id].cfilInterest = calcInvestLoanStatus(uInfo);
    interestDetail[id].cfilInterest = interestDetail[id].cfilInterest.add(uInfo.LoanCFil.NowInterest);

    return(records,
           uInfo.LoanCFil,
           interestDetail);
  }

  function GetInvestInfo(uint256 uid, address addr)
    public
    view
    returns(bool admin,
            InvestInfoView memory uInfoView){
    if(uid == 0){
      uid = SInfo.InvestAddrID[addr];
    }

    if(uid == 0){
      if(addr != address(0x0)){
        admin = (SInfo.SuperAdmin == addr) || (SInfo.Admins[addr]);
      }
      return (admin,
              uInfoView);
    }
    
    InvestInfo storage uInfo = SInfo.Invests[uid];

    admin = (SInfo.SuperAdmin == uInfo.Addr) || (SInfo.Admins[uInfo.Addr]);

    uInfoView.Addr = uInfo.Addr;
    uInfoView.ID = uInfo.ID;
    uInfoView.affID = uInfo.affID;
    uInfoView.totalAffTimes = uInfo.totalAffTimes;
    uInfoView.totalAffPackageTimes = uInfo.totalAffPackageTimes;
    uInfoView.totalAffCRFI = uInfo.totalAffCRFI;
    uInfoView.totalAffCFil = uInfo.totalAffCFil;
    uInfoView.nowInvestFinCRFI = uInfo.nowInvestFinCRFI;
    uInfoView.nowInvestFinCFil = uInfo.nowInvestFinCFil;

    return (admin,
            uInfoView);
  }

  function calcSFilToCFil(uint256 sfil)
    public
    view
    returns(uint256 cfil){
    cfil = sfil.mul(SInfo.LoanCFil.PledgeRate) / Decimal;
    return cfil;
  }

  function calcCFilToSFil(uint256 cfil)
    public
    view
    returns(uint256 sfil){

    sfil = cfil.mul(Decimal) / SInfo.LoanCFil.PledgeRate;
    return sfil;
  }
  
  //////////////////// for debug

  function getChainMDetail()
    public
    view
    returns(ChainManager memory chaimM){

    return SInfo.ChainM;
  }

  function getInvestChainDetail(uint256 id)
    public
    view
    returns(ChainQueue[] memory chains){

    InvestInfo storage uInfo = SInfo.Invests[id];

    chains = new ChainQueue[](SInfo.Packages.length);

    for(uint256 packageID = 0; packageID < SInfo.Packages.length; packageID++){
      chains[packageID] = uInfo.InvestRecords[packageID];
    }

    return chains;
  }
  
  //////////////////// internal func
  function _repayLoanCFil(address from,
                          uint256 cfilAmount)
    internal{
    require(cfilAmount > 0, "no cfil amount");
    require(msg.sender == address(CFil), "not cfil coin type");

    InvestInfo storage uInfo = SInfo.Invests[getUID(from)];
    updateInvesterLoanCFil(uInfo);

    // deal interest
    uint256 repayInterest = cfilAmount;
    if(uInfo.LoanCFil.NowInterest < cfilAmount){
      repayInterest = uInfo.LoanCFil.NowInterest;
    }

    uInfo.LoanCFil.NowInterest = uInfo.LoanCFil.NowInterest.sub(repayInterest);
    SInfo.cfilInterestPool = SInfo.cfilInterestPool.add(repayInterest);
    cfilAmount = cfilAmount.sub(repayInterest);

    // deal lending
    if(cfilAmount == 0){
      return;
    }

    uint256 repayLending = cfilAmount;
    if(uInfo.LoanCFil.Lending < cfilAmount){
      repayLending = uInfo.LoanCFil.Lending;
    }

    uint256 pledge = repayLending.mul(uInfo.LoanCFil.Pledge) / uInfo.LoanCFil.Lending;
    uInfo.LoanCFil.Lending = uInfo.LoanCFil.Lending.sub(repayLending);
    uInfo.LoanCFil.Pledge = uInfo.LoanCFil.Pledge.sub(pledge);
    SInfo.cfilLendingTotal = SInfo.cfilLendingTotal.sub(repayLending);
    SInfo.avaiCFilAmount = SInfo.avaiCFilAmount.add(repayLending);
    cfilAmount = cfilAmount.sub(repayLending);

    if(pledge > 0){
      SFil.send(from, pledge, "");
    }
    
    if(cfilAmount > 0){
      CFil.send(from, cfilAmount, "");
    }
  }
  
  function _loanCFil(address from,
                     uint256 sfilAmount)
    internal{

    require(sfilAmount > 0, "no sfil amount");
    require(msg.sender == address(SFil), "not sfil coin type");

    uint256 cfilAmount = calcSFilToCFil(sfilAmount);
    require(cfilAmount <= SInfo.avaiCFilAmount, "not enough cfil to loan");
    require(cfilAmount >= SInfo.LoanCFil.PaymentDue99, "cfil amount is too small");

    InvestInfo storage uInfo = SInfo.Invests[getUID(from)];
    updateInvesterLoanCFil(uInfo);
    
    if(uInfo.LoanCFil.Param < SInfo.LoanCFil.Param){
      uInfo.LoanCFil.Param = SInfo.LoanCFil.Param;
    }
    uInfo.LoanCFil.Lending = uInfo.LoanCFil.Lending.add(cfilAmount);
    uInfo.LoanCFil.Pledge = uInfo.LoanCFil.Pledge.add(sfilAmount);

    SInfo.cfilLendingTotal = SInfo.cfilLendingTotal.add(cfilAmount);
    SInfo.avaiCFilAmount = SInfo.avaiCFilAmount.sub(cfilAmount);

    CFil.send(from, cfilAmount, "");
    emit loanCFilEvent(from, cfilAmount, sfilAmount);
  }
  
  function _buyFinancialPackage(address from,
                                uint256 packageID,
                                address affAddr,
                                uint256 amount)
    internal{
    // check
    require(amount > 0, "no amount");
    require(packageID < SInfo.Packages.length, "invalid packageID");
    FinancialPackage storage package = SInfo.Packages[packageID];
    if(package.Type == FinancialType.CRFI){
      require(msg.sender == address(CRFI), "not CRFI coin type");
    }else if(package.Type == FinancialType.CFil){
      require(msg.sender == address(CFil), "not CFil coin type");
    } else {
      revert("not avai package type");
    }

    updateAllParam();
    
    // exec
    InvestInfo storage uInfo = SInfo.Invests[getUID(from)];    

    uint256 affID = uInfo.affID;

    if(affID == 0 && affAddr != from && affAddr != address(0x0)){
      uInfo.affID = getUID(affAddr);
      affID = uInfo.affID;
    }

    if(package.Days == 0){
      affID = 0;
    }

    if(affID != 0){
      InvestInfo storage affInfo = SInfo.Invests[affID];
      affInfo.totalAffPackageTimes++;      
      emit AffBought(affAddr, from, affInfo.totalAffPackageTimes, amount, packageID, block.timestamp); 
    }

    ChainQueue storage recordQ = uInfo.InvestRecords[package.ID];

    ChainItem storage item = SInfo.ChainM.GetAvaiItem();

    item.Data.Type = package.Type;
    item.Data.PackageID = package.ID;
    item.Data.Days = package.Days;
    item.Data.EndTime = block.timestamp.add(package.Days.mul(OneDayTime));
    item.Data.AffID = affID;
    item.Data.Amount = amount;
    item.Data.ParamCRFI = package.ParamCRFI;
    item.Data.ParamCFil = package.ParamCFil;

    SInfo.ChainM.PushEndItem(recordQ, item);

    ////////// for statistic
    package.Total = package.Total.add(amount);
    if(package.Type == FinancialType.CRFI){
      uInfo.nowInvestFinCRFI = uInfo.nowInvestFinCRFI.add(amount);
      SInfo.nowInvestCRFI = SInfo.nowInvestCRFI.add(amount);
      SInfo.totalWeightCRFI = SInfo.totalWeightCRFI.add(amount.mul(package.Weight) / Decimal);
    } else if(package.Type == FinancialType.CFil){
      uInfo.nowInvestFinCFil = uInfo.nowInvestFinCFil.add(amount);
      SInfo.nowInvestCFil = SInfo.nowInvestCFil.add(amount);
      SInfo.avaiCFilAmount = SInfo.avaiCFilAmount.add(amount);
      SInfo.totalWeightCFil = SInfo.totalWeightCFil.add(amount.mul(package.Weight) / Decimal);
    }
  }

  function _withdrawFinancial(InvestInfo storage uInfo, uint256 onlyPackageID, bool only, uint256 maxNum)
    internal
    returns(uint256 crfi,
            uint256 crfiInterest,
            uint256 cfil,
            uint256 cfilInterest){

    updateAllParam();

    if(!only){
      onlyPackageID = 0;
    }

    if(maxNum == 0){
      maxNum -= 1;
    }
    
    (uint256 packageID, ChainItem storage item, bool has) = getFirstValidItem(uInfo, onlyPackageID);
    
    while(has && maxNum > 0 && (!only || packageID == onlyPackageID)){
      maxNum--;
      QueueData storage data = item.Data;
      FinancialPackage storage package = SInfo.Packages[data.PackageID];

      (uint256 _crfiInterest, uint256 _cfilInterest) = calcInvestFinancial(data);
      crfiInterest = crfiInterest.add(_crfiInterest);
      cfilInterest = cfilInterest.add(_cfilInterest);

      addAffCRFI(uInfo, data, _crfiInterest, _cfilInterest);

      if((block.timestamp > data.EndTime && data.Days > 0) || (data.Days ==0 && only)){
        package.Total = package.Total.sub(data.Amount);
        if(data.Type == FinancialType.CFil){
          cfil = cfil.add(data.Amount);
          SInfo.totalWeightCFil = SInfo.totalWeightCFil.sub(data.Amount.mul(package.Weight) / Decimal);
        } else {
          crfi = crfi.add(data.Amount);
          SInfo.totalWeightCRFI = SInfo.totalWeightCRFI.sub(data.Amount.mul(package.Weight) / Decimal);
        }
        SInfo.ChainM.PopPutFirst(uInfo.InvestRecords[packageID]);
        (packageID, item, has) = getFirstValidItem(uInfo, packageID);
      } else {
        data.ParamCRFI = package.ParamCRFI;
        data.ParamCFil = package.ParamCFil;
        (packageID, item, has) = getNextItem(uInfo, packageID, item);
      }
    }

    return (crfi, crfiInterest, cfil, cfilInterest);
  }
        
  function getUID(address addr) internal returns(uint256 uID){
    uID = SInfo.InvestAddrID[addr];
    if(uID != 0){
      return uID;
    }
    
    SInfo.NewInvestID++;
    uID = SInfo.NewInvestID;

    InvestInfo storage uInfo = SInfo.Invests[uID];
    uInfo.Addr = addr;
    uInfo.ID = uID;
        
    SInfo.InvestAddrID[addr] = uID;
    return uID;
  }

  function calcSystemLoanStatus()
    internal
    view
    returns(uint256 param){

    if(block.timestamp == SInfo.LoanCFil.UpdateTime){
      return SInfo.LoanCFil.Param;
    }

    uint256 diffSec = block.timestamp.sub(SInfo.LoanCFil.UpdateTime);

    param = SInfo.LoanCFil.Param.add(calcInterest(Decimal, SInfo.LoanCFil.APY, diffSec));

    return param;
  }

  function calcInvestLoanStatus(InvestInfo storage uInfo)
    internal
    view
    returns(uint256 cfilInterest){

    if(uInfo.LoanCFil.Lending == 0){
      return 0;
    }
    
    uint256 param = calcSystemLoanStatus();
    if(uInfo.LoanCFil.Param >= param){
      return 0;
    }
    
    cfilInterest = uInfo.LoanCFil.Lending.mul(param.sub(uInfo.LoanCFil.Param)) / Decimal;
    
    return cfilInterest;
  }

  function updateSystemLoanStatus()
    internal{
    uint256 param;
    param = calcSystemLoanStatus();
    if(param <= SInfo.LoanCFil.Param){
      return;
    }

    SInfo.LoanCFil.Param = param;
    SInfo.LoanCFil.UpdateTime = block.timestamp;
  }

  function updateInvesterLoanCFil(InvestInfo storage uInfo)
    internal{
    updateSystemLoanStatus();
    uint256 cfilInterest = calcInvestLoanStatus(uInfo);
    if(cfilInterest == 0){
      return;
    }

    uInfo.LoanCFil.Param = SInfo.LoanCFil.Param;
    uInfo.LoanCFil.NowInterest = uInfo.LoanCFil.NowInterest.add(cfilInterest);
  }

  function calcInterest(uint256 amount, uint256 rate, uint256 sec)
    internal
    view
    returns(uint256){
    
    return amount.mul(rate).mul(sec) / 365 / OneDayTime / Decimal;    
  }

  function getFirstValidItem(InvestInfo storage uInfo, uint256 packageID)
    internal
    view
    returns(uint256 newPackageID, ChainItem storage item, bool has){
    
    while(packageID < SInfo.Packages.length){
      ChainQueue storage chain = uInfo.InvestRecords[packageID];
      if(chain.Size == 0){
        packageID++;
        continue;
      }
      item = SInfo.ChainM.GetFirstItem(chain);
      return (packageID, item, true);
    }

    return (0, SInfo.ChainM.GetNullItem(), false);
  }

  function getNextItem(InvestInfo storage uInfo,
                       uint256 packageID,
                       ChainItem storage item)
    internal
    view
    returns(uint256, ChainItem storage, bool){

    if(packageID >= SInfo.Packages.length){
      return (0, item, false);
    }

    if(SInfo.ChainM.HasNext(item)){
      return (packageID, SInfo.ChainM.Next(item), true);
    }

    return getFirstValidItem(uInfo, packageID+1);
  }

  function addAffCRFI(InvestInfo storage uInfo, QueueData storage data, uint256 crfiInterest, uint256 cfilInterest)
    internal{
    if(data.Days == 0){
      return;
    }
    
    uint256 affID = data.AffID;
    if(affID == 0){
      return;
    }
    InvestInfo storage affInfo = SInfo.Invests[affID];
    if(affInfo.nowInvestFinCFil < SInfo.AffRequire){
      return;
    }
    
    uint256 affCRFI = crfiInterest.mul(SInfo.AffRate) / Decimal;
    uint256 affCFil;

    bool emitFlag;
    if(affCRFI != 0){
      emitFlag = true;
      affInfo.totalAffCRFI = affInfo.totalAffCRFI.add(affCRFI);
    }

    if(SInfo.EnableAffCFil > 0){
      affCFil = cfilInterest.mul(SInfo.AffRate) / Decimal;
      if(affCFil != 0){
        emitFlag = true;
        affInfo.totalAffCFil = affInfo.totalAffCFil.add(affCFil);
      }
    }

    if(!emitFlag){
      return;
    }
    
    affInfo.totalAffTimes++;
    emit AffEvent(affInfo.Addr, uInfo.Addr, affInfo.totalAffTimes, affCRFI, affCFil, data.PackageID, block.timestamp);

    withdrawCoin(affInfo.Addr, 0, affCRFI, 0, affCFil);

  }

  function withdrawCoin(address addr,
                        uint256 crfi,
                        uint256 crfiInterest,
                        uint256 cfil,
                        uint256 cfilInterest)
    internal{
    
    require(cfil <= SInfo.nowInvestCFil, "cfil invest now error");
    require(cfil <= SInfo.avaiCFilAmount, "not enough cfil to withdraw");    
    require(crfi <= SInfo.nowInvestCRFI, "crfi invest now error");
    
    if(cfil > 0){
      SInfo.nowInvestCFil = SInfo.nowInvestCFil.sub(cfil);
      SInfo.avaiCFilAmount = SInfo.avaiCFilAmount.sub(cfil);
    }

    if(crfi > 0){
      SInfo.nowInvestCRFI = SInfo.nowInvestCRFI.sub(crfi);
    }
    
    if(cfilInterest > 0){
      require(SInfo.cfilInterestPool >= cfilInterest, "cfil interest pool is not enough");
      SInfo.cfilInterestPool = SInfo.cfilInterestPool.sub(cfilInterest);
      cfil = cfil.add(cfilInterest);
    }

    if(crfiInterest > 0){
      require(SInfo.crfiInterestPool >= crfiInterest, "crfi interest pool is not enough");
      SInfo.crfiInterestPool = SInfo.crfiInterestPool.sub(crfiInterest);
      crfi = crfi.add(crfiInterest);
      SInfo.crfiRewardTotal = SInfo.crfiRewardTotal.add(crfiInterest);
    }

    if(cfil > 0){
      CFil.send(addr, cfil, "");
    }

    if(crfi > 0){
      CRFI.send(addr, crfi, "");
    }
  }

  //////////////////// for update param
  
  function getFinancialCRFIRate(FinancialPackage storage package)
    internal
    view
    returns(uint256 rate){
    if(package.Total == 0){
      return 0;
    }
    
    uint256 x = package.Total.mul(package.Weight);
    if(package.Type == FinancialType.CRFI){
      if(SInfo.totalWeightCRFI == 0){
        return 0;
      }
      rate = x.mul(SInfo.crfiMinerPerDayCRFI) / SInfo.totalWeightCRFI;
    } else {
      if(SInfo.totalWeightCFil == 0){
        return 0;
      }
      rate = x.mul(SInfo.crfiMinerPerDayCFil) / SInfo.totalWeightCFil;
    }

    rate = rate.mul(365) / package.Total ;
    
    return rate;
  }

  function calcFinancialParam(FinancialPackage storage package)
    internal
    view
    returns(uint256 paramCRFI,
            uint256 paramCFil){

    uint256 diffSec = block.timestamp.sub(SInfo.ParamUpdateTime);
    if(diffSec == 0){
      return (package.ParamCRFI, package.ParamCFil);
    }

    paramCFil = package.ParamCFil.add(calcInterest(Decimal, package.CFilInterestRate, diffSec));
    paramCRFI = package.ParamCRFI.add(calcInterest(Decimal,
                                                   getFinancialCRFIRate(package),
                                                   diffSec));
    return (paramCRFI, paramCFil);
  }

  function updateFinancialParam(FinancialPackage storage package)
    internal{

    (package.ParamCRFI, package.ParamCFil) = calcFinancialParam(package);
  }

  function updateAllParam()
    internal{
    if(block.timestamp == SInfo.ParamUpdateTime){
      return;
    }

    for(uint256 i = 0; i < SInfo.Packages.length; i++){
      updateFinancialParam(SInfo.Packages[i]);
    }

    SInfo.ParamUpdateTime = block.timestamp;
  }

  function _calcInvestFinancial(uint256 packageID, uint256 amount, uint256 paramCRFI, uint256 paramCFil)
    internal
    view
    returns(uint256 crfiInterest, uint256 cfilInterest){
    
    FinancialPackage storage package = SInfo.Packages[packageID];

    (uint256 packageParamCRFI, uint256 packageParamCFil) = calcFinancialParam(package);
    crfiInterest = amount.mul(packageParamCRFI.sub(paramCRFI)) / Decimal;
    cfilInterest = amount.mul(packageParamCFil.sub(paramCFil)) / Decimal;

    return(crfiInterest, cfilInterest);
  }

  function calcInvestFinancial(QueueData storage data)
    internal
    view
    returns(uint256 crfiInterest, uint256 cfilInterest){
    return _calcInvestFinancial(data.PackageID, data.Amount, data.ParamCRFI, data.ParamCFil);
  }
}