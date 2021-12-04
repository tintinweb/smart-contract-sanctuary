//SPDX-License-Identifier: UNLICENSED


pragma solidity >=0.8.10 <0.9.0;

import "./Wallet.sol";
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


    function testL() public {
        Wallet(contractToClone).test();
    }



    function createStorage() public {
        require(DCAWallets[msg.sender] == address(0), "Wallet already exist for this address");
        //Create clone of Storage smart contract
        require(contractToClone != address(0), "No contract to clone");
        address clone = createClone(contractToClone);
        // Storage(clone).init(msg.sender); fonction pour initialiser le clone 
        Wallet(clone).init(address(this), msg.sender);
        DCAWallets[msg.sender] = clone;
        emit ClonedContract(clone);
    }

}