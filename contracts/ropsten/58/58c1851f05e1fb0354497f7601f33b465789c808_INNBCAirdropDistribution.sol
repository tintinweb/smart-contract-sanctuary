pragma solidity 0.4.24;

/**
 * @dev We use a fixed version of Solidity
 */


/**
 * @title ERC20Token Interface
 * @notice This is the interface to interact with ERC20 tokens
 * @dev As seen here https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20Token {
  function name() public view returns (string);
  function symbol() public view returns (string);
  function decimals() public view returns (uint);
  function totalSupply() public view returns (uint);
  function balanceOf(address account) public view returns (uint);
  function transfer(address to, uint amount) public returns (bool);
  function transferFrom(address from, address to, uint amount) public returns (bool);
  function approve(address spender, uint amount) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint);
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


/**
 * @title This contract handles the distribution of the bounties
 */
contract INNBCAirdropDistribution is Ownable {
  address public tokenINNBCAddress;

  function setINNBCTokenAddress(address tokenAddress) external onlyOwner() {
    require(tokenAddress != address(0), "Token address cannot be null");

    tokenINNBCAddress = tokenAddress;
  }

  function airdropTokens(address[] recipients, uint amountPerRecipient) external onlyOwner() {
    require(recipients.length <= 200, "Recipients list is too long");
    require(tokenINNBCAddress != address(0));

    ERC20Token tokenINNBC = ERC20Token(tokenINNBCAddress);

    require(
      recipients.length * amountPerRecipient <= tokenINNBC.allowance(msg.sender, address(this)),
      "This contract cannot handle this amount"
    );

    for (uint i = 0; i < recipients.length; i += 1) {
      tokenINNBC.transferFrom(msg.sender, recipients[i], amountPerRecipient);
    }
  }
}