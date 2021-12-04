// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "./BattleContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GameContract is BattleContract {
    struct GameOffer {
        uint id;
        uint acceptId;
        address creator;
        uint nft;
        uint bet;
        //uint ready;
    }

    struct GameAccept {
        uint id;
        uint offerId;
        address acceptor;
        uint nft;
        uint bet;
        //uint ready;
    }

    mapping(address => GameOffer[]) offers;
    mapping(uint => GameAccept[]) accepts;
    //Log[] logs;

    address public token;
    address public nftAddress;

    event Logs(Log log);
    event Offer(uint);
    event Accept(uint);

    function CreateOffer(uint nft, uint bet) public
    {
        IERC20(token).transferFrom(msg.sender, address(this), bet);
        uint id = Random(6);
        offers[msg.sender].push( GameOffer(id, 0, msg.sender, nft, bet) );
        emit Offer(id);
    }

    function GetOffers(address from) public view returns (GameOffer[] memory)
    {
        return offers[from];
    }

    function GetAccepts(uint offerId) public view returns (GameAccept[] memory)
    {
        return accepts[offerId];
    }

    function AcceptOffer(uint offerId, uint nft, uint bet) public
    {
        IERC20(token).transferFrom(msg.sender, address(this), bet);
        uint id = Random(7);
        accepts[offerId].push(GameAccept(id, offerId, msg.sender, nft, bet));
        emit Accept(id);
    }

    function StartBattle(uint offerId, uint acceptId) public //returns(Log memory)
    {
        GameOffer[] memory userOffers = offers[msg.sender];
        for(uint i = 0; i < userOffers.length; i++)
        {
            GameOffer memory offer = userOffers[i];
            if(offer.id == offerId)
            {
                GameAccept[] memory userAccepts = accepts[offerId];
                for(uint j = 0; j < userAccepts.length; j++)
                {
                    GameAccept memory accept = userAccepts[j];
                    if(accept.id == acceptId)
                    {
                        Log memory log = Fight(Battle(
                            EArenaType(Random(1)%3),
                            Bot(botsData[offer.nft],
                                int(baseData.baseHp),
                                Random(2) % baseData.roundCount,
                                Random(3) % baseData.roundCount),
                            Bot(botsData[accept.nft],
                                int(baseData.baseHp),
                                Random(4) % baseData.roundCount,
                                Random(5) % baseData.roundCount)
                        ));

                        //Log storage logSave = Log(log._roundsLog, log.battle);
                       // logSave._roundsLog = log._roundsLog;
                        //logs.push(log);

                        PayWinner(log, offer, accept);

                        emit Logs(log);
                    }
                }

            }
        }
        //Battle battle = Battle
    }

    function PayWinner(Log memory log, GameOffer memory offer, GameAccept memory accept) internal
    {
        IERC20 qzqToken = IERC20(token);
        if(log.battle._bot_1.Hp > log.battle._bot_2.Hp)
        {
            qzqToken.transferFrom(address(this), offer.creator, offer.bet + accept.bet);
        }
        else if(log.battle._bot_1.Hp < log.battle._bot_2.Hp)
        {
            qzqToken.transferFrom(address(this), accept.acceptor, offer.bet + accept.bet);
        }
        else
        {
            qzqToken.transferFrom(address(this), offer.creator, offer.bet);
            qzqToken.transferFrom(address(this), accept.acceptor, accept.bet);
        }
    }

    constructor(address tokenAddress) BattleContract()
    {
        token = tokenAddress;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Randomable {
    function Random(uint seed) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Randomable.sol";

contract BattleContract is Randomable, Ownable {

    enum EWeaponType
    {
        Lighting,
        Claw,
        Club,
        DoubleSpike,
        Spike,
        Blade,
        Saw,
        Drill,
        Hammer,
        Axe,
        _Length
    }

    enum EToyType
    {
        Drum,
        Windmill,
        Icecream,
        Ducky,
        Bottle,
        Shovel,
        Shaker,
        Ball,
        Lollipop,
        Rocket,
        Balloons,
        _Length
    }

    enum EPlatformType
    {
        Platform1,
        Platform2,
        Platform3
    }

    enum EArenaType
    {
        Round,
        Octogon,
        Square
    }

    struct RoundBot
    {
        int hpBefore;
        int hpAfter;
        uint attack;
        uint crit;
        uint _block;
        uint platform;
        bool isCrit;
    }

    struct Round
    {
        uint Id;
        RoundBot Bot_1;
        RoundBot Bot_2;
    }

    struct BaseData
    {
        uint baseHp;
        uint baseAttack;
        uint critMultiplier;
        uint platformBonus;
        uint roundCount;
    }

    struct BotData {
        uint _id;
        EWeaponType _weapon;
        EToyType _toy;
        EPlatformType _platform;
    }

    struct Bot
    {
        BotData botData;

        int Hp;
        uint CritRound;
        uint BlockRound;
    }

    struct Battle
    {
        EArenaType _arena;
        Bot _bot_1;
        Bot _bot_2;
    }

    struct Resistance
    {
        uint8[11] toy;
    }

    struct Log
    {
        Round _roundsLog1;
        Round _roundsLog2;
        Round _roundsLog3;
        Battle battle;
    }

    BaseData baseData;
    mapping(uint => BotData) botsData;
    Resistance[10] resistance;
    uint[] defence;
    uint[] damage;

    constructor() {
        baseData = BaseData(2000, 2500, 1190, 200, 3);

		resistance[0] = Resistance([45, 45, 46, 46, 47, 45, 48, 47, 45, 47, 50]);
        resistance[1] = Resistance([45, 48, 45, 50, 47, 45, 46, 45, 46, 48, 46]);
        resistance[2] = Resistance([47, 45, 46, 45, 48, 46, 47, 46, 50, 47, 49]);
        resistance[3] = Resistance([47, 47, 45, 45, 46, 47, 47, 50, 47, 47, 46]);
        resistance[4] = Resistance([46, 47, 47, 46, 46, 47, 50, 47, 45, 49, 45]);
        resistance[5] = Resistance([47, 46, 46, 47, 46, 48, 47, 46, 48, 46, 49]);
        resistance[6] = Resistance([48, 46, 48, 46, 50, 45, 46, 48, 47, 47, 46]);
        resistance[7] = Resistance([47, 48, 50, 48, 45, 47, 45, 46, 48, 46, 46]);
        resistance[8] = Resistance([50, 48, 46, 46, 46, 46, 46, 48, 47, 46, 46]);
        resistance[9] = Resistance([45, 46, 47, 47, 45, 50, 45, 47, 47, 49, 47]);

        defence = new uint[](uint(EToyType._Length));
        defence[0] = 300;
        defence[1] = 250;
        defence[2] = 250;
        defence[3] = 200;
        defence[4] = 200;
        defence[5] = 150;
        defence[6] = 100;
        defence[7] = 100;
        defence[8] = 100;
        defence[9] = 100;
        defence[10] = 100;

        damage = new uint[](uint(EWeaponType._Length));
        damage[0] = 300;
        damage[1] = 250;
        damage[2] = 200;
        damage[3] = 150;
        damage[4] = 120;
        damage[5] = 100;
        damage[6] = 100;
        damage[7] = 100;
        damage[8] = 100;
        damage[9] = 100;
    }

    function _Test() public view returns (Log memory)
    {
        return
        Fight(Battle(
            EArenaType(Random(515)%3),
            Bot(botsData[1],
                int(baseData.baseHp),
                Random(454) % baseData.roundCount,
                Random(5146) % baseData.roundCount),
            Bot(botsData[2],
                int(baseData.baseHp),
                Random(735673) % baseData.roundCount,
                Random(24562) % baseData.roundCount)
        ));
    }

    function SetBotData(uint _id,
        EWeaponType _weapon,
        EToyType _toy,
        EPlatformType _platform ) public onlyOwner
    {
        botsData[_id] = BotData(_id, _weapon, _toy, _platform);
    }

    function GetBotData(uint _id) public view returns(BotData memory)
    {
        return botsData[_id];
    }


    function Fight(Battle memory battle) internal view returns (Log memory)
    {
        //Round[3] memory _roundsLog;

        /*for(uint i = 0; i < baseData.roundCount; i++)
        {
            _roundsLog[i] = ExecuteRound(battle, i);
        }*/

        Round memory round1 = ExecuteRound(battle, 0);
        Round memory round2 = ExecuteRound(battle, 1);
        Round memory round3 = ExecuteRound(battle, 2);

        return Log(round1, round2, round3, battle);
    }

    function BlockBot(Bot memory bot, EWeaponType strikeWeapon) private view returns(uint)
    {
        uint result = 100000 - (resistance[uint(strikeWeapon)].toy[uint(bot.botData._toy)] * 1000 + defence[uint(bot.botData._toy)] * 10);
        return result;
    }

    function AttackBot(Bot memory bot) private view returns(uint)
    {
        return baseData.baseAttack + damage[uint(bot.botData._weapon)];
    }

    function ExecuteRound(Battle memory battle, uint roundIndex) private view returns(Round memory)
    {
        Round memory round = Round(
            roundIndex,
            RoundBot(battle._bot_1.Hp, battle._bot_1.Hp, 0, 1000, 100000, 0, false), RoundBot(battle._bot_2.Hp, battle._bot_2.Hp, 0, 1000, 100000, 0, false)
        );

        if (battle._bot_1.CritRound == roundIndex)
        {
            round.Bot_1.crit = baseData.critMultiplier;
            round.Bot_1.isCrit = true;
        }

        if (battle._bot_2.CritRound == roundIndex)
        {
            round.Bot_2.crit = baseData.critMultiplier;
            round.Bot_2.isCrit = true;
        }

        if (battle._bot_1.BlockRound == roundIndex)
        {
            round.Bot_1._block = BlockBot(battle._bot_1, battle._bot_2.botData._weapon);
            round.Bot_1.platform = uint(battle._bot_1.botData._platform) == uint(battle._arena) ? baseData.platformBonus : uint(0);
        }

        if (battle._bot_2.BlockRound == roundIndex)
        {
            round.Bot_2._block = BlockBot(battle._bot_2, battle._bot_1.botData._weapon);
            round.Bot_2.platform = uint(battle._bot_2.botData._platform) == uint(battle._arena) ? baseData.platformBonus : uint(0);
        }

        round.Bot_1.attack = AttackBot(battle._bot_1);
        round.Bot_2.attack = AttackBot(battle._bot_2);
        battle._bot_1.Hp -= int(round.Bot_2.attack * round.Bot_2.crit * round.Bot_1._block / 100_000_000 - round.Bot_1.platform) / 10;
        battle._bot_2.Hp -= int(round.Bot_1.attack * round.Bot_1.crit * round.Bot_2._block / 100_000_000 - round.Bot_2.platform) / 10;

        round.Bot_1.hpAfter = battle._bot_1.Hp;
        round.Bot_2.hpAfter = battle._bot_2.Hp;

        return round;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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