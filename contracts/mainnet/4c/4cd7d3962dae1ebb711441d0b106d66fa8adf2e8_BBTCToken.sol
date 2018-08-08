pragma solidity 0.4.21;
contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

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
        emit Transfer(msg.sender, _to, _value);
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
        emit Transfer(_from, _to, _value);
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
        emit Approval(msg.sender, _spender, _value);
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
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract BBTCToken is StandardToken, Owned {

    /* Constants */

    // Token Name
    string public constant name = "BloxOffice token";
    // Ticker Symbol
    string public constant symbol = "BBTC";
    // Decimals
    uint8 public constant decimals = 18;

    bool public tokenSaleClosed = false;



    /* Owners */

    // Ethereum fund owner wallet
    address public _fundowner = 0x761cE04C269314fAfCC545301414BfDA21539A75;

    // Dev Team multisig wallet
    address public _devteam = 0xb3871355181558059fB22ae7AfAd415499ae6f1E;

    // Advisors & Mentors multisig wallet
    address public _mentors = 0x589789B67aE612f47503E80ED14A18593C1C79BE;

    //Bounty address
    address public _bounty = 0x923A03dE5816CCB29684F6D420e774d721Ac6962;

    //private Sale; multisig wallet
    address public _privateSale = 0x90aBD12D92c0E5f5BcD2195ee3C6C15026506B96;

    /* Token Distribution */

    // Total supply of Tokens 999 Million
    uint256 public totalSupply = 999999999 * 10**uint256(decimals);

    // CrowdSale hard cap
    uint256 public TOKENS_SALE_HARD_CAP = 669999999 * 10**uint256(decimals);

    //Dev Team
    uint256 public DEV_TEAM = 160000000 * 10**uint256(decimals);

    //Mentors
    uint256 public MENTORS = 80000000 * 10**uint256(decimals);

    //Bounty
    uint256 public BOUNTY = 20000000 * 10**uint256(decimals);

    //Private Sale
    uint256 public PRIVATE = 70000000 * 10**uint256(decimals);

    /* Current max supply */
    uint256 public currentSupply;


    //Dates
    //Private Sale
    uint64 private constant privateSaleDate = 1519756200;

    //Pre-sale Start Date 15 April
    uint64 private constant presaleStartDate = 1523730600;
    //Pre-sale End Date 15 May
    uint64 private constant presaleEndDate = 1526408999;


    //CrowdSale Start Date 22-May
    uint64 private constant crowdSaleStart = 1526927400;
    //CrowdSale End Date 6 July
    uint64 private constant crowdSaleEnd = 1530901799;


    /* Base exchange rate is set to 1 ETH = 2500 BBTC */
    uint256 public constant BASE_RATE = 2500;

    /* Constructor */
    function BBTCToken(){
      //Assign the initial tokens
      //For dev team
      balances[_devteam] = DEV_TEAM;

      //For mentors
      balances[_mentors] = MENTORS;

      //For bounty
      balances[_bounty] = BOUNTY;

      //For private
      balances[_privateSale] = PRIVATE;

    }

    /// start Token sale
    function startSale () public onlyOwner{
      tokenSaleClosed = false;
    }

    //stop Token sale
    function stopSale () public onlyOwner {
      tokenSaleClosed = true;
    }

    /// @return if the token sale is finished
      function saleDue() public view returns (bool) {
          return crowdSaleEnd < uint64(block.timestamp);
      }

    modifier inProgress {
        require(currentSupply < TOKENS_SALE_HARD_CAP
                && !tokenSaleClosed
                && !saleDue());
        _;
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
        purchaseTokens(msg.sender);
    }

    /// @dev Issue token based on Ether received.
    /// @param _beneficiary Address that newly issued token will be sent to.
    function purchaseTokens(address _beneficiary) internal inProgress {

        uint256 tokens = computeTokenAmount(msg.value);

        balances[_beneficiary] = balances[_beneficiary].add(tokens);

        /// forward the raised funds to the fund address
        _fundowner.transfer(msg.value);
    }


    /// @dev Compute the amount of ING token that can be purchased.
    /// @param ethAmount Amount of Ether to purchase ING.
    /// @return Amount of ING token to purchase
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
        /// the percentage value (0-100) of the discount for each tier
        uint64 discountPercentage = currentTierDiscountPercentage();

        uint256 tokenBase = ethAmount.mul(BASE_RATE);
        uint256 tokenBonus = tokenBase.mul(discountPercentage).div(100);

        tokens = tokenBase.add(tokenBonus);
    }


    /// @dev Determine the current sale tier.
      /// @return the index of the current sale tier.
      function currentTierDiscountPercentage() internal view returns (uint64) {
          uint64 _now = uint64(block.timestamp);

          if(_now > crowdSaleStart) return 0;
          if(_now > presaleStartDate) return 10;
          if(_now > privateSaleDate) return 15;
          return 0;
      }

    /// @dev issue tokens for a single buyer
    /// @param _beneficiary addresses that the tokens will be sent to.
    /// @param _tokensAmount the amount of tokens, with decimals expanded (full).
    function doIssueTokens(address _beneficiary, uint256 _tokensAmount) public {
        require(_beneficiary != address(0));

        // compute without actually increasing it
        uint256 increasedTotalSupply = currentSupply.add(_tokensAmount);
        // roll back if hard cap reached
        require(increasedTotalSupply <= TOKENS_SALE_HARD_CAP);

        // increase token total supply
          currentSupply = increasedTotalSupply;
        // update the buyer&#39;s balance to number of tokens sent
        balances[_beneficiary] = balances[_beneficiary].add(_tokensAmount);
    }


    /// @dev Returns the current price.
    function price() public view returns (uint256 tokens) {
      return computeTokenAmount(1 ether);
    }
  }