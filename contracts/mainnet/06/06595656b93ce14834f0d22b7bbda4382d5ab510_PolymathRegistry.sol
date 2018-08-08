pragma solidity ^0.4.24;

/**
 * @title Utility contract to allow pausing and unpausing of certain functions
 */
contract Pausable {

    event Pause(uint256 _timestammp);
    event Unpause(uint256 _timestamp);

    bool public paused = false;

    /**
    * @notice Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @notice Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

   /**
    * @notice called by the owner to pause, triggers stopped state
    */
    function _pause() internal {
        require(!paused);
        paused = true;
        emit Pause(now);
    }

    /**
    * @notice called by the owner to unpause, returns to normal state
    */
    function _unpause() internal {
        require(paused);
        paused = false;
        emit Unpause(now);
    }

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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Utility contract to allow owner to retreive any ERC20 sent to the contract
 */
contract ReclaimTokens is Ownable {

    /**
    * @notice Reclaim all ERC20Basic compatible tokens
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0));
        ERC20Basic token = ERC20Basic(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance));
    }
}

/**
 * @title Core functionality for registry upgradability
 */
contract PolymathRegistry is ReclaimTokens {

    mapping (bytes32 => address) public storedAddresses;

    event LogChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);

    /**
     * @notice Get the contract address
     * @param _nameKey is the key for the contract address mapping
     * @return address
     */
    function getAddress(string _nameKey) view public returns(address) {
        bytes32 key = keccak256(bytes(_nameKey));
        require(storedAddresses[key] != address(0), "Invalid address key");
        return storedAddresses[key];
    }

    /**
     * @notice change the contract address
     * @param _nameKey is the key for the contract address mapping
     * @param _newAddress is the new contract address
     */
    function changeAddress(string _nameKey, address _newAddress) public onlyOwner {
        bytes32 key = keccak256(bytes(_nameKey));
        emit LogChangeAddress(_nameKey, storedAddresses[key], _newAddress);
        storedAddresses[key] = _newAddress;
    }


}