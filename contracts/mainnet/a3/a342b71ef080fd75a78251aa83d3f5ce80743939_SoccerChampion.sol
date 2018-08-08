pragma solidity ^0.4.18;

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

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

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract QIUToken is StandardToken,Ownable {
    string public name = &#39;QIUToken&#39;;
    string public symbol = &#39;QIU&#39;;
    uint8 public decimals = 0;
    uint public INITIAL_SUPPLY = 5000000000;
    uint public eth2qiuRate = 10000;

    function() public payable { } // make this contract to receive ethers

    function QIUToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY / 10;
        balances[this] = INITIAL_SUPPLY - balances[owner];
    }

    function getOwner() public view returns (address) {
        return owner;
    }  
    
    /**
    * @dev Transfer tokens from one address to another, only owner can do this super-user operate
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function ownerTransferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(tx.origin == owner); // only the owner can call the method.
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

      /**
    * @dev transfer token for a specified address,but different from transfer is replace msg.sender with tx.origin
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function originTransfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[tx.origin]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[tx.origin] = balances[tx.origin].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(tx.origin, _to, _value);
        return true;
    }

    event ExchangeForETH(address fromAddr,address to,uint qiuAmount,uint ethAmount);
    function exchangeForETH(uint qiuAmount) public returns (bool){
        uint ethAmount = qiuAmount * 1000000000000000000 / eth2qiuRate; // only accept multiple of 100
        require(this.balance >= ethAmount);
        balances[this] = balances[this].add(qiuAmount);
        balances[msg.sender] = balances[msg.sender].sub(qiuAmount);
        msg.sender.transfer(ethAmount);
        ExchangeForETH(this,msg.sender,qiuAmount,ethAmount);
        return true;
    }

    event ExchangeForQIU(address fromAddr,address to,uint qiuAmount,uint ethAmount);
    function exchangeForQIU() payable public returns (bool){
        uint qiuAmount = msg.value * eth2qiuRate / 1000000000000000000;
        require(qiuAmount <= balances[this]);
        balances[this] = balances[this].sub(qiuAmount);
        balances[msg.sender] = balances[msg.sender].add(qiuAmount);
        ExchangeForQIU(this,msg.sender,qiuAmount,msg.value);
        return true;
    }

    /*
    // transfer out method
    function ownerETHCashout(address account) public onlyOwner {
        account.transfer(this.balance);
    }*/
    function getETHBalance() public view returns (uint) {
        return this.balance; // balance is "inherited" from the address type
    }
}

