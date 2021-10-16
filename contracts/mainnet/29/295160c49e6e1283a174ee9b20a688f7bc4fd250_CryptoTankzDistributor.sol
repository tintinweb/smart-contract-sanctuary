/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

/**
      ______     ______     __  __     ______   ______   ______    
     /\  ___\   /\  == \   /\ \_\ \   /\  == \ /\__  _\ /\  __ \   
     \ \ \____  \ \  __<   \ \____ \  \ \  _-/ \/_/\ \/ \ \ \/\ \  
      \ \_____\  \ \_\ \_\  \/\_____\  \ \_\      \ \_\  \ \_____\ 
       \/_____/   \/_/ /_/   \/_____/   \/_/       \/_/   \/_____/ 
            ______   ______     __   __     __  __     ______      
           /\__  _\ /\  __ \   /\ "-.\ \   /\ \/ /    /\___  \     
           \/_/\ \/ \ \  __ \  \ \ \-.  \  \ \  _"-.  \/_/  /__    
              \ \_\  \ \_\ \_\  \ \_\\"\_\  \ \_\ \_\   /\_____\   
               \/_/   \/_/\/_/   \/_/ \/_/   \/_/\/_/   \/_____/   
               
   
    Twitter: https://twitter.com/CryptoTankZ
   
    Gitbook: https://crypto-tankz.gitbook.io/
   
    Telegram: https://t.me/CryptoTankz
   
    Announcemnts: https://t.me/CryptoTankzCH
    
    Website: https://cryptotankz.com



	This is special SmartContract helper for CryptoTankz.
	It provides new player registration to database.
	Special paid game-items tracking.
	Tokens distribution to the winners.
	
	All reward-tokens are locked here. 
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

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
     */
    function allowance(address owner, address spender) external view returns (uint256);
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
  
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
  
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
  
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract ERC20Detailed is IERC20 {
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _decimals = decimals_;
        _name = name_;
        _symbol = symbol_;
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
}

contract OwnableDistributor {
    address internal _owner;
    address internal _distributor;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event newDistributorSet(address indexed previousDistributor, address indexed newDistributor);

    constructor () {
        _distributor = address(0);
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setDistributor(address _address) external onlyOwner {
        require (_distributor == address(0));
        _distributor = _address;
        emit newDistributorSet(address(0), _address);
    }
    
    function distributor() public view returns (address) {
        return _distributor;
    }
    
    modifier onlyDistributor() {
        require(_distributor == msg.sender, "caller is not rewards distributor");
        _;
    }
}

contract CryptoTankzDistributor is OwnableDistributor {
    using SafeMath for uint256;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address uniswapV2router;
    
    // Game rewards conditions setup.
    mapping (address => bool) private playersDatabase;
    uint256 playerRewardLimit;
    event playerAddedToDatabase (address playerAddress, bool isAdded);
    event playerRemovedFromDatabase (address playerAddress, bool isAdded);
    event rewardTransfered(address indexed from, address indexed to, uint256 value);
    
     // Game items database.
    string[] private weapon = [
        "Small Cannon",
        "Large Cannon",
        "Double Cannon",
        "Slow Machine Gun",
        "Fast Machine Gun",
        "Rocket Launcher",
        "Ground Missile",
        "Air Missile",
        "Tracking Missile",
        "Nuclear Missile"
    ];
    string[] private armor = [
        "Metal Helm",
        "War Belt",
        "Anit-Fire Shield",
        "Anti-Missile Shield",
        "Additional Steel Body",
        "Caterpillars Shield",
        "Bulletproof Vest",
        "Engine Protection",
        "Shock Absorbers",
        "Titanium Hatch"
    ];
    string[] private health = [
        "First Aid Kit",
        "Bandages",
        "Painkillers",
        "Food",
        "Water",
        "Repair Kit",
        "Engine Oil",
        "New Battery",
        "New Caterpillars",
        "New Suspension"
    ];
    string[] private upgrade = [
        "Large Caterpillars",
        "Climb Improvement",
        "Engine Booster",
        "Special Fuel",
        "Large Exhaust",
        "Bigger Fuel Tank",
        "Double Fire",
        "Auto Tracking",
        "Wide Radar View",
        "Artifacts Scanner"
    ];
    string[] private artifact = [
        "Gold Ring",
        "Human Bone",
        "Garrison Flag",
        "Rusty Knife",
        "Binoculars",
        "Eagle Plate",
        "Purple Heart Medal",
        "Soldier Dog Tag",
        "Silver Bullet",
        "Lucky Medallion"
    ];
    
    constructor(address router) {
        uniswapV2router = router;
        
        name = "CryptoTankz Distributor";
        symbol = "CTDIST";
        decimals = 9;
        playerRewardLimit = 3000000000000; //maximum amount of reward-tokens for player per game (3000) + decimals (9)
    }
    
    /**
     * @dev Functions to operate game items database.
     */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function gameItemWeapon(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "WEAPON", weapon);
    }
    
    function gameItemArmor(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "ARMOR", armor);
    }
    
    function gameItemHealth(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "HEALTH", health);
    }

    function gameItemUpgrade(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "UPGRADE", upgrade);
    }
    
    function gameItemArtifact(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "ARTIFACT", artifact);
    }
    
    function itemName(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }
     
    function toString(uint256 value) internal pure returns (string memory) {
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
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) internal view returns (uint256) {
        return allowed[_owner][_spender];
    }
  
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        balances[_from] = balances[_from].sub(_value, "ERC20: transfer amount exceeds balance");
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function addNewPlayerToDatabase(address _address) public onlyDistributor {
        playersDatabase[_address] = true;
        emit playerAddedToDatabase (_address, playersDatabase[_address]);
    }

    function removePlayerFromDatabase(address _address) public onlyDistributor {
        playersDatabase[_address] = false;
        emit playerRemovedFromDatabase (_address, playersDatabase[_address]);
    }
        
    function isPlayerInDatabase(address _address) public view returns(bool) {
        return playersDatabase[_address];
    }
    
    // Returns the maximum amount of reward-tokens for the player per one game (decimals (9) are cut here for better clarity)
    function maxRewardPerPlayer() public view returns (uint256) {
        return playerRewardLimit.div(1*10**9);
    }
    
    /**
     * This function allow to send reward-tokens to player, but special conditions must be provided:
     *
     * -the owner must be zero address (completed renouceOwnership is required as first)
     * -function can be called only by Distributor (not by contract owner or player)
     * -distributor cannot send any reward to his own address or owner address.
     * -the player by using another function has to be registered in database first.
     * -amount of each reward-tokens cannot be greater than maximum limit, which is 3000 tokens.
     * -function doesn't generate new tokens. Rewards end when the pool (tokens in the contract) will be empty.
     */
    function claimRewardForWinner(address _address, uint256 _rewardAmount) external onlyDistributor {
        require (owner() == address(0), "renouce owership required. The Owner must be zero address");
        require (_address != _distributor, "distributor cannot send reward to himself");
        require (playersDatabase[_address] == true, "address is not registred in players database");
        require (_rewardAmount <= playerRewardLimit, "amount cannot be higher than limit");
        require (_address != address(0), "zero address not allowed");
        require (_rewardAmount != 0, "amount cannot be zero");
        balances[address(this)] = balances[address(this)].sub(_rewardAmount, "reward pool is empty already");
        balances[_address] = balances[_address].add(_rewardAmount);
        emit rewardTransfered(address(this), _address, _rewardAmount);
    }
}