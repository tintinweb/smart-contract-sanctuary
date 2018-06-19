pragma solidity 0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of &quot;user permissions&quot;. 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/**
 * @title ExchangeRate
 * @dev Allows updating and retrieveing of Conversion Rates for PAY tokens
 *
 * ABI
 * [{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_symbol&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_rate&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;updateRate&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;data&quot;,&quot;type&quot;:&quot;uint256[]&quot;}],&quot;name&quot;:&quot;updateRates&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_symbol&quot;,&quot;type&quot;:&quot;string&quot;}],&quot;name&quot;:&quot;getRate&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;owner&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;bytes32&quot;}],&quot;name&quot;:&quot;rates&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;newOwner&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;transferOwnership&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:false,&quot;name&quot;:&quot;timestamp&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;symbol&quot;,&quot;type&quot;:&quot;bytes32&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;rate&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;RateUpdated&quot;,&quot;type&quot;:&quot;event&quot;}]
 */
contract ExchangeRate is Ownable {

  event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

  mapping(bytes32 => uint) public rates;

  /**
   * @dev Allows the current owner to update a single rate.
   * @param _symbol The symbol to be updated. 
   * @param _rate the rate for the symbol. 
   */
  function updateRate(string _symbol, uint _rate) public onlyOwner {
    rates[sha3(_symbol)] = _rate;
    RateUpdated(now, sha3(_symbol), _rate);
  }

  /**
   * @dev Allows the current owner to update multiple rates.
   * @param data an array that alternates sha3 hashes of the symbol and the corresponding rate . 
   */
  function updateRates(uint[] data) public onlyOwner {
    if (data.length % 2 > 0)
      throw;
    uint i = 0;
    while (i < data.length / 2) {
      bytes32 symbol = bytes32(data[i * 2]);
      uint rate = data[i * 2 + 1];
      rates[symbol] = rate;
      RateUpdated(now, symbol, rate);
      i++;
    }
  }

  /**
   * @dev Allows the anyone to read the current rate.
   * @param _symbol the symbol to be retrieved. 
   */
  function getRate(string _symbol) public constant returns(uint) {
    return rates[sha3(_symbol)];
  }

}