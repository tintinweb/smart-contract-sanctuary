pragma solidity 0.4.24;
/**
* @title IADOWR Special Event Contract
* @dev ERC-20 Token Standard Compliant Contract
*/

/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * Token contract interface for external use
 */
contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public;

}


/**
 * @title admined
 * @notice This contract have some admin-only functions
 */
contract admined {
    mapping (address => uint8) public admin; //Admin address is public

    /**
    * @dev This contructor takes the msg.sender as the first administer
    */
    constructor() internal {
        admin[msg.sender] = 2; //Set initial master admin to contract creator
        emit AssignAdminship(msg.sender, 2);
    }

    /**
    * @dev This modifier limits function execution to the admin
    */
    modifier onlyAdmin(uint8 _level) { //A modifier to define admin-only functions
        require(admin[msg.sender] >= _level);
        _;
    }

    /**
    * @notice This function transfer the adminship of the contract to _newAdmin
    * @param _newAdmin User address
    * @param _level User new level
    */
    function assingAdminship(address _newAdmin, uint8 _level) onlyAdmin(2) public { //Admin can be transfered
        admin[_newAdmin] = _level;
        emit AssignAdminship(_newAdmin , _level);
    }

    /**
    * @dev Log Events
    */
    event AssignAdminship(address newAdminister, uint8 level);

}

contract IADSpecialEvent is admined {

    using SafeMath for uint256;

    //This ico contract have 2 states
    enum State {
        Ongoing,
        Successful
    }
    //public variables
    token public constant tokenReward = token(0xC1E2097d788d33701BA3Cc2773BF67155ec93FC4);
    State public state = State.Ongoing; //Set initial stage
    uint256 public totalRaised; //eth in wei funded
    uint256 public totalDistributed; //tokens distributed
    uint256 public completedAt;
    address public creator;
    mapping (address => bool) whiteList;
    uint256 public rate = 6250;//Base rate is 5000 IAD/ETH - It&#39;s a 25% bonus
    string public version = &#39;1&#39;;

    //events for log
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    /**
    * @notice ICO constructor
    */
    constructor () public {

        creator = msg.sender;

        emit LogFunderInitialized(creator);
    }

    /**
    * @notice whiteList handler
    */
    function whitelistAddress(address _user, bool _flag) onlyAdmin(1) public {
        whiteList[_user] = _flag;
    }

    function checkWhitelist(address _user) onlyAdmin(1) public view returns (bool flag) {
        return whiteList[_user];
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {
        //must be whitlisted
        require(whiteList[msg.sender] == true);
        //lets get the total purchase
        uint256 tokenBought = msg.value.mul(rate);
        //Minimum 150K tokenss
        require(tokenBought >= 150000 * (10 ** 18));
        //Keep track of total wei raised
        totalRaised = totalRaised.add(msg.value);
        //Keep track of total tokens distributed
        totalDistributed = totalDistributed.add(tokenBought);
        //Transfer the tokens
        tokenReward.transfer(msg.sender, tokenBought);
        //Logs
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);
    }

    /**
    * @notice closure handler
    */
    function finish() onlyAdmin(2) public { //When finished eth and tremaining tokens are transfered to creator

        if(state != State.Successful){
          state = State.Successful;
          completedAt = now;
        }

        uint256 remanent = tokenReward.balanceOf(this);
        require(creator.send(address(this).balance));
        tokenReward.transfer(creator,remanent);

        emit LogBeneficiaryPaid(creator);
        emit LogContributorsPayout(creator, remanent);

    }

    function sendTokensManually(address _to, uint256 _amount) onlyAdmin(2) public {

        require(whiteList[_to] == true);
        //Keep track of total tokens distributed
        totalDistributed = totalDistributed.add(_amount);
        //Transfer the tokens
        tokenReward.transfer(_to, _amount);
        //Logs
        emit LogContributorsPayout(_to, _amount);

    }

    /**
    * @notice Function to claim eth on contract
    */
    function claimETH() onlyAdmin(2) public{

        require(creator.send(address(this).balance));

        emit LogBeneficiaryPaid(creator);

    }

    /**
    * @notice Function to claim any token stuck on contract at any time
    */
    function claimTokens(token _address) onlyAdmin(2) public{
        require(state == State.Successful); //Only when sale finish

        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(msg.sender,remainder); //Transfer tokens to admin

    }

    /*
    * @dev direct payments handler
    */

    function () public payable {

        contribute();

    }
}