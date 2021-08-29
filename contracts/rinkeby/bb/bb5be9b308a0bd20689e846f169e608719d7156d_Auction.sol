/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {


    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface INFT {
    function mint(address to) external;
}

contract Auction {
    
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_AND_MINT_ROLE");
    bytes32 public constant AUCTION_SETTER_ROLE = keccak256("AUCTION_SETTER");

    event Bid(address from_address, bytes32 bid_hash);
    event Transfer(address from_address, address to_address, uint256 amount);
    event SetAuction(uint256 from_block, uint256 to_block, uint256 winners_count);

    INFT public nft;
    IERC20 public token;
    address public wallet_address;
    
    uint256 public from_block;
    uint256 public to_block;
    uint256 public winners_count;

   
    constructor(IERC20 _token, INFT _nft, address _wallet_address) {
        nft = _nft;
        token = _token;
        wallet_address = _wallet_address;
        
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function setWalletAddress(address new_address) public {
        //require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");

        wallet_address = new_address;
    }
    
    function setAuction(uint256 _from_block, uint256 _to_block, uint256 _winners_count) public {
        //require(hasRole(AUCTION_SETTER_ROLE, msg.sender), "Caller is not an auction setter");
        
        from_block = _from_block;
        to_block = _to_block;
        winners_count = _winners_count;
        
        emit SetAuction(from_block, to_block, winners_count);
    }
    
    function setBid(bytes32 bid_hash) public {
        require(from_block <= block.number && block.number <= to_block);
        emit Bid(msg.sender, bid_hash);
    }
    
    function transferAndMint(address from_address, uint256 amount) public {
        //require(hasRole(TRANSFER_AND_MINT_ROLE, msg.sender), "Caller cannot transfer");
        
        token.transferFrom(from_address, wallet_address, amount);
        
        emit Transfer(from_address, wallet_address, amount);
        
        nft.mint(from_address);
    }
}