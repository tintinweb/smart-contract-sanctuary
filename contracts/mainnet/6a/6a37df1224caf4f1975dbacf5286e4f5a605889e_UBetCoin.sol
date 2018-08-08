pragma solidity 0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
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


contract UBetCoin is StandardToken, Ownable {
  
    string public constant name = "UBetCoin";
    string public constant symbol = "UBET";
    uint8 public constant decimals = 0;
    uint256 public constant totalCoinSupply = 4000000000 * (10 ** uint256(decimals));  

    /// Base exchange rate is set to 1 ETH = 962 UBET.
    uint256 public ratePerOneEther = 962;

    /// Issue event index starting from 0.
    uint64 public issueIndex = 0;

    /// Emitted for each sucuessful token purchase.
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);
    
    // All funds will be transferred in this wallet.
    address public moneyWallet = 0x709cbaF04d5Bd1D62D156DBda13064f994938f28;
  
    struct UBetCheck {
      string accountNumber;
      string routingNumber;
      string institution;
      uint256 amount;
      string digitalCheckFingerPrint;
    }
    
    mapping (address => UBetCheck) UBetChecks;
    address[] public uBetCheckAccts;
    
    
    function UBetCoin() public {
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
      purchaseTokens(msg.sender);
    }
    
    /// @dev Register UBetCheck to the chain
    /// @param _beneficiary recipient ether address
    /// @param _accountNumber the account number stated in the check
    /// @param _routingNumber the routing number stated in the check
    /// @param _institution the name of the institution / bank in the check
    /// @param _amount the amount in currency in the chek
    /// @param _digitalCheckFingerPrint the hash 256 of the file
    function registerUBetCheck(address _beneficiary, string _accountNumber, string _routingNumber, string _institution,  uint256 _amount, string _digitalCheckFingerPrint) public payable onlyOwner {
      
      require(_beneficiary != address(0));
      
      require(bytes(_accountNumber).length != 0);
      require(bytes(_routingNumber).length != 0);
      require(bytes(_institution).length != 0);
      require(_amount > 0);
      require(bytes(_digitalCheckFingerPrint).length != 0);
      
      var uBetCheck = UBetChecks[_beneficiary];
      
      uBetCheck.accountNumber = _accountNumber;
      uBetCheck.routingNumber = _routingNumber;
      uBetCheck.amount = _amount;
      uBetCheck.digitalCheckFingerPrint = _digitalCheckFingerPrint;
      
      uBetCheckAccts.push(_beneficiary) -1;
    }
    
    /// @dev List all the checks in the
    function getUBetChecks() view public returns (address[]) {
      return uBetCheckAccts;
    }
    
    /// @dev Return UBetCheck information by supplying beneficiary adddress
    function getUBetCheck(address _address) view public returns (string, string, string, uint256, string) {
      return (UBetChecks[_address].accountNumber, 
              UBetChecks[_address].routingNumber, 
              UBetChecks[_address].institution,
              UBetChecks[_address].amount, 
              UBetChecks[_address].digitalCheckFingerPrint);
    }
        
    /// @dev Issue token based on Ether received.
    /// @param _beneficiary Address that newly issued token will be sent to.
    function purchaseTokens(address _beneficiary) public payable {
      // only accept a minimum amount of ETH?
      require(msg.value >= 0.00104 ether);

      uint256 tokens = computeTokenAmount(msg.value);
      doIssueTokens(_beneficiary, tokens);

      /// forward the funds to the money wallet
      moneyWallet.transfer(this.balance);
    }
    
    /// @dev return total count of registered UBet Checks
    function countUBetChecks() view public returns (uint) {
        return uBetCheckAccts.length;
    }
    
    /// @dev Issue tokens for a single buyer on the sale
    /// @param _beneficiary addresses that the sale tokens will be sent to.
    /// @param _tokens the amount of tokens, with decimals expanded (full).
    function issueTokens(address _beneficiary, uint256 _tokens) public onlyOwner {
      doIssueTokens(_beneficiary, _tokens);
    }

    /// @dev issue tokens for a single buyer
    /// @param _beneficiary addresses that the tokens will be sent to.
    /// @param _tokens the amount of tokens, with decimals expanded (full).
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
      require(_beneficiary != address(0));    

      // compute without actually increasing it
      uint256 increasedTotalSupply = totalSupply.add(_tokens);
    
      // increase token total supply
      totalSupply = increasedTotalSupply;
      // update the beneficiary balance to number of tokens sent
      balances[_beneficiary] = balances[_beneficiary].add(_tokens);

      // event is fired when tokens issued
      Issue(
          issueIndex++,
          _beneficiary,
          _tokens
      );
    }

    /// @dev Compute the amount of UBET token that can be purchased.
    /// @param ethAmount Amount of Ether to purchase UBET.
    /// @return Amount of UBET token to purchase
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
      tokens = ethAmount.mul(ratePerOneEther).div(10**18);
    }
}