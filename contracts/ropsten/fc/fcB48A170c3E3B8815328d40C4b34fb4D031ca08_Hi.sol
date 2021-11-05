// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 *      __  __                 _
 *     |  \/  | ___  _ __  ___| |_ ___ _ __
 *     | |\/| |/ _ \| '_ \/ __| __/ _ \ '__|
 *     | |  | | (_) | | | \__ \ ||  __/ |
 *     |_|__|_|\___/|_| |_|___/\__\___|_|_     _
 *     / ___|  __ _| |_ ___  ___| |__ (_) |__ | | ___  ___
 *     \___ \ / _` | __/ _ \/ __| '_ \| | '_ \| |/ _ \/ __|
 *      ___) | (_| | || (_) \__ \ | | | | |_) | |  __/\__ \
 *     |____/ \__,_|\__\___/|___/_| |_|_|_.__/|_|\___||___/
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./ERC2981ContractWideRoyalties.sol";
import "./MerkleProof.sol";

/**
 * @notice Original Satoshibles contract interface
 */
interface IHey {
    function ownerOf(
        uint256 _tokenId
    )
        external
        view
        returns (address owner);
}

/**
 * @title Monster Satoshibles
 * @notice NFT of monsters that can be burned and combined into prime monsters!
 * @author Aaron Hanson
 */
contract Hi is ERC721, ERC2981ContractWideRoyalties, Ownable {

    /// The max token supply
    uint256 public constant MAX_SUPPLY = 6666;

    /// The presale portion of the max supply
    uint256 public constant MAX_PRESALE_SUPPLY = 3333;

    /// Mysterious constants 💀
    uint256 constant DEATH = 0xDEAD;
    uint256 constant LIFE = 0x024350AC;
    uint256 constant ALPHA = LIFE % DEATH * 1000;
    uint256 constant OMEGA = LIFE % DEATH + ALPHA;

    /// Prime types
    uint256 constant FRANKENSTEIN = 0;
    uint256 constant WEREWOLF = 1;
    uint256 constant VAMPIRE = 2;
    uint256 constant ZOMBIE = 3;
    uint256 constant INVALID = 4;

    /// Number of prime parts
    uint256 constant NUM_PARTS = 4;

    /// Bitfield mask for prime part detection during prime minting
    uint256 constant HAS_ALL_PARTS = 2 ** NUM_PARTS - 1;

    /// Merkle root summarizing the presale whitelist
    bytes32 public constant WHITELIST_MERKLE_ROOT =
        0xdb6eea27a6a35a02d1928e9582f75c1e0a518ad5992b5cfee9cc0d86fb387b8d;

    /// Additional team wallets (can withdraw)
    address public constant TEAM_WALLET_A =
        0xF746362D8162Eeb3624c17654FFAa6EB8bD71820;
    address public constant TEAM_WALLET_B =
        0x16659F9D2ab9565B0c07199687DE3634c0965391;
    address public constant TEAM_WALLET_C =
        0x7a73f770873761054ab7757E909ae48f771379D4;
    address public constant TEAM_WALLET_D =
        0xB7c7e3809591F720f3a75Fb3efa05E76E6B7B92A;

    /// The maximum ERC-2981 royalties percentage
    uint256 public constant MAX_ROYALTIES_PCT = 600;

    /// Original Satoshibles contract instance
    IHey public immutable SATOSHIBLE_CONTRACT;

    /// The max presale token ID
    uint256 public immutable MAX_PRESALE_TOKEN_ID;

    /// The current token supply
    uint256 public totalSupply;

    /// The current state of the sale
    bool public saleIsActive;

    /// Indicates if the public sale was opened manually
    bool public publicSaleOpenedEarly;

    /// The default and discount token prices in wei
    uint256 public tokenPrice    = 99900000000000000; // 0.0999 ether
    uint256 public discountPrice = 66600000000000000; // 0.0666 ether

    /// Tracks number of presale mints already used per address
    mapping(address => uint256) public whitelistMintsUsed;

    /// The current state of the laboratory
    bool public laboratoryHasElectricity;

    /// Merkle root summarizing all monster IDs and their prime parts
    bytes32 public primePartsMerkleRoot;

    /// The provenance URI
    string public provenanceURI = "Not Yet Set";

    /// When true, the provenanceURI can no longer be changed
    bool public provenanceUriLocked;

    /// The base URI
    string public baseURI = "https://api.satoshibles.com/monsters/token/";

    /// When true, the baseURI can no longer be changed
    bool public baseUriLocked;

    /// Use Counters for token IDs
    using Counters for Counters.Counter;

    /// Monster token ID counter
    Counters.Counter monsterIds;

    /// Prime token ID counter for each prime type
    mapping(uint256 => Counters.Counter) primeIds;

    /// Prime ID offsets for each prime type
    mapping(uint256 => uint256) primeIdOffset;

    /// Bitfields that track original Satoshibles already used for discounts
    mapping(uint256 => uint256) satDiscountBitfields;

    /// Bitfields that track original Satoshibles already used in lab
    mapping(uint256 => uint256) satLabBitfields;

    /**
     * @notice Emitted when the saleIsActive flag changes
     * @param isActive Indicates whether or not the sale is now active
     */
    event SaleStateChanged(
        bool indexed isActive
    );

    /**
     * @notice Emitted when the public sale is opened early
     */
    event PublicSaleOpenedEarly();

    /**
     * @notice Emitted when the laboratoryHasElectricity flag changes
     * @param hasElectricity Indicates whether or not the laboratory is open
     */
    event LaboratoryStateChanged(
        bool indexed hasElectricity
    );

    /**
     * @notice Emitted when a prime is created in the lab
     * @param creator The account that created the prime
     * @param primeId The ID of the prime created
     * @param satId The Satoshible used as the 'key' to the lab
     * @param monsterIdsBurned The IDs of the monsters burned
     */
    event PrimeCreated(
        address indexed creator,
        uint256 indexed primeId,
        uint256 indexed satId,
        uint256[4] monsterIdsBurned
    );

    /**
     * @notice Requires the specified Satoshible to be owned by msg.sender
     * @param _satId Original Satoshible token ID
     */
    modifier onlySatHolder(
        uint256 _satId
    ) {
        require(
            SATOSHIBLE_CONTRACT.ownerOf(_satId) == _msgSender(),
            "Sat not owned"
        );
        _;
    }

    /**
     * @notice Requires msg.sender to be the owner or a team wallet
     */
    modifier onlyTeam() {
        require(
            _msgSender() == TEAM_WALLET_A
                || _msgSender() == TEAM_WALLET_B
                || _msgSender() == TEAM_WALLET_C
                || _msgSender() == TEAM_WALLET_D
                || _msgSender() == owner(),
            "Not owner or team address"
        );
        _;
    }

    /**
     * @notice Boom... Let's go!
     * @param _initialBatchCount Number of tokens to mint to msg.sender
     * @param _immutableSatoshible Original Satoshible contract address
     * @param _royaltiesPercentage Initial royalties percentage for ERC-2981
     */
    constructor(
        uint256 _initialBatchCount,
        address _immutableSatoshible,
        uint256 _royaltiesPercentage
    )
        ERC721("Hi", "HI")
    {
        SATOSHIBLE_CONTRACT = IHey(
            _immutableSatoshible
        );

        require(
            _royaltiesPercentage <= MAX_ROYALTIES_PCT,
            "Royalties too high"
        );

        _setRoyalties(
            _msgSender(),
            _royaltiesPercentage
        );

        _initializePrimeIdOffsets();
        _initializeSatDiscountAvailability();
        _initializeSatLabAvailability();
        _mintTokens(_initialBatchCount);

        require(
            belowMaximum(_initialBatchCount, MAX_PRESALE_SUPPLY,
                MAX_SUPPLY
            ) == true,
            "Would exceed max supply"
        );

        unchecked {
            MAX_PRESALE_TOKEN_ID = _initialBatchCount + MAX_PRESALE_SUPPLY;
        }
    }

    /**
     * @notice Mints monster tokens during presale, optionally with discounts
     * @param _numberOfTokens Number of tokens to mint
     * @param _satsForDiscount Array of Satoshible IDs for discounted mints
     * @param _whitelistedTokens Account's total number of whitelisted tokens
     * @param _proof Merkle proof to be verified
     */
    function mintTokensPresale(
        uint256 _numberOfTokens,
        uint256[] calldata _satsForDiscount,
        uint256 _whitelistedTokens,
        bytes32[] calldata _proof
    )
        external
        payable
    {
        require(
            publicSaleOpenedEarly == false,
            "Presale has ended"
        );

        require(
            belowMaximum(monsterIds.current(), _numberOfTokens,
                MAX_PRESALE_TOKEN_ID
            ) == true,
            "Would exceed presale size"
        );

        require(
            belowMaximum(whitelistMintsUsed[_msgSender()], _numberOfTokens,
                _whitelistedTokens
            ) == true,
            "Would exceed whitelisted count"
        );

        require(
            verifyWhitelisted(_msgSender(), _whitelistedTokens,
                _proof
            ) == true,
            "Invalid whitelist proof"
        );

        whitelistMintsUsed[_msgSender()] += _numberOfTokens;

        _doMintTokens(
            _numberOfTokens,
            _satsForDiscount
        );
    }

    /**
     * @notice Mints monsters during public sale, optionally with discounts
     * @param _numberOfTokens Number of monster tokens to mint
     * @param _satsForDiscount Array of Satoshible IDs for discounted mints
     */
    function mintTokensPublicSale(
        uint256 _numberOfTokens,
        uint256[] calldata _satsForDiscount
    )
        external
        payable
    {
        require(
            publicSaleOpened() == true,
            "Public sale has not started"
        );

        require(
            belowMaximum(monsterIds.current(), _numberOfTokens,
                MAX_SUPPLY
            ) == true,
            "Not enough tokens left"
        );

        _doMintTokens(
            _numberOfTokens,
            _satsForDiscount
        );
    }

    /**
     * @notice Mints a prime token by burning two or more monster tokens
     * @param _primeType Prime type to mint
     * @param _satId Original Satoshible token ID to use as 'key' to the lab
     * @param _monsterIds Array of monster token IDs to potentially be burned
     * @param _monsterPrimeParts Array of bitfields of monsters' prime parts
     * @param _proofs Array of merkle proofs to be verified
     */
    function mintPrimeToken(
        uint256 _primeType,
        uint256 _satId,
        uint256[] calldata _monsterIds,
        uint256[] calldata _monsterPrimeParts,
        bytes32[][] calldata _proofs
    )
        external
        onlySatHolder(_satId)
    {
        require(
            laboratoryHasElectricity == true,
            "Prime laboratory not yet open"
        );

        require(
            _primeType < INVALID,
            "Invalid prime type"
        );

        require(
            belowMaximum(
                primeIdOffset[_primeType],
                primeIds[_primeType].current() + 1,
                primeIdOffset[_primeType + 1]
            ) == true,
            "No more primes left of this type"
        );

        require(
            satIsAvailableForLab(_satId) == true,
            "Sat has already been used in lab"
        );

        // bitfield tracking aggregate parts across monsters
        // (head = 1, eyes = 2, mouth = 4, body = 8)
        uint256 combinedParts;

        uint256[4] memory burnedIds;

        unchecked {
            uint256 burnedIndex;
            for (uint256 i = 0; i < _monsterIds.length; i++) {
                require(
                    verifyMonsterPrimeParts(
                        _monsterIds[i],
                        _monsterPrimeParts[i],
                        _proofs[i]
                    ) == true,
                    "Invalid monster traits proof"
                );

                uint256 theseParts = _monsterPrimeParts[i]
                    >> (_primeType * NUM_PARTS) & HAS_ALL_PARTS;

                if (combinedParts | theseParts != combinedParts) {
                    _burn(
                        _monsterIds[i]
                    );
                    burnedIds[burnedIndex++] = _monsterIds[i];
                    combinedParts |= theseParts;
                    if (combinedParts == HAS_ALL_PARTS) {
                        break;
                    }
                }
            }
        }

        require(
            combinedParts == HAS_ALL_PARTS,
            "Not enough parts for this prime"
        );

        _retireSatFromLab(_satId);
        primeIds[_primeType].increment();

        unchecked {
            uint256 primeId = primeIdOffset[_primeType]
                + primeIds[_primeType].current();

            totalSupply++;

            _safeMint(
                _msgSender(),
                primeId
            );

            emit PrimeCreated(
                _msgSender(),
                primeId,
                _satId,
                burnedIds
            );
        }
    }

    /**
     * @notice Activates or deactivates the sale
     * @param _isActive Whether to activate or deactivate the sale
     */
    function activateSale(
        bool _isActive
    )
        external
        onlyOwner
    {
        saleIsActive = _isActive;

        emit SaleStateChanged(
            _isActive
        );
    }

    /**
     * @notice Starts the public sale before MAX_PRESALE_TOKEN_ID is minted
     */
    function openPublicSaleEarly()
        external
        onlyOwner
    {
        publicSaleOpenedEarly = true;

        emit PublicSaleOpenedEarly();
    }

    /**
     * @notice Modifies the prices in case of major ETH price changes
     * @param _tokenPrice The new default token price
     * @param _discountPrice The new discount token price
     */
    function updateTokenPrices(
        uint256 _tokenPrice,
        uint256 _discountPrice
    )
        external
        onlyOwner
    {
        require(
            _tokenPrice >= _discountPrice,
            "discountPrice cannot be larger"
        );

        require(
            saleIsActive == false,
            "Sale is active"
        );

        tokenPrice = _tokenPrice;
        discountPrice = _discountPrice;
    }

    /**
     * @notice Sets primePartsMerkleRoot summarizing all monster prime parts
     * @param _merkleRoot The new merkle root
     */
    function setPrimePartsMerkleRoot(
        bytes32 _merkleRoot
    )
        external
        onlyOwner
    {
        primePartsMerkleRoot = _merkleRoot;
    }

    /**
     * @notice Turns the laboratory on or off
     * @param _hasElectricity Whether to turn the laboratory on or off
     */
    function electrifyLaboratory(
        bool _hasElectricity
    )
        external
        onlyOwner
    {
        laboratoryHasElectricity = _hasElectricity;

        emit LaboratoryStateChanged(
            _hasElectricity
        );
    }

    /**
     * @notice Mints the final prime token
     */
    function mintFinalPrime()
        external
        onlyOwner
    {
        require(
            _exists(OMEGA) == false,
            "Final prime already exists"
        );

        unchecked {
            totalSupply++;
        }

        _safeMint(
            _msgSender(),
            OMEGA
        );
    }

    /**
     * @notice Sets the provenance URI
     * @param _newProvenanceURI The new provenance URI
     */
    function setProvenanceURI(
        string calldata _newProvenanceURI
    )
        external
        onlyOwner
    {
        require(
            provenanceUriLocked == false,
            "Provenance URI has been locked"
        );

        provenanceURI = _newProvenanceURI;
    }

    /**
     * @notice Prevents further changes to the provenance URI
     */
    function lockProvenanceURI()
        external
        onlyOwner
    {
        provenanceUriLocked = true;
    }

    /**
     * @notice Sets a new base URI
     * @param _newBaseURI The new base URI
     */
    function setBaseURI(
        string calldata _newBaseURI
    )
        external
        onlyOwner
    {
        require(
            baseUriLocked == false,
            "Base URI has been locked"
        );

        baseURI = _newBaseURI;
    }

    /**
     * @notice Prevents further changes to the base URI
     */
    function lockBaseURI()
        external
        onlyOwner
    {
        baseUriLocked = true;
    }

    /**
     * @notice Withdraws sale proceeds
     * @param _amount Amount to withdraw in wei
     */
    function withdraw(
        uint256 _amount
    )
        external
        onlyTeam
    {
        payable(_msgSender()).transfer(
            _amount
        );
    }

    /**
     * @notice Withdraws any other tokens
     * @dev WARNING: Double check token is legit before calling this
     * @param _token Contract address of token
     * @param _to Address to which to withdraw
     * @param _amount Amount to withdraw
     * @param _hasVerifiedToken Must be true (sanity check)
     */
    function withdrawOther(
        address _token,
        address _to,
        uint256 _amount,
        bool _hasVerifiedToken
    )
        external
        onlyOwner
    {
        require(
            _hasVerifiedToken == true,
            "Need to verify token"
        );

        IERC20(_token).transfer(
            _to,
            _amount
        );
    }

    /**
     * @notice Sets token royalties (ERC-2981)
     * @param _recipient Recipient of the royalties
     * @param _value Royalty percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        external
        onlyOwner
    {
        require(
            _value <= MAX_ROYALTIES_PCT,
            "Royalties too high"
        );

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /**
     * @notice Checks which Satoshibles can still be used for a discounted mint
     * @dev Uses bitwise operators to find the bit representing each Satoshible
     * @param _satIds Array of original Satoshible token IDs
     * @return Token ID for each of the available _satIds, zero otherwise
     */
    function satsAvailableForDiscountMint(
        uint256[] calldata _satIds
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory satsAvailable = new uint256[](_satIds.length);

        unchecked {
            for (uint256 i = 0; i < _satIds.length; i++) {
                if (satIsAvailableForDiscountMint(_satIds[i])) {
                    satsAvailable[i] = _satIds[i];
                }
            }
        }

        return satsAvailable;
    }

    /**
     * @notice Checks which Satoshibles can still be used to mint a prime
     * @dev Uses bitwise operators to find the bit representing each Satoshible
     * @param _satIds Array of original Satoshible token IDs
     * @return Token ID for each of the available _satIds, zero otherwise
     */
    function satsAvailableForLab(
        uint256[] calldata _satIds
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory satsAvailable = new uint256[](_satIds.length);

        unchecked {
            for (uint256 i = 0; i < _satIds.length; i++) {
                if (satIsAvailableForLab(_satIds[i])) {
                    satsAvailable[i] = _satIds[i];
                }
            }
        }

        return satsAvailable;
    }

    /**
     * @notice Checks if a Satoshible can still be used for a discounted mint
     * @dev Uses bitwise operators to find the bit representing the Satoshible
     * @param _satId Original Satoshible token ID
     * @return isAvailable True if _satId can be used for a discounted mint
     */
    function satIsAvailableForDiscountMint(
        uint256 _satId
    )
        public
        view
        returns (bool isAvailable)
    {
        unchecked {
            uint256 page = _satId / 256;
            uint256 shift = _satId % 256;
            isAvailable = satDiscountBitfields[page] >> shift & 1 == 1;
        }
    }

    /**
     * @notice Checks if a Satoshible can still be used to mint a prime
     * @dev Uses bitwise operators to find the bit representing the Satoshible
     * @param _satId Original Satoshible token ID
     * @return isAvailable True if _satId can still be used to mint a prime
     */
    function satIsAvailableForLab(
        uint256 _satId
    )
        public
        view
        returns (bool isAvailable)
    {
        unchecked {
            uint256 page = _satId / 256;
            uint256 shift = _satId % 256;
            isAvailable = satLabBitfields[page] >> shift & 1 == 1;
        }
    }

    /**
     * @notice Verifies a merkle proof for a monster ID and its prime parts
     * @param _monsterId Monster token ID
     * @param _monsterPrimeParts Bitfield of the monster's prime parts
     * @param _proof Merkle proof be verified
     * @return isVerified True if the merkle proof is verified
     */
    function verifyMonsterPrimeParts(
        uint256 _monsterId,
        uint256 _monsterPrimeParts,
        bytes32[] calldata _proof
    )
        public
        view
        returns (bool isVerified)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _monsterId,
                _monsterPrimeParts
            )
        );

        isVerified = MerkleProof.verify(
            _proof,
            primePartsMerkleRoot,
            node
        );
    }

    /**
     * @notice Gets total count of existing prime tokens for a prime type
     * @param _primeType Prime type
     * @return supply Count of existing prime tokens for this prime type
     */
    function primeSupply(
        uint256 _primeType
    )
        public
        view
        returns (uint256 supply)
    {
        supply = primeIds[_primeType].current();
    }

    /**
     * @notice Gets total count of existing prime tokens
     * @return supply Count of existing prime tokens
     */
    function totalPrimeSupply()
        public
        view
        returns (uint256 supply)
    {
        unchecked {
            supply = primeSupply(FRANKENSTEIN)
                + primeSupply(WEREWOLF)
                + primeSupply(VAMPIRE)
                + primeSupply(ZOMBIE)
                + (_exists(OMEGA) ? 1 : 0);
        }
    }

    /**
     * @notice Gets total count of monsters burned
     * @return burned Count of monsters burned
     */
    function monstersBurned()
        public
        view
        returns (uint256 burned)
    {
        unchecked {
            burned = monsterIds.current() + totalPrimeSupply() - totalSupply;
        }
    }

    /**
     * @notice Gets state of public sale
     * @return publicSaleIsOpen True if public sale phase has begun
     */
    function publicSaleOpened()
        public
        view
        returns (bool publicSaleIsOpen)
    {
        publicSaleIsOpen =
            publicSaleOpenedEarly == true ||
            monsterIds.current() >= MAX_PRESALE_TOKEN_ID;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721, ERC2981Base)
        returns (bool doesSupportInterface)
    {
        doesSupportInterface = super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Verifies a merkle proof for an account's whitelisted tokens
     * @param _account Account to verify
     * @param _whitelistedTokens Number of whitelisted tokens for _account
     * @param _proof Merkle proof to be verified
     * @return isVerified True if the merkle proof is verified
     */
    function verifyWhitelisted(
        address _account,
        uint256 _whitelistedTokens,
        bytes32[] calldata _proof
    )
        public
        pure
        returns (bool isVerified)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _account,
                _whitelistedTokens
            )
        );

        isVerified = MerkleProof.verify(
            _proof,
            WHITELIST_MERKLE_ROOT,
            node
        );
    }

    /**
     * @dev Base monster burning function
     * @param _tokenId Monster token ID to burn
     */
    function _burn(
        uint256 _tokenId
    )
        internal
        override
    {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId) == true,
            "not owner nor approved"
        );

        unchecked {
            totalSupply -= 1;
        }

        super._burn(
            _tokenId
        );
    }

    /**
     * @dev Base URI for computing tokenURI
     * @return Base URI string
     */
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    /**
     * @dev Base monster minting function, calculates price with discounts
     * @param _numberOfTokens Number of monster tokens to mint
     * @param _satsForDiscount Array of Satoshible IDs for discounted mints
     */
    function _doMintTokens(
        uint256 _numberOfTokens,
        uint256[] calldata _satsForDiscount
    )
        private
    {
        require(
            saleIsActive == true,
            "Sale must be active"
        );

        require(
            _numberOfTokens >= 1,
            "Need at least 1 token"
        );

        require(
            _numberOfTokens <= 50,
            "Max 50 at a time"
        );

        require(
            _satsForDiscount.length <= _numberOfTokens,
            "Too many sats for discount"
        );

        unchecked {
            uint256 discountIndex;

            for (; discountIndex < _satsForDiscount.length; discountIndex++) {
                _useSatForDiscountMint(_satsForDiscount[discountIndex]);
            }

            uint256 totalPrice = tokenPrice * (_numberOfTokens - discountIndex)
                + discountPrice * discountIndex;

            require(
                totalPrice == msg.value,
                "Ether amount not correct"
            );
        }

        _mintTokens(
            _numberOfTokens
        );
    }

    /**
     * @dev Base monster minting function.
     * @param _numberOfTokens Number of monster tokens to mint
     */
    function _mintTokens(
        uint256 _numberOfTokens
    )
        private
    {
        unchecked {
            totalSupply += _numberOfTokens;

            for (uint256 i = 0; i < _numberOfTokens; i++) {
                monsterIds.increment();
                _safeMint(
                    _msgSender(),
                    monsterIds.current()
                );
            }
        }
    }

    /**
     * @dev Marks a Satoshible ID as having been used for a discounted mint
     * @param _satId Satoshible ID that was used for a discounted mint
     */
    function _useSatForDiscountMint(
        uint256 _satId
    )
        private
        onlySatHolder(_satId)
    {
        require(
            satIsAvailableForDiscountMint(_satId) == true,
            "Sat for discount already used"
        );

        unchecked {
            uint256 page = _satId / 256;
            uint256 shift = _satId % 256;
            satDiscountBitfields[page] &= ~(1 << shift);
        }
    }

    /**
     * @dev Marks a Satoshible ID as having been used to mint a prime
     * @param _satId Satoshible ID that was used to mint a prime
     */
    function _retireSatFromLab(
        uint256 _satId
    )
        private
    {
        unchecked {
            uint256 page = _satId / 256;
            uint256 shift = _satId % 256;
            satLabBitfields[page] &= ~(1 << shift);
        }
    }

    /**
     * @dev Initializes prime token ID offsets
     */
    function _initializePrimeIdOffsets()
        private
    {
        unchecked {
            primeIdOffset[FRANKENSTEIN] = ALPHA;
            primeIdOffset[WEREWOLF] = ALPHA + 166;
            primeIdOffset[VAMPIRE] = ALPHA + 332;
            primeIdOffset[ZOMBIE] = ALPHA + 498;
            primeIdOffset[INVALID] = ALPHA + 665;
        }
    }

    /**
     * @dev Initializes bitfields of Satoshibles available for discounted mints
     */
    function _initializeSatDiscountAvailability()
        private
    {
        unchecked {
            for (uint256 i = 0; i < 20; i++) {
                satDiscountBitfields[i] = type(uint256).max;
            }
        }
    }

    /**
     * @dev Initializes bitfields of Satoshibles available to mint primes
     */
    function _initializeSatLabAvailability()
        private
    {
        unchecked {
            for (uint256 i = 0; i < 20; i++) {
                satLabBitfields[i] = type(uint256).max;
            }
        }
    }

    /**
     * @dev Helper function used for token ID range checks when minting
     * @param _currentValue Current token ID counter value
     * @param _incrementValue Number of tokens to increment by
     * @param _maximumValue Maximum token ID value allowed
     * @return isBelowMaximum True if _maximumValue is not exceeded
     */
    function belowMaximum(
        uint256 _currentValue,
        uint256 _incrementValue,
        uint256 _maximumValue
    )
        private
        pure
        returns (bool isBelowMaximum)
    {
        unchecked {
            isBelowMaximum = _currentValue + _incrementValue <= _maximumValue;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
	/// @notice Called with the sale price to determine how much royalty
	//          is owed and to whom.
	/// @param _tokenId - the NFT asset queried for royalty information
	/// @param _value - the sale price of the NFT asset specified by _tokenId
	/// @return _receiver - address of who should be sent the royalty payment
	/// @return _royaltyAmount - the royalty payment amount for value sale price
	function royaltyInfo(uint256 _tokenId, uint256 _value)
		external
		view
		returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
	RoyaltyInfo private _royalties;

	/// @dev Sets token royalties
	/// @param _recipient recipient of the royalties
	/// @param _value percentage (using 2 decimals - 10000 = 100, 0 = 0)
	function _setRoyalties(
		address _recipient,
		uint256 _value
	)
		internal
	{
		require(_value <= 10000, "ERC2981Royalties: Too high");
		_royalties = RoyaltyInfo(_recipient, uint24(_value));
	}

	/// @inheritdoc	IERC2981Royalties
	function royaltyInfo(
		uint256,
		uint256 _value
	)
		external
		view
		override
		returns (address receiver, uint256 royaltyAmount)
	{
		RoyaltyInfo memory royalties = _royalties;
		receiver = royalties.recipient;
		royaltyAmount = (_value * royalties.amount) / 10000;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981Royalties.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
	struct RoyaltyInfo {
		address recipient;
		uint24 amount;
	}

	/// @inheritdoc	ERC165
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override
		returns (bool)
	{
		return
			interfaceId == type(IERC2981Royalties).interfaceId ||
			super.supportsInterface(interfaceId);
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