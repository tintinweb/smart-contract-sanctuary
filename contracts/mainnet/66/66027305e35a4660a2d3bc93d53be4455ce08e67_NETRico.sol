pragma solidity ^0.4.23;

// File: contracts/commons/SafeMath.sol

/**
 * @title SafeMath by OpenZeppelin (partially)
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

// File: contracts/interfaces/ERC20TokenInterface.sol

/**
 * Token contract interface for external use
 */
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 value);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

}

// File: contracts/interfaces/FiatContractInterface.sol

/**
* @title Fiat currency contract
* @dev This contract will return the value of 0.01$ ETH in wei
*/
contract FiatContractInterface {

    function EUR(uint _id) public constant returns (uint256);

}

// File: contracts/NETRico.sol

/**
* @title NETRico sale main contract
*/
contract NETRico {

    FiatContractInterface price = FiatContractInterface(0x8055d0504666e2B6942BeB8D6014c964658Ca591); // MAINNET ADDRESS

    using SafeMath for uint256;

    //This sale have 3 stages
    enum State {
        Stage1,
        Stage2,
        Successful
    }

    //public variables
    State public state = State.Stage1; //Set initial stage
    uint256 public startTime;
    uint256 public startStage2Time;
    uint256 public deadline;
    uint256 public totalRaised; //eth in wei
    uint256 public totalDistributed; //tokens distributed
    uint256 public completedAt; //Time stamp when the sale finish
    ERC20TokenInterface public tokenReward; //Address of the valid token used as reward
    address public creator; //Address of the contract deployer
    string public campaignUrl; //Web site of the campaign
    string public version = "2";

    //events for log
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator, string _url);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    /**
    * @notice NETRico constructor
    * @param _campaignUrl is the ICO _url
    * @param _addressOfTokenUsedAsReward is the token totalDistributed
    * @param _startTime timestamp of Stage1 start
    * @param _startStage2Time timestamp of Stage2 start
    * @param _deadline timestamp of Stage2 stop
    */
    function NETRico(string _campaignUrl, ERC20TokenInterface _addressOfTokenUsedAsReward,
        uint256 _startTime, uint256 _startStage2Time, uint256 _deadline) public {
        require(_addressOfTokenUsedAsReward != address(0)
            && _startTime > now
            && _startStage2Time > _startTime
            && _deadline > _startStage2Time);

        creator = 0xB987B463c7573f0B7b6eD7cc8E5Fab9042272065;
        //creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = ERC20TokenInterface(_addressOfTokenUsedAsReward);

        startTime = _startTime;
        startStage2Time = _startStage2Time;
        deadline = _deadline;

        emit LogFunderInitialized(creator, campaignUrl);
    }

    /**
    * @notice Function to handle eth transfers
    * @dev BEWARE: if a call to this functions doesn&#39;t have
    * enough gas, transaction could not be finished
    */
    function() public payable {
        contribute();
    }

    /**
    * @notice Set timestamp of Stage2 start
    **/
    function setStage2Start(uint256 _startStage2Time) public onlyCreator {
        require(_startStage2Time > now && _startStage2Time > startTime && _startStage2Time < deadline);
        startStage2Time = _startStage2Time;
    }

    /**
    * @notice Set timestamp of deadline
    **/
    function setDeadline(uint256 _deadline) public onlyCreator {
        require(_deadline > now && _deadline > startStage2Time);
        deadline = _deadline;
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {
        require(now >= startTime);

        uint256 tokenBought;
        //Variable to store amount of tokens bought
        uint256 tokenPrice = price.EUR(0);
        //1 cent value in wei

        totalRaised = totalRaised.add(msg.value);
        //Save the total eth totalRaised (in wei)

        tokenPrice = tokenPrice.mul(2);
        //0.02$ EUR value in wei
        tokenPrice = tokenPrice.div(10 ** 8);
        //Change base 18 to 10

        tokenBought = msg.value.div(tokenPrice);
        //Base 18/ Base 10 = Base 8
        tokenBought = tokenBought.mul(10 ** 10);
        //Base 8 to Base 18

        require(tokenBought >= 100 * 10 ** 18);
        //Minimum 100 base tokens

        //Bonus calculation
        if (state == State.Stage1) {
            tokenBought = tokenBought.mul(140);
            tokenBought = tokenBought.div(100);
            //+40%
        } else if (state == State.Stage2) {
            tokenBought = tokenBought.mul(120);
            tokenBought = tokenBought.div(100);
            //+20%
        }

        totalDistributed = totalDistributed.add(tokenBought);
        //Save to total tokens distributed

        tokenReward.transfer(msg.sender, tokenBought);
        //Send Tokens

        creator.transfer(msg.value);
        // Send ETH to creator
        emit LogBeneficiaryPaid(creator);

        //LOGS
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);

        checkIfFundingCompleteOrExpired();
    }

    /**
    * @notice check status
    */
    function checkIfFundingCompleteOrExpired() public {

        if (now > deadline && state != State.Successful) {

            state = State.Successful;
            //Sale becomes Successful
            completedAt = now;
            //ICO finished

            emit LogFundingSuccessful(totalRaised);
            //we log the finish

            finished();
        } else if (state == State.Stage1 && now >= startStage2Time) {

            state = State.Stage2;

        }
    }

    /**
    * @notice Function for closure handle
    */
    function finished() public { //When finished eth are transferred to creator
        require(state == State.Successful);
        //Only when sale finish

        uint256 remainder = tokenReward.balanceOf(this);
        //Remaining tokens on contract
        //Funds send to creator if any
        if (address(this).balance > 0) {
            creator.transfer(address(this).balance);
            emit LogBeneficiaryPaid(creator);
        }

        tokenReward.transfer(creator, remainder);
        //remainder tokens send to creator
        emit LogContributorsPayout(creator, remainder);

    }

    /**
    * @notice Function to claim any token stuck on contract
    */
    function claimTokens(ERC20TokenInterface _address) public {
        require(state == State.Successful);
        //Only when sale finish
        require(msg.sender == creator);

        uint256 remainder = _address.balanceOf(this);
        //Check remainder tokens
        _address.transfer(creator, remainder);
        //Transfer tokens to creator

    }
}