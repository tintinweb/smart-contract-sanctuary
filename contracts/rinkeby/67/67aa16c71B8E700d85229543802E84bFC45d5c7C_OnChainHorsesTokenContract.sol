pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./HorseUtilityContract.sol";
import "base64-sol/base64.sol";

contract OnChainHorsesTokenContract is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    struct TokenTraits {
        uint8 maneColor;
        uint8 patternColor;
        uint8 hoofColor;
        uint8 bodyColor;
        uint8 background;
        uint8 tail;
        uint8 mane;
        uint8 pattern;
        uint8 headAccessory;
        uint8 bodyAccessory;
        uint8 utility;
        bool burned;
    }

    address public utilityContract = 0x0000000000000000000000000000000000000001;
    uint256 public maxTokens = 10000;
    uint256 public mintedTokens = 0;
    uint256 public burnedTokens = 0;
    uint256 public rebirthedTokens = 0;
    uint256 public burnedRebirthedTokens = 0;
    uint256 public mintPrice = 0.02 ether;
    uint256 public rebirthPrice = 0.01 ether;
    uint256 public claimableTokensPerAddress = 20;
    uint256 public maxTokensPerTxn = 5;
    uint256 public whitelistTokensUnlocksAtBlockNumber = 0;
    uint256 public whitelistAddressCount = 0;
    bool public saleActive = false;

    mapping(address => uint256) whitelistedAddressMintsLeft;
    mapping(uint256 => TokenTraits) public traits;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _maxTokens
    ) ERC721(tokenName, tokenSymbol) {
        maxTokens = _maxTokens;
    }

    function startSale() public onlyOwner {
        whitelistTokensUnlocksAtBlockNumber = block.number + 40320; // approximately a week
        saleActive = true;
        mint(1);
    }

    function setUtilityContract(address _utilityContract) public onlyOwner {
        utilityContract = _utilityContract;
    }

    function withdraw() public onlyOwner {
        uint256 balance = payable(address(this)).balance;
        payable(msg.sender).transfer(balance);
    }

    function packMetaData(
        string memory name,
        string memory svg,
        uint256 last
    ) private pure returns (bytes memory) {
        string memory comma = ",";
        if (last > 0) comma = "";
        return
            abi.encodePacked(
                '{"trait_type": "',
                name,
                '", "value": "',
                svg,
                '"}',
                comma
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        TokenTraits memory _traits = traits[tokenId];
        bytes memory _horseColors = HorseUtilityContract(utilityContract)
            .renderColors(
                _traits.maneColor,
                _traits.patternColor,
                _traits.hoofColor,
                _traits.bodyColor
            );

        string memory _image = Base64.encode(
            HorseUtilityContract(utilityContract).renderHorse(
                _horseColors,
                _traits.background,
                _traits.tail,
                _traits.mane,
                _traits.pattern,
                _traits.headAccessory,
                _traits.bodyAccessory,
                _traits.utility
            )
        );

        bytes memory _properties = abi.encodePacked(
            packMetaData(
                "background",
                HorseUtilityContract(utilityContract).getBackground(
                    _traits.background
                ),
                0
            ),
            packMetaData(
                "tail",
                HorseUtilityContract(utilityContract).getTail(
                    _traits.tail
                ),
                0
            ),
            packMetaData(
                "mane",
                HorseUtilityContract(utilityContract).getMane(
                    _traits.mane
                ),
                0
            ),
            packMetaData(
                "pattern",
                HorseUtilityContract(utilityContract).getPattern(
                    _traits.pattern
                ),
                0
            ),
            packMetaData(
                "head accessory",
                HorseUtilityContract(utilityContract).getHeadAccessory(
                    _traits.headAccessory
                ),
                0
            ),
            packMetaData(
                "body accessory",
                HorseUtilityContract(utilityContract).getBodyAccessory(
                    _traits.bodyAccessory
                ),
                0
            ),
            packMetaData(
                "utility",
                HorseUtilityContract(utilityContract).getUtility(
                    _traits.utility
                ),
                0
            )
        );

        _properties = abi.encodePacked(
            _properties,
            packMetaData(
                "mane color",
                HorseUtilityContract(utilityContract).getManeColor(
                    traits[tokenId].maneColor
                ),
                0
            ),
            packMetaData(
                "pattern color",
                HorseUtilityContract(utilityContract).getPatternColor(
                    traits[tokenId].patternColor
                ),
                0
            ),
            packMetaData(
                "hoof color",
                HorseUtilityContract(utilityContract).getHoofColor(
                    traits[tokenId].hoofColor
                ),
                0
            ),
            packMetaData(
                "body color",
                HorseUtilityContract(utilityContract).getBodyColor(
                    traits[tokenId].bodyColor
                ),
                1
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            // TODO:
                            // * create test that checks if number is rendered correctly
                            // * create test that checks so this is correct json
                            '{"name":"OnChain Horse #',
                            uint2str(tokenId),
                            '", "description": "", "attributes": [',
                            _properties,
                            '], "image":"data:image/svg+xml;base64,',
                            _image,
                            '"}'
                        )
                    )
                )
            );
    }

    function claim(uint256 amount) public {
        require(
            whitelistedAddressMintsLeft[msg.sender] >= amount,
            "Exceeded amount of claims left on address"
        );
        require(
            whitelistTokensUnlocksAtBlockNumber > block.number,
            "Claim period is over"
        );
        mint(amount);
        whitelistedAddressMintsLeft[msg.sender] -= amount;
    }

    function publicMint(uint256 amount) public payable {
        require(
            (amount.add(mintedTokens) <=
                maxTokens - whitelistAddressCount * claimableTokensPerAddress &&
                whitelistTokensUnlocksAtBlockNumber < block.number) ||
                (amount.add(mintedTokens) <= maxTokens &&
                    whitelistTokensUnlocksAtBlockNumber > block.number),
            "Amount exceeded max tokens"
        );
        require(mintPrice.mul(amount) <= msg.value, "Not enough ether to mint");
        require(saleActive, "Sale has not started");
        mint(amount);
    }

    function mint(uint256 amount) private {
        require(
            amount <= maxTokensPerTxn,
            "Trying to mint more than allowed tokens"
        );
        for (uint256 i = 0; i < amount; i++) {
            generateTraits(mintedTokens + i);
            _safeMint(msg.sender, mintedTokens + i);
        }
        mintedTokens += amount;
    }

    function rebirth(uint256 tokenId1, uint256 tokenId2) public payable {
        require(tokenId1 != tokenId2, "Not different tokens");
        require(ownerOf(tokenId1) == msg.sender, "Not owner of token");
        require(ownerOf(tokenId2) == msg.sender, "Not owner of token");
        require(!traits[tokenId1].burned, "Already burned");
        require(!traits[tokenId2].burned, "Already burned");
        require(msg.value == rebirthPrice, "Not enough ether to rebirth");

        traits[tokenId1].burned = true;
        traits[tokenId2].burned = true;
        _burn(tokenId1);
        _burn(tokenId2);

        if (tokenId1 < maxTokens) {
            burnedTokens++;
        } else {
            burnedRebirthedTokens++;
        }

        if (tokenId2 < maxTokens) {
            burnedTokens++;
        } else {
            burnedRebirthedTokens++;
        }

        uint256 rebirthTokenId = maxTokens.add(rebirthedTokens);
        generateTraits(rebirthTokenId);
        _safeMint(msg.sender, rebirthTokenId);
        rebirthedTokens++;
    }

    function generateTraits(uint256 tokenId) public {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, tokenId)
            )
        );
        uint8[] memory traitIds = new uint8[](11);

        traitIds[0] = HorseUtilityContract(utilityContract).getRandomManeColor(
            randomNumber
        );
        randomNumber = randomNumber / 10;
        traitIds[1] = HorseUtilityContract(utilityContract)
            .getRandomPatternColor(randomNumber);
        randomNumber = randomNumber / 10;
        traitIds[2] = HorseUtilityContract(utilityContract).getRandomHoofColor(
            randomNumber
        );
        randomNumber = randomNumber / 10;
        traitIds[3] = HorseUtilityContract(utilityContract).getRandomBodyColor(
            randomNumber
        );
        randomNumber = randomNumber / 10;
        traitIds[4] = HorseUtilityContract(utilityContract).getRandomBackground(
            randomNumber
        );
        randomNumber = randomNumber / 10;
        traitIds[5] = HorseUtilityContract(utilityContract).getRandomTail(
            randomNumber
        );
        randomNumber = randomNumber / 10;
        traitIds[6] = HorseUtilityContract(utilityContract).getRandomMane(
            randomNumber
        );
        randomNumber = randomNumber / 10;
        traitIds[7] = HorseUtilityContract(utilityContract).getRandomPattern(
            randomNumber
        );
        randomNumber = randomNumber / 10;
        traitIds[8] = HorseUtilityContract(utilityContract)
            .getRandomHeadAccessory(randomNumber);
        randomNumber = randomNumber / 10;
        traitIds[9] = HorseUtilityContract(utilityContract)
            .getRandomBodyAccessory(randomNumber);
        randomNumber = randomNumber / 10;
        traitIds[10] = HorseUtilityContract(utilityContract).getRandomUtility(
            randomNumber
        );

        traits[tokenId] = TokenTraits(
            traitIds[0],
            traitIds[1],
            traitIds[2],
            traitIds[3],
            traitIds[4],
            traitIds[5],
            traitIds[6],
            traitIds[7],
            traitIds[8],
            traitIds[9],
            traitIds[10],
            false
        );
    }

    function addWhitelistAddresses(address[] memory newWhitelistMembers)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < newWhitelistMembers.length; i++) {
            whitelistedAddressMintsLeft[
                newWhitelistMembers[i]
            ] = claimableTokensPerAddress;
            whitelistAddressCount++;
        }
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./OnChainHorsesTokenContract.sol";

