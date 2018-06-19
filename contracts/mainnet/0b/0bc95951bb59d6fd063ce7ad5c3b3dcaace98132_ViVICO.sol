pragma solidity 0.4.24;
/**
* @title Vivalid ICO Contract
* @dev ViV is an ERC-20 Standar Compliant Token
* For more info https://vivalid.io
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

contract ViVICO is admined {

    using SafeMath for uint256;
    //This ico have 5 possible states
    enum State {
        PreSale, //PreSale - best value
        MainSale,
        OnHold,
        Failed,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.PreSale; //Set initial stage
    uint256 public PreSaleStart = now; //Once deployed
    uint256 constant public PreSaleDeadline = 1529452799; //(GMT): Tuesday, 19 de June de 2018 23:59:59
    uint256 public MainSaleStart; //TBA
    uint256 public MainSaleDeadline; // TBA
    uint256 public completedAt; //Set when ico finish
    //Token-eth related
    uint256 public totalRaised; //eth collected in wei
    uint256 public PreSaleDistributed; //presale tokens distributed
    uint256 public totalDistributed; //Whole sale tokens distributed
    ERC20Basic public tokenReward; //Token contract address
    uint256 public softCap = 11000000 * (10 ** 18); //11M Tokens
    uint256 public hardCap = 140000000 * (10 ** 18); // 140M tokens
    //User balances handlers
    mapping (address => uint256) public ethOnContract; //Balance of sent eth per user
    mapping (address => uint256) public tokensSent; //Tokens sent per user
    mapping (address => uint256) public balance; //Tokens pending to send per user
    //Contract details
    address public creator;
    string public version = &#39;1&#39;;

    //Tokens per eth rates
    uint256[5] rates = [2520,2070,1980,1890,1800];

    //User rights handlers
    mapping (address => bool) public whiteList; //List of allowed to send eth
    mapping (address => bool) public KYCValid; //KYC validation to claim tokens

    //events for log
    event LogFundrisingInitialized(address _creator);
    event LogMainSaleDateSet(uint256 _time);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogRefund(address _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFundingFailed(uint _totalRaised);

    //Modofoer to prevent execution if ico has ended or is holded
    modifier notFinishedOrHold() {
        require(state != State.Successful && state != State.OnHold && state != State.Failed);
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
    * @notice Whitelist function
    */
    function whitelistAddress(address _user, bool _flag) public onlyAdmin(1) {
        whiteList[_user] = _flag;
    }
    
    /**
    * @notice KYC validation function
    */
    function validateKYC(address _user, bool _flag) public onlyAdmin(1) {
        KYCValid[_user] = _flag;
    }

    /**
    * @notice Main Sale Start function
    */
    function setMainSaleStart(uint256 _startTime) public onlyAdmin(2) {
        require(state == State.OnHold);
        require(_startTime > now);
        MainSaleStart = _startTime;
        MainSaleDeadline = MainSaleStart.add(12 weeks);
        state = State.MainSale;

        emit LogMainSaleDateSet(MainSaleStart);
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinishedOrHold payable {
        require(whiteList[msg.sender] == true); //User must be whitelisted
        require(msg.value >= 0.1 ether); //Minimal contribution
        
        uint256 tokenBought = 0; //tokens bought variable

        totalRaised = totalRaised.add(msg.value); //ether received updated
        ethOnContract[msg.sender] = ethOnContract[msg.sender].add(msg.value); //ether sent by user updated

        //Rate of exchange depends on stage
        if (state == State.PreSale){
            
            require(now >= PreSaleStart);

            tokenBought = msg.value.mul(rates[0]);
            PreSaleDistributed = PreSaleDistributed.add(tokenBought); //Tokens sold on presale updated
        
        } else if (state == State.MainSale){

            require(now >= MainSaleStart);

            if (now <= MainSaleStart.add(1 weeks)){
                tokenBought = msg.value.mul(rates[1]);
            } else if (now <= MainSaleStart.add(2 weeks)){
                tokenBought = msg.value.mul(rates[2]);
            } else if (now <= MainSaleStart.add(3 weeks)){
                tokenBought = msg.value.mul(rates[3]);
            } else tokenBought = msg.value.mul(rates[4]);
                
        }

        require(totalDistributed.add(tokenBought) <= hardCap);

        if(KYCValid[msg.sender] == true){
            //if there are any unclaimed tokens
            uint256 tempBalance = balance[msg.sender];
            //clear pending balance
            balance[msg.sender] = 0;
            //If KYC is valid tokens are send immediately
            require(tokenReward.transfer(msg.sender, tokenBought.add(tempBalance)));
            //Tokens sent to user updated
            tokensSent[msg.sender] = tokensSent[msg.sender].add(tokenBought.add(tempBalance));

            emit LogContributorsPayout(msg.sender, tokenBought.add(tempBalance));

        } else{
            //If KYC is not valid tokens becomes pending
            balance[msg.sender] = balance[msg.sender].add(tokenBought);

        }

        totalDistributed = totalDistributed.add(tokenBought); //whole tokens sold updated
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

            state = State.OnHold; //Once presale ends the ICO holds

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
        //Users have 14 days period to claim tokens
        if (now > completedAt.add(14 days)){
            //If there is any token left after
            uint256 remanent = tokenReward.balanceOf(this);
            //It&#39;s send to creator
            tokenReward.transfer(creator,remanent);
            emit LogContributorsPayout(creator, remanent);
        }
        //After successful eth is send to creator
        creator.transfer(address(this).balance);

        emit LogBeneficiaryPaid(creator);

    }

    function claimEth() onlyAdmin(2) public {
        //Only if softcap is reached
        require(totalDistributed >= softCap);
        //eth is send to creator
        creator.transfer(address(this).balance);
        emit LogBeneficiaryPaid(creator);
    }

    /**
    * @notice function to let users claim their tokens
    */
    function claimTokensByUser() public {
        //User must have a valid KYC
        require(KYCValid[msg.sender] == true);
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
        //User must have a valid KYC
        require(KYCValid[_target] == true);
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
        //Users have 90 days to claim a refund
        if (now < completedAt.add(90 days)){
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
        } else{
            //After 90 days period only a master admin can use the function
            require(level[msg.sender] >= 2);
            //To claim remanent tokens on contract
            uint256 remanent = tokenReward.balanceOf(this);
            //And ether
            creator.transfer(address(this).balance);
            tokenReward.transfer(creator,remanent);

            emit LogBeneficiaryPaid(creator);
            emit LogContributorsPayout(creator, remanent);
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