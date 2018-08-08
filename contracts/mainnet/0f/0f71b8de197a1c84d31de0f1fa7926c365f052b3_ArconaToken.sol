pragma solidity ^0.4.21;

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
 
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, require mintingFinished before start transfers
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  bool public mintingFinished = false;

  mapping(address => uint256) releaseTime;
  // Only after finishMinting and checks for bounty accounts time restrictions
  modifier timeAllowed() {
    require(mintingFinished);
    require(releaseTime[msg.sender] == 0 || now > releaseTime[msg.sender]); //finishSale + releasedays * 1 days
    _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public timeAllowed returns (bool) {
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

  // release time of freezed account
  function checkReleaseAt(address _owner) public constant returns (uint256 date) {
    return releaseTime[_owner];
  }

  // change restricted releaseXX account
  function changeReleaseAccount(address _owner, address _newowner) internal returns (bool) {
    require(balances[_newowner] == 0);
    require(releaseTime[_owner] != 0 );
    require(releaseTime[_newowner] == 0 );
    balances[_newowner] = balances[_owner];
    releaseTime[_newowner] = releaseTime[_owner];
    balances[_owner] = 0;
    releaseTime[_owner] = 0;
    return true;
  }

  // release Customer&#39;s account after KYC
  function releaseAccount(address _owner) internal returns (bool) {
    releaseTime[_owner] = now;
    return true;
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
    require(mintingFinished);
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @param _releaseTime The (optional) freeze time - KYC & bounty accounts.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount, uint256 _releaseTime) internal canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    if ( _releaseTime > 0 ) {
        releaseTime[_to] = _releaseTime;
    }
    emit Transfer(0x0, _to, _amount);
    return true;
  }

  // drain tokens
  function unMint(address _from) internal returns (bool) {
    totalSupply = totalSupply.sub(balances[_from]);
    emit Transfer(_from, 0x0, balances[_from]);
    balances[_from] = 0;
    return true;
  }
 
}
  
   
contract ArconaToken is MintableToken {

    string public constant name = "Arcona Distribution Contract";
    string public constant symbol = "ARCONA";
    uint8 public constant decimals = 18;
   
    using SafeMath for uint;
    
    address public multisig;
    address public restricted;
    address public registerbot;
    address public certbot;
    address public release6m;
    address public release12m;
    address public release18m;

    mapping (address => bool) registered;
    mapping (address => address) referral;
    mapping (string => address) certificate;

    uint restrictedPercent = 40;
    uint refererPercent = 55; // 5.5%
    uint first24Percent = 50; // 50%
    uint auctionPercent = 5; // 5%
    uint bonusPeriod = 21; // 21 days (20 + 1st day whitelist sale)

    uint public startSale;
    uint public finishSale;
    bool public isGlobalPause=false;
    uint public minTokenSale = 10*10**18; // min 10 tokens
    uint public totalWeiSale = 2746*10**18; // softcap reached on preICO:  0x516130856e743090af9d7fd95d6fc94c8743a4e1
    bool public isFinished=false;

    uint public startAuction;
    uint public finishAuction;
    uint public hardcap = 25*10**6; // USD
    uint public rateSale = 400*10**18; // 1ETH = 400 ARN
    uint public rateUSD = 500; // ETH Course in USD

    // constructor
    function ArconaToken(uint256 _startSale,uint256 _finishSale,address _multisig,address _restricted,address _registerbot,address _certbot, address _release6m, address _release12m, address _release18m) public  {
        multisig = _multisig;
        restricted = _restricted;
        registerbot = _registerbot;
        certbot = _certbot;
        release6m = _release6m;
        release12m = _release12m;
        release18m = _release18m;
        startSale = _startSale;
        finishSale = _finishSale;
    }

    modifier isRegistered() {
        require (registered[msg.sender]);
        _;
    }

    modifier anySaleIsOn() {
        require(now > startSale && now < finishSale && !isGlobalPause);
        _;
    }

    modifier isUnderHardCap() {
        uint totalUsdSale = rateUSD.mul(totalWeiSale).div(1 ether);
        require(totalUsdSale <= hardcap);
        _;
    }

    function changefirst24Percent(uint _percent) public onlyOwner {
        first24Percent = _percent;
    }

    function changeCourse(uint _usd) public onlyOwner {
        rateUSD = _usd;
    }

    function changeMultisig(address _new) public onlyOwner {
        multisig = _new;
    }

    function changeRegisterBot(address _new) public onlyOwner {
        registerbot = _new;
    }

    function changeCertBot(address _new) public onlyOwner {
        certbot = _new;
    }

    function changeRestricted(address _new) public onlyOwner {
        if (isFinished) {
            changeReleaseAccount(restricted,_new);
        }
        restricted = _new;
    }

    function proceedKYC(address _customer) public {
        require(msg.sender == registerbot || msg.sender == owner);
        require(_customer != address(0));
       releaseAccount(_customer);
    }

    function changeRelease6m(address _new) public onlyOwner {
        if (isFinished) {
            changeReleaseAccount(release6m,_new);
        }
        release6m = _new;
    }

    function changeRelease12m(address _new) public onlyOwner {
        if (isFinished) {
            changeReleaseAccount(release12m,_new);
        }
        release12m = _new;
    }

    function changeRelease18m(address _new) public onlyOwner {
        if (isFinished) {
            changeReleaseAccount(release18m,_new);
        }
        release18m = _new;
    }

    function addCertificate(string _id,  address _owner) public {
        require(msg.sender == certbot || msg.sender == owner);
        require(certificate[_id] == address(0));
        if (_owner != address(0)) {
            certificate[_id] = _owner;
        } else {
            certificate[_id] = owner;
        }    
    }

    function editCertificate(string _id,  address _newowner) public {
        require(certificate[_id] != address(0));
        require(msg.sender == certificate[_id] || msg.sender == certbot || msg.sender == owner );
        certificate[_id] = _newowner;
    }

    function checkCertificate(string _id) public view returns (address) {
        return certificate[_id];
    }

    function deleteCertificate(string _id) public  {
        require(msg.sender == certbot || msg.sender == owner);
        delete certificate[_id];
    }

    function registerCustomer(address _customer, address _referral) public {
        require(msg.sender == registerbot || msg.sender == owner);
        require(_customer != address(0));
        registered[_customer] = true;
        if (_referral != address(0) && _referral != _customer) {
            referral[_customer] = _referral;
        }
    }

    function checkCustomer(address _customer) public view returns (bool, address) {
        return ( registered[_customer], referral[_customer]);
    }

    // import preICO customers from 0x516130856e743090af9d7fd95d6fc94c8743a4e1
    function importCustomer(address _customer, address _referral, uint _tokenAmount) public {
        require(msg.sender == registerbot || msg.sender == owner);
        require(_customer != address(0));
        require(now < startSale); // before ICO starts
        registered[_customer] = true;
        if (_referral != address(0) && _referral != _customer) {
            referral[_customer] = _referral;
        }
        mint(_customer, _tokenAmount, now + 99 * 1 years); // till KYC is completed
    }

    function deleteCustomer(address _customer) public {
        require(msg.sender == registerbot || msg.sender == owner);
        require(_customer!= address(0));
        delete registered[_customer];
        delete referral[_customer];
        // Drain tokens
        unMint(_customer);
    }

    function globalPause(bool _state) public onlyOwner {
        isGlobalPause = _state;
    }

    function changeRateSale(uint _tokenAmount) public onlyOwner {
        require(isGlobalPause || (now > startSale && now < finishSale));
        rateSale = _tokenAmount;
    }

    function changeStartSale(uint256 _ts) public onlyOwner {
        startSale = _ts;
    }

    function changeMinTokenSale(uint256 _ts) public onlyOwner {
        minTokenSale = _ts;
    }

    function changeFinishSale(uint256 _ts) public onlyOwner {
        finishSale = _ts;
    }

    function setAuction(uint256 _startAuction, uint256 _finishAuction, uint256 _auctionPercent) public onlyOwner {
        require(_startAuction < _finishAuction);
        require(_auctionPercent > 0);
        require(_startAuction > startSale);
        require(_finishAuction <= finishSale);
        finishAuction = _finishAuction;
        startAuction = _startAuction;
        auctionPercent = _auctionPercent;
    }

    function finishMinting() public onlyOwner {
        require(!isFinished);
        isFinished=true;
        uint issuedTokenSupply = totalSupply;
        // 40% restricted + 60% issuedTokenSupply = 100%
        uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(100 - restrictedPercent);
        issuedTokenSupply = issuedTokenSupply.add(restrictedTokens);
        // 13% - 11% for any purpose and 2% bounty
        mint(restricted, issuedTokenSupply.mul(13).div(100), now);
        // 27% - freezed founds to team & adwisers
        mint(release6m, issuedTokenSupply.mul(85).div(1000), now + 180 * 1 days); // 8.5 %
        mint(release12m, issuedTokenSupply.mul(85).div(1000), now + 365 * 1 days); // 8.5 %
        mint(release18m, issuedTokenSupply.mul(10).div(100), now + 545 * 1 days); // 10 %
        mintingFinished=true;
    }

    function foreignBuyTest(uint256 _weiAmount, uint256 _rate) public pure returns (uint tokenAmount) {
        require(_weiAmount > 0);
        require(_rate > 0);
        return _rate.mul(_weiAmount).div(1 ether);
    }
    
    // BTC external payments
    function foreignBuy(address _holder, uint256 _weiAmount, uint256 _rate) public {
        require(msg.sender == registerbot || msg.sender == owner);
        require(_weiAmount > 0);
        require(_rate > 0);
        registered[_holder] = true;
        uint tokens = _rate.mul(_weiAmount).div(1 ether);
        mint(_holder, tokens, now + 99 * 1 years); // till KYC is completed
        totalWeiSale = totalWeiSale.add(_weiAmount);
    }

    function createTokens() public isRegistered anySaleIsOn isUnderHardCap payable {
        uint tokens = rateSale.mul(msg.value).div(1 ether);
        require(tokens >= minTokenSale); // min 10 tokens
        multisig.transfer(msg.value);
        uint percent = 0;
        uint bonusTokens = 0;
        uint finishBonus = startSale + (bonusPeriod * 1 days);
        if ( now < finishBonus ) {
            if ( now <= startSale + 1 days ) {
                percent = first24Percent;   // 1st day: 50% (for registered whitelist only)
           } else {        // 25% total:
               percent = (finishBonus - now).div(1 days); // last 15days -1% every day
               if ( percent >= 15 ) {  //  first 5days, -1% every 12h
                  percent = 27 - (now - startSale).div(1 hours).div(12);
               } else {
                  percent = percent.add(1);
               }				
          }
        } else {
            if ( now >= startAuction && now < finishAuction ) {
                percent = auctionPercent;
            }
        }
        if ( percent > 0 ) {
            bonusTokens = tokens.mul(percent).div(100);
            tokens = tokens.add(bonusTokens);
        }

        totalWeiSale = totalWeiSale.add(msg.value);
        mint(msg.sender, tokens, now + 99 * 1 years); // till KYC is completed

        if ( referral[msg.sender] != address(0) ) {
            uint refererTokens = tokens.mul(refererPercent).div(1000);
            mint(referral[msg.sender], refererTokens, now + 99 * 1 years);
        }
    }

    function() external isRegistered anySaleIsOn isUnderHardCap payable {
        createTokens();
    }
    
}