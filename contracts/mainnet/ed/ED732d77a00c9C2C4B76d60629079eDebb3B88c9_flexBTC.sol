/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

// File: contracts/fBTCStorage.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract fBTCStorage {
    /** WARNING: NEVER RE-ORDER VARIABLES! 
     *  Always double-check that new variables are added APPEND-ONLY.
     *  Re-ordering variables can permanently BREAK the deployed proxy contract.
     */

    bool public initialized;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) public blacklist;

    uint256 internal _totalSupply;

    string public constant name = "flexBTC";
    string public constant symbol = "flexBTC";
    uint256 public multiplier;
    uint8 public constant decimals = 18;
    address public admin;
    uint256 internal constant deci = 1e18;

    bool internal getpause;
}

// File: contracts/Proxiable.sol



pragma solidity ^0.6.0;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
            ) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7,
                newAddress
            )
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return
            0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

// File: contracts/fBTC.sol





pragma solidity ^0.6.0;



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
     * Returns a boolean value indicating whBTCer the operation succeeded.
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
     * Returns a boolean value indicating whBTCer the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this mBTCod brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/BTCereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whBTCer the operation succeeded.
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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/BTCereum/solidity/issues/2691
        return msg.data;
    }
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

contract LibraryLock is fBTCStorage {
    // Ensures no one can manipulate the Logic Contract once it is deployed.	
    // PARITY WALLET HACK PREVENTION	

    modifier delegatedOnly() {	
        require(	
            initialized == true,	
            "The library is locked. No direct 'call' is allowed."	
        );	
        _;	
    }	
    function initialize() internal {	
        initialized = true;	
    }	
}

