/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]
// SPDX-License-Identifier: MIT

//  MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// File @openzeppelin/contracts/security/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/Market/ILandMarket.sol

//  MIT
pragma solidity ^0.8.0;

interface ILandMarket {
    event PutShopLand(uint indexed landId, address indexed seller, uint price, uint _timeStamp);
    event GetOffShopLand(uint indexed landId, address indexed seller);
    event BuyShopLand(uint indexed landId, address indexed buyer, address indexed seller, uint price);
    function getShopByLandId(uint _landId) external view returns(address, uint, uint, uint);
    function getOffShopLand(uint _landId) external returns(uint);
    function putShopLand(uint _landId,uint _sellPrice) external returns(uint);
    function delLandSalesInfo(uint _landId) external;
    function addLandSalesInfo(uint _landId, address _seller, uint _sellPrice) external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File contracts/ERC20/IRichToken.sol

//  MIT
pragma solidity ^0.8.0;

interface IRichToken is IERC20 {
    event Recharge(address indexed from, address indexed to, uint256 value);
    event MintSelf(address indexed to, uint256 value, uint tax);
    function transferAccount(address from, address to, uint256 amount) external returns (bool);
    function getBurnAddress() external view returns(address);
    function getRichFarmByAddress(address account) external view returns (address, uint);
    function getCapValue() external view returns(uint256);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File contracts/Land/ILandCore.sol

//  MIT
pragma solidity ^0.8.0;

interface ILandCore is IERC721 {
    event NewLand(address indexed to, uint indexed landId, uint8 landType, uint8 landStage, string ident, uint code, uint landPrice);
    event StageStart(uint8 landStage, bool status);
    event StageConfig(uint8 stageId, uint8 landType, uint256 stagePrice, uint stageTotalNumber, uint airdropTotalNumber);
    event StageIncrease(uint8 stageId, uint8 landType, uint256 stagePrice, uint stageIncreaseNumber, uint airdropIncreaseNumber);
    function getCEO() external view returns(address);
    function getCFO() external view returns(address);
    function getCOO() external view returns(address);
    function getCSO() external view returns(address);
    function getOpenedLandCount() external view returns(uint);
    function transferByMainContract(address from, address to, uint256 tokenId) external;
    function safeTransferByMainContract(address from, address to, uint256 tokenId) external;
    function getLandByTokenId(uint _tokenId) external view returns(
        uint8,
        uint8,
        string memory,
        uint,
        uint,
        address,
        uint,
        uint
    ) ;
    function getLandStageInfo(uint _tokenId) external view returns (uint8, uint8, uint256, uint, uint ,uint,uint);
}


// File contracts/Utils/IRCUtils.sol

//  MIT
pragma solidity ^0.8.0;

interface IRCUtils {
    function createIdent(uint _len, uint _max, uint _landType) external returns (string memory);
    function stringConcat(string memory _a, string memory _b) external view returns(string memory);
}


// File contracts/Promotion/IHire.sol

//  MIT
pragma solidity ^0.8.0;

interface IHire {
    function getOwnerByTokenId(uint _tokenId) external view returns(address, address, uint, uint, uint);
    function getHireInfoByTokenId(uint _tokenId) external view returns(address, address, uint, uint, uint, uint);
    function settleHireByDep() external;
    function getExpireHireNum() external view returns(uint);
}


// File contracts/Dependency/FarmDep.sol

//  MIT
pragma solidity ^0.8.0;






contract FarmDep is Pausable{
    address public whitelistSetterAddress;
    IRichToken private richTokenInter;
    ILandCore private landCodeInter;
    ILandMarket private landMarketInter;
    IRCUtils private rcUtilsInter;
    IHire private hireInter;
    address public richTokenAddress;
    address public landCoreAddress;
    address public landMarketAddress;
    address public hireAddress;
    address public rcUtilsAddress;
    address[] private farmDeps;
    // 1/10000
    uint public burnPoint = 1;
    uint public fundPoint = 50;
    uint public minPrice = 10 * (10 ** 9);
    uint public minTaxPrice = 3 * (10 ** 9);
    address owner;

    event SetFarmDeps(address _op , address _delAddr);
    event DelFarmDeps(address _op , address _delAddr);

    constructor() {
        owner = msg.sender;
        whitelistSetterAddress = msg.sender;
    }

    modifier onlyWhitelistSetter() {
        require(msg.sender == whitelistSetterAddress || msg.sender == owner);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyRichToken() {
        require(richTokenAddress==msg.sender);
        _;
    }

    modifier onlyLandCode() {
        require(landCoreAddress==msg.sender);
        _;
    }

    modifier onlyLandMarket() {
        require(landMarketAddress==msg.sender);
        _;
    }

    function setWhitelistSetter(address _newSetter) external onlyOwner {
        whitelistSetterAddress = _newSetter;
    }

    function setRichToken(address _newAddress) external onlyWhitelistSetter {
        richTokenAddress = _newAddress;
        richTokenInter = IRichToken(_newAddress);
        farmDeps.push(_newAddress);
    }

    function setLandCore(address _newAddress) external onlyWhitelistSetter {
        landCoreAddress = _newAddress;
        landCodeInter = ILandCore(_newAddress);
        farmDeps.push(_newAddress);
    }

    function setLandMarket(address _newAddress) external onlyWhitelistSetter {
        landMarketAddress = _newAddress;
        landMarketInter = ILandMarket(_newAddress);
        farmDeps.push(_newAddress);
    }

    function setRcUtilsAddress(address _newAddress) external onlyWhitelistSetter {
        rcUtilsAddress = _newAddress;
        rcUtilsInter = IRCUtils(_newAddress);
        farmDeps.push(_newAddress);
    }

    function setHire(address _newAddress) external onlyWhitelistSetter {
        hireAddress = _newAddress;
        hireInter = IHire(_newAddress);
        farmDeps.push(_newAddress);
    }

    function setBurnPoint(uint _point) external onlyWhitelistSetter {
        require(_point <= 100);
        burnPoint = _point;
    }

    function setFundPoint(uint _point) external onlyWhitelistSetter {
        require(_point <= 1000);
        fundPoint = _point;
    }

    function setMinTaxPrice(uint _minTaxPrice) external onlyWhitelistSetter {
        minTaxPrice = _minTaxPrice;
    }

    function setMinPrice(uint _value) external onlyWhitelistSetter{
        minPrice = _value;
    }

    function setFarmDeps(address _newAddress) external onlyOwner{
        farmDeps.push(_newAddress);
        emit SetFarmDeps(msg.sender, _newAddress);
    }

    function delFarmDeps(address _address) external onlyOwner{
        for (uint i = 0; i < farmDeps.length; i++){
            if (farmDeps[i] == _address) {
                farmDeps[i] = address(0);
            }
        }
        emit DelFarmDeps(msg.sender, _address);
    }

    function getFarmDeps() public view returns(address[] memory) {
        return farmDeps;
    }

    function getCEO() public view returns(address) {
        return landCodeInter.getCEO();
    }

    function getCFO() public view returns(address) {
        return landCodeInter.getCFO();
    }

    function getCOO() public view returns(address) {
        return landCodeInter.getCOO();
    }

    function getCSO() public view returns(address) {
        return landCodeInter.getCSO();
    }

    function getBurn() public view returns(address) {
        return richTokenInter.getBurnAddress();
    }

    function getBurnPoint() public view returns(uint){
        return burnPoint;
    }

    function getFundPoint() public view returns(uint){
        return fundPoint;
    }

    function setPause() external onlyWhitelistSetter whenNotPaused {
        _pause();
    }

    function setUnpause() external onlyWhitelistSetter whenPaused {
        _unpause();
    }

}


// File contracts/Promotion/HireStorage.sol

//  MIT
pragma solidity ^0.8.0;

contract HireStorage {
    uint public constant hireCount = 1;
    uint public constant freezeTime = 7 days;

    struct HireInfo {
        address owner;
        address hirer;
        uint tokenId;
        uint taxPoint;
        uint startTime;
        uint endTime;
    }

    uint[] internal hireTokens;
    mapping (uint => HireInfo) public tokenIdToHire;
    mapping (address => uint[]) public hirerToTokens;
    mapping (address => uint) public ownerToCount;
}


// File @openzeppelin/contracts/utils/math/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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


// File contracts/Promotion/HireService.sol

//  MIT
pragma solidity ^0.8.0;


abstract contract HireService is HireStorage, IHire{
    function getHireInfoByTokenId(uint _tokenId) external view override returns(address, address, uint, uint, uint, uint) {
        HireInfo memory _hireInfo = tokenIdToHire[_tokenId];
        return (
            _hireInfo.owner,
            _hireInfo.hirer,
            _hireInfo.taxPoint,
            _hireInfo.startTime,
            _hireInfo.endTime,
            _hireInfo.tokenId
        );
    }

    function getExpireHireNum() external view override returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < hireTokens.length; i++) {
            HireInfo memory _info = tokenIdToHire[hireTokens[i]];
            if (_info.endTime <= block.timestamp && _info.hirer != address(0)) {
                counter++;
            }
        }
        return counter;
    }
}


// File contracts/Promotion/HireContract.sol

//  MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;




contract Hire is HireService{
    using SafeMath for uint256;
    FarmDep public farmDep;
    address private owner;
    constructor (address _farmDep) {
        farmDep = FarmDep(_farmDep);
        owner = msg.sender;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == farmDep.getCOO() ||
            msg.sender == farmDep.getCEO() ||
            msg.sender == farmDep.getCFO() ||
            msg.sender == farmDep.getCSO(), "sender is not matched");
        _;
    }

