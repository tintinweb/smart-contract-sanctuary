pragma solidity ^0.4.23;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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


interface TokenInterface {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract HivelocityNetworkTokenSale {
    address public owner;
    uint256 public price;
    using SafeMath for uint256;
    TokenInterface hivelocityNetworkToken;

    constructor(TokenInterface _tokenAddress) public {
        hivelocityNetworkToken = _tokenAddress;
        owner = msg.sender;
    }
        
    /**
      * @dev accept ether payment
      */
    function() public payable {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
      * @dev buy token from contract by sending ether
      */
    function buy() payable public returns(bool){
        // calculate token etherPrice base on ether to JPY rate
        require(price > 1);
        uint256 value = msg.value * price;
        uint256 numberOfToken = (value.div(10 ** 18)) * 10; 
        // require contract has enough token
        require(numberOfToken <= hivelocityNetworkToken.balanceOf(this));
        // transfer token to sender(user)
        return hivelocityNetworkToken.transfer(msg.sender, numberOfToken);
    }

    /** 
      * @dev withdraw ether from contract to owner
      */
    function withdrawEther() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    /**
      * @dev withdraw token from contract to owner
      */
    function withdrawToken() public onlyOwner {
        uint256 currentToken = hivelocityNetworkToken.balanceOf(this);
        require(currentToken > 0);
        hivelocityNetworkToken.transfer(owner, currentToken);
    } 

    /**
      * @dev Get the current etherPrice of ethereum
      */
    function getEtherPrice() public view returns(uint256) {
        return price;
    }
    
    /**
      * @dev Set the current etherPrice of ethereum
      */
    function setEtherPrice(uint256 _etherPrice) public onlyOwner() {
        price = _etherPrice;
    }
}