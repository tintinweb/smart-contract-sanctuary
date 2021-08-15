/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity 0.6.8;
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}*/

contract charity{
    address payable owner;
//    uint256 timenow;
    uint256 someval;
    uint256 somevalDai;

    uint256 oneWei = 1 wei;

    //IERC20 Dai = IERC20(address(0x3ac1c6ff50007ee705f36e40F7Dc6f393b1bc5e7));

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

    emit AddpersonEvent(_adr,_needval );

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
    require(Aperson[_adr].exists , "He/She Not Exist" );
    (payable(_adr)).transfer(Aperson[_adr].needval);
    emit WithdrawEvent(_adr, Aperson[_adr].needval);
    delete Aperson[_adr];
    delete persons[0];

    return _adr;
}

function RemoveFirstPersonViaOwner() external OnlyOwnerc returns(bool){
    delete Aperson[persons[0]];
    delete persons[0];

    // emit
    return true;
}

function RemoveAndWithdrawFirstPerson() external OnlyOwnerc returns(bool) {
    require(Aperson[persons[0]].exists , "He/She Not Exist" );
    (payable(persons[0])).transfer(Aperson[persons[0]].needval);
    emit WithdrawEvent(persons[0], Aperson[persons[0]].needval);
    delete Aperson[persons[0]];
    delete persons[0];

    //emit
    return true;   
}

function WithdrawToOwner() external OnlyOwnerc returns(address) {
    msg.sender.transfer(address(this).balance);
    //emit
    return msg.sender;
}
function EditInformationOfPerson(address _adr, string memory _name, uint256 _needval) public OnlyOwnerc returns(bool) {
    require(Aperson[_adr].exists , "He/She Not Exist" );

    Aperson[_adr] =  personX(_adr, _name, (_needval * oneWei) , true);
//    timenow = block.timestamp;

    emit AddpersonEvent(_adr,_needval );
    return true;
}


}