// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import './IERC1155Receiver.sol';
import "./ERC165.sol";
import './Events.sol';
import './Ownable.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
    function approve(address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function setApprovalForAll(address operator, bool approved) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount,bytes calldata data) external;
}

interface ISwap {
    function swapErc20(uint256 gratiaId, address inToken, uint256 inAmount, address outToken, uint8 router, address to) external;
    function swapErc721(uint256 gratiaId, address inToken, uint256 inId, address outToken, uint8 router, address to) external;
    function swapErc1155(uint256 gratiaId, address inToken, uint256 inId, uint256 inAmount, address outToken, uint256 outId, uint8 router, address to) 
    external;
}

contract GratiaPack is ERC165, IERC1155Receiver, IERC721Receiver, Context, Events, Ownable {

    struct Token {
        uint8 tokenType; // 1: ERC20, 2: ERC721, 3: ERC1155
        address tokenAddress;
    }

    // Token types
    uint8 private constant TOKEN_TYPE_ERC20 = 1;
    uint8 private constant TOKEN_TYPE_ERC721 = 2;
    uint8 private constant TOKEN_TYPE_ERC1155 = 3;

    uint256 private constant MAX_GRATIA_SUPPLY = 13337;

    // Mapping from gratia ID -> token(erc20) -> balance
    mapping(uint256 => mapping(address => uint256)) private _insideERC20TokenBalances;

    // Mapping from gratia ID -> token(erc1155) -> tokenId -> balance
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private _insideERC1155TokenBalances;

    // Mapping from gratia ID -> tokens
    mapping(uint256 => Token[]) private _insideTokens;

    // Mapping from gratia ID -> token(erc721 or erc1155) -> ids
    mapping(uint256 => mapping(address => uint256[])) private _insideTokenIds;

    // Mapping from gratia ID -> locked time
    mapping(uint256 => uint256) private _lockedTimestamp;

    IERC721 public _gratia;
    ISwap public _swap;

    modifier onlyGratiaOwner(uint256 gratiaId) {
        require(_gratia.exists(gratiaId), "Gratia does not exist");
        require(_gratia.ownerOf(gratiaId) == msg.sender, "Only owner can call");
        _;
    }
    
    modifier gratiaExists(uint256 gratiaId) {
        require(_gratia.exists(gratiaId), "Gratia does not exist");
        _;
    }

    modifier unlocked(uint256 gratiaId) {
        require(_lockedTimestamp[gratiaId] == 0 || _lockedTimestamp[gratiaId] < block.timestamp, "Gratia is locked");
        _;
    }

    constructor(address gratia) {
        _gratia = IERC721(gratia);
    }

    // View functions

    /**
     * @dev check if token exists inside gratia.
     */
    function existsId(uint256 gratiaId, address token, uint256 id) public view returns (bool) {
        uint256[] memory ids = _insideTokenIds[gratiaId][token];

        for (uint256 i; i < ids.length; i++) {
            if (ids[i] == id) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev check if gratia has been locked.
     */
    function isLocked(uint256 gratiaId) external view gratiaExists(gratiaId) returns (bool locked, uint256 endTime) {
        if (_lockedTimestamp[gratiaId] == 0 || _lockedTimestamp[gratiaId] < block.timestamp) {
            locked = false;
        } else {
            locked = true;
            endTime = _lockedTimestamp[gratiaId];
        }
    }


    /**
     * @dev get token counts inside gratia
     */
    function getInsideTokensCount(uint256 gratiaId) public view gratiaExists(gratiaId) returns (uint256 erc20Len, uint256 erc721Len, uint256 erc1155Len) {
        Token[] memory tokens = _insideTokens[gratiaId];
        for (uint256 i; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == TOKEN_TYPE_ERC20) {
                erc20Len += 1;
            }
            if (token.tokenType == TOKEN_TYPE_ERC721) {
                erc721Len += 1;
            }
            if (token.tokenType == TOKEN_TYPE_ERC1155) {
                erc1155Len += 1;
            }
        }
    }

    /**
     * @dev get tokens by gratiaId
     */
    function getTokens(uint256 gratiaId) external view gratiaExists(gratiaId) returns (uint8[] memory tokenTypes, address[] memory tokenAddresses) {
        Token[] memory tokens = _insideTokens[gratiaId];
        
        tokenTypes = new uint8[](tokens.length);
        tokenAddresses = new address[](tokens.length);

        for (uint256 i; i < tokens.length; i++) {
            tokenTypes[i] = tokens[i].tokenType;
            tokenAddresses[i] = tokens[i].tokenAddress;
        }        
    }

    /**
     * @dev get ERC20 token info
     */
    function getERC20Tokens(uint256 gratiaId) public view gratiaExists(gratiaId) returns (address[] memory addresses, uint256[] memory tokenBalances) {
        Token[] memory tokens = _insideTokens[gratiaId];
        (uint256 erc20Len,,) = getInsideTokensCount(gratiaId);
        
        tokenBalances = new uint256[](erc20Len);
        addresses = new address[](erc20Len);
        uint256 j;

        for (uint256 i; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == TOKEN_TYPE_ERC20) {
                addresses[j] = token.tokenAddress;
                tokenBalances[j] = _insideERC20TokenBalances[gratiaId][token.tokenAddress];
                j++;
            }
        }        
    }

    /**
     * @dev get ERC721 token info
     */
    function getERC721Tokens(uint256 gratiaId) public view gratiaExists(gratiaId) returns (address[] memory addresses, uint256[] memory tokenBalances) {
        Token[] memory tokens = _insideTokens[gratiaId];
        (,uint256 erc721Len,) = getInsideTokensCount(gratiaId);
        
        tokenBalances = new uint256[](erc721Len);
        addresses = new address[](erc721Len);
        uint256 j;

        for (uint256 i; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == TOKEN_TYPE_ERC721) {
                addresses[j] = token.tokenAddress;
                tokenBalances[j] = _insideTokenIds[gratiaId][token.tokenAddress].length;
                j++;
            }
        }
    }

    /**
     * @dev get ERC721 or ERC1155 ids
     */
    function getERC721OrERC1155Ids(uint256 gratiaId, address insideToken) public view gratiaExists(gratiaId) returns (uint256[] memory) {
        return _insideTokenIds[gratiaId][insideToken];
    }

    /**
     * @dev get ERC1155 token addresses info
     */
    function getERC1155Tokens(uint256 gratiaId) public view gratiaExists(gratiaId) returns (address[] memory addresses) {
        Token[] memory tokens = _insideTokens[gratiaId];
        (,,uint256 erc1155Len) = getInsideTokensCount(gratiaId);
        
        addresses = new address[](erc1155Len);
        uint256 j;

        for (uint256 i; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == TOKEN_TYPE_ERC1155) {
                addresses[j] = token.tokenAddress;
                j++;
            }
        }
    }

    /**
     * @dev get ERC1155 token balances by ids
     */
    function getERC1155TokenBalances(uint256 gratiaId, address insideToken, uint256[] memory tokenIds) public view gratiaExists(gratiaId) returns (uint256[] memory tokenBalances) {
        tokenBalances = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            tokenBalances[i] = _insideERC1155TokenBalances[gratiaId][insideToken][tokenIds[i]];
        }
    }
    

    // Write functions

    function setSwap(address swap) external onlyOwner {
        _swap = ISwap(swap);
    }

    /**
     * @dev lock gratia.
     */
    function lockGratia(uint256 gratiaId, uint256 timeInSeconds) external onlyGratiaOwner(gratiaId) unlocked(gratiaId) {
        _lockedTimestamp[gratiaId] = block.timestamp + timeInSeconds;
        
        emit LockedGratia(gratiaId, msg.sender, block.timestamp, block.timestamp + timeInSeconds);
    }

    /**
     * @dev deposit erc20 tokens into gratia.
     */
    function depositErc20IntoGratia(uint256 gratiaId, address[] memory tokens, uint256[] memory amounts) external gratiaExists(gratiaId){
        require(tokens.length > 0 && tokens.length == amounts.length);

        for (uint256 i; i < tokens.length; i++) {
            require(tokens[i] != address(0));
            IERC20 iToken = IERC20(tokens[i]);

            uint256 prevBalance = iToken.balanceOf(address(this));
            iToken.transferFrom(msg.sender, address(this),amounts[i]);
            
            uint256 receivedAmount = iToken.balanceOf(address(this)) - prevBalance;

            _increaseInsideTokenBalance(gratiaId, TOKEN_TYPE_ERC20, tokens[i], receivedAmount);

            emit DepositedErc20IntoGratia(gratiaId, msg.sender, tokens[i], receivedAmount);
            
        }
    }

    /**
     * @dev withdraw erc20 tokens from gratia.
     */
    function withdrawErc20FromGratia(uint256 gratiaId, address[] memory tokens, uint256[] memory amounts, address to) 
    public onlyGratiaOwner(gratiaId) unlocked(gratiaId) {
        require(tokens.length > 0 && tokens.length == amounts.length);

        for (uint256 i; i < tokens.length; i++) {
            require(tokens[i] != address(0));
            IERC20 iToken = IERC20(tokens[i]);

            iToken.transfer(to, amounts[i]);

            _decreaseInsideTokenBalance(gratiaId, TOKEN_TYPE_ERC20, tokens[i], amounts[i]);
            
            emit WithdrewErc20FromGratia(gratiaId, msg.sender, tokens[i], amounts[i], to);
        }
    }

    /**
     * @dev send erc20 tokens from my gratia to another gratia.
     */
    function sendErc20(uint256 fromGratiaId, address[] memory tokens, uint256[] memory amounts, uint256 toGratiaId) 
    public onlyGratiaOwner(fromGratiaId) unlocked(fromGratiaId) {
        require(fromGratiaId != toGratiaId);
        require(tokens.length > 0 && tokens.length == amounts.length);

        for (uint256 i; i < tokens.length; i++) {
            require(tokens[i] != address(0));
            require(_gratia.exists(toGratiaId));

            _decreaseInsideTokenBalance(fromGratiaId, TOKEN_TYPE_ERC20, tokens[i], amounts[i]);
            _increaseInsideTokenBalance(toGratiaId, TOKEN_TYPE_ERC20, tokens[i], amounts[i]);

            emit SentErc20(fromGratiaId, msg.sender, tokens[i], amounts[i], toGratiaId);
        }
    }

    /**
     * @dev deposit erc721 tokens into gratia.
     */
    function depositErc721IntoGratia(uint256 gratiaId, address token, uint256[] memory tokenIds) external gratiaExists(gratiaId) {
        require(token != address(0), "Deposit ERC721: Zero address of token");

        for (uint256 i; i < tokenIds.length; i++) {
            require(token != address(this) || (token == address(this) && gratiaId != tokenIds[i]));
            
            IERC721 iToken = IERC721(token);
            
            iToken.safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            _putInsideTokenId(gratiaId, token, tokenIds[i]);

            emit DepositedErc721IntoGratia(gratiaId, msg.sender, token, tokenIds[i]);
        }
        _increaseInsideTokenBalance(gratiaId, TOKEN_TYPE_ERC721, token, tokenIds.length);
    }

    /**
     * @dev withdraw erc721 token from gratia.
     */
    function withdrawErc721FromGratia(uint256 gratiaId, address token, uint256[] memory tokenIds, address to) 
    public onlyGratiaOwner(gratiaId) unlocked(gratiaId) {
        require(token != address(0));
        IERC721 iToken = IERC721(token);

        for (uint256 i; i < tokenIds.length; i++) {
            address tokenOwner = iToken.ownerOf(tokenIds[i]);

            require(tokenOwner == address(this));

            iToken.safeTransferFrom(tokenOwner, to, tokenIds[i]);

            _popInsideTokenId(gratiaId, token, tokenIds[i]);

            emit WithdrewErc721FromGratia(gratiaId, msg.sender, token, tokenIds[i], to);
        }
        _decreaseInsideTokenBalance(gratiaId, TOKEN_TYPE_ERC721, token, tokenIds.length);
    }

    /**
     * @dev send erc721 tokens from my gratia to another gratia.
     */
    function sendErc721(uint256 fromGratiaId, address token, uint256[] memory tokenIds, uint256 toGratiaId) 
    public onlyGratiaOwner(fromGratiaId) unlocked(fromGratiaId) {
        require(fromGratiaId != toGratiaId);
        require(token != address(0));
        require(_gratia.exists(toGratiaId));

        for (uint256 i; i < tokenIds.length; i++) {
            _popInsideTokenId(fromGratiaId, token, tokenIds[i]);

            _putInsideTokenId(toGratiaId, token, tokenIds[i]);

            emit SentErc721(fromGratiaId, msg.sender, token, tokenIds[i], toGratiaId);
        }
        _increaseInsideTokenBalance(toGratiaId, TOKEN_TYPE_ERC721, token, tokenIds.length);
        _decreaseInsideTokenBalance(fromGratiaId, TOKEN_TYPE_ERC721, token, tokenIds.length);
    }

    /**
     * @dev deposit erc1155 token into gratia.
     */
    function depositErc1155IntoGratia(uint256 gratiaId, address token, uint256[] memory tokenIds, uint256[] memory amounts) external gratiaExists(gratiaId){
        require(token != address(0));
        IERC1155 iToken = IERC1155(token);

        for (uint256 i; i < tokenIds.length; i++) {
            iToken.safeTransferFrom(msg.sender, address(this), tokenIds[i], amounts[i], bytes(""));

            _putInsideTokenIdForERC1155(gratiaId, token, tokenIds[i]);

            _increaseInsideERC1155TokenBalance(gratiaId, TOKEN_TYPE_ERC1155, token, tokenIds[i], amounts[i]);

            emit DepositedErc1155IntoGratia(gratiaId, msg.sender, token, tokenIds[i], amounts[i]);
        }
    }

    /**
     * @dev withdraw erc1155 token from gratia.
     */
    function withdrawErc1155FromGratia(uint256 gratiaId, address token, uint256[] memory tokenIds, uint256[] memory amounts, address to) 
    public onlyGratiaOwner(gratiaId) unlocked(gratiaId) {
        require(token != address(0));
        IERC1155 iToken = IERC1155(token);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            iToken.safeTransferFrom(address(this), to, tokenId, amount, bytes(""));

            _decreaseInsideERC1155TokenBalance(gratiaId, token, tokenId, amount);

            _popInsideTokenIdForERC1155(gratiaId, token, tokenId);

            _popERC1155FromGratia(gratiaId, token, tokenId);
            
            emit WithdrewErc1155FromGratia(gratiaId, msg.sender, token, tokenId, amount, to);
        }
    }

    /**
     * @dev send erc1155 token from my gratia to another gratia.
     */
    function sendErc1155(uint256 fromGratiaId, address token, uint256[] memory tokenIds, uint256[] memory amounts, uint256 toGratiaId) 
    public onlyGratiaOwner(fromGratiaId) unlocked(fromGratiaId) {
        require(fromGratiaId != toGratiaId);
        require(token != address(0));
        require(_gratia.exists(toGratiaId));

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            _decreaseInsideERC1155TokenBalance(fromGratiaId, token, tokenId, amount);

            _increaseInsideERC1155TokenBalance(toGratiaId, TOKEN_TYPE_ERC1155, token, tokenId, amount);

            _popInsideTokenIdForERC1155(fromGratiaId, token, tokenId);

            _putInsideTokenIdForERC1155(toGratiaId, token, tokenId);

            _popERC1155FromGratia(fromGratiaId, token, tokenId);
            
            emit SentErc1155(fromGratiaId, msg.sender, token, tokenId, amount, toGratiaId);
        }
    }

    /**
     * @dev withdraw all of inside tokens into specific address.
     */
    function withdrawAll(uint256 gratiaId, address to) external gratiaExists(gratiaId) {
        require(to != address(0));
        
        (address[] memory erc20Addresses, uint256[] memory erc20Balances) = getERC20Tokens(gratiaId);
        
        withdrawErc20FromGratia(gratiaId, erc20Addresses, erc20Balances, to);

        (address[] memory erc721Addresses, ) = getERC721Tokens(gratiaId);
        for (uint256 a; a < erc721Addresses.length; a++) {
            uint256[] memory ids = getERC721OrERC1155Ids(gratiaId, erc721Addresses[a]);
            
            withdrawErc721FromGratia(gratiaId, erc721Addresses[a], ids, to);
        }

        address[] memory erc1155Addresses = getERC1155Tokens(gratiaId);
        for (uint256 a; a < erc1155Addresses.length; a++) {
            uint256[] memory ids = getERC721OrERC1155Ids(gratiaId, erc1155Addresses[a]);
            uint256[] memory tokenBalances = getERC1155TokenBalances(gratiaId, erc1155Addresses[a], ids);
            
            withdrawErc1155FromGratia(gratiaId, erc1155Addresses[a], ids, tokenBalances, to);
        }
    }

    /**
     * @dev send all of inside tokens to specific gratia.
     */
    function sendAll(uint256 fromGratiaId, uint256 toGratiaId) external gratiaExists(fromGratiaId) gratiaExists(toGratiaId) {
        (address[] memory erc20Addresses, uint256[] memory erc20Balances) = getERC20Tokens(fromGratiaId);
        sendErc20(fromGratiaId, erc20Addresses, erc20Balances, toGratiaId);

        (address[] memory erc721Addresses,) = getERC721Tokens(fromGratiaId);
        
        for (uint256 a; a < erc721Addresses.length; a++) {
            uint256[] memory ids = getERC721OrERC1155Ids(fromGratiaId, erc721Addresses[a]);
            
            sendErc721(fromGratiaId, erc721Addresses[a], ids, toGratiaId);
        }

        address[] memory erc1155Addresses = getERC1155Tokens(fromGratiaId);
        for (uint256 a; a < erc1155Addresses.length; a++) {
            uint256[] memory ids = getERC721OrERC1155Ids(fromGratiaId, erc1155Addresses[a]);
            uint256[] memory tokenBalances = getERC1155TokenBalances(fromGratiaId, erc1155Addresses[a], ids);
            
            sendErc1155(fromGratiaId, erc1155Addresses[a], ids, tokenBalances, toGratiaId);
        }
    }
    
    /**
     * @dev external function to increase token balance of gratia
     */
    function increaseInsideTokenBalance(uint256 gratiaId, uint8 tokenType, address token, uint256 amount) external gratiaExists(gratiaId) {
        require(msg.sender != address(0));
        require(msg.sender == address(_gratia));

        _increaseInsideTokenBalance(gratiaId, tokenType, token, amount);
    }

    function swapErc20(uint256 gratiaId, address inToken, uint256 inAmount, address outToken, uint8 router, address to) 
    external onlyGratiaOwner(gratiaId) unlocked(gratiaId) {
        require(address(_swap) != address(0));
        require(_insideERC20TokenBalances[gratiaId][inToken] >= inAmount);

        IERC20(inToken).approve(address(_swap), inAmount);

        _swap.swapErc20(gratiaId, inToken, inAmount, outToken, router, to);
        
        emit SwapedErc20(msg.sender, gratiaId, inToken, inAmount, outToken, to);

        _decreaseInsideTokenBalance(gratiaId, TOKEN_TYPE_ERC20, inToken, inAmount);
    }

    function swapErc721(uint256 gratiaId, address inToken, uint256 inId, address outToken, uint8 router, address to) 
    external onlyGratiaOwner(gratiaId) unlocked(gratiaId) {
        require(address(_swap) != address(0));
        require(existsId(gratiaId, inToken, inId));
        
        IERC721(inToken).approve(address(_swap), inId);

        _swap.swapErc721(gratiaId, inToken, inId, outToken, router, to);
        
        emit SwapedErc721(msg.sender, gratiaId, inToken, inId, outToken, to);

        _popInsideTokenId(gratiaId, inToken, inId);
    }

    function swapErc1155(uint256 gratiaId, address inToken, uint256 inId, uint256 inAmount, address outToken, uint256 outId, uint8 router, address to) 
    external onlyGratiaOwner(gratiaId) unlocked(gratiaId) {
        require(address(_swap) != address(0));
        require(existsId(gratiaId, inToken, inId));
        require(_insideERC1155TokenBalances[gratiaId][inToken][inId] >= inAmount);

        IERC1155(inToken).setApprovalForAll(address(_swap), true);

        _swap.swapErc1155(gratiaId, inToken, inId, inAmount, outToken, outId, router, to);
        
        emit SwapedErc1155(msg.sender, gratiaId, inToken, inId, inAmount, outToken, outId, to);

        _decreaseInsideERC1155TokenBalance(gratiaId, inToken, inId, inAmount);

        _popInsideTokenIdForERC1155(gratiaId, inToken, inId);

        _popERC1155FromGratia(gratiaId, inToken, inId);
    }

    function _popERC1155FromGratia(uint256 gratiaId, address token, uint256 tokenId) private {
        uint256[] memory ids = _insideTokenIds[gratiaId][token];
        
        if (_insideERC1155TokenBalances[gratiaId][token][tokenId] == 0 && ids.length == 0) {
            
            delete _insideERC1155TokenBalances[gratiaId][token][tokenId];
            delete _insideTokenIds[gratiaId][token];
            
            _popTokenFromGratia(gratiaId, TOKEN_TYPE_ERC1155, token);
        }
    }
    
    /**
     * @dev private function to increase token balance of gratia
     */
    function _increaseInsideTokenBalance(uint256 gratiaId, uint8 tokenType, address token, uint256 amount) private {
        _insideERC20TokenBalances[gratiaId][token] += amount;
        _putTokenIntoGratia(gratiaId, tokenType, token);
    }

    /**
     * @dev private function to increase erc1155 token balance of gratia
     */
    function _increaseInsideERC1155TokenBalance(uint256 gratiaId, uint8 tokenType, address token, uint256 tokenId, uint256 amount) private {
        _insideERC1155TokenBalances[gratiaId][token][tokenId] += amount;
        _putTokenIntoGratia(gratiaId, tokenType, token);
    }

    /**
     * @dev private function to decrease token balance of gratia
     */
    function _decreaseInsideTokenBalance(uint256 gratiaId, uint8 tokenType, address token, uint256 amount) private {
        require(_insideERC20TokenBalances[gratiaId][token] >= amount);
        
        _insideERC20TokenBalances[gratiaId][token] -= amount;
        
        if (_insideERC20TokenBalances[gratiaId][token] == 0) {
            delete _insideERC20TokenBalances[gratiaId][token];
            _popTokenFromGratia(gratiaId, tokenType, token);
        }
    }

    /**
     * @dev private function to decrease erc1155 token balance of gratia
     */
    function _decreaseInsideERC1155TokenBalance(uint256 gratiaId, address token, uint256 tokenId, uint256 amount) private {
        require(_insideERC1155TokenBalances[gratiaId][token][tokenId] >= amount);
        
        _insideERC1155TokenBalances[gratiaId][token][tokenId] -= amount;
    }

    /**
     * @dev private function to put a token id to gratia
     */
    function _putInsideTokenId(uint256 gratiaId, address token, uint256 tokenId) private {
        uint256[] storage ids = _insideTokenIds[gratiaId][token];
        ids.push(tokenId);
    }

    /**
     * @dev private function to put a token id to gratia in ERC1155
     */
    function _putInsideTokenIdForERC1155(uint256 gratiaId, address token, uint256 tokenId) private {
        uint256[] storage ids = _insideTokenIds[gratiaId][token];
        bool isExist;
        
        for (uint256 i; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                isExist = true;
            }
        }
        
        if (!isExist) {
            ids.push(tokenId);
        }
    }

    /**
     * @dev private function to pop a token id from gratia
     */
    function _popInsideTokenId(uint256 gratiaId, address token, uint256 tokenId) private {
        uint256[] storage ids = _insideTokenIds[gratiaId][token];
        
        for (uint256 i; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
            }
        }

        if (ids.length == 0) {
            delete _insideTokenIds[gratiaId][token];
        }
    }

    /**
     * @dev private function to pop a token id from gratia in ERC1155
     */
    function _popInsideTokenIdForERC1155(uint256 gratiaId, address token, uint256 tokenId) private {
        uint256 tokenBalance = _insideERC1155TokenBalances[gratiaId][token][tokenId];
        
        if (tokenBalance <= 0) {
            delete _insideERC1155TokenBalances[gratiaId][token][tokenId];
            _popInsideTokenId(gratiaId, token, tokenId);
        }
    }

    /**
     * @dev put token(type, address) to gratia
     */
    function _putTokenIntoGratia(uint256 gratiaId, uint8 tokenType, address tokenAddress) private {
        Token[] storage tokens = _insideTokens[gratiaId];
        bool exists = false;
        
        for (uint256 i; i < tokens.length; i++) {
            if (
                tokens[i].tokenType == tokenType &&
                tokens[i].tokenAddress == tokenAddress
            ) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            tokens.push(Token({
                tokenType: tokenType,
                tokenAddress: tokenAddress
            }));
        }
    }

    /**
     * @dev pop token(type, address) from gratia
     */
    function _popTokenFromGratia(uint256 gratiaId, uint8 tokenType, address tokenAddress) private {
        Token[] storage tokens = _insideTokens[gratiaId];
        
        for (uint256 i; i < tokens.length; i++) {
            if (
                tokens[i].tokenType == tokenType &&
                tokens[i].tokenAddress == tokenAddress
            ) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }

        if (tokens.length == 0) {
            delete _insideTokens[gratiaId];
        }
    }
   
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
        return 0xbc197c81;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Events {
    event LockedGratia(
        uint256 gratiaId,
        address indexed owner,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event OpenedGratia(
        uint256 gratiaId,
        address indexed owner
    );

    event ClosedGratia(
        uint256 gratiaId,
        address indexed owner
    );

    event DepositedErc20IntoGratia(
        uint256 gratiaId,
        address indexed owner,
        address indexed erc20Token,
        uint256 amount
    );

    event WithdrewErc20FromGratia(
        uint256 gratiaId,
        address indexed owner,
        address indexed erc20Token,
        uint256 amount,
        address indexed to
    );

    event SentErc20(
        uint256 fromGratiaId,
        address indexed owner,
        address indexed erc20Token,
        uint256 amount,
        uint256 toGratiaId
    );

    event DepositedErc721IntoGratia(
        uint256 gratiaId,
        address indexed owner,
        address indexed erc721Token,
        uint256 tokenId
    );

    event WithdrewErc721FromGratia(
        uint256 gratiaId,
        address indexed owner,
        address indexed erc721Token,
        uint256 tokenId,
        address indexed to
    );

    event SentErc721(
        uint256 fromGratiaId,
        address indexed owner,
        address indexed erc721Token,
        uint256 tokenId,
        uint256 toGratiaId
    );

    event DepositedErc1155IntoGratia(
        uint256 gratiaId,
        address indexed owner,
        address indexed erc1155Token,
        uint256 tokenId,
        uint256 amount
    );

    event WithdrewErc1155FromGratia(
        uint256 gratiaId,
        address indexed owner,
        address indexed erc1155Token,
        uint256 tokenId,
        uint256 amount,
        address indexed to
    );

    event SentErc1155(
        uint256 fromGratiaId,
        address indexed owner,
        address indexed erc1155Token,
        uint256 tokenId,
        uint256 amount,
        uint256 toGratiaId
    );

    event SwapedErc20(
        address indexed owner,
        uint256 gratiaId,
        address inToken,
        uint256 inAmount,
        address outToken,
        address indexed to
    );

    event SwapedErc721(
        address indexed owner,
        uint256 gratiaId,
        address inToken,
        uint256 inId,
        address outToken,
        address indexed to
    );

    event SwapedErc1155(
        address indexed owner,
        uint256 gratiaId,
        address inToken,
        uint256 inId,
        uint256 inAmount,
        address outToken,
        uint256 outId,
        address indexed to
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

// File: @openzeppelin/contracts/access/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
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