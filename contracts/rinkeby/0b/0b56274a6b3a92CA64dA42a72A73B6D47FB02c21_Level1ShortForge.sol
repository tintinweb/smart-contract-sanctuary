// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//                                           .....                                                 //
//                                     -+*%@@@@@@@@@#*++=-:                                        //
//                                 .=#@@@@@@@@@@@@@@@@@@@@@@#+:                                    //
//                               -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-                                  //
//                             [email protected]@@@@@@@@@%*+==----==*#@@@@@@@@@@%-                                //
//                           :%@@@@@@@@*-.              :+%@@@@@@@@#.                              //
//                          [email protected]@@@@@@@+.                    -#@@@@@@@@+                             //
//                         *@@@@@@@+.                        :#@@@@@@@%.                           //
//                        *@@@@@@@:                            [email protected]@@@@@@@-                          //
//                       [email protected]@@@@@%.                              :@@@@@@@@=                         //
//                      [email protected]@@@@@@.                                [email protected]@@@@@@@=                        //
//                      %@@@@@@=                                  #@@@@@@@@=                       //
//                     [email protected]@@@@@@.                                  [email protected]@@@@@@@@-                      //
//                     #@@@@@@#                                    %@@@@@@@@@.                     //
//                     @@@@@@@*                                    [email protected]@@@@@@@@*                     //
//                     @@@@@@@*                                     @@@@@@@@@@.                    //
//                    [email protected]@@@@@@*                                     *@@@@@@@@@=                    //
//                    [email protected]@@@@@@#                                     [email protected]@@@@@@@@#                    //
//                    [email protected]@@@@@@%                                     [email protected]@@@@@@@@@                    //
//                     @@@@@@@@                                     [email protected]@@@@@@@@@.                   //
//                     %@@@@@@@.                                    [email protected]@@@@@@@@@:                   //
//                     %@@@@@@@-                                    [email protected]@@@@@@@@@-                   //
//                    :@@@@@@@@*                                    #@@@@@@@@@@-                   //
//                   [email protected]@@@@@@@@@           .+%@@%[email protected]@@%+.          [email protected]@@@@@@@@@@:                   //
//                  . @@@@@@@@@@=         [email protected]#+-:.   .:=%@=         [email protected]@@@@@@@@@@:                   //
//                   [email protected]@@@@@@@@@%        [email protected]:            [email protected]        @@@@@@@@@@@@:                   //
//                   *@@@@@@@@@@@#       *=              #:       #@@@@@@@@@@@@:                   //
//                   *@@@@@@@@@@@@%:     ::     .--:     :      .%@@@@@@@@@@@@@=                   //
//                   [email protected]@@@@@@@@@@@@@+           [email protected]@#       .   [email protected]@@@@@@@@@@@@@@*                   //
//                   [email protected]@@@@@@@@@@@@@@%=.-+       *@.      :@##@@@@@@@@@@@@@@@@@@                   //
//                   [email protected]@@@@@@@@@@@@@@@@@@@=  .==:    -+=:-%@@@@@@@@@@@@@@@@@@@@@:                  //
//                  [email protected]*[email protected]@@@@@@@@@@@@#+%@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@*                  //
//                  *# [email protected]@@@@@@@@@@@@%  :+#@@@@@@@@@@@@@@@%+:.%@@@@@@@@@@@@@@@@@@.                 //
//                 +* [email protected]@@@@@@@@@@@@@@=     :-=+****++=-:     %@@@@@@@@@@@@@@@@@@%:                //
//                +=  #@@@@@@@@@@@@@@@@:                     *@@@@@@@@@@@@@@@@@@@@@*:              //
//              -+.  *@#@@@@@@@@@@@@@@@%.                   *@@@@@@@@@@@@@@@@@@@@@%*@#:            //
//             :.   *%:[email protected]@@@@@@@@@@@@@@@%.                .%#@@@@@@@@@@@@@@@@@@@[email protected]%  [email protected]+           //
//                -#=  %@@@@@@@@@@@@@@@@@%.             :[email protected]@@@@@@@@@@@@@@@@@@:*@=  .*+          //
//                .   [email protected]@@@@@@@@@@@@@@@@@@:            .   *@@@@@@@@@@@@@@@@@@@* #@.   =          //
//                   [email protected][email protected]@@@@@@@@@@@@@@@@@@.               #+*@@@@@@@@@@@@@@@@@@: %#              //
//                   ** :@@@@@@@@@@@@@@@@@@@*               #::@@@@@@@@@@@@@@@@@@%[email protected]=             //
//                  -#  [email protected]@@@@@@@@@@@@@@@@@@@.              +. @@@@@@@@@@@@@@@@@@@%.:%:            //
//                 .#. [email protected]@@@@@@@@@@@@@@@@@@#@=              .- %@@@@@@@@@@@@@@@@@%=#..*.           //
//                .*. -%@@@@@@@@@@@@@@@@@@*[email protected]+                 %@@@@@@@@@@@@@@%#@@*.+=             //
//                  =%@@@@@@@@@@@@@@@@@@@@:[email protected]                 @@@@@@@@@@@@@@@+ .=%*  -:           //
//              .=#@@#=#@@@@@@@@@@@@@@@@@+ +%                 [email protected]@@@@@@@@@@@@@@@+   :+:             //
//           :+#%*=: .#@@@@@@@@@@@@@*%@@%  #-                 *%[email protected]@@@@@@@@@@%-+%%=   .             //
//        -==-:     [email protected]#[email protected]@@@@@@@@@@@ [email protected]@. .*                  %.:@@@@@@@@@@@%   .=*+=:             //
//               .+%*: [email protected]@@@@@@@@@@% [email protected]:  -                   * [email protected]@@@@@@@@@@@.       :-:           //
//             -*#-    #@@@@@@@@@@@# #-                       . %%.%@@@@@@@@@+                     //
//          -=+-.      *@@@@@@@@@@@* :                         [email protected]: [email protected]@@@@[email protected]@#                     //
//                     [email protected]@@@*#@@@@@*                          .%:   #@@@@  .%@.                    //
//                      %@@@.:@@@.%%                          -.    .%@@@   :@:                    //
//                      :@@@  #@@ [email protected]                                :@@@.   *-                    //
//                       :%@-  #@= #*                                 :@@*   =.                    //
//                         :+:  [email protected]= =+                                 .#@+                        //
//                               .+*: .                                  :*%-                      //
//                                  :.                                      :.                     //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////

