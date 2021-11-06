/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

// File: contracts/utils/Owner.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner {
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);

    constructor(){
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) external onlyOwner {
        require(account != address(0),"zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner,"not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }
}

// File: contracts/Comptroller.sol




pragma solidity ^0.8.0;


interface IDGE20Miner {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

contract Comptroller is Owner {

    struct Miner {
        string  name;
        bool    exist;
        bool    enable;
        uint    totalSupply;
    }
    mapping(address => Miner) public miners;
    address[] private allMiners;


    uint public totalSupply;

    IDGE20Miner public DGE20;

    event AddMiner(address indexed miner);
    event MinerEnable(address indexed miner, uint totalSupply, bool enable);
    event Mint(address indexed miner, uint amount, address indexed recipient);
    
     constructor(IDGE20Miner DGE20_) {
        DGE20 = DGE20_;
    }


    function addMinter(address miner_, string memory name_) onlyOwner external {

        require(!miners[miner_].exist,"Comptroller: miner is exist");

        miners[miner_] = Miner({
            name:name_,
            exist:true,
            enable: true,
            totalSupply:0
        });

        allMiners.push(miner_);
        emit AddMiner(miner_);
    }


    function minerEnable(address miner_,bool enable) onlyOwner external {

        miners[miner_].enable = enable;
        emit MinerEnable(miner_, miners[miner_].totalSupply, enable);
    }

    function mint(address recipient, uint256 amount) external returns (bool){

        address miner_ = msg.sender;

        require(amount > 0, 'Comptroller: amount should larger than 0');
        require(miners[miner_].enable, 'Comptroller: miner permission denied');
        require(DGE20.mint(recipient, amount), 'Comptroller: mint failed');
        miners[miner_].totalSupply += amount;
        totalSupply += amount;
        
        emit Mint(miner_,amount,recipient);
        return true;
    }
    
    function getAllMiners() external view returns (address[] memory) {
        return allMiners;
    }
}