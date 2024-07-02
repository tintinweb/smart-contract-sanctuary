/**
 *Submitted for verification at cronoscan.com on 2022-05-24
*/

/**
 *Submitted for verification at testnet.cronoscan.com on 2022-05-24
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/3_Ballot.sol



pragma solidity 0.8.13;


contract Steakhouse is Ownable {

    uint256 private EGGS_TO_HATCH_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 3;
    bool private initialized = false;
    address payable private recAdd;
    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedSteak;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    uint256 private marketSteak;
    
    constructor() {
        recAdd = payable(msg.sender);
    }
    
    function reGrill(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMySteak(msg.sender);
        uint256 newMiners = eggsUsed / EGGS_TO_HATCH_1MINERS;
        hatcheryMiners[msg.sender] = hatcheryMiners[msg.sender] + newMiners;
        claimedSteak[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral eggs
        claimedSteak[referrals[msg.sender]] = claimedSteak[referrals[msg.sender]] + eggsUsed/8;
        
        //boost market to nerf miners hoarding
        marketSteak=marketSteak + eggsUsed / 5;
    }
    
    function eatSteak() public {
        require(initialized);
        uint256 hasEggs = getMySteak(msg.sender);
        uint256 eggValue = calculateSteakSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedSteak[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketSteak = marketSteak + hasEggs;
        recAdd.transfer(fee);
        payable (msg.sender).transfer(eggValue - fee);
    }
    
    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasEggs = getMySteak(adr);
        uint256 eggValue = calculateSteakSell(hasEggs);
        return eggValue;
    }
    
    function grillSteak(address ref) public payable {
        require(initialized);
        uint256 eggsBought = calculateSteakBuy(msg.value, address(this).balance - msg.value);
        eggsBought = eggsBought - devFee(eggsBought);
        uint256 fee = devFee(msg.value);
        recAdd.transfer(fee);
        claimedSteak[msg.sender] = claimedSteak[msg.sender] + eggsBought;
        reGrill(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return (PSN * bs) / (PSNH + (((PSN*rs) + (PSNH*rt)) / rt));
    }
    
    function calculateSteakSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketSteak,address(this).balance);
    }
    
    function calculateSteakBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketSteak);
    }
    
    function calculateSteakBuySimple(uint256 eth) public view returns(uint256) {
        return calculateSteakBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return amount*devFeeVal/100;
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketSteak == 0);
        initialized = true;
        marketSteak = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMySteak(address adr) public view returns(uint256) {
        return claimedSteak[adr] + getSteakSinceLastHatch(adr);
    }
    
    function getSteakSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS, block.timestamp - lastHatch[adr]);
        return secondsPassed * hatcheryMiners[adr];
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}