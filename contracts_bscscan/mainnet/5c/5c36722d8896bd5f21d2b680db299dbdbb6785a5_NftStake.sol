/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface NFT is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract Ownable is Context {
    address                  public  _owner;
    mapping(address => bool) private _roles;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = _msgSender();
        _roles[_msgSender()] = true;
        emit OwnershipTransferred(address(0), _msgSender());
    }

    modifier onlyOwner() {
        require(_roles[_msgSender()]);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _roles[_owner] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _roles[_owner] = false;
        _roles[newOwner] = true;
        _owner = newOwner;
    }

    function setOwnerState(address addr, bool state) public onlyOwner {
        _roles[addr] = state;
    }
}

contract NftStake is Ownable {
    address[] private nfts;
    uint256 userPertotalReward = 200000000000000000000000;
    address   private _back = 0x123b931ffb9b9dC15008B4495343B15Cdc37cAE8;
    // mapping(address => uint256[3]) private confNums; // nftaddr => [total, duration, erc20decimals]
    mapping(address => address)    private confAddr; // nftaddr => coinAddr

    uint256[60] TimeList = [19462961016666700000000 ,7958722297977480000000 ,7585655384733750000000 ,7231626500196230000000 ,6895664112116530000000 ,6576846266641410000000 ,6274298058270870000000 ,5987189228927240000000 ,5714731889546420000000 ,5456178357938980000000 ,5210819106987600000000 ,4977980817550430000000 ,4757024530726840000000 ,4547343894415350000000 ,4348363499351540000000 ,4159537300059890000000 ,3980347116386310000000 ,3810301211499020000000 ,3648932942455850000000 ,3495799479634450000000 ,3350480591511520000000 ,3212577491456160000000 ,3081711743372600000000 ,2957524223189250000000 ,19331292557107800000000 ,2584827456161880000000 ,2462370982081120000000 ,2346163601088080000000 ,2235886414858170000000 ,2131236798810860000000 ,2031927571642000000000 ,1937686207235850000000 ,1848254086794220000000 ,1763385789130170000000 ,1682848417178950000000 ,1606420958877800000000 ,1533893680660770000000 ,1465067551904240000000 ,1399753698743550000000 ,1337772885762090000000 ,1278955024130350000000 ,1223138704845110000000 ,1170170755788120000000 ,1119905821388440000000 ,1072205963735160000000 ,1026940284045810000000 ,983984563451565000000 ,943220922113715000000 ,904537495735727000000 ,867828128583294000000 ,832992082169916000000 ,799933758808582000000 ,768562439270932000000 ,738792033833961000000 ,710540846031105000000 ,683731348459362000000 ,658289970027244000000 ,634146894059701000000 ,611235866705985000000 ,589481377165884000000];
    uint256 public DURATION = 30 days;
    // user => nft => tokenids

    mapping(address => mapping(address => uint256[])) stakeIds;
    // user => nft => tokenid  => [stime, lasttime, amount]
    mapping(address => mapping(address => mapping(uint256 => uint256[3]))) stakes;
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    receive() external payable {}

    function wEth(address addr, uint256 amount) public onlyOwner {
        payable(addr).transfer(amount);
    }

    function wErc(address con, address addr, uint256 amount) public onlyOwner {
        IERC20(con).transfer(addr, amount);
    }

    function wNft(address nft, address toaddr, uint256 id) public onlyOwner {
        NFT(nft).transferFrom(address(this), toaddr, id);
    }

    function setBack(address addr) public onlyOwner {
        _back = addr;
    }

    function getMyNfts(address user) public view returns 
        (address[] memory, uint256[] memory, string[]  memory) {
        uint256 total;
        for (uint256 i=0; i<nfts.length; i++) {
            total += NFT(nfts[i]).balanceOf(user);
        }

        string[]  memory nftNames = new string[](total);
        address[] memory nftAddrs = new address[](total);
        uint256[] memory tokenIds = new uint256[](total);

        uint256 index = 0;
        for (uint256 i=0; i<nfts.length; i++) {
            total = NFT(nfts[i]).balanceOf(user);
            for (uint256 j=0; j<total; j++) {
                uint256 tokenid = NFT(nfts[i]).tokenOfOwnerByIndex(user, j);

                nftNames[index] = NFT(nfts[i]).symbol();
                nftAddrs[index] = nfts[i];
                tokenIds[index] = tokenid;

                index++;
            }
        }

        return (nftAddrs, tokenIds, nftNames);
    }

    function getMyStakes() public view returns (address[] memory, 
        uint256[] memory, string[] memory, uint256[] memory, uint256[] memory) {
        
        uint256 total;
        for (uint256 i=0; i<nfts.length; i++) {
            total += stakeIds[_msgSender()][nfts[i]].length;
        }
        
        address[] memory nftAddrs = new address[](total);
        uint256[] memory tokenIds = new uint256[](total);
        string[]  memory nftNames = new string[](total);
        uint256[] memory claims = new uint256[](total);
        uint256[] memory avails = new uint256[](total);

        uint256 index = 0;
        for (uint256 i=0; i<nfts.length; i++) {
            total = stakeIds[_msgSender()][nfts[i]].length;
            for (uint256 j=0; j<total; j++) {
                uint256 tokenid = stakeIds[_msgSender()][nfts[i]][j];

                tokenIds[index] = tokenid;
                nftAddrs[index] = nfts[i];
                nftNames[index] = NFT(nfts[i]).symbol();
                claims[index] = stakes[_msgSender()][nfts[i]][tokenid][2];
                avails[index] = getUnClaim(_msgSender(), nfts[i], tokenid);
                index++;
            }
        }

        return (nftAddrs, tokenIds, nftNames, claims, avails);
    }

    function addOrUpdateNft(address nft, address coin) public onlyOwner {
        require(isContract(coin) && isContract(nft) && coin != address(0) && nft != address(0));

        if (confAddr[nft] == address(0)) {
            nfts.push(nft);
        }

        confAddr[nft] = coin;
    }

    function doStake(address nft, uint256 tokenid) public {
        require(confAddr[nft] != address(0));

        NFT(nft).transferFrom(_msgSender(), _back, tokenid);

        stakeIds[_msgSender()][nft].push(tokenid);
        stakes[_msgSender()][nft][tokenid] = [block.timestamp, block.timestamp, 0];
    }

    function claim(address nft, uint256 id) public {
        require(stakes[_msgSender()][nft][id][0] > 0 && confAddr[nft] != address(0));

        uint256 canClaim = getUnClaim(_msgSender(), nft, id);
        if (canClaim > 0) {
            IERC20(confAddr[nft]).transfer(_msgSender(), canClaim);
            stakes[_msgSender()][nft][id][1]  = block.timestamp;
            stakes[_msgSender()][nft][id][2] += canClaim;
        }
    }

    function getUnClaim(address user, address nft, uint256 tokenid) private view returns (uint256) {
        uint256[3] memory mystake = stakes[user][nft][tokenid];
        uint256 startTime = mystake[0];
        uint256 userpledgemonth =  (block.timestamp-startTime) / DURATION;

        if (userpledgemonth >= TimeList.length) {
            return userPertotalReward - mystake[2];
        }
        uint256 award;
        for (uint i = 0;i <= userpledgemonth;i++){
            if (i == userpledgemonth){
                award = award +  (((block.timestamp - startTime) - (DURATION * userpledgemonth)) * (TimeList[i] / DURATION));
            }else{
                award = award + TimeList[i];
            }
        }
        award = award - mystake[2];
        return award;
    }
}