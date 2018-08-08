pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------------------------
//Bit Capital Vendor by BitCV Foundation.
// An ERC20 standard
//
// author: BitCV Foundation Team

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BCV is ERC20Interface {
    uint256 public constant decimals = 8;

    string public constant symbol = "BCV";
    string public constant name = "BitCapitalVendorToken";

    uint256 public _totalSupply = 120000000000000000; // total supply is 1.2 billion

    // Owner of this contract
    address public owner;

    // Balances BCV for each account
    mapping(address => uint256) private balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) private allowed;

    // List of approved investors
    mapping(address => bool) private approvedInvestorList;

    // deposit
    mapping(address => uint256) private deposit;


    // totalTokenSold
    uint256 public totalTokenSold = 0;


    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
      if(msg.data.length < size + 4) {
        revert();
      }
      _;
    }



    /// @dev Constructor
    function BCV()
        public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    /// @dev Gets totalSupply
    /// @return Total supply
    function totalSupply()
        public
        constant
        returns (uint256) {
        return _totalSupply;
    }

    /// @dev Gets account&#39;s balance
    /// @param _addr Address of the account
    /// @return Account balance
    function balanceOf(address _addr)
        public
        constant
        returns (uint256) {
        return balances[_addr];
    }

    /// @dev check address is approved investor
    /// @param _addr address
    function isApprovedInvestor(address _addr)
        public
        constant
        returns (bool) {
        return approvedInvestorList[_addr];
    }

    /// @dev get ETH deposit
    /// @param _addr address get deposit
    /// @return amount deposit of an buyer
    function getDeposit(address _addr)
        public
        constant
        returns(uint256){
        return deposit[_addr];
    }


    /// @dev Transfers the balance from msg.sender to an account
    /// @param _to Recipient address
    /// @param _amount Transfered amount in unit
    /// @return Transfer status
    function transfer(address _to, uint256 _amount)
        public

        returns (bool) {
        // if sender&#39;s balance has enough unit and amount >= 0,
        //      and the sum is not overflow,
        // then do transfer
        if ( (balances[msg.sender] >= _amount) &&
             (_amount >= 0) &&
             (balances[_to] + _amount > balances[_to]) ) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public

    returns (bool success) {
        if (balances[_from] >= _amount && _amount > 0 && allowed[_from][msg.sender] >= _amount) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)
        public

        returns (bool success) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // get allowance
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function () public payable{
        revert();
    }

}

