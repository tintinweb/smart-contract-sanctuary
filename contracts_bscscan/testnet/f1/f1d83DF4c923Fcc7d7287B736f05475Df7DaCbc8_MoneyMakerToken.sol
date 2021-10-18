/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/binance/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
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
     * https://github.com/binance/EIPs/issues/20#issuecomment-263524729
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
     * https://eips.binance.org/EIPS/eip-1884[EIP1884] increases the gas cost
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
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
interface IEACAggregatorProxy
{
    function latestAnswer() external view returns (uint256);
}
interface tokenInterface
{
   function transfer(address _to, uint256 _amount) external returns (bool);
   function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
   function balanceOf(address user) external view returns(uint);
}
contract MoneyMakerToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;


    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;

    event BurnToken(address indexed _user, uint256 indexed transferToken);
    event Checkwallet(address target, bool frozen);
    event Unlockwallet(address target, bool frozen);

    mapping (address  => bool) public frozen ;

    modifier whenNotFrozen(address target) {
      require(!frozen[target]);
        _;
    }
    modifier whenFrozen(address target){
    require(frozen[target]);
    _;
    }
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX_SUPPLY = 50000000 * 10**18;
    uint256 private constant MAX_BURN = 5000000 * 10**18;

    uint256 public burnedTokens;

    uint public presaledays ;
    uint public privatesaledays;
    uint public publicsaledays;
    bool public isBNBSell;
    bool public isBUSDSell;
    bool public safeguard;  //putting safeguard on will halt all non-owner functions


    uint256 private burnFee = 10000000000;

    string private constant _name = 'Money Maker Token';
    string private constant _symbol = 'MMT';
    uint8 public constant _decimals = 18;
    uint256 public base = 100000000000000000;
    uint256 public currentPrice_= base  ;
    uint256 public sellPrice  = base ;
    uint256 public presale_price = 30000000000000000 ;
   uint256 public prisale_price = 60000000000000000 ;
   uint256 public pubsale_price = 90000000000000000 ;
    address public tokenBUSDAddress;
    address public EACAggregatorProxyAddress;
    uint256 public constant totalPreAllocated = MAX_SUPPLY * 2 / 100;
    uint256 public constant totalPriAllocated = MAX_SUPPLY * 3 / 100;
    uint256 public constant totalPubAllocated = MAX_SUPPLY * 5 / 100;
     uint256 private _totalSupply = totalPreAllocated + totalPriAllocated + totalPubAllocated;
    uint256 public presalesoldout;
    uint256 public prisalesoldout;
    uint256 public pubsalesoldout;

    uint256 public frozenSupply;
    //frozen balance that user can claim
    struct userfrozentokenInfo
    {
      uint256 _frozenbalances;
      uint _frozentimeout;
    }
    mapping(address => userfrozentokenInfo) public userInfo ;
    address[] private users;

    event Mint(address indexed to, uint256 amount);
    uint public mintTotal = 0;
    mapping(address => bool) internal minters;
      modifier onlyMinter(){
        require(minters[msg.sender],"Caller must be minters");
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(
      address _to,
      uint256 _amount
    )
      onlyMinter
      public
      returns (bool)
    {
      require(mintTotal + _amount <= MAX_SUPPLY, 'Maximum supply limit has been reached');
      _mint(_to,_amount);
      mintTotal += _amount;
      return true;
    }

    constructor (address _tokenBUSDAddress,address _EACAggregatorProxyAddress) {
        excludeAccount(_msgSender());
        minters[_msgSender()]=true;
        tokenBUSDAddress=_tokenBUSDAddress;
        EACAggregatorProxyAddress=_EACAggregatorProxyAddress;
        presaledays = block.timestamp.add(1200);// after live deployedtime.add(864000);
        privatesaledays = presaledays.add(1200);// after live presaledays.add(864000);
        publicsaledays = privatesaledays.add(1200);// after live privatesaledays.add(864000);
        //test -- 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        //main -- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE

    }

    function burn(uint256 value) public {
      _burn(msg.sender, value);
    }
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function BNBToBUSD(uint bnbAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return bnbAmount * bnbpreice * (10 ** (_decimals-8)) / (10 ** (_decimals));
    }

    function BUSDToBNB(uint busdAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return busdAmount  / bnbpreice * (10 ** (_decimals-10));
    }

    function BUSDToToken(uint _busdAmount,uint256 currentPrice) public pure returns(uint)
    {
       return ((_busdAmount / currentPrice) * (10 ** _decimals)) ;
    }

    function TokenToBUSD(uint TokenAmount,uint256 currentPrice) public pure returns(uint)
    {
        return TokenAmount / (10**_decimals) * currentPrice;
    }
    function TokenToBNB(uint256 TokenAmount,uint256 currentPrice) public view returns(uint)
    {
        uint amt =  TokenToBUSD(TokenAmount,currentPrice);
        return BUSDToBNB(amt);
    }
    function setSellOff() external  onlyOwner returns(bool)
    {
      isBNBSell =false;
      isBUSDSell = false;
      return true;
    }
    function setBusdSell() external  onlyOwner returns(bool)
    {
      isBUSDSell = true;
      isBNBSell = false;
      return true;
    }
    function setBNBSell() external  onlyOwner returns(bool)
    {
      isBNBSell = true;
      isBUSDSell = false;
      return true;
    }
    function adjustSellPrice(uint _sellprice) external onlyOwner returns(bool)
    {
        sellPrice = _sellprice;
        return true;
    }
    function adjustPrice(uint currenT) public onlyOwner returns(bool)
    {
        base = currenT;
        return true;
    }
    function adjustPreprice(uint currenT) public onlyOwner returns(bool)
    {
        presale_price = currenT;
        return true;
    }
    function adjustPriprice(uint currenT) public onlyOwner returns(bool)
    {
        prisale_price = currenT;
        return true;
    }
    function adjustPubprice(uint currenT) public onlyOwner returns(bool)
    {
        pubsale_price = currenT;
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function _Checkwallet(address target) public onlyOwner whenNotFrozen(target) returns (bool) {
      frozen[target] = true;
      emit Checkwallet(target, true);
      return true;
    }
    function _Unlockwallet(address target) public onlyOwner whenFrozen(target) returns (bool) {
      frozen[target] = false;
      emit Unlockwallet(target, false);
      return true;
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "MMT: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "MMT: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "IBEP20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    function excludeAccount(address account) public onlyOwner() {
        require(_excluded.length < 100,"Only 100 account will be excluded");
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "MMT: approve from the zero address");
        require(spender != address(0), "MMT: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "MMT: transfer from the zero address");
        require(recipient != address(0), "MMT: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

        if (!_isExcluded[recipient]) {
            _transferStandard(recipient, burnFee);
        }
    }


    function _transferStandard(address recipient, uint256 tAmount) private {
      if(burnedTokens + tAmount <= MAX_BURN && _balances[recipient]>=tAmount){
        _totalSupply = _totalSupply.sub(tAmount);
        _balances[recipient] = _balances[recipient].sub(tAmount);
        burnedTokens += tAmount;
        emit BurnToken(recipient, tAmount);
      }
    }
    function airdropACTIVE(address[] memory recipients,uint256[] memory _tokenAmount) public onlyOwner returns(bool) {
      require(!isContract(msg.sender),  'No contract address allowed');
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          _mint(recipients[i], _tokenAmount[i]);
        }
        return true;
    }
    function setminter(address account) public onlyOwner returns(bool) {
      require(!minters[account],"This account is already set as minter");
      minters[account]=true;
      return true;
    }
    function removeminter(address account) public onlyOwner returns(bool) {
      require(minters[account],"This account is not set as minter");
      minters[account]=false;
      return true;
    }
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "MMT: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function sell(uint256 _amountOfTokens) external
    {
        require(isBNBSell || isBUSDSell,"Sell is not enabled");
        address _customerAddress = msg.sender;
        uint256 userbalance = balanceOf(_customerAddress);
        
        require(userbalance > 0 ,"No balance");
        require(userbalance >= _amountOfTokens ,"Not enough balance");
        uint256 _busd = TokenToBUSD(_amountOfTokens,base) * sellPrice;
        transfer(address(this), _amountOfTokens);
        //transferFrom(_customerAddress, address(this), _amountOfTokens);
        if(isBNBSell)
        {
          uint256 bnbamt = BUSDToBNB(_busd);
           payable(_customerAddress).transfer(bnbamt);
        }
        else
        {
          tokenInterface(tokenBUSDAddress).transfer(_customerAddress,_busd);
        }
        emit Transfer(_customerAddress, address(this), _amountOfTokens);
    }
    event BuyToken(address _user,uint256 _amount, uint256 _curprice);
    function buy( uint256 tokenAmount) public payable returns(bool)
    {
      require(!safeguard);
      require(!isContract(msg.sender),  'No contract address allowed');
      require(tokenAmount > 0 || msg.value > 0, "invalid amount sent");
      if(tokenAmount > 0)
      {
        require(tokenAmount >= 1 * (10 ** _decimals), "invalid amount sent");
      }
      address _customerAddress = msg.sender;
      uint256 BUSDToken;

      uint256 MMTToken;
      if(block.timestamp <= presaledays)
      {
        currentPrice_=presale_price;
        if(tokenAmount > 0 )
        {
            tokenAmount = TokenToBUSD(tokenAmount,currentPrice_);
            BUSDToken = tokenAmount;
        }
        if(msg.value > 0)
        {
            tokenAmount += BNBToBUSD(msg.value);
        }
        MMTToken = BUSDToToken(tokenAmount,currentPrice_);
        //MMTToken = MMTToken * presale_price;
        require(MMTToken <  totalPreAllocated,"Amount exceeds");
        presalesoldout +=MMTToken;
        if(userInfo[_customerAddress]._frozenbalances==0)
        {
          users.push(_customerAddress);
        }
        userInfo[_customerAddress]._frozenbalances = userInfo[_customerAddress]._frozenbalances.add(MMTToken);
        userInfo[_customerAddress]._frozentimeout = block.timestamp.add(1800) ;
        tokenInterface(tokenBUSDAddress).transferFrom(msg.sender, address(this), BUSDToken);
        emit BuyToken(msg.sender, MMTToken,currentPrice_);
      }
      else if(block.timestamp > presaledays && block.timestamp <= privatesaledays)
      {
        currentPrice_=prisale_price;
        if(tokenAmount > 0 )
        {
            tokenAmount = TokenToBUSD(tokenAmount,currentPrice_);
            BUSDToken = tokenAmount;
        }
        if(msg.value > 0)
        {
            tokenAmount += BNBToBUSD(msg.value);
        }
        MMTToken = BUSDToToken(tokenAmount,currentPrice_);
       // MMTToken = MMTToken * prisale_price;
        require(MMTToken <  totalPriAllocated,"Amount exceeds");
        prisalesoldout +=MMTToken;
        if(userInfo[_customerAddress]._frozenbalances==0)
        {
          users.push(_customerAddress);
        }
        userInfo[_customerAddress]._frozenbalances = userInfo[_customerAddress]._frozenbalances.add(MMTToken);
        userInfo[_customerAddress]._frozentimeout = block.timestamp.add(1200) ;
        tokenInterface(tokenBUSDAddress).transferFrom(msg.sender, address(this), BUSDToken);
        emit BuyToken(msg.sender, MMTToken, currentPrice_);
      }
      else if(block.timestamp > presaledays && block.timestamp > privatesaledays && block.timestamp <= publicsaledays)
      {
        currentPrice_=pubsale_price;
        if(tokenAmount > 0 )
        {
            tokenAmount = TokenToBUSD(tokenAmount,currentPrice_);
            BUSDToken = tokenAmount;
        }
        if(msg.value > 0)
        {
            tokenAmount += BNBToBUSD(msg.value);
        }
        MMTToken = BUSDToToken(tokenAmount,currentPrice_);
        //MMTToken = MMTToken * pubsale_price;
        require(MMTToken <  totalPubAllocated,"Amount exceeds");
        pubsalesoldout +=MMTToken;
        if(userInfo[_customerAddress]._frozenbalances==0)
        {
          users.push(_customerAddress);
        }
        userInfo[_customerAddress]._frozenbalances = userInfo[_customerAddress]._frozenbalances.add(MMTToken);
        userInfo[_customerAddress]._frozentimeout = block.timestamp.add(600) ;
        tokenInterface(tokenBUSDAddress).transferFrom(msg.sender, address(this), BUSDToken);
        emit BuyToken(msg.sender, MMTToken, currentPrice_);
      }

      return true;
    }
    event BurnPhaseToken(string phase,uint vValue);
    function burnafterallsales() public onlyOwner() {
      require(publicsaledays  < block.timestamp ,"Sale is not finished yet");
      uint256 presaleBurn = totalPreAllocated.sub(presalesoldout);
      uint256 prisaleBurn=totalPriAllocated.sub(prisalesoldout);
      uint256 pubsaleBurn=totalPubAllocated.sub(pubsalesoldout);
      uint256 tokenstoburn =presaleBurn.add(prisaleBurn).add(pubsaleBurn);
      _totalSupply = _totalSupply.sub(tokenstoburn.mul(98).div(100));
      uint256 tokentodist = tokenstoburn.mul(2).div(100);
      uint user = users.length;
      tokentodist = tokentodist/user;
      for(uint i=0; i < user; i++)
      {
        userInfo[users[i]]._frozenbalances += tokentodist;
      }
    }
    function addSaleDays(uint _presaleday,uint _prisaleday,uint _pubsaleday) public onlyOwner() {
      presaledays = presaledays.add(_presaleday);
      privatesaledays = privatesaledays.add(_prisaleday);
      publicsaledays = publicsaledays.add(_pubsaleday);
    }

  /*  function closePreSale() public onlyOwner() {
        require(presaledays < block.timestamp ,"Presale is not yet finished");
        uint256 presaleBurn = totalPreAllocated.sub(presalesoldout);
        presaleBurn = presaleBurn.mul(98).div(100);
        _totalSupply = _totalSupply.sub(presaleBurn);
        emit BurnPhaseToken('Pre Sale',presaleBurn);
    }
    function closePriSale() public onlyOwner() {
        require(privatesaledays  < block.timestamp ,"Private sale is not yet finished");
        uint256 prisaleBurn=totalPriAllocated.sub(prisalesoldout);
        _totalSupply = _totalSupply.sub(prisaleBurn);
        emit BurnPhaseToken('Private Sale',prisaleBurn);
    }
    function closePubSale() public onlyOwner() {
        require(publicsaledays  < block.timestamp ,"Public sale is not yet finished");
        uint256 pubsaleBurn=totalPubAllocated.sub(pubsalesoldout);
        _totalSupply = _totalSupply.sub(pubsaleBurn);
        emit BurnPhaseToken('Public Sale',pubsaleBurn);

    }*/
    function changeBUSDTokenAddress(address _tokenBUSDAddress) public onlyOwner returns(bool)
    {
        tokenBUSDAddress = _tokenBUSDAddress;
        return true;
    }
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }
}