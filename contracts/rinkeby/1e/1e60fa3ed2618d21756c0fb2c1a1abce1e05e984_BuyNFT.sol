/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

//
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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function issuer() external view returns (address);

    function estimateFee(uint256 value) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Fee(address indexed from, address indexed to, address indexed issuer, uint256 value);
}
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function metadata(uint256 tokenId) external view returns (address creator);
    function transfer(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
}
interface FIATContract {
    function getToken2JPY(string memory __symbol) external view returns (string memory _symbolToken, uint _token2JPY);
}
contract BuyNFT is Ownable{
    struct Token {
        string symbol;
        bool existed;
    }
    mapping(address => Token) public tokensFiat;
    address[] public fiat = [
        address(0), // ETH
        address(0x3F1a8a7C4ef4Cc131A41418e2775f186063f6fB3) // F
    ];
    FIATContract public fiatContract;
    constructor () {
        tokensFiat[address(0)] = Token('ETH', true);
        tokensFiat[address(0x3F1a8a7C4ef4Cc131A41418e2775f186063f6fB3)] = Token('F', true);
        fiatContract = FIATContract(0xb7A734052382542209DBAD486B21293Ad9e38797);
    }
    using SafeMath for uint256;
    address public BuyNFTSub = address(0x26e0c7911711Dd35455E31aB4D8c41A81d37ec9c);
    address payable public ceoAddress = payable(address(0x64470E5F5DD38e497194BbcAF8Daa7CA578926F6));
    uint256 public Percen = 1000;

    struct Price {
        uint[] tokenIds;
        address maker;
        uint256 Price2JPY;
        address[] fiat;
        address buyByFiat;
        bool isBuy;
    }
    struct Game {
        mapping(uint256 => Price) tokenPrice;
        uint[] tokenIdSale;
        uint256 Fee;
        uint256 limitFee;
        uint256 CreatorFee;
    }

    mapping(address => Game) public Games;
    address[] public arrGames;

    /**
     * @dev Throws if called by any account other than the ceo address.
     */
    modifier onlyCeoAddress() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlySub() {
        require(msg.sender == BuyNFTSub);
        _;
    }
    function checkIsOwnerOf(address _game, uint[] memory _tokenIds) public view returns (bool) {
        bool flag = true;
        IERC721 erc721Address = IERC721(_game);
        for(uint i = 0; i < _tokenIds.length; i++) {
            if(erc721Address.ownerOf(_tokenIds[i]) != msg.sender) flag = false;
        }
        return flag;
    }
    modifier isOwnerOf(address _game, uint[] memory _tokenIds) {
        require(checkIsOwnerOf(_game, _tokenIds));
        _;
    }
    modifier isValidFiat(address[] memory _fiat) {
        bool isValid = true;
        for(uint256 i = 0; i < _fiat.length; i++) {
            bool isExist = tokensFiat[_fiat[i]].existed;

            if(!isExist) isValid = false;
        }
        require(isValid);
        _;
    }
    modifier isValidFiatBuy(address _fiat) {

        require(tokensFiat[_fiat].existed);
        _;
    }
    event SetFiat(string[] _symbols, address[] _address, address _from);
    event _setPrice(address _game, uint[] _tokenIds, uint256 _Price, uint8 _type);
    event _resetPrice(address _game, uint256 _orderId);
    
    function getFiat() public view returns (address[] memory) {
        return fiat;
    }
    function setBuyNFTSub(address _sub) public onlyOwner {
        BuyNFTSub = _sub;
    }
    function setFiat(string[] memory _symbols, address[] memory addrrs) public onlyOwner {

        for(uint i = 0; i < _symbols.length; i++) {
            tokensFiat[addrrs[i]].symbol = _symbols[i];
            if(!tokensFiat[addrrs[i]].existed) {
                fiat.push(addrrs[i]);
                tokensFiat[addrrs[i]].existed = true;
            }
        }
        emit SetFiat(_symbols, addrrs, msg.sender);
    }
    function getTokensFiat(address _fiat) public view returns(string memory __symbol, bool _existed) {
        return (tokensFiat[_fiat].symbol, tokensFiat[_fiat].existed);
    }
    function price2wei(uint256 _price, address _fiatBuy) public view returns(uint256) {
        uint weitoken;
        (, weitoken) = fiatContract.getToken2JPY(tokensFiat[_fiatBuy].symbol);
        return _price.mul(weitoken).div(1 ether);
    }
    function tokenId2wei(address _game, uint256 _orderId, address _fiatBuy) public view returns(uint256) {
        uint weitoken;
        uint _price = Games[_game].tokenPrice[_orderId].Price2JPY;
        (, weitoken) = fiatContract.getToken2JPY(tokensFiat[_fiatBuy].symbol);
        return _price.mul(weitoken).div(1 ether);
    }
    function setFiatContract(address _fiatContract) public onlyOwner {
        fiatContract = FIATContract(_fiatContract);
    }
    function getTokenPrice(address _game, uint _orderId) public view
    returns(address _maker, uint[] memory _tokenIds, uint _Price2JPY, address[] memory _fiat, address _buyByFiat, bool _isBuy) {

        return (Games[_game].tokenPrice[_orderId].maker,
        Games[_game].tokenPrice[_orderId].tokenIds,
        Games[_game].tokenPrice[_orderId].Price2JPY,
        Games[_game].tokenPrice[_orderId].fiat,
        Games[_game].tokenPrice[_orderId].buyByFiat,
        Games[_game].tokenPrice[_orderId].isBuy);

    }
    function getArrGames() public view returns(address[] memory){
        return arrGames;
    }
    function ownerOf(address _game, uint256 _tokenId) public view returns (address){
        IERC721 erc721Address = IERC721(_game);
        return erc721Address.ownerOf(_tokenId);
    }

    function balanceOf() public view returns (uint256){
        return address(this).balance;
    }
    function updateArrGames(address _game) internal {
        bool flag = false;
        for(uint i = 0; i< arrGames.length; i++) {
            if(arrGames[i] == _game) flag = true;
        }
        if(!flag) arrGames.push(_game);
    }
    function setPrice(uint _orderId, address _game, uint[] memory _tokenIds, uint256 _price, address[] memory _fiat) internal {
        require(Games[_game].tokenPrice[_orderId].maker == address(0) || Games[_game].tokenPrice[_orderId].maker == msg.sender);
        Games[_game].tokenPrice[_orderId] = Price(_tokenIds, msg.sender, _price, _fiat, address(0), false);
        Games[_game].tokenIdSale.push(_orderId);
        updateArrGames(_game);
    }

    function calFee(address _game, uint256 _price) public view returns (uint256){
        uint256 fee =_price.mul(Games[_game].Fee).div(Percen);

        return fee;
    }

    function calPrice(address _game, uint256 _orderId) public view
    returns(address _tokenOwner, uint256 _Price2JPY, address[] memory _fiat, address _buyByFiat, bool _isBuy) {
        return (Games[_game].tokenPrice[_orderId].maker,
        Games[_game].tokenPrice[_orderId].Price2JPY,
        Games[_game].tokenPrice[_orderId].fiat,
        Games[_game].tokenPrice[_orderId].buyByFiat,
        Games[_game].tokenPrice[_orderId].isBuy);
    }
    function setPriceFee(uint _orderId, address _game, uint[] memory _tokenIds, uint256 _Price, address[] memory _fiat) public isOwnerOf(_game, _tokenIds) isValidFiat(_fiat){
        setPrice(_orderId, _game, _tokenIds, _Price, _fiat);
        emit _setPrice(_game, _tokenIds, _Price, 1);
    }

    function setLimitFee(address _game, uint256 _Fee, uint256 _limitFee, uint256 _creatorFee) public onlyOwner {
        require(_Fee >= 0 && _limitFee >= 0);
        Games[_game].Fee = _Fee;
        Games[_game].limitFee = _limitFee;
        Games[_game].CreatorFee = _creatorFee;
        updateArrGames(_game);
    }
    function setLimitFeeAll(address[] memory _game, uint256[] memory _Fee, uint256[] memory _limitFee, uint256[] memory _creatorFee) public onlyOwner {
        require(_game.length == _Fee.length);
        for(uint i = 0; i < _game.length; i++){
            require(_Fee[i] >= 0 && _limitFee[i] >= 0);
            Games[_game[i]].Fee = _Fee[i];
            Games[_game[i]].limitFee = _limitFee[i];
            Games[_game[i]].CreatorFee = _creatorFee[i];
            updateArrGames(_game[i]);
        }
    }
    function _withdraw(uint256 amount) internal {
        require(address(this).balance >= amount);
        if(amount > 0) {
            ceoAddress.transfer(amount);
        }
    }
    function withdraw(uint256 amount, address[] memory _tokenTRC20s) public onlyOwner {
        _withdraw(amount);
        for(uint i = 0; i < _tokenTRC20s.length; i++) {
            if(_tokenTRC20s[i] != address(0)) {
                IERC20 erc20 = IERC20(_tokenTRC20s[i]);
                uint erc20Balance = erc20.balanceOf(address(this));
                if(erc20Balance > 0) {
                    erc20.transfer(ceoAddress, erc20Balance);
                }
            }
        }
    }
    function cancelBussinessByGameId(address _game, uint256 _tokenId) private {
        IERC721 erc721Address = IERC721(_game);
        if (Games[_game].tokenPrice[_tokenId].maker == erc721Address.ownerOf(_tokenId)) {
            resetPrice(_game, _tokenId);
        }
    }

    function cancelBussinessByGame(address _game) private {
        uint256[] memory _arrTokenId = Games[_game].tokenIdSale;
        for (uint i = 0; i < _arrTokenId.length; i++) {
            cancelBussinessByGameId(_game, _arrTokenId[i]);
        }

    }
    function cancelBussiness() public onlyOwner {
        for(uint j = 0; j< arrGames.length; j++) {
            address _game = arrGames[j];
            cancelBussinessByGame(_game);
        }
        withdraw(address(this).balance, fiat);
    }

    function changeCeo(address payable _address) public onlyCeoAddress {
        require(_address != address(0));
        ceoAddress = _address;

    }
    // Move the last element to the deleted spot.
    // Delete the last element, then correct the length.
    function _burnArrayTokenIdSale(address _game, uint256 index)  internal {
        if (index >= Games[_game].tokenIdSale.length) return;

        for (uint i = index; i<Games[_game].tokenIdSale.length-1; i++){
            Games[_game].tokenIdSale[i] = Games[_game].tokenIdSale[i+1];
        }
        delete Games[_game].tokenIdSale[Games[_game].tokenIdSale.length-1];
        Games[_game].tokenIdSale.pop();
    }
    function removePrice(address _game, uint _orderId) public {
        require(msg.sender == Games[_game].tokenPrice[_orderId].maker);
        resetPrice(_game, _orderId);
    }
    function resetPrice(address _game, uint256 _orderId) internal {
        Price storage _price = Games[_game].tokenPrice[_orderId];
        _price.maker = address(0);
        _price.Price2JPY = 0;
        _price.buyByFiat = address(0);
        _price.isBuy = false;
        for (uint8 i = 0; i < Games[_game].tokenIdSale.length; i++) {
            if (Games[_game].tokenIdSale[i] == _orderId) {
                _burnArrayTokenIdSale(_game, i);
            }
        }
        emit _resetPrice(_game, _orderId);
    }
    function resetPrice4sub(address _game, uint256 _tokenId) public onlySub {
        resetPrice(_game, _tokenId);
    }
}