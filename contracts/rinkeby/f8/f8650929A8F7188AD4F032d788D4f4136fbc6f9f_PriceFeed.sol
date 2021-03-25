/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: contracts\Ownable.sol

pragma solidity ^0.5.16;


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  
  constructor (address _owner) public {
    require(_owner != address(0));
    owner = _owner;
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0),"invalid address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IAggregatorV3Interface{
    function latestRoundData() external view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract PriceFeed is Ownable{
    using SafeMath for uint256;
    
    bytes32 public dLINK;
    bytes32 public dBTC;
    bytes32 public dETH;
    bytes32 public dSNX;

    IAggregatorV3Interface internal priceFeed;
    
    mapping( bytes32 => addressesForPrices) public synthKey;
    
    struct addressesForPrices{
        bytes32 synth;
        IAggregatorV3Interface priceFeedAddress;
        uint256 _price;
    }


    constructor() public Ownable(msg.sender){
        setBytes32Code();
        
        synthKey[dBTC].synth = dBTC;
        synthKey[dBTC].priceFeedAddress = IAggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
        
        synthKey[dETH].synth = dETH;
        synthKey[dETH].priceFeedAddress = IAggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        synthKey[dLINK].synth = dLINK;
        synthKey[dLINK].priceFeedAddress = IAggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);
        
        synthKey[dSNX].synth = dSNX;
        synthKey[dSNX].priceFeedAddress = IAggregatorV3Interface(0xE96C4407597CD507002dF88ff6E0008AB41266Ee);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(bytes32 _synth) external returns (int) {
        priceFeed = IAggregatorV3Interface(synthKey[_synth].priceFeedAddress);
        
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        synthKey[_synth]._price = uint256(price).mul(10000000000);
        return price;
    }
    
    function setSynthAddress(string calldata _synth, IAggregatorV3Interface _address) external onlyOwner{
        bytes32 __synth = stringToBytes32(_synth);
        synthKey[__synth].synth = __synth;
        synthKey[__synth].priceFeedAddress = _address;
    }
    
    function setBytes32Code() internal{
        dLINK = stringToBytes32("dLINK");
        dBTC = stringToBytes32("dBTC");
        dETH = stringToBytes32("dETH");
        dSNX = stringToBytes32("dSNX");
    }
    
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function viewPrice(string memory _synth) public view returns (uint256){
        bytes32 __synth = stringToBytes32(_synth);
        return synthKey[__synth]._price;
    }
}