pragma solidity 0.4.25;
/**
* @title PRIWGR ICO Contract
* @dev PRIWGR is an ERC-20 Standar Compliant Token
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
    function transfer(address to, uint256 value) public;
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

contract PRIWGRICO is admined {

    using SafeMath for uint256;
    //This ico have these possible states
    enum State {
        MAINSALE,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.MAINSALE; //Set initial stage
    uint256 public MAINSALEStart = now;
    uint256 public SaleDeadline = MAINSALEStart.add(120 days); //Human time (GMT):
    uint256 public completedAt; //Set when ico finish
    //Token-eth related
    uint256 public totalRaised; //eth collected in wei
    uint256 public totalDistributed; //Whole sale tokens distributed
    ERC20Basic public tokenReward; //Token contract address

    //Contract details
    address public creator; //Creator address
    address public WGRholder; //Holder address
    string public version = &#39;0.1&#39;; //Contract version

    //Price related
    uint256 public USDPriceInWei; // 0.01 cent (0.0001$) in wei

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
    constructor(ERC20Basic _addressOfTokenUsedAsReward, uint _initialUSDInWei) public {

        creator = msg.sender; //Creator is set from deployer address
        WGRholder = creator; //WGRholder is set to creator address
        tokenReward = _addressOfTokenUsedAsReward; //Token address is set during deployment
        USDPriceInWei = _initialUSDInWei;

        emit LogFundrisingInitialized(creator); //Log contract initialization

    }

    /**
    * @notice contribution handler
    */
    function contribute(address _target, uint256 _value) public notFinished payable {
        require(now > MAINSALEStart); //Current time must be equal or greater than the start time

        address user;
        uint remaining;
        uint256 tokenBought;
        uint256 temp;

        if(_target != address(0) && level[msg.sender] >= 1){
          user = _target;
          remaining = _value.mul(1e18);
        } else {
          user = msg.sender;
          remaining = msg.value.mul(1e18);
        }

        totalRaised = totalRaised.add(remaining.div(1e18)); //ether received updated

        while(remaining > 0){

          (temp,remaining) = tokenBuyCalc(remaining);
          tokenBought = tokenBought.add(temp);

        }

        temp = 0;

        totalDistributed = totalDistributed.add(tokenBought); //Whole tokens sold updated
        if ( address(this).balance >= 1e18){ //Of balace is 1 ETH or more
            WGRholder.transfer(address(this).balance); //After successful eth is send to WGRholder
            emit LogBeneficiaryPaid(WGRholder); //Log transaction
        }

        tokenReward.transfer(user,tokenBought);

        emit LogFundingReceived(user, msg.value, totalRaised); //Log the purchase

        checkIfFundingCompleteOrExpired(); //Execute state checks
    }


    /*
    * This function handle the token purchases values
    */
    function tokenBuyCalc(uint _value) internal view returns (uint sold,uint remaining) {

      uint256 tempPrice = USDPriceInWei; //0.001$ in wei

      //state == State.MAINSALE

      tempPrice = tempPrice.mul(1000); //0.1$
      sold = _value.div(tempPrice);

      return (sold,0);

    }

    /**
    * @notice Process to check contract current status
    */
    function checkIfFundingCompleteOrExpired() public {

        if ( now > SaleDeadline && state != State.Successful){ //If Deadline is reached and not yet successful

            state = State.Successful; //ICO becomes Successful
            completedAt = now; //ICO is complete

            emit LogFundingSuccessful(totalRaised); //we log the finish
            successful(); //and execute closure

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

        WGRholder.transfer(address(this).balance); //After successful eth is send to WGRholder

        emit LogBeneficiaryPaid(WGRholder); //Log transaction

    }

    /*
    * Funtion to update current price of ether
    * it expects the value in wei of 0.01 cent (0.0001$)
    */
    function setPrice(uint _value) public onlyAdmin(2) {

      USDPriceInWei = _value;

    }
    function setHolder(address _holder) public onlyAdmin(2) {

      WGRholder = _holder;

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

        contribute(address(0),0); //Forward to contribute function

    }
}