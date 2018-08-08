pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Rescue compatible ERC20Basic Token
     *
     * @param _token ERC20Basic The address of the token contract
     */
    function rescueTokens(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        assert(_token.transfer(owner, balance));
    }

    /**
     * @dev Withdraw Ether
     */
    function withdrawEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


/**
 * @title Sell ERC20Basic Tokens
 */
contract SellERC20BasicTokens is Ownable {
    using SafeMath for uint256;

    // Token
    ERC20Basic public token;
    uint256 etherDecimals = 18;
    uint256 tokenDecimals;
    uint256 decimalDiff;

    // Ether Minimum
    uint256 public etherMinimum;

    // RATE
    uint256 public rate;
    uint256 public depositRate;

    // Deposit
    uint256 public deposit;
    
    // Wallet
    address public wallet;


    /**
     * @dev Constructor
     *
     * @param _token address
     * @param _tokenDecimals uint256
     * @param _etherMinimum uint256
     * @param _rate uint256
     * @param _depositRate uint256
     * @param _wallet address
     */
    constructor(ERC20Basic _token, uint256 _tokenDecimals, uint256 _etherMinimum, uint256 _rate, uint256 _depositRate, address _wallet) public {
        token = _token;
        tokenDecimals = _tokenDecimals;
        decimalDiff = etherDecimals.sub(_tokenDecimals);
        etherMinimum = _etherMinimum;
        rate = _rate;
        depositRate = _depositRate;
        wallet = _wallet;
    }

    /**
     * @dev receive ETH and send tokens
     */
    function () public payable {
        // minimum limit
        uint256 weiAmount = msg.value;
        require(weiAmount >= etherMinimum.mul(10 ** etherDecimals));

        // make sure: onsale > 0
        uint256 balance = token.balanceOf(address(this));
        uint256 onsale = balance.sub(deposit);
        require(onsale > 0);

        // token amount
        uint256 tokenBought = weiAmount.mul(rate).div(10 ** decimalDiff);
        uint256 tokenDeposit = weiAmount.mul(depositRate).div(10 ** decimalDiff);
        uint256 tokenAmount = tokenBought.add(tokenDeposit);
        require(tokenAmount > 0);

        // transfer tokens
        if (tokenAmount <= onsale) {
            assert(token.transfer(msg.sender, tokenBought));
        } else {
            uint256 weiExpense = onsale.div(rate + depositRate);
            tokenBought = weiExpense.mul(rate);
            tokenDeposit = onsale.sub(tokenBought);

            // transfer tokens
            assert(token.transfer(msg.sender, tokenBought));

            // refund
            msg.sender.transfer(weiAmount - weiExpense.mul(10 ** decimalDiff));
        }

        // deposit +
        deposit = deposit.add(tokenDeposit);

        // onsale -
        onsale = token.balanceOf(address(this)).sub(deposit);

        // transfer eth back to owner
        owner.transfer(address(this).balance);
    }

    /**
     * @dev Send Token
     * 
     * @param _receiver address
     * @param _amount uint256
     */
    function sendToken(address _receiver, uint256 _amount) external {
        require(msg.sender == wallet);
        require(_amount <= deposit);
        assert(token.transfer(_receiver, _amount));
        deposit = deposit.sub(_amount);
    }

    /**
     * @dev Set Rate
     * 
     * @param _rate uint256
     * @param _depositRate uint256
     */
    function setRate(uint256 _rate, uint256 _depositRate) external onlyOwner {
        rate = _rate;
        depositRate = _depositRate;
    }

    /**
     * @dev Set Wallet
     * 
     * @param _wallet address
     */
    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }
}