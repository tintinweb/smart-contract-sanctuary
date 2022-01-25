// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface PlayingCard {
    function batchMintCard(address _to,uint256 _cardType,uint256 _numberOfToken) external;
    function mintCard(address to,uint256 cardType) external ;
    function burn(address _address,uint _tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address); 
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function idCardType(uint256 _tokenId) external returns(uint256);
    function totalCardType() external view returns(uint);
}

interface Medal {

    function mint(address _to,uint256 _id,uint256 _quantity) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;
    function burn(address _account,uint256 _id,uint256 _amount) external;
   
    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface Consumer{
    function getLatestPrice() external view returns (int);
}

interface SwapPair {
    function getReserves() external view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface MembershipPool {
     function balanceOf(address account) external view returns (uint256);
}

contract NFTSwap is Ownable, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant DENOMINATOR = 10000;
    
    IERC20 public NFT4Play;

    // 0 = DAI,1 = USDC,2 = USDT 
    IERC20[3] public stableCoins;

    address public treasury;
    address public medalOwner;

    SwapPair public NFT4Play_eth_Pair;
    Consumer public PriceConsumer;
    MembershipPool public membershipPool;

    uint public cardDiscount;
    uint public legendaryMedalDiscount;

    uint public legendaryMedalId;
    bool public statusOfLegendaryMedalsSale;
    uint public legendaryMedalsPriceInStable;
    uint public legendaryMedalsPriceIn4play;
    bool public legendaryMedals4PlayFixedPrice;

    bool public card4PlayFixedPrice;
    bool public differentPair;
    bool public isSetSwapedMedals;

    struct Game{
        bool mintable;
        PlayingCard cardContract;
        uint256[] cardsPriceInStable;
        uint256[] cardsPriceIn4Play;
    }

    Medal public medalContract;
    Game[] games;

    mapping(address=>mapping(uint => uint)) public userSwapedMedals;

    event SetTreasury(address _treasury);
    event AddNewGameCard(address _cardContract);
    event SetCardsPriceInStable(uint256 _cardType, uint256 _price);
    event SetCardsPriceIn4Play(uint256 _cardType, uint256 _price);
    
    event SwapWithMedals(address _account, uint _gameId,uint256 _medalId,uint _amountOfMedal);
    event BuyCardsWithStableCoin(address _account,uint256 _gameId,uint256 _index,uint _cardType,uint256 _noOfCards,uint _amount);
    event BuyCardsWithNft4Play(address _account,uint256 _gameId,uint _cardType,uint256 _noOfCards,uint _amount);
    event PurchaseLegendaryMedal(address _account,uint _index,uint _amountOfMedal,uint _amount);
    event PurchaseLegendaryMedal4play(address _account,uint _amountOfMedal,uint _amount);

    constructor(address[3] memory _tokens,address _medalContract,address _membershipPool,address _treasury,address _priceConsumer){ 
        for(uint i=0; i< _tokens.length; i++){
            require(_tokens[i] != address(0),"NFTSwap: token address is not valid");
            stableCoins[i] = IERC20(_tokens[i]);
        }
        PriceConsumer = Consumer(_priceConsumer);
        medalContract = Medal(_medalContract);
        membershipPool = MembershipPool(_membershipPool);
        treasury = _treasury;
        cardDiscount = 5000;
        legendaryMedalId = 5;
        _pause();
    }

    modifier isPriceSet(uint _gameId,uint _cardType) {
        require(_isPriceSet(_gameId,_cardType),"NFTSwap: card price is not set");
        _;
    }

    modifier validGameId(uint _gameId){
        require(games.length > _gameId && games[_gameId].mintable,"NFTSwap: use valid game Id");
        _;
    }

    modifier checkMember(){
        require(membershipPool.balanceOf(msg.sender) > 0,"NFTSwap: only members can Purchase/Mint");
        _;
    }

    // Admin function

    function set4PlayToken(address _nft4Play) external onlyOwner(){
        require(_nft4Play != address(0),"NFTSwap: _nft4Play address is not valid");
        NFT4Play = IERC20(_nft4Play);

    }

