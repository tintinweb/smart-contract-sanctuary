pragma solidity ^0.4.13;


/* taking ideas from FirstBlood token */
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

    // called by the owner on emergency, triggers stopped state
    function halt() external onlyOwner {
        halted = true;
    }

    // called by the owner on end of emergency, returns to normal state
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}


contract FluencePreSale is Haltable, SafeMath {

    mapping (address => uint256) public balanceOf;

    /*/
     *  Constants
    /*/

    string public constant name = "Fluence Presale Token";

    string public constant symbol = "FPT";

    uint   public constant decimals = 18;

    // 6% of tokens
    uint256 public constant SUPPLY_LIMIT = 6000000 ether;

    // What is given to contributors, <= SUPPLY_LIMIT
    uint256 public totalSupply;

    // If soft cap is not reached, refund process is started
    uint256 public softCap = 1000 ether;

    // Basic price
    uint256 public constant basicThreshold = 500 finney;

    uint public constant basicTokensPerEth = 1500;

    // Advanced price
    uint256 public constant advancedThreshold = 5 ether;

    uint public constant advancedTokensPerEth = 2250;

    // Expert price
    uint256 public constant expertThreshold = 100 ether;

    uint public constant expertTokensPerEth = 3000;

    // As we have different prices for different amounts,
    // we keep a mapping of contributions to make refund
    mapping (address => uint256) public etherContributions;

    // Max balance of the contract
    uint256 public etherCollected;

    // Address to withdraw ether to
    address public beneficiary;

    uint public startAtBlock;

    uint public endAtBlock;

    // All tokens are sold
    event GoalReached(uint amountRaised);

    // Minimal ether cap collected
    event SoftCapReached(uint softCap);

    // New contribution received and tokens are issued
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    // Ether is taken back
    event Refunded(address indexed holder, uint256 amount);

    // If soft cap is reached, withdraw should be available
    modifier softCapReached {
        if (etherCollected < softCap) {
            revert();
        }
        assert(etherCollected >= softCap);
        _;
    }

    // Allow contribution only during presale
    modifier duringPresale {
        if (block.number < startAtBlock || block.number > endAtBlock || totalSupply >= SUPPLY_LIMIT) {
            revert();
        }
        assert(block.number >= startAtBlock && block.number <= endAtBlock && totalSupply < SUPPLY_LIMIT);
        _;
    }

    // Allow withdraw only during refund
    modifier duringRefund {
        if(block.number <= endAtBlock || etherCollected >= softCap || this.balance == 0) {
            revert();
        }
        assert(block.number > endAtBlock && etherCollected < softCap && this.balance > 0);
        _;
    }

    function FluencePreSale(uint _startAtBlock, uint _endAtBlock, uint softCapInEther){
        require(_startAtBlock > 0 && _endAtBlock > 0);
        beneficiary = msg.sender;
        startAtBlock = _startAtBlock;
        endAtBlock = _endAtBlock;
        softCap = softCapInEther * 1 ether;
    }

    // Change beneficiary address
    function setBeneficiary(address to) onlyOwner external {
        require(to != address(0));
        beneficiary = to;
    }

    // Withdraw contract&#39;s balance to beneficiary account
    function withdraw() onlyOwner softCapReached external {
        require(this.balance > 0);
        beneficiary.transfer(this.balance);
    }

    // Process contribution, issue tokens to user
    function contribute(address _address) private stopInEmergency duringPresale {
        if(msg.value < basicThreshold && owner != _address) {
            revert();
        }
        assert(msg.value >= basicThreshold || owner == _address);
        // Minimal contribution

        uint256 tokensToIssue;

        if (msg.value >= expertThreshold) {
            tokensToIssue = safeMult(msg.value, expertTokensPerEth);
        }
        else if (msg.value >= advancedThreshold) {
            tokensToIssue = safeMult(msg.value, advancedTokensPerEth);
        }
        else {
            tokensToIssue = safeMult(msg.value, basicTokensPerEth);
        }

        assert(tokensToIssue > 0);

        totalSupply = safeAdd(totalSupply, tokensToIssue);

        // Goal is already reached, can&#39;t issue any more tokens
        if(totalSupply > SUPPLY_LIMIT) {
            revert();
        }
        assert(totalSupply <= SUPPLY_LIMIT);

        // Saving ether contributions for the case of refund
        etherContributions[_address] = safeAdd(etherContributions[_address], msg.value);

        // Track ether before adding current contribution to notice the event of reaching soft cap
        uint collectedBefore = etherCollected;
        etherCollected = safeAdd(etherCollected, msg.value);

        // Tokens are issued
        balanceOf[_address] = safeAdd(balanceOf[_address], tokensToIssue);

        NewContribution(_address, tokensToIssue, msg.value);

        if (totalSupply == SUPPLY_LIMIT) {
            GoalReached(etherCollected);
        }
        if (etherCollected >= softCap && collectedBefore < softCap) {
            SoftCapReached(etherCollected);
        }
    }

    function() external payable {
        contribute(msg.sender);
    }

    function refund() stopInEmergency duringRefund external {
        uint tokensToBurn = balanceOf[msg.sender];


        // Sender must have tokens
        require(tokensToBurn > 0);

        // Burn
        balanceOf[msg.sender] = 0;

        // User contribution amount
        uint amount = etherContributions[msg.sender];

        // Amount must be positive -- refund is not processed yet
        assert(amount > 0);

        etherContributions[msg.sender] = 0;
        // Clear state

        // Reduce counters
        etherCollected = safeSubtract(etherCollected, amount);
        totalSupply = safeSubtract(totalSupply, tokensToBurn);

        // Process refund. In case of error, it will be thrown
        msg.sender.transfer(amount);

        Refunded(msg.sender, amount);
    }


}