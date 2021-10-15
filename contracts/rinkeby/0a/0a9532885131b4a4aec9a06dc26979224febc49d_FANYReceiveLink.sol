/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

contract FANYReceiveLink is Ownable {
    using SafeMath for uint256;
    address[] public businessAddresses;
    struct sendErc21 {
        address erc20;
        address maker;
        address taker;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 status; // 1 available, 2 canceled, 3 taken
    }
    mapping(uint256 => sendErc21) private sendErc21s;
    struct coin {
        uint256 amount;
        address maker;
        address taker;
        uint256 start;
        uint256 end;
        uint256 status; // 1 available, 2 canceled, 3 taken
    }
    mapping(uint256 => coin) private coins;

    struct sendErc721 {
        address erc721;
        uint256 tokenId;
        address maker;
        address taker;
        uint256 start;
        uint256 end;
        uint256 status; // 1 available, 2 canceled, 3 taken
    }
    mapping(uint256 => sendErc721) private sendErc721s;
    modifier onlyManager() {
        require(msg.sender == owner() || isBusiness());
        _;
    }

    function isBusiness() public view returns (bool) {
        bool valid;
        for (uint256 i = 0; i < businessAddresses.length; i++) {
            if (businessAddresses[i] == msg.sender) valid = true;
        }
        return valid;
    }

    function setBusinessAdress(address[] memory _businessAddresses) public onlyOwner {
        businessAddresses = _businessAddresses;
    }

    event Coin(uint256 _id);
    event SendERC21(uint256 _id);
    event SendERC721(uint256 _id);
    event RequestSendERC21(uint256 _id, address taker);
    event RequestSendERC721(uint256 _id, address taker, uint256 tokenId);
    event RequestCoin(uint256 _id, address taker);

    constructor() {}

    function sendTRC21s(
        uint256 _num,
        uint256[] memory _ids,
        address _erc20,
        uint256 _amount,
        uint256 _start,
        uint256 _end
    ) public {
        IERC20 erc20 = IERC20(_erc20);
        require(erc20.transferFrom(msg.sender, address(this), _amount.mul(_num)));
        for (uint256 i = 0; i < _num; i++) {
            _sendTRC21(_ids[i], _erc20, _amount, _start, _end);
        }
    }

    function sendTRC21(
        uint256 _id,
        address _erc20,
        uint256 _amount,
        uint256 _start,
        uint256 _end
    ) public {
        IERC20 erc20 = IERC20(_erc20);
        require(erc20.transferFrom(msg.sender, address(this), _amount));
        _sendTRC21(_id, _erc20, _amount, _start, _end);
    }

    function _sendTRC21(
        uint256 _id,
        address _erc20,
        uint256 _amount,
        uint256 _start,
        uint256 _end
    ) internal {
        require(sendErc21s[_id].maker == address(0), "This id existed !");

        sendErc21s[_id].erc20 = _erc20;
        sendErc21s[_id].amount = _amount;
        sendErc21s[_id].maker = msg.sender;
        sendErc21s[_id].start = _start;
        sendErc21s[_id].end = _end;
        sendErc21s[_id].status = 1;
        emit SendERC21(_id);
    }

    function getSendERC21(uint256 _id)
        public
        view
        returns (
            address erc20,
            address maker,
            address taker,
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 status
        )
    {
        return (sendErc21s[_id].erc20, sendErc21s[_id].maker, sendErc21s[_id].taker, sendErc21s[_id].amount, sendErc21s[_id].start, sendErc21s[_id].end, sendErc21s[_id].status);
    }

    function validateTime(uint256 _type, uint256 _id) public view returns (bool) {
        bool validate;
        if (_type == 1) {
            validate = block.timestamp >= sendErc21s[_id].start && block.timestamp <= sendErc21s[_id].end;
        } else if (_type == 2) {
            validate = block.timestamp >= coins[_id].start && block.timestamp <= coins[_id].end;
        } else {
            validate = block.timestamp >= sendErc721s[_id].start && block.timestamp <= sendErc721s[_id].end;
        }
        return validate;
    }

    function requestSendERC21(uint256 _id) public {
        require(sendErc21s[_id].status == 1, "this package not existed !");
        uint256 status = 3;
        if (msg.sender != sendErc21s[_id].maker) {
            require(validateTime(1, _id), "This time not available !");
            //            require(sendErc21s[_id].taker == msg.sender);
        } else {
            require(block.timestamp > sendErc21s[_id].end, "This time not available !");
            status = 2;
        }

        IERC20 erc20 = IERC20(sendErc21s[_id].erc20);
        erc20.transfer(msg.sender, sendErc21s[_id].amount);
        sendErc21s[_id].amount = 0;
        sendErc21s[_id].status = status;
        sendErc21s[_id].taker = msg.sender;
        emit RequestSendERC21(_id, msg.sender);
    }

    function getSendCoin(uint256 _id)
        public
        view
        returns (
            address maker,
            address taker,
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 status
        )
    {
        return (coins[_id].maker, coins[_id].taker, coins[_id].amount, coins[_id].start, coins[_id].end, coins[_id].status);
    }

    function sendCoins(
        uint256 _num,
        uint256[] memory _ids,
        uint256 _amount,
        uint256 _start,
        uint256 _end
    ) public payable {
        require(msg.value >= _amount.mul(_num));
        for (uint256 i = 0; i < _num; i++) {
            _sendCoin(_ids[i], _amount, _start, _end);
        }
    }

    function sendCoin(
        uint256 _id,
        uint256 _amount,
        uint256 _start,
        uint256 _end
    ) public payable {
        require(msg.value == _amount);
        _sendCoin(_id, _amount, _start, _end);
    }

    function _sendCoin(
        uint256 _id,
        uint256 _amount,
        uint256 _start,
        uint256 _end
    ) internal {
        require(coins[_id].maker == address(0), "This id existed !");
        coins[_id].amount = _amount;
        coins[_id].maker = msg.sender;
        coins[_id].start = _start;
        coins[_id].end = _end;
        coins[_id].status = 1;
        emit Coin(_id);
    }

    function requestSendCoin(uint256 _id) public {
        require(coins[_id].status == 1, "this package not existed !");
        uint256 status = 3;
        if (msg.sender != coins[_id].maker) {
            require(validateTime(2, _id), "This time not available !");
            //            require(coins[_id].taker == msg.sender);
        } else {
            require(block.timestamp > coins[_id].end, "This time not available !");
            status = 2;
        }
        payable(msg.sender).transfer(coins[_id].amount);
        coins[_id].amount = 0;
        coins[_id].status = status;
        coins[_id].taker = msg.sender;
        emit RequestCoin(_id, msg.sender);
    }

    function sendTRC721s(
        uint256[] memory _ids,
        address _erc721,
        uint256[] memory _tokenIds,
        uint256 _start,
        uint256 _end
    ) public {
        IERC721 erc721 = IERC721(_erc721);
        for (uint256 i = 0; i < _ids.length; i++) {
            erc721.transferFrom(msg.sender, address(this), _tokenIds[i]);
            _sendTRC721(_ids[i], _erc721, _tokenIds[i], _start, _end);
        }
    }

    function sendTRC721(
        uint256 _id,
        address _erc721,
        uint256 _tokenId,
        uint256 _start,
        uint256 _end
    ) public {
        IERC721 erc721 = IERC721(_erc721);
        erc721.transferFrom(msg.sender, address(this), _tokenId);
        _sendTRC721(_id, _erc721, _tokenId, _start, _end);
    }

    function _sendTRC721(
        uint256 _id,
        address _erc721,
        uint256 _tokenId,
        uint256 _start,
        uint256 _end
    ) public {
        require(sendErc721s[_id].maker == address(0), "This id existed !");

        sendErc721s[_id].erc721 = _erc721;
        sendErc721s[_id].tokenId = _tokenId;
        sendErc721s[_id].maker = msg.sender;
        sendErc721s[_id].start = _start;
        sendErc721s[_id].end = _end;
        sendErc721s[_id].status = 1;
        emit SendERC721(_id);
    }

    function getSendERC721(uint256 _id)
        public
        view
        returns (
            address erc721,
            address maker,
            address taker,
            uint256 tokenId,
            uint256 start,
            uint256 end,
            uint256 status
        )
    {
        return (sendErc721s[_id].erc721, sendErc721s[_id].maker, sendErc721s[_id].taker, sendErc721s[_id].tokenId, sendErc721s[_id].start, sendErc721s[_id].end, sendErc721s[_id].status);
    }

    function requestSendERC721(uint256 _id) public {
        require(sendErc721s[_id].status == 1, "this package not existed !");
        uint256 status = 3;
        if (msg.sender != sendErc721s[_id].maker) {
            require(validateTime(3, _id), "This time not available !");
            //            require(sendErc721s[_id].taker == msg.sender);
        } else {
            require(block.timestamp > sendErc721s[_id].end, "This time not available !");
            status = 2;
        }
        IERC721 erc721 = IERC721(sendErc721s[_id].erc721);
        uint256 tokenId = sendErc721s[_id].tokenId;
        erc721.transferFrom(address(this), msg.sender, tokenId);
        sendErc721s[_id].tokenId = 0;
        sendErc721s[_id].status = status;
        sendErc721s[_id].taker = msg.sender;
        emit RequestSendERC721(_id, msg.sender, tokenId);
    }

    function resetLink(uint256 _id, uint256 _type) public onlyManager {
        // _type == 1 => Coin
        // _type == 2 => sendErc21s
        // _type == 3 => sendErc721s
        if (_type == 1) {
            payable(coins[_id].maker).transfer(coins[_id].amount);
            coins[_id].amount = 0;
            coins[_id].status = 2;
        } else if (_type == 2) {
            IERC20 erc20 = IERC20(sendErc21s[_id].erc20);
            erc20.transfer(sendErc21s[_id].maker, sendErc21s[_id].amount);
            sendErc21s[_id].amount = 0;
            sendErc21s[_id].status = 2;
        } else {
            IERC721 erc721 = IERC721(sendErc721s[_id].erc721);
            uint256 tokenId = sendErc721s[_id].tokenId;
            erc721.transferFrom(address(this), sendErc721s[_id].maker, tokenId);
            sendErc721s[_id].tokenId = 0;
            sendErc721s[_id].status = 2;
        }
    }
}