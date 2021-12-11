pragma solidity ^0.8.9;

interface IMultiNFT{
  function ownerOf721(uint tokenId) external view returns (address);
  function balanceOf1155(address owner, uint tokenId) external view returns (uint);
  function tokenUri721(uint tokenId) external view returns (string memory);
  function uri1155(uint tokenId) external view returns (string memory);
  function supportsInterface(bytes4) external view returns (bool);
}

contract Clout {

  struct  CloutVals {
    uint16 totalRate;
    uint16 newKingRate;
    uint16 denominator;
  }

  struct CloutKing {
    address kingAddress;
    address nftAddress;
    uint256 tokenId;
  }

  mapping (address => uint) private refunds;

  uint256 currentCrownVal;
  uint256 totalDeployerRewards;

  address public deployer;
  CloutVals public cloutVals;
  CloutKing public cloutKing;

  bool private _lock;

  constructor(address _firstKing, address _firstNft, uint _tokenId) {

    currentCrownVal = 1*(10**16);
    deployer = payable(msg.sender);

    cloutVals = CloutVals ({
      totalRate: 120,
      newKingRate: 100,
      denominator: 1000
    });

    cloutKing = CloutKing({
      kingAddress: _firstKing,
      nftAddress: _firstNft,
      tokenId: _tokenId
      });
  }

  function takeCloutCrown(address _nftAddr, uint _tokenId) external payable {

    require(!_lock);
    _lock = true;

    uint256 newCrownVal = getNextCrownVal();
    require(msg.value >= newCrownVal, "Amt low");
    require(checkOwnership(msg.sender, _nftAddr, _tokenId), "Bad owner.");

    //Check for gas saving by loading struct into memory here
    /* uint256 denominator = cloutVals.denominator;

    uint totalRewards = newCrownVal * cloutVals.totalRate / denominator;
    uint kingRewards = newCrownVal * cloutVals.newKingRate / denominator; */

    CloutVals memory stepVals = cloutVals;

    uint totalRewards = newCrownVal * stepVals.totalRate / stepVals.denominator;
    uint kingRewards = newCrownVal * stepVals.newKingRate / stepVals.denominator;
    uint kingRewardsAndBase = kingRewards + currentCrownVal;
    address prevKing = cloutKing.kingAddress;

    //Effects - crown new king, set new cloutVal
    cloutKing = CloutKing({
      kingAddress: msg.sender,
      nftAddress: _nftAddr,
      tokenId: _tokenId
      });

    totalDeployerRewards += (totalRewards - kingRewards);
    currentCrownVal = newCrownVal;

    //interaction - payout
    (bool success, ) = (prevKing).call{value:kingRewardsAndBase}("");
    require(success, "Transfer failed.");

    if(msg.value > newCrownVal) {
      refunds[msg.sender] = (msg.value - newCrownVal);
    }

    _lock = false;

  }

  function takeRefund() external {
    require(checkRefunds() > 0, "Nothing to refund.");
    uint pending = refunds[msg.sender];
    refunds[msg.sender] = 0;

    (bool success, ) = (msg.sender).call{value:pending}("");
    require(success, "Transfer failed.");
  }

  function checkOwnership (address userAddress, address _nftAddr, uint _tokenId) public view returns (bool) {
    CloutVals memory vals = cloutVals;
    IMultiNFT token = IMultiNFT(_nftAddr);
    (bool i721, bool i1155) = (token.supportsInterface(0x80ac58cd), token.supportsInterface(0xd9b67a26));
    require(i721 || i1155, "Only ERC721 and ERC1155.");

    if(i721){
      return (token.ownerOf721(_tokenId) == userAddress);
    }
    else{
      return (token.balanceOf1155(userAddress, _tokenId) > 0);
    }
  }

  function getCloutKingUri() public view returns (string memory) {

    CloutKing memory cloutKingInst = cloutKing;

    IMultiNFT token = IMultiNFT(cloutKingInst.nftAddress);
    (bool i721) = token.supportsInterface(0x80ac58cd);
    if(i721){
      return token.tokenUri721(cloutKingInst.tokenId);
    }
    else{
      return token.uri1155(cloutKingInst.tokenId);
    }
  }

  function getNextCrownVal() public view returns (uint) {
    return (currentCrownVal * cloutVals.totalRate / cloutVals.denominator);
  }

  function checkRefunds() public view returns (uint) {
    return refunds[msg.sender];
  }

  function setKing(address _kingAddr, address _nftAddr, uint _tokenId) external {
    cloutKing = CloutKing({
      kingAddress: _kingAddr,
      nftAddress: _nftAddr,
      tokenId: _tokenId
      });
  }

  receive() payable external {}

}