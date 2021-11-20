// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
/// @title EtherTrust
/// @author Nassim Dehouche
/// @notice This contract can create and execute wills in ethereum
/// @dev All function calls are currently implemented without side effects

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";


contract EtherTrust is Ownable, Pausable, ReentrancyGuard  {
/**
 * 
 *
 * `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */

event willCreated(address _testator, uint _index);
event willUpdated(address _testator, uint _index);
event willCancelled(address _testator, uint _index);
event willExecuted(address _testator, uint _index, address _beneficiary);
event logPayment(address _sender, address _receiver, uint _value);
event logFailedPayment(address _sender, address _receiver, uint _value);

event logAlive(address _testator);

modifier isNotZero(uint _value){
     require(_value>0); 
    _;   
    
}


modifier isTestator(address _caller) { 
    require(msg.sender==wills[msg.sender][0].testator); 
    _;
  }
modifier isBeneficiary(address _caller) { 
    require(msg.sender==wills[msg.sender][0].beneficiary); 
    _;
  }
  
modifier isMature(address _testator, uint _id){
     require(block.timestamp>lastAlive[_testator]+wills[_testator][_id].maturity); 
    _;   
    
}

modifier isValidUpdate(uint _newValue, uint _newReward) { 
    require(msg.sender==wills[msg.sender][0].testator); 
    _;
  }

 struct Will{ 
  uint value;
  uint reward;
  uint maturity;
  address payable testator;
  address payable beneficiary;
  }

mapping(address => Will[]) public wills;
mapping(address => uint) public lastAlive;
address[] public testators;
uint public numTestators;

receive() external payable { 
}

fallback() external payable {
require(msg.data.length == 0); 
emit logPayment(msg.sender, address(this), msg.value);
//Check data length in fallback functions
//Since the fallback functions is not only called for plain ether transfers (without data) but also when no other function matches, 
//you should check that the data is empty if the fallback function is intended to be used only for the purpose of logging received Ether. 
//Otherwise, callers will not notice if your contract is used incorrectly and functions that do not exist are called
}

  
function createWill(uint _reward, uint _maturity,  address payable _beneficiary) 
payable 
public  
isNotZero(msg.value)
whenNotPaused
returns (uint _id) {
require(_reward <= msg.value, "Insufficient funds sent.");    
emit logPayment(msg.sender, address(this), msg.value);

//check whether this is a new testator
if (lastAlive[msg.sender]==0){
testators.push(msg.sender);   
numTestators+=1;
}

//Update the testator's last sign of life
lastAlive[msg.sender]= block.timestamp;
emit logAlive(msg.sender);

_id= wills[msg.sender].length;
wills[msg.sender].push(Will({
value: msg.value-_reward, 
reward:_reward,
maturity: _maturity, 
testator: payable(msg.sender), 
beneficiary: _beneficiary
}));
}

function IAmAlive() 
public 
returns (bool _alive)
{
require(lastAlive[msg.sender]!=0);
emit logAlive(msg.sender);
_alive=true;
lastAlive[msg.sender]= block.timestamp;

}

function changeReward(uint _id, uint _decrease) 
payable
public 
isTestator(msg.sender)
returns (bool _updated)
{
    
lastAlive[msg.sender]= block.timestamp;
emit logAlive(msg.sender);
emit willUpdated(msg.sender, _id);
_updated=true;   

if (msg.value>0){
wills[msg.sender][_id].reward+=msg.value;   
emit logPayment(msg.sender, address(this), msg.value);
}
else if (_decrease>0 && _decrease< wills[msg.sender][_id].reward){
wills[msg.sender][_id].reward-=_decrease;
(bool sent, ) = msg.sender.call{value: _decrease}("");
        require(sent, "Failed to send Ether");
    emit logPayment(address(this), msg.sender, _decrease);
    
}
}

function changeValue(uint _id, uint _decrease) 
payable
public 
isTestator(msg.sender)
returns (bool _updated)
{
emit logAlive(msg.sender);
emit willUpdated(msg.sender, _id);
_updated=true;   

if (msg.value>0){
wills[msg.sender][_id].value+=msg.value;   
emit logPayment(msg.sender, address(this), msg.value);
}
else if (_decrease>0 && _decrease< wills[msg.sender][_id].value){
wills[msg.sender][_id].value-=_decrease;
(bool sent, ) = msg.sender.call{value: _decrease}("");
        require(sent, "Failed to send Ether");
    emit logPayment(address(this), msg.sender, _decrease);
    
}
}





function changeBeneficiary(uint _id, address payable _beneficiary) 
public 
isTestator(msg.sender)
returns (bool _updated)
{
require(wills[msg.sender][_id].beneficiary!=_beneficiary);
lastAlive[msg.sender]= block.timestamp;
emit logAlive(msg.sender);
wills[msg.sender][_id].beneficiary=_beneficiary;
emit willUpdated(msg.sender, _id);
_updated=true;    
}

function changeMaturity(uint _id, uint _maturity) 
public 
isTestator(msg.sender)
returns (bool _updated)
{
lastAlive[msg.sender]= block.timestamp;
emit logAlive(msg.sender);
wills[msg.sender][_id].maturity=_maturity;
emit willUpdated(msg.sender, _id);
_updated=true;    
}






function cancelWill(uint _id) 
public 
isTestator(msg.sender)
returns (bool _cancelled)
{
(bool sent, ) = msg.sender.call{value: wills[msg.sender][_id].value}("");
        require(sent, "Failed to send Ether");
    emit logPayment(address(this), msg.sender, wills[msg.sender][_id].value);
    
emit willCancelled(msg.sender, _id);
_cancelled=true;
wills[msg.sender][_id] = wills[msg.sender][wills[msg.sender].length - 1];
delete wills[msg.sender][wills[msg.sender].length - 1];
wills[msg.sender].pop();



}


function executeWill(address _testator, uint _id) 
public 
isMature(_testator,_id)
nonReentrant()
whenNotPaused
returns (bool _executed)
{
(bool sent1, ) = wills[_testator][_id].beneficiary.call{value: wills[_testator][_id].value}("");
        require(sent1, "Failed to send Ether");
    emit logPayment(address(this), wills[_testator][_id].beneficiary, wills[_testator][_id].value);
    
(bool sent2, ) = msg.sender.call{value: wills[_testator][_id].reward}("");
        require(sent2, "Failed to send Ether");
    emit logPayment(address(this), msg.sender, wills[_testator][_id].reward);

_executed=sent1&&sent2;
wills[_testator][_id] = wills[_testator][wills[_testator].length - 1];
delete wills[_testator][wills[_testator].length - 1];
wills[_testator].pop();    
}


function getWills(address _testator)  public  view  returns(Will[] memory ) {
      return wills[_testator];
}


//constructor() {
//owner = msg.sender; 
//emit OwnerSet(address(0), owner);



//modifier isOwner() {
//require(msg.sender == publisher, "Caller is not owner");
//_;
//}


//function togglePause() isOwnerr public {
//    pause = !pause;
//}

//modifier onlyIfNotPaused { if (!pause) _; }
//modifier onlyIfPaused { if (paused) _; }


}