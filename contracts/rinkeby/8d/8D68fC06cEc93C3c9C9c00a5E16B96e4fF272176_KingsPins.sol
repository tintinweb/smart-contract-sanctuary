// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Sacramento Kings
/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "./core/IERC721CreatorCore.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                           ╦                                             //
//                         ╔╬╬                                             //
//                        ╔╬╣  ╔╗                   ╔╗  ╦╦╦    ╔╬╬╗        //
//                ╔╦╬   ╔╬╬╬╬  ╬╬         ╔╬╬╗   ╔╬╬╬╬╬╬╬╣   ╔╬╬╬╬╬        //
//            ╔╦╬╬╬╬╝  ╔╬╬╬╬╝       ╔╦╬╦╬╬╬╬╬╣  ╔╬╬╩  ╬╬╬╝ ╦╬╬╩ ╠╬╬╣       //
//           ╠╬╬╬╬╬╬  ╬╬╬╬╩   ╔╦╬   ╬╬╬╬╝ ╠╬╬  ╔╬╬╣  ╬╬╬╣╔╬╬╩   ╠╬╬╣       //
//           ╚╩╩╬╬╬╬╦╬╬╬╩     ╠╬╬  ╠╬╬╝   ╬╬╣ ╔╬╬╬╬╦╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//              ╬╬╬╬╬╬╝      ╠╬╬╝  ╬╬╣   ╠╬╬╬╬╩╩╬╬╬╩╬╬╬╬╩   ╚╩╩╩╩╩  ╬╬╬╬   //
//              ╬╬╬╬╬╣       ╠╬╬   ╬╬╣   ╚╬╩╩      ╬╬╬╬╗      ╔╦╦╦╬╬╬╝╙    //
//             ╬╬╬╣╬╬╬╬╦    ╔╦╬╬╦╦╦╬╬╝      ╔╦╦╬╬╬╬╬╬╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩       //
//             ╠╬╬╝ ╬╬╬╬╬╦╦╬╬╩╬╬╬╩╩╩   ╔╦╬╬╩╩╬╬╬╬╝╠╬╬⌐                     //
//             ╬╬╬   ╙╬╬╬╬╬╬╝     ╔╦╦╬╬╬╩╝ ╔╬╬╬╩╝╔╬╬╝                      //
//            ╬╬╬╣           ╔╦╦╬╬╬╬╩╝    ╔╬╬╬╝ ╔╬╬╩                       //
//      ╬    ╬╬╬╬╝        ╔╦╬╬╬╬╬╬╩      ╔╬╬╬╬╦╦╬╬╩                        //
//      ╬╦╦╦╬╬╬╬╝     ╔╦╬╬╬╬╬╬╬╩╩        ╬╬╬╬╬╬╬╬╝                         //
//      ╚╬╬╬╬╬╬╩    ╔╬╬╬╬╬╬╬╬╩            ╚╩╩╩╝                            //
//       ╚╩╩╩╩╝   ╔╦╬╬╬╬╬╬╬╝                                               //
//             ╔╬╬╬╬╬╬╬╬╬╬╩                                                //
//           ╔╬╬╬╬╬╬╬╬╩╩╩╝                                                 //
//         ╔╬╬╬╬╬╩╩╝                                                       //
//       ╔╬╬╬╩╩                                                            //
//      ╬╬╩╝                                                               //
//    ╩╩╝                                                                  //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * 1985 Inaugural Season Opening Night Pin – Special Edition
 */
