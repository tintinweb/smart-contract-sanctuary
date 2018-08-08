pragma solidity ^0.4.15;

contract AbstractMintableToken {
    function mintFromTrustedContract(address _to, uint256 _amount) returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract RegistrationBonus is Ownable {
    address public tokenAddr;
    uint256 constant  bonusAmount = 1 * 1 ether;
    mapping (address => uint) public beneficiaryAddresses;
    mapping (uint => address) public beneficiaryUserIds;
    AbstractMintableToken token;

    event BonusEnrolled(address beneficiary, uint userId, uint256 amount);

    function RegistrationBonus(address _token){
        tokenAddr = _token;
        token = AbstractMintableToken(tokenAddr);
    }

    function addBonusToken(address _beneficiary, uint _userId) onlyOwner returns (bool) {
        require(beneficiaryAddresses[_beneficiary] == 0);
        require(beneficiaryUserIds[_userId] == 0);

        if(token.mintFromTrustedContract(_beneficiary, bonusAmount)) {
            beneficiaryAddresses[_beneficiary] = _userId;
            beneficiaryUserIds[_userId] = _beneficiary;
            BonusEnrolled(_beneficiary, _userId, bonusAmount);
            return true;
        } else {
            return false;
        }
    }
}