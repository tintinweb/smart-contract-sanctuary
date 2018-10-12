pragma solidity ^0.4.24;


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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title WTXHCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract WTXHCrowdsale is Ownable {
    using SafeMath for uint256;
    
    /////////////////////// VARIABLE INITIALIZATION ///////////////////////
    
    
    // All dates are stored as timestamps. GMT
    uint constant public startPresale   = 1541980800; // 12.11.2018 00:00:00
    uint constant public endPresale     = 1546819199; // 06.01.2019 23:59:00
    uint constant public startCrowdsale = 1546819200; // 07.01.2019 00:00:00
    uint constant public endCrowdsale   = 1552953599; // 18.03.2019 23:59:59
    
    // Decimals
    uint8 public constant decimals = 18;
    
    ERC20 public token;
    
    // Amount of ETH received and Token purchase during ICO
    uint public weiRaised;
    uint public wtxhRaised;
    
    // 1 ether  = 1000 WTXH
    uint256 public constant oneEtherValue = 1000;
    
    // Map of all purchaiser&#39;s balances 
    mapping(address => uint256) public balances;

    // Is a crowdsale closed?
    bool public closed;
    
    // Address where funds are collected
    address constant public wallet = 0x255ae182b2e823573FE0551FA8ece7F824Fd1E7F;
    
    uint256 public constant tokenForSale = 200000000;
    
    
    /////////////////////// MODIFIERS ///////////////////////

    // Ensure actions can only happen during Presale
    
    modifier notCloseICO(){
        require(!closed);
        _;
    }
    
     /////////////////////// EVENTS ///////////////////////

    /**
     * Event for token withdrawal logging
     * @param receiver who receive the tokens
     * @param amount amount of tokens sent
     */
    event TokenDelivered(address indexed receiver, uint256 amount);

    /**
     * Event for token adding by referral program
     * @param beneficiary who got the tokens
     * @param amount amount of tokens added
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    ///////////////////////  ///////////////////////


    /**
    * Init crowdsale by setting its params
    * @param _token Address of the token being sold
    */
    constructor (ERC20 _token)  public {
        token = _token;
    }
    
    /**
     * @param _beneficiary Token purchaser
     * @param _tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) notCloseICO internal {
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
        wtxhRaised = wtxhRaised.add(_tokenAmount);
    }

    /**
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
    function _getTokenAmount(uint256 _weiAmount) private view returns (uint256) {
        uint256 amountToken = _weiAmount * oneEtherValue;
        uint256  tokenBonus = _getTokenBonus(amountToken);
        return amountToken.add(tokenBonus);
    }

    /**
     * @dev Deliver tokens to receiver_ after crowdsale ends.
     */
    function withdrawTokensFor(address receiver_) public onlyOwner {
        assert(now >= startPresale && now <= endCrowdsale);
        _withdrawTokensFor(receiver_);
    }


    /**
     * @dev Withdraw tokens for receiver_ after crowdsale ends.
     */
    function _withdrawTokensFor(address receiverAdd) internal {
        require(closed);
        uint256 amount = balances[receiverAdd];
        require(amount > 0);
        balances[receiverAdd] = 0;
        emit TokenDelivered(receiverAdd, amount);
        _deliverTokens(receiverAdd, amount);
    }
    
    
    /**
     * @dev Tranfert wei amount
     */
    function _forwardFunds() private {
        wallet.transfer(msg.value);
    }
    
    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }
    
    function () payable external {
        buyTokens(msg.sender);
    }
    
    /**
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) notCloseICO public payable {

        uint256 weiAmount = msg.value;

        require(_beneficiary != address(0));
        require(weiAmount != 0 && weiAmount >=  decimals/1000);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);
        
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        
        if(tokenForSale == wtxhRaised) closed = true;
        _forwardFunds();
    }
    
        // get the token bonus by rate
    function _getTokenBonus(uint256 _wtxh) public view returns(uint256) {
        
        if (now <= 1543190399 && now >= startPresale) {
           return _wtxh.mul(30).div(100);
        } else if (now <= 1544399999 && now >= 1543190400 ) {
           return _wtxh.mul(55).div(100).div(2); 
        } else if (now <= 1545609599 && now >= 1544400000) {
           return _wtxh.mul(25).div(100); 
        } else if (now <= 1546819199 && now >= 1545609600) {
           return _wtxh.mul(20).div(100); 
        } else if (now <= 1548028799 && now >= 1546819200) {
           return _wtxh.mul(20).div(100); 
        } else if (now <= 1550447999 && now >= 1548028800) {
           return _wtxh.mul(15).div(100); 
        } else if (now <= endCrowdsale && now >= 1550448000) {
           return _wtxh.mul(10).div(100); 
        } else {
           return 0;
        } 
    }

}