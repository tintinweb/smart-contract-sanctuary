/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-12
*/

pragma solidity ^0.5.1;


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner external {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Multisender is Ownable {

    function multisend(address _tokenAddr, address[] calldata _to, uint256[] calldata _value) external onlyOwner returns (bool _success) {
        assert(_to.length == _value.length);
        //assert(_to.length <= 150);
        IERC20 token = IERC20(_tokenAddr);
        for (uint8 i = 0; i < _to.length; i++) {
            require(token.transfer(_to[i], _value[i]));
        }
        return true;
    }
    
    function refund(address _tokenAddr) external onlyOwner {
        IERC20 token = IERC20(_tokenAddr);
        uint256 _balance = token.balanceOf(address(this));
        require(_balance > 0);
        require(token.transfer(msg.sender, _balance));
    }
    
    function() external {
        revert();
    }
}