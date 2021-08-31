/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract Ownable {
  address public owner;

    constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract _1000eye_sale is Ownable {

    event Sale(uint256 indexed tokenId,address indexed owner,uint256 indexed hash);
    
    struct ArtSale {
        address owner;
        uint256 hash;
    }
    
    address[] public sales;
    
    uint256 public bloomberg_nasdag;
    uint256 public totalsale;
    IERC721 public erc721_1000;

  
    
    uint256 constant ALEN=10;
    ArtSale[] public  artsales;


    function FinalProcess(uint256 _bloomberg_nasdag) public {
        
        require(bloomberg_nasdag==0,"ALREADY_Processed");
        require(totalsale==ALEN, "1000_SOLD_STILL_IN_SALE");
        bloomberg_nasdag=_bloomberg_nasdag;
       
        uint256 i;
        
        for(i=0;i<ALEN;i++){
            ArtSale memory _artsale = ArtSale({
                owner: sales[i],
                hash: hashvalue(bloomberg_nasdag,i+1)

            });
            artsales.push(_artsale);
        }
        ArtSale[] memory data=sort(artsales);
        for(i=0;i<data.length;i++){
            emit Sale(i+1,data[i].owner,data[i].hash);
            erc721_1000.safeTransferFrom(erc721_1000.ownerOf(i+1), data[i].owner,i+1);
        }

    }  

    constructor(address _1000eye)
        public
    {
         erc721_1000=IERC721(_1000eye);
    }

    function hashvalue(uint256 seed,uint256 i) private pure returns (uint) {
        uint randomHash = uint256(keccak256(abi.encodePacked(int32(seed+i))));
        return randomHash;
    } 
    function hash(uint256 seed,uint256 i) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(int32(seed+i)));

    } 
    
    function  () external 
     payable {
        require(msg.value==1 wei, "MUST_1_ETHER_ONLY");
        require(totalsale<ALEN, "1000_SOLD_OUT");

        totalsale=sales.push(msg.sender);

    }
    function sort(ArtSale[] memory data) public pure returns (ArtSale[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }
    function quickSort(ArtSale[] memory ass,int left, int right)public pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = ass[uint(left + (right - left) / 2)].hash;
        while (i <= j) {
            while (ass[uint(i)].hash < pivot) i++;
            while (pivot < ass[uint(j)].hash) j--;
            if (i <= j) {
                //exchange
                address ta;
                uint256 ti;
                
                ta=ass[uint(i)].owner;
                ti=ass[uint(i)].hash;
                ass[uint(i)].owner=ass[uint(j)].owner;
                ass[uint(i)].hash=ass[uint(j)].hash;
                ass[uint(j)].owner=ta;
                ass[uint(j)].hash=ti;
                //(arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(ass, left, j);
        if (i < right)
            quickSort(ass, i, right);
    }
    
    function collect(address bene)external {
        uint256 balance=address(this).balance;
        (bool success, ) =address(uint160(bene)).call.value(balance)("");
        require(success,"ERR contract transfer eth to pool fail,maybe gas fail");
    }

}