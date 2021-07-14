// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MagicLampWalletBase.sol";
import "./MagicLampWalletEvents.sol";

import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./ERC165.sol";
import "./IBEP20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract MagicLampWallet is MagicLampWalletBase, MagicLampWalletEvents, ERC165, IERC1155Receiver, IERC721Receiver {
    using SafeMath for uint256;

    function tokenTypeBEP20() external pure returns (uint8) {
        return _TOKEN_TYPE_BEP20;
    }

    function tokenTypeERC721() external pure returns (uint8) {
        return _TOKEN_TYPE_ERC721;
    }

    function tokenTypeERC1155() external pure returns (uint8) {
        return _TOKEN_TYPE_ERC1155;
    }

    /**
     * @dev Checks if magicLamp has been locked.
     */
    function isLocked(address host, uint256 id) external view returns (bool locked, uint256 endTime) {
        if (_lockedTimestamps[host][id] <= block.timestamp) {
            locked = false;
        } else {
            locked = true;
            endTime = _lockedTimestamps[host][id] - 1;
        }
    }

    /**
     * @dev Gets token counts inside wallet, including BNB
     */
    function getTokensCount(address host, uint256 id)
    public view returns (uint256 bnbCount, uint256 bep20Count, uint256 erc721Count, uint256 erc1155Count) {
        if (_bnbBalances[host][id] > 0) {
            bnbCount = 1;
        }

        Token[] memory tokens = _tokens[host][id];

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == _TOKEN_TYPE_BEP20) {
                bep20Count++;
            } else if (token.tokenType == _TOKEN_TYPE_ERC721) {
                erc721Count++;
            } else if (token.tokenType == _TOKEN_TYPE_ERC1155) {
                erc1155Count++;
            }
        }
    }

    /**
     * @dev Gets tokens for wallet
     */
    function getTokens(address host, uint256 id) 
    external view returns (uint8[] memory tokenTypes, address[] memory tokenAddresses) {
        Token[] memory tokens = _tokens[host][id];

        tokenTypes = new uint8[](tokens.length);
        tokenAddresses = new address[](tokens.length);

        for (uint256 i; i < tokens.length; i++) {
            tokenTypes[i] = tokens[i].tokenType;
            tokenAddresses[i] = tokens[i].tokenAddress;
        }
    }

    /**
     * @dev Supports host(ERC721 token address) for wallet features
     */
    function support(address host) external onlyOwner {
        require(!walletFeatureHosted[host], "MagicLampWallet::support: already supported");

        walletFeatureHosts.push(host);
        walletFeatureHosted[host] = true;

        emit MagicLampWalletSupported(host);
    }

    /**
     * @dev Unsupports host(ERC721 token address) for wallet features
     */
    function unsupport(address host) external onlyOwner {
        require(walletFeatureHosted[host], "MagicLampWallet::unsupport: not found");

        for (uint256 i = 0; i < walletFeatureHosts.length; i++) {
            if (walletFeatureHosts[i] == host) {
                walletFeatureHosts[i] = walletFeatureHosts[walletFeatureHosts.length - 1];
                walletFeatureHosts.pop();
                delete walletFeatureHosted[host];
                emit MagicLampWalletUnsupported(host);
                break;
            }
        }
    }

    /**
     * @dev Gets 
     */
    function isSupported(address host) external view returns(bool) {
        return walletFeatureHosted[host];
    }

    /**
     * @dev Locks wallet
     */
    function lock(address host, uint256 id, uint256 timeInSeconds) external  {
        _onlyWalletOwner(host, id);
        _lockedTimestamps[host][id] = block.timestamp.add(timeInSeconds);

        emit MagicLampWalletLocked(_msgSender(), host, id, block.timestamp, _lockedTimestamps[host][id]);
    }

    /**
     * @dev Checks if token exists inside wallet
     */
    function existsERC721ERC1155(address host, uint256 id, address token, uint256 tokenId) public view returns (bool) {
        uint256[] memory ids = _erc721ERC1155TokenIds[host][id][token];

        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Gets BNB balance
     */
    function getBNB(address host, uint256 id) 
    public view  returns (uint256 balance) {
        balance = _bnbBalances[host][id];
    }

    /**
     * @dev Deposits BNB tokens into wallet
     */
    function depositBNB(address host, uint256 id, uint256 amount) external payable {
        _exists(host, id);
        require(amount > 0 && amount == msg.value, "MagicLampWallet::depositBNB: invalid amount");
        
        _bnbBalances[host][id] = _bnbBalances[host][id].add(msg.value);

        emit MagicLampWalletBNBDeposited(_msgSender(), host, id, msg.value);
    }

    /**
     * @dev Withdraws BNB tokens from wallet
     */
    function withdrawBNB(address host, uint256 id, uint256 amount) public {
        _onlyWalletOwnerOrHost(host, id);
        _unlocked(host, id);

        address to = IERC721(host).ownerOf(id);
        payable(to).transfer(amount);
        _bnbBalances[host][id] = _bnbBalances[host][id].sub(amount);

        emit MagicLampWalletBNBWithdrawn(_msgSender(), host, id, amount, to);
    }

    /**
     * @dev Transfers BNB tokens from wallet into another wallet
     */
    function transferBNB(address fromHost, uint256 fromId, uint256 amount, address toHost, uint256 toId) public  {
        _onlyWalletOwner(fromHost, fromId);
        _unlocked(fromHost, fromId);
        _exists(toHost, toId);
        require(fromHost != toHost || fromId != toId, "MagicLampWallet::transferBNB: same wallet");

        _bnbBalances[fromHost][fromId] = _bnbBalances[fromHost][fromId].sub(amount);
        _bnbBalances[toHost][toId] = _bnbBalances[toHost][toId].add(amount);

        emit MagicLampWalletBNBTransferred(_msgSender(), fromHost, fromId, amount, toHost, toId);
    }

    /**
     * @dev Gets BEP20 token info
     */
    function getBEP20Tokens(address host, uint256 id) 
    public view  returns (address[] memory addresses, uint256[] memory tokenBalances) {
        Token[] memory tokens = _tokens[host][id];
        (, uint256 bep20Count, , ) = getTokensCount(host, id);
        addresses = new address[](bep20Count);
        tokenBalances = new uint256[](bep20Count);
        uint256 j = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == _TOKEN_TYPE_BEP20) {
                addresses[j] = token.tokenAddress;
                tokenBalances[j] = _bep20TokenBalances[host][id][token.tokenAddress];
                j++;
            }
        }
    }

    /**
     * @dev Gets ERC721 token info
     */
    function getERC721Tokens(address host, uint256 id) 
    public view  returns (address[] memory addresses, uint256[] memory tokenBalances) {
        Token[] memory tokens = _tokens[host][id];
        (,, uint256 erc721Count, ) = getTokensCount(host, id);
        addresses = new address[](erc721Count);
        tokenBalances = new uint256[](erc721Count);
        uint256 j = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == _TOKEN_TYPE_ERC721) {
                addresses[j] = token.tokenAddress;
                tokenBalances[j] = _erc721ERC1155TokenIds[host][id][token.tokenAddress].length;
                j++;
            }
        }
    }

    /**
     * @dev Gets ERC721 or ERC1155 IDs
     */
    function getERC721ERC1155IDs(address host, uint256 id, address token) public view  returns (uint256[] memory) {
        return _erc721ERC1155TokenIds[host][id][token];
    }

    /**
     * @dev Gets ERC1155 token addresses info
     */
    function getERC1155Tokens(address host, uint256 id) public view returns (address[] memory addresses) {
        Token[] memory tokens = _tokens[host][id];
        (,,, uint256 erc1155Count) = getTokensCount(host, id);

        addresses = new address[](erc1155Count);
        uint256 j = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (token.tokenType == _TOKEN_TYPE_ERC1155) {
                addresses[j] = token.tokenAddress;
                j++;
            }
        }
    }

    /**
     * @dev Gets ERC1155 token balances by IDs
     */
    function getERC1155TokenBalances(address host, uint256 id, address token, uint256[] memory tokenIds)
    public view returns (uint256[] memory tokenBalances) {
        tokenBalances = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenBalances[i] = _erc1155TokenBalances[host][id][token][tokenIds[i]];
        }
    }

    /**
     * @dev Deposits BEP20 tokens into wallet.
     */
    function depositBEP20(address host, uint256 id, address[] memory tokens, uint256[] memory amounts) external {
        _exists(host, id);
        require(tokens.length > 0 && tokens.length == amounts.length, "MagicLampWallet::depositBEP20: invalid parameters");

        for (uint256 i = 0; i < tokens.length; i++) {
            IBEP20 token = IBEP20(tokens[i]);
            uint256 prevBalance = token.balanceOf(address(this));
            token.transferFrom(_msgSender(), address(this), amounts[i]);
            uint256 receivedAmount = token.balanceOf(address(this)).sub(prevBalance);
            _addBEP20TokenBalance(host, id, tokens[i], receivedAmount);

            emit MagicLampWalletBEP20Deposited(_msgSender(), host, id, tokens[i], receivedAmount);
        }
    }

    /**
     * @dev Withdraws BEP20 tokens from wallet.
     */
    function withdrawBEP20(address host, uint256 id, address[] memory tokens, uint256[] memory amounts)
    public  {
        _onlyWalletOwnerOrHost(host, id);
        _unlocked(host, id);
        require(tokens.length > 0 && tokens.length == amounts.length, "MagicLampWallet::withdrawBEP20: invalid parameters");

        address to = IERC721(host).ownerOf(id);

        for (uint256 i = 0; i < tokens.length; i++) {
            IBEP20 token = IBEP20(tokens[i]);
            token.transfer(to, amounts[i]);
            _subBEP20TokenBalance(host, id, tokens[i], amounts[i]);

            emit MagicLampWalletBEP20Withdrawn(_msgSender(), host, id, tokens[i], amounts[i], to);
        }
    }

    /**
     * @dev Transfers BEP20 tokens from wallet into another wallet.
     */
    function transferBEP20(address fromHost, uint256 fromId, address token, uint256 amount, address toHost, uint256 toId)
    public  {
        _onlyWalletOwner(fromHost, fromId);
        _unlocked(fromHost, fromId);
        _exists(toHost, toId);
        require(fromHost != toHost || fromId != toId, "MagicLampWallet::transferBEP20: same wallet");
        
        _subBEP20TokenBalance(fromHost, fromId, token, amount);
        _addBEP20TokenBalance(toHost, toId, token, amount);

        emit MagicLampWalletBEP20Transferred(_msgSender(), fromHost, fromId, token, amount, toHost, toId);
    }

    /**
     * @dev Deposits ERC721 tokens into wallet.
     */
    function depositERC721(address host, uint256 id, address token, uint256[] memory tokenIds) external  {
        _exists(host, id);

        IERC721 iToken = IERC721(token);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(token != host || tokenIds[i] != id, "MagicLampWallet::depositERC721: self deposit");

            iToken.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
            _putTokenId(host, id, _TOKEN_TYPE_ERC721, token, tokenIds[i]);

            emit MagicLampWalletERC721Deposited(_msgSender(), host, id, token, tokenIds[i]);
        }
    }

    /**
     * @dev Withdraws ERC721 token from wallet.
     */
    function withdrawERC721(address host, uint256 id, address token, uint256[] memory tokenIds)
    public {
        _onlyWalletOwnerOrHost(host, id);
        _unlocked(host, id);
        
        IERC721 iToken = IERC721(token);
        address to = IERC721(host).ownerOf(id);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            iToken.safeTransferFrom(address(this), to, tokenIds[i]);
            _popTokenId(host, id, _TOKEN_TYPE_ERC721, token, tokenIds[i]);

            emit MagicLampWalletERC721Withdrawn(_msgSender(), host, id, token, tokenIds[i], to);
        }
    }

    /**
     * @dev Transfers ERC721 tokens from wallet to another wallet.
     */
    function transferERC721(address fromHost, uint256 fromId, address token, uint256[] memory tokenIds, address toHost, uint256 toId) 
    public {
        _onlyWalletOwner(fromHost, fromId);
        _unlocked(fromHost, fromId);
        _exists(toHost, toId);
        require(fromHost != toHost || fromId != toId, "MagicLampWallet::transferERC721: same wallet");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _popTokenId(fromHost, fromId, _TOKEN_TYPE_ERC721, token, tokenIds[i]);
            _putTokenId(toHost, toId, _TOKEN_TYPE_ERC721, token, tokenIds[i]);

            emit MagicLampWalletERC721Transferred(_msgSender(), fromHost, fromId, token, tokenIds[i], toHost, toId);
        }
    }

    /**
     * @dev Deposits ERC1155 token into wallet.
     */
    function depositERC1155(address host, uint256 id, address token, uint256[] memory tokenIds, uint256[] memory amounts) 
    external {
        _exists(host, id);
        IERC1155 iToken = IERC1155(token);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            iToken.safeTransferFrom(_msgSender(), address(this), tokenIds[i], amounts[i], bytes(""));
            _addERC1155TokenBalance(host, id, token, tokenIds[i], amounts[i]);

            emit MagicLampWalletERC1155Deposited(_msgSender(), host, id, token, tokenIds[i], amounts[i]);
        }
    }

    /**
     * @dev Withdraws ERC1155 token from wallet.
     */
    function withdrawERC1155(address host, uint256 id, address token, uint256[] memory tokenIds, uint256[] memory amounts)
    public {
        _onlyWalletOwnerOrHost(host, id);
        _unlocked(host, id);
        IERC1155 iToken = IERC1155(token);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];
            address to = IERC721(host).ownerOf(id);
            iToken.safeTransferFrom(address(this), to, tokenId, amount, bytes(""));            
            _subERC1155TokenBalance(host, id, token, tokenId, amount);

            emit MagicLampWalletERC1155Withdrawn(_msgSender(), host, id, token, tokenId, amount, to);
        }
    }

    /**
     * @dev Transfers ERC1155 token from wallet to another wallet.
     */
    function transferERC1155(address fromHost, uint256 fromId, address token, uint256[] memory tokenIds, uint256[] memory amounts, address toHost, uint256 toId)
    public {
        _onlyWalletOwner(fromHost, fromId);
        _unlocked(fromHost, fromId); 
        require(fromHost != toHost || fromId != toId, "MagicLampWallet::transferERC1155: same wallet");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];
            _subERC1155TokenBalance(fromHost, fromId, token, tokenId, amount);
            _addERC1155TokenBalance(toHost, toId, token, tokenId, amount);

            emit MagicLampWalletERC1155Transferred(_msgSender(), fromHost, fromId, token, tokenId, amount, toHost, toId);
        }
    }

    /**
     * @dev Withdraws all of tokens from wallet.
     */
    function withdrawAll(address host, uint256 id) external {
        uint256 bnb = getBNB(host, id);
        if (bnb > 0) {
            withdrawBNB(host, id, bnb);
        }

        (address[] memory bep20Addresses, uint256[] memory bep20Balances) = getBEP20Tokens(host, id);
        if (bep20Addresses.length > 0) {
            withdrawBEP20(host, id, bep20Addresses, bep20Balances);
        }

        (address[] memory erc721Addresses, ) = getERC721Tokens(host, id);
        for (uint256 a = 0; a < erc721Addresses.length; a++) {
            uint256[] memory ids = _erc721ERC1155TokenIds[host][id][erc721Addresses[a]];
            withdrawERC721(host, id, erc721Addresses[a], ids);
        }

        address[] memory erc1155Addresses = getERC1155Tokens(host, id);
        for (uint256 a = 0; a < erc1155Addresses.length; a++) {
            uint256[] memory ids = _erc721ERC1155TokenIds[host][id][erc1155Addresses[a]];
            uint256[] memory tokenBalances = getERC1155TokenBalances(host, id, erc1155Addresses[a], ids);
            withdrawERC1155(host, id, erc1155Addresses[a], ids, tokenBalances);
        }
    }

    /**
     * @dev Transfers all of tokens to another wallet.
     */
    function transferAll(address fromHost, uint256 fromId, address toHost, uint256 toId) external {
        uint256 bnb = getBNB(fromHost, fromId);
        if (bnb > 0) {
            transferBNB(fromHost, fromId, bnb, toHost, toId);
        }

        (address[] memory bep20Addresses, uint256[] memory bep20Balances ) = getBEP20Tokens(fromHost, fromId);
        for(uint256 i = 0; i < bep20Addresses.length; i++){
            transferBEP20(fromHost, fromId, bep20Addresses[i], bep20Balances[i], toHost, toId);
        }

        (address[] memory erc721Addresses, ) = getERC721Tokens(fromHost, fromId);
        for (uint256 a = 0; a < erc721Addresses.length; a++) {
            uint256[] memory ids = getERC721ERC1155IDs(fromHost, fromId, erc721Addresses[a]);
            transferERC721(fromHost, fromId, erc721Addresses[a], ids, toHost, toId);
        }

        address[] memory erc1155Addresses = getERC1155Tokens(fromHost, fromId);
        for (uint256 a = 0; a < erc1155Addresses.length; a++) {
            uint256[] memory ids = getERC721ERC1155IDs(fromHost, fromId, erc1155Addresses[a]);
            uint256[] memory tokenBalances = getERC1155TokenBalances(fromHost, fromId, erc1155Addresses[a], ids);
            transferERC1155(fromHost, fromId, erc1155Addresses[a], ids, tokenBalances, toHost, toId);
        }
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
import "./MagicLampWalletStorage.sol";

contract MagicLampWalletBase is MagicLampWalletStorage, Ownable {
    using SafeMath for uint256;

    function _onlyWalletOwner(address host, uint256 id) internal view {
        require(walletFeatureHosted[host], "Unsupported host");
        require(
            IERC721(host).ownerOf(id) == _msgSender(),
            "Only wallet owner can call"
        );
    }

    function _exists(address host, uint256 id) internal view {
        require(walletFeatureHosted[host], "Unsupported host");
        require(IERC721(host).ownerOf(id) != address(0), "NFT does not exist");
    }

    function _unlocked(address host, uint256 id) internal view {
        require(_lockedTimestamps[host][id] <= block.timestamp, "Wallet is locked");
    }

    function _onlyWalletOwnerOrHost(address host, uint256 id) internal view {
        require(walletFeatureHosted[host], "Unsupported host");
        require(
            IERC721(host).ownerOf(id) == _msgSender() || host == _msgSender(),
            "Only wallet owner or host can call"
        );
    }

    /**
     * @dev Puts token(type, address)
     */
    function _putToken(address host, uint256 id, uint8 tokenType, address token) internal {
        Token[] storage tokens = _tokens[host][id];

        uint256 i = 0;
        for (; i < tokens.length && (tokens[i].tokenType != tokenType || tokens[i].tokenAddress != token); i++) {
        }

        if (i == tokens.length) {
            tokens.push(Token({tokenType: tokenType, tokenAddress: token}));
        }
    }

    /**
     * @dev Pops token(type, address)
     */
    function _popToken(address host, uint256 id, uint8 tokenType, address token) internal {
        Token[] storage tokens = _tokens[host][id];

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].tokenType == tokenType && tokens[i].tokenAddress == token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                if (tokens.length == 0) {
                    delete _tokens[host][id];
                }
                return;
            }
        }        
        require(false, "Not found token");
    }

    /**
     * @dev Puts a token id
     */
    function _putTokenId(address host, uint256 id, uint8 tokenType, address token, uint256 tokenId) internal {
        if (_erc721ERC1155TokenIds[host][id][token].length == 0) {
            _putToken(host, id, tokenType, token);
        }
        _erc721ERC1155TokenIds[host][id][token].push(tokenId);
    }

    /**
     * @dev Pops a token id
     */
    function _popTokenId(address host, uint256 id, uint8 tokenType, address token, uint256 tokenId) internal {
        uint256[] storage ids = _erc721ERC1155TokenIds[host][id][token];

        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
                if (ids.length == 0) {
                    delete _erc721ERC1155TokenIds[host][id][token];
                    _popToken(host, id, tokenType, token);
                }
                return;
            }
        }
        require(false, "Not found token id");
    }

    /**
     * @dev Adds token balance
     */
    function _addBEP20TokenBalance(address host, uint256 id, address token, uint256 amount) internal {
        if (amount == 0) return;
        if (_bep20TokenBalances[host][id][token] == 0) {
            _putToken(host, id, _TOKEN_TYPE_BEP20, token);
        }
        _bep20TokenBalances[host][id][token] = _bep20TokenBalances[host][id][token].add(amount);
    }

    /**
     * @dev Subs token balance
     */
    function _subBEP20TokenBalance(address host, uint256 id, address token, uint256 amount) internal {
        if (amount == 0) return;
        _bep20TokenBalances[host][id][token] = _bep20TokenBalances[host][id][token].sub(amount);
        if (_bep20TokenBalances[host][id][token] == 0) {
            _popToken(host, id, _TOKEN_TYPE_BEP20, token);
        }
    }

    /**
     * @dev Adds ERC1155 token balance
     */
    function _addERC1155TokenBalance(address host, uint256 id, address token, uint256 tokenId, uint256 amount) internal {
        if (amount == 0) return;
        if (_erc1155TokenBalances[host][id][token][tokenId] == 0) {
            _putTokenId(host, id, _TOKEN_TYPE_ERC1155, token, tokenId);
        }
        _erc1155TokenBalances[host][id][token][tokenId] = _erc1155TokenBalances[host][id][token][tokenId].add(amount);
    }

    /**
     * @dev Subs ERC1155 token balance
     */
    function _subERC1155TokenBalance(address host, uint256 id, address token, uint256 tokenId, uint256 amount) internal {
        if (amount == 0) return;
        _erc1155TokenBalances[host][id][token][tokenId] = _erc1155TokenBalances[host][id][token][tokenId].sub(amount);
        if (_erc1155TokenBalances[host][id][token][tokenId] == 0) {
            _popTokenId(host, id, _TOKEN_TYPE_ERC1155, token, tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MagicLampWalletEvents {
    event MagicLampWalletSupported(
        address indexed host
    );

    event MagicLampWalletUnsupported(
        address indexed host
    );

    event MagicLampWalletSwapChanged(
        address indexed previousMagicLampSwap,
        address indexed newMagicLampSwap
    );

    event MagicLampWalletLocked(
        address indexed owner,
        address indexed host,
        uint256 id,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event MagicLampWalletOpened(
        address indexed owner,
        address indexed host,
        uint256 id
    );

    event MagicLampWalletClosed(
        address indexed owner,
        address indexed host,
        uint256 id
    );

    event MagicLampWalletBNBDeposited(
        address indexed owner,
        address indexed host,
        uint256 id,
        uint256 amount
    );

    event MagicLampWalletBNBWithdrawn(
        address indexed owner,
        address indexed host,
        uint256 id,
        uint256 amount,
        address to
    );

    event MagicLampWalletBNBTransferred(
        address indexed owner,
        address indexed host,
        uint256 id,
        uint256 amount,
        address indexed toHost,
        uint256 toId
    );

    event MagicLampWalletBEP20Deposited(
        address indexed owner,
        address indexed host,
        uint256 id,
        address bep20Token,
        uint256 amount
    );

    event MagicLampWalletBEP20Withdrawn(
        address indexed owner,
        address indexed host,
        uint256 id,
        address bep20Token,
        uint256 amount,
        address to
    );

    event MagicLampWalletBEP20Transferred(
        address indexed owner,
        address indexed host,
        uint256 id,
        address bep20Token,
        uint256 amount,
        address indexed toHost,
        uint256 toId
    );

    event MagicLampWalletERC721Deposited(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId
    );

    event MagicLampWalletERC721Withdrawn(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId,
        address to
    );

    event MagicLampWalletERC721Transferred(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc721Token,
        uint256 erc721TokenId,
        address indexed toHost,
        uint256 toId
    );

    event MagicLampWalletERC1155Deposited(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount
    );

    event MagicLampWalletERC1155Withdrawn(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount,
        address indexed to
    );

    event MagicLampWalletERC1155Transferred(
        address indexed owner,
        address indexed host,
        uint256 id,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint256 amount,
        address indexed toHost,
        uint256 toId
    );

    event MagicLampWalletBEP20Swapped(
        address indexed owner,
        address indexed host,
        uint256 id,
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 outAmount,
        address indexed to
    );

    event MagicLampWalletERC721Swapped(
        address indexed owner,
        address indexed host,
        uint256 id,
        address inToken,
        uint256 inTokenId,
        address outToken,
        uint256 outTokenId,
        address indexed to
    );

    event MagicLampWalletERC1155Swapped(
        address indexed owner,
        address indexed host,
        uint256 id,
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
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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

contract MagicLampWalletStorage {
    struct Token {
        uint8 tokenType; // TOKEN_TYPE
        address tokenAddress;
    }

    // Token types
    uint8 internal constant _TOKEN_TYPE_BEP20 = 1;
    uint8 internal constant _TOKEN_TYPE_ERC721 = 2;
    uint8 internal constant _TOKEN_TYPE_ERC1155 = 3;
  
    // Mapping from Host -> ID -> Token(ERC721 or ERC1155) -> IDs
    mapping(address => mapping(uint256 => mapping(address => uint256[]))) internal _erc721ERC1155TokenIds;

    // Mapping from Host -> ID -> Token(BEP20) -> Balance
    mapping(address => mapping(uint256 => mapping(address => uint256))) internal _bep20TokenBalances;

    // Mapping from Host -> ID -> Token(ERC1155) -> Token ID -> Balance
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) internal _erc1155TokenBalances;

    // Mapping from Host -> ID -> Token(BNB) -> Balance
    mapping(address => mapping(uint256 => uint256)) internal _bnbBalances;

    address public magicLampSwap;

    // List of ERC721 tokens which wallet features get supported
    address[] public walletFeatureHosts;

    // Mapping from Host -> bool
    mapping(address => bool) public walletFeatureHosted;

    // Mapping from Host -> ID -> Tokens
    mapping(address => mapping(uint256 => Token[])) internal _tokens;

    // Mapping from Host -> ID -> Locked Time
    mapping(address => mapping(uint256 => uint256)) internal _lockedTimestamps;
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