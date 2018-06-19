pragma solidity 0.4.23;
/**
* @title IADOWR TGE CONTRACT
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
* @title DateTime contract
* @dev This contract will return the unix value of any date
*/
contract DateTime {

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public constant returns (uint timestamp);

}


/**
 * @title manager
 * @notice This contract have some manager-only functions
 */
contract manager {
    address public admin; //Admin address is public
    
    /**
    * @dev This contructor takes the msg.sender as the first administer
    */
    constructor() internal {
        admin = msg.sender; //Set initial admin to contract creator
        emit Manager(admin);
    }

    /**
    * @dev This modifier limits function execution to the admin
    */
    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    /**
    * @notice This function transfer the adminship of the contract to _newAdmin
    * @param _newAdmin The new admin of the contract
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

    /**
    * @dev Log Events
    */
    event TransferAdminship(address newAdminister);
    event Manager(address administer);

}

contract IADTGE is manager {

    using SafeMath for uint256;

    DateTime dateTimeContract = DateTime(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce);//Main
    
    //This TGE contract have 2 states
    enum State {
        Ongoing,
        Successful
    }
    //public variables
    token public constant tokenReward = token(0xC1E2097d788d33701BA3Cc2773BF67155ec93FC4);
    State public state = State.Ongoing; //Set initial stage
    uint256 public startTime = dateTimeContract.toTimestamp(2018,4,30,7,0); //From Apr 30 00:00 (PST)
    uint256 public deadline = dateTimeContract.toTimestamp(2018,5,31,6,59); //Until May 30 23:59 (PST)
    uint256 public totalRaised; //eth in wei funded
    uint256 public totalDistributed; //tokens distributed
    uint256 public completedAt;
    address public creator;
    uint256[2] public rates = [6250,5556];//Base rate is 5000 IAD/ETH - 1st 15 days 20% discount/2nd 15 days 10% discount
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
    * @notice TGE constructor
    */
    constructor () public {
        
        creator = msg.sender;
    
        emit LogFunderInitialized(creator);
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {
        require(now >= startTime);
        uint256 tokenBought;

        totalRaised = totalRaised.add(msg.value);

        if (now < startTime.add(15 days)){

            tokenBought = msg.value.mul(rates[0]);
        
        } else {

            tokenBought = msg.value.mul(rates[1]);
        
        }

        totalDistributed = totalDistributed.add(tokenBought);
        
        tokenReward.transfer(msg.sender, tokenBought);

        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

    /**
    * @notice check status
    */
    function checkIfFundingCompleteOrExpired() public {

        if(now > deadline){

            state = State.Successful; //TGE becomes Successful
            completedAt = now; //TGE end time

            emit LogFundingSuccessful(totalRaised); //we log the finish
            finished(); //and execute closure

        }
    }

    /**
    * @notice closure handler
    */
    function finished() public { //When finished eth and tremaining tokens are transfered to creator

        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        require(creator.send(address(this).balance));
        tokenReward.transfer(creator,remanent);

        emit LogBeneficiaryPaid(creator);
        emit LogContributorsPayout(creator, remanent);

    }

    /**
    * @notice Function to claim any token stuck on contract at any time
    */
    function claimTokens(token _address) onlyAdmin public{
        require(state == State.Successful); //Only when sale finish

        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(admin,remainder); //Transfer tokens to admin
        
    }

    /*
    * @dev direct payments handler
    */

    function () public payable {
        
        contribute();

    }
}