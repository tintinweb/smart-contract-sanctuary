pragma solidity 0.4.15;

interface STQToken {
    function mint(address _to, uint256 _amount) external;
}

/**
 * @title Helps contracts guard agains rentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2b594e4648446b19">[email&#160;protected]</a>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
    require(msg.sender == owner);
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


/// @title Storiqa pre-sale contract
contract STQPreSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function STQPreSale(address token, address funds) {
        require(address(0) != address(token) && address(0) != address(funds));

        m_token = STQToken(token);
        m_funds = funds;
    }


    // PUBLIC interface: payments

    // fallback function as a shortcut
    function() payable {
        require(0 == msg.data.length);
        buy();  // only internal call here!
    }

    /// @notice ICO participation
    /// @return number of STQ tokens bought (with all decimal symbols)
    function buy()
        public
        payable
        nonReentrant
        returns (uint)
    {
        address investor = msg.sender;
        uint256 payment = msg.value;
        require(payment >= c_MinInvestment);
        require(now < 1507766400);

        // issue tokens
        uint stq = payment.mul(c_STQperETH);
        m_token.mint(investor, stq);

        // record payment
        m_funds.transfer(payment);
        FundTransfer(investor, payment, true);

        return stq;
    }

    /// @notice Tests ownership of the current caller.
    /// @return true if it&#39;s an owner
    // It&#39;s advisable to call it by new owner to make sure that the same erroneous address is not copy-pasted to
    // addOwner/changeOwner and to isOwner.
    function amIOwner() external constant onlyOwner returns (bool) {
        return true;
    }


    // FIELDS

    /// @notice starting exchange rate of STQ
    uint public constant c_STQperETH = 150000;

    /// @notice minimum investment
    uint public constant c_MinInvestment = 10 finney;

    /// @dev contract responsible for token accounting
    STQToken public m_token;

    /// @dev address responsible for investments accounting
    address public m_funds;
}