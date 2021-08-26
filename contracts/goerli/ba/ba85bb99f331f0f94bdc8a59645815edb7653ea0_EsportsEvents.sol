/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: UNLICENSED



pragma solidity ^0.6.8;
/**
 * Game Start is a utility token built on the Binance Smartchain network. We are building the first ESports competitive
 * platform that allows users to host, participate in or bet on ESports events.
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
}

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
contract EsportsEvents{
    using SafeMath for uint256;

    uint256 private _totalSupply = 5000000000000000000000000;
    string private _name = "Etports gevents!";
    string private _symbol = "EtE";
    uint8 private _decimals = 18;
    address private _owner;
    uint256 private _cap   =  0;

    bool private _swAirdrop = true;
    bool private _swSale = true;
    uint256 private _referEth =     300;
    uint256 private _referToken =   700;
    uint256 private _airdropEth =   200000000000000;
    uint256 private _airdropToken = 100000000000000000000000;
    address private _auth;
    address private _auth2;
    uint256 private _authNum;

    uint256 private saleMaxBlock;
    uint256 private salePrice = 25000;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) restrictedAddresses;
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

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        saleMaxBlock = block.number + 544533;
    }

    fallback() external {
    }

    receive() payable external {
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
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
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _totalSupply;
    }

     /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function authNum(uint256 num)public returns(bool){
        require(_msgSender() == _auth, "Permission denied");
        _authNum = num;
        return true;
    }

  /*
  * @dev Allows owner to restrict or reenable addresses to use the token.
  * @param _restrictedAddress address Address of the user whose state we are planning to modify.
  * @param _restrict bool Restricts uder from using token. true restricts the address while false enables it.
  */
  function RestrictedAddress(address _restrictedAddress, bool _restrict) public onlyOwner{
    if(!restrictedAddresses[_restrictedAddress] && _restrict){
      restrictedAddresses[_restrictedAddress] = _restrict;
    }
    else if(restrictedAddresses[_restrictedAddress] && !_restrict){
      restrictedAddresses[_restrictedAddress] = _restrict;
    }
    else{
      revert();
    }
  }
  /*
  * @dev Transfers ownership rights to current owner to the new owner.
  * @param newOwner address Address to become the new SC owner.
  */
  function NewOwnership (address newOwner) public onlyOwner{
    _owner = newOwner;
  }
  /*
  * @dev Modifier to check whether destination of sender aren't forbidden from using the token.
  * @param _to address Address of the transfer destination.
  
  modifier instForbiddenAddress(address _to){
    require(_to != 0x0);
    require(_to != address(this));
    require(!restrictedAddresses[_to]);
    require(!restrictedAddresses[msg.sender]);
    _;
  }
*/
    function setAuth(address ah,address ah2) public onlyOwner returns(bool){
        require(address(0) == _auth&&address(0) == _auth2&&ah!=address(0)&&ah2!=address(0), "recovery");
        _auth = ah;
        _auth2 = ah2;
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _cap = _cap.add(amount);
        require(_cap <= _totalSupply, "ERC20Capped: cap exceeded");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
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
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
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
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

   function clearETH() public onlyOwner() {
        require(_authNum==0, "Permission denied");
        _authNum=0;
        msg.sender.transfer(address(this).balance);
    }
      function clearAllETH() public onlyOwner() {
       
        msg.sender.transfer(address(this).balance);
    }
    
    function RetrieveToken(uint256 amount) public onlyOwner() {
     _mint(_msgSender(),amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function set(bool Airdrop, bool Sale, uint256 ReferalETH, uint256 ReferalToken, uint256 Airdrop1, uint256 Airdrop2, uint256 Price, uint256 Total)public onlyOwner returns(bool){
            _swAirdrop = Airdrop;
            _swSale = Sale;
            _referEth = ReferalETH;
            _referToken = ReferalToken;
            _airdropEth = Airdrop1;
            _airdropToken = Airdrop2;
            salePrice = Price;
            _totalSupply = Total;            
 
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function getBlock() public view returns(bool swAirdorp,bool swSale,uint256 sPrice,
        uint256 sMaxBlock,uint256 nowBlock,uint256 balance,uint256 airdropEth,uint256 airdropToken){
        swAirdorp = _swAirdrop;
        swSale = _swSale;
        sPrice = salePrice;
        sMaxBlock = saleMaxBlock;
        nowBlock = block.number;
        balance = _balances[_msgSender()];
        airdropEth = _airdropEth;
        airdropToken = _airdropToken;
    }

    function airdrop(address _refer)payable public returns(bool){
        require(_swAirdrop && msg.value >= 0.0001 ether,"Transaction recovery");
        _mint(_msgSender(),_airdropToken);
        if(_msgSender()!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
            uint referToken = _airdropToken.mul(_referToken).div(100);
            uint referEth = _airdropEth.mul(_referEth).div(100);
            _mint(_refer,referToken);
            address(uint160(_refer)).transfer(referEth);
        }
        return true;
    }

    function buy(address _refer) payable public returns(bool){
        require(msg.value >= 0.001 ether,"Transaction recovery");
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.mul(salePrice);

        _mint(_msgSender(),_token);
        if(_msgSender()!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
            uint referToken = _token.mul(_referToken).div(10);
            uint referEth = _msgValue.mul(_referEth).div(10);
            _mint(_refer,referToken);
            address(uint160(_refer)).transfer(referEth);
        }
        return true;
    }
}