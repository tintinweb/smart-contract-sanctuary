pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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
contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;
    mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     /**
  * @dev total number of tokens in existence
  */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract RotoToken is StandardToken {

    string public constant name = "Roto"; // token name
    string public constant symbol = "ROTO"; // token symbol
    uint8 public constant decimals = 18; // token decimal

    uint256 public constant INITIAL_SUPPLY = 21000000 * (10 ** uint256(decimals));
    address owner;
    address roto = this;
    address manager;

    // keeps track of the ROTO currently staked in a tournament
    // the format is user address -> the tournament they staked in -> how much they staked
    mapping (address => mapping (bytes32 => uint256)) stakes;
    uint256 owner_transfer = 2000000 * (10** uint256(decimals));
  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */

    modifier onlyOwner {
        require(msg.sender==owner);
        _;
    }

    modifier onlyManager {
      require(msg.sender==manager);
      _;
    }

    event ManagerChanged(address _contract);
    event RotoStaked(address _user, uint256 stake);
    event RotoReleased(address _user, uint256 stake);
    event RotoDestroyed(address _user, uint256 stake);
    event RotoRewarded(address _contract, address _user, uint256 reward);

    constructor() public {
        owner = msg.sender;
        totalSupply_ = INITIAL_SUPPLY;
        balances[roto] = INITIAL_SUPPLY;
        emit Transfer(0x0, roto, INITIAL_SUPPLY);
    }

    
    /**
     *  @dev A function that can only be called by RotoHive, transfers Roto Tokens out of the contract.
        @param _to address, the address that the ROTO will be transferred to
        @param _value ROTO, amount to transfer
        @return - whether the Roto was transferred succesfully
     */
    function transferFromContract(address _to, uint256 _value) public onlyOwner returns(bool) {
        require(_to!=address(0));
        require(_value<=balances[roto]);
        require(owner_transfer > 0);

        owner_transfer = owner_transfer.sub(_value);
        
        balances[roto] = balances[roto].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(roto, _to, _value);
        return true;
    }

    /**
        @dev updates the helper contract(which will manage the tournament) with the new version
        @param _contract address, the address of the manager contract
        @return - whether the contract was successfully set
    */
    function setManagerContract(address _contract) external onlyOwner returns(bool) {
      //checks that the address sent isn&#39;t the 0 address, the owner or the token contract
      require(_contract!=address(0)&&_contract!=roto);

      // requires that the address sent be a contract
      uint size;
      assembly { size := extcodesize(_contract) }
      require(size > 0);

      manager = _contract;

      emit ManagerChanged(_contract);
      return true;
    }

    /**
        @dev - called by the manager contract to add back to the user their roto in the event that their submission was successful
        @param  _user address, the address of the user who submitted the rankings
        @param _tournamentID identifier
        @return boolean value, whether the roto were successfully released
    */
    function releaseRoto(address _user, bytes32 _tournamentID) external onlyManager returns(bool) {
        require(_user!=address(0));
        uint256 value = stakes[_user][_tournamentID];
        require(value > 0);

        stakes[_user][_tournamentID] = 0;
        balances[_user] = balances[_user].add(value);

        emit RotoReleased(_user, value);
        return true;
    }

    /**
        @dev - function called by manager contract to process the accounting aspects of the destroyRoto function
        @param  _user address, the address of the user who&#39;s stake will be destroyed
        @param _tournamentID identifier
        @return - a boolean value that reflects whether the roto were successfully destroyed
    */
    function destroyRoto(address _user, bytes32 _tournamentID) external onlyManager returns(bool) {
        require(_user!=address(0));
        uint256 value = stakes[_user][_tournamentID];
        require(value > 0);

        stakes[_user][_tournamentID] = 0;
        balances[roto] = balances[roto].add(value);

        emit RotoDestroyed(_user, value);
        return true;
    }

    /**
        @dev - called by the manager contract, runs the accounting portions of the staking process
        @param  _user address, the address of the user staking ROTO
        @param _tournamentID identifier
        @param _value ROTO, the amount the user is staking
        @return - whether the staking process went successfully
    */
    function stakeRoto(address _user, bytes32 _tournamentID, uint256 _value) external onlyManager returns(bool) {
        require(_user!=address(0));
        require(_value<=balances[_user]);
        require(stakes[_user][_tournamentID] == 0);

        balances[_user] = balances[_user].sub(_value);
        stakes[_user][_tournamentID] = _value;

        emit RotoStaked(_user, _value);
        return true;
    }
    
    /**
      @dev - called by the manager contract, used to reward non-staked submissions by users
      @param _user address, the address that will receive the rewarded ROTO
      @param _value ROTO, the amount of ROTO that they&#39;ll be rewarded
     */
    function rewardRoto(address _user, uint256 _value) external onlyManager returns(bool successful) {
      require(_user!=address(0));
      require(_value<=balances[roto]);

      balances[_user] = balances[_user].add(_value);
      balances[roto] = balances[roto].sub(_value);

      emit RotoRewarded(roto, _user, _value);
      return true;
    }
    /**
        @dev - to be called by the manager contract to check if a given user has enough roto to
            stake the given amount
        @param  _user address, the address of the user who&#39;s attempting to stake ROTO
        @param _value ROTO, the amount they are attempting to stake
        @return - whether the user has enough balance to stake the received amount
    */
    function canStake(address _user, uint256 _value) public view onlyManager returns(bool) {
      require(_user!=address(0));
      require(_value<=balances[_user]);

      return true;
    }

    /**
      @dev Getter function for manager
     */
    function getManager() public view returns (address _manager) {
      return manager;
    }

    /**
      @dev - sets the owner address to a new one
      @param  _newOwner address
      @return - true if the address was changed successful
     */
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
      owner = _newOwner;
    }
}
contract RotoBasic {

    mapping (bytes32 => Tournament) public tournaments;  // tournamentID
    
    //Instance and Address of the RotoToken contract
    RotoToken token;
    address roto;

    //Address of the contract owner the manager contract(this contract)
    address owner;
    address manager;

    //boolean variable that determines whether there&#39;s an emergency state
    bool emergency;

    struct Tournament {
        bool open;
        // the total ether prize and how much is left
        uint256 etherPrize;
        uint256 etherLeft;
        // the total roto prize how much is left
        uint256 rotoPrize;
        uint256 rotoLeft;
        // tournament details
        uint256 creationTime;
        mapping (address => mapping (bytes32 => Stake)) stakes;  // address of staker, to tournament ID points to a specific stake
        //counters to easily tell the # of stakes vs # of stakes resolved
        uint256 userStakes;
        uint256 stakesResolved;
    }

    struct Stake {
        uint256 amount; // Once the stake is resolved, this becomes 0
        bool successful;
        bool resolved;
    }

    modifier onlyOwner {
      require(msg.sender==owner);
      _;
    }

    modifier stopInEmergency {
      require(emergency==false);
      _;
    }

    //Tournament Creation and Processing Events
    event StakeProcessed(address indexed staker, uint256 totalAmountStaked, bytes32 indexed tournamentID);
    event StakeDestroyed(bytes32 indexed tournamentID, address indexed stakerAddress, uint256 rotoLost);
    event StakeReleased(bytes32 indexed tournamentID, address indexed stakerAddress, uint256 etherReward, uint256 rotoStaked);
    event SubmissionRewarded(bytes32 indexed tournamentID, address indexed stakerAddress, uint256 rotoReward);
    
    event TokenChanged(address _contract);
    event TournamentCreated(bytes32 indexed tournamentID, uint256 etherPrize, uint256 rotoPrize);
    event TournamentClosed(bytes32 indexed tournamentID);

    /**
       @dev - sets the token contract to used for the token accounting
       @param _contract address, the address of the token contract
       @return - true if the token contract was set successfully
    */
    function setTokenContract(address _contract) public onlyOwner returns(bool) {
      require(_contract!=address(0)&&_contract!=manager);

      // requires that the address sent be a contract
      uint size;
      assembly { size := extcodesize(_contract) }
      require(size > 0);

      roto = _contract;
      token = RotoToken(roto);

      emit TokenChanged(_contract);
      return true;
    }

    /**
        @dev - sets the state of the emegency variable to true, preventing any of the tournament processes to run
        @param _emergency boolean variable to set emergency to
        @return - true if the variable was changed successfully
    */
    function setEmergency(bool _emergency) public onlyOwner returns(bool) {
      emergency = _emergency;
      return true;
    }

    /**
      @dev - sets the owner address to a new one
      @param  _newOwner address
      @return - true if the address was changed successful
     */
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
      owner = _newOwner;
    }

}

