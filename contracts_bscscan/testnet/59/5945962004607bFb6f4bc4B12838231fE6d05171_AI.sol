// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IDexRouter {
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

interface IDexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



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
     * TODO: Add comment
     */
    function burn(uint256 burnQuantity) external returns (bool);

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


interface INeuralPepe is IERC721Enumerable {
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}

interface IAiRouter {
  function distributeTax(uint256 taxAmount) external;
  function isInSwap() external view returns (bool);
  function supportsDistribureFunction() external pure returns (bool);
  function authorize(address adr) external;
  function liquifyBack() external;
}

/**
 * @title AI Contract (The native token of Neural Pepe)
 * @dev Extends standard ERC20 contract
 */
contract AI is Context, IERC20 {
    using SafeMath for uint256;

    // Contract Info
    string private constant _name = 'AIv2';
    string private constant _symbol = 'AI';
    uint8 private constant _decimals = 18;

    // Constants
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant INITIAL_ALLOTMENT = 420000000000000000000;
    uint256 public constant emissionEnd = 1933606800;
    uint256 public constant aiSnapshot = 1632158133;
    uint256 public constant feeDenominator = 1000;

    // Public variables
    uint256 public emissionPerDay = 2300000000000000000;
    uint256 public MAX_EMISSION = 10000000000000000000;

    bool public collectTaxes = true;
    bool public feeOnNonTrade = false;
    bool public swapEnabled = false;
    
    address public ai2bnb;

    // Private variables
    mapping (address => bool) internal authorizations;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(uint256 => uint256) private _lastClaim;
    
    uint256 private _totalSupply;
 
    address private contractOwner;
    address private constant _pepeAddress = 0xdda79D8C0998a19ECa7fe6aAaBfCEe980E66F982;
    address private constant _dexRouterAddress = 0x3380aE82e39E42Ca34EbEd69aF67fAa0683Bb5c1; // APE
    address private _aiTaxAddress;

    IAiRouter private aiRouter;
    IDexRouter private router = IDexRouter(_dexRouterAddress);
    INeuralPepe private constant PEPE = INeuralPepe(_pepeAddress);

    address[] public pairs;

    mapping (address => address) private _taxAddresses;
    mapping (address => uint256) private _taxAmount;
    mapping (address => bool) private _isLaunched;
    mapping (address => bool) isFeeExempt;

    /**
     * @dev
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (uint amountToMintForDistribution) {
        contractOwner = msg.sender;
        authorizations[contractOwner] = true;

        ai2bnb = IDexFactory(router.factory()).createPair(router.WETH(), address(this));
        pairs.push(ai2bnb);
        _taxAddresses[ai2bnb] = address(0x1);
        _taxAmount[ai2bnb] = 5;
        _isLaunched[ai2bnb] = false;
        
        _allowances[address(this)][address(router)] = type(uint256).max; // DOUBLE CHECK
        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;

        _mint(contractOwner, amountToMintForDistribution);
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(authorizations[msg.sender], "!AUTHORIZED"); _;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
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
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev When accumulated AIs have last been claimed for a Neural Pepe index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(PEPE.ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        
        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : aiSnapshot;
        return lastClaimed;
    }

    /**
     * @dev Accumulated AI tokens for a Neural Pepe token index.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(PEPE.ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < PEPE.totalSupply(), "AI at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd) return 0;

        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd; // Getting the min value of both
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);

        return totalAccumulated;
    }

    /**
     * @dev Claim mints AIs and supports multiple Neural Pepe token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        uint256 totalClaimQty = 0;
        for (uint i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < PEPE.totalSupply(), "AI at index has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }

            uint tokenIndex = tokenIndices[i];
            require(PEPE.ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated AI");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    /**
     * @dev Only owner can call this function. Change AI emission per day.
     */
    function changeEmissionPerDay(uint256 _newEmissionPerDay) public onlyOwner {
      require(_newEmissionPerDay >= 0 || _newEmissionPerDay <= MAX_EMISSION, 'invalid emission per day');
      emissionPerDay = _newEmissionPerDay;
    }

    /**
     * @dev Only owner can call this function. Tax amount, can be between 1 and 20.
     */
    function changeTaxAddressAndAmount(address tradeAddress, address taxAddress, uint256 _newTaxAmount) public onlyOwner {
      require(_newTaxAmount >= 0 && _newTaxAmount <= 20, 'Provide valid tax between 1 and 20');
      require(_taxAddresses[tradeAddress] != address(0), 'Trade address doesnt exist');

      _taxAddresses[tradeAddress] = taxAddress;
      _taxAmount[tradeAddress] = _newTaxAmount;

      aiRouter = IAiRouter(taxAddress);
    }

     /**
     * @dev Only owner can call this function. Tax amount, can be between 1 and 20.
     */
    function changeTaxForAllTradeAddresses(uint256 _newTaxAmount) public onlyOwner {
      require(_newTaxAmount >= 0 && _newTaxAmount <= 20, 'Provide valid tax between 1 and 20');

      for (uint256 i = 0; i < pairs.length; i++) {
        _taxAmount[pairs[i]] = _newTaxAmount;
      }
    }

    /**
     * @dev Only owner can call this function. Activates tax collection.
     */
    function activateTaxCollection() public onlyOwner {
      require(!collectTaxes, 'Tax is already active');
      collectTaxes = true;
    }

    /**
     * @dev Only owner can call this function. Activates tax collection.
     */
    function stopTaxCollection() public onlyOwner {
      require(collectTaxes, 'Tax is already inactive');
      collectTaxes = false;
    }

    /**
     * @dev Only owner can call this function. Activates tax collection.
     */
    function changeTaxAddress(address newTaxAddress) public onlyOwner {
      require(newTaxAddress != address(0), 'Should not be a 0 address');
      require(IAiRouter(newTaxAddress).supportsDistribureFunction(), 'Not valid router');

      _aiTaxAddress = newTaxAddress;
      aiRouter = IAiRouter(_aiTaxAddress);
    }

    /**
     * @dev Only owner can call this function. Add taxable address.
    */
    function addTradeAddress(address newTradeAddress, address taxAddress, uint256 taxForAddress) public onlyOwner {
      require(newTradeAddress != address(0), 'Should not be a 0 address');
      require(!_isTradeAddressExists(newTradeAddress), 'The address you try do add already exists');


      pairs.push(newTradeAddress);
      _taxAddresses[newTradeAddress] = taxAddress;
      _taxAmount[newTradeAddress] = taxForAddress;
      _isLaunched[newTradeAddress] = false;
    }

    /**
     * @dev Only owner can call this function. Remove taxable address.
    */
    function removeTradeAddress(address tradeAddressToRemove) public onlyOwner {
      require(_isTradeAddressExists(tradeAddressToRemove), 'The address you try to remove doesnt exist');
      uint addressIndex = _getAddressIndex(tradeAddressToRemove).sub(1);

      for (uint i = addressIndex; i < pairs.length - 1; i++) {
        pairs[i] = pairs[pairs.length - 1];
      }
      pairs.pop();
    }
    /**
     * @dev Only owner can call this function. Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address adr) public onlyOwner {
        require(adr != address(0), 'Should not be a 0 address');
        contractOwner = adr;
        authorizations[contractOwner] = true;
    }

    /**
     * @dev Only owner can call this function. Renounce ownership to ZERO address. Caller must be owner.
     */
    function renounceOwnership() public onlyOwner {
        contractOwner = address(0);
    }

    /**
     * Authorize address. Caller must be owner.
    */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Caller must be owner.
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * @dev Internal functions.
     */
    function _isTradeAddressExists(address tradeAddress) public view returns (bool) {
      if (pairs.length == 0) { return false; }
      for(uint i = 0; i < pairs.length; i++) {
        if (pairs[i] == tradeAddress) {
          return true;
        }
      }
      return false;
    }

    function _getAddressIndex(address tradeAddress) private view returns (uint) {
      for(uint i = 0; i < pairs.length; i++) {
        if (pairs[i] == tradeAddress) {
          return i.add(1);
        }
      }
      return 0;
    }

    function _isTrade(address sender, address recipient) private view returns (bool, address) {
      if (pairs.length == 0) { return (false, address(0)); }
      for(uint i = 0; i < pairs.length; i++) {
        if (pairs[i] == sender || pairs[i] == recipient) {
          return (true, pairs[i]);
        }
      }
      return (false, address(0));
    }

    // function launch(address tradeAddress) internal {
    //   _isLaunched[tradeAddress] = true;

    // }
    

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
     * @dev Provides MAX approve to `spender`
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }


  function transfer(address recipient, uint256 amount) external override returns (bool) { return _transferFrom(msg.sender, recipient, amount); }

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if (_allowances[sender][msg.sender] != type(uint256).max) {
      require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
      _allowances[sender][msg.sender] -= amount;
    }

    return _transferFrom(sender, recipient, amount);
  }

	function _basicTransfer(address sender, address recipient, uint256 amount) internal  returns (bool) {
		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
  }

  function basicTransfer(address recipient, uint256 amount) external returns (bool) {
    return _basicTransfer(msg.sender, recipient, amount);
  }

  function returnTradeAddress(address sender, address recipient) internal view returns (address) {
    address[] memory liqPairs = pairs;
    for (uint256 i = 0; i < liqPairs.length; i++) {
      if (sender == liqPairs[i] || recipient == liqPairs[i]) {
        return liqPairs[i];
      }
    }
    return address(0);
  }

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

    // if inSwap _basicTransfer
    // launch
    // take fee
    // distribute tax, if needed liquify

		require(amount > 0);
    address tradeAddress = returnTradeAddress(sender, recipient);
    bool isInSwap = IAiRouter(_taxAddresses[tradeAddress]).isInSwap();

    if (isInSwap) {
      return _basicTransfer(sender, recipient, amount);
    }

    // activates the liquidity on DEX
    if (!_isLaunched[tradeAddress] && recipient == tradeAddress && tradeAddress != address(0)) {
        require(_balances[sender] > 0);
        require(sender == contractOwner, "Only the owner can be the first to add liquidity.");
        _isLaunched[tradeAddress] = !_isLaunched[tradeAddress];
        
        return _basicTransfer(sender, recipient, amount);
    }

    require(amount <= _balances[sender], "Insufficient Balance");
    _balances[sender] -= amount;

    // checks whether it needs to take a fee and takes it before transferring to the 
    uint256 amountReceived = shouldTakeFee(sender, recipient, tradeAddress) ? takeFee(sender, amount, tradeAddress) : amount;
    uint256 tax = amount - amountReceived;
    
    // checks whether there is enouth tokens on balance to liquify the pair
    // if (tax > 0) {
    //   IAiRouter(_taxAddresses[tradeAddress]).distributeTax(tax);
    // }

    if (shouldSwapBack(tradeAddress) && !isInSwap && tax > 0) {
      IAiRouter(_taxAddresses[tradeAddress]).liquifyBack();
    }

    _balances[recipient] += amountReceived;
    emit Transfer(sender, recipient, amountReceived);
    return true;
    }


	// Decides whether this trade should take a fee.
	// Trades with pairs are always taxed, unless sender or receiver is exempted.
	// Non trades, like wallet to wallet, are configured, untaxed by default.
	function shouldTakeFee(address sender, address recipient, address tradeAddress) internal view returns (bool) {
    if (isFeeExempt[sender] || isFeeExempt[recipient] || !_isLaunched[tradeAddress]) {
			return false;
		}

        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) {
				return true;
			}
        }

        return feeOnNonTrade;
    }

	function takeFee(address sender, uint256 amount, address tradeAddress) internal returns (uint256) {
		if (!_isLaunched[tradeAddress]) { return amount; }

		uint256 liqFee = 0;
    
    // If there is a liquidity tax active for autoliq, the contract keeps it.
    if (_taxAmount[tradeAddress] > 0) {
      liqFee = amount * _taxAmount[tradeAddress] / feeDenominator;
      _balances[_taxAddresses[tradeAddress]] += liqFee;
      emit Transfer(sender, _taxAddresses[tradeAddress], liqFee);

      IAiRouter(_taxAddresses[tradeAddress]).distributeTax(liqFee);
    }

    return amount - liqFee;
  }

  function shouldSwapBack(address tradeAddress) internal view returns (bool) {
      return _isLaunched[tradeAddress]
          && msg.sender != tradeAddress
          && swapEnabled
          && _balances[_taxAddresses[tradeAddress]] > 0;
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

    // ++
    /**
     * @dev Burns a quantity of tokens held by the caller.
     *
     * Emits an {Transfer} event to 0 address
     *
     */
    function burn(uint256 burnQuantity) public virtual override returns (bool) {
        _burn(msg.sender, burnQuantity);
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

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    // add MINTING function

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
    // function _setupDecimals(uint8 decimals_) internal {
    //     _decimals = decimals_;
    // }

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