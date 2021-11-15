// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

/**
 * @title Swap
 * @dev Main Swap contract that burns old token and mints new token for given user
 */

contract Owned {
        address public owner;      

        constructor() {
            owner = msg.sender;
        }

        modifier onlyOwner {
            assert(msg.sender == owner);
            _;
        }
        
        /* This function is used to transfer adminship to new owner
         * @param  _newOwner - address of new admin or owner        
         */

        function transferOwnership(address _newOwner) onlyOwner public {
            assert(_newOwner != address(0)); 
            owner = _newOwner;
        }          
}

contract Swapper is Owned
{
    
    ERC20 oldToken;
    ERC20 newToken;
    Burner burner;
    
    event SwapExecuted(address user, uint256 amount);

    struct VestingUnit {
        uint256 amount;
        uint256 timestamp;
    }
        
    uint256 public approvalDeadline;

    mapping(address => VestingUnit[]) public holdersVestingData;
    
    function claim() public {
        VestingUnit[] memory vestingUnits = holdersVestingData[msg.sender];
        uint sum = 0;
        for(uint i = 0; i < vestingUnits.length; i++) {
            uint256 finalClaimableTime = vestingUnits[i].timestamp + findTimeMultipler(i) * 30 days + 2 weeks;
            if(finalClaimableTime < block.timestamp){
                continue;
            }
            if(vestingUnits[i].amount > 0 && vestingUnits[i].timestamp < block.timestamp) {
                sum += vestingUnits[i].amount;
                delete holdersVestingData[msg.sender][i];
            }
        }
        newToken.transfer(msg.sender, sum);
    }
    
    function amountClaimable(address holder) public view returns(uint256) {
        VestingUnit[] memory vestingUnits = holdersVestingData[holder];
        uint sum = 0;
        for(uint i = 0; i < vestingUnits.length; i++) {
             uint256 finalClaimableTime = vestingUnits[i].timestamp + findTimeMultipler(i) * 30 days + 2 weeks;
            if(finalClaimableTime < block.timestamp){
                continue;
            }
            if(vestingUnits[i].amount > 0 && vestingUnits[i].timestamp < block.timestamp) {
                sum += vestingUnits[i].amount;
            }
        }
        return sum;
    }
     
    constructor(
        address _oldToken,
        address _newToken,
        address _burner,
        uint256 _approvalDeadline

    ) {
        approvalDeadline = _approvalDeadline;
        oldToken = ERC20(_oldToken);
        newToken = ERC20(_newToken);
        burner = Burner(_burner);

    }

    function updateApprovalDeadline(uint256 _approvalDeadline) onlyOwner public {
        approvalDeadline = _approvalDeadline;
    }
    
    function energencyWithdraw(uint256 _amount) onlyOwner public {
        newToken.transfer(msg.sender,_amount);
    }
    
	function SwapNow(uint256 _val) public {
	    require(approvalDeadline > block.timestamp);
	    require(oldToken.allowance(msg.sender, address(this)) >= _val); 
	    oldToken.transferFrom(msg.sender, address(this), _val);
	    burner.burn(_val);
	    newToken.transfer(msg.sender, _val / 10);
	    
	    setVestingData(_val);

	    emit SwapExecuted(msg.sender, _val);
	}
	
	function calculateCutPerMonth(uint256 totalAmount) private pure returns (uint256){
	    return totalAmount * 75/1000;
	}
	
	
	function setVestingData(uint256 _val) private {
	    	  
	    uint256 amount = calculateCutPerMonth(_val);
	    uint256 finalChunkAmount = _val - _val/10;
	    for(uint256 i=0; i < 11; i++){
	        uint256 vestingTimestamp = block.timestamp + 90 days + 30 days * i;
	        VestingUnit memory vestingData  = VestingUnit({amount:amount,timestamp:vestingTimestamp});
	        holdersVestingData[msg.sender].push(vestingData);
	        finalChunkAmount -= amount;
	    }
	    
	    holdersVestingData[msg.sender].push(VestingUnit({amount:finalChunkAmount,timestamp:block.timestamp + 90 days + 30 days * 11}));
	}
	
	
	function findTimeMultipler(uint256 i) private pure returns(uint256){
	    if((i+1)%12 == 0){
	        return 0 ;
	    }
	    else{
	        return 12 - (i+1)%12;
	    }
	}
	

	function remainingClaim(address _holder) view public returns(uint256) {
	    VestingUnit[] memory vestingUnits = holdersVestingData[_holder];
        uint sum = 0;
        for(uint i = 0; i < vestingUnits.length; i++) {
            if(vestingUnits[i].amount > 0) {
                sum += vestingUnits[i].amount;
            }
        }
        return sum;
	}
}

contract Burner is Owned {
    ERC20 oldToken;
    
    function returnOwnership(address _newOwner) public onlyOwner {
        oldToken.transferOwnership(_newOwner);
    }
    
    constructor(address _oldToken) {
        oldToken = ERC20(_oldToken);
    }
    
    function burn(uint256 _val) public {
        oldToken.burn(_val);
    }
}

interface ERC20 {
    function transferOwnership(address _newOwner) external;
    
    function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) external returns (bool success);
    
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function burn(uint256 _value) external;
    
    function transfer(address recipient, uint256 amount) external returns (bool);

}