    modifier onlyHireDep() {
        address[] memory deps = farmDep.getFarmDeps();
        address depAddress;
        for (uint i = 0; i < deps.length;i++) {
            if (msg.sender == deps[i]) {
                depAddress = deps[i];
                break;
            }
        }
        require(msg.sender == depAddress, "is not hire dependency");
        _;
    }
    uint public settleTime;

    event CreateHire(address indexed owner, address indexed hirer, uint indexed tokenId, uint _startTime, uint _endTime, uint _taxPoint);
    event EndOfHire(address indexed owner,  uint indexed tokenId);

    modifier markerCondition(uint _tokenId) {
        ILandMarket landMarketInter = ILandMarket(farmDep.landMarketAddress());
        address _seller;
        (_seller,,,)=landMarketInter.getShopByLandId(_tokenId);
        require(_seller == address(0), "this token on the market. take off the shelf");
        _;
    }
    modifier hireCondition(address _hirer, uint _tokenId) {
        require(tokenIdToHire[_tokenId].hirer == address(0), "this token has been leased");
        require(_hirer != msg.sender, "The rental address can't be yourself");
        require(
            hirerToTokens[_hirer].length == 0 ||
            (hirerToTokens[_hirer].length > 0
            && tokenIdToHire[(hirerToTokens[_hirer][0])].owner == msg.sender
            ), "The current tenant has already employed"
        );
        _;
    }

