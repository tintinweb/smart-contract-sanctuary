/**
 *Submitted for verification at polygonscan.com on 2021-11-26
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface KCS20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract AvxReseveContract {
    
    address private owner;

    KCS20 public token;
    uint public time;
    address public claimAddress;
    address public claimTokenAddress = 0x0E7903Fa2d2EB5dEB930046c8C607Fff6F670828;
    
    struct Claim{
        uint[] amounts;
        uint[] times;
        bool[] withdrawn;
    }
    
    mapping(address => Claim) claim;
    
    event Claimed(address user,uint amount, uint time);
    event Received(address, uint);
    
    constructor() {
        owner = msg.sender;
        claimAddress =  msg.sender;
        token = KCS20(claimTokenAddress);
       // time = 1645628400; //Wednesday, February 23, 2022 8:30:00 PM GMT+05:30
        time = block.timestamp; 

        uint tokens = 1680000 * (10**18);
        uint claimAmount = tokens * 5 / 100;
        
        Claim storage clm = claim[claimAddress];

        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);


        clm.times.push(time);
        /*clm.times.push(time + 30 days);
        clm.times.push(time + 60 days);
        clm.times.push(time + 90 days);
        clm.times.push(time + 120 days);
        clm.times.push(time + 150 days);
        clm.times.push(time + 180 days);
        clm.times.push(time + 210 days);
        clm.times.push(time + 240 days);
        clm.times.push(time + 270 days);
        clm.times.push(time + 300 days);
        clm.times.push(time + 330 days);
        clm.times.push(time + 360 days);
        clm.times.push(time + 390 days);
        clm.times.push(time + 420 days);
        clm.times.push(time + 450 days);
        clm.times.push(time + 480 days);
        clm.times.push(time + 510 days);
        clm.times.push(time + 540 days);
        clm.times.push(time + 570 days);*/

        clm.times.push(time + 3 minutes);
        clm.times.push(time + 6 minutes);
        clm.times.push(time + 9 minutes);
        clm.times.push(time + 12 minutes);
        clm.times.push(time + 15 minutes);
        clm.times.push(time + 18 minutes);
        clm.times.push(time + 21 minutes);
        clm.times.push(time + 24 minutes);
        clm.times.push(time + 27 minutes);
        clm.times.push(time + 30 minutes);
        clm.times.push(time + 33 minutes);
        clm.times.push(time + 36 minutes);
        clm.times.push(time + 39 minutes);
        clm.times.push(time + 42 minutes);
        clm.times.push(time + 45 minutes);
        clm.times.push(time + 48 minutes);
        clm.times.push(time + 51 minutes);
        clm.times.push(time + 54 minutes);
        clm.times.push(time + 57 minutes);

        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
    }
    
  

    
    // Update claims for addresses with multiple entries
    function updateClaimAddress(address addr) public {
        require(msg.sender == owner, "Permission error");
        
        Claim storage clm = claim[claimAddress];
        delete claim[claimAddress];
        claimAddress = addr;
        claim[claimAddress] = clm;
        
    }
    

    
    // Claim function
    function claimFunction(uint index,address addr) public {
        require(msg.sender == owner, "Permission error");
        uint amt = claim[addr].amounts[index];
        uint timeLimit = claim[addr].times[index];
        require(block.timestamp > timeLimit, "Time not reached");
        require(token.balanceOf(address(this)) >= amt, "Insufficient amount on contract");
        require(claim[addr].withdrawn[index]==false, "Not bought or already claimed");
        token.transfer(addr, amt);
        claim[addr].withdrawn[index] = true;
        emit Claimed(addr,amt, block.timestamp);
    }
    
    // Claim function
    function claimAll() public {
        address addr = msg.sender;
        uint len = claim[addr].amounts.length;
        uint amt = 0;
        for(uint i = 0; i < len; i++){
            if(block.timestamp > claim[addr].times[i] && claim[addr].withdrawn[i]==false) {
                amt += claim[addr].amounts[i];
            }
        }
        require(token.balanceOf(address(this)) >= amt, "Insufficient amount on contract");
        require(amt != 0, "Not bought or already claimed");
        token.transfer(addr, amt);
        for(uint i = 0; i < len; i++){
            if(block.timestamp > claim[addr].times[i]) {
               claim[addr].withdrawn[i] = true;
            }
        }
       
        emit Claimed(addr,amt, block.timestamp);
    }
    
    // View details
    function userDetails(address addr) public view returns (uint[] memory amounts, uint[] memory times, bool[] memory withdrawn) {
        uint len = claim[addr].amounts.length;
        amounts = new uint[](len);
        times = new uint[](len);
        withdrawn = new bool[](len);
        for(uint i = 0; i < len; i++){
            amounts[i] = claim[addr].amounts[i];
            times[i] = claim[addr].times[i];
            withdrawn[i] = claim[addr].withdrawn[i];
        }
        return (amounts, times, withdrawn);
    }
    

    
    // View details
    function userDetailsAll(address addr) public view returns (uint,uint,uint,uint) {
        uint len = claim[addr].amounts.length;
        uint totalAmount = 0;
        uint available = 0;
        uint withdrawn = 0;
        uint nextWithdrawnDate = 0;
        bool nextWithdrawnFound;
        for(uint i = 0; i < len; i++){
            totalAmount += claim[addr].amounts[i];
            if(claim[addr].withdrawn[i]==false){
                nextWithdrawnDate = (nextWithdrawnFound==false) ?  claim[addr].times[i] : nextWithdrawnDate;
                nextWithdrawnFound = true;
            }
            if(block.timestamp > claim[addr].times[i] && claim[addr].withdrawn[i]==false){
                available += claim[addr].amounts[i];
            }
            if(claim[addr].withdrawn[i]==true){
                withdrawn += claim[addr].amounts[i];
            }
        }
        return (totalAmount,available,withdrawn,nextWithdrawnDate);
    }
    
    // Get owner 
    function getOwner() public view returns (address) {
        return owner;
    }
    
 
    
    // Owner Token Withdraw    
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        //require(block.timestamp > (time + 570 days), "Time limit Found");
        require(block.timestamp > (time + 57 minutes), "Time limit Found");
        KCS20 token_ = KCS20(tokenAddress);
        token_.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
        return true;
    }
    
    // transfer ownership
    function ownershipTransfer(address to) public {
        require(to != address(0), "Cannot set to zero address");
        require(msg.sender == owner, "Only owner");
        owner = to;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
}