/// @title:  Steve Aoki NFT Forge Collection - Xtra Credit NFT
/// @author:  An NFT powered by Ether Cards - https://ether.cards

import "./burnNRedeem/ERC721BurnRedeem.sol";
import "./burnNRedeem/ERC721OwnerEnumerableSingleCreatorExtension.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./burnNRedeem/extensions/ICreatorExtensionTokenURI.sol";

interface ExtensionInterface {
    function mintNumber(uint256 tokenId) external view returns (uint256);
}

contract Level1ShortForge is
    ERC721BurnRedeem,
    ERC721OwnerEnumerableSingleCreatorExtension,
    ICreatorExtensionTokenURI
{
    using Strings for uint256;

    address public creator;
    mapping(uint256 => bool) private claimed;
    event forgeWith(
        uint16 _checkToken, // Hop SKip Flop  375
        uint16 _checkToken2, // Xtradit    879
        uint16 _checkToken3, // GameOver   867
        uint16 _checkToken4, // FreshMeat   873
        uint16 _checkToken5, // Vigilant Eye 834
        uint16 _checkToken6, // Bridge Over   801
        uint16 _burnToken  // Distored Reality  123
    );
    //event airDropTo(address _receiver);

    string private _endpoint =
        "https://client-metadata.ether.cards/api/aoki/Level1Short/";

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721BurnRedeem,
            IERC165,
            ERC721CreatorExtensionApproveTransfer
        )
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            super.supportsInterface(interfaceId) ||
            ERC721CreatorExtensionApproveTransfer.supportsInterface(
                interfaceId
            );
    }

    constructor(
        address _creator, //  0x01Ba93514e5Eb642Ec63E95EF7787b0eDd403ADd
        uint16 redemptionRate, // 1
        uint16 redemptionMax // 10
    )
        ERC721OwnerEnumerableSingleCreatorExtension(_creator)
        ERC721BurnRedeem(_creator, redemptionRate, redemptionMax)
    {
        creator = _creator;
    }

    /* 
    check whether can claim or not , if can claim return true.
    */
    function checkClaim(uint256 _tokenID) public view returns (bool) {
        return (!claimed[_tokenID]); // check status. false by default. then become true after claim.
    }

    function setup() external {
        super._activate();
    }