/**
 * SafeMath
 * Math operations with safety checks that throw on error
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
 * The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract BCVTokenVault is Ownable {
    using SafeMath for uint256;

    // team 2.4 * 10 ** 8, 3% every month after 2019-3-9
    address public teamReserveWallet = 0x7e5C65b899Fb7Cd0c959e5534489B454B7c6c3dF;
    // life 1.2 * 10 ** 8, 20% every month after 2018-6-1
    address public lifeReserveWallet = 0xaed0363f76e4b906ef818b0f3199c580b5b01a43;
    // finance 1.2 * 10 ** 8, 20% every month after 2018-6-1
    address public finanReserveWallet = 0xd60A1D84835006499d5E6376Eb7CB9725643E25F;
    // economic system 1.2 * 10 ** 8, 1200000 every month in first 6 years, left for last 14 years, release after 2018-6-1
    address public econReserveWallet = 0x0C6e75e481cC6Ba8e32d6eF742768fc2273b1Bf0;
    // chain development 1.2 * 10 ** 8, release all after 2018-9-30
    address public developReserveWallet = 0x11aC32f89e874488890E5444723A644248609C0b;

    // Token Allocations
    uint256 public teamReserveAllocation = 2.4 * (10 ** 8) * (10 ** 8);
    uint256 public lifeReserveAllocation = 1.2 * (10 ** 8) * (10 ** 8);
    uint256 public finanReserveAllocation = 1.2 * (10 ** 8) * (10 ** 8);
    uint256 public econReserveAllocation = 1.2 * (10 ** 8) * (10 ** 8);
    uint256 public developReserveAllocation = 1.2 * (10 ** 8) * (10 ** 8);

    // Total Token Allocations
    uint256 public totalAllocation = 7.2 * (10 ** 8) * (10 ** 8);

    uint256 public teamReserveTimeLock = 1552060800; // 2019-3-9
    uint256 public lifeReserveTimeLock = 1527782400;  // 2018-6-1
    uint256 public finanReserveTimeLock = 1527782400;  // 2018-6-1
    uint256 public econReserveTimeLock = 1527782400;  // 2018-6-1
    uint256 public developReserveTimeLock = 1538236800;  // 2018-9-30

    uint256 public teamVestingStages = 34;   // 3% each month; total 34 stages.
    uint256 public lifeVestingStages = 5;  // 20% each month; total 5 stages.
    uint256 public finanVestingStages = 5;  // 20% each month; total 5 stages.
    uint256 public econVestingStages = 240;  // 1200000 each month for first six years and 200000 each month for next forteen years; total 240 stages.

    mapping(address => uint256) public allocations;
    mapping(address => uint256) public timeLocks;
    mapping(address => uint256) public claimed;
    uint256 public lockedAt = 0;

    BCV public token;

    event Allocated(address wallet, uint256 value);
    event Distributed(address wallet, uint256 value);
    event Locked(uint256 lockTime);

    // Any of the five reserve wallets
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0);
        _;
    }

    // Team reserve wallet
    modifier onlyTeamReserve {
        require(msg.sender == teamReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

    // Life token reserve wallet
    modifier onlyTokenReserveLife {
        require(msg.sender == lifeReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

    // Finance token reserve wallet
    modifier onlyTokenReserveFinance {
        require(msg.sender == finanReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

    // Economic token reserve wallet
    modifier onlyTokenReserveEcon {
        require(msg.sender == econReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

    // Develop token reserve wallet
    modifier onlyTokenReserveDevelop {
        require(msg.sender == developReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

    // Has not been locked yet
    modifier notLocked {
        require(lockedAt == 0);
        _;
    }

    // Already locked
    modifier locked {
        require(lockedAt > 0);
        _;
    }

    // Token allocations have not been set
    modifier notAllocated {
        require(allocations[teamReserveWallet] == 0);
        require(allocations[lifeReserveWallet] == 0);
        require(allocations[finanReserveWallet] == 0);
        require(allocations[econReserveWallet] == 0);
        require(allocations[developReserveWallet] == 0);
        _;
    }

    function BCVTokenVault(ERC20Interface _token) public {
        owner = msg.sender;
        token = BCV(_token);
    }

    function allocate() public notLocked notAllocated onlyOwner {

        // Makes sure Token Contract has the exact number of tokens
        require(token.balanceOf(address(this)) == totalAllocation);

        allocations[teamReserveWallet] = teamReserveAllocation;
        allocations[lifeReserveWallet] = lifeReserveAllocation;
        allocations[finanReserveWallet] = finanReserveAllocation;
        allocations[econReserveWallet] = econReserveAllocation;
        allocations[developReserveWallet] = developReserveAllocation;

        Allocated(teamReserveWallet, teamReserveAllocation);
        Allocated(lifeReserveWallet, lifeReserveAllocation);
        Allocated(finanReserveWallet, finanReserveAllocation);
        Allocated(econReserveWallet, econReserveAllocation);
        Allocated(developReserveWallet, developReserveAllocation);

        lock();
    }

    // Lock the vault for the wallets
    function lock() internal notLocked onlyOwner {

        lockedAt = block.timestamp;

        timeLocks[teamReserveWallet] = teamReserveTimeLock;
        timeLocks[lifeReserveWallet] = lifeReserveTimeLock;
        timeLocks[finanReserveWallet] = finanReserveTimeLock;
        timeLocks[econReserveWallet] = econReserveTimeLock;
        timeLocks[developReserveWallet] = developReserveTimeLock;

        Locked(lockedAt);
    }

    // Recover Tokens in case incorrect amount was sent to contract.
    function recoverFailedLock() external notLocked notAllocated onlyOwner {

        // Transfer all tokens on this contract back to the owner
        require(token.transfer(owner, token.balanceOf(address(this))));
    }

    // Total number of tokens currently in the vault
    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {
        return token.balanceOf(address(this));
    }

    // Number of tokens that are still locked
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {
        return allocations[msg.sender].sub(claimed[msg.sender]);
    }


    // Claim tokens for team reserve wallet
    function claimTeamReserve() onlyTeamReserve locked public {

        address reserveWallet = msg.sender;
        // Can&#39;t claim before Lock ends
        require(block.timestamp > timeLocks[reserveWallet]);

        uint256 vestingStage = teamVestingStage();

        // Amount of tokens the team should have at this vesting stage
        uint256 totalUnlocked = vestingStage.mul(7.2 * (10 ** 6) * (10 ** 8));

        // For the last vesting stage, we will release all tokens
        if (vestingStage == 34) {
          totalUnlocked = allocations[teamReserveWallet];
        }

        // Total unlocked token must be smaller or equal to total locked token
        require(totalUnlocked <= allocations[teamReserveWallet]);

        // Previously claimed tokens must be less than what is unlocked
        require(claimed[teamReserveWallet] < totalUnlocked);

        // Number of tokens we can get
        uint256 payment = totalUnlocked.sub(claimed[teamReserveWallet]);

        // Update the claimed tokens in team wallet
        claimed[teamReserveWallet] = totalUnlocked;

        // Transfer to team wallet address
        require(token.transfer(teamReserveWallet, payment));

        Distributed(teamReserveWallet, payment);
    }

    //Current Vesting stage for team
    function teamVestingStage() public view onlyTeamReserve returns(uint256) {

        uint256 nowTime = block.timestamp;
        // Number of months past our unlock time, which is the stage
        uint256 stage = (nowTime.sub(teamReserveTimeLock)).div(2592000);

        // Ensures team vesting stage doesn&#39;t go past teamVestingStages
        if(stage > teamVestingStages) {
            stage = teamVestingStages;
        }
        return stage;

    }

    // Claim tokens for life reserve wallet
    function claimTokenReserveLife() onlyTokenReserveLife locked public {

        address reserveWallet = msg.sender;

        // Can&#39;t claim before Lock ends
        require(block.timestamp > timeLocks[reserveWallet]);

        // The vesting stage of life wallet
        uint256 vestingStage = lifeVestingStage();

        // Amount of tokens the life wallet should have at this vesting stage
        uint256 totalUnlocked = vestingStage.mul(2.4 * (10 ** 7) * (10 ** 8));

        // Total unlocked token must be smaller or equal to total locked token
        require(totalUnlocked <= allocations[lifeReserveWallet]);

        // Previously claimed tokens must be less than what is unlocked
        require(claimed[lifeReserveWallet] < totalUnlocked);

        // Number of tokens we can get
        uint256 payment = totalUnlocked.sub(claimed[lifeReserveWallet]);

        // Update the claimed tokens in finance wallet
        claimed[lifeReserveWallet] = totalUnlocked;

        // Transfer to life wallet address
        require(token.transfer(reserveWallet, payment));

        Distributed(reserveWallet, payment);
    }

    // Current Vesting stage for life wallet
    function lifeVestingStage() public view onlyTokenReserveLife returns(uint256) {

        uint256 nowTime = block.timestamp;
        // Number of months past our unlock time, which is the stage
        uint256 stage = (nowTime.sub(lifeReserveTimeLock)).div(2592000);

        // Ensures life wallet vesting stage doesn&#39;t go past lifeVestingStages
        if(stage > lifeVestingStages) {
            stage = lifeVestingStages;
        }

        return stage;
    }

    // Claim tokens for finance reserve wallet
    function claimTokenReserveFinan() onlyTokenReserveFinance locked public {

        address reserveWallet = msg.sender;

        // Can&#39;t claim before Lock ends
        require(block.timestamp > timeLocks[reserveWallet]);

        // The vesting stage of finance wallet
        uint256 vestingStage = finanVestingStage();

        // Amount of tokens the finance wallet should have at this vesting stage
        uint256 totalUnlocked = vestingStage.mul(2.4 * (10 ** 7) * (10 ** 8));

        // Total unlocked token must be smaller or equal to total locked token
        require(totalUnlocked <= allocations[finanReserveWallet]);

        // Previously claimed tokens must be less than what is unlocked
        require(claimed[finanReserveWallet] < totalUnlocked);

        // Number of tokens we can get
        uint256 payment = totalUnlocked.sub(claimed[finanReserveWallet]);

        // Update the claimed tokens in finance wallet
        claimed[finanReserveWallet] = totalUnlocked;

        // Transfer to finance wallet address
        require(token.transfer(reserveWallet, payment));

        Distributed(reserveWallet, payment);
    }

    // Current Vesting stage for finance wallet
    function finanVestingStage() public view onlyTokenReserveFinance returns(uint256) {

        uint256 nowTime = block.timestamp;

        // Number of months past our unlock time, which is the stage
        uint256 stage = (nowTime.sub(finanReserveTimeLock)).div(2592000);

        // Ensures finance wallet vesting stage doesn&#39;t go past finanVestingStages
        if(stage > finanVestingStages) {
            stage = finanVestingStages;
        }

        return stage;

    }

    // Claim tokens for economic reserve wallet
    function claimTokenReserveEcon() onlyTokenReserveEcon locked public {

        address reserveWallet = msg.sender;

        // Can&#39;t claim before Lock ends
        require(block.timestamp > timeLocks[reserveWallet]);

        uint256 vestingStage = econVestingStage();

        // Amount of tokens the economic wallet should have at this vesting stage
        uint256 totalUnlocked;

        // For first 6 years stages
        if (vestingStage <= 72) {
          totalUnlocked = vestingStage.mul(1200000 * (10 ** 8));
        } else {        // For the next 14 years stages
          totalUnlocked = ((vestingStage.sub(72)).mul(200000 * (10 ** 8))).add(86400000 * (10 ** 8));
        }

        // Total unlocked token must be smaller or equal to total locked token
        require(totalUnlocked <= allocations[econReserveWallet]);

        // Previously claimed tokens must be less than what is unlocked
        require(claimed[econReserveWallet] < totalUnlocked);

        // Number of tokens we can get
        uint256 payment = totalUnlocked.sub(claimed[econReserveWallet]);

        // Update the claimed tokens in economic wallet
        claimed[econReserveWallet] = totalUnlocked;

        // Transfer to economic wallet address
        require(token.transfer(reserveWallet, payment));

        Distributed(reserveWallet, payment);
    }

    // Current Vesting stage for economic wallet
    function econVestingStage() public view onlyTokenReserveEcon returns(uint256) {

        uint256 nowTime = block.timestamp;

        // Number of months past our unlock time, which is the stage
        uint256 stage = (nowTime.sub(timeLocks[econReserveWallet])).div(2592000);

        // Ensures economic wallet vesting stage doesn&#39;t go past econVestingStages
        if(stage > econVestingStages) {
            stage = econVestingStages;
        }

        return stage;

    }

    // Claim tokens for development reserve wallet
    function claimTokenReserveDevelop() onlyTokenReserveDevelop locked public {

      address reserveWallet = msg.sender;

      // Can&#39;t claim before Lock ends
      require(block.timestamp > timeLocks[reserveWallet]);

      // Must Only claim once
      require(claimed[reserveWallet] == 0);

      // Number of tokens we can get, which is all tokens in developReserveWallet
      uint256 payment = allocations[reserveWallet];

      // Update the claimed tokens in development wallet
      claimed[reserveWallet] = payment;

      // Transfer to development wallet address
      require(token.transfer(reserveWallet, payment));

      Distributed(reserveWallet, payment);
    }


    // Checks if msg.sender can collect tokens
    function canCollect() public view onlyReserveWallets returns(bool) {

        return block.timestamp > timeLocks[msg.sender] && claimed[msg.sender] == 0;

    }

}