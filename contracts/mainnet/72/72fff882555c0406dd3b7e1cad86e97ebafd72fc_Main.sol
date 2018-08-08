pragma solidity ^0.4.22;

// File: contracts/interfaces/IERC20Token.sol

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

// File: zeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/Main.sol

contract Bancor {
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn)
    public
    payable
    returns (uint256);

}

contract Main is Claimable {

    Bancor bancor;

    function Main(address _bancor) {
        bancor = Bancor(_bancor);
    }

    function transferToken(
        address[] path,
        address receiverAddress,
        address executor,
        uint256 amount
    )
    public
    returns
    (
        bool
    )
    {
        //TODO: require
        //TODO: events

        IERC20Token[] memory pathConverted = new IERC20Token[](path.length);

        for (uint i = 0; i < path.length; i++) {
            pathConverted[i] = IERC20Token(path[i]);
        }

        require(IERC20Token(path[0]).transferFrom(msg.sender, address(this), amount), "transferFrom msg.sender failed");
        require(IERC20Token(path[0]).approve(address(bancor), amount), "approve to bancor failed");
        uint256 amountReceived = bancor.quickConvert(pathConverted, amount, 1);
        require(IERC20Token(path[path.length - 1]).transfer(receiverAddress, amountReceived), "transfer back to receiverAddress failed");
        return true;
    }

}