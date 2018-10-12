pragma solidity 0.4.25;
/**
* @title ICO Contract
* @dev CARNOMIC is an ERC-20 Standar Compliant Token
*/

/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
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
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title admined
 * @notice This contract is administered
 */
contract admined {
    //mapping to user levels
    mapping(address => uint8) public level;
    //0 normal user
    //1 basic admin
    //2 master admin

    /**
    * @dev This contructor takes the msg.sender as the first master admin
    */
    constructor() internal {
        level[msg.sender] = 2; //Set initial admin to contract creator
        emit AdminshipUpdated(msg.sender,2); //Log the admin set
    }

    /**
    * @dev This modifier limits function execution to the admin
    */
    modifier onlyAdmin(uint8 _level) { //A modifier to define admin-only functions
        require(level[msg.sender] >= _level ); //It require the user level to be more or equal than _level
        _;
    }

    /**
    * @notice This function transfer the adminship of the contract to _newAdmin
    * @param _newAdmin The new admin of the contract
    */
    function adminshipLevel(address _newAdmin, uint8 _level) onlyAdmin(2) public { //Admin can be set
        require(_newAdmin != address(0)); //The new admin must not be zero address
        level[_newAdmin] = _level; //New level is set
        emit AdminshipUpdated(_newAdmin,_level); //Log the admin set
    }

    /**
    * @dev Log Events
    */
    event AdminshipUpdated(address _newAdmin, uint8 _level);

}

contract ICO is admined {

    using SafeMath for uint256;
    //This ico have these possible states
    enum State {
        PRESALE,
        WEEK1,
        WEEK2,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.PRESALE; //Set initial stage
    uint256 public PRESALEStart = 1542240000; //Human time (GMT): Thursday, 15 November 2018 0:00:00
    uint256 public ICOStart = 1543622400; //Human time (GMT): Saturday, 1 December 2018 0:00:00
    uint256 public SaleDeadline = ICOStart.add(2 weeks);
    uint256 public completedAt; //Set when ico finish
    //Token-eth related
    uint256 public totalRaised; //eth collected in wei
    uint256 public totalDistributed; //Whole sale tokens distributed
    ERC20Basic public tokenReward; //Token contract address
    uint256 public softCap = 4000 ether;
    uint256 public hardCap = 30000 ether;

    //Contract details
    address public creator; //Creator address
    string public version = &#39;0.1&#39;; //Contract version

    //events for log
    event LogFundrisingInitialized(address indexed _creator);
    event LogFundingReceived(address indexed _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address indexed _beneficiaryAddress);
    event LogContributorsPayout(address indexed _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);

    //Modifier to prevent execution if ico has ended or is holded
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    /**
    * @notice ICO constructor
    * @param _addressOfTokenUsedAsReward is the token to distribute
    */
    constructor(ERC20Basic _addressOfTokenUsedAsReward) public {

        creator = msg.sender; //Creator is set from deployer address
        tokenReward = _addressOfTokenUsedAsReward; //Token address is set during deployment

        emit LogFundrisingInitialized(creator); //Log contract initialization

    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {
        require(now > PRESALEStart); //This time must be equal or greater than the start time

        uint256 tokenBought;

        totalRaised = totalRaised.add(msg.value); //ether received updated

        if(state == State.PRESALE){

          tokenBought = msg.value.mul(3000); //1 ETH = 3000CNM

          //Bonus Calculation
          tokenBought = tokenBought.mul(125);
          tokenBought = tokenBought.div(100); //+25%

        } else if(state == State.WEEK1){

          tokenBought = msg.value.mul(2760); //1 ETH = 2760CNM

          //Bonus Calculation
          tokenBought = tokenBought.mul(115);
          tokenBought = tokenBought.div(100); //+15%

        } else {

          tokenBought = msg.value.mul(2520); //1 ETH = 2520CNM

          //Bonus Calculation
          tokenBought = tokenBought.mul(105);
          tokenBought = tokenBought.div(100); //+5%

        }

        totalDistributed = totalDistributed.add(tokenBought); //Whole tokens sold updated

        tokenReward.transfer(msg.sender,tokenBought);

        emit LogFundingReceived(msg.sender, msg.value, totalRaised); //Log the purchase

        checkIfFundingCompleteOrExpired(); //Execute state checks
    }

    /**
    * @notice Process to check contract current status
    */
    function checkIfFundingCompleteOrExpired() public {

        if ( (now > SaleDeadline || totalRaised == hardCap) && state != State.Successful){ //If hardacap or deadline is reached and not yet successful

            state = State.Successful; //ICO becomes Successful
            completedAt = now; //ICO is complete

            emit LogFundingSuccessful(totalRaised); //we log the finish
            successful(); //and execute closure

        } else if(state == State.PRESALE && now >= ICOStart ) {

            state = State.WEEK1; //We get on next stage

        } else if(state == State.WEEK1 && now >= ICOStart.add(1 weeks) ) {

            state = State.WEEK2; //We get on next stage

        }

    }

    /**
    * @notice successful closure handler
    */
    function successful() public {
        require(state == State.Successful); //When successful
        uint256 temp = tokenReward.balanceOf(address(this)); //Remanent tokens handle
        tokenReward.transfer(creator,temp); //Try to transfer

        emit LogContributorsPayout(creator,temp); //Log transaction

        creator.transfer(address(this).balance); //After successful eth is send to creator

        emit LogBeneficiaryPaid(creator); //Log transaction

    }

    /**
    * @notice Function to claim any token stuck on contract
    * @param _address Address of target token
    */
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(state == State.Successful); //Only when sale finish

        uint256 remainder = _address.balanceOf(address(this)); //Check remainder tokens
        _address.transfer(msg.sender,remainder); //Transfer tokens to admin

    }

    /*
    * @dev Direct payments handler
    */
    function () public payable {

        contribute(); //Forward to contribute function

    }
}