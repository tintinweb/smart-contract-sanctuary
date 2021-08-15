/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity 0.6.8;

contract charity{
    address payable owner;
    uint256 timenow;
    uint256 someval;

    uint256 oneWei = 1 wei;

struct personX{
    address adrs;
    string name_family;
    uint needval;
    bool exists;
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

modifier OnlyOwnerc(){
    require(owner == msg.sender);
    _;
}

function Addperson(address _adr, string memory _name, uint256 _needval ) public OnlyOwnerc returns(bool){
    require(!Aperson[_adr].exists , "He/She Exist" );
    Aperson[_adr] =  personX(_adr, _name, (_needval * oneWei) , true);
    persons.push(_adr);
//    timenow = block.timestamp;

    emit AddpersonEvent(msg.sender,_needval );

    return true;
}

function PayCharity() payable public returns (bool) {
    //require(msg.value >= _amount && _amount != 0 ,"You Haven't Enough in your Wallet");
    someval += msg.value;
    if( someval >= Aperson[persons[0]].needval ){
        Withdraw(persons[0]);
    }

    return true;
}

function Withdraw(address _adr) internal returns(address){
    (payable(_adr)).transfer(Aperson[_adr].needval);
    delete persons[0];
    delete Aperson[_adr];

    emit WithdrawEvent(_adr, Aperson[_adr].needval);

    return _adr;
}


}