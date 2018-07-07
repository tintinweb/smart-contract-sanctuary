pragma solidity 0.4.24;
/**
* @title TECH ICO Contract
* @dev TECH is an ERC-20 Standar Compliant Token
* Contact: WorkChainCenters@gmail.com  www.WorkChainCenters.io
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

contract TECHICO is admined {

    using SafeMath for uint256;
    //This ico have these possible states
    enum State {
        MainSale,
        Paused,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.MainSale; //Set initial stage
    uint256 constant public SaleStart = 1527879600; //Human time (GMT): Friday, 1 de June de 2018 19:00:00
    uint256 public SaleDeadline = 1535569200; //Human time (GMT): Wednesday, 29 August 2018 19:00:00
    uint256 public completedAt; //Set when ico finish
    //Token-eth related
    uint256 public totalRaised; //eth collected in wei
    uint256 public totalDistributed; //Whole sale tokens distributed
    ERC20Basic public tokenReward; //Token contract address
    uint256 public hardCap = 31200000 * (10 ** 18); // 31.200.000 tokens
    mapping(address => uint256) public pending; //tokens pending to being transfered
    //Contract details
    address public creator; //Creator address
    string public version = &#39;2&#39;; //Contract version
    //Bonus Related - How much tokens per bonus
    uint256 bonus1Remain = 1440000*10**18; //+20%
    uint256 bonus2Remain = 2380000*10**18; //+15%
    uint256 bonus3Remain = 3420000*10**18; //+10%
    uint256 bonus4Remain = 5225000*10**18; //+5%

    uint256 remainingActualState;
    State laststate;

    //User rights handlers
    mapping (address => bool) public whiteList; //List of allowed to send eth

    //Price related
    uint256 rate = 3000; //3000 tokens per ether unit

    //events for log
    event LogFundrisingInitialized(address _creator);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);
    event LogSalePaused(bool _paused);

    //Modifier to prevent execution if ico has ended or is holded
    modifier notFinished() {
        require(state != State.Successful && state != State.Paused);
        _;
    }

    /**
    * @notice ICO constructor
    * @param _addressOfTokenUsedAsReward is the token to distribute
    */
    constructor(ERC20Basic _addressOfTokenUsedAsReward ) public {

        creator = msg.sender; //Creator is set from deployer address
        tokenReward = _addressOfTokenUsedAsReward; //Token address is set during deployment
        emit LogFundrisingInitialized(creator); //Log contract initialization

        //PreSale tokens already sold = 4.720.047 tokens
        pending[0x8eBBcb4c4177941428E9E9E68C4914fb5A89650E] = 4720047000000000000002000;
        //To no exceed total tokens to sell, update numbers - bonuses not affected
        totalDistributed = 4720047000000000000002000;

    }

    /**
    * @notice Check remaining and cost function
    * @dev The cost function doesn&#39;t include the bonuses calculation
    */
    function remainingTokensAndCost() public view returns (uint256[2]){
        uint256 remaining = hardCap.sub(totalDistributed);
        uint256 cost = remaining.sub((bonus1Remain.mul(2)).div(10));
        cost = cost.sub((bonus2Remain.mul(15)).div(100));
        cost = cost.sub(bonus3Remain.div(10));
        cost = cost.sub((bonus4Remain.mul(5)).div(100));
        cost = cost.div(3000);
        return [remaining,cost];
    }

    /**
    * @notice Whitelist function
    * @param _user User address to be modified on list
    * @param _flag Whitelist status to set
    */
    function whitelistAddress(address _user, bool _flag) public onlyAdmin(1) {
        whiteList[_user] = _flag; //Assign status to user on whitelist
    }


    /**
    * @notice Pause function
    * @param _flag Pause status to set
    */
    function pauseSale(bool _flag) onlyAdmin(2) public {
        require(state != State.Successful);

        if(_flag == true){
            require(state != State.Paused);
            laststate = state;
            remainingActualState = SaleDeadline.sub(now);
            state = State.Paused;
            emit LogSalePaused(true);
        } else {
            require(state == State.Paused);
            state = laststate;
            SaleDeadline = now.add(remainingActualState);
            emit LogSalePaused(false);
        }
    }

    /**
    * @notice contribution handler
    */
    function contribute(address _target) public notFinished payable {
        require(now > SaleStart); //This time must be equal or greater than the start time

        //To handle admin guided contributions
        address user;
        //Let&#39;s if user is an admin and is givin a valid target
        if(_target != address(0) && level[msg.sender] >= 1){
          user = _target;
        } else {
          user = msg.sender; //If not the user is the sender
        }

        require(whiteList[user] == true); //User must be whitelisted

        totalRaised = totalRaised.add(msg.value); //ether received updated

        uint256 tokenBought = msg.value.mul(rate); //base tokens amount calculation

        //Bonus calc helpers
        uint256 bonus = 0; //How much bonus for this sale
        uint256 buyHelper = tokenBought; //Base tokens bought

        //Bonus Stage 1
        if(bonus1Remain > 0){ //If there still are some tokens with bonus

          //Lets check if tokens bought are less or more than remaining available
          //tokens whit bonus
          if(buyHelper <= bonus1Remain){ //If purchase is less
              bonus1Remain = bonus1Remain.sub(buyHelper); //Sub from remaining
              //Calculate the bonus for the total bought amount
              bonus = bonus.add((buyHelper.mul(2)).div(10));//+20%
              buyHelper = 0; //Clear buy helper
          }else{ //If purchase is more
              buyHelper = buyHelper.sub(bonus1Remain); //Sub from purchase helper the remaining
              //Calculate bonus for the remaining bonus tokens
              bonus = bonus.add((bonus1Remain.mul(2)).div(10));//+20%
              bonus1Remain = 0; //Clear bonus remaining tokens
          }

        }

        //Lets check if tokens bought are less or more than remaining available
        //tokens whit bonus
        if(bonus2Remain > 0 && buyHelper > 0){

          if(buyHelper <= bonus2Remain){ //If purchase is less
              bonus2Remain = bonus2Remain.sub(buyHelper);//Sub from remaining
              //Calculate the bonus for the total bought amount
              bonus = bonus.add((buyHelper.mul(15)).div(100));//+15%
              buyHelper = 0; //Clear buy helper
          }else{ //If purchase is more
              buyHelper = buyHelper.sub(bonus2Remain);//Sub from purchase helper the remaining
              //Calculate bonus for the remaining bonus tokens
              bonus = bonus.add((bonus2Remain.mul(15)).div(100));//+15%
              bonus2Remain = 0; //Clear bonus remaining tokens
          }

        }

        //Lets check if tokens bought are less or more than remaining available
        //tokens whit bonus
        if(bonus3Remain > 0 && buyHelper > 0){

          if(buyHelper <= bonus3Remain){ //If purchase is less
              bonus3Remain = bonus3Remain.sub(buyHelper);//Sub from remaining
              //Calculate the bonus for the total bought amount
              bonus = bonus.add(buyHelper.div(10));//+10%
              buyHelper = 0; //Clear buy helper
          }else{ //If purchase is more
              buyHelper = buyHelper.sub(bonus3Remain);//Sub from purchase helper the remaining
              //Calculate bonus for the remaining bonus tokens
              bonus = bonus.add(bonus3Remain.div(10));//+10%
              bonus3Remain = 0; //Clear bonus remaining tokens
          }

        }

        //Lets check if tokens bought are less or more than remaining available
        //tokens whit bonus
        if(bonus4Remain > 0 && buyHelper > 0){

          if(buyHelper <= bonus4Remain){ //If purchase is less
              bonus4Remain = bonus4Remain.sub(buyHelper);//Sub from remaining
              //Calculate the bonus for the total bought amount
              bonus = bonus.add((buyHelper.mul(5)).div(100));//+5%
              buyHelper = 0; //Clear buy helper
          }else{ //If purchase is more
              buyHelper = buyHelper.sub(bonus4Remain);//Sub from purchase helper the remaining
              //Calculate bonus for the remaining bonus tokens
              bonus = bonus.add((bonus4Remain.mul(5)).div(100));//+5%
              bonus4Remain = 0; //Clear bonus remaining tokens
          }

        }

        tokenBought = tokenBought.add(bonus); //Sum Up Bonus(es) to base purchase

        require(totalDistributed.add(tokenBought) <= hardCap); //The total amount after sum up must not be more than the hardCap

        pending[user] = pending[user].add(tokenBought); //Pending balance to distribute is updated
        totalDistributed = totalDistributed.add(tokenBought); //Whole tokens sold updated

        emit LogFundingReceived(user, msg.value, totalRaised); //Log the purchase

        checkIfFundingCompleteOrExpired(); //Execute state checks
    }

    /**
    * @notice Funtion to let users claim their tokens at the end of ico process
    */
    function claimTokensByUser() public{
        require(state == State.Successful); //Once ico is successful
        uint256 temp = pending[msg.sender]; //Get the user pending balance
        pending[msg.sender] = 0; //Clear it
        require(tokenReward.transfer(msg.sender,temp)); //Try to transfer
        emit LogContributorsPayout(msg.sender,temp); //Log the claim
    }

    /**
    * @notice Funtion to let admins claim users tokens on behalf of them at the end of ico process
    * @param _user Target user of token claim
    */
    function claimTokensByAdmin(address _user) onlyAdmin(1) public{
        require(state == State.Successful); //Once ico is successful
        uint256 temp = pending[_user]; //Get the user pending balance
        pending[_user] = 0; //Clear it
        require(tokenReward.transfer(_user,temp)); //Try to transfer
        emit LogContributorsPayout(_user,temp); //Log the claim
    }

    /**
    * @notice Process to check contract current status
    */
    function checkIfFundingCompleteOrExpired() public {
         //If hardacap or deadline is reached and not yet successful
        if ( (totalDistributed == hardCap || now > SaleDeadline)
            && state != State.Successful 
            && state != State.Paused) {
            //remanent tokens are assigned to creator for later handle
            pending[creator] = tokenReward.balanceOf(address(this)).sub(totalDistributed);

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
        uint256 temp = pending[creator]; //Remanent tokens handle
        pending[creator] = 0; //Clear user balance
        require(tokenReward.transfer(creator,temp)); //Try to transfer

        emit LogContributorsPayout(creator,temp); //Log transaction

        creator.transfer(address(this).balance); //After successful, eth is send to creator

        emit LogBeneficiaryPaid(creator); //Log transaction

    }

    /**
    * @notice Function to claim any token stuck on contract
    * @param _address Address of target token
    */
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(state == State.Successful); //Only when sale finish
        require(_address != address(tokenReward)); //Target token must be different from token on sale

        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(msg.sender,remainder); //Transfer tokens to admin

    }

    /*
    * @dev Direct payments handler
    */
    function () public payable {

        contribute(address(0)); //Forward to contribute function

    }
}