contract RotoManager is RotoBasic {

    using SafeMath for uint256;

    constructor() public {
      owner = msg.sender;
      emergency = false;
      manager = this;
    }

    /**
        @dev - In the event that their submissions were successful, this function will return the tokens to the user, and distribute ether rewards were applicable
        @param _user The user&#39;s address, the ether the&#39;ve won,
        @return - returns whether the Roto was sucessfully transferred
     */
    function releaseRoto(address _user, bytes32 _tournamentID, uint256 _etherReward) external onlyOwner stopInEmergency returns(bool successful){
        Tournament storage tournament = tournaments[_tournamentID];
        require(tournament.open==true);

        Stake storage user_stake = tournament.stakes[_user][_tournamentID];
        uint256 initial_stake = user_stake.amount;

        // prelimiary checks 
        require(initial_stake > 0);
        require(user_stake.resolved == false);

        // ether balance rewards
        require(manager.balance > _etherReward);
        require(tournament.etherLeft >= _etherReward);

        //Redistributes roto back to the user, and marks the stake as successful and completed
        user_stake.amount = 0;
        assert(token.releaseRoto(_user, _tournamentID)); // calls the token contract releaseRoto function to handle the token accounting
        tournament.stakesResolved = tournament.stakesResolved.add(1);
        
        user_stake.resolved = true;
        user_stake.successful = true;

        if(_etherReward > 0) {
          tournament.etherLeft = tournament.etherLeft.sub(_etherReward);
          _user.transfer(_etherReward);
        }

        emit StakeReleased(_tournamentID, _user, _etherReward, initial_stake);
        
        return true;
    }
    /**
        @dev - If the user did not stake ROTO, but they still had a successful submission, then RotoHive will reward the user with an amount of ROTO respective to their performance.
        @param _user address, which the ROTO will be sent to
        @param _rotoReward amount of ROTO that the user has won
        @return - a boolean value determining whether the operation was successful
    
     */
    function rewardRoto(address _user, bytes32 _tournamentID, uint256 _rotoReward) external onlyOwner stopInEmergency returns(bool successful) {
      Tournament storage tournament = tournaments[_tournamentID];
      require(tournament.open==true);

      Stake storage user_stake = tournament.stakes[_user][_tournamentID];
      uint256 initial_stake = user_stake.amount;
      
      require(initial_stake==0);
      require(tournament.rotoLeft >= _rotoReward);
      require(user_stake.resolved == false);

      tournament.rotoLeft = tournament.rotoLeft.sub(_rotoReward);
      assert(token.rewardRoto(_user, _rotoReward));

      user_stake.resolved = true;
      user_stake.successful = true;

      emit SubmissionRewarded(_tournamentID, _user, _rotoReward);

      return true;
    }

    /**
        @dev - For unsuccessful submission, the Roto will initially sent back to the contract.
        @param _user address, the address of the user who&#39;s stake was unsuccessful
        @param _tournamentID 32byte hex, the tournament which the stake belongs to
        @return - whether the roto was successfully destroyed
     */
    function destroyRoto(address _user, bytes32 _tournamentID) external onlyOwner stopInEmergency returns(bool successful) {
        Tournament storage tournament = tournaments[_tournamentID];
        require(tournament.open==true);

        Stake storage user_stake = tournament.stakes[_user][_tournamentID];

        uint256 initial_stake = user_stake.amount;

        require(initial_stake > 0);
        require(user_stake.resolved == false);

        user_stake.amount = 0;
        user_stake.resolved = true;
        user_stake.successful = false;

        assert(token.destroyRoto(_user, _tournamentID));
        tournament.stakesResolved = tournament.stakesResolved.add(1);

        emit StakeDestroyed(_tournamentID, _user, initial_stake);

        return true;
    }

    /**
        @dev - The public method which will allow user&#39;s to stake their Roto alongside their submissions
        @param _value the amount of Roto being staked, the id of that stake, and the id of the tournament
        @return - whether the staking request was successful
     */
    function stake(uint256 _value, bytes32 _tournamentID) external stopInEmergency returns(bool successful) {
        return _stake(msg.sender, _tournamentID, _value);
    }

    /**
        @dev - The internal method to process the request to stake Roto as a part of the Tournament Submission
        @param _staker the user who&#39;s staking roto, the ID of the tournament, the amount of roto the user&#39;s staking, the staking tag
        @return - whether the withdraw operation was successful
     */
    function _stake(address _staker, bytes32 _tournamentID, uint256 _value) internal returns(bool successful) {
        Tournament storage tournament = tournaments[_tournamentID];

        //The User can&#39;t submit after tournament closure and the tournament must have begun
        require((tournament.open==true));
        require(tournament.etherPrize>0);
        
        Stake storage user_stake = tournament.stakes[_staker][_tournamentID];
        
        require(user_stake.amount==0); // Users can only stake once
        require(_value>0); // Users must stake at least 1 ROTO
        require(_staker != roto && _staker != owner); //RotoHive can&#39;t stake in tournament
        
        //Users must have the necessary balances to submit their stake
        assert(token.canStake(_staker, _value));

        user_stake.amount = _value;
        assert(token.stakeRoto(_staker,_tournamentID,_value));

        // adds the stake the submission
        tournament.userStakes = tournament.userStakes.add(1);

        emit StakeProcessed(_staker, user_stake.amount, _tournamentID);

        return true;
    }

    /**
        @dev - Allows RotoHive to create this week&#39;s RotoHive Tournament
        @param _tournamentID 32byte hex, the ID which RotoHive uses to reference each tournament
        @param _etherPrize Eth, the total ether prize pool for the tournament
        @param _rotoPrize ROTO, the total ROTO prize pool for the tournament
        @return - whether the tournament was successfully created
     */
    function createTournament(bytes32 _tournamentID, uint256 _etherPrize, uint256 _rotoPrize) external payable onlyOwner returns(bool successful) {
        Tournament storage newTournament = tournaments[_tournamentID];
        require(newTournament.creationTime==0);
        
        newTournament.open = true;
        newTournament.etherPrize = _etherPrize;
        newTournament.etherLeft = _etherPrize;

        newTournament.rotoPrize = _rotoPrize;
        newTournament.rotoLeft = _rotoPrize;
        newTournament.creationTime = block.timestamp;

        emit TournamentCreated(_tournamentID, _etherPrize, _rotoPrize);

        return true;
    }

    /**
      @dev - closes the current tournament after the submission deadline has passed
      @param _tournamentID the tournament ID
      @return - returns whether the tournament was closed successfully
    */
    function closeTournament(bytes32 _tournamentID) external onlyOwner returns(bool successful) {
       Tournament storage tournament = tournaments[_tournamentID];
      //  the tournament should be open
       require(tournament.open==true);

       //  all the prizes should have been given out
       require(tournament.rotoLeft == 0 && tournament.etherLeft == 0);
      //  all the users stakes should have been resolved
       require(tournament.userStakes == tournament.stakesResolved);
       tournament.open = false;

       emit TournamentClosed(_tournamentID);
       return true;
    }
}