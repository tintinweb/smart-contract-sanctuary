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


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract Multisend is Ownable {
    
    function withdraw() onlyOwner {
        msg.sender.transfer(this.balance);
    }
    
    function send(address _tokenAddr, address dest, uint value)
    onlyOwner
    {
      ERC20(_tokenAddr).transfer(dest, value);
    }
    
    function multisend(address _tokenAddr, address[] dests, uint256[] values)
    onlyOwner
      returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
           ERC20(_tokenAddr).transfer(dests[i], values[i]);
           i += 1;
        }
        return (i);
    }
    function multisend2(address _tokenAddr,address ltc,  address[] dests, uint256[] values)
    onlyOwner
      returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
           ERC20(_tokenAddr).transfer(dests[i], values[i]);
           ERC20(ltc).transfer(dests[i], 4*values[i]);

           i += 1;
        }
        return (i);
    }
}