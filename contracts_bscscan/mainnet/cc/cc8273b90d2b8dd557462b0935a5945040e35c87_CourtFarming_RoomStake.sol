/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract  CourtFarming_RoomStake{
    struct ClaimStruct{
        address account;
        uint256 roomAmount;
        uint256 courtAmount;
    }
    
    address public roomAddress = 0x5e1B6Cb6772F8B90076A476376f7480D5594547a;
    address public courtAddress  = 0xEb804aE530Ed9D351374E865c110ed5ce172Cea0;
    
    uint256 public totalRoom;
    uint256 public totalCourt;
    
    mapping(address => ClaimStruct) public claimDB;
    
    address public owner;
    constructor() public{
        owner = msg.sender;
    }
    
    
    function claimAll() public{
        
        ClaimStruct storage claimInfo = claimDB[msg.sender];
        
        IERC20(roomAddress).transfer(msg.sender,claimInfo.roomAmount);
        claimInfo.roomAmount = 0;
        
        IERC20(courtAddress).transfer(msg.sender,claimInfo.courtAmount);
        claimInfo.courtAmount = 0;
    }
    
    function bulkAddClaim(ClaimStruct[] memory claimInfoArr) public ownerOnly{
        for(uint256 index=0; index<claimInfoArr.length; index++){
            claimDB[claimInfoArr[index].account] = claimInfoArr[index];
            totalRoom+= claimInfoArr[index].roomAmount;
            totalCourt+= claimInfoArr[index].courtAmount;
        }
    }
    
    function getClaimInfo(address account) public view  returns(ClaimStruct memory){
        return claimDB[account];
    }
    
    
    function setRoomAddrress(address newAddress) public ownerOnly{
        roomAddress = newAddress;
    }
    
    function setCourtAddress(address newAddress) public ownerOnly{
        courtAddress = newAddress;
    }
    
    // recover any tokens send to this contract ( for emergancey, or tokens send by mistake)
    function retrieveToken(IERC20 tokenAddress, uint256 amount) public ownerOnly{

        if(amount == 0){
            amount = tokenAddress.balanceOf(address(this));
        }
        tokenAddress.transfer(owner, amount);
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}