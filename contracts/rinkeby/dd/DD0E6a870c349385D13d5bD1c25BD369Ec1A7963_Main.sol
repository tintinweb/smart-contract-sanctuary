// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./structs/AppStorage.sol";
import "./structs/Game.sol";

import "./libraries/Buy.sol";
import "./libraries/Sell.sol";
import "./libraries/CreateGame.sol";
import "./libraries/GetCoins.sol";
import "./libraries/BuyUpgrade.sol";
import "./libraries/LevelUp.sol";
import "./libraries/PullRug.sol";
import "./libraries/ClaimAchievement.sol";
import "./libraries/ClaimGovernanceToken.sol";
import "./libraries/ClaimRandomEvent.sol";


contract Main is Initializable, ERC1155HolderUpgradeable, OwnableUpgradeable {
    AppStorage internal s;

    using Buy for Game;
    using Sell for Game;
    using BuyUpgrade for Game;
    using GetCoins for Game;
    using LevelUp for Game;
    using PullRug for Game;
    using ClaimAchievement for Game;
    using ClaimGovernanceToken for Game;
    using ClaimRandomEvent for Game;

    function initialize() public initializer {
        __Ownable_init_unchained();
        s.sunrise = block.number;
        s.random = uint(blockhash(block.number-1));
    }
    
    function createGame() public {
        CreateGame.createGame(s, s.random);
        s.random = uint(blockhash(block.number-1));
    }

    function buy(uint8 _buildingId) public {
        Game storage g = s.games[msg.sender];
        g.buy(s, _buildingId);
    }

    function sell(uint8 _buildingId) public {
        Game storage g = s.games[msg.sender];
        g.sell(s, _buildingId);
    }

    function getCoins() public view returns(int256) {
        Game storage g = s.games[msg.sender];
        return g.getCoins();
    }

    function buyUpgrade(uint8 _upgradeId) public {
        Game storage g = s.games[msg.sender];
        g.buyUpgrade(s, _upgradeId);
    }

    function pullRug(uint8 _rugId) public {
        Game storage g = s.games[msg.sender];
        g.pullRug(s, _rugId);
    }

    function levelUp() public {
        Game storage g = s.games[msg.sender];
        g.levelUp(s);
    }

    function getGame(address _a) public view returns(Game memory) {
        return s.games[_a];
    }

    function claimAchievement(uint8 _achievementId) public {
        Game storage g = s.games[msg.sender];
        g.claimAchievement(s, _achievementId);
    }

    function claimGovernanceToken() public {
        Game storage g = s.games[msg.sender];
        g.claimGovernanceToken(s);
    }

    function banance() public view returns(uint) {
        return s.bananas;
    }

    function sunrise() public view returns(uint) {
        return s.sunrise;
    }

    function claimRandomEvent() public {
        Game storage g = s.games[msg.sender];
        g.claimRandomEvent(s);
    }

    function transferBalance() public onlyOwner {
        s.tokens.safeTransferFrom(address(this), owner(), 0, s.tokens.balanceOf(address(this),0), "0x0");
        s.tokens.safeTransferFrom(address(this), owner(), 1, s.tokens.balanceOf(address(this),1), "0x0");
        s.tokens.safeTransferFrom(address(this), owner(), 2, s.tokens.balanceOf(address(this),2), "0x0");
        s.tokens.safeTransferFrom(address(this), owner(), 3, s.tokens.balanceOf(address(this),3), "0x0");
        s.tokens.safeTransferFrom(address(this), owner(), 4, s.tokens.balanceOf(address(this),4), "0x0");
        s.tokens.safeTransferFrom(address(this), owner(), 5, s.tokens.balanceOf(address(this),5), "0x0");
        s.tokens.safeTransferFrom(address(this), owner(), 6, s.tokens.balanceOf(address(this),6), "0x0");
    }

    function setContracts(Tokens _tokens, Vars _vars) public onlyOwner {
        s.tokens = _tokens;
        s.vars = _vars;

        //Move some CCGT to distribute
        s.tokens.safeTransferFrom(address(this), owner(), 0, 100000 * (10**18), "0x0");
    }

    function getPlayers() public view returns (address[] memory players) {
        players = s.gameIndex;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
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

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
import "./GetCoins.sol";
import "./CoinMath.sol";

library Buy {
    using GetCoins for Game;
    function buy(Game storage g, AppStorage storage s, uint8 _buildingId) validBuyBuildingNumber(_buildingId) external  {
        int bprice;
        require(g.buildingAmount[_buildingId] < 300);
        if(_buildingId == 21) {
            uint amount = 100;
            if(s.gameIndex.length < 46) {
                amount = 1000 - (s.gameIndex.length * 20);                
            }
            require(((block.number - s.sunrise)/amount) - s.bananas > 0);
            uint divide = s.gameIndex.length;
            if(s.gameIndex.length > 1) {
                divide = s.gameIndex.length / 2;
            }
            bprice = int(CoinMath.fracExp(s.vars.getPrice()[_buildingId], (s.bananas / divide)));
        } else {
            bprice = int(CoinMath.fracExp(s.vars.getPrice()[_buildingId], g.buildingAmount[_buildingId]));
        }
        require(g.getCoins() >= bprice, "X");
        g.tokens = g.tokens - bprice;
        g.buildingAmount[_buildingId]++;
        g.buildingSum[_buildingId] += (block.number - g.start);

        if(_buildingId  == 21) {
            s.bananas++;
        }
    }

    modifier validBuyBuildingNumber(uint buildingNumber) {
        if(buildingNumber>0 && buildingNumber<22) {
            _;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
import "./CoinMath.sol";
import "./GetCoins.sol";

library Sell {
    using GetCoins for Game;

    modifier validSellBuildingNumber(uint buildingNumber) {
        if(buildingNumber>0 && buildingNumber<22) {
            _;
        }
    }

    function sell(Game storage _g, AppStorage storage _s, uint8 _buildingId) validSellBuildingNumber(_buildingId) external {
        require(_g.buildingAmount[_buildingId] > 0);

        if(_buildingId == 1) {
            //Sold grandma
            _g.achievements = _g.achievements | (uint256(1) << 253);
        }

        int a = int(_g.buildingSum[_buildingId]) - (int(block.number - _g.start) / (_g.buildingAmount[_buildingId] + 1));
        if(a < 0) {
            _g.buildingSum[_buildingId] = 0;
        } else {
            _g.buildingSum[_buildingId] -= uint(a);
        }
        _g.buildingAmount[_buildingId]--;
        _g.tokens = _g.tokens + int256(CoinMath.fracExp(_s.vars.getPrice()[_buildingId], _g.buildingAmount[_buildingId]));
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
import "./NumHouses.sol";

library CreateGame {
    function createGame(AppStorage storage _s, uint random) external {
        Game memory g;
        g.buildingAmount[0] = NumHouses.numHouses(_s);
        g.owner = msg.sender;
        g.start = block.number;
        g.profit = _s.vars.getProfit();
        g.random = random;
        _s.games[msg.sender] = g;
        _s.gameIndex.push(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
library GetCoins {
    function getCoins(Game storage _g) public view returns (int256 total) {
        uint256 diff = block.number - _g.start;
        total = _g.tokens;
        for (uint256 i = 0; i < 22; i++) {
            if(_g.buildingAmount[i] > 0) {
                uint256 diffA = (diff * _g.buildingAmount[i]) - _g.buildingSum[i];
                uint256 cLevel = uint16(_g.level + 1);
                total = total + int256(diffA) * _g.profit[i] * int256(cLevel);
            }
        }
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
import "../structs/Upgrade.sol";
import "./GetCoins.sol";
import "./GetAchievement.sol";

library BuyUpgrade {
    using GetCoins for Game;
    using GetAchievement for Game;

    function buyUpgrade(Game storage _g, AppStorage storage _s, uint8 _upgradeId) public {
        Upgrade memory localUpgrade;
        localUpgrade = _s.vars.getUpgrade(_upgradeId);
        int currentCookies = _g.getCoins();
        require(uint256(currentCookies) >= localUpgrade.price);
        require(_g.upgrades[_upgradeId] < 1 && _g.level >= localUpgrade.level);
        
        if(localUpgrade.upgDep != 0) {
            require(_g.upgrades[localUpgrade.upgDep] > 0);
        }
        if(localUpgrade.achDep != 0) {
            require(_g.getAchievement(localUpgrade.achDep));
        }
        //Upgrade sets new production value for the building
        if(localUpgrade.typeId == 0) {
            localUpgrade.value % 2 == 0 ? localUpgrade.value * -1 : localUpgrade.value;
            _g.profit[localUpgrade.building] = int16(localUpgrade.value);
            //Pay
            _g.tokens = _g.tokens - (localUpgrade.price + (_g.getCoins() - currentCookies));
        }
        // //Give a certain amount of cookies
        if(localUpgrade.typeId == 1) {
            //Pay
            _g.tokens = _g.tokens + (int(localUpgrade.value) - int(localUpgrade.price));
        }
        // //Reset balance destroys 
        if(localUpgrade.typeId == 2) {
            //Pay
            _g.tokens = 0;
        }
        // //Award amount of buildings
        if(localUpgrade.typeId == 3) {
            //Pay
            _g.buildingAmount[localUpgrade.building] = uint32(int32(_g.buildingAmount[localUpgrade.building] + localUpgrade.value));
            _g.buildingSum[localUpgrade.building] = _g.buildingSum[localUpgrade.building] + uint256(int(localUpgrade.value) *  int(block.number - _g.start));
            _g.tokens = _g.tokens - int(localUpgrade.price);
        }
        // Record it was bought
        _g.upgrades[_upgradeId] = uint32(block.number - _g.start);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
import "./GetCoins.sol";
import "./CoinMath.sol";

library LevelUp {
    using GetCoins for Game;

    function levelUp(Game storage _g, AppStorage storage _s) external {
        require(
            uint256(_g.getCoins()) >= _s.vars.getLevelPrice()[uint256(_g.level + 1)]
        );
        uint32[22] memory buildingAmount;
        uint256[22] memory buildingSum;
        uint32[128] memory upgrades;
        uint32 numHouses = _g.buildingAmount[0];

        _g.upgrades = upgrades;
        _g.level++;
        _g.tokens = (int(block.number) - int(_g.start)) * int(numHouses * int(_g.level+1) * -1);
        _g.buildingAmount = buildingAmount;
        _g.buildingSum = buildingSum;
        _g.profit = _s.vars.getProfit();
        _g.buildingAmount[0] = numHouses;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
import "./GetCoins.sol";
import "./CoinMath.sol";
import "../Tokens.sol";


library PullRug {
    using GetCoins for Game;    

    function pullRug(Game storage _g, AppStorage storage _s, uint8 _rugId) external isRug(_rugId) {
        uint256 rlevel = _s.tokens.getRugLevel()[_rugId-1];
        uint256 rprice = _s.tokens.getRugPrice()[_rugId-1];
        require(
            _g.getCoins() >= int256(rprice) &&
                _s.tokens.balanceOf(address(this), _rugId) == 1 &&
                uint256(_g.level) >= rlevel,
            "S"
        );
        _s.tokens.safeTransferFrom(address(this), msg.sender, _rugId, 1, "0x0");

        //Reset his/her game
        uint32[22] memory buildingAmount;
        uint256[22] memory buildingSum;
        uint32[128] memory upgrades;
        _g.profit = _s.vars.getProfit();
        _g.buildingSum = buildingSum;
        _g.buildingAmount = buildingAmount;
        _g.upgrades = upgrades;
        _g.tokens = 0;
        _g.level = 0;
    }

    modifier isRug(uint _rugId) {
        if(_rugId>0 && _rugId <= 64) {
            _;
        }
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
import "../structs/Upgrade.sol";
import "./GetCoins.sol";
import "./GetAchievement.sol";

library ClaimAchievement {
    using GetCoins for Game;
    using GetAchievement for Game;

    function claimAchievement(Game storage _g, AppStorage storage _s, uint8 _achievementId) public {
        uint64 achievementValue = _s.vars.getAllAchievements()[_achievementId];
        bool b = false;
        uint count = 0;
        //Check deps
        if(_achievementId >= 0 && _achievementId < 10) {
            int tokens = _g.getCoins();
            require(tokens >= int(achievementValue), "N0F");
        }

        //Current prod
        if((_achievementId >= 10 && _achievementId < 20) || _achievementId == 129) {
            int total = 0;
            for(uint i=0; i<=20; i++) {
                if(_g.buildingAmount[i] > 0) {
                    total = total + ((int(_g.buildingAmount[i])) * _g.profit[i] * int(_g.level + 1));
                }
            }
            if(_achievementId != 129) {
                require(total > 0, 'O');
                require(total >= int(achievementValue), "NCF");
            } else {
                require(total <= int(achievementValue)*-1, "NNF");
            }
        }   

        //Check upgrade count
        if(_achievementId >= 20 && _achievementId < 30) {
            for(uint i = 0; i<=127; i++) {
                if(_g.upgrades[i] > 0) {
                    count++;
                }
            }
            require(count >= achievementValue, "N2F");
        }
        //Check achievement count
        if(_achievementId >= 30 && _achievementId < 40) {
            for(uint i = 0; i<=255; i++) {
                if(_g.getAchievement(i)) {
                    count++;
                }
            }
            require(count >= achievementValue, "N2F");
        }
        //Buildings 40 - 123
        if(_achievementId >= 40 && _achievementId <= 123)   {
            uint building = (_achievementId - 40);
            building = (building % 4 == 0) ? building : building-(building % 4);
            require(_g.buildingAmount[building/4] >= achievementValue, "N4F");
        }

        //Check Level
        if(_achievementId >= 130 && _achievementId < 140) { 
            require(_g.level >= achievementValue);
        }

        //Check CCGT Balance
        if(_achievementId >= 140 && _achievementId < 150) { 
            require(achievementValue > _s.tokens.balanceOf(msg.sender, 0) ** (10 ** 18));
        }

        //Spec update
        if(_achievementId >= 150 && _achievementId < 160) {
            require(_g.start > achievementValue, "AGE");
        }
        if(_achievementId >= 160 && _achievementId < 200) {
            require(_g.upgrades[achievementValue] > 0, "NUF");
        }
        b = true;
        if (b) {
           _g.achievements = _g.achievements | (uint256(1) << _achievementId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";
import "../structs/Upgrade.sol";
import "./GetCoins.sol";
import "./GetAchievement.sol";

library ClaimGovernanceToken {
    using GetCoins for Game;
    using GetAchievement for Game;

    function claimGovernanceToken(Game storage _g, AppStorage storage _s) public {
        uint256 achievements = 0;
        for (uint256 i = 0; i <= 128; i++) {
            if (_g.getAchievement(i)) {
                achievements++;
            }
        }
        achievements = _s.vars.governanceBlockHeight() - (achievements * _s.vars.governanceAchievementReward());
        uint256 diff = (((block.number - (_g.start + _g.claimed)) * (10**18)) / achievements);
        _g.claimed = uint64(block.number - _g.start);
        require(_s.tokens.balanceOf(address(this), 0) > diff);
        _s.tokens.safeTransferFrom(address(this), msg.sender, 0, diff, "0x0");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";

library ClaimRandomEvent {

    event Claim(address indexed _from, uint indexed _block, uint _random, uint _randomslice, uint32 result);

    function claimRandomEvent(Game storage _g, AppStorage storage _s) public  {
        uint32 mod = uint32((_g.random % 100) + 50);
        uint32 eventNumber = uint32(block.number % mod);
        require(eventNumber >= 0 && eventNumber <= 2, "NIW");

        //ICO
        if(mod <60) {
            _g.tokens = _g.tokens + int(mod * (1000 * (_g.level+1)));
        }

        //Bitconnect
        if(mod >= 60 && mod < 80) {
            if(mod%2==0) {
                _g.tokens = _g.tokens + int(mod * (2000 * (_g.level+1)));
            } else {
                _g.tokens = _g.tokens - int(mod * (1000 * (_g.level+1)));
            }
        }

        //Line dance
        if(mod >= 80 && mod < 100) {
            if(mod%2==0) {
                _g.tokens = _g.tokens + int(mod * (2000 * (_g.level+1)));
            } else {
                _g.tokens = _g.tokens - int(mod * (1000 * (_g.level+1)));
            }
        }

        //Achievement
        if(mod >= 100 && mod < 120) {
            _g.achievements = _g.achievements | (uint256(1) << 254);
        }

        //Prince
        if(mod >= 120) {
            _g.achievements = _g.achievements | (uint256(1) << 255);
        }
        _g.random = uint(blockhash(block.number - 1));
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
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

library CoinMath {
    // 10 / 1
    function fracExp(uint k, uint n) external pure returns (uint) {
        uint256[302] memory exp = [10, 15, 22, 33, 50, 75, 113, 170, 256, 384, 576, 864, 1297, 1946, 2919, 4378, 6568, 9852, 14778, 22168, 33252, 49878, 74818, 112227, 168341, 252511, 378767, 568151, 852226, 1278340, 1917510, 2876265, 4314398, 6471598, 9707397, 14561096, 21841644, 32762466, 49143699, 73715548, 110573323, 165859984, 248789977, 373184965, 559777448, 839666173, 1259499259, 1889248889, 2833873334, 4250810001, 6376215002, 9564322503, 14346483754, 21519725632, 32279588448, 48419382672, 72629074008, 108943611013, 163415416519, 245123124779, 367684687169, 551527030753, 827290546130, 1240935819196, 1861403728794, 2792105593192, 4188158389788, 6282237584682, 9423356377023, 14135034565535, 21202551848302, 31803827772453, 47705741658680, 71558612488021, 107337918732031, 161006878098047, 241510317147070, 362265475720606, 543398213580909, 815097320371364, 1222645980557046, 1833968970835569, 2750953456253354, 4126430184380031, 6189645276570048, 9284467914855072, 13926701872282604, 20890052808423912, 31335079212635864, 47002618818953800, 70503928228430688, 105755892342646048, 158633838513969056, 237950757770953600, 356926136656430400, 535389204984645632, 803083807476968320, 1204625711215452416, 1806938566823178496, 2710407850234767872, 4065611775352153088, 6098417663028229120, 9147626494542342144, 13721439741813514240, 20582159612720271360, 30873239419080409088, 46309859128620613632, 69464788692930904064, 104197183039396380672, 156295774559094571008, 234443661838641856512, 351665492757962752000, 527498239136944095232, 791247358705416273920, 1186871038058124279808, 1780306557087186419712, 2670459835630779629568, 4005689753446169182208, 6008534630169254559744, 9012801945253880791040, 13519202917880824856576, 20278804376821233090560, 30418206565231851732992, 45627309847847781793792, 68440964771771668496384, 102661447157657485967360, 153992170736486245728256, 230988256104729351815168, 346482384157094061277184, 519723576235641091915776, 779585364353461604319232, 1169378046530192406478848, 1754067069795288408391680, 2631100604692932746805248, 3946650907039399388643328, 5919976360559099619835904, 8879964540838647819141120, 13319946811257972265582592, 19979920216886958398373888, 29969880325330439745044480, 44954820487995663912534016, 67432230731993487278866432, 101148346097990222328365056, 151722519146985342082482176, 227583778720477987353919488, 341375668080717032570486784, 512063502121075548855730176, 768095253181613357643333632, 1152142879772420036465000448, 1728214319658629985978023936, 2592321479487944841528082432, 3888482219231917537170030592, 5832723328847875755999232000, 8749084993271813633998848000, 13123627489907719351486644224, 19685441234861581226253221888, 29528161852292368540844949504, 44292242778438559408337190912, 66438364167657839112505786368, 99657546251486749872665657344, 149486319377230133605091508224, 224229479065845182815451217920, 336344218598767739038804738048, 504516327898151678926951284736, 756774491847227694312287371264, 1135161737770841400730942701568, 1702742606656261749252693164032, 2554113909984392905354016456704, 3831170864976589920980978106368, 5746756297464884599996490448896, 8620134446197326899994735673344, 12930201669295988098192289824768, 19395302503943984399088248422400, 29092953755915977724532279476224, 43639430633873968838598232899584, 65459145950810948754297721978880, 98188718926216432138645837709312, 147283078389324630193570247081984, 220924617583986954297554625363968, 331386926375980413431933428563968, 497080389563970548090306104918016, 745620584345955930221850214268928, 1118430876518933967390369359331328, 1677646314778400734912771925213184, 2516469472167601390599534039531520, 3774704208251402230014489135153152, 5662056312377102768560981399306240, 8493084468565653576380719795535872, 12739626702848481517492584300150784, 19109440054272721123317371843379200, 28664160081409086296662076192456704, 42996240122113622527464086647603200, 64494360183170433791196129971404800, 96741540274755669133538268666658816, 145112310412133476030191292435660800, 217668465618200214045286938653491200, 326502698427300376408162629108891648, 489754047640950564612243943663337472, 734631071461425773131389620656799744, 1101946607192138659697084430985199616, 1652919910788207989545626646477799424, 2479379866182311984318439969716699136, 3719069799273468271625565133927874560, 5578604698910201817142537342186160128, 8367907048365303316009616371984891904, 12551860572547954974014424557977337856, 18827790858821932461021636836966006784, 28241686288232896330349213820626403328, 42362529432349349217890303600584818688, 63543794148524019104468972531232014336, 95315691222786028656703458796848021504, 142973536834179033540322222455981604864, 214460305251268559755216299423262834688, 321690457876902877411756312092055961600, 482535686815354221670304810745179668480, 723803530223031408063320942032092921856, 1085705295334547112094981413048139382784, 1628557943001820668142472119572209074176, 2442836914502730851097980727529666772992, 3664255371754096276646971091294500159488, 5496383057631145321664821347913631268864, 8244574586446716773571412407241272197120, 12366861879670077578208757840120257708032, 18550292819505112740535677916292862443520, 27825439229257667901877697259810118959104, 41738158843886499434964906660456829026304, 62607238265829751570298999219943592951808, 93910857398744632191151777288432088252416, 140866286098116957958134222849681530028032, 211299429147175456280014448108589090340864, 316949143720763107048769216826616454316032, 475423715581144699258780052908058272071680, 713135573371717048888170079362087408107520, 1069703360057575650703507574379398293356544, 1604555040086363476055261361569097440034816, 2406832560129544749855377310336043072880640, 3610248840194318207980600340211805146054656, 5415373260291476693000880867627570269519872, 8123059890437215658471340944131492853841920, 12184589835655822249766972130816964381638656, 18276884753483730898770379625464896774209536, 27415327130225598824035648008957894959562752, 41122990695338393284293314871915742842847232, 61684486043007599829960286590915813457264640, 92526729064511379937899801320289321799909376, 138790093596767109520930959112602779471839232, 208185140395150644474355810102819770821771264, 312277710592725946904493086588145257846669312, 468416565889088959970820887014386683541979136, 702624848833633400342150073389411228540993536, 1053937273250450179741387624348454436355440640, 1580905909875675586524731493580032028708962304, 2371358864813512904418122154784022481799741440, 3557038297220269198170858203647358535611711488, 5335557445830404431081587419585738551769169920, 8003336168745604428233830729977155208423145472, 12005004253118407910001346323195134309337923584, 18007506379677614400303219941251504457413296128, 27011259569516419065153629455418453692713533440, 40516889354274628597730444183127680539070300160, 60775334031411945431896866731150323802011860992, 91163001047117918147845300096725485703017791488, 136744501570676887362972751970923440528152330240, 205116752356015320903254326130549948818602852352, 307675128534022961072471885544154499280652992512, 461512692801034502455936639271243020762733346816, 692269039201551713119085751603523683249597448192, 1038403558802327650808267042011967220663401316352, 1557605338203491395082762148411269135206096830464, 2336408007305237254883420051830267094387155533824, 3504612010957855395547299590105310466846702436352, 5256918016436782768802395726731238917114033078272, 7885377024655174477722147248523585158827070193664, 11828065536982763663694542823345738437176728748032, 17742098305474144197467599601311700523141010817024, 26613147458211213700052970134553736519463351615488, 39919721187316823146227884469244419044443192033280, 59879581780975237315490255971280442831912952659968, 89819372671462840396344808352437778656380441329664, 134729059007194291748298363737622439167548637315072, 202093588510791416853260111467123144629337639092224, 303140382766187125279890167200684716944006458638336, 454710574149280646381460382522406047172039054196736, 682065861223921052648940310340851127245999848816640, 1023098791835881620511785333789897719112970406985728, 1534648187753822264614178527570362465693573075435520, 2301972281630733230767768318241059585564477078110208, 3452958422446099846151652477361589378346715617165312, 5179437633669149769227478716042384067520073425747968, 7769156450503725318455215966521512553183640278794240, 11653734675755588642296821842240205281678990558363648, 17480602013633381634217236978444435018711425557200896, 26220903020450075109781847037498398335681258896490496, 39331354530675115323128762126079343311136008905424896, 58997031796012665009325168479623777543861651676069888, 88495547694018992197075769579772174700564236392726528, 132743321541028504246349603788648736896531077953224704, 199114982311542745735700439403646122114340134687080448, 298672473467314118603550659105469183171510202030620672, 448008710200971135370030123540895841835439374074904576, 672013065301456745590341050428651695674984990083383296,6720130653014567455903410504286516956749849900833832960000000000000000000000];
        return (k * exp[n]) / 10;
    }
}

//TBD// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";

library NumHouses {
    function numHouses(AppStorage storage _s) external view returns(uint32 n){
        n = uint32(_s.tokens.balanceOf(msg.sender, 0) / (200 * (10**uint256(18))))+1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Game.sol";
import "../structs/AppStorage.sol";

library GetAchievement {
    function getAchievement(Game storage g, uint _boolNumber) public view returns (bool) {
        uint256 flag = (g.achievements >> _boolNumber) & uint256(1);
        return (flag == 1 ? true : false);
    } 
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {
    "contracts/libraries/Buy.sol": {
      "Buy": "0x30eb64827012de873df63982ba2320a102adf746"
    },
    "contracts/libraries/BuyUpgrade.sol": {
      "BuyUpgrade": "0xf6533b4cb3f8c1786305993601df1d899c1b64ec"
    },
    "contracts/libraries/ClaimAchievement.sol": {
      "ClaimAchievement": "0x84614a079c0729cdd9f58690d5c52757c7c3ffb6"
    },
    "contracts/libraries/ClaimGovernanceToken.sol": {
      "ClaimGovernanceToken": "0x539feb8ead57833c95f72558ed71fe7e75869e8e"
    },
    "contracts/libraries/ClaimRandomEvent.sol": {
      "ClaimRandomEvent": "0x46d5e639d00ad18e8c2c81c1017df2ba719e0dae"
    },
    "contracts/libraries/CreateGame.sol": {
      "CreateGame": "0xfd48d435cc7fd71d30aacaaaaf2d99f7c1e6a845"
    },
    "contracts/libraries/GetCoins.sol": {
      "GetCoins": "0x99458d875d8c387f805b5adb5c44cecd2e1a75c0"
    },
    "contracts/libraries/LevelUp.sol": {
      "LevelUp": "0xcecc43299fb37b7642fda319e24c8ba40e2fc53a"
    },
    "contracts/libraries/PullRug.sol": {
      "PullRug": "0x85d2ef1b44766309f9e1afde2dc8a9447286ee06"
    },
    "contracts/libraries/Sell.sol": {
      "Sell": "0xb42e83cfb75e22a043ed3aedf53efe2b6be3927e"
    }
  }
}