    function setPairAddress(address _pair) external onlyOwner(){
        require(_pair != address(0),"NFTSwap: _pair address is not valid");
        NFT4Play_eth_Pair = SwapPair(_pair);
    }

    function changePairState(bool _state) external onlyOwner(){
        require(differentPair != _state,"NFTSwap: _state must be different");
        differentPair = _state;
    }

    function changeSetMedalSwapedToken(bool _state) external onlyOwner(){
        require(isSetSwapedMedals != _state,"NFTSwap: _state must be different");
        isSetSwapedMedals = _state;
    }

    function addNewGameCard(address _cardContract,uint[] memory _priceInStable,uint[] memory _priceIn4Play) external onlyOwner() {
        require(_cardContract != address(0),"NFTSwap: _cardContract address is not valid");
        require(PlayingCard(_cardContract).totalCardType() > _priceIn4Play.length,"NFTSwap: listed card is less");
        require(PlayingCard(_cardContract).totalCardType() > _priceInStable.length,"NFTSwap: listed card is less");
        games.push(Game(true,PlayingCard(_cardContract),_priceInStable,_priceIn4Play));
        emit AddNewGameCard(_cardContract);
    }

    function changeGameMintable(uint _gameId,bool _mintable) external onlyOwner(){
        require(games[_gameId].mintable != _mintable,"NFTSwap: mintable should be different");
        games[_gameId].mintable = _mintable;
    }

