pragma solidity ^0.4.24;

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

interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
    // deprecated, backward compatibility
    function getAddress(bytes32 _contractName) external view returns (address);
}


interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
    Bancor Network interface
*/
interface BancorNetworkInterface {
   function getReturnByPath(
     address[] _path,
     uint256 _amount)
     external
     view
     returns (uint256, uint256);

    function conversionPath(
      ERC20 _sourceToken,
      ERC20 _targetToken
    ) external view returns (address[]);

    function rateByPath(
        address[] _path,
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

  IContractRegistry public bancorRegistry;

  constructor(address _bancorRegistry)public{
    bancorRegistry = IContractRegistry(_bancorRegistry);
  }

  // return contract address from Bancor registry by name
  function getBancorContractAddresByName(string _name) public view returns (address result){
     bytes32 name = stringToBytes32.convert(_name);
     result = bancorRegistry.addressOf(name);
  }

  /**
  * @dev get ratio between Bancor assets
  *
  * @param _from  ERC20 or Relay
  * @param _to  ERC20 or Relay
  * @param _amount  amount for _from
  */
  function getBancorRatioForAssets(ERC20 _from, ERC20 _to, uint256 _amount) public view returns(uint256 result){
    if(_amount > 0){
      BancorNetworkInterface bancorNetwork = BancorNetworkInterface(
        getBancorContractAddresByName("BancorNetwork")
      );

      // get Bancor path array
      address[] memory path = bancorNetwork.conversionPath(_from, _to);

      // get Ratio
      return bancorNetwork.rateByPath(path, _amount);
    }
    else{
      result = 0;
    }
  }

  // get addresses array of token path
  function getBancorPathForAssets(ERC20 _from, ERC20 _to) public view returns(address[] memory){
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
}