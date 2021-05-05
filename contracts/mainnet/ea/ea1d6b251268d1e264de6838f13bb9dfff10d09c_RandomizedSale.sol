/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 value, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns(uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
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
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RandomizedSale is Ownable {
    using SafeMath for uint256;
    
    uint256 constant public MAX_SUPPLY = 17;
    
    IERC1155  public nft;
    uint256   public price = 0.5 ether;
    uint256   public id;
    uint256   public offset;
    uint256   public start;
    uint256   public idToSend;
    uint256   public maxId;
    uint256   public amountSold = 0;
    bool      public ended = false;
    
    address[] public buyers;
    mapping(address => bool) public buyerMapping; // key is address, value is boolean where true means they already bought
    
    address payable public haus;
    address payable public seller;
    
    event Buy(address buyer, uint256 amount);
    
    constructor() public {
        start = 1620154800;
        id = 72;
        maxId  = id + MAX_SUPPLY - 1;
        
        nft = IERC1155(0x13bAb10a88fc5F6c77b87878d71c9F1707D2688A);
        seller = payable(address(0x15884D7a5567725E0306A90262ee120aD8452d58));
        haus = payable(address(0x38747BAF050d3C22315a761585868DbA16abFD89));
    }
    
    function buy(uint256 amount) public payable {
        require(amountSold + buyers.length < MAX_SUPPLY, "sold out");
        require(!buyerMapping[msg.sender], "already purchased");
        require(msg.sender == tx.origin, "no contracts");
        require(block.timestamp >= start, "early");
        require(amount <= MAX_SUPPLY, "ordered too many");
        require(amount <= 1, "ordered too many");
        require(msg.value == price.mul(amount), "wrong amount");
        
        uint256 balance = address(this).balance;
        uint256 hausFee = balance.div(20).mul(3);
        haus.transfer(hausFee);
        seller.transfer(address(this).balance);
        
        buyerMapping[msg.sender] = true;
        buyers.push(msg.sender);
        emit Buy(msg.sender, amount);
    }
    
    function supply() public view returns(uint256) {
        return MAX_SUPPLY.sub(amountSold);
    }
    
    function supply(uint256 _id) public view returns(uint256) {
        return nft.balanceOf(address(this), _id);
    }
    
    function end() public onlyOwner {
        if (!ended) {
            ended = true;
            offset = generateRandom();
            idToSend = id.add(offset);
        }
        
        uint256 balance = address(this).balance;
        uint256 hausFee = balance.div(20).mul(3);
        haus.transfer(hausFee);
        seller.transfer(address(this).balance);
    }
    
    function distribute() public onlyOwner {
        if (!ended) {
            return;
        }
        
        for (uint i = 0; i < buyers.length; i++) {
            address toSendTo = buyers[i];

            nft.safeTransferFrom(address(this), toSendTo, idToSend, 1, new bytes(0x0));
            
            buyerMapping[toSendTo] = false;
            
            idToSend = idToSend.add(1);
            if (idToSend > maxId) {
                idToSend = id;
            }
        }
        
        amountSold = amountSold.add(buyers.length);
        delete buyers;
    }
    
    function generateRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, block.difficulty)))%(MAX_SUPPLY);
    }
    
    function pull(uint256 _id) public onlyOwner {
        nft.safeTransferFrom(address(this), seller, _id, 1, new bytes(0x0));
    }
    
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}