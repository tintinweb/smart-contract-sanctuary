/**
 *Submitted for verification at Etherscan.io on 2021-08-12
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
    
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    
    
    address public nft_address;
    
    event Bid(address from_address, bytes32 bid_data);
    event Transfer(address token_address, address from_address, address to_address, uint256 amount);
    
    constructor(address initial_nft_address) {
        nft_address = initial_nft_address;
        
       // _setupRole(TRANSFER_ROLE, msg.sender);
    }
    
    function setNftAddress(address new_address) public {
        nft_address = new_address;
    }
    
    function setBid(bytes32 bid_data) public {
        emit Bid(msg.sender, bid_data);
    }
    
    function transferAndMint(address token_address, address from_address, address to_address, uint256 amount) public {
        //require(hasRole(TRANSFER_ROLE, msg.sender), "Caller cannot transfer");
        
        IERC20 usdt = IERC20(token_address);
        usdt.transferFrom(from_address, to_address, amount);
        
        emit Transfer(token_address, from_address, to_address, amount);
        
        INFT nft = INFT(nft_address);
        nft.mint(from_address);
    }
}