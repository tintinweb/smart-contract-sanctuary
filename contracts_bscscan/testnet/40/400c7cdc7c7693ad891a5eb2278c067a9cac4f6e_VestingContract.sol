/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

interface RDetails{
    function omniaAllocatedTo(address addr) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract VestingContract{
    
    // TO CHANGE START
    
    RDetails R1Contract = RDetails(0x82B0928c2172A42DC1c8f746b4aF5Fb8B91A79AB); // R1 address
    RDetails R2Contract = RDetails(0x9c10C2C3e474bd8798B671dd9a15559aae1C4627); // R2 address
    IERC20 OmniaToken = IERC20(0x397c333ABD03D9f3258d904f0fb0364C541685c9); //OMNIA address
     
    // TO CHANGE END
    
    mapping (address => uint256) public totalClaimedR1;
    mapping (address => uint256) public totalClaimedR2;
    uint public monthTime = 86400;
    uint public contractCreationTime;
    
    constructor() public{
        contractCreationTime = block.timestamp;
    }
   
    function withdrawTokensR1(address beneficiary) public {
        
        require(R1Contract.omniaAllocatedTo(beneficiary)>0, 'No Omnia Allocated!');
        
        uint256 totalAllocation = R1Contract.omniaAllocatedTo(beneficiary);
        uint256 amount = ((block.timestamp-contractCreationTime)/monthTime)*3*totalAllocation/100;
        uint256 realAmount = amount - totalClaimedR1[beneficiary];
        if(amount>R1Contract.omniaAllocatedTo(beneficiary)){
            realAmount = R1Contract.omniaAllocatedTo(beneficiary) - totalClaimedR1[beneficiary];
        }
        require(realAmount>0, 'Beneficiary is not due any tokens!');
        
        OmniaToken.transfer(beneficiary, realAmount);
        totalClaimedR1[beneficiary] += realAmount;
    }
    
    function withdrawTokensR2(address beneficiary) public {
        
        require(R2Contract.omniaAllocatedTo(beneficiary)>0, 'No Omnia Allocated!');
        
        uint256 totalAllocation = R2Contract.omniaAllocatedTo(beneficiary);
        uint256 amount = ((block.timestamp-contractCreationTime)/monthTime)*5*totalAllocation/100;
        uint256 realAmount = amount - totalClaimedR2[beneficiary];
        if(amount>R2Contract.omniaAllocatedTo(beneficiary)){
            realAmount = R2Contract.omniaAllocatedTo(beneficiary) - totalClaimedR2[beneficiary];
        }
        require(realAmount>0, 'Beneficiary is not due any tokens!');
        
        OmniaToken.transfer(beneficiary, realAmount);
        totalClaimedR2[beneficiary] += realAmount;
    }
    
    function checkTokensDueR1(address beneficiary) public view returns(uint256){
        
        if(R1Contract.omniaAllocatedTo(beneficiary)<=0){
            return 0;
        }
        
        uint256 totalAllocation = R1Contract.omniaAllocatedTo(beneficiary);
        uint256 amount = ((block.timestamp-contractCreationTime)/monthTime)*3*totalAllocation/100;
        uint256 realAmount = amount - totalClaimedR1[beneficiary];
        if(amount>R1Contract.omniaAllocatedTo(beneficiary)){
            realAmount = R1Contract.omniaAllocatedTo(beneficiary) - totalClaimedR1[beneficiary];
        }
        
        if(realAmount<=0){
            return 0;
        }
        else{
            return realAmount;
        }
    }
    
    function checkTokensDueR2(address beneficiary) public view returns(uint256){
        
        if(R2Contract.omniaAllocatedTo(beneficiary)<=0){
            return 0;
        }
        
        uint256 totalAllocation = R2Contract.omniaAllocatedTo(beneficiary);
        uint256 amount = ((block.timestamp-contractCreationTime)/monthTime)*3*totalAllocation/100;
        uint256 realAmount = amount - totalClaimedR2[beneficiary];
        if(amount>R2Contract.omniaAllocatedTo(beneficiary)){
            realAmount = R2Contract.omniaAllocatedTo(beneficiary) - totalClaimedR2[beneficiary];
        }
        
        if(realAmount<=0){
            return 0;
        }
        else{
            return realAmount;
        }
    }
    
    function checkUserAllocationContract(address beneficiary) public view returns(uint256){
        
        if(R2Contract.omniaAllocatedTo(beneficiary)>0 && R1Contract.omniaAllocatedTo(beneficiary)>0){
            return 3;
        }
        
        else if(R1Contract.omniaAllocatedTo(beneficiary)>0){
            return 1;
        }
        
        else if(R2Contract.omniaAllocatedTo(beneficiary)>0){
            return 2;
        }
        else{
            return 0;
        }
    }
}