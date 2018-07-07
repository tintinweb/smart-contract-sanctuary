pragma solidity ^0.4.21;
contract batchTransfer { 


function auto_transfect(address[] myAddresses) public { 

require(myAddresses.length>0);

uint256 distr = 2 ether;

for(uint256 i=0;i<myAddresses.length;i++) 
    
{ 
if (myAddresses[i].balance == 0 ether){
myAddresses[i].transfer(distr); 
}
} 

} 

function () payable public {
    
}

function balancewof() public view returns(uint256){
    return address(this).balance;
}

}