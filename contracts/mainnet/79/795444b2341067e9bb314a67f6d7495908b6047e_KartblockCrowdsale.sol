pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
      _transferOwnership(newOwner);
    }

     /**
      * @dev Transfers control of the contract to a newOwner.
      * @param newOwner The address to transfer ownership to.
      */
    function _transferOwnership(address newOwner) internal {
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
         uint256 c = a * b;
         assert(a == 0 || c / a == b);
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

     function max64(uint64 a, uint64 b) internal pure returns (uint64) {
         return a >= b ? a : b;
     }

     function min64(uint64 a, uint64 b) internal pure returns (uint64) {
         return a < b ? a : b;
     }

     function max256(uint256 a, uint256 b) internal pure returns (uint256) {
         return a >= b ? a : b;
     }

     function min256(uint256 a, uint256 b) internal pure returns (uint256) {
         return a < b ? a : b;
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
 contract ERC20 {
     uint256 public totalSupply;

     function balanceOf(address _owner) public constant returns (uint256 balance);
     function transfer(address _to, uint256 _value) public returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     function approve(address _spender, uint256 _value) public returns (bool success);
     function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
 contract BasicToken is ERC20Basic {
     using SafeMath for uint256;

     mapping (address => uint256) balances;

     // 2018-09-24 00:00:00 AST - start time for pre sale
     uint256 public presaleStartTime = 1537736400;

     // 2018-10-24 23:59:59 AST - end time for pre sale
     uint256 public presaleEndTime = 1540414799;

     // 2018-11-04 00:00:00 AST - start time for main sale
     uint256 public mainsaleStartTime = 1541278800;

     // 2019-01-04 23:59:59 AST - end time for main sale
     uint256 public mainsaleEndTime = 1546635599;

     address public constant investor1 = 0x8013e8F85C9bE7baA19B9Fd9a5Bc5C6C8D617446;
     address public constant investor2 = 0xf034E5dB3ed5Cb26282d2DC5802B21DB3205B882;
     address public constant investor3 = 0x1A7dD28A461D7e0D75b89b214d5188E0304E5726;

     /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
     function transfer(address _to, uint256 _value) public returns (bool) {
         require(_to != address(0));
         require(_value <= balances[msg.sender]);
         if (( (msg.sender == investor1) || (msg.sender == investor2) || (msg.sender == investor3)) && (now < (presaleStartTime + 300 days))) {
           revert();
         }
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
     function balanceOf(address _owner) public constant returns (uint256 balance) {
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
         if (( (_from == investor1) || (_from == investor2) || (_from == investor3)) && (now < (presaleStartTime + 300 days))) {
           revert();
         }

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
     function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }

     /**
      * approve should be called when allowed[_spender] == 0. To increment
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      */
     function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
         allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
         emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
         return true;
     }

     function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
         uint oldValue = allowed[msg.sender][_spender];
         if (_subtractedValue > oldValue) {
             allowed[msg.sender][_spender] = 0;
         }
         else {
             allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
         }
         emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
         return true;
     }

 }

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    string public constant name = "Kartblock";
    string public constant symbol = "KBT";
    uint8 public constant decimals = 18;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount, address _owner) canMint internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint internal returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract Whitelist is Ownable {

    mapping (address => bool) verifiedAddresses;

    function isAddressWhitelist(address _address) public view returns (bool) {
        return verifiedAddresses[_address];
    }

    function whitelistAddress(address _newAddress) external onlyOwner {
        verifiedAddresses[_newAddress] = true;
    }

    function removeWhitelistAddress(address _oldAddress) external onlyOwner {
        require(verifiedAddresses[_oldAddress]);
        verifiedAddresses[_oldAddress] = false;
    }

    function batchWhitelistAddresses(address[] _addresses) external onlyOwner {
        for (uint cnt = 0; cnt < _addresses.length; cnt++) {
            assert(!verifiedAddresses[_addresses[cnt]]);
            verifiedAddresses[_addresses[cnt]] = true;
        }
    }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public PresaleWeiRaised;
    uint256 public mainsaleWeiRaised;
    uint256 public tokenAllocated;

    event WalletChanged(address indexed previousWallet, address indexed newWallet);

    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function transferWallet(address newWallet) public onlyOwner {
      _transferOwnership(newWallet);
    }

    function _transferWallet(address newWallet) internal {
      require(newWallet != address(0));
      emit WalletChanged(owner, newWallet);
      wallet = newWallet;
    }
}

contract KartblockCrowdsale is Ownable, Crowdsale, Whitelist, MintableToken {
    using SafeMath for uint256;


    // ===== Cap & Goal Management =====
    uint256 public constant presaleCap = 10000 * (10 ** uint256(decimals));
    uint256 public constant mainsaleCap = 175375 * (10 ** uint256(decimals));
    uint256 public constant mainsaleGoal = 11700 * (10 ** uint256(decimals));

    // ============= Token Distribution ================
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
    uint256 public constant totalTokensForSale = 195500000 * (10 ** uint256(decimals));
    uint256 public constant tokensForFuture = 760000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForswap = 4500000 * (10 ** uint256(decimals));
    uint256 public constant tokensForInvester1 = 16000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForInvester2 = 16000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForInvester3 = 8000000 * (10 ** uint256(decimals));

    // how many token units a buyer gets per wei
    uint256 public rate;
    mapping (address => uint256) public deposited;
    address[] investors;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Finalized();

    constructor(
      address _owner,
      address _wallet
      ) public Crowdsale(_wallet) {

        require(_wallet != address(0));
        require(_owner != address(0));
        owner = _owner;
        mintingFinished = false;
        totalSupply = INITIAL_SUPPLY;
        rate = 1140;
        bool resultMintForOwner = mintForOwner(owner);
        require(resultMintForOwner);
        balances[0x9AF6043d1B74a7c9EC7e3805Bc10e41230537A8B] = balances[0x9AF6043d1B74a7c9EC7e3805Bc10e41230537A8B].add(tokensForswap);
        mainsaleWeiRaised.add(tokensForswap);
        balances[investor1] = balances[investor1].add(tokensForInvester1);
        balances[investor2] = balances[investor1].add(tokensForInvester2);
        balances[investor3] = balances[investor1].add(tokensForInvester3);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _investor) public  payable returns (uint256){
        require(_investor != address(0));
        require(validPurchase());
        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount);
        if (tokens == 0) {revert();}

        // update state
        if (isPresalePeriod())  {
          PresaleWeiRaised = PresaleWeiRaised.add(weiAmount);
        } else if (isMainsalePeriod()) {
          mainsaleWeiRaised = mainsaleWeiRaised.add(weiAmount);
        }
        tokenAllocated = tokenAllocated.add(tokens);
        if (verifiedAddresses[_investor]) {
           mint(_investor, tokens, owner);
        }else {
          investors.push(_investor);
          deposited[_investor] = deposited[_investor].add(tokens);
        }
        emit TokenPurchase(_investor, weiAmount, tokens);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
      return _weiAmount.mul(rate);
    }

    // ====================== Price Management =================
    function setPrice() public onlyOwner {
      if (isPresalePeriod()) {
        rate = 1140;
      } else if (isMainsalePeriod()) {
        rate = 1597;
      }
    }

    function isPresalePeriod() public view returns (bool) {
      if (now >= presaleStartTime && now < presaleEndTime) {
        return true;
      }
      return false;
    }

    function isMainsalePeriod() public view returns (bool) {
      if (now >= mainsaleStartTime && now < mainsaleEndTime) {
        return true;
      }
      return false;
    }

    function mintForOwner(address _wallet) internal returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[_wallet] = balances[_wallet].add(INITIAL_SUPPLY);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
      bool withinCap =  true;
      if (isPresalePeriod()) {
        withinCap = PresaleWeiRaised.add(msg.value) <= presaleCap;
      } else if (isMainsalePeriod()) {
        withinCap = mainsaleWeiRaised.add(msg.value) <= mainsaleCap;
      }
      bool withinPeriod = isPresalePeriod() || isMainsalePeriod();
      bool minimumContribution = msg.value >= 0.5 ether;
      return withinPeriod && minimumContribution && withinCap;
    }

    function readyForFinish() internal view returns(bool) {
      bool endPeriod = now < mainsaleEndTime;
      bool reachCap = tokenAllocated <= mainsaleCap;
      return endPeriod || reachCap;
    }


    // Finish: Mint Extra Tokens as needed before finalizing the Crowdsale.
    function finalize(
      address _tokensForFuture
      ) public onlyOwner returns (bool result) {
        require(_tokensForFuture != address(0));
        require(readyForFinish());
        result = false;
        mint(_tokensForFuture, tokensForFuture, owner);
        address contractBalance = this;
        wallet.transfer(contractBalance.balance);
        finishMinting();
        emit Finalized();
        result = true;
    }

    function transferToInvester() public onlyOwner returns (bool result) {
        require( now >= 1548363600);
        for (uint cnt = 0; cnt < investors.length; cnt++) {
            mint(investors[cnt], deposited[investors[cnt]], owner);
        }
        result = true;
    }

}