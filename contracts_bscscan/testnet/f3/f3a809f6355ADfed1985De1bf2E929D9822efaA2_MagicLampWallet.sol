// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Wallet.sol";

import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./ERC165.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract MagicLampWallet is ERC165, IERC1155Receiver, IERC721Receiver, Wallet {
    using SafeMath for uint256;

    // Mapping from NFT -> ID -> Token(ERC721 or ERC1155) -> IDs
    mapping(address => mapping(uint256 => mapping(address => uint256[]))) private _erc721ERC1155TokenIds;

    // Mapping from NFT -> ID -> Token(ERC20) -> Balance
    mapping(address => mapping(uint256 => mapping(address => uint256))) private _erc20TokenBalances;

    // Mapping from NFT -> ID -> Token(ERC1155) -> Token ID -> Balance
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) private _erc1155TokenBalances;

    /**
     * @dev Checks if token exists inside wallet.
     */
    function existsERC721ERC1155(address nft, uint256 id, address token, uint256 tokenId) public view returns (bool) {
        uint256[] memory ids = _erc721ERC1155TokenIds[nft][id][token];

        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Gets ERC20 token info
     */
    function getERC20Tokens(address nft, uint256 id) 
    public view  returns (address[] memory addresses, uint256[] memory tokenBalances) {
        exists(nft, id);
        Token[] memory tokens = _tokens[nft][id];
        (uint256 erc20Count, , ) = getTokensCount(nft, id);

        addresses = new address[](erc20Count);
        tokenBalances = new uint256[](erc20Count);
        uint256 j = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == TOKEN_TYPE_ERC20) {
                addresses[j] = token.tokenAddress;
                tokenBalances[j] = _erc20TokenBalances[nft][id][token.tokenAddress];
                j++;
            }
        }
    }

    /**
     * @dev Gets ERC721 token info
     */
    function getERC721Tokens(address nft, uint256 id) 
    public view  returns (address[] memory addresses, uint256[] memory tokenBalances) {
        exists(nft, id);
        Token[] memory tokens = _tokens[nft][id];
        (, uint256 erc721Count, ) = getTokensCount(nft, id);
        addresses = new address[](erc721Count);
        tokenBalances = new uint256[](erc721Count);
        uint256 j = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == TOKEN_TYPE_ERC721) {
                addresses[j] = token.tokenAddress;
                tokenBalances[j] = _erc721ERC1155TokenIds[nft][id][token.tokenAddress].length;
                j++;
            }
        }
    }

    /**
     * @dev Gets ERC721 or ERC1155 IDs
     */
    function getERC721ERC1155Ids(address nft, uint256 id, address token) public view  returns (uint256[] memory) {
        exists(nft, id);
        return _erc721ERC1155TokenIds[nft][id][token];
    }

    /**
     * @dev Gets ERC1155 token addresses info
     */
    function getERC1155Tokens(address nft, uint256 id) public view returns (address[] memory addresses) {
        exists(nft, id);
        Token[] memory tokens = _tokens[nft][id];
        (, , uint256 erc1155Count) = getTokensCount(nft, id);

        addresses = new address[](erc1155Count);
        uint256 j = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == TOKEN_TYPE_ERC1155) {
                addresses[j] = token.tokenAddress;
                j++;
            }
        }
    }

    /**
     * @dev Gets ERC1155 token balances by IDs
     */
    function getERC1155TokenBalances(address nft, uint256 id, address token, uint256[] memory tokenIds)
    public view returns (uint256[] memory tokenBalances) {
        exists(nft, id);
        tokenBalances = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenBalances[i] = _erc1155TokenBalances[nft][id][token][tokenIds[i]];
        }
    }

    /**
     * @dev Deposits ERC20 tokens into wallet.
     */
    function depositERC20(address nft, uint256 id, address[] memory tokens, uint256[] memory amounts) external {
        exists(nft, id) ;
        require(tokens.length > 0 && tokens.length == amounts.length, "MagicLampWallet::depositERC20: invalid parameters");

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);

            uint256 prevBalance = token.balanceOf(address(this));
            token.transferFrom(_msgSender(), address(this), amounts[i]);
            uint256 receivedAmount = token.balanceOf(address(this)).sub(prevBalance);

            _addTokenBalance(nft, id, TOKEN_TYPE_ERC20, tokens[i], receivedAmount);

            emit MagicLampWalletERC20Deposited(_msgSender(), nft, id, tokens[i], receivedAmount);
        }
    }

    /**
     * @dev Withdraws ERC20 tokens from wallet.
     */
    function withdrawERC20(address nft, uint256 id, address[] memory tokens, uint256[] memory amounts)
    public  {
        onlyWalletOwner(nft, id);
        unlocked(nft, id);
        require(tokens.length > 0 && tokens.length == amounts.length, "MagicLampWallet::withdrawERC20: invalid parameters");

        address to = IERC721(nft).ownerOf(id);

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);

            token.transfer(to, amounts[i]);

            _subTokenBalance(nft, id, TOKEN_TYPE_ERC20, tokens[i], amounts[i]);

            emit MagicLampWalletERC20Withdrawn(_msgSender(), nft, id, tokens[i], amounts[i], to);
        }
    }

    /**
     * @dev Transfers ERC20 tokens from wallet into another wallet.
     */
    function transferERC20(address fromNFT, uint256 fromId, address tokens, uint256 amounts, address toNFT, uint256 toId)
    public  {
        onlyWalletOwner(fromNFT, fromId);
        unlocked(fromNFT, fromId);
        exists(toNFT, toId);
        require(fromNFT != toNFT || fromId != toId, "MagicLampWallet::transferERC20: same wallet");
        //require(tokens.length > 0 && tokens.length == amounts.length, "MagicLampWallet::transferERC20: invalid parameters");

        //for (uint256 i = 0; i < tokens.length; i++) {
        _subTokenBalance(fromNFT, fromId, TOKEN_TYPE_ERC20, tokens, amounts);
        _addTokenBalance(toNFT, toId, TOKEN_TYPE_ERC20, tokens, amounts);

        emit MagicLampWalletERC20Transferred(_msgSender(), fromNFT, fromId, tokens, amounts, toNFT, toId);
        //}
    }

    /**
     * @dev Deposits ERC721 tokens into wallet.
     */
    function depositERC721(address nft, uint256 id, address token, uint256[] memory tokenIds) external  {
        exists(nft, id);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721 iToken = IERC721(token);

            iToken.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

            _putToken(nft, id, TOKEN_TYPE_ERC721, token);
            _putTokenId(nft, id, token, tokenIds[i]);

            emit MagicLampWalletERC721Deposited(_msgSender(), nft, id, token, tokenIds[i]);
        }
    }

    /**
     * @dev Withdraws ERC721 token from wallet.
     */
    function withdrawERC721(address nft, uint256 id, address token, uint256[] memory tokenIds)
    public {
        onlyWalletOwner(nft, id);
        unlocked(nft, id);
        IERC721 iToken = IERC721(token);

        address to = IERC721(nft).ownerOf(id);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(iToken.ownerOf(tokenIds[i]) == address(this));

            iToken.safeTransferFrom(address(this), to, tokenIds[i]);

            _popTokenId(nft, id, token, tokenIds[i]);
            _popToken(nft, id, TOKEN_TYPE_ERC721, token);

            emit MagicLampWalletERC721Withdrawn(_msgSender(), nft, id, token, tokenIds[i], to);
        }
    }

    /**
     * @dev Transfers ERC721 tokens from wallet to another wallet.
     */
    function transferERC721(address fromNFT, uint256 fromId, address token, uint256 tokenIds, address toNFT, uint256 toId) 
    public {
        onlyWalletOwner(fromNFT, fromId);
        unlocked(fromNFT, fromId);
        exists(toNFT, toId);
        require(fromNFT != toNFT || fromId != toId, "MagicLampWallet::transferERC721: same wallet");
        //require(tokenIds.length > 0, "MagicLampWallet::transferERC721: invalid parameters");

        //for (uint256 i = 0; i < tokenIds.length; i++) {
            _popTokenId(fromNFT, fromId, token, tokenIds);
            _popToken(fromNFT, fromId, TOKEN_TYPE_ERC721, token);

            _putToken(toNFT, toId, TOKEN_TYPE_ERC721, token);
            _putTokenId(toNFT, toId, token, tokenIds);

            emit MagicLampWalletERC721Transferred(_msgSender(), fromNFT, fromId, token, tokenIds, toNFT, toId);
       // }
    }

    /**
     * @dev Deposits ERC1155 token into wallet.
     */
    function depositERC1155(address nft, uint256 id, address token, uint256[] memory tokenIds, uint256[] memory amounts) 
    external {
        exists(nft, id);
        IERC1155 iToken = IERC1155(token);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            iToken.safeTransferFrom(_msgSender(), address(this), tokenIds[i], amounts[i], bytes(""));

            _putERC1155TokenId(nft, id, token, tokenIds[i]);

            _addERC1155TokenBalance(nft, id, TOKEN_TYPE_ERC1155, token, tokenIds[i], amounts[i]);

            emit MagicLampWalletERC1155Deposited(_msgSender(), nft, id, token, tokenIds[i], amounts[i]);
        }
    }

    /**
     * @dev Withdraws ERC1155 token from wallet.
     */
    function withdrawERC1155(address nft, uint256 id, address token, uint256[] memory tokenIds, uint256[] memory amounts)
    public {
        onlyWalletOwner(nft, id);
        unlocked(nft, id);
        IERC1155 iToken = IERC1155(token);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            address to = IERC721(nft).ownerOf(id);
            iToken.safeTransferFrom(address(this), to, tokenId, amount, bytes(""));

            _subERC1155TokenBalance(nft, id, token, tokenId, amount);

            _popERC1155TokenId(nft, id, token, tokenId);

            _popERC1155(nft, id, token, tokenId);

            emit MagicLampWalletERC1155Withdrawn(_msgSender(), nft, token, tokenId, amount, to);
        }
    }

    /**
     * @dev Transfers ERC1155 token from wallet to another wallet.
     */
    function transferERC1155(address fromNFT, uint256 fromId, address token, uint256 tokenId, uint256 amount, address toNFT, uint256 toId)
    public {
        onlyWalletOwner(fromNFT, fromId);
        unlocked(fromNFT, fromId); 
        require(fromNFT != toNFT || fromId != toId, "MagicLampWallet::transferERC1155: same wallet");
        //require(tokenIds.length > 0 && tokenIds.length == amounts.length, "MagicLampWallet::transferERC1155: invalid parameters");

        //for (uint256 i = 0; i < tokenIds.length; i++) {
            // uint256 tokenId = tokenIds;
            // uint256 amount = amounts;

            _subERC1155TokenBalance(fromNFT, fromId, token, tokenId, amount);

            _addERC1155TokenBalance(toNFT,toId, TOKEN_TYPE_ERC1155, token, tokenId, amount);

            _popERC1155TokenId(fromNFT, fromId, token, tokenId);

            _putERC1155TokenId(toNFT, toId, token, tokenId);

            _popERC1155(fromNFT, fromId, token, tokenId);

            emit MagicLampWalletERC1155Transferred(_msgSender(), fromNFT, token, tokenId, amount, toNFT, toId);
        //}
    }

    /**
     * @dev Withdraws all of tokens from wallet.
     */
    function withdrawAll(address nft, uint256 id, address to) external  {
        exists(nft, id);
        require(to != address(0));

        (address[] memory erc20Addresses, uint256[] memory erc20Balances) = getERC20Tokens(nft, id);
        withdrawERC20(nft, id, erc20Addresses, erc20Balances);

        (address[] memory erc721Addresses, ) = getERC721Tokens(nft, id);
        for (uint256 a = 0; a < erc721Addresses.length; a++) {
            uint256[] memory ids = getERC721ERC1155Ids(nft, id, erc721Addresses[a]);
            withdrawERC721(nft, id, erc721Addresses[a], ids);
        }

        address[] memory erc1155Addresses = getERC1155Tokens(nft, id);
        for (uint256 a = 0; a < erc1155Addresses.length; a++) {
            uint256[] memory ids = getERC721ERC1155Ids(nft, id, erc1155Addresses[a]);
            uint256[] memory tokenBalances = getERC1155TokenBalances(nft, id, erc1155Addresses[a], ids);
            withdrawERC1155(nft, id, erc1155Addresses[a], ids, tokenBalances);
        }
    }

    /**
     * @dev Transfers all of tokens to another wallet.
     */
    function transferAll(address fromNFT,uint256 fromId,address toNFT,uint256 toId) external{
        exists(fromNFT, fromId);
        exists(toNFT, toId);
        require(fromNFT != toNFT || fromId != toId, "MagicLampWallet::transferAll: same wallet");

        (address[] memory erc20Addresses, uint256[] memory erc20Balances ) = getERC20Tokens(fromNFT, fromId);
        for(uint256 i = 0; i < erc20Addresses.length; i++){
            transferERC20(fromNFT, fromId, erc20Addresses[i], erc20Balances[i], toNFT, toId);
        }

        (address[] memory erc721Addresses, ) = getERC721Tokens(fromNFT, fromId);

        for (uint256 a = 0; a < erc721Addresses.length; a++) {
            uint256[] memory ids = getERC721ERC1155Ids(fromNFT, fromId, erc721Addresses[a]);
            for(uint256 b = 0; b < ids.length; b++){
                transferERC721(fromNFT, fromId, erc721Addresses[a], ids[b], toNFT, toId);
            }
        }

        transfer1155(fromNFT, fromId, toNFT, toId);
    }
    
     function transfer1155(address fromNFT,uint256 fromId,address toNFT,uint256 toId) private {
        address[] memory erc1155Addresses = getERC1155Tokens(fromNFT, fromId);
        for (uint256 a = 0; a < erc1155Addresses.length; a++) {
            uint256[] memory ids = getERC721ERC1155Ids(fromNFT, fromId, erc1155Addresses[a]);
            uint256[] memory tokenBalances = getERC1155TokenBalances(fromNFT, fromId, erc1155Addresses[a], ids);
            require(ids.length > 0 && ids.length == tokenBalances.length, "MagicLampWallet::transferERC1155: invalid parameters");
            for(uint256 b =0; b < ids.length; b++){
                transferERC1155(fromNFT, fromId, erc1155Addresses[a], ids[b], tokenBalances[b], toNFT, toId);
            }
        }
    }

    function swapERC20(address nft, uint256 id, address inToken, uint256 inTokenAmount, address outToken, address router, address to) 
    external  {
        onlyWalletOwner(nft, id);
        unlocked(nft, id);
        require(address(magicLampSwap) != address(0), "MagicLampWallet::swapERC20: invalid magiclamp swap");
        require(_erc20TokenBalances[nft][id][inToken] >= inTokenAmount, "MagicLampWallet::swapERC20: invalid amount");

        IERC20(inToken).approve(address(magicLampSwap), inTokenAmount);

        (, uint256 outTokenAmount) = magicLampSwap.swapERC20(
            // nft,
            // id,
            inToken, inTokenAmount, outToken, router, to);

        emit MagicLampWalletERC20Swapped(_msgSender(), nft, id, inToken, inTokenAmount, outToken, outTokenAmount, to);

        _subTokenBalance(nft, id, TOKEN_TYPE_ERC20, inToken, inTokenAmount);
    }

    function swapERC721(address nft, uint256 id, address inToken, uint256 inTokenId, address outToken, address router, address to)
    external  {
        onlyWalletOwner(nft, id);
        unlocked(nft, id);
        require(address(magicLampSwap) != address(0), "MagicLampWallet::swapERC721: invalid magiclamp swap");
        require(existsERC721ERC1155(nft, id, inToken, inTokenId), "MagicLampWallet::swapERC721: not existing token");

        IERC721(inToken).approve(address(magicLampSwap), inTokenId);

        uint256 outTokenId = magicLampSwap.swapERC721(
            // nft,
            // id,
            inToken, inTokenId, outToken, router, to);

        emit MagicLampWalletERC721Swapped(_msgSender(), nft, id, inToken, inTokenId, outToken, outTokenId, to);

        _popTokenId(nft, id, inToken, inTokenId);
    }

    function swapERC1155(
        address nft,
        uint256 id,
        address inToken,
        uint256 inTokenId,
        uint256 inTokenAmount,
        address outToken,
        uint256 outTokenId,
        address router,
        address to
    ) external  {
        onlyWalletOwner(nft, id);
        unlocked(nft, id);
        require(address(magicLampSwap) != address(0), "MagicLampWallet::swapERC1155: invalid magiclamp swap");
        require(existsERC721ERC1155(nft, id, inToken, inTokenId), "MagicLampWallet::swapERC1155: not existing token");
        require(_erc1155TokenBalances[nft][id][inToken][inTokenId] >= inTokenAmount, "MagicLampWallet::swapERC1155: invalid amount");

        IERC1155(inToken).setApprovalForAll(address(magicLampSwap), true);

        (, uint256 outTokenAmount) = magicLampSwap.swapERC1155(
            // nft,
            // id,
            inToken, inTokenId, inTokenAmount, outToken, outTokenId, router, to);

        emit MagicLampWalletERC1155Swapped(_msgSender(), nft, inToken, inTokenId, inTokenAmount, outToken, outTokenId, outTokenAmount, to);

        _subERC1155TokenBalance(nft, id, inToken, inTokenId, inTokenAmount);

        _popERC1155TokenId(nft, id, inToken, inTokenId);

        _popERC1155(nft, id, inToken, inTokenId);
    }

    function _popERC1155(address nft, uint256 id, address token, uint256 tokenId) private {
        uint256[] memory ids = _erc721ERC1155TokenIds[nft][id][token];

        if (_erc1155TokenBalances[nft][id][token][tokenId] == 0 && ids.length == 0) {
            delete _erc1155TokenBalances[nft][id][token][tokenId];
            delete _erc721ERC1155TokenIds[nft][id][token];

            _popToken(nft, id, TOKEN_TYPE_ERC1155, token);
        }
    }

    /**
     * @dev private function to add token balance
     */
    function _addTokenBalance(address nft, uint256 id, uint8 tokenType, address tokenAddress, uint256 tokenAmount) private {
        _erc20TokenBalances[nft][id][tokenAddress] = _erc20TokenBalances[nft][id][tokenAddress].add(tokenAmount);
        _putToken(nft, id, tokenType, tokenAddress);
    }

    /**
     * @dev private function to add erc1155 token balance
     */
    function _addERC1155TokenBalance(address nft, uint256 id, uint8 tokenType, address tokenAddress, uint256 tokenId, uint256 tokenAmount) private {
        _erc1155TokenBalances[nft][id][tokenAddress][tokenId] = _erc1155TokenBalances[nft][id][tokenAddress][tokenId].add(tokenAmount);
        _putToken(nft, id, tokenType, tokenAddress);
    }

    /**
     * @dev private function to sub token balance
     */
    function _subTokenBalance(address nft, uint256 id, uint8 tokenType, address tokenAddress, uint256 tokenAmount) private {
        require(_erc20TokenBalances[nft][id][tokenAddress] >= tokenAmount, "MagicLampWallet::_subTokenBalance: insufficient token amount");

        _erc20TokenBalances[nft][id][tokenAddress] = _erc20TokenBalances[nft][id][tokenAddress].sub(tokenAmount);

        if (_erc20TokenBalances[nft][id][tokenAddress] == 0) {
            delete _erc20TokenBalances[nft][id][tokenAddress];
            _popToken(nft, id, tokenType, tokenAddress);
        }
    }

    /**
     * @dev private function to sub erc1155 token balance
     */
    function _subERC1155TokenBalance(address nft, uint256 id, address tokenAddress, uint256 tokenId, uint256 tokenAmount) private {
        require(_erc1155TokenBalances[nft][id][tokenAddress][tokenId] >= tokenAmount, "MagicLampWallet::_subERC1155TokenBalance: insufficient token amount");

        _erc1155TokenBalances[nft][id][tokenAddress][tokenId] = _erc1155TokenBalances[nft][id][tokenAddress][tokenId].sub(tokenAmount);
    }

    /**
     * @dev private function to put a token id
     */
    function _putTokenId(address nft, uint256 id, address token, uint256 tokenId) private {
        uint256[] storage ids = _erc721ERC1155TokenIds[nft][id][token];
        ids.push(tokenId);
    }

    /**
     * @dev private function to put a token id to wallet in ERC1155
     */
    function _putERC1155TokenId(address nft, uint256 id, address token, uint256 tokenId) private {
        uint256[] storage ids = _erc721ERC1155TokenIds[nft][id][token];
        bool isExist;

        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                isExist = true;
            }
        }

        if (!isExist) {
            ids.push(tokenId);
        }
    }

    /**
     * @dev private function to pop a token id
     */
    function _popTokenId(address nft, uint256 id, address token, uint256 tokenId) private {
        uint256[] storage ids = _erc721ERC1155TokenIds[nft][id][token];

        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
            }
        }

        if (ids.length == 0) {
            delete _erc721ERC1155TokenIds[nft][id][token];
        }
    }

    /**
     * @dev private function to pop a token id from wallet in ERC1155
     */
    function _popERC1155TokenId(address nft, uint256 id, address token, uint256 tokenId) private {
        uint256 tokenBalance = _erc1155TokenBalances[nft][id][token][tokenId];

        if (tokenBalance <= 0) {
            delete _erc1155TokenBalances[nft][id][token][tokenId];
            _popTokenId(nft, id, token, tokenId);
        }
    }

     /**
     * @dev Adds token balance of wallet.
     */
    function addTokenBalance(address nft, uint256 id, uint8 tokenType, address token, uint256 amount) external  {
        exists(nft, id);
        require(_msgSender() != address(0));
        require(_msgSender() == address(nft));

        _addTokenBalance(nft, id, tokenType, token, amount);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns (bytes4) {
        return 0xbc197c81;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./MagicLampWalletEvents.sol";
import "./IMagicLampSwap.sol";

contract Wallet is MagicLampWalletEvents, Ownable{
    using SafeMath for uint256;

    struct Token {
        uint8 tokenType; // TOKEN_TYPE
        address tokenAddress;
    }

    // Token types
    // uint8 internal constant TOKEN_TYPE_BNB = 0;
    uint8 internal constant TOKEN_TYPE_ERC20 = 1;
    uint8 internal constant TOKEN_TYPE_ERC721 = 2;
    uint8 internal constant TOKEN_TYPE_ERC1155 = 3;

    IMagicLampSwap public magicLampSwap;

     // A list of NFTs which this contract supports wallet features
    address[] public nfts;

    // Mapping from Address -> bool
    mapping(address => bool) public nftExists;

    // Mapping from NFT -> ID -> Tokens
    mapping(address => mapping(uint256 => Token[])) internal _tokens;

     // Mapping from NFT -> ID -> Locked Time
    mapping(address => mapping(uint256 => uint256)) private _lockedTimestamps;

    function supportedNFT(address nft) internal view{
        require(nftExists[nft], "Unsupported NFT");
    }

    function onlyWalletOwner(address nft, uint256 id) internal view{
        require(nftExists[nft], "Unsupported NFT");
        require(
            IERC721(nft).ownerOf(id) == _msgSender(),
            "Only NFT owner can call"
        );
    
    }

    function exists(address nft, uint256 id) internal view{
        require(nftExists[nft], "Unsupported NFT");
        require(IERC721(nft).ownerOf(id) != address(0), "NFT does not exist");
    }

    function unlocked(address nft, uint256 id) internal view{
        require(_lockedTimestamps[nft][id] <= block.timestamp, "NFT is locked");
    }

    function tokenTypeERC20() external pure returns (uint8) {
        return TOKEN_TYPE_ERC20;
    }

    function tokenTypeERC721() external pure returns (uint8) {
        return TOKEN_TYPE_ERC721;
    }

    function tokenTypeERC1155() external pure returns (uint8) {
        return TOKEN_TYPE_ERC1155;
    }

    /**
     * @dev Checks if magicLamp has been locked.
     */
    function isLocked(address nft, uint256 id) external view returns (bool locked, uint256 endTime) {
        exists(nft, id);
        if (_lockedTimestamps[nft][id] <= block.timestamp) {
            locked = false;
        } else {
            locked = true;
            endTime = _lockedTimestamps[nft][id] - 1;
        }
    }

     function setMagicLampSwap(address newAddress) external onlyOwner {
        address priviousAddress = address(magicLampSwap);
        require(priviousAddress != newAddress, "MagicLampWallet::setMagicLampSwap: same address");

        magicLampSwap = IMagicLampSwap(newAddress);

        emit MagicLampWalletSwapChanged(priviousAddress, newAddress);
    }

        /**
     * @dev Gets token counts inside wallet
     */
    function getTokensCount(address nft, uint256 id)
    public view returns (uint256 erc20Count, uint256 erc721Count, uint256 erc1155Count) {
        exists(nft, id);
        Token[] memory tokens = _tokens[nft][id];

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == TOKEN_TYPE_ERC20) {
                erc20Count = erc20Count.add(1);
            } else if (token.tokenType == TOKEN_TYPE_ERC721) {
                erc721Count = erc721Count.add(1);
            } else if (token.tokenType == TOKEN_TYPE_ERC1155) {
                erc1155Count = erc1155Count.add(1);
            }
        }
    }

     /**
     * @dev Gets tokens by NFT
     */
    function getTokens(address nft, uint256 id) 
    external view returns (uint8[] memory tokenTypes, address[] memory tokenAddresses) {
        exists(nft, id) ;
        Token[] memory tokens = _tokens[nft][id];

        tokenTypes = new uint8[](tokens.length);
        tokenAddresses = new address[](tokens.length);

        for (uint256 i; i < tokens.length; i++) {
            tokenTypes[i] = tokens[i].tokenType;
            tokenAddresses[i] = tokens[i].tokenAddress;
        }
    }

     // Write functions

    function registerNFT(address tokenAddress) external onlyOwner {
        require(!nftExists[tokenAddress], "MagicLampWallet::registerNFT: already registered");

        nfts.push(tokenAddress);
        nftExists[tokenAddress] = true;

        emit MagicLampWalletNFTRegistered(tokenAddress);
    }

    function unregisterNFT(address tokenAddress) external onlyOwner {
        require(nftExists[tokenAddress], "MagicLampWallet::unregisterNFT: not found");

        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i] == tokenAddress) {
                nfts[i] = nfts[nfts.length.sub(1)];
                nfts.pop();
                delete nftExists[tokenAddress];
                emit MagicLampWalletNFTUnregistered(tokenAddress);
                break;
            }
        }
    }

     /**
     * @dev Locks wallet.
     */
    function lock(address nft, uint256 id, uint256 timeInSeconds) external  {
        onlyWalletOwner(nft, id);
        unlocked(nft, id);
        _lockedTimestamps[nft][id] = block.timestamp.add(timeInSeconds);

        emit MagicLampWalletLocked(_msgSender(), nft, id, block.timestamp, _lockedTimestamps[nft][id]);
    }

     /**
     * @dev Puts token(type, address)
     */
    function _putToken(address nft, uint256 id, uint8 tokenType, address tokenAddress) internal {
        Token[] storage tokens = _tokens[nft][id];
        bool _exists = false;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (
                tokens[i].tokenType == tokenType &&
                tokens[i].tokenAddress == tokenAddress
            ) {
                _exists = true;
                break;
            }
        }

        if (!_exists) {
            tokens.push(Token({tokenType: tokenType, tokenAddress: tokenAddress}));
        }
    }

    /**
     * @dev Pops token(type, address)
     */
    function _popToken(address nft, uint256 id, uint8 tokenType, address tokenAddress) internal {
        Token[] storage tokens = _tokens[nft][id];

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].tokenType == tokenType && tokens[i].tokenAddress == tokenAddress) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }

        if (tokens.length == 0) {
            delete _tokens[nft][id];
        }
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev custom add
     */
    function burn(uint256 burnQuantity) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
    address private _authorizedNewOwner;

    event OwnershipTransferAuthorization(address indexed authorizedAddress);
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
     * @dev Returns the address of the current authorized new owner.
     */
    function authorizedNewOwner() public view virtual returns (address) {
        return _authorizedNewOwner;
    }

    /**
     * @notice Authorizes the transfer of ownership from _owner to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeOwnership( ).
     * This authorization may be removed by another call to this function authorizing
     * the null address.
     *
     * @param authorizedAddress The address authorized to become the new owner.
     */
    function authorizeOwnershipTransfer(address authorizedAddress) external onlyOwner {
        _authorizedNewOwner = authorizedAddress;
        emit OwnershipTransferAuthorization(_authorizedNewOwner);
    }

    /**
     * @notice Transfers ownership of this contract to the _authorizedNewOwner.
     */
    function assumeOwnership() external {
        require(_msgSender() == _authorizedNewOwner, "Ownable: only the authorized new owner can accept ownership");
        emit OwnershipTransferred(_owner, _authorizedNewOwner);
        _owner = _authorizedNewOwner;
        _authorizedNewOwner = address(0);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * @param confirmAddress The address wants to give up ownership.
     */
    function renounceOwnership(address confirmAddress) public virtual onlyOwner {
        require(confirmAddress == _owner, "Ownable: confirm address is wrong");
        emit OwnershipTransferred(_owner, address(0));
        _authorizedNewOwner = address(0);
        _owner = address(0);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MagicLampWalletEvents {
    event MagicLampWalletNFTRegistered(
        address indexed tokenAddress
    );

    event MagicLampWalletNFTUnregistered(
        address indexed tokenAddress
    );

    event MagicLampWalletSwapChanged(
        address indexed previousMagicLampSwap,
        address indexed newMagicLampSwap
    );

    event MagicLampWalletLocked(
        address indexed owner,
        address indexed nft,
        uint256 id,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event MagicLampWalletOpened(
        address indexed owner,
        address indexed nft,
        uint256 id
    );

    event MagicLampWalletClosed(
        address indexed owner,
        address indexed nft,
        uint256 id
    );

    event MagicLampWalletBNBDeposited(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc20Token,
        uint256 amount
    );

    event MagicLampWalletBNBWithdrawn(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc20Token,
        uint256 amount,
        address to
    );

    event MagicLampWalletBNBTransferred(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc20Token,
        uint256 amount,
        address indexed toNft,
        uint256 toId
    );

    event MagicLampWalletERC20Deposited(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc20Token,
        uint256 amount
    );

    event MagicLampWalletERC20Withdrawn(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc20Token,
        uint256 amount,
        address to
    );

    event MagicLampWalletERC20Transferred(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc20Token,
        uint256 amount,
        address indexed toNft,
        uint256 toId
    );

    event MagicLampWalletERC721Deposited(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId
    );

    event MagicLampWalletERC721Withdrawn(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId,
        address to
    );

    event MagicLampWalletERC721Transferred(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId,
        address indexed toNft,
        uint256 toId
    );

    event MagicLampWalletERC1155Deposited(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount
    );

    event MagicLampWalletERC1155Withdrawn(
        address indexed owner,
        address indexed nft,
        //uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount,
        address indexed to
    );

    event MagicLampWalletERC1155Transferred(
        address indexed owner,
        address indexed nft,
       // uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount,
        address indexed toNft,
        uint256 toId
    );

    event MagicLampWalletERC20Swapped(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 outAmount,
        address indexed to
    );

    event MagicLampWalletERC721Swapped(
        address indexed owner,
        address indexed nft,
        uint256 id,
        address inToken,
        uint256 inTokenId,
        address outToken,
        uint256 outTokenId,
        address indexed to
    );

    event MagicLampWalletERC1155Swapped(
        address indexed owner,
        address indexed nft,
        //uint256 id,
        address inToken,
        uint256 inTokenId,
        uint256 inAmount,
        address outToken,
        uint256 outTokenId,
        uint256 outTokenAmount,
        address indexed to
    );
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMagicLampSwap {
    function swap(uint8 inTokenType, address inToken, uint256 inTokenId, uint256 inAmount, uint8 outTokenType, address outToken, uint256 outTokenId, address router, address to) external returns(uint256, uint256);
    function swapERC20(address inToken, uint256 inAmount, address outToken, address router, address to) external returns(uint256, uint256);
    function swapERC721(address inToken, uint256 inTokenId, address outToken, address router, address to) external returns(uint256);
    function swapERC1155(address inToken, uint256 inTokenId, uint256 inAmount, address outToken, uint256 outTokenId, address router, address to) external returns(uint256, uint256);
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