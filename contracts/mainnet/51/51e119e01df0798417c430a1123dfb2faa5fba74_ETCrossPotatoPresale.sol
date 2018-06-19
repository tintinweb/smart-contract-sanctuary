pragma solidity ^0.4.21;

// SafeMath is a part of Zeppelin Solidity library
// licensed under MIT License
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/LICENSE

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract Owned {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /// @dev Contract constructor
    function Owned() public {
        owner = msg.sender;
    }
}


contract ETCrossPotatoPresale is Owned {
    using SafeMath for uint;

    uint256 public auctionEnd;
    uint256 public itemType;

    address public highestBidder;
    uint256 public highestBid = 0.001 ether;
    bool public ended;

    event Bid(address from, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    ETCrossPotatoPresale public sibling;
    address public potatoOwner = 0xf3a2727a3447653a58D57e4be63d5D5cdc55421B;

    function ETCrossPotatoPresale(uint256 _auctionEnd, uint256 _itemType) public {
        auctionEnd = _auctionEnd;
        itemType = _itemType;
    }

    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function auctionExpired() public view returns (bool) {
        return now > auctionEnd;
    }

    function nextBid() public view returns (uint256) {
        if (highestBid < 0.1 ether) {
            return highestBid.add(highestBid / 2);
        } else if (highestBid < 1 ether) {
            return highestBid.add(highestBid.mul(15).div(100));
        } else {
            return highestBid.add(highestBid.mul(4).div(100));
        }
    }

    function() public payable {
        require(!_isContract(msg.sender));
        require(!auctionExpired());

        uint256 requiredBid = nextBid();

        require(msg.value >= requiredBid);

        uint256 change = msg.value.sub(requiredBid);

        uint256 difference = requiredBid.sub(highestBid);
        uint256 reward = difference / 4;

        if (highestBidder != 0x0) {
            highestBidder.transfer(highestBid.add(reward));
        }

        if (address(sibling) != 0x0) {
            address siblingHighestBidder = sibling.highestBidder();
            if (siblingHighestBidder != 0x0) {
                siblingHighestBidder.transfer(reward / 2);
            }
        }

        if (potatoOwner != 0x0) {
            potatoOwner.transfer(reward / 10);
        }

        if (change > 0) {
            msg.sender.transfer(change);
        }

        highestBidder = msg.sender;
        highestBid = requiredBid;

        emit Bid(msg.sender, requiredBid);
    }

    function endAuction() public onlyOwner {
        require(auctionExpired());
        require(!ended);

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        owner.transfer(address(this).balance);
    }

    function setSibling(address _sibling) public onlyOwner {
        sibling = ETCrossPotatoPresale(_sibling);
    }

    function setPotatoOwner(address _potatoOwner) public onlyOwner {
        potatoOwner = _potatoOwner;
    }
}