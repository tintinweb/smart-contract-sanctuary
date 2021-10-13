/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// File: @openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin\contracts\utils\Address.sol



pragma solidity >=0.6.2 <0.8.0;

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

// File: node_modules\@openzeppelin\contracts\utils\Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts\ICryptoDogeNFT.sol



pragma solidity ^0.7.6;
pragma abicoder v2;

interface ICryptoDogeNFT{
    function balanceOf(address owner) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function getdoger(uint256 _tokenId) external view returns(
        uint256 _generation,
        uint256 _tribe,
        uint256 _exp,
        uint256 _dna,
        uint256 _farmTime,
        uint256 _bornTime
    );
    function getSale(uint256 _tokenId) external view returns(
        uint256 tokenId,
        address owner,
        uint256 price
    );
    function isEvolved(uint256 _tokenId) external view returns(bool);
    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns(uint256);
    function layDoge(address receiver, uint8[] memory tribe) external;
    function priceDoge() external returns(uint256);
    function evolve(uint256 _tokenId, address _owner, uint256 _dna) external;
    function getRare(uint256 _tokenId) external view returns(uint256);
    function exp(uint256 _tokenId, uint256 rewardExp) external;
    function dogerLevel(uint256 _tokenId) external view returns(uint256);
    function tokenByIndex(uint256 _tokenId) external view returns(uint256);
    function orders(address _owner) external view returns(uint256);
    function marketsSize() external view returns(uint256);
    function tokenSaleOfOwnerByIndex(address _owner, uint256 index) external view returns(uint256);
    function tokenSaleByIndex(uint256 index) external view returns(uint256);
    function setApprovalForAll(address operator, bool approved) external;
    function firstPurchaseTime(address _address) external view returns(uint256);
    function manager() external view returns(address);
    function setFirstPurchaseTime(address _address, uint256 _firstPurchaseTime) external;
    function setClassInfo(uint256 _tokenId, uint256 _classInfo) external;
    function totalSupply() external view returns(uint256);
    function getClaimTokenAmount(address _address) external view returns(uint256);
    function updateClaimTokenAmount(address _address, uint256 _newAmount) external;
}

// File: contracts\IMagicStoneNFT.sol



pragma solidity ^0.7.6;

interface IMagicStoneNFT{
    function createStone(address receiver) external;
    function priceStone() external view returns (uint256);
    function burn(uint256 _tokenId, address _address) external;
    function ownerOf(uint256 _tokenId) external view returns(address);
    function balanceOf(address _address) external view returns(uint256);
    function tokenOfOwnerByIndex(address _address, uint256 _index) external view returns(uint256);
    function totalSupply() external view returns(uint256);
}

// File: contracts\MarketController.sol



pragma solidity ^0.7.6;






interface ICryptoDogeController{
    function getClassInfo(uint256 _tokenId) external view returns(uint256);
    function battleTime(uint256 _tokenId) external view returns(uint256);
    function setStoneTime(uint256 _tokenId) external view returns(uint256);
    function cooldownTime() external view returns(uint256);
    function stoneInfo(uint256 _tokenId) external view returns(uint256);
}

