// Dependency file: @openzeppelin/contracts/GSN/Context.sol

// pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Dependency file: contracts/interfaces/IKULAPDex.sol

// pragma solidity 0.5.17;

// import "../helper/ERC20Interface.sol";
// import "./IKULAPTradingProxy.sol";

interface IKULAPDex {
  // /**
  // * @dev when new trade occure (and success), this event will be boardcast.
  // * @param _src Source token
  // * @param _srcAmount amount of source tokens
  // * @param _dest   Destination token
  // * @return _destAmount: amount of actual destination tokens
  // */
  // event Trade(ERC20 _src, uint256 _srcAmount, ERC20 _dest, uint256 _destAmount);

  /**
  * @notice use token address 0xeee...eee for ether
  * @dev makes a trade between src and dest token by tradingProxyIndex
  * Ex1: trade 0.5 ETH -> EOS
  * 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
  * Ex2: trade 30 EOS -> ETH
  * 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
  * @param tradingProxyIndex index of trading proxy
  * @param src Source token
  * @param srcAmount amount of source tokens
  * @param dest Destination token
  * @param minDestAmount minimun destination amount
  * @param partnerIndex index of partnership for revenue sharing
  * @return amount of actual destination tokens
  */
  function trade(
      uint256   tradingProxyIndex,
      ERC20     src,
      uint256   srcAmount,
      ERC20     dest,
      uint256   minDestAmount,
      uint256   partnerIndex
    )
    external
    payable
    returns(uint256);
  
  /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade with multiple routes ex. UNI -> ETH -> DAI
    * Ex: trade 50 UNI -> ETH -> DAI
    * Step1: trade 50 UNI -> ETH
    * Step2: trade xx ETH -> DAI
    * srcAmount: 50 * 1e18
    * routes: [0, 1]
    * srcTokens: [0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE]
    * destTokens: [0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, 0x6B175474E89094C44Da98b954EedeAC495271d0F]
    * @param srcAmount amount of source tokens
    * @param minDestAmount minimun destination amount
    * @param routes Trading paths
    * @param srcTokens all source of token pairs
    * @param destTokens all destination of token pairs
    * @param partnerIndex index of partnership for revenue sharing
    * @return amount of actual destination tokens
    */
    function tradeRoutes(
      uint256   srcAmount,
      uint256   minDestAmount,
      uint256[] calldata routes,
      ERC20[]   calldata srcTokens,
      ERC20[]   calldata destTokens,
      uint256   partnerIndex
    )
    external
    payable
    returns(uint256);
  
  /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade with split volumes to multiple-routes ex. UNI -> ETH (5%, 15% and 80%)
    * @param routes Trading paths
    * @param src Source token
    * @param srcAmounts amount of source tokens
    * @param dest Destination token
    * @param minDestAmount minimun destination amount
    * @param partnerIndex index of partnership for revenue sharing
    * @return amount of actual destination tokens
    */
    function splitTrades(
      uint256[] calldata routes,
      ERC20     src,
      uint256[] calldata srcAmounts,
      ERC20     dest,
      uint256   minDestAmount,
      uint256   partnerIndex
    )
    external
    payable
    returns(uint256);
  
  /**
  * @notice use token address 0xeee...eee for ether
  * @dev get amount of destination token for given source token amount
  * @param tradingProxyIndex index of trading proxy
  * @param src Source token
  * @param dest Destination token
  * @param srcAmount amount of source tokens
  * @return amount of actual destination tokens
  */
  function getDestinationReturnAmount(
    uint256 tradingProxyIndex,
    ERC20   src,
    ERC20   dest,
    uint256 srcAmount,
    uint256 partnerIndex
  )
    external
    view
    returns(uint256);
  
  function getDestinationReturnAmountForSplitTrades(
    uint256[] calldata routes,
    ERC20     src,
    uint256[] calldata srcAmounts,
    ERC20     dest,
    uint256   partnerIndex
  )
    external
    view
    returns(uint256);
  
  function getDestinationReturnAmountForTradeRoutes(
    ERC20     src,
    uint256   srcAmount,
    ERC20     dest,
    address[] calldata _tradingPaths,
    uint256   partnerIndex
  )
    external
    view
    returns(uint256);
}

// Dependency file: contracts/interfaces/IKULAPTradingProxy.sol

// pragma solidity 0.5.17;

