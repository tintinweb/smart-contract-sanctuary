pragma solidity ^0.4.18;


//>> Reference to https://github.com/OpenZeppelin/zeppelin-solidity

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

//<< Reference to https://github.com/OpenZeppelin/zeppelin-solidity




contract Coin {
    function sell(address _to, uint256 _value, string _note) public returns (bool);
}


/**
 * @title MultiOwnable
 */
contract MultiOwnable {
    address public root;
    mapping (address => address) public owners; // owner => parent of owner
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function MultiOwnable() public {
        root= msg.sender;
        owners[root]= root;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(owners[msg.sender] != 0);
        _;
    }
    
    /**
    * @dev Adding new owners
    */
    function newOwner(address _owner) onlyOwner public returns (bool) {
        require(_owner != 0);
        owners[_owner]= msg.sender;
        return true;
    }
    
    /**
     * @dev Deleting owners
     */
    function deleteOwner(address _owner) onlyOwner public returns (bool) {
        require(owners[_owner] == msg.sender || (owners[_owner] != 0 && msg.sender == root));
        owners[_owner]= 0;
        return true;
    }
}


/**
 * @title KStarCoinSale
 * @author Tae Kim
 * @notice This contract is for crowdfunding of KStarCoin.
 */
contract KStarCoinSale is MultiOwnable {
    using SafeMath for uint256;
    
    eICOLevel public level;
    uint256 public rate;
    uint256 public minWei;

    function checkValidLevel(eICOLevel _level) public pure returns (bool) {
        return (_level == eICOLevel.C_ICO_PRESALE || _level == eICOLevel.C_ICO_ONSALE || _level == eICOLevel.C_ICO_END);
    }

    modifier onSale() {
        require(level != eICOLevel.C_ICO_END);
        _;
    }
    
    enum eICOLevel { C_ICO_PRESALE, C_ICO_ONSALE, C_ICO_END }
    
    Coin public coin;
    address public wallet;

    // Constructure
    function KStarCoinSale(Coin _coin, address _wallet) public {
        require(_coin != address(0));
        require(_wallet != address(0));
        
        coin= _coin;
        wallet= _wallet;

        updateICOVars(  eICOLevel.C_ICO_PRESALE,
                        3750,       // 3000 is default, +750 is pre-sale bonus
                        1e5 szabo); // = 0.1 ether
    }
    
    // Update variables related to crowdfunding
    function updateICOVars(eICOLevel _level, uint _rate, uint _minWei) onlyOwner public returns (bool) {
        require(checkValidLevel(_level));
        require(_rate != 0);
        require(_minWei >= 1 szabo);
        
        level= _level;
        rate= _rate;
        minWei= _minWei;
        
        ICOVarsChange(level, rate, minWei);
        return true;
    }
    
    function () external payable {
        buyCoin(msg.sender);
    }
    
    function buyCoin(address beneficiary) onSale public payable {
        require(beneficiary != address(0));
        require(msg.value >= minWei);

        // calculate token amount to be created
        uint256 coins= getCoinAmount(msg.value);
        
        // update state 
        coin.sell(beneficiary, coins, "");
        
        forwardFunds();
    }

    function getCoinAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(rate);
    }
  
    // send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    
    event ICOVarsChange(eICOLevel level, uint256 rate, uint256 minWei);
}