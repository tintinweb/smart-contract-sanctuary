/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-01
*/

/** *Submitted for verification at BscScan.com on 2021-06-01
 * 
                              BUY BACK TOKEN(BBT)
                          ..',;::::::::::::::::::;,'..                          
                     ..,;:::,'....            ....,;:::;,..                     
                  .,:c:,..                            .',:c:'.                  
               .,:c;..                                    .';c:,.               
             ':c;..                                          ..;c:.             
          .'cc,.                    ..''''..                    .,c:'           
         'cc'.                   .':loc;;col:'.                   .,c:.         
       .:c,.                 ..,cc:,,lc;;cc,,:cc,..                 .;c;.       
      'c:.                .';cc;'.  .cc;;c:.  .';cc:'.                .:c'      
    .;l;.             ..,:l:,.      .:c;;c:.      .,:lc,..             .;l,     
   .;l'            .';cc;'.         .:c;;c:.         .';cc;'.            ,l;.   
  .;l'           .;cc,..            .:c;;c:.            ..,cc;.           ,l;   
  ;l,           .cl,.               .:c;;c:.               .,lc.           ,l,  
 'l;           .:l,                 .:c;;c:.                 ,l:.          .:l. 
.:c.           .cc.                 .:c;;c:.                 .lc.           .c:.
,l,            .:l'                 .cc;,c:.                 'l:.            ;l'
:c.             .cc'              ..:l:,':l;..              'cc.             .l;
l:.              .:l:'.        .':cc;..  ..;cc:'.        .':l:.              .:c
l;                 .,:c:,.    .::,.          .'::.    .,:c:,.                 ;l
l,                    .';cc;'.                    .';cc;'.                    ;l
l,                  ...  ..,:c:'.              .,:c:,..  ...                  ;l
l;                .;cc;.     .';cc,..      ..;cc;'.     .,cc;.               .:c
c:.              ,l:..          ..,cc;'..':c:,..           ':l,              .c:
;l'             ,l;.                'cc;;cc.                .;l,             'l,
.c;.           .cc.                 .:c;;c;                  .l:.           .:c.
 ,l'           .cc.                 .:c;;c;                  .l:.           'l, 
 .:c.           ,l;.                .:c;;c;                 .;l,           .c:. 
  .c:.           ,c:'.              .:c,;c;               .':c,           .:c.  
   .c:.           .,cc;'.           .:c,,c;            .';cc,.           .:c.   
    .c:.             .,:c:,.        .:c;,c;         .,:c:,.             .:c.    
     .:c'               .';c:;..    .:c,,c;     .';cc;'.               'c:.     
      .,c;.                ..,:c:,. .:c,,c;. .,:c:,..                .;c,.      
        .::'.                  .';c::c:,,:c::c;'.                  .,c:.        
          '::'.                   ..,::;,::,..                   .'::.          
            '::,.                     ....                     .,:;.            
              .,:;'.                                        .'::,.              
                ..;:;,..                                ..,::,..                
                    .';:;,'..                      ..',;:;'.                    
                        .',;;;;,,''..........'',,;;;;,..                        
                            ...,;:cccllllllccc:;,.. 
                              BUY BACK TOKEN(BBT)
*/
/** 
 * 
 * BUY BACK (BBT)
 * 
 * Official Website : https://buybacktoken.com/
 * 
 * Official Hub Center: https://hub.buybacktoken.com
 * 
 * Official Telegram Group : https://t.me/buybacktoken 
 *  
 * 
 * MÁX SUPPLY 10 000 000 000 (Billions)
 * 
 * 5% FEE (TRANSACTION) * 

LAUNCH AT PANCAKE SWAP 
    
    Inicial Liquidity
     
    9 000 000 000 Billions BBT
                &
    1500$ In value to paired with BBT
    
 
  BUY BACK (BBT)
    All Lp Tokens from inicial liquidity will be sent to Dead Adress.
    6% Tokens distributed to all Devs and Team Members
    4% Inicial Burn supply, sent to a burned adress.

   Máx Inicial Transfer Amount

   = 15 000 000 Millions Tokens = 0.15% Máx Supply - This feature will give a change to everyone buy at the fair launch.
   
   Máx Transfer amount will be unlimited before contract ownership be renounced.  

*/

pragma solidity 0.8.3;

// SPDX-License-Identifier: MIT

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
    function _msgSender() internal virtual view returns (address) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
      
        bytes32 codehash;


            bytes32 accountHash
;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-block.timestamp/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Token {
    function transfer(address, uint256) external returns (bool);
}

