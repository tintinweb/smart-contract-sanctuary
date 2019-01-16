pragma solidity ^0.5.0;
// pragma experimental ABIEncoderV2;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract InvestorWallet {
    address payable public creator;
    MysteriousBox public parent;

    constructor(address payable _creator) public {
        creator = _creator;
        parent = MysteriousBox(msg.sender);
    }

    function() external payable {}

    modifier onlyOwner() {
        require(msg.sender == creator);
        _;
    }

    function tokenFallback(address _from, uint _value, bytes memory _data) public pure {
        (_from);
        (_value);
        (_data);
    }

    function withdraw(address _token, uint _amount) public onlyOwner returns (bool _success) {
        if (address(0) == _token) {
            _success = creator.send(_amount);
        } else {
            ERC20 token = ERC20(_token);
            require(token.balanceOf(creator) >= _amount);
            _success = token.transfer(creator, _amount);
        }
    }

    function invest() public onlyOwner {
        parent.createBox();
    }


}


contract MysteriousBox is Ownable {

    using SafeMath for uint;
    uint public openPrice = 0.1 ether;

    uint private _nonce = 1;
    uint private _boxesLength = 0;
    uint private _boxesOpenedLength = 0;

    mapping(address => address) public investors;

    event BoxCreated(uint _boxIndex, address _creator);
    event BoxOpened(uint _boxIndex, address _opener);
    event BoxItemFound(uint _boxIndex, address _opener, address _item, uint _amount);

    event InvestorWalletCreated(address _wallet, address _creator);

    struct Item {
        address token;
        uint amount;
    }

    struct Box {
        uint index;
        bool opened;
        address opener;
        address creator;
        uint8 itemLength;
        uint createdAt;
        uint openedAt;
        mapping(uint => Item) items;
    }

    mapping(uint => Box) private boxes;
    mapping(address => bool) public tokens;

    constructor() public {}

    function addToken(address _token) public onlyOwner {
        require(_token != address(0));
        tokens[_token] = true;
    }

    function removeToken(address _token) public onlyOwner {
        require(_token != address(0));
        tokens[_token] = false;
    }

    function registerInvestor() public returns (address wallet) {
        wallet = address(new InvestorWallet(msg.sender));
        investors[msg.sender] = wallet;
        emit InvestorWalletCreated(wallet, msg.sender);
    }

    function openBox(uint _boxIndex) public payable {
        //        require(msg.value > openPrice);
        _openBox(_boxIndex);
    }

    function createBox() public onlyOwner returns (uint _id) {
        _id = _boxesLength++;

        Box storage box = boxes[_id];
        box.index = _id;
        box.opened = false;
        box.creator = msg.sender;
        box.itemLength = 3;
        box.createdAt = block.timestamp;

        for (uint8 i = 0; i < box.itemLength; i++) {
            box.items[i].token = address(i);
            box.items[i].amount = i;
            //            Item storage item = box.items[i];
            //            item.token = address(i);
            //            item.amount = i;
        }
        emit BoxCreated(_id, msg.sender);
    }

    function _openBox(uint _boxIndex) internal {
        require(boxes[_boxIndex].opened == false);
        boxes[_boxIndex].opened = true;
        boxes[_boxIndex].opener = msg.sender;
        emit BoxOpened(boxes[_boxIndex].index, msg.sender);
        for (uint i = 0; i < boxes[_boxIndex].itemLength; i++) {
            _sendReward(msg.sender, boxes[_boxIndex].items[i].token, boxes[_boxIndex].items[i].amount);
            emit BoxItemFound(
                boxes[_boxIndex].index,
                msg.sender,
                boxes[_boxIndex].items[i].token,
                boxes[_boxIndex].items[i].amount
            );
        }
        _boxesOpenedLength++;
    }

    function _sendReward(address _player, address _token, uint _amount) internal returns (bool _success) {
        _success = false;
        if (address(_token) == address(0)) {
            // Send ETH
        } else {
            ERC20 token = ERC20(_token);
            _success = token.transfer(_player, _amount);
        }
    }

    function _random(uint length) private returns (uint)
    {
        _nonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _nonce))) % length;
    }

    function _getFilteredBoxes(bool status) private view returns (Box[] memory _boxes) {
        for (uint i = 0; i < _boxesLength; i++) {
            if (boxes[i].opened == status) {
                _boxes[i] = boxes[i];
            }
        }
        return _boxes;
    }

}