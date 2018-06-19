pragma solidity ^0.4.11;

contract Mineable {
    address public owner;
    uint public supply = 100000000000000;
    string public name = &#39;MineableBonusEthereumToken&#39;;
    string public symbol = &#39;MBET&#39;;
    uint8 public decimals = 8;
    uint public price = 1 finney;
    uint public durationInBlocks = 157553; // 1 month
    uint public miningReward = 100000000;
    uint public amountRaised;
    uint public deadline;
    uint public tokensSold;
    uint private divider;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public successesOf;
    mapping (address => uint256) public failsOf;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    function isOwner() returns (bool isOwner) {
        return msg.sender == owner;
    }
    
    function addressIsOwner(address addr)  returns (bool isOwner) {
        return addr == owner;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Mineable() {
        owner = msg.sender;
        divider -= 1;
        divider /= 1048576;
        balanceOf[msg.sender] = supply;
        deadline = block.number + durationInBlocks;
    }
    
    function isCrowdsale() returns (bool isCrowdsale) {
        return block.number < deadline;
    }
    
    /* Send coins */
    function transfer(address _to, uint256 _value) {
        /* if the sender doesnt have enough balance then stop */
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        
        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        /* Notify anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
    }
    
    function () payable {
        if (isOwner()) {
            owner.transfer(amountRaised);
            FundTransfer(owner, amountRaised, false);
            amountRaised = 0;
        } else if (isCrowdsale()) {
            uint amount = msg.value;
            if (amount == 0) revert();
            
            uint tokensCount = amount * 100000000 / price;
            if (tokensCount < 100000000) revert();
            
            balanceOf[msg.sender] += tokensCount;
            supply += tokensCount;
            tokensSold += tokensCount;
            Transfer(0, this, tokensCount);
            Transfer(this, msg.sender, tokensCount);
            amountRaised += amount;
        } else if (msg.value == 0) {
            uint minedAtBlock = uint(block.blockhash(block.number - 1));
            uint minedHashRel = uint(sha256(minedAtBlock + uint(msg.sender))) / divider;
            uint balanceRel = balanceOf[msg.sender] * 1048576 / supply;
            
            if (minedHashRel < balanceRel * 933233 / 1048576 + 10485) {
                uint reward = miningReward + minedHashRel * 10000;
                balanceOf[msg.sender] += reward;
                supply += reward;
                Transfer(0, this, reward);
                Transfer(this, msg.sender, reward);
                successesOf[msg.sender]++;
            } else {
                failsOf[msg.sender]++;
            }
        } else {
            revert();
        }
    }
}