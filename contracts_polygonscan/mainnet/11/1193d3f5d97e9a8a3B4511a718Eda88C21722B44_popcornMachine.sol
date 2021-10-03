/**
 *Submitted for verification at polygonscan.com on 2021-10-03
*/

pragma solidity ^0.4.24;

// .d88b .d88b. 888b. 8b  8 8   8 8    8 888b. 
// 8P    8P  Y8 8  .8 8Ybm8 8www8 8    8 8wwwP 
// 8b    8b  d8 8wwK' 8  "8 8   8 8b..d8 8   b 
// `Y88P `Y88P' 8  Yb 8   8 8   8 `Y88P' 888P'
                                        
//                 ░░  ░░░░                          
//         ░░      ░░  ░░░░  ░░                      
//       ░░  ░░░░          ░░░░░░░░                  
//         ░░  ░░░░░░  ░░░░░░░░░░░░                  
//         ░░    ░░░░░░  ░░░░░░  ░░                  
//   ░░░░░░░░    ░░  ░░    ░░  ░░░░░░                
//   ░░░░  ░░░░░░░░  ░░░░    ░░  ░░░░                
// ░░  ░░░░░░    ░░░░░░  ░░░░░░    ░░                
//       ▓▓▒▒██▓▓    ████▒▒▒▒████▒▒██                
//     ░░▓▓▒▒██▓▓░░  ████  ░░▓▓▓▓  ▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//       ▓▓▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓                
//     ░░██▒▒████░░░░████░░░░▓▓▓▓░░▓▓      
//  
// 888b. .d88b. 888b. .d88b .d88b. 888b. 8b  8 
// 8  .8 8P  Y8 8  .8 8P    8P  Y8 8  .8 8Ybm8 
// 8wwP' 8b  d8 8wwP' 8b    8b  d8 8wwK' 8  "8 
// 8     `Y88P' 8     `Y88P `Y88P' 8  Yb 8   8 

// *****************ADDRESSES*****************
// CornHub Treasury address;
// 0x9bcD90E35A0fCC6aDA241acaBA9A376368B56dF5;
// polygon mainnet kernel CORN token contract
// 0xa0c45509036c422ea7c4d4fcac26a9925531d8c3;
// polygon mainnet popcorn POPCORN token contract
// 0x6531547b44784dDD8A934fB9fEB92ba582dfeD15;
// polygon mainnet butter BUTTER token contract
// 0x409e02e728418501720d7b1e5d7328ac461ecaae;
// polygon mainnet NFT minter contract address
// 0xDBB09CEd27B571885A1B4EBd093587eDC00eae20;
// ********************************************

contract Token {
  function transfer(address receiver, uint amount) public;
  function balanceOf(address tokenOwner) public view returns (uint balance);
}

