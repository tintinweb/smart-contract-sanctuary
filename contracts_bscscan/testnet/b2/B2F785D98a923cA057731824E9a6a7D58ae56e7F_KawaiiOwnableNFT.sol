pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}

interface IKawaiiCore {
    struct KawaiiData {
        string name;
        string category;
    }

    function getKawaiiData(uint256 tokenId) external view returns (KawaiiData memory);

    function sizeOfCategory(string calldata category) external view returns (uint256);

    function getIndexListCategory(string calldata category, uint256 index) external view returns (uint256);

    function getTotalCategory(address account, string calldata category) external view returns (uint256);

}

interface IKawaiiWarehouse {
    function getLimited(address _user, string calldata _category) external view returns (uint256);

    function notTransferableNFT(uint256 _id) external view returns (bool);
}

contract KawaiiOwnableNFT {
    using SafeMath for uint256;
    struct CategoryData {
        string category;
        uint256 amount;
    }

    function isTransferable(IKawaiiCore kawaiiCore, IKawaiiWarehouse kawaiiWarehouse, address from, address to, uint256 id, uint256 amount) external view returns (bool){
        require(kawaiiWarehouse.notTransferableNFT(id) == false, "KON: Cannot transfer this NFT");
        string memory category = kawaiiCore.getKawaiiData(id).category;
        uint256 limited = kawaiiWarehouse.getLimited(to, category);
        uint256 currentHoldingNumber = kawaiiCore.getTotalCategory(to, category);
        require(limited >= currentHoldingNumber.add(amount), "KON: own exceed NFT");
        return true;
    }

    function isMintable(IKawaiiCore kawaiiCore, IKawaiiWarehouse kawaiiWarehouse, address from, address to, uint256 id, uint256 amount) external view returns (bool){
        string memory category = kawaiiCore.getKawaiiData(id).category;
        uint256 limited = kawaiiWarehouse.getLimited(to, category);
        uint256 currentHoldingNumber = kawaiiCore.getTotalCategory(to, category);
        require(limited >= currentHoldingNumber.add(amount), "KON: own exceed NFT");
        return true;
    }

    function isBatchTransferable(IKawaiiCore kawaiiCore, IKawaiiWarehouse kawaiiWarehouse, address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external view returns (bool){
        CategoryData[] memory categories = new CategoryData[](ids.length);
        uint256 totalDiffCategory = 0;
        bool isDuplicate;
        for (uint256 i = 0; i < ids.length; i++) {
            require(kawaiiWarehouse.notTransferableNFT(ids[i]) == false, "KON: Cannot transfer this NFT");
            string memory category = kawaiiCore.getKawaiiData(ids[i]).category;
            isDuplicate = false;
            for (uint256 j = 0; j < totalDiffCategory; j++) {
                if (keccak256(abi.encode(category)) == keccak256(abi.encode(categories[j].category))) {
                    isDuplicate = true;
                    categories[j] = CategoryData(category, categories[j].amount.add(amounts[i]));
                    break;
                }
            }
            if (isDuplicate == false) {
                categories[i] = CategoryData(category, ids[i]);
                totalDiffCategory = totalDiffCategory.add(1);
            }
        }
        for (uint256 i = 0; i < totalDiffCategory; i++) {
            if (categories[i].amount > 0) {
                uint256 limited = kawaiiWarehouse.getLimited(to, categories[i].category);
                uint256 currentHoldingNumber = kawaiiCore.getTotalCategory(to, categories[i].category);
                require(limited >= currentHoldingNumber.add(categories[i].amount), "KON: own exceed NFT");
            }
        }
        return true;
    }

}

