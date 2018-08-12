pragma solidity 0.4.24;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: contracts/VestTokenAllocation.sol

/**
 * @title VestTokenAllocation contract
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="096e7c7a7d687f666e7c6064687b686c7a496e64686065276a6664">[email&#160;protected]</a>>
 */
contract VestTokenAllocation is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    uint256 public allocatedTokens;
    uint256 public canSelfDestruct;

    mapping (address => uint256) public totalTokensLocked;
    mapping (address => uint256) public releasedTokens;

    ERC20 public golix;
    address public tokenDistribution;

    event Released(address beneficiary, uint256 amount);

    /**
     * @dev creates the locking contract with vesting mechanism
     * as well as ability to set tokens for addresses and time contract can self-destruct
     * @param _token GolixToken address
     * @param _tokenDistribution GolixTokenDistribution contract address
     * @param _start timestamp representing the beginning of the token vesting process
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest. ie 1 year in secs
     * @param _duration time in seconds of the period in which the tokens completely vest. ie 4 years in secs
     * @param _canSelfDestruct timestamp of when contract is able to selfdestruct
     */
    function VestTokenAllocation
        (
            ERC20 _token,
            address _tokenDistribution,
            uint256 _start,
            uint256 _cliff,
            uint256 _duration,
            uint256 _canSelfDestruct
        )
        public
    {
        require(_token != address(0) && _cliff != 0);
        require(_cliff <= _duration);
        require(_start > now);
        require(_canSelfDestruct > _duration.add(_start));

        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;

        golix = ERC20(_token);
        tokenDistribution = _tokenDistribution;
        canSelfDestruct = _canSelfDestruct;
    }

    modifier onlyOwnerOrTokenDistributionContract() {
        require(msg.sender == address(owner) || msg.sender == address(tokenDistribution));
        _;
    }
    /**
     * @dev Adds vested token allocation
     * @param beneficiary Ethereum address of a person
     * @param allocationValue Number of tokens allocated to person
     */
    function addVestTokenAllocation(address beneficiary, uint256 allocationValue)
        external
        onlyOwnerOrTokenDistributionContract
    {
        require(totalTokensLocked[beneficiary] == 0 && beneficiary != address(0)); // can only add once.

        allocatedTokens = allocatedTokens.add(allocationValue);
        require(allocatedTokens <= golix.balanceOf(this));

        totalTokensLocked[beneficiary] = allocationValue;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = releasableAmount();

        require(unreleased > 0);

        releasedTokens[msg.sender] = releasedTokens[msg.sender].add(unreleased);

        golix.safeTransfer(msg.sender, unreleased);

        emit Released(msg.sender, unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(releasedTokens[msg.sender]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 totalBalance = totalTokensLocked[msg.sender];

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }

    /**
     * @dev allow for selfdestruct possibility and sending funds to owner
     */
    function kill() public onlyOwner {
        require(now >= canSelfDestruct);
        uint256 balance = golix.balanceOf(this);

        if (balance > 0) {
            golix.transfer(msg.sender, balance);
        }

        selfdestruct(owner);
    }
}