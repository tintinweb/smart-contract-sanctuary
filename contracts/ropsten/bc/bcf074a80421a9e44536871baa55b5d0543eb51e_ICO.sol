pragma solidity ^0.4.19;

contract Ownable {
    
    address public owner;

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
    * Transfers ownership to new Ethereum address. This function can only be called by the 
    * owner.
    * @param _newOwner the address to be granted ownership.
    **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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



contract TokenInterface {
    function transfer(address to, uint256 value) public returns (bool);
}


contract ICO is Ownable {
    
    using SafeMath for uint256;
    
    string public website = "www.propvesta.com";
    uint256 public rate;
    uint256 public tokensSold;
    address public fundsWallet = 0x304f970BaA307238A6a4F47caa9e0d82F082e3AD;
    
    TokenInterface public constant PROV = TokenInterface(0x409Ec1FCd524480b3CaDf4331aF21A2cB3Db68c9);
    
    function ICO() public {
        rate = 20000000;
    }
    
    function changeRate(uint256 _newRate) public onlyOwner {
        require(_newRate > 0 && rate != _newRate);
        rate = _newRate;
    }
    
    function changeFundsWallet(address _fundsWallet) public onlyOwner returns(bool) {
        fundsWallet = _fundsWallet;
        return true;
    }
    
    event TokenPurchase(address indexed investor, uint256 tokensPurchased);
    
    function buyTokens(address _investor) public payable {
        require(msg.value >= 1e16);
        uint256 exchangeRate = rate;
        uint256 bonus = 0;
        uint256 investment = msg.value;
        uint256 remainder = 0;
        if(investment >= 1e18 && investment < 2e18) {
            bonus = 30;
        } else if(investment >= 2e18 && investment < 3e18) {
            bonus = 35;
        } else if(investment >= 3e18 && investment < 4e18) {
            bonus = 40;
        } else if(investment >= 4e18 && investment < 5e18) {
            bonus = 45;
        } else if(investment >= 5e18) {
            bonus = 50;
        }
        exchangeRate = rate.mul(bonus).div(100).add(rate);
        uint256 toTransfer = 0;
        if(investment > 10e18) {
            uint256 bonusCap = 10e18;
            toTransfer = bonusCap.mul(exchangeRate);
            remainder = investment.sub(bonusCap);
            toTransfer = toTransfer.add(remainder.mul(rate));
        } else {
            toTransfer = investment.mul(exchangeRate);
        }
        PROV.transfer(_investor, toTransfer);
        TokenPurchase(_investor, toTransfer);
        tokensSold = tokensSold.add(toTransfer);
        fundsWallet.transfer(investment);
    }
    
    function() public payable {
        buyTokens(msg.sender);
    }
    
    function getTokensSold() public view returns(uint256) {
        return tokensSold;
    }
    
    event TokensWithdrawn(uint256 totalPROV);
    
    function withdrawPROV(uint256 _value) public onlyOwner {
        PROV.transfer(fundsWallet, _value);
        TokensWithdrawn(_value);
    }
}