/*
    function EmergencyAirdrop(address _to) external onlyOwner {
        _mintRedemption(_to);
        emit airDropTo(_to);
    }
*/
    //
    // Hop SKip Flop - 374-383
    // Mainnet
    /*
address public Xtradit = 0x2b09d7DBab4D4a3a7ca4AafB691bB8289b8c132A;
address public GameOver = 0x0d0dCD1af3D7d4De666F252c9eBEFdBF913fa3eb;
address public FreshMeat = 0xf9a38984244A37d7040d9bbE35aa7dd58C00ed9A;
address public VigilantEye = 0x3383a9C5dB21FE5e00491532CC5f38A1Bd747dcd;
address public BridgeOver = 0x2e631e51F83f5aD99dd69B812D755963633c8b62;
*/
    // Testnet
    address public Xtradit = 0x135A1979777A3c7EA724d850330841664Bd649da;
    address public GameOver = 0xE4Dd95316F3418AdDc17C484f012Dd4d34e7AFbC;
    address public FreshMeat = 0x821Ef6ED46E98bdE236fE6CBF9238d25EaBF9cf9;
    address public VigilantEye = 0xB4829d4E667f5Fe3F5058F8739e3e55F48bD0c49;
    address public BridgeOver = 0xf76c14106feD1e2F35b63B7c59De5143f8a22b2B;

    function forge(
        uint16 _checkToken, // Hop SKip Flop
        uint16 _checkToken2, // Xtradit
        uint16 _checkToken3, // GameOver
        uint16 _checkToken4, // FreshMeat
        uint16 _checkToken5, // Vigilant Eye
        uint16 _checkToken6, // Bridge Over
        uint16 _burnToken //  DistortedReality
    ) public {
        // Attempt Burn
        // Check that we can burn

        require(374 <= _checkToken && _checkToken <= 383, "!H");

        require(ExtensionInterface(Xtradit).mintNumber(_checkToken2) > 0 && ( ExtensionInterface(GameOver).mintNumber(_checkToken3) > 0 ), "!2 & !3");
        require(ExtensionInterface(FreshMeat).mintNumber(_checkToken4) > 0 && ( ExtensionInterface(VigilantEye).mintNumber(_checkToken5) > 0 ), "!4 & !5");
        require(redeemable(creator, _burnToken) && ExtensionInterface(BridgeOver).mintNumber(_checkToken6) > 0 , "IT , !6");

        require(checkClaim(_checkToken) == true && ( IERC721(creator).ownerOf(_checkToken) == msg.sender), "F1");
        require(checkClaim(_checkToken2) == true && ( IERC721(creator).ownerOf(_checkToken2) == msg.sender), "F2");
        require(checkClaim(_checkToken3) == true && (IERC721(creator).ownerOf(_checkToken3) == msg.sender), "F3");
        require(checkClaim(_checkToken4) == true && (IERC721(creator).ownerOf(_checkToken4) == msg.sender) , "F4");
        require(checkClaim(_checkToken5) == true && (IERC721(creator).ownerOf(_checkToken5) == msg.sender), "F5");
        require(checkClaim(_checkToken6) == true &&( IERC721(creator).ownerOf(_checkToken6) == msg.sender), "F6");

        // There is an invent in checkClaim.
        // Restructure setup and to have the same interface.
        claimed[_checkToken] = true;
        claimed[_checkToken2] = true;
        claimed[_checkToken3] = true;
        claimed[_checkToken4] = true;
        claimed[_checkToken5] = true;
        claimed[_checkToken6] = true;

        //    require(IERC721(creator).ownerOf(_burnToken) == msg.sender, "O0");
        /*
        require(
            IERC721(creator).getApproved(_burnToken) == address(this),
            "approval"
        );
*/
        // Then burn
        try
            IERC721(creator).transferFrom(
                msg.sender,
                address(0xdEaD),
                _burnToken
            )
        {} catch (bytes memory) {
            revert("Bf");
        }

        // Mint reward
        _mintRedemption(msg.sender);
        emit forgeWith(
            _checkToken, // Hop SKip Flop
            _checkToken2, // Xtradit
            _checkToken3, // GameOver
            _checkToken4, // FreshMeat
            _checkToken5, // Vigilant Eye
            _checkToken6, // Bridge Over
            _burnToken
        );
    }

    // tokenURI extension
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_mintNumbers[tokenId] != 0, "It");
        return
            string(
                abi.encodePacked(
                    _endpoint,
                    uint256(int256(_mintNumbers[tokenId])).toString()
                )
            );
    }

    function tokenURI(address creator, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenURI(tokenId);
    }
