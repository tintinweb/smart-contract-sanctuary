/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.10;


interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;

    function tokenOfOwner(address owner) external view returns (uint256[] memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getPropertiesByTokenIds(uint256[] calldata tokenIdArr ) external view returns(uint256[] memory);
}
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) view external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;
    constructor () {
        _guardCounter = 1;
    }
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


// Inheritancea
interface INftSwap {
    // Views
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenOfOwner(address owner) external view returns (uint256[] memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getPropertiesByTokenIds(uint256[] calldata tokenIdArr ) external view returns(uint256[] memory);

    //sell buy
    function sell(uint256 tokenId,uint256 price) external returns (bool);
    function sells(uint256[] calldata tokenIds,uint256[] calldata prices) external returns (bool);
    function withdraw(uint256 tokenId) external returns (bool);
    function withdraws(uint256[] calldata tokenIds) external returns (bool);
    function buy(uint256 tokenId) external returns (bool);
    function buys(uint256[] calldata tokenIds) external returns (bool);

    // EVENTS
    event Sell(uint256 indexed tokenId, uint256 price);
    event Withdraw(uint256 indexed tokenId);
    event Buy(address indexed buyer,address indexed from, uint256 tokenId, uint256 price);
}


contract ForthBoxNFT_Swap is INftSwap, Ownable, ReentrancyGuard,IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    string private _name = "ForthBox NFT Swap";
    string private _symbol = "NFT Swap";
    IERC20 public fbxToken;
    IERC721 public nftToken;

    address public fundAdress;
    address public metaBoxAdress;


    mapping(uint256 => address) private _owners;
    mapping(uint256 => uint256) private _sellPrice;
    mapping(uint256 => uint256) private _sellTime;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping (address => bool) private _Is_WhiteContractArr;
    address[] private _WhiteContractArr;

