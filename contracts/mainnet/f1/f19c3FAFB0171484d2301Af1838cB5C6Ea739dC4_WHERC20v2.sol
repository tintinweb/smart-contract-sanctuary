// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20{
    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;


import "./Interfaces/IWETH.sol";
import "./Interfaces/IToken.sol";
import "./Interfaces/IWHAsset.sol";
import "./Interfaces/IWhiteUSDCPool.sol";
import "./Interfaces/IWhiteOptionsPricer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IKeep3r {
    function getRequestedPayment() external view returns (uint);
}

/**
 * @author jmonteer
 * @title Whiteheart's Hedge Contract
 * @notice WHAsset implementation. Hedge contract: Wraps an amount of the underlying asset with an ATM put option (or other protection instrument)
 */
abstract contract WHAssetv2 is ERC721, IWHAssetv2, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint;
    using SafeMath for uint48;

    uint256 internal constant PRICE_DECIMALS = 1e8;
    uint256 public optionCollateralizationRatio = 100;
    address[] public underlyingToStableSwapPath;

    Counters.Counter private _tokenIds;
    IWhiteUSDCPool public immutable pool;
    IWhiteOptionsPricer public whiteOptionsPricer;
    IUniswapV2Router02 public swapRouter;
    AggregatorV3Interface public immutable priceProvider;

    address public keep3r;

    uint internal immutable DECIMALS;
    IERC20 public immutable stablecoin;

    mapping(address => bool) public routers;
    mapping(uint => Underlying) public underlying;
    mapping(address => bool) public autoUnwrapDisabled;

    constructor(
            IUniswapV2Router02 _swapRouter,
            IToken _stablecoin,
            IToken _token,
            AggregatorV3Interface _priceProvider,
            IWhiteUSDCPool _pool,
            IWhiteOptionsPricer _whiteOptionsPricer,
            string memory _name,
            string memory _symbol) public ERC721(_name, _symbol)
    {
        uint _DECIMALS = 10 ** (uint(IToken(_token).decimals()).sub(uint(IToken(_stablecoin).decimals()))) * PRICE_DECIMALS;
        DECIMALS = _DECIMALS;

        address[] memory _underlyingToStableSwapPath = new address[](2);
        _underlyingToStableSwapPath[0] = address(_token);
        _underlyingToStableSwapPath[1] = address(_stablecoin);

        underlyingToStableSwapPath = _underlyingToStableSwapPath;

        setSwapRouter(_swapRouter);
        whiteOptionsPricer = _whiteOptionsPricer;
        priceProvider = _priceProvider;
        stablecoin = _stablecoin;
        pool = _pool;
    }

    modifier onlyTokenOwner(uint tokenId) {
        require(underlying[tokenId].owner == msg.sender, "msg.sender != owner");
        _;
    }

    modifier onlyRouter {
        require(routers[msg.sender], "!not allowed");
        _;
    }


    function setSwapRouter(IUniswapV2Router02 newRouter) public onlyOwner {
      swapRouter = newRouter;
      setRouter(address(newRouter), true);
    }

    /**
     * @notice Sets swap router to swap underlying into USDC to pay for the protection
     * @param _router address of router contract
     * @param allowed bool telling if this address is an authorised router
     */
    function setRouter(address _router, bool allowed) public onlyOwner {
        routers[_router] = allowed;
    }

    /**
     * @notice Sets the Keep3r contract address. Keep3r is in charge of auto unwrapping a HedgeContract when it is in owner's best interest
     * @param newKeep3r address of Keep3r contract
     */
    function setKeep3r(address newKeep3r) external onlyOwner {
        keep3r = newKeep3r;
    }

    /**
     * @notice Returns cost of certain protection
     * @param amount amount to be protected
     * @param period duration of quoted protection
     * @return cost of protection
     */
    function wrapCost(uint amount, uint period) view external returns (uint cost){
        uint strike = _currentPrice();
        return whiteOptionsPricer.getOptionPrice(period, amount, strike);
    }

    /**
     * @notice Wraps an amount of principal into a HedgeContract
     * @param amount amount to be protected (principal)
     * @param period duration of protection
     * @param to recipient of WHAsset (onBehalfOf)
     * @param _mintToken boolean telling the function to mint a new ERC721 token representing this Hedge Contract or not
     * @param minPremiumUSDC param to protect against DEX slippage and front-running txs
     * @return newTokenId ID of new HedgeContract and its token if minted
     */
    function wrap(uint128 amount, uint period, address to, bool _mintToken, uint minPremiumUSDC) payable public override virtual returns (uint newTokenId) {
        newTokenId = _wrap(uint(amount), period, to, true, _mintToken, minPremiumUSDC);
    }

    /**
     * @notice Mints a token of an existing hedge contract
     * @param tokenId hedge contract id to mint a token for
     */
    function mintToken(uint tokenId) external {
        require(underlying[tokenId].active && underlying[tokenId].owner == msg.sender, "!not-tokenizable");
        _mint(msg.sender, tokenId);
    }

    /**
     * @notice Unwraps an active or inactive Hedge Contract, receiving back the principal amount
     * @param tokenId hedge contract id to be unwrapped
     */
    function unwrap(uint tokenId) external override onlyTokenOwner(tokenId) {
        _unwrap(tokenId);
    }

    /**
     * @notice Returns a list of autounwrappable hedge contracts. To be called off-chain
     * @return list of autounwrappable hedge contracts
     */
    function listAutoUnwrapable() external view returns (uint[] memory list) {
        uint counter = 0;
        for(uint i = 0; i <= _tokenIds.current() ; i++) {
            if(isAutoUnwrapable(i)) counter++;
        }
        list = new uint[](counter);
        uint index = 0;
        for(uint i = 0; i <= _tokenIds.current() ; i++) {
            if(isAutoUnwrapable(i)){
                list[index] = i;
                index++;
            }
            if(index>=counter) return list;
        }
    }

    /**
     * @notice Unwraps a list of autoUnwrappable hedge contracts in exchange for a fee (if called by Keep3r)
     * @param list list of hedge contracts to be unwrapped
     * @param rewardRecipient address of the recipient of the fees in exchange of autoExercise
     * @return reward that keep3r will receive
     */
    function autoUnwrapAll(uint[] calldata list, address rewardRecipient) external override returns (uint reward) {
        for(uint i = 0; i < list.length; i++){
            if(isAutoUnwrapable(list[i])) {
                _unwrap(list[i]);
            }
        }

        if(address(msg.sender).isContract() && msg.sender == keep3r) reward = pool.payKeep3r(rewardRecipient);
    }

    /**
     * @notice Unwraps a autoUnwrappable hedge contracts in exchange for a fee (if called by Keep3r)
     * @param tokenId HedgeContract to be unwrapped
     * @param rewardRecipient address of the recipient of the fees in exchange of autoExercise
     * @return reward that keep3r will receive
     */
    function autoUnwrap(uint tokenId, address rewardRecipient) public override returns (uint reward) {
        require(isAutoUnwrapable(tokenId), "!not-unwrapable");
        _unwrap(tokenId);

        if(address(msg.sender).isContract() && msg.sender == keep3r) reward = pool.payKeep3r(rewardRecipient);
    }

    /**
     * @notice Disables (or enables) autounwrapping for caller. If set to true, keep3rs wont be able to unwrap this user's WHAssets
     * @param disabled true to disable autounwrapping, false to re-enable autounwrapping
     */
    function setAutoUnwrapDisabled(bool disabled) external {
        autoUnwrapDisabled[msg.sender] = disabled;
    }

    /**
     * @notice Answers the question: is this hedge contract Auto unwrappable?
     * @param tokenId HedgeContract to be unwrapped
     * @return answer to the question: is this hedge contract Auto unwrappable
     */
    function isAutoUnwrapable(uint tokenId) public view returns (bool) {
        Underlying memory _underlying = underlying[tokenId];
        if(autoUnwrapDisabled[_underlying.owner]) return false;
        if(!_underlying.active) return false;

        bool ITM = false;
        uint currentPrice = _currentPrice();

        ITM = currentPrice < _underlying.strike;

        // if option is In The Money and the option is going to expire in the next minutes
        if (ITM && ((_underlying.expiration.sub(30 minutes) <= block.timestamp) && (_underlying.expiration >= block.timestamp))) {
            return true;
        }

        return false;
    }

    /**
     * @notice Internal function that wraps a hedge contract
     * @param amount amount
     * @param period period
     * @param to address that will receive the hedgecontract
     * @param receiveAsset whether or not require asset from sender
     * @param _mintToken whether or not to mint a token representing the hedge contract
     * @return newTokenId new token id
     */
    function _wrap(uint amount, uint period, address to, bool receiveAsset, bool _mintToken, uint minPremiumUSDC) internal returns (uint newTokenId){
        // new tokenId
        _tokenIds.increment();
        newTokenId = _tokenIds.current();

        // get cost of option
        uint strike = _currentPrice();

        uint total = whiteOptionsPricer.getOptionPrice(period, amount, strike);

        // receive asset + cost of hedge
        if(receiveAsset) _receiveAsset(msg.sender, amount, total);
        // buy option
        _createHedge(newTokenId, total, period, amount, strike, to, minPremiumUSDC);

        // mint ERC721 token
        if(_mintToken) _mint(to, newTokenId);

        emit Wrap(to, uint32(newTokenId), uint88(total), uint88(amount), uint48(strike), uint32(block.timestamp+period));
    }

    /**
     * @notice Internal function that creates the option protecting it
     * @param tokenId hedge contract id
     * @param totalFee total fee to be paid for the option
     * @param period seconds of duration of protection
     * @param amount amount to be protected
     * @param strike price at which the asset is protected
     * @param owner address of the owner of the hedge contract
     */
    function _createHedge(uint tokenId, uint totalFee, uint period, uint amount, uint strike, address owner, uint minPremiumUSDC) internal {
        uint collateral = amount.mul(strike).mul(optionCollateralizationRatio).div(100).div(DECIMALS);

        underlying[tokenId] = Underlying(
            bool(true),
            address(owner),
            uint88(amount),
            uint48(block.timestamp + period),
            uint48(strike)
        );

        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            totalFee,
            minPremiumUSDC,
            underlyingToStableSwapPath,
            address(pool),
            block.timestamp
        );
        uint totalStablecoin = amounts[amounts.length - 1];

        pool.lock(tokenId, collateral, totalStablecoin);
    }

    /**
     * @notice Exercises an option. only callable when unwrapping a hedge contract
     * @param tokenId id of hedge contract
     * @param owner owner of contract
     * @return optionProfit profit of exercised option
     * @return amount principal amount that was protected by it
     */
    function _exercise(uint tokenId, address owner) internal returns (uint optionProfit, uint amount, uint underlyingCurrentPrice) {
        Underlying storage _underlying = underlying[tokenId];
        amount = _underlying.amount;
        underlyingCurrentPrice = _currentPrice();

        if(_underlying.expiration < block.timestamp){
            pool.unlock(tokenId);
            optionProfit = 0;
        } else {
            (optionProfit) = _payProfit(owner, tokenId, _underlying.strike, _underlying.amount, underlyingCurrentPrice);
        }
    }

    /**
     * @notice Pays profit (if any) of underlying option
     * @param owner address of owner
     * @param tokenId tokenId
     * @param strike price at which the asset was protected
     * @param amount principal amount that was protected
     * @return profit profit of exercised option
     */
    function _payProfit(address owner, uint tokenId, uint strike, uint amount, uint underlyingCurrentPrice)
        internal
        returns (uint profit)
    {
        if(strike <= underlyingCurrentPrice){
            profit = 0;
        } else {
            profit = strike.sub(underlyingCurrentPrice).mul(amount).div(DECIMALS);
        }

        address _keep3r = address(msg.sender).isContract() ? keep3r : address(0);
        uint payKeep3r = _keep3r != address(0) ? IKeep3r(_keep3r).getRequestedPayment() : 0;

        require(payKeep3r <= profit, "!keep3r-requested-too-much");

        pool.send(tokenId, payable(owner), profit, payKeep3r);
    }

    /**
     * @notice Unwraps hedge contract
     * @param tokenId tokenId
     * @return owner address of hedge contract address
     * @return optionProfit profit of exercised option
     */
    function _unwrap(uint tokenId) internal returns (address owner, uint optionProfit) {
        Underlying storage _underlying = underlying[tokenId];
        owner = _underlying.owner;

        require(owner != address(0), "!tokenId-does-not-exist");
        require(_underlying.active, "!tokenId-does-not-exist");

        // exercise option
        (uint profit, uint amount, uint underlyingCurrentPrice) = _exercise(tokenId, owner);

        // burn token
        if(_exists(tokenId)) _burn(tokenId);
        _underlying.active = false;

        _sendTotal(payable(owner), amount);
        optionProfit = profit;

        emit Unwrap(owner, uint32(tokenId), uint128(underlyingCurrentPrice), uint128(profit));
    }

    /**
     * @notice changes hedge contract owner using HedgeContract underlying
     * @param from sender
     * @param to recipient
     * @param tokenId tokenId
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if(from != address(0) && to != address(0)){
            require(underlying[tokenId].owner == from, "!sth-went-wrong");
            underlying[tokenId].owner = to;
        }
    }

    function _receiveAsset(address from, uint amount, uint hedgeCost) internal virtual;

    function _sendTotal(address payable from, uint amount) internal virtual;

    function _currentPrice() internal view returns (uint) {
        (
            ,
            int price,
            ,
            ,

        ) = priceProvider.latestRoundData();

        return uint(price);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() payable external;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWHAssetv2 {
    event Wrap(address indexed account, uint32 indexed tokenId, uint88 cost, uint88 amount, uint48 strike, uint32 expiration);
    event Unwrap(address indexed account, uint32 indexed tokenId, uint128 closePrice, uint128 optionProfit);

    struct Underlying {
        bool active;
        address owner;
        uint88 amount;
        uint48 expiration;
        uint48 strike;
    }

    function wrap(uint128 amount, uint period, address to, bool mintToken, uint minUSDCPremium) payable external returns (uint newTokenId);
    function unwrap(uint tokenId) external;
    function autoUnwrap(uint tokenId, address rewardRecipient) external returns (uint);
    function autoUnwrapAll(uint[] calldata tokenIds, address rewardRecipient) external returns (uint);
    function wrapAfterSwap(uint total, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) external returns (uint newTokenId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface ILiquidityPool {
    struct LockedLiquidity { uint120 amount; uint120 premium; bool locked; }

    event Profit(uint indexed id, uint amount);
    event Loss(uint indexed id, uint amount);
    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event Withdraw(address indexed account, uint256 amount, uint256 writeAmount);

    function unlock(uint256 id) external;
    function setLockupPeriod(uint value) external;
    function deleteLockedLiquidity(uint id) external;
    function totalBalance() external view returns (uint256 amount);
    function setAllowedWHAsset(address _whAsset, bool approved) external;
    function send(uint256 id, address payable account, uint256 amount, uint payKeep3r) external;
}


interface IWhiteUSDCPool is ILiquidityPool {
    function lock(uint id, uint256 amountToLock, uint256 premium) external;
    function token() external view returns (IERC20);
    function payKeep3r(address keep3r) external returns (uint amount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IWhiteOptionsPricer {
    function getOptionPrice(
        uint256 period,
        uint256 amount,
        uint256 strike
    )
        external
        view
        returns (uint256 total);

    function getAmountToWrapFromTotal(uint total, uint period) external view returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

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

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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
     * Requirements:
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
     * Requirements:
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../WHAssetv2.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @author jmonteer
 * @title Whiteheart's Hedge Contract (WHETH)
 * @notice WHAsset implementation. Hedge contract: Wraps an amount of the underlying asset with an ATM put option (or other protection instrument)
 */
