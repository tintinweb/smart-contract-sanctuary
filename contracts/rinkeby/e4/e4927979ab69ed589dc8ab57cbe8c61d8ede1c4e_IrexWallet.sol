pragma solidity ^0.4.23;

import "./DetailedERC20.sol";
import "./PubERC20Wallet.sol";

contract IrexWallet {

    address[] public wallets;
    address public poolAddr;
    address public deployerAddr;
    address public ownerAddr;
    
    event WalletCreatedEvent( 
        address addr,
        string action,
        uint256 amount
    );
    event Deposited(
        address fromAddr,
        address toAddr,        
        uint256 value,
        bytes data
    );
    event OwnerChanged(
        address indexed previousAddr,
        address indexed newAddr
    );
    event DeployerChanged(
        address indexed previousAddr,
        address indexed newAddr
    );
    event PoolChanged(
        address indexed previousAddr,
        address indexed newAddr
    );
    event FlushToken(
        address indexed previousAddr,
        address indexed newAddr
    );
    
    modifier onlyDeployer() {
    require(msg.sender == deployerAddr);
    _;
    }
    modifier onlyOwner() {
    require(msg.sender == ownerAddr);
    _;
    }
    
    constructor() public {
        ownerAddr = msg.sender;
        deployerAddr = msg.sender;
        poolAddr = msg.sender;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnerChanged(ownerAddr, _newOwner);
        ownerAddr = _newOwner;
    }
    
    function changeDeployer(address _newDeployer) public onlyOwner{
        require(_newDeployer != address(0));
        deployerAddr = _newDeployer;
    }
    
    function changePool(address _newPool) public onlyOwner{
        require(_newPool != address(0));
        poolAddr = _newPool;
    }
    
    function createWallet() public onlyDeployer{
        PubERC20Wallet wallet = new PubERC20Wallet(address(this));
        wallets.push(wallet);
        emit WalletCreatedEvent(wallet, "Create", 0);
    }
    
    function getWallets() public view returns (address[]){
        return wallets;
    }
    
    function getDeployer() public view returns (address){
        return deployerAddr;
    }
    
    function getPool() public view returns (address){
        return poolAddr;
    }
    
    function emitDeposited (address _from, address _to, uint256 _value, bytes _data) public{
        emit Deposited(_from, _to, _value, _data);
    }
}