// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./RewardPool.sol";
import "./BeastNFT.sol";
import "./WarriorNFT.sol";

contract LegionNFT is Context, IERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 public bloodstone;
    IBeastNFT public beast;
    IWarriorNFT public warrior;
    string public _baseURL;
    RewardPool rewardpool;
    address public rewardPoolAddr;
    address ZERO = 0x0000000000000000000000000000000000000000;
    uint256 public supplyPrice = 1;

    uint256 maxBeasts = 10;
    uint256 public itemPrice = 50;
    uint256 public denominator = 100;


    struct Legion {
        string name;
        string imgUrl;
        uint256[] beast_ids;
        uint256[] warrior_ids;
        uint256 supplies;
        uint256 contracts;
        uint256 attack_power;
        uint256 minted_time;
    }
    mapping (uint256 => Legion) tokenData;
    mapping (address => uint256[]) addressTokenIds;

    string private _name;
    string private _symbol;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => uint256) tokenIdIndex;
    
    constructor() {
        _name = "Crypto Legions Game";
        _symbol = "LEGION";
        bloodstone = IERC20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
        rewardpool = new RewardPool();
        rewardPoolAddr = address(rewardpool);
        beast = new BeastNFT(rewardPoolAddr);
        warrior = new WarriorNFT(rewardPoolAddr);
        bloodstone.approve(rewardPoolAddr, 5000000*10**18);
        setBaseURL("https://ipfs.infura.io:5001/api/v0/cat/");
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool){}

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner || isApprovedForAll(owner, msg.sender), "ERC721: approval to current owner");
        require(msg.sender==owner, "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return addressTokenIds[owner].length;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return tokenToOwner[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");
        _approve(address(0), tokenId);

        addressTokenIds[from][tokenIdIndex[tokenId]] = addressTokenIds[from][addressTokenIds[from].length-1];
        tokenIdIndex[addressTokenIds[from][addressTokenIds[from].length-1]] = tokenIdIndex[tokenId];
        addressTokenIds[from].pop();
        tokenToOwner[tokenId] = to;
        
        addressTokenIds[to].push(tokenId);
        tokenIdIndex[tokenId] = addressTokenIds[to].length - 1;
        emit Transfer(from, to, tokenId);
    }

    function mint(uint256[] memory beastIds, uint256[] memory warriorIds) external {
        require(beastIds.length<=maxBeasts, "mint: you should not overflow max beast number");
        require(beastIds.length>0, "mint: you should add beasts");
        uint256 maxCapacity = 0;
        uint256 attack_power = 0;
        uint256 beastCount = beastIds.length;
        uint256 warriorCount = warriorIds.length;
        uint256 bloodstoneAmount = itemPrice.mul(warriorCount+beastCount).div(denominator)*10**18;
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount, "Insufficient payment");
        uint256 capacity = 0;
        for(uint i=0; i<beastCount; i++) {
            require(beast.ownerOf(beastIds[i]) == msg.sender, "mint : you should own these beast tokens");
            (,, capacity,,) = beast.getBeast(beastIds[i]);
            maxCapacity = maxCapacity.add(capacity);
            beast.burn(beastIds[i]);
        }
        require(maxCapacity >= warriorCount, "mint : You can not mint more warriors than max capacity");
        
        uint256 ap = 0;
        for(uint i=0; i<warriorCount; i++) {
            require(warrior.ownerOf(warriorIds[i]) == msg.sender, "mint : you should own these warrior tokens");
            (,, ap,,,) = warrior.getWarrior(warriorIds[i]);
            attack_power = attack_power.add(ap);
            warrior.burn(warriorIds[i]);

        }

        tokenIdIndex[_tokenIds.current()] = addressTokenIds[msg.sender].length - 1;
        tokenToOwner[_tokenIds.current()] = msg.sender;

        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
        addressTokenIds[msg.sender].push(_tokenIds.current());
        tokenData[_tokenIds.current()] = Legion("AAA", "QmTyQ3Mab2711GWGMyvXqMVCQpK49WH1KQRzhUBJS96Q7W", beastIds, warriorIds, 0, 0, attack_power, block.timestamp);
        _tokenIds.increment();
    }

    function getLegion(uint256 tokenId) external view 
        returns(string memory, string memory, uint256[] memory, uint256[] memory, uint256, uint256, uint256, uint256) {
        Legion memory legion = tokenData[tokenId];
        return (
            legion.name,
            legion.imgUrl,
            legion.beast_ids,
            legion.warrior_ids,
            legion.supplies,
            legion.contracts,
            legion.attack_power,
            legion.minted_time
        );
    }
    function addBeasts(uint256 tokenId, uint256[] memory beastIds) external {
        require(ownerOf(tokenId)==msg.sender, "You should own this legion");
        uint256 beastCount = beastIds.length;
        require(beastCount > 0, "Please add beast ids");
        Legion memory legion = tokenData[tokenId];
        require(legion.beast_ids.length+beastIds.length<=maxBeasts, "You could not overflow the max beasts number");
        for(uint i=0; i<beastCount; i++) {
            require(beast.ownerOf(beastIds[i]) == msg.sender, "You should own these beasts");
            //legion.beast_ids[legion.beast_ids.length] = beastIds[i];
            beast.burn(beastIds[i]);
        }
        uint256 unit = 10**18;
        uint256 bloodstoneAmount = itemPrice.mul(beastCount).mul(unit).div(denominator);
        require(bloodstone.balanceOf(msg.sender)>=bloodstoneAmount, "Insufficient balance");
        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
    }
    function addWarriors(uint256 tokenId, uint256[] memory warriorIds) external {
        require(ownerOf(tokenId)==msg.sender, "You should own this legion");
        uint256 warriorCount = warriorIds.length;
        require(warriorCount > 0, "Please add warrior ids");
        Legion memory legion = tokenData[tokenId];
        uint256 ap = 0;
        for(uint i=0; i<warriorCount; i++) {
            require(warrior.ownerOf(warriorIds[i]) == msg.sender, "You should own these warriors");
            (,, ap,,,) = warrior.getWarrior(warriorIds[i]);
            //legion.warrior_ids[legion.warrior_ids.length] = warriorIds[i];
            legion.attack_power = legion.attack_power.add(ap);
            warrior.burn(warriorIds[i]);
        }
        uint256 unit = 10**18;
        uint256 bloodstoneAmount = legion.supplies.mul(supplyPrice).mul(unit) + itemPrice.mul(warriorCount).mul(unit).div(denominator);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount, "Insufficient balance");
        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
    }
    function addSupply(uint256 tokenId, uint256 supply, bool fromWallet) external {
        require(ownerOf(tokenId)==msg.sender, "You should own this legion");
        if(fromWallet) {

        }
        Legion memory legion = tokenData[tokenId];
        // if(legion.supplies==0) {

        // }
        uint256 warriorCount = legion.warrior_ids.length;
        uint256 bloodstoneAmount = warriorCount.mul(supply).mul(supplyPrice)*10**18;
        require(bloodstone.balanceOf(msg.sender)>=bloodstoneAmount, "Insufficient balance");
        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
        legion.supplies = legion.supplies.add(supply);
    }
    function getTokenIds(address _address) external view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }
    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }

    function setItemPrice(uint256 _itemPrice, uint256 _denominator) external onlyOwner {
        itemPrice = _itemPrice;
        denominator = _denominator;
    }

    function setSupplyPrice(uint256 _price) external onlyOwner {
        supplyPrice = _price;
    }

    function setMaxBeastNumber(uint256 _maxNum) external onlyOwner {
        maxBeasts = _maxNum;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function withdrawBNB(address payable _addr, uint256 amount) public onlyOwner {
        _addr.transfer(amount);
    }

    function withdrawBNBOwner(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
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
pragma solidity 0.7.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IRewardPool.sol";
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract RewardPool is IRewardPool, Ownable {
    using SafeMath for uint256;
    IBEP20 public bloodstone;
    address beast;
    address warrior;
    address public legion;

    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }

    modifier onlyContract() {
        require(msg.sender == beast || msg.sender == warrior); _;
    }

    mapping (address => uint256) unclaimedUSD;
    mapping (address => uint256) transferedTokenAmount;
    
    constructor () {
        legion = msg.sender;
        bloodstone = IBEP20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
        beast = 0x4db14f4c369e6882076f2C95C8ed19a4891e58B5;
        warrior = 0x28f599e278Bc00139635573CFd1ECA47E593d260;
    }

    function getUnclaimedUSD(address _address) external view returns(uint256) {
        return unclaimedUSD[_address];
    }

    function returnTokenToPlayer(address _address, uint256 _amount) external override onlyContract {
        require(bloodstone.balanceOf(address(this))>_amount, "returnTokenToPlayer : Insufficient Funds");
        bloodstone.transfer(_address, _amount);
    }

    function setNftAddresses(address _beast, address _warrior) public onlyOwner {
        beast = _beast;
        warrior = _warrior;
    }
    
    function withdrawBNB(address payable _addr, uint256 amount) public onlyOwner {
        _addr.transfer(amount);
    }

    function withdrawBNBOwner(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


interface IBeastNFT is IERC721 {
    function getBeast(uint256 tokenId) external  view returns(string memory, uint256, uint256, string memory, string memory);
    function burn(uint256 tokenId) external;
}

contract BeastNFT is Context, IBeastNFT, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 public bloodstone;
    string public _baseURL;
    address public rewardpool;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address public legion;
    uint256 mintingPrice;

    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }

    struct Beast {
        string name;
        uint256 strength;
        uint256 capacity;
        string[2] imgUrl;
    }
    mapping (uint256 => Beast) tokenData;
    mapping (address => uint256[]) addressTokenIds;

    string private _name;
    string private _symbol;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => uint256) tokenIdIndex;
    constructor(address _rewardpool) {
        legion = msg.sender;
        _name = "Crypto Legions Beast";
        _symbol = "BEAST";
        bloodstone = IERC20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
        rewardpool = _rewardpool;
        mintingPrice = 20;
        bloodstone.approve(address(rewardpool), 5000000*10**18);
        setBaseURL("https://ipfs.infura.io:5001/api/v0/cat/");
    }
    function supportsInterface(bytes4 interfaceId) external override view returns (bool){}
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner || isApprovedForAll(owner, msg.sender), "ERC721: approval to current owner");
        require(msg.sender==owner, "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return addressTokenIds[owner].length;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return tokenToOwner[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        _approve(address(0), tokenId);

        addressTokenIds[from][tokenIdIndex[tokenId]] = addressTokenIds[from][addressTokenIds[from].length-1];
        tokenIdIndex[addressTokenIds[from][addressTokenIds[from].length-1]] = tokenIdIndex[tokenId];
        addressTokenIds[from].pop();
        tokenToOwner[tokenId] = to;
        
        addressTokenIds[to].push(tokenId);
        tokenIdIndex[tokenId] = addressTokenIds[to].length - 1;
        emit Transfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) external override onlyLegion{
        address owner = ownerOf(tokenId);
        _transfer(owner, address(0), tokenId);
    }

    function mint(uint256 amount) external {
        require(rewardpool!=ZERO, "mint : should set reward pool address first");
        uint256 bloodstoneAmount = getBloodstoneAmount(amount);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount*10**18, "Insufficient payment");
        bloodstone.transferFrom(msg.sender, rewardpool, bloodstoneAmount*10**18);
        uint256 randNum = 0;
        Beast memory beast;
        for(uint i=0; i<amount; i++) {
            addressTokenIds[msg.sender].push(_tokenIds.current());
            tokenIdIndex[_tokenIds.current()] = addressTokenIds[msg.sender].length - 1;
            tokenToOwner[_tokenIds.current()] = msg.sender;
            randNum = genRand(10000, i);
            if (randNum==0&&randNum<5) {
                string[2] memory imgs = ["QmNrqT2UXZ6vjAMN277fTo6TwV9Cg1dDop5QZg39Hbu3Tc", "QmbPKG9oTCeXwschSxCuvxRt5hsEaseDJqfaGRWUXHujvt"];
                beast = Beast("Phoenix", 6, 20, imgs);
            } else if (randNum>=5&&randNum<100) {
                string[2] memory imgs = ["QmNUQeLyZXdSjCQPJr83PTSWkwFbPXHGdF7pHwVUJcQSaj", "QmSwGmc4f7uckbE875qH3Pvz5V8tSDoYwNzdT16G7HQDqU"];
                beast = Beast("Dragon", 5, 5, imgs);
            } else if (randNum>=100&&randNum<800) {
                string[2] memory imgs = ["QmNatbVqKggWQQkoS8bxthU1YSe2TFNGCtuEmNCr8rVYDd", "QmduQCGnM1gxCt8wDNzfScFoKkUQXUXUqYWP4UCPhWxumf"];
                beast = Beast("Griffin", 4, 4, imgs);
            } else if (randNum>=800&&randNum<2200) {
                string[2] memory imgs = ["QmXJjCqKAuALekTM1MUGpQDi9GaGuC4U5o5fdbVmac1hSN", "QmRwqb5j7ux6wg7bqyHTvfD248PJDeaYEZaYDyJUK893C9"];
                beast = Beast("Pegasus", 3, 3, imgs);
            } else if (randNum>=2200&&randNum<5000) {
                string[2] memory imgs = ["QmSgKKqAZex4qBjtHciSXwwxn8Cqn8CJY4UCdEww62fNWQ", "QmToLNrMr3Qb5PzdeRdDSfQDWDQyrwwzf8awbcQuN46TTi"];
                beast = Beast("Barghest", 2, 2, imgs);
            } else {
                string[2] memory imgs = ["QmYqrDk6qcvo3Kg15RuMcJsZhJ4JatAuyv8VAWvCojKeAZ", "QmTeRPz37nQyEHHhu2rpMBePXy5GLZidA6XMUprUCv1A1f"];
                beast = Beast("Centaur", 1, 1, imgs);
            }
            tokenData[_tokenIds.current()] = beast;
            _tokenIds.increment();
        }
    }

    function setRewardPool(address _address) external onlyOwner {
        rewardpool = _address;
        bloodstone.approve(rewardpool, 5000000*10**18);
    }

    function genRand(uint256 maxNum, uint256 i) private view returns (uint256) {
        require(maxNum>0, "maxNum should be bigger than zero");
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty, i))) % maxNum);
    }

    function getBloodstoneAmount(uint256 _mintingAmount) public view returns (uint256) {
        require(_mintingAmount > 0, "amount should be bigger than zero");
        if(_mintingAmount==1) {
            return mintingPrice;
        } else if(_mintingAmount==5) {
            return mintingPrice.mul(5).mul(98).div(100);
        } else if(_mintingAmount==10) {
            return mintingPrice.mul(10).mul(97).div(100);
        } else if(_mintingAmount==20) {
            return mintingPrice.mul(20).mul(95).div(100);
        } else if(_mintingAmount==100) {
            return mintingPrice.mul(100).mul(90).div(100);
        } else {
            return mintingPrice.mul(_mintingAmount);
        }
    }

    function getTokenIds(address _address) external view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }

    function getBeast(uint256 tokenId) external view virtual override returns(string memory, uint256, uint256, string memory, string memory) {
        return (tokenData[tokenId].name, tokenData[tokenId].strength, tokenData[tokenId].capacity, tokenData[tokenId].imgUrl[0], tokenData[tokenId].imgUrl[1]);
    }

    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getMintingPrice() public view returns (uint256) {
        return mintingPrice;
    }

    function setMintingPrice(uint256 _price) public onlyOwner {
        require(_price>0, "price should be bigger than zero");
        mintingPrice = _price;
    }

    function withdrawBNB(address payable _addr, uint256 amount) public onlyOwner {
        _addr.transfer(amount);
    }

    function withdrawBNBOwner(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IRewardPool.sol";

interface IWarriorNFT is IERC721 {
    function getWarrior(uint256 tokenId) external view returns(string memory, uint256, uint256, string memory, string memory, uint256);
    function burn(uint256 tokenId) external;
}

contract WarriorNFT is Context, IWarriorNFT, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address ZERO = 0x0000000000000000000000000000000000000000;
    IERC20 public bloodstone;
    string public _baseURL;
    IRewardPool rewardPool;
    address public rewardPoolAddr;
    address public legion;
    uint256 mintingPrice;

    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }

    struct Warrior {
        string name;
        uint256 strength;
        uint256 attack_power;
        string[2] imgUrl;
        uint256 executeBackAmount;
    }
    mapping (uint256 => Warrior) tokenData;
    mapping (address => uint256[]) addressTokenIds;
    mapping (uint256 => bool) executed;

    string private _name;
    string private _symbol;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => uint256) tokenIdIndex;
    constructor(address _rewardpool) {
        legion = msg.sender;
        _name = "Crypto Legions Warrior";
        _symbol = "WARRIOR";
        bloodstone = IERC20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
        mintingPrice = 20;
        rewardPoolAddr = _rewardpool;
        rewardPool = IRewardPool(rewardPoolAddr);
        bloodstone.approve(rewardPoolAddr, 5000000*10**18);
        setBaseURL("https://ipfs.infura.io:5001/api/v0/cat/");
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool){}

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner || isApprovedForAll(owner, msg.sender), "ERC721: approval to current owner");
        require(msg.sender==owner, "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return addressTokenIds[owner].length;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return tokenToOwner[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        _approve(address(0), tokenId);

        addressTokenIds[from][tokenIdIndex[tokenId]] = addressTokenIds[from][addressTokenIds[from].length-1];
        tokenIdIndex[addressTokenIds[from][addressTokenIds[from].length-1]] = tokenIdIndex[tokenId];
        addressTokenIds[from].pop();
        tokenToOwner[tokenId] = to;
        
        addressTokenIds[to].push(tokenId);
        tokenIdIndex[tokenId] = addressTokenIds[to].length - 1;
        emit Transfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) external override onlyLegion{
        address owner = ownerOf(tokenId);
        _transfer(owner, address(0), tokenId);
    }

    function mint(uint256 amount) external {
        require(rewardPoolAddr!=ZERO, "mint : should set reward pool address first");
        uint256 bloodstoneAmount = getBloodstoneAmount(amount);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount*10**18, "Insufficient payment");
        bloodstone.transferFrom(msg.sender, address(rewardPoolAddr), bloodstoneAmount*10**18);
        uint256 executeBackAmount = bloodstoneAmount.mul(10**18).mul(20).div(100).div(amount);
        uint256 randNum;
        Warrior memory warrior;
        for(uint i=0; i<amount; i++) {
            addressTokenIds[msg.sender].push(_tokenIds.current());
            tokenIdIndex[_tokenIds.current()] = addressTokenIds[msg.sender].length - 1;
            tokenToOwner[_tokenIds.current()] = msg.sender;
            randNum = genRand(10000, i);
            if (randNum==0&&randNum<5) {
                string[2] memory imgs = ["Qma4GioKvo7yEzyN8Mk5G5qGmQ4w7g7nrdXwiix8iugthK", "QmUnW39Amrd4irc7XkiPSjnzZDw9DyHY5L6zNgqnbSbaTj"];
                warrior = Warrior("Dragon", 6, 45000+genRand(5001, randNum), imgs, executeBackAmount);
            } else if (randNum>=5&&randNum<100) {
                string[2] memory imgs = ["QmPkQJkvoo4HRKniqwwNZynAs5wr381PUCdAWqjmKgZmPy", "QmYmMNhQnZvrCxddJnAyGGGDBvAdPFMAp66tLNSrCBiFUT"];
                warrior = Warrior("Minotaur", 5, 4000+genRand(1501, randNum), imgs, executeBackAmount);
            } else if (randNum>=100&&randNum<800) {
                string[2] memory imgs = ["QmRWs3ToWngasDdZD9kKDwYKcnpK5saGYK2bCCaniL4ZtV", "QmSyDogoc2bTHM8LfsFtz8BPfLHfUCx8fCxzBLpXpQtRYS"];
                warrior = Warrior("Dwarf", 4, 3000+genRand(1000, randNum), imgs, executeBackAmount);
            } else if (randNum>=800&&randNum<2200) {
                string[2] memory imgs = ["QmXJpBzqkR2BxRREGGcFPAuKvbuJwaLYWsSXDurKPZjF5p", "QmUH3zhaHuLFz3enF8A3yJjDbYZTLqVrz2KFU1VUgDoAdK"];
                warrior = Warrior("Satyr", 3, 2000+genRand(1000, randNum), imgs, executeBackAmount);
            } else if (randNum>=2200&&randNum<5000) {
                string[2] memory imgs = ["QmcrAjTFb7RsCEiAkqcy3rcr9CUCNX17PG3QpVnkQMQ4vd", "QmcDqPWTMSdRbiaq4rJn6LRXE9V8gs9ehD18DSNgLoD4Uy"];
                warrior = Warrior("Gnome", 2, 1000+genRand(1000, randNum), imgs, executeBackAmount);
            } else {
                string[2] memory imgs = ["QmT2kUH6H6vmNKrgGhcg34jaWY7RresHoyCocThZiA9Q5z", "QmbKNLr8qMK4MXbiC9E6hARQqn8HiAgGS4tZWgJ6fioMa9"];
                warrior = Warrior("Hobbit", 1, 400+genRand(600, randNum), imgs, executeBackAmount);
            }
            tokenData[_tokenIds.current()] = warrior;
            _tokenIds.increment();
        }
    }

    function executeWarrior(uint256 _tokenId) external {
        require(msg.sender==ownerOf(_tokenId), "executeWarrior : you should own this token");
        require(rewardPoolAddr!=ZERO, "executeWarrior : Should set reward pool first");
        require(executed[_tokenId]==false, "executeWarrior : Already executed");
        rewardPool.returnTokenToPlayer(msg.sender, tokenData[_tokenId].executeBackAmount);
        executed[_tokenId] = true;
    }

    function genRand(uint256 maxNum, uint256 i) private view returns (uint256) {
        require(maxNum>0, "maxNum should be bigger than zero");
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty, i))) % maxNum);
    }

    function getBloodstoneAmount(uint256 _mintingAmount) private view returns (uint256) {
        require(_mintingAmount > 0, "amount should be bigger than zero");
        if(_mintingAmount==1) {
            return mintingPrice;
        } else if(_mintingAmount==5) {
            return mintingPrice.mul(5).mul(98).div(100);
        } else if(_mintingAmount==10) {
            return mintingPrice.mul(10).mul(97).div(100);
        } else if(_mintingAmount==20) {
            return mintingPrice.mul(20).mul(95).div(100);
        } else if(_mintingAmount==100) {
            return mintingPrice.mul(100).mul(90).div(100);
        } else {
            return mintingPrice.mul(_mintingAmount);
        }
    }

    function getTokenIds(address _address) external view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }

    function getWarrior(uint256 tokenId) external override view returns(string memory, uint256, uint256, string memory, string memory, uint256) {
        return (
            tokenData[tokenId].name,
            tokenData[tokenId].strength,
            tokenData[tokenId].attack_power,
            tokenData[tokenId].imgUrl[0],
            tokenData[tokenId].imgUrl[1],
            tokenData[tokenId].executeBackAmount
        );
    }

    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getMintingPrice() public view returns (uint256) {
        return mintingPrice;
    }

    function setMintingPrice(uint256 _price) public onlyOwner {
        require(_price>0, "price should be bigger than zero");
        mintingPrice = _price;
    }

    function withdrawBNB(address payable _addr, uint256 amount) public onlyOwner {
        _addr.transfer(amount);
    }

    function withdrawBNBOwner(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IRewardPool {
    function returnTokenToPlayer(address _address, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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