// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../UnicornMint.sol";
import "../library/BalanceLib.sol";
import "../interfaces/IURC20.sol";

contract Farm is UnicornMint{
    
    
    using SafeMath for  uint256;
    
    using SafeERC20 for IURC20;
    
    constructor(
        IURC20 _mac,
        uint256 _macsPerBlock
    ) 
    {
        mac = _mac;
        macsPerBlock = _macsPerBlock;
        startBlock = block.number;
        lastUpdateBlock = startBlock;
    }
    
    uint256 public startBlock;
    
    uint256 public macsPerBlock;

    
    uint256 internal DIVISOR = 100;
    uint256 internal MRATE = 90;
    uint256 internal BASE = 1000000;
    uint256 internal END_MONTH = 17;

    uint256 constant internal REDUCE_PERIOD = 864000;
    uint256 constant internal THRESHOLD = 200000000 * 1e18 ;
    
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;
    
    address public dead = 0x000000000000000000000000000000000000dEaD;

    IURC20  public mac;
    
    mapping(bytes32=>BalanceLib.Balance) public balances;
    
    mapping(bytes32=>uint) public rewards;
    
    event Mint(address indexed farm, address indexed account, uint salt, uint amount);
    
    event Burn(address indexed farm, address indexed account, uint salt, uint amount);
    
    event Withdraw(address indexed farm, address indexed account, uint salt, uint amount);

    
    function getRate(uint _m) public view returns (uint) {
        if(_m>END_MONTH) _m = END_MONTH;
        return BASE.mul(MRATE**_m)/(100**_m);
    }
    
    function hash(address minter,address account,uint256 salt) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                minter,
                account,
                salt
            )
        );
    }
    
    function mint(address account, uint256 _amount, uint256 salt) external onlyMinter {
        bytes32 _to = hash(msg.sender,account,salt);
        
        updateReward(_to);
        
        balances[_to].amount = balances[_to].amount.add(_amount);
        
        totalSupply = totalSupply.add(_amount);
        
        emit Mint(msg.sender,account,salt,_amount);
    }

    function burn(address account, uint256 _amount, uint256 salt) external onlyMinter {
        
        bytes32 _to = hash(msg.sender,account,salt);
        
        updateReward(_to);
        
        balances[_to].amount = balances[_to].amount.sub(_amount);
        
        totalSupply = totalSupply.sub(_amount);
        
        emit Burn(msg.sender,account,salt,_amount);

    }
    
    function withdraw(address account,uint256 salt) external onlyMinter returns(uint reward) {
        
        bytes32 _to = hash(msg.sender,account,salt);
        
        updateReward(_to);
        
        reward = rewards[_to];
        
        rewards[_to] = 0;
        
        safeMacTransfer(msg.sender,reward);
        
        emit Withdraw(msg.sender,account,salt,reward);
    }
    
    function autoMint() internal view returns( uint macMint, uint macPure, uint macBurn ) {
        
        (uint256 multiplier,uint256 curHash) = getMultiplier(lastUpdateBlock,block.number);
        
        macMint = multiplier.mul(macsPerBlock).div(BASE);
        
        macPure = macMint.mul(curHash).div(THRESHOLD);
        
        macBurn = macMint.sub(macPure);
        
    }

    function updateReward(bytes32 _to) internal {
        require(block.number>startBlock,"not start");
        ( , uint macPure, ) = autoMint();
        rewardPerTokenStored = rewardPerToken(macPure);
        lastUpdateBlock = block.number;
        
        rewards[_to] = 
            balances[_to].amount
            .mul(
                rewardPerTokenStored.sub(balances[_to].rewardPerTokenPaid)
            )
            .div(1e24)
            .add(rewards[_to]);

        balances[_to].rewardPerTokenPaid = rewardPerTokenStored;
        
    }

    function rewardPerToken(uint macPure) public view returns(uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            macPure.mul(1e24).div(totalSupply)
        );
    }

    function earned(address user,address farm,uint salt) public view returns (uint256) {
        bytes32 account = hash(farm,user,salt);
        
        (uint256 multiplier,uint256 hastRate) = getMultiplier(lastUpdateBlock,block.number);
        uint macPure = multiplier.mul(macsPerBlock).mul(hastRate).div(THRESHOLD).div(BASE);
        return
            balances[account].amount
                .mul(
                    rewardPerToken(macPure).sub(balances[account].rewardPerTokenPaid)
                )
                .div(1e24)
                .add(rewards[account]);

    }

    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256 multiplier,uint256 hashRate)
    {

        uint fromMonth = month(_from);
        uint toMonth  = month(_to);
        uint _startBlock = _from;
        
        for(;fromMonth<=toMonth;fromMonth++){
            uint _endBlock = monthEndBlock(fromMonth);
            if(_to<_endBlock) _endBlock = _to;
            multiplier = multiplier.add(
                _endBlock.sub(_startBlock).mul(getRate(fromMonth))
            );
            _startBlock = _endBlock;
        }

        hashRate = totalSupply;
        if(hashRate>THRESHOLD){
            hashRate = THRESHOLD;
        }
    }

    function monthEndBlock(uint256 _month) public view returns (uint) {
        return startBlock.add((_month+1).mul(REDUCE_PERIOD));
    }

    function month(uint256 blockNumber) public view returns (uint _month) {
        if(blockNumber>startBlock) {
            _month = (blockNumber-startBlock)/REDUCE_PERIOD;
        }
    }

    
    function safeMacTransfer(address _to, uint256 _amount) internal {
        uint256 macBal = mac.balanceOf(address(this));
        if (_amount > macBal) {
            mac.safeTransfer(_to, macBal);
        } else {
            mac.safeTransfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnicornMint is Ownable{
    
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private _minters;

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "MdxToken: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "MdxToken: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "MdxToken: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library BalanceLib {
    
    struct Balance {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardPerTokenPaid; // Reward debt. See explanation below.
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IURC20 is IERC20 {
    
    function decimals() external view returns(uint);
    
    function mint(address _to, uint256 _amount) external returns (bool);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IURC20.sol";
import "./library/PriceLib.sol";


contract UnicornOracle is Ownable {
    
    using PriceLib for mapping(bytes32=>PriceLib.Price);
    using SafeMath for uint256;
    
    
    address public factory;
    
    mapping(bytes32=>PriceLib.Price) public prices;
    
    event PriceSet(address indexed token0,address indexed token1, uint amount0, uint amount1);
    
    
    function setFactory(address _factory) public onlyOwner {
        
        factory = _factory;
        
    }
    
    function setPrice(address token0,address token1,uint amount0,uint amount1) public onlyOwner {
        
        PriceLib.Price memory price = PriceLib.Price({
            reserve0: amount0,
            reserve1: amount1,
            open: true
        });
        
        prices.setPrice(token0,token1,price);
        
        emit PriceSet(token0,token1,amount0,amount1);
        
    }
    
    function setPriceStatus(address token0,address token1) public onlyOwner {
        
        prices.setStatus(token0,token1);
        
    }
    
    
    function getPrice(uint256 amountIn, address tokenIn, address tokenOut) public view returns(uint256 amountOut) {
        
        uint unitIn = unit(tokenIn);
        
        uint unitOut = prices.getPrice(unitIn,factory,tokenIn,tokenOut);
        
        amountOut = amountIn.mul(unitOut).div(unitIn);
        
    }
    
    
    function getLpPrice(uint amountIn,address pair,address tokenOut) public view returns(uint amountOut) {
        (address[2] memory tokens,uint256[2] memory balances) = PriceLib.getLp(pair,amountIn);
        uint amountOut0 = getPrice(balances[0],tokens[0],tokenOut);
        uint amountOut1 = getPrice(balances[1],tokens[1],tokenOut);
        
        amountOut = amountOut0 + amountOut1;
    }
    
    
    function unit(address token) public view returns(uint) {
        uint _decimals = IURC20(token).decimals();
        return 10**_decimals;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IPancakeFactory.sol";

library PriceLib {

    using SafeMath for uint256;
    
    struct Price {
        uint256 reserve0;
        uint256 reserve1;
        bool open;
    }

    
    function hash(address token0, address token1) internal pure returns (bytes32) {
        
        if(token0>token1) (token0,token1) = (token1,token0);
        
        return keccak256(abi.encode(
            token0,
            token1
        ));
    }
    
    function setPrice(mapping(bytes32=>Price) storage prices, address token0, address token1, Price memory price) internal {
        
        (uint256 reserve0,uint256 reserve1) = (price.reserve0,price.reserve1);
        
        if(token0>token1) (reserve0,reserve1) = (reserve1,reserve0) ;
        
        price.reserve0 = reserve0;
        price.reserve1 = reserve1;
        
        prices[hash(token0,token1)] = price;
    }
    
    function setStatus(mapping(bytes32=>Price) storage prices, address token0, address token1) internal {
        
        bytes32 key = hash(token0,token1);
        
        prices[key].open = !prices[key].open;
    }
    
    
    function getReserve(mapping(bytes32=>Price) storage prices, address _factory, address token0, address token1) internal view returns(uint reserveIn, uint reserveOut) {
        
        Price memory price = prices[hash(token0,token1)];
        
        if(price.open) {
            
            (reserveIn,reserveOut) = (price.reserve0,price.reserve1);
            
            if(token0>token1) (reserveIn,reserveOut) = (reserveOut, reserveIn);
            
        } else {
            
            address _pair = IPancakeFactory(_factory).getPair(token0, token1);
            
            IPancakePair pancakePair = IPancakePair(_pair);
            
            (reserveIn, reserveOut,) = pancakePair.getReserves();

            if(pancakePair.token1()!=address(token1)){
                ( reserveIn,  reserveOut) = (reserveOut, reserveIn);
            }
            
        }
        
    }
        

    function getPrice(mapping(bytes32=>Price) storage prices, uint amountIn, address _factory, address token0, address token1) internal view returns(uint amountOut) { 
        if(token0==token1){
            return amountIn;
        }
        
        ( uint reserveIn, uint reserveOut) = getReserve(prices,_factory,token0,token1);
        
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut); 

    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PankSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PankSwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountOut = amountIn*reserveOut/reserveIn;
    }
    
    function getLp(address _pair,uint256 amount) internal view returns(address[2] memory tokens,uint256[2] memory balances){
        IPancakePair pair = IPancakePair(_pair);
        
        tokens[0] = pair.token0();
        tokens[1] = pair.token1();
        
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        
        balances[0] = amount.mul(reserve0).div(totalSupply);
        balances[1] = amount.mul(reserve1).div(totalSupply);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IPancakeFactory {
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

interface IPancakePair {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./UnicornFee.sol";
import "./WhiteList.sol";

contract UnicornMarket is IERC721Receiver, WhiteList, UnicornFee {
    
    using SafeMath for uint256;

    mapping(address=>mapping(uint=>Auction)) public auctions;

    struct Auction {
        uint price;
        address seller;
        bool status;
    }
    
    event AuctionCreate(address indexed _token,address indexed _seller,uint _tokenId,uint _price);
    event AuctionCancel(address indexed _token,uint _tokenId);
    event AuctionBid(address indexed _token,address indexed _buyer,uint _tokenId);

    constructor(IERC20 _DOM,uint _feeRate,address _feeOwner) UnicornFee(_DOM,_feeRate,_feeOwner) {}


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        require(isWhiteListed[msg.sender],"token is not in whiteList");
        if(Address.isContract(operator)){
            require(isWhiteListed[operator],"not in whiteList");
        }
        uint price = abi.decode(data,(uint));
        createAuction(msg.sender,from,tokenId,price);
        return this.onERC721Received.selector;
    }

    
    function createAuction(address token,address account, uint tokenId,uint price) private {
        require(price>0,"invalid price");
        auctions[token][tokenId] = Auction({
            price: price,
            seller: account,
            status: true
        });
        emit AuctionCreate(token,account,tokenId,price);
    }
    
    function cancelAuction(address token,uint tokenId) public {
        Auction storage auction = auctions[token][tokenId];
        require(auction.status,"invalid auction");
        require(msg.sender==auction.seller,"not good");
        delete auctions[token][tokenId];
        IERC721(token).safeTransferFrom(address(this),msg.sender,tokenId);
        emit AuctionCancel(token,tokenId);
    }
    
    function bid(address token,uint tokenId) public {
        Auction storage auction = auctions[token][tokenId];
        require(auction.status,"invalid auction");

        chargeFee(msg.sender,auction.seller,auction.price);
        
        delete auctions[token][tokenId];
        IERC721(token).safeTransferFrom(address(this),msg.sender,tokenId);
        emit AuctionBid(token,msg.sender,tokenId);
    }
    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract UnicornFee is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 public constant BASE = 100;
    uint256 public feeRate;
    address public feeOwner;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    
    IERC20 public DOM;
    
    constructor(IERC20 _DOM,uint256 _feeRate,address _feeOwner){
        DOM = _DOM;
        feeRate = _feeRate;
        feeOwner = _feeOwner;
    }
    
    function setFeeRate(uint256 _feeRate) public onlyOwner {
        feeRate = _feeRate;
    }
    
    function setFeeOwner(address _feeOwner)  public onlyOwner {
        feeOwner = _feeOwner;
    }
    
    function setChargeType(IERC20 _assetType) public onlyOwner {
        DOM = _assetType;
    }
    
    function chargeFee(address account, uint amount) internal {
        chargeFee(account,DEAD,amount);
    }
    
    function chargeFee(address account, address receipt, uint amount) internal {
        uint fee = amount.mul(feeRate)/BASE;
        DOM.safeTransferFrom(account,feeOwner,fee);
        DOM.safeTransferFrom(account,receipt,amount.sub(fee));
    }
    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract WhiteList is Ownable {

    function getWhiteListStatus(address _maker) external view returns (bool) {
        return isWhiteListed[_maker];
    }

    mapping (address => bool) public isWhiteListed;

    function addWhiteList (address _user) public onlyOwner {
        isWhiteListed[_user] = true;
        emit AddedWhiteList(_user);
    }

    function removeWhiteList (address _clearedUser) public onlyOwner {
        isWhiteListed[_clearedUser] = false;
        emit RemovedWhiteList(_clearedUser);
    }

    event AddedWhiteList(address indexed _user);

    event RemovedWhiteList(address indexed _user);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./library/UnicornLib.sol";
import "./library/MintLib.sol";

contract UnicornToken is ERC721URIStorage,ERC721Enumerable,Ownable {

    using UnicornLib for mapping(uint256=>UnicornLib.Unicorn);
    using MintLib for MintLib.MintData;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _minters;
    
    mapping(uint256=>UnicornLib.Unicorn) public unicorns;
    mapping(uint256=>address) public origins;

    event Mint(address indexed minter, uint tokenId);
    
    constructor(string memory _name, string memory _symbol) ERC721(_name,_symbol){}

    
    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "_addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "_delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs:/";
    }

    function mint(MintLib.MintData memory mintData) external onlyMinter virtual returns(uint tokenId)  {
        
        require(bytes(mintData.tokenURI).length > 0, "uri should be set");
        
        tokenId = mintData.tokenId;
        
        require(tokenId > 0,"not allowed");
        
        require(!unicorns.isExist(tokenId),"tokenId existed");
        
        require(mintData.validate(owner()),"Invalid signature");
    
        unicorns.add(mintData.unicorn,tokenId);
        
        _mint(mintData.owner, tokenId);
        
        _setTokenURI(tokenId, mintData.tokenURI);
        
        origins[tokenId] = mintData.owner;

        emit Mint(msg.sender,tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721,ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721,ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override(ERC721Enumerable,ERC721) {
        super._beforeTokenTransfer(from,to,tokenId);
    }
    
    function getUnicorns(address account, uint skip, uint limit) public view returns(uint256[] memory _tokenIds,UnicornLib.Unicorn[] memory _unicorns) {
        
        _tokenIds = new uint256[](limit);
        _unicorns = new UnicornLib.Unicorn[](limit);
        
        for(uint i;i<limit;i++) {
            uint tokenId = tokenOfOwnerByIndex(account, skip+i );
            _tokenIds[i] = tokenId;
            _unicorns[i] = unicorns[tokenId];
        }
        
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UnicornLib {

    struct Unicorn {
        uint volume;
        uint weight;
        Trait trait;
        Birth birth;
    }
    
    struct Trait {
        uint strength;
        uint stamina;
        uint speed;
    }
    
    struct Birth {
        uint birthTime;
        uint matronId;
        uint generation;
        uint race;
    }

    function add(mapping(uint256=>Unicorn) storage unicorns,Unicorn memory unicorn,uint tokenId) internal {
        require(!isExist(unicorns,tokenId),"existed");
        unicorn.birth.birthTime = block.timestamp;
        unicorns[tokenId] = unicorn;
    }

    function remove(mapping(uint256=>Unicorn) storage unicorns,uint tokenId) internal returns(Unicorn memory unicorn) {
        unicorn = unicorns[tokenId];
        delete unicorns[tokenId];
    }
    
    function isExist(mapping(uint256=>Unicorn) storage unicorns,uint tokenId) internal view returns(bool _exist) {
        _exist = unicorns[tokenId].birth.birthTime>0;
    }
    
    bytes32 constant TRAIT_TYPEHASH = keccak256(
        "Trait(uint strength,uint stamina,uint speed)"
    );
    
    bytes32 constant BIRTH_TYPEHASH = keccak256(
        "Birth(uint birthTime,uint matronId,uint generation,uint race)"
    );
    
     bytes32 constant UNICORN_TYPEHASH = keccak256(
        "Unicorn(uint volume,unit weight,Trait trait,Birth birth)"
    );


    function hash(Trait memory trait) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TRAIT_TYPEHASH,
                trait.strength,
                trait.stamina,
                trait.speed
            )
        );
    }
    
    function hash(Birth memory birth) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                BIRTH_TYPEHASH,
                birth.matronId,
                birth.generation,
                birth.race
            )
        );
    }
    
    function hash(Unicorn memory unicorn) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                UNICORN_TYPEHASH,
                unicorn.volume,
                unicorn.weight,
                hash(unicorn.trait),
                hash(unicorn.birth)
            )
        );
    }
  
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./UnicornLib.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

library MintLib {

    struct MintData {
        uint tokenId;
        address owner;
        string tokenURI;
        UnicornLib.Unicorn unicorn;
        bytes signature;
    }


    bytes32 public constant MINT_TYPEHASH = keccak256("MintData(uint256 tokenId,address owner,string tokenURI,Unicorn unicorn)");

    function hash(MintData memory data) internal pure returns (bytes32) {

        return keccak256(abi.encode(
                MINT_TYPEHASH,
                data.tokenId,
                data.owner,
                keccak256(bytes(data.tokenURI)),
                UnicornLib.hash(data.unicorn)
        ));
    }
    
    function validate(MintData memory mintData, address signer) internal view returns(bool) {
        return SignatureChecker.isValidSignatureNow(signer,hash(mintData),mintData.signature);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        return _owners[tokenId] != address(0);
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UnicornToken.sol";
import "./UnicornFee.sol";
import "./library/BreedLib.sol";
import "./interfaces/IUnicorn.sol";


contract UnicornBreed is UnicornFee {
    
    using BreedLib for BreedLib.Breed[];
    using BreedLib for mapping(uint=>BreedLib.Pregnancy);
    using SafeMath for uint256;
    using UnicornLib for mapping(uint256=>UnicornLib.Unicorn);
    using MintLib for MintLib.MintData;

    BreedLib.Breed[] public breeds;
    
    uint public BOX_PRICE = 200e18;
    
    mapping(uint=>BreedLib.Pregnancy) public pregnancies;

    IUnicorn public UNICORN;

    constructor(IUnicorn _UNICORN, IERC20 _DOM, uint _feeRate, address _feeOwner) UnicornFee(_DOM,_feeRate,_feeOwner) {
        UNICORN = _UNICORN;
    }
    
    event Pregnant(address owner, uint256 matronId);
    event Feed(address owner, uint256 matronId, uint count);
    event GiveBirth(address owner, uint256 tokenId, uint256 matronId);
    
    function addBreed(BreedLib.Breed memory _config) public onlyOwner {
        breeds.push(_config);
    }
    
    function removeBreed() public onlyOwner {
        breeds.pop();
    }
    
    function setBoxPrice(uint price) public onlyOwner {
        BOX_PRICE = price;
    }

    function _isReadyToBreed(uint _tokenId) internal view returns (bool) {
        UnicornLib.Unicorn memory unicorn = UNICORN.unicorns(_tokenId);
        return pregnancies.isReadyToBreed(_tokenId,breeds.getChildLimit(unicorn.birth.generation));
    }
    
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return UNICORN.ownerOf(_tokenId) == _claimant;
    }


    function isReadyToBreed(uint256 _tokenId)
        public
        view
        returns (bool)
    {
        require(_tokenId > 0);
        
        return _isReadyToBreed(_tokenId);
    }

    function breed(uint256 _tokenId) public {

        require(_owns(msg.sender, _tokenId),"caller only allow owner");

        UnicornLib.Unicorn memory unicorn = UNICORN.unicorns(_tokenId);

        require(_isReadyToBreed(_tokenId));
        
        chargeFee(msg.sender,breeds.getFee(unicorn.birth.generation));

        _breed(_tokenId);
    }


    function _breed(uint256 _tokenId) internal {
        
        UnicornLib.Unicorn memory unicorn = UNICORN.unicorns(_tokenId);

        uint cooldown = breeds.getCooldown(unicorn.birth.generation);

        pregnancies.breed(_tokenId,cooldown);
        
        emit Pregnant(UNICORN.ownerOf(_tokenId), _tokenId);
    }
    
    
    function feed(uint256 _tokenId) public {
        
        UnicornLib.Unicorn memory unicorn = UNICORN.unicorns(_tokenId);
        
        (uint feedFee,uint promote) = breeds.getFeed(unicorn.birth.generation,pregnancies[_tokenId].feedCount);
        
        chargeFee(msg.sender, feedFee);
        
        pregnancies.feed(_tokenId,promote);
        
        emit Feed(UNICORN.ownerOf(_tokenId),_tokenId,pregnancies[_tokenId].feedCount);
    }
    
    function giveBirth(MintLib.MintData memory mintData) public {
        
        UnicornLib.Birth memory birth = mintData.unicorn.birth;
        
        require(_owns(msg.sender, birth.matronId),"caller only allow owner");

        pregnancies.giveBirth(birth.matronId);
        
        UNICORN.mint(mintData);
        
        emit GiveBirth(mintData.owner, mintData.tokenId, birth.matronId);
        
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library BreedLib {
    
    using SafeMath for uint256;
    
    struct Breed {
        uint cooldown;
        uint fee;
        uint chlidLimit;
        uint feedFee;
        uint promote;
    }
    
    struct Pregnancy {
        uint edd;
        uint feedCount;
        uint chirdren;
    }
    
    //0.[1296000,120000000000000000000,3,10000000000000000000,259200]
    //1.[1296000,100000000000000000000,3,80000000000000000000,259200]
    //2.[1296000,80000000000000000000,3,60000000000000000000,259200]
    //3.[0,0,0,0,0]
    function getCooldown(Breed[] storage breeds,uint generation) internal view returns(uint) {
        return breeds[generation].cooldown;
    }
    
    function getFee(Breed[] storage breeds,uint generation) internal view returns(uint) {
        return breeds[generation].fee;
    }
    
    function getChildLimit(Breed[] storage breeds,uint generation) internal view returns(uint) {
        return breeds[generation].chlidLimit;
    }
    
    function getFeed(Breed[] storage breeds,uint generation,uint count) internal view returns(uint feedFee, uint promote) {
        uint baseFeedFee = breeds[generation].feedFee;
        feedFee = (2**count).mul(baseFeedFee);
        promote =  breeds[generation].promote;
    }
    
    function isReadyToBreed(mapping(uint256=>Pregnancy) storage pregancies,uint tokenId,uint chlidLimit) internal view returns(bool _ready) {
        Pregnancy memory pregnancy = pregancies[tokenId];
         _ready = (pregnancy.edd == 0) && (pregnancy.chirdren < chlidLimit);
    }
    
    function isReadyToGiveBirth(mapping(uint256=>Pregnancy) storage pregancies,uint tokenId) internal view returns(bool _ready){
        Pregnancy memory pregnancy = pregancies[tokenId];
        _ready = (pregnancy.edd > 0) && (pregnancy.edd < block.timestamp);
    }
    
    function breed(mapping(uint256=>Pregnancy) storage pregancies,uint tokenId,uint cooldown) internal {
        Pregnancy storage pregnancy = pregancies[tokenId];
        require(pregnancy.edd == 0 ,"during pregnancy");
        pregnancy.chirdren++;
        pregnancy.edd = block.timestamp.add(cooldown);
    }
    
    function feed(mapping(uint256=>Pregnancy) storage pregancies,uint256 tokenId,uint256 promote) internal {
        Pregnancy storage pregnancy = pregancies[tokenId];
        require(pregnancy.edd > block.timestamp, "feed over");
        pregnancy.edd = pregnancy.edd.sub(promote);
        require(pregnancy.edd>0,"not allow feed");
        pregnancy.feedCount++;
    }
    
    function giveBirth(mapping(uint256=>Pregnancy) storage pregancies,uint tokenId) internal {
        
        require(isReadyToGiveBirth(pregancies,tokenId),"isn't Ready");
        
        Pregnancy storage pregnancy = pregancies[tokenId];
        
        pregnancy.feedCount = 0;
        
        pregnancy.edd = 0;
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../library/MintLib.sol";
import "../library/UnicornLib.sol";


interface IUnicorn is IERC721 {
    
    function mint(MintLib.MintData memory mintData) external returns(uint tokenId);
    
    function unicorns(uint tokenId) external view returns(UnicornLib.Unicorn memory unicorn);
    
    function origins(uint tokenId) external view returns(address origin);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UnicornToken.sol";
import "./UnicornFee.sol";
import "./interfaces/IUnicorn.sol";


contract UnicornBox is UnicornFee {
    
    using SafeMath for uint256;
    using MintLib for MintLib.MintData;

    uint public BOX_PRICE = 200e18;
    
    IUnicorn public UNICORN;

    constructor(IUnicorn _UNICORN, IERC20 _DOM, uint _feeRate, address _feeOwner) UnicornFee(_DOM,_feeRate,_feeOwner) {
        UNICORN = _UNICORN;
    }
    
    event Blindbox(address owner, uint256 tokenId);
    
    function blindbox(MintLib.MintData memory mintData) public {
        
        UnicornLib.Birth memory birth = mintData.unicorn.birth;
        
        require(birth.matronId == 0,"blindbox: error matronId");
        
        chargeFee(msg.sender, BOX_PRICE);
        
        UNICORN.mint(mintData);
        
        emit Blindbox(mintData.owner, mintData.tokenId);
    
    }
    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IOracle.sol";
import "../interfaces/IUnicorn.sol";
import "../interfaces/IFarm.sol";
import "../interfaces/IURC20.sol";

import "../library/PoolLib.sol";
import "../library/PawnLib.sol";

contract UnicornFarm is Ownable,IERC721Receiver {
    
    using PoolLib for PoolLib.Pool[];
    
    using PawnLib for mapping(address=>PawnLib.Pawn[]);
    
    using SafeMath for uint256;
    
    using SafeERC20 for IURC20;
    
    IUnicorn public unicorn;
    
    IURC20 public mac;
    
    IURC20 public usdt;
    
    IFarm public farm;
    
    IOracle public oracle;
    
    PoolLib.Pool[] public pools;
    
    uint public mintShare = 15;
    
    address public dead = 0x000000000000000000000000000000000000dEaD;
    
    address public feeOwner;
    
    mapping(address=>mapping(uint=>uint[][])) public groups;
    
    mapping(uint=>uint) public amplifier;
    
    mapping(address=>PawnLib.Pawn[]) public pawns;
    
    mapping(uint=>PawnLib.Slot) public slots;
    
    constructor(IUnicorn _unicorn,IURC20 _mac,IURC20 _usdt,IFarm _farm,IOracle _oracle,address _feeOwner) {
        unicorn = _unicorn;
        mac = _mac;
        usdt = _usdt;
        farm = _farm;
        oracle = _oracle;
        feeOwner = _feeOwner;
    }
    
    function findGroup(address account,uint race) public view returns(uint groupId,bool create) {
        groupId = groups[account][race].length;
        create = true;
        while(groupId>0) {
            if(groups[account][race][--groupId].length<5){
                create = false;
                break;
            }
        }
    }
    
    function addGroup(address account,uint race,uint tokenId) internal returns(uint) {
        (uint groupId,bool create) = findGroup(account,race);
        
        if(create) {
            groupId = groups[account][race].length;
            groups[account][race].push();
            
        }
        
        groups[account][race][groupId].push(tokenId);
        
        return groupId;
    }
    
    function removeGroup(address account,uint race,uint groupId,uint tokenId) internal {
        uint len = groups[account][race][groupId].length;
        for(uint i;i<len;i++) {
            if(groups[account][race][groupId][i] == tokenId){
                if(i!=len - 1){
                    groups[account][race][groupId][i] = groups[account][race][groupId][len - 1];
                }
                groups[account][race][groupId].pop();
                break;
            }
        }
    }
    
    function mintGroup(address account,uint race,uint groupId) internal {
        
        if(groups[account][race][groupId].length==5) {
            for(uint i;i<5;i++) {
                
                uint tokenId = groups[account][race][groupId][i];
                
                PawnLib.Pawn storage pawn = pawns.get(account,tokenId,slots);
                
                uint hashMint = pawn.hashRate.mul(amplifier[race])/100;
                
                pawn.hashRate = pawn.hashRate.add(hashMint);
                
                farm.mint(account, hashMint, tokenId);
            }
        }
    }
    
     function burnGroup(address account,uint race,uint groupId) internal {
        
        if(groups[account][race][groupId].length==4) {
            for(uint i;i<4;i++) {
                
                uint tokenId = groups[account][race][groupId][i];
                
                PawnLib.Pawn storage pawn = pawns.get(account,tokenId,slots);
                
                uint hashBurn = pawn.hashRate.mul(amplifier[race])/(100+amplifier[race]);
                
                farm.burn(account, hashBurn, tokenId);
                
            }
        }
    }
    
    function addPool(PoolLib.Pool memory pool) external onlyOwner {
        pools.add(pool);
    }
    
    function setPool(uint pid,uint burn,uint fee,uint weight) external onlyOwner {
        pools.set(pid,burn,fee,weight);
    }
    
    function setAmplifier(uint race,uint boost) external onlyOwner {
        amplifier[race] = boost;
    }
    
    function setMintShare(uint _mintShare) external onlyOwner {
        mintShare = _mintShare;
    }
    
    function setOracle(IOracle _oracle) external onlyOwner {
        oracle = _oracle;
    }
    
    function onERC721Received(
        address ,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        
        require(address(unicorn) == msg.sender,"error 721 token");
       
        (uint amount,uint pid) = abi.decode(data,(uint,uint));
        
        stake(tokenId,amount, pid, from);
        
        return this.onERC721Received.selector;
    }
    
    function stake(uint tokenId,uint amount,uint pid,address account) internal {
        
        PoolLib.Pool memory pool = pools[pid];
        
        UnicornLib.Unicorn memory _unicorn = unicorn.unicorns(tokenId);
        
        uint groupId = addGroup(account,_unicorn.birth.race,tokenId);
        
        uint _hash = hash(tokenId,amount,pid);
        
        pool.token.safeTransferFrom(account,address(this),amount);
        
        pawns.add(account,PawnLib.Pawn({
            tokenId: tokenId,
            amount: amount,
            hashRate: _hash,
            groupId: groupId,
            pid: pid
        }),slots);
        
        mintGroup(account,_unicorn.birth.race,groupId);
        
        farm.mint(account,_hash,tokenId);
       
    }
    
    function unstake(uint tokenId) public {
        
        withdraw(tokenId);
        
        (uint slotId,bool active) = (slots[tokenId].slotId, slots[tokenId].active);
        
        require(active,"null slotId");
        
        PawnLib.Pawn memory pawn = pawns.remove(slotId, msg.sender, slots);
        
        require(tokenId == pawn.tokenId, "error tokenId");
        
        PoolLib.Pool memory pool = pools[pawn.pid];
        
        unicorn.safeTransferFrom(address(this),msg.sender,pawn.tokenId);
        
        uint fee = chargeFee(pawn.amount,pawn.pid);
        
        pool.token.safeTransfer(msg.sender,pawn.amount.sub(fee));
        
        UnicornLib.Unicorn memory _unicorn = unicorn.unicorns(pawn.tokenId);
        
        removeGroup(msg.sender,_unicorn.birth.race,pawn.groupId,pawn.tokenId);
        
        burnGroup(msg.sender,_unicorn.birth.race,pawn.groupId);
        
        farm.burn(msg.sender, pawn.hashRate, pawn.tokenId);
    }
    
    function withdraw(uint tokenId) public {
        
        (uint slotId,bool active) = (slots[tokenId].slotId, slots[tokenId].active);
        
        require(active,"null slotId");
        
        PawnLib.Pawn memory pawn = pawns[msg.sender][slotId];
        
        require(tokenId == pawn.tokenId, "error tokenId");
        
        farm.withdraw(msg.sender,pawn.tokenId);
        
        uint reward = mac.balanceOf(address(this));
        
        address minter = unicorn.origins(pawn.tokenId);
        
        uint mintReward = reward.mul(mintShare)/100;
        
        safeMacTransfer(minter,mintReward);
        
        safeMacTransfer(msg.sender,reward.sub(mintReward));
    }
    
    function withdrawAll() public {
        for(uint i;i<getPawnsLength(msg.sender);i++) {
            PawnLib.Pawn memory pawn = pawns[msg.sender][i];
            withdraw(pawn.tokenId);
        }
        
    }
    
    function earn(address account) public view returns(uint reward) {
        for(uint i;i<getPawnsLength(account);i++) {
            PawnLib.Pawn memory pawn = pawns[account][i];
            reward += farm.earned(account,address(this),pawn.tokenId);
        }
        
    }
    
    function chargeFee(uint amount,uint pid) internal returns(uint) {
        PoolLib.Pool memory pool = pools[pid];
        
        uint burn = amount.mul(pool.burn)/100;
        uint fee = amount.mul(pool.fee)/100;
        
        if(burn>0) pool.token.safeTransfer(dead,burn);
        if(fee>0) pool.token.safeTransfer(feeOwner,burn);
        
        return burn.add(fee);
    }
    
    function safeMacTransfer(address _to, uint256 _amount) internal {
        uint256 macBal = mac.balanceOf(address(this));
        if (_amount > macBal) {
            mac.safeTransfer(_to, macBal);
        } else {
            mac.safeTransfer(_to, _amount);
        }
    }
    
    function hash(uint tokenId,uint amount,uint pid) public view returns(uint _hash) {
        UnicornLib.Unicorn memory _unicorn = unicorn.unicorns(tokenId);
        PoolLib.Pool memory pool = pools[pid];
        
        
        uint decimals = pool.token.decimals();
        uint base = 10**decimals;
        require(amount<=_unicorn.volume.mul(base),"to big");
        
        uint price = oracle.getPrice(amount, address(pool.token), address(usdt));
        _hash = _unicorn.weight.mul(pool.weight).mul(price)/10000;
    }
    
    function getPawnsLength(address account) public view returns(uint) {
        return pawns[account].length;
    }
    
    function getPawns(address account) public view returns(PawnLib.Pawn[] memory _pawns) {
        _pawns = pawns[account];
    }
    
    function poolLength() public view returns(uint) {
        return pools.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    
     function getPrice(uint256 amountIn, address tokenIn, address tokenOut) external view returns(uint256 amountOut);
     
     function getLpPrice(uint amountIn,address pair,address tokenOut) external view returns(uint256 amountOut);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarm {
    
    function mint(address account, uint256 _amount, uint256 salt) external;
    
    function burn(address account, uint256 _amount, uint256 salt) external;
    
    function withdraw(address account,uint256 salt) external returns(uint reward);
    
    function earned(address user,address farm,uint salt) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IURC20.sol";


library PoolLib {
    
    struct Pool {
        IURC20 token;
        uint burn;
        uint fee;
        uint weight;
        uint total;
    }
    
    
    function add(Pool[] storage pools,Pool memory pool) internal returns(uint pid) {
        require(address(pool.token)!=address(0),"not allowed");
        pid = pools.length;
        pool.total = 0;
        pools.push(pool);
    }
    
    function set(Pool[] storage pools,uint pid, uint burn,uint fee,uint weight) internal {
        pools[pid].burn = burn;
        pools[pid].weight = weight;
        pools[pid].fee = fee;
    }
    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PawnLib {
    
    struct Pawn {
        uint tokenId;
        uint amount;
        uint hashRate;
        uint groupId;
        uint pid;
    }
    
    struct Slot {
        uint slotId;
        bool active;
    }
    
    function get(mapping(address=>Pawn[]) storage pawns,address account,uint tokenId,mapping(uint=>PawnLib.Slot) storage slots) internal view returns(Pawn storage pawn) {
        (uint slotId,bool active) = (slots[tokenId].slotId, slots[tokenId].active);
        require(active,"null slotId");
        pawn = pawns[account][slotId];
    }
    
    function add(mapping(address=>Pawn[]) storage pawns,address account,Pawn memory pawn,mapping(uint=>PawnLib.Slot) storage slots) internal returns(uint slotId) {
        slotId = pawns[account].length;
        pawns[account].push(pawn);
        
        slots[pawn.tokenId] = Slot({
            slotId: slotId,
            active: true
        });
    }
    
    function remove(mapping(address=>Pawn[]) storage pawns,uint slotId,address account,mapping(uint=>PawnLib.Slot) storage slots) internal returns(Pawn memory pawn) {
        
        uint lastIndex = pawns[account].length - 1;
        
        pawn = pawns[account][slotId];
        
        if(slotId != lastIndex) {
            
            Pawn memory lastPawn = pawns[account][lastIndex];
            
            pawns[account][slotId] = lastPawn;
            
            slots[lastPawn.tokenId] = Slot({
                slotId: slotId,
                active: true
            });
            
        }
        
        pawns[account].pop();
        
        delete slots[pawn.tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IOracle.sol";
import "../interfaces/IUnicorn.sol";
import "../interfaces/IFarm.sol";

import "../library/PoolLib.sol";
import "../library/LpPawnLib.sol";

contract LpFarm  is Ownable{
    
    using PoolLib for PoolLib.Pool[];
    
    using LpPawnLib for mapping(uint=>mapping(address=>LpPawnLib.Pawn));
    
    using SafeERC20 for IURC20;
    
    using SafeMath for uint256;
    
    PoolLib.Pool[] public pools;
    
    IFarm public farm;
    
    IURC20 public mac;
    
    IURC20 public usdt;
    
    IOracle public oracle;
    
    address public dead = 0x000000000000000000000000000000000000dEaD;
    
    address public feeOwner;
    
    mapping(uint=>mapping(address=>LpPawnLib.Pawn)) public pawns;
    
    constructor(IURC20 _mac,IURC20 _usdt,IFarm _farm,IOracle _oracle,address _feeOwner) {
        mac = _mac;
        usdt = _usdt;
        farm = _farm;
        oracle = _oracle;
        feeOwner = _feeOwner;
    }

    function addPool(PoolLib.Pool memory pool) external onlyOwner {
        pools.add(pool);
    }
    
    function setPool(uint pid,uint burn,uint fee,uint weight) external onlyOwner {
        pools.set(pid,burn,fee,weight);
    }
    
    
    
    function stake(uint amount,uint pid) external {
        
        PoolLib.Pool memory pool = pools[pid];
        
        uint _hash = hash(amount,pid);
        
        pool.token.safeTransferFrom(msg.sender,address(this),amount);
        
        pawns.add(pid,msg.sender,LpPawnLib.Pawn({
            amount: amount,
            hashRate: _hash
        }));
        
        farm.mint(msg.sender,_hash,pid);
       
    }
    
    function unstake(uint pid) public {
        
        LpPawnLib.Pawn memory pawn = pawns.remove(pid,msg.sender);
        
        PoolLib.Pool memory pool = pools[pid];
        
        uint fee = chargeFee(pawn.amount,pid);
        
        pool.token.safeTransfer(msg.sender, pawn.amount.sub(fee));
        
        withdraw(pid);
        
        farm.burn(msg.sender,pawn.hashRate, pid);
    }
    
    function withdraw(uint pid) public {
        uint reward = farm.withdraw(msg.sender,pid);
        mac.safeTransfer(msg.sender,reward);
    }
    
    function chargeFee(uint amount,uint pid) internal returns(uint) {
        PoolLib.Pool memory pool = pools[pid];
        
        uint burn = amount.mul(pool.burn)/100;
        uint fee = amount.mul(pool.fee)/100;
        
        if(burn>0) pool.token.safeTransfer(dead,burn);
        if(fee>0) pool.token.safeTransfer(feeOwner,burn);
        
        return burn.add(fee);
    }
    
    function hash(uint amount,uint pid) public view returns(uint _hash) {
        PoolLib.Pool memory pool = pools[pid];
        
        uint price = oracle.getLpPrice(amount, address(pool.token), address(usdt));
        _hash = pool.weight.mul(price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LpPawnLib {
    
    using SafeMath for uint256;
    
    struct Pawn {
        uint amount;
        uint hashRate;
    }
    
    function add(mapping(uint=>mapping(address=>Pawn)) storage pawns,uint pid,address account,Pawn memory pawn) internal {
        pawns[pid][account].amount = pawns[pid][account].amount.add(pawn.amount);
        pawns[pid][account].hashRate = pawns[pid][account].hashRate.add(pawn.hashRate);

    }
    
    function remove(mapping(uint=>mapping(address=>Pawn)) storage pawns,uint pid,address account) internal returns(Pawn memory pawn) {
        pawn = pawns[pid][account];
        delete pawns[pid][account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IOracle.sol";
import "../interfaces/IUnicorn.sol";
import "../interfaces/IFarm.sol";

import "../library/PairLib.sol";
import "../library/RandomPawnLib.sol";

contract RandomFarm  is Ownable{
    
    using PairLib for PairLib.Pool[];
    
    using RandomPawnLib for mapping(uint=>mapping(address=>RandomPawnLib.Pawn));
    
    using SafeERC20 for IURC20;
    
    using SafeMath for uint256;
    
    PairLib.Pool[] public pools;
    
    IFarm public farm;
    
    IURC20 public mac;
    
    IURC20 public usdt;
    
    IOracle public oracle;
    
    address public dead = 0x000000000000000000000000000000000000dEaD;
    
    address public feeOwner;
    
    mapping(uint=>mapping(address=>RandomPawnLib.Pawn)) public pawns;
    
    constructor(IURC20 _mac,IURC20 _usdt,IFarm _farm,IOracle _oracle,address _feeOwner) {
        mac = _mac;
        usdt = _usdt;
        farm = _farm;
        oracle = _oracle;
        feeOwner = _feeOwner;
    }

    function addPool(PairLib.Pool memory pool) external onlyOwner {
        pools.add(pool);
    }
    
    function setPool(uint pid,uint burn,uint fee,uint weight) external onlyOwner {
        pools.set(pid,burn,fee,weight);
    }
    
    
    
    function stake(uint amount,uint pid) external {
        
        PairLib.Pool memory pool = pools[pid];
        
        uint _hash = hash(amount,pid);
        
        pool.token0.safeTransferFrom(msg.sender,address(this),amount);
        
        pool.token1.safeTransferFrom(msg.sender,address(this),amount);
        
        pawns.add(pid,msg.sender,RandomPawnLib.Pawn({
            amount0: amount,
            amount1: amount,
            hashRate: _hash,
            block: block.number,
            soft: pool.soft
        }));
        
        farm.mint(msg.sender,_hash,pid);
       
    }
    
    function unstake(uint pid) public {
        
        RandomPawnLib.Pawn memory pawn = pawns.remove(pid,msg.sender);
        
        PairLib.Pool memory pool = pools[pid];
        
        //uint fee = chargeFee(pawn.amount,pid);
        
        pool.token0.safeTransfer(msg.sender, pawn.amount0);
        pool.token1.safeTransfer(msg.sender, pawn.amount1);
        
        withdraw(pid);
        
        farm.burn(msg.sender,pawn.hashRate, pid);
    }
    
    function withdraw(uint pid) public {
        uint reward = farm.withdraw(msg.sender,pid);
        mac.safeTransfer(msg.sender,reward);
    }
    
    // function chargeFee(uint amount,uint pid) internal returns(uint) {
    //     PairLib.Pool memory pool = pools[pid];
        
    //     uint burn = amount.mul(pool.burn)/100;
    //     uint fee = amount.mul(pool.fee)/100;
        
    //     if(burn>0) pool.token.safeTransfer(dead,burn);
    //     if(fee>0) pool.token.safeTransfer(feeOwner,burn);
        
    //     return burn.add(fee);
    // }
    
    function hash(uint amount,uint pid) public view returns(uint _hash) {
        PairLib.Pool memory pool = pools[pid];
        
        uint price0 = oracle.getPrice(amount, address(pool.token0), address(usdt));
        uint price1 = oracle.getPrice(amount, address(pool.token1), address(usdt));
        _hash = pool.weight.mul(price0.add(price1));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IURC20.sol";


library PairLib {
    
    struct Pool {
        IURC20 token0;
        IURC20 token1;
        uint burn;
        uint fee;
        uint weight;
        uint total;
        bool soft;
    }
    
    
    function add(Pool[] storage pools,Pool memory pool) internal returns(uint pid) {
        require(address(pool.token0)!=address(0),"not allowed");
        pid = pools.length;
        pool.total = 0;
        pools.push(pool);
    }
    
    function set(Pool[] storage pools,uint burn,uint fee,uint weight,uint pid) internal {
        pools[pid].burn = burn;
        pools[pid].weight = weight;
        pools[pid].fee = fee;
    }
    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library RandomPawnLib {
    
    using SafeMath for uint256;
    
    struct Pawn {
        uint amount0;
        uint amount1;
        uint hashRate;
        uint block;
        bool soft;
    }
    
    function add(mapping(uint=>mapping(address=>Pawn)) storage pawns,uint pid,address account,Pawn memory pawn) internal {
        require(pawns[pid][account].hashRate == 0,"locked");
        pawns[pid][account] = pawn;

    }
    
    function remove(mapping(uint=>mapping(address=>Pawn)) storage pawns,uint pid,address account) internal returns(Pawn memory pawn) {
        pawn = pawns[pid][account];
        delete pawns[pid][account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./UnicornFee.sol";

import "./interfaces/IUnicorn.sol";

import "./library/AuctionLib.sol";

contract UnicronAuction is UnicornFee {
    
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using AuctionLib for AuctionLib.Auction[];

    constructor(IUnicorn _unicorn, IERC20 _DOM,uint _feeRate,address _feeOwner) UnicornFee(_DOM,_feeRate,_feeOwner) {
        unicorn = _unicorn;
    }
    
    uint public BURN_RATE = 70;
    
    IUnicorn public unicorn;
    
    AuctionLib.Auction[] public auctions;
    
    AuctionLib.Bid[] public bids;
    
    mapping(uint=>uint) public auctionIndex;
    
    mapping(uint=>mapping(address=>uint[])) public bidRecords;

    event AuctionCreate(uint indexed _tokenId,uint _price, uint tokenId);
    event AuctionBid(address indexed _buyer,uint bidPrice, uint tokenId);
    event AuctionFinish(address indexed _buyer,uint _tokenId, uint tokenId);
    event Redeem(address indexed _buyer, uint tokenId);
    event RedeemBid(address indexed _buyer, uint _bidId, uint reward, uint amount);
    
    
    function createAuction(uint tokenId, uint startBlock, uint duration, uint price) public onlyOwner {
        
        UnicornLib.Unicorn memory _unicorn = unicorn.unicorns(tokenId);
        
        require(_unicorn.birth.birthTime == 0,"tokenId existed");
        
        require(price>0,"invalid price");
        
        uint endBlock = startBlock.add(duration);
        
        require(endBlock>startBlock,"invalid block number");
        
        uint auctionId = auctions.add(bids,price,tokenId,startBlock,endBlock);
        
        auctionIndex[tokenId] = auctionId;
        
        emit AuctionCreate(tokenId, price, tokenId);
    }
    
    function setAuction(uint tokenId, uint startBlock, uint duration ) public onlyOwner {
        
        uint endBlock = startBlock.add(duration);
        
        require(endBlock>startBlock,"invalid block number");
        
        uint auctionId = auctionIndex[tokenId];
        
        auctions.set(auctionId,startBlock,endBlock);
    }
    
    function bid(uint tokenId, uint bidPrice) public {
        
        uint auctionId = auctionIndex[tokenId];

        DOM.safeTransferFrom(msg.sender,address(this),bidPrice);
        
        uint bidId = auctions.bid(bids,auctionId,bidPrice);
        
        bidRecords[auctionId][msg.sender].push(bidId);

        emit AuctionBid(msg.sender, bidPrice, tokenId);
    }
    
    function redeemBid(uint bidId) public {
        
        (uint reward,address owner,uint amount) = auctions.claim(bids,bidId);
        
        chargeFee(owner,amount);
        
        reward = reward.mul(100-BURN_RATE)/100;
        
        DOM.safeTransfer(owner,reward);
        
        emit RedeemBid(owner, bidId, reward, amount);
        
    }
    
    function redeem(uint tokenId) public {
        
        uint auctionId = auctionIndex[tokenId];
        
        uint[] memory bidIds = bidRecords[auctionId][msg.sender];
        
        for(uint i;i<bidIds.length;i++) {
            if(!bids[bidIds[i]].claimed) {
                redeemBid(bidIds[i]);
            }
        }
        
        emit Redeem(msg.sender, tokenId);
    }
    
    function finishAuction(MintLib.MintData memory mintData) public {
        
        uint auctionId = auctionIndex[mintData.tokenId];
        
        (address owner, uint tokenId, uint amount) = auctions.claimAuction(bids, auctionId);
        
        require(owner==mintData.owner,"error owner");
        
        unicorn.mint(mintData);
        
        uint burnAmount = amount.mul(BURN_RATE)/100;
        
        DOM.safeTransfer(DEAD, burnAmount);
        
        emit AuctionFinish(owner, tokenId, tokenId);
    }
    
    function auctionLength() public view returns(uint) {
        return auctions.length;
    }
    
    
    function getAuctions() public view returns(AuctionLib.Auction[] memory _auctions, AuctionLib.Bid[] memory _bids) {
        
        uint auctionSize = auctionLength();
        
        _bids = new AuctionLib.Bid[](auctionSize);
        
        _auctions = auctions;
        
        for(uint i; i < auctionSize; i++) {
            _bids[i] = bids[_auctions[i].bidId];
        }
    }
    
    function getBids(uint tokenId, address account) public view returns(AuctionLib.Bid[] memory _bids,uint[] memory bidIds) {
        
        uint auctionId = auctionIndex[tokenId];
        
        bidIds = bidRecords[auctionId][account];
        
        _bids = new AuctionLib.Bid[](bidIds.length);
        
        for(uint i;i<bidIds.length;i++) {
            _bids[i] = bids[bidIds[i]];
        }
    }
    
    function getFinishBid(uint tokenId) public view returns(address owner) {
        
        uint auctionId = auctionIndex[tokenId];
        
        AuctionLib.Auction memory auction = auctions[auctionId];
        
        if(auction.endBlock < block.number) {
            
            owner = bids[auction.bidId].bider;
            
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AuctionLib {
    
    using SafeMath for uint256;
    
    
    struct Auction {
        uint tokenId;
        uint total;
        uint bidId;
        uint startBlock;
        uint endBlock;
        bool claimed;
    }
    
    struct Bid {
        uint auctionId;
        uint amount;
        bool claimed;
        address bider;
    }
    
    uint constant BID_INCR = 5;
    uint constant BID_BASE = 100;
    uint constant HALF_HOURS = 600;
    
    function add(Auction[] storage auctions, Bid[] storage bids, uint amount, uint tokenId, uint startBlock, uint endBlock) internal returns(uint auctionId) {
        
        auctionId = auctions.length;
        
        Auction memory auction = Auction({
            tokenId: tokenId,
            total: 0,
            bidId: bids.length,
            startBlock: startBlock,
            endBlock: endBlock,
            claimed: false
        });
        
        auctions.push(auction);
        
        bids.push(Bid({
            auctionId: auctionId,
            amount: amount,
            claimed: true,
            bider: address(0)
        }));
    }
    
    function set(Auction[] storage auctions, uint auctionId, uint startBlock, uint endBlock) internal {
        Auction storage auction = auctions[auctionId];
        auction.startBlock = startBlock;
        auction.endBlock = endBlock;
    }
    
    function check(Auction[] storage auctions, uint auctionId) internal view returns(bool) {
        Auction memory auction = auctions[auctionId];
        return auction.startBlock<block.number && auction.endBlock>block.number;
    }
    
    function bid(Auction[] storage auctions, Bid[] storage bids, uint auctionId, uint amount ) internal returns(uint bidId) {
        
        require(check(auctions,auctionId),"not in activity");
        
        Auction storage auction = auctions[auctionId];
        
        Bid memory lastBid = bids[auction.bidId];
        
        uint curBid = lastBid.amount.mul(BID_BASE+BID_INCR)/BID_BASE;
        
        require(amount>=curBid,"bid is too low");
        
        bidId = bids.length;
        
        bids.push(Bid({
            auctionId: auctionId,
            amount: amount,
            claimed: false,
            bider: msg.sender
        }));
        
        uint endBlock = block.number.add(HALF_HOURS);
        
        if(endBlock>auction.endBlock) {
            auction.endBlock = endBlock;
        }
        
        auction.bidId = bidId;
        auction.total = auction.total.add(amount);
    }
    
    function claim(Auction[] storage auctions, Bid[] storage bids, uint bidId) internal returns(uint reward, address owner, uint amount) {
        
        Bid storage _bid = bids[bidId];
        
        require(!_bid.claimed,"claimed");
        
        Auction memory auction = auctions[_bid.auctionId];
        
        require(auction.endBlock<block.number,"not ended");
        
        Bid memory lastBid = bids[auction.bidId];
        
        _bid.claimed = true;
        
        reward = lastBid.amount.mul(_bid.amount).div(auction.total);
        
        owner = _bid.bider;
        
        if(auction.bidId != bidId) amount = _bid.amount;
        
    }
    
    function claimAuction(Auction[] storage auctions,Bid[] storage bids, uint auctionId ) internal returns(address owner, uint tokenId, uint amount) {
        
        Auction storage auction = auctions[auctionId];
        
        require(auction.endBlock<block.number,"not ended");
        
        require(!auction.claimed,"auction claimed");
        
        auction.claimed = true;
        
        Bid storage lastBid = bids[auction.bidId];
        
        lastBid.claimed = true;
        
        owner = lastBid.bider;
        
        tokenId = auction.tokenId;
        
        amount = lastBid.amount;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../WhiteList.sol";

contract MAC is ERC20, WhiteList  {
    
    uint256 private constant preMineSupply = 700 * 1e18;
    uint256 private constant maxSupply = 30000 * 1e18;     // the total supply

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    EnumerableSet.AddressSet private _minters;
    
    uint256 public _taxFee = 3;
    
    uint256 public _liquidityFee = 3;
    
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public LIQUIDITY;
    

    constructor(address _LIQUIDITY) ERC20("Metacore", "MAC"){
        LIQUIDITY = _LIQUIDITY;
        _mint(msg.sender, preMineSupply);
    }

    function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
        if (_amount.add(totalSupply()) > maxSupply) {
            return false;
        }
        _mint(_to, _amount);
        return true;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    
    function setLiquidity(address liquidity) external onlyOwner {
        LIQUIDITY = liquidity;
    }

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "MdxToken: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "MdxToken: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "MdxToken: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {

        uint taxFeeAmount;
        uint liquidityFeeAmount;
        
        if(!isWhiteListed[sender]&&!isWhiteListed[recipient]){
            taxFeeAmount = amount.mul(_taxFee)/100;
            liquidityFeeAmount = amount.mul(_liquidityFee)/100;
        }
        
        amount = amount.sub(taxFeeAmount).sub(liquidityFeeAmount);
        super._transfer(sender,recipient,amount);
        
        if(taxFeeAmount>0) {
            super._transfer(sender,DEAD,taxFeeAmount);
        }
        
        if(liquidityFeeAmount>0) {
            super._transfer(sender,LIQUIDITY,liquidityFeeAmount);
        }
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DOM is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_,symbol_) {
        super._mint(msg.sender,10000000000000000000000000000);
    }
}