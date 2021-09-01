// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// contracts/HeroBox.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IIdleRNG.sol";
import "./base/ERC721HeroCallerBase.sol";
import "./base/ERC721KeyCallerBase.sol";
import "./base/ERC20TokenCallerBase.sol";
import "./utils/ExStrings.sol";
import "./utils/Integers.sol";

contract HeroBox is ERC721HeroCallerBase, ERC721KeyCallerBase, ERC20TokenCallerBase, Ownable {
    
    using ExStrings for string;
    using Integers for uint;
    using Integers for uint256;

    address _RNGContract;

    uint256 private _baseDNA = 111011127434030112131410101010203041122334402020203040514263646060603040506;
    string private _baseDNAStr = "111011127434030112131410101010203041122334402020203040514263646060603040506";

    event GetNewDNA(string dna);

    constructor() {
    }

    function RNGContract() public view returns (address) {
        return _RNGContract;
    }

    function setRNGContract(address addr) public {
        _RNGContract = addr;
    }


    struct HeroInfo {
        string hero_head;
        string hero_hand;
        string hero_body;
        string hero_weapon;
        string hero_plat;
        string hero_flag;

        string s_head;
        string s_hand;
        string s_body;
        string s_weapon;

        string _batch;
        string unit;
        string camp;
        string attr;
        string showD;
        string skillD;
        string showR1;
        string skillR1;
        string showR2;
        string skillR2;
    }

    struct RandIntData{
        bool HasData;
        uint[] RandIntList;
        uint index;
    }

    function get_rand_int(uint x, uint step) internal returns(uint mold){
        RandIntData memory rand_int_data;
        if (x == 0) {
            return step;
        }
        if (rand_int_data.HasData == false) {
            // rand_int_data.RandIntList = RandomNumber(_RandomNumber).GetRandIntList();
            rand_int_data.RandIntList = IIdleRNG(_RNGContract).expandRandomness(msg.sender, 25);
            rand_int_data.HasData = true;
        }
        uint v = rand_int_data.RandIntList[rand_int_data.index];
        mold = v%(x) + step;
        if (rand_int_data.index == 24){
            rand_int_data.HasData = false;
        }
        rand_int_data.index++;
    }

    function parseIntSelf(string memory _value)
        private
        pure
        returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }

    function get_hero_unit(uint batch) internal returns(string memory res) {
        uint unit = batch + 90 + get_rand_int(3, 0);
        res = Integers.toString(uint(unit));
        return res;
    }

    function get_hero_camp() internal returns(string memory res) {
        uint rand = get_rand_int(6, 11);
        res = Integers.toString(uint(rand));
        return res;
    }

    function get_hero_attr() internal returns(string memory res){
        uint health = get_rand_int(17, 27);
        uint speed = get_rand_int(17, 27);
        uint sum_avg = (140 - health - speed) / 2;
        uint skill = 0;
        if (sum_avg >= 35) {
            uint _scope = (43 - sum_avg) * 2;
            skill = 43 - get_rand_int(_scope, 0);
        }
        if (sum_avg < 35){
            uint _scope = (sum_avg - 27) * 2;
            skill = 27 + get_rand_int(_scope, 0);
        }
        uint mood = 140 - health - speed - skill;
        uint total = health+speed+skill+mood;
        require(total == 140, "total error");
        res = Integers.toString(uint(health));
        res = res.concat(Integers.toString(uint(speed)));
        res = res.concat(Integers.toString(uint(skill)));
        res = res.concat(Integers.toString(uint(mood)));
        return res;
    }


    function get_hero_head(bool first) internal returns(uint) {
        uint is_legend = get_rand_int(100, 1);
        if (is_legend <= 15 && first == true) {
            return 51;
        }
        uint res = 10 + get_rand_int(4, 1);
        return res;
    }

    function get_hero_hand(bool first) internal returns(uint) {
        uint is_legend = get_rand_int(100, 1);
        if (is_legend <= 15 && first == true) {
            return 61;
        }
        uint res = 20 + get_rand_int(6, 1);
        return res;
    }

    function get_hero_body(bool first) internal returns(uint) {
        uint is_legend = get_rand_int(100, 1);
        if (is_legend <= 15 && first == true) {
            return 71;
        }
        uint res = 30 + get_rand_int(6, 1);
        return res;
    }

    function get_hero_weapon(bool first) internal returns(uint) {
        uint is_legend = get_rand_int(100, 1);
        if (is_legend <= 15 && first == true) {
            return 81;
        }
        uint res = 40 + get_rand_int(6, 1);
        return res;
    }

    function get_hero_plat() internal returns(uint) {
        uint res = get_rand_int(6, 1);
        return res;
    }

    function get_hero_flag() internal returns(uint)  {
        uint res = get_rand_int(6, 1);
        return res;
    }

    function get_heroShow(bool first) internal returns(string memory res) {
        HeroInfo memory hero_info;

        hero_info.hero_head = Integers.toString(uint(get_hero_head(first)));
        hero_info.hero_hand = Integers.toString(uint(get_hero_hand(first)));
        hero_info.hero_body = Integers.toString(uint(get_hero_body(first)));
        hero_info.hero_weapon = Integers.toString(uint(get_hero_weapon(first)));
        hero_info.hero_plat = Integers.toString(uint(get_hero_plat()));
        hero_info.hero_flag = Integers.toString(uint(get_hero_flag()));

        res = hero_info.hero_head.concat(hero_info.hero_hand);
        res = res.concat(hero_info.hero_body);
        res = res.concat(hero_info.hero_weapon);
        res = res.concat("0");
        res = res.concat(hero_info.hero_plat);
        res = res.concat("0");
        res = res.concat(hero_info.hero_flag);

        return res;
    }

    function get_hero_skill() internal returns(string memory res) {
        HeroInfo memory hero_info;
        hero_info.s_head = Integers.toString(uint(get_rand_int(6, 1)));
        hero_info.s_hand = Integers.toString(uint(get_rand_int(6, 1)));
        hero_info.s_body = Integers.toString(uint(get_rand_int(6, 1)));
        hero_info.s_weapon = Integers.toString(uint(get_rand_int(6, 1)));
        res = "0";
        res = res.concat(hero_info.s_head);
        res = res.concat("0");
        res = res.concat(hero_info.s_hand);
        res = res.concat("0");
        res = res.concat(hero_info.s_body);
        res = res.concat("0");
        res = res.concat(hero_info.s_weapon);

        return res;
    }

    function duplication(string memory a, string memory b, string memory c) private pure returns(bool) {
        uint x = parseIntSelf(a);
        uint y = parseIntSelf(b);
        uint z = parseIntSelf(c);
        if (x == y || x == z || y == z) {
            return true;
        }
        return false;
    }


    function generateDna(uint batch, bool first) public returns(string memory dna){
        HeroInfo memory hero_info_dna;

        hero_info_dna._batch = Integers.toString(uint(batch));
        hero_info_dna.unit = get_hero_unit(batch);
        hero_info_dna.camp =  get_hero_camp();
        hero_info_dna.attr = get_hero_attr();
        hero_info_dna.showD = get_heroShow(first);
        hero_info_dna.skillD = get_hero_skill();
        hero_info_dna.showR1 = get_heroShow(false);
        hero_info_dna.skillR1 = get_hero_skill();
        hero_info_dna.showR2 = get_heroShow(false);
        hero_info_dna.skillR2 = get_hero_skill();

        dna = hero_info_dna._batch.concat(hero_info_dna.unit);
        dna = dna.concat(hero_info_dna.camp);
        dna = dna.concat(hero_info_dna.attr);
        dna = dna.concat(hero_info_dna.showD);
        dna = dna.concat(hero_info_dna.skillD);
        dna = dna.concat(hero_info_dna.showR1);
        dna = dna.concat(hero_info_dna.skillR1);
        dna = dna.concat(hero_info_dna.showR2);
        dna = dna.concat(hero_info_dna.skillR2);

    }

    function _generatorDNA(uint256[] memory randomNumbers) internal returns (uint256 newDNA) {
        string memory dna = generateDna(11, true);
        emit GetNewDNA(dna);
    }

    function _generatorDNAFake(uint256[] memory randomNumbers) internal returns (uint256 newDNA) {
        newDNA = _baseDNA + (randomNumbers[0] % 100000000);
    }

    function openBox(address to) public payable heroReady keyReady {
        require(to != address(0), "New hero owner could not be NullAddress");

        uint256 keyBalance = balanceOfKey(msg.sender);
        require(keyBalance >= 1, "Key count not enought");

        bool isApproved = isApprovedForAllKeys(msg.sender, address(this));
        require(isApproved, "Keys has not been approved to box contract");

        // bool isRNGSendReady = IIdleRNG(_RNGContract).isSeedReady(msg.sender);
        // require(isRNGSendReady, "Random seed not ready");
        
        uint256 keyTokenId = keyOfOwnerByIndex(msg.sender, 0);
        burnKey(keyTokenId);

        // uint256[] memory randomNumbers = IIdleRNG(_RNGContract).expandRandomness(msg.sender, 10);
        // uint256 nDNA = _generatorDNAFake(randomNumbers);
        _baseDNA = _baseDNA + 10000;
        _safeMintHero(to, _baseDNA);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20TokenCallerBase {

    address internal _token20Contract;

    constructor() {
    }

    modifier token20Ready() {
        require(_token20Contract != address(0), "Token contract is not ready");
        _;
    }

    function token20Contract() public view returns (address) {
        return _token20Contract;
    }

    function setToken20Contract(address addr) public {
        _token20Contract = addr;
    }

    function transferERC20TokenFrom(address sender, address recipient, uint256 amount) internal {
        IERC20(_token20Contract).transferFrom(sender, recipient, amount);
    }

    function transferERC20Token(address recipient, uint256 amount) internal {
        IERC20(_token20Contract).transfer(recipient, amount);
    }

    function balanceOfERC20Token(address owner) internal view returns (uint256) {
        return IERC20(_token20Contract).balanceOf(owner);
    }
    
    function allowanceOfERC20Token(address owner, address spender) internal view returns (uint256) {
        return IERC20(_token20Contract).allowance(owner, spender);
    }

    function checkERC20TokenBalanceAndApproved(address owner, uint256 amount) internal view {
        uint256 tokenBalance = balanceOfERC20Token(owner);
        require(tokenBalance >= amount, "Token balance not enough");

        uint256 allowanceToken = allowanceOfERC20Token(owner, address(this));
        require(allowanceToken >= amount, "Token allowance not enough");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IIdleHero.sol";

contract ERC721HeroCallerBase {

    address internal _heroContract;

    constructor() {
    }

    modifier heroReady() {
        require(_heroContract != address(0), "Hero contract is not ready");
        _;
    }

    function heroContract() public view returns (address) {
        return _heroContract;
    }

    function setHeroContract(address addr) public {
        _heroContract = addr;
    }

    function ownerOfHero(uint256 tokenId) internal view returns (address)  {
        return IERC721(_heroContract).ownerOf(tokenId);
    }

    function _safeMintHero(address to, uint256 newDNA) internal {
        IIdleHero(_heroContract).safeMintHero(to, newDNA);
    }

    function _safeTransferHeroToken(address from, address to, uint256 tokenId) internal {
        IERC721(_heroContract).safeTransferFrom(from, to, tokenId);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../interface/IIdleKey.sol";

contract ERC721KeyCallerBase {

    address internal _keyContract;

    constructor() {
    }

    modifier keyReady() {
        require(_keyContract != address(0), "Key contract is not ready");
        _;
    }

    function keyContract() public view returns (address) {
        return _keyContract;
    }

    function setKeyContract(address addr) public {
        _keyContract = addr;
    }

    function balanceOfKey(address owner) internal view returns (uint256) {
        return IERC721Enumerable(_keyContract).balanceOf(owner);
    }
    
    function isApprovedForAllKeys(address owner, address operator) internal view returns (bool) {
        return IERC721Enumerable(_keyContract).isApprovedForAll(owner, operator);
    }

    function keyOfOwnerByIndex(address owner, uint256 index) internal view returns (uint256) {
        return IERC721Enumerable(_keyContract).tokenOfOwnerByIndex(owner, index);
    }

    function burnKey(uint256 tokenId) internal {
        IIdleKey(_keyContract).burn(tokenId);
    }

    function isKeySoldOut() internal view returns (bool) {
        return IIdleKey(_keyContract).isSoldOut();
    }

    function safeMintKey(address to) internal {
        IIdleKey(_keyContract).safeMintKey(to);
    }

    function safeMintKeys(address to, uint256 count) internal {
        IIdleKey(_keyContract).safeMintKeys(to, count);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IdleHero contract interface
interface IIdleHero {
    function safeMintHero(address to, uint256 dna) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IdleKey Interface
interface IIdleKey {
    function currentId() external view returns (uint256);
    function isSoldOut() external view returns (bool);
    function safeMintKeys(address to, uint256 count) external;
    function safeMintKey(address to) external returns (uint256);
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contract interface
interface IIdleRNG {
    function getRandomNumber(address from) external;

    function expandRandomness(address from, uint256 n) external returns (uint256[] memory expandedValues);

    function isSeedReady(address from) external view returns (bool);
}

pragma solidity ^0.8.0;

/**
 * ExStrings Library
 * 
 * In summary this is a simple library of string functions which make simple 
 * string operations less tedious in solidity.
 * 
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 * 
 * @author James Lockhart <[email protected]>
 */
library ExStrings {

    /**
     * Concat (High gas cost)
     * 
     * Appends two strings together and returns a new value
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     * 
     * Returns the length of the specified string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     * 
     * Extracts the beginning part of a string based on the desired length
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
        internal
        pure
        returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     * 
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }


    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     * 
     * Compares the characters of two strings, to ensure that they have an 
     * identical footprint
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     * 
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     * 
     * Converts all the values of a string to their corresponding upper case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string 
     */
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

pragma solidity ^0.8.0;

/**
 * Integers Library
 * 
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 * 
 * @author James Lockhart <[email protected]>
 */
library Integers {

    function parseInt(string memory _value)
        public
        pure
        returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }

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


    function toByte(uint8 _base)
        public
        pure
        returns (bytes1 _ret) {
        assembly {
            let m_alloc := add(msize(),0x1)
            mstore8(m_alloc, _base)
            _ret := mload(m_alloc)
        }
    }


    function toBytes(uint _base)
        internal
        pure
        returns (bytes memory _ret) {
        assembly {
            let m_alloc := add(msize(),0x1)
            _ret := mload(m_alloc)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _base)
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}