// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./utils/BytesLibrary.sol";
import "./utils/StringLibrary.sol";
import "./token/IERC20.sol";
import "./token/IERC721.sol";
import "./token/IERC721Mintable.sol";
import "./token/IERC1155.sol";
import "./interfaces/ITokenFactory.sol";
import "./interfaces/ITransferProxy.sol";
import "./interfaces/IERC20TransferProxy.sol";
import "./utils/PancakeRouter.sol";
import "./interfaces/INFTStorage.sol";

contract Exchange is Ownable {
    using SafeMath for uint256;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    struct ExchangeData {
        bool is721;
        address token;
        uint256 tokenId;
        uint256 prevTotal;
        uint256 value;
        address priceToken;
        uint256 price;
        address payable owner;
        string salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BidData {
        bool is721;
        address token;
        uint256 tokenId;
        address priceToken;
        uint256 price;
        address payable winner;
        string salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    ///////////// Beneficiaries //////////////////////
    address payable public beneficiary;
    //////////////////////////////////////////////////

    ///////////// Proxies ////////////////////////////
    ITransferProxy public transferProxy;
    IERC20TransferProxy public erc20TransferProxy;
    //////////////////////////////////////////////////

    ///////////// Router /////////////////////////////
    IPancakeRouter02 public router;
    //////////////////////////////////////////////////

    ///////////// Storages ///////////////////////////
    INFTStorage public nftStorage;
    IERC20 public mall;
    //////////////////////////////////////////////////

    ///////////// Fees ///////////////////////////////
    uint256 public mallFee;
    uint256 public bnbFee;
    //////////////////////////////////////////////////

    ///////////// Events /////////////////////////////
    event Sold(address seller, address tokenAddress, uint256 tokenId, uint256 value);
    event Bought(address buyer, address tokenAddress, uint256 tokenId, uint256 value);
    event AuctionEnded(address owner, address winner, address tokenAddress, uint256 tokenId);
    event FeesPaid(address to, uint256 fee);
    //////////////////////////////////////////////////

    receive() external payable {}

    function setReceivers(address payable _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function setFees(uint256 _mallFee, uint256 _bnbFee) external onlyOwner {
        mallFee = _mallFee;
        bnbFee = _bnbFee;
    }

    function setMALL(IERC20 _mall) external onlyOwner {
        mall = _mall;
    }

    function setTransferProxy(ITransferProxy _transferProxy) external onlyOwner {
        transferProxy = _transferProxy;
    }

    function setERC20TransferProxy(IERC20TransferProxy _erc20TransferProxy) external onlyOwner {
        erc20TransferProxy = _erc20TransferProxy;
    }

    function setNFTStorage(INFTStorage _nftStorage) external onlyOwner {
        nftStorage = _nftStorage;
    }

    function setRouter(IPancakeRouter02 _router) external onlyOwner {
        router = IPancakeRouter02(_router);
    }

    ///////////// Verification Functions /////////////
    function _generateKey(address token, uint256 tokenId, uint256 value, address priceToken, uint256 price, string memory salt) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(token, tokenId, value, priceToken, price, salt));
    }

    function generateKey(address token, uint256 tokenId, uint256 value, address priceToken, uint256 price, string memory salt) external pure returns (bytes32 key) {
        key = _generateKey(token, tokenId, value, priceToken, price, salt);
    }

    function generateMessage(address token, uint256 tokenId, uint256 value, address priceToken, uint256 price, string memory salt) external pure returns (string memory _message) {
        _message = _generateKey(token, tokenId, value, priceToken, price, salt).toString();
    }

    function verifyOrder(ExchangeData memory data) public pure returns (bool verified) {
        bytes32 _message = _generateKey(data.token, data.tokenId, data.prevTotal, data.priceToken, data.price, data.salt);
        address confirmed = _message.toString().recover(data.v, data.r, data.s);
        return (confirmed == data.owner);
    }

    function verifyBid(BidData memory data) public pure returns (bool verified) {
        bytes32 _message = _generateKey(data.token, data.tokenId, 1, data.priceToken, data.price, data.salt);
        address confirmed = _message.toString().recover(data.v, data.r, data.s);
        return (confirmed == data.winner);
    }
    //////////////////////////////////////////////////

    //////////////Exchange Functions//////////////////
    function exchange(ExchangeData memory data) external payable {
        executeOrder(data);
        _transferCost(data);
        if (data.is721) {
            _transfer721(data);
        } else {
            // _transfer1155(data);
        }
    }

    function _transfer721(ExchangeData memory data) internal {
        transferProxy.erc721safeTransferFrom(IERC721(data.token), data.owner, msg.sender, data.tokenId);
        emit Sold(data.owner, address(data.token), data.tokenId, 1);
        emit Bought(msg.sender, address(data.token), data.tokenId, 1);
    }

    function _transfer1155(ExchangeData memory data) internal {
        transferProxy.erc1155safeTransferFrom(IERC1155(data.token), data.owner, msg.sender, data.tokenId, data.value, "");
        emit Sold(data.owner, address(data.token), data.tokenId, data.value);
        emit Bought(msg.sender, address(data.token), data.tokenId, data.value);
    }

    function _generateFees(ExchangeData memory data) internal view returns (address payable creator, uint256[2] memory _fees){
        uint256 price = data.price.mul(data.value);
        uint256[2] memory fees = requiredFee(mallFee, bnbFee);
        uint256 buyerFee;

        if (IERC20(data.priceToken) == IERC20(address(0))) {
            buyerFee = fees[1];
        } else {
            buyerFee = fees[0];
        }

        (address payable _creator,uint256 creatorFeePercentage) = nftStorage.getNFT(data.token, data.tokenId);
        uint256 creatorFee = (price.mul(creatorFeePercentage)).div(100);
        creator = _creator;
        _fees = [buyerFee, creatorFee];
    }

    function _transferCost(ExchangeData memory data) internal {
        uint256 price = data.price.mul(data.value);
        (address payable creator,uint256[2] memory fees) = _generateFees(data);
        if (creator == address(0)) {
            creator = beneficiary;
        }

        uint256 toSeller = price.sub(fees[1]);
        uint256 toBeneficiary = fees[0];
        uint256 toCreator = fees[1];

        if (IERC20(data.priceToken) == IERC20(address(0))) {
            require(msg.value >= price.add(fees[0]), "Order is underpriced");
            if (data.owner == creator) {
                data.owner.transfer(toSeller.add(toCreator));
            } else {
                data.owner.transfer(toSeller);
                creator.transfer(toCreator);
                emit FeesPaid(creator, toCreator);
            }

            beneficiary.transfer(toBeneficiary);
            payable(msg.sender).transfer(msg.value.sub(price.add(fees[0])));
            emit FeesPaid(beneficiary, toBeneficiary);
        } else {
            if (data.owner == creator) {
                erc20TransferProxy.erc20safeTransferFrom(IERC20(data.priceToken), msg.sender, data.owner, toSeller.add(toCreator));
            } else {
                erc20TransferProxy.erc20safeTransferFrom(IERC20(data.priceToken), msg.sender, data.owner, toSeller);
                erc20TransferProxy.erc20safeTransferFrom(IERC20(data.priceToken), msg.sender, creator, toCreator);
                emit FeesPaid(creator, toCreator);
            }

            erc20TransferProxy.erc20safeTransferFrom(IERC20(data.priceToken), msg.sender, beneficiary, toBeneficiary);
            emit FeesPaid(beneficiary, toBeneficiary);
        }
    }

    function executeOrder(ExchangeData memory data) internal {
        require(verifyOrder(data), "Order is not verified!");
        nftStorage.setComplete(
            _generateKey(data.token, data.tokenId, data.prevTotal, data.priceToken, data.price, data.salt),
            data.prevTotal,
            data.value
        );
    }
    //////////////////////////////////////////////////

    //////////////Auction Functions///////////////////
    function endAuction(BidData memory data) external payable {
        executeAuction(data);
        _transferCostAu(data);
        if (data.is721) {
            _transfer721Au(data);
        } else {
            // _transfer1155Au(data);
        }
    }

    function _transfer721Au(BidData memory data) internal {
        transferProxy.erc721safeTransferFrom(IERC721(data.token), msg.sender, data.winner, data.tokenId);
        emit AuctionEnded(msg.sender, data.winner, data.token, data.tokenId);
    }

    function _transfer1155Au(BidData memory data) internal {
        transferProxy.erc1155safeTransferFrom(IERC1155(data.token), msg.sender, data.winner, data.tokenId, 1, "");
        emit AuctionEnded(msg.sender, data.winner, data.token, data.tokenId);
    }

    function _generateFeesAu(BidData memory data) internal view returns (address payable creator, uint256 fee){
        uint256 price = data.price;
        (address payable _creator,uint256 creatorFeePercentage) = nftStorage.getNFT(data.token, data.tokenId);
        uint256 creatorFee = (price.mul(creatorFeePercentage)).div(100);
        creator = _creator;
        fee = creatorFee;
    }

    function _transferCostAu(BidData memory data) internal {
        uint256 price = data.price;
        (address payable creator,uint256 fee) = _generateFeesAu(data);

        if (creator == address(0)) {
            creator = beneficiary;
        }

        uint256 toSeller = price.sub(fee);
        uint256 toCreator = fee;

        if (creator == msg.sender) {
            erc20TransferProxy.erc20safeTransferFrom(IERC20(data.priceToken), data.winner, msg.sender, toSeller.add(toCreator));
        } else {
            erc20TransferProxy.erc20safeTransferFrom(IERC20(data.priceToken), data.winner, msg.sender, toSeller);
            erc20TransferProxy.erc20safeTransferFrom(IERC20(data.priceToken), data.winner, creator, toCreator);
            emit FeesPaid(creator, toCreator);
        }
    }

    function executeAuction(BidData memory data) internal {
        require(verifyBid(data), "Order is not verified!");
        nftStorage.setComplete(
            _generateKey(data.token, data.tokenId, 1, data.priceToken, data.price, data.salt),
            1,
            1
        );
    }
    //////////////////////////////////////////////////

    ///////////// Router Actions /////////////////////
    function requiredFee(uint256 _mallFee, uint256 _bnbFee) public view returns (uint256[2] memory _fees){
        address[] memory mallPath;
        address[] memory bnbPath;
        mallPath = new address[](3);
        bnbPath = new address[](2);
        mallPath[0] = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
        // BUSD
        mallPath[1] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        // WBNB
        mallPath[2] = address(mall);
        bnbPath[0] = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
        bnbPath[1] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        uint256 _feeForMALL = router.getAmountsOut(_mallFee, mallPath)[2];
        uint256 _feeForBNB = router.getAmountsOut(_bnbFee, bnbPath)[1];
        _fees[0] = _feeForMALL;
        _fees[1] = _feeForBNB;
    }
    //////////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev BytesLibrary operations.
 */
library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UintLibrary.sol";

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bab = new bytes(ba.length + bb.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bab[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bab[k++] = bb[i];
        return string(bab);
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bc = bytes(c);
        bytes memory bbb = new bytes(ba.length + bb.length + bc.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bbb[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bbb[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) bbb[k++] = bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory ba, bytes memory bb, bytes memory bc, bytes memory bd, bytes memory be, bytes memory bf, bytes memory bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(ba.length + bb.length + bc.length + bd.length + be.length + bf.length + bg.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) resultBytes[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) resultBytes[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) resultBytes[k++] = bc[i];
        for (uint i = 0; i < bd.length; i++) resultBytes[k++] = bd[i];
        for (uint i = 0; i < be.length; i++) resultBytes[k++] = be[i];
        for (uint i = 0; i < bf.length; i++) resultBytes[k++] = bf[i];
        for (uint i = 0; i < bg.length; i++) resultBytes[k++] = bg[i];
        return resultBytes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IERC721Mintable is IERC721{
    function mintToken(address _tokenOwner, string memory tokenURI) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenFactory {
    function addOperator(address _operator) external;

    function removeOperator(address _operator) external;

    function createERC721(address _owner, address _operator, string memory _contract_URI, string memory _name, string memory _symbol) external;

    function createERC1155(address _owner, address _operator, string memory _uri, string memory contract_uri) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/IERC721.sol";
import "../token/IERC1155.sol";

interface ITransferProxy {
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/IERC20.sol";

interface IERC20TransferProxy {
    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTStorage {
    event NFTAdded(address moderator, address _collection, uint256 _id, address payable _creator, uint256 _fee);
    event OrderExecuted(bytes32 orderId, uint256 total, uint256 sold);
    event ModeratorAdded(address _moderator);
    event ModeratorRemoved(address _moderator);


    function addModerator(address _moderator) external;

    function removeModerator(address _moderator) external;

    function addNFT(address _collection, uint256 _id, address payable _creator, uint256 _fee) external;

    function setComplete(bytes32 orderId, uint256 total, uint256 value) external;

    function getNFT(address _collection, uint256 _id) external view returns (address payable creator, uint256 feePrecentage);

    function getOrder(bytes32 _orderId) external view returns (uint256 total, uint256 sold);

    function isModerator(address _moderator) external view returns (bool _isModerator);


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";

library UintLibrary {
    using SafeMath for uint256;

    function toString(uint256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }

        uint256 j = i;
        uint256 len;

        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);

        for (uint256 k = len; k > 0; k--) {
            bstr[k - 1] = bytes1(uint8(48 + i % 10));
            i /= 10;
        }

        return string(bstr);
    }

    function bp(uint256 value, uint256 bpValue) internal pure returns (uint256) {
        return value.mul(bpValue).div(10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

