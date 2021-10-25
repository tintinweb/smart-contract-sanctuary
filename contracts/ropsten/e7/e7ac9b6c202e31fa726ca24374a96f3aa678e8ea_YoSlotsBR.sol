/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity 0.4.18;

// ----------------------------------------------------------------------------
// YoSlots - black&red 
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Modified ERC Interface
// ----------------------------------------------------------------------------
contract ERCInterface {
    function transfer(address to, uint tokens) public returns (bool success);
}

// ----------------------------------------------------------------------------
// YoSlots - black&red
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// YoCoin DICE
// ----------------------------------------------------------------------------
contract YoSlotsBR is ERCInterface, Owned {
    using SafeMath for uint;

    string public name;
    uint win;
    uint luck = 1000;
    bytes32 public nextLuckHash;
    uint public txCount = 0;
    uint public winCount = 0;
    uint public multi = 2;
    uint luckThreshold = 500;
    uint a;
    uint b;
    uint c;
    uint res;
    
    mapping(address => uint) balances;
    event Win(address indexed _from, uint control, uint amount, uint balance, uint mul, uint res, uint bet);
    event Lost(address indexed _from, uint control, uint amount, uint balancem, uint mul, uint res, uint bet);


    function YoDice() public {
        name = "YoSlots black&red";
    }

    function () public payable {
    }
    
    // 0 = red / 1 = black
    function bet(uint playerBet) public payable {
    require(playerBet == 1 || playerBet == 0);
        if (txCount != 0) {
        if (luck < luckThreshold) { res = 0; } else { res = 1;}
            if (address(this).balance != 0) {
                if (playerBet == res) { 
                    if (msg.value >= address(this).balance.div(multi)) {
                        win = address(this).balance; 
                    } else {
                        win = msg.value.mul(multi);
                }
            owner.transfer(win.mul(3).div(100));
            msg.sender.transfer(win.mul(97).div(100));
            Win(msg.sender, luck, win, address(this).balance, multi.mul(10), res, msg.value);
            winCount = winCount.add(1);
            } else {
            Lost(msg.sender, luck, msg.value, address(this).balance, multi.mul(10), res, msg.value);
            owner.transfer(msg.value.div(100));
            //balancing
            }
        }
        }
        a = uint(sha256((block.timestamp)))%1000;
        b = uint(sha256((block.difficulty)))%1000;
        c = uint(sha256((msg.sender)))%1000;
        luck = uint(sha256((a.mul(b.mul(c)))))%1000;
        nextLuckHash = keccak256(a,b,c);
        txCount = txCount.add(1);
    }

    function transfer(address to, uint amount) public returns (bool success) {
        to = to;
        amount = amount;
        return true;
    }
    
     function withdraw() public onlyOwner returns (bool success) {
        owner.transfer(address(this).balance);
        return true;
    }    
}