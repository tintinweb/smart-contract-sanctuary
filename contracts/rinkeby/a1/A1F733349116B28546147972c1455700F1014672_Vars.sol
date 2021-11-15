// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./structs/Upgrade.sol";
import "./structs/AppStorage.sol";


contract Vars is Initializable {
    AppStorage internal s;    
    int16[22] public profit = [int16(1),int16(1),int16(2),int16(3),int16(4),int16(5),int16(8),int16(12),int16(16),int16(25),int16(40),int16(65),int16(100),int16(200),int16(400),int16(600),int16(1000),int16(100),int16(1250),int16(1750),int16(-10),int16(6)];
    uint64[22] public price = [100000000000000,10,50,250,1250,5000,20000,80000,200000,1000000,5000000,25000000,125000000,525000000,1525000000,5555555555,15678901234,65555555555,365555555555,1365555555555,1,512];
    uint64[10] public levelPrice = [0,2000000,4500000,15000000,400000000,1200000000,6000000000,24000000000,124000000000,11924000000000];
    Upgrade[255] public upgs; 
    uint16 public constant bavailibility = 1000;
    uint16 public constant governanceAchievementReward = 20;
    uint16 public constant governanceBlockHeight = 1600;
    uint16 public constant bexponent = 4;
        
    function initialize() public initializer {
       
        Upgrade memory upd;

        upd.typeId = 4;
        upd.price = 2000;
        upd.value = 4000;
        
        uint8 i=0;
    
        upd.typeId = 1;
        upd.price = 1;
        upd.level = 0;
        upd.value = 15000;
        upgs[i] = upd;

        upd.level = 0;
        upd.price = 100000;
        upd.value = 1000000;        
        upgs[++i] = upd;

        //2Bog
        upd.typeId =1;
        upd.building = 2;
        upd.price = 500000;
        upd.value = -10000;
        upd.level = 2;
        upd.achDep = 0;
        upgs[++i] = upd;
        
        //3Rabobank
        upd.typeId = 0;
        upd.building = 2;
        upd.price = 500000;
        upd.value = -10;
        upd.achDep = 54;
        upgs[++i] = upd;

        //4ElSalvador
        upd.typeId = 3;
        upd.building = 5;
        upd.price = 500000;
        upd.value = 9;
        upd.achDep = 4;
        upd.upgDep = 6;
        upgs[++i] = upd;

        //5McAffee
        upd.typeId = 3;
        upd.building = 5;
        upd.price = 5000;
        upd.value = 5;
        upd.achDep = 1;
        upd.upgDep = 6;
        upd.level = 0;
        upgs[++i] = upd;
        
        //6Lambo
        upd.typeId = 1;
        upd.building = 0;
        upd.price = 1;
        upd.value = 1000;
        upd.achDep = 0;
        upd.upgDep = 0;
        upgs[++i] = upd;

        //7Moon
        upd.typeId = 1;
        upd.building = 1;
        upd.price = 1111000;
        upd.value = 1112222;
        upd.level = 1;
        upgs[++i] = upd;
        
        //8Bingo
        upd.typeId = 3;
        upd.building = 1;
        upd.price = 11000;
        upd.value = 10;
        upd.level = 0;
        upgs[++i] = upd;
        
        //9Laser Carlos
        upd.typeId = 0;
        upd.building = 7;
        upd.price = 600000;
        upd.value = 27;
        upd.level = 1;
        upgs[++i] = upd;
        
        //10Safu
        upd.typeId = 1;
        upd.building=0;
        upd.price = 2000;
        upd.value = 10000;
        upd.level = 0;
        upgs[++i] = upd;
        
        //11 House 1 - 3;
        upd.typeId = 0;
        upd.building = 0;
        upd.price = 100;
        upd.value = 3;
        upd.achDep = 1;
        upd.level = 0;
        upgs[++i] = upd;
        
        //12
        upd.price = 1000;
        upd.value = 5;
        upd.upgDep = i;
        upd.level = 2;
        upgs[++i] = upd;
        
        //13
        upd.price = 12000;
        upd.value = 9;
        upd.level = 1;
        upd.level = 4;
        upd.upgDep = i;
        upgs[++i] = upd;
        
        //14 GM 1 - 3
        upd.building = 1;
        upd.price = 300;
        upd.value = 3;
        upd.level = 0;
        upd.achDep = 44;
        upd.upgDep = 0;
        upgs[++i] = upd;
        
        //15
        upd.price = 3000;
        upd.value = 5;
        upd.level = 0;
        upd.upgDep = i;
        upd.achDep = 45;
        upgs[++i] = upd;
        
        //16
        upd.price = 32000;
        upd.value = 11;
        upd.upgDep = i;
        upd.level = 1;
        upd.achDep = 46;
        upgs[++i] = upd;
        
        
        //17 Wallet
        upd.building = 2;
        upd.upgDep = 0;
        upd.price = 80000;
        upd.value = 5;
        upd.level = 0;
        upd.achDep = 48;
        upgs[++i] = upd;
        
        // Wlalet
        upd.upgDep = i;
        upd.price = 500000;
        upd.value = 7;
        upd.level = 1;
        upd.achDep = 49;
        upgs[++i] = upd;

        upd.upgDep = i;
        upd.price = 1250000;
        upd.value = 11;
        upd.level = 2;
        upd.achDep = 50;
        upgs[++i] = upd;
        
        //20 Yellow paper
        upd.building = 3;
        upd.upgDep = 0;
        upd.price = 250000;
        upd.value = 5;
        upd.achDep = 52;
        upd.level = 1;
        upgs[++i] = upd;
        
        //21 Brown paper
        upd.upgDep = i;
        upd.price = 1250000;
        upd.value = 9;
        upd.level = 2;
        upgs[++i] = upd;
        upd.achDep = 53;
        
        //Hidden, for now
        upd.upgDep = i;
        upd.price = 2500000;
        upd.value = 13;
        upd.level = 3;
        upd.achDep = 54;
        upgs[++i] = upd;

        //23 Mortage 
        upd.building = 4;
        upd.upgDep = 0;
        upd.price = 150000;
        upd.level = 1;
        upd.achDep = 0;
        upd.value = 7;
        upgs[++i] = upd;

        //24 Large loan
        upd.upgDep = i;
        upd.price = 1000000;
        upd.value = 11;
        upd.level = 2;
        upgs[++i] = upd;

        //25 vC
        upd.upgDep = i;
        upd.price = 2000000;
        upd.value = 15;
        upd.level = 3;
        upgs[++i] = upd;

        //26 Etf 
        upd.building = 5;
        upd.upgDep = 0;
        upd.price = 500000;
        upd.value = 9;
        upd.level = 2;
        upgs[++i] = upd;

        //27 Techstonk 
        upd.upgDep = i;
        upd.price = 2000000;
        upd.value = 15;
        upd.level = 3;
        upgs[++i] = upd;

        //27 Gamestonk 
        upd.upgDep = i;
        upd.price = 5000000;
        upd.value = 17;
        upd.level = 4;
        upgs[++i] = upd;
    
        i=120;
        //Friends  120
        upd.upgDep = 0;
        upd.level = 0;
        upd.price = 500;
        upd.typeId = 3;
        upd.building = 20;
        upd.value = 1;
        upd.achDep = 1;
        upgs[i] = upd;
        
        upd.typeId = 0;
        upd.building = 20;
        upd.price = 1000000;
        upd.value = 21;
        upd.upgDep = 120;
        upd.achDep = 121;
        upgs[++i] = upd;
        
        // Evil gm
        upd.price = 666;
        upd.building = 1;
        upd.price = 666;
        upd.value = 16;
        upd.level = 1;
        upd.upgDep = 16;
        upd.achDep = 2;
        upgs[++i] = upd;
        
        // Evil GM reset    
        upd.building = 1;
        upd.price = 6666666;
        upd.value = 21;
        upd.achDep = 46;
        upd.upgDep = 122;
        upgs[++i] = upd;

        i = 124;

        // 125 numba up
        upd.price = 999999;
        upd.typeId = 0;
        upd.building = 0;
        upd.price = 999999;
        upd.value = 19;
        upd.level = 4;
        upd.upgDep = 10;
        upd.achDep = 5;
        upgs[++i] = upd;
        
        //126 Matthew
        upd.price = 999999;
        upd.typeId = 0;
        upd.building = 4;
        upd.price = 999999;
        upd.value = 21;
        upd.level = 5;
        upd.upgDep = 27;
        upd.achDep = 0;
        upgs[++i] = upd;

        //127 Rock
        upd.price = 1;
        upd.typeId = 1;
        upd.building = 0;
        upd.price = 10;
        upd.value = 9;
        upd.level = 0;
        upd.achDep = 2;
        upd.upgDep = 0;
        upgs[++i] = upd;

        //128 Sell Rock
        upd.price = 1;
        upd.typeId = 1;
        upd.building = 4;
        upd.price = 10;
        upd.value = 999999;
        upd.level = 2;
        upd.upgDep = 127;
        upgs[++i] = upd;


        //129 Coming to america
        upd.price = 10000;
        upd.typeId = 1;
        upd.building = 4;
        upd.price = 10;
        upd.value = 999999;
        upd.level = 2;
        upd.achDep = 255; //Prince achievement / event
        upd.upgDep = 0;
        upgs[++i] = upd;
    }

    //Type 
    // 0-9 Total tokens
    // 10-19 Total cpb
    // 20-29 Count upgrades
    // 30-39 Count achievements
    // 40-81 count buildings
    // 82-99 specific update 
    // 130-138 level
    uint64[256] public ach = [
        100,10000,500000,10000000,500000000,1000000000000,100000000000000,10000000000000000,50000000000000000,1000000000000000000,
        10,100,500,1000,5000,10000,100000,1000000,10000000,1000000000,
        1,5,10,20,30,40,50,60,80,100,
        10,20,30,40,50,60,80,100,111,256,
        5,10,20,50,5,10,20,50,5,10, 
        20,50,5,10,20,50,5,10,20,50, //52 WP
        5,10,20,50,5,10,20,50,5,10, 
        20,50,5,10,20,50,5,10,20,50,
        5,10,20,50,5,10,20,50,5,10, 
        20,50,5,10,20,50,5,10,20,50,
        5,10,20,50,5,10,20,50,5,10, 
        20,50,5,10,20,50,5,10,20,50,
        5,10,20,50,0,0,0,0,0,10, // 129
        0,1,2,3,4,5,6,7,8,9, // 130 - 139 level
        1,10,100,1000,5000,10000,50000,100000,250000,1000000, // CGT 140 - 149
        1,100,10000,1000000,100000000,100000000,10000000000,100000000000,1000000000000,1000000000000, // 150 - 159 AGE
        1,2,10,100,1000,10000,0,0,0, // 160 - 169 Negative production
        100,200,5000,10000,500000,0,0,0,0,0, // 170 - 179 Negative bank
        0,0,0,0,0,0,0,0,0,0, // 189
        0,0,0,0,0,0,0,0,0,0, // 199
        0,0,0,0,0,0,0,0,0,0, // 209
        0,0,0,0,0,0,0,0,0,0, // 219
        0,0,0,0,0,0,0,0,0,0, // 229
        0,0,0,0,0,0,0,0,0,0, // 239
        0,0,0,0,0,0,0,0,0,0, // 249
        0,0,0,0,0,0 // 256
    ];

    
    function getPrice() public view returns(uint64[22] memory) {
        return price;
    }
    function getProfit() public view returns(int16[22] memory) {
        return profit;
    }
    function getLevelPrice() public view returns(uint64[10] memory) {
        return levelPrice;
    }
    function getAllAchievements() public view returns(uint64[256] memory) {
        return ach;
    } 
    function getUpgrade(uint8 n) public view returns(Upgrade memory u) {
        return upgs[n];
    }
    function getUpgrades() public view returns (Upgrade[255] memory) {
        Upgrade[255] memory m;
        for(uint8 i=0; i<255; i++) {
            m[i] = upgs[i];
        }
        return m;
    }
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

struct Upgrade {
    uint8 typeId;
    uint8 building;
    uint8 upgDep;
    uint8 achDep;
    uint8 level;
    uint32 price;
    int64 value;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Game.sol";
import "./Upgrade.sol";
import "../Vars.sol";
import "../Tokens.sol";

struct AppStorage {
    Vars vars;
    Tokens tokens;
    uint sunrise;
    uint bananas;

    address[] gameIndex; 

    int16[22] profit;
    uint64[22] price;
    uint64[10] levelPrice;
    uint16 bavailibility;
    uint16 governanceAchievementReward;
    uint16 governanceBlockHeight;

    mapping(address => Game) games;
    uint8[256] upgrades;

    uint random;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Game {
    address owner;
    uint8 level;
    uint64 claimed;
    uint256 start;
    uint256 achievements;
    int256 tokens;
    int16[22] profit;
    uint32[22] buildingAmount;
    uint256[22] buildingSum;
    uint32[256] upgrades;
    uint256 random;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Tokens is Initializable, ERC1155Upgradeable {    

    uint256 public constant CCGT = 0;
    uint256 public constant RUG_1  = 1;
    uint256 public constant RUG_2  = 2;
    uint256 public constant RUG_3  = 3;
    uint256 public constant RUG_4  = 4;
    uint256 public constant RUG_5  = 5;   
    uint256 public constant RUG_6  = 6;
    uint256 public constant RUG_999  = 999;

    uint[6] public rugpull = [5000000, 999999999,1999999999,11999999999,1000000,1000000];
    uint16[6] public ruglevel = [3,4,5,6,9,10];


    function initialize(address a) public initializer {   
         __ERC1155_init("https://coinclicker.io/api/rug/{id}.json");

        _mint(a, CCGT, 1000 ** 18, "");
        _mint(a, RUG_1, 1, "");
        _mint(a, RUG_2, 1, "");
        _mint(a, RUG_3, 1, "");
        _mint(a, RUG_4, 1, "");
        _mint(a, RUG_5, 1, "");
        _mint(a, RUG_6, 1, "");
        _mint(0x1e133277eb9f7A576b051877B0A493e9E42845C1, RUG_999, 1, "");
    }

    function getRugLevel() public view returns(uint16[6] memory) {
        return ruglevel;
    } 
    
    function getRugPrice() public view returns(uint[6] memory) {
        return rugpull;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function uri(uint256) public view virtual override returns (string memory) {
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
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
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
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
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
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
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
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
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
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
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

