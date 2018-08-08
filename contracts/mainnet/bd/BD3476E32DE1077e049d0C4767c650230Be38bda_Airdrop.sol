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

contract Airdrop is Ownable, Destroyable {
    using SafeMath for uint256;

    /*
     *   Structures
     */
    // Holder of tokens
    struct Beneficiary {
        uint256 balance;
        uint256 airdrop;
        bool isBeneficiary;
    }

    /*
     *  State
     */
    bool public filled;
    bool public airdropped;
    uint256 public airdropLimit;
    uint256 public currentCirculating;
    uint256 public toVault;
    address public vault;
    address[] public addresses;
    Token public token;
    mapping(address => Beneficiary) public beneficiaries;


    /*
     *  Events
     */
    event NewBeneficiary(address _beneficiary);
    event SnapshotTaken(uint256 _totalBalance, uint256 _totalAirdrop, uint256 _toBurn,uint256 _numberOfBeneficiaries, uint256 _numberOfAirdrops);
    event Airdropped(uint256 _totalAirdrop, uint256 _numberOfAirdrops);
    event TokenChanged(address _prevToken, address _token);
    event VaultChanged(address _prevVault, address _vault);
    event AirdropLimitChanged(uint256 _prevLimit, uint256 _airdropLimit);
    event CurrentCirculatingChanged(uint256 _prevCirculating, uint256 _currentCirculating);
    event Cleaned(uint256 _numberOfBeneficiaries);
    event Vaulted(uint256 _tokensBurned);

    /*
     *  Modifiers
     */
    modifier isNotBeneficiary(address _beneficiary) {
        require(!beneficiaries[_beneficiary].isBeneficiary);
        _;
    }
    modifier isBeneficiary(address _beneficiary) {
        require(beneficiaries[_beneficiary].isBeneficiary);
        _;
    }
    modifier isFilled() {
        require(filled);
        _;
    }
    modifier isNotFilled() {
        require(!filled);
        _;
    }
    modifier wasAirdropped() {
        require(airdropped);
        _;
    }
    modifier wasNotAirdropped() {
        require(!airdropped);
        _;
    }

    /*
     *  Behavior
     */

    /**
     * @dev Constructor.
     * @param _token The token address
     * @param _airdropLimit The token limit by airdrop in wei
     * @param _currentCirculating The current circulating tokens in wei
     * @param _vault The address where tokens will be vaulted
     */
    function Airdrop(address _token, uint256 _airdropLimit, uint256 _currentCirculating, address _vault) public{
        require(_token != address(0));
        token = Token(_token);
        airdropLimit = _airdropLimit;
        currentCirculating = _currentCirculating;
        vault = _vault;
    }

    /**
     * @dev Allows the sender to register itself as a beneficiary for the airdrop.
     */
    function() payable public {
        addBeneficiary(msg.sender);
    }


    /**
     * @dev Allows the sender to register itself as a beneficiary for the airdrop.
     */
    function register() public {
        addBeneficiary(msg.sender);
    }

    /**
     * @dev Allows the owner to register a beneficiary for the airdrop.
     * @param _beneficiary The address of the beneficiary
     */
    function registerBeneficiary(address _beneficiary) public
    onlyOwner {
        addBeneficiary(_beneficiary);
    }

    /**
     * @dev Allows the owner to register beneficiaries for the airdrop.
     * @param _beneficiaries The array of addresses
     */
    function registerBeneficiaries(address[] _beneficiaries) public
    onlyOwner {
        for (uint i = 0; i < _beneficiaries.length; i++) {
            addBeneficiary(_beneficiaries[i]);
        }
    }

    /**
     * @dev Add a beneficiary for the airdrop.
     * @param _beneficiary The address of the beneficiary
     */
    function addBeneficiary(address _beneficiary) private
    isNotBeneficiary(_beneficiary) {
        require(_beneficiary != address(0));
        beneficiaries[_beneficiary] = Beneficiary({
            balance : 0,
            airdrop : 0,
            isBeneficiary : true
            });
        addresses.push(_beneficiary);
        emit NewBeneficiary(_beneficiary);
    }

    /**
     * @dev Take the balance of all the beneficiaries.
     */
    function takeSnapshot() public
    onlyOwner
    isNotFilled
    wasNotAirdropped {
        uint256 totalBalance = 0;
        uint256 totalAirdrop = 0;
        uint256 airdrops = 0;
        for (uint i = 0; i < addresses.length; i++) {
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            beneficiary.balance = token.balanceOf(addresses[i]);
            totalBalance = totalBalance.add(beneficiary.balance);
            if (beneficiary.balance > 0) {
                beneficiary.airdrop = (beneficiary.balance.mul(airdropLimit).div(currentCirculating));
                totalAirdrop = totalAirdrop.add(beneficiary.airdrop);
                airdrops = airdrops.add(1);
            }
        }
        filled = true;
        toVault = airdropLimit.sub(totalAirdrop);
        emit SnapshotTaken(totalBalance, totalAirdrop, toVault, addresses.length, airdrops);
    }

    /**
     * @dev Start the airdrop.
     */
    function airdropAndVault() public
    onlyOwner
    isFilled
    wasNotAirdropped {
        uint256 airdrops = 0;
        uint256 totalAirdrop = 0;
        for (uint256 i = 0; i < addresses.length; i++)
        {
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            if (beneficiary.airdrop > 0) {
                require(token.transfer(addresses[i], beneficiary.airdrop));
                totalAirdrop = totalAirdrop.add(beneficiary.airdrop);
                airdrops = airdrops.add(1);
            }
        }
        airdropped = true;
        currentCirculating = currentCirculating.add(airdropLimit);
        emit Airdropped(totalAirdrop, airdrops);

        token.transfer(vault, toVault);
        emit Vaulted(toVault);
    }

    /**
     * @dev Reset all the balances to 0 and the state to false.
     */
    function clean() public
    onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++)
        {
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            beneficiary.balance = 0;
            beneficiary.airdrop = 0;
        }
        filled = false;
        airdropped = false;
        toVault = 0;
        emit Cleaned(addresses.length);
    }

    /**
     * @dev Allows the owner to change the token address.
     * @param _token New token address.
     */
    function changeToken(address _token) public
    onlyOwner {
        emit TokenChanged(address(token), _token);
        token = Token(_token);
    }

    /**
     * @dev Allows the owner to change the vault address.
     * @param _vault New vault address.
     */
    function changeVault(address _vault) public
    onlyOwner {
        emit VaultChanged(vault, _vault);
        vault = _vault;
    }

    /**
     * @dev Allows the owner to change the token limit by airdrop.
     * @param _airdropLimit The token limit by airdrop in wei.
     */
    function changeAirdropLimit(uint256 _airdropLimit) public
    onlyOwner {
        emit AirdropLimitChanged(airdropLimit, _airdropLimit);
        airdropLimit = _airdropLimit;
    }

    /**
     * @dev Allows the owner to change the token limit by airdrop.
     * @param _currentCirculating The current circulating tokens in wei.
     */
    function changeCurrentCirculating(uint256 _currentCirculating) public
    onlyOwner {
        emit CurrentCirculatingChanged(currentCirculating, _currentCirculating);
        currentCirculating = _currentCirculating;
    }

    /**
     * @dev Allows the owner to flush the eth.
     */
    function flushEth() public onlyOwner {
        owner.transfer(address(this).balance);
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

    /**
     * @dev Get the token balance of the contract.
     * @return _balance The token balance of this contract
     */
    function tokenBalance() view public returns (uint256 _balance) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Get the token balance of the beneficiary.
     * @param _beneficiary The address of the beneficiary
     * @return _balance The token balance of the beneficiary
     */
    function getBalanceAtSnapshot(address _beneficiary) view public returns (uint256 _balance) {
        return beneficiaries[_beneficiary].balance / 1 ether;
    }

    /**
     * @dev Get the airdrop reward of the beneficiary.
     * @param _beneficiary The address of the beneficiary
     * @return _airdrop The token balance of the beneficiary
     */
    function getAirdropAtSnapshot(address _beneficiary) view public returns (uint256 _airdrop) {
        return beneficiaries[_beneficiary].airdrop / 1 ether;
    }

    /**
     * @dev Allows a beneficiary to verify if he is already registered.
     * @param _beneficiary The address of the beneficiary
     * @return _isBeneficiary The boolean value
     */
    function amIBeneficiary(address _beneficiary) view public returns (bool _isBeneficiary) {
        return beneficiaries[_beneficiary].isBeneficiary;
    }

    /**
     * @dev Get the number of beneficiaries.
     * @return _length The number of beneficiaries
     */
    function beneficiariesLength() view public returns (uint256 _length) {
        return addresses.length;
    }
}