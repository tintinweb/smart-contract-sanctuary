//SourceUnit: iTRC20.sol

pragma solidity ^0.5.10;
// SPDX-License-Identifier: MIT
interface TRC20Token {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function balanceOf(address _owner) external view returns(uint256);
    function transfer(address _to, uint256 _value) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);
    function approve(address _spender, uint256 _value) external returns(bool);
    function allowance(address _owner, address _spender) external view returns(uint256);
}


//SourceUnit: ownable.sol

pragma solidity ^0.5.10;
// SPDX-License-Identifier: MIT
contract ownable {
    address payable owner;
    modifier isOwner {
        require(owner == msg.sender,"XXYou should be owner to call this function.XX");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address payable _owner) public isOwner {
        require(owner != _owner,"You must enter a new value.");
        owner = _owner;
    }

    function getOwner() public view returns(address) {
        return(owner);
    }

}

//SourceUnit: whitexCharityBox.sol

pragma solidity ^0.5.10;

import "./iTRC20.sol";
import "./ownable.sol";

contract whitexCharityBox is ownable {

//****************************************************************************
//* Data
//****************************************************************************
    TRC20Token public WHXContract;
    TRC20Token public USDTContract;
    trcToken public BTTId;

//****************************************************************************
//* Events
//****************************************************************************
    event trxDonated(address _user, uint256 _amount);

//****************************************************************************
//* Main Functions
//****************************************************************************
    constructor () public { }

    function donateWithTrx() public payable returns(bool success) {
        emit trxDonated(msg.sender, msg.value);
        return success;
    }

//****************************************************************************
//* Owner Functions
//****************************************************************************

    function setWHXContract(TRC20Token _WHXContract) public isOwner returns(bool success){
        WHXContract = _WHXContract;
        return true;
    }

    function setUSDTContract(TRC20Token _USDTContract) public isOwner returns(bool success){
        USDTContract = _USDTContract;
        return true;
    }

    function setBTTId(trcToken _BTTId) public isOwner returns(bool success){
        BTTId = _BTTId;
        return true;
    }

    function withdrawTRX() public isOwner returns(bool success) {
        owner.transfer(address(this).balance);
        return true;
    }

    function withdrawWHX() public isOwner returns(bool success) {
        WHXContract.transfer(owner, WHXContract.balanceOf(address(this)));
        return true;
    }

    function withdrawUSDT() public isOwner returns(bool success) {
        USDTContract.transfer(owner, USDTContract.balanceOf(address(this)));
        return true;
    }

    function withdrawBTT() public isOwner returns(bool success) {
        owner.transferToken(address(this).tokenBalance(BTTId), BTTId);
        return true;   
    }

//****************************************************************************
//* Getter Functions
//****************************************************************************

    function trc10Balance(trcToken _id) public view returns(uint){
        trcToken id = _id;
        return address(this).tokenBalance(id);
    }

    function trc20Balance(TRC20Token _adrs) public view returns(uint){
        TRC20Token adrs = _adrs;
        return adrs.balanceOf(address(this));
    }
}