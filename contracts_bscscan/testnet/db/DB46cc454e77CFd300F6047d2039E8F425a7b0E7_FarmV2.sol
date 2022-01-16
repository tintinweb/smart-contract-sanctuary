//SPDX-License-Identifier: MIT
// Fruit Farm Game// https://fruitfarm.io
// Logical game contract
pragma solidity  0.8.11 ;
import "./Token.sol";

contract FarmV2 {
    using SafeMath
    for uint256;
    TokenV2 private token;
    address private vault1 = address(0xBCC04780cDd65EB90BEb16631E97acB9B9647D77);
    address private vault2 = address(0xf7428ACEe589552defB48fC1fC4C76e9E8C37A6D);
    enum Action {
        Plant,
        Harvest
    }
    enum Fruit {
        None,
        Lemon,
        Orange,
        Pear,
        Watermelon,
        Pineapple,
        Apple,
        Strawberry
    }
    struct Event {
        Action action;
        Fruit fruit;
        uint40 landIndex;
        uint40 createdAt;
    }
    struct Square {
        Fruit fruit;
        uint40 createdAt;
    }
    struct Farm {
        Square[] land;
        uint256 balance;
    }
    uint256 private SAVE_MINUTES = 30 * 60 * 3;
    uint256 farmCount = 0;
    mapping(address => Square[]) fields;
    mapping(address => uint40) syncedAt;
    mapping(address => uint40) rewardsOpenedAt;
    constructor(TokenV2 _token) {
        token = _token;
    }
    event FarmCreated(address indexed _address);
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    function createFarm(address payable v1, address payable v2) public payable {
        require(syncedAt[msg.sender] == 0, "FARM_EXISTS");
        uint decimals = token.decimals();
        require(
            // Farm Buy $0.10 to play
            msg.value >= 1 * 10 ** (decimals - 1), "INSUFFICIENT_BUY_FARM");
        require(
            // Wallet Buy Farm
            v1 == vault1 && v2 == vault2, "INVALID_WALLET_FARM");
        Square[] storage land = fields[msg.sender];
        Square memory empty = Square({
            fruit: Fruit.None,
            createdAt: 0
        });
        Square memory lemon = Square({
            fruit: Fruit.Lemon,
            createdAt: 0
        });
        // Each farmer starts with 5 fields & 3 lemon
        land.push(empty);
        land.push(lemon);
        land.push(lemon);
        land.push(lemon);
        land.push(empty);
        syncedAt[msg.sender] = uint40(block.timestamp);
        // They must wait X days before opening their first reward
        rewardsOpenedAt[msg.sender] = uint40(block.timestamp);
        (bool sentV1, ) = v1.call {
            value: msg.value.div(2)
        }("");
        require(sentV1, "BUY_FARM_FAILED");
        (bool sentV2, ) = v2.call {
            value: msg.value.div(2)
        }("");
        require(sentV2, "BUY_FARM_FAILED");
        farmCount += 1;
        //Emit an event
        emit FarmCreated(msg.sender);
    }

    function lastSyncedAt(address owner) private view returns(uint40) {
        return syncedAt[owner];
    }

    function getLand(address owner) public view returns(Square[] memory) {
        return fields[owner];
    }

    function getHarvestSeconds(Fruit _fruit) private pure returns(uint40) {
        if (_fruit == Fruit.Lemon) {
            // 5 minute
            return 1 * 60 * 5;
        } else if (_fruit == Fruit.Orange) {
            // 25 minutes
            return 5 * 60 * 5;
        } else if (_fruit == Fruit.Pear) {
            // 5 hour
            return 1 * 60 * 60 * 5;
        } else if (_fruit == Fruit.Watermelon) {
            // 20 hours
            return 4 * 60 * 60 * 5;
        } else if (_fruit == Fruit.Pineapple) {
            // 40 hours
            return 8 * 60 * 60 * 5;
        } else if (_fruit == Fruit.Apple) {
            //  120 hours
            return 24 * 60 * 60 * 5;
        } else if (_fruit == Fruit.Strawberry) {
            // 360 hours
            return 3 * 24 * 60 * 60 * 5;
        }
        require(false, "INVALID_FRUIT");
        return 9999999;
    }

    function getSeedPrice(Fruit _fruit) private view returns(uint price) {
        uint decimals = token.decimals();
        if (_fruit == Fruit.Lemon) {
            //$0.01

            return 1 * 10 ** decimals / 100;
        } else if (_fruit == Fruit.Orange) {
            // $0.10
            return 10 * 10 ** decimals / 100;
        } else if (_fruit == Fruit.Pear) {
            // $0.40
            return 40 * 10 ** decimals / 100;
        } else if (_fruit == Fruit.Watermelon) {
            // $1
            return 1 * 10 ** decimals;
        } else if (_fruit == Fruit.Pineapple) {
            // $4
            return 4 * 10 ** decimals;
        } else if (_fruit == Fruit.Apple) {
            // $10
            return 10 * 10 ** decimals;
        } else if (_fruit == Fruit.Strawberry) {
            // $50
            return 50 * 10 ** decimals;
        }
        require(false, "INVALID_FRUIT");
        return 100000 * 10 ** decimals;
    }

    function getFruitPrice(Fruit _fruit) private view returns(uint price) {
        uint decimals = token.decimals();
        if (_fruit == Fruit.Lemon) {
            // $0.02
            return 2 * 10 ** decimals / 100;
        } else if (_fruit == Fruit.Orange) {
            // $0.16
            return 16 * 10 ** decimals / 100;
        } else if (_fruit == Fruit.Pear) {
            // $0.80
            return 80 * 10 ** decimals / 100;
        } else if (_fruit == Fruit.Watermelon) {
            // $1.8
            return 180 * 10 ** decimals / 100;
        } else if (_fruit == Fruit.Pineapple) {
            // $8
            return 8 * 10 ** decimals;
        } else if (_fruit == Fruit.Apple) {
            // $16
            return 16 * 10 ** decimals;
        } else if (_fruit == Fruit.Strawberry) {
            // $80
            return 80 * 10 ** decimals;
        }
        require(false, "INVALID_FRUIT");
        return 0;
    }

    function requiredLandSize(Fruit _fruit) private pure returns(uint8 size) {
        if (_fruit == Fruit.Lemon || _fruit == Fruit.Orange) {
            return 5;
        } else if (_fruit == Fruit.Pear || _fruit == Fruit.Watermelon) {
            return 8;
        } else if (_fruit == Fruit.Pineapple) {
            return 11;
        } else if (_fruit == Fruit.Apple) {
            return 14;
        } else if (_fruit == Fruit.Strawberry) {
            return 17;
        }
        require(false, "INVALID_FRUIT");
        return 99;
    }

    function getLandPrice(uint8 landSize) private view returns(uint price) {
        uint decimals = token.decimals();
        if (landSize <= 5) {
            // $1
            return 1 * 10 ** decimals;
        } else if (landSize <= 8) {
            // 50
            return 50 * 10 ** decimals;
        } else if (landSize <= 11) {
            // $500
            return 500 * 10 ** decimals;
        }
        // $2500
        return 2500 * 10 ** decimals;
    }
    modifier hasFarm {
        require(lastSyncedAt(msg.sender) > 0, "NO_FARM");
        _;
    }

    function buildFarm(Event[] memory _events) private view hasFarm returns(Farm memory currentFarm) {
        Square[] memory land = fields[msg.sender];
        uint256 balance = token.balanceOf(msg.sender);
        for (uint8 index = 0; index < _events.length; index++) {
            Event memory farmEvent = _events[index];
            uint256 thirtyMinutesAgo = block.timestamp.sub(SAVE_MINUTES);
            require(farmEvent.createdAt >= thirtyMinutesAgo, "EVENT_EXPIRED");
            require(farmEvent.createdAt >= lastSyncedAt(msg.sender), "EVENT_IN_PAST");
            require(farmEvent.createdAt <= block.timestamp, "EVENT_IN_FUTURE");
            if (index > 0) {
                require(farmEvent.createdAt >= _events[index - 1].createdAt, "INVALID_ORDER");
            }
            if (farmEvent.action == Action.Plant) {
                require(land.length >= requiredLandSize(farmEvent.fruit), "INVALID_LEVEL");
                uint price = getSeedPrice(farmEvent.fruit);
                uint fmcPrice = getMarketPrice(price);
                require(balance >= fmcPrice, "INSUFFICIENT_FUNDS");
                balance = balance.sub(fmcPrice);
                Square memory plantedSeed = Square({
                    fruit: farmEvent.fruit,
                    createdAt: farmEvent.createdAt
                });
                land[farmEvent.landIndex] = plantedSeed;
            } else if (farmEvent.action == Action.Harvest) {
                Square memory square = land[farmEvent.landIndex];
                require(square.fruit != Fruit.None, "NO_FRUIT");
                uint40 duration = uint40(uint256(farmEvent.createdAt).sub(square.createdAt));
                uint256 secondsToHarvest = getHarvestSeconds(square.fruit);
                require(duration >= secondsToHarvest, "NOT_RIPE");

                // Clear the land
                Square memory emptyLand = Square({
                    fruit: Fruit.None,
                    createdAt: 0
                });
                land[farmEvent.landIndex] = emptyLand;
                uint price = getFruitPrice(square.fruit);
                uint fmcPrice = getMarketPrice(price);
                balance = balance.add(fmcPrice);
            }
        }
        return Farm({
            land: land,
            balance: balance
        });
    }

    function sync(Event[] memory _events) public hasFarm returns(Farm memory) {
        require(_events.length <= 612, "MAX_EVENT_ALLOWED");
        Farm memory farm = buildFarm(_events);
        // Update the land
        Square[] storage land = fields[msg.sender];
        for (uint8 i = 0; i < farm.land.length; i += 1) {
            land[i] = farm.land[i];
        }
        syncedAt[msg.sender] = uint40(block.timestamp);
        uint256 balance = token.balanceOf(msg.sender);
        // Update the balance - mint or burn
        if (farm.balance > balance) {
            uint256 profit = farm.balance.sub(balance);
            token.mint(msg.sender, profit);
        } else if (farm.balance < balance) {
            uint256 loss = balance.sub(farm.balance);
            token.burn(msg.sender, loss);
        }
        //  emit FarmSynced(msg.sender);

        return farm;
    }

    function levelUp() public hasFarm {
        require(fields[msg.sender].length <= 17, "MAX_LEVEL");
        Square[] storage land = fields[msg.sender];
        uint price = getLandPrice(uint8(land.length));
        uint fmcPrice = getMarketPrice(price);
        uint256 balance = token.balanceOf(msg.sender);
        require(balance >= fmcPrice, "INSUFFICIENT_FUNDS");
        // Store rewards in the Farm Contract to redistribute
        token.transferFrom(msg.sender, address(this), fmcPrice);
        // Add 3 lemon fields in the new fields
        Square memory lemon = Square({
            fruit: Fruit.Lemon,
            // Make them immediately harvestable in case they spent all their tokens
            createdAt: 0
        });
        for (uint8 index = 0; index < 3; index++) {
            land.push(lemon);
        }
        //  emit FarmSynced(msg.sender);
    }
    // How many tokens do you get per dollar
    // Algorithm is totalSupply / 10000 but we do this in gradual steps to avoid widly flucating prices between plant & harvest
    function getMarketRate() private view returns(uint conversion) {
        uint decimals = token.decimals();
        uint totalSupply = token.totalSupply();
        // Less than 100, 000 tokens
        if (totalSupply < (100000 * 10 ** decimals)) {
            // 1 Farm Dollar gets you 1 FMC token
            return 1;
        }
        // Less than 500, 000 tokens
        if (totalSupply < (500000 * 10 ** decimals)) {
            return 5;
        }
        // Less than 1, 000, 000 tokens
        if (totalSupply < (1000000 * 10 ** decimals)) {
            return 10;
        }
        // Less than 5, 000, 000 tokens
        if (totalSupply < (5000000 * 10 ** decimals)) {
            return 50;
        }
        // Less than 10, 000, 000 tokens
        if (totalSupply < (10000000 * 10 ** decimals)) {
            return 100;
        }
        // Less than 50, 000, 000 tokens
        if (totalSupply < (50000000 * 10 ** decimals)) {
            return 500;
        }
        // Less than 100, 000, 000 tokens
        if (totalSupply < (100000000 * 10 ** decimals)) {
            return 1000;
        }
        // Less than 500, 000, 000 tokens
        if (totalSupply < (500000000 * 10 ** decimals)) {
            return 5000;
        }
        // Less than 1, 000, 000, 000 tokens
        if (totalSupply < (1000000000 * 10 ** decimals)) {
            return 10000;
        }
        // 1 Farm Dollar gets you a 0.00001 of a token - Linear growth from here
        return totalSupply.div(10000);
    }

    function getMarketPrice(uint price) public view returns(uint conversion) {
        uint marketRate = getMarketRate();
        return price.div(marketRate);
    }

    function getFarm(address account) public view returns(Square[] memory farm) {
        return fields[account];
    }

    function getFarmCount() public view returns(uint count) {
        return farmCount;
    }
    // Depending on the fields you have determines your cut of the rewards.
    function myReward() public view hasFarm returns(uint256 amount) {
        uint256 lastOpenDate = rewardsOpenedAt[msg.sender];
        // Block timestamp is seconds based
        uint256 threeDaysAgo = block.timestamp.sub(60 * 60 * 24 * 5);
        require(lastOpenDate < threeDaysAgo, "NO_REWARD_READY");
        uint8 landSize = uint8(fields[msg.sender].length);
        // E.g. $1000
        uint256 farmBalance = token.balanceOf(address(this));
        // E.g. $1000 / 500 farms = $2
        uint256 farmShare = farmBalance / farmCount;
        if (landSize <= 5) {
            // E.g $0.2
            return farmShare.div(10);
        } else if (landSize <= 8) {
            // E.g $0.4
            return farmShare.div(5);
        } else if (landSize <= 11) {
            // E.g $1
            return farmShare.div(2);
        }
        // E.g $3
        return farmShare.mul(3).div(2);
    }

    function receiveReward() public hasFarm {
        uint256 amount = myReward();
        require(amount > 0, "NO_REWARD_AMOUNT");
        rewardsOpenedAt[msg.sender] = uint40(block.timestamp);
        token.transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MITr
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// Fruit Farm Game
// https://fruitfarm.io
// Token contract

contract TokenV2 is ERC20, ERC20Burnable {
    address public minter;
    address public owner;
    address public devfee = address(0xdcD1623A9B148bb3Cf7F91ff9d6fE70Ca531a588);
    uint256 public fees = 2;
    using SafeMath for uint256;

    event MinterChanged(address indexed from, address to);
    event TaxEvent(address indexed from, uint256 amoun);

    constructor() ERC20("Fruit Farm Game", "FFG") {
        owner = msg.sender;
        //_mint(owner, 200000 * 10**super.decimals() );
    }

    function setFees(uint256 f) public {
        require(msg.sender == owner, "owner only");
        require(f <= 2 && f >= 0, "Only fee below 2% is allowed.");
        fees = f;
    }

    function setDev(address wallet) public {
        require(msg.sender == owner, "owner only");
        devfee = wallet;
    }

    function passMinterRole(address farm) public returns (bool) {
        require(
            minter == address(0) || msg.sender == minter,
            "You are not minter"
        );
        minter = farm;

        emit MinterChanged(msg.sender, farm);
        return true;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function mint(address account, uint256 amount) public {
        require(
            minter == address(0) || msg.sender == minter,
            "You are not the minter"
        );
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        require(
            minter == address(0) || msg.sender == minter,
            "You are not the minter"
        );
        _burn(account, amount);
    }

    function transfer(address _to, uint256 _amount)
        public
        virtual
        override
        returns (bool)
    {
        uint256 fee = _amount.mul(fees).div(100); // Calculate fee
        super.transfer(_to, _amount.sub(fee));
        super.transfer(devfee, fee);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (msg.sender == minter) {
            _transfer(sender, recipient, amount);
            return true;
        }

        uint256 fee = amount.mul(fees).div(100); // Calculate feer

        super.transferFrom(sender, recipient, amount.sub(fee));
        super.transferFrom(sender, devfee, fee);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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