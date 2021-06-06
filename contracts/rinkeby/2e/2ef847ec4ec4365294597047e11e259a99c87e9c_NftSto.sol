/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

pragma solidity >=0.6.0 <0.8.0;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}



contract NftSto {
    struct Nft {
        string symbol;
        string name;
        string icon;
        string files;
    }

    uint public totalSupply;
    Nft[] public nftList;
    mapping (address => uint[]) private _holderTokens;
    mapping (string => bool) private _symbolMap;

    constructor() public {}

    function mintNft(address _to, string memory _symbol, string memory _name, string memory _icon) external  returns (uint256) {
        require(_symbolMap[_symbol] == false,"symbol exist");
        _symbolMap[_symbol]= true;
        uint tokenId = totalSupply;
        Nft memory n = Nft({symbol:_symbol,name:_name,icon:_icon,files:""});
        nftList.push(n);
        _holderTokens[_to].push(tokenId);
        totalSupply++;
        return tokenId;
    }

    function setFiles(uint _tokenId, string memory _files) external   {
        require(_tokenId < totalSupply,"tokenId too big");
        nftList[_tokenId].files = _files;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns
        (string memory, string memory, string memory, string memory) {
        uint length = _holderTokens[owner].length;
        require(length>0, "owner has no token");
        require(length > index,"index too big");
        uint tokenId =  _holderTokens[owner][index];
        return (nftList[tokenId].symbol,nftList[tokenId].name,nftList[tokenId].icon,nftList[tokenId].files);
    }
}