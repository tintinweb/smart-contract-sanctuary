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
    function estimateFee(uint256 value) public view returns (uint256);
}
contract BuyNFT {
    function tokensFiat(address token) public view returns (string symbol, bool existed);
    function tokenId2wei(address _game, uint256 _tokenId, address _fiatBuy) public view returns(uint256);
    function Games(address _game) public view returns(uint256, uint256, uint256);
    function getTokensFiat(address _fiat) public view returns(string _symbol, bool _existed);
    function Percen() public view returns(uint256);
    function resetPrice4sub(address _game, uint256 _tokenId, address[] _fiat) public;
    function ceoAddress() public view returns(address);
    function fiatContract() public view returns(address);
}
contract FIATContract {
    function getToken2JPY(string __symbol) public view returns (string _symbolToken, uint _token2JPY);
}
contract MarketSub is Ownable{
    constructor () public {
    }
    // ==================
    using SafeMath for uint256;
    address buynftAddress = address(0);
    BuyNFT public buynft = BuyNFT(buynftAddress);

    modifier isValidFiatBuy(address _fiat) {
        bool existed;
        (, existed) = buynft.getTokensFiat(_fiat);
        require(existed);
        _;
    }
    function setBuyNFT(address _buyNFT) public onlyOwner {
        buynftAddress = _buyNFT;
        buynft = BuyNFT(buynftAddress);
    }
    function tobuySub(address _fiatBuy, uint256 weiPrice, address tokenOwner, uint256 ownerProfit, uint256 creatorProfit,
        ITRC721 erc721Address, uint256 tokenId, uint256 businessProfit) internal{
        address ceo = buynft.ceoAddress();
        if(_fiatBuy == address(0)) {
            require(weiPrice <= msg.value);
            if(ownerProfit > 0) tokenOwner.transfer(ownerProfit);
            if(businessProfit > 0) ceo.transfer(businessProfit);
            if(creatorProfit > 0) {
                address creator;
                (creator) = erc721Address.metadata(tokenId);
                creator.transfer(creatorProfit);
            }

        }
        else {
            ITRC21 trc21 = ITRC21(_fiatBuy);
            uint256 fee = trc21.estimateFee(weiPrice);
            uint256 totalRequiree = fee.add(weiPrice);
            if(businessProfit > 0) totalRequiree = totalRequiree.add(trc21.estimateFee(businessProfit));
            if(creatorProfit > 0) totalRequiree = totalRequiree.add(trc21.estimateFee(creatorProfit));
            require(trc21.transferFrom(msg.sender, address(this), totalRequiree));
            if(ownerProfit > 0) trc21.transfer(tokenOwner, ownerProfit);
            if(businessProfit > 0) trc21.transfer(ceo, businessProfit);
            if(creatorProfit > 0) {
                address creatorr;
                (creatorr) = erc721Address.metadata(tokenId);
                trc21.transfer(creatorr, creatorProfit);
            }
        }
    }
    function tobuy1(address _game, uint256 tokenId, address _fiatBuy, string _symbolFiatBuy)
    public view returns(uint256, uint256, uint256) {
        uint256 weiPrice = buynft.tokenId2wei(_game, tokenId, _fiatBuy);
        uint256 businessProfit;
        uint256 creatorProfit;
        (businessProfit, creatorProfit) = calBusinessFee(_game, _symbolFiatBuy, weiPrice);
        uint256 ownerProfit = (weiPrice.sub(businessProfit)).sub(creatorProfit);

        return (creatorProfit, businessProfit, ownerProfit);

    }
    function calBusinessFee(address _game, string _symbolFiatBuy, uint256 weiPrice) public view
    returns (uint256 _businessProfit, uint256 _creatorProfit) {
        uint256 Fee;
        uint256 limitFee;
        uint256 CreatorFee;
        (Fee, limitFee, CreatorFee) = buynft.Games(_game);
        uint256 businessProfit = (weiPrice.mul(Fee)).div(buynft.Percen());
        FIATContract fiatCT = FIATContract(buynft.fiatContract());
        uint256 tokenOnJPY;
        (, tokenOnJPY) = fiatCT.getToken2JPY(_symbolFiatBuy);
        uint256 limitFee2Token = (tokenOnJPY.mul(limitFee)).div(1 ether);
        if(weiPrice > 0 && businessProfit < limitFee2Token) businessProfit = limitFee2Token;
        uint256 creatorProfit = (weiPrice.mul(CreatorFee)).div(buynft.Percen());
        return (businessProfit, creatorProfit);
    }
    function tobuy(address _game, uint256 tokenId, address _fiatBuy, string _symbolFiatBuy, ITRC721 erc721Address, address tokenOwner) internal {
        uint256 weiPrice = buynft.tokenId2wei(_game, tokenId, _fiatBuy);
        uint256 businessProfit;
        uint256 creatorProfit;
        (businessProfit, creatorProfit) = calBusinessFee(_game, _symbolFiatBuy, weiPrice);
        uint256 ownerProfit = (weiPrice.sub(businessProfit)).sub(creatorProfit);

        tobuySub(_fiatBuy, weiPrice, tokenOwner, ownerProfit, creatorProfit, erc721Address, tokenId, businessProfit);

    }
    function buy(address __game, uint256 tokenId, address _fiatBuy, string _symbolFiatBuy, address[] _fiat) public payable isValidFiatBuy(_fiatBuy){
        // address[] _fiat luon luon truyen empty .
        address _game = __game;

        ITRC721 erc721Address = ITRC721(_game);
        require(erc721Address.getApproved(tokenId) == address(this));
        address tokenOwner = erc721Address.ownerOf(tokenId);
        tobuy(_game, tokenId, _fiatBuy, _symbolFiatBuy, erc721Address, tokenOwner);
        erc721Address.transferFrom(tokenOwner, msg.sender, tokenId);
        buynft.resetPrice4sub(_game, tokenId, _fiat);
    }

}