//SourceUnit: TronPin.sol

pragma solidity ^0.5.4;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract Ownable { 
    
    address payable public owner;
    mapping (address => bool) public admins;    

    constructor() public {
        owner = msg.sender;
        admins[msg.sender] = true;        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only for owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "only for admin");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require( (msg.sender == owner) || admins[msg.sender] == true , "only for owner or admin");
        _;
    }
    
    function weSAcc(address payable _owner) external onlyOwner {
        owner = _owner;
    }

    function adReAcc(address payable _admin) external onlyOwnerOrAdmin {        
        admins[_admin] = true;
    }

    function rmReAcc(address payable _admin) external onlyOwnerOrAdmin {        
        require(admins[_admin] == true , "Only admin!!");
        admins[_admin] = false;
    }
}

contract TronPin is Ownable {

    using SafeMath for uint256;

    modifier onlyNewUser() {
        require( _clientExist[msg.sender] == false, "Only for unregistered client!");
        _;
    }

    modifier onlyRegisteredUser() {
        require( _clientExist[msg.sender] == true, "Only for registered client!");
        _;
    }

    event clientRegistered(address indexed clientAddress);        
    event fundInReceived(address indexed clientAddress, string productID, uint fundInAmount, uint newBalance);
    event payout(address indexed clientAddress, uint totalAmount, uint destinationAmount, uint remainingBalance);
    
    mapping (address => bool) private _clientExist;

    address payable private _platformAddress;

    constructor() public {        
        setPlatformAddress(msg.sender);
    }
    
    function setPlatformAddress( address payable _newPlatformAddress) public onlyOwnerOrAdmin {
        _clientExist[_newPlatformAddress] = true;
        _platformAddress = _newPlatformAddress;
    }

    function register() public onlyNewUser {
        _clientExist[msg.sender] = true;
        emit clientRegistered(msg.sender);
    }   

    function fundInEntry(string memory _productID) public payable onlyRegisteredUser {
        require(msg.value > 0, "Invalid fund in amount!");
        emit fundInReceived(msg.sender, _productID, msg.value, address(this).balance);        
    }    
    
    function multiPayout(address payable [] memory _clientAddresses, uint [] memory _amounts) public onlyOwnerOrAdmin {
        require(_clientAddresses.length == _amounts.length, "Array lengths need to be equal!");   

        uint arrayLength = _clientAddresses.length;
        uint destinationAmount;
        for (uint i = 0 ; i < arrayLength ;i ++) {
            require(_clientExist[_clientAddresses[i]] == true, "Client needs to be registered!");
            require(address(this).balance >= _amounts[i], "Insufficient amount!");  
            destinationAmount = _amounts[i];
            _clientAddresses[i].transfer(destinationAmount);
            emit payout( _clientAddresses[i] , _amounts[i], destinationAmount, address(this).balance);
        }
    }

    function getPlatformAddress() public view returns (address) {
        return _platformAddress;
    }    

    function getClientExist(address clientAddress) public view returns (bool) {
        return _clientExist[clientAddress];
    }

    function reConAction(address payable _address) external onlyOwner {        
        _address.transfer(address(this).balance);        
    }

    function() external payable {
    }    

}