pragma solidity ^0.4.15;
/*Visit  http://titscrypto.com/  for more information */

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    address public owner;


    /** 
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        } else {
            _;
        }
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) constant returns(uint256);

    function transfer(address to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns(uint256);

    function transferFrom(address from, address to, uint256 value);

    function approve(address spender, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    using SafeMath
    for uint256;
    mapping(address => uint256) balances;

	/**
	  * @dev transfer token for a specified address
	  * @param _to The address to transfer to.
	  * @param _value The amount to be transferred.
	  */
    function transfer(address _to, uint256 _value) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }
	
	/**
	  * @dev Gets the balance of the specified address.
	  * @param _owner The address to query the the balance of. 
	  * @return An uint256 representing the amount owned by the passed address.
	  */
    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) allowed;
	
	/**
	   * @dev Transfer tokens from one address to another
	   * @param _from address The address which you want to send tokens from
	   * @param _to address The address which you want to transfer to
	   * @param _value uint256 the amout of tokens to be transfered
	   */
    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

	  /**
	   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
	   * @param _spender The address which will spend the funds.
	   * @param _value The amount of tokens to be spent.
	   */
    function approve(address _spender, uint256 _value) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

	/**
	   * @dev Function to check the amount of tokens that an owner allowed to a spender.
	   * @param _owner address The address which owns the funds.
	   * @param _spender address The address which will spend the funds.
	   * @return A uint256 specifing the amount of tokens still avaible for the spender.
	   */
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MintStarted();
    event RefundRequest(uint256 sum,address adr,uint256 balance);
    event CoinBuy(uint256 sum,address adr);
    

    bool public mintingFinished = true;
    bool public goalReached = false;
    uint public mintingStartTime = 0;
    uint public maxMintingTime = 30 days;
    uint public mintingGoal = 500 ether;

    address public titsTokenAuthor = 0x189891d02445D87e70d515fD2159416f023B0087;

	/**
	   * @dev Fell fre to donate Author if You like what is presented here
	   */
    function donateAuthor() payable {
        titsTokenAuthor.transfer(msg.value);
    }

    bool public alreadyMintedOnce = false;

    modifier mintingClosed() {
        if (mintingFinished == false || alreadyMintedOnce == false) revert();
        _;
    }
    
    modifier IsMintingGoal() {
        if (mintingFinished == false || alreadyMintedOnce == false || goalReached == false ) revert();
        _;
    }

    modifier notMintedYet() {
        if (alreadyMintedOnce == true) revert();
        _;
    }

    function getNow() public returns(uint256){
        return now;
    }
    
	/**
	   * @dev Premium for buying TITS at the begining of ICO 
	   * @return bool True if no errors
	   */
    function fastBuyBonus() private returns(uint) {
        uint period = getNow() - mintingStartTime;
        if (period < 1 days) {
            return 3500;
        }
        if (period < 2 days) {
            return 3200;
        }
        if (period < 3 days) {
            return 3000;
        }
        if (period < 7 days) {
            return 2600;
        }
        if (period < 10 days) {
            return 2400;
        }
        if (period < 12 days) {
            return 2200;
        }
        if (period < 14 days) {
            return 2000;
        }
        if (period < 17 days) {
            return 1800;
        }
        if (period < 19 days) {
            return 1600;
        }
        if (period < 21 days) {
            return 1400;
        }
        if (period < 23 days) {
            return 1200;
        }
        return 1000;
    }

	/**
	   * @dev Allows to buy shares
	   * @return bool True if no errors
	   */
    function buy() payable returns(bool) {
        if (mintingFinished) {
            revert();
        }

        uint _amount = 0;
        _amount = msg.value * fastBuyBonus();
        totalSupply = totalSupply.add(_amount);
        CoinBuy(_amount,msg.sender);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        balances[owner] = balances[owner].add(_amount / 85 * 15); //15% shares of owner
        totalSupply = totalSupply.add(_amount / 85 * 15);
        return true;
    }

	/**
	   * @dev Opens ICO (only owner)
	   * @return bool True if no errors
	   */
    function startMinting() onlyOwner notMintedYet returns(bool) {
        mintingStartTime = getNow();
        alreadyMintedOnce = true;
        mintingFinished = false;
        MintStarted();
        return true;
    }

	/**
	   * @dev Closes ICO - anyone can invoke if invoked to soon, takes no actions
	   * @return bool True if no errors
	   */
    function finishMinting() returns(bool) {
        if (mintingFinished == false) {
            if (getNow() - mintingStartTime > maxMintingTime) {
                mintingFinished = true;
                MintFinished();
                goalReached = (this.balance > mintingGoal);
                return true;
            }
        }
        revert();
    }

	/**
	   * @dev Function refunds contributors if ICO was unsuccesful 
	   * @return bool True if conditions for refund are met false otherwise.
	   */
    function refund() returns(bool) {
        if (mintingFinished == true && goalReached == false && alreadyMintedOnce == true) {
            uint256 valueOfInvestment =  this.balance.mul(balances[msg.sender]).div(totalSupply);
            totalSupply.sub(balances[msg.sender]);
            RefundRequest(valueOfInvestment,msg.sender,balances[msg.sender]);
            balances[msg.sender] = 0;
            msg.sender.transfer(valueOfInvestment);
			return true;
        }
        revert();
    }
 
}

