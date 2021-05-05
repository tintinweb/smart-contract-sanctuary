// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./ERC165.sol";
import './Events721.sol';
import './Ownable.sol';

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function exists(uint256 tokenId) external view returns (bool);
    function approve(address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IAPYMONPACK {
    function isLocked(uint256 eggId) external view returns (bool locked, uint256 endTime);
    function isOpened(uint256 eggId) external view returns (bool);
}

interface ISwap {
    function swapErc721(
        uint256 eggId,
        address inToken,
        uint256 inId,
        address outToken,
        uint8 router,
        address to
    ) external;
}

contract ApymonPack721 is ERC165, IERC721Receiver, Context, Events721, Ownable {

    // Mapping from egg ID -> tokens
    mapping(uint256 => address[]) private _insideTokens;

    // Mapping from egg ID -> token(erc721) -> ids
    mapping(uint256 => mapping(address => uint256[])) private _insideTokenIds;

    IERC721 public _apymon;
    IAPYMONPACK public _apymonPack;

    ISwap public _swap;

    modifier onlyEggOwner(uint256 eggId) {
        require(_apymon.exists(eggId));
        require(_apymon.ownerOf(eggId) == msg.sender);
        _;
    }

    modifier unlocked(uint256 eggId) {
        (bool locked, ) = _apymonPack.isLocked(eggId);
        require(!locked, "Egg has been locked.");
        _;
    }

    modifier opened(uint256 eggId) {
        require(_apymonPack.isOpened(eggId), "Egg has been closed");
        _;
    }

    constructor() {
        _apymon = IERC721(0x9C008A22D71B6182029b694B0311486e4C0e53DB);
        _apymonPack = IAPYMONPACK(0x3dFCB488F6e96654e827Ab2aB10a463B9927d4f9);
    }

    // View functions

    /**
     * @dev check if egg token id exists in egg.
     */
    function existsId(
        uint256 eggId,
        address token,
        uint256 id
    ) public view returns (bool) {
        uint256[] memory ids = _insideTokenIds[eggId][token];

        for (uint256 i; i < ids.length; i++) {
            if (ids[i] == id) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev check if tokenId exists in egg
     */
    function getInsideTokensCount(
        uint256 eggId
    ) public view opened(eggId) returns (
        uint256 erc721Len
    ) {
        return _insideTokens[eggId].length;
    }

    /**
     * @dev get ERC721 token info
     */
    function getERC721Tokens(
        uint256 eggId
    ) public view opened(eggId) returns (
        address[] memory addresses,
        uint256[] memory tokenBalances
    ) {
        address[] memory tokens = _insideTokens[eggId];
        uint256 erc721Len = tokens.length;
        
        tokenBalances = new uint256[](erc721Len);
        addresses = new address[](erc721Len);
        uint256 j;

        for (uint256 i; i < tokens.length; i++) {
            addresses[j] = tokens[i];
            tokenBalances[j] = _insideTokenIds[eggId][tokens[i]].length;
            j++;
        }
    }

    /**
     * @dev get ERC721 ids
     */
    function getTokenIds(
        uint256 eggId,
        address insideToken
    ) public view opened(eggId) returns (uint256[] memory) {
        return _insideTokenIds[eggId][insideToken];
    }

    // Write functions

    function setSwap(address swap) external onlyOwner {
        _swap = ISwap(swap);
    }

    function setApymonPack(address _pack) external onlyOwner {
        _apymonPack = IAPYMONPACK(_pack);
    }

    /**
     * @dev deposit erc721 tokens into egg.
     */
    function depositErc721IntoEgg(
        uint256 eggId,
        address token,
        uint256[] memory tokenIds
    ) external {
        require(token != address(0));

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                token != address(_apymon) ||
                (token == address(_apymon) && eggId != tokenIds[i])
            );
            IERC721 iToken = IERC721(token);
            
            iToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            _putInsideTokenId(
                eggId,
                token,
                tokenIds[i]
            );

            if (_apymonPack.isOpened(eggId)) {
                emit DepositedErc721IntoEgg(
                    eggId,
                    msg.sender,
                    token,
                    tokenIds[i]
                );
            }
        }

        _putTokenIntoEgg(
            eggId,
            token
        );
    }

    /**
     * @dev withdraw erc721 token from egg.
     */
    function withdrawErc721FromEgg(
        uint256 eggId,
        address token,
        uint256[] memory tokenIds,
        address to
    ) public onlyEggOwner(eggId) unlocked(eggId) opened(eggId) {
        require(token != address(0));
        IERC721 iToken = IERC721(token);

        for (uint256 i; i < tokenIds.length; i++) {
            address tokenOwner = iToken.ownerOf(tokenIds[i]);

            require(tokenOwner == address(this));

            iToken.safeTransferFrom(
                tokenOwner,
                to,
                tokenIds[i]
            );

            _popInsideTokenId(
                eggId,
                token,
                tokenIds[i]
            );

            emit WithdrewErc721FromEgg(
                eggId,
                msg.sender,
                token,
                tokenIds[i],
                to
            );
        }

        uint256[] memory ids = _insideTokenIds[eggId][token];

        if (ids.length == 0) {
            _popTokenFromEgg(
                eggId,
                token
            );
        }
    }

    /**
     * @dev send erc721 tokens from my egg to another egg.
     */
    function sendErc721(
        uint256 fromEggId,
        address token,
        uint256[] memory tokenIds,
        uint256 toEggId
    ) public onlyEggOwner(fromEggId) unlocked(fromEggId) opened(fromEggId) {
        require(fromEggId != toEggId);
        require(token != address(0));
        require(_apymon.exists(toEggId));

        for (uint256 i; i < tokenIds.length; i++) {
            _popInsideTokenId(
                fromEggId,
                token,
                tokenIds[i]
            );

            _putInsideTokenId(
                toEggId,
                token,
                tokenIds[i]
            );

            emit SentErc721(
                fromEggId,
                msg.sender,
                token,
                tokenIds[i],
                toEggId
            );
        }

        uint256[] memory ids = _insideTokenIds[fromEggId][token];

        if (ids.length == 0) {
            _popTokenFromEgg(
                fromEggId,
                token
            );
        }

        _putTokenIntoEgg(
            toEggId,
            token
        );
    }

    function swapErc721(
        uint256 eggId,
        address inToken,
        uint256 inId,
        address outToken,
        uint8 router,
        address to
    ) external onlyEggOwner(eggId) unlocked(eggId) opened(eggId) {
        require(address(_swap) != address(0));
        require(existsId(eggId, inToken, inId));
        
        IERC721(inToken).approve(address(_swap), inId);

        _swap.swapErc721(
            eggId,
            inToken,
            inId,
            outToken,
            router,
            to
        );
        emit SwapedErc721(
            msg.sender,
            eggId,
            inToken,
            inId,
            outToken,
            to
        );

        _popInsideTokenId(
            eggId,
            inToken,
            inId
        );
    }

    /**
     * @dev private function to put a token id to egg
     */
    function _putInsideTokenId(
        uint256 eggId,
        address token,
        uint256 tokenId
    ) private {
        uint256[] storage ids = _insideTokenIds[eggId][token];
        ids.push(tokenId);
    }

    /**
     * @dev private function to pop a token id from egg
     */
    function _popInsideTokenId(
        uint256 eggId,
        address token,
        uint256 tokenId
    ) private {
        uint256[] storage ids = _insideTokenIds[eggId][token];
        for (uint256 i; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
            }
        }

        if (ids.length == 0) {
            delete _insideTokenIds[eggId][token];
        }
    }

    /**
     * @dev put token(type, address) to egg
     */
    function _putTokenIntoEgg(
        uint256 eggId,
        address tokenAddress
    ) private {
        address[] storage tokens = _insideTokens[eggId];
        bool exists = false;
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == tokenAddress) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            tokens.push(tokenAddress);
        }
    }

    /**
     * @dev pop token(type, address) from egg
     */
    function _popTokenFromEgg(
        uint256 eggId,
        address tokenAddress
    ) private {
        address[] storage tokens = _insideTokens[eggId];
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == tokenAddress) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }

        if (tokens.length == 0) {
            delete _insideTokens[eggId];
        }
    }
   
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}