// import "../helper/ERC20Interface.sol";

/**
 * @title KULAP Trading Proxy
 * @dev The KULAP trading proxy interface has an standard functions and event
 * for other smart contract to implement to join KULAP Dex as Market Maker.
 */
interface IKULAPTradingProxy {
    /**
    * @dev when new trade occure (and success), this event will be boardcast.
    * @param _src Source token
    * @param _srcAmount amount of source tokens
    * @param _dest   Destination token
    * @return _destAmount: amount of actual destination tokens
    */
    event Trade(ERC20 _src, uint256 _srcAmount, ERC20 _dest, uint256 _destAmount);

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between src and dest token
    * @param _src Source token
    * @param _dest   Destination token
    * @param _srcAmount amount of source tokens
    * @return _destAmount: amount of actual destination tokens
    */
    function trade(
        ERC20 _src,
        ERC20 _dest,
        uint256 _srcAmount
    )
        external
        payable
        returns(uint256 _destAmount);

    /**
    * @dev provide destinationm token amount for given source amount
    * @param _src Source token
    * @param _dest Destination token
    * @param _srcAmount Amount of source tokens
    * @return _destAmount: amount of expected destination tokens
    */
    function getDestinationReturnAmount(
        ERC20 _src,
        ERC20 _dest,
        uint256 _srcAmount
    )
        external
        view
        returns(uint256 _destAmount);

    /**
    * @dev provide source token amount for given destination amount
    * @param _src Source token
    * @param _dest Destination token
    * @param _destAmount Amount of destination tokens
    * @return _srcAmount: amount of expected source tokens
    */
    // function getSourceReturnAmount(
    //     ERC20 _src,
    //     ERC20 _dest,
    //     uint256 _destAmount
    // )
    //     external
    //     view
    //     returns(uint256 _srcAmount);
}
// Dependency file: contracts/helper/ERC20Interface.sol

// pragma solidity 0.5.17;

/**
 * @title ERC20
 * @dev The ERC20 interface has an standard functions and event
 * for erc20 compatible token on Ethereum blockchain.
 */
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external; // Some ERC20 doesn't have return
    function transferFrom(address _from, address _to, uint _value) external; // Some ERC20 doesn't have return
    function approve(address _spender, uint _value) external; // Some ERC20 doesn't have return
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
// Dependency file: @openzeppelin/contracts/ownership/Ownable.sol

// pragma solidity ^0.5.0;

// import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

// pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Dependency file: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

pragma solidity 0.5.17;

// import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/ownership/Ownable.sol";
// import "./helper/ERC20Interface.sol";
// import "./interfaces/IKULAPTradingProxy.sol";
// import "./interfaces/IKULAPDex.sol";

contract ProxyManagement is Ownable {
    /**
    * @dev Struct of trading proxy
    * @param name Name of trading proxy.
    * @param enable The flag of trading proxy to check is trading proxy enable.
    * @param proxy The address of trading proxy.
    */
    struct Proxy {
      string name;
      bool enable;
      IKULAPTradingProxy proxy;
    }

    event AddedTradingProxy(
        address indexed addedBy,
        string name,
        IKULAPTradingProxy indexed proxyAddress,
        uint256 indexed index
    );

    event EnabledTradingProxy(
        address indexed enabledBy,
        string name,
        IKULAPTradingProxy proxyAddress,
        uint256 indexed index
    );

    event DisabledTradingProxy(
        address indexed disabledBy,
        string name,
        IKULAPTradingProxy indexed proxyAddress,
        uint256 indexed index
    );

    Proxy[] public tradingProxies; // list of trading proxies

    modifier onlyTradingProxyEnabled(uint _index) {
        require(tradingProxies[_index].enable == true, "This trading proxy is disabled");
        _;
    }

    modifier onlyTradingProxyDisabled(uint _index) {
        require(tradingProxies[_index].enable == false, "This trading proxy is enabled");
        _;
    }

    /**
    * @dev Function for adding new trading proxy
    * @param _name Name of trading proxy.
    * @param _proxyAddress The address of trading proxy.
    * @return length of trading proxies.
    */
    function addTradingProxy(
        string memory _name,
        IKULAPTradingProxy _proxyAddress
    )
      public
      onlyOwner
    {
        tradingProxies.push(Proxy({
            name: _name,
            enable: true,
            proxy: _proxyAddress
        }));
        emit AddedTradingProxy(msg.sender, _name, _proxyAddress, tradingProxies.length - 1);
    }

    /**
    * @dev Function for disable trading proxy by index
    * @param _index The uint256 of trading proxy index.
    * @return length of trading proxies.
    */
    function disableTradingProxy(
        uint256 _index
    )
        public
        onlyOwner
        onlyTradingProxyEnabled(_index)
    {
        tradingProxies[_index].enable = false;
        emit DisabledTradingProxy(msg.sender, tradingProxies[_index].name, tradingProxies[_index].proxy, _index);
    }

    /**
    * @dev Function for enale trading proxy by index
    * @param _index The uint256 of trading proxy index.
    * @return length of trading proxies.
    */
    function enableTradingProxy(
        uint256 _index
    )
        public
        onlyOwner
        onlyTradingProxyDisabled(_index)
    {
        tradingProxies[_index].enable = true;
        emit EnabledTradingProxy(msg.sender, tradingProxies[_index].name, tradingProxies[_index].proxy, _index);
    }

    /**
    * @dev Function for get amount of trading proxy
    * @return Amount of trading proxies.
    */
    function getProxyCount() public view returns (uint256) {
        return tradingProxies.length;
    }

    /**
    * @dev Function for get enable status of trading proxy
    * @param _index The uint256 of trading proxy index.
    * @return enable status of trading proxy.
    */
    function isTradingProxyEnable(uint256 _index) public view returns (bool) {
        return tradingProxies[_index].enable;
    }
}

