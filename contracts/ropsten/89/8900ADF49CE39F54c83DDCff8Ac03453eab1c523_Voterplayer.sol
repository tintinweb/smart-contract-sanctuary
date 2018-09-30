pragma solidity ^0.4.24;

/**
 * @title -asbtc-voters v0.0.1
 * ┌┬┐┌─┐┌─┐┌┬┐   ╦╦ ╦╔═╗╔╦╗  ┌─┐┌─┐┌┐ ┌┬┐┌─┐
 *  │ ├┤ ├─┤│││   ║║ ║╚═╗ ║   ├─┤└─┐├┴┐ │ │
 *  ┴ └─┘┴ ┴┴ ┴  ╚╝╚═╝╚═╝ ╩   ┴ ┴└─┘└─┘ ┴ └─┘
 * ===========(0.0.1 test version)===========
 * 
 * ┌──────────────────────────────┐ ╔╦╗┬ ┬┌─┐┌┐┌┬┌─┌─┐  ╔╦╗┌─┐
 * │ rui chen,jiangnan cai        │  ║ ├─┤├─┤│││├┴┐└─┐   ║ │ │
 * │ jiaxin xu,xiaoling li        │  ╩ ┴ ┴┴ ┴┘└┘┴ ┴└─┘   ╩ └─┘
 * │ wang xin,yanglan xiong       └───────────────────────────┐
 * └──────────────────────────────────────────────────────────┘
 * 
 * ╔═╗┌─┐┌─┐┬┌─┐┬┌─┐┬   ┌─────────────────────────┐ ╦ ╦┌─┐┌┐ ╔═╗┬┌┬┐┌─┐ 
 * ║ ║├┤ ├┤ ││  │├─┤│   │ https://www.asbtc.com/  │ ║║║├┤ ├┴┐╚═╗│ │ ├┤  
 * ╚═╝└  └  ┴└─┘┴┴ ┴┴─┘ └─────────────────────────┘ ╚╩╝└─┘└─┘╚═╝┴ ┴ └─┘  
 * 
 * 
 * This is our first Dapp
 * I hope our team gets better and better
 * Thanks every one.
 * 
 * OK!Let&#39;s start the game.
 */