contract HorseUtilityContract is Ownable {
    using SafeMath for uint256;

    address tokenContract = 0x0000000000000000000000000000000000000001;

    //SVG-parts
    string svgStart =
        "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 32 32'>";
    string svgEnd = "</svg>";
    string base =
        "<path fill='url(#body-color)' d='M19 7h1v1h-1zm2 0h1v1h-1zm-2 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1H9zm0 1h1v1H9zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1H9zm0-1h1v1H9zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-3 3h1v1H9zm0 1h1v1H9zm0 1h1v1H9zm0 1h1v1H9zm2 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm8 0h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm2 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1z' /><path fill='#000' opacity='.35' d='M21 7h1v1h-1zm0 14h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-10 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1z' /><path fill='url(#hoof-color)' d='M9 25h1v1H9zm2 0h1v1h-1zm8 0h1v1h-1zm2 0h1v1h-1z' /><path fill='#000' d='M21 10h1v1h-1z' />";

    // attribute svgs
    mapping(uint8 => string) public maneColorSvgs;
    mapping(uint8 => string) public patternSvgsColorSvgs;
    mapping(uint8 => string) public hoofColorSvgs;
    mapping(uint8 => string) public bodyColorSvgs;
    mapping(uint8 => string) public backgroundSvgs;
    mapping(uint8 => string) public tailSvgs;
    mapping(uint8 => string) public maneSvgs;
    mapping(uint8 => string) public patternSvgs;
    mapping(uint8 => string) public headAccessorySvgs;
    mapping(uint8 => string) public bodyAccessorySvgs;
    mapping(uint8 => string) public utilitySvgs;

    // attribute names
    mapping(uint8 => string) public maneColorNames;
    mapping(uint8 => string) public patternColorNames;
    mapping(uint8 => string) public hoofColorNames;
    mapping(uint8 => string) public bodyColorNames;
    mapping(uint8 => string) public backgroundNames;
    mapping(uint8 => string) public tailNames;
    mapping(uint8 => string) public maneNames;
    mapping(uint8 => string) public patternNames;
    mapping(uint8 => string) public headAccessoryNames;
    mapping(uint8 => string) public bodyAccessoryNames;
    mapping(uint8 => string) public utilityNames;

    // attribute rarities
    uint256[] public maneColorRarities;
    uint256[] public patternColorRarities;
    uint256[] public hoofColorRarities;
    uint256[] public bodyColorRarities;
    uint256[] public backgroundRarities;
    uint256[] public tailRarities;
    uint256[] public maneRarities;
    uint256[] public patternRarities;
    uint256[] public headAccessoryRarities;
    uint256[] public bodyAccessoryRarities;
    uint256[] public utilityRarities;

    // amount of attributes
    uint8 public maneColorCount = 0;
    uint8 public patternColorCount = 0;
    uint8 public hoofColorCount = 0;
    uint8 public bodyColorCount = 0;
    uint8 public backgroundCount = 0;
    uint8 public tailCount = 0;
    uint8 public maneCount = 0;
    uint8 public patternCount = 0;
    uint8 public headAccessoryCount = 0;
    uint8 public bodyAccessoryCount = 0;
    uint8 public utilityCount = 0;

    string private _contractBaseURI = "";

    constructor() {
        maneColorRarities = new uint256[](15);
        patternColorRarities = new uint256[](15);
        hoofColorRarities = new uint256[](15);
        bodyColorRarities = new uint256[](15);
        backgroundRarities = new uint256[](15);
        tailRarities = new uint256[](15);
        maneRarities = new uint256[](15);
        patternRarities = new uint256[](15);
        headAccessoryRarities = new uint256[](15);
        bodyAccessoryRarities = new uint256[](15);
        utilityRarities = new uint256[](15);
    }

    function setTokenContract(address _tokenContract) public onlyOwner {
        tokenContract = _tokenContract;
    }

    function addManeColors(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = maneColorCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            maneColorSvgs[index] = svgs[i];
            maneColorRarities[index] = rarities[i];
            maneColorNames[index] = names[i];
            maneColorCount++;
        }
    }

    function addPatternColors(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = patternColorCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            patternSvgsColorSvgs[index] = svgs[i];
            patternColorRarities[index] = rarities[i];
            patternColorNames[index] = names[i];
            patternColorCount++;
        }
    }

    function addHoofColors(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = hoofColorCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            hoofColorSvgs[index] = svgs[i];
            hoofColorRarities[index] = rarities[i];
            hoofColorNames[index] = names[i];
            hoofColorCount++;
        }
    }

    function addBodyColors(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = bodyColorCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            bodyColorSvgs[index] = svgs[i];
            bodyColorRarities[index] = rarities[i];
            bodyColorNames[index] = names[i];
            bodyColorCount++;
        }
    }

    function addBackgrounds(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = backgroundCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            backgroundSvgs[index] = svgs[i];
            backgroundRarities[index] = rarities[i];
            backgroundNames[index] = names[i];
            backgroundCount++;
        }
    }

    function addTails(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = tailCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            tailSvgs[index] = svgs[i];
            tailRarities[index] = rarities[i];
            tailNames[index] = names[i];
            tailCount++;
        }
    }

    function addManes(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = maneCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            maneSvgs[index] = svgs[i];
            maneRarities[index] = rarities[i];
            maneNames[index] = names[i];
            maneCount++;
        }
    }

    function addPatterns(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = patternCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            patternSvgs[index] = svgs[i];
            patternRarities[index] = rarities[i];
            patternNames[index] = names[i];
            patternCount++;
        }
    }

    function addHeadAccessories(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = headAccessoryCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            headAccessorySvgs[index] = svgs[i];
            headAccessoryRarities[index] = rarities[i];
            headAccessoryNames[index] = names[i];
            headAccessoryCount++;
        }
    }

    function addBodyAccessories(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = bodyAccessoryCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            bodyAccessorySvgs[index] = svgs[i];
            bodyAccessoryRarities[index] = rarities[i];
            bodyAccessoryNames[index] = names[i];
            bodyAccessoryCount++;
        }
    }

    function addUtilities(
        string[] memory svgs,
        string[] memory names,
        uint256[] memory rarities
    ) public onlyOwner {
        uint8 initialCount = utilityCount;
        for (uint8 i = 0; i < svgs.length; i++) {
            uint8 index = i + initialCount;
            utilitySvgs[index] = svgs[i];
            utilityRarities[index] = rarities[i];
            utilityNames[index] = names[i];
            utilityCount++;
        }
    }

    function getRandomIndex(
        uint256[] memory attributeRarities,
        uint8 attributeCount,
        uint256 randomNumber
    ) private pure returns (uint8 index) {
        uint256 random10k = randomNumber % 10000;
        uint256 steps = 0;
        for (uint8 i = 0; i < attributeCount; i++) {
            uint256 currentRarity = attributeRarities[i] + steps;
            if (random10k < currentRarity) {
                return i;
            }
            steps = currentRarity;
        }
        return 0;
    }

    function getRandomManeColor(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return getRandomIndex(maneColorRarities, maneColorCount, randomNumber);
    }

    function getRandomPatternColor(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return
            getRandomIndex(
                patternColorRarities,
                patternColorCount,
                randomNumber
            );
    }

    function getRandomHoofColor(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return getRandomIndex(hoofColorRarities, hoofColorCount, randomNumber);
    }

    function getRandomBodyColor(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return getRandomIndex(bodyColorRarities, bodyColorCount, randomNumber);
    }

    function getRandomBackground(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return
            getRandomIndex(backgroundRarities, backgroundCount, randomNumber);
    }

    function getRandomTail(uint256 randomNumber) public view returns (uint8) {
        if (msg.sender != tokenContract) return 0;
        return getRandomIndex(tailRarities, tailCount, randomNumber);
    }

    function getRandomMane(uint256 randomNumber) public view returns (uint8) {
        if (msg.sender != tokenContract) return 0;
        return getRandomIndex(maneRarities, maneCount, randomNumber);
    }

    function getRandomPattern(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return getRandomIndex(patternRarities, patternCount, randomNumber);
    }

    function getRandomHeadAccessory(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return
            getRandomIndex(
                headAccessoryRarities,
                headAccessoryCount,
                randomNumber
            );
    }

    function getRandomBodyAccessory(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return
            getRandomIndex(
                bodyAccessoryRarities,
                bodyAccessoryCount,
                randomNumber
            );
    }

    function getRandomUtility(uint256 randomNumber)
        public
        view
        returns (uint8)
    {
        if (msg.sender != tokenContract) return 0;
        return getRandomIndex(utilityRarities, utilityCount, randomNumber);
    }

    function getManeColor(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return maneColorNames[index];
    }

    function getPatternColor(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return patternColorNames[index];
    }

    function getHoofColor(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return hoofColorNames[index];
    }

    function getBodyColor(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return bodyColorNames[index];
    }

    function getBackground(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return backgroundNames[index];
    }

    function getTail(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return tailNames[index];
    }

    function getMane(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return maneNames[index];
    }

    function getPattern(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return patternNames[index];
    }

    function getHeadAccessory(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return headAccessoryNames[index];
    }

    function getBodyAccessory(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return bodyAccessoryNames[index];
    }

    function getUtility(uint8 index) public view returns (string memory) {
        if (msg.sender != tokenContract) return "";
        return utilityNames[index];
    }

    function renderHorse(
        bytes memory colors,
        uint8 background,
        uint8 tail,
        uint8 mane,
        uint8 pattern,
        uint8 headAccessory,
        uint8 bodyAccessory,
        uint8 utility
    ) public view returns (bytes memory) {
        if (msg.sender != tokenContract) return "";
        bytes memory start = abi.encodePacked(
            svgStart,
            colors,
            backgroundSvgs[background],
            base,
            patternSvgs[pattern]
        );
        return
            abi.encodePacked(
                start,
                tailSvgs[tail],
                maneSvgs[mane],
                headAccessorySvgs[headAccessory],
                bodyAccessorySvgs[bodyAccessory],
                utilitySvgs[utility],
                svgEnd
            );
    }

    function packColor(string memory colorName, string memory colorSvg)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "<linearGradient id='",
                colorName,
                "'><stop stop-color='",
                colorSvg,
                "'/></linearGradient>"
            );
    }

    function renderColors(
        uint8 maneColor,
        uint8 patternColor,
        uint8 hoofColor,
        uint8 bodyColor
    ) public view returns (bytes memory) {
        return
            abi.encodePacked(
                "<defs>",
                packColor("mane-color", maneColorSvgs[maneColor]),
                packColor("pattern-color", patternSvgsColorSvgs[patternColor]),
                packColor("hoof-color", hoofColorSvgs[hoofColor]),
                packColor("body-color", bodyColorSvgs[bodyColor]),
                "</defs>"
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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