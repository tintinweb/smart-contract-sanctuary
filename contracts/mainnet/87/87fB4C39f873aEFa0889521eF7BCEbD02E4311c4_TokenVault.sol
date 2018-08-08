pragma solidity ^0.4.21;

/**
 * Changes by https://www.docademic.com/
 */

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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Destroyable is Ownable{
    /**
     * @notice Allows to destroy the contract and return the tokens to the owner.
     */
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}


interface Token {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address who) view external returns (uint256);
}

contract TokenVault is Ownable, Destroyable {
    using SafeMath for uint256;

    Token public token;

    /**
     * @dev Constructor.
     * @param _token The token address
     */
    function TokenVault(address _token) public{
        require(_token != address(0));
        token = Token(_token);
    }

    /**
     * @dev Get the token balance of the contract.
     * @return _balance The token balance of this contract in wei
     */
    function Balance() view public returns (uint256 _balance) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Get the token balance of the contract.
     * @return _balance The token balance of this contract in ether
     */
    function BalanceEth() view public returns (uint256 _balance) {
        return token.balanceOf(address(this)) / 1 ether;
    }

    /**
     * @dev Allows the owner to flush the tokens of the contract.
     */
    function transferTokens(address _to, uint256 amount) public onlyOwner {
        token.transfer(_to, amount);
    }


    /**
     * @dev Allows the owner to flush the tokens of the contract.
     */
    function flushTokens() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Allows the owner to destroy the contract and return the tokens to the owner.
     */
    function destroy() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
        selfdestruct(owner);
    }

}