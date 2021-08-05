/**
 *Submitted for verification at Etherscan.io on 2020-11-20
*/

pragma solidity ^0.6.12;

library stringToBytes32 {
  function convert(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
   }
}

interface IBancorPoolParser {
  function parseConnectorsByPool(address _from, address _to, uint256 poolAmount)
    external
    view
    returns(uint256 totalValue);
}


interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
    // deprecated, backward compatibility
    function getAddress(bytes32 _contractName) external view returns (address);
}


interface BancorNetworkInterface {
   function getReturnByPath(
     address[] calldata _path,
     uint256 _amount)
     external
     view
     returns (uint256, uint256);

    function conversionPath(
      address _sourceToken,
      address _targetToken
    ) external view returns (address[] memory);

    function rateByPath(
        address[] memory _path,
        uint256 _amount
    ) external view returns (uint256);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract GetBancorData is Ownable{
  using stringToBytes32 for string;
  IBancorPoolParser public BancorPoolParser;
  IContractRegistry public bancorRegistry;

  constructor(address _bancorRegistry)public{
    bancorRegistry = IContractRegistry(_bancorRegistry);
  }

  // return contract address from Bancor registry by name
  function getBancorContractAddresByName(string memory _name) public view returns (address result){
     bytes32 name = stringToBytes32.convert(_name);
     result = bancorRegistry.addressOf(name);
  }

  /**
  * @dev get ratio between Bancor assets
  *
  * @param _from  address or Relay
  * @param _to  address or Relay
  * @param _amount  amount for _from
  */
  function getBancorRatioForAssets(address _from, address _to, uint256 _amount) public view returns(uint256 result){
    if(_amount > 0){
      try BancorPoolParser.parseConnectorsByPool(_from, _to, _amount)
        returns(uint256 totalValue)
       {
         result = totalValue;
       }
       catch{
         result = getRatioByPath(_from, _to, _amount);
       }
    }
    else{
      result = 0;
    }
  }


  // Works for Bancor assets and old bancor pools
  function getRatioByPath(address _from, address _to, uint256 _amount) public view returns(uint256) {
    BancorNetworkInterface bancorNetwork = BancorNetworkInterface(
      getBancorContractAddresByName("BancorNetwork")
    );
    // get Bancor path array
    address[] memory path = bancorNetwork.conversionPath(_from, _to);
    // get Ratio
    return bancorNetwork.rateByPath(path, _amount);
  }



  // get addresses array of token path
  function getBancorPathForAssets(address _from, address _to) public view returns(address[] memory){
    BancorNetworkInterface bancorNetwork = BancorNetworkInterface(
      getBancorContractAddresByName("BancorNetwork")
    );

    address[] memory path = bancorNetwork.conversionPath(_from, _to);

    return path;
  }

  // update bancor registry
  function changeRegistryAddress(address _bancorRegistry) public onlyOwner{
    bancorRegistry = IContractRegistry(_bancorRegistry);
  }

  // update BancorPoolParser
  function changeBancorPoolParser(address _BancorPoolParser) public onlyOwner{
    BancorPoolParser = IBancorPoolParser(_BancorPoolParser);
  }
}