interface ERC20Interface {
  function totalSupply() external view returns (uint);
  function balanceOf(address tokenOwner) external view returns (uint balance);
  function allowance(address tokenOwner, address spender) external view returns (uint remaining);
  function transfer(address to, uint tokens) external returns (bool success);
  function approve(address spender, uint tokens) external returns (bool success);
  function transferFrom(address from, address to, uint tokens) external returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface NFTInterface{
  function mintNft(address receiver, string memory tokenURI) public view returns(uint256);
}

contract Ownable {
  address public owner;
  function Ownable() internal {
    owner = msg.sender;
    }
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
}

contract popcornMachine is Ownable {
    address cornKernel = 0xa0c45509036c422ea7c4d4fcac26a9925531d8c3;
    address popCorn = 0x6531547b44784dDD8A934fB9fEB92ba582dfeD15;
    address butter = 0x409e02e728418501720d7b1e5d7328ac461ecaae;
    address minterAddr = 0xDBB09CEd27B571885A1B4EBd093587eDC00eae20; 
    address[] popped; // airdrop array of everyone who has interacted w/ contract
    string _tokenURI; // metadata for NFT images and descriptions
    uint256 _totalCornPopped = 0; // counter for total kernels burned on contract
    uint256 _totalPopCornBurned = 0; // counter for total popcorn burned on contract
    event cornPopped(address indexed _from, uint256 _amount); // burn kernels
    event airdrop(address indexed to, uint256 amount, address token); // airdrop
    event ownerNuke(address _token, uint256 _payout); // owner withdraw
    event nftMinted(address _to, uint256 burnedCorn); // NFT created
    event vipMinted(address _vip); // few

  function burnKernel(uint256 kernelToBurn) public {
    uint256 _amount = kernelToBurn * 10**18;
    uint256 contractBalance = ERC20Interface(popCorn).balanceOf(this);
    uint256 allowance = ERC20Interface(cornKernel).allowance(msg.sender, address(this));
    require(allowance >= _amount, "Check Kernel spend allowance");
    require(_amount >= 1, "You need to send some Corn Kernels");
    require(_amount < ERC20Interface(cornKernel).balanceOf(msg.sender), "Not enough Corn Kernels owned");
    require(_amount <= contractBalance, "Not enough PopCorn in the contract");
    ERC20Interface(popCorn).transfer(msg.sender, _amount);
    ERC20Interface(cornKernel).transferFrom(msg.sender, this, _amount);
     _totalCornPopped = _totalCornPopped + kernelToBurn;
    emit cornPopped(msg.sender, _amount);
    if(ERC20Interface(butter).balanceOf(msg.sender)==0){popped.push(address(msg.sender));}
    butterAirdrop();
  }
  
  function mint(uint256 popCornToBurn) public returns (uint) {
    bool verify = false;
    uint256 _burnedCorn = popCornToBurn * 10**18;
    uint256 allowance = ERC20Interface(popCorn).allowance(msg.sender, address(this));
    if(popCornToBurn == 1) {verify = true;} else
    if(popCornToBurn == 3) {verify = true;} else
    if(popCornToBurn == 5) {verify = true;}
    require(verify = true, "Must burn 1, 2, or 5 POPCORN to mint.");
    require(_burnedCorn <= ERC20Interface(popCorn).balanceOf(msg.sender), "Burn more Kernels to mint.");
    require(allowance >= _burnedCorn, "Check PopCorn spend allowance.");
    // change NFT metadata based on popCornToBurn input
    _tokenURI = "http://my-json-server.typicode.com/misctyler/demo/tokens/1";
    if (popCornToBurn >= 3) {_tokenURI = "http://my-json-server.typicode.com/misctyler/demo/tokens/2";}
    if (popCornToBurn >= 5) {_tokenURI = "http://my-json-server.typicode.com/misctyler/demo/tokens/3";}
    ERC20Interface(popCorn).transferFrom(msg.sender, this, _burnedCorn);
    _totalPopCornBurned = _totalPopCornBurned + popCornToBurn;
    emit nftMinted(msg.sender, popCornToBurn);
    return NFTInterface(minterAddr).mintNft(msg.sender, _tokenURI);
  }

  function vipMint(address _address) public onlyOwner returns(uint) {
    _tokenURI = "http://my-json-server.typicode.com/misctyler/demo/tokens/4";
    emit vipMinted(_address);
    return NFTInterface(minterAddr).mintNft(_address, _tokenURI);
    }
    
  function poppedAirdrop(address _tokenAddr) public onlyOwner returns (uint256) {
    uint256 _payout = ERC20Interface(_tokenAddr).balanceOf(this)/popped.length;
    uint256 i = 0;
    while (i < popped.length) {
      ERC20Interface(_tokenAddr).transfer(popped[i], _payout);
      emit airdrop(popped[i], _payout, _tokenAddr);
      i += 1;
      }
    return (i);
  }

  function butterAirdrop() internal returns (uint256) {
    uint256 _prepayout = ERC20Interface(butter).balanceOf(this)/(800);
    uint256 _payout = _prepayout/popped.length;
    uint256 i = 0;
    while (i < popped.length) {
      ERC20Interface(butter).transfer(popped[i], _payout);
      emit airdrop(popped[i], _payout, butter);
      i += 1;
      }
    return (i);
  }

  function contractStats() public view returns(
  uint256, uint256, uint256) {
    return(
      popped.length, // number of burnKernel() interactions
      ERC20Interface(popCorn).balanceOf(this), // popcorn held by contract
      ERC20Interface(cornKernel).balanceOf(this)); // kernels held by contract
  }

  function tokenNuke(address _tokenAddr) public onlyOwner returns (uint256) {
    uint256 _payout = ERC20Interface(_tokenAddr).balanceOf(this);
    ERC20Interface(_tokenAddr).transfer(msg.sender, _payout);
    emit ownerNuke(_tokenAddr, _payout); 
  }
    
  function yeetOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}