contract BUYBACK is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "Cheems Inu Musk";
    string private _symbol = "CIM";
    uint8 private _decimals = 18;
    
    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 1000000 *10**18; // 10 Billion totalSupply
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));
    
    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;
    
    uint256 public _taxFee = 0; // 0 = 0%
    uint256 public _buybackv1Fee = 0; // 0 = 0%
    uint256 public _buybackv2Fee = 0; // 0 = 0%
    uint256 public _burningFee = 0; // 0 = 0%
    uint256 public _smarketingFee = 0; // 0 = 0%
    
    uint256 public _maxTxAmount = 1000000 * 10**18; // 15 Million inicial máx transfer
    
    uint256 public _taxFeeTotal;
    uint256 public _buybackv1FeeTotal;
    uint256 public _buybackv2FeeTotal;
    uint256 public _burningFeeTotal;
    uint256 public _smarketingFeeTotal;
    
    address public buybackv1Address  = 0x83Eebb91EdbFb444c55a225Be4ac38e567dD7CDC;      // BuyBackv1 Address
    address public buybackv2Address  = 0x83Eebb91EdbFb444c55a225Be4ac38e567dD7CDC;      // BuyBackv2 Address
    address public burningAddress;  // 0x000000000000000000000000000000000000dead  Burning Address add after deployment
    address public smarketingAddress = 0x29983A2D76104C97ece1fAc9c187aadA643a9773;      // SMarketing Address
    
    event RewardsDistributed(uint256 amount);
    
    

    constructor() {
        
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        
        _reflectionBalance[_msgSender()] = _reflectionTotal;
        emit Transfer(address(0), _msgSender(), _tokenTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
       _transfer(_msgSender(),recipient,amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub( amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee) public view returns (uint256) {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            return tokenAmount.mul(_getReflectionRate());
        } else {
            return tokenAmount.sub(tokenAmount.mul(_taxFee).div(10000)).mul(_getReflectionRate());
        }
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256) {
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();
        
        if(sender != owner() && recipient != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){
            transferAmount = collectFee(sender,amount,rate);
        }

        //@dev Transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));
        
        //@dev If any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }
        
        emit Transfer(sender, recipient, transferAmount);
    }
    
    function _burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account == msg.sender);
        
        _reflectionBalance[account] = _reflectionBalance[account].sub(amount, "ERC20: burn amount exceeds balance");
        _tokenTotal = _tokenTotal.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function collectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        
        uint256 transferAmount = amount;
        
        uint256 buybackv1Fee = amount.mul(_buybackv1Fee).div(10000);
        uint256 buybackv2Fee = amount.mul(_buybackv2Fee).div(10000);
        uint256 taxFee = amount.mul(_taxFee).div(10000);
        uint256 burningFee = amount.mul(_burningFee).div(10000);
        uint256 smarketingFee = amount.mul(_smarketingFee).div(10000);
        
          //@dev Burning fee
        if (burningFee > 0){
            transferAmount = transferAmount.sub(burningFee);
            _reflectionBalance[burningAddress] = _reflectionBalance[burningAddress].add(burningFee.mul(rate));
            _burningFeeTotal = _burningFeeTotal.add(burningFee);
            emit Transfer(account,burningAddress,burningFee);
        }
        
         //@dev SMarketing fee
        if (smarketingFee > 0){
            transferAmount = transferAmount.sub(smarketingFee);
            _reflectionBalance[smarketingAddress] = _reflectionBalance[smarketingAddress].add(smarketingFee.mul(rate));
            _smarketingFeeTotal = _smarketingFeeTotal.add(smarketingFee);
            emit Transfer(account,smarketingAddress,smarketingFee);
        }

        
        //@dev Tax fee
        if (taxFee > 0) {
            transferAmount = transferAmount.sub(taxFee);
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            _taxFeeTotal = _taxFeeTotal.add(taxFee);
            emit RewardsDistributed(taxFee);
        }

        //@dev BuyBackv1 fee
        if(buybackv1Fee > 0){
            transferAmount = transferAmount.sub(buybackv1Fee);
            _reflectionBalance[buybackv1Address] = _reflectionBalance[buybackv1Address].add(buybackv1Fee.mul(rate));
            _buybackv1FeeTotal = _buybackv1FeeTotal.add(buybackv1Fee);
            emit Transfer(account,buybackv1Address,buybackv1Fee);
        }
        
        //@dev BuyBackv2 fee
        if(buybackv2Fee > 0){
            transferAmount = transferAmount.sub(buybackv2Fee);
            _reflectionBalance[buybackv2Address] = _reflectionBalance[buybackv2Address].add(buybackv2Fee.mul(rate));
            _buybackv2FeeTotal = _buybackv2FeeTotal.add(buybackv2Fee);
            emit Transfer(account,buybackv2Address,buybackv2Fee);
        }
        
       
        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }
    
    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    
   
    function ExcludedFromFee(address account, bool) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function IncludeFromFee(address account, bool) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
     function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tokenTotal.mul(maxTxPercent).div(
            10**2
        );
     }
     
    function setTaxFee(uint256 fee) public onlyOwner {
        _taxFee = fee;
    }
    
    function setBuyBackv2Fee(uint256 fee) public onlyOwner {
        _buybackv2Fee = fee;
    }
    
    function setBuyBackv1Fee(uint256 fee) public onlyOwner {
        _buybackv1Fee = fee;
    }
    
     function setBurningFee(uint256 fee) public onlyOwner {
        _burningFee = fee;
    }
    
     function setSMarketingFee(uint256 fee) public onlyOwner {
        _smarketingFee = fee;
    }
    
    function setBuyBackv1Address(address _Address) public onlyOwner {
        require(_Address != buybackv1Address);
        
        buybackv1Address = _Address;
    }
    
    function setBuyBackv2Address(address _Address) public onlyOwner {
        require(_Address != buybackv2Address);
        
        buybackv2Address = _Address;
    }
    
    function setBurningAddress(address _Address) public onlyOwner {
        require(_Address != burningAddress);
        
        burningAddress = _Address;
    }
    
     function setSMarketingAddress(address _Address) public onlyOwner {
        require(_Address != smarketingAddress);
        
        smarketingAddress = _Address;
    }
    
    // function to allow admin to transfer ETH from this contract
    function TransferETH(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
    }
    
    // function to allow admin to transfer ERC20 tokens from this contract
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        Token(_tokenAddress).transfer(_to, _amount);
    }
    
    
    receive() external payable {}
}