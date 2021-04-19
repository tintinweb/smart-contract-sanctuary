/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity ^0.4.18;


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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.18;



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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.18;


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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: @tokenfoundry/sale-contracts/contracts/sale/DisbursementHandler.sol

pragma solidity 0.4.18;





contract DisbursementHandler is Ownable {

    struct Disbursement {
        uint256 timestamp;
        uint256 tokens;
    }

    event LogSetup(address indexed vestor, uint256 tokens, uint256 timestamp);
    event LogChangeTimestamp(address indexed vestor, uint256 index, uint256 timestamp);
    event LogWithdraw(address indexed to, uint256 value);

    ERC20 public token;
    mapping(address => Disbursement[]) public disbursements;
    mapping(address => uint256) public withdrawnTokens;

    function DisbursementHandler(address _token) public {
        token = ERC20(_token);
    }

    /// @dev Called by the sale contract to create a disbursement.
    /// @param vestor The address of the beneficiary.
    /// @param tokens Amount of tokens to be locked.
    /// @param timestamp Funds will be locked until this timestamp.
    function setupDisbursement(
        address vestor,
        uint256 tokens,
        uint256 timestamp
    )
        public
        onlyOwner
    {
        require(block.timestamp < timestamp);
        disbursements[vestor].push(Disbursement(timestamp, tokens));
        LogSetup(vestor, timestamp, tokens);
    }

    /// @dev Change an existing disbursement.
    /// @param vestor The address of the beneficiary.
    /// @param timestamp Funds will be locked until this timestamp.
    /// @param index Index of the DisbursementVesting in the vesting array.
    function changeTimestamp(
        address vestor,
        uint256 index,
        uint256 timestamp
    )
        public
        onlyOwner
    {
        require(block.timestamp < timestamp);
        require(index < disbursements[vestor].length);
        disbursements[vestor][index].timestamp = timestamp;
        LogChangeTimestamp(vestor, index, timestamp);
    }

    /// @dev Transfers tokens to a given address
    /// @param to Address of token receiver
    /// @param value Number of tokens to transfer
    function withdraw(address to, uint256 value)
        public
    {
        uint256 maxTokens = calcMaxWithdraw();
        uint256 withdrawAmount = value < maxTokens ? value : maxTokens;
        withdrawnTokens[msg.sender] = SafeMath.add(withdrawnTokens[msg.sender], withdrawAmount);
        token.transfer(to, withdrawAmount);
        LogWithdraw(to, value);
    }

    /// @dev Calculates the maximum amount of vested tokens
    /// @return Number of vested tokens to withdraw
    function calcMaxWithdraw()
        public
        constant
        returns (uint256)
    {
        uint256 maxTokens = 0;
        Disbursement[] storage temp = disbursements[msg.sender];
        for (uint256 i = 0; i < temp.length; i++) {
            if (block.timestamp > temp[i].timestamp) {
                maxTokens = SafeMath.add(maxTokens, temp[i].tokens);
            }
        }
        maxTokens = SafeMath.sub(maxTokens, withdrawnTokens[msg.sender]);
        return maxTokens;
    }
}