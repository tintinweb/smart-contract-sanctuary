pragma solidity 0.4.24;
/**
* @title ROC ICO Contract - TEST DEPLOYMENT
* @author Fares A. Akel C. <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5f39713e312b30313630713e343a331f38323e3633713c3032">[email&#160;protected]</a>
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
    function totalSupply() constant external returns (uint256 supply);
    function balanceOf(address _owner) constant external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

/**
 * @title admined
 * @notice This contract is administered
 */
contract admined {
    mapping(address => uint8) public level;
    //Levels are
    //0 normal user (default)
    //1 basic admin
    //2 master admin

    /**
    * @dev This contructor takes the msg.sender (deployer wallet) as the first master admin
    */
    constructor() internal {
        level[msg.sender] = 2; //Set initial admin to contract creator
        emit AdminshipUpdated(msg.sender,2);
    }

    /**
    * @dev This modifier limits function execution to the admin
    */
    modifier onlyAdmin(uint8 _level) { //A modifier to define admin-only functions
        require(level[msg.sender] >= _level );
        _;
    }

    /**
    * @notice This function set adminship on the contract to _newAdmin
    * @param _newAdmin The new admin of the contract
    * @param _level The level assigned
    */
    function adminshipLevel(address _newAdmin, uint8 _level) onlyAdmin(2) public { //Admin can be set
        require(_newAdmin != address(0));
        level[_newAdmin] = _level;
        emit AdminshipUpdated(_newAdmin,_level);
    }

    /**
    * @dev Log Events
    */
    event AdminshipUpdated(address _newAdmin, uint8 _level);

}

contract ROCICO is admined {

    using SafeMath for uint256;
    //This ico have these possible states
    enum State {
        Stage1,
        Stage2,
        Stage3,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.Stage1; //Set initial stage
    uint256 public startTime = now; //Human time (GMT): Saturday, 15 September 2018 0:00:00
    uint256 public Stage1Deadline = now.add(5 minutes); //Human time (GMT): Sunday, 30 September 2018 12:00:00
    uint256 public Stage2Deadline = now.add(10 minutes); //Human time (GMT): Monday, 15 October 2018 12:00:00
    uint256 public Stage3Deadline = now.add(15 minutes); //Human time (GMT): Tuesday, 30 October 2018 23:59:59
    uint256 public completedAt; //Set when ico finish

    //Token-eth related
    uint256 public totalRaised; //eth collected in wei
    uint256 public totalDistributed; //Whole sale tokens distributed
    ERC20Basic public tokenReward; //Token contract address

    //Contract details
    address public creator;
    address public beneficiary;
    string public version = &#39;1&#39;;

    //Tokens per eth rates
    uint256[3] rates = [1000000,800000,700000];

    //events for log
    event LogFundrisingInitialized(address _creator);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);

    //Modifier to prevent execution if ico has ended
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    /**
    * @notice ICO constructor
    */
    constructor(address _beneficiaryAddress) public {

        beneficiary = _beneficiaryAddress;
        creator = msg.sender; //Creator is set on deployment
        tokenReward = ERC20Basic(0x9bba0ced6a607891c92788c9b6c4953a8e7b19c2); //Token contract address

        emit LogFundrisingInitialized(beneficiary);
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {

        //Minimum contribution 0.001 eth
        require(msg.value >= 1 finney);

        uint256 tokenBought = 0; //tokens bought variable

        totalRaised = totalRaised.add(msg.value); //ether received counter updated

        emit LogFundingReceived(msg.sender, msg.value, totalRaised); //log

        if(state == State.Stage1){

            tokenBought = msg.value.mul(rates[0]); //Stage1 rate

            //Bonus 25%
            tokenBought = tokenBought.mul(125);
            tokenBought = tokenBought.div(100);

        } else if(state == State.Stage2){

            tokenBought = msg.value.mul(rates[1]); //Stage2 rate

            //Bonus 15%
            tokenBought = tokenBought.mul(115);
            tokenBought = tokenBought.div(100);

        } else {

            tokenBought = msg.value.mul(rates[2]); //Stage3 rate

            //Bonus 5%
            tokenBought = tokenBought.mul(105);
            tokenBought = tokenBought.div(100);

        }

        tokenBought = tokenBought.div(1e10); //Decimals correction

        totalDistributed = totalDistributed.add(tokenBought); //whole tokens sold counter updated

        require(tokenReward.transfer(msg.sender,tokenBought));

        emit LogContributorsPayout(msg.sender,tokenBought); //Log the claim

        checkIfFundingCompleteOrExpired(); //State check
    }

    /**
    * @notice function to check status
    */
    function checkIfFundingCompleteOrExpired() public {

        if( now >= Stage3Deadline && state != State.Successful ){//If deadline is reached

            state = State.Successful; //ICO becomes Successful
            completedAt = now; //ICO is complete

            emit LogFundingSuccessful(totalRaised); //we log the finish
            successful(); //and execute closure

        } else if (state == State.Stage1 && now >= Stage1Deadline){

            state = State.Stage2;

        } else if (state == State.Stage2 && now >= Stage2Deadline){

            state = State.Stage3;

        }
    }

    /**
    * @notice successful closure handler
    */
    function successful() public {
        //When successful
        require(state == State.Successful);

        //If there is any token left after ico
        uint256 remanent = tokenReward.balanceOf(this); //Total tokens remaining
        require(tokenReward.transfer(beneficiary,remanent));//Tokens are send back to creator

        //After successful ico all remaining eth is send to beneficiary
        beneficiary.transfer(address(this).balance);
        emit LogBeneficiaryPaid(creator);
    }

    /**
    * @notice Function to claim any token stuck on contract
    */
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{

        require(state == State.Successful);

        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(msg.sender,remainder); //Transfer tokens to admin

    }

    /*
    * @dev Direct payments handler
    */
    function () public payable {

        contribute();

    }
}