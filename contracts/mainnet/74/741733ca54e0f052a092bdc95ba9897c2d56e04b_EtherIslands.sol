pragma solidity ^0.4.19;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EtherIslands is Ownable, ERC721 {
    using SafeMath for uint256;

    /*** EVENTS ***/
    event NewIsland(uint256 tokenId, bytes32 name, address owner);
    event IslandSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, bytes32 name);
    event Transfer(address from, address to, uint256 tokenId);
    event DividendsPaid(address to, uint256 amount, bytes32 divType);
    event ShipsBought(uint256 tokenId, address owner);
    event IslandAttacked(uint256 attackerId, uint256 targetId, uint256 treasuryStolen);
    event TreasuryWithdrawn(uint256 tokenId);

    /*** STRUCTS ***/
    struct Island {
        bytes32 name;
        address owner;
        uint256 price;
        uint256 treasury;
        uint256 treasury_next_withdrawal_block;
        uint256 previous_price;
        uint256 attack_ships_count;
        uint256 defense_ships_count;
        uint256 transactions_count;
        address approve_transfer_to;
        address[2] previous_owners;
    }

    struct IslandBattleStats {
        uint256 attacks_won;
        uint256 attacks_lost;
        uint256 defenses_won;
        uint256 defenses_lost;
        uint256 treasury_stolen;
        uint256 treasury_lost;
        uint256 attack_cooldown;
        uint256 defense_cooldown;
    }

    /*** CONSTANTS ***/
    string public constant NAME = "EtherIslands";
    string public constant SYMBOL = "EIS";

    bool public maintenance = true;
    uint256 islands_count;

    uint256 shipPrice = 0.01 ether;
    uint256 withdrawalBlocksCooldown = 720;
    uint256 battle_cooldown = 40;
    address m_address = 0x9BB3364Baa5dbfcaa61ee0A79a9cA17359Fc7bBf;

    mapping(address => uint256) private ownerCount;
    mapping(uint256 => Island) private islands;
    mapping(uint256 => IslandBattleStats) private islandBattleStats;

    /*** DEFAULT METHODS ***/
    function symbol() public pure returns (string) {return SYMBOL;}

    function name() public pure returns (string) {return NAME;}

    function implementsERC721() public pure returns (bool) {return true;}

    function EtherIslands() public {
    }

    /** PUBLIC METHODS **/
    function createIsland(bytes32 _name, uint256 _price, address _owner, uint256 _attack_ships_count, uint256 _defense_ships_count) public onlyOwner {
        require(msg.sender != address(0));
        _create_island(_name, _owner, _price, 0, _attack_ships_count, _defense_ships_count);
    }

    function importIsland(bytes32 _name, address[3] _owners, uint256[7] _island_data, uint256[8] _island_battle_stats) public onlyOwner {
        require(msg.sender != address(0));
        _import_island(_name, _owners, _island_data, _island_battle_stats);
    }

    function attackIsland(uint256 _attacker_id, uint256 _target_id) public payable {
        require(maintenance == false);
        Island storage attackerIsland = islands[_attacker_id];
        IslandBattleStats storage attackerIslandBattleStats = islandBattleStats[_attacker_id];

        Island storage defenderIsland = islands[_target_id];
        IslandBattleStats storage defenderIslandBattleStats = islandBattleStats[_target_id];

        require(attackerIsland.owner == msg.sender);
        require(attackerIsland.owner != defenderIsland.owner);
        require(msg.sender != address(0));
        require(msg.value == 0);
        require(block.number >= attackerIslandBattleStats.attack_cooldown);
        require(block.number >= defenderIslandBattleStats.defense_cooldown);
        require(attackerIsland.attack_ships_count > 0); // attacker must have at least 1 attack ship
        require(attackerIsland.attack_ships_count > defenderIsland.defense_ships_count);

        uint256 goods_stolen = SafeMath.mul(SafeMath.div(defenderIsland.treasury, 100), 25);

        defenderIsland.treasury = SafeMath.sub(defenderIsland.treasury, goods_stolen);

        attackerIslandBattleStats.attacks_won++;
        attackerIslandBattleStats.treasury_stolen = SafeMath.add(attackerIslandBattleStats.treasury_stolen, goods_stolen);

        defenderIslandBattleStats.defenses_lost++;
        defenderIslandBattleStats.treasury_lost = SafeMath.add(defenderIslandBattleStats.treasury_lost, goods_stolen);

        uint256 cooldown_block = block.number + battle_cooldown;
        attackerIslandBattleStats.attack_cooldown = cooldown_block;
        defenderIslandBattleStats.defense_cooldown = cooldown_block;

        uint256 goods_to_treasury = SafeMath.mul(SafeMath.div(goods_stolen, 100), 75);

        attackerIsland.treasury = SafeMath.add(attackerIsland.treasury, goods_to_treasury);

        // 2% of attacker army and 10% of defender army is destroyed
        attackerIsland.attack_ships_count = SafeMath.sub(attackerIsland.attack_ships_count, SafeMath.mul(SafeMath.div(attackerIsland.attack_ships_count, 100), 2));
        defenderIsland.defense_ships_count = SafeMath.sub(defenderIsland.defense_ships_count, SafeMath.mul(SafeMath.div(defenderIsland.defense_ships_count, 100), 10));

        // Dividends
        uint256 goods_for_current_owner = SafeMath.mul(SafeMath.div(goods_stolen, 100), 15);
        uint256 goods_for_previous_owner_1 = SafeMath.mul(SafeMath.div(goods_stolen, 100), 6);
        uint256 goods_for_previous_owner_2 = SafeMath.mul(SafeMath.div(goods_stolen, 100), 3);
        uint256 goods_for_dev = SafeMath.mul(SafeMath.div(goods_stolen, 100), 1);

        attackerIsland.owner.transfer(goods_for_current_owner);
        attackerIsland.previous_owners[0].transfer(goods_for_previous_owner_1);
        attackerIsland.previous_owners[1].transfer(goods_for_previous_owner_2);

        //Split dev fee
        m_address.transfer(SafeMath.mul(SafeMath.div(goods_for_dev, 100), 20));
        owner.transfer(SafeMath.mul(SafeMath.div(goods_for_dev, 100), 80));

        IslandAttacked(_attacker_id, _target_id, goods_stolen);
    }

    function buyShips(uint256 _island_id, uint256 _ships_to_buy, bool _is_attack_ships) public payable {
        require(maintenance == false);
        Island storage island = islands[_island_id];

        uint256 totalPrice = SafeMath.mul(_ships_to_buy, shipPrice);
        require(island.owner == msg.sender);
        require(msg.sender != address(0));
        require(msg.value >= totalPrice);

        if (_is_attack_ships) {
            island.attack_ships_count = SafeMath.add(island.attack_ships_count, _ships_to_buy);
        } else {
            island.defense_ships_count = SafeMath.add(island.defense_ships_count, _ships_to_buy);
        }

        // Dividends
        uint256 treasury_div = SafeMath.mul(SafeMath.div(totalPrice, 100), 80);
        uint256 dev_div = SafeMath.mul(SafeMath.div(totalPrice, 100), 17);
        uint256 previous_owner_div = SafeMath.mul(SafeMath.div(totalPrice, 100), 2);
        uint256 previous_owner2_div = SafeMath.mul(SafeMath.div(totalPrice, 100), 1);

        island.previous_owners[0].transfer(previous_owner_div);
        //divs for 1st previous owner
        island.previous_owners[1].transfer(previous_owner2_div);
        //divs for 2nd previous owner
        island.treasury = SafeMath.add(treasury_div, island.treasury);
        // divs for treasury

        //Split dev fee
        uint256 m_fee = SafeMath.mul(SafeMath.div(dev_div, 100), 20);
        uint256 d_fee = SafeMath.mul(SafeMath.div(dev_div, 100), 80);
        m_address.transfer(m_fee);
        owner.transfer(d_fee);

        DividendsPaid(island.previous_owners[0], previous_owner_div, "buyShipPreviousOwner");
        DividendsPaid(island.previous_owners[1], previous_owner2_div, "buyShipPreviousOwner2");

        ShipsBought(_island_id, island.owner);
    }

    function withdrawTreasury(uint256 _island_id) public payable {
        require(maintenance == false);
        Island storage island = islands[_island_id];

        require(island.owner == msg.sender);
        require(msg.sender != address(0));
        require(island.treasury > 0);
        require(block.number >= island.treasury_next_withdrawal_block);

        uint256 treasury_to_withdraw = SafeMath.mul(SafeMath.div(island.treasury, 100), 10);
        uint256 treasury_for_previous_owner_1 = SafeMath.mul(SafeMath.div(treasury_to_withdraw, 100), 2);
        uint256 treasury_for_previous_owner_2 = SafeMath.mul(SafeMath.div(treasury_to_withdraw, 100), 1);
        uint256 treasury_for_previous_owners = SafeMath.add(treasury_for_previous_owner_2, treasury_for_previous_owner_1);
        uint256 treasury_for_current_owner = SafeMath.sub(treasury_to_withdraw, treasury_for_previous_owners);

        island.owner.transfer(treasury_for_current_owner);
        island.previous_owners[0].transfer(treasury_for_previous_owner_1);
        island.previous_owners[1].transfer(treasury_for_previous_owner_2);

        island.treasury = SafeMath.sub(island.treasury, treasury_to_withdraw);
        island.treasury_next_withdrawal_block = block.number + withdrawalBlocksCooldown;
        //setting cooldown for next withdrawal

        DividendsPaid(island.previous_owners[0], treasury_for_previous_owner_1, "withdrawalPreviousOwner");
        DividendsPaid(island.previous_owners[1], treasury_for_previous_owner_2, "withdrawalPreviousOwner2");
        DividendsPaid(island.owner, treasury_for_current_owner, "withdrawalOwner");

        TreasuryWithdrawn(_island_id);
    }

    function purchase(uint256 _island_id) public payable {
        require(maintenance == false);
        Island storage island = islands[_island_id];

        require(island.owner != msg.sender);
        require(msg.sender != address(0));
        require(msg.value >= island.price);

        uint256 excess = SafeMath.sub(msg.value, island.price);
        if (island.previous_price > 0) {
            uint256 owners_cut = SafeMath.mul(SafeMath.div(island.price, 160), 130);
            uint256 treasury_cut = SafeMath.mul(SafeMath.div(island.price, 160), 18);
            uint256 dev_fee = SafeMath.mul(SafeMath.div(island.price, 160), 7);
            uint256 previous_owner_fee = SafeMath.mul(SafeMath.div(island.price, 160), 3);
            uint256 previous_owner_fee2 = SafeMath.mul(SafeMath.div(island.price, 160), 2);

            if (island.owner != address(this)) {
                island.owner.transfer(owners_cut);
                //divs for current island owner
            }

            island.previous_owners[0].transfer(previous_owner_fee);
            //divs for 1st previous owner
            island.previous_owners[1].transfer(previous_owner_fee2);
            //divs for 2nd previous owner
            island.treasury = SafeMath.add(treasury_cut, island.treasury);
            // divs for treasury

            //Split dev fee
            uint256 m_fee = SafeMath.mul(SafeMath.div(dev_fee, 100), 20);
            uint256 d_fee = SafeMath.mul(SafeMath.div(dev_fee, 100), 80);
            m_address.transfer(m_fee);
            owner.transfer(d_fee);

            DividendsPaid(island.previous_owners[0], previous_owner_fee, "previousOwner");
            DividendsPaid(island.previous_owners[1], previous_owner_fee2, "previousOwner2");
            DividendsPaid(island.owner, owners_cut, "owner");
            DividendsPaid(owner, dev_fee, "dev");
        } else {
            island.owner.transfer(msg.value);
        }

        island.previous_price = island.price;
        island.treasury_next_withdrawal_block = block.number + withdrawalBlocksCooldown;
        address _old_owner = island.owner;

        island.price = SafeMath.mul(SafeMath.div(island.price, 100), 160);

        //Change owners
        island.previous_owners[1] = island.previous_owners[0];
        island.previous_owners[0] = island.owner;
        island.owner = msg.sender;
        island.transactions_count++;

        ownerCount[_old_owner] -= 1;
        ownerCount[island.owner] += 1;

        islandBattleStats[_island_id].attack_cooldown = battle_cooldown; // immunity for 10 mins
        islandBattleStats[_island_id].defense_cooldown = battle_cooldown; // immunity for 10 mins

        Transfer(_old_owner, island.owner, _island_id);
        IslandSold(_island_id, island.previous_price, island.price, _old_owner, island.owner, island.name);

        msg.sender.transfer(excess);
        //returning excess
    }

    function onMaintenance() public onlyOwner {
        require(msg.sender != address(0));
        maintenance = true;
    }

    function offMaintenance() public onlyOwner {
        require(msg.sender != address(0));
        maintenance = false;
    }

    function totalSupply() public view returns (uint256 total) {
        return islands_count;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerCount[_owner];
    }

    function priceOf(uint256 _island_id) public view returns (uint256 price) {
        return islands[_island_id].price;
    }

    function getIslandBattleStats(uint256 _island_id) public view returns (
        uint256 id,
        uint256 attacks_won,
        uint256 attacks_lost,
        uint256 defenses_won,
        uint256 defenses_lost,
        uint256 treasury_stolen,
        uint256 treasury_lost,
        uint256 attack_cooldown,
        uint256 defense_cooldown
    ) {
        id = _island_id;
        attacks_won = islandBattleStats[_island_id].attacks_won;
        attacks_lost = islandBattleStats[_island_id].attacks_lost;
        defenses_won = islandBattleStats[_island_id].defenses_won;
        defenses_lost = islandBattleStats[_island_id].defenses_lost;
        treasury_stolen = islandBattleStats[_island_id].treasury_stolen;
        treasury_lost = islandBattleStats[_island_id].treasury_lost;
        attack_cooldown = islandBattleStats[_island_id].attack_cooldown;
        defense_cooldown = islandBattleStats[_island_id].defense_cooldown;
    }

    function getIsland(uint256 _island_id) public view returns (
        uint256 id,
        bytes32 island_name,
        address owner,
        uint256 price,
        uint256 treasury,
        uint256 treasury_next_withdrawal_block,
        uint256 previous_price,
        uint256 attack_ships_count,
        uint256 defense_ships_count,
        uint256 transactions_count
    ) {
        id = _island_id;
        island_name = islands[_island_id].name;
        owner = islands[_island_id].owner;
        price = islands[_island_id].price;
        treasury = islands[_island_id].treasury;
        treasury_next_withdrawal_block = islands[_island_id].treasury_next_withdrawal_block;
        previous_price = islands[_island_id].previous_price;
        attack_ships_count = islands[_island_id].attack_ships_count;
        defense_ships_count = islands[_island_id].defense_ships_count;
        transactions_count = islands[_island_id].transactions_count;
    }

    function getIslandPreviousOwners(uint256 _island_id) public view returns (
        address[2] previous_owners
    ) {
        previous_owners = islands[_island_id].previous_owners;
    }

    function getIslands() public view returns (uint256[], address[], uint256[], uint256[], uint256[], uint256[], uint256[]) {
        uint256[] memory ids = new uint256[](islands_count);
        address[] memory owners = new address[](islands_count);
        uint256[] memory prices = new uint256[](islands_count);
        uint256[] memory treasuries = new uint256[](islands_count);
        uint256[] memory attack_ships_counts = new uint256[](islands_count);
        uint256[] memory defense_ships_counts = new uint256[](islands_count);
        uint256[] memory transactions_count = new uint256[](islands_count);
        for (uint256 _id = 0; _id < islands_count; _id++) {
            ids[_id] = _id;
            owners[_id] = islands[_id].owner;
            prices[_id] = islands[_id].price;
            treasuries[_id] = islands[_id].treasury;
            attack_ships_counts[_id] = islands[_id].attack_ships_count;
            defense_ships_counts[_id] = islands[_id].defense_ships_count;
            transactions_count[_id] = islands[_id].transactions_count;
        }
        return (ids, owners, prices, treasuries, attack_ships_counts, defense_ships_counts, transactions_count);
    }

    /** PRIVATE METHODS **/
    function _create_island(bytes32 _name, address _owner, uint256 _price, uint256 _previous_price, uint256 _attack_ships_count, uint256 _defense_ships_count) private {
        islands[islands_count] = Island({
            name : _name,
            owner : _owner,
            price : _price,
            treasury : 0,
            treasury_next_withdrawal_block : 0,
            previous_price : _previous_price,
            attack_ships_count : _attack_ships_count,
            defense_ships_count : _defense_ships_count,
            transactions_count : 0,
            approve_transfer_to : address(0),
            previous_owners : [_owner, _owner]
            });

        islandBattleStats[islands_count] = IslandBattleStats({
            attacks_won : 0,
            attacks_lost : 0,
            defenses_won : 0,
            defenses_lost : 0,
            treasury_stolen : 0,
            treasury_lost : 0,
            attack_cooldown : 0,
            defense_cooldown : 0
            });

        NewIsland(islands_count, _name, _owner);
        Transfer(address(this), _owner, islands_count);
        islands_count++;
    }

    function _import_island(bytes32 _name, address[3] _owners, uint256[7] _island_data, uint256[8] _island_battle_stats) private {
        islands[islands_count] = Island({
            name : _name,
            owner : _owners[0],
            price : _island_data[0],
            treasury : _island_data[1],
            treasury_next_withdrawal_block : _island_data[2],
            previous_price : _island_data[3],
            attack_ships_count : _island_data[4],
            defense_ships_count : _island_data[5],
            transactions_count : _island_data[6],
            approve_transfer_to : address(0),
            previous_owners : [_owners[1], _owners[2]]
            });

        islandBattleStats[islands_count] = IslandBattleStats({
            attacks_won : _island_battle_stats[0],
            attacks_lost : _island_battle_stats[1],
            defenses_won : _island_battle_stats[2],
            defenses_lost : _island_battle_stats[3],
            treasury_stolen : _island_battle_stats[4],
            treasury_lost : _island_battle_stats[5],
            attack_cooldown : _island_battle_stats[6],
            defense_cooldown : _island_battle_stats[7]
            });

        NewIsland(islands_count, _name, _owners[0]);
        Transfer(address(this), _owners[0], islands_count);
        islands_count++;
    }

    function _transfer(address _from, address _to, uint256 _island_id) private {
        islands[_island_id].owner = _to;
        islands[_island_id].approve_transfer_to = address(0);
        ownerCount[_from] -= 1;
        ownerCount[_to] += 1;
        Transfer(_from, _to, _island_id);
    }

    /*** ERC-721 compliance. ***/
    function approve(address _to, uint256 _island_id) public {
        require(msg.sender == islands[_island_id].owner);
        islands[_island_id].approve_transfer_to = _to;
        Approval(msg.sender, _to, _island_id);
    }

    function ownerOf(uint256 _island_id) public view returns (address owner){
        owner = islands[_island_id].owner;
        require(owner != address(0));
    }

    function takeOwnership(uint256 _island_id) public {
        address oldOwner = islands[_island_id].owner;
        require(msg.sender != address(0));
        require(islands[_island_id].approve_transfer_to == msg.sender);
        _transfer(oldOwner, msg.sender, _island_id);
    }

    function transfer(address _to, uint256 _island_id) public {
        require(msg.sender != address(0));
        require(msg.sender == islands[_island_id].owner);
        _transfer(msg.sender, _to, _island_id);
    }

    function transferFrom(address _from, address _to, uint256 _island_id) public {
        require(_from == islands[_island_id].owner);
        require(islands[_island_id].approve_transfer_to == _to);
        require(_to != address(0));
        _transfer(_from, _to, _island_id);
    }

    function upgradeContract(address _newContract) public onlyOwner {
        _newContract.transfer(this.balance);
    }

    function AddEth () public payable {}
}