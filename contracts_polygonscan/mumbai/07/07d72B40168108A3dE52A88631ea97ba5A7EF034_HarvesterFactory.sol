// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //重入保护
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IFactory.sol";


// LIBRARIES //

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}


//
contract HarvesterFactory is Ownable, ReentrancyGuard, IFactory {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    event OnAddOperator(address operator);

    event OnGeneMetaData(
        uint indexed tokenId,
        address owner,
        uint256 _energy_efficiency, 
        uint256 _uru_efficiency, 
        uint256 _max_durability,
        string metadata
    );

    event OnAllowUpgrade (
        uint indexed tokenId,
        address owner,
        uint256 _energy_efficiency, 
        uint256 _uru_efficiency, 
        uint256 _max_durability
    );

    event OnUpgradeHarvester (
        uint indexed oldId,
        uint indexed newId,
        address owner,
        uint256 _energy_efficiency, 
        uint256 _uru_efficiency, 
        uint256 _max_durability,
        string metadata
    );

    //是否允许升级
    struct UpgradeCharacter {
        uint256 energy_efficiency;   //源晶采集效率
        uint256 uru_efficiency;      //钨矿采集效率
        uint256 max_durability;      //最大耐久度    
        bool isAllow;              
    }

    mapping(bytes32 => UpgradeCharacter) private allowUpgrades;

    //拥有者地址与数量的映射
    mapping(address => uint256) private ownerCount;

    //内部自增计数器与拥有者地址的映射
    mapping(uint256  => address) private itemIdOwners;

    string internal nftNameHarvester = "MetaGlobe Harvester NFT";
    
    struct Character {
        uint256 energy_efficiency;   //源晶采集效率
        uint256 uru_efficiency;      //钨矿采集效率
        uint256 max_durability;      //最大耐久度
        uint256 itemId;               //内部自增计数器id
    }

    Counters.Counter private _itemIds;

    mapping(uint256 => Character) characters;

    //token_id 与 item_id的映射
    mapping(uint256 => uint256) harvesterHolders;

    uint256 internal randomResult;

    //操作员数组
    mapping(address => bool) private operators;

    /**
    * @dev ensure collector pays for mint token
    */
    modifier isOperator() {
       require(operators[msg.sender], "Sender is not an operator.");
        _;
    }    
    
   // 合约部署者增加操作员
    function addOperator(address _operator) external nonReentrant onlyOwner returns(bool){
        require(_operator != address(0), "operator is the zero address"); 

        operators[_operator] = true;
        emit OnAddOperator(_operator);
        return true;
    }

    // 合约部署者移除操作员
    function removeOperator(address _operator) external nonReentrant onlyOwner returns(bool){
        require(_operator != address(0), "operator is the zero address"); 

        operators[_operator] = false;

        return true;
    }

    receive() external payable {}

    fallback() external payable {}
  
    function setRandomNumber(uint256 _seed) public onlyOwner returns (bool) {
        randomResult = _seed;
        return true;
    }
    
    /**
     * @dev impletement IFactory
     *
     * Returns metadata whether the operation succeeded.
     *
     */
    function geneMetaData(address owner, uint256 _id, string memory _imageUrl) external override returns (uint256[] memory, string memory){
        // require(operators[msg.sender], "Sender is not an operator.");

        uint256 energy_efficiency = 100;
        uint256 uru_efficiency = 100;
        uint256 max_durability = 100;

        randomResult = uint256(keccak256(abi.encode(block.timestamp, randomResult)));

        //先随机选出哪一个为保底
        uint rand = uint256(keccak256(abi.encode(randomResult, 1))) % 3; // 0,1,2

        if (rand == 0) {
            uru_efficiency = ((uint256(keccak256(abi.encode(randomResult, 2))) % 100) * 70 + 3000) / 100; 
            max_durability = ((uint256(keccak256(abi.encode(randomResult, 3))) % 100) * 70 + 3000) / 100; 
            energy_efficiency  = 300 - uru_efficiency - max_durability;
        } else if (rand == 1) {
            energy_efficiency = ((uint256(keccak256(abi.encode(randomResult, 2))) % 100) * 70 + 3000) / 100; 
            max_durability = ((uint256(keccak256(abi.encode(randomResult, 3))) % 100) * 70 + 3000) / 100; 
            uru_efficiency = 300 - energy_efficiency - max_durability;
        } else if (rand == 2) {
            energy_efficiency = ((uint256(keccak256(abi.encode(randomResult, 2))) % 100) * 70 + 3000) / 100; 
            uru_efficiency = ((uint256(keccak256(abi.encode(randomResult, 3))) % 100) * 70 + 3000) / 100; 
            max_durability = 300 - energy_efficiency - uru_efficiency;
        }

        uint[] memory result = new uint[](3);  
        result[0] = energy_efficiency;
        result[1] = uru_efficiency;
        result[2] = max_durability;
        
        _itemIds.increment();
        itemIdOwners[_itemIds.current()] = owner;
        ownerCount[owner] ++;
        harvesterHolders[_itemIds.current()] = _id;

        characters[_id] = Character(
                energy_efficiency,
                uru_efficiency,
                max_durability,
                _itemIds.current()
        );

        string memory json = string(abi.encodePacked('{"name": ', nftNameHarvester, '", "description": "Harvester for meta globe game", "attributes": [{"trait_type": "Energy Efficiency", "value":', energy_efficiency, '}, {"trait_type": "Uru Efficiency", "value":', uru_efficiency, '}, {"trait_type": "Max Durability", "value":', max_durability, '}]'));
        json = Base64.encode(bytes(string(abi.encodePacked(json, ', "image":', _imageUrl, '"}'))));
        
        emit OnGeneMetaData(_id, owner, energy_efficiency, uru_efficiency, max_durability, json);
        return (result, json);
    }

    /**
     * @dev upgrade meta data 
     *
     * Returns a string value whether the operation succeeded.
     *
     */
    function upgradeMetaData(address owner, uint256 oldId, uint256 newId, string memory _imageUrl) external override returns (uint256[] memory, string memory) {
        // require(operators[msg.sender], "Sender is not an operator.");
        bytes32 hash = keccak256(abi.encodePacked(owner, address(this), oldId));

        require(allowUpgrades[hash].isAllow == true, "Not Allow");

        uint256 energy_efficiency = characters[oldId].energy_efficiency + allowUpgrades[hash].energy_efficiency;
        uint256 uru_efficiency = characters[oldId].uru_efficiency + allowUpgrades[hash].uru_efficiency;
        uint256 max_durability = characters[oldId].max_durability + allowUpgrades[hash].max_durability;

        allowUpgrades[hash].energy_efficiency = 0;
        allowUpgrades[hash].uru_efficiency = 0;
        allowUpgrades[hash].max_durability = 0;
        allowUpgrades[hash].isAllow = false;


        uint[] memory result = new uint[](3);  
        result[0] = energy_efficiency;
        result[1] = uru_efficiency;
        result[2] = max_durability;
        
        _itemIds.increment();
        itemIdOwners[_itemIds.current()] = owner;
        itemIdOwners[characters[oldId].itemId] = address(0x0); //将旧的编号拥有者设置为0地址
        // ownerCount[owner] ++; //不需要增加
        harvesterHolders[_itemIds.current()] = newId;

        characters[newId] = Character(
                energy_efficiency,
                uru_efficiency,
                max_durability,
                _itemIds.current()
        );

        string memory json = string(abi.encodePacked('{"name": ', nftNameHarvester, '", "description": "Harvester for meta globe game", "attributes": [{"trait_type": "Energy Efficiency", "value":', energy_efficiency, '}, {"trait_type": "Uru Efficiency", "value":', uru_efficiency, '}, {"trait_type": "Max Durability", "value":', max_durability, '}]'));
        json = Base64.encode(bytes(string(abi.encodePacked(json, ', "image":', _imageUrl, '"}'))));
        
        emit OnUpgradeHarvester(oldId, newId, owner, energy_efficiency, uru_efficiency, max_durability, json);

        return (result, json);
    }

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

    //操作员设置采集器升级许可及升级的数值
    function setAllowUpgrades(address owner, uint tokenId, uint256 _energy_efficiency, uint256 _uru_efficiency, uint256 _max_durability)       
            public
            nonReentrant
            isOperator
            returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(owner, address(this), tokenId));

        allowUpgrades[hash].energy_efficiency = _energy_efficiency;
        allowUpgrades[hash].uru_efficiency = _uru_efficiency;
        allowUpgrades[hash].max_durability = _max_durability;
        allowUpgrades[hash].isAllow = true;
        emit OnAllowUpgrade(tokenId, owner, _energy_efficiency, _uru_efficiency, _max_durability);
        return true;
    }

    //获取采集器NFT属性状态
    function getCharacterStats(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            characters[tokenId].energy_efficiency,
            characters[tokenId].uru_efficiency,
            characters[tokenId].max_durability
        );
    }

    // 获取用户拥有的采集器列表， 可用于游戏
    function getHarvesterListByOwner(address owner) public view returns (uint[] memory) {
      // 为了节省gas消耗 在内存中创建结果数组方法之后完后就会销毁
      uint count = ownerCount[owner];
      uint[] memory result = new uint[](count);
      
      uint counter = 0;
      for (uint i = 1; i < _itemIds.current() + 1; i++) {
          if (itemIdOwners[i] == owner) {
              result[counter] = harvesterHolders[i];
              counter++;
          }
      }
      return result;
   }
   
    /**
    * @dev withdraw ether to owner/admin wallet
    * @notice only owner can call this method
    */
    function withdraw() public onlyOwner returns(bool){
        payable(msg.sender).transfer(address(this).balance);
        return true; 
    }

    constructor(uint256 _seed) {
        randomResult = _seed;
        operators[msg.sender] = true;  //将部署者设置为操作员
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev Interface of the IFactory for meta globe nfts
 */
interface IFactory {

    /**
     * @dev Generate meta data from a seed
     *
     * Returns a string value whether the operation succeeded.
     *
     */
    function geneMetaData(address owner,uint256 _id, string memory _imageUrl) external returns (uint256[] memory, string memory);

    /**
     * @dev upgrade meta data 
     *
     * Returns a string value whether the operation succeeded.
     *
     */
    function upgradeMetaData(address owner, uint256 oldId, uint256 newId, string memory _imageUrl) external returns (uint256[] memory, string memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}