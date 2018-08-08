pragma solidity ^0.4.21;

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MainframeTokenDistribution is Ownable {

  uint public totalDistributed;
  ERC20 mainframeToken;

  event TokensDistributed(address receiver, uint amount);

  constructor(address tokenAddress) public {
    mainframeToken = ERC20(tokenAddress);
  }

  function distributeTokens(address tokenOwner, address[] recipients, uint[] values) onlyOwner external {
    require(recipients.length == values.length);
    for(uint i = 0; i < recipients.length; i++) {
      if(values[i] > 0) {
        require(mainframeToken.transferFrom(tokenOwner, recipients[i], values[i]));
        emit TokensDistributed(recipients[i], values[i]);
        totalDistributed += values[i];
      }
    }
  }

  function emergencyERC20Drain(ERC20 token) external onlyOwner {
    // owner can drain tokens that are sent here by mistake
    uint256 amount = token.balanceOf(this);
    token.transfer(owner, amount);
  }
}