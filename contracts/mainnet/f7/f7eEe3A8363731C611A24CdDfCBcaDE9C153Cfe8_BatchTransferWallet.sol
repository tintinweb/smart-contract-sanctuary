/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

/**
 *Submitted for verification at Etherscan.io on 2018-12-07
*/

pragma solidity ^0.4.23;
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

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BatchTransferWallet is Ownable {
    using SafeMath for uint256;

    /**
    * @dev Send token to multiple address
    * @param _investors The addresses of EOA that can receive token from this contract.
    * @param _tokenAmounts The values of token are sent from this contract.
    */
    function batchTransferFrom(address _tokenAddress, address[] _investors, uint[] _tokenAmounts) public {
        ERC20 token = ERC20(_tokenAddress);
        require(_investors.length == _tokenAmounts.length && _investors.length != 0);

        for (uint i = 0; i < _investors.length; i++) {
            require(_tokenAmounts[i] > 0 && _investors[i] != 0x0);
            token.transferFrom(msg.sender,_investors[i], _tokenAmounts[i]);
        }
    }

    /**
    * @dev return token balance this contract has
    * @return _address token balance this contract has.
    */
    function balanceOfContract(address _tokenAddress,address _address) public view returns (uint) {
        ERC20 token = ERC20(_tokenAddress);
        return token.balanceOf(_address);
    }
    
    function getTotalSendingAmount(uint256[] _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            totalSendingAmount += _amounts[i];
        }
    }
    // Events allow light clients to react on
    // changes efficiently.
    event Sent(address from, address to, uint amount);
    function transferMulti(address[] receivers, uint256[] amounts) payable {
        require(msg.value != 0 && msg.value >= getTotalSendingAmount(amounts));
        for (uint256 j = 0; j < amounts.length; j++) {
            receivers[j].transfer(amounts[j]);
            emit Sent(msg.sender, receivers[j], amounts[j]);
        }
    }
    /**
        * @dev Withdraw the amount of token that is remaining in this contract.
        * @param _address The address of EOA that can receive token from this contract.
        */
        function withdraw(address _address) public onlyOwner {
            require(_address != address(0));
            _address.transfer(address(this).balance);
        }
}