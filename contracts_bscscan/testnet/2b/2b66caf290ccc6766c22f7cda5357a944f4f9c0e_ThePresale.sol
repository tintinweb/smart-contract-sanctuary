/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address tokenOwner)  external returns (uint balance);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address internal _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() private view returns (address) {
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
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() private {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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

contract ThePresale is Ownable{

    using SafeMath for uint256;
    using Address for address;

    address private _receiver;
    mapping (address => bool) private _allowedUsers;
    uint256 private _hardCap=0;
    uint256 private _min=0;
    uint256 private _max=0;
    uint256 private _collected=0;
    bool private _active=false;


    constructor () {
        _owner = _msgSender();
    }

    function receiver() public view returns (address) {
        return _receiver;
    }
    
    function updateReceiver(address _newReceiver) external onlyOwner() returns (address) {
        _receiver=_newReceiver;
        return _receiver;
    }

    function hardCap() public view returns (uint256) {
        return _hardCap;
    }
    
    function updateHardCap(uint256 _newHardCap) external onlyOwner() returns (uint256) {
        require(_newHardCap > 0);
        _hardCap=_newHardCap;
        return _hardCap;
    }

    function min() public view returns (uint256) {
        return _min;
    }
    
    function updateMin(uint256 _newMin) external onlyOwner() returns (uint256) {
        require(_newMin>0,"Amount must be greater than 0.");
        require(_newMin<_max,"Amount must be lower than Min.");
        _min=_newMin;
        return _hardCap;
    }

    function max() public view returns (uint256) {
        return _max;
    }
    
    function updateMax(uint256 _newMax) external onlyOwner() returns (uint256) {
        require(_newMax>0,"Amount must be greater than 0.");
        require(_newMax>_min,"Amount must be greater than Min.");
        _max=_newMax;
        return _hardCap;
    }
    
    function active() public view returns (bool) {
        return _active;
    }
    
    function updateActive(bool _newActive) external onlyOwner() returns (bool) {
        require(_newActive == true || _newActive == false, "Must be a boolean value");
        _active=_newActive;
        return _active;
    }

    function collected() public view returns (uint256) {
        return _collected;
    }
    
    function removeSomeoneFromAllowedUsers(address userToRemove) external onlyOwner() {
        require(_allowedUsers[userToRemove], "User is not in the list.");
        _allowedUsers[userToRemove]=false;
    }
    
    function addSomeoneInAllowedUsers(address userToAdd) external onlyOwner() {
        require(!_allowedUsers[userToAdd], "User already whitelisted.");
        _allowedUsers[userToAdd]=true;
    }

    function reset() external onlyOwner() {
        _hardCap = 0;
        _min = 0;
        _max = 0;
        _active = false;
        _collected = 0;
        // for (uint256 i = 0; i < _allowedUsers.length; i++) {
        //   _allowedUsers[i]=false;
        // }
    }
    
    function newEntity(address _REC, uint256 _HC, uint256 _MIN, uint256 _MAX) external onlyOwner() {
        require(_REC != address(0) , "Must not be a 0 address.");
        require(_MIN < _MAX , "Min should be smaller than Max.");
        require(_MIN > 0 , "Hard Cap must not be 0.");
        require(_MAX > 0 , "Hard Cap must not be 0.");
        require(_HC > 0 , "Hard Cap must not be 0.");
        _receiver = _REC;
        _hardCap = _HC;
        _min = _MIN;
        _max = _MAX;
        _active = true;
        _collected = 0;
    }

    function addWhitelistedUsers(address _from, address[] memory _addressesToAdd) external onlyOwner(){
        require(_from == msg.sender, "Not from the owner.");
        for (uint256 i = 0; i < _addressesToAdd.length; i++) {
          _allowedUsers[_addressesToAdd[i]]=true;
        }
        // require(_addressesToAdd != 0, "No dead address.");

    }
   
    function theVesting(IERC20 _token, address[] memory _to, uint256[] memory _values) payable public onlyOwner() {
      require(_to.length == _values.length);
      for (uint256 i = 0; i < _to.length; i++) {
          _token.transferFrom(msg.sender, _to[i], _values[i]);
        }
    }
   
    function theReceiveFunds(address payable _from, uint256 _amount) payable public {
      require(_active == true, "Presale is not active.");
      require(_hardCap > 0, "Hard Cap should be greater than 0.");
      require(_min > 0, "Min should be greater than 0.");
      require(_max > 0, "Max should be greater than 0.");
      require(_amount >= _min, "Amount exceeds minimum contribution.");
      require(_amount <= _max, "Amount exceeds maximum contribution.");
      require(_amount + _collected <= _hardCap, "Hard Cap reached.");
      require(_allowedUsers[_from], "User not whitelisted.");
      _from.transfer(_amount);
    }
    
    function theReceiveFundsFromAnotherCurrency(IERC20 _currency, address _from, uint256 _amount) external {
      require(_active == true, "Presale is not active.");
      require(_hardCap > 0, "Hard Cap should be greater than 0.");
      require(_min > 0, "Min should be greater than 0.");
      require(_max > 0, "Max should be greater than 0.");
      require(_amount >= _min, "Amount exceeds minimum contribution.");
      require(_amount <= _max, "Amount exceeds maximum contribution.");
      require(_amount + _collected <= _hardCap, "Hard Cap reached.");
      require(_allowedUsers[_from], "User not whitelisted.");
      _currency.transferFrom(_from, _receiver, _amount);
    }

}