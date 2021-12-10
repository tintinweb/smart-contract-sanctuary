/**
 *Submitted for verification at snowtrace.io on 2021-12-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IKongz

abstract contract AvaxFoxes {
	function balanceOf(address _user) external view returns(uint256) {}
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {}
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]



//pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

//pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/math/[email protected]

//pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

//pragma solidity >=0.6.0 <0.8.0;



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
    constructor (string memory name_, string memory symbol_){
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


// File @openzeppelin/contracts/access/[email protected]

//pragma solidity >=0.6.0 <0.8.0;

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
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        //emit OwnershipTransferred(address(0), msgSender);
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



// File: SlyFox.sol

contract AvaxFoxesToken is ERC20 ("SlyFox", "SLY"), Ownable {
	using SafeMath for uint256;
    mapping(address => bool) public whitelisted;
    uint256[] public encodedrarities = [22858366611210472943388152914235503000591018933556467973949279112022292969482,9077043629329499767371562271880154768239542273140097758931747570688166003201,8283010212241199113176427359195919583730732934792451084338987344960252584529,14603054024662608285799562363233401095765609425311475473822817269093832622153,14490030539307968654240286176065670506290946977120204008833797746567856361472,938448145885951929620471670099499082196712656607763221893776649682734350338,8287217198170296567345076703467414543206616540523829425029808753174236632144,1258006878155674273883904834810855980598195039135171151748480588724212170769,9177005940481486142277743926417185907095330903499514133459604192794968663176,14629714984463339986194326828635354684473426989446655159084296843880164492435,1162862301528965237369968815209705593580809374864493624299116334498018370089,9286639297226801253476115635550456569582357134262730816362063092811437704777,29089653061396845699139095229499754755310823532995032207261117648940247855625,8256918532479528501686782496529417931893476683506203880864207931177383506434,14477607025302723135685393577522645061523815071373320378817755270169084625986,10196533237454982995221174494263485842676298700088618681542821002357015356418,21955294122827541168420560785320873010200919371558439739858963021749567882449,10067523099678625373933818790639826242688894433645246077572562073870567776257,3097503816046144206547720913597760544772162578436942626113880123190573801985,8383696770165659905004354968016400796592332089472101323672023128787594592896,2051375447135942441866320473963314770953722199743780358500106441318224790024,904850490166142600242817612885883851464402756345954309046340447681948943888,961168693388547165584216619138115725199594427457706274711769979709819200089,15620727421931903882420968501636889513684865668734644438159736616427874194057,7576268697809260071724713684563852000524449679566866695054730741820805878848,8256921605363461401425379228884263582325596246459751144199020688552040891458,7255365679413080183579101820145226599454261296568695527523265956989093875777,961389663650428411290787268398101248499079143767756329397493296814222610577,7523267699703235906947451741032874427983294460360747255516316367943308674080,1825598727445461101485379392028852686490842012048022214251258981909536965905,21712784502676926160972522790481826320669018843786969828074966849839050850904,7255115760062181194319958790790160012004311362973645233715114301223503987848,15493481919493487862442438184184949471221321426169518293193630038770168664144,14474264856204187928511042693388931778567459367194977538793110782950336660114,5359207736703912569006203600034253059253231843383131488825914388556059658,8482882570672991151102941865745269183609318213384803251029502244086926607433,15622686188357955395810490798963459241025759627380487071444084303708010354192,113520948512189423792857979515593994381799646621518802534531888928700802189,29886467016031511499765927476344139337140862150820807671864206754020375925442,15621164650795731409834175774802375280119572451634494270317510346033385177290,1049514992588268869586979921759727300814872089136199970643662714217855521280,18220172588338733724458179002733209013737933872869183296266197012723934756928,11790391804638920591330040541214846163933715604990718450756697736633219883136,2954617412283825905686965930609090790997769627670808778320833686190799979657,16325919338460166576909853927466151207970051108680543877255595188181457475209,15717899149399739957287347079427279307106405851413294931448108463844916989972,23520269057303912886617956950758468514803339186329751222267290890195528061505,8255040885919738367091602416494832109497162843880100064271248230252678809161,7497184288303697520290050373713239178913528434316319197086666711308072719425,1032401677878034582765982661920079001823188182543047868765027909582474293833,1813040466663388810909951412759822303043472028161509211279280138161047777282,24556141428841339684036130623448186610606432002280009027390776618478244999688,16402055908493527232118106989599962090596733234176256502679545792356713608,1047795536877960118554286168389777424505074716061113509502247780734097212432,15507648231870731563668352675512832890047967499305071548563297036982274044122,4670895422861902960879107667055835433106226262987166831449016956118104055882,7368443413023340134070323990871801249430401773007677743315534344200353787969,15619632570943088562094729676685997819043472420215276381981751807974442569880,8369583131126195115096612544401171821709955183489070419114120391933798424713,14355804481840416242716206869894798330996573057956661732560931419478037578,7606501844032005904653868393531818678240164388021844226222694892163796377665,7267512215458162821701530655521340910598182367215064062625008145850448257552,7354060604059018719037706889661824560579017199340025312104709238824907313176,14587534583491370147769648931396251503210431790870940609752443309004645467264,7237060865655186086476214760441381853471677180247080557264992166500561854690,8284972471855001999974213923949052216536565112987719686743863532952087729160,8382227129778890586240877818608208170583221267479290059213508695121268580969,1047750729436520095825293485996513315312330059802453524860636509259295887872,22728948561648179939896694595455611982459220402789396465968148665495934276672,15382171947894357233518560430799781134140408539041698230499798930420102893720,1926309016887746502755983016396862308486749248740680982735583717925096526872,10191485042723851807449941127383712654537163438748324583995042805368605377105,16283266431364051321528323352684251181298867146932358948202540578137929220618,10857290870908278878622990849935957452827246982553860456455254996158331228688,9159556147539199460283549072812468836260929637533604378180244007689711256712,1038965311834205841980424298519751212346105905604049922163434895356222541841,115094008622484435242311910145653110486537109464116652034367965353426133018,21824129999040362599725044029905718403070299686904801399185043525176257446416,21882432440524874403595628522128013866755317416889098242252574343546100060168,10182375174401454728042906250379144700872765842309636867335420102238271480897,16399878337769293753341440894936939299845378705412480701991690064479589536330,15519989416831880149886517733431242556287914698709047929971865493719904784450,15861238074925787618810191213697568120646314408754083691754208167645583282313,15507620637302581569502218109160221849264352352123614412728957193321481306177,14645410001339260594488751621169755228758638260980441476880475825070492157000,30873949048380316248976412494349541520159139388651780735267350082747057832448,21826115162699267455797618244510934832524939513068111143155476089857361612944,11098257505267690819240921868685789117521027813723283440861249646866863497938,15378637020436036224214563676690440011585464343909634090022565904004535555594,22845340332400956089422026194066201926759005198663554636533797106035114378009,15718148441274811154495976489787824685389379583659545245858387491298710945793,7621077841328843861376770995629726094445151727569195125686306878253282394120,24554149897842697851188930565763574884711310019769659816647797832883357885704,8313020191592002610852273379415425899952741493169241868252952165292506915072,904629203120122134400090862715993006862740782117660864752209239968754438730,15988199590588140789233226560388077725557835360446349670538392047033606254665,2714101849970344618222430703170853424638317643791079436312205752121197625880,14604986134290002319418265014392352603966541582091865295839662097126587962384,14492155907418365049702942433482441110719277256162793967425279010160022388810,117309537246174583604138729470311797449147326641395317838077256796259746368,22615697651796885584452837915743121846222137999302353390132520271519085498968,14855688094087095403226440314388107528647103899531938043587780443021230474770,15608579437515348714127312128507103071841573715254044494066118740603631187217,29854643050344324150007595581590945628893676460961805302322632525578999243328,7271046466399896183135404144429707175020579226535397659089981276035513397473,1922605790927799900475861459609189399275944223255024262462825823626122531602,21727170384008593726948732010201610981777833142239117680727562621457768190977,8383910287085323701029572270620254714079954569263261661682683362259736461386,3067274597735217311056045685165410080777075837924440409094319710239169974354,9272444959331002492878717706947741531221912262125206729737270019946992206042,1132808769104031513481172576663715209745144740033616420083712246776708277268,21838479059979759060449492269620265754218854784337093882705713219359965548617,16398139112814660507509419381863902910820180508087368712175038523136452624992,22743302315210757624138493745670541918912663389088945052510562272652067680841,9063925449922185824586798191975654710996916541144659204892200169803333276801,922301955386009952832666144626865410786885639110805492197978633912397107776,14474484039015712598052146662251741491697646569032152547062365191862749234256,9173697773155878820683476930406547934124881246393593618998154663159486482008];    

	uint256 constant public BASE_RATE = 1 ether; 	

	// Tue Mar 18 2031 17:46:47 GMT+0000
	uint256 public START = 0;
    uint256 constant public END = 2031622407;
    address private _admin;

	mapping(uint256 => uint256) public lastUpdate;    

	//AvaxFox public  AvaxFoxesContract;
    AvaxFoxes AvaxFoxesContract = AvaxFoxes(0x9E073C3613cF70ebB666431f27cC2CD97b9F0ddB);
    
	
    constructor() {
        START = block.timestamp;
        _admin = msg.sender;
        whitelistUser(_admin);        
    }	

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? b : a;
	}
    function getTotalClaimable(address _user) public view returns(uint256) {
       uint256[] memory ids = AvaxFoxesContract.walletOfOwner(_user);
       uint256 pending = 0;
       uint256 time = min(block.timestamp, END);
       for (uint i = 0; i < ids.length; i++){
           pending += getRarityof(ids[i]).mul(BASE_RATE.mul(time.sub(max(lastUpdate[ids[i]],START))).div(86400));
       }
       return pending;
	}
    function setClaimed(address _user) private {
       uint256[] memory ids = AvaxFoxesContract.walletOfOwner(_user);       
       uint256 time = min(block.timestamp, END);
       for (uint i = 0; i < ids.length; i++){
           lastUpdate[ids[i]] = time;
       }      
	}

	function getReward(address _from) public {
		uint count = getTotalClaimable(_from);
        setClaimed(_from);
		_mint(_from, count);
	}

    function mint(address _to, uint256 _amount) external {
		require(whitelisted[msg.sender]);
		_mint(_to, _amount);
	}

	function burn(address _from, uint256 _amount) external {
		require(msg.sender == _from || whitelisted[msg.sender]);
		_burn(_from, _amount);
	}

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
 
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function getRarity(uint256 _packedBools,uint256 _boolNumber) public view returns (uint256)
    {
        uint256 flag = (_packedBools >> ((85-_boolNumber)*3)) & uint256(7);
        return flag;        
    }
    function getRarityof(uint256 id) public view returns (uint256)
    {          
        if(id==10000){
            return 0;
        }
        if(id>9944){
            id = id + 30;
        }
        return getRarity(encodedrarities[id/85], id%85)+1;        
    }
}