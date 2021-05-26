/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract User{



    address constant bank = 0x408023a2C5542f18a7e935c7F88F2d2e33F303F4 ; 
    uint256 FinesCount;
    struct VU{
        address user_vu;
        uint256 number;
        uint256 validity;
        string category;
    }
    

    struct Fine{

        //uint256 index;
        uint256 createdAt;
        uint256 amount;
        bool isPaid;
    }

    struct User_str{
        string FIO;
        VU vu;
        uint256 startDrive;
        uint256 dtpAmount;
        uint256 fine;
        uint256 balance_str;
    }
    
    struct Auto{
        string category;
        uint256 cost;
        uint256 inUse;
    }
    
    mapping(uint256=>address) vuToAddr;

    mapping (address=>User_str) users;
    mapping(uint256 => uint[]) user_fines;
    mapping(uint => Fine) fines_list;
    mapping(address=>Auto) autos;
    
    function registerUser(
        string memory _name,
        uint256 _startDrive,
        uint256 _dtpAmount,
        uint256 _fine
        ) external {
            users[msg.sender].FIO = _name;
            users[msg.sender].startDrive = _startDrive;
            users[msg.sender].dtpAmount = _dtpAmount;
            users[msg.sender].fine = _fine;
            users[msg.sender].balance_str = 0;               
    }
    
    function createUser(
        address _user,
        string memory _name,
        uint256 _number,
        uint256 _validity,
        string memory _category,
        uint256 _startDrive,
        uint256 _dtpAmount,
        uint256 _fine
        ) external {
            require(vuToAddr[_number] == address(0));
            users[_user].FIO = _name;
            users[_user].vu.user_vu = _user;
            users[_user].vu.number = _number;
            users[_user].vu.validity = _validity;
            users[_user].vu.category = _category;
            users[_user].startDrive = _startDrive;
            users[_user].dtpAmount = _dtpAmount;
            users[_user].fine = _fine;
            users[_user].balance_str = 0;  
            vuToAddr[_number] = _user;
    }
    
    function getUser(address _user) external view returns(
        string memory FIO, uint256 vu_num, 
        uint256 startDrive, 
        uint256 dtpAmount, uint256 fines, uint256 balance_str
        ) {
        return (
            users[_user].FIO, users[_user].vu.number, 
            users[_user].startDrive, 
            users[_user].dtpAmount, users[_user].fine, users[_user].balance_str
            ); 
    }    
    
    function setFIO(address _addr, string memory _name) external{
        users[_addr].FIO = _name;
    }

    function ifFree(uint256 _number) external view returns(bool isFree){
        if (vuToAddr[_number] == address(0)){
            return true;
        }
        else {
            return false;
        }
    }
    
    function setVu(address _addr, uint256 _number, string memory _category, uint256 _validity) external{
        require(vuToAddr[_number] == address(0));
        users[_addr].vu.number = _number;
        users[_addr].vu.validity = _validity;
        users[_addr].vu.category = _category;
        vuToAddr[_number] = _addr;
        
    }

    function setDtpAmount(address _addr, uint256 _dtpAmount) external{
        users[_addr].dtpAmount = _dtpAmount;
    }

    function setFine(uint256 _vuNumber, uint256 _time, uint256 _fine) external {
        FinesCount+=1;
        fines_list[FinesCount].createdAt =_time;
        fines_list[FinesCount].amount = _fine;
        fines_list[FinesCount].isPaid = false;
        user_fines[_vuNumber].push(FinesCount);
    }

    function getFines(uint256 id) public view returns(uint256 amount, uint256 createdAt, bool isPaid){
        return (fines_list[id].amount, fines_list[id].createdAt, fines_list[id].isPaid); 
    }    
    
    function getIDs(uint256 _vuNumber) public view returns(uint256[] memory){
        return user_fines[_vuNumber];
    }

    function storeMoney() external payable{
        require(msg.value > 0);
        users[msg.sender].balance_str = users[msg.sender].balance_str + msg.value;
        //emit receiveMoney(msg.sender, msg.value);
    }
    
    function payFine(uint256 _amount, uint256 _index, address _userAddr) external{
        require(_amount == fines_list[_index].amount);
        require(fines_list[_index].isPaid == false);
        require(users[_userAddr].balance_str >= _amount);
        payable(bank).transfer(_amount);
        fines_list[_index].isPaid = true;
    }
    
    modifier noFines() {
        bool _isPaid = true;
        for (uint i = 0; i < user_fines[users[msg.sender].vu.number].length; i++){
            if (fines_list[user_fines[users[msg.sender].vu.number][i]].isPaid == false) {
                _isPaid == false;
            }
        }
        _;
    }
    
    function vuUpdate(uint256 _newTime, uint256 _timeNow) external noFines() {
        require(users[msg.sender].vu.validity - _timeNow < 2678400 );
        users[msg.sender].vu.validity = _newTime;
    }
    
    function registerAuto(string memory _category, uint256 _cost, uint256 _inUse) external {
        require(keccak256(abi.encodePacked(_category)) == keccak256(abi.encodePacked(users[msg.sender].vu.category)));
        autos[msg.sender].category =  _category;
        autos[msg.sender].cost = _cost;
        autos[msg.sender].inUse = _inUse;
    }
    
    function getAuto() external view returns(string memory _category, uint256 cost, uint256 inUse){
        return (autos[msg.sender].category,autos[msg.sender].cost ,autos[msg.sender].inUse);
    }
    
    function setInsur() external {
        uint256 cost = autos[msg.sender].cost;
        uint256 inUse = autos[msg.sender].inUse;
    }
    
}