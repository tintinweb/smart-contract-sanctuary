pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library Zero {
  function requireNotZero(uint a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}

library ToAddress {
  function toAddr(uint source) internal pure returns(address) {
    return address(source);
  }

  function toAddr(bytes source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}


contract ERC20AdToken {
    using SafeMath for uint;
    using Zero for *;

    string public symbol;
    string public  name;
    
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(string _symbol, string _name) public {
        symbol = _symbol;
        name = _name;
        balanceOf[this] = 10000000000;
        emit Transfer(address(0), this, 10000000000);
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balanceOf[to] = balanceOf[to].add(tokens);
        emit Transfer(this, to, tokens);
        return true;
    }
    
    function massTransfer(address[] addresses, uint tokens) public returns (bool success) {
        for (uint i = 0; i < addresses.length; i++) {
            ERC20AdToken(this).transfer(addresses[i], tokens);
        }
        
        return true;
    }

    function () public payable {
        revert();
    }

}


contract MoneyBox is ERC20AdToken {
  uint public constant startSellPrice = 9400 szabo; //0.0094 eth
  uint public constant startBuyPrice = 10 finney; //0.01 eth
  uint public constant minInvesment = 10 finney; // 0.01 eth
  uint public constant increasePricePeriod = 3 hours; //3 days
  uint public constant increasePercent = 4; //every time price will be increased for 4%
  
  uint public lastIncrementPriceTime;
  uint public sellPrice;
  uint public buyPrice;
  
  event TokenBuyed(address indexed addr, uint tokens, uint price);
  event TokensSelled(address indexed addr, uint tokens, uint price);

//   constructor() ERC20AdToken("Earn 3.55% every day. http://EarnEveryDay.info", 
//                             "Send eth to this contract and earn 3.55% every day. More details here: http://EarnEveryDay.info") public {
  constructor() ERC20AdToken("EED", 
                            "EED Token Info Name") public {
    lastIncrementPriceTime = now;
    sellPrice = startSellPrice;
    buyPrice = startBuyPrice;
  }
  
  
}