// Implementation Contract with all the logic of the smart contract
//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "./IERC20.sol";


contract Wallet {


    address public Factory;
    address public walletOwner;
    uint public depositedDAI;

    



    modifier isFactory() {
        require(msg.sender == Factory, "Not the Factory");
        _;
        }

    modifier isWalletOwner() {
    require(msg.sender == walletOwner, "Not the owner");
    _;
    }

    constructor(){
        Factory = msg.sender; // force default deployment to be init'd
        walletOwner = msg.sender;
        depositedDAI = 0;
    }


    address public addrDAI = 0x31F42841c2db5173425b5223809CF3A38FEde360 ; // Ropsten DAI


    function init() public isFactory { // isFactory
        require(walletOwner ==  address(0)); // ensure not init'd already.
        Factory = msg.sender;
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