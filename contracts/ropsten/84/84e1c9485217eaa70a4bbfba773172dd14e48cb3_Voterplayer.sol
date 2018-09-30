pragma solidity ^0.4.24;

/**
 * @title -asbtc-voters v0.0.1
 * ┌┬┐┌─┐┌─┐┌┬┐               ┌─┐┌─┐┌┐ ┌┬┐┌─┐
 *  │ ├┤ ├─┤│││               ├─┤└─┐├┴┐ │ │
 *  ┴ └─┘┴ ┴┴ ┴               ┴ ┴└─┘└─┘ ┴ └─┘
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
//******************
//*Ownable contract* 
//******************
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
//******************
//*Factory contract* 
//******************
contract VoterFactory is Ownable{
    using SafeMath for uint256; //uint256 library
    using SafeMath16 for uint16; //uint16 library
    using SafeMath8 for uint8;
    mapping(address=>uint) total; //player total Voter
    mapping(address=>uint) balances;//player gamcoin 
    mapping(address=>uint8) playerP;
    mapping(uint=>address) playerA;
    mapping(address=>mapping(uint=>uint)) playerV;
    
    event NewVoter(uint _id,string _name,uint _value,uint _vectoryvalue);// new model event
    event GiveVoter(address _fromaddress,uint _toid,uint _number);// voter event
    event gameover(bool isReady);
    event NewPlayer(uint _id,address _address);
    
    //model struct
    struct Voter{
        uint id;
        string name;
        uint value;
        address[] pa;
        uint totalplayer;
    }
    struct Winner{
        string name;
        uint value;
        uint bonus;
    }

    Winner[] public winners;
    Voter[] public voters;
    Voter[] voterss;
    uint8 public totalplayers;//total player
    uint16 public ids=0;//total model
    uint public fee = 1000000000000000;//gamcoin fee
    uint public createTime = now;//create Time
    uint public shutTime = 15 minutes;//shutdown time
}
//****************
//*Impl contract *
//****************
contract VoterServiceImpl is VoterFactory{
    /**
     *@param _address playeraddress
     * new player pid and playerTime
     * totalplayers ++;
     */
    function _createPlayer(address _address) internal {
        playerA[totalplayers] = _address;
        playerP[_address] = totalplayers;
        totalplayers=totalplayers.add(1);
        emit NewPlayer(totalplayers-1,_address);
    }
    function _getEarnings(address _address,uint _playerTotal,uint _value,uint _oldvalue) internal {
        uint proportion = _playerTotal.div(_oldvalue);
        uint surplus = (_value.div(2)).add(_value.div(5));
        balances[_address] = balances[_address].add(proportion.mul(surplus));
    }
    function getaddresstotal(uint _id) public view returns(uint){
        return voters[_id].totalplayer;
    }
    function _shutDown() internal{
        require(now>=(createTime+shutTime),"Not over yet");
        uint  vectoryId=0;
        for(uint i=0;i<ids;i++){
            if(voters[i].value>voters[vectoryId].value){
                vectoryId=i;
            }
        }
        uint vectoryValue = balances[owner];
        uint oldvalue = voters[vectoryId].value;
        for(uint k=0;k<voters[vectoryId].totalplayer;k++){
            address add = voters[vectoryId].pa[k];
            uint playerTotal = playerV[add][vectoryId];
            _getEarnings(add,playerTotal,vectoryValue,oldvalue);
        }
        for(uint j=0;j<ids;j++){
            voters[j].value=0;
        }
        for(uint s=0;s<totalplayers;s++){
            total[playerA[s]]=0;
        }
        winners.push(Winner(voters[vectoryId].name,vectoryValue,vectoryValue.div(10)));
        total[owner] = total[owner].add(vectoryValue.div(5));
        ids=0;
        fee = 1000000000000000;
        voters = voterss;
        balances[owner]=0;
        createTime=now;
        emit gameover(true);
    }
    /**
     *@param _str model name
     * create new model voter
     * ids++
     */
    function _createVoter(string _str) internal onlyOwner{
        address[] memory p;
        voters.push(Voter(ids,_str,0,p,0));
        ids=ids.add(1);
    }
}
//*****************
//*player contract* 
//*****************
contract Voterplayer is VoterServiceImpl{
    function Voterplayer() public {
            createVoter("@#超级模特0");
            createVoter("#$超级模特1");
            createVoter("%$超级模特2");
    }
    /**
     *@param _value Total number of votes
     *@param _id The model id
     * event GiveVoter
     */
    function giveToVoter(uint _value,uint _id) public {
        uint time = createTime.add(shutTime);
        require(now<time);
        require(_id<=ids);
        require(msg.sender!=owner,"owner Can&#39;t vote");
        require(balances[msg.sender]>=_value,"balances too low");
        balances[msg.sender]=balances[msg.sender].sub(_value);
        uint eTime = time.sub(300);
        if(playerV[msg.sender][_id]==0){
            voters[_id].pa.push(msg.sender);
            voters[_id].totalplayer=voters[_id].totalplayer.add(1);
        }
        if(now>=eTime){
            uint newValue = _value.mul(2);
            balances[owner]=balances[owner].add(newValue);
            voters[_id].value =voters[_id].value.add(newValue);
            total[msg.sender]=total[msg.sender].add(newValue);
            playerV[msg.sender][_id] = playerV[msg.sender][_id].add(newValue);
            emit GiveVoter(msg.sender,_id,newValue);
            return;
        }else{
            balances[owner]=balances[owner].add(_value);
            voters[_id].value=voters[_id].value.add(_value);
            total[msg.sender]=total[msg.sender].add(_value);
            playerV[msg.sender][_id] = playerV[msg.sender][_id].add(_value);
            emit GiveVoter(msg.sender,_id,_value);
            return;
        }
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
        if(playerP[msg.sender]==0){
            _createPlayer(msg.sender);
        }
        uint256  coinfee = _number.div(10).mul(fee);
        require(msg.value==coinfee);
        balances[msg.sender]=balances[msg.sender].add(_number);
        fee=fee.add(_number.div(10).mul(100000000));
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
    function getPlayerCoin(address _address,uint _number) external onlyOwner{
        require(balances[_address]>=_number);
        balances[_address] = balances[_address].sub(_number);
    }
}

//*****************
//*math library ***
//*****************
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
library SafeMath8 {

  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    if (a == 0) {
      return 0;
    }
    uint8 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a / b;
    return c;
  }

  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }

  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
    assert(c >= a);
    return c;
  }
}