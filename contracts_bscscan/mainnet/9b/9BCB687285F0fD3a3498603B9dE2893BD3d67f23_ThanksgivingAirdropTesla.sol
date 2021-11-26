/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    address private _potentialOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerNominated(address potentialOwner);

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
     * @dev Returns the address of the current potentialOwner.
     */
    function potentialOwner() public view returns (address) {
        return _potentialOwner;
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

    function nominatePotentialOwner(address newOwner) public virtual onlyOwner {
        _potentialOwner = newOwner;
        emit OwnerNominated(newOwner);
    }

    function acceptOwnership () public virtual {
        require(msg.sender == _potentialOwner, 'You must be nominated as potential owner before you can accept ownership');
        emit OwnershipTransferred(_owner, _potentialOwner);
        _owner = _potentialOwner;
        _potentialOwner = address(0);
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function exists(uint256 tokenId) external view returns (bool);
}

contract ThanksgivingAirdropTesla is Ownable {
    using Address for address;
    using SafeMath for uint256;

    struct Participant {
        address nftAddress;
        uint256 startTokenId;
        uint256 endTokenId;
        uint256 weight;
    }
    Participant[] public participants;
    uint256 public totalWeight;

    address public winnerNFTAddress;
    uint256 public winnerNFTTokenId;

    event AddParticipantList(address indexed _nftAddress, uint256 indexed _startTokenId, uint256 indexed _endTokenId);
    event RemoveParticipantList(uint256 _index);
    event DrawLottery(address indexed _nftAddress, uint256 indexed _tokenId);

    constructor() {
        // MPB
        participants.push(Participant({
            nftAddress: address(0x061C6eECA7B14cF4eC1B190Dd879008DD7d7E470),
            startTokenId: 0,
            endTokenId: 999,
            weight: 999 - 0 + 1
        }));
        participants.push(Participant({
            nftAddress: address(0x061C6eECA7B14cF4eC1B190Dd879008DD7d7E470),
            startTokenId: 1200,
            endTokenId: 1299,
            weight: 1299 - 1200 + 1
        }));
        participants.push(Participant({
        nftAddress: address(0x061C6eECA7B14cF4eC1B190Dd879008DD7d7E470),
            startTokenId: 1800,
            endTokenId: 2009,
            weight: 2009 - 1800 + 1
        }));
        participants.push(Participant({
            nftAddress: address(0x061C6eECA7B14cF4eC1B190Dd879008DD7d7E470),
            startTokenId: 5500,
            endTokenId: 5599,
            weight: 5599 - 5500 + 1
        }));
        participants.push(Participant({
            nftAddress: address(0x061C6eECA7B14cF4eC1B190Dd879008DD7d7E470),
            startTokenId: 2030,
            endTokenId: 2049,
            weight: 2049 - 2030 + 1
        }));

        // SR Kiss-up Dog
        participants.push(Participant({
        nftAddress: address(0xca109033175298D0019B8F1b7b14AcA0A299680f),
            startTokenId: 7149,
            endTokenId: 7001,
            weight: 7149 - 7001 + 1
        }));

        // SSR Kiss-up Dog
        participants.push(Participant({
            nftAddress: address(0x203515178c95688CA033699942337f04454696aC),
            startTokenId: 7000,
            endTokenId: 7000,
            weight: 7000 - 7000 + 1
        }));

        // R Metamon
        participants.push(Participant({
            nftAddress: address(0x982B5345D0f213ecb2a8e6e24336909f59B1d6E3),
            startTokenId: 100220,
            endTokenId: 107939,
            weight: 107939 - 100220 + 1
        }));
        participants.push(Participant({
            nftAddress: address(0x982B5345D0f213ecb2a8e6e24336909f59B1d6E3),
            startTokenId: 119120,
            endTokenId: 120219,
            weight: 120219 - 119120 + 1
        }));
        participants.push(Participant({
            nftAddress: address(0x982B5345D0f213ecb2a8e6e24336909f59B1d6E3),
            startTokenId: 119060,
            endTokenId: 119089,
            weight: 119089 - 119060 + 1
        }));

        // SR Metamon
        participants.push(Participant({
            nftAddress: address(0xf278dcAe8E18E1D162Ed95bD9FF6cE8aaaBB4EE2),
            startTokenId: 100020,
            endTokenId: 100069,
            weight: 100069 - 100020 + 1
        }));
        participants.push(Participant({
            nftAddress: address(0xf278dcAe8E18E1D162Ed95bD9FF6cE8aaaBB4EE2),
            startTokenId: 100120,
            endTokenId: 100175,
            weight: 100175 - 100120 + 1
        }));

        // SSR Metamon
        participants.push(Participant({
            nftAddress: address(0x280825cd4872ECBA941416EAccDaA3F4d9Bf6EA7),
            startTokenId: 100003,
            endTokenId: 100003,
            weight: 100003 - 100003 + 1
        }));

        for (uint256 i = 0; i < participants.length; i++) {
            totalWeight = totalWeight + participants[i].weight;
        }
    }

    function addParticipantList(address _nftAddress, uint256 _startTokenId, uint256 _endTokenId) external onlyOwner {
        uint256 weight = _endTokenId - _startTokenId + 1;
        participants.push(Participant({
            nftAddress: _nftAddress,
            startTokenId: _startTokenId,
            endTokenId: _endTokenId,
            weight: weight
        }));
        totalWeight = totalWeight + weight;

        emit AddParticipantList(_nftAddress, _startTokenId, _endTokenId);
    }

    function removeParticipantList(uint256 _index) external onlyOwner {
        require(_index < participants.length, "index out of list length");
        participants[_index] = participants[participants.length - 1];
        participants.pop();

        emit RemoveParticipantList(_index);
    }

    function drawLottery() external onlyOwner {
        bool getWinner = false;
        while (!getWinner) {
            uint256 seed = block.timestamp;
            uint256 winnerIdx = genRandom(seed);
            for (uint256 i = 0; i < participants.length; i++) {
                if (winnerIdx + 1 > participants[i].weight) {
                    winnerIdx = winnerIdx - participants[i].weight;
                } else {
                    IERC721 nft = IERC721(participants[i].nftAddress);
                    uint256 tokenId = participants[i].startTokenId + winnerIdx;
                    if (!nft.exists(tokenId)) {
                        break;
                    }
                    address owner = nft.ownerOf(tokenId);
                    if (Address.isContract(owner) && owner != 0xEF0Dff2D82B09c6A9fB9Cd261B3FcBb7b0560b28) {
                        break;
                    }
                    if (owner == 0x4A8b627E54f3B51A91a04a40D7a7cD56e65f9C06 || owner == 0x2ff783343F1d9AACA6255446761D119f88333f5F
                    || owner == 0x5A160aC2d3A090d1a2a3aEE9b0a83A1251a4e3eC || owner == 0xc99e4E934f1dDd2E3E03FfE38Fe862aB5d6139BE) {
                        break;
                    }
                    winnerNFTAddress = participants[i].nftAddress;
                    winnerNFTTokenId = tokenId;
                    getWinner = true;
                    break;
                }
            }
            seed = seed + block.timestamp;
        }
        emit DrawLottery(winnerNFTAddress, winnerNFTTokenId);
    }

    function genRandom(uint256 _seed) private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, _msgSender(), block.difficulty, _seed))) % totalWeight;
    }

}