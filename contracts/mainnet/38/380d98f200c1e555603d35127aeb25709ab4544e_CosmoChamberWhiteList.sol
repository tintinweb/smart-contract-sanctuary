/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

pragma solidity >=0.5.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

library Address {
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { codehash := extcodehash(account) }
    return (codehash != 0x0 && codehash != accountHash);
  }

}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface CosmoChamber {
    function authorizedGenerator(uint256 _amount, address receiver) external;
}

contract Whitelist is Ownable {
    using SafeMath for uint256;
    
    CosmoChamber cosmoChamber;
    
    event NewNFTPrice(uint256 indexed _newprice);
    
    uint256 public NFTprice = 0.03 * 10**18;
	mapping (address => bool) public IfWhiteList;
    
	constructor(
		address cosmoChamberAddress
	) public {
		cosmoChamber = CosmoChamber(cosmoChamberAddress);
	}
	
	function mint(uint _amount) public payable {
	    require(msg.value >= NFTprice.mul(_amount), "Insufficient ETH");
	    require(_amount > 0 && _amount <= 2, "Invalid amount");
	    require(_ifWhiteListed(msg.sender), "Unqualified!");
        IfWhiteList[msg.sender] = false;
	    cosmoChamber.authorizedGenerator(_amount, msg.sender);
	}
	
	function setWhitelist(address[] memory _users) public onlyOwner {
	    uint userLength = _users.length;
	    for (uint i = 0; i < userLength; i++) {
	        IfWhiteList[_users[i]] = true;
	    }
	}
	
	function _ifWhiteListed(address _user) private view returns(bool) {
	    return IfWhiteList[_user];
	}
	
	function setNFTPrice(uint256 _newPrice) public onlyOwner {
	    require(_newPrice > 0);
	    NFTprice = _newPrice;
	    emit NewNFTPrice(_newPrice);
	}
}

contract CosmoChamberWhiteList is Whitelist {
    constructor(address _cosmoChamberAddress) public Whitelist(_cosmoChamberAddress) {
		
	}
	
	function withdrawBalance() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}