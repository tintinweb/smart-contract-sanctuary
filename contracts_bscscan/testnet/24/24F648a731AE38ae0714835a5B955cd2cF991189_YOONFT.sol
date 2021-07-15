// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YOONFT is ERC1155, Ownable, ERC1155Burnable {
    using SafeERC20 for IERC20;

    // TODO: replace me
    string uri_ = "http://localhost:3000/";
    uint256 randNonce = 0;
    enum Quality {
        N,
        R,
        SR,
        SSR
    }
    struct Fighter {
        uint256 id; // pet: 1-24 building: 25-41
        uint256 strength; // hashrate
        uint256 level; // default 1
        uint256 rarity; // quality 0-3
        uint256 exp; // increase experience by burning lower nft
        uint256 hashPrice;
        uint256 series; // 3: amount 1
    }

    mapping(uint256 => Fighter) public fighters;

    uint256[] initExp = [100, 500, 50000, 500000];
    uint256[] extraExp = [0, 50, 110, 240];
    uint256[] initStrength = [1, 100, 500, 800];
    uint256[] initStrengthRandomMax = [2, 100, 200, 400];
    uint256[] stengthUpgradeCoefficient = [10, 12, 13, 14];
    // pet probability
    uint32[25] ids = [
        49551,
        49552,
        49553,
        49554,
        49563,
        49572,
        49581,
        49590,
        49599,
        50499,
        51399,
        52299,
        53199,
        54099,
        54999,
        59499,
        63999,
        68499,
        72999,
        77499,
        81999,
        86499,
        90999,
        95499,
        99999
    ];
    // building probability
    uint32[17] buildingChance = [
        47915,
        47916,
        47917,
        47918,
        47919,
        47939,
        47959,
        47979,
        47999,
        49999,
        51999,
        53999,
        55999,
        66999,
        77999,
        88999,
        99999
    ];

    uint32[41] private MAX_SUPPLY = [
        0,
        10,
        10,
        10,
        100,
        100,
        100,
        100,
        100,
        10000,
        10000,
        10000,
        10000,
        10000,
        10000,
        1000000000,
        1000000000,
        1000000000,
        1000000000,
        1000000000,
        1000000000,
        1000000000,
        1000000000,
        1000000000,
        1000000000,
        10,
        10,
        10,
        10,
        100,
        100,
        100,
        100,
        1000,
        1000,
        1000,
        1000,
        1000000000,
        1000000000,
        1000000000,
        1000000000
    ];

    uint256 public dayIndex = 0;
    uint256 public boxPerDayLimit = 10;

    uint256 private nonce = 0;
    uint256 cards = 10000; // pet 24 building 17

    uint256[] buildingPrice = [1000, 3000, 30000, 100000]; // Quality low to hight
    uint256 public boxPrice = 100 * 10**18;

    mapping(uint256 => uint256) public boxOpenCountPerDay; // Maximum box open per day.
    address key;
    address yoo;

    constructor(address _key, address _yoo) public ERC1155(uri_) {
        for (uint8 i = 0; i < MAX_SUPPLY.length; i++) {
            totalSupply[i] = MAX_SUPPLY[i];
        }

        key = _key;
        yoo = _yoo;
        fighters[0] = Fighter(0, 0, 0, 0, 0, 0, 0);
        fighters[1] = Fighter(1, 0, 1, 3, initExp[3], 0, 3);
        fighters[2] = Fighter(2, 0, 1, 3, initExp[3], 0, 3);
        fighters[3] = Fighter(3, 0, 1, 3, initExp[3], 0, 3);
        fighters[4] = Fighter(4, 0, 1, 2, initExp[3], 0, 3);
        fighters[5] = Fighter(5, 0, 1, 2, initExp[2], 0, 3);
        fighters[6] = Fighter(6, 0, 1, 2, initExp[2], 0, 3);
        fighters[7] = Fighter(7, 0, 1, 2, initExp[2], 0, 3);
        fighters[8] = Fighter(8, 0, 1, 2, initExp[2], 0, 3);
        fighters[9] = Fighter(9, 0, 1, 1, initExp[1], 0, 3);
        fighters[10] = Fighter(10, 0, 1, 1, initExp[1], 0, 3);
        fighters[11] = Fighter(11, 0, 1, 1, initExp[1], 0, 3);
        fighters[12] = Fighter(12, 0, 1, 1, initExp[1], 0, 3);
        fighters[13] = Fighter(13, 0, 1, 1, initExp[1], 0, 3);
        fighters[14] = Fighter(14, 0, 1, 1, initExp[1], 0, 3);
        fighters[15] = Fighter(15, 1, 1, 0, initExp[0], 0, 1);
        fighters[16] = Fighter(16, 1, 1, 0, initExp[0], 0, 1);
        fighters[17] = Fighter(17, 1, 1, 0, initExp[0], 0, 1);
        fighters[18] = Fighter(18, 1, 1, 0, initExp[0], 0, 1);
        fighters[19] = Fighter(19, 1, 1, 0, initExp[0], 0, 1);
        fighters[20] = Fighter(20, 1, 1, 0, initExp[0], 0, 1);
        fighters[21] = Fighter(21, 1, 1, 0, initExp[0], 0, 1);
        fighters[22] = Fighter(22, 1, 1, 0, initExp[0], 0, 1);
        fighters[23] = Fighter(23, 1, 1, 0, initExp[0], 0, 1);
        fighters[24] = Fighter(24, 1, 1, 0, initExp[0], 0, 1);
        // building
        fighters[25] = Fighter(25, 3000, 1, 3, 0, 0, 2);
        fighters[26] = Fighter(26, 3000, 1, 3, 0, 0, 2);
        fighters[27] = Fighter(27, 3000, 1, 3, 0, 0, 2);
        fighters[28] = Fighter(28, 3000, 1, 3, 0, 0, 2);
        fighters[29] = Fighter(29, 1000, 1, 2, 0, 0, 2);
        fighters[30] = Fighter(30, 1000, 1, 2, 0, 0, 2);
        fighters[31] = Fighter(31, 1000, 1, 2, 0, 0, 2);
        fighters[32] = Fighter(32, 1000, 1, 2, 0, 0, 2);
        fighters[33] = Fighter(33, 300, 1, 1, 0, 0, 2);
        fighters[34] = Fighter(34, 300, 1, 1, 0, 0, 2);
        fighters[35] = Fighter(35, 300, 1, 1, 0, 0, 2);
        fighters[36] = Fighter(36, 300, 1, 1, 0, 0, 2);
        fighters[37] = Fighter(37, 100, 1, 0, 0, 0, 2);
        fighters[38] = Fighter(38, 100, 1, 0, 0, 0, 2);
        fighters[39] = Fighter(39, 100, 1, 0, 0, 0, 2);
        fighters[40] = Fighter(40, 100, 1, 0, 0, 0, 2);
    }

    uint256 public boxes;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public circulatingSupply;

    event BoxAdded(uint256 id, uint256 maxSupply);
    event TurnSlot(
        address indexed user,
        uint256 id,
        uint256 cid,
        uint256 strength
    );
    event OpenBox(
        address indexed user,
        uint256 id,
        uint256 cid,
        uint256 strength
    );
    event LevelUp(address indexed user, uint256 targetId, uint256 exp);
    event BuyBuilding(address indexed user, uint256 id, uint256 amount);
    event Withdraw(address indexed user, address tokenAddr, uint256 amount);

    function changeFighter(
        uint256 tokenId,
        uint256 strength,
        uint256 level,
        uint256 rarity,
        uint256 exp,
        uint256 hashPrice,
        uint256 series
    ) public onlyOwner returns (bool) {
        fighters[tokenId] = Fighter(
            tokenId,
            strength,
            level,
            rarity,
            exp,
            hashPrice,
            series
        );
        return true;
    }

    function nextId() public view returns (uint256) {
        return cards.add(1);
    }

    function setBoxPrice(uint256 price) public onlyOwner {
        boxPrice = price;
    }

    function addBox(
        uint256 id,
        uint256 maxSupply,
        uint256 strength,
        uint256 level,
        uint256 rarity,
        uint256 exp,
        uint256 hashPrice,
        uint256 series
    ) public onlyOwner returns (uint256) {
        require(maxSupply > 0, "Maximum supply can not be 0");

        return
            _addBox(
                id,
                maxSupply,
                strength,
                level,
                rarity,
                exp,
                hashPrice,
                series
            );
    }

    function _addBox(
        uint256 id,
        uint256 maxSupply,
        uint256 strength,
        uint256 level,
        uint256 rarity,
        uint256 exp,
        uint256 hashPrice,
        uint256 series
    ) internal returns (uint256) {
        boxes = boxes.add(1);
        totalSupply[id] = maxSupply;
        emit BoxAdded(id, maxSupply);
        fighters[id] = Fighter(
            id,
            strength,
            level,
            rarity,
            exp,
            hashPrice,
            series
        );
        return boxes;
    }

    // 1-10 KEY turn the slot 1-10
    function turnSlot(uint256 _amount) public {
        uint256 onekey = 1000000000000000000;
        require(_amount.mod(onekey) == 0, "Amount invalid");
        uint256 count = _amount.div(onekey);
        require(count >= 1 && count <= 10, "Amount invalid");

        IERC20(key).safeTransferFrom(msg.sender, address(this), _amount);
        for (uint8 i = 0; i < count; i++) {
            _turnSlot();
        }
    }

    function _turnSlot() internal {
        uint256 rand = importSeedFromThird(nonce, 100000);
        uint256 cid = getBuilding(rand);
        nonce++;
        if (cid == 0) {
            emit TurnSlot(msg.sender, 0, 0, 0);
            return;
        }
        Fighter memory fighter = fighters[cid];
        _mint(msg.sender, cid, 1, "");
        emit TurnSlot(msg.sender, cid, cid, fighter.strength);
    }

    // some YOO open one box
    function openBox(uint256 _amount) public {
        require(_amount == boxPrice, "Amount invalid");
        updateDay();
        require(
            boxOpenCountPerDay[dayIndex].add(1) <= boxPerDayLimit,
            "It has exceeded the maximum per day！"
        );

        IERC20(yoo).safeTransferFrom(msg.sender, address(this), boxPrice);
        _openBox();
        boxOpenCountPerDay[dayIndex] = boxOpenCountPerDay[dayIndex].add(1);
    }

    function _openBox() internal {
        uint256 rand = importSeedFromThird(nonce, 100000);
        uint256 cid = getPet(rand);
        nonce++;
        if (cid == 0) {
            rand = importSeedFromThird(nonce, 10);
            cid = getNPet(rand);
        }
        if (cid == 0) {
            emit OpenBox(msg.sender, 0, 0, 0);
            return;
        }
        Fighter memory fighter = fighters[cid];
        if (fighter.series == 3) {
            cards = nextId();
            _mint(msg.sender, cards, 1, "");
            fighters[cards] = fighter;
            uint256 _strength = randomStrength(cid);
            fighters[cards].strength = _strength;
            emit OpenBox(msg.sender, cards, cid, _strength);
        } else {
            _mint(msg.sender, cid, 1, "");
            emit OpenBox(msg.sender, cid, cid, fighter.strength);
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        require(
            circulatingSupply[id].add(amount) <= totalSupply[id],
            "Total supply reached."
        );
        circulatingSupply[id] = circulatingSupply[id].add(amount);
        _mint(to, id, amount, "");
    }

    /**
     * @notice Generates a random number between 0 - (count - 1)
     * @param seed The seed to generate different number if block.timestamp is same
     * for two or more numbers.
     * @param count The number count
     */
    function importSeedFromThird(uint256 seed, uint256 count)
        internal
        view
        returns (uint256)
    {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, seed))
        ) % count;
        return randomNumber;
    }

    function randomStrength(uint256 cid) internal view returns (uint256) {
        Fighter memory fighter = fighters[cid];
        if (fighter.rarity == 0) {
            return initStrength[fighter.rarity];
        }
        return
            initStrength[fighter.rarity] +
            _randomStrength(initStrengthRandomMax[fighter.rarity].add(1));
    }

    function _randomStrength(uint256 max) internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, nonce))
        ) % max;
        return randomNumber;
    }

    /**
     * @notice get a pet
     * @param rand random
     */
    function getPet(uint256 rand) internal returns (uint32) {
        uint32 id = 0;
        for (uint8 i = 0; i < ids.length; i++) {
            if (rand <= ids[i]) {
                id = i;
                break;
            }
        }
        if (id > 0) {
            if (circulatingSupply[id] < totalSupply[id]) {
                circulatingSupply[id] = circulatingSupply[id].add(1);
            } else {
                id = 0;
            }
        }
        return id;
    }

    /**
     * @notice get a n pet
     * @param rand random
     */
    function getNPet(uint256 rand) internal returns (uint256) {
        uint256 id = rand + 15;
        if (circulatingSupply[id] < totalSupply[id]) {
            circulatingSupply[id] = circulatingSupply[id].add(1);
        } else {
            id = 0;
        }
        return id;
    }

    /**
     * @notice get a building
     * @param rand random
     */
    function getBuilding(uint256 rand) internal returns (uint32) {
        uint32 id = 0;
        for (uint8 i = 0; i < buildingChance.length; i++) {
            if (rand <= buildingChance[i]) {
                id = i;
                break;
            }
        }
        if (id > 0) {
            id = id + 25;
            if (circulatingSupply[id] < totalSupply[id]) {
                circulatingSupply[id] = circulatingSupply[id].add(1);
            } else {
                id = 0;
            }
        }
        return id;
    }

    function setURI(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    function getFighter(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Fighter memory fighter = fighters[tokenId];
        uint256 _level = level(tokenId);
        uint256 _strength = strength(tokenId);
        return (
            fighter.id,
            _strength,
            _level,
            fighter.rarity,
            fighter.exp,
            fighter.hashPrice,
            fighter.series
        );
    }

    function levelUp(
        uint256[] memory fromIds,
        uint256[] memory amounts,
        uint256 targetId
    ) public {
        require(
            balanceOf(msg.sender, targetId) > 0,
            "You don't own this token."
        );
        Fighter storage targetFighter = fighters[targetId];

        require(targetFighter.series == 3, "This token can't upgrade");

        burnBatch(_msgSender(), fromIds, amounts);
        uint256 exp;
        for (uint256 i = 0; i < fromIds.length; i++) {
            Fighter memory fromFighter = fighters[fromIds[i]];
            exp = exp.add(fromFighter.exp.mul(amounts[i]));
        }

        targetFighter.exp = targetFighter.exp.add(exp);

        emit LevelUp(msg.sender, targetId, exp);
    }

    function buyBuilding(uint256 id, uint256 amount) public {
        require(false, "forbidden");
        require(id > 24, "The id 25-40");
        require(id < 41, "The id 25-40");
        require(amount > 0, "Amount gt 0");

        require(
            circulatingSupply[id].add(amount) <= totalSupply[id],
            "Total supply reached."
        );
        circulatingSupply[id] = circulatingSupply[id].add(amount);

        Fighter memory fighter = fighters[id];
        uint256 _amount = buildingPrice[fighter.rarity] * 1e18 * amount;
        IERC20(yoo).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, id, amount, "");
        emit BuyBuilding(msg.sender, id, amount);
    }

    function withdraw(address tokenAddr, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddr);
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit Withdraw(msg.sender, tokenAddr, amount);
    }

    /**
     * pet level
     * @param id  pet id
     */
    function level(uint256 id) public view returns (uint256) {
        Fighter memory fighter = fighters[id];
        uint256 exp = fighter.exp;
        uint256 _level = 1;
        uint256 e = initExp[fighter.rarity];
        while (true) {
            e = e + 30 + 30 * _level**2 + 10 + extraExp[fighter.rarity];
            if (exp < e) {
                break;
            }
            _level++;
            if (_level > 99) {
                _level = 99;
                break;
            }
        }
        return _level;
    }

    /**
     * pet strength
     * @param id  pet id
     */
    function strength(uint256 id) public view returns (uint256) {
        Fighter memory fighter = fighters[id];
        uint256 _level = level(id);
        if (_level == 1) {
            return fighter.strength;
        }
        if (fighter.series != 3) {
            return fighter.strength;
        }
        uint256 stre = fighter.strength;
        uint256 le = _level.sub(1);
        if (fighter.rarity == 1) {
            stre = fighter.strength.mul(le).mul(12).div(10);
        } else if (fighter.rarity == 2) {
            stre = fighter.strength.mul(le).mul(13).div(10);
        } else if (fighter.rarity == 3) {
            stre = fighter.strength.mul(le).mul(14).div(10);
        }
        return stre;
    }

    function getTotalSupply(uint256[] memory ids_)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory t = new uint256[](ids_.length);
        for (uint256 i = 0; i < ids_.length; i++) {
            t[i] = totalSupply[ids_[i]];
        }
        return t;
    }

    function getCirculatingSupply(uint256[] memory ids_)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory t = new uint256[](ids_.length);
        for (uint256 i = 0; i < ids_.length; i++) {
            t[i] = circulatingSupply[ids_[i]];
        }
        return t;
    }

    function getBoxOpenCountPerDay(uint256 _dayIndex)
        public
        view
        returns (uint256)
    {
        return boxOpenCountPerDay[_dayIndex];
    }

    function updateDay() internal {
        dayIndex = now / 86400;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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