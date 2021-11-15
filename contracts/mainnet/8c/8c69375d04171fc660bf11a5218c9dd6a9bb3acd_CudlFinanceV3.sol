//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Interface for our erc20 token
interface IToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract CudlFinanceV3 is
    Initializable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable
{
    address public mooncats;
    address public PONDERWARE;
    address public MUSE_DAO;
    address public MUSE_DEVS;

    uint256 public gas; // if gas higher then this you can't kill
    uint256 public lastGas; //here we record last gas paid, to keep track of chain gas. If gas is high, no pets can die.

    IToken public token;

    struct Pet {
        address nft;
        uint256 id;
    }

    mapping(address => bool) public supportedNfts;
    mapping(uint256 => Pet) public petDetails;

    // mining tokens
    mapping(uint256 => uint256) public lastTimeMined;

    // Pet properties
    mapping(uint256 => uint256) public timeUntilStarving;
    mapping(uint256 => uint256) public petScore;
    mapping(uint256 => bool) public petDead;
    mapping(uint256 => uint256) public timePetBorn;

    // items/benefits for the PET could be anything in the future.
    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public itemPoints;
    mapping(uint256 => string) public itemName;
    mapping(uint256 => uint256) public itemTimeExtension;

    mapping(uint256 => mapping(address => address)) public careTaker;

    mapping(address => mapping(uint256 => bool)) public isNftInTheGame; //keeps track if nft already played
    mapping(address => mapping(uint256 => uint256)) public nftToId; //keeps track if nft already played

    uint256 public feesEarned;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    CountersUpgradeable.Counter private _itemIds;

    event Mined(uint256 nftId, uint256 reward, address recipient);
    event BuyAccessory(
        uint256 nftId,
        uint256 itemId,
        uint256 amount,
        uint256 itemTimeExtension,
        address buyer
    );
    event Fatalize(uint256 opponentId, uint256 nftId, address killer);
    event NewPlayer(
        address nftAddress,
        uint256 nftId,
        uint256 playerId,
        address owner
    );
    event Bonk(
        uint256 attacker,
        uint256 victim,
        uint256 winner,
        uint256 reward
    );

    // Rewards algorithm

    uint256 public la;
    uint256 public lb;
    uint256 public ra;
    uint256 public rb;

    address public lastBonker;

    // NEW STORE v2

    mapping(uint256 => uint256) public spent;
    mapping(address => uint256) public balance;
    mapping(address => bool) public isOperator;

    constructor() {}

    modifier isAllowed(uint256 _id) {
        Pet memory _pet = petDetails[_id];
        address ownerOf = IERC721Upgradeable(_pet.nft).ownerOf(_pet.id);
        require(
            ownerOf == msg.sender || careTaker[_id][ownerOf] == msg.sender,
            "!owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            isOperator[msg.sender],
            "Roles: caller does not have the OPERATOR role"
        );
        _;
    }

    // GAME ACTIONS

    function depositCudl(uint256 amount) external {
        balance[msg.sender] += amount;
        // burn real cul
        token.burnFrom(msg.sender, amount);
    }

    //this withdraws all your eanrings
    function claimRewards(uint256[] memory petIds) public onlyOwner {
        lastGas = tx.gasprice;
        uint256 petId;
        uint256 amount;
        for (uint256 i = 0; i < petIds.length; i++) {
            petId = petIds[i];

            require(isPetOwner(petId, msg.sender), "!owner");
            // This enforces helping kills/broadcast txs as you won't mine with any pet unless you kill your deads
            require(isPetSafe(petId), "Your pet is starving, you can't mine");

            if (lastTimeMined[petId] == 0) {
                lastTimeMined[petId] = block.timestamp;
            }
            uint256 earning = getEarnings(petId);
            amount += earning;

            // TODO check
            spent[petId] = 0;

            lastTimeMined[petId] = block.timestamp;
            emit Mined(petId, earning, msg.sender);
        }

        amount += balance[msg.sender];
        balance[msg.sender] = 0;

        if (amount > 0) token.mint(msg.sender, amount);
    }

    function buyAccesory(uint256 nftId, uint256 itemId)
        public
        onlyOwner
        isAllowed(nftId)
    {
        require(!petDead[nftId], "ded pet");

        uint256 amount = itemPrice[itemId];
        require(amount > 0, "item does not exist");

        // recalculate time until starving
        timeUntilStarving[nftId] = block.timestamp + itemTimeExtension[itemId];
        petScore[nftId] += itemPoints[itemId];

        if (getEarnings(nftId) + balance[msg.sender] >= amount) {
            spent[nftId] += amount;
        } else {
            token.burnFrom(msg.sender, amount);
        }

        feesEarned += amount / 10;

        emit BuyAccessory(
            nftId,
            itemId,
            amount,
            itemTimeExtension[itemId],
            msg.sender
        );
    }

    function feedMultiple(uint256[] calldata ids, uint256[] calldata itemIds)
        external
    {
        for (uint256 i = 0; i < ids.length; i++) {
            buyAccesory(ids[i], itemIds[i]);
        }
    }

    //TOOD DECIDE FATALITY
    function fatality(uint256 _deadId, uint256 _tokenId) external {
        require(
            !isPetSafe(_deadId) &&
                tx.gasprice <= gas && //inspired by NFT GAS by 0Xmons
                petDead[_deadId] == false,
            "The PET has to be starved or gas below ${gas} to claim his points"
        );

        petScore[_tokenId] =
            petScore[_tokenId] +
            (((petScore[_deadId] * (20)) / (100)));

        petScore[_deadId] = 0;

        petDead[_deadId] = true;
        emit Fatalize(_deadId, _tokenId, msg.sender);
    }

    function getCareTaker(uint256 _tokenId, address _owner)
        public
        view
        returns (address)
    {
        return (careTaker[_tokenId][_owner]);
    }

    function setCareTaker(
        uint256 _tokenId,
        address _careTaker,
        bool clearCareTaker
    ) external isAllowed(_tokenId) {
        if (clearCareTaker) {
            delete careTaker[_tokenId][msg.sender];
        } else {
            careTaker[_tokenId][msg.sender] = _careTaker;
        }
    }

    // requires approval
    function giveLife(address nft, uint256 _id) external {
        require(IERC721Upgradeable(nft).ownerOf(_id) == msg.sender, "!OWNER");
        require(
            !isNftInTheGame[nft][_id],
            "this nft was already registered can't again"
        );
        require(supportedNfts[nft], "!forbidden");

        // burn 6 cudl to join
        token.burnFrom(msg.sender, 6 * 1 ether);

        uint256 newId = _tokenIds.current();
        // set the pet struct
        petDetails[newId] = Pet(nft, _id);

        nftToId[nft][_id] = newId;

        isNftInTheGame[nft][_id] = true;

        timeUntilStarving[newId] = block.timestamp + 3 days; //start with 3 days of life.
        timePetBorn[newId] = block.timestamp;

        emit NewPlayer(nft, _id, newId, msg.sender);

        _tokenIds.increment();
    }

    // BAZAAR

    function burnScore(uint256 petId, uint256 amount) external onlyOperator {
        require(!petDead[petId]);

        petScore[petId] -= amount;
    }

    function addScore(uint256 petId, uint256 amount) external onlyOperator {
        require(!petDead[petId]);
        petScore[petId] += amount;
    }

    function spend(uint256 petId, uint256 amount) external onlyOperator {
        spent[petId] -= amount;
    }

    function gibCudl(uint256 petId, uint256 amount) external onlyOperator {
        spent[petId] += amount;
    }

    function addTOD(uint256 petId, uint256 duration) external onlyOperator {
        require(!petDead[petId]);
        timeUntilStarving[petId] = block.timestamp + duration;
    }

    function isPetOwner(uint256 petId, address user)
        public
        view
        returns (bool)
    {
        Pet memory _pet = petDetails[petId];
        address ownerOf = IERC721Upgradeable(_pet.nft).ownerOf(_pet.id);
        return (ownerOf == user || careTaker[petId][ownerOf] == user);
    }

    // GETTERS

    function getEarnings(uint256 petId) public view returns (uint256) {
        uint256 amount = (((block.timestamp - lastTimeMined[petId]) / 1 days) *
            getRewards(petId));

        // if (amount <= spent[petId]) return 0;

        return amount - spent[petId];
    }

    function getPendingBalance(uint256[] memory petIds, address user)
        public
        view
        returns (uint256)
    {
        uint256 total;
        for (uint256 i = 0; i < petIds.length; i++) {
            total += getEarnings(petIds[i]);
        }

        return total + balance[user];
    }

    // check that pet didn't starve
    function isPetSafe(uint256 _nftId) public view returns (bool) {
        uint256 _timeUntilStarving = timeUntilStarving[_nftId];
        if (
            (_timeUntilStarving != 0 &&
                _timeUntilStarving >= block.timestamp) || lastGas >= gas
        ) {
            return true;
        } else {
            return false;
        }
    }

    // GETTERS

    function getPetInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _pet,
            bool _isStarving,
            uint256 _score,
            uint256 _level,
            uint256 _expectedReward,
            uint256 _timeUntilStarving,
            uint256 _lastTimeMined,
            uint256 _timepetBorn,
            address _owner,
            address _token,
            uint256 _tokenId,
            bool _isAlive
        )
    {
        Pet memory thisPet = petDetails[_nftId];

        _pet = _nftId;
        _isStarving = !this.isPetSafe(_nftId);
        _score = petScore[_nftId];
        _level = level(_nftId);
        _expectedReward = getRewards(_nftId);
        _timeUntilStarving = timeUntilStarving[_nftId];
        _lastTimeMined = lastTimeMined[_nftId];
        _timepetBorn = timePetBorn[_nftId];
        _owner = IERC721Upgradeable(thisPet.nft).ownerOf(thisPet.id);
        _token = petDetails[_nftId].nft;
        _tokenId = petDetails[_nftId].id;
        _isAlive = !petDead[_nftId];
    }

    // get the level the pet is on to calculate the token reward
    function getRewards(uint256 tokenId) public view returns (uint256) {
        // This is the formula to get token rewards R(level)=(level)*6/7+6
        uint256 _level = level(tokenId);
        if (_level == 1) {
            return 6 ether;
        }
        _level = (_level * 1 ether * ra) / rb;
        return (_level + 5 ether);
    }

    // get the level the pet is on to calculate points
    function level(uint256 tokenId) public view returns (uint256) {
        // This is the formula L(x) = 2 * sqrt(x * 2)
        uint256 _score = petScore[tokenId] / 100;
        if (_score == 0) {
            return 1;
        }
        uint256 _level = sqrtu(_score * la);
        return (_level * lb);
    }

    // ADMIN

    function editCurves(
        uint256 _la,
        uint256 _lb,
        uint256 _ra,
        uint256 _rb
    ) external onlyOwner {
        la = _la;
        lb = _lb;
        ra = _ra;
        rb = _rb;
    }

    // edit specific item in case token goes up in value and the price for items gets to expensive for normal users.
    function editItem(
        uint256 _id,
        uint256 _price,
        uint256 _points,
        string calldata _name,
        uint256 _timeExtension
    ) external onlyOwner {
        itemPrice[_id] = _price;
        itemPoints[_id] = _points;
        itemName[_id] = _name;
        itemTimeExtension[_id] = _timeExtension;
    }

    // to support more projects
    function setSupported(address _nft, bool isSupported) public onlyOwner {
        supportedNfts[_nft] = isSupported;
    }

    function setGas(uint256 _gas) public onlyOwner {
        gas = _gas;
    }

    function addOperator(address _address, bool _isAllowed) public onlyOwner {
        isOperator[_address] = _isAllowed;
    }

    // add items/accessories
    function createItem(
        string calldata name,
        uint256 price,
        uint256 points,
        uint256 timeExtension
    ) external onlyOwner {
        _itemIds.increment();
        uint256 newItemId = _itemIds.current();
        itemName[newItemId] = name;
        itemPrice[newItemId] = price;
        itemPoints[newItemId] = points;
        itemTimeExtension[newItemId] = timeExtension;
    }

    function changeEarners(address _newAddress) public {
        require(
            msg.sender == MUSE_DEVS || msg.sender == PONDERWARE,
            "!forbidden"
        );
        if (msg.sender == MUSE_DEVS) {
            MUSE_DEVS = _newAddress;
        } else if (msg.sender == PONDERWARE) {
            PONDERWARE = _newAddress;
        }
    }

    // anyone can call this
    function claimEarnings() public {
        token.mint(address(this), feesEarned);
        feesEarned = 0;

        uint256 bal = token.balanceOf(address(this));
        token.transfer(PONDERWARE, bal / 3);
        token.transfer(MUSE_DAO, bal / 3);
        token.transfer(MUSE_DEVS, bal / 3);
    }

    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        unchecked {
            for (uint256 i = 0; i < 5; i++) {
                n += uint256(
                    keccak256(
                        abi.encodePacked(blockhash(block.number - i - 1), seed)
                    )
                );
            }
        }
        return (n) % max;
    }

    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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
library CountersUpgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

