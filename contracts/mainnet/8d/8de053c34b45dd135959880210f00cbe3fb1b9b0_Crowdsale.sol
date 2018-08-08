pragma solidity 0.4.21;


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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}



contract CryptoRoboticsToken {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function burn(uint256 value) public;
}


contract ICOContract {
    function setTokenCountFromPreIco(uint256 value) public;
}


contract Crowdsale is Ownable {
    using SafeMath for uint256;

    // The token being sold
    CryptoRoboticsToken public token;
    ICOContract ico;

    // Address where funds are collected
    address public wallet;

    // Amount of wei raised
    uint256 public weiRaised;

    uint256 public openingTime;
    uint256 public closingTime;

    bool public isFinalized = false;

    uint public tokenPriceInWei = 105 szabo;

    uint256 public cap = 1008 ether;


    event Finalized();
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime);
        _;
    }


    function Crowdsale(CryptoRoboticsToken _token) public
    {
        require(_token != address(0));


        wallet = 0xeb6BD1436046b22Eb03f6b7c215A8537C9bed868;
        token = _token;
        openingTime = now;
        closingTime = 1526601600;
    }


    function () external payable {
        buyTokens(msg.sender);
    }


    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        uint _diff =  weiAmount % tokenPriceInWei;

        if (_diff > 0) {
            msg.sender.transfer(_diff);
            weiAmount = weiAmount.sub(_diff);
        }

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);


        _forwardFunds(weiAmount);
    }


    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen {
        require(_beneficiary != address(0));
        require(weiRaised.add(_weiAmount) <= cap);
        require(_weiAmount >= 20 ether);
    }


    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }


    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _tokenAmount = _tokenAmount * 1 ether;
        _deliverTokens(_beneficiary, _tokenAmount);
    }


    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint _tokens = _weiAmount.div(tokenPriceInWei);
        return _tokens;
    }


    function _forwardFunds(uint _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }


    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }

    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed() || capReached());

        finalization();
        emit Finalized();

        isFinalized = true;
    }


    function setIco(address _ico) onlyOwner public {
        ico = ICOContract(_ico);
    }


    function finalization() internal {
        uint _balance = token.balanceOf(this);
        if (_balance > 0) {
            token.transfer(address(ico), _balance);
            ico.setTokenCountFromPreIco(_balance);
        }
    }
}