/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

pragma solidity 0.5.16;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/utils/Address.sol



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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/math/SafeMath.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/token/ERC20/IERC20.sol



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: Pre-Sale.sol

contract Presale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;

    IERC20 private _token;
    uint256 private _tokenDecimals = 18;
    address payable private _wallet;
    uint256 public _rate = 10000000000000000;
    uint256 public _weiRaised;
    uint256 public endICO = 1626294250;
    uint public minPurchase = 10000000000000000;
    uint public maxPurchase = 100000000000000000000;
    uint public hardCap;
    uint public softCap;
    uint public availableTokensICO = 1000000000000000000000;
    uint256 public _rewardTokenCount = 2 ether; // 2 tokens per MATIC
    address[] public _whitelist =  [
                            0xcCc5802DCe888683a77B906994E11554740362F5,
                            0x78Add6b167a669F2D2A2bd90a578598572765C75,
                            0xEF65953cdA61b8eCcdF7BFeA5A9c5896Ab32D2EC,	
                            0x91F730e5f85BC1Efe6497d941A7c6F9F159126DA,	
                            0x117c55CEAEcbC12Cff2e9DCB0F0949876Cfbf21D,	
                            0xF00aeA879FEc57C08F2739E5ba89B455942C7d4e,	
                            0x7061e70B88268765072520A44d0A1E326121959e,	
                            0xa237466B0585A4840af903a5a0CEa93983B803ad,	
                            0xAbB64609c38ec423D78fBDCEA97FAd284061a59b,	
                            0x15b66544f7D17222607A045d3F004591765309E2,	
                            0x5DB8638D35E022467F3Bc8eFC93ec7Cd126A370e,	
                            0xB521ba53dd76E6A503425d973464f6329213D2C6,	
                            0x67aa2F8ece6A8DA4E1759776816ce9D94747c138,	
                            0x60915920B97799551C046AB11d96aCb79b719899,	
                            0xDa3140D6698805aec58384F99897D9781Bd1ac6e,	
                            0xd062092BAF32BB2bEe340028d53D06198a7Cf032,	
                            0x9898E12A615D0A23b0E738873154f70070cbE680,	
                            0x8281e0Aa17BdCA83611D038CE2CF0e4856Ba22f7,	
                            0x8281e0Aa17BdCA83611D038CE2CF0e4856Ba22f7,	
                            0xd6347718074C3AE835a49ce31e293860b415813f,	
                            0x621ade4Fa795F4CF18F713A98961271BBD540611,	
                            0x8d012c274936d72dF2085Ab89Cc9C8e8247aA1EA,	
                            0xcbDB632C11D2a173C288c9ffa6BbD1D2eeD8AfCe,	
                            0x9eDA9317771080eC5c5Da3b88b4D349103D18EEc,	
                            0xF4a5411139c6C660965162eb549cf3a1851F2943,	
                            0x249C57D94Baa8D61773d004A0E6c1a22c945749f,	
                            0x393451651A91EF458e954dB8804D42Ae15bBC813,	
                            0x73Db983039Bc2F438FBd3cB3131417410DAD417F,	
                            0xA3599Cf1048930c9E897fe9245Dd95511CD16F1c,	
                            0xf3f717664E34218D17841Ed294825bFE51126eA3,	
                            0x4615a93bb1FB1A4d93866b18b962526cdE4f22FE,	
                            0x462459412dE45e300992E24D1f2256840694ab31,	
                            0x1d8E86079c7d63b46650c8564c3e19150cDD17fE,	
                            0x6dA64C0db759a0CC8D0E473E5A372525BDA44602,	
                            0x41f31bC9357f34e51115E232Cfb1Be525AC60B82,	
                            0x553dfeE8329A080a8b486665C0A583BbBb472a38,	
                            0x64a9EB1B7B8601ED4bBc5F68934469ffDa7ef543,	
                            0x6dA31701A98fac38d0536E4889DD3149e4b961b8,	
                            0xC621910649BC0c2E4170d1eFB453847c1867d1b1,	
                            0xc5C6e56303199e58d5FFf0A93B5F0968790f89C8,	
                            0xeCF48F983f184F68cb8B892894Ba4d1b4b88C47C,	
                            0x0C1c9f4462Daf1e244854eB46f26217e3361D01C,	
                            0x7eaFafb98F50E477A8D3015d0f9E0439f30121EF,	
                            0x79F57E53618D51eeEF5bADDea0Cb2FB2a0b836FB,	
                            0x5DB8638D35E022467F3Bc8eFC93ec7Cd126A370e,	
                            0xFD5B061127Be14dED27D8a8f380fD760321326E8,	
                            0x7A13BFC2f21809A0eC1c8f787DFA5136579EB6D1,	
                            0x231DC6af3C66741f6Cf618884B953DF0e83C1A2A,	
                            0xDa3140D6698805aec58384F99897D9781Bd1ac6e,	
                            0xcf16eE08420cC221b4d578f253A23F3c681fA2d2,	
                            0x984895138A2F2df973f7bF86e75a407Fc4761689,
                            0xE4F97132E899bc7cDe314038Da464427FBa27Ba3,	
                            0xC6AaEC76D63F74187Ef0535E3da947392d129DE2,	
                            0xD1453C1310846EC5Ba080fCb1D3E128e9D124745,	
                            0xa51BFFf166A5856eC27f456EFEea0E168f4b51D7,	
                            0xEF65953cdA61b8eCcdF7BFeA5A9c5896Ab32D2EC,	
                            0x45A1829320A626AD4D82168E6242d030a709Ae85,	
                            0xD8aBcfeC16caE6E4beE297dAab7643B37e593AAb,	
                            0x26cCddA3Cbf743576a465eA9D84f6847f77Aa737,	
                            0xE57C2d78Df84C41b3A4a9F335550F69e10e10B19,	
                            0xd676A44e0CBFE328C1dD67195812Be6382dDc557,	
                            0x9779323d503353b2471C8B960894053e6F7f08B7,	
                            0x7706774304d03056B696a4DC3374b0aFA3eA4937,	
                            0xf617E6857f5Dff4E49866Ebf521a60db2627b97e,	
                            0x63c960065eaFcc491F953BD343fa28074132fF1D,	
                            0xB6E924fF23d1A220d474A73D5D1CBCf99f57cAb6,	
                            0x25B336f51A533193fb8625aAf4AcD49e17EA28Ae,	
                            0x07529A0DBeaA96754F7296DB6C0Aca9224601917,	
                            0xAC99d9D77E08300916bBbdF9C934dA055f522539,	
                            0x5371ea6440bF544a2322B5A9e9dE1E04c2b6a8b9,	
                            0xc655ECD136d33881E800cB2204b5400D81Fe3A12,	
                            0x7caF9E4717621C2332228A58A213b2DbB329D458,	
                            0xD136C1A2CF7b033093E449F72062b835254Ab23e,	
                            0xf925fA575018e1DF7ee9bE6ed7C4aEf306418dfF,	
                            0xCB865F3867ebc8D5Aa2E69f21Aa1c6B142Ef9D7b,	
                            0xEA7202f9230dAC216B0a4d4206AE9Ac4BC814359,	
                            0x91b883bBea30d674b617E64271779DE2E693a1ec,	
                            0x44D5C324D3643a91884D9830A4cD87f6BA0c1f22,	
                            0x473391762E1a0033e2959B0166863150B2904F10,	
                            0x41086dc10eE7b900124a77D06f734BCa704CCbF0,	
                            0x58440dAc3D6962F3FAD231e2E238F02A7FbA8D7a, 	
                            0x576bF5674179dECB0891A12735A2deeEad170Bfb,	
                            0x7CB1FA27A7F5FAbC055E1CDBda3821F249300159,	
                            0xeb42523A092CeaFb6b5b52b0a88d3F88154A3494,	
                            0x8E7c869c3eA55F4701826494CC83d15885C06DF6,	
                            0x5F045d4CC917072c6D97440b73a3d65Cb7E05e18,	
                            0x7eaFafb98F50E477A8D3015d0f9E0439f30121EF,	
                            0xa8A762ef90B1482b3AebdE95D1A643f6B38eF1eD,	
                            0xaA747f556d2b3445E33b24B6339278cBbf2dc683,	
                            0xF2F8C75731f20b5F759583ed9e0EdEA4f05661E1,	
                            0x88C37d3444d75570ea855D88538dD11A54c64daF,	
                            0xA046bAf02A83955787E8AaE77334F6d2Fba5576B,	
                            0xcA896E8040Bec149C4Fb5F6c7564bF4C1CC659b2,	
                            0x62BA33Ccc4a404456e388456C332D871DaE7ae9e,	
                            0x65447911A39A393E7b79f5964B360c0DF9Bf3701,	
                            0x999e2d7DE21Fa2E1243B6a4072AfFE1410A7b485,	
                            0x1ee93BF13d1D1d876330B011B28c507e392bc5E1,	
                            0x5d7d30c4C793d3d0655c6550ec610203fD42EC3C,	
                            0x4FF01121Fe58ef00d24eBAA42dFEA63191778848,	
                            0x1b18D4D3491E6aAA6d883600572B0573A4e39995,	
                            0x37eeEeB9bc8e3d144E2225660645ed68bE5b666C,	
                            0xefdee53249EF08013D31AEAC2A738912197b7b5e,	
                            0x7Cd3DC26372c4b57aeC9F4aa9F5DeDa3DE05F578,	
                            0xD206c66bc5C4886db7c577eA243c7c59cDE7B4e6,	
                            0x92D55b5Bf9C28feE577D61a34ab8AE74593D0f71,	
                            0x46AAA27dBC0c4d4d1c8Afb81E7e032D44E0fdE36,	
                            0x357798cF6c8e51c77265aFf75dA367e3046521e5,	
                            0x6c8C7539Bf6A61c249c520C837Ed0e19F91344dC,	
                            0xfA31DCfF7bED47232B82b50FC0ec9582b9B4Fb3a,	
                            0xFfDe865353Cb473544b8f98965A9D1f284ddA3b5,	
                            0x589169EEE30B318dDf501aEe0a2463B35d4cA9b8,	
                            0xBd1E1Cc9613B510d1669D1e79Fd0115C70a4C7be,	
                            0x7caF9E4717621C2332228A58A213b2DbB329D458,	
                            0xe5D331Af8F8c037DaDB7a104d49f99881187bf8d,	
                            0xFc2409D354aecF18b179153Eb76e00eFb64c25aD,	
                            0x6737E12f8675318d2734eC5033c73aDd8DC3103c,	
                            0xF0607e43F7Fb2C888324dEAb09E34e4aBfEE6483,	
                            0x3774539539A91bA9dBcFbA5802fCBdbb8A40f45F,	
                            0x0B431F91c54C303AE29E4023A70da6caDEB0D387,	
                            0x6FA011E62DCF08A6A34e2128D1a7238A14BEaa5A,	
                            0x3f6121301D1E82F52285f601C3720Ca6514090a1,	
                            0x26cCddA3Cbf743576a465eA9D84f6847f77Aa737,	
                            0xcd2ffAf0Bf833EeF3b09C22756A52701F035844a,	
                            0x78bbdEDd45C31f0AE0071FF0e0B6742C2e45B39b,	
                            0x05586F66c500A215f1d1F3B38a2Dec0CE870ba30,	
                            0x139CDaD81a2689785ca6CcD75Eab7B63625Ac8D0,	
                            0x8a3700824e59400Ac1E254846D4b1E70156b3dc0,	
                            0x9C0244D8cf50cb154340F86098e7516adf417C75,	
                            0x10D37F3AFEe8839f16785539120b408A17cD4A60,	
                            0x74f5C619E7C23d788EeAD0b748A1ada20e081E00,	
                            0x003CC1750568b4Df54d7C904f3Ae2D6501f54358,	
                            0xa51BFFf166A5856eC27f456EFEea0E168f4b51D7,	
                            0xe83b248f783425A1bc3639FD7cCFFd698d38Cd05,	
                            0x7126845297E287F4ae18B4001d7688B6cf219955,	
                            0x64524218879e96D9a11d48994219E389B55369B1,	
                            0x425912cC8161a9E704c9fF1C49DB069c44f8F2BC,	
                            0xc6830255313a132970b4A6A8729f9723190fB87f,	
                            0xA1792068ab6cAdFf17CB0F47E14EBFa7c062C2f2,	
                            0xcFB176f6bCff89c35fE9EE14Fb3E77a30609D5E0,	
                            0xAFc6dfc1cb44E8267F62281B3632795Adb6854f4,	
                            0xA585F8A07D9Dadd8800b0406dBD578B6c4D134Dd,	
                            0xFfa63650fdA779F51d017C5A448C310c4ebb8106,	
                            0xBd305Af2d1E0712C57e7Eb33f175D3f0Bd4E898A,	
                            0x894D437C214A67Eb317E928939B9f1BC12D9254C,	
                            0xf617E6857f5Dff4E49866Ebf521a60db2627b97e,	
                            0x4985496569C9a5CcF8B612cB40ba8f4B94A44534,	
                            0xB79ACBfb800cB1fB8ea88ff66E1E55F747d40aeb,	
                            0x792A8c39Ff0395672850e354bA911D48fFc19cD5,	
                            0x1315030c1cC52B347E238241C50cf3772F6d57C9,	
                            0x63C7bC068b7E32F972dac8Fd7E0A953186727c74,	
                            0x722Cd9d7e04399EA85E2Acdb4715579021DE6074,	
                            0xDd71785728296Ea92AD3316Bd52344E2b5245dCc,	
                            0xBF274d835903CD079bCf44CeBF2c670fDf0a766D,	
                            0x2b4916c1f93eFebC349Dd0C1b6bBA68eD9C0B968,	
                            0xFa94fB54359EFa764ff88dD3526263A9e5933eae,	
                            0xdF7F6a989543A5C65B14fF29655019012f8aF613,	
                            0xb4630Ce451831107fEbA573C74BE6FB667Dfd2CE,	
                            0xB04E1B3D1e98097b3986C366Eb679DA0ed95168C,	
                            0xAbB64609c38ec423D78fBDCEA97FAd284061a59b,	
                            0x5377463c67404E44f7b5C0Cf2fe67ea854F18E11,	
                            0x4BD8dE83B562edAEE255f7dDeA534edeF7BC5641,	
                            0x47d771b647D994411ecEd4dc795A3c7a5BF2181a,	
                            0x43183DF1879daF4bBa3A0912C19127aEeeCcfbA8,	
                            0xC3E7D60EC6d343A2e5aF0f815E88502CE286E07c,	
                            0x8D20dFE758965a003A73Ba3245bdcd309D12e3dE,	
                            0x34CD56f7e3782aDD372E8adce9c01c688aa6F97c,	
                            0xd87D755A9F3dF5d9fd55DE38E06bBCA24cf89a8F,	
                            0x48768F1c19F3C017d3dc296CC4d32132f14bb437,	
                            0x78bbdEDd45C31f0AE0071FF0e0B6742C2e45B39b,	
                            0x733AB147ef8F4efEA84ced248F1AFE74FBe21582,	
                            0xc79C62c6D44eE6008C88F1cEF59067dd2c551949,	
                            0x5E364545718acf5c851f26f2acB0CA9F21574Eb2,	
                            0xa1d4baBa09C609C3d8d4D163DA4755C155C3232B,	
                            0xbd38B8C2c67BBd4404F724c5f7aB04A990817483,	
                            0xaCDB42766820dDC420caa527ea9fCE76A58b3c67,	
                            0x757233ab96f929b29259ce9655E7fDC192AF4e03,	
                            0xFa94fB54359EFa764ff88dD3526263A9e5933eae,	
                            0xAbD56378d208ef9855Cd149c6ebfc124bEB01374,	
                            0xB718887CBA6735BAcB3dc33743413940EF8982B8,	
                            0x5e2d4dcbDC864AFA6094A6b93e2b6813fE3D560d,	
                            0xcC38Ec4a91d774425a9bAd3ccBc3a54342B6b0C7,	
                            0x84c1bdd7b5dffA1078E4577E3aFE6819d0A1B34D,	
                            0xEB002AF9ca6AA416BaACEfA78E5D505759286355,	
                            0x04eA72B1e2982Ab6c3e7dDc8D6F1A4340F2aa1D5,	
                            0x2dBC97FAFd68396bf4beC82b89Aa8E78Af2e3077,	
                            0x5CCbb4C11F4ECe1e0F45cC19e5a8B534d2d08DB9,	
                            0x98d0E5A9063C05Bc36A14c01F99f41b354d53bF3,	
                            0x6739e546097e25547C5492d7Bd9296DC13077694,	
                            0x4F4Ee62565E898BeE92bae48890A31a6F38C2C2E,	
                            0xfE5a0963409609243a819A28034505567418b32c,	
                            0x139CDaD81a2689785ca6CcD75Eab7B63625Ac8D0,	
                            0x5E364545718acf5c851f26f2acB0CA9F21574Eb2,	
                            0xc50406db4770d7d8c98Db9dE97a072cD2207b20b,	
                            0x44eD262E751B02cd51494e685f01630f514B86c9,	
                            0xdCb111Ce57362108cD23667E8AF7C705237d0cd8,	
                            0xAC20B08E2d500462f81418570C3B62FF5E340116
    ];

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (uint256 rate, address payable wallet, IERC20 token, uint256 tokenDecimals) public {
        require(rate > 0, "Pre-Sale: rate is 0");
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(address(token) != address(0), "Pre-Sale: token is the zero address");
        
        _rate = rate;
        _wallet = wallet;
        _token = token;
        _tokenDecimals = 18 - tokenDecimals;
    }

    function () external payable {
        if(endICO > 0 && now < endICO){
            buyTokens(_msgSender());
        }
        else{
            revert('Pre-Sale is closed');
        }
    }
     
    //Start Pre-Sale
    function startICO(uint endDate, uint _minPurchase, uint _maxPurchase) external onlyOwner icoNotActive() {
        availableTokensICO = _token.balanceOf(address(this));
        require(endDate > now, 'duration should be > 0');
        require(availableTokensICO > 0 && availableTokensICO <= _token.totalSupply(), 'availableTokens should be > 0 and <= totalSupply');
        require(_minPurchase > 0, '_minPurchase should > 0');
        endICO = endDate; 
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }
    
    function stopICO() external onlyOwner icoActive(){
        endICO = 0;
    }
    
    //Pre-Sale 
    function buyTokens(address beneficiary) public nonReentrant icoActive payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);

        availableTokensICO = availableTokensICO - weiAmount;

        _processPurchase(beneficiary, _rewardTokenCount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
        _forwardFunds();
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
        require(weiAmount <= maxPurchase, 'have to send max: maxPurchase');
        bool isWhiteListed = false;
        for (uint i = 0; i <= _whitelist.length; i++) {
            if(_whitelist[i] == beneficiary) {
              isWhiteListed = true;
            }
        }
        require(isWhiteListed == false, 'You have no access for the pre-sale');
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

 
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }


    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate).div(10**_tokenDecimals);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
    
    function withdraw() external onlyOwner {
         require(address(this).balance > 0, 'Contract has no money');
        _wallet.transfer(address(this).balance);    
    }

    function addWalletToPresaleList(address wallet) external onlyOwner {
        bool isWhiteListed = false;
        for (uint i = 0; i <= _whitelist.length; i++) {
            if(_whitelist[i] == wallet) {
              isWhiteListed = true;
            }
        }
        require(isWhiteListed == true, "Is already white listed");
        _whitelist.push(wallet);
    }
    
    function token() public view returns (IERC20) {
        return _token;
    }

    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function rewardTokenCount() public view returns (uint256) {
        return _rewardTokenCount;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }
    
    function setRate(uint256 newRate) public onlyOwner {
        _rate = newRate;
    }

    function setRewardTokenCount(uint256 rewardToken) public onlyOwner {
        _rewardTokenCount = rewardToken;
    }
    
    function setAvailableTokens(uint256 amount) public onlyOwner {
        availableTokensICO = amount;
    }
 
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner(){
        _wallet = newWallet;
    }
    
    function setSoftCap(uint256 value) external onlyOwner{
        softCap = value;
    }
    
    function setHardCap(uint256 value) external onlyOwner{
        hardCap = value;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner{
        maxPurchase = value;
    }
    
    function setMinPurchase(uint256 value) external onlyOwner{
        minPurchase = value;
    }
    
    function takeTokens(IERC20 tokenAddress)  public onlyOwner{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(_wallet, tokenAmt);
    }
    
    modifier icoActive() {
        require(endICO > 0 && now < endICO && availableTokensICO > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < now, 'ICO should not be active');
        _;
    }
    
}