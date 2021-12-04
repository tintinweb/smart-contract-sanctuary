//SPDX-License-Identifier: UNLICENSED


pragma solidity >=0.8.10 <0.9.0;

//import "./Wallet.sol";
import "./CloneFactory.sol";
import "./IERC20.sol";



contract StorageFactory is CloneFactory  {
    address public admin;
    address public contractToClone;

    mapping(address => address) public DCAWallets; // Only one per address
    event ClonedContract(address _clonedContract);

    constructor(){
        admin = msg.sender;
        Wallet wallet = new Wallet(address(this));
        contractToClone = address(wallet);
    }

    modifier isAdmin() {
        require(msg.sender == admin, "Not the admin");
        _;
    }

    function setContractToClone(address _addr) external isAdmin {
        contractToClone = _addr;
    }

    function createStorage() public {
        require(DCAWallets[msg.sender] == address(0), "Wallet already exist for this address");
        //Create clone of Storage smart contract
        require(contractToClone != address(0), "No contract to clone");
        address clone = createClone(contractToClone);
        // Storage(clone).init(msg.sender); fonction pour initialiser le clone 
        Wallet(clone).init();
        DCAWallets[msg.sender] = clone;
        emit ClonedContract(clone);
    }

}


contract Wallet {


    address public factoryAddress;
    address public walletOwner;
    uint public depositedDAI;
    uint public data = 18;

    modifier isFactory() {
        require(msg.sender == factoryAddress, "Not the Factory");
        _;
        }

    modifier isWalletOwner() {
    require(msg.sender == walletOwner, "Not the owner");
    _;
    }

    constructor(address _factoryAddress){
        // force default deployment to be init'd
        factoryAddress = _factoryAddress;
        walletOwner = _factoryAddress;
        depositedDAI = 0;
        data = 10;
    }


    address public addrDAI = 0x31F42841c2db5173425b5223809CF3A38FEde360 ; // Ropsten DAI


    function init() public isFactory { // isFactory
        require(walletOwner ==  address(0)); // ensure not init'd already.
        factoryAddress = msg.sender;
        walletOwner = tx.origin;
    }

    function getEtherAmount() public view isWalletOwner returns (uint){
        return address(this).balance;
    }

    function approve(IERC20 _token, uint _amount) external isWalletOwner{
        IERC20(_token).approve(address(this), _amount);
    }

    function deposit(IERC20 _token, uint _amount) external isWalletOwner {
        require(_token == IERC20(addrDAI), "Please use DAI");
        require(_token.transferFrom(msg.sender, address(this), _amount));
        depositedDAI += _amount;
        
    }

    function withdraw(IERC20 _token, uint _amount) external isWalletOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Amount above deposited DAI");
        depositedDAI -= _amount;
        _token.transfer(msg.sender, _amount);
    }
    






}