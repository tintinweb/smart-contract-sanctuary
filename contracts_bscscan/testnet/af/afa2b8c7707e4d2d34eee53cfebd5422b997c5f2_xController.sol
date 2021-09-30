/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface IBEP20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transferFromMain(address recipient, uint256 amount) external returns(bool); 
}

contract xController{
    
    event TokenPurchased(address indexed _owner, uint256 _amount, uint256 _bnb);

    IBEP20 Token;

    bool public is_preselling;
    address payable owner;
    address payable fundreceiver;
    uint256 soldTokens;
    uint256 receivedFunds;

    constructor(IBEP20 _tokenAddress)  {
        Token = _tokenAddress;
        owner = payable(msg.sender);
        fundreceiver = owner;
        is_preselling = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "invalid owner");
        _;
    }
    
    //buy tokens
    function xBurn(uint256 _amount) public payable returns(bool)  {
        require(is_preselling, "pre selling is over.");
        Token.transferFromMain(msg.sender, _amount);
        fundreceiver.transfer(msg.value);
        soldTokens += _amount;
        receivedFunds += msg.value;
        emit TokenPurchased(msg.sender, _amount, msg.value);
        return true;
    }
    
    function getTokenSupply() public view returns(uint256){
        return Token.totalSupply();
    }
    
    function getTokenbalance(address _address) public view returns(uint256){
        return Token.balanceOf(_address);
    }
    
    function totalSoldTokens() public view returns(uint256){
        return soldTokens;
    }
    function totalReceivedFunds() public view returns(uint256){
        return receivedFunds;
    }
    
    function getbalance()  public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function TransferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function SetReceiver(address payable _fund) public onlyOwner {
        fundreceiver = _fund;
    }


    function SetPreSellingStatus() public onlyOwner {
        if (is_preselling) {
            is_preselling = false;
        } else {
            is_preselling = true;
        }
    }

}