contract flexBTC is fBTCStorage, Context, IERC20, Proxiable, LibraryLock {	
    using SafeMath for uint256;

    event fTokenBlacklist(address indexed account, bool blocked);
    event ChangeMultiplier(uint256 multiplier);
    event AdminChanged(address admin);
    event CodeUpdated(address indexed newCode);	

    function initialize(uint256 _totalsupply) public {
        require(!initialized, "The library has already been initialized.");	
        LibraryLock.initialize();
        admin = msg.sender;
        multiplier = 1 * deci;
        _totalSupply = _totalsupply;
        _balances[msg.sender] = _totalSupply;
    }

    /// @dev Update the logic contract code	
    function updateCode(address newCode) external onlyAdmin delegatedOnly {	
        updateCodeAddress(newCode);	
        emit CodeUpdated(newCode);	
    }

    function setMultiplier(uint256 _multiplier)
        external
        onlyAdmin()
        ispaused()
    {
        require(
            _multiplier > multiplier,
            "the multiplier should be greater than previous multiplier"
        );
        multiplier = _multiplier;
        emit ChangeMultiplier(multiplier);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply.mul(multiplier).div(deci);
    }

    function setTotalSupply(uint256 inputTotalsupply) external onlyAdmin() {
        require(
            inputTotalsupply > totalSupply(),
            "the input total supply is not greater than present total supply"
        );
        multiplier = (inputTotalsupply.mul(deci)).div(_totalSupply);
        emit ChangeMultiplier(multiplier);
    }

    function balanceOf(address account) public override view returns (uint256) {
        uint256 externalAmt;
        externalAmt = _balances[account].mul(multiplier).div(deci);
        return externalAmt;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        Notblacklist(msg.sender)
        Notblacklist(recipient)
        ispaused()
        returns (bool)
    {
        uint256 internalAmt;
        uint256 externalAmt = amount;
        internalAmt = (amount.mul(deci)).div(multiplier);

        _transfer(msg.sender, recipient, externalAmt);
        return true;
    }

    function allowance(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        uint256 internalAmt;
         uint256 maxapproval = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
         maxapproval = maxapproval.div(multiplier).mul(deci);
        if(_allowances[owner][spender] > maxapproval){
           internalAmt = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        }else{
          internalAmt = (_allowances[owner][spender]).mul(multiplier).div(deci);
        }
       
        return internalAmt;
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        Notblacklist(spender)
        Notblacklist(msg.sender)
        ispaused()
        returns (bool)
    {
        uint256 internalAmt;
        uint256 externalAmt = amount;
        _approve(msg.sender, spender, externalAmt);
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
    function increaseAllowance(address spender, uint256 addedValue) public 
        Notblacklist(spender)
        Notblacklist(msg.sender)
        ispaused()  
        returns (bool) {
         uint256 externalAmt = allowance(_msgSender(),spender) ;
        _approve(_msgSender(), spender, externalAmt.add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public 
        Notblacklist(spender)
        Notblacklist(msg.sender)
        ispaused() 
        returns (bool) {
        uint256 externalAmt = allowance(_msgSender(),spender) ;
        _approve(_msgSender(), spender, externalAmt.sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        Notblacklist(sender)
        Notblacklist(msg.sender)
        Notblacklist(recipient)
        ispaused()
        returns (bool)
    {
        uint256 externalAmt = allowance(sender,_msgSender());
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
           externalAmt.sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 externalAmt
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 internalAmt = externalAmt.mul(deci).div(multiplier);
        _balances[sender] = _balances[sender].sub(
            internalAmt,
            "ERC20: transfer internalAmt exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(internalAmt);
        emit Transfer(sender, recipient, externalAmt);
    }

    function mint(address mintTo, uint256 amount)
        public
        virtual
        onlyAdmin()
        ispaused()
        returns (bool)
    {
        uint256 externalAmt = amount;
        uint256 internalAmt = externalAmt.mul(deci).div(multiplier);
        _mint(mintTo, internalAmt, externalAmt);
        return true;
    }

    function _mint(
        address account,
        uint256 internalAmt,
        uint256 externalAmt
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(internalAmt);
        _balances[account] = _balances[account].add(internalAmt);
        emit Transfer(address(0), account, externalAmt);
    }

    function burn(address burnFrom, uint256 amount)
        public
        virtual
        onlyAdmin()
        ispaused()
        returns (bool)
    {
        uint256 internalAmt;
        uint256 externalAmt = amount;
        internalAmt = externalAmt.mul(deci).div(multiplier);

        _burn(burnFrom, internalAmt, externalAmt);
        return true;
    }

    function _burn(
        address account,
        uint256 internalAmt,
        uint256 externalAmt
    ) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            internalAmt,
            "ERC20: burn internaAmt exceeds balance"
        );
        _totalSupply = _totalSupply.sub(internalAmt);
        emit Transfer(account, address(0), externalAmt);
    }

    function _approve(
        address owner,
        address spender,
        uint256 externalAmt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
         uint256 internalAmt;
         uint256 maxapproval = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
         maxapproval = maxapproval.div(multiplier).mul(deci);
        if(externalAmt > maxapproval){
           internalAmt = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        }else{
         internalAmt = externalAmt.mul(deci).div(multiplier);
        }
        _allowances[owner][spender] = internalAmt;
        emit Approval(owner, spender,externalAmt);
    }

    function TransferOwnerShip(address account) public onlyAdmin() {
        require(account != address(0), "account cannot be zero address");
        require(msg.sender == admin, "you are not the admin");
        admin = account;
        emit AdminChanged(admin);
    }

    function pause() external onlyAdmin() {
        getpause = true;
    }

    function unpause() external onlyAdmin() {
        getpause = false;
    }

    // pause unpause

    modifier ispaused() {
        require(getpause == false, "the contract is paused");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "you are not the admin");
        _;
    }

    function AddToBlacklist(address account) external onlyAdmin() {
        blacklist[account] = true;
        emit fTokenBlacklist(account, true);
    }

    function RemoveFromBlacklist(address account) external onlyAdmin() {
        blacklist[account] = false;
        emit fTokenBlacklist(account, false);
    }

    modifier Notblacklist(address account) {
        require(!blacklist[account], "account is blacklisted");
        _;
    }
}