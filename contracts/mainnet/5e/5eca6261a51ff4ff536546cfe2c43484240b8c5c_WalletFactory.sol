pragma solidity ^0.4.21;
contract Admin {
    address public admin;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function transferAdminship(address newAdmin) public onlyAdmin {
        if (newAdmin != address(0)) {
            admin = newAdmin;
        }
    }
}
contract Pausable is Admin {

    bool public paused = false;


    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev called by the admin to pause, triggers stopped state
     */
    function pause() public onlyAdmin whenNotPaused returns(bool) {
        paused = true;
        return true;
    }

    /**
     * @dev called by the admin to unpause, returns to normal state
     */
    function unpause() public onlyAdmin whenPaused returns(bool) {
        paused = false;
        return true;
    }
}

contract Wallet is Pausable {
    event DepositWallet(address _depositBy, uint256 _amount);
    event Withdraw(uint256 _amount);
    event Transfer(address _to,uint256 _amount);
    
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAdminOrOwner() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }
    constructor(address _admin,address _who) public {
        require(_admin != address(0));
        admin = _admin;
        owner = _who;
    }
    
    // admin can set anyone as owner, even empty
    function setOwner(address _who) external onlyAdmin {
        owner = _who;
    }
    
    function deposit() public payable{
        emit DepositWallet(msg.sender,msg.value);
    }
    
    function() public payable{
        emit DepositWallet(msg.sender,msg.value);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function transfer(address _to,uint256 _amount) external onlyOwner whenNotPaused{
        require(address(this).balance>=_amount);
        require(_to!=address(0));
        if (_amount>0){
            _to.transfer(_amount);
        }
        emit Transfer(_to,_amount);
    }
    
    function withdraw() public onlyOwner whenNotPaused{
        require(owner!=address(0));
        uint256 _val = address(this).balance;
        if (_val>0){
            owner.transfer(_val);
        }
        emit Withdraw(_val);
    }
}

contract WalletFactory {
    event WalletCreated(address admin,address owner, address wallet);
    mapping(address => address[]) public wallets;
    address public factoryOwner;
    
    constructor() public{
        factoryOwner = msg.sender;
    }
    // you can donate to me
    function createWallet(address _admin,address _owner) public payable{
        // you can create max 10 wallets for free
        if (wallets[msg.sender].length>10){
            require(msg.value>=0.01 ether);
        }
        Wallet w = new Wallet(_admin,_owner);
        wallets[msg.sender].push(address(w));
        emit WalletCreated(_admin,_owner, address(w));
    }
    
    function myWallets() public view returns(address[]){
        return wallets[msg.sender];
    }

    function withdraw(address _to) public{
        require(factoryOwner == msg.sender);
        require(_to!=address(0));
        _to.transfer(address(this).balance);
    }
    
    function transferOwnership(address newAdmin) public {
        require(factoryOwner == msg.sender);
        if (newAdmin != address(0)) {
            factoryOwner = newAdmin;
        }
    }
}