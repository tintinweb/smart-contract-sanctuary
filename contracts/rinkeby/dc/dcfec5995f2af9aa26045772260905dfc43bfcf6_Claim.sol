/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.8.3;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


interface AvastarsNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract Claim {

    address owner;
    bool addressesFinalized;
    mapping (address => uint256) private amountClaimableByAddress;
    mapping(address => uint256) public airDropTokensTotal;
    address public reserveAddress = 0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3;
    
    using Roles for Roles.Role;
        
    Roles.Role private _approvedCaller;

    AvastarsNFT private avastarsNFT = AvastarsNFT(0x30E011460AB086a0daA117DF3c87Ec0c283A986E);

    constructor() {
        owner = msg.sender;
    _approvedCaller.add(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3);        
    }

    modifier isOwner() {
        require(msg.sender == owner, "Not ownwer");
        _;
    }

    function pushAddresses(address[] memory attendee) public isOwner {

        for(uint256 i = 0; i < attendee.length; i++){
            amountClaimableByAddress[attendee[i]] = 1;
        }

    }

    function finalizeAddresses() public {
        require(_approvedCaller.has(msg.sender), "Only team can finalize list.");
        addressesFinalized = true;
    }
    
    function getRandomAvastar(uint256 avastarsInReserve) internal view returns (uint256 randomAvastarIndex) {
        uint256 hash = uint((keccak256(abi.encodePacked(avastarsInReserve,msg.sender,block.number))));
        randomAvastarIndex = hash % avastarsInReserve;
    }

    function claimAvastar() public {
        require(addressesFinalized == true);
        require(amountClaimableByAddress[msg.sender] == 1);
        
        amountClaimableByAddress[msg.sender] = 0;
        
        uint256 avastarsInReserve = avastarsNFT.balanceOf(reserveAddress);

        uint256 randomAvastarIndex = getRandomAvastar(avastarsInReserve); 
        
        uint256 avastarToSend = avastarsNFT.tokenOfOwnerByIndex(reserveAddress, randomAvastarIndex);
        
        avastarsNFT.safeTransferFrom(reserveAddress, msg.sender, avastarToSend);
    }
    
    function addCaller(address newCaller) public isOwner {
        _approvedCaller.add(newCaller);
    }
    
    function removeCaller(address newCaller) public isOwner {
        _approvedCaller.remove(newCaller);
    }    

}