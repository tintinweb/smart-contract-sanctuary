pragma solidity 0.8.3;

import "./ProjectOwnerServiceInterface.sol";

contract DummyOwnerService is ProjectOwnerServiceInterface {

    function getProjectOwner(address _address) external override view returns(address) {
        return 0xA0b3bDe4f4c86438BEE13673647a9616ffDE0496; // KG address
    }
    
    function getProjectFeeInWei(address _address) external override view returns(uint256) {
        return 1000000000000000; // 0,001 eth
    }

    function isProjectRegistered(address _address) external override view returns(bool) {
        return true;
    }

    function isProjectOwnerService() external override view returns(bool){
        return true;
    }

}