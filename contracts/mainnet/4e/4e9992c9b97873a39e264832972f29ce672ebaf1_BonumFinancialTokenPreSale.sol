pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


contract InvestorsList is Ownable {
    using SafeMath for uint;

    /* Investor */

    enum WhiteListStatus  {Usual, WhiteList, PreWhiteList}

    struct Investor {
        bytes32 id;
        uint tokensCount;
        address walletForTokens;
        WhiteListStatus whiteListStatus;
        bool isVerified;
    }

    /*Investor&#39;s end*/

    mapping (address => bool) manipulators;
    mapping (address => bytes32) public nativeInvestorsIds;
    mapping (bytes32 => Investor) public investorsList;

    /*Manipulators*/

    modifier allowedToManipulate(){
        require(manipulators[msg.sender] || msg.sender == owner);
        _;
    }

    function changeManipulatorAddress(address saleAddress, bool isAllowedToManipulate) external onlyOwner{
        require(saleAddress != 0x0);
        manipulators[saleAddress] = isAllowedToManipulate;
    }

    /*Manipulators&#39; end*/

    function setInvestorId(address investorAddress, bytes32 id) external onlyOwner{
        require(investorAddress != 0x0 && id != 0);
        nativeInvestorsIds[investorAddress] = id;
    }

    function addInvestor(
        bytes32 id,
        WhiteListStatus status,
        bool isVerified
    ) external onlyOwner {
        require(id != 0);
        require(investorsList[id].id == 0);

        investorsList[id].id = id;
        investorsList[id].tokensCount = 0;
        investorsList[id].whiteListStatus = status;
        investorsList[id].isVerified = isVerified;
    }

    function removeInvestor(bytes32 id) external onlyOwner {
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].id = 0;
    }

    function isAllowedToBuyByAddress(address investor) external view returns(bool){
        require(investor != 0x0);
        bytes32 id = nativeInvestorsIds[investor];
        require(id != 0 && investorsList[id].id != 0);
        return investorsList[id].isVerified;
    }

    function isAllowedToBuyByAddressWithoutVerification(address investor) external view returns(bool){
        require(investor != 0x0);
        bytes32 id = nativeInvestorsIds[investor];
        require(id != 0 && investorsList[id].id != 0);
        return true;
    }

    function isAllowedToBuy(bytes32 id) external view returns(bool){
        require(id != 0 && investorsList[id].id != 0);
        return investorsList[id].isVerified;
    }

    function isPreWhiteListed(bytes32 id) external constant returns(bool){
        require(id != 0 && investorsList[id].id != 0);
        return investorsList[id].whiteListStatus == WhiteListStatus.PreWhiteList;
    }

    function isWhiteListed(bytes32 id) external view returns(bool){
        require(id != 0 && investorsList[id].id != 0);
        return investorsList[id].whiteListStatus == WhiteListStatus.WhiteList;
    }

    function setVerificationStatus(bytes32 id, bool status) external onlyOwner{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].isVerified = status;
    }

    function setWhiteListStatus(bytes32 id, WhiteListStatus status) external onlyOwner{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].whiteListStatus = status;
    }

    function addTokens(bytes32 id, uint tokens) external allowedToManipulate{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].tokensCount = investorsList[id].tokensCount.add(tokens);
    }

    function subTokens(bytes32 id, uint tokens) external allowedToManipulate{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].tokensCount = investorsList[id].tokensCount.sub(tokens);
    }

    function setWalletForTokens(bytes32 id, address wallet) external onlyOwner{
        require(id != 0 && investorsList[id].id != 0);
        investorsList[id].walletForTokens = wallet;
    }
}