/*
    function drain(IERC20 _token) external onlyOwner {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }*/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./core/IERC721CreatorCore.sol";

import "./ERC721RedeemBase.sol";
import "./IERC721BurnRedeem.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
contract ERC721BurnRedeem is
    ReentrancyGuard,
    ERC721RedeemBase,
    IERC721BurnRedeem
{
    //using EnumerableSet for EnumerableSet.UintSet;

    //  mapping(address => mapping(uint256 => address)) private _recoverableERC721;

    constructor(
        address creator,
        uint16 redemptionRate,
        uint16 redemptionMax
    ) ERC721RedeemBase(creator, redemptionRate, redemptionMax) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721RedeemBase, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721BurnRedeem).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721BurnRedeem-setERC721Recoverable}
     */
    function setERC721Recoverable(
        address contract_,
        uint256 tokenId,
        address recoverer
    ) external virtual override adminRequired {}

    /**
     * @dev See {IERC721BurnRedeem-recoverERC721}
     */
    function recoverERC721(address contract_, uint256 tokenId)
        external
        virtual
        override
    {}

    /**
     * @dev See {IERC721BurnRedeem-redeemERC721}
     
    function redeemERC721(
        address[] calldata contracts,
        uint256[] calldata tokenIds
    ) external virtual override nonReentrant {
        require(
            contracts.length == tokenIds.length,
            "BurnRedeem: Invalid parameters"
        );
        require(
            contracts.length == _redemptionRate,
            "BurnRedeem: Incorrect number of NFTs being redeemed"
        );

        // Attempt Burn
        for (uint256 i = 0; i < contracts.length; i++) {
            // Check that we can burn
            require(
                redeemable(contracts[i], tokenIds[i]),
                "BurnRedeem: Invalid NFT"
            );

            try IERC721(contracts[i]).ownerOf(tokenIds[i]) returns (
                address ownerOfAddress
            ) {
                require(
                    ownerOfAddress == msg.sender,
                    "BurnRedeem: Caller must own NFTs"
                );
            } catch (bytes memory) {
                revert("BurnRedeem: Bad token contract");
            }

            try IERC721(contracts[i]).getApproved(tokenIds[i]) returns (
                address approvedAddress
            ) {
                require(
                    approvedAddress == address(this),
                    "BurnRedeem: Contract must be given approval to burn NFT"
                );
            } catch (bytes memory) {
                revert("BurnRedeem: Bad token contract");
            }

            // Then burn
            try
                IERC721(contracts[i]).transferFrom(
                    msg.sender,
                    address(0xdEaD),
                    tokenIds[i]
                )
            {} catch (bytes memory) {
                revert("BurnRedeem: Burn failure");
            }
        }

        // Mint reward
        _mintRedemption(msg.sender);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override nonReentrant returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./core/IERC721CreatorCore.sol";

import "./extensions/ERC721/ERC721CreatorExtensionApproveTransfer.sol";

import "./libraries/SingleCreatorBase.sol";

/**
 * Provide token enumeration functionality (Base Class. Use if you are using multiple inheritance where other contracts
 * already derive from either ERC721SingleCreatorExtension or ERC1155SingleCreatorExtension).
 *
 * IMPORTANT: You must call _activate in order for enumeration to work
 */
