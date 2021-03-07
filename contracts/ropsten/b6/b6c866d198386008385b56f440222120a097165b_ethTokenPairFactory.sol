/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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


abstract contract ERC20TokenBurnable {

  
   //totalsupply
   function totalSupply() public view virtual returns (uint256 _totalSupply);

    /// @param _owner The address from which the balance will be retrieved
    
    function balanceOf(address _owner) public view virtual returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
   
    function transfer(address _to, uint256 _value) public virtual returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
   
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function disApprove(address _spender)  public virtual returns (bool success);
  
     /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    
    function allowance(address owner, address spender) public view virtual returns (uint256 _allowances);
    function increaseAllowance(address _spender, uint _addedValue) public virtual returns (bool success);
    function decreaseAllowance(address _spender, uint _subtractedValue) public virtual returns (bool success);
     function name() public view virtual returns (string memory);

    /* Get the contract constant _symbol */
    function symbol() public view virtual returns (string memory);

    /* Get the contract constant _decimals */
    function decimals() public view virtual returns (uint8 _decimals); 
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual;
    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual;
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
}


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

    function safeTransfer(ERC20TokenBurnable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20TokenBurnable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(ERC20TokenBurnable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20TokenBurnable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20TokenBurnable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
        
  
    }
    
      function safeBurn(ERC20TokenBurnable token, uint256 amount) internal {
         _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, amount));
    }  
     function safeBurnFrom(ERC20TokenBurnable token, address account, uint256 amount) internal{
         _callOptionalReturn(token, abi.encodeWithSelector(token.burnFrom.selector, account, amount));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ERC20TokenBurnable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
abstract contract ReentrancyGuarded {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}



/*

Unique Token Pool contract with ETH vault for swap

*/
contract EthTokenSwapPoolContract is ReentrancyGuarded {
    
    using SafeERC20 for ERC20TokenBurnable;
    event Received(address,uint256); 
    event SwapRateChangedTo(uint256); 
    event Swapped(address,uint256);
    
   
     ERC20TokenBurnable public tokenContractAddress;
     uint256 public proposedWeiInVault;
     string public poolName;
     uint256 public initialTokenTotalSupply;
     bool poolActiveStatus;
    
    constructor(
    ERC20TokenBurnable _tokenaddress,
    uint256 _weiiinvault
  )
    
  {
    
    tokenContractAddress = _tokenaddress;
    proposedWeiInVault = _weiiinvault;
    poolName = tokenContractAddress.name();
    initialTokenTotalSupply = tokenContractAddress.totalSupply();
    poolActiveStatus = false;
    
  }
  
   modifier poolActive(){
        require(poolActiveStatus, "This pool is currently not activated");
        _;
    }
    

 receive() external payable {
     
     if(address(this).balance >= proposedWeiInVault)
     {
      proposedWeiInVault = address(this).balance; 
      if(!poolActiveStatus)
         poolActiveStatus = true;
      emit SwapRateChangedTo(swapRate()); 
     }
      emit Received(msg.sender, msg.value);
     
     }
    
/*
 returns swap rate of 1 token in wei
*/
function swapRate() public view  poolActive returns(uint256 _ramount)
{
    require(tokenContractAddress.totalSupply() != 0, "Token supply is 0");
    return uint256((proposedWeiInVault * (10 ** uint256(tokenContractAddress.decimals()))) / tokenContractAddress.totalSupply()); // swap rate of 1 Token in wei
}
//_amount of tokens
function requestSwap(address payable _requestor, uint256 _amount) public nonReentrant poolActive
{
    require(address(this).balance >= proposedWeiInVault,"The proposed amount of ETHER is not deposited fully");
    require(_requestor != address(0));
    require(tokenContractAddress.balanceOf(_requestor) >= (_amount * tokenContractAddress.decimals()));
    
    // calculate wei amount according to currenct swap rate
    uint256 swapedweiamount = _amount * swapRate();
    
    //smallesttoken units
    uint256 smallestTokenUnits = _amount * (10 ** uint256(tokenContractAddress.decimals()));
    
    //burn the amount of tokens from requestors tokenbalance
    SafeERC20.safeBurnFrom(tokenContractAddress, _requestor, smallestTokenUnits);
    //send the ether as per the swap rate 
    Address.sendValue(_requestor,swapedweiamount);
    
    emit Swapped(_requestor, _amount);
   
    
}

function poolsEtherBalanceINwei() public view returns (uint256 _balanceOfPool)
{
 return address(this).balance;
}
}

/*
The factory contract to create Token Pools for swapping with ETH

*/
contract ethTokenPairFactory is Ownable{
    
    using SafeERC20 for ERC20TokenBurnable;
    
    struct PoolDetails{
        string poolName;
        address poolCreator;
        EthTokenSwapPoolContract tokenPool; 
        uint256 totalGrantedEthAmount;
        ERC20TokenBurnable tokenAddress;
        bool exist;
        }
        
    mapping (address => PoolDetails) public PoolsRecords;
      
    event TokenPoolCreated(EthTokenSwapPoolContract);
    
    //create the token pool contract
function createTokenPoolContract(ERC20TokenBurnable _tokenaddr, uint256 etherInPool) internal returns(EthTokenSwapPoolContract)
{
    uint256 weiiinpool = etherInPool * (10 ** 18);
    EthTokenSwapPoolContract swapContract = new EthTokenSwapPoolContract(_tokenaddr,weiiinpool);
    return swapContract;
}

//call pool contract create function and put record
function buildTokenPool(ERC20TokenBurnable _tokenaddr, uint256 etherInPool) public
{
    require(!PoolsRecords[address(_tokenaddr)].exist, "The token pool already exists");
   EthTokenSwapPoolContract swapContractAddress =  createTokenPoolContract(_tokenaddr,etherInPool);
   PoolsRecords[address(_tokenaddr)] = PoolDetails({
                                                poolName: _tokenaddr.name(),
                                                poolCreator: msg.sender,
                                                tokenPool: swapContractAddress,
                                                totalGrantedEthAmount: etherInPool,
                                                tokenAddress: _tokenaddr,
                                                exist: true
                                                
                                                
                                            });
    emit TokenPoolCreated(swapContractAddress);                                         
        
}

//check if token pool exist
function tokenPoolExist(ERC20TokenBurnable _tokenaddr) public view returns(bool)
{
    return(PoolsRecords[address(_tokenaddr)].exist);
}

//get the token pool address if the token pool already exist
function getTokenPoolAddress(ERC20TokenBurnable _tokenaddr) public view returns(EthTokenSwapPoolContract _tokenPool)
{
     require(PoolsRecords[address(_tokenaddr)].exist, "The token pool does not exist");
     return PoolsRecords[address(_tokenaddr)].tokenPool;
}
//get the token pool swap rate
function getTokenSwapRate(ERC20TokenBurnable _tokenaddr) public view returns(uint256 _swaprate)
{
     require(PoolsRecords[address(_tokenaddr)].exist, "The token pool does not exist");
     return PoolsRecords[address(_tokenaddr)].tokenPool.swapRate();
}
//get the amount of ether currently present in the pool
function getTokenPoolEtherBalance(ERC20TokenBurnable _tokenaddr) public view returns(uint256 _balanceINwei)
{
     require(PoolsRecords[address(_tokenaddr)].exist, "The token pool does not exist");
     return PoolsRecords[address(_tokenaddr)].tokenPool.poolsEtherBalanceINwei();
}

function swapToken(ERC20TokenBurnable _tokenaddr, uint256 _amount) public
{
    require(PoolsRecords[address(_tokenaddr)].exist, "The token pool does not exist");
    //allow the pool contract to handle _amount number of tokens sent by msg.sender
     SafeERC20.safeApprove(_tokenaddr,address(PoolsRecords[address(_tokenaddr)].tokenPool),_amount * (10 ** uint256(_tokenaddr.decimals())));
     PoolsRecords[address(_tokenaddr)].tokenPool.requestSwap(payable(msg.sender), _amount);
}

}