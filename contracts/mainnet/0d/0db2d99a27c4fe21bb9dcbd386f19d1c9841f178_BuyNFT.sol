/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity 0.4.26;
pragma experimental ABIEncoderV2;
library SafeMath {
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
    constructor() public {
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;

    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transfer(address to, uint256 tokenId) public;

    function transferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract BuyNFT is Ownable {

    using SafeMath for uint256;
    address public ceoAddress;
    uint256 public Percen = 1000;
    struct Price {
        address tokenOwner;
        uint256 Price;
        uint256 fee;
    }
    struct Game {
        mapping(uint256 => Price) tokenPrice;
        uint[] tokenIdSale;
        uint256 Fee;
        uint256 limitFee;
    }

    mapping(address => Game) public Games;
    address[] public arrGames;
    constructor() public {
        ceoAddress = msg.sender;
        Games[address(0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe)].Fee = 0;
        Games[address(0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe)].limitFee = 0;
        arrGames.push(address(0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe));
    }
    function getArrGames() public view returns(address[] memory){
        return arrGames;
    }
    /**
     * @dev Throws if called by any account other than the ceo address.
     */
    modifier onlyCeoAddress() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier isOwnerOf(address _game, uint256 _tokenId) {
        IERC721 erc721Address = IERC721(_game);
        require(erc721Address.ownerOf(_tokenId) == msg.sender);
        _;
    }
    event Sell(address _user, address _game, uint256 _tokenId, uint256 _Price);
    event Buy(address _user, address _game, uint256 _tokenId, uint256 _Price);
    event _resetPrice(address _game, uint256 _tokenId);
    function ownerOf(address _game, uint256 _tokenId) public view returns (address){
        IERC721 erc721Address = IERC721(_game);
        return erc721Address.ownerOf(_tokenId);
    }

    function balanceOf() public view returns (uint256){
        return address(this).balance;
    }
    function getTokenPrice(address _game, uint256 _tokenId) public view returns (Price) {
        return Games[_game].tokenPrice[_tokenId];
    }
    
    function getApproved(address _game, uint256 _tokenId) public view returns (address){
        IERC721 erc721Address = IERC721(_game);
        return erc721Address.getApproved(_tokenId);
    }

    function setPrice(address _game, uint256 _tokenId, uint256 _price, uint256 _fee) internal {
        Games[_game].tokenPrice[_tokenId] = Price(msg.sender, _price, _fee);
        Games[_game].tokenIdSale.push(_tokenId);
        bool flag = false;
        for(uint i = 0; i< arrGames.length; i++) {
            if(arrGames[i] == _game) flag = true;
        }
        if(!flag) arrGames.push(_game);
    }

    function calFee(address _game, uint256 _price) public view returns (uint fee){
        fee =_price.mul(Games[_game].Fee).div(Percen);
    }
    function calPrice(address _game, uint256 _tokenId, uint256 _Price) public view returns(uint256 _Need) {
        uint256 fee;
        uint256 totalFee;
        if (Games[_game].tokenPrice[_tokenId].Price < _Price) {
            fee = calFee(_game, _Price.sub(Games[_game].tokenPrice[_tokenId].Price));
            totalFee = calFee(_game, _Price);
            if(Games[_game].tokenPrice[_tokenId].Price == 0 && fee < Games[_game].limitFee) {
                _Need = Games[_game].limitFee;
            } else if(Games[_game].tokenPrice[_tokenId].Price > 0 && totalFee < Games[_game].limitFee) {
                _Need = 0;
            } else {
                if(totalFee < Games[_game].tokenPrice[_tokenId].fee) _Need = 0;
                else _Need = totalFee.sub(Games[_game].tokenPrice[_tokenId].fee);
            }

        }
    }
    function sell(address _game, uint256 _tokenId, uint256 _Price) public payable isOwnerOf(_game, _tokenId) {
        IERC721 erc721Address = IERC721(_game);
        if(erc721Address.ownerOf(_tokenId) != Games[_game].tokenPrice[_tokenId].tokenOwner && erc721Address.ownerOf(_tokenId) != address(this)) resetPrice(_game, _tokenId);
        require(Games[_game].tokenPrice[_tokenId].Price != _Price);
        uint256 Need = calPrice(_game, _tokenId, _Price);

        require(msg.value >= Need);
        uint256 fee;
        if (Games[_game].tokenPrice[_tokenId].Price < _Price) {
            fee = calFee(_game, _Price.sub(Games[_game].tokenPrice[_tokenId].Price));
            uint256 totalFee = calFee(_game, _Price);

            if(Games[_game].tokenPrice[_tokenId].Price == 0 && fee < Games[_game].limitFee) {

                fee = Games[_game].limitFee;
            } else if(Games[_game].tokenPrice[_tokenId].Price > 0 && totalFee < Games[_game].limitFee) {

                fee = 0;
            } else {
                if(totalFee < Games[_game].tokenPrice[_tokenId].fee) fee = 0;
                else fee = totalFee.sub(Games[_game].tokenPrice[_tokenId].fee);
            }
            fee = fee.add(Games[_game].tokenPrice[_tokenId].fee);
        } else {

            fee = Games[_game].tokenPrice[_tokenId].fee;
        }

        setPrice(_game, _tokenId, _Price, fee);
        emit Sell(msg.sender, _game, _tokenId, _Price);
    }

    function removePrice(address _game, uint256 _tokenId) public isOwnerOf(_game, _tokenId){
        msg.sender.transfer(Games[_game].tokenPrice[_tokenId].fee);
        if(Games[_game].tokenPrice[_tokenId].tokenOwner == address(this)) {
            IERC721 erc721Address = IERC721(_game);
            erc721Address.transfer(Games[_game].tokenPrice[_tokenId].tokenOwner, _tokenId);
        }
        resetPrice(_game, _tokenId);
    }

    function setLimitFee(address _game, uint256 _Fee, uint256 _limitFee) public onlyOwner {
        require(_Fee >= 0 && _limitFee >= 0);
        Games[_game].Fee = _Fee;
        Games[_game].limitFee = _limitFee;
    }
    function setLimitFeeAll(address[] memory _game, uint256[] memory _Fee, uint256[] memory _limitFee) public onlyOwner {
        require(_game.length == _Fee.length);
        for(uint i = 0; i < _game.length; i++){
            require(_Fee[i] >= 0 && _limitFee[i] >= 0);
            Games[_game[i]].Fee = _Fee[i];
            Games[_game[i]].limitFee = _limitFee[i];
        }
    }
    function _withdraw(uint256 amount) internal {
        require(address(this).balance >= amount);
        if(amount > 0) {
            msg.sender.transfer(amount);
        }
    }
    function withdraw(uint256 amount) public onlyCeoAddress {
        _withdraw(amount);
    }
    function cancelBussinessByGameId(address _game, uint256 _tokenId) private {
        IERC721 erc721Address = IERC721(_game);
        if (Games[_game].tokenPrice[_tokenId].tokenOwner == erc721Address.ownerOf(_tokenId)
        || Games[_game].tokenPrice[_tokenId].tokenOwner == address(this)) {

            uint256 amount = Games[_game].tokenPrice[_tokenId].fee;
            if( amount > 0 && address(this).balance >= amount) {
                Games[_game].tokenPrice[_tokenId].tokenOwner.transfer(amount);
            }
            if(Games[_game].tokenPrice[_tokenId].tokenOwner == address(this)) erc721Address.transfer(Games[_game].tokenPrice[_tokenId].tokenOwner, _tokenId);
            resetPrice(_game, _tokenId);
        }
    }

    function cancelBussinessByGame(address _game) private {
        uint256[] memory _arrTokenId = Games[_game].tokenIdSale;
        for (uint i = 0; i < _arrTokenId.length; i++) {
            cancelBussinessByGameId(_game, _arrTokenId[i]);
        }

    }
    function cancelBussiness() public onlyCeoAddress {
        for(uint j = 0; j< arrGames.length; j++) {
            address _game = arrGames[j];
            cancelBussinessByGame(_game);
        }
        _withdraw(address(this).balance);
    }

    function revenue() public view returns (uint256){
        uint256 fee;
        for(uint j = 0; j< arrGames.length; j++) {
            address _game = arrGames[j];
            IERC721 erc721Address = IERC721(arrGames[j]);
            for (uint i = 0; i < Games[_game].tokenIdSale.length; i++) {
                uint256 _tokenId = Games[_game].tokenIdSale[i];
                if (Games[_game].tokenPrice[_tokenId].tokenOwner == erc721Address.ownerOf(_tokenId)) {

                    fee = fee.add(Games[_game].tokenPrice[_tokenId].fee);
                }
            }
        }

        uint256 amount = address(this).balance.sub(fee);
        return amount;
    }

    function changeCeo(address _address) public onlyCeoAddress {
        require(_address != address(0));
        ceoAddress = _address;

    }

    function buy(address _game, uint256 tokenId) public payable {
        IERC721 erc721Address = IERC721(_game);
        require(erc721Address.getApproved(tokenId) == address(this));
        require(Games[_game].tokenPrice[tokenId].Price > 0 && Games[_game].tokenPrice[tokenId].Price == msg.value);
        erc721Address.transferFrom(Games[_game].tokenPrice[tokenId].tokenOwner, msg.sender, tokenId);
        Games[_game].tokenPrice[tokenId].tokenOwner.transfer(msg.value);
        resetPrice(_game, tokenId);
        emit Buy(msg.sender, _game, tokenId, msg.value);
    }
    function _burnArrayTokenIdSale(address _game, uint256 index)  internal {
        if (index >= Games[_game].tokenIdSale.length) return;

        for (uint i = index; i<Games[_game].tokenIdSale.length-1; i++){
            Games[_game].tokenIdSale[i] = Games[_game].tokenIdSale[i+1];
        }
        delete Games[_game].tokenIdSale[Games[_game].tokenIdSale.length-1];
        Games[_game].tokenIdSale.length--;
    }

    function resetPrice(address _game, uint256 _tokenId) private {
        Games[_game].tokenPrice[_tokenId] = Price(address(0), 0, 0);
        for (uint8 i = 0; i < Games[_game].tokenIdSale.length; i++) {
            if (Games[_game].tokenIdSale[i] == _tokenId) {
                _burnArrayTokenIdSale(_game, i);
            }
        }
        emit _resetPrice(_game, _tokenId);
    }
}