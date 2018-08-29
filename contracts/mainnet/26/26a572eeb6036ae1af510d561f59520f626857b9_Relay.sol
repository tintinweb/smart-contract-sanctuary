pragma solidity 0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9bfffaedfedbfaf0f4f6f9fab5f8f4f6">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Relay is Ownable {
    address public licenseSalesContractAddress;
    address public registryContractAddress;
    address public apiRegistryContractAddress;
    address public apiCallsContractAddress;
    uint public version;

    // ------------------------------------------------------------------------
    // Constructor, establishes ownership because contract is owned
    // ------------------------------------------------------------------------
    constructor() public {
        version = 4;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens (just in case)
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Sets the license sales contract address
    // ------------------------------------------------------------------------
    function setLicenseSalesContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        licenseSalesContractAddress = newAddress;
    }

    // ------------------------------------------------------------------------
    // Sets the registry contract address
    // ------------------------------------------------------------------------
    function setRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        registryContractAddress = newAddress;
    }

    // ------------------------------------------------------------------------
    // Sets the api registry contract address
    // ------------------------------------------------------------------------
    function setApiRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiRegistryContractAddress = newAddress;
    }

    // ------------------------------------------------------------------------
    // Sets the api calls contract address
    // ------------------------------------------------------------------------
    function setApiCallsContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiCallsContractAddress = newAddress;
    }
}