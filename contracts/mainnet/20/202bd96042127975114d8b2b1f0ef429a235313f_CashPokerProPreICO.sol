pragma solidity ^0.4.15;


contract Token {
    uint256 public totalSupply;

    function balanceOf(address who) constant returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();

    event Unpause();

    bool public paused = false;


    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


contract CashPokerProPreICO is Ownable, Pausable {
    using SafeMath for uint;

    /* The party who holds the full token pool and has approve()&#39;ed tokens for this crowdsale */
    address public tokenWallet = 0x774d91ac35f4e2f94f0e821a03c6eaff8ad4c138;
	
    uint public tokensSold;

    uint public weiRaised;

    mapping (address => uint256) public purchasedTokens;
     
    uint public investorCount;

    Token public token = Token(0xA8F93FAee440644F89059a2c88bdC9BF3Be5e2ea);

    uint public constant minInvest = 0.01 ether;

    uint public constant tokensLimit = 8000000 * 1 ether;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime = 1503770400; // 26 August 2017
    
    uint256 public endTime = 1504893600; // 8 September 2017

    uint public price = 0.00017 * 1 ether;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // fallback function can be used to buy tokens
    function() payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) whenNotPaused payable {
        require(startTime <= now && now <= endTime);

        uint weiAmount = msg.value;

        require(weiAmount >= minInvest);

        uint tokenAmountEnable = tokensLimit.sub(tokensSold);

        require(tokenAmountEnable > 0);

        uint tokenAmount = weiAmount / price * 1 ether;

        if (tokenAmount > tokenAmountEnable) {
            tokenAmount = tokenAmountEnable;
            weiAmount = tokenAmount * price / 1 ether;
            msg.sender.transfer(msg.value - weiAmount);
        }

        if (purchasedTokens[beneficiary] == 0) investorCount++;
        
        purchasedTokens[beneficiary] = purchasedTokens[beneficiary].add(tokenAmount);

        weiRaised = weiRaised.add(weiAmount);

        require(token.transferFrom(tokenWallet, beneficiary, tokenAmount));

        tokensSold = tokensSold.add(tokenAmount);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
    }

    function withdrawal(address to) onlyOwner {
        to.transfer(this.balance);
    }

    function transfer(address to, uint amount) onlyOwner {
        uint tokenAmountEnable = tokensLimit.sub(tokensSold);

        if (amount > tokenAmountEnable) amount = tokenAmountEnable;

        require(token.transferFrom(tokenWallet, to, amount));

        tokensSold = tokensSold.add(amount);
    }
}