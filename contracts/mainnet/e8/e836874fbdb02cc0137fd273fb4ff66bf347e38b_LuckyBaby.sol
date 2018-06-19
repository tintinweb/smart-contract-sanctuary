pragma solidity ^0.4.21;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
    function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x / y;
        return z;
    }
}

contract LuckyBaby is Ownable, SafeMath {

    ERC20 public token;
    bool public activityClosed = false;
    uint public maxGasPrice = 30000000000;
    struct LuckyItem {
        address luckyMan;
        uint amount;
    }

    LuckyItem[] public history;

    uint public tokenRewardRate;

    uint public minTicket;
    uint public maxTicket;
    
    function () payable public {
        if (msg.sender == owner) {
            return;   
        }
        require(!activityClosed);
        require(tx.gasprice <= maxGasPrice);
        require(msg.value >= minTicket);
        require(msg.value <= maxTicket);
        award(msg.value, msg.sender);
    }
    
    function award (uint amount, address add) private {
        uint random_number = (uint(block.blockhash(block.number-1)) - uint(add)) % 100;
        if (random_number == 0) {
            uint reward = safeMult(amount, 100);
            require(address(this).balance >= reward);
            add.transfer(reward);
            LuckyItem memory item = LuckyItem({luckyMan:add, amount:reward});
            history.push(item);
        }
        if (token.balanceOf(this) >= tokenRewardRate) {
            token.transfer(add, tokenRewardRate);
        }
    }
    function LuckyBaby() public {
        token = ERC20(address(0x00));
        tokenRewardRate = 20*10**18;
        minTicket = 10**16;
        maxTicket = 10**17;
    }
    function setToken(ERC20 newToken) onlyOwner public {
        token = newToken;
    }
    function setMaxGasPrice(uint max) onlyOwner public {
        maxGasPrice = max;
    }
    function setActivityState(bool close) onlyOwner public {
        activityClosed = close;
    }
    function setTokenRewardRate(uint rate) onlyOwner public {
        tokenRewardRate = rate;
    }
    function setMaxTicket(uint max) onlyOwner public {
        maxTicket = max;
    }
    function withdrawToken(uint amount) onlyOwner public {
        uint256 leave = token.balanceOf(this);
        if (leave >= amount) {
            token.transfer(owner, amount);
        }
    }
    function withdrawEther(uint amount) onlyOwner public {
       owner.transfer(amount);
    }
    function clear() onlyOwner public {
        uint leave = token.balanceOf(this);
        if (leave > 0) {
            token.transfer(owner, leave);
        }
        uint balance = address(this).balance;
        if (balance > 0) {
            owner.transfer(balance);
        }
    }
}