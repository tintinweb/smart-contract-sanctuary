pragma solidity ^0.4.23;

/**
 * @title SafeMath
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
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
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
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Voting{

    using SafeMath for uint;

    struct Vote{
        address voter;
        uint enityID;
        uint voted;
        uint tokensStaked;
        uint votingPeriod;
    }

    struct Entity{
        uint id;
        string name;
        uint startTime;
        uint reward;
        uint noOfStakedTokens;
        Vote[] votes;
        uint firstPeriodOutcome;
        uint secondPeriodOutcome;
        uint finalOutcome;
        mapping(address => bool) voteCasted;
    }


    Entity[] public entities;

    struct Wallet{
        uint voteCount;
        bool registered;
        uint[] lastOutcomes;
    }

    mapping(address => Wallet) public wallets;
    address[] walletList;


    mapping(uint => mapping(address => uint)) public payouts;
    address public owner;

    ERC20 public token;

  

    constructor(address _token) public{
        owner = msg.sender; //TODO
        token = ERC20(_token);
    }

    modifier onlyOwner(){
        require(msg.sender == owner || msg.sender == address(this));
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner{
        require(_newOwner != 0x0);
        require(_newOwner != owner);

        owner = _newOwner;
    }


    event NewEntity(uint id, string name, uint startTime, uint reward);
    function addEntity(string _name, uint _startTime, uint _reward) public onlyOwner{
        require(_startTime > 0 && _reward > 0);

        uint newEntityID = entities.length;

        entities.length++;
        Entity storage newEntity = entities[entities.length - 1];

        newEntity.id = entities.length - 1;
        newEntity.name = _name;
        newEntity.startTime = _startTime;
        newEntity.reward = _reward;
        newEntity.noOfStakedTokens = 0;
        newEntity.firstPeriodOutcome = 0;
        newEntity.secondPeriodOutcome = 0;
        newEntity.finalOutcome = 0;

        Vote memory v;
        newEntity.votes.push(v);
        entities.push(newEntity);

        token.transferFrom(msg.sender, address(this), _reward);
        for(uint i = 0; i < walletList.length; i++){
            wallets[walletList[i]].voteCount = wallets[walletList[i]].voteCount.sub(1);
        }

        emit NewEntity(newEntityID, _name, _startTime, _reward);
    }

    event VoteCasted(uint entityID, uint voted, uint tokenAmount, uint votingPeriod, address voter);
    function castVote(uint _entityID, uint _voted, uint _tokenStaked) public{
        require(_entityID >= 0 && _tokenStaked > 0);

        Entity storage entity = entities[_entityID];
        Wallet storage wallet = wallets[msg.sender];

        require(!entity.voteCasted[msg.sender]);
        require(wallet.voteCount <= 20);

        if(!wallet.registered){
            uint[] memory empty;
            wallets[msg.sender] = Wallet(0, true, empty);
            walletList.push(msg.sender);
        }
        
        uint votingPeriod;  

        // if(now >= entity.startTime && now <= entity.startTime + 7 days){
        //     votingPeriod = 1;
        // } else if(now > entity.startTime + 7 days && now <= entity.startTime + 14 days){
        //     votingPeriod = 2;
        // } else {
        //     return;
        // }


        if(now >= entity.startTime && now <= entity.startTime + 5 seconds){
            votingPeriod = 1;
        } else if(now > entity.startTime + 5 seconds && now <= entity.startTime + 10 seconds){
            if(entity.firstPeriodOutcome == 0){
                this.determineFirstPeriodOutcome(entity.id);
            }

            require(entity.firstPeriodOutcome != _voted);
            votingPeriod = 2;

        } else {
            revert();
        }

        entity.votes.push(Vote(msg.sender, _entityID, _voted, _tokenStaked, votingPeriod));
        entity.noOfStakedTokens = entity.noOfStakedTokens.add(_tokenStaked);

        token.transferFrom(msg.sender, address(this), _tokenStaked);

        wallet.voteCount = wallet.voteCount.add(1);

        entity.voteCasted[msg.sender] = true;

        emit VoteCasted(_entityID, _voted, _tokenStaked, votingPeriod, msg.sender);
    }

    function getYESVotesByEntity(uint _entityID) public view returns(uint){
        require(_entityID >= 0);

        Entity memory entity = entities[_entityID];

        uint count = 0;

        for(uint i = 0; i < entity.votes.length; i++){
            if(entity.votes[i].voted == 1){
                count = count.add(1);
            }
        }

        return count;
    }


    function getNOVotesByEntity(uint _entityID) public view returns(uint){
        require(_entityID >= 0);

        Entity memory entity = entities[_entityID];

        uint count = 0;

        for(uint i = 0; i < entity.votes.length; i++){
            if(entity.votes[i].voted == 2){
                count = count.add(1);
            }
        }

        return count;
    }

    function getCurrentPeriodByEntity(uint _entityID) public view returns(uint){
        require(_entityID >= 0);

        Entity memory entity = entities[_entityID];

        uint time = entity.startTime;

        uint period = 0;

        if(now >= time && now < time + 5 seconds){
            period = 1;
        }
        else if(now >= time + 5 seconds && now <= time + 10 seconds ){
            period = 2;
        }

        return period;

    }

    function getOutcomeOfFirstPeriodByEntity(uint _entityID) public view returns(uint){
        require(_entityID >= 0);
        return entities[_entityID].firstPeriodOutcome;
    }

    function getOutcomeOfSecondPeriodByEntity(uint _entityID) public view returns(uint){
        require(_entityID >= 0);
        return entities[_entityID].secondPeriodOutcome;
    }

    function getFinalOutcomeByEntity(uint _entityID) public view returns(uint){
        require(_entityID >= 0);
        return entities[_entityID].finalOutcome;
    }

    function getVotingPower(uint _noOfStakedTokens, uint _VotertokensStaked, address voter) public view returns(uint){

        Wallet memory w = wallets[voter];

        uint Co = 0;
        uint Io = 0;
        uint i = 0;
        if(w.lastOutcomes.length > 20){
            uint counter = w.lastOutcomes.length - 20;

            for(i = 0; i < 20; i++){
                if(w.lastOutcomes[counter] == 1){
                    Co = Co.add(1);
                } else if(w.lastOutcomes[counter] == 2){
                    Io = Io.add(1);
                }
                counter = counter.add(1);
            }
        }
        else {
            for(i = 0; i < w.lastOutcomes.length; i++){
                if(w.lastOutcomes[i] == 1){
                    Co = Co.add(1);
                } else if(w.lastOutcomes[i] == 2){
                    Io = Io.add(1);
                }
            }
        }

        uint Si = _VotertokensStaked;
        uint St = _noOfStakedTokens;

        uint Vmax = w.voteCount; // ?? TODO

        return getResult(Co, Io, Si, St, Vmax);
        
    

    }

    function getResult(uint Co, uint Io, uint Si, uint St, uint Vmax) public pure returns(uint){

        uint Vp = 1 + ((Co.sub(Io).div(Vmax)).mul(1).div(20) + (Si.div(St)).mul(3).div(20));
// Vp = 1 + (0.05 x (Co - Io / Vm+x) + (0.15 * (Si / St)))
        return Vp;
    }

    event FirstPeriodOutcome(uint entityID, uint outcome);
    function determineFirstPeriodOutcome(uint _entityID) external onlyOwner{
        require(_entityID >= 0);

        Entity storage entity = entities[_entityID];

        uint yesVotesPower = 0;
        uint noVotesPower = 0;


        uint i = 0;
        for(i = 0; i < entity.votes.length; i++){
            uint votingPower = 0;
            if(entity.votes[i].votingPeriod == 1 && entity.votes[i].voted == 1){

                votingPower = getVotingPower(entity.noOfStakedTokens, entity.votes[i].tokensStaked, entity.votes[i].voter);
                yesVotesPower = yesVotesPower.add(votingPower);

            } else if(entity.votes[i].votingPeriod == 1 && entity.votes[i].voted == 2){

                votingPower = getVotingPower(entity.noOfStakedTokens, entity.votes[i].tokensStaked, entity.votes[i].voter);
                noVotesPower = noVotesPower.add(votingPower);

            }
        }

        uint totalVotingPower = yesVotesPower + noVotesPower;

        uint yes_percent = yesVotesPower.mul(100).div(totalVotingPower);
        uint no_percent = noVotesPower.mul(100).div(totalVotingPower);

        if(yes_percent > no_percent){
            entity.firstPeriodOutcome = 1;
        }else{
            entity.firstPeriodOutcome = 2;
        }

        emit FirstPeriodOutcome(_entityID, entity.firstPeriodOutcome);
    }


    // event SecondPeriodOutcome(uint entityID, uint outcome);
    function determineOutcome(uint _entityID) external onlyOwner{
        require(_entityID >= 0);

        Entity storage entity = entities[_entityID];

        // require(now > entity.startTime + 5 seconds);
        if(entity.firstPeriodOutcome == 0){
            this.determineFirstPeriodOutcome(entity.id);
        }

        uint yesVotesPower = 0;
        uint noVotesPower = 0;

        bool voteExists;


        uint i = 0;
        for(i = 0; i < entity.votes.length; i++){
            uint votingPower = 0;
            if(entity.votes[i].votingPeriod == 2 && entity.votes[i].voted == 1){

                votingPower = getVotingPower(entity.noOfStakedTokens, entity.votes[i].tokensStaked, entity.votes[i].voter);
                yesVotesPower = yesVotesPower.add(votingPower);
                voteExists = true;

            } else if(entity.votes[i].votingPeriod == 2 && entity.votes[i].voted == 2){

                votingPower = getVotingPower(entity.noOfStakedTokens, entity.votes[i].tokensStaked, entity.votes[i].voter);
                noVotesPower = noVotesPower.add(votingPower);
                voteExists = true;

            }
        }

        if(voteExists){
            uint totalVotingPower = yesVotesPower + noVotesPower;

            uint yes_percent = yesVotesPower.mul(100).div(totalVotingPower);
            uint no_percent = noVotesPower.mul(100).div(totalVotingPower);

            if(yes_percent > no_percent){
                entity.secondPeriodOutcome = 1;
            }else{
                entity.secondPeriodOutcome = 2;
            }

        }

        this.determineFinalOutcome(entity.id);
        // emit SecondPeriodOutcome(_entityID,entity.secondPeriodOutcome);


    }

    event FinalOutcome(uint entityID, uint outcome);
    function determineFinalOutcome(uint _entityID) external onlyOwner{
        require(_entityID >= 0);

        Entity storage entity = entities[_entityID];
        uint i = 0;

        if(entity.secondPeriodOutcome == 0){
            uint votingPowerYes = 0;
            uint votingPowerNo = 0;

            for(i = 0; i < entity.votes.length; i++){
                if(entity.votes[i].votingPeriod == 1 && entity.votes[i].voted == 1){
                    votingPowerYes = votingPowerYes.add(getVotingPower(entity.noOfStakedTokens, entity.votes[i].tokensStaked, entity.votes[i].voter));
                } else if(entity.votes[i].votingPeriod == 1 && entity.votes[i].voted == 2){
                    votingPowerNo = votingPowerNo.add(getVotingPower(entity.noOfStakedTokens, entity.votes[i].tokensStaked, entity.votes[i].voter));
                }
            }

            uint total = votingPowerYes + votingPowerNo;
            uint percent_yes = votingPowerYes.mul(100).div(total);
            uint percent_no = votingPowerNo.mul(100).div(total);

            if(percent_yes >= uint(251).div(5)){
                entity.finalOutcome = 1;
            } else if(percent_no >= uint(251).div(5)){
                entity.finalOutcome = 2;
            }

        } else {

         
            uint votingPower1 = 0;
            uint votingPower2 = 0;

            for(i = 0; i < entity.votes.length; i++){
                if(entity.votes[i].votingPeriod == 1 && entity.votes[i].voted == entity.firstPeriodOutcome){
                    votingPower1 = votingPower1.add(getVotingPower(entity.noOfStakedTokens, entity.votes[i].tokensStaked, entity.votes[i].voter));
                } else if(entity.votes[i].votingPeriod == 2){
                    votingPower2 = votingPower2.add(getVotingPower(entity.noOfStakedTokens, entity.votes[i].tokensStaked, entity.votes[i].voter));
                }
            }


            uint totalPower = votingPower1 + votingPower2;

            uint first_percent = votingPower1.mul(100).div(totalPower);
            uint second_percent = votingPower2.mul(100).div(totalPower);

            if(second_percent > 60){
                entity.finalOutcome = entity.secondPeriodOutcome;
            } else {
                entity.finalOutcome = entity.firstPeriodOutcome;
            }
            
        }

        setPayoutForWinners(entity.finalOutcome, entity);
        emit FinalOutcome(_entityID, entity.finalOutcome);
    }

    event PayoutSet(uint en,address voter, uint amount);
    function setPayoutForWinners(uint _outcome, Entity memory entity) internal{
        
        uint reward = entity.reward;
        uint totalStakedTokens = entity.noOfStakedTokens;

        Vote[] memory votes = entity.votes;

        uint i = 0;

        for(i = 0; i < votes.length; i++){
            if(votes[i].voted == _outcome){

                uint stakedTokensByVoter = votes[i].tokensStaked;
                uint percent_coin = stakedTokensByVoter.mul(100).div(totalStakedTokens);
                uint percent_reward = reward.mul(percent_coin).div(100);

                uint claimableAmount = stakedTokensByVoter + percent_reward;

                payouts[entity.id][votes[i].voter] = claimableAmount;
                wallets[votes[i].voter].lastOutcomes.push(1);
                // emit PayoutSet(entity.id, votes[i].voter, payouts[entity.id][votes[i].voter]);

            } else {
                wallets[votes[i].voter].lastOutcomes.push(2);
            }
        }
    }

    event TokenClaimed(address claimer, uint amount);
    function claimTokens(uint _entityID) external{
        require(_entityID >= 0);

        uint claimableAmount = payouts[_entityID][msg.sender];
        require(token.balanceOf(address(this)) >= claimableAmount);

        payouts[_entityID][msg.sender] = 0;

        token.transfer(msg.sender, claimableAmount);

        emit TokenClaimed(msg.sender, claimableAmount);
    }


    // function getEntity(uint _entityID) public view returns(){
    //     require(_entityID >= 0);
    //     Entity memory entity = entities[_entityID];

    // }

}