/*
* Fee collection by partner reference
*/
contract Partnership is ProxyManagement {
    using SafeMath for uint256;

    struct Partner {
      address wallet;       // To receive fee on the KULAP Dex network
      uint16 fee;           // fee in bps
      bytes16 name;         // Partner reference
    }

    mapping(uint256 => Partner) public partners;

    constructor() public {
        Partner memory partner = Partner(msg.sender, 0, "KULAP");
        partners[0] = partner;
    }

    function updatePartner(uint256 index, address wallet, uint16 fee, bytes16 name)
        external
        onlyOwner
    {
        Partner memory partner = Partner(wallet, fee, name);
        partners[index] = partner;
    }

    function amountWithFee(uint256 amount, uint256 partnerIndex)
        internal
        view
        returns(uint256 remainingAmount)
    {
        Partner storage partner = partners[partnerIndex];
        if (partner.fee == 0) {
            return amount;
        }
        uint256 fee = amount.mul(partner.fee).div(10000);
        return amount.sub(fee);
    }

    function collectFee(uint256 partnerIndex, uint256 amount, ERC20 token)
        internal
        returns(uint256 remainingAmount)
    {
        Partner storage partner = partners[partnerIndex];
        if (partner.fee == 0) {
            return amount;
        }
        uint256 fee = amount.mul(partner.fee).div(10000);
        require(fee < amount, "fee exceeds return amount!");
        token.transfer(partner.wallet, fee);
        return amount.sub(fee);
    }
}

