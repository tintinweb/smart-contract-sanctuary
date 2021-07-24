/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity ^0.8.6;

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

contract TerminusClaim {

    address owner;
    bool addressesFinalized;
    mapping (address => uint256) private amountClaimableByAddress;
    address public reserveAddress = 0xc53f5c08237F679b5411B0028c0c8FA4C91c54Ca; //terminus address 
    
    using Roles for Roles.Role;
        
    Roles.Role private _approvedCaller;

    AvastarsNFT private avastarsNFT = AvastarsNFT(0xF3E778F839934fC819cFA1040AabaCeCBA01e049);  //mainnet avastars 

    constructor() {
        owner = msg.sender;
    _approvedCaller.add(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3);
    _approvedCaller.add(0xBFfAc0D7B5AfAED417C36Ec492BEA4ec16DfC8b9); 
    _approvedCaller.add(0x442DCCEe68425828C106A3662014B4F131e3BD9b);    
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
    
    function avastarsRemaining() public view returns (uint256 avastarsInReserveAccount) {
        avastarsInReserveAccount = avastarsNFT.balanceOf(reserveAddress);
    }
    
    function addCaller(address newCaller) public isOwner {
        _approvedCaller.add(newCaller);
    }
    
    function removeCaller(address newCaller) public isOwner {
        _approvedCaller.remove(newCaller);
    }    

}