abstract contract ERC721OwnerEnumerableSingleCreatorBase is
    SingleCreatorBase,
    ERC721CreatorExtensionApproveTransfer
{
    mapping(address => uint256) private _ownerBalance;
    mapping(address => mapping(uint256 => uint256)) private _tokensByOwner;
    mapping(uint256 => uint256) private _tokensIndex;

    /**
     * @dev must call this to activate enumeration capability
     */
    function _activate() internal {
        IERC721CreatorCore(_creator).setApproveTransferExtension(true);
    }

    /**
     * @dev Get the token for an owner by index
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            index < _ownerBalance[owner],
            "ERC721Enumerable: owner index out of bounds"
        );
        return _tokensByOwner[owner][index];
    }

    /**
     * @dev Get the balance for the owner for this extension
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        return _ownerBalance[owner];
    }

    function approveTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external override returns (bool) {
        require(msg.sender == _creator, "Invalid caller");
        if (from != address(0) && from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to != address(0) && to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
        return true;
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _ownerBalance[to];
        _tokensByOwner[to][length] = tokenId;
        _tokensIndex[tokenId] = length;
        _ownerBalance[to] += 1;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownerBalance[from] - 1;
        uint256 tokenIndex = _tokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _tokensByOwner[from][lastTokenIndex];

            _tokensByOwner[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _tokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _tokensIndex[tokenId];
        delete _tokensByOwner[from][lastTokenIndex];
        _ownerBalance[from] -= 1;
    }
}

/**
 * Provide token enumeration functionality (Extension)
 *
 * IMPORTANT: You must call _activate in order for enumeration to work
 */
abstract contract ERC721OwnerEnumerableSingleCreatorExtension is
    ERC721OwnerEnumerableSingleCreatorBase,
    ERC721SingleCreatorExtension
{
    constructor(address creator) ERC721SingleCreatorExtension(creator) {}
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable URI's
 */
interface ICreatorExtensionTokenURI is IERC165 {
    /**
     * Get the uri for a given creator/tokenId
     */
    function tokenURI(address creator, uint256 tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorCore.sol";

/**
 * @dev Core ERC721 creator interface
 */
interface IERC721CreatorCore is ICreatorCore {
    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to, string calldata uri)
        external
        returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count)
        external
        returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris)
        external
        returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri)
        external
        returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count)
        external
        returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris)
        external
        returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./core/IERC721CreatorCore.sol";
import "./extensions/CreatorExtension.sol";