contract KingsPins is AdminControl {

     address private _creator;    

    /**
     * @dev Activate the contract and mint the tokens
     */
    function activate(address creator) public adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "Requires creator to implement IERC721CreatorCore");
        require(_creator == address(0), "Already active");

        _creator = creator;

        string[84] memory hashes = [
            "mdx21f5lP3vDFzRySV8m4n5kd3E_vXGmaHSs2uC6NcQ",
            "SOXmBqJDWYYzyzcuY2Kssof6TpS4gC7ZY2mKY9h-D_E",
            "oUewfazRxNNyFOF-MTZECu6brW9BIDPW38akY9CbtOg",
            "agLZK3myhunlyY3oX4vL_GWAbtm2R6FzpLb3q8WUKxE",
            "wmA4g9EQZD3mfLt7QnrG5GcJpV5Sloea0QlyCvuBhQw",
            "Z6ptejLWEwZjNT6tHl3uKRUgZ_3yeNtpRn28mzHZyCg",
            "sRfnvi-41Pb5qsq0fywBAT6iaehdVqQidqozVqj1tSs",
            "qozuGWkw1_crmcyoeDOE7zdmXCb_9Hq9kQYx4LSXN08",
            "ZJOEfx5HIjGsvNWrG7VZ-1CRfhBhhDepGiQGHQRnPq8",
            "pog4NmGp1Ft1xsrdDhzxDU84qSsDh3Lz34zqQcmct3M",
            "vXlw0JsstKkkRA92wBbXjtxkSBu33OvL6mbsKXNSU8c",
            "CsQf0akwjdOfbvfXSMk782sCNhUIfo5rB0ZLDWE3mwI",
            "UY1XlH9S7BgtL9ZcRjo2wOyLchqmY0fpLbwHmIZqG6Q",
            "ozexV0CN3QLpF9r9RZ0quezpq6bQA_xcPAuicWW7AQ8",
            "HDe3kEWjN9EQQG5TlyMO60bPg0dxBOR6Yqun-CNhpx0",
            "IzkQnUXJzRTClJpxBsWJl0VeQrcJFzDifG3-eStcLFM",
            "QhyXNYUcH6RQSmP2yU0Kh-xUB3A6RjGgRrBOstL8CCU",
            "lzcZkaaGDFawPLOgleAI5ogcUZ2UEzvUHFvKj1cWA8U",
            "LgOfDu3bBGdkyoVEk1-K6FsCfyt0qE-8d-WZkGqiDFE",
            "SboO2zUhhPVNNjf3XJr5fAjpLt-qr85DZVBfT2rk5_s",
            "yRz-W0hcua6K97lQVS1nU1gXuVdpMGf7H4DRqNwd3jQ",
            "D1tqlNS4IW1fTWbJk9Av5o2cUYYZ7ccjhlKhSLbs7VQ",
            "TUQ3kIiy_90zWrCoRTgZg8_Z6w7RhT9Xpw8m6NjW6BM",
            "jPCGRcOHGPMa7PMHRcA7BGkn1uzR14Sb0nHYj7AWHXc",
            "pK2h971pmK8VX0VZXRCOxcSz_Q01enG7kVK4zF8LE2U",
            "VytCFcGwCWsnKcuNt4-sg1rfT8p9EMp5Gh3x82zlkSU",
            "LnZJ2rrtkpZ71mTmojpFr1IeeM9H7yi9l0zafiJe8j4",
            "UQKqAsuJtJiUjbZXVVXVPAqRbQtzFVBOz8FoXPPCnPM",
            "LvVPcUqUKC-VFdRQoH3q3IDmkkpxEMA9N6Mc0Tgz3wY",
            "L4Lh3dbvA328-ovkQB26LQanf7-2zlBRUA9feMB7_Ng",
            "hQzYWTUz4QuZ26kh4kBEcpVDG4OcyPDJO9Fv3tFzWFc",
            "ilmMA17sY16MY_1PgFet5lxKnVZwt18xBhMMJq93yro",
            "nLh_pKaL6fhXU5-3bUFLI3KpqBhWOTQqk6eHFNKou1k",
            "-rnLyIIjPZyNMwvlszGh2hH3meLzRGSfLMtGBvOUcRE",
            "xrAHdW3wHoKH4uacxwYtHGEH9CN-1Ihracqk1CBeVWk",
            "HJl4P1mdLzF5fTtSpFu_rQsnpvsrJ3zdfqjcPJSq8AM",
            "95fgRJeGDEZboPEbsPwcYpUyKU6CNajwd03KjIah918",
            "1q249yW3WXWCIcSAHqTF4A4f14iXcagNAhIFI97GtJs",
            "fxgTQMiFr-GLuoeezhkFn1QxAqGYW7pJ6vsV-RNo2so",
            "ejF7a8Z_DBCZKub_A3i_R-QoSOmrqBnNDYpJsjt6blQ",
            "r2ZJrskXgMrRVne5fPeDIG1qhcZ0Pdo8OmXXybUYveM",
            "E-tz4u0zAFUoLHGuRujKg4T5k35_DLoRs01ae2vvYKI",
            "2g_wvMtl8DLB0Lxg6kkwBVPQYjt9eaZbPQa1SYPpvyQ",
            "iNL86xE8kNNb3L7j-ztmUxOFDio_RCpd6CjlpiHFLOo",
            "3CCHaY7wtlcd8imSAL-FsR0PTOkfdBuziOQX7BVk-14",
            "Vv47URPO7SidofsYzjwiKFrQNK6AXLJdTXxtwLTx6MI",
            "wB-y3l9TSy67uGecnMVXNhVcG0sNSUt2oCh_t_YtZJ8",
            "HWFIDPA2nkU4B-ybcAOc-KFB5V2KrtxpODUMPINZwGg",
            "iEggRcgXyL_mvjqwZfiRpQ4W0_XO4agCpAQ9_bduQUc",
            "_avn1n9J4TIccU4p_rPqVFOyL-agfPUYsTNeqPUnNbg",
            "OO60BJn1QB7G-QxLT2sE7ds_BkOBuahyq9HzGQeCkao",
            "uJETazKkdSpqKiPHoP43gpedG9yavmG2Un-m0UG9v1g",
            "spFC7BpOrV5UpQP1fjDdMxLqmLC_3sypntya9fhampA",
            "z2JFW6jcx4ak2DmZfDkEidI3NIaGeRiZGJ9XROIA5sY",
            "uW1mCRhq1B3VRPDFEE3nFJUkdsmwTvrVbE-UT6pxtok",
            "2XbHUb2b3S8JZDQbm8Utjg5i3QI0-_hWsBL1s5ha9Ms",
            "nQKVftnCU5VrnMhSaLLEEgtoYWcGvhAKt7ZYqVelqmw",
            "j13eXYze9rFjrFZyAMQlMqQXC7K3rNz9hEYk7I3pU0M",
            "crFpfFSa4vfDQStuDYdq2O46EP8zxpUa_2ZFBr7LT2s",
            "bJR_4VLv-hWU7TSpqCUs1ezau0cfv4ARE66UoMbsyQk",
            "87o5zQ026hMK9juFHhiUByqHLDd1i4F_Bz79C7ne1FE",
            "AMtn4SRcyvNPFkCelwNvtntBfUHqfnn4EINJtDSY3KU",
            "NPT1nusPvmOfsyivNpNLQitHi6zlueI6G1RZbnoMp28",
            "lS6TIurSukGM92DsfxoUu8Dxoy_atIrCoi3XseZqQ2w",
            "JAxNwYrk_C502jTomeMzo8otjfO8KYS2_g9gFV13oZA",
            "Yf9KFqrhIZ2ohbeQHcRjSwfxL4Oa2jwZwSKtRrSUY0M",
            "Mc_TZRzkia8O5vbeEFi5To45npGtbHFTgMY6UiZjnl4",
            "p19iD1c4YOwXni7-ZbLcih08beehQVJQGBCohphuBcA",
            "pUAI-F78fTw-DsLxzg1FaIKKIaz_E10QbPHxq9aKe14",
            "tvNoAKXPgA0f-wgRqdlH93MbutjWyIe1U81Cw_3akMQ",
            "fPrUWMNosaLuUKOO-C_X1I_UCilAkbZPvd72oQKnI9s",
            "Ac1uUb4yi7fT9MmaXawTSjyUdl918pQTmvaKVBgSX_c",
            "ujNxT3qtdfMRW6yKhxF15sJqv1LSnz78UnR3qPCEXVM",
            "Tkc0WtgFjUoQ9oGdLKMgNz4e2Np5R8amFnwp0OVVzqM",
            "SbtNPpyKLaFbchmP4SEe9rxpcPNoP3nlqGOv8SYMu24",
            "JfrJAN-ngDUbGwkNnVff8qfDkMsZ4gGtBrHG-5r5_7M",
            "o_I9Ghne2X8DhZOjp_S7vyE9KN1FfNeuW_bvfOr7NnQ",
            "oz6V2bC-PVfDAtIJTiYB8BAyxDAN4RJmRLeC14emA40",
            "McDLNHSEIm6uZPaeyOwl_xiNbUO_4OPit6thjKpg7Wg",
            "o3k_-F8pGP-v6AIv-jTPgz2Givr7xJeWMSTbXoUlj8Q",
            "QgZwFC5wuKIJ3Pv_3CTmxkdc705ENM8_5lNd7Qxmxk8",
            "2JnlggtDmkc9H9KTmCK9Tj-rjKoDTyOrAIiyAFLvmwE",
            "-9zCHYC3UD4QASu1eloANMXoBAsiF8DmQqKprmAaNx4",
            "eWVXQ3AqLbZaSgwskenkloejJ43X9JhlsUXcXvSy_Ss"];

        IERC721CreatorCore(_creator).setTokenURIPrefixExtension('https://arweave.net/');
        for (uint i = 0; i < hashes.length; i++) {
            IERC721CreatorCore(_creator).mintExtension(owner(), hashes[i]);
        }
    }

    function setBaseTokenURI(string calldata uri) external adminRequired {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(uri);
    }

    function setBaseTokenURI(string calldata uri, bool identical) external adminRequired {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(uri, identical);
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIExtension(tokenId, uri);
    }

    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIExtension(tokenIds, uris);
    }

    function setTokenURIPrefix(string calldata prefix) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIPrefixExtension(prefix);
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
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
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
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
    function mintBase(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

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
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
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
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
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
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
    constructor() {
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

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
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

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
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

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
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

}

{
  "optimizer": {
    "enabled": true,
    "runs": 25
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