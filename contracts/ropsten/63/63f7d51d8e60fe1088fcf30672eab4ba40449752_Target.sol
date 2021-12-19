/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity 0.4.21;

contract Target {

    address private owner;
    address oldOwner;
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Target() public{
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }


    function changeOwner(address newOwner) public  onlyOwner  returns (address){
        owner = newOwner;
         return owner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
    }        

}