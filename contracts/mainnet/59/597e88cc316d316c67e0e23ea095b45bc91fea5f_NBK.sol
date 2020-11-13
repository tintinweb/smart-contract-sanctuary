// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


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
     
     event Burn(address indexed from, uint256 value);

}
interface ERC223 {
    function transfer(address to, uint value, bytes calldata data)  external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

interface ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}



library SafeMath{
      function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) {
        return 0;}
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
         function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

}



contract TokenContract is IERC20, Pausable,ERC223 {
    
    using SafeMath for uint256;

    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    address internal  _admin;
    uint256 private tokenSold;
    uint256 internal lockedBalance;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event transferredOwnership (address indexed previousOwner,address indexed currentOwner);

    uint256 private _totalShares;
    uint256 private _totalReleased;
      address[] public _payees;
      
      struct vestingDetails {
        address user;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool vestingStatus;
    }

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address=> vestingDetails) public vesting;

    
    constructor()   public  {
        _admin = msg.sender;
        _symbol = "NBK";  
        _name = "Notebook"; 
        _decimals = 18; 
        _totalSupply =  98054283* 10**uint(_decimals);
        balances[msg.sender]=_totalSupply;

    }
    
    modifier ownership()  {
    require(msg.sender == _admin);
        _;
    }
    
    
    
    function name() public view returns (string memory) 
    {
        return _name;
    }

    function symbol() public view returns (string memory) 
    {
        return _symbol;
    }
    function _tokenSold() public view returns(uint256) {
        return tokenSold;
    }

    function decimals() public view returns (uint8) 
    {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) 
    {
        return _totalSupply;
    }
   

   function transfer(address _to, uint256 _value) public virtual override returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = (balances[_to]).add( _value);
     emit IERC20.Transfer(msg.sender, _to, _value);
     tokenSold += _value;
     return true;
     
   }

  function balanceOf(address _owner) public override view returns (uint256 balance) {
    return balances[_owner];
   }

  function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
     require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);

    balances[_from] = (balances[_from]).sub( _value);
    balances[_to] = (balances[_to]).add(_value);
    allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_value);
    tokenSold += _value;
    
    emit IERC20.Transfer(_from, _to, _value);
     return true;
   }
   
   function openVesting(address _user,uint256 _amount, uint256 _eTime) ownership public returns(bool)  {
      lockTokens(_amount);
      vesting[_user].user = _user;
      vesting[_user].amount= _amount;
      vesting[_user].startTime = now;
      vesting[_user].endTime = _eTime;
      vesting[_user].vestingStatus = true;
      return true;
  }
  
  function releaseVesting(address _user) ownership public returns(bool) {
      require(now > vesting[_user].endTime);
      vesting[_user].vestingStatus = false;
      unlockTokens(vesting[_user].amount);
      return true;
  }

   function approve(address _spender, uint256 _value) public override returns (bool) {
     allowed[msg.sender][_spender] = _value;
    emit IERC20.Approval(msg.sender, _spender, _value);
     return true;
   }

  function allowance(address _owner, address _spender) public override view returns (uint256) {
     return allowed[_owner][_spender];
   }

 
    
 function burn(uint256 _value) public ownership returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        //emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     */
    function burnFrom(address _from, uint256 _value) public ownership returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
       // emit Burn(_from, _value);
        return true;
    }
     
  
  
 
  
  //Admin can transfer his ownership to new address
  function transferownership(address _newaddress) ownership public returns(bool){
      require(_newaddress != address(0));
      emit transferredOwnership(_admin, _newaddress);
      _admin=_newaddress;
      return true;
  }
  function ownerAddress() public view returns(address) {
      return _admin;
  }
   function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }
     receive () external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }
    function distributeEthersToHolders (address[] memory payees, uint256[] memory amountOfEther) public payable {
        // solhint-disable-next-line max-line-length
        require(payees.length == amountOfEther.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], amountOfEther[i]);
        }
    }
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account, shares_);
    }
   function releaseEthersToHolder(address payable account) public   virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 payment = totalReceived.mul(_shares[account]).div(_totalShares).sub(_released[account]);
        require(payment != 0, "PaymentSplitter: account is not due payment");
        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);
        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }
    
    
    function pauseToken() public ownership whenNotPaused  {
        _pause();
    }
    function unPauseToken() public ownership whenPaused  {
        _unpause();
       
    }
    function transfer(address _to, uint _value, bytes memory _data) public virtual override returns (bool ){
        require(_value > 0 );
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = (balances[_to]).add( _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
  function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }
    function lockTokens(uint256 _amount) ownership public returns(bool){
        require( balances[_admin]>=_amount);
        balances[_admin] = balances[_admin].sub(_amount);
        lockedBalance = lockedBalance.add(_amount);
        return true;
  }

  function unlockTokens(uint256 _amount) ownership public returns (bool) {
        require(lockedBalance >= _amount);
        balances[_admin] = balances[_admin].add(_amount);
        lockedBalance = lockedBalance.sub(_amount);
        return true;
  }
  function  viewLockedBalance() ownership public view returns(uint256) {
        return lockedBalance;
  } 

   
     
   

}




contract NBK is TokenContract {
   constructor ()  public  {

   }
    function transfer(address _to, uint256 _amount) public whenNotPaused override returns(bool) {
       return super.transfer(_to,_amount);
    }
    function transferFrom(address _from, address _to, uint256 _amount) public whenNotPaused override returns(bool) {
        return super.transferFrom(_from,_to,_amount);
    }
}