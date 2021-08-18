/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.7.6;

interface AvastarsContract {
        function useTraits(uint256 _primeId, bool[12] calldata _traitFlags) external;
}

interface ARTContract {
        function burnArt(uint256 artToBurn) external;
        function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AvastarsInterface {
    
        constructor() {
            Avastars = AvastarsContract(AvastarsAddress);
            AvastarReplicantToken = ARTContract(ARTAddress);
            owner = msg.sender;
            setPaymentIncrement(5000000000000000);
        }
        
        modifier isOwner() {
        require(msg.sender == owner, "Must be owner of contract");
        _;
    }
        
        address public AvastarsAddress = 0x30E011460AB086a0daA117DF3c87Ec0c283A986E;
        address public ARTAddress = 0xdB32d39D5487b2a6116863C80e2C9E4DA1834f84;
        address public owner;
        uint256 public paymentIncrement;
        
        address payable paymentWallet = 0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3;
        
        event TraitsBurned(address msgsender, uint256 paymentTier); 
        
        AvastarsContract Avastars;
        ARTContract AvastarReplicantToken;
        
        function burnReplicantTraits(uint256 paymentTier, uint[] memory avastarIDs, bool[12][] memory avastarTraits) public payable {
            
            require(msg.value >= paymentTier * paymentIncrement);
            require(avastarIDs.length == avastarTraits.length);
            
            uint256 totalAvastars = avastarIDs.length;
            
            for (uint i = 0; i < totalAvastars; i = i + 1){
                Avastars.useTraits(avastarIDs[i],avastarTraits[i]);
            }
            
            AvastarReplicantToken.transferFrom(msg.sender,address(this),1000000000000000000);
            AvastarReplicantToken.burnArt(1);
            paymentWallet.transfer(msg.value);
    
            emit TraitsBurned(msg.sender, paymentTier);
        }
        
        function setPaymentIncrement(uint256 newIncrement) public isOwner {
            paymentIncrement = newIncrement;
        }
        
}