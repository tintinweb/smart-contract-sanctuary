/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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


// File @openzeppelin/contracts/math/[email protected]



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


// File contracts/ILootSkinMintable.sol



pragma solidity 0.6.12;

interface ILootSkinMintable {
    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) external;

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;
}


// File contracts/StartingMint.sol



pragma solidity 0.6.12;



contract StartingMint is Ownable {
    using SafeMath for uint256;

    //remaining box to public sale
    uint256 public publicAvailable;
    //remaining box which owner can mint
    uint256 public privateAvailable;

    //ETH per box
    uint256 public price = 0.05 ether;

    uint256 public startTime;

    //1. In the opening phase, 8 skins can be randomly opened for each box
    uint256 public skinsInBox = 8;
    //2. Total number of skins
    uint256 public allSkins = 119;
    //3. randomly skin id in (baseId + 0) to (baseId+allSkins) and
    //4. randomly number will be generated by the segments of hash
    uint256 public baseId = 1;
    bytes32 mask4 =
        0xffffffff00000000000000000000000000000000000000000000000000000000;

    ILootSkinMintable public lootSkin;

    constructor(ILootSkinMintable _lootSkin) public {
        lootSkin = _lootSkin;
    }

    function claim() public payable onlyEOA {
        require(startTime > 0 && block.timestamp > startTime, "not start");
        require(publicAvailable > 0, "mint out");
        //pay eth
        require(msg.value == price, "invalid value");
        _claim(msg.sender);
        publicAvailable = publicAvailable.sub(1);
    }

    function ownerClaim(address _receiveAddress) public onlyOwner {
        require(privateAvailable > 0, "private mint out");
        _claim(_receiveAddress);
        privateAvailable = privateAvailable.sub(1);
    }

    function _claim(address _receiveAddress) internal {
        _mintLoot(_receiveAddress);
    }

    function _mintLoot(address _receiveAddress) internal {
        bytes32 seed = keccak256(abi.encode(_receiveAddress, block.number));
        //value is available id
        uint256[] memory availableIds = new uint256[](allSkins);
        uint256 length = availableIds.length;
        //result, user will get $skinsInBox skins
        uint256[] memory selectedIds = new uint256[](skinsInBox);
        uint256[] memory amounts = new uint256[](skinsInBox);

        for (uint256 i = 0; i < skinsInBox; i++) {
            //offset 4 bytes very time to generate random id
            bytes4 n = bytes4((seed << (i * 4 * 8)) & mask4);
            uint256 index = uint32(n) % length;
            uint256 value;

            if (availableIds[index] == 0) {
                value = index;
            } else {
                value = availableIds[index];
            }

            if (availableIds[length - 1] == 0) {
                availableIds[index] = length - 1;
            } else {
                availableIds[index] = availableIds[length - 1];
            }

            selectedIds[i] = baseId + value;
            amounts[i] = 1;

            length--;
        }
        //batch mint
        lootSkin.mintBatch(_receiveAddress, selectedIds, amounts, "");
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "only EOA");
        _;
    }

    function setMintLootParams(
        uint256 _allSkins,
        uint256 _skinsInBox,
        uint256 _baseId
    ) public onlyOwner {
        allSkins = _allSkins;
        skinsInBox = _skinsInBox;
        baseId = _baseId;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setAvailable(uint256 _publicAvailable, uint256 _privateAvailable)
        public
        onlyOwner
    {
        publicAvailable = _publicAvailable;
        privateAvailable = _privateAvailable;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        require(startTime == 0, "can not reset");
        require(block.timestamp < _startTime, "invilid startTime");
        startTime = _startTime;
    }

    function withdraw(
        address _to,
        address _token,
        uint256 _value
    ) public onlyOwner {
        if (_token == address(0)) {
            (bool success, ) = _to.call{value: _value}(new bytes(0));
            require(success, "!safeTransferETH");
        } else {
            // bytes4(keccak256(bytes('transfer(address,uint256)')));
            (bool success, bytes memory data) = _token.call(
                abi.encodeWithSelector(0xa9059cbb, _to, _value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "!safeTransfer"
            );
        }
    }
}