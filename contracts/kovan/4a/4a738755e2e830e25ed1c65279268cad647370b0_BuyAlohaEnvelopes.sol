/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/IAlohaNFT.sol

pragma solidity ^0.6.6;

interface IAlohaNFT {
    function awardItem(
        address wallet,
        uint256 tokenImage,
        uint256 tokenRarity,
        uint256 tokenBackground
    ) external returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenRarity(uint256 tokenId) external returns (uint256);
    function tokenImage(uint256 tokenId) external returns (uint256);
    function tokenBackground(uint256 tokenId) external returns (uint256);
}

// File: contracts/BuyAlohaEnvelopes.sol

pragma solidity 0.6.6;





contract BuyAlohaEnvelopes is Ownable{

    address private _alohaToken;
    address private _alohaNFT;
    address private _burnAddress;
    address private _treasuryAddress;
    address private _daoAddress;
    mapping (uint256 => uint256[]) private _imagesByRarity;
    uint256 private packOf2Price = 5000000000000000000000000; //5K
    uint256 private packOf3Price = 10000000000000000000000000; //10K
    uint256 private packOf4Price = 50000000000000000000000000; //50K
    uint256 private packOf5Price = 100000000000000000000000000; //100K

    constructor(
        address alohaNFT,
        address alohaToken,
        address burnAddress,
        address treasuryAddress,
        address daoAddress) public
    {
        require(alohaToken != address(0), "The alohaToken address cannot be the zero address(0x000...)");
        require(alohaNFT != address(0), "The alohaNFT address cannot be the zero address(0x000...)");
        require(burnAddress != address(0), "The burnAddress cannot be the zero address(0x000...)");
        require(treasuryAddress != address(0), "The treasuryAddress cannot be the zero address(0x000...)");
        require(daoAddress != address(0), "The daoAddress cannot be the zero address(0x000...)");

        _alohaNFT = alohaNFT;
        _alohaToken = alohaToken;
        _burnAddress = burnAddress;
        _treasuryAddress = treasuryAddress;
        _daoAddress = daoAddress;
    }

    function setPackOf2Price(uint256 price) onlyOwner public{
        require(price > 0, "The price cannot be 0");
        packOf2Price = price;
    }

    function setPackOf3Price(uint256 price) onlyOwner public{
        require(price > 0, "The price cannot be 0");
        packOf3Price = price;
    }

    function setPackOf4Price(uint256 price) onlyOwner  public{
        require(price > 0, "The price cannot be 0");
        packOf4Price = price;
    }

    function setPackOf5Price(uint256 price) onlyOwner public{
        require(price > 0, "The price cannot be 0");
        packOf5Price = price;
    }

    function getPackOf2Price() view public returns (uint256){
        return packOf2Price;
    }

    function getPackOf3Price() view public returns (uint256){
        return packOf3Price;
    }

    function getPackOf4Price() view public returns (uint256){
        return packOf4Price;
    }

    function getPackOf5Price() view public returns (uint256){
        return packOf5Price;
    }

    function setImagesByRarity(uint256 rarity, uint256[] memory images) public onlyOwner{
        require(rarity < 4, "The rarity does not exist");

        _imagesByRarity[rarity] = images;
    }

    function getImagesByRarity(uint256 rarity) view public returns (uint256[] memory){
        require(rarity < 4, "The rarity does not exist");

        return _imagesByRarity[rarity];
    }   

    function buyPackOf2(uint256 amount) public{
        require(amount == packOf2Price, "The prices don't match");
        buyPack(2, amount);
    }

    function buyPackOf3(uint256 amount) public{
        require(amount == packOf3Price, "The prices don't match");
        buyPack(3, amount);
    }

    function buyPackOf4(uint256 amount) public{
        require(amount == packOf4Price, "The prices don't match");
        buyPack(4, amount);
    }

    function buyPackOf5(uint256 amount) public{
        require(amount == packOf5Price, "The prices don't match");
        buyPack(5, amount);
    }

    function buyPack(uint256 numOfCards, uint256 amount) internal{
        uint256 seventyPercent = SafeMath.div(SafeMath.mul(amount, 70), 100);
        uint256 twentyPercent = SafeMath.div(SafeMath.mul(amount, 20), 100);
        uint256 tenPercent = SafeMath.div(SafeMath.mul(amount, 10), 100);

        IERC20(_alohaToken).transferFrom(msg.sender, _burnAddress, seventyPercent);
        IERC20(_alohaToken).transferFrom(msg.sender, _treasuryAddress, twentyPercent);
        IERC20(_alohaToken).transferFrom(msg.sender, _daoAddress, tenPercent);

        uint256 rarity = 1;

        if(numOfCards == 2){
            rarity = 1;
        } else if(numOfCards == 3){
            rarity = 1;
        } else if(numOfCards == 4){
            rarity = 2;
        } else {
            rarity = 3;
        }

        uint256[] memory images = _imagesByRarity[rarity];
        uint256 randNum = _randomNumber(images.length, numOfCards)-1;
        uint256 image = images[randNum];

        uint256 background = _randomNumber(3, numOfCards)-1;

        IAlohaNFT(_alohaNFT).awardItem(msg.sender, rarity, image, background);

        for (uint256 i = 0; i < numOfCards-1; i++) {
            if(numOfCards == 2){
                randNum = 100;
            } else {
                randNum = _randomNumber(100, numOfCards)-1;
            }

            if(randNum == 1 || randNum == 2){
                rarity = 3;
            }
            if(randNum >= 3 && randNum <= 13){
                rarity = 2;
            }
            if(randNum > 13 && randNum <= 100){
                rarity = 1;
            }

            images = _imagesByRarity[rarity];
            randNum = _randomNumber(images.length, numOfCards)-1;
            image = images[randNum];

            background = _randomNumber(3, numOfCards)-1;

            IAlohaNFT(_alohaNFT).awardItem(msg.sender, rarity, image, background);
        }
    }

    function _randomNumber(uint256 _limit, uint256 _salt) internal virtual view returns (uint256) {
        uint256 _gasleft = gasleft();
        bytes32 _blockhash = blockhash(block.number - 1);
        uint256 _blocklimit = block.difficulty;
        bytes32 _structHash = keccak256(
            abi.encode(
                _blockhash,
                _blocklimit,
                block.timestamp,
                _gasleft,
                _salt
            )
        );

        uint256 randomNumber = uint256(_structHash);
        assembly {randomNumber := add(mod(randomNumber, _limit), 1)}
        return uint8(randomNumber);
    }
}