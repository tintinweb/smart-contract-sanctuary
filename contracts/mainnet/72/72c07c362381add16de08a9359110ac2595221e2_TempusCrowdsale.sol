pragma solidity 0.4.23;


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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 * @title MintableTokenInterface interface
 */
contract MintableTokenIface {
    function mint(address to, uint256 amount) public returns (bool);
}


/**
 * @title TempusCrowdsale
 * @dev TempusCrowdsale is a base contract for managing IQ-300 token crowdsale,
 * allowing investors to purchase project tokens with ether.
 */
contract TempusCrowdsale {
    using SafeMath for uint256;

    // Crowdsale owners
    mapping(address => bool) public owners;

    // The token being sold
    MintableTokenIface public token;

    // Addresses where funds are collected
    address[] public wallets;

    // Current phase Id
    uint256 public currentRoundId;

    // Maximum amount of tokens this contract can mint
    uint256 public tokensCap;

    // Amount of issued tokens
    uint256 public tokensIssued;

    // Amount of received Ethers in wei
    uint256 public weiRaised;

    // Minimum Deposit 0.1 ETH in wei
    uint256 public minInvestment = 100000000000000000;

    // Crowdsale phase with its own parameters
    struct Round {
        uint256 startTime;
        uint256 endTime;
        uint256 weiRaised;
        uint256 tokensIssued;
        uint256 tokensCap;
        uint256 tokenPrice;
    }

    Round[5] public rounds;

    /**
     * @dev TokenPurchase event emitted on token purchase
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @dev WalletAdded event emitted on wallet add
     * @param wallet the address of added account
     */
    event WalletAdded(address indexed wallet);

    /**
     * @dev WalletRemoved event emitted on wallet deletion
     * @param wallet the address of removed account
     */
    event WalletRemoved(address indexed wallet);

    /**
     * @dev OwnerAdded event emitted on owner add
     * @param newOwner is the address of added account
     */
    event OwnerAdded(address indexed newOwner);

    /**
     * @dev OwnerRemoved event emitted on owner removal
     * @param removedOwner is the address of removed account
     */
    event OwnerRemoved(address indexed removedOwner);

    /**
     * @dev SwitchedToNextRound event triggered when contract changes its phase
     * @param id is the index of the new phase
     */
    event SwitchedToNextRound(uint256 id);

    constructor(MintableTokenIface _token) public {
        token = _token;
        tokensCap = 100000000000000000;
        rounds[0] = Round(now, now.add(30 * 1 days), 0, 0, 20000000000000000, 50000000);
        rounds[1] = Round(now.add(30 * 1 days).add(1), now.add(60 * 1 days), 0, 0, 20000000000000000, 100000000);
        rounds[2] = Round(now.add(60 * 1 days).add(1), now.add(90 * 1 days), 0, 0, 20000000000000000, 200000000);
        rounds[3] = Round(now.add(90 * 1 days).add(1), now.add(120 * 1 days), 0, 0, 20000000000000000, 400000000);
        rounds[4] = Round(now.add(120 * 1 days).add(1), 1599999999, 0, 0, 20000000000000000, 800000000);
        currentRoundId = 0;
        owners[msg.sender] = true;
    }

    function() external payable {
        require(msg.sender != address(0));
        require(msg.value >= minInvestment);
        if (now > rounds[currentRoundId].endTime) {
            switchToNextRound();
        }
        uint256 tokenPrice = rounds[currentRoundId].tokenPrice;
        uint256 tokens = msg.value.div(tokenPrice);
        token.mint(msg.sender, tokens);
        emit TokenPurchase(msg.sender, msg.value, tokens);
        tokensIssued = tokensIssued.add(tokens);
        rounds[currentRoundId].tokensIssued = rounds[currentRoundId].tokensIssued.add(tokens);
        weiRaised = weiRaised.add(msg.value);
        rounds[currentRoundId].weiRaised = rounds[currentRoundId].weiRaised.add(msg.value);
        if (rounds[currentRoundId].tokensIssued >= rounds[currentRoundId].tokensCap) {
            switchToNextRound();
        }
        forwardFunds();
    }

    /**
     * @dev switchToNextRound sets the startTime, endTime and tokenCap of the next phase
     * and sets the next phase as current phase.
     */
    function switchToNextRound() public {
        uint256 prevRoundId = currentRoundId;
        uint256 nextRoundId = currentRoundId + 1;
        require(nextRoundId < rounds.length);
        rounds[prevRoundId].endTime = now;
        rounds[nextRoundId].startTime = now + 1;
        rounds[nextRoundId].endTime = now + 30;
        if (nextRoundId == rounds.length - 1) {
            rounds[nextRoundId].tokensCap = tokensCap.sub(tokensIssued);
        } else {
            rounds[nextRoundId].tokensCap = tokensCap.sub(tokensIssued).div(5);
        }
        currentRoundId = nextRoundId;
        emit SwitchedToNextRound(currentRoundId);
    }

    /**
     * @dev Add collecting wallet address to the list
     * @param _address Address of the wallet
     */
    function addWallet(address _address) public onlyOwner {
        require(_address != address(0));
        for (uint256 i = 0; i < wallets.length; i++) {
            require(_address != wallets[i]);
        }
        wallets.push(_address);
        emit WalletAdded(_address);
    }

    /**
     * @dev Delete wallet by its index
     * @param index Index of the wallet in the list
     */
    function delWallet(uint256 index) public onlyOwner {
        require(index < wallets.length);
        address walletToRemove = wallets[index];
        for (uint256 i = index; i < wallets.length - 1; i++) {
            wallets[i] = wallets[i + 1];
        }
        wallets.length--;
        emit WalletRemoved(walletToRemove);
    }

    /**
     * @dev Adds administrative role to address
     * @param _address The address that will get administrative privileges
     */
    function addOwner(address _address) public onlyOwner {
        owners[_address] = true;
        emit OwnerAdded(_address);
    }

    /**
     * @dev Removes administrative role from address
     * @param _address The address to remove administrative privileges from
     */
    function delOwner(address _address) public onlyOwner {
        owners[_address] = false;
        emit OwnerRemoved(_address);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    /**
     * @dev forwardFunds splits received funds ~equally between wallets
     * and sends receiwed ethers to them.
     */
    function forwardFunds() internal {
        uint256 value = msg.value.div(wallets.length);
        uint256 rest = msg.value.sub(value.mul(wallets.length));
        for (uint256 i = 0; i < wallets.length - 1; i++) {
            wallets[i].transfer(value);
        }
        wallets[wallets.length - 1].transfer(value + rest);
    }
}