contract SoccerChampion is Ownable {
    using SafeMath for uint256;
    
    struct Tournament {
        uint id;
        bool isEnded;
        bool isLockedForSupport;
        bool initialized;
        Team[] teams;
        SupportTicket[] tickets;
    }
    
    struct Team {
        uint id;
        bool isKnockout;
        bool isChampion;
    }

    struct SupportTicket {
        uint teamId;
        address supportAddres;
        uint supportAmount;
    }

    //ufixed private serviceChargeRate = 1/100;
    mapping (uint => Tournament) public tournaments;
    uint private _nextTournamentId = 0;
    QIUToken public _internalToken;
    uint private _commissionNumber;
    uint private _commissionScale;
    
    function SoccerChampion(QIUToken _tokenAddress) public {
        _nextTournamentId = 0;
        _internalToken = _tokenAddress;
        _commissionNumber = 2;
        _commissionScale = 100;
    }

    function modifyCommission(uint number,uint scale) public onlyOwner returns(bool){
        _commissionNumber = number;
        _commissionScale = scale;
        return true;
    }

    event NewTouramentCreateSuccess(uint newTourId);
    function createNewTourament(uint[] teamIds) public onlyOwner{
        uint newTourId = _nextTournamentId;
        tournaments[newTourId].id = newTourId;
        tournaments[newTourId].isEnded = false;
        tournaments[newTourId].isLockedForSupport = false;
        tournaments[newTourId].initialized = true;
        for(uint idx = 0; idx < teamIds.length; idx ++){
            Team memory team;
            team.id = teamIds[idx];
            team.isChampion = false;
            tournaments[newTourId].teams.push(team);
        }
        _nextTournamentId ++;   
        NewTouramentCreateSuccess(newTourId);
    }

    function supportTeam(uint tournamentId, uint teamId, uint amount) public {
        require(tournaments[tournamentId].initialized);
        require(_internalToken.balanceOf(msg.sender) >= amount);
        require(!tournaments[tournamentId].isEnded);
        require(!tournaments[tournamentId].isLockedForSupport);
        require(amount > 0);
        SupportTicket memory ticket;
        ticket.teamId = teamId;
        ticket.supportAddres = msg.sender;
        ticket.supportAmount = amount;
        _internalToken.originTransfer(this, amount);
        tournaments[tournamentId].tickets.push(ticket);
    }

    function _getTournamentSupportAmount(uint tournamentId) public view returns(uint){
        uint supportAmount = 0;
        for(uint idx = 0; idx < tournaments[tournamentId].tickets.length; idx++){
            supportAmount = supportAmount.add(tournaments[tournamentId].tickets[idx].supportAmount);
        }
        return supportAmount;
    }

    function _getTeamSupportAmount(uint tournamentId, uint teamId) public view returns(uint){
        uint supportAmount = 0;
        for(uint idx = 0; idx < tournaments[tournamentId].tickets.length; idx++){
            if(tournaments[tournamentId].tickets[idx].teamId == teamId){
                supportAmount = supportAmount.add(tournaments[tournamentId].tickets[idx].supportAmount);
            }
        }
        return supportAmount;
    }

    function _getUserSupportForTeamInTournament(uint tournamentId, uint teamId) public view returns(uint){
        uint supportAmount = 0;
        for(uint idx = 0; idx < tournaments[tournamentId].tickets.length; idx++){
            if(tournaments[tournamentId].tickets[idx].teamId == teamId && tournaments[tournamentId].tickets[idx].supportAddres == msg.sender){
                supportAmount = supportAmount.add(tournaments[tournamentId].tickets[idx].supportAmount);
            }
        }
        return supportAmount;
    }


    function getTeamlistSupportInTournament(uint tournamentId) public view returns(uint[] teamIds, uint[] supportAmounts, bool[] knockOuts, uint championTeamId, bool isEnded, bool isLocked){  
        if(tournaments[tournamentId].initialized){
            teamIds = new uint[](tournaments[tournamentId].teams.length);
            supportAmounts = new uint[](tournaments[tournamentId].teams.length);
            knockOuts = new bool[](tournaments[tournamentId].teams.length);
            championTeamId = 0;
            for(uint tidx = 0; tidx < tournaments[tournamentId].teams.length; tidx++){
                teamIds[tidx] = tournaments[tournamentId].teams[tidx].id;
                if(tournaments[tournamentId].teams[tidx].isChampion){
                    championTeamId = teamIds[tidx];
                }
                knockOuts[tidx] = tournaments[tournamentId].teams[tidx].isKnockout;
                supportAmounts[tidx] = _getTeamSupportAmount(tournamentId, teamIds[tidx]);
            }
            isEnded = tournaments[tournamentId].isEnded;
            isLocked = tournaments[tournamentId].isLockedForSupport;
        }
    }

    function getUserSupportInTournament(uint tournamentId) public view returns(uint[] teamIds, uint[] supportAmounts){
        if(tournaments[tournamentId].initialized){
            teamIds = new uint[](tournaments[tournamentId].teams.length);
            supportAmounts = new uint[](tournaments[tournamentId].teams.length);
            for(uint tidx = 0; tidx < tournaments[tournamentId].teams.length; tidx++){
                teamIds[tidx] = tournaments[tournamentId].teams[tidx].id;
                uint userSupportAmount = _getUserSupportForTeamInTournament(tournamentId, teamIds[tidx]);
                supportAmounts[tidx] = userSupportAmount;
            }
        }
    }


    function getUserWinInTournament(uint tournamentId) public view returns(bool isEnded, uint winAmount){
        if(tournaments[tournamentId].initialized){
            isEnded = tournaments[tournamentId].isEnded;
            if(isEnded){
                for(uint tidx = 0; tidx < tournaments[tournamentId].teams.length; tidx++){
                    Team memory team = tournaments[tournamentId].teams[tidx];
                    if(team.isChampion){
                        uint tournamentSupportAmount = _getTournamentSupportAmount(tournamentId);
                        uint teamSupportAmount = _getTeamSupportAmount(tournamentId, team.id);
                        uint userSupportAmount = _getUserSupportForTeamInTournament(tournamentId, team.id);
                        uint gainAmount = (userSupportAmount.mul(tournamentSupportAmount)).div(teamSupportAmount);
                        winAmount = (gainAmount.mul(_commissionScale.sub(_commissionNumber))).div(_commissionScale);
                    }
                }
            }else{
                winAmount = 0;
            }
        }
    }

    function knockoutTeam(uint tournamentId, uint teamId) public onlyOwner{
        require(tournaments[tournamentId].initialized);
        require(!tournaments[tournamentId].isEnded);
        for(uint tidx = 0; tidx < tournaments[tournamentId].teams.length; tidx++){
            Team storage team = tournaments[tournamentId].teams[tidx];
            if(team.id == teamId){
                team.isKnockout = true;
            }
        }
    }

    event endTournamentSuccess(uint tourId);
    function endTournament(uint tournamentId, uint championTeamId) public onlyOwner{
        require(tournaments[tournamentId].initialized);
        require(!tournaments[tournamentId].isEnded);
        tournaments[tournamentId].isEnded = true;
        uint tournamentSupportAmount = _getTournamentSupportAmount(tournaments[tournamentId].id);
        uint teamSupportAmount = _getTeamSupportAmount(tournaments[tournamentId].id, championTeamId);
        uint totalClearAmount = 0;
        for(uint tidx = 0; tidx < tournaments[tournamentId].teams.length; tidx++){
            Team storage team = tournaments[tournamentId].teams[tidx];
            if(team.id == championTeamId){
                team.isChampion = true;
                break;
            }
        }

        for(uint idx = 0 ; idx < tournaments[tournamentId].tickets.length; idx++){
            SupportTicket memory ticket = tournaments[tournamentId].tickets[idx];
            if(ticket.teamId == championTeamId){
                if(teamSupportAmount != 0){
                    uint gainAmount = (ticket.supportAmount.mul(tournamentSupportAmount)).div(teamSupportAmount);
                    uint actualGainAmount = (gainAmount.mul(_commissionScale.sub(_commissionNumber))).div(_commissionScale);
                    _internalToken.ownerTransferFrom(this, ticket.supportAddres, actualGainAmount);
                    totalClearAmount = totalClearAmount.add(actualGainAmount);
                }
            }
        }
        _internalToken.ownerTransferFrom(this, owner, tournamentSupportAmount.sub(totalClearAmount));
        endTournamentSuccess(tournamentId);
    }

    event lockTournamentSuccess(uint tourId, bool isLock);
    function lockTournament(uint tournamentId, bool isLock) public onlyOwner{
        require(tournaments[tournamentId].initialized);
        require(!tournaments[tournamentId].isEnded);
        tournaments[tournamentId].isLockedForSupport = isLock;
        lockTournamentSuccess(tournamentId, isLock);
    }
}