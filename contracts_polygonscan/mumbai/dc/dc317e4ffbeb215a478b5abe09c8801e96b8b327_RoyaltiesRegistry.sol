/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRoyaltiesProvider.sol";
import "../RoyaltiesV1Luxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";


contract RoyaltiesRegistry is IRoyaltiesProvider, OwnableUpgradeable {
     event RoyaltiesSetForToken(address indexed token, uint indexed tokenId, LibPart.Part[] royalties);
    event RoyaltiesSetForContract(address indexed token, LibPart.Part[] royalties);

    struct RoyaltiesSet {
        bool initialized;
        LibPart.Part[] royalties;
    }

    mapping(bytes32 => RoyaltiesSet) public royaltiesByTokenAndTokenId;
    mapping(address => RoyaltiesSet) public royaltiesByToken;
    mapping(address => address) public royaltiesProviders;

    function __RoyaltiesRegistry_init() external initializer {
        __Ownable_init_unchained();
    }

    function setProviderByToken(address token, address provider) external {
        checkOwner(token);
        royaltiesProviders[token] = provider;
    }
     function setRoyaltiesByToken(address token, LibPart.Part[] memory royalties) external {
        checkOwner(token);
        uint sumRoyalties = 0;
        delete royaltiesByToken[token];
        for (uint i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0), "RoyaltiesByToken recipient should be present");
            require(royalties[i].value != 0, "Royalty value for RoyaltiesByToken should be > 0");
            royaltiesByToken[token].royalties.push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 3000, "Set by token royalties sum more, than 30%");
        royaltiesByToken[token].initialized = true;
        emit RoyaltiesSetForContract(token, royalties);
    }

    function setRoyaltiesByTokenAndTokenId(address token, uint tokenId, LibPart.Part[] memory royalties) external {
        checkOwner(token);
        setRoyaltiesCacheByTokenAndTokenId(token, tokenId, royalties);
    }
    
    
    
    function checkOwner(address token) internal view {
        if ((owner() != _msgSender())) {
            try OwnableUpgradeable(token).owner() returns (address result) {
                if(result != _msgSender()) {
                    revert("Sender is not owner of the token");
                }
            }
            catch {
            revert("Token owner not detected");
            }
        }
    }
    function getRoyalties(address token, uint tokenId) override external returns (LibPart.Part[] memory) {
        RoyaltiesSet storage royaltiesSetNFT = royaltiesByTokenAndTokenId[keccak256(abi.encode(token, tokenId))];
        RoyaltiesSet storage royaltiesSetToken = royaltiesByToken[token];
        if (royaltiesSetNFT.initialized && royaltiesSetToken.initialized) {
            for(uint i=0; i<royaltiesSetNFT.royalties.length; i++) {
                royaltiesSetToken.royalties.push(royaltiesSetNFT.royalties[i]);
            }
            return royaltiesSetToken.royalties;
        }
        else if (royaltiesSetNFT.initialized) {
            return royaltiesSetNFT.royalties;
        }
        
        (bool result, LibPart.Part[] memory resultRoyalties) = providerExtractor(token, tokenId);
        if (result == false) {
            resultRoyalties = royaltiesFromContract(token, tokenId);
        }
        setRoyaltiesCacheByTokenAndTokenId(token, tokenId, resultRoyalties);
        if(royaltiesSetToken.initialized) {
            if(resultRoyalties.length > 0) {
                for(uint i=0; i<resultRoyalties.length; i++) {
                    royaltiesSetToken.royalties.push(resultRoyalties[i]);
                }
            }
                return royaltiesSetToken.royalties;
        }
        return resultRoyalties;
    }

    function setRoyaltiesCacheByTokenAndTokenId(address token, uint tokenId, LibPart.Part[] memory royalties) internal {
        uint sumRoyalties = 0;
        bytes32 key = keccak256(abi.encode(token, tokenId));
        delete royaltiesByTokenAndTokenId[key].royalties;
        for (uint i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0), "RoyaltiesByTokenAndTokenId recipient should be present");
            require(royalties[i].value != 0, "Royalty value for RoyaltiesByTokenAndTokenId should be > 0");
            royaltiesByTokenAndTokenId[key].royalties.push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 6800, "Set by token and tokenId royalties sum more, than 68%");
        royaltiesByTokenAndTokenId[key].initialized = true;
        emit RoyaltiesSetForToken(token, tokenId, royalties);
    }

    function royaltiesFromContract(address token, uint tokenId) internal view returns (LibPart.Part[] memory) {
        if (IERC165Upgradeable(token).supportsInterface(type(RoyaltiesV1Luxy).interfaceId)) {
            RoyaltiesV1Luxy v1 = RoyaltiesV1Luxy(token);
            try v1.getRoyalties(tokenId) returns (LibPart.Part[] memory result) {
                return result;
            } catch {}
        }
        return new LibPart.Part[](0);
    }

    function providerExtractor(address token, uint tokenId) internal returns (bool result, LibPart.Part[] memory royalties) {
        result = false;
        address providerAddress = royaltiesProviders[token];
        if (providerAddress != address(0x0)) {
            IRoyaltiesProvider provider = IRoyaltiesProvider(providerAddress);
            try provider.getRoyalties(token, tokenId) returns (LibPart.Part[] memory royaltiesByProvider) {
                royalties = royaltiesByProvider;
                result = true;
            } catch {}
        }
    }

    uint256[50] private __gap;


}

/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint tokenId) external returns (LibPart.Part[] memory);
}

/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./LibPart.sol";

abstract contract RoyaltiesV1Luxy is Initializable {

    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);
    event RoyaltieAccountUpdate(
        uint256 tokenId,
        uint256 index,
        address previousAccount,
        address newAccount
    );
    mapping(uint256 => LibPart.Part[]) internal royalties;

    function __RoyaltiesV1Luxy_init_unchained() internal initializer {}

    function __RoyaltiesV1Luxy_init() public initializer {
        __RoyaltiesV1Luxy_init_unchained();
    }

    function getRoyalties(uint256 id)
        public
        virtual
        view
        returns (LibPart.Part[] memory)
    {
        return royalties[id];
    }

    function _setRoyalties(uint256 _id, LibPart.Part[] memory _royalties)
        internal
    {
        require(royalties[_id].length == 0, "Royalties already set");
        for (uint256 i = 0; i < _royalties.length; i++) {
            require(
                _royalties[i].account != address(0x0),
                "Recipient should be present"
            );
            require(
                _royalties[i].value != 0,
                "Royalty value should be positive"
            );
            royalties[_id].push(_royalties[i]);
        }
        emit RoyaltiesSet(_id, _royalties);
    }

    function _updateAccount(
        uint256 _id,
        address _from,
        address _to
    ) internal {
        uint256 length = royalties[_id].length;
        address previousAccount = address(0x0);
        uint256 index = 0;
        for (uint256 i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                previousAccount = royalties[_id][i].account;
                index = i;
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
        require(
            previousAccount != address(0x0),
            "Account not found, are you using the correct wallet?"
        );
        emit RoyaltieAccountUpdate(
            _id,
            index,
            previousAccount,
            royalties[_id][index].account
        );
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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