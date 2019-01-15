pragma solidity ^0.4.24;

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
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner()  {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = true;
    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
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
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
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
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
       * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
       * @param _spender The address which will spend the funds.
       * @param _value The amount of tokens to be spent.
       */
      function approve(address _spender, uint256 _value) public returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
      }

      /**
       * @dev Function to check the amount of tokens that an owner allowed to a spender.
       * @param _owner address The address which owns the funds.
       * @param _spender address The address which will spend the funds.
       * @return A uint256 specifing the amount of tokens still avaible for the spender.
       */
      function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
      }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(0X0, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract BlockableToken is Ownable{
    event Blocked(address blockedAddress);
    event UnBlocked(address unBlockedAddress);
    //keep mapping of blocked addresses
    mapping (address => bool) public blockedAddresses;
    modifier whenNotBlocked(){
      require(!blockedAddresses[msg.sender]);
      _;
    }

    function blockAddress(address toBeBlocked) onlyOwner public {
      blockedAddresses[toBeBlocked] = true;
      emit Blocked(toBeBlocked);
    }
    function unBlockAddress(address toBeUnblocked) onlyOwner public {
      blockedAddresses[toBeUnblocked] = false;
      emit UnBlocked(toBeUnblocked);
    }
}


contract StrikeToken is MintableToken, Pausable, BlockableToken{
    string public name = "Dimensions Strike Token";
    string public symbol = "DST";
    uint256 public decimals = 18;

    event Ev(string message, address whom, uint256 val);

    struct XRec {
        bool inList;
        address next;
        address prev;
        uint256 val;
    }

    struct QueueRecord {
        address whom;
        uint256 val;
    }

    address first = 0x0;
    address last = 0x0;

    mapping (address => XRec) public theList;

    QueueRecord[]  theQueue;

    // add a record to the END of the list
    function add(address whom, uint256 value) internal {
        theList[whom] = XRec(true,0x0,last,value);
        if (last != 0x0) {
            theList[last].next = whom;
        } else {
            first = whom;
        }
        last = whom;
        emit Ev("add",whom,value);
    }

    function remove(address whom) internal {
        if (first == whom) {
            first = theList[whom].next;
            theList[whom] = XRec(false,0x0,0x0,0);
            return;
        }
        address next = theList[whom].next;
        address prev = theList[whom].prev;
        if (prev != 0x0) {
            theList[prev].next = next;
        }
        if (next != 0x0) {
            theList[next].prev = prev;
        }
        theList[whom] =XRec(false,0x0,0x0,0);
        emit Ev("remove",whom,0);
    }

    function update(address whom, uint256 value) internal {
        if (value != 0) {
            if (!theList[whom].inList) {
                add(whom,value);
            } else {
                theList[whom].val = value;
                emit Ev("update",whom,value);
            }
            return;
        }
        if (theList[whom].inList) {
            remove(whom);
        }
    }

    /**
     * @dev Allows anyone to transfer the Strike tokens once trading has started
     * @param _to the recipient address of the tokens.
     * @param _value number of tokens to be transfered.
     */
    function transfer(address _to, uint _value) public whenNotPaused whenNotBlocked returns (bool) {
        bool result = super.transfer(_to, _value);
        update(msg.sender,balances[msg.sender]);
        update(_to,balances[_to]);
        return result;
    }

    /**
     * @dev Allows anyone to transfer the Strike tokens once trading has started
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused whenNotBlocked returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        update(_from,balances[_from]);
        update(_to,balances[_to]);
        return result;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */

    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        bool result = super.mint(_to,_amount);
        update(_to,balances[_to]);
        return result;
    }

    constructor()  public{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract StrikeTokenCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    StrikeToken public token = new StrikeToken();

    // start and end times
    uint256 public startTimestamp = 1575158400;
    uint256 public endTimestamp = 1577750400;
    uint256 etherToWei = 10**18;

    // address where funds are collected and tokens distributed
    address public hardwareWallet = 0xDe3A91E42E9F6955ce1a9eDb23Be4aBf8d2eb08B;
    address public restrictedWallet = 0xDe3A91E42E9F6955ce1a9eDb23Be4aBf8d2eb08B;
    address public additionalTokensFromCommonPoolWallet = 0xDe3A91E42E9F6955ce1a9eDb23Be4aBf8d2eb08B;

    mapping (address => uint256) public deposits;
    uint256 public numberOfPurchasers;

    // Percentage bonus tokens given in Token Sale, on a daily basis
    uint256[] public bonus = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    uint256 public rate = 4800; // 4800 DST is one Ether

    // amount of raised money in wei
    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;
    uint256 public advisorTokensGranted = 0;
    uint256 public commonPoolTokensGranted = 0;

    uint256 public minContribution = 100 * 1 finney;
    uint256 public hardCapEther = 30000;
    uint256 hardcap = hardCapEther * etherToWei;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event MainSaleClosed();

    uint256 public weiRaisedInPresale  = 0 ether;

    bool private frozen = false;

    function freeze() public onlyOwner{
      frozen = true;
    }
    function unfreeze() public onlyOwner{
      frozen = false;
    }

    modifier whenNotFrozen() {
        require(!frozen);
        _;
    }
    modifier whenFrozen() {
        require(frozen);
        _;
    }

    function setHardwareWallet(address _wallet) public onlyOwner {
        require(_wallet != 0x0);
        hardwareWallet = _wallet;
    }

    function setRestrictedWallet(address _restrictedWallet) public onlyOwner {
        require(_restrictedWallet != 0x0);
        restrictedWallet = _restrictedWallet;
    }

    function setAdditionalTokensFromCommonPoolWallet(address _wallet) public onlyOwner {
        require(_wallet != 0x0);
        additionalTokensFromCommonPoolWallet = _wallet;
    }

    function setHardCapEther(uint256 newEtherAmt) public onlyOwner{
        require(newEtherAmt > 0);
        hardCapEther = newEtherAmt;
        hardcap = hardCapEther * etherToWei;
    }

    constructor() public  {
        require(startTimestamp >= now);
        require(endTimestamp >= startTimestamp);
    }

    // check if valid purchase
    modifier validPurchase {
        require(now >= startTimestamp);
        require(now < endTimestamp);
        require(msg.value >= minContribution);
        require(frozen == false);
        _;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        if (now > endTimestamp)
            return true;
        return false;
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable validPurchase {
        require(beneficiary != 0x0);

        uint256 weiAmount = msg.value;

        // Check if the hardcap has been exceeded
        uint256 weiRaisedSoFar = weiRaised.add(weiAmount);
        require(weiRaisedSoFar + weiRaisedInPresale <= hardcap);

        if (deposits[msg.sender] == 0) {
            numberOfPurchasers++;
        }
        deposits[msg.sender] = weiAmount.add(deposits[msg.sender]);

        uint256 daysInSale = (now - startTimestamp) / (1 days);
        uint256 thisBonus = 0;
        if(daysInSale < 29 ){
            thisBonus = bonus[daysInSale];
        }

        // Calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);
        uint256 extraBonus = tokens.mul(thisBonus);
        extraBonus = extraBonus.div(100);
        tokens = tokens.add(extraBonus);

        // Update the global token sale variables
        uint256 finalTokenCount;
        finalTokenCount = tokens.add(tokensSold);
        weiRaised = weiRaisedSoFar;
        tokensSold = finalTokenCount;

        token.mint(beneficiary, tokens);
        hardwareWallet.transfer(msg.value);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function grantTokensAdvisors(address beneficiary,uint256 dstTokenCount) public onlyOwner{
        dstTokenCount = dstTokenCount * etherToWei;
        advisorTokensGranted = advisorTokensGranted.add(dstTokenCount);
        token.mint(beneficiary,dstTokenCount);
    }

    function grantTokensCommonPool(address beneficiary,uint256 dstTokenCount) public onlyOwner{
        dstTokenCount = dstTokenCount * etherToWei;
        commonPoolTokensGranted = commonPoolTokensGranted.add(dstTokenCount);
        token.mint(beneficiary,dstTokenCount);
    }

    // finish mining coins and transfer ownership of Change coin to owner
    function finishMinting() public onlyOwner returns(bool){
        require(hasEnded());

        uint issuedTokenSupply = token.totalSupply();
        uint publicTokens = issuedTokenSupply-advisorTokensGranted;
        if(publicTokens>60*advisorTokensGranted/40 ){
          uint restrictedTokens=(publicTokens)*40/60-advisorTokensGranted;
          token.mint(restrictedWallet, restrictedTokens);
          advisorTokensGranted=advisorTokensGranted+restrictedTokens;
        }
        else if(publicTokens<60*advisorTokensGranted/40){
          uint256 deltaCommonPool=advisorTokensGranted*60/40-publicTokens;
          token.mint(additionalTokensFromCommonPoolWallet,deltaCommonPool);
        }

        token.finishMinting();
        token.transferOwnership(owner);
        emit MainSaleClosed();
        return true;
    }

    // fallback function can be used to buy tokens
    function () payable public {
        buyTokens(msg.sender);
    }
    function setRate(uint256 amount) onlyOwner public {
        require(amount>=0);
        rate = amount;
    }
    function setBonus(uint256 [] amounts) onlyOwner public {
      require( amounts.length > 30 );
        bonus = amounts;
    }
    function setWeiRaisedInPresale(uint256 amount) onlyOwner public {
        require(amount>=0);
        weiRaisedInPresale = amount;
    }
    function setEndTimeStamp(uint256 end) onlyOwner public {
        require(end>now);
        endTimestamp = end;
    }
    function setStartTimeStamp(uint256 start) onlyOwner public {
        startTimestamp = start;
    }
    function pauseTrading() onlyOwner public{
        token.pause();
    }
    function startTrading() onlyOwner public{
        token.unpause();
    }
    function smartBlockAddress(address toBeBlocked) onlyOwner public{
        token.blockAddress(toBeBlocked);
    }
    function smartUnBlockAddress(address toBeUnblocked) onlyOwner public{
        token.unBlockAddress(toBeUnblocked);
    }
    function changeTokenOwner(address newOwner) public onlyOwner {
        require(hasEnded());
        token.changeOwner(newOwner);
    }
    function bulkGrantTokenAdvisors(address [] beneficiaries,uint256 [] granttokencounts) public onlyOwner{
      require( beneficiaries.length == granttokencounts.length);
      for (uint256 i=0; i<beneficiaries.length; i++) {
        grantTokensAdvisors(beneficiaries[i],granttokencounts[i]);
      }
    }
    function bulkGrantTokenCommonPool(address [] beneficiaries,uint256 [] granttokencounts) public onlyOwner{
      require( beneficiaries.length == granttokencounts.length);
      for (uint256 i=0; i<beneficiaries.length; i++) {
        grantTokensCommonPool(beneficiaries[i],granttokencounts[i]);
      }
    }

}