    function createHire(address _hirer, uint _tokenId, uint _taxPoint, uint _days)
    public hireCondition(_hirer, _tokenId){
        ILandCore landCoreInter = ILandCore(farmDep.landCoreAddress());
        address _seller;
        (,,,,,_seller,,)=landCoreInter.getLandByTokenId(_tokenId);
        require(_seller == address(0), "this token on the market. take off the shelf");

        require(msg.sender == landCoreInter.ownerOf(_tokenId), "you are not token owner");
        require(_days > 0 && _days <= 30, "Lease time is an integer less than 30");
        require(_taxPoint >= 30 && _taxPoint <= 100, "taxPoint between 30 and 100");
        landCoreInter.transferByMainContract(msg.sender,address(this), _tokenId);
        hireTokens.push(_tokenId);
        uint _ts = block.timestamp - (block.timestamp % 60);
        uint thawingTime = _ts + (_days * 1 days);
        tokenIdToHire[_tokenId] = HireInfo(msg.sender, _hirer, _tokenId, _taxPoint, _ts, thawingTime);
        hirerToTokens[_hirer].push(_tokenId);
        ownerToCount[msg.sender] = ownerToCount[msg.sender] + 1;
        emit CreateHire(msg.sender, _hirer, _tokenId, _ts, thawingTime, _taxPoint);
        _settleHire(landCoreInter);
    }

