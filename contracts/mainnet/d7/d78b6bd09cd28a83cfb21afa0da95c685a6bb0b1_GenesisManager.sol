pragma solidity 0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
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

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

contract ILivepeerToken is ERC20, Ownable {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _amount) public;
}

contract GenesisManager is Ownable {
    using SafeMath for uint256;

    // LivepeerToken contract
    ILivepeerToken public token;

    // Address of the token distribution contract
    address public tokenDistribution;
    // Address of the Livepeer bank multisig
    address public bankMultisig;
    // Address of the Minter contract in the Livepeer protocol
    address public minter;

    // Initial token supply issued
    uint256 public initialSupply;
    // Crowd&#39;s portion of the initial token supply
    uint256 public crowdSupply;
    // Company&#39;s portion of the initial token supply
    uint256 public companySupply;
    // Team&#39;s portion of the initial token supply
    uint256 public teamSupply;
    // Investors&#39; portion of the initial token supply
    uint256 public investorsSupply;
    // Community&#39;s portion of the initial token supply
    uint256 public communitySupply;

    // Token amount in grants for the team
    uint256 public teamGrantsAmount;
    // Token amount in grants for investors
    uint256 public investorsGrantsAmount;
    // Token amount in grants for the community
    uint256 public communityGrantsAmount;

    // Timestamp at which vesting grants begin their vesting period
    // and timelock grants release locked tokens
    uint256 public grantsStartTimestamp;

    // Map receiver addresses => contracts holding receivers&#39; vesting tokens
    mapping (address => address) public vestingHolders;
    // Map receiver addresses => contracts holding receivers&#39; time locked tokens
    mapping (address => address) public timeLockedHolders;

    enum Stages {
        // Stage for setting the allocations of the initial token supply
        GenesisAllocation,
        // Stage for the creating token grants and the token distribution
        GenesisStart,
        // Stage for the end of genesis when ownership of the LivepeerToken contract
        // is transferred to the protocol Minter
        GenesisEnd
    }

    // Current stage of genesis
    Stages public stage;

    // Check if genesis is at a particular stage
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    /**
     * @dev GenesisManager constructor
     * @param _token Address of the Livepeer token contract
     * @param _tokenDistribution Address of the token distribution contract
     * @param _bankMultisig Address of the company bank multisig
     * @param _minter Address of the protocol Minter
     */
    function GenesisManager(
        address _token,
        address _tokenDistribution,
        address _bankMultisig,
        address _minter,
        uint256 _grantsStartTimestamp
    )
        public
    {
        token = ILivepeerToken(_token);
        tokenDistribution = _tokenDistribution;
        bankMultisig = _bankMultisig;
        minter = _minter;
        grantsStartTimestamp = _grantsStartTimestamp;

        stage = Stages.GenesisAllocation;
    }

    /**
     * @dev Set allocations for the initial token supply at genesis
     * @param _initialSupply Initial token supply at genesis
     * @param _crowdSupply Tokens allocated for the crowd at genesis
     * @param _companySupply Tokens allocated for the company (for future distribution) at genesis
     * @param _teamSupply Tokens allocated for the team at genesis
     * @param _investorsSupply Tokens allocated for investors at genesis
     * @param _communitySupply Tokens allocated for the community at genesis
     */
    function setAllocations(
        uint256 _initialSupply,
        uint256 _crowdSupply,
        uint256 _companySupply,
        uint256 _teamSupply,
        uint256 _investorsSupply,
        uint256 _communitySupply
    )
        external
        onlyOwner
        atStage(Stages.GenesisAllocation)
    {
        require(_crowdSupply.add(_companySupply).add(_teamSupply).add(_investorsSupply).add(_communitySupply) == _initialSupply);

        initialSupply = _initialSupply;
        crowdSupply = _crowdSupply;
        companySupply = _companySupply;
        teamSupply = _teamSupply;
        investorsSupply = _investorsSupply;
        communitySupply = _communitySupply;
    }

    /**
     * @dev Start genesis
     */
    function start() external onlyOwner atStage(Stages.GenesisAllocation) {
        // Mint the initial supply
        token.mint(this, initialSupply);

        stage = Stages.GenesisStart;
    }

    /**
     * @dev Add a team grant for tokens with a vesting schedule
     * @param _receiver Grant receiver
     * @param _amount Amount of tokens included in the grant
     * @param _timeToCliff Seconds until the vesting cliff
     * @param _vestingDuration Seconds starting from the vesting cliff until the end of the vesting schedule
     */
    function addTeamGrant(
        address _receiver,
        uint256 _amount,
        uint256 _timeToCliff,
        uint256 _vestingDuration
    )
        external
        onlyOwner
        atStage(Stages.GenesisStart)
    {
        uint256 updatedGrantsAmount = teamGrantsAmount.add(_amount);
        // Amount of tokens included in team grants cannot exceed the team supply during genesis
        require(updatedGrantsAmount <= teamSupply);

        teamGrantsAmount = updatedGrantsAmount;

        addVestingGrant(_receiver, _amount, _timeToCliff, _vestingDuration);
    }

    /**
     * @dev Add an investor grant for tokens with a vesting schedule
     * @param _receiver Grant receiver
     * @param _amount Amount of tokens included in the grant
     * @param _timeToCliff Seconds until the vesting cliff
     * @param _vestingDuration Seconds starting from the vesting cliff until the end of the vesting schedule
     */
    function addInvestorGrant(
        address _receiver,
        uint256 _amount,
        uint256 _timeToCliff,
        uint256 _vestingDuration
    )
        external
        onlyOwner
        atStage(Stages.GenesisStart)
    {
        uint256 updatedGrantsAmount = investorsGrantsAmount.add(_amount);
        // Amount of tokens included in investor grants cannot exceed the investor supply during genesis
        require(updatedGrantsAmount <= investorsSupply);

        investorsGrantsAmount = updatedGrantsAmount;

        addVestingGrant(_receiver, _amount, _timeToCliff, _vestingDuration);
    }

    /**
     * @dev Add a grant for tokens with a vesting schedule. An internal helper function used by addTeamGrant and addInvestorGrant
     * @param _receiver Grant receiver
     * @param _amount Amount of tokens included in the grant
     * @param _timeToCliff Seconds until the vesting cliff
     * @param _vestingDuration Seconds starting from the vesting cliff until the end of the vesting schedule
     */
    function addVestingGrant(
        address _receiver,
        uint256 _amount,
        uint256 _timeToCliff,
        uint256 _vestingDuration
    )
        internal
    {
        // Receiver must not have already received a grant with a vesting schedule
        require(vestingHolders[_receiver] == address(0));

        // Create a vesting holder contract to act as the holder of the grant&#39;s tokens
        // Note: the vesting grant is revokable
        TokenVesting holder = new TokenVesting(_receiver, grantsStartTimestamp, _timeToCliff, _vestingDuration, true);
        vestingHolders[_receiver] = holder;

        // Transfer ownership of the vesting holder to the bank multisig
        // giving the bank multisig the ability to revoke the grant
        holder.transferOwnership(bankMultisig);

        token.transfer(holder, _amount);
    }

    /**
     * @dev Add a community grant for tokens that are locked until a predetermined time in the future
     * @param _receiver Grant receiver address
     * @param _amount Amount of tokens included in the grant
     */
    function addCommunityGrant(
        address _receiver,
        uint256 _amount
    )
        external
        onlyOwner
        atStage(Stages.GenesisStart)
    {
        uint256 updatedGrantsAmount = communityGrantsAmount.add(_amount);
        // Amount of tokens included in investor grants cannot exceed the community supply during genesis
        require(updatedGrantsAmount <= communitySupply);

        communityGrantsAmount = updatedGrantsAmount;

        // Receiver must not have already received a grant with timelocked tokens
        require(timeLockedHolders[_receiver] == address(0));

        // Create a timelocked holder contract to act as the holder of the grant&#39;s tokens
        TokenTimelock holder = new TokenTimelock(token, _receiver, grantsStartTimestamp);
        timeLockedHolders[_receiver] = holder;

        token.transfer(holder, _amount);
    }

    /**
     * @dev End genesis
     */
    function end() external onlyOwner atStage(Stages.GenesisStart) {
        // Transfer the crowd supply to the token distribution contract
        token.transfer(tokenDistribution, crowdSupply);
        // Transfer company supply to the bank multisig
        token.transfer(bankMultisig, companySupply);
        // Transfer ownership of the LivepeerToken contract to the protocol Minter
        token.transferOwnership(minter);

        stage = Stages.GenesisEnd;
    }
}