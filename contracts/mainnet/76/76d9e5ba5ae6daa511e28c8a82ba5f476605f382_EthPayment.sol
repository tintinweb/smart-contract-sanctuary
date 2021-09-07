/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.8.0;


contract EthPayment{
    
    //OWNER STUFF
    address owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    uint256 constant COST = 40000000000000000;
    
    uint256 MINT_STATUS = 0;
    
    function getStatus() public view returns(uint256 status){
        return MINT_STATUS;
    }
    
    function setStatus(uint256 status) public onlyOwner{
        MINT_STATUS = status;
    }
    
    uint256 constant TOTAL = 10000;
    
    function totalSupply() public view returns(uint256 total){
        return CURRENT_MINT;
    }
    
    uint256 CURRENT_MINT = 0;
    
    uint256 constant RESERVES = 52;
    
    uint256 constant WALLET_MAX = 10;
    
    mapping(address => uint256) totals;
    

    event Minted(address frm, uint256 amount);
    
    constructor(){
        owner = msg.sender;
    }
    
    function balanceOf(address add) public view returns(uint256 res){
        return totals[add];
    }
    
    function mint(uint256 amount) public payable{
        require(((msg.value >= amount * COST) || msg.sender == owner) && MINT_STATUS > 0 && amount > 0 && (totals[msg.sender] + amount <= WALLET_MAX || msg.sender == owner) && CURRENT_MINT + amount <= TOTAL);
        
        totals[msg.sender] += amount;
        CURRENT_MINT += amount;
        
        emit Minted(msg.sender, amount);
    }
    
    
    function payout () public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    
    
    
    
}