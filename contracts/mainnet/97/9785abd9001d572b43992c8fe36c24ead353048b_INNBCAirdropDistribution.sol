pragma solidity 0.4.24;



/**
 * @title ERC20Token Interface
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


/**
 * @title This contract handles the airdrop distribution
 */
contract INNBCAirdropDistribution is Ownable {
  address public tokenINNBCAddress;

  /**
   * @dev Sets the address of the INNBC token
   * @param tokenAddress The address of the INNBC token contract
   */
  function setINNBCTokenAddress(address tokenAddress) external onlyOwner() {
    require(tokenAddress != address(0), "Token address cannot be null");

    tokenINNBCAddress = tokenAddress;
  }

  /**
   * @dev Batch transfers tokens from the owner account to the recipients
   * @param recipients An array of the addresses of the recipients
   * @param amountPerRecipient An array of amounts of tokens to give to each recipient
   */
  function airdropTokens(address[] recipients, uint[] amountPerRecipient) external onlyOwner() {
    /* 100 recipients is the limit, otherwise we may reach the gas limit */
    require(recipients.length <= 100, "Recipients list is too long");

    /* Both arrays need to have the same length */
    require(recipients.length == amountPerRecipient.length, "Arrays do not have the same length");

    /* We check if the address of the token contract is set */
    require(tokenINNBCAddress != address(0), "INNBC token contract address cannot be null");

    ERC20Token tokenINNBC = ERC20Token(tokenINNBCAddress);

    /* We check if the owner has enough tokens for everyone */
    require(
      calculateSum(amountPerRecipient) <= tokenINNBC.balanceOf(msg.sender),
      "Sender does not have enough tokens"
    );

    /* We check if the contract is allowed to handle this amount */
    require(
      calculateSum(amountPerRecipient) <= tokenINNBC.allowance(msg.sender, address(this)),
      "This contract is not allowed to handle this amount"
    );

    /* If everything is okay, we can transfer the tokens */
    for (uint i = 0; i < recipients.length; i += 1) {
      tokenINNBC.transferFrom(msg.sender, recipients[i], amountPerRecipient[i]);
    }
  }

  /**
   * @dev Calculates the sum of an array of uints
   * @param a An array of uints
   * @return The sum as an uint
   */
  function calculateSum(uint[] a) private pure returns (uint) {
    uint sum;

    for (uint i = 0; i < a.length; i = SafeMath.add(i, 1)) {
      sum = SafeMath.add(sum, a[i]);
    }

    return sum;
  }
}