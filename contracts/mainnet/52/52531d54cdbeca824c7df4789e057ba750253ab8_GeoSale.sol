pragma solidity ^0.6.0;


// SPDX-License-Identifier: MIT
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

/**
 * This source code belongs to Augur
 */
/**
 * @title SafeMathInt256
 * @dev Int256 math operations with safety checks that throw on error
 */
library SafeMathInt256 {
    // Signed ints with n bits can range from -2**(n-1) to (2**(n-1) - 1)
    int256 private constant INT256_MIN = -2**(255);
    int256 private constant INT256_MAX = (2**(255) - 1);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // No need to check for dividing by 0 -- Solidity automatically throws on division by 0
        int256 c = a / b;
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require(((a >= 0) && (b >= a - INT256_MAX)) || ((a < 0) && (b <= a - INT256_MIN)));
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        require(((a >= 0) && (b <= INT256_MAX - a)) || ((a < 0) && (b >= INT256_MIN - a)));
        return a + b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function abs(int256 a) internal pure returns (int256) {
        if (a < 0) {
            return -a;
        }
        return a;
    }

    function getInt256Min() internal pure returns (int256) {
        return INT256_MIN;
    }

    function getInt256Max() internal pure returns (int256) {
        return INT256_MAX;
    }

    // Float [fixed point] Operations
    function fxpMul(int256 a, int256 b, int256 base) internal pure returns (int256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(int256 a, int256 b, int256 base) internal pure returns (int256) {
        return div(mul(a, base), b);
    }
}

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

contract FinalBondingCurve {
    using SafeMath for uint;
    using SafeMathInt256 for int;

    uint constant private MAX_INT = 2**255-1;
    uint constant private bisectionPrecision = 0.01 ether; 
    int constant private displacement = 2e15;
    int constant private B = 4*3.2000e40;
    int constant private A = 1250000;
    
    uint public cap;

    constructor(uint _cap) public {
        cap = _cap;
    }

    function computeSaleParameters(
        uint a, // Tokens sold up to now
        uint R // Reserve currency amount that you are willing to spend
    ) 
        public   
        view
        returns (
            uint T, // T = b - a, amount of tokens
            uint finalExpenditure
        )
    {
        
        uint b_cap = cap;
        uint b = b_cap;
        uint best_b;
        uint lower = a;
        uint iterations;

        uint Rr;  // R(sub)r stands for required reserve currency: amount that is needed to purchase b - a tokens

        while(iterations < 20) {
            Rr = evaluateIntegral(safeCastUintToInt(b), safeCastUintToInt(a));
            if(Rr > R) {
                // If the required value is more than what is attached, 
                // we need to find a lower value than R
                b_cap = b;
                b = ((b.sub(lower)).div(2)).add(lower); // b = lower + [b - lower] / 2
            } else {
                finalExpenditure = Rr;
                best_b = b;
                lower = best_b;

                if(R.sub(Rr) > bisectionPrecision) {
                    if(b == b_cap) {
                        break;
                    }
                    b = ((b_cap.sub(b)).div(2)).add(b);
                } else {
                    break;
                }
            }
            iterations++;
        }

        require(
            finalExpenditure <= R, 
            "FinalBondingCurve.computeSaleParameters() - Not enough ether"
        );

        if(finalExpenditure > 0) {
            T = best_b.sub(a);
        }
        require(T > 0, "FinalBondingCurve.computeSaleParameters() - Returned 0 tokens");
    }

    function evaluateIntegral(int b, int a) public pure returns (uint) {
        int _displacement = displacement;

        int _b;
        int _a;

        int b_delta = b.sub(_displacement);
        int a_delta = a.sub(_displacement);

        int _b_fourthComponent = power(uint(SafeMathInt256.abs(b_delta)), uint32(4), false).div(B);
        int _b_firstComponent = A.mul(b_delta);

        _b = _b_fourthComponent.add(_b_firstComponent);

        _a = power(uint(SafeMathInt256.abs(a_delta)), uint32(4), false).div(B)
            .add(A.mul(a_delta));

        require(
            _b > _a, 
            "FinalBondingCurve.evaluateIntegral() - Negative price computed"
        );

        int result = _b.sub(_a);
        return uint(result);
        
    }

    function power(
        uint256 base,
        uint32 exp,
        bool negativeBase // true if base is negative
    ) 
        public
        pure
        returns (int) 
    {
        // (uint result, uint8 precision) = Power.power(base, 1, exp, 1);
        // result = result.div(2**uint(precision));

        uint result = u_pow(base, uint(exp));
        if(negativeBase) {
            return safeCastUintToInt(result) * int(-1);
        } else {
            return safeCastUintToInt(result);
        }
    }

    function u_pow(uint a, uint b) public pure returns (uint r) {
        r = 1;
        while(true) {
            if(b % 2 == 1) r = r.mul(a);
            
            b /= 2;
            if(b == 0) break;
            a = a.mul(a);
        }
    }
    
    function safeCastUintToInt(uint value) public pure returns (int) {
        require(value <= 2**255-1, "FinalBondingCurve.castUintToInt - Overflow");
        return int(value);
    }
}

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
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

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


abstract contract ERC777Receiver is IERC777Recipient {

    // Needed constants to accept ERC777 tokens in deposit
    IERC1820Registry constant private _erc1820 = // See EIP1820
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = // See EIP777
        keccak256("ERC777TokensRecipient");

    constructor() public {
        // Register as a token receiver
        _erc1820.setInterfaceImplementer(
            address(this), 
            TOKENS_RECIPIENT_INTERFACE_HASH, 
            address(this)
        );
    }

    address private token;

    //  @dev: This hook is called when the contract receives GeoTokens.
    //  The contract can only receive GeoTokens from the owner
    function tokensReceived(
        address /*operator*/,
        address from,
        address /*to*/,
        uint256 ,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external override {
        require(msg.sender == getToken(), "GeoPreSale.tokensReceived() - Wrong token");
        require(from == getOwner(), "GeoPreSale.tokensReceived() - Only owner");
    }

    function getOwner() virtual public view returns(address);

    function getToken() virtual public view returns(address);
}


contract Withdrawable is Ownable {

    event EtherWithdrawn(
        address sender,
        uint amount
    );

    receive() external virtual payable {}

    // @dev: allows the owner to withdraw the eth that has been deposited in the contract
    function withdrawEth() external onlyOwner {
        address payable to = payable(msg.sender);
        uint bal;
        assembly {
            bal := selfbalance()
        }
        require(
            bal > 0, 
            "Withdrawable withdrawEth() - No ether balance in the contract"
        );
        (bool success, ) = to.call{value: bal}("");
        require(
            success,
            "Withdrawable withdrawEth() - Could not withdraw eth"
        );

        emit EtherWithdrawn(
            msg.sender,
            bal
        );
    }
}


contract GeoSale is 
    ERC777Receiver,
    Withdrawable,
    FinalBondingCurve {

    uint constant private PEAK_PRICE = 1500000; // WEI / GAGEO

    address public token;

    uint public startSaleTimestamp; // Unix timestamp
    uint public duration; // Seconds
    uint public price = 1000000; // WEI / GAGEO
    uint public tokensSold; // in nanoGeos (gaGeos)

    event PurchasedGeoTokens(
        address indexed sender,
        uint ethAmount,
        uint geoAmount,
        uint returnedEth
    );

    event RemainingGeoTokensWithdrawn(
        address sender,
        uint amount
    );

    constructor(
        uint _startSaleTimestamp,
        uint _duration,
        uint _cap,
        address _token
    )
        FinalBondingCurve(_cap)
        public 
    {
        require(cap > 0);
        require(_token != address(0));
        require(_duration > 0);
        startSaleTimestamp = _startSaleTimestamp;
        duration = _duration;
        token = _token;
    }

    fallback() external {
        revert("GeoPreSale - Fallback function called");
    }

    receive() external payable override {
        swapEtherForGeo();
    }

    function setStartSaleTimestamp(uint timestamp) external onlyOwner {
        startSaleTimestamp = timestamp;
    }

    function setDuration(uint _duration) external onlyOwner {
        require(_duration > 0);
        duration = _duration;
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0));
        token = _token;
    }

    function setCap(uint _cap) external onlyOwner {
        require(_cap > 0);
        FinalBondingCurve.cap = _cap;
    }

    // @dev: allows the owner to withdraw GeoTokens that have not been sold out
    // after the sale has ended
    function withdrawGeo() external onlyOwner {
        require(saleIsOver(), "GeoSale.withdrawGeo() - Sale is not over");

        IERC20 _token = IERC20(getToken());
        uint remainingTokens = _token.balanceOf(address(this));
        _token.transfer(msg.sender, remainingTokens);

        emit RemainingGeoTokensWithdrawn(
            msg.sender,
            remainingTokens
        );
    }

    function swapEtherForGeo() public payable returns (bool) {
        require(saleStarted(), "GeoSale.swapEtherForGeo() - Sale has not started");
        require(!saleIsOver(), "GeoSale.swapEtherForGeo() - Sale is over");

        uint _tokensSold = tokensSold;
        uint _cap = cap;
        uint tokensBought;
        uint finalExpenditure;

        if(_tokensSold < _cap) {
            (tokensBought, finalExpenditure) = computeSaleParameters(_tokensSold, msg.value);
            _tokensSold = _tokensSold.add(tokensBought);

            if(_tokensSold >= _cap && msg.value > finalExpenditure) {
                uint tokensBoughtAtFixexRate = purchaseAtFixedRate(msg.value.sub(finalExpenditure));
                finalExpenditure = finalExpenditure.add(tokensBoughtAtFixexRate.mul(PEAK_PRICE));
                tokensBought = tokensBought.add(tokensBoughtAtFixexRate);
                _tokensSold = _tokensSold.add(tokensBoughtAtFixexRate);
            }
        } else {
            tokensBought = purchaseAtFixedRate(msg.value);
            finalExpenditure = tokensBought.mul(PEAK_PRICE);
            _tokensSold = _tokensSold.add(tokensBought);
        }

        price = finalExpenditure.div(tokensBought);
        tokensSold = _tokensSold;
        uint returnedEth = msg.value.sub(finalExpenditure);

        // Up to this moment, computations were done in nanoGeos.
        // So we perform a conversion to attoGeos by multiplying by 10^9
        tokensBought = tokensBought.mul(10**9);
        require(IERC20(getToken()).transfer(msg.sender, tokensBought));
        address payable to = payable(msg.sender);
        (bool success, ) = to.call{value: returnedEth}("");
        require(
            success,
            "GeoSale.swapEtherForGeo - Could not return eth"
        );

        emit PurchasedGeoTokens(
            msg.sender,
            finalExpenditure,
            tokensBought,
            returnedEth
        );
        return true;
    }

    function precomputePurchase(uint value) 
        external 
        view 
        returns(uint tokensBought, uint finalExpenditure, uint _price) 
    {
        if(!saleStarted()) {
            return (0,0,0);
        }

        if(saleIsOver()) {
            return (0,0,0);
        }

        uint _tokensSold = tokensSold;
        uint _cap = cap;

        if(_tokensSold < _cap) {
            (tokensBought, finalExpenditure) = computeSaleParameters(_tokensSold, value);
            _tokensSold = _tokensSold.add(tokensBought);

            if(_tokensSold >= _cap && value > finalExpenditure) {
                uint tokensBoughtAtFixexRate = purchaseAtFixedRate(value.sub(finalExpenditure));
                finalExpenditure = finalExpenditure.add(tokensBoughtAtFixexRate.mul(PEAK_PRICE));
                tokensBought = tokensBought.add(tokensBoughtAtFixexRate);
                _tokensSold = _tokensSold.add(tokensBoughtAtFixexRate);
            }
        } else {
            tokensBought = purchaseAtFixedRate(value);
            finalExpenditure = tokensBought.mul(PEAK_PRICE);
            _tokensSold = _tokensSold.add(tokensBought);
        }

        // Up to this moment, computations were done in nanoGeos.
        // So we perform a conversion to attoGeos by multiplying by 10^9
        tokensBought = tokensBought.mul(10**9);
        
        _price = finalExpenditure.div(tokensBought);
    }

    function purchaseAtFixedRate(uint value) internal pure returns (uint) {
        return value.div(PEAK_PRICE);
    }

    function getToken() public view override returns (address) {
        return token;
    }

    function getOwner() public view override returns (address) {
        return Ownable.owner();
    }

    function getPrice() public view returns (uint) {
        return price;
    }

    function getTokensSold() public view returns (uint) {
        return tokensSold;
    }

    function getStartSaleTimestamp() public view returns (uint) {
        return startSaleTimestamp;
    }

    function endSaleTimestamp() public view returns (uint) {
        return now + duration;
    }

    function getEndSaletimestamp() public view returns (uint) {
        return now + duration;
    }

    function saleStarted() public view returns (bool) {
        return now > startSaleTimestamp;
    }

    function saleIsOver() public view returns (bool) {
        return now > startSaleTimestamp + duration;
    }
    
}