    function setTreasury(address _treasury) external onlyOwner(){
        require(_treasury != address(0),"NFTSwap: _treasury address is not valid");
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    function setCardsPriceIn4Play(uint _gameId,uint256[] memory _cardTypes, uint256[] memory _price) external onlyOwner() {
        require(_cardTypes.length == _price.length,"NFTSwap: _cardTypes length is not equal to price length ");
        for(uint8 i = 0; i < _cardTypes.length; i++){
            require(_price[i] > 0,"NFTSwap: _price must be greater than zero");
            require(_cardTypes[i] <= games[_gameId].cardContract.totalCardType() ,"NFTSwap: _price must be greater than zero");
            games[_gameId].cardsPriceIn4Play[_cardTypes[i].sub(1)] = _price[i];
            emit SetCardsPriceIn4Play(_cardTypes[i], _price[i]);
        }
    }

    function setCardsPriceInStable(uint _gameId,uint256[] memory _cardTypes, uint256[] memory _price) external onlyOwner() {
        require(_cardTypes.length == _price.length,"NFTSwap: _cardTypes length is not equal to price length ");
        for(uint8 i = 0; i < _cardTypes.length; i++){
            require(_price[i] > 0,"NFTSwap: _price must be greater than zero");
            require(_cardTypes[i] <= games[_gameId].cardContract.totalCardType() ,"NFTSwap: _price must be greater than zero");
            games[_gameId].cardsPriceInStable[_cardTypes[i].sub(1)] = _price[i];
            emit SetCardsPriceInStable(_cardTypes[i], _price[i]);
        }
    }

    function setOneLegendaryMedalPriceInDoller(uint _price) external onlyOwner(){
        require(_price > 0,"NFTSwap: _price must be greater than zero");
        legendaryMedalsPriceInStable = _price;
    }

    function setOneLegendaryMedalPriceIn4play(uint _price) external onlyOwner(){
        require(_price > 0,"NFTSwap: _price must be greater than zero");
        legendaryMedalsPriceIn4play = _price;
    }

    function setLegendaryMedalOwner(address _medalOwner) external onlyOwner(){
        require(_medalOwner != address(0),"NFTSwap: _medalOwner address is not valid");
        medalOwner = _medalOwner;
    }

    function changeStatusOfLegendaryMedalsSale(bool _status) external onlyOwner(){
        require(_status != statusOfLegendaryMedalsSale,"NFTSwap: _ststus must be different");
        statusOfLegendaryMedalsSale = _status;
    }

    function changeStatusOfMedal4PlayFixedPrice(bool _status) external onlyOwner(){
        require(_status != legendaryMedals4PlayFixedPrice,"NFTSwap: _ststus must be different");
        legendaryMedals4PlayFixedPrice = _status;
    }

    function changeStatusForCards4PlayFixedPrice(bool _status) external onlyOwner(){
        require(_status != card4PlayFixedPrice,"NFTSwap: _status must be different");
        card4PlayFixedPrice = _status;
    }

    function changeCardDiscount(uint _discount) external onlyOwner(){
        require(_discount != cardDiscount,"NFTSwap: _discount must be different");
        require(_discount < DENOMINATOR,"NFTSwap: _discount is not valid");
        cardDiscount = _discount;
    }

    function changeMedalDiscount(uint _discount) external onlyOwner(){
        require(_discount != legendaryMedalDiscount,"NFTSwap: _discount must be different");
        require(_discount < DENOMINATOR,"NFTSwap: _discount is not valid");
        legendaryMedalDiscount = _discount;
    }
    
    /**
     * @dev Triggers smart contract to stopped state
    */

    function pause() public onlyOwner(){
        _pause();
    }

    /**
     * @dev Returns smart contract to normal state
    */
    function unpause() public onlyOwner(){
        _unpause();
    }

    //internal

    function _isPriceSet(uint _gameId,uint _cardType) internal view returns (bool){
        return games[_gameId].cardsPriceInStable[_cardType.sub(1)] > 0;
    }

    function _mintCardType(address _address,uint _gameId,uint _cardType,uint _amountOfCards) internal{
        if(_cardType == 5 || _cardType == 4){
            games[_gameId].cardContract.batchMintCard(_address,_cardType,_amountOfCards);
        }
        else{
            for(uint8 i=0; i < _amountOfCards; i++){
                uint random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,i))) % 20;
                if(random == _cardType){
                    _cardType =  _cardType.add(1);
                }
                games[_gameId].cardContract.mintCard(_address,_cardType);
            }
        }
    }

    function purchaseMedals(uint _amountOfMedal) internal{
        require(_amountOfMedal > 0 ,"NFTSwap: _amount must be greater than zero");
        require(statusOfLegendaryMedalsSale,"NFTSwap: can't buy medals");
        require(medalContract.balanceOf(medalOwner,legendaryMedalId) >= _amountOfMedal,"NFTSwap: medalOwner balance is low");
        medalContract.safeTransferFrom(medalOwner,msg.sender,legendaryMedalId,_amountOfMedal,"");
    }

    function payableAmountForLegendary(uint256 _amountOfMedal) public view returns(uint256){
        uint dollerAmount = (legendaryMedalsPriceInStable.mul(DENOMINATOR.sub(legendaryMedalDiscount))).div(DENOMINATOR);
        return dollerAmount.mul(nft4PlayInDollor()).div(10**18).mul(_amountOfMedal);
    }

    /**
     * @dev purchase Legendary card 
    */

    function purchaseLegendaryMedal(uint _index,uint _amountOfMedal) external checkMember() nonReentrant{
        require(legendaryMedalsPriceInStable > 0,"NFTSwap: Price is not set");
        uint totalPrice = legendaryMedalsPriceInStable.mul( _amountOfMedal);
        stableCoins[_index].safeTransferFrom(msg.sender,treasury,totalPrice);
        purchaseMedals(_amountOfMedal);
        emit PurchaseLegendaryMedal(msg.sender,_index,_amountOfMedal,totalPrice);
    }

    function purchaseLegendaryMedal4play(uint _amountOfMedal) external checkMember() nonReentrant{
        uint totalPrice;
        if(legendaryMedals4PlayFixedPrice){
            require(legendaryMedalsPriceIn4play > 0,"NFTSwap: Price is not set");
            totalPrice = legendaryMedalsPriceIn4play.mul(_amountOfMedal);
        }
        else{
            require(legendaryMedalsPriceInStable > 0,"NFTSwap: Price is not set");
            totalPrice = payableAmountForLegendary(_amountOfMedal);
        }
        NFT4Play.safeTransferFrom(msg.sender,treasury,totalPrice);
        purchaseMedals(_amountOfMedal);
        emit PurchaseLegendaryMedal4play(msg.sender,_amountOfMedal,totalPrice);
    }


    /**
     * @dev swap medal with card
    */

    function swapWithMedals(uint _gameId,uint256 _medalId,uint _amountOfMedal) external validGameId(_gameId) whenNotPaused nonReentrant{   
        require(medalContract.balanceOf(msg.sender,_medalId) >= _amountOfMedal,"NFTSwap: medal balance is low");
        require(_amountOfMedal > 0,"NFTSwap: _amountOfMedal must be greater than zero");
        medalContract.burn(msg.sender,_medalId,_amountOfMedal);
        _mintCardType(msg.sender,_gameId,_medalId,_amountOfMedal);
        if(isSetSwapedMedals){
            userSwapedMedals[msg.sender][_medalId] = userSwapedMedals[msg.sender][_medalId].add(_amountOfMedal);
        }
        emit SwapWithMedals(msg.sender,_gameId,_medalId,_amountOfMedal);
    }

    /**
     * @dev mint card using stable coin
    */

    function buyCardsWithStableCoin(uint256 _gameId,uint256 _index,uint _cardType,uint256 _noOfCards) external checkMember() validGameId(_gameId) isPriceSet(_gameId,_cardType) whenNotPaused nonReentrant{
        require(games[_gameId].cardContract.totalCardType() > _cardType && _cardType > 0,"NFTSwap: card type is not valid");
        require(stableCoins.length > _index,"NFTSwap: use valid index");
        require(_noOfCards > 0,"NFTSwap: no of card must be greater than zero");
        uint totalPrice = games[_gameId].cardsPriceInStable[_cardType.sub(1)].mul( _noOfCards);
        stableCoins[_index].safeTransferFrom(msg.sender,treasury,totalPrice);
        _mintCardType(msg.sender,_gameId,_cardType,_noOfCards);
        emit BuyCardsWithStableCoin(msg.sender,_gameId,_index,_cardType,_noOfCards,totalPrice);
    } 

    /**
     * @dev mint card using 4Play token
    */

    function buyCardsWithNFT4Play(uint256 _gameId,uint _cardType,uint256 _noOfCards) external checkMember() isPriceSet(_gameId,_cardType) validGameId(_gameId) whenNotPaused nonReentrant{
        require(games[_gameId].cardContract.totalCardType() > _cardType && _cardType > 0,"NFTSwap: card type is not valid");
        require(_noOfCards > 0,"NFTSwap: no of card must be greater than zero");
        uint totalPrice;
        if(card4PlayFixedPrice){
            require(games[_gameId].cardsPriceIn4Play[_cardType.sub(1)] > 0,"NFTSwap: card price is not set");
            totalPrice = games[_gameId].cardsPriceIn4Play[_cardType.sub(1)].mul(_noOfCards);
        }
        else{
            totalPrice = payableAmount(_gameId,_cardType,_noOfCards);
        }
        NFT4Play.safeTransferFrom(msg.sender,treasury,totalPrice);
        _mintCardType(msg.sender,_gameId,_cardType,_noOfCards);
        emit BuyCardsWithNft4Play(msg.sender,_gameId,_cardType, _noOfCards,totalPrice);
    }

    function payableAmount(uint _gameId,uint _cardType,uint256 _noOfCards) public view returns(uint256){
        uint dollerAmount = (games[_gameId].cardsPriceInStable[_cardType.sub(1)].mul(DENOMINATOR.sub(cardDiscount))).div(DENOMINATOR);
        return dollerAmount.mul(nft4PlayInDollor()).div(10**18).mul(_noOfCards);
    } 

    function nft4PlayInDollor() public view returns(uint256){
        (uint256 reserve0,uint256 reserve1,) = NFT4Play_eth_Pair.getReserves();
        uint256 temp;
        if(differentPair){
            temp = reserve1.mul(10**18).div(reserve0);
        }
        else{
            temp = reserve0.mul(10**18).div(reserve1);
        }
        return temp.div(uint256(PriceConsumer.getLatestPrice())).mul(10**8);
    }

    function totalListedGame() external view returns(uint){
        return games.length;
    }

    function getGameDetail(uint _gameId) external view returns(Game memory){
        return games[_gameId];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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