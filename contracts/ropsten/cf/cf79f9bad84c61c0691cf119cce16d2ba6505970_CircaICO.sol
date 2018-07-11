pragma solidity 0.4.24;
/**
* @title Circa ICO Contract
* @dev Circa is an ERC-20 Standar Compliant Token
* @author Fares A. Akel C. f.antonio.akel@gmail.com
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
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function burnToken(uint256 _burnedAmount) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title admined
 * @notice This contract is administered
 */
contract admined {
    mapping(address => uint8) level;
    //0 normal user
    //1 basic admin
    //2 master admin

    /**
    * @dev This contructor set the first master admin
    */
    constructor() internal {
        level[0xEFfea09df22E0B25655BD3f23D9B531ba47d2A8B] = 2; //Set initial admin
        emit AdminshipUpdated(0xEFfea09df22E0B25655BD3f23D9B531ba47d2A8B,2);
    }

    /**
    * @dev This modifier limits function execution to the admin by level
    */
    modifier onlyAdmin(uint8 _level) { //A modifier to define admin-only functions
        require(level[msg.sender] >= _level );
        _;
    }

    /**
    * @notice This function set the adminship level on the contract to _newAdmin
    * @param _newAdmin The new admin of the contract
    * @param _level level to set
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

contract CircaICO is admined {

    using SafeMath for uint256;
    //This ico have these possible states
    enum State {
        PreSale, //PreSale - best value
        MainSale,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.PreSale; //Set initial stage
    uint256 constant public PreSaleStart = 1532908800; //Human time (GMT): Monday, 30 July 2018 0:00:00
    uint256 constant public PreSaleDeadline = 1534118399; //Human time (GMT): Sunday, 12 August 2018 23:59:59
    uint256 constant public MainSaleStart = 1535155200; //Human time (GMT): Saturday, 25 August 2018 0:00:00
    uint256 constant public MainSaleDeadline = 1536105599; //Human time (GMT): Tuesday, 4 September 2018 23:59:59
    uint256 public completedAt; //Set when ico finish

    //Token-eth related
    uint256 public totalRaised; //eth collected in wei [INFO]
    uint256 public PreSaleDistributed; //presale tokens distributed [INFO]
    uint256 public MainSaleDistributed; //MainSale tokens distributed [INFO]
    uint256 public PreSaleLimit = 260000000 * (10 ** 18); //260M tokens
    uint256 public mainSale1Limit = 190000000 * (10 ** 18); // 190M tokens
    uint256 public totalDistributed; //Whole sale tokens distributed [INFO]
    ERC20Basic public tokenReward; //Token contract address
    uint256 public hardCap = 640000000 * (10 ** 18); // 640M tokens (max tokens to be distributed by contract) [INFO]
    //Contract details
    address public creator;
    string public version = &#39;1&#39;;

    bool ended = false;

    //Tokens per eth rates
    uint256[3] rates = [45000,35000,28000];

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
    * @param _addressOfTokenUsedAsReward is the token to distribute
    */
    constructor(ERC20Basic _addressOfTokenUsedAsReward) public {

        creator = 0xEFfea09df22E0B25655BD3f23D9B531ba47d2A8B; //Creator is set
        tokenReward = _addressOfTokenUsedAsReward; //Token address is set during deployment

        emit LogFundrisingInitialized(creator);
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {
        require(msg.value <= 500 ether); //No whales

        uint256 tokenBought = 0; //tokens bought variable

        totalRaised = totalRaised.add(msg.value); //ether received updated

        //Rate of exchange depends on stage
        if (state == State.PreSale){

            require(now >= PreSaleStart);

            tokenBought = msg.value.mul(rates[0]);

            if(PreSaleDistributed <= 30000000 * (10**18)){
              tokenBought = tokenBought.mul(12);
              tokenBought = tokenBought.div(10); //+20%
            } else if (PreSaleDistributed <= 50000000 * (10**18)){
              tokenBought = tokenBought.mul(11);
              tokenBought = tokenBought.div(10); //+10%
            }

            PreSaleDistributed = PreSaleDistributed.add(tokenBought); //Tokens sold on presale updated

        } else if (state == State.MainSale){

            require(now >= MainSaleStart);

            if(MainSaleDistributed < mainSale1Limit){
              tokenBought = msg.value.mul(rates[1]);

              if(MainSaleDistributed <= 80000000 * (10**18)){
                tokenBought = tokenBought.mul(12);
                tokenBought = tokenBought.div(10); //+20%
              }

            } else tokenBought = msg.value.mul(rates[2]);

            MainSaleDistributed = MainSaleDistributed.add(tokenBought);

        }

        totalDistributed = totalDistributed.add(tokenBought); //whole tokens sold updated

        require(totalDistributed <= hardCap);
        require(tokenReward.transfer(msg.sender, tokenBought));

        emit LogContributorsPayout(msg.sender, tokenBought);
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);

        checkIfFundingCompleteOrExpired();
    }

    /**
    * @notice check status
    */
    function checkIfFundingCompleteOrExpired() public {

        //If hardCap is reached ICO ends
        if (totalDistributed == hardCap && state != State.Successful){

            state = State.Successful; //ICO becomes Successful
            completedAt = now; //ICO is complete

            emit LogFundingSuccessful(totalRaised); //we log the finish
            successful(); //and execute closure

        } else if(state == State.PreSale && PreSaleDistributed >= PreSaleLimit){

            state = State.MainSale; //Once presale ends the ICO holds

        }
    }

    function forceNextStage() onlyAdmin(2) public {

        if(state == State.PreSale && now > PreSaleDeadline){
          state = State.MainSale;
        } else if (state == State.MainSale && now > MainSaleDeadline ){
          state = State.Successful; //ICO becomes Successful
          completedAt = now; //ICO is complete

          emit LogFundingSuccessful(totalRaised); //we log the finish
          successful(); //and execute closure
        } else revert();

    }

    /**
    * @notice successful closure handler
    */
    function successful() public {
        //When successful
        require(state == State.Successful);
        if(ended == false){
            ended = true;
            //If there is any token left after ico
            uint256 remanent = hardCap.sub(totalDistributed); //Total tokens to distribute - total distributed
            //It&#39;s burned
            require(tokenReward.burnToken(remanent));
        }
        //After successful all remaining eth is send to creator
        creator.transfer(address(this).balance);
        emit LogBeneficiaryPaid(creator);

    }

    /**
    * @notice Manual eth retrieve
    */
    function ethRetrieve() onlyAdmin(2) public {
      creator.transfer(address(this).balance);
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