/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Scatter {
    event TransferFailed(address to, uint256 value);
    
    address public owner;
    address public feeAddress;
    uint256 public fee;
    
    
    constructor(address _feeAddress, uint256 _fee){
        feeAddress = _feeAddress;
        fee = _fee;
        owner = msg.sender;
    }
    

    
    function scatterTokenSimple(IERC20 token, address[] memory recipients, uint256[] memory values,bool revertOnfail) external payable collectFee  {
          
         uint totalSuccess = 0;
          
        for (uint256 i = 0; i < recipients.length; i++){
            (bool success,bytes memory returnData) = address(token).call(abi.encodePacked( 
                    token.transferFrom.selector,
                    abi.encode(msg.sender, recipients[i], values[i])
                ));
                
            if(success){
                (bool decoded) = abi.decode(returnData,(bool));
                if(revertOnfail==true) require(decoded,'One of the transfers failed');
                else if(decoded==false) emit TransferFailed(recipients[i],values[i]);
                if(decoded) totalSuccess++;
            }
            else if(success==false){
                if(revertOnfail==true) require(false,'One of the transfers failed');
                else emit TransferFailed(recipients[i],values[i]);
            }
           }
           require(totalSuccess>=1,'all transfers failed');
           returnExtraEth();
    }
    
        
    function returnExtraEth () internal {
        uint256 balance = address(this).balance;
        if (balance > 0){ 
            payable(msg.sender).transfer(balance); 
        }
    }
    
    
    function scatterEther(address[] memory recipients, uint256[] memory values, bool revertOnfail)  external payable collectFee {
        uint totalSuccess = 0;
         for (uint256 i = 0; i < recipients.length; i++){
           (bool success,)= recipients[i].call{value:values[i],gas:3500}('');
           if(revertOnfail) require(success,'One of the transfers failed');
           else if(success==false){
               emit TransferFailed(recipients[i],values[i]);
           }
           if(success) totalSuccess++;
        }
        
        require(totalSuccess>=1,'all transfers failed');
        returnExtraEth();
    }
    
    function changeFee (uint256 _fee) external onlyOwner {
        fee = _fee;
    }
    
    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    
    function changeFeeAddress (address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }
    
    modifier onlyOwner {
        require(msg.sender==owner,'Only owner can call this function');
        _;
    }
    
    modifier collectFee {
        if(fee>0){
            require(msg.value>=fee,'insufficient fee sent');
            payable(feeAddress).transfer(fee);
        }
        _;
    }
}