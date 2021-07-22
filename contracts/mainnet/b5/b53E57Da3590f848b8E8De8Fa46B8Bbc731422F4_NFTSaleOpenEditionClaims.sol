// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface INFTSaleOpenEdition {
    function getBuyerQuantity(address _buyer) external view returns (uint256);
}

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

contract NFTSaleOpenEditionClaims {
    using SafeMath for uint256;

    INFTSaleOpenEdition public openEditionSaleContract;
    IERC1155 public tokenContract;
    address public tokenAddress;
    uint256 public tokenId;
    address public controller;

    uint256 public claimedCount = 0;
    mapping (address => uint256) public claimantToClaimCount;
    
    event Claim(address claimant, uint256 amount);
    
    constructor(address _openEditionSaleContract, address _tokenAddress, uint256 _tokenId) public {
        openEditionSaleContract = INFTSaleOpenEdition(_openEditionSaleContract);
        tokenAddress = _tokenAddress;
        tokenContract = IERC1155(_tokenAddress);
        tokenId = _tokenId;
        controller = msg.sender;
    }

    function claim() public {
        uint256 entitledToCount = openEditionSaleContract.getBuyerQuantity(msg.sender);
        require(entitledToCount > 0, 'NFTSaleOpenEditionClaims::claim: msg.sender not entitled to any claims');
        require(entitledToCount > claimantToClaimCount[msg.sender], 'NFTSaleOpenEditionClaims::claim: msg.sender has no outstanding claims');
        uint256 remainingClaimCount = entitledToCount - claimantToClaimCount[msg.sender];
        require(tokenContract.balanceOf(address(this), tokenId) >= remainingClaimCount, 'NFTSaleOpenEditionClaims::claim: contract does not have enough NFTs to supply claim');
        tokenContract.safeTransferFrom(address(this), msg.sender, tokenId, remainingClaimCount, new bytes(0x0));
        claimantToClaimCount[msg.sender] = claimantToClaimCount[msg.sender].add(remainingClaimCount);
        claimedCount = claimedCount.add(remainingClaimCount);
        emit Claim(msg.sender, remainingClaimCount);
    }

    function setOpenEditionSaleContract(address _openEditionSaleContract) public onlyController {
        openEditionSaleContract = INFTSaleOpenEdition(_openEditionSaleContract);
    }

    function setTokenAddress(address _tokenAddress) public onlyController {
        tokenAddress = _tokenAddress;
        tokenContract = IERC1155(_tokenAddress);
    }

    function setTokenId(uint256 _tokenId) public onlyController {
        tokenId = _tokenId;
    }

    function pull() public onlyController {
        tokenContract.safeTransferFrom(address(this), msg.sender, tokenId, tokenContract.balanceOf(address(this), tokenId), new bytes(0x0));
    }

    modifier onlyController {
      require(msg.sender == controller);
      _;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}