pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


//--------------- Based on Crowdsale.sol -----------

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract RSCCoinCrowdsale is Ownable {
    using SafeMath for uint256;
    
    uint8 public decimals = 18;
    uint256 public totalSupply_;

    // The token being sold
    ERC20Basic public tokenContract;
    
    // Total token amount was supplied in this crowdsale
    uint256 public totalSale;
    uint256 public totalSaled = 0;
   
    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;


    function RSCCoinCrowdsale(address _newFundsWallet, address _erc20) public {
        require(_erc20 != address(0));

        tokenContract = ERC20Basic(_erc20);

        wallet = _newFundsWallet;
        
        totalSale = 350 * (10 ** 6) * (10 ** uint256(decimals));
     
        totalSupply_ = totalSale;

        weiRaised = 0;
    }

    // get name of token
    function name() public pure returns (string) { return "Ronaldinho Soccer Coin"; }
    // get symbol (identifier) of token
    function symbol() public pure returns (string) { return "RSC"; }
    // how many decimals to show
    function decimals() public view returns (uint8) { return decimals; }
    // total token was supplied
    function totalSupply() public view returns (uint256) { return totalSupply_; }
    // number of all token will be sale in crowdsale time
    function totalAmount() public pure returns (uint256) { return 0; }
	// get balance of address (token)
    function balanceOf(address _address) public view returns (uint256) { return tokenContract.balanceOf(_address); }
    // get current rate
    function getRate() public pure returns (uint256) { return 500; }
    
    // get fund raised, ether in contract
    function fundRaised() public view returns (uint256) {
        return weiRaised;
    }

    // fallback function can be used to buy tokens
    function () public payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens (address beneficiary) public payable {
        require(beneficiary != address(0));

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);

        totalSaled = totalSaled.add(tokens);
        require(totalSaled <= totalSale);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        tokenContract.transfer(msg.sender, tokens);

        forwardFunds();
    }

    // Allow the owner to transfer tokens from the token contract
    function issueTokens(address _to, uint256 _amount) public
    {
        require(msg.sender == owner);
        require(_to != address(0));
        if (msg.sender == owner){
            totalSaled = totalSaled.add(_amount);
            require(totalSaled <= totalSale);
        }
        else revert();
        tokenContract.transfer(_to, _amount);
    }

    // Override this method to have a way to add business logic to your crowdsale when buying
    function getTokenAmount(uint256 weiAmount) internal pure returns (uint256) {
        return weiAmount.mul(500);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}