pragma solidity ^0.4.23;

interface Registry{
    function hasAttribute(address,bytes32) view returns(bool);
}
contract RegistryHelper {
    Registry public registry = Registry(0x0000000000013949f288172bd7e36837bddc7211);
    bytes32 constant public IS_MINT_RATIFIER = "isTUSDMintRatifier";
    bytes32 constant public IS_MINT_PAUSER = "isTUSDMintPausers";
    bytes32 public constant HAS_PASSED_KYC_AML = "hasPassedKYC/AML";
    bytes32 public constant CAN_BURN = "canBurn";
    bytes32 public constant IS_BLACKLISTED = "isBlacklisted";
    bytes32 public constant IS_DEPOSIT_ADDRESS = "isDepositAddress"; 
    bytes32 public constant IS_REGISTERED_CONTRACT = "isRegisteredContract"; 

    function check(address addr, bytes32 attributes) view returns (bool){
        return registry.hasAttribute(addr, attributes);
    }
    
    function isRatifier(address addr) view returns (bool){
        return registry.hasAttribute(addr, IS_MINT_RATIFIER);
    }
    
    function isChecker(address addr) view returns (bool){
        return registry.hasAttribute(addr, IS_MINT_PAUSER);
    }
    
    function passedKYC(address addr) view returns (bool){
        return registry.hasAttribute(addr, HAS_PASSED_KYC_AML);
    }
    
    function canBurn(address addr) view returns (bool){
        return registry.hasAttribute(addr, CAN_BURN);
    }
    
    function isBlacklisted(address addr) view returns (bool){
        return registry.hasAttribute(addr, IS_BLACKLISTED);
    }
    
    function isDepositAddress(address addr) view returns (bool){
        return registry.hasAttribute(addr, IS_DEPOSIT_ADDRESS);
    }
    
    function isRegisteredContract(address addr) view returns (bool){
        return registry.hasAttribute(addr, IS_REGISTERED_CONTRACT);
    }
}