    function _settleHire(ILandCore _landCoreInter) internal  {
        for (uint i = 0; i < hireTokens.length; i++) {
            HireInfo memory _info = tokenIdToHire[hireTokens[i]];
            if (_info.hirer != address(0) && _info.endTime <= block.timestamp) {
                _landCoreInter.transferByMainContract(address(this), _info.owner, _info.tokenId);
                delete tokenIdToHire[_info.tokenId];
                _removeArrayEle(_info.hirer, _info.tokenId);
                ownerToCount[_info.owner] = ownerToCount[_info.owner] - 1;
                _swapHireTokens(i, hireTokens.length - 1);
                hireTokens.pop();
                emit EndOfHire(_info.owner, _info.tokenId);
            }
        }
        uint _ts = block.timestamp - (block.timestamp % 60);
        settleTime = _ts;
    }

    function _removeArrayEle(address _address, uint ele) internal  {
        for (uint i = 0; i < hirerToTokens[_address].length; i++){
            if ((hirerToTokens[_address])[i] == ele) {
                _swap(_address,i, hirerToTokens[_address].length - 1);
                (hirerToTokens[_address]).pop();
            }
        }
    }

    function _swap(address _address, uint i, uint j) internal {
        uint t = hirerToTokens[_address][i];
        hirerToTokens[_address][i] = hirerToTokens[_address][j];
        hirerToTokens[_address][j] = t;
    }

    function _swapHireTokens(uint i, uint j) internal {
        uint t = hireTokens[i];
        hireTokens[i] = hireTokens[j];
        hireTokens[j] = t;
    }

    function settleHireByCLevel() public onlyCLevel{
        ILandCore landCoreInter = ILandCore(farmDep.landCoreAddress());
        _settleHire(landCoreInter);
    }

    function settleHireByDep() external override onlyHireDep{
        ILandCore landCoreInter = ILandCore(farmDep.landCoreAddress());
        _settleHire(landCoreInter);
    }

    function getRentalRecords() public view returns (HireInfo[] memory, HireInfo[] memory){
        HireInfo[] memory rentInfos = new HireInfo[](ownerToCount[msg.sender]);
        uint counter = 0;
        for (uint i = 0; i < hireTokens.length; i++) {
            if (tokenIdToHire[hireTokens[i]].owner == msg.sender) {
                rentInfos[counter] = tokenIdToHire[hireTokens[i]];
                counter ++;
            }
        }
        uint _len = hirerToTokens[msg.sender].length;
        HireInfo[] memory employedInfos = new HireInfo[](_len);
        for (uint i = 0; i < _len; i++) {
            employedInfos[i] = tokenIdToHire[(hirerToTokens[msg.sender][i])];
        }
        return (rentInfos,employedInfos);
    }

    function getOwnerByTokenId(uint _tokenId) external view override returns(address, address, uint, uint, uint) {
        if (tokenIdToHire[_tokenId].owner == address(0)) {
            ILandCore landCoreInter = ILandCore(farmDep.landCoreAddress());
            return (
            landCoreInter.ownerOf(_tokenId),
            address(0),
            tokenIdToHire[_tokenId].taxPoint,
            tokenIdToHire[_tokenId].startTime,
            tokenIdToHire[_tokenId].endTime
            );
        }
        return (
            tokenIdToHire[_tokenId].owner,
            tokenIdToHire[_tokenId].hirer,
            tokenIdToHire[_tokenId].taxPoint,
            tokenIdToHire[_tokenId].startTime,
            tokenIdToHire[_tokenId].endTime
        );
    }
}