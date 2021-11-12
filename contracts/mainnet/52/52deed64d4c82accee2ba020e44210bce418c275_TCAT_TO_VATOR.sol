/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
  constructor() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external returns (uint256);
}

contract TCAT_TO_VATOR is Ownable {
    using SafeMath for uint256;
    
    // TCAT token contract address
    address public tokenAddressTCAT = 0x0E84D86C3745A05D65f8051407249cd1c4970346;
    
    // VATOR token contract address
    address public tokenAddressVATOR = 0x051Bda85FbC58AcE9D6060Ba9488aBE120ac072D;
    
    // Team address
    address public addressTeam = 0xD938FFD144253d61Ae7f26194E84fe9929de7b4b;
    
    function withdraw() public {
        require(Token(tokenAddressTCAT).balanceOf(msg.sender) > 0, "You don't have TCAT");
        
        uint256 tokenAmount = Token(tokenAddressTCAT).balanceOf(msg.sender);
        
        require(Token(tokenAddressTCAT).transferFrom(msg.sender, addressTeam, tokenAmount), "Could not transfer token.");
        require(Token(tokenAddressVATOR).transferFrom(addressTeam, msg.sender, tokenAmount), "Could not transfer tokens.");
    }
    
    function setTokenAddressTCAT(address _tokenAddress) public onlyOwner {
        tokenAddressTCAT = _tokenAddress;
    }
    
    function setTokenAddressVATOR(address _tokenAddress) public onlyOwner {
        tokenAddressVATOR = _tokenAddress;
    }
    
    function setTeamAddress(address _teamAddress) public onlyOwner {
        addressTeam = _teamAddress;
    }
    
    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
            
            Token(_tokenAddress).transfer(_to, _amount);
    }
}