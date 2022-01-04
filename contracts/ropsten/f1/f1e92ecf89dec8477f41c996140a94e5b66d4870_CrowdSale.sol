/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.4.23;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not beingzero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow
  * (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



contract ERC20 {
    using SafeMath for uint256; 

    mapping(address => uint256) balances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    uint256 totalSupply_;
    address owner_;

    constructor(uint _totalSupply) public {
        totalSupply_ = _totalSupply;
        owner_ = msg.sender;
        // Assigns all tokens to the owner
        balances[owner_] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) { 
        return totalSupply_; 
    }

    function balanceOf(address _owner) public view 
        returns (uint256) { 
        return balances[_owner]; 
    }

    function transfer(address _to, uint256 _value) public returns (bool) { 
        require(_to != address(0)); 
        require(_value <= balances[owner_]); 

        balances[owner_] = balances[owner_].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(owner_, _to, _value); 

        return true; 
    } 

}


contract CrowdSale {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    /**
    * Event for token purchase logging
    */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
    * @param _rate Number of token units a buyer gets per wei
    * @param _wallet Address where collected funds will be 
    * forwarded to
    * @param _token Address of the token being sold
    */
    constructor(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    function () external payable {
        buyTokens(msg.sender, msg.value);
    }

    function testTokens(address _investor, uint256 _weiAmount) public payable {
        //uint256 tokens = calculateToken(_weiAmount);
        token.transfer(_investor, _weiAmount);
    }

    function buyTokens(address _investor, uint256 _weiAmount) public payable {
        require(_investor != address(0));
        require(_weiAmount != 0);

        weiRaised = weiRaised.add(_weiAmount);
        
        uint256 tokens = calculateToken(_weiAmount);
        token.transfer(_investor, tokens);
        emit TokenPurchase(
            msg.sender, _investor, 
            _weiAmount, tokens
        );

        wallet.transfer(msg.value);
    }

    function calculateToken(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }
}