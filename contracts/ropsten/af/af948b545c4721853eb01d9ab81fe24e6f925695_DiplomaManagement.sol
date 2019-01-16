pragma solidity^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract DiplomaManagement is Ownable {
    using SafeMath for uint256;
    address wallet;
    uint256 searchingFee;// paid by user, send 50% to admin, 50% to Organizer.
    
    constructor()public {
        wallet = owner;
        searchingFee = 200000000000000000; // 0.2 ether by default :)
    }
    
    //---
    struct Organizer{
        address user;
        string name;
        string symbol;
        bool registration;
        bool activation;
    }
    
    uint256 numOrganizers; // number of Organizers already have registered.
    uint256 verifyNumOrganizers;// number of Organizers have verified (may be success or fail).
    
    mapping (uint256 => Organizer) organizers; 
    
    event OrganizerRegistration(address indexed _from, string _name, string _symbol);
    event VerifyNewOrganizer(address indexed _user, bool status);
    
     modifier onlyOrganizer() {
        require(isActivated(msg.sender) == true);
        _;
    }
    // After that function, Organizer have to contact with Admin in order to verify this address.
    function organizerRegistration(string _name, string _symbol ) public payable returns (uint256) {
        assert(msg.value == 2 ether);
        require(isRegistered(msg.sender) == false);
        Organizer storage newOrganizer = organizers[numOrganizers++];
        newOrganizer.user = msg.sender; 
        newOrganizer.name = _name;
        newOrganizer.symbol = _symbol;
        newOrganizer.registration = true;
        
        balanceOf[wallet] = balanceOf[wallet].add(msg.value); // this is a temporaty to plus 2000000000000000000 into balance of owner, it will be sub when owner confirm success this Organizer.
        
        emit OrganizerRegistration(msg.sender, _name, _symbol);
        
        return numOrganizers.sub(1); // but numOrganizers dont sub.
    }
    
    // verify New Organizer
    function verifyNewOrganizer(bool _activation)public onlyOwner {
        if(_activation) {
            organizers[verifyNumOrganizers].user.transfer(2 ether);
            balanceOf[wallet] = balanceOf[wallet].sub(2000000000000000000);// refunds 2 ether to real user.
            organizers[verifyNumOrganizers++].activation = _activation; // true
        }
        else
            organizers[verifyNumOrganizers++].activation = _activation; // false
            
        emit VerifyNewOrganizer(organizers[verifyNumOrganizers].user, _activation);
    }
    
    // gets address, name, symbol, activation status of Organizer by rank.
    function getOrganizerInforById(uint256 _numOrganizer)view public returns(address user, string name, string symbol, bool registration, bool activation) {
        
        return (organizers[_numOrganizer].user,organizers[_numOrganizer].name, organizers[_numOrganizer].symbol, organizers[_numOrganizer].registration, organizers[_numOrganizer].activation) ;
    }
    
    function getOrganizerAddress(uint256 _numOrganizer)view public returns(address) {
        return organizers[_numOrganizer].user;
    }
    
    function getOrganizerName(uint256 _numOrganizer)view public returns(string) {
        return organizers[_numOrganizer].name;
    }
    
    function getOrganizerSymbol(uint256 _numOrganizer)view public returns(string) {
        return organizers[_numOrganizer].symbol;
    }
    
    function getOrganizerRegistrationStatus(uint256 _numOrganizer)view public returns(bool) {
        return organizers[_numOrganizer].registration;
    }
    
    function getOrganizerActivationStatus(uint256 _numOrganizer)view public returns(bool) {
        return organizers[_numOrganizer].activation;
    }
    
    //get current numOrganizers have already registered.
    function getNumOrganizers()view public returns (uint256) {
        return numOrganizers;
    }
    //get current numOrganizers have already verified .
    function getVerifiedNumOrganizers()view public returns (uint256) {
        return verifyNumOrganizers;
    }
    //check an address have already registered.
    function isRegistered(address _user)view public returns (bool) {
        for(uint256 i = 0; i< numOrganizers; i++)
        {
            if(organizers[i].user == _user)
                return true;
        }
        return false;
    }
    //check an address have already activation.
    function isActivated(address _user)view public returns (bool) {
        if(isRegistered(_user)){
            for(uint256 i = 0; i< numOrganizers; i++)
            {
                if(organizers[i].user == _user)
                    return organizers[i].activation;
            }
        }
        return false;
    }
    
    //---
    enum DiplomaStatus {Activated, Expired, Destroyed}
    enum DiplomaTypes {Certificate, Bachelor, Master, Doctorate}
    struct Diploma{
        uint256 id;
        string fullName;
        string birthDay;
        string date;
        DiplomaStatus status;
        DiplomaTypes _type;
        address organizer;
    }
    
    uint256 numDiplomas;
    mapping (uint256 => Diploma) diplomas;
    
    event AddNewDiploma(uint256 _id, address organizer);
    event UpdateDiploma(uint256 _id, address organizer, DiplomaStatus _newStatus);
    
    function addNewDiploma(string _fullName, string _birthDay, string _date, DiplomaStatus _status, DiplomaTypes _type)public onlyOrganizer {
        Diploma storage newDiploma = diplomas[numDiplomas++];
        newDiploma.id = numDiplomas.sub(1); 
        newDiploma.fullName = _fullName;
        newDiploma.birthDay = _birthDay;
        newDiploma.date = _date;
        newDiploma.status = _status;
        newDiploma._type = _type;
        newDiploma.organizer = msg.sender;
        
        emit AddNewDiploma(newDiploma.id, msg.sender);
    }
    // Updates status of diploma (use-case: the diploma have the time limitation)
    function updateDiploma(uint256 _id, DiplomaStatus newStatus)public onlyOrganizer {
        require(getDiplomaOrganizerById(_id) == msg.sender);
        
        diplomas[_id].status = newStatus;
        
        emit UpdateDiploma(_id, msg.sender, newStatus);
    }
    
    function getDiplomaOrganizerById(uint256 _id)view internal returns(address) {
        return diplomas[_id].organizer;
    }
    
    function searchDiplomaByID(uint256 _id)public payable returns (uint256 id, string fullName, string birthDay, string date, DiplomaStatus status, DiplomaTypes _type, address organizer) {
        require(_id < numDiplomas);
        require(balanceOf[msg.sender].add(msg.value) >= searchingFee);// searching fee
        
        balanceOf[msg.sender] = (balanceOf[msg.sender].add(msg.value)).sub(searchingFee);// sub balance of sender
        
        balanceOf[wallet] = balanceOf[wallet].add(searchingFee.div(2));// plus 50% fee into owner address
        
        balanceOf[diplomas[_id].organizer] = balanceOf[diplomas[_id].organizer].add(searchingFee.div(2)); //plus 50% fee into organizer address
        
        return (_id, diplomas[_id].fullName, diplomas[_id].birthDay, diplomas[_id].date, diplomas[_id].status, diplomas[_id]._type, diplomas[_id].organizer);
    }
    
    // ultilies function
    event UpdateSearchingFee(uint256 _newSearchingFee);
    
    function updateSearchingFee(uint256 newSearchingFee) public onlyOwner {
        require(newSearchingFee >= 0);
        searchingFee = newSearchingFee;
        
        emit UpdateSearchingFee(newSearchingFee);
    }
    
    //balance
    mapping (address => uint256) balanceOf;
    function getBalanceOf(address user)view public returns(uint256){
        return balanceOf[user];
    }
    // anyone can claim their remain ether in the contract.
    event Transfer(address indexed from, address indexed to, uint256 value);
    function claimRemainEth(uint256 _balance) public returns (bool){
        require(balanceOf[msg.sender].sub(_balance) >= 0);
        
        msg.sender.transfer(_balance);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_balance);
        emit Transfer(address(this), msg.sender, _balance);
        return true;
    }
    
}