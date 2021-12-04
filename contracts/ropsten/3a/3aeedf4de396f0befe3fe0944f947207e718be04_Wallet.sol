// Implementation Contract with all the logic of the smart contract
//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "./IERC20.sol";


contract Wallet {

    
    address public factoryAddress;
    address public walletOwner;
    address public contract_;
    uint public depositedDAI;

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
    }


    address public msgSender;
    address public txOrigin;

    function test() public {
        msgSender = msg.sender;
        txOrigin = tx.origin;
    }



    address public addrDAI = 0x31F42841c2db5173425b5223809CF3A38FEde360 ; // Ropsten DAI


    function init(address _factory, address _owner) public { // isFactory
        require(factoryAddress == address(0));
        require(walletOwner ==  address(0)); // ensure not init'd already.
        factoryAddress = _factory;
        walletOwner = _owner;
        contract_ = address(this);
        addrDAI = 0x31F42841c2db5173425b5223809CF3A38FEde360;
        depositedDAI = 0;
    }

    function getEtherAmount() public view isWalletOwner returns (uint){
        return address(this).balance;
    }

    function approve1(IERC20 _token, uint _amount) external isWalletOwner{
        IERC20(_token).approve(contract_, _amount);
    }

    function approve2(IERC20 _token, uint _amount) external isWalletOwner{
        IERC20(_token).approve(address(this), _amount);
    }

    function deposit(IERC20 _token, uint _amount) external isWalletOwner {
        require(IERC20(_token) == IERC20(addrDAI), "Please use DAI");
        require(_token.transferFrom(msg.sender, address(this), _amount));
        depositedDAI += _amount;
        
    }

    function withdraw(IERC20 _token, uint _amount) external isWalletOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Amount above deposited DAI");
        depositedDAI -= _amount;
        _token.transfer(msg.sender, _amount);
    }
}