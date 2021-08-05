/**
 *Submitted for verification at Etherscan.io on 2020-06-14
*/

pragma solidity ^0.6.0;

// "SPDX-License-Identifier: UNLICENSED"

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


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
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    function _setupDecimals(uint8 decimals_) internal {
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


/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface MyUniswapProxy {
    // function calculateIndexValueAndNextTokenIndex(uint numberOfTokens) external returns(uint, uint);
    function calculateIndexValueAndNext2Tokens(uint numberOfTokens) external returns(uint, uint, uint);
    function executeSwap(ERC20 srcToken, uint srcQty, ERC20 destToken, address destAddress) external;
}

contract ERCIndex is ERC20, Owner {
    
    // Variables
    
    ERC20[] public topTokens;
    //ERC20 daiToken = ERC20(0xaD6D458402F60fD3Bd25163575031ACDce07538D); // ropsten
    // ERC20 daiToken = ERC20(0x2448eE2641d78CC42D7AD76498917359D961A783); // rinkeby
    ERC20 daiToken = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); // mainnet
    
    MyUniswapProxy public myUniswapProxy;
    
    bool public isActive = true;
    bool public canBeBought = true;

    // Functions
        
    constructor(address _myProxyAddress) public ERC20("ERC Index", "ERCI") {
        
        _mint(msg.sender, 0);
        
        myUniswapProxy = MyUniswapProxy(_myProxyAddress);
        
        daiToken.approve(address(myUniswapProxy), uint(-1));
    
    }
    
    // add address of ERC20 token to top token regitry
    function addNextTopToken(ERC20 _token) public isOwner {
        // ropsten addresses:
        // DAI 0xaD6D458402F60fD3Bd25163575031ACDce07538D
        // BAT 0xDb0040451F373949A4Be60dcd7b6B8D6E42658B6
        // MKR 0x4a47be893ddef62696800ffcddb8476c92ab4221
        // LINK 0xb4f7332ed719Eb4839f091EDDB2A3bA309739521 -
        // OMG 0x4BFBa4a8F28755Cb2061c413459EE562c6B9c51b -
        // KNC 0x7b2810576aa1cce68f2b118cef1f36467c648f92 -
        
        // wont have more than 10 ERC20 tokens - keeping gas costs low
        require(topTokensLength() < 10);
        
        topTokens.push(_token);
        
        _token.approve(address(myUniswapProxy), uint(-1));
    }
    
    // remove address of ERC20 token to top token regitry & sell it for DAI
    function removeTopTopen(uint _index) public isOwner {
        
        require(_index >= 0 && _index < topTokensLength()); 
        
        if (topTokens[_index].balanceOf(address(this)) > 0) {
            
            _sellERCToken(topTokens[_index], topTokens[_index].balanceOf(address(this)), address(this)); // sell token for dai
            
        }
        
        topTokens[_index] = topTokens[topTokensLength() - 1]; // remove token from top tokens (ovverride with token in last place)
        
        topTokens.pop(); // remove last token from array
        
    }
    
    function topTokensLength() public view returns (uint) {
        
        return topTokens.length;
        
    }
    
    // helper function used by myUniswapProxy contract
    function getTokenAddressAndBalance(uint _index) public view returns (ERC20, uint) {
        
        require (_index < topTokensLength());
        
        return (topTokens[_index], topTokens[_index].balanceOf(address(this)));
        
    }
    
    /*
        Call this function to purchase ERCI with DAI (must set dai allowance beforehand)
        The index will buy the appropriate token from its registry and mint the sender their share of ERCI
    */
    function buyERCIWithDai(uint256 _daiAmount) public returns(bool) {
    
        require(isActive, "Contract was shut down!");
        require(canBeBought, "Index can't be bought currently");
        require(_daiAmount > 0);
        require(daiToken.transferFrom(msg.sender, address(this), _daiAmount));
        
        require(topTokensLength() > 0);
        
        uint daiValue;
        
        uint index;
        
        uint index2;
        
        // claculate dai value of ERCI index and the next token that should be purchased
        // (daiValue, index) = myUniswapProxy.calculateIndexValueAndNextTokenIndex(topTokensLength());
        (daiValue, index, index2) = myUniswapProxy.calculateIndexValueAndNext2Tokens(topTokensLength());
        
        // number of ERCI to grant sender
        // ! daiValue will include the current dai deposi
        
        uint mintAmount = getMintAmount(_daiAmount, daiValue);
        
        // buy token with both sender's dai and contract's dai
        _buyERCToken(daiToken.balanceOf(address(this)) / uint(3), topTokens[index2]); // use a third of dai to buy the second token
        _buyERCToken(daiToken.balanceOf(address(this)), topTokens[index]); // use the rest to buy the main token
        
        _mint(msg.sender, mintAmount);
    }
    
    // Calculate fair share of ERCI tokens
    // note - _totalDaiValue is always >= _addAmount
    function getMintAmount(uint _addAmount, uint _totalDaiValue) public view returns(uint) {
        
        uint previousDaiValue = _totalDaiValue - _addAmount;
        
        if (previousDaiValue == 0) {
            
            return _addAmount; // will do 1:1 in this case
            
        } else {
            
            return (totalSupply() * _addAmount) / previousDaiValue; // return proportional value of index
            
        }
        
    }
    
    function _buyERCToken(uint _daiAmount, ERC20 _token) private {
        
        myUniswapProxy.executeSwap(daiToken, _daiAmount, _token, address(this));
        
    }

    // call this function to sell ERCI tokens and claim your share of DAI from the fund
    function sellERCIforDai(uint _erciAmount) public {
        
        require(_erciAmount > 0 , "Amount too low");
        require(_erciAmount <= balanceOf(msg.sender), "Insufficient funds");
        require(_erciAmount <= allowance(msg.sender, address(this)), "ERCI allowance not set");
        require(ERC20(this).transferFrom(msg.sender, address(this), _erciAmount));
        
        uint percent = getPercent(_erciAmount);
        
        _sellPercentOfIndexForDai(percent, msg.sender);
        
        _claimToken(daiToken, percent);
        
        _burn(address(this), _erciAmount);
        
    }
    
    function sellERCIforERC20tokens(uint _erciAmount) public {
        
        require(_erciAmount > 0 , "Amount too low");
        require(_erciAmount <= balanceOf(msg.sender), "Insufficient funds");
        require(_erciAmount <= allowance(msg.sender, address(this)), "ERCI allowance not set");
        require(ERC20(this).transferFrom(msg.sender, address(this), _erciAmount));
        
        uint percent = getPercent(_erciAmount);
        
        for (uint i = 0; i < topTokensLength(); i++) {
            
            _claimToken(topTokens[i], percent);
            
        }
        
        _claimToken(daiToken, percent);
        
        _burn(address(this), _erciAmount);
    }
    
    // return the percent of ERCI that is being sold, multiplied by 10 ** 18
    function getPercent(uint _erciAmount) internal view returns(uint) {
        
        return (_erciAmount * (10 ** 18))  / totalSupply(); // instead of 0.125 return 125000000000000000
        
    }
    
    // will sell percent of each token and send DAI to _receiver
    function _sellPercentOfIndexForDai(uint _percent, address _receiver) internal {
        
        for (uint i = 0; i < topTokensLength(); i++) {
            
            uint tokenBalance = topTokens[i].balanceOf(address(this));
            
            if (tokenBalance > 0) {
            
                uint sellAmount = (tokenBalance * _percent) / 10 ** 18; // because percent is multiplied by 10 ** 18
    
                _sellERCToken(topTokens[i], sellAmount, _receiver);
            
            }
        }
    }
    
    // when selling, also claim you share of token (DAI) the fund is holding
    function _claimToken(ERC20 _token, uint _percent) internal {
    
        uint tokenAmount = (_token.balanceOf(address(this)) * _percent) / 10 ** 18;
        
        if (tokenAmount > 0) {
        
            _token.transfer(msg.sender, tokenAmount);
        
        }    
    }
    
    function _sellERCToken(ERC20 _token, uint _amount, address _receiver) internal {
        
        // fuck require(_token.approve(address(myUniswapProxy), _amount)); // so it can sell the token - no need for this - will cause KNC contract to revert
        
        myUniswapProxy.executeSwap(_token, _amount, daiToken, _receiver); // send dai to user
        
    }
    
    function setCanBeBought(bool _value) public isOwner {
        canBeBought = _value;
    }
    
    // disable purchasing of ERCI and sell all tokens for DAI
    function exit() isOwner public {
        
        isActive = false;
        
        // sell 100% of index for dai
        _sellPercentOfIndexForDai(10 ** 18, address(this)); // will send DAI to contract
        
    }

}