/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity 0.5.17;

contract KYC_ADDRESS{
    mapping (address=>string)  myName;
    
    function register(string calldata _name) external returns(bool){
        myName[msg.sender] = _name;
    }
    
    function getName() external view returns(string memory){
        return myName[msg.sender];        
    }
    
    function getNameAddr(address _addr) external view returns(string memory){
        return myName[_addr];
    }

}