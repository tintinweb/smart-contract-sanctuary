/**
 *Submitted for verification at snowtrace.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/ISpirit.sol


// ERC-721 Smart Contract for the Avax Ghost NFT Collection - https://avaxghost.com

//     ___             __    _____   ______   ___      __         
//    / _ \           / /   | ____| |____  | |__ \    / /         
//   | | | | __  __  / /_   | |__       / /     ) |  / /_     ___ 
//   | | | | \ \/ / | '_ \  |___ \     / /     / /  | '_ \   / _ \
//   | |_| |  >  <  | (_) |  ___) |   / /     / /_  | (_) | |  __/
//    \___/  /_/\_\  \___/  |____/   /_/     |____|  \___/   \___|
//                                                                
//    

pragma solidity 0.8.10;

interface ISpirit {
    function mint(address owner, uint256 amount) external;
    function burn(address owner, uint256 amount) external payable;
    function balanceOf(address owner) external view returns(uint256);
}
// File: contracts/interfaces/IGraveyard.sol


// ERC-721 Smart Contract for the Avax Ghost NFT Collection - https://avaxghost.com

//     ___             __    _____   ______   ___      __         
//    / _ \           / /   | ____| |____  | |__ \    / /         
//   | | | | __  __  / /_   | |__       / /     ) |  / /_     ___ 
//   | | | | \ \/ / | '_ \  |___ \     / /     / /  | '_ \   / _ \
//   | |_| |  >  <  | (_) |  ___) |   / /     / /_  | (_) | |  __/
//    \___/  /_/\_\  \___/  |____/   /_/     |____|  \___/   \___|
//                                                                
//    

pragma solidity 0.8.10;

interface IGraveyard {
    function createGraveyard(address owner) external;
}
// File: contracts/interfaces/IAvaxGhost.sol


// ERC-721 Smart Contract for the Avax Ghost NFT Collection - https://avaxghost.com

//     ___             __    _____   ______   ___      __         
//    / _ \           / /   | ____| |____  | |__ \    / /         
//   | | | | __  __  / /_   | |__       / /     ) |  / /_     ___ 
//   | | | | \ \/ / | '_ \  |___ \     / /     / /  | '_ \   / _ \
//   | |_| |  >  <  | (_) |  ___) |   / /     / /_  | (_) | |  __/
//    \___/  /_/\_\  \___/  |____/   /_/     |____|  \___/   \___|
//                                                                
//    

pragma solidity 0.8.10;

interface IAvaxGhost {
    function stakingBonus(address owner) external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/GraveDigger.sol


// ERC-721 Smart Contract for the Avax Ghost NFT Collection - https://avaxghost.com

//     ___             __    _____   ______   ___      __         
//    / _ \           / /   | ____| |____  | |__ \    / /         
//   | | | | __  __  / /_   | |__       / /     ) |  / /_     ___ 
//   | | | | \ \/ / | '_ \  |___ \     / /     / /  | '_ \   / _ \
//   | |_| |  >  <  | (_) |  ___) |   / /     / /_  | (_) | |  __/
//    \___/  /_/\_\  \___/  |____/   /_/     |____|  \___/   \___|
//                                                                
//                                                                

pragma solidity 0.8.10;





/* A 'GraveDigger' who is only allowed 
 * to take actions related with graveyard
 * and spirits. He prefers to define himself
 * as a night-bringer.
 * He is also raged to whom are in PURGATORY and
 * carries them to the theirs end.
 */