contract BonumFinancialTokenPreSale is Pausable{
    using SafeMath for uint;

    string public constant name = "Bonum Financial Token PreSale";

    uint public startDate;
    uint public endDate;
    uint public whiteListPreSaleDuration = 1 days;

    function setWhiteListDuration(uint duration) external onlyOwner{
        require(duration > 0);
        whiteListPreSaleDuration = duration * 1 days;
    }

    uint public fiatValueMultiplier = 10**6;
    uint public tokenDecimals = 10**18;

    InvestorsList public investors;

    address beneficiary;

    uint public ethUsdRate;
    uint public collected = 0;
    uint public tokensSold = 0;
    uint public tokensSoldWithBonus = 0;

    uint[] firstColumn;
    uint[] secondColumn;

    event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);

    function BonumFinancialTokenPreSale(
        uint _startDate,
        uint _endDate,
        address _investors,
        address _beneficiary,
        uint _baseEthUsdRate
    ) public {
        startDate = _startDate;
        endDate = _endDate;

        investors = InvestorsList(_investors);
        beneficiary = _beneficiary;

        ethUsdRate = _baseEthUsdRate;

        initBonusSystem();
    }


    function initBonusSystem() private{
        firstColumn.push(1750000);
        firstColumn.push(10360000);
        firstColumn.push(18980000);
        firstColumn.push(25000000);

        secondColumn.push(1560000);
        secondColumn.push(9220000);
        secondColumn.push(16880000);
        secondColumn.push(22230000);
    }

    function setNewBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != 0x0);
        beneficiary = newBeneficiary;
    }

    function setEthUsdRate(uint rate) external onlyOwner {
        require(rate > 0);
        ethUsdRate = rate;
    }

    function setNewStartDate(uint newStartDate) external onlyOwner{
        require(newStartDate > 0);
        startDate = newStartDate;
    }

    function setNewEndDate(uint newEndDate) external onlyOwner{
        require(newEndDate > 0);
        endDate = newEndDate;
    }

    function setNewInvestorsList(address investorsList) external onlyOwner {
        require(investorsList != 0x0);
        investors = InvestorsList(investorsList);
    }

    modifier activePreSale(){
        require(now >= startDate && now < endDate);
        _;
    }

    modifier underCap(){
        require(tokensSold < uint(750000).mul(tokenDecimals));
        _;
    }

    modifier isAllowedToBuy(){
        require(investors.isAllowedToBuyByAddressWithoutVerification(msg.sender));
        _;
    }

    modifier minimumAmount(){
        require(msg.value.mul(ethUsdRate).div(fiatValueMultiplier.mul(1 ether)) >= 100);
        _;
    }


    function() payable public whenNotPaused activePreSale minimumAmount underCap isAllowedToBuy{

        bytes32 id = investors.nativeInvestorsIds(msg.sender);

        uint tokens = msg.value.mul(ethUsdRate).div(fiatValueMultiplier);

        tokensSold = tokensSold.add(tokens);
        tokens = tokens.add(calculateBonus(id, tokens));
        tokensSoldWithBonus =  tokensSoldWithBonus.add(tokens);

        NewContribution(msg.sender, tokens, msg.value);

        collected = collected.add(msg.value);
        investors.addTokens(id, tokens);

        beneficiary.transfer(msg.value);
    }

    //usd * 10^6
    function otherCoinsPurchase(bytes32 id, uint amountInUsd) external whenNotPaused underCap activePreSale onlyOwner {
        require(id.length > 0 && amountInUsd >= (uint(100).mul(fiatValueMultiplier)) && investors.isAllowedToBuy(id));

        uint tokens = amountInUsd.mul(tokenDecimals).div(fiatValueMultiplier);

        tokensSold = tokensSold.add(tokens);
        tokens = tokens.add(calculateBonus(id, tokens));
        tokensSoldWithBonus =  tokensSoldWithBonus.add(tokens);

        investors.addTokens(id, tokens);
    }


    function calculateBonus(bytes32 id, uint tokensCount) public constant returns (uint){
        if (now < (startDate.add(whiteListPreSaleDuration))) {
            require(tokensCount >= 3000 * tokenDecimals);

            if (investors.isPreWhiteListed(id)) {
                return tokensCount.mul(35).div(100);
            }
            return tokensCount.mul(25).div(100);
        }

        //+1 because needs whole days
        uint day = ((now.sub(startDate.add(whiteListPreSaleDuration))).div(1 days)).add(1);
        uint B1;
        uint B2;

        if (tokensCount < uint(1000).mul(tokenDecimals)) {
            B1 = (((tokensCount - 100 * tokenDecimals) * (firstColumn[1] - firstColumn[0])) /  ((1000-100) * tokenDecimals)) + firstColumn[0];
            B2 = (((tokensCount - 100 * tokenDecimals) * (secondColumn[1] - secondColumn[0])) /  ((1000-100) * tokenDecimals)) + secondColumn[0];
        }

        if (tokensCount >= uint(1000).mul(tokenDecimals) && tokensCount < uint(10000).mul(tokenDecimals)) {
            B1 = (((tokensCount - 1000 * tokenDecimals) * (firstColumn[2] - firstColumn[1])) / ((10000-1000) * tokenDecimals)) + firstColumn[1];
            B2 = (((tokensCount - 1000 * tokenDecimals) * (secondColumn[2] - secondColumn[1])) / ((10000-1000) * tokenDecimals)) + secondColumn[1];
        }

        if (tokensCount >= uint(10000).mul(tokenDecimals) && tokensCount < uint(50000).mul(tokenDecimals)) {
            B1 = (((tokensCount - 10000 * tokenDecimals) * (firstColumn[3] - firstColumn[2])) / ((50000-10000) * tokenDecimals)) + firstColumn[2];
            B2 = (((tokensCount - 10000 * tokenDecimals) * (secondColumn[3] - secondColumn[2])) / ((50000-10000) * tokenDecimals)) + secondColumn[2];
        }

        if (tokensCount >=  uint(50000).mul(tokenDecimals)) {
            B1 = firstColumn[3];
            B2 = secondColumn[3];
        }

        uint bonusPercent = B1.sub(((day - 1).mul(B1 - B2)).div(12));

        return calculateBonusTokensAmount(tokensCount, bonusPercent);
    }

    function calculateBonusTokensAmount(uint tokensCount, uint bonusPercent) private constant returns(uint){
        uint bonus = tokensCount.mul(bonusPercent);
        bonus = bonus.div(100);
        bonus = bonus.div(fiatValueMultiplier);
        return bonus;
    }
}