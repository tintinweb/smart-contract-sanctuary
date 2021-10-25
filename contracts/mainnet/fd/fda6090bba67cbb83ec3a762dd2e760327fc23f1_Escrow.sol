/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity 0.7.0;

interface IERC20 {
     function transferFrom(address _token, address _from, address _to, uint256 _value) external returns (bool success);
}

interface ERC20 {
     function allowance(address owner, address spender) external returns (uint256 amount);
}

interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Escrow {
    mapping(uint256 => uint256) private amounts;
    mapping(uint256 => address) private owners;
    mapping(uint256 => address) private tokenAddresses;
    INFT nftContract;
    address transferAddress = address(0);
    address nftAddress = address(0);
    address immutable auer = msg.sender;
    
    constructor(){
        
    }
    
    function getAmount(uint256 tokenId) public view virtual returns (uint256){
        return amounts[tokenId];
    }
    
    function getOwner(uint256 tokenId) public view virtual returns (address){
        return owners[tokenId];
    }
    
    function getTokenAddress(uint256 tokenId) public view virtual returns (address){
        return tokenAddresses[tokenId];
    }
    
    function initNFT(address nft,address transfer) public {
        require(auer == msg.sender, "no author");
        require(transferAddress == address(0), "have init");
        nftAddress = nft;
        nftContract = INFT(nftAddress);
        transferAddress = transfer;
    }
    
    function setNFT(uint256 tokenId,address tokenAddress,uint256 amount,address owner) public {
        require(nftContract.ownerOf(tokenId) == address(this), "no escrow");
        require(owners[tokenId] == address(0), "is selling");
        amounts[tokenId] = amount;
        owners[tokenId] = owner;
        tokenAddresses[tokenId] = tokenAddress;
    }
    
    function pullNFT(uint256 tokenId) public {
        require(nftContract.ownerOf(tokenId) == address(this), "no escrow");
        require(owners[tokenId] == msg.sender, "no owner");
        require(amounts[tokenId] > 0, "amount error");
        amounts[tokenId] = 0; 
        owners[tokenId] = address(0); 
        tokenAddresses[tokenId] = address(0); 
        nftContract.transferFrom(address(this),msg.sender,tokenId);
    }
    
    function buyNFT(uint256 tokenId) payable public {
        require(nftContract.ownerOf(tokenId) == address(this), "no escrow");
        uint256 amount = amounts[tokenId];
        require(amount > 0, "amount error");
        address tokenAddress = tokenAddresses[tokenId];
        address owner = owners[tokenId];
        if(tokenAddress == address(0)){
            require(amount == msg.value, "amount error");
            amounts[tokenId] = 0; 
            owners[tokenId] = address(0); 
            tokenAddresses[tokenId] = address(0); 
            address(uint160(owner)).transfer(amount);
        }else{
            require(ERC20(tokenAddress).allowance(msg.sender,transferAddress) >= amount,"approve error");
            amounts[tokenId] = 0; 
            owners[tokenId] = address(0); 
            tokenAddresses[tokenId] = address(0); 
            IERC20(transferAddress).transferFrom(tokenAddress,msg.sender,owner,amount);
        }
        nftContract.transferFrom(address(this),msg.sender,tokenId);
    }
}