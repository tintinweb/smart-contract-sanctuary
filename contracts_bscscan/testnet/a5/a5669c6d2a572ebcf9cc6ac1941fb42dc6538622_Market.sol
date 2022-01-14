/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;

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

/**
 * @title TRC21 interface
 */
interface ITRC21 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function issuer() external view returns (address);

    function estimateFee(uint256 value) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Fee(address indexed from, address indexed to, address indexed issuer, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ITRC721 {
    function transferFrom(address from, address to, uint256 tokenId) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function metadata(uint256 tokenId) public view returns (address creator);
    function transfer(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
}
contract FIATContract {
    function getToken2JPY(string __symbol) public view returns (string _symbolToken, uint _token2JPY);
}
contract Market is Ownable{
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    struct Token {
        string symbol;
        bool existed;
    }
    mapping(address => Token) public tokensFiat;
    address[] public fiat = [
    address(0), // BNB
    address(0x7B65496Ca742374362970c36AC1C69E641aD997e) // XCJ
    ];
    FIATContract public fiatContract;
    constructor () public {
        tokensFiat[address(0)] = Token('BNB', true);
        tokensFiat[address(0x7B65496Ca742374362970c36AC1C69E641aD997e)] = Token('G', true);
    }

    // ==================
    using SafeMath for uint256;
    address public BuyNFTSub;
    address public ceoAddress = address(0x64470E5F5DD38e497194BbcAF8Daa7CA578926F6);
    uint256 public Percen = 1000;

    struct Price {
        address tokenOwner;
        uint256 Price2JPY;
        address[] fiat;
        address buyByFiat;
        bool isBuy;
    }
    struct Game {
        mapping(uint256 => Price) tokenPrice;
        // mapping(uint => )
        // uint[] tokenIdSale;
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
    modifier isOwnerOf(address _game, uint256 _tokenId) {
        ITRC721 erc721Address = ITRC721(_game);
        require(erc721Address.ownerOf(_tokenId) == msg.sender);
        _;
    }
    modifier isValidFiat(address[] _fiat) {
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
    event _setPrice(address _game, uint256 _tokenId, uint256 _Price, uint8 _type);
    event _resetPrice(address _game, uint256 _tokenId);
    function () public payable {}
    function getFiat() public view returns (address[]) {
        return fiat;
    }
    function setBuyNFTSub(address _sub) public onlyOwner {
        BuyNFTSub = _sub;
    }
    function setFiat(string[] _symbols, address[] addrrs) public onlyOwner {

        for(uint i = 0; i < _symbols.length; i++) {
            tokensFiat[addrrs[i]].symbol = _symbols[i];
            if(!tokensFiat[addrrs[i]].existed) {
                fiat.push(addrrs[i]);
                tokensFiat[addrrs[i]].existed = true;
            }
        }
        emit SetFiat(_symbols, addrrs, msg.sender);
    }
    function getTokensFiat(address _fiat) public view returns(string __symbol, bool _existed) {
        return (tokensFiat[_fiat].symbol, tokensFiat[_fiat].existed);
    }
    function price2wei(uint256 _price, address _fiatBuy) public view returns(uint256) {
        uint weitoken;
        (, weitoken) = fiatContract.getToken2JPY(tokensFiat[_fiatBuy].symbol);
        return _price.mul(weitoken).div(1 ether);
    }
    function tokenId2wei(address _game, uint256 _tokenId, address _fiatBuy) public view returns(uint256) {
        uint weitoken;
        uint _price = Games[_game].tokenPrice[_tokenId].Price2JPY;
        (, weitoken) = fiatContract.getToken2JPY(tokensFiat[_fiatBuy].symbol);
        return _price.mul(weitoken).div(1 ether);
    }
    function setFiatContract(address _fiatContract) public onlyOwner {
        fiatContract = FIATContract(_fiatContract);
    }
    function getTokenPrice(address _game, uint256 _tokenId, address[] _fiat2Reset) public
    returns(address _tokenOwner, uint256 _Price2JPY, address[] _fiat, address _buyByFiat, bool _isBuy) {
        ITRC721 erc721Address = ITRC721(_game);
        if(erc721Address.ownerOf(_tokenId) != Games[_game].tokenPrice[_tokenId].tokenOwner
        && erc721Address.ownerOf(_tokenId) != address(this)) resetPrice(_game, _tokenId, _fiat2Reset);

        return (Games[_game].tokenPrice[_tokenId].tokenOwner,
        Games[_game].tokenPrice[_tokenId].Price2JPY,
        Games[_game].tokenPrice[_tokenId].fiat,
        Games[_game].tokenPrice[_tokenId].buyByFiat,
        Games[_game].tokenPrice[_tokenId].isBuy);

    }
    function getArrGames() public view returns(address[] memory){
        return arrGames;
    }
    function ownerOf(address _game, uint256 _tokenId) public view returns (address){
        ITRC721 erc721Address = ITRC721(_game);
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
    function setPrice(address _game, uint256 _tokenId, uint256 _price, address[] _fiat) internal {
        Games[_game].tokenPrice[_tokenId] = Price(msg.sender, _price, _fiat, address(0), false);
        // Games[_game].tokenIdSale.push(_tokenId);
        updateArrGames(_game);
    }

    function calFee(address _game, uint256 _price) public view returns (uint256){
        uint256 fee =_price.mul(Games[_game].Fee).div(Percen);

        return fee;
    }

    function calPrice(address _game, uint256 _tokenId) public view
    returns(address _tokenOwner, uint256 _Price2JPY, address[] _fiat, address _buyByFiat, bool _isBuy) {
        return (Games[_game].tokenPrice[_tokenId].tokenOwner,
        Games[_game].tokenPrice[_tokenId].Price2JPY,
        Games[_game].tokenPrice[_tokenId].fiat,
        Games[_game].tokenPrice[_tokenId].buyByFiat,
        Games[_game].tokenPrice[_tokenId].isBuy);
    }
    function setPriceFee(address _game, uint256 _tokenId, uint256 _Price, address[] _fiat) public
    isOwnerOf(_game, _tokenId) isValidFiat(_fiat){

        setPrice(_game, _tokenId, _Price, _fiat);
        emit _setPrice(_game, _tokenId, _Price, 1);
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
    function withdraw(uint256 amount, address[] _tokenTRC21s, uint256[] _amountTRC21s) public onlyOwner {
        _withdraw(amount);
        for(uint256 i = 0; i < _tokenTRC21s.length; i++) {
            if(_tokenTRC21s[i] != address(0)) {
                ITRC21 trc21 = ITRC21(_tokenTRC21s[i]);
                require(trc21.balanceOf(address(this)) >= _amountTRC21s[i]);
                if(_amountTRC21s[i] > 0) {
                    trc21.transfer(ceoAddress, _amountTRC21s[i]);
                }
            }
        }
    }
    function cancelBussinessByGameId(address _game, uint256 _tokenId, address[] _fiat) private {
        ITRC721 erc721Address = ITRC721(_game);
        if (Games[_game].tokenPrice[_tokenId].tokenOwner == erc721Address.ownerOf(_tokenId)) {
            resetPrice(_game, _tokenId, _fiat);
        }
    }


    function changeCeo(address _address) public onlyCeoAddress {
        require(_address != address(0));
        ceoAddress = _address;

    }

    function removePrice(address _game, uint256 _tokenId, address[] _fiat) public isOwnerOf(_game, _tokenId){
        resetPrice(_game, _tokenId, _fiat);
    }
    function resetPrice(address _game, uint256 _tokenId, address[] _fiat) internal {
        Games[_game].tokenPrice[_tokenId] = Price(address(0), 0, _fiat, address(0), false);

        emit _resetPrice(_game, _tokenId);
    }
    function resetPrice4sub(address _game, uint256 _tokenId, address[] _fiat) public onlySub {
        resetPrice(_game, _tokenId, _fiat);
    }
}