/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/utils/ReentrancyGuard.sol



pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: lol2.sol



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

contract VestingContract is ReentrancyGuard{ 
    
    // TO CHANGE START
    
    RDetails R1Contract = RDetails(0x82B0928c2172A42DC1c8f746b4aF5Fb8B91A79AB); // R1 address
    RDetails R2Contract = RDetails(0x9c10C2C3e474bd8798B671dd9a15559aae1C4627); // R2 address
    IERC20 OmniaToken = IERC20(0x397c333ABD03D9f3258d904f0fb0364C541685c9); //OMNIA address
     
    // TO CHANGE END
    
    mapping (address => uint256) public totalClaimedR1;
    mapping (address => uint256) public totalClaimedR2;
    uint public monthTime = 86400;
    uint public contractCreationTime;
    
    constructor() ReentrancyGuard() public{
        contractCreationTime = block.timestamp;
    }
   
    function withdrawTokensR1(address beneficiary) nonReentrant() public {
        
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
    
    function withdrawTokensR2(address beneficiary) nonReentrant() public {
        
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