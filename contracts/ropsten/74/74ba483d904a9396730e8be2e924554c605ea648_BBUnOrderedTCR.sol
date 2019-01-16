pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    // modify by chris to make sure the proxy contract can set the first owner
    require(msg.sender == owner);
    _;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwnerProxyCall() {
    // modify by chris to make sure the proxy contract can set the first owner
    if(owner!=address(0)){
      require(msg.sender == owner);
    }
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwnerProxyCall {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



/**
 * @title BBLib
 * @dev Assorted BB operations
 */
library BBLib {
	function toB32(bytes a) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a));
	}
	function toB32(uint256 a) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a));
	}
	function toB32(uint256 a, bytes b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a, b));
	}
	function toB32(uint256 a, address b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a, b));
	}
	function toB32(uint256 a, address b, bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a, b, c));
	}
	function toB32(uint256 a, bytes b, address c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a, b,c));
	}
	function toB32(bytes a, bytes b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(bytes a, uint256 b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(uint256 a, uint256 b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(uint256 a, bytes b,bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	
	function toB32(uint256 a, uint256 b,bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}

	function toB32(bytes a, address b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(address a, bytes b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(address a, uint256 b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(bytes a, uint256 b, bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	function toB32(bytes a, address b, bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	
	function toB32(uint256 a, bytes b, uint256 c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	function toB32(uint256 a, uint256 b,bytes c, address d) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c, d));
	}
	function toB32(uint256 a, bytes b,uint256 c, address d) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c, d));
	}
	function toB32(bytes a, bytes b, address c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	function toB32(bytes a, uint256 b, address c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}

	function toB32(bytes a, uint256 b, bytes c, address d) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c,d));
	}
	function toB32(bytes a, uint256 b, bytes32 c, bytes d) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c,d));
	}


	function bytesToBytes32(bytes b) internal pure returns (bytes32) {
	    bytes32 out;

	    for (uint i = 0; i < 32; i++) {
	      out |= bytes32(b[i] & 0xFF) >> (i * 8);
	    }
	    return out;
  	}
}  /**
 * Created on 2018-10-13 10:20
 * @summary: 
 * @author: Chris Nguyen
 */




/**
 * Created on 2018-08-13 10:14
 * @summary: key-value storage
 * @author: Chris Nguyen
 */





/**
 * @title key-value storage contract
 */