contract GraveDigger is Ownable {
    
    enum Team { PURGATORY, PURPLE, GREEN }

    struct Player {
        Team team;
        uint8 graveyardLevel;
        uint256 score;
        uint256 lastHarvestTimestamp;
        address account;
    }
    
    mapping(address => Player) private players;
    
    Player[] private scoreboard;
    
    IAvaxGhost private avaxGhost;
    
    IGraveyard private graveyard;
    
    ISpirit private spirit;
    
    bool public changeSideEnabled = false;
    
    uint8 public graveyardLevelCap = 13;

    uint256 public sideChangeCostEther = 4 ether;
    
    uint256 public sideChangeCostSpirit = 4000 ether;
    
    uint256 public baseStakingAmount = 0.0001 ether;
    
    uint8 public purpleTeamStakingMultipler = 1;
    
    uint8 public greenTeamStakingMultipler = 1;
    
    event DiggerReady(address indexed _from, Team _team);
    event Harvest(address indexed _from, uint256 _amount);
    event LevelUp(address indexed _from, uint8 _value);
    event TeamChanged(address indexed _from, Team _team);
    
    constructor(address _avaxGhost, address _graveyard, address _spirit) {
        avaxGhost = IAvaxGhost(_avaxGhost);
        graveyard = IGraveyard(_graveyard);
        spirit = ISpirit(_spirit);
    }
    
    function constructGraveyard(Team team) external {
        
        require(team == Team.PURPLE || team == Team.GREEN, "Invalid team");
        
        address owner = msg.sender;
        
        uint256 avaxGhostBalance = avaxGhost.balanceOf(owner);
        
        require(avaxGhostBalance > 0, "Need to mint AVAXGHOST first!");
        
        require(players[owner].graveyardLevel <= 0, "Graveyard already constructed");
        
        graveyard.createGraveyard(owner);
        
        players[owner].team = team;
        
        players[owner].graveyardLevel = 1;
        
        players[owner].lastHarvestTimestamp = block.timestamp;

        players[owner].account = owner;
    
        scoreboard.push(players[owner]);
    
        emit DiggerReady(owner, team);
        
    }

    function harvest() external {
        
        address owner = msg.sender;

        uint256 amount = harvestAmount(owner);
        
        require(amount > 0, "Nothing to harvest");
        
        spirit.mint(owner, amount);
        
        players[owner].lastHarvestTimestamp = block.timestamp;
        
        players[owner].score += amount;
        
        updateScoreboard(players[owner]);
        
        emit Harvest(owner, amount);
        
    }

    function levelUp() external {
    
        address owner = msg.sender;
        
        uint8 currentLevel = players[owner].graveyardLevel;

        require(currentLevel > 0, "Graveyard is not constructed");
        require(currentLevel < graveyardLevelCap, "Graveyard max level reached");
        
        uint256 levelUpSpirits = graveyardLevelUpCost(owner);
        
        uint256 spiritsBalance = spirit.balanceOf(owner);
        
        require(levelUpSpirits <= spiritsBalance, "Not enough spirit");
        
        spirit.burn(owner, levelUpSpirits);

        uint8 newLevel = currentLevel + 1;
        
        players[owner].graveyardLevel = newLevel;

        players[owner].score = spiritsBalance - levelUpSpirits;
        
        updateScoreboard(players[owner]);

        emit LevelUp(owner, newLevel);
        
    }

    function changeTeam(Team team) external payable {

        require(changeSideEnabled, "Changing is not enabled yet!");

        address owner = msg.sender;
        
        require(teamOf(owner) != team, "Already in team");
        
        if(msg.value > 0) {

            require(msg.value >= sideChangeCostEther, "Insufficient fee");

        } else {

            uint256 spiritsBalance = spirit.balanceOf(owner);
            
            require(sideChangeCostSpirit <= spiritsBalance, "Not enough spirit");
            
            spirit.burn(owner, sideChangeCostSpirit);

            players[owner].score = spiritsBalance - sideChangeCostSpirit;
            
        }

        players[owner].team = team;

        updateScoreboard(players[owner]);

        emit TeamChanged(owner, team);

    }
    
    function updateScoreboard(Player memory player) private {
        
        uint256 scoreboardLength = scoreboard.length;
        
        if(scoreboardLength == 0) {
            // No need to update anything at!
            return;
        }

        for(uint256 i; i < scoreboardLength; i++) {
            if(scoreboard[i].account == player.account) {
                scoreboard[i] = player;
                return;
            }
        }
        
    }

    function getScoreboard() external view returns(Player[] memory) {
        return scoreboard;
    }
    
    function graveyardLevelOf(address owner) public view returns(uint) {
        return players[owner].graveyardLevel;
    }
    
    function harvestTimestampOf(address owner) public view returns(uint256) {
        return players[owner].lastHarvestTimestamp;
    }

    function teamOf(address owner) public view returns(Team) {
        return players[owner].team;
    }
    
    function harvestAmount(address owner) public view returns(uint256) {

        uint256 stakingBonus = avaxGhost.stakingBonus(owner);

        uint8 teamBonus = 1;
        
        Team team = teamOf(owner);
        
        if(team == Team.PURPLE) {
            teamBonus = purpleTeamStakingMultipler;
        } else if(team == Team.GREEN) {
            teamBonus = greenTeamStakingMultipler;
        }

        return (block.timestamp - harvestTimestampOf(owner)) * (baseStakingAmount + stakingBonus) * graveyardLevelOf(owner) * teamBonus;

    }
    
    function graveyardLevelUpCost(address owner) public view returns(uint256) {
        return (4 ** graveyardLevelOf(owner)) * 1 ether;
    }

    function setLevelCap(uint8 _levelCap) external onlyOwner {
        require(_levelCap > graveyardLevelCap, "New level cap cannot be lower than the current");
        graveyardLevelCap = _levelCap;
    }

    function setChangeSideCostSpirit(uint256 _sideChangeCostSpirit) external onlyOwner {
        require(_sideChangeCostSpirit >= 0, "The cost of changing side cannot be negative");
        sideChangeCostSpirit = _sideChangeCostSpirit;
    }

    function setSideChangeCostEther(uint256 _sideChangeCostEther) external onlyOwner {
        require(_sideChangeCostEther >= 0, "The cost of changing side quickly cannot be negative");
        sideChangeCostEther = _sideChangeCostEther;
    }
    
    function setBaseStakingAmount(uint256 _baseStakingAmount) external onlyOwner {
        require(_baseStakingAmount >= 0, "The base staking amount cannot be negative");
        baseStakingAmount = _baseStakingAmount;
    }
    
    function setPurpleTeamStakingMultiplier(uint8 _purpleTeamStakingMultiplier) external onlyOwner {
        require(_purpleTeamStakingMultiplier >= 0, "The base staking amount cannot be negative");
        purpleTeamStakingMultipler = _purpleTeamStakingMultiplier;
    }
    
    function setGreenTeamStakingMultiplier(uint8 _greenTeamStakingMultiplier) external onlyOwner {
        require(_greenTeamStakingMultiplier >= 0, "The base staking amount cannot be negative");
        greenTeamStakingMultipler = _greenTeamStakingMultiplier;
    }
    
    function setAvaxGhost(address _avaxGhost) external onlyOwner {
        require(_avaxGhost != address(0), "0x0 Forbidden");
        avaxGhost = IAvaxGhost(_avaxGhost);
    }
    
    function setGraveyard(address _graveyard) external onlyOwner {
        require(_graveyard != address(0), "0x0 Forbidden");
        graveyard = IGraveyard(_graveyard);
    }
    
    function setSpirit(address _spirit) external onlyOwner {
        require(_spirit != address(0), "0x0 Forbidden");
        spirit = ISpirit(_spirit);
    }
    
    function enableChangeSide() external onlyOwner {
        changeSideEnabled = true;
    }
    
    function disableChangeSide() external onlyOwner {
        changeSideEnabled = false;
    }
    
    function withdraw() external payable onlyOwner {

        uint256 balance = address(this).balance;

        require(balance > 0, "Nothing to withdraw");
        
        payable(msg.sender).transfer(balance);

    }
    
}