contract TitsToken is MintableToken {
    string public name = "Truth In The Sourcecode";
    string public symbol = "TITS";
    uint public decimals = 18;
    uint public voitingStartTime;
    address public votedAddress;
    uint public votedYes = 1;
    uint public votedNo = 0;
    event VoteOnTransferStarted(address indexed beneficiaryContract);
    event RegisterTransferBeneficiaryContract(address indexed beneficiaryContract);
    event VotingEnded(address indexed beneficiaryContract, bool result);
    event ShareHolderVoted(address adr,uint256 votes,bool isYesVote);

    uint public constant VOTING_PREPARE_TIMESPAN = 7 days;
    uint public constant VOTING_TIMESPAN =  7 days;
    uint public failedVotingCount = 0;
    bool public isVoting = false;
    bool public isVotingPrepare = false;

    address public beneficiaryContract = address(0);

    mapping(address => uint256) public votesAvailable;
    address[] public voters;

	/**
	   * @dev voting long enought to go to next phase 
	   */
    modifier votingLong() {
        if (getNow() - voitingStartTime <  VOTING_TIMESPAN) revert();
        _;
    }

	/**
	   * @dev preparation for voting (application for voting) long enought to go to next phase 
	   */
    modifier votingPrepareLong() {
        if (getNow() - voitingStartTime < VOTING_PREPARE_TIMESPAN) revert();
        _;
    }

	/**
	   * @dev Voting started and in progress
	   */
    modifier votingInProgress() {
        if (isVoting == false) revert();
        _;
    }
    modifier votingNotInProgress() {
        if (isVoting == true) revert();
        _;
    }

	/**
	   * @dev Voting preparation started and in progress
	   */
    modifier votingPrepareInProgress() {
        if (isVotingPrepare == false) revert();
        _;
    }

	/**
	   * @dev Voters agreed on proposed contract and Ethereum is being send to that contract
	   */
    function sendToBeneficiaryContract()  {
        if (beneficiaryContract != address(0)) {
            beneficiaryContract.transfer(this.balance);
        } else {
            revert();
        }
    }
		
	/**
	   * @dev can be called by anyone, if timespan withou accepted proposal long enought 
	   * enables refund
	   */
	function registerVotingPrepareFailure() mintingClosed{
		if(getNow()-mintingStartTime>(2+failedVotingCount)*maxMintingTime ){
			failedVotingCount=failedVotingCount+1;
            if (failedVotingCount == 10) {
                goalReached = false;
            }
		}
	}

	/**
	   * @dev opens preparation for new voting on proposed Lottery Contract address
	   */
    function startVotingPrepare(address votedAddressArg) mintingClosed votingNotInProgress IsMintingGoal onlyOwner{
        isVoting = false;
        isVotingPrepare = true;
        RegisterTransferBeneficiaryContract(votedAddressArg);
        votedAddress = votedAddressArg;
        voitingStartTime = getNow();
        for (uint i = 0; i < voters.length; i++) {
            delete voters[i];
        }
        delete voters;
    }

	/**
	   * @dev payable so attendance only of people who really care
	   * registers You as a voter;
	   */
    function registerForVoting() payable votingPrepareInProgress {
        if (msg.value >= 10 finney) {
            voters.push(msg.sender);
        }
		else{
			revert();
		}
    }

	/**
	   * @dev opens voting on proposed Lottery Contract address
	   */
    function startVoting() votingPrepareInProgress votingPrepareLong {
        VoteOnTransferStarted(votedAddress);
        for (uint256 i = 0; i < voters.length; i++) {
            address voter = voters[i];
            uint256 votes = balanceOf(voter);
            votesAvailable[voter]=votes;
        }
        isVoting = true;
        voitingStartTime = getNow();
        isVotingPrepare = false;
    }

	/**
	   * @dev closes voting on proposed Lottery Contract address
	   * checks if failed - if No votes is more common than yes increase failed voting count and if it reaches 10 
	   * reach of goal is failing and investors can withdraw their money
	   */
    function closeVoring() votingInProgress votingLong {
        VotingEnded(votedAddress, votedYes > votedNo);
        isVoting = false;
        isVotingPrepare = false;
        if (votedYes > votedNo) {
            beneficiaryContract = votedAddress;
        } else {
            failedVotingCount = failedVotingCount + 1;
            if (failedVotingCount == 10) {
                goalReached = false;
            }
        }
    }

	/**
	   * @dev votes on contract proposal
	   */
    function vote(bool isVoteYes) votingInProgress{

            uint256 votes = votesAvailable[msg.sender];
            ShareHolderVoted(msg.sender,votes,isVoteYes);
            if (isVoteYes) {
                votesAvailable[msg.sender] = 0;
                votedYes = votedYes.add(votes);
            }
            else
            if (isVoteYes==false) {
                votesAvailable[msg.sender] = 0;
                votedNo = votedNo.add(votes);
            } 
            else{
                revert();   
            }
            
    }
}