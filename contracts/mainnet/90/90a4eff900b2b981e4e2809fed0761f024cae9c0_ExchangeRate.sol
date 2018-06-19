contract Ownable {

  address public owner;
  
  mapping(address => uint) public balances;

  function Ownable() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract ExchangeRate is Ownable {

  event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

  mapping(bytes32 => uint) public rates;

  function updateRate(string _symbol, uint _rate) public onlyOwner {
    rates[keccak256(_symbol)] = _rate;
    RateUpdated(now, keccak256(_symbol), _rate);
  }

  
  function updateRates(uint[] data) public onlyOwner {
    if (data.length % 2 > 0)
      revert();
    uint i = 0;
    while (i < data.length / 2) {
      bytes32 symbol = bytes32(data[i * 2]);
      uint rate = data[i * 2 + 1];
      rates[symbol] = rate;
      RateUpdated(now, symbol, rate);
      i++;
    }
  }

  function getRate(string _symbol) public constant returns(uint) {
    return rates[keccak256(_symbol)];
  }

}