/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
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

/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
abstract contract ERC223ReceivingContract {
    function tokenFallback(address sender, uint amount, bytes memory data) public virtual;
}

contract TheWallCoupons is Context
{
    using SafeMath for uint256;
    using Address for address;

    string public standard='Token 0.1';
    string public name='TheWall';
    string public symbol='TWC';
    uint8 public decimals=0;
    
    event Transfer(address indexed sender, address indexed receiver, uint256 amount, bytes data);

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    address private _thewallusers;

    function setTheWallUsers(address thewallusers) public
    {
        require(thewallusers != address(0), "TheWallCoupons: non-zero address is required");
        require(_thewallusers == address(0), "TheWallCoupons: _thewallusers can be initialized only once");
        _thewallusers = thewallusers;
    }

    modifier onlyTheWallUsers()
    {
        require(_msgSender() == _thewallusers, "TheWallCoupons: can be called from _theWallusers only");
        _;
    }

    function transfer(address receiver, uint256 amount, bytes memory data) public returns(bool)
    {
        _transfer(_msgSender(), receiver, amount, data);
        return true;
    }
    
    function transfer(address receiver, uint256 amount) public returns(bool)
    {
        bytes memory empty = hex"00000000";
         _transfer(_msgSender(), receiver, amount, empty);
         return true;
    }

    function _transfer(address sender, address receiver, uint amount, bytes memory data) internal
    {
        require(receiver != address(0), "TheWallCoupons: Transfer to zero-address is forbidden");

        balanceOf[sender] = balanceOf[sender].sub(amount);
        balanceOf[receiver] = balanceOf[receiver].add(amount);
        
        if (receiver.isContract())
        {
            ERC223ReceivingContract r = ERC223ReceivingContract(receiver);
            r.tokenFallback(sender, amount, data);
        }
        emit Transfer(sender, receiver, amount, data);
    }

    function _mint(address account, uint256 amount) onlyTheWallUsers public
    {
        require(account != address(0), "TheWallCoupons: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        bytes memory empty = hex"00000000";
        emit Transfer(address(0), account, amount, empty);
    }

    function _burn(address account, uint256 amount) onlyTheWallUsers public
    {
        require(account != address(0), "TheWallCoupons: burn from the zero address");

        balanceOf[account] = balanceOf[account].sub(amount, "TheWallCoupons: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        bytes memory empty = hex"00000000";
        emit Transfer(account, address(0), amount, empty);
    }
}

/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
contract TheWallUsers is Ownable
{
    using SafeMath for uint256;
    using Address for address payable;

    struct User
    {
        string          nickname;
        bytes           avatar;
        address payable referrer;
    }
    
    TheWallCoupons private _coupons;

    mapping (address => User) public _users;
    
    event NicknameChanged(address indexed user, string nickname);
    event AvatarChanged(address indexed user, bytes avatar);

    event CouponsCreated(address indexed owner, uint256 created);
    event CouponsUsed(address indexed owner, uint256 used);

    event ReferrerChanged(address indexed me, address indexed referrer);
    event ReferralPayment(address indexed referrer, address indexed referral, uint256 amountWei);

    constructor (address coupons)
    {
        _coupons = TheWallCoupons(coupons);
        _coupons.setTheWallUsers(address(this));
    }

    function setNickname(string memory nickname) public
    {
        _users[_msgSender()].nickname = nickname;
        emit NicknameChanged(_msgSender(), nickname);
    }

    function setAvatar(bytes memory avatar) public
    {
        _users[_msgSender()].avatar = avatar;
        emit AvatarChanged(_msgSender(), avatar);
    }
    
    function setNicknameAvatar(string memory nickname, bytes memory avatar) public
    {
        setNickname(nickname);
        setAvatar(avatar);
    }
    
    function _useCoupons(address owner, uint256 count) internal returns(uint256 used)
    {
        used = _coupons.balanceOf(owner);
        if (count < used)
        {
            used = count;
        }
        if (used > 0)
        {
            _coupons._burn(owner, used);
            emit CouponsUsed(owner, used);
        }
    }

    function giveCoupons(address owner, uint256 count) public onlyOwner
    {
        _giveCoupons(owner, count);
    }
    
    function giveCouponsMulti(address[] memory owners, uint256 count) public onlyOwner
    {
        for(uint i = 0; i < owners.length; ++i)
        {
            _giveCoupons(owners[i], count);
        }
    }
    
    function _giveCoupons(address owner, uint256 count) internal
    {
        require(owner != address(0));
        _coupons._mint(owner, count);
        emit CouponsCreated(owner, count);
    }
    
    function _processRef(address me, address payable referrerCandidate, uint256 amountWei) internal returns(uint256)
    {
        User storage user = _users[me];
        if (referrerCandidate != address(0) && !referrerCandidate.isContract() && user.referrer == address(0))
        {
            user.referrer = referrerCandidate;
            emit ReferrerChanged(me, referrerCandidate);
        }
        
        uint256 alreadyPayed = 0;
        uint256 refPayment = amountWei.mul(6).div(100);

        address payable ref = user.referrer;
        if (ref != address(0))
        {
            ref.sendValue(refPayment);
            alreadyPayed = refPayment;
            emit ReferralPayment(ref, me, refPayment);
            
            ref = _users[ref].referrer;
            if (ref != address(0))
            {
                ref.sendValue(refPayment);
                alreadyPayed = refPayment.mul(2);
                emit ReferralPayment(ref, me, refPayment);
            }
        }
        
        return alreadyPayed;
    }
}

/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
contract TheWallCore is TheWallUsers
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using Address for address;
    using Address for address payable;

    event SizeChanged(int256 wallWidth, int256 wallHeight);
    event AreaCostChanged(uint256 costWei);
    event FundsReceiverChanged(address fundsReceiver);
    event SecretCommited(uint256 secret, bytes32 hashOfSecret);
    event SecretUpdated(bytes32 hashOfNewSecret);

    enum Status
    {
        None,
        ForSale,
        ForRent,
        Rented
    }

    enum TokenType
    {
        Unknown,
        Area,
        Cluster
    }

    struct Token
    {
        TokenType  tt;
        Status     status;
        string     link;
        string     tags;
        string     title;
        uint256    cost;
        uint256    rentDuration;
        address    tenant;
        bytes      content;
    }
    
    struct Area
    {
        int256     x;
        int256     y;
        bool       premium;
        uint256    cluster;
        bytes      image;
        bytes32    hashOfSecret;
        uint256    nonce;
    }

    struct Cluster
    {
        uint256[]  areas;
        mapping (uint256 => uint256) areaToIndex;
        uint256    revision;
    }

    // x => y => area erc-721
    mapping (int256 => mapping (int256 => uint256)) private _areasOnTheWall;

    // erc-721 => Token, Area or Cluster
    mapping (uint256 => Token) private _tokens;
    mapping (uint256 => Area) private _areas;
    mapping (uint256 => Cluster) private _clusters;

    mapping (bytes32 => uint256) private _secrets;
    bytes32 private _hashOfSecret;
    bytes32 private _hashOfSecretToCommit;

    int256  public  _wallWidth;
    int256  public  _wallHeight;
    uint256 public  _costWei;
    address payable private _fundsReceiver;
    address private _thewall;

    constructor (address coupons) TheWallUsers(coupons)
    {
        _wallWidth = 1000;
        _wallHeight = 1000;
        _costWei = 1 ether / 10;
        _fundsReceiver = payable(_msgSender());
    }

    function setTheWall(address thewall) public
    {
        require(thewall != address(0) && _thewall == address(0));
        _thewall = thewall;
    }

    modifier onlyTheWall()
    {
        require(_msgSender() == _thewall);
        _;
    }
    
    function setWallSize(int256 wallWidth, int256 wallHeight) public onlyOwner
    {
        require(_wallWidth <= wallWidth && _wallHeight <= wallHeight);
        _wallWidth = wallWidth;
        _wallHeight = wallHeight;
        emit SizeChanged(wallWidth, wallHeight);
    }

    function setCostWei(uint256 costWei) public onlyOwner
    {
        _costWei = costWei;
        emit AreaCostChanged(costWei);
    }

    function setFundsReceiver(address payable fundsReceiver) public onlyOwner
    {
        require(fundsReceiver != address(0));
        _fundsReceiver = fundsReceiver;
        emit FundsReceiverChanged(fundsReceiver);
    }

    function commitSecret(uint256 secret) public onlyOwner
    {
        require(_hashOfSecretToCommit == keccak256(abi.encodePacked(secret)));
        _secrets[_hashOfSecretToCommit] = secret;
        emit SecretCommited(secret, _hashOfSecretToCommit);
        delete _hashOfSecretToCommit;
    }

    function updateSecret(bytes32 hashOfNewSecret) public onlyOwner
    {
        _hashOfSecretToCommit = _hashOfSecret;
        _hashOfSecret = hashOfNewSecret;
        emit SecretUpdated(hashOfNewSecret);
    }

    function _canBeTransferred(uint256 tokenId) public view returns(TokenType)
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No such token found");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: Can't transfer rented item");
        if (token.tt == TokenType.Area)
        {
            Area memory area = _areas[tokenId];
            require(area.cluster == uint256(0), "TheWallCore: Can't transfer area owned by cluster");
        }
        return token.tt;
    }

    function _isOrdinaryArea(uint256 areaId) public view
    {
        Token storage token = _tokens[areaId];
        require(token.tt == TokenType.Area, "TheWallCore: Token is not area");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: Unordinary status");
        Area memory area = _areas[areaId];
        require(area.cluster == uint256(0), "TheWallCore: Area is owned by cluster");
    }

    function _areasInCluster(uint256 clusterId) public view returns(uint256[] memory)
    {
        return _clusters[clusterId].areas;
    }

    function _forSale(uint256 tokenId, uint256 priceWei) onlyTheWall public
    {
        _canBeTransferred(tokenId);
        Token storage token = _tokens[tokenId];
        token.cost = priceWei;
        token.status = Status.ForSale;
    }

    function _forRent(uint256 tokenId, uint256 priceWei, uint256 durationSeconds) onlyTheWall public
    {
        _canBeTransferred(tokenId);
        Token storage token = _tokens[tokenId];
        token.cost = priceWei;
        token.status = Status.ForRent;
        token.rentDuration = durationSeconds;
    }

    function _createCluster(uint256 tokenId, string memory title) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        token.tt = TokenType.Cluster;
        token.status = Status.None;
        token.title = title;

        Cluster storage cluster = _clusters[tokenId];
        cluster.revision = 1;
    }

    function _removeCluster(uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt == TokenType.Cluster, "TheWallCore: no cluster found for remove");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: can't remove rented cluster");

        Cluster storage cluster = _clusters[tokenId];
        for(uint i=0; i<cluster.areas.length; ++i)
        {
            uint256 areaId = cluster.areas[i];
            
            Token storage areaToken = _tokens[areaId];
            areaToken.status = token.status;
            areaToken.link = token.link;
            areaToken.tags = token.tags;
            areaToken.title = token.title;

            Area storage area = _areas[areaId];
            area.cluster = 0;
        }
        delete _clusters[tokenId];
        delete _tokens[tokenId];
    }
    
    function _abs(int256 v) pure public returns (int256)
    {
        if (v < 0)
        {
            v = -v;
        }
        return v;
    }

    function _create(uint256 tokenId, int256 x, int256 y, uint256 clusterId, uint256 nonce) onlyTheWall public returns (uint256 revision, bytes32 hashOfSecret)
    {
        _areasOnTheWall[x][y] = tokenId;

        Token storage token = _tokens[tokenId];
        token.tt = TokenType.Area;
        token.status = Status.None;

        Area storage area = _areas[tokenId];
        area.x = x;
        area.y = y;
        if (_abs(x) <= 100 && _abs(y) <= 100)
        {
            area.premium = true;
        }
        else
        {
            area.nonce = nonce;
            area.hashOfSecret = _hashOfSecret;
        }

        revision = 0;
        if (clusterId !=0)
        {
            area.cluster = clusterId;
        
            Cluster storage cluster = _clusters[clusterId];
            cluster.revision += 1;
            revision = cluster.revision;
            cluster.areas.push(tokenId);
            cluster.areaToIndex[tokenId] = cluster.areas.length - 1;
        }
        
        return (revision, area.hashOfSecret);
    }

    function _areaOnTheWall(int256 x, int256 y) public view returns(uint256)
    {
        return _areasOnTheWall[x][y];
    }

    function _buy(address payable tokenOwner, uint256 tokenId, address me, uint256 weiAmount, uint256 revision, address payable referrerCandidate) payable onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForSale, "TheWallCore: Item is not for sale");
        require(weiAmount == token.cost, "TheWallCore: Invalid amount of wei");

        bool premium = false;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            require(area.cluster == 0, "TheWallCore: Owned by cluster area can't be sold");
            premium = _isPremium(area, tokenId);
        }
        else
        {
            require(_clusters[tokenId].revision == revision, "TheWallCore: Incorrect cluster's revision");
        }
        
        token.status = Status.None;

        uint256 fee;
        if (!premium)
        {
            fee = msg.value.mul(30).div(100);
            uint256 alreadyPayed = _processRef(me, referrerCandidate, fee);
            _fundsReceiver.sendValue(fee.sub(alreadyPayed));
        }
        tokenOwner.sendValue(msg.value.sub(fee));
    }
    
    function _rent(address payable tokenOwner, uint256 tokenId, address me, uint256 weiAmount, uint256 revision, address payable referrerCandidate) payable onlyTheWall public returns(uint256 rentDuration)
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForRent, "TheWallCore: Item is not for rent");
        require(weiAmount == token.cost, "TheWallCore: Invalid amount of wei");

        bool premium = false;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            require(area.cluster == 0, "TheWallCore: Owned by cluster area can't be rented");
            premium = _isPremium(area, tokenId);
        }
        else
        {
            require(_clusters[tokenId].revision == revision, "TheWall: Incorrect cluster's revision");
        }

        rentDuration = block.timestamp.add(token.rentDuration);
        token.status = Status.Rented;
        token.cost = 0;
        token.rentDuration = rentDuration;
        token.tenant = me;
        
        uint256 fee;
        if (!premium)
        {
            fee = msg.value.mul(30).div(100);
            uint256 alreadyPayed = _processRef(me, referrerCandidate, fee);
            _fundsReceiver.sendValue(fee.sub(alreadyPayed));
        }
        tokenOwner.sendValue(msg.value.sub(fee));

        return rentDuration;
    }

    function _isPremium(Area storage area, uint256 tokenId) internal returns(bool)
    {
        if (area.hashOfSecret != bytes32(0))
        {
            uint256 secret = _secrets[area.hashOfSecret];
            if (secret != 0)
            {
                uint256 factor = uint256(keccak256(abi.encodePacked(secret, tokenId, area.nonce)));
                area.premium = ((factor % 1000) == 1);
                area.hashOfSecret = bytes32(0);
            }
        }
        return area.premium;
    }

    function _rentTo(uint256 tokenId, address tenant, uint256 durationSeconds) onlyTheWall public returns(uint256 rentDuration)
    {
        _canBeTransferred(tokenId);
        rentDuration = block.timestamp.add(durationSeconds);
        Token storage token = _tokens[tokenId];
        token.status = Status.Rented;
        token.cost = 0;
        token.rentDuration = rentDuration;
        token.tenant = tenant;
        return rentDuration;
    }

    function _cancel(uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForRent || token.status == Status.ForSale, "TheWallCore: item is not for rent or for sale");
        token.cost = 0;
        token.status = Status.None;
        token.rentDuration = 0;
    }
    
    function _finishRent(address who, uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.tenant == who, "TheWall: Only tenant can finish rent");
        require(token.status == Status.Rented && token.rentDuration > block.timestamp, "TheWallCore: item is not rented");
        token.status = Status.None;
        token.rentDuration = 0;
        token.cost = 0;
        token.tenant = address(0);
    }
    
    function _addToCluster(address me, address areaOwner, address clusterOwner, uint256 areaId, uint256 clusterId) onlyTheWall public returns(uint256 revision)
    {
        require(areaOwner == clusterOwner, "TheWallCore: Area and Cluster have different owners");
        require(areaOwner == me, "TheWallCore: Can be called from owner only");

        Token storage areaToken = _tokens[areaId];
        Token storage clusterToken = _tokens[clusterId];
        require(areaToken.tt == TokenType.Area, "TheWallCore: Area not found");
        require(clusterToken.tt == TokenType.Cluster, "TheWallCore: Cluster not found");
        require(areaToken.status != Status.Rented || areaToken.rentDuration < block.timestamp, "TheWallCore: Area is rented");
        require(clusterToken.status != Status.Rented || clusterToken.rentDuration < block.timestamp, "TheWallCore: Cluster is rented");

        Area storage area = _areas[areaId];
        require(area.cluster == 0, "TheWallCore: Area already in cluster");
        area.cluster = clusterId;
        
        areaToken.status = Status.None;
        areaToken.rentDuration = 0;
        areaToken.cost = 0;
        
        Cluster storage cluster = _clusters[clusterId];
        cluster.revision += 1;
        cluster.areas.push(areaId);
        cluster.areaToIndex[areaId] = cluster.areas.length - 1;
        return cluster.revision;
    }

    function _removeFromCluster(address me, address areaOwner, address clusterOwner, uint256 areaId, uint256 clusterId) onlyTheWall public returns(uint256 revision)
    {
        require(areaOwner == clusterOwner, "TheWallCore: Area and Cluster have different owners");
        require(areaOwner == me, "TheWallCore: Can be called from owner only");

        Token storage areaToken = _tokens[areaId];
        Token storage clusterToken = _tokens[clusterId];
        require(areaToken.tt == TokenType.Area, "TheWallCore: Area not found");
        require(clusterToken.tt == TokenType.Cluster, "TheWallCore: Cluster not found");
        require(clusterToken.status != Status.Rented || clusterToken.rentDuration < block.timestamp, "TheWallCore: Cluster is rented");

        Area storage area = _areas[areaId];
        require(area.cluster == clusterId, "TheWallCore: Area is not in cluster");
        area.cluster = 0;

        Cluster storage cluster = _clusters[clusterId];
        cluster.revision += 1;
        uint index = cluster.areaToIndex[areaId];
        if (index != cluster.areas.length - 1)
        {
            uint256 movedAreaId = cluster.areas[cluster.areas.length - 1];
            cluster.areaToIndex[movedAreaId] = index;
            cluster.areas[index] = movedAreaId;
        }
        delete cluster.areaToIndex[areaId];
        cluster.areas.pop();
        return cluster.revision;
    }

    function _canBeManaged(address who, address owner, uint256 tokenId) internal view returns (TokenType t)
    {
        Token storage token = _tokens[tokenId];
        t = token.tt;
        require(t != TokenType.Unknown, "TheWallCore: No token found");
        if (t == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            if (area.cluster != uint256(0))
            {
                token = _tokens[area.cluster];
                require(token.tt == TokenType.Cluster, "TheWallCore: No cluster token found");
            }
        }
        
        if (token.status == Status.Rented && token.rentDuration > block.timestamp)
        {
            require(who == token.tenant, "TheWallCore: Rented token can be managed by tenant only");
        }
        else
        {
            require(who == owner, "TheWallCore: Only owner can manager token");
        }
    }

    function _setContent(address who, address owner, uint256 tokenId, bytes memory content) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.content = content;
    }

    function _setImage(address who, address owner, uint256 tokenId, bytes memory image) onlyTheWall public
    {
        TokenType tt = _canBeManaged(who, owner, tokenId);
        require(tt == TokenType.Area, "TheWallCore: Image can be set to area only");
        Area storage area = _areas[tokenId];
        area.image = image;
    }

    function _setLink(address who, address owner, uint256 tokenId, string memory link) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.link = link;
    }

    function _setTags(address who, address owner, uint256 tokenId, string memory tags) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.tags = tags;
    }

    function _setTitle(address who, address owner, uint256 tokenId, string memory title) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.title = title;
    }

    function tokenInfo(uint256 tokenId) public view returns(bytes memory, string memory, string memory, string memory, bytes memory)
    {
        Token memory token = _tokens[tokenId];
        bytes memory image;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            image = area.image;
        }
        return (image, token.link, token.tags, token.title, token.content);
    }

    function _canBeCreated(int256 x, int256 y) view public
    {
        require(_abs(x) < _wallWidth && _abs(y) < _wallHeight, "TheWallCore: Out of wall");
        require(_areaOnTheWall(x, y) == uint256(0), "TheWallCore: Area is busy");
    }

    function _processPaymentCreate(address me, uint256 weiAmount, uint256 areasNum, address payable referrerCandidate) onlyTheWall public payable returns(uint256)
    {
        uint256 usedCoupons = _useCoupons(me, areasNum);
        areasNum -= usedCoupons;
        return _processPayment(me, weiAmount, areasNum, referrerCandidate);
    }
    
    function _processPayment(address me, uint256 weiAmount, uint256 itemsAmount, address payable referrerCandidate) internal returns (uint256)
    {
        uint256 payValue = _costWei.mul(itemsAmount);
        require(payValue <= weiAmount, "TheWallCore: Invalid amount of wei");
        if (weiAmount > payValue)
        {
            payable(me).sendValue(weiAmount.sub(payValue));
        }
        if (payValue > 0)
        {
            uint256 alreadyPayed = _processRef(me, referrerCandidate, payValue);
            _fundsReceiver.sendValue(payValue.sub(alreadyPayed));
        }
        return payValue;
    }

    function _canBeCreatedMulti(int256 x, int256 y, int256 width, int256 height) view public
    {
        require(_abs(x) < _wallWidth &&
                _abs(y) < _wallHeight &&
                _abs(x.add(width)) < _wallWidth &&
                _abs(y.add(height)) < _wallHeight,                
                "TheWallCpre: Out of wall");
        require(width > 0 && height > 0, "TheWallCore: dimensions must be greater than zero");
    }

    function _buyCoupons(address me, uint256 weiAmount, address payable referrerCandidate) public payable onlyTheWall returns (uint256)
    {
        uint256 couponsAmount = weiAmount.div(_costWei);
        uint payValue = _processPayment(me, weiAmount, couponsAmount, referrerCandidate);
        if (payValue > 0)
        {
            _giveCoupons(me, couponsAmount);
        }
        return payValue;
    }
    
    function _clusterOf(uint256 tokenId) view public returns (uint256)
    {
        return _areas[tokenId].cluster;
    }
}