contract BBStorage is Ownable {


    /**** Storage Types *******/

    mapping(bytes32 => uint256)    private uIntStorage;
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => bool)       private boolStorage;
    mapping(bytes32 => int256)     private intStorage;

    mapping(bytes32 => bool)       private admins;

    event AdminAdded(address indexed admin, bool add);
    /*** Modifiers ************/
   
    /// @dev Only allow access from the latest version of a contract in the network after deployment
    modifier onlyAdminStorage() {
        // // The owner is only allowed to set the storage upon deployment to register the initial contracts, afterwards their direct access is disabled
        require(admins[keccak256(abi.encodePacked(&#39;admin:&#39;,msg.sender))] == true);
        _;
    }

    /**
     * @dev 
     * @param admin Admin of the contract
     * @param add is true/false
     */
    function addAdmin(address admin, bool add) public onlyOwner {
        require(admin!=address(0x0));
        admins[keccak256(abi.encodePacked(&#39;admin:&#39;,admin))] = add;
        emit AdminAdded(admin, add);
    }
    
    /**** Get Methods ***********/

    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view returns (uint256) {
        return uIntStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }


    /**** Set Methods ***********/


    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyAdminStorage external {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value) onlyAdminStorage external {
        uIntStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string _value) onlyAdminStorage external {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes _value) onlyAdminStorage external {
        bytesStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyAdminStorage external {
        boolStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setInt(bytes32 _key, int _value) onlyAdminStorage external {
        intStorage[_key] = _value;
    }


    /**** Delete Methods ***********/
    
    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyAdminStorage external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) onlyAdminStorage external {
        delete uIntStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) onlyAdminStorage external {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) onlyAdminStorage external {
        delete bytesStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyAdminStorage external {
        delete boolStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteInt(bytes32 _key) onlyAdminStorage external {
        delete intStorage[_key];
    }

}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract BBStandard is Ownable {
  using SafeMath for uint256;
  BBStorage public bbs = BBStorage(0x0);
  ERC20 public bbo = ERC20(0x0);

  /**
   * @dev set storage contract address
   * @param storageAddress Address of the Storage Contract
   */
  function setStorage(address storageAddress) onlyOwner public {
    bbs = BBStorage(storageAddress);
  }
  

  /**
   * @dev set BBO contract address
   * @param BBOAddress Address of the BBO token
   */
  function setBBO(address BBOAddress) onlyOwner public {
    bbo = ERC20(BBOAddress);
  }
  /**
  * @dev withdrawTokens: call by admin to withdraw any token
  * @param anyToken token address
  * 
  */
  function emergencyERC20Drain(ERC20 anyToken) public onlyOwner{
      if(address(this).balance > 0 ) {
        owner.transfer( address(this).balance );
      }
      if( anyToken != address(0x0) ) {
          require( anyToken.transfer(owner, anyToken.balanceOf(this)) );
      }
  }
}

  /**
 * Created on 2018-08-13 10:20
 * @summary: 
 * @author: Chris Nguyen
 */





/**
 * @title BBVoting contract 
 */
contract BBVoting is BBStandard{
  BBVotingHelper public helper = BBVotingHelper(0x0);
  function setHelper(address _helper) onlyOwner public {
    helper = BBVotingHelper(_helper);
  }

  event PollStarted(uint256 indexed pollID, address indexed creator);
  event PollUpdated(uint256 indexed pollID,bool indexed isCancel);
  event PollOptionAdded(uint256 indexed pollID, uint256 optionID);

  event VotingRightsGranted(address indexed voter, uint256 numTokens);
  event VotingRightsWithdrawn(address indexed voter, uint256 numTokens);

  event VoteCommitted(address indexed voter, uint256 indexed pollID);
  event VoteRevealed(address indexed voter, uint256 indexed pollID);
  
  /**
   * @dev request voting rights
   * 
   */
  function requestVotingRights(uint256 numTokens) public {
    require(bbo.balanceOf(msg.sender) >= numTokens);
    uint256 voteTokenBalance = bbs.getUint(BBLib.toB32(msg.sender,&#39;STAKED_VOTE&#39;));
    require(bbo.transferFrom(msg.sender, address(this), numTokens));
    bbs.setUint(BBLib.toB32(msg.sender,&#39;STAKED_VOTE&#39;), voteTokenBalance.add(numTokens));
    emit VotingRightsGranted(msg.sender, numTokens);
  }
  
  /**
   * @dev withdraw voting rights
   * 
   */
  function withdrawVotingRights(uint256 numTokens) public 
  {
    uint256 voteTokenBalance = bbs.getUint(BBLib.toB32(msg.sender,&#39;STAKED_VOTE&#39;));
    require (voteTokenBalance > 0);
    require (numTokens > 0);
    require (numTokens<= voteTokenBalance);
    bbs.setUint(BBLib.toB32(msg.sender,&#39;STAKED_VOTE&#39;), voteTokenBalance.sub(numTokens));
    require(bbo.transfer(msg.sender, numTokens));
    emit VotingRightsWithdrawn(msg.sender, numTokens);
  }


  /**
   * @dev commitVote for poll
   * @param pollID Job Hash
   * @param secretHash Hash of Choice address and salt uint
   */
  function commitVote(uint256 pollID, bytes32 secretHash, uint256 tokens) public 
  {
    //uint256 minVotes = bbs.getUint(keccak256(&#39;MIN_VOTES&#39;));
    //uint256 maxVotes = bbs.getUint(keccak256(&#39;MAX_VOTES&#39;));
    uint256 pollStatus = bbs.getUint(BBLib.toB32(pollID,&#39;STATUS&#39;));
    require(pollStatus == 1);
    //require(tokens >= minVotes);
    //require(tokens <= maxVotes);
    (,,uint256 addPollOptionEndDate,uint256 commitEndDate,) = helper.getPollStage(pollID);
    
    require(addPollOptionEndDate<now);
    require(commitEndDate>now);
    require(secretHash != 0);
    
    uint256 voteTokenBalance = bbs.getUint(BBLib.toB32(msg.sender,&#39;STAKED_VOTE&#39;));
    if(voteTokenBalance<tokens){
      requestVotingRights(tokens.sub(voteTokenBalance));
    }
    require(bbs.getUint(BBLib.toB32(msg.sender,&#39;STAKED_VOTE&#39;)) >= tokens);
    // add secretHash

    bbs.setBytes(BBLib.toB32(pollID ,&#39;SECRET_HASH&#39;,msg.sender), abi.encodePacked(secretHash));
    bbs.setUint(BBLib.toB32(pollID ,&#39;VOTES&#39;, msg.sender), tokens);
    
    emit VoteCommitted(msg.sender, pollID);
  }


  /**
  * @dev revealVote for poll
  * @param pollID Job Hash
  * @param choice uint 
  * @param salt salt
  */
  function revealVote(uint256 pollID, uint choice, uint salt) public 
  {
    (,,,uint256 commitEndDate, uint256 revealEndDate) = helper.getPollStage(pollID);
    require(commitEndDate<now);
    require(revealEndDate>now);
    uint256 pollStatus = bbs.getUint(BBLib.toB32(pollID,&#39;STATUS&#39;));
    require(pollStatus >= 1);
    uint256 voteTokenBalance = bbs.getUint(BBLib.toB32(msg.sender,&#39;STAKED_VOTE&#39;));
    uint256 votes = bbs.getUint(BBLib.toB32(pollID,&#39;VOTES&#39;,msg.sender));
    // check staked vote
    require(voteTokenBalance>= votes);

    bytes32 choiceHash = BBLib.toB32(choice,salt);

    bytes32 secretHash = BBLib.bytesToBytes32(bbs.getBytes(BBLib.toB32(pollID,&#39;SECRET_HASH&#39;,msg.sender)));
    require(choiceHash == secretHash);
    // make sure not reveal yet
    require(bbs.getUint(BBLib.toB32(pollID,&#39;CHOICE&#39;,msg.sender)) == 0x0);
    uint256 numVote = bbs.getUint(BBLib.toB32(pollID,&#39;VOTE_FOR&#39;,choice));
    //save result poll
    bbs.setUint(BBLib.toB32(pollID,&#39;VOTE_FOR&#39;,choice), numVote.add(votes));
    // save voter choice
    bbs.setUint(BBLib.toB32(pollID,&#39;CHOICE&#39;,msg.sender), choice);
    // set has vote flag 
    if(pollStatus == 1)
      bbs.setUint(BBLib.toB32(pollID,&#39;STATUS&#39;), 2);
    emit VoteRevealed(msg.sender, pollID);
  }


  function updatePoll(uint256 pollID, bool isCancel, uint256 commitDuration,uint256 revealDuration) public returns(bool success) {
    (uint256 pollStatus, address creator,,,uint256 revealEndDate) = helper.getPollStage(pollID);
    require(pollStatus == 1);
    require(revealEndDate < now);
    require(creator == msg.sender);
    if(isCancel){
      return _doCancel(pollID);
    }else{
      return _doExtendPoll(pollID, commitDuration, revealDuration);
    }
  }

  function _doCancel(uint256 pollID) private returns(bool success){
    // TODO here
    // set status to 0
    bbs.setUint(BBLib.toB32(pollID,&#39;STATUS&#39;), 0);
    success = true;
    emit PollUpdated(pollID, true );

  }

  function _doExtendPoll(uint256 pollID, uint256 commitDuration,uint256 revealDuration) private returns(bool success){
    bbs.setUint(BBLib.toB32(pollID,&#39;COMMIT_ENDDATE&#39;), block.timestamp.add(commitDuration));
    bbs.setUint(BBLib.toB32(pollID,&#39;REVEAL_ENDDATE&#39;), block.timestamp.add(commitDuration).add(revealDuration));
    success = true;
    emit PollUpdated(pollID, false);
  }

  function startPoll(bytes extraData, uint256 addOptionDuration, uint256 commitDuration,uint256 revealDuration) public returns(uint256 pollID) {    
    uint256 latestID  = bbs.getUint(BBLib.toB32(&#39;POLL_COUNTER&#39;));
    pollID = latestID.add(1);
    bbs.setUint(BBLib.toB32(&#39;POLL_COUNTER&#39;), pollID);
    // save startPoll address
    bbs.setAddress(BBLib.toB32(pollID, &#39;OWNER&#39;), msg.sender);
    // addPollOptionEndDate
    uint256 addPollOptionEndDate = block.timestamp.add(addOptionDuration);
    // commitEndDate
    uint256 commitEndDate = addPollOptionEndDate.add(commitDuration);
    // revealEndDate
    uint256 revealEndDate = commitEndDate.add(revealDuration);
    // save addPollOption, commit, reveal EndDate
    bbs.setUint(BBLib.toB32(pollID,&#39;STATUS&#39;), 1);
    bbs.setUint(BBLib.toB32(pollID,&#39;ADDOPTION_ENDDATE&#39;), addPollOptionEndDate);
    bbs.setUint(BBLib.toB32(pollID,&#39;COMMIT_ENDDATE&#39;), commitEndDate);
    bbs.setUint(BBLib.toB32(pollID,&#39;REVEAL_ENDDATE&#39;), revealEndDate);

    _doAddPollOption(pollID, extraData);

    emit PollStarted(pollID, msg.sender);
    return pollID;
  }
  
  function addPollOption(uint256 pollID, bytes pollOption) public returns(bool success){
    (uint256 pollStatus, address creator,,,) = helper.getPollStage(pollID);
    require(pollStatus == 1);
    require(creator == msg.sender);
    //todo check msg.sender
    require(bbs.getUint(BBLib.toB32(pollID,&#39;ADDOPTION_ENDDATE&#39;)) > now);
    return _doAddPollOption(pollID, pollOption);
  }
  
  function _doAddPollOption(uint256 pollID, bytes optionHashIPFS) private  returns(bool success){
    // check optionID make sure this hash not saved yet
    require(bbs.getUint(BBLib.toB32(pollID, &#39;OPTION&#39;, optionHashIPFS))== 0x0);
    // get latestID + 1 for new ID
    uint256 optionID = bbs.getUint(BBLib.toB32(pollID, &#39;OPTION_COUNTER&#39;)).add(1);
    // save latestID
    bbs.setUint(BBLib.toB32(pollID, &#39;OPTION_COUNTER&#39;), optionID);
    // save option
    bbs.setBytes(BBLib.toB32(pollID, &#39;IPFS_HASH&#39;, optionID), optionHashIPFS);
    bbs.setAddress(BBLib.toB32(pollID, &#39;CREATOR&#39;, optionID), msg.sender);
    success = true;
    emit PollOptionAdded(pollID, optionID);
  }
  
}

  /**
 * Created on 2018-08-13 10:20
 * @summary: 
 * @author: Chris Nguyen
 */





/**
 * @title BBVoting contract 
 */
contract BBVotingHelper is BBStandard{

  function getPollResult(uint256 pollID) public view returns(uint256[], uint256[]){
    uint256 numOption = bbs.getUint(BBLib.toB32(pollID, &#39;OPTION_COUNTER&#39;));
    uint256[] memory opts = new uint256[](numOption.add(1));
    uint256[] memory votes = new uint256[](numOption.add(1));
    for(uint256 i = 0; i <= numOption ; i++){
      opts[i] = i;
      votes[i] = (bbs.getUint(BBLib.toB32(pollID,&#39;VOTE_FOR&#39;,opts[i])));
    }

    return (opts, votes);
  }
  function getPollID(uint256 pollType, uint256 relatedTo) public view returns(uint256 pollID){
    pollID = bbs.getUint(BBLib.toB32(relatedTo, pollType,&#39;POLL&#39;));
  }

  function getPollStage(uint256 pollID) public view returns(uint256, address, uint256, uint256, uint256){
    uint256 pollStatus = bbs.getUint(BBLib.toB32(pollID,&#39;STATUS&#39;));
    address creator = bbs.getAddress(BBLib.toB32(pollID, &#39;OWNER&#39;));
    uint256 addPollOptionEndDate = bbs.getUint(BBLib.toB32(pollID,&#39;ADDOPTION_ENDDATE&#39;));
    uint256 commitEndDate = bbs.getUint(BBLib.toB32(pollID,&#39;COMMIT_ENDDATE&#39;));
    uint256 revealEndDate = bbs.getUint(BBLib.toB32(pollID,&#39;REVEAL_ENDDATE&#39;));
    return (pollStatus, creator, addPollOptionEndDate, commitEndDate, revealEndDate); 
  }
    /**
  * @dev check Hash for poll
  * @param pollID Job Hash
  * @param choice uint256 
  * @param salt salt
  */
  function checkHash(uint256 pollID, uint256 choice, uint salt) public view returns(bool){
    bytes32 choiceHash = BBLib.toB32(choice,salt);
    bytes32 secretHash = BBLib.bytesToBytes32(bbs.getBytes(BBLib.toB32(pollID,&#39;SECRET_HASH&#39;,msg.sender)));
    return (choiceHash==secretHash);
  }
  function checkStakeBalance() public view returns(uint256 tokens){
    tokens = bbs.getUint(BBLib.toB32(msg.sender,&#39;STAKED_VOTE&#39;));
  }
  function hasVoting(uint256 pollType, uint256 relatedTo) public view returns(bool r){
    uint256 pollID = getPollID(pollType, relatedTo);
    if(pollID > 0) {
      uint256 pollStatus = bbs.getUint(BBLib.toB32(pollID,&#39;STATUS&#39;));
      uint256 revealEndDate = bbs.getUint(BBLib.toB32(pollID,&#39;REVEAL_ENDDATE&#39;));
      r = (pollStatus >= 1 && revealEndDate < now);
    }
  }
  function getPollOption(uint256 pollID, uint256 optID) public view returns(bytes opt){
    opt = bbs.getBytes(BBLib.toB32(pollID, &#39;IPFS_HASH&#39;, optID));
  }
  
  function getPollWinner(uint256 pollID)public constant returns(bool isFinished, uint256 winner, uint256 winnerVotes , bool hasVote, uint256 quorum) {
    (uint256 pollStatus,,,,uint256 revealEndDate) = getPollStage(pollID);
    isFinished = (revealEndDate <= now);
    if(pollStatus==2){
      hasVote = true;
      uint256 totalVotes = 0;
      (uint256[] memory addrs,uint256[] memory votes) = getPollResult(pollID);
      for(uint256 i=0; i< addrs.length ;i++){
        totalVotes = totalVotes.add(votes[i]);
        if(winnerVotes<votes[i]){
          winnerVotes = votes[i];
          winner = addrs[i];
        }
      }
      if(totalVotes > 0)
        quorum = winnerVotes.mul(100).div(totalVotes);
    }
  }
  /**
  @param voter           Address of voter who voted in the majority bloc
  @param pollID          Integer identifier associated with target poll
  @return correctVotes    Number of tokens voted for winning option
  */
  function getNumPassingTokens(address voter, uint256 pollID) public constant returns (uint256 correctVotes) {
      (bool isFinished, uint256 winner,, bool hasVote,) = getPollWinner(pollID);
      if(isFinished==true && hasVote == true){
        uint256 userChoice = bbs.getUint(BBLib.toB32(pollID,&#39;CHOICE&#39;, voter));
        if (winner == userChoice){
          correctVotes = bbs.getUint(BBLib.toB32(pollID ,&#39;VOTES&#39;, voter));
        }
      }
  }
}







contract BBTCRHelper is BBStandard {

    function setParamsUnOrdered(uint256 listID, uint256 applicationDuration, uint256 commitDuration, uint256 revealDuration, uint256 minStake, uint256 initQuorum, uint256 exitDuration) onlyOwner public  {
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;APPLICATION_DURATION&#39;), applicationDuration);
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;COMMIT_DURATION&#39;), commitDuration);
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;REVEAL_DURATION&#39;), revealDuration);
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;MIN_STAKE&#39;), minStake);
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;MIN_STAKE&#39;), minStake);
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;QUORUM&#39;), initQuorum);
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;EXITDURATION&#39;), exitDuration);

    }

    function getListParamsUnOrdered(uint256 listID) public view returns(uint256 applicationDuration, uint256 commitDuration, uint256 revealDuration, uint256 minStake){
        applicationDuration = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;APPLICATION_DURATION&#39;));
        commitDuration = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;COMMIT_DURATION&#39;));
        revealDuration = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;REVEAL_DURATION&#39;));
        minStake = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;MIN_STAKE&#39;));
    }

    function getStakedBalanceUnOrdered(uint256 listID, bytes32 itemHash) public constant returns (uint256) {
        return  bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;STAKED&#39;));
    }

}




contract BBUnOrderedTCR is BBStandard{
	// events
	event ItemApplied(uint256 indexed listID, bytes32 indexed itemHash, bytes data);
    event Challenge(uint256 indexed listID, bytes32 indexed itemHash, uint256 pollID, address sender);
    //
    BBVoting public voting = BBVoting(0x0);
    BBVotingHelper public votingHelper = BBVotingHelper(0x0);
    BBTCRHelper public tcrHelper = BBTCRHelper(0x0);
      
    function setVoting(address p) onlyOwner public  {
      voting = BBVoting(p);
    }
    function setVotingHelper(address p) onlyOwner public  {
      votingHelper = BBVotingHelper(p);
    }

    function setTCRHelper(address p) onlyOwner public  {
      tcrHelper = BBTCRHelper(p);
    }


    function isOwnerItem(uint256 listID, bytes32 itemHash) private constant returns (bool r){
        address owner = bbs.getAddress(BBLib.toB32(&#39;TCR&#39;,listID, itemHash, &#39;OWNER&#39;));
         r = (owner == msg.sender && owner != address(0x0));
    }

     function canApply(uint256 listID, bytes32 itemHash) private constant returns (bool r){
        address owner = bbs.getAddress(BBLib.toB32(&#39;TCR&#39;,listID, itemHash, &#39;OWNER&#39;));
         r = (owner == msg.sender || owner == address(0x0));
    }

    //Lam sao user bi remove, kiem tra so deposit
    function depositToken(uint256 listID, bytes32 itemHash, uint amount) public returns(bool) {
        (,,, uint256 minStake) = tcrHelper.getListParamsUnOrdered(listID);
        uint256 staked = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;STAKED&#39;));
        require(staked.add(amount) >= minStake);
        require (bbo.transferFrom(msg.sender, address(this), amount));
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;STAKED&#39;), staked.add(amount));
        return true;
    }
    function apply(uint256 listID, uint256 amount, bytes32 itemHash, bytes data) public {
    	//TODO add index of item in the list
        require(canApply(listID,itemHash));
        //
    	(uint256 applicationDuration,,,) = tcrHelper.getListParamsUnOrdered(listID);
        require(depositToken(listID, itemHash,amount));
        // save creator
        bbs.setAddress(BBLib.toB32(&#39;TCR&#39;,listID, itemHash, &#39;OWNER&#39;), msg.sender);
        // save application endtime
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;APPLICATION_ENDTIME&#39;), block.timestamp.add(applicationDuration));
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;), 1);
        // emit event
        emit ItemApplied(listID, itemHash, data);
    }
    
    // lay balance - min stake >= _amount // set lai stake
    function withdraw(uint256 listID, bytes32 itemHash, uint _amount) external {
    	//TODO allow withdraw unlocked token
        require (isOwnerItem(listID, itemHash));
        (,,, uint256 minStake) = tcrHelper.getListParamsUnOrdered(listID);
        uint256 staked = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;STAKED&#39;));
        require(staked - minStake >= _amount);

        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;STAKED&#39;), staked.sub(_amount));
        assert(bbo.transfer(msg.sender, _amount));
    
    }
    
    function initExit(uint256 listID, bytes32 itemHash) external {	
    	//TODO Initialize an exit timer for a listing to leave the whitelist
        // exit timer 
        require (isOwnerItem(listID, itemHash));
        require(bbs.getUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;)) == 3);
        uint256 applicationExitDuration = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;EXITDURATION&#39;));
        // save application exittime
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;EXITTIME&#39;), block.timestamp.add(applicationExitDuration));

    }
    // set state = 0, tra tien so huu
    function finalizeExit(uint256 listID, bytes32 itemHash) external {
        // TODO Allow a listing to leave the whitelist
        // after x timer will 
        require (isOwnerItem(listID, itemHash));
        require(bbs.getUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;)) == 3);
        uint256 applicationExitTime= bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;EXITTIME&#39;));
        require(now > applicationExitTime);
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;), 0);

    }
    function calcRewardPool(uint256 listID, uint256 stakedToken) internal constant returns(uint256){
        uint oneHundred = 100; 
        return (oneHundred.sub(bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;LOSE_PERCENT&#39;)))
            .mul(stakedToken)).div(100);
    }
    function challenge(uint256 listID, bytes32 itemHash, bytes _data) external returns (uint pollID) {
        // not in challenge stage
        require(bbs.getUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;)) != 2);
        // require deposit token        
        (, uint256 commitDuration, uint256 revealDuration, uint256 minStake) = tcrHelper.getListParamsUnOrdered(listID);
        require (bbo.transferFrom(msg.sender, address(this), minStake));
        
        pollID = voting.startPoll(_data, 0 , commitDuration, revealDuration);
        require(pollID > 0);
        // save pollID 
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, pollID, &#39;CHALLENGER_STAKED&#39;), minStake);

        bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;POLL_ID&#39;), pollID);
        
        bbs.setUint(BBLib.toB32(&#39;TCR_POLL_ID&#39;, pollID ), calcRewardPool(listID, minStake));
        // save challenger
        bbs.setAddress(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;CHALLENGER&#39;), msg.sender);
        // in challenge stage
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;), 2);
        emit Challenge(listID, itemHash, pollID, msg.sender);
    }

    function updateStatus(uint256 listID, bytes32 itemHash) public {
        if (canBeWhitelisted(listID, itemHash)) {
            whitelistApplication(listID, itemHash);
        } else if (challengeCanBeResolved(listID, itemHash)) {
            resolveChallenge(listID, itemHash);
        } else {
         revert();
        }
    }

    function claimReward(uint pollID) public {
        require(bbs.getBool(BBLib.toB32(&#39;TCR_VOTER_CLAIMED&#39;, pollID, msg.sender)) == false);
        uint256 numReward = voterReward(msg.sender, pollID);
        require(numReward > 0);
        assert(bbo.transfer(msg.sender, numReward));
        bbs.setBool(BBLib.toB32(&#39;TCR_VOTER_CLAIMED&#39;, pollID, msg.sender), true);
    }
    function voterReward(address voter, uint pollID) public view returns (uint numReward) {
        if(bbs.getBool(BBLib.toB32(&#39;TCR_VOTER_CLAIMED&#39;, pollID, voter)) == false){
           uint256 userVotes =  votingHelper.getNumPassingTokens(voter, pollID);
            (bool isFinished,, uint256 winnerVotes,, uint256 quorum) = votingHelper.getPollWinner(pollID);
            if(isFinished==true && userVotes > 0 && quorum > 50){
                uint256 rewardPool =  bbs.getUint(BBLib.toB32(&#39;TCR_POLL_ID&#39;, pollID ));
                numReward = userVotes.mul(rewardPool).div(winnerVotes); // (vote/totalVotes) * staked
            }
        } 
        
    }
    function whitelistApplication(uint256 listID, bytes32 itemHash) private {
        bbs.setBool(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;WHITE_LISTED&#39;), true);
        bbs.setUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;), 3);
    }
    function canBeWhitelisted(uint256 listID, bytes32 itemHash) view public returns (bool) {
        uint256 applicationEndtime = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;APPLICATION_ENDTIME&#39;));
	    uint256 stage = bbs.getUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;));
        if(applicationEndtime > 0 && applicationEndtime < now && stage == 1 && !isWhitelisted(listID, itemHash)){
            return true;
        }
        return false;
    }
	function isWhitelisted(uint256 listID, bytes32 itemHash) view public returns (bool whitelisted) {
        return bbs.getBool(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;WHITE_LISTED&#39;));
	}

    function challengeCanBeResolved(uint256 listID, bytes32 itemHash) view public returns (bool) {
        uint pollID = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;POLL_ID&#39;));
        uint256 stage = bbs.getUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;));
        require(stage == 2);
        (bool isFinished,,,,) = votingHelper.getPollWinner(pollID);
        return isFinished;
    }
    function determineReward(uint pollID) public view returns (uint) {
        uint256 minStake = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, pollID, &#39;CHALLENGER_STAKED&#39;));
        // Edge case, nobody voted, give all tokens to the challenger.
        // quorum 70 --> lose
        // if nobody voted, ?? TODO
        (,,, bool hasVote, ) = votingHelper.getPollWinner(pollID);
        if (hasVote!=true) {
            return 2 * minStake;//TODO ... should reward to voter
        }

        return (2 * minStake) - bbs.getUint(BBLib.toB32(&#39;TCR_POLL_ID&#39;, pollID ));
    }
    function resolveChallenge(uint256 listID, bytes32 itemHash) private {
        uint pollID = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;POLL_ID&#39;));
        (bool isFinished, , uint256 winnerVotes ,, uint256 quorum) = votingHelper.getPollWinner(pollID);
        uint256 initQuorum = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, &#39;QUORUM&#39;));
        uint256 reward = determineReward(pollID);
        if(quorum>= initQuorum && isFinished == true && winnerVotes > 0){
            //pass vote
            whitelistApplication(listID, itemHash);
            uint256 staked = bbs.getUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;STAKED&#39;));
            bbs.setUint(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;STAKED&#39;), staked.add(reward));
        }else{
            // did not pass // thang do khong pass, trang thai true -false,
            //remove ra khoi list
            bbs.setUint(BBLib.toB32(&#39;TCR&#39;,listID, itemHash,&#39;STAGE&#39;), 0);
            assert(bbo.transfer(bbs.getAddress(BBLib.toB32(&#39;TCR&#39;, listID, itemHash, &#39;CHALLENGER&#39;)), reward));
        }
    }
}