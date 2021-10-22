/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol



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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// File: @openzeppelin/contracts/utils/Context.sol



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
}

// File: GLAMarket.sol


pragma solidity ^0.8.0;



contract GLAMarket is Ownable, Initializable {
    using SafeMath for uint256;
    
    uint8 public marketFee;
    uint8 public maxFee;

    address public gameManager;

    mapping (uint256 => address) public heroOwners; // heroid to owner  
    mapping (uint256 => uint256) public heroPrices; // heroid to hero price
    
    // Mapping from owner to list of owned hero IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedHeroes;
    // Mapping from hero ID to index of the owner heroes list
    mapping(uint256 => uint256) private _listedHeroesIndex;
    mapping(address => uint256) private heroesSalesOf;
    uint256 private totalNFTOnSale;

    event List(uint256 indexed heroId_, address owner_, uint256 price_);
    event Delist(uint256 indexed heroId_);
    event Purchase(address buyer_, uint256 indexed heroId_, uint256 price_);
    event ChangePrice(uint256 indexed heroId, uint256 newPrice);
    modifier only(string memory necessaryContract ) {
        require(IGameManager(gameManager).getContract(necessaryContract) == msg.sender, "not authorized");
        _;
    }

    modifier onlyGameManager {
        require(gameManager == msg.sender, "not authorized");
        _;
    }

    function initialize(address gameManager_) public initializer{
        gameManager = gameManager_; 
        marketFee = 5; // percent
        maxFee = 10;
    }

    // User has to `approve` to allow this contract to trasfer their NFTs
    function listOnMarket(uint256 heroId_, uint256 price_) public {
        address heroContract = IGameManager(gameManager).getContract("GLAHeroNFT");
        address owner_ = IGLAHeroNFT(heroContract).ownerOf(heroId_);
        require(msg.sender == owner_, "You not own this hero");
        IGLAHeroNFT(heroContract).transferFrom(owner_, address(this), heroId_);
        totalNFTOnSale+=1;
        heroOwners[heroId_] = owner_;
        heroPrices[heroId_] = price_;
        _ownedHeroes[owner_][heroesSalesOf[owner_]] = heroId_;
        _listedHeroesIndex[heroId_] = heroesSalesOf[owner_];
        heroesSalesOf[owner_]+=1;
        emit List(heroId_, owner_, price_);
    }

    // User can delist their NFT from the Market
    function delistAndWithdraw(uint256 heroId_) public {
        require(msg.sender == heroOwners[heroId_], "You are not the NFT owner!");
        _withdraw(heroId_);
        _delist(heroId_);
  }

    // Buy heroes of other users on the market
    function purchaseHero(uint256 heroId_) public {
        require(heroOwners[heroId_] != address(0), "This character not on sales");
        address GLATokenContract = IGameManager(gameManager).getContract("GLAToken");
        address devWallet = IGameManager(gameManager).getDevWallet();
        address heroContract = IGameManager(gameManager).getContract("GLAHeroNFT");
        
        uint256 realPrice = heroPrices[heroId_].mul(10**18); // Price in GLA
        uint256 fee = realPrice.mul(marketFee).div(100);
        uint256 ftReceive = realPrice.sub(fee); // Actual GLA received by the seller
        
        // Transfer GLA to the seller
        require(IGLAToken(GLATokenContract).transferFrom(msg.sender, heroOwners[heroId_], ftReceive) == true, "Purchase error");
        
        // Transfer transaction fee to dev wallet
        IGLAToken(GLATokenContract).transferFrom(msg.sender, devWallet, fee);
        emit Purchase(msg.sender, heroId_, heroPrices[heroId_]);
        _delist(heroId_);

        // Transfer NFT to the buyer
        IGLAHeroNFT(heroContract).transferFrom(address(this), msg.sender, heroId_);

    }
    
    function getAmountHeroOf(address owner) public view returns(uint256){
        return heroesSalesOf[owner];
    }
    
    function getTotalHeroOnSales() public view returns(uint256){
        return totalNFTOnSale;
    }
    
    function heroOfOwnerByIndex(address owner, uint256 index) public view  returns (uint256) {
        require(index < heroesSalesOf[owner], "owner index out of bounds");
        return _ownedHeroes[owner][index];
    }
    
    function getListHeroesOf(address owner) public view returns(HeroOnSales[] memory){
        address heroNFT = IGameManager(gameManager).getContract("GLAHeroNFT");
        uint256 totalHero = getAmountHeroOf(owner);
        HeroOnSales[] memory listHeroOnSales = new HeroOnSales[](totalHero);
        for (uint i=0; i<totalHero; i++){
            uint256 heroId_ = heroOfOwnerByIndex(owner, i);
            listHeroOnSales[i]=HeroOnSales(IGLAHeroNFT(heroNFT).getHero(heroId_), heroPrices[heroId_]);
        }
        return listHeroOnSales;
    }
    
    // Get list heroes to display on Frontend, 10 heroes/page
    // Page starts from 0
    function getHeroesPage(uint256 page_) public view returns(HeroOnSales[] memory){
        address heroNFT = IGameManager(gameManager).getContract("GLAHeroNFT");
        Hero[] memory listAllHeroesMarket = IGLAHeroNFT(heroNFT).getListHeroesOf(address(this));
        require(listAllHeroesMarket.length > page_*10 ,"Out of bounds");
        uint256 stop = listAllHeroesMarket.length - 10 * page_;
        uint256 start = 0;
        uint256 count =0;
        if (listAllHeroesMarket.length > (page_+1)*10)
            start = listAllHeroesMarket.length - (page_+1)*10;
        HeroOnSales[] memory heroesPage = new HeroOnSales[](stop - start);
        for(uint256 i = start; i<stop; i++){
            heroesPage[count] = HeroOnSales(listAllHeroesMarket[i], heroPrices[listAllHeroesMarket[i].heroId]);
            count++;
        }
        return heroesPage;
    }
    
    function getHeroPrice(uint256 heroId_) public view returns(uint256){
        return heroPrices[heroId_];
    }
    
    function setHeroPrice(uint256 heroId_, uint256 price_) public {
        require(msg.sender == heroOwners[heroId_], "You are not the NFT owner!");
        heroPrices[heroId_] = price_;
        emit ChangePrice(heroId_, price_);
    }
    
    function _delist(uint256 heroId_) internal {
        totalNFTOnSale--;
        address currentOwner = heroOwners[heroId_];
        heroOwners[heroId_] = address(0);
        heroPrices[heroId_] = 0;
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastHeroIndex = heroesSalesOf[currentOwner] - 1;
        heroesSalesOf[currentOwner]-=1;
        uint256 heroIndex = _listedHeroesIndex[heroId_];

        // When the token to be deleted is the last token, the swap operation is unnecessary
        if (heroIndex != lastHeroIndex) {
            uint256 lastHeroId = _ownedHeroes[currentOwner][lastHeroIndex];

            _ownedHeroes[currentOwner][heroIndex] = lastHeroId; // Move the last token to the slot of the to-delete token
            _listedHeroesIndex[lastHeroId] = heroIndex; // Update the moved token's index
        }
        // This also deletes the contents at the last position of the array
        delete _listedHeroesIndex[heroId_];
        delete _ownedHeroes[currentOwner][lastHeroIndex];
        
        emit Delist(heroId_);
    }

    function _withdraw(uint256 heroId_) internal {
        address heroContract = IGameManager(gameManager).getContract("GLAHeroNFT");
        IGLAHeroNFT(heroContract).transferFrom(address(this), heroOwners[heroId_], heroId_);
    }
  
    function setFee(uint8 fee) external onlyGameManager {
        if (fee > maxFee){
          marketFee = maxFee;
        } else {
          marketFee = fee;
        }
    }

    function setManagerContract(address manager) public onlyOwner {
        gameManager = manager;
    }

}

interface IGameManager{
    function  getContract(string memory contract_) external view returns (address);
    function  getDevWallet() external view returns (address);
}

interface IGLAHeroNFT{
    function mint (address owner, uint heroType, uint8 rarity) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function getHero(uint256 heroId_) external view returns(Hero memory);
    function getListHeroesOf(address owner) external view returns(Hero[] memory);
    function getListHeroIdsOf(address owner) external view returns(uint256[] memory);
}

interface IGLAToken{
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

    struct Hero {
        uint256 heroId;
        uint types;
        string name;
        uint8 rarity;
        uint8 level;
        uint256 experience;    
        uint256 lastBattleTime;
    }
    
    struct HeroOnSales{
    Hero hero;
    uint256 price;
    }