contract KULAPDex is IKULAPDex, Partnership, ReentrancyGuard {
    event Trade(
        address indexed srcAsset, // Source
        uint256         srcAmount,
        address indexed destAsset, // Destination
        uint256         destAmount,
        address indexed trader, // User
        uint256         fee // System fee
    );

    using SafeMath for uint256;
    ERC20 public etherERC20 = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between Ether to token by tradingProxyIndex
    * @param tradingProxyIndex index of trading proxy
    * @param srcAmount amount of source tokens
    * @param dest Destination token
    * @return amount of actual destination tokens
    */
    function _tradeEtherToToken(
        uint256 tradingProxyIndex,
        uint256 srcAmount,
        ERC20 dest
    )
        private
        returns(uint256)
    {
        // Load trading proxy
        IKULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex].proxy;
        // Trade to proxy
        uint256 destAmount = tradingProxy.trade.value(srcAmount)(
            etherERC20,
            dest,
            srcAmount
        );
        return destAmount;
    }

    // Receive ETH in case of trade Token -> ETH, will get ETH back from trading proxy
    function () external payable {}

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between token to Ether by tradingProxyIndex
    * @param tradingProxyIndex index of trading proxy
    * @param src Source token
    * @param srcAmount amount of source tokens
    * @return amount of actual destination tokens
    */
    function _tradeTokenToEther(
        uint256 tradingProxyIndex,
        ERC20 src,
        uint256 srcAmount
    )
        private
        returns(uint256)
    {
        // Load trading proxy
        IKULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex].proxy;
        // Approve to TradingProxy
        src.approve(address(tradingProxy), srcAmount);
        // Trande to proxy
        uint256 destAmount = tradingProxy.trade(
            src,
            etherERC20,
            srcAmount
        );
        return destAmount;
    }

    /**
    * @dev makes a trade between token to token by tradingProxyIndex
    * @param tradingProxyIndex index of trading proxy
    * @param src Source token
    * @param srcAmount amount of source tokens
    * @param dest Destination token
    * @return amount of actual destination tokens
    */
    function _tradeTokenToToken(
        uint256 tradingProxyIndex,
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest
    )
        private
        returns(uint256)
    {
        // Load trading proxy
        IKULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex].proxy;
        // Approve to TradingProxy
        src.approve(address(tradingProxy), srcAmount);
        // Trande to proxy
        uint256 destAmount = tradingProxy.trade(
            src,
            dest,
            srcAmount
        );
        return destAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between src and dest token by tradingProxyIndex
    * Ex1: trade 0.5 ETH -> DAI
    * 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    * Ex2: trade 30 DAI -> ETH
    * 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    * @param _tradingProxyIndex index of trading proxy
    * @param _src Source token
    * @param _srcAmount amount of source tokens
    * @param _dest Destination token
    * @return amount of actual destination tokens
    */
    function _trade(
        uint256             _tradingProxyIndex,
        ERC20               _src,
        uint256             _srcAmount,
        ERC20               _dest
    )
        private
        onlyTradingProxyEnabled(_tradingProxyIndex)
        returns(uint256)
    {
        // Destination amount
        uint256 destAmount;
        // Record src/dest asset for later consistency check.
        uint256 srcAmountBefore;
        uint256 destAmountBefore;

        if (etherERC20 == _src) { // Source
            srcAmountBefore = address(this).balance;
        } else {
            srcAmountBefore = _src.balanceOf(address(this));
        }
        if (etherERC20 == _dest) { // Dest
            destAmountBefore = address(this).balance;
        } else {
            destAmountBefore = _dest.balanceOf(address(this));
        }
        if (etherERC20 == _src) { // Trade ETH -> Token
            destAmount = _tradeEtherToToken(_tradingProxyIndex, _srcAmount, _dest);
        } else if (etherERC20 == _dest) { // Trade Token -> ETH
            destAmount = _tradeTokenToEther(_tradingProxyIndex, _src, _srcAmount);
        } else { // Trade Token -> Token
            destAmount = _tradeTokenToToken(_tradingProxyIndex, _src, _srcAmount, _dest);
        }

        // Recheck if src/dest amount correct
        if (etherERC20 == _src) { // Source
            require(address(this).balance == srcAmountBefore.sub(_srcAmount), "source amount mismatch after trade");
        } else {
            require(_src.balanceOf(address(this)) == srcAmountBefore.sub(_srcAmount), "source amount mismatch after trade");
        }
        if (etherERC20 == _dest) { // Dest
            require(address(this).balance == destAmountBefore.add(destAmount), "destination amount mismatch after trade");
        } else {
            require(_dest.balanceOf(address(this)) == destAmountBefore.add(destAmount), "destination amount mismatch after trade");
        }
        return destAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between src and dest token by tradingProxyIndex
    * Ex1: trade 0.5 ETH -> DAI
    * 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    * Ex2: trade 30 DAI -> ETH
    * 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    * @param tradingProxyIndex index of trading proxy
    * @param src Source token
    * @param srcAmount amount of source tokens
    * @param dest Destination token
    * @param minDestAmount minimun destination amount
    * @param partnerIndex index of partnership for revenue sharing
    * @return amount of actual destination tokens
    */
    function trade(
        uint256   tradingProxyIndex,
        ERC20     src,
        uint256   srcAmount,
        ERC20     dest,
        uint256   minDestAmount,
        uint256   partnerIndex
    )
        external
        payable
        nonReentrant
        returns(uint256)
    {
        uint256 destAmount;
        // Prepare source's asset
        if (etherERC20 != src) {
            src.transferFrom(msg.sender, address(this), srcAmount); // Transfer token to this address
        }
        // Trade with proxy
        destAmount = _trade(tradingProxyIndex, src, srcAmount, dest);
        // Throw exception if destination amount doesn't meet user requirement.
        require(destAmount >= minDestAmount, "destination amount is too low.");
        if (etherERC20 == dest) {
            (bool success, ) = msg.sender.call.value(destAmount)(""); // Send back ether to sender
            require(success, "Transfer ether back to caller failed.");
        } else { // Send back token to sender
            // Some ERC20 Smart contract not return Bool, so we can't use require(dest.transfer(x, y)); here
            dest.transfer(msg.sender, destAmount);
        }

        // Collect fee
        uint256 remainingAmount = collectFee(partnerIndex, destAmount, dest);

        emit Trade(address(src), srcAmount, address(dest), remainingAmount, msg.sender, 0);
        return remainingAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade with multiple routes ex. UNI -> ETH -> DAI
    * Ex: trade 50 UNI -> ETH -> DAI
    * Step1: trade 50 UNI -> ETH
    * Step2: trade xx ETH -> DAI
    * srcAmount: 50 * 1e18
    * routes: [0, 1]
    * srcTokens: [0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE]
    * destTokens: [0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, 0x6B175474E89094C44Da98b954EedeAC495271d0F]
    * @param srcAmount amount of source tokens
    * @param minDestAmount minimun destination amount
    * @param routes Trading paths
    * @param srcTokens all source of token pairs
    * @param destTokens all destination of token pairs
    * @param partnerIndex index of partnership for revenue sharing
    * @return amount of actual destination tokens
    */
    function tradeRoutes(
        uint256   srcAmount,
        uint256   minDestAmount,
        uint256[] calldata routes,
        ERC20[]   calldata srcTokens,
        ERC20[]   calldata destTokens,
        uint256   partnerIndex
    )
        external
        payable
        nonReentrant
        returns(uint256)
    {
        require(routes.length > 0, "routes can not be empty");
        require(routes.length == srcTokens.length && routes.length == destTokens.length, "Parameter value lengths mismatch");

        uint256 remainingAmount;
        {
          uint256 destAmount;
          if (etherERC20 != srcTokens[0]) {
              srcTokens[0].transferFrom(msg.sender, address(this), srcAmount); // Transfer token to This address
          }
          uint256 pathSrcAmount = srcAmount;
          for (uint i = 0; i < routes.length; i++) {
              uint256 tradingProxyIndex = routes[i];
              ERC20 pathSrc = srcTokens[i];
              ERC20 pathDest = destTokens[i];
              destAmount = _trade(tradingProxyIndex, pathSrc, pathSrcAmount, pathDest);
              pathSrcAmount = destAmount;
          }
          // Throw exception if destination amount doesn't meet user requirement.
          require(destAmount >= minDestAmount, "destination amount is too low.");
          if (etherERC20 == destTokens[destTokens.length - 1]) { // Trade Any -> ETH
              // Send back ether to sender
              (bool success,) = msg.sender.call.value(destAmount)("");
              require(success, "Transfer ether back to caller failed.");
          } else { // Trade Any -> Token
              // Send back token to sender
              // Some ERC20 Smart contract not return Bool, so we can't use require(dest.transfer(x, y)) here
              destTokens[destTokens.length - 1].transfer(msg.sender, destAmount);
          }

          // Collect fee
          remainingAmount = collectFee(partnerIndex, destAmount, destTokens[destTokens.length - 1]);
        }

        emit Trade(address(srcTokens[0]), srcAmount, address(destTokens[destTokens.length - 1]), remainingAmount, msg.sender, 0);
        return remainingAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade with split volumes to multiple-routes ex. UNI -> ETH (5%, 15% and 80%)
    * @param routes Trading paths
    * @param src Source token
    * @param srcAmounts amount of source tokens
    * @param dest Destination token
    * @param minDestAmount minimun destination amount
    * @param partnerIndex index of partnership for revenue sharing
    * @return amount of actual destination tokens
    */
    function splitTrades(
        uint256[] calldata routes,
        ERC20     src,
        uint256[] calldata srcAmounts,
        ERC20     dest,
        uint256   minDestAmount,
        uint256   partnerIndex
    )
        external
        payable
        nonReentrant
        returns(uint256)
    {
        require(routes.length > 0, "routes can not be empty");
        require(routes.length == srcAmounts.length, "routes and srcAmounts lengths mismatch");
        uint256 srcAmount = srcAmounts[0];
        uint256 destAmount = 0;
        // Prepare source's asset
        if (etherERC20 != src) {
            src.transferFrom(msg.sender, address(this), srcAmount); // Transfer token to this address
        }
        // Trade with proxies
        for (uint i = 0; i < routes.length; i++) {
            uint256 tradingProxyIndex = routes[i];
            uint256 amount = srcAmounts[i];
            destAmount = destAmount.add(_trade(tradingProxyIndex, src, amount, dest));
        }
        // Throw exception if destination amount doesn't meet user requirement.
        require(destAmount >= minDestAmount, "destination amount is too low.");
        if (etherERC20 == dest) {
            (bool success, ) = msg.sender.call.value(destAmount)(""); // Send back ether to sender
            require(success, "Transfer ether back to caller failed.");
        } else { // Send back token to sender
            // Some ERC20 Smart contract not return Bool, so we can't use require(dest.transfer(x, y)); here
            dest.transfer(msg.sender, destAmount);
        }

        // Collect fee
        uint256 remainingAmount = collectFee(partnerIndex, destAmount, dest);

        emit Trade(address(src), srcAmount, address(dest), remainingAmount, msg.sender, 0);
        return remainingAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev get amount of destination token for given source token amount
    * @param tradingProxyIndex index of trading proxy
    * @param src Source token
    * @param dest Destination token
    * @param srcAmount amount of source tokens
    * @return amount of actual destination tokens
    */
    function getDestinationReturnAmount(
        uint256 tradingProxyIndex,
        ERC20   src,
        ERC20   dest,
        uint256 srcAmount,
        uint256 partnerIndex
    )
        external
        view
        returns(uint256)
    {
        // Load trading proxy
        IKULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex].proxy;
        uint256 destAmount = tradingProxy.getDestinationReturnAmount(src, dest, srcAmount);
        return amountWithFee(destAmount, partnerIndex);
    }

    function getDestinationReturnAmountForSplitTrades(
        uint256[] calldata routes,
        ERC20     src,
        uint256[] calldata srcAmounts,
        ERC20     dest,
        uint256   partnerIndex
    )
        external
        view
        returns(uint256)
    {
        require(routes.length > 0, "routes can not be empty");
        require(routes.length == srcAmounts.length, "routes and srcAmounts lengths mismatch");
        uint256 destAmount = 0;
        
        for (uint i = 0; i < routes.length; i++) {
            uint256 tradingProxyIndex = routes[i];
            uint256 amount = srcAmounts[i];
            // Load trading proxy
            IKULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex].proxy;
            destAmount = destAmount.add(tradingProxy.getDestinationReturnAmount(src, dest, amount));
        }
        return amountWithFee(destAmount, partnerIndex);
    }

    function getDestinationReturnAmountForTradeRoutes(
        ERC20     src,
        uint256   srcAmount,
        ERC20     dest,
        address[] calldata _tradingPaths,
        uint256   partnerIndex
    )
        external
        view
        returns(uint256)
    {
        src;
        dest;
        uint256 destAmount;
        uint256 pathSrcAmount = srcAmount;
        for (uint i = 0; i < _tradingPaths.length; i += 3) {
            uint256 tradingProxyIndex = uint256(_tradingPaths[i]);
            ERC20 pathSrc = ERC20(_tradingPaths[i+1]);
            ERC20 pathDest = ERC20(_tradingPaths[i+2]);

            // Load trading proxy
            IKULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex].proxy;
            destAmount = tradingProxy.getDestinationReturnAmount(pathSrc, pathDest, pathSrcAmount);
            pathSrcAmount = destAmount;
        }
        return amountWithFee(destAmount, partnerIndex);
    }

    // In case of expected and unexpected event that have some token amounts remain in this contract, owner can call to collect them.
    function collectRemainingToken(
        ERC20 token,
        uint256 amount
    )
      public
      onlyOwner
    {
        token.transfer(msg.sender, amount);
    }

    // In case of expected and unexpected event that have some ether amounts remain in this contract, owner can call to collect them.
    function collectRemainingEther(
        uint256 amount
    )
      public
      onlyOwner
    {
        (bool success, ) = msg.sender.call.value(amount)(""); // Send back ether to sender
        require(success, "Transfer ether back to caller failed.");
    }
}