    constructor() {
        fbxToken = IERC20(0xC77deEa77eE9F16596a0Ef0Df8aDFD3a87B49470);
        nftToken = IERC721(0x0661F8F45D085BaA4526A2DF35491F3faFe880A9);
        fundAdress = 0x56E6A432EAcD52183b4629E6ea1332a4FA93F9EB;
        metaBoxAdress = 0x9015F338F5cD3F03657346421C87A2351cb4Bc9F;
    }
    // constructor(address fbxTokenAdrr,address nftTokenAdrr, address tFundAdress, address tMetaBoxAdress) {
    //     fbxToken = IERC20(fbxTokenAdrr);
    //     nftToken = IERC721(nftTokenAdrr);
    //     fundAdress = tFundAdress;
    //     metaBoxAdress = tMetaBoxAdress;
    // }
    /* ========== VIEWS ========== */
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < totalSupply(), "ForthBoxNFT_Swap: global index out of bounds");
        return _allTokens[index];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function _exists(uint256 tokenId) private view returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function tokenOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 num = balanceOf(owner);
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=0; i<num; ++i) {
            Token_list[i] =_ownedTokens[owner][i];
        }
        return Token_list;
    }
    function onERC721Received(address,address,uint256,bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function tokenURI(uint256 tokenId) external view returns (string memory){      
        return nftToken.tokenURI(tokenId);
    }

    function isWhiteContract(address account) public view returns (bool) {
        if(!account.isContract()) return true;
        return _Is_WhiteContractArr[account];
    }
    function getWhiteAccountNum() public view returns (uint256){
        return _WhiteContractArr.length;
    }
    function getWhiteAccountIth(uint256 ith) public view returns (address WhiteAddress){
        require(ith <_WhiteContractArr.length, "ForthBoxNFTDeFi: not in White Adress");
        return _WhiteContractArr[ith];
    }

    function getSellInfo(uint256 tokenId) public view returns (uint256 prices,uint256 time){
        require(_exists(tokenId), "ERC721: token none exist");
        return (_sellPrice[tokenId],_sellTime[tokenId]);
    }

    function getSellInfos(uint256[] calldata tokenIdArr) public view returns ( uint256[] memory prices,uint256[] memory times){
        uint256 num = tokenIdArr.length;
        prices = new uint256[](uint256(num));
        times = new uint256[](uint256(num));
        for(uint256 i=0; i<tokenIdArr.length; ++i) {
            prices[i] = _sellPrice[tokenIdArr[i]];
            times[i] =_sellTime[tokenIdArr[i]];
        }
        return (prices,times);
    }
    function getPropertiesByTokenIds(uint256[] calldata tokenIdArr ) external view returns(uint256[] memory){
        return nftToken.getPropertiesByTokenIds(tokenIdArr);
    }
    //---private---//
    function _mint(address to, uint256 tokenId) private {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _addTokenToAllTokensEnumeration(tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
    }
    function _burn(uint256 tokenId) private {
        address owner = ownerOf(tokenId);
        _removeTokenFromOwnerEnumeration(owner, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _sellPrice[tokenId];   
        delete _sellTime[tokenId];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    //---write---//
    function sell(uint256 tokenId,uint256 price) public nonReentrant returns (bool){
        require(isWhiteContract(_msgSender()), "ForthBoxNFT_Swap: Contract not in white list!");
        require(_msgSender() == nftToken.ownerOf(tokenId),"ForthBoxNFT_Swap: Only the owner of this Token could sell It!");

        nftToken.safeTransferFrom(_msgSender(), address(this), tokenId);
        _mint(_msgSender(), tokenId);
        _sellPrice[tokenId] = price;
        _sellTime[tokenId] = block.timestamp;
        emit Sell(tokenId, price);
        return true;
    }
    function sells(uint256[] calldata tokenIds,uint256[] calldata prices ) public returns (bool){
        require(isWhiteContract(_msgSender()), "ForthBoxNFT_Swap: Contract not in white list!");
        require(tokenIds.length<=200, "ForthBoxNFT: num exceed 200!");
        for(uint256 i=0; i<tokenIds.length; ++i) {
            sell(tokenIds[i],prices[i]);
        }
        return true;
    }
    function withdraw(uint256 tokenId) public nonReentrant returns (bool){
        require(isWhiteContract(_msgSender()), "ForthBoxNFT_Swap: Contract not in white list!");
        require(_msgSender() == ownerOf(tokenId),"ForthBoxNFT_Swap: Only the owner of this Token could withdraw It!");
        nftToken.safeTransferFrom(address(this),_msgSender(),  tokenId);
        _burn(tokenId);
        emit Withdraw(tokenId);
        return true;
    }
    function withdraws(uint256[] calldata tokenIds) public returns (bool){
        require(isWhiteContract(_msgSender()), "ForthBoxNFT_Swap: Contract not in white list!");
        require(tokenIds.length<=200, "ForthBoxNFT: num exceed 200!");
        for(uint256 i=0; i<tokenIds.length; ++i) {
            withdraw(tokenIds[i]);
        }
        return true;
    }

    function buy(uint256 tokenId) public nonReentrant returns (bool){
        require(isWhiteContract(_msgSender()), "ForthBoxNFT_Swap: Contract not in white list!");
        require(_exists(tokenId),"ForthBoxNFT_Swap: token none exist");

        address ownerToken = ownerOf(tokenId);
        uint256 price0 = _sellPrice[tokenId];
        uint256 fee = price0.mul(5).div(100);
        _burn(tokenId);

        fbxToken.safeTransferFrom(_msgSender(), ownerToken, price0.sub(fee));
        fbxToken.safeTransferFrom(_msgSender(), fundAdress, fee.mul(10).div(100));
        fbxToken.safeTransferFrom(_msgSender(), metaBoxAdress, fee.mul(10).div(100));
        fbxToken.safeTransferFrom(_msgSender(), address(0), fee.mul(80).div(100));

        nftToken.safeTransferFrom(address(this),_msgSender(),  tokenId);

        emit Buy(_msgSender(), ownerToken,tokenId,price0);
        return true;
    }
    function buys(uint256[] calldata tokenIds) public returns (bool){
        require(isWhiteContract(_msgSender()), "ForthBoxNFT_Swap: Contract not in white list!");
        require(tokenIds.length<=200, "ForthBoxNFT: num exceed 200!");
        for(uint256 i=0; i<tokenIds.length; ++i) {
            buy(tokenIds[i]);
        }
        return true;
    }

    //---write onlyOwner---//
    function addWhiteAccount(address account) external onlyOwner{
        require(!_Is_WhiteContractArr[account], "ForthBox NFT DeFi:Account is already White list");
        require(account.isContract(), "ForthBox NFT DeFi: not Contract Adress");
        _Is_WhiteContractArr[account] = true;
        _WhiteContractArr.push(account);
    }
    function removeWhiteAccount(address account) external onlyOwner{
        require(_Is_WhiteContractArr[account], "ForthBox NFT DeFi:Account is already out White list");
        for (uint256 i = 0; i < _WhiteContractArr.length; i++){
            if (_WhiteContractArr[i] == account){
                _WhiteContractArr[i] = _WhiteContractArr[_WhiteContractArr.length - 1];
                _WhiteContractArr.pop();
                _Is_WhiteContractArr[account] = false;
                break;
            }
        }
    }

}