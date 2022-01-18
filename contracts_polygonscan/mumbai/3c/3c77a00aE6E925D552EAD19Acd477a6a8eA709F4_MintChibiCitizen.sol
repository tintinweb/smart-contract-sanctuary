// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IMintChibiCitizen.sol";
import "./interfaces/IChibiCitizen.sol";
import "./AccessControl.sol";

contract MintChibiCitizen is IMintChibiCitizen, AccessControl {
    // Generation 0 can have maximum 5555 citizens and others can have 10000 units.
    uint16 public constant GEN_0_CITIZEN_MAX_COUNT = 5555;
    uint16 public constant GEN_X_CITIZEN_MAX_COUNT = 10000;
    uint16 public constant ELIGIBLE_SEALS_MAX_COUNT = 2500;
    uint16 public constant MAX_CITIZEN_MINTED_PER_TX = 10;
    // minting states
    bool public mintWithSealEnabled;
    bool public mintWithWhitelistEnabled;
    bool public mintWithShinEnabled;
    // Probability for minting citizen: Soldier (10%), Farmer (30%), Trader (30%), Craftsman (30%)
    uint8[4] public citizenProbabilities = [1, 3, 3, 3];
    // current generation
    uint8 public currentGeneration;
    // amount of $SHIN used to mint a citizen, depending on the current generation
    uint16 public costToMint;
    // number of eligible Seals available which can be used for minting, maximum 2500
    uint16 public sealsUsed;
    /**
     * available citizens list for the current generation. We can randomize from this list for each minting
     * each generation should have 10000 citizens (excep gen 0) and each class should have maximum 3000 units
     * sample data [01152, 10224, 22442, 31252]
     * 01152: soldier (0) - id 1152
     * 10224: farmer (1) - id 224
     * 22442: soldier (2) - id 2442
     * 31252: craftsman (3) - id 1252
     */
    uint16[] public availableCitizens;
    // mapping to check if Seal was already used to claim Chibi Citizen
    mapping(uint256 => bool) private _sealsClaimed;
    // mapping of whitelist users
    mapping(address => bool) private _whitelist;
    // mapping to check if address was already used to claim Chibi Citizen with whitelist
    mapping(address => bool) private _whitelistClaimed;
    // external contracts
    IChibiCitizen private _chibiCitizenContract;
    IERC721 private _sealContract;
    ERC20Burnable private _shinContract;

    constructor(
        address chibiCitizenAddr,
        address sealAddr,
        address shinAddr
    ) {
        // setup related contracts
        _chibiCitizenContract = IChibiCitizen(chibiCitizenAddr);
        _sealContract = IERC721(sealAddr);
        _shinContract = ERC20Burnable(shinAddr);

        // enabled for gen 0
        mintWithSealEnabled = true;
        mintWithWhitelistEnabled = true;
    }

    // see {IMintChibiCitizen-safeMintCitizenWithSeal}
    function safeMintCitizenWithSeal(uint256[] calldata sealTokenIds)
        external
        override
    {
        require(mintWithSealEnabled, "Minting is disabled");
        require(sealTokenIds.length > 0, "Seals must not be blank");
        require(
            sealTokenIds.length <= ELIGIBLE_SEALS_MAX_COUNT - sealsUsed,
            "Not enough available seats"
        );
        require(
            sealTokenIds.length <= availableCitizens.length,
            "Not enough available citizens"
        );
        require(
            sealTokenIds.length <= MAX_CITIZEN_MINTED_PER_TX,
            "Exceed numbers of citizens per transaction"
        );
        for (uint256 i = 0; i < sealTokenIds.length; i++) {
            require(
                _sealsClaimed[sealTokenIds[i]] == false,
                string(
                    abi.encodePacked(
                        "Seal token ",
                        Strings.toString(sealTokenIds[i]),
                        "was used"
                    )
                )
            );
            require(
                _sealContract.ownerOf(sealTokenIds[i]) == _msgSender(),
                string(
                    abi.encodePacked(
                        "Wrong owner of Seal token ",
                        Strings.toString(sealTokenIds[i])
                    )
                )
            );
        }

        for (uint256 i = 0; i < sealTokenIds.length; i++) {
            _mintCitizen(1);
            _sealsClaimed[sealTokenIds[i]] = true;
            sealsUsed++;
        }
    }

    // see {IMintChibiCitizen-safeMintWithWhitelist}
    function safeMintWithWhitelist() external override {
        require(mintWithWhitelistEnabled, "Minting is disabled");
        require(_whitelist[msg.sender], "Not in whitelist");
        require(!_whitelistClaimed[msg.sender], "Wallet was already used");
        _mintCitizen(2);
        _whitelistClaimed[msg.sender] = true;
    }

    // see {IMintChibiCitizen-safeMintWithShin}
    function safeMintWithShin(uint256 numberOfTokens) external override {
        require(mintWithShinEnabled, "Minting is disabled");
        require(
            numberOfTokens <= availableCitizens.length,
            "Not enough available citizens"
        );
        require(
            numberOfTokens <= MAX_CITIZEN_MINTED_PER_TX,
            "Exceed numbers of citizens per transaction"
        );
        require(
            _shinContract.balanceOf(msg.sender) >= numberOfTokens * costToMint,
            "Not enough Shin"
        );
        require(
            _shinContract.allowance(msg.sender, address(this)) >=
                numberOfTokens * costToMint,
            "Not allowed to burn Shin"
        );

        // burn SHINs before minting citizen
        _shinContract.burnFrom(msg.sender, numberOfTokens * costToMint);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintCitizen(0);
        }
    }

    // see {IMintChibiCitizen-getCurrentGeneration}
    function getCurrentGeneration()
        external
        view
        override
        returns (ChibiGeneration memory gen)
    {
        gen.generation = currentGeneration;
        gen.availableCitizens = uint16(availableCitizens.length);
        gen.costToMint = costToMint;
        gen.mintWithSealEnabled = mintWithSealEnabled;
        gen.mintWithWhitelistEnabled = mintWithWhitelistEnabled;
        gen.mintWithShinEnabled = mintWithShinEnabled;
        for (uint256 i = 0; i < availableCitizens.length; i++) {
            uint256 class = availableCitizens[i] / 10000;
            if (class == 0) {
                gen.availableSoldiers++;
            } else if (class == 1) {
                gen.availableFarmers++;
            } else if (class == 2) {
                gen.availableTraders++;
            } else {
                gen.availableCraftsmen++;
            }
        }
    }

    // see {IMintChibiCitizen-checkSealStatuses}
    function checkSealStatuses(uint16[] calldata sealTokenIds)
        external
        view
        override
        returns (SealStatus memory status)
    {
        status.mintWithSealEnabled = mintWithSealEnabled;
        status.availableSlots = ELIGIBLE_SEALS_MAX_COUNT - sealsUsed;
        if (status.availableSlots > availableCitizens.length) {
            status.availableSlots = uint16(availableCitizens.length);
        }
        status.sealStatuses = new bool[](sealTokenIds.length);
        for (uint256 i = 0; i < sealTokenIds.length; i++) {
            status.sealStatuses[i] = !_sealsClaimed[sealTokenIds[i]];
        }
    }

    // see {IMintChibiCitizen-checkWhitelistStatus}
    function checkWhitelistStatus(address addr)
        external
        view
        override
        returns (uint8)
    {
        if (!mintWithWhitelistEnabled) {
            return 3;
        }
        if (availableCitizens.length == 0) {
            return 4;
        }
        if (!_whitelist[addr]) {
            return 1;
        }
        if (_whitelistClaimed[addr]) {
            return 2;
        }
        return 0;
    }

    // see {IMintChibiCitizen-setExternalContractAddresses}
    function setExternalContractAddresses(
        address chibiCitizenAddr,
        address sealAddr,
        address shinAddr
    ) external override onlyOwner {
        _chibiCitizenContract = IChibiCitizen(chibiCitizenAddr);
        _sealContract = IERC721(sealAddr);
        _shinContract = ERC20Burnable(shinAddr);
    }

    // see {IMintChibiCitizen-initializeNewGeneration}
    function initializeNewGeneration(uint8 gen, uint16 cost)
        external
        override
        onlyOwner
    {
        currentGeneration = gen;
        costToMint = cost;
        mintWithSealEnabled = false;
        mintWithWhitelistEnabled = false;
        mintWithShinEnabled = false;
        delete availableCitizens;

        emit MintEnabled(
            currentGeneration,
            costToMint,
            mintWithSealEnabled,
            mintWithWhitelistEnabled,
            mintWithShinEnabled
        );
    }

    // see {IMintChibiCitizen-addCitizens}
    function addCitizens(uint8 citizenClass) external override onlyOwner {
        // only allow 4 classes: Soldier(1), Farmer(2), Trader(3), Craftsman(4)
        require(citizenClass < 4, "Invalid class");

        uint16 totalCount = currentGeneration == 0
            ? GEN_0_CITIZEN_MAX_COUNT
            : GEN_X_CITIZEN_MAX_COUNT;
        uint256 newCitizenCount = citizenClass < 3
            ? (totalCount * citizenProbabilities[citizenClass]) / 10
            : totalCount - availableCitizens.length;
        for (uint16 i = 0; i < newCitizenCount; i++) {
            availableCitizens.push(citizenClass * 10000 + i);
        }
        assert(availableCitizens.length <= totalCount);
    }

    // see {IMintChibiCitizen-updateWhitelist}
    function updateWhitelist(
        address[] calldata newWhitelist,
        bool enabled,
        uint8 source
    ) external override onlyOwner {
        for (uint256 i = 0; i < newWhitelist.length; i++) {
            _whitelist[newWhitelist[i]] = enabled;
            emit WhitelistEnabled(newWhitelist[i], enabled, source);
        }
    }

    // see {IMintChibiCitizen-enablesMintCitizenWithSeal}
    function enablesMintCitizenWithSeal(bool enabled)
        external
        override
        onlyOwner
    {
        mintWithSealEnabled = enabled;

        emit MintEnabled(
            currentGeneration,
            costToMint,
            mintWithSealEnabled,
            mintWithWhitelistEnabled,
            mintWithShinEnabled
        );
    }

    // see {IMintChibiCitizen-enablesMintCitizenWithWhitelist}
    function enablesMintCitizenWithWhitelist(bool enabled)
        external
        override
        onlyOwner
    {
        mintWithWhitelistEnabled = enabled;

        emit MintEnabled(
            currentGeneration,
            costToMint,
            mintWithSealEnabled,
            mintWithWhitelistEnabled,
            mintWithShinEnabled
        );
    }

    // see {IMintChibiCitizen-enablesMintCitizenWithShin}
    function enablesMintCitizenWithShin(bool enabled)
        external
        override
        onlyOwner
    {
        mintWithShinEnabled = enabled;

        emit MintEnabled(
            currentGeneration,
            costToMint,
            mintWithSealEnabled,
            mintWithWhitelistEnabled,
            mintWithShinEnabled
        );
    }

    /**
     * mint chibi citizen, randomly pick one from availableCitizens
     * mintMethod: 0 - Shin, 1 - Seal, 2 - Whitelist
     */
    function _mintCitizen(uint8 mintMethod) private {
        require(availableCitizens.length > 0, "No available citizen to mint");

        // randomize a citizen
        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.number, msg.sender)
            )
        ) % availableCitizens.length;
        uint256 citizenClass = availableCitizens[randomIndex] / 10000;
        uint16 classId = availableCitizens[randomIndex] % 10000;
        // remove from the current list
        (
            availableCitizens[randomIndex],
            availableCitizens[availableCitizens.length - 1]
        ) = (
            availableCitizens[availableCitizens.length - 1],
            availableCitizens[randomIndex]
        );
        availableCitizens.pop();
        // mint
        _chibiCitizenContract.safeMint(
            msg.sender,
            currentGeneration,
            IChibiCitizen.CitizenClass(citizenClass),
            classId,
            mintMethod
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IMintChibiCitizen {
    event MintEnabled(
        uint8 indexed currentGeneration,
        uint16 costToMint,
        bool mintWithSealEnabled,
        bool mintWithWhitelistEnabled,
        bool mintWithShinEnabled
    );

    event WhitelistEnabled(address indexed wallet, bool enabled, uint8 source);

    struct ChibiGeneration {
        uint8 generation;
        bool mintWithSealEnabled;
        bool mintWithWhitelistEnabled;
        bool mintWithShinEnabled;
        uint16 costToMint;
        uint256 availableCitizens;
        uint256 availableSoldiers;
        uint256 availableFarmers;
        uint256 availableTraders;
        uint256 availableCraftsmen;
    }

    struct SealStatus {
        bool mintWithSealEnabled;
        uint16 availableSlots;
        bool[] sealStatuses;
    }

    // set external contract addresses (ChibiCitizen, Seal, Shin)
    function setExternalContractAddresses(
        address chibiCitizenAddr,
        address sealAddr,
        address shinAddr
    ) external;

    // mint citizen with Seals. Each seal can only be used once.
    function safeMintCitizenWithSeal(uint256[] calldata sealTokenIds) external;

    // mint citizen with whitelist. Each wallet address can only be used once.
    function safeMintWithWhitelist() external;

    // mint citizen with SHIN. Each seal can only be used once.
    function safeMintWithShin(uint256 numberOfTokens) external;

    // get the current generation which is available to mint
    function getCurrentGeneration()
        external
        view
        returns (ChibiGeneration memory);

    /*
     * check if Seals are egligible to claim Citizens
     */
    function checkSealStatuses(uint16[] calldata sealTokenIds)
        external
        view
        returns (SealStatus memory);

    /*
     * check status of an address in the current whitelist
     * return an uint status
     * 0: Eligible
     * 1: Not in whitelist
     * 2: Wallet address was already used
     * 3: Minting is disabled
     * 4: No available citizens
     */
    function checkWhitelistStatus(address addr) external view returns (uint8);

    // initialize new generation - only owner
    function initializeNewGeneration(uint8 gen, uint16 cost) external;

    // set up citizens by class - only owner
    function addCitizens(uint8 citizenClass) external;

    // update whitelist - only owner
    function updateWhitelist(
        address[] calldata newWhitelist,
        bool enabled,
        uint8 source
    ) external;

    // enable/disable minting with seal - only owner
    function enablesMintCitizenWithSeal(bool enabled) external;

    // enable/disable minting with whitelist - only owner
    function enablesMintCitizenWithWhitelist(bool enabled) external;

    // enable/disable minting with whitelist - only owner
    function enablesMintCitizenWithShin(bool enabled) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IChibiCitizen {
    // Mint method: 0 - Shin, 1 - Seal, 2 - Whitelist
    event Minted(
        uint256 indexed tokenId,
        uint8 indexed generation,
        CitizenClass indexed class,
        uint16 classId,
        uint8 mintMethod
    );
    event LevelChanged(
        uint256 indexed tokenId,
        uint8 indexed level,
        uint16 indexed exp
    );

    enum CitizenClass {
        SOLDIER,
        FARMER,
        TRADER,
        CRAFTSMAN
    }

    // metadata of citizen
    struct Citizen {
        CitizenClass class;
        uint16 classId;
        /** citizen generation from 0 => 5 */
        uint8 generation;
        /** default 1 */
        uint8 level;
        /** default 0 */
        uint16 exp;
        bool minted;
    }

    // Only minters can mint SHIN, which are other smart contracts (such as CitizenStaking contract)
    function safeMint(
        address to,
        uint8 generation,
        CitizenClass classs,
        uint16 classId,
        uint8 mintMethod
    ) external;

    // Only level managers can update citizen's level & exp
    function setLevel(
        uint256 tokenId,
        uint8 level,
        uint16 exp
    ) external;

    // set base token URI to use fixed metadata or dynamic metadata (including level, experience) - only owner
    function setBaseTokenURI(
        string calldata baseTokenURI,
        bool useFixedMetadata
    ) external;

    // return token metadata - only owner
    function getTokenMetadata(uint256 tokenId)
        external
        returns (Citizen memory);

    // return the number of soldiers, farmers, traders, craftsmen in a uint array
    function getTokenCounts()
        external
        view
        returns (uint256[] memory tokenCounts);

    // return the token ids owned by an owner
    function getTokenIds(address owner)
        external
        view
        returns (uint256[] memory tokenIds);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// @openzeppelin 4.4.1
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * Get the idea from Openzeppelin AccessControl
 */
abstract contract AccessControl is Ownable {
    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function grantRole(bytes32 role, address account) public virtual onlyOwner {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        onlyOwner
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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