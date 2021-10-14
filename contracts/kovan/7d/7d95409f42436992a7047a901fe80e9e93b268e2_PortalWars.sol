/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

interface ERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool) ;

    function balanceOf(address account) external view returns (uint256) ;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);

    
}

interface IERC721 /* is ERC165 */ {

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;
    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);
} 
 
interface Diamond{

    function openPortals(uint256[] calldata _tokenIds) external;
    
    function ownerOf(uint256 _tokenId) external view returns (address owner_);
}



contract PortalWars{
    address public gotchiAddress = 0x07543dB60F19b9B48A69a7435B5648b46d4Bb58E;
    
    enum State {Submitted, Committed, Opening, Winner, Loser}
    
    mapping (address => address) public opponents;
    mapping (address => uint256) public deposits;
    mapping (address => State) public playerState;
    
    address[] public submittedPlayers;
    
    Diamond gotchiDiamond = Diamond(gotchiAddress);
    IERC721 aavegotchi = IERC721(gotchiAddress);

    ERC20 ghst = ERC20(0xeDaA788Ee96a0749a2De48738f5dF0AA88E99ab5);
    
    address public admin;
    
    constructor() {
        admin = msg.sender;
        
        aavegotchi.setApprovalForAll(address(this),true);
        
        ghst.approve(gotchiAddress,115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }
    
    modifier onlyAdmin{
        require(msg.sender == admin);
        _;
    }
    
    modifier onlySubmitted{
        require(playerState[msg.sender] == State.Submitted, "You have not yet submitted a portal or already have an opponent!");
        _;
    }
    
    function changeAdmin(address _admin) public onlyAdmin{
        admin = _admin;
    }
    
    function submitPortal(uint256 _portal) public{
        //todo: require that the 721 is an unopened portal
        aavegotchi.safeTransferFrom(msg.sender,address(this),_portal,"");
        submittedPlayers.push(msg.sender);
        deposits[msg.sender] = _portal;
        playerState[msg.sender] = State.Submitted;
    }
    
    function selectOpponent(address _opponent) public onlySubmitted{
        opponents[msg.sender] = _opponent;
        opponents[_opponent] = msg.sender;
        playerState[msg.sender] = State.Committed;
        playerState[_opponent] = State.Committed;
    }

    function getOpponent() public view returns(address) {
        require(playerState[msg.sender] == State.Committed, "You are not yet in a matchup");
        return opponents[msg.sender];
    }


    function returnERC721(uint256 _tokenId) public onlyAdmin{
        
        aavegotchi.safeTransferFrom(address(this),msg.sender,_tokenId,"");        

    }
    

    function returnGHST() public onlyAdmin{
        ghst.transfer(msg.sender, ghst.balanceOf(address(this)));
    }
    
   
    
    function onERC721Received(
        address, /* _operator */
        address, /*  _from */
        uint256, /*  _tokenId */
        bytes calldata /* _data */
    ) external pure  returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
    
    
    
}