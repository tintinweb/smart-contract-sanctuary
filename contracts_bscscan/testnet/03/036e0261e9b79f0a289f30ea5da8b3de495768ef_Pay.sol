/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

 
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    address  private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


 interface tokenInterface
 {
    function sysTransfer(address _wallet, uint _amount) external  returns(bool);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function _isIdoParticipant(address _to) external returns (bool);
    function balanceOf(address _to) external returns (uint256);
    function inludeInIDO(address _add) external returns(bool);
  
 }


contract Pay is Ownable{
    
    using SafeMath for uint256;
    using Address for address;
    
    // ----------------------------------------IDO GLOBAL DATA STORAGE ------------------------------------------


  
      // Public variables for IDO
    
   	uint256 public exchangeRate = 1500000;         // exchange rate  1 BNB = 1500000 tokens 
   	uint256 public idoBNBReceived;                  // how many BNB Received through IDO
   	uint256 public totalTokenSold;                  // how many tokens sold
	uint256 public minimumContribution = 10**16;    // Minimum amount to invest - 0.01 BNB (in 18 decimal format)
    uint256 public maximumContribution = 50**17;    // Maximum amount to inveest - 0.5 BNB
    uint256 public maximumTokenHold = 15* 10**6* 10**18;   // Maximum amount a wallet can hold 15 million
    bool    public idoClosed;
    uint256 public idoAllotToken      = 15 * 10**9 * 10**18; // 15 billion for IDO
    address public _defiPlug_contract;
    address public tokenAddress ;
    bool    private isPreHoldingsDist;


//------------------------------------------END---------------------------------------------------------


    // -------------------------TokenHolderAddresses-------------------
    address public  _devMarketingWallet=0x8e2968C0d37a541864D496b5e106fF45D190c168;
    address public  _lpWallet=0xA8330fd4649bFF4198D25e17227c28C18A82A62F;
    address public  _teamWallet=0x3Ca577EF8f392b13e3490864efccdd16A88AA388;
    address public  _charityWallet=0x0A4C9366Fb8d687EBc172C28C0dFC41Ae6705a4d;
    //--------------------------------------------------------------------
    
  
    
    uint256 public  _bountyBonusAllot = 10 * 10**9 * 10**18;   //  10 billion
    uint256 public  _totalBountyDistributed;                 // no of distribute token
    uint256 public  _lpAllot         = 10 * 10**9 * 10**18;  //  10 billion
    uint256 public  _devMarketingAllot = 5 *  10**9 * 10**18;   // 5 billion
    uint256 public  _teamAllot            = 25 * 10**8 * 10**18; //  2.5 billion
    uint256 public  _charityAllot         = 25 * 10**8 * 10**18; //  2.5 billion
    uint256 public  _lockedTokenAllot     = 5 *  10**9 * 10**18;   // 5 billion
    uint256 public  _lockedPeriod;
    bool    public  _lockedTokenClaimed;  
    
    
    
    function addAdmin(address _minter) public onlyOwner {
        require(_minter !=address(0) , "Invalid address");
        _defiPlug_contract=_minter;
    }

    modifier onlyAdmin() {
        require(_defiPlug_contract ==_msgSender() && Address.isContract(_msgSender()), "Caller could be only minter contract");
        _;
    }
    
    function setToken(address _token) public returns(bool){
        
        require(_token!=address(0),"Invalid address");
        tokenAddress=_token;
    }
    
    
    function transferBonus(address _receiver, uint256 _amount) internal   {
        require(_totalBountyDistributed<=_bountyBonusAllot,"no more bonus is available");
        tokenInterface(tokenAddress).sysTransfer(_receiver,_amount);
        _totalBountyDistributed.add(_amount);
    }
    

    function openLockedToken() public onlyOwner returns(bool){
        
        require(_lockedTokenClaimed==false,"Token already Claimed");
        require(_lockedPeriod<=block.timestamp,"Please wait until locked period over");
        // _mint(msg.sender,_lockedTokenAllot);
        tokenInterface(tokenAddress).transfer(owner(),_lockedTokenAllot);
        _lockedTokenClaimed=true;
    }
    
    
    function InitializePreFund() public onlyOwner {
        
        require(isPreHoldingsDist==false,"InitializePreFund is already over!");
        tokenInterface(tokenAddress).sysTransfer(_lpWallet,_lpAllot);
        tokenInterface(tokenAddress).sysTransfer(_devMarketingWallet,_devMarketingAllot);
        tokenInterface(tokenAddress).sysTransfer(_teamWallet,_teamAllot);
        tokenInterface(tokenAddress).sysTransfer(_charityWallet,_charityAllot);
        tokenInterface(tokenAddress).sysTransfer(owner(),idoAllotToken);
        isPreHoldingsDist=true;
    }
    
    
    constructor() public{
        
         _lockedPeriod= block.timestamp+157784760; // 5 years
    }
    
    
    
     // ------------------------IDO functions -----------------


    event buyTokenEvent (address sender,uint amount, uint tokenPaid);
    function buyToken() payable public returns(uint)
    {
		
		//checking conditions
		require(idoClosed==false,"IDO is Closed Now.");
        require(msg.value >= minimumContribution, "less then minimum contribution");
        require(tokenInterface(tokenAddress).balanceOf(msg.sender)<=maximumTokenHold,"wallet reach maximum holdings");
        require(msg.value<=maximumContribution,"You hit wallet max holdings limit");
        
        //calculating tokens to issue
        uint256 tokenTotal = msg.value * exchangeRate;
        require(totalTokenSold.add(tokenTotal)<=idoAllotToken,"all tokens already sold");
        //updating state variables
        idoBNBReceived += msg.value;
        totalTokenSold += tokenTotal;
        
        //sending tokens. This contract must hold enough tokens.

        transferBonus(msg.sender,tokenTotal);
        
        if(tokenInterface(tokenAddress)._isIdoParticipant(msg.sender)==false){
            
            tokenInterface(tokenAddress).inludeInIDO(msg.sender);
        }
        
        //send ether to owner
        forwardBNBToOwner();
        
        //logging event
        emit buyTokenEvent(msg.sender,msg.value, tokenTotal);
        
        return tokenTotal;

    }


	//Automatocally forwards ether from smart contract to owner address
	function forwardBNBToOwner() internal {
		payable(owner()).transfer(msg.value); 
	}
	
	
	// exchange rate => 1 BNB = how many tokens
    function setExchangeRate(uint256 _exchangeRatePercent) onlyOwner public returns (bool)
    {
        exchangeRate = _exchangeRatePercent;
        return true;
    }

    function setIdoClosed() onlyOwner public returns (bool)
    {
        idoClosed = true;
        return true;
    }

    function setMinimumContribution(uint256 _minimumContribution) onlyOwner public returns (bool)
    {
        minimumContribution = _minimumContribution;
        return true;
    }
    
    
    function setMaximumContribution(uint256 _maximumContribution) onlyOwner public returns (bool)
    {
        maximumContribution = _maximumContribution;
        return true;
    }
    
	function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string memory){
        // no need for overflow checking as that will be done in transfer function
        require(totalTokenSold<idoAllotToken,"token sold");
        uint256 remainToken = idoAllotToken.sub(totalTokenSold);
        require(remainToken<=tokenAmount);
        // _mint(msg.sender,tokenAmount);
        tokenInterface(tokenAddress).transfer(owner(),tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }

    function manualWithdrawBNB() public onlyOwner returns(string memory){
        payable(owner()).transfer(address(this).balance);
        return "BNB withdrawn to owner wallet";
    }
    
}