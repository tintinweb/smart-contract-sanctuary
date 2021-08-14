/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

pragma solidity 0.6.8;

contract charity{
    address payable owner;
    uint256 timenow;
    uint256 someval;

struct personX{
    address payable adrs;
    string name_family;
    uint needval;
   // uint256 timetosave;
}
mapping (address => personX)Aperson;
//mapping (address => uint128)timetosave;
address[] persons;

event WithdrawEvent(address indexed adrsx, uint256 amount);
event AddpersonEvent(address indexed adrsadd, uint256 needval /*,uint128 timex*/);

//Aperson[] persons;
constructor() public {
    owner = msg.sender;
}

modifier onlyOwnerc(){
    require(owner == msg.sender);
    _;
}

function addperson(string memory _name, uint256 _needval ) public returns(bool){
    Aperson[msg.sender] =  personX(msg.sender, _name, _needval);
    persons.push(msg.sender);
    timenow = block.timestamp;

    emit AddpersonEvent(msg.sender,_needval );

    return true;
}

function payCharity(uint256 _amount) payable public returns (bool) {
    require(msg.value >= _amount && _amount != 0 ,"You Haven't Enough in your Wallet");
    someval += _amount;
    if( someval >= Aperson[persons[0]].needval ){
        Withdraw(persons[0]);
    }

    return true;
}

function Withdraw(address _adr) public payable returns(address){
    (payable(_adr)).transfer(Aperson[_adr].needval);
    emit WithdrawEvent(_adr, Aperson[_adr].needval);

    return _adr;
}


}