interface IMagicStoneController{
    function stoneDogeInfo(uint256 _tokenId) external view returns(uint256);
}
contract MarketController is Ownable{

    struct Doge{
        uint256 _tokenId;
        uint256 _generation;
        uint256 _tribe;
        uint256 _exp;
        uint256 _dna;
        uint256 _farmTime;
        uint256 _bornTime;
        uint256 _rare;
        uint256 _level;
        bool _isEvolved;
        uint256 _salePrice;
        address _owner;
        uint256 _classInfo;
        uint256 _availableBattleTime;
        uint256 _stoneInfo;
    }

    struct Stone{
        uint256 _tokenId;
        uint256 _dogeId;
    }

    address public cryptoDogeNFT;
    address public cryptoDogeController;
    address public magicStoneNFT;
    address public magicStoneController;
    
    constructor (){
        cryptoDogeNFT = address(0xE4de8D81dE25353E7959e901c279f083e1BD44C4);
        cryptoDogeController = address(0xE6E60f98e4073252429027f758eC00927F6d2952);
        magicStoneNFT = address(0xCC1D2FC72C4b7838e45Ef64cfA87470b4A98D839);
        magicStoneController = address(0xdB58FC5a3F65d8649D90677F80b8bC11B7d43e09);
    }

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
    }

    function setCryptoDogeController(address _address) public onlyOwner{
        cryptoDogeController = _address;
    }
    
    function setMagicStoneNFT(address _nftAddress) public onlyOwner{
        magicStoneNFT = _nftAddress;
    }

    function setMagicStoneController(address _address) public onlyOwner{
        magicStoneController = _address;
    }

    function getDogesInfo(uint256[] memory ids) public view returns(Doge[] memory){
        uint256 totalDoges = ids.length;
        Doge[] memory doges= new Doge[](totalDoges);
        for(uint256 i = 0; i < totalDoges; i ++){
            doges[i]._tokenId = ids[i];
            (uint256 _generation, uint256 _tribe, uint256 _exp, uint256 _dna, uint256 _farmTime, uint256 _bornTime) = ICryptoDogeNFT(cryptoDogeNFT).getdoger(ids[i]);
            doges[i]._generation = _generation;
            doges[i]._tribe = _tribe;
            doges[i]._exp = _exp;
            doges[i]._dna = _dna;
            doges[i]._farmTime = _farmTime;
            doges[i]._bornTime = _bornTime;
            doges[i]._rare = ICryptoDogeNFT(cryptoDogeNFT).getRare(ids[i]);
            doges[i]._level = ICryptoDogeNFT(cryptoDogeNFT).dogerLevel(ids[i]);
            doges[i]._isEvolved = ICryptoDogeNFT(cryptoDogeNFT).isEvolved(ids[i]);
            (, address owner, uint256 price) = ICryptoDogeNFT(cryptoDogeNFT).getSale(ids[i]);
            if(owner != address(0))
                doges[i]._owner = owner;
            else
                doges[i]._owner = ICryptoDogeNFT(cryptoDogeNFT).ownerOf(ids[i]);
            doges[i]._salePrice = price;
            doges[i]._classInfo = ICryptoDogeController(cryptoDogeController).getClassInfo(ids[i]);
            doges[i]._availableBattleTime = ICryptoDogeController(cryptoDogeController).battleTime(ids[i]) + ICryptoDogeController(cryptoDogeController).cooldownTime();
            doges[i]._stoneInfo = ICryptoDogeController(cryptoDogeController).stoneInfo(ids[i]);
        }
        return doges;
    }

    function getDogeOfSaleByOwner() public view returns(Doge[] memory){
        uint256 totalDoges = ICryptoDogeNFT(cryptoDogeNFT).orders(msg.sender);
        uint256[] memory ids = new uint256[](totalDoges);
        uint256 i = 0;
        for(; i < totalDoges; i ++){
            ids[i] = ICryptoDogeNFT(cryptoDogeNFT).tokenSaleOfOwnerByIndex(msg.sender, i);
        }
        return getDogesInfo(ids);
    }

    function getDogeOfSale() public view returns(Doge[] memory){
        uint256 totalDoges = ICryptoDogeNFT(cryptoDogeNFT).marketsSize();
        uint256[] memory ids = new uint256[](totalDoges);
        uint256 i = 0;
        for(; i < totalDoges; i ++){
            ids[i] = ICryptoDogeNFT(cryptoDogeNFT).tokenSaleByIndex(i);
        }
        return getDogesInfo(ids);
    }
    
    function getDogeByOwner() public view returns(Doge[] memory){
        uint256 totalDoges = ICryptoDogeNFT(cryptoDogeNFT).balanceOf(msg.sender);
        uint256[] memory ids = new uint256[](totalDoges);
        uint256 i = 0;
        for(; i < totalDoges; i ++){
            ids[i] = ICryptoDogeNFT(cryptoDogeNFT).tokenOfOwnerByIndex(msg.sender, i);
        }
        return getDogesInfo(ids);
    }

    function getStonesInfo(uint256[] memory ids) public view returns(Stone[] memory){
        uint256 totalStones = ids.length;
        Stone[] memory stones= new Stone[](totalStones);
        for(uint256 i = 0; i < totalStones; i ++){
            stones[i]._tokenId = ids[i];
            stones[i]._dogeId = IMagicStoneController(magicStoneController).stoneDogeInfo(ids[i]);
        }
        return stones;
    }

    function getStoneByOwner() public view returns(Stone[] memory){
        uint256 totalStones = IMagicStoneNFT(magicStoneNFT).balanceOf(msg.sender);
        uint256[] memory ids = new uint256[](totalStones);
        uint256 i = 0;
        for(; i < totalStones; i ++){
            ids[i] = IMagicStoneNFT(magicStoneNFT).tokenOfOwnerByIndex(msg.sender, i);
        }
        return getStonesInfo(ids);
    }
}