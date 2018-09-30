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

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  function getOwner() public returns (address) {
	return owner;
  }

}

contract AngelToken {
	function getTotalSupply() public returns (uint256);
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
}

contract GiveAnAngelCS is Ownable {
    using SafeMath for uint256;

    AngelToken public token;
    address public wallet;
    uint256 public price;
    uint256 public weiRaised;
	// integer number - eg. 30 means 30 percent 
	uint256 public currentBonus = 0;
	uint256 public constant ETH_LIMIT = 1 * (10 ** 17);

    event AngelTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function GiveAnAngelCS(uint256 _price, address _wallet) {
        require(_price > 0);
        require(_wallet != address(0));

        token = AngelToken(0x4597cf324eb06ff0c4d1cc97576f11336d8da730);
        price = _price;
        wallet = _wallet;
    }

    // fallback function can be used to buy tokens
    function () payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        uint256 weiAmount = msg.value;

		require(weiAmount >= ETH_LIMIT);
		
        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(currentBonus.add(100)).mul(10**18).div(price).div(100);

        require(validPurchase(tokens));

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.transfer(msg.sender, tokens);

        AngelTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase(uint256 tokens) internal constant returns (bool) {
        return token.balanceOf(this) >= tokens;
    }
	
	function setBonus(uint256 _bonus) onlyOwner public {
		currentBonus = _bonus;
	}
	
	function setPrice(uint256 _price) onlyOwner public {
		price = _price;
	}
	
	function getBonus() public returns (uint256) {
        return currentBonus;
    }
	
	function getRaised() public returns (uint256) {
        return weiRaised;
    }
	
	function returnToOwner() onlyOwner public {
		uint256 currentBalance = token.balanceOf(this);
		token.transfer(getOwner(), currentBalance);
	}
}