contract WHETHv2 is WHAssetv2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public WETH;

    constructor(
            IUniswapV2Router02 _swapRouter,
            IToken _stablecoin,
            AggregatorV3Interface _priceProvider,
            IWhiteUSDCPool _pool,
            IWhiteOptionsPricer _whiteOptionsPricer
    ) public WHAssetv2(_swapRouter, _stablecoin, IToken(_swapRouter.WETH()), _priceProvider, _pool, _whiteOptionsPricer, "Whiteheart Hedged ETH", "WHETH") {
      connectRouter(_swapRouter);
      IERC20(_stablecoin).safeApprove(address(_pool), type(uint256).max);
    }

    receive() payable external {}

    function connectRouter(IUniswapV2Router02 _swapRouter) public onlyOwner {
      WETH = _swapRouter.WETH();
      IERC20(WETH).safeApprove(address(_swapRouter), type(uint256).max);
    }

    /**
     * @notice function to be called by the router after a swap has been completed
     * @param total principal + hedge cost added amount
     * @param protectionPeriod seconds of protection
     * @param to recipient of Hedge Contract (onBehalfOf)
     * @param mintToken whether to mintToken or not
     * @return newTokenId new hedge contract id
     */
    function wrapAfterSwap(uint total, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) external onlyRouter override returns (uint newTokenId) {
        uint amountToWrap = whiteOptionsPricer.getAmountToWrapFromTotal(total, protectionPeriod);
        newTokenId = _wrap(amountToWrap, protectionPeriod, to, false, mintToken, minUSDCPremium);
    }

    /**
     * @notice internal function that supports the receival of principal+hedge cost to be sent
     * @param from address sender
     * @param amount principal to receive
     * @param toUsdc hedgeCost
     */
    function _receiveAsset(address from, uint amount, uint toUsdc) internal override {
        uint received = msg.value;
        require(received >= amount.add(toUsdc), "!wrong value");
        if(received > amount.add(toUsdc)) payable(from).transfer(received.sub(amount.add(toUsdc)));
        IWETH(WETH).deposit{value:amount.add(toUsdc)}();
    }

    /**
     * @notice internal function of support that sends the principal that was protected
     * @param to receiver of principal
     * @param amount principal that has been protected
     */
    function _sendTotal(address payable to, uint amount) internal override {
        IWETH(WETH).withdraw(amount);
        to.transfer(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../WHAssetv2.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @author jmonteer
 * @title Whiteheart's Hedge Contract (Any ERC20)
 * @notice WHAsset implementation. Hedge contract: Wraps an amount of the underlying asset with an ATM put option (or other protection instrument)
 */
contract WHERC20v2 is WHAssetv2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 public immutable token;

    constructor(
            IUniswapV2Router02 _swapRouter,
            IToken _stablecoin,
            IToken _token,
            AggregatorV3Interface _priceProvider,
            IWhiteUSDCPool _pool,
            IWhiteOptionsPricer _whiteOptionsPricer,
            string memory _name,
            string memory _symbol
    ) public WHAssetv2(_swapRouter, _stablecoin, _token, _priceProvider, _pool, _whiteOptionsPricer, _name, _symbol) {
        token = _token;

        IERC20(_stablecoin).safeApprove(address(_pool), type(uint256).max);
        IERC20(_token).safeApprove(address(_swapRouter), type(uint256).max);
    }

    function wrap(uint128 amount, uint period, address to, bool _mintToken, uint minPremiumUSDC) payable public override returns (uint newTokenId) {
        require(msg.value == 0, "!eth not accepted");
        newTokenId = super.wrap(amount, period, to, _mintToken, minPremiumUSDC);
    }

    /**
     * @notice function to be called by the router after a swap has been completed
     * @param total principal + hedge cost added amount
     * @param protectionPeriod seconds of protection
     * @param to recipient of Hedge Contract (onBehalfOf)
     * @param mintToken whether to mintToken or not
     * @return newTokenId new hedge contract id
     */
    function wrapAfterSwap(uint total, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) external onlyRouter override returns (uint newTokenId) {
        uint amountToWrap = whiteOptionsPricer.getAmountToWrapFromTotal(total, protectionPeriod);
        newTokenId = _wrap(amountToWrap, protectionPeriod, to, false, mintToken, minUSDCPremium);
    }

    /**
     * @notice internal function that supports the receival of principal+hedge cost to be sent
     * @param from address sender
     * @param amount principal to receive
     * @param toUsdc hedgeCost
     */
    function _receiveAsset(address from, uint amount, uint toUsdc) internal override {
        token.safeTransferFrom(from, address(this), amount.add(toUsdc));
    }

    /**
     * @notice internal function of support that sends the principal that was protected
     * @param to receiver of principal
     * @param amount principal that has been protected
     */
    function _sendTotal(address payable to, uint amount) internal override {
        token.safeTransfer(to, amount);
    }
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2020 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import "../Interfaces/IWhiteStakingERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity 0.6.12;


abstract
contract WhiteStaking is ERC20, IWhiteStaking {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 public immutable WHITE;
    uint internal constant ACCURACY = 1e30;
    address payable public immutable FALLBACK_RECIPIENT;

    uint public totalProfit = 0;
    mapping(address => uint) internal lastProfit;
    mapping(address => uint) internal savedProfit;

    uint256 public lockupPeriod = 1 days;
    mapping(address => uint256) public lastStakeTimestamp;
    mapping(address => bool) public _revertTransfersInLockUpPeriod;

    constructor(ERC20 _token, string memory name, string memory short)
        public ERC20(name, short)
    {
        WHITE = _token;
        FALLBACK_RECIPIENT = msg.sender;
    }

    function claimProfit() external override returns (uint profit) {
        profit = saveProfit(msg.sender);
        require(profit > 0, "Zero profit");
        savedProfit[msg.sender] = 0;
        _transferProfit(profit);
        emit Claim(msg.sender, profit);
    }

    function deposit(uint amount) external override {
       lastStakeTimestamp[msg.sender] = block.timestamp;
        require(amount > 0, "!amount");
        WHITE.safeTransferFrom(msg.sender, address(this), amount);

        _mint(msg.sender, amount); 
    }

    function withdraw(uint amount) external lockupFree override {
        _burn(msg.sender, amount);

        WHITE.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Used for ...
     */
    function revertTransfersInLockUpPeriod(bool value) external {
        _revertTransfersInLockUpPeriod[msg.sender] = value;
    }

    function profitOf(address account) external view override returns (uint) {
        return savedProfit[account].add(getUnsaved(account));
    }

    function getUnsaved(address account) internal view returns (uint profit) {
        return totalProfit.sub(lastProfit[account]).mul(balanceOf(account)).div(ACCURACY);
    }

    function saveProfit(address account) internal returns (uint profit) {
        uint unsaved = getUnsaved(account);
        lastProfit[account] = totalProfit;
        profit = savedProfit[account].add(unsaved);
        savedProfit[account] = profit;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (from != address(0)) saveProfit(from);
        if (to != address(0)) saveProfit(to);
        if (
            lastStakeTimestamp[from].add(lockupPeriod) > block.timestamp &&
            lastStakeTimestamp[from] > lastStakeTimestamp[to]
        ) {
            require(
                !_revertTransfersInLockUpPeriod[to],
                "the recipient does not accept blocked funds"
            );
            lastStakeTimestamp[to] = lastStakeTimestamp[from];
        }
    }

    function _transferProfit(uint amount) internal virtual;

    modifier lockupFree {
        require(
            lastStakeTimestamp[msg.sender].add(lockupPeriod) <= block.timestamp,
            "Action suspended due to lockup"
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWhiteStaking {    
    event Claim(address indexed acount, uint amount);
    event Profit(uint amount);

    function claimProfit() external returns (uint profit);
    function deposit(uint amount) external;
    function withdraw(uint amount) external;
    function profitOf(address account) external view returns (uint);
}

interface IWhiteStakingERC20 {
    function sendProfit(uint amount) external;
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2020 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import "./WhiteStaking.sol";
pragma solidity 0.6.12;

contract WhiteStakingUSDC is WhiteStaking, IWhiteStakingERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 public immutable USDC;

    constructor(ERC20 _token, ERC20 usdc) public 
        WhiteStaking(_token, "Staked WHITE", "sWHITE") {
        USDC = usdc;
    }

    function sendProfit(uint amount) external override {
        uint _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            totalProfit += amount.mul(ACCURACY) / _totalSupply;
            USDC.safeTransferFrom(msg.sender, address(this), amount);
            emit Profit(amount);
        } else {
            USDC.safeTransferFrom(msg.sender, FALLBACK_RECIPIENT, amount);
        }
    }

    function _transferProfit(uint amount) internal override {
        USDC.safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract FakeWBTC is ERC20("FakeWBTC", "FAKE") {
    constructor() public {
        _setupDecimals(8);
    }

    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

contract FakeWHITE is ERC20("FakeWHITE", "FAKEWHITE") {

    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

contract FakeWETH is ERC20("FakeWETH", "FAKETH") {
    receive() external payable {}
    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint wad) external {
        payable(msg.sender).transfer(wad);
        _burn(msg.sender, wad);
    }
}

contract FakeUSDC is ERC20("FakeUSDC", "FAKEU") {
    using SafeERC20 for ERC20;
    constructor() public {
        _setupDecimals(6);
    }
    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Interfaces/Keep3r/ICollectableDust.sol";

abstract contract CollectableDust is ICollectableDust {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    EnumerableSet.AddressSet internal protocolTokens;

    constructor() public {}

    function _addProtocolToken(address _token) internal {
        require(!protocolTokens.contains(_token), "collectable-dust::token-is-part-of-the-protocol");
        protocolTokens.add(_token);
    }

    function _removeProtocolToken(address _token) internal {
        require(protocolTokens.contains(_token), "collectable-dust::token-not-part-of-the-protocol");
        protocolTokens.remove(_token);
    }

    function _sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        require(_to != address(0), "collectable-dust::cant-send-dust-to-zero-address");
        require(!protocolTokens.contains(_token), "collectable-dust::token-is-part-of-the-protocol");
        if (_token == ETH_ADDRESS) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
        emit DustSent(_to, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ICollectableDust {
    event DustSent(address _to, address token, uint256 amount);

    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Governable.sol";
import "./CollectableDust.sol";
import "../Interfaces/IWHAsset.sol";
import "../Interfaces/Keep3r/IKeep3rV1.sol";
import "../Interfaces/Keep3r/IChainLinkFeed.sol";
import "../Interfaces/Keep3r/IKeep3rV1Helper.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract WhiteKeep3r is Governable, CollectableDust {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IKeep3rV1 public keep3r = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    IChainLinkFeed public immutable ETHUSD = IChainLinkFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    
    uint public constant gasUsed = 100_000;
    address public job;

    IERC20 public immutable token; 

    constructor(IERC20 _token) public Governable(msg.sender) CollectableDust() {
        token = _token;
    }

    function unwrapAll(address whAsset, uint[] calldata tokenIds) external paysKeeper(tokenIds) {
        IWHAssetv2(whAsset).autoUnwrapAll(tokenIds, address(this));
    }

    function refillCredit() external onlyGovernor {
        uint balance = token.balanceOf(address(this));
        keep3r.addCredit(address(token), job, balance);
    }

    function _isKeeper() internal {
        require(tx.origin == msg.sender, "keep3r::isKeeper:keeper-is-a-smart-contract");
        require(keep3r.isKeeper(msg.sender), "keep3r::isKeeper:keeper-is-not-registered");
    }

    function getRequestedPayment() public view returns(uint){
        uint256 gasPrice = Math.min(tx.gasprice, uint256(FASTGAS.latestAnswer()));

        return gasPrice.mul(gasUsed).mul(uint(ETHUSD.latestAnswer())).div(1e20);
    }

    function getRequestedPaymentETH() public view returns(uint){
        uint256 gasPrice = Math.min(tx.gasprice, uint256(FASTGAS.latestAnswer()));

        return gasPrice.mul(gasUsed);
    }

    function setJob(address newJob) external onlyGovernor {
        job = newJob;
    }

    modifier paysKeeper(uint[] calldata tokenIds) {
        _isKeeper();
        
        _; // function executed by keep3r

        uint paidReward = tokenIds.length.mul(getRequestedPayment());

        keep3r.receipt(address(token), msg.sender, paidReward);
    }

    function setKeep3r(address _keep3r) external onlyGovernor {
        token.safeApprove(address(keep3r), 0);
        keep3r = IKeep3rV1(_keep3r);
        token.safeApprove(address(_keep3r), type(uint256).max);
    }

    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../Interfaces/Keep3r/IGovernable.sol";

abstract contract Governable is IGovernable {
    address public governor;
    address public pendingGovernor;

    constructor(address _governor) public {
        require(_governor != address(0), "governable::governor-should-not-be-zero-address");
        governor = _governor;
    }

    function _setPendingGovernor(address _pendingGovernor) internal {
        require(_pendingGovernor != address(0), "governable::pending-governor-should-not-be-zero-address");
        pendingGovernor = _pendingGovernor;
        emit PendingGovernorSet(_pendingGovernor);
    }

    function _acceptGovernor() internal {
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit GovernorAccepted();
    }

    modifier onlyGovernor {
        require(msg.sender == governor, "governable::only-governor");
        _;
    }

    modifier onlyPendingGovernor {
        require(msg.sender == pendingGovernor, "governable::only-pending-governor");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IKeep3rV1 {
    function KPRH() external returns (address);

    function name() external returns (string memory);

    function isKeeper(address) external returns (bool);

    function worked(address keeper) external;

    function workReceipt(address keeper, uint amount) external;

    function receiptETH(address keeper, uint256 amount) external;

    function receipt(address credit, address keeper, uint256 amount) external;

    function addKPRCredit(address job, uint256 amount) external;

    function addCredit(address asset, address job, uint256 amount) external;

    function addJob(address job) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IChainLinkFeed {
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IKeep3rV1Helper {
    function quote(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IGovernable {
    event PendingGovernorSet(address pendingGovernor);
    event GovernorAccepted();

    function setPendingGovernor(address _pendingGovernor) external;

    function acceptGovernor() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces/IWETH.sol";
import "./Interfaces/IWHAsset.sol";
import "./Interfaces/IWHSwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@sushiswap/core/contracts/uniswapv2/libraries/TransferHelper.sol";
import "@sushiswap/core/contracts/uniswapv2/libraries/UniswapV2Library.sol";

/**
 * @author jmonteer
 * @title Whiteheart's Swap+Wrap router using Uniswap-like DEX
 * @notice Contract performing a swap and sending the output to the corresponding WHAsset contract for it to be wrapped into a Hedge Contract
 */
contract WHSwapRouter is IWHSwapRouter, Ownable {
    address public immutable factory; 
    address public immutable WETH;

    // Maps the underlying asset to the corresponding Hedge Contracts
    mapping(address => address) public whAssets;
    
    /**
     * @notice Constructor
     * @param _factory DEX factory contract 
     * @param _WETH Ether ERC20's token address
     */
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    /**
     * @notice Adds an entry to the underlyingAsset => WHAsset contract. It can be used to set the underlying asset to 0x0 address
     * @param token Asset address
     * @param whAsset WHAsset contract for the underlying asset
     */
    function setWHAsset(address token, address whAsset) external onlyOwner {
        whAssets[token] = whAsset;
    }

    /**
     * @notice Function used by WHAsset contracts to swap underlying assets into USDC, to buy options. Same function than "original" router's function
     * @param amountIn amount of the token being swap
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_output_amount');        

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    /**
     * @notice Custom function for swapExactTokensForTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountIn amount of the token being swap
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactTokensForTokensAndWrap(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to, 
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external virtual override ensure(deadline) returns (uint[] memory amounts, uint newTokenId){
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_output_amount');        
        
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }

        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapTokensForExactTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut exact amount of output asset expected
     * @param amountInMax maximum amount of tokens to be sent to the DEX
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapTokensForExactTokensAndWrap(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external virtual override ensure(deadline) returns (uint[] memory amounts, uint newTokenId) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'excessive_input_amount');
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapExactETHForTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactETHForTokensAndWrap(uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        virtual
        payable
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {           
        address[] memory _path = path; // to avoid stack too deep
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, _path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_input_amount');

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]));   
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Custom function for swapETHForExactTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut amount of the token being swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapETHForExactTokensAndWrap(uint amountOut,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    )
        external
        virtual
        payable
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {
        address[] memory _path = path; // to avoid stack too deep
        require(_path[0] == WETH, 'invalid_path');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, _path);
        require(amounts[0] <= msg.value, 'excessive_input_amount');

        IWETH(WETH).deposit{value: amounts[0]}();
        {
            assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]));
        }

        if(msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapExactTokensForETH that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountIn amount of the token being swapped
     * @param amountOutMin minimum amount of the output asset to be received
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactTokensForETHAndWrap(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        override
        ensure(deadline)
        returns(uint[] memory amounts, uint newTokenId) 
    {
        require(path[path.length - 1] == WETH, 'invalid_path');

        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "insufficient_output_amount");
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }        
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Custom function for swapTokensForExactETH that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut amount of the output asset to be received
     * @param amountInMax maximum amount of input that user is willing to send to the contract to reach amountOut 
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapTokensForExactETHAndWrap(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {
        require(path[path.length - 1] == WETH, 'invalid_path');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'excessive_input_amount');
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        } 
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Internal function to be called after all swap params have been calc'd. it performs a swap and sends output to corresponding WHAsset contract
     * @param path ordered list of assets to be swap from, to
     * @param amounts list of amounts to send/receive of each of path's asset
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
    */
    function _swapAndWrap(address[] calldata path, uint[] memory amounts, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) 
        internal
        returns (uint newTokenId)
    {
        address whAsset = whAssets[path[path.length - 1]];
        require(whAsset != address(0), 'whAsset_does_not_exist');
        _swap(amounts, path, whAsset);
        newTokenId = IWHAssetv2(whAsset).wrapAfterSwap(amounts[amounts.length - 1], protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Internal function to be called for actually swapping the involved assets. requires the initial amount to have already been sent to the first pair
     * @param amounts list of amounts to send/receive of each of path's asset
     * @param path ordered list of assets to be swap from, to
     * @param _to recipient of swap's output
      */
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for(uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, )  = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    // **** LIBRARY FUNCTIONS **** 
    // from original Uniswap router
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWHSwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokensAndWrap(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to, 
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external returns (uint[] memory amounts, uint newTokenId);

    function swapTokensForExactTokensAndWrap(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod, 
        bool mintToken,
        uint minUSDCPremium
    ) external returns (uint[] memory amounts, uint newTokenId);

    function swapExactETHForTokensAndWrap(uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        payable
        returns (uint[] memory amounts, uint newTokenId);

    function swapETHForExactTokensAndWrap(uint amountOut, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        payable
        returns (uint[] memory amounts, uint newTokenId);


    function swapExactTokensForETHAndWrap(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        returns(uint[] memory amounts, uint newTokenId);

    function swapTokensForExactETHAndWrap(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        returns (uint[] memory amounts, uint newTokenId);

// **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        pure
        returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        pure        
        returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view        
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
        returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'fa418eb2c6e15c39605695377d0e364aca1c3c56b333eefe9c0d4b707662f785' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './libraries/SafeMath.sol';

contract UniswapV2ERC20 {
    using SafeMathUniswap for uint;

    string public constant name = 'SushiSwap LP Token';
    string public constant symbol = 'SLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

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

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract UniswapV2Pair is UniswapV2ERC20 {
    using SafeMathUniswap  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
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
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20Uniswap(token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            address migrator = IUniswapV2Factory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != uint256(-1), "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20Uniswap(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20Uniswap(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20Uniswap(token0).balanceOf(address(this)), IERC20Uniswap(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
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
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@sushiswap/core/contracts/uniswapv2/UniswapV2Pair.sol";

contract SushiSwapPairMock is UniswapV2Pair {
    constructor() public UniswapV2Pair() {
        return;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/UniswapV2Factory.sol";

contract SushiSwapFactoryMock is UniswapV2Factory {
    constructor() public UniswapV2Factory(msg.sender) {
        return;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces/IWhiteUSDCPool.sol";
import "./Interfaces/IWhiteStakingERC20.sol";

/**
 * @author jmonteer & 0mllwntrmt3
 * @title Whiteheart Stablecoin Liquidity Pool
 * @notice Accumulates liquidity in USDC from LPs and distributes P&L in USDC
 */
contract WhiteUSDCPool is
    IWhiteUSDCPool,
    Ownable,
    ERC20("Whiteheart USDC LP Token", "writeUSDC")
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // token that is holded in the pool
    IERC20 public override immutable token;
    // address of fee recipient contract
    IWhiteStakingERC20 public immutable settlementFeeRecipient;
    address public hegicFeeRecipient;

    // storage variable to keep
    uint256 public owedToKeep3r = 0;
    // amount locked as collateral for open positions
    uint256 public lockedAmount;
    // amount of locked premiums
    uint256 public lockedPremium;
    // minimum amount of time to pass between last provide timestamp and withdrawal
    uint256 public lockupPeriod = 2 weeks;
    uint256 public hegicFee = 0;
    uint256 public constant INITIAL_RATE = 1e13;

    // WHAsset contracts allowed to open positions using this pool
    mapping(address => bool) public whAssets;
    // Last provided timestamp for this address
    mapping(address => uint256) public lastProvideTimestamp;
    // Locked Liquidity mapping per WHAsset (whAsset address => id => LockedLiquidity)
    mapping(address => mapping(uint => LockedLiquidity)) public lockedLiquidity;
    // Whether or not the tranfers of Locked funds are allowed
    mapping(address => bool) public _revertTransfersInLockUpPeriod;

    /**
     * @param _token USDC address
     * @param _settlementFeeRecipient Address of contract that will receive the fees
     */
    constructor(IERC20 _token, IWhiteStakingERC20 _settlementFeeRecipient) public {
        token = _token;
        settlementFeeRecipient = _settlementFeeRecipient;
        hegicFeeRecipient = msg.sender;
        IERC20(_token).safeApprove(address(_settlementFeeRecipient), type(uint256).max);
    }

    modifier onlyWHAssets {
        require(whAssets[msg.sender], "whiteheart::pool::not-allowed");
        _;
    }

    /**
     * @notice Used for changing the lockup period
     * @param value New period value
     */
    function setLockupPeriod(uint256 value) external override onlyOwner {
        require(value <= 60 days, "Lockup period is too large");
        lockupPeriod = value;
    }

    /**
     * @notice Used for changing the Hegic fee recipient
     * @param value New value
     */
    function setHegicFeeRecipient(address value) external onlyOwner {
        require(value != address(0));
        hegicFeeRecipient = value;
    }

    /**
     * @notice Used for withdrawing the Hegic fee
     */
    function withdrawHegicFee() external {
      token.safeTransfer(hegicFeeRecipient, hegicFee);
      hegicFee = 0;
    }

    /**
     * @notice Allows new smart contract to open positions using USDC pools
     * @param _whAsset whAsset address
     * @param approved set to true for approval, set to false for rejecting previously granted access
     */
    function setAllowedWHAsset(address _whAsset, bool approved) external override onlyOwner {
        whAssets[_whAsset] = approved;
    }

    /**
     * @notice Lets each user to decide whether or not they want to allow incoming transfers of locked funds
     * @param value bool option. true if the transfer should be reverted, false if it shouldnt
     */
    function revertTransfersInLockUpPeriod(bool value) external {
        _revertTransfersInLockUpPeriod[msg.sender] = value;
    }

    /**
     * @notice called by WHAsset contract to lock funds and premium (when opening a position)
     * @param id Id of the Hedge Contract that is being opened
     * @param amountToLock Amount of funds that should be locked in an option
     * @param totalFee premium paid for the protection. It will be locked until funds are unlocked
     */
    function lock(uint id, uint256 amountToLock, uint256 totalFee) external override onlyWHAssets {
        address creator = msg.sender;
        require(
            lockedAmount.add(amountToLock).mul(10) <= totalBalance().mul(8),
            "Pool Error: Amount is too large."
        );

        uint256 premium = totalFee.mul(30).div(100);
        uint256 settlementFee = totalFee.mul(30).div(100);
        uint256 hegicFeeAmount = totalFee.sub(premium).sub(settlementFee);

        lockedLiquidity[creator][id] = (LockedLiquidity(uint120(amountToLock), uint120(premium), true));
        lockedPremium = lockedPremium.add(premium);
        lockedAmount = lockedAmount.add(amountToLock);

        settlementFeeRecipient.sendProfit(settlementFee);
        hegicFee = hegicFee.add(hegicFeeAmount);
    }

    /**
     * @notice calls by WHAsset contract to unlock funds and premium (when closing a position, either exercising or unlocking funds)
     * @param id Id of the Hedge Contract that is being opened
     */
    function unlock(uint256 id) external override {
        LockedLiquidity storage ll = lockedLiquidity[msg.sender][id];
        require(ll.locked, "LockedLiquidity with such id has already unlocked");
        ll.locked = false;

        lockedPremium = lockedPremium.sub(ll.premium);
        lockedAmount = lockedAmount.sub(ll.amount);

        emit Profit(id, ll.premium);
    }

    /**
     * @notice Function that can only be called by WHAsset contracts to retrieve funds owed to a keep3r
     * @param keep3r address of the function to receive accumulated rewards
     */
    function payKeep3r(address keep3r) external onlyWHAssets override returns (uint amount) {
        amount = owedToKeep3r;
        owedToKeep3r = 0;
        if(amount > 0) token.safeTransfer(keep3r, amount);
    }

    /**
     * @notice function that pays profit (if any) to the hedge contract holder and unlocks premium and liquidity
     * @param id Id of the Hedge Contract that is being closed
     * @param to address to receive profit
     * @param amount profit to be sent
     * @param _payKeep3r amount to be saved for the keep3r unwrapping the asset
     */
    function send(uint id, address payable to, uint256 amount, uint _payKeep3r)
        external
        override
    {
        LockedLiquidity storage ll = lockedLiquidity[msg.sender][id];
        require(ll.locked, "LockedLiquidity with such id has already unlocked");
        require(to != address(0));

        ll.locked = false;
        lockedPremium = lockedPremium.sub(ll.premium);
        lockedAmount = lockedAmount.sub(ll.amount);

        uint transferAmount = amount > ll.amount ? ll.amount : amount;
        token.safeTransfer(to, transferAmount.sub(_payKeep3r));

        if(_payKeep3r > 0) owedToKeep3r = owedToKeep3r.add(_payKeep3r);

        if (transferAmount <= ll.premium)
            emit Profit(id, ll.premium - transferAmount);
        else
            emit Loss(id, transferAmount - ll.premium);
    }

    /**
     * @notice deletes locked liquidity, receiving a gas refund. used to reduce gas usage
     * @param id Id of the Hedge Contract that is being closed
     */
    function deleteLockedLiquidity(uint id) external override {
        delete lockedLiquidity[msg.sender][id];
    }

    /**
     * @notice A provider supplies USDC to the pool and receives writeUSDC tokens
     * @param amount Amount to send to the contract
     * @param minMint minimum amount of writeUSDC tokens to be minted
     * @return mint amount of writeUSDC minted to provider
     */
    function provide(uint256 amount, uint256 minMint) external returns (uint256 mint) {
        lastProvideTimestamp[msg.sender] = block.timestamp;
        uint supply = totalSupply();
        uint balance = totalBalance();
        if (supply > 0 && balance > 0)
            mint = amount.mul(supply).div(balance);
        else
            mint = amount.mul(INITIAL_RATE);

        require(mint >= minMint, "Pool: Mint limit is too large");
        require(mint > 0, "Pool: Amount is too small");
        _mint(msg.sender, mint);
        emit Provide(msg.sender, amount, mint);

        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice A provider supplies writeUSDC to the pool and receives USDC tokens
     * @param amount Amount to withdraw from the pool
     * @param maxBurn maximum amount of writeUSDC to be burned in exchange
     * @return burn amount of writeUSDC burnt from provider
     */
    function withdraw(uint256 amount, uint256 maxBurn) external returns (uint256 burn) {
        require(
            lastProvideTimestamp[msg.sender].add(lockupPeriod) <= block.timestamp,
            "Pool: Withdrawal is locked up"
        );
        require(
            amount <= availableBalance(),
            "Pool Error: You are trying to unlock more funds than have been locked for your contract. Please lower the amount."
        );

        burn = divCeil(amount.mul(totalSupply()), totalBalance());

        require(burn <= maxBurn, "Pool: Burn limit is too small");
        require(burn <= balanceOf(msg.sender), "Pool: Amount is too large");
        require(burn > 0, "Pool: Amount is too small");

        _burn(msg.sender, burn);
        emit Withdraw(msg.sender, amount, burn);
        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Returns provider's share in USDC
     * @param user Provider's address
     * @return share Provider's share in USDC
     */
    function shareOf(address user) external view returns (uint256 share) {
        uint supply = totalSupply();
        if (supply > 0)
            share = totalBalance().mul(balanceOf(user)).div(supply);
        else
            share = 0;
    }

    /**
     * @notice Returns the amount of USDC available for withdrawals
     * @return balance Unlocked amount
     */
    function availableBalance() public view returns (uint256 balance) {
        return totalBalance().sub(lockedAmount);
    }

    /**
     * @notice Returns the USDC total balance provided to the pool
     * @return balance Pool balance
     */
    function totalBalance() public override view returns (uint256 balance) {
        return token.balanceOf(address(this)).sub(lockedPremium).sub(hegicFee);
    }

    /**
     * @notice Internal function that checks if to be transferred tokens are locked and act accordingly
     * @param from sender
     * @param to recipient
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (
            lastProvideTimestamp[from].add(lockupPeriod) > block.timestamp &&
            lastProvideTimestamp[from] > lastProvideTimestamp[to]
        ) {
            require(
                !_revertTransfersInLockUpPeriod[to],
                "the recipient does not accept blocked funds"
            );
            lastProvideTimestamp[to] = lastProvideTimestamp[from];
        }
    }

    // support function that divides and chooses result's ceil
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        if (a % b != 0)
            c = c + 1;
        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0
import "./Interfaces/IWhiteOptionsPricer.sol";

pragma solidity 0.6.12;

/**
 * @author jmonteer & 0mllwntrmt3
 * @title Whiteheart Options Pricer: Separate module to price protection of WHAssets
 * @notice Support contract that provides prices for certain protection periods, strikes and amounts
 */
contract WhiteOptionsPricer is IWhiteOptionsPricer, Ownable {
    using SafeMath for uint;

    uint256 public impliedVolRate;
    uint256 internal constant PRICE_DECIMALS = 1e8;

    AggregatorV3Interface public underlyingPriceProvider;

    constructor(AggregatorV3Interface _priceProvider) public {
        underlyingPriceProvider = _priceProvider;
        impliedVolRate = 5500;
    }

    /**
     * @notice Used for adjusting the options prices while balancing asset's implied volatility rate
     * @param value New IVRate value
     */
    function setImpliedVolRate(uint256 value) external onlyOwner {
        require(value >= 1000, "ImpliedVolRate limit is too small");
        impliedVolRate = value;
    }

    /**
     * @notice Returns the price that opening a certain option should cost
     * @param period period of protection
     * @param amount amount of underlying asset to be protected
     * @return total totalfee
     */
    function getOptionPrice(
        uint256 period,
        uint256 amount,
        uint256
    )
        external
        override
        view
        returns (uint256 total)
    {
        require(period <= 4 weeks, "!period: too long");
        require(period >= 1 days, "!period: too short");

        return amount
            .mul(sqrt(period))
            .mul(impliedVolRate)
            .div(PRICE_DECIMALS);
    }


    /**
     * @notice Returns the amount of WHAsset that is going to be created when provided with the total
     * amount of underlying asset sent (some goes to protecting the asset, some to the principal being protected)
     * @param total principal + hedgecost
     * @param period period of protection
     * @return maximum amount to be wrapped
     */
    function getAmountToWrapFromTotal(uint total, uint period) external view override returns (uint){
        uint numerator = total.mul(PRICE_DECIMALS).mul(10000);
        uint denominator = PRICE_DECIMALS.add(sqrt(period).mul(impliedVolRate));
        return numerator.div(denominator).div(10000);
    }

    /**
     * @dev Counts square root of the number.
     * Throws "invalid opcode" at uint(-1)

     */
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        result = x;
        uint256 k = (x + 1) >> 1;
        while (k < result) (result, k) = (k, (x / k + k) >> 1);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract FakePriceProvider is AggregatorV3Interface {
    uint256 public price;
    uint8 public override decimals = 8;
    string public override description = "Test implementation";
    uint256 public override version = 0;

    constructor(uint256 _price) public {
        price = _price;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function getRoundData(uint80) external override view returns (uint80, int256, uint256, uint256, uint80) {
        revert("Test implementation");
    }

    function latestAnswer() external view returns(int result) {
        (, result, , , ) = latestRoundData();
    }

    function latestRoundData()
        public
        override
        view
        returns (
            uint80,
            int256 answer,
            uint256,
            uint256,
            uint80
        )
    {
        answer = int(price);
    }
}

