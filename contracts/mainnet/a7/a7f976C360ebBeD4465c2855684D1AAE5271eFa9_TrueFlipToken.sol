pragma solidity ^0.4.11;

contract Owned {

    address public owner = msg.sender;
    address public potentialOwner;

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    modifier onlyPotentialOwner {
      require(msg.sender == potentialOwner);
      _;
    }

    event NewOwner(address old, address current);
    event NewPotentialOwner(address old, address potential);

    function setOwner(address _new)
      onlyOwner
    {
      NewPotentialOwner(owner, _new);
      potentialOwner = _new;
      // owner = _new;
    }

    function confirmOwnership()
      onlyPotentialOwner
    {
      NewOwner(owner, potentialOwner);
      owner = potentialOwner;
      potentialOwner = 0;
    }
}

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract AbstractToken {
    // This is not an abstract function, because solc won&#39;t recognize generated getter functions for public variables as functions
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}


/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
contract StandardToken is AbstractToken {

    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    /*
     *  Read and write storage functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read storage functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}


/// @title Token contract - Implements Standard Token Interface for TrueFlip.
/// @author Zerion - <<span class="__cf_email__" data-cfemail="fb9295999483bb819e89929495d59294">[email&#160;protected]</span>>
contract TrueFlipToken is StandardToken, SafeMath, Owned {
    /*
     * External contracts
     */
    address public mintAddress;
    /*
     * Token meta data
     */
    string constant public name = "TrueFlip";
    string constant public symbol = "TFL";
    uint8 constant public decimals = 8;

    // 1 050 000 TFL tokens were minted during PreICO
    // 13&#160;650&#160;000 TFL tokens can be minted during ICO
    // 2 100 000 TFL tokens can be minted for Advisory
    // 4 200 000 TFL tokens can be minted for Team
    // Overall, 21 000 000 TFL tokens can be minted
    uint constant public maxSupply = 21000000 * 10 ** 8;

    // Only true until finalize function is called.
    bool public mintingAllowed = true;
    // Address where minted tokens are reserved
    address constant public mintedTokens = 0x6049604960496049604960496049604960496049;

    modifier onlyMint() {
        // Only minter is allowed to proceed.
        require(msg.sender == mintAddress);
        _;
    }

    /// @dev Function to change address that is allowed to do emission.
    /// @param newAddress Address of new emission contract.
    function setMintAddress(address newAddress)
        public
        onlyOwner
        returns (bool)
    {
        if (mintAddress == 0x0)
            mintAddress = newAddress;
    }

    /// @dev Contract constructor function sets initial token balances.
    function TrueFlipToken(address ownerAddress)
    {
        owner = ownerAddress;
        balances[mintedTokens] = mul(1050000, 10 ** 8);
        totalSupply = balances[mintedTokens];
    }

    function mint(address beneficiary, uint amount, bool transfer)
        external
        onlyMint
        returns (bool success)
    {
        require(mintingAllowed == true);
        require(add(totalSupply, amount) <= maxSupply);
        totalSupply = add(totalSupply, amount);
        if (transfer) {
            balances[beneficiary] = add(balances[beneficiary], amount);
        } else {
            balances[mintedTokens] = add(balances[mintedTokens], amount);
            if (beneficiary != 0) {
                allowed[mintedTokens][beneficiary] = amount;
            }
        }
        return true;
    }

    function finalize()
        public
        onlyMint
        returns (bool success)
    {
        mintingAllowed = false;
        return true;
    }

    function requestWithdrawal(address beneficiary, uint amount)
        public
        onlyOwner
    {
        allowed[mintedTokens][beneficiary] = amount;
    }

    function withdrawTokens()
        public
    {
        transferFrom(mintedTokens, msg.sender, allowance(mintedTokens, msg.sender));
    }
}