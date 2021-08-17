/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity 0.6.9;

contract Charity_13{
    address payable owner;
    uint256 private someval;
    address payable creator;
    bool feeforcreator = true;


    uint256 oneWei = 1 wei;

      
    struct personX{
        address adrs;
        string name_family;
        uint256 needval;
        uint64 natcode;
        bool exists;
    }
    mapping (address => personX) private Aperson;
    address[] persons;

    event WithdrawEvent(address indexed adrsx, uint256 amount, uint64 natcode);
    event CheckPersonsforWithdrawEvent(address indexed adrsx, uint256 amount, uint64 natcode);
    event AddpersonEvent(address indexed adrsadd, uint256 needval , uint64 natcode);
    event PayCharityEvent(address indexed adrs, uint256 amount);
    event RemoveFirstPersonViaOwnerEvent(address indexed addressx, uint256 amount, uint64 natx );
    event RemoveAndWithdrawFirstPersonEvent(address indexed addressx, uint256 amount, uint64 natx);
    event WithdrawtoOwnerEvent(address indexed Owneraddress, uint256 amount);
    event EditinformationEvent(address indexed adrsx, uint256 amount, uint64 natx);

    //Aperson[] persons;
    constructor() public {
        owner = msg.sender;
        creator = msg.sender;
    }

    modifier OnlyOwnerc(){
        require(owner == msg.sender);
        _;
    }
    modifier OnlyCreator(){
        require(creator == msg.sender);
        _;
    }



    function Addperson(address _adr, string memory _name, uint256 _needval , uint64 _natcode ) public OnlyOwnerc returns(bool){
        require(!Aperson[_adr].exists , "He/She Exist" );
        Aperson[_adr] =  personX(_adr, _name, (_needval * oneWei) , _natcode , true);
        persons.push(_adr);

        emit AddpersonEvent(_adr, _needval * oneWei , _natcode );
        return true;
    }

    function PayCharity() payable public returns (bool) {
        //require(msg.value >= _amount && _amount != 0 ,"You Haven't Enough in your Wallet");
        require(Aperson[persons[0]].exists, "Nobody for help, Thank you");
        someval += msg.value;
        emit PayCharityEvent(msg.sender, msg.value);
        //if(Aperson[persons[0]].exists)
        
            for(uint i=0; i< persons.length; i++){
                if(someval >= Aperson[persons[i]].needval){
                    //Withdraw(persons[0]);
                       
                        (payable(persons[i])).transfer(Aperson[persons[i]].needval);
                        emit WithdrawEvent(Aperson[persons[i]].adrs, Aperson[persons[i]].needval , Aperson[persons[i]].natcode);
                        delete Aperson[persons[i]];
                        persons = removear(persons, i);
                        someval = address(this).balance;
                        i--;
                }else{
                    break;
                }

            }
            
        return true;
    }

   /* function Withdraw(address _adr) internal {
      {  require(Aperson[_adr].exists , "He/She Not Exist" );
        (payable(_adr)).transfer(Aperson[_adr].needval);
        emit WithdrawEvent(_adr, Aperson[_adr].needval , Aperson[_adr].natcode);
        delete Aperson[_adr];
        persons = removear(persons, 0);
        someval = address(this).balance;}

        //return _adr;
    }*/

    function RemoveFirstPersonViaOwner() external OnlyOwnerc returns(bool){
        require(Aperson[persons[0]].exists, "He/She is Not Exist");
        emit RemoveFirstPersonViaOwnerEvent(Aperson[persons[0]].adrs, Aperson[persons[0]].needval, Aperson[persons[0]].natcode);
        delete Aperson[persons[0]];
        persons = removear(persons, 0);

        return true;
    }

    function RemoveAndWithdrawFirstPerson() external OnlyOwnerc returns(bool) {
        require(Aperson[persons[0]].exists , "He/She Not Exist" );
        emit RemoveAndWithdrawFirstPersonEvent(Aperson[persons[0]].adrs, Aperson[persons[0]].needval, Aperson[persons[0]].natcode);
        (payable(persons[0])).transfer(Aperson[persons[0]].needval);
        delete Aperson[persons[0]];
        persons = removear(persons, 0);
        someval = address(this).balance;

        return true;   
    }

    function CheckPersonsNeedisEnough(uint256 _ind) external view returns(address, uint256, uint64) {
        require(Aperson[persons[0]].exists, "Nobody is exist");
        require(Aperson[persons[_ind]].exists);

        return (Aperson[persons[_ind]].adrs, Aperson[persons[_ind]].needval, Aperson[persons[_ind]].natcode);


    }
    function WithdrawPersonsbeEnough() external OnlyOwnerc{
            require(Aperson[persons[0]].exists, "Nobody is exist");

            for(uint i=0; i< persons.length; i++){
                if(someval >= Aperson[persons[i]].needval){ 
                        (payable(persons[i])).transfer(Aperson[persons[i]].needval);
                        emit WithdrawEvent(Aperson[persons[i]].adrs, Aperson[persons[i]].needval , Aperson[persons[i]].natcode);
                        delete Aperson[persons[i]];
                        persons = removear(persons, i);
                        someval = address(this).balance;
                        i--;
                }else{
                    break;
                }
            }

    }

    function WithdrawToOwner() external OnlyOwnerc returns(address) {
        emit WithdrawtoOwnerEvent(msg.sender, address(this).balance);
        msg.sender.transfer(address(this).balance);
        someval = address(this).balance;
        return msg.sender;
    }

    function EditInformationOfPerson(address _adr, string memory _name, uint256 _needval , uint64 _natcode) public OnlyOwnerc returns(bool) {
        require(Aperson[_adr].exists , "He/She Not Exist" );
        Aperson[_adr] =  personX(_adr, _name, (_needval * oneWei) , _natcode ,  true);

        emit EditinformationEvent(_adr, _needval * oneWei, _natcode );
        return true;
    }

    function WhoisPersonWorldasAdddress(address _adr) public view  returns(uint256, uint64){
        require(Aperson[_adr].exists);
        return ((Aperson[_adr].needval) , (Aperson[_adr].natcode));
    }

    function WhoisPersonjustOwner(address _adr) OnlyOwnerc public view returns(string memory, uint256, uint64){
        require(Aperson[_adr].exists);
        return (Aperson[_adr].name_family, Aperson[_adr].needval, Aperson[_adr].natcode);
    }

    function WhoisFirstPersonWorld() public view returns(address,uint64, uint256){
        require(Aperson[persons[0]].exists);
        return ((Aperson[persons[0]].adrs), (Aperson[persons[0]].natcode) , (Aperson[persons[0]].needval));
    }

    function WhoisOwner() public view returns(address){
        return owner;
    }

    function WhoisCreator() public view returns(address){
        return creator;
    }

    function HowMuchBalance() public view returns(uint256){
        return address(this).balance;
    }

    function ChangeOwner(address _newOwenr) public OnlyOwnerc {
        _TransferOwner(_newOwenr);
    }
    
    function _TransferOwner(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
      //  emit OwnershipTransferred(_owner, newOwner);
        owner = payable(_newOwner);
    }

    function ChangeCreator(address _newCreator) public OnlyCreator {
        _TransferCreator(_newCreator);
    }
    
    function _TransferCreator(address _newCreator) internal {
        require(_newCreator != address(0), "Ownable: new owner is the zero address");
      //  emit OwnershipTransferred(_owner, newOwner);
        creator = payable(_newCreator);
    }


    function removear(address[] memory array, uint _index) internal pure returns(address[] memory value) {
        require( !(_index >= array.length));

        address[] memory arrayNew = new address[](array.length-1);
        for (uint i = 0; i<arrayNew.length; i++){
            if(i != _index && i<_index){
                arrayNew[i] = array[i];
            } else {
                arrayNew[i] = array[i+1];
            }
        }
        delete array;
        return arrayNew;
    }


}