import "./libraries/LegacyInterfaces.sol";
import "./RedeemBase.sol";
import "./IERC721RedeemBase.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
abstract contract ERC721RedeemBase is
    RedeemBase,
    CreatorExtension,
    IERC721RedeemBase
{
    // The creator mint contract
    address private _creator;

    uint16 internal immutable _redemptionRate;
    uint16 private _redemptionMax;
    uint16 private _redemptionCount;
    uint256[] private _mintedTokens;
    mapping(uint256 => uint256) internal _mintNumbers;

    constructor(
        address creator,
        uint16 redemptionRate_,
        uint16 redemptionMax_
    ) {
        require(
            ERC165Checker.supportsInterface(
                creator,
                type(IERC721CreatorCore).interfaceId
            ) ||
                ERC165Checker.supportsInterface(
                    creator,
                    LegacyInterfaces.IERC721CreatorCore_v1
                ),
            "Redeem: Minting reward contract must implement IERC721CreatorCore"
        );
        _redemptionRate = redemptionRate_;
        _redemptionMax = redemptionMax_;
        _creator = creator;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RedeemBase, CreatorExtension, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721RedeemBase).interfaceId ||
            RedeemBase.supportsInterface(interfaceId) ||
            CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionMax}
     */
    function redemptionMax() external view virtual override returns (uint16) {
        return _redemptionMax;
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionRate}
     */
    function redemptionRate() external view virtual override returns (uint16) {
        return _redemptionRate;
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionRemaining}
     */
    function redemptionRemaining()
        external
        view
        virtual
        override
        returns (uint16)
    {
        return _redemptionMax - _redemptionCount;
    }

    /**
     * @dev See {IERC721RedeemBase-mintNumber}.
     */
    function mintNumber(uint256 tokenId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _mintNumbers[tokenId];
    }

    /**
     * @dev See {IERC721RedeemBase-mintedTokens}.
     */
    function mintedTokens() external view override returns (uint256[] memory) {
        return _mintedTokens;
    }

    /**
     * @dev mint token that was redeemed for
     */
    function _mintRedemption(address to) internal {
        require(
            _redemptionCount < _redemptionMax,
            "Redeem: No redemptions remaining"
        );
        _redemptionCount++;

        // Mint token
        uint256 tokenId = _mint(to, _redemptionCount);

        _mintedTokens.push(tokenId);
        _mintNumbers[tokenId] = _redemptionCount;
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to, uint16) internal returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IERC721RedeemBase.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
interface IERC721BurnRedeem is IERC721RedeemBase, IERC721Receiver {
    /**
     * @dev Enable recovery of a given token. Can only be called by contract owner/admin.
     * This is a special function used in case someone accidentally sends a token to this contract.
     */
    function setERC721Recoverable(
        address contract_,
        uint256 tokenId,
        address recoverer
    ) external;

    /**
     * @dev Recover a token.  Returns it to the recoverer set by setERC721Recoverable
     * This is a special function used in case someone accidentally sends a token to this contract.
     */
    function recoverERC721(address contract_, uint256 tokenId) external;

