pragma solidity ^0.4.13;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    function () payable public {
        ReceivedEther(msg.sender, msg.value);
    }
}

contract DelegateProxy is TokenRecipient, Ownable {

    /**
     * Execute a DELEGATECALL from the proxy contract
     *
     * @dev Owner only
     * @param dest Address to which the call will be sent
     * @param calldata Calldata to send
     * @return Result of the delegatecall (success or failure)
     */
    function delegateProxy(address dest, bytes calldata)
        public
        onlyOwner
        returns (bool result)
    {
        return dest.delegatecall(calldata);
    }

    /**
     * Execute a DELEGATECALL and assert success
     *
     * @dev Same functionality as `delegateProxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param calldata Calldata to send
     */
    function delegateProxyAssert(address dest, bytes calldata)
        public
    {
        require(delegateProxy(dest, calldata));
    }

}

contract WyvernDAOProxy is DelegateProxy {

    function WyvernDAOProxy ()
        public
    {
        owner = msg.sender;
    }

}