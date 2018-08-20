pragma solidity 0.4.24;
/**
* @title ICO CONTRACT
* @dev ERC-20 Token Standard Compliant
*/

/**
 * @title SafeMath by OpenZepelin
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

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

    }

/**
 * @title admined
 * @notice This contract is administered
 */
contract admined {
    address public admin; //Admin address is public

    /**
    * @dev This contructor takes the msg.sender as the first administer
    */
    constructor() internal {
        admin = 0x6585b849371A40005F9dCda57668C832a5be1777; //Set initial admin to contract creator
        emit Admined(admin);
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
    event Admined(address administer);

}

contract ICO is admined {

    using SafeMath for uint256;
    //This ico have these states
    enum State {
        stage1,
        stage2,
        stage3,
        stage4,
        stage5,
        Successful
    }
    //public variables
    State public state = State.stage1; //Set initial stage
    uint256 public startTime = now;
    uint256 public stage1Deadline = startTime.add(20 days);
    uint256 public stage2Deadline = stage1Deadline.add(20 days);
    uint256 public stage3Deadline = stage2Deadline.add(20 days);
    uint256 public stage4Deadline = stage3Deadline.add(20 days);
    uint256 public stage5Deadline = stage4Deadline.add(20 days);
    uint256 public totalRaised; //eth in wei
    uint256 public totalDistributed; //tokens
    uint256 public stageDistributed;
    uint256 public completedAt;
    token public tokenReward;
    address constant public creator = 0x6585b849371A40005F9dCda57668C832a5be1777;
    string public version = &#39;1&#39;;
    uint256[5] rates = [2327,1551,1163,931,775];

    mapping (address => address) public refLed;

    //events for log
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogStageFinish(State _state, uint256 _distributed);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
    /**
    * @notice ICO constructor
    * @param _addressOfTokenUsedAsReward is the token totalDistributed
    */
    constructor (token _addressOfTokenUsedAsReward ) public {

        tokenReward = _addressOfTokenUsedAsReward;

        emit LogFunderInitialized(creator);
    }

    /**
    * @notice contribution handler
    */
    function contribute(address _ref) public notFinished payable {

        address referral = _ref;
        uint256 referralBase = 0;
        uint256 referralTokens = 0;
        uint256 tokenBought = 0;

        if(refLed[msg.sender] == 0){ //If no referral set yet
          refLed[msg.sender] = referral; //Set referral to passed one
        } else { //If not, then it was set previously
          referral = refLed[msg.sender]; //A referral must not be changed
        }

        totalRaised = totalRaised.add(msg.value);

        //Rate of exchange depends on stage
        if (state == State.stage1){

            tokenBought = msg.value.mul(rates[0]);

        } else if (state == State.stage2){

            tokenBought = msg.value.mul(rates[1]);

        } else if (state == State.stage3){

            tokenBought = msg.value.mul(rates[2]);

        } else if (state == State.stage4){

            tokenBought = msg.value.mul(rates[3]);

        } else if (state == State.stage5){

            tokenBought = msg.value.mul(rates[4]);

        }

        //If there is any referral, the base calc will be made with this value
        referralBase = tokenBought;

        //2% Bonus Calc
        if(msg.value >= 5 ether ){
          tokenBought = tokenBought.mul(102);
          tokenBought = tokenBought.div(100); //1.02 = +2%
        }

        totalDistributed = totalDistributed.add(tokenBought);
        stageDistributed = stageDistributed.add(tokenBought);

        tokenReward.transfer(msg.sender, tokenBought);

        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);


        if (referral != address(0) && referral != msg.sender){

            referralTokens = referralBase.div(20); // 100% / 20 = 5%
            totalDistributed = totalDistributed.add(referralTokens);
            stageDistributed = stageDistributed.add(referralTokens);

            tokenReward.transfer(referral, referralTokens);

            emit LogContributorsPayout(referral, referralTokens);
        }

        checkIfFundingCompleteOrExpired();
    }

    /**
    * @notice check status
    */
    function checkIfFundingCompleteOrExpired() public {

        if(now > stage5Deadline && state!=State.Successful ){ //if we reach ico deadline and its not Successful yet

            emit LogStageFinish(state,stageDistributed);

            state = State.Successful; //ico becomes Successful
            completedAt = now; //ICO is complete

            emit LogFundingSuccessful(totalRaised); //we log the finish
            finished(); //and execute closure

        } else if(state == State.stage1 && now > stage1Deadline){

            emit LogStageFinish(state,stageDistributed);

            state = State.stage2;
            stageDistributed = 0;

        } else if(state == State.stage2 && now > stage2Deadline){

            emit LogStageFinish(state,stageDistributed);

            state = State.stage3;
            stageDistributed = 0;

        } else if(state == State.stage3 && now > stage3Deadline){

            emit LogStageFinish(state,stageDistributed);

            state = State.stage4;
            stageDistributed = 0;

        } else if(state == State.stage4 && now > stage4Deadline){

            emit LogStageFinish(state,stageDistributed);

            state = State.stage5;
            stageDistributed = 0;

        }
    }

    /**
    * @notice closure handler
    */
    function finished() public { //When finished eth are transfered to creator

        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        creator.transfer(address(this).balance);
        tokenReward.transfer(creator,remanent);

        emit LogBeneficiaryPaid(creator);
        emit LogContributorsPayout(creator, remanent);

    }

    /**
    * @notice Function to claim any token stuck on contract
    */
    function claimTokens(token _address) onlyAdmin public{
        require(state == State.Successful); //Only when sale finish

        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(admin,remainder); //Transfer tokens to admin

    }

    /*
    * @dev direct payments doesn&#39;t handle referral system
    * so it call contribute with referral 0x0000000000000000000000000000000000000000
    */

    function () public payable {

        contribute(address(0));

    }
}