    /**
     * @dev Redeem ERC721 tokens for redemption reward NFT.
     * Requires the user to grant approval beforehand by calling contract's 'approve' function.
     * If the it cannot redeem the NFT, it will clear approvals
     
    function redeemERC721(
        address[] calldata contracts,
        uint256[] calldata tokenIds
    ) external;
    */
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

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {
    event ExtensionRegistered(
        address indexed extension,
        address indexed sender
    );
    event ExtensionUnregistered(
        address indexed extension,
        address indexed sender
    );
    event ExtensionBlacklisted(
        address indexed extension,
        address indexed sender
    );
    event MintPermissionsUpdated(
        address indexed extension,
        address indexed permissions,
        address indexed sender
    );
    event RoyaltiesUpdated(
        uint256 indexed tokenId,
        address payable[] receivers,
        uint256[] basisPoints
    );
    event DefaultRoyaltiesUpdated(
        address payable[] receivers,
        uint256[] basisPoints
    );
    event ExtensionRoyaltiesUpdated(
        address indexed extension,
        address payable[] receivers,
        uint256[] basisPoints
    );
    event ExtensionApproveTransferUpdated(
        address indexed extension,
        bool enabled
    );

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI)
        external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(
        address extension,
        string calldata baseURI,
        bool baseURIIdentical
    ) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical)
        external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri)
        external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(
        uint256[] memory tokenId,
        string[] calldata uri
    ) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris)
        external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions)
        external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(
        address extension,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    function getFees(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Base creator extension variables
 */
abstract contract CreatorExtension is ERC165 {
    /**
     * @dev Legacy extension interface identifiers
     *
     * {IERC165-supportsInterface} needs to return 'true' for this interface
     * in order backwards compatible with older creator contracts
     */
    bytes4 internal constant LEGACY_EXTENSION_INTERFACE = 0x7005caad;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == LEGACY_EXTENSION_INTERFACE ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Library of legacy interface constants
 */
library LegacyInterfaces {
    // LEGACY ERC721CreatorCore interface
    bytes4 internal constant IERC721CreatorCore_v1 = 0x478c8530;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./access/AdminControl.sol";

import "./IRedeemBase.sol";

struct range {
    uint256 min;
    uint256 max;
}

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
abstract contract RedeemBase is AdminControl, IRedeemBase {
    using EnumerableSet for EnumerableSet.UintSet;

    // approved contract tokens
    mapping(address => bool) private _approvedContracts;

    // approved specific tokens
    mapping(address => EnumerableSet.UintSet) private _approvedTokens;
    mapping(address => range[]) private _approvedTokenRange;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRedeemBase).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRedeemBase-updateApprovedContracts}
     */
    function updateApprovedContracts(
        address[] memory contracts,
        bool[] memory approved
    ) public virtual override adminRequired {
        require(
            contracts.length == approved.length,
            "Redeem: Invalid input parameters"
        );
        for (uint256 i = 0; i < contracts.length; i++) {
            _approvedContracts[contracts[i]] = approved[i];
        }
        emit UpdateApprovedContracts(contracts, approved);
    }

    /**
     * @dev See {IRedeemBase-updateApprovedTokens}
     */
    function updateApprovedTokens(
        address contract_,
        uint256[] memory tokenIds,
        bool[] memory approved
    ) public virtual override adminRequired {
        require(
            tokenIds.length == approved.length,
            "Redeem: Invalid input parameters"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                approved[i] && !_approvedTokens[contract_].contains(tokenIds[i])
            ) {
                _approvedTokens[contract_].add(tokenIds[i]);
            } else if (
                !approved[i] && _approvedTokens[contract_].contains(tokenIds[i])
            ) {
                _approvedTokens[contract_].remove(tokenIds[i]);
            }
        }
        emit UpdateApprovedTokens(contract_, tokenIds, approved);
    }

    /**
     * @dev See {IRedeemBase-updateApprovedTokenRanges}
     */
    function updateApprovedTokenRanges(
        address contract_,
        uint256[] memory minTokenIds,
        uint256[] memory maxTokenIds
    ) public virtual override adminRequired {
        require(
            minTokenIds.length == maxTokenIds.length,
            "Redeem: Invalid input parameters"
        );

        uint256 existingRangesLength = _approvedTokenRange[contract_].length;
        for (uint256 i = 0; i < existingRangesLength; i++) {
            _approvedTokenRange[contract_][i].min = 0;
            _approvedTokenRange[contract_][i].max = 0;
        }

        for (uint256 i = 0; i < minTokenIds.length; i++) {
            require(
                minTokenIds[i] < maxTokenIds[i],
                "Redeem: min must be less than max"
            );
            if (i < existingRangesLength) {
                _approvedTokenRange[contract_][i].min = minTokenIds[i];
                _approvedTokenRange[contract_][i].max = maxTokenIds[i];
            } else {
                _approvedTokenRange[contract_].push(
                    range(minTokenIds[i], maxTokenIds[i])
                );
            }
        }
        emit UpdateApprovedTokenRanges(contract_, minTokenIds, maxTokenIds);
    }

    /**
     * @dev See {IRedeemBase-redeemable}
     */
    function redeemable(address contract_, uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (_approvedContracts[contract_]) {
            return true;
        }
        if (_approvedTokens[contract_].contains(tokenId)) {
            return true;
        }
        if (_approvedTokenRange[contract_].length > 0) {
            for (
                uint256 i = 0;
                i < _approvedTokenRange[contract_].length;
                i++
            ) {
                if (
                    _approvedTokenRange[contract_][i].max != 0 &&
                    tokenId >= _approvedTokenRange[contract_][i].min &&
                    tokenId <= _approvedTokenRange[contract_][i].max
                ) {
                    return true;
                }
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IRedeemBase.sol";

/**
 * @dev Base redemption interface
 */
interface IERC721RedeemBase is IRedeemBase {
    /**
     * @dev Get the max number of redemptions
     */
    function redemptionMax() external view returns (uint16);

    /**
     * @dev Get the redemption rate
     */
    function redemptionRate() external view returns (uint16);

    /**
     * @dev Get number of redemptions left
     */
    function redemptionRemaining() external view returns (uint16);

    /**
     * @dev Get the mint number of a created token id
     */
    function mintNumber(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get list of all minted tokens
     */
    function mintedTokens() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAdminControl.sol";

abstract contract AdminControl is Ownable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IAdminControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(
            owner() == msg.sender || _admins.contains(msg.sender),
            "AdminControl: Must be owner or admin"
        );
        _;
    }

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins()
        external
        view
        override
        returns (address[] memory admins)
    {
        admins = new address[](_admins.length());
        for (uint256 i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public view override returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./access/IAdminControl.sol";

/**
 * @dev Base redemption interface
 */
interface IRedeemBase is IAdminControl {
    event UpdateApprovedContracts(address[] contracts, bool[] approved);
    event UpdateApprovedTokens(
        address contract_,
        uint256[] tokenIds,
        bool[] approved
    );
    event UpdateApprovedTokenRanges(
        address contract_,
        uint256[] minTokenIds,
        uint256[] maxTokenIds
    );

    /**
     * @dev Update approved contracts that can be used to redeem. Can only be called by contract owner/admin.
     */
    function updateApprovedContracts(
        address[] calldata contracts,
        bool[] calldata approved
    ) external;

    /**
     * @dev Update approved tokens that can be used to redeem. Can only be called by contract owner/admin.
     */
    function updateApprovedTokens(
        address contract_,
        uint256[] calldata tokenIds,
        bool[] calldata approved
    ) external;

    /**
     * @dev Update approved token ranges that can be used to redeem. Can only be called by contract owner/admin.
     * Clears out old ranges
     */
    function updateApprovedTokenRanges(
        address contract_,
        uint256[] calldata minTokenIds,
        uint256[] calldata maxTokenIds
    ) external;

    /**
     * @dev Check if an NFT is redeemable
     */
    function redeemable(address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {
    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);
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

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../../access/AdminControl.sol";

import "../../core/IERC721CreatorCore.sol";
import "./ERC721CreatorExtension.sol";
import "./IERC721CreatorExtensionApproveTransfer.sol";

/**
 * @dev Suggested implementation for extensions that require the creator to
 * check with it before a transfer occurs
 */
abstract contract ERC721CreatorExtensionApproveTransfer is
    AdminControl,
    ERC721CreatorExtension,
    IERC721CreatorExtensionApproveTransfer
{
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, CreatorExtension, IERC165)
        returns (bool)
    {
        return
            interfaceId ==
            type(IERC721CreatorExtensionApproveTransfer).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorExtensionApproveTransfer-setApproveTransfer}
     */
    function setApproveTransfer(address creator, bool enabled)
        external
        override
        adminRequired
    {
        require(
            ERC165Checker.supportsInterface(
                creator,
                type(IERC721CreatorCore).interfaceId
            ),
            "creator must implement IERC721CreatorCore"
        );
        IERC721CreatorCore(creator).setApproveTransferExtension(enabled);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../core/IERC721CreatorCore.sol";

import "./LegacyInterfaces.sol";

abstract contract SingleCreatorBase {
    address internal _creator;
}

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract ERC721SingleCreatorExtension is SingleCreatorBase {
    constructor(address creator) {
        require(
            ERC165Checker.supportsInterface(
                creator,
                type(IERC721CreatorCore).interfaceId
            ) ||
                ERC165Checker.supportsInterface(
                    creator,
                    LegacyInterfaces.IERC721CreatorCore_v1
                ),
            "Redeem: Minting reward contract must implement IERC721CreatorCore"
        );
        _creator = creator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../CreatorExtension.sol";

/**
 * @dev Base ERC721 creator extension variables
 */
abstract contract ERC721CreatorExtension is CreatorExtension {
    /**
     * @dev Legacy extension interface identifiers (see CreatorExtension for more)
     *
     * {IERC165-supportsInterface} needs to return 'true' for this interface
     * in order backwards compatible with older creator contracts
     */

    // Required to be recognized as a contract to receive onBurn for older creator contracts
    bytes4 internal constant LEGACY_ERC721_EXTENSION_BURNABLE_INTERFACE =
        0xf3f4e68b;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC721CreatorExtensionApproveTransfer is IERC165 {
    /**
     * @dev Set whether or not the creator will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * @dev Called by creator contract to approve a transfer
     */
    function approveTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external returns (bool);
}