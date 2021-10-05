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
interface BuyNFT {
    function tokensFiat(address token) external view returns (string memory symbol, bool existed);
    function tokenId2wei(address _game, uint256 _tokenId, address _fiatBuy) external view returns(uint256);
    function Games(address _game) external view returns(uint256, uint256, uint256);
    function getTokensFiat(address _fiat) external view returns(string memory _symbol, bool _existed);
    function Percen() external view returns(uint256);
    function resetPrice4sub(address _game, uint256 _tokenId) external;
    function ceoAddress() external view returns(address);
    function fiatContract() external view returns(address);
    function getTokenPrice(address _game, uint _orderId) external view returns(address payable _maker, uint[] memory _tokenIds, uint _Price2USD, address[] memory _fiat, address _buyByFiat, bool _isBuy);
}
interface FIATContract {
    function getToken2JPY(string memory __symbol) external view returns (string memory _symbolToken, uint _token2JPY);
}
contract BuyNFTSub is Ownable{
    using SafeMath for uint256;
    address buynftAddress = address(0x1e60Fa3ed2618D21756C0fB2C1A1abCE1e05e984);
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
    function tobuySub(address _game, address _fiatBuy, uint256 weiPrice, address payable _maker, uint256 ownerProfit, uint256 creatorProfit, uint256 businessProfit, uint tokenId) internal{
        IERC721 erc721Address = IERC721(_game);
        address payable ceo = payable(buynft.ceoAddress());
        if(_fiatBuy == address(0)) {
            require(weiPrice <= msg.value);
            if(ownerProfit > 0) _maker.transfer(ownerProfit);
            if(businessProfit > 0) ceo.transfer(businessProfit);
            if(creatorProfit > 0) {
                address payable creator;
                (creator) = payable(erc721Address.metadata(tokenId));
                creator.transfer(creatorProfit);
            }

        }
        else {
            IERC20 trc21 = IERC20(_fiatBuy);
            uint256 fee = trc21.estimateFee(weiPrice);
            uint256 totalRequiree = fee.add(weiPrice);
            if(businessProfit > 0) totalRequiree = totalRequiree.add(trc21.estimateFee(businessProfit));
            if(creatorProfit > 0) totalRequiree = totalRequiree.add(trc21.estimateFee(creatorProfit));
            require(trc21.transferFrom(msg.sender, address(this), totalRequiree));
            if(ownerProfit > 0) trc21.transfer(_maker, ownerProfit);
            if(businessProfit > 0) trc21.transfer(ceo, businessProfit);
            if(creatorProfit > 0) {
                address creatorr;
                (creatorr) = erc721Address.metadata(tokenId);
                trc21.transfer(creatorr, creatorProfit);
            }
        }
    }
    function calBusinessFee(address _game, string memory _symbolFiatBuy, uint256 weiPrice) public view
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
    function tobuy(address _game, uint _orderId, address _fiatBuy, string memory _symbolFiatBuy, address payable _maker, uint tokenId) internal {
        uint256 weiPrice = buynft.tokenId2wei(_game, _orderId, _fiatBuy);
        uint256 businessProfit;
        uint256 creatorProfit;
        (businessProfit, creatorProfit) = calBusinessFee(_game, _symbolFiatBuy, weiPrice);
        uint256 ownerProfit = (weiPrice.sub(businessProfit)).sub(creatorProfit);

        tobuySub(_game, _fiatBuy, weiPrice, _maker, ownerProfit, creatorProfit, businessProfit, tokenId);

    }
    function buy(address _game, uint _orderId, address _fiatBuy, string memory _symbolFiatBuy) public payable isValidFiatBuy(_fiatBuy){
        // address[] _fiat luon luon truyen empty .
        address payable _maker;
        uint[] memory _tokenIds;
        (_maker, _tokenIds, , ,,) = buynft.getTokenPrice(_game, _orderId);
        IERC721 erc721Address = IERC721(_game);
        require(erc721Address.isApprovedForAll(_maker, address(this)));
        tobuy(_game, _orderId, _fiatBuy, _symbolFiatBuy, _maker, _tokenIds[0]);
        for(uint i = 0; i < _tokenIds.length; i++) {
            erc721Address.transferFrom(_maker, msg.sender, _tokenIds[i]);
        }
        
        buynft.resetPrice4sub(_game, _orderId);
    }

}