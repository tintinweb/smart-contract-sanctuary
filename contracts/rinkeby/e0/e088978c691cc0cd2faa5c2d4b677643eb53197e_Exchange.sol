/**
 *Submitted for verification at Etherscan.io on 2021-10-06
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
contract Exchange is Ownable{
    event MakeOrder(address maker, uint256 index, string orderId);
    event CancelOrder(address maker, uint256 index);
    event ExchangeNFT(address sender, uint256 index, IERC721 NFTTo, uint256 tokenIdTo);
    
    using SafeMath for uint256;
    IERC20 public feeToken = IERC20(0x18d4d562465DF77DA8171Ec244eA21b1DBBAE0D6);
    address public signer = 0x64470E5F5DD38e497194BbcAF8Daa7CA578926F6;
    uint public feeExchange = 40;
    uint public panaltyPercent = 20;
    modifier onlySigner() {
        require(signer == msg.sender);
        _;
    }
    struct order {
        string _orderId;
        IERC721 _NFTFrom;
        uint _tokenIdFrom;
        uint status; // 1 waiting; 2 finish; 3 canceled
        string _type;
    }
    mapping(address => order[]) public orders;
    function getMessageHash(uint timestamp, uint _tokenIdTo) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(timestamp, _tokenIdTo));
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function permit(uint timestamp, uint _tokenIdTo, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return ecrecover(getEthSignedMessageHash(getMessageHash(timestamp, _tokenIdTo)), v, r, s) == signer;
    }
    
    function getOrders(address _from) public view returns(order[] memory){
        return orders[_from];
    }
    function getFee() public view returns(uint) {
        uint decimal = feeToken.decimals();
        return feeExchange.mul(10**decimal);
    }
    function makeOrder(string memory _orderId, IERC721 _NFTFrom, uint _tokenIdFrom, string memory _type) public {
        require(feeToken.transferFrom(msg.sender, address(this), getFee()));
        orders[msg.sender].push(order(_orderId, _NFTFrom, _tokenIdFrom, 1, _type));
        emit MakeOrder(msg.sender, orders[msg.sender].length - 1, _orderId);
    }
    function cancelOrder(uint _index) public {
        require(orders[msg.sender][_index].status == 1);
        require(feeToken.transfer(msg.sender, getFee().mul(100-panaltyPercent).div(100)));
        orders[msg.sender][_index].status = 3;
        emit CancelOrder(msg.sender, _index);
    }
    function exchange(address _From, uint _index, IERC721 _NFTTo, uint _tokenIdTo, uint timestamp, uint8 v, bytes32 r, bytes32 s) public {
        require(orders[_From][_index].status == 1);
        require(permit(timestamp, _tokenIdTo, v, r, s));
        require(feeToken.transferFrom(msg.sender, address(this), getFee()));
        _NFTTo.transferFrom(msg.sender, _From, _tokenIdTo);
        orders[_From][_index]._NFTFrom.transferFrom(_From, msg.sender, orders[_From][_index]._tokenIdFrom);
        orders[_From][_index].status = 2;
        emit ExchangeNFT(msg.sender, _index, _NFTTo, _tokenIdTo);
    }
    function configSigner(address _signer) public onlySigner {
        signer = _signer;
    }
    function config(IERC20 _feeToken, uint _feeExchange, uint _panaltyPercent) public onlyOwner {
        feeToken = _feeToken;
        feeExchange = _feeExchange;
        panaltyPercent = _panaltyPercent;
    }
    function withdraw(IERC20 _token, uint _amount, address _to) public onlyOwner {
        _token.transfer(_to, _amount);
    }
}