//****************
// Ownable contract 
//****************
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner,"Have no legal powerd");
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
//****************
//Factory contract 
//****************
contract VoterFactory is Ownable{
    using SafeMath for uint256; //uint256 library
    using SafeMath16 for uint16; //uint16 library
    mapping(address=>uint) total; //player total Voter
    mapping(address=>uint) balances;//player gamcoin 
    mapping(uint=>mapping(uint=>uint)) playervoter;//playerId->modelId->totalvoters
    mapping(address=>uint) playerpid;//address->playerpid
    mapping(uint=>address) playeraddr;//playerid->address
    mapping(address=>uint) playerTime;//address -> playersurplus Time
    
    event NewVoter(uint _id,string _name,uint _value,uint _vectoryvalue);// new model event
    event GiveVoter(address _fromaddress,uint _toid,uint _number);// voter event
    
    //model struct
    struct Voter{
        uint id;
        string name;
        uint value;
        uint vectoryvalue;
    }
    
    Voter[] public voters;
    uint public totalplayers;//total player
    uint16 public ids=0;//total model
    uint public fee = 1000000000000000;//gamcoin fee
    uint public createTime = now;//create Time
    uint public shutTime = 60 minutes;//shutdown time
    uint _pid=0;//player address to pid
}
//****************
//Impl contract 
//****************
contract VoterServiceImpl is VoterFactory{
    /**
     *@param _address playeraddress
     * new player pid and playerTime
     * totalplayers ++;
     */
    function _createPlayer(address _address) internal {
        playerpid[_address]= _pid;
        playeraddr[_pid] = _address;
        _pid=_pid.add(1);
        totalplayers=totalplayers.add(1);
        playerTime[msg.sender] = now;
    }
    function _getEarnings(address _address,uint _id) internal {
        uint  value = playervoter[playerpid[msg.sender]][_id];
        uint  modelvalue = voters[_id].vectoryvalue;
        uint  totalvalue = voters[_id].value;
        //uint  activevalue = value.div(totalvalue).mul(modelvalue);
        balances[_address]=balances[_address].add(value+modelvalue+totalvalue);
    }
    function _getplayersurplus() internal{
        /*uint nowTime = now;
        uint surplusTime = nowTime.sub(playerTime[msg.sender]);
        uint surplusvalue = total[msg.sender].div(balances[owner]);
        balances[owner]=balances[owner].sub(surplusTime.mul(surplusvalue).mul(100000));
        balances[msg.sender]=balances[msg.sender].add(surplusTime.mul(surplusvalue).mul(100000));*/
        playerTime[msg.sender]=now;
    }
    function _shutDown() internal{
        require(now>=(createTime+shutTime),"Not over yet");
        uint  vectoryId=0;
        /*for(uint i=0;i<ids;i++){
            if(voters[i].value>voters[vectoryId].value){
                vectoryId=i;
            }
        }
        for(uint j=0;j<ids;j++){
            voters[j].value=0;
        }
        for(uint k=0;k<totalplayers;k++){
            if(playervoter[k][vectoryId]!=0){
                _getEarnings(playeraddr[k],vectoryId);
            }
            total[playeraddr[k]]=0;
        }*/
        uint vectoryValue = balances[owner];
        voters[vectoryId].vectoryvalue+=vectoryValue;
        balances[owner]=0;
        createTime=now;
    }
    /**
     *@param _str model name
     * create new model voter
     * ids++
     */
    function _createVoter(string _str) internal onlyOwner{
        voters.push(Voter(ids,_str,0,0));
        ids=ids.add(1);
    }
}
//****************
//player contract 
//****************
contract Voterplayer is VoterServiceImpl{
    /**
     *@param _value Total number of votes
     *@param _id The model id
     * event GiveVoter
     */
    function giveToVoter(uint _value,uint _id) public {
        require(msg.sender!=owner,"owner Can&#39;t vote");
        require(balances[msg.sender]>=_value,"balances too low");
        balances[msg.sender]=balances[msg.sender].sub(_value);
        balances[owner]=balances[owner].add(_value);
        voters[_id].value=voters[_id].value.add(_value);
        total[msg.sender]=total[msg.sender].add(_value);
        playervoter[playerpid[msg.sender]][_id]=playervoter[playerpid[msg.sender]][_id].add(_value);
        emit GiveVoter(msg.sender,_id,_value);
    }
    /**
     *@param player address
     * Gets the number of player votes
     */
    function getTotalVoter(address _address) view public returns(uint totals){
        return total[_address];
    }
    /**
     *@param player address
     * Get the game coin balance
     */
    function balanceOf(address _address) view public returns(uint balance){
        return balances[_address];
    }
    /**
     *@param _number The number of game coin
     * buy the game coin 
     */
    function buyGameCoin(uint256 _number) public payable{
        if(playerpid[msg.sender]==0){
            _createPlayer(msg.sender);
        }
        uint256  coinfee = _number.mul(fee);
        require(msg.value==coinfee);
        balances[msg.sender]=balances[msg.sender].add(_number);
        fee=fee.add(_number.mul(100000000));
        owner.transfer(msg.value.div(100));
    }
    /**
     *@param _name The name of model
     * create model of this game 
     */
    function createVoter(string _name) public onlyOwner{
        _createVoter(_name);
        emit NewVoter(ids-1,_name,0,0);
    }
     /**
     *@param _time 
     * Set the end of the game
     */
    function setTime(uint _time) public onlyOwner{
        createTime=now;
        shutTime= _time;
    }
     /**
     *@param _name The name of model
     * create model of this game 
     */
    function setFee(uint _fee) public onlyOwner{
        fee=_fee;
    }
     /**
     *End the game and start a new round
     */
    function gameOver() public onlyOwner{
        _shutDown();
    }
     /**
     *Get all balances
     */
    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }
     /**
     *Obtain player&#39;s periodic benefits
     */
    function getplayersurplus() public {
        _getplayersurplus();
    }
}

//****************
//math library 
//****************
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a / b;
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}