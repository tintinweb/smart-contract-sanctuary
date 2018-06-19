pragma solidity ^0.4.20;
/**
* @title ICO SALE CONTRACT
* @dev ERC-20 Token Standard Compliant
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
* @title Fiat currency contract
* @dev This contract will return the value of 0.01$ ETH in wei
*/
contract FiatContract {
 
  function EUR(uint _id) constant public returns (uint256);

}

/**
* @title DateTime contract
* @dev This contract will return the unix value of any date
*/
contract DateTimeAPI {
        
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) constant public returns (uint timestamp);

}

/**
* @title ERC20 Token interface
*/
contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

}

/**
* @title NETRico sale main contract
*/
contract NETRico {

    FiatContract price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591); // MAINNET ADDRESS

    DateTimeAPI dateTimeContract = DateTimeAPI(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce);//Main

    using SafeMath for uint256;
    //This sale have 5 stages
    enum State {
        Stage1,
        Stage2,
        Stage3,
        Stage4,
        Successful
    }
    //public variables
    State public state = State.Stage1; //Set initial stage
    uint256 public startTime = dateTimeContract.toTimestamp(2018,4,1,0); //From Apr 1 2018 00:00
    uint256 public deadline = dateTimeContract.toTimestamp(2019,3,27,0); //Stop Mar 27 2019 00:00
    uint256 public totalRaised; //eth in wei
    uint256 public totalDistributed; //tokens distributed
    uint256 public completedAt; //Time stamp when the sale finish
    token public tokenReward; //Address of the valid token used as reward
    address public creator; //Address of the contract deployer
    string public campaignUrl; //Web site of the campaign
    string public version = &#39;2&#39;;

    //events for log
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        string _url);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
    /**
    * @notice NETRico constructor
    * @param _campaignUrl is the ICO _url
    * @param _addressOfTokenUsedAsReward is the token totalDistributed
    */
    function NETRico (string _campaignUrl, token _addressOfTokenUsedAsReward) public {
        creator = 0xB987B463c7573f0B7b6eD7cc8E5Fab9042272065;
        //creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = token(_addressOfTokenUsedAsReward);

        emit LogFunderInitialized(
            creator,
            campaignUrl
            );
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {
        require(now >= startTime);

        uint256 tokenBought; //Variable to store amount of tokens bought
        uint256 tokenPrice = price.EUR(0); //1 cent value in wei

        totalRaised = totalRaised.add(msg.value); //Save the total eth totalRaised (in wei)

        tokenPrice = tokenPrice.mul(2); //0.02$ EUR value in wei 
        tokenPrice = tokenPrice.div(10 ** 8); //Change base 18 to 10

        tokenBought = msg.value.div(tokenPrice); //Base 18/ Base 10 = Base 8
        tokenBought = tokenBought.mul(10 ** 10); //Base 8 to Base 18

        require(tokenBought >= 100 * 10 ** 18); //Minimum 100 base tokens 
        
        //Bonus calculation
        if (state == State.Stage1){
            tokenBought = tokenBought.mul(2); //+100%
        } else if (state == State.Stage2){
            tokenBought = tokenBought.mul(175);
            tokenBought = tokenBought.div(100); //+75%
        } else if (state == State.Stage3){
            tokenBought = tokenBought.mul(15);
            tokenBought = tokenBought.div(10); //+50%
        } else if (state == State.Stage4){
            tokenBought = tokenBought.mul(125);
            tokenBought = tokenBought.div(100); //+25%
        }

        totalDistributed = totalDistributed.add(tokenBought); //Save to total tokens distributed
        
        tokenReward.transfer(msg.sender,tokenBought); //Send Tokens
        
        creator.transfer(msg.value); // Send ETH to creator
        emit LogBeneficiaryPaid(creator);
        
        //LOGS
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit  LogContributorsPayout(msg.sender,tokenBought);

        checkIfFundingCompleteOrExpired();
    }

    /**
    * @notice check status
    */
    function checkIfFundingCompleteOrExpired() public {

        if(now > deadline && state != State.Successful){

            state = State.Successful; //Sale becomes Successful
            completedAt = now; //ICO finished

            emit LogFundingSuccessful(totalRaised); //we log the finish

            finished();
        } else if(state == State.Stage3 && now > dateTimeContract.toTimestamp(2018,12,27,0)){

            state = State.Stage4;
            
        } else if(state == State.Stage2 && now > dateTimeContract.toTimestamp(2018,9,28,0)){

            state = State.Stage3;
            
        } else if(state == State.Stage1 && now > dateTimeContract.toTimestamp(2018,6,30,0)){

            state = State.Stage2;

        }
    }

    /**
    * @notice Function for closure handle
    */
    function finished() public { //When finished eth are transfered to creator
        require(state == State.Successful); //Only when sale finish
        
        uint256 remainder = tokenReward.balanceOf(this); //Remaining tokens on contract
        //Funds send to creator if any
        if(address(this).balance > 0) {
            creator.transfer(address(this).balance);
            emit LogBeneficiaryPaid(creator);
        }
 
        tokenReward.transfer(creator,remainder); //remainder tokens send to creator
        emit LogContributorsPayout(creator, remainder);

    }

    /**
    * @notice Function to claim any token stuck on contract
    */
    function claimTokens(token _address) public{
        require(state == State.Successful); //Only when sale finish
        require(msg.sender == creator);

        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(creator,remainder); //Transfer tokens to creator
        
    }

    /**
    * @notice Function to handle eth transfers
    * @dev BEWARE: if a call to this functions doesn&#39;t have
    * enought gas, transaction could not be finished
    */
    function() public payable {
        contribute();
    }
    
}