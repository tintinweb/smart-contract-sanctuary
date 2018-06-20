pragma solidity 0.4.24;
/**
* @title CNC ICO Contract
* @dev CNC is an ERC-20 Standar Compliant Token
*/

/**
 * @title SafeMath by OpenZeppelin (partially)
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
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
    * @dev This contructor takes the msg.sender as the first master admin
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
    * @notice This function transfer the adminship of the contract to _newAdmin
    * @param _newAdmin The new admin of the contract
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

contract CNCICO is admined {

    using SafeMath for uint256;
    //This ico have 4 possible states
    enum State {
        PreSale, //PreSale - best value
        MainSale,
        Failed,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.PreSale; //Set initial stage
    uint256 public PreSaleStart = now; //Once deployed
    uint256 constant public PreSaleDeadline = 1528502399; //Human time (GMT): Friday, 8 June 2018 23:59:59
    uint256 public MainSaleStart = 1528722000; //Human time (GMT): Monday, 11 June 2018 13:00:00
    uint256 public MainSaleDeadline = 1533081599; //Human time (GMT): Tuesday, 31 July 2018 23:59:59
    uint256 public completedAt; //Set when ico finish

    //Token-eth related
    uint256 public totalRaised; //eth collected in wei
    uint256 public PreSaleDistributed; //presale tokens distributed
    uint256 public PreSaleLimit = 75000000 * (10 ** 18);
    uint256 public totalDistributed; //Whole sale tokens distributed
    ERC20Basic public tokenReward; //Token contract address
    uint256 public softCap = 50000000 * (10 ** 18); //50M Tokens
    uint256 public hardCap = 600000000 * (10 ** 18); // 600M tokens
    bool public claimed;
    //User balances handlers
    mapping (address => uint256) public ethOnContract; //Balance of sent eth per user
    mapping (address => uint256) public tokensSent; //Tokens sent per user
    mapping (address => uint256) public balance; //Tokens pending to send per user
    //Contract details
    address public creator;
    string public version = &#39;1&#39;;

    //Tokens per eth rates
    uint256[2] rates = [50000,28572];

    //events for log
    event LogFundrisingInitialized(address _creator);
    event LogMainSaleDateSet(uint256 _time);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogRefund(address _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFundingFailed(uint _totalRaised);

    //Modifier to prevent execution if ico has ended
    modifier notFinished() {
        require(state != State.Successful && state != State.Failed);
        _;
    }

    /**
    * @notice ICO constructor
    * @param _addressOfTokenUsedAsReward is the token to distribute
    */
    constructor(ERC20Basic _addressOfTokenUsedAsReward ) public {

        creator = msg.sender; //Creator is set from deployer address
        tokenReward = _addressOfTokenUsedAsReward; //Token address is set during deployment

        emit LogFundrisingInitialized(creator);
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {

        uint256 tokenBought = 0; //tokens bought variable

        totalRaised = totalRaised.add(msg.value); //ether received updated
        ethOnContract[msg.sender] = ethOnContract[msg.sender].add(msg.value); //ether sent by user updated

        //Rate of exchange depends on stage
        if (state == State.PreSale){

            require(now >= PreSaleStart);

            tokenBought = msg.value.mul(rates[0]);
            PreSaleDistributed = PreSaleDistributed.add(tokenBought); //Tokens sold on presale updated
            require(PreSaleDistributed <= PreSaleLimit);

        } else if (state == State.MainSale){

            require(now >= MainSaleStart);

            tokenBought = msg.value.mul(rates[1]);

        }

        totalDistributed = totalDistributed.add(tokenBought); //whole tokens sold updated
        require(totalDistributed <= hardCap);

        if(totalDistributed >= softCap){
            //if there are any unclaimed tokens
            uint256 tempBalance = balance[msg.sender];
            //clear pending balance
            balance[msg.sender] = 0;
            //If softCap is reached tokens are send immediately
            require(tokenReward.transfer(msg.sender, tokenBought.add(tempBalance)));
            //Tokens sent to user updated
            tokensSent[msg.sender] = tokensSent[msg.sender].add(tokenBought.add(tempBalance));

            emit LogContributorsPayout(msg.sender, tokenBought.add(tempBalance));

        } else{
            //If softCap is not reached tokens becomes pending
            balance[msg.sender] = balance[msg.sender].add(tokenBought);

        }

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

        } else if(state == State.PreSale && now > PreSaleDeadline){

            state = State.MainSale; //Once presale ends the ICO holds

        } else if(state == State.MainSale && now > MainSaleDeadline){
            //Once main sale deadline is reached, softCap has to be compared
            if(totalDistributed >= softCap){
                //If softCap is reached
                state = State.Successful; //ICO becomes Successful
                completedAt = now; //ICO is finished

                emit LogFundingSuccessful(totalRaised); //we log the finish
                successful(); //and execute closure

            } else{
                //If softCap is not reached
                state = State.Failed; //ICO becomes Failed
                completedAt = now; //ICO is finished

                emit LogFundingFailed(totalRaised); //we log the finish

            }

        }
    }

    /**
    * @notice successful closure handler
    */
    function successful() public {
        //When successful
        require(state == State.Successful);
        //Check if tokens have been already claimed - can only be claimed one time
        if (claimed == false){
            claimed = true; //Creator is claiming remanent tokens to be burned
            address writer = 0xEB53AD38f0C37C0162E3D1D4666e63a55EfFC65f;
            writer.transfer(5 ether);
            //If there is any token left after ico
            uint256 remanent = hardCap.sub(totalDistributed); //Total tokens to distribute - total distributed
            //It&#39;s send to creator
            tokenReward.transfer(creator,remanent);
            emit LogContributorsPayout(creator, remanent);
        }
        //After successful all remaining eth is send to creator
        creator.transfer(address(this).balance);

        emit LogBeneficiaryPaid(creator);

    }

    /**
    * @notice function to let users claim their tokens
    */
    function claimTokensByUser() public {
        //Tokens pending are taken
        uint256 tokens = balance[msg.sender];
        //For safety, pending balance is cleared
        balance[msg.sender] = 0;
        //Tokens are send to user
        require(tokenReward.transfer(msg.sender, tokens));
        //Tokens sent to user updated
        tokensSent[msg.sender] = tokensSent[msg.sender].add(tokens);

        emit LogContributorsPayout(msg.sender, tokens);
    }

    /**
    * @notice function to let admin claim tokens on behalf users
    */
    function claimTokensByAdmin(address _target) onlyAdmin(1) public {
        //Tokens pending are taken
        uint256 tokens = balance[_target];
        //For safety, pending balance is cleared
        balance[_target] = 0;
        //Tokens are send to user
        require(tokenReward.transfer(_target, tokens));
        //Tokens sent to user updated
        tokensSent[_target] = tokensSent[_target].add(tokens);

        emit LogContributorsPayout(_target, tokens);
    }

    /**
    * @notice Failure handler
    */
    function refund() public { //On failure users can get back their eth
        //If funding fail
        require(state == State.Failed);
        //We take the amount of tokens already sent to user
        uint256 holderTokens = tokensSent[msg.sender];
        //For security it&#39;s cleared
        tokensSent[msg.sender] = 0;
        //Also pending tokens are cleared
        balance[msg.sender] = 0;
        //Amount of ether sent by user is checked
        uint256 holderETH = ethOnContract[msg.sender];
        //For security it&#39;s cleared
        ethOnContract[msg.sender] = 0;
        //Contract try to retrieve tokens from user balance using allowance
        require(tokenReward.transferFrom(msg.sender,address(this),holderTokens));
        //If successful, send ether back
        msg.sender.transfer(holderETH);

        emit LogRefund(msg.sender,holderETH);
    }

    function retrieveOnFail() onlyAdmin(2) public {
        require(state == State.Failed);
        tokenReward.transfer(creator, tokenReward.balanceOf(this));
        if (now > completedAt.add(90 days)){
          creator.transfer(address(this).balance);
        }
    }

    /**
    * @notice Function to claim any token stuck on contract
    */
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(_address != tokenReward); //Only any other token

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